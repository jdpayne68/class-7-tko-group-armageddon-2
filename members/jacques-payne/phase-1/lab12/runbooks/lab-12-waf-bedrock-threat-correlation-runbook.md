# Lab 12 Runbook: AWS WAF, Amazon Bedrock, and Threat Correlation

## 1. Purpose

This lab deploys and validates a serverless AWS security-analysis workflow using Terraform.

The solution protects an Amazon API Gateway endpoint with AWS WAF, sends WAF telemetry to Amazon CloudWatch Logs, analyzes blocked requests with AWS Lambda and Amazon Bedrock, stores normalized events in Amazon DynamoDB, and correlates recent events into security findings.

The lab demonstrates:

- Infrastructure as code with Terraform
- API protection with AWS WAF
- Centralized security telemetry with CloudWatch Logs
- Event normalization and persistence with Lambda and DynamoDB
- Generative AI-assisted security analysis with Amazon Bedrock
- Deterministic threat scoring and event correlation
- Least-privilege IAM separation
- Reproducible validation and evidence collection

## 2. Architecture

The deployed workflow contains two related paths.

### Protected application path

```text
Client
  |
  v
AWS WAF
  |
  v
Amazon API Gateway
  |
  v
Protected API Lambda
```

AWS WAF evaluates requests before API Gateway invokes the protected application Lambda.

A deterministic lab rule blocks requests containing:

```text
x-lab-attack: true
```

Normal requests are allowed and return HTTP 200. Requests containing the test header are blocked with HTTP 403.

### Security-analysis path

```text
AWS WAF
  |
  v
CloudWatch Logs
  |
  v
WAF Analyzer Lambda
  |                  \
  v                   v
DynamoDB Events     Amazon Bedrock
  |
  v
Threat Correlation Lambda
  |                  \
  v                   v
DynamoDB Findings  Amazon Bedrock
```

The analyzer Lambda:

1. Reads recent blocked WAF events from CloudWatch Logs.
2. Normalizes relevant request and WAF attributes.
3. Creates deterministic event identifiers.
4. Stores new events in DynamoDB.
5. Sends each new event to Amazon Bedrock for security analysis.
6. Skips duplicate events already present in DynamoDB.

The correlation Lambda:

1. Reads recent normalized events from DynamoDB.
2. Groups related events by source and target.
3. Calculates a deterministic risk score.
4. Uses Amazon Bedrock to produce a narrative correlation report.
5. Stores the resulting finding in a separate DynamoDB table.

## 3. Repository Layout

```text
members/jacques-payne/phase-1/lab12/
├── evidence/
├── runbooks/
├── scripts/
├── src/
│   ├── protected_api_handler.py
│   ├── waf_bedrock_analyzer.py
│   └── waf_threat_correlation_agent.py
├── terraform/
└── test-events/
```

Terraform files use numeric prefixes to organize the configuration by responsibility:

```text
00-versions.tf
01-provider.tf
02-locals.tf
03-variables.tf
04-data.tf
10-dynamodb.tf
20-cloudwatch.tf
30-iam-lambda.tf
40-lambda-packaging.tf
41-lambda-application.tf
42-lambda-analyzer.tf
43-lambda-correlation.tf
50-api-gateway.tf
60-waf.tf
70-eventbridge-scheduler.tf
90-outputs.tf
```

## 4. Prerequisites

Required local tools:

- Terraform
- AWS CLI
- Python 3
- `curl`
- `jq`
- Git

The AWS CLI identity must have permission to create the resources defined by the Terraform configuration.

The Lambda runtime model identifier is:

```text
us.anthropic.claude-haiku-4-5-20251001-v1:0
```

The `us.` prefix identifies the US cross-Region inference profile.

First-time use of the model may require an account-level AWS Marketplace agreement. Marketplace subscription permissions should be granted temporarily to an authorized administrative identity, not to the Lambda execution roles.

The final foundation-model availability state should report:

```text
Agreement:     AVAILABLE
Authorization: AUTHORIZED
Entitlement:   AVAILABLE
Region:        AVAILABLE
```

The inference profile should report:

```text
Status: ACTIVE
Type:   SYSTEM_DEFINED
```

## 5. Local Configuration

Create a local Terraform variables file at:

```text
members/jacques-payne/phase-1/lab12/terraform/terraform.tfvars
```

This file is ignored by Git and must not be committed.

It defines values such as:

- AWS Region
- Bedrock inference-profile identifier
- Bedrock resource ARNs
- Whether scheduled execution is enabled

