#!/usr/bin/env bash
set -Eeuo pipefail

: "${CHECK_ONLY_TIMEOUT:=600}"
: "${STEP_TIMEOUT:=180}"
: "${HEARTBEAT_SECS:=15}"

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES
export LIBGL_ALWAYS_SOFTWARE=1
export SDL_AUDIODRIVER=${SDL_AUDIODRIVER:-dummy}
export SDL_VIDEODRIVER=${SDL_VIDEODRIVER:-dummy}
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export XDG_DATA_HOME="${PWD}/.xdg-data"
export XDG_CACHE_HOME="${PWD}/.xdg-cache"
export XDG_CONFIG_HOME="${PWD}/.xdg-config"

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

heartbeat() {
	while sleep "${HEARTBEAT_SECS}"; do
		printf '[check_only] heartbeat %(%Y-%m-%dT%H:%M:%S%z)T\n' -1
	done
}

run_step() {
	local label="$1"
	shift
	echo "[check_only] >>> ${label}"
	if timeout -k 10 "${STEP_TIMEOUT}" stdbuf -oL -eL "$@"; then
		echo "[check_only] <<< ${label} (ok)"
	else
		echo "[check_only] <<< ${label} (failed)" >&2
		return 1
	fi
}

overall_timeout() {
	sleep "${CHECK_ONLY_TIMEOUT}" && echo "[check_only] ERROR: overall timeout reached" >&2 && kill -TERM $$
}

overall_timeout & OT_PID=$!
HB_PID=""
cleanup() {
	[[ -n "${HB_PID}" ]] && kill "${HB_PID}" 2>/dev/null || true
	[[ -n "${OT_PID}" ]] && kill "${OT_PID}" 2>/dev/null || true
	pkill -P $$ 2>/dev/null || true
}
trap cleanup EXIT INT TERM

heartbeat & HB_PID=$!

mkdir -p "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}"

godot_bin="$(bash "${SCRIPT_DIR}/godot_resolver.sh" | tail -n1)"
export GODOT_BIN="${godot_bin}"
echo "[check_only] Using $(${GODOT_BIN} --version)"

run_step "godot_check_only" "${SCRIPT_DIR}/check_only.sh"

baseline_dir="${REPO_ROOT}/dev/screenshots/ui_baseline"
current_dir="${REPO_ROOT}/dev/screenshots/ui_current"
if [[ ! -d "${baseline_dir}" ]]; then
	echo "[check_only] Missing UI baseline directory: ${baseline_dir}" >&2
	exit 1
fi
mkdir -p "${current_dir}"
find "${current_dir}" -maxdepth 1 -type f -name '*.png' -delete
find "${current_dir}" -maxdepth 1 -type f -name '*.png.import' -delete

run_step "ui_baseline_capture" "${SCRIPT_DIR}/run_headless_godot.sh" "--output=${current_dir}"
run_step "ui_compare" "${SCRIPT_DIR}/ui_compare.sh" "${baseline_dir}" "${current_dir}"
run_step "replay_smoke" "${GODOT_BIN}" "--headless" "--path" "${REPO_ROOT}" "--script" "res://tools/replay_headless.gd" "--duration=60" "--seed=42"

echo "[check_only] all steps passed"
