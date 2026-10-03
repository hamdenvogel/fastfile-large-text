# -*- coding: utf-8 -*-
"""Find juxtaposed string chains (#13#10 without +) whose total chars > 255."""
from __future__ import annotations

import re
from pathlib import Path

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")

# Pattern: '...'#13#10'...'  (juxtaposition, no + between)
# Find sequences of string + optional #codes + string without +
JUXT = re.compile(
    r"('(?:[^']|'')*')"
    r"((?:#\d+)+)"
    r"('(?:[^']|'')*')"
)


def main() -> None:
    text = UI18N.read_text(encoding="utf-8-sig")
    # Find all places with '#13#10''  (char codes then immediately another string)
    # without + in between
    bad = []
    for m in re.finditer(r"('(?:[^']|'')*'(?:#\d+)+)+'(?:[^']|'')*'", text):
        chunk = m.group(0)
        if " + " in chunk or "+\n" in chunk or "+ " in chunk:
            continue
        # only juxtaposition
        if "+" in chunk:
            continue
        # decode approximate length of string contents
        parts = re.findall(r"'((?:[^']|'')*)'", chunk)
        total = sum(len(p.replace("''", "'")) for p in parts)
        # plus newlines for each #13#10 pair roughly
        n_nl = chunk.count("#13")
        total_with_nl = total + n_nl  # approx
        if total_with_nl > 255:
            line = text.count("\n", 0, m.start()) + 1
            bad.append((line, total_with_nl, chunk[:80].encode("ascii", "backslashreplace").decode()))

    print(f"juxtaposition chains >255: {len(bad)}")
    for line, n, prev in bad[:40]:
        print(f"  L{line} ~{n}: {prev}")

    # Auto-fix: insert ' + ' before each ' that follows #digits
    # Only for lines that are pure juxtaposition overlong
    if not bad:
        return

    def fix_juxt(s: str) -> str:
        # Replace #13#10' with #13#10 + '  and similar for any #n sequence before '
        return re.sub(r"((?:#\d+)+)'", r"\1 + '", s)

    # Apply only to matches that are overlong juxtaposition
    out = []
    pos = 0
    fixed = 0
    for m in re.finditer(r"('(?:[^']|'')*'(?:#\d+)+)+'(?:[^']|'')*'", text):
        chunk = m.group(0)
        if "+" in chunk:
            continue
        parts = re.findall(r"'((?:[^']|'')*)'", chunk)
        total = sum(len(p.replace("''", "'")) for p in parts) + chunk.count("#13")
        if total <= 255:
            continue
        out.append(text[pos:m.start()])
        out.append(fix_juxt(chunk))
        pos = m.end()
        fixed += 1
    out.append(text[pos:])
    if fixed:
        raw = "".join(out).encode("utf-8")
        UI18N.write_bytes(b"\xef\xbb\xbf" + raw)
        print(f"fixed {fixed} chains")
    else:
        print("nothing to auto-fix (maybe already fixed)")


if __name__ == "__main__":
    main()
