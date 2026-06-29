# Wiring the Flutter app to the rover (WebSocket control)

The point where the Flutter remote becomes a real remote: the app now sends live
drive commands to the Pi over WiFi, and the rover responds. Confirmed driving
forward, reverse, brake and steering from the phone.

## What was done

- Added two packages to the app: `web_socket_channel` (the network link) and
  `flutter_riverpod` (to hold the connection and command state).
- Built a small control stack in `remote-controller/lib/`:
  - `core/rover_config.dart` - the Pi's address and ports (`ws://192.168.0.4:8765`).
  - `core/drive_command.dart` - one drive command in the exact format the Pi
    expects: `{"cmd":"F|R|B|S","spd":0-255,"steer":-1.0..1.0}`.
  - `core/drive_sequencer.dart` - the "brain": turns held buttons + the steering
    stick into the next command to send. Handles the speed ramp-up, the
    soft-stop on release, hold-to-reverse, and the rule that you must stop before
    switching between forward and reverse.
  - `data/rover_connection.dart` - opens the WebSocket, reconnects on its own if
    the link drops.
  - `providers/rover_controller.dart` - the heartbeat: every 100 ms it re-sends
    the currently-held command. This is required: the Pi stops the rover if
    commands stop arriving, so the app must keep sending while a button is held.
- Wired the existing UI to this stack:
  - Accelerate (hold to ramp up, release to soft-stop), Brake (hold = brake),
    Reverse (changed from a tap-toggle to hold-to-reverse, matching the firmware).
  - The steering stick now feeds the steering value and is locked to left/right.
  - The "ROVER" status dot shows the live connection state (green = connected,
    amber = connecting, red = disconnected).
- Android: allowed the app to reach the Pi over the local network
  (`INTERNET` permission + cleartext traffic, needed because the link is plain
  `ws://`, not encrypted).
- Fixed a steering bug found during the first live drive: while reversing,
  left/right were swapped. Corrected in the Pi's mixer (`pi/control/mixer.py`)
  so reverse steering mirrors forward, like a car backing up. The app needed no
  change for this.
- Documented the protocol properly: `pi/control/README.md` now spells out the
  client streaming contract (the 100 ms heartbeat, what the `{"ok":true}` reply
  does and does not guarantee).
- Added tests: pure command-logic tests for the app's sequencer
  (`remote-controller/test/core/drive_sequencer_test.dart`) and updated the Pi
  mixer tests for the reverse fix.

## How to reproduce

1. Make sure the Pi control service is running and the rover is **off the ground**
   (wheels free to spin) for the first test:
   ```bash
   # on the Pi
   sudo systemctl status rover-control.service   # should be active
   ```
2. If you changed the Pi code (e.g. the reverse-steering fix), update and restart
   the service:
   ```bash
   # on the Pi
   cd ~/rover && git pull origin dev
   sudo systemctl restart rover-control.service
   ```
3. Put the phone on the **same WiFi** as the Pi (the Pi is at `192.168.0.4`).
4. Build and run the app on the Android phone:
   ```bash
   cd remote-controller
   flutter pub get
   flutter run        # with the phone plugged in and USB debugging on
   ```
5. Watch the "ROVER" dot: it goes amber (connecting) then green (connected).
6. Drive:
   - Hold **Accelerate**: speed ramps up; release to coast to a stop.
   - Move the **steering stick** left/right while accelerating to curve.
   - Hold **Reverse**: backs up with steering; release to stop.
   - Tap/hold **Brake**: instant stop.
   - You cannot go straight from forward to reverse: release and let it stop first.
7. Run the app tests any time:
   ```bash
   cd remote-controller && flutter test
   ```

## Blockers

| Issue | Status | Notes |
|---|---|---|
| App crashed on launch: "Tried to read the state of an uninitialized provider" | Resolved | The connection was started inside the controller's setup before its state existed. Deferred the connect to a microtask so the state is ready first. |
| Reverse steering turned the wrong way | Resolved | Differential-drive quirk (same wheel input yaws the opposite way when moving backward). Mirrored the turn in reverse in `pi/control/mixer.py`. |
| App could not reach the Pi | Resolved | Android blocks plain `ws://` by default. Added `INTERNET` permission and `usesCleartextTraffic="true"` to the Android manifest. |
| The stale default counter widget test failed | Resolved | Replaced it with a real smoke test that boots the app inside a `ProviderScope`. |
