# Python on the Pi — Style and Conventions

Applies in addition to the global Python rules (`~/.claude/rules/python.md`).

## Serial (pyserial)

- Always use `pyserial` for Arduino communication — no raw file I/O on `/dev/tty*`
- Always set an explicit `timeout` on `serial.Serial()` — never block indefinitely
- Always check `ser.is_open` before writing
- Wrap serial writes in try/except `serial.SerialException` — connection can drop

```python
import serial

ser = serial.Serial("/dev/ttyACM0", baudrate=115200, timeout=1.0)
```

## Async

- All network services (WebSocket, camera stream) use `asyncio` — no threading
- Never mix `time.sleep()` into async code — use `await asyncio.sleep()`
- Serial reads that block must run in `asyncio.get_event_loop().run_in_executor()`
  to avoid blocking the event loop

## Services

- Every Pi service must handle `SIGTERM` for clean shutdown (systemd sends this):

```python
import signal, asyncio

def _shutdown(sig, loop):
    loop.stop()

loop = asyncio.get_event_loop()
loop.add_signal_handler(signal.SIGTERM, _shutdown, signal.SIGTERM, loop)
```

- Log with `structlog`, never `print()` or bare `logging`
- All config (serial port path, WebSocket port, etc.) via environment variables —
  never hardcoded

## Device path

The Arduino will appear as `/dev/ttyACM0` (or `/dev/ttyACM1` if another device
is present). Always make the device path configurable via an environment variable:

```python
import os
SERIAL_PORT = os.environ.get("SERIAL_PORT", "/dev/ttyACM0")
```

## Permissions

The `th3pl4gu3` user must be in the `dialout` group to access serial:
`sudo usermod -aG dialout th3pl4gu3` — only needs to be done once.
