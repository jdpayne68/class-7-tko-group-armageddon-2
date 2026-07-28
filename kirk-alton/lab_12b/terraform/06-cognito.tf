# ================================================================
# AMAZON COGNITO
# ================================================================

# ----------------------------------------------------------------
# Cognito User Pool
# ----------------------------------------------------------------
resource "aws_cognito_user_pool" "chewbacca_auth_rest" {
  name                     = "${local.name_prefix}-users-${local.name_suffix}"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "ON"
  user_pool_tier           = "ESSENTIALS"

  username_configuration {
    case_sensitive = false
  }

  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD"]
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "name"
    required            = true

    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "birthdate"
    required            = true

    string_attribute_constraints {
      min_length = 10
      max_length = 10
    }
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "phone_number"
    required            = true

    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }
}

# ----------------------------------------------------------------
# Public App Client - Token Helper And Managed Login
# ----------------------------------------------------------------
resource "aws_cognito_user_pool_client" "public" {
  name         = "${local.name_prefix}-public-client-${local.name_suffix}"
  user_pool_id = aws_cognito_user_pool.chewbacca_auth_rest.id

  generate_secret                      = false
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  auth_session_validity                = 5
  access_token_validity                = 15
  id_token_validity                    = 15
  refresh_token_validity               = 1
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", local.required_auth_scope]
  callback_urls                        = [var.callback_url]
  supported_identity_providers         = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# ----------------------------------------------------------------
# Secret-Bearing App Client - SECRET_HASH Practice
# ----------------------------------------------------------------
resource "aws_cognito_user_pool_client" "cli" {
  name         = "${local.name_prefix}-cli-client-${local.name_suffix}"
  user_pool_id = aws_cognito_user_pool.chewbacca_auth_rest.id

  generate_secret                      = true
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  auth_session_validity                = 5
  access_token_validity                = 15
  id_token_validity                    = 15
  refresh_token_validity               = 1
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", local.required_auth_scope]
  callback_urls                        = [var.callback_url]
  supported_identity_providers         = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# ----------------------------------------------------------------
# Cognito Prefix Domain And Managed Login Branding
# ----------------------------------------------------------------
resource "aws_cognito_user_pool_domain" "chewbacca_auth_rest" {
  domain                = "${local.name_prefix}-${local.name_suffix}"
  user_pool_id          = aws_cognito_user_pool.chewbacca_auth_rest.id
  managed_login_version = 2
}

resource "aws_cognito_managed_login_branding" "public" {
  client_id                   = aws_cognito_user_pool_client.public.id
  user_pool_id                = aws_cognito_user_pool.chewbacca_auth_rest.id
  use_cognito_provided_values = true

  depends_on = [aws_cognito_user_pool_domain.chewbacca_auth_rest]
}

resource "aws_cognito_managed_login_branding" "cli" {
  client_id                   = aws_cognito_user_pool_client.cli.id
  user_pool_id                = aws_cognito_user_pool.chewbacca_auth_rest.id
  use_cognito_provided_values = true

  depends_on = [aws_cognito_user_pool_domain.chewbacca_auth_rest]
}

# ----------------------------------------------------------------
# Chewbacca Lab User
# ----------------------------------------------------------------
resource "aws_cognito_user" "chewbacca" {
  user_pool_id   = aws_cognito_user_pool.chewbacca_auth_rest.id
  username       = var.test_username
  password       = var.test_user_password
  enabled        = true
  message_action = "SUPPRESS"

  attributes = {
    birthdate             = var.test_user_birthdate
    email                 = var.test_user_email
    email_verified        = true
    name                  = "Chewbacca Raaawr"
    phone_number          = var.test_user_phone_number
    phone_number_verified = true
  }
}
