Sonic repo — @dev workspace and #binder workflow note

This note defines how the Sonic repo should align with the same @dev workspace and dev workflow process used by the uDOS core repo, while preserving stricter contribution boundaries for the distributable/public repo.

⸻

Purpose

The Sonic repo should operate as a uDOS-aligned development stream inside the shared @dev workspace model.

This means Sonic development should:
	•	use the same @dev workspace conventions as uDOS core
	•	track milestones, objectives, and pending dev work as #binders
	•	support local extension/scaffolding for active development
	•	keep local experimental/dev-mode materials out of the distributable repo by default
	•	restrict contribution to the public/distributable Sonic repo to approved contributors only

Sonic should therefore behave like a governed dev stream inside the broader uDOS dev ecosystem, not a free-form or directly self-mutating public repo.

⸻

Core alignment with uDOS core

The Sonic repo should mirror the same high-level dev process as uDOS core:

Shared development model
	•	@dev workspace is the active development surface
	•	#binder is the mission / milestone / objective container
	•	local extension supports background, staged, and experimental development
	•	approved, reviewed outputs are selectively promoted into the distributable repo
	•	repo-facing development is milestone-led, not branch-chaos-led

Shared lifecycle

For Sonic, the same lifecycle should apply:

Open
Hand off
Advance
Review
Commit
Complete
Compile
Promote

With meaning:
	•	Open — define a Sonic dev objective or milestone
	•	Hand off — make the task schedulable/advancable in @dev
	•	Advance — perform bounded dev progress locally
	•	Review — inspect changes, notes, risks, and scope drift
	•	Commit — checkpoint local progress
	•	Complete — objective is materially achieved
	•	Compile — clean and normalize the binder outcome
	•	Promote — selectively contribute approved outputs to the Sonic distributable repo

Important distinction:

local completion does not imply public repo contribution.

⸻

Sonic inside @dev

Sonic should be treated as a first-class project stream inside @dev.

Example conceptual structure:

@dev/
  sonic/
    workspace/
    binders/
    local-extension/
    review/
    compost/

This gives Sonic its own governed dev surface while staying consistent with the uDOS-wide model.

Recommended @dev Sonic sections

workspace/

Active notes, scratch implementation, current tasks, experiments, temporary context.

binders/

Milestones, objectives, missions, feature streams, fixes, refactors.

local-extension/

Local-only extension logic, adapters, dev helpers, prototypes, automation support, unpublished scaffolds.

review/

Items pending approval, promotion, merge decision, contributor validation.

compost/

Deprecated experiments, stale drafts, superseded notes, abandoned exploratory material.

⸻

#binder usage for Sonic

All meaningful Sonic development should be represented as #binders inside the @dev workspace.

What becomes a #binder

Use a binder for:
	•	milestone work
	•	feature streams
	•	major bugfix efforts
	•	architecture updates
	•	migration work
	•	packaging or release prep
	•	API integration work
	•	extension / adapter development
	•	documentation overhaul
	•	review and cleanup objectives

Examples:

#binder/sonic-auth-refactor
#binder/sonic-ui-shell
#binder/sonic-packaging-cleanup
#binder/sonic-extension-runtime
#binder/sonic-release-prep-v1

Binder purpose in Sonic

Each Sonic binder should track:
	•	objective
	•	milestone association
	•	current state
	•	pending tasks
	•	blockers
	•	risks
	•	files/areas touched
	•	local-only outputs
	•	candidate outputs for promotion
	•	compile and completion criteria

That makes Sonic dev progress inspectable and schedulable.

⸻

Pending dev task advancement

A key requirement is that pending Sonic development can be advanced from the @dev workspace.

This should work the same way as uDOS core:
	•	pending work is organized into #binders
	•	binders can be reviewed, resumed, handed off, or paused
	•	work advances locally first
	•	progress is milestone-aware
	•	outputs remain staged until approved

Advancement rules

Sonic binder advancement should:
	•	occur within the local @dev workspace and local extension
	•	prefer bounded increments over broad speculative churn
	•	track objective progress against milestone targets
	•	avoid direct uncontrolled mutation of the distributable repo
	•	produce reviewable outputs and checkpoints
	•	separate dev scaffolding from promotable repo content

So the local @dev workspace acts as the true development engine, while the public/distributable Sonic repo remains a curated release surface.

⸻

Milestones and objectives

Sonic needs explicit milestone tracking, not just ad hoc task accumulation.

Recommended hierarchy

Milestones

Larger delivery checkpoints.

Examples:
	•	runtime stabilization
	•	extension packaging
	•	UI refresh
	•	release prep
	•	adapter support
	•	docs parity with uDOS core conventions

Objectives

Specific mission outcomes beneath a milestone.

Examples:
	•	implement config loader
	•	normalize command routing
	•	clean extension bootstrap
	•	add manifest validation
	•	rewrite setup docs
	•	add local dev profile support

Binders

Execution containers for objectives or milestone slices.

This gives the model:

Milestone
  -> Objective
    -> #binder

Or sometimes:

Milestone
  -> #binder

for larger efforts.

⸻

Local extension model

Sonic should support a local extension layer for development that is intentionally excluded from standard distributable repo contribution.

This local extension is where dev-mode progression happens safely.

Purpose of local extension
	•	experiments
	•	dev helpers
	•	automation support
	•	private notes/config
	•	binder state
	•	local adapters
	•	temporary tooling
	•	review staging
	•	background dev artifacts

Principle

The local extension is allowed to be dynamic, messy, and development-oriented.

The distributable repo is not.

So the architecture should assume:
	•	local extension = active dev zone
	•	repo contribution = approved promotion zone

