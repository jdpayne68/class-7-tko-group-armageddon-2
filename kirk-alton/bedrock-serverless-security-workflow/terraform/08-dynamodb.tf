# ================================================================
# DYNAMODB TOKEN TRACKING
# ================================================================

# ----------------------------------------------------------------
# Token Holocron Table
# ----------------------------------------------------------------
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

# ----------------------------------------------------------------
# Shield Generator Events Table
# ----------------------------------------------------------------
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
