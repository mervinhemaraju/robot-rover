"""Failsafe watchdog: stop the rover if commands stop arriving.

Accelerate is hold-to-drive, so the app streams commands while a button is held.
If that stream stops (client crash, Wi-Fi drop, app backgrounded) the rover must
not keep driving. The watchdog fires a stop callback once when no kick() has
happened within the timeout, then re-arms when activity resumes.
"""

from __future__ import annotations

import asyncio
from collections.abc import Awaitable, Callable

import structlog

log = structlog.get_logger()


class Watchdog:
    """Calls on_timeout once each time the command stream goes quiet."""

    def __init__(
        self, timeout_s: float, on_timeout: Callable[[], Awaitable[None]]
    ) -> None:
        self._timeout_s = timeout_s
        self._on_timeout = on_timeout
        self._kicked = asyncio.Event()
        self._task: asyncio.Task[None] | None = None
        self._seen_activity = False

    def start(self) -> None:
        self._task = asyncio.create_task(self._run(), name="watchdog")

    def kick(self) -> None:
        """Record activity; resets the countdown."""
        self._kicked.set()

    async def stop(self) -> None:
        if self._task is not None:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass

    async def _run(self) -> None:
        while True:
            try:
                await asyncio.wait_for(self._kicked.wait(), timeout=self._timeout_s)
                self._kicked.clear()
                self._seen_activity = True
            except asyncio.TimeoutError:
                # Only trip if commands actually arrived since the last trip, so
                # an idle server (no client connected) does not raise a false
                # failsafe. Fires once per quiet period, then re-arms on activity.
                if self._seen_activity:
                    self._seen_activity = False
                    log.warning("watchdog_timeout", timeout_s=self._timeout_s)
                    await self._on_timeout()
