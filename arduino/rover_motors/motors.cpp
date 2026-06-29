#include <Arduino.h>
#include <stdlib.h>
#include "motors.h"
#include "config.h"

static int clampPwm(int v) {
  if (v > PWM_MAX) return PWM_MAX;
  if (v < -PWM_MAX) return -PWM_MAX;
  return v;
}

// Drive one motor pair: direction from the sign, speed from the magnitude.
static void driveSide(int enPin, int inA, int inB, int pwm) {
  if (pwm > 0) {
    digitalWrite(inA, HIGH);
    digitalWrite(inB, LOW);
  } else if (pwm < 0) {
    digitalWrite(inA, LOW);
    digitalWrite(inB, HIGH);
  } else {
    digitalWrite(inA, LOW);
    digitalWrite(inB, LOW);
  }
  analogWrite(enPin, abs(pwm));
}

void motorsBegin() {
  pinMode(LEFT_EN, OUTPUT);
  pinMode(LEFT_IN1, OUTPUT);
  pinMode(LEFT_IN2, OUTPUT);
  pinMode(RIGHT_EN, OUTPUT);
  pinMode(RIGHT_IN3, OUTPUT);
  pinMode(RIGHT_IN4, OUTPUT);
  motorsCoast();
}

void motorsDrive(int leftPwm, int rightPwm) {
  driveSide(LEFT_EN, LEFT_IN1, LEFT_IN2, clampPwm(leftPwm));
  driveSide(RIGHT_EN, RIGHT_IN3, RIGHT_IN4, clampPwm(rightPwm));
}

void motorsCoast() {
  driveSide(LEFT_EN, LEFT_IN1, LEFT_IN2, 0);
  driveSide(RIGHT_EN, RIGHT_IN3, RIGHT_IN4, 0);
}

void motorsBrakeEngage() {
  // Both direction pins HIGH shorts the motor windings, braking actively.
  // The caller releases this to a coast after BRAKE_MS (non-blocking).
  digitalWrite(LEFT_IN1, HIGH);
  digitalWrite(LEFT_IN2, HIGH);
  digitalWrite(RIGHT_IN3, HIGH);
  digitalWrite(RIGHT_IN4, HIGH);
  analogWrite(LEFT_EN, PWM_MAX);
  analogWrite(RIGHT_EN, PWM_MAX);
}
