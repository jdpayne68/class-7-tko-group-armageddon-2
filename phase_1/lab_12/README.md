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

`terraform/terraform-tfvars.example` is the deployment template. Copy or rename it to a local `.tfvars` file, fill in your values, and pass that file to Terraform. The Imposter Syndrome workflow expects `terraform/chewbacca.tfvars` by default.

## Deployment Runbook

### Manual Deployment

Run Terraform from the lab root module:

```bash
cd terraform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=chewbacca.tfvars -out=chewbacca.tfplan
terraform apply chewbacca.tfplan
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

For the skill scanner and guided Terraform workflow, see [Imposter Syndrome Defense](terraform/scripts/imposter_syndrome/README.md).

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

### Project

- [Repository README](../../README.md)
- [Repository Structure](../../repository-structure.md)
- [Imposter Syndrome Defense](terraform/scripts/imposter_syndrome/README.md)
- [Lab Architecture Notes](docs/architecture.md)
- [Deployment Guide Notes](docs/deployment-guide.md)
- [Security Design Notes](docs/security-design.md)
- [Cleanup Notes](docs/cleanup.md)
- [Troubleshooting Notes](docs/troubleshooting.md)

### Terraform

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- [Terraform CLI: `init`](https://developer.hashicorp.com/terraform/cli/commands/init)
- [Terraform CLI: `fmt`](https://developer.hashicorp.com/terraform/cli/commands/fmt)
- [Terraform CLI: `validate`](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [Terraform CLI: `plan`](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [Terraform CLI: `apply`](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Terraform CLI: `destroy`](https://developer.hashicorp.com/terraform/cli/commands/destroy)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)

### AWS

- [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- [AWS Identity and Access Management User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)
- [IAM Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Amazon Cognito Developer Guide](https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html)
- [Amazon API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [AWS Lambda Python Handler Documentation](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html)
- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html)
- [Amazon CloudWatch Logs User Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [Amazon EventBridge Scheduler User Guide](https://docs.aws.amazon.com/scheduler/latest/UserGuide/what-is-scheduler.html)
- [Amazon SNS Developer Guide](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html)

### Python, Git, And GitHub

- [Python Documentation](https://docs.python.org/3/)
- [`venv` - Creation Of Virtual Environments](https://docs.python.org/3/library/venv.html)
- [Python Packaging: Installing Packages Using Virtual Environments](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [pip User Guide](https://pip.pypa.io/en/stable/user_guide/)
- [Git Documentation](https://git-scm.com/docs)
- [GitHub Documentation: Repositories](https://docs.github.com/en/repositories)
