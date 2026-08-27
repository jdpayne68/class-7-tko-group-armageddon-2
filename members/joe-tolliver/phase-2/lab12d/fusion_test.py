import json
import os

import boto3

from datetime import datetime, timezone

from providers import Indicator, CisaKevProvider

from dataclasses import dataclass, asdict

from providers import ProviderResult

from agents.report import (
    ThreatIntelligenceReportService,
    ThreatIntelligenceReportBuilder,
    ReportConfiguration,
    NarrativeBuilder,
)

from models.enums import (
    IndicatorSource,
    IndicatorType,
    ProviderStatus,
    ProviderTrustLevel,
    ThreatCondition,
    ThreatConfidence,
    ThreatSeverity,
)

from agents.fusion import (
    ThreatEvidence,
    EvidenceAggregator,
    EvidenceSelector,
    ThreatCorrelation,
    ThreatAssessmentEngine,
    ThreatClassifier,
    ThreatSummaryBuilder,
    NarrativeAdapter,
)


@dataclass
class ReportSummaryAdapter:
    """
    Translate Fusion's ThreatSummary / AssessmentResult
    into the contract expected by agents.report.
    """

    overall_risk: str
    overall_confidence: int
    recommended_priority: str

    known_exploited: bool
    ransomware_associated: bool

    techniques: list[str]
    cves: list[str]

    sources_consulted: int
    successful_sources: int
    not_found_sources: int
    failed_sources: int

    supporting_reasons: list[str]
    limitations: list[str]

    analyzed_at: str
    policy_version: str

    def to_dict(self):
        return asdict(self)


@dataclass
class ReportEvidenceAdapter:
    """
    Translate Fusion evidence into the evidence contract
    expected by agents.report.
    """

    providers_consulted: set[str]
    successful_providers: set[str]
    not_found_providers: set[str]
    failed_providers: set[str]

    techniques: set[str]
    cves: set[str]

    confidence_scores: list[int]
    abuse_scores: list[int]
    provider_risks: list[str]

    known_exploited: bool
    ransomware_associated: bool
    tor_observed: bool
    whitelisted: bool

    total_reports: int
    distinct_reporting_users: int

    provider_evidence: dict
    warnings: list[str]

    def to_dict(self):
        return asdict(self)


class BedrockNarrativeProvider:
    """
    Use Amazon Bedrock only to explain an already-completed
    deterministic security assessment.
    """

    def __init__(
        self,
        model_id: str | None = None,
    ) -> None:

        self.model_id = (
            model_id
            or os.getenv(
                "BEDROCK_MODEL_ID",
                "us.anthropic.claude-haiku-4-5-20251001-v1:0",
            )
        )

        self.client = boto3.client(
            "bedrock-runtime"
        )

    def generate(
        self,
        *,
        indicator,
        executive_summary,
        findings,
        recommendations,
        limitations,
    ) -> str:

        prompt = f"""
You are a SOC analyst assistant.

Explain the following completed security investigation
for a security manager.

IMPORTANT RULES:

- Do not change the established risk.
- Do not change the confidence.
- Do not change the priority.
- Do not invent new findings.
- Do not invent new recommendations.
- Do not claim that exploitation occurred in this
  environment unless the supplied evidence says so.
- Clearly distinguish known exploitation in the wild
  from confirmed compromise of this environment.

Indicator:
{json.dumps(indicator, indent=2, default=str)}

Executive Summary:
{json.dumps(executive_summary, indent=2, default=str)}

Findings:
{json.dumps(findings, indent=2, default=str)}

Recommendations:
{json.dumps(recommendations, indent=2, default=str)}

Limitations:
{json.dumps(limitations, indent=2, default=str)}

Produce a concise executive security narrative.
""".strip()

        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 700,
            "temperature": 0.2,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt,
                        }
                    ],
                }
            ],
        }

        print(
            "\nInvoking Bedrock model:",
            self.model_id,
        )

        response = self.client.invoke_model(
            modelId=self.model_id,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(request_body),
        )

        response_body = json.loads(
            response["body"].read()
        )

        content = response_body.get(
            "content",
            [],
        )

        if not content:
            raise ValueError(
                "Bedrock returned no narrative content."
            )

        narrative = content[0].get("text")

        if not narrative:
            raise ValueError(
                "Bedrock response did not contain text."
            )

        return narrative


