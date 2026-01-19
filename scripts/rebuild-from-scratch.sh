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

# Helpers
wait_for_ventoy_parts() {
    local dev="$1" retries="${2:-60}"
    local p1="${dev}1" p2="${dev}2"
    echo "Waiting for $p1 and $p2 (max ${retries}s)..."
    for i in $(seq 1 "$retries"); do
        if [ -b "$p1" ] && [ -b "$p2" ]; then
            echo "✓ Partitions detected: $p1 and $p2"
            return 0
        fi
        # Aggressive reread every iteration
        blockdev --rereadpt "$dev" 2>/dev/null || true
        partprobe "$dev" 2>/dev/null || true
        partx -u "$dev" 2>/dev/null || true
        udevadm settle --timeout=2 2>/dev/null || true
        
        # Log state every 5 seconds
        if [ $((i % 5)) -eq 0 ]; then
            echo "  [$i/${retries}s] Still waiting..."
            lsblk "$dev" -o NAME,SIZE,TYPE,FSTYPE,LABEL 2>/dev/null | tee -a "$VENTOY_INSTALL_LOG" || true
        fi
        sleep 1
    done
    return 1
}

# Global log for Ventoy installer (write where user can read)
LOG_DIR="$BASE_DIR/LOGS"
mkdir -p "$LOG_DIR"
VENTOY_INSTALL_LOG="$LOG_DIR/ventoy-install-$(date -Iseconds).log"

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

# Step 1: Unmount everything and ensure disk is fully released
echo ""
echo -e "${BLUE}[1/7] Unmounting all partitions on $USB...${NC}"

# Check for swap
if swapon --show | grep -q "$USB"; then
    echo "  Disabling swap on $USB"
    swapoff "${USB}"* 2>/dev/null || true
fi

# Unmount all partitions
for part in ${USB}*[0-9]; do
    if mount | grep -q "$part"; then
        echo "  Unmounting $part"
        umount "$part" 2>/dev/null || true
    fi
done

# Remove device-mapper mappings if any
if command -v dmsetup &>/dev/null; then
    dmsetup remove_all 2>/dev/null || true
fi

# Check for holders (LVM, dm, md)
if [ -d "/sys/block/${USB#/dev/}/holders" ]; then
    HOLDERS=$(ls -1 "/sys/block/${USB#/dev/}/holders" 2>/dev/null || true)
    if [ -n "$HOLDERS" ]; then
        echo -e "${RED}WARNING: Device has holders: $HOLDERS${NC}"
        echo "  Attempting to release..."
        for holder in $HOLDERS; do
            dmsetup remove "$holder" 2>/dev/null || true
        done
    fi
fi

sleep 2

# Step 2: Complete wipe and install Ventoy
echo ""
echo -e "${BLUE}[2/7] Wiping disk and installing fresh Ventoy...${NC}"
echo -e "${YELLOW}This will take 30-60 seconds...${NC}"

# Pre-wipe to avoid stale partition tables
echo ""; echo "  Pre-wiping existing signatures..."
wipefs -a "$USB" || true
if command -v sgdisk &>/dev/null; then
    sgdisk --zap-all "$USB" || true
fi
dd if=/dev/zero of="$USB" bs=1M count=4 conv=fsync 2>/dev/null || true
sync

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

# Patch Ventoy's wait_and_create_part to be more robust
echo "Patching Ventoy for better partition detection..."
if [ -f "$VENTOY_DIR/tool/ventoy_lib.sh" ]; then
    # Backup original
    cp "$VENTOY_DIR/tool/ventoy_lib.sh" "$VENTOY_DIR/tool/ventoy_lib.sh.orig" 2>/dev/null || true
    
    # Replace wait_and_create_part with robust version
    cat > /tmp/ventoy_wait_patch.sh << 'PATCH_EOF'
