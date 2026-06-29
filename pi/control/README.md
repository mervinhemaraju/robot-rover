# Control server (Phase 3)

WebSocket control server for the rover. Receives JSON drive commands from the
Flutter app and forwards them to the Arduino over serial. Deploys to
`~/rover/control/` on the Pi.

## Message contract

Incoming (app -> server), one JSON object per WebSocket message:

```json
{ "cmd": "F", "spd": 180, "steer": 0.3 }
```

- `cmd`: `F` forward, `R` reverse, `B` brake, `S` soft stop (required).
- `spd`: `0`-`255` (optional, default 0; ignored for `B`/`S`).
- `steer`: `-1.0`..`1.0`, positive = right (optional, default 0; ignored for `B`/`S`).

Outgoing (server -> app): `{"ok": true}` or `{"ok": false, "error": "..."}`.

## Client streaming contract

The firmware is stream-to-drive: it stops if commands stop arriving. A client
MUST therefore behave as follows:

- **While a control is held**, re-send the current command continuously.
  Recommended cadence: ~100 ms, comfortably inside `WATCHDOG_TIMEOUT_S` (0.3 s).
  Sending a command once is not enough: the watchdog will stop the rover.
- **On release**, send `S` (soft stop) once, then go quiet.
- **Brake** is `B`; hold = keep sending `B`, release = send `S`.
- Forward<->reverse: pass through `S` first. The client must enforce this; see below.

`{"ok": true}` means the server parsed and forwarded the command to the Arduino.
It does NOT mean the Arduino executed it. A forward->reverse flip without a stop
in between is rejected by the Arduino's interlock (`ERR interlock`), but the
server still replies `{"ok": true}` (it does not read the Arduino reply back).
So clients must enforce the stop-before-reverse rule themselves.

Reference client: the Flutter app in `remote-controller/` (`DriveSequencer` +
`RoverController`, 100 ms heartbeat).

## Safety

- The Arduino's forward<->reverse interlock remains the last line of defence.
- A watchdog stops the rover if no command arrives within `WATCHDOG_TIMEOUT_S`
  (accelerate is hold-to-drive, so the app streams commands).
- Motors are stopped on client disconnect and on SIGTERM/SIGINT.

## Configuration (environment variables)

| Variable | Default | Meaning |
| --- | --- | --- |
| `WS_HOST` | `0.0.0.0` | WebSocket bind address |
| `WS_PORT` | `8765` | WebSocket port |
| `SERIAL_PORT` | `/dev/ttyACM0` | Arduino serial device |
| `SERIAL_BAUD` | `115200` | Serial baud (must match the sketch) |
| `WATCHDOG_TIMEOUT_S` | `0.3` | Failsafe stop timeout |
| `STEER_GAIN` | `1.0` | Steering sensitivity multiplier |
| `MAX_SPEED` | `255` | Upper PWM clamp |

## Run

```bash
cd ~/rover/control
source <your-venv>/bin/activate
pip install -r requirements.txt
python main.py
```

## Test

Pure logic (parsing + mixer) has no hardware dependency:

```bash
pip install pytest
pytest
```
