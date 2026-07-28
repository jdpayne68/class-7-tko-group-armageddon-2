# AWS Resource Study Guide

## Complete Resource Inventory

Every managed resource block is listed here. Repeated resources are intentionally explicit to match the original learning style.

| Terraform Address | Why It Exists | Primary Dependency / Consumer |
| --- | --- | --- |
| `random_string.cognito_domain_suffix` | makes the Cognito prefix domain globally unique | Cognito user-pool domain |
| `aws_cognito_user_pool.chewbacca_auth_rest` | identity directory, password policy, MFA, and token issuer | app clients and API authorizer |
| `aws_cognito_user_pool_client.public` | no-secret API auth client and managed-login client | token helper and browser login |
| `aws_cognito_user_pool_client.cli` | secret-bearing client for `SECRET_HASH` study | manual CLI flow |
| `aws_cognito_user_pool_domain.chewbacca_auth_rest` | activates OAuth/OIDC and managed-login endpoints | browser login |
| `aws_cognito_managed_login_branding.public` | gives the public programmatic client a usable login style | public client |
| `aws_cognito_managed_login_branding.cli` | gives the secret client a usable login style | CLI client |
| `aws_cognito_user.chewbacca` | supplies the lab identity | Cognito authentication flow |
| `aws_dynamodb_table.token_holocron` | stores token-use metadata | helper, route Lambdas, detector |
| `aws_iam_policy.route_lambda_token_update` | grants only `UpdateItem` on the token table | Jedi and Sith roles |
| `aws_iam_policy.token_detector_scan` | grants only `Scan` on the token table | detector role |
| `aws_iam_policy.scheduler_invoke_detector` | grants only detector invocation | Scheduler role |
| `aws_iam_role.jedi_python_role` | execution identity for Jedi Lambda | Jedi function |
| `aws_iam_role.sith_node_role` | execution identity for Sith Lambda | Sith function |
| `aws_iam_role.unused_token_detector_role` | execution identity for detector Lambda | detector function |
| `aws_iam_role.scheduler_role` | identity EventBridge Scheduler assumes | Scheduler target |
| `aws_iam_role.api_gateway_cloudwatch_role` | identity API Gateway assumes for logging | API Gateway account setting |
| `aws_iam_role_policy_attachment.jedi_python_basic_execution` | CloudWatch Logs permission | Jedi role |
| `aws_iam_role_policy_attachment.jedi_python_token_update` | table update permission | Jedi role |
| `aws_iam_role_policy_attachment.sith_node_basic_execution` | CloudWatch Logs permission | Sith role |
| `aws_iam_role_policy_attachment.sith_node_token_update` | table update permission | Sith role |
| `aws_iam_role_policy_attachment.unused_token_detector_basic_execution` | CloudWatch Logs permission | detector role |
| `aws_iam_role_policy_attachment.unused_token_detector_scan` | table scan permission | detector role |
| `aws_iam_role_policy_attachment.scheduler_invoke_detector` | detector invocation permission | Scheduler role |
| `aws_iam_role_policy_attachment.api_gateway_cloudwatch_logs` | API Gateway log-publish permission | API Gateway role |
| `aws_cloudwatch_log_group.jedi_python` | finite-retention Jedi logs | Jedi function |
| `aws_cloudwatch_log_group.sith_node` | finite-retention Sith logs | Sith function |
| `aws_cloudwatch_log_group.unused_token_detector` | detector logs and alert source | detector and metric filter |
| `aws_cloudwatch_log_group.api_gateway_access` | structured REST access logs | prod stage |
| `aws_lambda_function.jedi_python` | protected Python route | API Jedi integration |
| `aws_lambda_function.sith_node` | protected Node.js route | API Sith integration |
| `aws_lambda_function.unused_token_detector` | detects old unused records | Scheduler and CloudWatch Logs |
| `aws_api_gateway_rest_api.chewbacca_auth_rest_api` | REST API container and execution ARN | all REST resources |
| `aws_api_gateway_authorizer.cognito` | connects the REST API to the user pool | protected methods |
| `aws_api_gateway_resource.jedi` | creates `/jedi` | Jedi GET method |
| `aws_api_gateway_method.jedi_get` | defines scoped Cognito authorization | Jedi integration |
| `aws_api_gateway_integration.jedi_lambda` | forwards requests/events with Lambda proxy semantics | Jedi Lambda |
| `aws_lambda_permission.api_gateway_invoke_jedi` | permits invocation from this API/path | API Gateway |
| `aws_api_gateway_resource.sith` | creates `/sith` | Sith GET method |
| `aws_api_gateway_method.sith_get` | defines scoped Cognito authorization | Sith integration |
| `aws_api_gateway_integration.sith_lambda` | forwards requests/events with Lambda proxy semantics | Sith Lambda |
| `aws_lambda_permission.api_gateway_invoke_sith` | permits invocation from this API/path | API Gateway |
| `aws_api_gateway_deployment.chewbacca_auth_rest` | snapshots deployable REST configuration | prod stage |
| `aws_api_gateway_stage.prod` | publishes the snapshot at `/prod` | API callers |
| `aws_api_gateway_method_settings.prod` | enables metrics/execution logging without body tracing | prod stage |
| `aws_api_gateway_account.current` | gives API Gateway its regional CloudWatch role | REST execution logging |
| `aws_scheduler_schedule.unused_token_check` | periodically invokes the detector | detector Lambda |
| `aws_cloudwatch_log_metric_filter.unused_token` | converts `ALERT:` log lines to metric points | alarm |
| `aws_sns_topic.token_alerts` | notification fan-out destination | alarm and subscribers |
| `aws_sns_topic_subscription.token_alert_emails` | optional human email endpoint | SNS topic |
| `aws_cloudwatch_metric_alarm.unused_token` | evaluates alert metric and publishes to SNS | operator notification |

