#!/usr/bin/env bash
set -euo pipefail

# Launch Project Yolkless at several window sizes in sequence.
# Usage:
#   ./tools/run_resolutions.sh                # use defaults
#   GODOT_BIN=godot ./tools/run_resolutions.sh 1280x720 1920x1080
#   GODOT_ARGS="--fullscreen" ./tools/run_resolutions.sh 1920x1080

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"
GODOT_ARGS="${GODOT_ARGS:-}"

if [ "$#" -gt 0 ]; then
  RESOLUTIONS=("$@")
else
  RESOLUTIONS=(
    "480x960"
    "600x360"
    "800x600"
    "1024x768"
    "1280x720"
    "1600x900"
    "1920x1080"
  )
fi

echo "Project Yolkless resolution sweep (${#RESOLUTIONS[@]} variants)."
echo "Closing the window advances to the next size. Ctrl+C to abort."
echo ""

for resolution in "${RESOLUTIONS[@]}"; do
  echo "Launching at ${resolution}..."
  "${GODOT_BIN}" --path "${PROJECT_ROOT}" --resolution "${resolution}" --windowed ${GODOT_ARGS}
  echo ""
done

echo "All requested resolutions complete."
