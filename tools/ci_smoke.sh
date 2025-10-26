#!/usr/bin/env bash
set -euo pipefail

: "${GODOT_BIN:=/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe}"

export PATH="/snap/bin:$PATH"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "[ci_smoke] godot binary not found at $GODOT_BIN" >&2
	exit 1
fi

if [ ! -d ".godot/imported" ] || [ -z "$(ls -A .godot/imported 2>/dev/null || true)" ]; then
	echo "[warmup] running one-time import…"
	"$GODOT_BIN" --headless --path . --import
fi

"$GODOT_BIN" --headless --path . -s res://game/scripts/ci_smoke.gd

# SandboxGrid regression checks (fails fast if CA logic regresses)
"$GODOT_BIN" --headless --script tests/sandbox/test_sandbox_grid.gd --quit
