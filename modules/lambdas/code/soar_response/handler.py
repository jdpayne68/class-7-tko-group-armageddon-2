import json
import os
import boto3

sns = boto3.client("sns")
topic_arn = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    print("SOAR Response triggered")

    sns.publish(
        TopicArn=topic_arn,
        Subject="SOAR Test Alert",
        Message="This is a test SOAR response alert."
    )

    return {"status": "ok", "alert": "sent"}