## Cognito Resources

### User pool: `aws_cognito_user_pool.chewbacca_auth_rest`

**Purpose and integration.** The pool is the authoritative user directory and JWT issuer. API Gateway's authorizer trusts its ARN; both app clients belong to it.

**Important arguments and AWS concepts.** `user_pool_tier = "ESSENTIALS"` and the `PASSWORD` sign-in policy support choice-based `USER_AUTH`. `mfa_configuration = "ON"` plus `software_token_mfa_configuration` requires TOTP. Alias and auto-verification settings allow email sign-in/recovery. Schema blocks make name, birthdate, and phone required. The password policy applies to both permanent and temporary passwords.

**Mistakes/troubleshooting.** Schema attributes cannot be freely removed or changed after pool creation. `ALLOW_USER_AUTH` errors point to pool tier/sign-in policy or app-client flow settings. MFA setup failures usually mean the user has not associated and verified a software token.

**Security/production.** Keep MFA, hide user enumeration through clients, consider deletion protection and threat protection, and define real email delivery/onboarding. Required phone/birthdate attributes increase personal-data handling obligations.

### App clients: `public` and `cli`

**Purpose and integration.** The public client supports a local helper that cannot safely keep a secret. The CLI client intentionally has a secret so the learner can practice `SECRET_HASH`. Both issue access tokens accepted by the API authorizer.

**Important arguments and concepts.** `explicit_auth_flows` controls Cognito API authentication. OAuth code flow, callback URL, identity provider, and scopes support managed login. Token validity values are short lab durations, and the units block prevents accidental interpretation as hours/days.

**Mistakes/troubleshooting.** A secret-bearing client requires a correct HMAC secret hash for API auth. A callback URL must match exactly. `aws.cognito.signin.user.admin` is the scope enforced by the API methods; use an access token.

**Security/production.** Public clients should use authorization code with PKCE. Confidential clients must keep secrets server-side. Rotate/recreate exposed secrets and reduce scopes to application requirements.

### Domain and branding

**Purpose and integration.** `aws_cognito_user_pool_domain` publishes Cognito-hosted OAuth endpoints. The two `aws_cognito_managed_login_branding` resources assign Cognito's default managed-login style to programmatically created clients.

**Important arguments and concepts.** A prefix domain is globally unique and version `2` selects managed login. AWS does not automatically add branding when a client is created by API/Terraform.

**Mistakes/troubleshooting.** Reserved domain words, uniqueness collisions, missing callback/OAuth settings, or missing branding produce unusable login pages. Domain changes can take time to propagate.

**Security/production.** Prefer a controlled custom domain when brand trust or policy requires it. Keep redirect URIs exact; never use broad wildcard redirects.

