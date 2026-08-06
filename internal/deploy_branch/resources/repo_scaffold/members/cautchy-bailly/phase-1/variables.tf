# [lab12]
# Variables

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "ace"
}

# Token telemetry (lessonf)
# A token is "abandoned" once it is this old and still unused. The detector
# runs every 5 minutes, so this must exceed the schedule interval or a token
# gets flagged before its owner has had a fair chance to use it.

variable "unused_after_minutes" {
  type    = number
  default = 10
}

# Bedrock (lessong / lessonh)
# Model access is enabled in the console, not by Terraform. If this model is
# not enabled in var.aws_region, invoke_model returns AccessDeniedException.

variable "bedrock_model_id" {
  type    = string
  default = "anthropic.claude-3-haiku-20240307-v1:0"
}

# WAF log analysis (lessonh)

variable "waf_lookback_minutes" {
  type    = number
  default = 10
}

# lab12 - analyzer

variable "max_log_events" {
  type    = number
  default = 25
}

# lab12 - correlation agent

variable "correlation_window_minutes" {
  type    = number
  default = 60
}

# Below this many events in the window, there is no pattern to correlate and
# the agent exits without creating a finding.
variable "minimum_event_count" {
  type    = number
  default = 3
}

variable "max_correlation_events" {
  type    = number
  default = 500
}

variable "admin_uri_keywords" {
  type    = string
  default = "admin,login,signin,auth,token,cognito"
}

# lab12a - finding event envelope
# These three must agree between the correlation agent's publish call and the
# EventBridge rule patterns. A mismatch means findings are stored, the event
# fires, and nothing matches it - a silent break with no error anywhere.

variable "finding_event_source" {
  type    = string
  default = "seir.waf.correlation"
}

variable "finding_event_detail_type" {
  type    = string
  default = "WAF Threat Finding Created"
}

# lab12 - Bedrock toggle
# false keeps every deterministic stage running - scoring, findings,
# playbooks, incidents - and drops only the narrative layer.

variable "enable_bedrock" {
  type    = bool
  default = true
}

# lab12b - executive report

variable "report_prefix" {
  type    = string
  default = "executive-reports"
}

variable "report_period_hours" {
  type    = number
  default = 24
}

variable "max_items_per_table" {
  type    = number
  default = 5000
}

variable "organization_name" {
  type    = string
  default = "SEIR Cloud Security"
}

variable "report_title" {
  type    = string
  default = "Executive Security Report"
}

variable "report_schedule_expression" {
  type    = string
  default = "cron(0 7 * * ? *)"
}
