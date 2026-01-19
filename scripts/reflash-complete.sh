#!/bin/bash
#
# Sonic Stick Complete Reflash Workflow
# Installs Ventoy, copies ISOs, configures custom menu, and creates data partition
#
# Usage: sudo bash scripts/reflash-complete.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USB="${USB:-/dev/sdb}"  # Edit this to your USB device or set USB=/dev/sdX

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "reflash-complete"
exec > >(tee -a "$LOG_FILE") 2>&1

log_info "Starting Sonic Stick reflash for $USB"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Confirm setup
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}Sonic Stick Complete Reflash Workflow${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Target USB: $USB"
echo ""
lsblk "$USB" 2>/dev/null | head -10
echo ""
echo -e "${RED}WARNING: This will ERASE all data on $USB${NC}"
read -p "Type 'ERASE' to continue: " confirm
if [[ "$confirm" != "ERASE" ]]; then
  echo "Cancelled."
  exit 0
fi

# Step 1: Install Ventoy
echo ""
echo -e "${BLUE}[Step 1/5] Installing Ventoy...${NC}"
sudo bash "$BASE_DIR/scripts/install-ventoy.sh"
sleep 2

# Step 2: Mount and copy ISOs + custom config
echo ""
echo -e "${BLUE}[Step 2/5] Copying ISOs and config to USB...${NC}"
sudo mkdir -p /mnt/sonic
if sudo mount "${USB}1" /mnt/sonic; then
  echo "Mounted ${USB}1 at /mnt/sonic"
  
  # Create ISO directories
  sudo mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
  sudo mkdir -p /mnt/sonic/RaspberryPi
  sudo mkdir -p /mnt/sonic/ventoy
  sudo mkdir -p /mnt/sonic/LOGS
  
  # Copy payloads
  if [[ -d "$BASE_DIR/ISOS/Ubuntu" ]]; then
    echo "Copying Ubuntu ISOs..."
    sudo cp -v "$BASE_DIR"/ISOS/Ubuntu/*.iso /mnt/sonic/ISOS/Ubuntu/ 2>/dev/null || echo "  (No Ubuntu ISOs found)"
  fi
  
  if [[ -d "$BASE_DIR/ISOS/Minimal" ]]; then
    echo "Copying Minimal ISOs..."
    sudo cp -v "$BASE_DIR"/ISOS/Minimal/*.iso /mnt/sonic/ISOS/Minimal/ 2>/dev/null || echo "  (No Minimal ISOs found)"
  fi
  
  if [[ -d "$BASE_DIR/ISOS/Rescue" ]]; then
    echo "Copying Rescue ISOs..."
    sudo cp -v "$BASE_DIR"/ISOS/Rescue/*.iso /mnt/sonic/ISOS/Rescue/ 2>/dev/null || echo "  (No Rescue ISOs found)"
  fi
  
  if [[ -d "$BASE_DIR/RaspberryPi" ]]; then
    echo "Copying RaspberryPi images..."
    sudo cp -v "$BASE_DIR"/RaspberryPi/*.img.xz /mnt/sonic/RaspberryPi/ 2>/dev/null || echo "  (No RPi images found)"
  fi
  
  # Copy custom Ventoy configuration
  if [[ -f "$BASE_DIR/config/ventoy/ventoy.json" ]]; then
    echo -e "${GREEN}Installing custom Ventoy menu...${NC}"
    mkdir -p /mnt/sonic/ventoy
    
    # Validate JSON syntax before copying
    if python3 -m json.tool "$BASE_DIR/config/ventoy/ventoy.json" >/dev/null 2>&1; then
      cp -v "$BASE_DIR/config/ventoy/ventoy.json" /mnt/sonic/ventoy/
      echo -e "${GREEN}✓ ventoy.json is valid${NC}"
    else
      echo -e "${YELLOW}⚠ ventoy.json has syntax errors, using example instead${NC}"
      cp -v "$BASE_DIR/config/ventoy/ventoy.json.example" /mnt/sonic/ventoy/ventoy.json
    fi
  else
    echo -e "${YELLOW}ventoy.json not found, using example${NC}"
    mkdir -p /mnt/sonic/ventoy
    cp -v "$BASE_DIR/config/ventoy/ventoy.json.example" /mnt/sonic/ventoy/ventoy.json
  fi
  
  sudo umount /mnt/sonic
  echo "Unmounted USB"
else
  echo -e "${RED}ERROR: Failed to mount ${USB}1${NC}"
  exit 1
fi


# Step 3: Create data partition
echo ""
echo -e "${BLUE}[Step 3/5] Creating FLASH partition...${NC}"
echo "This partition will store logs, session data, and library tracking"
sleep 1

if bash "$BASE_DIR/scripts/create-data-partition.sh" "$USB"; then
  echo -e "${GREEN}✓ Data partition created${NC}"
else
  echo -e "${YELLOW}⚠ Data partition creation failed (may already exist)${NC}"
fi

# Step 4: Initialize library catalog
echo ""
echo -e "${BLUE}[Step 4/5] Initializing library catalog...${NC}"
sudo mkdir -p /mnt/sonic-data
if sudo mount "${USB}3" /mnt/sonic-data 2>/dev/null; then
  echo "Running library scan..."
  sudo mount "${USB}1" /mnt/sonic 2>/dev/null || true
  bash "$BASE_DIR/scripts/scan-library.sh" /mnt/sonic-data /mnt/sonic || echo "Scan will run on first boot"
  sudo umount /mnt/sonic 2>/dev/null || true
  sudo umount /mnt/sonic-data
  echo -e "${GREEN}✓ Library initialized${NC}"
else
  echo -e "${YELLOW}⚠ Data partition not yet created${NC}"
fi

# Step 5: Boot test
echo ""
echo -e "${BLUE}[Step 5/5] Verifying USB configuration...${NC}"

mkdir -p /mnt/sonic-verify
if mount "${USB}1" /mnt/sonic-verify 2>/dev/null; then
  echo "Checking ventoy.json..."
  if [[ -f /mnt/sonic-verify/ventoy/ventoy.json ]]; then
    if python3 -m json.tool /mnt/sonic-verify/ventoy/ventoy.json >/dev/null 2>&1; then
      echo -e "${GREEN}✓ ventoy.json is valid${NC}"
    else
      echo -e "${RED}✗ ventoy.json has syntax errors!${NC}"
      echo "  Run: sudo bash scripts/fix-ventoy-stick.sh"
    fi
  else
    echo -e "${YELLOW}⚠ ventoy.json not found on USB${NC}"
  fi
  umount /mnt/sonic-verify 2>/dev/null || true
fi

# Step 6: Boot test (was step 5)
echo ""
echo -e "${BLUE}[Step 6/6] Ready for boot test${NC}"
read -p "Reboot to test Ventoy menu? (y/n): " boottest
if [[ "$boottest" == "y" ]]; then
  echo ""
  echo -e "${GREEN}Boot Test Instructions:${NC}"
  echo "1. Reboot your machine"
  echo "2. Press F12 or ESC at startup to select USB boot"
  echo "3. You should see the custom Ventoy menu with:"
  echo "   • Ubuntu 22.04.5 LTS Desktop"
  echo "   • Lubuntu 22.04.5 LTS"
  echo "   • Ubuntu MATE 22.04.5 LTS"
  echo "   • Alpine Linux 3.19.1"
  echo "   • TinyCore Pure64 15.0"
  echo ""
  echo -e "${YELLOW}Tips:${NC}"
  echo "   • ISOs marked 'installer+live' can run without installing"
  echo "   • Use arrow keys to navigate the menu"
  echo "   • Press ESC to return to previous menu"
  echo ""
  read -p "Press Enter when done with boot test..."
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Reflash workflow complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "USB Stick Configuration:"
lsblk "$USB" -o NAME,SIZE,FSTYPE,LABEL
echo ""
echo -e "${BLUE}What you can do now:${NC}"
echo "  1. Boot from USB - Custom menu with all ISOs"
echo "  2. View library - bash scripts/scan-library.sh"
echo "  3. Check logs - mount FLASH partition"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  • No menu items? - Remount USB and check /mnt/sonic/ISOS/"
echo "  • Boot fails? - Check BIOS boot order (USB first)"
echo "  • Missing ISOs? - Run: bash scripts/download-payloads.sh"
echo ""