⸻

Contribution boundary

This is important and should be explicit.

Rule

Contribution to the distributable Sonic repo is strictly for approved contributors only.

That means:
	•	local users/devs can work in @dev and local extension
	•	local outputs can accumulate and compile
	•	candidate changes can be staged for promotion
	•	but only approved contributors may actually contribute those approved outputs into the public/distributable repo

This protects the repo from:
	•	uncontrolled dev-mode spillover
	•	personal local scaffolding leakage
	•	unstable experiments
	•	accidental architecture drift
	•	noisy or non-curated commits

Promotion model

Use a deliberate promotion step:

local @dev workspace
  -> binder compile
  -> review
  -> approval
  -> contributor promotion
  -> distributable repo

That should be the official path.

⸻

Sonic gitignore scaffold guidance

Sonic should include gitignore support for the local extension and workspace-linked development materials.

The goal is to keep local dev artifacts out of the distributable repo.

Recommended ignore categories

The Sonic repo should ignore local dev structures such as:

# uDOS / @dev local development
.dev/
@dev/
binders/
.local-extension/
.local/
.compost/
review-staging/
workspace-state/

# Local notes, scratch, and generated artifacts
*.local.md
*.draft.md
*.scratch.md
*.temp.md

# Local config and machine-specific state
.env.local
.env.dev.local
*.machine.json
*.local.json
*.cache.json

# Binder and workflow runtime state
binder-state/
binder-cache/
binder-runs/
workflow-state/
workflow-cache/

# Review / compile staging
compile-staging/
promotion-staging/
approval-staging/

# OS/editor noise
.DS_Store
Thumbs.db
.vscode/
.idea/

Important note

The exact ignore layout may differ depending on Sonic’s existing repo structure, but the principle should remain:

all local extension, binder runtime state, dev scratch material, and unpublished review/compile staging should be gitignored by default.

Only clean, approved, promotable artifacts should enter the public repo.

⸻

Recommended Sonic workflow

1. Open a Sonic binder

Create a binder for a milestone or objective.

Example:

#binder/sonic-extension-runtime
#binder/sonic-config-normalization
#binder/sonic-release-prep

2. Work inside @dev

Do all active development, exploration, notes, scaffolding, and helper logic inside the Sonic area of @dev and local extension.

3. Advance pending work

Resume or hand off pending binders and push bounded progress forward.

4. Track milestone alignment

Each binder should map to a milestone and objective.

5. Review candidate outcomes

Inspect what is promotable versus what remains local/dev-only.

6. Compile the binder

Clean development relics, normalize outputs, reduce clutter, and prepare a reviewable mission outcome.

7. Promote only approved outputs

An approved contributor selectively transfers appropriate changes into the distributable repo.

⸻

Binder fields recommended for Sonic

Each Sonic binder should ideally track:

binder: sonic-extension-runtime
project: sonic
milestone: extension-runtime-v1
objective: establish local extension runtime and promotion boundary
status: active
priority: high
mode: slow-and-low
repo_target: sonic
local_only: true
promotion_candidate: partial
approved_contributor_required: true
compile_target: review-ready

Useful additional fields:

files_touched:
repo_paths:
local_paths:
blockers:
review_required: true
promotion_notes:
completion_criteria:


⸻

Compile and promotion behavior

For Sonic, compile should prepare the binder outcome for repo review, not auto-publish it into the distributable repo.

compile should
	•	clean local dev clutter
	•	consolidate notes and changes
	•	identify promotable outputs
	•	separate local-only materials
	•	archive stale experiments into compost/review
	•	generate a clear promotion summary

promote should
	•	require contributor approval
	•	only move approved assets into the repo
	•	preserve repo cleanliness
	•	exclude local binder/runtime debris
	•	maintain Sonic’s distributable integrity

This keeps Sonic aligned with uDOS core discipline.

⸻

Governance rule

Sonic should follow the same governance philosophy as uDOS core:

The @dev workspace is the active mission-development surface; #binders are the unit of progress, milestone tracking, and autonomous advancement; local extension supports flexible development; the distributable Sonic repo remains a curated, contributor-governed output surface.

That sentence is worth keeping almost verbatim.

⸻

Recommended short-form policy block

You could drop this into the repo docs as-is:

Sonic development should follow the same @dev workspace and binder-driven workflow model as the uDOS core repo. Pending development tasks, milestones, and objectives are tracked as #binders within the Sonic area of @dev, and may be advanced locally through bounded dev workflow progression.

Local extension scaffolding, binder state, review staging, and experimental development materials must remain excluded from the distributable repo through gitignore and workspace separation. Contribution to the public/distributable Sonic repo is restricted to approved contributors only, with repo-facing changes promoted only after review, compile, and approval.

⸻

Recommended command concepts

A matching command pattern could look like:

binder open #sonic-extension-runtime
binder handoff #sonic-extension-runtime
binder advance #sonic-extension-runtime
binder review #sonic-extension-runtime
binder compile #sonic-extension-runtime
binder promote #sonic-extension-runtime

And for milestones:

binder open #sonic-release-prep-v1
binder status #sonic-release-prep-v1


⸻

Final intent

The Sonic repo should not drift into an isolated or looser workflow.

It should be:
	•	developed locally through @dev
	•	organized through #binders
	•	tracked by milestone and objective
	•	protected by local-extension separation
	•	promoted into the distributable repo only through approved contributor governance

That gives Sonic the same disciplined dev-mode architecture as uDOS core, while still allowing active forward development.

Convert this into a tighter repo-ready markdown note with headings and policy language styled for direct inclusion in the Sonic repo.