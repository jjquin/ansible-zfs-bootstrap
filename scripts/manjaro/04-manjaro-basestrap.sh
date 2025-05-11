#!/bin/bash
set -euo pipefail

# 04-manjaro-basestrap.sh

# Prompt for TARGET_HOST if not set
if [ -z "${TARGET_HOST-}" ]; then
    read -p "Enter target hostname: " TARGET_HOST
    export TARGET_HOST
fi

# Check or detect DISTRO_ID, ensure it is manjaro
if [ -z "${DISTRO_ID-}" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID=$ID
        export DISTRO_ID
        echo "Detected DISTRO_ID: $DISTRO_ID"
    else
        echo "Cannot detect DISTRO_ID and it is not set. Exiting."
        exit 1
    fi
fi

if [ "$DISTRO_ID" != "manjaro" ]; then
    echo "Warning: DISTRO_ID is '$DISTRO_ID', expected 'manjaro'. Continuing anyway."
fi

MNT=/mnt

# 1. Update mirrors and refresh package database
sudo pacman-mirrors --fasttrack
sudo pacman -Syy

# 2. Detect latest installed kernel (e.g., linux515)
KERNEL=$(mhwd-kernel -li | awk '/installed/ {print $2}' | head -n1)
if [[ -z "$KERNEL" ]]; then
    echo "ERROR: Could not detect installed kernel."
    exit 1
fi

KERNEL_HEADERS="${KERNEL}-headers"
KERNEL_ZFS="${KERNEL}-zfs"

echo "Detected kernel: $KERNEL"
echo "Will install: $KERNEL, $KERNEL_HEADERS, $KERNEL_ZFS"

# 3. Install base system and essential packages for first boot
sudo basestrap "$MNT" \
    base base-devel \
    "$KERNEL" "$KERNEL_HEADERS" "$KERNEL_ZFS" \
    linux-firmware \
    sudo git ansible nano \
    networkmanager dracut

# 4. Create /mnt/etc and set hostname
sudo mkdir -p "$MNT/etc"
echo "$TARGET_HOST" | sudo tee "$MNT/etc/hostname"

echo "Base system installed, networking enabled, and hostname set."

# 5. Enter chroot for further configuration
echo "Entering chroot for further configuration..."
sudo arch-chroot "$MNT"

# End of script
