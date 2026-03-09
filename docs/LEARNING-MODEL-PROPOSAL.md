# Task 1.1 Deliverable: Learning Model Proposal

**Binder**: #binder/sonic-education-pathway  
**Task**: 1.1 - Learning Model Proposal  
**Date**: 2026-03-10  
**Status**: Complete

---

## Executive Summary

The current `courses/01-sonic-screwdriver/` course is well-structured with clear learning objectives and three core lessons. This proposal assesses the current state, identifies gaps, and recommends enhancements to improve clarity and completeness for learners.

**Recommendation**: The course structure is solid. Focus Task 1.2-1.5 on:
1. Expanding lesson depth with examples and hands-on exercises
2. Improving navigation and cross-references with docs
3. Creating explicit learning paths for different user personas
4. Building out advanced courses (deployment patterns, troubleshooting)

---

## Current State Assessment

### What Exists (✅ Already Implemented)

| Component | Status | Quality | Notes |
|-----------|--------|---------|-------|
| **Course Structure** | ✅ | Good | Clear three-lesson sequence |
| **Learning Objectives** | ✅ | Good | Explicitly defined, realistic scope |
| **Prerequisites** | ✅ | Good | Documented entry requirements |
| **Mental Model** | ✅ | Excellent | `plan → inspect → dry-run → apply → handoff` is memorable |
| **Lesson 1** | ✅ | Good | Introduces framework and boundaries |
| **Lesson 2** | ✅ | Good | Covers planning/manifest/dry-run workflow |
| **Lesson 3** | ✅ | Good | Explains apply, rescue, handoff |
| **Hands-on Project** | ✅ | Fair | Project structure exists but may need expansion |
| **Integration to Docs** | 🟡 | Partial | Links to external docs exist but could be clearer |

### What Needs Improvement (🟡 Opportunities)

#### 1. Example Completeness
- **Gap**: Lessons reference concepts but may lack worked examples
- **Impact**: Students struggle to apply concepts to real scenarios
- **Fix**: Add 1-2 concrete examples per lesson (e.g., "Real USB deployment scenario")

#### 2. Hands-on Progression
- **Gap**: Project folder exists but structure unclear
- **Impact**: Unclear what students should *do* vs *read*
- **Fix**: Create explicit project milestones (P1: simple dry-run, P2: full apply, etc.)

#### 3. Troubleshooting and Rescue Path
- **Gap**: Lesson 3 mentions rescue but doesn't teach debugging/recovery
- **Impact**: Students unsure what to do when deployment fails
- **Fix**: Add troubleshooting guide linked from lesson 3

#### 4. Reference Integration
- **Gap**: Links to `docs/howto/`, `docs/specs/` exist but feel disconnected
- **Impact**: Learners don't know when to look deeper into reference docs
- **Fix**: Create explicit "deeper dive" sections in each lesson

#### 5. Multiple Learning Personas
- **Gap**: Course is one-size-fits-all
- **Impact**: Different learners (operators, developers, learners) have different needs
- **Fix**: Create persona-based learning paths and optional modules

#### 6. Course Navigation
- **Gap**: Entry point is good but internal navigation could be clearer
- **Impact**: Learners get lost or miss connections between lessons
- **Fix**: Add lesson-end navigation guides and learning path map

#### 7. Prerequisite Validation
- **Gap**: Prerequisites documented but not validated
- **Impact**: Students may start without required knowledge
- **Fix**: Create optional "prerequisites check" exercises

---

## Proposed Learning Model

### Core Mental Model (Unchanged)

Keep the existing model—it's excellent:

```
PLAN → INSPECT → DRY-RUN → APPLY → HAND OFF
```

Each lesson teaches one phase:
- Lesson 1: Introduces full model + boundaries
- Lesson 2: Teaches PLAN, INSPECT, DRY-RUN in depth
- Lesson 3: Teaches APPLY and HAND OFF

### Learning Path Architecture

