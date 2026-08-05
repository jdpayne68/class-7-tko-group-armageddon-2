resource "aws_cloudwatch_event_rule" "analyzer_schedule" {
  name                = "${var.project_name}-analyzer-schedule"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "analyzer" {
  rule = aws_cloudwatch_event_rule.analyzer_schedule.name
  arn  = aws_lambda_function.analyzer.arn
}

resource "aws_lambda_permission" "analyzer_eventbridge" {
  statement_id  = "AllowEventBridgeAnalyzer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.analyzer_schedule.arn
}

resource "aws_cloudwatch_event_rule" "correlation_schedule" {
  name                = "${var.project_name}-correlation-schedule"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "correlation" {
  rule = aws_cloudwatch_event_rule.correlation_schedule.name
  arn  = aws_lambda_function.correlation.arn

  input = jsonencode({
    correlation_window_minutes = 60
  })
}