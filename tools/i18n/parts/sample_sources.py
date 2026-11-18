import json
from pathlib import Path

c = json.loads(Path("tools/i18n/catalog.json").read_text(encoding="utf-8"))
lo, hi = 0, 80
for i in range(lo, hi):
    e = c["entries"][i]
    s = e["source"].replace("\r", "\\r").replace("\n", "\\n")
    print(f"{i}\t{e['kind']}\t{e['key'][:48]}\t{s[:140]}")
