# Medusa Backend Deployment on AWS ECS with Fargate

This project demonstrates deploying the [Medusa](https://medusajs.com/) open-source headless commerce backend on **AWS ECS (Fargate)** using **Terraform**, along with a **GitHub Actions** workflow for continuous deployment.

---

## 🏗️ Infrastructure Overview

- **Terraform** is used to provision:
  - VPC with public and private subnets
  - ECS Cluster with Fargate Launch Type
  - Task Definitions and Services
  - Application Load Balancer
  - Amazon RDS (PostgreSQL)
  - CloudWatch Logs

---

## 🚀 Deployment Flow

### 1. **Terraform Setup**

Make sure you have Terraform installed. Then run the following commands:

```bash
terraform init
terraform plan
terraform apply
Note: Make sure to fill in sensitive values in terraform.tfvars.

2. CI/CD Pipeline
We use GitHub Actions to build and deploy Docker images to AWS ECR and trigger ECS deployment.

Located in: .github/workflows/deploy.yml

Pipeline Steps:

Build Docker image

Push image to ECR

Update ECS service with new image

📁 Project Structure
bash
Copy
Edit
.
├── .github/workflows/        # GitHub Actions pipeline
├── terraform/                # All Terraform modules and configs
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── Dockerfile                # (To be placed in medusa-backend or root)
├── medusa-backend/           # (Optional) Medusa app source
├── README.md
✅ TODO (Optional Enhancements)
Add domain name and HTTPS using ACM & Route 53

Enable Auto Scaling for ECS Service

Add monitoring and alerting (CloudWatch Alarms)

🔗 Useful Links
Medusa Docs

Terraform AWS Provider

GitHub Actions Docs

🙌 Author
@saivijayy
Project for showcasing infrastructure automation and cloud-native deployment.
