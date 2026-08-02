##############################################################
# Lambda Log Group
##############################################################

resource "aws_cloudwatch_log_group" "lambda_logs" {

  name = "/aws/lambda/waf-bedrock-analyzer"

  retention_in_days = 7

  tags = {

    Name        = "Lambda Logs"
    Environment = "Prod"
    Project     = "Lambda"

  }

}

##############################################################
# WAF Log Group
##############################################################

resource "aws_cloudwatch_log_group" "waf_logs" {

  name = "aws-waf-logs-api"

  retention_in_days = 7

  tags = {

    Name        = "WAF Logs"
    Environment = "Prod"
    Project     = "Lambda"

  }

}