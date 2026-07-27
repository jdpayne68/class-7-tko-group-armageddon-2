# ================================================================
# AWS LAMBDA
# ================================================================

# -------------------------------------------------------------------------------
# Lambda Function - Jedi Python
# -------------------------------------------------------------------------------
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

# Zip Archive - Jedi Python
data "archive_file" "jedi_python" {
  type        = "zip"
  source_file = "${path.module}/lambda-code/jedi_python.py"
  output_path = "${path.module}/lambda-code/jedi_python.zip"
}

# -------------------------------------------------------------------------------
# Lambda Function - Sith Node
# -------------------------------------------------------------------------------
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

# Zip Archive - Sith Node
data "archive_file" "sith_node" {
  type        = "zip"
  source_file = "${path.module}/lambda-code/sith_node.js"
  output_path = "${path.module}/lambda-code/sith_node.zip"
}

# -------------------------------------------------------------------------------
# Lambda Function - Unused Token Detector
# -------------------------------------------------------------------------------
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

# Zip Archive - Unused Token Detector
data "archive_file" "unused_token_detector" {
  type        = "zip"
  source_file = "${path.module}/lambda-code/unused_token_detector.py"
  output_path = "${path.module}/lambda-code/unused_token_detector.zip"
}

# -------------------------------------------------------------------------------
# Lambda Function - WAF Log Analyzer
# -------------------------------------------------------------------------------
resource "aws_lambda_function" "waf_bedrock_analyzer" {
  filename         = data.archive_file.waf_bedrock_analyzer.output_path
  source_code_hash = data.archive_file.waf_bedrock_analyzer.output_base64sha256

  function_name = local.waf_bedrock_analyzer_function_name
  description   = "Reads WAF logs and sends to Bedrock for analysis"
  role          = aws_iam_role.waf_bedrock_analyzer_role.arn

  handler     = "waf_bedrock_analyzer.lambda_handler"
  runtime     = "python3.14"
  memory_size = 128
  timeout     = 120

  environment {
    variables = {
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE   = aws_dynamodb_table.shield_generator_events.name
      # Use the latest model. anthropic.claude-3-haiku-20240307-v1:0 is legacy and not available for many users.
      BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-6"
      LOOKBACK_MINUTES = 10
      MAX_LOG_EVENTS = 25
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.unused_token_detector,
    aws_iam_role_policy_attachment.unused_token_detector_basic_execution,
    aws_iam_role_policy_attachment.unused_token_detector_scan,
  ]
}

# Zip Archive - Unused Token Detector
data "archive_file" "waf_bedrock_analyzer" {
  type        = "zip"
  source_file = "${path.module}/lambda-code/waf_bedrock_analyzer.py"
  output_path = "${path.module}/lambda-code/waf_bedrock_analyzer.zip"
}
