# ================================================================
# VARIABLES
# ================================================================

# ----------------------------------------------------------------
# AWS Provider Inputs
# ----------------------------------------------------------------
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region used by the Cognito Auth Flow REST lab."
}

variable "aws_profile" {
  type        = string
  default     = "default"
  description = "Local AWS CLI profile used by the AWS provider."
}

# ----------------------------------------------------------------
# Core Application Inputs
# ----------------------------------------------------------------
variable "app" {
  type        = string
  description = "Application name (short)."
  default     = "chewbacca-auth-rest" # Update with new application name
}

variable "env" {
  type        = string
  default     = "dev"
  description = "Input environment name (dev, test, prod)."

  validation {
    condition     = contains(["dev", "test", "prod"], lower(var.env))
    error_message = "The env value must be dev, test, or prod."
  }
}

# ----------------------------------------------------------------
# Cognito Test User Inputs
# ----------------------------------------------------------------
variable "test_username" {
  type        = string
  default     = "chewbacca"
  description = "Username for the lab Cognito user."
}

variable "test_user_email" {
  type        = string
  default     = "chewbacca@example.com"
  description = "Email address for the lab Cognito user."
}

variable "test_user_phone_number" {
  type        = string
  default     = "+18328321734"
  description = "E.164 phone number for the lab Cognito user."
}

variable "test_user_birthdate" {
  type        = string
  default     = "1977-05-25"
  description = "Birthdate required by the user pool schema in YYYY-MM-DD form."
}

variable "test_user_password" {
  type        = string
  sensitive   = true
  description = "Permanent password for the lab Cognito user. Store it outside version control."

  validation {
    condition = (
      length(var.test_user_password) >= 12 &&
      can(regex("[A-Z]", var.test_user_password)) &&
      can(regex("[a-z]", var.test_user_password)) &&
      can(regex("[0-9]", var.test_user_password)) &&
      can(regex("[^A-Za-z0-9]", var.test_user_password))
    )
    error_message = "The test user password must be at least 12 characters and contain uppercase, lowercase, number, and symbol characters."
  }
}

variable "callback_url" {
  type        = string
  default     = "https://example.com/callback"
  description = "OAuth callback URL used by Cognito managed login. Replace before browser testing."
}

# ----------------------------------------------------------------
# Operations Inputs
# ----------------------------------------------------------------
variable "log_retention_days" {
  type        = number
  default     = 14
  description = "Number of days that Lambda and API Gateway logs are retained."
}

variable "token_unused_minutes" {
  type        = number
  default     = 10
  description = "Age in minutes after which an unused token record produces an alert."
}

variable "token_scan_schedule" {
  type        = string
  default     = "rate(5 minutes)"
  description = "EventBridge Scheduler expression for the unused-token detector."
}

variable "alert_email" {
  type        = string
  default     = null
  nullable    = true
  description = "Optional email address subscribed to unused-token SNS alerts."
}
