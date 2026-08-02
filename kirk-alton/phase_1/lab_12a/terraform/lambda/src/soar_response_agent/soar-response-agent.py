#!/usr/bin/env python3

import json
import math
import os
import re
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError


# ============================================================
# AWS clients
# ============================================================

dynamodb = boto3.resource("dynamodb")
bedrock_client = boto3.client("bedrock-runtime")
sns_client = boto3.client("sns")


# ============================================================
# Environment variables
# ============================================================

CORRELATION_FINDINGS_TABLE = os.environ[
    "CORRELATION_FINDINGS_TABLE"
]

SECURITY_INCIDENTS_TABLE = os.environ[
    "SECURITY_INCIDENTS_TABLE"
]

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

BEDROCK_MODEL_ID = os.environ.get(
    "BEDROCK_MODEL_ID",
    "anthropic.claude-3-haiku-20240307-v1:0",
)

ENABLE_BEDROCK = (
    os.environ.get("ENABLE_BEDROCK", "true").lower()
    == "true"
)

findings_table = dynamodb.Table(
    CORRELATION_FINDINGS_TABLE
)

incidents_table = dynamodb.Table(
    SECURITY_INCIDENTS_TABLE
)


# ============================================================
# Playbooks
# ============================================================

PLAYBOOKS = {
    "LOW": {
        "name": "RECORD_ONLY",
        "notify": False,
        "create_incident": True,
        "priority": 4,
        "description": (
            "Record the finding for historical analysis. "
            "No immediate analyst notification is required."
        ),
    },
    "MEDIUM": {
        "name": "NOTIFY_ANALYST",
        "notify": True,
        "create_incident": True,
        "priority": 3,
        "description": (
            "Create an incident and notify the security "
            "operations team for review."
        ),
    },
    "HIGH": {
        "name": "CREATE_AND_ESCALATE_INCIDENT",
        "notify": True,
        "create_incident": True,
        "priority": 2,
        "description": (
            "Create a high-priority incident and escalate "
            "the finding to the security operations team."
        ),
    },
    "CRITICAL": {
        "name": "REQUEST_URGENT_REVIEW",
        "notify": True,
        "create_incident": True,
        "priority": 1,
        "description": (
            "Create a critical incident and request urgent "
            "human review. No containment action is performed."
        ),
    },
}


# ============================================================
# Email-safe Markdown rendering
# ============================================================

REPORT_SECTION_HEADINGS = {
    "incident title",
    "soc alert",
    "manager summary",
    "analyst investigation checklist",
    "investigation checklist",
    "why this playbook was selected",
    "limitations and unknowns",
}

REPORT_SECTION_HEADING_ALIASES = {
    "analyst investigation checklist": (
        "Investigation Checklist"
    ),
}


def normalize_email_text(text: str) -> str:
    """Normalize generated text before email rendering."""
    return (
        text.replace("\r\n", "\n")
        .replace("\r", "\n")
        .replace("\u2014", "—")
        .replace("\u2013", "–")
        .replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\\_", "_")
    )


def strip_inline_markdown(text: str) -> str:
    """Convert common inline Markdown to email-safe plain text."""
    text = re.sub(r"!\[([^\]]*)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*(.*?)\*\*", r"\1", text)
    text = re.sub(r"__(.*?)__", r"\1", text)
    text = re.sub(r"(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)", r"\1", text)
    text = re.sub(r"(?<!_)_(?!_)(.*?)(?<!_)_(?!_)", r"\1", text)
    text = re.sub(r"\\([\\`*_{}\[\]()#+.!|-])", r"\1", text)
    return text.strip()


def is_markdown_rule(line: str) -> bool:
    """Return True for Markdown horizontal rules."""
    return bool(
        re.fullmatch(
            r"\s{0,3}([-*_])(?:\s*\1){2,}\s*",
            line,
        )
    )


def append_blank(lines: list[str]) -> None:
    """Append at most one blank line."""
    if lines and lines[-1] != "":
        lines.append("")


