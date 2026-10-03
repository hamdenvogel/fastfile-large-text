# -*- coding: utf-8 -*-
"""Restore Japanese plumbing + finish remaining gaps in uI18n.pas."""
from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
UNCONSTS = ROOT / "src" / "UnConsts.pas"
CACHE = ROOT / "tools" / "ja_translation_cache.json"

ATOM = r"(?:'(?:[^']|'')*'|#\d+)"
STR_EXPR = rf"(?:{ATOM})(?:\s*(?:\+\s*)?(?:{ATOM}))*"


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=0), encoding="utf-8")


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


def encode_pascal(text: str) -> str:
    parts = []
    buf = []

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
    return "".join(parts) if parts else "''"


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
        if text.startswith("(*", i):
            j = text.find("*)", i + 2)
            if j < 0:
                return n
            i = j + 2
            continue
        break
    return i


def translate_one(text: str, cache: dict) -> str:
    if text in cache:
        return cache[text]
    if not text or not text.strip():
        cache[text] = text
        return text
    stripped = text.strip()
    if stripped in {"-", "&", "...", "OK", "AI", "F1", "F5", "CSV", "CRLF", "UTF-8", "ANSI", "TAB"}:
        cache[text] = text
        return text
    if len(stripped) <= 1:
        cache[text] = text
        return text

    amp_char = ""
    src = text
    amp_idx = text.find("&")
    if amp_idx >= 0 and amp_idx + 1 < len(text) and text[amp_idx + 1].isalnum():
        amp_char = text[amp_idx + 1]
        src = text[:amp_idx] + text[amp_idx + 1 :]

    import translators as ts

    last_err = None
    ja = None
    for attempt in range(6):
        try:
            ja = ts.translate_text(src, translator="bing", from_language="en", to_language="ja")
            break
        except Exception as e:
            last_err = e
            time.sleep(0.8 * (attempt + 1))
    if ja is None:
        print(f"TRANSLATE FAIL: {src[:60]!r} -> {last_err}", flush=True)
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
    save_cache(cache)
    time.sleep(0.15)
    return ja


def parse_call_langs(text: str, i: int, n_langs: int):
    langs = []
    for li in range(n_langs):
        i = skip_ws_comments(text, i)
        em = re.match(STR_EXPR, text[i:])
        if not em:
            raise RuntimeError(f"lang {li} parse fail near {text[i:i+80]!r}")
        langs.append(em.group(0))
        i += em.end()
        i = skip_ws_comments(text, i)
        if li < n_langs - 1:
            if text[i] != ",":
                raise RuntimeError(f"comma after lang {li}")
            i += 1
        else:
            if text[i] != ")":
                raise RuntimeError("expected )")
            i += 1
    return langs, i


