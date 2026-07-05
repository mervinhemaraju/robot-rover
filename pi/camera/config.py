"""Environment-driven configuration for the camera stream service.

All tunables come from environment variables so nothing is hardcoded and the
same code runs on the bench and on the rover.
"""

from __future__ import annotations

import os
from dataclasses import dataclass


def _env_flag(name: str, default: str = "0") -> bool:
    return os.environ.get(name, default).strip().lower() in ("1", "true", "yes")


@dataclass(frozen=True)
class Config:
    """Immutable runtime configuration."""

    http_host: str
    http_port: int
    frame_width: int
    frame_height: int
    frame_rate: int
    hflip: bool
    vflip: bool

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            # 0.0.0.0 so the phone on the same Wi-Fi can reach it, not just localhost.
            http_host=os.environ.get("HTTP_HOST", "0.0.0.0"),
            http_port=int(os.environ.get("HTTP_PORT", "8080")),
            frame_width=int(os.environ.get("CAM_WIDTH", "640")),
            frame_height=int(os.environ.get("CAM_HEIGHT", "480")),
            frame_rate=int(os.environ.get("CAM_FPS", "30")),
            # Mount-orientation fixes are config, not code.
            hflip=_env_flag("CAM_HFLIP"),
            vflip=_env_flag("CAM_VFLIP"),
        )
