# New Pi Service: $ARGUMENTS

Scaffold a new Python service for the Raspberry Pi.

## 1. Clarify intent

If $ARGUMENTS does not make the service purpose clear, ask:
- What does this service do? (WebSocket server, camera stream, serial bridge)
- Does it need serial access to the Arduino?
- Does it need to expose a network port? Which one?

## 2. Determine location

Pi services live in `pi/<service-name>/`. The entry point is `main.py`.
If the `pi/` root folder does not exist yet, note it must be created
and add it to the Repository layout table in `.claude/CLAUDE.md`.

## 3. Scaffold the service

```
pi/<service-name>/
  main.py          # entry point, asyncio event loop + signal handling
  service.py       # core service logic
  exceptions.py    # custom exception types
  requirements.txt # pinned dependencies
```

`main.py` template:

```python
import asyncio
import signal
import structlog

from service import Service

log = structlog.get_logger()

def _handle_shutdown(sig: signal.Signals, loop: asyncio.AbstractEventLoop) -> None:
    log.info("shutdown_signal_received", signal=sig.name)
    loop.stop()

async def main() -> None:
    service = Service()
    await service.start()

if __name__ == "__main__":
    loop = asyncio.new_event_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, _handle_shutdown, sig, loop)
    try:
        loop.run_until_complete(main())
    finally:
        loop.close()
```

## 4. Systemd unit file

Create `pi/<service-name>/<service-name>.service`:

```ini
[Unit]
Description=Rover <service-name> service
After=network.target

[Service]
Type=simple
User=th3pl4gu3
WorkingDirectory=/home/th3pl4gu3/rover/<service-name>
EnvironmentFile=/home/th3pl4gu3/rover/.env
ExecStart=/home/th3pl4gu3/rover/.venv/bin/python main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Install instructions (to include in the doc):
```bash
sudo cp <service-name>.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable <service-name>
sudo systemctl start <service-name>
```

## 5. Apply style rules

Verify the service follows `.claude/rules/python-pi-style.md`:
- `pyserial` with explicit timeout if serial is needed
- `asyncio` throughout — no `time.sleep()`, no threading
- `SIGTERM` handler present
- All config via environment variables
- `structlog` for logging

## 6. Report

State every file created and a one-line summary of what the service does.
