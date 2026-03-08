# Dry Run

Status: migration source
Primary learning destination: `courses/02-system-provisioning/lessons/02-build-and-dry-run.md`

Use dry-run to validate device selection and manifest values before any destructive action.

```bash
python3 apps/sonic-cli/cli.py plan --usb-device /dev/sdb --dry-run --layout-file config/sonic-layout.json --out memory/sonic/sonic-manifest.json
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --dry-run

# Native partitioning payload-only dry-run
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --payloads-only --dry-run

# Native payloads dir override dry-run
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --payloads-dir /path/to/payloads --payloads-only --dry-run

# Native payloads without validation (dry-run)
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json --no-validate-payloads --payloads-only --dry-run
```
