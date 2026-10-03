# -*- coding: utf-8 -*-
"""Apply Chinese plumbing+rewrite using existing caches (no re-translate if complete)."""
from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
sys.path.insert(0, str(ROOT / "tools"))

from add_chinese_i18n import (  # noqa: E402
    BACKUP,
    CACHE_CN,
    CACHE_TW,
    UI18N,
    KEEP_EN,
    apply_plumbing,
    collect_english_strings,
    decode_pascal,
    encode_pascal,
    ensure_bom_utf8,
    inject_lang_options,
    load_cache,
    log,
    LOG,
    mirror_putnv_english_gaps,
    mirror_putnv_japanese,
    rewrite_set_calls,
    save_cache,
    translate_one,
)


def main() -> int:
    LOG.write_text("", encoding="utf-8")
    log("=== apply Chinese (caches ready) ===")
    if not BACKUP.exists():
        raise SystemExit(f"missing {BACKUP}")
    shutil.copy2(BACKUP, UI18N)
    log(f"Restored {BACKUP.name}")

    raw = UI18N.read_bytes()
    text = raw.decode("utf-8-sig") if raw.startswith(b"\xef\xbb\xbf") else raw.decode("utf-8")
    text = text.replace("\r\n", "\n")

    cache_cn = load_cache(CACHE_CN)
    cache_tw = load_cache(CACHE_TW)
    ens = collect_english_strings(text)
    log(f"EN={len(ens)} cache CN={len(cache_cn)} TW={len(cache_tw)}")

    # Fill any remaining gaps quickly
    for s in ens:
        if s not in cache_cn or (cache_cn.get(s) == s and s.strip() not in KEEP_EN and len(s.strip()) > 1):
            translate_one(s, "zh-Hans", cache_cn, CACHE_CN)
        if s not in cache_tw or (cache_tw.get(s) == s and s.strip() not in KEEP_EN and len(s.strip()) > 1):
            translate_one(s, "zh-Hant", cache_tw, CACHE_TW)
    save_cache(CACHE_CN, cache_cn)
    save_cache(CACHE_TW, cache_tw)

    log("Plumbing...")
    text = apply_plumbing(text)
    log("Lang options...")
    text = inject_lang_options(text, cache_cn, cache_tw)

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
    log("Mirror English PutNV gaps...")
    text = mirror_putnv_english_gaps(text, cache_cn, cache_tw)
    save_cache(CACHE_CN, cache_cn)
    save_cache(CACHE_TW, cache_tw)

    ensure_bom_utf8(UI18N, text)
    log(f"Wrote {UI18N}")
    log(f"Set14={text.count('Set14(')} Set12={text.count('Set12(')}")
    log(
        f"PutNV CN={text.count('PutNV(GTextChineseSimplified')} "
        f"TW={text.count('PutNV(GTextChineseTraditional')}"
    )
    log(f"alChineseSimplified={'alChineseSimplified' in text}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
