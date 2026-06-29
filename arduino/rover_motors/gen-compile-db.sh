#!/usr/bin/env bash
# Regenerate compile_commands.json for clangd (editor IntelliSense only; this
# does not affect the real Arduino build/upload).
#
# Run after adding or removing a source file, changing #includes, or upgrading
# the Renesas core. The build/ output directory is git-ignored.
set -euo pipefail

SKETCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FQBN="arduino:renesas_uno:minima"

# Prefer arduino-cli on PATH; fall back to the binary bundled with Arduino IDE.
if command -v arduino-cli >/dev/null 2>&1; then
  CLI="arduino-cli"
else
  CLI="/Applications/Arduino IDE.app/Contents/Resources/app/lib/backend/resources/arduino-cli"
fi

"$CLI" compile \
  --fqbn "$FQBN" \
  --only-compilation-database \
  --build-path "$SKETCH_DIR/build" \
  "$SKETCH_DIR"

echo "compile_commands.json regenerated in $SKETCH_DIR/build"
