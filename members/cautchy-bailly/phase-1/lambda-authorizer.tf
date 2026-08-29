# [lab12]
# /analyze Lambda authorizer (edge RBAC)
#
# A REQUEST authorizer that admits only members of the admins
# group, evaluated BEFORE the analyzer is invoked. A denied
# caller never triggers the analyzer Lambda, so the invocation
# and its Bedrock/DynamoDB cost are avoided entirely - the point
# of moving this check to the edge.
#
# This authorizer validates the token itself (RS256 against the
# pool JWKS), because a route uses ONE authorizer, not two: with
# a custom authorizer on /analyze, the built-in Cognito
# validation is not also in the path. cryptography is not in the
# runtime, so it ships as a layer.

data "archive_file" "authorizer_layer" {
  type        = "zip"
  source_dir  = "${path.module}/layers/authorizer"
  output_path = "${path.module}/build/authorizer-layer.zip"
}

resource "aws_lambda_layer_version" "authorizer" {
  layer_name          = "${var.project}-authorizer-deps"
  description         = "cryptography for JWT RS256 verification"
  filename            = data.archive_file.authorizer_layer.output_path
  source_code_hash    = data.archive_file.authorizer_layer.output_base64sha256
  compatible_runtimes = ["python3.13"]
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/src/authorizer"
  output_path = "${path.module}/build/authorizer.zip"
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${var.project}-admin-authorizer"
  role             = aws_iam_role.authorizer_role.arn
  handler          = "authorizer.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  timeout          = 10
  memory_size      = 256

  layers = [aws_lambda_layer_version.authorizer.arn]

  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.pool.id
      ADMIN_GROUP  = "admins"
      # AWS_REGION is a reserved runtime variable, already present - do not set.
    }
  }

  depends_on = [aws_cloudwatch_log_group.authorizer]
}

# API Gateway authorizer resource
#
# type REQUEST so the function receives the raw Authorization
# header (and could see other request context if ever needed).
# identity_source makes the header the cache key, so repeated
# calls with the same token skip re-invocation for the TTL.

resource "aws_api_gateway_authorizer" "admin" {
  name                             = "${var.project}-admin-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  type                             = "REQUEST"
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials           = aws_iam_role.authorizer_invoke.arn
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}

# Permission + invoke role

resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/authorizers/*"
}

# API Gateway assumes this role to call the authorizer function.
resource "aws_iam_role" "authorizer_invoke" {
  name = "${var.project}_authorizer_invoke"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "authorizer_invoke" {
  name = "${var.project}_authorizer_invoke"
  role = aws_iam_role.authorizer_invoke.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.authorizer.arn
    }]
  })
}

# Execution role for the authorizer itself
#
# Logging only. It reaches the pool JWKS over the public
# internet, which needs no IAM.

resource "aws_iam_role" "authorizer_role" {
  name               = "${var.project}_authorizer_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "authorizer_basic" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
