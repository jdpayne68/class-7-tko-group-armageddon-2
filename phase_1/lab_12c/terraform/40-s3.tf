# ================================================================
# S3 BUCKETS
# ================================================================

# -------------------------------------------------------------------------------
# S3 Bucket - Executive Reports
# -------------------------------------------------------------------------------
resource "aws_s3_bucket" "executive_report_bucket" {
  bucket        = "${local.name_prefix}-executive-reports-${local.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "executive_report_bucket" {
  bucket = aws_s3_bucket.executive_report_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "report_bucket" {
  bucket = aws_s3_bucket.executive_report_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    # SSE-C encryption is now disabled by default. State block as best practice and enable explicitly if needed.
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/blocking-unblocking-s3-c-encryption-gpb.html
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_public_access_block" "executive_report_bucket" {
  bucket                  = aws_s3_bucket.executive_report_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------------------------------------------------------
# S3 Bucket - Compliance Evidence Reports
# -------------------------------------------------------------------------------
resource "aws_s3_bucket" "compliance_evidence_report_bucket" {
  bucket        = "${local.name_prefix}-compliance-evidence-reports-${local.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "compliance_evidence_report_bucket" {
  bucket = aws_s3_bucket.compliance_evidence_report_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "compliance_evidence_report_bucket" {
  bucket = aws_s3_bucket.compliance_evidence_report_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_public_access_block" "compliance_evidence_report_bucket" {
  bucket                  = aws_s3_bucket.compliance_evidence_report_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
