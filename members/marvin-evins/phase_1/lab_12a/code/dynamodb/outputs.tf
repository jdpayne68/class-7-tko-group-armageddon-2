output "waf_events_table_arn" {
  value = aws_dynamodb_table.waf_events.arn
}

output "waf_correlation_findings_table_arn" {
  value = aws_dynamodb_table.waf_correlation_findings.arn
}

output "security_incidents_table_arn" {
  value = aws_dynamodb_table.security_incidents.arn
}



######################12c########################
#we need this because we are creating a new table for compliance evidence in the dynamodb module
### this will allow us to reference the arn of the compliance evidence table in other modules or resources that depend on it.
### the arn is a unique identifier for the table and can be used to grant permissions or access to the table in other parts of the infrastructure.
output "compliance_evidence_table_arn" {
  value = aws_dynamodb_table.compliance_evidence.arn
}


output "compliance_evidence_table_name" {
  description = "Name of the DynamoDB compliance evidence table"
  value       = aws_dynamodb_table.compliance_evidence.name
}