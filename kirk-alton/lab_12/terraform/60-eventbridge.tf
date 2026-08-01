# ================================================================
# EVENTBRIDGE RULES AND SCHEDULES
# ================================================================

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
