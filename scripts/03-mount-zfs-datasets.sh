#!/bin/bash
set -e

# 03-mount-zfs-datasets.sh

# Check or detect DISTRO_ID
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

# Check or prompt for TARGET_HOST
if [ -z "${TARGET_HOST-}" ]; then
    read -rp "Enter the hostname for this system (e.g., parents-pc or thinkpad-t450): " TARGET_HOST
    export TARGET_HOST
fi

POOL=zroot
ROOT_PARENT="$POOL/ROOT"
ROOT_DATASET="$ROOT_PARENT/$DISTRO_ID"
VARLOG_DATASET="$ROOT_DATASET/var/log"
MNT=/mnt

# 1. Import pool if not already imported
if ! zpool list | grep -q "^$POOL\b"; then
    echo "Importing pool $POOL..."
    sudo zpool import $POOL
fi

# 2. Create zroot/ROOT if it doesn't exist
if ! zfs list "$ROOT_PARENT" >/dev/null 2>&1; then
    echo "Creating parent root dataset $ROOT_PARENT..."
    sudo zfs create -o exec=on -o setuid=on -o devices=on "$ROOT_PARENT"
fi

# 3. Create root dataset if needed
if zfs list "$ROOT_DATASET" >/dev/null 2>&1; then
    echo "Error: Root dataset $ROOT_DATASET already exists."
    read -p "Do you want to DESTROY and RECREATE it? Type YES to confirm: " CONFIRM
    if [[ "$CONFIRM" == "YES" ]]; then
        echo "Destroying existing root dataset $ROOT_DATASET..."
        sudo zfs destroy -r "$ROOT_DATASET"
        echo "Recreating root dataset $ROOT_DATASET..."
        sudo zfs create -o mountpoint=/ -o canmount=noauto "$ROOT_DATASET"
    else
        echo "Exiting without changes."
        exit 1
    fi
else
    echo "Creating root dataset $ROOT_DATASET..."
    sudo zfs create -o mountpoint=/ -o canmount=noauto "$ROOT_DATASET"
fi

# 4. Create /var/log dataset with lz4 compression, legacy mountpoint, and auto-create parents
if zfs list "$VARLOG_DATASET" >/dev/null 2>&1; then
    echo "$VARLOG_DATASET already exists."
else
    echo "Creating $VARLOG_DATASET with compression=lz4, mountpoint=legacy, and creating parents if needed..."
    sudo zfs create -p -o compression=lz4 -o mountpoint=legacy "$VARLOG_DATASET"
fi

# 5. Confirm the root dataset was created successfully
if zfs list "$ROOT_DATASET" >/dev/null 2>&1; then
    echo "Confirmed: Root dataset $ROOT_DATASET exists."
else
    echo "ERROR: Root dataset $ROOT_DATASET does not exist after creation attempt!"
    exit 1
fi

# 5b. Set ZFSBootMenu user properties
echo "Setting ZFSBootMenu properties on $ROOT_DATASET and $ROOT_PARENT..."
sudo zfs set org.zfsbootmenu:bootfs=on "$ROOT_DATASET"
sudo zfs set org.zfsbootmenu:active=on "$ROOT_PARENT"
sudo zfs set org.zfsbootmenu:commandline="quiet" "$ROOT_PARENT"

# 6. Export pool if already imported
if zpool list | grep -q "^$POOL\b"; then
    echo "Exporting pool $POOL..."
    sudo zpool export $POOL
fi

# 7. Ensure /mnt exists
sudo mkdir -p "$MNT"

# 8. Import pool at /mnt
echo "Importing pool $POOL at $MNT..."
sudo zpool import -R "$MNT" $POOL

# 9. Mount root dataset
echo "Mounting root dataset $ROOT_DATASET..."
sudo zfs mount "$ROOT_DATASET"

# 10. Ensure /mnt/var exists before mounting /var/log
sudo mkdir -p "$MNT/var"

# 11. Mount /var/log dataset
echo "Mounting $VARLOG_DATASET to $MNT/var/log..."
sudo mount -t zfs "$VARLOG_DATASET" "$MNT/var/log"

echo "Root dataset and /var/log dataset setup complete."
