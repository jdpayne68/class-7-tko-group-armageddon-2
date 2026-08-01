#!/usr/bin/env python3
"""
Cognito Token Retriever with Enhanced Logging
Combines the reliability of the working script with the rich features of the structure
"""

import boto3
import getpass
import base64
import json
import os
import sys
import time
from datetime import datetime, timezone
from typing import Optional, Dict, Any

# ==================================================
# CONFIGURATION
# ==================================================

REGION = os.getenv("AWS_REGION", "us-east-1")
API_BASE = os.getenv(
    "API_BASE",
    "https://a9x4k2m7qp.execute-api.us-east-1.amazonaws.com/prod",
)
JEDI_ROUTE = os.getenv("JEDI_ROUTE", "jedi")
SITH_ROUTE = os.getenv("SITH_ROUTE", "sith")
NAME_QUERY = "?name="
NAME = os.getenv("CHEWBACCA_NAME", "Chewbacca")

# ==================================================
# HEADERS & LOGGING
# ==================================================

class Colors:
    """ANSI color codes"""
    GREEN = "\033[92m"
    RED = "\033[91m"
    CYAN = "\033[96m"
    MAGENTA = "\033[95m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    WHITE = "\033[97m"
    BOLD = "\033[1m"
    RESET = "\033[0m"
    
    @classmethod
    def should_color(cls) -> bool:
        return sys.stdout.isatty() and os.getenv("TERM") != "dumb"


class Headers:
    """Header formatting functions"""
    
    @staticmethod
    def _color(text: str, color: str) -> str:
        if Colors.should_color():
            return f"{color}{text}{Colors.RESET}"
        return text
    
    @classmethod
    def header(cls, title: str, color: str = Colors.BOLD) -> None:
        """Main header with full width separator"""
        width = 60
        print(cls._color(f"\n{'=' * width}", color))
        print(cls._color(f"{title.center(width)}", color))
        print(cls._color(f"{'=' * width}", color))
    
    @classmethod
    def sub_header(cls, title: str, color: str = Colors.BLUE) -> None:
        """Sub header with dashes"""
        width = 50
        print(cls._color(f"\n{'-' * width}", color))
        print(cls._color(f"  {title}", color))
        print(cls._color(f"{'-' * width}", color))
    
    @classmethod
    def short_header(cls, title: str, color: str = Colors.CYAN) -> None:
        """Short header with single dash"""
        print(cls._color(f"\n--- {title} ---", color))


class Logger:
    """Enhanced logging with colors and structured output"""
    
    @staticmethod
    def _color(text: str, color: str) -> str:
        if Colors.should_color():
            return f"{color}{text}{Colors.RESET}"
        return text
    
    @classmethod
    def alert(cls, msg: str) -> None:
        """Alert message - only the [ALERT] tag is colored"""
        alert_tag = cls._color("[ALERT]", Colors.RED)
        print(f"{alert_tag} {msg}")
    
    @classmethod
    def info(cls, msg: str) -> None:
        """Info message - only the [INFO] tag is colored"""
        info_tag = cls._color("[INFO]", Colors.CYAN)
        print(f"{info_tag} {msg}")
    
    @classmethod
    def success(cls, msg: str) -> None:
        """Success message with checkmark"""
        print(cls._color(f"✅ {msg}", Colors.GREEN))
    
    @classmethod
    def error(cls, msg: str) -> None:
        """Error message with X"""
        print(cls._color(f"❌ {msg}", Colors.RED))
    
    @classmethod
    def warn(cls, msg: str) -> None:
        """Warning message - only the [WARN] tag is colored"""
        warn_tag = cls._color("[WARN]", Colors.YELLOW)
        print(f"{warn_tag} {msg}")
    
    @classmethod
    def step(cls, msg: str) -> None:
        """Step message - only the [STEP] tag is colored"""
        step_tag = cls._color("[STEP]", Colors.BLUE)
        print(f"\n{step_tag} {msg}")
    
    @classmethod
    def debug(cls, msg: str) -> None:
        """Debug message - only the [DEBUG] tag is colored"""
        if os.getenv("DEBUG", "false").lower() == "true":
            debug_tag = cls._color("[DEBUG]", Colors.YELLOW)
            print(f"{debug_tag} {msg}")


# ==================================================
# JWT HELPERS
# ==================================================

def decode_jwt(token: str) -> Optional[Dict[str, Any]]:
    """Decode a JWT token without validation"""
    try:
        payload = token.split(".")[1]
        payload += '=' * (-len(payload) % 4)
        decoded = base64.urlsafe_b64decode(payload)
        return json.loads(decoded)
    except Exception as e:
        Logger.debug(f"Failed to decode JWT: {e}")
        return None


def format_expiration(exp: int) -> tuple:
    """Format expiration time and calculate remaining time"""
    exp_time = datetime.fromtimestamp(exp, tz=timezone.utc)
    now = datetime.now(timezone.utc)
    remaining = exp_time - now
    return exp_time, remaining


def display_jwt_info(token: str, token_type: str) -> None:
    """Display JWT claims and information"""
    decoded = decode_jwt(token)
    if not decoded:
        return
    
    # ID TOKEN CLAIMS is subheader (BLUE), ACCESS TOKEN CLAIMS is subheader (MAGENTA)
    if token_type.upper() == "ID":
        Headers.sub_header(f"{token_type.upper()} TOKEN CLAIMS", Colors.BLUE)
    else:
        Headers.sub_header(f"{token_type.upper()} TOKEN CLAIMS", Colors.MAGENTA)
    
    print(json.dumps(decoded, indent=4))
    
    # Groups is short header
    groups = decoded.get("cognito:groups", [])
    if groups:
        Headers.short_header(f"Groups ({len(groups)})")
        for group in groups:
            print(f"  - {group}")
    
    # Expiration is short header
    exp = decoded.get("exp")
    if exp:
        exp_time, remaining = format_expiration(exp)
        Headers.short_header("Expiration")
        print(f"  Expires: {exp_time.strftime('%Y-%m-%d %H:%M:%S UTC')}")
        print(f"  Remaining: {remaining}")


# ==================================================
# AUTHENTICATION
# ==================================================

def authenticate(
    client_id: str,
    username: str,
    password: str,
    region: str = REGION
) -> Dict[str, Any]:
    """
    Authenticate with Cognito and handle MFA
    
    Returns:
        AuthenticationResult dictionary containing tokens
    """
    client = boto3.client("cognito-idp", region_name=region)
    
    Logger.step("Initiating authentication...")
    Logger.debug(f"Client ID: {client_id[:10]}...")
    Logger.debug(f"Username: {username}")
    Logger.debug(f"Region: {region}")
    
    try:
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": username,
                "PASSWORD": password
            }
        )
        
        challenge = response.get("ChallengeName")
        Logger.debug(f"Challenge: {challenge if challenge else 'None'}")
        
        # Handle MFA challenge
        if challenge == "SOFTWARE_TOKEN_MFA":
            Logger.warn("MFA code required")
            mfa_code = input("\nMFA code: ").strip()
            
            if not mfa_code:
                Logger.error("No MFA code entered")
                sys.exit(1)
            
            Logger.debug("Verifying MFA code...")
            response = client.respond_to_auth_challenge(
                ClientId=client_id,
                ChallengeName="SOFTWARE_TOKEN_MFA",
                Session=response["Session"],
                ChallengeResponses={
                    "USERNAME": username,
                    "SOFTWARE_TOKEN_MFA_CODE": mfa_code
                }
            )
            Logger.success("MFA verified successfully!")
        
        elif challenge:
            Logger.error(f"Unhandled challenge: {challenge}")
            Logger.debug(f"Response: {json.dumps(response, indent=2)}")
            sys.exit(1)
        
        if "AuthenticationResult" not in response:
            Logger.error("No AuthenticationResult in response")
            Logger.debug(f"Response: {json.dumps(response, indent=2)}")
            sys.exit(1)
        
        auth_result = response["AuthenticationResult"]
        Logger.success("Authentication successful!")
        
        return auth_result
        
    except Exception as e:
        error_msg = str(e)
        Logger.error(f"Authentication failed: {error_msg}")
        
        if "Incorrect username or password" in error_msg:
            Logger.warn("Username or password is incorrect")
            Logger.info("Current settings:")
            Logger.info(f"  Username: {username}")
            masked = password[0] + '*' * (len(password)-2) + password[-1] if len(password) > 1 else '***'
            Logger.info(f"  Password: {masked}")
        elif "MFA" in error_msg:
            Logger.warn("MFA issue - make sure you're entering the correct 6-digit code")
            Logger.info("  The code changes every 30 seconds, so enter it quickly!")
        
        raise


