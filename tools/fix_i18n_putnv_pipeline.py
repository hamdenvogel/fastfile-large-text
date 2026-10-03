# -*- coding: utf-8 -*-
"""Full rebuild: bak_before_ja -> Japanese restore -> correct PutNV."""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
BAK_JA = ROOT / "tools" / "uI18n.pas.bak_before_ja"
BAK_BROKEN = ROOT / "tools" / "uI18n.pas.bak_broken_putnv"


def main() -> None:
    if not BAK_JA.exists():
        raise SystemExit(f"missing {BAK_JA}")

    if UI18N.exists():
        shutil.copy2(UI18N, BAK_BROKEN)
        print(f"backed up broken -> {BAK_BROKEN}")

    shutil.copy2(BAK_JA, UI18N)
    print(f"restored {BAK_JA.name} -> uI18n.pas")

    print("=== restore_japanese_i18n.py ===")
    r = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "restore_japanese_i18n.py")],
        cwd=str(ROOT / "tools"),
    )
    if r.returncode != 0:
        raise SystemExit(f"japanese restore failed: {r.returncode}")

    print("=== rebuild_i18n_putnv_correct.py (convert in place) ===")
    # Inline convert without re-copying bak
    from rebuild_i18n_putnv_correct import convert_values, inject_helpers, validate_putnv_lines

    text = UI18N.read_text(encoding="utf-8")
    print(f"pre-convert Values={text.count('.Values[')} PutNV={text.count('PutNV(')} JA={text.count('GTextJapanese')}")
    text = inject_helpers(text)
    text, n = convert_values(text)
    print(f"converted {n}, remaining Values={text.count('.Values[')}")
    bad = validate_putnv_lines(text)
    print(f"suspicious endings: {len(bad)}")
    for item in bad[:15]:
        print(" ", item)
    UI18N.write_text(text, encoding="utf-8")
    print("done")


if __name__ == "__main__":
    main()
