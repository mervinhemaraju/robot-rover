#include <Arduino.h>
#include <string.h>
#include <stdlib.h>
#include "commands.h"
#include "config.h"
#include "motors.h"

// Translational direction, derived from the sign of (left + right). A pure
// spin-in-place (sum == 0) counts as STOPPED for interlock purposes, which is
// fine for the app's command set (accel/reverse always bias the sum).
enum Direction { DIR_STOPPED, DIR_FORWARD, DIR_REVERSE };
enum MotionState { STATE_STOPPED, STATE_DRIVING, STATE_BRAKING };

static Direction currentDir = DIR_STOPPED;
static MotionState state = STATE_STOPPED;
static unsigned long brakeStart = 0;

static const int LINE_BUF = 32;
static char buf[LINE_BUF];
static int len = 0;

static Direction classify(int left, int right) {
  long sum = (long)left + (long)right;
  if (sum > 0) return DIR_FORWARD;
  if (sum < 0) return DIR_REVERSE;
  return DIR_STOPPED;
}

static void setLed(bool on) {
  digitalWrite(LED_PIN, on ? HIGH : LOW);
}

static void doStop() {
  motorsCoast();
  state = STATE_STOPPED;
  currentDir = DIR_STOPPED;
  setLed(false);
}

static void handleDrive(int l, int r) {
  Direction req = classify(l, r);
  if ((currentDir == DIR_FORWARD && req == DIR_REVERSE) ||
      (currentDir == DIR_REVERSE && req == DIR_FORWARD)) {
    Serial.println("ERR interlock: send S (stop) before reversing direction");
    return;
  }
  motorsDrive(l, r);
  state = STATE_DRIVING;
  currentDir = req;  // DIR_STOPPED for a pure spin (sum == 0)
  setLed(req != DIR_STOPPED);
  Serial.print("OK D ");
  Serial.print(l);
  Serial.print(' ');
  Serial.println(r);
}

static void handleBrake() {
  motorsBrakeEngage();
  state = STATE_BRAKING;
  brakeStart = millis();
  setLed(true);
  Serial.println("OK B");
}

static void printStatus() {
  Serial.print("STATUS dir=");
  Serial.print(currentDir == DIR_FORWARD ? "FWD"
               : currentDir == DIR_REVERSE ? "REV"
               : "STOP");
  Serial.print(" state=");
  Serial.println(state == STATE_DRIVING ? "DRIVING"
                 : state == STATE_BRAKING ? "BRAKING"
                 : "STOPPED");
}

static void parseLine(char* line) {
  char* tok = strtok(line, " ");
  if (tok == NULL) return;

  if (strcmp(tok, "D") == 0) {
    char* lt = strtok(NULL, " ");
    char* rt = strtok(NULL, " ");
    if (lt == NULL || rt == NULL) {
      Serial.println("ERR D needs <left> <right>");
      return;
    }
    handleDrive(atoi(lt), atoi(rt));
  } else if (strcmp(tok, "S") == 0) {
    doStop();
    Serial.println("OK S");
  } else if (strcmp(tok, "B") == 0) {
    handleBrake();
  } else if (strcmp(tok, "?") == 0) {
    printStatus();
  } else {
    Serial.print("ERR unknown command: ");
    Serial.println(tok);
  }
}

void commandsBegin() {
  pinMode(LED_PIN, OUTPUT);
  setLed(false);
}

void commandsUpdate() {
  // Non-blocking brake pulse: release to a coast after BRAKE_MS.
  if (state == STATE_BRAKING && millis() - brakeStart >= BRAKE_MS) {
    doStop();
  }

  // Accumulate serial bytes into a line buffer; parse on newline.
  while (Serial.available() > 0) {
    char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      if (len > 0) {
        buf[len] = '\0';
        parseLine(buf);
        len = 0;
      }
    } else if (len < LINE_BUF - 1) {
      buf[len++] = c;
    }
    // Overflow chars are dropped; the line parses (truncated) at the newline.
  }
}
