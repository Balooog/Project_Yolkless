#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
	export GODOT_BIN
fi

export PATH="/snap/bin:$PATH"

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "[ci_smoke] Godot binary not found at $GODOT_BIN" >&2
	exit 1
fi

if [ ! -d ".godot/imported" ] || [ -z "$(ls -A .godot/imported 2>/dev/null || true)" ]; then
	echo "[warmup] running one-time import…"
	"$GODOT_BIN" --headless --path . --import
fi

"$GODOT_BIN" --headless --path . -s res://game/scripts/ci_smoke.gd

# SandboxGrid regression checks (fails fast if CA logic regresses)
"$GODOT_BIN" --headless --script tests/sandbox/test_sandbox_grid.gd --quit
