#!/bin/bash
#
# Sonic Stick - Quick ISO Repair
# Copies ISOs to stick without rebuilding Ventoy or repartitioning
#
# Usage: sudo bash scripts/repair-isos.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USB="${USB:-/dev/sdb}"

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "repair-isos"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info "Starting ISO repair on $USB"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Banner
clear
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║         SONIC STICK - QUICK ISO REPAIR                    ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${MAGENTA}This will:${NC}"
echo "  1. Mount the SONIC partition"
echo "  2. Copy all ISOs from repo to USB stick"
echo "  3. Copy Ventoy config (if needed)"
echo "  4. Update library catalog"
echo ""
echo -e "${BLUE}This is much faster than a full rebuild!${NC}"
echo ""

# Check if partition exists - detect dynamically
SONIC_PART=$(detect_sonic_partition "$USB")
if [ -z "$SONIC_PART" ]; then
    # Fallback: try ${USB}1
    if [ -b "${USB}1" ]; then
        SONIC_PART="${USB}1"
    elif [ -b "${USB}p1" ]; then
        SONIC_PART="${USB}p1"
    else
        echo -e "${RED}ERROR: SONIC partition not found on $USB${NC}"
        echo "You may need to run a full rebuild instead (option 3)."
        exit 1
    fi
fi

echo -e "${BLUE}Using SONIC partition: $SONIC_PART${NC}"
echo "Target USB device: $USB"
lsblk "$USB" -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
echo ""

read -p "Continue with ISO repair? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${BLUE}Cancelled.${NC}"
    exit 0
fi

# Unmount if already mounted
if mount | grep -q "$SONIC_PART"; then
    echo "Unmounting $SONIC_PART..."
    umount "$SONIC_PART" 2>/dev/null || true
fi

# Mount partition
echo ""
echo -e "${BLUE}Mounting $SONIC_PART...${NC}"
mkdir -p /mnt/sonic
mount "$SONIC_PART" /mnt/sonic || {
    echo -e "${RED}Failed to mount $SONIC_PART${NC}"
    exit 1
}
echo -e "${GREEN}✓ Mounted${NC}"

# Create directory structure if missing
echo ""
echo -e "${BLUE}Ensuring directory structure...${NC}"
mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
mkdir -p /mnt/sonic/RaspberryPi
mkdir -p /mnt/sonic/ventoy
mkdir -p /mnt/sonic/LOGS
echo -e "${GREEN}✓ Directories ready${NC}"

# Copy ISOs with progress
ISO_COUNT=0

echo ""
echo -e "${BLUE}Copying ISOs...${NC}"
echo ""

