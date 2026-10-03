#!/usr/bin/env python3
"""Restore procedure/function signatures from backup (multiline const params)."""
from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

BACKUP = Path(
    r"C:\Hamden\Sistemas\Backend\delphi\delphi7\FastFile\Components\FileReadThread-2-bkp\Src\MainUnit.pas"
)
CURRENT = Path(__file__).resolve().parent.parent / "MainUnit.pas"

DECL_START = re.compile(
    r"^(\s*)(procedure|function|constructor|destructor)\s+([\w.]+)", re.I
)


def extract_decl(lines: list[str], start_idx: int) -> tuple[int, list[str]]:
    i = start_idx
    decl_lines = [lines[i]]
    if "(" not in lines[i]:
        if decl_lines[0].rstrip().endswith(";"):
            return i, decl_lines
        i += 1
        while i < len(lines) and not decl_lines[-1].rstrip().endswith(";"):
            decl_lines.append(lines[i])
            i += 1
        return i - 1, decl_lines

    i += 1
    while i < len(lines):
        joined = " ".join(decl_lines)
        last = decl_lines[-1].rstrip()
        if last.endswith(");") or (last.endswith(";") and ")" in joined):
            break
        s = lines[i].strip()
        if s.startswith(("const ", "var ", "out ")):
            decl_lines.append(lines[i])
            i += 1
            continue
        # parameter continuation without leading const/var
        if re.match(r"^[A-Za-z_]", s) and (":" in s or s.endswith(");") or s.endswith(")")):
            decl_lines.append(lines[i])
            i += 1
            continue
        if (
            not s.startswith(
                ("procedure ", "function ", "constructor ", "destructor ", "begin")
            )
            and ("," in s or ":" in s)
            and not last.endswith(";")
        ):
            decl_lines.append(lines[i])
            i += 1
            continue
        break
    return i - 1, decl_lines


def collect_decls(lines: list[str]) -> list[dict]:
    decls: list[dict] = []
    i = 0
    while i < len(lines):
        m = DECL_START.match(lines[i])
        if m:
            end, dlines = extract_decl(lines, i)
            text = "\n".join(dlines)
            if "(" in text or m.group(2).lower() in ("constructor", "destructor"):
                decls.append(
                    {
                        "key": m.group(3),
                        "start": i,
                        "end": end,
                        "lines": dlines,
                        "text": text,
                        "has_const_cont": any(
                            l.lstrip().startswith("const ") for l in dlines[1:]
                        ),
                    }
                )
            i = end + 1
            continue
        i += 1
    return decls


def norm_sig(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip())


def main() -> int:
    if not BACKUP.is_file():
        print("Backup not found:", BACKUP, file=sys.stderr)
        return 1
    if not CURRENT.is_file():
        print("Current not found:", CURRENT, file=sys.stderr)
        return 1

    backup_lines = BACKUP.read_text(encoding="utf-8", errors="replace").splitlines()
    current_lines = CURRENT.read_text(encoding="utf-8", errors="replace").splitlines()

    b_decls = collect_decls(backup_lines)
    c_decls = collect_decls(current_lines)

    b_by_key: dict[str, list[dict]] = defaultdict(list)
    for d in b_decls:
        b_by_key[d["key"]].append(d)

    c_by_key: dict[str, list[dict]] = defaultdict(list)
    for d in c_decls:
        c_by_key[d["key"]].append(d)

    replacements: list[tuple[int, int, list[str], str, int]] = []
    skipped: list[tuple] = []

    for key in sorted(set(c_by_key) & set(b_by_key)):
        clist = c_by_key[key]
        blist = b_by_key[key]
        for idx, cd in enumerate(clist):
            if idx >= len(blist):
                skipped.append((key, idx, "no backup match"))
                continue
            bd = blist[idx]
            if bd["text"] == cd["text"]:
                continue
            b_consts = len(re.findall(r"\bconst\b", bd["text"]))
            c_consts = len(re.findall(r"\bconst\b", cd["text"]))
            same_params = norm_sig(bd["text"]) == norm_sig(cd["text"])
            if same_params or bd["has_const_cont"] or b_consts > c_consts:
                replacements.append((cd["start"], cd["end"], bd["lines"], key, idx))
                continue
            if b_consts == c_consts and " const " in bd["text"]:
                replacements.append((cd["start"], cd["end"], bd["lines"], key, idx))

    print(f"Backup decls: {len(b_decls)}, Current decls: {len(c_decls)}")
    print(f"Replacements: {len(replacements)}")
    for r in replacements:
        print(f"  {r[3]}[{r[4]}] lines {r[0]+1}-{r[1]+1}")
    for s in skipped:
        print(f"  SKIP {s}")

    new_lines = current_lines[:]
    for c_start, c_end, b_lines, _key, _idx in sorted(
        replacements, key=lambda x: x[0], reverse=True
    ):
        new_lines[c_start : c_end + 1] = b_lines

    CURRENT.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
    print("Written", CURRENT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
