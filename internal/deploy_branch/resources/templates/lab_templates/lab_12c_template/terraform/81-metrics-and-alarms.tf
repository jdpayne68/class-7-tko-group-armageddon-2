# ================================================================
# CLOUDWATCH METRICS AND ALARMS
# ================================================================


# ================================================================
# CLOUDWATCH METRICS
# ================================================================

# -------------------------------------------------------------------------------
# CloudWatch Metric - Unused Token Detector
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_log_metric_filter" "unused_token" {
  name           = "${local.name_prefix}-unused-token-filter-${local.name_suffix}"
  pattern        = "\"ALERT: Token unused\""
  log_group_name = aws_cloudwatch_log_group.unused_token_detector.name

  metric_transformation {
    name          = "UnusedTokenAlert"
    namespace     = "${local.name_prefix}/TokenDetector-${local.name_suffix}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# ================================================================
# CLOUDWATCH ALARMS
# ================================================================

# -------------------------------------------------------------------------------
# CloudWatch Alarm - Unused Token Alert
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "unused_token" {
  alarm_name          = "${local.name_prefix}-unused-token-alarm-${local.name_suffix}"
  alarm_description   = "Detector found at least one token record that was never used"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1

  metric_name = "UnusedTokenAlert"
  namespace   = "${local.name_prefix}/TokenDetector-${local.name_suffix}"
  period      = 60
  statistic   = "Sum"

  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.token_alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.unused_token]
}
