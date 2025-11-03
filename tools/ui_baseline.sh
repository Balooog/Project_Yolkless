#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${1:-}" 

if [[ -n "${OUTPUT_DIR}" ]]; then
	ABS_OUT="${OUTPUT_DIR}"
	if [[ "${ABS_OUT}" != /* ]]; then
		ABS_OUT="$(cd "${REPO_ROOT}" && python3 - "$ABS_OUT" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).resolve())
PY
)"
	fi
	echo "[ui_baseline] generating baseline into ${ABS_OUT}"
	"${SCRIPT_DIR}/ui_viewport_matrix.sh" --out-dir="${ABS_OUT}"
else
	echo "[ui_baseline] generating baseline into ${REPO_ROOT}/dev/screenshots/ui_baseline"
	"${SCRIPT_DIR}/ui_viewport_matrix.sh" --baseline
fi
