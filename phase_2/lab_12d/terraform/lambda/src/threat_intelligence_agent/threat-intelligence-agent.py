#!/usr/bin/env python3
"""
threat-intelligence-agent.py

Agent 10 orchestration Lambda for threat-intelligence enrichment.

Event contract
--------------
Preferred EventBridge event from the SOAR Response Agent:

{
  "source": "seir.soar",
  "detail-type": "Security Incident Created",
  "detail": {
    "incident_id": "INC-...",
    "finding_id": "...",
    "primary_source_ip": "73.166.82.125",
    "severity": "MEDIUM"
  }
}

Direct Lambda tests may pass the detail fields at the top level.

Responsibilities
----------------
- Extract or retrieve an indicator from the event context.
- Run compatible threat-intelligence providers.
- Fuse provider observations deterministically.
- Build JSON, Markdown, and console-friendly reports.
- Optionally store report artifacts and summary metadata.
- Optionally enrich the source incident with threat-intelligence status.

This handler does not perform containment or destructive response.
"""

from __future__ import annotations

import hashlib
import ipaddress
import json
import os
import re
import traceback

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Mapping

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from fusion import IntelligenceFusionEngine
from provider_registry import build_default_registry
from providers import Indicator, ProviderResult
from report import ThreatIntelligenceReportService


# ============================================================
# AWS clients
# ============================================================

dynamodb = boto3.resource("dynamodb")
s3_client = boto3.client("s3")


# ============================================================
# Environment variables
# ============================================================

THREAT_INTEL_REPORTS_TABLE = os.environ.get(
    "THREAT_INTEL_REPORTS_TABLE",
    "",
).strip()

SECURITY_INCIDENTS_TABLE = os.environ.get(
    "SECURITY_INCIDENTS_TABLE",
    "",
).strip()

CORRELATION_FINDINGS_TABLE = os.environ.get(
    "CORRELATION_FINDINGS_TABLE",
    "",
).strip()

REPORT_BUCKET = os.environ.get(
    "REPORT_BUCKET",
    "",
).strip()

REPORT_PREFIX = os.environ.get(
    "REPORT_PREFIX",
    "threat-intelligence",
).strip("/")

ENABLED_PROVIDERS = os.environ.get(
    "ENABLED_PROVIDERS",
    "",
).strip()

STORE_REPORTS = (
    os.environ.get("STORE_REPORTS", "true").lower()
    == "true"
)

UPDATE_INCIDENT = (
    os.environ.get("UPDATE_INCIDENT", "true").lower()
    == "true"
)

DEFAULT_INDICATOR_TYPE = os.environ.get(
    "DEFAULT_INDICATOR_TYPE",
    "IP",
).upper()


# ============================================================
# General helpers
# ============================================================

def utc_now() -> str:
    """Return the current UTC timestamp in ISO-8601 format."""

    return datetime.now(timezone.utc).isoformat()


def response(
    status_code: int,
    body: Mapping[str, Any],
) -> dict[str, Any]:
    """Build a Lambda proxy-style response."""

    return {
        "statusCode": status_code,
        "body": json.dumps(
            decimal_to_native(body),
            default=json_default,
        ),
    }


def json_default(value: Any) -> Any:
    """JSON fallback serializer."""

    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)

        return float(value)

    if hasattr(value, "to_dict"):
        return value.to_dict()

    return str(value)


def decimal_to_native(value: Any) -> Any:
    """Convert DynamoDB Decimals into native Python values."""

    if isinstance(value, list):
        return [decimal_to_native(item) for item in value]

    if isinstance(value, dict):
        return {
            key: decimal_to_native(item)
            for key, item in value.items()
        }

    if isinstance(value, Decimal):
        if value % 1 == 0:
            return int(value)

        return float(value)

    return value


def object_to_dict(value: Any) -> dict[str, Any]:
    """Convert compatible objects into dictionaries."""

    to_dict = getattr(value, "to_dict", None)

    if callable(to_dict):
        result = to_dict()

        if isinstance(result, dict):
            return decimal_to_native(result)

    if isinstance(value, dict):
        return decimal_to_native(value)

    return {"value": json_default(value)}


def normalize_enabled_providers(value: str) -> set[str] | None:
    """Parse the optional provider allow-list."""

    if not value:
        return None

    providers = {
        item.strip()
        for item in value.split(",")
        if item.strip()
    }

    return providers or None


