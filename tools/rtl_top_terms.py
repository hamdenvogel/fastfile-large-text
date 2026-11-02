"""Lists the most frequent short English UI segments (for curating rtl_overrides.py)."""
import re
import sys
from collections import Counter

sys.path.insert(0, __file__.rsplit("\\", 1)[0])
import gen_rtl_i18n as g  # noqa: E402

d = g.load()
items = g.collect_items(d)
cnt = Counter()
for (_k, _key), src in items.items():
    nl, lines = g.split_item(src)
    for line in lines:
        for part in g.parts_of(line):
            _l, core, _t = g.lead_trail(part)
            if core and g.has_letters(core) and not g.is_codeish(core):
                plain = core.replace("&&", "\0").replace("&", "").replace("\0", "&")
                if len(plain.split()) <= 3 and len(plain) <= 30:
                    cnt[plain] += 1
n = int(sys.argv[1]) if len(sys.argv) > 1 else 300
with open("tools/_top_terms.txt", "w", encoding="utf-8") as f:
    for t, c in cnt.most_common(n):
        f.write("%d\t%s\n" % (c, t))
print(len(cnt), "distinct short segments")
