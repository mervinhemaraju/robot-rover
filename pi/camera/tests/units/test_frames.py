"""Unit tests for the latest-frame FrameBuffer."""

import asyncio
import threading

from frames import FrameBuffer

_WAIT = 1.0  # generous upper bound so a broken buffer fails fast, not hangs


async def _first_frame(buffer: FrameBuffer) -> bytes:
    return await asyncio.wait_for(anext(buffer.frames()), timeout=_WAIT)


def test_subscriber_receives_published_frame() -> None:
    # Arrange
    async def scenario() -> bytes:
        buffer = FrameBuffer()
        task = asyncio.create_task(_first_frame(buffer))
        await asyncio.sleep(0)  # let the subscriber start waiting

        # Act
        buffer.publish(b"jpeg-1")
        return await task

    # Assert
    assert asyncio.run(scenario()) == b"jpeg-1"


def test_slow_subscriber_skips_to_latest_frame() -> None:
    # Arrange: a subscriber that collects two frames.
    async def scenario() -> list[bytes]:
        buffer = FrameBuffer()
        received: list[bytes] = []

        async def consume() -> None:
            async for frame in buffer.frames():
                received.append(frame)
                if len(received) == 2:
                    return

        task = asyncio.create_task(consume())
        await asyncio.sleep(0)

        # Act: one frame is consumed, then three arrive back-to-back before
        # the subscriber gets scheduled again.
        buffer.publish(b"jpeg-1")
        await asyncio.sleep(0.01)
        buffer.publish(b"jpeg-2")
        buffer.publish(b"jpeg-3")
        buffer.publish(b"jpeg-4")
        await asyncio.wait_for(task, timeout=_WAIT)
        return received

    # Assert: the middle frames were dropped, not queued.
    assert asyncio.run(scenario()) == [b"jpeg-1", b"jpeg-4"]


def test_multiple_subscribers_each_receive_the_frame() -> None:
    # Arrange
    async def scenario() -> list[bytes]:
        buffer = FrameBuffer()
        tasks = [asyncio.create_task(_first_frame(buffer)) for _ in range(3)]
        await asyncio.sleep(0)

        # Act
        buffer.publish(b"jpeg-1")
        return list(await asyncio.gather(*tasks))

    # Assert: fan-out, not first-come-first-served.
    assert asyncio.run(scenario()) == [b"jpeg-1", b"jpeg-1", b"jpeg-1"]


def test_publish_from_thread_delivers_to_loop_subscriber() -> None:
    # Arrange: mimics the encoder thread handing a frame across.
    async def scenario() -> bytes:
        buffer = FrameBuffer()
        thread = threading.Thread(
            target=buffer.publish_from_thread, args=(b"jpeg-thread",)
        )

        # Act
        thread.start()
        frame = await _first_frame(buffer)
        thread.join()
        return frame

    # Assert
    assert asyncio.run(scenario()) == b"jpeg-thread"


def test_late_subscriber_gets_current_frame_immediately() -> None:
    # Arrange: a frame published before anyone subscribes.
    async def scenario() -> bytes:
        buffer = FrameBuffer()
        buffer.publish(b"jpeg-1")

        # Act: subscribe after the fact.
        return await _first_frame(buffer)

    # Assert: new viewers see the current frame without waiting for the next one.
    assert asyncio.run(scenario()) == b"jpeg-1"
