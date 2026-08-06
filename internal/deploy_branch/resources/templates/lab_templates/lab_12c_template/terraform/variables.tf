# ================================================================
# VARIABLES
# ================================================================

# -------------------------------------------------------------------------------
# Core Variables
# -------------------------------------------------------------------------------
# TODO: Add lab variables as resources are implemented

variable "env" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "app" {
  description = "Application name used for shared naming helpers."
  type        = string
  default     = "bedrock-serverless"
}
