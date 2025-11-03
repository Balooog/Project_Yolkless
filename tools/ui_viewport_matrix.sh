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

usage() {
	cat <<'EOF'
Usage: ui_viewport_matrix.sh [options]

Options:
  --baseline            Generate placeholder baselines in dev/screenshots/ui_baseline/.
  --out-dir=PATH        Generate placeholder PNGs into PATH (implies placeholder mode).
  --placeholders        Generate placeholder PNGs into dev/screenshots/ui_current/.
  --help                Show this help message.

Without options the script captures the viewport matrix from Godot smoke scenes.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--baseline)
			MODE="placeholder"
			OUTPUT_DIR="${REPO_ROOT}/dev/screenshots/ui_baseline"
			shift
			;;
		--out-dir=*)
			MODE="placeholder"
			OUTPUT_DIR="${1#*=}"
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
