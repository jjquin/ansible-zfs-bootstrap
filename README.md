## ansible-zfs-bootstrap

This repository provides a reproducible, script-driven and Ansible-automated workflow for installing Linux distributions (with ZFS root) on multiple machines, supporting both single- and multi-distro setups. It is designed for advanced users who want to automate and standardize their Linux installations across different hardware using ZFS, with all post-install configuration managed by Ansible.

---

### **What This Repo Does**

- **Bootstraps a new Linux install** (from a live ISO) with ZFS as the root filesystem.
- **Supports multiple hosts and distros** by prompting for or auto-detecting the target machine and distribution.
- **Automates pre-chroot setup** (partitioning, pool creation, base install) via scripts.
- **Delegates all post-chroot configuration** (users, hostname, software, etc.) to Ansible playbooks and roles.
- **Keeps all scripts, templates, and Ansible logic in one place** for easy management and reproducibility.

---

## **How to Use**

### **1. Boot a Live ISO**

Boot into a supported Linux live ISO (e.g., Manjaro, Debian, Fedora, etc.).

---

### **2. Run the Bootstrap Script**

You can run the bootstrap script directly with:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jjquin/ansible-zfs-bootstrap/main/scripts/00-bootstrap.sh)

  ```
- Proceed with pool creation, dataset setup, and base install as directed by the scripts.
- After chroot and base install, use the included Ansible playbook (`ansible/site.yml`) to configure users, hostname, software, and more.

---

## **Host and Hardware Logic**

- `TARGET_HOST` controls host-specific logic, such as which drives to use for ZFS pools.
- If left blank, the script attempts to auto-detect based on CPU vendor and drive count.
- If not recognized, you will be prompted to enter the hostname manually.
- Scripts can use `TARGET_HOST` to prompt for drive selection or automate hardware-specific steps.

---

## **Extending and Customizing**

- Add or edit scripts in `scripts//` for pre-chroot setup.
- Add or edit Ansible roles and playbooks in `ansible/` for post-install configuration.
- Use `TARGET_HOST` and `DISTRO_ID` in your scripts and playbooks for conditional logic.

---

## **Contributing**

PRs and issues are welcome! Please document any new hardware or distro logic clearly in both scripts and playbooks.

---

**This repository aims to make multi-distro, ZFS-root Linux installs repeatable, robust, and easy to manage with Ansible.**

---
Answer from Perplexity: pplx.ai/share
