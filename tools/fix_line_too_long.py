# -*- coding: utf-8 -*-
"""Break physical source lines whose UTF-8 byte length exceeds 1023 (dcc64 F2069)."""
from __future__ import annotations

import re
from pathlib import Path

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
MAX_BYTES = 900  # margin under 1023


def utf8_len(s: str) -> int:
    return len(s.encode("utf-8"))


def split_string_content(content: str, max_bytes: int) -> list[str]:
    """Split decoded string content into chunks each encoding to <= max_bytes as Pascal '...'."""
    chunks: list[str] = []
    buf: list[str] = []
    cur = 0

    def flush() -> None:
        nonlocal cur
        chunks.append("".join(buf))
        buf.clear()
        cur = 0

    for ch in content:
        # Pascal encoding cost: quote doubles; UTF-8 bytes of char
        piece = ch.replace("'", "''") if False else ch
        # cost in source: UTF-8 of char, but ' becomes '' (2 ASCII bytes)
        if ch == "'":
            cost = 2
        else:
            cost = len(ch.encode("utf-8"))
        # also account for surrounding quotes later — leave headroom in max_bytes
        if cur + cost > max_bytes and buf:
            flush()
        buf.append(ch)
        cur += cost
    if buf:
        flush()
    return chunks


def encode_pascal_chunk(content: str) -> str:
    return "'" + content.replace("'", "''") + "'"


def break_line(line: str) -> list[str]:
    if utf8_len(line) <= 1023:
        return [line]

    indent_m = re.match(r"^(\s*)", line)
    indent = indent_m.group(1) if indent_m else "    "
    cont = indent + "  "

    # If line has ' + ' splits, rebuild respecting byte limit
    if " + " in line:
        parts = line.split(" + ")
        out: list[str] = []
        buf = parts[0]
        for p in parts[1:]:
            # also break p if it's a single huge '...'
            pieces = [p]
            if p.strip().startswith("'") and utf8_len(p) > MAX_BYTES:
                # extract string content and resplit
                sm = re.fullmatch(r"(\s*)'((?:[^']|'')*)'(.*)", p)
                if sm:
                    lead, inner, trail = sm.group(1), sm.group(2), sm.group(3)
                    content = inner.replace("''", "'")
                    sub = split_string_content(content, MAX_BYTES - 10)
                    pieces = []
                    for i, c in enumerate(sub):
                        prefix = lead if i == 0 else ""
                        pieces.append(prefix + encode_pascal_chunk(c) + (trail if i == len(sub) - 1 else ""))
            for piece in pieces:
                candidate = buf + " + " + piece
                if utf8_len(candidate) <= MAX_BYTES:
                    buf = candidate
                else:
                    out.append(buf + " +")
                    buf = cont + piece.lstrip()
                    if utf8_len(buf) > MAX_BYTES:
                        # hard break inside
                        sm = re.match(r"(\s*)'((?:[^']|'')*)'(.*)$", buf, re.S)
                        if sm:
                            lead, inner, trail = sm.group(1), sm.group(2), sm.group(3)
                            content = inner.replace("''", "'")
                            sub = split_string_content(content, MAX_BYTES - 20)
                            for i, c in enumerate(sub):
                                if i < len(sub) - 1:
                                    out.append((lead if i == 0 else cont) + encode_pascal_chunk(c) + " +")
                                else:
                                    buf = (lead if i == 0 else cont) + encode_pascal_chunk(c) + trail
                        else:
                            # last resort hard cut by bytes
                            b = buf.encode("utf-8")
                            while len(b) > MAX_BYTES:
                                # cut at char boundary
                                cut = MAX_BYTES - 20
                                while cut > 0 and (b[cut] & 0xC0) == 0x80:
                                    cut -= 1
                                chunk = b[:cut].decode("utf-8", errors="ignore")
                                out.append(chunk)
                                b = b[cut:]
                                buf = cont + b.decode("utf-8", errors="ignore")
                            else:
                                buf = cont + b.decode("utf-8", errors="ignore") if isinstance(b, bytes) else buf
        out.append(buf)
        return out

    # Whole line is one or more juxtaposed strings — find the big '...' and split
    m = re.search(r"'((?:[^']|'')*)'", line)
    if not m:
        # hard byte split
        b = line.encode("utf-8")
        out = []
        while len(b) > MAX_BYTES:
            cut = MAX_BYTES - 10
            while cut > 0 and (b[cut] & 0xC0) == 0x80:
                cut -= 1
            out.append(b[:cut].decode("utf-8"))
            b = b[cut:]
        out.append(b.decode("utf-8"))
        return out

    # Split all string atoms that are too big; rebuild line with +
    def repl_atom(mm: re.Match) -> str:
        inner = mm.group(1)
        content = inner.replace("''", "'")
        enc = encode_pascal_chunk(content)
        if utf8_len(enc) <= MAX_BYTES:
            return enc
        subs = split_string_content(content, MAX_BYTES - 10)
        return " + ".join(encode_pascal_chunk(c) for c in subs)

    rebuilt = STR_ATOM.sub(repl_atom, line) if False else None

    STR = re.compile(r"'((?:[^']|'')*)'")
    rebuilt = STR.sub(lambda mm: (
        encode_pascal_chunk(mm.group(1).replace("''", "'"))
        if utf8_len(encode_pascal_chunk(mm.group(1).replace("''", "'"))) <= MAX_BYTES
        else " + ".join(
            encode_pascal_chunk(c)
            for c in split_string_content(mm.group(1).replace("''", "'"), MAX_BYTES - 10)
        )
    ), line)

    # Now break physical lines on +
    return break_line(rebuilt) if utf8_len(rebuilt) > 1023 else [rebuilt]


