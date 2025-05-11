#!/bin/bash
set -euo pipefail

# 00-bootstrap.sh
# Detects target host and distro, ensures git is installed, and clones the linux-zfs-bootstrap repo.

# Prompt for TARGET_HOST
read -p "Enter target hostname (leave blank for auto-detect): " TARGET_HOST

# Auto-detect if blank
if [ -z "$TARGET_HOST" ]; then
    CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
    NVME_COUNT=$(ls /dev/nvme* 2>/dev/null | wc -l)

    if [[ "$CPU_VENDOR" == "AuthenticAMD" && "$NVME_COUNT" -ge 2 ]]; then
        TARGET_HOST="parents-pc"
    elif [[ "$CPU_VENDOR" == "GenuineIntel" && "$NVME_COUNT" -eq 0 ]]; then
        TARGET_HOST="thinkpad-t450"
    else
        while [ -z "$TARGET_HOST" ]; do
            read -p "Unknown hardware. Please enter hostname (parents-pc/thinkpad-t450): " TARGET_HOST
        done
    fi
fi

export TARGET_HOST

# Save to temp config for later scripts
echo "TARGET_HOST=$TARGET_HOST" > /tmp/host.conf

# Distro detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
else
    echo "Cannot detect distro!"
    exit 1
fi

export DISTRO_ID
echo "DISTRO_ID=$DISTRO_ID" >> /tmp/host.conf

# Ensure git is installed
if ! command -v git &>/dev/null; then
    echo "Git not found, attempting to install..."
    case "$DISTRO_ID" in
        manjaro|arch)
            sudo pacman -Sy --noconfirm git
            ;;
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y git
            ;;
        fedora)
            sudo dnf install -y git
            ;;
        *)
            echo "Unknown distro, please install git manually."
            exit 1
            ;;
    esac
fi

# Clone the linux-zfs-bootstrap repo to $HOME if not already present
REPO_DIR="$HOME/linux-zfs-bootstrap"
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/jjquin/linux-zfs-bootstrap.git "$REPO_DIR"
fi

echo "Bootstrap complete. Repo cloned to $REPO_DIR."
echo "Host: $TARGET_HOST, Distro: $DISTRO_ID"
echo "You can now run the next script in $REPO_DIR/scripts/"

# Optionally, cd into the repo and start the next phase automatically:
# cd "$REPO_DIR/scripts"
# ./01-zfs-live-setup.sh
