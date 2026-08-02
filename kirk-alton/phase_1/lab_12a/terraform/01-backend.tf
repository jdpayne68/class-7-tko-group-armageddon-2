# ================================================================
# BACKEND
# ================================================================

# ----------------------------------------------------------------
# Terraform Backend Configuration - AWS (S3)
# ----------------------------------------------------------------
# Documentation - S3 Backend
# https://developer.hashicorp.com/terraform/language/backend/s3

terraform {
  backend "s3" {
    bucket       = "theowaf-class7-kirk"
    key          = "armageddon/lab-12a/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
