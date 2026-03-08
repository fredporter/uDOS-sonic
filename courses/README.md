# uDOS-sonic Courses

This root is the education lane for `uDOS-sonic`.

Purpose:

- teach hardware bootstrap and deployment concepts through the real repo
- turn Sonic into a learnable pathway, not just an installer codebase
- align Sonic with the same family architecture language used by `uDOS`

## Current State

The working runtime now uses the same top-level language the courses teach:

- `apps/`
- `services/`
- `modules/`
- `vault/`
- `memory/`

The course system is the education-facing layer that organizes those real
surfaces into a guided path.

During this transition:

- the runtime layout remains canonical
- `wiki/` is the first student-facing orientation layer
- `docs/` remains the reference-first source of truth
- `courses/` becomes the guided learning ladder

## Learning Ladder

Sonic should currently teach four major levels:

1. Deployment Fundamentals
2. System Provisioning
3. Portable Dev Systems
4. Infrastructure Deployment

## Course Format

Each course should eventually follow the same structure:

- `README.md`
- `overview.md`
- `objectives.md`
- `prerequisites.md`
- `lessons/`
- `exercises/`
- `checkpoints/`
- `project/`
- `extension/`

## Pathway Role

Within the wider repo family:

- `uDOS` is the shared core and architecture umbrella
- `uDOS-sonic` is the deployment and hardware bootstrap pathway
- `uHOME-server` is the home infrastructure runtime pathway

Sonic courses should therefore teach:

- how to plan and verify installs
- how to provision disks and devices safely
- how to stage portable development systems
- how to hand deployments off to `uDOS` and `uHOME`

## Initial Course Scaffolds

- `01-deployment-fundamentals/`
- `02-system-provisioning/`
- `03-portable-dev-systems/`
- `04-infrastructure-deployment/`
