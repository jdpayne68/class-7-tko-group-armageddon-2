output "waf_analyzer_lambda_arn" {
  value = aws_lambda_function.waf_analyzer.arn
}

output "threat_correlation_lambda_arn" {
  value = aws_lambda_function.threat_correlation.arn
}

output "soar_response_lambda_arn" {
  value = aws_lambda_function.soar_response.arn
}

output "executive_dashboard_lambda_arn" {
  value = aws_lambda_function.executive_dashboard.arn
}
output "soar_response_arn" {
  value = aws_lambda_function.soar_response.arn
}

output "soar_response_name" {
  value = aws_lambda_function.soar_response.function_name
}
