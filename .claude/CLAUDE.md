# DIY Remote-Controlled Rover Robot — Project Context

@.claude/rules/repo-layout.md
@.claude/rules/inventory-sync.md
@.claude/rules/hardware-safety.md
@.claude/rules/pi-shutdown-reminder.md
@.claude/rules/phase-gate.md
@.claude/rules/arduino-sketch-style.md
@.claude/rules/python-pi-style.md
@.claude/skills/log-progress/SKILL.md
@.claude/skills/wiring-check/SKILL.md
@.claude/skills/phase-review/SKILL.md
@.claude/skills/serial-debug/SKILL.md
@.claude/skills/new-arduino-sketch/SKILL.md
@.claude/skills/new-pi-service/SKILL.md

## Who is building this

Mervin — IT professional (Python, Flutter, Dart, Kotlin, Docker, Kubernetes, Terraform, Ansible, Java). No prior electronics/hardware background. Based in Beau Bassin-Rose Hill, Mauritius.

**Working agreement:** Claude assists with the code (Python on the Pi, Arduino sketches, Flutter app) but author owns and writes it. Claude explains every hardware/electronics concept in plain language before any physical step, provides exact wiring diagrams before connections are made, and proactively flags risks (wrong voltage, polarity, current limits) before they happen — not after. No assumed electronics knowledge.

---

## Project goal

A 4-wheeled rover, controllable via WiFi and Bluetooth simultaneously, with:

* Live camera feed while driving
* Flutter mobile app as the remote controller
* Python backend on the Pi
* Steering-only joystick + separate Accelerate/Brake/Reverse buttons (not a traditional dual-axis joystick)
* Live telemetry: speed (km/h), battery % and voltage
* Expandable later: servo arms/hands, pan-tilt camera mount, faster motors, obstacle sensing, computer vision

Optional future: remote access over the internet (not just local WiFi) via Tailscale and/or Cloudflare Tunnel.

---

## Finalised hardware stack

### Brain

* **Raspberry Pi 3 Model B** (already owned) — main controller, Linux, Python, built-in WiFi + Bluetooth 4.1, full-size CSI camera port, GPIO pre-soldered
* **Arduino Uno R4 Minima** — motor co-processor, real-time PWM + encoder reading, USB-C serial link to Pi (Renesas RA4M1, 48MHz, 32KB RAM, 6–24V input range, 3.3V logic, max 8mA per GPIO pin — never connect motors directly to pins, always via L298N)

### Motion

* **Waveshare Robot Chassis Kit NS** — double-deck mounting plates, 4× TT motors (6–9V, 190RPM@6V, 160mA), standard wheels, tools included. No encoders bundled.
* **L298N dual H-bridge motor driver** (×2 purchased, 1 spare) — 2A per channel continuous, screw terminals, no soldering. Left motors on OUT1/OUT2, right motors on OUT3/OUT4.
* **Photo Interrupter Sensor ×4** (Waveshare, includes 20-slot encoder disk) — one per motor, for Phase 4 PID speed control. 6mm sensor gap width.

### Vision

* **Raspberry Pi Camera Module v2** (8MP) — standard CSI ribbon, connects directly to Pi 3B (no adapter needed, unlike Pi Zero).
* *(Deferred to Phase 5)* SG90 servos ×2 + pan-tilt bracket for steerable camera mount.

### Power

* **2× 18650 Li-ion cells, 3.7V 3000mAh** — sourced locally in Mauritius (international shipping of lithium cells is restricted/unreliable; Pi Hut UK could not ship these to Mauritius).
* **2× 18650 battery holder** — fully enclosed, series-wired (7.4V output), built-in ON/OFF switch, bare wire + DC barrel jack leads (Temu). No separate rocker switch needed.
* **20W Adjustable DC-DC Buck Converter with digital display** — steps 7.4V down to 5V for the Pi. **Must be manually set to exactly 5V (verified with multimeter) before ever connecting to the Pi.** Pi 3B max input is 5.25V — do not use a UBEC or any converter that can drift above this.
* **VariCore VC-Q4** 4-slot intelligent 18650 charger (AliExpress) — CE/FCC/RoHS certified, USB-C input, display per slot.

### Tools and wiring

* **ANENG DM850** digital multimeter (Temu) — for verifying buck converter output, battery voltage, continuity.
* Half-size breadboard (sourced locally, Advanced M).
* Jumper wires M-M, M-F, F-F — already owned.
* USB-A to USB-C cable — already owned (Arduino Uno R4 Minima uses USB-C, not USB-B).
* Phillips screwdriver — already owned.
* MicroSD card 64GB Class 10 — in use.
* Velcro cable straps, mixed colors, 50pcs (Temu) — reusable cable management.

### Rejected alternatives (with reasoning, for context)

