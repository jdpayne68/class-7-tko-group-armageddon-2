# Cognito Auth Flow REST Terraform Reference

This directory is a complete reference implementation for the Cognito-protected REST lab and its token-detector add-on. It is intentionally written in the same direct, file-oriented style as the original `terraform` draft: descriptive resource names, section-banner comments, explicit resources, simple locals, and no modules or large `for_each` abstractions.

This is a study companion. It does not replace the original implementation, and it does not modify the neighboring `terraform` directory.

## What This Deploys

- Cognito user pool with required software-token MFA
- public app client for the token helper and a secret-bearing app client for `SECRET_HASH` practice
- Cognito prefix domain and default managed-login branding
- Chewbacca lab user with a permanent password
- Python Jedi, Node.js Sith, and Python unused-token detector Lambda functions
- DynamoDB token-tracking table
- API Gateway REST API with `GET /jedi` and `GET /sith`
- Cognito User Pool authorizer with the `aws.cognito.signin.user.admin` scope
- `prod` REST API deployment and stage
- Lambda and API Gateway CloudWatch log groups
- EventBridge Scheduler invocation of the unused-token detector
- CloudWatch Logs metric filter, CloudWatch alarm, and encrypted SNS topic
- least-privilege IAM roles and policies for each service relationship

## Architecture

```text
                         authentication
CLI / managed login --------------------------> Cognito User Pool
       |                                         |  public + secret clients
       | access token                            |  software-token MFA
       v                                         |
API Gateway REST API <---------------------------+
  Cognito authorizer checks signature, claims, and required scope
       |
       +-- GET /prod/jedi --> Jedi Python Lambda --+
       |                                             |
       +-- GET /prod/sith --> Sith Node Lambda ------+--> DynamoDB token table
                                                             ^
local get_token.py creates unused token records --------------+
                                                             |
EventBridge Scheduler --> Detector Lambda -- scans -----------+
                              |
                              v
                    CloudWatch Logs metric filter
                              |
                              v
                      CloudWatch alarm --> SNS
```

There is no VPC in this architecture. Cognito, API Gateway, Lambda, DynamoDB, EventBridge Scheduler, CloudWatch, and SNS use AWS-managed service networking. Adding a VPC to the Lambdas would add NAT or VPC endpoint requirements without helping this lab.

## Directory Map

| Path | Purpose |
| --- | --- |
| `00-providers.tf` | Terraform version, provider versions, AWS profile/Region, and default tags |
| `01-backend.tf` | local-state default plus commented GCS and S3 remote-state examples |
| `variables.tf` | user-controlled deployment inputs |
| `locals.tf` | normalized environment, names, tags, and the required Cognito scope |
| `naming-helpers.tf` | unique suffix for the globally unique Cognito prefix domain |
| `aws-helpers.tf` | current Region, account, and partition lookups |
| `cognito.tf` | user pool, clients, domain, branding, and test user |
| `dynamodb.tf` | token-tracking table |
| `iam-policies.tf` | least-privilege customer-managed policies |
| `lambda-roles.tf` | Lambda, Scheduler, and API Gateway roles and attachments |
| `lambda.tf` | Lambda packages and functions |
| `api-gateway.tf` | protected REST routes, integrations, deployment, stage, and logging account settings |
| `eventbridge.tf` | scheduled detector invocation |
| `monitoring.tf` | log groups, log-derived metric, alarm, and SNS notification path |
| `outputs.tf` | IDs, URLs, client values, and detector resources used for testing |
| `.tflint.hcl` | Terraform/AWS lint configuration and documented current-runtime exception |
| `lambda-code/` | the three Lambda handlers |
| `scripts/get_token.py` | client-side helper that authenticates and writes a token record |
| `docs/` | style analysis, file/resource notes, troubleshooting, and official references |

See [FILE-STUDY-GUIDE.md](docs/FILE-STUDY-GUIDE.md), [RESOURCE-STUDY-GUIDE.md](docs/RESOURCE-STUDY-GUIDE.md), and [REFERENCES.md](docs/REFERENCES.md) for the detailed study material.

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create the documented services and IAM resources
- Python 3 with `boto3` for `scripts/get_token.py`
- an authenticator app for TOTP enrollment
- a real OAuth callback URL if you want to complete managed login in a browser

