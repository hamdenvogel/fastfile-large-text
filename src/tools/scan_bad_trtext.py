# Scan .pas for TrText/ShowMessage keys that look Portuguese or mojibake (not found in uI18n English keys sample)
import re, os
SRC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
I18N = os.path.join(SRC, 'uI18n.pas')
with open(I18N, 'r', encoding='utf-8', errors='replace') as f:
    i18n = f.read()
keys = set(re.findall(r"GTextEnglish\.Values\['([^']+)'\]", i18n))
keys |= set(re.findall(r"Set11\('([^']+)'", i18n))

suspect = []
for root, _, files in os.walk(SRC):
    if 'Old' in root or 'tools' in root or 'FastMM4' in root:
        continue
    for fn in files:
        if not fn.endswith('.pas') or fn.endswith('_utf8.pas'):
            continue
        path = os.path.join(root, fn)
        try:
            with open(path, 'r', encoding='cp1252', errors='replace') as f:
                text = f.read()
        except Exception:
            continue
        for m in re.finditer(r"TrText\('([^']{4,200})'\)", text):
            k = m.group(1)
            if k in keys:
                continue
            if re.search(r'[Erro|Arquivo|linha|mescl|n.o |At.|Copiar|poss|dele|ção|ï¿]', k, re.I):
                suspect.append((fn, k[:100]))
        if len(suspect) > 80:
            break
    if len(suspect) > 80:
        break

print('Sample TrText keys NOT in GTextEnglish (Portuguese/mojibake?), count', len(suspect))
for fn, k in suspect[:40]:
    print(fn, ':', k)
