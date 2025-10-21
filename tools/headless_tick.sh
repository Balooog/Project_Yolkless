#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <seconds>" >&2
  exit 1
fi
SECONDS_TO_SIM="$1"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/.."
echo "Headless tick not yet wired into runtime; invoke in-editor offline grant instead."
echo "Requested seconds: $SECONDS_TO_SIM"
