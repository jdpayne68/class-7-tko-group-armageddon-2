"""
fusion.py

Agent 10 — Threat Intelligence Fusion Engine

Purpose
-------
Combine normalized observations from multiple threat-intelligence providers
into one deterministic, provider-independent security assessment.

Processing model
----------------

    ProviderResult[]
            |
            v
    EvidenceAggregator
            |
            v
      ThreatEvidence
            |
            v
    ThreatPolicyEngine
            |
            v
       ThreatSummary

Architectural boundaries
------------------------

This module:

    - Aggregates normalized provider observations
    - Preserves supporting evidence
    - Calculates confidence
    - Calculates risk
    - Assigns investigation priority
    - Produces a provider-independent summary

This module does NOT:

    - Call external threat-intelligence APIs
    - Write to DynamoDB
    - Invoke Amazon Bedrock
    - Generate PDF reports
    - Perform automated remediation
    - Modify infrastructure

Providers collect facts.

The fusion engine converts those facts into an assessment.
"""

from __future__ import annotations

import logging

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from statistics import mean
from typing import Any, Iterable, Mapping, Protocol


LOGGER = logging.getLogger(__name__)


# ============================================================
# SECTION 1
# ENUMERATIONS
#
# These enumerations constrain the values that the fusion
# engine may produce.
#
# Using enums prevents inconsistent strings such as:
#
#     "High"
#     "HIGH"
#     "high"
#
# All downstream agents receive predictable values.
# ============================================================


class RiskLevel(str, Enum):
    """Normalized risk levels produced by the fusion engine."""

    UNKNOWN = "UNKNOWN"
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class PriorityLevel(str, Enum):
    """Normalized investigation priorities."""

    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class ProviderStatus(str, Enum):
    """Expected provider-result statuses."""

    SUCCESS = "SUCCESS"
    NOT_FOUND = "NOT_FOUND"
    ERROR = "ERROR"


# ============================================================
# SECTION 2
# PROVIDER RESULT CONTRACT
#
# The provider package may already contain a ProviderResult
# dataclass.
#
# This Protocol describes only the fields required by the
# fusion engine.
#
# The fusion engine therefore remains loosely coupled to the
# provider implementation.
# ============================================================


class ProviderResultProtocol(Protocol):
    """
    Minimum provider-result interface required by fusion.py.

    Any object with these attributes may be processed by the
    fusion engine.
    """

    provider: str
    indicator_id: str
    indicator: str
    indicator_type: str
    status: str
    retrieved_at: str
    data: Mapping[str, Any]
    error: str | None


# ============================================================
# SECTION 3
# SUPPORTING EVIDENCE MODELS
#
# ProviderEvidence records how each provider participated in
# the investigation.
#
# It preserves provenance without exposing every provider's
# entire raw response in the final summary.
# ============================================================


@dataclass(frozen=True)
class ProviderEvidence:
    """
    Audit-friendly record describing one provider contribution.
    """

    provider: str
    status: str
    retrieved_at: str | None

    confidence: int | None = None
    risk: str | None = None

    contributed_techniques: tuple[str, ...] = ()
    contributed_cves: tuple[str, ...] = ()

    known_exploited: bool = False
    error: str | None = None

    def to_dict(self) -> dict[str, Any]:
        """Return a JSON-serializable dictionary."""

        result = asdict(self)

        result["contributed_techniques"] = list(
            self.contributed_techniques
        )
        result["contributed_cves"] = list(
            self.contributed_cves
        )

        return result


# ============================================================
# SECTION 4
# THREAT EVIDENCE MODEL
#
# ThreatEvidence contains facts only.
#
# It contains no risk decision, no priority decision, and no
# recommendation.
#
# This separation allows another policy engine to evaluate the
# same evidence differently.
# ============================================================


