# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

########################
# DynamoDB Table 1
########################

resource "aws_dynamodb_table" "waf_events" {
  name         = "waf-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "waf-events"
    Environment = "Seir"
    Project     = "Lab12c"
  }
}


########################
# DynamoDB Table 2
########################

resource "aws_dynamodb_table" "waf_correlation_findings" {
  name         = "waf-correlation-findings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "finding_id"

  attribute {

    name = "finding_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "waf-correlation-findings"
    Environment = "Seir"
    Project     = "Lab12c"
  }
}


########################
# DynamoDB Table 3
########################

resource "aws_dynamodb_table" "security_incidents" {
  name         = "security-incidents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incident_id"

  attribute {

    name = "incident_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "security-incidents"
    Environment = "Seir"
    Project     = "Lab12c"
  }
}


########################
# DynamoDB Table 4
########################

resource "aws_dynamodb_table" "compliance_evidence" {
  name         = "compliance-evidence"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "evidence_id"

  attribute {

    name = "evidence_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "compliance-evidence"
    Environment = "Seir"
    Project     = "Lab12c"
  }
}


########################
# DynamoDB Table 5
########################

# resource "aws_dynamodb_table" "compliance_findings" {
#   name         = "compliance-findings"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "finding_id"

#   attribute {

#     name = "finding_id"
#     type = "S"
#   }

#   point_in_time_recovery {
#     enabled = true
#   }

#   server_side_encryption {
#     enabled = true
#   }

#   tags = {
#     Name        = "compliance-findings"
#     Environment = "Seir"
#     Project     = "Lab12c"
#   }
# }