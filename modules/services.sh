#!/usr/bin/env bash
# Service management module

run_services() {
    log_info "=== Service Hardening ==="

    # Display current service states
    log_info "All services:"
    systemctl list-units --type=service --no-pager || true

    log_info "Running services:"
    systemctl list-units --type=service --state=running --no-pager || true

    log_info "Failed services:"
    systemctl list-units --type=service --state=failed --no-pager || true

    # Ensure SSH is enabled
    log_info "Ensuring sshd is enabled..."
    if [[ "$DRY_RUN" != true ]]; then
        systemctl enable --now sshd
    fi

    # List listening ports for visibility
    log_info "Listening ports:"
    ss -tunlp || true

    # Interactive service disabling/enabling is removed; instead we could read from a config file.
    # For now, we just warn about unnecessary services.
    log_warn "Review services manually and disable unnecessary ones with: systemctl disable --now <service>"
}