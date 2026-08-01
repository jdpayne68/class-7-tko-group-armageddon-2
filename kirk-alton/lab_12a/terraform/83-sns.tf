# ================================================================
# SNS ALERTS AND SUBSCRIPTIONS
# ================================================================

# -------------------------------------------------------------------------------
# SNS Alerts and Subscriptions
# -------------------------------------------------------------------------------

resource "aws_sns_topic" "token_alerts" {
  name              = "${local.name_prefix}-auth-alerts-${local.name_suffix}"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "token_alert_emails" {
  count = length(var.alert_emails)

  topic_arn = aws_sns_topic.token_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

resource "aws_sns_topic" "waf_security_incidents_alert" {
  name              = "waf-security-incidents-alert"
  kms_master_key_id = "alias/aws/sns"

}

resource "aws_sns_topic_subscription" "waf_security_incidents_alert_emails" {
  count = length(var.alert_emails)

  topic_arn = aws_sns_topic.waf_security_incidents_alert.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}
