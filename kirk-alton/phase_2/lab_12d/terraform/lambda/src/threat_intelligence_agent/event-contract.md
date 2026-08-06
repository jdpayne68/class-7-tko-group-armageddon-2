# Threat Intelligence Agent Event Contract

Preferred EventBridge event emitted after SOAR creates or reuses an incident.

```json
{
  "source": "seir.soar",
  "detail-type": "Security Incident Created",
  "detail": {
    "incident_id": "INC-72284090-2e23-4618-b896-ce0e249c7957",
    "finding_id": "72284090-2e23-4618-b896-ce0e249c7957",
    "severity": "MEDIUM",
    "primary_source_ip": "73.166.82.125",
    "primary_target": "/prod",
    "event_count": 151
  }
}
```

Direct Lambda tests may pass the `detail` fields at the top level.

The handler supports these indicator fields, in order:

- `indicator.value` plus `indicator.type`
- `indicator_value` plus `indicator_type`
- `primary_source_ip`
- `source_ip`
- `ip_address`
- `ip`
- `cve_id` or `cve`
- `technique_id` or `attack_technique`

If no indicator is present in the event, the handler attempts to retrieve the
incident or finding from DynamoDB when the table names are configured.
