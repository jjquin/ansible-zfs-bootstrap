#!/bin/bash
set -euo pipefail

# 04-arch-basestrap.sh

# Prompt for TARGET_HOST if not set
if [ -z "${TARGET_HOST-}" ]; then
    read -p "Enter target hostname: " TARGET_HOST
    export TARGET_HOST
fi

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

if [ "$DISTRO_ID" != "arch" ]; then
    echo "Warning: DISTRO_ID is '$DISTRO_ID', expected 'arch'. Continuing anyway."
fi

MNT=/mnt

# 1. Update mirrors using reflector
if ! command -v reflector &>/dev/null; then
    sudo pacman -Sy --noconfirm reflector rsync
fi

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sudo reflector --verbose --country US,CA --protocol https --sort rate --latest 20 --download-timeout 6 --save /etc/pacman.d/mirrorlist

sudo pacman -Syy

# 2. Copy pacman.conf and pacman keyring to /mnt
sudo cp /etc/pacman.conf "$MNT/etc/pacman.conf"
sudo mkdir -p "$MNT/etc/pacman.d/"
sudo rsync -a /etc/pacman.d/gnupg "$MNT/etc/pacman.d/"

# 3. Set kernel and ZFS packages (standard Arch names)
KERNEL="linux"
KERNEL_HEADERS="linux-headers"
KERNEL_ZFS="zfs-linux"

# 4. Install base system and essential packages for first boot
sudo basestrap "$MNT" \
    base base-devel \
    "$KERNEL" "$KERNEL_HEADERS" "$KERNEL_ZFS" \
    linux-firmware \
    sudo git ansible nano \
    networkmanager

# 5. Create /mnt/etc and set hostname
sudo mkdir -p "$MNT/etc"
echo "$TARGET_HOST" | sudo tee "$MNT/etc/hostname"

# 6. Copy chroot script into /mnt/root
sudo mkdir -p "$MNT/root"
sudo cp ./05-arch-chroot-zfs-boot.sh "$MNT/root/"

echo "Base system installed, networking enabled, hostname set, pacman.conf and keys copied, and chroot script copied."

# 7. Enter chroot for further configuration
echo "Entering chroot for further configuration..."
sudo arch-chroot "$MNT"

# End of script
