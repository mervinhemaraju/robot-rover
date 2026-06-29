"""WebSocket control server: app messages in, serial commands out.

Pipeline per message: parse -> validate -> mix -> queue to controller, then kick
the watchdog and acknowledge the client. The server holds no driving state; it
wires the pure logic (protocol, mixer) to the serial controller.
"""

from __future__ import annotations

import json
from typing import TYPE_CHECKING

import structlog
from websockets.exceptions import ConnectionClosed

from config import Config
from controller import MotorController
from exceptions import InvalidCommandError
from mixer import to_serial
from protocol import parse
from watchdog import Watchdog

if TYPE_CHECKING:
    # Imported only for type checking to stay robust across websockets versions.
    from websockets.server import WebSocketServerProtocol

log = structlog.get_logger()


class ControlServer:
    """Handles WebSocket connections and forwards drive commands to the rover."""

    def __init__(
        self, config: Config, controller: MotorController, watchdog: Watchdog
    ) -> None:
        self._config = config
        self._controller = controller
        self._watchdog = watchdog

    async def handle(self, websocket: "WebSocketServerProtocol") -> None:
        """Connection lifecycle: read messages until the client goes away."""
        peer = websocket.remote_address
        log.info("client_connected", peer=peer)
        try:
            async for raw in websocket:
                await self._handle_message(websocket, raw)
        except ConnectionClosed:
            log.info("client_connection_closed", peer=peer)
        finally:
            # Safety: never leave the rover driving after a client disconnects.
            await self._controller.stop_motors()
            log.info("client_disconnected", peer=peer)

    async def _handle_message(
        self, websocket: "WebSocketServerProtocol", raw: str | bytes
    ) -> None:
        try:
            command = parse(raw, max_speed=self._config.max_speed)
        except InvalidCommandError as exc:
            log.warning("invalid_command", error=str(exc))
            await self._reply(websocket, ok=False, error=str(exc))
            return

        # Valid command counts as activity, so reset the failsafe first.
        self._watchdog.kick()
        serial_command = to_serial(command, steer_gain=self._config.steer_gain)
        await self._controller.send(serial_command)
        await self._reply(websocket, ok=True)

    async def _reply(
        self,
        websocket: "WebSocketServerProtocol",
        ok: bool,
        error: str | None = None,
    ) -> None:
        payload: dict[str, object] = {"ok": ok}
        if error is not None:
            payload["error"] = error
        try:
            await websocket.send(json.dumps(payload))
        except ConnectionClosed:
            pass  # Client already gone; nothing to acknowledge.
