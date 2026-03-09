# Recovery Escalation Example

Date: 2026-03-10
Profile: `rescue-maintenance-stick`
Manifest: `vault/manifests/reference-rescue-maintenance-dry-run.manifest.json`

## Scenario

Dry-run completed, but operator discovered inconsistent payload inventory before
apply.

## Decision

Stopped execution and escalated to artifact owner for payload refresh.

## Evidence Collected

- dry-run output transcript
- profile copy used for generation
- payload inventory snapshot

## Why This Matters

The safest recovery action is often to stop and escalate before destructive
steps begin.
