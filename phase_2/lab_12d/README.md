# Lab 12d - Threat Intelligence Enrichment

Lab 12d expands the security pipeline with provider-based threat intelligence, fused risk scoring, and enrichment artifacts. This lab is still in progress and should be treated as the active integration area for the threat-intelligence agents.

[Back to repository README](../../README.md) | [Phase 2](../README.md) | [Previous: Lab 12c](../../phase_1/lab_12c/README.md)

---

## Overview

This lab builds on Lab 12c and adds a threat-intelligence event contract, provider registry, enrichment agent, and report generation path. The goal is to enrich SOAR incidents with external intelligence while keeping provider integrations modular and testable.

| Objective | Outcome |
| --- | --- |
| Add threat-intelligence enrichment | SOAR events can trigger provider-based context gathering |
| Normalize provider output | Provider responses are shaped into a shared event/report contract |
| Fuse risk context | Enrichment data supports a combined operational risk view |
| Preserve artifacts | Threat-intelligence reports are stored for review and follow-on analysis |

> [!NOTE]
> Lab 12d is IN PROGRESS. Terraform additions are currently staged in `terraform/new-code.tf` while the integration is being finalized.

## Architecture Summary

| Component | Purpose |
| --- | --- |
| Lab 12c Security Pipeline | Supplies findings, incidents, executive reports, and compliance reports |
| Threat Intelligence Agent | Enriches SOAR events with external provider context |
| Provider Registry | Keeps provider integrations modular and easier to extend |
| Provider Modules | Implement AbuseIPDB, CISA KEV, and MITRE ATT&CK enrichment logic |
| Fusion Logic | Combines provider outputs into a concise risk assessment |
| S3 and DynamoDB | Store threat-intelligence report artifacts and structured enrichment records |
| EventBridge | Routes successful SOAR response events into threat-intelligence enrichment |

## Directory Structure

```text
lab_12d/
├── requirements.txt
└── terraform/
    ├── build-layers.md
    ├── new-code.tf
    ├── terraform-changes.md
    ├── lambda/src/threat_intelligence_agent/
    ├── lambda/src/soar_response_agent/
    ├── scripts/build-layers.sh
    └── *.tf
```

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create IAM, Lambda, Lambda layers, S3, DynamoDB, EventBridge, SNS, WAF, Cognito, API Gateway, CloudWatch, and Bedrock resources
- Python 3 for helper scripts and Lambda layer preparation
- Bedrock model access enabled in the target AWS account and Region
- Threat-intelligence provider configuration where required

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
> Build the reporting layer before Terraform so the executive, compliance, and threat-intelligence reporting paths have the expected package structure available at deploy time.

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

Terraform deploys the inherited Lab 12c stack plus any active Lab 12d resources. Because Lab 12d is in progress, inspect `terraform/new-code.tf` and `terraform/terraform-changes.md` before applying.

### Optional Script-Assisted Workflow

```bash
cd terraform
scripts/build-layers.sh
python scripts/get-token.py
scripts/test-malicious-waf-traffic.sh
```

The layer script prepares reporting dependencies. The token and traffic scripts support authenticated testing and controlled WAF event generation so enrichment can be tested from realistic upstream events.

## Validation Steps

1. Confirm the inherited stack outputs are present:

```bash
terraform output lambda_function_names
terraform output dynamodb_table_names
terraform output report_bucket_names
```

2. Confirm any Lab 12d-specific outputs from `terraform/new-code.tf` are present after deployment.
3. Generate WAF activity and confirm SOAR response completes successfully.
4. Confirm the threat-intelligence agent receives the SOAR event contract.
5. Check the threat-intelligence report table and report bucket for enrichment artifacts.
6. Review the threat-intelligence Lambda logs for provider responses, fallback behavior, and fused risk scoring.
7. Use `terraform/lambda/src/threat_intelligence_agent/test_events/threat-intelligence-test.json` for direct Lambda testing.

## Cleanup

```bash
cd terraform
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

> [!WARNING]
> Preserve generated reports before cleanup. Report buckets and DynamoDB tables are part of the Terraform-managed lab state.

## Troubleshooting

| Issue | Check |
| --- | --- |
| No threat-intelligence report appears | Confirm the SOAR response event is emitted and the EventBridge rule target is active |
| Provider data is missing | Confirm enabled providers, API credentials, timeout handling, and provider logs |
| AbuseIPDB is skipped | The current implementation keeps AbuseIPDB placeholder handling until secure key storage is added |
| Report dependency import error | Rebuild the layer with `terraform/scripts/build-layers.sh` and redeploy |
| Terraform does not include Lab 12d resources | Confirm `terraform/new-code.tf` is present and included in the root module |

## References

- [Repository README](../../README.md)
- [Previous Lab: Compliance Reporting](../../phase_1/lab_12c/README.md)
- [Security Intelligence Foundations](../../internal/security-intelligence-foundations.md)
- [ReportLab Layer Build Notes](terraform/build-layers.md)
- [Terraform Change Notes](terraform/terraform-changes.md)
- [Threat Intelligence Agent Notes](terraform/lambda/src/threat_intelligence_agent/agent-changes.md)
- [Threat Intelligence Event Contract](terraform/lambda/src/threat_intelligence_agent/event-contract.md)
- [Provider Module Notes](terraform/lambda/src/threat_intelligence_agent/providers/providers-changes.md)
