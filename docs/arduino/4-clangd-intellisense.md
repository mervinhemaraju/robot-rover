# clangd IntelliSense for the Arduino sketch

How to get VS Code's clangd extension to understand the UNO R4 Minima sketch so
it stops showing false `Arduino.h not found` / undeclared-identifier errors.
This is editor-only; it does not affect the actual Arduino build or upload.

## What was done

- Generated a compilation database from the real Arduino build with
  `arduino/rover_motors/gen-compile-db.sh`, which writes
  `arduino/rover_motors/build/compile_commands.json` (git-ignored).
- Added a small `arduino/rover_motors/.clangd` that points clangd at that
  database and adapts the ARM cross-compile command to clangd's host clang:
  - `Compiler: clang++` (use host clang, not the arm-none-eabi cross-compiler)
  - `Add: [-xc++, -include, Arduino.h]` (parse `.ino` as C++ and give it the
    implicit core include so `Serial`/`HIGH` resolve)
  - `Remove: [-mcpu=*, -mfpu=*, -mfloat-abi=*, -mthumb, -mabi=*]` (drop ARM-only
    flags host clang rejects)
- Added `.vscode/settings.json` mapping `*.ino` to C++ (local only).

## How to reproduce

1. Install the clangd VS Code extension (it downloads its own clangd binary; no
   separate install needed). The Microsoft C/C++ IntelliSense should be disabled
   to avoid conflicts.
2. Generate the compilation database:
   ```bash
   cd <repo>
   ./arduino/rover_motors/gen-compile-db.sh
   ```
   It auto-finds `arduino-cli` on PATH, or falls back to the binary bundled with
   Arduino IDE. Re-run it after adding a source file, changing `#include`s, or
   upgrading the Renesas core.
3. The committed `arduino/rover_motors/.clangd` already has the right settings.
4. In VS Code: Cmd+Shift+P -> "clangd: Restart language server". The errors clear.

## Blockers

| Issue | Status | Notes |
|---|---|---|
| `Arduino.h file not found`, undeclared `HIGH`/`analogWrite` | Resolved | clangd had no compile flags. Fixed by generating `compile_commands.json`. |
| `Unsupported argument 'cortex-m4' to -mcpu` | Resolved | The build command targets arm-none-eabi. Stripped ARM flags via `.clangd` `Remove` and set `Compiler: clang++`. |
| `.ino`: "expected exactly one compiler job" | Resolved | clangd does not know the `.ino` extension. Added `-xc++`. |
| `.ino`: local symbols (`SERIAL_BAUD`) undeclared | Resolved | `@response-files` in `.clangd` made clangd treat a response file as the input. Inlining was tried, then replaced by the cleaner database approach above. |
