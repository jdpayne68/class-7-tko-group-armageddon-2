# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl 

###############
# WAF Web ACL
###############
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl

resource "aws_wafv2_web_acl" "seir_waf" {
  name  = "seir_waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Remove inline rule block - it's now managed separately

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "api_waf"
    sampled_requests_enabled   = true
  }

  # Prevent Terraform from managing inline rules
  lifecycle {
    ignore_changes = [rule]
  }
}


###################
# Web ACL Rule
###################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_rule

resource "aws_wafv2_web_acl_rule" "block_attacks" {
  name        = "block_attacks" # Must match existing rule name
  priority    = 2
  web_acl_arn = aws_wafv2_web_acl.seir_waf.arn

  override_action { # tells aws to use whatever action it has set to perform with this detection pack. We won't set the acvtion block/allow
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block_attacks"
    sampled_requests_enabled   = true
  }
}


resource "aws_wafv2_web_acl_rule" "block_sql_inject" {
  name        = "block_sql_inject" # Must match existing rule name
  priority    = 1
  web_acl_arn = aws_wafv2_web_acl.seir_waf.arn

  override_action { # tells aws to use whatever action it has set to perform with this detection pack. We won't set the activtion block/allow
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesSQLiRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block_sql_inject"
    sampled_requests_enabled   = true
  }
}


resource "aws_wafv2_web_acl_rule" "block_ddos_attacks" {
  name        = "block_ddos_attacks" # Must match existing rule name
  priority    = 3
  web_acl_arn = aws_wafv2_web_acl.seir_waf.arn

  action { # tells aws to use whatever action it has set to perform with this detection pack. We won't set the acvtion block/allow
    block {}
  }

  statement {
    rate_based_statement {
      limit              = 15
      aggregate_key_type = "IP"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block_ddos_attacks"
    sampled_requests_enabled   = true
  }
}


#########################
# Web ACL Association
#########################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association 

resource "aws_wafv2_web_acl_association" "seir_assoc" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.seir_waf.arn
}



##################
# WAF Logging
##################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration

resource "aws_wafv2_web_acl_logging_configuration" "seir_logging" {

  log_destination_configs = [
    aws_cloudwatch_log_group.waf_logs.arn

  ]

  resource_arn = aws_wafv2_web_acl.seir_waf.arn

}