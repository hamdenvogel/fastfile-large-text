#!/usr/bin/env python3
"""Remove orphan duplicate signature lines left by partial restore."""
import re
from pathlib import Path

MAIN = Path(__file__).resolve().parent.parent / "MainUnit.pas"

ORPHAN = re.compile(
    r"^\s+(?:"
    r"ANewLineCount: Int64; AInvalidateDenseIndex, ADiscardSparseCkpt: Boolean\);"
    r"|AInsertLines: TStringList(?: = nil)?(?:; ALineSpanCount: Integer = 1)?\);"
    r"|AInsertLines: TStringList; ALineSpanCount: Integer\);"
    r"|AShortcut: Word = 0; AImageIndex: Integer = -1\): TMenuItem;"
    r"|HintByte0: Integer; CaseSens: Boolean\): Integer;"
    r"|MaxWidth: Integer\): string;"
    r"|Index: Integer; const ItemRect: TRect\);"
    r"|AMatchMode: TFilterMatchMode\);"
    r"|SrcBmp: TBitmap; SrcBlend: Integer\);"
    r")\s*$"
)


def main() -> None:
    lines = MAIN.read_text(encoding="utf-8", errors="replace").splitlines()
    out = []
    removed = 0
    for i, line in enumerate(lines):
        if ORPHAN.match(line):
            prev = out[-1].rstrip() if out else ""
            if (
                prev.endswith(");")
                or prev.endswith(": TMenuItem;")
                or prev.endswith(": string;")
                or prev.endswith(": Integer;")
                or prev.endswith(": TRect;")
            ):
                removed += 1
                continue
        out.append(line)
    MAIN.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"Removed {removed} orphan lines from {MAIN}")


if __name__ == "__main__":
    main()
