output "reports_bucket_name" {
  value = aws_s3_bucket.reports_bucket.bucket
}

output "reports_bucket_arn" {
  value = aws_s3_bucket.reports_bucket.arn
}
