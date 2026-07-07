# Camera Module v2 Connection + MJPEG Stream Server

Phase 3: the rover's live video feed. The Pi Camera Module v2 was physically
connected to the Pi 3B, and a new Python service (`pi/camera/`) now streams
MJPEG video over HTTP on port 8080, viewable in any browser and (next step)
in the Flutter app.

## What was done

- Identified the camera box contents: the long white ribbon (the one to use),
  a maroon/amber Pi Zero adapter ribbon (not needed for the Pi 3B, kept in the
  box), and a white circular lens focus ring tool (kept; factory focus is fine).
- Connected the white ribbon to the Pi's CSI port (labelled CAMERA, between
  HDMI and the audio jack): silver contacts facing the HDMI port, blue tab
  facing the Ethernet/USB ports. Pi was shut down cleanly first; the CSI port
  must never be plugged or unplugged while powered.
- Verified detection with `rpicam-hello --list-cameras` (shows `imx219`) and a
  test photo with `rpicam-still -n -o test.jpg`, pulled to the Mac with `scp`.
  Photo quality confirmed good; no focus adjustment needed.
- Built the `pi/camera/` service: Picamera2 capturing at 640x480/30fps scaled
  from the full-field-of-view sensor mode, encoded by the Pi 3B's hardware
  MJPEG encoder (near-zero CPU), served by aiohttp as
  `multipart/x-mixed-replace` on `GET /stream`, plus `GET /healthz`.
  Latest-frame fan-out: slow viewers skip frames instead of building up lag.
- 5 unit tests for the frame fan-out logic; all passing.
- Deployed to the Pi and confirmed live video in the Mac browser at
  `http://192.168.0.4:8080/stream`.
- Camera is mounted upside down on the rover: fixed with `CAM_HFLIP=1` and
  `CAM_VFLIP=1` (both together = true 180-degree rotation; one alone would
  mirror the image). Now baked into `rover-camera.service`.

## How to reproduce

1. Shut down the Pi cleanly (`sudo shutdown -h now`, wait for the green LED to
   go dark), disconnect power.
2. Connect the camera ribbon to the CSI port as described above, power up.
3. Verify detection:

   ```bash
   rpicam-hello --list-cameras   # expect an imx219 entry
   ```

4. Pull the service code (the Pi uses a sparse checkout, see Blockers):

   ```bash
   cd ~/rover
   git pull
   git sparse-checkout add pi/camera
   ```

5. Install dependencies (picamera2 must come from apt, not pip):

   ```bash
   sudo apt install -y python3-picamera2 --no-install-recommends
   pip install --user --break-system-packages -r ~/rover/pi/camera/requirements.txt
   ```

6. First run in the foreground to verify:

   ```bash
   cd ~/rover/pi/camera && python3 main.py
   # expect: camera_started ... then listening host=0.0.0.0 port=8080
   ```

   Open `http://192.168.0.4:8080/stream` in a browser on the same WiFi.

7. Install as a systemd service (auto-start on boot, restart on failure):

   ```bash
   sudo cp ~/rover/pi/camera/rover-camera.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now rover-camera.service
   ```

8. Orientation or other tuning is environment variables only (no code
   changes): `CAM_WIDTH`, `CAM_HEIGHT`, `CAM_FPS`, `CAM_HFLIP`, `CAM_VFLIP`,
   `HTTP_PORT`. Set them in the unit file and
   `sudo systemctl daemon-reload && sudo systemctl restart rover-camera`.

## Blockers

| Issue | Status | Notes |
|---|---|---|
| `rpicam-still` appeared stuck, printing frame stats forever | Resolved | It was preview mode; `rpicam-hello` never saves a photo. Use `rpicam-still -n -o file.jpg` (5s auto-exposure settle, then captures and exits) |
| `git pull` on the Pi did not materialize `pi/camera/` | Resolved | The Pi's sparse checkout lists specific folders, not all of `pi/`. Fixed with `git sparse-checkout add pi/camera`. Remember this for every new `pi/` service |
| Stream upside down | Resolved | Camera is mounted inverted; `CAM_HFLIP=1 CAM_VFLIP=1` in the systemd unit |

## Still open in Phase 3

- Point the Flutter app's `placeholder_livefeed.dart` at
  `http://192.168.0.4:8080/stream`.
- Battery voltage/percentage telemetry (voltage divider into an Arduino
  analog pin).
- Bluetooth serial fallback control channel.
