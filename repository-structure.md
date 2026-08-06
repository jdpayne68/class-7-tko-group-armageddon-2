# Repository Structure

This repository is organized as a progressive DevSecOps lab portfolio. The root repository contains shared documentation, canonical badge resources, participant submission areas, and deployable lab implementations for Phase 1 and Phase 2.

## Top-Level Layout

```text
.
├── .github/                 # Pull request template and GitHub repository metadata
├── assets/                  # Shared image and visual assets used by documentation
├── badges/                  # Canonical reusable badge library
├── enable_model/            # Helper assets for enabling required Bedrock models
├── internal/                # Maintainer-only documentation and branch bootstrap tooling
├── main/                    # Group submission workspace and evidence folders
├── members/                 # Participant-specific submission folders
├── phase_1/                 # Deployable Phase 1 lab progression: Lab 12 through Lab 12c
├── phase_2/                 # Deployable Phase 2 lab progression: Lab 12d
├── README.md                # Repository landing page
└── repository-structure.md  # This structure guide
```

> [!NOTE]
> `RIKB/` is generated repository intelligence and is intentionally ignored by Git. It is not required for peers to deploy or work through the labs.

## Phase Layout

### Phase 1

`phase_1/` contains the completed progression from baseline WAF detection through compliance reporting.

| Lab | Path | Purpose |
| --- | --- | --- |
| Lab 12 | `phase_1/lab_12` | WAF activity detection, Bedrock-assisted analysis, and correlation findings |
| Lab 12a | `phase_1/lab_12a` | Adds SOAR incident creation and analyst notification workflows |
| Lab 12b | `phase_1/lab_12b` | Adds executive PDF and JSON reporting through Lambda and S3 |
| Lab 12c | `phase_1/lab_12c` | Adds compliance evidence reporting and control mapping |

### Phase 2

`phase_2/` contains the threat-intelligence expansion work.

| Lab | Path | Purpose |
| --- | --- | --- |
| Lab 12d | `phase_2/lab_12d` | Adds provider-based threat intelligence, event contracts, fused risk scoring, and intelligence reports |

## Standard Lab Structure

Each deployable lab follows the same basic layout.

```text
lab_12x/
├── .env.example             # Environment variable template
├── README.md                # Lab-specific deployment and validation guide
├── docs/                    # Architecture, deployment, security, cleanup, and troubleshooting notes
├── evidence/                # Placeholder for generated or captured validation evidence
├── requirements.txt         # Python dependencies used by local helper scripts
├── sample_output/           # Placeholder for example JSON/PDF/report artifacts
└── terraform/               # Terraform root module, Lambda source, and helper scripts
```

Phase 2 Lab 12d follows the same pattern and adds `terraform/new-code.tf` for in-progress Terraform implementation work.

## Terraform Module Layout

Each lab keeps Terraform in a flat root-module layout with numbered files by infrastructure domain.

```text
terraform/
├── 00-providers.tf          # Provider requirements and provider configuration
├── 01-backend.tf            # Terraform backend configuration
├── 02-helper-resources.tf   # Helper resources such as random IDs or generated values
├── 03-helper-data.tf        # Data sources such as caller identity, region, and partition
├── 10-iam-policies.tf       # IAM policy documents and permissions
├── 11-iam-roles.tf          # IAM roles and role attachments
├── 20-cognito.tf            # Cognito user pool and authentication resources
├── 30-api-gateway.tf        # API Gateway routes, stages, integrations, and auth wiring
├── 40-s3.tf                 # S3 buckets and report storage resources
├── 41-dynamodb.tf           # DynamoDB tables for events, findings, incidents, and evidence
├── 50-lambda.tf             # Lambda functions, packaging, and Lambda permissions
├── 60-eventbridge.tf        # EventBridge rules, targets, and event routing
├── 72-waf.tf                # AWS WAF Web ACLs, managed rules, and logging configuration
├── 80-cloudwatch-logs.tf    # CloudWatch log groups and log retention
├── 81-metrics-and-alarms.tf # Metrics and alarms
├── 83-sns.tf                # SNS topics and notification resources
├── locals.tf                # Shared naming, tags, ARNs, and derived local values
├── outputs.tf               # Terraform outputs used for deployment and testing
├── variables.tf             # Input variables
└── terraform-tfvars.example # Example Terraform variable values
```

Labs 12b, 12c, and 12d also include `build-layers.md` and `scripts/build-layers.sh` because the executive/compliance/reporting agents require a Lambda layer build step before Terraform deployment.

## Lambda Source Layout

Lambda code is organized one folder per function under each lab's `terraform/lambda/src/` directory.

```text
terraform/lambda/src/
├── jedi_python/
├── sith_node/
├── unused_token_detector/
├── waf_bedrock_analyzer/
├── waf_threat_correlation_agent/
├── soar_response_agent/
├── executive_dashboard_agent/
├── compliance_agent/
└── threat_intelligence_agent/
```

Not every lab contains every agent. The agent set grows as the labs progress.

