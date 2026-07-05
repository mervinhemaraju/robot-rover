"""Latest-frame handoff between the encoder thread and asyncio consumers.

The hardware encoder delivers JPEGs on its own thread; HTTP clients consume
them on the asyncio loop. Only the newest frame is kept: a slow client skips
frames instead of building up a backlog, so the driver always sees "now"
rather than a growing delay.
"""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator


class FrameBuffer:
    """Single-slot frame store with wake-up for any number of subscribers.

    Must be constructed on the event loop thread (it captures the running
    loop for the thread-safe publish path).
    """

    def __init__(self) -> None:
        self._loop = asyncio.get_running_loop()
        self._frame: bytes | None = None
        self._seq = 0
        self._new_frame = asyncio.Event()

    def publish_from_thread(self, frame: bytes) -> None:
        """Hand a frame over from the encoder thread (thread-safe)."""
        self._loop.call_soon_threadsafe(self.publish, frame)

    def publish(self, frame: bytes) -> None:
        """Store a frame and wake all waiting subscribers (loop thread only)."""
        self._frame = frame
        self._seq += 1
        # Swap the event before setting it so late subscribers wait on a fresh
        # one; everyone already waiting is released exactly once.
        event = self._new_frame
        self._new_frame = asyncio.Event()
        event.set()

    async def frames(self) -> AsyncIterator[bytes]:
        """Yield each new frame, skipping any missed while the consumer was busy."""
        last_seq = 0
        while True:
            if self._frame is not None and self._seq != last_seq:
                last_seq = self._seq
                yield self._frame
                continue
            await self._new_frame.wait()