@dataclass
class ThreatEvidence:
    """
    Normalized evidence gathered from all provider results.

    This object represents observations, not conclusions.
    """

    providers_consulted: set[str] = field(default_factory=set)

    successful_providers: set[str] = field(default_factory=set)
    not_found_providers: set[str] = field(default_factory=set)
    failed_providers: set[str] = field(default_factory=set)

    techniques: set[str] = field(default_factory=set)
    cves: set[str] = field(default_factory=set)

    confidence_scores: list[int] = field(default_factory=list)
    abuse_scores: list[int] = field(default_factory=list)

    provider_risks: list[str] = field(default_factory=list)

    known_exploited: bool = False
    ransomware_associated: bool = False
    tor_observed: bool = False
    whitelisted: bool = False

    total_reports: int = 0
    distinct_reporting_users: int = 0

    provider_evidence: dict[str, ProviderEvidence] = field(
        default_factory=dict
    )

    warnings: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        """
        Return a deterministic, JSON-serializable representation.

        Sets are sorted so repeated processing produces stable output.
        """

        return {
            "providers_consulted": sorted(self.providers_consulted),
            "successful_providers": sorted(self.successful_providers),
            "not_found_providers": sorted(self.not_found_providers),
            "failed_providers": sorted(self.failed_providers),
            "techniques": sorted(self.techniques),
            "cves": sorted(self.cves),
            "confidence_scores": list(self.confidence_scores),
            "abuse_scores": list(self.abuse_scores),
            "provider_risks": list(self.provider_risks),
            "known_exploited": self.known_exploited,
            "ransomware_associated": self.ransomware_associated,
            "tor_observed": self.tor_observed,
            "whitelisted": self.whitelisted,
            "total_reports": self.total_reports,
            "distinct_reporting_users": (
                self.distinct_reporting_users
            ),
            "provider_evidence": {
                provider: evidence.to_dict()
                for provider, evidence in sorted(
                    self.provider_evidence.items()
                )
            },
            "warnings": list(self.warnings),
        }


# ============================================================
# SECTION 5
# THREAT SUMMARY MODEL
#
# ThreatSummary is the public output of fusion.py.
#
# Future agents should consume this object instead of reading
# provider-specific schemas.
# ============================================================


@dataclass
class ThreatSummary:
    """
    Final provider-independent assessment produced by Agent 10.
    """

    overall_risk: str = RiskLevel.UNKNOWN.value
    overall_confidence: int = 0
    recommended_priority: str = PriorityLevel.LOW.value

    known_exploited: bool = False
    ransomware_associated: bool = False

    techniques: list[str] = field(default_factory=list)
    cves: list[str] = field(default_factory=list)

    sources_consulted: int = 0
    successful_sources: int = 0
    not_found_sources: int = 0
    failed_sources: int = 0

    supporting_reasons: list[str] = field(default_factory=list)
    limitations: list[str] = field(default_factory=list)

    analyzed_at: str = field(default_factory=lambda: utc_now_iso())

    policy_version: str = "gen2x-threat-policy-v1"

    def to_dict(self) -> dict[str, Any]:
        """Return a JSON-serializable summary."""

        return asdict(self)


# ============================================================
# SECTION 6
# POLICY CONFIGURATION
#
# Thresholds are stored in a configuration object instead of
# being scattered throughout the policy methods.
#
# An organization may later load these values from:
#
#     - Environment variables
#     - AWS Systems Manager Parameter Store
#     - AWS AppConfig
#     - A tenant-specific policy file
# ============================================================


@dataclass(frozen=True)
class ThreatPolicy:
    """
    Deterministic thresholds used by ThreatPolicyEngine.
    """

    policy_version: str = "gen2x-threat-policy-v1"

    high_abuse_score: int = 75
    medium_abuse_score: int = 25

    high_confidence: int = 85
    medium_confidence: int = 60

    high_report_count: int = 25
    medium_report_count: int = 5

    minimum_successful_sources_for_high_confidence: int = 2

    known_exploited_risk: RiskLevel = RiskLevel.HIGH
    known_exploited_priority: PriorityLevel = PriorityLevel.CRITICAL

    ransomware_priority: PriorityLevel = PriorityLevel.CRITICAL

    tor_minimum_risk: RiskLevel = RiskLevel.MEDIUM


# ============================================================
# SECTION 7
# EVIDENCE AGGREGATOR
#
# EvidenceAggregator converts many provider-specific results
# into one normalized ThreatEvidence object.
#
# It collects facts.
#
# It does not calculate overall risk or investigation priority.
# ============================================================


