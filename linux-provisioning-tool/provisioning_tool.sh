#!/bin/bash

# Bash config
# -e stops script if any command return exitcode ! 0
# -u Force error if script use undefined variable
# -o pipefail causes the entire pipeline to return an error status if any part of the pipeline terminates with an error.
set -euo pipefail

LOG_FILE="./provision-$(date '+%Y%m%d-%H%M%S').log"

# First > means redirect stdout
# >(command) means process substitution, create temporary file with output of command
exec > >(tee -a "$LOG_FILE") 2>&1

# Fetch first arg and set DRY_RUN
# If DRY_RUN is set use it's value, if NOT false is default option
if [[ "${1:-false}" == "true" ]]; then
  DRY_RUN=true
else
  DRY_RUN=false
fi

REQUIRED_PACKAGES=("htop" "curl" "git")
USERS=("devuser1" "devuser2")
USER_GROUP="developers"
PORTS_TO_OPEN=("20" "80" "443")
SSH_PORT=22
ENABLE_PASSWORD_AUTH="yes"
ENABLE_SSH_KEY_AUTH="yes"
TIMEZONE="Europe/Warsaw"
HOSTNAME_SET="dev-machine"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_BACKUP="$SSHD_CONFIG.bak"

# === HELPER FUNCTIONS ===
run_cmd() {
    if [ "$DRY_RUN" ]; then
        #$* arguments passed to the function as one string of text
        echo "[DRY RUN] $*"
    else
        eval "$@" # Execute all arguments one by one
    fi
}

copy_file(){
    local SRC="$1"
    local DEST="$2"

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would copy $SRC to $DEST"
    else
        cp "$SRC" "$DEST"
    fi
}

#ID - id of linux distributution
#ID_LIKE - list of distro similar to your linux distro
pkg_detect(){
    source /etc/os-release
    if [[ "$ID_LIKE" == *"rhel"* ]] || [[ "$ID" == "rocky" ]]; then
        echo "dnf"
    else
        echo "apt"
    fi
}

install_packages() {
    local PKG_MGR
    PKG_MGR=$(pkg_detect)
    echo "[INFO] Installing packages using $PKG_MGR"
    if [ "$PKG_MGR" = "apt" ]; then
        run_cmd "apt update -y"
        run_cmd "apt install -y ${REQUIRED_PACKAGES[*]}" # REQUIRED_PACKAGES[*] all packages as one text string
    else
        run_cmd "dnf update -y"
        run_cmd "dnf install -y ${REQUIRED_PACKAGES[*]}"
    fi
}

setup_users() {
    if ! getent group "$USER_GROUP" > /dev/null; then
        run_cmd "groupadd $USER_GROUP"
    fi

    for USER in "${USERS[@]}"; do
        if ! id "$USER" &>/dev/null; then 
            run_cmd "useradd -m -s /bin/bash -G $USER_GROUP $USER"
            run_cmd "echo \"$USER:ChangeMe123\" | chpasswd"
        fi

        local SSH_DIR="/home/$USER/.ssh"
        local KEY_FILE="authorized_keys/$USER"
        if [ -f "$KEY_FILE" ]; then
            run_cmd "mkdir -p $SSH_DIR"
            run_cmd "chmod 700 $SSH_DIR"
            copy_file "$KEY_FILE" "$SSH_DIR/authorized_keys"
            run_cmd "chmod 600 $SSH_DIR/authorized_keys"
            run_cmd "chown -R $USER:$USER $SSH_DIR"
        else
            echo "[WARN] Missing authorized_keys for $USER"
        fi
    done
}

