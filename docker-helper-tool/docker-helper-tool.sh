#!/bin/bash


# --------- Colors ---------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# \033 (or \e) is the ASCII ESC (escape) character.
# Then, in parentheses [, the ANSI escape sequence begins.
# 0;31m is the color code—e.g., 31 is red, 32 green, 33 yellow, 34 blue.

# --------- Docker installation for CentOS ---------
install_docker() {
    LOG_FILE="docker_install.log"
    echo "========== $(date '+%Y-%m-%d %H:%M:%S') ==========" | tee -a "$LOG_FILE"

    {
        echo -e "${BLUE}[INFO] Removing old Docker versions (if any)...${NC}"
        sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true

        echo -e "${BLUE}[INFO] Updating system packages...${NC}"
        sudo dnf -y update

        echo -e "${BLUE}[INFO] Installing dnf-plugins-core (with --nogpgcheck)...${NC}"
        sudo dnf install -y --nogpgcheck dnf-plugins-core

        echo -e "${BLUE}[INFO] Adding Docker repository...${NC}"
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

        echo -e "${BLUE}[INFO] Installing Docker packages (with --nogpgcheck)...${NC}"
        sudo dnf install -y --nogpgcheck docker-ce docker-ce-cli containerd.io

        echo -e "${BLUE}[INFO] Starting and enabling Docker service...${NC}"
        sudo systemctl start docker
        sudo systemctl enable docker

        echo -e "${BLUE}[INFO] Creating docker group if it does not exist and adding user '$USER' to it...${NC}"
        sudo groupadd -f docker
        sudo usermod -aG docker "$USER"

        echo -e "${GREEN}[INFO] Docker version:${NC}"
        docker --version

        echo -e "${GREEN}[INFO] Docker info:${NC}"
        docker info

        echo -e "${BLUE}[INFO] Testing Docker installation by running hello-world container...${NC}"
        sudo docker run hello-world

    } 2>&1 | tee -a "$LOG_FILE"

    # Sprawdzanie statusu ostatniego polecenia (docker run)
    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
        echo -e "${GREEN}Docker installation completed successfully.${NC}"
        echo -e "${YELLOW}Please log out and log back in (or reboot) to apply docker group permissions.${NC}"
    else
        echo -e "${RED}Docker installation failed. Check the log file at $LOG_FILE for details.${NC}"
        return 1
    fi
}

# --------- General Functions ---------
check_docker_installed() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed!${NC}"
        read -p "Do you want to install Docker now? (y/n): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then # check if input is Y or y
            install_docker
        else
            echo -e "${YELLOW}Please install Docker manually and rerun the script.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Docker is installed.${NC}"
    fi
}
# =~ — Regex matching operator.
# ^[Yy]$ — is a regular expression (regex) that matches:
# ^ — the beginning of a string
# [Yy] — one character, which can be either an uppercase Y or a lowercase y
# $ — the end of a string

# command is a built-in command in Bash that searches for and executes commands in the shell environment.
# command -v docker &> /dev/null checks if docker is on the system, but does not print anything.
# ! means: if docker is NOT found, the then block will be executed.

pause() {
    read -rp "Press [Enter] to continue..." 
}

# --------- Container Operations ---------
list_containers() {
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
}

# docker ps -a — shows all containers (both running and stopped).
# --format — lets you specify how the output should look in template format.
# "table ..." — is an instruction to display the output in tabular format.
# {{.Names}}, {{.Image}}, {{.Status}} — are placeholders (places to insert values) that correspond to specific container fields:

start_container() {
    read -p "Enter container name: " name # -p wait for input, save it in name variable
    docker start "$name" && echo -e "${GREEN}Container '$name' started.${NC}" || echo -e "${RED}Failed to start container '$name'.${NC}"
}

stop_container() {
    read -p "Enter container name: " name
    docker stop "$name" && echo -e "${GREEN}Container '$name' stopped.${NC}" || echo -e "${RED}Failed to stop container '$name'.${NC}"
}

remove_container() {
    read -p "Enter container name to remove: " name
    docker rm "$name" && echo -e "${GREEN}Container '$name' removed.${NC}" || echo -e "${RED}Failed to remove container '$name'.${NC}"
}

show_stats() {
    docker stats --no-stream
}

# --------- Image Operations ---------
build_image(){
    read -p "Enter path to Dockerfile directory: " path
    read -p "Enter image name/tag (e.g user/image:tag): " img_name
    docker build -t "$img_name" "$path" && echo -e "${GREEN}Image '$img_name' built successfully.${NC}" || echo -e "${RED}Image build failed.${NC}"
}

push_image() {
    read -p "Enter Docker Hub username: " username
    read -p "Enter image name/tag (e.g user/image:tag): " img_name
    docker login -u "$username"
    docker push "$img_name" && echo -e "${GREEN}Image '$img_name' pushed successfully.${NC}" || echo -e "${RED}Failed to push image '${img_name}'.${NC}"
}

# --------- Volume and Network Operations ---------
list_volumes() {
    docker volume ls
}

create_volume() {
    read -p "Enter volume name: " volume_name
    docker volume create "$volume_name"  && echo -e "${GREEN}Volume '$volume_name' created.${NC}" || echo -e "${RED}Failed to create volume '$volume_name'.${NC}"
}

list_networks() {
    docker network ls
}

create_network() {
    read -p "Enter network name: " network_name
    docker network create "$network_name" && echo -e "${GREEN}Network '$network_name' created.${NC}" || echo -e "${RED}Failed to create network '$network_name'.${NC}"
}

remove_network() {
    read -p "Enter network name to remove: " network_name
    docker network rm "$network_name" && echo -e "${GREEN}Network '$network_name' removed.${NC}" || echo -e "${RED}Failed to remove network '$network_name'.${NC}"
}

# --------- Docker System Cleanup ---------
cleanup_docker() {
    echo "This will remove all unused containers, volumes, and networks."
    read -p "Are you sure (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker system prune -f && echo -e "${GREEN}Docker cleanup completed.${NC}" || echo -e "${RED}Docker cleanup failed.${NC}"
    else
        echo -e "${BLUE}Cleanup canceled.${NC}"
    fi
}

# --------- Main Menu ---------
main_menu() {
    while true; do
        clear
        echo "Welcome to Docker Helper Tool!"
        echo "Choose an option:"
        PS3="Select an option (1-9):"

    # The REPLY variable in Bash is automatically set by the select construct – you don't need to define it
    # When the user types e.g. 2 and presses Enter:
    # REPLY will have the value "2" (i.e. the option number),
    # opt will have the value "Stop" (i.e. the value of the selected option from the list

        select opt in "Install Docker" "Start Container" "Stop Container" "Remove Container" "Show Stats" "Build Image" "Push Image" "List Containers" "List Volumes" "Cleanup Docker" "Exit"; do
            case $REPLY in
                1) install_docker ;;
                2) start_container ;;
                3) stop_container ;;
                4) remove_container ;;
                5) show_stats ;;
                6) build_image ;;
                7) push_image ;;
                8) list_containers ;;
                9) list_volumes ;;
                10) cleanup_docker ;;
                11) echo -e "${BLUE}Exiting...${NC}"; exit 0 ;;
                *) echo -e "${RED}Invalid option, please try again.${NC}" ;;
            esac
            break # exit select, return to while - refresh menu
        done
        pause
    done
}

# Check if Docker is installed
check_docker_installed

# Run the main menu
main_menu