# uDOS‑Sonic – Education Structure Refactor Brief

## Objective
Position **uDOS‑sonic** as the *deployment and hardware bootstrap pathway* for the uDOS ecosystem while making the repo easy to learn through structured course material.

uDOS‑sonic should teach developers how to:

- provision Linux systems
- deploy uDOS environments
- create portable dev environments
- build install automation pipelines

---

# Strategic Positioning

uDOS‑sonic becomes:

**The portable deployment and provisioning system for uDOS.**

Key capabilities:

- USB installers
- dual‑boot environments
- system rescue environments
- automated infrastructure provisioning

---

# Proposed Repository Structure

```
uDOS-sonic/
  apps/
  modules/
  services/
  vault/
  docs/
  courses/
  scripts/
  config/
  tests/
```

### apps

```
apps/
  sonic-cli/
  sonic-ui/
```

CLI controls build and deployment pipelines.

### modules

```
modules/
  usb-installer/
  dualboot/
  rescue/
  uhome-bundle/
```

Modules represent installable deployment paths.

### services

```
services/
  planner/
  manifest/
  device-catalog/
  build-engine/
```

Services create install plans and device manifests.

### vault

Deployment history stored as Markdown.

```
vault/
  manifests/
  device-profiles/
  deployment-notes/
  templates/
```

This allows:

- auditability
- learning examples
- Obsidian compatibility

---

# Sonic Learning Path

## Course 01 – Deployment Fundamentals

Topics:

- Linux disk layout
- boot loaders
- multi‑boot systems
- installer automation

Project:
Create USB deployment plan.

---

## Course 02 – System Provisioning

Topics:

- provisioning workflows
- install manifests
- configuration pipelines

Project:
Build automated install plan.

---

## Course 03 – Portable Dev Systems

Topics:

- portable dev environments
- USB OS environments
- rescue systems

Project:
Build portable dev toolkit.

---

## Course 04 – Infrastructure Deployment

Topics:

- deploying uDOS nodes
- server provisioning
- automated hardware setup

Project:
Provision uDOS + uHOME system.

---

# Integration with uDOS

uDOS‑sonic consumes:

- uDOS module definitions
- uDOS deployment profiles
- uDOS vault schemas

Sonic should **not redefine core architecture**.

Its role is:

```
take uDOS profile
→ deploy to hardware
```

---

# Implementation Tasks

1. Replace legacy layout with shared uDOS structure
2. Add `/courses` learning path
3. Introduce Markdown deployment vault
4. Separate planning services from installer modules
5. Provide example deployment profiles

---

# Expected Outcome

uDOS‑sonic becomes:

- deployment reference architecture
- infrastructure education platform
- hardware provisioning toolkit