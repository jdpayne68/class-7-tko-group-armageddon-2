#Core identity of the deployment.
variable "aws_region" {
  description = "AWS region to deploy ARMAGEDDON into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "armageddon-2026-summer-deployment"
  type        = string
  default     = "armageddon-summer-2026"
}


#DynamoDB table name variables

# Raw WAF events table name
variable "waf_events_table_name" {
  description = "DynamoDB_table_name_for raw WAF events"
  type        = string
  default     = "waf-events"
}

variable "waf_correlation_findings_table_name" {
  description = "DynamoDB table name for correlated findings"
  type        = string
  default     = "waf-correlation-findings"
}
# Correlated WAF findings table name
variable "security_incidents_table_name" {
  description = "DynamoDB table name for security incidents"
  type        = string
  default     = "security-incidents"
}
# Security incidents table name



# S3 bucket for raw WAF events
# S3 bucket for executive reports
variable "reports_bucket_name" {
  description = "S3 bucket name for executive reports"
  type        = string
  default     = "armageddon-executive-reports"
}

# Email address for security analyst alerts
variable "alerts_sns_email" {
  description = "Email address for security analyst alerts"
  type        = string
  default     = "marvinevins69@gmail.com"
}
# EventBridge schedule expressions for various Lambdas
#EventBridge needs a cron/rate expression to know how often to run each Lambda.
#WAF Analyzer:  every 1 minute in prod
variable "waf_analyzer_schedule_expression" {
  description = "EventBridge schedule for WAF Analyzer Lambda"
  type        = string
  default     = "rate(5 minutes)"
}

# Threat Correlation Lambda schedule expression
## Threat Correlation Lambda: every 5 minutes in prod
variable "threat_correlation_schedule_expression" {
  description = "EventBridge schedule for Threat Correlation Lambda"
  type        = string
  default     = "rate(5 minutes)"
}

# Executive Dashboard Lambda schedule expression
## Executive Dashboard Lambda: every 1 hour in prod
variable "executive_dashboard_schedule_expression" {
  description = "EventBridge schedule for Executive Dashboard Lambda"
  type        = string
  default     = "rate(1 hour)"
}
# variable "soar_role_arn" {
#   type = string
# }

variable "model_id" {
  type = string
  default = "anthropic.claude-3-sonnet-20240229-v1:0"

}
