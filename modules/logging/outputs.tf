output "waf_log_group_name" {
  value = aws_cloudwatch_log_group.waf_logs.name
}

output "waf_analyzer_log_group_name" {
  value = aws_cloudwatch_log_group.waf_analyzer_logs.name
}

output "threat_correlation_log_group_name" {
  value = aws_cloudwatch_log_group.threat_correlation_logs.name
}

output "soar_response_log_group_name" {
  value = aws_cloudwatch_log_group.soar_response_logs.name
}

output "executive_dashboard_log_group_name" {
  value = aws_cloudwatch_log_group.executive_dashboard_logs.name
}
