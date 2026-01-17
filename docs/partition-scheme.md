# 5-Partition Scheme

This document details the complete USB stick layout and security dongle setup.

## Partition Table

| Part | Device | Size | Type | Label | Purpose |
|------|--------|------|------|-------|---------|
| 1 | sdb1 | 32 MB | EFI | Ventoy | Boot firmware |
| 2 | sdb2 | ~82 GB | exFAT | SONIC | ISOs, tools, logs |
| 3 | sdb3 | 16 GB | ext4 | TCE | TinyCore persistence |
| 4 | sdb4 | 8 GB | linux-swap | SONIC_SWAP | Virtual RAM |
| 5 | sdb5 | 2 GB | ext4 | DONGLE | Keys vault (optional LUKS) |

**Total:** 128 GB (adjust sizes for smaller sticks)

## Creating Partitions (GParted)

### Prerequisites
```bash
sudo apt install gparted
sudo gparted /dev/sdb &
```

### Steps

1. **Shrink Partition 2 (exFAT)**
   - Right-click `sdb2` → Resize
   - Set to **82 GB** (leaves ~46 GB for new partitions)
   - Apply changes

2. **Create TCE Partition (sdb3)**
   - Right-click unallocated space → New
   - Size: **16 GB**
   - Filesystem: **ext4**
   - Label: **TCE**
   - Create

3. **Create SWAP Partition (sdb4)**
   - Right-click unallocated → New
   - Size: **8 GB**
   - Filesystem: **linux-swap**
   - Label: **SONIC_SWAP**
   - Create

4. **Create DONGLE Partition (sdb5)**
   - Right-click unallocated → New
   - Size: **2 GB** (remaining space)
   - Filesystem: **ext4**
   - Label: **DONGLE**
   - Create

5. **Apply all changes** (GParted → Edit → Apply All Operations)

### Verify
```bash
lsblk /dev/sdb
# Should show 5 partitions with correct sizes and labels
```

## Security Dongle Setup

The DONGLE partition (`sdb5`, 2 GB, label: DONGLE) stores sensitive data.

### Option 1: Plain ext4 (Simple)

```bash
# Mount DONGLE
sudo mkdir -p /mnt/dongle
sudo mount /dev/sdb5 /mnt/dongle

# Create directories
sudo mkdir -p /mnt/dongle/{keys,certs,bios}

# Copy SSH keys
sudo cp ~/.ssh/id_rsa /mnt/dongle/keys/
sudo cp ~/.ssh/id_rsa.pub /mnt/dongle/keys/
sudo chmod 400 /mnt/dongle/keys/id_rsa

# Copy GPG keyring
sudo cp -r ~/.gnupg /mnt/dongle/certs/

# Optional: BIOS backup
# (After boot test, copy BIOS update files here)

# Unmount
sudo umount /mnt/dongle
```

### Option 2: LUKS Encryption (Recommended for sensitive keys)

```bash
# Format with LUKS
sudo cryptsetup luksFormat /dev/sdb5
# Enter passphrase (remember it!)

# Open encrypted volume
sudo cryptsetup luksOpen /dev/sdb5 dongle-crypt
# Enter passphrase

# Create ext4 filesystem
sudo mkfs.ext4 -L DONGLE /dev/mapper/dongle-crypt

# Mount encrypted volume
sudo mkdir -p /mnt/dongle
sudo mount /dev/mapper/dongle-crypt /mnt/dongle

# Create subdirectories
sudo mkdir -p /mnt/dongle/{keys,certs,bios}
sudo chown $(id -u):$(id -g) /mnt/dongle/{keys,certs,bios}

# Copy sensitive data
cp ~/.ssh/id_rsa /mnt/dongle/keys/
cp -r ~/.gnupg /mnt/dongle/certs/

# Unmount
sudo umount /mnt/dongle
sudo cryptsetup luksClose dongle-crypt
```

### Auto-Mount DONGLE on Boot (Optional)

Edit `/etc/fstab` to auto-mount DONGLE at startup:

```bash
# Plain ext4
/dev/sdb5  /mnt/dongle  ext4  defaults,nofail  0  2

# LUKS encrypted (requires passphrase entry or keyfile)
/dev/mapper/dongle-crypt  /mnt/dongle  ext4  defaults,nofail  0  2
```

## TCE Persistence

TinyCore can save packages and config to the TCE partition:

```bash
# Boot TinyCore from USB
# Mount TCE partition
sudo mkdir -p /media/TCE
sudo mount /dev/sdb3 /media/TCE

# Install packages (persists to TCE)
tce-load -iw package-name
filetool.sh -b  # Backup on shutdown

# Verify TCE mount
mount | grep TCE
```

## SWAP Usage

The SONIC_SWAP partition (`sdb4`, 8 GB) provides virtual RAM:

```bash
# Enable swap after boot
sudo swapon /dev/sdb4

# Check swap status
swapon -s
free -h
```

On systems with low RAM (< 2 GB), enable swap to prevent OOM kills:
```bash
# Add to /etc/fstab for auto-enable
/dev/sdb4  none  swap  sw  0  0
```

## Troubleshooting

**"Can't shrink exFAT"**
- Unmount the partition first: `sudo umount /dev/sdb2`
- Ensure no files are in use (close file manager)

**"GParted won't apply changes"**
- All partitions must be unmounted
- Some USB sticks need a reboot after unmounting
- Try: `sudo umount /dev/sdb*` before applying

**"LUKS passphrase not working"**
- Ensure Caps Lock is OFF
- Try: `sudo cryptsetup luksChangeKey /dev/sdb5` to reset passphrase

**"TCE mount fails"**
- Verify partition exists: `lsblk | grep sdb3`
- Check filesystem: `sudo fsck -n /dev/sdb3`
- If corrupted: `sudo mkfs.ext4 -L TCE /dev/sdb3`

## Backing Up DONGLE

To back up encrypted DONGLE:

```bash
# Create backup image
sudo cryptsetup luksOpen /dev/sdb5 dongle-crypt
sudo dd if=/dev/mapper/dongle-crypt of=~/sonic-dongle-backup.img bs=4M

# Restore from backup
sudo dd if=~/sonic-dongle-backup.img of=/dev/mapper/dongle-crypt bs=4M
sudo cryptsetup luksClose dongle-crypt
```

---

**See also:** [Logging & Key Vault](logging.md) | [Overview](overview.md)
