"""Async owner of the serial link.

All serial access funnels through a single worker coroutine, so the one physical
port has exactly one owner (no read/write races) and the blocking pyserial calls
run in a thread executor (the asyncio event loop is never blocked).

Commands are coalesced: only the latest pending command is sent. Under a stream
of joystick updates this keeps latency low and avoids a backlog, which is the
correct behaviour for real-time control (the freshest intent wins).
"""

from __future__ import annotations

import asyncio

import structlog

from exceptions import SerialError
from serial_link import MotorSerial

log = structlog.get_logger()


class MotorController:
    """Serializes access to the Arduino over a single background worker."""

    def __init__(self, serial_link: MotorSerial) -> None:
        self._serial = serial_link
        self._pending: str | None = None
        self._wakeup = asyncio.Event()
        self._worker: asyncio.Task[None] | None = None

    async def start(self) -> None:
        """Open the serial port and start the worker.

        Raises:
            SerialConnectionError: the port could not be opened.
        """
        loop = asyncio.get_running_loop()
        await loop.run_in_executor(None, self._serial.open)
        self._worker = asyncio.create_task(self._run(), name="serial-worker")

    async def send(self, command: str) -> None:
        """Queue a serial command (latest wins; non-blocking)."""
        self._pending = command
        self._wakeup.set()

    async def stop_motors(self) -> None:
        """Convenience helper: request an immediate soft stop."""
        await self.send("S")

    async def close(self) -> None:
        """Cancel the worker and leave the rover stopped with the port closed."""
        if self._worker is not None:
            self._worker.cancel()
            try:
                await self._worker
            except asyncio.CancelledError:
                pass
        loop = asyncio.get_running_loop()
        await loop.run_in_executor(None, self._safe_final_stop)

    def _safe_final_stop(self) -> None:
        try:
            if self._serial.is_open:
                self._serial.send("S")
        except SerialError as exc:
            log.error("final_stop_failed", error=str(exc))
        self._serial.close()

    async def _run(self) -> None:
        loop = asyncio.get_running_loop()
        while True:
            await self._wakeup.wait()
            self._wakeup.clear()
            command = self._pending
            self._pending = None
            if command is None:
                continue
            try:
                await loop.run_in_executor(None, self._io, command)
            except SerialError as exc:
                log.error("serial_io_failed", cmd=command, error=str(exc))

    def _io(self, command: str) -> None:
        """Blocking serial write + non-blocking drain. Runs in an executor."""
        self._serial.send(command)
        for line in self._serial.read_available():
            log.info("arduino", line=line)
