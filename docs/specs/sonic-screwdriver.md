# Sonic Provisioning Contract

Status: Active
Updated: 2026-03-08

## Purpose

Define `uDOS-sonic` as the current standalone provisioning layer for
profile-aware installs, with explicit alignment to the canonical `uHOME`
runtime and Wizard-managed networking.

Key goals:

- provide a standalone, decoupleable provisioning utility
- materialize profile-aware install layouts and staged bundles
- preserve `uHOME Server` and `uHOME TV Node` rollout support in the current release lane
- support thin-GUI and Steam-console presentation packaging for `uHOME`
- hand off managed networking and control-plane behavior to Wizard
- keep device database and launch-profile data deterministic

---

## Standalone Contract

Sonic Screwdriver should run in isolation from uDOS:
- Own repo + docs + datasets + release artifacts.
- Optional integration hooks for uDOS/Wizard/App.
- No dependency on uDOS internals for basic partition/build operations.

---

## Install lanes

Sonic provides two active install lanes:

- standalone bundle handoff
- USB or image install

The standalone bundle handoff is the canonical `uHOME Server` lane from the
Sonic side.
The USB or image lane remains valid for profile-aware node rollout, including
`uHOME TV Node`.

Both lanes may be used for:

- standalone Sonic distribution
- standalone `uHOME` distribution
- combined Sonic + `uHOME` distribution

## USB or image layout contract

The USB or image lane uses:

- `config/sonic-layout.json`
- `config/sonic-manifest.json.example`
- `memory/sonic/`
- `distribution/`
- `apps/sonic-cli/cli.py`
- `services/`
- `scripts/partition-layout.sh`
- `scripts/apply-payloads-v2.sh`
- `scripts/sonic-stick.sh`

The default layout remains a profile-capable multi-partition GPT layout. Layout
values may be adjusted through `config/sonic-layout.json` and the Sonic CLI.

Rules:

- layouts remain profile-aware
- install manifests must be reviewable before execution
- run steps are destructive and must be treated as explicit execution
- layout-driven installs may bootstrap a node for later Wizard enrollment, but
  may not define a separate Sonic runtime protocol
- layouts may package thin GUI, Steam-console UX, or both for the target node

## `uHOME` bundle contract ownership

The canonical `uHOME` bundle lane is owned by `uHOME-server`, not by
`uDOS-sonic`.

Canonical sources live in the sibling `uHOME-server` repo under:

- `src/uhome_server/sonic/uhome_bundle.py`
- `src/uhome_server/sonic/uhome_installer.py`
- `src/uhome_server/sonic/uhome_preflight.py`

Sonic should consume those artifacts and contracts as external dependencies
rather than keeping a local compatibility copy.

Bundle responsibilities:

- preflight hardware validation
- artifact manifest verification
- staged install plan generation
- config and enable steps
- rollback token support where provided

Current canonical component family for `uHOME` bundle installs:

- `jellyfin`
- `comskip`
- `hdhomerun_config`
- `udos_uhome`

## Wizard networking alignment

Sonic provisions nodes. Wizard owns ongoing network-aware control.

For the current release lane:

- Sonic may bootstrap a `uHOME` node for LAN use or later enrollment
- Wizard owns `/api/beacon/*` and `/api/ha/*`
- beacon configuration, tunnel state, and node control remain Wizard-managed
- baseline `uHOME` must still work LAN-local without beacon or VPN setup
- Sonic and `uHOME` may be shipped without the full `uDOS/core` runtime package
  set when used as standalone distributions

## Device and launch-profile data

Sonic device and launch-profile data remain valid inputs for:

- hardware-aware install guidance
- profile selection
- launcher and UI bundle planning where those surfaces are active

These records must not redefine the `uHOME` runtime scope.

## Presentation packaging

Sonic may provision the following `uHOME` presentation combinations:

- thin GUI only
- Steam-console only
- thin GUI plus Steam-console

These remain presentation-layer choices over the same `uHOME` install and node
contracts.

## Non-goals

- no separate Sonic-owned runtime networking protocol
- no mandatory Windows gaming or dual-boot requirement for `uHOME`
- no cloud dependency in the core provisioning lane

## Related documents

- `docs/integration-spec.md`
- external current `uHOME` runtime spec in `uHOME-server`
- Wizard beacon implementation docs in their owning repo
