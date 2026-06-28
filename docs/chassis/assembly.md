# Chassis Assembly: Waveshare Robot Chassis Kit NS

## Status

Mechanical assembly complete. Electronics now mounted on standoffs and wired -
see `component-mounting.md` for the final layout and ground deck wiring.

---

## What is assembled

- Double-deck mounting plates screwed together
- All 4 TT motors fitted to the motor brackets
- Wheels attached to all 4 motors
- Chassis is free-standing and ready for electronics mounting

---

## What is not yet mounted

These will be mounted during Phase 2 wiring:

| Component | Planned location |
| --- | --- |
| Raspberry Pi 3B | Upper deck |
| Arduino Uno R4 Minima | Upper deck, near Pi |
| L298N motor driver (x1 active) | Lower or upper deck, near motor wires |
| Half-size breadboard | Upper deck |
| 18650 battery holder | Lower deck (heavier, keeps center of gravity low) |
| 20W buck converter | Lower or upper deck, near battery and Pi |

Mount order: start with the L298N and motor wiring on the lower deck, then add the Arduino and Pi on the upper deck once the motor circuit is tested.

---

## Motor wiring notes

The 4 TT motors come with pre-attached wire leads. They connect to the L298N screw terminals:

- Left front + left rear motors: both to OUT1/OUT2 (in parallel)
- Right front + right rear motors: both to OUT3/OUT4 (in parallel)

Motor polarity at this stage does not need to be perfect. If a motor spins the wrong direction during testing, swap its two wires on the L298N terminal.

---

## Kit contents used

- 2x mounting plates (upper and lower deck)
- 4x TT motors with wire leads
- 4x wheels
- Motor brackets and mounting hardware
- Phillips screwdriver (included in kit, or standard Phillips)
