# Welcome to the Sonic wiki

Updated: 2026-03-08

This wiki is the student-facing orientation layer for `uDOS-sonic`.

Use it when you want the shortest path to understanding:

- what Sonic is
- what it owns
- how it relates to `uDOS` and `uHOME-server`
- where to start learning

When you want implementation detail, move from the wiki into `courses/` and
then into `docs/`.

## Start Here

- first steps: [Getting Started](Getting-Started.md)
- learning ladder: [Education Pathways](Education-Pathways.md)
- repo boundaries: [Repo Map](Repo-Map.md)
- common questions: [FAQ](FAQ.md)

## Project Snapshot

- repo front door: [../README.md](../README.md)
- course ladder: [../courses/README.md](../courses/README.md)
- docs index: [../docs/README.md](../docs/README.md)
- active structure assessment: [../docs/sonic-structure-assessment-2026-03-08.md](../docs/sonic-structure-assessment-2026-03-08.md)

## Core Idea

Sonic is the deployment and hardware bootstrap pathway for the repo family.

It plans and applies deployments to real hardware, but it does not own the full
runtime of every system it can install.

Current family split:

- `uDOS` = shared architecture and Wizard integration
- `uDOS-sonic` = deployment and hardware bootstrap
- `uHOME-server` = canonical `uHOME` runtime contracts
