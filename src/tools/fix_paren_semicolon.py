"""Repair literals in uI18n.pas where '; ' was corrupted into '); '.

A ')' directly before ';' that has no matching '(' inside the same literal
(adjacent 'a'#233'b' pieces are one literal) is removed.
Usage: python fix_paren_semicolon.py [--apply]
"""
import re
import sys
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / "uI18n.pas"
GROUP = re.compile(r"(?:'(?:[^']|'')*'|#\$?[0-9A-Fa-f]+)+")


def decode_group(g):
    """Return list of (is_text, raw_piece) and logical text with positions."""
    return re.findall(r"'(?:[^']|'')*'|#\$?[0-9A-Fa-f]+", g)


def fix_group(g):
    pieces = decode_group(g)
    # Build logical char stream mapped back to (piece index, offset in raw piece).
    chars = []
    for pi, p in enumerate(pieces):
        if p.startswith("'"):
            body = p[1:-1]
            j = 0
            while j < len(body):
                if body[j] == "'":
                    chars.append(("'", pi, j + 1, 2))
                    j += 2
                else:
                    chars.append((body[j], pi, j + 1, 1))
                    j += 1
        else:
            chars.append(("\0", pi, 0, len(p)))
    depth = 0
    drop = set()
    for k, (c, pi, off, ln) in enumerate(chars):
        if c == "(":
            depth += 1
        elif c == ")":
            if depth > 0:
                depth -= 1
            elif k + 1 < len(chars) and chars[k + 1][0] == ";":
                drop.add((pi, off))
    if not drop:
        return g, 0
    out = []
    for pi, p in enumerate(pieces):
        offs = sorted(o for (q, o) in drop if q == pi)
        for o in reversed(offs):
            p = p[:o] + p[o + 1:]
        out.append(p)
    return "".join(out), len(drop)


def main():
    apply = "--apply" in sys.argv
    raw = PATH.read_bytes()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    lines = text.split("\n")
    total = 0
    samples = []
    for i, line in enumerate(lines):
        if "'" not in line or ");" not in line:
            continue
        code = line.split("//")[0] if "'" not in line.split("//")[0][-1:] else line

        def repl(m):
            nonlocal total
            new, n = fix_group(m.group(0))
            if n:
                total += n
                if len(samples) < 25:
                    samples.append((i + 1, m.group(0)[:110], new[:110]))
            return new

        lines[i] = GROUP.sub(repl, line)
    sys.stdout.reconfigure(encoding="utf-8")
    for s in samples:
        print(s[0], "\n  -", s[1], "\n  +", s[2])
    print("fixes:", total)
    if apply:
        out = "\n".join(lines).encode("utf-8")
        PATH.write_bytes((b"\xef\xbb\xbf" if bom else b"") + out)
        print("written")


if __name__ == "__main__":
    main()
