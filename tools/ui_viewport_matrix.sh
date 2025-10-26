#!/usr/bin/env bash
set -euo pipefail

: "${GODOT_BIN:=/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

VIEWPORTS=(
	"640x360"
	"800x600"
	"1280x720"
	"1920x1080"
)

for vp in "${VIEWPORTS[@]}"; do
	echo "[ui_viewport_matrix] capturing viewport ${vp}"
	"${GODOT_BIN}" --path "${REPO_ROOT}" --script "res://tools/ui_screenshots.gd" -- "--viewport=${vp}" "--capture"
done
