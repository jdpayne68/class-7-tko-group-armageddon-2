resource "aws_cloudwatch_event_rule" "finding_created" {
  name = "${var.project_name}-finding-created"

  event_pattern = jsonencode({
    source = [
      "seir.waf.correlation"
    ]

    detail-type = [
      "WAF Threat Finding Created"
    ]
  })
}

resource "aws_cloudwatch_event_target" "soar" {
  rule = aws_cloudwatch_event_rule.finding_created.name
  arn  = aws_lambda_function.soar.arn
}

resource "aws_lambda_permission" "soar_eventbridge" {
  statement_id  = "AllowEventBridgeSOAR"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.finding_created.arn
}
