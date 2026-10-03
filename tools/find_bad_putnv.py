# -*- coding: utf-8 -*-
"""Find PutNV lines that don't parse as a complete Delphi call."""
from pathlib import Path

path = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
text = path.read_text(encoding="utf-8")
lines = text.splitlines()


def parse_putnv(line: str) -> str | None:
    """Return None if OK, else error message."""
    idx = line.find("PutNV(")
    if idx < 0:
        return None
    i = idx + len("PutNV(")
    depth = 1
    in_str = False
    n = len(line)
    while i < n:
        ch = line[i]
        if in_str:
            if ch == "'":
                # Delphi: '' is escaped quote; ' # starts end of fragment
                if i + 1 < n and line[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
                i += 1
                continue
            i += 1
            continue
        # not in string
        if ch == "'":
            in_str = True
            i += 1
            continue
        if ch == "(":
            depth += 1
            i += 1
            continue
        if ch == ")":
            depth -= 1
            i += 1
            if depth == 0:
                # rest should be ; and optional whitespace/comment
                rest = line[i:].strip()
                if rest == ";" or rest.startswith(";"):
                    # anything after ; besides whitespace/comment is bad
                    after = rest[1:].strip()
                    if after and not after.startswith("//") and not after.startswith("{"):
                        return f"junk after PutNV: {after[:60]!r}"
                    return None
                return f"expected ; after PutNV, got {rest[:40]!r}"
            continue
        if ch == ";":
            return f"bare ; at depth {depth} pos {i}: ...{line[max(0,i-30):i+30]!r}"
        i += 1
    if in_str:
        return "unterminated string"
    if depth:
        return f"unclosed PutNV depth={depth}"
    return None


bad = []
for n, line in enumerate(lines, 1):
    if "PutNV(" not in line:
        continue
    err = parse_putnv(line)
    if err:
        bad.append((n, err, line[:180]))

print(f"bad_count={len(bad)}")
for n, err, preview in bad[:80]:
    print(f"{n}: {err}")
    print(f"   {preview}")
