#!/bin/bash
# Verify Sonic Stick USB layout: checks Ventoy partitions, ISO locations, and ventoy.json presence
# Usage: sudo bash scripts/verify-usb-layout.sh /dev/sdX

set -euo pipefail

USB_DEVICE="${1:-${USB:-/dev/sdb}}"
MNT_DIR="/mnt/sonic-verify"

echo "[Verify] Target USB: ${USB_DEVICE}"
if [[ ! -b "${USB_DEVICE}" ]]; then
  echo "[Error] Device not found: ${USB_DEVICE}" >&2
  exit 1
fi

echo "[Info] Partition table:"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "${USB_DEVICE}" | sed '1!s/^/  /'

# Expect two partitions: 1=data (exFAT/NTFS), 2=VTOYEFI (FAT)
DATA_PART="${USB_DEVICE}1"
EFI_PART="${USB_DEVICE}2"

if [[ ! -b "${DATA_PART}" ]]; then
  echo "[Error] Data partition not found: ${DATA_PART}" >&2
  exit 2
fi

mkdir -p "${MNT_DIR}"
echo "[Info] Mounting data partition read-only: ${DATA_PART} -> ${MNT_DIR}"
MNT_OWNED=0
if mount -o ro "${DATA_PART}" "${MNT_DIR}" 2>/dev/null; then
  MNT_OWNED=1
else
  # Already mounted elsewhere? Use existing mountpoint.
  EXISTING_MNT=$(findmnt -n -o TARGET "${DATA_PART}" 2>/dev/null || true)
  if [[ -n "${EXISTING_MNT}" && -d "${EXISTING_MNT}" ]]; then
    echo "[Info] Data partition already mounted at: ${EXISTING_MNT}"
    MNT_DIR="${EXISTING_MNT}"
  else
    echo "[Error] Failed to mount ${DATA_PART}. Is it already mounted?" >&2
    exit 3
  fi
fi

PASS=1

echo "[Check] Ventoy config: ${MNT_DIR}/ventoy/ventoy.json"
if [[ -f "${MNT_DIR}/ventoy/ventoy.json" ]]; then
  echo "  ✓ Found ventoy.json"
else
  echo "  ✗ Missing ventoy.json (expected at /ventoy/ventoy.json)"
  PASS=0
fi

echo "[Check] ISO directories: ${MNT_DIR}/ISOS/{Ubuntu,Minimal,Rescue}"
for d in Ubuntu Minimal Rescue; do
  if [[ -d "${MNT_DIR}/ISOS/${d}" ]]; then
    echo "  ✓ ${d} exists"
  else
    echo "  ✗ ${d} missing"
    PASS=0
  fi
done

echo "[List] Top-level ISOs present:"
find "${MNT_DIR}/ISOS" -maxdepth 2 -type f -name '*.iso' -printf '  • %p\n' | sort || true

echo "[Check] EFI partition label"
EFI_INFO=$(lsblk -no LABEL,FSTYPE "${EFI_PART}" 2>/dev/null || true)
if echo "${EFI_INFO}" | grep -qi 'VTOYEFI'; then
  echo "  ✓ EFI partition labeled VTOYEFI"
else
  echo "  ✗ EFI partition label not detected (got: ${EFI_INFO:-none})"
  # Not fatal
fi

if [[ "${MNT_OWNED}" -eq 1 ]]; then
  echo "[Info] Unmounting ${MNT_DIR}"
  umount "${MNT_DIR}" || true
  rmdir "${MNT_DIR}" 2>/dev/null || true
else
  echo "[Info] Left existing mount intact: ${MNT_DIR}"
fi

if [[ "${PASS}" -eq 1 ]]; then
  echo "[Result] USB layout looks correct ✅"
  exit 0
else
  echo "[Result] Issues detected with USB layout ⚠"
  exit 4
fi
