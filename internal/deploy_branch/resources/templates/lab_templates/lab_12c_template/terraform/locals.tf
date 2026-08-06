# ================================================================
# LOCALS
# ================================================================

locals {
  # -------------------------------------------------------------------
  # Core Account, Environment, And Naming Locals
  # -------------------------------------------------------------------
  # TODO: Implement locals

  # AWS Environment
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  # Environment setup
  env = lower(var.env)
  app = lower(var.app)

  # Naming helpers
  name_prefix   = "${local.app}-${local.env}"
  name_suffix   = random_string.suffix.result
  bucket_suffix = random_id.bucket_suffix.hex

  # Tags
  common_tags = {
    Application = local.app
    Environment = local.env
    ManagedBy   = "Terraform"
  }
}
