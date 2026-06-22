# Serial Debug: $ARGUMENTS

Diagnose Pi ↔ Arduino serial communication issues systematically.

## 1. Find the device

On the Pi, run:
```bash
ls /dev/ttyACM* /dev/ttyUSB*
```
Expected: `/dev/ttyACM0` when Arduino is connected via USB-C.
If missing: Arduino is not detected — check the USB-C cable and try a different port.

## 2. Check permissions

```bash
groups th3pl4gu3
```
The `dialout` group must be present. If not:
```bash
sudo usermod -aG dialout th3pl4gu3
# then log out and back in, or reboot
```

## 3. Check baud rate match

- Arduino sketch: confirm `Serial.begin(115200)` in `setup()`
- Pi Python: confirm `serial.Serial(..., baudrate=115200)`
- Mismatched baud rates produce garbled output, not an error

## 4. Send a test command manually

On the Pi, open a raw serial connection:
```bash
python3 -c "
import serial, time
s = serial.Serial('/dev/ttyACM0', 115200, timeout=2)
time.sleep(2)  # wait for Arduino reset after connect
s.write(b'PING\n')
print(repr(s.readline()))
s.close()
"
```
Expected: Arduino echoes a response. No response = sketch not running or wrong port.

## 5. Check Arduino is running

In Arduino IDE Serial Monitor (or `screen /dev/ttyACM0 115200` on the Pi),
confirm the sketch is sending output. Opening a serial connection resets the
Arduino — wait 2 seconds before sending the first command.

## 6. Report findings

State:
- Device path found (or not found)
- Permission status
- Baud rate match confirmed (yes/no)
- Test command result
- Root cause and fix applied (or what is still needed)
