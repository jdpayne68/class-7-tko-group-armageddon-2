variable "reports_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for executive reports"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all S3 resources"
}
