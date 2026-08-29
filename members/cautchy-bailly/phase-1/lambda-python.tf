# [lab12]
# Package
# Replaces the manual "zip python.zip lambda_function.py" step.
# source_code_hash is what makes terraform apply notice handler edits.

data "archive_file" "python" {
  type        = "zip"
  source_dir  = "${path.module}/src/python"
  output_path = "${path.module}/build/python.zip"
}

# Lambda Python function

resource "aws_lambda_function" "python" {
  function_name    = "${var.project}-python-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  filename         = data.archive_file.python.output_path
  source_code_hash = data.archive_file.python.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TOKEN_TABLE = aws_dynamodb_table.token_tracking.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.python]
}
