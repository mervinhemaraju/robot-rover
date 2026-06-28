# What's Next

Survey the current project state and produce a prioritised list of actionable next steps.

## 1. Read project state

Read these files in full before producing any output:

- `.claude/CLAUDE.md` — focus on **Build phases** (deliverables) and **Current state** (done/pending per phase)
- `.claude/inventory.yaml` — check which parts are owned/in-use vs. in-transit/deferred; parts not yet on hand are blockers

## 2. Determine active phase

Identify the lowest-numbered phase that is not yet marked complete. That is the active phase. Note its deliverable.

## 3. Produce the next-steps list

Output the following sections:

---

### Active phase: Phase <N> — <Name>

**Deliverable:** one sentence from the build phases definition.

**What's next — prioritised**

Number each item. Order by: blockers first (must-resolve), then hardware steps, then software steps, then testing/verification steps.

For each item include:
- What to do (one clear sentence)
- Why it matters or what it unblocks (one sentence)
- Any prerequisite that must be true first (parts on hand, previous step done, etc.)

**Blocked items** (cannot start yet)

List anything that is blocked and state the blocker explicitly:
- Part not yet received
- Previous step not confirmed complete
- Dependency on another task

**Upcoming phases (preview)**

One bullet per future phase: the single most important thing to think about or prepare for that phase, so nothing catches you off guard.

---

## 4. Call out risks

If anything in the current state looks risky or inconsistent (e.g. a step marked done but a dependency missing, a part listed in-use but wiring not documented), flag it here as a one-liner.

## 5. Do not modify any files

This skill is read-only. Do not update CLAUDE.md, inventory.yaml, or any other file. Report only.
