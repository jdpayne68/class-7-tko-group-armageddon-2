#!/bin/bash
set -e

# ---------------------------------------------------------
# Colors
# ---------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------------------------------------------------------
# User Input
# ---------------------------------------------------------
read -p "Enter AWS Region [us-east-1]: " AWS_REGION_INPUT
AWS_REGION="${AWS_REGION_INPUT:-us-east-1}"

read -p "Enter Model ID [anthropic.claude-3-sonnet-20240229-v1:0]: " MODEL_ID_INPUT
MODEL_ID="${MODEL_ID_INPUT:-anthropic.claude-3-sonnet-20240229-v1:0}"

read -p "Enter Company Name [Kirk DevSecOps]: " COMPANY_NAME_INPUT
COMPANY_NAME="${COMPANY_NAME_INPUT:-Kirk DevSecOps}"

read -p "Enter Company Website [https://kirkdevsecops.com]: " COMPANY_WEBSITE_INPUT
COMPANY_WEBSITE="${COMPANY_WEBSITE_INPUT:-https://kirkdevsecops.com}"

export AWS_REGION
export MODEL_ID

log "Region: $AWS_REGION"
log "Model: $MODEL_ID"
log "Company: $COMPANY_NAME"
log "Website: $COMPANY_WEBSITE"

# ---------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------
log "Checking prerequisites..."

command -v aws >/dev/null 2>&1 || error "AWS CLI not found."
command -v jq  >/dev/null 2>&1 || error "jq not found."
command -v base64 >/dev/null 2>&1 || error "base64 not found."

aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials invalid."
aws configure get region >/dev/null 2>&1 || warn "AWS CLI region not set; using $AWS_REGION"

# ---------------------------------------------------------
# Step 1: List Offers
# ---------------------------------------------------------
log "Listing offers for model: $MODEL_ID"

OFFER_JSON=$(aws bedrock list-foundation-model-agreement-offers \
    --region "$AWS_REGION" \
    --model-id "$MODEL_ID" 2>/dev/null) || error "Error querying offers."

if [ -z "$OFFER_JSON" ] || ! echo "$OFFER_JSON" | grep -q "offers"; then
    error "No offers found for model: $MODEL_ID"
fi

OFFER_ID=$(echo "$OFFER_JSON" | jq -r '.offers[0].offerId')
OFFER_TOKEN=$(echo "$OFFER_JSON" | jq -r '.offers[0].offerToken')

[ -z "$OFFER_ID" ]    && error "Failed to extract OFFER_ID"
[ -z "$OFFER_TOKEN" ] && error "Failed to extract OFFER_TOKEN"

log "Offer ID: $OFFER_ID"
log "Offer Token: ${OFFER_TOKEN:0:50}..."

# ---------------------------------------------------------
# Step 2: Submit Use Case
# ---------------------------------------------------------
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

aws bedrock put-use-case-for-model-access \
    --region "$AWS_REGION" \
    --form-data "$FORM_B64" || error "Use case submission failed."

log "Use case submitted."

# ---------------------------------------------------------
# Step 3: Accept Agreement
# ---------------------------------------------------------
log "Accepting marketplace agreement..."

RESPONSE=$(aws bedrock create-foundation-model-agreement \
    --region "$AWS_REGION" \
    --model-id "$MODEL_ID" \
    --offer-token "$OFFER_TOKEN" 2>&1)

if echo "$RESPONSE" | grep -q "Agreement already exists"; then
    log "Agreement already exists — continuing."
elif echo "$RESPONSE" | grep -q "modelId"; then
    log "Agreement created successfully."
else
    error "Agreement creation failed: $RESPONSE"
fi

# ---------------------------------------------------------
# Step 4: Verify
# ---------------------------------------------------------
log "Verifying access..."
sleep 5

aws bedrock list-foundation-model-agreement-offers \
    --model-id "$MODEL_ID" \
    --region "$AWS_REGION"

# ---------------------------------------------------------
# Step 5: Test Invocation
# ---------------------------------------------------------
log "Testing model invocation..."

PAYLOAD=$(echo -n '{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 200,
  "messages": [
    {
      "role": "user",
      "content": [
        { "type": "text", "text": "Hello Claude 3 Sonnet!" }
      ]
    }
  ]
}' | base64)

aws bedrock-runtime invoke-model \
  --region "$AWS_REGION" \
  --model-id "$MODEL_ID" \
  --body "$PAYLOAD" \
  --content-type application/json \
  invoke_output.json

if [ -f invoke_output.json ]; then
    log "✓ Invocation complete — check invoke_output.json"
else
    warn "Invocation may have failed — no output file found."
fi

log "✓ Model access enabled successfully for $MODEL_ID"
