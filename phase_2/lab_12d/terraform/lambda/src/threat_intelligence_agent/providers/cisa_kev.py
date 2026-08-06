"""CISA Known Exploited Vulnerabilities provider."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

from typing import Any, Mapping

from .base import BaseThreatIntelProvider, Indicator, ProviderResult, ProviderStatus


class CisaKevProvider(BaseThreatIntelProvider):
    """Query CISA KEV for CVE exploitation status."""

    name = "cisa_kev"
    supported_indicator_types = {"CVE"}
    cache_ttl_hours = 12

    def __init__(self) -> None:
        self.url = os.environ.get(
            "CISA_KEV_URL",
            "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json",
        ).strip()

    def enrich(
        self,
        indicator: Indicator,
        *,
        context: Mapping[str, Any] | None = None,
    ) -> ProviderResult:
        try:
            with urllib.request.urlopen(self.url, timeout=10) as response:
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

        vulnerabilities = payload.get("vulnerabilities", [])
        if not isinstance(vulnerabilities, list):
            vulnerabilities = []

        cve = indicator.value.upper()
        match = next(
            (
                item
                for item in vulnerabilities
                if str(item.get("cveID", "")).upper() == cve
            ),
            None,
        )

        if not match:
            return self.result(indicator, status=ProviderStatus.NOT_FOUND)

        data = {
            "cve_id": cve,
            "known_exploited": True,
            "ransomware_associated": (
                str(match.get("knownRansomwareCampaignUse", "")).lower()
                in {"known", "yes", "true", "confirmed"}
            ),
            "known_ransomware_campaign_use": match.get("knownRansomwareCampaignUse"),
            "vendor_project": match.get("vendorProject"),
            "product": match.get("product"),
            "vulnerability_name": match.get("vulnerabilityName"),
            "date_added": match.get("dateAdded"),
            "due_date": match.get("dueDate"),
            "required_action": match.get("requiredAction"),
            "notes": match.get("notes"),
            "confidence": 95,
            "risk": "HIGH",
            "raw_provider_data": match,
        }

        return self.result(
            indicator,
            status=ProviderStatus.SUCCESS,
            data=data,
        )
