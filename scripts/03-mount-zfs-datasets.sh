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

POOL=zroot
ROOT_PARENT="$POOL/ROOT"
ROOT_DATASET="$ROOT_PARENT/$DISTRO_ID"
MNT=/mnt

# 1. Import pool if not already imported
if ! zpool list | grep -q "^$POOL\b"; then
    echo "Importing pool $POOL..."
    sudo zpool import $POOL
fi

# 2. Create zroot/ROOT if it doesn't exist (must be done before distro-specific root)
if ! zfs list "$ROOT_PARENT" >/dev/null 2>&1; then
    echo "Creating parent root dataset $ROOT_PARENT..."
    sudo zfs create -o exec=on -o setuid=on -o devices=on "$ROOT_PARENT"
fi

# 3. Check if root dataset for the distro exists
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

# 4. Confirm the root dataset was created successfully
if zfs list "$ROOT_DATASET" >/dev/null 2>&1; then
    echo "Confirmed: Root dataset $ROOT_DATASET exists."
else
    echo "ERROR: Root dataset $ROOT_DATASET does not exist after creation attempt!"
    exit 1
fi

# 5. Export pool if already imported
if zpool list | grep -q "^$POOL\b"; then
    echo "Exporting pool $POOL..."
    sudo zpool export $POOL
fi

# 6. Ensure /mnt exists
sudo mkdir -p "$MNT"

# 7. Import pool at /mnt
echo "Importing pool $POOL at $MNT..."
sudo zpool import -R "$MNT" $POOL

# 8. Mount root dataset
echo "Mounting root dataset $ROOT_DATASET..."
sudo zfs mount "$ROOT_DATASET"

echo "Root dataset setup complete."
