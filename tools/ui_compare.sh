#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
	echo "Usage: $0 <baseline_dir> <current_dir>"
	exit 1
fi

BASELINE_DIR="$1"
CURRENT_DIR="$2"
RMS_THRESHOLD="${UI_RMS_THRESH:-0.02}"

python3 - "$BASELINE_DIR" "$CURRENT_DIR" "$RMS_THRESHOLD" <<'PY'
import os
import sys
from PIL import Image, ImageChops, ImageStat

base_dir, current_dir, threshold = sys.argv[1], sys.argv[2], float(sys.argv[3])
failures = []

def rms_normalized(img_a: Image.Image, img_b: Image.Image) -> float:
	diff = ImageChops.difference(img_a, img_b).convert("RGB")
	stat = ImageStat.Stat(diff)
	return sum(value / 255.0 for value in stat.rms) / len(stat.rms)

for filename in sorted(name for name in os.listdir(base_dir) if name.lower().endswith(".png")):
	base_path = os.path.join(base_dir, filename)
	curr_path = os.path.join(current_dir, filename)
	if not os.path.exists(curr_path):
		print(f"[ui_compare] missing image in current set: {filename}")
		failures.append(filename)
		continue
	base_img = Image.open(base_path).convert("RGBA")
	curr_img = Image.open(curr_path).convert("RGBA")
	if base_img.size != curr_img.size:
		print(f"[ui_compare] size mismatch for {filename}: {base_img.size} vs {curr_img.size}")
		failures.append(filename)
		continue
	score = rms_normalized(base_img, curr_img)
	if score > threshold:
		print(f"[ui_compare] FAIL {filename}: rms={score:.4f} > {threshold}")
		failures.append(filename)
	else:
		print(f"[ui_compare] OK   {filename}: rms={score:.4f} ≤ {threshold}")

if failures:
	print(f"[ui_compare] {len(failures)} file(s) exceeded RMS threshold {threshold}.")
	sys.exit(1)

print(f"[ui_compare] All screenshots within RMS threshold ≤ {threshold}.")
PY
