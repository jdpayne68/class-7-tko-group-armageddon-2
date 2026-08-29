# [lab12a]
# Threat Correlation Agent -> SOAR Response Agent
#
# Triggered by the EventBridge finding event. Retrieves the
# authoritative finding, validates it is still OPEN, selects a
# deterministic playbook by severity, asks Bedrock for analyst
# and management summaries, creates an incident, notifies, and
# updates workflow status.
#
# Playbooks are chosen by severity, not by the model:
#   LOW      record only
#   MEDIUM   notify analyst
#   HIGH     notify + create incident
#   CRITICAL notify + create incident + request containment approval

data "archive_file" "soar" {
  type        = "zip"
  source_dir  = "${path.module}/src/soar"
  output_path = "${path.module}/build/soar.zip"
}

resource "aws_lambda_function" "soar" {
  function_name    = "${var.project}-soar-response-agent"
  role             = aws_iam_role.soar_role.arn
  handler          = "soar_response_agent.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.soar.output_path
  source_code_hash = data.archive_file.soar.output_base64sha256
  timeout          = 120
  memory_size      = 256

  environment {
    variables = {
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name
      SNS_TOPIC_ARN              = aws_sns_topic.alerts.arn
      BEDROCK_MODEL_ID           = var.bedrock_model_id
      ENABLE_BEDROCK             = tostring(var.enable_bedrock)
    }
  }

  depends_on = [aws_cloudwatch_log_group.soar]
}
