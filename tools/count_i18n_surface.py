# -*- coding: utf-8 -*-
"""Count translation surface for Chinese i18n."""
from __future__ import annotations

import re
from pathlib import Path

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
text = UI18N.read_text(encoding="utf-8")

# PutNV(GTextEnglish, Key, Val)
putnv = re.findall(
    r"PutNV\(GTextEnglish,\s*((?:'(?:[^']|'')*'|#\d+|\s|\+)+),\s*((?:'(?:[^']|'')*'|#\d+|\s|\+)+)\);",
    text,
)
print("PutNV GTextEnglish approx", len(putnv))

# Set12 calls
print("procedure Set12", len(re.findall(r"procedure Set12\(", text)))
print("Set12(", len(re.findall(r"\bSet12\(", text)))
print("PutNV GTextJapanese", text.count("PutNV(GTextJapanese"))
print("file lines", text.count("\n") + 1)
print("file chars", len(text))

# Sample Set12 body
m = re.search(r"procedure Set12\(const K: string;.*?^\s*end;", text, re.S | re.M)
if m:
    print("--- sample Set12 body ---")
    print(m.group(0)[:500])
