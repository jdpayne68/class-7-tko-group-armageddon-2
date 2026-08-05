# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server

###########################
# Cognito Resource Server
###########################

resource "aws_cognito_resource_server" "seir_deepend_server" {
  identifier = "seir-api"
  name       = "rbac_api"

  scope {
    scope_name        = "admin-scope"
    scope_description = "the level of access for the admin"
  }

  scope {
    scope_name        = "user-scope"
    scope_description = "the level of access for the user"
  }

  user_pool_id = aws_cognito_user_pool.seir_deepend.id
}


#####################
# Cognito User Pool
#####################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool

resource "aws_cognito_user_pool" "seir_deepend" {
  name = "seir-deepend"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}


##################
# Cognito Client
##################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client

resource "aws_cognito_user_pool_client" "seir_deepend_client" {
  name                                 = "seir-deepend-client"
  user_pool_id                         = aws_cognito_user_pool.seir_deepend.id
  callback_urls                        = ["https://localhost/callback"]
  logout_urls                          = ["https://localhost/logout"]
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH"]
  allowed_oauth_flows                  = ["code"] # https://datatracker.ietf.org/doc/html/rfc6749#section-1.3
  allowed_oauth_scopes = ["email", "openid", "profile", "${aws_cognito_resource_server.seir_deepend_server.identifier}/admin-scope",
  "${aws_cognito_resource_server.seir_deepend_server.identifier}/user-scope"]
  supported_identity_providers = ["COGNITO"]
  access_token_validity        = 1

  refresh_token_rotation {
    feature                    = "ENABLED"
    retry_grace_period_seconds = 15
  }

  token_validity_units {
    access_token = "days"
  }
}


################
# Cognito User
################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user

resource "aws_cognito_user" "seir_username" {
  user_pool_id   = aws_cognito_user_pool.seir_deepend.id
  username       = var.seir_user_username
  password       = var.seir_user_password
  message_action = "SUPPRESS"

  attributes = {
    email          = var.seir_email
    email_verified = true
  }
}


################
#Authorizer
################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer

resource "aws_api_gateway_authorizer" "seir_pass" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.seir_api.id
  provider_arns = [aws_cognito_user_pool.seir_deepend.arn]
}