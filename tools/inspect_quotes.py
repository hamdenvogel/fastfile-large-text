# -*- coding: utf-8 -*-
from pathlib import Path
line = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8").splitlines()[1068]
idx = line.find("only")
print(line[idx:idx+20])
print([hex(ord(c)) for c in line[idx:idx+20]])
# also find all quote positions in value part
v = line.split(",", 2)[2]
print("value part:", v)
print("quotes at:", [i for i,c in enumerate(v) if c=="'"])