def is_report_section_heading(value: str) -> bool:
    """Return True for one of the fixed report section headings."""
    return value.strip().rstrip(":").lower() in REPORT_SECTION_HEADINGS


def normalize_report_section_heading(value: str) -> str:
    """Return the preferred display name for a report section."""

    normalized = value.strip().rstrip(":").lower()
    return REPORT_SECTION_HEADING_ALIASES.get(
        normalized,
        value.strip().rstrip(":"),
    )


def parse_markdown_to_email(text: str) -> str:
    """
    Render controlled Markdown as readable SNS/email plain text.

    The renderer intentionally removes Markdown structure instead of
    replacing it with more dividers. The outer email template already
    provides the visual frame.
    """
    if not text:
        return "No summary available."

    text = normalize_email_text(text)
    parsed_lines: list[str] = []

    for raw_line in text.split("\n"):
        line = raw_line.rstrip()
        stripped = line.strip()

        if not stripped:
            append_blank(parsed_lines)
            continue

        if is_markdown_rule(stripped):
            append_blank(parsed_lines)
            continue

        heading = re.match(
            r"^\s{0,3}(#{1,6})\s+(.+?)\s*$",
            stripped,
        )
        if heading:
            level = len(heading.group(1))
            heading_text = strip_inline_markdown(
                heading.group(2)
            ).rstrip(":")

            if (
                level == 1
                and heading_text.lower().startswith(
                    "incident response"
                )
            ):
                append_blank(parsed_lines)
                continue

            append_blank(parsed_lines)
            if is_report_section_heading(heading_text):
                parsed_lines.append(
                    email_section(
                        normalize_report_section_heading(
                            heading_text
                        )
                    )
                )
                append_blank(parsed_lines)
            else:
                parsed_lines.append(f"{heading_text}:")
            continue

        bold_only = re.match(
            r"^\s*\*\*(.+?)\*\*\s*$",
            stripped,
        )
        if bold_only:
            heading_text = strip_inline_markdown(
                bold_only.group(1)
            ).rstrip(":")

            append_blank(parsed_lines)
            if is_report_section_heading(heading_text):
                parsed_lines.append(
                    email_section(
                        normalize_report_section_heading(
                            heading_text
                        )
                    )
                )
                append_blank(parsed_lines)
            else:
                parsed_lines.append(heading_text)
            continue

        plain_heading = re.match(
            r"^(.+?):$",
            stripped,
        )
        if plain_heading and is_report_section_heading(
            plain_heading.group(1)
        ):
            append_blank(parsed_lines)
            parsed_lines.append(
                email_section(
                    normalize_report_section_heading(
                        strip_inline_markdown(
                            plain_heading.group(1)
                        )
                    ).upper()
                )
            )
            append_blank(parsed_lines)
            continue

        checkbox = re.match(
            r"^\s*[-*]\s+\[([ xX])\]\s+(.+)$",
            stripped,
        )
        if checkbox:
            checked = checkbox.group(1).lower() == "x"
            marker = "[x]" if checked else "[ ]"
            parsed_lines.append(
                "  "
                + marker
                + " "
                + strip_inline_markdown(
                    checkbox.group(2)
                )
            )
            continue

        bullet = re.match(
            r"^\s*[-*]\s+(.+)$",
            stripped,
        )
        if bullet:
            parsed_lines.append(
                "  - "
                + strip_inline_markdown(
                    bullet.group(1)
                )
            )
            continue

        numbered = re.match(
            r"^\s*(\d+)\.\s+(.+)$",
            stripped,
        )
        if numbered:
            parsed_lines.append(
                f"{numbered.group(1)}. "
                + strip_inline_markdown(
                    numbered.group(2)
                )
            )
            continue

        parsed_lines.append(strip_inline_markdown(line))

    rendered = "\n".join(parsed_lines).strip()
    rendered = re.sub(r"\n{3,}", "\n\n", rendered)
    return rendered or "No summary available."


