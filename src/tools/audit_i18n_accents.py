"""Audit / fix translation quality in uI18n.pas.

  1) Mojibake: PL/RO/HU/CS letters stored as single-byte #codes of a
     central-European code page (cp1250 / ISO-8859-2) -> 'ró¿nicy', 'existã'.
  2) Missing diacritics: a word written plain in one value while the same word
     is written accented elsewhere in that language (and never plain in a
     correctly accented value).

Usage: audit_i18n_accents.py            -> report
       audit_i18n_accents.py --samples  -> report + proposed word fixes
"""
import re
import sys
import unicodedata
from collections import Counter, defaultdict

sys.path.insert(0, __file__.rsplit('\\', 1)[0])
from audit_i18n_full import load_tables  # noqa: E402

ALPHA = {
    'PL': set('ąćęłńóśźżĄĆĘŁŃÓŚŹŻ'),
    'CZ': set('áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ'),
    'HU': set('áéíóöőúüűÁÉÍÓÖŐÚÜŰ'),
    'RO': set('ăâîșşțţĂÂÎȘŞȚŢ'),
}
ACCENT_LANGS = ('PT', 'ES', 'FR', 'DE', 'IT', 'PL', 'PTPT', 'RO', 'HU', 'CZ')
WORD = re.compile(r"[^\W\d_]+", re.UNICODE)


def fix_mojibake(lang, v):
    if lang not in ALPHA:
        return v
    out = []
    for ch in v:
        o = ord(ch)
        if 0x80 <= o <= 0xFF and ch not in ALPHA[lang]:
            cand = None
            for enc in ('iso8859_2', 'cp1250'):
                c = bytes([o]).decode(enc, errors='replace')
                if c in ALPHA[lang]:
                    cand = c
                    break
            out.append(cand or ch)
        else:
            out.append(ch)
    return ''.join(out)


def strip_acc(w):
    return ''.join(c for c in unicodedata.normalize('NFD', w)
                   if unicodedata.category(c) != 'Mn')


def word_fixes(lang, vals):
    """plain(lower) -> accented(lower) when unambiguous."""
    accented = defaultdict(Counter)
    plain_in_acc = Counter()
    for v in vals:
        has_acc = strip_acc(v) != v
        for w in WORD.findall(v):
            s = strip_acc(w)
            if s != w:
                accented[s.lower()][w.lower()] += 1
            elif has_acc:
                plain_in_acc[w.lower()] += 1
    fixes = {}
    for plain, forms in accented.items():
        if len(plain) < 3 or len(forms) != 1:
            continue
        acc, n = forms.most_common(1)[0]
        # Plain spelling inside otherwise accented text = either a valid word
        # (keep) or a partially degraded value (fix) -> require clear majority.
        if n >= 2 and n >= 3 * plain_in_acc[plain]:
            fixes[plain] = acc
    return fixes


def apply_case(src, acc):
    if src.isupper():
        return acc.upper()
    if src[:1].isupper():
        return acc[:1].upper() + acc[1:]
    return acc


def fix_words(v, fixes):
    def rep(m):
        w = m.group(0)
        acc = fixes.get(w.lower())
        return apply_case(w, acc) if acc and strip_acc(w) == w else w
    return WORD.sub(rep, v)


def main():
    samples = '--samples' in sys.argv
    text, _ = load_tables()
    print('== 1) mojibake ==')
    for l in ALPHA:
        bad = [(k, v) for k, v in text[l].items() if fix_mojibake(l, v) != v]
        print(l, len(bad))
        for k, v in bad[:4]:
            print('   ', v[:60], '->', fix_mojibake(l, v)[:60])
    print('== 2) missing diacritics ==')
    for l in ACCENT_LANGS:
        vals = {k: fix_mojibake(l, v) for k, v in text[l].items()}
        fixes = word_fixes(l, vals.values())
        changed = [(k, v, fix_words(v, fixes)) for k, v in vals.items()
                   if v != text['EN'].get(k)]
        changed = [c for c in changed if c[1] != c[2]]
        print(l, 'values:', len(changed), 'word-rules:', len(fixes))
        if samples:
            used = Counter()
            for _, v, nv in changed:
                for w in WORD.findall(v):
                    if w.lower() in fixes and strip_acc(w) == w:
                        used[(w.lower(), fixes[w.lower()])] += 1
            print('   top rules:', ', '.join('%s>%s(%d)' % (a, b, n)
                                           for (a, b), n in used.most_common(25)))
            for _, v, nv in changed[:3]:
                print('   ', v[:70])
                print('    ->', nv[:70])


if __name__ == '__main__':
    main()
