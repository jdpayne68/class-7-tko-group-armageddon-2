# [lab12b]
# Executive Report Bucket (lab12b)
#
# Holds the PDF and JSON produced by the dashboard agent:
#   executive-reports/YYYY/MM/DD/pdf/executive-security-*.pdf
#   executive-reports/YYYY/MM/DD/json/executive-security-*.json

resource "aws_s3_bucket" "reports" {
  bucket = "${var.project}-reports-${data.aws_caller_identity.current.account_id}"
  force_destroy = true #allows TF to delete the bucket even if it has objects in it

  tags = {
    Name        = "Executive Reports"
    Environment = "Lab"
    Project     = "lab12"
  }
}

# These reports summarise security incidents. Nothing about them should ever
# be reachable anonymously.
resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Reject any plaintext request outright rather than relying on callers to
# choose HTTPS.
data "aws_iam_policy_document" "reports_tls_only" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.reports.arn,
      "${aws_s3_bucket.reports.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "reports" {
  bucket = aws_s3_bucket.reports.id
  policy = data.aws_iam_policy_document.reports_tls_only.json

  depends_on = [aws_s3_bucket_public_access_block.reports]
}
