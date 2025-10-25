#!/usr/bin/env bash
set -euo pipefail

if output="$(/usr/bin/env bash tools/bootstrap_godot.sh)"; then
    eval "$output"
else
    echo "[ci] Bootstrap failed; skipping check_only." >&2
    exit 0
fi
export GODOT_BIN
echo "[ci] Using $("$GODOT_BIN" --version)"

if ./tools/check_only.sh; then
    echo "✅ Check passed"
else
    echo "❌ Check failed"
    exit 1
fi
