
# DynamoDB Tables for ARMAGEDDON SOAR Platform


resource "aws_dynamodb_table" "waf_events" {
  name         = var.waf_events_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = var.common_tags
}

resource "aws_dynamodb_table" "waf_correlation_findings" {
  name         = var.waf_correlation_findings_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "finding_id"

  attribute {
    name = "finding_id"
    type = "S"
  }

# Enable DynamoDB Streams for the waf_correlation_findings table
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

# Enable TTL for the waf_correlation_findings table
  tags = var.common_tags
}

resource "aws_dynamodb_table" "security_incidents" {
  name         = var.security_incidents_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "incident_id"

  attribute {
    name = "incident_id"
    type = "S"
  }

  tags = var.common_tags
}


###################12c################################

resource "aws_dynamodb_table" "compliance_evidence" {
  name         = var.compliance_evidence_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "evidence_id"

  attribute {
    name = "evidence_id"
    type = "S"
  }

  tags = var.common_tags
}