# WebSocket control server (Phase 3 step 2)

The Python service on the Pi that receives JSON drive commands (from the Flutter
app) over WebSocket and forwards them to the Arduino over serial. Lives in
`pi/control/`, runs as a systemd service so it starts on boot.

## What was done

- Built `pi/control/` as a clean, self-contained service with one concern per
  module: `config` (env settings), `protocol` (parse/validate JSON), `mixer`
  (steering math), `serial_link` (pyserial wrapper), `controller` (async serial
  owner), `watchdog` (failsafe), `server` (WebSocket handler), `main` (wiring).
- Message contract: `{"cmd":"F|R|B|S","spd":0-255,"steer":-1.0..1.0}` in,
  `{"ok":true}` / `{"ok":false,"error":...}` out. The mixer turns cmd/spd/steer
  into the Arduino's `D <left> <right>` / `S` / `B`. The canonical protocol
  spec (including the client streaming contract) lives in `pi/control/README.md`.
- Safety: a watchdog stops the rover if the command stream goes quiet
  (accelerate is hold-to-drive, so the app must stream); motors also stop on
  client disconnect and on SIGTERM/SIGINT.
- Updated the interactive Pi REPL (`pi/serial-repl/`) to the new protocol with a
  `MotorSerial` service wrapper and custom exceptions.
- Set up auto-start on boot via `pi/control/rover-control.service`.

## How to reproduce (on the Pi)

1. Sparse-checkout only the Pi code (dev branch):
   ```bash
   cd ~
   git clone --filter=blob:none --sparse -b dev https://github.com/mervinhemaraju/robot-rover.git rover
   cd rover
   git sparse-checkout set pi/control pi/serial-repl
   ```
2. Install dependencies directly (no venv). Bookworm marks system Python as
   externally managed, so use the override:
   ```bash
   cd ~/rover/pi/control
   pip install --user --break-system-packages -r requirements.txt
   ```
3. One-time: serial access for the service user:
   ```bash
   sudo usermod -aG dialout th3pl4gu3   # then reboot
   ```
4. Install and enable the service:
   ```bash
   sudo cp ~/rover/pi/control/rover-control.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now rover-control.service
   journalctl -u rover-control.service -f
   ```
   Look for `listening host=0.0.0.0 port=8765`.
5. Smoke-test from another machine on the Wi-Fi (rover off the ground), streaming
   because of the watchdog:
   ```python
   import asyncio, json, websockets
   async def go():
       async with websockets.connect("ws://192.168.0.4:8765") as ws:
           for _ in range(10):
               await ws.send(json.dumps({"cmd":"F","spd":150,"steer":0.0}))
               print(await ws.recv()); await asyncio.sleep(0.1)
           await ws.send(json.dumps({"cmd":"S"}))
   asyncio.run(go())
   ```

## Blockers

| Issue | Status | Notes |
|---|---|---|
| Service failed with `200/CHDIR` | Resolved | `WorkingDirectory` pointed at the wrong path. Set it to `/home/th3pl4gu3/rover/pi/control` and ran `systemctl daemon-reload` (edits need a reload). |
| `pip install` blocked: externally-managed-environment | Resolved | Used `pip install --user --break-system-packages`. |
| `could not open /dev/ttyACM0: No such file or directory` | Resolved | Arduino was not on the Pi (still on the Mac after re-upload). Re-plugged into the Pi with the data cable; service self-healed via `Restart=always`. |
| Idle server logged a spurious `watchdog_timeout` at startup | Resolved | Watchdog now only trips after it has seen at least one command. |
