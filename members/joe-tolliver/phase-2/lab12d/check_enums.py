from models.enums import (
    ThreatCondition,
    ThreatSeverity,
    ThreatConfidence,
    ProviderTrustLevel,
    ProviderType,
    PlatformType,
    IndicatorSource,
    IndicatorType,
    ThreatAssessment,
    ThreatDomain,
    ThreatType,
)

print("Threat Conditions:")
print(ThreatCondition.names())

print("\nThreat Severities:")
print(ThreatSeverity.names())

print("\nThreat Confidence:")
print(ThreatConfidence.names())

print("\nProvider Trust:")
print(ProviderTrustLevel.names())

print("\nProvider Types:")
print(ProviderType.names())

print("\nPlatforms:")
print(PlatformType.names())

print("\nIndicator Sources:")
print(IndicatorSource.names())

print("\nIndicator Types:")
print(IndicatorType.names())

print("\nThreat Assessments:")
print(ThreatAssessment.names())

print("\nThreat Types:")
print(ThreatType.names())

print("\nThreat Domains:")
print(ThreatDomain.names())