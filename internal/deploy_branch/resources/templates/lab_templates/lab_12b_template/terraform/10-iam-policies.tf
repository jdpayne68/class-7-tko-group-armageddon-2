# ================================================================
# IAM POLICIES
# ================================================================

# -------------------------------------------------------------------------------
# Jedi And Sith Route Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "route_lambda_token_update" {
  name        = "${local.name_prefix}-route-token-update-${local.name_suffix}"
  description = "Allows the Jedi and Sith route Lambdas to mark token records as used"
  policy      = data.aws_iam_policy_document.route_lambda_token_update.json
}

data "aws_iam_policy_document" "route_lambda_token_update" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.token_holocron.arn]
  }
}

# -------------------------------------------------------------------------------
# Unused Token Detector Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "token_detector_scan" {
  name        = "${local.name_prefix}-token-detector-scan-${local.name_suffix}"
  description = "Allows the unused-token detector Lambda to scan token records"
  policy      = data.aws_iam_policy_document.token_detector_scan.json
}

data "aws_iam_policy_document" "token_detector_scan" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.token_holocron.arn]
  }
}

# -------------------------------------------------------------------------------
# WAF Bedrock Analyzer Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "waf_bedrock_analyzer" {
  name        = "${local.name_prefix}-waf-bedrock-analyzer-policy-${local.name_suffix}"
  description = "Allows WAF log analyzer Lambda to filter CloudWatch logs, invoke Bedrock models, and store WAF events in DynamoDB"
  policy      = data.aws_iam_policy_document.waf_bedrock_analyzer.json
}

data "aws_iam_policy_document" "waf_bedrock_analyzer" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
  # Bedrock Permissions - Invoke Model
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = local.bedrock_invoke_resources
  }
  # DynamoDB Permissions
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.shield_generator_events.arn]
  }
}

# -------------------------------------------------------------------------------
# WAF Threat Correlation Agent Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "waf_threat_correlation_agent" {
  name        = "${local.name_prefix}-waf-threat-correlation-agent-policy-${local.name_suffix}"
  description = "Allows WAF threat correlation agent Lambda to read CloudWatch logs, query WAF events from DynamoDB, write correlation findings, and invoke Bedrock models"
  policy      = data.aws_iam_policy_document.waf_threat_correlation_agent.json
}

data "aws_iam_policy_document" "waf_threat_correlation_agent" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }


  # DynamoDB Read permissions - WAF Events Table
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem"
    ]
    resources = [
      aws_dynamodb_table.shield_generator_events.arn,
      "${aws_dynamodb_table.shield_generator_events.arn}/index/*"
    ]
  }
  # DynamoDB Write permissions - Correlation Findings Table
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.waf_correlation_findings.arn
    ]
  }
  # Bedrock Permissions - Invoke Model
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = local.bedrock_invoke_resources
  }

  # EventBridge Permissions
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = ["*"]
  }
}

# -------------------------------------------------------------------------------
# SOAR Response Agent Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "soar_response_agent" {
  name        = "${local.name_prefix}-soar-response-agent-policy-${local.name_suffix}"
  description = "Allows SOAR Response Agent to read correlation findings, create security incidents, invoke Bedrock, and publish SNS notifications"
  policy      = data.aws_iam_policy_document.soar_response_agent.json
}

data "aws_iam_policy_document" "soar_response_agent" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }

  # DynamoDB Read - Correlation Findings Table
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.waf_correlation_findings.arn
    ]
  }

  # DynamoDB Write - Security Incidents Table
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [
      aws_dynamodb_table.waf_security_incidents.arn
    ]
  }

  # Bedrock Permissions - Invoke Model
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = local.bedrock_invoke_resources
  }

  # SNS Publish Permissions
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.waf_security_incidents_alert.arn
    ]
  }
}

# -------------------------------------------------------------------------------
# Executive Dashboard Agent Lambda Permissions
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "executive_dashboard" {
  name        = "${local.name_prefix}-executive-dashboard-${local.name_suffix}"
  description = "Allows Executive Dashboard Agent to read tables and write to S3"
  policy      = data.aws_iam_policy_document.executive_dashboard.json
}

