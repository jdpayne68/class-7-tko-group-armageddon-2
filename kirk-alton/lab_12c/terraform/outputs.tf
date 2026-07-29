# # ================================================================
# # OUTPUTS
# # ================================================================

# # -------------------------------------------------------------------------------
# # Context - Account and Environment
# # -------------------------------------------------------------------------------
# output "aws_account_id" {
#   description = "AWS account ID in which Terraform creates the lab resources."
#   value       = data.aws_caller_identity.current.account_id
# }

# # -------------------------------------------------------------------------------
# # Testing Commands
# # -------------------------------------------------------------------------------
# output "test_waf_command" {
#   description = "Command to simulate XSS attack and generate test WAF traffic."
#   value       = "curl -X POST '${local.api_base_url}/analyze' -H 'Content-Type: application/json' -d '{\"name\":\"<script>alert(1)</script>\"}'"
# }

# output "check_waf_logs_command" {
#   description = "Command to check WAF logs in CloudWatch."
#   value       = "aws logs filter-log-events --log-group-name ${aws_cloudwatch_log_group.waf_logs.name} --start-time $(date -v-5M +%s%3N) --region ${local.region} --limit 25"
# }

# # -------------------------------------------------------------------------------
# # API Gateway Outputs
# # -------------------------------------------------------------------------------
# output "api_base_url" {
#   description = "Base URL for the deployed prod REST API stage."
#   value       = local.api_base_url
# }

# output "jedi_url" {
#   description = "Protected Jedi route URL."
#   value       = "${local.api_base_url}/jedi"
# }

# output "sith_url" {
#   description = "Protected Sith route URL."
#   value       = "${local.api_base_url}/sith"
# }

# output "analyzer_endpoint" {
#   description = "WAF Bedrock analyzer endpoint URL for sending test traffic."
#   value       = "${local.api_base_url}/analyze"
# }

# # -------------------------------------------------------------------------------
# # Cognito Outputs
# # -------------------------------------------------------------------------------
# output "managed_login_url" {
#   description = "Managed login authorization URL for the public app client."
#   value       = "https://${aws_cognito_user_pool_domain.chewbacca_auth_rest.domain}.auth.${local.region}.amazoncognito.com/oauth2/authorize?response_type=code&client_id=${aws_cognito_user_pool_client.public.id}&redirect_uri=${urlencode(var.callback_url)}&scope=openid+email+profile"
# }

# output "user_pool_id" {
#   description = "Cognito user pool ID."
#   value       = aws_cognito_user_pool.chewbacca_auth_rest.id
# }

# output "user_pool_arn" {
#   description = "Cognito user pool ARN used by the API Gateway authorizer."
#   value       = aws_cognito_user_pool.chewbacca_auth_rest.arn
# }

# output "cognito_issuer" {
#   description = "Issuer claim expected in JWTs from the Cognito user pool."
#   value       = "https://cognito-idp.${local.region}.amazonaws.com/${aws_cognito_user_pool.chewbacca_auth_rest.id}"
# }

# output "public_client_id" {
#   description = "No-secret client ID for scripts"
#   value       = aws_cognito_user_pool_client.public.id
# }

# output "cli_client_id" {
#   description = "Secret-bearing client ID."
#   value       = aws_cognito_user_pool_client.cli.id
# }

# output "cli_client_secret" {
#   description = "Secret-bearing app client secret. Read with terraform output -raw cli_client_secret."
#   value       = aws_cognito_user_pool_client.cli.client_secret
#   sensitive   = true
# }

# # -------------------------------------------------------------------------------
# # Lambda Function Names
# # -------------------------------------------------------------------------------
# output "jedi_lambda_function_name" {
#   description = "Name of the Jedi Python Lambda function."
#   value       = aws_lambda_function.jedi_python.function_name
# }

# output "sith_lambda_function_name" {
#   description = "Name of the Sith Node.js Lambda function."
#   value       = aws_lambda_function.sith_node.function_name
# }

# output "unused_token_detector_function_name" {
#   description = "Name of the unused token detector Lambda function."
#   value       = aws_lambda_function.unused_token_detector.function_name
# }

# output "waf_bedrock_analyzer_function_name" {
#   description = "Name of the WAF Bedrock analyzer Lambda function."
#   value       = aws_lambda_function.waf_bedrock_analyzer.function_name
# }

# output "waf_threat_correlation_agent_function_name" {
#   description = "Name of the WAF threat correlation agent Lambda function."
#   value       = aws_lambda_function.waf_threat_correlation_agent.function_name
# }

