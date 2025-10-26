#!/usr/bin/env bash
set -euo pipefail
: "${GODOT_BIN:=/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe}"
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <seconds>" >&2
  exit 1
fi

SECONDS_TO_SIM="$1"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Error: Godot binary not found at $GODOT_BIN. Update GODOT_BIN to the renderer-enabled CLI." >&2
  exit 2
fi

set -x
"$GODOT_BIN" \
  --headless \
  --path "$ROOT_DIR" \
  --script "res://tools/replay_headless.gd" \
  --duration="$SECONDS_TO_SIM"
