#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Colors And Logging
# ==================================================

if { [ -t 1 ] && [ "${TERM:-}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; } || [ -n "${FORCE_COLOR:-}" ]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  CYAN=$'\033[0;36m'
  WHITE=$'\033[0;37m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  WHITE=""
  BOLD=""
  RESET=""
fi

log_info() {
  printf "%b %b%s%b\n" "${CYAN}[INFO]${RESET}" "$WHITE" "$*" "$RESET"
}

log_warn() {
  printf "%b %b%s%b\n" "${YELLOW}[WARN]${RESET}" "$WHITE" "$*" "$RESET"
}

log_error() {
  printf "%b %b%s%b\n" "${RED}[ERROR]${RESET}" "$RED" "$*" "$RESET" >&2
}

log_step() {
  printf "\n%b %b%s%b\n" "${BLUE}[STEP]${RESET}" "$WHITE" "$*" "$RESET"
}

log_success() {
  printf "%b %b%s%b\n" "${GREEN}OK:${RESET}" "$WHITE" "$*" "$RESET"
}

die() {
  log_error "$*"
  exit 1
}

header() {
  local title="$1"
  local width=${#title}
  printf "\n%b%s%b\n" "$BOLD" "$(printf '%*s' "$width" '' | tr ' ' '=')" "$RESET"
  printf "%b%s%b\n" "$BOLD" "$title" "$RESET"
  printf "%b%s%b\n\n" "$BOLD" "$(printf '%*s' "$width" '' | tr ' ' '=')" "$RESET"
}

sub_header() {
  local title="$1"
  local width=${#title}
  printf "\n%b%s%b\n" "$WHITE" "$(printf '%*s' "$width" '' | tr ' ' '-')" "$RESET"
  printf "%b%s%b\n" "$WHITE" "$title" "$RESET"
  printf "%b%s%b\n" "$WHITE" "$(printf '%*s' "$width" '' | tr ' ' '-')" "$RESET"
}

# Backward-compatible names used by the original script.
log() { log_info "$@"; }
warn() { log_warn "$@"; }
error() { die "$@"; }
info() { log_info "$@"; }

# ==================================================
# Globals
# ==================================================

MODELS_ARRAY=()
CURRENT_VIEW=""
MODEL_ID=""
MODEL_SELECTED="false"

# ==================================================
# Input Helpers
# ==================================================

is_back_command() {
  local input=${1:-}
  local lower_input

  lower_input=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')
  [ "$lower_input" = "back" ] || [ "$lower_input" = "b" ]
}

pause_for_enter() {
  local prompt=${1:-"Press Enter to continue..."}
  printf "\n%s" "$prompt"
  read -r _
}

# ==================================================
# Model Listing
# ==================================================

print_model_table() {
  local models_json="$1"
  local count=0
  local model_id provider status status_color

  printf "%b%-5s | %-55s | %-20s | %-12s%b\n" "$CYAN" "#" "Model ID" "Provider" "Status" "$RESET"
  printf "%b%-5s-+-%-55s-+-%-20s-+-%-12s%b\n" "$CYAN" "-----" "-------------------------------------------------------" "--------------------" "------------" "$RESET"

  MODELS_ARRAY=()

  while IFS= read -r line; do
    count=$((count + 1))
    model_id=$(printf '%s' "$line" | jq -r '.ModelID')
    provider=$(printf '%s' "$line" | jq -r '.Provider')
    status=$(printf '%s' "$line" | jq -r '.Status')

    case "$status" in
      ACTIVE) status_color="$GREEN" ;;
      LEGACY) status_color="$YELLOW" ;;
      *) status_color="$RED" ;;
    esac

    printf "%-5s | %-55s | %-20s | %b%-12s%b\n" "$count" "$model_id" "$provider" "$status_color" "$status" "$RESET"
    MODELS_ARRAY+=("$model_id")
  done < <(printf '%s' "$models_json" | jq -c '.[]')

  printf "\n"
  log_info "Total: $count models available"
  printf "\n%bType 'back' or 'b' to return to main menu%b\n" "$YELLOW" "$RESET"
}

list_all_models() {
  local region="$1"
  local filter=${2:-all}
  local query models_json

  log_step "Fetching foundation models in $region"

  query='modelSummaries[*].{ModelID:modelId, Provider:providerName, Status:modelLifecycle.status}'
  if [ "$filter" = "active" ]; then
    query='modelSummaries[?modelLifecycle.status==`ACTIVE`].{ModelID:modelId, Provider:providerName, Status:modelLifecycle.status}'
  fi

  if ! models_json=$(aws bedrock list-foundation-models \
    --region "$region" \
    --query "$query" \
    --output json 2>/dev/null); then
    log_warn "Unable to fetch foundation models in $region."
    return 1
  fi

  if [ -z "$models_json" ] || [ "$models_json" = "[]" ] || [ "$models_json" = "null" ]; then
    log_warn "No models found in $region."
    return 1
  fi

  print_model_table "$models_json"
  CURRENT_VIEW="list"
  return 0
}

list_models_by_provider() {
  local region="$1"
  local provider="$2"
  local models_json filtered_json count

  log_step "Searching provider: $provider"

  if ! models_json=$(aws bedrock list-foundation-models \
    --region "$region" \
    --query 'modelSummaries[?modelLifecycle.status==`ACTIVE`].{ModelID:modelId, Provider:providerName, Status:modelLifecycle.status}' \
    --output json 2>/dev/null); then
    log_warn "Unable to fetch active foundation models in $region."
    return 1
  fi

  filtered_json=$(printf '%s' "$models_json" | jq --arg provider "$provider" '[.[] | select((.Provider // "" | ascii_downcase) == ($provider | ascii_downcase))]')
  count=$(printf '%s' "$filtered_json" | jq 'length')

  if [ "$count" -eq 0 ]; then
    log_warn "No active models found for provider: $provider"
    log_info "Check the provider spelling or choose a common provider from the list."
    return 1
  fi

  print_model_table "$filtered_json"
  log_info "Provider: $provider"
  CURRENT_VIEW="provider"
  return 0
}

# ==================================================
# Model Selection
# ==================================================

get_model_by_number() {
  local num="$1"

  if [ "${#MODELS_ARRAY[@]}" -eq 0 ]; then
    log_warn "No models are loaded. List models first."
    return 1
  fi

  if [ "$num" -ge 1 ] && [ "$num" -le "${#MODELS_ARRAY[@]}" ]; then
    printf '%s\n' "${MODELS_ARRAY[$((num - 1))]}"
    return 0
  fi

  return 1
}

select_model_with_back() {
  local model_selection

  while true; do
    printf "\nEnter model number to select, or 'back' to return: "
    read -r model_selection

    if is_back_command "$model_selection"; then
      return 1
    fi

    if [[ "$model_selection" =~ ^[0-9]+$ ]]; then
      if MODEL_ID=$(get_model_by_number "$model_selection"); then
        log_success "Selected model: $MODEL_ID"
        return 0
      fi

      log_warn "Invalid number. Select between 1 and ${#MODELS_ARRAY[@]}."
    else
      log_warn "Invalid input. Enter a number or 'back' to return."
    fi
  done
}

# ==================================================
# Menu
# ==================================================

show_main_menu() {
  if [ -n "${TERM:-}" ] && command -v clear >/dev/null 2>&1; then
    clear || true
  fi

  header "Amazon Bedrock Model Access Setup"
  printf "Select an option:\n"
  printf "  1) Show all models\n"
  printf "  2) Show only active models\n"
  printf "  3) Filter by provider\n"
  printf "  4) Exit\n\n"
}

show_provider_menu() {
  sub_header "Common Providers"
  printf "  - Anthropic\n"
  printf "  - Amazon\n"
  printf "  - Meta\n"
  printf "  - Cohere\n"
  printf "  - AI21 Labs\n"
  printf "  - Stability AI\n"
  printf "  - Mistral AI\n\n"
}

# ==================================================
# Prerequisites
# ==================================================

read -r -p "Enter AWS Region [us-east-1]: " AWS_REGION_INPUT
AWS_REGION="${AWS_REGION_INPUT:-us-east-1}"

log_step "Checking prerequisites"
command -v aws >/dev/null 2>&1 || die "AWS CLI not found. Install it and retry."
aws --version >/dev/null 2>&1 || die "AWS CLI is installed but not responding correctly."
command -v jq >/dev/null 2>&1 || die "jq not found. Install jq and retry."
command -v base64 >/dev/null 2>&1 || die "base64 not found. Install it or check PATH."

aws sts get-caller-identity >/dev/null 2>&1 || die "AWS credentials are invalid or not configured."
aws configure get region >/dev/null 2>&1 || log_warn "AWS CLI region is not set; using $AWS_REGION."

# ==================================================
# Main Menu Loop
# ==================================================

while [ "$MODEL_SELECTED" != "true" ]; do
  show_main_menu
  read -r -p "Your choice [1-4]: " MENU_CHOICE

  case "$MENU_CHOICE" in
    1)
      if list_all_models "$AWS_REGION" "all"; then
        if select_model_with_back; then
          MODEL_SELECTED="true"
        fi
      else
        pause_for_enter "Press Enter to return to main menu..."
      fi
      ;;
    2)
      if list_all_models "$AWS_REGION" "active"; then
        if select_model_with_back; then
          MODEL_SELECTED="true"
        fi
      else
        pause_for_enter "Press Enter to return to main menu..."
      fi
      ;;
    3)
      show_provider_menu
      read -r -p "Enter provider name, or type 'back' to return: " PROVIDER_INPUT

      if is_back_command "$PROVIDER_INPUT"; then
        continue
      fi

      if [ -z "$PROVIDER_INPUT" ]; then
        log_warn "Provider name cannot be blank."
        pause_for_enter "Press Enter to return to main menu..."
        continue
      fi

      if list_models_by_provider "$AWS_REGION" "$PROVIDER_INPUT"; then
        if select_model_with_back; then
          MODEL_SELECTED="true"
        fi
      else
        pause_for_enter "Press Enter to return to main menu..."
      fi
      ;;
    4)
      log_info "Exiting."
      exit 0
      ;;
    *)
      log_warn "Invalid option. Select 1, 2, 3, or 4."
      sleep 1
      ;;
  esac
