"""AbuseIPDB provider for IP reputation enrichment."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request

from typing import Any, Mapping

from .base import BaseThreatIntelProvider, Indicator, ProviderResult, ProviderStatus


class AbuseIpDbProvider(BaseThreatIntelProvider):
    """Query AbuseIPDB for IP reputation data."""

    name = "abuseipdb"
    supported_indicator_types = {"IP", "IPV4", "IPV6"}

    def __init__(self) -> None:
        self.api_key = os.environ.get("ABUSEIPDB_API_KEY", "").strip()
        self.endpoint = os.environ.get(
            "ABUSEIPDB_ENDPOINT",
            "https://api.abuseipdb.com/api/v2/check",
        ).strip()
        self.max_age_days = os.environ.get("ABUSEIPDB_MAX_AGE_DAYS", "90")

    def enrich(
        self,
        indicator: Indicator,
        *,
        context: Mapping[str, Any] | None = None,
    ) -> ProviderResult:
        if not self.api_key:
            return self.result(
                indicator,
                status=ProviderStatus.ERROR,
                error="ABUSEIPDB_API_KEY is not configured.",
            )

        params = urllib.parse.urlencode(
            {
                "ipAddress": indicator.value,
                "maxAgeInDays": self.max_age_days,
                "verbose": "true",
            }
        )

        request = urllib.request.Request(
            f"{self.endpoint}?{params}",
            headers={
                "Accept": "application/json",
                "Key": self.api_key,
            },
            method="GET",
        )

        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return self.result(indicator, status=ProviderStatus.NOT_FOUND)
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

        data = payload.get("data", {}) if isinstance(payload, dict) else {}

        if not data:
            return self.result(indicator, status=ProviderStatus.NOT_FOUND)

        normalized = {
            "abuse_confidence_score": data.get("abuseConfidenceScore", 0),
            "total_reports": data.get("totalReports", 0),
            "distinct_reporting_users": data.get("numDistinctUsers", 0),
            "country_code": data.get("countryCode"),
            "domain": data.get("domain"),
            "isp": data.get("isp"),
            "usage_type": data.get("usageType"),
            "is_tor": data.get("isTor", False),
            "is_whitelisted": data.get("isWhitelisted", False),
            "last_reported_at": data.get("lastReportedAt"),
            "raw_provider_data": data,
        }

        return self.result(
            indicator,
            status=ProviderStatus.SUCCESS,
            data=normalized,
        )
