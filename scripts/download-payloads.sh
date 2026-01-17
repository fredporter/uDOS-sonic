#!/bin/bash
#
# Sonic Stick Download Payloads Script
# Downloads all ISO and Raspberry Pi images for the Sonic Stick project
# Uses wget with resume capability (wget -c)
#
# Usage: bash scripts/download-payloads.sh
#

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$BASE_DIR/TOOLS"
ISOS_DIR="$BASE_DIR/ISOS"
RASPI_DIR="$BASE_DIR/RaspberryPi"

# Create directories
mkdir -p "$TOOLS_DIR" "$ISOS_DIR/Minimal" "$ISOS_DIR/Rescue" "$ISOS_DIR/Ubuntu" "$RASPI_DIR"

echo "Sonic Stick download starting"
echo "Base directory: $BASE_DIR"
echo ""

# Define all downloads as an associative array
# Format: "destination|url"
declare -a DOWNLOADS=(
  "$TOOLS_DIR/ventoy-1.0.98-linux.tar.gz|https://github.com/ventoy/Ventoy/releases/download/v1.0.98/ventoy-1.0.98-linux.tar.gz"
  "$ISOS_DIR/Rescue/CorePure64-15.0.iso|http://tinycorelinux.net/15.x/x86_64/release/CorePure64-15.0.iso"
  "$ISOS_DIR/Minimal/alpine-standard-3.19.1-x86_64.iso|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-standard-3.19.1-x86_64.iso"
  "$RASPI_DIR/raspios-bookworm-arm64-lite.img.xz|https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz"
  "$RASPI_DIR/ubuntu-22.04.5-preinstalled-server-arm64+raspi.img.xz|https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-preinstalled-server-arm64+raspi.img.xz"
  "$RASPI_DIR/DietPi_RPi234-ARMv8-Bookworm.img.xz|https://dietpi.com/downloads/images/DietPi_RPi234-ARMv8-Bookworm.img.xz"
  "$ISOS_DIR/Ubuntu/ubuntu-22.04.5-desktop-amd64.iso|https://releases.ubuntu.com/jammy/ubuntu-22.04.5-desktop-amd64.iso"
  "$ISOS_DIR/Ubuntu/lubuntu-22.04.5-desktop-amd64.iso|https://cdimage.ubuntu.com/lubuntu/releases/jammy/release/lubuntu-22.04.5-desktop-amd64.iso"
  "$ISOS_DIR/Ubuntu/ubuntu-mate-22.04.5-desktop-amd64.iso|https://cdimage.ubuntu.com/ubuntu-mate/releases/jammy/release/ubuntu-mate-22.04.5-desktop-amd64.iso"
)

echo "Planned downloads (${#DOWNLOADS[@]}):"
for i in "${!DOWNLOADS[@]}"; do
  IFS='|' read -r dest url <<< "${DOWNLOADS[$i]}"
  printf "  [%02d] %s\n" $((i+1)) "$dest"
  printf "       %s\n" "$url"
done
echo ""

# Download each file
total=${#DOWNLOADS[@]}
for i in "${!DOWNLOADS[@]}"; do
  IFS='|' read -r dest url <<< "${DOWNLOADS[$i]}"
  current=$((i+1))
  
  filename=$(basename "$dest")
  echo "[$current/$total] Downloading: $filename"
  echo "    URL: $url"
  
  # Use wget with resume (-c) capability
  if wget -c "$url" -O "$dest" 2>&1 | tail -5; then
    echo "    ✓ Complete"
  else
    echo "    ✗ Failed (check network and URL)"
    exit 1
  fi
  echo ""
done

echo "==================================="
echo "All downloads complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Plug in your USB stick (label it SONIC)"
echo "  2. Run: sudo bash scripts/reflash-complete.sh"
echo "  3. Follow prompts to install Ventoy and partition the stick"
echo ""
