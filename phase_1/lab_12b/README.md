# Lab 12b - Executive Reporting

Lab 12b adds executive reporting to the SOAR pipeline. It converts incident and finding data into PDF and JSON report artifacts stored in S3 for review, sharing, and evidence collection.

[Back to repository README](../../README.md) | [Previous: Lab 12a](../lab_12a/README.md) | [Next: Lab 12c](../lab_12c/README.md)

---

## Overview

This lab keeps the detection and SOAR workflows from Lab 12a and adds an executive dashboard agent. The reporting Lambda reads incident context, generates report artifacts, and writes them to the executive report bucket.

| Objective | Outcome |
| --- | --- |
| Generate executive reports | Security incidents become PDF and JSON artifacts |
| Preserve machine-readable output | JSON reports support review and downstream processing |
| Store reports centrally | S3 holds generated executive report artifacts |
| Add reporting dependencies safely | ReportLab is packaged as a Lambda layer before Terraform deployment |

## Architecture Summary

| Component | Purpose |
| --- | --- |
| Lab 12a SOAR Stack | Supplies incident records and analyst summaries |
| Executive Dashboard Lambda | Generates PDF and JSON executive reports |
| ReportLab Lambda Layer | Provides the PDF generation library used by the reporting Lambda |
| S3 Report Bucket | Stores generated report artifacts |
| DynamoDB | Provides incident and finding data used by reports |
| CloudWatch Logs | Captures report generation errors and execution details |

## Directory Structure

```text
lab_12b/
├── docs/
├── sample_output/
├── requirements.txt
└── terraform/
    ├── build-layers.md
    ├── lambda/src/executive_dashboard_agent/
    ├── scripts/build-layers.sh
    ├── scripts/get-token.py
    ├── scripts/test-malicious-waf-traffic.sh
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
> Terraform deploys the Lambda layer, but the local layer files must exist first. If the layer is missing, reporting Lambdas can deploy incorrectly or fail at import time.

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

The layer build prepares the dependency artifact. Terraform then deploys the API, WAF, SOAR, reporting Lambda, report bucket, permissions, schedules, and logs.

### Optional Script-Assisted Workflow

Use the helper scripts to reduce manual setup and testing:

```bash
cd terraform
scripts/build-layers.sh
python scripts/get-token.py
scripts/test-malicious-waf-traffic.sh
```

`build-layers.sh` prepares the PDF dependency layer. `get-token.py` supports authenticated API testing. `test-malicious-waf-traffic.sh` generates controlled WAF events that can flow into correlation, SOAR, and reporting.

## Validation Steps

1. Confirm Terraform outputs include the executive dashboard Lambda and report bucket:

```bash
terraform output lambda_function_names
terraform output report_bucket_names
terraform output cloudwatch_log_groups
```

2. Generate WAF traffic and allow the scheduled workflows to process events.
3. Confirm a SOAR incident exists in DynamoDB.
4. Invoke or trigger the executive dashboard agent after incident creation.
5. Check the executive report S3 bucket for PDF and JSON artifacts.
6. Review the executive dashboard CloudWatch log group if no report appears.
7. Use `terraform/lambda/src/executive_dashboard_agent/test_events/executive-dashboard-test.json` for direct Lambda testing.

## Cleanup

```bash
cd terraform
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

> [!WARNING]
> Empty generated report artifacts from S3 if Terraform cannot delete a non-empty report bucket.

## Troubleshooting

| Issue | Check |
| --- | --- |
| `No module named 'reportlab'` | Re-run `terraform/scripts/build-layers.sh`, then redeploy Terraform |
| `No module named 'boto3.docs'` | Confirm the layer build copied the complete boto3 and botocore package contents |
| No PDF appears in S3 | Check the executive dashboard Lambda logs and confirm a valid incident exists |
| Bedrock report generation fails | Confirm model access, model ID, Region, and Lambda timeout settings |

## References

- [Repository README](../../README.md)
- [Previous Lab: SOAR Response](../lab_12a/README.md)
- [Next Lab: Compliance Reporting](../lab_12c/README.md)
- [ReportLab Layer Build Notes](terraform/build-layers.md)
- [Lab Architecture Notes](docs/architecture.md)
- [Deployment Guide Notes](docs/deployment-guide.md)
- [Security Design Notes](docs/security-design.md)
- [Cleanup Notes](docs/cleanup.md)
- [Troubleshooting Notes](docs/troubleshooting.md)
