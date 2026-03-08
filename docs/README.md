# Sonic Docs

## Current
- specs/sonic-screwdriver.md
- integration-spec.md
- sonic-structure-assessment-2026-03-08.md
- specs/uDOS_Xbox_Entertainment_Spec.md
- specs/uDOS-Gameplay-Anchors-v1.3-Spec.md
- specs/v1-3 GAMEPLAY.md
- howto/build-usb.md
- howto/dry-run.md
- howto/standalone-release-and-install.md
- ../courses/README.md
- ../wiki/Home.md
- devlog/2026-01-24-sonic-standalone-baseline.md

## Active Direction

- `integration-spec.md` is the active Sonic integration contract
- `specs/sonic-screwdriver.md` now describes the active Sonic
  provisioning contract
- `sonic-structure-assessment-2026-03-08.md` is the current
  repo-structure assessment against the education brief and family split
- `distribution/` and `memory/sonic/` define the tracked-vs-local storage boundary
- the active `uHOME` runtime and install spec is external to this repository
  and should be referenced as an integration dependency, not an internal doc
- Wizard owns active network-control surfaces such as beacon and Home Assistant
  integration
- `uHOME-server` is now the canonical owner of `uHOME` bundle, preflight, and
  install-plan contracts
- this repo no longer keeps local `uHOME` contract code
- public `apps/`, `modules/`, `services/`, and `vault/` roots are now present
  as the latest education-facing structure
- numbered learning-path docs are migration candidates for the new `courses/`
  root rather than long-term canonical reference docs
- `wiki/` is the student-facing orientation layer

## Legacy
- `specs/sonic-screwdriver-legacy-baseline.md` captures the first standalone planning split.
- `roadmap-v1-4-*.md` files capture historical exploration that is still kept in
  this repo.
