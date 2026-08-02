
# Root Terraform Wiring for ARMAGEDDON

# WAF Module
module "waf" {
  source = "./modules/waf"

  prefix      = local.prefix
  common_tags = local.common_tags
  # prefix      = local.prefix
}

# Logging Module (CloudWatch Log Groups)
module "logging" {
  source = "./modules/logging"

  prefix      = local.prefix
  common_tags = local.common_tags
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"

  # This part wires up the DynamoDB table names from the local variables to the DynamoDB module inputs
  waf_events_table_name               = local.waf_events_table_name
  waf_correlation_findings_table_name = local.waf_correlation_findings_table_name
  security_incidents_table_name       = local.security_incidents_table_name

  common_tags = local.common_tags
}

# S3 Reports Bucket
# This module provisions the S3 bucket for storing executive reports.

module "s3" {
  source = "./modules/s3"

  reports_bucket_name = local.reports_bucket_name
  common_tags         = local.common_tags
}

# SNS Alerts Module
# This module provisions the SNS topic for sending security alerts to analysts.

module "sns" {
  source = "./modules/sns"

  alerts_topic_name = local.alerts_topic_name
  alerts_email      = var.alerts_sns_email

  common_tags = local.common_tags
}

# IAM Roles for Lambdas
# This module provisions the necessary IAM roles for the Lambda functions.
module "iam" {
  source = "./modules/iam"

  # Pass table ARNs from DynamoDB module
  waf_events_table_arn               = module.dynamodb.waf_events_table_arn
  waf_correlation_findings_table_arn = module.dynamodb.waf_correlation_findings_table_arn
  security_incidents_table_arn       = module.dynamodb.security_incidents_table_arn

  # Pass SNS topic ARN from SNS module to IAM module
  sns_topic_arn = module.sns.alerts_topic_arn

  common_tags = local.common_tags
  prefix      = local.prefix
  # reports_bucket_name = local.reports_bucket_name
  reports_bucket_arn = module.s3.reports_bucket_arn
}

# Lambda Functions
# This module provisions the Lambda functions for WAF analysis, threat correlation, SOAR response, and the executive dashboard.
module "lambdas" {
  source = "./modules/lambdas"

  # IAM roles from IAM module
  waf_analyzer_role_arn        = module.iam.waf_analyzer_role_arn
  threat_correlation_role_arn  = module.iam.threat_correlation_role_arn
  soar_response_role_arn       = module.iam.soar_response_role_arn
  executive_dashboard_role_arn = module.iam.executive_dashboard_role_arn

  # DynamoDB table names
  waf_events_table_name               = local.waf_events_table_name
  waf_correlation_findings_table_name = local.waf_correlation_findings_table_name
  security_incidents_table_name       = local.security_incidents_table_name

  # S3 bucket for reports
  reports_bucket_name = local.reports_bucket_name
  sns_topic_arn       = module.sns.alerts_topic_arn
  prefix              = local.prefix


  common_tags = local.common_tags
}

# EventBridge Schedules + Custom Events
module "eventbridge" {
  source = "./modules/eventbridge"

  # Lambda ARNs from lambdas module
  waf_analyzer_lambda_arn        = module.lambdas.waf_analyzer_lambda_arn
  threat_correlation_lambda_arn  = module.lambdas.threat_correlation_lambda_arn
  soar_response_lambda_arn       = module.lambdas.soar_response_lambda_arn
  executive_dashboard_lambda_arn = module.lambdas.executive_dashboard_lambda_arn

  # Schedule expressions
  waf_analyzer_schedule_expression        = var.waf_analyzer_schedule_expression
  threat_correlation_schedule_expression  = var.threat_correlation_schedule_expression
  executive_dashboard_schedule_expression = var.executive_dashboard_schedule_expression
  soar_response_arn                       = module.lambdas.soar_response_arn
  soar_response_name                      = module.lambdas.soar_response_name


  common_tags = local.common_tags
  prefix      = local.prefix
}
