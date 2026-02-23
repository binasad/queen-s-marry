variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for salon assets (must be globally unique)"
  type        = string
  default     = "salon-app-assets-queensmarry-2026"
}

variable "s3_allow_public_read" {
  description = "Allow public read for bucket objects (needed for serving images)"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.small"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for EC2 access (matches aws_key_pair.my_key)"
  type        = string
  default     = "terra-key-ec2"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "assign_elastic_ip" {
  description = "Assign Elastic IP for stable public IP (useful for DDNS)"
  type        = bool
  default     = true
}