def format_analyst_summary_for_email(summary_text: str) -> str:
    """Format the analyst summary for SNS/email readability."""
    return parse_markdown_to_email(summary_text)


EMAIL_CHARACTER_WIDTHS = {
    " ": 0.35,
    ":": 0.35,
    "-": 0.45,
    "/": 0.45,
    ".": 0.30,
    "I": 0.35,
    "J": 0.45,
    "L": 0.55,
    "F": 0.65,
    "T": 0.65,
    "A": 0.75,
    "B": 0.75,
    "C": 0.75,
    "D": 0.78,
    "E": 0.70,
    "G": 0.78,
    "H": 0.78,
    "K": 0.75,
    "N": 0.78,
    "O": 0.78,
    "P": 0.70,
    "Q": 0.78,
    "R": 0.75,
    "S": 0.70,
    "U": 0.78,
    "V": 0.75,
    "W": 1.05,
    "X": 0.75,
    "Y": 0.75,
    "Z": 0.70,
}

EMAIL_DECORATION_WIDTHS = {
    "*": 0.42,
    "-": 0.35,
    "═": 0.42,
    "─": 0.35,
}


def estimate_email_text_width(text: str) -> float:
    """Estimate proportional-font visual width for email headings."""

    return sum(
        EMAIL_CHARACTER_WIDTHS.get(
            character,
            0.70,
        )
        for character in text
    )


def estimate_decoration_length(
    heading: str,
    line_character: str,
) -> int:
    """Estimate divider length needed to visually match heading text."""

    text_width = estimate_email_text_width(heading)
    line_character_width = EMAIL_DECORATION_WIDTHS.get(
        line_character,
        0.40,
    )

    return max(
        len(heading),
        math.ceil(text_width / line_character_width),
    )


def decorated_heading(
    label: str,
    line_character: str,
) -> str:
    """Build a left-aligned heading for proportional email fonts."""

    heading = label.upper()
    line = line_character * estimate_decoration_length(
        heading,
        line_character,
    )

    return "\n".join(
        [
            line,
            heading,
            line,
        ]
    )


def email_header(title: str) -> str:
    """Build the preferred top-level email header."""
    return decorated_heading(title, "═")


def email_major_section(title: str) -> str:
    """Build a left-aligned major email section header."""
    return decorated_heading(f"{title}:", "═")


def email_section(title: str) -> str:
    """Build the preferred email section header."""
    return decorated_heading(f"{title}:", "─")


# ============================================================
# General helpers
# ============================================================

def utc_now() -> str:
    """Return the current UTC time in ISO-8601 format."""
    return datetime.now(timezone.utc).isoformat()


def decimal_to_native(value: Any) -> Any:
    """Convert DynamoDB Decimal values to Python numbers."""
    if isinstance(value, list):
        return [decimal_to_native(item) for item in value]
    if isinstance(value, dict):
        return {key: decimal_to_native(item) for key, item in value.items()}
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    return value


def normalize_severity(value: Any) -> str:
    """Validate and normalize a severity value."""
    severity = str(value or "LOW").upper()
    if severity not in PLAYBOOKS:
        print(f"Unknown severity '{severity}'. Defaulting to LOW.")
        return "LOW"
    return severity


# ============================================================
# EventBridge event parsing
# ============================================================

def extract_finding_id(event: dict[str, Any]) -> str:
    """Extract the finding ID from an EventBridge event."""
    detail = event.get("detail", {})
    finding_id = detail.get("finding_id") or event.get("finding_id")
    if not finding_id:
        raise ValueError("The event does not contain finding_id.")
    return str(finding_id)


# ============================================================
# Finding retrieval and validation
# ============================================================

