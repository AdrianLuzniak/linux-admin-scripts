#!/bin/bash

set -euo pipefail

LOG_FILE="./provision-$(date '+%Y%m%d-%H%M%S').log"

# First > means redirect stdout
# >(command) means process substitution, create temporary file with output of command
exec > >(tee -a "LOG_FILE") 2>&1

# If DRY_RUN is set use it's value, if NOT false is default option
DRY_RUN=${DRY_RUN:-false}

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
pgk_detect(){
    source /etc/os-release
    if [[ "$ID_LIKE" == *"rhel"* ]] || [[ "ID" == "rocky" ]]; then
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
        local KEY_FILE="autorized_keys/$USER"
        if [ -f "$KEY_FILE" ]; then
            run_cmd "mkdir -p $SSH_DIR"
            run_cmd "chmod 700 "$SSH_DIR"
            copy_file "$KEY_FILE" "$SSH_DIR/authorized_keys"
            run_cmd "chmod 600 $SSH_DIR/authorized_keys"
            run_cmd "chown -R $USER:$USER $SSH_DIR\"
        else
            echo "[WARN] Missing authorized_keys for $USER"
        fi
    done
}

