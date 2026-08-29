# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group

#################
# WAF Log Group
#################

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-event"
  retention_in_days = 7
  tags = {
    Name        = "WAF_Logs"
    Environment = "Seir"
    Project     = "Lab12c"

  }
}