#!/usr/bin/env bash
set -euo pipefail

: "${VK_ICD_FILENAMES:=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json}"
export VK_ICD_FILENAMES

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${GODOT_BIN:-}" ]] || [[ ! -x "${GODOT_BIN:-}" ]]; then
	GODOT_BIN="$(bash "${ROOT_DIR}/tools/godot_resolver.sh")"
	export GODOT_BIN
fi

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "[nightly_replay] Godot binary not found at $GODOT_BIN" >&2
	exit 1
fi
REPORT_ROOT="$ROOT_DIR/reports/nightly"
STAMP="${NIGHTLY_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
RUN_DIR="$REPORT_ROOT/$STAMP"
mkdir -p "$RUN_DIR"

DURATION="${DURATION:-300}"
SEED="${SEED:-42}"
STRATEGY="${STRATEGY:-normal}"
ENV_RENDERER_MODE="${ENV_RENDERER:-}"
ECONOMY_AMORTIZE="${ECONOMY_AMORTIZE_SHIPMENT:-}"

RUN_LOG="$RUN_DIR/headless.log"
SUMMARY_JSON="$RUN_DIR/summary.json"

pushd "$ROOT_DIR" >/dev/null
{
  ARGS=("--headless" "--path" "$ROOT_DIR" "--script" "res://tools/replay_headless.gd" "--duration=$DURATION" "--seed=$SEED" "--strategy=$STRATEGY")
  if [[ -n "$ENV_RENDERER_MODE" ]]; then
    ARGS+=("--env_renderer=$ENV_RENDERER_MODE")
  fi
  if [[ -n "$ECONOMY_AMORTIZE" ]]; then
    ARGS+=("--economy_amortize_shipment=$ECONOMY_AMORTIZE")
  fi
  "$GODOT_BIN" "${ARGS[@]}" 2>&1 | tee "$RUN_LOG"
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
