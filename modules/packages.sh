#!/usr/bin/env bash
# System updates module

run_packages() {
    log_info "=== System Updates ==="

    local status=0
    if dnf check-update &>/dev/null; then
        status=$?  # 100 means updates available
    else
        status=$?
    fi

    if [[ $status -eq 100 ]]; then
        log_info "Updates are available."
        if [[ "$AUTO_UPGRADE" == true ]]; then
            log_info "Auto‑upgrade enabled. Installing updates..."
            if [[ "$DRY_RUN" != true ]]; then
                dnf update -y
            fi
            log_info "System updated."
        else
            log_warn "Updates available. Run with --auto-upgrade to install automatically."
            # Optionally, we could still prompt if stdin is a terminal, but we'll keep non‑interactive.
        fi
    elif [[ $status -eq 0 ]]; then
        log_info "System is up to date."
    else
        log_error "Failed to check for updates (exit code: $status)."
        exit 1
    fi
}