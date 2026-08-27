# Lab 12c — WAF-to-Bedrock SOAR Pipeline

## 1. What is this lab supposed to do?

This lab builds a serverless **SOAR (Security Orchestration, Automation, and Response) pipeline** that automatically detects, stores, and interprets malicious traffic hitting a protected API — using AWS WAF for detection, DynamoDB for structured storage, and Amazon Bedrock (Claude Haiku 4.5) for AI-generated SOC analyst narratives on top of deterministic, rules-based risk scoring.

In plain terms: attackers hit an API → WAF blocks/logs it → a scheduled Lambda normalizes and stores each event → a second scheduled Lambda correlates events by source IP/URI/rule, scores the risk deterministically, and asks an LLM to write a human-readable incident summary a SOC analyst could act on.

**Lab 12a extends this into a closed-loop SOAR pipeline.** Once the correlation agent writes a finding to `waf-correlation-findings`, it publishes a small routing event to EventBridge. A third Lambda — `soar_response_agent` — is invoked by that event (not on a schedule), pulls the *complete* finding back out of DynamoDB, selects a deterministic response playbook by severity, asks Bedrock for both an analyst-facing and a management-facing summary, opens an incident record, sends an SNS notification, and marks the finding as processed so it can't be actioned twice. That turns the pipeline from "detect and score" into "detect, score, and respond."

