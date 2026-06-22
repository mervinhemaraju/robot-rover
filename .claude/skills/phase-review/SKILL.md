# Phase Review: $ARGUMENTS

Summarise the current build phase status and update CLAUDE.md if needed.

## 1. Read current state

Read `.claude/CLAUDE.md` — focus on:
- **Build phases** section (deliverables per phase)
- **Current state** section (what is done, what is pending)

Also read `.claude/inventory.yaml` to check if any in-transit parts are
blockers for the current phase.

## 2. Produce the summary

Output a concise status report:

---
### Phase <N> — <Name> — <Status: In Progress / Complete / Blocked>

**Done**
- Bullet list of confirmed completed steps

**Pending**
- Bullet list of what still needs to happen before this phase is complete

**Blockers**
| Blocker | Type | Notes |
|---|---|---|
| Description | Parts / Software / Hardware | What is needed to unblock |

**Deliverable met?** Yes / No — one sentence on why or why not.

---

## 3. Update CLAUDE.md

If the review reveals that the current state in CLAUDE.md is out of date
(e.g. a step is done but not recorded), update the **Current state** section
to match reality. State what was changed.

## 4. Suggest next action

One sentence: the single most valuable next step to advance the phase.
