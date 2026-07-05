"""Entry point: wire config, logging, signals, and run the camera stream server.

Run on the Pi (defaults shown):

    python main.py
    # or override via env, e.g. HTTP_PORT=8080 CAM_FPS=20 python main.py
"""

from __future__ import annotations

import asyncio
import signal

import structlog
from aiohttp import web

from camera import Camera
from config import Config
from exceptions import CameraStartError
from frames import FrameBuffer
from server import StreamServer

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
    frame_buffer = FrameBuffer()
    camera = Camera(config, frame_buffer)
    try:
        camera.start()
    except CameraStartError as exc:
        # Exit and let systemd retry: mirrors how the control server handles a
        # slow-to-appear Arduino.
        log.error("camera_start_failed", error=str(exc))
        return

    server = StreamServer(config, frame_buffer)
    runner = web.AppRunner(server.build_app())
    await runner.setup()
    site = web.TCPSite(runner, config.http_host, config.http_port)
    await site.start()
    log.info("listening", host=config.http_host, port=config.http_port)

    # systemd sends SIGTERM; Ctrl-C sends SIGINT. Either triggers a clean stop.
    stop_event = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stop_event.set)
    await stop_event.wait()

    log.info("shutting_down")
    await runner.cleanup()
    camera.stop()


def main() -> int:
    _configure_logging()
    asyncio.run(_run(Config.from_env()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