During manual validation, keep both schedules disabled:

```hcl
enable_schedules = false
```

This prevents the analyzer and correlation Lambda functions from running automatically while tests are being performed manually.

The project uses a local Terraform backend. Protect these generated files and never commit them:

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.tfplan
*.zip
.terraform/
```

The local state file is also required for the eventual controlled Terraform destroy.

## 6. Terraform Deployment

Initialize Terraform:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform init
```

Check Terraform formatting:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  fmt -check -recursive
```

Validate the configuration:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  validate
```

Create a saved deployment plan:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  plan \
  -out=lab12.tfplan
```

The initial plan created 30 managed resources:

```text
Plan: 30 to add, 0 to change, 0 to destroy.
```

Apply only the reviewed saved plan:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  apply lab12.tfplan
```

The initial deployment completed with:

```text
Apply complete! Resources: 30 added, 0 changed, 0 destroyed.
```

Terraform state can contain more entries than the managed-resource plan count because `terraform state list` also includes data sources.

Confirm the deployed Bedrock model configuration:

```bash
ANALYZER_NAME="$(
  terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
    output -raw analyzer_lambda_name
)"

CORRELATION_NAME="$(
  terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
    output -raw correlation_lambda_name
)"

aws lambda get-function-configuration \
  --region us-east-1 \
  --function-name "$ANALYZER_NAME" \
  --query 'Environment.Variables.BEDROCK_MODEL_ID' \
  --output text

aws lambda get-function-configuration \
  --region us-east-1 \
  --function-name "$CORRELATION_NAME" \
  --query 'Environment.Variables.BEDROCK_MODEL_ID' \
  --output text
```

Both functions should report:

```text
us.anthropic.claude-haiku-4-5-20251001-v1:0
```

Confirm that both EventBridge Scheduler schedules remain disabled:

```bash
SCHEDULE_GROUP="$(
  terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
    output -raw scheduler_schedule_group_name
)"

for SCHEDULE in \
  armageddon2-lab12-dev-analyzer \
  armageddon2-lab12-dev-correlation
do
  aws scheduler get-schedule \
    --region us-east-1 \
    --group-name "$SCHEDULE_GROUP" \
    --name "$SCHEDULE" \
    --query '[Name,State]' \
    --output text
done
```

Expected:

```text
armageddon2-lab12-dev-analyzer     DISABLED
armageddon2-lab12-dev-correlation  DISABLED
```

## 7. Validate the Protected API and AWS WAF

Retrieve the API URL from Terraform:

```bash
API_URL="$(
  terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
    output -raw api_invoke_url
)"
```

Test a normal request:

```bash
curl \
  --silent \
  --include \
  "$API_URL"
```

Expected result:

```text
HTTP 200
```

The protected Lambda should return a message indicating that the Armageddon 2 protected API is running.

Test the deterministic AWS WAF rule:

```bash
curl \
  --silent \
  --include \
  -H 'x-lab-attack: true' \
  "$API_URL"
```

Expected result:

```text
HTTP 403
```

The deterministic test header is used only to prove that the Web ACL is associated with the API Gateway stage and can block a known request.

Retrieve the WAF log-group name:

```bash
WAF_LOG_GROUP="$(
  terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
    output -raw waf_log_group_name
)"
```

Inspect recent blocked events:

```bash
aws logs filter-log-events \
  --region us-east-1 \
  --log-group-name "$WAF_LOG_GROUP" \
  --filter-pattern '{ $.action = "BLOCK" }' \
  --output json
```

A successful blocked-event record includes values similar to:

```text
action:            BLOCK
terminatingRuleId: LabDeterministicBlock
httpMethod:        GET
uri:               /dev/analyze
```

WAF logs can contain client IP addresses, request identifiers, API hostnames, and account-specific ARNs. Sanitize that information before capturing or publishing evidence.

## 8. Validate the WAF Analyzer

The analyzer reads blocked WAF events from CloudWatch Logs, creates normalized event records, stores new records in DynamoDB, and invokes Amazon Bedrock for AI-assisted analysis.

Generate fresh blocked requests before each clean analyzer test:

```bash
REQUEST_START_MS=$(( $(date +%s) * 1000 ))

curl \
  --silent \
  --output /dev/null \
  --write-out 'HTTP status: %{http_code}\n' \
  -H 'x-lab-attack: true' \
  "$API_URL"
```

Expected:

```text
HTTP status: 403
```

Wait until the event appears in CloudWatch Logs:

```bash
EVENT_COUNT=0

for ATTEMPT in {1..20}; do
  EVENT_COUNT="$(
    aws logs filter-log-events \
      --region us-east-1 \
      --log-group-name "$WAF_LOG_GROUP" \
      --start-time "$REQUEST_START_MS" \
      --filter-pattern '{ $.action = "BLOCK" }' \
      --output json |
    jq '.events | length'
  )"

  echo "Attempt $ATTEMPT: $EVENT_COUNT fresh blocked event(s)"

  if [[ "$EVENT_COUNT" -gt 0 ]]; then
    echo "Fresh WAF event is available."
    break
  fi

  sleep 15
done
```

Using JSON output and `jq` ensures the result is one integer even if the AWS CLI response is paginated.

Invoke the analyzer manually:

```bash
ANALYZER_RESPONSE="/tmp/lab12-analyzer-response.json"

aws lambda invoke \
  --region us-east-1 \
  --function-name "$ANALYZER_NAME" \
  --cli-binary-format raw-in-base64-out \
  --payload '{
    "source": "manual-validation",
    "task": "analyze-waf-events"
  }' \
  "$ANALYZER_RESPONSE"
```

Inspect the application response:

```bash
jq '
  {
    statusCode,
    body: (.body | fromjson)
  }
' "$ANALYZER_RESPONSE"
```

A successful response resembles:

```json
{
  "statusCode": 200,
  "body": {
    "message": "WAF event processing completed.",
    "events_found": 3,
    "events_stored": 3,
    "events_analyzed": 3,
    "events_failed": 0
  }
}
```

The successful validation criteria are:

```text
Lambda StatusCode:  200
FunctionError:       absent or null
events_stored:       at least 1
events_analyzed:     at least 1
events_failed:       0
```

The analyzer uses deterministic event identifiers and conditional DynamoDB writes. Events already present in the table are treated as duplicates and are not analyzed again.

## 9. Validate Threat Correlation

The correlation Lambda reads normalized WAF events from DynamoDB and requires a minimum number of events inside its configured time window.

The deployed default settings are:

```text
Minimum event count:       3
Correlation window:        60 minutes
Maximum events evaluated:  500
```

Generate at least three fresh blocked requests:

```bash
REQUEST_START_MS=$(( $(date +%s) * 1000 ))

for REQUEST_NUMBER in 1 2 3; do
  STATUS="$(
    curl \
      --silent \
      --output /dev/null \
      --write-out '%{http_code}' \
      -H 'x-lab-attack: true' \
      "$API_URL"
  )"

  echo "Request $REQUEST_NUMBER: HTTP $STATUS"
  sleep 2
done
```

All three requests should return:

```text
HTTP 403
```

Wait until CloudWatch contains all three events:

```bash
EVENT_COUNT=0

for ATTEMPT in {1..20}; do
  EVENT_COUNT="$(
    aws logs filter-log-events \
      --region us-east-1 \
      --log-group-name "$WAF_LOG_GROUP" \
      --start-time "$REQUEST_START_MS" \
      --filter-pattern '{ $.action = "BLOCK" }' \
      --output json |
    jq '.events | length'
  )"

  echo "Attempt $ATTEMPT: $EVENT_COUNT fresh blocked event(s)"

  if [[ "$EVENT_COUNT" -ge 3 ]]; then
    echo "All three WAF events are available."
    break
  fi

  sleep 15
done
```

Invoke the analyzer once to normalize and store the new events before correlation:

```bash
ANALYZER_RESPONSE="/tmp/lab12-analyzer-correlation-test.json"

aws lambda invoke \
  --region us-east-1 \
  --function-name "$ANALYZER_NAME" \
  --cli-binary-format raw-in-base64-out \
  --payload '{
    "source": "manual-validation",
    "task": "analyze-waf-events"
  }' \
  "$ANALYZER_RESPONSE"
```

Confirm that at least three events were stored and analyzed with no failures.

Invoke the threat-correlation Lambda:

```bash
CORRELATION_RESPONSE="/tmp/lab12-correlation-response.json"

aws lambda invoke \
  --region us-east-1 \
  --function-name "$CORRELATION_NAME" \
  --cli-binary-format raw-in-base64-out \
  --payload \
    fileb://members/jacques-payne/phase-1/lab12/test-events/lab12-correlation.json \
  "$CORRELATION_RESPONSE"
```

Inspect the application response:

```bash
jq '
  {
    statusCode,
    body: (
      if (.body | type) == "string"
      then (.body | fromjson)
      else .body
      end
    )
  }
' "$CORRELATION_RESPONSE"
```