# ==================================================
# TOKEN DISPLAY
# ==================================================

def display_tokens(auth_result: Dict[str, Any]) -> None:
    """Display all tokens with their information"""
    
    id_token = auth_result.get("IdToken")
    access_token = auth_result.get("AccessToken")
    refresh_token = auth_result.get("RefreshToken")
    
    # Display ID Token
    if id_token:
        display_jwt_info(id_token, "ID")
        Logger.debug(f"ID Token (first 50 chars): {id_token[:50]}...")
    
    # Display Access Token
    if access_token:
        display_jwt_info(access_token, "ACCESS")
        Logger.debug(f"Access Token (first 50 chars): {access_token[:50]}...")
    
    if refresh_token:
        Logger.debug(f"Refresh Token (first 50 chars): {refresh_token[:50]}...")


def print_curl_commands(id_token: str, access_token: str) -> None:
    """Print curl commands for API testing"""
    
    # API TEST COMMANDS is header
    Headers.header("API TEST COMMANDS")
    
    # Using ID Tokens is subheader (BLUE)
    Headers.sub_header("Using ID Token", Colors.BLUE)
    
    # Jedi Route is short header (green)
    Headers.short_header("Jedi Route", Colors.GREEN)
    print(f'\n  curl "{API_BASE}/{JEDI_ROUTE}{NAME_QUERY}{NAME}" \\')
    print(f'    -H "Authorization: Bearer {id_token}"')
    
    # Sith Route is short header (red)
    Headers.short_header("Sith Route", Colors.RED)
    print(f'\n  curl "{API_BASE}/{SITH_ROUTE}{NAME_QUERY}{NAME}" \\')
    print(f'    -H "Authorization: Bearer {id_token}"')
    
    # Using Access Token is subheader (MAGENTA/Purple)
    Headers.sub_header("Using Access Token", Colors.MAGENTA)
    
    # Jedi Route is short header (green)
    Headers.short_header("Jedi Route", Colors.GREEN)
    print(f'\n  curl "{API_BASE}/{JEDI_ROUTE}{NAME_QUERY}{NAME}" \\')
    print(f'    -H "Authorization: Bearer {access_token}"')
    
    # Sith Route is short header (red)
    Headers.short_header("Sith Route", Colors.RED)
    print(f'\n  curl "{API_BASE}/{SITH_ROUTE}{NAME_QUERY}{NAME}" \\')
    print(f'    -H "Authorization: Bearer {access_token}"')


