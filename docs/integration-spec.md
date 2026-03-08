# Sonic Integration Spec

Status: Active
Updated: 2026-03-08

This document aligns Sonic's public integration story to the active
`uHOME` scope maintained outside this repository.

Sonic's canonical `uHOME` alignment is:

- a tested standalone bundle handoff for `uHOME Server`
- a bounded USB or image lane that can materialize either `uHOME Server`,
  `uHOME TV Node`, or the current dual-boot `uHOME Steam Server + Windows 10 Gaming` disk
- node bootstrap that can hand off to Wizard-managed home-node and beacon
  networking
- packaging that may ship `uHOME` with thin GUI, Steam-console UX, or both
- device-catalog and launch-profile inputs that remain profile-aware rather than
  defining a separate `uHOME` runtime

Older Sonic hybrid-console or media-launcher briefs may remain in the repo as
historical exploration, but they are not the active source of truth.

## 1. Device Database Contract

Sonic Screwdriver publishes its curated device catalog via `wizard.routes.sonic_plugin_routes`. Any Wizard/Sonic bolt-on can consume the same SQLite + Schema artifacts described here and bundle them for CLI/GUI consumers. The Wizard API routes keep the catalog discoverable both from the TUI (`PLUGIN list`) and from remote automation by exposing the same contract documented here.

### Storage
- Seed catalog sources: `datasets/`
- Tracked distribution descriptors: `distribution/`
- Seed runtime DB: `memory/sonic/seed/sonic-devices.seed.db`
- User runtime DB: `memory/sonic/user/sonic-devices.user.db`
- Legacy compatibility mirror: `memory/sonic/sonic-devices.db`
- Local payload library: `memory/sonic/artifacts/payloads/`
- Local download/artifact staging: `memory/sonic/artifacts/`
- Local bolt-ons: `library/sonic/`
- Schema: `datasets/sonic-devices.schema.json`
- Markdown reference table: `datasets/sonic-devices.table.md`
- Seed rebuild source: `datasets/sonic-devices.sql`
- Datasets folder also hosts `sonic-devices.csv` for bulk editing before rebuilding.

Normal-user contract:
- seed catalog is distributed and read-only
- user catalog is local, writable, and overlays seed records at read time
- current-machine bootstrap records live in the user catalog
- both layers may carry `*_template_md` refs

### Key Fields (device record)

| Field | Description |
|---|---|
| `id` | Unique slug (vendor-model-variant) |
| `vendor`, `model`, `variant` | Human identifiers |
| `year`, `cpu`, `gpu`, `ram_gb`, `storage_gb` | Performance profile |
| `bios`, `secure_boot`, `tpm` | Firmware/security capabilities |
| `usb_boot`, `uefi_native`, `reflash_potential` | Sonic/boot readiness |
| `methods` | JSON array, e.g. `["sonic_usb","wizard_netboot"]` |
| `notes`, `sources` | Freeform guidance |
| `last_seen` | Last update timestamp |
| `settings_template_md` | Obsidian-style Markdown template for configurable settings |
| `installers_template_md` | Obsidian-style Markdown template for installer flows |
| `containers_template_md` | Obsidian-style Markdown template for container/service notes |
| `drivers_template_md` | Obsidian-style Markdown template for driver/firmware notes |

### Wizard API Endpoints
- `GET /api/sonic/health` – quick availability summary & rebuild hints.
- `GET /api/sonic/schema` – JSON schema for validation.
- `GET /api/sonic/devices` – paginated catalog with filters: `vendor`, `reflash_potential`, `usb_boot`, `uefi_native`.
- `GET /api/sonic/db/status` – DB sync status alias.
- `POST /api/sonic/db/rebuild` – DB rebuild alias.
- `GET /api/sonic/db/export` – DB export alias.
- `POST /api/sonic/bootstrap/current` – register the current machine in the local user catalog.

Current standalone Sonic runtime in this repository provides the following implemented surfaces:
- `GET /api/sonic/health`
- `GET /api/sonic/gui/summary`
- `GET /api/sonic/devices`
- `GET /api/sonic/db/status`
- `POST /api/sonic/db/rebuild`
- `GET /api/sonic/db/export`
- `GET /api/sonic/manifest/verify`
- `POST /api/sonic/plan`

