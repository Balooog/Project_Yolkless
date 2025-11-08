#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-}"
BASELINE_DIR=""

: "${UI_BASELINE_PLACEHOLDER:=0}"

resolve_path() {
	local path="$1"
	if [[ "${path}" != /* ]]; then
		path="$(cd "${REPO_ROOT}" && python3 - "$path" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
	fi
	echo "${path}"
}

if [[ -n "${OUTPUT_DIR}" ]]; then
	BASELINE_DIR="$(resolve_path "${OUTPUT_DIR}")"
else
	BASELINE_DIR="${REPO_ROOT}/dev/screenshots/ui_baseline"
fi

mkdir -p "${BASELINE_DIR}"
echo "[ui_baseline] generating baseline into ${BASELINE_DIR}"

if [[ "${UI_BASELINE_PLACEHOLDER}" == "1" ]]; then
	python3 "${SCRIPT_DIR}/ui_generate_baseline.py" --output "${BASELINE_DIR}"
	exit 0
fi

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
	export GODOT_BIN
fi

LOCAL_HOME="${REPO_ROOT}/.godot-home"
export HOME="${LOCAL_HOME}"
export XDG_DATA_HOME="${LOCAL_HOME}/.local/share"
export XDG_CONFIG_HOME="${LOCAL_HOME}/.config"
export XDG_CACHE_HOME="${LOCAL_HOME}/.cache"
export XDG_RUNTIME_DIR="${LOCAL_HOME}/.runtime"
mkdir -p "${XDG_DATA_HOME}/godot" "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" "${XDG_RUNTIME_DIR}"

RELATIVE_OUTPUT="$(python3 - "$REPO_ROOT" "$BASELINE_DIR" <<'PY'
import pathlib
import sys
repo = pathlib.Path(sys.argv[1]).resolve()
target = pathlib.Path(sys.argv[2]).resolve()
print(target.relative_to(repo))
PY
)"

"${GODOT_BIN}" --headless --rendering-driver vulkan --quiet --path "${REPO_ROOT}" --script "res://tools/ui_capture_baseline.gd" -- "--output=res://../${RELATIVE_OUTPUT}"
