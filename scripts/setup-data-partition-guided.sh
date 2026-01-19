#!/bin/bash
#
# Quick setup: Shrink Ventoy partition and create data partition
# This uses GParted for safety
#
# Usage: sudo bash scripts/setup-data-partition-guided.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "setup-data-partition-guided"
exec > >(tee -a "$LOG_FILE") 2>&1

USB="/dev/sdb"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info "Launching guided data partition setup for $USB"

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Sonic Stick - Setup Data Partition${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "Current layout:"
lsblk "$USB" -o NAME,SIZE,FSTYPE,LABEL
echo ""
echo -e "${YELLOW}What we'll do:${NC}"
echo "1. Shrink ${USB}1 (Ventoy exFAT) to ~110GB"
echo "2. Create ${USB}3 (FLASH ext4) with remaining space (~4GB)"
echo ""
echo -e "${BLUE}This requires GParted (graphical tool)${NC}"
echo ""

# Check if GParted is installed
if ! command -v gparted &> /dev/null; then
    echo -e "${YELLOW}GParted not found. Installing...${NC}"
    sudo apt update && sudo apt install -y gparted
fi

echo "Steps to follow in GParted:"
echo ""
echo -e "${GREEN}1. Right-click ${USB}1 → Resize/Move${NC}"
echo "   • New size: 110000 MiB (~107 GB)"
echo "   • Free space following: ~4000 MiB"
echo "   • Click Resize/Move"
echo ""
echo -e "${GREEN}2. Right-click unallocated space → New${NC}"
echo "   • File system: ext4"
echo "   • Label: FLASH"
echo "   • Click Add"
echo ""
echo -e "${GREEN}3. Click the green checkmark (Apply All Operations)${NC}"
echo "   • Wait for completion (may take 2-5 minutes)"
echo ""
echo -e "${YELLOW}4. When done, close GParted${NC}"
echo ""

read -p "Ready to launch GParted? (y/n): " launch
if [[ "$launch" == "y" ]]; then
    sudo gparted "$USB" &
    echo ""
    echo -e "${BLUE}GParted launched. Follow the steps above.${NC}"
    echo ""
    read -p "Press Enter when you've completed the steps in GParted..."
    
    echo ""
    echo -e "${GREEN}Verifying new partition...${NC}"
    sleep 2
    lsblk "$USB" -o NAME,SIZE,FSTYPE,LABEL
    echo ""
    
    # Check if partition 3 exists
    if [ -b "${USB}3" ]; then
        echo -e "${GREEN}✓ ${USB}3 found!${NC}"
        echo ""
        echo "Initializing FLASH..."
        
        sudo mkdir -p /mnt/sonic-data
        sudo mount "${USB}3" /mnt/sonic-data
        
        # Create directory structure
        sudo mkdir -p /mnt/sonic-data/{logs,sessions,library,devices,config}
        
        # Create initial files
        cat | sudo tee /mnt/sonic-data/library/iso-catalog.json > /dev/null << EOF
{
  "last_updated": "$(date -Iseconds)",
  "available_isos": [],
  "scan_on_boot": true
}
EOF
        
        cat | sudo tee /mnt/sonic-data/config/sonic-stick.conf > /dev/null << EOF
# Sonic Stick Configuration
STICK_NAME="SONIC"
DATA_VERSION="1.0"
CREATED="$(date -Iseconds)"
AUTO_SCAN=true
EOF
        
        cat | sudo tee /mnt/sonic-data/README.txt > /dev/null << EOF
╔══════════════════════════════════════════════════════════════╗
║              SONIC STICK - DATA PARTITION                    ║
╚══════════════════════════════════════════════════════════════╝

This partition stores:
  • logs/       - Boot logs and system messages
  • sessions/   - Session data from live boots
  • library/    - ISO catalog and installation tracking
  • devices/    - Hardware detection logs
  • config/     - Sonic Stick configuration

Label: FLASH
Filesystem: ext4
Created: $(date)
EOF
        
        sudo chmod -R 755 /mnt/sonic-data
        
        echo -e "${GREEN}✓ FLASH initialized${NC}"
        echo ""
        echo "Contents:"
        ls -la /mnt/sonic-data/
        
        sudo umount /mnt/sonic-data
        echo ""
        echo -e "${GREEN}✓ Setup complete!${NC}"
    else
        echo -e "${RED}✗ Partition ${USB}3 not found${NC}"
        echo "Please verify you created it in GParted"
    fi
else
    echo "Skipped. Run this script again when ready."
fi

echo ""
echo -e "${BLUE}Final layout:${NC}"
lsblk "$USB" -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
