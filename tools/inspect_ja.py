# -*- coding: utf-8 -*-
from pathlib import Path
import re
t = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8-sig")
# find first Set12 call and dump last 3 args
m = re.search(r"\bSet12\s*\(", t)
print("first Set12 at", m.start() if m else None)
if m:
    # find closing by simple scan
    i = m.end()-1
    depth=0
    in_str=False
    j=i
    while j < len(t):
        c=t[j]
        if in_str:
            if c=="'" and not (j+1<len(t) and t[j+1]=="'"):
                in_str=False
            elif c=="'" and j+1<len(t) and t[j+1]=="'":
                j+=2; continue
            j+=1; continue
        if c=="'":
            in_str=True; j+=1; continue
        if c=="(":
            depth+=1
        elif c==")":
            depth-=1
            if depth==0:
                break
        j+=1
    block=t[m.start():j+1]
    Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\tools\sample_set12.txt").write_text(block, encoding="utf-8")
    print("wrote sample_set12.txt len", len(block))
    # check if JA looks japanese
    print("cjk in sample", bool(re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", block)))
# create lines
for line in t.splitlines():
    if "Japanese" in line and ("CreateTable" in line or "Assign" in line or "FreeAndNil" in line or "Values[K]" in line):
        print("LINE:", line)
