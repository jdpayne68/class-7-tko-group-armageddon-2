# ================================================================
# IMPOSTER SYNDROME SKILL DEFINITIONS
# ================================================================
#
# Generated from active Terraform resource and data blocks.
# Edit this file when the lab architecture changes.
#
# Terraform directory: phase_1/lab_12/terraform

# -------------------------------------------------------------------
# 02-helper-resources.tf
# -------------------------------------------------------------------

#SKILL: Terraform
#SKILL: Terraform Helpers
resource "random_string" "suffix" {
}

#SKILL: Terraform
#SKILL: Terraform Helpers
resource "random_id" "bucket_suffix" {
}

# -------------------------------------------------------------------
# 03-helper-data.tf
# -------------------------------------------------------------------

#SKILL: AWS Account
#SKILL: Account Discovery
data "aws_region" "current" {
}

#SKILL: AWS Account
#SKILL: Account Discovery
data "aws_caller_identity" "current" {
}

#SKILL: AWS Account
#SKILL: Account Discovery
data "aws_partition" "current" {
}

# -------------------------------------------------------------------
# 10-iam-policies.tf
# -------------------------------------------------------------------

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Protected API Routes
resource "aws_iam_policy" "route_lambda_token_update" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Protected API Routes
data "aws_iam_policy_document" "route_lambda_token_update" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Token Security
resource "aws_iam_policy" "token_detector_scan" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Token Security
data "aws_iam_policy_document" "token_detector_scan" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Amazon Bedrock
resource "aws_iam_policy" "waf_bedrock_analyzer" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Amazon Bedrock
data "aws_iam_policy_document" "waf_bedrock_analyzer" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Threat Correlation
resource "aws_iam_policy" "waf_threat_correlation_agent" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Threat Correlation
data "aws_iam_policy_document" "waf_threat_correlation_agent" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Security Automation
resource "aws_iam_policy" "scheduler_invoke_detector" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Security Automation
data "aws_iam_policy_document" "scheduler_invoke_detector" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Security Automation
resource "aws_iam_policy" "scheduler_invoke_analyzer" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Security Automation
data "aws_iam_policy_document" "scheduler_invoke_analyzer" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Threat Correlation
resource "aws_iam_policy" "scheduler_invoke_correlation" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: Threat Correlation
data "aws_iam_policy_document" "scheduler_invoke_correlation" {
}

#SKILL: AWS IAM
#SKILL: IAM Managed Policies
#SKILL: Least Privilege Design
resource "aws_iam_policy" "lambda_application_signals_execution_role" {
}

# -------------------------------------------------------------------
# 11-iam-roles.tf
# -------------------------------------------------------------------

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
#SKILL: Least Privilege Design
data "aws_iam_policy_document" "lambda_assume_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Least Privilege Design
resource "aws_iam_role" "jedi_python_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Least Privilege Design
resource "aws_iam_role_policy_attachment" "jedi_python_basic_execution" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Least Privilege Design
resource "aws_iam_role_policy_attachment" "jedi_python_token_update" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Least Privilege Design
resource "aws_iam_role" "sith_node_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Least Privilege Design
resource "aws_iam_role_policy_attachment" "sith_node_basic_execution" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Least Privilege Design
resource "aws_iam_role_policy_attachment" "sith_node_token_update" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Token Security
resource "aws_iam_role" "unused_token_detector_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Token Security
resource "aws_iam_role_policy_attachment" "unused_token_detector_basic_execution" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Token Security
resource "aws_iam_role_policy_attachment" "unused_token_detector_scan" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Amazon Bedrock
resource "aws_iam_role" "waf_bedrock_analyzer_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Amazon Bedrock
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer_basic_execution" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Amazon Bedrock
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Amazon Bedrock
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer_appsignals" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Threat Correlation
resource "aws_iam_role" "waf_threat_correlation_agent_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent_basic_execution" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent_appsignals" {
}

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
#SKILL: Least Privilege Design
data "aws_iam_policy_document" "api_gateway_assume_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Least Privilege Design
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Least Privilege Design
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
}

