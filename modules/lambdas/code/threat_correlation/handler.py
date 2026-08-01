import json
import os
import boto3
import time

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["WAF_CORRELATION_FINDINGS_TABLE"])


def lambda_handler(event, context):
    print("Threat Correlation triggered")

    item = {
        "finding_id": str(int(time.time())),
        "summary": "Test correlation finding",
        "timestamp": int(time.time() * 1000)
    }

    table.put_item(Item=item)

    return {"status": "ok", "written_item": item}
