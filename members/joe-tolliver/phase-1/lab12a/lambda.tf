# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function

#######################
# Waf Bedrock Analyzer
#######################

data "archive_file" "waf_bedrock_analyze" {
  type        = "zip"
  source_file = "./code/waf_bedrock_analyzer.py"
  output_path = "./function/waf_bedrock_analyzer.zip"
}

resource "aws_lambda_function" "waf_bedrock_analyzer" {
  function_name = "waf-bedrock-analyzer"
  role          = aws_iam_role.waf_execution.arn
  handler       = "waf_bedrock_analyzer.lambda_handler"
  code_sha256   = data.archive_file.waf_bedrock_analyze.output_base64sha256
  filename      = data.archive_file.waf_bedrock_analyze.output_path
  timeout       = 90
  memory_size   = 256

  environment {
    variables = {
      WAF_LOG_GROUP  = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE = aws_dynamodb_table.waf_events.name

      BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
      LOOKBACK_MINUTES = 10
      MAX_LOG_EVENTS   = 25
    }
  }

  runtime = "python3.14"
}


##########################
# Waf Threat Correlation
##########################

data "archive_file" "waf_threat_correlation" {
  type        = "zip"
  source_file = "./code/waf_threat_correlation_agent.py"
  output_path = "./function/waf_threat_correlation_agent.zip"
}

resource "aws_lambda_function" "waf_threat_correlation_agent" {
  function_name = "waf-threat-correlation-agent"
  role          = aws_iam_role.waf_execution.arn
  handler       = "waf_threat_correlation_agent.lambda_handler"
  code_sha256   = data.archive_file.waf_threat_correlation.output_base64sha256
  filename      = data.archive_file.waf_threat_correlation.output_path
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name

      BEDROCK_MODEL_ID           = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
      CORRELATION_WINDOW_MINUTES = 60
      MINIMUM_EVENT_COUNT        = 3
      MAX_EVENTS                 = 500
      ADMIN_URI_KEYWORDS         = "admin,login,signin,auth,token,cognito"
    }
  }

  runtime = "python3.14"
}


################
# SOAR Lambda
################

data "archive_file" "soar_agent" {
  type        = "zip"
  source_file = "./code/soar_response_agent.py"
  output_path = "./function/soar_response_agent.zip"
}

resource "aws_lambda_function" "soar_response_agent" {
  function_name = "soar-response-agent"
  role          = aws_iam_role.waf_execution.arn
  handler       = "soar_response_agent.lambda_handler"
  code_sha256   = data.archive_file.soar_agent.output_base64sha256
  filename      = data.archive_file.soar_agent.output_path
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name

      SOAR_NOTIFICATIONS_TOPIC_ARN = aws_sns_topic.soar_notifications.arn
      CRITICAL_ALERTS_TOPIC_ARN    = aws_sns_topic.critical_alerts.arn
      BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
      ENABLE_BEDROCK   = true
    }
  }

  runtime = "python3.14"
}