class EvidenceAggregator:
    """
    Aggregate provider observations into normalized evidence.
    """

    def aggregate(
        self,
        provider_results: Iterable[ProviderResultProtocol],
    ) -> ThreatEvidence:
        """
        Process provider results and return one ThreatEvidence object.

        A provider failure does not terminate fusion. Failures are
        recorded so the final summary can describe incomplete coverage.
        """

        evidence = ThreatEvidence()

        for result in provider_results:
            self._process_result(result, evidence)

        return evidence

    def _process_result(
        self,
        result: ProviderResultProtocol,
        evidence: ThreatEvidence,
    ) -> None:
        """Process one provider result."""

        provider_name = normalize_provider_name(result.provider)
        status = normalize_status(result.status)
        data = safe_mapping(result.data)

        evidence.providers_consulted.add(provider_name)

        if status == ProviderStatus.SUCCESS.value:
            evidence.successful_providers.add(provider_name)

        elif status == ProviderStatus.NOT_FOUND.value:
            evidence.not_found_providers.add(provider_name)

        else:
            evidence.failed_providers.add(provider_name)

        techniques = extract_techniques(data)
        cves = extract_cves(
            data=data,
            indicator=getattr(result, "indicator", None),
            indicator_type=getattr(result, "indicator_type", None),
        )

        evidence.techniques.update(techniques)
        evidence.cves.update(cves)

        confidence = extract_confidence(data)

        if confidence is not None:
            evidence.confidence_scores.append(confidence)

        abuse_score = extract_integer(
            data.get("abuse_confidence_score"),
            minimum=0,
            maximum=100,
        )

        if abuse_score is not None:
            evidence.abuse_scores.append(abuse_score)

            # An AbuseIPDB score is itself a confidence-like signal.
            # Including it here allows sources without a generic
            # "confidence" field to contribute to overall confidence.
            evidence.confidence_scores.append(abuse_score)

        provider_risk = normalize_risk(data.get("risk"))

        if provider_risk is not None:
            evidence.provider_risks.append(provider_risk)

        known_exploited = bool(data.get("known_exploited", False))

        if known_exploited:
            evidence.known_exploited = True

        ransomware_associated = extract_ransomware_association(data)

        if ransomware_associated:
            evidence.ransomware_associated = True

        if data.get("is_tor") is True:
            evidence.tor_observed = True

        if data.get("is_whitelisted") is True:
            evidence.whitelisted = True

        total_reports = extract_integer(
            data.get("total_reports"),
            minimum=0,
        )

        if total_reports is not None:
            evidence.total_reports += total_reports

        distinct_users = extract_integer(
            data.get("distinct_reporting_users"),
            minimum=0,
        )

        if distinct_users is not None:
            evidence.distinct_reporting_users += distinct_users

        provider_evidence = ProviderEvidence(
            provider=provider_name,
            status=status,
            retrieved_at=getattr(result, "retrieved_at", None),
            confidence=confidence,
            risk=provider_risk,
            contributed_techniques=tuple(sorted(techniques)),
            contributed_cves=tuple(sorted(cves)),
            known_exploited=known_exploited,
            error=getattr(result, "error", None),
        )

        evidence.provider_evidence[provider_name] = provider_evidence

        if status == ProviderStatus.ERROR.value:
            error_message = getattr(result, "error", None)

            warning = f"{provider_name} did not return usable intelligence."

            if error_message:
                warning = f"{warning} Error: {error_message}"

            evidence.warnings.append(warning)


# ============================================================
# SECTION 8
# THREAT POLICY ENGINE
#
# ThreatPolicyEngine converts facts into decisions.
#
# This is where the organization expresses its security policy.
#
# Every decision remains deterministic and explainable.
# ============================================================