A successful result resembles:

```json
{
  "statusCode": 200,
  "body": {
    "message": "Threat correlation completed.",
    "finding_created": true,
    "finding_id": "example-finding-uuid",
    "events_correlated": 6,
    "severity": "LOW",
    "risk_score": 25
  }
}
```

The exact event count, severity, and risk score depend on the events present within the correlation window.

The successful validation criteria are:

```text
Lambda StatusCode:    200
FunctionError:         absent or null
Application status:   200
finding_created:       true
events_correlated:     at least 3
error:                 absent
```

Do not publish the `primary_source_ip` value returned by the correlation Lambda.

## 10. Validate the Stored Correlation Finding

Retrieve the findings-table name:

```bash
FINDINGS_TABLE="$(
  terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
    output -raw correlation_findings_table_name
)"
```

Extract the finding ID from the Lambda response:

```bash
FINDING_ID="$(
  jq -r '
    .body
    | if type == "string" then fromjson else . end
    | .finding_id
  ' "$CORRELATION_RESPONSE"
)"
```

Retrieve only non-sensitive summary attributes:

```bash
aws dynamodb get-item \
  --region us-east-1 \
  --table-name "$FINDINGS_TABLE" \
  --key "{\"finding_id\":{\"S\":\"$FINDING_ID\"}}" \
  --projection-expression \
    "finding_id, created_at, #finding_status, severity, risk_score, event_count" \
  --expression-attribute-names \
    '{"#finding_status":"status"}' \
  --output json |
jq '{
  finding_id: .Item.finding_id.S,
  created_at: .Item.created_at.S,
  status: .Item.status.S,
  severity: .Item.severity.S,
  risk_score: (.Item.risk_score.N | tonumber),
  event_count: (.Item.event_count.N | tonumber)
}'
```

A successful stored finding resembles:

```json
{
  "finding_id": "example-finding-uuid",
  "created_at": "ISO-8601 timestamp",
  "status": "OPEN",
  "severity": "LOW",
  "risk_score": 25,
  "event_count": 6
}
```

This proves the complete security-analysis path:

```text
AWS WAF
  → CloudWatch Logs
  → Analyzer Lambda
  → DynamoDB event table
  → Amazon Bedrock
  → Correlation Lambda
  → DynamoDB findings table
```

## 11. DynamoDB Numeric Serialization

Boto3 does not accept Python `float` objects when serializing DynamoDB items.

The correlation evidence package contains calculated values, such as active time spans, that may be represented internally as Python floats.

The initial correlation attempt failed with:

```text
Float types are not supported. Use Decimal types instead.
```

The solution converts floats recursively immediately before the DynamoDB write:

```python
def to_dynamodb_compatible(value: Any) -> Any:
    """Recursively convert Python values for DynamoDB."""
    if isinstance(value, float):
        return Decimal(str(value))

    if isinstance(value, dict):
        return {
            key: to_dynamodb_compatible(item)
            for key, item in value.items()
        }

    if isinstance(value, list):
        return [
            to_dynamodb_compatible(item)
            for item in value
        ]

    if isinstance(value, tuple):
        return [
            to_dynamodb_compatible(item)
            for item in value
        ]

    return value
```

The converted structure is passed directly to DynamoDB:

```python
findings_table.put_item(
    Item=to_dynamodb_compatible(item)
)
```

Using `Decimal(str(value))` avoids copying ordinary binary floating-point artifacts into the DynamoDB number.

The conversion occurs only at the storage boundary. Earlier application logic can continue using normal Python floats for calculations and JSON communication with Amazon Bedrock.

## 12. Troubleshooting Lessons

### Bedrock legacy-model failure

The original Claude 3 Haiku model was active as an inference profile but was marked as legacy for this account because it had not been used recently.

The invocation returned an error indicating that the model should be replaced with an active Bedrock model.

Resolution:

1. Select Claude Haiku 4.5.
2. Update the Lambda environment variables.
3. Update the IAM Bedrock resource ARNs.
4. Create and review a Terraform plan.
5. Apply the saved plan.

### Cross-Region inference-profile identifier

Runtime inference uses:

```text
us.anthropic.claude-haiku-4-5-20251001-v1:0
```

The `us.` prefix identifies the US cross-Region inference profile and is required by this solution’s Lambda runtime configuration.

The foundation-model availability API uses the underlying foundation-model identifier:

```text
anthropic.claude-haiku-4-5-20251001-v1:0
```