### Test user: `aws_cognito_user.chewbacca`

**Purpose and integration.** Supplies a confirmed local lab identity whose permanent password can immediately enter the MFA setup/authentication flow.

**Important arguments and concepts.** All required schema values are supplied. `message_action = "SUPPRESS"` avoids sending the default invitation. `password` differs from `temporary_password`: it does not force the `NEW_PASSWORD_REQUIRED` challenge.

**Mistakes/troubleshooting.** Missing required attributes reject creation. Passwords must satisfy the pool policy. Terraform cannot pre-enroll the user's authenticator seed.

**Security/production.** End-user passwords should not normally be managed in Terraform. State access reveals sensitive configuration; use a real registration/admin workflow.

## DynamoDB Resource

### Table: `aws_dynamodb_table.token_holocron`

**Purpose and integration.** The helper writes a record when it retrieves tokens, routes mark the record used, and the detector scans for old `used=false` records.

**Important arguments and concepts.** `token_id` is the partition key. On-demand billing fits unpredictable lab traffic. server-side encryption and PITR are enabled.

**Mistakes/troubleshooting.** Terraform `attribute` blocks describe keys/indexes only. The helper's local AWS identity—not a Lambda role—needs `PutItem`. Full scans paginate and consume read capacity.

**Security/production.** Never store raw access/ID/refresh tokens. Add retention/TTL and redesign around an indexed status/timestamp query at scale.

## IAM Resources

### Customer policies

**Purpose and integration.** Route update, detector scan, and Scheduler invoke policies each express one relationship. They reference exact Terraform-created ARNs, which also creates dependency edges.

**Important arguments and concepts.** IAM authorization combines an assumed role's trust policy, attached identity policies, action, resource, and any conditions. The route policy has only `UpdateItem`; the detector only `Scan`; Scheduler only `InvokeFunction` on one function.

**Mistakes/troubleshooting.** A trust policy alone grants no service actions. A permission policy does not let a service assume a role. Check CloudTrail/role ARN, action spelling, resource ARN, and propagation when denied.

**Security/production.** Avoid `Resource = "*"` where resource-level permissions exist. The draft's unused Bedrock wildcard policy is intentionally absent.

### Roles and attachments

**Purpose and integration.** Separate roles prevent Jedi, Sith, detector, Scheduler, and API Gateway from inheriting each other's permissions. Attachments join reusable managed/customer policies to roles.

**Important arguments and concepts.** Lambda trusts `lambda.amazonaws.com`; Scheduler trusts `scheduler.amazonaws.com`; API Gateway trusts `apigateway.amazonaws.com`. AWS-managed basic execution grants Lambda log publishing.

**Mistakes/troubleshooting.** API Gateway's CloudWatch role is configured account-wide per Region. Another stack may already own it. IAM role creation can succeed before permissions are fully propagated; explicit dependencies reduce this race.

**Security/production.** Review AWS-managed policies over time, add conditions such as source account/ARN where supported, and coordinate singleton account settings.

## Lambda And Permission Resources

### Lambda functions: Jedi, Sith, and detector

**Purpose and integration.** Jedi and Sith serve protected proxy routes and update token records. The detector reads those records on schedule and emits structured-enough alert text.

**Important arguments and concepts.** An archive hash causes code updates. Handler strings are `filename.export`. Python 3.14 and Node.js 24 are current managed runtimes. Environment variables link functions to the table without hard-coding its generated name.

**Mistakes/troubleshooting.** `Runtime.ImportModuleError` means a handler/file/dependency mismatch. Timeouts or `AccessDenied` point to table size, IAM, or wrong environment variables. The Node and Python SDKs are runtime-provided in this lab.

**Security/production.** Bundle pinned dependencies, scan packages, use versions/aliases and reserved concurrency where appropriate, and avoid logging tokens. The routes should use conditional updates to reject arbitrary/unissued token IDs in a production detector.

### Lambda permissions: Jedi and Sith

**Purpose and integration.** Resource-based Lambda policies allow only this REST API's GET path (across stages) to invoke each function.

**Important arguments and concepts.** API Gateway calls Lambda with its service principal. `source_arn` narrows the permission to API ID, method, and path.

**Mistakes/troubleshooting.** Missing permission commonly appears as API Gateway `500` with an invocation-permission error. Method/path case and stage wildcards must match the execution ARN.

