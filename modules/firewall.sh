#!/usr/bin/env bash
# Firewall hardening module

run_firewall() {
    log_info "=== Firewall Hardening ==="

    # Install firewalld if missing
    if ! dnf list installed firewalld &>/dev/null; then
        log_info "firewalld not installed. Installing..."
        if [[ "$DRY_RUN" != true ]]; then
            dnf install -y firewalld
        fi
    else
        log_info "firewalld is installed."
    fi

    # Enable and start firewalld
    log_info "Enabling firewalld..."
    if [[ "$DRY_RUN" != true ]]; then
        systemctl enable --now firewalld
    fi

    # Show current configuration (for logging)
    if [[ "$VERBOSE" == true ]]; then
        log_debug "Active zones:"
        firewall-cmd --get-active-zones || log_warn "firewall-cmd --get-active-zones failed"
        log_debug "Current rules:"
        firewall-cmd --list-all || log_warn "firewall-cmd --list-all failed"
    fi

    # Remove all services except SSH (permanent)
    log_info "Removing unnecessary services from firewall..."
    local services=($(firewall-cmd --list-services))
    for service in "${services[@]}"; do
        if [[ "$service" != "ssh" ]]; then
            log_info "Removing service: $service"
            if [[ "$DRY_RUN" != true ]]; then
                firewall-cmd --remove-service="$service" --permanent
            fi
        fi
    done

    # Remove all ports except 22/tcp
    log_info "Removing unnecessary ports..."
    local ports=($(firewall-cmd --list-ports))
    for port in "${ports[@]}"; do
        if [[ "$port" != "22/tcp" ]]; then
            log_info "Removing port: $port"
            if [[ "$DRY_RUN" != true ]]; then
                firewall-cmd --remove-port="$port" --permanent
            fi
        fi
    done

    # Reload firewalld to apply changes
    if [[ "$DRY_RUN" != true ]]; then
        log_info "Reloading firewall..."
        systemctl reload firewalld
    fi

    log_info "Firewall hardened."
}