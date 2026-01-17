# Project Overview

## Goals

Sonic Stick is a single, portable USB stick that provides:

1. **Ventoy bootloader** — multiboot 100+ ISOs without re-flashing
2. **Clean rescue environment** — TinyCore, Alpine, Ubuntu all in one menu
3. **Persistent storage** — TinyCore workspace survives reboots
4. **Virtual swap** — run low-memory systems safely
5. **Security dongle** — encrypted partition for keys and configs

## 5-Partition Layout

```
┌─ sdb1: Ventoy EFI (32 MB)
│  └─ Boot firmware for UEFI systems
├─ sdb2: Ventoy Data (exFAT, ~82 GB)
│  └─ ISOs, Ventoy config, boot logs
├─ sdb3: TCE Persistence (ext4, 16 GB)
│  └─ TinyCore persistent storage
├─ sdb4: SONIC_SWAP (linux-swap, 8 GB)
│  └─ Virtual RAM for low-memory machines
└─ sdb5: DONGLE (ext4, 2 GB)
   └─ Encrypted SSH keys, GPG certs, BIOS backups
```

## Repo Layout

- `scripts/` — Automated workflows (download, install, reflash, logging)
- `docs/` — Deep dives (BIOS, partitioning, Ventoy config, logging)
- `config/` — Sample configs (Ventoy menu)
- `ISOS/` — Downloaded desktop & rescue ISOs (excluded from git)
- `RaspberryPi/` — Downloaded RPi images (excluded from git)
- `TOOLS/` — Ventoy binaries (excluded from git)

## Quick Workflow

1. **Download**: `bash scripts/download-payloads.sh`
2. **Install Ventoy**: Automated by `scripts/install-ventoy.sh`
3. **Reflash & Partition**: `sudo bash scripts/reflash-complete.sh`
4. **Boot**: Insert stick, select Ventoy menu entry
5. **Persist**: Mount TCE or DONGLE partitions as needed

## Technologies

- **Ventoy** (v1.0.98) — multiboot bootloader
- **TinyCore 15** — minimal, fast rescue OS
- **Ubuntu 22.04 LTS** — standard desktop + server
- **Alpine Linux 3.19** — lightweight alternative
- **Raspberry Pi images** — prep SD cards on the go
- **LUKS** (optional) — encrypt DONGLE partition

## Security Notes

- **Secure Boot**: Disable in BIOS (Ventoy/TinyCore don't need it)
- **Boot Order**: Ensure USB is first or auto-boot falls back to internal disk
- **DONGLE partition**: Optional LUKS encryption for sensitive keys
- **Logging**: Boot info saved to `/mnt/sdb2/LOGS/boot.log`

## Known Limitations

- UEFI x86_64 only (no BIOS, no ARM desktop)
- Secure Boot must be disabled
- 128 GB USB recommended (can adapt script for smaller sticks)
- ISOs must fit in exFAT partition (file size limit ~4 GB per ISO)

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for bug reports, features, and PRs.