# Ubuntu ISOs
echo "Copying Ubuntu ISOs..."
if [ -d "$BASE_DIR/ISOS/Ubuntu" ] && ls "$BASE_DIR"/ISOS/Ubuntu/*.iso &>/dev/null; then
    for iso in "$BASE_DIR"/ISOS/Ubuntu/*.iso; do
        filename=$(basename "$iso")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -h --no-perms --progress "$iso" /mnt/sonic/ISOS/Ubuntu/
        elif command -v pv &>/dev/null; then
            pv "$iso" > "/mnt/sonic/ISOS/Ubuntu/$filename"
        else
            cp -v "$iso" /mnt/sonic/ISOS/Ubuntu/
        fi
        ((ISO_COUNT++))
    done
    echo -e "${GREEN}  ✓ Ubuntu ISOs copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No Ubuntu ISOs in repo${NC}"
fi
echo ""

# Minimal ISOs
echo "Copying Minimal ISOs..."
if [ -d "$BASE_DIR/ISOS/Minimal" ] && ls "$BASE_DIR"/ISOS/Minimal/*.iso &>/dev/null; then
    for iso in "$BASE_DIR"/ISOS/Minimal/*.iso; do
        filename=$(basename "$iso")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -h --no-perms --progress "$iso" /mnt/sonic/ISOS/Minimal/
        elif command -v pv &>/dev/null; then
            pv "$iso" > "/mnt/sonic/ISOS/Minimal/$filename"
        else
            cp -v "$iso" /mnt/sonic/ISOS/Minimal/
        fi
        ((ISO_COUNT++))
    done
    echo -e "${GREEN}  ✓ Minimal ISOs copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No Minimal ISOs in repo${NC}"
fi
echo ""

# Rescue ISOs
echo "Copying Rescue ISOs..."
if [ -d "$BASE_DIR/ISOS/Rescue" ] && ls "$BASE_DIR"/ISOS/Rescue/*.iso &>/dev/null; then
    for iso in "$BASE_DIR"/ISOS/Rescue/*.iso; do
        filename=$(basename "$iso")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -h --no-perms --progress "$iso" /mnt/sonic/ISOS/Rescue/
        elif command -v pv &>/dev/null; then
            pv "$iso" > "/mnt/sonic/ISOS/Rescue/$filename"
        else
            cp -v "$iso" /mnt/sonic/ISOS/Rescue/
        fi
        ((ISO_COUNT++))
    done
    echo -e "${GREEN}  ✓ Rescue ISOs copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No Rescue ISOs in repo${NC}"
fi
echo ""

# Raspberry Pi images
echo "Copying Raspberry Pi images..."
if [ -d "$BASE_DIR/RaspberryPi" ] && ls "$BASE_DIR"/RaspberryPi/*.img.xz &>/dev/null; then
    for img in "$BASE_DIR"/RaspberryPi/*.img.xz; do
        filename=$(basename "$img")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -h --no-perms --progress "$img" /mnt/sonic/RaspberryPi/
        elif command -v pv &>/dev/null; then
            pv "$img" > "/mnt/sonic/RaspberryPi/$filename"
        else
            cp -v "$img" /mnt/sonic/RaspberryPi/
        fi
    done
    echo -e "${GREEN}  ✓ RPi images copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No RPi images in repo${NC}"
fi
echo ""

# Copy Ventoy config if missing or user wants to update
if [ ! -f "/mnt/sonic/ventoy/ventoy.json" ]; then
    echo -e "${BLUE}Installing Ventoy config...${NC}"
    if [ -f "$BASE_DIR/config/ventoy/ventoy.json" ]; then
        cp -v "$BASE_DIR/config/ventoy/ventoy.json" /mnt/sonic/ventoy/
        echo -e "${GREEN}✓ Config installed${NC}"
    else
        echo -e "${YELLOW}⚠ Config file not found in repo${NC}"
    fi
else
    echo -e "${BLUE}Ventoy config already exists${NC}"
    read -p "Overwrite with repo version? [y/N]: " update_config
    if [[ "$update_config" =~ ^[Yy]$ ]] && [ -f "$BASE_DIR/config/ventoy/ventoy.json" ]; then
        cp -v "$BASE_DIR/config/ventoy/ventoy.json" /mnt/sonic/ventoy/
        echo -e "${GREEN}✓ Config updated${NC}"
    fi
fi

# Update catalog if FLASH partition exists
if [ -b "${USB}3" ]; then
    echo ""
    echo -e "${BLUE}Updating library catalog on FLASH partition...${NC}"
    mkdir -p /mnt/sonic-data
    if mount "${USB}3" /mnt/sonic-data 2>/dev/null; then
        mkdir -p /mnt/sonic-data/library
        cat > /mnt/sonic-data/library/iso-catalog.json << EOF
{
  "last_updated": "$(date -Iseconds)",
  "total_isos": $ISO_COUNT,
  "auto_scan": true,
  "repaired": true,
  "repair_date": "$(date -Iseconds)"
}
EOF
        sync
        umount /mnt/sonic-data
        echo -e "${GREEN}✓ Catalog updated${NC}"
    else
        echo -e "${YELLOW}⚠ Could not mount FLASH partition${NC}"
    fi
fi

# Verify ISOs
echo ""
echo -e "${BLUE}Verifying ISOs on stick...${NC}"
STICK_ISO_COUNT=$(find /mnt/sonic/ISOS -name "*.iso" 2>/dev/null | wc -l)
echo -e "${GREEN}  Found: $STICK_ISO_COUNT ISOs${NC}"
if [ $STICK_ISO_COUNT -gt 0 ]; then
    find /mnt/sonic/ISOS -name "*.iso" -exec basename {} \; | sort | sed 's/^/    • /'
fi

# Unmount
sync
umount /mnt/sonic
rmdir /mnt/sonic 2>/dev/null || true

# Success
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              REPAIR COMPLETE - ISOs READY!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ $STICK_ISO_COUNT ISOs now on stick${NC}"
echo ""
echo "Your Sonic Stick should now boot properly with all ISOs available."
echo ""

log_info "Repair completed successfully - $STICK_ISO_COUNT ISOs installed"