class ThreatPolicyEngine:
    """
    Evaluate normalized evidence using deterministic policy rules.
    """

    def __init__(
        self,
        policy: ThreatPolicy | None = None,
    ) -> None:
        self.policy = policy or ThreatPolicy()

    def evaluate(
        self,
        evidence: ThreatEvidence,
    ) -> ThreatSummary:
        """
        Convert ThreatEvidence into a ThreatSummary.
        """

        confidence = self.calculate_confidence(evidence)

        risk, risk_reasons = self.calculate_risk(
            evidence=evidence,
            overall_confidence=confidence,
        )

        priority, priority_reasons = self.calculate_priority(
            evidence=evidence,
            risk=risk,
        )

        limitations = self.build_limitations(evidence)

        return ThreatSummary(
            overall_risk=risk.value,
            overall_confidence=confidence,
            recommended_priority=priority.value,
            known_exploited=evidence.known_exploited,
            ransomware_associated=evidence.ransomware_associated,
            techniques=sorted(evidence.techniques),
            cves=sorted(evidence.cves),
            sources_consulted=len(evidence.providers_consulted),
            successful_sources=len(evidence.successful_providers),
            not_found_sources=len(evidence.not_found_providers),
            failed_sources=len(evidence.failed_providers),
            supporting_reasons=risk_reasons + priority_reasons,
            limitations=limitations,
            policy_version=self.policy.policy_version,
        )

    def calculate_confidence(
        self,
        evidence: ThreatEvidence,
    ) -> int:
        """
        Calculate the overall confidence score.

        Initial instructional model:

            1. Average available confidence signals.
            2. Increase confidence when several successful providers
               corroborate the investigation.
            3. Reduce confidence when provider failures limit coverage.
            4. Clamp the final result between 0 and 100.

        This is intentionally understandable and auditable.

        A later lab may replace this with weighted-source confidence.
        """

        valid_scores = [
            score
            for score in evidence.confidence_scores
            if 0 <= score <= 100
        ]

        if valid_scores:
            confidence = round(mean(valid_scores))
        else:
            confidence = self._infer_confidence_without_scores(
                evidence
            )

        successful_count = len(evidence.successful_providers)
        failed_count = len(evidence.failed_providers)

        if (
            successful_count
            >= self.policy.minimum_successful_sources_for_high_confidence
        ):
            confidence += 5

        if evidence.known_exploited:
            confidence = max(confidence, 90)

        if evidence.ransomware_associated:
            confidence = max(confidence, 90)

        confidence -= failed_count * 5

        return clamp_integer(confidence, minimum=0, maximum=100)

    def calculate_risk(
        self,
        *,
        evidence: ThreatEvidence,
        overall_confidence: int,
    ) -> tuple[RiskLevel, list[str]]:
        """
        Calculate overall risk and preserve the rules that caused it.

        Rule ordering matters.

        Stronger evidence is evaluated first.
        """

        reasons: list[str] = []

        # ----------------------------------------------------
        # Rule 1:
        # CISA KEV or equivalent known-exploitation evidence.
        # ----------------------------------------------------

        if evidence.known_exploited:
            reasons.append(
                "The vulnerability appears in a known-exploited "
                "vulnerability source."
            )

            return self.policy.known_exploited_risk, reasons

        # ----------------------------------------------------
        # Rule 2:
        # Ransomware association.
        # ----------------------------------------------------

        if evidence.ransomware_associated:
            reasons.append(
                "Threat intelligence associates the vulnerability "
                "or indicator with ransomware activity."
            )

            return RiskLevel.HIGH, reasons

        # ----------------------------------------------------
        # Rule 3:
        # High IP abuse confidence.
        # ----------------------------------------------------

        maximum_abuse_score = max(
            evidence.abuse_scores,
            default=0,
        )

        if maximum_abuse_score >= self.policy.high_abuse_score:
            reasons.append(
                "At least one provider returned a high abuse "
                f"confidence score of {maximum_abuse_score}."
            )

            return RiskLevel.HIGH, reasons

        # ----------------------------------------------------
        # Rule 4:
        # Provider explicitly returned high or critical risk.
        # ----------------------------------------------------

        normalized_provider_risks = {
            risk.upper()
            for risk in evidence.provider_risks
        }

        if RiskLevel.CRITICAL.value in normalized_provider_risks:
            reasons.append(
                "A provider classified the indicator as CRITICAL."
            )

            return RiskLevel.CRITICAL, reasons

        if RiskLevel.HIGH.value in normalized_provider_risks:
            reasons.append(
                "A provider classified the indicator as HIGH risk."
            )

            return RiskLevel.HIGH, reasons

        # ----------------------------------------------------
        # Rule 5:
        # Repeated independent abuse reports.
        # ----------------------------------------------------

        if evidence.total_reports >= self.policy.high_report_count:
            reasons.append(
                "The indicator has a high volume of independent "
                f"abuse reports: {evidence.total_reports}."
            )

            return RiskLevel.HIGH, reasons

        # ----------------------------------------------------
        # Rule 6:
        # Medium abuse score, multiple reports, or strong
        # confidence with supporting behavioral evidence.
        # ----------------------------------------------------

        if maximum_abuse_score >= self.policy.medium_abuse_score:
            reasons.append(
                "At least one provider returned a medium abuse "
                f"confidence score of {maximum_abuse_score}."
            )

            return RiskLevel.MEDIUM, reasons

        if evidence.total_reports >= self.policy.medium_report_count:
            reasons.append(
                "The indicator has multiple independent abuse "
                f"reports: {evidence.total_reports}."
            )

            return RiskLevel.MEDIUM, reasons

        if (
            overall_confidence >= self.policy.high_confidence
            and evidence.techniques
        ):
            reasons.append(
                "High-confidence intelligence is accompanied by "
                "mapped adversary techniques."
            )

            return RiskLevel.MEDIUM, reasons

        # ----------------------------------------------------
        # Rule 7:
        # TOR alone is suspicious context, but not sufficient
        # to declare an indicator malicious.
        # ----------------------------------------------------

        if evidence.tor_observed:
            reasons.append(
                "The indicator is associated with TOR infrastructure."
            )

            return self.policy.tor_minimum_risk, reasons

        # ----------------------------------------------------
        # Rule 8:
        # Whitelisting may lower risk, but it must not override
        # stronger evidence evaluated above.
        # ----------------------------------------------------

        if evidence.whitelisted:
            reasons.append(
                "A provider identified the indicator as whitelisted "
                "and no stronger malicious evidence was present."
            )

            return RiskLevel.LOW, reasons

        # ----------------------------------------------------
        # Rule 9:
        # No strong malicious evidence.
        # ----------------------------------------------------

        if evidence.successful_providers:
            reasons.append(
                "Providers returned intelligence, but no configured "
                "high-risk condition was satisfied."
            )

            return RiskLevel.LOW, reasons

        reasons.append(
            "No successful provider supplied sufficient intelligence "
            "to determine risk."
        )

        return RiskLevel.UNKNOWN, reasons

    def calculate_priority(
        self,
        *,
        evidence: ThreatEvidence,
        risk: RiskLevel,
    ) -> tuple[PriorityLevel, list[str]]:
        """
        Calculate investigation priority.

        Risk and priority are intentionally separate.

        Risk describes the observed threat.

        Priority describes how urgently the organization should act.
        """

        reasons: list[str] = []

        if evidence.known_exploited:
            reasons.append(
                "Known exploitation requires immediate investigation."
            )

            return self.policy.known_exploited_priority, reasons

        if evidence.ransomware_associated:
            reasons.append(
                "Ransomware association requires immediate investigation."
            )

            return self.policy.ransomware_priority, reasons

        if risk == RiskLevel.CRITICAL:
            reasons.append(
                "Critical risk requires immediate investigation."
            )

            return PriorityLevel.CRITICAL, reasons

        if risk == RiskLevel.HIGH:
            reasons.append(
                "High-risk intelligence requires expedited investigation."
            )

            return PriorityLevel.HIGH, reasons

        if risk == RiskLevel.MEDIUM:
            reasons.append(
                "Medium-risk intelligence should enter the standard "
                "SOC investigation queue."
            )

            return PriorityLevel.MEDIUM, reasons

        reasons.append(
            "The current assessment does not require expedited response."
        )

        return PriorityLevel.LOW, reasons

    def build_limitations(
        self,
        evidence: ThreatEvidence,
    ) -> list[str]:
        """
        Describe incomplete coverage and interpretation limits.
        """

        limitations = list(evidence.warnings)

        if not evidence.providers_consulted:
            limitations.append(
                "No threat-intelligence providers were consulted."
            )

        if not evidence.successful_providers:
            limitations.append(
                "No provider returned a successful intelligence result."
            )

        if evidence.not_found_providers:
            limitations.append(
                "A provider reporting NOT_FOUND does not prove that "
                "the indicator is benign."
            )

        if evidence.failed_providers:
            limitations.append(
                "The assessment may be incomplete because one or more "
                "providers failed."
            )

        if not evidence.confidence_scores:
            limitations.append(
                "No provider supplied a numeric confidence score; "
                "confidence was inferred from available evidence."
            )

        return deduplicate_strings(limitations)

    @staticmethod
    def _infer_confidence_without_scores(
        evidence: ThreatEvidence,
    ) -> int:
        """
        Infer a conservative confidence value when providers do not
        expose numeric confidence scores.
        """

        if evidence.known_exploited:
            return 90

        successful_count = len(evidence.successful_providers)

        if successful_count >= 3:
            return 75

        if successful_count == 2:
            return 65

        if successful_count == 1:
            return 50

        return 0


