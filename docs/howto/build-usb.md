# Build USB (Linux)

Status: active how-to

For `uHOME`-specific bundle, preflight, or staged install contracts, use the
canonical sources in the sibling `uHOME-server` repository. This guide covers
the Sonic-owned USB planning and execution lane.

1) Generate manifest (adjust layout via config/sonic-layout.json):
```bash
python3 apps/sonic-cli/cli.py plan \
  --usb-device /dev/sdb \
  --layout-file config/sonic-layout.json \
  --out memory/sonic/sonic-manifest.json
```

Default profile:
- Linux-side `uHOME` deployment surface with later handoff to `uHOME-server`
- `Windows 10 Gaming` on the Windows side
- controller-first modular navigation metadata for both surfaces

2) Run launcher:
```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json
```

Native UEFI partitioning:
```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json
```

Payload-only (skip partitioning):
```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --payloads-only
```

Skip payloads (partition only):
```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --skip-payloads
```

Override payloads directory:
```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --payloads-dir /path/to/payloads
```

Disable payload validation (escape hatch):
```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --no-validate-payloads
```

3) Add payloads (optional):
- Place uDOS squashfs at `memory/sonic/artifacts/payloads/udos/udos.squashfs`
- Add files to `memory/sonic/artifacts/payloads/windows`, `memory/sonic/artifacts/payloads/media`, `memory/sonic/artifacts/payloads/wizard`, etc.

4) Follow prompts and confirm destructive steps.