* **Gamma 5005 4WD kit** — rejected: Arduino-only brain, no WiFi, no camera streaming, no Python path. Its chassis/motors/sensors are reusable in principle but the bundled controller can't meet the project's core requirements.
* **Arduino Nano R4** — rejected for the primary board: too new (minimal tutorials/community), fiddly form factor for a first hardware build, no L298N wiring tutorials use this footprint. Real and legitimate board, just not the right starting point.
* **Pi Zero 2W** — rejected in favor of the already-owned Pi 3B: more RAM, GPIO pre-soldered, full-size CSI (standard ribbon works directly, no special Pi Zero ribbon needed).
* **PCA9685 PWM driver** — considered as Arduino alternative; rejected as primary co-processor because it's output-only (can't read encoders/sensors, no real-time logic). Good future add-on once servo count exceeds Arduino's pins.
* **AliExpress generic 4WD PCB chassis** — rejected: no encoders, single-deck (too cramped for Pi 3B + Arduino + L298N + battery).
* **L293D motor driver** — rejected: only 600mA/channel, insufficient for 4 TT motors under load. Must be L298N (2A/channel).
* **9V battery holder / AA holders / various Advanced M battery accessories** — wrong voltage/format for this build; confirmed not viable for 18650 cells.

---

## Build phases

**Phase 1 — Brain setup** ✅ *complete*
Flash Raspberry Pi OS (64-bit Lite), configure WiFi + Bluetooth, SSH access (ed25519 key auth), install Python dependencies.
Deliverable: Pi reachable over WiFi from laptop.

**Phase 2 — Wheels moving**
Wire Arduino Uno R4 Minima + L298N + 4 motors. Upload Arduino motor sketch. Pi sends serial commands to Arduino over USB.
Deliverable: rover drives forward/backward/turns via Python script.
Includes: Mode 1 (instant stop) as first pass.

**Phase 3 — Remote control and camera**
Pi Camera v2 live stream (MJPEG, port 8080). Flutter app over WebSocket (port 8765) for WiFi control + Bluetooth serial fallback. Both connectivity paths active simultaneously.
Control scheme: steering-only joystick (X-axis) + Accelerate button (hold = ramp up, release = soft stop) + Brake button (active braking pulse, instant stop) + Reverse button (hold = reverse, steering active). **Safety rule: cannot go directly from forward to reverse or reverse to forward — must pass through full stop first.**
Live telemetry overlays: speed (km/h, from encoder pulses), battery % and voltage (voltage divider into Arduino analog pin).
Deliverable: drive rover from phone with live video feed, working steering/accel/brake/reverse, live telemetry.

**Phase 4 — Speed and precision**
Wire 4× photo interrupter sensors to encoder disks. Arduino PID loop for closed-loop speed control. Variable speed slider in app actually governs target speed via PID, not just raw PWM. Add Mode 3 (acceleration ramp) and Mode 4 (active reverse-pulse braking).
Deliverable: smooth, reliable speed control at higher speeds; accurate speedometer.

**Phase 5 — Arms and extras**
Add SG90 servos for pan-tilt camera mount and robot arms/hands. Add PCA9685 PWM expander if servo count exceeds Arduino's available pins. Add ultrasonic obstacle sensing.
Deliverable: rover with steerable camera and moving arms.

