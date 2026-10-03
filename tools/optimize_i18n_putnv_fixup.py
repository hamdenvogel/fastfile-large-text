# -*- coding: utf-8 -*-
"""Finish PutNV conversion: remaining Values, forward decls, collapse call."""
from __future__ import annotations

import re
from pathlib import Path

PATH = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")


def parse_string_literal(s: str, i: int) -> tuple[str, int]:
    """Parse a Delphi string starting at s[i] which must be \"'\"."""
    assert s[i] == "'"
    j = i + 1
    out = ["'"]
    n = len(s)
    while j < n:
        ch = s[j]
        if ch == "'":
            if j + 1 < n and s[j + 1] == "'":
                out.append("''")
                j += 2
                continue
            out.append("'")
            return "".join(out), j + 1
        out.append(ch)
        j += 1
    raise ValueError(f"Unterminated string at {i}")


def parse_rhs(s: str, i: int) -> tuple[str, int]:
    """Parse Delphi RHS expression until statement ';' not inside string."""
    n = len(s)
    start = i
    while i < n and s[i] in " \t\r\n":
        i += 1
    expr_start = i
    while i < n:
        ch = s[i]
        if ch == "'":
            _, i = parse_string_literal(s, i)
            continue
        if ch == "{":
            # skip brace comment
            end = s.find("}", i + 1)
            if end < 0:
                raise ValueError("Unterminated comment")
            i = end + 1
            continue
        if ch == "/" and i + 1 < n and s[i + 1] == "/":
            end = s.find("\n", i)
            if end < 0:
                i = n
            else:
                i = end
            continue
        if ch == ";":
            return s[expr_start:i].strip(), i + 1
        i += 1
    raise ValueError(f"No ';' for RHS starting at {start}")


def convert_remaining_values(text: str) -> tuple[str, int]:
    pat = re.compile(r"(?P<table>\bG(?:Text)?\w+)\.Values\[")
    out = []
    i = 0
    count = 0
    n = len(text)
    while True:
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            break
        out.append(text[i : m.start()])
        table = m.group("table")
        j = m.end()
        # parse key expression until ]
        # keys are almost always a single string literal, possibly with [] chars inside quotes
        key_start = j
        depth = 1
        k = j
        while k < n and depth:
            ch = text[k]
            if ch == "'":
                _, k = parse_string_literal(text, k)
                continue
            if ch == "[":
                depth += 1
                k += 1
                continue
            if ch == "]":
                depth -= 1
                if depth == 0:
                    key = text[key_start:k].strip()
                    k += 1
                    break
                k += 1
                continue
            k += 1
        else:
            raise ValueError("Unbalanced Values[")
        # expect :=
        while k < n and text[k] in " \t\r\n":
            k += 1
        if text[k : k + 2] != ":=":
            raise ValueError(f"Expected := after Values at {k}")
        k += 2
        val, k = parse_rhs(text, k)
        out.append(f"PutNV({table}, {key}, {val});")
        count += 1
        i = k
    return "".join(out), count


def main() -> None:
    text = PATH.read_text(encoding="utf-8")

    # Forward-declare helpers used by Collapse before their bodies
    if "function ExtractKeyPart(const S: string; Sep: Char): string; forward;" not in text:
        anchor = "{ Append Name=Value in O(1)."
        if anchor not in text:
            raise SystemExit("helpers comment anchor missing")
        text = text.replace(
            anchor,
            "function ExtractKeyPart(const S: string; Sep: Char): string; forward;\n"
            "function CompareTableByKey(List: TStringList; Index1, Index2: Integer): Integer; forward;\n\n"
            + anchor,
            1,
        )

    text, n = convert_remaining_values(text)
    print(f"Converted remaining Values: {n}")
    print(f"Remaining .Values[: {text.count('.Values[')}")

    sort_block = (
        "  { Sort all tables by key so FastIndexOfName can use binary search. }\n"
        "  SortTablesForFastLookup;"
    )
    new_block = (
        "  { Collapse duplicate keys (last write wins) then sort for binary lookup. }\n"
        "  CollapseAllTranslationTables;\n"
        "  SortTablesForFastLookup;"
    )
    if "CollapseAllTranslationTables;" not in text:
        if sort_block not in text:
            raise SystemExit("sort block not found")
        text = text.replace(sort_block, new_block, 1)
        print("Inserted CollapseAllTranslationTables call")
    else:
        print("Collapse call already present")

    # Also rewrite nested Set12 bodies if any still use Values - already handled.

    # Spot-check Set12: should use PutNV now
    set12_values = len(re.findall(r"procedure Set12\([\s\S]*?^begin\n([\s\S]*?)^  end;", text, re.M))
    print(f"Set12-like blocks scanned: {set12_values}")

    PATH.write_text(text, encoding="utf-8")
    print(f"Wrote {PATH}")


if __name__ == "__main__":
    main()