# ============================================================
# SECTION 9
# INTELLIGENCE FUSION ENGINE
#
# This is the public orchestration interface.
#
# Most callers need only:
#
#     fusion_engine = IntelligenceFusionEngine()
#     summary = fusion_engine.fuse(results)
# ============================================================


class IntelligenceFusionEngine:
    """
    Coordinate evidence aggregation and policy evaluation.
    """

    def __init__(
        self,
        *,
        aggregator: EvidenceAggregator | None = None,
        policy_engine: ThreatPolicyEngine | None = None,
    ) -> None:
        self.aggregator = aggregator or EvidenceAggregator()
        self.policy_engine = (
            policy_engine or ThreatPolicyEngine()
        )

    def fuse(
        self,
        provider_results: Iterable[ProviderResultProtocol],
    ) -> ThreatSummary:
        """
        Produce one final summary from provider results.
        """

        results = list(provider_results)

        LOGGER.info(
            "Starting threat-intelligence fusion with %d provider results.",
            len(results),
        )

        evidence = self.aggregator.aggregate(results)
        summary = self.policy_engine.evaluate(evidence)

        LOGGER.info(
            (
                "Threat-intelligence fusion completed: "
                "risk=%s confidence=%d priority=%s"
            ),
            summary.overall_risk,
            summary.overall_confidence,
            summary.recommended_priority,
        )

        return summary

    def fuse_with_evidence(
        self,
        provider_results: Iterable[ProviderResultProtocol],
    ) -> tuple[ThreatEvidence, ThreatSummary]:
        """
        Return both evidence and final summary.

        This method is useful for:

            - Audit logs
            - Report generation
            - Unit tests
            - Debugging
            - Bedrock narrative grounding
        """

        results = list(provider_results)

        evidence = self.aggregator.aggregate(results)
        summary = self.policy_engine.evaluate(evidence)

        return evidence, summary


