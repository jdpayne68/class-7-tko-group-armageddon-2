# Phase 1 - Serverless Security Pipeline

Phase 1 builds the core security pipeline for the project: detect WAF activity, correlate findings, automate response, and generate executive and compliance reports. Each lab keeps the same Terraform structure and adds one capability layer at a time.

[Back to repository README](../README.md) | [Phase 2](../phase_2/README.md) | [Repository Structure](../repository-structure.md)

---

## Quick Links

- [Lab 12 - WAF Threat Correlation](lab_12/README.md)
- [Lab 12a - SOAR Response](lab_12a/README.md)
- [Lab 12b - Executive Reporting](lab_12b/README.md)
- [Lab 12c - Compliance Reporting](lab_12c/README.md)

## Lab Progression

| Path | Description |
| --- | --- |
| [Lab 12](lab_12/README.md) | Builds the baseline WAF detection pipeline with Bedrock-assisted log analysis, correlated findings, and security evidence capture |
| [Lab 12a](lab_12a/README.md) | Extends WAF findings into a SOAR workflow that creates incidents, formats analyst summaries, and sends notifications |
| [Lab 12b](lab_12b/README.md) | Adds executive reporting that converts security incidents into PDF and JSON artifacts stored for review |
| [Lab 12c](lab_12c/README.md) | Adds compliance reporting that maps security activity to controls and produces evidence-ready report artifacts |

## Architecture Path

| Stage | Added Capability |
| --- | --- |
| Lab 12 | Cognito, API Gateway, Lambda, AWS WAF, Bedrock analysis, DynamoDB findings, EventBridge schedules, CloudWatch logs, and SNS token alerts |
| Lab 12a | SOAR incident creation, deterministic playbook selection, EventBridge routing, and analyst notification flow |
| Lab 12b | Executive report generation, S3 report artifacts, and the ReportLab Lambda layer |
| Lab 12c | Compliance evidence mapping, compliance report artifacts, controls metadata, and compliance-focused reporting |

## Deployment Instructions

Choose the lab you want to deploy, then run Terraform from that lab's `terraform/` root module.

```bash
cd lab_12/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

> [!IMPORTANT]
> `terraform apply` creates AWS resources. Confirm your AWS profile, Region, variables, and expected cost before applying a lab.

Labs with PDF reporting functions require the ReportLab Lambda layer before deployment:

| Lab | Layer Instructions |
| --- | --- |
| Lab 12b | [lab_12b/terraform/docs/build-layers.md](lab_12b/terraform/docs/build-layers.md) |
| Lab 12c | [lab_12c/terraform/docs/build-layers.md](lab_12c/terraform/docs/build-layers.md) |

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create the documented services and IAM resources
- Python 3 for helper scripts and Lambda layer builds
- AWS Bedrock model access for labs that invoke Bedrock
- An email address if SNS alert subscriptions are enabled

> [!NOTE]
> Labs are designed for flexible parallel deployment. The Terraform code uses lab-specific backends, variable naming prefixes, and random suffixes to reduce naming collisions across multiple deployments.

## Documentation

| Document | Use |
| --- | --- |
| [Repository README](../README.md) | Main repository navigation and shared deployment notes |
| [Repository Structure](../repository-structure.md) | Repository map and intended lab progression |
| [Internal Contributing Guide](../internal/CONTRIBUTING.md) | Contribution, validation, and safety expectations |
| [Lab 12 Build Layers](lab_12b/terraform/docs/build-layers.md) | Manual ReportLab layer build steps for Lab 12b |
| [Lab 12c Build Layers](lab_12c/terraform/docs/build-layers.md) | Manual ReportLab layer build steps for Lab 12c |

## Operating Notes

Deploy labs in order when learning the architecture. Deploy a later lab directly when you want the full stack for that phase, since later labs include the earlier Terraform and Lambda patterns plus the newly introduced capability.
