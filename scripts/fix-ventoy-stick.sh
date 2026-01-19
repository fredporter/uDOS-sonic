#!/bin/bash
#
# Sonic Stick Ventoy Recovery & Fix Script
# Diagnoses and fixes "not a standard ventoy" errors
#
# Usage: sudo bash scripts/fix-ventoy-stick.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USB="${USB:-/dev/sdb}"

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "fix-ventoy-stick"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_section "Sonic Stick Ventoy Recovery Tool"

# Safety check
if [[ $EUID -ne 0 ]]; then
  log_error "Must run with sudo"
  exit 1
fi

if [[ ! "$USB" =~ ^/dev/sd[a-z]$ ]]; then
  log_error "USB must be /dev/sdX (not /dev/sdX1)"
  exit 1
fi

if [[ ! -e "$USB" ]]; then
  log_error "USB device $USB not found"
  exit 1
fi

# Display current USB state
log_info "Current USB state:"
lsblk "$USB" 2>/dev/null || fdisk -l "$USB" | head -10

# Step 1: Diagnose the issue
log_section "Step 1: Diagnosing the issue..."

VENTOY_FOUND=false
if blkid "$USB"* 2>/dev/null | grep -i "VENTOY" >/dev/null; then
  VENTOY_FOUND=true
  log_ok "Ventoy partitions detected"
else
  log_warn "No Ventoy partition detected - Ventoy may not be properly installed"
fi

# Check if USB is mounted
MOUNTED_PARTS=""
for part in ${USB}*; do
  if mountpoint -q "$part" 2>/dev/null; then
    MOUNTED_PARTS="$MOUNTED_PARTS $part"
  fi
done

if [[ -n "$MOUNTED_PARTS" ]]; then
  log_warn "Some partitions are mounted:$MOUNTED_PARTS"
  log_info "Unmounting..."
  for part in $MOUNTED_PARTS; do
    umount "$part" || true
  done
fi

# Step 2: Suggest action plan
log_section "Step 2: Repair options"
echo ""
echo -e "${BLUE}Options:${NC}"
echo "  1) Full reinstall (wipe + fresh Ventoy + copy configs)"
echo "  2) Quick fix (copy/validate ventoy.json only)"
echo "  3) Upgrade Ventoy (keep existing partitions)"
echo "  4) Exit"
echo ""
read -rp "Choose action [1-4]: " action

