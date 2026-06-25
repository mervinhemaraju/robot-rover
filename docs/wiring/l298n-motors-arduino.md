# Wiring: L298N + 4 Motors + Arduino Uno R4 Minima

## Overview

The Arduino controls motor direction and speed via the L298N H-bridge. The 7.4V battery pack powers the motors. The Arduino is powered separately via USB from the laptop (or later via the buck converter from the same battery pack).

---

## Power lesson learned

Connecting Arduino 5V to the L298N 12V terminal does NOT work. The L298N has an internal 7805 voltage regulator that needs at least 7V input to produce the 5V logic supply the chip requires. With 5V in, the regulator outputs ~2.7V and the chip does not switch the motors.

**Always use the 7.4V battery pack for L298N motor power.**

---

## Jumper caps: remove before wiring

The L298N ships with jumper caps on ENA and ENB. These hold both enable pins permanently HIGH (full speed, no PWM control). Remove both jumper caps before connecting any Arduino wires.

Each ENA/ENB header has two pins:
- **Signal pin**: aligned with the IN1–IN4 row. This is where the Arduino PWM wire goes.
- **5V pin**: the pin behind it (slightly offset). Leave this unconnected.

---

## Motor connections (OUT terminals)

Motor wires have 2-pin female Dupont connectors. Use M-M jumper wires: male end into the motor connector, other male end into the L298N screw terminal.

Two motors share each channel — insert both wires into the same screw terminal and tighten together.

| L298N terminal | Motors connected |
|---|---|
| OUT1 | Left front motor wire 1 + Left rear motor wire 1 |
| OUT2 | Left front motor wire 2 + Left rear motor wire 2 |
| OUT3 | Right front motor wire 1 + Right rear motor wire 1 |
| OUT4 | Right front motor wire 2 + Right rear motor wire 2 |

If a motor spins the wrong direction, swap its two wires on the OUT terminal.

---

## Arduino to L298N logic wiring

Use M-F jumper wires (male into Arduino pin header, female onto L298N pin).

| Arduino pin | L298N pin | Purpose |
|---|---|---|
| Pin 5 | ENA (signal pin) | Left motors speed (PWM) |
| Pin 4 | IN1 | Left motors direction |
| Pin 7 | IN2 | Left motors direction |
| Pin 6 | ENB (signal pin) | Right motors speed (PWM) |
| Pin 8 | IN3 | Right motors direction |
| Pin 9 | IN4 | Right motors direction |
| GND (any) | GND | Common ground (critical) |

All three GND pins on the Arduino are electrically identical. Use whichever is most convenient.

---

## Battery to L298N power wiring

| Battery wire | L298N terminal |
|---|---|
| Red (positive) | 12V |
| Black (negative) | GND (same terminal as Arduino GND wire) |

Turn the battery holder switch OFF before making any changes. Turn it ON only when ready to test.

---

## Test sequence

1. Arduino connected to laptop via USB-C, sketch uploaded
2. Battery switch OFF
3. All wiring complete
4. Open Serial Monitor at 115200 baud
5. Flip battery switch ON
6. Confirm ready message appears
7. Send `F` — all four wheels spin forward
8. Send `S` — stop
9. Send `B` — all four wheels spin backward

---

## Arduino sketch pin constants (motor_first_test.ino)

```cpp
const int LEFT_EN  = 5;   // ENA
const int LEFT_IN1 = 4;   // IN1
const int LEFT_IN2 = 7;   // IN2
const int RIGHT_EN = 6;   // ENB
const int RIGHT_IN3 = 8;  // IN3
const int RIGHT_IN4 = 9;  // IN4
```
