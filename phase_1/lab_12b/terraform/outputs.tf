# ================================================================
# OUTPUTS
# ================================================================

# -------------------------------------------------------------------------------
# API GATEWAY OUTPUTS
# -------------------------------------------------------------------------------
output "api_gateway" {
  description = "API Gateway endpoints and URLs."
  value = {
    base_url    = local.api_base_url
    jedi_url    = "${local.api_base_url}/jedi"
    sith_url    = "${local.api_base_url}/sith"
    analyze_url = "${local.api_base_url}/analyze"
  }
}

# -------------------------------------------------------------------------------
# COGNITO OUTPUTS
# -------------------------------------------------------------------------------
output "cognito" {
  description = "Cognito user pool and client configuration."
  value = {
    user_pool_id      = aws_cognito_user_pool.chewbacca_auth_rest.id
    user_pool_arn     = aws_cognito_user_pool.chewbacca_auth_rest.arn
    cognito_issuer    = "https://cognito-idp.${local.region}.amazonaws.com/${aws_cognito_user_pool.chewbacca_auth_rest.id}"
    public_client_id  = aws_cognito_user_pool_client.public.id
    cli_client_id     = aws_cognito_user_pool_client.cli.id
    cli_client_secret = aws_cognito_user_pool_client.cli.client_secret
    managed_login_url = "https://${aws_cognito_user_pool_domain.chewbacca_auth_rest.domain}.auth.${local.region}.amazoncognito.com/oauth2/authorize?response_type=code&client_id=${aws_cognito_user_pool_client.public.id}&redirect_uri=${urlencode(var.callback_url)}&scope=openid+email+profile"
  }
  sensitive = true
}

# -------------------------------------------------------------------------------
# LAMBDA FUNCTION NAMES
# -------------------------------------------------------------------------------
output "lambda_function_names" {
  description = "All Lambda function names."
  value = {
    jedi_python           = aws_lambda_function.jedi_python.function_name
    sith_node             = aws_lambda_function.sith_node.function_name
    unused_token_detector = aws_lambda_function.unused_token_detector.function_name
    waf_bedrock_analyzer  = aws_lambda_function.waf_bedrock_analyzer.function_name
    threat_correlation    = aws_lambda_function.waf_threat_correlation_agent.function_name
    soar_response         = aws_lambda_function.soar_response_agent.function_name
    executive_dashboard   = aws_lambda_function.executive_dashboard.function_name
  }
}

# -------------------------------------------------------------------------------
# DYNAMODB TABLE NAMES
# -------------------------------------------------------------------------------
output "dynamodb_table_names" {
  description = "All DynamoDB table names."
  value = {
    token_holocron         = aws_dynamodb_table.token_holocron.name
    waf_events             = aws_dynamodb_table.shield_generator_events.name
    waf_correlation        = aws_dynamodb_table.waf_correlation_findings.name
    waf_security_incidents = aws_dynamodb_table.waf_security_incidents.name
  }
}

# -------------------------------------------------------------------------------
# S3 REPORT BUCKETS
# -------------------------------------------------------------------------------
output "report_bucket_names" {
  description = "S3 buckets used for generated security reports."
  value = {
    executive_reports = aws_s3_bucket.executive_report_bucket.id
  }
}

# -------------------------------------------------------------------------------
# EVENTBRIDGE OUTPUTS
# -------------------------------------------------------------------------------
output "eventbridge" {
  description = "EventBridge rules and schedulers."
  value = {
    rules = {
      medium_high = aws_cloudwatch_event_rule.soar_response_medium_high.name
      critical    = aws_cloudwatch_event_rule.soar_response_critical.name
    }
    rule_arns = {
      medium_high = aws_cloudwatch_event_rule.soar_response_medium_high.arn
      critical    = aws_cloudwatch_event_rule.soar_response_critical.arn
    }
    schedulers = {
      waf_analyzer       = aws_scheduler_schedule.waf_bedrock_analyzer.name
      threat_correlation = aws_scheduler_schedule.threat_correlation.name
      unused_token       = aws_scheduler_schedule.unused_token_check.name
    }
    scheduler_arns = {
      waf_analyzer       = aws_scheduler_schedule.waf_bedrock_analyzer.arn
      threat_correlation = aws_scheduler_schedule.threat_correlation.arn
      unused_token       = aws_scheduler_schedule.unused_token_check.arn
    }
  }
}

# -------------------------------------------------------------------------------
# SNS TOPICS
# -------------------------------------------------------------------------------
output "sns_topic_arns" {
  description = "SNS topic ARNs for alerts."
  value = {
    token_alerts           = aws_sns_topic.token_alerts.arn
    waf_security_incidents = aws_sns_topic.waf_security_incidents_alert.arn
  }
}

# -------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUPS
# -------------------------------------------------------------------------------
output "cloudwatch_log_groups" {
  description = "All CloudWatch log groups."
  value = {
    lambda = {
      jedi_python           = aws_cloudwatch_log_group.jedi_python.name
      sith_node             = aws_cloudwatch_log_group.sith_node.name
      unused_token_detector = aws_cloudwatch_log_group.unused_token_detector.name
      waf_bedrock_analyzer  = aws_cloudwatch_log_group.waf_bedrock_analyzer.name
      soar_response         = aws_cloudwatch_log_group.soar_response_agent.name
      executive_dashboard   = aws_cloudwatch_log_group.executive_dashboard.name
    }
    waf_logs           = aws_cloudwatch_log_group.waf_logs.name
    api_gateway_access = aws_cloudwatch_log_group.api_gateway_access.name
  }
}

# -------------------------------------------------------------------------------
# TESTING COMMANDS
# -------------------------------------------------------------------------------
output "test_commands" {
  description = "Useful commands for testing and debugging."
  value = {
    send_test_xss_traffic = "curl -X POST '${local.api_base_url}/analyze' -H 'Content-Type: application/json' -d '{\"name\":\"<script>alert(1)</script>\"}'"
    check_waf_logs        = "aws logs filter-log-events --log-group-name ${aws_cloudwatch_log_group.waf_logs.name} --start-time $(date -v-5M +%s%3N) --region ${local.region} --limit 25"
  }
}
