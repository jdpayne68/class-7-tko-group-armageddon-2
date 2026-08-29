import json
import os
import boto3
import time

s3 = boto3.client("s3")
bucket = os.environ["REPORTS_BUCKET"]

def lambda_handler(event, context):
    print("Executive Dashboard triggered")

    report = {
        "generated_at": int(time.time()),
        "summary": "Test executive report"
    }

    key = f"reports/test_report_{int(time.time())}.json"

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(report),
        ContentType="application/json"
    )

    return {"status": "ok", "report_key": key}
