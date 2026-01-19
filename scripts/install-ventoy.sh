#!/bin/bash
#
# Sonic Stick Ventoy Installer/Upgrader
# Installs or upgrades Ventoy on a USB stick
#
# Usage: sudo bash scripts/install-ventoy.sh
# Set USB=/dev/sdX and MODE=install or MODE=upgrade
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "install-ventoy"
exec > >(tee -a "$LOG_FILE") 2>&1

# Edit these for your system (override with environment: USB=/dev/sdX MODE=upgrade)
USB="${USB:-/dev/sdb}"              # USB device (e.g., /dev/sdb, NOT /dev/sdb1)
VENTOY_VER="${VENTOY_VER:-${VENTOY_VERSION:-1.1.10}}"  # Ventoy version to use
MODE="${MODE:-install}"             # install or upgrade
VENTOY_TAR="${VENTOY_TAR:-${BASE_DIR}/TOOLS/ventoy-${VENTOY_VER}-linux.tar.gz}"
VENTOY_DIR="${VENTOY_DIR:-${BASE_DIR}/TOOLS/ventoy-${VENTOY_VER}}"

log_env_snapshot

# Safety check
if [[ "$EUID" -ne 0 ]]; then
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

log_section "Ventoy Installer - $MODE mode"
log_info "Target USB: $USB"
log_info "Ventoy version: $VENTOY_VER"
lsblk "$USB" 2>/dev/null || fdisk -l "$USB" | head -5 | tee -a "$LOG_FILE"
read -p "Type 'ERASE' to proceed with $MODE: " confirm
if [[ "$confirm" != "ERASE" ]]; then
  log_warn "Cancelled by user"
  exit 0
fi

# Unmount all partitions
log_info "Unmounting partitions..."
for partition in "${USB}"*; do
  if [[ "$partition" != "$USB" ]]; then
    if mountpoint -q "$partition" 2>/dev/null; then
      umount "$partition" || true
    fi
  fi
done

# Fetch/extract Ventoy bits if missing
if [[ ! -f "$VENTOY_DIR/Ventoy2Disk.sh" ]]; then
  if [[ ! -f "$VENTOY_TAR" ]]; then
    log_info "Ventoy $VENTOY_VER not found locally. Downloading..."
    mkdir -p "$(dirname "$VENTOY_TAR")"
    wget -O "$VENTOY_TAR" "https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VER}/ventoy-${VENTOY_VER}-linux.tar.gz"
  fi
  log_info "Extracting Ventoy $VENTOY_VER..."
  tar -xzf "$VENTOY_TAR" -C "$(dirname "$VENTOY_TAR")"
fi

if [[ ! -f "$VENTOY_DIR/Ventoy2Disk.sh" ]]; then
  log_error "Failed to prepare Ventoy script at $VENTOY_DIR/Ventoy2Disk.sh"
  exit 1
fi

cd "$VENTOY_DIR"

# Run installer
log_info "Running Ventoy installer..."
if [[ "$MODE" == "install" ]]; then
  bash Ventoy2Disk.sh -i "$USB" | tee -a "$LOG_FILE" || { log_error "Install failed"; exit 1; }
elif [[ "$MODE" == "upgrade" ]]; then
  bash Ventoy2Disk.sh -u "$USB" | tee -a "$LOG_FILE" || { log_error "Upgrade failed"; exit 1; }
fi

log_section "Ventoy installed successfully"
log_info "Mount data partition and copy ISOs:"
log_info "  sudo mkdir -p /mnt/sonic"
log_info "  sudo mount ${USB}1 /mnt/sonic   # Ventoy data partition"
log_info "  sudo cp -r ../ISOS/* /mnt/sonic/ISOS/"
log_info "  sudo cp -r ../RaspberryPi/* /mnt/sonic/RaspberryPi/"
log_info "  sudo mkdir -p /mnt/sonic/ventoy && sudo cp -v ../config/ventoy/ventoy.json /mnt/sonic/ventoy/"
log_info "  sudo umount /mnt/sonic"
log_ok "install-ventoy finished"
