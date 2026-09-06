#!/usr/bin/env python3
"""Fail when a local QML text sink is not explicitly PlainText."""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SINK = re.compile(r"\b(Text|Label|TextEdit|StyledText)\s*\{")


def object_end(source, start):
    depth = 1
    index = start
    while index < len(source) and depth:
        depth += source[index] == "{"
        depth -= source[index] == "}"
        index += 1
    return index if depth == 0 else None


def has_direct_plain_text_format(body):
    depth = 0
    direct = []
    for char in body:
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        elif depth == 0:
            direct.append(char)
    return re.search(r"\btextFormat\s*:\s*Text\.PlainText\b", "".join(direct)) is not None


def main():
    missing = []
    for path in sorted(ROOT.rglob("*.qml")):
        source = path.read_text(encoding="utf-8")
        for match in SINK.finditer(source):
            end = object_end(source, match.end())
            body = source[match.end():end] if end else ""
            if not has_direct_plain_text_format(body):
                line = source.count("\n", 0, match.start()) + 1
                missing.append(f"MISSING {path.relative_to(ROOT)}:{line} ({match.group(1)})")
    if missing:
        print("\n".join(missing), file=sys.stderr)
        return 1
    print("QML text-format audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
