#!/usr/bin/env python
"""Generates src/uI18nRtl.pas (Arabic + Hebrew translation tables).

Pipeline
  1. tests/i18ndump/build.cmd  -> tests/i18ndump/i18n_dump.txt (all 14 existing languages)
  2. this script: takes the English text of every key (union of all languages),
     machine-translates it (Google via the `translators` package, Bing fallback) with
     protected tokens ({n}) for format specs, key combos, paths, acronyms ...,
     applies tools/rtl_overrides.py (hand-curated terms) and writes uI18nRtl.pas.

Usage
  python tools/gen_rtl_i18n.py            # translate (resumable, uses tools/rtl_cache_*.json) + emit
  python tools/gen_rtl_i18n.py --emit     # only (re)emit from the caches, never calls the network
  python tools/gen_rtl_i18n.py --lang ar  # one language only

Re-run after adding new texts to uI18n.pas (rebuild the dump first): only the
missing segments are translated. Texts that are not in the tables fall back to English.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

from rtl_dump_stats import load  # noqa: E402

try:
    from rtl_overrides import OVERRIDES  # noqa: E402
except Exception:  # pragma: no cover
    OVERRIDES = {"ar": {}, "he": {}}

OUT = ROOT / "src" / "uI18nRtl.pas"
LANGS = {
    # code: (google code, bing code, Delphi name, cache file)
    "ar": ("ar", "ar", "Arabic", ROOT / "tools" / "rtl_cache_ar.json"),
    "he": ("iw", "he", "Hebrew", ROOT / "tools" / "rtl_cache_he.json"),
}

# --------------------------------------------------------------------------- protect

FORMAT_RE = r"%%|%(?:\d+:)?[-+ 0#]*(?:\d+|\*)?(?:\.\d+)?[sdfxXgGeEcuiSD]"
PROTECT_PATTERNS = [
    r"\{[^{}\n]{0,40}\}",                                            # {name} templates
    FORMAT_RE,
    r"https?://\S+",
    r"[A-Za-z]:\\[^\s\"'|]+",                                        # C:\path
    r"(?:(?:Ctrl|Alt|Shift|Win)\+)+(?:Num[+\-]?|[A-Za-z0-9]+|[+\-])",  # key combos
    r"\bF(?:1[0-2]|[1-9])\b",                                        # F1..F12
    r"\.{4,}",                                                       # dot leaders
    r"\"[^\s\"]{1,30}\"",                                            # "code"
    r"`[^`\n]{1,60}`",                                               # `code`
    r"\*\.[A-Za-z0-9*]+",                                            # *.txt
    r"\b[\w\-]+\.(?:txt|csv|log|json|xml|exe|bat|py|sql|bak|zip|md|ini|dll|html?|tsv|xlsx?|rar|7z|gz|pdf|dpr|pas)\b",
    r"(?<![\w.])\.[A-Za-z0-9]{1,5}\b",                              # .ext
    r"\$[0-9A-Fa-f]+\b|\b0x[0-9A-Fa-f]+\b",                          # hex
    r"\b(?:FastFile|ScriptEngine|VBScript\.RegExp|RegExp|DuckDB|Delphi|Pascal|JavaScript|PowerShell|Python|Notepad\+\+)\b",
    r"\b[A-Za-z]+_[A-Za-z0-9_]+\b",                                  # snake_case identifiers
    r"\b[a-z]+[A-Z][A-Za-z0-9]*\b",                                  # camelCase identifiers
    r"\b[A-Z]{3,}(?:-\d+)?\b",                                       # CSV, JSON, UTF-8 ...
    r"\bUTF-\d+(?:\s?(?:LE|BE))?\b|\b\d+-bit\b",
]
PROTECT_RE = re.compile("|".join("(?:%s)" % p for p in PROTECT_PATTERNS))
TOKEN_RE = re.compile(r"\{\s*([0-9\u0660-\u0669]+)\s*\}")
ACCEL_RE = re.compile(r"(?<!&)&(?!&)([A-Za-z0-9])")
AR_DIGITS = str.maketrans("\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669", "0123456789")


class Seg:
    """One translatable piece: protected text, tokens, accelerator."""

    def __init__(self, core: str):
        self.orig = core
        self.accel = None
        self.tokens: list[str] = []
        text = core
        # single '&' before a letter = menu accelerator ('&&' is a literal ampersand)
        m = ACCEL_RE.search(text)
        if m:
            self.accel = m.group(1)
            text = text[: m.start()] + m.group(1) + text[m.end():]

        def sub(mo):
            self.tokens.append(mo.group(0))
            return "{%d}" % len(self.tokens)

        text = re.sub(r"&&", sub, text)  # literal ampersand kept verbatim
        text = PROTECT_RE.sub(sub, text)
        self.protected = text

    def restore(self, translated: str) -> str | None:
        found = [int(x.translate(AR_DIGITS)) for x in TOKEN_RE.findall(translated)]
        if sorted(found) != list(range(1, len(self.tokens) + 1)):
            return None
        out = TOKEN_RE.sub(
            lambda mo: self.tokens[int(mo.group(1).translate(AR_DIGITS)) - 1], translated
        )
        return out


def has_letters(s: str) -> bool:
    return len(re.findall(r"[A-Za-z]", s)) >= 2


# --------------------------------------------------------------------------- translate

_tlock = threading.Lock()


def google_or_bing(text: str, lang: str, engines: list[str]) -> str:
    import translators as ts

    last = None
    for attempt in range(6):
        for eng in engines:
            to = LANGS[lang][0] if eng == "google" else LANGS[lang][1]
            try:
                out = ts.translate_text(text, translator=eng, from_language="en", to_language=to)
                if isinstance(out, str) and out.strip():
                    return out
            except Exception as e:  # noqa: BLE001
                last = e
        time.sleep(1.5 * (attempt + 1))
    raise RuntimeError("translate failed: %r (%s)" % (text[:60], last))


def load_cache(p: Path) -> dict:
    if p.exists():
        try:
            return json.loads(p.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            return {}
    return {}


def save_cache(p: Path, c: dict) -> None:
    p.write_text(json.dumps(c, ensure_ascii=False, indent=0), encoding="utf-8")


def tokens_ok(t: str, n: int) -> bool:
    found = [int(x.translate(AR_DIGITS)) for x in TOKEN_RE.findall(t)]
    return sorted(found) == list(range(1, n + 1))


def _work(args):
    """Runs in a worker process (the translators lib serialises calls inside one process)."""
    lang, p, ntok = args
    for engines in (["google", "bing"], ["bing", "google"]):
        try:
            t = google_or_bing(p, lang, engines)
        except Exception as e:  # noqa: BLE001
            print("  ERR", e, flush=True)
            continue
        if tokens_ok(t, ntok):
            return p, t
    return p, ""  # failure marker -> English fallback


def translate_segments(lang: str, segs: dict[str, Seg], workers: int) -> dict[str, str]:
    """segs: protected text -> Seg. Returns protected text -> translated (tokens still as {n})."""
    from concurrent.futures import ProcessPoolExecutor

    cache_path = LANGS[lang][3]
    cache = load_cache(cache_path)
    todo = [p for p in segs if p not in cache or cache[p] == ""]
    print(f"[{lang}] {len(segs)} segments, {len(todo)} to translate", flush=True)
    if todo:
        jobs = [(lang, p, len(segs[p].tokens)) for p in todo]
        done = 0
        with ProcessPoolExecutor(max_workers=workers) as ex:
            for p, t in ex.map(_work, jobs, chunksize=4):
                cache[p] = t
                done += 1
                if done % 100 == 0:
                    print(f"  [{lang}] {done}/{len(todo)}", flush=True)
                    save_cache(cache_path, cache)
        save_cache(cache_path, cache)
    return cache


# --------------------------------------------------------------------------- items

SKIP_LONG_SAME = 8  # long text identical to English in >= N other languages -> AI prompt / data, keep English


def collect_items(d):
    en_t = d[("en", "T")]
    en_k = d[("en", "K")]
    keys_t, keys_k = set(), set()
    for (lang, kind), tbl in d.items():
        (keys_t if kind == "T" else keys_k).update(tbl.keys())
    items: dict[tuple[str, str], str] = {}
    for k in keys_t:
        items[("T", k)] = en_t.get(k, k)
    for k in keys_k:
        v = en_k.get(k)
        if v is None:
            for lg in ("pt-BR", "es", "de"):
                v = d[(lg, "K")].get(k)
                if v:
                    break
        items[("K", k)] = v or k
    # skip long data/prompt texts that no language translates
    others = [lg for lg in {l for (l, _k) in d} if lg != "en"]
    skipped = []
    for (kind, k), src in list(items.items()):
        if len(src) < 60:
            continue
        same = 0
        for lg in others:
            v = d[(lg, kind)].get(k)
            if v is not None and v == src:
                same += 1
        if same >= SKIP_LONG_SAME:
            skipped.append(k)
            del items[(kind, k)]
    print(f"items: {len(items)} (skipped {len(skipped)} untranslated-by-design long texts)")
    return items


def split_item(src: str):
    """-> (newline, [lines]) ; each line -> list of '|' parts"""
    nl = "\r\n" if "\r\n" in src else ("\n" if "\n" in src else "")
    lines = re.split(r"\r\n|\n|\r", src)
    return nl, lines


def parts_of(line: str):
    return line.split("|")


def lead_trail(part: str):
    m = re.match(r"^(\s*)(.*?)(\s*)$", part, re.S)
    return m.group(1), m.group(2), m.group(3)


def build_segments(items):
    segs: dict[str, Seg] = {}
    for (_kind, _k), src in items.items():
        nl, lines = split_item(src)
        for line in lines:
            for part in parts_of(line):
                _l, core, _t = lead_trail(part)
                if core and has_letters(core) and not is_codeish(core):
                    s = Seg(core)
                    if re.search(r"[A-Za-z]{2,}", re.sub(r"\{\d+\}", "", s.protected)):
                        segs.setdefault(s.protected, s)
    return segs


def is_codeish(core: str) -> bool:
    letters = len(re.findall(r"[A-Za-z]", core))
    return letters < 2


_MARKS_RE = re.compile("[\u0591-\u05bd\u05bf\u05c1\u05c2\u05c4\u05c5\u05c7\u064b-\u065f\u0670]")


def strip_marks(s: str) -> str:
    """Hebrew niqqud / cantillation and Arabic harakat are not used in UI text."""
    return _MARKS_RE.sub("", s)


def translate_item(src: str, lang: str, cache: dict, ovr: dict) -> str | None:
    nl, lines = split_item(src)
    out_lines = []
    changed = False
    for line in lines:
        new_parts = []
        for part in parts_of(line):
            lead, core, trail = lead_trail(part)
            if not core or not has_letters(core) or is_codeish(core):
                new_parts.append(part)
                continue
            if core in ovr:
                new_parts.append(lead + ovr[core] + trail)
                changed = True
                continue
            seg = Seg(core)
            if seg.accel:
                plain = ACCEL_RE.sub(lambda mo: mo.group(1), core, count=1)
                if plain in ovr:
                    o = ovr[plain]
                    if len(core) <= 40 and "\n" not in core:
                        o = o + " (&%s)" % seg.accel
                    new_parts.append(lead + o + trail)
                    changed = True
                    continue
            if not re.search(r"[A-Za-z]{2,}", re.sub(r"\{\d+\}", "", seg.protected)):
                new_parts.append(part)
                continue
            t = cache.get(seg.protected)
            if not t:
                return None
            restored = seg.restore(t)
            if restored is None:
                return None
            restored = strip_marks(restored.strip())
            if seg.accel and len(core) <= 40 and "\n" not in core:
                restored = restored + " (&%s)" % seg.accel
            new_parts.append(lead + restored + trail)
            changed = True
        out_lines.append("|".join(new_parts))
    if not changed:
        return None
    return (nl or "\n").join(out_lines) if len(out_lines) > 1 else out_lines[0]


# --------------------------------------------------------------------------- emit

def pas_lit(s: str, piece: int = 70) -> str:
    if s == "":
        return "''"
    chunks = [s[i : i + piece] for i in range(0, len(s), piece)]
    out = []
    for ch in chunks:
        buf = []
        inq = False
        for c in ch:
            o = ord(c)
            if 32 <= o < 127:
                if not inq:
                    buf.append("'")
                    inq = True
                buf.append("''" if c == "'" else c)
            else:
                if inq:
                    buf.append("'")
                    inq = False
                buf.append("#%d" % o)
        if inq:
            buf.append("'")
        out.append("".join(buf))
    if len(out) == 1:
        return out[0]
    return "\n    + ".join(out)


def emit(results: dict[str, dict[tuple[str, str], str]]) -> None:
    lines = [
        "unit uI18nRtl;",
        "",
        "{ GENERATED by tools\\gen_rtl_i18n.py - do not edit by hand.",
        "  Arabic (ar) and Hebrew (he) UI translations. Keys are the same English texts / IDs",
        "  used by the 14 base languages in uI18n.pas. Missing keys fall back to English.",
        "  Non-ASCII characters are written as #nnn so the file is editor/bidi safe. }",
        "",
        "interface",
        "",
        "type",
        "  { IsText = True: English-text table (TrText); False: ID-key table (Tr). }",
        "  TRtlPutProc = procedure(const IsText: Boolean; const K, V: string);",
        "",
        "procedure AddArabicTranslations(const Put: TRtlPutProc);",
        "procedure AddHebrewTranslations(const Put: TRtlPutProc);",
        "",
        "implementation",
        "",
    ]
    CH = 120
    for lang in ("ar", "he"):
        name = LANGS[lang][2]
        entries = sorted(results.get(lang, {}).items(), key=lambda kv: (kv[0][0], kv[0][1].lower()))
        nparts = max(1, (len(entries) + CH - 1) // CH)
        for p in range(nparts):
            lines.append(f"procedure Add{name}Part{p + 1:02d}(const Put: TRtlPutProc);")
            lines.append("begin")
            for (kind, k), v in entries[p * CH : (p + 1) * CH]:
                lines.append(
                    f"  Put({'True' if kind == 'T' else 'False'},\n    {pas_lit(k)},\n    {pas_lit(v)});"
                )
            lines.append("end;")
            lines.append("")
        lines.append(f"procedure Add{name}Translations(const Put: TRtlPutProc);")
        lines.append("begin")
        for p in range(nparts):
            lines.append(f"  Add{name}Part{p + 1:02d}(Put);")
        lines.append("end;")
        lines.append("")
    lines.append("end.")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8-sig", newline="\r\n")
    print("wrote", OUT, sum(len(v) for v in results.values()), "entries")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", action="store_true", help="only emit from caches")
    ap.add_argument("--lang", choices=list(LANGS))
    ap.add_argument("--workers", type=int, default=6)
    a = ap.parse_args()

    d = load()
    items = collect_items(d)
    segs = build_segments(items)
    results: dict[str, dict] = {}
    for lang in LANGS:
        if a.lang and lang != a.lang:
            cache = load_cache(LANGS[lang][3])
        elif a.emit:
            cache = load_cache(LANGS[lang][3])
        else:
            cache = translate_segments(lang, segs, a.workers)
        ovr = OVERRIDES.get(lang, {})
        res = {}
        miss = 0
        for key, src in items.items():
            # whole-item override (exact English source)
            if src in ovr:
                res[key] = ovr[src]
                continue
            t = translate_item(src, lang, cache, ovr)
            if t is None:
                miss += 1
                continue
            res[key] = t
        print(f"[{lang}] translated {len(res)} / {len(items)} (missing {miss})")
        results[lang] = res
    emit(results)


if __name__ == "__main__":
    import multiprocessing

    multiprocessing.freeze_support()
    main()
