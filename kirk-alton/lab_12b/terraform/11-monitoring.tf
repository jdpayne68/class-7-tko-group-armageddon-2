# ================================================================
# MONITORING
# ================================================================

# ================= CLOUDWATCH LOGS - LOG GROUPS =================

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
  name              = "aws-waf-logs-${local.name_prefix}/api-gateway-waf"
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

# ====================== CLOUDWATCH - METRICS ====================

# -------------------------------------------------------------------------------
# Detector Log Metric
# -------------------------------------------------------------------------------
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

# ====================== CLOUDWATCH - ALARMS =====================

# -------------------------------------------------------------------------------
# CloudWatch Alarm - Unused Token Alert
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "unused_token" {
  alarm_name          = "${local.name_prefix}-unused-token-alarm-${local.name_suffix}"
  alarm_description   = "Detector found at least one token record that was never used"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1

  metric_name = "UnusedTokenAlert"
  namespace   = "${local.name_prefix}/TokenDetector-${local.name_suffix}"
  period      = 60
  statistic   = "Sum"

  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.token_alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.unused_token]
}

# =========================== SNS ALERTS =========================

# -------------------------------------------------------------------------------
# SNS Alert Topic And Optional Email Subscription
# -------------------------------------------------------------------------------

# Token Alerts
resource "aws_sns_topic" "token_alerts" {
  name              = "${local.name_prefix}-auth-alerts-${local.name_suffix}"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "token_alert_emails" {
  count = length(var.alert_emails)

  topic_arn = aws_sns_topic.token_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# WAF Security Incidents Alert
resource "aws_sns_topic" "waf_security_incidents_alert" {
  name              = "waf-security-incidents-alert"
  kms_master_key_id = "alias/aws/sns"

}

resource "aws_sns_topic_subscription" "waf_security_incidents_alert_emails" {
  count = length(var.alert_emails)

  topic_arn = aws_sns_topic.waf_security_incidents_alert.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}
