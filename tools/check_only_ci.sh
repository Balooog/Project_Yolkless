#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
export GODOT_BIN

echo "[ci] Using $("$GODOT_BIN" --version)"

if "${SCRIPT_DIR}/check_only.sh"; then
	echo "✅ Check passed"
else
	echo "❌ Check failed"
	exit 1
fi

BASELINE_DIR="${REPO_ROOT}/dev/screenshots/ui_baseline"
CURRENT_DIR="${REPO_ROOT}/dev/screenshots/ui_current"

if [[ ! -d "${BASELINE_DIR}" ]]; then
	echo "[ci] Missing UI baseline directory: ${BASELINE_DIR}" >&2
	exit 1
fi

mkdir -p "${CURRENT_DIR}"
find "${CURRENT_DIR}" -maxdepth 1 -type f -name '*.png' -delete
find "${CURRENT_DIR}" -maxdepth 1 -type f -name '*.png.import' -delete

BASELINE_SCENES="res://scenes/ui_baseline/hud_blank_reference.tscn,res://scenes/ui_baseline/hud_power_normal.tscn,res://scenes/ui_baseline/hud_power_warning.tscn,res://scenes/ui_baseline/hud_power_critical.tscn"
"${SCRIPT_DIR}/ui_viewport_matrix.sh" --out-dir="${CURRENT_DIR}" --scenes="${BASELINE_SCENES}" --no-viewport-suffix
"${SCRIPT_DIR}/ui_compare.sh" "${BASELINE_DIR}" "${CURRENT_DIR}"
