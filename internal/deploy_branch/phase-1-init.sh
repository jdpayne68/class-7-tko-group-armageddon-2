#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# ==================================================
# Configuration
# ==================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
TEMPLATE_ROOT="${TEMPLATE_ROOT:-$REPO_ROOT/shared/templates/lab_templates}"
PHASE_ROOT="${PHASE_ROOT:-$REPO_ROOT/phase_1}"

MODE="interactive"
ASSUME_YES="false"
SHOW_DIFFS="false"

LABS=(
  "lab_12"
  "lab_12a"
  "lab_12b"
  "lab_12c"
)

SELECTED_LABS=()


# ==================================================
# Headers And Logging
# ==================================================

RESET="\033[0m"
GREEN="\033[92m"
RED="\033[91m"
CYAN="\033[96m"
MAGENTA="\033[95m"
YELLOW="\033[93m"
BLUE="\033[94m"
WHITE="\033[97m"
BOLD="\033[1m"

USE_COLOR=false
if [ "${FORCE_COLOR:-false}" = "true" ]; then
  USE_COLOR=true
elif [ "${NO_COLOR:-false}" != "true" ] && [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  USE_COLOR=true
fi

should_color() {
  [ "$USE_COLOR" = "true" ]
}

color_text() {
  local color="$1"
  shift

  if should_color; then
    printf "%b%s%b" "$color" "$*" "$RESET"
  else
    printf "%s" "$*"
  fi
}

line_for() {
  local char="$1"
  local title="$2"
  local length=${#title}

  printf "%${length}s" "" | tr " " "$char"
}

header() {
  local title="$1"
  local color="${2:-$BOLD}"
  local line

  line="$(line_for "=" "$title")"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
  color_text "$color" "$title"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
}

sub_header() {
  local title="$1"
  local color="${2:-$BLUE}"
  local line

  line="$(line_for "-" "$title")"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
  color_text "$color" "$title"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
}

short_header() {
  local title="$1"
  local color="${2:-$CYAN}"

  printf "\n"
  color_text "$color" "--- $title ---"
  printf "\n"
}

log_tag() {
  local tag="$1"
  local color="$2"

  color_text "$color" "[$tag]"
}

log_info() {
  printf "%s %s\n" "$(log_tag INFO "$CYAN")" "$*"
}

log_step() {
  printf "\n%s %s\n" "$(log_tag STEP "$BLUE")" "$*"
}

log_warn() {
  printf "%s %s\n" "$(log_tag WARN "$YELLOW")" "$*"
}

log_alert() {
  printf "%s " "$(log_tag ALERT "$RED")"
  color_text "$RED" "$*"
  printf "\n"
}

log_success() {
  color_text "$GREEN" "OK:"
  printf " %s\n" "$*"
}

log_error() {
  printf "%s " "$(log_tag ERROR "$RED")" >&2
  color_text "$RED" "$*" >&2
  printf "\n" >&2
}


# ==================================================
# Input Helpers
# ==================================================

usage() {
  cat <<USAGE
Usage:
  ./phase-1-init.sh [options]

Options:
  --check                  Check template and target status only.
  --deploy                 Copy missing files from templates into phase_1.
  --diffs                  Show files that already exist but differ.
  --yes                    Skip deploy confirmation prompts.
  --lab LAB                Limit to one lab. Can be used more than once.
                           Valid labs: lab_12, lab_12a, lab_12b, lab_12c
  --templates PATH         Override template root.
  --target PATH            Override phase_1 target root.
  -h, --help               Show this help.

Safety:
  Existing files are never overwritten or deleted.
  Missing files and directories are created only during deploy.
USAGE
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local answer

  read -r -p "$prompt " answer
  answer="${answer:-$default}"

  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_lab() {
  local candidate="$1"
  local lab

  for lab in "${LABS[@]}"; do
    if [ "$candidate" = "$lab" ]; then
      return 0
    fi
  done

  return 1
}

selected_labs() {
  if [ "${#SELECTED_LABS[@]}" -gt 0 ]; then
    printf "%s\n" "${SELECTED_LABS[@]}"
  else
    printf "%s\n" "${LABS[@]}"
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --check)
        MODE="check"
        shift
        ;;
      --deploy)
        MODE="deploy"
        shift
        ;;
      --diffs)
        SHOW_DIFFS="true"
        shift
        ;;
      --yes|-y)
        ASSUME_YES="true"
        shift
        ;;
      --lab)
        if [ "$#" -lt 2 ]; then
          log_error "--lab requires a value."
          exit 2
        fi
        if ! is_valid_lab "$2"; then
          log_error "Unknown lab: $2"
          exit 2
        fi
        SELECTED_LABS+=("$2")
        shift 2
        ;;
      --templates)
        if [ "$#" -lt 2 ]; then
          log_error "--templates requires a path."
          exit 2
        fi
        TEMPLATE_ROOT="$2"
        shift 2
        ;;
      --target)
        if [ "$#" -lt 2 ]; then
          log_error "--target requires a path."
          exit 2
        fi
        PHASE_ROOT="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 2
        ;;
    esac
  done
}


