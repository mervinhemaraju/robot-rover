# Robot Rover

A DIY 4-wheeled rover controllable over WiFi and Bluetooth, with a live camera feed and a Flutter mobile app as the remote controller.

## What it does

- Drive the rover from a phone via WiFi (WebSocket) or Bluetooth fallback
- Watch a live camera feed while driving
- Steering joystick + separate Accelerate, Brake, and Reverse buttons
- Live telemetry: speed (km/h), battery voltage and percentage

## Hardware

| Component | Role |
|---|---|
| Raspberry Pi 3 Model B | Main brain — Linux, Python, WiFi, Bluetooth, camera |
| Arduino Uno R4 Minima | Motor co-processor — PWM, encoder reading, serial link to Pi |
| Waveshare Robot Chassis NS | Double-deck frame, 4× TT motors |
| L298N dual H-bridge (×2) | Motor driver — left and right motor pairs |
| Pi Camera Module v2 | Live video stream |
| 2× 18650 Li-ion cells (7.4V) | Power supply |
| 20W DC-DC buck converter | Steps 7.4V down to 5V for the Pi |

## Repository layout

| Path | What it is |
|---|---|
| `remote-controller/` | Flutter mobile app — control interface and live feed |
| `docs/` | Step-by-step setup guides, one per phase/topic |

## Build phases

| Phase | Goal | Status |
|---|---|---|
| 1 | Pi setup — OS, WiFi, SSH, Python | In progress |
| 2 | Wheels moving — Arduino + L298N + serial commands from Pi | Not started |
| 3 | Remote control + camera — Flutter app, WebSocket, MJPEG stream, telemetry | Not started |
| 4 | Speed and precision — encoders, PID loop, closed-loop speed control | Not started |
| 5 | Arms and extras — servos, pan-tilt camera, obstacle sensing | Not started |

## Docs

Setup guides live in `docs/`, organised by component:

- `docs/raspberry-pi/` — Pi OS setup, networking, Bluetooth
- `docs/arduino/` — motor sketches, serial protocol
- `docs/flutter-app/` — remote controller app
- `docs/hardware/` — wiring, power, physical assembly

## Networking (Phase 3+)

- WebSocket control on port `8765`
- MJPEG camera stream on port `8080`
- Bluetooth serial as a fallback (commands only, no video)
