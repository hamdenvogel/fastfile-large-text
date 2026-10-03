"""Full i18n coverage audit for FastFile (14 languages).

Collects every UI string reachable by the translation layer:
  * TrText(<literal>) / ShowAppMessage(<literal>) in first-party .pas units
  * Tr('<key>', <default>) symbolic keys
  * DFM Caption / Hint / TextHint / Items.Strings / column captions
and checks which of the 14 GText* / G* tables in uI18n.pas lack an entry.

Also flags hardcoded literals that bypass translation entirely:
  * FastFileMsgInfo/Warn/Error/Success/YesNo('literal') without TrText
  * UpdateStatusBar('literal') without TrText / Tr
  * .Caption := 'literal' / .Hint := 'literal' in code

Writes tools/i18n_audit_report.txt and tools/i18n_missing.json.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
I18N = ROOT / "uI18n.pas"

LANGS = ["EN", "PT", "ES", "FR", "DE", "IT", "PL", "PTPT", "RO", "HU", "CZ", "JA", "ZHCN", "ZHTW"]
TEXT_TABLES = {
    "GTextEnglish": "EN", "GTextPortuguese": "PT", "GTextSpanish": "ES", "GTextFrench": "FR",
    "GTextGerman": "DE", "GTextItalian": "IT", "GTextPolish": "PL", "GTextPortuguesePT": "PTPT",
    "GTextRomanian": "RO", "GTextHungarian": "HU", "GTextCzech": "CZ", "GTextJapanese": "JA",
    "GTextChineseSimplified": "ZHCN", "GTextChineseTraditional": "ZHTW",
}
KEY_TABLES = {
    "GEnglish": "EN", "GPortuguese": "PT", "GSpanish": "ES", "GFrench": "FR", "GGerman": "DE",
    "GItalian": "IT", "GPolish": "PL", "GPortuguesePT": "PTPT", "GRomanian": "RO",
    "GHungarian": "HU", "GCzech": "CZ", "GJapanese": "JA", "GChineseSimplified": "ZHCN",
    "GChineseTraditional": "ZHTW",
}

# Units that are third-party / not UI.
SKIP_UNITS = {"uI18n.pas", "DSiWin32.pas", "FastMM4.pas", "uPosBMH.pas", "uMMF.pas", "uMMF_utf8.pas",
              "UnBufferedTextWriter.pas", "UnBufferedTextWriter_utf8.pas", "MyObjectList.pas",
              "StopWatch.pas", "ThreadUtilities.pas", "TLineReader.pas", "UnitInt64List.pas",
              "UnTemporaryFileStream.pas", "uTemporaryFileStream.pas", "UnTextFileStream.pas"}


def parse_literal(s, i):
    """Parse a Delphi string expression at s[i]: 'a''b'#233'c' + 'd' ...
    Returns (value, end) or (None, i) if no literal starts at i."""
    n = len(s)
    out = []
    got = False
    while True:
        j = i
        if not got:
            while j < n and s[j] in " \t\r\n":
                j += 1
        else:
            # Adjacent parts ('a'#13'b') or explicit '+' concatenation only;
            # whitespace-separated literals are distinct items (DFM Items.Strings).
            k = j
            while k < n and s[k] in " \t\r\n":
                k += 1
            if k < n and s[k] == "+":
                k += 1
                while k < n and s[k] in " \t\r\n":
                    k += 1
                if k < n and (s[k] == "'" or s[k] == "#"):
                    j = k
                else:
                    return "".join(out), i
            elif k != j:
                return "".join(out), i
        if j < n and s[j] == "'":
            j += 1
            buf = []
            while j < n:
                if s[j] == "'":
                    if j + 1 < n and s[j + 1] == "'":
                        buf.append("'")
                        j += 2
                        continue
                    j += 1
                    break
                if s[j] in "\r\n":
                    return (None, i) if not got else ("".join(out), i)
                buf.append(s[j])
                j += 1
            out.append("".join(buf))
            got = True
            i = j
            continue
        if j < n and s[j] == "#":
            m = re.match(r"#(\$[0-9A-Fa-f]+|\d+)", s[j:])
            if not m:
                break
            v = m.group(1)
            out.append(chr(int(v[1:], 16) if v.startswith("$") else int(v)))
            got = True
            i = j + len(m.group(0))
            continue
        break
    if not got:
        return None, i
    return "".join(out), i


def literal_args(s, i, count):
    """Parse `count` comma-separated literal args starting after '('."""
    vals = []
    for _ in range(count):
        v, j = parse_literal(s, i)
        if v is None:
            return None
        vals.append(v)
        while j < len(s) and s[j] in " \t\r\n":
            j += 1
        if len(vals) < count:
            if j >= len(s) or s[j] != ",":
                return None
            j += 1
        i = j
    return vals


def read(p):
    return p.read_text(encoding="utf-8", errors="replace")


def strip_comments(src):
    # remove { } and (* *) and // comments, keep string literals intact
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "'":
            j = i + 1
            while j < n:
                if src[j] == "'":
                    if j + 1 < n and src[j + 1] == "'":
                        j += 2
                        continue
                    break
                if src[j] == "\n":
                    break
                j += 1
            out.append(src[i:j + 1])
            i = j + 1
        elif c == "{" and not src.startswith("{$", i):
            j = src.find("}", i)
            j = n if j < 0 else j
            out.append(" " * 0 + "\n" * src.count("\n", i, j))
            i = j + 1
        elif src.startswith("(*", i):
            j = src.find("*)", i)
            j = n if j < 0 else j
            out.append("\n" * src.count("\n", i, j))
            i = j + 2
        elif src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def load_tables():
    t = strip_comments(read(I18N))
    text = {l: {} for l in LANGS}
    keyed = {l: {} for l in LANGS}
    for m in re.finditer(r"PutNV\(\s*(\w+)\s*,", t):
        tbl = m.group(1)
        vals = literal_args(t, m.end(), 2)
        if not vals:
            continue
        if tbl in TEXT_TABLES:
            text[TEXT_TABLES[tbl]][vals[0]] = vals[1]
        elif tbl in KEY_TABLES:
            keyed[KEY_TABLES[tbl]][vals[0]] = vals[1]
    for m in re.finditer(r"\b(?:RegexExamples_)?Set14\(", t):
        vals = literal_args(t, m.end(), 15)
        if not vals:
            continue
        k = vals[0]
        for l, v in zip(LANGS, vals[1:]):
            text[l][k] = v
    return text, keyed


def is_translatable(s):
    s2 = s.strip()
    if len(s2) < 2:
        return False
    if not re.search(r"[A-Za-z]{2}", s2):
        return False
    if re.fullmatch(r"[A-Za-z]:\\.*|\\\\.*|https?://\S+|[\w.-]+\.(ini|txt|log|exe|dll|json|csv|pas|dfm)", s2, re.I):
        return False
    if re.fullmatch(r"[A-Z0-9_]+", s2) and len(s2) <= 6:
        return False
    # Component / action identifiers left as design-time captions (ActionClear, Button1).
    if " " not in s2 and "." not in s2 and re.search(r"[a-z][A-Z0-9]", s2):
        return False
    # Leftover AlphaControls demo captions ("-Settings -") and non-UI tokens.
    if s2.startswith("-") and s2.endswith("-"):
        return False
    if s2 in NON_UI:
        return False
    if re.fullmatch(r"[\w.+-]+@[\w.-]+", s2) or re.fullmatch(r"(Ctrl|Alt|Shift)(\+\w+)+", s2):
        return False
    return True


NON_UI = {
    "FastFile", "PackFolder Test", "Hints showing is disabled \r\nin this demo by definition",
    "Hamden Vogel - All rights reserved.", "Developed by: Hamden Vogel",
    "Copyright (c) 2024, Hamden Vogel.\r\nAll rights reserved.", "Build time: ...",
    "Skinned menus", "Controls Enabled", "Embedded skins", "External skins",
    # MainUnit.dfm debug/test buttons and AlphaControls demo leftovers (never shown).
    "Test 3", "Test messagebox with checkbox", "Test read file", "test read file 2",
    "getLineFromOffSet(1) test", "test", "item 1", "hvogel",
    "Watermark may be configured in the<br><b>MainForm.sFloatSample</b> component.",
    "www.alphaskins.com/forum", "www.alphaskins.com/pchase.php", "www.alphaskins.com/showdoc.php",
    "GNU General Public Licence",
    # Prompt sent to the AI engine (English on purpose), not a UI caption.
    "SPLIT_PATTERN_AI_PROMPT_BODY",
}


def reachable_units():
    """Unit file names compiled into FastFile.exe (uses-closure from FastFile.dpr)."""
    by_name = {p.stem.lower(): p for p in ROOT.glob("*.pas")}
    seen = set()
    todo = []
    dpr = strip_comments(read(ROOT / "FastFile.dpr"))
    for m in re.finditer(r"\buses\b(.*?);", dpr, re.S | re.I):
        todo += [u.split(" in ")[0].strip().lower() for u in m.group(1).split(",")]
    while todo:
        u = todo.pop()
        if u in seen or u not in by_name:
            continue
        seen.add(u)
        src = strip_comments(read(by_name[u]))
        for m in re.finditer(r"\buses\b(.*?);", src, re.S | re.I):
            todo += [x.strip().split(" ")[0].lower() for x in m.group(1).split(",")]
    return {by_name[u].name for u in seen}


def collect_usage():
    trtext = {}   # text -> set(locations)
    trkeys = {}   # key -> (default, set(locations))
    raw = []      # (file, line, kind, text)
    dfm = {}      # text -> set(locations)
    live = reachable_units()
    for p in sorted(ROOT.glob("*.pas")):
        if p.name in SKIP_UNITS or p.name not in live:
            continue
        src = strip_comments(read(p))
        line_of = lambda pos: src.count("\n", 0, pos) + 1
        for m in re.finditer(r"\b(TrText|ShowAppMessage)\(", src):
            v, _ = parse_literal(src, m.end())
            if v is not None and is_translatable(v):
                trtext.setdefault(v, set()).add(f"{p.name}:{line_of(m.start())}")
        for m in re.finditer(r"\bTr\(", src):
            vals = literal_args(src, m.end(), 2)
            if vals:
                k, d = vals
                e = trkeys.setdefault(k, [d, set()])
                e[1].add(f"{p.name}:{line_of(m.start())}")
        for m in re.finditer(r"\b(FastFileMsgInfo|FastFileMsgWarn|FastFileMsgError|FastFileMsgSuccess|"
                             r"FastFileMsgYesNo|UpdateStatusBar|ShowMessage|MessageDlg)\(", src):
            v, _ = parse_literal(src, m.end())
            if v is not None and is_translatable(v):
                raw.append((p.name, line_of(m.start()), m.group(1), v))
        for m in re.finditer(r"\.(Caption|Hint|TextHint)\s*:=\s*", src):
            v, j = parse_literal(src, m.end())
            if v is None or not is_translatable(v):
                continue
            k = j
            while k < len(src) and src[k] in " \t":
                k += 1
            if k < len(src) and src[k] in ";\r\n" or src.startswith("end", k) or src.startswith("else", k):
                raw.append((p.name, line_of(m.start()), "." + m.group(1), v))
    for p in sorted(ROOT.glob("*.dfm")):
        if p.with_suffix(".pas").name not in live:
            continue
        src = read(p)
        for m in re.finditer(r"^\s*(Caption|Hint|TextHint|Title\.Caption)\s*=\s*", src, re.M):
            v, _ = parse_literal(src, m.end())
            if v is not None and is_translatable(v):
                dfm.setdefault(v, set()).add(f"{p.name}:{src.count(chr(10), 0, m.start()) + 1}")
        for m in re.finditer(r"Items\.Strings\s*=\s*\((.*?')\)\s*$", src, re.S | re.M):
            body = m.group(1)
            i = 0
            while i < len(body):
                v, j = parse_literal(body, i)
                if v is None:
                    i += 1
                    continue
                if is_translatable(v):
                    dfm.setdefault(v, set()).add(f"{p.name}:items")
                i = j
    return trtext, trkeys, raw, dfm


def main():
    text, keyed = load_tables()
    trtext, trkeys, raw, dfm = collect_usage()

    needed = {}
    for s, locs in trtext.items():
        needed.setdefault(s, set()).update(locs)
    for s, locs in dfm.items():
        needed.setdefault(s, set()).update(locs)

    missing = {}
    for s in sorted(needed):
        # Id-style keys (Hist.Foo) must also exist in English, plain text falls back to itself.
        pool = LANGS if (" " not in s and "." in s.strip(".")) else LANGS[1:]
        langs = [l for l in pool if s not in text[l]]
        if langs:
            missing[s] = {"langs": langs, "where": sorted(needed[s])[:4]}

    # Tr(key, default): covered if key is in the keyed table OR default is in the text table.
    missing_keys = {}
    for k, (d, locs) in sorted(trkeys.items()):
        langs = [l for l in LANGS[1:] if k not in keyed[l] and d not in text[l]]
        if langs and is_translatable(d):
            missing_keys[k] = {"default": d, "langs": langs, "where": sorted(locs)[:4]}
            e = missing.setdefault(d, {"langs": [], "where": sorted(locs)[:4]})
            e["langs"] = [l for l in LANGS[1:] if l in set(e["langs"]) | set(langs)]

    per_lang = {l: 0 for l in LANGS}
    for v in missing.values():
        for l in v["langs"]:
            per_lang[l] += 1
    per_lang_k = {l: 0 for l in LANGS[1:]}
    for v in missing_keys.values():
        for l in v["langs"]:
            per_lang_k[l] += 1

    lines = []
    lines.append(f"Strings needed (TrText/ShowAppMessage/DFM): {len(needed)}")
    lines.append(f"  missing in >=1 language: {len(missing)}")
    lines.append("  per language: " + ", ".join(f"{l}={c}" for l, c in per_lang.items()))
    lines.append(f"Symbolic Tr keys: {len(trkeys)}  missing in >=1 language: {len(missing_keys)}")
    lines.append("  per language: " + ", ".join(f"{l}={c}" for l, c in per_lang_k.items()))
    lines.append(f"Hardcoded literals bypassing translation: {len(raw)}")
    lines.append("")
    lines.append("[RAW literals]")
    for f, ln, kind, v in raw:
        lines.append(f"  {f}:{ln} {kind} {v!r}")
    lines.append("")
    lines.append("[Missing TrText/DFM]")
    for s, v in missing.items():
        lines.append(f"  {s!r}  missing={','.join(v['langs'])}  at={';'.join(v['where'])}")
    lines.append("")
    lines.append("[Missing Tr keys]")
    for k, v in missing_keys.items():
        lines.append(f"  {k} ({v['default']!r}) missing={','.join(v['langs'])}")

    (ROOT / "tools" / "i18n_audit_report.txt").write_text("\n".join(lines), encoding="utf-8")
    (ROOT / "tools" / "i18n_missing.json").write_text(
        json.dumps({"text": missing, "keys": missing_keys,
                    "raw": [list(r) for r in raw]}, ensure_ascii=False, indent=1),
        encoding="utf-8")
    print("\n".join(lines[:7]))


if __name__ == "__main__":
    sys.exit(main())
