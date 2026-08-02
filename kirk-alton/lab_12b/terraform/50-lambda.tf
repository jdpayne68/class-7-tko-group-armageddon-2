# ================================================================
# AWS LAMBDA
# ================================================================

# -------------------------------------------------------------------------------
# Lambda Function - Jedi Python
# -------------------------------------------------------------------------------
# Zip Archive - Jedi Python Lambda
data "archive_file" "jedi_python" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/jedi_python"
  output_path = "${path.module}/lambda/src/jedi_python.zip"
}

resource "aws_lambda_function" "jedi_python" {
  filename         = data.archive_file.jedi_python.output_path
  source_code_hash = data.archive_file.jedi_python.output_base64sha256

  function_name = local.jedi_function_name
  description   = "Protected Python route for the Cognito REST auth-flow lab"
  role          = aws_iam_role.jedi_python_role.arn

  handler     = "jedi_python.lambda_handler"
  runtime     = "python3.14"
  memory_size = 128
  timeout     = 10

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

# -------------------------------------------------------------------------------
# Lambda Function - Sith Node
# -------------------------------------------------------------------------------
# Zip Archive - Sith Node Lambda
data "archive_file" "sith_node" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/sith_node"
  output_path = "${path.module}/lambda/src/sith_node.zip"
}

resource "aws_lambda_function" "sith_node" {
  filename         = data.archive_file.sith_node.output_path
  source_code_hash = data.archive_file.sith_node.output_base64sha256

  function_name = local.sith_function_name
  description   = "Protected Node.js route for the Cognito REST auth-flow lab"
  role          = aws_iam_role.sith_node_role.arn

  handler     = "sith_node.handler"
  runtime     = "nodejs24.x"
  memory_size = 128
  timeout     = 10

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

# -------------------------------------------------------------------------------
# Lambda Function - Unused Token Detector
# -------------------------------------------------------------------------------
# Zip Archive - Unused Token Detector Lambda
data "archive_file" "unused_token_detector" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/unused_token_detector"
  output_path = "${path.module}/lambda/src/unused_token_detector.zip"
}

resource "aws_lambda_function" "unused_token_detector" {
  filename         = data.archive_file.unused_token_detector.output_path
  source_code_hash = data.archive_file.unused_token_detector.output_base64sha256

  function_name = local.token_detector_function_name
  description   = "Scans token records and logs alerts for tokens that have not been used"
  role          = aws_iam_role.unused_token_detector_role.arn

  handler     = "unused_token_detector.lambda_handler"
  runtime     = "python3.14"
  memory_size = 128
  timeout     = 30

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

# -------------------------------------------------------------------------------
# Lambda Function - WAF Bedrock Analyzer
# -------------------------------------------------------------------------------
# Zip Archive - WAF Bedrock Analyzer Lambda
data "archive_file" "waf_bedrock_analyzer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/waf_bedrock_analyzer"
  output_path = "${path.module}/lambda/src/waf_bedrock_analyzer.zip"
}

