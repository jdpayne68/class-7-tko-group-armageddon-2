# Stores executive reports (PDF, HTML, JSON summaries)

# Used by the Executive Dashboard Lambda
# Must be tagged

# Must block public access



# S3 Bucket for ARMAGEDDON Executive Reports

resource "aws_s3_bucket" "reports_bucket" {
  bucket = var.reports_bucket_name

  tags = var.common_tags
}

# Block all public access (security best practice)
resource "aws_s3_bucket_public_access_block" "reports_bucket_block" {
  bucket = aws_s3_bucket.reports_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (keeps historical reports)
resource "aws_s3_bucket_versioning" "reports_bucket_versioning" {
  bucket = aws_s3_bucket.reports_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "reports_bucket_encryption" {
  bucket = aws_s3_bucket.reports_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
