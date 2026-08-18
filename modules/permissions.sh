#!/usr/bin/env bash
# File permissions hardening module

check_file() {
    local file="$1"
    local expected_perms="$2"

    if [[ ! -f "$file" ]]; then
        log_warn "File does not exist: $file"
        return
    fi

    log_info "Checking: $file"
    local owner=$(stat -c '%U' "$file")
    local group=$(stat -c '%G' "$file")
    local perms=$(stat -c '%a' "$file")

    log_debug "  Owner: $owner, Group: $group, Perms: $perms"

    if [[ "$owner" != "root" || "$group" != "root" ]]; then
        log_info "  Changing owner/group to root:root"
        if [[ "$DRY_RUN" != true ]]; then
            chown root:root "$file"
        fi
    fi

    if [[ "$perms" != "$expected_perms" ]]; then
        log_info "  Changing permissions to $expected_perms"
        if [[ "$DRY_RUN" != true ]]; then
            chmod "$expected_perms" "$file"
        fi
    fi
}

find_writable() {
    local file_type="$1"  # f or d
    local find_cmd="find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -path /run -prune -o -type $file_type -perm -o+w -print 2>/dev/null"
    local files
    files=$(eval "$find_cmd" || true)

    if [[ -n "$files" ]]; then
        log_warn "World‑writable $file_type files found:"
        echo "$files" | while IFS= read -r f; do
            log_warn "  $f"
            if [[ "$file_type" == "d" ]]; then
                local perms=$(stat -c '%a' "$f")
                if [[ "$perms" == 1??? ]]; then
                    log_debug "    Sticky bit is set."
                else
                    log_warn "    Sticky bit is NOT set. Consider setting it."
                    # Optionally fix: if [[ "$DRY_RUN" != true ]]; then chmod +t "$f"; fi
                fi
            fi
        done
    else
        log_info "No world‑writable $file_type files found."
    fi
}

find_special_permissions() {
    local file_type="$1"
    local find_cmd="find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -path /run -prune -o -type $file_type \( -perm -4000 -o -perm -2000 \) -print 2>/dev/null"
    local files
    files=$(eval "$find_cmd" || true)

    if [[ -n "$files" ]]; then
        log_info "Files with SUID/SGID found:"
        echo "$files" | while IFS= read -r f; do
            local perms=$(stat -c '%a' "$f")
            local type=""
            [[ "$perms" == 4??? ]] && type="SUID"
            [[ "$perms" == 2??? ]] && type="SGID"
            log_info "  $f ($type)"
        done
    else
        log_info "No SUID/SGID $file_type files found."
    fi
}

run_permissions() {
    log_info "=== File Permissions Hardening ==="

    # Check critical files
    check_file "/etc/passwd" "644"
    check_file "/etc/group" "644"
    check_file "/etc/ssh/sshd_config" "600"

    # Detailed stats for sensitive files
    log_info "Detailed stats for sensitive files:"
    for file in /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/ssh/sshd_config; do
        if [[ -f "$file" ]]; then
            log_info "  $(basename "$file"): $(stat -c '%U %G %a' "$file")"
        else
            log_warn "  $file does not exist."
        fi
    done

    # World‑writable files and directories
    find_writable "f"
    find_writable "d"

    # SUID/SGID files and directories
    find_special_permissions "f"
    find_special_permissions "d"

    # Orphaned files (no user/group)
    log_info "Checking for orphaned files (no user/group)..."
    local orphans=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -path /run -prune -o \( -nouser -o -nogroup \) -print 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        log_warn "Orphaned files found:"
        echo "$orphans" | while IFS= read -r f; do
            log_warn "  $f"
        done
    else
        log_info "No orphaned files found."
    fi
}