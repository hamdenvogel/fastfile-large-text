# -*- coding: utf-8 -*-
"""
Repair uI18n.pas.bak_broken_putnv (has full Japanese Set12 + corrupted PutNV)
and write to src/uI18n.pas.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
SRC = ROOT / "tools" / "uI18n.pas.bak_broken_putnv"
DST = ROOT / "src" / "uI18n.pas"


def parse_string(s: str, i: int) -> int:
    """Return index after closing quote of string starting at s[i]=='."""
    assert s[i] == "'"
    j = i + 1
    n = len(s)
    while j < n:
        if s[j] == "'":
            if j + 1 < n and s[j + 1] == "'":
                j += 2
                continue
            return j + 1
        j += 1
    raise ValueError("unterminated string")


def find_putnv_calls(text: str) -> list[tuple[int, int]]:
    """Return (start, end) spans of PutNV(...); including the semicolon."""
    spans = []
    i = 0
    n = len(text)
    while True:
        j = text.find("PutNV(", i)
        if j < 0:
            break
        # skip procedure declaration
        line_start = text.rfind("\n", 0, j) + 1
        if text[line_start:j].lstrip().startswith("procedure "):
            i = j + 6
            continue
        k = j + 6
        depth = 1
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
            if ch == ";" and depth >= 1:
                # premature ; — call is broken; extend to line end semicolon
                # find next newline-ish end
                end = text.find("\n", k)
                if end < 0:
                    end = n
                # include through last ; on this physical stretch
                spans.append((j, end))
                k = end
                depth = 0
                break
            k += 1
        else:
            # depth hit 0 via )
            if k < n and text[k] == ";":
                k += 1
            spans.append((j, k))
        i = max(k, j + 6)
    return spans


def repair_broken_call(call: str) -> str:
    """Repair a single PutNV(...) fragment that may be corrupted."""
    # Already well-formed?
    try:
        if call.rstrip().endswith(");") or call.rstrip().endswith(");"):
            # verify parse
            if _well_formed(call):
                return call
    except Exception:
        pass

    s = call.rstrip()
    # Class A: ends with ';', missing ')' before it, and string already contains content
    if s.endswith(";") and not s.endswith(");"):
        opens = s.count("(")
        closes = s.count(")")
        # crude: if more opens, add )
        if opens > closes:
            s = s[:-1] + ");"
            if _well_formed(s):
                return s

    # Class B: string closed too early before '; rest).';' or '; rest';'
    # Pattern: ...'xxx'); yyy).';  or ...'xxx'); yyy';
    # Merge '; yyy).' back into string
    if not _well_formed(s):
        s2 = _merge_early_semicolon(s)
        if _well_formed(s2):
            return s2

    # Class C: English-style only); -> only; inside last string, then ensure );
    s3 = s.replace("only); file", "only; file")
    s3 = s3.replace("lista); arquivo", "lista; arquivo")
    s3 = s3.replace("lista); ficheiro", "lista; ficheiro")
    s3 = s3.replace("lista); archivo", "lista; archivo")
    if s3.endswith(";") and not s3.endswith(");"):
        s3 = s3[:-1] + ");"
    if _well_formed(s3):
        return s3

    return call  # leave as-is; will report


def _well_formed(call: str) -> bool:
    s = call.strip()
    if not s.startswith("PutNV("):
        return False
    i = 6
    depth = 1
    n = len(s)
    while i < n and depth:
        ch = s[i]
        if ch == "'":
            i = parse_string(s, i)
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == ";":
            return False
        i += 1
    if depth != 0:
        return False
    rest = s[i:].strip()
    return rest == ";" or rest == ""


