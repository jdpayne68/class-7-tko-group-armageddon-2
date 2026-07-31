# # -------------------------------------------------------------------------------
# # Lambda Layer - ReportLab
# # -------------------------------------------------------------------------------
# 
# # Zip Archive - ReportLab Layer
# data "archive_file" "reportlab_layer" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda/layers/reportlab-layer"
#   output_path = "${path.module}/lambda/layers/reportlab-layer.zip"
# 
#   excludes = [
#     "**/.DS_Store",
#     "**/__pycache__",
#     "**/*.pyc",
#   ]
# }
# 
# # Lambda Layer - ReportLab
# resource "aws_lambda_layer_version" "reportlab" {
#   filename    = data.archive_file.reportlab_layer.output_path
#   layer_name  = "${local.name_prefix}-reportlab-${local.name_suffix}"
#   description = "ReportLab PDF generation library for Executive Dashboard Agent"
# 
#   compatible_runtimes      = ["python3.12"]
#   compatible_architectures = ["x86_64"]
# 
#   source_code_hash = data.archive_file.reportlab_layer.output_base64sha256
# }
# 
# # -------------------------------------------------------------------------------
# # Lambda Function - Executive Dashboard Agent
# # -------------------------------------------------------------------------------
# # Lambda Function - Executive Dashboard Agent
# resource "aws_lambda_function" "executive_dashboard" {
#   filename         = data.archive_file.executive_dashboard_agent.output_path
#   source_code_hash = data.archive_file.executive_dashboard_agent.output_base64sha256
# 
#   function_name = local.executive_dashboard_function_name
#   description   = "Generates executive security reports with PDF and JSON outputs"
#   role          = aws_iam_role.executive_dashboard_role.arn
# 
#   handler       = "executive_dashboard_agent.lambda_handler"
#   runtime       = "python3.12"
#   architectures = ["x86_64"]
#   memory_size   = 256
#   timeout       = 120
# 
#   # ================================================================
#   # ATTACH THE REPORTLAB LAYER HERE
#   # ================================================================
#   layers = [
#     aws_lambda_layer_version.reportlab.arn,
#     "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
#   ]
# 
#   ephemeral_storage {
#     size = 512
#   }
# 
#   environment {
#     variables = {
#       WAF_EVENTS_TABLE           = aws_dynamodb_table.shield_generator_events.name
#       CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
#       SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.waf_security_incidents.name
#       REPORT_BUCKET              = aws_s3_bucket.executive_report_bucket.id
#       BEDROCK_MODEL_ID           = "us.anthropic.claude-sonnet-4-6"
#       REPORT_PERIOD_HOURS        = "24"
#       ORGANIZATION_NAME          = "SEIR Cloud Security"
#       REPORT_TITLE               = "Executive Security Report"
#       ENABLE_BEDROCK             = "true"
#       MAX_ITEMS_PER_TABLE        = "5000"
#     }
#   }
# 
#   depends_on = [
#     aws_cloudwatch_log_group.executive_dashboard,
#     aws_iam_role_policy_attachment.executive_dashboard_basic_execution,
#     aws_iam_role_policy_attachment.executive_dashboard,
#     aws_iam_role_policy_attachment.executive_dashboard_appsignals,
#   ]
# }
# 
# # Zip Archive - Executive Dashboard Agent
# data "archive_file" "executive_dashboard_agent" {
#   type        = "zip"
#   source_file = "${path.module}/lambda/src/executive_dashboard_agent.py"
#   output_path = "${path.module}/lambda/executive_dashboard_agent.zip"
# }
# 
# 
# 
# 
# # CloudWatch Log Group - Executive Dashboard
# resource "aws_cloudwatch_log_group" "executive_dashboard" {
#   name              = "/aws/lambda/${local.executive_dashboard_function_name}"
#   retention_in_days = var.log_retention_days
# }
# 
# # -------------------------------------------------------------------------------
# # S3 Bucket for Executive Reports
# # -------------------------------------------------------------------------------
# resource "aws_s3_bucket" "executive_report_bucket" {
#   bucket        = "${local.name_prefix}-executive-reports-${local.bucket_suffix}"
#   force_destroy = true
# }
# 
# resource "aws_s3_bucket_versioning" "executive_report_bucket" {
#   bucket = aws_s3_bucket.executive_report_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# 
# resource "aws_s3_bucket_server_side_encryption_configuration" "report_bucket" {
#   bucket = aws_s3_bucket.executive_report_bucket.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
# 
# resource "aws_s3_bucket_public_access_block" "executive_report_bucket" {
#   bucket                  = aws_s3_bucket.executive_report_bucket.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
# 
# # -------------------------------------------------------------------------------
# # Executive Dashboard Agent IAM Permissions
# # -------------------------------------------------------------------------------
# resource "aws_iam_policy" "executive_dashboard" {
#   name        = "${local.name_prefix}-executive-dashboard-${local.name_suffix}"
#   description = "Allows Executive Dashboard Agent to read tables and write to S3"
#   policy      = data.aws_iam_policy_document.executive_dashboard.json
# }
# 
# data "aws_iam_policy_document" "executive_dashboard" {
#   # DynamoDB Read permissions
#   statement {
#     effect = "Allow"
#     actions = [
#       "dynamodb:Scan",
#       "dynamodb:Query",
#       "dynamodb:GetItem",
#       "dynamodb:BatchGetItem"
#     ]
#     resources = [
#       aws_dynamodb_table.shield_generator_events.arn,
#       aws_dynamodb_table.waf_correlation_findings.arn,
#       aws_dynamodb_table.waf_security_incidents.arn,
#     ]
#   }
# 
#   # S3 Write permissions
#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:PutObject",
#       "s3:PutObjectAcl",
#       "s3:GetObject",
#     ]
#     resources = [
#       "${aws_s3_bucket.executive_report_bucket.arn}/*",
#     ]
#   }
# 
#   # Bedrock Permissions - Invoke Model
#   statement {
#     effect = "Allow"
#     actions = [
#       "bedrock:InvokeModel"
#     ]
#     resources = ["*"]
#   }
# }
# 
# # -------------------------------------------------------------------------------
# # Lambda IAM Role - Executive Dashboard
# # -------------------------------------------------------------------------------
# resource "aws_iam_role" "executive_dashboard_role" {
#   name               = "${local.name_prefix}-executive-dashboard-role-${local.name_suffix}"
#   assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
#   description        = "Execution role for the Executive Dashboard Lambda"
# }
# 
# resource "aws_iam_role_policy_attachment" "executive_dashboard_basic_execution" {
#   role       = aws_iam_role.executive_dashboard_role.name
#   policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }
# 
# resource "aws_iam_role_policy_attachment" "executive_dashboard" {
#   role       = aws_iam_role.executive_dashboard_role.name
#   policy_arn = aws_iam_policy.executive_dashboard.arn
# }
# 
# # Attach Application Signals Policy
# resource "aws_iam_role_policy_attachment" "executive_dashboard_appsignals" {
#   role       = aws_iam_role.executive_dashboard_role.name
#   policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
# }
# 
# # -------------------------------------------------------------------------------
# # EventBridge Scheduler - Executive Dashboard
# # -------------------------------------------------------------------------------
# resource "aws_scheduler_schedule" "executive_dashboard" {
#   name        = "${local.name_prefix}-executive-dashboard"
#   description = "Generates executive security report every 24 hours"
# 
#   schedule_expression = "rate(24 hours)"
#   state               = "ENABLED"
# 
#   flexible_time_window {
#     mode = "OFF"
#   }
# 
#   target {
#     arn      = aws_lambda_function.executive_dashboard.arn
#     role_arn = aws_iam_role.scheduler_role.arn
#     input = jsonencode({
#       source              = "eventbridge-scheduler",
#       report_period_hours = 24
#     })
#   }
# 
#   depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_executive_dashboard]
# }
# 
# # -------------------------------------------------------------------------------
# # EventBridge Scheduler Permissions - Executive Dashboard
# # -------------------------------------------------------------------------------
# resource "aws_iam_policy" "scheduler_invoke_executive_dashboard" {
#   name        = "${local.name_prefix}-scheduler-invoke-executive-dashboard-${local.name_suffix}"
#   description = "Allows EventBridge Scheduler to invoke the executive dashboard Lambda"
#   policy      = data.aws_iam_policy_document.scheduler_invoke_executive_dashboard.json
# }
# 
# data "aws_iam_policy_document" "scheduler_invoke_executive_dashboard" {
#   statement {
#     effect    = "Allow"
#     actions   = ["lambda:InvokeFunction"]
#     resources = [aws_lambda_function.executive_dashboard.arn]
#   }
# }
# 
# resource "aws_iam_role_policy_attachment" "scheduler_invoke_executive_dashboard" {
#   role       = aws_iam_role.scheduler_role.name
#   policy_arn = aws_iam_policy.scheduler_invoke_executive_dashboard.arn
# }
# 
# # -------------------------------------------------------------------------------
# # Lambda Permissions - Invoke Executive Dashboard Agent
# # -------------------------------------------------------------------------------
# resource "aws_lambda_permission" "executive_dashboard_scheduler" {
#   statement_id  = "AllowSchedulerInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.executive_dashboard.function_name
#   principal     = "scheduler.amazonaws.com"
#   source_arn    = aws_scheduler_schedule.executive_dashboard.arn
# }
