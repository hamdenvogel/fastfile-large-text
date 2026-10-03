# -*- coding: utf-8 -*-
import re, time
from pathlib import Path
text = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8", errors="replace")

def find_call_spans(text, name):
    spans = []
    pat = re.compile(rf"\b{name}\s*\(")
    for mi, m in enumerate(pat.finditer(text)):
        start = m.start()
        open_paren = m.end() - 1
        depth = 0
        j = open_paren
        in_str = False
        n = len(text)
        while j < n:
            c = text[j]
            if in_str:
                if c == "'":
                    if j + 1 < n and text[j + 1] == "'":
                        j += 2
                        continue
                    in_str = False
                j += 1
                continue
            if c == "'":
                in_str = True
                j += 1
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    spans.append((start, open_paren, j))
                    break
            j += 1
        else:
            print("UNCLOSED", mi, start)
            break
        if mi and mi % 200 == 0:
            print("ok", mi)
    return spans

t0 = time.time()
spans = find_call_spans(text, "Set11")
print("spans", len(spans), "sec", time.time() - t0)
