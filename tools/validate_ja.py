# -*- coding: utf-8 -*-
import json, re
from pathlib import Path

raw = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_bytes()
print("BOM", raw[:3] == b"\xef\xbb\xbf")
t = raw.decode("utf-8-sig")
print("alJapanese", "alJapanese" in t)
print("GTextJapanese create", "GTextJapanese   := CreateTable" in t or "GTextJapanese := CreateTable" in t)
print("Set11(", len(re.findall(r"\bSet11\s*\(", t)))
print("Set12(", len(re.findall(r"\bSet12\s*\(", t)))
print("CJK chars", bool(re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", t)))
# count Set12 with 13 string args roughly: look for JA assignment in body
print("GTextJapanese.Values[K]", "GTextJapanese.Values[K] := JA" in t)
c = json.loads(Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\tools\ja_translation_cache.json").read_text(encoding="utf-8"))
same = sum(1 for k, v in c.items() if k == v)
cjk = sum(1 for v in c.values() if re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", v or ""))
print("cache", len(c), "identical_en", same, "with_cjk", cjk)
for k, v in c.items():
    if k != v and re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", v or ""):
        print("SAMPLE:", k[:50], "=>", v[:70])
        break
# verify one known key in file
idx = t.find("Set12(\n    'Filter / Grep'")
if idx < 0:
    idx = t.find("Set12(\n    'Recent &tabs'")
print("sample call idx", idx)
if idx >= 0:
    print(t[idx:idx+500][-120:])
