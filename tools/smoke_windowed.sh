#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export REPO_ROOT_OVERRIDE="${REPO_ROOT}"
source "${SCRIPT_DIR}/env_common.sh"
unset REPO_ROOT_OVERRIDE

godot_bin="$(bash "${SCRIPT_DIR}/godot_resolver.sh" | tail -n1)"
"${godot_bin}" --path "${REPO_ROOT}" --script "res://tools/quit_next_frame.gd"