# ------------------------------------------------------------
# 1. Create indicator
# ------------------------------------------------------------

indicator = Indicator.create(
    value="CVE-2021-44228",
    indicator_type="CVE",
)


# ------------------------------------------------------------
# 2. Query CISA
# ------------------------------------------------------------

provider = CisaKevProvider()
result = provider.enrich(indicator)

print("\n=== PROVIDER RESULT ===")
print(result.to_dict())


# ------------------------------------------------------------
# 3. Translate provider result into Fusion's evidence model
# ------------------------------------------------------------

evidence = ThreatEvidence(
    provider_name=result.provider,

    provider_status=ProviderStatus.SUCCESS,
    provider_trust=ProviderTrustLevel.HIGH,

    indicator_value=result.indicator,
    indicator_type=IndicatorType.CVE,
    indicator_source=IndicatorSource.EXTERNAL_API,

    condition=ThreatCondition.OTHER,

    severity=ThreatSeverity.UNKNOWN,
    confidence=ThreatConfidence.OBSERVED,

    summary=(
        "CISA KEV reports this CVE as a "
        "known exploited vulnerability."
    ),

    observed_at=datetime.fromisoformat(
        result.retrieved_at.replace("Z", "+00:00")
    ),

    expires_at=datetime.fromtimestamp(
        result.expires_at,
        tz=timezone.utc,
    ),

    metadata={
        "provider_data": result.data
    },
)


# ------------------------------------------------------------
# 4. Create an evidence repository
# ------------------------------------------------------------

aggregator = EvidenceAggregator()


# ------------------------------------------------------------
# 5. Add the evidence
# ------------------------------------------------------------

inspector_evidence = ThreatEvidence(
    provider_name="simulated_aws_inspector",

    provider_status=ProviderStatus.SUCCESS,
    provider_trust=ProviderTrustLevel.HIGH,

    indicator_value="CVE-2021-44228",
    indicator_type=IndicatorType.CVE,
    indicator_source=IndicatorSource.INSPECTOR,

    condition=ThreatCondition.VULNERABLE_LIBRARY,

    severity=ThreatSeverity.HIGH,
    confidence=ThreatConfidence.VALIDATED,

    summary=(
        "Simulated AWS Inspector evidence indicates that "
        "an application asset contains a library affected "
        "by CVE-2021-44228."
    ),

    metadata={
        "simulation": True,
        "resource_id": "i-0123456789example",
        "package": "log4j",
    },
)

aggregator.add(evidence)
aggregator.add(inspector_evidence)


# ------------------------------------------------------------
# 6. Inspect what Fusion now knows
# ------------------------------------------------------------

print("\n=== FUSION EVIDENCE ===")
print(evidence.to_dict())

print("\n=== EVIDENCE COUNT ===")
print(len(aggregator))

print("\n=== EVIDENCE INVENTORY ===")
print(aggregator.inventory())

print("\n=== SERIALIZED AGGREGATOR ===")
print(aggregator.to_dict())


# ------------------------------------------------------------
# 7. Select evidence eligible for reasoning
# ------------------------------------------------------------

selector = EvidenceSelector()

selected_evidence = selector.select(aggregator)

print("\n=== SELECTED EVIDENCE ===")
print("Selected count:", len(selected_evidence))

for item in selected_evidence:
    print(
        item.provider_name,
        item.indicator_value,
        item.condition.value,
        item.provider_trust.value,
    )


# ------------------------------------------------------------
# 8. Attempt correlation
# ------------------------------------------------------------

correlator = ThreatCorrelation()

groups = correlator.correlate(selected_evidence)

