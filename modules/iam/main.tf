
# IAM Roles for ARMAGEDDON Lambda Functions


# Reusable trust policy for Lambda
# This policy document allows Lambda functions to assume the IAM role.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      # The service principal for AWS Lambda functions
      # This is required for the Lambda service to assume the role.
      identifiers = ["lambda.amazonaws.com"] # this one worked. the other attempts failed
    }
  }
}


# WAF Analyzer Lambda Role
# this role allows the WAF Analyzer Lambda function to read WAF logs from CloudWatch and write raw events to DynamoDB

# IAM role for the WAF Analyzer Lambda function
resource "aws_iam_role" "waf_analyzer_role" {
  name               = "${var.prefix}-waf-analyzer-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.common_tags
}


# IAM policy for the WAF Analyzer Lambda function
resource "aws_iam_role_policy" "waf_analyzer_policy" {
  role = aws_iam_role.waf_analyzer_role.id # refers to the WAF Analyzer Lambda IAM role
#
# Reads WAF logs from CloudWatch


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read WAF logs from CloudWatch
      {
        Effect   = "Allow"
        Action   = ["logs:FilterLogEvents", "logs:GetLogEvents"]
        Resource = "*"
      },
      # Write raw events to DynamoDB
      # Writes raw events into DynamoDB
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = var.waf_events_table_arn
      }
    ]
  })
}





# this role allows the Threat Correlation Lambda function to read raw WAF events and write correlated findings
# Threat Correlation Lambda Role
# Reads raw WAF events

# Writes correlated findings

resource "aws_iam_role" "threat_correlation_role" {
  name               = "${var.prefix}-threat-correlation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.common_tags
}


# IAM policy for the Threat Correlation Lambda function
# This Lambda cannot read incidents or write to S3 or SNS
resource "aws_iam_role_policy" "threat_correlation_policy" {
  role = aws_iam_role.threat_correlation_role.id # refers to the Threat Correlation Lambda IAM role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read raw WAF events
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan", "dynamodb:Query"]
        Resource = var.waf_events_table_arn
      },
      # Write correlated findings
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = var.waf_correlation_findings_table_arn
      }
    ]
  })
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "threat_correlation_eventbridge_policy" {
  name = "${var.prefix}-threat-correlation-eventbridge-policy"
  role = aws_iam_role.threat_correlation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/default"
      }
    ]
  })
}



# SOAR Response Lambda Role
# this role allows the SOAR Response Lambda function to read correlated findings, write security incidents, and send alerts to SNS
# Reads correlated findings

# Writes security incidents

# Sends alerts to SNS


resource "aws_iam_role" "soar_response_role" {
  name               = "${var.prefix}-soar-response-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.common_tags
}

resource "aws_iam_role_policy" "soar_response_policy" {
  role = aws_iam_role.soar_response_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read correlated findings
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan", "dynamodb:Query"]
        Resource = var.waf_correlation_findings_table_arn
      },
      # Write security incidents
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = var.security_incidents_table_arn
      },
      # Send alerts to SNS
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Executive Dashboard Lambda Role
# this role allows the Executive Dashboard Lambda function to read security incidents and write reports to S3

# Reads security incidents

# Writes reports to S3


resource "aws_iam_role" "executive_dashboard_role" {
  name               = "${var.prefix}-executive-dashboard-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.common_tags
}

resource "aws_iam_role_policy" "executive_dashboard_policy" {
  role = aws_iam_role.executive_dashboard_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read incidents
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan", "dynamodb:Query"]
        Resource = var.security_incidents_table_arn
      },
      # Write reports to S3
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.reports_bucket_arn}/*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "soar_basic_execution" {
  role       = aws_iam_role.soar_response_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy_attachment" "threat_correlation_logs" {
  role       = aws_iam_role.threat_correlation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "soar_role" {
  name = "${var.prefix}-soar-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


# resource "aws_lambda_function" "soar" {
#   function_name = "${var.prefix}-soar"
#   role          = var.soar_role_arn
#   handler       = "handler.lambda_handler"
#   runtime       = "python3.12"
#   filename      = "${path.module}/code/soar.zip"

#   environment {
#     variables = {
#       AWS_REGION = var.aws_region
#       MODEL_ID   = var.model_id
#     }
#   }

#   tags = var.common_tags
# }
