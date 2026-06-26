# Buck Converter Setup: Setting to 5V for the Raspberry Pi

Do this **before** the Pi is ever connected to the converter. There is no undo if you connect at the wrong voltage.

---

## What the buck converter does

The 18650 battery pack outputs ~7.4V in series. The Raspberry Pi 3B requires exactly 5V; its maximum safe input is **5.25V**. Anything above that can permanently damage the Pi.

The buck converter steps the voltage down. It has a small adjustment screw (potentiometer) that controls the output voltage. Out of the box it is not set to 5V; you must set it manually and verify with a multimeter.

---

## What you need

- 20W Adjustable DC-DC Buck Converter (the one with the digital display)
- 18650 battery pack (both cells inserted, fully or partially charged)
- ANENG DM850 multimeter
- Small flat-head or Phillips screwdriver (the potentiometer screw is tiny)
- The Pi **not present** (set it aside until step 8)

---

## Steps

### 1. Do not connect the Pi yet

Keep the Pi away from this process entirely. You are working with 7.4V input and an unknown output voltage until calibration is done.

### 2. Identify the buck converter terminals

The board has four screw terminals:

```text
[ IN+ ][ IN- ]      <-- battery pack connects here (input)
[ OUT+ ][ OUT- ]    <-- Pi will connect here later (output)
```

The digital display on the board shows the **output voltage**.

### 3. Connect the battery pack to the input

- **IN+** → red wire (positive) from battery pack
- **IN-** → black wire (negative) from battery pack

Tighten the screw terminals firmly. Loose connections cause voltage fluctuation.

> **Polarity risk:** Reversing IN+ and IN- will not necessarily destroy the buck converter immediately, but it can. Double-check red → IN+ and black → IN− before powering on.

### 4. Turn on the battery pack switch

The digital display should light up showing the current output voltage. It will likely read something other than 5V. This is expected.

### 5. Locate the potentiometer

It is a small brass screw on the surface of the board, usually near one corner. Turning it adjusts the output voltage:

- **Clockwise** → increases output voltage
- **Counter-clockwise** → decreases output voltage

Turn slowly. Small movements make a noticeable difference.

### 6. Adjust until the display reads 5.0V

Turn the potentiometer screw gradually, pausing after each small turn to let the display settle. Aim for **5.0V** on the display.

### 7. Verify with the multimeter

The display is a guide, not ground truth. Confirm with the multimeter:

1. Set the multimeter to **DC Voltage (V⎓)**, range 20V or auto
2. Plug the **black probe into the COM port** on the multimeter body
3. Plug the **red probe into the VΩ port** on the multimeter body (the one marked with V and Ω — not the A/10A port, which is for current only)
4. Touch the **red probe tip to OUT+** and the **black probe tip to OUT−**
5. Read the value

**Target range: 4.95V – 5.05V**

If the multimeter disagrees with the display, trust the multimeter and adjust until the multimeter reads within the target range.

> Why this matters: A reading of 5.3V on the multimeter means 5.3V will hit the Pi's power rail. The Pi 3B's limit is 5.25V. A reading of 5.3V may cause immediate damage or shorten its lifespan. There is no warning, no fuse, no recovery.

### 8. Lock the potentiometer

The potentiometer is a mechanical screw. Rover vibration and physical knocks can shift it, changing the output voltage without any warning. Lock it in place before the Pi ever connects.

**Apply a single small drop of clear nail varnish directly onto the potentiometer screw head.** Let it seep into the thread around the screw, then leave it to cure for at least one hour before powering on again.

- Do not flood the board. One drop on the screw head is enough.
- Do not skip the curing time. Wet varnish conducts slightly and can cause erratic readings.
- If you ever need to recalibrate, pick the dried varnish off the screw head with a toothpick, re-adjust, re-verify with the multimeter, then apply a fresh drop.

> Clear nail varnish is available at any pharmacy. Hot glue from a glue gun is an acceptable alternative and peels off more easily, but is bulkier.

### 9. Power off before connecting the Pi

Turn the battery pack switch off. Only now is it safe to wire the Pi:

- **OUT+** → Pi micro USB power input (positive rail)
- **OUT−** → Pi micro USB power input (negative/ground)

### 10. Power on and verify boot

Turn the battery switch back on. The Pi should boot normally: solid red PWR LED, green ACT LED blinking during boot.

If the Pi shows a **rainbow square** in the top-right corner of the display (or if you were using a display), that is an undervoltage warning: the converter output is too low. Adjust up slightly and recheck.

**Note on voltage under load:** Once the Pi is drawing current (500–700mA during boot), the multimeter will read slightly lower than your no-load calibration reading — a drop of 0.01–0.05V is normal and is not potentiometer drift. What matters is that the under-load reading stays within 4.95–5.05V. If your no-load reading was 5.01V and it reads 4.98V with the Pi running, that is correct behaviour.

---

## After any future adjustment

If you ever re-adjust the potentiometer (e.g. after transport, after a knock), always re-verify with the multimeter **before** reconnecting the Pi. The screw can shift.

---

## Quick reference

| Check | Value |
| --- | --- |
| Battery pack output (input to converter) | ~7.4V |
| Converter output target | 5.00V |
| Acceptable multimeter range | 4.95V – 5.05V |
| Pi 3B absolute maximum input | 5.25V |
| Symptom of too-low voltage | Rainbow square / boot loop |
| Symptom of too-high voltage | Silent damage (no warning) |