**Lab 12b adds an executive reporting layer.** A fourth Lambda — `executive_dashboard_agent` — runs on demand (and can be scheduled the same way Lambdas #1/#2 are) to scan all three DynamoDB tables over a configurable reporting window, asks Bedrock to synthesize the raw counts into an executive-level narrative, and renders both a PDF and a JSON version of an Executive Security Report using ReportLab, writing both to a date-partitioned S3 key. That turns the pipeline from "detect, score, and respond" into "detect, score, respond, and report" — giving leadership a periodic, human-readable rollup instead of requiring them to read DynamoDB records directly.

**Lab 12c adds a compliance evidence layer.** A fifth Lambda — `compliance_evidence_agent` — reads `controls.json`, a data-driven library of compliance controls (control ID, framework mappings, and a `validation` block naming which deterministic Python validator to run — `table_exists`, `s3_prefix`, and others defined for future controls). The agent's own rule is explicit in its docstring: **"Python evaluates controls. Bedrock explains the results."** For every selected control it runs the matching validator, immediately writes one evidence record to a new `compliance-evidence` DynamoDB table (one control at a time, not batched until the end — see Lessons Learned), then only after every control has a deterministic PASS/FAIL/REVIEW status does it ask Bedrock to narrate what was already computed. It renders a synchronized PDF + JSON compliance report with the same ReportLab layer already built for Lambda #4, and uploads both to `compliance-reports/` in the report bucket. It runs on its own daily `cron()` schedule, deliberately offset one hour after the executive dashboard agent's schedule, so the `s3_prefix` control that checks for a same-day executive report doesn't race it.

### High-Level Flow

```
API Gateway + Cognito
    ↓
AWS WAF v2
    ↓
CloudWatch Logs
    ↓
waf-bedrock-analyzer lambda  (scheduled, every 10 min)
    ↓
waf-events (DynamoDB)
    ↓
waf-threat-correlation-agent lambda  (scheduled, every 60 min)
    ↓
waf-correlation-findings (DynamoDB)
    ↓  events:PutEvents → "WAF Threat Finding Created"
Amazon EventBridge  (event-pattern rule, not a schedule)
    ↓
soar_response_agent lambda
    ↓
security-incidents (DynamoDB)   +   SNS notification

waf-events  +  waf-correlation-findings  +  security-incidents  (DynamoDB)
    ↓  on-demand / scheduled dynamodb:Scan across all three tables
executive_dashboard_agent lambda   (Bedrock synthesis + ReportLab rendering)
    ↓
Amazon S3 — executive-reports/YYYY/MM/DD/pdf/*.pdf  +  /json/*.json

controls.json  (data-driven control library)
    ↓
compliance_evidence_agent lambda   (scheduled, cron daily, 1 hr after dashboard_agent)
    ↓  per-control: evaluate → write evidence immediately → next control
compliance-evidence (DynamoDB)   +   Bedrock narrates the computed PASS/FAIL/REVIEW results
    ↓
Amazon S3 — compliance-reports/YYYY/MM/DD/pdf/*.pdf  +  /json/*.json
```
---
## 2. Badges

![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)
![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-Serverless-FF9900?style=for-the-badge&logo=awslambda&logoColor=white)
![Amazon Bedrock](https://img.shields.io/badge/Amazon%20Bedrock-Claude%20Haiku%204.5-1E8E6E?style=for-the-badge&logo=amazonaws&logoColor=white)
![DynamoDB](https://img.shields.io/badge/DynamoDB-NoSQL-4053D6?style=for-the-badge&logo=amazondynamodb&logoColor=white)
![AWS WAF](https://img.shields.io/badge/AWS%20WAF-Web%20ACL-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![Cognito](https://img.shields.io/badge/Amazon%20Cognito-Auth-DD344C?style=for-the-badge&logo=amazoncognito&logoColor=white)
![Amazon EventBridge](https://img.shields.io/badge/Amazon%20EventBridge-Event%20Driven-FF4F8B?style=for-the-badge&logo=amazonaws&logoColor=white)
![Amazon SNS](https://img.shields.io/badge/Amazon%20SNS-Notifications-CC2264?style=for-the-badge&logo=amazonsimplenotificationservice&logoColor=white)
![SOAR](https://img.shields.io/badge/SOAR-Automated%20Response-2EA44F?style=for-the-badge)
![Amazon S3](https://img.shields.io/badge/Amazon%20S3-Report%20Storage-569A31?style=for-the-badge&logo=amazons3&logoColor=white)
![ReportLab](https://img.shields.io/badge/ReportLab-PDF%20Generation-B7312C?style=for-the-badge&logo=python&logoColor=white)
![Executive Reporting](https://img.shields.io/badge/Executive%20Reporting-Automated-6F42C1?style=for-the-badge)
![Compliance Evidence](https://img.shields.io/badge/Compliance%20Evidence-NIST%20%7C%20CIS-0B7285?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Lab%20%2F%20Educational-2EA44F?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-9E9E9E?style=for-the-badge)

---

## 3. Project overview

The pipeline has five Lambda functions — two on `rate()` schedules, one event-driven, and two on daily `cron()` schedules — sitting on top of a shared data layer:

| Component | Role |
|---|---|
| **API Gateway + Cognito** | A protected REST endpoint (`POST /seir_analyze`), authenticated with a Cognito User Pool authorizer |
| **AWS WAF v2** | Inspects traffic to the API stage; blocks common web attacks, SQL, and rate-based abuse; logs every match to CloudWatch |
| **CloudWatch Logs** | Landing zone for raw WAF JSON records |
| **`waf-bedrock-analyzer` Lambda** | Runs every 10 minutes — reads recent WAF logs, normalizes and deduplicates them into DynamoDB, and asks Bedrock for a per-event SOC summary |
| **`waf-events` (DynamoDB)** | Structured, deduplicated store of individual WAF events |
| **`waf-threat-correlation-agent` Lambda** | Runs every 60 minutes — scans `waf-events`, groups activity by source IP / URI / rule, computes a deterministic 0–100 risk score, asks Bedrock to turn that evidence into an analyst-facing narrative, writes the finding to `waf-correlation-findings`, and publishes a `WAF Threat Finding Created` event to EventBridge |
| **`waf-correlation-findings` (DynamoDB)** | Store of aggregated, severity-ranked findings for analyst review |
| **Amazon EventBridge (event-pattern rule)** | Fires on `detail-type: "WAF Threat Finding Created"` — distinct from the two schedule-based rules — and invokes `soar_response_agent` with routing info only (`finding_id`, `severity`, `risk_score`) |
| **`soar_response_agent` Lambda** | Event-driven, not scheduled — retrieves the *complete* finding from DynamoDB by `finding_id`, validates it hasn't already been processed, selects a deterministic response playbook by severity, asks Bedrock for an analyst summary and a management summary, writes an incident, publishes an SNS notification, and updates the finding's workflow status |
| **`security-incidents` (DynamoDB)** | Store of opened incidents, keyed by a deterministic `INC-<finding_id>` ID so retried events can't create duplicates |
| **`executive_dashboard_agent` Lambda** | On-demand (or scheduled) — scans `waf-events`, `waf-correlation-findings`, and `security-incidents` over a configurable reporting window, asks Bedrock to synthesize the counts into an executive narrative, and renders a PDF + JSON report with ReportLab |
| **Amazon S3 (report bucket)** | Stores the rendered executive reports under a date-partitioned key (`executive-reports/YYYY/MM/DD/pdf|json/...`) |
| **`controls.json`** | Data-driven library of compliance controls — control ID, title, severity, framework mappings (NIST CSF 2.0, CIS Controls v8, and others attached but not yet evaluated), and a `validation` block naming which registered validator function evaluates it |
| **`compliance_evidence_agent` Lambda** | Runs daily on its own `cron()` schedule — loads `controls.json`, filters to the requested framework(s), runs each control through a deterministic validator, writes an evidence record to DynamoDB **immediately after each control** (not batched), asks Bedrock only to narrate the already-computed results, and renders a PDF + JSON compliance report with the shared ReportLab layer |
| **`compliance-evidence` (DynamoDB)** | Append-only evidence log — one immutable record per control per run, so an auditor asking "why did this control pass on this date" has a durable answer that doesn't depend on the PDF still existing |

The design deliberately separates **deterministic math** (risk scoring, correlation, counts, playbook selection, control PASS/FAIL/REVIEW status — all plain Python) from **AI interpretation** (Bedrock is only ever asked to explain/narrate evidence and decisions that have already been calculated, never to invent numbers or choose the response itself, and never to decide whether a control passed). The executive reporting layer follows the same rule — Bedrock narrates the counts `executive_dashboard_agent` already pulled from DynamoDB, it doesn't generate them. The compliance layer takes this furthest: a control that can't be evaluated becomes `REVIEW`, never a silent `PASS`, and Bedrock never sees raw AWS resources at all — only the control ID, its computed status, and the observation Python already wrote.

---

## 4. Requirements

To build and run this lab, you'll need:

- [ ] **Terraform** ≥ 1.5.0, AWS provider `~> 6.0`
- [ ] **AWS Console access** with permissions to create IAM roles/policies, Lambda, API Gateway, Cognito, DynamoDB, CloudWatch, WAFv2, and EventBridge resources
- [ ] **Amazon Bedrock model access** enabled in your target region, including the one-time AWS Marketplace model subscription
- [ ] **Python** 3.14 (matches the Lambda runtime) with `boto3` for local testing/token scripts
- [ ] **VS Code** (or your editor of choice) with the HashiCorp Terraform extension
- [ ] **Git Bash** (or an equivalent shell) for running Terraform/AWS CLI commands on Windows
- [ ] **AWS CLI**, configured with credentials that match the IAM permissions above
- [ ] **Lambda Layers** capability — `reportlab` (used by both `executive_dashboard_agent` and `compliance_evidence_agent` for PDF generation) is not part of the standard Python Lambda runtime and must be packaged as a layer or bundled into the deployment ZIP, built for the Lambda Linux runtime and attached to both functions
---

## 5. Project / folder structure

```
LAB12C/
├── .terraform/                         # Terraform provider plugin cache (auto-generated, gitignored)
├── code/
│   ├── compliance.py                    # Lambda #5 source (Agent 9: Compliance Agent)
│   ├── controls.json                    # data-driven compliance control library, packaged into the Lambda #5 zip
│   ├── executive_dashboard_agent.py    # Lambda #4 source
│   ├── requirements.txt                # reportlab==4.4.3 — packaged into the Lambda layer below
│   ├── soar_response_agent.py          # Lambda #3 source
│   ├── waf_bedrock_analyzer.py         # Lambda #1 source
│   └── waf_threat_correlation_agent.py # Lambda #2 source
├── compliance_test_event.json          # manual test-invoke payload — {"frameworks": ["NIST CSF 2.0", "CIS Controls v8"]}
├── correlation_findings/
│   └── log-events-viewer-result.csv    # exported view of correlation findings/log review
├── function/                           # terraform-generated zip artifacts (git-ignored)
│   ├── compliance_evidence_agent.zip
│   ├── executive_dashboard_agent.zip
│   ├── soar_response_agent.zip
│   ├── waf_bedrock_analyzer.zip
│   └── waf_threat_correlation_agent.zip
├── layers/
│   └── reportlab/                      # pip-installed reportlab, built for the Lambda Linux runtime
├── screenshots/                        # artifacts for section 7 — see below
├── troubleshooting/                    # notes/logs referenced in section 11
├── .gitignore
├── .terraform.lock.hcl                 # provider dependency lock (safe to commit)
├── apigateway.tf                       # REST API, resource, method, Lambda proxy integration, stage
├── cloudwatch.tf                       # WAF log group
├── cognito.tf                          # User pool, resource server/scopes, app client, test user, authorizer
├── dynamodb.tf                         # waf-events + waf-correlation-findings + security-incidents + compliance-evidence tables
├── eventbridge.tf                      # 2 rate schedules + 1 event-pattern rule + 2 cron schedules (dashboard, compliance) + invoke permissions
├── iam-01.tf                           # Shared execution role for analyzer / correlation agent / soar_response_agent + inline policy
├── iam-02.tf                           # executive_dashboard_agent execution role + inline policy
├── iam-03.tf                           # compliance_evidence_agent execution role + inline policy
├── lambda.tf                           # All five Lambda function resources + archive_file packaging + shared reportlab layer resource
├── locals.tf                           # report_prefix local ("executive-reports")
├── outputs.tf                          # Cognito app client ID, API Gateway invoke URL
├── provider.tf                         # AWS provider + Terraform version pin
├── readme.md                           # this file
├── s3-bucket.tf                        # shared report bucket — holds both executive-reports/ and compliance-reports/ prefixes
├── sns.tf                              # sns topic, subscription, policy
├── terraform.tfstate                   # Terraform state — contains sensitive values, should be gitignored
├── terraform.tfstate.backup            # same as above
├── variables.tf                        # region, Cognito test user credentials, notification email, report bucket name
└── waf.tf                              # Web ACL, managed rule groups, rate-based rule, association, logging
```
---

## 6. Steps used to complete this lab

1. **Provider & variables** — pinned the AWS provider version and defined `region`, the test Cognito user's username/password, and a notification email.
2. **Identity layer** — created the Cognito User Pool, resource server with `admin-scope`/`user-scope`, an app client with `generate_secret = false` and `ALLOW_USER_PASSWORD_AUTH`, a suppressed-invite test user, and a `COGNITO_USER_POOLS` API Gateway authorizer.
3. **Edge layer** — built the REST API, the `/seir_analyze` resource and `POST` method (Cognito-authorized), an `AWS_PROXY` integration to the analyzer Lambda, and deployed it to a `prod` stage.
4. **WAF layer** — created the Web ACL with the AWS Managed Common Rule Set, the Managed SQLi Rule Set, and a custom rate-based rule (15 requests/IP), then associated the Web ACL with the API Gateway stage and enabled logging to CloudWatch.
5. **Logging & storage** — created the `aws-waf-logs-events` log group (7-day retention) and the three DynamoDB tables (`waf-events`, `waf-correlation-findings`, `security-incidents`), all with PITR and encryption enabled.
6. **IAM** — split the original shared Lambda execution role into purpose-specific roles per function (analyzer, correlation agent, SOAR response agent), each scoped to only the CloudWatch Logs, DynamoDB, SNS, EventBridge, and Bedrock `InvokeModel` permissions it actually needs (both foundation-model and cross-region inference-profile ARNs), plus the one-time AWS Marketplace subscribe permissions Bedrock needs for third-party models.
7. **Lambda #1 — analyzer** — wrote `waf_bedrock_analyzer.py` to pull recent WAF logs, normalize/deduplicate events into `waf-events`, and call Bedrock for a per-event SOC summary; packaged and deployed via `archive_file`.
8. **Lambda #2 — correlation agent** — wrote `waf_threat_correlation_agent.py` to scan `waf-events`, group by source IP/URI/rule, score risk deterministically, call Bedrock for a narrative, save findings to `waf-correlation-findings`, and publish a `WAF Threat Finding Created` event to EventBridge (routing info only — `finding_id`, `severity`, `risk_score`).
9. **Scheduling** — created the two EventBridge schedule rules (`rate(10 minutes)` and `rate(60 minutes)`) and the matching Lambda invoke permissions for Lambdas #1 and #2.
10. **Incident storage** — added the `security-incidents` DynamoDB table (primary key `incident_id`) to hold opened incidents.
11. **Lambda #3 — SOAR response agent** — wrote `soar_response_agent.py` to:
    - Retrieve the *complete* finding from `waf-correlation-findings` by `finding_id` rather than trusting the small EventBridge payload as authoritative
    - Validate the finding exists, is still `OPEN`, hasn't already been processed, has a valid severity, and has the required evidence fields
    - Select a deterministic response playbook by severity (table below)
    - Call Bedrock for an analyst summary and a management summary
    - Write a `security-incidents` record using a deterministic ID (`INC-<finding_id>`) via a conditional `PutItem`, so a retried EventBridge delivery can't create a duplicate incident
    - Publish the SNS notification
    - Update the original finding's workflow status so it can't be reprocessed
12. **Event-pattern rule** — added a third EventBridge rule matching `detail-type: "WAF Threat Finding Created"` (an event pattern, not a schedule) with an invoke permission scoped to `soar_response_agent`.
13. **Deploy** — `terraform init` → `terraform plan` → `terraform apply`, resolving cross-file resource reference issues as they came up (including a broken SNS topic ARN reference and an EventBridge severity case mismatch — see Troubleshooting).
14. **Validation** — ran `get-token-easy_updated.py` to obtain a Cognito bearer token, called the protected `/seir_analyze` endpoint, and confirmed events landing in `waf-events`, findings landing in `waf-correlation-findings`, and — once a finding crossed the severity threshold — an incident landing in `security-incidents` with a matching SNS notification.
15. **Log review** — checked each Lambda's CloudWatch execution logs (including `soar_response_agent`) to confirm the Bedrock SOC summaries, correlation narratives, and analyst/management incident summaries were all generating as expected.
16. **Idempotency check** — manually re-published the same `finding_id` event through EventBridge and confirmed the conditional `PutItem` blocked a duplicate incident from being created.

### Playbook selection (soar_response_agent)

| Severity | Playbook |
|----------|----------|
| Low | Record only |
| Medium | Notify analyst |
| High | Notify and create incident |
| Critical | Notify, create incident, request containment approval |

### Expected EventBridge input (WAF Threat Finding Created)

```json
{
  "version": "0",
  "id": "example-event-id",
  "detail-type": "WAF Threat Finding Created",
  "source": "seir.waf.correlation",
  "account": "123456789012",
  "time": "2026-07-14T20:10:00Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "finding_id": "7ea476d0-1fea-4ff0-a95a-6377faac5cb4",
    "severity": "HIGH",
    "risk_score": 75
  }
}
```
The event envelope carries standard EventBridge fields (`source`, `detail-type`, `detail`); `soar_response_agent` only reads `detail.finding_id` for routing, then retrieves the authoritative finding from DynamoDB.

17. **Dependency packaging** — `reportlab` isn't part of the standard Lambda Python runtime, so it was packaged as a Lambda layer (built against the Lambda Linux runtime, matching the function's architecture) rather than assuming it would just be importable.
18. **Report bucket** — added an S3 bucket for executive reports, with versioning and default encryption enabled.
19. **IAM for the new Lambda** — scoped `dynamodb:Scan` to all three tables, `bedrock:InvokeModel` for the narrative summary, and `s3:PutObject` restricted to the `executive-reports/*` prefix of the report bucket (see the required-permissions block below).
20. **Lambda #4 — executive dashboard agent** — wrote `executive_dashboard_agent.py` to:
    - Scan `waf-events`, `waf-correlation-findings`, and `security-incidents` for the configured `report_period_hours` window (capped by `MAX_ITEMS_PER_TABLE` per table)
    - Ask Bedrock to turn the raw counts into an executive-level narrative
    - Render the report in memory with ReportLab (no `/tmp` dependency, since the PDF is built entirely in memory) and also produce a synchronized JSON version of the same facts
    - Upload both objects to S3 under a date-partitioned key (`executive-reports/YYYY/MM/DD/pdf|json/...`)
    - Package and deploy via `archive_file`, attaching the `reportlab` layer
21. **Lambda configuration** — set memory to 1024 MB and timeout to 120 seconds (well above the 3-second default) to give the scan-across-three-tables + Bedrock call + PDF render enough headroom; left ephemeral storage at the 512 MB default since the report never touches disk.
22. **Test invoke** — invoked `executive_dashboard_agent` with a manual test event (`{"report_period_hours": 24}`) and confirmed both the PDF and JSON objects landed in the report bucket under the expected date-partitioned prefix.
23. **Compliance evidence table** — added `compliance-evidence` (PITR + encryption enabled, same as the other three tables). A second table, `compliance-findings`, was scaffolded for open/current compliance gaps but removed before deploy — nothing was going to read from it yet, and the append-only evidence log already covers the audit-trail use case (see Lessons Learned).
24. **Controls library** — authored `controls.json`: a data-driven library of compliance controls, each with a `control_id`, title, severity, framework mappings, and a `validation` block naming which registered validator evaluates it. Four controls currently exercise two validator types (`table_exists`, `s3_prefix`); seven validators total are registered (`table_exists`, `table_not_empty`, `minimum_records`, `s3_prefix`, `bedrock_enabled`, `eventbridge_rule_exists`, `eventbridge_schedule_exists`, `sns_topic_exists`, `lambda_exists`) so new controls can be added by editing JSON, not code.
25. **IAM for the compliance agent** — `iam-03.tf` scopes `dynamodb:DescribeTable` + `dynamodb:Scan` to the three source tables, `dynamodb:BatchWriteItem` to `compliance-evidence`, `s3:ListBucket` to the `executive-reports/*` prefix (so the `s3_prefix` control can confirm a dashboard report exists), `s3:PutObject` to `compliance-reports/*`, and `bedrock:InvokeModel` for both the foundation-model and inference-profile ARNs.
26. **Lambda #5 — compliance evidence agent** — wrote `compliance.py` to:
    - Load `controls.json` and filter to the requested framework(s) (or `"ALL"`)
    - Run every selected control through its validator, and immediately write that control's evidence record to `compliance-evidence` before evaluating the next one — not batched until the end of the loop, so a mid-run crash still preserves every control already evaluated
    - Calculate a transparent PASS/FAIL/REVIEW score deterministically (`REVIEW` never counts toward the score, so missing evidence can't inflate it)
    - Ask Bedrock only to narrate the already-computed results — Bedrock never sees raw AWS resources, only control IDs, statuses, and observations Python already wrote
    - Render synchronized PDF + JSON reports with ReportLab and upload both to `compliance-reports/YYYY/MM/DD/pdf|json/...`
    - Package and deploy via `archive_file`, attaching the same `reportlab` layer already built for `executive_dashboard_agent`
27. **Scheduling** — converted both the dashboard agent and the compliance agent from independent `rate()` schedules to fixed daily `cron()` expressions — `cron(0 22 * * ? *)` for `executive_dashboard_agent` and `cron(0 23 * * ? *)` for `compliance_evidence_agent` — so the compliance agent's report-existence check reliably runs an hour after a fresh executive report lands, instead of two independently-drifting `rate()` clocks racing each other.
28. **Test invoke** — invoked `compliance_evidence_agent` with `compliance_test_event.json` (`{"frameworks": ["NIST CSF 2.0", "CIS Controls v8"]}`) and confirmed the evidence records, PDF, and JSON report all landed correctly.

---

## 7. Screenshots
1. `Init`, `Validate`, `Plan`, And `Apply` showing all steps having successed

![Init](./screenshots/01_terraform_init.png)

![Validate](./screenshots/02_terraform_validate.png)

![Plan](./screenshots/03_terraform_plan.png)

![Apply](./screenshots/04_terraform_apply.png)

2. Shows that the `WAF ACL` was created and its rules the actions it takes an the priority of each one. 

![WAF](./screenshots/06_waf_acl.png)

3. This show how it looks when logged into correctly with a `Access Token` 

![Access Token](./screenshots/012_api_call.png)

![Cloud Log](./screenshots/020_cognito_working.png)

4. Shows the lambda functions both the `waf-bedrock-analyzer` This is set up to run every `10 minutes` and `waf-threat-correlation-agent` This is set up to run every `60 minutes` and the `envirnoment variables` for both 

![Waf Bedrock Analyzer](./screenshots/013_waf_function.png)

![Environment variables](./screenshots/014_waf_env_var.png)

![Waf Threat Correlation Agent](./screenshots/015_correlation_agent_function.png)

![Environment variables](./screenshots/016_agent_env_var.png)

5. Shows the the Dynamodb table created after the lambda function `Waf Bedrock Analyzer` has been run. 

![Dynamodb Table](./screenshots/010_waf_event_table.png)

6. Shows the Waf blocking attacks and the information being captured by the `CloudWatch Logs`.  This also shows the `Waf SOC Summary` and what was actually blocked.

![Block Action](./screenshots/07_block_action.png)

![SOC](./screenshots/08_waf_soc_summary.png)

![Cloudslog](./screenshots/09_waf_block_cloudlogs.png)

7. This shows the `waf-threat-correlation-agent` after taking the information from the Waf Bedrock Anaylzer after `60 minutes`.  The Dynamodb table is also created.

![Correlation Agent 1](./screenshots/017_correlation_agent_event.png)

![Correlation Agent 2](./screenshots/018_correlation_agent_event_2.png)

![Correlation Agent 3](./screenshots/019_correlation_agent_event_3.png)

![Correlation Report](./correlation_findings/log-events-viewer-result.csv)

![Dynamodb Table](./screenshots/021_correlation_dynamodb.png)

8. This shows the new function the `SOAR Response Agent` along with its environment variables it takes the information from the `waf-correlation-findings` and validates the finding has not already been processed, selects a response from the playbook, ask bedrock to create summaries, incident records, and send notifications.

![Soar Response Agent](./screenshots/025_soar_function.png)

![Environment Variables](./screenshots/026_soar_env_var.png)

9. The correlation information is sent to the `SOAR agent` it can now create incident record and alerts.  It creates the Dynamodb table for `Security Incidents` and `CloudWatch Logs` along with sending `SNS` depending on the `Severity` from the `Playbook`

![CloudWatch Logs](./screenshots/023_SOAR_cloudwatch.png)

![Security Incident](./screenshots/022_soar_agent_security_incident.png)

![SNS](./screenshots/024_sns_email.png)

![]()

10. Shows the new `executive_dashboard_agent` function, its environment variables, and the attached `reportlab` Lambda layer.
![CloudWatch Log Summary](./screenshots/027_executive_summary.png)

![Executive Dashboard Function](./screenshots/028_executive_function.png)

![Executive Dashboard Env Vars](./screenshots/029_executive_env_var.png)

![Reportlab Layer](./screenshots/033_lambda_layer.png)



11. Shows a manual test invoke of `executive_dashboard_agent` succeeding, and the resulting PDF + JSON objects landing in the S3 report bucket under the date-partitioned prefix.

![Test Invoke](./screenshots/032_test_invoke.png)

![S3 Report Bucket](./screenshots/030_s3_executive.png)

![Executive PDF Report](./screenshots/031_pdf_1.png)

![Executive PDF Report](./screenshots/031_pdf_2.png)

---

12. Shows the new `compliance_evidence_agent` function, its environment variables, and the shared `reportlab` Lambda layer attached to a second function.

![Compliance Agent Function](./screenshots/039_lambda_function.png)

![Compliance Agent Env Vars](./screenshots/040_compliance_env_var.png)

13. Shows a manual test invoke of `compliance_evidence_agent` succeeding, the `compliance-evidence` DynamoDB table populated with one evidence record per control, `CloudWatch Log for compliance` and the resulting PDF + JSON objects landing in the S3 report bucket under `compliance-reports/`.

![Compliance Test Invoke](./screenshots/041_compliance_invoke.png)

![Compliance Evidence Table](./screenshots/037_compliance_evidence_dynamodb.png)

![CloudWatch Log Compliance](./screenshots/038_cloudwatch_log_compliance.png)

![Compliance S3 Report](./screenshots/034_compliance_reports_json_pdf.png)

![Compliance PDF Report 1](./screenshots/035_compliance_evidence_report_1.png)

![Compliance PDF Report 2](./screenshots/036_compliance_evidence_report_2.png)
---

## 8. Steps used to teardown / destroy the infrastructure

![Terraform Destroy](./screenshots/05_terraform_destroy.png)

1. Run `terraform destroy` from the project root and review the destroy plan before confirming.
2. Verify in the AWS Console that the Web ACL, API Gateway, Cognito User Pool, all five Lambdas, all four DynamoDB tables (`waf-events`, `waf-correlation-findings`, `security-incidents`, `compliance-evidence`), the CloudWatch log group, and all five EventBridge rules (two rate schedules + one event-pattern rule + two cron schedules) are gone.
3. Note: the **AWS Marketplace subscription** to the Bedrock model is an account-level grant, not a Terraform-managed resource — it is not removed by `destroy` and does not need to be, since it costs nothing on its own (you're only billed for actual model invocations).
4. Double-check CloudWatch for any orphaned log groups Lambda auto-creates (`/aws/lambda/...`) that Terraform doesn't manage, since those keep incurring storage cost until deleted manually — this now includes `/aws/lambda/executive_dashboard_agent` and `/aws/lambda/compliance_evidence_agent`.
5. **Empty the S3 report bucket before (or during) destroy.** Terraform can't delete a non-empty bucket unless `force_destroy = true` is set on the `aws_s3_bucket` resource; otherwise, manually delete both the `executive-reports/` and `compliance-reports/` PDF/JSON objects (and any versions, if versioning is on) first, or `terraform destroy` will fail on that resource.
6. Confirm the `reportlab` Lambda layer version is also removed — layer versions aren't deleted automatically just because the functions using them (now two) are gone.

---

## 9. Lessons learned

### What Did You Learn While Building This Lab?

This lab helped demonstrate how AWS security logs can be used as evidence for automated threat analysis. Instead of only viewing raw WAF logs manually, the project shows how logs can be normalized, stored, scored, and summarized using cloud-native services.

Key learning areas:

- How AWS WAF logs can be read from CloudWatch Logs.
- How Lambda functions can process security events automatically.
- How DynamoDB can store normalized security evidence and final findings.
- How Amazon Bedrock can generate incident summaries from structured security data.
- How a second Lambda function can correlate multiple WAF events instead of analyzing only one event at a time.
- How environment variables make Lambda functions configurable without hardcoding values.
- How to move from a scheduled/batch pattern to an **event-driven** one using EventBridge event patterns instead of `rate()` schedules.
- How to make automation **idempotent** using a deterministic resource ID (`INC-<finding_id>`) plus a DynamoDB conditional write, so a retried event can't create a duplicate incident.
- Why an EventBridge event payload should carry only routing information, while the authoritative record stays in DynamoDB — it keeps downstream consumers from acting on stale or incomplete event data.
- How splitting one shared IAM role into purpose-specific roles per Lambda makes it much easier to reason about (and fix) permission errors one function at a time.
- How to package a third-party Python dependency (`reportlab`) that isn't in the standard Lambda runtime, using a Lambda layer built for the Lambda Linux runtime.
- How to generate a PDF entirely in memory inside a Lambda function, avoiding any dependency on `/tmp` storage.
- How to aggregate across multiple DynamoDB tables into a single reporting window and keep two output formats (PDF and JSON) synchronized from the same source data.
- How to build a **data-driven control engine** — a validator registry (`{"table_exists": validate_table_exists, ...}`) keyed by a `"type"` string in JSON, so new compliance controls are added by editing `controls.json`, not by writing new Lambda code.
- Why write-immediately beats batch-at-the-end for evidence/audit trails: `boto3`'s `batch_writer()` only guarantees a flush when its `with` block exits (or every 25 buffered items) — switching to one `put_item()` call per control right after that control evaluates means a crash mid-run still leaves a durable record for everything already checked, at the cost of one API call per control instead of a batch.
- The difference between an **append-only evidence log** (one immutable record per control per run, for "why did this pass on this date") and a **current-state findings table** (a shrinking worklist of what's open right now, upserted by `control_id`) — and why you don't need the second one until something actually consumes it.
- Why `rate()` and `cron()` schedules answer different questions: `rate()` is simplest but starts counting from whenever the rule was enabled, so two independent `rate()` rules will drift relative to each other over time; `cron()` pins an exact UTC time, which is what you need when one scheduled job's output (the executive report) has to reliably exist before another scheduled job (the compliance check) runs.

### What struggles did you have while completing this project?
- Scoping IAM correctly for Bedrock: invoking Claude Haiku 4.5 requires authorizing *both* the foundation-model ARN and the cross-region inference-profile ARN (the `us.`-prefixed one) — missing either produces an `AccessDenied` on invoke.
- Remembering the one-time AWS Marketplace subscription step Bedrock needs before a third-party model can be invoked at all.
- The WAF logging destination naming rule: the CloudWatch log group **must** be prefixed `aws-waf-logs-`, or the logging configuration silently fails to attach.
- Timeout issue with Lambda Functions: have to set a timeout default is 3 seconds which isn't enough time to run the labs.
- Dynamodb table was not creating return items when when the WAF information was coming through.  How to make changes to the script to push it through.
- A broken cross-file Terraform reference on the SNS topic ARN (pointing at the wrong resource) caused `sns:Publish` calls from `soar_response_agent` to fail until it was corrected.
- Copy-pasted the `aws_cloudwatch_event_target` block for the new compliance schedule from the executive dashboard block and forgot to rename the resource — `terraform validate` failed with a duplicate resource address (`aws_cloudwatch_event_target.executive_dashboard` declared twice) until one was renamed.
- First attempt at offsetting the compliance schedule from the dashboard schedule used `rate(1 day, 1 hour)`, assuming `rate()` could combine units the way you'd read it in plain English — it can't; `rate()` only accepts a single `rate(value unit)` field. Switching to `cron()` for both schedules was the actual fix.
- A missing space in a hand-written `cron()` expression (`cron(0 22* * ? *)`) silently collapsed the hour and day-of-month fields into one malformed token, dropping the expression from the required 6 fields to 5 — AWS would have rejected it at `apply`, not `plan`, since schedule expression syntax is validated by the EventBridge API rather than Terraform itself.



### How Did You Save Money After Completing the Teardown?

To reduce cost, the infrastructure should be destroyed when the lab is complete — including emptying the S3 report bucket (both the `executive-reports/` and `compliance-reports/` prefixes), since `terraform destroy` won't remove a non-empty bucket by default.


---

## 10. References

**a. AWS / Terraform documentation**
- [AWS WAFv2 Web ACL — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl)
- [AWS WAFv2 Web ACL Rule — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_rule)
- [AWS WAFv2 Web ACL Association — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association)
- [AWS WAFv2 Logging Configuration — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration)
- [API Gateway REST API — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api)
- [API Gateway Method — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method)
- [API Gateway Integration — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration)
- [API Gateway Authorizer — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer)
- [Cognito User Pool — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool)
- [Cognito Resource Server — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server)
- [Cognito User Pool Client — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client)
- [DynamoDB Table — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table)
- [Lambda Function — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [CloudWatch Event Rule — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)
- [CloudWatch Log Group — Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)
- [Amazon Bedrock — Model Access & Permissions](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html#model-access-permissions)
- [Cross Region Inference](https://docs.aws.amazon.com/bedrock/latest/userguide/geographic-cross-region-inference.html)
- [Region Compatibility](https://docs.aws.amazon.com/bedrock/latest/userguide/models-region-compatibility.html)
- [Models Region Compatibility](https://docs.aws.amazon.com/bedrock/latest/userguide/models-region-compatibility.html)
- [ReportLab User Guide (PDF generation)](https://docs.reportlab.com/)
- [AWS Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html)
- [Amazon S3 PutObject API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html)
- [AWS Lambda Ephemeral Storage (/tmp)](https://docs.aws.amazon.com/lambda/latest/dg/configuration-ephemeral-storage.html)
- [Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html)
- [Lambda Layers 2](https://aws.amazon.com/blogs/compute/using-lambda-layers-to-simplify-your-development-process/)
- [EventBridge Schedule Patterns — rate() and cron() syntax](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html)
- [DynamoDB Table Resource — batch_writer (boto3)](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb/table/batch_writer.html)

---

## 11. Troubleshooting

![AccessDenied 1](./troubleshooting/01_AccessDenied.png)

## AWS Marketplace

`aws-marketplace:Subscribe` = Allows an IAM entity to subscribe to AWS Marketplace products, including Amazon Bedrock foundation models.

`aws-marketplace:ViewSubscriptions` = Allows an IAM identity to return a list of AWS Marketplace products, including Amazon Bedrock foundation models.

`aws-marketplace:Unsubscribe` = Allows an IAM identity to unsubscribe from AWS Marketplace products, including Amazon Bedrock foundation models.

Once any identity in your account successfully subscribes to this model (in any region), every role/user in the account can invoke it without marketplace permissions going forward
       
one-time AWS Marketplace subscription that Bedrock automatically tries to create the first time any identity in your account invokes a third-party model like Claude.

```      
Loose
{
  "Effect" : "Allow"
  "Action" : ["aws-marketplace:Subscribe",
  "aws-marketplace:ViewSubscriptions"
   ]
   Resource = "*"
}


Tighten 
{
  Effect = "Allow"
  Action = ["aws-marketplace:Subscribe", 
"aws-marketplace:ViewSubscriptions"]
  Resource = "*"
  Condition = {
    "ForAllValues:StringEquals" = {
      "aws-marketplace:ProductId" = ["<the specific product ID for this model>"]
    }
```

![AccessDenied 2](./troubleshooting/02_AccessDeniedRegion.png)

If you get this error with a model with cross-region inference profile: the us. prefix means Bedrock can route your request to any of several underlying regions (typically us-east-1, us-east-2, us-west-2) — not necessarily whichever region your Lambda itself runs in. 

When it does this the fix is widen the foundation-model resource to cover all regions the us. profile can use

This applies to the other regions as well eu and apac prefixes as well.

```
Hardcode Ex.
{
  "Effect" : "Allow"
  "Action" : ["bedrock:InvokeModel"],
  "Resource" : [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
    "arn:aws:bedrock:us-east-2::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
    "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
    "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
  ]
}

Wildcard Ex.
{
  "Effect" : "Allow"
  "Action" : ["bedrock:InvokeModel"],
  "Resource" : [
    "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-202,51001-v1:0"
    "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
  ]
}
```

![ValidationExecption](./troubleshooting/03_ValidationExecption.png)

when using a model with Cross-region inference the resource for the IAM needs 2 the foundational-model and the inference-profile and for the inference-profile the model need to have the us. prefix.  And when using the Environmental Variable and BEDROCK_MODEL_ID point it to the us. prefix model. ex:BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
The prefix also depends on the region you are using if it not in the US the us. prefix is incorrect. AWS group-level geographic prefixes are restricted to major multi-region zones like us (United States), eu (Europe), and apac (Asia-Pacific). 

```
{
        "Effect" : "Allow"
        "Action" : [
          "bedrock:InvokeModel"
        ],
        "Resource" : [ 
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0", "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0",
        ]
      }
```

![CorrelationError](./troubleshooting/04_CorrelationError.png)

This error is from the `waf_threat_corelation_agent.py`, its rejecting the float values and needs to go in as Decimal. 

change `decimal_to_native` to `native_to_decimal` on all of the `decimal_to_native` in the code

add this line into the code `findings_table.put_item(Item=native_to_decimal(item))`

```
# ============================================================
# Finding persistence
# ============================================================

def determine_overall_risk(
    evidence_package: dict[str, Any],
) -> tuple[int, str, str | None]:
    """Determine the highest deterministic risk in the window."""

    source_findings = evidence_package.get(
        "top_source_ips",
        [],
    )

    if not source_findings:
        return 0, "LOW", None

    highest = source_findings[0]

    return (
        highest.get("risk_score", 0),
        highest.get("severity", "LOW"),
        highest.get("source_ip"),
    )


def save_finding(
    evidence_package: dict[str, Any],
    bedrock_report: str,
) -> str:
    """Store the final correlation finding."""

    finding_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()

    risk_score, severity, primary_source_ip = (
        determine_overall_risk(evidence_package)
    )

    targeted_uris = evidence_package.get(
        "top_targeted_uris",
        [],
    )

    primary_target = (
        targeted_uris[0].get("uri")
        if targeted_uris
        else None
    )

    item = {
        "finding_id": finding_id,
        "created_at": created_at,
        "window_start": evidence_package[
            "analysis_window"
        ]["start"],
        "window_end": evidence_package[
            "analysis_window"
        ]["end"],
        "severity": severity,
        "risk_score": risk_score,
        "event_count": evidence_package["summary"][
            "total_events"
        ],
        "primary_source_ip": (
            primary_source_ip or "NONE"
        ),
        "primary_target": primary_target or "NONE",
        "status": "OPEN",
        "bedrock_report": bedrock_report,
        "evidence": evidence_package,
    }

    findings_table.put_item(Item=native_to_decimal(item))

    print(
        f"Saved correlation finding {finding_id} "
        f"with severity {severity}."
    )

    return finding_id
  ```

## Missing / Mismatched `reportlab` Layer

If `executive_dashboard_agent` fails immediately with `Unable to import module 'executive_dashboard_agent': No module named 'reportlab'`, the layer either isn't attached to the function or was built for the wrong platform. `reportlab` has to be `pip install`-ed for the Lambda Linux runtime (and matching architecture — `x86_64` vs `arm64`) before zipping it into a layer; a layer built on a local Windows or macOS machine without targeting `manylinux` won't work.

## Duplicate Terraform Resource Address

Copy-pasting a resource block to wire up a new schedule and forgetting to rename it produces:

```
Error: Duplicate resource "aws_cloudwatch_event_target" configuration
  A aws_cloudwatch_event_target resource named "executive_dashboard" was
  already declared at eventbridge.tf:164,1-56.
```

This happened when the `aws_cloudwatch_event_target` wired to the new `compliance_agent` rule kept the same resource name (`executive_dashboard`) as the one already wired to `dashboard_agent`. Terraform requires every `resource "<type>" "<name>"` address to be unique within a module — it isn't optional, and it fails at `terraform validate`/`plan`, before anything touches AWS. Fix: give the copy-pasted resource its own name (e.g. `compliance_dashboard` / `compliance_evidence`) that reflects what it actually targets.

## Invalid `rate()` Schedule Expression

```
schedule_expression = "rate(1 day, 1 hour)"   # invalid
```

Reads like plain English ("once a day plus an hour"), but AWS `rate()` expressions only accept a single `rate(value unit)` field — there's no way to combine units in one `rate()` string. This fails validation at `terraform apply` (Terraform itself doesn't parse the string; the EventBridge API rejects it when the rule is created). If you need two schedules offset from each other by a fixed amount, `rate()` is the wrong tool entirely, since each `rate()` rule starts counting from whenever *that* rule was enabled — two independent `rate()` clocks will drift relative to each other over time even if they start in sync. Use `cron()` on both rules instead, at two fixed UTC times.

## Malformed `cron()` Expression — Missing Field

```
schedule_expression = "cron(0 22* * ? *)"   # invalid — 5 fields, one malformed
schedule_expression = "cron(0 22 * * ? *)"  # valid — 6 fields
```

A missing space between the hour and the next field (`22*` instead of `22 *`) silently merges two fields into one malformed token. AWS `cron()` expressions require **exactly six** space-separated fields — `minutes hours day-of-month month day-of-week year` — and reject anything with more or fewer. This is easy to miss on review since `22*` still looks like a single plausible token at a glance; splitting the expression on spaces and counting fields is the fastest way to catch it before `apply`.

---

## 12. Useful Code

### Get Access Token

aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id <your id> \
  --auth-parameters USERNAME=<your username>,PASSWORD=<your password> \
  --region <your region>

### Use Token

curl -i -X Post https://abc123xyz9.execute-api.<your region>.amazonaws.com/<stage name> \-H "Authorization: Bearer"

### Create Lambda Layer Folder 

mkdir -p reportlab_layer/python

`mkdir` = make directory. It creates directories.

`-p` = parents. This option tells mkdir to: Create any missing parent directories.  Not produce an error if the directory already exists.

`layer_build/python` = the directory path to create name it what ever you want.

pip install -r requirements.txt \
  -t layer/python/ \
  --platform manylinux2014_x86_64 \
  --only-binary=:all: \
  --python-version 3.14

  `-t layer/python/` — installs packages into that folder instead of your global/venv site-packages

`--platform manylinux2014_x86_64 --only-binary=:all`: — critical if you're building on macOS/Windows or any non-Lambda Linux, since it forces pip to grab Linux-compatible wheels instead of compiling for your local OS. Skip this if you're building directly in a Lambda-like Linux container.

`--python-version 3.14` — match whatever runtime your Lambdas use

cd reportlab_layer

tar -a -c -f ../lambda_layer.zip python

`cd reportlab_layer`: changes the directory to this folder

`tar -a -c -f ../lambda_layer.zip python`: creates the zip folder ships with `Git Bash`

### Manually Invoke the Compliance Agent

aws lambda invoke \
  --function-name compliance-evidence-agent \
  --payload file://compliance_test_event.json \
  --cli-binary-format raw-in-base64-out \
  response.json

`--payload file://compliance_test_event.json` — passes `{"frameworks": ["NIST CSF 2.0", "CIS Controls v8"]}` as the event, overriding the `COMPLIANCE_FRAMEWORKS` environment default for just this invoke

`--cli-binary-format raw-in-base64-out` — required on AWS CLI v2 when passing a raw JSON payload file rather than a base64-encoded string

`response.json` — where the Lambda's return value (status code + summary body) is written; check CloudWatch Logs for the full per-control evaluation trail

## 13. Author & Contributors

- **Author:** Joe Tolliver
- **Group Leader:** Jaqcues Payne
- **Group Name:** TKO
- **Date / Version:** 8-11-2026 (Lab 12c)
