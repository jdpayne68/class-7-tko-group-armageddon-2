"""MITRE ATT&CK technique provider."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

from typing import Any, Mapping

from .base import BaseThreatIntelProvider, Indicator, ProviderResult, ProviderStatus


class MitreAttackProvider(BaseThreatIntelProvider):
    """Resolve MITRE ATT&CK technique IDs to basic technique metadata."""

    name = "mitre_attack"
    supported_indicator_types = {"TECHNIQUE", "ATTACK_TECHNIQUE"}
    cache_ttl_hours = 168

    def __init__(self) -> None:
        self.url = os.environ.get("MITRE_STIX_URL", "").strip()

    def enrich(
        self,
        indicator: Indicator,
        *,
        context: Mapping[str, Any] | None = None,
    ) -> ProviderResult:
        if not self.url:
            return self.result(
                indicator,
                status=ProviderStatus.SUCCESS,
                data={
                    "matched_technique_ids": [indicator.value.upper()],
                    "confidence": 60,
                    "risk": "MEDIUM",
                    "note": "MITRE_STIX_URL is not configured; technique identity was preserved without external enrichment.",
                },
            )

        try:
            with urllib.request.urlopen(self.url, timeout=15) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            return self.result(
                indicator,
                status=ProviderStatus.ERROR,
                error=f"HTTP {error.code}: {error.reason}",
            )
        except Exception as error:  # noqa: BLE001 - provider failures are evidence, not fatal.
            return self.result(
                indicator,
                status=ProviderStatus.ERROR,
                error=f"{type(error).__name__}: {error}",
            )

        technique_id = indicator.value.upper()
        objects = payload.get("objects", []) if isinstance(payload, dict) else []

        for item in objects:
            if not isinstance(item, dict):
                continue

            external_refs = item.get("external_references", [])
            if not isinstance(external_refs, list):
                continue

            for ref in external_refs:
                if not isinstance(ref, dict):
                    continue

                if str(ref.get("external_id", "")).upper() == technique_id:
                    return self.result(
                        indicator,
                        status=ProviderStatus.SUCCESS,
                        data={
                            "matched_technique_ids": [technique_id],
                            "techniques": [
                                {
                                    "technique_id": technique_id,
                                    "name": item.get("name"),
                                    "description": item.get("description"),
                                    "url": ref.get("url"),
                                }
                            ],
                            "confidence": 80,
                            "risk": "MEDIUM",
                        },
                    )

        return self.result(indicator, status=ProviderStatus.NOT_FOUND)
