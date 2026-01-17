#!/bin/bash
#
# Sonic Stick Complete Reflash Workflow
# Installs Ventoy, copies ISOs, and guides partitioning
#
# Usage: sudo bash scripts/reflash-complete.sh
#

set -e

USB="/dev/sdb"  # Edit this to your USB device

# Confirm setup
echo "=========================================="
echo "Sonic Stick Complete Reflash Workflow"
echo "=========================================="
echo "Target USB: $USB"
echo ""
lsblk "$USB" 2>/dev/null | head -10
echo ""
read -p "Type 'ERASE' to continue: " confirm
if [[ "$confirm" != "ERASE" ]]; then
  echo "Cancelled."
  exit 0
fi

# Step 1: Install Ventoy
echo ""
echo "[Step 1/4] Installing Ventoy..."
sudo bash scripts/install-ventoy.sh
sleep 2

# Step 2: Mount and copy ISOs
echo ""
echo "[Step 2/4] Copying ISOs to USB..."
sudo mkdir -p /mnt/sonic
if sudo mount "${USB}2" /mnt/sonic; then
  echo "Mounted ${USB}2 at /mnt/sonic"
  
  # Create ISO directories
  sudo mkdir -p /mnt/sonic/{ISOS,RaspberryPi,LOGS}
  
  # Copy payloads
  if [[ -d "ISOS" ]]; then
    echo "Copying ISOS..."
    sudo cp -rv ISOS/* /mnt/sonic/ISOS/ 2>/dev/null | tail -3
  fi
  
  if [[ -d "RaspberryPi" ]]; then
    echo "Copying RaspberryPi images..."
    sudo cp -rv RaspberryPi/* /mnt/sonic/RaspberryPi/ 2>/dev/null | tail -3
  fi
  
  sudo umount /mnt/sonic
  echo "Unmounted USB"
else
  echo "ERROR: Failed to mount ${USB}2"
  exit 1
fi

# Step 3: Boot test
echo ""
echo "[Step 3/4] Boot test (optional)"
read -p "Insert USB and reboot to test Ventoy menu? (y/n): " boottest
if [[ "$boottest" == "y" ]]; then
  echo "1. Reboot your machine"
  echo "2. Press F12 or ESC at startup to select USB boot"
  echo "3. Verify Ventoy menu appears with ISOs"
  echo "4. Test booting TinyCore and Ubuntu installer"
  read -p "Press Enter when done with boot test..."
fi

# Step 4: Partitioning with GParted
echo ""
echo "[Step 4/4] Partitioning USB (GParted)"
echo ""
echo "You will now partition the USB stick:"
echo "  1. Shrink exFAT from ~114GB to ~82GB"
echo "  2. Create ext4 partition (16GB, label: TCE)"
echo "  3. Create linux-swap (8GB, label: SONIC_SWAP)"
echo "  4. Create ext4 partition (2GB, label: DONGLE)"
echo ""
read -p "Start GParted? (y/n): " gparted
if [[ "$gparted" == "y" ]]; then
  if command -v gparted &> /dev/null; then
    sudo gparted "$USB" &
  else
    echo "GParted not installed. Install with: sudo apt install gparted"
    exit 1
  fi
fi

echo ""
echo "=========================================="
echo "Reflash workflow complete!"
echo "=========================================="
echo ""
echo "After GParted:"
echo "  sudo lsblk $USB"
echo "  # Verify all 5 partitions exist"
echo ""
echo "Mount DONGLE partition (optional):"
echo "  sudo mkdir -p /mnt/dongle"
echo "  sudo mount ${USB}5 /mnt/dongle"
echo "  # Store SSH keys, GPG certs, BIOS backups"
echo ""
