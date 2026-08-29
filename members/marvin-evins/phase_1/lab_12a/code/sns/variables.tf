variable "alerts_topic_name" {
  type        = string
  description = "Name of the SNS topic for security alerts"
}

variable "alerts_email" {
  type        = string
  description = "Email address subscribed to SNS alerts"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags applied to all SNS resources"
}
