# Pi Serial Motor Test: First Full-Chain Verification

Testing the complete chain: Pi Python script → USB serial → Arduino → L298N → motors.

---

## What was done

- Debugged Arduino not appearing as `/dev/ttyACM0` on the Pi - root cause was a charge-only USB-C cable (no data lines)
- Fixed buck converter undervoltage: adjusted potentiometer from ~5.03V to 5.13V no-load so under-load voltage (Pi + Arduino) holds at ~5.09V without triggering undervoltage warnings
- Confirmed Arduino detected on `/dev/ttyACM0` with correct data cable
- Connected one motor to L298N OUT1/OUT2 and ran `pi/serial-repl/main.py` - motor spun forward 1 second then stopped (chain verified)
- Wired all 4 motors (left pair to OUT1/OUT2, right pair to OUT3/OUT4) and right channel logic pins (ENB=pin6, IN3=pin8, IN4=pin9) to Arduino
- Updated `pi/serial-repl/main.py` to test full sequence: F (2s) → S → B (2s) → S → L (1s) → S → R (1s) → S
- Added `turnLeft()` and `turnRight()` functions to `motor_first_test.ino`; replaced `ledOn()`/`ledOff()` with `toggleLed()` (single `E` command toggles state)
- F and B confirmed working with all 4 motors
- Session ended early: serial connection dropped during/after L command; battery depleted to 3.4V output on buck converter display

---

## How to reproduce

### Verify Arduino is detected on Pi

1. Connect Arduino USB-C to Pi USB-A using a **data cable** (the same cable used to upload sketches from the Mac)
2. SSH into Pi: `ssh th3pl4gu3@192.168.0.4`
3. Run: `ls /dev/ttyACM0` - must return `/dev/ttyACM0`
4. If not found, run `lsusb` - Arduino should appear as a Renesas device. If absent, the cable is charge-only.

### Run the serial test script

```bash
# From Mac
scp pi/serial-repl/main.py th3pl4gu3@192.168.0.4:~/rover/

# On Pi
cd ~/rover && source venv/bin/activate && python main.py
```

### Arduino commands (current sketch)

| Command | Action |
|---|---|
| `F` | All 4 wheels forward |
| `B` | All 4 wheels backward |
| `S` | Stop all motors |
| `L` | Turn left (left motors backward, right motors forward) |
| `R` | Turn right (left motors forward, right motors backward) |
| `E` | Toggle onboard LED on/off |

---

## Blockers

| Issue | Status | Notes |
|---|---|---|
| Charge-only USB-C cable | Resolved | Use only the cable confirmed to carry data (same one used for Mac uploads). Label it. |
| Buck converter undervoltage under load | Resolved | Potentiometer adjusted to 5.13V no-load; reads 5.09V with Pi + Arduino. Two brief warnings at boot are normal (startup surge). |
| Serial connection drops during/after L (turn left) command | Open | `serial.SerialException: write failed: [Errno 5] Input/output error` after sending L. F and B work fine. Suspected cause: increased current draw during turn causes voltage dip that resets Arduino. Needs diagnosis next session. |
| Battery depleted mid-session | Resolved (charge needed) | Buck converter output dropped to 3.4V after repeated motor runs. Cells need full charge before next session. Always check battery voltage before testing - below 7.0V combined, charge first. |
