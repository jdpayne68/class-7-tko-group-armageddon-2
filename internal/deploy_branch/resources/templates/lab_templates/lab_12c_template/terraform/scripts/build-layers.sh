#!/usr/bin/env bash

set -euo pipefail

# ===================================================================
# CONFIGURATION
# ===================================================================

REQUIREMENTS=("boto3>=1.34" "botocore>=1.34" "reportlab==4.4.3")
LAYER_NAME="reportlab-layer"
LAYER_PYTHON_VERSION="python3.12"
LAYER_PYTHON_MINOR="3.12"
LAYER_PLATFORM="manylinux2014_x86_64"
LAYER_DIR_NAME="reportlab-layer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ===================================================================
# COLORS
# ===================================================================

if [ "${FORCE_COLOR:-false}" = "true" ]; then
    RESET="$(printf '\033[0m')"
    GREEN="$(printf '\033[32m')"
    RED="$(printf '\033[31m')"
    YELLOW="$(printf '\033[33m')"
    CYAN="$(printf '\033[36m')"
    BOLD_GREEN="$(printf '\033[1;32m')"
    BOLD_RED="$(printf '\033[1;31m')"
    BOLD_YELLOW="$(printf '\033[1;33m')"
    BOLD_CYAN="$(printf '\033[1;36m')"
    BOLD_BLUE="$(printf '\033[1;34m')"
    BOLD_WHITE="$(printf '\033[1;37m')"
elif [ "${NO_COLOR:-false}" != "true" ] && [ -t 1 ] && [ "$TERM" != "dumb" ]; then
    RESET="$(printf '\033[0m')"
    GREEN="$(printf '\033[32m')"
    RED="$(printf '\033[31m')"
    YELLOW="$(printf '\033[33m')"
    CYAN="$(printf '\033[36m')"
    BOLD_GREEN="$(printf '\033[1;32m')"
    BOLD_RED="$(printf '\033[1;31m')"
    BOLD_YELLOW="$(printf '\033[1;33m')"
    BOLD_CYAN="$(printf '\033[1;36m')"
    BOLD_BLUE="$(printf '\033[1;34m')"
    BOLD_WHITE="$(printf '\033[1;37m')"
else
    RESET=""
    GREEN=""
    RED=""
    YELLOW=""
    CYAN=""
    BOLD_GREEN=""
    BOLD_RED=""
    BOLD_YELLOW=""
    BOLD_CYAN=""
    BOLD_BLUE=""
    BOLD_WHITE=""
fi

log_tag() { printf "%s[%s]%s" "$2" "$1" "$RESET"; }
log_info() { printf "%s %s\n" "$(log_tag INFO "$CYAN")" "$*"; }
log_ok() { printf "%sOK:%s      %s\n" "$GREEN" "$RESET" "$*"; }
log_warn() { printf "%s %s\n" "$(log_tag WARN "$YELLOW")" "$*"; }
log_error() { printf "%s %s%s%s\n" "$(log_tag ERROR "$RED")" "$RED" "$*" "$RESET" >&2; }
log_step() { printf "\n%s %s\n" "$(log_tag STEP "$BOLD_BLUE")" "$*"; }
log_section() {
    printf "\n%s%s%s\n" "$BOLD_WHITE" "============================================================" "$RESET"
    printf "%s%s%s\n" "$BOLD_WHITE" "$*" "$RESET"
    printf "%s%s%s\n" "$BOLD_WHITE" "============================================================" "$RESET"
}
log_success() { printf "\n%s✅ %s%s\n" "$BOLD_GREEN" "$*" "$RESET"; }
log_failure() { printf "\n%s❌ %s%s\n" "$BOLD_RED" "$*" "$RESET"; }
log_reminder() { printf "\n%s🔔 %s%s\n" "$BOLD_CYAN" "$*" "$RESET"; }


# ===================================================================
# INPUT HELPERS
# ===================================================================

confirm_replace() {
    local path="$1"
    local answer

    if [ ! -t 0 ]; then
        log_error "Existing layer content requires replacement: $path"
        log_error "Run again with --force in automation, or run interactively and confirm replacement."
        return 1
    fi

    log_warn "Existing layer content will be replaced: $path"
    printf "Continue and rebuild the layer? [y/N] "
    read -r answer

    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}


# ===================================================================
# BUILD FUNCTIONS
# ===================================================================

