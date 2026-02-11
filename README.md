# uDOS Sonic Screwdriver v1.0.1.0

Sonic Screwdriver is a Linux-only USB build system for multi-boot sticks.
It separates planning (Core) from execution (Bash) so destructive operations are explicit,
reviewable, and OS-aware.

## Principles

- Core plans, validates, and writes a manifest.
- Bash executes disk operations only on Linux.
- Dry-run is supported for inspection before changes.
- v1.1.0+ targets a custom multi-partition layout (Ventoy-free).

## Quick Start (Linux)

1) Generate a manifest:
```bash
python3 core/sonic_cli.py plan --usb-device /dev/sdb --ventoy-version 1.1.10
```

2) Run the launcher (reads the manifest):
```bash
bash scripts/sonic-stick.sh --manifest config/sonic-manifest.json
```

Dry-run:
```bash
python3 core/sonic_cli.py plan --usb-device /dev/sdb --dry-run
bash scripts/sonic-stick.sh --manifest config/sonic-manifest.json --dry-run
```

## OS Support

- Supported: Linux (Ubuntu/Debian/Alpine)
- Unsupported: macOS, Windows (build operations)

## Layout

```
sonic/
├── core/                   # Planning and validation (Python)
├── scripts/                # Execution layer (Bash, Linux-only)
├── config/                 # Ventoy + manifest configuration
├── docs/                   # Specs, howto, devlog
├── LOGS/                   # Local logs
└── version.json            # Sonic version metadata
```

## Docs

- docs/specs/sonic-screwdriver-v1.0.1.md
- docs/specs/sonic-screwdriver-v1.1.0.md
- ../docs/ROADMAP.md
- docs/howto/build-usb.md
- docs/howto/dry-run.md
- docs/devlog/2026-01-24-sonic-v1.0.1.md
- docs/.archive/ (legacy Sonic Stick docs)

## Safety Notes

- All destructive operations require sudo and explicit confirmation.
- Always verify target device before running rebuild scripts.