# output "soar_response_agent_function_name" {
#   description = "Name of the SOAR response agent Lambda function."
#   value       = aws_lambda_function.soar_response_agent.function_name
# }

# # -------------------------------------------------------------------------------
# # DynamoDB Tables
# # -------------------------------------------------------------------------------
# output "token_table_name" {
#   description = "DynamoDB table used by the token helper and route Lambdas."
#   value       = aws_dynamodb_table.token_holocron.name
# }

# output "waf_events_table_name" {
#   description = "DynamoDB table storing WAF events."
#   value       = aws_dynamodb_table.shield_generator_events.name
# }

# output "waf_correlation_findings_table_name" {
#   description = "DynamoDB table storing threat correlation findings."
#   value       = aws_dynamodb_table.waf_correlation_findings.name
# }

# output "waf_security_incidents_table_name" {
#   description = "DynamoDB table storing security incidents."
#   value       = aws_dynamodb_table.waf_security_incidents.name
# }

# # -------------------------------------------------------------------------------
# # EventBridge Outputs
# # -------------------------------------------------------------------------------
# output "eventbridge_rule_names" {
#   description = "EventBridge rule names for SOAR triggers."
#   value = {
#     medium_high = aws_cloudwatch_event_rule.soar_response_medium_high.name
#     critical    = aws_cloudwatch_event_rule.soar_response_critical.name
#   }
# }

# output "eventbridge_rule_arns" {
#   description = "EventBridge rule ARNs for SOAR triggers."
#   value = {
#     medium_high = aws_cloudwatch_event_rule.soar_response_medium_high.arn
#     critical    = aws_cloudwatch_event_rule.soar_response_critical.arn
#   }
# }

# output "scheduler_names" {
#   description = "EventBridge scheduler names for Lambda invocations."
#   value = {
#     waf_analyzer       = aws_scheduler_schedule.waf_bedrock_analyzer.name
#     threat_correlation = aws_scheduler_schedule.threat_correlation.name
#     unused_token       = aws_scheduler_schedule.unused_token_check.name
#   }
# }

# output "scheduler_arns" {
#   description = "EventBridge scheduler ARNs for Lambda invocations."
#   value = {
#     waf_analyzer       = aws_scheduler_schedule.waf_bedrock_analyzer.arn
#     threat_correlation = aws_scheduler_schedule.threat_correlation.arn
#     unused_token       = aws_scheduler_schedule.unused_token_check.arn
#   }
# }

# # -------------------------------------------------------------------------------
# # SNS Outputs
# # -------------------------------------------------------------------------------
# output "token_alert_topic_arn" {
#   description = "SNS topic that receives unused-token alarms."
#   value       = aws_sns_topic.token_alerts.arn
# }

# output "waf_security_incidents_topic_arn" {
#   description = "SNS topic ARN for WAF security incident alerts."
#   value       = aws_sns_topic.waf_security_incidents_alert.arn
# }

# # -------------------------------------------------------------------------------
# # CloudWatch Log Groups
# # -------------------------------------------------------------------------------
# output "jedi_python_log_group_name" {
#   description = "CloudWatch log group for the Jedi Python Lambda."
#   value       = aws_cloudwatch_log_group.jedi_python.name
# }

# output "sith_node_log_group_name" {
#   description = "CloudWatch log group for the Sith Node.js Lambda."
#   value       = aws_cloudwatch_log_group.sith_node.name
# }

# output "unused_token_detector_log_group_name" {
#   description = "CloudWatch log group for the unused token detector Lambda."
#   value       = aws_cloudwatch_log_group.unused_token_detector.name
# }

# output "waf_bedrock_analyzer_log_group_name" {
#   description = "CloudWatch log group for the WAF Bedrock analyzer Lambda."
#   value       = aws_cloudwatch_log_group.waf_bedrock_analyzer.name
# }

# output "soar_response_agent_log_group_name" {
#   description = "CloudWatch log group for the SOAR response agent Lambda."
#   value       = aws_cloudwatch_log_group.soar_response_agent.name
# }

# output "waf_log_group_name" {
#   description = "CloudWatch log group where WAF logs are stored."
#   value       = aws_cloudwatch_log_group.waf_logs.name
# }

# output "api_gateway_access_log_group_name" {
#   description = "CloudWatch log group for API Gateway access logs."
#   value       = aws_cloudwatch_log_group.api_gateway_access.name
# }