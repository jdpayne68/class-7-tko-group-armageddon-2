# Troubleshooting Guide

Work left to right through the service boundary. Avoid changing several layers at once.

| Symptom | Likely Cause | Checks / Fix |
| --- | --- | --- |
| `terraform init` cannot query providers | network/DNS restriction or registry outage | Confirm network access to `registry.terraform.io`; retry from the intended environment. |
| Provider schema will not load | provider binary execution blocked or wrong platform | Re-run init for the current platform, inspect `.terraform/providers`, and allow provider execution. |
| AWS data source/plan authentication error | wrong profile, expired SSO session, or wrong Region | Run `aws sts get-caller-identity --profile ...`; refresh SSO and confirm `aws_profile`/`aws_region`. |
| Cognito schema update proposes replacement or fails | required standard attributes are hard to change | Treat the schema as an early design decision; recreate only in a disposable lab. |
| `ALLOW_USER_AUTH` rejected | app-client flow, pool tier, or first-factor policy missing | Confirm Essentials tier, `PASSWORD` first factor, and `ALLOW_USER_AUTH` on the client. |
| Managed login says something went wrong | domain, branding, OAuth flow, scope, or callback missing/mismatched | Check the domain is active, branding exists for that client, and callback matches exactly. Allow propagation time. |
| `NotAuthorizedException` with secret client | missing or incorrect `SECRET_HASH` | Recalculate HMAC from username + client ID using the correct client secret. |
| User cannot sign in while MFA is required | TOTP not enrolled or session expired | Restart auth, associate/verify the software token, set preference, and use each new `Session` only once. |
| API returns `401` | absent, malformed, expired, wrong-Region, or wrong-pool token | Decode only for inspection; compare `iss`, `exp`, and client claims with Terraform outputs. |
| API returns `403` | ID token used or access token lacks required scope | Use the access token and confirm `scope` includes `aws.cognito.signin.user.admin`. |
| API returns `500` | API Gateway cannot invoke Lambda or execution role/logging error | Check Lambda resource policy, integration URI, API execution logs, and `aws_lambda_permission`. |
| API returns `502` | Lambda exception or invalid proxy response | Inspect Lambda logs; response must contain numeric `statusCode` and string `body`. |
| API changes do not appear | REST API was not redeployed | Inspect deployment trigger inputs and apply a new deployment. |
| Lambda `Runtime.ImportModuleError` | handler/module mismatch or missing dependency | Jedi: `jedi_python.lambda_handler`; Sith: `sith_node.handler`; detector: `unused_token_detector.lambda_handler`. |
| Route says `update-failed` | wrong table environment variable or no `UpdateItem` permission | Check `TOKEN_TABLE_NAME`, role attachment, table ARN, and CloudWatch error. |
| Helper fails `PutItem` | caller's own AWS identity lacks DynamoDB access | Grant the operator only `dynamodb:PutItem` on the output table; Lambda roles are unrelated. |
| Detector misses records | `used` is not Boolean false, timestamp invalid, threshold not elapsed, or scan failure | Inspect an item, detector result log, pagination errors, environment threshold, and current UTC time. |
| No custom metric | filter created after the log, phrase mismatch, or wrong log group | Generate a new exact `ALERT: Token unused` line and inspect the filter/namespace. Filters are not retroactive. |
| Alarm stays `INSUFFICIENT_DATA` | metric has never emitted | Invoke detector after creating an old unused record; then inspect the custom metric. |
| No email alert | SNS subscription is pending | Confirm the AWS SNS email, inspect topic subscription status, and test-publish to the topic. |
| Scheduler target failure | role trust/InvokeFunction permission wrong | Inspect Scheduler execution history, role trust principal, policy target ARN, and Lambda state. |
| API Gateway logging conflicts during apply | another stack owns regional `cloudwatch_role_arn` | Import `aws_api_gateway_account.current` or remove it here and use the centrally managed setting. |
| Destroy cannot remove user pool/table | deletion protection enabled outside this reference | Disable protection deliberately, apply, then destroy. Confirm the active account first. |

## Safe Diagnostic Commands

```bash
terraform fmt -check -recursive
terraform validate
terraform providers
terraform state list
terraform output
aws sts get-caller-identity --profile default
```

Do not paste JWTs, passwords, client secrets, TOTP seeds, or Terraform state into shared tickets or chat logs.
