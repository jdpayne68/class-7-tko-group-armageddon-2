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

### Project

- [Repository README](../../README.md)
- [Previous Lab: Compliance Reporting](../../phase_1/lab_12c/README.md)
- [Security Intelligence Foundations](../../internal/security-intelligence-foundations.md)
- [ReportLab Layer Build Notes](terraform/build-layers.md)
- [Terraform Change Notes](terraform/terraform-changes.md)
- [Threat Intelligence Agent Notes](terraform/lambda/src/threat_intelligence_agent/agent-changes.md)
- [Threat Intelligence Event Contract](terraform/lambda/src/threat_intelligence_agent/event-contract.md)
- [Provider Module Notes](terraform/lambda/src/threat_intelligence_agent/providers/providers-changes.md)

### Terraform

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- [Terraform CLI: `init`](https://developer.hashicorp.com/terraform/cli/commands/init)
- [Terraform CLI: `validate`](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [Terraform CLI: `plan`](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [Terraform CLI: `apply`](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform `aws_lambda_function`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [Terraform `aws_lambda_layer_version`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version)
- [Terraform `aws_cloudwatch_event_rule`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)
- [Terraform `aws_dynamodb_table`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table)
- [Terraform `aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

### AWS

- [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)
- [IAM Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [AWS Lambda Python Handler Documentation](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html)
- [AWS Lambda Python Deployment Packages](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)
- [Working With Layers For Python Lambda Functions](https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html)
- [Amazon EventBridge User Guide](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html)
- [Amazon EventBridge Event Patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
- [Amazon EventBridge `PutEvents` API](https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_PutEvents.html)
- [Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html)
- [AWS Secrets Manager User Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Security Incident Response Guide](https://docs.aws.amazon.com/whitepapers/latest/aws-security-incident-response-guide/welcome.html)
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html)

### Threat Intelligence And Vulnerability Intelligence

- [AbuseIPDB APIv2 Documentation](https://docs.abuseipdb.com/)
- [AbuseIPDB API Documentation](https://www.abuseipdb.com/api.html)
- [AbuseIPDB Pricing And Plan Limits](https://www.abuseipdb.com/pricing)
- [CISA Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [CISA KEV JSON Feed](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)
- [CVE Program FAQ](https://www.cve.org/ResourcesSupport/FAQs)
- [CVE Numbering Authorities](https://www.cve.org/programorganization/cnas)
- [CVE Program Structure](https://www.cve.org/ProgramOrganization/Structure)
- [CVE Services](https://www.cve.org/AllResources/CveServices)
- [NVD Vulnerability Metrics](https://nvd.nist.gov/vuln-metrics)
- [NVD CVE FAQ](https://nvd.nist.gov/general/FAQ-Sections/CVE-FAQs)
- [FIRST CVSS v4.0 Specification](https://www.first.org/cvss/v4.0/specification-document)

### MITRE ATT&CK

- [ATT&CK Resources And Overview](https://attack.mitre.org/resources/)
- [Enterprise Tactics](https://attack.mitre.org/tactics/)
- [Enterprise Techniques](https://attack.mitre.org/techniques/)
- [ATT&CK Data And Tools](https://attack.mitre.org/resources/attack-data-and-tools/)
- [ATT&CK Data Model](https://mitre-attack.github.io/attack-data-model/)

### Python, Reporting, Git, And GitHub

- [Python Documentation](https://docs.python.org/3/)
- [`venv` - Creation Of Virtual Environments](https://docs.python.org/3/library/venv.html)
- [Python Packaging: Installing Packages Using Virtual Environments](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [pip User Guide](https://pip.pypa.io/en/stable/user_guide/)
- [ReportLab User Guide](https://docs.reportlab.com/reportlab/userguide/ch1_intro/)
- [Git Documentation](https://git-scm.com/docs)
- [GitHub Documentation: Repositories](https://docs.github.com/en/repositories)
