#ifndef MOTORS_H
#define MOTORS_H

// Low-level motor primitives. Each call drives both motor PAIRS via the L298N
// (left pair on one channel, right pair on the other). Signed PWM: positive =
// forward, negative = reverse, 0 = coast. Values are clamped to +/- PWM_MAX.

void motorsBegin();
void motorsDrive(int leftPwm, int rightPwm);
void motorsCoast();        // soft stop: enables to 0, motors coast to a halt
void motorsBrakeEngage();  // active brake: short both windings (caller times release)

#endif