These identifiers are used by different Bedrock operations and are not interchangeable.

### AWS Marketplace model agreement

A Haiku 4.5 invocation initially failed because the account had not completed the required AWS Marketplace agreement.

The error referenced:

```text
aws-marketplace:ViewSubscriptions
aws-marketplace:Subscribe
```

Resolution:

1. Temporarily attach `AWSMarketplaceManageSubscriptions` to the administrative user.
2. Invoke Claude Haiku 4.5 through the Bedrock playground.
3. Confirm that the agreement reports `AVAILABLE`.
4. Remove the temporary Marketplace policy.
5. Do not attach Marketplace permissions to the Lambda roles.

### Duplicate analyzer events

The analyzer creates deterministic event IDs and performs conditional DynamoDB writes.

Once an event is stored, a later invocation treats it as a duplicate and skips Bedrock analysis.

If event storage succeeds but Bedrock analysis fails, the same stored event is not automatically reanalyzed. After correcting the failure, generate a new blocked request and process the new event.

### AWS CLI pagination and zsh arithmetic

Using `--output text` with a paginated `filter-log-events` response can return more than one numeric value.

For example:

```text
1
0
```

A multiline value cannot be evaluated safely as a zsh integer.

Resolution:

```bash
aws logs filter-log-events \
  --region us-east-1 \
  --log-group-name "$WAF_LOG_GROUP" \
  --start-time "$REQUEST_START_MS" \
  --filter-pattern '{ $.action = "BLOCK" }' \
  --output json |
jq '.events | length'
```

This produces one integer after the complete JSON response is assembled.

## 13. Evidence Index

The following evidence demonstrates the completed Lab 12 workflow.

| File | Validation demonstrated |
|---|---|
| `01-terraform-commit-history.png` | Incremental Lab 12 implementation history |
| `02-bedrock-model-and-profile-access.png` | Haiku 4.5 agreement and active inference profile |
| `03-terraform-plan-complete.png` | Initial Terraform deployment plan |
| `04-terraform-apply-complete.png` | Successful initial infrastructure deployment |
| `05-terraform-state-and-disabled-schedules.png` | Terraform state and disabled schedules |
| `06-api-gateway-allowed-and-waf-blocked.png` | Allowed request and deterministic WAF block |
| `07-waf-blocked-event-log.png` | Blocked request recorded in CloudWatch Logs |
| `08-bedrock-enriched-analyzer-response.png` | Successful WAF analysis with Amazon Bedrock |
| `09-threat-correlation-finding-created.png` | Successful correlation finding creation |
| `10-dynamodb-correlation-finding.png` | Finding persisted in DynamoDB |
| `11-terraform-no-drift.png` | Configuration, state, and deployed resources aligned |
| `12-terraform-destroy-complete.png` | Planned final controlled cleanup evidence |

Evidence 12 is captured only after the runbook and architecture artifacts are reviewed and committed.

Before publishing any screenshot, redact:

- Personal email addresses
- AWS account IDs
- Client or source IP addresses
- API Gateway invocation URLs
- Account-specific ARNs
- Request IDs and session identifiers
- Credentials, tokens, and secrets

Resource names, model IDs, timestamps, HTTP status codes, finding UUIDs, and Terraform summaries may remain visible when they do not reveal protected account information.

## 14. Final Validation and Drift Check

Run Terraform formatting and validation:

```bash
TF_DIR="members/jacques-payne/phase-1/lab12/terraform"

terraform -chdir="$TF_DIR" \
  fmt -check -recursive

terraform -chdir="$TF_DIR" \
  validate
```

Validate Python syntax without generating bytecode:

```bash
python3 <<'PY'
from pathlib import Path

source_directory = Path("members/jacques-payne/phase-1/lab12/src")

for path in sorted(source_directory.glob("*.py")):
    compile(
        path.read_text(),
        str(path),
        "exec",
    )
    print(f"Validated: {path}")
PY
```

Check the repository diff for whitespace errors:

```bash
git diff --check
```

Perform a final privacy-safe Terraform drift check:

