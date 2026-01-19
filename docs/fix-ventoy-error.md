# Fixing "Not a Standard Ventoy" Error

If your Sonic Stick is reporting "not a standard ventoy" when you try to boot, follow these steps to fix it.

## Quick Fix (Recommended)

### Option 1: Use the automatic fix script

```bash
sudo bash scripts/fix-ventoy-stick.sh
```

This script will:
1. Diagnose the problem
2. Offer repair options:
   - **Full reinstall** - Wipe and reinstall everything (recommended if Ventoy is corrupted)
   - **Quick fix** - Just update the ventoy.json configuration
   - **Upgrade** - Update Ventoy version while keeping existing partitions

### Option 2: Use the main launcher menu

```bash
sudo bash scripts/sonic-stick.sh
```

Then select option `7) Fix 'not a standard ventoy' error`

## What Causes This Error?

The "not a standard ventoy" error typically means:

1. **Ventoy not properly installed** - The Ventoy bootloader is missing or corrupted
2. **Missing ventoy.json** - The configuration file isn't on the USB
3. **Invalid JSON syntax** - The ventoy.json has syntax errors
4. **Missing partition structure** - Ventoy partitions weren't created correctly
5. **Wrong BIOS settings** - USB isn't set as first boot device

## Manual Steps (If Scripts Don't Work)

### Step 1: Unmount the USB
```bash
sudo umount /dev/sdb* 2>/dev/null || true
```

### Step 2: Reinstall Ventoy
```bash
sudo bash scripts/install-ventoy.sh
```
When prompted, type `ERASE` to proceed.

### Step 3: Mount and verify
```bash
sudo mkdir -p /mnt/sonic
sudo mount /dev/sdb1 /mnt/sonic
```

### Step 4: Add the configuration
```bash
sudo mkdir -p /mnt/sonic/ventoy
sudo cp config/ventoy/ventoy.json /mnt/sonic/ventoy/
```

### Step 5: Verify the JSON is valid
```bash
python3 -m json.tool /mnt/sonic/ventoy/ventoy.json
```
Should output nothing if valid. If you see errors, use the example instead:
```bash
sudo cp config/ventoy/ventoy.json.example /mnt/sonic/ventoy/ventoy.json
```

### Step 6: Create directory structure
```bash
sudo mkdir -p /mnt/sonic/ISOS/{Ubuntu,Minimal,Rescue}
sudo mkdir -p /mnt/sonic/RaspberryPi
sudo mkdir -p /mnt/sonic/LOGS
```

### Step 7: Unmount and reboot
```bash
sudo umount /mnt/sonic
sudo reboot
```

## Troubleshooting

### Still showing "not a standard ventoy"?

**Check BIOS settings:**
- Reboot and enter BIOS (usually F2, DEL, or F10)
- Set USB as first boot device
- Save and exit

**Check USB port:**
- Try a different USB 3.0 port (not USB-C)
- Some laptops have problematic USB ports

**Check the USB with fdisk:**
```bash
sudo fdisk -l /dev/sdb
```
Should show multiple partitions with "Ventoy" in the labels.

**Check if Ventoy is actually installed:**
```bash
sudo blkid /dev/sdb*
```
Should show labels like "Ventoy" or similar.

### Getting "Mount: unknown filesystem type exfat"?

The Ventoy data partition uses exFAT. Install the driver:
```bash
sudo apt-get install exfat-fuse exfat-utils
```

## Advanced: Verify Ventoy Installation

```bash
# Check partition table
sudo parted -l /dev/sdb

# Check Ventoy magic bytes
sudo dd if=/dev/sdb bs=512 count=4 skip=0 2>/dev/null | hexdump -C | head

# Check for Ventoy signature
sudo strings /dev/sdb* | grep -i "ventoy"
```

## Need More Help?

See the main [README.md](../README.md) and [docs/logging-and-debugging.md](../docs/logging-and-debugging.md) for:
- How to collect support logs
- Full troubleshooting guide
- Community support resources
