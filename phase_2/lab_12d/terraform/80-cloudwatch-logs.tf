# ================================================================
# CLOUDWATCH LOGS
# ================================================================

# -------------------------------------------------------------------------------
# Lambda Log Groups
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "jedi_python" {
  name              = "/aws/lambda/${local.jedi_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "sith_node" {
  name              = "/aws/lambda/${local.sith_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "unused_token_detector" {
  name              = "/aws/lambda/${local.token_detector_function_name}"
  retention_in_days = var.log_retention_days
}

# WAF Bedrock Analyzer
resource "aws_cloudwatch_log_group" "waf_bedrock_analyzer" {

  name              = "/aws/lambda/waf-bedrock-analyzer"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "soar_response_agent" {
  name              = "/aws/lambda/${local.soar_response_agent_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "executive_dashboard" {
  name              = "/aws/lambda/${local.executive_dashboard_function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "compliance_agent" {
  name              = "/aws/lambda/${local.compliance_agent_function_name}"
  retention_in_days = var.log_retention_days
}

# -------------------------------------------------------------------------------
# API Gateway Access Log Group
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "api_gateway_access" {
  name              = "/aws/apigateway/${local.name_prefix}-api/prod/access"
  retention_in_days = var.log_retention_days
}

# -------------------------------------------------------------------------------
# WAF Log Group
# -------------------------------------------------------------------------------
# WAF enforces naming prefix on CloudWatch logs.
# You must choose a logging destination whose name begins with aws-waf-logs-
# https://docs.aws.amazon.com/waf/latest/developerguide/logging-management-configure.html

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${local.name_prefix}-${local.name_suffix}/api-gateway-waf"
  retention_in_days = var.log_retention_days
}

# -------------------------------------------------------------------------------
# Resource Policy for WAF Log Group
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_log_resource_policy" "cloudwatch_waf_log_delivery" {
  policy_document = data.aws_iam_policy_document.cloudwatch_waf_log_delivery.json
  policy_name     = "${local.name_prefix}-cloudwatch-waf-log-delivery-${local.name_suffix}"
}

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
