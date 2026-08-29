import json
import os
import logging
import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
MODEL_ID = os.getenv("MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0")

bedrock = boto3.client("bedrock-runtime", region_name=AWS_REGION)

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
    event_type = event_detail.get("eventType", "Unknown")
    source_ip = event_detail.get("sourceIP", "Unknown")
    username = event_detail.get("username", "Unknown")
    severity = event_detail.get("severity", "Unknown")

    return (
        f"You are the SOAR reasoning engine for ARMAGEDDON.\n"
        f"Analyze the following security event and produce a recommended action.\n\n"
        f"Event Type: {event_type}\n"
        f"Source IP: {source_ip}\n"
        f"Username: {username}\n"
        f"Severity: {severity}\n\n"
        f"Provide:\n"
        f"- A short summary\n"
        f"- A recommended SOAR action\n"
        f"- Confidence level (0–100%)\n"
    )

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    detail = event.get("detail", {})
    if not detail:
        return {"error": "Missing event.detail"}

    prompt = build_prompt(detail)
    reasoning = call_claude(prompt)

    return {
        "reasoning": reasoning,
        "originalEvent": detail
    }
