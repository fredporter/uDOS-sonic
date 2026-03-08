# Sonic Screwdriver Changelog

## v1.5.5 (2026-03-09)

- Complete the runtime refactor and repo-family separation of Sonic from local `uHOME` contract ownership.
- Finish the active `apps/`, `services/`, `modules/`, `vault/`, and editable-install structure for the public repo surface.
- Add Linux smoke workflow, packaging/setup entrypoints, and governance docs for release readiness.
- Simplify the learner-facing surface to one canonical Sonic Screwdriver course and move superseded docs and course scaffolds into `docs/.compost/`.
- Keep broader platform education in the sibling `uDOS` course ladder instead of duplicating it in Sonic.

## v1.5.4 (2026-03-08)

- Move the active Sonic runtime into `apps/sonic-cli/`, `apps/sonic-ui/`, and `services/`.
- Update repo docs, course material, and operator scripts to the new runtime roots and entrypoints.
- Keep `uHOME-server` as the external canonical owner of `uHOME` install contracts while Sonic owns deployment surfaces only.
- Enforce Linux-only build gating consistently across the CLI, HTTP API, and shared runtime service.
- Fix the moved Sonic UI dependency set so `npm install` and `npm run build` succeed under the new app root.

## v1.5.3 (2026-03-08)

- Remove local `uHOME` bundle/preflight/install-plan compatibility code from `uDOS-sonic`.
- Treat `uHOME-server` as the only canonical owner of `uHOME` install contracts.
- Add student-facing `courses/` and `wiki/` roots and continue doc migration.
- Introduce public `apps/`, `modules/`, `services/`, and `vault/` structure docs for the education-facing repo format.

## v1.5.2 (2026-03-07)

- Move USB installer planning into `installers/usb/`.
- Remove transitional `core/*` shims and switch live entrypoints to the new package layout.
- De-version the active contract docs so future upgrades do not require another path rename.

## v1.0.1.0 (2026-01-24)

- Introduce core planning layer and manifest output.
- Separate OS-specific bash execution from core planning.
- Add OS limitation checks and dry-run mode.
- Restructure docs into specs/howto/devlog with legacy archive.

## v1.0.0.6

- Legacy Sonic Stick Pack (Ventoy USB toolkit).