| Agent | Introduced In | Purpose |
| --- | --- | --- |
| `jedi_python` | Lab 12 | Python protected-route Lambda used by API Gateway |
| `sith_node` | Lab 12 | Node.js protected-route Lambda used by API Gateway |
| `unused_token_detector` | Lab 12 | Detects potentially unused or suspicious token activity |
| `waf_bedrock_analyzer` | Lab 12 | Summarizes WAF activity with Bedrock-assisted analysis |
| `waf_threat_correlation_agent` | Lab 12 | Correlates WAF events into security findings |
| `soar_response_agent` | Lab 12a | Creates incidents, analyst summaries, and SOC notifications |
| `executive_dashboard_agent` | Lab 12b | Generates executive security reports and S3 report artifacts |
| `compliance_agent` | Lab 12c | Maps incidents/findings to compliance evidence and controls |
| `threat_intelligence_agent` | Lab 12d | Enriches incidents with provider-based threat intelligence |
| `fusion_agent` | Lab 12d | Supports fused risk scoring and intelligence synthesis |
| `provider_registry_agent` | Lab 12d | Provides provider registration and lookup support |
| `threat_intelligence_report_agent` | Lab 12d | Produces threat-intelligence report artifacts |

Most Lambda folders include a `test_events/` subdirectory with Lambda console test payloads.

## Helper Scripts

Each lab stores operational helper scripts under `terraform/scripts/`.

| Script | Purpose |
| --- | --- |
| `get-token.py` | Retrieves Cognito tokens for authenticated API testing |
| `test-malicious-waf-traffic.sh` | Generates controlled WAF-triggering traffic for lab validation |
| `build-layers.sh` | Builds required Lambda layer assets for report-generation agents |
| `parser.py` | Helper parsing utility retained where needed by the lab |
| `imposter-syndrome-defense.py` | Local support/encouragement helper script used in later labs |

## Badge Library

`badges/` is the canonical reusable badge library copied from the workstation source of truth.

```text
badges/
├── README.md
├── assets/logos/            # Local SVG sources, exported icons, and fallback placeholders
├── library/
│   ├── aws-badges.md
│   ├── az-badges.md
│   ├── core-badges.md
│   ├── gcp-badges.md
│   ├── git-badges.md
│   ├── methodology-badges.md
│   └── skill-badges.md
└── services/cloud/
    ├── aws-services.md
    ├── az-services.md
    └── gcp-services.md
```

AWS and Azure provider badges use custom base64-encoded SVG logos in the Shields.io `logo=` parameter because named provider slugs have not rendered consistently. Google Cloud provider badges use the native `logo=googlecloud` slug. Individual cloud service badges remain simple provider-colored text badges unless a stable icon path is available. For maintenance guidance, see the badge library README and the Shields.io [Static Badges](https://shields.io/docs/static-badges) and [Logos](https://shields.io/docs/logos) documentation. Local SVG sources for referenced badge logos are stored in `badges/assets/logos/` and indexed by `logo-manifest.json`.

## Internal Maintainer Area

`internal/` contains maintainer-only guidance and branch setup tooling.

```text
internal/
├── CONTRIBUTING.md
├── deploy_branch/
│   ├── README.md
│   ├── phase-1-init.sh
│   └── resources/
│       ├── repo_scaffold/
│       └── templates/lab_templates/
└── security-intelligence-foundations.md
```

`internal/deploy_branch/phase-1-init.sh` bootstraps peer-ready Phase 1 branch content from internal resources. It creates missing scaffold and lab files, preserves existing work, and intentionally excludes `RIKB/` and `badges/` from peer branch setup.

## Main And Member Areas

`main/` contains group-submission evidence and placeholder directories for phase deliverables.

```text
main/
├── phase-1/
│   ├── evidence/
│   ├── lab12/
│   ├── lab12a/
│   ├── lab12b/
│   └── sample-output/
└── phase-2/
    ├── lab12c/
    └── lab12d/
```

`members/` contains participant-specific workspaces. Each participant folder follows the same broad phase split:

```text
members/<participant>/
├── phase-1/
│   ├── lab12/
│   ├── lab12a/
│   └── lab12b/
└── phase-2/
    ├── lab12c/
    └── lab12d/
```

Some participant folders contain completed Terraform, screenshots, reports, troubleshooting notes, or artifacts; others are placeholders for submission work.

## Generated And Local-Only Paths

The following paths should not be treated as source-controlled deployable source:

| Path Or Pattern | Reason |
| --- | --- |
| `RIKB/` | Generated repository intelligence knowledge base |
| `.terraform/` | Local Terraform provider/module cache |
| `*.tfstate`, `*.tfstate.*` | Terraform state files |
| `terraform/lambda/layers/` | Locally built Lambda layer output |
| `*.zip` | Generated Lambda or layer package artifacts |
| `.DS_Store` | macOS filesystem metadata |
| `__pycache__/`, `*.pyc` | Python bytecode/cache files |
| `.env`, `.env.lambda`, `terraform.tfvars` | Local environment and secret-bearing configuration |

## Naming Conventions

Repository naming follows these conventions:

- folders use snake case, such as `phase_1`, `lab_12`, and `sample_output`
- files use kebab case where practical, such as `build-layers.sh` and `terraform-tfvars.example`
- Terraform files use numeric prefixes to preserve domain ordering
- Lambda function folders use snake case and keep each function isolated under `terraform/lambda/src/`

## Operational Flow

A normal lab workflow is:

1. Read the lab `README.md`.
2. Create and activate a local Python virtual environment if using helper scripts.
3. Install the lab `requirements.txt`.
4. Build Lambda layers first for labs that include `build-layers.sh`.
5. Change into the lab's `terraform/` directory.
6. Run Terraform initialization, validation, planning, and apply.
7. Use helper scripts and Lambda test events to validate API, WAF, SOAR, reporting, and evidence flows.
8. Capture outputs in `evidence/` or `sample_output/` as appropriate.
9. Destroy lab resources when finished if the environment is temporary.
