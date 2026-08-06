# [lab12]
# Package

data "archive_file" "detector" {
  type        = "zip"
  source_dir  = "${path.module}/src/detector"
  output_path = "${path.module}/build/detector.zip"
}

# unused-token-detector (lessonf + lessong)
#
# Scheduled by EventBridge. Finds tokens issued but never used,
# enriches each through Bedrock, escalates through SNS.
#
# timeout is 60s, not the 3s default: a scan plus one Bedrock
# call per finding will not finish in three seconds, and the
# failure looks like a silent timeout in CloudWatch rather than
# an error.

resource "aws_lambda_function" "detector" {
  function_name    = "${var.project}-unused-token-detector"
  role             = aws_iam_role.detector_role.arn
  handler          = "detection.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.detector.output_path
  source_code_hash = data.archive_file.detector.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      TOKEN_TABLE          = aws_dynamodb_table.token_tracking.name
      UNUSED_AFTER_MINUTES = var.unused_after_minutes
      BEDROCK_MODEL_ID     = var.bedrock_model_id
      SNS_TOPIC_ARN        = aws_sns_topic.alerts.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.detector]
}
