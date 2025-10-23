#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <seconds>" >&2
  exit 1
fi

SECONDS_TO_SIM="$1"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
GODOT_BIN="${GODOT_BIN:-godot4}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Error: $GODOT_BIN not found in PATH. Set GODOT_BIN to your Godot 4 CLI." >&2
  exit 2
fi

set -x
"$GODOT_BIN" \
  --headless \
  --path "$ROOT_DIR" \
  --script "res://game/scripts/ci/econ_probe.gd" \
  -- \
  --seconds="$SECONDS_TO_SIM"