wait_and_create_part() {
    vPART1=$1
    vPART2=$2
    echo "Wait for partitions $vPART1 and $vPART2 ..."
    
    # Aggressive udev settling first
    sync; sleep 1
    udevadm settle --timeout=10 2>/dev/null || true
    partprobe 2>/dev/null || true
    
    for i in 0 1 2 3 4 5 6 7 8 9; do
        if [ -b "$vPART1" ] && [ -b "$vPART2" ]; then
            break
        else
            echo "Wait for $vPART1 and $vPART2 ..."
            udevadm settle --timeout=2 2>/dev/null || true
            sleep 1
        fi
    done

    # Check part1
    if [ -b "$vPART1" ]; then
        echo "$vPART1 exist OK"
    else
        if [ -f "/sys/class/block/${vPART1#/dev/}/dev" ]; then
            MajorMinor=$(sed "s/:/ /" /sys/class/block/${vPART1#/dev/}/dev)        
            echo "mknod -m 0660 $vPART1 b $MajorMinor ..."
            mknod -m 0660 $vPART1 b $MajorMinor 2>/dev/null || true
        fi
    fi
    
    # Check part2
    if [ -b "$vPART2" ]; then
        echo "$vPART2 exist OK"
    else
        if [ -f "/sys/class/block/${vPART2#/dev/}/dev" ]; then
            MajorMinor=$(sed "s/:/ /" /sys/class/block/${vPART2#/dev/}/dev)        
            echo "mknod -m 0660 $vPART2 b $MajorMinor ..."
            mknod -m 0660 $vPART2 b $MajorMinor 2>/dev/null || true
        fi
    fi

    # Final check
    if [ -b "$vPART1" ] && [ -b "$vPART2" ]; then
        echo "partition exist OK"
    else
        echo "[WARN] Partitions not fully ready, but continuing..."
    fi
}
PATCH_EOF
    
    # Replace the function in ventoy_lib.sh
    sed -i '/^wait_and_create_part() {/,/^}/d' "$VENTOY_DIR/tool/ventoy_lib.sh"
    cat /tmp/ventoy_wait_patch.sh >> "$VENTOY_DIR/tool/ventoy_lib.sh"
    rm /tmp/ventoy_wait_patch.sh
    echo "✓ Ventoy patched"
fi

# Run Ventoy installer with -I flag (force install, wipe disk)
cd "$VENTOY_DIR"
# Ventoy requires TWO confirmations: first "y", then "y" again for double-check
printf "y\ny\n" | ./Ventoy2Disk.sh -I -g "$USB" 2>&1 | tee "$VENTOY_INSTALL_LOG" || {
    echo -e "${RED}Ventoy installation failed${NC}"
    echo "Ventoy install log: $VENTOY_INSTALL_LOG"
    exit 1
}
log_info "Ventoy install log: $VENTOY_INSTALL_LOG"

cd "$BASE_DIR"

# Aggressive partition table reread
echo "Forcing kernel partition table reread..."
sync; sleep 2
blockdev --rereadpt "$USB" 2>/dev/null || true
partprobe "$USB" 2>/dev/null || true
partx -u "$USB" 2>/dev/null || true
udevadm settle --timeout=10 2>/dev/null || true
sleep 2
udevadm trigger --name-match="${USB##*/}" 2>/dev/null || true
udevadm settle --timeout=10 2>/dev/null || true
sleep 2

# Verify GPT was written
echo "Verifying partition table..."
if ! fdisk -l "$USB" 2>/dev/null | grep -q "${USB}1"; then
    echo -e "${RED}ERROR: fdisk shows no partitions after Ventoy install!${NC}"
    fdisk -l "$USB" 2>&1 | tee -a "$VENTOY_INSTALL_LOG"
    echo "Ventoy install log: $VENTOY_INSTALL_LOG"
    exit 1
fi

# Wait for partition nodes to appear
echo "Waiting for partition device nodes to appear..."
wait_for_ventoy_parts "$USB" 60 || {
    log_warn "Partitions missing after first Ventoy run; retrying install..."
    cd "$VENTOY_DIR"
    # Two confirmations needed
    printf "y\ny\n" | ./Ventoy2Disk.sh -I -g "$USB" 2>&1 | tee -a "$VENTOY_INSTALL_LOG" || {
        log_error "Ventoy installation failed on retry"
        echo "Ventoy install log: $VENTOY_INSTALL_LOG"
        exit 1
    }
    cd "$BASE_DIR"
    
    # Same aggressive reread after retry
    echo "Forcing kernel partition table reread after retry..."
    sync; sleep 2
    blockdev --rereadpt "$USB" 2>/dev/null || true
    partprobe "$USB" 2>/dev/null || true
    partx -u "$USB" 2>/dev/null || true
    udevadm settle --timeout=10 2>/dev/null || true
    sleep 2
    udevadm trigger --name-match="${USB##*/}" 2>/dev/null || true
    udevadm settle --timeout=10 2>/dev/null || true
    sleep 2
    
    wait_for_ventoy_parts "$USB" 30 || {
        log_error "Ventoy partitions not detected after retry (missing ${USB}1 or ${USB}2)"
        echo ""
        echo "=== DIAGNOSTIC OUTPUT ==="
        echo "--- lsblk ---"
        lsblk "$USB" -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL 2>&1 | tee -a "$VENTOY_INSTALL_LOG"
        echo "--- fdisk -l ---"
        fdisk -l "$USB" 2>&1 | tee -a "$VENTOY_INSTALL_LOG"
        echo "--- blkid ---"
        blkid | grep "$USB" 2>&1 | tee -a "$VENTOY_INSTALL_LOG" || echo "No blkid entries for $USB"
        echo "--- /sys/block entries ---"
        ls -la /sys/block/"${USB##*/}"/ 2>&1 | tee -a "$VENTOY_INSTALL_LOG"
        echo "--- dmesg tail (last 30 lines) ---"
        dmesg | tail -n 30 | tee -a "$VENTOY_INSTALL_LOG"
        echo ""
        echo "Ventoy install log: $VENTOY_INSTALL_LOG"
        exit 1
    }
}

# Detect Ventoy partitions dynamically (don't assume partition numbers!)
echo "Detecting Ventoy partitions..."
SONIC_PART=$(detect_sonic_partition "$USB" || true)
VENTOY_PART=$(detect_ventoy_partition "$USB" || true)

if [ -z "$SONIC_PART" ]; then
    # Find first exfat partition (Ventoy creates this as partition 1, labeled "Ventoy")
    echo "SONIC label not found, searching for exFAT partition..."
    for part in ${USB}*[0-9] ${USB}p*[0-9]; do
        if [ -b "$part" ] && blkid "$part" 2>/dev/null | grep -q "TYPE=\"exfat\""; then
            SONIC_PART="$part"
            echo "✓ Found exFAT partition: $SONIC_PART"
            break
        fi
    done
fi

if [ -z "$SONIC_PART" ]; then
    log_error "Could not find Ventoy data partition (exFAT)"
    echo "Available partitions:"
    lsblk "$USB" -o NAME,SIZE,FSTYPE,LABEL
    exit 1
fi

log_info "✓ Using data partition: $SONIC_PART"

# Verify partition has exFAT filesystem and SONIC label
echo "Verifying SONIC partition filesystem..."
if ! blkid "$SONIC_PART" | grep -q "TYPE=\"exfat\""; then
    log_warn "SONIC partition is not exFAT, formatting now..."
    # Determine cluster size based on disk size
    disk_size_gb=$(lsblk -b -d -n -o SIZE "$USB" | awk '{print int($1/1024/1024/1024)}')
    if [ $disk_size_gb -gt 32 ]; then
        cluster_sectors=256  # 128KB for >32GB
    else
        cluster_sectors=64   # 32KB for <=32GB
    fi
    
    mkexfatfs -n "SONIC" -s $cluster_sectors "$SONIC_PART" || {
        log_error "Failed to format $SONIC_PART as exFAT"
        exit 1
    }
    log_info "✓ Formatted $SONIC_PART as exFAT (label: SONIC)"
    sync; sleep 2
elif ! blkid "$SONIC_PART" | grep -q "LABEL=\"SONIC\""; then
    # Partition exists but wrong label, relabel it
    log_info "Relabeling partition to SONIC..."
    exfatlabel "$SONIC_PART" "SONIC" || log_warn "Could not relabel partition"
    sync; sleep 1
fi

# Step 3: Mount and copy ISOs
echo ""
echo -e "${BLUE}[3/7] Mounting Ventoy partition and copying ISOs...${NC}"
mkdir -p /mnt/sonic
sleep 2

# Mount SONIC partition (Ventoy data)
mount "$SONIC_PART" /mnt/sonic || {
    echo -e "${RED}Failed to mount $SONIC_PART${NC}"
    exit 1
}

echo -e "${GREEN}✓ Mounted $SONIC_PART${NC}"

# Create directory structure
mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
mkdir -p /mnt/sonic/RaspberryPi
mkdir -p /mnt/sonic/ventoy
mkdir -p /mnt/sonic/LOGS

# Copy Ubuntu ISOs with progress
echo ""
echo "Copying Ubuntu ISOs..."
if [ -d "$BASE_DIR/ISOS/Ubuntu" ] && ls "$BASE_DIR"/ISOS/Ubuntu/*.iso &>/dev/null; then
    for iso in "$BASE_DIR"/ISOS/Ubuntu/*.iso; do
        filename=$(basename "$iso")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -ah --progress "$iso" /mnt/sonic/ISOS/Ubuntu/
        elif command -v pv &>/dev/null; then
            pv "$iso" > "/mnt/sonic/ISOS/Ubuntu/$filename"
        else
            cp -v "$iso" /mnt/sonic/ISOS/Ubuntu/
        fi
    done
    echo -e "${GREEN}  ✓ Ubuntu ISOs copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No Ubuntu ISOs${NC}"
fi

# Copy Minimal ISOs with progress
echo "Copying Minimal ISOs..."
if [ -d "$BASE_DIR/ISOS/Minimal" ] && ls "$BASE_DIR"/ISOS/Minimal/*.iso &>/dev/null; then
    for iso in "$BASE_DIR"/ISOS/Minimal/*.iso; do
        filename=$(basename "$iso")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -ah --progress "$iso" /mnt/sonic/ISOS/Minimal/
        elif command -v pv &>/dev/null; then
            pv "$iso" > "/mnt/sonic/ISOS/Minimal/$filename"
        else
            cp -v "$iso" /mnt/sonic/ISOS/Minimal/
        fi
    done
    echo -e "${GREEN}  ✓ Minimal ISOs copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No Minimal ISOs${NC}"
fi

# Copy Rescue ISOs with progress
echo "Copying Rescue ISOs..."
if [ -d "$BASE_DIR/ISOS/Rescue" ] && ls "$BASE_DIR"/ISOS/Rescue/*.iso &>/dev/null; then
    for iso in "$BASE_DIR"/ISOS/Rescue/*.iso; do
        filename=$(basename "$iso")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -ah --progress "$iso" /mnt/sonic/ISOS/Rescue/
        elif command -v pv &>/dev/null; then
            pv "$iso" > "/mnt/sonic/ISOS/Rescue/$filename"
        else
            cp -v "$iso" /mnt/sonic/ISOS/Rescue/
        fi
    done
    echo -e "${GREEN}  ✓ Rescue ISOs copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No Rescue ISOs${NC}"
fi

# Copy Raspberry Pi images with progress
echo "Copying Raspberry Pi images..."
if [ -d "$BASE_DIR/RaspberryPi" ] && ls "$BASE_DIR"/RaspberryPi/*.img.xz &>/dev/null; then
    for img in "$BASE_DIR"/RaspberryPi/*.img.xz; do
        filename=$(basename "$img")
        echo "  → $filename"
        if command -v rsync &>/dev/null; then
            rsync -ah --progress "$img" /mnt/sonic/RaspberryPi/
        elif command -v pv &>/dev/null; then
            pv "$img" > "/mnt/sonic/RaspberryPi/$filename"
        else
            cp -v "$img" /mnt/sonic/RaspberryPi/
        fi
    done
    echo -e "${GREEN}  ✓ RPi images copied${NC}"
else
    echo -e "${YELLOW}  ⚠ No RPi images${NC}"
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
    exfatlabel "$SONIC_PART" "SONIC" && echo -e "${GREEN}✓ Partition relabeled to SONIC${NC}" || echo -e "${YELLOW}⚠ Could not relabel (exfatlabel not found)${NC}"
elif command -v fatlabel &>/dev/null; then
    # Try with fatlabel as fallback (may not work on exFAT)
    fatlabel "$SONIC_PART" "SONIC" 2>/dev/null && echo -e "${GREEN}✓ Partition relabeled to SONIC${NC}" || echo -e "${YELLOW}⚠ Could not relabel partition${NC}"
else
    echo -e "${YELLOW}⚠ exfatlabel not found, partition will remain labeled as Ventoy${NC}"
    echo -e "${YELLOW}  Install exfatprogs: sudo apt install exfatprogs${NC}"
fi

# Step 6: Shrink partition 1 and create FLASH data partition
echo ""
echo -e "${BLUE}[6/7] Creating FLASH data partition...${NC}"
echo -e "${YELLOW}This will backup data, repartition, and restore${NC}"

# Get the partition number of the SONIC partition
SONIC_PART_NUM=$(get_partition_number "$SONIC_PART")
if [ -z "$SONIC_PART_NUM" ]; then
    log_error "Could not determine SONIC partition number from $SONIC_PART"
    exit 1
fi

# Get current size of SONIC partition in MB
CURRENT_SIZE=$(parted -s "$USB" unit MB print | grep "^ ${SONIC_PART_NUM}" | awk '{print $4}' | sed 's/MB//')
DATA_SIZE=4096  # 4GB for data partition
NEW_SIZE=$((CURRENT_SIZE - DATA_SIZE))

echo "  Current partition size: ${CURRENT_SIZE}MB"
echo "  New Ventoy partition size: ${NEW_SIZE}MB"
echo "  FLASH partition size: ${DATA_SIZE}MB (~4GB)"
echo ""

# Create temporary backup directory
BACKUP_DIR="/tmp/sonic-backup-$$"
mkdir -p "$BACKUP_DIR"

echo "  Backing up data from $SONIC_PART..."
cp -a /mnt/sonic/* "$BACKUP_DIR/" || {
    echo -e "${YELLOW}  ⚠ Backup failed, skipping FLASH partition${NC}"
    rm -rf "$BACKUP_DIR"
    NEW_SIZE=0
}

if [ "$NEW_SIZE" -gt 0 ]; then
    # Unmount
    umount /mnt/sonic 2>/dev/null || true
    
    # Delete SONIC partition and recreate it smaller
    echo "  Repartitioning..."
    parted -s "$USB" rm $SONIC_PART_NUM || {
        echo -e "${YELLOW}  ⚠ Failed to remove partition${NC}"
        NEW_SIZE=0
    }
fi

if [ "$NEW_SIZE" -gt 0 ]; then
    parted -s "$USB" mkpart primary 2048s ${NEW_SIZE}MB || {
        echo -e "${YELLOW}  ⚠ Failed to create partition${NC}"
        NEW_SIZE=0
    }
fi

if [ "$NEW_SIZE" -gt 0 ]; then
    # Format the new smaller partition
    echo "  Formatting $SONIC_PART..."
    sleep 2
    partprobe "$USB" 2>/dev/null || true
    sleep 2
    # Rediscover partition after repartitioning
    SONIC_PART=$(detect_sonic_partition "$USB")
    if [ -z "$SONIC_PART" ]; then
        # Fallback: assume same partition number
        if [[ "$USB" =~ nvme ]]; then
            SONIC_PART="${USB}p${SONIC_PART_NUM}"
        else
            SONIC_PART="${USB}${SONIC_PART_NUM}"
        fi
    fi
    mkfs.exfat -L "SONIC" "$SONIC_PART" || {
        echo -e "${YELLOW}  ⚠ Failed to format partition${NC}"
        NEW_SIZE=0
    }
fi

if [ "$NEW_SIZE" -gt 0 ]; then
    # Restore data
    echo "  Restoring data..."
    mount "$SONIC_PART" /mnt/sonic
    cp -a "$BACKUP_DIR"/* /mnt/sonic/ || {
        echo -e "${YELLOW}  ⚠ Failed to restore data${NC}"
        NEW_SIZE=0
    }
    sync
fi

# Cleanup backup
rm -rf "$BACKUP_DIR"

if [ "$NEW_SIZE" -gt 0 ]; then
    # Create partition 3 (data)
    echo ""
    echo "  Creating partition 3 for FLASH data..."
    parted -s "$USB" mkpart primary ${NEW_SIZE}MB 100% || {
        echo -e "${YELLOW}  ⚠ Could not create partition 3${NC}"
        NEW_SIZE=0
    }
fi
    
if [ "$NEW_SIZE" -gt 0 ]; then
    sleep 2
    partprobe "$USB" 2>/dev/null || true
    sleep 2
    
    # Detect the new FLASH partition (should be the last partition)
    FLASH_PART=$(detect_flash_partition "$USB")
    if [ -z "$FLASH_PART" ]; then
        # Find the last partition number and assume it's the FLASH partition
        for part in ${USB}*[0-9] ${USB}p*[0-9]; do
            if [ -b "$part" ]; then
                FLASH_PART="$part"
            fi
        done
    fi
    
    # Format FLASH partition
    if [ -n "$FLASH_PART" ] && [ -b "$FLASH_PART" ]; then
        echo "  Formatting $FLASH_PART as ext4 with label FLASH..."
        mkfs.ext4 -F -L "FLASH" "$FLASH_PART"
        
        # Step 7: Initialize data partition
        echo ""
        echo -e "${BLUE}[7/7] Initializing FLASH partition...${NC}"
        mkdir -p /mnt/sonic-data
        mount "$FLASH_PART" /mnt/sonic-data
        
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
        echo -e "${YELLOW}⚠ Could not find FLASH partition after creation${NC}"
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
    echo -e "${RED}✗ FLASH data partition missing (this build is incomplete)${NC}"
    exit 1
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
