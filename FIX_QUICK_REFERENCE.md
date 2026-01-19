# Quick Reference - Fixing Your Sonic Stick

## The Problem
Your USB shows: **"not a standard ventoy"** ❌

## The Solution (Choose One)

### **Option 1: Automatic Fix (RECOMMENDED)** ⭐
```bash
sudo bash scripts/fix-ventoy-stick.sh
```
✅ Diagnoses and fixes automatically  
✅ Offers 3 repair options  
✅ Most reliable  

### **Option 2: From Main Menu**
```bash
sudo bash scripts/sonic-stick.sh
```
Then select: **7) Fix 'not a standard ventoy' error**

### **Option 3: Full Rebuild** (Nuclear option)
```bash
sudo bash scripts/reflash-complete.sh
```
⚠️ Erases entire USB, rebuilds from scratch  

## What Each Option Does

| Option | What It Does | Time | Best For |
|--------|------------|------|----------|
| Auto Fix | Diagnoses problem, offers repairs | 5-15 min | Most issues |
| Main Menu | Same as auto fix, integrated | 5-15 min | Easy access |
| Full Rebuild | Wipes USB, installs fresh Ventoy | 15-30 min | Corrupted stick |

## After Fixing

1. **Reboot with USB inserted**
2. **Press F12 or ESC** at startup
3. **Select USB from boot menu**
4. **You should see Ventoy menu** ✅

## Still Not Working?

### Check BIOS Boot Order
- Reboot, enter BIOS (F2, DEL, or F10)
- Set USB as **first boot device**
- Save and exit

### Try Different USB Port
- USB 3.0 ports work best
- Avoid USB-C adapters
- Try the stick in different ports

### Check USB Health
```bash
sudo bash scripts/fix-ventoy-stick.sh
# Select option 1 (Full Reinstall) if others fail
```

### Get Support
```bash
# Collect debug logs
sudo bash scripts/collect-logs.sh

# Check logs
tail -f LOGS/fix-ventoy-stick.log
```

## Technical Info

**What was fixed:**
- ✅ Ventoy installation validation
- ✅ ventoy.json configuration simplified
- ✅ JSON syntax validation added
- ✅ Automatic fallback configs
- ✅ Better error messages

**Files you updated:**
- `scripts/fix-ventoy-stick.sh` (NEW)
- `scripts/install-ventoy.sh` (improved)
- `scripts/reflash-complete.sh` (improved)
- `scripts/sonic-stick.sh` (added fix option)
- `config/ventoy/ventoy.json` (simplified)
- `docs/fix-ventoy-error.md` (NEW - detailed guide)

## Need More Info?

Read the full guide:
```bash
cat docs/fix-ventoy-error.md
```

Or the technical summary:
```bash
cat VENTOY_FIX_SUMMARY.md
```

---

**TL;DR:** Run `sudo bash scripts/fix-ventoy-stick.sh` and reboot! 🚀