def build_report_id(
    *,
    incident_id: str | None,
    finding_id: str | None,
    indicator: Indicator,
) -> str:
    """Build a deterministic report ID for retry-safe processing."""

    seed = "|".join(
        item
        for item in [
            incident_id,
            finding_id,
            indicator.indicator_id,
        ]
        if item
    )

    digest = hashlib.sha256(seed.encode("utf-8")).hexdigest()[:16]

    return f"TIR-{digest}"


# ============================================================
# Event contract parsing
# ============================================================

def parse_event_contract(
    event: Mapping[str, Any],
) -> dict[str, Any]:
    """
    Normalize EventBridge and direct-test events into one context.

    Preferred contract:
        source: seir.soar
        detail-type: Security Incident Created
        detail.incident_id
        detail.finding_id
        detail.primary_source_ip
    """

    detail = event.get("detail")

    if not isinstance(detail, Mapping):
        detail = event

    context = {
        "source": event.get("source") or detail.get("source"),
        "detail_type": (
            event.get("detail-type")
            or event.get("detail_type")
            or detail.get("detail-type")
            or detail.get("detail_type")
        ),
        "incident_id": detail.get("incident_id") or event.get("incident_id"),
        "finding_id": detail.get("finding_id") or event.get("finding_id"),
        "severity": detail.get("severity") or event.get("severity"),
        "raw_event": dict(event),
        "detail": dict(detail),
    }

    indicator = extract_indicator(detail)

    incident = {}
    finding = {}

    if not indicator and context["incident_id"]:
        incident = get_dynamodb_item(
            table_name=SECURITY_INCIDENTS_TABLE,
            key_name="incident_id",
            key_value=str(context["incident_id"]),
        )
        indicator = extract_indicator(incident)

    if not indicator and context["finding_id"]:
        finding = get_dynamodb_item(
            table_name=CORRELATION_FINDINGS_TABLE,
            key_name="finding_id",
            key_value=str(context["finding_id"]),
        )
        indicator = extract_indicator(finding)

    if not finding and context["finding_id"]:
        finding = get_dynamodb_item(
            table_name=CORRELATION_FINDINGS_TABLE,
            key_name="finding_id",
            key_value=str(context["finding_id"]),
        )

    if not incident and context["incident_id"]:
        incident = get_dynamodb_item(
            table_name=SECURITY_INCIDENTS_TABLE,
            key_name="incident_id",
            key_value=str(context["incident_id"]),
        )

    if not indicator:
        raise ValueError(
            "The event did not contain a supported threat-intelligence indicator."
        )

    context["indicator"] = indicator
    context["incident"] = incident
    context["finding"] = finding

    return context


def extract_indicator(
    data: Mapping[str, Any],
) -> Indicator | None:
    """Extract an indicator from direct fields or common incident fields."""

    indicator_value = None
    indicator_type = None

    indicator_object = data.get("indicator")

    if isinstance(indicator_object, Mapping):
        indicator_value = (
            indicator_object.get("value")
            or indicator_object.get("indicator")
        )
        indicator_type = (
            indicator_object.get("type")
            or indicator_object.get("indicator_type")
        )
    elif isinstance(indicator_object, str):
        indicator_value = indicator_object

    indicator_value = indicator_value or first_present(
        data,
        [
            "indicator_value",
            "primary_source_ip",
            "source_ip",
            "ip_address",
            "ip",
            "cve_id",
            "cve",
            "technique_id",
            "attack_technique",
        ],
    )

    indicator_type = indicator_type or first_present(
        data,
        [
            "indicator_type",
            "type",
        ],
    )

    if not indicator_value:
        return None

    value = str(indicator_value).strip()

    if not value:
        return None

    inferred_type = str(indicator_type or infer_indicator_type(value)).upper()

    return Indicator(
        value=value,
        indicator_type=inferred_type,
    )


def first_present(
    data: Mapping[str, Any],
    keys: list[str],
) -> Any:
    """Return the first non-empty field from a mapping."""

    for key in keys:
        value = data.get(key)

        if value not in (None, ""):
            return value

    return None


def infer_indicator_type(value: str) -> str:
    """Infer a supported indicator type from the indicator value."""

    try:
        ipaddress.ip_address(value)
        return "IP"
    except ValueError:
        pass

    if re.fullmatch(r"CVE-\d{4}-\d{4,}", value, flags=re.IGNORECASE):
        return "CVE"

    if re.fullmatch(r"T\d{4}(\.\d{3})?", value, flags=re.IGNORECASE):
        return "TECHNIQUE"

    return DEFAULT_INDICATOR_TYPE


