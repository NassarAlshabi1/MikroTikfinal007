#!/usr/bin/env python3
"""Make generated Isar schema IDs safe for Dart Web/JavaScript builds.

Isar uses signed 64-bit hashes for collection and index IDs. Dart Web cannot
represent some of those integer literals exactly in JavaScript, even though
the same IDs are valid on the VM. This script is intentionally run only in the
Web CI job after code generation; native builds keep the original IDs.
"""

from __future__ import annotations

import hashlib
import re
from pathlib import Path

MAX_SAFE_JS_INTEGER = 9_007_199_254_740_991
ID_PATTERN = re.compile(r"(?P<prefix>\bid\s*:\s*)(?P<value>-?\d{16,})(?P<suffix>\b)")


def safe_id(original: int) -> int:
    """Return a deterministic non-zero signed 31-bit ID."""
    digest = hashlib.sha256(str(original).encode("ascii")).digest()
    value = int.from_bytes(digest[:4], "big") & 0x7FFFFFFF
    return value or 1


def patch_file(path: Path) -> int:
    source = path.read_text(encoding="utf-8")
    used: set[int] = set()
    replacements = 0

    def replace(match: re.Match[str]) -> str:
        nonlocal replacements
        original = int(match.group("value"))
        if abs(original) <= MAX_SAFE_JS_INTEGER:
            used.add(original)
            return match.group(0)

        replacement = safe_id(original)
        while replacement in used:
            replacement += 1
            if replacement > 0x7FFFFFFF:
                replacement = 1
        used.add(replacement)
        replacements += 1
        return f"{match.group('prefix')}{replacement}{match.group('suffix')}"

    patched = ID_PATTERN.sub(replace, source)
    if replacements:
        path.write_text(patched, encoding="utf-8")
    return replacements


def main() -> None:
    total = 0
    for path in sorted(Path("lib").rglob("*.g.dart")):
        total += patch_file(path)
    print(f"Patched {total} JavaScript-unsafe Isar schema IDs for Web build")


if __name__ == "__main__":
    main()
