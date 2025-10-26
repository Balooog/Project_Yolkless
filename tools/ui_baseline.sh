#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-${REPO_ROOT}/dev/screenshots/ui_baseline}"

GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
export GODOT_BIN

echo "[ui_baseline] capturing baseline screenshots into ${OUTPUT_DIR}"

mkdir -p "${OUTPUT_DIR}"

"${GODOT_BIN}" --path "${REPO_ROOT}" --rendering-driver vulkan --script "res://tools/ui_screenshots.gd" -- "--baseline=${OUTPUT_DIR}"
