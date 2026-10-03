# -*- coding: utf-8 -*-
"""Final Chinese coverage report vs EN and PT."""
import re, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
text = (ROOT / "src" / "uI18n.pas").read_text(encoding="utf-8-sig")


def keys(name):
    return set(re.findall(rf"PutNV\({name},\s*'((?:''|[^'])*)'", text))


def extract_calls(name, src):
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


def split_args(call):
    s = call[1:-1]
    args, buf, depth, i = [], [], 0, 0
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


print("Set12:", len(re.findall(r"(?<![A-Za-z0-9_])Set12\s*\(", text)))
print("Set14 calls:", len(re.findall(r"(?<![A-Za-z0-9_])Set14\s*\(", text)))
print("RegexExamples_Set14:", len(re.findall(r"RegexExamples_Set14\s*\(", text)))

for label, a, b in [
    ("GText EN vs CN", "GTextEnglish", "GTextChineseSimplified"),
    ("GText EN vs TW", "GTextEnglish", "GTextChineseTraditional"),
    ("GText PT vs CN", "GTextPortuguese", "GTextChineseSimplified"),
    ("G EN vs CN", "GEnglish", "GChineseSimplified"),
    ("G PT vs CN", "GPortuguese", "GChineseSimplified"),
]:
    ka, kb = keys(a), keys(b)
    miss = sorted(ka - kb)
    print(f"{label}: {a}={len(ka)} {b}={len(kb)} missing={len(miss)}")
    if miss[:5]:
        print("  sample:", miss[:5])

# Set14 arg count
bad = 0
for c in extract_calls("Set14", text):
    if c.lstrip("(").startswith("const") or "string" in c[:80]:
        continue
    if len(split_args(c)) != 15:
        bad += 1
print("Set14 bad args:", bad)
bad = 0
for c in extract_calls("RegexExamples_Set14", text):
    if c.lstrip("(").startswith("const") or "string" in c[:80]:
        continue
    if len(split_args(c)) != 15:
        bad += 1
print("RegexExamples_Set14 bad args:", bad)

# sample traditional vs simplified differ
samples = [
    "Close",
    "Confirmation",
    "language.option.chinese_simplified",
    "toolbar.close",
]
for k in samples:
    m1 = re.search(rf"PutNV\(GTextChineseSimplified,\s*'{re.escape(k)}',\s*'((?:''|[^'])*)'", text)
    m2 = re.search(rf"PutNV\(GTextChineseTraditional,\s*'{re.escape(k)}',\s*'((?:''|[^'])*)'", text)
    m3 = re.search(rf"PutNV\(GChineseSimplified,\s*'{re.escape(k)}',\s*'((?:''|[^'])*)'", text)
    m4 = re.search(rf"PutNV\(GChineseTraditional,\s*'{re.escape(k)}',\s*'((?:''|[^'])*)'", text)
    print(f"key {k!r}:")
    if m1:
        print(f"  TextCN={m1.group(1)}")
    if m2:
        print(f"  TextTW={m2.group(1)}")
    if m3:
        print(f"  GCN={m3.group(1)}")
    if m4:
        print(f"  GTW={m4.group(1)}")

# plumbing checks
for needle in [
    "GTextChineseSimplified := TStringList.Create",
    "GChineseSimplified := TStringList.Create",
    "alChineseSimplified",
    "zh-CN",
    "zh-TW",
]:
    print(f"has {needle!r}: {needle in text}")
