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

  jedi_function_name                        = "${local.name_prefix}-jedi-python-${local.name_suffix}"
  sith_function_name                        = "${local.name_prefix}-sith-node-${local.name_suffix}"
  token_detector_function_name              = "${local.name_prefix}-unused-token-detector-${local.name_suffix}"
  waf_bedrock_analyzer_function_name        = "${local.name_prefix}-waf-bedrock-analyzer-${local.name_suffix}"
  waf_bedrock_threat_correlation_agent_name = "${local.name_prefix}-waf-bedrock-threat-correlation-agent-${local.name_suffix}"
  soar_response_agent_name                  = "${local.name_prefix}-soar-response-agent-${local.name_suffix}"
  executive_dashboard_function_name         = "${local.name_prefix}-executive-dashboard-agent-${local.name_suffix}"

  token_table_name                  = "${local.name_prefix}-token-holocron-${local.name_suffix}"
  waf_table_name                    = "${local.name_prefix}-shield-generator-events-${local.name_suffix}"
  waf_correlation_table_name        = "${local.name_prefix}-waf-correlation-findings-${local.name_suffix}"
  waf_security_incidents_table_name = "${local.name_prefix}-waf-security-incidents-${local.name_suffix}"

  # API Gateway Base URL
  api_base_url = "https://${aws_api_gateway_rest_api.chewbacca_auth_rest_api.id}.execute-api.${local.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"

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