print("\n=== CORRELATION GROUPS ===")
print("Group count:", len(groups))
print(groups)


# ------------------------------------------------------------
# 9. Classify each correlation group
# ------------------------------------------------------------

classifier = ThreatClassifier()

print("\n=== THREAT CLASSIFICATION ===")

for group in groups:

    threat_type, threat_domain = classifier.classify(group)

    print("Threat Type:", threat_type.value)
    print("Threat Domain:", threat_domain.value)
    
    
# ------------------------------------------------------------
# 10. Assess each correlated threat
# ------------------------------------------------------------

assessment_engine = ThreatAssessmentEngine()

print("\n=== THREAT ASSESSMENT ===")

for group in groups:

    assessment = assessment_engine.assess(group)

    print(
        "Threat Type:",
        assessment.threat_type.value,
    )

    print(
        "Threat Domain:",
        assessment.threat_domain.value,
    )

    print(
        "Severity:",
        assessment.severity.value,
    )

    print(
        "Confidence:",
        assessment.confidence.value,
    )

    print(
        "Assessment:",
        assessment.assessment.value,
    )

    print(
        "Evidence Count:",
        len(assessment.supporting_evidence),
    )

    print("\nRationale:")

    for reason in assessment.rationale:
        print("-", reason)

    print("\nMetadata:")
    print(assessment.metadata)
    
    
    # --------------------------------------------------------
    # 11. Build the communication summary
    # --------------------------------------------------------

    summary_builder = ThreatSummaryBuilder()

    summary = summary_builder.build(assessment)

    print("\n=== THREAT SUMMARY ===")

    print("Title:", summary.title)

    print(
        "Executive Summary:",
        summary.executive_summary,
    )

    print(
        "Evidence Count:",
        summary.evidence_count,
    )

    print(
        "Provider Count:",
        summary.provider_count,
    )

    print("\nFindings:")

    for finding in summary.findings:
        print("-", finding)

    print("\nRecommendations:")

    for recommendation in summary.recommendations:
        print("-", recommendation)
        
        
    # --------------------------------------------------------
    # 12. Prepare the assessment for AI explanation
    # --------------------------------------------------------

    narrative_adapter = NarrativeAdapter()

    prompt = narrative_adapter.create_prompt(summary)

    print("\n=== AI NARRATIVE PROMPT ===")
    print(prompt)
    
    
    # --------------------------------------------------------
    # 13. Adapt Fusion output for the reporting engine
    # --------------------------------------------------------

    confidence_map = {
        ThreatConfidence.UNKNOWN: 0,
        ThreatConfidence.OBSERVED: 25,
        ThreatConfidence.SUSPECTED: 40,
        ThreatConfidence.CORRELATED: 60,
        ThreatConfidence.VALIDATED: 80,
        ThreatConfidence.VERIFIED: 90,
        ThreatConfidence.CONFIRMED: 100,
    }

    known_exploited = False
    ransomware_associated = False

    providers_consulted = set()
    successful_providers = set()

    confidence_scores = []
    provider_risks = []
    provider_evidence = {}

    cves = set()

    for item in group.evidence:

        providers_consulted.add(
            item.provider_name
        )

        if item.provider_status == ProviderStatus.SUCCESS:
            successful_providers.add(
                item.provider_name
            )

        confidence_scores.append(
            confidence_map.get(
                item.confidence,
                0,
            )
        )

        provider_risks.append(
            item.severity.value
        )

        provider_evidence[
            item.provider_name
        ] = item.to_dict()

        if item.indicator_type == IndicatorType.CVE:
            cves.add(
                item.indicator_value
            )

        provider_data = item.metadata.get(
            "provider_data",
            {},
        )

        if provider_data.get(
            "known_exploited"
        ) is True:
            known_exploited = True

        ransomware_value = provider_data.get(
            "known_ransomware_campaign_use",
            "",
        )

        if str(ransomware_value).upper() == "KNOWN":
            ransomware_associated = True


    report_summary = ReportSummaryAdapter(

        overall_risk=assessment.severity.value,

        overall_confidence=confidence_map.get(
            assessment.confidence,
            0,
        ),

        recommended_priority=(
            assessment.severity.value
        ),

        known_exploited=known_exploited,

        ransomware_associated=(
            ransomware_associated
        ),

        techniques=[],

        cves=sorted(cves),

        sources_consulted=len(
            providers_consulted
        ),

        successful_sources=len(
            successful_providers
        ),

        not_found_sources=0,

        failed_sources=0,

        supporting_reasons=list(
            assessment.rationale
        ),

        limitations=[
            (
                "AWS Inspector evidence is simulated "
                "for Lab12d testing."
            )
        ],

        analyzed_at=summary.generated_at.isoformat(),

        policy_version=(
            "lab12d-custom-policy-1.0"
        ),
    )


    report_evidence = ReportEvidenceAdapter(

        providers_consulted=(
            providers_consulted
        ),

        successful_providers=(
            successful_providers
        ),

        not_found_providers=set(),

        failed_providers=set(),

        techniques=set(),

        cves=cves,

        confidence_scores=(
            confidence_scores
        ),

        abuse_scores=[],

        provider_risks=provider_risks,

        known_exploited=(
            known_exploited
        ),

        ransomware_associated=(
            ransomware_associated
        ),

        tor_observed=False,

        whitelisted=False,

        total_reports=0,

        distinct_reporting_users=0,

        provider_evidence=(
            provider_evidence
        ),

        warnings=[
            (
                "AWS Inspector evidence is simulated "
                "and does not represent a real AWS finding."
            )
        ],
    )


