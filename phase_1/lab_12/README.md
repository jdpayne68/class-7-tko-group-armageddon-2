# Lab 12 - WAF Threat Correlation

Lab 12 builds the baseline security pipeline for the project. It deploys protected API routes, captures WAF activity, analyzes suspicious requests with Bedrock, and stores correlated threat findings for later response workflows.

[Back to repository README](../../README.md) | [Phase 1](../README.md) | [Next: Lab 12a](../lab_12a/README.md)

---

## Overview

This lab establishes the first production-oriented security loop: application traffic is protected by Cognito, inspected by AWS WAF, processed by Lambda agents, and persisted in DynamoDB for analysis.

| Objective | Outcome |
| --- | --- |
| Deploy protected API routes | Cognito-authorized Jedi and Sith Lambda endpoints behind API Gateway |
| Capture WAF activity | WAF logs are stored in CloudWatch Logs and processed on a schedule |
| Analyze suspicious traffic | Bedrock-assisted analysis summarizes WAF events |
| Correlate findings | Related WAF events are grouped into durable DynamoDB findings |

> [!NOTE]
> This lab is the foundation for the later SOAR, reporting, compliance, and threat-intelligence labs.

## Architecture Summary

| Component | Purpose |
| --- | --- |
| Cognito | Provides user pool authentication for protected routes |
| API Gateway | Exposes the `/jedi`, `/sith`, and `/analyze` routes |
| AWS WAF | Detects and blocks suspicious requests before they reach the backend |
| Lambda | Runs route handlers, token checks, WAF analysis, and threat correlation |
| DynamoDB | Stores token, WAF event, and correlation finding records |
| EventBridge Scheduler | Invokes recurring analysis and correlation workflows |
| CloudWatch Logs | Stores Lambda, API Gateway, and WAF logs |
| SNS | Sends token-related operational alerts |

## Directory Structure

```text
lab_12/
├── docs/
├── evidence/
├── requirements.txt
└── terraform/
    ├── lambda/src/
    ├── scripts/
    ├── terraform-tfvars.example
    └── *.tf
```

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create IAM, Lambda, API Gateway, Cognito, WAF, DynamoDB, EventBridge, CloudWatch, SNS, and S3 resources
- Python 3 for helper scripts
- Bedrock model access enabled in the target AWS account and Region

Create and activate the local Python environment from the lab root:

```bash
python3 -m venv .
source bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

> [!IMPORTANT]
> No Lambda layer is required for Lab 12. The ReportLab layer starts in Lab 12b when PDF report generation is introduced.

Review `terraform/terraform-tfvars.example` before deployment. If your environment needs different values, create a local `terraform/terraform.tfvars` file or pass variables through your normal Terraform workflow.

## Deployment Runbook

### Manual Deployment

Run Terraform from the lab root module:

```bash
cd terraform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

`terraform init` prepares the backend and providers. `terraform validate` catches configuration issues before AWS API calls. `terraform plan` shows exactly what will be created before `terraform apply` deploys the lab.

### Optional Script-Assisted Workflow

After Terraform deploys the infrastructure, the helper scripts reduce manual testing work:

```bash
cd terraform
python scripts/get-token.py
scripts/test-malicious-waf-traffic.sh
```

`get-token.py` retrieves Cognito tokens for API testing. `test-malicious-waf-traffic.sh` sends controlled WAF-triggering requests so the analysis and correlation pipeline has events to process.

> [!TIP]
> Use `terraform output test_commands` for generated commands that match the deployed API Gateway URL and CloudWatch log group names.

## Validation Steps

1. Confirm Terraform outputs are available:

```bash
terraform output
terraform output lambda_function_names
terraform output dynamodb_table_names
terraform output test_commands
```

2. Generate WAF test traffic with `terraform/scripts/test-malicious-waf-traffic.sh`.
3. Check WAF logs with the `check_waf_logs` command from `terraform output test_commands`.
4. Inspect the WAF event and correlation DynamoDB tables from `terraform output dynamodb_table_names`.
5. Review Lambda logs from `terraform output cloudwatch_log_groups`.
6. Use the Lambda test events in `terraform/lambda/src/*/test_events/` for direct function testing.

## Cleanup

Destroy the lab from the Terraform root module:

```bash
cd terraform
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

> [!WARNING]
> If Terraform reports that an S3 bucket is not empty, remove generated test artifacts from that bucket before retrying destroy.

## Troubleshooting

| Issue | Check |
| --- | --- |
| Bedrock access denied | Confirm model access is enabled in the same AWS Region used by Terraform |
| WAF logs are empty | Generate traffic with `test-malicious-waf-traffic.sh` and confirm the API URL is current |
| Cognito token script fails | Confirm the Cognito outputs and user variables match the deployed lab |
| Correlation findings do not appear | Check EventBridge Scheduler status and Lambda logs for the WAF analyzer and correlation agent |

## References

- [Repository README](../../README.md)
- [Repository Structure](../../repository-structure.md)
- [Lab Architecture Notes](docs/architecture.md)
- [Deployment Guide Notes](docs/deployment-guide.md)
- [Security Design Notes](docs/security-design.md)
- [Cleanup Notes](docs/cleanup.md)
- [Troubleshooting Notes](docs/troubleshooting.md)
