"""Stats over tests/i18ndump/i18n_dump.txt (dev helper for gen_rtl_i18n.py)."""
from __future__ import annotations

import collections
import sys
from pathlib import Path

DUMP = Path(__file__).resolve().parent.parent / "tests" / "i18ndump" / "i18n_dump.txt"


def unesc(s: str) -> str:
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            out.append({"\\": "\\", "r": "\r", "n": "\n", "p": "|"}.get(n, n))
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def load(path: Path = DUMP):
    data: dict[tuple[str, str], dict[str, str]] = collections.defaultdict(dict)
    for line in path.read_text(encoding="utf-8-sig").split("\n"):
        line = line.rstrip("\r")
        if not line:
            continue
        parts = line.split("|", 3)
        if len(parts) != 4:
            continue
        lang, kind, k, v = parts
        data[(lang, kind)][unesc(k)] = unesc(v)
    return data


if __name__ == "__main__":
    d = load()
    for (lang, kind), tbl in sorted(d.items()):
        print(lang, kind, len(tbl))
    keys_t = set()
    keys_k = set()
    for (lang, kind), tbl in d.items():
        (keys_t if kind == "T" else keys_k).update(tbl.keys())
    print("union T", len(keys_t), "union K", len(keys_k))
    en_t = d[("en", "T")]
    en_k = d[("en", "K")]
    print("T keys missing in EN T:", len([k for k in keys_t if k not in en_t]))
    print("K keys missing in EN K:", len([k for k in keys_k if k not in en_k]))
    total_chars = sum(len(k) for k in keys_t) + sum(len(en_k.get(k, "")) for k in keys_k)
    print("approx chars to translate", total_chars)
