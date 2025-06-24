#!/bin/bash

# --------- General Functions ---------
check_docker_installed() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed! Please install docker first."
        exit 1
    fi
}

pause() {
    read -p "Press [Enter] to continue..." 
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
    docker start "$name"
}

stop_container() {
    read -p "Enter container name: " name
    docker stop "$name"
}

remove_container() {
    read -p "Enter container name to remove: " name
    docker rm "$name"
}

show_stats() {
    docker stats --no-stream
}

# --------- Image Operations ---------
build_image(){
    read -p "Enter path to Dockerfile directory: " path
    read -p "Enter image name/tag (e.g user/image:tag): " img_name
    docker build -t "$img_name" "$path"
}

push_image() {
    read -p "Enter Docker Hub username: " username
    read -p "Enter image name/tag (e.g user/iamge:tag): " img_name
    docker login -u "$username"
    docker push "$img_name"
}

# --------- Volume and Network Operations ---------
list_volumes() {
    docker volume ls
}

create_volume() {
    read -p "Enter volume name: " volume_name
    docker volume create "$volume_name"
}

list_networks() {
    docker network ls
}

create_network() {
    read -p "Enter network name: " network_name
    docker network create "$network_name"
}

remove_network() {
    read -p "Enter network name to remove: " network_name
    docker network rm "$network_name"
}

# --------- Docker System Cleanup ---------
cleanup_docker() {
    echo "This will remove all unused containers, volumes, and networks."
    read -p "Are you sure (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y"]]; then
        docker system prune -f
    else
        echo "Cleanup canceled."
    fi
}

# --------- Main Menu ---------
main_menu() {
    clear
    echo "Welcome to Docker Helper Tool!"
    echo "Choose an option:"
    PS3="Select an option (1-9):"

# The REPLY variable in Bash is automatically set by the select construct – you don't need to define it
# When the user types e.g. 2 and presses Enter:
# REPLY will have the value "2" (i.e. the option number),
# opt will have the value "Stop" (i.e. the value of the selected option from the list

    select opt in "Start Container" "Stop Container" "Remove Container" "Show Stats" "Build Image" "Push Image" "List Containers" "List Volumes" "Cleanup Docker" "Exit"; do
        case $REPLY in
            1) start_container ;;
            2) stop_container ;;
            3) remove_container ;;
            4) show_stats ;;
            5) build_image ;;
            6) push_image ;;
            7) list_containers ;;
            8) list_volumes ;;
            9) cleanup_docker ;;
            10) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option, please try again." ;;
        esac
        pause
        main_menu
    done
}

# Check if Docker is installed
check_docker_installed

# Run the main menu
main_menu