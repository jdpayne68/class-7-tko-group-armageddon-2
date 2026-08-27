from datetime import datetime, timezone
from uuid import uuid4

from providers import Indicator, CisaKevProvider

from models.enums import (
    IndicatorSource,
    IndicatorType,
    PlatformType,
    ProviderTrustLevel,
    ProviderType,
    ThreatCondition,
    ThreatConfidence,
    ThreatSeverity,
)

from models.evidence import (
    EvidenceContext,
    EvidenceIdentity,
    EvidenceIndicator,
    EvidenceSource,
    ThreatEvidence,
)


# ============================================================
# STEP 1 — Create something to investigate
# ============================================================

indicator = Indicator.create(
    value="CVE-2021-44228",
    indicator_type="CVE",
)


# ============================================================
# STEP 2 — Ask the external provider
# ============================================================

provider = CisaKevProvider()

result = provider.enrich(indicator)

print("\n=== PROVIDER RESULT ===")
print(result.to_dict())


# ============================================================
# STEP 3 — Translate ProviderResult into ThreatEvidence
# ============================================================

evidence = ThreatEvidence(
    identity=EvidenceIdentity(
        evidence_id=str(uuid4()),
        provider_name=result.provider,
        provider_type=ProviderType.GOVERNMENT,
        provider_platform=PlatformType.OTHER,
    ),

    indicator=EvidenceIndicator(
        indicator_type=IndicatorType.CVE,
        indicator_value=result.indicator,
        indicator_source=IndicatorSource.EXTERNAL_API,

        # CISA says this CVE is in KEV.
        # CISA does NOT tell us whether one of our machines
        # is currently vulnerable or unpatched.
        condition=ThreatCondition.OTHER,
    ),

    source=EvidenceSource(
        metadata={
            "provider_status": result.status,
            "provider_data": result.data,
        }
    ),

    context=EvidenceContext(
        # CISA KEV does not supply our Gen2X severity.
        severity=ThreatSeverity.UNKNOWN,

        # We directly observed the provider's result.
        confidence=ThreatConfidence.OBSERVED,

        # This is our trust classification for CISA.
        provider_trust=ProviderTrustLevel.HIGH,

        # Convert ProviderResult's Unix timestamp
        # into the datetime expected by ThreatEvidence.
        expires_at=datetime.fromtimestamp(
            result.expires_at,
            tz=timezone.utc,
        ),

        tags={
            "cisa-kev",
            "cve",
            "known-exploited",
        },

        notes=(
            "CISA KEV reports this CVE as a "
            "known exploited vulnerability."
        ),
    ),
)


# ============================================================
# STEP 4 — See the normalized evidence
# ============================================================

print("\n=== THREAT EVIDENCE ===")
print(evidence.describe())

print("\n=== SERIALIZED EVIDENCE ===")
print(evidence.to_dict())