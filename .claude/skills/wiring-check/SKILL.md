# Wiring Check: $ARGUMENTS

Generate a step-by-step wiring checklist for the connection described in
$ARGUMENTS (e.g. "L298N to Arduino", "buck converter to Pi").

## 1. Confirm parts

Read `.claude/inventory.yaml`. List which parts are needed for this wiring
and confirm each is present (`owned`, status `received` or `in_use`).
If any part is missing, stop and say so — do not continue.

## 2. List the connections

Produce a table of every wire that needs to be made:

| From | Pin / Terminal | To | Pin / Terminal | Notes |
|---|---|---|---|---|
| Component A | Pin name / number | Component B | Pin name / number | Voltage, colour suggestion |

Be exact — no "connect to power" without specifying which power rail and voltage.

## 3. Voltage and current warnings

For each connection, call out any risk:
- Wrong voltage levels
- Polarity-sensitive connections
- Current limits that must not be exceeded

## 4. Pre-power checklist

A numbered checklist to verify before applying power:

- [ ] All connections double-checked against the table above
- [ ] No bare wire ends that could short
- [ ] Buck converter verified at 5V with multimeter (if Pi is involved)
- [ ] Motors connected via L298N only — not directly to Arduino pins
- [ ] Power switch is OFF before making any changes

## 5. Test procedure

Describe the minimum test to confirm the wiring is correct once power is on,
before moving on (e.g. "run this script and expect this output").
