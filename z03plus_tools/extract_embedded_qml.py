#!/usr/bin/env python3
"""Recover readable QML/JS source blocks embedded in a Qt application ELF.

Z03 stores its QML in the executable's Qt resource data.  This conservative
extractor does not alter the executable: it writes every NUL-delimited textual
block beginning with a QML/JS marker, plus an index for manual reconstruction.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

MARKERS = (b"import QtQuick", b"pragma Singleton", b".import QtQuick", b"//import QtQuick")


def printable_ratio(block: bytes) -> float:
    allowed = sum(b in (9, 10, 13) or 32 <= b < 127 or b >= 0x80 for b in block)
    return allowed / len(block) if block else 0.0


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("elf", type=Path)
    ap.add_argument("output", type=Path)
    args = ap.parse_args()

    data = args.elf.read_bytes()
    args.output.mkdir(parents=True, exist_ok=True)
    blocks: list[dict[str, object]] = []

    # Qt resources contain UTF-8 text separated by non-text/zero metadata.
    for offset, raw in enumerate(data.split(b"\0")):
        # Recover the true file offset without repeatedly searching identical data.
        pass

    start = 0
    block_id = 0
    while start < len(data):
        end = data.find(b"\0", start)
        if end < 0:
            end = len(data)
        raw = data[start:end]
        marker = next((m for m in MARKERS if m in raw), None)
        if marker and len(raw) >= 100 and printable_ratio(raw) >= 0.92:
            marker_at = raw.index(marker)
            text = raw[marker_at:].decode("utf-8", errors="replace")
            digest = hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]
            path = args.output / f"qml_{block_id:03d}_{start + marker_at:08x}_{digest}.qml.txt"
            path.write_text(text, encoding="utf-8")
            blocks.append({
                "id": block_id,
                "offset": f"0x{start + marker_at:x}",
                "size": len(text.encode("utf-8")),
                "file": path.name,
                "first_line": text.splitlines()[0] if text.splitlines() else "",
                "contains_settings": any(x in text.lower() for x in ("zybset", "setdebug", "settings", "setmodel")),
            })
            block_id += 1
        start = end + 1

    (args.output / "index.json").write_text(json.dumps(blocks, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Extracted {len(blocks)} QML-like blocks to {args.output}")


if __name__ == "__main__":
    main()
