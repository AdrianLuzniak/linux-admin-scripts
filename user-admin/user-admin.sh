#!/bin/bash

# ===============================
# User Management Script (user-admin.sh)
# Features:
# - Add user (with home directory and password)
# - Delete user (with home directory)
# - Grant sudo privileges
# - Lock user account
# - Generate user report
# ===============================

SCRIPT_NAME=$(basename "$0") #get only script name without relative path
ACTION="$1"
USERNAME="$2"
LOCK_TYPE="$3"

add_user () {
    local username="$1"

    # Check if user already exist
    if id "$username" &>/dev/null; then
        echo "User '$username' already exist."
        return 1
    fi

    # Add user with home directory
    useradd -m "$username" # -m creates home dir
    if [ $? -ne 0 ]; then
        echo "Failed to create user '$username'."
        return 1
    fi

    # Set user password
    echo "Set a password for user '$username':"
    passwd "$username"

    echo "User '$username' has been added successfully."
}

delete_user () {
    local username="$1"
    
    # Check if the user exist
    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi

    # Delete user and their home directory
    userdel -r "$username" # -r delete home dir and mails
    if [ $? -ne 0 ]; then
        echo "Error while deleting user '$username'."
        return 1
    fi
    
    echo "User '$username' has been deleted successfully."
}

grant_sudo () {
    local username="$1"

    # Check if the user exist
    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi

    # Detect which sudo group exists: sudo or wheel
    local sudo_group=""
    if getent group sudo >/dev/null 2>&1; then
        sudo_group="sudo"
    elif getent group wheel >/dev/null 2>&1; then
        sudo_group="wheel"
    else
        echo "Neither 'sudo' nor 'wheel' group exists on this system."
        return 1
    fi

    # Check if user is already in sudo group
    if groups "$username" | grep -qw "$sudo_group"; then # -q silent mode; -w match whole word
        echo "User '$username' already has sudo privileges."
        return 0
    fi
    # Add user to the sudo group
    usermod -aG "$sudo_group" "$username"
    if [ $? -ne 0 ]; then 
        echo "Failed to add '$username' to the sudo group"
        return 1
    fi

    echo "User '$username' has been granted sudo privileges"
}

lock_user () {
    local username="$1"

    # ${parameter:-default}
    # parameter — is a variable (e.g. $2).
    # default — is the default value you want to assign if the variable is empty or undefined.
    # :-  "If parameter is unset or empty, use default."
    local lock_type="${2:-soft}" 
  
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi

    echo "Locking user '$username' with '$lock_type' lock..."

    case "$lock_type" in
        soft)
            # Soft lock the user account
            passwd -l "$username"
            if [ $? -ne 0 ]; then
                echo "Failed to apply soft lock user '$username'."
                return 1
            fi
            echo "Soft lock applied to user '$username'."
            ;;
        hard) 
            # {} logical block of commands to be executed as a whole expression
            passwd -l "$username" || { echo "Failed to lock password for user '$username'."; return 1; } # lock password for user
            usermod -L "$username"  || { echo "Failed to lock account for user '$username'."; return 1; } # lock user account
            usermod -s /sbin/nologin "$username" || { echo "Failed to set nologin shell for user '$username'."; return 1; } # lock interactive shell login
            echo "Hard lock applied to user '$username'."
            ;;
        *)
            echo "Invalid lock type '$lock_type'. Use 'soft' or 'hard'."
            return 1
            ;;
    esac
}

