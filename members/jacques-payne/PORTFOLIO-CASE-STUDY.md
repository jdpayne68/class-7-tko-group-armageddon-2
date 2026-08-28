# Armageddon #2 Security Engineering Platform

## Portfolio / Educational Case Study

### Executive Summary

Armageddon #2 is a multi-stage AWS security-engineering portfolio project built through the SEIR Foundations coursework.

The project began with a WAF-protected API and threat-correlation workflow, then progressively added event-driven SOAR, executive reporting, compliance evidence, authentication and RBAC, token-use telemetry, and a shared Python / Pydantic domain-contract layer.

The result is not a single isolated lab. It is a documented progression showing how security detection, response, governance, reporting, compliance evidence, identity, telemetry, and data contracts can be designed as connected but separately governed responsibilities.

The project was completed in a controlled educational environment and is presented as **hands-on portfolio work, not professional production experience**.

---

## The Problem

Security platforms often fail when too many responsibilities are collapsed into one component.

Common risks include:

- detection logic directly performing containment;
- generative AI being allowed to make authoritative security decisions;
- event payloads becoming the only source of truth;
- reports drifting from operational data;
- automation bypassing human approval;
- compliance evidence being confused with certification;
- weak authentication and authorization boundaries;
- little evidence that infrastructure was validated or cleaned up correctly.

Armageddon #2 addresses those risks by separating each responsibility and validating the interfaces between them.

---

## Design Goals

The project was designed around several constraints:

1. Keep security and compliance decisions deterministic where objective rules exist.
2. Use generative AI for explanation or enrichment, not silent authority.
3. Preserve one authoritative operational record.
4. Apply least privilege to AWS service interactions.
5. Require human approval for high-impact containment.
6. Make validation evidence part of the engineering lifecycle.
7. Treat teardown as a controlled engineering operation.
8. Keep identity, authorization, and telemetry as separate concerns.
9. Preserve domain truth when information is projected into reports.
10. Make the work reproducible and understandable to both technical and non-technical reviewers.

---

## Architecture Evolution

### Stage 1: WAF Analysis and Threat Correlation

**Lab 12** established the security-analysis foundation.

Core services:

```text
AWS WAF
API Gateway
Lambda
CloudWatch Logs
DynamoDB
Amazon Bedrock
IAM
```

Primary flow:

```text
Client
  |
  v
AWS WAF
  |
  v
API Gateway
  |
  v
Protected Lambda
  |
  +--> WAF event analysis
  |
  +--> DynamoDB evidence
  |
  +--> threat-correlation Lambda
          |
          +--> deterministic correlation
          +--> optional Bedrock enrichment
          |
          v
      correlation finding
```

Validation included allowed and blocked requests, WAF logs, Bedrock-enriched output, DynamoDB findings, Terraform no-drift, and controlled destruction.

---

### Stage 2: Event-Driven SOAR

**Lab 12A** added event-driven response orchestration.

```text
Threat finding
    |
    v
EventBridge
    |
    +--> MEDIUM / HIGH
    |       |
    |       v
    |   SOAR Lambda
    |
    +--> CRITICAL
            |
            +--> SOAR Lambda
            +--> critical SNS alert
```

The SOAR Lambda retrieves the authoritative finding from DynamoDB rather than treating the EventBridge event as the complete record.

The implementation uses deterministic severity playbooks and idempotency controls.

Validated behavior included:

- 47-resource deployment;
- HIGH-severity incident creation;
- CRITICAL urgent-review routing;
- duplicate-processing protection;
- standard and critical SNS paths;
- human-review boundaries;
- no-drift validation;
- complete teardown.

A core rule was preserved:

```text
containment_performed = false
human_review_required = true
```

Automation could recommend and route. It could not silently perform containment.

---

### Stage 3: Executive Security Reporting

**Lab 12B** added executive reporting without changing the operational authority model.

Authoritative inputs:

```text
DynamoDB waf-events
DynamoDB correlation findings
DynamoDB security incidents
```

Reporting pipeline:

```text
Authoritative operational data
        |
        v
Executive Dashboard Lambda
        |
        +--> deterministic metrics
        +--> period comparison
        +--> security posture
        +--> optional Bedrock narrative
        |
        v
Shared report document
        |
        +--> PDF
        +--> JSON
        |
        v
Amazon S3
```

Validated behavior included:

- 58-resource deployment;
- deterministic current / previous period metrics;
- ReportLab PDF rendering;
- synchronized PDF and JSON outputs;
- optional Bedrock narrative generation;
- S3 encryption and public-access controls;
- generated artifact integrity hashes;
- no-drift validation;
- complete teardown.

The report presentation could vary, but the underlying facts remained derived from the same authoritative operational records.

---

### Stage 4: Compliance Evidence

**Lab 12C** added a Compliance Evidence Agent.