def restore_plumbing(text: str) -> str:
    if "GJapanese:" not in text:
        text = text.replace(
            "  GCzech: TStringList = nil;\n",
            "  GCzech: TStringList = nil;\n  GJapanese: TStringList = nil;\n",
            1,
        )
        print("+ GJapanese var")
    if "GTextJapanese:" not in text:
        text = text.replace(
            "  GTextCzech: TStringList = nil;\n",
            "  GTextCzech: TStringList = nil;\n  GTextJapanese: TStringList = nil;\n",
            1,
        )
        print("+ GTextJapanese var")

    if "GJapanese.CustomSort" not in text:
        text = text.replace(
            "  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);\n",
            "  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);\n"
            "  if Assigned(GJapanese)         then GJapanese.CustomSort(CompareTableByKey);\n",
            1,
        )
    if "GTextJapanese.CustomSort" not in text:
        text = text.replace(
            "  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);\n",
            "  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);\n"
            "  if Assigned(GTextJapanese)     then GTextJapanese.CustomSort(CompareTableByKey);\n",
            1,
        )

    if "GJapanese       := CreateTable" not in text and "GJapanese := CreateTable" not in text:
        text = text.replace(
            "  GCzech          := CreateTable;\n",
            "  GCzech          := CreateTable;\n  GJapanese       := CreateTable;\n",
            1,
        )
        print("+ GJapanese CreateTable")
    if "GTextJapanese   := CreateTable" not in text and "GTextJapanese := CreateTable" not in text:
        text = text.replace(
            "  GTextCzech      := CreateTable;\n",
            "  GTextCzech      := CreateTable;\n"
            "  GTextJapanese   := CreateTable;\n"
            "  GTextJapanese.Assign(GTextEnglish);\n",
            1,
        )
        print("+ GTextJapanese CreateTable + early Assign")

    # remove mid Assign if present (keep only early)
    text = text.replace(
        "  GTextCzech.Assign(GTextEnglish);\n  GTextJapanese.Assign(GTextEnglish);\n",
        "  GTextCzech.Assign(GTextEnglish);\n",
        1,
    )

    if "FreeAndNil(GJapanese)" not in text:
        text = text.replace(
            "  FreeAndNil(GCzech);\n",
            "  FreeAndNil(GCzech);\n  FreeAndNil(GJapanese);\n",
            1,
        )
    if "FreeAndNil(GTextJapanese)" not in text:
        text = text.replace(
            "  FreeAndNil(GTextCzech);\n",
            "  FreeAndNil(GTextCzech);\n  FreeAndNil(GTextJapanese);\n",
            1,
        )

    if "alJapanese:     Result := GTextJapanese" not in text:
        text = text.replace(
            "    alCzech:        Result := GTextCzech;\n  else\n    Result := GTextEnglish;",
            "    alCzech:        Result := GTextCzech;\n"
            "    alJapanese:     Result := GTextJapanese;\n"
            "  else\n    Result := GTextEnglish;",
            1,
        )
        print("+ TextTableForLanguage alJapanese")
    if "alJapanese:     Result := GJapanese" not in text:
        text = text.replace(
            "    alCzech:        Result := GCzech;\n  else\n    Result := GEnglish;",
            "    alCzech:        Result := GCzech;\n"
            "    alJapanese:     Result := GJapanese;\n"
            "  else\n    Result := GEnglish;",
            1,
        )
        print("+ TableForLanguage alJapanese")

    if "Normalized = 'ja'" not in text:
        text = text.replace(
            "  else if (Normalized = 'cs') or (Normalized = 'cs-cz') or (Normalized = 'czech') then\n"
            "    Result := alCzech\n"
            "  else\n"
            "    Result := alEnglish;",
            "  else if (Normalized = 'cs') or (Normalized = 'cs-cz') or (Normalized = 'czech') then\n"
            "    Result := alCzech\n"
            "  else if (Normalized = 'ja') or (Normalized = 'ja-jp') or (Normalized = 'japanese') then\n"
            "    Result := alJapanese\n"
            "  else\n"
            "    Result := alEnglish;",
            1,
        )
        print("+ AppLanguageFromCode ja")
    if "alJapanese:     Result := 'ja'" not in text:
        text = text.replace(
            "    alCzech:        Result := 'cs';\n  else\n    Result := 'en';",
            "    alCzech:        Result := 'cs';\n"
            "    alJapanese:     Result := 'ja';\n"
            "  else\n    Result := 'en';",
            1,
        )
        print("+ AppLanguageCode ja")

    # Fix every Set12 nested procedure body to assign JA
    pat = re.compile(
        r"(procedure Set12\(const K: string;\s*"
        r"const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA: string\);\s*"
        r"begin\s*"
        r"GTextEnglish\.Values\[K\] := EN;\s*"
        r"GTextPortuguese\.Values\[K\] := PT;\s*"
        r"GTextSpanish\.Values\[K\] := ES;\s*"
        r"GTextFrench\.Values\[K\] := FR;\s*"
        r"GTextGerman\.Values\[K\] := DE;\s*"
        r"GTextItalian\.Values\[K\] := IT;\s*"
        r"GTextPolish\.Values\[K\] := PL;\s*"
        r"GTextPortuguesePT\.Values\[K\] := PTPT;\s*"
        r"GTextRomanian\.Values\[K\] := RO;\s*"
        r"GTextHungarian\.Values\[K\] := HU;\s*"
        r"GTextCzech\.Values\[K\] := CZ;\s*)"
        r"(GTextJapanese\.Values\[K\] := JA;\s*)?"
        r"(end;)",
        re.S,
    )

    def repl_set12(m: re.Match) -> str:
        return m.group(1) + "    GTextJapanese.Values[K] := JA;\n  " + m.group(3)

    text2, n = pat.subn(repl_set12, text)
    print(f"Set12 bodies with JA assign: {n}")
    text = text2
    return text


