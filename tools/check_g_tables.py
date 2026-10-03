# -*- coding: utf-8 -*-
import re, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
text = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8-sig")

def keys(name):
    return set(re.findall(rf"PutNV\({name},\s*'((?:''|[^'])*)'", text))

ge, gp, gj, gcn = keys("GEnglish"), keys("GPortuguese"), keys("GJapanese"), keys("GChineseSimplified")
print("G EN", len(ge), "PT", len(gp), "JA", len(gj), "CN", len(gcn))
print("EN-PT", len(ge-gp), "EN-JA", len(ge-gj), "EN-CN", len(ge-gcn))
print("CN keys:", sorted(gcn))
print("JA keys:", sorted(gj))
# keys EN has PT has but not CN
print("PT has CN lacks:", sorted((ge & gp) - gcn)[:40])
