#!/bin/bash
# Shared logging helpers for Sonic Stick scripts.
# Usage: source this file, then call init_logging "script-name".

# Do not change shell options here; caller controls set -euo pipefail.

__sonic_logging_loaded=1

# Color palette
__LOG_RED='\033[0;31m'
__LOG_YELLOW='\033[1;33m'
__LOG_BLUE='\033[0;34m'
__LOG_GREEN='\033[0;32m'
__LOG_DIM='\033[0;2m'
__LOG_RESET='\033[0m'

# Derive repository root (two levels up from this helper)
__LOG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__LOG_REPO_ROOT="$(cd "${__LOG_LIB_DIR}/../.." && pwd)"

init_logging() {
  local script_name="${1-}"
  local timestamp="${2-}"
  script_name="${script_name:-$(basename "$0" .sh)}"
  timestamp="${timestamp:-$(date -Iseconds)}"

  if [[ -z "${LOG_ROOT:-}" ]]; then
    for candidate in "/media/$USER/SONIC/LOGS" "/mnt/sonic/LOGS"; do
      if [[ -d "$candidate" && -w "$candidate" ]]; then
        LOG_ROOT="$candidate"
        break
      fi
    done
  fi

  # Fallback to repo LOGS directory
  LOG_ROOT="${LOG_ROOT:-${BASE_DIR:-${__LOG_REPO_ROOT}}/LOGS}"
  
  # Try to create LOG_ROOT if it doesn't exist
  if [[ ! -d "$LOG_ROOT" ]]; then
    if ! mkdir -p "$LOG_ROOT" 2>/dev/null; then
      # Can't create preferred location, use /tmp
      LOG_ROOT="/tmp/sonic-stick-logs"
      mkdir -p "$LOG_ROOT" || LOG_ROOT="/tmp"
    fi
  fi

  LOG_FILE="${LOG_FILE:-${LOG_ROOT}/${script_name}-${timestamp}.log}"
  if ! touch "$LOG_FILE" 2>/dev/null; then
    # Fallback to /tmp if we can't write to preferred location
    LOG_FILE="/tmp/${script_name}-${timestamp}.log"
    if ! touch "$LOG_FILE" 2>/dev/null; then
      echo "ERROR: cannot write log file anywhere (tried $LOG_ROOT and /tmp)" >&2
      exit 1
    fi
    echo "WARNING: Using fallback log location: $LOG_FILE" >&2
  fi

  export LOG_ROOT LOG_FILE

  if [[ "${DEBUG:-0}" != "0" ]]; then
    set -x
  fi
  set -E
  trap 'log_error "Command failed (exit $?) at line $LINENO: $BASH_COMMAND"' ERR

  log_info "Logging to $LOG_FILE"
}

_log() {
  local level="$1"; shift
  local message="$*"
  local now
  now="$(date -Iseconds)"
  local color="${__LOG_RESET}"
  case "$level" in
    INFO) color="${__LOG_BLUE}";;
    OK) color="${__LOG_GREEN}";;
    WARN) color="${__LOG_YELLOW}";;
    ERROR) color="${__LOG_RED}";;
    DEBUG) color="${__LOG_DIM}";;
  esac
  local line="[$now] [$level] $message"
  if [[ -n "${LOG_FILE:-}" ]]; then
    echo -e "$line" | tee -a "$LOG_FILE" >&2
  else
    echo -e "$line" >&2
  fi
}

log_info() { _log INFO "$*"; }
log_ok() { _log OK "$*"; }
log_warn() { _log WARN "$*"; }
log_error() { _log ERROR "$*"; }
log_debug() { if [[ "${DEBUG:-0}" != "0" ]]; then _log DEBUG "$*"; fi; }

log_section() {
  local title="$*"
  log_info "============================================"
  log_info "$title"
  log_info "============================================"
}

log_cmd() {
  # Logs and executes a command, preserving exit code.
  log_debug "Running: $*"
  "$@" 2>&1 | tee -a "$LOG_FILE"
  local rc=${PIPESTATUS[0]}
  if [[ $rc -ne 0 ]]; then
    log_error "Command failed (exit $rc): $*"
  fi
  return $rc
}

log_env_snapshot() {
  log_info "Environment snapshot:"
  log_debug "PWD=$(pwd)"
  if command -v uname >/dev/null 2>&1; then log_info "uname: $(uname -a)"; fi
  if command -v lsblk >/dev/null 2>&1; then log_info "lsblk: $(lsblk -o NAME,SIZE,FSTYPE,LABEL | tr '\n' '; ')"; fi
  if command -v df >/dev/null 2>&1; then log_info "df: $(df -h --output=source,size,used,avail,target | tr '\n' '; ')"; fi
}

