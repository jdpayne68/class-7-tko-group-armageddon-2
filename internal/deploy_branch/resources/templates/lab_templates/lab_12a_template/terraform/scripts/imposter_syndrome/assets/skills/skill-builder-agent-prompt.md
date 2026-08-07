# Terraform Skill Builder Agent

## Terraform Directory

```text
PASTE_TERRAFORM_DIRECTORY_HERE
```

## Task

Analyze the Terraform deployment above and generate the canonical skill
definition file for the **Imposter Syndrome** scanner.

Create or replace only:

```text
terraform/scripts/imposter_syndrome/assets/skills/skills.tf
```

Do not modify deployment Terraform, scripts, quotes, examples, documentation,
state, plans, generated files, or any other repository content.

`skills.tf` is the active scanner contract. `skills-example.tf` is only a human
reference and must not be treated as scanner input.

## Architecture

The scanner uses three separate inputs:

```text
Student Terraform  -> What was built
skills.tf          -> What skills those blocks demonstrate
quotes.json        -> Encouragement shown by the script
```

This prompt is responsible only for generating `skills.tf`.

## Ignore

Do not scan or extract Terraform from:

```text
.terraform/
.git/
terraform/scripts/
terraform/assets/
terraform/lambda/
*.tfstate
*.tfstate.*
*.tfplan
*.zip
```

Also ignore generated, cache, backup, temporary, and editor metadata files.

Never scan the output file itself:

```text
terraform/scripts/imposter_syndrome/assets/skills/skills.tf
```

## Extract

Extract every active Terraform block matching:

```hcl
resource "TYPE" "NAME" {
  ...
}

data "TYPE" "NAME" {
  ...
}
```

Preserve each block as syntactically complete Terraform.

Rules:

- Do not invent blocks.
- Do not omit active blocks.
- Do not redesign, rename, normalize, optimize, or fix Terraform.
- Do not deduplicate blocks.
- Preserve duplicate resource or data source types when they exist in the deployment.
- Do not extract commented-out Terraform.

## Strip Comments

Remove comments copied from the deployment.

Strip comment forms such as:

```hcl
# comment

// comment

/*
  comment
*/
```

The generated file should contain only:

1. The required file header.
2. Generated `#SKILL:` tags.
3. Extracted Terraform `resource` and `data` blocks.

Do not copy section headings, notes, disabled Terraform, documentation comments,
or other nonfunctional comments from the deployment.

## Skill Tag Methodology

Use a two-or-three tag model for every extracted block.

Every block must receive:

1. A service/product skill.
2. A capability skill.
3. An optional workflow/context skill only when it adds clear operational meaning.

The service/product tag identifies the platform or product the block belongs to.
The capability tag identifies the practical infrastructure skill demonstrated by
that block. The optional workflow/context tag identifies the larger engineering
pattern the block supports.

Do not use more than three tags on any block.

This keeps the scanner accurate without turning every resource into noisy
metadata. A block may relate to many ideas, but `skills.tf` should capture only
the strongest two or three skills a student can reasonably claim from that
block.

## Skill Selection Rules

Prefer stable, reusable skill names over one-off labels.

Use this decision order:

1. Identify the Terraform block type.
2. Assign the most specific service/product skill.
3. Assign the most specific capability skill.
4. Add one workflow/context skill only when the block directly supports a named workflow.
5. If several workflow/context skills apply, choose the strongest one.

Recommended workflow/context priority:

```text
Threat Correlation
Amazon Bedrock
Security Automation
WAF Telemetry
Protected API Routes
```

Use this priority only when a block could reasonably receive multiple workflow
tags. Do not force a workflow tag onto generic infrastructure.

## Service And Product Skills

Recommended service/product skill names include:

```text
AWS Account
AWS IAM
AWS Lambda
AWS WAF
Amazon API Gateway
Amazon Bedrock
Amazon CloudWatch
Amazon Cognito
Amazon DynamoDB
Amazon EventBridge
Amazon EventBridge Scheduler
Amazon S3
Amazon SNS
Terraform
```

## Capability Skills

Recommended capability skill names include:

```text
Account Discovery
API Authorization
API Deployments
API Lambda Integrations
API Logging Configuration
API Methods
API Resource Routing
API Stages
App Clients
IAM Managed Policies
IAM Permission Policies
IAM Policy Attachments
IAM Resource Policies
IAM Roles
IAM Trust Policies
Lambda Functions
Lambda Invocation Permissions
Lambda Packaging
Log Groups
Log Metric Filters
Log Resource Policies
Managed Rule Groups
NoSQL Tables
Scheduled Invocations
Topic Subscriptions
User Pools
Web ACL Associations
WAF Log Delivery
```

