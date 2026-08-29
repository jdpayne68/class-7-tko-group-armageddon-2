# resource "aws_cognito_user_group" "satellite_user_group" {
#   name         = "satellite_user_group"
#   user_pool_id = aws_cognito_user_pool.satellite_pool.id
#   description  = "Managed by Terraform"
#   precedence   = -10
#   // role_arn = aws_iam_role.group_role.arn
# }

# resource "aws_cognito_user_group" "satellite_admin_group" {
#   name         = "satellite_admin_group"
#   user_pool_id = aws_cognito_user_pool.satellite_pool.id
#   description  = "Managed by Terraform"
#   precedence   = 1
#   // role_arn = aws_iam_role.group_role.arn
# }
# resource "aws_cognito_user" "marvinevins" {
#   user_pool_id = aws_cognito_user_pool.satellite_pool.id
#   username     = "marvinevins"

#   attributes = {
#     email          = "marvinnevins69@gmail.com"
#     email_verified = true
#   }



#   # Let Cognito generate a temporary password and require reset on first login
#   force_alias_creation = false
#   message_action       = "SUPPRESS"
# }

# # this part of the code is for adding the user to the group, 
# #which is required for the user to have access to the resources in the group

# # for admin group 
# resource "aws_cognito_user_in_group" "marvinevins_admin_group" {
#   user_pool_id = aws_cognito_user_pool.satellite_pool.id # this is the user pool id of the user pool where the user and group are created
#   username     = aws_cognito_user.marvinevins.username
#   group_name   = aws_cognito_user_group.satellite_admin_group.name
# }


# # for user group
# resource "aws_cognito_user_in_group" "marvinevins_user_group" {
#   user_pool_id = aws_cognito_user_pool.satellite_pool.id # this is the user pool id of the user pool where the user and group are created
#   username     = aws_cognito_user.marvinevins.username
#   group_name   = aws_cognito_user_group.satellite_user_group.name
# }