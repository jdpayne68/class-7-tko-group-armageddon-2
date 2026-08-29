# Jacques Payne - Armageddon #2

## Individual Project Area

This directory contains Jacques Payne's implementation, validation evidence, runbooks, and technical documentation for the **Armageddon #2 / SEIR Foundations** group project.

The work is organized as a progressive security-engineering platform. Each lab adds a new capability while preserving the controls and evidence established in the previous stage.

> **Project classification:** Lab / Educational / Portfolio  
> **Final closeout audit:** PASS  
> **Audit result:** 24 checks passed, 0 failures  
> **Final infrastructure status:** Cleaned up after validation

---

## Project at a Glance

| Phase | Lab | Primary Focus | Final Status |
|---|---|---|---|
| Phase 1 | [Lab 12](phase-1/lab12/README.md) | AWS WAF analysis and Amazon Bedrock threat correlation | Validated and torn down |
| Phase 1 | [Lab 12A](phase-1/lab12a/README.md) | Event-driven SOAR response with human-review boundaries | Validated and torn down |
| Phase 1 | [Lab 12B](phase-1/lab12b/README.md) | Executive security reporting with synchronized PDF / JSON artifacts | Validated and torn down |
| Phase 2 | [Lab 12C](phase-2/lab12c/README.md) | Compliance evidence, Cognito authentication, RBAC, and token-use telemetry | Validated and torn down |
| Phase 2 | [Lab 12D](phase-2/lab12d/README.md) | Shared Python / Pydantic domain models and governed report lifecycle | Validated, 9 tests passing |

---

## Platform Evolution

```text
Lab 12
AWS WAF + API Gateway + Lambda + DynamoDB
        |
        v
Threat analysis + Amazon Bedrock correlation
        |
        v
Lab 12A
EventBridge + SOAR + SNS + security incidents
        |
        v
Human-review boundary for containment
        |
        v
Lab 12B
Executive metrics + PDF / JSON reporting + S3
        |
        v
Lab 12C
Compliance evidence + deterministic control evaluation
        |
        +--> Cognito MFA
        +--> group-based RBAC
        +--> token-use telemetry
        +--> unused-token detection
        |
        v
Lab 12D
Shared Pydantic contracts for evidence, threats,
responses, governance, and reports
```

The implementation deliberately separates:

```text
detection
analysis
response recommendation
authorization
reporting
compliance evidence
domain contracts
```

This keeps automated decisions auditable and prevents generative AI from silently becoming the authority for security or compliance outcomes.

---

## Engineering Principles Demonstrated

### Secure by Design

The labs use controls such as:

- least-privilege IAM permissions;
- scoped DynamoDB, S3, Lambda, SNS, and EventBridge access;
- WAF protection;
- Cognito authentication and TOTP MFA;
- group-based role-based access control;
- token ownership validation;
- S3 Block Public Access and encryption;
- explicit human approval boundaries for containment;
- secret and generated-artifact hygiene.

### Deterministic Decisions

Amazon Bedrock is used for explanation, enrichment, or narrative generation where appropriate.

It is **not** used as the final authority for:

- WAF severity;
- SOAR playbook selection;
- containment decisions;
- compliance PASS / FAIL / REVIEW results;
- compliance scoring.

Those decisions remain deterministic and auditable.

### Evidence-Driven Validation

The project preserves:

- Terraform plan and apply evidence;
- live AWS validation;
- CloudWatch logs;
- DynamoDB records;
- generated PDF and JSON artifacts;
- SHA-256 integrity hashes where applicable;
- regression-test output;
- no-drift validation;
- reviewed destroy plans;
- post-destroy Terraform state checks;
- post-destroy AWS inventory checks.

### Human Governance

High-impact response actions remain separated from automated recommendation.

```text
recommendation
      |
      v
approval required?
      |
      v
authorized
      |
      v
eligible for execution
```

