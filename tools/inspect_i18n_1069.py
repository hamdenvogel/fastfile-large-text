# -*- coding: utf-8 -*-
from pathlib import Path

path = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
lines = path.read_text(encoding="utf-8").splitlines()
for n in range(1068, 1080):
    line = lines[n - 1]
    print(f"--- {n} len={len(line)} ---")
    print(repr(line))
