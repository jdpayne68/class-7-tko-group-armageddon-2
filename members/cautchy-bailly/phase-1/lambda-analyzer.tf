# [lab12]
# Sensor -> Analyzer
#
# Reads recent WAF logs, normalizes each event, stores it, and
# asks Bedrock for a per-event incident summary.
#
# This is the lab12 analyzer, not the lesson-h one. It adds a
# deterministic event_id (so replays dedupe), event_epoch (which
# the correlation agent filters on), rule_type and web_acl_id.

data "archive_file" "analyzer" {
  type        = "zip"
  source_dir  = "${path.module}/src/analyzer"
  output_path = "${path.module}/build/analyzer.zip"
}

resource "aws_lambda_function" "analyzer" {
  function_name    = "${var.project}-waf-bedrock-analyzer"
  role             = aws_iam_role.analyzer_role.arn
  handler          = "waf_bedrock_analyzer.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.analyzer.output_path
  source_code_hash = data.archive_file.analyzer.output_base64sha256
  timeout          = 120
  memory_size      = 256

  environment {
    variables = {
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE   = aws_dynamodb_table.waf_events.name
      BEDROCK_MODEL_ID = var.bedrock_model_id
      ENABLE_BEDROCK   = tostring(var.enable_bedrock)
      LOOKBACK_MINUTES = var.waf_lookback_minutes
      MAX_LOG_EVENTS   = var.max_log_events
    }
  }

  depends_on = [aws_cloudwatch_log_group.analyzer]
}
