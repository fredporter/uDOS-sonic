#!/bin/bash
# Sonic Stick launcher: one entry point to download payloads, install/upgrade Ventoy, reflash, rebuild, scan, and collect logs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USB="${USB:-/dev/sdb}"
VENTOY_VERSION_DEFAULT="${VENTOY_VERSION:-1.1.10}"

# Re-exec with sudo for device access while preserving USB/VENTOY_VERSION
if [[ $EUID -ne 0 && -z "${SONIC_SUDO_REEXEC:-}" ]]; then
  exec sudo -E SONIC_SUDO_REEXEC=1 USB="$USB" VENTOY_VERSION="$VENTOY_VERSION_DEFAULT" bash "$0" "$@"
fi

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "sonic-stick"
exec > >(tee -a "$LOG_FILE") 2>&1

log_section "Sonic Stick Launcher"
log_info "Target USB device: $USB (override with USB=/dev/sdX)"
log_info "Ventoy version: $VENTOY_VERSION_DEFAULT"
log_info "Repo: $BASE_DIR"

pause() { read -rp "Press Enter to continue..."; }

menu() {
  echo ""
  echo "Select an action:"
  echo "  1) Download payloads (ISOs, Ventoy, Pi images)"
  echo "  2) Install/Upgrade Ventoy only"
  echo "  3) Reflash stick (install Ventoy + copy ISOs + data partition)"
  echo "  4) Rebuild from scratch (wipe and rebuild)"
  echo "  5) Create data partition only"
  echo "  6) Scan library (refresh iso-catalog)"
  echo "  7) Fix 'not a standard ventoy' error"
  echo "  8) Collect support logs"
  echo "  9) Quit"
  echo ""
  read -rp "Choice [1-9]: " choice
  case "$choice" in
    1)
      log_section "Download payloads"
      bash "$SCRIPT_DIR/download-payloads.sh" || log_warn "Downloads failed"
      ;;
    2)
      log_section "Install/Upgrade Ventoy"
      USB="$USB" VENTOY_VER="$VENTOY_VERSION_DEFAULT" bash "$SCRIPT_DIR/install-ventoy.sh" || log_warn "Install/upgrade failed or cancelled"
      ;;
    3)
      log_section "Reflash complete"
      USB="$USB" bash "$SCRIPT_DIR/reflash-complete.sh" || log_warn "Reflash failed or cancelled"
      ;;
    4)
      log_section "Rebuild from scratch"
      USB="$USB" VENTOY_VERSION="$VENTOY_VERSION_DEFAULT" bash "$SCRIPT_DIR/rebuild-from-scratch.sh" || log_warn "Rebuild failed or cancelled"
      ;;
    5)
      log_section "Create data partition"
      USB="$USB" bash "$SCRIPT_DIR/create-data-partition.sh" "$USB" || log_warn "Data partition creation failed or cancelled"
      ;;
    6)
      log_section "Scan library"
      # Try common mount points; user can edit if different
      DATA_MNT="${DATA_MNT:-/mnt/sonic-data}"
      VTOY_MNT="${VTOY_MNT:-/mnt/sonic}"
      bash "$SCRIPT_DIR/scan-library.sh" "$DATA_MNT" "$VTOY_MNT" || log_warn "Scan failed (partition not mounted?)"
      ;;
    7)
      log_section "Fix Ventoy error"
      USB="$USB" bash "$SCRIPT_DIR/fix-ventoy-stick.sh" || log_warn "Fix failed"
      ;;
    8)
      log_section "Collect support logs"
      USB="$USB" bash "$SCRIPT_DIR/collect-logs.sh" "$USB" || log_warn "Log collection failed"
      ;;
    9)
      log_ok "Done"
      exit 0
      ;;
    *)
      log_warn "Invalid choice"
      ;;
  esac
  pause
}

while true; do
  menu
done
