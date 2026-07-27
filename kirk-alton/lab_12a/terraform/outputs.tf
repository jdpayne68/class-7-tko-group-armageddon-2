# ================================================================
# OUTPUTS
# ================================================================

output "api_base_url" {
  description = "Base URL for the deployed prod REST API stage."
  value       = "https://${aws_api_gateway_rest_api.chewbacca_auth_rest_api.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "aws_account_id" {
  description = "AWS account ID in which Terraform creates the lab resources."
  value       = data.aws_caller_identity.current.account_id
}

output "jedi_url" {
  description = "Protected Jedi route URL."
  value       = "https://${aws_api_gateway_rest_api.chewbacca_auth_rest_api.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/jedi"
}

output "sith_url" {
  description = "Protected Sith route URL."
  value       = "https://${aws_api_gateway_rest_api.chewbacca_auth_rest_api.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/sith"
}

output "user_pool_id" {
  description = "Cognito user pool ID."
  value       = aws_cognito_user_pool.chewbacca_auth_rest.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN used by the API Gateway authorizer."
  value       = aws_cognito_user_pool.chewbacca_auth_rest.arn
}

output "cognito_issuer" {
  description = "Issuer claim expected in JWTs from this user pool."
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.chewbacca_auth_rest.id}"
}

output "public_client_id" {
  description = "No-secret client ID used by scripts/get_token.py."
  value       = aws_cognito_user_pool_client.public.id
}

output "cli_client_id" {
  description = "Secret-bearing client ID used for SECRET_HASH practice."
  value       = aws_cognito_user_pool_client.cli.id
}

output "cli_client_secret" {
  description = "Secret-bearing app client secret. Read with terraform output -raw cli_client_secret."
  value       = aws_cognito_user_pool_client.cli.client_secret
  sensitive   = true
}

output "managed_login_url" {
  description = "Managed login authorization URL for the public app client."
  value       = "https://${aws_cognito_user_pool_domain.chewbacca_auth_rest.domain}.auth.${data.aws_region.current.region}.amazoncognito.com/oauth2/authorize?response_type=code&client_id=${aws_cognito_user_pool_client.public.id}&redirect_uri=${urlencode(var.callback_url)}&scope=openid+email+profile"
}

output "token_table_name" {
  description = "DynamoDB table used by the token helper and route Lambdas."
  value       = aws_dynamodb_table.token_holocron.name
}

output "token_alert_topic_arn" {
  description = "SNS topic that receives unused-token alarms."
  value       = aws_sns_topic.token_alerts.arn
}

output "api_gateway_waf_web_acl_arn" {
  description = "AWS WAF Web ACL ARN attached to the prod REST API stage."
  value       = aws_wafv2_web_acl.shield_generator.arn
}
