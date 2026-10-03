# -*- coding: utf-8 -*-
"""Second pass: fix leftover Set12 / incomplete Set14 calls in-place."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
sys.path.insert(0, str(ROOT / "tools"))

from add_chinese_i18n import (  # noqa: E402
    CACHE_CN,
    CACHE_TW,
    UI18N,
    ensure_bom_utf8,
    load_cache,
    log,
    LOG,
    rewrite_set_calls,
)


def main() -> int:
    LOG.write_text("", encoding="utf-8")
    log("=== fix leftover Set12/incomplete Set14 ===")
    raw = UI18N.read_bytes()
    text = raw.decode("utf-8-sig") if raw.startswith(b"\xef\xbb\xbf") else raw.decode("utf-8")
    text = text.replace("\r\n", "\n")
    cache_cn = load_cache(CACHE_CN)
    cache_tw = load_cache(CACHE_TW)
    before12 = text.count("Set12(")
    text = rewrite_set_calls(text, cache_cn, cache_tw)
    after12 = text.count("Set12(")
    ensure_bom_utf8(UI18N, text)
    log(f"Set12 before={before12} after={after12}")
    log(f"Set14={text.count('Set14(')}")
    log(f"Wrote {UI18N}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
