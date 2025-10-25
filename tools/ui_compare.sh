#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
	echo "Usage: $0 <baseline_dir> <current_dir>"
	exit 1
fi

BASELINE_DIR="$1"
CURRENT_DIR="$2"
DIFF_COUNT=0

for base_img in "${BASELINE_DIR}"/*.png; do
	filename="$(basename "${base_img}")"
	current_img="${CURRENT_DIR}/${filename}"
	if [[ ! -f "${current_img}" ]]; then
		echo "[ui_compare] missing image in current set: ${filename}"
		((DIFF_COUNT++))
		continue
	fi
	if ! cmp -s "${base_img}" "${current_img}"; then
		echo "[ui_compare] pixel delta detected for ${filename}"
		((DIFF_COUNT++))
	fi
done

if [[ ${DIFF_COUNT} -gt 0 ]]; then
	echo "[ui_compare] ${DIFF_COUNT} file(s) differ from baseline (threshold policy to be refined in PX-010.9)."
	exit 1
fi

echo "[ui_compare] screenshots match baseline."
