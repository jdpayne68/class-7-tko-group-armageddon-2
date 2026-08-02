# kirk-alton/

```text
.
├── README.md
├── CONTRIBUTING.md
├── repo-structure.md
├── phase-1-init.sh
│
├── docs/
│   ├── architecture.md
│   ├── cleanup.md
│   ├── deployment-guide.md
│   ├── security-design.md
│   └── troubleshooting.md
│
├── phase_1/
│   ├── README.md
│   │
│   ├── lab_12/
│   │   ├── assets/
│   │   ├── evidence/
│   │   ├── sample_output/
│   │   ├── .env.example
│   │   ├── readme.md
│   │   ├── requirements.txt
│   │   └── terraform/
│   │
│   ├── lab_12a/
│   │   ├── assets/
│   │   ├── evidence/
│   │   ├── sample_output/
│   │   ├── .env.example
│   │   ├── readme.md
│   │   ├── requirements.txt
│   │   └── terraform/
│   │
│   ├── lab_12b/
│   │   ├── assets/
│   │   ├── evidence/
│   │   ├── sample_output/
│   │   ├── .env.example
│   │   ├── readme.md
│   │   ├── requirements.txt
│   │   └── terraform/
│   │
│   └── lab_12c/
│       ├── assets/
│       ├── evidence/
│       ├── sample_output/
│       ├── .env.example
│       ├── readme.md
│       ├── requirements.txt
│       └── terraform/
│
├── phase_2/
│   └── README.md
│
└── shared/
    ├── diagrams/
    ├── test_events/
    │   ├── analyzer.json
    │   ├── correlation.json
    │   ├── dashboard.json
    │   └── soar.json
    │
    └── templates/
        ├── lab_templates/
        │   ├── lab_12_template/
        │   ├── lab_12a_template/
        │   ├── lab_12b_template/
        │   └── lab_12c_template/
        │
        └── terraform_templates/
```

## Phase 1 Lab Progression

```text
phase_1/
├── lab_12/      WAF threat analysis and correlation
├── lab_12a/     Lab 12 plus SOAR response automation
├── lab_12b/     Lab 12a plus executive dashboard reporting
└── lab_12c/     Lab 12b plus compliance reporting
```

## Standard Lab Layout

Each `phase_1/lab_12*` directory follows the same top-level pattern:

```text
lab_12*/
├── assets/
├── evidence/
├── sample_output/
├── .env.example
├── readme.md
├── requirements.txt
└── terraform/
    ├── 00-providers.tf
    ├── 01-backend.tf
    ├── 02-helper-resources.tf
    ├── 03-helper-data.tf
    ├── 10-iam-policies.tf
    ├── 11-iam-roles.tf
    ├── 20-cognito.tf
    ├── 30-api-gateway.tf
    ├── 40-s3.tf
    ├── 41-dynamodb.tf
    ├── 50-lambda.tf
    ├── 60-eventbridge.tf
    ├── 72-waf.tf
    ├── 80-cloudwatch-logs.tf
    ├── 81-metrics-and-alarms.tf
    ├── 83-sns.tf
    ├── locals.tf
    ├── outputs.tf
    ├── variables.tf
    ├── scripts/
    └── lambda/
        └── src/
```

## Lambda Source Layout

Lambda functions live in individual folders under each lab's `terraform/lambda/src/` directory. Each function folder can include its own `test_events/` folder.

```text
terraform/lambda/src/
├── jedi_python/
├── sith_node/
├── unused_token_detector/
├── waf_bedrock_analyzer/
├── waf_threat_correlation_agent/
├── soar_response_agent/              # lab_12a and later
├── executive_dashboard_agent/        # lab_12b and later
└── compliance_agent/                 # lab_12c only
```

## Shared Templates

The `shared/templates/lab_templates/` directory contains deployable starter templates for Phase 1. The `phase-1-init.sh` script uses these templates to check or deploy missing files into `phase_1/` without overwriting existing work.

```text
shared/templates/lab_templates/
├── lab_12_template/
├── lab_12a_template/
├── lab_12b_template/
└── lab_12c_template/
```