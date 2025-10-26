#!/usr/bin/env bash
set -euo pipefail

: "${GODOT_BIN:=/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEST_DIR="${PROJECT_ROOT}/dev/screenshots/ui_current"

# Resolve Godot user data path (Windows AppData equivalent)
if command -v "${GODOT_BIN}" >/dev/null 2>&1; then
	USERDATA_OUTPUT="$("${GODOT_BIN}" --headless --script - <<'GDOT' 2>/dev/null || true
extends SceneTree

func _init() -> void:
	print(ProjectSettings.globalize_path("user://"))
	quit()
GDOT
)"
else
	echo "[sync_ui_screenshots] Godot binary not found at $GODOT_BIN" >&2
	exit 1
fi

USERDATA="$(echo "$USERDATA_OUTPUT" | tr -d '\r' | tail -n 1)"
if [[ -z "$USERDATA" ]]; then
	echo "[sync_ui_screenshots] Unable to resolve Godot user data directory from $GODOT_BIN." >&2
	USERDATA=""
fi

if [[ -n "$USERDATA" ]]; then
	if command -v wslpath >/dev/null 2>&1; then
		if [[ "$USERDATA" =~ ^[A-Za-z]:[\\/].* ]]; then
			USERDATA="$(wslpath -u "$USERDATA")"
		fi
	fi
fi

# Fallback: common Windows AppData path if auto-detection failed.
if [[ -z "$USERDATA" || ! -d "${USERDATA%/}" ]]; then
	if [[ -n "${USERPROFILE:-}" ]]; then
		if command -v wslpath >/dev/null 2>&1; then
			PROFILE_PATH="$(wslpath -u "$USERPROFILE" 2>/dev/null || echo "$USERPROFILE")"
		else
			PROFILE_PATH="$USERPROFILE"
		fi
		PROFILE_CANDIDATE="${PROFILE_PATH%/}/AppData/Roaming/Godot/app_userdata/Project Yolkless"
		if [[ -d "$PROFILE_CANDIDATE" ]]; then
			USERDATA="$PROFILE_CANDIDATE"
		fi
	fi
fi

if [[ -z "$USERDATA" || ! -d "${USERDATA%/}" ]]; then
	for candidate in /mnt/c/Users/*/AppData/Roaming/Godot/app_userdata/Project\ Yolkless; do
		if [[ -d "$candidate" ]]; then
			USERDATA="$candidate"
			break
		fi
	done
fi

SOURCE_DIR="${USERDATA%/}/ui_screenshots"

if [[ ! -d "$SOURCE_DIR" ]]; then
	echo "[sync_ui_screenshots] No captured screenshots found at $SOURCE_DIR" >&2
	exit 0
fi

mkdir -p "$DEST_DIR"

echo "[sync_ui_screenshots] Copying PNGs from $SOURCE_DIR to $DEST_DIR"
find "$SOURCE_DIR" -maxdepth 1 -type f -name '*.png' -print -exec cp {} "$DEST_DIR" \;

echo "[sync_ui_screenshots] Done."
