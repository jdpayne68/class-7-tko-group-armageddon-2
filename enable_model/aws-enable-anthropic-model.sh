#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Global variables
MODELS_ARRAY=()
CURRENT_VIEW=""

# Function to normalize "back" input - handles back, BACK, BaCk, b, B, etc.
is_back_command() {
    local input=$1
    # Convert to lowercase for comparison
    local lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    # Check if it's 'back' or 'b'
    if [[ "$lower_input" == "back" ]] || [[ "$lower_input" == "b" ]]; then
        return 0  # True - it's a back command
    else
        return 1  # False - not a back command
    fi
}

# Function to list all available models with numbers
list_all_models() {
    local region=$1
    local filter=${2:-"all"}  # all, active, or provider filter
    
    log "Fetching all foundation models in $region..."
    echo ""
    
    # Build query based on filter
    local query='modelSummaries[*].{ModelID:modelId, Provider:providerName, Status:modelLifecycle.status}'
    
    if [ "$filter" == "active" ]; then
        query='modelSummaries[?modelLifecycle.status==`ACTIVE`].{ModelID:modelId, Provider:providerName, Status:modelLifecycle.status}'
    fi
    
    # Get models as JSON
    local models_json=$(aws bedrock list-foundation-models \
        --region "$region" \
        --query "$query" \
        --output json 2>/dev/null)
    
    if [ -z "$models_json" ] || [ "$models_json" == "[]" ] || [ "$models_json" == "null" ]; then
        warn "No models found in $region"
        return 1
    fi
    
    # Print header
    printf "${CYAN}%-5s | %-55s | %-20s | %-12s${NC}\n" "#" "Model ID" "Provider" "Status"
    printf "${CYAN}%-5s-+-%-55s-+-%-20s-+-%-12s${NC}\n" "-----" "-------------------------------------------------------" "--------------------" "------------"
    
    # Parse and print with numbers
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
        model_id=$(echo "$line" | jq -r '.ModelID')
        provider=$(echo "$line" | jq -r '.Provider')
        status=$(echo "$line" | jq -r '.Status')
        
        # Color status
        if [ "$status" == "ACTIVE" ]; then
            status_colored="${GREEN}ACTIVE${NC}"
        elif [ "$status" == "LEGACY" ]; then
            status_colored="${YELLOW}LEGACY${NC}"
        else
            status_colored="${RED}$status${NC}"
        fi
        
        printf "%-5s | %-55s | %-20s | " "$count" "$model_id" "$provider"
        echo -e "$status_colored"
    done < <(echo "$models_json" | jq -c '.[]')
    
    echo ""
    log "Total: $count models available"
    echo ""
    echo -e "${YELLOW}Type 'back' or 'b' to return to main menu${NC}"
    echo ""
    
    # Store models in a global array for later use
    MODELS_ARRAY=()
    while IFS= read -r line; do
        MODELS_ARRAY+=("$(echo "$line" | jq -r '.ModelID')")
    done < <(echo "$models_json" | jq -c '.[]')
    
    CURRENT_VIEW="list"
    return 0
}