def get_finding(finding_id: str) -> dict[str, Any]:
    """Retrieve the complete correlation finding."""
    print(f"Retrieving finding {finding_id}.")
    response = findings_table.get_item(
        Key={"finding_id": finding_id},
        ConsistentRead=True,
    )
    finding = response.get("Item")
    if not finding:
        raise ValueError(f"Finding {finding_id} does not exist.")
    return decimal_to_native(finding)


def validate_finding(finding: dict[str, Any]) -> None:
    """Validate that the finding can enter the SOAR workflow."""
    required_fields = ["finding_id", "severity", "created_at", "bedrock_report"]
    missing_fields = [field for field in required_fields if not finding.get(field)]
    if missing_fields:
        raise ValueError("Finding is missing required fields: " + ", ".join(missing_fields))
    
    current_status = str(finding.get("status", "OPEN")).upper()
    completed_statuses = {"RESPONSE_COMPLETED", "ESCALATED", "CLOSED", "RESOLVED"}
    if current_status in completed_statuses:
        raise AlreadyProcessedError(f"Finding is already in status {current_status}.")


class AlreadyProcessedError(Exception):
    """Raised when a finding has already been processed."""


# ============================================================
# Playbook selection
# ============================================================

def select_playbook(finding: dict[str, Any]) -> dict[str, Any]:
    """Select a response playbook deterministically."""
    severity = normalize_severity(finding.get("severity"))
    playbook = {**PLAYBOOKS[severity], "severity": severity}
    print(f"Selected playbook {playbook['name']} for severity {severity}.")
    return playbook


# ============================================================
# Bedrock informational enrichment
# ============================================================

def build_finding_context(finding: dict[str, Any], playbook: dict[str, Any]) -> dict[str, Any]:
    """Create a compact context object for Bedrock."""
    evidence = finding.get("evidence", {})
    return {
        "finding_id": finding.get("finding_id"),
        "created_at": finding.get("created_at"),
        "severity": playbook["severity"],
        "risk_score": finding.get("risk_score"),
        "primary_source_ip": finding.get("primary_source_ip"),
        "primary_target": finding.get("primary_target"),
        "event_count": finding.get("event_count"),
        "correlation_report": finding.get("bedrock_report"),
        "deterministic_findings": evidence.get("deterministic_findings", []),
        "selected_playbook": {
            "name": playbook["name"],
            "description": playbook["description"],
        },
    }


def call_bedrock(finding_context: dict[str, Any]) -> dict[str, Any]:
    """Generate informational response material using Bedrock."""
    # Check if using Nova model
    is_nova = "nova" in BEDROCK_MODEL_ID.lower() or "amazon" in BEDROCK_MODEL_ID.lower()

    prompt = f"""
You are assisting a Security Operations Center.

A deterministic SOAR workflow has already selected the response
playbook. You must not change the severity, risk score, evidence,
or selected playbook.

Threat finding:
{json.dumps(finding_context, indent=2, default=str)}

Create a response in controlled Markdown using exactly these
level-2 headings:

## Incident Title
## SOC Alert
## Manager Summary
## Investigation Checklist
## Why This Playbook Was Selected
## Limitations and Unknowns

Requirements:
- Preserve the exact report structure and headings listed above.
- Do not add, remove, rename, or reorder sections.
- Do not introduce any new top-level headings.
- Never use Markdown tables.
- Base the response only on the supplied evidence.
- Separate observed facts from possible interpretations.
- Favor bullet lists, nested bullets, and checklists over paragraphs.
- Use one- or two-sentence paragraphs only when bullets are not
  appropriate.
- Reduce verbosity. Write 30 to 40 percent shorter than a narrative
  incident report while preserving meaningful analysis.
- Make critical findings visible within 30 to 60 seconds of scanning.
- Put the most important indicators, affected resources, attack
  patterns, confidence, and operational impact first.
- Present observations before interpretation.
- Keep supporting details beneath the primary finding instead of
  embedding them in long paragraphs.
- Avoid narrative writing, background education, generic cybersecurity
  explanations, marketing language, repetition, and long introductory
  or concluding paragraphs.
- Do not restate the same evidence in multiple sections unless it is
  operationally necessary.
- Every sentence must present evidence, explain operational impact,
  support a conclusion, or recommend an action. Omit anything else.
- Write recommendations as an operational checklist, not documentation.
- Start recommended actions with strong verbs whenever possible.
- Use direct, evidence-driven, high-signal language.
- Do not claim that an exploit succeeded.
- Do not claim that the source IP is malicious unless the evidence
  explicitly proves that.
- Do not recommend automatic IP blocking, account disabling,
  credential revocation, or destructive containment.
- State clearly that a human analyst must review the finding.
- Do not include a top-level Incident Response heading.
- Do not include horizontal rules.
- Use Markdown checkboxes only for analyst checklist tasks.
""".strip()

    if is_nova:
        request_body = {
            "inferenceConfig": {
                "max_new_tokens": 1400,
                "temperature": 0.2,
                "top_p": 0.9
            },
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}]
                }
            ]
        }
    else:
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1400,
            "temperature": 0.2,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": prompt}]
                }
            ]
        }

    print(f"Invoking Bedrock model {BEDROCK_MODEL_ID}.")
    response = bedrock_client.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(request_body),
    )

    response_body = json.loads(response["body"].read())

    if is_nova:
        response_text = response_body.get("output", {}).get("message", {}).get("content", [{}])[0].get("text", "")
    else:
        content = response_body.get("content", [])
        response_text = content[0].get("text", "") if content else ""

    if not response_text:
        raise ValueError("Bedrock returned no response text.")

    print("Bedrock SOAR summary generated.")
    return {"generated": True, "model_id": BEDROCK_MODEL_ID, "text": response_text}


