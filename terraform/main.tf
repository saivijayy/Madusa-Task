	# main.tf
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "medusa-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  tags = {
    Project = "Medusa"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "medusa-db-sg"
  description = "Security group for Medusa RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
  description = "Allow PostgreSQL from my IP"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["152.58.195.106/32"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medusa-db-sg"
  }
}



# 🟩 NEW SECURITY GROUP: Allows ALB to talk to ECS on port 3000
resource "aws_security_group" "ecs_service_sg" {
  name        = "medusa-ecs-sg"
  description = "Allow ALB to reach ECS tasks on port 3000"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # 🟦 ALB SG must already exist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "public" {
  name       = "medusa-db-subnet-group"
  subnet_ids = module.vpc.public_subnets  # Ensure this matches the VPC your ECS is in

  tags = {
    Name = "Medusa DB Subnet Group"
  }
}

resource "aws_db_instance" "medusa" {
  identifier              = "medusa-db"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = "medusa"
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.public.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  publicly_accessible     = true
  skip_final_snapshot     = true

  tags = {
    Name = "Medusa RDS Instance"
  }
}

resource "aws_ecs_cluster" "medusa" {
  name = "medusa-cluster"
}


resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "medusa" {
  family                   = "medusa-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "medusa"
      image = "850995548387.dkr.ecr.us-east-1.amazonaws.com/medusa-backend:v1.0.0"
      essential = true
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/medusa-task"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "medusa"
        }
      }
    }
  ])
}



resource "aws_ecs_service" "medusa" {
  name            = "medusa-service-v2"
  cluster         = aws_ecs_cluster.medusa.id
  task_definition = aws_ecs_task_definition.medusa.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.medusa_tg_9000.arn
    container_name   = "medusa"
    container_port   = 9000
  }


  depends_on = [aws_lb_listener.frontend]
}

resource "aws_ecr_repository" "medusa_backend" {
  name = "medusa-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = false
}


resource "aws_lb" "medusa_alb" {
  name               = "medusa-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}


resource "aws_lb_target_group" "medusa_tg_9000" {
  name        = "medusa-tg-9000"
  port        = 9000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id = module.vpc.vpc_id

  health_check {
    path                = "/store/products"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}


resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.medusa_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.medusa_tg_9000.arn
  }
}

# variables.tf
variable "aws_region" {
  default = "us-east-1"
}

variable "db_name" {
  default = "medusadb"
}

variable "db_user" {
  default = "medusa"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

# outputs.tf
output "alb_url" {
  value = aws_lb.medusa_alb.dns_name
  description = "URL to access the Medusa backend"
}

output "db_endpoint" {
  value = aws_db_instance.medusa.address
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_logs" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
