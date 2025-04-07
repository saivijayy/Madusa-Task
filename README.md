# 🚀 Medusa Headless Commerce Deployment on AWS ECS (Fargate)

[![Deploy Status](https://img.shields.io/badge/deploy-success-brightgreen)](https://github.com/saivijayy/Medusa-Task/actions)

This project deploys the open-source [Medusa](https://medusajs.com/) backend to AWS using ECS with Fargate. Infrastructure is provisioned using Terraform, and a CI/CD pipeline is set up using GitHub Actions.

---

## 🧰 Tech Stack

- **Terraform** – IaC for AWS resources  
- **AWS ECS (Fargate)** – Serverless container orchestration  
- **RDS (PostgreSQL)** – Managed database  
- **Docker** – Containerized Medusa backend  
- **GitHub Actions** – CI/CD pipeline for deployment  

---

## 🗂️ Project Structure

. ├── .github/workflows/ # GitHub Actions for CD │ └── deploy.yml ├── terraform/ # Terraform IaC configs │ ├── main.tf │ ├── variables.tf │ ├── terraform.tfvars │ └── ... ├── Dockerfile # Medusa Docker container ├── package.json # Medusa dependencies ├── README.md # Project documentation └── .gitignore # Ignore state files, node_modules, etc.

yaml
Copy
Edit

---

## ⚙️ Infrastructure Overview

pgsql
Copy
Edit
        +-----------------------------+
        |    GitHub Actions Workflow  |
        | - Build Docker image        |
        | - Push to ECR               |
        | - Deploy to ECS Fargate     |
        +-------------+---------------+
                      |
                      ▼
+--------------------- AWS Infrastructure ----------------------+ | | | +----------------+ +----------------+ +-----------+ | | | VPC | --> | Subnets | --> | ECS w/ | | | | | | (Public/Private)| | Fargate | | | +----------------+ +----------------+ +-----------+ | | | | | | | ▼ ▼ ▼ | | Internet Gateway NAT Gateway RDS (Postgres)| | (Medusa DB) | +---------------------------------------------------------------+

yaml
Copy
Edit

---

## 🚀 Deployment Steps

### 1. Clone the repository

```bash
git clone https://github.com/saivijayy/Medusa-Task.git
cd Medusa-Task
2. Provision AWS infrastructure
bash
Copy
Edit
cd terraform
terraform init
terraform apply
Update terraform.tfvars with your AWS values (e.g., DB credentials, region).

3. Trigger CI/CD pipeline
bash
Copy
Edit
git add .
git commit -m "Initial deploy"
git push
This will:

Build your Docker image

Push it to AWS ECR

Update your ECS service with the new image

✅ ECS tasks are successfully deployed and containerized Medusa backend is up!

🔒 .gitignore (safety for secrets)
We’ve ensured sensitive files and large unnecessary folders are excluded:

bash
Copy
Edit
node_modules/
.terraform/
*.tfstate
*.tfstate.backup
.env
terraform/*.tfstate*
🙋‍♂️ Author
Sai Vijay
📍 GitHub Profile
