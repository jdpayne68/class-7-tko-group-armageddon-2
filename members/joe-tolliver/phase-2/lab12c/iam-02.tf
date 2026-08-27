resource "aws_iam_role" "report_lab" {
  name = "report-lab"

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


resource "aws_iam_role_policy" "report_policy" {
  name = "report_policy"
  role = aws_iam_role.report_lab.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "ReadSecurityData",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:Scan"
        ],
        "Resource" : [
          aws_dynamodb_table.waf_events.arn,
          aws_dynamodb_table.waf_correlation_findings.arn,
          aws_dynamodb_table.security_incidents.arn
        ]
      },
      {
       "Sid": "WriteLogs",
        "Effect": "Allow",
        "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        "Resource": "*"
      }, 
      {
        "Sid" : "InvokeBedrock",
        "Effect" : "Allow",
        "Action" : [
          "bedrock:InvokeModel"
        ],
        "Resource" : [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0", "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      },
      {
        "Sid" : "WriteExecutiveReports",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.seir_bucket.arn}/${local.report_prefix}/*"
          ]
        
      }
    ]
  })
}