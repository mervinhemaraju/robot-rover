# Component Mounting and Ground Deck Wiring

Mounting all the electronics onto the two chassis decks and finalizing the ground
deck power wiring, ending with a full drive test on the assembled rover.

---

## What was done

- Mounted the Pi and Arduino on standoffs (small pillars) so the boards sit lifted
  off the metal decks. This is required: the sharp points under each board are the
  solder tails of through-hole parts (GPIO header, USB ports, etc.) and some are
  electrically live. Resting a board flat on the metal deck could short them.
- Settled the final layout (changed from the original plan in `assembly.md`):
  - **Ground deck:** buck converter, L298N, Raspberry Pi
  - **Top deck:** Arduino, breadboard
  - **Below the ground deck:** 18650 battery holder (heaviest part, kept low and
    centered for stability; switch left accessible for charging)
- Finalized the ground deck power wiring (battery split in parallel to the buck
  converter and the L298N, buck output to the Pi, L298N out to the four motors,
  logic leads up to the Arduino).
- Verified the buck converter output before trusting the Pi.
- Re-ran the full drive test (F / B / L / R) on the fully mounted rover - all four
  wheels behaved correctly, no issues.

---

## How to reproduce

### 1. Mount the boards on standoffs

1. Use the board's corner mounting holes (the plain holes, not the pin headers).
2. Put a standoff between each board corner and the deck so the board floats above
   the surface with an air gap underneath.
3. Screw down through the corner holes into the standoffs. Never let a metal screw
   head or standoff touch the underside pins.
4. If the chassis holes do not line up, use nylon standoffs or thick Velcro pads
   under the corners (away from the pins) to lift the board instead.

Layout: buck converter + L298N + Pi on the ground deck; Arduino + breadboard on the
top deck; battery holder fixed below the ground deck.

### 2. Wire the ground deck (battery switch OFF the whole time)

The battery feeds two things in parallel. Use the L298N screw terminals as the
junction (they grip two wires each):

| From | To |
|---|---|
| Battery **red (+)** | L298N **12V** terminal |
| Jumper from L298N **12V** | Buck **IN+** |
| Battery **black (-)** | L298N **GND** terminal |
| Jumper from L298N **GND** | Buck **IN-** |

Buck converter to Pi:

| From | To |
|---|---|
| Buck **OUT+** | Pi micro USB **+** |
| Buck **OUT-** | Pi micro USB **-** |

Motors (two per channel):

| L298N terminal | Motors |
|---|---|
| OUT1 / OUT2 | Left front + left rear |
| OUT3 / OUT4 | Right front + right rear |

Common ground and logic leads up to the Arduino (top deck):

| Arduino pin | L298N pin |
|---|---|
| GND | GND |
| Pin 5 | ENA |
| Pin 4 | IN1 |
| Pin 7 | IN2 |
| Pin 6 | ENB |
| Pin 8 | IN3 |
| Pin 9 | IN4 |

### 3. Power up safely and test

1. Battery switch ON.
2. Immediately measure buck **OUT+** to **OUT-** with the multimeter. It must read
   **4.95-5.15V** before the Pi is trusted. If not, switch off and adjust.
3. SSH into the Pi and run the serial test: `cd ~/rover && source venv/bin/activate && python main.py`
4. Confirm all four wheels run F / B / L / R correctly. If a side drives backward on
   F, swap that side's two OUT wires.

---

## Notes

- Polarity: red is positive, black is negative. Reversing into the buck converter
  can destroy it; reversing into the L298N 12V/GND can damage the L298N. There is no
  fuse. Double-check before the switch goes on.
- The only step that can silently kill hardware is the buck output to the Pi. Always
  meter it before trusting it. Everything else (reversed motor wires, swapped logic
  pins) is recoverable by re-swapping.
