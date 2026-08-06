# Class 7.5 Armageddon - TKO Group Submission

Progressive series of production-oriented serverless AWS architectures showcasing secure application development, cloud security automation, advanced threat intelligence, security incident reporting, and AI-powered security response agents. Built with Cognito, API Gateway, Lambda, AWS WAF, Bedrock, DynamoDB, EventBridge, CloudWatch, SNS, and S3.

---

## Quick Links
- [Group Submission - Phase 1](./main/phase-1/)
- [Participant Submissions](./members/)
- [Participant Branches](https://github.com/jdpayne68/class-7-tko-group-armageddon-2/branches)
- [Repository structure](./repository-structure.md)


## Lab Progression

### Phase 1

Core security pipeline: detect WAF activity, correlate findings, automate response, and generate reports.

| Path | Description |
| --- | --- |
| [Lab 12](phase_1/lab_12/README.md) | Builds the baseline WAF detection pipeline with Bedrock-assisted log analysis, correlated findings, and security evidence capture |
| [Lab 12a](phase_1/lab_12a/README.md) | Extends WAF findings into a SOAR workflow that creates incidents, formats analyst summaries, and sends notifications |
| [Lab 12b](phase_1/lab_12b/README.md) | Adds executive reporting that converts security incidents into PDF and JSON artifacts stored for review |
| [Lab 12c](phase_1/lab_12c/README.md) | Adds compliance reporting that maps security activity to controls and produces evidence-ready report artifacts |

### Phase 2

Threat-intelligence expansion: add provider context, fused risk scoring, and enrichment artifacts.

| Path | Description |
| --- | --- |
| [Lab 12d](phase_2/lab_12d/README.md) | Expands the incident pipeline with provider-based threat intelligence, fused risk scoring, and enrichment reports |

> [!NOTE]
> Lab 12d is IN PROGRESS. Work in this directory is not yet finalized.

## Documentation

| Document | Use |
| --- | --- |
| [Repository Structure](repository-structure.md) | Repository map and intended lab progression |
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

The Lambda source is organized into one folder per function in each lab's `terraform/lambda/src/` directory.

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

## Deployment Instructions

Choose the lab you want to deploy, then run Terraform from that lab's `terraform/` root module. The Terraform files and example inputs are already included in each lab.

> [!IMPORTANT]
> `terraform apply` creates AWS resources. Confirm your AWS profile, Region, variables, and expected cost before applying a lab.

```bash
cd phase_1/lab_12/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Review the lab's `terraform-tfvars.example` and variable definitions before applying. Do not commit real passwords, account IDs, secrets, state files, or environment files.

> [!TIP]
> Build the ReportLab layer before `terraform plan` or `terraform apply` for reporting labs so Terraform can package the layer artifact.

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

> [!NOTE]
> Bedrock model access must be enabled in the target AWS account and Region before Bedrock-backed agents can invoke Anthropic models. Use [enable_model/aws-enable-anthropic-model.sh](enable_model/aws-enable-anthropic-model.sh) when you need the repository helper for Anthropic model access setup.


## Operating Notes

> [!NOTE]
> Labs are designed for flexible parallel deployment. The Terraform code uses lab-specific backends, variable naming prefixes, and random suffixes to reduce naming collisions across multiple deployments.

Multiple labs can be deployed in the same AWS account and Region when their Terraform state remains isolated. The variables default to the `bedrock-serverless` application name with a `dev` environment, while generated suffixes keep resource names unique.

The reporting Lambdas use Python 3.12 and a ReportLab Lambda layer. The core analysis and response agents use Python 3.14 unless the lab-specific Terraform declares otherwise.
