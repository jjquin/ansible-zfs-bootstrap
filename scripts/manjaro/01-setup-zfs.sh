#!/bin/bash
set -e

# Detect running kernel and install ZFS
KERNEL_PKG=$(mhwd-kernel -li | grep 'installed' | awk '{print $2}')
KERNEL_ZFS_PKG="${KERNEL_PKG}-zfs"
KERNEL_HDRS_PKG="${KERNEL_PKG}-headers"

sudo pacman-mirrors --fasttrack
sudo pacman -Syy
sudo pacman -S --noconfirm $KERNEL_ZFS_PKG zfs-utils $KERNEL_HDRS_PKG

# Try to load the ZFS module; print error and exit if it fails
if ! sudo modprobe zfs; then
  echo "Error: modprobe zfs failed. ZFS kernel module could not be loaded." >&2
  exit 1
fi

# Set hostid (replace with your preferred value if needed)
sudo rm -f /etc/hostid
sudo zgenhostid dadab0de

# Optionally start SSH
read -p "Start SSH server for remote access? (y/n): " SSH_CHOICE
if [[ "$SSH_CHOICE" =~ ^[Yy]$ ]]; then
    sudo systemctl start sshd
    echo "SSH server started."
    echo "IP address(es):"
    hostname -I
fi

# List any ZFS pools and datasets
echo "Existing ZFS pools:"
sudo zpool list || echo "No pools found."

if sudo zpool list | grep -q zroot; then
    echo "Datasets in zroot:"
    sudo zfs list -r zroot
else
    echo "No zroot pool found."
fi
