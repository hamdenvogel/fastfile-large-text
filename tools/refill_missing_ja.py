# -*- coding: utf-8 -*-
"""Re-apply Japanese from cache onto Set12 JA args and direct GTextJapanese assigns."""
from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
CACHE = ROOT / "tools" / "ja_translation_cache.json"

ATOM = r"(?:'(?:[^']|'')*'|#\d+)"
STR_EXPR = rf"(?:{ATOM})(?:\s*(?:\+\s*)?(?:{ATOM}))*"


def load_cache():
    return json.loads(CACHE.read_text(encoding="utf-8"))


def save_cache(cache):
    tmp = CACHE.with_suffix(".json.tmp")
    data = json.dumps(cache, ensure_ascii=False, indent=0)
    for attempt in range(5):
        try:
            tmp.write_text(data, encoding="utf-8")
            tmp.replace(CACHE)
            return
        except OSError:
            time.sleep(0.3 * (attempt + 1))
    # last resort: skip persist this round
    print("WARN: cache save failed", flush=True)


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

    def flush():
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
            i = n if j < 0 else j + 1
            continue
        if text.startswith("(*", i):
            j = text.find("*)", i + 2)
            i = n if j < 0 else j + 2
            continue
        break
    return i


def has_cjk(s: str) -> bool:
    return bool(re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", s or ""))


def translate_one(text: str, cache: dict) -> str:
    if text in cache and has_cjk(cache[text]):
        return cache[text]
    if text in cache and cache[text] != text:
        return cache[text]
    if not text or not text.strip():
        return text
    stripped = text.strip()
    if stripped in {"-", "&", "...", "OK", "AI", "F1", "F5", "CSV", "CRLF", "UTF-8", "ANSI", "TAB", "B", "MB", "GB", "TB"}:
        cache[text] = text
        return text
    if len(stripped) <= 2 and not any(c.isalpha() and ord(c) > 127 for c in stripped):
        # short tokens like B, MB already handled; keep short ASCII
        if stripped.isascii() and len(stripped) <= 3 and stripped.upper() == stripped:
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
            ja = ts.translate_text(src, translator="bing", from_language="en", to_language="ja")
            break
        except Exception as e:
            last_err = e
            time.sleep(0.7 * (attempt + 1))
    if ja is None:
        print(f"FAIL {src[:50]!r}: {last_err}", flush=True)
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
    if len(cache) % 20 == 0:
        save_cache(cache)
    time.sleep(0.12)
    return ja


def parse_set12_args(text: str, start_after_paren: int):
    i = start_after_paren
    args = []
    for li in range(13):
        i = skip_ws_comments(text, i)
        if li == 0 and text.startswith("TAGLINE_KEY", i):
            args.append(("TAGLINE_KEY", i, i + len("TAGLINE_KEY")))
            i += len("TAGLINE_KEY")
        else:
            em = re.match(STR_EXPR, text[i:])
            if not em:
                return None, start_after_paren
            args.append((em.group(0), i, i + em.end()))
            i += em.end()
        i = skip_ws_comments(text, i)
        if li < 12:
            if i >= len(text) or text[i] != ",":
                return None, start_after_paren
            i += 1
        else:
            if i >= len(text) or text[i] != ")":
                return None, start_after_paren
            i += 1
    return args, i


def fix_set12_ja(text: str, cache: dict) -> str:
    out = []
    pos = 0
    fixed = 0
    skipped = 0
    translated_now = 0
    for m in re.finditer(r"(?<!procedure )\bSet12\s*\(", text):
        out.append(text[pos:m.end()])
        args, end_i = parse_set12_args(text, m.end())
        if not args:
            # copy until we can't - fallback leave as-is
            out.append(text[m.end():m.end()+1])
            pos = m.end()
            continue
        en_expr, ja_expr = args[1][0], args[12][0]
        if en_expr == "TAGLINE_KEY":
            # already handled separately usually
            out.append(text[m.end():end_i])
            pos = end_i
            continue
        en = decode_pascal(en_expr)
        ja = decode_pascal(ja_expr)
        need = (not has_cjk(ja)) and (ja == en or not has_cjk(ja))
        # Always refresh if JA equals EN and EN looks like real text
        if ja == en and len(en.strip()) > 0:
            need = True
        if has_cjk(ja):
            need = False
        # keep pure technical tokens
        if en.strip() in {"B", "MB", "GB", "TB", "OK", "AI", "F1", "F5", "CSV", "TAB", "CRLF", "UTF-8", "ANSI", "-", "..."}:
            need = False
        if need:
            new_ja = translate_one(en, cache)
            if new_ja != ja:
                # rebuild call args with new JA
                pieces = []
                for idx, (expr, a, b) in enumerate(args):
                    if idx == 12:
                        pieces.append(encode_pascal(new_ja))
                    else:
                        pieces.append(expr)
                # reconstruct with original spacing roughly: key/langs on lines
                rebuilt = "\n    " + ",\n    ".join(pieces) + ")"
                # end_i already consumed ')'
                out.append(rebuilt)
                fixed += 1
                if en not in cache or cache.get(en) == new_ja:
                    translated_now += 1
                pos = end_i
                if fixed % 25 == 0:
                    print(f"  set12 fixed {fixed}", flush=True)
                    save_cache(cache)
                continue
            else:
                skipped += 1
        out.append(text[m.end():end_i])
        pos = end_i
    out.append(text[pos:])
    print(f"Set12 JA fixed={fixed} skipped_same={skipped}")
    return "".join(out)


def fix_direct_assigns(text: str, cache: dict) -> str:
    """Fix GTextJapanese.Values['Key'] := 'same or english'; using cache/translate."""
    pat = re.compile(
        r"(GTextJapanese\.Values\['((?:[^']|'')*)'\]\s*:=\s*)"
        r"('(?:[^']|'')*')\s*;"
    )

    def repl(m: re.Match) -> str:
        prefix = m.group(1)
        key = m.group(2).replace("''", "'")
        val_expr = m.group(3)
        val = decode_pascal(val_expr)
        if has_cjk(val):
            return m.group(0)
        # Prefer translating the English meaning: often key IS the English text
        src = key if (val == key or not val) else val
        # Also try EN from GTextEnglish same key nearby? use key as EN for TrText keys
        ja = translate_one(src, cache)
        if not has_cjk(ja) and ja == src:
            return m.group(0)
        return prefix + encode_pascal(ja) + ";"

    text2, n = pat.subn(repl, text)
    print(f"Direct assigns rewritten (pattern matches processed via subn count={n})")
    return text2


def main():
    cache = load_cache()
    text = UI18N.read_text(encoding="utf-8-sig")
    print("cache", len(cache))
    text = fix_set12_ja(text, cache)
    save_cache(cache)
    # Direct assigns: only those clearly untranslated
    text = fix_direct_assigns(text, cache)
    UI18N.write_bytes(b"\xef\xbb\xbf" + text.encode("utf-8"))
    save_cache(cache)
    print("done cache", len(cache))
    return 0


if __name__ == "__main__":
    sys.exit(main())
