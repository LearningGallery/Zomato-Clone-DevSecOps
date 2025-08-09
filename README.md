# Zomato-Clone Infrastructure as Code (IaC) with Terraform & GitHub Actions CI/CD

## Project Overview

This project automates the provisioning and management of AWS infrastructure required to run the **Zomato-Clone** application. It uses **Terraform** to declaratively define cloud resources (VPC, IGW, subnets, security groups, etc.) and GitHub Actions to implement a robust CI/CD pipeline for continuous deployment.

---

## Architecture

- **AWS VPC** with public and private subnets  
- Internet Gateway (IGW) for outbound internet access  
- Security groups and route tables configured as per best practices  
- Resource tagging for easy identification and cost tracking  
- Modular Terraform code structure with environment-specific configurations (`dev`, `uat`, `prod`)

---

## Key Components

- `Terraform-Code/`  
  - Modular Terraform configuration files  
  - Environment folders (e.g., `dev`) with separate state and variable files  

- **GitHub Actions workflow**  
  - Runs `terraform plan` and uploads the plan artifact  
  - Runs `terraform apply` on the saved plan artifact to ensure idempotent and safe changes  
  - Uses secure environment variables for AWS credentials  
  - State locking and backend configured (if applicable)

---

## Prerequisites

Before running this project, ensure you have the following:

- **AWS Account** with programmatic access (access key ID and secret access key)  
- **Terraform v1.6.6** installed locally (or use Terraform CLI in GitHub Actions)  
- **GitHub repository** with configured **GitHub Actions workflows**  
- AWS CLI configured locally (optional for manual testing)  
- Sufficient IAM permissions for Terraform to create/update VPC and related resources  
- Optional: Terraform backend (S3 + DynamoDB) configured for remote state locking and management

---

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/LearningGallery/Zomato-Clone-DevSecOps.git
cd Zomato-Clone-DevSecOps/Terraform-Code/environments/dev
