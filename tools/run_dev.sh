#!/usr/bin/env bash
set -euo pipefail
export PATH="/snap/bin:$PATH"

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${ROOT_DIR}/tools/godot_resolver.sh")"
	export GODOT_BIN
fi

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "Godot binary not found at $GODOT_BIN. Install the renderer-enabled CLI or update GODOT_BIN." >&2
	exit 1
fi
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"
STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="$LOG_DIR/game-$STAMP.log"
echo "Logging to $LOG_FILE"
if [[ "${NO_WINDOW:-0}" == "1" ]]; then
  "$GODOT_BIN" --headless --path "$ROOT_DIR" "$@" 2>&1 | tee "$LOG_FILE"
else
  "$GODOT_BIN" --path "$ROOT_DIR" "$@" 2>&1 | tee "$LOG_FILE"
fi