#SKILL: AWS IAM
#SKILL: IAM Trust Policies
#SKILL: Security Automation
data "aws_iam_policy_document" "scheduler_assume_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Security Automation
resource "aws_iam_role" "scheduler_role" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Security Automation
resource "aws_iam_role_policy_attachment" "scheduler_invoke_detector" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Threat Correlation
resource "aws_iam_role_policy_attachment" "scheduler_invoke_correlation" {
}

#SKILL: AWS IAM
#SKILL: IAM Policy Attachments
#SKILL: Security Automation
resource "aws_iam_role_policy_attachment" "scheduler_invoke_analyzer" {
}

# -------------------------------------------------------------------
# 20-cognito.tf
# -------------------------------------------------------------------

#SKILL: Amazon Cognito
#SKILL: User Pools
#SKILL: Authentication
resource "aws_cognito_user_pool" "chewbacca_auth_rest" {
}

#SKILL: Amazon Cognito
#SKILL: App Clients
#SKILL: Authentication
resource "aws_cognito_user_pool_client" "public" {
}

#SKILL: Amazon Cognito
#SKILL: App Clients
#SKILL: Authentication
resource "aws_cognito_user_pool_client" "cli" {
}

#SKILL: Amazon Cognito
#SKILL: Authentication
resource "aws_cognito_user_pool_domain" "chewbacca_auth_rest" {
}

#SKILL: Amazon Cognito
#SKILL: Managed Login Branding
#SKILL: Authentication
resource "aws_cognito_managed_login_branding" "public" {
}

#SKILL: Amazon Cognito
#SKILL: Managed Login Branding
#SKILL: Authentication
resource "aws_cognito_managed_login_branding" "cli" {
}

#SKILL: Amazon Cognito
#SKILL: Test Users
#SKILL: Authentication
resource "aws_cognito_user" "chewbacca" {
}

# -------------------------------------------------------------------
# 30-api-gateway.tf
# -------------------------------------------------------------------

#SKILL: Amazon API Gateway
#SKILL: REST APIs
#SKILL: Serverless APIs
resource "aws_api_gateway_rest_api" "chewbacca_auth_rest_api" {
}

#SKILL: Amazon API Gateway
#SKILL: API Authorization
#SKILL: Protected API Routes
resource "aws_api_gateway_authorizer" "cognito" {
}

#SKILL: Amazon API Gateway
#SKILL: API Resource Routing
#SKILL: Serverless APIs
resource "aws_api_gateway_resource" "jedi" {
}

#SKILL: Amazon API Gateway
#SKILL: API Methods
#SKILL: Serverless APIs
resource "aws_api_gateway_method" "jedi_get" {
}

#SKILL: Amazon API Gateway
#SKILL: API Lambda Integrations
#SKILL: Serverless APIs
resource "aws_api_gateway_integration" "jedi_lambda" {
}

#SKILL: AWS Lambda
#SKILL: Lambda Invocation Permissions
#SKILL: Serverless Compute
resource "aws_lambda_permission" "api_gateway_invoke_jedi" {
}

#SKILL: Amazon API Gateway
#SKILL: API Resource Routing
#SKILL: Amazon Bedrock
resource "aws_api_gateway_resource" "waf_bedrock_analyzer" {
}

#SKILL: Amazon API Gateway
#SKILL: API Methods
#SKILL: Amazon Bedrock
resource "aws_api_gateway_method" "waf_bedrock_analyzer_post" {
}

#SKILL: Amazon API Gateway
#SKILL: API Lambda Integrations
#SKILL: Amazon Bedrock
resource "aws_api_gateway_integration" "waf_bedrock_analyzer_lambda" {
}

#SKILL: AWS Lambda
#SKILL: Lambda Invocation Permissions
#SKILL: Serverless Compute
resource "aws_lambda_permission" "apigateway" {
}

#SKILL: Amazon API Gateway
#SKILL: API Logging Configuration
#SKILL: Serverless APIs
resource "aws_api_gateway_account" "current" {
}

# -------------------------------------------------------------------
# 41-dynamodb.tf
# -------------------------------------------------------------------

#SKILL: Amazon DynamoDB
#SKILL: NoSQL Tables
resource "aws_dynamodb_table" "token_holocron" {
}