unlock_user (){
    local username="$1"

    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi

    echo "Unlocking user '$username'..."
    passwd -u "$username" || { echo "Failed to unlock password for user '$username'."; return 1; } # unlock password for user
    usermod -U "$username" || { echo "Failed to unlock account for user '$username'."; return 1; } # unlock user account
    usermod -s /bin/bash "$username" || { echo "Failed to unlock interactive shell login for user '$username'."; return 1; } # unlocking the interactive shell when logging in
    echo "User '$username' was successfully unlocked."

}
generate_report() {    
    local report_file="user_report.txt"
    echo "Generating user report"

    # awk – a line-by-line text processing program, often used to work with text files (e.g. /etc/passwd)
    # awk 'condition { action }', -F field separator, we can use awk WITHOUT condition
    # The condition in awk applies to one line of input – awk processes the data line by line, and for each line
    # In awk, to combine several things into one print, we write them next to each other using "
    # If the condition is true for a given line, awk executes the code in {}

    # UID
    # 0 superuser (root)
    # 1–999 system users (e.g. daemon, nobody, sshd, systemd-network)
    # 1000+ regular users (e.g. you)
    # 65534 often nobody, a user with no privileges
    
    echo "===== ACTIVE USERS (UID ≥ 1000) =====" > "$report_file"
    awk -F: '$3 >= 1000 && $3 < 65534 { print "- " $1 " (UID: "$3")" }' /etc/passwd >> "$report_file"

    echo -e "\n===== USERS WITH SUDO PRIVILEGES =====" >> "$report_file"
    if [ -f /etc/group ]; then
        if getent group sudo >/dev/null 2>&1; then
            sudo_users=$(getent group sudo | awk -F: '{ print $4 }' | tr ',' '\n' | sort)
        elif getent group wheel >/dev/null 2>&1; then
            sudo_users=$(getent group wheel | awk -F: '{ print $4 }' | tr ',' '\n' | sort)
        else 
            sudo_users=""
        fi

        if [ -z "$sudo_users" ]; then
            echo "No users in sudo group." >> "$report_file"
        else
            echo "$sudo_users" | awk '{ print "- " $1 }' >> "$report_file"
        fi
        
        if [ $? -ne 0 ]; then
        echo "Failed to append sudo users to $report_file"
        return 1
        fi
    fi

    echo "Report saved to '$report_file'"
    cat "$report_file"
}


if [ "$EUID" -ne 0 ]; then
    echo "Please execute this script with sudo privileges."
    exit 1
fi

# Main argument handling
case "$ACTION" in
    --add|-a|add)
        if [ -z "$USERNAME" ]; then
            echo "Usage: $SCRIPT_NAME add <username>"
            exit 1
        fi
        add_user "$USERNAME"
        exit $?
        ;;
    --delete|-d|delete)
        if [ -z "$USERNAME" ]; then
            echo "Usage: $SCRIPT_NAME delete <username>"
            exit 1
        fi
        delete_user "$USERNAME"
        exit $?
        ;;
    --sudo|-s|sudo) 
        if [ -z "$USERNAME" ]; then
            echo "Usage $SCRIPT_NAME sudo <username>"
            exit 1
        fi
        grant_sudo "$USERNAME"
        exit $?
        ;;
    --lock|-l|lock)
        if [ -z "$USERNAME" ]; then
            echo "Usage: $SCRIPT_NAME lock <username> <soft|hard>"
            exit 1
        fi

        if [[ "$LOCK_TYPE" != "soft" && "$LOCK_TYPE" != "hard" ]]; then
            echo "Invalid lock type '$LOCK_TYPE'. Use 'soft' or 'hard'."
            exit 1
        fi

        lock_user "$USERNAME" "$LOCK_TYPE"
        exit_code=$?    
        exit $exit_code 

        ;;
    --unlock|-u|unlock)
        if [ -z "$USERNAME" ]; then
            echo "Usage: $SCRIPT_NAME unlock <username>"
            exit 1
        fi
        unlock_user "$USERNAME"
        exit $?
        ;;
    --report|-r|report)
        generate_report
        exit $?
        ;;
    *)
        echo "Usage: $SCRIPT_NAME <option> [arguments]"
        echo ""
        echo "Options:"
        echo "  --add|-a|add <username>           Add a new user"
        echo "  --delete|-d|delete <username>     Delete a user"
        echo "  --sudo|-s|sudo <username>         Grant sudo privileges to a user"
        echo "  --lock|-l|lock <username> <type>  Lock user account (type: soft | hard)"
        echo "  --unlock|-u|unlock <username>     Unlock user account"
        echo "  --report|-r|report                Generate a sudo users report"
        echo ""
        echo "Examples:"
        echo "  $SCRIPT_NAME --add alice"
        echo "  $SCRIPT_NAME -l bob soft"
        echo "  $SCRIPT_NAME report"
        exit 1
        ;;
esac
