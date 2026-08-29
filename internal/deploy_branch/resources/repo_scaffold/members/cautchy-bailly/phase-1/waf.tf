# [lab12]
# The sensor. Everything hostile dies here at the edge, before the
# authorizer or any Lambda sees it. Four rule groups in priority order,
# then a default allow for traffic that behaves.

resource "aws_wafv2_web_acl" "waf" {
  name  = "${var.project}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Common set - the generalist. Broad strokes.
  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRules"
      sampled_requests_enabled   = true
    }
  }

  # SQLi specialist. The common set waved a hand-crafted "' OR 1=1--"
  # straight through once - this is why it won't again.
  rule {
    name     = "AWSManagedSQLi"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRules"
      sampled_requests_enabled   = true
    }
  }

  # Known-bad inputs - patterns tied to live CVEs. Cheap, high value.
  rule {
    name     = "AWSManagedKnownBadInputs"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # Rate limit - 100 req / 5 min / IP. Blunt, but it stops a flood.
  rule {
    name     = "rate-limit"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 100
        evaluation_window_sec = 300
        aggregate_key_type    = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf"
    sampled_requests_enabled   = true
  }
}

# Bolt the WAF to the stage - this is what makes it run BEFORE the
# authorizer. Blocked never reaches Cognito; unauthenticated never
# reaches Lambda.
resource "aws_wafv2_web_acl_association" "api_assoc" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}

# WAF logging - two quiet traps the reference walks into:
#   1. the destination ARN must drop the trailing ":*" that
#      aws_cloudwatch_log_group.arn returns, or it's rejected.
#   2. WAF delivers via delivery.logs.amazonaws.com, which needs a
#      resource policy on the log group (see cloudwatch.tf). Skip it and
#      logging applies clean, delivers nothing, and the analyzer starves.

resource "aws_wafv2_web_acl_logging_configuration" "logging" {
  log_destination_configs = [trimsuffix(aws_cloudwatch_log_group.waf_logs.arn, ":*")]
  resource_arn            = aws_wafv2_web_acl.waf.arn

  # Redact auth headers. WAF logs the whole request, so without this
  # every token students send sits in CloudWatch in plaintext - a
  # credential store nobody asked for.
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }

  depends_on = [aws_cloudwatch_log_resource_policy.waf_log_delivery]
}
