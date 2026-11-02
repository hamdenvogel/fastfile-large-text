"""Offline catalog, validation and Pascal emission for the extra UI languages."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from gen_rtl_i18n import pas_lit
from rtl_dump_stats import DUMP, load

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "tools" / "i18n"
CATALOG = DATA / "catalog.json"
OUT = ROOT / "src" / "uI18nExtra.pas"
LANGUAGES = {
    "hi": ("Hindi", "hindi"),
    "ru": ("Russian", "russian"),
    "ko": ("Korean", "korean"),
    "nl": ("Dutch", "dutch"),
    "tr": ("Turkish", "turkish"),
    "uk": ("Ukrainian", "ukrainian"),
    "th": ("Thai", "thai"),
    "el": ("Greek", "greek"),
    "nb": ("Norwegian", "norwegian"),
    "sv": ("Swedish", "swedish"),
    "da": ("Danish", "danish"),
    "is": ("Icelandic", "icelandic"),
}
BASE_LANGUAGES = {
    "en", "pt-BR", "es", "fr", "de", "it", "pl", "pt-PT",
    "ro", "hu", "cs", "ja", "zh-CN", "zh-TW", "ar", "he",
}
FORMAT_RE = re.compile(
    r"%%|(?<![0-9])%(?:\d+:)?[-+ 0#]*(?:\d+|\*)?(?:\.\d+)?[sdfxXgGeEcuiSD]"
)


def catalog_entries(dump: Path) -> list[dict[str, str]]:
    tables = load(dump)
    keys: set[tuple[str, str]] = set()
    for (language, kind), values in tables.items():
        if language in BASE_LANGUAGES:
            keys.update((kind, key) for key in values)
    entries = []
    for kind, key in sorted(keys):
        source = tables[("en", kind)].get(key)
        if source is None:
            source = key if kind == "T" else next(
                (tables[(language, kind)][key]
                 for language in ("pt-BR", "es", "de", "ar", "he")
                 if key in tables[(language, kind)]),
                key,
            )
        entries.append({"kind": kind, "key": key, "source": source})
    for name, suffix in LANGUAGES.values():
        key = "language.option." + suffix
        if ("K", key) not in keys:
            entries.append({"kind": "K", "key": key, "source": name})
    return entries


def fingerprint(entries: list[dict[str, str]]) -> str:
    text = json.dumps(entries, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def read_document(path: Path) -> dict:
    document = json.loads(
        path.read_text(encoding="utf-8"), object_pairs_hook=unique_object,
    )
    if not isinstance(document, dict):
        raise ValueError(f"{path.name}: expected a JSON object")
    return document


def write_catalog(dump: Path) -> None:
    entries = catalog_entries(dump)
    if CATALOG.exists():
        old_entries, _digest = validate_catalog()
        current = {(entry["kind"], entry["key"]): entry for entry in entries}
        old_keys = {(entry["kind"], entry["key"]) for entry in old_entries}
        entries = [
            current[(entry["kind"], entry["key"])]
            for entry in old_entries
            if (entry["kind"], entry["key"]) in current
        ] + [
            entry for entry in entries if (entry["kind"], entry["key"]) not in old_keys
        ]
    DATA.mkdir(exist_ok=True)
    lines = [
        "{",
        '  "sha256": ' + json.dumps(fingerprint(entries)) + ",",
        '  "entries": [',
    ]
    lines.extend(
        "    " + json.dumps(entry, ensure_ascii=False)
        + ("," if index + 1 < len(entries) else "")
        for index, entry in enumerate(entries)
    )
    lines.extend(["  ]", "}"])
    CATALOG.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Catalog: {len(entries)} entries, {fingerprint(entries)}")


def validate_catalog() -> tuple[list[dict[str, str]], str]:
    catalog = read_document(CATALOG)
    entries = catalog["entries"]
    digest = fingerprint(entries)
    if digest != catalog["sha256"]:
        raise ValueError("Catalog fingerprint does not match its entries")
    pairs = [(entry["kind"], entry["key"]) for entry in entries]
    if len(set(pairs)) != len(pairs):
        raise ValueError("Duplicate catalog keys")
    return entries, digest


def translations_for(
    code: str, entries: list[dict[str, str]], digest: str,
) -> dict[str, str]:
    document = read_document(DATA / (code + ".json"))
    if document["sha256"] != digest:
        raise ValueError(f"{code}: translations belong to a different catalog")
    translations = document["translations"]
    unchanged = document.get("unchanged", {})
    if not isinstance(translations, dict) or not isinstance(unchanged, dict):
        raise ValueError(f"{code}: translations and unchanged must be objects")
    expected = {str(index) for index in range(len(entries))}
    if set(translations) != expected:
        missing = sorted(expected - set(translations), key=int)
        extra = sorted(set(translations) - expected)
        raise ValueError(f"{code}: missing {missing[:20]}, unexpected {extra[:20]}")
    for index, entry in enumerate(entries):
        value = translations[str(index)]
        source = entry["source"]
        if not isinstance(value, str) or (source.strip() and not value.strip()):
            raise ValueError(f"{code} entry {index}: empty or invalid translation")
        value.encode("utf-16-le")
        if (len(source) - len(source.lstrip()) != len(value) - len(value.lstrip())) or (
            source[:len(source) - len(source.lstrip())]
            != value[:len(value) - len(value.lstrip())]
        ) or source[len(source.rstrip()):] != value[len(value.rstrip()):]:
            raise ValueError(f"{code} entry {index}: changed surrounding whitespace")
        if "\ufffd" in value or any(
            "\u202a" <= char <= "\u202e" or "\u2066" <= char <= "\u2069"
            for char in value
        ):
            raise ValueError(f"{code} entry {index}: damaged text or BiDi control")
        if FORMAT_RE.findall(source) != FORMAT_RE.findall(value):
            raise ValueError(f"{code} entry {index}: changed Format parameters")
        if source.count("|") != value.count("|"):
            raise ValueError(f"{code} entry {index}: changed pipe separators")
        if re.findall(r"\r\n|\r|\n", source) != re.findall(r"\r\n|\r|\n", value):
            raise ValueError(f"{code} entry {index}: changed line breaks")
        if value == source and re.search(r"[A-Za-z\u00c0-\u024f]{2}", source):
            reason = unchanged.get(str(index))
            if not isinstance(reason, str) or not reason.strip():
                raise ValueError(
                    f"{code} entry {index}: unchanged text needs an explicit reason"
                )
    for index, reason in unchanged.items():
        if index not in expected or translations[index] != entries[int(index)]["source"]:
            raise ValueError(f"{code}: stale unchanged declaration {index}")
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError(f"{code}: invalid unchanged reason for {index}")
    aliases: dict[tuple[str, str], tuple[int, str]] = {}
    for index, entry in enumerate(entries):
        key = (entry["kind"], entry["key"].casefold())
        value = translations[str(index)]
        if key in aliases and aliases[key][1] != value:
            raise ValueError(
                f"{code}: case-insensitive aliases {aliases[key][0]}/{index} differ"
            )
        aliases[key] = (index, value)
    return translations


def validate_runtime(
    entries: list[dict[str, str]], translations: dict[str, dict[str, str]],
    dump: Path, baseline: Path | None,
) -> None:
    tables = load(dump)
    for code in LANGUAGES:
        expected = {
            (entry["kind"], entry["key"].casefold()): translations[code][str(index)]
            for index, entry in enumerate(entries)
        }
        actual = {
            (kind, key.casefold()): value
            for (language, kind), table in tables.items() if language == code
            for key, value in table.items()
        }
        if actual != expected:
            different = [
                key for key in expected if actual.get(key) != expected[key]
            ]
            unexpected = actual.keys() - expected.keys()
            raise ValueError(
                f"{code}: runtime differs at {different[:10]}, "
                f"unexpected {list(unexpected)[:10]}"
            )
        print(f"{code}: {len(actual)} distinct runtime keys match the catalog")
    current_sources = {
        (entry["kind"], entry["key"]): entry["source"]
        for entry in catalog_entries(dump)
    }
    recorded_sources = {
        (entry["kind"], entry["key"]): entry["source"] for entry in entries
    }
    if current_sources != recorded_sources:
        raise ValueError("The compiled source catalog differs from the recorded snapshot")
    if baseline is not None:
        old_tables = load(baseline)
        added_keys = {"language.option." + suffix for _name, suffix in LANGUAGES.values()}
        for pair, before in old_tables.items():
            after = tables.get(pair)
            if after is None or any(after.get(key) != value for key, value in before.items()):
                raise ValueError(f"Existing language table changed: {pair}")
            additions = after.keys() - before.keys()
            if additions != (added_keys if pair[1] == "K" else set()):
                raise ValueError(f"Unexpected additions to existing language table: {pair}")
        print(
            f"Existing language tables preserved; "
            f"selector labels checked for {len(LANGUAGES)} extra languages"
        )


def pascal_literal(text: str) -> str:
    units = text.encode("utf-16-le")
    return pas_lit("".join(
        chr(units[index] | (units[index + 1] << 8))
        for index in range(0, len(units), 2)
    ))


def emit(
    entries: list[dict[str, str]], translations: dict[str, dict[str, str]],
) -> None:
    lines = [
        "unit uI18nExtra;", "",
        "{ Generated offline by tools\\gen_extra_i18n.py. }", "",
        "interface", "",
        "type",
        "  TExtraPutProc = procedure(const IsText: Boolean; const K, V: string);",
        "",
        "procedure AddExtraTranslations(const Code: string; const Put: TExtraPutProc);",
        "",
        "implementation", "",
        "uses SysUtils;", "",
    ]
    part_names: dict[str, list[str]] = {}
    for code, (name, _suffix) in LANGUAGES.items():
        part_names[code] = []
        for start in range(0, len(entries), 100):
            procedure = f"Add{name}Part{start // 100 + 1:02d}"
            part_names[code].append(procedure)
            lines.extend([f"procedure {procedure}(const Put: TExtraPutProc);", "begin"])
            for index in range(start, min(start + 100, len(entries))):
                entry = entries[index]
                is_text = "True" if entry["kind"] == "T" else "False"
                lines.extend([
                    f"  Put({is_text},",
                    "    " + pascal_literal(entry["key"]).replace("\n", "\n    ") + ",",
                    "    " + pascal_literal(translations[code][str(index)]).replace(
                        "\n", "\n    "
                    ) + ");",
                ])
            lines.extend(["end;", ""])
    lines.extend([
        "procedure AddExtraTranslations(const Code: string; const Put: TExtraPutProc);",
        "begin",
    ])
    for index, (code, procedures) in enumerate(part_names.items()):
        prefix = "if" if index == 0 else "else if"
        lines.extend([f"  {prefix} Code = '{code}' then", "  begin"])
        lines.extend("    " + procedure + "(Put);" for procedure in procedures)
        lines.append("  end")
    lines.extend([
        "  else",
        "    raise EArgumentException.Create('Unknown translation language: ' + Code);",
        "end;", "", "end.", "",
    ])
    OUT.write_text("\r\n".join(lines), encoding="utf-8-sig")
    print(f"Emitted {OUT.name}: {len(entries)} entries in each of {len(LANGUAGES)} languages")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", action="store_true")
    parser.add_argument("--dump", type=Path, default=DUMP)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--runtime", action="store_true")
    parser.add_argument("--baseline", type=Path)
    args = parser.parse_args()
    if args.catalog:
        write_catalog(args.dump)
        return
    entries, digest = validate_catalog()
    translations = {
        code: translations_for(code, entries, digest) for code in LANGUAGES
    }
    print(f"Validated {len(entries)} entries per language")
    if args.baseline is not None and not args.runtime:
        raise ValueError("--baseline requires --runtime")
    if args.runtime:
        validate_runtime(entries, translations, args.dump, args.baseline)
    if not args.check:
        emit(entries, translations)


if __name__ == "__main__":
    main()
