# -*- coding: utf-8 -*-
from pathlib import Path
line = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8").splitlines()[1068]
# full line quote analysis with Delphi rules
i = 0
in_s = False
while i < len(line):
    if line[i] == "'":
        if in_s and i + 1 < len(line) and line[i + 1] == "'":
            print(i, "escaped quote")
            i += 2
            continue
        in_s = not in_s
        print(i, "TOGGLE", "IN" if in_s else "OUT", repr(line[max(0,i-5):i+15]))
    i += 1
print("final in_s", in_s)
# show chars 55-90 of value
comma2 = line.find(", '", line.find("PutNV"))
print("from second string:", repr(line[comma2:comma2+100]))
for j, ch in enumerate(line[comma2:comma2+100]):
    print(j, repr(ch))
