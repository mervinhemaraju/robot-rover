"""Environment-driven configuration for the control server.

All tunables come from environment variables so nothing is hardcoded and the
same code runs on the bench and on the rover.
"""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    """Immutable runtime configuration."""

    ws_host: str
    ws_port: int
    serial_port: str
    serial_baud: int
    watchdog_timeout_s: float
    steer_gain: float
    max_speed: int

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            # 0.0.0.0 so the phone on the same Wi-Fi can reach it, not just localhost.
            ws_host=os.environ.get("WS_HOST", "0.0.0.0"),
            ws_port=int(os.environ.get("WS_PORT", "8765")),
            serial_port=os.environ.get("SERIAL_PORT", "/dev/ttyACM0"),
            serial_baud=int(os.environ.get("SERIAL_BAUD", "115200")),
            # Failsafe: stop if no command arrives within this window (hold-to-drive).
            watchdog_timeout_s=float(os.environ.get("WATCHDOG_TIMEOUT_S", "0.3")),
            steer_gain=float(os.environ.get("STEER_GAIN", "1.0")),
            max_speed=int(os.environ.get("MAX_SPEED", "255")),
        )
