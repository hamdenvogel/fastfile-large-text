# -*- coding: utf-8 -*-
"""Faster Japanese add for uI18n.pas — regex-friendly Set11 rewriter."""
from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
CACHE = ROOT / "tools" / "ja_translation_cache.json"
BACKUP = ROOT / "tools" / "uI18n.pas.bak_before_ja"
LOG = ROOT / "tools" / "ja_i18n.log"
PROGRESS = ROOT / "tools" / "ja_i18n_progress.txt"


def log(msg: str) -> None:
    print(msg, flush=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(msg + "\n")


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=0), encoding="utf-8")


def decode_pascal(expr: str) -> str:
    # Drop Pascal '+' concatenators between atoms
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
    """Encode Unicode for Delphi; newlines become #13#10 outside quotes."""
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


# Match one Pascal string atom: '...' or #digits
ATOM = r"(?:'(?:[^']|'')*'|#\d+)"
# Concatenated string expression ('a'#13'b' or 'a' + 'b')
STR_EXPR = rf"(?:{ATOM})(?:\s*(?:\+\s*)?(?:{ATOM}))*"


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


def iter_set11(text: str):
    """Yield (start, end, key_expr, lang_exprs[11])."""
    call_re = re.compile(
        rf"\bSet11\s*\(\s*({STR_EXPR})\s*,",
        re.MULTILINE,
    )
    pos = 0
    while True:
        m = call_re.search(text, pos)
        if not m:
            break
        start = m.start()
        i = m.end()
        langs = []
        for li in range(11):
            i = skip_ws_comments(text, i)
            em = re.match(STR_EXPR, text[i:])
            if not em:
                raise RuntimeError(f"lang {li} parse fail at {i} near {text[i:i+60]!r}")
            langs.append(em.group(0))
            i += em.end()
            i = skip_ws_comments(text, i)
            if li < 10:
                if i >= len(text) or text[i] != ",":
                    raise RuntimeError(f"expected comma after lang {li} at {i} near {text[i:i+40]!r}")
                i += 1
            else:
                if i >= len(text) or text[i] != ")":
                    raise RuntimeError(f"expected ) after lang 10 at {i}: {text[i:i+40]!r}")
                i += 1
        yield start, i, m.group(1), langs
        pos = i


def translate_one(text: str) -> str:
    import translators as ts

    if not text or not text.strip():
        return text
    stripped = text.strip()
    if stripped in {"-", "&", "...", "OK", "AI", "F1", "F5", "CSV", "CRLF", "UTF-8", "ANSI"}:
        return text
    if len(stripped) <= 1:
        return text

    amp_char = ""
    src = text
    amp_idx = text.find("&")
    if amp_idx >= 0 and amp_idx + 1 < len(text) and text[amp_idx + 1].isalnum():
        amp_char = text[amp_idx + 1]
        src = text[:amp_idx] + text[amp_idx + 1 :]

    def do_tr(s: str) -> str:
        last_err = None
        for attempt in range(6):
            try:
                # bing tends to be more tolerant than google free endpoint
                return ts.translate_text(
                    s, translator="bing", from_language="en", to_language="ja"
                )
            except Exception as e:
                last_err = e
                time.sleep(2.0 * (attempt + 1))
                try:
                    return ts.translate_text(
                        s, translator="google", from_language="en", to_language="ja"
                    )
                except Exception as e2:
                    last_err = e2
                    time.sleep(3.0 * (attempt + 1))
        raise RuntimeError(last_err)

    try:
        if len(src) > 900:
            parts = []
            cur = ""
            for part in re.split(r"(\n)", src):
                if len(cur) + len(part) > 800 and cur:
                    parts.append(cur)
                    cur = part
                else:
                    cur += part
            if cur:
                parts.append(cur)
            out = []
            for ch in parts:
                if not ch.strip() or ch == "\n":
                    out.append(ch)
                else:
                    time.sleep(0.4)
                    out.append(do_tr(ch) or ch)
            result = "".join(out)
        else:
            time.sleep(0.35)
            result = do_tr(src) or src
    except Exception as e:
        log(f"WARN {e!r} :: {text[:80]!r}")
        return None  # signal failure — do not cache English as success

    if amp_char and result and "&" not in result:
        result = f"{result}(&{amp_char})"
    return result


