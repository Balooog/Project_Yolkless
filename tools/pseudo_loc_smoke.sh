#!/usr/bin/env bash
set -Eeuo pipefail

: "${PSEUDO_LOC:=1}"
: "${PSEUDO_LOC_SCENE:=res://scenes/ui_smoke/MainHUD.tscn}"
: "${PSEUDO_LOC_OUTPUT:=dev/screenshots/ui_pseudo_loc}"

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export PSEUDO_LOC

if [[ -z "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh" | tail -n1)"
fi

OUTPUT_DIR="${REPO_ROOT}/${PSEUDO_LOC_OUTPUT}"
mkdir -p "${OUTPUT_DIR}"
find "${OUTPUT_DIR}" -maxdepth 1 -type f \( -name '*.png' -o -name '*.png.import' \) -delete

echo "[pseudo-loc] linting ${PSEUDO_LOC_SCENE}"
timeout 120 "${GODOT_BIN}" --headless --path "${REPO_ROOT}" --script "res://tools/uilint_scene.gd" -- "${PSEUDO_LOC_SCENE}"

echo "[pseudo-loc] capturing viewport matrix to ${OUTPUT_DIR}"
"${SCRIPT_DIR}/ui_viewport_matrix.sh" --out-dir="${OUTPUT_DIR}" --scenes="${PSEUDO_LOC_SCENE}" --no-viewport-suffix

echo "[pseudo-loc] completed"
