# -*- coding: utf-8 -*-
from pathlib import Path

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
raw = UI18N.read_bytes()
# work line by line in binary to match compiler byte counts if UTF-8
text = raw.decode("utf-8-sig")
lines = text.splitlines()
long_char = []
long_utf8 = []
for i, line in enumerate(lines, 1):
    if len(line) > 1023:
        long_char.append((i, len(line)))
    blen = len(line.encode("utf-8"))
    if blen > 1023:
        long_utf8.append((i, len(line), blen))

print("char>1023", len(long_char))
print("utf8>1023", len(long_utf8))
for i, c, b in long_utf8[:20]:
    print(f"  L{i} chars={c} utf8={b}")

# show around 21107
for i in range(21100, 21115):
    if i <= len(lines):
        L = lines[i - 1]
        print(f"L{i} chars={len(L)} utf8={len(L.encode('utf-8'))}")
