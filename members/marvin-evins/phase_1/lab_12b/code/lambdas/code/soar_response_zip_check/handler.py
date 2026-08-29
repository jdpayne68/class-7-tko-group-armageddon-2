import json
import os
import time
import boto3

sns = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")

sns_topic_arn = os.environ["SNS_TOPIC_ARN"]

incidents_table = dynamodb.Table(
    os.environ["SECURITY_INCIDENTS_TABLE"]
)


def lambda_handler(event, context):
    print("SOAR Response triggered")
    print(json.dumps(event))

    detail = event.get("detail", {})

    finding_id = detail.get("findingId")
    finding = detail.get("finding", {})
    original_summary = detail.get("summary", "No summary provided")
    reasoning = detail.get("reasoning", "No AI reasoning provided")

    incident_id = f"INC-{finding_id}"

    incident = {
        "incident_id": incident_id,
        "finding_id": finding_id,
        "status": "OPEN",
        "summary": original_summary,
        "reasoning": reasoning,
        "finding": finding,
        "created_at": int(time.time() * 1000)
    }

    incidents_table.put_item(Item=incident)

    message = f"""
ARMAGEDDON SECURITY INCIDENT

Incident ID:
{incident_id}

Finding:
{original_summary}

AI SOAR Analysis:
{reasoning}

Status:
OPEN
"""

    sns.publish(
        TopicArn=sns_topic_arn,
        Subject=f"ARMAGEDDON Security Incident {incident_id}",
        Message=message
    )

    return {
        "status": "incident-created",
        "incident_id": incident_id
    }