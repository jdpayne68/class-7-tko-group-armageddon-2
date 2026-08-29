# ================================================================
# THREAT INTELLIGENCE AGENT
# ================================================================

# -------------------------------------------------------------------------------
# Variable - AbuseIPDB API Key
# -------------------------------------------------------------------------------
variable "abuseipdb_api_key" {
  description = "Optional AbuseIPDB API key used by the Threat Intelligence Agent for IP reputation enrichment."
  type        = string
  default     = ""
  sensitive   = true
}

# -------------------------------------------------------------------------------
# Variable - Threat Intelligence Providers
# -------------------------------------------------------------------------------
variable "threat_intelligence_enabled_providers" {
  description = "Comma-separated provider allow-list for the Threat Intelligence Agent."
  type        = string
  default     = "cisa_kev,abuseipdb,mitre_attack"
}

# -------------------------------------------------------------------------------
# Locals - Threat Intelligence Agent
# -------------------------------------------------------------------------------
locals {
  threat_intelligence_agent_function_name = "${local.name_prefix}-threat-intelligence-agent-${local.name_suffix}"
  threat_intelligence_reports_table_name  = "${local.name_prefix}-threat-intelligence-reports-${local.name_suffix}"
}

# ================================================================
# THREAT INTELLIGENCE STORAGE
# ================================================================

# -------------------------------------------------------------------------------
# DynamoDB Table - Threat Intelligence Reports
# -------------------------------------------------------------------------------
resource "aws_dynamodb_table" "threat_intelligence_reports" {
  name         = local.threat_intelligence_reports_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "report_id"

  attribute {
    name = "report_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# -------------------------------------------------------------------------------
# S3 Bucket - Threat Intelligence Reports
# -------------------------------------------------------------------------------
resource "aws_s3_bucket" "threat_intelligence_report_bucket" {
  bucket        = "${local.name_prefix}-threat-intel-reports-${local.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "threat_intelligence_report_bucket" {
  bucket = aws_s3_bucket.threat_intelligence_report_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "threat_intelligence_report_bucket" {
  bucket = aws_s3_bucket.threat_intelligence_report_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_public_access_block" "threat_intelligence_report_bucket" {
  bucket                  = aws_s3_bucket.threat_intelligence_report_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ================================================================
# THREAT INTELLIGENCE IAM
# ================================================================

# -------------------------------------------------------------------------------
# Threat Intelligence Agent Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "threat_intelligence_agent" {
  name        = "${local.name_prefix}-threat-intelligence-agent-${local.name_suffix}"
  description = "Allows Threat Intelligence Agent to read incident context, store reports, and update incident enrichment metadata"
  policy      = data.aws_iam_policy_document.threat_intelligence_agent.json
}

data "aws_iam_policy_document" "threat_intelligence_agent" {
  # DynamoDB Read permissions - incident and finding context
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem"
    ]
    resources = [
      aws_dynamodb_table.waf_security_incidents.arn,
      aws_dynamodb_table.waf_correlation_findings.arn,
    ]
  }

  # DynamoDB Write permissions - threat-intelligence reports
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [
      aws_dynamodb_table.threat_intelligence_reports.arn,
    ]
  }

  # DynamoDB Update permissions - source incident enrichment
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.waf_security_incidents.arn,
    ]
  }

  # S3 Report Bucket permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.threat_intelligence_report_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.threat_intelligence_report_bucket.arn}/*",
    ]
  }
}

# -------------------------------------------------------------------------------
# SOAR Response Agent EventBridge Publish Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "soar_response_agent_threat_intel_events" {
  name        = "${local.name_prefix}-soar-threat-intel-events-${local.name_suffix}"
  description = "Allows SOAR Response Agent to publish incident-created events for threat-intelligence enrichment"
  policy      = data.aws_iam_policy_document.soar_response_agent_threat_intel_events.json
}

data "aws_iam_policy_document" "soar_response_agent_threat_intel_events" {
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "arn:${local.partition}:events:${local.region}:${local.account_id}:event-bus/default"
    ]
  }
}

