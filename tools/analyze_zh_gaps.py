# -*- coding: utf-8 -*-
"""Find all GTextEnglish / GEnglish keys missing Chinese; prepare patch data."""
import re
import sys
import json
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
text = (ROOT / "src" / "uI18n.pas").read_text(encoding="utf-8-sig")


def extract_putnv_pairs(list_name: str):
    """Return dict key -> list of (value, start, end) for PutNV(list, key, value).
    Value may span concatenated strings; we capture roughly until );
    """
    results = {}
    pat = re.compile(
        rf"PutNV\({re.escape(list_name)},\s*'((?:''|[^'])*)',\s*",
        re.M,
    )
    for m in pat.finditer(text):
        key = m.group(1).replace("''", "'")
        # parse value expression until matching );
        i = m.end()
        depth = 0
        start = i
        while i < len(text):
            c = text[i]
            if c == "'":
                i += 1
                while i < len(text):
                    if text[i] == "'":
                        if i + 1 < len(text) and text[i + 1] == "'":
                            i += 2
                            continue
                        i += 1
                        break
                    i += 1
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                if depth == 0:
                    # end of PutNV
                    val_expr = text[start:i].strip()
                    results.setdefault(key, []).append((val_expr, m.start(), i + 1))
                    break
                depth -= 1
            i += 1
    return results


def first_string(expr: str):
    m = re.search(r"'((?:''|[^'])*)'", expr)
    return m.group(1).replace("''", "'") if m else expr[:80]


for base, cn, tw in [
    ("GTextEnglish", "GTextChineseSimplified", "GTextChineseTraditional"),
    ("GEnglish", "GChineseSimplified", "GChineseTraditional"),
]:
    en = extract_putnv_pairs(base)
    cn_keys = set(extract_putnv_pairs(cn))
    tw_keys = set(extract_putnv_pairs(tw))
    miss_cn = sorted(set(en) - cn_keys)
    miss_tw = sorted(set(en) - tw_keys)
    print(f"\n{base}: {len(en)} keys; missing CN={len(miss_cn)} TW={len(miss_tw)}")
    for k in miss_cn:
        en_val = first_string(en[k][0][0])
        print(f"  MISS {k!r}")
        print(f"    EN: {en_val[:100]!r}")

# Also check JA parity: keys EN has that JA lacks
en = extract_putnv_pairs("GTextEnglish")
ja = set(extract_putnv_pairs("GTextJapanese"))
cn = set(extract_putnv_pairs("GTextChineseSimplified"))
print(f"\nGText EN-JA gap: {len(set(en)-ja)}")
print(f"GText EN-CN gap: {len(set(en)-cn)}")
print(f"Keys JA has that CN lacks: {len(ja-cn)}")
print(f"Keys CN has that JA lacks: {len(cn-ja)}")

# Export missing for translation
missing = sorted(set(en) - cn)
out = []
for k in missing:
    out.append({"key": k, "en": first_string(en[k][0][0])})
(ROOT / "tools" / "zh_missing_keys.json").write_text(
    json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8"
)
print(f"Wrote tools/zh_missing_keys.json ({len(out)} keys)")
