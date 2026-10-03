# -*- coding: utf-8 -*-
s = "View encoding: forced (list decode only); file on disk unchanged)."
print(len(s))
s2 = "View encoding: forced (list decode only)"
print(len(s2))
from pathlib import Path
line = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8").splitlines()[1068]
# Simulate find_bad parser with debug
i = line.find("PutNV(") + len("PutNV(")
depth = 1
in_str = False
while i < len(line):
    ch = line[i]
    if in_str:
        if ch == "'":
            if i + 1 < len(line) and line[i + 1] == "'":
                i += 2
                continue
            in_str = False
            print(f"{i}: leave str after {line[i-20:i+1]!r}")
            i += 1
            continue
        i += 1
        continue
    if ch == "'":
        in_str = True
        print(f"{i}: enter str {line[i:i+30]!r}")
        i += 1
        continue
    if ch == "(":
        depth += 1
        i += 1
        continue
    if ch == ")":
        depth -= 1
        print(f"{i}: ) depth now {depth} ctx {line[i-15:i+10]!r}")
        i += 1
        if depth == 0:
            print("closed", line[i:i+20])
            break
        continue
    if ch == ";":
        print(f"{i}: BARE ; depth={depth} in_str={in_str} ctx={line[i-20:i+20]!r}")
        break
    i += 1
