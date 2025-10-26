#!/usr/bin/env bash
set -euo pipefail

TARGET_BIN="/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe"

if [[ ! -f "$TARGET_BIN" ]]; then
    echo "[bootstrap] Expected Godot binary at $TARGET_BIN" >&2
    echo "[bootstrap] Install the Windows console build and retry." >&2
    exit 1
fi

echo "GODOT_BIN=${TARGET_BIN}"
