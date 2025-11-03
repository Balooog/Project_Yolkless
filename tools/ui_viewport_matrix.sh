#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
export GODOT_BIN

MODE="godot"
OUTPUT_DIR=""
BASELINE_MODE="false"
BASELINE_SCENES="res://scenes/ui_baseline/hud_blank_reference.tscn,res://scenes/ui_baseline/hud_power_normal.tscn,res://scenes/ui_baseline/hud_power_warning.tscn,res://scenes/ui_baseline/hud_power_critical.tscn"
SCENE_LIST=""
APPEND_VIEWPORT_SUFFIX=1

usage() {
	cat <<'EOF'
Usage: ui_viewport_matrix.sh [options]

Options:
  --baseline            Capture Godot HUD screenshots into dev/screenshots/ui_baseline/.
  --out-dir=PATH        Capture screenshots into PATH.
  --placeholders        Generate synthetic placeholder PNGs into dev/screenshots/ui_current/.
  --help                Show this help message.

Without options the script captures the viewport matrix from Godot smoke scenes.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--baseline)
		BASELINE_MODE="true"
		OUTPUT_DIR="${REPO_ROOT}/dev/screenshots/ui_baseline"
		SCENE_LIST="${BASELINE_SCENES}"
		APPEND_VIEWPORT_SUFFIX=0
		shift
		;;
	--out-dir=*)
		OUTPUT_DIR="${1#*=}"
		shift
		;;
	--scenes=*)
		SCENE_LIST="${1#*=}"
		shift
		;;
	--no-viewport-suffix)
		APPEND_VIEWPORT_SUFFIX=0
		shift
		;;
	--placeholders)
		MODE="placeholder"
		OUTPUT_DIR="${REPO_ROOT}/dev/screenshots/ui_current"
		shift
		;;
	--help|-h)
		usage
		exit 0
		;;
	*)
		echo "[ui_viewport_matrix] unknown option: $1" >&2
		usage
		exit 1
		;;
	esac
done

if [[ "${MODE}" == "placeholder" ]]; then
	if [[ -z "${OUTPUT_DIR}" ]]; then
		echo "[ui_viewport_matrix] placeholder mode requires --out-dir or --baseline." >&2
		exit 1
	fi
	if [[ "${OUTPUT_DIR}" != /* ]]; then
		OUTPUT_DIR="$(cd "${REPO_ROOT}" && python3 - "$OUTPUT_DIR" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
	fi
	echo "[ui_viewport_matrix] generating placeholder HUD matrix at ${OUTPUT_DIR}"
	python3 "${SCRIPT_DIR}/ui_generate_baseline.py" --output "${OUTPUT_DIR}"
	exit 0
fi

if [[ -n "${OUTPUT_DIR}" ]]; then
	if [[ "${OUTPUT_DIR}" != /* ]]; then
		OUTPUT_DIR="$(cd "${REPO_ROOT}" && python3 - "$OUTPUT_DIR" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
	fi
	mkdir -p "${OUTPUT_DIR}"
	find "${OUTPUT_DIR}" -maxdepth 1 -type f \( -name '*.png' -o -name '*.png.import' \) -delete
fi

VIEWPORTS=("1280x720")

if [[ "${BASELINE_MODE}" == "false" ]] && [[ -z "${OUTPUT_DIR}" ]]; then
	# Default matrix capture with multiple breakpoints only when output dir not specified.
	VIEWPORTS=("640x360" "800x600" "1280x720" "1920x1080")
fi

for vp in "${VIEWPORTS[@]}"; do
	echo "[ui_viewport_matrix] capturing viewport ${vp}"
	cmd=("${GODOT_BIN}" --path "${REPO_ROOT}" --rendering-driver vulkan --script "res://tools/ui_screenshots.gd" -- "--viewport=${vp}" "--capture")
	if [[ -n "${SCENE_LIST}" ]]; then
		cmd+=("--scenes=${SCENE_LIST}")
	fi
	if [[ ${APPEND_VIEWPORT_SUFFIX} -eq 0 ]]; then
		cmd+=("--no-viewport-suffix")
	fi
	if [[ -n "${OUTPUT_DIR}" ]]; then
		cmd+=("--output=${OUTPUT_DIR}")
	fi
	"${cmd[@]}"
done
