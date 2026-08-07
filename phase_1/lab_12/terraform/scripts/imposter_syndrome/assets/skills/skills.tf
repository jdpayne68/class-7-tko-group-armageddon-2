# ================================================================
# TERRAFORM SKILL DEFINITIONS
#
# AI AGENT GENERATED
#
# Canonical RESOURCE/DATA -> SKILL mappings used by
# the Imposter Syndrome scanner.
#
# Each active resource or data block has two or three #SKILL tags:
# service/product, capability, and optional workflow context.
# Do not scan this file as student Terraform.
# ================================================================

#SKILL: Terraform
#SKILL: Terraform Helpers
resource "random_string" "suffix" {
  length  = 3
  special = false
  upper   = false
}

#SKILL: Terraform
#SKILL: Terraform Helpers
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

#SKILL: AWS Account
#SKILL: Account Discovery
data "aws_region" "current" {}

#SKILL: AWS Account
#SKILL: Account Discovery
data "aws_caller_identity" "current" {}

#SKILL: AWS Account
#SKILL: Account Discovery
data "aws_partition" "current" {}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
resource "aws_iam_policy" "route_lambda_token_update" {
  name        = "${local.name_prefix}-route-token-update-${local.name_suffix}"
  description = "Allows the Jedi and Sith route Lambdas to mark token records as used"
  policy      = data.aws_iam_policy_document.route_lambda_token_update.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
data "aws_iam_policy_document" "route_lambda_token_update" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.token_holocron.arn]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Security Automation
resource "aws_iam_policy" "token_detector_scan" {
  name        = "${local.name_prefix}-token-detector-scan-${local.name_suffix}"
  description = "Allows the unused-token detector Lambda to scan token records"
  policy      = data.aws_iam_policy_document.token_detector_scan.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Security Automation
data "aws_iam_policy_document" "token_detector_scan" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.token_holocron.arn]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Amazon Bedrock
resource "aws_iam_policy" "waf_bedrock_analyzer" {
  name        = "${local.name_prefix}-waf-bedrock-analyzer-policy-${local.name_suffix}"
  description = "Allows WAF log analyzer Lambda to filter CloudWatch logs, invoke Bedrock models, and store WAF events in DynamoDB"
  policy      = data.aws_iam_policy_document.waf_bedrock_analyzer.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Amazon Bedrock
data "aws_iam_policy_document" "waf_bedrock_analyzer" {
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = local.bedrock_invoke_resources
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.shield_generator_events.arn]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Threat Correlation
resource "aws_iam_policy" "waf_threat_correlation_agent" {
  name        = "${local.name_prefix}-waf-threat-correlation-agent-policy-${local.name_suffix}"
  description = "Allows WAF threat correlation agent Lambda to read CloudWatch logs, query WAF events from DynamoDB, write correlation findings, and invoke Bedrock models"
  policy      = data.aws_iam_policy_document.waf_threat_correlation_agent.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Threat Correlation
data "aws_iam_policy_document" "waf_threat_correlation_agent" {
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem"
    ]
    resources = [
      aws_dynamodb_table.shield_generator_events.arn,
      "${aws_dynamodb_table.shield_generator_events.arn}/index/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.waf_correlation_findings.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = local.bedrock_invoke_resources
  }
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = ["*"]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
resource "aws_iam_policy" "scheduler_invoke_detector" {
  name        = "${local.name_prefix}-scheduler-invoke-detector-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the unused-token detector"
  policy      = data.aws_iam_policy_document.scheduler_invoke_detector.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
data "aws_iam_policy_document" "scheduler_invoke_detector" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.unused_token_detector.arn]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
resource "aws_iam_policy" "scheduler_invoke_analyzer" {
  name        = "${local.name_prefix}-scheduler-invoke-analyzer-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the WAF Bedrock analyzer"
  policy      = data.aws_iam_policy_document.scheduler_invoke_analyzer.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
data "aws_iam_policy_document" "scheduler_invoke_analyzer" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.waf_bedrock_analyzer.arn]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Threat Correlation
resource "aws_iam_policy" "scheduler_invoke_correlation" {
  name        = "${local.name_prefix}-scheduler-invoke-correlation-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the threat correlation agent"
  policy      = data.aws_iam_policy_document.scheduler_invoke_correlation.json
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Threat Correlation
data "aws_iam_policy_document" "scheduler_invoke_correlation" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.waf_threat_correlation_agent.arn]
  }
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
resource "aws_iam_policy" "lambda_application_signals_execution_role" {
  name        = "${local.name_prefix}-appsignals-policy-${local.name_suffix}"
  description = "Allows Lambda to write X-Ray trace segments and create CloudWatch log streams for Application Signals telemetry data"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchApplicationSignalsXrayWritePermissions"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments"
        ]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "CloudWatchApplicationSignalsLogGroupWritePermissions"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/application-signals/data:*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Protected API Routes
resource "aws_iam_role" "jedi_python_role" {
  name               = "${local.name_prefix}-lambda-python-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Jedi Python Lambda"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Protected API Routes
resource "aws_iam_role_policy_attachment" "jedi_python_basic_execution" {
  role       = aws_iam_role.jedi_python_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Protected API Routes
resource "aws_iam_role_policy_attachment" "jedi_python_token_update" {
  role       = aws_iam_role.jedi_python_role.name
  policy_arn = aws_iam_policy.route_lambda_token_update.arn
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Protected API Routes
resource "aws_iam_role" "sith_node_role" {
  name               = "${local.name_prefix}-lambda-node-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Sith Node.js Lambda"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Protected API Routes
resource "aws_iam_role_policy_attachment" "sith_node_basic_execution" {
  role       = aws_iam_role.sith_node_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Protected API Routes
resource "aws_iam_role_policy_attachment" "sith_node_token_update" {
  role       = aws_iam_role.sith_node_role.name
  policy_arn = aws_iam_policy.route_lambda_token_update.arn
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Security Automation
resource "aws_iam_role" "unused_token_detector_role" {
  name               = "${local.name_prefix}-unused-token-detector-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the unused-token detector Lambda"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Security Automation
resource "aws_iam_role_policy_attachment" "unused_token_detector_basic_execution" {
  role       = aws_iam_role.unused_token_detector_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Security Automation
resource "aws_iam_role_policy_attachment" "unused_token_detector_scan" {
  role       = aws_iam_role.unused_token_detector_role.name
  policy_arn = aws_iam_policy.token_detector_scan.arn
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Amazon Bedrock
resource "aws_iam_role" "waf_bedrock_analyzer_role" {
  name               = "${local.name_prefix}-waf-bedrock-analyzer-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the WAF log forwarder Lambda"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Amazon Bedrock
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer_basic_execution" {
  role       = aws_iam_role.waf_bedrock_analyzer_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Amazon Bedrock
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer" {
  role       = aws_iam_role.waf_bedrock_analyzer_role.name
  policy_arn = aws_iam_policy.waf_bedrock_analyzer.arn
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Amazon Bedrock
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer_appsignals" {
  role       = aws_iam_role.waf_bedrock_analyzer_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Threat Correlation
resource "aws_iam_role" "waf_threat_correlation_agent_role" {
  name               = "${local.name_prefix}-waf-threat-correlation-agent-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the WAF threat correlation agent"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent_basic_execution" {
  role       = aws_iam_role.waf_threat_correlation_agent_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent" {
  role       = aws_iam_role.waf_threat_correlation_agent_role.name
  policy_arn = aws_iam_policy.waf_threat_correlation_agent.arn
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent_appsignals" {
  role       = aws_iam_role.waf_threat_correlation_agent_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

#SKILL: AWS IAM
#SKILL: IAM Roles
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name               = "${local.name_prefix}-api-gateway-cloudwatch-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
  description        = "Allows API Gateway to publish REST API logs to CloudWatch"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

#SKILL: AWS IAM
#SKILL: IAM Roles
resource "aws_iam_role" "scheduler_role" {
  name               = "${local.name_prefix}-scheduler-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
  description        = "Allows EventBridge Scheduler to invoke the detector Lambda"
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
resource "aws_iam_role_policy_attachment" "scheduler_invoke_detector" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_detector.arn
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "scheduler_invoke_correlation" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_correlation.arn
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
resource "aws_iam_role_policy_attachment" "scheduler_invoke_analyzer" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_analyzer.arn
}

#SKILL: Amazon Cognito
#SKILL: User Pools
resource "aws_cognito_user_pool" "chewbacca_auth_rest" {
  name                     = "${local.name_prefix}-users-${local.name_suffix}"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "ON"
  user_pool_tier           = "ESSENTIALS"
  username_configuration {
    case_sensitive = false
  }
  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD"]
  }
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  software_token_mfa_configuration {
    enabled = true
  }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "name"
    required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }
  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "birthdate"
    required            = true
    string_attribute_constraints {
      min_length = 10
      max_length = 10
    }
  }
  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "phone_number"
    required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }
}

#SKILL: Amazon Cognito
#SKILL: App Clients
resource "aws_cognito_user_pool_client" "public" {
  name                                 = "${local.name_prefix}-public-client-${local.name_suffix}"
  user_pool_id                         = aws_cognito_user_pool.chewbacca_auth_rest.id
  generate_secret                      = false
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  auth_session_validity                = 5
  access_token_validity                = 15
  id_token_validity                    = 15
  refresh_token_validity               = 1
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", local.required_auth_scope]
  callback_urls                        = [var.callback_url]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

#SKILL: Amazon Cognito
#SKILL: App Clients
resource "aws_cognito_user_pool_client" "cli" {
  name                                 = "${local.name_prefix}-cli-client-${local.name_suffix}"
  user_pool_id                         = aws_cognito_user_pool.chewbacca_auth_rest.id
  generate_secret                      = true
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  auth_session_validity                = 5
  access_token_validity                = 15
  id_token_validity                    = 15
  refresh_token_validity               = 1
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", local.required_auth_scope]
  callback_urls                        = [var.callback_url]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

#SKILL: Amazon Cognito
#SKILL: Hosted UI Domains
resource "aws_cognito_user_pool_domain" "chewbacca_auth_rest" {
  domain                = "${local.name_prefix}-${local.name_suffix}"
  user_pool_id          = aws_cognito_user_pool.chewbacca_auth_rest.id
  managed_login_version = 2
}

#SKILL: Amazon Cognito
#SKILL: Managed Login Branding
resource "aws_cognito_managed_login_branding" "public" {
  client_id                   = aws_cognito_user_pool_client.public.id
  user_pool_id                = aws_cognito_user_pool.chewbacca_auth_rest.id
  use_cognito_provided_values = true
  depends_on                  = [aws_cognito_user_pool_domain.chewbacca_auth_rest]
}

#SKILL: Amazon Cognito
#SKILL: Managed Login Branding
resource "aws_cognito_managed_login_branding" "cli" {
  client_id                   = aws_cognito_user_pool_client.cli.id
  user_pool_id                = aws_cognito_user_pool.chewbacca_auth_rest.id
  use_cognito_provided_values = true
  depends_on                  = [aws_cognito_user_pool_domain.chewbacca_auth_rest]
}

#SKILL: Amazon Cognito
#SKILL: User Provisioning
resource "aws_cognito_user" "chewbacca" {
  user_pool_id   = aws_cognito_user_pool.chewbacca_auth_rest.id
  username       = var.test_username
  password       = var.test_user_password
  enabled        = true
  message_action = "SUPPRESS"
  attributes = {
    birthdate             = var.test_user_birthdate
    email                 = var.test_user_email
    email_verified        = true
    name                  = "Chewbacca Raaawr"
    phone_number          = var.test_user_phone_number
    phone_number_verified = true
  }
}

#SKILL: Amazon API Gateway
#SKILL: REST API Definition
resource "aws_api_gateway_rest_api" "chewbacca_auth_rest_api" {
  name        = "${local.name_prefix}-api-${local.name_suffix}"
  description = "REST API prote4cted by AWS Cognito and WAF"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

#SKILL: Amazon API Gateway
#SKILL: API Authorization
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.name_prefix}-cognito-authorizer-${local.name_suffix}"
  rest_api_id     = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.chewbacca_auth_rest.arn]
  identity_source = "method.request.header.Authorization"
}

#SKILL: Amazon API Gateway
#SKILL: API Resource Routing
#SKILL: Protected API Routes
resource "aws_api_gateway_resource" "jedi" {
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id
  path_part   = "jedi"
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
}

#SKILL: Amazon API Gateway
#SKILL: API Methods
#SKILL: Protected API Routes
resource "aws_api_gateway_method" "jedi_get" {
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  http_method          = "GET"
  resource_id          = aws_api_gateway_resource.jedi.id
  rest_api_id          = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  authorization_scopes = [local.required_auth_scope]
}

#SKILL: Amazon API Gateway
#SKILL: API Lambda Integrations
#SKILL: Protected API Routes
resource "aws_api_gateway_integration" "jedi_lambda" {
  http_method             = aws_api_gateway_method.jedi_get.http_method
  resource_id             = aws_api_gateway_resource.jedi.id
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.jedi_python.invoke_arn
}

#SKILL: AWS Lambda
#SKILL: Lambda Invocation Permissions
#SKILL: Protected API Routes
resource "aws_lambda_permission" "api_gateway_invoke_jedi" {
  statement_id  = "AllowAPIGatewayInvokeJedi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jedi_python.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/GET/jedi"
}

#SKILL: Amazon API Gateway
#SKILL: API Resource Routing
#SKILL: Protected API Routes
resource "aws_api_gateway_resource" "sith" {
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id
  path_part   = "sith"
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
}

#SKILL: Amazon API Gateway
#SKILL: API Methods
#SKILL: Protected API Routes
resource "aws_api_gateway_method" "sith_get" {
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  http_method          = "GET"
  resource_id          = aws_api_gateway_resource.sith.id
  rest_api_id          = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  authorization_scopes = [local.required_auth_scope]
}

#SKILL: Amazon API Gateway
#SKILL: API Lambda Integrations
#SKILL: Protected API Routes
resource "aws_api_gateway_integration" "sith_lambda" {
  http_method             = aws_api_gateway_method.sith_get.http_method
  resource_id             = aws_api_gateway_resource.sith.id
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sith_node.invoke_arn
}

#SKILL: AWS Lambda
#SKILL: Lambda Invocation Permissions
#SKILL: Protected API Routes
resource "aws_lambda_permission" "api_gateway_invoke_sith" {
  statement_id  = "AllowAPIGatewayInvokeSith"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sith_node.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/GET/sith"
}

#SKILL: Amazon API Gateway
#SKILL: API Resource Routing
#SKILL: Amazon Bedrock
resource "aws_api_gateway_resource" "waf_bedrock_analyzer" {
  rest_api_id = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  parent_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.root_resource_id
  path_part   = "analyze"
}

#SKILL: Amazon API Gateway
#SKILL: API Methods
#SKILL: Amazon Bedrock
resource "aws_api_gateway_method" "waf_bedrock_analyzer_post" {
  rest_api_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  resource_id   = aws_api_gateway_resource.waf_bedrock_analyzer.id
  http_method   = "POST"
  authorization = "NONE"
}

#SKILL: Amazon API Gateway
#SKILL: API Lambda Integrations
#SKILL: Amazon Bedrock
resource "aws_api_gateway_integration" "waf_bedrock_analyzer_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  resource_id             = aws_api_gateway_resource.waf_bedrock_analyzer.id
  http_method             = aws_api_gateway_method.waf_bedrock_analyzer_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.waf_bedrock_analyzer.invoke_arn
}

#SKILL: AWS Lambda
#SKILL: Lambda Invocation Permissions
resource "aws_lambda_permission" "apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_bedrock_analyzer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chewbacca_auth_rest_api.execution_arn}/*/POST/analyze"
}

#SKILL: Amazon API Gateway
#SKILL: API Deployments
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

#SKILL: Amazon API Gateway
#SKILL: API Stages
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.chewbacca_auth_rest.id
  rest_api_id   = aws_api_gateway_rest_api.chewbacca_auth_rest_api.id
  stage_name    = "prod"
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

#SKILL: Amazon API Gateway
#SKILL: REST APIs
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

#SKILL: Amazon API Gateway
#SKILL: API Logging Configuration
resource "aws_api_gateway_account" "current" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
  depends_on          = [aws_iam_role_policy_attachment.api_gateway_cloudwatch_logs]
}

#SKILL: Amazon DynamoDB
#SKILL: NoSQL Tables
resource "aws_dynamodb_table" "token_holocron" {
  name         = local.token_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "token_id"
  attribute {
    name = "token_id"
    type = "S"
  }
  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }
}

#SKILL: Amazon DynamoDB
#SKILL: NoSQL Tables
resource "aws_dynamodb_table" "shield_generator_events" {
  name         = local.waf_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  attribute {
    name = "event_id"
    type = "S"
  }
  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }
}

#SKILL: Amazon DynamoDB
#SKILL: NoSQL Tables
#SKILL: Threat Correlation
resource "aws_dynamodb_table" "waf_correlation_findings" {
  name         = local.waf_correlation_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "finding_id"
  attribute {
    name = "finding_id"
    type = "S"
  }
  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }
}

#SKILL: Terraform
#SKILL: Lambda Packaging
#SKILL: Protected API Routes
data "archive_file" "jedi_python" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/jedi_python"
  output_path = "${path.module}/lambda/src/jedi-python.zip"
  excludes = [
    "test_events/**",
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Protected API Routes
resource "aws_lambda_function" "jedi_python" {
  filename         = data.archive_file.jedi_python.output_path
  source_code_hash = data.archive_file.jedi_python.output_base64sha256
  function_name    = local.jedi_function_name
  description      = "Protected Python route for the Cognito REST auth-flow lab"
  role             = aws_iam_role.jedi_python_role.arn
  handler          = "jedi-python.lambda_handler"
  runtime          = "python3.14"
  memory_size      = 128
  timeout          = 10
  environment {
    variables = {
      TOKEN_TABLE_NAME = aws_dynamodb_table.token_holocron.name
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.jedi_python,
    aws_iam_role_policy_attachment.jedi_python_basic_execution,
    aws_iam_role_policy_attachment.jedi_python_token_update,
  ]
}

#SKILL: Terraform
#SKILL: Lambda Packaging
#SKILL: Protected API Routes
data "archive_file" "sith_node" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/sith_node"
  output_path = "${path.module}/lambda/src/sith-node.zip"
  excludes = [
    "test_events/**",
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Protected API Routes
resource "aws_lambda_function" "sith_node" {
  filename         = data.archive_file.sith_node.output_path
  source_code_hash = data.archive_file.sith_node.output_base64sha256
  function_name    = local.sith_function_name
  description      = "Protected Node.js route for the Cognito REST auth-flow lab"
  role             = aws_iam_role.sith_node_role.arn
  handler          = "sith-node.handler"
  runtime          = "nodejs24.x"
  memory_size      = 128
  timeout          = 10
  environment {
    variables = {
      TOKEN_TABLE_NAME = aws_dynamodb_table.token_holocron.name
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.sith_node,
    aws_iam_role_policy_attachment.sith_node_basic_execution,
    aws_iam_role_policy_attachment.sith_node_token_update,
  ]
}

#SKILL: Terraform
#SKILL: Lambda Packaging
#SKILL: Security Automation
data "archive_file" "unused_token_detector" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/unused_token_detector"
  output_path = "${path.module}/lambda/src/unused-token-detector.zip"
  excludes = [
    "test_events/**",
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Security Automation
resource "aws_lambda_function" "unused_token_detector" {
  filename         = data.archive_file.unused_token_detector.output_path
  source_code_hash = data.archive_file.unused_token_detector.output_base64sha256
  function_name    = local.token_detector_function_name
  description      = "Scans token records and logs alerts for tokens that have not been used"
  role             = aws_iam_role.unused_token_detector_role.arn
  handler          = "unused-token-detector.lambda_handler"
  runtime          = "python3.14"
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
      TOKEN_TABLE_NAME     = aws_dynamodb_table.token_holocron.name
      TOKEN_UNUSED_MINUTES = tostring(var.token_unused_minutes)
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.unused_token_detector,
    aws_iam_role_policy_attachment.unused_token_detector_basic_execution,
    aws_iam_role_policy_attachment.unused_token_detector_scan,
  ]
}

#SKILL: Terraform
#SKILL: Lambda Packaging
#SKILL: Amazon Bedrock
data "archive_file" "waf_bedrock_analyzer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/waf_bedrock_analyzer"
  output_path = "${path.module}/lambda/src/waf-bedrock-analyzer.zip"
  excludes = [
    "test_events/**",
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Amazon Bedrock
resource "aws_lambda_function" "waf_bedrock_analyzer" {
  filename         = data.archive_file.waf_bedrock_analyzer.output_path
  source_code_hash = data.archive_file.waf_bedrock_analyzer.output_base64sha256
  function_name    = local.waf_bedrock_analyzer_function_name
  description      = "Reads WAF logs and sends to Bedrock for analysis"
  role             = aws_iam_role.waf_bedrock_analyzer_role.arn
  handler          = "waf-bedrock-analyzer.lambda_handler"
  runtime          = "python3.14"
  memory_size      = 128
  timeout          = var.bedrock_lambda_timeout
  layers = [
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]
  environment {
    variables = {
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE   = aws_dynamodb_table.shield_generator_events.name
      BEDROCK_MODEL_ID = local.bedrock_model_id
      LOOKBACK_MINUTES = 10
      MAX_LOG_EVENTS   = 25
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.waf_bedrock_analyzer,
    aws_iam_role_policy_attachment.waf_bedrock_analyzer_basic_execution,
    aws_iam_role_policy_attachment.waf_bedrock_analyzer,
    aws_iam_role_policy_attachment.waf_bedrock_analyzer_appsignals,
  ]
}

#SKILL: Terraform
#SKILL: Lambda Packaging
#SKILL: Threat Correlation
data "archive_file" "waf_threat_correlation_agent" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/waf_threat_correlation_agent"
  output_path = "${path.module}/lambda/src/waf-threat-correlation-agent.zip"
  excludes = [
    "test_events/**",
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Threat Correlation
resource "aws_lambda_function" "waf_threat_correlation_agent" {
  filename         = data.archive_file.waf_threat_correlation_agent.output_path
  source_code_hash = data.archive_file.waf_threat_correlation_agent.output_base64sha256
  function_name    = local.waf_bedrock_threat_correlation_agent_name
  description      = "Reads WAF logs and sends to Bedrock for analysis"
  role             = aws_iam_role.waf_threat_correlation_agent_role.arn
  handler          = "waf-threat-correlation-agent.lambda_handler"
  runtime          = "python3.14"
  memory_size      = 128
  timeout          = var.bedrock_lambda_timeout
  layers = [
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]
  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.shield_generator_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      BEDROCK_MODEL_ID           = local.bedrock_model_id
      CORRELATION_WINDOW_MINUTES = "60"
      MINIMUM_EVENT_COUNT        = "3"
      MAX_EVENTS                 = "500"
      ADMIN_URI_KEYWORDS         = "admin,login,signin,auth,token,cognito"
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.waf_logs,
    aws_iam_role_policy_attachment.waf_threat_correlation_agent_basic_execution,
    aws_iam_role_policy_attachment.waf_threat_correlation_agent,
  ]
}

#SKILL: Amazon EventBridge Scheduler
#SKILL: Scheduled Invocations
#SKILL: Security Automation
resource "aws_scheduler_schedule" "unused_token_check" {
  name                = "${local.name_prefix}-unused-token-check${local.name_suffix}"
  description         = "Checks for unused Cognito tokens every 5 minutes"
  schedule_expression = var.token_scan_schedule
  state               = "ENABLED"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.unused_token_detector.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ source = "eventbridge-scheduler" })
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_detector]
}

#SKILL: Amazon EventBridge Scheduler
#SKILL: Scheduled Invocations
#SKILL: Amazon Bedrock
resource "aws_scheduler_schedule" "waf_bedrock_analyzer" {
  name                = "${local.name_prefix}-waf-bedrock-analyzer${local.name_suffix}"
  description         = "Runs WAF log analysis every 5 minutes"
  schedule_expression = "rate(5 minutes)"
  state               = "ENABLED"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.waf_bedrock_analyzer.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ source = "eventbridge-scheduler" })
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_analyzer]
}

#SKILL: Amazon EventBridge Scheduler
#SKILL: Scheduled Invocations
#SKILL: Threat Correlation
resource "aws_scheduler_schedule" "threat_correlation" {
  name                = "${local.name_prefix}-threat-correlation${local.name_suffix}"
  description         = "Runs WAF threat correlation every 5 minutes"
  schedule_expression = "rate(5 minutes)"
  state               = "ENABLED"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.waf_threat_correlation_agent.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ source = "eventbridge-scheduler" })
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_correlation]
}

