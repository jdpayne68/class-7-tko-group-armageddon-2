# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription

##########################
# SNS SOAR Notifications
##########################

resource "aws_sns_topic" "soar_notifications" {
  name = "soar-notifications"
}

resource "aws_sns_topic_subscription" "soar_sub" {
  topic_arn = aws_sns_topic.soar_notifications.arn
  protocol  = "email"
  endpoint  = var.seir_email
}


###################################
# SNS Critical SOAR Notifications
###################################

resource "aws_sns_topic" "critical_alerts" {
  name = "critical-alert"
}

resource "aws_sns_topic_subscription" "critical_alerts_sub" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.seir_email
}


#######################
# SNS Critical Policy
#######################

resource "aws_sns_topic_policy" "critical_alerts_policy" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.critical_alerts.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.waf_finding_critical.arn
        }
      }
    }]
  })
}