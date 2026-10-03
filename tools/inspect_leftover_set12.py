# -*- coding: utf-8 -*-
from pathlib import Path
import re
import sys

root = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
sys.path.insert(0, str(root / "tools"))
t = (root / "src" / "uI18n.pas").read_text(encoding="utf-8-sig")
ms = list(re.finditer(r"(?m)^\s*Set12\s*\(", t))
print("count", len(ms))
m = ms[0]
chunk = t[m.start() - 80 : m.start() + 600]
(root / "tools" / "zh_leftover_set12.txt").write_text(chunk, encoding="utf-8")
print("line", t.count("\n", 0, m.start()) + 1)

from add_chinese_i18n import iter_set12_calls

n12 = n14 = set12name = 0
samples = []
for start, end, key, langs, name in iter_set12_calls(t):
    if name == "Set12":
        set12name += 1
    if len(langs) == 12:
        n12 += 1
        if len(samples) < 3:
            samples.append((name, key[:40], len(langs), t[start : start + 60].replace("\n", " ")))
    elif len(langs) == 14:
        n14 += 1
print("iter Set12-named", set12name, "n12", n12, "n14", n14)
for s in samples:
    print(" sample", s)
