#!/usr/bin/env bash
set -euo pipefail

# Allow overriding the Godot binary (default to Godot CLI in PATH)
GODOT_BIN="${GODOT_BIN:-godot4}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "[check_only] godot binary not found: $GODOT_BIN" >&2
  exit 1
fi

mkdir -p logs

# Validate TSV schemas before running Godot check-only.
python3 tools/validate_tables.py --tables=data/upgrade.tsv,data/research.tsv,data/environment_profiles.tsv,data/materials.tsv --schema=docs/data/Schemas.md

# Guard against hangs: disable remote debugger socket and add an optional timeout.
TIMEOUT_SECS="${CHECK_ONLY_TIMEOUT:-300}"
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout ${TIMEOUT_SECS}"
fi

version_info="$($GODOT_BIN --version 2>&1)"
printf '[check_only] Using %s (%s)\n' "$GODOT_BIN" "$version_info"
set +e
$TIMEOUT_BIN "$GODOT_BIN" \
  --headless \
  --editor-remote-port 0 \
  --path . \
  --check-only project.godot \
  --quit \
  --verbose 2>&1 | tee logs/godot-check.log
exit_code=${PIPESTATUS[0]}
set -e

if [ "$exit_code" -ne 0 ]; then
  echo "[check_only] godot exited with status ${exit_code}. See logs/godot-check.log for details." >&2
  exit "$exit_code"
fi

echo "[check_only] Completed successfully."
