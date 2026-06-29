"""Parsing and validation of incoming WebSocket drive commands.

Wire format (JSON):
    {"cmd": "F|R|B|S", "spd": 0-255, "steer": -1.0..1.0}

- cmd  : required. F = forward, R = reverse, B = brake, S = soft stop.
- spd  : optional (default 0). Clamped to [0, max_speed]. Ignored for B / S.
- steer: optional (default 0.0). Clamped to [-1.0, 1.0]. Ignored for B / S.

External input is untrusted, so this module fails fast on anything malformed and
clamps numeric ranges rather than trusting the client.
"""

from __future__ import annotations

import json
from dataclasses import dataclass

from exceptions import InvalidCommandError

VALID_COMMANDS = frozenset({"F", "R", "B", "S"})


@dataclass(frozen=True)
class DriveCommand:
    """A validated drive command."""

    cmd: str
    spd: int = 0
    steer: float = 0.0


def _clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def _require_number(value: object, field: str) -> float:
    # bool is a subclass of int; reject it so {"spd": true} is not treated as 1.
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise InvalidCommandError(f"{field} must be a number, got {value!r}")
    return float(value)


def parse(raw: str | bytes, max_speed: int = 255) -> DriveCommand:
    """Parse and validate a raw WebSocket message into a DriveCommand.

    Raises:
        InvalidCommandError: the message is not a well-formed drive command.
    """
    try:
        payload = json.loads(raw)
    except (json.JSONDecodeError, TypeError) as exc:
        raise InvalidCommandError(f"not valid JSON: {exc}") from exc

    if not isinstance(payload, dict):
        raise InvalidCommandError("payload must be a JSON object")

    cmd = payload.get("cmd")
    if cmd not in VALID_COMMANDS:
        raise InvalidCommandError(
            f"cmd must be one of {sorted(VALID_COMMANDS)}, got {cmd!r}"
        )

    spd = int(_clamp(_require_number(payload.get("spd", 0), "spd"), 0, max_speed))
    steer = _clamp(_require_number(payload.get("steer", 0.0), "steer"), -1.0, 1.0)
    return DriveCommand(cmd=cmd, spd=spd, steer=steer)
