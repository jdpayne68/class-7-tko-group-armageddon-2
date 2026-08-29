variable "prefix" {
  type        = string
  description = "Naming prefix for EventBridge rules"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all EventBridge resources"
}

# Lambda ARNs
variable "waf_analyzer_lambda_arn" {
  type        = string
}

variable "threat_correlation_lambda_arn" {
  type        = string
}

variable "soar_response_lambda_arn" {
  type        = string
}

variable "executive_dashboard_lambda_arn" {
  type        = string
}

# Schedule expressions
variable "waf_analyzer_schedule_expression" {
  type        = string
}

variable "threat_correlation_schedule_expression" {
  type        = string
}

variable "executive_dashboard_schedule_expression" {
  type        = string
}

variable "soar_response_arn" {
  type = string
}

variable "soar_response_name" {
  type = string
}
variable "soar_lambda_arn" {
  type = string
}