API Gateway's `aws_api_gateway_account` setting is account-and-Region scoped. If the account already manages `cloudwatch_role_arn` elsewhere, import that setting or coordinate ownership before applying this reference.

## Deploy

```bash
cd /Users/kirk/devsecops/cognito-cli-auth-flow/REST/labs/cognito-auth-flow-REST/lab-docs/terraform-temp
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`. At minimum, replace `test_user_password`. Replace `callback_url` before browser-based managed-login testing. Do not commit `terraform.tfvars`.

```bash
terraform fmt -check -recursive
terraform init
terraform validate
tflint --init
tflint
terraform plan -out=tfplan
terraform apply tfplan
```

The local backend is the default so the directory works without a pre-existing state bucket. For team or production use, configure one remote backend in `01-backend.tf`, then run `terraform init -reconfigure`.

## Complete TOTP Enrollment

Terraform enables required software-token MFA, but a TOTP shared secret is user-specific authentication state, not infrastructure configuration. Complete enrollment with the existing lab's manual `associate-software-token` and `verify-software-token` sequence before using the helper script. This separation also avoids placing a TOTP seed in Terraform state.

## Use The Token Helper

The helper uses the public no-secret app client. Its AWS identity also needs `dynamodb:PutItem` on the token table; that is an operator/client permission and is deliberately not granted to any Lambda role.

```bash
export AWS_REGION="$(terraform output -raw user_pool_id | cut -d_ -f1)"
export COGNITO_PUBLIC_CLIENT_ID="$(terraform output -raw public_client_id)"
export COGNITO_USERNAME="chewbacca"
export API_BASE="$(terraform output -raw api_base_url)"
export TOKEN_TABLE_NAME="$(terraform output -raw token_table_name)"
python scripts/get_token.py
```

The script prompts for the password and MFA code, creates a DynamoDB record with `used=false`, and prints access-token route commands. A route request carrying its `x-token-id` updates that record to `used=true`.

## Quick Authorization Checks

No token should be rejected before Lambda:

```bash
curl "$(terraform output -raw jedi_url)?name=Chewbacca"
```

Expected: `401 Unauthorized`.

Use the access token printed by the helper for the scoped method:

```bash
curl "$(terraform output -raw jedi_url)?name=Chewbacca" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "x-token-id: $TOKEN_ID"
```

Do not use the ID token for these methods. The configured authorization scope makes the access token the appropriate token type.

## Detector Test

Run the helper, but do not invoke either API route. After `token_unused_minutes` has elapsed, wait for the schedule or invoke the detector Lambda manually. A log line beginning with `ALERT: Token unused` becomes a custom metric, which moves the alarm to `ALARM` and publishes to SNS.

If `alert_email` was set, confirm the subscription from the AWS email before expecting messages. Terraform cannot confirm an email subscription for you.

## Security Notes

- `test_user_password` and the generated app-client secret are sensitive, but Terraform state still contains sensitive values. Protect the state file and use a secure remote backend in shared environments.
- The reference outputs the client secret only as a sensitive output because the lab explicitly practices `SECRET_HASH`. Retrieve it only when needed.
- The two route roles can only update the one token table. The detector can only scan it. Scheduler can only invoke the detector.
- API execution logging does not include full request/response data because that can expose JWTs or personal data.
- The Lambda handlers currently use runtime-included AWS SDKs to preserve the project's simple single-file packaging. Production packages should pin and bundle SDK dependencies.
- The test user, short-lived tokens, example callback, and email-based SNS subscription are lab choices, not a production identity lifecycle.

## Production Considerations

- Enable Cognito deletion protection and define a real user onboarding process instead of managing end-user passwords in Terraform.
- Use a real callback/logout URL and consider a custom Cognito domain.
- Put state in an encrypted, versioned remote backend with locking and tightly controlled access.
- Consider customer-managed KMS keys, DynamoDB deletion protection, backup policy, alarms for Lambda/API errors, WAF, throttling, and API Gateway custom domains.
- Replace full-table scans with a scalable data model or index when token volume grows.
- Add a TTL attribute and retention policy for token metadata; never store raw JWTs in DynamoDB or logs.
- Package and pin application dependencies, add unit/integration tests, and promote immutable Lambda versions through environments.

## Destroy

```bash
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Destroying the DynamoDB table removes token-tracking records. Point-in-time recovery helps with accidental changes while the table exists, but it is not a substitute for a production backup and retention policy.
