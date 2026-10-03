# -*- coding: utf-8 -*-
"""
Add Simplified + Traditional Chinese as 13th/14th UI languages in uI18n.pas.

Phases:
  1) Plumbing (enums, tables, codes, Set12->Set14 bodies)
  2) Translate unique EN strings -> zh-CN / zh-TW (cached)
  3) Rewrite Set12 calls -> Set14 with ZHCN/ZHTW args
  4) Mirror PutNV(GTextJapanese,...) / PutNV(GTextEnglish,...) with Chinese
  5) language.option.* for both Chinese + native names in G* tables

Resumable via tools/zh_cn_cache.json and tools/zh_tw_cache.json.
"""
from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
BACKUP = ROOT / "tools" / "uI18n.pas.bak_before_zh"
CACHE_CN = ROOT / "tools" / "zh_cn_cache.json"
CACHE_TW = ROOT / "tools" / "zh_tw_cache.json"
LOG = ROOT / "tools" / "zh_i18n.log"
PROGRESS = ROOT / "tools" / "zh_i18n_progress.txt"

ATOM = r"(?:'(?:[^']|'')*'|#\d+)"
STR_EXPR = rf"(?:{ATOM})(?:\s*(?:\+\s*)?(?:{ATOM}))*"

KEEP_EN = {"-", "&", "...", "OK", "AI", "F1", "F5", "CSV", "CRLF", "UTF-8", "ANSI", "TAB", "PPI"}