# ============================================================
# Persistence helpers
# ============================================================

def get_dynamodb_item(
    *,
    table_name: str,
    key_name: str,
    key_value: str,
) -> dict[str, Any]:
    """Fetch a single DynamoDB item if the table is configured."""

    if not table_name or not key_value:
        return {}

    table = dynamodb.Table(table_name)
    result = table.get_item(
        Key={key_name: key_value},
        ConsistentRead=True,
    )

    return decimal_to_native(result.get("Item", {}))


def store_report_artifacts(
    *,
    report_id: str,
    report_json: str,
    report_markdown: str,
) -> dict[str, str]:
    """Store report renderings in S3 when configured."""

    if not STORE_REPORTS or not REPORT_BUCKET:
        return {}

    json_key = f"{REPORT_PREFIX}/{report_id}.json"
    markdown_key = f"{REPORT_PREFIX}/{report_id}.md"

    s3_client.put_object(
        Bucket=REPORT_BUCKET,
        Key=json_key,
        Body=report_json.encode("utf-8"),
        ContentType="application/json",
    )

    s3_client.put_object(
        Bucket=REPORT_BUCKET,
        Key=markdown_key,
        Body=report_markdown.encode("utf-8"),
        ContentType="text/markdown; charset=utf-8",
    )

    return {
        "report_bucket": REPORT_BUCKET,
        "json_s3_key": json_key,
        "markdown_s3_key": markdown_key,
    }


def store_report_record(
    *,
    report_id: str,
    context: Mapping[str, Any],
    summary: Mapping[str, Any],
    evidence: Mapping[str, Any],
    artifact_locations: Mapping[str, str],
) -> None:
    """Store report summary metadata in DynamoDB when configured."""

    if not STORE_REPORTS or not THREAT_INTEL_REPORTS_TABLE:
        return

    indicator = context["indicator"]
    table = dynamodb.Table(THREAT_INTEL_REPORTS_TABLE)

    item = {
        "report_id": report_id,
        "created_at": utc_now(),
        "incident_id": context.get("incident_id") or "NONE",
        "finding_id": context.get("finding_id") or "NONE",
        "indicator": indicator.value,
        "indicator_type": indicator.indicator_type,
        "overall_risk": summary.get("overall_risk", "UNKNOWN"),
        "overall_confidence": summary.get("overall_confidence", 0),
        "recommended_priority": summary.get("recommended_priority", "LOW"),
        "providers_consulted": evidence.get("providers_consulted", []),
        "successful_providers": evidence.get("successful_providers", []),
        "failed_providers": evidence.get("failed_providers", []),
        "report_bucket": artifact_locations.get("report_bucket", "NONE"),
        "json_s3_key": artifact_locations.get("json_s3_key", "NONE"),
        "markdown_s3_key": artifact_locations.get("markdown_s3_key", "NONE"),
    }

    table.put_item(Item=item)


def update_incident_record(
    *,
    context: Mapping[str, Any],
    report_id: str,
    summary: Mapping[str, Any],
    artifact_locations: Mapping[str, str],
) -> None:
    """Enrich the source incident with threat-intelligence metadata."""

    if not UPDATE_INCIDENT or not SECURITY_INCIDENTS_TABLE:
        return

    incident_id = context.get("incident_id")

    if not incident_id:
        return

    table = dynamodb.Table(SECURITY_INCIDENTS_TABLE)

    table.update_item(
        Key={"incident_id": str(incident_id)},
        UpdateExpression=(
            "SET threat_intel_report_id = :report_id, "
            "threat_intel_status = :status, "
            "threat_intel_risk = :risk, "
            "threat_intel_confidence = :confidence, "
            "threat_intel_priority = :priority, "
            "threat_intel_updated_at = :updated_at, "
            "threat_intel_json_s3_key = :json_key, "
            "threat_intel_markdown_s3_key = :markdown_key"
        ),
        ExpressionAttributeValues={
            ":report_id": report_id,
            ":status": "COMPLETED",
            ":risk": summary.get("overall_risk", "UNKNOWN"),
            ":confidence": summary.get("overall_confidence", 0),
            ":priority": summary.get("recommended_priority", "LOW"),
            ":updated_at": utc_now(),
            ":json_key": artifact_locations.get("json_s3_key", "NONE"),
            ":markdown_key": artifact_locations.get("markdown_s3_key", "NONE"),
        },
    )


