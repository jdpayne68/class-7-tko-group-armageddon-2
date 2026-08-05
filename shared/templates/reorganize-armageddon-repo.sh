#!/usr/bin/env bash
set -Eeuo pipefail

MODE="dry-run"

case "${1:-}" in
  "") ;;
  --apply) MODE="apply" ;;
  -h|--help)
    cat <<'EOF'
Usage:
  ./reorganize-armageddon-repo.sh
  ./reorganize-armageddon-repo.sh --apply

Without --apply, the script only prints the planned changes.
EOF
    exit 0
    ;;
  *)
    echo "ERROR: Unknown argument: $1" >&2
    exit 1
    ;;
esac

ROOT="$(pwd)"
REPO_NAME="$(basename "$ROOT")"

if [[ ! -d ".git" ]]; then
  echo "ERROR: Run this from the Git repository root." >&2
  exit 1
fi

if [[ ! -d "phase-1" ]]; then
  echo "ERROR: phase-1/ was not found." >&2
  exit 1
fi

run() {
  if [[ "$MODE" == "dry-run" ]]; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ensure_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "KEEP DIR: $dir"
  else
    run mkdir -p "$dir"
  fi
}

is_tracked() {
  git ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

safe_move() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "MISSING:  $src"
    return
  fi

  if [[ -e "$dst" ]]; then
    echo "SKIP:     $dst already exists"
    return
  fi

  ensure_dir "$(dirname "$dst")"

  if is_tracked "$src"; then
    echo "GIT MOVE: $src -> $dst"
    run git mv -- "$src" "$dst"
  else
    echo "MOVE:     $src -> $dst"
    run mv -- "$src" "$dst"
  fi
}

safe_create_file() {
  local path="$1"
  local content="$2"

  if [[ -e "$path" ]]; then
    echo "KEEP FILE: $path"
    return
  fi

  ensure_dir "$(dirname "$path")"

  if [[ "$MODE" == "dry-run" ]]; then
    echo "DRY-RUN: create $path"
  else
    printf '%s' "$content" > "$path"
    echo "CREATE:   $path"
  fi
}

replace_in_tf_files() {
  local search="$1"
  local replacement="$2"

  if [[ "$MODE" == "dry-run" ]]; then
    echo "DRY-RUN: replace '$search' with '$replacement' in Terraform files"
    return
  fi

  find phase-1/lab12/terraform -maxdepth 1 -type f -name '*.tf' -print0 |
  while IFS= read -r -d '' file; do
    SEARCH="$search" REPLACEMENT="$replacement" perl -0pi -e '
      my $search = $ENV{"SEARCH"};
      my $replacement = $ENV{"REPLACEMENT"};
      s/\Q$search\E/$replacement/g;
    ' "$file"
  done
}

append_gitignore_pattern() {
  local pattern="$1"

  if [[ -f ".gitignore" ]] && grep -Fqx "$pattern" .gitignore; then
    echo "KEEP IGNORE: $pattern"
    return
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    echo "DRY-RUN: append '$pattern' to .gitignore"
  else
    printf '%s\n' "$pattern" >> .gitignore
    echo "ADD IGNORE: $pattern"
  fi
}

echo
echo "Repository: $ROOT"
echo "Mode:       $MODE"
echo

if [[ "$MODE" == "apply" ]]; then
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup="../${REPO_NAME}-pre-reorg-${timestamp}.tar.gz"

  echo "Creating backup: $backup"

  tar \
    --exclude='.git' \
    --exclude='.terraform' \
    --exclude='*.tfstate' \
    --exclude='*.tfstate.*' \
    -czf "$backup" \
    phase-1 \
    README.md \
    CONTRIBUTING.md \
    repo-structure.md \
    docs \
    shared \
    .github \
    .gitignore \
    2>/dev/null || {
      echo "ERROR: Backup creation failed." >&2
      exit 1
    }

  echo "Backup complete."
  echo
fi

target_dirs=(
  "phase-1/lab12/code/foundation"
  "phase-1/lab12/code/lab12"
  "phase-1/lab12/code/lab12a"
  "phase-1/lab12/code/lab12b"
  "phase-1/lab12/terraform"
  "phase-1/lab12/layers/dashboard"
  "phase-1/lab12/test-events"
  "phase-1/lab12/evidence/lab12"
  "phase-1/lab12/evidence/lab12a"
  "phase-1/lab12/evidence/lab12b"
  "phase-1/lab12/sample-output/pdf"
  "phase-1/lab12/sample-output/json"
)

for dir in "${target_dirs[@]}"; do
  ensure_dir "$dir"
done

safe_move "phase-1/README.md" "phase-1/lab12/README.md"

safe_create_file "phase-1/README.md" '# Phase 1

The cumulative Armageddon 2 implementation is maintained in:

- [Lab 12, Lab 12a, and Lab 12b](./lab12/)
'

safe_move "phase-1/src/protected_api_handler.py" \
  "phase-1/lab12/code/foundation/protected_api_handler.py"

safe_move "phase-1/src/waf_bedrock_analyzer.py" \
  "phase-1/lab12/code/lab12/waf_bedrock_analyzer.py"

safe_move "phase-1/src/waf_threat_correlation_agent.py" \
  "phase-1/lab12/code/lab12/waf_threat_correlation_agent.py"

