# Raspberry Pi — Always Shut Down Cleanly

Whenever a session involves the Raspberry Pi and is wrapping up — or whenever
power disconnection is mentioned — always include this reminder before closing:

---
**Before disconnecting power from the Pi:**
1. Run `sudo shutdown -h now`
2. Wait for the green activity LED to stop blinking and go dark
3. Only then disconnect power

Skipping this risks filesystem corruption and may require a full re-flash.
(This already happened once on this project.)

---

## When to show this

- At the end of any session where the Pi was actively used
- Whenever the user mentions disconnecting, powering off, or packing up
- Whenever a wiring change requires removing power from the Pi