# Function to filter models by provider
list_models_by_provider() {
    local region=$1
    local provider=$2
    
    log "Fetching models from provider: $provider in $region..."
    echo ""
    
    local models_json=$(aws bedrock list-foundation-models \
        --region "$region" \
        --query "modelSummaries[?providerName=='$provider' && modelLifecycle.status=='ACTIVE'].{ModelID:modelId, Provider:providerName, Status:modelLifecycle.status}" \
        --output json 2>/dev/null)
    
    if [ -z "$models_json" ] || [ "$models_json" == "[]" ]; then
        warn "No active models found for provider: $provider"
        echo -e "${BLUE}[INFO]${NC} Try again with a different provider name."
        echo ""
        return 1
    fi
    
    # Print header
    printf "${CYAN}%-5s | %-55s | %-20s | %-12s${NC}\n" "#" "Model ID" "Provider" "Status"
    printf "${CYAN}%-5s-+-%-55s-+-%-20s-+-%-12s${NC}\n" "-----" "-------------------------------------------------------" "--------------------" "------------"
    
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
        model_id=$(echo "$line" | jq -r '.ModelID')
        provider=$(echo "$line" | jq -r '.Provider')
        status=$(echo "$line" | jq -r '.Status')
        
        printf "%-5s | %-55s | %-20s | ${GREEN}%-12s${NC}\n" "$count" "$model_id" "$provider" "$status"
    done < <(echo "$models_json" | jq -c '.[]')
    
    echo ""
    log "Total: $count models from $provider"
    echo ""
    echo -e "${YELLOW}Type 'back' or 'b' to return to main menu${NC}"
    echo ""
    
    # Store models in global array
    MODELS_ARRAY=()
    while IFS= read -r line; do
        MODELS_ARRAY+=("$(echo "$line" | jq -r '.ModelID')")
    done < <(echo "$models_json" | jq -c '.[]')
    
    CURRENT_VIEW="provider"
    return 0
}

# Function to get model by number
get_model_by_number() {
    local num=$1
    if [ -z "$MODELS_ARRAY" ]; then
        error "No models loaded. Please list models first."
    fi
    
    if [ "$num" -ge 1 ] && [ "$num" -le "${#MODELS_ARRAY[@]}" ]; then
        echo "${MODELS_ARRAY[$((num-1))]}"
        return 0
    else
        return 1
    fi
}

# Function to display main menu
show_main_menu() {
    clear
    echo ""
    info "========================================"
    info "Amazon Bedrock Model Access Setup"
    info "========================================"
    echo ""
    echo "Select an option:"
    echo "  1) Show ALL models"
    echo "  2) Show only ACTIVE models"
    echo "  3) Filter by provider"
    echo "  4) Exit"
    echo ""
}

# Function to handle model selection with back support
select_model_with_back() {
    local prompt="Enter model number to select, or 'back' to return: "
    
    while true; do
        echo ""
        read -p "$prompt" MODEL_SELECTION
        
        # Check for back command (case insensitive)
        if is_back_command "$MODEL_SELECTION"; then
            return 1  # User wants to go back
        fi
        
        # Validate number
        if [[ "$MODEL_SELECTION" =~ ^[0-9]+$ ]]; then
            MODEL_ID=$(get_model_by_number "$MODEL_SELECTION")
            if [ $? -eq 0 ]; then
                log "✓ Selected model: $MODEL_ID"
                return 0  # Successfully selected model
            else
                warn "Invalid number. Please select between 1 and ${#MODELS_ARRAY[@]}"
            fi
        else
            warn "Invalid input. Enter a number or 'back' to return."
        fi
    done
}

# Main script starts here
read -p "Enter AWS Region [us-east-1]: " AWS_REGION_INPUT
AWS_REGION="${AWS_REGION_INPUT:-us-east-1}"

# Prerequisites check first
log "Checking prerequisites..."
command -v aws >/dev/null 2>&1 || error "AWS CLI not found. Please install it and retry."
aws --version >/dev/null 2>&1 || error "AWS CLI malfunctioning."
command -v jq >/dev/null 2>&1 || error "jq not found. Please install it."
command -v base64 >/dev/null 2>&1 || error "base64 not found. Please install or check PATH."

aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials invalid or not configured."
aws configure get region >/dev/null 2>&1 || warn "AWS CLI region not set, using $AWS_REGION"