resource "aws_lambda_function" "waf_bedrock_analyzer" {
  filename         = data.archive_file.waf_bedrock_analyzer.output_path
  source_code_hash = data.archive_file.waf_bedrock_analyzer.output_base64sha256

  function_name = local.waf_bedrock_analyzer_function_name
  description   = "Reads WAF logs and sends to Bedrock for analysis"
  role          = aws_iam_role.waf_bedrock_analyzer_role.arn

  handler     = "waf_bedrock_analyzer.lambda_handler"
  runtime     = "python3.14"
  memory_size = 128
  timeout     = var.bedrock_lambda_timeout

  # CloudWatch Application Signals Layer
  # https://docs.aws.amazon.com/lambda/latest/dg/monitoring-application-signals.html
  # https://docs.aws.amazon.com/lambda/latest/dg/monitoring-application-signals.html

  layers = [
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]

  environment {
    variables = {
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE   = aws_dynamodb_table.shield_generator_events.name
      BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-6"
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

# -------------------------------------------------------------------------------
# Lambda Function - WAF Threat Correlation Agent
# -------------------------------------------------------------------------------
# Zip Archive - WAF Threat Correlation Agent Lambda
data "archive_file" "waf_threat_correlation_agent" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/waf_threat_correlation_agent"
  output_path = "${path.module}/lambda/src/waf_threat_correlation_agent.zip"
}

resource "aws_lambda_function" "waf_threat_correlation_agent" {
  filename         = data.archive_file.waf_threat_correlation_agent.output_path
  source_code_hash = data.archive_file.waf_threat_correlation_agent.output_base64sha256

  function_name = local.waf_bedrock_threat_correlation_agent_name
  description   = "Reads WAF logs and sends to Bedrock for analysis"
  role          = aws_iam_role.waf_threat_correlation_agent_role.arn

  handler     = "waf_threat_correlation_agent.lambda_handler"
  runtime     = "python3.14"
  memory_size = 128
  timeout     = var.bedrock_lambda_timeout

  # CloudWatch Application Signals Layer
  # https://docs.aws.amazon.com/lambda/latest/dg/monitoring-application-signals.html
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Application-Signals-Enable-LambdaMain.html
  layers = [
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.shield_generator_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      BEDROCK_MODEL_ID           = "us.anthropic.claude-sonnet-4-6"
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

# -------------------------------------------------------------------------------
# Lambda Function - SOAR Response Agent
# -------------------------------------------------------------------------------
# Zip Archive - SOAR Response Agent Lambda
data "archive_file" "soar_response_agent" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/soar_response_agent"
  output_path = "${path.module}/lambda/src/soar_response_agent.zip"
}

resource "aws_lambda_function" "soar_response_agent" {
  filename         = data.archive_file.soar_response_agent.output_path
  source_code_hash = data.archive_file.soar_response_agent.output_base64sha256

  function_name = local.soar_response_agent_name
  description   = "SOAR response agent that processes WAF threat findings and creates security incidents"
  role          = aws_iam_role.soar_response_agent_role.arn

  handler     = "soar_response_agent.lambda_handler"
  runtime     = "python3.14"
  memory_size = 128
  timeout     = var.bedrock_lambda_timeout

  layers = [
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]

  environment {
    variables = {
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.waf_security_incidents.name
      SNS_TOPIC_ARN              = aws_sns_topic.waf_security_incidents_alert.arn
      BEDROCK_MODEL_ID           = "us.anthropic.claude-sonnet-4-6"
      ENABLE_BEDROCK             = "true"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.soar_response_agent,
    aws_iam_role_policy_attachment.soar_response_agent_basic_execution,
    aws_iam_role_policy_attachment.soar_response_agent,
    aws_iam_role_policy_attachment.soar_response_agent_appsignals,
  ]
}

# -------------------------------------------------------------------------------
# Lambda Layer - ReportLab
# -------------------------------------------------------------------------------
data "archive_file" "reportlab_layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/layers/reportlab-layer"
  output_path = "${path.module}/lambda/layers/reportlab-layer.zip"

  excludes = [
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

resource "aws_lambda_layer_version" "reportlab" {
  filename    = data.archive_file.reportlab_layer.output_path
  layer_name  = "${local.name_prefix}-reportlab-${local.name_suffix}"
  description = "ReportLab PDF generation library for reporting Lambdas"

  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]

  source_code_hash = data.archive_file.reportlab_layer.output_base64sha256
}

# -------------------------------------------------------------------------------
# Lambda Function - Executive Dashboard Agent
# -------------------------------------------------------------------------------
resource "aws_lambda_function" "executive_dashboard" {
  filename         = data.archive_file.executive_dashboard_agent.output_path
  source_code_hash = data.archive_file.executive_dashboard_agent.output_base64sha256

  function_name = local.executive_dashboard_function_name
  description   = "Generates executive security reports with PDF and JSON outputs"
  role          = aws_iam_role.executive_dashboard_role.arn

  handler       = "executive_dashboard_agent.lambda_handler"
  runtime       = "python3.12"
  architectures = ["x86_64"]
  memory_size   = 256
  timeout       = 120

  layers = [
    aws_lambda_layer_version.reportlab.arn,
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.shield_generator_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.waf_security_incidents.name
      REPORT_BUCKET              = aws_s3_bucket.executive_report_bucket.id
      BEDROCK_MODEL_ID           = "us.anthropic.claude-sonnet-4-6"
      REPORT_PERIOD_HOURS        = "24"
      ORGANIZATION_NAME          = "SEIR Cloud Security"
      REPORT_TITLE               = "Executive Security Report"
      ENABLE_BEDROCK             = "true"
      MAX_ITEMS_PER_TABLE        = "5000"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executive_dashboard,
    aws_iam_role_policy_attachment.executive_dashboard_basic_execution,
    aws_iam_role_policy_attachment.executive_dashboard,
    aws_iam_role_policy_attachment.executive_dashboard_appsignals,
  ]
}

data "archive_file" "executive_dashboard_agent" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/executive_dashboard_agent"
  output_path = "${path.module}/lambda/src/executive_dashboard_agent.zip"
}
