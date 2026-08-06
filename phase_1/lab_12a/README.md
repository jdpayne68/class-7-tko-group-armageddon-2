# Lab 12a - SOAR Response

Lab 12a extends the WAF threat-correlation pipeline with a SOAR response agent. It creates security incidents from correlated findings, selects deterministic response playbooks, formats analyst summaries, and sends notifications for human review.

[Back to repository README](../../README.md) | [Previous: Lab 12](../lab_12/README.md) | [Next: Lab 12b](../lab_12b/README.md)

---

## Overview

This lab keeps the Lab 12 detection pipeline and adds incident response orchestration. EventBridge routes qualifying findings into the SOAR Lambda, which records incidents in DynamoDB and publishes operational notifications through SNS.

| Objective | Outcome |
| --- | --- |
| Convert findings into incidents | Correlated WAF findings become durable incident records |
| Keep playbook selection deterministic | Severity maps to response behavior without model authorization |
| Notify analysts | SNS messages provide email-friendly incident context |
| Preserve human review | The workflow does not perform destructive containment |

## Architecture Summary

| Component | Purpose |
| --- | --- |
| Lab 12 Detection Stack | Supplies WAF events and correlated findings |
| EventBridge Rules | Route medium, high, and critical findings to SOAR response |
| SOAR Response Lambda | Creates incidents, selects playbooks, and prepares analyst summaries |
| DynamoDB | Stores correlation findings and security incidents |
| SNS | Sends analyst notifications for playbooks that require notification |
| CloudWatch Logs | Captures execution logs for troubleshooting and audit review |

## Directory Structure

```text
lab_12a/
├── docs/
├── evidence/
├── requirements.txt
└── terraform/
    ├── lambda/src/soar_response_agent/
    ├── scripts/
    ├── terraform-tfvars.example
    └── *.tf
```

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create IAM, Lambda, EventBridge, DynamoDB, SNS, WAF, Cognito, API Gateway, CloudWatch, and S3 resources
- Python 3 for helper scripts
- Bedrock model access enabled in the target AWS account and Region
- An email address if SNS incident notifications are enabled

Create and activate the local Python environment from the lab root:

```bash
python3 -m venv .
source bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

> [!IMPORTANT]
> No Lambda layer is required for Lab 12a. The SOAR agent uses the runtime and AWS SDK available to the deployed Lambda environment.

Review `terraform/terraform-tfvars.example` before deployment. Keep passwords, account identifiers, and alert addresses out of version control.

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

Terraform deploys the base API and WAF pipeline, then adds the SOAR resources that listen for correlated findings. Reviewing the plan is important because this lab introduces additional IAM permissions, DynamoDB tables, EventBridge rules, and SNS notifications.

### Optional Script-Assisted Workflow

After deployment, use the included scripts to authenticate and generate test traffic:

```bash
cd terraform
python scripts/get-token.py
scripts/test-malicious-waf-traffic.sh
```

The token helper streamlines authenticated API testing. The WAF traffic script generates enough controlled security events for the correlation and SOAR flow without relying on manual curl loops.

## Validation Steps

1. Confirm the SOAR Lambda and incident table are present:

```bash
terraform output lambda_function_names
terraform output dynamodb_table_names
terraform output eventbridge
terraform output sns_topic_arns
```

2. Generate WAF traffic with `terraform/scripts/test-malicious-waf-traffic.sh`.
3. Confirm correlation findings are created in the WAF correlation table.
4. Confirm SOAR incidents are created in the security incidents table.
5. Check SNS email delivery if incident notification subscriptions are configured.
6. Review the SOAR Lambda log group from `terraform output cloudwatch_log_groups`.
7. Use `terraform/lambda/src/soar_response_agent/test_events/soar-response-test.json` for direct Lambda testing.

## Cleanup

```bash
cd terraform
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

> [!WARNING]
> Confirm you no longer need generated incident records before destroying the lab. DynamoDB tables are removed with the Terraform stack.

## Troubleshooting

| Issue | Check |
| --- | --- |
| No incident was created | Confirm the finding severity matches the EventBridge rules and the finding status has not already been processed |
| No SNS email arrived | Confirm the subscription is confirmed and the selected playbook requires notification |
| SOAR summary falls back | Check Bedrock access, model ID, Lambda timeout, and CloudWatch logs |
| Duplicate processing behavior | Confirm the finding status and deterministic incident ID logic in the SOAR agent |

## References

- [Repository README](../../README.md)
- [Previous Lab: WAF Threat Correlation](../lab_12/README.md)
- [Next Lab: Executive Reporting](../lab_12b/README.md)
- [Lab Architecture Notes](docs/architecture.md)
- [Deployment Guide Notes](docs/deployment-guide.md)
- [Security Design Notes](docs/security-design.md)
- [Cleanup Notes](docs/cleanup.md)
- [Troubleshooting Notes](docs/troubleshooting.md)