done

# ==================================================
# Company Information
# ==================================================

printf "\n"
read -r -p "Enter Company Name [Kirk DevSecOps]: " COMPANY_NAME_INPUT
COMPANY_NAME="${COMPANY_NAME_INPUT:-Kirk DevSecOps}"

read -r -p "Enter Company Website [https://kirkdevsecops.com]: " COMPANY_WEBSITE_INPUT
COMPANY_WEBSITE="${COMPANY_WEBSITE_INPUT:-https://kirkdevsecops.com}"

export AWS_REGION
export MODEL_ID

log_info "Using region: $AWS_REGION"
log_info "Using model ID: $MODEL_ID"
log_info "Using company name: $COMPANY_NAME"
log_info "Using company website: $COMPANY_WEBSITE"

# ==================================================
# Enable Model Access
# ==================================================

log_step "Listing offers for model: $MODEL_ID"
if ! OFFER_JSON=$(aws bedrock list-foundation-model-agreement-offers --region "$AWS_REGION" --model-id "$MODEL_ID" 2>/dev/null); then
  log_error "Error querying offers for $MODEL_ID."
  log_info "Possible causes: unavailable model in region, incorrect model ID, or missing permissions."
  log_info "Available active models in $AWS_REGION:"
  list_all_models "$AWS_REGION" "active" || true
  exit 1
