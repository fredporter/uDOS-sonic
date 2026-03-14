# Sonic Release Policy

## Purpose

Define when `uDOS-sonic-screwdriver` releases are notes-only versus when they
may attach packaging artifacts.

## Default Policy

Sonic releases are tagged from `main` using semantic version tags.

Default behavior:

- create GitHub release notes from `CHANGELOG.md`
- do not attach build artifacts by default

## Artifact Attachment Rule

Artifacts may be attached only when all of the following are true:

1. the packaging output is produced by a documented, repeatable build path
2. the output is reviewed as a real public deliverable, not a scratch bundle
3. the artifact type and naming are documented in repo docs
4. the validation path covers the relevant packaging or smoke checks

## Current State

Current Sonic releases are treated as notes-first.

Rationale:

- packaging surfaces exist, but artifact attachment policy should wait for a
  stable, reviewable output lane
- large generated payloads remain outside the git repo and should not be
  invented during release creation

## Current Artifact Candidates

The first candidate release surfaces are:

- `distribution/installers/bundles/*.json`
- `distribution/installers/usb/*.json`
- `distribution/launchers/`

These are candidates because they are:

- tracked in git
- small enough to review
- already documented as public packaging descriptors

They are not attached yet because the repo still needs:

- explicit artifact naming conventions
- a stable packaging build step for release assembly
- a clear distinction between tracked descriptors and generated payloads
