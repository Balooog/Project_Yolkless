#!/usr/bin/env bash
set -euo pipefail

export PATH="/snap/bin:$PATH"

if [ ! -d ".godot/imported" ] || [ -z "$(ls -A .godot/imported 2>/dev/null || true)" ]; then
	echo "[warmup] running one-time import…"
	godot4 --headless --path . --import
fi

godot4 --headless --path . -s res://game/scripts/ci_smoke.gd