# Partition detection helpers for native UEFI Sonic sticks
# These functions dynamically detect partitions by label/type instead of assuming partition numbers

detect_esp_partition() {
  # Find the ESP boot partition (fat32 with ESP label)
  # Returns empty string if not found (not an error - caller handles it)
  local device="$1"
  local part
  for part in "${device}"*[0-9]; do
    if [ -b "$part" ]; then
      local label=$(blkid -s LABEL -o value "$part" 2>/dev/null || echo "")
      if [ "$label" = "ESP" ]; then
        echo "$part"
        return 0
      fi
    fi
  done
  # Check for nvme partition naming
  for part in "${device}p"*[0-9]; do
    if [ -b "$part" ]; then
      local label=$(blkid -s LABEL -o value "$part" 2>/dev/null || echo "")
      if [ "$label" = "ESP" ]; then
        echo "$part"
        return 0
      fi
    fi
  done
  return 0  # Not an error, just not found
}

detect_sonic_partition() {
  # Find the SONIC data partition (exfat with SONIC label)
  # Returns empty string if not found (not an error - caller handles it)
  local device="$1"
  local part
  for part in "${device}"*[0-9]; do
    if [ -b "$part" ]; then
      local label=$(blkid -s LABEL -o value "$part" 2>/dev/null || echo "")
      if [ "$label" = "SONIC" ]; then
        echo "$part"
        return 0
      fi
    fi
  done
  # Check for nvme partition naming
  for part in "${device}p"*[0-9]; do
    if [ -b "$part" ]; then
      local label=$(blkid -s LABEL -o value "$part" 2>/dev/null || echo "")
      if [ "$label" = "SONIC" ]; then
        echo "$part"
        return 0
      fi
    fi
  done
  return 0  # Not an error, just not found
}

detect_flash_partition() {
  # Returns empty string if not found (not an error - caller handles it)
  local device="$1"
  local part
  for part in "${device}"*[0-9]; do
    if [ -b "$part" ]; then
      local label=$(blkid -s LABEL -o value "$part" 2>/dev/null || echo "")
      if [ "$label" = "FLASH" ]; then
        echo "$part"
        return 0
      fi
    fi
  done
  # Check for nvme partition naming
  for part in "${device}p"*[0-9]; do
    if [ -b "$part" ]; then
      local label=$(blkid -s LABEL -o value "$part" 2>/dev/null || echo "")
      if [ "$label" = "FLASH" ]; then
        echo "$part"
        return 0
      fi
    fi
  done
  return 0  # Not an error, just not found
}

detect_partition_by_label() {
  local label="$1"
  if [[ -z "$label" ]]; then
    return 1
  fi
  local part
  part=$(lsblk -rpo NAME,LABEL 2>/dev/null | awk -v target="$label" '$2==target {print $1; exit}')
  if [[ -n "$part" ]]; then
    echo "$part"
    return 0
  fi
  return 1
}

get_partition_number() {
  # Extract partition number from a partition path
  # Works with both /dev/sdb1 and /dev/nvme0n1p1 formats
  local part="$1"
  if [[ "$part" =~ p([0-9]+)$ ]]; then
    # nvme style: /dev/nvme0n1p1
    echo "${BASH_REMATCH[1]}"
  elif [[ "$part" =~ ([0-9]+)$ ]]; then
    # sd style: /dev/sdb1
    echo "${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

sonic_detect_os() {
  # Align with Wizard OS detection semantics.
  if [[ -f /etc/alpine-release ]]; then
    echo "alpine"
    return 0
  fi
  if command -v apk >/dev/null 2>&1; then
    echo "alpine"
    return 0
  fi
  if [[ -f /etc/os-release ]]; then
    if grep -q "ID=alpine" /etc/os-release || grep -q "ID='alpine'" /etc/os-release; then
      echo "alpine"
      return 0
    fi
    if grep -q "ID=ubuntu" /etc/os-release || grep -q "ID='ubuntu'" /etc/os-release; then
      echo "ubuntu"
      return 0
    fi
  fi
  local uname_out
  uname_out="$(uname -s 2>/dev/null || echo "unknown")"
  case "$uname_out" in
    Darwin) echo "macos" ;;
    Linux) echo "ubuntu" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

sonic_copy() {
  # OS-aware copy helper: prefers rsync when available.
  local src="$1"
  local dest="$2"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --no-perms --no-owner --no-group "$src" "$dest"
    return $?
  fi
  if cp -a "$src" "$dest" 2>/dev/null; then
    return 0
  fi
  cp -R "$src" "$dest"
}
