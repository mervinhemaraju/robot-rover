"""Entry point: wire config, logging, signals, and run the control server.

Run on the Pi (defaults shown):

    python main.py
    # or override via env, e.g. SERIAL_PORT=/dev/ttyACM1 WS_PORT=8765 python main.py
"""

from __future__ import annotations

import asyncio
import signal

import structlog
import websockets

from config import Config
from controller import MotorController
from exceptions import SerialConnectionError
from serial_link import MotorSerial
from server import ControlServer
from watchdog import Watchdog

log = structlog.get_logger()


def _configure_logging() -> None:
    structlog.configure(
        processors=[
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.dev.ConsoleRenderer(),
        ],
    )


async def _run(config: Config) -> None:
    serial_link = MotorSerial(config.serial_port, baud=config.serial_baud)
    controller = MotorController(serial_link)
    try:
        await controller.start()
    except SerialConnectionError as exc:
        log.error("serial_connect_failed", error=str(exc))
        return

    watchdog = Watchdog(config.watchdog_timeout_s, controller.stop_motors)
    watchdog.start()
    server = ControlServer(config, controller, watchdog)

    # systemd sends SIGTERM; Ctrl-C sends SIGINT. Either triggers a clean stop.
    stop_event = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stop_event.set)

    async with websockets.serve(server.handle, config.ws_host, config.ws_port):
        log.info("listening", host=config.ws_host, port=config.ws_port)
        await stop_event.wait()

    log.info("shutting_down")
    await watchdog.stop()
    await controller.close()  # stops motors and closes the serial port


def main() -> int:
    _configure_logging()
    asyncio.run(_run(Config.from_env()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
