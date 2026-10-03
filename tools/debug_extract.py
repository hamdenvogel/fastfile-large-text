# -*- coding: utf-8 -*-
import re, time, importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "addja",
    r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\tools\add_japanese_i18n.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

text = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(
    encoding="utf-8", errors="replace"
)
t0 = time.time()
spans = mod.find_call_spans(text, "Set11")
print("spans", len(spans), time.time() - t0)
bad = 0
ens = []
seen = set()
t0 = time.time()
for i, (start, op, cl) in enumerate(spans):
    exprs = mod.extract_pascal_string_exprs(text[op + 1 : cl])
    if len(exprs) != 12:
        bad += 1
        if bad <= 5:
            print("BAD", i, len(exprs), "pos", start, "sample", exprs[:2] if exprs else None)
            print("BLOB head:", repr(text[op + 1 : op + 120]))
        continue
    en = mod.decode_pascal_string_expr(exprs[1])
    if en not in seen:
        seen.add(en)
        ens.append(en)
print("bad", bad, "unique", len(ens), "sec", time.time() - t0)
