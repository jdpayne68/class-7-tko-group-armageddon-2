#!/usr/bin/env bash

set -u

# ==================================================
# CONFIGURATION
# ==================================================

API_BASE="${API_BASE:-}"
REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-6}"
MIN_EVENTS=25

LEVEL_NAME=""
TARGET_EVENTS="${TARGET_EVENTS:-}"
DEFAULT_DELAY="0.75"
TIMED_MODE=false
DURATION_MIN=0
DRY_RUN="${DRY_RUN:-false}"

declare -a ATTACK_PLAN=()


# ==================================================
# HEADERS & LOGGING
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

should_color() {
  [ -t 1 ] && [ "${TERM:-}" != "dumb" ]
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

header() {
  local title="$1"
  local color="${2:-$BOLD}"
  local width=60
  local line

  line="$(printf "%${width}s" "" | tr " " "=")"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
  color_text "$color" "$(printf "%*s" $(((${#title} + width) / 2)) "$title")"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
}

sub_header() {
  local title="$1"
  local color="${2:-$BLUE}"
  local width=50
  local line

  line="$(printf "%${width}s" "" | tr " " "-")"
  printf "\n"
  color_text "$color" "$line"
  printf "\n"
  color_text "$color" "  $title"
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

log_alert() { printf "%s %s\n" "$(log_tag ALERT "$RED")" "$*"; }
log_info() { printf "%s %s\n" "$(log_tag INFO "$CYAN")" "$*"; }
log_warn() { printf "%s %s\n" "$(log_tag WARN "$YELLOW")" "$*"; }
log_step() { printf "\n%s %s\n" "$(log_tag STEP "$BLUE")" "$*"; }
log_debug() {
  if [ "${DEBUG:-false}" = "true" ]; then
    printf "%s %s\n" "$(log_tag DEBUG "$YELLOW")" "$*"
  fi
}

log_success() {
  color_text "$GREEN" "OK:"
  printf " %s\n" "$*"
}

log_error() {
  color_text "$RED" "ERROR:"
  printf " %s\n" "$*"
}


# ==================================================
# INPUT HELPERS
# ==================================================

prompt_default() {
  local prompt="$1"
  local default="$2"
  local value

  if [ -n "$default" ]; then
    read -r -p "$prompt [$default]: " value
    printf "%s" "${value:-$default}"
  else
    read -r -p "$prompt: " value
    printf "%s" "$value"
  fi
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

require_number_range() {
  local value="$1"
  local min="$2"
  local max="$3"

  [[ "$value" =~ ^[0-9]+$ ]] &&
    [ "$value" -ge "$min" ] &&
    [ "$value" -le "$max" ]
}

query_separator() {
  case "$1" in
    *\?*) printf "&" ;;
    *) printf "?" ;;
  esac
}


# ==================================================
# ATTACK PLANS
# ==================================================

add_payload() {
  local attack_type="$1"
  local payload="$2"

  ATTACK_PLAN+=("${attack_type}|${payload}")
}

load_medium_payloads() {
  ATTACK_PLAN=()

  add_payload "xss" "%3Cscript%3Ealert(1)%3C%2Fscript%3E"
  add_payload "xss" "%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E"
  add_payload "xss" "%3Csvg%20onload%3Dalert(1)%3E"

  add_payload "sqli" "%27%20OR%20%271%27%3D%271"
  add_payload "sqli" "%27%20UNION%20SELECT%20NULL--"
  add_payload "sqli" "%27%20OR%201%3D1--"

  add_payload "lfi" "%2e%2e%2f%2e%2e%2fetc%2fpasswd"
  add_payload "lfi" "..%2F..%2F..%2Fwindows%2Fwin.ini"
  add_payload "lfi" "%2fetc%2fpasswd"

  LEVEL_NAME="MEDIUM"
  TARGET_EVENTS="${TARGET_EVENTS:-27}"
  DEFAULT_DELAY="0.75"
}

load_high_payloads() {
  ATTACK_PLAN=()

  add_payload "xss" "%3Ciframe%20srcdoc%3D%27%3Cscript%3Ealert(document.domain)%3C%2Fscript%3E%27%3E%3C%2Fiframe%3E"
  add_payload "xss" "%3Cimg%20src%3Dx%20onerror%3Dprompt(document.cookie)%3E"
  add_payload "xss" "%3Cmath%20href%3Djavascript%3Aalert(2)%3E"

  add_payload "sqli" "%27%20UNION%20ALL%20SELECT%20NULL%2CNULL%2CNULL--"
  add_payload "sqli" "%27%3B%20SELECT%20pg_sleep(2)--"
  add_payload "sqli" "admin%27%20AND%20%271%27%3D%271%27--"

  add_payload "lfi" "%2e%2e%252f%2e%2e%252fetc%252fpasswd"
  add_payload "lfi" "%252e%252e%252f%252e%252e%252fboot.ini"
  add_payload "lfi" "%2e%2e%2f%2e%2e%2fproc%2fself%2fenviron"

  LEVEL_NAME="HIGH"
  TARGET_EVENTS="${TARGET_EVENTS:-36}"
  DEFAULT_DELAY="0.50"
}

load_critical_payloads() {
  ATTACK_PLAN=()

  add_payload "xss" "%3Csvg%2Fonload%3Deval(atob(%27YWxlcnQoMSk%3D%27))%3E"
  add_payload "xss" "%3Cmeta%20http-equiv%3Drefresh%20content%3D0%3Burl%3Djavascript%3Aalert(1)%3E"
  add_payload "xss" "%3Cobject%20data%3Djavascript%3Aalert(document.domain)%3E"

  add_payload "sqli" "%27%20OR%20EXISTS(SELECT%201%20FROM%20users)--"
  add_payload "sqli" "%27%20AND%20SLEEP(3)--"
  add_payload "sqli" "%27%3B%20DROP%20TABLE%20users--"

  add_payload "lfi" "%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd"
  add_payload "lfi" "..%252f..%252f..%252f..%252fvar%252flog%252fauth.log"
  add_payload "lfi" "%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fshadow"

  LEVEL_NAME="CRITICAL"
  TARGET_EVENTS="${TARGET_EVENTS:-45}"
  DEFAULT_DELAY="0.35"
}

select_level() {
  local level="${ATTACK_LEVEL:-}"

  while :; do
    if [ -z "$level" ]; then
      sub_header "Attack Level" "$MAGENTA"
      printf "  1) Medium   - 27 events, basic XSS/SQLi/LFI mix\n"
      printf "  2) High     - 36 events, stronger encoded payloads\n"
      printf "  3) Critical - 45 events, evasive payload variants\n"
      read -r -p "Select 1, 2, or 3: " level
    fi

    case "$level" in
      1|medium|MEDIUM) load_medium_payloads; break ;;
      2|high|HIGH) load_high_payloads; break ;;
      3|critical|CRITICAL) load_critical_payloads; break ;;
      *)
        log_warn "Please select 1, 2, or 3."
        level=""
        ;;
    esac
  done

  if ! [[ "$TARGET_EVENTS" =~ ^[0-9]+$ ]]; then
    log_error "TARGET_EVENTS must be a positive number."
    exit 1
  fi

  if [ "$TARGET_EVENTS" -lt "$MIN_EVENTS" ]; then
    log_warn "TARGET_EVENTS was below ${MIN_EVENTS}; raising to ${MIN_EVENTS}."
    TARGET_EVENTS="$MIN_EVENTS"
  fi
}


