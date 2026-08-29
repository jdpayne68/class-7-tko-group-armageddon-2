# Lab 12 — Autonomous WAF-to-SOAR Security Pipeline on AWS

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC?logo=terraform&logoColor=white)
![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E6.0-FF9900?logo=amazonaws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-22.x-339933?logo=nodedotjs&logoColor=white)
![Bedrock](https://img.shields.io/badge/Bedrock-Claude%20Sonnet%204.5-8A63D2)
![WAF](https://img.shields.io/badge/WAF%20Effectiveness-252%2F254-success)
![ClickOps](https://img.shields.io/badge/ClickOps-0%25-success)

---

## Overview

This is the whole SEIR security pipeline, built in Terraform: a request comes in
off the internet, WAF decides whether it's hostile, Cognito decides who's
asking, RBAC decides what they're allowed to touch, and then — if anything
suspicious got logged — a chain of agents wakes up, correlates the evidence into
a finding, publishes that finding onto an event bus, and a SOAR agent picks it
up and opens an incident *without a human touching anything*. A separate agent
writes the executive report. Every AWS Console click from the ClickOps version
became a resource here. The only things created by hand are the two that
genuinely shouldn't live in code: Cognito users with permanent passwords, and
Bedrock model access.

```
                          Internet
                              │
                              ▼
                    ┌───────────────────┐
                    │      AWS WAF      │  common + SQLi + known-bad + rate-limit
                    └─────────┬─────────┘
                              │  hostile → 403, before anything downstream runs
                              ▼
                    ┌───────────────────┐
                    │  API Gateway v1   │  Cognito authorizer + Lambda authorizer
                    └─────────┬─────────┘
                              │  no token → 401 · not admin on /analyze → 403 at edge
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        /python (GET)    /node (GET)   /analyze (POST)
         any group        admins only    admins only (edge-enforced)
              │               │               │
              └───────┬───────┘               │
                      ▼                        ▼
          WAF logs → CloudWatch          on-demand analysis
                      │
                      ▼
        ┌──────────────────────────┐
        │  waf-bedrock-analyzer    │  normalize each event → DynamoDB
        └────────────┬─────────────┘
                     ▼
        ┌──────────────────────────┐
        │  waf-events (telemetry)  │
        └────────────┬─────────────┘
                     ▼
        ┌──────────────────────────┐
        │  threat-correlation-agent│  deterministic scoring → finding → PutEvents
        └────────────┬─────────────┘
                     ▼
              EventBridge bus
           (severity-routed rules)
                     ▼
        ┌──────────────────────────┐
        │  soar-response-agent     │  playbook → INCIDENT RECORD → SNS
        └────────────┬─────────────┘
                     ▼
        ┌──────────────────────────┐
        │  executive-dashboard     │  PDF + JSON → S3
        └──────────────────────────┘
```

The design principle running through all of it: **each stage reads from the
previous stage's output store, and the whole thing degrades gracefully.** If
Bedrock is unavailable, the deterministic security workflow — scoring, findings,
playbooks, incidents, reports — still runs end to end. The AI narrative is
enrichment layered on top, never the mechanism. (We learned to appreciate that
design decision the hard way. More on that below.)

---

## Requirements

| Thing | Version / Notes |
|---|---|
| Terraform | ≥ 1.5 |
| AWS CLI | v2, configured |
| Python | 3.9+ locally (helper scripts), 3.13 in Lambda |
| `boto3` | `python -m pip install boto3` — the scripts need it |
| Authenticator app | Google Authenticator, Authy, 1Password — for MFA (TOTP) |
| Bedrock model access | **Enabled by hand in the console.** Requires a valid payment method on the account. |
| A working AWS payment method | Not a joke. See the anecdotes. |

### The manual steps Terraform can't do

**Bedrock model access.** Console → Bedrock → Model access → enable Claude
Sonnet 4.5 (or whichever model you set in `variables.tf`). There is no API and
no Terraform resource for this. Skip it and the pipeline still runs with
`enable_bedrock = false` — you lose only the AI narrative.

**Cognito users.** Creating a user needs a permanent password, and a permanent
password in Terraform state is worse than a manual step. Users, their groups,
and their MFA enrolment are handled by the scripts.

---

## Folder Structure

```
lab12/
├── provider.tf              # AWS + archive providers, caller identity
├── variables.tf             # region, project, model id, thresholds, toggles
├── terraform.tfvars         # your values (bedrock_model_id lives here)
│
├── apigateway.tf            # REST API, 3 routes, Cognito authorizer, deployment
├── cognito.tf               # user pool, MFA (TOTP), RBAC groups, app client
├── waf.tf                   # Web ACL — 4 rule groups, association, logging+redaction
├── cloudwatch.tf            # all log groups + WAF log delivery policy
├── dynamodb.tf              # waf-events, correlation-findings, incidents, tokens
├── eventbridge.tf           # schedules + severity-routed finding rules
├── sns.tf                   # alert + critical-alert topics
├── s3.tf                    # executive report bucket (TLS-only, versioned)
├── bedrock.tf               # model ARN scoping (profiles + foundation models)
├── iam.tf                   # one least-privilege role per function
│
├── lambda-python.tf         # /python — greeting + token telemetry
├── lambda-node.tf           # /node   — admin-only, RBAC gate
├── lambda-authorizer.tf     # /analyze edge authorizer (JWT verify + admin gate)
├── lambda-analyzer.tf       # waf-bedrock-analyzer
├── lambda-correlation.tf    # waf-threat-correlation-agent
├── lambda-soar.tf           # soar-response-agent
├── lambda-dashboard.tf      # executive-dashboard-agent
├── lambda-detector.tf       # unused-token-detector (carried from lesson f/g)
├── outputs.tf
│
├── src/                     # handler code, packaged by archive_file
│   ├── python/  node/  authorizer/
│   ├── analyzer/  correlation/  soar/  dashboard/  detector/
│
└── scripts/
    ├── build_layer.sh       # builds reportlab + cryptography layers
    ├── enroll_user.sh        # create user + TOTP MFA + first token (with phone)
    ├── enroll_user_no_phone.sh   # same, phone-free pool
    ├── get_token.py          # authenticate → ID token (+ telemetry row)
    ├── verify_groups.py      # decode a token, show groups
    └── verify.sh             # full post-deploy verification
```

`src/` must sit beside the `.tf` files. `archive_file` resolves it relative to
the module and fails at **plan** time if it's missing — loud and early, which is
the point.

---

## Steps

### 1. Build the layers, then deploy

```bash
cd lab12
bash scripts/build_layer.sh    # reportlab (PDF) + cryptography (JWT verify)
terraform init
terraform apply
```

Two to three minutes.

### 2. Enable Bedrock, then create a user

Enable the model in the console (see Requirements). Then enrol a user — this
runs the whole create → password → TOTP → first-token sequence:

```bash
bash scripts/enroll_user_no_phone.sh admin_papa you@example.com admins
```

You'll add the printed secret to your authenticator app, type the code twice
(once to verify enrolment, once to log in), and get an **ID token**. Hold onto
it.

### 3. Prove the front door

```bash
API=$(aws apigateway get-rest-apis --query "items[?name=='ace-rest-api'].id" --output text)
URL="https://$API.execute-api.us-east-1.amazonaws.com/prod"

curl -s -o /dev/null -w '%{http_code}\n' "$URL/python"                                          # 401 — authorizer
curl -s -o /dev/null -w '%{http_code}\n' "$URL/python?name=%3Cscript%3Ealert(1)%3C/script%3E"   # 403 — WAF
curl -s "$URL/python?name=Chewbacca" -H "Authorization: $TOKEN"                                 # 200
```

401, 403, 200 — three codes, three layers.

### 4. Walk the pipeline

```bash
# generate traffic
for i in $(seq 1 8); do curl -s -o /dev/null "$URL/python?name=%3Cscript%3Ealert($i)%3C/script%3E"; curl -s -o /dev/null "$URL/admin?x=%27%20OR%201%3D1--"; done

# wait ~90s, then walk it (write to a file — Git Bash can't map /dev/stdout)
aws lambda invoke --function-name ace-waf-bedrock-analyzer --payload '{}' --cli-binary-format raw-in-base64-out out.json && cat out.json
aws lambda invoke --function-name ace-waf-threat-correlation-agent --payload '{"correlation_window_minutes":60}' --cli-binary-format raw-in-base64-out out.json && cat out.json
aws dynamodb scan --table-name ace-security-incidents --max-items 5
aws lambda invoke --function-name ace-executive-dashboard-agent --payload '{"report_period_hours":24}' --cli-binary-format raw-in-base64-out out.json && cat out.json
aws s3 ls s3://$(terraform output -raw report_bucket)/executive-reports/ --recursive
```

The money shot is the incidents scan: an `INC-` record that appeared with **no
manual trigger** proves the full `Correlation → EventBridge → SOAR` chain fired
on its own.

### 5. Verify everything

```bash
bash scripts/verify.sh
```

---

## Artifacts

Capture these for the report.

**The WAF report.** wafchecker.myapp against `$URL/python?name=test` returned
**252 / 254 blocked (403)**, with the single non-403 being a `405` — the API
correctly refusing a disallowed HTTP method, not a WAF bypass. Effectively zero
bypasses across SQLi, XSS, path traversal, SSRF, command injection, and the
rest. Export the HTML report and the CSV. This is the headline.

**The four-layer response test.** 401 (no token) / 403 (WAF) / 200 (authenticated)
/ 403-with-body (RBAC). Four rejections, four origins — the cleanest single
proof of defense-in-depth.

**The automatic incident.** The `INC-` record in `ace-security-incidents`,
appearing with no manual SOAR invocation. This is the architecture's whole
reason for existing.

**Terraform convergence.** `terraform plan` → "No changes. Your infrastructure
matches the configuration." plus `verify.sh` all-pass. Together they prove the
stack is complete and correct.

### Screenshots worth taking

| # | What | Where |
|---|---|---|
| 1 | `terraform apply` complete, resource count | terminal |
| 2 | wafchecker 252/254 result | browser |
| 3 | 401 / 403 / 200 side by side | terminal |
| 4 | WAF sampled requests showing a blocked payload | WAF console |
| 5 | `waf-events` rows | DynamoDB |
| 6 | correlation response with `event_published: true` | terminal |
| 7 | the `INC-` incident record | DynamoDB |
| 8 | executive PDF in S3 | S3 console |
| 9 | `verify.sh` all-pass | terminal |

---

## Teardown

```bash
terraform destroy
```

One gotcha, learned live: the reports bucket has **versioning enabled**, and S3
refuses to delete a non-empty versioned bucket. `destroy` will error on it with
`BucketNotEmpty`. Empty it first:

```bash
aws s3 rm s3://ace-reports-<account-id> --recursive
aws s3api delete-objects --bucket ace-reports-<account-id> \
  --delete "$(aws s3api list-object-versions --bucket ace-reports-<account-id> \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"
terraform destroy
```

Everything else tears down in under a minute. Cognito users vanish with the
pool; Bedrock access is account-level and stays enabled (costs nothing idle).

---

## References

Amazon Web Services. (2026). *Amazon Bedrock user guide: Supported foundation
models and inference profiles*.
https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html

Amazon Web Services. (2026). *Amazon Bedrock user guide: Model access*.
https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html

Amazon Web Services. (2026). *Amazon Cognito developer guide: TOTP software
token MFA*.
https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa-totp.html

Amazon Web Services. (2026). *Amazon EventBridge user guide: Events and event
patterns*.
https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-events.html

Amazon Web Services. (2026). *AWS WAF developer guide: Managed rule groups*.
https://docs.aws.amazon.com/waf/latest/developerguide/waf-managed-rule-groups.html

Amazon Web Services. (2026). *Amazon SNS developer guide: SMS sandbox*.
https://docs.aws.amazon.com/sns/latest/dg/sns-sms-sandbox.html

HashiCorp. (2026). *Terraform AWS provider: aws_wafv2_web_acl*.
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl

HashiCorp. (2026). *Terraform: Resource dependencies and targeting*.
https://developer.hashicorp.com/terraform/tutorials/state/resource-dependencies

---

## Troubleshooting

Read the error. Check CloudWatch. Check IAM. Verify Terraform. In that order.

### Which layer said no?

| Response | Origin | Did the Lambda run? |
|---|---|---|
| `403`, empty body | WAF | No |
| `401 Unauthorized` | Cognito authorizer | No |
| `403 {"error":"Access denied"}` | Lambda RBAC (or /analyze edge authorizer) | Depends |
| `502` | Handler crashed | Yes, badly |

### `{"message":"Unauthorized"}` on every authenticated call

You're sending the **access token**. The Cognito authorizer validates the **ID
token**. They look identical and both carry `cognito:groups`, but only the ID
token passes. `get_token.py` prints the ID token; decode with
`verify_groups.py` and confirm `token_use: id`, not `access`.

### `events_stored: 0, events_failed: N`

The analyzer read the events fine — the *store* is failing. Almost always
Bedrock: a model call throwing inside the per-event loop. Check the analyzer log
group. If Bedrock is denied, set `enable_bedrock = false` and re-apply; the
store no longer depends on the model.

### `Float types are not supported. Use Decimal types instead.`

Correlation returns a 500 with this on the finding write. DynamoDB takes
`Decimal`, not Python `float`, and the agent's computed ratios and spans are
floats nested inside the evidence blob. Fixed by converting the whole item
recursively before `put_item` (see `to_decimal` in the correlation and SOAR
agents). A genuine defect in the stock code — it fails for anyone.

### `Invalid phone number format` at InitiateAuth

A stale user from a previous run has a malformed `phone_number`. The enrol
script skips creation for existing users, so the bad attribute survives. Delete
the user and re-run:
`aws cognito-idp admin-delete-user --user-pool-id <pool> --username <name>`.

### MFA code never arrives (SMS)

New accounts sit in the SNS SMS sandbox — texts only reach verified numbers.
Use TOTP. The scripts default to it for exactly this reason.

### `SMS_MFA` challenge you can't answer

A verified phone made Cognito default to SMS. The enrol script detects this,
disables SMS for the user, and restarts on TOTP. If you're stuck, delete and
re-enrol.

### `could not archive missing directory: ./src/...`

`src/` isn't beside your `.tf` files. Plan-time failure, nothing was attempted.
Extract the full tree; don't cherry-pick `.tf` files.

### WAF logs empty after a blocked request

The log-delivery resource policy is missing. WAF reports logging as configured
and delivers nothing. Confirm with
`aws wafv2 get-logging-configuration --resource-arn <waf-arn>`.

### Reference to undeclared resource, building folder-by-folder

The IAM ↔ SNS ↔ EventBridge ↔ Lambda cluster references itself. It cannot be
added a file at a time — add the whole cluster together. See the anecdotes.

---

## The Anecdotes — a build in its own words

Every one of these actually happened. They're here because a build report that
only shows the clean path is lying by omission, and because the next person
(possibly future me) deserves to know where the tripwires are.

**The WAF that was 100% effective and also completely absent.** We spent the
better part of an afternoon testing a WAF that, it turned out, hadn't been
created yet. Every XSS payload returned 401 instead of the expected 403, and we
kept theorizing: wrong rule set? bad association? payload not matching? The
truth was dumber and more profound — there was no WAF in the request path at
all, so of course nothing got blocked; the 401 was just the authorizer doing its
job on an unauthenticated request. Lesson filed permanently: *you cannot test a
resource that doesn't exist, and "it's not blocking" and "it's not there" look
identical from a curl.*

**`incoke`.** One transposed letter cost a genuine minute of confusion before
the AWS CLI, bless it, printed "Maybe you meant: invoke." The machine was more
patient than the human that day.

**`/dev/stdout` and the Git Bash betrayal.** Every `aws lambda invoke` piped to
`/dev/stdout` died with `No such file or directory: '/proc/self/fd/1'`. Turns
out Git Bash's MSYS layer doesn't map `/dev/stdout` the way real Linux does. The
fix — write to `out.json`, then `cat` it — is so mundane it's almost insulting,
but we now do it reflexively.

**boto3 was installed. boto3 was not installed. Both were true.** `python -c
"import boto3"` succeeded. The script, three lines later, `ModuleNotFoundError`.
The culprit: `python` and `python3` on this Windows box are *different
interpreters*, and only one had the package. Schrödinger's dependency, resolved
by installing into the specific interpreter the script actually called.

**The access token that was valid, signed, correct, and wrong.** Authentication
worked flawlessly. Every API call came back `Unauthorized`. The token was real —
it just wasn't the *right* token. Cognito hands back three on login, and the
authorizer wants the ID token while our script proudly printed the access token.
A one-character fix (`AccessToken` → `IdToken`) ended a saga. Auth is a place
where "almost right" and "completely broken" are the same thing.

**The dependency knot that would not be sliced.** The plan was a beautiful
file-by-file build with a screenshot at each step. Reality: `iam.tf` needs
`sns.tf` needs `eventbridge.tf` needs the Lambdas needs the IAM roles. A perfect
little circle of mutual dependence that rejected every attempt to add one file
at a time. The build has three honest chunks, not eight tidy ones — foundation,
the entangled security core (applied as a unit, because it *is* a unit), and the
front door on top. Terraform resolves the whole graph at once; the moment you
hand-slice it, you inherit the ordering it was doing for you.

**`touch sns.tf`.** In a moment of optimism, an empty file was created to
satisfy a reference. Terraform read it, found nothing inside, and produced a
*new* error about what the empty file should have contained. Creating a file and
creating the *contents* of a file are, it turns out, different acts.

**The SMS code that would never come.** MFA insisted on texting a code to a
phone. AWS, meanwhile, keeps new accounts in an SMS sandbox where texts only go
to pre-verified numbers. We waited for a message that was never, ever coming.
The whole enrolment flow got rebuilt around TOTP, which needs no phone, no
sandbox, and no faith in the postal service of SMS.

**The final boss: a declined card.** After the WAF was hardened to 252/254,
after the auth chain was bulletproof, after the pipeline read sixteen events
clean — Bedrock returned `AccessDenied` on *every* model, including the Haiku
that had worked days before. Not an IAM problem. Not a model problem. A billing
problem. The single most sophisticated agentic security pipeline in the lab,
brought to a halt by an expired payment method. There is a lesson in here about
cloud architecture and there is a separate, funnier lesson about remembering to
update your card, and we choose to dwell on neither.

**The last bug, hiding behind the last bill.** With the card sorted and Bedrock
finally live, the analyzer stored its events clean and the correlation agent
ran — and returned a 500: `Float types are not supported. Use Decimal types
instead.` DynamoDB, it turns out, has strong opinions about numbers: it takes
`Decimal`, never Python `float`, and the correlation agent computes ratios and
time spans that come out as floats, buried deep in a nested evidence blob.
Chasing them one at a time would have been whack-a-mole; the fix was to walk the
whole finding recursively and convert every float before the write. One helper
function, and the finding saved, the event published, and the incident opened
itself. This one's a genuine defect in the stock lab code — it fails for anyone
who runs it — so it earned a spot in the troubleshooting table too. The lesson:
the pipeline can survive a missing model and a declined card, but it will not
survive a rogue float.

The one genuinely good thing to come out of that last disaster: it forced us to
actually finish the `enable_bedrock = false` graceful-degradation path — which
means the pipeline now provably runs its entire deterministic workflow with zero
dependency on a paid external model. A billing failure turned into a resilience
feature. We'll take it.

---

## Author

**Cautchy Bailly**

Built as the Terraform counterpart to the `BalericaAI/armageddon` SEIR
Foundations lab series — the WAF-to-SOAR agentic pipeline, deployed as one
stack, with every documented failure mode engineered out.

### Contributors

- Lab curriculum and architecture — SEIR Foundations, `BalericaAI/armageddon`
- Terraform implementation, defect analysis, hardening, and the debugging saga
  above — this repository

> "ClickOps proves it works. Terraform proves you can rebuild it."
> — and, added this build: *"Graceful degradation proves it survives the things
> you didn't plan for. Including your own credit card."*
