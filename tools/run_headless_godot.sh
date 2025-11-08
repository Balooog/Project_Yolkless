#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${REPO_ROOT}/bin/Godot_v4.5.1-stable_linux.x86_64"
DEFAULT_OUTPUT="${REPO_ROOT}/dev/screenshots/ui_baseline"
if [[ $# -gt 0 ]]; then
	EXTRA_ARGS=("$@")
else
	EXTRA_ARGS=("--output=${DEFAULT_OUTPUT}")
fi

mkdir -p "${DEFAULT_OUTPUT}"

export XDG_DATA_HOME="${REPO_ROOT}/.xdg-data"
export XDG_CACHE_HOME="${REPO_ROOT}/.xdg-cache"
export XDG_CONFIG_HOME="${REPO_ROOT}/.xdg-config"
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/lvp_icd.x86_64.json"

run_with_vulkan() {
	echo "[run_headless] Using Vulkan (Lavapipe)"
	"${GODOT_BIN}" \
		--headless \
		--path "${REPO_ROOT}" \
		--rendering-driver vulkan \
		--script "res://tools/ui_capture_baseline.gd" \
		-- "${EXTRA_ARGS[@]}"
}

run_with_xvfb() {
	echo "[run_headless] Using OpenGL (llvmpipe via Xvfb)"
	xvfb-run -a -s "-screen 0 1280x720x24" \
		"${GODOT_BIN}" \
		--display-driver x11 \
		--rendering-driver opengl3 \
		--path "${REPO_ROOT}" \
		--script "res://tools/ui_capture_baseline.gd" \
		-- "${EXTRA_ARGS[@]}"
}

if vulkaninfo 2>/dev/null | grep -q "Lavapipe"; then
	run_with_vulkan
else
	run_with_xvfb
fi
