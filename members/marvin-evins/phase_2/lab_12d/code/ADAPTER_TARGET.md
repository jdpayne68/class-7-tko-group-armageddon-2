# Armageddon -> Agent 10 Adapter Target

Input fields from Armageddon TEST-001:

```text
finding_id: TEST-001
source_ip: 203.0.113.25
request_count: 150
severity: HIGH
attack_type: credential-probing
```

Target concept:

```text
Armageddon finding
      -> adapter
      -> Agent 10 ThreatEvidence
      -> EvidenceAggregator
      -> evidence set
      -> later fusion/threat assessment
```

The adapter should remain isolated from the working AWS/Terraform 12C pipeline until the local model conversion test passes.