# ---------------------------------------------
# 14. Create simulated Inspector ProviderResult
# ---------------------------------------------

simulated_inspector_result = ProviderResult(
    provider="simulated_aws_inspector",

    indicator_id=indicator.indicator_id,
    indicator=indicator.value,
    indicator_type=indicator.indicator_type,

    status="SUCCESS",

    retrieved_at=inspector_evidence.observed_at.isoformat(),

    expires_at=(
        int(inspector_evidence.observed_at.timestamp())
        + 86400
    ),

    data={
        "simulation": True,
        "condition": inspector_evidence.condition.value,
        "resource_id": inspector_evidence.metadata.get(
            "resource_id"
        ),
        "package": inspector_evidence.metadata.get(
            "package"
        ),
    },

    error=None,
)


print("\n=== SIMULATED PROVIDER RESULT ===")
print(simulated_inspector_result.to_dict())


# ---------------------------------------------
# 15. Build report
# ---------------------------------------------

bedrock_narrative_provider = (
    BedrockNarrativeProvider()
)


report_configuration = ReportConfiguration(
    generate_narrative=True,
)


narrative_builder = NarrativeBuilder(
    provider=bedrock_narrative_provider,
)


report_builder = ThreatIntelligenceReportBuilder(
    configuration=report_configuration,
    narrative_builder=narrative_builder,
)


report_service = ThreatIntelligenceReportService(
    builder=report_builder,
)

report = report_service.create_report(
    indicator=indicator,
    summary=report_summary,
    evidence=report_evidence,

    provider_results=[
        result,
        simulated_inspector_result,
    ],

    metadata={
        "lab": "lab12d",
        "simulation_used": True,
    },
)

print("\n=== BEDROCK NARRATIVE ===")

if report.narrative:
    print(report.narrative)
else:
    print("No Bedrock narrative was generated.")

print("\n=== STRUCTURED THREAT REPORT ===")

print(
    report_service.render_console(
        report
    )
)

# --------------------------------------------------------
# 16. Render report as JSON
# --------------------------------------------------------

json_report = report_service.render_json(
        report
    )

print("\n=== JSON REPORT ===")
print(json_report)


# --------------------------------------------------------
# 17. Render report as Markdown
# --------------------------------------------------------

markdown_report = (
        report_service.render_markdown(
            report
        )
    )

print("\n=== MARKDOWN REPORT ===")
print(markdown_report)