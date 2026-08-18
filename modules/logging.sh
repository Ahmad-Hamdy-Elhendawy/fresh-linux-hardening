#!/usr/bin/env bash
# Logging and auditing module

run_logging() {
    log_info "=== Logging & Auditing ==="

    # Check journald
    if systemctl is-active systemd-journald &>/dev/null; then
        log_info "systemd-journald is active."
    else
        log_warn "systemd-journald is not active."
    fi

    if systemctl is-enabled systemd-journald &>/dev/null; then
        log_info "systemd-journald is enabled."
    else
        log_warn "systemd-journald is not enabled."
    fi

    # Check for logs
    if journalctl -n 1 &>/dev/null; then
        log_info "Logs are being generated."
    else
        log_warn "No logs found in journal."
    fi

    # Check rsyslog secure log destinations
    log_info "Checking rsyslog secure log destinations:"
    grep -REo "/.*secure$" /etc/rsyslog.conf /etc/rsyslog.d/ 2>/dev/null || log_info "No custom secure log found."

    # Journal disk usage
    log_info "Journal disk usage:"
    journalctl --disk-usage || true

    # Persistent logging
    if [[ -d "/var/log/journal" ]]; then
        log_info "Logs have permanent storage."
    else
        log_warn "Logs have volatile storage (directory /var/log/journal not found)."
    fi

    # Number of failed logins
    local failed=$(journalctl -u sshd.service --no-pager 2>/dev/null | grep -i "fail" | wc -l || echo "0")
    log_info "Number of failed logins: $failed"

    # Install auditd if not present
    if ! dnf list installed audit &>/dev/null; then
        log_info "auditd not installed. Installing..."
        if [[ "$DRY_RUN" != true ]]; then
            dnf install -y audit
            systemctl enable --now auditd
        fi
    else
        log_info "auditd is installed."
    fi

    # Show audit rules
    if [[ "$DRY_RUN" != true ]]; then
        log_info "Current audit rules:"
        auditctl -l || true
    fi
}