#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
OUT_DIR="$ROOT_DIR/build/linux"
mkdir -p "$OUT_DIR"
: "${GODOT_BIN:=/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot binary not found at $GODOT_BIN. Install the renderer-enabled CLI or update GODOT_BIN." >&2
  exit 1
fi
exec "$GODOT_BIN" --path "$ROOT_DIR" --headless --export-release "Linux" "$OUT_DIR/Yolkless.x86_64"
