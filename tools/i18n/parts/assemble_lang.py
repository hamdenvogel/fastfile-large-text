"""Assemble part JSON files into tools/i18n/<code>.json for the current catalog."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / "tools" / "i18n"
PARTS = DATA / "parts"
CATALOG = DATA / "catalog.json"
FORMAT_RE = re.compile(
    r"%%|(?<![0-9])%(?:\d+:)?[-+ 0#]*(?:\d+|\*)?(?:\.\d+)?[sdfxXgGeEcuiSD]"
)


def load_catalog():
    document = json.loads(CATALOG.read_text(encoding="utf-8"))
    return document["entries"], document["sha256"]


def validate_one(index: int, source: str, value: str, unchanged: dict[str, str], code: str):
    if not isinstance(value, str):
        raise ValueError(f"{code} {index}: not a string")
    if source.strip() and not value.strip():
        raise ValueError(f"{code} {index}: empty translation")
    value.encode("utf-16-le")
    if (len(source) - len(source.lstrip()) != len(value) - len(value.lstrip())) or (
        source[: len(source) - len(source.lstrip())]
        != value[: len(value) - len(value.lstrip())]
    ) or source[len(source.rstrip()) :] != value[len(value.rstrip()) :]:
        raise ValueError(f"{code} {index}: changed surrounding whitespace")
    if "\ufffd" in value or any(
        "\u202a" <= char <= "\u202e" or "\u2066" <= char <= "\u2069" for char in value
    ):
        raise ValueError(f"{code} {index}: damaged text or BiDi control")
    if FORMAT_RE.findall(source) != FORMAT_RE.findall(value):
        raise ValueError(f"{code} {index}: changed Format parameters")
    if source.count("|") != value.count("|"):
        raise ValueError(f"{code} {index}: changed pipe separators")
    if re.findall(r"\r\n|\r|\n", source) != re.findall(r"\r\n|\r|\n", value):
        raise ValueError(f"{code} {index}: changed line breaks")
    if value == source and re.search(r"[A-Za-z\u00c0-\u024f]{2}", source):
        reason = unchanged.get(str(index))
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError(f"{code} {index}: unchanged text needs an explicit reason")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("code")
    parser.add_argument(
        "--parts",
        nargs="+",
        required=True,
        help="Part JSON files under tools/i18n/parts or absolute paths",
    )
    args = parser.parse_args()
    entries, digest = load_catalog()
    translations: dict[str, str] = {}
    unchanged: dict[str, str] = {}
    must_path = PARTS / f"must_{args.code}.json"
    if must_path.exists():
        must = json.loads(must_path.read_text(encoding="utf-8"))
        translations.update(must.get("translations", {}))
        unchanged.update(must.get("unchanged", {}))
    for name in args.parts:
        path = Path(name)
        if not path.is_absolute():
            path = PARTS / name
        document = json.loads(path.read_text(encoding="utf-8"))
        translations.update(document.get("translations", {}))
        unchanged.update(document.get("unchanged", {}))
    expected = {str(index) for index in range(len(entries))}
    missing = sorted(expected - set(translations), key=int)
    extra = sorted(set(translations) - expected, key=lambda x: int(x) if x.isdigit() else x)
    if missing or extra:
        raise SystemExit(
            f"{args.code}: missing {missing[:20]} ({len(missing)}), "
            f"unexpected {extra[:20]} ({len(extra)})"
        )
    for index, entry in enumerate(entries):
        validate_one(
            index, entry["source"], translations[str(index)], unchanged, args.code
        )
    for index, reason in list(unchanged.items()):
        if index not in expected or translations[index] != entries[int(index)]["source"]:
            del unchanged[index]
            continue
        if not isinstance(reason, str) or not reason.strip():
            raise SystemExit(f"{args.code}: invalid unchanged reason for {index}")
    out = {
        "sha256": digest,
        "unchanged": {k: unchanged[k] for k in sorted(unchanged, key=int)},
        "translations": {str(i): translations[str(i)] for i in range(len(entries))},
    }
    target = DATA / f"{args.code}.json"
    target.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote {target.name}: {len(entries)} entries, unchanged={len(out['unchanged'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
