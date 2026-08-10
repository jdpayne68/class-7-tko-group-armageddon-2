# Lab 12A Evidence Manifest

This directory contains engineering evidence for the standalone Lab 12A event-driven SOAR response workflow.

The instructor repository did not provide a Lab 12A-specific screenshot checklist. These artifacts document the implemented requirements and successful validation.

| Evidence | What it proves |
|---|---|
| [`01-terraform-plan-complete.png`](./01-terraform-plan-complete.png) | Final reviewed Terraform plan: 47 additions, zero changes, and zero destroys. |
| [`02-terraform-apply-complete.png`](./02-terraform-apply-complete.png) | Successful deployment of all 47 planned Lab 12A resources. |
| [`03-sns-subscriptions-confirmed.png`](./03-sns-subscriptions-confirmed.png) | Both email subscriptions are confirmed for standard SOAR notifications and immediate critical alerts. |
| [`04-eventbridge-rules-and-targets.png`](./04-eventbridge-rules-and-targets.png) | MEDIUM/HIGH findings route to SOAR; CRITICAL findings route to SOAR and critical-alert SNS. |
| [`05-high-severity-end-to-end-workflow.png`](./05-high-severity-end-to-end-workflow.png) | A HIGH finding created an incident, published SNS, and completed the finding workflow. |
| [`06-idempotent-retry-skipped.png`](./06-idempotent-retry-skipped.png) | A replayed completed finding was skipped and did not create a duplicate incident. |
| [`07-critical-soar-workflow.png`](./07-critical-soar-workflow.png) | A CRITICAL finding created a priority-1 incident and preserved the human-approval boundary. |
| [`08-critical-dual-sns-publication.png`](./08-critical-dual-sns-publication.png) | CloudWatch metrics confirm publication to both CRITICAL routing destinations. |
| [`09a-correlation-eventbridge-publication.png`](./09a-correlation-eventbridge-publication.png) | The correlation Lambda created a HIGH finding and published it to EventBridge. |
| [`09b-soar-incident-completion.png`](./09b-soar-incident-completion.png) | EventBridge invoked SOAR automatically, resulting in incident creation, notification, and workflow completion. |
| [`10-terraform-no-drift.png`](./10-terraform-no-drift.png) | Terraform reported no infrastructure drift after operational validation. |

| [`11-terraform-destroy-plan.png`](./11-terraform-destroy-plan.png) | Reviewed destroy plan: zero additions, zero changes, and 47 resources to destroy. |
| [`12-terraform-destroy-complete.png`](./12-terraform-destroy-complete.png) | Successful removal of all 47 managed Lab 12A resources. |
| [`13-post-destroy-verification.png`](./13-post-destroy-verification.png) | Terraform state contains zero managed resources and no objects remain to destroy. |

## Evidence handling

- Personal repository and branch information may remain visible to identify the submission author.
- AWS account IDs, email addresses, subscription identifiers, API identifiers, and environment-specific values must be redacted.
- Redactions must be flattened into the final PNG pixels before evidence is committed.