# ==================================================
# Path And File Helpers
# ==================================================

template_for_lab() {
  local lab="$1"

  printf "%s/%s_template" "$TEMPLATE_ROOT" "$lab"
}

target_for_lab() {
  local lab="$1"

  printf "%s/%s" "$PHASE_ROOT" "$lab"
}

is_ignored_file() {
  local path="$1"

  case "$path" in
    */.DS_Store) return 0 ;;
    *.zip) return 0 ;;
    *.tfstate|*.tfstate.*) return 0 ;;
    */tfplan|*/tfplan-*) return 0 ;;
    */.terraform/*) return 0 ;;
    */__pycache__/*) return 0 ;;
    *.pyc) return 0 ;;
    *) return 1 ;;
  esac
}

require_template_root() {
  if [ ! -d "$TEMPLATE_ROOT" ]; then
    log_error "Template root does not exist: $TEMPLATE_ROOT"
    exit 1
  fi
}

show_configuration() {
  sub_header "Configuration" "$WHITE"
  log_info "Repository root: $REPO_ROOT"
  log_info "Template root:   $TEMPLATE_ROOT"
  log_info "Phase 1 target:  $PHASE_ROOT"
  log_info "Selected labs:   $(selected_labs | tr '\n' ' ')"
}


# ==================================================
# Check Logic
# ==================================================

check_lab() {
  local lab="$1"
  local template_dir target_dir source_file rel target_file
  local total=0
  local missing=0
  local same=0
  local changed=0

  template_dir="$(template_for_lab "$lab")"
  target_dir="$(target_for_lab "$lab")"

  sub_header "$lab" "$BLUE"

  if [ ! -d "$template_dir" ]; then
    log_alert "Missing template: $template_dir"
    return 1
  fi

  if [ ! -d "$target_dir" ]; then
    log_warn "Target lab does not exist yet: $target_dir"
  fi

  while IFS= read -r source_file; do
    if is_ignored_file "$source_file"; then
      continue
    fi

    rel="${source_file#$template_dir/}"
    target_file="$target_dir/$rel"
    total=$((total + 1))

    if [ ! -e "$target_file" ]; then
      missing=$((missing + 1))
      continue
    fi

    if cmp -s "$source_file" "$target_file"; then
      same=$((same + 1))
    else
      changed=$((changed + 1))
      if [ "$SHOW_DIFFS" = "true" ]; then
        log_warn "Differs: $lab/$rel"
      fi
    fi
  done < <(find "$template_dir" -type f | sort)

  log_info "Template files: $total"
  log_info "Already matching: $same"
  log_info "Missing from target: $missing"
  log_info "Existing but different: $changed"
}

check_all() {
  local lab failed=0

  header "PHASE 1 TEMPLATE CHECK" "$BOLD"
  require_template_root
  show_configuration

  while IFS= read -r lab; do
    check_lab "$lab" || failed=1
  done < <(selected_labs)

  return "$failed"
}


# ==================================================
# Deploy Logic
# ==================================================

create_template_directories() {
  local template_dir="$1"
  local target_dir="$2"
  local source_dir rel target_dir_path

  while IFS= read -r source_dir; do
    rel="${source_dir#$template_dir/}"
    if [ "$rel" = "$source_dir" ]; then
      continue
    fi
    target_dir_path="$target_dir/$rel"
    mkdir -p "$target_dir_path"
  done < <(find "$template_dir" -type d | sort)
}

deploy_lab() {
  local lab="$1"
  local template_dir target_dir source_file rel target_file
  local copied=0
  local skipped=0
  local changed=0

  template_dir="$(template_for_lab "$lab")"
  target_dir="$(target_for_lab "$lab")"

  sub_header "$lab" "$BLUE"

  if [ ! -d "$template_dir" ]; then
    log_alert "Missing template: $template_dir"
    return 1
  fi

  mkdir -p "$target_dir"
  create_template_directories "$template_dir" "$target_dir"

  while IFS= read -r source_file; do
    if is_ignored_file "$source_file"; then
      continue
    fi

    rel="${source_file#$template_dir/}"
    target_file="$target_dir/$rel"

    if [ -e "$target_file" ]; then
      skipped=$((skipped + 1))
      if ! cmp -s "$source_file" "$target_file"; then
        changed=$((changed + 1))
        log_warn "Preserved existing different file: $lab/$rel"
      fi
      continue
    fi

    mkdir -p "$(dirname "$target_file")"
    cp -p "$source_file" "$target_file"
    copied=$((copied + 1))
    log_success "Created $lab/$rel"
  done < <(find "$template_dir" -type f | sort)

  log_info "Copied missing files: $copied"
  log_info "Preserved existing files: $skipped"
  log_info "Existing files with differences: $changed"
}

deploy_all() {
  local lab failed=0

  header "PHASE 1 TEMPLATE DEPLOY" "$BOLD"
  require_template_root
  show_configuration

  log_warn "Existing files will be preserved. Nothing will be deleted or overwritten."

  if [ "$ASSUME_YES" != "true" ]; then
    if ! prompt_yes_no "Deploy missing template files into phase_1? [y/N]" "n"; then
      log_warn "Deployment cancelled."
      return 0
    fi
  fi

  mkdir -p "$PHASE_ROOT"

  while IFS= read -r lab; do
    deploy_lab "$lab" || failed=1
  done < <(selected_labs)

  return "$failed"
}


# ==================================================
# Interactive Menu
# ==================================================

interactive_menu() {
  local choice

  header "PHASE 1 TEMPLATE INIT" "$BOLD"
  show_configuration

  while true; do
    sub_header "Actions" "$WHITE"
    printf "1. Check template status\n"
    printf "2. Deploy missing files\n"
    printf "3. Show differing existing files\n"
    printf "4. Quit\n"
    printf "\n"
    read -r -p "Select an option [1-4]: " choice

    case "$choice" in
      1)
        SHOW_DIFFS="false"
        check_all
        ;;
      2)
        deploy_all
        ;;
      3)
        SHOW_DIFFS="true"
        check_all
        ;;
      4|q|Q|quit|exit)
        log_info "Exiting."
        return 0
        ;;
      *)
        log_warn "Choose 1, 2, 3, or 4."
        ;;
    esac
  done
}


# ==================================================
# Main
# ==================================================

main() {
  parse_args "$@"

  case "$MODE" in
    check)
      check_all
      ;;
    deploy)
      deploy_all
      ;;
    interactive)
      interactive_menu
      ;;
    *)
      log_error "Unsupported mode: $MODE"
      exit 2
      ;;
  esac
}

main "$@"
