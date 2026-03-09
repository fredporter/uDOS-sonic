# Vault Device Profile Templates

This folder contains tracked reference device profiles for planning and teaching.

These are example templates, not live runtime state. Copy one into your working
area, adapt fields for your target hardware, then generate and inspect a plan.

## Available Profiles

- `uhome-steam-windows10-dualboot.profile.json`
- `windows10-entertainment-flashpack.profile.json`
- `linux-uhome-single-surface.profile.json`
- `windows10-gaming-single-surface.profile.json`
- `dualboot-minimal-lab.profile.json`
- `rescue-maintenance-stick.profile.json`

## Verification Workflow

1. Validate JSON syntax: `python -m json.tool <profile-file>.json`
2. Compare profile assumptions with `config/sonic-layout.json`
3. Generate a dry-run manifest before any apply operation