## Workflow And Context Skills

Recommended workflow/context skill names include:

```text
Amazon Bedrock
Protected API Routes
Security Automation
Threat Correlation
WAF Telemetry
```

Only use these when they describe the role the block plays in the deployment.
For example, an ordinary Lambda function receives `AWS Lambda` and
`Lambda Functions`; a Lambda function that performs unused-token detection may
also receive `Security Automation`.

## Resource Mapping Framework

Use these mappings as the primary framework for common Terraform block types.

### AWS Account

```text
aws_caller_identity                -> AWS Account + Account Discovery
aws_partition                      -> AWS Account + Account Discovery
aws_region                         -> AWS Account + Account Discovery
```

### Terraform Helpers

```text
archive_file                       -> Terraform + Lambda Packaging
random_id                          -> Terraform + Terraform Helpers
random_string                      -> Terraform + Terraform Helpers
```

### AWS IAM

```text
aws_iam_role                       -> AWS IAM + IAM Roles
aws_iam_policy                     -> AWS IAM + IAM Managed Policies
aws_iam_role_policy_attachment     -> AWS IAM + IAM Policy Attachments
aws_iam_policy_document            -> AWS IAM + IAM Permission Policies
```

For `aws_iam_policy_document`, inspect the document purpose:

```text
Assume-role document with principals and sts:AssumeRole -> AWS IAM + IAM Trust Policies
Permission statement document                            -> AWS IAM + IAM Permission Policies
Resource-based access document                           -> AWS IAM + IAM Resource Policies
```

If an IAM block grants permissions for a specific workflow, the third tag may
name that workflow.

Examples:

```text
Bedrock invoke permissions           -> AWS IAM + IAM Permission Policies + Amazon Bedrock
WAF log delivery resource policy     -> AWS IAM + IAM Resource Policies + WAF Telemetry
Threat correlation Lambda role       -> AWS IAM + IAM Roles + Threat Correlation
```

### AWS Lambda

```text
aws_lambda_function                 -> AWS Lambda + Lambda Functions
aws_lambda_permission               -> AWS Lambda + Lambda Invocation Permissions
archive_file                        -> Terraform + Lambda Packaging
```

Add a workflow/context tag only when the function or permission clearly supports
a named workflow.

Examples:

```text
unused_token_detector Lambda         -> AWS Lambda + Lambda Functions + Security Automation
waf_bedrock_analyzer Lambda          -> AWS Lambda + Lambda Functions + Threat Correlation
soar_response_agent Lambda           -> AWS Lambda + Lambda Functions + Security Automation
```

### Amazon API Gateway

```text
aws_api_gateway_rest_api            -> Amazon API Gateway + REST API Definition
aws_api_gateway_authorizer          -> Amazon API Gateway + API Authorization
aws_api_gateway_resource            -> Amazon API Gateway + API Resource Routing
aws_api_gateway_method              -> Amazon API Gateway + API Methods
aws_api_gateway_integration         -> Amazon API Gateway + API Lambda Integrations
aws_api_gateway_deployment          -> Amazon API Gateway + API Deployments
aws_api_gateway_stage               -> Amazon API Gateway + API Stages
aws_api_gateway_account             -> Amazon API Gateway + API Logging Configuration
```

Use `Protected API Routes` only for routes, methods, integrations, or
permissions that directly support protected application endpoints.

### Amazon Cognito

```text
aws_cognito_user_pool               -> Amazon Cognito + User Pools
aws_cognito_user_pool_client        -> Amazon Cognito + App Clients
```

### AWS WAF

```text
aws_wafv2_web_acl                   -> AWS WAF + Managed Rule Groups
aws_wafv2_web_acl_association       -> AWS WAF + Web ACL Associations
aws_wafv2_web_acl_logging_configuration -> AWS WAF + WAF Log Delivery
```

Use `WAF Telemetry` only when the block directly supports WAF logging, metrics,
or downstream analysis.

### Amazon CloudWatch

