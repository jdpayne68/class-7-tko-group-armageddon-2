import base64
import getpass
import json
import os
import uuid
from datetime import datetime, timezone

import boto3

# ==================================================
# CONFIGURATION
# ==================================================

REGION = os.getenv("AWS_REGION", "us-east-1")
API_BASE = os.getenv("API_BASE")
CLIENT_ID = os.getenv("COGNITO_PUBLIC_CLIENT_ID")
USERNAME = os.getenv("COGNITO_USERNAME")
TOKEN_TABLE_NAME = os.getenv("TOKEN_TABLE_NAME")


# ==================================================
# HELPERS
# ==================================================

def required(value, name):
    if value:
        return value
    raise SystemExit(f"Set the {name} environment variable before running this script.")


def decode_jwt(token):
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


def create_token_record(table_name, username):
    token_id = str(uuid.uuid4())
    issued_at = datetime.now(timezone.utc).isoformat()

    boto3.resource("dynamodb", region_name=REGION).Table(table_name).put_item(
        Item={
            "token_id": token_id,
            "username": username,
            "issued_at": issued_at,
            "used": False,
            "source": "get_token.py",
        }
    )

    return token_id


# ==================================================
# AUTHENTICATION
# ==================================================

api_base = required(API_BASE, "API_BASE")
client_id = required(CLIENT_ID, "COGNITO_PUBLIC_CLIENT_ID")
username = required(USERNAME, "COGNITO_USERNAME")
table_name = required(TOKEN_TABLE_NAME, "TOKEN_TABLE_NAME")
password = os.getenv("COGNITO_PASSWORD") or getpass.getpass("Password: ")

client = boto3.client("cognito-idp", region_name=REGION)
response = client.initiate_auth(
    ClientId=client_id,
    AuthFlow="USER_PASSWORD_AUTH",
    AuthParameters={"USERNAME": username, "PASSWORD": password},
)

if response.get("ChallengeName") == "SOFTWARE_TOKEN_MFA":
    response = client.respond_to_auth_challenge(
        ClientId=client_id,
        ChallengeName="SOFTWARE_TOKEN_MFA",
        Session=response["Session"],
        ChallengeResponses={
            "USERNAME": username,
            "SOFTWARE_TOKEN_MFA_CODE": input("MFA code: ").strip(),
        },
    )
elif response.get("ChallengeName"):
    raise SystemExit(
        f"Unhandled challenge {response['ChallengeName']}. Complete initial MFA enrollment with the lab runbook first."
    )

auth = response["AuthenticationResult"]
access_token = auth["AccessToken"]
token_id = create_token_record(table_name, username)

print("\nAccess token claims:\n")
print(json.dumps(decode_jwt(access_token), indent=2))
print("\nToken tracking ID:\n")
print(token_id)
print("\nProtected route tests:\n")

for route in ("jedi", "sith"):
    print(
        f'''curl "{api_base}/{route}?name=Chewbacca" \\
  -H "Authorization: Bearer {access_token}" \\
  -H "x-token-id: {token_id}"\n'''
    )
