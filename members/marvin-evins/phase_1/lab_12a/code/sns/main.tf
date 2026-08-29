
# SNS Topic for ARMAGEDDON Security Alerts


resource "aws_sns_topic" "alerts_topic" {
  name = var.alerts_topic_name
  tags = var.common_tags
}

# Email subscription for alerts
resource "aws_sns_topic_subscription" "alerts_email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}
