
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "waf_execution" {
  name = "soar-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      },
    ]
  })
}


resource "aws_iam_role_policy" "waf_policy" {
  name = "soar_policy"
  role = aws_iam_role.waf_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow"
        "Action" : ["logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents", "logs:FilterLogEvents"
        ],
        "Resource" : "*"
      },

      {
        "Effect" : "Allow"
        "Action" : ["dynamodb:GetItem", "dynamodb:Query",
          "dynamodb:UpdateItem", "dynamodb:Scan"
        ],
        "Resource" : "*"
      },

      {
        "Effect" : "Allow",
        "Action" : ["events:PutEvents"],
        "Resource" : "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
      },

      {
        "Effect" : "Allow"
        "Action" : [
          "dynamodb:PutItem"
        ]
        "Resource" : [aws_dynamodb_table.waf_events.arn, aws_dynamodb_table.waf_correlation_findings.arn, aws_dynamodb_table.security_incidents.arn]
      },

      {
        "Effect" : "Allow",
        "Action" : ["sns:Publish"],
        "Resource" : [aws_sns_topic.soar_notifications.arn, aws_sns_topic.critical_alerts.arn]
      },

      {
        "Effect" : "Allow"
        "Action" : [
          "bedrock:InvokeModel"
        ],
        "Resource" : [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0", "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      },
      #######################################################################################################
      # AWS Marketplace
      # aws-marketplace:Subscribe = Allows an IAM entity to subscribe to AWS Marketplace products, including Amazon Bedrock foundation models.
      # aws-marketplace:ViewSubscriptions = Allows an IAM identity to return a list of AWS Marketplace products, including Amazon Bedrock foundation models.
      # aws-marketplace:Unsubscribe = Allows an IAM identity to unsubscribe from AWS Marketplace products, including Amazon Bedrock foundation models.
      # Once any identity in your account successfully subscribes to this model (in any region), every role/user in the account can invoke it without marketplace permissions going forward
      # https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html#model-access-permissions
      # one-time AWS Marketplace subscription that Bedrock automatically tries to create the first time any identity in your account invokes a third-party model like Claude.
      {
        "Effect" : "Allow"
        "Action" : [
          "aws-marketplace:Subscribe",
          "aws-marketplace:ViewSubscriptions"
        ]
        Resource = "*"
      }
    ]
  })
}


