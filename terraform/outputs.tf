output "backend_public_ip" {
  description = "Public IP of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "backend_elastic_ip" {
  description = "Elastic IP (if assigned) - use for DDNS"
  value       = var.assign_elastic_ip ? aws_eip.backend[0].public_ip : null
}

output "s3_bucket_name" {
  description = "S3 bucket name for assets"
  value       = aws_s3_bucket.salon_assets.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.salon_assets.arn
}

output "backend_ssh_command" {
  description = "SSH command to connect to backend"
  value       = "ssh -i <your-key.pem> ubuntu@${var.assign_elastic_ip ? aws_eip.backend[0].public_ip : aws_instance.backend.public_ip}"
}
