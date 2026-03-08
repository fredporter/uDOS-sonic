# uDOS-sonic Structure Assessment

Updated: 2026-03-08
Status: baseline assessment

Implementation note:

- `courses/` and `wiki/` have since been added
- public `apps/`, `modules/`, `services/`, and `vault/` roots are now present
- local `uHOME` compatibility code has since been removed from this repo
- the active CLI, UI, and runtime service code have since been moved into
  `apps/` and `services/`

## Scope

This assessment compares the current `uDOS-sonic` repository against:

- `docs/uDOS-sonic-education-dev-brief.md`
- the active standalone Sonic structure in this repo
- the `uDOS` family transition rules in `uDOS/dev/docs/specs/V1-5-3-EDUCATION-REPO-TRANSITION-PROGRAM.md`
- the cross-repo split documented in `uDOS/docs/howto/SONIC-UHOME-EXTERNAL-INTEGRATION.md`
- the current `uHOME-server` repo boundary

## Executive Summary

`uDOS-sonic` is structurally halfway to the new education-facing model.

The good news:

- the code already has clear service boundaries
- the repo already has standalone runtime separation from `uDOS`
- the deployment pathway is real and teachable

The gaps:

- the top-level folder names still expose legacy implementation language instead of family architecture language
- `docs/` mixes reference docs, tutorial flow, historical briefs, and product exploration
- `courses/` and `vault/` are not yet surfaced
- some `uHOME` install-contract ownership is still duplicated locally even
  though `uHOME-server` is now the canonical owner

The recommended path is the same one `uDOS` is using: do not do a big-bang rename first. Keep the working runtime intact, add education-facing structure and documentation now, then move code only after ownership is unambiguous.

## What Already Aligns

### 1. Services already exist in substance

The proposed Sonic brief calls for:

- `services/planner`
- `services/manifest`
- `services/device-catalog`
- `services/build-engine`

The current repo already has those concerns, just under different roots:

- planner and manifest generation: `installers/usb/plan.py`, `installers/usb/manifest.py`
- shared service layer: `installers/usb/service.py`
- HTTP control plane: `core/sonic_api.py`
- MCP facade: `core/sonic_mcp.py`
- device catalog data and rebuild logic: `datasets/` plus `installers/usb/service.py`
- build execution layer: `scripts/sonic-stick.sh` and related shell helpers

This means the repo is not conceptually misaligned. It is mostly naming and packaging misalignment.

### 2. Sonic already has a real deployment pathway

The new brief positions Sonic as:

- portable deployment
- hardware bootstrap
- provisioning automation

That matches the active repo direction much more than the older hybrid-console narrative does. The current working system already centers on:

- USB planning
- manifest generation
- device catalog lookup
- OS-aware execution
- standalone API and UI surfaces

### 3. Repo separation from `uDOS` is already correct

The family-level split is already documented in `uDOS`:

- `uDOS` owns shared architecture language, Wizard integration, and family coordination
- `uDOS-sonic` owns deployment and hardware bootstrap
- `uHOME-server` owns the `uHOME` runtime

That separation is directionally correct and should be reinforced, not reversed.

## Main Misalignments

### 1. Repo root still uses implementation-first naming

Current roots:

- `core/`
- `installers/`
- `ui/`
- `datasets/`
- `distribution/`
- `memory/`
- `library/`
- `payloads/`

Target education-facing roots:

- `apps/`
- `modules/`
- `services/`
- `vault/`
- `docs/`
- `courses/`
- `scripts/`
- `config/`
- `tests/`

The current roots make sense to maintainers, but they do not answer the family onboarding questions cleanly:

1. What app surfaces does Sonic expose?
2. What install modules does Sonic provide?
3. What services power planning and deployment?
4. What Markdown surfaces does Sonic read or write?
5. How does Sonic connect back to `uDOS` and `uHOME`?

### 2. `docs/` is overloaded

`docs/` currently mixes four different document types:

- active reference docs
- lesson-like sequences (`01-overview.md` through `09-summary.md`)
- historical product exploration
- roadmap/brief material

That weakens the educational story because learners cannot tell what is canonical, what is a lesson, and what is archive.

### 3. The educational path is implicit, not explicit

The new Sonic brief defines four courses, but the repo has no `courses/` root yet.

There is already teachable material:

- `docs/01-overview.md`
- `docs/02-usb-setup.md`
- `docs/08-boot-model.md`
- `docs/howto/build-usb.md`
- `docs/howto/dry-run.md`
- `docs/integration-spec.md`

But these are not organized as a student path.

### 4. `uHOME` ownership still needs cleanup

This is the highest-risk structural issue.