def apply_plumbing(text: str) -> str:
    text = text.replace(
        "alPolish, alPortuguesePT, alRomanian, alHungarian, alCzech);",
        "alPolish, alPortuguesePT, alRomanian, alHungarian, alCzech, alJapanese);",
    )
    if "GJapanese:" not in text:
        text = text.replace(
            "  GCzech: TStringList = nil;\n",
            "  GCzech: TStringList = nil;\n  GJapanese: TStringList = nil;\n",
        )
    if "GTextJapanese:" not in text:
        text = text.replace(
            "  GTextCzech: TStringList = nil;\n",
            "  GTextCzech: TStringList = nil;\n  GTextJapanese: TStringList = nil;\n",
        )
    text = text.replace(
        "  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);\n",
        "  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);\n"
        "  if Assigned(GJapanese)         then GJapanese.CustomSort(CompareTableByKey);\n",
    )
    text = text.replace(
        "  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);\n",
        "  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);\n"
        "  if Assigned(GTextJapanese)     then GTextJapanese.CustomSort(CompareTableByKey);\n",
    )
    text = text.replace(
        "  GCzech          := CreateTable;\n",
        "  GCzech          := CreateTable;\n  GJapanese       := CreateTable;\n",
    )
    text = text.replace(
        "  GTextCzech      := CreateTable;\n",
        "  GTextCzech      := CreateTable;\n  GTextJapanese   := CreateTable;\n",
    )
    text = text.replace(
        "  GTextCzech.Assign(GTextEnglish);\n",
        "  GTextCzech.Assign(GTextEnglish);\n  GTextJapanese.Assign(GTextEnglish);\n",
    )
    text = text.replace(
        "  FreeAndNil(GCzech);\n",
        "  FreeAndNil(GCzech);\n  FreeAndNil(GJapanese);\n",
    )
    text = text.replace(
        "  FreeAndNil(GTextCzech);\n",
        "  FreeAndNil(GTextCzech);\n  FreeAndNil(GTextJapanese);\n",
    )
    text = text.replace(
        "    alCzech:        Result := GTextCzech;\n  else\n    Result := GTextEnglish;",
        "    alCzech:        Result := GTextCzech;\n"
        "    alJapanese:     Result := GTextJapanese;\n"
        "  else\n    Result := GTextEnglish;",
    )
    text = text.replace(
        "    alCzech:        Result := GCzech;\n  else\n    Result := GEnglish;",
        "    alCzech:        Result := GCzech;\n"
        "    alJapanese:     Result := GJapanese;\n"
        "  else\n    Result := GEnglish;",
    )
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
    )
    text = text.replace(
        "    alCzech:        Result := 'cs';\n  else\n    Result := 'en';",
        "    alCzech:        Result := 'cs';\n"
        "    alJapanese:     Result := 'ja';\n"
        "  else\n    Result := 'en';",
    )
    text = re.sub(
        r"procedure Set11\(const K: string;\s*"
        r"const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string\);",
        "procedure Set12(const K: string;\n"
        "    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ, JA: string);",
        text,
    )
    old_body = (
        "  begin\n"
        "    GTextEnglish.Values[K] := EN;\n"
        "    GTextPortuguese.Values[K] := PT;\n"
        "    GTextSpanish.Values[K] := ES;\n"
        "    GTextFrench.Values[K] := FR;\n"
        "    GTextGerman.Values[K] := DE;\n"
        "    GTextItalian.Values[K] := IT;\n"
        "    GTextPolish.Values[K] := PL;\n"
        "    GTextPortuguesePT.Values[K] := PTPT;\n"
        "    GTextRomanian.Values[K] := RO;\n"
        "    GTextHungarian.Values[K] := HU;\n"
        "    GTextCzech.Values[K] := CZ;\n"
        "  end;"
    )
    new_body = old_body.replace(
        "    GTextCzech.Values[K] := CZ;\n  end;",
        "    GTextCzech.Values[K] := CZ;\n    GTextJapanese.Values[K] := JA;\n  end;",
    )
    text = text.replace(old_body, new_body)
    text = text.replace("procedure Set11(", "procedure Set12(")
    text = text.replace(
        "  { language.option.japanese removed ? Japanese replaced by new languages }\n",
        "  { Japanese (ja) is a first-class UI language }\n",
    )
    return text


def inject_lang_options(text: str) -> str:
    if "language.option.japanese" in text:
        return text
    block = f"""
  GEnglish.Values['language.option.japanese']      := 'Japanese';
  GPortuguese.Values['language.option.japanese']   := 'Japon'#234's';
  GSpanish.Values['language.option.japanese']      := 'Japon'#233's';
  GFrench.Values['language.option.japanese']       := 'Japonais';
  GGerman.Values['language.option.japanese']       := 'Japanisch';
  GItalian.Values['language.option.japanese']      := 'Giapponese';
  GPolish.Values['language.option.japanese']       := 'Japo'#324'ski';
  GPortuguesePT.Values['language.option.japanese'] := 'Japon'#234's';
  GRomanian.Values['language.option.japanese']     := 'Japonez'#259;
  GHungarian.Values['language.option.japanese']    := 'Jap'#225'n';
  GCzech.Values['language.option.japanese']        := 'Japon'#353'tina';
  GJapanese.Values['language.option.japanese']     := {encode_pascal("日本語")};
  GJapanese.Values['language.option.english'] := {encode_pascal("英語")};
  GJapanese.Values['language.option.portuguese_brazil'] := {encode_pascal("ポルトガル語（ブラジル）")};
  GJapanese.Values['language.option.spanish'] := {encode_pascal("スペイン語")};
  GJapanese.Values['language.option.french'] := {encode_pascal("フランス語")};
  GJapanese.Values['language.option.german'] := {encode_pascal("ドイツ語")};
  GJapanese.Values['language.option.italian'] := {encode_pascal("イタリア語")};
  GJapanese.Values['language.option.polish'] := {encode_pascal("ポーランド語")};
  GJapanese.Values['language.option.portuguese_portugal'] := {encode_pascal("ポルトガル語（ポルトガル）")};
  GJapanese.Values['language.option.romanian'] := {encode_pascal("ルーマニア語")};
  GJapanese.Values['language.option.hungarian'] := {encode_pascal("ハンガリー語")};
  GJapanese.Values['language.option.czech'] := {encode_pascal("チェコ語")};
  GJapanese.Values['language.combo.hint'] := {encode_pascal("アプリケーションの言語")};
  GJapanese.Values['status.system_ready'] := {encode_pascal("システム準備完了")};
"""
    m = re.search(r"GCzech\.Values\['language\.option\.czech'\]\s*:=\s*[^;]+;", text)
    if not m:
        raise RuntimeError("anchor missing")
    return text[: m.end()] + "\n" + block + text[m.end() :]