# -------------------------------------------------------------------------------
# EventBridge Permissions - Invoke Threat Intelligence Agent
# -------------------------------------------------------------------------------
resource "aws_lambda_permission" "threat_intelligence_agent_soar_event" {
  statement_id  = "AllowEventBridgeThreatIntelInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.threat_intelligence_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.threat_intelligence_agent_soar_event.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Threat Intelligence Agent
# -------------------------------------------------------------------------------
resource "aws_iam_role" "threat_intelligence_agent_role" {
  name               = "${local.name_prefix}-threat-intelligence-agent-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Threat Intelligence Agent Lambda"
}

resource "aws_iam_role_policy_attachment" "threat_intelligence_agent_basic_execution" {
  role       = aws_iam_role.threat_intelligence_agent_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "threat_intelligence_agent" {
  role       = aws_iam_role.threat_intelligence_agent_role.name
  policy_arn = aws_iam_policy.threat_intelligence_agent.arn
}

resource "aws_iam_role_policy_attachment" "threat_intelligence_agent_appsignals" {
  role       = aws_iam_role.threat_intelligence_agent_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}

resource "aws_iam_role_policy_attachment" "soar_response_agent_threat_intel_events" {
  role       = aws_iam_role.soar_response_agent_role.name
  policy_arn = aws_iam_policy.soar_response_agent_threat_intel_events.arn
}

# ================================================================
# THREAT INTELLIGENCE LOGS
# ================================================================

# -------------------------------------------------------------------------------
# CloudWatch Log Group - Threat Intelligence Agent
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "threat_intelligence_agent" {
  name              = "/aws/lambda/${local.threat_intelligence_agent_function_name}"
  retention_in_days = var.log_retention_days
}

# ================================================================
# THREAT INTELLIGENCE LAMBDA
# ================================================================

# -------------------------------------------------------------------------------
# Lambda Function - Threat Intelligence Agent
# -------------------------------------------------------------------------------
# Zip Archive - Threat Intelligence Agent Lambda
data "archive_file" "threat_intelligence_agent" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src/threat_intelligence_agent"
  output_path = "${path.module}/lambda/src/threat-intelligence-agent.zip"

  excludes = [
    "test_events/**",
    "**/.DS_Store",
    "**/__pycache__",
    "**/*.pyc",
  ]
}

# Lambda Function - Threat Intelligence Agent
resource "aws_lambda_function" "threat_intelligence_agent" {
  filename         = data.archive_file.threat_intelligence_agent.output_path
  source_code_hash = data.archive_file.threat_intelligence_agent.output_base64sha256

  function_name = local.threat_intelligence_agent_function_name
  description   = "Enriches SOAR incidents with provider-based threat intelligence, fusion risk, and report artifacts"
  role          = aws_iam_role.threat_intelligence_agent_role.arn

  handler     = "threat-intelligence-agent.lambda_handler"
  runtime     = "python3.14"
  memory_size = 256
  timeout     = var.bedrock_lambda_timeout

  layers = [
    "arn:${local.partition}:lambda:${local.region}:615299751070:layer:AWSOpenTelemetryDistroPython:5"
  ]

  environment {
    variables = {
      THREAT_INTEL_REPORTS_TABLE = aws_dynamodb_table.threat_intelligence_reports.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.waf_security_incidents.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      REPORT_BUCKET              = aws_s3_bucket.threat_intelligence_report_bucket.id
      REPORT_PREFIX              = "threat-intelligence"
      ENABLED_PROVIDERS          = var.threat_intelligence_enabled_providers
      ABUSEIPDB_API_KEY          = var.abuseipdb_api_key
      STORE_REPORTS              = "true"
      UPDATE_INCIDENT            = "true"
      DEFAULT_INDICATOR_TYPE     = "IP"
      ABUSEIPDB_ENDPOINT         = "https://api.abuseipdb.com/api/v2/check"
      ABUSEIPDB_MAX_AGE_DAYS     = "90"
      CISA_KEV_URL               = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"
      MITRE_STIX_URL             = ""
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.threat_intelligence_agent,
    aws_iam_role_policy_attachment.threat_intelligence_agent_basic_execution,
    aws_iam_role_policy_attachment.threat_intelligence_agent,
    aws_iam_role_policy_attachment.threat_intelligence_agent_appsignals,
  ]
}

# ================================================================
# THREAT INTELLIGENCE EVENTBRIDGE
# ================================================================

# -------------------------------------------------------------------------------
# EventBridge Rule - Threat Intelligence Agent - SOAR Incident Created
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "threat_intelligence_agent_soar_event" {
  name        = "${local.name_prefix}-threat-intel-soar-event-${local.name_suffix}"
  description = "Triggers Threat Intelligence Agent after SOAR creates or reuses a security incident"

  event_pattern = jsonencode({
    source      = ["seir.soar"]
    detail-type = ["Security Incident Created"]
    detail = {
      incident_id = [{ exists = true }]
      finding_id  = [{ exists = true }]
    }
  })
}

resource "aws_cloudwatch_event_target" "threat_intelligence_agent_soar_event" {
  rule      = aws_cloudwatch_event_rule.threat_intelligence_agent_soar_event.name
  target_id = "threat-intelligence-agent"
  arn       = aws_lambda_function.threat_intelligence_agent.arn
}

# ================================================================
# THREAT INTELLIGENCE OUTPUTS
# ================================================================

# -------------------------------------------------------------------------------
# Output - Threat Intelligence Agent
# -------------------------------------------------------------------------------
output "threat_intelligence_agent" {
  description = "Threat Intelligence Agent Lambda, storage, and EventBridge integration."
  value = {
    function_name = aws_lambda_function.threat_intelligence_agent.function_name
    log_group     = aws_cloudwatch_log_group.threat_intelligence_agent.name
    reports_table = aws_dynamodb_table.threat_intelligence_reports.name
    report_bucket = aws_s3_bucket.threat_intelligence_report_bucket.id
    event_rule    = aws_cloudwatch_event_rule.threat_intelligence_agent_soar_event.name
  }
}

# -------------------------------------------------------------------------------
# Output - Threat Intelligence Test Command
# -------------------------------------------------------------------------------
output "threat_intelligence_test_command" {
  description = "AWS CLI command for invoking the Threat Intelligence Agent with its bundled test event."
  value       = "aws lambda invoke --function-name ${aws_lambda_function.threat_intelligence_agent.function_name} --payload fileb://lambda/src/threat_intelligence_agent/test_events/threat-intelligence-test.json /tmp/threat-intelligence-response.json --region ${local.region}"
}
