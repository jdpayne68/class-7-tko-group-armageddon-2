# ================================================================
# BACKEND
# ================================================================
# Terraform uses the local backend when no backend block is enabled.
# Keep local state for the lab, or uncomment and configure one remote backend.

# ----------------------------------------------------------------
# Terraform Backend Configuration - Google (GCS)
# ----------------------------------------------------------------
# Documentation - GCS Backend
# https://developer.hashicorp.com/terraform/language/backend/gcs

# terraform {
#   backend "gcs" {
#     bucket = "REPLACE_WITH_YOUR_STATE_BUCKET"
#     prefix = "chewbacca-auth-rest-lab/dev"
#   }
# }

# ----------------------------------------------------------------
# Terraform Backend Configuration - AWS (S3)
# ----------------------------------------------------------------
# Documentation - S3 Backend
# https://developer.hashicorp.com/terraform/language/backend/s3

# terraform {
#   backend "s3" {
#     bucket       = "REPLACE_WITH_YOUR_STATE_BUCKET"
#     key          = "chewbacca-auth-rest-lab/dev/terraform.tfstate"
#     region       = "us-east-1"
#     use_lockfile = true
#     encrypt      = true
#   }
# }
