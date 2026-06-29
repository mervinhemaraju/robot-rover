// Rover motor control sketch (Phase 3).
//
// Param-based serial protocol over USB at 115200 baud. Replaces the single-char
// motor_first_test sketch. Test by hand in the Arduino Serial Monitor first,
// then drive from the Pi WebSocket server using the exact same protocol.
//
// Protocol (newline-terminated lines):
//   D <left> <right>   drive each motor pair, signed PWM -255..255 (sign =
//   direction) S                  soft stop (coast) B                  active
//   brake pulse, then stop ?                  print status
//
// Safety: forward<->reverse is interlocked. Send S (or a zero/spin command)
// before flipping translational direction, or the drive command is rejected.
//
// Wiring lives once in config.h. If left/right are swapped or a side spins the
// wrong way, fix config.h (or rewire) - never patch it on the Pi side.

#include "commands.h"
#include "config.h"
#include "motors.h"

void setup() {
  Serial.begin(SERIAL_BAUD);
  motorsBegin();
  commandsBegin();
  Serial.println("Ready. Protocol: D <left> <right> | S | B | ?");
}

void loop() { commandsUpdate(); }