#### Standard Path (Recommended for most learners)
1. Overview + Prerequisites + Objectives
2. Lesson 1: Framework and Boundaries (conceptual foundation)
3. Lesson 2: Layout, Manifest, Dry-Run (hands-on planning)
4. Project Phase 1: Plan a simple deployment (dry-run only)
5. Lesson 3: Apply, Rescue, Handoff (careful execution)
6. Project Phase 2: Apply a deployment (with rollback)
7. Optional: Troubleshooting Guide (when things go wrong)

#### Fast-Track Path (For experienced operators)
1. Quick reference card (summary of plan/inspect/dry-run/apply flow)
2. Lesson 2: Layout, Manifest, Dry-Run (skipping intro)
3. Project Phase 1: Plan a deployment
4. Lesson 3: Apply, Rescue, Handoff
5. Project Phase 2: Full deployment

#### Developer Path (For extension/integration developers)
1. Lesson 1: Framework and Boundaries (understand where Sonic stops)
2. Reference: `docs/architecture/services-*` (understand service layer)
3. Reference: `docs/specs/sonic-screwdriver.md` (understand contracts)
4. Optional: Advanced Project (custom build engine)

#### Troubleshooting Path (For debugging failures)
1. Troubleshooting Guide (when something breaks)
2. Rescue and Handoff section (recovery procedures)
3. FAQ/Common Issues
4. Escalation path (when to contact support)

### User Personas

| Persona | Primary Goal | Learning Path | Time | |---|---|---|---| | **Hardware Operator** | Deploy Sonic to hardware safely | Standard Path | 90 min | | **Experienced Admin** | Quick reference + hands-on | Fast-Track | 30 min | | **Developer/Integrator** | Understand Sonic architecture | Developer Path | 60 min | | **Troubleshooter** | Fix deployment failures | Troubleshooting Path | 30 min | | **Learner/Student** | Deep understanding of concepts | Standard Path + exploration | 120 min |

---

## Gap Analysis

## What Each Gap Means

### Gap 1: Example Completeness
**Current**: Lessons explain concepts  
**Needed**: "Here's a specific USB deployment scenario and what the output looks like"  
**Why**: Concrete examples reduce cognitive load and build confidence  
**Fix**: Add "Real Scenario" sidebars to each lesson

### Gap 2: Hands-on Progression  
**Current**: Project folder exists  
**Needed**: Clear milestone structure with increasing complexity  
**Why**: Learners need scaffolded practice, not just reading  
**Fix**: P1 (plan only), P2 (plan+dry-run), P3 (full apply)

### Gap 3: Troubleshooting
**Current**: Lesson 3 mentions rescue  
**Needed**: Detailed troubleshooting decision tree and recovery procedures  
**Why**: Deployments fail; learners need confidence in recovery  
**Fix**: Create `lessons/04-troubleshooting.md`

### Gap 4: Reference Integration
**Current**: Links exist but feel optional  
**Needed**: Clear "when to dive deeper" guidance in lessons  
**Why**: Learners don't know which reference docs apply to them  
**Fix**: Add "Deeper Dive" sections with pointers to specs/howto

### Gap 5: Learning Personas
**Current**: One-size-fits-all course  
**Needed**: Different paths for operators, devs, learners, troubleshooters  
**Why**: Different backgrounds need different pacing and depth  
**Fix**: Create `learning-paths.md` with persona guides

### Gap 6: Navigation
**Current**: Linear lesson structure  
**Needed**: Explicit interconnections and navigation aids  
**Why**: Learners get lost or miss related content  
**Fix**: Add lesson-end navigation and visual learning path map

### Gap 7: Prerequisite Validation
**Current**: Prerequisites documented  
**Needed**: Optional check exercises to validate readiness  
**Why**: Students may start without required knowledge  
**Fix**: Create `prerequisites-check.md` with 3-4 quick exercises

---

## Recommended Task Sequencing

