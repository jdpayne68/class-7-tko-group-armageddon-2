resource "aws_iam_role" "compliance_evidence_agent_role" {
  name = "compliance-evidence-agent-role"

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

resource "aws_iam_role_policy" "compliance_evidence_agent_policy" {
  name = "compliance-evidence-agent-policy"
  role = aws_iam_role.compliance_evidence_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "ReadSecurityData",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DescribeTable",
          "dynamodb:Scan"
        ],
        "Resource" : [
          aws_dynamodb_table.waf_events.arn,
          aws_dynamodb_table.waf_correlation_findings.arn,
          aws_dynamodb_table.security_incidents.arn
        ]
      },
      {
        "Sid" : "WriteComplianceEvidence",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : [
          aws_dynamodb_table.compliance_evidence.arn
        ]
      },
      {
        "Sid" : "InvokeBedrock",
        "Effect" : "Allow",
        "Action" : [
          "bedrock:InvokeModel"
        ],
        "Resource" : [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      },
      {
        "Sid" : "ListExecutiveReportsPrefix",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : aws_s3_bucket.seir_bucket.arn,
        "Condition" : {
          "StringLike" : {
            "s3:prefix" : ["executive-reports/*"]
          }
        }
      },
      {
        "Sid" : "WriteComplianceReports",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.seir_bucket.arn}/compliance-reports/*"
        ]
      },
      {
        "Sid" : "WriteLogs",
        "Effect" : "Allow",
        "Action" : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        "Resource" : "*"
      }
    ]
  })
}