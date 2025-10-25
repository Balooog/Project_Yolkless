#!/usr/bin/env bash
set -euo pipefail

GODOT_VER="${GODOT_VER:-4.2.2}"
LIN_NAME="Godot_v${GODOT_VER}-stable_linux.x86_64"
BIN_DIR="${BIN_DIR:-./bin}"
BIN_PATH="${BIN_DIR}/${LIN_NAME}"

mkdir -p "$BIN_DIR"
if [[ ! -x "$BIN_PATH" ]]; then
    ZIP_PATH="${BIN_PATH}.zip"
    if [[ -f "$ZIP_PATH" ]]; then
        if ! command -v unzip >/dev/null 2>&1; then
            echo "[bootstrap] unzip not available; install it or extract $ZIP_PATH manually." >&2
            exit 1
        fi
        echo "[bootstrap] Extracting Godot archive from ${ZIP_PATH}..." >&2
        unzip -q -o "$ZIP_PATH" -d "$BIN_DIR"
        chmod +x "$BIN_PATH"
    else
        echo "[bootstrap] Expected archive $ZIP_PATH not present." >&2
        echo "[bootstrap] Download https://github.com/godotengine/godot/releases/download/${GODOT_VER}-stable/${LIN_NAME}.zip" >&2
        exit 1
    fi
fi

chmod +x "$BIN_PATH"

echo "GODOT_BIN=${BIN_PATH}"
