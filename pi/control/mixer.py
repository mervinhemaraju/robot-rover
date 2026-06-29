"""Translate a validated DriveCommand into a rover_motors serial command.

Differential-drive mix for the control scheme (steering-only joystick + separate
accelerate / reverse / brake buttons):

    base  = +spd (forward) or -spd (reverse)
    turn  = steer_gain * steer * spd
    left  = base + turn
    right = base - turn

Positive steer turns right (left wheels run faster than right). If a wheel would
exceed the PWM range, both wheels are scaled together so the turn ratio (and thus
the curve the rover follows) is preserved rather than clipped.

This module is pure: no I/O, fully unit-testable.
"""

from __future__ import annotations

from protocol import DriveCommand

_PWM_MAX = 255


def to_serial(command: DriveCommand, steer_gain: float = 1.0) -> str:
    """Return the rover_motors serial line for a command ('D l r' / 'S' / 'B')."""
    if command.cmd == "S":
        return "S"
    if command.cmd == "B":
        return "B"

    base = command.spd if command.cmd == "F" else -command.spd
    turn = steer_gain * command.steer * command.spd
    left = base + turn
    right = base - turn

    # Scale both wheels down together if either exceeds the PWM range, so the
    # left/right ratio (the turn shape) is preserved instead of being clipped.
    peak = max(abs(left), abs(right))
    if peak > _PWM_MAX:
        scale = _PWM_MAX / peak
        left *= scale
        right *= scale

    return f"D {int(round(left))} {int(round(right))}"