# ==================================================
# RUN CONFIGURATION
# ==================================================

collect_inputs() {
  header "WAF MALICIOUS TRAFFIC TEST" "$BOLD"

  if [ -z "$API_BASE" ]; then
    API_BASE="$(prompt_default \
      "Enter the base API URL" \
      "https://example.execute-api.us-east-1.amazonaws.com/prod")"
  fi

  if [ -z "$API_BASE" ]; then
    log_error "Base API URL cannot be empty."
    exit 1
  fi

  select_level

  sub_header "Pacing" "$BLUE"
  if [ -n "${TEST_DURATION_MIN:-}" ]; then
    if ! require_number_range "$TEST_DURATION_MIN" 1 10; then
      log_error "TEST_DURATION_MIN must be a number from 1 to 10."
      exit 1
    fi
    TIMED_MODE=true
    DURATION_MIN="$TEST_DURATION_MIN"
  elif prompt_yes_no "Spread requests over a test duration? [y/N]:" "n"; then
    while :; do
      read -r -p "Enter test duration in minutes (1-10): " DURATION_MIN
      if require_number_range "$DURATION_MIN" 1 10; then
        TIMED_MODE=true
        break
      fi
      log_warn "Please enter a number from 1 to 10."
    done
  fi
}

calculate_delay() {
  if [ "${DELAY_SECONDS:-}" ]; then
    printf "%s" "$DELAY_SECONDS"
    return
  fi

  if [ "$TIMED_MODE" = true ]; then
    awk -v duration="$DURATION_MIN" -v total="$TARGET_EVENTS" \
      'BEGIN { printf "%.2f", (duration * 60) / total }'
  else
    printf "%s" "$DEFAULT_DELAY"
  fi
}

