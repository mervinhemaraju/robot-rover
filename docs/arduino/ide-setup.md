# Arduino IDE Setup: macOS (Apple Silicon)

## Environment

- macOS on Apple Silicon (M-series chip)
- Arduino IDE 2.3.10
- Board: Arduino UNO R4 Minima
- Board package: Arduino UNO R4 Boards v1.6.0

---

## Install the board package

1. Open Arduino IDE
2. Go to **Tools > Board > Boards Manager**
3. Search for `Arduino UNO R4`
4. Install **Arduino UNO R4 Boards** (v1.6.0 or later)

---

## Fix: bad CPU type error on Apple Silicon

The board package bundles an older `arm-none-eabi-gcc` toolchain compiled for x86_64. On Apple Silicon, this fails with:

```
fork/exec .../arm-none-eabi-g++: bad CPU type in executable
```

Fix: install Rosetta 2, which lets macOS run x86_64 binaries transparently.

```bash
softwareupdate --install-rosetta --agree-to-license
```

Restart Arduino IDE after installation. No further configuration needed.

---

## Board and port selection

- **Tools > Board > Arduino UNO R4 Boards > Arduino UNO R4 Minima**
- **Tools > Port > /dev/cu.usbmodem1101** (appears when Arduino is connected via USB-C)

Connect the Arduino to the Mac with a USB-A to USB-C cable before opening the port menu.

---

## Upload and verify

1. Open the sketch
2. Click **Upload** (right-arrow button, top-left)
3. Wait for: `Sketch uses X bytes (Y%) of program storage space`
4. Open **Tools > Serial Monitor** (Shift+Cmd+M)
5. Set baud rate to **115200** (bottom-right of Serial Monitor)
6. Confirm the ready message appears

For `motor_first_test.ino` the expected output on open:

```
Ready. F=forward  B=backward  S=stop
```

Type `F`, `B`, or `S` and press Enter to send commands.

---

## Quick reference

| Setting | Value |
| --- | --- |
| Board package | Arduino UNO R4 Boards v1.6.0 |
| Board | Arduino UNO R4 Minima |
| Port | /dev/cu.usbmodem1101 |
| Baud rate | 115200 |
| Apple Silicon fix | Rosetta 2 via `softwareupdate --install-rosetta` |
