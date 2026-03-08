# Lesson 02 - USB Layout Basics

The classic Sonic lesson flow starts with a multi-partition USB layout.

The important concept is not one exact partition table. The important concept
is that Sonic treats a deployment layout as explicit, reviewable structure.

Typical roles in the layout include:

- EFI boot partition
- read-only system image
- writable data or persistence partition
- optional service or tooling partition
- optional Windows or media partition

In the current repo, the active layout comes from:

- `config/sonic-layout.json`
- generated manifest output in `memory/sonic/sonic-manifest.json`

Learners should focus on the role of each partition before they focus on exact
sizes.
