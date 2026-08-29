variable "prefix" {
  type        = string
  description = "Naming prefix for all IAM roles"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all IAM resources"
}

variable "waf_events_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table for raw WAF events"
}

variable "waf_correlation_findings_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table for correlated findings"
}

variable "security_incidents_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table for security incidents"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for alerts"
}

variable "reports_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket for executive reports"
}
# variable "soar_role_arn" {
#   type        = string
#   description = "IAM role ARN for the SOAR reasoning Lambda"
# }

variable "aws_region" {
  type = string
}

variable "model_id" {
  type = string
}


### 12c#########
variable "compliance_evidence_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table for compliance evidence"
}



