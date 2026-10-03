# -*- coding: utf-8 -*-
"""Validate Set14 logical arg count and Chinese PutNV key coverage."""
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
text = (ROOT / "src" / "uI18n.pas").read_text(encoding="utf-8-sig")


def extract_calls(name: str, src: str):
    out = []
    for m in re.finditer(rf"(?<![A-Za-z0-9_]){re.escape(name)}\s*\(", src):
        start = m.end() - 1
        depth = 0
        j = start
        while j < len(src):
            c = src[j]
            if c == "'":
                j += 1
                while j < len(src):
                    if src[j] == "'":
                        if j + 1 < len(src) and src[j + 1] == "'":
                            j += 2
                            continue
                        j += 1
                        break
                    j += 1
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    out.append((m.start(), src[start : j + 1]))
                    break
            j += 1
    return out


def split_top_level_args(call_parens: str):
    """call_parens includes surrounding (...). Split by top-level commas."""
    assert call_parens[0] == "(" and call_parens[-1] == ")"
    s = call_parens[1:-1]
    args = []
    buf = []
    depth = 0
    i = 0
    while i < len(s):
        c = s[i]
        if c == "'":
            buf.append(c)
            i += 1
            while i < len(s):
                buf.append(s[i])
                if s[i] == "'":
                    if i + 1 < len(s) and s[i + 1] == "'":
                        buf.append(s[i + 1])
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            continue
        if c == "(":
            depth += 1
            buf.append(c)
            i += 1
            continue
        if c == ")":
            depth -= 1
            buf.append(c)
            i += 1
            continue
        if c == "," and depth == 0:
            args.append("".join(buf).strip())
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    if buf:
        args.append("".join(buf).strip())
    return args


def first_string_literal(arg: str):
    m = re.search(r"'((?:''|[^'])*)'", arg)
    return m.group(1).replace("''", "'") if m else None


# --- Set14 body ---
body_m = re.search(
    r"procedure\s+Set14\s*\(.*?\)\s*;\s*(?:begin)(.*?)(?:^\s*end;)",
    text,
    re.S | re.M,
)
print("=== Set14 implementation ===")
if body_m:
    body = body_m.group(1)
    for name in (
        "GEnglish",
        "GJapanese",
        "GChineseSimplified",
        "GChineseTraditional",
        "ZHCN",
        "ZHTW",
        "JA",
    ):
        print(f"  {name} in body: {name in body}")
else:
    # try alternate: function might use PutNV
    m2 = re.search(r"procedure Set14\(.*?\);\s*\n(.*?)(?=\nprocedure |\nfunction )", text, re.S)
    if m2:
        body = m2.group(1)
        print(body[:800])
        for name in ("GChineseSimplified", "GChineseTraditional", "ZHCN", "ZHTW"):
            print(f"  {name}: {name in body}")
    else:
        print("  BODY NOT FOUND")

# Find Set14 implementation more carefully
idx = text.find("procedure Set14(")
# find implementation (second occurrence often)
impl_idx = text.find("procedure Set14(", idx + 1)
if impl_idx < 0:
    impl_idx = idx
end_impl = text.find("\nend;", impl_idx)
body = text[impl_idx:end_impl]
print("--- Set14 body snippet ---")
print(body[:1200])

calls = extract_calls("Set14", text)
real = []
for pos, c in calls:
    # skip signatures
    inner = c[1:80]
    if inner.lstrip().startswith("const") or "string" in inner[:60]:
        continue
    real.append((pos, c))

bad = []
for pos, c in real:
    args = split_top_level_args(c)
    if len(args) != 15:
        key = first_string_literal(args[0]) if args else "?"
        bad.append((len(args), key, pos))

print(f"\nSet14 real calls: {len(real)}")
print(f"Set14 bad logical arg counts: {len(bad)}")
for b in bad[:15]:
    print(" ", b)

rex = extract_calls("RegexExamples_Set14", text)
rex_real = []
for pos, c in rex:
    inner = c[1:80]
    if inner.lstrip().startswith("const") or "string" in inner[:60]:
        continue
    rex_real.append((pos, c))
rex_bad = []
for pos, c in rex_real:
    args = split_top_level_args(c)
    if len(args) != 15:
        key = first_string_literal(args[0]) if args else "?"
        rex_bad.append((len(args), key, pos))
print(f"RegexExamples_Set14 real: {len(rex_real)} bad: {len(rex_bad)}")
for b in rex_bad[:10]:
    print(" ", b)

# PutNV key sets for G tables used by Set14
def putnv_keys(list_name: str):
    keys = set()
    for m in re.finditer(rf"PutNV\({re.escape(list_name)},\s*'((?:''|[^'])*)'", text):
        keys.add(m.group(1).replace("''", "'"))
    return keys


# Set14 writes via PutNV inside Set14 - keys come from Set14 first arg
set14_keys = set()
for pos, c in real:
    args = split_top_level_args(c)
    if args:
        k = first_string_literal(args[0])
        if k:
            set14_keys.add(k)

# After Init, G* tables get keys from Set14. Count PutNV for Chinese text tables vs EN text
gtext_cn = putnv_keys("GTextChineseSimplified")
gtext_tw = putnv_keys("GTextChineseTraditional")
gtext_ja = putnv_keys("GTextJapanese")
gtext_en = putnv_keys("GTextEnglish")
g_cn = putnv_keys("GChineseSimplified")
g_tw = putnv_keys("GChineseTraditional")
g_ja = putnv_keys("GJapanese")
g_en = putnv_keys("GEnglish")

print("\n=== PutNV key counts ===")
print(f"GTextEnglish: {len(gtext_en)}")
print(f"GTextJapanese: {len(gtext_ja)}")
print(f"GTextChineseSimplified: {len(gtext_cn)}")
print(f"GTextChineseTraditional: {len(gtext_tw)}")
print(f"GEnglish: {len(g_en)}")
print(f"GJapanese: {len(g_ja)}")
print(f"GChineseSimplified: {len(g_cn)}")
print(f"GChineseTraditional: {len(g_tw)}")
print(f"Set14 keys: {len(set14_keys)}")

missing_cn_text = gtext_en - gtext_cn
missing_tw_text = gtext_en - gtext_tw
print(f"GText EN keys missing in CN: {len(missing_cn_text)}")
print(f"GText EN keys missing in TW: {len(missing_tw_text)}")
if missing_cn_text:
    print(" sample CN missing:", sorted(missing_cn_text)[:20])
if missing_tw_text:
    print(" sample TW missing:", sorted(missing_tw_text)[:20])

# language.option keys
for k in (
    "language.option.chinese_simplified",
    "language.option.chinese_traditional",
    "language.option.japanese",
):
    print(f"key {k} in Set14 keys: {k in set14_keys or k in g_en or any(k in x for x in set14_keys)}")

# AppLanguageFromCode
for needle in (
    "alChineseSimplified",
    "alChineseTraditional",
    "zh-Hans",
    "zh-Hant",
    "zh-CN",
    "zh-TW",
    "chinese_simplified",
    "chinese_traditional",
):
    print(f"uI18n contains {needle!r}: {needle in text}")

print("\nSet12 leftover:", len(re.findall(r"(?<![A-Za-z0-9_])Set12\s*\(", text)))
print("DONE")
