#!/usr/bin/env bash
set -euo pipefail

# Launch Project Yolkless at several window sizes in sequence.
# Usage:
#   ./tools/run_resolutions.sh                # use defaults
#   GODOT_ARGS="--fullscreen" ./tools/run_resolutions.sh 1920x1080

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GODOT_ARGS="${GODOT_ARGS:-}"

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
	export GODOT_BIN
fi

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "[run_resolutions] Godot binary not found at $GODOT_BIN" >&2
	exit 1
fi

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
