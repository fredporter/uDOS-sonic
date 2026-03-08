# Repo Map

The active runtime currently lives under:

- `apps/`
- `services/`
- `modules/`
- `vault/`
- `scripts/`
- `config/`
- `distribution/`
- `memory/`
- `datasets/`
- `tests/`

What these mean in practice:

- `apps/` contains the CLI and browser UI surfaces
- `services/` contains shared planning, manifest, API, and MCP logic
- `modules/` contains install-domain architecture surfaces
- `vault/` contains tracked templates and deployment notes
- `scripts/` contains Linux-side execution steps
- `memory/` contains local runtime state and generated artifacts

The education-facing structure now matches the active top-level runtime roots,
with `courses/` and `wiki/` layered on top for guided learning.

That structure is explained in:

- [../docs/sonic-structure-assessment-2026-03-08.md](../docs/sonic-structure-assessment-2026-03-08.md)
