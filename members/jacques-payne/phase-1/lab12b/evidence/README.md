# Lab 12B Evidence Manifest

This directory contains engineering evidence for the standalone Lab 12B
executive security reporting workflow.

Evidence `01` through `13` preserves the inherited Lab 12A event-driven SOAR
baseline. Evidence `14` through `25` documents the Lab 12B executive reporting
extension, populated synthetic-data validation, no-drift result, teardown, and
post-destroy verification.

| Evidence | What it proves |
|---|---|
| [`01-terraform-plan-complete.png`](./01-terraform-plan-complete.png) | Inherited Lab 12A Terraform plan: 47 additions, zero changes, and zero destroys. |
| [`02-terraform-apply-complete.png`](./02-terraform-apply-complete.png) | Successful deployment of all 47 inherited Lab 12A resources. |
| [`03-sns-subscriptions-confirmed.png`](./03-sns-subscriptions-confirmed.png) | Both email subscriptions were confirmed for standard SOAR notifications and critical alerts. |
| [`04-eventbridge-rules-and-targets.png`](./04-eventbridge-rules-and-targets.png) | MEDIUM and HIGH findings route to SOAR; CRITICAL findings route to SOAR and critical-alert SNS. |
| [`05-high-severity-end-to-end-workflow.png`](./05-high-severity-end-to-end-workflow.png) | A HIGH finding created an incident, published SNS, and completed the finding workflow. |
| [`06-idempotent-retry-skipped.png`](./06-idempotent-retry-skipped.png) | A replayed completed finding was skipped and did not create a duplicate incident. |
| [`07-critical-soar-workflow.png`](./07-critical-soar-workflow.png) | A CRITICAL finding created a priority-1 incident while preserving the human-approval boundary. |
| [`08-critical-dual-sns-publication.png`](./08-critical-dual-sns-publication.png) | CloudWatch metrics confirm publication to both CRITICAL routing destinations. |
| [`09a-correlation-eventbridge-publication.png`](./09a-correlation-eventbridge-publication.png) | The correlation Lambda created a HIGH finding and published it to EventBridge. |
| [`09b-soar-incident-completion.png`](./09b-soar-incident-completion.png) | EventBridge invoked SOAR automatically, resulting in incident creation, notification, and workflow completion. |
| [`10-terraform-no-drift.png`](./10-terraform-no-drift.png) | Terraform reported no infrastructure drift after Lab 12A operational validation. |
| [`11-terraform-destroy-plan.png`](./11-terraform-destroy-plan.png) | Inherited Lab 12A destroy plan: zero additions, zero changes, and 47 resources to destroy. |
| [`12-terraform-destroy-complete.png`](./12-terraform-destroy-complete.png) | Successful removal of all 47 inherited Lab 12A resources. |
| [`13-post-destroy-verification.png`](./13-post-destroy-verification.png) | Terraform state contained zero managed resources after the Lab 12A teardown. |
| [`14-terraform-plan-complete.png`](./14-terraform-plan-complete.png) | Final reviewed Lab 12B Terraform plan: 58 additions, zero changes, and zero destroys. |
| [`15-security-runtime-plan-review.png`](./15-security-runtime-plan-review.png) | Planned runtime and security settings were reviewed, including Python 3.12, x86_64, memory, timeout, ephemeral storage, ReportLab layer compatibility, S3 encryption, versioning, ownership controls, public-access blocking, and force-destroy behavior. |
| [`16-terraform-apply-complete.png`](./16-terraform-apply-complete.png) | Successful deployment of all 58 Lab 12B resources. |
| [`17-executive-report-publication-verified.png`](./17-executive-report-publication-verified.png) | The executive-dashboard Lambda generated synchronized PDF and JSON artifacts, uploaded both to S3 with AES256 encryption, and preserved the human-review and no-containment boundary. |
| [`18-executive-security-report.pdf`](./18-executive-security-report.pdf) | Initial empty-data executive report with `NORMAL` posture and zero observed WAF events, findings, and incidents. |
| [`19-populated-report-verification.png`](./19-populated-report-verification.png) | Controlled synthetic data produced four current-period WAF events, one HIGH finding with risk score 60, one SOAR incident awaiting human review, an `ELEVATED` posture, and synchronized encrypted report artifacts. |
| [`20-populated-executive-security-report.pdf`](./20-populated-executive-security-report.pdf) | Human-readable populated executive report generated from the complete WAF-to-correlation-to-SOAR-to-reporting workflow. |
| [`20-populated-executive-security-report.json`](./20-populated-executive-security-report.json) | Machine-readable report document synchronized with the populated PDF by report ID and reporting period. |
| [`21-terraform-no-drift.png`](./21-terraform-no-drift.png) | Terraform reported no infrastructure drift after populated operational testing. |
| [`22-terraform-destroy-plan.png`](./22-terraform-destroy-plan.png) | Reviewed Lab 12B destroy plan: zero additions, zero changes, and 58 resources to destroy. |
| [`23-terraform-destroy-complete.png`](./23-terraform-destroy-complete.png) | Successful destruction of all 58 Lab 12B resources. |
| [`24-post-destroy-terraform-state-empty.png`](./24-post-destroy-terraform-state-empty.png) | Terraform state contained zero managed resources after teardown. |
| [`25-post-destroy-aws-resources-zero.png`](./25-post-destroy-aws-resources-zero.png) | No matching Lab 12B resources remained across Lambda, Lambda layers, DynamoDB, EventBridge, Scheduler, SNS, API Gateway, WAF, S3, and CloudWatch Logs. |

## Preserved artifact hashes

The populated PDF and JSON were copied from the report bucket before teardown.

```text
20-populated-executive-security-report.pdf
SHA-256: 6fa0549fe9a95db91dc276e44259c47a01ff18222a69ec6349b51b93d9ef210b

20-populated-executive-security-report.json
SHA-256: 4ddb0df9f218debe8a4718893b94c3a2a2320aa425e0857c6d17a29742668437
```

## Evidence handling

- Personal repository and branch information may remain visible to identify the submission author.
- AWS account IDs, ARNs, email addresses, subscription identifiers, API URLs,
  bucket names containing account IDs, credentials, and environment-specific
  private values must be redacted.
- Documentation-only IP addresses `198.51.100.88` and `203.0.113.45` may
  remain visible because they are synthetic test data.
- Report IDs, incident IDs, synthetic URI paths, WAF rule names, risk scores,
  and severity values may remain visible.
- Redactions must be flattened into the final PNG pixels before evidence is committed.
- PDF and JSON evidence must be reviewed for sensitive values before commit.
