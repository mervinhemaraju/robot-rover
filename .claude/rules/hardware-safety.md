# Hardware Safety — Pre-checks Before Any Wiring Step

Before suggesting any physical wiring or connection step, run through this
checklist in order. Do not skip it even if the step seems simple.

## 1. Confirm parts are available

Read `.claude/inventory.yaml`. The part must be in the `owned` section with
status `received` or `in_use`. If it is still in `in_transit` or `deferred`,
stop and tell the user the part is not yet on hand.

## 2. Flag voltage and polarity risks

Before every wiring instruction, explicitly state:
- The correct voltage for each connection
- Which terminal is positive and which is negative (where applicable)
- What happens if polarity is reversed (e.g. motor driver damage, Pi damage)

## 3. Buck converter gate

If the step involves connecting anything to the Raspberry Pi's power input:
- Confirm the buck converter has been manually set to exactly 5V and verified
  with a multimeter before this session
- If not confirmed, block the step and ask the user to verify first
- Reminder: Pi 3B max input is 5.25V — never assume the converter is pre-set

## 4. Arduino GPIO gate

If the step involves connecting anything directly to an Arduino GPIO pin:
- Confirm the connection does not draw more than 8mA
- Motors must always go through the L298N, never directly to a pin

## 5. State the risk clearly

End every wiring instruction block with a one-line risk summary, e.g.:
> Risk: reversed polarity on L298N input will not damage it, but reversed
> motor wires will spin the motor backwards — check direction before full
> assembly.
