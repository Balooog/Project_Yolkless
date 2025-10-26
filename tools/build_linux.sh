#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
OUT_DIR="$ROOT_DIR/build/linux"
mkdir -p "$OUT_DIR"

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${ROOT_DIR}/tools/godot_resolver.sh")"
	export GODOT_BIN
fi

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "Godot binary not found at $GODOT_BIN. Install the renderer-enabled CLI or update GODOT_BIN." >&2
	exit 1
fi

exec "$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Linux" "$OUT_DIR/Yolkless.x86_64"
