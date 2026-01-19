#!/bin/bash
#
# Quick relabel script - changes partition label from "Ventoy" to "SONIC"
# Usage: sudo bash scripts/relabel-sonic.sh
#

set -euo pipefail

USB="${USB:-/dev/sdb}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Sonic Stick - Relabel Partition${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

if [[ ! -b "$USB" ]]; then
    echo -e "${RED}Device $USB not found${NC}"
    exit 1
fi

echo "Current partitions:"
lsblk -o NAME,SIZE,FSTYPE,LABEL "$USB"
echo ""

# Check if partition is mounted
MOUNT_POINT=$(findmnt -n -o TARGET "${USB}1" 2>/dev/null || true)
if [[ -n "$MOUNT_POINT" ]]; then
    echo -e "${YELLOW}Partition is mounted at: $MOUNT_POINT${NC}"
    echo "Unmounting..."
    umount "${USB}1" || {
        echo -e "${RED}Failed to unmount. Please unmount manually and try again.${NC}"
        exit 1
    }
fi

# Check for exfatlabel
if ! command -v exfatlabel &>/dev/null; then
    echo -e "${RED}Error: exfatlabel not found${NC}"
    echo ""
    echo "Install exfatprogs:"
    echo "  Ubuntu/Debian: sudo apt install exfatprogs"
    echo "  Fedora: sudo dnf install exfatprogs"
    echo "  Arch: sudo pacman -S exfatprogs"
    exit 1
fi

# Relabel
echo -e "${BLUE}Relabeling $SONIC_PART from 'Ventoy' to 'SONIC'...${NC}"
exfatlabel "$SONIC_PART" "SONIC" || {
    echo -e "${RED}Failed to relabel partition${NC}"
    exit 1
}

echo -e "${GREEN}✓ Partition relabeled successfully!${NC}"
echo ""
echo "New partition layout:"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$USB"
echo ""
echo -e "${GREEN}Done! Your partition is now labeled 'SONIC'${NC}"
echo ""