# ============================================================
# SECTION 10
# EXTRACTION HELPERS
#
# These functions isolate schema interpretation from the core
# aggregation workflow.
#
# When a provider adds a new normalized field, these helpers can
# be expanded without rewriting the fusion engine.
# ============================================================


def extract_techniques(
    data: Mapping[str, Any],
) -> set[str]:
    """
    Extract MITRE ATT&CK technique identifiers from known fields.
    """

    techniques: set[str] = set()

    possible_values = [
        data.get("matched_technique_ids"),
        data.get("technique_ids"),
        data.get("techniques"),
    ]

    for value in possible_values:
        if not isinstance(value, list):
            continue

        for item in value:
            if isinstance(item, str):
                normalized = normalize_technique_id(item)

                if normalized:
                    techniques.add(normalized)

            elif isinstance(item, Mapping):
                technique_id = item.get("technique_id")

                if isinstance(technique_id, str):
                    normalized = normalize_technique_id(
                        technique_id
                    )

                    if normalized:
                        techniques.add(normalized)

    return techniques


def extract_cves(
    *,
    data: Mapping[str, Any],
    indicator: str | None,
    indicator_type: str | None,
) -> set[str]:
    """
    Extract CVE identifiers from provider data and indicator metadata.
    """

    cves: set[str] = set()

    direct_cve = data.get("cve_id")

    if isinstance(direct_cve, str):
        normalized = normalize_cve(direct_cve)

        if normalized:
            cves.add(normalized)

    list_values = [
        data.get("cves"),
        data.get("related_cves"),
    ]

    for value in list_values:
        if not isinstance(value, list):
            continue

        for item in value:
            if not isinstance(item, str):
                continue

            normalized = normalize_cve(item)

            if normalized:
                cves.add(normalized)

    if (
        isinstance(indicator_type, str)
        and indicator_type.upper() == "CVE"
        and isinstance(indicator, str)
    ):
        normalized = normalize_cve(indicator)

        if normalized:
            cves.add(normalized)

    return cves


def extract_confidence(
    data: Mapping[str, Any],
) -> int | None:
    """
    Extract a normalized confidence score from provider data.
    """

    confidence_fields = (
        "confidence",
        "confidence_score",
        "overall_confidence",
        "malicious_confidence",
    )

    for field_name in confidence_fields:
        value = extract_integer(
            data.get(field_name),
            minimum=0,
            maximum=100,
        )

        if value is not None:
            return value

    return None


