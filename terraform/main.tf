# Salon App - Infrastructure as Code
# Provisions AWS resources for backend (EC2) and S3 storage

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# S3 Bucket for file uploads (profiles, service images)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "salon_assets" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "Salon App Assets"
    Environment = var.environment
    Project     = "queen-s-marry"
  }
}

resource "aws_s3_bucket_public_access_block" "salon_assets" {
  bucket = aws_s3_bucket.salon_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "salon_assets" {
  bucket = aws_s3_bucket.salon_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# EC2 instance for backend (Node.js API)
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "backend" {
  name        = "salon-backend-sg"
  description = "Security group for Salon backend API"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "salon-backend-sg"
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.backend.id]

  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "salon-backend"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Elastic IP (optional - for stable public IP / DDNS)
# -----------------------------------------------------------------------------
resource "aws_eip" "backend" {
  count  = var.assign_elastic_ip ? 1 : 0
  domain = "vpc"
  instance = aws_instance.backend.id

  tags = {
    Name = "salon-backend-eip"
  }
}
