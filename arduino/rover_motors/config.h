#ifndef CONFIG_H
#define CONFIG_H

// Single source of truth for wiring and tuning constants.
// If left/right are swapped on the hardware, or a side drives the wrong way,
// fix it HERE (or rewire), never in the Pi or WebSocket layer.

// Serial link to the Pi (must match pyserial baud on the Pi side).
const unsigned long SERIAL_BAUD = 115200;

// L298N pin mapping (Arduino pin -> L298N pin). Same wiring as motor_first_test,
// so the existing docs/wiring/l298n-motors-arduino.md stays valid.
const int LEFT_EN   = 5;  // ENA  - PWM speed, left motor pair
// IN1/IN2 swapped (4<->7) to correct a reversed left channel: bench test showed
// both left wheels spinning backward on a forward command.
const int LEFT_IN1  = 7;  // IN1  - direction, left motor pair
const int LEFT_IN2  = 4;  // IN2  - direction, left motor pair
const int RIGHT_EN  = 6;  // ENB  - PWM speed, right motor pair
const int RIGHT_IN3 = 8;  // IN3  - direction, right motor pair
const int RIGHT_IN4 = 9;  // IN4  - direction, right motor pair

// Onboard LED used as a "motors active" indicator (no external wiring needed).
const int LED_PIN = LED_BUILTIN;

// PWM duty range for analogWrite on the enable pins.
const int PWM_MAX = 255;
const int PWM_MIN = 0;

// Active brake pulse duration before releasing to a coast. Non-blocking;
// timed with millis() in commands.cpp.
const unsigned long BRAKE_MS = 200;

// Failsafe: if the rover is driving and no command arrives for this long, stop.
// This is independent of the Pi, so a dead Pi server cannot leave the rover
// running. Keep it longer than the app's command stream (~100 ms) and the Pi
// watchdog (~300 ms); the Arduino is the last-resort backstop.
// NOTE: a single manual command (Serial Monitor / Pi REPL) now auto-stops after
// this interval. Resend to keep driving.
const unsigned long COMMAND_TIMEOUT_MS = 500;

#endif
