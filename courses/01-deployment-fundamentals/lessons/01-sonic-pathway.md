# Lesson 01 - Sonic As A Pathway

Sonic is the deployment and hardware bootstrap pathway for the repo family.

That means Sonic is responsible for preparing hardware and writing reviewed
deployment plans onto real devices. It does not own the whole runtime for every
system it can deploy.

Current family split:

- `uDOS` owns shared architecture language and Wizard integration
- `uDOS-sonic` owns planning, provisioning, and hardware bootstrap
- `uHOME-server` owns the canonical `uHOME` runtime contracts

The key safety idea is separation:

- Python plans and validates
- shell execution applies destructive disk changes
- dry-run allows review before real writes

This keeps Sonic understandable as both an engineering system and an
educational system.
