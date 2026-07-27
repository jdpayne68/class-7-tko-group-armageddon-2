# ================================================================
# LOCALS
# ================================================================

locals {
  # -------------------------------------------------------------------
  # Core Account, Environment, And Naming Locals
  # -------------------------------------------------------------------

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

  jedi_function_name                        = "${local.name_prefix}-jedi-python"
  sith_function_name                        = "${local.name_prefix}-sith-node"
  token_detector_function_name              = "${local.name_prefix}-unused-token-detector"
  waf_bedrock_analyzer_function_name        = "${local.name_prefix}-waf-bedrock-analyzer"
  waf_bedrock_threat_correlation_agent_name = "${local.name_prefix}-waf-bedrock-threat-correlation-agent"

  token_table_name           = "${local.name_prefix}-token-holocron"
  waf_table_name             = "${local.name_prefix}-shield-generator-events"
  waf_correlation_table_name = "${local.name_prefix}-waf-correlation-findings"


  # Cognito
  required_auth_scope = "aws.cognito.signin.user.admin"

  # Bedrock Configuration
  bedrock_model_id  = "anthropic.claude-3-haiku-20240307-v1:0"
  bedrock_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${local.bedrock_model_id}"

  # Tags
  common_tags = {
    Application = local.app
    Environment = local.env
    ManagedBy   = "Terraform"
    Lab         = "CognitoAuthFlowREST"
  }
}
