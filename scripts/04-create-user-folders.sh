#!/bin/bash
set -e

# --- For jj and leah ---
for user in jj leah; do
    home="/home/$user"
    # Create folders
    mkdir -p "$home/Media/Pictures" "$home/Media/Music" "$home/Media/Videos"
    mkdir -p "$home/.var/lib"
done

# --- For jj only ---
mkdir -p /home/jj/Vaults/Nexus/Projects
mkdir -p /home/jj/Vaults/Nexus/Resources

# --- For leah only ---
mkdir -p /home/leah/Documents/Templates

# --- For Shared ---
mkdir -p /home/Shared/Documents

# --- Symlinks for jj and leah ---
for user in jj leah; do
    ln -sf /home/Shared "$home/Shared"
done

# --- Symlinks for jj only ---
ln -sf /home/jj/Vaults/Nexus/Inbox /home/jj/Documents
ln -sf /home/jj/Vaults/Nexus/Projects /home/jj/Projects
ln -sf /home/jj/Vaults/Nexus/Resources /home/jj/Resources

echo "Folders and symlinks created."
