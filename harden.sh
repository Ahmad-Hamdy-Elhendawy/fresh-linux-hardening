#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Default options
DRY_RUN=false
VERBOSE=false
AUTO_UPGRADE=false
ONLY_MODULE=""

# === Logging functions ===
log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_debug() { [[ "$VERBOSE" == true ]] && echo "[DEBUG] $*"; }

# === Help ===
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Linux hardening script.

Options:
  --dry-run           Show what would be done without actually changing anything
  --verbose           Print detailed debug information
  --auto-upgrade      Automatically install system updates without prompting
  --only <module>     Run only the specified module (ssh, packages, firewall, users, permissions, services, logging)
  --help              Show this help message

All modules run by default. Must be run as root.
EOF
}

# === Parse arguments ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)     DRY_RUN=true; shift ;;
        --verbose)     VERBOSE=true; shift ;;
        --auto-upgrade) AUTO_UPGRADE=true; shift ;;
        --only)        ONLY_MODULE="$2"; shift 2 ;;
        --help)        show_help; exit 0 ;;
        *)             log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# === Root check ===
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root."
    exit 1
fi

# === Source modules ===
source_module() {
    local module="$1"
    local file="$MODULES_DIR/$module.sh"
    if [[ -f "$file" ]]; then
        source "$file"
        log_debug "Sourced module: $module"
    else
        log_error "Module not found: $module"
        exit 1
    fi
}

# Load all modules (or only the specified one)
if [[ -n "$ONLY_MODULE" ]]; then
    source_module "$ONLY_MODULE"
    # Call the module's main function if it exists
    if declare -f "run_${ONLY_MODULE}" >/dev/null; then
        "run_${ONLY_MODULE}"
    else
        log_error "Module $ONLY_MODULE does not define a run_${ONLY_MODULE} function."
        exit 1
    fi
else
    # Source all modules and run them in order
    for mod in ssh packages firewall users permissions services logging; do
        source_module "$mod"
        if declare -f "run_${mod}" >/dev/null; then
            "run_${mod}"
        else
            log_warn "Module $mod has no run_${mod} function, skipping."
        fi
    done
fi

log_info "Hardening completed."