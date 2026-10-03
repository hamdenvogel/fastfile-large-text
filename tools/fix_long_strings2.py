# -*- coding: utf-8 -*-
"""Find and split ALL Pascal string literals > 255 elements (robust)."""
from __future__ import annotations

import re
from pathlib import Path

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")

# Match '...' atoms; '' inside is escaped quote
STR_ATOM = re.compile(r"'((?:[^']|'')*)'")


def content_len(inner: str) -> int:
    return len(inner.replace("''", "'"))


def encode_chunks(text: str, max_len: int = 200) -> str:
    if not text:
        return "''"
    parts: list[str] = []
    buf: list[str] = []
    cur = 0

    def flush() -> None:
        nonlocal cur
        parts.append("'" + "".join(buf).replace("'", "''") + "'")
        buf.clear()
        cur = 0

    for ch in text:
        if ch == "\r":
            continue
        if ch == "\n":
            if buf:
                flush()
            parts.append("#13#10")
            continue
        add = 2 if ch == "'" else 1
        # Delphi counts characters in the literal; use conservative max
        if cur + add > max_len and buf:
            flush()
        buf.append(ch)
        cur += add
    if buf:
        flush()
    return " + ".join(parts) if parts else "''"


def main() -> None:
    raw = UI18N.read_bytes()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")

    bad = []
    for m in STR_ATOM.finditer(text):
        n = content_len(m.group(1))
        if n > 255:
            bad.append((m.start(), m.end(), m.group(1), n))

    print(f"found {len(bad)} overlong", flush=True)
    for start, end, inner, n in bad:
        # line number
        line = text.count("\n", 0, start) + 1
        preview = inner[:50].encode("ascii", "backslashreplace").decode()
        print(f"  L{line} len={n}: {preview}", flush=True)

    for start, end, inner, n in reversed(bad):
        decoded = inner.replace("''", "'")
        # Keep literal backslash-n as two chars if present as \\n in decoded... 
        # decoded from Pascal already has single \n meaning backslash+n if source was \n
        text = text[:start] + encode_chunks(decoded, max_len=200) + text[end:]

    bad2 = [m for m in STR_ATOM.finditer(text) if content_len(m.group(1)) > 255]
    print(f"remaining {len(bad2)}", flush=True)

    out = text.encode("utf-8")
    if bom:
        out = b"\xef\xbb\xbf" + out
    UI18N.write_bytes(out)
    print("wrote", flush=True)


if __name__ == "__main__":
    main()