#SKILL: AWS WAF
#SKILL: Managed Rule Groups
resource "aws_wafv2_web_acl" "shield_generator" {
  name        = "${local.name_prefix}-shield-generator-waf-${local.name_suffix}"
  description = "Regional Web ACL protecting API Gateways"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 0
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-sqli-rule-set-${local.name_suffix}"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "RateLimitRule"
    priority = 1
    action {
      count {}
    }
    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-rate-limit-${local.name_suffix}"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-common-rule-set-${local.name_suffix}"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-known-bad-inputs-${local.name_suffix}"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-anonymous-ip-list-${local.name_suffix}"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-api-waf-${local.name_suffix}"
    sampled_requests_enabled   = true
  }
}

#SKILL: AWS WAF
#SKILL: Web ACL Associations
resource "aws_wafv2_web_acl_association" "api_gateway_prod" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.shield_generator.arn
}

#SKILL: AWS WAF
#SKILL: WAF Log Delivery
resource "aws_wafv2_web_acl_logging_configuration" "api_gateway" {
  resource_arn = aws_wafv2_web_acl.shield_generator.arn
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_logs.arn
  ]
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: Protected API Routes
resource "aws_cloudwatch_log_group" "jedi_python" {
  name              = "/aws/lambda/${local.jedi_function_name}"
  retention_in_days = var.log_retention_days
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: Protected API Routes
resource "aws_cloudwatch_log_group" "sith_node" {
  name              = "/aws/lambda/${local.sith_function_name}"
  retention_in_days = var.log_retention_days
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: Security Automation
resource "aws_cloudwatch_log_group" "unused_token_detector" {
  name              = "/aws/lambda/${local.token_detector_function_name}"
  retention_in_days = var.log_retention_days
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: Amazon Bedrock
resource "aws_cloudwatch_log_group" "waf_bedrock_analyzer" {
  name              = "/aws/lambda/${local.waf_bedrock_analyzer_function_name}"
  retention_in_days = var.log_retention_days
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
resource "aws_cloudwatch_log_group" "api_gateway_access" {
  name              = "/aws/apigateway/${local.name_prefix}-api-${local.name_suffix}/prod/access"
  retention_in_days = var.log_retention_days
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: WAF Telemetry
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${local.name_prefix}-${local.name_suffix}/api-gateway-waf"
  retention_in_days = var.log_retention_days
}

#SKILL: Amazon CloudWatch
#SKILL: Log Resource Policies
#SKILL: WAF Telemetry
resource "aws_cloudwatch_log_resource_policy" "cloudwatch_waf_log_delivery" {
  policy_document = data.aws_iam_policy_document.cloudwatch_waf_log_delivery.json
  policy_name     = "${local.name_prefix}-cloudwatch-waf-log-delivery-${local.name_suffix}"
}

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
#SKILL: WAF Telemetry
data "aws_iam_policy_document" "cloudwatch_waf_log_delivery" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.waf_logs.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${local.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}

#SKILL: Amazon CloudWatch
#SKILL: Log Metric Filters
#SKILL: Security Automation
resource "aws_cloudwatch_log_metric_filter" "unused_token" {
  name           = "${local.name_prefix}-unused-token-filter-${local.name_suffix}"
  pattern        = "\"ALERT: Token unused\""
  log_group_name = aws_cloudwatch_log_group.unused_token_detector.name
  metric_transformation {
    name          = "UnusedTokenAlert"
    namespace     = "${local.name_prefix}/TokenDetector-${local.name_suffix}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

#SKILL: Amazon CloudWatch
#SKILL: Metric Alarms
#SKILL: Security Automation
resource "aws_cloudwatch_metric_alarm" "unused_token" {
  alarm_name          = "${local.name_prefix}-unused-token-alarm-${local.name_suffix}"
  alarm_description   = "Detector found at least one token record that was never used"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "UnusedTokenAlert"
  namespace           = "${local.name_prefix}/TokenDetector-${local.name_suffix}"
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.token_alerts.arn]
  depends_on          = [aws_cloudwatch_log_metric_filter.unused_token]
}

#SKILL: Amazon SNS
#SKILL: Notification Topics
resource "aws_sns_topic" "token_alerts" {
  name              = "${local.name_prefix}-auth-alerts-${local.name_suffix}"
  kms_master_key_id = "alias/aws/sns"
}

#SKILL: Amazon SNS
#SKILL: Topic Subscriptions
resource "aws_sns_topic_subscription" "token_alert_emails" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.token_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}
