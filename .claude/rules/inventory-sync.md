# Inventory — Keep inventory.yaml in Sync

Whenever parts are discussed in a session, update `.claude/inventory.yaml`
before the end of that turn. Do not wait to be asked.

## Triggers

Update the inventory when the user mentions any of the following:

- A part has arrived / been received
- A part is now in use / installed
- A new part has been ordered
- A part is being added to the deferred list
- A part is being rejected (add to `rejected` with a reason)
- A quantity, source, or note needs correcting

## How to update

- Move the item to the correct section (`owned`, `in_transit`, `deferred`, `rejected`)
- Update the `status` field if it changed (`received` → `in_use`, etc.)
- Add or correct any fields (`qty`, `source`, `notes`) based on what was discussed
- Do not remove items — rejected parts stay in `rejected` for reference

## After updating

Tell the user what changed in one line (e.g. "Updated inventory: Arduino Uno R4 Minima moved from in_transit → owned, status: received").