def fix_language_option(text: str) -> str:
    if "GEnglish.Values['language.option.japanese']" in text:
        print("language.option.japanese already present")
        return text
    block = """
  GEnglish.Values['language.option.japanese']      := 'Japanese';
  GPortuguese.Values['language.option.japanese']   := 'Japon'#234's';
  GSpanish.Values['language.option.japanese']      := 'Japon'#233's';
  GFrench.Values['language.option.japanese']       := 'Japonais';
  GGerman.Values['language.option.japanese']       := 'Japanisch';
  GItalian.Values['language.option.japanese']      := 'Giapponese';
  GPolish.Values['language.option.japanese']       := 'Japo'#241'ski';
  GPortuguesePT.Values['language.option.japanese'] := 'Japon'#234's';
  GRomanian.Values['language.option.japanese']     := 'Japonez'#227';
  GHungarian.Values['language.option.japanese']    := 'Jap'#225'n';
  GCzech.Values['language.option.japanese']        := 'Japon'#353'tina';
  GJapanese.Values['language.option.japanese']     := '日本語';
  GJapanese.Values['language.option.english'] := '英語';
  GJapanese.Values['language.option.portuguese_brazil'] := 'ポルトガル語（ブラジル）';
  GJapanese.Values['language.option.spanish'] := 'スペイン語';
  GJapanese.Values['language.option.french'] := 'フランス語';
  GJapanese.Values['language.option.german'] := 'ドイツ語';
  GJapanese.Values['language.option.italian'] := 'イタリア語';
  GJapanese.Values['language.option.polish'] := 'ポーランド語';
  GJapanese.Values['language.option.portuguese_portugal'] := 'ポルトガル語（ポルトガル）';
  GJapanese.Values['language.option.romanian'] := 'ルーマニア語';
  GJapanese.Values['language.option.hungarian'] := 'ハンガリー語';
  GJapanese.Values['language.option.czech'] := 'チェコ語';
"""
    anchor = "  GCzech.Values['language.option.czech']        := #200'e'#154'tina';\nend;"
    if anchor not in text:
        raise RuntimeError("language.option czech anchor missing")
    text = text.replace(
        anchor,
        "  GCzech.Values['language.option.czech']        := #200'e'#154'tina';\n" + block + "end;",
        1,
    )
    text = text.replace(
        "  { language.option.japanese removed ? Japanese replaced by new languages }\n",
        "  { language.option.japanese restored as 12th UI language }\n",
        1,
    )
    print("Added language.option.japanese")
    return text


def fix_tagline(text: str, cache: dict) -> str:
    if "Set11(TAGLINE_KEY" not in text:
        print("TAGLINE already fixed or missing")
        return text
    start = text.find("Set11(TAGLINE_KEY")
    i = start + len("Set11(")
    i = skip_ws_comments(text, i)
    assert text.startswith("TAGLINE_KEY", i)
    i += len("TAGLINE_KEY")
    i = skip_ws_comments(text, i)
    assert text[i] == ","
    i += 1
    args = []
    for li in range(11):
        i = skip_ws_comments(text, i)
        if text.startswith("TAGLINE_KEY", i):
            args.append("TAGLINE_KEY")
            i += len("TAGLINE_KEY")
        else:
            em = re.match(STR_EXPR, text[i:])
            if not em:
                raise RuntimeError(f"TAGLINE arg {li}")
            args.append(em.group(0))
            i += em.end()
        i = skip_ws_comments(text, i)
        if li < 10:
            assert text[i] == ","
            i += 1
        else:
            assert text[i] == ")"
            i += 1
    m = re.search(r"TAGLINE_KEY\s*=\s*((?:'(?:[^']|'')*'|#\d+|\s|\+)+);", text)
    ja_expr = encode_pascal(translate_one(decode_pascal(m.group(1)), cache))
    new_call = "Set12(\n    TAGLINE_KEY,\n    " + ",\n    ".join(args) + ",\n    " + ja_expr + ")"
    text = text[:start] + new_call + text[i:]
    print("TAGLINE fixed")
    return text


