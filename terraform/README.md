# Terraform - Queen's Marry Salon Infrastructure

This directory provisions AWS infrastructure for the Queen's Marry salon app backend.

## What Terraform Manages

| Resource | Purpose |
|----------|---------|
| **Key pair** | SSH key (`terra-key-ec2`) uploaded to EC2 for secure access |
| **Security group** | Firewall rules (SSH 22, HTTP 80, Backend API 5000) |
| **EC2 instance** | Ubuntu server for backend API (Node.js / Docker) |
| **S3 bucket** | Storage for salon assets (images, uploads) |

## Prerequisites

### 1. AWS CLI

Configure credentials:

```powershell
aws configure
```

Verify:

```powershell
aws sts get-caller-identity
```

### 2. Terraform

**Windows (winget):**

```powershell
winget install Hashicorp.Terraform
```

Close and reopen the terminal, or refresh PATH:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

**Chocolatey:** `choco install terraform`  
**Manual:** [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads)

### 3. SSH Key Pair

Create a key pair in the `terraform` folder (or use an existing one):

```powershell
cd terraform
ssh-keygen -t ed25519 -f terra-key-ec2
```

Keep `terra-key-ec2` (private) and `terra-key-ec2.pub` (public). Terraform uploads the public key to AWS.

## Quick Start

```powershell
cd terraform

# 1. Initialize (downloads providers)
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan (preview changes)
terraform plan

# 4. Apply (create resources)
terraform apply
```

## File Structure

| File | Purpose |
|------|---------|
| `terraform.tf` | Terraform & provider requirements |
| `providers.tf` | AWS provider config (region) |
| `ec2.tf` | Key pair, security group, EC2 instance |
| `s3.tf` | S3 bucket for salon assets |
| `variables.tf` | Input variables |
| `user-data.sh` | EC2 bootstrap script (Node, Docker, Redis, Nginx) |
| `terra-key-ec2` / `terra-key-ec2.pub` | SSH keys (do not commit private key) |

## Variables

Copy the example and edit:

```powershell
copy terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values. **Never commit `terraform.tfvars` or `.env`** – they may contain secrets.

## Outputs

After `terraform apply`, useful outputs include:

- EC2 public IP for SSH and API access
- SSH command to connect

## Destroy

To tear down all resources:

```powershell
terraform destroy
```

## Security

- **Never commit:** `terraform.tfvars`, `.env`, or `terra-key-ec2` (private key)
- Add to `.gitignore` if needed: `.env`, `terra-key-ec2`
- Rotate AWS keys if they were ever exposed

## Notes

- **Region:** Ensure `providers.tf` uses a valid region (e.g. `us-east-1`). `eu-east-1` is invalid.
- **Database:** Supabase remains separate – not managed by this Terraform.
- **Redis:** Installed on EC2 via user-data (localhost:6379). Ensure `REDIS_URL=redis://localhost:6379` in your backend `.env` on the server. For **existing** instances, install manually: `sudo apt install -y redis-server && sudo systemctl enable redis-server && sudo systemctl start redis-server`
- **Admin-web:** Deployed on Vercel – not managed here.
