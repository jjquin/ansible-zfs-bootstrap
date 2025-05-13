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

# 4. Set ZFSBootMenu properties
echo "Setting ZFSBootMenu properties..."
zfs set org.zfsbootmenu:bootfs=on zroot/ROOT/$DISTRO_ID
zfs set org.zfsbootmenu:active=on zroot/ROOT
zfs set org.zfsbootmenu:commandline="quiet" zroot/ROOT

# 5. Setup zfs list cache
echo "Setting up zfs list cache..."
mkdir -p /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/zroot

# 6. Enable required ZFS systemd services
echo "Enabling ZFS systemd services..."
systemctl enable zfs-import-cache.service
systemctl enable zfs.target
systemctl enable zfs-import.target
systemctl enable zfs-zed.service

# 7. Configure dracut for ZFS and regenerate initramfs
echo "Configuring dracut for ZFS..."
cat << EOF > /etc/dracut.conf.d/zol.conf
nofsck="yes"
add_dracutmodules+=" zfs "
omit_dracutmodules+=" btrfs "
EOF

echo "Regenerating initramfs with dracut..."
dracut --force --regenerate-all

# 8. Arch-specific: Initialize and sign pacman keys for archzfs
if [ "$DISTRO_ID" = "arch" ]; then
    echo "Initializing and signing pacman keys for archzfs..."
    pacman-key --init
    pacman-key --populate
    pacman-key --lsign-key F75D9D76
fi

# 9. Set root password
echo "Set root password:"
passwd

echo "Minimal ZFS boot setup complete. You may now reboot."
