#!/usr/bin/env bash
set -euo pipefail
export PATH="/snap/bin:$PATH"

: "${GODOT_BIN:=/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe}"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
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
