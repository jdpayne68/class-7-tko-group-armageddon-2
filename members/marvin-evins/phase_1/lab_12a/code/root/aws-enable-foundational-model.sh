#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Prompt for AWS region and model id if not provided
read -p "Enter AWS Region [us-east-1]: " AWS_REGION_INPUT
AWS_REGION="${AWS_REGION_INPUT:-us-east-1}"

read -p "Enter Model ID [us.anthropic.claude-sonnet-4-6]: " MODEL_ID_INPUT
MODEL_ID="${MODEL_ID_INPUT:-us.anthropic.claude-sonnet-4-6}"

read -p "Enter Company Name [Kirk DevSecOps]: " COMPANY_NAME_INPUT
COMPANY_NAME="${COMPANY_NAME_INPUT:-Kirk DevSecOps}"

read -p "Enter Company Website [https://kirkdevsecops.com]: " COMPANY_WEBSITE_INPUT
COMPANY_WEBSITE="${COMPANY_WEBSITE_INPUT:-https://kirkdevsecops.com}"

export AWS_REGION
export MODEL_ID

log "Using region: $AWS_REGION"
log "Using model ID: $MODEL_ID"
log "Using company name: $COMPANY_NAME"
log "Using company website: $COMPANY_WEBSITE"

# Prerequisites check
log "Checking prerequisites..."
command -v aws >/dev/null 2>&1 || error "AWS CLI not found. Please install it and retry."
aws --version >/dev/null 2>&1 || error "AWS CLI malfunctioning."
command -v jq >/dev/null 2>&1 || error "jq not found. Please install it."
command -v base64 >/dev/null 2>&1 || error "base64 not found. Please install or check PATH."

aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials invalid or not configured."
aws configure get region >/dev/null 2>&1 || warn "AWS CLI region not set, using $AWS_REGION"

# Step 1: List offers
log "Listing offers for model: $MODEL_ID"
OFFER_JSON=$(aws bedrock list-foundation-model-agreement-offers --region "$AWS_REGION" --model-id "$MODEL_ID" 2>/dev/null) || error "Error querying offers for $MODEL_ID"

if [ -z "$OFFER_JSON" ] || [ "$OFFER_JSON" == "{}" ] || ! echo "$OFFER_JSON" | grep -q "offers"; then
    error "No offers found for model: $MODEL_ID"
fi

OFFER_ID=$(echo "$OFFER_JSON" | jq -r '.offers[0].offerId')
OFFER_TOKEN=$(echo "$OFFER_JSON" | jq -r '.offers[0].offerToken')

[ -z "$OFFER_ID" ] || [ "$OFFER_ID" == "null" ] && error "Failed to extract OFFER_ID from response"
[ -z "$OFFER_TOKEN" ] || [ "$OFFER_TOKEN" == "null" ] && error "Failed to extract OFFER_TOKEN from response"

log "OFFER_ID: $OFFER_ID"
log "OFFER_TOKEN: ${OFFER_TOKEN:0:50}..."

# Step 2: Submit use case
log "Submitting use case..."
cat > form.json << EOF
{
  "companyName": "$COMPANY_NAME",
  "companyWebsite": "$COMPANY_WEBSITE",
  "intendedUsers": "0",
  "industryOption": "Software as a Service",
  "otherIndustryOption": "",
  "useCases": "Internal development and testing."
}
EOF

FORM_B64=$(base64 < form.json | tr -d '\n')
aws bedrock put-use-case-for-model-access --region "$AWS_REGION" --form-data "$FORM_B64" || error "Use case submission failed"
log "Use case submitted successfully"

# Step 3: Accept agreement
log "Accepting marketplace agreement..."
RESPONSE=$(aws bedrock create-foundation-model-agreement \
    --region "$AWS_REGION" \
    --model-id "$MODEL_ID" \
    --offer-token "$OFFER_TOKEN") || error "Marketplace agreement failed"

if echo "$RESPONSE" | grep -q "modelId"; then
    log "Agreement created successfully: $(echo "$RESPONSE" | jq -r '.modelId')"
else
    error "Agreement creation failed: $RESPONSE"
fi

# Step 4: Verify
log "Verifying access..."
sleep 5  # Wait for propagation
aws bedrock get-foundation-model-agreement --region "$AWS_REGION" --model-id "$MODEL_ID" || error "Verification failed"

# Step 5: Test invocation
log "Testing model invocation..."
INVOKE_OUTPUT=$(aws bedrock invoke-model \
  --region "$AWS_REGION" \
  --model-id "$MODEL_ID" \
  --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":50,"messages":[{"role":"user","content":"Hello, can you help me?"}]}' \
  --content-type 'application/json' 2>&1)

if echo "$INVOKE_OUTPUT" | grep -qi "error"; then
    warn "Model invocation test failed or may take time to propagate."
else
    log "✓ Model invocation test successful"
fi

log "✓ Model access enabled successfully for $MODEL_ID"