configure_ssh() {
    if [ ! -f "$SSHD_BACKUP" ]; then
        copy_file "$SSHD_CONFIG" "$SSHD_BACKUP"
    fi

    # Look for PasswordAuthentication, PubkeyAuthentication and change it's values
    run_cmd "sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication $ENABLE_PASSWORD_AUTH/' $SSHD_CONFIG"
    run_cmd "sed -i 's/^#\\?PubkeyAuthentication.*/PubkeyAuthentication $ENABLE_SSH_KEY_AUTH/' $SSHD_CONFIG"

    # Create and setup sftp group
    # SFTP is supposed to work in the chrooted /home/<username>
    # Instead of the standard shell, internal-sftp is forced
    # TCP tunneling is forbidden (no port forwarding)
    if ! grep -q "Match Group sftpusers" "$SSHD_CONFIG"; then
        run_cmd "groupadd -f sftpusers"
        echo -e "\nMatch Group sftpusers\n  ChrootDirectory /home/%u\n  ForceCommand internal-sftp\n  AllowTcpForwarding no\n" | tee -a "$SSHD_CONFIG"
    fi

    # Validate sshd syntax
    if sshd -t -f "$SSHD_CONFIG"; then
        echo " SSH configuration has correct syntax"
    else
        echo "Incorrect syntax in SSH configuration! Restoring backup config."
        copy_file "$SSHD_BACKUP" "$SSHD_BACKUP"
        return 1
    fi

    run_cmd "systemctl restart sshd"
}

configure_system() {
    run_cmd "timedatectl set-timezone $TIMEZONE"
    run_cmd "hostnamectl set-hostname $HOSTNAME_SET"
    run_cmd "timedatectl set-ntp true"
}

# Command checks if provided command exist, -v verify mode - returns path to executable
configure_firewall() {
    if command -v ufw &>/dev/null; then
        run_cmd "ufw allow $SSH_PORT"
        for PORT in "${PORTS_TO_OPEN[@]}"; do
            run_cmd "ufw allow $PORT"
        done
        run_cmd "ufw --force enable" # Enable firewall
    elif command -v firewall-cmd &>/dev/null; then
        for PORT in "${PORTS_TO_OPEN[@]}"; do
            run_cmd "firewall-cmd --permanent --add-port=${PORT}/tcp"
        done
        run_cmd "firewall-cmd --reload"
    else
        echo "[WARN] No firewall tool found"
    fi
}

rollback_changes() {
    echo "[INFO] Rolling back changes..."
    if [ -f "$SSHD_BACKUP" ]; then
        copy_file "$SSHD_BACKUP" "$SSHD_CONFIG"
        run_cmd "systemctl restart sshd"
        echo "[INFO] Restored sshd_config from backup"
    fi

    for USER in "${USERS[@]}"; do
        if id "$USER" &>/dev/null; then
            run_cmd "userdel -r $USER" # -r delete home directory and user files
        fi
    done

    if getent group "$USER_GROUP" &>/dev/null; then
        run_cmd "groupdel $USER_GROUP"
    fi

    if command -v ufw &>/dev/null; then
        for PORT in "${PORTS_TO_OPEN[@]}"; do
            run_cmd "ufw delete allow $PORT" || true # || true means don't exit script even if command failed
        done
    elif command -v firewall-cmd &>/dev/null; then
        for PORT in "${PORTS_TO_OPEN[@]}"; do
            run_cmd "firewall-cmd --permanent --remove-port=${PORT}/tcp"
        done
        run_cmd "firewall-cmd --reload"
    fi
}

auto_mode() {
    echo "[AUTO] Running full automatic provisioning..."
    install_packages
    setup_users
    configure_ssh
    configure_system
    configure_firewall
    echo "[AUTO] Provisioning completed."
}

manual_mode() {
    echo "[MANUAL] Choose actions:"
    echo "1) Install packages"
    echo "2) Setup users and SSH keys"
    echo "3) Configure SSH"
    echo "4) Set timezone/hostname/NTP"
    echo "5) Configure firewall"
    echo "6) Exit"
    while true; do
        read -rp "Select [1-6]: " opt # -r ignore special chars, -p show communicate before executing command
        case $opt in
            1) install_packages ;;
            2) setup_users ;;
            3) configure_ssh ;;
            4) configure_system ;;
            5) configure_firewall ;;
            6) break ;;
            *) echo "Invalid option" ;;
        esac
    done
}

show_menu() {
    echo "========== PROVISION MENU =========="
    echo "1) Automatic provisioning"
    echo "2) Manual step-by-step provisioning"
    echo "3) Rollback changes"
    echo "4) Exit"
    echo "===================================="
    read -rp "Choose an option [1-4]: " CHOICE

    case $CHOICE in
        1) auto_mode ;;
        2) manual_mode ;;
        3) rollback_changes ;;
        4) echo "Bye!"; exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
}

# === START ===
show_menu