`uDOS-sonic` still contains:

- `installers/bundles/uhome/bundle.py`
- `installers/bundles/uhome/installer.py`
- `installers/bundles/uhome/preflight.py`
- `distribution/launchers/uhome/`

At the same time, `uHOME-server` now contains migrated `sonic` install-plan and bundle modules under:

- `src/uhome_server/sonic/uhome_bundle.py`
- `src/uhome_server/sonic/uhome_installer.py`
- `src/uhome_server/sonic/uhome_preflight.py`

The repo decision is now:

- `uHOME-server` owns the canonical bundle, preflight, and staged install-plan contract
- `uDOS-sonic` may keep temporary compatibility copies while it migrates toward
  consuming released artifacts, examples, or imported contracts

That resolves the ownership question, but the duplicate local files should
still be reduced over time.

The current repo can now bridge to the sibling `uHOME-server` modules when that
repo is available locally, which is the right transitional behavior while the
remaining local compatibility copies are phased down.

### 5. `memory/` is runtime-correct but education-invisible

The main `uDOS` transition program explicitly says not to rename `memory/` to `vault/` yet.

Sonic should follow the same rule.

That means:

- keep `memory/sonic/` as the runtime root
- add a public `vault/` presentation only for tracked Markdown examples and templates
- do not move logs, caches, databases, or generated artifacts into `vault/`

### 6. `payloads/`, `library/`, and parts of `distribution/` are not good public roots

These roots are valid operationally, but weak as top-level teaching surfaces:

- `payloads/` overlaps conceptually with `memory/sonic/artifacts/payloads/`
- `library/` is a local bolt-on/runtime cache concept, not a primary family architecture root
- `distribution/` mixes packaging metadata with older launcher artifacts and profile descriptors

These should be kept as internal/runtime support until narrower ownership is defined.

## Current-To-Target Mapping

| Current root | Recommended education-facing role | Assessment | Recommended action |
| --- | --- | --- | --- |
| `ui/` | `apps/sonic-ui/` | Good fit, wrong root name | Move later, document now |
| `installers/usb/cli.py` | `apps/sonic-cli/` | CLI exists but is buried inside installer code | Extract or wrap later |
| `installers/usb/` | `modules/usb-installer/` plus `services/` | Real module already exists | Split by interface vs logic over time |
| `installers/bundles/uhome/` | `modules/uhome-bundle/` or external dependency | Boundary conflict with `uHOME-server` | Resolve ownership first |
| `core/sonic_api.py` | `services/api/` or `apps/api/` | Good service boundary | Rehome after import shims exist |
| `core/sonic_mcp.py` | `services/mcp/` or service adapter | Good service boundary | Rehome later |
| `datasets/` | `services/device-catalog/` plus `vault/templates/` for docs/examples | Data is useful but root is too implementation-specific | Keep data, change presentation |
| `memory/` | runtime backing for future `vault/` | Keep as runtime truth | Do not rename yet |
| `docs/01-09` flow | `courses/` | Strong migration candidate | Convert to course materials |
| `distribution/` | packaging support, not primary top-level teaching root | Mixed ownership | Narrow and de-emphasize |
| `library/` | internal/local extension lane | Not part of public family IA | Keep internal |
| `payloads/` | examples/scaffold only | Redundant with runtime artifact root | Reduce to template-only or archive |
| `tests/` | `tests/` | Already aligned | Add sub-structure later |
| `config/` | `config/` | Already aligned | Keep |
| `scripts/` | `scripts/` | Already aligned | Keep |

## Recommended Sonic Target Tree

This is the target information architecture Sonic should teach toward, without requiring an immediate hard rename:

```text
uDOS-sonic/
  apps/
    sonic-cli/
    sonic-ui/
  modules/
    usb-installer/
    dualboot/
    rescue/
    uhome-bundle/
  services/
    planner/
    manifest/
    device-catalog/
    build-engine/
  vault/
    manifests/
    device-profiles/
    deployment-notes/
    templates/
  docs/
    architecture/
    decisions/
    reference/
    operations/
    integrations/
    archive/
  courses/
    01-deployment-fundamentals/
    02-system-provisioning/
    03-portable-dev-systems/
    04-infrastructure-deployment/
  scripts/
  config/
  tests/
```

## Recommended Canonical Ownership By Repo

### `uDOS`

Should own:

- family architecture language
- Wizard integration and cross-repo discovery
- shared course umbrella and companion-repo framing
- shared schemas only when they are truly family-wide

Should not own:

- Sonic runtime code
- Sonic datasets and build scripts
- `uHOME-server` runtime implementation

### `uDOS-sonic`

Should own:

