# linux-zfs-bootstrap

This repository provides a reproducible, script-driven workflow for installing Linux distributions with ZFS as the root filesystem. It is designed for advanced users who want to automate and standardize minimal Linux installations across different hardware and distributions, with all post-install configuration delegated to Ansible (see [ansible-linux-zfs](https://github.com/jjquin/ansible-linux-zfs)).

---

## What This Repo Does

- **Bootstraps a new Linux install** (from a live ISO) with ZFS as the root filesystem.
- **Supports multiple hosts and distros** by prompting for or auto-detecting the target machine and distribution.
- **Automates pre-chroot setup** (partitioning, pool creation, base install) via scripts.
- **Sets up only a minimal base system**: no user accounts or applications are installed-just enough to boot and hand off to Ansible for further configuration.
- **Keeps all setup scripts organized in a single place** for easy management and reproducibility.

---

## Directory Structure

- `scripts/`  
  Contains all setup scripts:
  - Common scripts for general tasks.
  - Distro-specific scripts in subfolders named after the distro ID (from `/etc/os-release`).

---

## How to Use

1. **Boot a Live ISO**  
   Boot into a supported Linux live ISO (e.g., Manjaro, Debian, Fedora, etc.).

2. **Run the Bootstrap Script**  
   Run the bootstrap script from the live environment:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jjquin/linux-zfs-bootstrap/main/scripts/00-bootstrap.sh)
```

- Follow prompts for pool creation, dataset setup, and base install as directed by the scripts.
- After reboot, continue with Ansible-based configuration using [ansible-linux-zfs](https://github.com/jjquin/ansible-linux-zfs).

---

## Host and Hardware Logic

- `TARGET_HOST` controls host-specific logic, such as which drives to use for ZFS pools.
- If left blank, the script attempts to auto-detect based on CPU vendor and drive count.
- If not recognized, you will be prompted to enter the hostname manually.
- Scripts use `TARGET_HOST` to prompt for drive selection or automate hardware-specific steps.

---

## Extending and Customizing

- Add or edit scripts in `scripts/` for pre-chroot setup.
- Use `TARGET_HOST` and `DISTRO_ID` in your scripts for conditional logic.
- For post-install configuration, see [ansible-linux-zfs](https://github.com/jjquin/ansible-linux-zfs).

---

## Contributing

Pull requests and issues are welcome! Please document any new hardware or distro logic clearly in the scripts.

---

**This repository aims to make multi-distro, ZFS-root Linux installs repeatable, robust, and easy to manage with Ansible.**
