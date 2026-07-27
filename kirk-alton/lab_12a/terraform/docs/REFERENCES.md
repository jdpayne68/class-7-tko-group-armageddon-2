# Official References

Only official AWS, HashiCorp, and Terraform Registry references are used below.

## AWS Service Documentation

| Service / Concept | Official AWS Documentation |
| --- | --- |
| Cognito user pools and authentication | [Cognito user pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html), [Authentication flows](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication.html), [Choice-based authentication](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flows-selection-sdk.html) |
| Cognito MFA | [Adding MFA to a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html) |
| Cognito app clients and token validity | [Application-specific settings with app clients](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html) |
| Cognito managed login and domain | [Managed login](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-managed-login.html), [Prefix domain](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-assign-domain-prefix.html) |
| Cognito access-token scopes | [Access tokens](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-the-access-token.html) |
| API Gateway REST APIs | [REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-rest-api.html), [Resources and methods](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-method-settings-method-request.html) |
| API Gateway Cognito authorizer | [Control REST API access with a Cognito user pool](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html) |
| API Gateway Lambda proxy integration | [Lambda proxy integrations](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html) |
| API Gateway deployment/stage | [Deploy REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html) |
| API Gateway CloudWatch logging | [Set up REST API logging](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html) |
| Lambda functions and runtimes | [Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html), [Supported runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html) |
| Lambda execution roles | [Lambda execution role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html) |
| API Gateway invoking Lambda | [Using Lambda with API Gateway](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html) |
| DynamoDB table/data model | [Core components](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html), [On-demand capacity](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/on-demand-capacity-mode.html), [PITR](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/PointInTimeRecovery.html) |
| IAM roles, policies, and least privilege | [IAM roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html), [Policies and permissions](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html), [Least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege) |
| EventBridge Scheduler | [What is EventBridge Scheduler?](https://docs.aws.amazon.com/scheduler/latest/UserGuide/what-is-scheduler.html), [Managing targets](https://docs.aws.amazon.com/scheduler/latest/UserGuide/managing-targets.html) |
| CloudWatch Lambda logs | [Lambda CloudWatch Logs](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs.html) |
| CloudWatch metric filters | [Creating metrics from logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringLogData.html), [Filter pattern syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html) |
| CloudWatch alarms | [Using CloudWatch alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Alarms.html) |
| SNS topics and email subscriptions | [Creating an SNS topic](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html), [Email notifications](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html), [Encryption at rest](https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html) |

## Terraform AWS Provider Resource Documentation

The configuration pins AWS provider `6.46.x`; these links point to that version.

| Terraform Type | Official Registry Documentation |
| --- | --- |
| `aws_cognito_user_pool` | [Cognito user pool](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cognito_user_pool) |
| `aws_cognito_user_pool_client` | [Cognito user pool client](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cognito_user_pool_client) |
| `aws_cognito_user_pool_domain` | [Cognito user pool domain](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cognito_user_pool_domain) |
| `aws_cognito_managed_login_branding` | [Cognito managed login branding](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cognito_managed_login_branding) |
| `aws_cognito_user` | [Cognito user](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cognito_user) |
| `aws_dynamodb_table` | [DynamoDB table](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/dynamodb_table) |
| `aws_iam_policy` | [IAM policy](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/iam_policy) |
| `aws_iam_role` | [IAM role](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/iam_role) |
| `aws_iam_role_policy_attachment` | [IAM role policy attachment](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/iam_role_policy_attachment) |
| `aws_lambda_function` | [Lambda function](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/lambda_function) |
| `aws_lambda_permission` | [Lambda permission](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/lambda_permission) |
| `aws_api_gateway_rest_api` | [API Gateway REST API](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_rest_api) |
| `aws_api_gateway_authorizer` | [API Gateway authorizer](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_authorizer) |
| `aws_api_gateway_resource` | [API Gateway resource](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_resource) |
| `aws_api_gateway_method` | [API Gateway method](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_method) |
| `aws_api_gateway_integration` | [API Gateway integration](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_integration) |
| `aws_api_gateway_deployment` | [API Gateway deployment](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_deployment) |
| `aws_api_gateway_stage` | [API Gateway stage](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_stage) |
| `aws_api_gateway_method_settings` | [API Gateway method settings](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_method_settings) |
| `aws_api_gateway_account` | [API Gateway account](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/api_gateway_account) |
| `aws_scheduler_schedule` | [EventBridge Scheduler schedule](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/scheduler_schedule) |
| `aws_cloudwatch_log_group` | [CloudWatch log group](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cloudwatch_log_group) |
| `aws_cloudwatch_log_metric_filter` | [CloudWatch Logs metric filter](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cloudwatch_log_metric_filter) |
| `aws_cloudwatch_metric_alarm` | [CloudWatch metric alarm](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/cloudwatch_metric_alarm) |
| `aws_sns_topic` | [SNS topic](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/sns_topic) |
| `aws_sns_topic_subscription` | [SNS topic subscription](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/resources/sns_topic_subscription) |

## Terraform Data Sources And Utility Providers

| Terraform Type | Official Documentation |
| --- | --- |
| `aws_iam_policy_document` | [IAM policy document data source](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/data-sources/iam_policy_document) |
| `aws_region` | [Region data source](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/data-sources/region) |
| `aws_caller_identity` | [Caller identity data source](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/data-sources/caller_identity) |
| `aws_partition` | [Partition data source](https://registry.terraform.io/providers/hashicorp/aws/6.46.0/docs/data-sources/partition) |
| `archive_file` | [Archive file data source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) |
| `random_string` | [Random string resource](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) |

## Terraform Language And Operations

| Topic | Official HashiCorp Documentation |
| --- | --- |
| Terraform configuration language | [Language overview](https://developer.hashicorp.com/terraform/language) |
| Resource dependencies | [Resource behavior and dependencies](https://developer.hashicorp.com/terraform/language/resources/behavior) |
| Sensitive data in state | [Manage sensitive data](https://developer.hashicorp.com/terraform/language/manage-sensitive-data) |
| Local backend | [Local backend](https://developer.hashicorp.com/terraform/language/backend/local) |
| S3 backend and lockfile | [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) |
| GCS backend | [GCS backend](https://developer.hashicorp.com/terraform/language/backend/gcs) |
| Provider dependency lock file | [Dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock) |
| Core workflow | [Terraform workflow](https://developer.hashicorp.com/terraform/intro/core-workflow) |
