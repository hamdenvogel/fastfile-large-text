"""Audit: which forms/units set translated UI text at runtime but do not react to
WM_FF_LANGUAGE_CHANGED (runtime language switch)."""
import os
import re

SRC = os.path.join(os.path.dirname(__file__), '..')

RUNTIME_TEXT = re.compile(
    r"(\.(Caption|Hint|Text|TextHint)\s*:=|Items\.Add\(|Items\.Insert\(|Cells\[|"
    r"Panels\[\d+\]\.Text|Lines\.Add\(|\.Items\[\w+\]\s*:=)[^;]*\bTr(Text)?\(",
    re.I)
HANDLER = re.compile(r"WM_FF_LANGUAGE_CHANGED|\$8000\s*\+\s*\$3A1", re.I)


def read(p):
    b = open(p, 'rb').read()
    for enc in ('utf-8-sig', 'cp1252'):
        try:
            return b.decode(enc)
        except UnicodeDecodeError:
            pass
    return b.decode('latin-1')


rows = []
for fn in sorted(os.listdir(SRC)):
    if not fn.lower().endswith('.pas'):
        continue
    p = os.path.join(SRC, fn)
    s = read(p)
    has_dfm = os.path.exists(os.path.join(SRC, fn[:-4] + '.dfm'))
    is_form = has_dfm or re.search(r"=\s*class\s*\(\s*T(s)?Form\b", s) is not None
    if not is_form:
        continue
    hits = [ln for ln in s.splitlines() if RUNTIME_TEXT.search(ln)]
    handler = bool(HANDLER.search(s))
    rows.append((fn, has_dfm, handler, len(hits)))

print('%-34s %-4s %-8s %s' % ('unit', 'dfm', 'handler', 'runtime-text-lines'))
for fn, dfm, h, n in sorted(rows, key=lambda r: (r[2], -r[3])):
    print('%-34s %-4s %-8s %d' % (fn, 'y' if dfm else '-', 'YES' if h else 'no', n))