def main() -> int:
    LOG.write_text("", encoding="utf-8")
    log("=== start ===")
    raw = UI18N.read_bytes()
    if not BACKUP.exists():
        BACKUP.write_bytes(raw)
    try:
        text = raw.decode("utf-8-sig") if raw.startswith(b"\xef\xbb\xbf") else raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("cp1252")

    cache = load_cache()
    log("Scanning Set11...")
    calls = list(iter_set11(text))
    log(f"Set11 calls: {len(calls)}")

    # unique EN
    ens = []
    seen = set()
    for _a, _b, _k, langs in calls:
        en = decode_pascal(langs[0])
        if en not in seen:
            seen.add(en)
            ens.append(en)
    # czech override keys
    for m in re.finditer(r"GTextCzech\.Values\[('(?:[^']|'')*')\]", text):
        k = decode_pascal(m.group(1))
        if k not in seen:
            seen.add(k)
            ens.append(k)
    log(f"Unique EN: {len(ens)}")

    keep_en = {"-", "&", "...", "OK", "AI", "F1", "F5", "CSV", "CRLF", "UTF-8", "ANSI"}
    pending = [
        s
        for s in ens
        if (s not in cache)
        or (not cache.get(s))
        or (cache.get(s) == s and s.strip() not in keep_en and len(s.strip()) > 1)
    ]
    log(f"Pending translate: {len(pending)}")
    for i, s in enumerate(pending, 1):
        ja = translate_one(s)
        if not ja:
            log(f"SKIP fail: {s[:60]!r}")
            continue
        cache[s] = ja
        PROGRESS.write_text(f"{i}/{len(pending)}\n{s[:100]}\n{ja[:100]}\n", encoding="utf-8")
        if i % 10 == 0:
            save_cache(cache)
            log(f"  {i}/{len(pending)}")
    save_cache(cache)
    missing = [s for s in ens if s not in cache or not cache[s]]
    log(f"Missing after pass: {len(missing)}")

    log("Plumbing...")
    text = apply_plumbing(text)
    text = inject_lang_options(text)

    log("Rewriting calls...")
    # Re-scan original Set11 on current text (still Set11 calls until we replace)
    # apply_plumbing does not rename calls
    out = []
    last = 0
    calls2 = list(iter_set11(text))
    log(f"Set11 after plumbing: {len(calls2)}")
    for idx, (start, end, key, langs) in enumerate(calls2, 1):
        out.append(text[last:start])
        en = decode_pascal(langs[0])
        ja = cache.get(en, en)
        parts = ["Set12(", f"    {key},"]
        for e in langs:
            parts.append(f"    {e},")
        parts.append(f"    {encode_pascal(ja)})")
        out.append("\n".join(parts))
        last = end
        if idx % 200 == 0:
            log(f"  rewrite {idx}")
    out.append(text[last:])
    text = "".join(out)

    log("Czech mirrors...")
    lines = text.splitlines(keepends=True)
    new_lines = []
    for i, line in enumerate(lines):
        new_lines.append(line)
        m = re.match(r"(\s*)GTextCzech\.Values\[('(?:[^']|'')*')\]\s*:=\s*(.+);(\s*)$", line)
        if not m:
            continue
        indent, key_lit, _e, ws = m.groups()
        nxt = lines[i + 1] if i + 1 < len(lines) else ""
        if "GTextJapanese.Values[" in nxt:
            continue
        key = decode_pascal(key_lit)
        ja = cache.get(key)
        if not ja or ja == key:
            ja2 = translate_one(key)
            if ja2:
                ja = ja2
                cache[key] = ja
        if not ja:
            ja = key
        new_lines.append(f"{indent}GTextJapanese.Values[{key_lit}] := {encode_pascal(ja)};{ws}")
    save_cache(cache)
    text = "".join(new_lines)

    UI18N.write_bytes(b"\xef\xbb\xbf" + text.encode("utf-8"))
    log(f"Wrote {UI18N}")
    log(f"Set11 left={len(list(iter_set11(text)))} Set12~={text.count('Set12(')} cache={len(cache)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
