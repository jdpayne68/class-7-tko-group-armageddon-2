# ================================================================
# IAM POLICIES
# ================================================================

# -------------------------------------------------------------------------------
# DynamoDB UpdateItem - Jedi And Sith Route Lambdas
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "route_lambda_token_update" {
  name        = "${local.name_prefix}-route-token-update"
  description = "Allows the Jedi and Sith route Lambdas to mark token records as used"
  policy      = data.aws_iam_policy_document.route_lambda_token_update.json
}

data "aws_iam_policy_document" "route_lambda_token_update" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.token_holocron.arn]
  }
}

# -------------------------------------------------------------------------------
# DynamoDB Scan - Unused Token Detector Lambda
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "token_detector_scan" {
  name        = "${local.name_prefix}-token-detector-scan"
  description = "Allows the unused-token detector Lambda to scan token records"
  policy      = data.aws_iam_policy_document.token_detector_scan.json
}

data "aws_iam_policy_document" "token_detector_scan" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.token_holocron.arn]
  }
}

# -------------------------------------------------------------------------------
# EventBridge Scheduler - Invoke Detector Lambda
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "scheduler_invoke_detector" {
  name        = "${local.name_prefix}-scheduler-invoke-detector"
  description = "Allows EventBridge Scheduler to invoke the unused-token detector"
  policy      = data.aws_iam_policy_document.scheduler_invoke_detector.json
}

data "aws_iam_policy_document" "scheduler_invoke_detector" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.unused_token_detector.arn]
  }
}

# -------------------------------------------------------------------------------
# WAF Log Processor - Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "waf_log_processor" {
  name        = "${local.name_prefix}-waf-log-processor-policy"
  description = "IAM policy for WAF to Bedrock Lambda function"
  policy      = data.aws_iam_policy_document.waf_log_processor.json
}

data "aws_iam_policy_document" "waf_log_processor" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
  # Bedrock permissions
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = ["*"]
  }
  # DynamoDB Permissions
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.shield_generator_events.arn]
  }
  # # EventBridge Permissions (use later)
  # statement {
  #   effect = "Allow"
  #   actions = [
  #     "events:PutEvents"
  #   ]
  #   resources = ["*"]
  # }
}