data "aws_iam_policy_document" "executive_dashboard" {
  # DynamoDB Read permissions
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem"
    ]
    resources = [
      aws_dynamodb_table.shield_generator_events.arn,
      aws_dynamodb_table.waf_correlation_findings.arn,
      aws_dynamodb_table.waf_security_incidents.arn,
    ]
  }

  # S3 Write permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.executive_report_bucket.arn}/*",
    ]
  }

  # Bedrock Permissions - Invoke Model
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = local.bedrock_invoke_resources
  }
}

# -------------------------------------------------------------------------------
# EventBridge Scheduler Permissions - Invoke Unused Token Detector
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "scheduler_invoke_detector" {
  name        = "${local.name_prefix}-scheduler-invoke-detector-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the unused-token detector"
  policy      = data.aws_iam_policy_document.scheduler_invoke_detector.json
}

data "aws_iam_policy_document" "scheduler_invoke_detector" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.unused_token_detector.arn]
  }
}

# -------------------------------------------------------------------------------
# EventBridge Scheduler Permissions - Invoke WAF Bedrock Analyzer Lambda
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "scheduler_invoke_analyzer" {
  name        = "${local.name_prefix}-scheduler-invoke-analyzer-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the WAF Bedrock analyzer"
  policy      = data.aws_iam_policy_document.scheduler_invoke_analyzer.json
}

data "aws_iam_policy_document" "scheduler_invoke_analyzer" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.waf_bedrock_analyzer.arn]
  }
}

# -------------------------------------------------------------------------------
# EventBridge Scheduler Permissions - Invoke Threat Correlation
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "scheduler_invoke_correlation" {
  name        = "${local.name_prefix}-scheduler-invoke-correlation-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the threat correlation agent"
  policy      = data.aws_iam_policy_document.scheduler_invoke_correlation.json
}

data "aws_iam_policy_document" "scheduler_invoke_correlation" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.waf_threat_correlation_agent.arn]
  }
}

# -------------------------------------------------------------------------------
# EventBridge Permissions - Invoke SOAR Response
# -------------------------------------------------------------------------------
resource "aws_lambda_permission" "soar_response_medium_high" {
  statement_id  = "AllowEventBridgeMediumHigh-${local.name_suffix}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.soar_response_medium_high.arn
}

resource "aws_lambda_permission" "soar_response_critical" {
  statement_id  = "AllowEventBridgeCritical-${local.name_suffix}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_agent.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.soar_response_critical.arn
}

# -------------------------------------------------------------------------------
# EventBridge Permissions - SNS Publish
# -------------------------------------------------------------------------------
resource "aws_sns_topic_policy" "waf_security_incidents_alert" {
  arn = aws_sns_topic.waf_security_incidents_alert.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.waf_security_incidents_alert.arn
      }
    ]
  })
}

# -------------------------------------------------------------------------------
# EventBridge Scheduler Permissions - Invoke Executive Dashboard Agent
# -------------------------------------------------------------------------------
resource "aws_iam_policy" "scheduler_invoke_executive_dashboard" {
  name        = "${local.name_prefix}-scheduler-invoke-executive-dashboard-${local.name_suffix}"
  description = "Allows EventBridge Scheduler to invoke the executive dashboard Lambda"
  policy      = data.aws_iam_policy_document.scheduler_invoke_executive_dashboard.json
}

data "aws_iam_policy_document" "scheduler_invoke_executive_dashboard" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.executive_dashboard.arn]
  }
}

resource "aws_lambda_permission" "executive_dashboard_scheduler" {
  statement_id  = "AllowSchedulerInvoke-${local.name_suffix}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.executive_dashboard.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.executive_dashboard.arn
}

# -------------------------------------------------------------------------------
# IAM Policy - Application Signals Policy (Copy of AWS Managed Policy)
# -------------------------------------------------------------------------------
# BUG: Attaching the managed policy to Lambda results in the error: "Does not exist or is not attachable"
# Managed Policy: arn:aws:iam::aws:policy/CloudWatchLambdaApplicationSignalsExecutionRolePolicy
# Custom policy used as a workaround
# FIXME: Managed policy can be attached to role in console. Need to debug further to find permanent solution.

resource "aws_iam_policy" "lambda_application_signals_execution_role" {
  name        = "${local.name_prefix}-appsignals-policy-${local.name_suffix}"
  description = "Allows Lambda to write X-Ray trace segments and create CloudWatch log streams for Application Signals telemetry data"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchApplicationSignalsXrayWritePermissions"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments"
        ]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "CloudWatchApplicationSignalsLogGroupWritePermissions"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/application-signals/data:*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}
