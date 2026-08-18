#!/usr/bin/env bash
# SSH hardening module

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_BACKUP="/etc/ssh/sshd_config.bak"

configure_sshd() {
    local exp="$1"
    local option="$2"
    local line="$exp $option"

    if grep -Ei "^[[:space:]]*#?${exp}[[:space:]]*${option}" "$SSHD_CONFIG" >/dev/null; then
        sed -i -E "s/^[[:space:]]*#?${exp}[[:space:]]*${option}/$line/" "$SSHD_CONFIG"
        log_debug "Updated $exp to '$option'"
    else
        echo "$line" >> "$SSHD_CONFIG"
        log_debug "Appended $line"
    fi
}

run_ssh() {
    log_info "=== SSH Hardening ==="

    # Install SSH if missing
    if ! dnf list installed openssh-server &>/dev/null; then
        log_info "Installing openssh-server..."
        if [[ "$DRY_RUN" != true ]]; then
            dnf install -y openssh-server
        fi
    else
        log_info "SSH is already installed."
    fi

    # Backup configuration
    if [[ ! -f "$SSHD_BACKUP" ]]; then
        log_info "Creating backup of SSH config."
        [[ "$DRY_RUN" != true ]] && cp "$SSHD_CONFIG" "$SSHD_BACKUP"
    else
        log_info "SSH backup already exists."
    fi

    # Apply hardening settings
    log_info "Configuring SSH..."
    configure_sshd "PermitRootLogin" "no"
    configure_sshd "PasswordAuthentication" "no"
    configure_sshd "PermitEmptyPasswords" "no"

    # Validate configuration
    log_info "Validating SSH configuration..."
    if sshd -t; then
        log_info "SSH configuration is valid."
    else
        log_error "SSH configuration is invalid. Restoring backup..."
        if [[ "$DRY_RUN" != true ]]; then
            cp "$SSHD_BACKUP" "$SSHD_CONFIG"
            if sshd -t; then
                log_info "Backup restored successfully."
            else
                log_error "Backup is also invalid. Manual intervention required."
                exit 1
            fi
        fi
    fi

    # Enable and start SSH service
    log_info "Enabling SSH service..."
    if [[ "$DRY_RUN" != true ]]; then
        systemctl enable --now sshd
    fi
    log_info "SSH service enabled and running."
}