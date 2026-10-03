# -*- coding: utf-8 -*-
"""Normalize uI18n.pas: at most one blank line; remove spurious blanks between code lines."""
from pathlib import Path
import re

PATH = Path(__file__).resolve().parents[1] / 'uI18n.pas'

KEEP_AFTER = re.compile(
    r'^(end;?\s*$|implementation\s*$|interface\s*$)$', re.I
)
KEEP_BEFORE = re.compile(
    r'^(procedure|function|type|const|var|uses|implementation|interface|initialization|finalization)\b',
    re.I,
)
SECTION_END = re.compile(r';?\s*$')


def trimmed(s: str) -> str:
    return s.strip()


def is_blank(s: str) -> bool:
    return trimmed(s) == ''


def should_keep_blank(prev: str, nxt: str) -> bool:
    if not prev or not nxt:
        return bool(prev or nxt)
    p = trimmed(prev)
    n = trimmed(nxt)

    if KEEP_AFTER.match(p):
        return True
    if KEEP_BEFORE.match(n):
        return True

    # interface declaration block: keep one blank between declarations
    if p.endswith(';') and KEEP_BEFORE.match(n):
        return True

    # after end; before next procedure
    if re.search(r'\bend;?\s*$', p, re.I) and KEEP_BEFORE.match(n):
        return True

    # do not keep blank inside uses / enum / continued statements
    if p.endswith(','):
        return False
    if p.endswith(('+', '(', 'and', 'or', 'then', 'do', 'of')):
        return False
    if p.endswith(':') and not p.endswith('::') and 'Set11' not in p and ':=' not in p:
        # type TAppLanguage = ( ...  -- line ending with : only on "type" line rare
        if p.lower() in ('type', 'uses', 'var', 'const'):
            return False
    if p.lower() in ('begin', 'type', 'uses', 'var', 'const', 'interface', 'implementation'):
        return False
    if n.startswith(("'", '#')):
        return False
    if p.endswith(';') and (n.startswith('G') or '.Values[' in n or 'Set11' in n or n.startswith('if ')):
        return False
    if p.endswith(';') and not KEEP_BEFORE.match(n):
        return False

    return False


def normalize(lines: list[str]) -> list[str]:
    # strip trailing empty at EOF
    while lines and is_blank(lines[-1]):
        lines.pop()

    out: list[str] = []
    i = 0
    n = len(lines)
    while i < n:
        if not is_blank(lines[i]):
            out.append(lines[i].rstrip('\r\n') + '\n')
            i += 1
            continue

        # collect run of blanks
        j = i
        while j < n and is_blank(lines[j]):
            j += 1
        prev = out[-1] if out else ''
        nxt = lines[j] if j < n else ''
        if should_keep_blank(prev, nxt):
            if out and not is_blank(out[-1]):
                out.append('\n')
        i = j

    # collapse any accidental doubles
    final: list[str] = []
    for line in out:
        if is_blank(line):
            if final and not is_blank(final[-1]):
                final.append('\n')
        else:
            final.append(line)
    while final and is_blank(final[-1]):
        final.pop()
    if final and not final[-1].endswith('\n'):
        final[-1] += '\n'
    return final


def main() -> None:
    raw = PATH.read_bytes()
    text = raw.decode('utf-8', errors='replace')
    lines = text.splitlines(keepends=True)
    if not lines:
        lines = [text]
    before = len(lines)
    blank_before = sum(1 for ln in lines if is_blank(ln))
    result = normalize(lines)
    blank_after = sum(1 for ln in result if is_blank(ln))
    PATH.write_text(''.join(result), encoding='utf-8', newline='')
    print(f'lines {before} -> {len(result)}, blank lines {blank_before} -> {blank_after}')


if __name__ == '__main__':
    main()
