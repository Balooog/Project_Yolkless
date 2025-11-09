#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -z "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh" | tail -n1)"
fi

echo "[localization] exporting POT via ${GODOT_BIN}"
"${GODOT_BIN}" --headless --path "${REPO_ROOT}" --script "res://tools/export_strings.gd" --output "res://i18n/strings.pot"

if ! git -C "${REPO_ROOT}" diff --quiet -- i18n/strings.pot; then
	echo "[localization] strings.pot drift detected. Run tools/export_strings.gd and commit the result." >&2
	git -C "${REPO_ROOT}" --no-pager diff --stat -- i18n/strings.pot >&2 || true
	exit 1
fi

echo "[localization] POT in sync"