The core design rule was:

```text
Python evaluates controls.
Amazon Bedrock explains the results.
```

The agent uses a reusable control library and deterministic validators to produce:

```text
PASS
FAIL
REVIEW
```

It then calculates a deterministic score, stores evidence records in DynamoDB, and produces synchronized JSON and PDF compliance reports.

The validated control set mapped evidence to:

```text
NIST CSF 2.0
CIS Controls v8
```

The implementation deliberately does **not** claim that technical evidence equals certification or a completed audit.

---

### Stage 5: Authentication, RBAC, and Token-Use Telemetry

After the original Lab 12C submission, the environment was extended with an identity and telemetry layer.

```text
Amazon Cognito
User Pool + MFA + Groups
        |
        | JWT
        v
API Gateway Cognito Authorizer
        |
        v
Protected Lambda
   /           \
  /             \
RBAC          Token telemetry
  |                |
  |                v
  |           DynamoDB
  |         token-tracking
  |                |
  |                v
  |       Unused Token Detector
  |                |
  +------------> CloudWatch Logs
```

Groups:

```text
security-viewers
security-analysts
security-admins
```

Live authorization validation:

| Scenario | Result |
|---|---:|
| No Cognito token | 401 |
| Viewer | 403 |
| Analyst missing `x-token-id` | 400 |
| Analyst with owned token | 200 |
| Analyst using another user's token record | 403 |
| Administrator with owned token | 200 |

Token-use telemetry validated:

```text
used=false -> used=true
```

Unused-token detection produced a structured:

```text
UNUSED_TOKEN
```

alert and corresponding CloudWatch log entry.

The final enhancement deployment created 75 managed resources. The final teardown validated:

```text
Plan: 0 to add, 0 to change, 75 to destroy
Destroy complete: 75 resources
Terraform state count: 0
AWS-side resource verification: absent
```

---

### Stage 6: Shared Domain Contracts

**Lab 12D** moved from infrastructure to shared application contracts.

The model architecture is:

```text
ENUMS
  |
  v
controlled vocabulary

MODELS
  |
  v
validated contracts

AGENTS
  |
  v
work performed using those contracts
```

Pydantic models cover:

```text
Provider
Evidence
Threat
Response
Governance / Approval
Report
```

Validation demonstrated:

- rejection of unexpected input;
- assignment-time validation;
- serialization and restoration;
- enum reconstruction;
- Threat / Response composition;
- approval-state enforcement;
- report projections that preserve established facts;
- DRAFT -> REVIEW -> FINAL -> ARCHIVED lifecycle;
- prevention of mutation after finalization;
- deterministic JSON artifact generation;
- SHA-256 artifact integrity;
- regression-suite preservation.

Final test result:

```text
9 passed
```

Lab 12D deploys no AWS infrastructure, so no cloud teardown is required.

---

## Security and Governance Decisions

### 1. Generative AI Is Advisory

Amazon Bedrock enriches or explains information.

It does not become the final authority for:

```text
severity
response playbook
containment
compliance outcome
compliance score
```

### 2. Human Approval Is Explicit

Automated workflows may create incidents, send notifications, and recommend containment.

High-impact execution remains behind an approval boundary.

### 3. Events Are Not the Authoritative Record

EventBridge carries routing information.

The SOAR workflow retrieves the authoritative finding from DynamoDB before taking the next governed action.

### 4. Reports Preserve Operational Truth

PDF and JSON reporting are generated from shared report documents derived from the same operational data.

This reduces the risk of inconsistent human-readable and machine-readable reports.

### 5. Authentication and Authorization Are Separate

Cognito answers:

```text
Who are you?
```

Application RBAC answers:

```text
May you perform this operation?
```

Token telemetry answers a different question:

```text
Was this issued token/session record actually used?
```

### 6. Compliance Evidence Is Not Certification

The Compliance Evidence Agent reports what observable technical evidence supports.

It does not claim organizational certification, audit success, or overall security.

### 7. Cleanup Is Part of Engineering

The infrastructure lifecycle includes:

```text
plan
review
apply
validate
no-drift
destroy plan
review
destroy
Terraform state verification
AWS-side absence verification
```

A successful lab is not considered complete merely because the deployment worked.

---

## Validation Approach

The project treats evidence as a first-class engineering artifact.

Evidence includes:

- Terraform plan and apply screenshots;
- AWS configuration checks;
- live API responses;
- CloudWatch logs;
- DynamoDB records;
- SNS behavior;
- S3 artifacts;
- generated PDF and JSON reports;
- SHA-256 hashes;
- pytest results;
- troubleshooting screenshots;
- no-drift results;
- destroy-plan review;
- post-destroy Terraform state;
- post-destroy AWS inventory.

A final read-only repository audit also validated:

