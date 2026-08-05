#!/usr/bin/env bash
set -Eeuo pipefail

# Armageddon 2 Phase 1 repository scaffold
#
# Usage:
#   ./setup-armageddon-phase1.sh
#   ./setup-armageddon-phase1.sh /path/to/repository
#
# The script is idempotent:
# - Existing files are preserved.
# - Missing directories and starter files are created.
# - Empty implementation directories receive .gitkeep files.

PROJECT_ROOT="${1:-$(pwd)}"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "ERROR: Directory does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

cd "$PROJECT_ROOT"

if [[ ! -d ".git" ]]; then
  echo "WARNING: $PROJECT_ROOT does not appear to be a Git repository." >&2
  echo "The scaffold will still be created." >&2
fi

create_file() {
  local path="$1"
  local content="${2:-}"

  mkdir -p "$(dirname "$path")"

  if [[ -e "$path" ]]; then
    echo "KEEP   $path"
    return
  fi

  printf '%s' "$content" > "$path"
  echo "CREATE $path"
}

create_dir() {
  local path="$1"
  mkdir -p "$path"
  echo "DIR    $path"
}

echo
echo "Creating Armageddon 2 Phase 1 structure in:"
echo "  $PROJECT_ROOT"
echo

# -------------------------------------------------------------------
# Directories
# -------------------------------------------------------------------

directories=(
  "phase-1/terraform"
  "phase-1/src"
  "phase-1/layers/dashboard"
  "phase-1/test-events"
  "phase-1/evidence/lab12"
  "phase-1/evidence/lab12a"
  "phase-1/evidence/lab12b"
  "phase-1/sample-output/pdf"
  "phase-1/sample-output/json"
  "phase-2"
  "docs"
  ".github"
)

for directory in "${directories[@]}"; do
  create_dir "$directory"
done

# -------------------------------------------------------------------
# Root files
# -------------------------------------------------------------------

create_file ".gitignore" '# macOS
.DS_Store
__MACOSX/

# Terraform
**/.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log
terraform.tfvars
*.auto.tfvars
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Lambda build artifacts
phase-1/build/
phase-1/lambda-packages/
phase-1/layers/**/python/
*.zip

# Python
__pycache__/
*.py[cod]
.pytest_cache/
.venv/
venv/

# Environment and secrets
.env
.env.*
!.env.example
*.pem
*.key
credentials
credentials.*

# IDE
.vscode/
.idea/

# Logs
*.log
'

create_file "README.md" '# Class 7 TKO Group Armageddon 2

Group submission repository for Armageddon 2.

## Phase 1

- Lab 12: WAF event analysis and threat correlation
- Lab 12a: SOAR response automation
- Lab 12b: Executive security reporting

See [Phase 1](./phase-1/) for the implementation.
'

create_file "CONTRIBUTING.md" '# Contributing

1. Do not push directly to `main`.
2. Create work from the latest approved base branch.
3. Never commit AWS credentials, private keys, `.env` files, real `terraform.tfvars`, or Terraform state.
4. Run formatting and validation before opening a pull request.
5. Include validation evidence and cleanup instructions.
6. Use clear commit messages such as:
   - `feat(lab12): add WAF correlation Lambda`
   - `fix(iam): allow correlation agent to publish EventBridge events`
   - `docs: add Phase 1 deployment instructions`
'

create_file ".github/pull_request_template.md" '## Summary

Describe the lab work included in this pull request.

## Labs

- [ ] Lab 12
- [ ] Lab 12a
- [ ] Lab 12b

## Validation

- [ ] `terraform fmt -check -recursive`
- [ ] `terraform validate`
- [ ] Python files compile
- [ ] No credentials, state files, or private values are committed
- [ ] AWS resources were tested
- [ ] Evidence was added
- [ ] Cleanup steps were documented

## Test results

Describe the tests performed and their results.

## Known issues

List any remaining problems or write `None`.
'

# -------------------------------------------------------------------
# Phase documentation
# -------------------------------------------------------------------

create_file "phase-1/README.md" '# Armageddon 2: Phase 1

## Architecture

```text
Client
  |
  v
API Gateway
  |
  v
Application Lambda

API Gateway requests are inspected by AWS WAF
  |
  v
CloudWatch WAF Logs
  |
  v
WAF Bedrock Analyzer
  |
  v
DynamoDB: waf-events
  |
  v
Threat Correlation Agent
  |
  v
DynamoDB: waf-correlation-findings
  |
  v
EventBridge
  |
  v
SOAR Response Agent
  |-- SNS notification
  |-- DynamoDB: security-incidents
  `-- Finding status update

Executive Dashboard Agent
  |-- Reads all three DynamoDB tables
  |-- Invokes Amazon Bedrock
  `-- Writes PDF and JSON reports to Amazon S3
```

## Labs

- Lab 12: analyzer and correlation pipeline
- Lab 12a: EventBridge and SOAR response
- Lab 12b: executive PDF and JSON reporting

## Deployment

Complete the Terraform implementation, then run:

