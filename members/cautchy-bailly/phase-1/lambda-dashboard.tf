# [lab12b]
# Executive Dashboard Agent (lab12b)
#
# Scans all three tables for the reporting period, asks Bedrock
# for an executive narrative, and writes a synchronized PDF and
# JSON pair to S3.
#
# reportlab is NOT in the Lambda runtime. It ships as a layer -
# run scripts/build_layer.sh before the first apply.

data "archive_file" "reportlab_layer" {
  type        = "zip"
  source_dir  = "${path.module}/layers/reportlab"
  output_path = "${path.module}/build/reportlab-layer.zip"
}

resource "aws_lambda_layer_version" "reportlab" {
  layer_name          = "${var.project}-reportlab"
  description         = "reportlab 4.4.3 for PDF generation"
  filename            = data.archive_file.reportlab_layer.output_path
  source_code_hash    = data.archive_file.reportlab_layer.output_base64sha256
  compatible_runtimes = ["python3.13"]
}

data "archive_file" "dashboard" {
  type        = "zip"
  source_dir  = "${path.module}/src/dashboard"
  output_path = "${path.module}/build/dashboard.zip"
}

resource "aws_lambda_function" "dashboard" {
  function_name    = "${var.project}-executive-dashboard-agent"
  role             = aws_iam_role.dashboard_role.arn
  handler          = "executive_dashboard_agent.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.dashboard.output_path
  source_code_hash = data.archive_file.dashboard.output_base64sha256

  # Per lab12b: 1024 MB, 120s, 512 MB ephemeral. The PDF is built in
  # memory, so /tmp is only needed if later revisions add chart images.
  timeout     = 120
  memory_size = 1024

  # NOTE: reserved_concurrent_executions was set to 2 to cap this function's
  # blast radius (it is the only 1 GB agent). It is omitted because reserving
  # ANY concurrency requires the account's unreserved pool to stay at or above
  # 10, and a constrained account has too little headroom for that. The daily
  # schedule means real contention here is near zero anyway. To re-enable on an
  # account with room, set a value and confirm:
  #   aws lambda get-account-settings \
  #     --query 'AccountLimit.UnreservedConcurrentExecutions'

  ephemeral_storage {
    size = 512
  }

  layers = [aws_lambda_layer_version.reportlab.arn]

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name

      REPORT_BUCKET = aws_s3_bucket.reports.bucket
      REPORT_PREFIX = var.report_prefix

      BEDROCK_MODEL_ID = var.bedrock_model_id
      ENABLE_BEDROCK   = tostring(var.enable_bedrock)

      REPORT_PERIOD_HOURS = var.report_period_hours
      MAX_ITEMS_PER_TABLE = var.max_items_per_table

      ORGANIZATION_NAME = var.organization_name
      REPORT_TITLE      = var.report_title
    }
  }

  depends_on = [aws_cloudwatch_log_group.dashboard]
}
