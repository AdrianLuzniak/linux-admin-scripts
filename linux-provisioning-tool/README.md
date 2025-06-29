# 🔧 Linux Provisioning Script

This is a fully automated and interactive Bash script for provisioning development or testing Linux environments. It handles package installation, user creation with SSH access, SSH configuration, firewall rules, and basic system setup.

> ✅ **Tested on**: CentOS 8 / Rocky Linux 9  
> ⚠️ May work on Debian/Ubuntu-based systems, but the script is optimized for RHEL-based distributions.

---

## 📦 Features

- Detects package manager (`dnf` or `apt`) automatically.
- Installs required packages (e.g., `htop`, `curl`, `git`).
- Creates users and assigns them to a shared group.
- Adds SSH access with password and/or public key authentication.
- Sets timezone, hostname, and enables NTP.
- Configures firewall (`ufw` or `firewalld`) to open required ports.
- Supports **dry-run mode** (`DRY_RUN=true`) to simulate actions.
- Allows **manual** or **automatic** provisioning.
- Supports **rollback** of most actions.

---

## ⚙️ Requirements

- Root privileges (`sudo` or run as root).
- Linux with working `bash` shell.
- SSH server installed and running (`sshd`).
- Public keys stored in `authorized_keys/` folder.
- Tested on: **Rocky Linux 9**, **CentOS 8**.

---

## 🚀 Quick Start

Clone the repo and make the script executable:

```bash
chmod +x provision.sh
```

Then run it:

```bash
./provision.sh
```

You will be prompted with a menu:

```
========== PROVISION MENU ==========
1) Automatic provisioning
2) Manual step-by-step provisioning
3) Rollback changes
4) Exit
====================================
```

---

## 🧪 Dry-Run Mode

Use dry-run mode to see what actions the script *would* take, without making actual changes:

```bash
./provision.sh true
```

---

## 🛠 Automatic Provisioning

Run all provisioning steps at once:

```bash
./provision.sh
# then choose option 1 (Automatic provisioning)
```

This will:
1. Install required packages (`htop`, `curl`, `git`)
2. Create users (`devuser1`, `devuser2`)
3. Configure SSH (password & key auth)
4. Set timezone to Europe/Warsaw and hostname to `dev-machine`
5. Open ports 20, 80, 443 (and SSH - 22) in the firewall

---

## 🧩 Manual Provisioning

Choose specific steps to execute:

```bash
./provision.sh
# then choose option 2 (Manual provisioning)
```

You'll see options like:

```
1) Install packages
2) Setup users and SSH keys
3) Configure SSH
4) Set timezone/hostname/NTP
5) Configure firewall
```

---

## 🔐 Adding SSH Keys for Users

Before running the script, prepare a folder named `authorized_keys/` in the same directory.

For each user (e.g. `devuser1`), place their public key file in:

```
authorized_keys/devuser1
authorized_keys/devuser2
```

These will be copied to:

```
/home/devuser1/.ssh/authorized_keys
```

If a key file is missing, the script will print a warning.

---

## 🔁 Rollback

To undo most of the changes:

```bash
./provision.sh
# then choose option 3 (Rollback changes)
```

This will:
- Remove users and home directories
- Delete the user group
- Restore original `sshd_config`
- Revert opened firewall ports (if possible)

---

## 📁 Log File

Every run creates a timestamped log file:

```
provision-YYYYMMDD-HHMMSS.log
```

All stdout and stderr are captured.

---

## 📄 License

MIT — feel free to use, modify, and distribute.

---

## 🧠 Notes

- Password for created users is set to `ChangeMe123` (change after login).
- SSH config is backed up before any changes.
- `internal-sftp` is configured for `sftpusers` group with `ChrootDirectory`.

---

Happy provisioning! 🚀