Wizard-compatible aliases are also exposed under `/api/platform/sonic/*` for the routes above where applicable.

Consumers should respect the `methods` array to know whether a device supports
`sonic_usb`, native UEFI boot, or additional profile-specific install methods.
Template fields should be treated as open-box Markdown references, not embedded opaque payloads.

### Syncing Plan
1. Build tool (`wizard.routes.sonic_plugin_routes`) exports `devices` so dashboards show current catalog.
2. Seed rebuild refreshes `memory/sonic/seed/sonic-devices.seed.db` from `datasets/sonic-devices.sql`.
3. User imports and current-machine bootstrap write only to `memory/sonic/user/sonic-devices.user.db`.
4. UI/automation can poll `/api/sonic/health` or `/api/sonic/sync/status` and show quick instructions when the seed catalog is stale or the current machine has not yet been registered.

## 2. USB Builder API (Plan + Run)

Sonic exposes two CLI verbs via `apps/sonic-cli/cli.py`, backed by the
shared `services/` runtime and helper scripts for partitioning and payload
application. Wizard bolt-ons can wrap or invoke these commands over SSH/CLI.

### Commands
```bash
python3 apps/sonic-cli/cli.py plan \
  --usb-device /dev/sdX \
  --layout-file config/sonic-layout.json \
  --out memory/sonic/sonic-manifest.json

python3 apps/sonic-cli/cli.py run \
  --manifest memory/sonic/sonic-manifest.json \
  [--dry-run]
```

### Manifest expectations (`services/planner.py` and `services/manifest.py`)
- `usb_device` – raw block device.
- `layout` – `config/sonic-layout.json` describing partition labels/payloads.
- `payload_dir` – local payload library root, defaulting to `memory/sonic/artifacts/payloads/`.
- partition `payload_dir` and `image` entries resolve relative to the manifest payload root.
- `windows_mode` – `install` or `wtg`.
- `device_profile` – matches `devices.id` from sonic DB to set `windows10_boot`, `media_mode`.

Primary post-plan steps:
1. `scripts/partition-layout.sh` uses manifest partitions to set GPT entries, format them, and create labels.
2. `scripts/apply-payloads-v2.sh` mounts partitions and copies from the local payload library under `memory/sonic/artifacts/payloads/` unless overridden.
3. `scripts/sonic-stick.sh` (run phase) executes payload application, installs grub/bootloaders, and finalizes Windows payloads (ISO extraction or WTG injection).

Wizard bolt-ons should treat the plan/run APIs as a two-phase contract: the
plan command returns a manifest JSON plus `sha256(layout)` so a UI can verify
the payload before running. The run phase consumes that manifest; it is
idempotent but destructive, so the TUI should prompt users before executing the
plan. Logging from both CLI commands should be captured in
`memory/sonic/sonic-flash.log` so `PLUGIN` or `WIZARD` pages can surface
execution history.

### Current `uHOME` alignment for USB and image builds

Any `uHOME`-aligned USB or image build must:

1. resolve to one deployment role:
   - `uHOME Server`
   - `uHOME TV Node`
2. stay consistent with the current external `uHOME` runtime spec
3. support node bootstrap only up to the point of handing networking control to
   Wizard-owned surfaces
4. only claim dual-boot gaming or Windows media-launcher behavior when the
   manifest explicitly carries the matching boot targets, surfaces, and controller mappings
5. reuse the same component and config concepts as the standalone bundle lane
   where practical
6. support packaging of thin GUI, Steam-console UX, or both as presentation
   surfaces for the deployed node

### Wizard networking handoff

Sonic's role is to prepare a deployable node. After install, node
networking and managed control must hand off to Wizard-owned services.

## MCP facade

Sonic may expose an MCP facade, but MCP is not the canonical runtime protocol.
The intended layering is:
- shared Sonic service layer owns business logic
- HTTP API remains the primary control plane for browser UI and service integration
- MCP wraps the same service calls for AI/operator tooling

This keeps the browser GUI, local automation, and agent-facing tooling consistent without duplicating core install logic.

For `uHOME` this includes:

