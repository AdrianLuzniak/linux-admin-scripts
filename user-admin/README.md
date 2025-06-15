# User Management Script (`user-admin.sh`)

A Bash script for managing Linux system users.  
It provides functionalities to 
- **add / delete users**, 
- **manage sudo permissions**, 
- **lock / unlock accounts**,
- **generate user reports**.

---

## Features

- Add new users with home directory creation and password setup  
- Delete users along with their home directories  
- Grant sudo privileges (supports `sudo` or `wheel` groups)  
- Configure passwordless sudo access  
- Remove passwordless sudo access  
- Lock user accounts (soft or hard lock)  
- Unlock user accounts  
- Generate reports of active users, sudo users, and users with passwordless sudo  

---

## Requirements

- Linux system with standard user management utilities (`useradd`, `userdel`, `passwd`, `usermod`, `getent`)  
- Root privileges or run script with `sudo`  
- **Tested on**: CentOS Stream 9 (should work on other RHEL-based distributions)
---


## Commands
| Command                        | Description                                      | Example                                  |
|-------------------------------|------------------------------------------------|------------------------------------------|
| `add <username>`               | Add a new user with home directory and password| `sudo ./user-admin.sh add alice`          |
| `delete <username>`            | Delete user and their home directory            | `sudo ./user-admin.sh delete alice`       |
| `sudo <username>`              | Grant sudo privileges to user                    | `sudo ./user-admin.sh sudo alice`         |
| `nopasswd-sudo <username>`    | Grant passwordless sudo to user                  | `sudo ./user-admin.sh nopasswd-sudo alice`|
| `nopasswd-sudo <username> remove` | Remove passwordless sudo from user           | `sudo ./user-admin.sh nopasswd-sudo alice remove` |
| `lock <username> <soft\|hard>` | Lock user account (soft disables login, hard locks password) | `sudo ./user-admin.sh lock alice soft`    |
| `unlock <username>`            | Unlock user account                              | `sudo ./user-admin.sh unlock alice`       |
| `report`                      | Generate a report of active users and sudo privileges | `sudo ./user-admin.sh report`             |


## Usage
```bash
sudo ./user-admin.sh <command> [arguments]
```
##### Usage examples
- Add user 'bob'
```bash
sudo ./user-admin.sh add bob
```

- Grant sudo privileges to 'bob'
```bash
sudo ./user-admin.sh sudo bob
```

- Grant passwordless sudo to 'bob'
```bash
sudo ./user-admin.sh nopasswd-sudo bob
```

- Remove passwordless sudo from 'bob'
```bash
sudo ./user-admin.sh nopasswd-sudo bob remove
```

- Lock user 'bob' with soft lock
```bash
sudo ./user-admin.sh lock bob soft
```

- Unlock user 'bob'
```bash
sudo ./user-admin.sh unlock bob
```

- Generate users report
```bash
sudo ./user-admin.sh report
```

## Notes
- The script must be run with root privileges to perform user management operations.

- Passwordless sudo configuration depends on - editing /etc/sudoers or /etc/sudoers.d files. Use with caution.

##### Locking methods differ:
- Soft lock disables user login by setting shell to /usr/sbin/nologin or /bin/false.

- Hard lock locks the user password (using passwd -l).