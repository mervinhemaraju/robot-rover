# Phase Gate — Don't Skip Ahead

Before suggesting any work that belongs to Phase N, verify that Phase N-1
is marked complete in the **Current state** section of `.claude/CLAUDE.md`.

## How to check

Read `.claude/CLAUDE.md`. The **Current state** section lists phase statuses.
A phase is complete when it is marked as such and its deliverable is met
(as described in the **Build phases** section).

## If the previous phase is not complete

- Do not proceed with Phase N work
- Tell the user which phase is still open and what is left to complete it
- Offer to help finish the current phase instead

## Why this matters

Half-assembled phases create hard-to-debug states — e.g. writing Flutter
WebSocket code before serial communication with the Arduino is proven working.
Each phase deliverable is a verified checkpoint; skipping one hides assumptions.
