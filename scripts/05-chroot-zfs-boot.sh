#!/bin/bash
set -euo pipefail

# 05-chroot-zfs-boot.sh
# Run this INSIDE the chroot!

# 1. Source /etc/os-release for DISTRO_ID, or prompt if missing
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-}"
fi

if [ -z "${DISTRO_ID-}" ]; then
    read -rp "Could not detect DISTRO_ID. Please enter your distro ID (e.g., arch, manjaro): " DISTRO_ID
    export DISTRO_ID
fi

echo "Using DISTRO_ID: $DISTRO_ID"

# 2. Set matching ZFS hostid
echo "Setting ZFS hostid..."
rm -f /etc/hostid
zgenhostid dadab0de

# 3. Ensure /etc/zfs exists and set zpool cachefile
echo "Setting zpool cachefile..."
mkdir -p /etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache zroot

# 5. Setup zfs list cache
echo "Setting up zfs list cache..."
mkdir -p /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/zroot

# 6. Ensure correct symlink for history_event-zfs-list-cacher.sh
SYMLINK_PATH="/etc/zfs/zed.d/history_event-zfs-list-cacher.sh"
TARGET_PATH="/usr/lib/zfs-linux/zed.d/history_event-zfs-list-cacher.sh"

if [[ ! -L "$SYMLINK_PATH" || "$(readlink -f "$SYMLINK_PATH")" != "$TARGET_PATH" ]]; then
    echo "Creating symlink: $SYMLINK_PATH -> $TARGET_PATH"
    ln -sf "$TARGET_PATH" "$SYMLINK_PATH"
else
    echo "Symlink for history_event-zfs-list-cacher.sh already exists and is correct."
fi

# 7. Enable required ZFS systemd services
echo "Enabling ZFS systemd services..."
systemctl enable zfs-import-cache.service
systemctl enable zfs.target
systemctl enable zfs-import.target
systemctl enable zfs-zed.service

# 8. Configure dracut for ZFS and regenerate initramfs
echo "Configuring dracut for ZFS..."
cat << EOF > /etc/dracut.conf.d/zol.conf
nofsck="yes"
add_dracutmodules+=" zfs "
omit_dracutmodules+=" btrfs "
EOF

echo "Regenerating initramfs with dracut..."
dracut --force --regenerate-all

# 9. Arch-specific: Initialize and sign pacman keys for archzfs
if [ "$DISTRO_ID" = "arch" ]; then
    echo "Initializing and signing pacman keys for archzfs..."
    pacman-key --init
    pacman-key --populate
    pacman-key --lsign-key F75D9D76
fi

# 10. Set root password
echo "Set root password:"
passwd

echo "Minimal ZFS boot setup complete. You may now reboot."
