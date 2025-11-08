#!/usr/bin/env python3
"""
Generate placeholder HUD baseline PNGs that match the documentation spec.

The generator writes four deterministic 1280x720 RGBA images:
  - hud_blank_reference.png
  - hud_power_normal.png
  - hud_power_warning.png
  - hud_power_critical.png

Each image renders safe-area guides and slot blocks for the HUD dock.
"""

from __future__ import annotations

import argparse
import os
import struct
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Tuple

WIDTH = 1280
HEIGHT = 720


@dataclass(frozen=True)
class Rect:
	x: int
	y: int
	w: int
	h: int

	@property
	def x1(self) -> int:
		return self.x + self.w

	@property
	def y1(self) -> int:
		return self.y + self.h


def hex_rgba(value: str) -> Tuple[int, int, int, int]:
	value = value.strip()
	if value.startswith("#") and len(value) in (7, 9):
		value = value[1:]
	if value.lower().startswith("rgba"):
		parts = value[value.find("(") + 1:value.find(")")].split(",")
		r, g, b = (int(parts[i]) for i in range(3))
		a = int(float(parts[3]) * 255) if "." in parts[3] else int(parts[3])
		return r, g, b, a
	if len(value) == 6:
		value += "FF"
	if len(value) != 8:
		raise ValueError(f"Unsupported color token: {value}")
	r = int(value[0:2], 16)
	g = int(value[2:4], 16)
	b = int(value[4:6], 16)
	a = int(value[6:8], 16)
	return r, g, b, a


def draw_rect(pixels: bytearray, rect: Rect, color: Tuple[int, int, int, int]) -> None:
	r, g, b, a = color
	for yy in range(rect.y, rect.y1):
		row_offset = (yy * WIDTH + rect.x) * 4
		for xx in range(rect.w):
			idx = row_offset + xx * 4
			pixels[idx] = r
			pixels[idx + 1] = g
			pixels[idx + 2] = b
			pixels[idx + 3] = a


def draw_border(pixels: bytearray, rect: Rect, color: Tuple[int, int, int, int], thickness: int = 1) -> None:
	top = Rect(rect.x, rect.y, rect.w, thickness)
	bottom = Rect(rect.x, rect.y1 - thickness, rect.w, thickness)
	left = Rect(rect.x, rect.y, thickness, rect.h)
	right = Rect(rect.x1 - thickness, rect.y, thickness, rect.h)
	for band in (top, bottom, left, right):
		draw_rect(pixels, band, color)


def blend_color(base: Tuple[int, int, int, int], mix: Tuple[int, int, int, int], weight: float) -> Tuple[int, int, int, int]:
	r = int(base[0] * (1 - weight) + mix[0] * weight)
	g = int(base[1] * (1 - weight) + mix[1] * weight)
	b = int(base[2] * (1 - weight) + mix[2] * weight)
	a = int(base[3] * (1 - weight) + mix[3] * weight)
	return r, g, b, a


def write_png(path: Path, pixels: bytearray) -> None:
	def chunk(tag: bytes, data: bytes) -> bytes:
		return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

	raw = bytearray()
	for row in range(HEIGHT):
		raw.append(0)  # filter type 0
		offset = row * WIDTH * 4
		raw.extend(pixels[offset:offset + WIDTH * 4])

	with path.open("wb") as handle:
		handle.write(b"\x89PNG\r\n\x1a\n")
		handle.write(chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 6, 0, 0, 0)))
		handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), level=9)))
		handle.write(chunk(b"IEND", b""))


def base_canvas() -> bytearray:
	bg = hex_rgba("#14181F")
	pixels = bytearray([bg[0], bg[1], bg[2], bg[3]] * WIDTH * HEIGHT)

	hud_dock = Rect(928, 24, 288, 128)
	draw_border(pixels, hud_dock, hex_rgba("#2A3038FF"), thickness=1)

	return pixels


def draw_slot_block(pixels: bytearray, rect: Rect, accent: Tuple[int, int, int, int], active: bool) -> None:
	fill = blend_color(hex_rgba("#1D222AFF"), accent, 0.08 if active else 0.0)
	border = blend_color(accent, hex_rgba("#0F1318FF"), 0.6)
	draw_rect(pixels, rect, fill)
	draw_border(pixels, rect, border, thickness=1)

	icon_size = rect.h - 12
	icon_rect = Rect(rect.x + 10, rect.y + 6, icon_size, icon_size)
	icon_color = blend_color(accent, hex_rgba("#0F1318FF"), 0.3)
	draw_rect(pixels, icon_rect, icon_color)

	text_bar_rect = Rect(rect.x + icon_size + 16, rect.y + rect.h - 6, rect.w - icon_size - 24, 4)
	text_color = blend_color(accent, hex_rgba("#FFFFFF80"), 0.5)
	draw_rect(pixels, text_bar_rect, text_color)


def create_blank_reference() -> bytearray:
	pixels = base_canvas()
	slot_outline = hex_rgba("#2F363FFF")
	for rect in SLOT_RECTS:
		draw_border(pixels, rect, slot_outline, thickness=1)
	return pixels


def create_power_variant(accent: Tuple[int, int, int, int]) -> bytearray:
	pixels = base_canvas()
	normal = hex_rgba("#FFFFFFFF")
	for rect in SLOT_RECTS[1:]:
		draw_slot_block(pixels, rect, normal, active=True)
	draw_slot_block(pixels, SLOT_RECTS[0], accent, active=True)
	return pixels


SLOT_RECTS = [
	Rect(992, 24, 224, 32),   # A: power
	Rect(992, 64, 224, 32),   # B: economy
	Rect(992, 104, 224, 32),  # C: population
]


def generate(output_dir: Path) -> None:
	output_dir.mkdir(parents=True, exist_ok=True)
	for png in output_dir.glob("*.png"):
		png.unlink()

	images = {
		"hud_blank_reference.png": create_blank_reference(),
		"hud_power_normal.png": create_power_variant(hex_rgba("#FFFFFFFF")),
		"hud_power_warning.png": create_power_variant(hex_rgba("#FFB300FF")),
		"hud_power_critical.png": create_power_variant(hex_rgba("#FF1744FF")),
	}

	for name, pixels in images.items():
		write_png(output_dir / name, pixels)


def parse_args(argv: Iterable[str]) -> argparse.Namespace:
	parser = argparse.ArgumentParser(description="Generate placeholder HUD baseline PNGs.")
	parser.add_argument("--output", "-o", required=True, help="Directory to populate with baseline PNGs.")
	return parser.parse_args(argv)


def main() -> int:
	args = parse_args(os.sys.argv[1:])
	output_path = Path(args.output).expanduser()
	if not output_path.is_absolute():
		output_path = (Path.cwd() / output_path).resolve()
	generate(output_path)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