```bash
PLAN_FILE="lab12-final-no-drift.tfplan"
PLAN_LOG="/tmp/lab12-final-no-drift.log"

terraform -chdir="$TF_DIR" \
  plan \
  -detailed-exitcode \
  -out="$PLAN_FILE" \
  > "$PLAN_LOG" 2>&1

PLAN_EXIT=$?

echo "FINAL TERRAFORM DRIFT CHECK"
echo "==========================="

case "$PLAN_EXIT" in
  0)
    echo "Result: No infrastructure changes detected."
    grep -E \
      'No changes\.|Your infrastructure matches the configuration\.' \
      "$PLAN_LOG"
    ;;
  1)
    echo "Result: Terraform plan failed."
    tail -n 20 "$PLAN_LOG"
    ;;
  2)
    echo "Result: Terraform detected pending changes."
    grep -E '^  # |^Plan:' "$PLAN_LOG"
    ;;
  *)
    echo "Result: Unexpected Terraform exit code: $PLAN_EXIT"
    ;;
esac
```

Terraform uses these detailed plan exit codes:

```text
0 = plan completed with no pending changes
1 = Terraform encountered an error
2 = plan completed with pending changes
```

The required final result is:

```text
Result: No infrastructure changes detected.
No changes. Your infrastructure matches the configuration.
```

## 15. Architecture Artifacts

Lab 12 uses two architecture files:

```text
members/jacques-payne/phase-1/lab12/architecture/
├── lab-12-waf-bedrock-threat-correlation-architecture.excalidraw
└── lab-12-waf-bedrock-threat-correlation-architecture.png
```

The `.excalidraw` file is the editable source of truth.

The SVG is the portable export for repository viewing and documentation.

The diagram should depict:

1. Client traffic entering AWS WAF.
2. AWS WAF protecting the API Gateway stage.
3. API Gateway invoking the protected API Lambda.
4. AWS WAF sending logs to CloudWatch Logs.
5. The analyzer Lambda reading recent WAF events.
6. The analyzer storing normalized events in DynamoDB.
7. The analyzer invoking the Haiku 4.5 inference profile.
8. The correlation Lambda reading the event table.
9. The correlation Lambda invoking the same inference profile.
10. The correlation Lambda writing findings to DynamoDB.
11. EventBridge Scheduler schedules connected to both processing functions.
12. Both schedules labeled `DISABLED BY DEFAULT`.

The diagram must distinguish:

- Synchronous application traffic
- Asynchronous security telemetry
- AI-assisted analysis
- Persistent event and finding storage
- Optional scheduled execution

## 16. Controlled Destroy

Do not destroy the environment until:

- Functional validation is complete.
- Evidence 01–11 has been reviewed and committed.
- The runbook is reviewed and committed.
- The editable Excalidraw diagram is committed.
- The exported SVG is committed.
- Terraform reports no drift.

Create a saved destroy plan:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  plan \
  -destroy \
  -out=lab12-destroy.tfplan
```

Review the plan summary and every resource marked for destruction.

Apply only the reviewed saved plan:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  apply lab12-destroy.tfplan
```

The expected ending resembles:

```text
Apply complete! Resources: 0 added, 0 changed, 30 destroyed.
```

The exact destroyed count must match the reviewed destroy plan.

Capture the privacy-safe completion summary as:

```text
12-terraform-destroy-complete.png
```

After the destroy, confirm Terraform manages no remaining resources:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  state list
```

No managed-resource addresses should be returned.

Run a final plan:

```bash
terraform -chdir=members/jacques-payne/phase-1/lab12/terraform \
  plan
```

The plan may propose recreating the environment because the configuration remains present while the deployed resources have been destroyed. That is expected for a reusable independently deployable lab.

Do not commit:

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.tfplan
*.zip
.terraform/
```

Retain the Terraform source, Lambda source, test events, runbook, diagram files, and approved evidence.

## 17. Authoritative References

- [Amazon Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html)
- [Amazon Bedrock inference profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles.html)
- [Amazon Bedrock geographic cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/geographic-cross-region-inference.html)
- [Boto3 DynamoDB type serializer](https://boto3.amazonaws.com/v1/documentation/api/latest/_modules/boto3/dynamodb/types.html)
- [Terraform plan command](https://developer.hashicorp.com/terraform/cli/commands/plan)

## 18. Completion Criteria

Lab 12 is complete when:

- Terraform formatting and validation pass.
- The protected API returns HTTP 200 for an allowed request.
- AWS WAF returns HTTP 403 for the deterministic test request.
- CloudWatch Logs records the blocked request.
- The analyzer stores and analyzes new events without failures.
- The correlation Lambda creates a finding from at least three recent events.
- DynamoDB contains the stored correlation finding.
- Terraform reports no drift before cleanup.
- Evidence 01–12 is reviewed and committed.
- The runbook and both architecture files are committed.
- The controlled Terraform destroy succeeds.
- The local Git working tree is clean.
