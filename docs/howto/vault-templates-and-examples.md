# Vault Templates and Examples Workflow

Use this guide to move from template profile to reviewed deployment evidence.

## Scope

This workflow is for tracked examples and planning artifacts in `vault/`.
Runtime outputs still belong in `memory/sonic/`.

## Step 1: Choose a Profile Template

Pick a starting point from:

- `vault/templates/device-profiles/`

Validate syntax before editing:

```bash
python -m json.tool vault/templates/device-profiles/<profile>.profile.json >/dev/null
```

## Step 2: Adapt for Your Target

Adjust fields for:

- boot targets
- partition sizing
- profile mode
- surface assumptions

Keep your working copy outside `vault/` until reviewed.

## Step 3: Generate and Inspect Dry-Run Plan

Run planning and dry-run against your working profile and compare with:

- `vault/manifests/reference-dualboot-dry-run.manifest.json`
- `vault/manifests/reference-windows-entertainment-apply.manifest.json`
- `vault/manifests/reference-rescue-maintenance-dry-run.manifest.json`

Review destructive steps carefully before any apply operation.

## Step 4: Record Deployment Notes

Capture outcomes in `vault/deployment-notes/` using the same pattern as:

- `dualboot-lab-retro.md`
- `windows-entertainment-canary.md`
- `recovery-escalation-example.md`

Every note should include profile ID, manifest ID, risks, and handoff outcome.

## Maintenance

Refresh vault examples when:

- `config/sonic-layout.json` changes
- flash-pack partition contracts change
- boot selector targets or profile ownership changes