```bash
cd terraform
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Do not run `terraform apply` until the plan and expected cost have been reviewed.
'

create_file "phase-2/README.md" '# Armageddon 2: Phase 2

Phase 2 labs will be added when assigned.
'

create_file "docs/architecture.md" '# Architecture

Document the final deployed architecture, resource names, data flow, trust boundaries, and failure paths here.
'

create_file "docs/deployment-guide.md" '# Deployment Guide

Document prerequisites, deployment commands, required Bedrock model access, validation steps, and expected outputs here.
'

create_file "docs/security-design.md" '# Security Design

Document IAM roles, least-privilege policies, encryption, logging, secrets handling, and human-approval controls here.
'

create_file "docs/troubleshooting.md" '# Troubleshooting

Record errors, root causes, fixes, and validation commands here.
'

create_file "docs/cleanup.md" '# Cleanup

List every AWS resource that must be removed after testing.

Include:

- API Gateway
- Lambda functions and layers
- EventBridge rules and targets
- SNS topics and subscriptions
- DynamoDB tables
- S3 report bucket objects and bucket
- WAF Web ACL and association
- CloudWatch log groups
- IAM roles and policies
'

# -------------------------------------------------------------------
# Terraform starter files
# -------------------------------------------------------------------

create_file "phase-1/terraform/versions.tf" 'terraform {
  required_version = ">= 1.5.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
'

create_file "phase-1/terraform/provider.tf" 'provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
'

create_file "phase-1/terraform/variables.tf" 'variable "aws_region" {
  description = "AWS Region used for the lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for named AWS resources."
  type        = string
  default     = "armageddon-2"
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model or inference profile ID."
  type        = string
}

variable "report_bucket_name" {
  description = "Globally unique S3 bucket name for executive reports."
  type        = string
}

variable "notification_email" {
  description = "Email address used for the optional SNS subscription."
  type        = string
  default     = ""
}
'

create_file "phase-1/terraform/terraform.tfvars.example" 'aws_region          = "us-east-1"
project_name        = "armageddon-2"
bedrock_model_id    = "<enabled-bedrock-model-or-inference-profile-id>"
report_bucket_name  = "<globally-unique-report-bucket-name>"
notification_email  = "<optional-email-address>"
'

create_file "phase-1/terraform/locals.tf" 'locals {
  common_tags = {
    Project     = var.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
  }

  function_names = {
    application = "${var.project_name}-protected-api"
    analyzer    = "${var.project_name}-waf-analyzer"
    correlation = "${var.project_name}-threat-correlation"
    soar        = "${var.project_name}-soar-response"
    dashboard   = "${var.project_name}-executive-dashboard"
  }
}
'

create_file "phase-1/terraform/data.tf" 'data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}
'

terraform_placeholders=(
  "api-gateway.tf"
  "waf.tf"
  "cloudwatch.tf"
  "dynamodb.tf"
  "s3.tf"
  "sns.tf"
  "lambda-application.tf"
  "lambda-analyzer.tf"
  "lambda-correlation.tf"
  "lambda-soar.tf"
  "lambda-dashboard.tf"
  "iam-application.tf"
  "iam-analyzer.tf"
  "iam-correlation.tf"
  "iam-soar.tf"
  "iam-dashboard.tf"
  "eventbridge-schedules.tf"
  "eventbridge-routing.tf"
  "outputs.tf"
)

for filename in "${terraform_placeholders[@]}"; do
  title="${filename%.tf}"
  create_file "phase-1/terraform/$filename" "# ${title}

# TODO: Implement this component.
"
done

# -------------------------------------------------------------------
# Python source placeholders
# -------------------------------------------------------------------

create_file "phase-1/src/protected_api_handler.py" '"""Simple API Lambda protected by AWS WAF."""

import json
from typing import Any


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Return a small response so API Gateway traffic can be tested."""

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "Armageddon 2 protected API is running.",
            }
        ),
    }
'

python_placeholders=(
  "waf_bedrock_analyzer.py"
  "waf_threat_correlation_agent.py"
  "soar_response_agent.py"
  "executive_dashboard_agent.py"
)

for filename in "${python_placeholders[@]}"; do
  create_file "phase-1/src/$filename" "\"\"\"Replace this placeholder with the reviewed instructor-provided ${filename}.\"\"\"
"
done

create_file "phase-1/layers/dashboard/requirements.txt" 'reportlab==4.4.3
'

create_file "phase-1/layers/dashboard/README.md" '# Executive dashboard Lambda layer

`reportlab` is not included in the standard AWS Lambda Python runtime.

Build this layer in a Lambda-compatible Linux environment. Do not commit the generated `python/` directory or ZIP archive.
'

# -------------------------------------------------------------------
# Test event templates
# -------------------------------------------------------------------

create_file "phase-1/test-events/analyzer.json" '{}
'

create_file "phase-1/test-events/correlation.json" '{
  "correlation_window_minutes": 60
}
'

create_file "phase-1/test-events/soar.json" '{
  "version": "0",
  "id": "example-event-id",
  "detail-type": "WAF Threat Finding Created",
  "source": "seir.waf.correlation",
  "account": "000000000000",
  "time": "2026-01-01T00:00:00Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "finding_id": "replace-with-test-finding-id",
    "severity": "HIGH",
    "risk_score": 75
  }
}
'

create_file "phase-1/test-events/dashboard.json" '{
  "report_period_hours": 24
}
'

# -------------------------------------------------------------------
# Preserve empty directories
# -------------------------------------------------------------------

find \
  phase-1/evidence \
  phase-1/sample-output \
  -type d -empty \
  -exec touch {}/.gitkeep \;

echo
echo "Scaffold complete."
echo
echo "Next commands:"
echo "  git status"
echo "  git add ."
echo '  git commit -m "chore: add Armageddon 2 Phase 1 scaffold"'
echo "  git push"
echo
echo "Existing files were preserved."