- LAN-local home-node operation by default
- optional enrollment into Wizard-managed beacon or tunnel flows
- no Sonic-owned long-running network control protocol
- no requirement for the full `uDOS/core` runtime in standalone Sonic or
  standalone `uHOME` distributions

## 3. `uHOME` bundle contract ownership

The standalone `uHOME` bundle contract is owned by `uHOME-server`.

Sonic may consume, stage, or hand off that contract during deployment, but it
is not the canonical owner of the bundle schema, preflight rules, or staged
install-plan semantics.

Authoritative code lives in `uHOME-server`:

- `src/uhome_server/sonic/uhome_bundle.py`
- `src/uhome_server/sonic/uhome_installer.py`
- `src/uhome_server/sonic/uhome_preflight.py`

Transition note:

- new contract changes should be made in `uHOME-server`
- Sonic should reference released examples and external contracts rather than redefining them locally

Install contract summary:

- artifact manifest: `uhome-bundle.json`
- verification: checksum validation per component
- rollback: optional rollback token and snapshot record support
- preflight: hardware profile gating
- plan phases:
  - `preflight`
  - `verify`
  - `stage`
  - `configure`
  - `enable`
  - `finalize`

Current canonical bundle components:

- `jellyfin`
- `comskip`
- `hdhomerun_config`
- `udos_uhome`

Bundle variants may additionally stage:

- thin-GUI presentation assets
- Steam-console launcher assets
- both presentation layers side by side

## 4. Home-node and beacon alignment

Sonic must treat `uHOME` node networking as a Wizard contract.

### Home-node rollout expectations

- a `uHOME Server` deployment may advertise or expose Wizard-managed control
  endpoints after install
- a `uHOME TV Node` deployment may be prepared as a playback-facing node that
  later enrolls with the household server and optional Wizard network control
- a deployment may expose thin GUI, Steam-console UX, or both on the same node
- Sonic documentation must describe node role selection directly rather than
  relying on older hybrid-console narratives

### Beacon alignment

When a deployment uses Wizard beacon networking:

- Sonic may install the node with the files and profile needed for later beacon
  enrollment
- Wizard routes under `/api/beacon/*` remain the active runtime control surface
- beacon configuration, tunnel status, quotas, and cache operations remain
  Wizard-owned

## 5. Wizard plugin installation flow

Plugin installs flowing through the Core `PLUGIN install <id>` command should reuse the same repository index/manifest validation logic that Wizard already exposes:

1. `core/tui/ucode.py` copies `/wizard/distribution/plugins/<id>` into `/library/<id>` and writes `container.json` metadata so the Wizard `LibraryManagerService` can load it.
2. The CLI then calls `LibraryManagerService.install_integration`, which enforces dependency wiring, runs setup scripts, and optionally builds APK bundles for the plugin.
3. `wizard.services.plugin_repository.PluginRepository` keeps track of available plugins, manifest checksums, and whether a plugin is already installed so the CLI can report upgrade availability.
4. Add hooks from the Wizard `plugin_repository` into _the same_ Sonic/USB story so plugin install actions can trigger schema validation (`GET /api/sonic/schema`) before enabling new media/USB tooling.

## 6. Wizard and Home Assistant control-plane alignment

For `uHOME`, Wizard integration is bounded to control-plane ownership rather
than install ownership.

Current `uHOME`-relevant Wizard surfaces:

- Home Assistant bridge routes under `/api/ha/`
- `uhome.*` command dispatch for tuner, DVR, ad-processing, and playback
- optional config-controlled bridge enablement

This remains optional and does not define install validity by itself.

## 7. Sonic scope guardrails

To keep the active scope stable:

- treat the device catalog and launch-profile decisions as install inputs, not as
  a replacement for the `uHOME` runtime spec
- keep older hybrid-console, launcher-heavy, or dual-boot product exploration
  docs non-canonical unless promoted by active implementation
- prefer the `uHOME-server` bundle contract when documenting `uHOME Server`
- keep the USB or image lane profile-aware and bounded when documenting
  `uHOME TV Node`
- align node networking and beacon behavior to Wizard's active route and service
  contracts

## 8. Related documents

- external current `uHOME` runtime spec in `uHOME-server`
- Wizard beacon and Home Assistant implementation docs in their owning repo
