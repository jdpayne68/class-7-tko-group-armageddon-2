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