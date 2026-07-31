#!/usr/bin/env bash

set -euo pipefail

# ===================================================================
# CONFIGURATION
# ===================================================================

REQUIREMENTS=("boto3>=1.34" "botocore>=1.34" "reportlab==4.4.3")
LAYER_NAME="reportlab-layer"
LAYER_PYTHON_VERSION="python3.12"
LAYER_DIR_NAME="reportlab-layer"

# ===================================================================
# COLORS
# ===================================================================

if [ -t 1 ] && [ "$TERM" != "dumb" ]; then
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

log_info() { printf "%sINFO:%s    %s\n" "$CYAN" "$RESET" "$*"; }
log_ok() { printf "%sOK:%s      %s\n" "$GREEN" "$RESET" "$*"; }
log_warn() { printf "%sWARN:%s    %s\n" "$YELLOW" "$RESET" "$*"; }
log_error() { printf "%sERROR:%s   %s\n" "$RED" "$RESET" "$*"; }
log_step() { printf "\n%sSTEP:%s    %s\n" "$BOLD_BLUE" "$RESET" "$*"; }
log_section() {
    printf "\n%s%s%s\n" "$BOLD_WHITE" "============================================================" "$RESET"
    printf "%s%s%s\n" "$BOLD_WHITE" "$*" "$RESET"
    printf "%s%s%s\n" "$BOLD_WHITE" "============================================================" "$RESET"
}
log_success() { printf "\n%s✅ %s%s\n" "$BOLD_GREEN" "$*" "$RESET"; }
log_failure() { printf "\n%s❌ %s%s\n" "$BOLD_RED" "$*" "$RESET"; }
log_reminder() { printf "\n%s🔔 %s%s\n" "$BOLD_CYAN" "$*" "$RESET"; }


# ===================================================================
# BUILD FUNCTIONS
# ===================================================================

build_layer() {
    local root_dir="$1"
    local force="$2"

    local layer_path="${root_dir}/layers/${LAYER_DIR_NAME}"

    log_step "Building Lambda layer..."

    if [ "$force" = "true" ] && [ -d "$layer_path" ]; then
        log_info "Force rebuild requested, removing existing layer..."
        rm -rf "$layer_path"
    fi

    if [ "$force" != "true" ] && [ -d "$layer_path" ]; then
        local site_packages="${layer_path}/python/lib/${LAYER_PYTHON_VERSION}/site-packages"
        if [ -d "$site_packages/botocore/docs" ] && [ -d "$site_packages/reportlab" ]; then
            log_success "Layer already exists and is valid"
            return 0
        fi
    fi

    local site_packages
    site_packages=$(python3 -c "import site; print(site.getsitepackages()[0])")

    if [ ! -d "$site_packages" ]; then
        log_error "Could not find site-packages in venv"
        return 1
    fi

    log_info "Site-packages: $site_packages"

    local layer_site_packages="${layer_path}/python/lib/${LAYER_PYTHON_VERSION}/site-packages"
    mkdir -p "$(dirname "$layer_site_packages")"

    log_info "Copying site-packages to layer..."
    cp -r "$site_packages"/* "$layer_site_packages"/

    log_info "Cleaning up unnecessary files (preserving botocore/docs)..."

    find "$layer_path" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$layer_path" -type f -name "*.pyc" -delete 2>/dev/null || true
    find "$layer_path" -type d -name "test" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true
    find "$layer_path" -type d -name "tests" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true
    find "$layer_path" -type d -name "docs" -not -path "*/botocore/docs*" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true
    find "$layer_path" -type d -name "examples" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true

    if [ ! -d "${layer_site_packages}/botocore/docs" ]; then
        log_warn "botocore/docs missing, restoring from venv..."
        if [ -d "${site_packages}/botocore/docs" ]; then
            mkdir -p "${layer_site_packages}/botocore"
            cp -r "${site_packages}/botocore/docs" "${layer_site_packages}/botocore/"
            log_ok "Restored botocore/docs"
        else
            log_error "botocore/docs not found in venv!"
            return 1
        fi
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

    if ! PYTHONPATH="$site_packages" python3 -c "
import reportlab
import boto3
import botocore.docs
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
print('All imports successful')
" 2>/dev/null; then
        log_error "Layer verification failed"
        return 1
    fi

    log_ok "All dependencies imported successfully (including botocore.docs)"
    return 0
}

# ===================================================================
# MAIN
# ===================================================================

main() {
    local force_rebuild=false
    local root_dir="."

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force) force_rebuild=true; shift ;;
            --help)
                echo ""
                echo "Usage: $0 [--force] [ROOT_DIR]"
                echo ""
                echo "  --force    Force rebuild"
                echo "  ROOT_DIR   Root directory (default: current)"
                echo ""
                exit 0
                ;;
            *) root_dir="$1"; shift ;;
        esac
    done

    if [ "$root_dir" = "." ]; then
        root_dir="$(pwd)"
    else
        root_dir="$(cd "$root_dir" 2>/dev/null && pwd || echo "$root_dir")"
    fi

    # ============================================================
    # START
    # ============================================================
    log_section "λ Lambda Layer Builder λ"
    log_info "Root directory: $root_dir"
    local layer_path="${root_dir}/layers/${LAYER_DIR_NAME}"
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
    log_reminder "Move layers/ folder to /lambda root directory if needed"

}

main "$@"