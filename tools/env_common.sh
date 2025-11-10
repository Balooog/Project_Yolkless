#!/usr/bin/env bash

# Shared environment bootstrap for Codex scripts (run_dev, CI, smoke).
# Usage: source this file before invoking Godot so all runs share the
# repo-local Godot user data sandbox and shader-cache settings.

if [[ -z "${ENV_COMMON_DIR:-}" ]]; then
	ENV_COMMON_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
fi

if [[ -n "${REPO_ROOT_OVERRIDE:-}" ]]; then
	REPO_ROOT="${REPO_ROOT_OVERRIDE}"
	unset REPO_ROOT_OVERRIDE
else
	REPO_ROOT="$(cd "${ENV_COMMON_DIR}/.." && pwd)"
fi

export XDG_CONFIG_HOME="${REPO_ROOT}/.gduser/config"
export XDG_DATA_HOME="${REPO_ROOT}/.gduser/data"
export XDG_CACHE_HOME="${REPO_ROOT}/.gduser/cache"
export GODOT_USER_DATA_DIR="${REPO_ROOT}/.gduser"
: "${YOLKLESS_DISABLE_SHADER_CACHE:=1}"
export YOLKLESS_DISABLE_SHADER_CACHE

mkdir -p \
	"${XDG_CONFIG_HOME}" \
	"${XDG_DATA_HOME}" \
	"${XDG_CACHE_HOME}/godot/shader_cache" \
	"${GODOT_USER_DATA_DIR}/logs" \
	"${GODOT_USER_DATA_DIR}/telemetry" \
	"${GODOT_USER_DATA_DIR}/perf" \
	"${GODOT_USER_DATA_DIR}/screenshots/ui_baseline" \
	"${GODOT_USER_DATA_DIR}/screenshots/ui_current" \
	"${GODOT_USER_DATA_DIR}/cache/godot/shader_cache"
