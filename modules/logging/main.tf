# creates:

    # CloudWatch Log Groups for each Lambda

    # Optional WAF Log Group (if you later enable WAF logging)

    # Proper retention policies

    # Tags

    # Outputs


# CloudWatch Log Groups for ARMAGEDDON Lambdas


resource "aws_cloudwatch_log_group" "waf_analyzer_logs" {
  name              = "/aws/lambda/${var.prefix}-waf-analyzer"
  retention_in_days = 30
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "threat_correlation_logs" {
  name              = "/aws/lambda/${var.prefix}-threat-correlation"
  retention_in_days = 30
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "soar_response_logs" {
  name              = "/aws/lambda/${var.prefix}-soar-response"
  retention_in_days = 30
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "executive_dashboard_logs" {
  name              = "/aws/lambda/${var.prefix}-executive-dashboard"
  retention_in_days = 30
  tags              = var.common_tags
}


resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/${var.prefix}-waf"
  retention_in_days = 30
  tags              = var.common_tags
}


