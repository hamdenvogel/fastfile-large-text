# -*- coding: utf-8 -*-
from pathlib import Path

lines = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(
    encoding="utf-8-sig"
).splitlines()
bad = []
for i in range(len(lines) - 1):
    a = lines[i].rstrip()
    b = lines[i + 1].lstrip()
    if not b.startswith("'"):
        continue
    # ends with #13#10 but not with + (needs + before next string)
    if a.endswith("#13#10") and not a.endswith("+"):
        bad.append(i + 1)

print("missing + before next string after #13#10:", len(bad))
for n in bad[:40]:
    print(n, repr(lines[n - 1][-70:]))
    print("   ->", repr(lines[n][:60]))
