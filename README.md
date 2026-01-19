# Sonic Stick Pack v1.0.0.0

**The ultimate multiboot rescue + install USB for Linux sysadmins, makers, and tinkerers.**

Sonic Stick is a Ventoy-powered USB toolkit that boots a custom menu offering rescue tools, installers, persistent storage, and a built-in security dongle—all from one 128 GB stick. Keep it in your pocket, plug into any UEFI machine, and get instant access to TinyCore, Ubuntu, Alpine, Raspberry Pi tools, and more.

## What You Get

🚀 **One-stick superpower**
- **Ventoy bootloader** — no re-imaging needed; add/remove ISOs like files
- **Clean menu system** — organized by rescue, installers, and utilities
- **Persistent storage** — TinyCore/uDOS workspace that survives reboots
- **Swap partition** — virtual RAM safety net for low-memory machines
- **Security dongle** — encrypted vault for SSH keys, GPG certs, BIOS configs

💾 **Pre-loaded payloads** (ISOs not included; you download)
- **TinyCore 15** — tiny, fast, ultra-portable
- **Ubuntu 22.04 LTS** + Lubuntu, Ubuntu MATE flavours
- **Alpine Linux** — lightweight rescue environment
- **Raspberry Pi images** — prep SD cards on the go

📋 **Partition layout (128 GB)**
```
Sonic Stick (SONIC label)
├─ Partition 1: Ventoy EFI/Boot (32 MB, auto-created)
├─ Partition 2: Ventoy Data (exFAT, ~82 GB) — ISOs, tools, logs, config
├─ Partition 3: TCE Persistence (ext4, 16 GB) — TinyCore persistent workspace
├─ Partition 4: SONIC_SWAP (8 GB) — virtual RAM for low-memory systems
└─ Partition 5: DONGLE (ext4, 2 GB) — encrypted key vault + BIOS backups
```

## Quick Start

### One-command launcher (Ubuntu)
- Click-to-run: `gnome-terminal -- bash -lc "cd ~/Code/sonic-stick && ./scripts/sonic-stick.sh"`
- CLI: `sudo ./scripts/sonic-stick.sh` (menu to download payloads, install/upgrade Ventoy, reflash, rebuild, scan, collect logs)

### Troubleshooting: "Not a Standard Ventoy" Error?

If you see this error when booting, run the fix script:
```bash
sudo bash scripts/fix-ventoy-stick.sh
```

Or select **option 7** from the main menu. See [docs/fix-ventoy-error.md](docs/fix-ventoy-error.md) for detailed troubleshooting.

### 1. Download payloads (30–60 min)
```bash
bash scripts/download-payloads.sh
```
Fetches TinyCore, Ubuntu, Alpine, RaspberryPi images, and Ventoy. wget resumes partial downloads.

### 2. Reflash & partition USB (on Ubuntu)
```bash
sudo bash scripts/reflash-complete.sh
```
- Installs Ventoy
- Copies ISOs to the stick
- Walks you through GParted to create persistence, swap, and security partitions

### 3. Boot & configure
- Reboot with SONIC stick inserted
- Select from the Ventoy menu:
  - **[LIVE]** Alpine — runs from USB, type `setup-alpine` to install
  - **[INSTALLER]** Ubuntu flavours — installs to your system disk
  - **[IMAGES]** Raspberry Pi images — write to SD cards
- See [docs/ventoy-usage.md](docs/ventoy-usage.md) for what's live vs installer

### 4. Customize the Ventoy menu (optional)
```bash
sudo mkdir -p /mnt/sonic
sudo mount /dev/sdb2 /mnt/sonic
sudo cp config/ventoy/ventoy.json.example /mnt/sonic/ventoy/ventoy.json
sudo nano /mnt/sonic/ventoy/ventoy.json  # Edit menu names & descriptions
sudo umount /mnt/sonic
# Reboot—menu updates automatically!
```

## Project Layout

```
sonic-stick/
├── README.md                    # This file
├── LICENSE                      # MIT License
├── .gitignore                   # Excludes large ISO/payloads
├── docs/
│   ├── overview.md              # Project goals & architecture
│   ├── QUICK-START.md           # Short build walkthrough
│   ├── partition-scheme.md      # Current partitioning plan
│   ├── ventoy-usage.md          # How to boot and navigate Ventoy
│   └── logging-and-debugging.md # How to capture and share logs
├── config/
│   └── ventoy/
│       └── ventoy.json.example  # Sample Ventoy menu config
├── scripts/
│   ├── collect-logs.sh          # Build/boot support bundle collector
│   ├── download-payloads.sh     # Fetch ISOs (wget-based)
│   ├── install-ventoy.sh        # Install/upgrade Ventoy
│   ├── sonic-stick.sh           # Unified launcher/menu (Ubuntu-friendly)
│   ├── reflash-complete.sh      # Full reflash + partitioning workflow
│   ├── rebuild-from-scratch.sh  # Full wipe + rebuild with data partition
│   ├── create-data-partition.sh # Add FLASH partition
│   ├── setup-data-partition-guided.sh # GParted-guided data partition
│   ├── scan-library.sh          # Generate ISO catalog
│   ├── tinycore-bootlog.sh      # Boot logging hook for TinyCore
│   └── lib/logging.sh           # Shared logging helpers
├── ISOS/                        # (empty; populated by download script)
│   ├── Ubuntu/
│   ├── Rescue/
│   └── Minimal/
├── RaspberryPi/                 # (empty; populated by download script)
└── TOOLS/                       # (empty; populated by download script)
```

## Logging & Debugging

- All major scripts now tee output to `LOGS/<script>-<timestamp>.log`. If the stick is mounted, logs are written to `/media/$USER/SONIC/LOGS`; otherwise they land in the repo `LOGS/` folder.
- Turn on shell tracing with `DEBUG=1` (for example `DEBUG=1 sudo bash scripts/reflash-complete.sh`).
- Collect a support bundle after a failing boot: `sudo bash scripts/collect-logs.sh /dev/sdX` (replace `/dev/sdX` with your stick). The bundle includes `lsblk`, `blkid`, `dmesg` tail, Ventoy config/version, and data-partition logs without copying ISOs.
- TinyCore boots can append hardware/dmesg info to the stick via `scripts/tinycore-bootlog.sh`, writing `LOGS/boot.log` (prefers `FLASH` when mounted).
- Details and what to attach when filing issues are in [docs/logging-and-debugging.md](docs/logging-and-debugging.md).

## Requirements

**To build the stick:**
- Ubuntu 22.04 LTS or similar (tested on noble)
- sudo access
- wget (for downloads)
- GParted (for partitioning)
- ~150 GB free disk space (for downloads)
- Ventoy version pinned to 1.1.10 (auto-downloaded by launcher or download script)

**To boot the stick:**
- Any UEFI PC (x86_64)
- 2–4 GB RAM (TinyCore needs less)
- Ventoy supports ~100+ ISOs simultaneously

## Getting Started (TL;DR)

1. **Clone this repo**:
   ```bash
   git clone https://github.com/fredporter/sonic-stick.git
   cd sonic-stick
   ```

2. **Download ISOs:**
   ```bash
   bash scripts/download-payloads.sh
   ```

3. **Plug in USB, then reflash:**
   ```bash
   sudo bash scripts/reflash-complete.sh
   ```

4. **Follow GParted prompts** to shrink exFAT and create 4 extra partitions.

5. **Boot & enjoy!** USB will auto-mount at `/media/$USER/SONIC`.

## Contributing

Found a bug? Want to add a feature? 🙌 See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License — See [LICENSE](LICENSE)

**Created by:** Fred Porter & contributors
