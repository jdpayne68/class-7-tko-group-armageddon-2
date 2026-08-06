variable "aws_region" {
  description = "AWS Region used for the lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for named AWS resources."
  type        = string
  default     = "armageddon-2"
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model or inference profile ID."
  type        = string
}

variable "report_bucket_name" {
  description = "Globally unique S3 bucket name for executive reports."
  type        = string
}

variable "notification_email" {
  description = "Email address used for the optional SNS subscription."
  type        = string
  default     = ""
}
