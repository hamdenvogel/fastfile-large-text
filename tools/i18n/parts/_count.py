import json
from pathlib import Path

root = Path("tools/i18n/parts")
for path in sorted(root.rglob("*.json")):
    if path.name.startswith(("must_", "src_")):
        continue
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
        translations = document.get("translations", {})
        keys = sorted(int(key) for key in translations)
        span = (keys[0], keys[-1]) if keys else None
        print(f"{path.relative_to(root)}: {len(keys)} {span}")
    except Exception as error:
        print(path.name, type(error).__name__, error)
