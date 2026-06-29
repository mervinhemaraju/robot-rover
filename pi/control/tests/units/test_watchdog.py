"""Unit tests for the failsafe watchdog."""

import asyncio

from watchdog import Watchdog

_TIMEOUT = 0.05  # short timeout so tests stay fast


def test_idle_does_not_trip() -> None:
    # Arrange: a watchdog that records every time it fires.
    fired: list[int] = []

    async def on_timeout() -> None:
        fired.append(1)

    async def scenario() -> None:
        watchdog = Watchdog(_TIMEOUT, on_timeout)
        watchdog.start()
        await asyncio.sleep(_TIMEOUT * 3)  # never kicked
        await watchdog.stop()

    # Act
    asyncio.run(scenario())

    # Assert: no client activity means no false failsafe.
    assert fired == []


def test_trips_once_after_activity_then_silence() -> None:
    # Arrange
    fired: list[int] = []

    async def on_timeout() -> None:
        fired.append(1)

    async def scenario() -> None:
        watchdog = Watchdog(_TIMEOUT, on_timeout)
        watchdog.start()
        watchdog.kick()  # a command arrived
        await asyncio.sleep(_TIMEOUT * 3)  # then the stream goes quiet
        await watchdog.stop()

    # Act
    asyncio.run(scenario())

    # Assert: exactly one stop, not a stream of them.
    assert fired == [1]
