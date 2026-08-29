variable "waf_events_table_name" {
  type        = string
  description = "Name of the DynamoDB table for raw WAF events"
}

variable "waf_correlation_findings_table_name" {
  type        = string
  description = "Name of the DynamoDB table for correlated findings"
}

variable "security_incidents_table_name" {
  type        = string
  description = "Name of the DynamoDB table for security incidents"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all DynamoDB tables"
}


#### 12c#########################
variable "compliance_evidence_table_name" {
  type        = string
  description = "Name of the DynamoDB table for compliance evidence"
}