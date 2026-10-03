# -*- coding: utf-8 -*-
"""Convert any remaining .Values[] to PutNV; fix truncated PutNV lines."""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rebuild_i18n_putnv_correct import convert_values

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")


def fix_missing_close_paren(text: str) -> tuple[str, int]:
    """Fix PutNV(...); missing ) before ;  e.g. PutNV(a, b, 'x'#227';"""
    lines = text.splitlines(keepends=True)
    n = 0
    out = []
    for line in lines:
        if "PutNV(" in line and not line.rstrip().endswith("+"):
            stripped = line.rstrip("\r\n")
            # ends with ; but not );
            if stripped.endswith(";") and not stripped.endswith(");"):
                # only if open PutNV not closed
                if stripped.count("(") > stripped.count(")"):
                    # insert ) before final ;
                    nl = "\n" if line.endswith("\n") else ""
                    if line.endswith("\r\n"):
                        nl = "\r\n"
                    elif line.endswith("\n"):
                        nl = "\n"
                    else:
                        nl = ""
                    stripped = stripped[:-1] + ");"
                    line = stripped + nl
                    n += 1
        out.append(line)
    return "".join(out), n


def main() -> None:
    text = UI18N.read_text(encoding="utf-8")
    text, nfix = fix_missing_close_paren(text)
    print(f"fixed missing ): {nfix}")
    before = text.count(".Values[")
    text, n = convert_values(text)
    print(f"converted more Values: {n}, before={before}, after={text.count('.Values[')}")
    text, nfix2 = fix_missing_close_paren(text)
    print(f"fixed missing ) again: {nfix2}")
    UI18N.write_text(text, encoding="utf-8")
    print(f"Set11 count: {len(re.findall(r'\\bSet11\\s*\\(', text))}")
    print(f"Set12 count: {len(re.findall(r'\\bSet12\\s*\\(', text))}")


if __name__ == "__main__":
    main()
