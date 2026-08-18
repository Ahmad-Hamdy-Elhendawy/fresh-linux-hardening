#!/usr/bin/env bash
# Users and authentication module

run_users() {
    log_info "=== User Hardening ==="

    # Create admin user if not exists
    if id -u admin &>/dev/null; then
        log_info "User 'admin' exists (UID: $(id -u admin))."
    else
        log_info "Creating user 'admin'..."
        if [[ "$DRY_RUN" != true ]]; then
            useradd -m -s /bin/bash admin
        fi
        log_info "User 'admin' created."
    fi

    # Add admin to wheel group for sudo
    log_info "Adding admin to wheel group..."
    if [[ "$DRY_RUN" != true ]]; then
        usermod -aG wheel admin
    fi

    # Check for non‑root accounts with UID 0
    log_info "Checking for extra UID 0 accounts..."
    local extra_users=$(getent passwd | grep ':0:' | grep -v '^root:')
    if [[ -n "$extra_users" ]]; then
        log_warn "Found non‑root UID 0 accounts:"
        echo "$extra_users" | while IFS=: read user _; do
            log_warn "  Removing user: $user"
            if [[ "$DRY_RUN" != true ]]; then
                userdel -r "$user" 2>/dev/null || log_error "Failed to remove $user"
            fi
        done
    else
        log_info "No extra UID 0 accounts."
    fi

    # List users with /nologin and interactive shells (for informational purposes)
    log_info "Users with /nologin shell:"
    getent passwd | grep -E '/nologin$' | cut -d: -f1 || true

    log_info "Users with interactive shells:"
    getent passwd | grep -E '/(bash|zsh|sh)$' | cut -d: -f1 || true
}