# Arduino Sketch Style

## Timing — never use delay()

`delay()` blocks the entire loop, making the rover unresponsive to serial
commands while waiting. Always use non-blocking timing with `millis()`:

```cpp
unsigned long lastUpdate = 0;
const unsigned long INTERVAL_MS = 100;

void loop() {
  unsigned long now = millis();
  if (now - lastUpdate >= INTERVAL_MS) {
    lastUpdate = now;
    // do periodic work here
  }
  // handle serial every iteration regardless
}
```

## Pin constants

Define every pin at the top of the sketch as a constant — never use raw numbers inline:

```cpp
const int LEFT_MOTOR_EN  = 5;
const int LEFT_MOTOR_IN1 = 4;
const int LEFT_MOTOR_IN2 = 3;
```

## Serial

- Baud rate is always `115200` — must match the Pi's `pyserial` config
- Parse commands in `loop()` using `Serial.available()` — non-blocking
- Never `Serial.print()` inside a tight loop or ISR — it blocks
- Use `Serial.println()` for debug only during development; remove before final build

## Motors

- Motors are always driven via L298N — never connect motor wires to Arduino pins directly
- Max GPIO current is 8mA; L298N logic pins are fine, motor terminals are not
- Enable pins (ENA, ENB) use `analogWrite()` for PWM speed control (0–255)
- Direction pins (IN1–IN4) use `digitalWrite()` only

## Loop discipline

Keep `loop()` fast — it must return in microseconds, not milliseconds:
- No blocking I/O
- No `delay()`
- No `while()` loops that wait for a condition
- Serial parsing and motor updates are the only work in `loop()`
