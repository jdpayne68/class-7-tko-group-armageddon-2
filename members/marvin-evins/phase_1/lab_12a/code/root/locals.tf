locals {
  # A consistent prefix for naming resources
  prefix = "${var.app_name}-${var.environment}"

  # Standard tags applied to all resources
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
  }

  # DynamoDB table names (computed once, reused everywhere)
  waf_events_table_name               = "${local.prefix}-${var.waf_events_table_name}"
  waf_correlation_findings_table_name = "${local.prefix}-${var.waf_correlation_findings_table_name}"
  security_incidents_table_name       = "${local.prefix}-${var.security_incidents_table_name}"

  # S3 bucket name for executive reports
  reports_bucket_name = "${local.prefix}-${var.reports_bucket_name}"

  # SNS topic name
  alerts_topic_name = "${local.prefix}-alerts-topic"
}
