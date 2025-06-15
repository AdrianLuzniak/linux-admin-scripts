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
    if groups "$username" | grep -qw "sudo"; then # -q silent mode; -w match whole word
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

    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi

    # Lock the user account
    passwd -l "$username"
    if [ $? -ne 0 ]; then
        echo "Failed to lock user '$username'."
        return 1
    fi
    
    echo "User '$username' has been locked successfully."

}

unlock_user (){
    local username="$1"

    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi

    echo "Unlocking user '$username'..."
    sudo passwd -u "$username" # unlock password for user
    sudo usermod -U "$username" # unlock user account
    sudo usermod -s /bin/bash "$username" #u nlocking the interactive shell when logging in
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
        sudo_users=$(getent group sudo | awk -F: '{ print $4 }' | tr ',' '\n' | sort)
        if [ -z "$sudo_users" ]; then
            echo "No users in sudo group." >> "$report_file"
        else
            echo "$sudo_users" | awk '{ print "- " $1 }' >> "$report_file"
        fi
    fi

    echo "Report saved to '$report_file'"
    cat "$report_file"
}

# Main argument handling
case "$1" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: $0 add <username>"
            exit 1
        fi
        add_user "$2"
        ;;
    delete)
        if [ -z "$2" ]; then
            echo "Usage: $0 delete <username>"
            exit 1
        fi
        delete_user "$2"
        ;;
    sudo) 
        if [ -z "$2" ]; then
            echo "Usage $0 sudo <username>"
            exit 1
        fi
        grant_sudo "$2"
        ;;
    lock)
        if [ -z "$2" ]; then
            cho "Usage: $0 lock <username>"
            exit 1
        fi
        lock_user "$2"
        ;;
    unlock)
        if [ -z "$2" ]; then
            cho "Usage: $0 lock <username>"
            exit 1
        fi
        unlock_user "$2"
        ;;
    report)
        generate_report
        ;;
    *)
        echo "Available commands:"
        echo "  add <username>     - Add a new user"
        echo "  delete <username>  - Delete an existing user"
        echo "  sudo <username>    - Grant sudo privileges"
        echo "  lock <username>    - Lock user account"
        echo "  report             - Generate user access report"
        ;;
esac
