"""Remove a dangling '+' after a string literal right before ')' ',' or ';'
(E2029 Expression expected).  Usage: fix_dangling_plus.py <file.pas>"""
import re
import sys

p = sys.argv[1]
raw = open(p, 'rb').read()
bom = raw.startswith(b'\xef\xbb\xbf')
s = raw.decode('utf-8-sig')
pat = re.compile(r"(')[ \t]*\+[ \t]*(?:\r\n[ \t]*)?(?=[),;])")
hits = [s.count('\n', 0, m.start()) + 1 for m in pat.finditer(s)]
print('fixed:', len(hits), hits[:60])
s2 = pat.sub(r'\1', s)
open(p, 'wb').write((b'\xef\xbb\xbf' if bom else b'') + s2.encode('utf-8'))
