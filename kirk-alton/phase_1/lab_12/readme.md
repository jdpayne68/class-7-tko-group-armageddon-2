# Armageddon 2: Phase 1

## Architecture

```text
Client
  |
  v
API Gateway
  |
  v
Application Lambda

API Gateway requests are inspected by AWS WAF
  |
  v
CloudWatch WAF Logs
  |
  v
WAF Bedrock Analyzer
  |
  v
DynamoDB: waf-events
  |
  v
Threat Correlation Agent
  |
  v
DynamoDB: waf-correlation-findings
  |
  v
EventBridge
  |
  v
SOAR Response Agent
  |-- SNS notification
  |-- DynamoDB: security-incidents
  `-- Finding status update

Executive Dashboard Agent
  |-- Reads all three DynamoDB tables
  |-- Invokes Amazon Bedrock
  `-- Writes PDF and JSON reports to Amazon S3
```

## Labs

- Lab 12: analyzer and correlation pipeline
- Lab 12a: EventBridge and SOAR response
- Lab 12b: executive PDF and JSON reporting

## Deployment

Complete the Terraform implementation, then run:

```bash
cd terraform
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Do not run `terraform apply` until the plan and expected cost have been reviewed.
