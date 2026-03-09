# Sonic Vault

`vault/` is the tracked Markdown-first learning and example layer for Sonic.

This is not the runtime state directory. Runtime artifacts, logs, databases,
and generated manifests still belong under `memory/sonic/`.

Use `vault/` for tracked, educational, and example-first material only.

## Structure

- `templates/`: reusable templates and profile examples
- `manifests/`: reference deployment manifests for review practice
- `deployment-notes/`: worked examples, canary notes, and retrospectives

## Quick Start

1. Choose a profile template from `templates/device-profiles/`
2. Copy and adapt it for your target hardware
3. Generate a dry-run manifest and compare with `manifests/` references
4. Record findings in `deployment-notes/`

## Refresh Cadence

- Review template and manifest examples each release cycle (`v1.x`)
- Update examples whenever partition contracts or boot targets change
- Keep references aligned with `config/sonic-layout.json` and flash packs
