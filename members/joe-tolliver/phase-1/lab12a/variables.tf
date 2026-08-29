variable "region" {
  type        = string
  description = "the region that will be used for the resources"
}

variable "seir_user_username" {
  type        = string
  description = "username for the user"
}

variable "seir_user_password" {
  type        = string
  description = "user's permanent password"
  sensitive   = true
}

variable "seir_email" {
  type        = string
  description = "endpoint to send notifications"
  default     = "class7.science828@passinbox.com"
}