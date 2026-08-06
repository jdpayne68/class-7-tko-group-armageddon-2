"""Base models and contracts for threat-intelligence providers."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Any, Mapping


class ProviderStatus(str, Enum):
    """Provider result status values consumed by the fusion engine."""

    SUCCESS = "SUCCESS"
    NOT_FOUND = "NOT_FOUND"
    ERROR = "ERROR"


@dataclass(frozen=True)
class Indicator:
    """Normalized threat-intelligence indicator."""

    value: str
    indicator_type: str

    @property
    def indicator_id(self) -> str:
        return f"{self.indicator_type.upper()}:{self.value}"

    def to_dict(self) -> dict[str, Any]:
        return {
            "indicator_id": self.indicator_id,
            "value": self.value,
            "indicator_type": self.indicator_type.upper(),
        }


@dataclass(frozen=True)
class ProviderResult:
    """Normalized provider response consumed by fusion and reporting."""

    provider: str
    indicator_id: str
    indicator: str
    indicator_type: str
    status: str
    retrieved_at: str
    data: Mapping[str, Any] = field(default_factory=dict)
    error: str | None = None
    expires_at: str | None = None

    def to_dict(self) -> dict[str, Any]:
        result = asdict(self)
        result["data"] = dict(self.data)
        return result

    def to_source_record(self) -> dict[str, Any]:
        return self.to_dict()


class BaseThreatIntelProvider:
    """Base class for provider implementations."""

    name = "base"
    supported_indicator_types: set[str] = set()
    cache_ttl_hours = 24

    def supports(self, indicator: Indicator) -> bool:
        return indicator.indicator_type.upper() in self.supported_indicator_types

    def enrich(
        self,
        indicator: Indicator,
        *,
        context: Mapping[str, Any] | None = None,
    ) -> ProviderResult:
        raise NotImplementedError

    def result(
        self,
        indicator: Indicator,
        *,
        status: ProviderStatus,
        data: Mapping[str, Any] | None = None,
        error: str | None = None,
        expires_at: str | None = None,
    ) -> ProviderResult:
        retrieved_at = utc_now_iso()
        return ProviderResult(
            provider=self.name,
            indicator_id=indicator.indicator_id,
            indicator=indicator.value,
            indicator_type=indicator.indicator_type.upper(),
            status=status.value,
            retrieved_at=retrieved_at,
            expires_at=expires_at or utc_offset_iso(hours=self.cache_ttl_hours),
            data=dict(data or {}),
            error=error,
        )


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def utc_offset_iso(*, hours: int) -> str:
    return (
        datetime.now(timezone.utc) + timedelta(hours=hours)
    ).isoformat().replace("+00:00", "Z")
