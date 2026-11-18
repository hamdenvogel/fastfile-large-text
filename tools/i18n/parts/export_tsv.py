"""Export a catalog range as TSV for offline translation."""
import json
import sys
from pathlib import Path

lo, hi = int(sys.argv[1]), int(sys.argv[2])
c = json.loads(Path("tools/i18n/catalog.json").read_text(encoding="utf-8"))
out = Path(sys.argv[3])
lines = []
for i in range(lo, hi + 1):
    src = c["entries"][i]["source"].replace("\\", "\\\\").replace("\r", "\\r").replace("\n", "\\n").replace("\t", "\\t")
    lines.append(f"{i}\t{src}")
out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {out} ({hi - lo + 1} rows)")
