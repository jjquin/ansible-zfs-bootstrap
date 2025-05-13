#!/bin/bash
set -e

BIG_WARNING="
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! WARNING: THIS WILL DESTROY ALL DATA ON THE SELECTED DRIVE(S) !!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"

# --- Step 1: Check for existing zroot pool ---
if zpool list | grep -q '^zroot\b'; then
    echo "$BIG_WARNING"
    echo "zroot pool already exists."
    read -p "Do you want to OVERWRITE zroot and WIPE the drives? (y/N): " OVERWRITE
    [[ ! "$OVERWRITE" =~ ^[Yy]$ ]] && { echo "Exiting."; exit 0; }
    sudo zpool export zroot
else
    echo "$BIG_WARNING"
    echo "No existing zroot pool found."
    read -p "Do you want to CREATE a new zroot and WIPE the drives? (y/N): " CREATE
    [[ ! "$CREATE" =~ ^[Yy]$ ]] && { echo "Exiting."; exit 0; }
fi

# --- Step 2: Set drives based on TARGET_HOST or prompt ---
DRIVE1=""
DRIVE2=""

if [[ "${TARGET_HOST-}" == "parents-pc" ]]; then
    DRIVE1="/dev/disk/by-id/nvme-Sabrent_Rocket_4.0_1TB_038507081B5D88262037"
    DRIVE2="/dev/disk/by-id/nvme-Sabrent_Rocket_4.0_1TB_6D12070C05A292162211"
elif [[ "${TARGET_HOST-}" == "thinkpad-t450" ]]; then
    DRIVE1=$(ls /dev/disk/by-id | grep -i samsung | grep -v part | head -n1)
    DRIVE1="/dev/disk/by-id/$DRIVE1"
    DRIVE2=""
fi

# If DRIVE1 is still blank, prompt for layout and drive selection
if [[ -z "$DRIVE1" ]]; then
    mapfile -t drives < <(ls /dev/disk/by-id | grep -Ev 'part|loop|_1$|_1-part')
    PS3="Is this a single drive or a mirror? "
    select layout in "Single Drive" "Mirror (2 drives)"; do
        [[ $REPLY == 1 || $REPLY == 2 ]] && break
    done
    if [[ $REPLY == 1 ]]; then
        echo "Select the drive for the pool:"
        select d in "${drives[@]}"; do
            DRIVE1="/dev/disk/by-id/$d"
            break
        done
        DRIVE2=""
    else
        echo "Select the FIRST drive for the mirror:"
        select d1 in "${drives[@]}"; do
            DRIVE1="/dev/disk/by-id/$d1"
            break
        done
        echo "Select the SECOND drive for the mirror:"
        select d2 in "${drives[@]}"; do
            [[ "$d2" != "$d1" ]] && DRIVE2="/dev/disk/by-id/$d2" && break
        done
    fi
fi

echo "$BIG_WARNING"
echo "The following drive(s) will be COMPLETELY WIPED:"
echo "$DRIVE1"
[[ -n "$DRIVE2" ]] && echo "$DRIVE2"
read -p "Are you ABSOLUTELY SURE you want to wipe these drives? (type YES to continue): " FINAL_CONFIRM
[[ "$FINAL_CONFIRM" != "YES" ]] && { echo "Exiting."; exit 0; }

# --- Step 3: Wipe drives ---
wipe_drive() {
    local disk="$1"
    echo "Wiping disk $disk"
    sudo wipefs -a "$disk"
    sudo sgdisk --zap-all "$disk"
    sudo zpool labelclear -f "$disk" || true
}
wipe_drive "$DRIVE1"
[[ -n "$DRIVE2" ]] && wipe_drive "$DRIVE2"

# --- Step 4: Build zpool create command ---
ZPOOL_CMD=(zpool create -f
  -o ashift=12
  -O encryption=aes-256-gcm
  -O keylocation=prompt
  -O keyformat=passphrase
  -O atime=off
  -O xattr=sa
  -O acltype=posixacl
  -O checksum=blake3
  -O mountpoint=none
  -O dnodesize=auto
  -O normalization=formD
  -O devices=off
  -O exec=off
  -O setuid=off
  -O autotrim=on
  -O compression=lz4
  zroot
)
if [[ -n "$DRIVE2" ]]; then
    ZPOOL_CMD+=(mirror "$DRIVE1" "$DRIVE2")
else
    ZPOOL_CMD+=("$DRIVE1")
fi

echo "About to run: ${ZPOOL_CMD[*]}"
read -p "Proceed with zpool creation? (y/n): " CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { echo "Exiting before pool creation."; exit 0; }

"${ZPOOL_CMD[@]}"
