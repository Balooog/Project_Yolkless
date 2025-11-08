#!/usr/bin/env python3
"""
Validate HUD baseline PNGs against the layout contract.

Checks:
  1. Toast region must be empty (matches background colour).
  2. All non-background pixels must live inside the safe-area rectangle.
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence, Tuple

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
EXPECTED_SIZE = (1280, 720)
SAFE_AREA = (32, 24, 1248, 696)  # left, top, right, bottom (exclusive)
TOAST_RECT = (340, 624, 600, 72)  # x, y, width, height


class BaselineError(Exception):
	"""Raised when a baseline PNG violates the layout contract."""


@dataclass(frozen=True)
class ImageData:
	width: int
	height: int
	pixels: bytearray

	def pixel(self, x: int, y: int) -> Tuple[int, int, int, int]:
		idx = (y * self.width + x) * 4
		return tuple(self.pixels[idx + channel] for channel in range(4))  # type: ignore[return-value]


def read_png_rgba(path: Path) -> ImageData:
	with path.open("rb") as handle:
		if handle.read(len(PNG_SIGNATURE)) != PNG_SIGNATURE:
			raise BaselineError("Not a PNG file.")
		width = height = None
		color_type = bit_depth = None
		compressed = bytearray()
		while True:
			raw_len = handle.read(4)
			if not raw_len:
				break
			(length,) = struct.unpack(">I", raw_len)
			chunk_type = handle.read(4)
			data = handle.read(length)
			_ = handle.read(4)  # CRC (ignored)
			if chunk_type == b"IHDR":
				width, height, bit_depth, color_type, *_rest = struct.unpack(">IIBBBBB", data)
			elif chunk_type == b"IDAT":
				compressed.extend(data)
			elif chunk_type == b"IEND":
				break
		if width is None or height is None or color_type is None or bit_depth is None:
			raise BaselineError("Missing IHDR chunk.")
		if color_type != 6 or bit_depth != 8:
			raise BaselineError("PNG must be RGBA 8-bit.")
		raw = zlib.decompress(bytes(compressed))
		bpp = 4
		stride = width * bpp
		pixels = bytearray(width * height * bpp)
		prev = bytearray(stride)
		i = 0
		pos = 0
		for _ in range(height):
			filter_type = raw[pos]
			pos += 1
			line = bytearray(raw[pos:pos + stride])
			pos += stride
			recon = _apply_filter(filter_type, line, prev, bpp)
			pixels[i:i + stride] = recon
			prev = recon
			i += stride
		return ImageData(width, height, pixels)


def _apply_filter(filter_type: int, line: bytearray, prev: bytearray, bpp: int) -> bytearray:
	if filter_type == 0:
		return line
	recon = bytearray(len(line))
	if filter_type == 1:  # Sub
		for idx, value in enumerate(line):
			left = recon[idx - bpp] if idx >= bpp else 0
			recon[idx] = (value + left) & 0xFF
	elif filter_type == 2:  # Up
		for idx, value in enumerate(line):
			up = prev[idx] if prev else 0
			recon[idx] = (value + up) & 0xFF
	elif filter_type == 3:  # Average
		for idx, value in enumerate(line):
			left = recon[idx - bpp] if idx >= bpp else 0
			up = prev[idx] if prev else 0
			recon[idx] = (value + ((left + up) // 2)) & 0xFF
	elif filter_type == 4:  # Paeth
		for idx, value in enumerate(line):
			left = recon[idx - bpp] if idx >= bpp else 0
			up = prev[idx] if prev else 0
			up_left = prev[idx - bpp] if idx >= bpp else 0
			recon[idx] = (value + _paeth(left, up, up_left)) & 0xFF
	else:
		raise BaselineError(f"Unsupported PNG filter: {filter_type}")
	return recon


def _paeth(a: int, b: int, c: int) -> int:
	p = a + b - c
	pa = abs(p - a)
	pb = abs(p - b)
	pc = abs(p - c)
	if pa <= pb and pa <= pc:
		return a
	if pb <= pc:
		return b
	return c


def assert_toast_empty(image: ImageData) -> None:
	bg = image.pixel(0, 0)
	x, y, w, h = TOAST_RECT
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if image.pixel(xx, yy) != bg:
				raise BaselineError(f"Toast rect not empty at ({xx}, {yy}).")


def assert_safe_area(image: ImageData) -> None:
	bg = image.pixel(0, 0)
	min_x, min_y = image.width, image.height
	max_x = max_y = -1
	for y in range(image.height):
		for x in range(image.width):
			if image.pixel(x, y) != bg:
				if x < min_x:
					min_x = x
				if y < min_y:
					min_y = y
				if x > max_x:
					max_x = x
				if y > max_y:
					max_y = y
	if max_x == -1 or max_y == -1:
		raise BaselineError("No HUD pixels detected.")
	left, top, right, bottom = SAFE_AREA
	if not (left <= min_x and top <= min_y and max_x < right and max_y < bottom):
		raise BaselineError(
			f"HUD dock exceeds safe area: bounds=({min_x},{min_y})-({max_x},{max_y}), "
			f"expected within ({left},{top})-({right - 1},{bottom - 1})."
	)


def validate_image(path: Path) -> None:
	image = read_png_rgba(path)
	if (image.width, image.height) != EXPECTED_SIZE:
		raise BaselineError(f"Expected 1280x720 image, found {image.width}x{image.height}.")
	assert_toast_empty(image)
	assert_safe_area(image)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
	parser = argparse.ArgumentParser(description="Validate UI baseline PNG layout.")
	parser.add_argument(
		"--images",
		default="dev/screenshots/ui_baseline",
		help="Directory containing baseline PNGs (default: %(default)s).",
	)
	return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
	args = parse_args(argv)
	root = Path(args.images).expanduser()
	if not root.is_dir():
		print(f"[ui_assert] Missing directory: {root}", file=sys.stderr)
		return 1
	pngs = sorted(root.glob("*.png"))
	if not pngs:
		print(f"[ui_assert] No PNGs found in {root}", file=sys.stderr)
		return 1
	failed = False
	for png in pngs:
		try:
			validate_image(png)
			print(f"[ui_assert] OK {png.name}")
		except BaselineError as exc:
			failed = True
			print(f"[ui_assert] {png.name}: {exc}", file=sys.stderr)
	return 1 if failed else 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv[1:]))
