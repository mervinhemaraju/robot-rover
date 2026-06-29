# Rover motors sketch (Phase 3 control sketch)

The real motor-control sketch that replaces the single-char `motor_first_test`.
It speaks a parameter-based serial protocol, enforces a forward/reverse safety
interlock, and has its own failsafe stop. Lives in `arduino/rover_motors/`.

## What was done

- Split the sketch into clean modules: `rover_motors.ino` (setup/loop only),
  `config.h` (all pins and tuning constants), `motors.{h,cpp}` (motor
  primitives), `commands.{h,cpp}` (serial parser + safety logic).
- New serial protocol (newline-terminated, 115200 baud):
  - `D <left> <right>` drive each motor pair, signed PWM `-255..255` (sign = direction)
  - `S` soft stop (coast)
  - `B` active brake pulse, then stop
  - `?` print status
- Forward/reverse interlock: you cannot flip directly between forward and
  reverse. Send `S` first, or the drive command is rejected with `ERR interlock`.
- Fixed two wiring mistakes found on the bench (see Blockers).
- Added a serial-timeout failsafe: if the rover is driving and no command
  arrives for `COMMAND_TIMEOUT_MS` (500 ms), it stops itself and prints
  `FAILSAFE stop: no command`. This protects against the Pi server dying
  mid-drive (the Arduino is the last line of defence, independent of the Pi).

## How to reproduce

1. Open `arduino/rover_motors/rover_motors.ino` in the Arduino IDE (board:
   Arduino UNO R4 Minima). The IDE compiles all files in the folder together.
2. Power the L298N from the 7.4V battery pack (not USB) with charged cells.
3. Upload. Open Serial Monitor at 115200 baud, line ending set to **New Line**.
   You should see `Ready. Protocol: D <left> <right> | S | B | ?`.
4. With the rover off the ground, verify directions:

   | Send | Expected |
   |---|---|
   | `D 150 0` | both left wheels forward |
   | `D 0 150` | both right wheels forward |
   | `D 150 150` | all four forward |
   | `S` then `D -150 -150` | all four backward |
   | `D -150 150` | spin left in place |
   | `D 150 -150` | spin right in place |
   | `B` | brief active brake, then stop |

5. Verify the interlock: `D 150 150` then `D -150 -150` directly returns
   `ERR interlock: send S (stop) before reversing direction`. Send `S`, then
   `D -150 -150` works.
6. Verify the failsafe: send `D 150 150` and do nothing. After ~500 ms the wheels
   stop on their own and it prints `FAILSAFE stop: no command`. Resend to keep
   driving (this also means single manual commands are now ~500 ms pulses).

## Blockers

| Issue | Status | Notes |
|---|---|---|
| Both left wheels spun backward on a forward command | Resolved | Whole left channel was reversed. Swapped `LEFT_IN1`/`LEFT_IN2` (pins 4<->7) in `config.h`. |
| Back-right wheel spun opposite to front-right | Resolved | One motor of the right pair was wired the opposite way. Cannot be fixed in software (shared L298N channel); swapped that motor's two leads at the OUT3/OUT4 screw terminals. |
| Rover could keep driving if the Pi server crashed mid-drive | Resolved | Added the Arduino serial-timeout failsafe in `commands.cpp` (500 ms). |
