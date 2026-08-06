# Lab 12c - Compliance Reporting

Lab 12c adds compliance evidence reporting to the security pipeline. It maps incident and finding activity to control-oriented evidence, then stores generated compliance artifacts for audit and review workflows.

[Back to repository README](../../README.md) | [Previous: Lab 12b](../lab_12b/README.md) | [Next: Lab 12d](../../phase_2/lab_12d/README.md)

---

## Overview

This lab keeps the executive reporting pipeline from Lab 12b and adds a compliance agent with a controls file and compliance playbook. The result is a fuller security reporting workflow that supports both operational response and evidence-ready compliance review.

| Objective | Outcome |
| --- | --- |
| Generate compliance evidence | Security activity is mapped into compliance-focused report artifacts |
| Preserve control context | `controls.json` and the compliance playbook guide report structure |
| Store evidence artifacts | Compliance reports are written to the configured S3 bucket |
| Maintain report dependencies | ReportLab is packaged as a Lambda layer before Terraform deployment |

## Architecture Summary

| Component | Purpose |
| --- | --- |
| Lab 12b Reporting Stack | Supplies incidents, executive reports, and report storage patterns |
| Compliance Agent Lambda | Produces compliance evidence reports from security findings and incidents |
| Controls File | Provides local control metadata used by the Lambda at runtime |
| Compliance Playbook | Documents the agent's reporting intent and operating context |
| ReportLab Lambda Layer | Provides PDF generation dependencies for reporting Lambdas |
| DynamoDB and S3 | Store compliance evidence records and generated report artifacts |

## Directory Structure

```text
lab_12c/
├── docs/
├── sample_output/
├── requirements.txt
└── terraform/
    ├── build-layers.md
    ├── lambda/src/compliance_agent/
    ├── lambda/src/executive_dashboard_agent/
    ├── scripts/build-layers.sh
    └── *.tf
```

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create IAM, Lambda, Lambda layers, S3, DynamoDB, EventBridge, SNS, WAF, Cognito, API Gateway, and CloudWatch resources
- Python 3 for helper scripts and Lambda layer preparation
- Bedrock model access enabled in the target AWS account and Region

Create and activate the local Python environment from the lab root:

```bash
python3 -m venv .
source bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

Build the ReportLab Lambda layer before running Terraform:

```bash
cd terraform
scripts/build-layers.sh
cd ..
```

> [!IMPORTANT]
> The compliance and executive reporting Lambdas depend on the layer files created by `scripts/build-layers.sh`. Build the layer before `terraform plan` or `terraform apply`.

For manual layer details, see [terraform/build-layers.md](terraform/build-layers.md).

## Deployment Runbook

### Manual Deployment

```bash
cd terraform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform deploys the detection, SOAR, executive reporting, and compliance reporting resources as one lab stack. The generated suffixes help keep AWS resource names unique across multiple deployments.

### Optional Script-Assisted Workflow

```bash
cd terraform
scripts/build-layers.sh
python scripts/get-token.py
scripts/test-malicious-waf-traffic.sh
```

The layer script prepares report-generation dependencies. The token and traffic scripts help create authenticated requests and WAF events that can move through the reporting pipeline.

## Validation Steps

1. Confirm Terraform outputs include the compliance agent and report buckets:

```bash
terraform output lambda_function_names
terraform output dynamodb_table_names
terraform output report_bucket_names
```

2. Generate WAF activity and confirm correlation findings and SOAR incidents are created.
3. Trigger or test the executive and compliance report agents.
4. Check the compliance evidence table from `terraform output dynamodb_table_names`.
5. Check the compliance report bucket from `terraform output report_bucket_names`.
6. Review compliance agent logs from `terraform output cloudwatch_log_groups`.
7. Use `terraform/lambda/src/compliance_agent/test_events/compliance-test-event.json` for direct Lambda testing.

## Cleanup

```bash
cd terraform
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

> [!WARNING]
> Preserve required evidence artifacts before destroy. Terraform will remove the compliance evidence table and report bucket when cleanup completes.

## Troubleshooting

| Issue | Check |
| --- | --- |
| Compliance Lambda import error | Rebuild the ReportLab layer and redeploy Terraform |
| No compliance artifact appears | Confirm the source incident or finding exists and check the compliance Lambda logs |
| Missing controls data | Confirm `terraform/lambda/src/compliance_agent/controls.json` is packaged with the Lambda source |
| Report text is too generic | Review the compliance playbook and Bedrock model access settings |

## References

- [Repository README](../../README.md)
- [Previous Lab: Executive Reporting](../lab_12b/README.md)
- [Next Lab: Threat Intelligence](../../phase_2/lab_12d/README.md)
- [ReportLab Layer Build Notes](terraform/build-layers.md)
- [Lab Architecture Notes](docs/architecture.md)
- [Deployment Guide Notes](docs/deployment-guide.md)
- [Security Design Notes](docs/security-design.md)
- [Cleanup Notes](docs/cleanup.md)
- [Troubleshooting Notes](docs/troubleshooting.md)