safe_move "phase-1/src/soar_response_agent.py" \
  "phase-1/lab12/code/lab12a/soar_response_agent.py"

safe_move "phase-1/src/executive_dashboard_agent.py" \
  "phase-1/lab12/code/lab12b/executive_dashboard_agent.py"

terraform_moves=(
  "versions.tf|versions.tf"
  "provider.tf|provider.tf"
  "variables.tf|variables.tf"
  "locals.tf|locals.tf"
  "data.tf|data.tf"
  "api-gateway.tf|foundation-apigateway.tf"
  "cloudwatch.tf|foundation-cloudwatch.tf"
  "lambda-application.tf|foundation-lambda.tf"
  "waf.tf|foundation-waf.tf"
  "iam-application.tf|foundation-iam.tf"
  "dynamodb.tf|lab12-dynamodb.tf"
  "lambda-analyzer.tf|lab12-lambda-analyzer.tf"
  "lambda-correlation.tf|lab12-lambda-correlation.tf"
  "iam-analyzer.tf|lab12-iam-analyzer.tf"
  "iam-correlation.tf|lab12-iam-correlation.tf"
  "eventbridge-schedules.tf|lab12-schedules.tf"
  "lambda-soar.tf|lab12a-lambda-soar.tf"
  "iam-soar.tf|lab12a-iam-soar.tf"
  "eventbridge-routing.tf|lab12a-eventbridge.tf"
  "sns.tf|lab12a-sns.tf"
  "lambda-dashboard.tf|lab12b-lambda-dashboard.tf"
  "iam-dashboard.tf|lab12b-iam-dashboard.tf"
  "s3.tf|lab12b-s3.tf"
  "outputs.tf|outputs.tf"
  "terraform.tfvars.example|terraform.tfvars.example"
)

for mapping in "${terraform_moves[@]}"; do
  src_name="${mapping%%|*}"
  dst_name="${mapping##*|}"
  safe_move "phase-1/terraform/$src_name" \
    "phase-1/lab12/terraform/$dst_name"
done

safe_move "phase-1/layers/dashboard/requirements.txt" \
  "phase-1/lab12/layers/dashboard/requirements.txt"

safe_move "phase-1/layers/dashboard/README.md" \
  "phase-1/lab12/layers/dashboard/README.md"

safe_move "phase-1/test-events/analyzer.json" \
  "phase-1/lab12/test-events/lab12-analyzer.json"

safe_move "phase-1/test-events/correlation.json" \
  "phase-1/lab12/test-events/lab12-correlation.json"

safe_move "phase-1/test-events/soar.json" \
  "phase-1/lab12/test-events/lab12a-soar.json"

safe_move "phase-1/test-events/dashboard.json" \
  "phase-1/lab12/test-events/lab12b-dashboard.json"

for lab in lab12 lab12a lab12b; do
  safe_move "phase-1/evidence/$lab/.gitkeep" \
    "phase-1/lab12/evidence/$lab/.gitkeep"
done

safe_move "phase-1/sample-output/pdf/.gitkeep" \
  "phase-1/lab12/sample-output/pdf/.gitkeep"

safe_move "phase-1/sample-output/json/.gitkeep" \
  "phase-1/lab12/sample-output/json/.gitkeep"

replace_in_tf_files "../src/protected_api_handler.py" \
  "../code/foundation/protected_api_handler.py"

replace_in_tf_files "../src/waf_bedrock_analyzer.py" \
  "../code/lab12/waf_bedrock_analyzer.py"

replace_in_tf_files "../src/waf_threat_correlation_agent.py" \
  "../code/lab12/waf_threat_correlation_agent.py"

replace_in_tf_files "../src/soar_response_agent.py" \
  "../code/lab12a/soar_response_agent.py"

replace_in_tf_files "../src/executive_dashboard_agent.py" \
  "../code/lab12b/executive_dashboard_agent.py"

append_gitignore_pattern "phase-1/lab12/build/"
append_gitignore_pattern "phase-1/lab12/lambda-packages/"
append_gitignore_pattern "phase-1/lab12/layers/**/python/"
append_gitignore_pattern "phase-1/lab12/terraform/terraform.tfvars"

old_dirs=(
  "phase-1/src"
  "phase-1/terraform"
  "phase-1/layers/dashboard"
  "phase-1/layers"
  "phase-1/test-events"
  "phase-1/evidence/lab12"
  "phase-1/evidence/lab12a"
  "phase-1/evidence/lab12b"
  "phase-1/evidence"
  "phase-1/sample-output/pdf"
  "phase-1/sample-output/json"
  "phase-1/sample-output"
)

for dir in "${old_dirs[@]}"; do
  if [[ -d "$dir" ]]; then
    if [[ -z "$(find "$dir" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
      echo "REMOVE EMPTY DIR: $dir"
      run rmdir "$dir"
    else
      echo "REVIEW DIR: $dir still contains unmapped files"
    fi
  fi
done

echo
if [[ "$MODE" == "dry-run" ]]; then
  echo "No files were changed."
  echo "Run with --apply after reviewing the plan."
else
  echo "Reorganization completed."
  echo
  echo "Next:"
  echo "  find phase-1 -maxdepth 4 -type f | sort"
  echo "  git status"
  echo "  git diff --stat"
fi
