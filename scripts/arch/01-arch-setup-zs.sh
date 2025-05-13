#!/bin/bash
set -euo pipefail

# 01-arch-zfs-setup.sh (Arch version)
# Installs ZFS on the Arch Linux live ISO, loads the module, and sets hostid.

# Check or detect DISTRO_ID, ensure it is arch
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

if [[ "$DISTRO_ID" != "arch" ]]; then
    echo "This script is only for Arch Linux. Exiting."
    exit 1
fi

# --- Optimize mirrors using reflector ---
echo "Optimizing pacman mirrors with reflector..."
if ! command -v reflector &>/dev/null; then
    sudo pacman -Sy --noconfirm reflector rsync
fi

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# You can change the country codes below to your preferred region
sudo reflector --verbose --country US,CA --protocol https --sort rate --latest 20 --download-timeout 6 --save /etc/pacman.d/mirrorlist

sudo pacman -Syy

# --- Add archzfs repo if missing ---
if ! grep -q "^\[archzfs\]" /etc/pacman.conf; then
    echo -e "\n[archzfs]\nServer = https://archzfs.com/\$repo/\$arch" | sudo tee -a /etc/pacman.conf
    echo "Added [archzfs] repo to /etc/pacman.conf."
fi

# --- Import and locally sign the archzfs key ---
ARCHZFS_KEY="F75D9D76"
if ! sudo pacman-key --list-keys "$ARCHZFS_KEY" &>/dev/null; then
    sudo pacman-key -r "$ARCHZFS_KEY"
    sudo pacman-key --lsign-key "$ARCHZFS_KEY"
    echo "Imported and locally signed archzfs key."
fi

sudo pacman -Syy

# --- Install kernel headers and ZFS ---
# Try to install prebuilt zfs-linux, fallback to zfs-dkms if unavailable
if sudo pacman -S --noconfirm zfs-linux zfs-utils linux-headers; then
    echo "Installed prebuilt zfs-linux module."
else
    sudo pacman -S --noconfirm zfs-dkms zfs-utils linux-headers base-devel
    echo "Installed zfs-dkms for current kernel."
fi

# --- Load the ZFS module ---
if ! sudo modprobe zfs; then
    echo "Error: modprobe zfs failed. ZFS kernel module could not be loaded." >&2
    exit 1
fi

# --- Set hostid (customize as needed) ---
sudo rm -f /etc/hostid
sudo zgenhostid dadab0de

# --- List any ZFS pools and datasets ---
echo "Existing ZFS pools:"
sudo zpool list || echo "No pools found."

if sudo zpool list | grep -q zroot; then
    echo "Datasets in zroot:"
    sudo zfs list -r zroot
else
    echo "No zroot pool found."
fi

echo "ZFS live setup complete. Continue with pool creation and dataset setup."
