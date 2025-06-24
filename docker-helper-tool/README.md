# Docker Helper Tool

A user-friendly Bash script to help manage Docker installation and common Docker operations on CentOS 9.  
This tool offers a simple interactive menu to install Docker, manage containers, images, volumes, networks, and perform cleanup tasks.

---

## Key Features

- **Automated Docker installation on CentOS 9**  
  Removes old versions, installs dependencies, adds Docker repo, installs Docker engine and CLI, and configures user permissions.
  
- **Container management**  
  Create, start, stop, remove containers interactively.
  
- **Image operations**  
  Build Docker images from a Dockerfile, push images to Docker Hub, list and remove images.
  
- **Volume and network management**  
  List and create Docker volumes and networks, remove networks.
  
- **System cleanup**  
  Remove all unused containers, volumes, and networks with confirmation.
  
- **Colorful and clear terminal output**  
  Uses ANSI colors for better readability of logs and messages.

---

## Requirements

- Tested on **CentOS 9** (should work on similar RHEL-based distros with `dnf`)
- Must be run with **sudo** or as root because Docker installation and many Docker commands require elevated privileges
- User running the script will be added to the `docker` group, but a logout/login or reboot is required to apply group permissions

---

## Installation & Usage

1. Save the script to a file, e.g. `docker-helper.sh`.
2. Make it executable:
   ```bash
   chmod +x docker-helper.sh
    ```
3. Run the script with sudo:
    ```bash
    sudo ./docker-helper.sh
    Follow the interactive menu to install Docker or manage Docker resources.
    ```

4. Follow the interactive menu to install Docker or manage Docker resources.

## Example Commands in the Tool
* **Install Docker**: Select option 1 to install Docker if not already present.

* **Create a container**: Select option 2, then enter the image name (e.g. ubuntu:latest), optionally a container name, and any additional docker run options.

* **Start/Stop** containers: Select options 3 or 4, then specify container names.

* **Build an image**: Select option 7, provide path to Dockerfile directory and image name/tag.

* **Push an image**: Select option 8, enter Docker Hub username and image name/tag.

* **List containers/images**: Options 9 and 10.

* **Cleanup unused Docker resources**: Option 13.

## Notes
* After Docker installation, log out and log back in or reboot to apply the new group permissions and use Docker without sudo.

* The script logs Docker installation steps and errors to docker_install.log in the current directory.

* Colors are used to highlight information (blue), success (green), warnings (yellow), and errors (red).