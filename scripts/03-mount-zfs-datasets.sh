#!/bin/bash
set -e

# Make sure DISTRO_ID is set, e.g., export DISTRO_ID=manjaro
: "${DISTRO_ID:?DISTRO_ID must be set (e.g., manjaro)}"

POOL=zroot
ROOT_DATASET="$POOL/ROOT/$DISTRO_ID"
MNT=/mnt

# 1. Import pool if not already imported
if ! zpool list | grep -q "^$POOL\b"; then
    echo "Importing pool $POOL..."
    sudo zpool import $POOL
fi

# 2. Create root dataset for the distro if it doesn't exist
if ! zfs list "$ROOT_DATASET" >/dev/null 2>&1; then
    echo "Creating root dataset $ROOT_DATASET..."
    sudo zfs create -o mountpoint=/ -o canmount=noauto "$ROOT_DATASET"
fi

# 3. Export pool if already imported
if zpool list | grep -q "^$POOL\b"; then
    echo "Exporting pool $POOL..."
    sudo zpool export $POOL
fi

# 4. Ensure /mnt exists
sudo mkdir -p "$MNT"

# 5. Import pool at /mnt
echo "Importing pool $POOL at $MNT..."
sudo zpool import -R "$MNT" $POOL

# 6. Mount root dataset
echo "Mounting root dataset $ROOT_DATASET..."
sudo zfs mount "$ROOT_DATASET"

# 7. Create all necessary parent directories under /mnt
PARENT_DIRS=(
    "$MNT/home/jj"
    "$MNT/home/leah"
    "$MNT/var/lib"
)
for dir in "${PARENT_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating parent directory: $dir"
        sudo mkdir -p "$dir"
    else
        echo "Parent directory already exists: $dir"
    fi
done

# 8. Mount all remaining datasets (ZFS will create child mountpoints as needed)
echo "Mounting all datasets..."
sudo zfs mount -a

echo "All datasets mounted under $MNT."
sudo zfs list -r -o name,mountpoint $POOL
