# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api#terraform-resources
# this one has all of the need code for api rest gateway

############################
# API Gateway - REST API
###########################

resource "aws_api_gateway_rest_api" "seir_api" {
  name        = "seir-api"
  description = "REST API protected by AWS WAF"

  endpoint_configuration {

    types = ["REGIONAL"]
  }
}

############
# Resource
############

resource "aws_api_gateway_resource" "seir_analyze" {
  rest_api_id = aws_api_gateway_rest_api.seir_api.id
  parent_id   = aws_api_gateway_rest_api.seir_api.root_resource_id
  path_part   = "seir_analyze"
}

################
# POST Method
################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method

resource "aws_api_gateway_method" "seir_post" {
  rest_api_id          = aws_api_gateway_rest_api.seir_api.id
  resource_id          = aws_api_gateway_resource.seir_analyze.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.seir_pass.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
}

######################
# Lambda Integration
######################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration

resource "aws_api_gateway_integration" "seir_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.seir_api.id
  resource_id             = aws_api_gateway_resource.seir_analyze.id
  http_method             = aws_api_gateway_method.seir_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.waf_bedrock_analyzer.invoke_arn
}

################
# Deployment
################

resource "aws_api_gateway_deployment" "seir_deployment" {
  rest_api_id = aws_api_gateway_rest_api.seir_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.seir_analyze.id,
      aws_api_gateway_method.seir_post.id,
      aws_api_gateway_integration.seir_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


##############################################################
# Stage
##############################################################

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.seir_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.seir_api.id
  stage_name    = "prod"
}

##############################################################
# Lambda Permission
##############################################################

resource "aws_lambda_permission" "apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_bedrock_analyzer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.seir_api.execution_arn}/*/*"
}