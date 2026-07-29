output "waf_events_table_arn" {
  value = aws_dynamodb_table.waf_events.arn
}

output "waf_correlation_findings_table_arn" {
  value = aws_dynamodb_table.waf_correlation_findings.arn
}

output "security_incidents_table_arn" {
  value = aws_dynamodb_table.security_incidents.arn
}