# ==================================================
# MAIN
# ==================================================

def main():
    """Main execution function"""
    
    # Main Header
    Headers.header("COGNITO TOKEN RETRIEVER", Colors.BOLD)
    
    # Get credentials - prompt if not set (borrowed from reference script)
    client_id = os.getenv("COGNITO_PUBLIC_CLIENT_ID")
    if not client_id:
        client_id = input("Public app client ID: ")
    
    username = os.getenv("COGNITO_USERNAME")
    if not username:
        username = input("Username: ")
    
    password = os.getenv("COGNITO_PASSWORD")
    if not password:
        password = getpass.getpass("Password: ")
    
    # Configuration Subheader (WHITE)
    Headers.sub_header("Configuration", Colors.WHITE)
    Logger.info(f"Region: {REGION}")
    Logger.info(f"Client ID: {client_id[:10]}...")
    Logger.info(f"Username: {username}")
    Logger.info(f"API Base: {API_BASE}")
    Logger.info(f"Jedi Route: {JEDI_ROUTE}")
    Logger.info(f"Sith Route: {SITH_ROUTE}")
    
    print()
    
    try:
        # Authenticate
        auth_result = authenticate(client_id, username, password)
        
        # Display tokens
        display_tokens(auth_result)
        
        # Curl commands
        id_token = auth_result.get("IdToken")
        access_token = auth_result.get("AccessToken")
        print_curl_commands(id_token, access_token)
        
        # Summary - subheader (WHITE)
        Headers.sub_header("SUMMARY", Colors.WHITE)
        Logger.success("Authentication completed successfully!")
        Logger.info(f"  ID Token:    {auth_result.get('IdToken', 'N/A')[:30]}...")
        Logger.info(f"  Access Token: {auth_result.get('AccessToken', 'N/A')[:30]}...")
        if auth_result.get('RefreshToken'):
            Logger.info(f"  Refresh Token: {auth_result['RefreshToken'][:30]}...")
        
        # Optional: Save token to file
        if os.getenv("SAVE_TOKEN", "false").lower() == "true":
            token_file = os.getenv("TOKEN_FILE", ".token")
            with open(token_file, "w") as f:
                json.dump(auth_result, f)
            Logger.info(f"Tokens saved to {token_file}")
        
        return 0
        
    except KeyboardInterrupt:
        Logger.warn("Cancelled by user")
        return 130
    except Exception as e:
        Logger.error(f"Unexpected error: {e}")
        if os.getenv("DEBUG", "false").lower() == "true":
            import traceback
            traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())