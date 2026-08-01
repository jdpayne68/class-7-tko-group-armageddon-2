import json
import os
import boto3
import time

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["WAF_EVENTS_TABLE"])

def lambda_handler(event, context):
    print("WAF Analyzer triggered")

    # Minimal test event
    item = {
        "event_id": str(int(time.time())),
        "message": "Test WAF event",
        "timestamp": int(time.time() * 1000)
    }

    table.put_item(Item=item)

    return {"status": "ok", "written_item": item}
