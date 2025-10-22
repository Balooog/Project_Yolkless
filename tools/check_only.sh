#!/usr/bin/env bash
set -euo pipefail

export PATH="/snap/bin:$PATH"

mkdir -p logs
godot4 --headless --verbose --path . --check-only project.godot 2>&1 | tee logs/godot-check.log
