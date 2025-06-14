#!/bin/bash

LOG_DIR="/var/log/sys-audit"
LOG_FILE="$LOG_DIR/$(hostname)_$(date +%Y-%m-%d_%H_%M_%S).log"
SERVICES=(sshd cron firewalld NetworkManager systemd-journald)
mkdir -p "$LOG_DIR"

#C  === COLOR DEFINITIONS (only if terminal supports it) ===
# -t 1 checks if file descriptor 1 (stdout) is connected to an interactive terminal (TTY)

if [[ -t 1 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""
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

echo -e "\n${BLUE}===== End of Report =====${RESET}"
echo "Report saved to: $LOG_FILE"


} | tee -a "$LOG_FILE"