def fix_regex_examples(text: str, cache: dict) -> str:
    old_sig = (
        "procedure RegexExamples_Set11(const K: string; "
        "const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string);\n"
        "begin\n"
        "  GTextEnglish.Values[K] := EN;\n"
        "  GTextPortuguese.Values[K] := PT;\n"
        "  GTextSpanish.Values[K] := ES;\n"
        "  GTextFrench.Values[K] := FR;\n"
        "  GTextGerman.Values[K] := DE;\n"
        "  GTextItalian.Values[K] := IT;\n"
        "  GTextPolish.Values[K] := PL;\n"
        "  GTextPortuguesePT.Values[K] := PTPT;\n"
        "  GTextRomanian.Values[K] := RO;\n"
        "  GTextHungarian.Values[K] := HU;\n"
        "  GTextCzech.Values[K] := CZ;\n"
    )
    # match with or without broken JA line
    m = re.search(
        re.escape(old_sig) + r"(?:\s*GTextJapanese\.Values\[K\] := JA;\s*)?end;",
        text,
    )
    if m:
        text = (
            text[: m.start()]
            + "procedure RegexExamples_Set12(const K: string; "
            "const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA: string);\n"
            "begin\n"
            "  GTextEnglish.Values[K] := EN;\n"
            "  GTextPortuguese.Values[K] := PT;\n"
            "  GTextSpanish.Values[K] := ES;\n"
            "  GTextFrench.Values[K] := FR;\n"
            "  GTextGerman.Values[K] := DE;\n"
            "  GTextItalian.Values[K] := IT;\n"
            "  GTextPolish.Values[K] := PL;\n"
            "  GTextPortuguesePT.Values[K] := PTPT;\n"
            "  GTextRomanian.Values[K] := RO;\n"
            "  GTextHungarian.Values[K] := HU;\n"
            "  GTextCzech.Values[K] := CZ;\n"
            "  GTextJapanese.Values[K] := JA;\n"
            "end;"
            + text[m.end() :]
        )
        print("RegexExamples_Set12 signature")
    elif "procedure RegexExamples_Set12(" in text:
        print("RegexExamples_Set12 already present")
    else:
        raise RuntimeError("RegexExamples helper not found")

    if "SP_AI_JA :=" not in text:
        text = text.replace(
            "SP_AI_EN, SP_AI_PT, SP_AI_ES, SP_AI_FR, SP_AI_DE, SP_AI_IT, "
            "SP_AI_PL, SP_AI_PTPT, SP_AI_RO, SP_AI_HU, SP_AI_CZ: string;",
            "SP_AI_EN, SP_AI_PT, SP_AI_ES, SP_AI_FR, SP_AI_DE, SP_AI_IT, "
            "SP_AI_PL, SP_AI_PTPT, SP_AI_RO, SP_AI_HU, SP_AI_CZ, SP_AI_JA: string;",
            1,
        )
        m_en = re.search(r"SP_AI_EN\s*:=\s*((?:'(?:[^']|'')*'|#\d+|\s|\+)+);", text)
        ja_txt = translate_one(decode_pascal(m_en.group(1)), cache)
        m_cz = re.search(r"(SP_AI_CZ\s*:=\s*(?:'(?:[^']|'')*'|#\d+|\s|\+)+\s*;)", text)
        text = text.replace(
            m_cz.group(1),
            m_cz.group(1) + "\n  SP_AI_JA := " + encode_pascal(ja_txt) + ";",
            1,
        )
        print("SP_AI_JA injected")

    if "RegexExamples_Set11(" not in text:
        print("No RegexExamples_Set11 calls left")
        return text

    call_re = re.compile(r"\bRegexExamples_Set11\s*\(")
    out = []
    pos = 0
    n_fixed = 0
    while True:
        m = call_re.search(text, pos)
        if not m:
            out.append(text[pos:])
            break
        out.append(text[pos:m.start()])
        i = skip_ws_comments(text, m.end())
        em = re.match(STR_EXPR, text[i:])
        key_expr = em.group(0)
        key_txt = decode_pascal(key_expr)
        j = i + em.end()
        j = skip_ws_comments(text, j)
        assert text[j] == ","
        j += 1
        if key_txt == "SPLIT_PATTERN_AI_PROMPT_BODY":
            idents = []
            for li in range(11):
                j = skip_ws_comments(text, j)
                im = re.match(r"SP_AI_[A-Z]+", text[j:])
                idents.append(im.group(0))
                j += im.end()
                j = skip_ws_comments(text, j)
                if li < 10:
                    assert text[j] == ","
                    j += 1
                else:
                    assert text[j] == ")"
                    j += 1
            out.append(
                "RegexExamples_Set12(" + key_expr + ", " + ", ".join(idents) + ", SP_AI_JA)"
            )
        else:
            langs, j = parse_call_langs(text, j, 11)
            ja_expr = encode_pascal(translate_one(decode_pascal(langs[0]), cache))
            out.append(
                "RegexExamples_Set12(\n    "
                + ",\n    ".join([key_expr] + langs + [ja_expr])
                + ")"
            )
        n_fixed += 1
        if j < len(text) and text[j] == ";":
            out.append(";")
            j += 1
        pos = j
        if n_fixed % 15 == 0:
            print(f"  regex {n_fixed}", flush=True)
            save_cache(cache)
    text = "".join(out)
    print(f"RegexExamples calls fixed: {n_fixed}")
    return text


