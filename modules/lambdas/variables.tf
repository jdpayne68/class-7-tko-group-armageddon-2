variable "prefix" {
  type        = string
  description = "Naming prefix for Lambda functions"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all Lambda resources"
}

# IAM role ARNs
variable "waf_analyzer_role_arn" {
  type        = string
  description = "IAM role ARN for WAF Analyzer Lambda"
}

variable "threat_correlation_role_arn" {
  type        = string
  description = "IAM role ARN for Threat Correlation Lambda"
}

variable "soar_response_role_arn" {
  type        = string
  description = "IAM role ARN for SOAR Response Lambda"
}

variable "executive_dashboard_role_arn" {
  type        = string
  description = "IAM role ARN for Executive Dashboard Lambda"
}

# DynamoDB table names
variable "waf_events_table_name" {
  type        = string
}

variable "waf_correlation_findings_table_name" {
  type        = string
}

variable "security_incidents_table_name" {
  type        = string
}

# SNS + S3
variable "sns_topic_arn" {
  type        = string
}

variable "reports_bucket_name" {
  type        = string
}
