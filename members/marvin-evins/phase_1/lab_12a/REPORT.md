# Lab 12A Deliverable — SOAR Response
**Participant:** Marvin Evins  
**Phase:** 1  
**Status:** Completed / working pipeline evidence available

## Objective
Lab 12A extends the Armageddon security pipeline from detection and correlation into automated incident-response orchestration. The SOAR stage receives a correlated security finding, evaluates the finding, records an incident, and routes an analyst-facing notification when the playbook requires it.

## Implementation Summary
My implementation uses AWS Lambda, EventBridge, DynamoDB, Amazon Bedrock, SNS, CloudWatch, and Terraform. The response workflow is designed around a test security finding and a deterministic event path rather than destructive automated containment.

The tested Armageddon finding used `TEST-001`, a HIGH-severity credential-probing event with 150 suspicious requests from source IP `203.0.113.25`. The reasoning Lambda processed the finding with Amazon Bedrock and produced a security analysis. The SOAR response Lambda then received the completed reasoning event, created an incident record in DynamoDB, and published an SNS notification.

## Verified Workflow
1. Security finding enters the reasoning workflow.
2. Bedrock produces a human-readable security assessment.
3. EventBridge emits/routes a `ReasoningCompleted` event.
4. The SOAR response Lambda processes the event.
5. A security incident is written to DynamoDB.
6. SNS sends the analyst notification.
7. CloudWatch stores Lambda execution logs for audit/troubleshooting.

## Evidence to Submit
- Screenshot: SOAR reasoning Lambda invocation/result.
- Screenshot: SOAR response Lambda CloudWatch log showing the function was triggered.
- Screenshot: DynamoDB `security-incidents` item containing `finding_id = TEST-001`.
- Screenshot: EventBridge rule / event pattern connecting reasoning completion to response.
- Screenshot: SNS topic or confirmed notification (redact personal email address).
- Code evidence: SOAR Lambda source and Terraform for Lambda, EventBridge, DynamoDB, SNS, and IAM.

## Key Result
The key proof for Lab 12A is that a correlated/high-severity finding did not stop at detection. It moved into an automated response workflow, generated reasoning, created a persistent incident record, and triggered notification behavior.

## Security Note
The workflow preserves a human-review model and avoids destructive automated containment. This makes the automation demonstrable while reducing the risk of an agent independently taking irreversible action.