display_plan() {
  local delay="$1"
  local estimated_seconds

  estimated_seconds="$(awk -v total="$TARGET_EVENTS" -v delay="$delay" \
    'BEGIN { printf "%.0f", total * delay }')"

  sub_header "Configuration" "$WHITE"
  log_info "API Base: $API_BASE"
  log_info "Attack level: $LEVEL_NAME"
  log_info "Attack types: XSS, SQLi, path traversal/LFI"
  log_info "Target events: $TARGET_EVENTS"
  log_info "Request timeout: ${REQUEST_TIMEOUT}s"
  log_info "Delay between requests: ${delay}s"

  if [ "$TIMED_MODE" = true ]; then
    log_info "Duration: ${DURATION_MIN} minute(s), spread evenly"
  else
    log_info "Estimated run time: about ${estimated_seconds}s"
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_warn "Dry run enabled. No HTTP requests will be sent."
  fi
}

confirm_run() {
  if [ "${ASSUME_YES:-false}" = "true" ]; then
    return 0
  fi

  printf "\n"
  log_alert "This sends malicious test payloads to the configured API."
  log_alert "Use only against your own lab endpoint."

  if ! prompt_yes_no "Continue? [y/N]:" "n"; then
    log_warn "Cancelled by user."
    exit 130
  fi
}


# ==================================================
# TRAFFIC GENERATION
# ==================================================

send_request() {
  local count="$1"
  local attack_type="$2"
  local payload="$3"
  local sep
  local full_url
  local timestamp
  local http_code
  local curl_status

  sep="$(query_separator "$API_BASE")"
  full_url="${API_BASE}${sep}name=${payload}&attack_type=${attack_type}&test_level=${LEVEL_NAME}"
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  log_step "[$count/$TARGET_EVENTS] ${LEVEL_NAME} ${attack_type}"
  log_debug "URL: $full_url"

  if [ "$DRY_RUN" = "true" ]; then
    log_info "Dry run: $full_url"
    return 0
  fi

  http_code="$(
    curl -sk \
      --max-time "$REQUEST_TIMEOUT" \
      --user-agent "waf-lab-test/${LEVEL_NAME}/${attack_type}" \
      --header "X-WAF-Test-Level: ${LEVEL_NAME}" \
      --header "X-WAF-Test-Type: ${attack_type}" \
      --output /dev/null \
      --write-out "%{http_code}" \
      "$full_url"
  )"
  curl_status=$?

  if [ "$curl_status" -eq 0 ]; then
    log_info "Timestamp: $timestamp | HTTP: $http_code"
  else
    log_warn "Timestamp: $timestamp | curl exit: $curl_status | HTTP: ${http_code:-000}"
  fi
}

run_test() {
  local delay="$1"
  local plan_size="${#ATTACK_PLAN[@]}"
  local index
  local entry
  local attack_type
  local payload
  local count=1
  local start_time
  local elapsed

  start_time="$(date +%s)"
  short_header "Starting Traffic" "$CYAN"

  while [ "$count" -le "$TARGET_EVENTS" ]; do
    index=$(( (count - 1) % plan_size ))
    entry="${ATTACK_PLAN[$index]}"
    attack_type="${entry%%|*}"
    payload="${entry#*|}"

    send_request "$count" "$attack_type" "$payload"

    if [ "$count" -lt "$TARGET_EVENTS" ]; then
      sleep "$delay"
    fi

    if [ $((count % 5)) -eq 0 ] || [ "$count" -eq "$TARGET_EVENTS" ]; then
      elapsed=$(( $(date +%s) - start_time ))
      log_info "Progress: $count/$TARGET_EVENTS sent | elapsed: ${elapsed}s"
    fi

    count=$((count + 1))
  done
}

print_summary() {
  local delay="$1"

  sub_header "Summary" "$WHITE"
  log_success "Completed WAF malicious traffic test."
  log_info "Level: $LEVEL_NAME"
  log_info "Events sent: $TARGET_EVENTS"
  log_info "Attack mix: XSS, SQLi, path traversal/LFI"
  log_info "Delay used: ${delay}s"
  log_info "Check WAF logs, EventBridge correlation, Lambda logs, and SNS output."
}


# ==================================================
# MAIN
# ==================================================

main() {
  local delay

  collect_inputs
  delay="$(calculate_delay)"
  display_plan "$delay"
  confirm_run
  run_test "$delay"
  print_summary "$delay"
}

main "$@"
