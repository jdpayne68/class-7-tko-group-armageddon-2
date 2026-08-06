# ================================================================
# DYNAMODB TOKEN TRACKING
# ================================================================

# -------------------------------------------------------------------------------
# Token Holocron Table
# -------------------------------------------------------------------------------
resource "aws_dynamodb_table" "token_holocron" {
  name         = local.token_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "token_id"

  attribute {
    name = "token_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# -------------------------------------------------------------------------------
# Shield Generator Events Table
# -------------------------------------------------------------------------------
resource "aws_dynamodb_table" "shield_generator_events" {
  name         = local.waf_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# -------------------------------------------------------------------------------
# Correlation Findings Table
# -------------------------------------------------------------------------------
resource "aws_dynamodb_table" "waf_correlation_findings" {
  name         = local.waf_correlation_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "finding_id"

  attribute {
    name = "finding_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# -------------------------------------------------------------------------------
# Security Incidents Table
# -------------------------------------------------------------------------------
resource "aws_dynamodb_table" "waf_security_incidents" {
  name         = local.waf_security_incidents_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incident_id"

  attribute {
    name = "incident_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# -------------------------------------------------------------------------------
# Compliance Evidence Table
# -------------------------------------------------------------------------------
resource "aws_dynamodb_table" "compliance_evidence" {
  name         = local.compliance_evidence_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "evidence_id"

  attribute {
    name = "evidence_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}