def _merge_early_semicolon(s: str) -> str:
    """If a string ends and ; + trailing text follows before PutNV closes, merge."""
    # Walk like PutNV parser; on bare ; at depth 1, merge into previous string
    if not s.startswith("PutNV("):
        return s
    i = 6
    depth = 1
    n = len(s)
    last_str_end = -1  # index after closing quote
    while i < n and depth:
        ch = s[i]
        if ch == "'":
            i = parse_string(s, i)
            last_str_end = i
            continue
        if ch == "(":
            depth += 1
            i += 1
            continue
        if ch == ")":
            depth -= 1
            i += 1
            continue
        if ch == ";":
            if last_str_end <= 0:
                return s
            # Merge from this ; up to before final statement end into the string
            # Remove closing quote at last_str_end-1, insert content, re-close
            # Content to merge: from i to the last `).` or end before final issues
            # Take everything from `;` through a trailing `).` if present, else to end
            tail = s[i:]  # starts with ;
            # Prefer ending at ).'  pattern leftovers like `; foo).';` or `; foo';`
            merged_body = tail
            # strip trailing ; 
            if merged_body.endswith(";"):
                merged_body = merged_body[:-1]
            # if ends with ) that was meant to close PutNV wrongly left inside — keep ). in message
            # Rebuild: s[:last_str_end-1] + merged_body + "'" + ");"
            # last_str_end points after '
            new_s = s[: last_str_end - 1] + merged_body + "');"
            return new_s
        i += 1
    return s


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing {SRC}")
    text = SRC.read_text(encoding="utf-8")
    print(f"loaded broken ({len(text)} chars)")

    # Line-oriented repair for common single-line PutNV corruption
    lines = text.splitlines(keepends=True)
    fixed = 0
    still_bad = []
    out_lines = []
    for n, line in enumerate(lines, 1):
        if "PutNV(" not in line or "procedure PutNV(" in line:
            out_lines.append(line)
            continue
        if line.rstrip().endswith("+"):
            out_lines.append(line)  # multi-line; handle later
            continue
        raw = line.rstrip("\r\n")
        nl = line[len(raw) :]
        if _well_formed(raw):
            out_lines.append(line)
            continue
        repaired = repair_broken_call(raw)
        if repaired != raw and _well_formed(repaired):
            out_lines.append(repaired + nl)
            fixed += 1
        else:
            # try specific substitutions then add )
            r2 = raw
            for a, b in [
                ("only); file", "only; file"),
                ("lista); arquivo", "lista; arquivo"),
                ("lista); ficheiro", "lista; ficheiro"),
                ("lista); archivo", "lista; archivo"),
                ("liste); fichier", "liste; fichier"),
                ("Decode); Datei", "Decode; Datei"),
                ("elenco); file", "elenco; file"),
                ("listy); plik", "listy; plik"),
                ("list'#259'); fi", "list'#259'; fi"),
                ("dekodolas); lemezen", "dekodolas; lemezen"),
                ("seznamu); soubor", "seznamu; soubor"),
                ("bytes); each", "bytes; each"),
                ("bytes); cada", "bytes; cada"),
                ("octets); c", "octets; c"),
                ("ausgeglichen); j", "ausgeglichen; j"),
                ("byte); ogni", "byte; ogni"),
                ("bajtow); kazda", "bajtow; kazda"),
                ("octeti); fie", "octeti; fie"),
                ("kiegyensul", "kiegyensul"),  # noop placeholder
            ]:
                r2 = r2.replace(a, b)
            if r2.endswith(";") and not r2.endswith(");"):
                if r2.count("(") > r2.count(")"):
                    r2 = r2[:-1] + ");"
            # merge early close for #code strings: "lista'); resto"
            if not _well_formed(r2):
                r2 = _merge_early_semicolon(raw)
                if r2.endswith(";") and not r2.endswith(");") and r2.count("(") > r2.count(")"):
                    r2 = r2[:-1] + ");"
            if _well_formed(r2):
                out_lines.append(r2 + nl)
                fixed += 1
            else:
                still_bad.append((n, raw[:120]))
                out_lines.append(line)
    text2 = "".join(out_lines)
    print(f"fixed single-line PutNV: {fixed}")
    print(f"still bad: {len(still_bad)}")
    for n, preview in still_bad[:30]:
        print(f"  {n}: {preview}")

    DST.write_text(text2, encoding="utf-8")
    print(f"wrote {DST}")
    print(f"Set12 procs: {len(re.findall(r'procedure Set12\\(', text2))}")
    print(f"Set11 procs: {len(re.findall(r'procedure Set11\\(', text2))}")
    print(f"GTextJapanese: {text2.count('GTextJapanese')}")


if __name__ == "__main__":
    main()
