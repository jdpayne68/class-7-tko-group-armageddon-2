import json
import os
import boto3
import time

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["WAF_CORRELATION_FINDINGS_TABLE"])

events = boto3.client("events")

def lambda_handler(event, context):
    print("Threat Correlation triggered")

    item = {
        "finding_id": int(time.time()),
        "summary": "Test correlation finding",
        "timestamp": int(time.time() * 1000)
    }

    # write finding to DynamoDB
    table.put_item(Item=item)

    # emit FindingCreated event to EventBridge
    events.put_events(
        Entries=[
            {
                "Source": "armageddon.threat-correlation",
                "DetailType": "FindingCreated",
                "Detail": json.dumps({
                    "newImage": item,
                    "findingId": item["finding_id"],
                    "summary": item["summary"],
                    "timestamp": item["timestamp"]
                })
            }
        ]
    )

    return {"status": "ok", "written_item": item}
