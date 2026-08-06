# Class 7 TKO Group Armageddon 2

Serverless AWS security lab series using Cognito, API Gateway, Lambda, AWS WAF, Bedrock, DynamoDB, EventBridge, CloudWatch, SNS, S3 reporting buckets, and staged security-response agents.

<<<<<<< HEAD
## Group submission

- [Phase 1: Labs 12, 12a, and 12b](./main/phase-1/)
- [Phase 2: Labs 12c and 12d](./main/phase-2/)

## Repository areas

- [Participant work](./members/)
- [Shared resources](./shared/)
- [Team documentation](./docs/)
- [Repository structure](./docs/repo-structure.md)
=======
This repository is organized as a progressive lab sequence. Each lab keeps the same Terraform shape and adds one capability layer at a time so the security architecture stays visible while the automation becomes more advanced.

## What This Demonstrates

- Cognito User Pool authentication
- API Gateway protected routes
- Python and Node.js Lambda functions
- unused-token detection
- AWS WAF log analysis
- Bedrock-assisted WAF analysis
- WAF threat correlation
- SOAR incident response automation
- executive security reporting
- compliance evidence reporting
- threat-intelligence enrichment work in progress
- DynamoDB evidence and report records
- EventBridge event routing and scheduled workflows
- CloudWatch logs, metrics, and alarms
- SNS alerting
- S3 report artifact storage
- Lambda layers for reporting dependencies

The labs preserve a small Jedi/Sith route pattern while adding WAF, incident-response, reporting, and intelligence agents around it.

## Lab Progression

Start with the phase and lab that matches the capability you want to build.

### Phase 1

Core serverless security path: detect WAF activity, correlate findings, respond to incidents, and produce reports.

| Path | Description |
| --- | --- |
| [Lab 12](phase_1/lab_12/readme.md) | Detect and correlate WAF threat activity |
| [Lab 12a](phase_1/lab_12a/readme.md) | Create SOAR incidents from findings |
| [Lab 12b](phase_1/lab_12b/readme.md) | Generate executive security reports |
| [Lab 12c](phase_1/lab_12c/readme.md) | Produce compliance evidence reports |

### Phase 2

Threat-intelligence expansion: enrich incidents with provider context, fused risk, and report artifacts.

| Path | Description |
| --- | --- |
| [Lab 12d](phase_2/lab_12d/README.md) | Enrich SOAR incidents with threat intelligence |

## Documentation

| Document | Use |
| --- | --- |
| [Repository Structure](repo-structure.md) | Repository map and intended lab progression |
| [Internal Contributing Guide](internal/CONTRIBUTING.md) | Contribution, validation, and safety expectations |
| [Security Intelligence Foundations](internal/security-intelligence-foundations.md) | Background reference for AbuseIPDB, CISA KEV, CVEs, MITRE ATT&CK, and threat-intelligence concepts |
| [Lab 12 Build Layers](phase_1/lab_12b/terraform/build-layers.md) | Manual ReportLab layer build steps for Lab 12b |
| [Lab 12c Build Layers](phase_1/lab_12c/terraform/build-layers.md) | Manual ReportLab layer build steps for Lab 12c |
| [Lab 12d Build Layers](phase_2/lab_12d/terraform/build-layers.md) | Manual ReportLab layer build steps for Lab 12d |

Each phase lab also contains a `docs/` directory with architecture, deployment, security, cleanup, and troubleshooting placeholders for lab-specific notes.

## Terraform Deployment Components

Deployments use fixed file structures and numeric prefixes to identify infrastructure domains consistently across all deployment phases.

| Domain | Example File Structure |
| --- | --- |
| Runtime Code | `lambda/src/` |
| Scripts | `scripts/` |
| Inputs & Outputs | `variables.tf`, `locals.tf`, `outputs.tf` |
| **00 - 09**: Foundation (Providers, Backend, Helpers) | `00-providers.tf`, `01-backend.tf`, `02-helper-resources.tf`, `03-helper-data.tf` |
| **10 - 19**: Identity & Access Management (IAM) | `10-iam-policies.tf`, `11-iam-roles.tf` |
| **20 - 29**: Identity (User Management & Authentication) | `20-cognito.tf` |
| **30 - 39**: API Management | `30-api-gateway.tf` |
| **40 - 49**: Storage | `40-s3.tf` |
| **50 - 59**: Data | `50-dynamodb.tf` |
| **60 - 69**: Compute | `60-lambda.tf` |
| **70 - 79**: Security | `70-waf.tf` |
| **80 - 89**: Eventing | `80-eventbridge.tf`, `81-sns.tf` |
| **90 - 99**: Observability | `90-cloudwatch-logs.tf`, `91-metrics-and-alarms.tf` |


## Lambda Agents

The Lambda source is organized into one folder per function under each lab's `terraform/lambda/src/` directory. Later labs include all earlier agents plus the newly introduced capability.

| Agent | Introduced In | Purpose |
| --- | --- | --- |
| `jedi_python` | Lab 12 | Python protected-route handler |
| `sith_node` | Lab 12 | Node.js protected-route handler |
| `unused_token_detector` | Lab 12 | Token-use detection workflow |
| `waf_bedrock_analyzer` | Lab 12 | Bedrock-assisted WAF analysis |
| `waf_threat_correlation_agent` | Lab 12 | WAF finding correlation |
| `soar_response_agent` | Lab 12a | SOAR incident creation and notification workflow |
| `executive_dashboard_agent` | Lab 12b | Executive security report generation |
| `compliance_agent` | Lab 12c | Compliance evidence report generation |
| `threat_intelligence_agent` | Lab 12d | Threat-intelligence enrichment and reporting work in progress |

Many Lambda folders include `test_events/` files for direct Lambda testing.

## Getting Started

Choose a lab, copy its Terraform variables example, then initialize Terraform from that lab's root module.

```bash
cd phase_1/lab_12
cp terraform/terraform-tfvars.example terraform/terraform.tfvars
cd terraform
terraform init
terraform validate
terraform plan
```

Edit `terraform.tfvars` before applying. Do not commit real passwords, account IDs, secrets, state files, or environment files.

Labs with PDF reporting functions require the ReportLab Lambda layer before deployment:

| Lab | Layer Instructions |
| --- | --- |
| Lab 12b | [phase_1/lab_12b/terraform/build-layers.md](phase_1/lab_12b/terraform/build-layers.md) |
| Lab 12c | [phase_1/lab_12c/terraform/build-layers.md](phase_1/lab_12c/terraform/build-layers.md) |
| Lab 12d | [phase_2/lab_12d/terraform/build-layers.md](phase_2/lab_12d/terraform/build-layers.md) |

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create the documented services and IAM resources
- Python 3 for helper scripts and Lambda layer builds
- AWS Bedrock model access for labs that invoke Bedrock
- An email address if SNS alert subscriptions are enabled

Use [enable_model/aws-enable-anthropic-model.sh](enable_model/aws-enable-anthropic-model.sh) when you need the repository helper for Anthropic model access setup.


## Operating Notes

Use separate Terraform state keys and resource names when running multiple labs in the same AWS account and Region. The backend files are lab-specific, and the variables default to the `bedrock-serverless` application name with a `dev` environment.

The reporting Lambdas use Python 3.12 and a ReportLab Lambda layer. The core analysis and response agents use Python 3.14 unless the lab-specific Terraform declares otherwise.

Follow [internal/CONTRIBUTING.md](internal/CONTRIBUTING.md) before opening a pull request, especially the guidance on secrets, Terraform state, validation evidence, and cleanup instructions.
>>>>>>> d58e1ea (Updated root README.md)
