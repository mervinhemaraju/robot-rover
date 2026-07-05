"""Camera capture: Picamera2 driving the Pi's hardware MJPEG encoder.

The Pi 3B encodes MJPEG in the VideoCore hardware, so streaming costs almost
no CPU. Frames land in a FrameBuffer for the HTTP server to fan out.
"""

from __future__ import annotations

import io

import structlog
from libcamera import Transform
from picamera2 import Picamera2
from picamera2.encoders import MJPEGEncoder, Quality
from picamera2.outputs import FileOutput

from config import Config
from exceptions import CameraStartError
from frames import FrameBuffer

log = structlog.get_logger()


class _FrameSink(io.BufferedIOBase):
    """File-like sink for FileOutput; receives one complete JPEG per write().

    write() runs on the encoder's thread, so it must not touch asyncio state
    directly; publish_from_thread does the thread-safe handoff.
    """

    def __init__(self, frame_buffer: FrameBuffer) -> None:
        self._frames = frame_buffer

    def writable(self) -> bool:
        return True

    def write(self, buf: bytes) -> int:
        self._frames.publish_from_thread(bytes(buf))
        return len(buf)


class Camera:
    """Owns the Picamera2 pipeline; start() begins publishing, stop() releases it."""

    def __init__(self, config: Config, frame_buffer: FrameBuffer) -> None:
        self._config = config
        self._sink = _FrameSink(frame_buffer)
        self._picam2: Picamera2 | None = None

    def start(self) -> None:
        try:
            picam2 = Picamera2()
        except (RuntimeError, IndexError) as exc:
            raise CameraStartError(f"camera not detected: {exc}") from exc

        # Requesting the target size here makes the ISP scale down from the
        # full-field-of-view binned sensor mode; the imx219's native VGA mode
        # is heavily cropped and would give tunnel vision while driving.
        # YUV420 is the format the hardware MJPEG encoder consumes.
        video_config = picam2.create_video_configuration(
            main={
                "size": (self._config.frame_width, self._config.frame_height),
                "format": "YUV420",
            },
            transform=Transform(
                hflip=int(self._config.hflip), vflip=int(self._config.vflip)
            ),
            controls={"FrameRate": float(self._config.frame_rate)},
        )
        try:
            picam2.configure(video_config)
            picam2.start_recording(
                MJPEGEncoder(), FileOutput(self._sink), quality=Quality.MEDIUM
            )
        except (RuntimeError, ValueError) as exc:
            picam2.close()
            raise CameraStartError(f"capture pipeline failed to start: {exc}") from exc

        self._picam2 = picam2
        log.info(
            "camera_started",
            width=self._config.frame_width,
            height=self._config.frame_height,
            fps=self._config.frame_rate,
        )

    def stop(self) -> None:
        if self._picam2 is None:
            return
        self._picam2.stop_recording()
        self._picam2.close()
        self._picam2 = None
        log.info("camera_stopped")
