#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <seconds>" >&2
  exit 1
fi

SECONDS_TO_SIM="$1"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${ROOT_DIR}/tools/godot_resolver.sh")"
	export GODOT_BIN
fi

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "Error: Godot binary not found at $GODOT_BIN. Update GODOT_BIN to the renderer-enabled CLI." >&2
	exit 2
fi

set -x
"$GODOT_BIN" \
  --headless \
  --path "$ROOT_DIR" \
  --script "res://tools/replay_headless.gd" \
  --duration="$SECONDS_TO_SIM"
