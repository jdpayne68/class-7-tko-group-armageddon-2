# Lab 12 — Phase 1 Evidence

WAF-to-SOAR autonomous security pipeline. Screenshots ordered by pipeline flow;
opened in sequence they walk the architecture from edge to executive report.

## Screenshots

| # | File | Proves |
|---|------|--------|
| 01 | terraform-outputs-and-plan | Stack deployed; outputs resolve, plan reads clean |
| 02 | waf-401-403-layered-defense | WAF blocks (403) and authorizer rejects (401) — two layers, two codes |
| 03 | wafchecker-243-of-254-blocked | 243/254 attacks blocked, 0 real bypasses (1x405 = method refusal) |
| 04 | authenticated-200-python-and-node-rbac | Valid ID token → 200 + greeting on /python and /node, groups=admins |
| 05 | waf-logs-block-records | WAF delivering BLOCK records to CloudWatch — the telemetry source |
| 06 | analyzer-events-stored-and-waf-events-scan | Analyzer normalized 11 events into waf-events (incl. the blocked SQLi) |
| 07 | correlation-event-published-after-decimal-fix | Correlation finding created + published to EventBridge (risk 85, CRITICAL) |
| 08 | incident-auto-created-INC-record | **SOAR auto-created INC- incident — no manual trigger. The centerpiece.** |
| 09 | dashboard-invoke-report-to-s3 | Dashboard generated PDF + JSON to S3 |
| 10 | s3-executive-report-object-detail | The report object in S3 — ARN, versioning, size |
| 11 | executive-report-pdf-rendered | The rendered executive PDF — CRITICAL posture, metrics, narrative |

## The story in one line

Hostile request → WAF blocks at edge → analyzer normalizes → correlation scores
and publishes → SOAR opens the incident on its own → dashboard reports it.
Every arrow in the architecture, with a real artifact.

## Note on 07

Shows the Float-types DynamoDB error immediately above the successful run — a
genuine defect in the stock lab code (findings carry computed floats; DynamoDB
takes only Decimal). Fixed with a recursive float→Decimal conversion before the
write. Kept the before/after in one frame on purpose; it documents the fix.

## report/

The executive PDF itself (executive-security-report.pdf) — the actual artifact
the pipeline produced, not just a screenshot of it.

## _setaside/

Near-duplicates and troubleshooting shots, kept out of the numbered set but
retained for reference. Not part of the submission proof.
