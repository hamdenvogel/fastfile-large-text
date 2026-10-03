# -*- coding: utf-8 -*-
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
p = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
raw = p.read_bytes()
bom = raw.startswith(b"\xef\xbb\xbf")
text = raw.decode("utf-8-sig")
nl = "\r\n" if "\r\n" in text else "\n"
lines = text.replace("\r\n", "\n").split("\n")
fixed = 0
for i in range(len(lines) - 1):
    a = lines[i].rstrip()
    b = lines[i + 1].lstrip()
    if b.startswith("'") and a.endswith("#13#10") and not a.endswith("+"):
        lines[i] = a + " +"
        fixed += 1
        print(f"fixed line {i + 1}")
out = nl.join(lines)
if text.endswith("\n") and not out.endswith("\n"):
    out += "\n" if nl == "\n" else "\r\n"
data = out.encode("utf-8")
if bom:
    data = b"\xef\xbb\xbf" + data
p.write_bytes(data)
print(f"total fixed: {fixed}")
