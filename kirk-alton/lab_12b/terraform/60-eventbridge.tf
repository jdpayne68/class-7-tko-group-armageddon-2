# ================================================================
# EVENTBRIDGE RULES AND SCHEDULES
# ================================================================

# -------------------------------------------------------------------------------
# SOAR Response Event Rules
# -------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "soar_response_medium_high" {
  name        = "${local.name_prefix}-soar-response-medium-high-${local.name_suffix}"
  description = "Triggers SOAR response agent for MEDIUM and HIGH severity WAF findings"
  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["MEDIUM", "HIGH"]
    }
  })
}

resource "aws_cloudwatch_event_target" "soar_response_medium_high" {
  rule      = aws_cloudwatch_event_rule.soar_response_medium_high.name
  target_id = "soar-response-agent"
  arn       = aws_lambda_function.soar_response_agent.arn
}

resource "aws_cloudwatch_event_rule" "soar_response_critical" {
  name        = "${local.name_prefix}-soar-response-critical${local.name_suffix}"
  description = "Triggers SOAR response agent and critical alert for CRITICAL severity WAF findings"
  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["CRITICAL"]
    }
  })
}

resource "aws_cloudwatch_event_target" "soar_response_critical_agent" {
  rule      = aws_cloudwatch_event_rule.soar_response_critical.name
  target_id = "soar-response-agent"
  arn       = aws_lambda_function.soar_response_agent.arn
}

resource "aws_cloudwatch_event_target" "soar_response_critical_sns" {
  rule      = aws_cloudwatch_event_rule.soar_response_critical.name
  target_id = "critical-alert-sns"
  arn       = aws_sns_topic.waf_security_incidents_alert.arn
}

# -------------------------------------------------------------------------------
# Scheduled Detectors and Correlation
# -------------------------------------------------------------------------------

resource "aws_scheduler_schedule" "unused_token_check" {
  name        = "${local.name_prefix}-unused-token-check${local.name_suffix}"
  description = "Checks for unused Cognito tokens every 5 minutes"

  schedule_expression = var.token_scan_schedule
  state               = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.unused_token_detector.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ source = "eventbridge-scheduler" })
  }

  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_detector]
}

resource "aws_scheduler_schedule" "waf_bedrock_analyzer" {
  name        = "${local.name_prefix}-waf-bedrock-analyzer${local.name_suffix}"
  description = "Runs WAF log analysis every 5 minutes"

  schedule_expression = "rate(5 minutes)"
  state               = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.waf_bedrock_analyzer.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ source = "eventbridge-scheduler" })
  }

  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_analyzer]
}

resource "aws_scheduler_schedule" "threat_correlation" {
  name        = "${local.name_prefix}-threat-correlation${local.name_suffix}"
  description = "Runs WAF threat correlation every 5 minutes"

  schedule_expression = "rate(5 minutes)"
  state               = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.waf_threat_correlation_agent.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ source = "eventbridge-scheduler" })
  }

  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_correlation]
}

# -------------------------------------------------------------------------------
# Executive Dashboard Schedule
# -------------------------------------------------------------------------------

resource "aws_scheduler_schedule" "executive_dashboard" {
  name        = "${local.name_prefix}-executive-dashboard"
  description = "Generates executive security report every 24 hours"

  schedule_expression = "rate(24 hours)"
  state               = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.executive_dashboard.arn
    role_arn = aws_iam_role.scheduler_role.arn
    input = jsonencode({
      source              = "eventbridge-scheduler",
      report_period_hours = 24
    })
  }

  depends_on = [aws_iam_role_policy_attachment.scheduler_invoke_executive_dashboard]
}
