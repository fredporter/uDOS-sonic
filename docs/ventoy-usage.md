# What's Running? A Guide to Your Sonic Stick ISOs

This clarifies **what boots from the USB** vs **what installs to your system disk**.

## Three Types

### 🟢 LIVE (Runs entirely from USB, nothing permanent)
- **Alpine Linux 3.19.1**
  - Boots into a live Linux shell
  - Everything runs in RAM
  - To install Alpine to your disk: type `setup-alpine` at boot
  - No changes persist after reboot (unless you install)

### 🔴 INSTALLER (Boots installer, installs to your system disk)
- **Ubuntu 22.04 LTS Desktop** ✅ Tested working
  - Boots into installer
  - **Choose "Install Ubuntu"** from the Ventoy menu (if prompted)
  - Installer asks where to install (select your system disk, NOT the USB)
  - When done: reboot and remove USB → Ubuntu boots from your system disk
  - Next boot: Ubuntu runs from your system disk (USB not needed)
  
- **Lubuntu 22.04 LTS** ⚠️ Works but needs WiFi
  - Same as Ubuntu, but lightweight
  - Requires internet connection during install
  - If no WiFi: get a USB WiFi adapter or use Ethernet
  
- **Ubuntu MATE 22.04 LTS** ✅ Tested working
  - Same as Ubuntu, MATE desktop instead of GNOME
  - Works well, should boot normally after install

### ❓ TINYCORE (Live, but has UEFI boot issue)
- **TinyCore 15.0**
  - "Error: no bootfile for UEFI" — known issue
  - Solution: See [Troubleshooting](#troubleshooting) below

---

## After Installing (How to Boot Your New OS)

### Scenario 1: You installed Ubuntu/Lubuntu/Ubuntu MATE

**After reboot:**
1. Remove the Sonic Stick from USB
2. Reboot your machine
3. **Your installed Ubuntu now boots automatically** (it's on your system disk)
4. You can plug the USB stick back in anytime to boot other ISOs

**To verify it's installed:**
```bash
lsblk
# You should see your system disk (e.g., /dev/nvme0n1 or /dev/sda)
# with Ubuntu partitions on it, not on sdb (the USB)
```

### Scenario 2: You want to boot the USB again
1. Insert Sonic Stick
2. Reboot
3. Press **F12** (or ESC) at startup to get boot menu
4. Select **USB / Ventoy**
5. Ventoy menu appears

### Scenario 3: You booted Alpine (live)
- **If you didn't run `setup-alpine`:**
  - Reboot, remove USB → your original OS boots
  - Alpine changes are lost
  
- **If you ran `setup-alpine`:**
  - Alpine is now installed to your system disk
  - Next boot (after removing USB): Alpine starts
  - Changes persist

---

## Clearing Things Up

**Q: "Is the OS running from the USB stick?"**
- **Live ISOs (Alpine):** YES, runs entirely from USB
- **Installers (Ubuntu/Lubuntu/MATE):** NO, installs to your system disk after boot

**Q: "Can I install multiple OSes?"**
- Not with this workflow—installers overwrite each other
- But you can use the USB stick to rescue/repair any installed OS

**Q: "Why did Ubuntu MATE crash at the end?"**
- Possible disk write error or power issue
- Likely still installed (check by removing USB and rebooting)
- If it didn't finish: run the installer again to complete setup

**Q: "Why no WiFi on Lubuntu?"**
- Live environment doesn't have all drivers
- **Solution:** Use Ethernet cable + USB adapter, or bring up WiFi manually:
  ```bash
  nmcli dev wifi list
  nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASS"
  ```

---

## Troubleshooting

### TinyCore: "Error: no boot file for UEFI"
**Issue:** TinyCore CorePure64 has issues with some UEFI firmware

**Solutions:**
1. **Disable Secure Boot** in BIOS:
   - Reboot, press F2 / Del / F10 (depending on manufacturer)
   - Find "Secure Boot" → Disable
   - Save and exit
   - Try TinyCore again

2. **Or skip TinyCore**, use Alpine instead (works on all systems)

3. **Or use 32-bit TinyCore** (download separately if needed)

### Ubuntu/Lubuntu installer can't find WiFi
1. Plug in Ethernet cable (easiest)
2. Or use USB WiFi adapter (install driver if needed)
3. Or skip WiFi:
   - Installer might work without internet (for offline packages)
   - You can set up WiFi after installation completes

### Ubuntu MATE "died" at end of install
1. **Likely still installed!**
   - Remove USB stick, reboot
   - See if Ubuntu MATE boots

2. **If it didn't boot:**
   - Insert USB stick, reboot to Ventoy
   - Boot Ubuntu MATE installer again
   - This time choose "Repair Installation" if offered
   - Or reinstall from scratch

### Installed OS won't boot after remove USB
**Issue:** BIOS still set to USB first, or installer didn't finish

**Solutions:**
1. Reboot, press F12 → select your **system disk** (not USB)
2. Or go into BIOS, set system disk to boot first
3. If still failing: boot USB stick again, run installer to completion

---

## Next Steps

### To customize the Ventoy menu:
```bash
# Copy the example config to the USB stick
sudo mkdir -p /mnt/sonic
sudo mount /dev/sdb2 /mnt/sonic
sudo mkdir -p /mnt/sonic/ventoy
sudo cp config/ventoy/ventoy.json.example /mnt/sonic/ventoy/ventoy.json

# Edit it:
sudo nano /mnt/sonic/ventoy/ventoy.json

# Save and reboot—menu updates automatically!
sudo umount /mnt/sonic
```

### To add more ISOs:
```bash
sudo mount /dev/sdb2 /mnt/sonic
# Copy new ISO files to /mnt/sonic/ISOS/
sudo cp ~/Downloads/*.iso /mnt/sonic/ISOS/
sudo umount /mnt/sonic
# Reboot—Ventoy finds them automatically!
```

---

**See also:** [Partition Scheme](partition-scheme.md) | [Overview](overview.md)
