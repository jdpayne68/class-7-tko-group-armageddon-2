# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

####################################
# EventBridge Schedule Waf_Bedrock
####################################

resource "aws_cloudwatch_event_rule" "waf_bedrock" {
  name                = "waf-bedrock"
  description         = "Waf bedrock analyzer"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "waf_analyze" {
  rule = aws_cloudwatch_event_rule.waf_bedrock.name
  arn  = aws_lambda_function.waf_bedrock_analyzer.arn
}


##############################################################
# Allow EventBridge to Invoke Lambda
##############################################################

resource "aws_lambda_permission" "allow_eventbridge_waf_bedrock" {

  statement_id  = "AllowExecutionFromEventBridgeWafBedrock"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_bedrock_analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_bedrock.arn
}



###################################
# EventBridge Schedule Waf_Threat
###################################

resource "aws_cloudwatch_event_rule" "waf_threat" {
  name                = "waf-threat"
  description         = "Waf threat correlation agent"
  schedule_expression = "rate(60 minutes)"
}

resource "aws_cloudwatch_event_target" "waf_treat_agent" {
  rule = aws_cloudwatch_event_rule.waf_threat.name
  arn  = aws_lambda_function.waf_threat_correlation_agent.arn
}


##############################################################
# Allow EventBridge to Invoke Lambda
##############################################################

resource "aws_lambda_permission" "allow_eventbridge_waf_threat" {

  statement_id  = "AllowExecutionFromEventBridgeWafThreat"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_threat_correlation_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_threat.arn
}
