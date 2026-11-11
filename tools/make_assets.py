#!/usr/bin/env python3
"""Flat paper-cut app icon and a static paper texture. No third-party art."""
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "LittlePandaChinese/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
PAPER = ROOT / "LittlePandaChinese/Resources/Assets.xcassets/PaperTexture.imageset/paper.png"


def write_png(path: Path, width: int, height: int, rgb) -> None:
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        row = bytearray()
        for x in range(width):
            row.extend(rgb(x, y))
        raw.extend(row)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def inside(x, y, cx, cy, rx, ry) -> bool:
    dx = (x - cx) / rx
    dy = (y - cy) / ry
    return dx * dx + dy * dy <= 1


def icon(x, y):
    paper = (246, 232, 204)
    ink = (42, 30, 22)
    white = (255, 250, 242)
    blush = (244, 140, 132)
    # bamboo
    if inside(x, y, 170, 430, 28, 210) or inside(x, y, 250, 390, 22, 180):
        return (63, 140, 78)
    if inside(x, y, 120, 300, 70, 28) or inside(x, y, 210, 250, 64, 24):
        return (47, 122, 68)
    # ears
    if inside(x, y, 360, 300, 78, 78) or inside(x, y, 664, 300, 78, 78):
        return ink
    # body
    if inside(x, y, 512, 760, 210, 150):
        return white
    # arms
    if inside(x, y, 330, 740, 70, 40) or inside(x, y, 694, 740, 70, 40):
        return ink
    # head
    if inside(x, y, 512, 470, 230, 230):
        # eye patches
        if inside(x, y, 430, 470, 78, 62) or inside(x, y, 594, 470, 78, 62):
            if inside(x, y, 438, 458, 22, 22) or inside(x, y, 608, 458, 22, 22):
                return white
            return ink
        if inside(x, y, 512, 545, 28, 18):
            return ink
        dx = x - 512
        dy = y - 610
        if (dx * dx) / (46 * 46) + (dy * dy) / (28 * 28) <= 1 and y >= 610 and (dx * dx) / (34 * 34) + (dy * dy) / (16 * 16) >= 1:
            return ink
        if inside(x, y, 400, 540, 28, 22) or inside(x, y, 624, 540, 28, 22):
            return blush
        return white
    # head outline band
    if inside(x, y, 512, 470, 246, 246) and not inside(x, y, 512, 470, 230, 230):
        return ink
    if inside(x, y, 512, 760, 226, 166) and not inside(x, y, 512, 760, 210, 150):
        return ink
    return paper


def paper_pixel(x, y):
    n = (x * 374761393 + y * 668265263) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    grain = (n >> 24) & 255
    value = 236 + (grain % 18)
    if (x * 3 + y * 5) % 53 == 0:
        value -= 28
    if (x + y * 2) % 97 == 0:
        value -= 16
    value = max(180, min(255, value))
    return (value, max(0, value - 4), max(0, value - 12))


if __name__ == "__main__":
    write_png(ICON, 1024, 1024, icon)
    write_png(PAPER, 256, 256, paper_pixel)
    print(ICON, ICON.stat().st_size)
    print(PAPER, PAPER.stat().st_size)
