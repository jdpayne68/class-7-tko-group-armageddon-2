# [lab12]
# Telemetry Database -> Threat Correlation Agent
#
# Reads normalized events in a time window, computes
# deterministic statistics, scores suspicious source IPs, asks
# Bedrock to interpret the evidence, stores the finding, and
# announces it on the event bus.
#
# The deterministic scoring happens BEFORE Bedrock is called.
# The model interprets evidence; it does not produce the score.

data "archive_file" "correlation" {
  type        = "zip"
  source_dir  = "${path.module}/src/correlation"
  output_path = "${path.module}/build/correlation.zip"
}

resource "aws_lambda_function" "correlation" {
  function_name    = "${var.project}-waf-threat-correlation-agent"
  role             = aws_iam_role.correlation_role.arn
  handler          = "waf_threat_correlation_agent.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.correlation.output_path
  source_code_hash = data.archive_file.correlation.output_base64sha256
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.correlation_findings.name
      BEDROCK_MODEL_ID           = var.bedrock_model_id
      ENABLE_BEDROCK             = tostring(var.enable_bedrock)
      CORRELATION_WINDOW_MINUTES = var.correlation_window_minutes
      MINIMUM_EVENT_COUNT        = var.minimum_event_count
      MAX_EVENTS                 = var.max_correlation_events
      ADMIN_URI_KEYWORDS         = var.admin_uri_keywords

      # Consumed by the publish step added to close the pipeline gap.
      # These must match the EventBridge rule patterns in eventbridge.tf.
      EVENT_BUS_NAME    = "default"
      EVENT_SOURCE      = var.finding_event_source
      EVENT_DETAIL_TYPE = var.finding_event_detail_type
    }
  }

  depends_on = [aws_cloudwatch_log_group.correlation]
}