def log(msg: str) -> None:
    print(msg, flush=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(msg + "\n")


def load_cache(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def save_cache(path: Path, cache: dict) -> None:
    path.write_text(json.dumps(cache, ensure_ascii=False, indent=0), encoding="utf-8")


def decode_pascal(expr: str) -> str:
    s = re.sub(r"\s*\+\s*", "", expr.strip().rstrip(",").strip())
    out = []
    i = 0
    n = len(s)
    while i < n:
        if s[i] == "'":
            i += 1
            buf = []
            while i < n:
                if s[i] == "'":
                    if i + 1 < n and s[i + 1] == "'":
                        buf.append("'")
                        i += 2
                        continue
                    i += 1
                    break
                buf.append(s[i])
                i += 1
            out.append("".join(buf))
        elif s[i] == "#":
            i += 1
            j = i
            while j < n and s[j].isdigit():
                j += 1
            if j > i:
                out.append(chr(int(s[i:j])))
                i = j
        else:
            i += 1
    return "".join(out)


def encode_pascal(text: str, max_line_bytes: int = 900) -> str:
    """Encode Unicode for Delphi UTF-8 source; split long lines with +."""
    parts: list[str] = []
    buf: list[str] = []

    def flush() -> None:
        if buf:
            parts.append("'" + "".join(buf).replace("'", "''") + "'")
            buf.clear()

    for ch in text:
        if ch == "\r":
            continue
        if ch == "\n":
            flush()
            parts.append("#13#10")
        else:
            buf.append(ch)
    flush()
    if not parts:
        return "''"

    # Pack into lines under UTF-8 byte budget
    lines: list[str] = []
    cur = ""
    for p in parts:
        cand = p if not cur else cur + " + " + p
        if len(cand.encode("utf-8")) > max_line_bytes and cur:
            lines.append(cur)
            cur = p
        else:
            cur = cand
    if cur:
        lines.append(cur)
    if len(lines) == 1:
        return lines[0]
    return ("\n    ").join(lines)


def skip_ws_comments(text: str, i: int) -> int:
    n = len(text)
    while i < n:
        if text[i] in " \t\r\n":
            i += 1
            continue
        if text.startswith("//", i):
            while i < n and text[i] not in "\r\n":
                i += 1
            continue
        if text[i] == "{":
            j = text.find("}", i + 1)
            if j < 0:
                return n
            i = j + 1
            continue
        break
    return i


def translate_one(text: str, to_lang: str, cache: dict, cache_path: Path) -> str:
    if text in cache and cache[text]:
        return cache[text]
    if not text or not text.strip():
        cache[text] = text
        return text
    stripped = text.strip()
    if stripped in KEEP_EN or len(stripped) <= 1:
        cache[text] = text
        return text

    amp_char = ""
    src = text
    amp_idx = text.find("&")
    if amp_idx >= 0 and amp_idx + 1 < len(text) and text[amp_idx + 1].isalnum():
        amp_char = text[amp_idx + 1]
        src = text[:amp_idx] + text[amp_idx + 1 :]

    import translators as ts

    ja = None
    last_err = None
    for attempt in range(6):
        try:
            ja = ts.translate_text(
                src, translator="bing", from_language="en", to_language=to_lang
            )
            break
        except Exception as e:
            last_err = e
            time.sleep(0.7 * (attempt + 1))
    if ja is None:
        log(f"TRANSLATE FAIL [{to_lang}]: {src[:60]!r} -> {last_err}")
        ja = text
    if amp_char and "&" not in ja:
        up, low = amp_char.upper(), amp_char.lower()
        for i, ch in enumerate(ja):
            if ch in (low, up):
                ja = ja[:i] + "&" + ja[i:]
                break
        else:
            ja = ja + "(&" + amp_char + ")"
    cache[text] = ja
    if len(cache) % 15 == 0:
        save_cache(cache_path, cache)
    time.sleep(0.12)
    return ja


def apply_plumbing(text: str) -> str:
    text = text.replace("\r\n", "\n")
    # Enum
    text = text.replace(
        "alPolish, alPortuguesePT, alRomanian, alHungarian, alCzech, alJapanese);",
        "alPolish, alPortuguesePT, alRomanian, alHungarian, alCzech, alJapanese,\n"
        "                   alChineseSimplified, alChineseTraditional);",
    )

    def ins_after(needle: str, insert: str) -> None:
        nonlocal text
        # Already inserted?
        check = insert.split("\n")[0].strip()
        if check and check in text:
            return
        if needle not in text:
            raise RuntimeError(f"missing needle: {needle!r}")
        text = text.replace(needle, needle + insert, 1)

    ins_after(
        "  GJapanese: TStringList = nil;\n",
        "  GChineseSimplified: TStringList = nil;\n"
        "  GChineseTraditional: TStringList = nil;\n",
    )
    ins_after(
        "  GTextJapanese: TStringList = nil;\n",
        "  GTextChineseSimplified: TStringList = nil;\n"
        "  GTextChineseTraditional: TStringList = nil;\n",
    )

    # Collapse
    ins_after(
        "  CollapseDuplicateKeysKeepLast(GJapanese);\n",
        "  CollapseDuplicateKeysKeepLast(GChineseSimplified);\n"
        "  CollapseDuplicateKeysKeepLast(GChineseTraditional);\n",
    )
    ins_after(
        "  CollapseDuplicateKeysKeepLast(GTextJapanese);\n",
        "  CollapseDuplicateKeysKeepLast(GTextChineseSimplified);\n"
        "  CollapseDuplicateKeysKeepLast(GTextChineseTraditional);\n",
    )

    # CustomSort
    ins_after(
        "  if Assigned(GJapanese)         then GJapanese.CustomSort(CompareTableByKey);\n",
        "  if Assigned(GChineseSimplified) then GChineseSimplified.CustomSort(CompareTableByKey);\n"
        "  if Assigned(GChineseTraditional) then GChineseTraditional.CustomSort(CompareTableByKey);\n",
    )
    ins_after(
        "  if Assigned(GTextJapanese)     then GTextJapanese.CustomSort(CompareTableByKey);\n",
        "  if Assigned(GTextChineseSimplified) then GTextChineseSimplified.CustomSort(CompareTableByKey);\n"
        "  if Assigned(GTextChineseTraditional) then GTextChineseTraditional.CustomSort(CompareTableByKey);\n",
    )

    # CreateTable in AddCommonTranslations
    ins_after(
        "  GJapanese       := CreateTable;\n",
        "  GChineseSimplified := CreateTable;\n"
        "  GChineseTraditional := CreateTable;\n",
    )
    ins_after(
        "  GTextJapanese   := CreateTable;\n",
        "  GTextChineseSimplified := CreateTable;\n"
        "  GTextChineseTraditional := CreateTable;\n",
    )
    ins_after(
        "  GTextJapanese.Assign(GTextEnglish);\n",
        "  GTextChineseSimplified.Assign(GTextEnglish);\n"
        "  GTextChineseTraditional.Assign(GTextEnglish);\n",
    )

    # FreeAndNil
    ins_after(
        "  FreeAndNil(GJapanese);\n",
        "  FreeAndNil(GChineseSimplified);\n"
        "  FreeAndNil(GChineseTraditional);\n",
    )
    ins_after(
        "  FreeAndNil(GTextJapanese);\n",
        "  FreeAndNil(GTextChineseSimplified);\n"
        "  FreeAndNil(GTextChineseTraditional);\n",
    )

    # TableForLanguage / TextTableForLanguage
    text = text.replace(
        "    alJapanese:     Result := GTextJapanese;\n  else\n    Result := GTextEnglish;",
        "    alJapanese:     Result := GTextJapanese;\n"
        "    alChineseSimplified: Result := GTextChineseSimplified;\n"
        "    alChineseTraditional: Result := GTextChineseTraditional;\n"
        "  else\n    Result := GTextEnglish;",
    )
    text = text.replace(
        "    alJapanese:     Result := GJapanese;\n  else\n    Result := GEnglish;",
        "    alJapanese:     Result := GJapanese;\n"
        "    alChineseSimplified: Result := GChineseSimplified;\n"
        "    alChineseTraditional: Result := GChineseTraditional;\n"
        "  else\n    Result := GEnglish;",
    )

    # AppLanguageFromCode / Code
    text = text.replace(
        "  else if (Normalized = 'ja') or (Normalized = 'ja-jp') or (Normalized = 'japanese') then\n"
        "    Result := alJapanese\n"
        "  else\n"
        "    Result := alEnglish;",
        "  else if (Normalized = 'ja') or (Normalized = 'ja-jp') or (Normalized = 'japanese') then\n"
        "    Result := alJapanese\n"
        "  else if (Normalized = 'zh-cn') or (Normalized = 'zh_cn') or (Normalized = 'zh-hans') or\n"
        "          (Normalized = 'zh-sg') or (Normalized = 'chinese_simplified') or (Normalized = 'chs') then\n"
        "    Result := alChineseSimplified\n"
        "  else if (Normalized = 'zh-tw') or (Normalized = 'zh_tw') or (Normalized = 'zh-hant') or\n"
        "          (Normalized = 'zh-hk') or (Normalized = 'zh-mo') or (Normalized = 'chinese_traditional') or\n"
        "          (Normalized = 'cht') then\n"
        "    Result := alChineseTraditional\n"
        "  else if (Normalized = 'zh') or (Normalized = 'chinese') then\n"
        "    Result := alChineseSimplified\n"
        "  else\n"
        "    Result := alEnglish;",
    )
    text = text.replace(
        "    alJapanese:     Result := 'ja';\n  else\n    Result := 'en';",
        "    alJapanese:     Result := 'ja';\n"
        "    alChineseSimplified: Result := 'zh-CN';\n"
        "    alChineseTraditional: Result := 'zh-TW';\n"
        "  else\n    Result := 'en';",
    )

    # Set12 signature -> Set14
    text = re.sub(
        r"procedure Set12\(const K: string;\s*"
        r"const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA: string\);",
        "procedure Set14(const K: string;\n"
        "    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA, ZHCN, ZHTW: string);",
        text,
    )
    # Set12 bodies PutNV Japanese -> add Chinese
    text = text.replace(
        "      PutNV(GTextJapanese, K, JA);\n  end;",
        "    PutNV(GTextJapanese, K, JA);\n"
        "    PutNV(GTextChineseSimplified, K, ZHCN);\n"
        "    PutNV(GTextChineseTraditional, K, ZHTW);\n"
        "  end;",
    )
    text = text.replace(
        "    PutNV(GTextJapanese, K, JA);\n  end;",
        "    PutNV(GTextJapanese, K, JA);\n"
        "    PutNV(GTextChineseSimplified, K, ZHCN);\n"
        "    PutNV(GTextChineseTraditional, K, ZHTW);\n"
        "  end;",
    )
    # Rename remaining procedure Set12( that might use different formatting
    text = text.replace("procedure Set12(", "procedure Set14(")

    # RegexExamples_Set12 -> Set14
    text = text.replace(
        "procedure RegexExamples_Set12(const K: string; const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA: string);",
        "procedure RegexExamples_Set14(const K: string; const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA, ZHCN, ZHTW: string);",
    )
    text = text.replace(
        "  PutNV(GTextJapanese, K, JA);\nend;\n\nprocedure AddCommonTranslationsRegexExamplesPart1;",
        "  PutNV(GTextJapanese, K, JA);\n"
        "  PutNV(GTextChineseSimplified, K, ZHCN);\n"
        "  PutNV(GTextChineseTraditional, K, ZHTW);\n"
        "end;\n\nprocedure AddCommonTranslationsRegexExamplesPart1;",
    )
    text = text.replace("RegexExamples_Set12(", "RegexExamples_Set14(")

    # SPLIT_PATTERN AI prompt vars
    text = text.replace(
        "SP_AI_EN, SP_AI_PT, SP_AI_ES, SP_AI_FR, SP_AI_DE, SP_AI_IT, SP_AI_PL, SP_AI_PTPT, SP_AI_RO, SP_AI_HU, SP_AI_CZ, SP_AI_JA: string;",
        "SP_AI_EN, SP_AI_PT, SP_AI_ES, SP_AI_FR, SP_AI_DE, SP_AI_IT, SP_AI_PL, SP_AI_PTPT, SP_AI_RO, SP_AI_HU, SP_AI_CZ, SP_AI_JA, SP_AI_ZHCN, SP_AI_ZHTW: string;",
    )

    return text


def iter_set12_calls(text: str):
    """Yield (start, end, key_expr, lang_exprs) for Set12/Set14/RegexExamples_* calls."""
    for name in ("RegexExamples_Set14", "RegexExamples_Set12", "Set14", "Set12"):
        call_re = re.compile(rf"\b{name}\s*\(")
        pos = 0
        while True:
            m = call_re.search(text, pos)
            if not m:
                break
            line_start = text.rfind("\n", 0, m.start()) + 1
            if text[line_start : m.start()].lstrip().startswith("procedure "):
                pos = m.end()
                continue
            i = m.end()
            i = skip_ws_comments(text, i)
            km = re.match(STR_EXPR, text[i:])
            if not km:
                km = re.match(r"[A-Za-z_][A-Za-z0-9_]*", text[i:])
                if not km:
                    pos = m.end()
                    continue
            key = km.group(0)
            i += km.end()
            i = skip_ws_comments(text, i)
            if text[i] != ",":
                pos = m.end()
                continue
            i += 1
            langs = []
            ok = True
            while True:
                i = skip_ws_comments(text, i)
                em = re.match(STR_EXPR, text[i:])
                if not em:
                    em = re.match(r"[A-Za-z_][A-Za-z0-9_]*", text[i:])
                    if not em:
                        ok = False
                        break
                langs.append(em.group(0))
                i += em.end()
                i = skip_ws_comments(text, i)
                if text[i] == ",":
                    i += 1
                    continue
                if text[i] == ")":
                    i += 1
                    break
                ok = False
                break
            if ok and len(langs) in (12, 14):
                yield m.start(), i, key, langs, name
            pos = i if ok else m.end()


def inject_lang_options(text: str, cache_cn: dict, cache_tw: dict) -> str:
    if "language.option.chinese_simplified" in text:
        return text

    def enc(s: str) -> str:
        return encode_pascal(s)

    # Names of Chinese options in each UI language
    block = f"""
  PutNV(GEnglish, 'language.option.chinese_simplified', 'Chinese (Simplified)');
  PutNV(GPortuguese, 'language.option.chinese_simplified', 'Chin'#234's (Simplificado)');
  PutNV(GSpanish, 'language.option.chinese_simplified', 'Chino (Simplificado)');
  PutNV(GFrench, 'language.option.chinese_simplified', 'Chinois (simplifi'#233')');
  PutNV(GGerman, 'language.option.chinese_simplified', 'Chinesisch (vereinfacht)');
  PutNV(GItalian, 'language.option.chinese_simplified', 'Cinese (semplificato)');
  PutNV(GPolish, 'language.option.chinese_simplified', 'Chi'#324'ski (uproszczony)');
  PutNV(GPortuguesePT, 'language.option.chinese_simplified', 'Chin'#234's (Simplificado)');
  PutNV(GRomanian, 'language.option.chinese_simplified', 'Chinez'#259' (simplificat'#259')');
  PutNV(GHungarian, 'language.option.chinese_simplified', 'K'#237'nai (egyszer'#369's'#237'tett)');
  PutNV(GCzech, 'language.option.chinese_simplified', #268#237'n'#353'tina (zjednodu'#353'en'#225')');
  PutNV(GJapanese, 'language.option.chinese_simplified', {enc("中国語（簡体字）")});
  PutNV(GChineseSimplified, 'language.option.chinese_simplified', {enc("简体中文")});
  PutNV(GChineseTraditional, 'language.option.chinese_simplified', {enc("簡體中文")});

  PutNV(GEnglish, 'language.option.chinese_traditional', 'Chinese (Traditional)');
  PutNV(GPortuguese, 'language.option.chinese_traditional', 'Chin'#234's (Tradicional)');
  PutNV(GSpanish, 'language.option.chinese_traditional', 'Chino (Tradicional)');
  PutNV(GFrench, 'language.option.chinese_traditional', 'Chinois (traditionnel)');
  PutNV(GGerman, 'language.option.chinese_traditional', 'Chinesisch (traditionell)');
  PutNV(GItalian, 'language.option.chinese_traditional', 'Cinese (tradizionale)');
  PutNV(GPolish, 'language.option.chinese_traditional', 'Chi'#324'ski (tradycyjny)');
  PutNV(GPortuguesePT, 'language.option.chinese_traditional', 'Chin'#234's (Tradicional)');
  PutNV(GRomanian, 'language.option.chinese_traditional', 'Chinez'#259' (tradi'#539'ional'#259')');
  PutNV(GHungarian, 'language.option.chinese_traditional', 'K'#237'nai (hagyom'#225'nyos)');
  PutNV(GCzech, 'language.option.chinese_traditional', #268#237'n'#353'tina (tradi'#269'n'#237')');
  PutNV(GJapanese, 'language.option.chinese_traditional', {enc("中国語（繁体字）")});
  PutNV(GChineseSimplified, 'language.option.chinese_traditional', {enc("繁体中文")});
  PutNV(GChineseTraditional, 'language.option.chinese_traditional', {enc("繁體中文")});

  PutNV(GChineseSimplified, 'language.option.english', {enc("英语")});
  PutNV(GChineseSimplified, 'language.option.portuguese_brazil', {enc("葡萄牙语（巴西）")});
  PutNV(GChineseSimplified, 'language.option.spanish', {enc("西班牙语")});
  PutNV(GChineseSimplified, 'language.option.french', {enc("法语")});
  PutNV(GChineseSimplified, 'language.option.german', {enc("德语")});
  PutNV(GChineseSimplified, 'language.option.italian', {enc("意大利语")});
  PutNV(GChineseSimplified, 'language.option.polish', {enc("波兰语")});
  PutNV(GChineseSimplified, 'language.option.portuguese_portugal', {enc("葡萄牙语（葡萄牙）")});
  PutNV(GChineseSimplified, 'language.option.romanian', {enc("罗马尼亚语")});
  PutNV(GChineseSimplified, 'language.option.hungarian', {enc("匈牙利语")});
  PutNV(GChineseSimplified, 'language.option.czech', {enc("捷克语")});
  PutNV(GChineseSimplified, 'language.option.japanese', {enc("日语")});
  PutNV(GChineseSimplified, 'language.combo.hint', {enc("应用程序语言")});
  PutNV(GChineseSimplified, 'status.system_ready', {enc("系统就绪")});

  PutNV(GChineseTraditional, 'language.option.english', {enc("英語")});
  PutNV(GChineseTraditional, 'language.option.portuguese_brazil', {enc("葡萄牙語（巴西）")});
  PutNV(GChineseTraditional, 'language.option.spanish', {enc("西班牙語")});
  PutNV(GChineseTraditional, 'language.option.french', {enc("法語")});
  PutNV(GChineseTraditional, 'language.option.german', {enc("德語")});
  PutNV(GChineseTraditional, 'language.option.italian', {enc("義大利語")});
  PutNV(GChineseTraditional, 'language.option.polish', {enc("波蘭語")});
  PutNV(GChineseTraditional, 'language.option.portuguese_portugal', {enc("葡萄牙語（葡萄牙）")});
  PutNV(GChineseTraditional, 'language.option.romanian', {enc("羅馬尼亞語")});
  PutNV(GChineseTraditional, 'language.option.hungarian', {enc("匈牙利語")});
  PutNV(GChineseTraditional, 'language.option.czech', {enc("捷克語")});
  PutNV(GChineseTraditional, 'language.option.japanese', {enc("日語")});
  PutNV(GChineseTraditional, 'language.combo.hint', {enc("應用程式語言")});
  PutNV(GChineseTraditional, 'status.system_ready', {enc("系統就緒")});
"""
    anchor = "PutNV(GJapanese, 'language.option.japanese'"
    idx = text.find(anchor)
    if idx < 0:
        # insert before AddCommonTranslations end collapse
        marker = "  CollapseAllTranslationTables;"
        if marker not in text:
            raise RuntimeError("lang option anchor missing")
        return text.replace(marker, block + "\n" + marker, 1)
    # find end of japanese option block (after last PutNV(GJapanese, 'language.option
    # Insert after the japanese language.option.japanese line's statement
    semi = text.find(";", idx)
    return text[: semi + 1] + "\n" + block + text[semi + 1 :]


def collect_english_strings(text: str) -> list[str]:
    seen = set()
    out = []

    def add(s: str) -> None:
        if s not in seen:
            seen.add(s)
            out.append(s)

    for _a, _b, _k, langs, _name in iter_set12_calls(text):
        if langs:
            add(decode_pascal(langs[0]))

    # PutNV(GTextEnglish, key, val)
    for m in re.finditer(
        r"PutNV\(GTextEnglish,\s*(" + STR_EXPR + r")\s*,\s*(" + STR_EXPR + r")\s*\)\s*;",
        text,
    ):
        add(decode_pascal(m.group(2)))
        # also key when key==english phrase tables
        add(decode_pascal(m.group(1)))

    return out


def rewrite_set_calls(text: str, cache_cn: dict, cache_tw: dict) -> str:
    out = []
    last = 0
    n = 0
    # MUST process in document order — iter_set12_calls groups by name.
    calls = sorted(list(iter_set12_calls(text)), key=lambda x: x[0])
    for start, end, key, langs, name in calls:
        if start < last:
            # Overlap from a previous longer match — skip
            continue
        out.append(text[last:start])
        proc = "Set14"
        if "RegexExamples" in name:
            proc = "RegexExamples_Set14"
        if len(langs) == 14:
            chunk = text[start:end]
            if name.endswith("Set12"):
                chunk = chunk.replace(name + "(", proc + "(", 1)
            out.append(chunk)
            last = end
            continue
        en_src = langs[0]
        if en_src.startswith("SP_AI_"):
            parts = [f"{proc}(", f"    {key},"] if "\n" in text[start:end] else None
            if parts is None:
                args = ", ".join([key] + langs + ["SP_AI_ZHCN", "SP_AI_ZHTW"])
                out.append(f"{proc}({args})")
            else:
                for e in langs:
                    parts.append(f"    {e},")
                parts.append("    SP_AI_ZHCN,")
                parts.append("    SP_AI_ZHTW)")
                out.append("\n".join(parts))
            last = end
            n += 1
            continue
        en = decode_pascal(en_src)
        zhcn = cache_cn.get(en, en)
        zhtw = cache_tw.get(en, en)
        parts = [f"{proc}(", f"    {key},"]
        for e in langs:
            parts.append(f"    {e},")
        parts.append(f"    {encode_pascal(zhcn)},")
        parts.append(f"    {encode_pascal(zhtw)})")
        out.append("\n".join(parts))
        last = end
        n += 1
        if n % 100 == 0:
            log(f"  rewrite Set14 {n}")
    out.append(text[last:])
    log(f"Rewrote Set12->Set14 calls: {n}")
    return "".join(out)


def mirror_putnv_japanese(text: str, cache_cn: dict, cache_tw: dict) -> str:
    """After each PutNV(GTextJapanese, K, V) add CN/TW if missing."""
    lines = text.splitlines(keepends=True)
    new_lines = []
    added = 0
    for i, line in enumerate(lines):
        new_lines.append(line)
        m = re.match(
            r"(\s*)PutNV\(GTextJapanese,\s*(" + STR_EXPR + r"|K)\s*,\s*(" + STR_EXPR + r"|JA|ZHCN|ZHTW)\s*\)\s*;(\s*)$",
            line,
        )
        if not m:
            continue
        indent, key_expr, val_expr, ws = m.groups()
        # skip Set14 body lines using JA identifier
        if val_expr.strip() in {"JA", "ZHCN", "ZHTW"}:
            continue
        nxt = "".join(lines[i + 1 : i + 3])
        if "PutNV(GTextChineseSimplified" in nxt:
            continue
        # Prefer translating English key text when key is a string literal
        if key_expr.startswith("'") or key_expr.startswith("#"):
            key_txt = decode_pascal(key_expr)
            # Prefer EN value from matching PutNV(GTextEnglish) if key is phrase
            en = key_txt
            zhcn = cache_cn.get(en) or translate_one(en, "zh-Hans", cache_cn, CACHE_CN)
            zhtw = cache_tw.get(en) or translate_one(en, "zh-Hant", cache_tw, CACHE_TW)
        else:
            # variable key — translate Japanese value as source? better skip
            continue
        new_lines.append(
            f"{indent}PutNV(GTextChineseSimplified, {key_expr}, {encode_pascal(zhcn)});{ws}"
        )
        new_lines.append(
            f"{indent}PutNV(GTextChineseTraditional, {key_expr}, {encode_pascal(zhtw)});{ws}"
        )
        added += 1
        if added % 50 == 0:
            save_cache(CACHE_CN, cache_cn)
            save_cache(CACHE_TW, cache_tw)
            log(f"  mirror JA PutNV {added}")
    log(f"Mirrored Japanese PutNV -> CN/TW: {added}")
    return "".join(new_lines)


def mirror_putnv_english_gaps(text: str, cache_cn: dict, cache_tw: dict) -> str:
    """For PutNV(GTextEnglish) without Chinese nearby, add CN/TW."""
    lines = text.splitlines(keepends=True)
    new_lines = []
    added = 0
    for i, line in enumerate(lines):
        new_lines.append(line)
        m = re.match(
            r"(\s*)PutNV\(GTextEnglish,\s*(" + STR_EXPR + r")\s*,\s*(" + STR_EXPR + r")\s*\)\s*;(\s*)$",
            line,
        )
        if not m:
            continue
        indent, key_expr, val_expr, ws = m.groups()
        # look ahead up to 20 lines for Chinese
        window = "".join(lines[i : i + 20])
        if "PutNV(GTextChineseSimplified, " + key_expr in window:
            continue
        # also check if same key appears later in file for Chinese - skip heavy; just check window
        en = decode_pascal(val_expr)
        zhcn = cache_cn.get(en) or translate_one(en, "zh-Hans", cache_cn, CACHE_CN)
        zhtw = cache_tw.get(en) or translate_one(en, "zh-Hant", cache_tw, CACHE_TW)
        # Insert after the Japanese line of this cluster if present
        # Find cluster end: last PutNV for same key in following lines
        insert_at = len(new_lines)  # after current
        j = i + 1
        while j < len(lines):
            if f"PutNV(GText" in lines[j] and key_expr in lines[j]:
                insert_at = len(new_lines) + (j - i)
                j += 1
                continue
            break
        # We'll append after current line for simplicity, then Chinese may be mid-cluster —
        # better append after scanning cluster without modifying insert_at mid-loop.
        # Simpler: append CN/TW immediately after English; collapse keeps last wins.
        new_lines.append(
            f"{indent}PutNV(GTextChineseSimplified, {key_expr}, {encode_pascal(zhcn)});{ws}"
        )
        new_lines.append(
            f"{indent}PutNV(GTextChineseTraditional, {key_expr}, {encode_pascal(zhtw)});{ws}"
        )
        added += 1
        if added % 40 == 0:
            save_cache(CACHE_CN, cache_cn)
            save_cache(CACHE_TW, cache_tw)
            log(f"  mirror EN PutNV {added}")
    log(f"Mirrored English PutNV gaps -> CN/TW: {added}")
    return "".join(new_lines)


def ensure_bom_utf8(path: Path, text: str) -> None:
    text = text.replace("\r\n", "\n").replace("\n", "\r\n")
    path.write_bytes(b"\xef\xbb\xbf" + text.encode("utf-8"))


def main() -> int:
    LOG.write_text("", encoding="utf-8")
    log("=== Chinese i18n start ===")
    raw = UI18N.read_bytes()
    if not BACKUP.exists():
        BACKUP.write_bytes(raw)
        log(f"Backup -> {BACKUP}")

    text = raw.decode("utf-8-sig") if raw.startswith(b"\xef\xbb\xbf") else raw.decode("utf-8")

    cache_cn = load_cache(CACHE_CN)
    cache_tw = load_cache(CACHE_TW)
    log(f"Cache CN={len(cache_cn)} TW={len(cache_tw)}")

    log("Collecting English strings...")
    ens = collect_english_strings(text)
    log(f"Unique EN strings: {len(ens)}")

    pending = [
        s
        for s in ens
        if s not in cache_cn
        or not cache_cn.get(s)
        or (cache_cn.get(s) == s and s.strip() not in KEEP_EN and len(s.strip()) > 1)
    ]
    log(f"Pending zh-Hans translate: {len(pending)}")
    for i, s in enumerate(pending, 1):
        translate_one(s, "zh-Hans", cache_cn, CACHE_CN)
        PROGRESS.write_text(f"CN {i}/{len(pending)}\n{s[:120]}\n", encoding="utf-8")
        if i % 20 == 0:
            save_cache(CACHE_CN, cache_cn)
            log(f"  CN {i}/{len(pending)}")
    save_cache(CACHE_CN, cache_cn)

    pending_tw = [
        s
        for s in ens
        if s not in cache_tw
        or not cache_tw.get(s)
        or (cache_tw.get(s) == s and s.strip() not in KEEP_EN and len(s.strip()) > 1)
    ]
    log(f"Pending zh-Hant translate: {len(pending_tw)}")
    for i, s in enumerate(pending_tw, 1):
        translate_one(s, "zh-Hant", cache_tw, CACHE_TW)
        PROGRESS.write_text(f"TW {i}/{len(pending_tw)}\n{s[:120]}\n", encoding="utf-8")
        if i % 20 == 0:
            save_cache(CACHE_TW, cache_tw)
            log(f"  TW {i}/{len(pending_tw)}")
    save_cache(CACHE_TW, cache_tw)

    log("Plumbing...")
    text = apply_plumbing(text)
    log("Lang options...")
    text = inject_lang_options(text, cache_cn, cache_tw)

    # SP_AI Chinese prompts (translate from EN assignment if present)
    if "SP_AI_ZHCN" in text and "SP_AI_ZHCN :=" not in text and "SP_AI_ZHCN:=" not in text:
        m = re.search(r"SP_AI_EN\s*:=\s*(.+?);\s*\n", text, re.S)
        if m:
            en_prompt = decode_pascal(m.group(1))
            zhcn = translate_one(en_prompt, "zh-Hans", cache_cn, CACHE_CN)
            zhtw = translate_one(en_prompt, "zh-Hant", cache_tw, CACHE_TW)
            ja_assign = re.search(r"SP_AI_JA\s*:=\s*.+?;\s*\n", text, re.S)
            if ja_assign:
                insert = (
                    f"  SP_AI_ZHCN := {encode_pascal(zhcn)};\n"
                    f"  SP_AI_ZHTW := {encode_pascal(zhtw)};\n"
                )
                text = text[: ja_assign.end()] + insert + text[ja_assign.end() :]
                log("Injected SP_AI_ZHCN / SP_AI_ZHTW")

    log("Rewrite Set calls...")
    text = rewrite_set_calls(text, cache_cn, cache_tw)
    log("Mirror Japanese PutNV...")
    text = mirror_putnv_japanese(text, cache_cn, cache_tw)
    save_cache(CACHE_CN, cache_cn)
    save_cache(CACHE_TW, cache_tw)
    log("Mirror English PutNV gaps...")
    text = mirror_putnv_english_gaps(text, cache_cn, cache_tw)
    save_cache(CACHE_CN, cache_cn)
    save_cache(CACHE_TW, cache_tw)

    ensure_bom_utf8(UI18N, text)
    log(f"Wrote {UI18N}")
    log(f"Set14~={text.count('Set14(')} Set12 left={text.count('Set12(')}")
    log(f"PutNV CN={text.count('PutNV(GTextChineseSimplified')} TW={text.count('PutNV(GTextChineseTraditional')}")
    log(f"cache CN={len(cache_cn)} TW={len(cache_tw)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
