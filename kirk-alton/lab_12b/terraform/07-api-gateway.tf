# ================================================================
# API GATEWAY REST API
# ================================================================

# -------------------------------------------------------------------------------
# REST API And Cognito Authorizer
# -------------------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "chewbacca_auth_rest_api" {
  name        = "${local.name_prefix}-api"
  description = "REST API prote4cted by AWS Cognito and WAF"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.name_prefix}-cognito-authorizer-${local.name_suffix}"
  rest_api_id     = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.chewbacca_auth_rest.arn]
  identity_source = "method.request.header.Authorization"
}

# -------------------------------------------------------------------------------
# Jedi Resource, Method, And Lambda Proxy Integration
# -------------------------------------------------------------------------------
resource "aws_api_gateway_resource" "jedi" {
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id
  path_part   = "jedi"
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
}

resource "aws_api_gateway_method" "jedi_get" {
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  http_method          = "GET"
  resource_id          = aws_api_gateway_resource.jedi.id
  rest_api_id          = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  authorization_scopes = [local.required_auth_scope]
}

resource "aws_api_gateway_integration" "jedi_lambda" {
  http_method             = aws_api_gateway_method.jedi_get.http_method
  resource_id             = aws_api_gateway_resource.jedi.id
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.jedi_python.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke_jedi" {
  statement_id  = "AllowAPIGatewayInvokeJedi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jedi_python.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/GET/jedi"
}

# -------------------------------------------------------------------------------
# Sith Resource, Method, And Lambda Proxy Integration
# -------------------------------------------------------------------------------
resource "aws_api_gateway_resource" "sith" {
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id
  path_part   = "sith"
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
}

resource "aws_api_gateway_method" "sith_get" {
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  http_method          = "GET"
  resource_id          = aws_api_gateway_resource.sith.id
  rest_api_id          = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  authorization_scopes = [local.required_auth_scope]
}

resource "aws_api_gateway_integration" "sith_lambda" {
  http_method             = aws_api_gateway_method.sith_get.http_method
  resource_id             = aws_api_gateway_resource.sith.id
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sith_node.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke_sith" {
  statement_id  = "AllowAPIGatewayInvokeSith"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sith_node.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/GET/sith"
}

# -------------------------------------------------------------------------------
# WAF Log to Bedrock Resource, Method, And Lambda Proxy Integration
# -------------------------------------------------------------------------------
resource "aws_api_gateway_resource" "waf_bedrock_analyzer" {
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id

  # Rename path with Star Wars theme after updating references in scripts/code.
  path_part = "analyze"

}

resource "aws_api_gateway_method" "waf_bedrock_analyzer_post" {
  rest_api_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.waf_bedrock_analyzer.id
  http_method   = "POST"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "waf_bedrock_analyzer_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.waf_bedrock_analyzer.id
  http_method             = aws_api_gateway_method.waf_bedrock_analyzer_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.waf_bedrock_analyzer.invoke_arn

}

resource "aws_lambda_permission" "apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_bedrock_analyzer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/POST/analyze"

}


# -------------------------------------------------------------------------------
# REST API Deployment
# -------------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "chewbacca_auth_rest" {
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  description = "Protected Jedi and Sith routes with Cognito authorization and WAF log analysis"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_authorizer.cognito.id,
      aws_api_gateway_resource.jedi.id,
      aws_api_gateway_method.jedi_get.id,
      aws_api_gateway_integration.jedi_lambda.id,
      aws_api_gateway_resource.sith.id,
      aws_api_gateway_method.sith_get.id,
      aws_api_gateway_integration.sith_lambda.id,

      aws_api_gateway_resource.waf_bedrock_analyzer.id,
      aws_api_gateway_method.waf_bedrock_analyzer_post.id,
      aws_api_gateway_integration.waf_bedrock_analyzer_lambda.id

    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.jedi_lambda,
    aws_api_gateway_integration.sith_lambda,
    aws_api_gateway_integration.waf_bedrock_analyzer_lambda
  ]
}
# -------------------------------------------------------------------------------
# REST API Prod Stage
# -------------------------------------------------------------------------------
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.chewbacca_auth_rest.id
  rest_api_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  stage_name    = "prod"

  # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access.arn
    format = jsonencode({
      requestId         = "$context.requestId",
      extendedRequestId = "$context.extendedRequestId",
      ip                = "$context.identity.sourceIp",
      caller            = "$context.identity.caller",
      user              = "$context.identity.user",
      requestTime       = "$context.requestTime",
      httpMethod        = "$context.httpMethod",
      resourcePath      = "$context.resourcePath",
      status            = "$context.status",
      protocol          = "$context.protocol",
      responseLength    = "$context.responseLength"
    })
  }

  depends_on = [aws_api_gateway_account.current]
}

resource "aws_api_gateway_method_settings" "prod" {
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    data_trace_enabled = false
    logging_level      = "INFO"
    metrics_enabled    = true
  }
}

# -------------------------------------------------------------------------------
# API Gateway Account-Level CloudWatch Role
# -------------------------------------------------------------------------------
resource "aws_api_gateway_account" "current" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch_logs]
}