# ================================================================
# EVENTBRIDGE
# ================================================================

# -------------------------------------------------------------------------------
# EventBridge - Unused-Token Check
# -------------------------------------------------------------------------------
# EventBridge is best for event routing.
# EventBridge: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html

# resource "aws_cloudwatch_event_rule" "unused_token_check" {
#   name                = "unused-token-check"
#   description         = "Checks for unused Cognito tokens every 5 minutes."
#   schedule_expression = "rate(5 minutes)"
#   state               = "ENABLED"

#   }

# resource "aws_cloudwatch_event_target" "unused_token_target" {
#   rule = aws_cloudwatch_event_rule.unused_token_check.name
#   arn  = aws_lambda_function.unused_token_detector.arn

# }

# -------------------------------------------------------------------------------
# EventBridge Scheduler - Unused-Token Check
# -------------------------------------------------------------------------------
# EventBridge Scheduler is best for scheduled tasks (cron/rate).
# https://aws.amazon.com/blogs/compute/introducing-amazon-eventbridge-scheduler/
# https://docs.aws.amazon.com/eventbridge/latest/userguide/using-eventbridge-scheduler.html

resource "aws_scheduler_schedule" "unused_token_check" {
  name        = "${local.name_prefix}-unused-token-check"
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
