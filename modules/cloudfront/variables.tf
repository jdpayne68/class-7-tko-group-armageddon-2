variable "origin_domain_name" {
  type        = string
  description = "Domain name of the CloudFront origin (S3 or ALB)"
}

variable "origin_access_identity" {
  type        = string
  description = "CloudFront Origin Access Identity for S3"
}

variable "logging_bucket" {
  type        = string
  description = "S3 bucket for CloudFront logs"
}

variable "waf_acl_arn" {
  type        = string
  description = "ARN of the WAF Web ACL"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to CloudFront resources"
}