# Fix recursion: break_line calling itself — simplify main path

def break_line_simple(line: str) -> list[str]:
    if utf8_len(line) <= 1023:
        return [line]

    indent_m = re.match(r"^(\s*)", line)
    indent = indent_m.group(1) if indent_m else "    "
    cont = indent + "  "

    # Expand any single huge quotes into + chunks first
    def expand(mm: re.Match) -> str:
        content = mm.group(1).replace("''", "'")
        enc = encode_pascal_chunk(content)
        if utf8_len(enc) <= MAX_BYTES:
            return enc
        return " + ".join(
            encode_pascal_chunk(c)
            for c in split_string_content(content, MAX_BYTES - 10)
        )

    line2 = re.sub(r"'((?:[^']|'')*)'", expand, line)

    parts = line2.split(" + ")
    out: list[str] = []
    buf = parts[0]
    for p in parts[1:]:
        cand = buf + " + " + p
        if utf8_len(cand) <= MAX_BYTES:
            buf = cand
        else:
            out.append(buf + " +")
            buf = cont + p.lstrip()
    out.append(buf)

    # Final safety
    final: list[str] = []
    for L in out:
        if utf8_len(L) <= 1023:
            final.append(L)
        else:
            # should be rare
            b = L.encode("utf-8")
            first = True
            while len(b) > MAX_BYTES:
                cut = MAX_BYTES - 10
                while cut > 0 and (b[cut] & 0xC0) == 0x80:
                    cut -= 1
                piece = b[:cut].decode("utf-8")
                final.append(piece if first else cont + piece.lstrip())
                first = False
                b = b[cut:]
            rest = b.decode("utf-8")
            final.append(rest if first else cont + rest.lstrip())
    return final


def main() -> None:
    raw = UI18N.read_bytes()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    lines = text.splitlines(keepends=True)

    new_lines: list[str] = []
    fixed = 0
    for idx, line in enumerate(lines):
        if line.endswith("\r\n"):
            core, nl = line[:-2], "\r\n"
        elif line.endswith("\n"):
            core, nl = line[:-1], "\n"
        else:
            core, nl = line.rstrip("\r"), ("\n" if line.endswith("\r") else "")

        if utf8_len(core) > 1023:
            print(f"L{idx+1} chars={len(core)} utf8={utf8_len(core)}", flush=True)
            parts = break_line_simple(core)
            for p in parts:
                new_lines.append(p + nl)
                if utf8_len(p) > 1023:
                    print(f"  STILL {utf8_len(p)}", flush=True)
            fixed += 1
        else:
            new_lines.append(line)

    out = "".join(new_lines).encode("utf-8")
    if bom:
        out = b"\xef\xbb\xbf" + out
    UI18N.write_bytes(out)
    print(f"fixed {fixed}", flush=True)

    text2 = UI18N.read_text(encoding="utf-8-sig")
    rem = [
        (i + 1, len(l), len(l.encode("utf-8")))
        for i, l in enumerate(text2.splitlines())
        if len(l.encode("utf-8")) > 1023
    ]
    print(f"remaining utf8>1023: {len(rem)}")
    for i, c, b in rem[:10]:
        print(f"  L{i} chars={c} utf8={b}")


if __name__ == "__main__":
    main()
