# -*- coding: utf-8 -*-
"""Finish Chinese i18n using existing zh_cn_cache + fresh zh-Hant translations."""
from __future__ import annotations

import json
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
    apply_plumbing,
    collect_english_strings,
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
    KEEP_EN,
    decode_pascal,
    encode_pascal,
)
import re


def main() -> int:
    LOG.write_text("", encoding="utf-8")
    log("=== finish Chinese i18n ===")

    # Restore clean pre-zh source
    if not BACKUP.exists():
        raise SystemExit(f"missing {BACKUP}")
    shutil.copy2(BACKUP, UI18N)
    log(f"Restored {BACKUP.name}")

    text = UI18N.read_bytes()
    text = text.decode("utf-8-sig") if text.startswith(b"\xef\xbb\xbf") else text.decode("utf-8")
    text = text.replace("\r\n", "\n")

    cache_cn = load_cache(CACHE_CN)
    cache_tw = load_cache(CACHE_TW)
    log(f"Cache CN={len(cache_cn)} TW={len(cache_tw)}")

    ens = collect_english_strings(text)
    log(f"Unique EN: {len(ens)}")

    # Fill any missing CN with zh-Hans
    pending_cn = [
        s
        for s in ens
        if s not in cache_cn
        or not cache_cn.get(s)
        or (cache_cn.get(s) == s and s.strip() not in KEEP_EN and len(s.strip()) > 1)
    ]
    log(f"Pending zh-Hans: {len(pending_cn)}")
    for i, s in enumerate(pending_cn, 1):
        translate_one(s, "zh-Hans", cache_cn, CACHE_CN)
        if i % 20 == 0:
            save_cache(CACHE_CN, cache_cn)
            log(f"  CN {i}/{len(pending_cn)}")
    save_cache(CACHE_CN, cache_cn)

    # Rebuild TW with zh-Hant (clear English fallbacks)
    pending_tw = [
        s
        for s in ens
        if s not in cache_tw
        or not cache_tw.get(s)
        or (cache_tw.get(s) == s and s.strip() not in KEEP_EN and len(s.strip()) > 1)
    ]
    log(f"Pending zh-Hant: {len(pending_tw)}")
    for i, s in enumerate(pending_tw, 1):
        translate_one(s, "zh-Hant", cache_tw, CACHE_TW)
        if i % 20 == 0:
            save_cache(CACHE_TW, cache_tw)
            log(f"  TW {i}/{len(pending_tw)}")
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
    save_cache(CACHE_CN, cache_cn)
    save_cache(CACHE_TW, cache_tw)
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
    log(f"cache CN={len(cache_cn)} TW={len(cache_tw)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
