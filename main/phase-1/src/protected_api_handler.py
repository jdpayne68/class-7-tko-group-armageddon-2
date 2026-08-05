"""Simple API Lambda protected by AWS WAF."""

import json
from typing import Any


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Return a small response so API Gateway traffic can be tested."""

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "Armageddon 2 protected API is running.",
            }
        ),
    }
