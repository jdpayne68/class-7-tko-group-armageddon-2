
# EventBridge -> Lambda Permissions


# Allow EventBridge to invoke WAF Analyzer
resource "aws_lambda_permission" "allow_eventbridge_waf" {
  statement_id  = "AllowEventBridgeWAF"
  action        = "lambda:InvokeFunction"
  function_name = var.waf_analyzer_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_analyzer_schedule.arn
}

# Allow EventBridge to invoke Threat Correlation
resource "aws_lambda_permission" "allow_eventbridge_correlation" {
  statement_id  = "AllowEventBridgeCorrelation"
  action        = "lambda:InvokeFunction"
  function_name = var.threat_correlation_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.threat_correlation_schedule.arn
}

# Allow EventBridge to invoke Executive Dashboard
resource "aws_lambda_permission" "allow_eventbridge_dashboard" {
  statement_id  = "AllowEventBridgeDashboard"
  action        = "lambda:InvokeFunction"
  function_name = var.executive_dashboard_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.executive_dashboard_schedule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_soar_reasoning" {
  statement_id  = "AllowEventBridgeSOARReasoning"
  action        = "lambda:InvokeFunction"
  function_name = var.soar_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.finding_created_rule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_soar_response" {
  statement_id  = "AllowEventBridgeSOARResponse"
  action        = "lambda:InvokeFunction"
  function_name = var.soar_response_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reasoning_completed_rule.arn
}