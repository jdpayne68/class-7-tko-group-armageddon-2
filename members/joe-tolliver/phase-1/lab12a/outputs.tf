output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.seir_deepend_client.id
}

output "api_gateway_stage" {
  value = aws_api_gateway_stage.prod.invoke_url
}