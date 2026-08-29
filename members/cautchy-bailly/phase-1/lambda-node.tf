# [lab12]
# Package

data "archive_file" "node" {
  type        = "zip"
  source_dir  = "${path.module}/src/node"
  output_path = "${path.module}/build/node.zip"
}

# Lambda Node function

resource "aws_lambda_function" "node" {
  function_name    = "${var.project}-node-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.node.output_path
  source_code_hash = data.archive_file.node.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TOKEN_TABLE = aws_dynamodb_table.token_tracking.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.node]
}
