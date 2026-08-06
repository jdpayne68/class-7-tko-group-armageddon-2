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
    ├── docs/build-layers.md
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

For manual layer details, see [terraform/docs/build-layers.md](terraform/docs/build-layers.md).

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

### Project

- [Repository README](../../README.md)
- [Previous Lab: Executive Reporting](../lab_12b/README.md)
- [Next Lab: Threat Intelligence](../../phase_2/lab_12d/README.md)
- [ReportLab Layer Build Notes](terraform/docs/build-layers.md)
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
- [Terraform CLI: `validate`](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [Terraform CLI: `plan`](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [Terraform CLI: `apply`](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform `aws_lambda_layer_version`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version)
- [Terraform `aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Terraform `aws_dynamodb_table`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table)

### AWS

- [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)
- [IAM Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Working With Layers For Python Lambda Functions](https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html)
- [AWS Lambda Python Deployment Packages](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)
- [Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [Amazon EventBridge User Guide](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html)
- [AWS Security Incident Response Guide](https://docs.aws.amazon.com/whitepapers/latest/aws-security-incident-response-guide/welcome.html)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html)

### Compliance And Reporting

- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls v8](https://www.cisecurity.org/controls/v8)
- [AWS Audit Manager User Guide](https://docs.aws.amazon.com/audit-manager/latest/userguide/what-is.html)
- [ReportLab User Guide](https://docs.reportlab.com/reportlab/userguide/ch1_intro/)

### Python, Git, And GitHub

- [Python Documentation](https://docs.python.org/3/)
- [`venv` - Creation Of Virtual Environments](https://docs.python.org/3/library/venv.html)
- [Python Packaging: Installing Packages Using Virtual Environments](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [pip User Guide](https://pip.pypa.io/en/stable/user_guide/)
- [Git Documentation](https://git-scm.com/docs)
- [GitHub Documentation: Repositories](https://docs.github.com/en/repositories)
