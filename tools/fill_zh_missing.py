# -*- coding: utf-8 -*-
"""Fill missing Chinese Simplified/Traditional PutNV entries for 100% coverage."""
from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
CACHE_CN = ROOT / "tools" / "zh_cn_cache.json"
CACHE_TW = ROOT / "tools" / "zh_tw_cache.json"


def log(msg: str) -> None:
    print(msg, flush=True)


def load_cache(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def save_cache(path: Path, cache: dict) -> None:
    path.write_text(json.dumps(cache, ensure_ascii=False, indent=0), encoding="utf-8")


def pascal_escape(s: str) -> str:
    return s.replace("'", "''")


def expr_to_plain(expr: str) -> str:
    """Flatten a Delphi string expression into plain text for translation."""
    parts = []
    i = 0
    s = expr
    while i < len(s):
        if s[i] == "'":
            i += 1
            buf = []
            while i < len(s):
                if s[i] == "'":
                    if i + 1 < len(s) and s[i + 1] == "'":
                        buf.append("'")
                        i += 2
                        continue
                    i += 1
                    break
                buf.append(s[i])
                i += 1
            parts.append("".join(buf))
            continue
        if s[i] == "#":
            m = re.match(r"#(\d+)", s[i:])
            if m:
                parts.append(chr(int(m.group(1))))
                i += len(m.group(0))
                continue
        i += 1
    return "".join(parts)


def plain_to_pascal_literal(s: str) -> str:
    """Encode plain text as a Delphi string literal (may use #13#10)."""
    if "\r\n" in s:
        s = s.replace("\r\n", "\n")
    if "\n" not in s:
        return "'" + pascal_escape(s) + "'"
    chunks = s.split("\n")
    out = []
    for idx, ch in enumerate(chunks):
        out.append("'" + pascal_escape(ch) + "'")
        if idx < len(chunks) - 1:
            out.append("#13#10")
    # join with +
    result = []
    i = 0
    while i < len(out):
        if out[i].startswith("'") and i + 1 < len(out) and out[i + 1] == "#13#10":
            result.append(out[i] + "#13#10")
            i += 2
            if i < len(out) and out[i].startswith("'"):
                result[-1] = result[-1] + " +"
                # next literal on new line handled by caller join
            continue
        result.append(out[i])
        i += 1
    # Simpler approach:
    pieces = []
    for idx, ch in enumerate(chunks):
        lit = "'" + pascal_escape(ch) + "'"
        if idx < len(chunks) - 1:
            lit += "#13#10"
        pieces.append(lit)
    return " +\n    ".join(pieces)


def translate_one(text: str, to_lang: str, cache: dict, cache_path: Path) -> str:
    if text in cache and cache[text]:
        return cache[text]
    if not text or not text.strip():
        cache[text] = text
        return text
    stripped = text.strip()
    if stripped in {"OK", "-", "%s", "%d"} or len(stripped) <= 1:
        cache[text] = text
        return text

    amp_char = ""
    src = text
    amp_idx = text.find("&")
    if amp_idx >= 0 and amp_idx + 1 < len(text) and text[amp_idx + 1].isalnum():
        amp_char = text[amp_idx + 1]
        src = text[:amp_idx] + text[amp_idx + 1 :]

    import translators as ts

    out = None
    last_err = None
    for attempt in range(6):
        try:
            out = ts.translate_text(
                src, translator="bing", from_language="en", to_language=to_lang
            )
            break
        except Exception as e:
            last_err = e
            time.sleep(0.7 * (attempt + 1))
    if out is None:
        log(f"TRANSLATE FAIL [{to_lang}]: {src[:60]!r} -> {last_err}")
        out = text
    if amp_char and "&" not in out:
        up, low = amp_char.upper(), amp_char.lower()
        for i, ch in enumerate(out):
            if ch in (low, up):
                out = out[:i] + "&" + out[i:]
                break
        else:
            out = out + "(&" + amp_char + ")"
    cache[text] = out
    if len(cache) % 10 == 0:
        save_cache(cache_path, cache)
    time.sleep(0.12)
    return out


def find_putnv_blocks(src: str, list_name: str):
    """Yield (key, value_expr, full_stmt_start, full_stmt_end) for PutNV(list,...)."""
    pat = re.compile(rf"PutNV\({re.escape(list_name)},\s*'((?:''|[^'])*)',\s*")
    for m in pat.finditer(src):
        key = m.group(1).replace("''", "'")
        i = m.end()
        depth = 0
        start_val = i
        while i < len(src):
            c = src[i]
            if c == "'":
                i += 1
                while i < len(src):
                    if src[i] == "'":
                        if i + 1 < len(src) and src[i + 1] == "'":
                            i += 2
                            continue
                        i += 1
                        break
                    i += 1
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                if depth == 0:
                    val = src[start_val:i].strip()
                    end = i + 1
                    if end < len(src) and src[end] == ";":
                        end += 1
                    yield key, val, m.start(), end
                    break
                depth -= 1
            i += 1


def keys_of(src: str, list_name: str) -> set[str]:
    return {k for k, *_ in find_putnv_blocks(src, list_name)}


def insert_after_anchor(src: str, key: str, anchor_list: str, new_stmts: str) -> str:
    """Insert new_stmts after the PutNV(anchor_list, key, ...) statement."""
    for k, val, start, end in find_putnv_blocks(src, anchor_list):
        if k == key:
            # skip trailing whitespace/newline then insert
            insert_at = end
            # keep one newline after ;
            if insert_at < len(src) and src[insert_at] in "\r\n":
                pass
            return src[:insert_at] + "\n" + new_stmts + src[insert_at:]
    raise KeyError(f"anchor PutNV({anchor_list}, {key!r}) not found")


def main() -> None:
    text = UI18N.read_text(encoding="utf-8-sig")
    # normalize to \n for edits; restore CRLF at end
    had_bom = UI18N.read_bytes()[:3] == b"\xef\xbb\xbf"
    text = text.replace("\r\n", "\n")

    cache_cn = load_cache(CACHE_CN)
    cache_tw = load_cache(CACHE_TW)

    # --- GText gaps ---
    en_text = {k: v for k, v, *_ in find_putnv_blocks(text, "GTextEnglish")}
    # last occurrence wins
    en_text = {}
    for k, v, s, e in find_putnv_blocks(text, "GTextEnglish"):
        en_text[k] = v
    cn_text = keys_of(text, "GTextChineseSimplified")
    miss_text = sorted(set(en_text) - cn_text)
    log(f"GText missing CN: {len(miss_text)}")

    # Prefer insert after Czech; fallback German/English
    anchors_text = [
        "GTextCzech",
        "GTextHungarian",
        "GTextRomanian",
        "GTextPortuguesePT",
        "GTextPolish",
        "GTextItalian",
        "GTextGerman",
        "GTextEnglish",
    ]

    for key in miss_text:
        plain = expr_to_plain(en_text[key])
        zhcn = translate_one(plain, "zh-Hans", cache_cn, CACHE_CN)
        zhtw = translate_one(plain, "zh-Hant", cache_tw, CACHE_TW)
        lit_cn = plain_to_pascal_literal(zhcn)
        lit_tw = plain_to_pascal_literal(zhtw)
        stmts = (
            f"  PutNV(GTextChineseSimplified, '{pascal_escape(key)}', {lit_cn});\n"
            f"  PutNV(GTextChineseTraditional, '{pascal_escape(key)}', {lit_tw});"
        )
        inserted = False
        for anc in anchors_text:
            try:
                text = insert_after_anchor(text, key, anc, stmts)
                inserted = True
                log(f"  +GText {key[:60]!r} via {anc}")
                break
            except KeyError:
                continue
        if not inserted:
            log(f"  FAIL insert GText {key!r}")

    # --- G table gaps (popup/toolbar etc.) ---
    en_g = {}
    for k, v, s, e in find_putnv_blocks(text, "GEnglish"):
        en_g[k] = v
    cn_g = keys_of(text, "GChineseSimplified")
    miss_g = sorted(set(en_g) - cn_g)
    log(f"G missing CN: {len(miss_g)}")

    anchors_g = [
        "GCzech",
        "GHungarian",
        "GRomanian",
        "GPortuguesePT",
        "GPolish",
        "GItalian",
        "GGerman",
        "GPortuguese",
        "GEnglish",
    ]

    for key in miss_g:
        plain = expr_to_plain(en_g[key])
        zhcn = translate_one(plain, "zh-Hans", cache_cn, CACHE_CN)
        zhtw = translate_one(plain, "zh-Hant", cache_tw, CACHE_TW)
        lit_cn = plain_to_pascal_literal(zhcn)
        lit_tw = plain_to_pascal_literal(zhtw)
        stmts = (
            f"  PutNV(GChineseSimplified, '{pascal_escape(key)}', {lit_cn});\n"
            f"  PutNV(GChineseTraditional, '{pascal_escape(key)}', {lit_tw});"
        )
        inserted = False
        for anc in anchors_g:
            try:
                text = insert_after_anchor(text, key, anc, stmts)
                inserted = True
                log(f"  +G {key!r} via {anc}")
                break
            except KeyError:
                continue
        if not inserted:
            log(f"  FAIL insert G {key!r}")

    save_cache(CACHE_CN, cache_cn)
    save_cache(CACHE_TW, cache_tw)

    out = text.replace("\n", "\r\n")
    data = out.encode("utf-8")
    if had_bom:
        data = b"\xef\xbb\xbf" + data
    UI18N.write_bytes(data)

    # re-validate
    text2 = UI18N.read_text(encoding="utf-8-sig")
    en_t = {k for k, *_ in find_putnv_blocks(text2, "GTextEnglish")}
    cn_t = {k for k, *_ in find_putnv_blocks(text2, "GTextChineseSimplified")}
    tw_t = {k for k, *_ in find_putnv_blocks(text2, "GTextChineseTraditional")}
    en_g2 = {k for k, *_ in find_putnv_blocks(text2, "GEnglish")}
    cn_g2 = {k for k, *_ in find_putnv_blocks(text2, "GChineseSimplified")}
    tw_g2 = {k for k, *_ in find_putnv_blocks(text2, "GChineseTraditional")}
    log("=== after ===")
    log(f"GText EN-CN={len(en_t-cn_t)} EN-TW={len(en_t-tw_t)}")
    log(f"G EN-CN={len(en_g2-cn_g2)} EN-TW={len(en_g2-tw_g2)}")
    if en_t - cn_t:
        log(f" still GText: {sorted(en_t-cn_t)}")
    if en_g2 - cn_g2:
        log(f" still G: {sorted(en_g2-cn_g2)}")
    log("Wrote uI18n.pas")


if __name__ == "__main__":
    main()
