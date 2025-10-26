#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INPUT_DIR="${1:-${REPO_ROOT}/reports/nightly}"
OUTPUT_PATH="${2:-${REPO_ROOT}/reports/dashboard/index.html}"

if [[ ! -d "${INPUT_DIR}" ]]; then
	echo "[generate_dashboard] Input directory not found: ${INPUT_DIR}" >&2
	exit 1
fi

mkdir -p "$(dirname "${OUTPUT_PATH}")"

python3 "${SCRIPT_DIR}/gen_dashboard.py" --input "${INPUT_DIR}" --output "${OUTPUT_PATH}"

echo "[generate_dashboard] Wrote dashboard to ${OUTPUT_PATH}"
