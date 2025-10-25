#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"
OUTPUT_DIR="${1:-${REPO_ROOT}/dev/screenshots/ui_baseline}"

echo "[ui_baseline] capturing baseline screenshots into ${OUTPUT_DIR}"

"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --script "res://tools/ui_screenshots.gd" -- "--baseline=${OUTPUT_DIR}"
