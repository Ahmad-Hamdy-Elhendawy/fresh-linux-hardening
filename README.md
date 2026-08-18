# Linux Hardening Script

A modular Bash script for basic security hardening of RHEL-based Linux systems (Fedora, CentOS, RHEL).  
It covers SSH, system updates, firewall, user accounts, file permissions, services, and logging.

## Structure

linux-hardening/
├── harden.sh                 # Main entry point
├── modules/
│   ├── ssh.sh                # SSH configuration & hardening
│   ├── packages.sh           # System update management
│   ├── firewall.sh           # firewalld lockdown
│   ├── users.sh              # User accounts & sudo
│   ├── permissions.sh        # File permissions, SUID/SGID, world‑writable
│   ├── services.sh           # Service status & enable/disable helpers
│   └── logging.sh            # Journald, rsyslog, auditd
└── README.md

## Prerequisites

- RHEL, CentOS, or Fedora with `dnf` package manager.
- Root or sudo access (script must be run as root).
- Internet connection for package installation.

## Usage

```bash
sudo ./harden.sh [OPTIONS]
Options
Option	Description
--dry-run	Show what would be changed without actually doing it.
--verbose	Print extra debug information during execution.
--auto-upgrade	Automatically install system updates without prompting.
--only <module>	Run only one module (e.g., --only ssh).
--help	Display help text and exit.
Examples
Run all modules with verbose output and auto‑upgrade:

bash
sudo ./harden.sh --verbose --auto-upgrade
Just check SSH hardening without making changes:

bash
sudo ./harden.sh --dry-run --only ssh
Modules Overview
Module	What it does
ssh	Ensures OpenSSH is installed, backs up sshd_config, disables root login, password auth, and empty passwords; validates config before restarting.
packages	Checks for available system updates; installs them only if --auto-upgrade is given.
firewall	Installs firewalld, enables it, removes all services and ports except SSH (22/tcp).
users	Creates an admin user with sudo (wheel group), removes any non‑root accounts with UID 0, lists interactive/nologin users.
permissions	Fixes ownership/permissions on /etc/passwd, /etc/group, and sshd_config; scans for world‑writable files/directories, SUID/SGID binaries, and orphaned files (no owner/group).
services	Lists all running/failed services, ensures sshd is enabled, and displays listening ports.
logging	Checks journald, rsyslog, ensures auditd is installed, shows failed login counts and disk usage.
Safety & Warnings
Test in a safe environment first – this script makes permanent changes to your system.

The firewall module removes all open ports except SSH (22/tcp). If you need other services (e.g., HTTP, HTTPS), add them manually after running the script.

The SSH module disables password authentication. Make sure you have SSH key‑based access configured before running, otherwise you may lock yourself out.

The script is designed for dnf‑based distributions. It will not work on Debian/Ubuntu without modifications.

Customization
Edit the module files directly to adjust behaviour:

In modules/ssh.sh, you can change the SSH directives (e.g., PermitRootLogin).

In modules/firewall.sh, modify the list of services/ports to keep.

In modules/users.sh, change the admin username or group.

Troubleshooting
"Permission denied" – run as root or with sudo.

Module not found – ensure all .sh files are in the modules/ directory and are executable.

SSH validation fails – the script attempts to restore from backup; if that also fails, you will need to manually fix /etc/ssh/sshd_config.

Firewall rules not applying – check if firewalld is running with systemctl status firewalld; reload with firewall-cmd --reload.

License
This script is provided "as is", without warranty of any kind. Use at your own risk.