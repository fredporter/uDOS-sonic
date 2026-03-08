# Lesson 01 - Runtime Roles

Older Sonic lesson docs described separate roles for:

- core local system behavior
- orchestration and validation
- gaming or media deployment surfaces

The important current lesson is boundary ownership, not those exact older
labels.

Today, you should think in terms of:

- Sonic planner and manifest generation
- Sonic execution scripts for Linux-only destructive work
- `uDOS` for shared family architecture and Wizard integration
- `uHOME-server` for canonical `uHOME` runtime contracts

If a learner understands those boundaries, the repo becomes much easier to
navigate.
