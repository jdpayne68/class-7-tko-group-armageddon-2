# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

##############################################################
# EventBridge Schedule Medium/High
##############################################################

resource "aws_cloudwatch_event_rule" "waf_finding_medium_high" {
  name        = "waf-finding-medium-high"
  description = "Routes Medium/High WAF findings to the SOAR response agent"

  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["MEDIUM", "HIGH"]
    }
  })
}


##############################################################
# EventBridge Target Medium/High
##############################################################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target

resource "aws_cloudwatch_event_target" "soar_medium_high" {
  rule = aws_cloudwatch_event_rule.waf_finding_medium_high.name
  arn  = aws_lambda_function.soar_response_agent.arn
}


##############################################################
# Allow EventBridge to Invoke Lambda
##############################################################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_finding_medium_high.arn
}


##############################################################
# EventBridge Schedule Critical
##############################################################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule

resource "aws_cloudwatch_event_rule" "waf_finding_critical" {
  name        = "waf-finding-critical"
  description = "Routes Criticial WAF findings to the SOAR response agent"

  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["CRITICAL"]
    }
  })
}


##############################################################
# EventBridge Targets Critical
##############################################################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target

resource "aws_cloudwatch_event_target" "soar_critical" {
  rule = aws_cloudwatch_event_rule.waf_finding_critical.name
  arn  = aws_lambda_function.soar_response_agent.arn
}

##############################################################
# Allow EventBridge to Invoke Lambda
##############################################################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

resource "aws_lambda_permission" "allow_eventbridge_critical" {
  statement_id  = "AllowExecutionFromEventBridgeCritical"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_finding_critical.arn

}


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


#########################################
# Eventbridge Schecdule Executive Agent
#########################################

resource "aws_cloudwatch_event_rule" "dashboard_agent" {
  name                = "dashboard-agent"
  description         = "Executive Dashboard Agent"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "executive_dashboard" {
  rule = aws_cloudwatch_event_rule.dashboard_agent.name
  arn  = aws_lambda_function.executive_dashboard_agent.arn
}


##############################################################
# Allow EventBridge to Invoke Lambda
##############################################################

resource "aws_lambda_permission" "allow_eventbridge_executive_agent" {
  statement_id  = "AllowExecutionFromEventBridgeExecutiveAgent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.executive_dashboard_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dashboard_agent.arn

}