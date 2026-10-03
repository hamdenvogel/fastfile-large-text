"""Rewrite uI18n.pas translation literals:
  - central-European mojibake (#code of cp1250 / ISO-8859-2 bytes) -> real letters;
  - words written without diacritics -> accented form used elsewhere in the
    same language (rules from audit_i18n_accents.word_fixes).
Only literals whose value changes are rewritten.  Run with --dry to preview.
"""
import re
import sys
from collections import Counter

sys.path.insert(0, __file__.rsplit('\\', 1)[0])
from audit_i18n_full import I18N, LANGS, TEXT_TABLES, KEY_TABLES, load_tables  # noqa: E402
from audit_i18n_accents import (ACCENT_LANGS, WORD, fix_mojibake, strip_acc,  # noqa: E402
                                word_fixes, apply_case)

# Plain spellings that are valid words too (never auto-accent).
KEEP_PLAIN = {
    'ES': {'mas', 'solo', 'esta', 'este', 'estas', 'estos', 'aun', 'como', 'donde',
           'cual', 'quien', 'que', 'cuando', 'cuanto', 'tu', 'si', 'mi', 'el', 'publico',
           'practica'},
    'PT': {'esta', 'publico', 'pratica', 'secretaria', 'pais'},
    'PTPT': {'esta', 'publico', 'pratica', 'secretaria', 'pais'},
    'DE': {'zahlen', 'musste', 'wurde', 'konnte', 'wurden', 'große', 'grosse'},
    'FR': {'sur', 'des', 'du', 'ou', 'la', 'a', 'mais', 'marche', 'peche', 'cote',
           'active', 'enregistre', 'supprime', 'copie', 'affiche'},
    'IT': set(),
    'CZ': {'byt', 'rychle'},
    'PL': {'linie', 'sesje'},
    'RO': {'activa', 'nota'},
    'HU': set(),
}
DE_TRANSLIT = str.maketrans({'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'Ä': 'Ae', 'Ö': 'Oe', 'Ü': 'Ue'})


def parse_literal_span(s, i):
    """Like audit_i18n_full.parse_literal but returns (value, start, end)."""
    n = len(s)
    j = i
    while j < n and s[j] in ' \t\r\n':
        j += 1
    start = j
    out = []
    got = False
    i = j
    while True:
        j = i
        if got:
            k = j
            while k < n and s[k] in ' \t\r\n':
                k += 1
            if k < n and s[k] == '+':
                k += 1
                while k < n and s[k] in ' \t\r\n':
                    k += 1
                if k < n and s[k] in "'#":
                    j = k
                else:
                    return ''.join(out), start, i
            elif k != j:
                return ''.join(out), start, i
        if j < n and s[j] == "'":
            j += 1
            buf = []
            while j < n:
                if s[j] == "'":
                    if j + 1 < n and s[j + 1] == "'":
                        buf.append("'")
                        j += 2
                        continue
                    j += 1
                    break
                if s[j] in '\r\n':
                    return (None, start, i) if not got else (''.join(out), start, i)
                buf.append(s[j])
                j += 1
            out.append(''.join(buf))
            got = True
            i = j
            continue
        if j < n and s[j] == '#':
            m = re.match(r'#(\$[0-9A-Fa-f]+|\d+)', s[j:])
            if not m:
                break
            v = m.group(1)
            out.append(chr(int(v[1:], 16) if v.startswith('$') else int(v)))
            got = True
            i = j + len(m.group(0))
            continue
        break
    if not got:
        return None, start, i
    return ''.join(out), start, i


def args_spans(s, i, count):
    res = []
    for _ in range(count):
        v, a, b = parse_literal_span(s, i)
        if v is None:
            return None
        res.append((v, a, b))
        j = b
        while j < len(s) and s[j] in ' \t\r\n':
            j += 1
        if len(res) < count:
            if j >= len(s) or s[j] != ',':
                return None
            j += 1
        i = j
    return res


def render(v, indent):
    """Adjacent parts ('a'#13'b') form ONE Delphi literal (max 255 elements),
    so break with ' +' every ~180 elements, #codes included."""
    parts = []
    cur = ''
    count = 0
    for ch in v:
        o = ord(ch)
        if count >= 180:
            if cur:
                parts.append("'" + cur.replace("'", "''") + "'")
                cur = ''
            parts.append('\n')
            count = 0
        if o < 32 or o == 127:
            if cur:
                parts.append("'" + cur.replace("'", "''") + "'")
                cur = ''
            parts.append('#%d' % o)
        else:
            cur += ch
        count += 1
    if cur:
        parts.append("'" + cur.replace("'", "''") + "'")
    if not parts:
        return "''"
    out = ''
    for p in parts:
        if p == '\n':
            out += ' +\r\n' + indent
        else:
            out += p
    return out.rstrip()


def build_rules(text):
    rules = {}
    for l in ACCENT_LANGS:
        vals = [fix_mojibake(l, v) for v in text[l].values()]
        r = word_fixes(l, vals)
        for w in KEEP_PLAIN.get(l, ()):
            r.pop(w, None)
        if l == 'DE':
            acc_forms = set()
            for v in vals:
                for w in WORD.findall(v):
                    if strip_acc(w) != w:
                        acc_forms.add(w.lower())
            for a in acc_forms:
                t = a.translate(DE_TRANSLIT)
                if t != a and t not in r and len(t) >= 4:
                    r[t] = a
            for w in KEEP_PLAIN['DE']:
                r.pop(w, None)
        rules[l] = r
    return rules


def fix_value(lang, v, rules):
    nv = fix_mojibake(lang, v)
    r = rules.get(lang)
    if r:
        def rep(m):
            w = m.group(0)
            acc = r.get(w.lower())
            if acc and strip_acc(w) == w and w.lower() != acc:
                return apply_case(w, acc)
            return w
        nv = WORD.sub(rep, nv)
    return nv


def main():
    dry = '--dry' in sys.argv
    text, _ = load_tables()
    rules = build_rules(text)
    raw = I18N.read_bytes()
    bom = raw.startswith(b'\xef\xbb\xbf')
    s = raw.decode('utf-8-sig')
    edits = []  # (start, end, newtext)
    stats = Counter()
    en_vals = set(text['EN'].values())

    def consider(lang, v, a, b):
        if lang not in ACCENT_LANGS:
            return
        if v in en_vals and fix_mojibake(lang, v) == v:
            return
        nv = fix_value(lang, v, rules)
        if nv != v:
            line_start = s.rfind('\n', 0, a) + 1
            indent = re.match(r'[ \t]*', s[line_start:]).group(0) + '  '
            edits.append((a, b, render(nv, indent)))
            stats[lang] += 1

    # RegexExamples_Set14 holds regex patterns: never touched.
    for m in re.finditer(r'\bSet14\(', s):
        sp = args_spans(s, m.end(), 15)
        if not sp:
            continue
        for lang, (v, a, b) in zip(LANGS, sp[1:]):
            consider(lang, v, a, b)
    for m in re.finditer(r'PutNV\(\s*(\w+)\s*,', s):
        tbl = m.group(1)
        lang = TEXT_TABLES.get(tbl) or KEY_TABLES.get(tbl)
        if not lang:
            continue
        sp = args_spans(s, m.end(), 2)
        if not sp:
            continue
        v, a, b = sp[1]
        consider(lang, v, a, b)

    edits.sort()
    # drop overlaps (should not happen)
    clean, last = [], -1
    for e in edits:
        if e[0] >= last:
            clean.append(e)
            last = e[1]
    print('literals to rewrite:', len(clean), dict(stats))
    if dry:
        for a, b, t in clean[:25]:
            print('  ', s[a:b][:80].replace('\r\n', ' '), '\n   ->', t[:80].replace('\r\n', ' '))
        return
    out = []
    pos = 0
    for a, b, t in clean:
        out.append(s[pos:a])
        out.append(t)
        pos = b
    out.append(s[pos:])
    data = ''.join(out).encode('utf-8')
    if bom:
        data = b'\xef\xbb\xbf' + data
    I18N.write_bytes(data)
    print('written')


if __name__ == '__main__':
    main()