### Task 1.2: Create Enhanced Course Structure
**Input**: This proposal + current course  
**Output**: Updated course skeleton with:
- Expanded project milestones (P1-3)
- Placeholder for troubleshooting lesson
- Learning paths document
- Navigation guides in lesson files

**Effort**: ~2 hours

### Task 1.3: Deepen Existing Lessons with Examples
**Input**: Three lessons from 1.2  
**Output**: Enriched lessons with:
- Real scenario examples (1-2 per lesson)
- Worked output samples
- "Deeper Dive" pointers to specs/howto
- Checkpoint exercises

**Effort**: ~6-8 hours

### Task 1.4: Create Troubleshooting Lesson
**Input**: Troubleshooting content from docs + dev experience  
**Output**: New `lessons/04-troubleshooting.md` with:
- Common failure scenarios
- Diagnostic decision tree
- Recovery procedures
- Escalation guidance

**Effort**: ~3-4 hours

### Task 1.5+: Secondary Courses
**Input**: This analysis + learner feedback  
**Output**: Courses on:
- Deployment patterns (multi-host, staged rollout, A/B)
- Troubleshooting and recovery
- Extension and customization

**Effort**: Later cycles

---

## Proposed Improvements by Priority

### Priority: Critical (Unblock learners)

- **Add worked examples to lessons**: Learners need concrete scenarios
- **Clarify project milestones**: Hands-on work should be scaffolded
- **Add troubleshooting guide**: Deployments fail; recovery must be documented

### Priority: High (Improve clarity)

- **Create learning paths guide**: Different personas have different needs
- **Add "Deeper Dive" pointers**: Learners need navigation to specs/howto
- **Improve lesson navigation**: Explicit connections between lessons

### Priority: Medium (Nice to have)

- **Create prerequisites check exercises**: Validate readiness early
- **Add quick reference card**: Fast-track path for experienced practitioners
- **Expand project with rubric**: Clear grading/completion criteria

### Priority: Low (Future)

- **Create advanced courses**: Deployment patterns, extension development
- **Add video/visual explanations**: For abstract concepts like dry-run
- **Build interactive simulator**: Practice deployments in sandboxed environment

---

## Success Criteria for v1.6

By end of v1.6, the course should enable:

1. ✅ **Novice operator** completes course in < 90 minutes
2. ✅ **Student can plan** a deployment safely with dry-run
3. ✅ **Student understands** when to escalate vs. troubleshoot
4. ✅ **Developer can find** relevant architecture docs
5. ✅ **Course integrates** with `docs/howto/` and `docs/specs/` seamlessly

---

## Comparison: Before vs. After

### Before (v1.5.5)
- ✅ Core course with 3 lessons
- ✅ Clear learning objectives
- 🟢 Good conceptual foundation
- 🟡 Limited examples
- 🟡 Unclear hands-on progression
- 🟡 No troubleshooting path
- 🟡 One-size-fits-all approach

### After (v1.6 - Target)
- ✅ Core course with 4 lessons (added troubleshooting)
- ✅ Clear learning objectives
- ✅ Rich examples and scenarios
- ✅ Scaffolded project milestones
- ✅ Troubleshooting and recovery documented
- ✅ Multiple learning paths for different personas
- ✅ Strong integration with reference docs

---

## Next Steps

Ready to proceed to Task 1.2:

**Task 1.2**: Create enhanced course structure with expanded project milestones, learning paths, and navigation guides.

**Estimated effort**: 2 hours (completing by end of Week 1)

---

## References

- Current course: `/Users/fredbook/Code/uDOS-sonic/courses/01-sonic-screwdriver/`
- Current lessons: `lessons/{01,02,03}-*.md`
- Related docs: `docs/howto/`, `docs/specs/sonic-screwdriver.md`
- Roadmap: [docs/ROADMAP-v1.6.md](../ROADMAP-v1.6.md)
- Development workflow: [docs/uDOS-sonic-dev-brief.md](../uDOS-sonic-dev-brief.md)

