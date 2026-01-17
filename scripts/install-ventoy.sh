#!/bin/bash
#
# Sonic Stick Ventoy Installer/Upgrader
# Installs or upgrades Ventoy on a USB stick
#
# Usage: sudo bash scripts/install-ventoy.sh
# Set USB=/dev/sdX and MODE=install or MODE=upgrade
#

set -e

# Edit these for your system
USB="/dev/sdb"              # USB device (e.g., /dev/sdb, NOT /dev/sdb1)
VENTOY_VER="1.0.98"        # Ventoy version to use
MODE="install"              # install or upgrade
VENTOY_TAR="TOOLS/ventoy-${VENTOY_VER}-linux.tar.gz"

# Safety check
if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Must run with sudo"
  exit 1
fi

if [[ ! "$USB" =~ ^/dev/sd[a-z]$ ]]; then
  echo "ERROR: USB must be /dev/sdX (not /dev/sdX1)"
  exit 1
fi

if [[ ! -e "$USB" ]]; then
  echo "ERROR: USB device $USB not found"
  exit 1
fi

# Confirm before erasing
echo "=========================================="
echo "Ventoy Installer - $MODE mode"
echo "=========================================="
echo "Target USB: $USB"
echo "Ventoy version: $VENTOY_VER"
echo ""
lsblk "$USB" 2>/dev/null || fdisk -l "$USB" | head -5
echo ""
read -p "Type 'ERASE' to proceed with $MODE: " confirm
if [[ "$confirm" != "ERASE" ]]; then
  echo "Cancelled."
  exit 0
fi

# Unmount all partitions
echo "Unmounting partitions..."
for partition in "${USB}"*; do
  if [[ "$partition" != "$USB" ]]; then
    if mountpoint -q "$partition" 2>/dev/null; then
      umount "$partition" || true
    fi
  fi
done

# Extract and run Ventoy
echo "Extracting Ventoy $VENTOY_VER..."
cd "$(dirname "$VENTOY_TAR")"
tar -xzf "$(basename "$VENTOY_TAR")"
VENTOY_DIR="ventoy-${VENTOY_VER}"

if [[ ! -d "$VENTOY_DIR" ]]; then
  echo "ERROR: Failed to extract Ventoy"
  exit 1
fi

cd "$VENTOY_DIR"

# Run installer
echo "Running Ventoy installer..."
if [[ "$MODE" == "install" ]]; then
  bash Ventoy2Disk.sh -i "$USB" || { echo "Install failed"; exit 1; }
elif [[ "$MODE" == "upgrade" ]]; then
  bash Ventoy2Disk.sh -u "$USB" || { echo "Upgrade failed"; exit 1; }
fi

echo ""
echo "=========================================="
echo "Ventoy installed successfully!"
echo "=========================================="
echo ""
echo "Mount data partition and copy ISOs:"
echo "  sudo mkdir -p /mnt/sonic"
echo "  sudo mount ${USB}2 /mnt/sonic"
echo "  sudo cp -r ../ISOS/* /mnt/sonic/ISOS/"
echo "  sudo cp -r ../RaspberryPi/* /mnt/sonic/RaspberryPi/"
echo "  sudo umount /mnt/sonic"
echo ""
