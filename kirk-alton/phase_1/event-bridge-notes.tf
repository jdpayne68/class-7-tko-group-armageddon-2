# ================================================================
# EVENTBRIDGE RULES
# ================================================================

# -------------------------------------------------------------------------------
# EventBridge Rule - Unused-Token Check
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