#SKILL: Amazon DynamoDB
#SKILL: NoSQL Tables
resource "aws_dynamodb_table" "shield_generator_events" {
}

#SKILL: Amazon DynamoDB
#SKILL: NoSQL Tables
#SKILL: Threat Correlation
resource "aws_dynamodb_table" "waf_correlation_findings" {
}

# -------------------------------------------------------------------
# 50-lambda.tf
# -------------------------------------------------------------------

#SKILL: Terraform
#SKILL: Lambda Packaging
data "archive_file" "jedi_python" {
}

#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Threat Correlation
resource "aws_lambda_function" "waf_threat_correlation_agent" {
}

# -------------------------------------------------------------------
# 60-eventbridge.tf
# -------------------------------------------------------------------

#SKILL: Amazon EventBridge Scheduler
#SKILL: Scheduled Invocations
#SKILL: Token Security
resource "aws_scheduler_schedule" "unused_token_check" {
}

#SKILL: Amazon EventBridge Scheduler
#SKILL: Scheduled Invocations
#SKILL: Amazon Bedrock
resource "aws_scheduler_schedule" "waf_bedrock_analyzer" {
}

#SKILL: Amazon EventBridge Scheduler
#SKILL: Scheduled Invocations
#SKILL: Threat Correlation
resource "aws_scheduler_schedule" "threat_correlation" {
}

# -------------------------------------------------------------------
# 72-waf.tf
# -------------------------------------------------------------------

#SKILL: AWS WAF
#SKILL: Managed Rule Groups
#SKILL: WAF Telemetry
resource "aws_wafv2_web_acl" "shield_generator" {
}

#SKILL: AWS WAF
#SKILL: Web ACL Associations
#SKILL: WAF Telemetry
resource "aws_wafv2_web_acl_association" "api_gateway_prod" {
}

#SKILL: AWS WAF
#SKILL: WAF Log Delivery
#SKILL: WAF Telemetry
resource "aws_wafv2_web_acl_logging_configuration" "api_gateway" {
}

# -------------------------------------------------------------------
# 80-cloudwatch-logs.tf
# -------------------------------------------------------------------

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
resource "aws_cloudwatch_log_group" "jedi_python" {
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
resource "aws_cloudwatch_log_group" "sith_node" {
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: Token Security
resource "aws_cloudwatch_log_group" "unused_token_detector" {
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: Amazon Bedrock
resource "aws_cloudwatch_log_group" "waf_bedrock_analyzer" {
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
resource "aws_cloudwatch_log_group" "api_gateway_access" {
}

#SKILL: Amazon CloudWatch
#SKILL: Log Groups
#SKILL: WAF Telemetry
resource "aws_cloudwatch_log_group" "waf_logs" {
}

#SKILL: Amazon CloudWatch
#SKILL: Log Resource Policies
#SKILL: WAF Telemetry
resource "aws_cloudwatch_log_resource_policy" "cloudwatch_waf_log_delivery" {
}

#SKILL: AWS IAM
#SKILL: IAM Permission Policies
#SKILL: WAF Telemetry
data "aws_iam_policy_document" "cloudwatch_waf_log_delivery" {
}

# -------------------------------------------------------------------
# 81-metrics-and-alarms.tf
# -------------------------------------------------------------------

#SKILL: Amazon CloudWatch
#SKILL: Log Metric Filters
#SKILL: Token Security
resource "aws_cloudwatch_log_metric_filter" "unused_token" {
}

#SKILL: Amazon CloudWatch
#SKILL: Metric Alarms
#SKILL: Token Security
resource "aws_cloudwatch_metric_alarm" "unused_token" {
}

# -------------------------------------------------------------------
# 83-sns.tf
# -------------------------------------------------------------------

#SKILL: Amazon SNS
#SKILL: Notification Topics
#SKILL: Alerting
resource "aws_sns_topic" "token_alerts" {
}

#SKILL: Amazon SNS
#SKILL: Topic Subscriptions
#SKILL: Alerting
resource "aws_sns_topic_subscription" "token_alert_emails" {
}
