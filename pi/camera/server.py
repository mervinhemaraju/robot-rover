"""HTTP server exposing the camera as an MJPEG stream.

GET /stream  -> multipart/x-mixed-replace stream of JPEG frames (MJPEG).
GET /healthz -> "ok" once the service is up (frames may still be warming up).
"""

from __future__ import annotations

import structlog
from aiohttp import web

from config import Config
from frames import FrameBuffer

log = structlog.get_logger()

_BOUNDARY = "frame"


class StreamServer:
    """aiohttp application serving the shared FrameBuffer to any number of clients."""

    def __init__(self, config: Config, frame_buffer: FrameBuffer) -> None:
        self._config = config
        self._frames = frame_buffer

    def build_app(self) -> web.Application:
        app = web.Application()
        app.add_routes(
            [
                web.get("/stream", self._stream),
                web.get("/healthz", self._healthz),
            ]
        )
        return app

    async def _healthz(self, _request: web.Request) -> web.Response:
        return web.Response(text="ok")

    async def _stream(self, request: web.Request) -> web.StreamResponse:
        response = web.StreamResponse(
            status=200,
            headers={
                "Content-Type": f"multipart/x-mixed-replace; boundary={_BOUNDARY}",
                # Live video must never be cached or buffered by intermediaries.
                "Cache-Control": "no-store",
                "Pragma": "no-cache",
            },
        )
        await response.prepare(request)
        log.info("client_connected", remote=request.remote)
        try:
            async for frame in self._frames.frames():
                await response.write(
                    b"--" + _BOUNDARY.encode() + b"\r\n"
                    b"Content-Type: image/jpeg\r\n"
                    b"Content-Length: " + str(len(frame)).encode() + b"\r\n"
                    b"\r\n" + frame + b"\r\n"
                )
        except (ConnectionResetError, ConnectionError):
            # Normal end of stream: the viewer closed the app or dropped off Wi-Fi.
            pass
        finally:
            log.info("client_disconnected", remote=request.remote)
        return response