```text
24 checks passed
0 failures
```

including JSON validity, local Markdown links, Terraform formatting, secret-like signatures, tracked-artifact hygiene, Lab 12D regression tests, and worktree cleanliness.

---

## Troubleshooting Examples

The project preserved failures as engineering evidence rather than hiding them.

Examples include:

### Terraform IAM Policy Failure

A malformed IAM policy was traced to a statement that had lost required resource entries.

The correction process followed:

```text
observe
isolate
inspect
correct
validate
deploy
capture evidence
```

### Controlled Vocabulary Mismatch

Lab 12D initially used:

```text
ThreatConfidence.HIGH
```

The shared contract correctly rejected it because `HIGH` described severity, not confidence.

The valid value for the scenario was:

```text
ThreatConfidence.VERIFIED
```

### Report Lifecycle Contract Mismatch

The Report model referenced:

```text
DRAFT
REVIEW
FINAL
ARCHIVED
```

while the original `ReportStatus` enum did not define `REVIEW` or `FINAL`.

The minimum contract-alignment fix was made, followed by regression testing.

Result:

```text
9 passed
```

These examples demonstrate that troubleshooting, validation, and regression testing were treated as part of the implementation rather than as cleanup after the fact.

---

## Technologies Demonstrated

### AWS

```text
AWS WAF
API Gateway
Lambda
DynamoDB
CloudWatch
EventBridge
EventBridge Scheduler
SNS
S3
Amazon Bedrock
Amazon Cognito
IAM
```

### Infrastructure and Automation

```text
Terraform
AWS CLI
Git
shell scripting
```

### Python

```text
Python 3.12
Pydantic v2
pytest
ReportLab
JSON serialization
structured logging
```

### Security Engineering Concepts

```text
least privilege
defense in depth
authentication
multifactor authentication
RBAC
idempotency
human approval boundaries
event-driven architecture
security telemetry
compliance evidence
control evaluation
artifact integrity
audit evidence
infrastructure lifecycle validation
```

---

## Productionization Considerations

This project intentionally remains a lab / educational implementation.

A production implementation would require additional work such as:

- remote encrypted Terraform state with controlled locking and access;
- CI/CD policy gates;
- centralized secrets management;
- formal key-management requirements;
- production-grade alert routing and escalation;
- durable dead-letter and retry handling;
- richer monitoring and SLOs;
- deployment separation across accounts and environments;
- centralized identity lifecycle management;
- formal change-management controls;
- backup and recovery requirements;
- scale and performance testing;
- threat modeling and formal security review;
- organization-specific control ownership and audit procedures.

Calling out these gaps is important because a validated portfolio lab is not the same thing as a production operating environment.

---

## Skills This Project Demonstrates

This portfolio project provides concrete evidence of hands-on practice with:

- Terraform-based AWS infrastructure;
- event-driven security workflows;
- Lambda and DynamoDB integration;
- WAF and API protection;
- least-privilege IAM;
- observability through CloudWatch;
- Cognito authentication and MFA;
- application-level RBAC;
- security telemetry design;
- deterministic compliance evaluation;
- S3 security controls;
- PDF / JSON reporting;
- Bedrock integration with bounded authority;
- Python data contracts with Pydantic;
- pytest regression testing;
- troubleshooting and remediation;
- documentation and runbook development;
- infrastructure teardown and verification.

These are demonstrated as **portfolio / educational capabilities**, not represented as employer production experience.

---

## Interview Summary

A concise way to explain the project is:

> Armageddon #2 is a multi-stage AWS security-engineering portfolio project. I started with a WAF-protected API and threat-correlation workflow, then added event-driven SOAR, executive reporting, deterministic compliance evidence, Cognito MFA and RBAC, token-use telemetry, and a shared Pydantic domain-model layer. A key design principle was keeping generative AI advisory rather than authoritative. Security decisions, compliance outcomes, and containment boundaries remained deterministic and auditable. I validated each stage with live evidence, no-drift checks, regression tests, and controlled teardown, including independent AWS-side cleanup verification.

---

## Repository Navigation

- [Jacques Payne project index](README.md)
- [Lab 12](phase-1/lab12/README.md)
- [Lab 12A](phase-1/lab12a/README.md)
- [Lab 12B](phase-1/lab12b/README.md)
- [Lab 12C](phase-2/lab12c/README.md)
- [Lab 12D](phase-2/lab12d/README.md)

---

## Attribution

Armageddon #2 was completed as a group project.

**Group Leader:** Jacques Payne

**Group Members**

- Jacques Payne
- Joe Tolliver, Jr.
- Cautchy Bailly
- Kirk Alton

The implementation, evidence, validation, and documentation described in this case study refer to the work maintained under:

```text
members/jacques-payne/
```

Phase 1 group submission materials were maintained through Kirk Alton's repository.