def create_fallback_summary(finding_context: dict[str, Any]) -> dict[str, Any]:
    """Create a deterministic fallback if Bedrock is disabled or unavailable."""
    severity = finding_context["severity"]
    finding_id = finding_context["finding_id"]
    source_ip = finding_context.get("primary_source_ip") or "unknown"
    target = finding_context.get("primary_target") or "unknown"
    event_count = finding_context.get("event_count") or 0
    playbook = finding_context["selected_playbook"]["name"]

    text = f"""
Incident Title:
{severity} WAF Threat Finding {finding_id}

SOC Alert:
The threat-correlation workflow identified {event_count} related
WAF event(s). The primary observed source IP was {source_ip}, and
the primary target was {target}.

Manager Summary:
A {severity.lower()}-severity correlation finding requires review
under playbook {playbook}.

Investigation Checklist:
1. Review the correlated WAF events.
2. Confirm the source IP and targeted resources.
3. Review API Gateway and application logs.
4. Check related authentication activity.
5. Document analyst conclusions.

Why This Playbook Was Selected:
The deterministic workflow selected {playbook} based on the
stored severity.

Limitations and Unknowns:
This summary does not prove successful exploitation. Human review
is required.
""".strip()

    return {"generated": False, "model_id": None, "text": text}


# ============================================================
# Incident creation
# ============================================================

def build_incident_id(finding_id: str) -> str:
    """Build a deterministic incident ID."""
    return f"INC-{finding_id}"


