#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"

VIEWPORTS=(
	"640x360"
	"800x600"
	"1280x720"
	"1920x1080"
)

for vp in "${VIEWPORTS[@]}"; do
	echo "[ui_viewport_matrix] capturing viewport ${vp}"
	"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --script "res://tools/ui_screenshots.gd" -- "--viewport=${vp}"
done
