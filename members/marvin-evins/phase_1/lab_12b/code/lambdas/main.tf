
# Lambda Functions for ARMAGEDDON SOAR Platform

# WAF Analyzer Lambda
# what this does is analyze WAF events and store them in the WAF events DynamoDB table
resource "aws_lambda_function" "waf_analyzer" {
  function_name = "${var.prefix}-waf-analyzer"
  role          = var.waf_analyzer_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/code/waf_analyzer.zip"

  environment {
    variables = {
      WAF_EVENTS_TABLE = var.waf_events_table_name
    }
  }

  tags = var.common_tags
}

# Threat Correlation Lambda
# what this does is correlate WAF events and store the findings in the WAF correlation findings DynamoDB table

resource "aws_lambda_function" "threat_correlation" {
  function_name = "${var.prefix}-threat-correlation"
  role          = var.threat_correlation_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/code/threat_correlation.zip"

  environment {
    # environment variables for the Threat Correlation Lambda
    #there are two tables here for the Threat Correlation Lambda
    variables = {
      WAF_EVENTS_TABLE               = var.waf_events_table_name
      WAF_CORRELATION_FINDINGS_TABLE = var.waf_correlation_findings_table_name
    }
  }

  tags = var.common_tags
}

# module "soar" {
#   source = "./code/soar"

#   soar_lambda_arn = var.soar_lambda_arn
# }

# SOAR Response Lambda
# what this does is respond to security incidents based on the correlated findings and send alerts via SNS
resource "aws_lambda_function" "soar_response" {
  function_name    = "${var.prefix}-soar-response"
  role             = var.soar_response_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = "${path.module}/code/soar_response.zip"
  source_code_hash = filebase64sha256("${path.module}/code/soar_response.zip")

  environment {
    # environment variables for the SOAR Response Lambda
    # there are three variables here: the WAF correlation findings table, the security incidents table, and the SNS topic ARN
    variables = {
      WAF_CORRELATION_FINDINGS_TABLE = var.waf_correlation_findings_table_name
      SECURITY_INCIDENTS_TABLE       = var.security_incidents_table_name
      SNS_TOPIC_ARN                  = var.sns_topic_arn
    }
  }

  tags = var.common_tags
}


# Executive Dashboard Lambda
# what this does is read security incidents and write reports to the S3 bucket
# environment variables for the Executive Dashboard Lambda
# there are two variables here: the security incidents table and the reports S3 bucket

resource "aws_lambda_function" "executive_dashboard" {
  function_name = "${var.prefix}-executive-dashboard"
  role          = var.executive_dashboard_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/code/executive_dashboard.zip"

  environment {
    variables = {
      SECURITY_INCIDENTS_TABLE = var.security_incidents_table_name
      REPORTS_BUCKET           = var.reports_bucket_name
    }
  }

  tags = var.common_tags
}



resource "aws_lambda_function" "soar" {
  function_name    = "${var.prefix}-soar"
  role             = var.soar_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = "${path.module}/code/soar.zip"
  source_code_hash = filebase64sha256("${path.module}/code/soar.zip")
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      # AWS_REGION = var.aws_region
      MODEL_ID = var.model_id
    }
  }

  tags = var.common_tags
}








# Compliance Lambda
# Lab 12C
# Evaluates compliance controls, stores evidence in DynamoDB,
# and generates JSON/PDF compliance reports in S3.


resource "aws_lambda_function" "compliance" {
  function_name = "${var.prefix}-compliance"

  role    = var.compliance_role_arn
  handler = "compliance.lambda_handler"
  runtime = "python3.12"

  filename         = "${path.module}/code/compliance.zip"
  source_code_hash = filebase64sha256("${path.module}/code/compliance.zip")

  timeout     = 60
  memory_size = 512

  environment {
    variables = {
      COMPLIANCE_EVIDENCE_TABLE = var.compliance_evidence_table_name
      REPORT_BUCKET             = var.reports_bucket_name
      REPORT_PREFIX             = "compliance-reports"

      COMPLIANCE_FRAMEWORKS = "NIST CSF 2.0"
      ENABLE_BEDROCK        = "true"
      BEDROCK_MODEL_ID      = "us.anthropic.claude-sonnet-4-6"

      ORGANIZATION_NAME              = "Armageddon"
      REPORT_TITLE                   = "Armageddon Compliance Evidence Report"
      WAF_EVENTS_TABLE               = var.waf_events_table_name
      WAF_CORRELATION_FINDINGS_TABLE = var.waf_correlation_findings_table_name
      SECURITY_INCIDENTS_TABLE       = var.security_incidents_table_name

      CONTROLS_FILE = "/var/task/controls.json"
    }
  }

  tags = var.common_tags
}