case "$action" in
  1)
    log_section "Full Reinstall"
    echo -e "${RED}WARNING: This will erase all data on $USB${NC}"
    read -p "Type 'ERASE' to proceed: " confirm
    if [[ "$confirm" != "ERASE" ]]; then
      log_warn "Cancelled by user"
      exit 0
    fi
    
    # Unmount everything
    log_info "Unmounting all partitions..."
    for partition in ${USB}*; do
      if mountpoint -q "$partition" 2>/dev/null; then
        umount "$partition" || true
      fi
    done
    
    sleep 1
    
    # Run fresh install
    log_info "Running fresh Ventoy installation..."
    MODE=install USB="$USB" bash "$SCRIPT_DIR/install-ventoy.sh"
    
    # Now copy configs
    sleep 2
    log_info "Copying Ventoy configuration..."
    mkdir -p /mnt/sonic
    
    if mount "${USB}1" /mnt/sonic; then
      # Create directory structure
      mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
      mkdir -p /mnt/sonic/RaspberryPi
      mkdir -p /mnt/sonic/ventoy
      mkdir -p /mnt/sonic/LOGS
      
      # Copy configs
      if [[ -f "$BASE_DIR/config/ventoy/ventoy.json" ]]; then
        log_ok "Copying ventoy.json..."
        cp -v "$BASE_DIR/config/ventoy/ventoy.json" /mnt/sonic/ventoy/ || log_warn "Failed to copy ventoy.json"
      else
        log_warn "ventoy.json not found - using fallback config"
        cp -v "$BASE_DIR/config/ventoy/ventoy.json.example" /mnt/sonic/ventoy/ventoy.json || log_warn "Failed to copy example config"
      fi
      
      # Copy ISOs if they exist
      if [[ -d "$BASE_DIR/ISOS/Ubuntu" ]] && ls "$BASE_DIR/ISOS/Ubuntu"/*.iso &>/dev/null; then
        log_ok "Copying Ubuntu ISOs..."
        cp -v "$BASE_DIR/ISOS/Ubuntu"/*.iso /mnt/sonic/ISOS/Ubuntu/ || true
      fi
      
      if [[ -d "$BASE_DIR/ISOS/Minimal" ]] && ls "$BASE_DIR/ISOS/Minimal"/*.iso &>/dev/null; then
        log_ok "Copying Minimal ISOs..."
        cp -v "$BASE_DIR/ISOS/Minimal"/*.iso /mnt/sonic/ISOS/Minimal/ || true
      fi
      
      if [[ -d "$BASE_DIR/ISOS/Rescue" ]] && ls "$BASE_DIR/ISOS/Rescue"/*.iso &>/dev/null; then
        log_ok "Copying Rescue ISOs..."
        cp -v "$BASE_DIR/ISOS/Rescue"/*.iso /mnt/sonic/ISOS/Rescue/ || true
      fi
      
      if [[ -d "$BASE_DIR/RaspberryPi" ]] && ls "$BASE_DIR/RaspberryPi"/*.img.xz &>/dev/null; then
        log_ok "Copying RaspberryPi images..."
        cp -v "$BASE_DIR/RaspberryPi"/*.img.xz /mnt/sonic/RaspberryPi/ || true
      fi
      
      umount /mnt/sonic || true
      log_ok "USB configuration complete"
    else
      log_error "Failed to mount ${USB}1"
      exit 1
    fi
    
    log_ok "Full reinstall complete!"
    ;;
    
  2)
    log_section "Quick Fix (Config Only)"
    
    mkdir -p /mnt/sonic
    
    if mount "${USB}1" /mnt/sonic; then
      mkdir -p /mnt/sonic/ventoy
      
      # Validate JSON first
      if [[ -f "$BASE_DIR/config/ventoy/ventoy.json" ]]; then
        if python3 -m json.tool "$BASE_DIR/config/ventoy/ventoy.json" >/dev/null 2>&1; then
          log_ok "ventoy.json is valid"
          cp -v "$BASE_DIR/config/ventoy/ventoy.json" /mnt/sonic/ventoy/
        else
          log_error "ventoy.json has syntax errors"
          log_info "Using example config instead..."
          cp -v "$BASE_DIR/config/ventoy/ventoy.json.example" /mnt/sonic/ventoy/ventoy.json || exit 1
        fi
      else
        log_warn "ventoy.json not found - using example"
        cp -v "$BASE_DIR/config/ventoy/ventoy.json.example" /mnt/sonic/ventoy/ventoy.json || exit 1
      fi
      
      # Create missing directories
      mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
      mkdir -p /mnt/sonic/RaspberryPi
      mkdir -p /mnt/sonic/LOGS
      
      umount /mnt/sonic || true
      log_ok "Configuration fixed!"
    else
      log_error "Failed to mount ${USB}1"
      exit 1
    fi
    ;;
    
  3)
    log_section "Ventoy Upgrade"
    
    # Unmount
    for partition in ${USB}*; do
      if mountpoint -q "$partition" 2>/dev/null; then
        umount "$partition" || true
      fi
    done
    
    sleep 1
    MODE=upgrade USB="$USB" bash "$SCRIPT_DIR/install-ventoy.sh"
    log_ok "Ventoy upgraded!"
    ;;
    
  4)
    log_info "Exiting"
    exit 0
    ;;
    
  *)
    log_error "Invalid choice"
    exit 1
    ;;
esac

# Final check
log_section "Verification"
log_info "Final USB state:"
lsblk "$USB" 2>/dev/null || fdisk -l "$USB" | head -10

log_section "Recovery complete!"
echo ""
echo -e "${GREEN}✓ USB stick fixed!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Reboot with USB inserted"
echo "2. Select USB in boot menu (F12 or ESC)"
echo "3. You should see Ventoy menu"
echo ""
echo -e "${YELLOW}If still showing 'not a standard ventoy':${NC}"
echo "  • Check BIOS boot order (USB should be first)"
echo "  • Try a different USB port"
echo "  • Verify with: sudo parted -l $USB"
echo ""
log_ok "fix-ventoy-stick finished"