# ============================================================
# Lambda handler
# ============================================================

def lambda_handler(
    event: dict[str, Any],
    context: Any,
) -> dict[str, Any]:
    """Run threat-intelligence enrichment for a SOAR incident."""

    print("=" * 60)
    print("Starting Threat Intelligence Agent")
    print("=" * 60)

    print("Received event:")
    print(json.dumps(event, indent=2, default=json_default))

    try:
        contract = parse_event_contract(event)
        indicator: Indicator = contract["indicator"]
        report_id = build_report_id(
            incident_id=(
                str(contract["incident_id"])
                if contract.get("incident_id")
                else None
            ),
            finding_id=(
                str(contract["finding_id"])
                if contract.get("finding_id")
                else None
            ),
            indicator=indicator,
        )

        enabled_providers = normalize_enabled_providers(ENABLED_PROVIDERS)

        print(
            "Threat intelligence target: "
            f"{indicator.indicator_type}:{indicator.value}"
        )

        registry = build_default_registry()
        provider_results = registry.enrich(
            indicator,
            context={
                "source": contract.get("source"),
                "detail_type": contract.get("detail_type"),
                "incident_id": contract.get("incident_id"),
                "finding_id": contract.get("finding_id"),
                "severity": contract.get("severity"),
                "incident": contract.get("incident", {}),
                "finding": contract.get("finding", {}),
            },
            enabled_providers=enabled_providers,
        )

        fusion_engine = IntelligenceFusionEngine()
        evidence, summary = fusion_engine.fuse_with_evidence(provider_results)

        report_service = ThreatIntelligenceReportService()
        report = report_service.create_report(
            indicator=indicator,
            summary=summary,
            evidence=evidence,
            provider_results=provider_results,
            metadata={
                "event_source": contract.get("source"),
                "event_detail_type": contract.get("detail_type"),
                "incident_id": contract.get("incident_id"),
                "finding_id": contract.get("finding_id"),
                "generated_by": "threat_intelligence_agent",
            },
        )
        report.report_id = report_id

        report_json = report_service.render_json(report)
        report_markdown = report_service.render_markdown(report)
        console_report = report_service.render_console(report)

        print("\n===== THREAT INTELLIGENCE SUMMARY =====")
        print(console_report)
        print("=======================================\n")

        summary_dict = summary.to_dict()
        evidence_dict = evidence.to_dict()
        provider_result_dicts = [
            object_to_dict(result)
            for result in provider_results
        ]

        artifact_locations = store_report_artifacts(
            report_id=report_id,
            report_json=report_json,
            report_markdown=report_markdown,
        )

        store_report_record(
            report_id=report_id,
            context=contract,
            summary=summary_dict,
            evidence=evidence_dict,
            artifact_locations=artifact_locations,
        )

        update_incident_record(
            context=contract,
            report_id=report_id,
            summary=summary_dict,
            artifact_locations=artifact_locations,
        )

        result = {
            "message": "Threat intelligence enrichment completed.",
            "report_id": report_id,
            "incident_id": contract.get("incident_id"),
            "finding_id": contract.get("finding_id"),
            "indicator": indicator.to_dict(),
            "summary": summary_dict,
            "evidence": evidence_dict,
            "provider_results": provider_result_dicts,
            "artifact_locations": artifact_locations,
            "stored": bool(artifact_locations or THREAT_INTEL_REPORTS_TABLE),
            "incident_updated": bool(
                UPDATE_INCIDENT
                and SECURITY_INCIDENTS_TABLE
                and contract.get("incident_id")
            ),
        }

        print("Threat intelligence workflow result:")
        print(json.dumps(result, indent=2, default=json_default))

        return response(200, result)

    except (ClientError, BotoCoreError) as error:
        print(
            "AWS service error: "
            f"{type(error).__name__}: {error}"
        )
        print(traceback.format_exc())

        return response(
            500,
            {
                "message": (
                    "Threat intelligence enrichment failed because "
                    "an AWS service returned an error."
                ),
                "error": str(error),
            },
        )

    except Exception as error:  # noqa: BLE001 - Lambda must return structured failures.
        print(
            "Unexpected threat intelligence error: "
            f"{type(error).__name__}: {error}"
        )
        print(traceback.format_exc())

        return response(
            500,
            {
                "message": "Threat intelligence enrichment failed.",
                "error": str(error),
            },
        )
