##############################################################
# API Gateway - REST API
##############################################################

resource "aws_api_gateway_rest_api" "chewbacca_auth_rest_api" {
  name = "${var.project_name}-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

##############################################################
# Resource
##############################################################

resource "aws_api_gateway_resource" "analyze" {
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id
  path_part   = "analyze"
}

##############################################################
# POST Method
##############################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.analyze.id
  http_method   = "GET"
  authorization = "NONE"
}

###############################################################
#Lambda Integration
###############################################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration

resource "aws_api_gateway_integration" "application" {
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.analyze.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.application.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowApiGatewayInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.application.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/*"
}