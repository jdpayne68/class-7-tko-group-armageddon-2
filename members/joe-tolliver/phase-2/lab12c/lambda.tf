# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
# https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file

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
  timeout = 90
  memory_size = 256

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
  timeout = 60
  memory_size = 256

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
  timeout = 30
  memory_size = 256

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


#############################
# Executive Dashboard Agent
#############################

data "archive_file" "executive_agent" {
  type        = "zip"
  source_file = "./code/executive_dashboard_agent.py"
  output_path = "./function/executive_dashboard_agent.zip"
}

resource "aws_lambda_function" "executive_dashboard_agent" {
  function_name = "executive-dashboard-agent"
  role          = aws_iam_role.report_lab.arn
  handler       = "executive_dashboard_agent.lambda_handler"
  layers        = [aws_lambda_layer_version.reportlab_layer.arn]
  code_sha256   = data.archive_file.executive_agent.output_base64sha256
  filename      = data.archive_file.executive_agent.output_path
  timeout = 120
  memory_size = 1024
  
  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name

      REPORT_BUCKET = aws_s3_bucket.seir_bucket.bucket
      REPORT_PREFIX = local.report_prefix

      BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
      ENABLE_BEDROCK   = true

      REPORT_PERIOD_HOURS = 24
      MAX_ITEMS_PER_TABLE = 5000

      ORGANIZATION_NAME = "SEIR Cloud Security"
      REPORT_TITLE      = "Executive Security Report"
    }
  }

  runtime = "python3.14"
}


#############################
# Compliance Agent
#############################

data "archive_file" "compliance_agent" {
  type        = "zip"
  output_path = "./function/compliance_evidence_agent.zip"

  source {
  content  = file("./code/compliance.py")
  filename = "compliance.py"
}

    source {
    content  = file("./code/controls.json")
    filename = "controls.json"
  }
}

resource "aws_lambda_function" "compliance_evidence_agent" {
  function_name = "compliance-evidence-agent"
  role          = aws_iam_role.compliance_evidence_agent_role.arn
  handler       = "compliance.lambda_handler"
  layers        = [aws_lambda_layer_version.reportlab_layer.arn]
  code_sha256   = data.archive_file.compliance_agent.output_base64sha256
  filename      = data.archive_file.compliance_agent.output_path
  timeout = 90
  memory_size = 256
  
  environment {
    variables = {
      CONTROLS_FILE = "/var/task/controls.json"

      COMPLIANCE_EVIDENCE_TABLE = aws_dynamodb_table.compliance_evidence.name

      REPORT_BUCKET = aws_s3_bucket.seir_bucket.bucket
      REPORT_PREFIX = "compliance-reports"

      COMPLIANCE_FRAMEWORKS = "NIST CSF 2.0,CIS Controls v8"

      BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
      ENABLE_BEDROCK = true

      ORGANIZATION_NAME = "SEIR Cloud Security"
      REPORT_TITLE = "Compliance Evidence Report"
    }
  }

  runtime = "python3.14"
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version

#################
# Lambda Layer
#################

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "./reportlab_layer"
  output_path = "./reportlab_layer/reportlab_layer.zip"
}

resource "aws_lambda_layer_version" "reportlab_layer" {
  filename            = data.archive_file.layer_zip.output_path
  layer_name          = "reportlab-layer"
  compatible_runtimes = ["python3.14"]
}

