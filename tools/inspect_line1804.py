# -*- coding: utf-8 -*-
from pathlib import Path
raw = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_bytes()
for label, needle in [
    ("ja-ro", b"GRomanian.Values['language.option.japanese']"),
    ("cz-ro", b"GRomanian.Values['language.option.czech']"),
    ("pl-ro", b"GRomanian.Values['language.option.polish']"),
]:
    i = raw.find(needle)
    chunk = raw[i : i + 100]
    print(label, chunk)
    # show from := to end of line
    line_end = raw.find(b"\n", i)
    print(" line:", raw[i:line_end])
