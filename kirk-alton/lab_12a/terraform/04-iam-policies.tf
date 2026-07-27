# ================================================================
# IAM POLICIES
# ================================================================

# -------------------------------------------------------------------------------
# Jedi And Sith Route Lambda Permissions
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
# Unused Token Detector Lambda Permissions
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
# EventBridge Scheduler Permissions
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
# WAF Log Analyzer Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "waf_bedrock_analyzer" {
  name        = "${local.name_prefix}-waf-bedrock-analyzer-policy"
  description = "IAM policy for WAF log analyzer lambda function"
  policy      = data.aws_iam_policy_document.waf_bedrock_analyzer.json
}

data "aws_iam_policy_document" "waf_bedrock_analyzer" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
  # Bedrock Permissions - Invoke Model
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

# -------------------------------------------------------------------------------
# WAF Threat Correlation Agent Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "waf_threat_correlation_agent" {
  name        = "${local.name_prefix}-waf-threat-correlation-agent-policy"
  description = "IAM policy for WAF threat correlation agent lambda function"
  policy      = data.aws_iam_policy_document.waf_threat_correlation_agent.json
}

data "aws_iam_policy_document" "waf_threat_correlation_agent" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }


  # DynamoDB Read permissions - WAF Events Table
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
  # DynamoDB Write permissions - Correlation Findings Table
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
  # Bedrock Permissions - Invoke Model
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = ["*"]
  }
}