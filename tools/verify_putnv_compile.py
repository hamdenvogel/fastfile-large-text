# -*- coding: utf-8 -*-
"""Verify PutNV calls that would cause E2029 (bare ; at depth>0)."""
from pathlib import Path

path = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
text = path.read_text(encoding="utf-8")


def parse_string(s, i):
    j = i + 1
    n = len(s)
    while j < n:
        if s[j] == "'":
            if j + 1 < n and s[j + 1] == "'":
                j += 2
                continue
            return j + 1
        j += 1
    raise ValueError("unterminated")


def scan_file(text: str):
    errors = []
    i = 0
    n = len(text)
    while True:
        j = text.find("PutNV(", i)
        if j < 0:
            break
        line_start = text.rfind("\n", 0, j) + 1
        if text[line_start:j].lstrip().startswith("procedure "):
            i = j + 6
            continue
        k = j + 6
        depth = 1
        start_line = text.count("\n", 0, j) + 1
        try:
            while k < n and depth:
                ch = text[k]
                if ch == "'":
                    k = parse_string(text, k)
                    continue
                if ch == "(":
                    depth += 1
                    k += 1
                    continue
                if ch == ")":
                    depth -= 1
                    k += 1
                    continue
                if ch == ";" and depth > 0:
                    errors.append((start_line, depth, text[j:j+100].replace("\n", " ")))
                    # skip to next line
                    k = text.find("\n", k)
                    if k < 0:
                        k = n
                    break
                k += 1
            else:
                if k < n and text[k] == ";":
                    k += 1
        except ValueError as e:
            errors.append((start_line, -1, f"parse err {e}: {text[j:j+80]!r}"))
            k = text.find("\n", j) 
            if k < 0:
                k = n
        i = max(k, j + 6)
    return errors


errs = scan_file(text)
print(f"bare-semicolon-in-PutNV errors: {len(errs)}")
for e in errs[:40]:
    print(e[0], e[1], e[2][:120])
print("Values leftover", text.count(".Values["))
print("Set12", text.count("procedure Set12("))
print("Collapse", "CollapseAllTranslationTables;" in text)
print("line1069", text.splitlines()[1068][:100])