fi

if [ -z "$OFFER_JSON" ] || [ "$OFFER_JSON" = "{}" ] || ! printf '%s' "$OFFER_JSON" | grep -q "offers"; then
  die "No offers found for model: $MODEL_ID"
fi

OFFER_ID=$(printf '%s' "$OFFER_JSON" | jq -r '.offers[0].offerId')
OFFER_TOKEN=$(printf '%s' "$OFFER_JSON" | jq -r '.offers[0].offerToken')

[ -n "$OFFER_ID" ] && [ "$OFFER_ID" != "null" ] || die "Failed to extract OFFER_ID from response."
[ -n "$OFFER_TOKEN" ] && [ "$OFFER_TOKEN" != "null" ] || die "Failed to extract OFFER_TOKEN from response."

log_info "OFFER_ID: $OFFER_ID"
log_info "OFFER_TOKEN: ${OFFER_TOKEN:0:50}..."

log_step "Submitting use case"
MODEL_ACCESS_FORM="model-access-form.json"
cat > "$MODEL_ACCESS_FORM" <<EOF
{
  "companyName": "$COMPANY_NAME",
  "companyWebsite": "$COMPANY_WEBSITE",
  "intendedUsers": "0",
  "industryOption": "Software as a Service",
  "otherIndustryOption": "",
  "useCases": "Internal development and testing."
}
EOF

FORM_PATH="$(pwd)/$MODEL_ACCESS_FORM"
log_info "Model access form created at: $FORM_PATH"
log_info "Form contents:"
jq '.' "$MODEL_ACCESS_FORM" || cat "$MODEL_ACCESS_FORM"

FORM_B64=$(base64 < "$MODEL_ACCESS_FORM" | tr -d '\n')
aws bedrock put-use-case-for-model-access --region "$AWS_REGION" --form-data "$FORM_B64" || die "Use case submission failed."
log_success "Use case submitted successfully."

log_step "Accepting marketplace agreement"
RESPONSE=$(aws bedrock create-foundation-model-agreement \
  --region "$AWS_REGION" \
  --model-id "$MODEL_ID" \
  --offer-token "$OFFER_TOKEN") || die "Marketplace agreement failed."

if printf '%s' "$RESPONSE" | grep -q "modelId"; then
  log_success "Agreement created successfully: $(printf '%s' "$RESPONSE" | jq -r '.modelId')"
else
  die "Agreement creation failed: $RESPONSE"
fi

log_step "Verifying access"
sleep 5
aws bedrock get-foundation-model-agreement --region "$AWS_REGION" --model-id "$MODEL_ID" || die "Verification failed."

log_step "Testing model invocation"
if INVOKE_OUTPUT=$(aws bedrock-runtime invoke-model \
  --region "$AWS_REGION" \
  --model-id "$MODEL_ID" \
  --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":50,"messages":[{"role":"user","content":"Hello, can you help me?"}]}' \
  --content-type 'application/json' \
  /tmp/bedrock-invoke-response.json 2>&1); then
  log_success "Model invocation request completed."
  jq '.' /tmp/bedrock-invoke-response.json 2>/dev/null || cat /tmp/bedrock-invoke-response.json
else
  log_warn "Model invocation test failed or may need time to propagate."
  printf "%s\n" "$INVOKE_OUTPUT"
fi

header "Model Access Complete"
log_success "Model access enabled successfully for $MODEL_ID"
log_info "Model access form saved at: $FORM_PATH"
log_info "OFFER_ID: $OFFER_ID"
log_info "Region: $AWS_REGION"
