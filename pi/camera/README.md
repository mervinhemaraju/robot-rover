# Camera stream server (Phase 3)

MJPEG live-video server for the rover. Captures from the Pi Camera v2 with
Picamera2, encodes MJPEG in the Pi 3B's hardware video encoder (near-zero CPU),
and serves it over HTTP to the Flutter app or any browser. Deploys to
`~/rover/pi/camera/` on the Pi.

## Endpoints

| Endpoint | What it returns |
| --- | --- |
| `GET /stream` | `multipart/x-mixed-replace` MJPEG stream (open in a browser to test) |
| `GET /healthz` | `ok` once the service is up |

Any number of clients can watch simultaneously; each always receives the
newest frame. Slow clients skip frames instead of accumulating lag, so the
driver's view stays live.

## Design notes

- Frames are captured at the requested output size but scaled by the ISP from
  the full-field-of-view binned sensor mode; the imx219's native VGA mode is
  heavily cropped and unusable for driving.
- The encoder runs on its own thread inside Picamera2; `FrameBuffer` does the
  thread-to-asyncio handoff and holds only the latest frame.
- If the camera fails to start, the service exits and systemd restarts it
  (same self-heal pattern as the control server).

## Configuration (environment variables)

| Variable | Default | Meaning |
| --- | --- | --- |
| `HTTP_HOST` | `0.0.0.0` | HTTP bind address |
| `HTTP_PORT` | `8080` | HTTP port |
| `CAM_WIDTH` | `640` | Frame width (px) |
| `CAM_HEIGHT` | `480` | Frame height (px) |
| `CAM_FPS` | `30` | Target frame rate |
| `CAM_HFLIP` | `0` | Set `1` to mirror horizontally (mount orientation) |
| `CAM_VFLIP` | `0` | Set `1` to flip vertically (mount orientation) |

## Install and run

```bash
sudo apt install -y python3-picamera2 --no-install-recommends
pip install --user --break-system-packages -r requirements.txt
python3 main.py
```

As a service:

```bash
sudo cp rover-camera.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now rover-camera.service
```

Verify from another machine on the same Wi-Fi:

```
http://192.168.0.4:8080/stream
```

## Test

Pure logic (the frame fan-out) has no hardware dependency:

```bash
pip install pytest
pytest
```
