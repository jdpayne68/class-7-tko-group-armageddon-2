## EventBridge Logging for ARMAGEDDON SOAR Platform
# ARMAGEDDON has three scheduled Lambdas:

    # WAF Analyzer runs every 5 minutes

    # Threat Correlation runs every 5 minutes

    # Executive Dashboard  runs every hour

# And one custom event trigger:

    # SOAR Response is triggered when Threat Correlation emits a “FindingCreated” event

# EventBridge handles all four.

# EventBridge Schedules + Custom Events

# WAF Analyzer Schedule
# Runs every 5 minutes
# this schedule triggers the WAF Analyzer Lambda every 5 minutes

resource "aws_cloudwatch_event_rule" "waf_analyzer_schedule" {
  name                = "${var.prefix}-waf-analyzer-schedule"
  schedule_expression = var.waf_analyzer_schedule_expression
  tags                = var.common_tags
}

resource "aws_cloudwatch_event_target" "waf_analyzer_target" {
  rule      = aws_cloudwatch_event_rule.waf_analyzer_schedule.name
  target_id = "wafAnalyzerLambda"
  arn       = var.waf_analyzer_lambda_arn
}

# ---------------------------------------------
# Threat Correlation Schedule 
# Runs every 5 minutes
# this schedule triggers the Threat Correlation Lambda every 5 minutes
# ---------------------------------------------
resource "aws_cloudwatch_event_rule" "threat_correlation_schedule" {
  name                = "${var.prefix}-threat-correlation-schedule"
  schedule_expression = var.threat_correlation_schedule_expression
  tags                = var.common_tags
}

resource "aws_cloudwatch_event_target" "threat_correlation_target" {
  rule      = aws_cloudwatch_event_rule.threat_correlation_schedule.name
  target_id = "threatCorrelationLambda"
  arn       = var.threat_correlation_lambda_arn
}

# ---------------------------------------------
# Executive Dashboard Schedule
# Runs every hour
# this schedule triggers the Executive Dashboard Lambda every hour

# ---------------------------------------------
resource "aws_cloudwatch_event_rule" "executive_dashboard_schedule" {
  name                = "${var.prefix}-executive-dashboard-schedule"
  schedule_expression = var.executive_dashboard_schedule_expression
  tags                = var.common_tags
}

resource "aws_cloudwatch_event_target" "executive_dashboard_target" {
  rule      = aws_cloudwatch_event_rule.executive_dashboard_schedule.name
  target_id = "executiveDashboardLambda"
  arn       = var.executive_dashboard_lambda_arn
}

# ---------------------------------------------
# Custom Event: FindingCreated → SOAR Response
# This custom event rule listens for the "FindingCreated" event from the Threat Correlation service and triggers the SOAR Response Lambda.
#   This allows the SOAR Response Lambda to automatically react to new findings without manual intervention.
# ---------------------------------------------
resource "aws_cloudwatch_event_rule" "finding_created_rule" {
  name = "${var.prefix}-finding-created-rule"

  event_pattern = jsonencode({
    source = ["armageddon.threat-correlation"]
    detail-type = ["FindingCreated"]
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "finding_created_target" {
  rule      = aws_cloudwatch_event_rule.finding_created_rule.name
  target_id = "soarResponseLambda"
  arn       = var.soar_response_lambda_arn
}
