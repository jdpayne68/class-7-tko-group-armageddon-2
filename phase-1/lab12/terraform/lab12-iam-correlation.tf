data "aws_iam_policy_document" "correlation_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "correlation" {
  name               = "${var.project_name}-correlation-role"
  assume_role_policy = data.aws_iam_policy_document.correlation_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "correlation_basic" {
  role       = aws_iam_role.correlation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy_document" "correlation_permissions" {
  statement {
    sid = "ReadWafEvents"

    actions = [
      "dynamodb:Scan",
    ]

    resources = [
      aws_dynamodb_table.waf_events.arn,
    ]
  }

  statement {
    sid = "WriteCorrelationFindings"

    actions = [
      "dynamodb:PutItem",
    ]

    resources = [
      aws_dynamodb_table.correlation_findings.arn,
    ]
  }

  statement {
    sid = "InvokeBedrock"

    actions = [
      "bedrock:InvokeModel",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "PublishFindingEvent"

    actions = [
      "events:PutEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "correlation_permissions" {
  name   = "${var.project_name}-correlation-policy"
  role   = aws_iam_role.correlation.id
  policy = data.aws_iam_policy_document.correlation_permissions.json
}
