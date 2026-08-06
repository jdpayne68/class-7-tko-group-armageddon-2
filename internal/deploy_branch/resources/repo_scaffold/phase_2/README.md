# Phase 2 - Threat Intelligence Expansion

Phase 2 extends the Phase 1 security pipeline with threat-intelligence enrichment, provider context, fused risk scoring, and enrichment artifacts. This phase is the active integration area for the Lab 12d intelligence agents.

[Back to repository README](../README.md) | [Phase 1](../phase_1/README.md) | [Repository Structure](../repository-structure.md)

---

## Quick Links

- [Lab 12d - Threat Intelligence Enrichment](lab_12d/README.md)
- [Security Intelligence Foundations](../internal/security-intelligence-foundations.md)
- [Lab 12d Build Layers](lab_12d/terraform/docs/build-layers.md)
- [Lab 12d Terraform Change Notes](lab_12d/terraform/terraform-changes.md)

## Lab Progression

| Path | Description |
| --- | --- |
| [Lab 12d](lab_12d/README.md) | Expands the incident pipeline with provider-based threat intelligence, fused risk scoring, and enrichment reports |

> [!NOTE]
> Lab 12d is IN PROGRESS. Work in this directory is not yet finalized.

## Architecture Path

| Stage | Added Capability |
| --- | --- |
| Lab 12d | Threat-intelligence event contract, provider registry, AbuseIPDB, CISA KEV, MITRE ATT&CK context, fused risk scoring, and enrichment artifacts |

## Deployment Instructions

Run Terraform from the Lab 12d `terraform/` root module after building the ReportLab layer.

```bash
cd lab_12d/terraform
scripts/build-layers.sh
terraform init
terraform validate
terraform plan
terraform apply
```

> [!IMPORTANT]
> Because Lab 12d is in progress, inspect [lab_12d/terraform/new-code.tf](lab_12d/terraform/new-code.tf) and [lab_12d/terraform/terraform-changes.md](lab_12d/terraform/terraform-changes.md) before applying.

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI credentials with permission to create the documented services and IAM resources
- Python 3 for helper scripts and Lambda layer builds
- AWS Bedrock model access for agents that invoke Bedrock
- Threat-intelligence provider configuration where required

## Documentation

| Document | Use |
| --- | --- |
| [Repository README](../README.md) | Main repository navigation and shared deployment notes |
| [Phase 1 README](../phase_1/README.md) | Prior security pipeline stages that Lab 12d builds on |
| [Security Intelligence Foundations](../internal/security-intelligence-foundations.md) | Background reference for AbuseIPDB, CISA KEV, CVEs, MITRE ATT&CK, and intelligence concepts |
| [Lab 12d README](lab_12d/README.md) | Lab-specific deployment, validation, cleanup, and troubleshooting notes |
| [Lab 12d Build Layers](lab_12d/terraform/docs/build-layers.md) | Manual ReportLab layer build steps for Lab 12d |
| [Lab 12d Terraform Change Notes](lab_12d/terraform/terraform-changes.md) | Implementation notes for current Lab 12d Terraform additions |

## Operating Notes

Use Phase 2 when you want to test enrichment after the SOAR and reporting workflow exists. The threat-intelligence agent is designed to support human investigation, not automatic containment.