def extract_ransomware_association(
    data: Mapping[str, Any],
) -> bool:
    """
    Interpret normalized ransomware-association fields.
    """

    boolean_value = data.get("ransomware_associated")

    if boolean_value is True:
        return True

    campaign_value = data.get(
        "known_ransomware_campaign_use"
    )

    if not isinstance(campaign_value, str):
        return False

    normalized = campaign_value.strip().lower()

    return normalized in {
        "known",
        "yes",
        "true",
        "confirmed",
    }


# ============================================================
# SECTION 11
# NORMALIZATION HELPERS
#
# These helpers make malformed or inconsistent provider values
# safe for deterministic processing.
# ============================================================


def normalize_provider_name(value: Any) -> str:
    """Normalize a provider name for evidence keys."""

    if not isinstance(value, str):
        return "unknown_provider"

    normalized = value.strip().lower()

    return normalized or "unknown_provider"


def normalize_status(value: Any) -> str:
    """Normalize a provider status."""

    if not isinstance(value, str):
        return ProviderStatus.ERROR.value

    normalized = value.strip().upper()

    allowed = {
        status.value
        for status in ProviderStatus
    }

    if normalized not in allowed:
        return ProviderStatus.ERROR.value

    return normalized


def normalize_risk(value: Any) -> str | None:
    """Normalize a provider risk label."""

    if not isinstance(value, str):
        return None

    normalized = value.strip().upper()

    allowed = {
        risk.value
        for risk in RiskLevel
    }

    if normalized not in allowed:
        return None

    return normalized


def normalize_technique_id(value: str) -> str | None:
    """
    Normalize a MITRE ATT&CK technique identifier.

    Examples:

        T1110
        T1110.001
    """

    normalized = value.strip().upper()

    if not normalized.startswith("T"):
        return None

    identifier = normalized[1:]

    if not identifier:
        return None

    components = identifier.split(".")

    if not all(component.isdigit() for component in components):
        return None

    return normalized


def normalize_cve(value: str) -> str | None:
    """
    Normalize a CVE identifier.

    Example:

        CVE-2021-44228
    """

    normalized = value.strip().upper()
    components = normalized.split("-")

    if len(components) != 3:
        return None

    prefix, year, identifier = components

    if prefix != "CVE":
        return None

    if not year.isdigit() or len(year) != 4:
        return None

    if not identifier.isdigit():
        return None

    return normalized


def safe_mapping(value: Any) -> Mapping[str, Any]:
    """Return a mapping or an empty dictionary."""

    if isinstance(value, Mapping):
        return value

    return {}


def extract_integer(
    value: Any,
    *,
    minimum: int | None = None,
    maximum: int | None = None,
) -> int | None:
    """
    Safely convert a value to an integer and validate its range.
    """

    if value is None or isinstance(value, bool):
        return None

    try:
        converted = int(value)
    except (TypeError, ValueError):
        return None

    if minimum is not None and converted < minimum:
        return None

    if maximum is not None and converted > maximum:
        return None

    return converted


def clamp_integer(
    value: int,
    *,
    minimum: int,
    maximum: int,
) -> int:
    """Constrain an integer to an inclusive range."""

    return max(minimum, min(maximum, value))


def deduplicate_strings(
    values: Iterable[str],
) -> list[str]:
    """Remove duplicate strings while preserving their order."""

    return list(dict.fromkeys(values))


def utc_now_iso() -> str:
    """Return the current UTC time in ISO-8601 format."""

    return (
        datetime.now(timezone.utc)
        .isoformat()
        .replace("+00:00", "Z")
    )


# ============================================================
# SECTION 12
# CONVENIENCE FUNCTION
#
# This helper supports callers that do not need to customize the
# aggregator or policy engine.
# ============================================================


def fuse_provider_results(
    provider_results: Iterable[ProviderResultProtocol],
    *,
    policy: ThreatPolicy | None = None,
) -> ThreatSummary:
    """
    Fuse provider results using the default fusion pipeline.

    Example:

        summary = fuse_provider_results(results)

        print(summary.overall_risk)
        print(summary.recommended_priority)
    """

    engine = IntelligenceFusionEngine(
        policy_engine=ThreatPolicyEngine(policy),
    )

    return engine.fuse(provider_results)