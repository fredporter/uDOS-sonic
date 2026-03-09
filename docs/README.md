# Sonic Docs

## Current
- specs/sonic-screwdriver.md
- integration-spec.md
- sonic-structure-assessment-2026-03-08.md
- howto/build-usb.md
- howto/quickstart.md
- howto/dry-run.md
- howto/dev-workflow.md
- howto/standalone-release-and-install.md
- howto/vault-templates-and-examples.md
- ../LEGAL.md
- ../CONTRIBUTING.md
- ../CONTRIBUTORS.md
- ../CODE_OF_CONDUCT.md
- ../courses/README.md
- ../wiki/Home.md
- devlog/2026-01-24-sonic-standalone-baseline.md
- .compost/README.md

## Active Direction

- `integration-spec.md` is the active Sonic integration contract
- `specs/sonic-screwdriver.md` describes the active Sonic provisioning contract
- `sonic-structure-assessment-2026-03-08.md` is a baseline assessment record,
  not the live repo map
- `distribution/` and `memory/sonic/` define the tracked-vs-local storage
  boundary
- the active `uHOME` runtime and install spec is external to this repository
  and should be referenced as an integration dependency, not an internal doc
- Wizard owns active network-control surfaces such as beacon and Home Assistant
  integration
- `uHOME-server` is the canonical owner of `uHOME` bundle, preflight, and
  install-plan contracts
- active learner-facing material now lives in one Sonic course plus the wiki
- superseded lesson chains, exploration notes, archived course scaffolds, and
  older specs now live in `docs/.compost/`
- `pyproject.toml` plus `installers/setup/` define the current editable install
  path for Sonic operator entrypoints
- local `@dev` / binder workflow state is intentionally excluded from tracked
  repo content; the public repo keeps only reviewed outputs

## Legacy

- `docs/.compost/` holds superseded lesson chains, exploration notes, archived
  course scaffolds, and older specs.
