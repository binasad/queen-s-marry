# Terraform - Salon App Infrastructure

This directory provisions AWS infrastructure for the Queen's Marry salon app.

## What Terraform Manages

| Resource | Purpose |
|----------|---------|
| **EC2 instance** | Backend API (Node.js) – runs Docker |
| **S3 bucket** | File storage (profile images, service images) |
| **Security group** | Firewall rules (ports 22, 80, 443, 5000) |
| **Elastic IP** (optional) | Stable public IP for DDNS (e.g. aztrosyssalonappapi.ddns.net) |

## Prerequisites

1. **AWS CLI** configured with credentials:
   ```bash
   aws configure
   ```

2. **Terraform** installed ([terraform.io](https://terraform.io)):
   ```bash
   # Windows (choco)
   choco install terraform

   # Or download from https://www.terraform.io/downloads
   ```

3. **SSH key pair** in AWS EC2 (create in AWS Console → EC2 → Key Pairs)

## Quick Start

```bash
cd terraform

# 1. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your s3_bucket_name, ssh_key_name

# 2. Initialize
terraform init

# 3. Plan (preview changes)
terraform plan

# 4. Apply (create resources)
terraform apply
```

## Outputs After Apply

- `backend_public_ip` – EC2 public IP
- `backend_elastic_ip` – Stable IP for DDNS (if enabled)
- `s3_bucket_name` – S3 bucket for assets
- `backend_ssh_command` – SSH command to connect

## Current Setup vs Terraform

| Component | Current | With Terraform |
|-----------|---------|----------------|
| Backend | Docker on EC2 (manual) | EC2 + user-data (Docker pre-installed) |
| Database | Supabase (managed) | Keep Supabase – no change |
| S3 | Manual bucket | Terraform-managed bucket |
| Admin-web | Vercel | Keep Vercel – no change |

## Optional: Supabase with Terraform

If you want to manage Supabase via Terraform:

```hcl
# Add to main.tf
terraform {
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}
```

See [Supabase Terraform Provider](https://registry.terraform.io/providers/supabase/supabase/latest/docs).

## Optional: Vercel Deployment

Vercel has a [Terraform provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs) for managing deployments.

## Destroy

To tear down all resources:

```bash
terraform destroy
```
