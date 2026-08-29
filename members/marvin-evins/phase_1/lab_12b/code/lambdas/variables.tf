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
variable "soar_role_arn" {
  type        = string
  description = "IAM role ARN for the SOAR reasoning Lambda"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the SOAR reasoning Lambda"
}

variable "model_id" {
  type        = string
  description = "Model ID for the SOAR reasoning Lambda"
  default     =  "anthropic.claude-3-sonnet-20240229-v1:0"
}


variable "compliance_role_arn" {
  type        = string
  description = "IAM role ARN for the Compliance Lambda"
}

variable "compliance_evidence_table_name" {
  type        = string
  description = "Name of the DynamoDB compliance evidence table"
}

# variable "reports_bucket_name" {
#   type        = string
#   description = "Name of the existing S3 reports bucket"
# }