- hardware planning
- USB, disk image, rescue, and provisioning modules
- device catalog and hardware compatibility logic
- build orchestration and deployment execution surfaces
- deployment-focused UI and CLI
- deployment courses and hardware-bootstrap examples

Should not own:

- the full `uHOME` runtime
- long-running `uHOME` service behavior
- Wizard-managed network control behavior

### `uHOME-server`

Should own:

- the `uHOME` runtime and Linux-side service behavior
- bundle/install-plan contract if the bundle is fundamentally a `uHOME` release artifact
- preflight rules for `uHOME` host requirements
- presentation/runtime assets that are part of `uHOME`, not generic deployment

Should not own:

- generic Sonic hardware planning
- Sonic USB execution pipeline
- Sonic device catalog and hardware bootstrap UX

## Specific Recommendations

### Recommendation 1: align documentation before code movement

Do this first:

- create `courses/`
- split `docs/` into reference vs archive intent
- rewrite top-level messaging around "deployment and hardware bootstrap"
- add explicit cross-repo boundary notes

Do not start by renaming code packages.

### Recommendation 2: make `courses/` the home for the existing lesson flow

The current numbered docs are a strong seed for the new educational pathway.

Suggested first mapping:

- `01-deployment-fundamentals/`
  - current sources: `docs/01-overview.md`, `docs/02-usb-setup.md`, `docs/08-boot-model.md`
- `02-system-provisioning/`
  - current sources: `docs/03-udos-core.md`, `docs/05-ubuntu-wizard.md`, `docs/howto/build-usb.md`, `docs/howto/dry-run.md`
- `03-portable-dev-systems/`
  - current sources: `docs/06-local-drives.md`, `docs/howto/standalone-release-and-install.md`
- `04-infrastructure-deployment/`
  - current sources: `docs/integration-spec.md`, device catalog docs, deployment examples

### Recommendation 3: treat `uHOME-server` as the resolved canonical owner

The canonical owner is now:

- canonical bundle contract: `uHOME-server`
- Sonic responsibility: consume or stage that contract during deployment

If that decision is accepted, `uDOS-sonic` should eventually keep only:

- deployment adapters
- released example profiles
- references to `uHOME-server` artifacts

### Recommendation 4: treat `vault/` as a public teaching surface, not a runtime rename

For Sonic, `vault/` should contain tracked Markdown only:

- sample deployment manifests
- device profile examples
- deployment notes
- reusable templates

Keep these runtime concerns in `memory/sonic/`:

- logs
- DBs
- generated manifests
- downloaded payloads
- build outputs

### Recommendation 5: de-emphasize historical product-specific docs

Docs centered on older media, kiosk, or hybrid-console exploration should be treated as archive unless they are still active deployment targets.

The educational Sonic story is clearer when the top-level narrative is:

- deploy systems
- bootstrap hardware
- produce portable environments
- hand off to `uDOS` or `uHOME`

not:

- maintain every historical gaming/media exploration as equal-priority documentation

## Phased Migration Plan

### Phase 1: documentation alignment

- add `courses/` scaffold
- add a structure assessment and current-to-target mapping
- update `README.md` and `docs/README.md` to use family architecture language
- mark legacy docs as archive candidates

### Phase 2: boundary cleanup

- decide canonical `uHOME` bundle ownership
- remove or reduce duplicate `uHOME` installer contracts in Sonic
- narrow `distribution/` to Sonic-owned packaging descriptors
- decide whether `payloads/` survives as template-only tracked scaffold

### Phase 3: package re-homing

- re-home `ui/` into `apps/sonic-ui/`
- introduce `apps/sonic-cli/` as the explicit CLI surface
- re-home service logic from `core/` and `installers/` into `services/`
- re-home install lanes into `modules/`
- keep compatibility wrappers in old paths until imports are fully updated

### Phase 4: educational hardening

- convert numbered docs into real course folders
- add exercises, checkpoints, and project tasks
- add examples that demonstrate one deployment concept at a time
- tighten tests around planner, manifest, device-catalog, and execution boundaries

## Immediate Next Actions

The highest-value next actions are:

1. finish the docs-first educational scaffold
2. reduce the remaining duplicate `uHOME` bundle and preflight copies in Sonic
3. rewrite the repo root README around the new Sonic pathway
4. only then begin moving code into `apps/`, `modules/`, and `services/`

## Bottom Line

The repo does not need a conceptual restart.

It already contains the right deployment capabilities. The work now is to:

- express those capabilities using the same architecture language as `uDOS`
- make the learning path explicit
- remove cross-repo ownership ambiguity with `uHOME-server`
- preserve the runtime while the education-facing structure becomes visible
