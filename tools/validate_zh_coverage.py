# -*- coding: utf-8 -*-
import re
from pathlib import Path

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
                    out.append(src[start : j + 1])
                    break
            j += 1
    return out


def count_strings(call: str):
    strings = []
    i = 0
    s = call
    while i < len(s):
        if s[i] == "'":
            i += 1
            buf = []
            while i < len(s):
                if s[i] == "'":
                    if i + 1 < len(s) and s[i + 1] == "'":
                        buf.append("'")
                        i += 2
                        continue
                    i += 1
                    break
                buf.append(s[i])
                i += 1
            strings.append("".join(buf))
            continue
        i += 1
    return strings


print("=== uI18n coverage ===")
print("Set12 bare:", len(re.findall(r"(?<![A-Za-z0-9_])Set12\s*\(", text)))
print("Set14:", len(re.findall(r"(?<![A-Za-z0-9_])Set14\s*\(", text)))
print("RegexExamples_Set12:", len(re.findall(r"RegexExamples_Set12\s*\(", text)))
print("RegexExamples_Set14:", len(re.findall(r"RegexExamples_Set14\s*\(", text)))
print("PutNV GTextChineseSimplified:", text.count("PutNV(GTextChineseSimplified"))
print("PutNV GTextChineseTraditional:", text.count("PutNV(GTextChineseTraditional"))
print("PutNV GTextJapanese:", text.count("PutNV(GTextJapanese"))
print("PutNV GChineseSimplified:", text.count("PutNV(GChineseSimplified"))
print("PutNV GChineseTraditional:", text.count("PutNV(GChineseTraditional"))
print("PutNV GJapanese:", text.count("PutNV(GJapanese"))

sig = re.search(r"procedure\s+Set14\s*\((.*?)\);", text, re.S)
if sig:
    params = " ".join(sig.group(1).split())
    print("Set14 signature:", params[:240])
    print("  has ZHCN/ZHTW/Chinese:", any(x in params for x in ("ZHCN", "ZHTW", "ChineseSimplified", "ChineseTraditional", "AZh")))

rex = re.search(r"procedure\s+RegexExamples_Set14\s*\((.*?)\);", text, re.S)
if rex:
    params = " ".join(rex.group(1).split())
    print("RegexExamples_Set14 signature:", params[:240])

calls = extract_calls("Set14", text)
real = [c for c in calls if not c.lstrip("(").startswith("const") and "string" not in c[:100]]
bad = []
for c in real:
    n = len(count_strings(c))
    if n != 15:
        strings = count_strings(c)
        bad.append((n, strings[0] if strings else "?", c[:70].replace("\n", " ")))
print("Set14 real calls:", len(real), "bad arg counts:", len(bad))
for b in bad[:20]:
    print(" ", b)

rex_calls = extract_calls("RegexExamples_Set14", text)
rex_real = [c for c in rex_calls if not c.lstrip("(").startswith("const") and "string" not in c[:100]]
rex_bad = []
for c in rex_real:
    n = len(count_strings(c))
    # key + 14 langs = 15, or maybe different shape
    if n != 15:
        strings = count_strings(c)
        rex_bad.append((n, strings[0] if strings else "?", c[:70].replace("\n", " ")))
print("RegexExamples_Set14 real:", len(rex_real), "bad:", len(rex_bad))
for b in rex_bad[:10]:
    print(" ", b)

# MainUnit / assistant / consts
print("\n=== wiring ===")
for rel in [
    "src/MainUnit.pas",
    "src/uFastFileAssistant.pas",
    "src/UnConsts.pas",
]:
    p = ROOT / rel
    if not p.exists():
        print(rel, "MISSING")
        continue
    t = p.read_text(encoding="utf-8", errors="ignore")
    hits = []
    for key in (
        "alChineseSimplified",
        "alChineseTraditional",
        "Chinese Simplified",
        "Chinese Traditional",
        "中文",
        "LANG_CHINESE",
        "zh-Hans",
        "zh-Hant",
    ):
        if key in t:
            hits.append(key)
    print(f"{rel}: {hits or 'no chinese markers'}")

# TAppLanguage High usage
for rel in ["src/uFastFileAssistant.pas", "src/MainUnit.pas"]:
    p = ROOT / rel
    if p.exists():
        t = p.read_text(encoding="utf-8", errors="ignore")
        print(rel, "Low..High(TAppLanguage):", "Low..High(TAppLanguage)" in t or "Low to High(TAppLanguage)" in t)
