# ================================================================
# WAF
# ================================================================

# -------------------------------------------------------------------------------
# Regional Web ACL For API Gateways - Shield Generator
# -------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "shield_generator" {
  name        = "${local.name_prefix}-shield-generator-waf"
  description = "Regional Web ACL protecting API Gateways"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 0: SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 0

    override_action {
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
      metric_name                = "${local.name_prefix}-waf-sqli-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 1: Rate Limiting
  rule {
    name     = "RateLimitRule"
    priority = 1

    # Action C: Count mode (monitor only, does not block)
    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"

        # Advanced rate limit configuration (commented out)
        # Scope down to specific paths
        # scope_down_statement {
        #   byte_match_statement {
        #     search_string = "/login"
        #     positional_constraint = "EXACTLY"
        #     field_to_match {
        #       uri_path {}
        #     }
        #     text_transformation {
        #       priority = 0
        #       type     = "NONE"
        #     }
        #   }
        # }

        # Forwarded IP configuration for CloudFront/ALB
        # forwarded_ip_config {
        #   header_name       = "X-Forwarded-For"
        #   fallback_behavior = "MATCH"
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
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
      metric_name                = "${local.name_prefix}-waf-common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Anonymous IP List
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-anonymous-ip-list"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-api-waf"
    sampled_requests_enabled   = true
  }
}

# -------------------------------------------------------------------------------
# Attach Web ACL to Prod REST API Stage
# -------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "api_gateway_prod" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.shield_generator.arn
}

# -------------------------------------------------------------------------------
# WAF Logging Configuration for Sheild Generator Web ACL
# -------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_logging_configuration" "api_gateway" {
  resource_arn = aws_wafv2_web_acl.shield_generator.arn
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_logs.arn
  ]

  #   # Redact sensitive headers
  #   redacted_fields {
  #     single_header {
  #       name = "authorization"
  #     }
  #   }

  #   redacted_fields {
  #     single_header {
  #       name = "cookie"
  #     }
  #   }
}
