"""Split Delphi string-literal groups longer than 255 elements (E2056).
A group is adjacent parts without '+':  'abc'#13#10'def'  counts as one literal.
Usage: fix_long_literals.py <file.pas> [--dry]
"""
import re
import sys
from pathlib import Path

PART = re.compile(r"'(?:[^'\r\n]|'')*'|#\$[0-9A-Fa-f]+|#\d+")
GROUP = re.compile(r"(?:'(?:[^'\r\n]|'')*'|#\$[0-9A-Fa-f]+|#\d+)+")
MAX_ELEMS = 255
CHUNK = 200


def elems(part):
    if part.startswith('#'):
        return 1
    body = part[1:-1].replace("''", "'")
    return sum(2 if ord(c) > 0xFFFF else 1 for c in body)


def split_group(group, indent):
    chunks, cur, n = [], '', 0
    for p in PART.findall(group):
        if p.startswith("'"):
            body = p[1:-1].replace("''", "'")
            while body:
                room = CHUNK - n
                if room <= 0:
                    chunks.append(cur)
                    cur, n = '', 0
                    continue
                take, body = body[:room], body[room:]
                cur += "'" + take.replace("'", "''") + "'"
                n += len(take)
        else:
            if n >= CHUNK:
                chunks.append(cur)
                cur, n = '', 0
            cur += p
            n += 1
    if cur:
        chunks.append(cur)
    return (' +\r\n' + indent).join(chunks)


def main():
    path = Path(sys.argv[1])
    dry = '--dry' in sys.argv
    raw = path.read_bytes()
    bom = raw.startswith(b'\xef\xbb\xbf')
    s = raw.decode('utf-8-sig')
    lines = s.split('\r\n')
    fixed = 0
    for i, line in enumerate(lines):
        if len(line) < MAX_ELEMS:
            continue
        stripped = line.lstrip()
        if stripped.startswith(('//', '{', '(*')):
            continue
        indent = line[:len(line) - len(stripped)]

        def rep(m):
            nonlocal fixed
            g = m.group(0)
            if sum(elems(p) for p in PART.findall(g)) <= MAX_ELEMS:
                return g
            fixed += 1
            return split_group(g, indent + '  ')
        new = GROUP.sub(rep, line)
        if new != line:
            if dry:
                print(i + 1, line[:90])
            lines[i] = new
    print('groups split:', fixed)
    if not dry and fixed:
        data = '\r\n'.join(lines).encode('utf-8')
        path.write_bytes((b'\xef\xbb\xbf' if bom else b'') + data)


if __name__ == '__main__':
    main()
