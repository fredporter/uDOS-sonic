# uDOS-sonic

`uDOS-sonic` is the deployment and hardware bootstrap pathway for the uDOS repo family.

It is responsible for:

- hardware-aware planning
- USB and image deployment
- manifest generation and verification
- device catalog and compatibility guidance
- portable provisioning and rescue workflows

It is not the canonical owner of the `uHOME` runtime contract.

## Repo Family Boundary

The current repo split is:

- `uDOS` = shared architecture language, Wizard integration, family coordination
- `uDOS-sonic` = deployment, provisioning, hardware bootstrap
- `uHOME-server` = canonical `uHOME` runtime, bundle, preflight, and install-plan contracts

For `uHOME`-specific contracts, the source of truth is the sibling
`uHOME-server` repository, not this one.

## What Sonic Owns

Sonic owns the deployment lane that takes a reviewed profile and applies it to
real hardware:

`take profile -> generate manifest -> verify -> stage payloads -> apply to device`

Current active surfaces in this repo:

- USB plan and run CLI
- standalone HTTP API
- MCP facade over the same service layer
- browser UI for planning and catalog inspection
- device catalog and manifest validation

## What Sonic Does Not Own

Sonic does not own:

- the long-running `uHOME` runtime
- `uHOME` bundle/preflight/install-plan source of truth
- Wizard-managed beacon, Home Assistant, or network control surfaces

This repo no longer carries local `uHOME` bundle contract code. Use the sibling
`uHOME-server` repo directly for `uHOME` bundle, preflight, and install-plan
work.

## Quick Start (Linux)

Generate a plan:

```bash
python3 apps/sonic-cli/cli.py plan \
  --usb-device /dev/sdb \
  --out memory/sonic/sonic-manifest.json
```

Run a dry-run first:

```bash
python3 apps/sonic-cli/cli.py plan \
  --usb-device /dev/sdb \
  --dry-run \
  --out memory/sonic/sonic-manifest.json

bash scripts/sonic-stick.sh \
  --manifest memory/sonic/sonic-manifest.json \
  --dry-run
```

Apply the manifest:

```bash
bash scripts/sonic-stick.sh --manifest memory/sonic/sonic-manifest.json
```

Serve the local API:

```bash
python3 apps/sonic-cli/cli.py serve-api
```

Serve the MCP facade:

```bash
python3 apps/sonic-cli/cli.py serve-mcp
```

## Learning Surfaces

There are now three ways to enter this repo:

- student-facing wiki: [wiki/Home.md](/Users/fredbook/Code/uDOS-sonic/wiki/Home.md)
- guided course ladder: [courses/README.md](/Users/fredbook/Code/uDOS-sonic/courses/README.md)
- reference docs: [docs/README.md](/Users/fredbook/Code/uDOS-sonic/docs/README.md)

Use the wiki for orientation, `courses/` for guided learning, and `docs/` for
implementation details and active contracts.

## Current Runtime Layout

The active runtime now aligns to the public repo structure:

- `apps/sonic-cli/` = operator CLI
- `apps/sonic-ui/` = browser UI
- `services/` = planner, manifest, API, MCP, and runtime service layer
- `modules/` = install-domain architecture surfaces
- `vault/` = tracked templates, manifests, and deployment notes for learners
- `scripts/` = Linux-side execution steps
- `config/` = layout and manifest defaults
- `distribution/` = tracked packaging descriptors and launch assets
- `memory/sonic/` = local runtime state and generated artifacts
- `datasets/` = device catalog sources
- `tests/` = verification coverage

The earlier structure review is kept as a baseline record in
[docs/sonic-structure-assessment-2026-03-08.md](/Users/fredbook/Code/uDOS-sonic/docs/sonic-structure-assessment-2026-03-08.md).

## Current Default Deployment Story

The default standalone profile currently produces a dual-boot disk with:

- a Linux-side `uHOME` surface and handoff path
- a Windows 10 gaming surface
- controller-first launch metadata for both sides

That is one active deployment profile, not the whole identity of the repo.
The broader Sonic role is deployment infrastructure and portable provisioning.

## Key Docs

- provisioning contract: [docs/specs/sonic-screwdriver.md](/Users/fredbook/Code/uDOS-sonic/docs/specs/sonic-screwdriver.md)
- integration boundary: [docs/integration-spec.md](/Users/fredbook/Code/uDOS-sonic/docs/integration-spec.md)
- structure assessment: [docs/sonic-structure-assessment-2026-03-08.md](/Users/fredbook/Code/uDOS-sonic/docs/sonic-structure-assessment-2026-03-08.md)
- USB build how-to: [docs/howto/build-usb.md](/Users/fredbook/Code/uDOS-sonic/docs/howto/build-usb.md)
- dry-run how-to: [docs/howto/dry-run.md](/Users/fredbook/Code/uDOS-sonic/docs/howto/dry-run.md)

## OS Support

- Supported: Linux
- Unsupported for build operations: macOS, Windows

## Safety

- destructive steps require explicit execution
- always verify the target block device
- run dry-run before any real apply
- treat `memory/sonic/` as local runtime state, not canonical tracked source