This boundary is preserved throughout the SOAR, compliance, RBAC, and shared-domain-model work.

---

## Validation and Cleanup Summary

### Lab 12

Validated WAF-protected API behavior, threat analysis, Bedrock enrichment, DynamoDB correlation findings, Terraform no-drift, and controlled teardown.

### Lab 12A

Validated a 47-resource event-driven SOAR deployment, HIGH and CRITICAL response paths, duplicate-processing protection, SNS notifications, human-review controls, no-drift validation, and complete teardown.

### Lab 12B

Validated a 58-resource executive-reporting deployment, deterministic metrics, optional Bedrock narrative generation, ReportLab PDF creation, synchronized JSON publication, S3 security controls, artifact integrity, no-drift validation, and complete teardown.

### Lab 12C

Validated the Compliance Evidence Agent and the later authentication / RBAC / token-telemetry enhancement.

The final enhancement deployment added 75 managed resources and validated:

```text
No Cognito token            -> HTTP 401
Viewer                       -> HTTP 403
Analyst missing x-token-id   -> HTTP 400
Analyst with owned token     -> HTTP 200
Wrong-owner token            -> HTTP 403
Administrator with owned token -> HTTP 200
Token state                  -> used=false -> used=true
Unused-token detector        -> UNUSED_TOKEN alert
CloudWatch alert logging     -> validated
```

The final teardown then confirmed:

```text
Plan: 0 to add, 0 to change, 75 to destroy
75 resources destroyed
Terraform state count: 0
AWS-side resources: absent
```

### Lab 12D

Lab 12D does not deploy AWS infrastructure.

It validates shared Gen2X domain contracts with Python and Pydantic, including controlled vocabulary, assignment validation, serialization, Threat / Response composition, approval state, report projection, report lifecycle enforcement, and immutable final-report behavior.

Final regression result:

```text
9 passed
```

---

## Repository Navigation

### Phase 1

- [Lab 12 - WAF / Bedrock Threat Correlation](phase-1/lab12/README.md)
- [Lab 12A - Event-Driven SOAR Response](phase-1/lab12a/README.md)
- [Lab 12B - Executive Security Reporting](phase-1/lab12b/README.md)

### Phase 2

- [Lab 12C - Compliance Evidence Agent](phase-2/lab12c/README.md)
- [Lab 12D - Gen2X Shared Domain Models and Validation](phase-2/lab12d/README.md)

### Portfolio Summary

- [Armageddon #2 Portfolio Case Study](PORTFOLIO-CASE-STUDY.md)

---

## Final Repository Audit

The final read-only audit checked:

```text
Git branch and clean worktree
README / runbook / evidence inventory
tracked Terraform state, tfvars, and plan files
tracked .venv, __pycache__, .DS_Store, and .pyc files
high-risk AWS / GitHub / private-key signatures
tracked JSON validity
local Markdown links
Terraform formatting
current Lab 12D regression tests
post-audit worktree cleanliness
```

Final result:

```text
PASS: 24
NOTE: 2
FAIL: 0
```

The two notes identified the absence of this top-level README and the portfolio case study. Those two closeout documents were then added.

---

## Portfolio / Educational Boundary

This repository documents hands-on lab and portfolio work.

It demonstrates engineering practices, testing, troubleshooting, security controls, documentation, and validation performed in a controlled educational environment. It should not be interpreted as a claim that the same architecture was operated as a production service for an employer or customer.

---

## Author and Collaboration

**Author and Group Leader:** Jacques Payne

**Armageddon #2 Group**

- Jacques Payne
- Joe Tolliver, Jr.
- Cautchy Bailly
- Kirk Alton

Armageddon #2 was completed as a group project with members maintaining individual work areas and branches.

The contents under `members/jacques-payne/` represent the implementation, evidence, validation, and documentation maintained in Jacques Payne's project area. Phase 1 group submission materials were maintained through Kirk Alton's repository.
