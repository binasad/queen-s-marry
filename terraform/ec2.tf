# Latest Ubuntu 22.04 AMI (region-specific)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "my_key" {
  key_name   = "terra-key-ec2"
  public_key = file("${path.module}/terra-key-ec2.pub")
}

# Security group for EC2
resource "aws_security_group" "my_security_group" {
  name        = "salon-backend-sg"
  description = "Allow SSH, HTTP, and backend API access"

  # Inbound rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }
}

# EC2 instance
resource "aws_instance" "my_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  # Bootstrap: installs Node 20, PM2, Nginx reverse-proxy, Docker, Certbot
  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  tags = {
    Name = "backendSalonMarryQueen"
  }
}

# Elastic IP - stable public IP for DNS/DDNS (doesn't change on restart)
resource "aws_eip" "backend" {
  instance = aws_instance.my_instance.id
  domain   = "vpc"

  tags = {
    Name = "salon-backend-eip"
  }
}
