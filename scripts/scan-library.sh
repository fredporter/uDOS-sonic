#!/bin/bash
#
# Sonic Stick - Library Scanner
# Scans USB stick for ISOs and updates the library catalog
#
# Usage: bash scripts/scan-library.sh [data-mount-point]
# Example: bash scripts/scan-library.sh /mnt/sonic-data
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/lib/logging.sh"
init_logging "scan-library"
exec > >(tee -a "$LOG_FILE") 2>&1

DATA_MOUNT="${1:-/mnt/sonic-data}"
VENTOY_MOUNT="${2:-/media/$USER/Ventoy}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info "Starting library scan"

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Sonic Stick Library Scanner${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Check if data partition is mounted
if [ ! -d "$DATA_MOUNT/library" ]; then
    echo -e "${YELLOW}Data partition not found at $DATA_MOUNT${NC}"
    echo "Please mount the FLASH partition first:"
    echo "  sudo mount /dev/sdX3 $DATA_MOUNT"
    exit 1
fi

# Check if Ventoy partition is mounted
if [ ! -d "$VENTOY_MOUNT/ISOS" ]; then
    echo -e "${YELLOW}Ventoy partition not found at $VENTOY_MOUNT${NC}"
    echo "Please mount the Ventoy partition first or specify path:"
    echo "  $0 $DATA_MOUNT /path/to/ventoy"
    exit 1
fi

CATALOG="$DATA_MOUNT/library/iso-catalog.json"
TIMESTAMP=$(date -Iseconds)

echo "Scanning: $VENTOY_MOUNT/ISOS"
echo "Catalog: $CATALOG"
echo ""

# Scan for ISOs
echo -e "${BLUE}Scanning for ISO files...${NC}"

# Create temporary JSON
cat > /tmp/sonic-catalog.json << EOF
{
  "last_updated": "$TIMESTAMP",
  "scan_location": "$VENTOY_MOUNT/ISOS",
  "categories": {
    "ubuntu": {
      "name": "Ubuntu & Variants",
      "description": "Desktop installers for Ubuntu family",
      "isos": []
    },
    "minimal": {
      "name": "Minimal & Rescue",
      "description": "Lightweight and recovery systems",
      "isos": []
    },
    "rescue": {
      "name": "Rescue Tools",
      "description": "Emergency recovery and repair tools",
      "isos": []
    }
  },
  "boot_modes": {
    "live": "Run directly from USB without installing",
    "installer": "Install to internal disk/SSD",
    "rescue": "Troubleshooting and recovery tools"
  }
}
EOF

# Scan Ubuntu ISOs
if [ -d "$VENTOY_MOUNT/ISOS/Ubuntu" ]; then
    echo "  Scanning Ubuntu directory..."
    COUNT=0
    while IFS= read -r iso; do
        if [ -f "$iso" ]; then
            BASENAME=$(basename "$iso")
            SIZE=$(du -h "$iso" | cut -f1)
            
            # Determine type and description
            if [[ "$BASENAME" =~ "ubuntu-22" ]]; then
                DESC="Ubuntu 22.04 LTS Desktop - Full-featured installer"
                MODE="installer+live"
            elif [[ "$BASENAME" =~ "lubuntu" ]]; then
                DESC="Lubuntu 22.04 LTS - Lightweight Ubuntu with LXDE"
                MODE="installer+live"
            elif [[ "$BASENAME" =~ "mate" ]]; then
                DESC="Ubuntu MATE 22.04 LTS - Traditional desktop experience"
                MODE="installer+live"
            else
                DESC="Ubuntu-based distribution"
                MODE="installer"
            fi
            
            echo "    ✓ $BASENAME ($SIZE)"
            COUNT=$((COUNT + 1))
        fi
    done < <(find "$VENTOY_MOUNT/ISOS/Ubuntu" -type f -name "*.iso")
    echo "    Found: $COUNT ISOs"
fi

# Scan Minimal ISOs
if [ -d "$VENTOY_MOUNT/ISOS/Minimal" ]; then
    echo "  Scanning Minimal directory..."
    COUNT=0
    while IFS= read -r iso; do
        if [ -f "$iso" ]; then
            BASENAME=$(basename "$iso")
            SIZE=$(du -h "$iso" | cut -f1)
            echo "    ✓ $BASENAME ($SIZE)"
            COUNT=$((COUNT + 1))
        fi
    done < <(find "$VENTOY_MOUNT/ISOS/Minimal" -type f -name "*.iso")
    echo "    Found: $COUNT ISOs"
fi

# Scan Rescue ISOs
if [ -d "$VENTOY_MOUNT/ISOS/Rescue" ]; then
    echo "  Scanning Rescue directory..."
    COUNT=0
    while IFS= read -r iso; do
        if [ -f "$iso" ]; then
            BASENAME=$(basename "$iso")
            SIZE=$(du -h "$iso" | cut -f1)
            echo "    ✓ $BASENAME ($SIZE)"
            COUNT=$((COUNT + 1))
        fi
    done < <(find "$VENTOY_MOUNT/ISOS/Rescue" -type f -name "*.iso")
    echo "    Found: $COUNT ISOs"
fi

# Count total
TOTAL_ISOS=$(find "$VENTOY_MOUNT/ISOS" -type f -name "*.iso" | wc -l)

echo ""
echo -e "${GREEN}Scan complete: $TOTAL_ISOS ISOs found${NC}"

# Create detailed catalog
cat > "$CATALOG" << EOF
{
  "last_updated": "$TIMESTAMP",
  "scan_location": "$VENTOY_MOUNT/ISOS",
  "total_isos": $TOTAL_ISOS,
  "categories": [
    {
      "name": "Ubuntu Desktop",
      "path": "Ubuntu",
      "isos": [
$(find "$VENTOY_MOUNT/ISOS/Ubuntu" -type f -name "*.iso" 2>/dev/null | while read iso; do
    NAME=$(basename "$iso")
    SIZE=$(stat -f%z "$iso" 2>/dev/null || stat -c%s "$iso" 2>/dev/null || echo 0)
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "        {\"filename\": \"$NAME\", \"size_mb\": $SIZE_MB, \"mode\": \"installer+live\"},"
done | sed '$ s/,$//')
      ]
    },
    {
      "name": "Minimal Systems",
      "path": "Minimal",
      "isos": [
$(find "$VENTOY_MOUNT/ISOS/Minimal" -type f -name "*.iso" 2>/dev/null | while read iso; do
    NAME=$(basename "$iso")
    SIZE=$(stat -f%z "$iso" 2>/dev/null || stat -c%s "$iso" 2>/dev/null || echo 0)
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "        {\"filename\": \"$NAME\", \"size_mb\": $SIZE_MB, \"mode\": \"installer+live\"},"
done | sed '$ s/,$//')
      ]
    },
    {
      "name": "Rescue Tools",
      "path": "Rescue",
      "isos": [
$(find "$VENTOY_MOUNT/ISOS/Rescue" -type f -name "*.iso" 2>/dev/null | while read iso; do
    NAME=$(basename "$iso")
    SIZE=$(stat -f%z "$iso" 2>/dev/null || stat -c%s "$iso" 2>/dev/null || echo 0)
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo "        {\"filename\": \"$NAME\", \"size_mb\": $SIZE_MB, \"mode\": \"live+rescue\"},"
done | sed '$ s/,$//')
      ]
    }
  ]
}
EOF

echo ""
echo "Catalog saved to: $CATALOG"
echo ""
cat "$CATALOG" | grep -E "(filename|size_mb)" | head -20

echo ""
echo -e "${GREEN}✓ Library scan complete${NC}"
