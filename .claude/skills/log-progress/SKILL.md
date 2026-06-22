# Log Progress: $ARGUMENTS

Document the work completed in this session into `docs/`.

## 1. Determine the file

Docs are organised into subfolders by component, with numbered files to preserve order.

**Subfolder by component:**

| Component | Subfolder |
|---|---|
| Raspberry Pi setup / OS / networking | `docs/raspberry-pi/` |
| Arduino sketches / motor control | `docs/arduino/` |
| Flutter remote-controller app | `docs/flutter-app/` |
| Power / wiring / hardware assembly | `docs/hardware/` |
| General / cross-cutting | `docs/general/` |

**File naming:** `<N>-<slug>.md` where `N` is the next sequential number in that subfolder.

Examples:
- `docs/raspberry-pi/1-initial-setup.md`
- `docs/raspberry-pi/2-wifi-bluetooth.md`
- `docs/arduino/1-motor-sketch.md`
- `docs/flutter-app/1-project-setup.md`

To find the next number, list existing files in the subfolder and increment the highest.

If the file already exists (resuming a session), append a new dated section — do not rewrite existing content.

## 2. Gather context

- `git diff` and `git log --oneline` to see what changed this session
- Current phase status from `.claude/CLAUDE.md`

## 3. Write the doc

Keep it plain, short, and readable by someone with no prior context:

---
# <Title>

## What was done
- One bullet per step, plain English, no jargon

## How to reproduce
Numbered steps anyone could follow from scratch.
Exact commands, exact values — nothing left to guesswork.

## Blockers
| Issue | Status | Notes |
|---|---|---|
| What went wrong | Resolved / Open | How it was fixed or what's needed |

*(Omit this section if there were no blockers)*

---

## 4. Update current state

If the session advanced a phase, update the **Current state** section
in `.claude/CLAUDE.md` to reflect the new status.

## 5. Report

State which file was written or updated, and one line summarising what was logged.