def create_incident(
    finding: dict[str, Any],
    playbook: dict[str, Any],
    response_summary: dict[str, Any],
) -> tuple[str, bool]:
    """Create the incident record."""
    finding_id = finding["finding_id"]
    incident_id = build_incident_id(finding_id)
    now = utc_now()

    # Format the analyst summary using the new parser
    formatted_summary = format_analyst_summary_for_email(response_summary["text"])

    incident = {
        "incident_id": incident_id,
        "finding_id": finding_id,
        "created_at": now,
        "updated_at": now,
        "severity": playbook["severity"],
        "priority": playbook["priority"],
        "status": "OPEN",
        "assigned_team": "SOC",
        "playbook": playbook["name"],
        "playbook_description": playbook["description"],
        "primary_source_ip": finding.get("primary_source_ip", "UNKNOWN"),
        "primary_target": finding.get("primary_target", "UNKNOWN"),
        "event_count": finding.get("event_count", 0),
        "risk_score": finding.get("risk_score", 0),
        "analyst_summary": formatted_summary,
        "bedrock_summary_generated": response_summary["generated"],
        "bedrock_model_id": response_summary["model_id"] or "NONE",
        "containment_performed": False,
        "human_review_required": True,
    }

    try:
        incidents_table.put_item(
            Item=incident,
            ConditionExpression="attribute_not_exists(incident_id)",
        )
        print(f"Created security incident {incident_id}.")
        return incident_id, True
    except ClientError as error:
        error_code = error.response.get("Error", {}).get("Code")
        if error_code == "ConditionalCheckFailedException":
            print(f"Incident {incident_id} already exists. Reusing existing incident.")
            return incident_id, False
        raise


# ============================================================
# SNS notification
# ============================================================

def publish_notification(
    finding: dict[str, Any],
    incident_id: str,
    playbook: dict[str, Any],
    response_summary: dict[str, Any],
) -> str | None:
    """Publish an informational SOC notification."""
    if not playbook["notify"]:
        print(f"Playbook {playbook['name']} does not require an SNS notification.")
        return None

    severity = playbook["severity"]
    subject = f"[{severity}] WAF Security Incident {incident_id}"

    # Format the analyst summary using the new parser
    formatted_summary = format_analyst_summary_for_email(response_summary["text"])

    message_parts = []
    
    # Header
    message_parts.append(
        email_header("WAF SECURITY INCIDENT")
    )
    message_parts.append("")
    
    # Incident metadata
    message_parts.append(f"INCIDENT: {incident_id}")
    message_parts.append(f"FINDING:  {finding['finding_id']}")
    message_parts.append(f"SEVERITY: {severity}")
    message_parts.append(f"RISK:     {finding.get('risk_score', 0)}/100")
    message_parts.append(f"PLAYBOOK: {playbook['name']}")
    message_parts.append("")
    message_parts.append(f"SOURCE IP:  {finding.get('primary_source_ip', 'UNKNOWN')}")
    message_parts.append(f"TARGET:     {finding.get('primary_target', 'UNKNOWN')}")
    message_parts.append(f"EVENTS:     {finding.get('event_count', 0)}")
    message_parts.append("")
    message_parts.append("HUMAN REVIEW REQUIRED: YES")
    message_parts.append("CONTAINMENT PERFORMED: NO")
    message_parts.append("")
    
    # Analyst summary
    message_parts.append(
        email_major_section("ANALYST SUMMARY")
    )
    message_parts.append("")
    message_parts.append(formatted_summary)
    message_parts.append("")
    
    # JSON payload
    message_parts.append(
        email_section("JSON PAYLOAD")
    )
    
    json_payload = {
        "incident_id": incident_id,
        "finding_id": finding['finding_id'],
        "severity": severity,
        "risk_score": finding.get('risk_score', 0),
        "playbook": playbook["name"],
        "source_ip": finding.get('primary_source_ip', 'UNKNOWN'),
        "target": finding.get('primary_target', 'UNKNOWN'),
        "event_count": finding.get('event_count', 0),
        "human_review_required": True,
        "containment_performed": False,
        "analyst_summary": formatted_summary,
    }
    
    message_parts.append(json.dumps(json_payload, indent=2, default=str))
    
    message = "\n".join(message_parts)

    response = sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject[:100],
        Message=message,
        MessageAttributes={
            "severity": {"DataType": "String", "StringValue": severity},
            "playbook": {"DataType": "String", "StringValue": playbook["name"]},
            "incident_id": {"DataType": "String", "StringValue": incident_id},
        },
    )

    message_id = response.get("MessageId")
    print(f"Published SNS notification {message_id}.")
    return message_id


# ============================================================
# Finding workflow update
# ============================================================