build_layer() {
    local root_dir="$1"
    local force="$2"

    local layer_path="${root_dir}/lambda/layers/${LAYER_DIR_NAME}"

    log_step "Building Lambda layer..."

    if [ -e "$layer_path" ]; then
        local site_packages="${layer_path}/python/lib/${LAYER_PYTHON_VERSION}/site-packages"
        if [ "$force" != "true" ] && [ -d "$layer_path" ] && [ -d "$site_packages/boto3/docs" ] && [ -d "$site_packages/botocore/docs" ] && [ -d "$site_packages/reportlab" ]; then
            log_success "Layer already exists and is valid"
            return 0
        fi

        if [ "$force" != "true" ]; then
            if ! confirm_replace "$layer_path"; then
                log_warn "Layer rebuild cancelled. Existing content was preserved."
                return 1
            fi
        else
            log_info "Force rebuild requested."
        fi

        log_info "Replacing existing layer content..."
        rm -rf "$layer_path"
    fi

    local layer_site_packages="${layer_path}/python/lib/${LAYER_PYTHON_VERSION}/site-packages"
    mkdir -p "$layer_site_packages"

    log_info "Installing Lambda-compatible packages..."
    log_info "Platform: $LAYER_PLATFORM"
    python3 -m pip install \
        --upgrade \
        --platform "$LAYER_PLATFORM" \
        --implementation cp \
        --python-version "$LAYER_PYTHON_MINOR" \
        --only-binary=:all: \
        --target "$layer_site_packages" \
        "${REQUIREMENTS[@]}"

    if [ ! -d "${layer_site_packages}/boto3/docs" ]; then
        log_error "boto3/docs not found in layer"
        return 1
    fi

    if [ ! -d "${layer_site_packages}/botocore/docs" ]; then
        log_error "botocore/docs not found in layer"
        return 1
    fi

    if [ ! -f "${layer_site_packages}/boto3/docs/__init__.py" ]; then
        touch "${layer_site_packages}/boto3/docs/__init__.py"
    fi

    if [ ! -f "${layer_site_packages}/botocore/docs/__init__.py" ]; then
        touch "${layer_site_packages}/botocore/docs/__init__.py"
    fi

    log_ok "Layer built at: $layer_path"
    return 0
}

verify_layer() {
    local layer_path="$1"

    log_step "Verifying layer..."

    local site_packages="${layer_path}/python/lib/${LAYER_PYTHON_VERSION}/site-packages"
    if [ ! -d "$site_packages" ]; then
        log_error "Site-packages directory not found"
        return 1
    fi

    if [ ! -d "$site_packages/reportlab" ]; then
        log_error "reportlab package not found"
        return 1
    fi

    if [ ! -d "$site_packages/boto3" ]; then
        log_error "boto3 package not found"
        return 1
    fi

    if [ ! -d "$site_packages/boto3/docs" ]; then
        log_error "boto3/docs package not found"
        return 1
    fi

    if [ ! -d "$site_packages/botocore/docs" ]; then
        log_error "botocore/docs package not found"
        return 1
    fi

    if PYTHONPATH="$site_packages" python3 -c "
import reportlab
import boto3
import boto3.docs
import botocore.docs
print('All imports successful')
" >/dev/null 2>&1; then
        log_ok "Local import check passed"
    else
        log_warn "Local import check skipped or failed"
        log_warn "This can happen when Linux wheels are built on macOS"
    fi

    log_ok "Layer structure contains reportlab, boto3/docs, and botocore/docs"
    return 0
}

# ===================================================================
# MAIN
# ===================================================================

main() {
    local force_rebuild=false
    local root_dir="$DEFAULT_ROOT_DIR"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force) force_rebuild=true; shift ;;
            --help)
                echo ""
                echo "Usage: $0 [--force] [ROOT_DIR]"
                echo ""
                echo "  --force    Force rebuild"
                echo "  ROOT_DIR   Terraform root directory (default: script parent)"
                echo ""
                exit 0
                ;;
            *) root_dir="$1"; shift ;;
        esac
    done

    root_dir="$(cd "$root_dir" 2>/dev/null && pwd || echo "$root_dir")"

    # ============================================================
    # START
    # ============================================================
    log_section "λ Lambda Layer Builder λ"
    log_info "Root directory: $root_dir"
    local layer_path="${root_dir}/lambda/layers/${LAYER_DIR_NAME}"
    log_info "Layer location: $layer_path"

    # ============================================================
    # CHECK PYTHON
    # ============================================================
    log_step "Checking Python..."

    if ! command -v python3 &> /dev/null; then
        log_error "python3 not found"
        exit 1
    fi
    log_ok "Python found: $(python3 --version)"

    # ============================================================
    # CHECK VIRTUAL ENVIRONMENT
    # ============================================================
    log_step "Checking virtual environment..."

    if [ -z "${VIRTUAL_ENV:-}" ]; then
        log_error "No virtual environment detected!"
        log_error "Please activate your venv first: source .venv/bin/activate"
        exit 1
    fi
    log_ok "Virtual environment: $VIRTUAL_ENV"

    # ============================================================
    # BUILD LAYER
    # ============================================================
    if ! build_layer "$root_dir" "$force_rebuild"; then
        log_failure "Layer build failed!"
        exit 1
    fi

    # ============================================================
    # VERIFY LAYER
    # ============================================================
    if ! verify_layer "$layer_path"; then
        log_failure "Layer verification failed!"
        exit 1
    fi

    # ============================================================
    # SUMMARY
    # ============================================================
    local size_mb
    size_mb=$(du -sm "$layer_path" 2>/dev/null | cut -f1)

    log_section "✅ Build Complete!"
    log_info "Location: $layer_path"
    log_info "Size: ${size_mb} MB"
    log_info "Python version: $LAYER_PYTHON_VERSION"
    log_info "Requirements: ${REQUIREMENTS[*]}"

    log_success "Layer is ready to deploy!"
    log_reminder "Run terraform apply from this lab's terraform directory to package and publish the layer."

}

main "$@"
