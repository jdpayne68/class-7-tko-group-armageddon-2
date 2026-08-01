# ================================================================
# LAMBDA ROLES
# ================================================================

# -------------------------------------------------------------------------------
# Shared Lambda Trust Policy
# -------------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Jedi Python
# -------------------------------------------------------------------------------
resource "aws_iam_role" "jedi_python_role" {
  name               = "${local.name_prefix}-lambda-python-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Jedi Python Lambda"
}

resource "aws_iam_role_policy_attachment" "jedi_python_basic_execution" {
  role       = aws_iam_role.jedi_python_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "jedi_python_token_update" {
  role       = aws_iam_role.jedi_python_role.name
  policy_arn = aws_iam_policy.route_lambda_token_update.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Sith Node
# -------------------------------------------------------------------------------
resource "aws_iam_role" "sith_node_role" {
  name               = "${local.name_prefix}-lambda-node-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Sith Node.js Lambda"
}

resource "aws_iam_role_policy_attachment" "sith_node_basic_execution" {
  role       = aws_iam_role.sith_node_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sith_node_token_update" {
  role       = aws_iam_role.sith_node_role.name
  policy_arn = aws_iam_policy.route_lambda_token_update.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Unused Token Detector
# -------------------------------------------------------------------------------
resource "aws_iam_role" "unused_token_detector_role" {
  name               = "${local.name_prefix}-unused-token-detector-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the unused-token detector Lambda"
}

resource "aws_iam_role_policy_attachment" "unused_token_detector_basic_execution" {
  role       = aws_iam_role.unused_token_detector_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "unused_token_detector_scan" {
  role       = aws_iam_role.unused_token_detector_role.name
  policy_arn = aws_iam_policy.token_detector_scan.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Bedrock Analyzer
# -------------------------------------------------------------------------------
resource "aws_iam_role" "waf_bedrock_analyzer_role" {
  name               = "${local.name_prefix}-waf-bedrock-analyzer-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the WAF log forwarder Lambda"
}

resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer_basic_execution" {
  role       = aws_iam_role.waf_bedrock_analyzer_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer" {
  role       = aws_iam_role.waf_bedrock_analyzer_role.name
  policy_arn = aws_iam_policy.waf_bedrock_analyzer.arn
}

# Attach Custom CloudWatch Application Signals Policy
# Provides X-Ray write access and CloudWatch Logs permissions for telemetry data
# This is CORRECT - attaching to the analyzer role
resource "aws_iam_role_policy_attachment" "waf_bedrock_analyzer_appsignals" {
  role       = aws_iam_role.waf_bedrock_analyzer_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - WAF Threat Correlation Agent
# -------------------------------------------------------------------------------
resource "aws_iam_role" "waf_threat_correlation_agent_role" {
  name               = "${local.name_prefix}-waf-threat-correlation-agent-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the WAF threat correlation agent"
}

resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent_basic_execution" {
  role       = aws_iam_role.waf_threat_correlation_agent_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent" {
  role       = aws_iam_role.waf_threat_correlation_agent_role.name
  policy_arn = aws_iam_policy.waf_threat_correlation_agent.arn
}

# Attach Custom CloudWatch Application Signals Policy
# Provides X-Ray write access and CloudWatch Logs permissions for telemetry data
resource "aws_iam_role_policy_attachment" "waf_threat_correlation_agent_appsignals" {
  role       = aws_iam_role.waf_threat_correlation_agent_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - SOAR Response Agent
# -------------------------------------------------------------------------------
resource "aws_iam_role" "soar_response_agent_role" {
  name               = "${local.name_prefix}-soar-response-agent-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the SOAR Response Agent"
}

resource "aws_iam_role_policy_attachment" "soar_response_agent_basic_execution" {
  role       = aws_iam_role.soar_response_agent_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "soar_response_agent" {
  role       = aws_iam_role.soar_response_agent_role.name
  policy_arn = aws_iam_policy.soar_response_agent.arn
}

resource "aws_iam_role_policy_attachment" "soar_response_agent_appsignals" {
  role       = aws_iam_role.soar_response_agent_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}


# ================================================================
# API GATEWAY ROLES
# ================================================================

# -------------------------------------------------------------------------------
# API Gateway IAM Role - API Gateway CloudWatch Logging
# -------------------------------------------------------------------------------
data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name               = "${local.name_prefix}-api-gateway-cloudwatch-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
  description        = "Allows API Gateway to publish REST API logs to CloudWatch"
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# ================================================================
# EVENTBRIDGE ROLES
# ================================================================
# -------------------------------------------------------------------------------
# EventBridge IAM Role - EventBridge Scheduler
# -------------------------------------------------------------------------------
data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler_role" {
  name               = "${local.name_prefix}-scheduler-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
  description        = "Allows EventBridge Scheduler to invoke the detector Lambda"
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_detector" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_detector.arn
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_correlation" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_correlation.arn
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_analyzer" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_analyzer.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Executive Dashboard
# -------------------------------------------------------------------------------
resource "aws_iam_role" "executive_dashboard_role" {
  name               = "${local.name_prefix}-executive-dashboard-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Executive Dashboard Lambda"
}

resource "aws_iam_role_policy_attachment" "executive_dashboard_basic_execution" {
  role       = aws_iam_role.executive_dashboard_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "executive_dashboard" {
  role       = aws_iam_role.executive_dashboard_role.name
  policy_arn = aws_iam_policy.executive_dashboard.arn
}

resource "aws_iam_role_policy_attachment" "executive_dashboard_appsignals" {
  role       = aws_iam_role.executive_dashboard_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_executive_dashboard" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_executive_dashboard.arn
}

# -------------------------------------------------------------------------------
# Lambda IAM Role - Compliance Agent
# -------------------------------------------------------------------------------
resource "aws_iam_role" "compliance_agent_role" {
  name               = "${local.name_prefix}-compliance-agent-role-${local.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "Execution role for the Compliance Agent Lambda"
}

resource "aws_iam_role_policy_attachment" "compliance_agent_basic_execution" {
  role       = aws_iam_role.compliance_agent_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "compliance_agent" {
  role       = aws_iam_role.compliance_agent_role.name
  policy_arn = aws_iam_policy.compliance_agent.arn
}

resource "aws_iam_role_policy_attachment" "compliance_agent_appsignals" {
  role       = aws_iam_role.compliance_agent_role.name
  policy_arn = aws_iam_policy.lambda_application_signals_execution_role.arn
}
