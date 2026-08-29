# [lab12a]
# Alert Topic
#
# SOAR notifications and unused-token alerts.
#
# No subscription is created - SNS needs a confirmed endpoint:
#   aws sns subscribe --protocol email \
#     --topic-arn "$(terraform output -raw alert_topic_arn)" \
#     --notification-endpoint you@example.com

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-security-alerts"

  tags = {
    Name        = "Security Alerts"
    Environment = "Lab"
    Project     = "lab12"
  }
}

# Critical Alert Topic
#
# Targeted directly by the CRITICAL EventBridge rule, so a human
# is paged in parallel with the automated response rather than
# after it.

resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project}-critical-alerts"

  tags = {
    Name        = "Critical Alerts"
    Environment = "Lab"
    Project     = "lab12"
  }
}

# EventBridge cannot publish to a topic without an explicit resource policy.
# Omit this and the rule reports as configured while every CRITICAL page is
# silently dropped.
data "aws_iam_policy_document" "critical_alerts_publish" {
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.critical_alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.finding_critical.arn]
    }
  }
}

resource "aws_sns_topic_policy" "critical_alerts" {
  arn    = aws_sns_topic.critical_alerts.arn
  policy = data.aws_iam_policy_document.critical_alerts_publish.json
}
