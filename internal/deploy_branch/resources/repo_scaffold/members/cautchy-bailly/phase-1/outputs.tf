# [lab12]
# Sensor

# Consumed by scripts/verify.sh so it never has to guess the region.
output "aws_region" {
  value = var.aws_region
}

output "api_url" {
  value = aws_api_gateway_stage.prod.invoke_url
}

output "api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "stage_arn" {
  value = aws_api_gateway_stage.prod.arn
}

output "waf_arn" {
  value = aws_wafv2_web_acl.waf.arn
}

# Identity

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "cognito_groups" {
  value = [
    aws_cognito_user_group.admins.name,
    aws_cognito_user_group.students.name,
  ]
}

# Pipeline tables

output "waf_events_table" {
  value = aws_dynamodb_table.waf_events.name
}

output "correlation_findings_table" {
  value = aws_dynamodb_table.correlation_findings.name
}

output "security_incidents_table" {
  value = aws_dynamodb_table.security_incidents.name
}

output "token_table" {
  value = aws_dynamodb_table.token_tracking.name
}

# Agents - invoke by hand instead of waiting for the schedule
#   aws lambda invoke --function-name "$(terraform output -raw analyzer_function)" \
#     --payload '{}' /dev/stdout

output "analyzer_function" {
  value = aws_lambda_function.analyzer.function_name
}

output "correlation_function" {
  value = aws_lambda_function.correlation.function_name
}

output "soar_function" {
  value = aws_lambda_function.soar.function_name
}

output "dashboard_function" {
  value = aws_lambda_function.dashboard.function_name
}

# Routing

output "finding_event_pattern" {
  description = "What the correlation agent publishes and the rules match on."
  value = {
    source        = var.finding_event_source
    detail_type   = var.finding_event_detail_type
    medium_high   = aws_cloudwatch_event_rule.finding_medium_high.name
    critical      = aws_cloudwatch_event_rule.finding_critical.name
  }
}

# Alerting and reports

output "alert_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "critical_alert_topic_arn" {
  value = aws_sns_topic.critical_alerts.arn
}

output "report_bucket" {
  value = aws_s3_bucket.reports.bucket
}

# Verification

output "bedrock_model_id" {
  value = var.bedrock_model_id
}

output "admin_authorizer_function" {
  value = aws_lambda_function.authorizer.function_name
}

output "log_groups" {
  value = [
    aws_cloudwatch_log_group.analyzer.name,
    aws_cloudwatch_log_group.authorizer.name,
    aws_cloudwatch_log_group.correlation.name,
    aws_cloudwatch_log_group.soar.name,
    aws_cloudwatch_log_group.dashboard.name,
    aws_cloudwatch_log_group.waf_logs.name,
  ]
}
