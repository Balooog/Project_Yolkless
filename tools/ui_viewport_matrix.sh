#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
export GODOT_BIN

VIEWPORTS=(
	"640x360"
	"800x600"
	"1280x720"
	"1920x1080"
)

for vp in "${VIEWPORTS[@]}"; do
	echo "[ui_viewport_matrix] capturing viewport ${vp}"
	"${GODOT_BIN}" --path "${REPO_ROOT}" --rendering-driver vulkan --script "res://tools/ui_screenshots.gd" -- "--viewport=${vp}" "--capture"
done
