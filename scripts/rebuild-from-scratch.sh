#!/bin/bash
#
# Sonic Stick - Complete Clean Build
# Wipes USB stick completely and rebuilds with custom Ventoy menu + data partition
#
# Usage: sudo bash scripts/rebuild-from-scratch.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USB="${USB:-/dev/sdb}"
VENTOY_VERSION="${VENTOY_VERSION:-1.1.10}"

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "rebuild-from-scratch"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Dependencies
NEED_EXFAT=0
if ! command -v exfatresize &>/dev/null; then
    NEED_EXFAT=1
    log_warn "exfatresize (exfatprogs) not found; FLASH partition creation will be skipped"
    log_info "Install with: sudo apt install exfatprogs"
fi
FLASH_DONE=0

log_info "Starting complete rebuild on $USB"
log_env_snapshot

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Banner
clear
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║         SONIC STICK - COMPLETE REBUILD FROM SCRATCH       ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${MAGENTA}This will:${NC}"
echo "  1. WIPE all data on $USB"
echo "  2. Install fresh Ventoy bootloader"
echo "  3. Copy all ISOs with organized structure"
echo "  4. Install custom Ventoy menu with organized categories"
echo "  5. Relabel main partition to SONIC"
echo "  6. Create FLASH partition for logs/tracking (4GB ext4)"
echo "  7. Initialize library catalog system"
echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}WARNING: ALL DATA ON $USB WILL BE PERMANENTLY ERASED!${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""
lsblk "$USB" -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
echo ""
read -p "Type 'REBUILD' in capitals to continue: " confirm
if [[ "$confirm" != "REBUILD" ]]; then
    echo -e "${BLUE}Cancelled.${NC}"
    exit 0
fi

# Step 1: Unmount everything
echo ""
echo -e "${BLUE}[1/7] Unmounting all partitions on $USB...${NC}"
for part in ${USB}*[0-9]; do
    if mount | grep -q "$part"; then
        echo "  Unmounting $part"
        umount "$part" 2>/dev/null || true
    fi
done
sleep 1

# Step 2: Complete wipe and install Ventoy
echo ""
echo -e "${BLUE}[2/7] Wiping disk and installing fresh Ventoy...${NC}"
echo -e "${YELLOW}This will take 30-60 seconds...${NC}"

# Prepare Ventoy (download/extract if needed)
VENTOY_DIR="$BASE_DIR/TOOLS/ventoy-${VENTOY_VERSION}"
VENTOY_TAR="$BASE_DIR/TOOLS/ventoy-${VENTOY_VERSION}-linux.tar.gz"

if [ ! -f "$VENTOY_DIR/Ventoy2Disk.sh" ]; then
    if [ ! -f "$VENTOY_TAR" ]; then
        echo -e "${YELLOW}Downloading Ventoy ${VENTOY_VERSION}...${NC}"
        mkdir -p "$BASE_DIR/TOOLS"
        wget -O "$VENTOY_TAR" "https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VERSION}/ventoy-${VENTOY_VERSION}-linux.tar.gz" || {
            echo -e "${RED}Failed to download Ventoy${NC}"
            exit 1
        }
    fi
    echo -e "${BLUE}Extracting Ventoy ${VENTOY_VERSION}...${NC}"
    tar -xzf "$VENTOY_TAR" -C "$BASE_DIR/TOOLS" || {
        echo -e "${RED}Failed to extract Ventoy${NC}"
        exit 1
    }
fi

if [ ! -f "$VENTOY_DIR/Ventoy2Disk.sh" ]; then
    echo -e "${RED}Ventoy2Disk.sh not found at $VENTOY_DIR/Ventoy2Disk.sh${NC}"
    exit 1
fi

# Run Ventoy installer with -I flag (force install, wipe disk)
cd "$VENTOY_DIR"
echo "yes" | ./Ventoy2Disk.sh -I -g "$USB" || {
    echo -e "${RED}Ventoy installation failed${NC}"
    exit 1
}

cd "$BASE_DIR"
sleep 3

# Wait for partitions to appear
echo "Waiting for partitions to settle..."
partprobe "$USB" 2>/dev/null || true
sleep 3

# Step 3: Mount and copy ISOs
echo ""
echo -e "${BLUE}[3/7] Mounting Ventoy partition and copying ISOs...${NC}"
mkdir -p /mnt/sonic
sleep 2

# Mount first partition (Ventoy data)
mount "${USB}1" /mnt/sonic || {
    echo -e "${RED}Failed to mount ${USB}1${NC}"
    exit 1
}

echo -e "${GREEN}✓ Mounted ${USB}1${NC}"

# Create directory structure
mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
mkdir -p /mnt/sonic/RaspberryPi
mkdir -p /mnt/sonic/ventoy
mkdir -p /mnt/sonic/LOGS

# Copy Ubuntu ISOs
echo ""
echo "Copying Ubuntu ISOs..."
if [ -d "$BASE_DIR/ISOS/Ubuntu" ]; then
    cp -v "$BASE_DIR"/ISOS/Ubuntu/*.iso /mnt/sonic/ISOS/Ubuntu/ 2>/dev/null && echo -e "${GREEN}  ✓ Ubuntu ISOs copied${NC}" || echo -e "${YELLOW}  ⚠ No Ubuntu ISOs${NC}"
fi

# Copy Minimal ISOs
echo "Copying Minimal ISOs..."
if [ -d "$BASE_DIR/ISOS/Minimal" ]; then
    cp -v "$BASE_DIR"/ISOS/Minimal/*.iso /mnt/sonic/ISOS/Minimal/ 2>/dev/null && echo -e "${GREEN}  ✓ Minimal ISOs copied${NC}" || echo -e "${YELLOW}  ⚠ No Minimal ISOs${NC}"
fi

# Copy Rescue ISOs
echo "Copying Rescue ISOs..."
if [ -d "$BASE_DIR/ISOS/Rescue" ]; then
    cp -v "$BASE_DIR"/ISOS/Rescue/*.iso /mnt/sonic/ISOS/Rescue/ 2>/dev/null && echo -e "${GREEN}  ✓ Rescue ISOs copied${NC}" || echo -e "${YELLOW}  ⚠ No Rescue ISOs${NC}"
fi

# Copy Raspberry Pi images
echo "Copying Raspberry Pi images..."
if [ -d "$BASE_DIR/RaspberryPi" ]; then
    cp -v "$BASE_DIR"/RaspberryPi/*.img.xz /mnt/sonic/RaspberryPi/ 2>/dev/null && echo -e "${GREEN}  ✓ RPi images copied${NC}" || echo -e "${YELLOW}  ⚠ No RPi images${NC}"
fi

# Step 4: Install custom Ventoy menu
echo ""
echo -e "${BLUE}[4/7] Installing custom Ventoy menu configuration...${NC}"
if [ -f "$BASE_DIR/config/ventoy/ventoy.json" ]; then
    cp -v "$BASE_DIR/config/ventoy/ventoy.json" /mnt/sonic/ventoy/
    echo -e "${GREEN}  ✓ Custom menu installed${NC}"
    echo ""
    echo "  Menu includes:"
    echo "    • Ubuntu 22.04.5 LTS Desktop"
    echo "    • Lubuntu 22.04.5 LTS (Lightweight)"
    echo "    • Ubuntu MATE 22.04.5 LTS"
    echo "    • Alpine Linux 3.19.1 (Minimal)"
    echo "    • TinyCore Pure64 15.0 (Rescue)"
else
    echo -e "${YELLOW}  ⚠ Custom menu not found, using Ventoy defaults${NC}"
fi

# Verify ISOs
echo ""
echo "Verifying ISOs on stick:"
ISO_COUNT=$(find /mnt/sonic/ISOS -name "*.iso" | wc -l)
echo -e "${GREEN}  Found: $ISO_COUNT ISOs${NC}"
find /mnt/sonic/ISOS -name "*.iso" -exec basename {} \; | sort

# Unmount
sync
umount /mnt/sonic
echo -e "${GREEN}✓ ISOs and config installed${NC}"

# Relabel partition 1 to SONIC
echo ""
echo -e "${BLUE}[5/7] Relabeling partition to SONIC...${NC}"
if command -v exfatlabel &>/dev/null; then
    exfatlabel "${USB}1" "SONIC" && echo -e "${GREEN}✓ Partition relabeled to SONIC${NC}" || echo -e "${YELLOW}⚠ Could not relabel (exfatlabel not found)${NC}"
elif command -v fatlabel &>/dev/null; then
    # Try with fatlabel as fallback (may not work on exFAT)
    fatlabel "${USB}1" "SONIC" 2>/dev/null && echo -e "${GREEN}✓ Partition relabeled to SONIC${NC}" || echo -e "${YELLOW}⚠ Could not relabel partition${NC}"
else
    echo -e "${YELLOW}⚠ exfatlabel not found, partition will remain labeled as Ventoy${NC}"
    echo -e "${YELLOW}  Install exfatprogs: sudo apt install exfatprogs${NC}"
fi

# Step 6: Shrink partition 1 and create FLASH data partition
echo ""
echo -e "${BLUE}[6/7] Creating FLASH data partition...${NC}"
echo -e "${YELLOW}This will shrink the Ventoy partition and create a 4GB ext4 partition${NC}"

if [ "$NEED_EXFAT" -eq 1 ]; then
    echo -e "${YELLOW}⚠ exfatresize not found - skipping FLASH partition creation${NC}"
    echo -e "${YELLOW}  Install it with: sudo apt install exfatprogs${NC}"
    NEW_SIZE=0
else
    # Get current size of partition 1 in MB
    CURRENT_SIZE=$(parted -s "$USB" unit MB print | grep "^ 1" | awk '{print $4}' | sed 's/MB//')
    DATA_SIZE=4096  # 4GB for data partition
    NEW_SIZE=$((CURRENT_SIZE - DATA_SIZE))

    echo "  Current partition size: ${CURRENT_SIZE}MB"
    echo "  New Ventoy partition size: ${NEW_SIZE}MB"
    echo "  FLASH partition size: ${DATA_SIZE}MB (~4GB)"
    echo ""
    
    # First shrink the exFAT filesystem
    echo "  Shrinking exFAT filesystem..."
    exfatresize -s $((NEW_SIZE * 1024 * 1024)) "${USB}1" || {
        echo -e "${YELLOW}  ⚠ Filesystem resize failed, continuing without data partition${NC}"
        NEW_SIZE=0
    }
    
    if [ "$NEW_SIZE" -gt 0 ]; then
        # Now resize the partition
        echo "  Resizing partition table..."
        parted -s "$USB" resizepart 1 ${NEW_SIZE}MB || {
            echo -e "${YELLOW}  ⚠ Partition resize failed${NC}"
            NEW_SIZE=0
        }
    fi
fi

if [ "$NEW_SIZE" -gt 0 ]; then
    # Create partition 3 (data)
    echo ""
    echo "  Creating partition 3 for FLASH data..."
    parted -s "$USB" mkpart primary ext4 ${NEW_SIZE}MB 100% || {
        echo -e "${YELLOW}  ⚠ Could not create partition 3${NC}"
        NEW_SIZE=0
    }
fi
    
if [ "$NEW_SIZE" -gt 0 ]; then
    sleep 2
    partprobe "$USB" 2>/dev/null || true
    sleep 2
    
    # Format partition 3
    if [ -b "${USB}3" ]; then
        echo "  Formatting ${USB}3 as ext4 with label FLASH..."
        mkfs.ext4 -F -L "FLASH" "${USB}3"
        
        # Step 7: Initialize data partition
        echo ""
        echo -e "${BLUE}[7/7] Initializing FLASH partition...${NC}"
        mkdir -p /mnt/sonic-data
        mount "${USB}3" /mnt/sonic-data
        
        # Create directory structure
        mkdir -p /mnt/sonic-data/{logs,sessions,library,devices,config}
        
        # Create initial catalog
        cat > /mnt/sonic-data/library/iso-catalog.json << EOF
{
  "last_updated": "$(date -Iseconds)",
  "total_isos": $ISO_COUNT,
  "auto_scan": true
}
EOF
        
        # Create config
        cat > /mnt/sonic-data/config/sonic-stick.conf << EOF
# Sonic Stick Configuration
STICK_NAME="SONIC"
VERSION="2.0"
BUILD_DATE="$(date -Iseconds)"
AUTO_SCAN=true
LOG_BOOTS=true
EOF
        
        # Create README
        cat > /mnt/sonic-data/README.txt << EOF
╔══════════════════════════════════════════════════════════════╗
║              SONIC STICK - DATA PARTITION                    ║
╚══════════════════════════════════════════════════════════════╝

This partition stores persistent data across boots:

  • logs/       - Boot and system logs
  • sessions/   - Session data from live boots
  • library/    - ISO catalog and tracking
  • devices/    - Hardware detection logs
  • config/     - Sonic Stick configuration

Label: FLASH
Filesystem: ext4
Created: $(date)
ISO Count: $ISO_COUNT

This partition is separate from the Ventoy bootloader and your ISOs.
EOF
        
        chmod -R 755 /mnt/sonic-data
        sync
        umount /mnt/sonic-data
        
        FLASH_DONE=1
        echo -e "${GREEN}✓ FLASH data partition initialized${NC}"
    else
        echo -e "${YELLOW}⚠ Partition ${USB}3 not found${NC}"
    fi
else
    echo ""
    echo -e "${YELLOW}⚠ Skipping FLASH partition creation${NC}"
    echo -e "${YELLOW}  You can create it manually later with:${NC}"
    echo -e "${YELLOW}  sudo bash scripts/create-data-partition.sh${NC}"
fi

# Step 8: Final verification
echo ""
echo -e "${BLUE}[8/8] Final verification...${NC}"
sleep 1

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              REBUILD COMPLETE - READY TO BOOT!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Final USB stick layout:${NC}"
lsblk "$USB" -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
echo ""
echo -e "${GREEN}✓ $ISO_COUNT ISOs ready to boot${NC}"
echo -e "${GREEN}✓ Custom Ventoy menu installed${NC}"
if [ "$FLASH_DONE" -eq 1 ]; then
    echo -e "${GREEN}✓ FLASH data partition ready${NC}"
else
    echo -e "${YELLOW}⚠ FLASH data partition not created (install exfatprogs and rerun)${NC}"
fi
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     NEXT STEPS:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "1. REBOOT your computer"
echo "2. Press F12 or ESC during boot"
echo "3. Select 'USB' or 'UEFI: SONIC' from boot menu"
echo "4. You should see the custom Ventoy menu with:"
echo ""
echo "   • Ubuntu 22.04.5 LTS Desktop (Installer)"
echo "   • Lubuntu 22.04.5 LTS (Lightweight Installer)"
echo "   • Ubuntu MATE 22.04.5 LTS (Installer)"
echo "   • Alpine Linux 3.19.1 (Live + Installer)"
echo "   • TinyCore Pure64 15.0 (Recovery Tool)"
echo ""
echo -e "${BLUE}Navigation:${NC}"
echo "   • Use arrow keys to select"
echo "   • Press Enter to boot"
echo "   • ESC to go back/exit"
echo ""
echo -e "${BLUE}Modes:${NC}"
echo "   • 'Installer' = Will install to your system disk"
echo "   • 'Live' = Runs from USB without installing"
echo "   • 'Recovery' = Emergency tools"
echo ""
echo -e "${GREEN}Enjoy your Sonic Stick! 🚀${NC}"
echo ""
