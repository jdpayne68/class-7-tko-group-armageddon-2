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


# WAF Analyzer Target
# this is the target for the WAF Analyzer schedule, it tells EventBridge to invoke the WAF Analyzer Lambda every 5 minutes
resource "aws_cloudwatch_event_target" "waf_analyzer_target" {
  rule      = aws_cloudwatch_event_rule.waf_analyzer_schedule.name
  target_id = "wafAnalyzerLambda"
  arn       = var.waf_analyzer_lambda_arn
}


# Threat Correlation Schedule 
# Runs every 5 minutes
# this schedule triggers the Threat Correlation Lambda every 5 minutes
# we use schedule_expression = "rate(5 minutes)" to run the Threat Correlation Lambda every 5 minutes
# we use targets to tell EventBridge to invoke the Threat Correlation Lambda every 5 minutes
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


# Executive Dashboard Schedule
# Runs every hour
# this schedule triggers the Executive Dashboard Lambda every hour

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


# Custom Event: FindingCreated → SOAR Response
# This custom event rule listens for the "FindingCreated" event from the Threat Correlation service and triggers the SOAR Response Lambda.
#   This allows the SOAR Response Lambda to automatically react to new findings without manual intervention.

resource "aws_cloudwatch_event_rule" "finding_created_rule" {
  name = "${var.prefix}-finding-created-rule"

  event_pattern = jsonencode({
    source = ["armageddon.threat-correlation"]
    detail-type = ["FindingCreated"]
  })

  tags = var.common_tags
}


resource "aws_cloudwatch_event_target" "soar_reasoning_target" {
  rule      = aws_cloudwatch_event_rule.finding_created_rule.name
  target_id = "SOARReasoning"
  arn       = var.soar_lambda_arn
}

# SOAR Response Target this will trigger the SOAR Response Lambda when a FindingCreated event is emitted by the Threat Correlation service.
# so this tells eventbridge hen a finding is created, invoke the SOAR Lambda
resource "aws_cloudwatch_event_target" "soar_target" {
  rule      = aws_cloudwatch_event_rule.finding_created_rule.name
  target_id = "soar-response"
  arn       = var.soar_response_lambda_arn

  input_transformer {
    input_paths = {
      newImage  = "$.detail.newImage"
      findingId = "$.detail.findingId"
      summary   = "$.detail.summary"
      timestamp = "$.detail.timestamp"
    }

    input_template = <<EOF
{
  "newImage": <newImage>,
  "findingId": <findingId>,
  "summary": <summary>,
  "timestamp": <timestamp>
}
EOF
  }
}

#EventBridge cannot invoke SOAR unless SOAR explicitly allows it.
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
 function_name = var.soar_response_name

  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.finding_created_rule.arn
}
resource "aws_lambda_permission" "allow_eventbridge_to_invoke_soar" {
  statement_id  = "AllowExecutionFromEventBridgeSOAR"
  action        = "lambda:InvokeFunction"
  function_name = var.soar_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.finding_created_rule.arn
}
