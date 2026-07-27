# Existing Terraform Analysis And Style Decisions

## What Was Analyzed

The neighboring `terraform` directory was read in full before this reference was written, including all `.tf` files, Lambda handlers, the token helper, the REST lab README, architecture notes, CLI lab, Console lab, environment template, and teardown guide. The token-detector lab was also traced because the existing Terraform draft already includes its detector Lambda, DynamoDB permissions, and token-aware route code.

## Existing Style

The draft uses:

- one concern per plainly named `.tf` file;
- large `====` file headings and `----` section headings;
- explicit resources rather than modules or dense collection expressions;
- descriptive snake-case Terraform labels;
- `app` and `env` inputs normalized into a `name_prefix` local;
- data-driven IAM policy documents;
- separate IAM policy, role, and attachment resources;
- `archive_file` data sources next to Lambda resources;
- direct defaults that make a lab approachable;
- extensive inline comments and official documentation URLs.

This reference preserves those choices. It intentionally does not introduce modules, generated maps of functions, dynamic blocks, wrapper tooling, or a remote-state bootstrap module.

## Gaps Found In The Draft

The existing files are clearly an in-progress learning implementation. Important findings were:

- `api-gateway.tf` mixes intended resources with provider examples and references resources that do not exist.
- The API stage points to the example deployment and uses stage name `example`.
- Lambda handlers use `lambda.handler` and `index.handler`, but the archive filenames export `jedi_python.lambda_handler`, `unused_token_detector.lambda_handler`, and `sith_node.handler`.
- Route Lambdas update DynamoDB, but the draft attaches DynamoDB permissions only to the detector role.
- The DynamoDB ARN is malformed (`dynamodb` is missing a colon before the Region) and hard-coded to a table that Terraform does not create.
- The detector scans a table, but no table, schedule, metric filter, alarm, or SNS topic is declared.
- A Bedrock invoke policy is attached even though no handler calls Bedrock.
- Cognito resources, the authorizer, protected methods, Lambda permissions, log groups, and outputs are absent.
- The GCS backend is hard-coded to a personal bucket, preventing a clean reference initialization for other learners.
- Random and local providers are declared even where their resources are not used; the archive provider is used but not declared.
- The CLI lab's `create-user-pool` path does not automatically create the “default” app client later looked up by name.
- The user-pool schema requires birthdate, but the documented test-user command omits it.
- The Lambda runtimes in the older lab commands are behind the newer runtime choices already present in the Terraform draft.

## Decisions In This Reference

- Both the base REST auth flow and token-detector add-on are included because the current draft already combines them.
- `app-env` naming is retained, even though some CLI lab examples omit the environment.
- A random suffix is used only for Cognito's globally unique prefix domain.
- Local state is the zero-setup default. The draft's GCS structure remains as a commented option, with an S3 option beside it.
- The provider remains pinned to the draft's AWS `~> 6.46.0` line. The archive provider is added because the code uses `archive_file`.
- Python 3.14 and Node.js 24 are retained because they are current supported Lambda runtimes and match the draft's intent.
- Bedrock permission is removed because unused wildcard permission is neither required nor least privilege.
- API Gateway logging is explicit. The account-level nature of `aws_api_gateway_account` is called out because it can conflict with another stack.
- TOTP enrollment remains an after-apply authentication step. A TOTP seed does not belong in Terraform state.
- The test user's permanent password uses the AWS provider's supported `password` argument. It remains a lab-only pattern because passwords and state require careful handling.

## Dependency Flow

Terraform infers most ordering from references:

```text
user pool -> app clients/domain/branding/user
user pool -> API authorizer -> methods -> integrations -> deployment -> stage
table -> IAM policies -> role attachments -> Lambdas
Lambda -> API integrations and Lambda permissions
detector Lambda -> Scheduler invoke policy -> Scheduler schedule
detector log group -> metric filter -> alarm -> SNS topic
```

Explicit `depends_on` is used only where a relationship exists operationally but is not fully represented by an argument, such as IAM policy propagation before Lambda creation, API configuration before deployment, and the API Gateway CloudWatch policy before setting the account role.
