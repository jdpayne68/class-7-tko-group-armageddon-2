# ================================================================
# HELPER RESOURCES
# ================================================================

# -------------------------------------------------------------------------------
# NAMING HELPERS
# -------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 3
  special = false
  upper   = false
}

# Random Hex ID for bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