**Possible later addition — Internet access (not phase-locked)**
Tailscale (recommended first step — zero config, permanent IP, encrypted, lowest latency of remote options) for driving the rover from anywhere. Cloudflare Tunnel as an optional secondary/public-facing layer once local Tailscale access works (Mervin already has a Cloudflare account/stack). AWS + Kubernetes explicitly evaluated and rejected as the access layer — wrong tool for a single physically-tethered device (camera/serial must run on the Pi itself, can't containerize into a cluster); revisit only if the project becomes a multi-rover fleet with a genuine telemetry/management-plane need.

---

## Repository layout

| Path | What it is |
| --- | --- |
| `arduino/` | Arduino sketches — `motor_first_test/` for Phase 2 hardware validation, real motor sketch to follow |
| `remote-controller/` | Flutter mobile app (Phase 3+) — WebSocket control, MJPEG live feed, joystick + buttons UI, telemetry overlays |
| `docs/` | Per-phase and per-topic setup guides, written after each session with `/log-progress` |
| `~/rover/control/` | Python WebSocket server on the Pi (Phase 3+) |
| `~/rover/camera/` | Python MJPEG camera stream on the Pi (Phase 3+) |
| `~/rover/logs/` | Pi-side log output |

> `~/rover/` is the on-device path on the Pi, not in this repo. The Pi-side Python code will live there.

---

## Networking design (Phase 3+)

* WebSocket server on **port 8765** for control commands (JSON, e.g. `{"cmd":"F","spd":180,"steer":0.3}`)
* MJPEG stream on **port 8080** for camera video
* Bluetooth serial as a fallback control channel (commands only, no video — BT bandwidth can't support live video)
* No internet required for local operation; Pi gets a local IP via router DHCP reservation
* Commands: `F` (forward), `R` (reverse), `B` (brake), `S` (soft stop), each with `spd` (0–255) and `steer` (-1.0 to 1.0)

---

## Key technical constraints (always apply these)

* No soldering experience — all connections via jumper wires, breadboard, and screw terminals. No soldering required in Phases 1–3.
* Buck converter output **must be verified at exactly 5V with a multimeter before ever connecting to the Pi** (Pi 3B max input 5.25V).
* L298N: 2 motors per channel — left motors together on OUT1/OUT2, right motors together on OUT3/OUT4.
* Pi 3B GPIO is 3.3V logic; Arduino Uno R4 Minima is also 3.3V logic — direct serial connection is safe.
* Arduino R4 Minima max GPIO current is 8mA — never connect motors directly to pins, always via L298N.
* NS chassis motor voltage range is 6–9V — powered directly from the 7.4V pack via L298N, no separate regulation needed for motors.
* Photo interrupter sensors need 3.3V or 5V supply plus a digital input pin on the Arduino — one per motor.
* Always shut down the Pi cleanly with `sudo shutdown -h now` and wait for the green LED to stop before disconnecting power. An abrupt power cut already caused filesystem corruption once requiring a re-flash.
* The Pi 3B's micro USB port is power-only — never assumes a USB-to-Mac connection provides networking.
* **Power supply must be a proper 5V/2.5A wall charger.** A Mac/laptop USB port (~0.5–0.9A) is insufficient and caused a boot loop (rainbow-screen undervoltage symptom) during Phase 1 setup.
* Lithium 18650 cells frequently cannot be shipped internationally to Mauritius (confirmed with Pi Hut UK) — source these locally.

---

## Current state (update this section as the project progresses)

**Phase 1 status:** ✅ Complete.

* Pi 3B flashed with Raspberry Pi OS (64-bit Lite), hostname `th3pl4gu3-rover`, user `th3pl4gu3`, SSH key auth (ed25519) configured. 64GB microSD card in use.
* Resolved: boot loop caused by underpowered USB source (Mac port) — fixed with proper wall charger.
* Resolved: WiFi/filesystem corruption after an abrupt power loss — fixed by re-flashing and always shutting down cleanly.
* Pi joins WiFi (hidden SSID), reachable via SSH. DHCP-reserved IP `192.168.0.4` confirmed active.
* System updated (`apt update && full-upgrade`), Python 3.13 confirmed present.
* `python3-pip`, `python3-venv`, `git` installed.
* `~/rover/{control,camera,logs}` directory structure created. Python venv set up.
* Bluetooth confirmed working: `hci0 UP RUNNING`, soft-block resolved via `rfkill unblock bluetooth` (state persists across reboots via systemd-rfkill).

**Phase 2 status:** In progress.

* All hardware received. No longer blocked.
* Waveshare NS chassis mechanically assembled: frame, wheels, and all 4 motors fitted. Arduino, Pi, L298N, breadboard, battery holder, and buck converter not yet mounted.
* Arduino IDE 2.x set up on macOS (Apple Silicon): Rosetta 2 installed to fix `arm-none-eabi-gcc bad CPU type` error. Board package: Arduino UNO R4 Boards v1.6.0, board: Arduino UNO R4 Minima, port: `/dev/cu.usbmodem1101`.
* `arduino/motor_first_test/motor_first_test.ino` uploaded and serial-tested: responds correctly to `F`, `B`, `S`, `L`, `X` commands via Serial Monitor at 115200 baud.
* L298N wired to all 4 motors and Arduino. Motors confirmed spinning forward and backward via Serial Monitor commands. See `docs/wiring/l298n-motors-arduino.md`.
* Lesson: 5V from Arduino USB is not enough to power L298N (internal regulator needs >7V input). Must use 7.4V battery pack for motor power.
* Buck converter setup pending: requires 9V battery for multimeter verification before Pi can be connected.
* Next steps: (1) buy 9V battery + resistor pack, (2) calibrate buck converter, (3) connect Pi, (4) write Pi serial script to replace Serial Monitor control.

**Phase 3 pre-work (Flutter app):** UI complete and ahead of schedule. `remote-controller/` Flutter app has joystick, Accelerate/Brake/Reverse buttons, and MJPEG camera feed screen built. Needs wiring to live WebSocket and camera stream once Phase 2 and 3 backend are ready.

**Parts tracking:** See `.claude/inventory.yaml` — read this before suggesting any wiring or purchasing step.
