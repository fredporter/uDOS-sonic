#!/bin/bash
# Sonic Stick launcher: one entry point to download payloads, install/upgrade Ventoy, reflash, rebuild, scan, and collect logs.

set -euo pipefail

VERSION="1.0.0.6"
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

log_section "Sonic Stick Launcher v${VERSION}"
log_info "Target USB device: $USB (override with USB=/dev/sdX)"
log_info "Ventoy version: $VENTOY_VERSION_DEFAULT"
log_info "Repo: $BASE_DIR"

pause() { read -rp "Press Enter to continue..."; }

verify_stick() {
  log_section "USB Stick Verification"
  
  # Check if USB device exists
  if [[ ! -e "$USB" ]]; then
    log_error "USB device $USB not found"
    return 1
  fi
  
  echo ""
  log_info "Checking USB structure..."
  
  # Show partition layout
  echo ""
  lsblk -o NAME,SIZE,FSTYPE,LABEL "$USB" 2>/dev/null || fdisk -l "$USB" | head -15
  
  # Track issues
  ISSUES=()
  HAS_VENTOY=0
  HAS_SONIC=0
  HAS_FLASH=0
  HAS_VENTOY_JSON=0
  ISO_COUNT=0
  
  # Check for Ventoy bootloader (VTOYEFI partition)
  echo ""
  if blkid "$USB"* 2>/dev/null | grep -i "VTOYEFI" >/dev/null; then
    log_ok "✓ Ventoy bootloader (VTOYEFI) detected"
    HAS_VENTOY=1
  else
    log_error "✗ Ventoy bootloader not detected"
    ISSUES+=("no_ventoy")
  fi
  
  # Check for SONIC label - detect dynamically
  echo ""
  SONIC_PART=$(detect_sonic_partition "$USB")
  if [ -z "$SONIC_PART" ]; then
    # Fallback: check first partition
    if [ -b "${USB}1" ]; then
      SONIC_PART="${USB}1"
    elif [ -b "${USB}p1" ]; then
      SONIC_PART="${USB}p1"
    fi
  fi
  
  if [ -n "$SONIC_PART" ]; then
    PART_LABEL=$(blkid -s LABEL -o value "$SONIC_PART" 2>/dev/null || echo "")
    if [[ "$PART_LABEL" == "SONIC" ]]; then
      log_ok "✓ SONIC main partition found ($SONIC_PART)"
      HAS_SONIC=1
    elif [[ "$PART_LABEL" == "Ventoy" ]]; then
      log_warn "⚠ Main partition labeled 'Ventoy' (should be 'SONIC')"
      log_warn "  Partition: $SONIC_PART"
      ISSUES+=("wrong_label")
    else
      log_warn "⚠ Main partition has unexpected label: '$PART_LABEL'"
      log_warn "  Partition: $SONIC_PART"
      ISSUES+=("wrong_label")
    fi
  else
    log_error "✗ Could not find SONIC partition"
    ISSUES+=("no_sonic")
  fi
  
  # Check for FLASH partition
  echo ""
  FLASH_PART=$(detect_flash_partition "$USB")
  if [ -n "$FLASH_PART" ]; then
    log_ok "✓ FLASH data partition found ($FLASH_PART)"
    HAS_FLASH=1
  else
    log_warn "⚠ FLASH partition not found (optional)"
    ISSUES+=("no_flash")
  fi
  
  # Check ventoy.json and ISOs
  echo ""
  log_info "Checking configuration and ISOs..."
  TEMP_MNT=$(mktemp -d)
  if [ -n "$SONIC_PART" ] && mount "$SONIC_PART" "$TEMP_MNT" 2>/dev/null; then
    # Check ventoy.json
    if [[ -f "$TEMP_MNT/ventoy/ventoy.json" ]]; then
      if python3 -m json.tool "$TEMP_MNT/ventoy/ventoy.json" >/dev/null 2>&1; then
        log_ok "✓ ventoy.json is valid"
        HAS_VENTOY_JSON=1
      else
        log_error "✗ ventoy.json has syntax errors"
        ISSUES+=("bad_json")
      fi
    else
      log_warn "⚠ ventoy.json not found"
      ISSUES+=("no_json")
    fi
    
    # Count ISOs
    if [[ -d "$TEMP_MNT/ISOS" ]]; then
      ISO_COUNT=$(find "$TEMP_MNT/ISOS" -name "*.iso" 2>/dev/null | wc -l)
      if [[ $ISO_COUNT -gt 0 ]]; then
        log_ok "✓ Found $ISO_COUNT ISO(s) ready to boot"
      else
        log_warn "⚠ No ISOs found in ISOS directory"
        ISSUES+=("no_isos")
      fi
    else
      log_warn "⚠ ISOS directory not found"
      ISSUES+=("no_isos")
    fi
    
    umount "$TEMP_MNT" 2>/dev/null || true
  else
    log_error "✗ Could not mount $SONIC_PART for verification"
    ISSUES+=("cant_mount")
  fi
  rm -rf "$TEMP_MNT"
  
  # Show summary
  echo ""
  log_section "Verification Summary"
  
  if [[ ${#ISSUES[@]} -eq 0 ]]; then
    echo -e "\033[0;32m"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              ✓ STICK IS PERFECTLY CONFIGURED!             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo "✓ Ventoy bootloader installed"
    echo "✓ SONIC partition labeled correctly"
    echo "✓ FLASH data partition present"
    echo "✓ ventoy.json configured"
    echo "✓ $ISO_COUNT ISO(s) ready to boot"
    echo ""
    echo "Your stick is ready to use!"
    return 0
  else
    echo -e "\033[1;33m"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  ⚠ ISSUES DETECTED                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    
    # List issues
    for issue in "${ISSUES[@]}"; do
      case "$issue" in
        no_ventoy) echo "✗ Ventoy not installed" ;;
        wrong_label) echo "⚠ Partition labeled '$PART1_LABEL' (should be 'SONIC')" ;;
        no_flash) echo "⚠ FLASH partition missing (optional)" ;;
        no_json) echo "⚠ ventoy.json not configured" ;;
        bad_json) echo "✗ ventoy.json has errors" ;;
        no_isos) echo "⚠ No ISOs found" ;;
        cant_mount) echo "✗ Cannot mount main partition" ;;
      esac
    done
    
    echo ""
    echo "Recommended actions:"
    
    # Suggest appropriate fix
    if [[ " ${ISSUES[*]} " =~ " no_ventoy " ]] || [[ " ${ISSUES[*]} " =~ " cant_mount " ]]; then
      echo "  → Full rebuild required (Ventoy not properly installed)"
      echo ""
      read -rp "Run full rebuild now? [y/N]: " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        USB="$USB" VENTOY_VERSION="$VENTOY_VERSION_DEFAULT" bash "$SCRIPT_DIR/rebuild-from-scratch.sh"
        return $?
      fi
    elif [[ " ${ISSUES[*]} " =~ " wrong_label " ]] && [[ ${#ISSUES[@]} -eq 1 || (${#ISSUES[@]} -eq 2 && " ${ISSUES[*]} " =~ " no_flash ") ]]; then
      echo "  → Quick fix: Just relabel partition to SONIC"
      echo ""
      read -rp "Relabel partition now? [y/N]: " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/relabel-sonic.sh"
        return $?
      fi
    elif [[ " ${ISSUES[*]} " =~ " no_isos " ]] && [[ ${#ISSUES[@]} -le 2 ]]; then
      echo "  → Recommended: Copy ISOs to stick (quick repair)"
      echo "  → Alternative: Rebuild from scratch (menu option 3)"
      echo ""
      read -rp "Copy ISOs now (faster)? [Y/n]: " response
      if [[ -z "$response" ]] || [[ "$response" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/repair-isos.sh"
        return $?
      else
        read -rp "Run full rebuild instead? [y/N]: " response2
        if [[ "$response2" =~ ^[Yy]$ ]]; then
          USB="$USB" VENTOY_VERSION="$VENTOY_VERSION_DEFAULT" bash "$SCRIPT_DIR/rebuild-from-scratch.sh"
          return $?
        fi
      fi
    else
      echo "  → Recommended: Rebuild from scratch (menu option 3)"
      echo ""
      read -rp "Run rebuild now? [y/N]: " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        USB="$USB" VENTOY_VERSION="$VENTOY_VERSION_DEFAULT" bash "$SCRIPT_DIR/rebuild-from-scratch.sh"
        return $?
      fi
    fi
  fi
  
  echo ""
}

menu() {
  echo ""
  echo "Select an action:"
  echo "  1) Download payloads (ISOs, Ventoy, Pi images)"
  echo "  2) Install/Upgrade Ventoy only"
  echo "  3) Rebuild from scratch (wipe, copy ISOs, create FLASH)"
  echo "  4) Verify stick (check structure, config, offer fixes)"
  echo "  5) Quit"
  echo ""
  read -rp "Choice [1-5]: " choice
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
      log_section "Rebuild from scratch"
      USB="$USB" VENTOY_VERSION="$VENTOY_VERSION_DEFAULT" bash "$SCRIPT_DIR/rebuild-from-scratch.sh" || log_warn "Rebuild failed or cancelled"
      ;;
    4)
      verify_stick
      ;;
    5)
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
