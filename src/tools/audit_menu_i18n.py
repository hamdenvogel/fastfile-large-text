import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "MainUnit.pas").read_text(encoding="utf-8", errors="replace")
i18n = (root / "uI18n.pas").read_text(encoding="utf-8", errors="replace")

blocks = []
for name in [
    "BuildMenu",
    "BuildListViewPopupMenu",
    "LocalizeTopToolbar",
    "UpdateToolsPopupFastFileExtrasCaptions",
    "BuildToolbarOverflowMenu",
]:
    m = re.search(rf"procedure TfrmMain\.{name}.*?\nend;", main, re.S)
    if m:
        blocks.append(m.group(0))

trtext_keys = set()
tr_keys = set()  # (symbolic_key, default_en)
for b in blocks:
    for m in re.finditer(r"TrText\('([^']*(?:''[^']*)*)'\)", b):
        trtext_keys.add(m.group(1).replace("''", "'"))
    for m in re.finditer(r"Tr\('([^']+)',\s*'([^']*(?:''[^']*)*)'\)", b):
        tr_keys.add((m.group(1), m.group(2).replace("''", "'")))

lang_map_gtext = {
    "PT": "GTextPortuguese",
}
lang_map_g = {
    "PT": "GPortuguese",
}

translations_gtext = {}
translations_g = {}

set11_re = re.compile(
    r"Set11\(\s*'((?:[^']|'')+)'\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'",
    re.S,
)
for m in set11_re.finditer(i18n):
    key = m.group(1).replace("''", "'")
    en = m.group(2).replace("''", "'")
    pt = m.group(3).replace("''", "'")
    if key not in translations_gtext:
        translations_gtext[key] = set()
    if pt and pt != en:
        translations_gtext[key].add("PT")

for lang_code, gtext in lang_map_gtext.items():
    pat = rf"{re.escape(gtext)}\.Values\['((?:[^']|'')+)'\]\s*:=\s*'((?:[^']|'')*)'"
    for m in re.finditer(pat, i18n):
        key = m.group(1).replace("''", "'")
        val = m.group(2).replace("''", "'")
        if key not in translations_gtext:
            translations_gtext[key] = set()
        if val and val != key:
            translations_gtext[key].add(lang_code)

for lang_code, gtable in lang_map_g.items():
    pat = rf"{re.escape(gtable)}\.Values\['((?:[^']|'')+)'\]\s*:=\s*'((?:[^']|'')*)'"
    for m in re.finditer(pat, i18n):
        key = m.group(1).replace("''", "'")
        val = m.group(2).replace("''", "'")
        if key not in translations_g:
            translations_g[key] = set()
        if val and val != key:
            translations_g[key].add(lang_code)

missing_trtext = []
for k in sorted(trtext_keys):
    if "PT" not in translations_gtext.get(k, set()):
        missing_trtext.append(k)

missing_tr = []
for sym, default in sorted(tr_keys):
    if "PT" not in translations_g.get(sym, set()):
        missing_tr.append(f"{sym} (default: {default})")

print(f"Menu TrText keys: {len(trtext_keys)}")
print(f"Menu Tr symbolic keys: {len(tr_keys)}")
print(f"TrText missing PT: {len(missing_trtext)}")
for k in missing_trtext:
    print(f"  TrText MISSING PT: {k}")
print(f"Tr missing PT (GPortuguese by key): {len(missing_tr)}")
for k in missing_tr:
    print(f"  Tr MISSING PT: {k}")

out = root / "tools" / "menu_i18n_missing_pt.txt"
out.write_text(
    "\n".join(["[TrText]"] + missing_trtext + ["", "[Tr]"] + missing_tr),
    encoding="utf-8",
)
print(f"\nWrote {out}")
