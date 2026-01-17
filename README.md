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
- Select TinyCore, Ubuntu installer, or Alpine from the Ventoy menu
- Mount `/dev/sdb5` for your encrypted SSH/GPG keys

### 4. (Optional) Add Ventoy menu config
```bash
sudo cp config/ventoy/ventoy.json.example /mnt/sonic/ventoy/ventoy.json
# Edit ISO names and submenus as needed
```

## Project Layout

```
sonic-stick/
├── README.md                    # This file
├── LICENSE                      # MIT License
├── .gitignore                   # Excludes large ISO/payloads
├── docs/
│   ├── overview.md              # Project goals & architecture
│   ├── partition-scheme.md      # 5-partition layout + security dongle setup
│   ├── bios.md                  # UEFI/BIOS boot configuration
│   ├── logging.md               # Boot logging & key storage
│   ├── ventoy-config.md         # Menu customization
│   └── runbook-ubuntu.md        # Manual install reference
├── config/
│   └── ventoy/
│       └── ventoy.json.example  # Sample Ventoy menu config
├── scripts/
│   ├── download-payloads.sh     # Fetch ISOs (wget-based)
│   ├── install-ventoy.sh        # Install/upgrade Ventoy
│   ├── reflash-complete.sh      # Full reflash + partitioning workflow
│   └── tinycore-bootlog.sh      # Boot logging hook for TinyCore
├── ISOS/                        # (empty; populated by download script)
│   ├── Ubuntu/
│   ├── Rescue/
│   └── Minimal/
├── RaspberryPi/                 # (empty; populated by download script)
└── TOOLS/                       # (empty; populated by download script)
```

## Requirements

**To build the stick:**
- Ubuntu 22.04 LTS or similar (tested on noble)
- sudo access
- wget (for downloads)
- GParted (for partitioning)
- ~150 GB free disk space (for downloads)

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
