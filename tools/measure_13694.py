# -*- coding: utf-8 -*-
from pathlib import Path
import re

t = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8-sig")
line = t.splitlines()[13693]
print("line chars", len(line), "utf8", len(line.encode("utf-8")))
for m in re.finditer(r"'((?:[^']|'')*)'", line):
    inner = m.group(1)
    n = len(inner.replace("''", "'"))
    b = len(inner.encode("utf-8"))
    print(f"  chars={n} utf8={b} :: {inner[:60].encode('ascii','backslashreplace').decode()}")

# Compare EN version length nearby - find Define transform JA and EN
idx = t.find("'Define:  def transform(line, ctx) -> str | None'#13#10 +\n")
print("EN-style with + exists", idx > 0)
# Show English first occurrence of this key pattern - look at Set12 call structure
# Fix: rewrite JA line to match other languages format with + and short segments
