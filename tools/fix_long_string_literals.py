# -*- coding: utf-8 -*-
"""Split Delphi string literals longer than 255 chars in uI18n.pas."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
MAX_LEN = 240


def decode_pascal_literal(inner: str) -> str:
    return inner.replace("''", "'")


def encode_pascal_literal(plain: str) -> str:
    return "'" + plain.replace("'", "''") + "'"


def split_plain(plain: str, max_len: int = MAX_LEN) -> str:
    if len(plain) <= max_len:
        return encode_pascal_literal(plain)
    parts = []
    while plain:
        parts.append(encode_pascal_literal(plain[:max_len]))
        plain = plain[max_len:]
    return " +\n      ".join(parts)


def process_line(line: str) -> tuple[str, int]:
    """Rewrite long '...' segments; return (newline, fixes)."""
    if "'" not in line:
        return line, 0
    out = []
    i = 0
    fixes = 0
    n = len(line)
    while i < n:
        if line[i] != "'":
            out.append(line[i])
            i += 1
            continue
        # parse literal
        i += 1
        buf = []
        while i < n:
            if line[i] == "'":
                if i + 1 < n and line[i + 1] == "'":
                    buf.append("'")
                    i += 2
                    continue
                break
            buf.append(line[i])
            i += 1
        plain = "".join(buf)
        if i < n and line[i] == "'":
            i += 1
        if len(plain) > 255:
            out.append(split_plain(plain))
            fixes += 1
        else:
            out.append(encode_pascal_literal(plain))
    return "".join(out), fixes


def main() -> None:
    raw = ROOT.read_bytes()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    nl = "\r\n" if "\r\n" in text else "\n"
    lines = text.replace("\r\n", "\n").split("\n")
    total = 0
    for idx, line in enumerate(lines):
        new_line, fixes = process_line(line)
        if fixes:
            print(f"line {idx + 1}: split {fixes} literal(s), was too long")
            lines[idx] = new_line
            total += fixes
    out = nl.join(lines)
    if text.endswith("\n") and not out.endswith("\n"):
        out += nl
    data = out.encode("utf-8")
    if bom:
        data = b"\xef\xbb\xbf" + data
    ROOT.write_bytes(data)
    print(f"Done. Fixed {total} literals.")

    # verify no segment > 255
    text2 = ROOT.read_text(encoding="utf-8-sig")
    bad = 0
    for li, line in enumerate(text2.splitlines(), 1):
        i = 0
        while i < len(line):
            if line[i] != "'":
                i += 1
                continue
            i += 1
            buf = []
            while i < len(line):
                if line[i] == "'":
                    if i + 1 < len(line) and line[i + 1] == "'":
                        buf.append("'")
                        i += 2
                        continue
                    break
                buf.append(line[i])
                i += 1
            if i < len(line) and line[i] == "'":
                i += 1
            if len(buf) > 255:
                bad += 1
                print(f"STILL BAD line {li} len={len(buf)}")
    print(f"Remaining bad segments: {bad}")


if __name__ == "__main__":
    main()