```text
aws_cloudwatch_log_group            -> Amazon CloudWatch + Log Groups
aws_cloudwatch_log_resource_policy  -> Amazon CloudWatch + Log Resource Policies
aws_cloudwatch_log_metric_filter    -> Amazon CloudWatch + Log Metric Filters
aws_cloudwatch_metric_alarm         -> Amazon CloudWatch + Metric Alarms
```

### Amazon DynamoDB

```text
aws_dynamodb_table                  -> Amazon DynamoDB + NoSQL Tables
```

Add a workflow/context tag when the table exists specifically for correlation,
evidence, incidents, or another named security workflow.

### Amazon EventBridge Scheduler

```text
aws_scheduler_schedule              -> Amazon EventBridge Scheduler + Scheduled Invocations
```

### Amazon SNS

```text
aws_sns_topic                       -> Amazon SNS + Notification Topics
aws_sns_topic_subscription          -> Amazon SNS + Topic Subscriptions
```

### Amazon S3

```text
aws_s3_bucket                       -> Amazon S3 + Object Storage
aws_s3_bucket_*                     -> Amazon S3 + Bucket Configuration
```

## Examples

```hcl
#SKILL: AWS Lambda
#SKILL: Lambda Functions
#SKILL: Security Automation
resource "aws_lambda_function" "unused_token_detector" {
  ...
}
```

```hcl
#SKILL: AWS IAM
#SKILL: IAM Roles
#SKILL: Amazon Bedrock
resource "aws_iam_role" "waf_bedrock_analyzer_role" {
  ...
}
```

```hcl
#SKILL: AWS IAM
#SKILL: IAM Permission Policies
data "aws_iam_policy_document" "unused_token_detector" {
  ...
}
```

```hcl
#SKILL: AWS WAF
#SKILL: Managed Rule Groups
resource "aws_wafv2_web_acl" "shield_generator" {
  ...
}
```

```hcl
#SKILL: Terraform
#SKILL: Lambda Packaging
data "archive_file" "soar_response_agent" {
  ...
}
```

## Required Tag Format

Every extracted `resource` or `data` block must have two or three skill tags
immediately above its declaration.

Use this model:

1. Service or product skill.
2. Capability skill.
3. Optional workflow/context skill when it adds clear operational meaning.

There must be no blank line between the final `#SKILL:` tag and the Terraform block.
There should also be no blank lines between adjacent `#SKILL:` tags.

The tag format is strictly:

```text
#SKILL: <Skill Name>
```

Do not use any other comment as a skill marker.

## Output Header

Begin `skills.tf` with:

```hcl
# ================================================================
# TERRAFORM SKILL DEFINITIONS
#
# AI AGENT GENERATED
#
# Canonical RESOURCE/DATA -> SKILL mappings used by
# the Imposter Syndrome scanner.
#
# Each active resource or data block has two or three #SKILL tags:
# service/product, capability, and optional workflow context.
# Do not scan this file as student Terraform.
# ================================================================
```

After the header, output only the tagged Terraform blocks.

## Validation

Before finishing, verify:

- Every active `resource` block in the deployment was extracted.
- Every active `data` block in the deployment was extracted.
- Existing deployment comments were removed.
- Commented-out Terraform was not extracted.
- Every extracted block has two or three `#SKILL:` tags.
- No extracted block has one skill tag.
- No extracted block has more than three skill tags.
- Every group of `#SKILL:` tags is immediately above its block.
- There are no blank lines inside a skill-tag group.
- Duplicate resources and duplicate data source types were preserved.
- No Terraform resources or data sources were invented.
- Ignored directories were not scanned.
- No deployment files were modified.
- `skills-example.tf` was not modified.
- The final file exists at `terraform/scripts/imposter_syndrome/assets/skills/skills.tf`.
- No references to the old skill-contract filename exist in generated skill assets.
- No references to the old misspelled directory path exist in generated skill assets.

If feasible, run:

```bash
terraform fmt -check terraform/scripts/imposter_syndrome/assets/skills/skills.tf
```

If a block cannot be confidently mapped to a skill, include it anyway with the
best broad skill labels and report it as low confidence in the final response.

## Final Response

Report only:

```text
Terraform Skill Definitions Generated

Resources: <count>
Data Sources: <count>
Total Blocks: <count>
Total Skill Tags: <count>
Unique Skills: <count>
Blocks With 2 Tags: <count>
Blocks With 3 Tags: <count>
Blocks With More Than 3 Tags: <count>
Low Confidence Mappings: <count>

Output:
terraform/scripts/imposter_syndrome/assets/skills/skills.tf
```
