# System Audit Script

This Bash script performs a comprehensive system audit on a Linux machine and generates a detailed report including system info, service statuses, disk usage, logs, network info, and security updates. The report is saved to a timestamped log file and simultaneously displayed on the terminal with optional colored output.

---

## Key Features

- **Root Privileges Check:** Ensures the script is run with `sudo` or root privileges.
- **System Information:** Displays hostname, uptime, kernel version, CPU model, and RAM usage.
- **Service Statuses:** Checks if essential services (sshd, cron, firewalld, NetworkManager, systemd-journald) are active.
- **Disk Usage:** Shows mounted disks and their usage.
- **Kernel & System Logs:** Outputs recent kernel warnings/errors and critical system log entries.
- **Logged-in Users:** Lists currently logged-in users.
- **SSH Sessions:** Displays active SSH TCP sessions.
- **Network Info:** Shows IP addresses and DNS servers.
- **Listening Ports:** Lists open TCP and UDP ports excluding localhost.
- **Sudo Users:** Lists users belonging to the `sudo` group.
- **Password Expiry:** Detects users with non-expiring passwords.
- **Optional Full Mode:**
  - Top 10 SUID/SGID files on the system.
  - Count of installed RPM packages.
  - Available security updates via `dnf` or `yum`.
  - Usage summary of `/tmp` and `/var/log` directories.
  - Top 5 largest log files in `/var/log`.

- **Colorized Output:** Uses terminal colors for better readability, can be disabled.
- **Logging:** The report is saved to `/var/log/sys-audit/` with a hostname and timestamped filename.
- **System Logging:** Script execution is logged via `logger` with the executing user info.
- **Command-line Arguments:**
  - `--short` — Runs a shorter version of the report (disables full mode).
  - `--no-color` — Disables colorized terminal output.
  - `--output=PATH` — Saves the report to a custom log file path.

---

## Requirements

- Linux system with `bash`
- Root (sudo) privileges to run
- Installed commands: `lscpu`, `free`, `systemctl`, `df`, `dmesg`, `journalctl`, `who`, `ss`, `ip`, `getent`, `chage`, `find`, `rpm`, `dnf` or `yum`
- Access to `/var/log/sys-audit/` directory or write permission to the chosen output directory
- **Tested on:** CentOS Stream 9 (should work on other RHEL-based distributions)
---

## Usage Examples

Run full report (default):

```bash
sudo ./sys-audit.sh
```

Run report without colored output:

```bash
sudo ./sys-audit.sh --no-color
```
Save report to custom file:

```bash
sudo ./sys-audit.sh --output=/tmp/my_custom_report.log
```

Combine options:

```bash
sudo ./sys-audit.sh --short --no-color --output=/tmp/my_custom_report.log
```

## Advantages
**Comprehensive**: Collects a wide range of system health indicators in one script.

**Automatable**: Can be scheduled via cron for regular system audits.

**Readable**: Colorized output helps quickly identify issues.

**Flexible**: Options to customize output verbosity, colors, and log file location.

**Lightweight**: Pure bash script without heavy dependencies.

**Secure**: Checks for root privileges and logs usage to system logger for audit trail.

## Additional notes
- Make sure the user running the script has write permission to the specified log directory.

- Requires system utilities and services mentioned above to be present.

- Security update info depends on availability of dnf or yum and proper repository configuration.