# Main menu loop
while true; do
    show_main_menu
    read -p "Your choice [1-4]: " MENU_CHOICE
    
    case $MENU_CHOICE in
        1)
            list_all_models "$AWS_REGION" "all"
            # After showing models, allow user to select or go back
            if [ $? -eq 0 ]; then
                if select_model_with_back; then
                    break 2  # Model selected, proceed
                fi
                # Otherwise, user went back - loop continues
            else
                # No models found, wait for back command
                echo ""
                echo -e "${YELLOW}Type 'back' or 'b' to return to main menu${NC}"
                while true; do
                    echo ""
                    read -p "Enter 'back' to return: " BACK_INPUT
                    if is_back_command "$BACK_INPUT"; then
                        break
                    else
                        warn "Please type 'back' or 'b' to return"
                    fi
                done
            fi
            ;;
        2)
            list_all_models "$AWS_REGION" "active"
            if [ $? -eq 0 ]; then
                if select_model_with_back; then
                    break 2
                fi
            else
                echo ""
                echo -e "${YELLOW}Type 'back' or 'b' to return to main menu${NC}"
                while true; do
                    echo ""
                    read -p "Enter 'back' to return: " BACK_INPUT
                    if is_back_command "$BACK_INPUT"; then
                        break
                    else
                        warn "Please type 'back' or 'b' to return"
                    fi
                done
            fi
            ;;
        3)
            while true; do
                # Get provider input
                echo ""
                echo "Common providers:"
                echo "  - Anthropic"
                echo "  - Amazon"
                echo "  - Meta"
                echo "  - Cohere"
                echo "  - AI21 Labs"
                echo "  - Stability AI"
                echo "  - Mistral AI"
                echo ""
                read -p "Enter provider name (or type 'back' to return): " PROVIDER_INPUT
                
                # Check for back command (case insensitive)
                if is_back_command "$PROVIDER_INPUT"; then
                    break  # Go back to main menu
                fi
                
                PROVIDER="$PROVIDER_INPUT"
                echo ""
                
                # Try to list models for this provider
                list_models_by_provider "$AWS_REGION" "$PROVIDER"
                if [ $? -eq 0 ]; then
                    # Models found, allow selection
                    if select_model_with_back; then
                        break 3  # Model selected, break all loops
                    fi
                    # User went back from model selection, break provider loop to go to main menu
                    break
                else
                    # No models found, loop continues to ask for provider again
                    # The warning and info messages were already shown by list_models_by_provider
                    echo ""
                    continue
                fi
            done
            ;;
        4)
            log "Exiting..."
            exit 0
            ;;
        *)
            warn "Invalid option. Please select 1-4."
            sleep 1
            ;;
    esac
done

# Get company information
echo ""
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

# Step 1: List offers
log "Listing offers for model: $MODEL_ID"
OFFER_JSON=$(aws bedrock list-foundation-model-agreement-offers --region "$AWS_REGION" --model-id "$MODEL_ID" 2>/dev/null) || {
    error "Error querying offers for $MODEL_ID. This might mean:"
    echo "  1. The model is not available in this region"
    echo "  2. The model ID is incorrect"
    echo "  3. You don't have permissions to access this model"
    echo ""
    echo "Available model IDs in $AWS_REGION:"
    list_all_models "$AWS_REGION"
    exit 1
}

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

# Create the model access form file
MODEL_ACCESS_FORM="model-access-form.json"
cat > "$MODEL_ACCESS_FORM" << EOF
{
  "companyName": "$COMPANY_NAME",
  "companyWebsite": "$COMPANY_WEBSITE",
  "intendedUsers": "0",
  "industryOption": "Software as a Service",
  "otherIndustryOption": "",
  "useCases": "Internal development and testing."
}
EOF

# Output the path to the model access form
FORM_PATH="$(pwd)/$MODEL_ACCESS_FORM"
log "Model access form created at: $FORM_PATH"
log "Form contents:"
cat "$MODEL_ACCESS_FORM" | jq '.' || cat "$MODEL_ACCESS_FORM"

FORM_B64=$(base64 < "$MODEL_ACCESS_FORM" | tr -d '\n')
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
    echo "Error output: $INVOKE_OUTPUT"
else
    log "✓ Model invocation test successful"
    echo "Response: $INVOKE_OUTPUT" | jq '.' 2>/dev/null || echo "$INVOKE_OUTPUT"
fi

# Output final summary with form path
log "========================================"
log "✓ Model access enabled successfully for $MODEL_ID"
log "📋 Model access form saved at: $FORM_PATH"
log "🔑 OFFER_ID: $OFFER_ID"
log "🌐 Region: $AWS_REGION"
log "========================================"