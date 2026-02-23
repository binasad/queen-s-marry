output "ec2_public_ip" {
  description = "Public IP of the EC2 instance (same as Elastic IP when attached)"
  value       = aws_eip.backend.public_ip
}

output "elastic_ip" {
  description = "Elastic IP - use this for your DNS/DDNS (aztrosyssalonappapi.ddns.net)"
  value       = aws_eip.backend.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i terra-key-ec2 ubuntu@${aws_eip.backend.public_ip}"
}

output "api_base_url" {
  description = "Backend API base URL (update your .env with this)"
  value       = "https://aztrosyssalonappapi.ddns.net/api/v1"
}

# CloudFront outputs
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (e.g. d1234abcd.cloudfront.net)"
  value       = aws_cloudfront_distribution.salon_assets.domain_name
}

output "cloudfront_url" {
  description = "Base URL for S3 assets via CloudFront - use https://<this>/path/to/image.jpg"
  value       = "https://${aws_cloudfront_distribution.salon_assets.domain_name}"
}
