import json
import os
import logging
import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
MODEL_ID = os.getenv("MODEL_ID", "us.anthropic.claude-sonnet-4-6")

bedrock = boto3.client("bedrock-runtime", region_name=AWS_REGION)
events = boto3.client("events", region_name=AWS_REGION)
def call_claude(prompt: str, max_tokens: int = 500) -> str:
    try:
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": prompt}]
                }
            ]
        }

        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(body)
        )

        result = json.loads(response["body"].read())
        return result["content"][0]["text"]

    except (BotoCoreError, ClientError, KeyError) as e:
        logger.error(f"Claude invocation failed: {e}")
        return "SOAR Reasoning Error: Claude invocation failed."

def build_prompt(event_detail: dict) -> str:
    finding = event_detail.get("newImage", {})

    finding_id = event_detail.get("findingId", "Unknown")
    summary = event_detail.get("summary", "Unknown")

    severity = finding.get("severity", "Unknown")
    source_ip = finding.get("source_ip", "Unknown")
    attack_type = finding.get("attack_type", "Unknown")
    request_count = finding.get("request_count", "Unknown")
    username = finding.get("username", "Unknown")

    return (
        f"You are the SOAR reasoning engine for ARMAGEDDON.\n"
        f"Analyze the following security finding and produce a recommended action.\n\n"
        f"Finding ID: {finding_id}\n"
        f"Summary: {summary}\n"
        f"Severity: {severity}\n"
        f"Source IP: {source_ip}\n"
        f"Attack Type: {attack_type}\n"
        f"Request Count: {request_count}\n"
        f"Username: {username}\n\n"
        f"Provide:\n"
        f"- A short security summary\n"
        f"- Threat assessment\n"
        f"- A recommended SOAR action\n"
        f"- Confidence level (0-100%)\n"
        f"- Brief explanation for the analyst\n"
    )

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    detail = event.get("detail", {})
    if not detail:
        return {"error": "Missing event.detail"}

    prompt = build_prompt(detail)
    reasoning = call_claude(prompt)

    reasoning_event = {
    "findingId": detail.get("findingId"),
    "summary": detail.get("summary"),
    "timestamp": detail.get("timestamp"),
    "finding": detail.get("newImage", {}),
    "reasoning": reasoning
    }

    response = events.put_events(
        Entries=[
            {
                "Source": "armageddon.soar-reasoning",
                "DetailType": "ReasoningCompleted",
                "Detail": json.dumps(reasoning_event)
            }
        ]
    )

    logger.info(f"ReasoningCompleted event emitted: {json.dumps(response)}")

    return {
        "status": "reasoning-complete",
        "reasoning": reasoning,
        "findingId": detail.get("findingId")
    }