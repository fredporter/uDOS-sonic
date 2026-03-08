# Lesson 02 - Build And Dry-Run

The standard safe workflow is:

1. generate a manifest
2. inspect the manifest
3. run dry-run for the apply layer
4. only then execute real writes

Core commands:

```bash
python3 apps/sonic-cli/cli.py plan \
  --usb-device /dev/sdb \
  --dry-run \
  --layout-file config/sonic-layout.json \
  --out memory/sonic/sonic-manifest.json

bash scripts/sonic-stick.sh \
  --manifest memory/sonic/sonic-manifest.json \
  --dry-run
```

This workflow is the core educational habit Sonic should teach:

- inspect first
- apply second
- never collapse planning and destruction into one invisible step
