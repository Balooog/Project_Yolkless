#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
if ! command -v godot4 >/dev/null 2>&1; then
  echo "godot4 binary not found in PATH. Install Godot 4.x CLI." >&2
  exit 1
fi
if [[ "${NO_WINDOW:-0}" == "1" ]]; then
  exec godot4 --headless --path "$ROOT_DIR" "$@"
else
  exec godot4 --path "$ROOT_DIR" "$@"
fi
