output "api_invoke_url" {
  description = "Callable URL for the protected GET /analyze endpoint"
  value = join(
    "",
    [
      aws_api_gateway_stage.application.invoke_url,
      aws_api_gateway_resource.analyze.path,
    ]
  )
}

output "application_lambda_name" {
  description = "Protected application Lambda function name"
  value       = aws_lambda_function.application.function_name
}

output "analyzer_lambda_name" {
  description = "WAF analyzer Lambda function name"
  value       = aws_lambda_function.analyzer.function_name
}

output "correlation_lambda_name" {
  description = "Threat-correlation Lambda function name"
  value       = aws_lambda_function.correlation.function_name
}

output "waf_events_table_name" {
  description = "DynamoDB table containing normalized WAF events"
  value       = aws_dynamodb_table.waf_events.name
}

output "correlation_findings_table_name" {
  description = "DynamoDB table containing correlation findings"
  value       = aws_dynamodb_table.correlation_findings.name
}

output "waf_log_group_name" {
  description = "CloudWatch log group reserved for AWS WAF logs"
  value       = aws_cloudwatch_log_group.waf.name
}