def fix_history() -> None:
    t = UNCONSTS.read_text(encoding="utf-8")
    if "Japanese as 12th UI language" in t:
        print("HISTORY already OK")
        return
    i = t.find("HISTORY =")
    chunk = t[i : i + 40000]
    nums = [int(x) for x in re.findall(r"Internal v3\.0\.5\.(\d+)", chunk)]
    nxt = max(nums) + 1 if nums else 121
    old = (
        "    '  v3.0.5.100  (2026-09-06)  (current)'#13#10 +\n"
        "    '-------------------------------------------------------'#13#10 +\n"
    )
    new = (
        f"    '  v3.0.5.{nxt}  (2026-09-15)  (current)'#13#10 +\n"
        "    '-------------------------------------------------------'#13#10 +\n"
        "    '  i18n: Japanese as 12th UI language — full uI18n.pas coverage:'#13#10 +\n"
        "    '    alJapanese / ja, GTextJapanese Set12, language.option.japanese,'#13#10 +\n"
        "    '    combo + Assistente; TAGLINE/RegexExamples/help blocks.'#13#10 +\n"
        f"    '    Internal v3.0.5.{nxt}: Japones completo em uI18n (12 idiomas).'#13#10 +\n"
        "    ''#13#10 +\n"
        "    '-------------------------------------------------------'#13#10 +\n"
        "    '  v3.0.5.100  (2026-09-06)'#13#10 +\n"
        "    '-------------------------------------------------------'#13#10 +\n"
    )
    if old not in t:
        raise RuntimeError("HISTORY header not found")
    t = t.replace(old, new, 1)
    t = t.replace(
        "APPLICATION_VERSION = '3.0.5.100';",
        f"APPLICATION_VERSION = '3.0.5.{nxt}';",
        1,
    )
    UNCONSTS.write_text(t, encoding="utf-8")
    print(f"HISTORY + version -> 3.0.5.{nxt}")


def validate(text: str) -> None:
    checks = [
        ("GJapanese:", "GJapanese var"),
        ("GTextJapanese:", "GTextJapanese var"),
        ("GJapanese       := CreateTable", "GJapanese create"),
        ("GTextJapanese   := CreateTable", "GTextJapanese create"),
        ("GTextJapanese.Assign(GTextEnglish)", "JA Assign"),
        ("alJapanese:     Result := GTextJapanese", "TextTable JA"),
        ("alJapanese:     Result := GJapanese", "Table JA"),
        ("Normalized = 'ja'", "FromCode ja"),
        ("alJapanese:     Result := 'ja'", "Code ja"),
        ("GTextJapanese.Values[K] := JA", "Set12 JA body"),
        ("language.option.japanese", "lang option"),
        ("FreeAndNil(GTextJapanese)", "free JA"),
    ]
    for needle, label in checks:
        ok = needle in text
        print(("OK" if ok else "MISSING"), label)
    print("Set11(", len(re.findall(r"\bSet11\s*\(", text)))
    print("RegexExamples_Set11(", text.count("RegexExamples_Set11("))


def main() -> int:
    cache = load_cache()
    text = UI18N.read_text(encoding="utf-8-sig")

    text = restore_plumbing(text)
    text = fix_language_option(text)
    text = fix_tagline(text, cache)
    text = fix_regex_examples(text, cache)

    validate(text)

    UI18N.write_bytes(b"\xef\xbb\xbf" + text.encode("utf-8"))
    save_cache(cache)
    fix_history()
    print("Wrote uI18n.pas, cache", len(cache))
    return 0


if __name__ == "__main__":
    sys.exit(main())
