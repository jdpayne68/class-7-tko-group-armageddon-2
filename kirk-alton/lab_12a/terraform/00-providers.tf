# ================================================================
# TERRAFORM PROVIDERS
# ================================================================

# ----------------------------------------------------------------
# Required Terraform And Providers
# ----------------------------------------------------------------
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46.0"
      # Documentation - AWS Provider
      # https://registry.terraform.io/providers/hashicorp/aws/latest
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
      # Documentation - Archive Provider
      # https://registry.terraform.io/providers/hashicorp/archive/latest
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
      # Documentation - Random Provider
      # https://registry.terraform.io/providers/hashicorp/random/latest
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.common_tags
  }
}

provider "archive" {
  # no config needed
}

provider "random" {
  # no config needed
}
