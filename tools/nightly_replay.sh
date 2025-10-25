#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
REPORT_ROOT="$ROOT_DIR/reports/nightly"
STAMP="${NIGHTLY_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
RUN_DIR="$REPORT_ROOT/$STAMP"
mkdir -p "$RUN_DIR"

GODOT_BIN="${GODOT_BIN:-godot4}"
DURATION="${DURATION:-300}"
SEED="${SEED:-42}"
STRATEGY="${STRATEGY:-normal}"

RUN_LOG="$RUN_DIR/headless.log"
SUMMARY_JSON="$RUN_DIR/summary.json"

pushd "$ROOT_DIR" >/dev/null
{
  "$GODOT_BIN" --headless --path "$ROOT_DIR" --script res://tools/replay_headless.gd --duration="$DURATION" --seed="$SEED" --strategy="$STRATEGY" 2>&1 | tee "$RUN_LOG"
} || true
popd >/dev/null

if [[ -s "$RUN_LOG" ]]; then
  tail -n 1 "$RUN_LOG" > "$SUMMARY_JSON"
fi

APPDATA_DIR="$HOME/.local/share/godot/app_userdata/Project Yolkless"
PERF_DIR="$APPDATA_DIR/logs/perf"
TELEMETRY_DIR="$APPDATA_DIR/logs/telemetry"

if [[ -d "$PERF_DIR" ]]; then
  find "$PERF_DIR" -maxdepth 1 -type f -name 'tick_*.csv' -newermt '-1 minute' -exec cp {} "$RUN_DIR" \;
fi

if [[ -d "$TELEMETRY_DIR" ]]; then
  find "$TELEMETRY_DIR" -maxdepth 1 -type f -name 'replay_*.json' -newermt '-1 minute' -exec cp {} "$RUN_DIR" \;
fi

if command -v jq >/dev/null 2>&1 && [[ -s "$SUMMARY_JSON" ]]; then
  jq '.' "$SUMMARY_JSON" > "$RUN_DIR/summary.pretty.json"
fi

echo "Nightly replay artifacts stored under $RUN_DIR"
