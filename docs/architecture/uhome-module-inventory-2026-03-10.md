# uHOME Module Inventory (Task 2.1)

Date: 2026-03-10
Binder: `#binder/sonic-uhome-boundary` (`v1.6.2`)

## Scope

Audited local uHOME-related modules in:

- `installers/bundles/uhome/`
- `distribution/launchers/uhome/`

## Findings

### 1. `installers/bundles/uhome/`

Current state: empty directory

Classification:

- local compatibility bundle/preflight/installer code appears already removed
- no local Python modules remain in this path

Implication:

- duplicate local ownership footprint is lower than earlier assessment snapshots
- bridge-import work (Task 2.2+) must target external `uHOME-server` surfaces

### 2. `distribution/launchers/uhome/`

Current files:

- `distribution/launchers/uhome/README.md`
- `distribution/launchers/uhome/uhome-console.sh`

Classification:

- `uhome-console.sh`: local launcher shim/presentation asset
- `README.md`: local documentation for launcher staging path

Ownership recommendation:

- keep launcher shell asset in Sonic as deployment-time staging artifact
- treat bundle/preflight/install-plan contracts as external canonical owner (`uHOME-server`)

## Ownership Matrix

| Surface | Current Location | Classification | Canonical Owner |
|---|---|---|---|
| uHOME bundle contract | (not present locally) | external dependency | `uHOME-server` |
| uHOME preflight contract | (not present locally) | external dependency | `uHOME-server` |
| uHOME installer contract | (not present locally) | external dependency | `uHOME-server` |
| uHOME launcher shell | `distribution/launchers/uhome/uhome-console.sh` | local deployment shim | `uDOS-sonic` (staging layer) |

## Gap to Next Tasks

Task 2.2 requires external module availability to define/import bridge paths
against canonical `uHOME-server` APIs.

Candidate expected external targets (from prior assessment notes):

- `src/uhome_server/sonic/uhome_bundle.py`
- `src/uhome_server/sonic/uhome_installer.py`
- `src/uhome_server/sonic/uhome_preflight.py`

## Outcome

Task 2.1 is complete: local inventory and ownership classification produced.

Remaining binder work is blocked on external dependency confirmation.
