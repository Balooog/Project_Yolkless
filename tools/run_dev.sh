#!/usr/bin/env bash
set -euo pipefail
export PATH="/snap/bin:$PATH"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
if ! command -v godot4 >/dev/null 2>&1; then
  echo "godot4 binary not found in PATH. Install Godot 4.x CLI." >&2
  exit 1
fi
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"
STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="$LOG_DIR/game-$STAMP.log"
echo "Logging to $LOG_FILE"
if [[ "${NO_WINDOW:-0}" == "1" ]]; then
  godot4 --headless --path "$ROOT_DIR" "$@" 2>&1 | tee "$LOG_FILE"
else
  godot4 --path "$ROOT_DIR" "$@" 2>&1 | tee "$LOG_FILE"
fi
