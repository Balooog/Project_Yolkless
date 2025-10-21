#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
OUT_DIR="$ROOT_DIR/build/linux"
mkdir -p "$OUT_DIR"
if ! command -v godot4 >/dev/null 2>&1; then
  echo "godot4 binary not found in PATH. Install Godot 4.x CLI." >&2
  exit 1
fi
exec godot4 --path "$ROOT_DIR" --headless --export-release "Linux" "$OUT_DIR/Yolkless.x86_64"
