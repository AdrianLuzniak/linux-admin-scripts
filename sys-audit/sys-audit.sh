# ===============================
# System Audit Script (sys-audit.sh)
#
# Features:
# - Generates a detailed audit report about system health and configuration
# - Logs execution to syslog with `logger`
# - Supports short and colorless output via CLI arguments
# - Saves reports to a timestamped log file in /var/log/sys-audit
# - Verifies sudo/root privileges before execution
#
# Arguments:
#   --short       → generates minimal report (skips heavy checks)
#   --no-color    → disables colored output
#   --output=FILE → saves output to a custom log file path
#
# Tested On:
# - CentOS Stream 9 (fully compatible)
# - Should work on RHEL-based systems (Rocky, AlmaLinux, RHEL)
#
# Author:    Adrian Łuźniak
# Created:   2025-06-14
# ===============================

#!/bin/bash

LOG_DIR="/var/log/sys-audit"
LOG_FILE="$LOG_DIR/$(hostname)_$(date +%Y-%m-%d_%H_%M_%S).log"
SERVICES=(sshd cron firewalld NetworkManager systemd-journald)

# Startup options
FULL_MODE=true
USE_COLOR=true

# Check if script is executed with sudo, for root EUID = 0
if [[ $EUID -ne 0 ]]; then
    echo "This script must be executed with sudo privileges!"
    exit 1
fi

# Logging to system log
logger -t sys-audit "Script $0 was executed by user $(whoami)"

# Parsing args
for arg in "$@"; do
   case "$arg" in
    --short) FULL_MODE=false;;
    --no-color) USE_COLOR=false;;
    --output=*) LOG_FILE="${arg#*=}" #delete smalles part from left side till =
    esac
done

mkdir -p "$LOG_DIR"

# === COLOR DEFINITIONS (only if terminal supports it) and USE_COLOR=true ===
# -t 1 checks if file descriptor 1 (stdout) is connected to an interactive terminal (TTY)

if [[ -t 1 && "$USE_COLOR" == true ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

# === MAIN EXECUTION BLOCK ===
# -e special characters support
{
echo "${BLUE}===== System Audit Report =====${RESET}"
echo "Generated on: $(date)"
echo "${BLUE}===============================${RESET}"

echo -e "\n${YELLOW}>> System information${RESET}"
echo ">> Hostname: $(hostname)"
echo " Uptime: $(uptime -p)"
echo ">> Kernel version $(uname -r)"
echo ">> CPU Info:"; lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//' # delete additional spaces
echo ">> RAM:"; free -h |awk '/^Mem:/ {print "Total: "$2", Used: "$3", Free: "$4}'

echo -e "\n${YELLOW}>> Service Statuses${RESET}"
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "$service: ${GREEN}Active${RESET}"
    else
        echo -e "$service: ${RED}Inactive${RESET}"
    fi
done

echo -e "\n ${YELLOW}>>Disk Space${RESET}"
df -hT | awk 'NR==1 || /^\/dev/' # Look for /dev/, / / opens and closes regex in awk

echo -e "\n${YELLOW}>> Kerner Warnings & Errors (dmesg)${RESET}"
dmesg --level=err,warn | tail -n 5 || echo "No recent kernel warnings."

# Only crit errors with additional info since last boot
echo -e "\n${YELLOW}>> System Log Errors (journalctl)${RESET}"
journalctl -p 3 -xb | tail -n 5 || echo "No recent critical log entries."

echo -e "\n${YELLOW}>> Loged-in Users ${RESET}"
who

# Check socket tcp connections, look for ssh, show entries without DNS name, but with PID
echo -e "\n${YELLOW}>> SSH Sessions${RESET}"
ss -tnp | grep ssh || echo "No active SSH sessions."

echo -e "\n${YELLOW}>> Network Info${RESET}"
ip -brief address
echo "DNS servers:"
grep nameserver /etc/resolv.conf

#Shows tcp, udp connections excluding IP of localhost
echo -e "${YELLOW}>> Listening ports${RESET}"
ss -tuln | grep -v "127.0.0.1"

echo -e "\n${YELLOW}>> Users with sudo access${RESET}"
getent group sudo || grep - Po '^sudo.+:\K.*' /etc/group # \K resets match and whow everything after it

echo -e "\n${YELLOW}>> Non-expiring Passwords${RESET}"
for user in $(cut -d: -f1 /etc/passwd); do
    expiry=$(chage -l "$user" 2>/dev/null | grep "Password expires" | awk -F': ' '{print $2}') # awk used to return password date
    [[ "$expiry" == "never" ]] && echo "$user: never expires"
done

if [[ "$FULL_MODE" == true ]]; then
    echo -e "\n${YELLOW}>> SUID/SGID Files (Top 10)${RESET}"
    # Search filesystem for wiles with bits 4000 or 2000
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -lh {} + 2>/dev/null | head -n 10

    echo -e "\n${YELLOW}>> Installed Packages Count${RESET}"
    rpm -qa | wc -l # query all installed packages and count them

    echo -e "\n${YELLOW}>> Security Updates Available${RESET}"
    if command -v dnf -y >/dev/null; then # Check if package installer is available
        dnf updateinfo list security available || echo " No security updates info available."
    elif command -v yum -y >/dev/null; then
        yum updateinfo list security available || echo "No security updates info available."
    fi

    echo -e "\n${YELLOW}>> /tmp and /var/log Usage${YELLOW}"
    du -sh /tmp /var/log 2>/dev/null

    echo -e "\n${YELLOW}>> Top 5 Log Files in /var/log${RESET}"
    #exec du -h on found files, {} file symbol, + means execute once for all found files
    find /var/log -type f -exec du -h {} + | sort -hr | head -n 5 
fi

echo -e "\n${BLUE}===== End of Report =====${RESET}"
echo "Report saved to: $LOG_FILE"

} | tee -a "$LOG_FILE"