**Security/production.** Narrow stage from `*` if only one stage should invoke the function, and use `source_account` where appropriate.

## API Gateway Resources

### REST API, resources, methods, authorizer, and integrations

**Purpose and integration.** The REST API contains `/jedi` and `/sith`. Each GET method uses the same native Cognito authorizer and scope, then uses Lambda proxy integration.

**Important arguments and concepts.** `REGIONAL` creates an AWS Region endpoint. The authorizer validates Cognito JWTs from its provider pool. With `authorization_scopes`, an access token must carry the required scope. `AWS_PROXY` passes request context directly to Lambda, and the integration call is always POST.

**Mistakes/troubleshooting.** `401` usually means missing/invalid/expired/wrong-pool token. `403` often means wrong token type or missing scope. A malformed Lambda proxy response yields `502`. The public client and API must use the same pool.

**Security/production.** Add throttling, WAF, resource policy, custom domain, request validation, alarms, and carefully designed CORS if browser clients are introduced.

### Deployment, stage, settings, and account

**Purpose and integration.** A deployment snapshots the REST configuration; the `prod` stage makes that snapshot callable. Settings turn on metrics/execution logs, access logs go to a dedicated group, and the account resource supplies API Gateway's logging role.

**Important arguments and concepts.** The trigger hash changes when authorizer/resources/methods/integrations change. `create_before_destroy` avoids dropping the stage's deployment first. REST API configuration is not live until deployed.

**Mistakes/troubleshooting.** Stale behavior means the deployment trigger missed a dependency or no new deployment was created. Logging errors usually mean the regional account role is missing or not assumable.

**Security/production.** `data_trace_enabled = false` avoids request/response body leakage. The account role is a shared singleton; import or manage it centrally when necessary.

## EventBridge Scheduler Resource

### Schedule: `aws_scheduler_schedule.unused_token_check`

**Purpose and integration.** Runs the detector every five minutes by default using a dedicated execution role.

**Important arguments and concepts.** Scheduler assumes its role, then calls Lambda's Invoke API. `mode = "OFF"` disables flexible timing so the rate is predictable for the lab.

**Mistakes/troubleshooting.** Classic EventBridge rule examples use different resources and permissions. Check Scheduler execution history, target ARN, trust policy, and invoke policy.

**Security/production.** Configure retries and a dead-letter queue, alarm on failed invocations, and choose a schedule appropriate to cost and detection latency.

## CloudWatch And SNS Resources

### Log groups and metric filter

**Purpose and integration.** Explicit log groups prevent infinite default retention. The detector filter turns matching future log events into a custom count metric.

**Important arguments and concepts.** Metric filters work only on newly ingested logs and Standard-class groups. The exact phrase is quoted so it is matched as a phrase. A default zero prevents gaps when logs are ingested without alerts.

**Mistakes/troubleshooting.** Old events never backfill a metric. Test exact capitalization/punctuation and confirm the Lambda uses the expected log group.

**Security/production.** Set retention to policy, redact PII/tokens, encrypt with customer keys when required, and control log access.

### Alarm, SNS topic, and subscription

**Purpose and integration.** The alarm sums alert events in one-minute periods. On threshold breach, it publishes to an SNS topic; an optional subscription sends email.

**Important arguments and concepts.** Missing data is non-breaching, avoiding false alarms while no detector logs arrive. The topic uses the AWS-managed SNS KMS key. Email endpoints require out-of-band confirmation.

**Mistakes/troubleshooting.** A pending confirmation receives no notifications. An alarm can remain `INSUFFICIENT_DATA` until metric data exists. Confirm the metric namespace/name exactly.

**Security/production.** Add a restrictive topic policy where cross-account publishing is not needed, use governed operational endpoints, and test the alarm path on a schedule.

## Terraform Data Sources

- `aws_region.current`, `aws_caller_identity.current`, and `aws_partition.current` make endpoints/ARNs portable and verify the selected AWS context.
- IAM policy-document data sources generate valid JSON and expose dependencies without hand-built string documents.
- Archive-file data sources create deterministic ZIP inputs and hashes. Their output ZIPs are generated artifacts and ignored by Git.

Data-source failures during plan usually indicate missing credentials, an unavailable provider plugin, or a referenced local file that does not exist.
