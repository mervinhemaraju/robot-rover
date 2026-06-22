# New Arduino Sketch: $ARGUMENTS

Scaffold a new Arduino sketch following project conventions.

## 1. Clarify intent

If $ARGUMENTS does not make the sketch purpose clear, ask:
- What does this sketch control or read? (motors, encoders, sensors)
- What commands should it accept over serial?
- What should it send back to the Pi?

## 2. Determine location

Arduino sketches live in `arduino/<sketch-name>/<sketch-name>.ino`.
If the `arduino/` root folder does not exist yet, note it must be created
and add it to the Repository layout table in `.claude/CLAUDE.md`.

## 3. Scaffold the sketch

Use this structure — fill in the purpose-specific logic:

```cpp
// Pin constants — define every pin here, never inline
const int EXAMPLE_PIN = 9;

// State variables
unsigned long lastUpdate = 0;
const unsigned long UPDATE_INTERVAL_MS = 50;

void setup() {
  Serial.begin(115200);  // must match Pi pyserial config
  // pinMode declarations here
}

void loop() {
  // 1. Parse incoming serial commands (non-blocking)
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    handleCommand(cmd);
  }

  // 2. Periodic updates (non-blocking millis pattern)
  unsigned long now = millis();
  if (now - lastUpdate >= UPDATE_INTERVAL_MS) {
    lastUpdate = now;
    // periodic sensor reads, telemetry sends, etc.
  }
}

void handleCommand(const String& cmd) {
  // parse and dispatch commands from Pi
  // e.g. if (cmd == "PING") Serial.println("PONG");
}
```

## 4. Apply style rules

Verify the sketch follows `.claude/rules/arduino-sketch-style.md`:
- No `delay()` anywhere
- All pins as constants
- Serial baud rate is `115200`
- Motors only via L298N
- `loop()` returns in microseconds

## 5. Report

State the file created and a one-line summary of what it does.
