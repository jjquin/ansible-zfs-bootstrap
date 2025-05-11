#!/bin/bash
set -euo pipefail

# 05-manjaro-chroot-zfs-boot.sh
# Run this INSIDE the chroot!

# 1. Set matching ZFS hostid
echo "Setting ZFS hostid..."
rm -f /etc/hostid
zgenhostid dadab0de

# 2. Ensure /etc/zfs exists and set zpool cachefile
echo "Setting zpool cachefile..."
mkdir -p /etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache zroot

# 3. Set ZFSBootMenu properties
# Detect distro ID for bootfs property
if [ -z "${DISTRO_ID-}" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID=$ID
    else
        echo "Warning: Could not detect DISTRO_ID, defaulting to 'manjaro'."
        DISTRO_ID=manjaro
    fi
fi

echo "Setting ZFSBootMenu properties..."
zfs set org.zfsbootmenu:bootfs=on zroot/ROOT/$DISTRO_ID
zfs set org.zfsbootmenu:active=on zroot/ROOT
zfs set org.zfsbootmenu:commandline="quiet" zroot/ROOT

# 4. Setup zfs list cache
echo "Setting up zfs list cache..."
mkdir -p /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/zroot

# 5. Enable required ZFS systemd services
echo "Enabling ZFS systemd services..."
systemctl enable zfs-import-cache.service
systemctl enable zfs.target
systemctl enable zfs-import.target
systemctl enable zfs-zed.service

# 6. Configure dracut for ZFS and regenerate initramfs
echo "Configuring dracut for ZFS..."
cat << EOF > /etc/dracut.conf.d/zol.conf
nofsck="yes"
add_dracutmodules+=" zfs "
omit_dracutmodules+=" btrfs "
EOF

echo "Regenerating initramfs with dracut..."
dracut --force --regenerate-all

# 7. Set root password
echo "Set root password:"
passwd

echo "Minimal ZFS boot setup complete. You may now reboot."
