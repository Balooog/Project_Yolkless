#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GODOT_BIN="$(bash "${SCRIPT_DIR}/godot_resolver.sh")"
export GODOT_BIN

echo "[ci] Using $("$GODOT_BIN" --version)"

if "${SCRIPT_DIR}/check_only.sh"; then
	echo "✅ Check passed"
else
	echo "❌ Check failed"
	exit 1
fi
