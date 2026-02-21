# S3 bucket for salon app assets (images, uploads)
# Create in the same account as EC2, then migrate data from old bucket

data "aws_region" "current" {}

resource "aws_s3_bucket" "salon_assets" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Environment = var.environment
    Project     = "queens-marry-salon"
  }
}

# Block public access by default; allow public read only when s3_allow_public_read = true
resource "aws_s3_bucket_public_access_block" "salon_assets" {
  bucket = aws_s3_bucket.salon_assets.id

  block_public_acls       = true
  block_public_policy     = !var.s3_allow_public_read
  ignore_public_acls      = true
  restrict_public_buckets = !var.s3_allow_public_read
}

# Bucket policy for public read (when serving images via direct S3 URLs)
resource "aws_s3_bucket_policy" "salon_assets" {
  count = var.s3_allow_public_read ? 1 : 0

  bucket = aws_s3_bucket.salon_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.salon_assets.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.salon_assets]
}

# Versioning for backup/recovery
resource "aws_s3_bucket_versioning" "salon_assets" {
  bucket = aws_s3_bucket.salon_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}
