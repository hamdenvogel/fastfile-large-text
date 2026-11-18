"""Add language.option.finnish/vietnamese to existing extra language JSON files."""
from __future__ import annotations

import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1]
digest = json.loads((DATA / "catalog.json").read_text(encoding="utf-8"))["sha256"]
names = {
    "hi": ("फिनिश", "वियतनामी"),
    "ru": ("Финский", "Вьетнамский"),
    "ko": ("핀란드어", "베트남어"),
    "nl": ("Fins", "Vietnamees"),
    "tr": ("Fince", "Vietnamca"),
    "uk": ("Фінська", "В'єтнамська"),
    "th": ("ฟินแลนด์", "เวียดนาม"),
    "el": ("Φινλανδικά", "Βιετναμικά"),
    "nb": ("Finsk", "Vietnamesisk"),
    "sv": ("Finska", "Vietnamesiska"),
    "da": ("Finsk", "Vietnamesisk"),
    "is": ("Finnska", "Víetnamska"),
}
for code, (fi, vi) in names.items():
    path = DATA / f"{code}.json"
    doc = json.loads(path.read_text(encoding="utf-8"))
    doc["translations"]["3428"] = fi
    doc["translations"]["3429"] = vi
    out = {
        "sha256": digest,
        "unchanged": doc.get("unchanged", {}),
        "translations": {str(i): doc["translations"][str(i)] for i in range(3430)},
    }
    path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(code, "ok")
