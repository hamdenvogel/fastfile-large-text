# -*- coding: utf-8 -*-
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
text = (ROOT / "src" / "uI18n.pas").read_text(encoding="utf-8-sig")

MISSING = [
    "File changed on disk since load",
    "SplitEqualParts.FailureFormat",
    "SplitEqualParts.SuccessFormat",
    "SplitFileFraction.FailureFormat",
    "SplitFileFraction.Hint",
    "SplitFileFraction.SuccessFormat",
    "When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.",
]

for key in MISSING:
    print("=" * 60)
    print("KEY:", key[:80])
    # find PutNV lines with this key
    for m in re.finditer(rf"PutNV\((G\w+),\s*'{re.escape(key)}',\s*'((?:''|[^'])*)'", text):
        print(f"  PutNV {m.group(1)} = {m.group(2)[:60]!r}")
    # find Set14 containing this key as first arg
    idx = text.find(f"'{key}'")
    if idx < 0:
        print("  literal not found as 'key'")
        continue
    # show context around first few occurrences
    count = 0
    start = 0
    while count < 3:
        idx = text.find(f"'{key}'", start)
        if idx < 0:
            break
        # look back for Set14 or PutNV
        back = text[max(0, idx - 80) : idx]
        print(f"  @ {idx}: ...{back[-60:]!r}")
        start = idx + 1
        count += 1

# Also: for each missing key, get English value and Japanese if any
print("\n=== JA coverage of same keys ===")
for key in MISSING:
    has_ja = bool(re.search(rf"PutNV\(GTextJapanese,\s*'{re.escape(key)}'", text))
    print(f"  JA PutNV: {has_ja} | {key[:50]}")