def update_finding_status(
    finding_id: str,
    incident_id: str,
    playbook: dict[str, Any],
    sns_message_id: str | None,
) -> None:
    """Mark the finding as processed by the SOAR workflow."""
    now = utc_now()

    expression_values = {
        ":response_status": "RESPONSE_COMPLETED",
        ":incident_id": incident_id,
        ":playbook": playbook["name"],
        ":processed_at": now,
        ":sns_message_id": sns_message_id or "NOT_SENT",
        ":open_status": "OPEN",
    }

    findings_table.update_item(
        Key={"finding_id": finding_id},
        UpdateExpression=(
            "SET #status = :response_status, "
            "incident_id = :incident_id, "
            "response_playbook = :playbook, "
            "response_processed_at = :processed_at, "
            "sns_message_id = :sns_message_id"
        ),
        ConditionExpression="attribute_not_exists(#status) OR #status = :open_status",
        ExpressionAttributeNames={"#status": "status"},
        ExpressionAttributeValues=expression_values,
    )

    print(f"Updated finding {finding_id} to RESPONSE_COMPLETED.")


# ============================================================
# Lambda handler
# ============================================================

def lambda_handler(
    event: dict[str, Any],
    context: Any,
) -> dict[str, Any]:
    """Process a correlated threat finding."""
    print("=" * 60)
    print("Starting SOAR Response Agent")
    print("=" * 60)

    print("Received event:")
    print(json.dumps(event, indent=2, default=str))

    try:
        finding_id = extract_finding_id(event)
        finding = get_finding(finding_id)

        print("Retrieved finding:")
        print(json.dumps(finding, indent=2, default=str))

        validate_finding(finding)

        playbook = select_playbook(finding)
        finding_context = build_finding_context(finding, playbook)

        if ENABLE_BEDROCK:
            try:
                response_summary = call_bedrock(finding_context)
            except Exception as bedrock_error:
                print("Bedrock enrichment failed. Using deterministic fallback.")
                print(f"Bedrock error: {type(bedrock_error).__name__}: {bedrock_error}")
                response_summary = create_fallback_summary(finding_context)
        else:
            print("Bedrock enrichment is disabled. Using deterministic fallback.")
            response_summary = create_fallback_summary(finding_context)

        print("\n===== SOAR RESPONSE SUMMARY =====")
        print(response_summary["text"])
        print("=================================\n")

        incident_id, incident_created = create_incident(
            finding=finding,
            playbook=playbook,
            response_summary=response_summary,
        )

        sns_message_id = publish_notification(
            finding=finding,
            incident_id=incident_id,
            playbook=playbook,
            response_summary=response_summary,
        )

        update_finding_status(
            finding_id=finding_id,
            incident_id=incident_id,
            playbook=playbook,
            sns_message_id=sns_message_id,
        )

        result = {
            "message": "SOAR response workflow completed.",
            "finding_id": finding_id,
            "incident_id": incident_id,
            "incident_created": incident_created,
            "severity": playbook["severity"],
            "playbook": playbook["name"],
            "notification_sent": sns_message_id is not None,
            "sns_message_id": sns_message_id,
            "bedrock_summary_generated": response_summary["generated"],
            "containment_performed": False,
            "human_review_required": True,
        }

        print("SOAR workflow result:")
        print(json.dumps(result, indent=2, default=str))

        return {"statusCode": 200, "body": json.dumps(result)}

    except AlreadyProcessedError as error:
        print(str(error))
        return {
            "statusCode": 200,
            "body": json.dumps({"message": str(error), "workflow_skipped": True}),
        }

    except (ClientError, BotoCoreError) as error:
        print(f"AWS service error: {type(error).__name__}: {error}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "SOAR workflow failed because an AWS service returned an error.",
                "error": str(error),
            }),
        }

    except Exception as error:
        print(f"Unexpected SOAR error: {type(error).__name__}: {error}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "SOAR response workflow failed.",
                "error": str(error),
            }),
        }
