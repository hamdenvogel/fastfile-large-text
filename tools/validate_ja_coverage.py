# -*- coding: utf-8 -*-
from pathlib import Path
import re, json

t = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas").read_text(encoding="utf-8-sig")
u = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\UnConsts.pas").read_text(encoding="utf-8")
cache = json.loads(Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\tools\ja_translation_cache.json").read_text(encoding="utf-8"))

print("APP_VER", re.search(r"APPLICATION_VERSION = '([^']+)'", u).group(1))
print("HISTORY current", re.search(r"v3\.0\.5\.\d+[^\n']*current", u).group(0))
print("JA body count", t.count("GTextJapanese.Values[K] := JA"))
print("Set11(", len(re.findall(r"\bSet11\s*\(", t)))
print("TAGLINE Set11", "Set11(TAGLINE" in t)

# Analyze Set12 last args: how many end with CJK vs English
ATOM = r"(?:'(?:[^']|'')*'|#\d+)"
STR_EXPR = rf"(?:{ATOM})(?:\s*(?:\+\s*)?(?:{ATOM}))*"

def skip(text, i):
    n=len(text)
    while i<n:
        if text[i] in ' \t\r\n':
            i+=1; continue
        if text.startswith('//',i):
            while i<n and text[i] not in '\r\n': i+=1
            continue
        if text[i]=='{':
            j=text.find('}',i+1)
            i = n if j<0 else j+1
            continue
        break
    return i

def decode(expr):
    s=re.sub(r'\s*\+\s*','',expr.strip())
    out=[]; i=0; n=len(s)
    while i<n:
        if s[i]=="'":
            i+=1; buf=[]
            while i<n:
                if s[i]=="'":
                    if i+1<n and s[i+1]=="'":
                        buf.append("'"); i+=2; continue
                    i+=1; break
                buf.append(s[i]); i+=1
            out.append(''.join(buf))
        elif s[i]=='#':
            i+=1; j=i
            while j<n and s[j].isdigit(): j+=1
            out.append(chr(int(s[i:j]))); i=j
        else:
            i+=1
    return ''.join(out)

cjk=0; same_en=0; total=0; samples=[]
for m in re.finditer(r"\bSet12\s*\(", t):
    i=skip(t, m.end())
    args=[]
    ok=True
    for li in range(13):  # key + 12 langs
        i=skip(t,i)
        if li==0 and t.startswith('TAGLINE_KEY', i):
            args.append('TAGLINE_KEY'); i+=len('TAGLINE_KEY')
        else:
            em=re.match(STR_EXPR, t[i:])
            if not em:
                ok=False; break
            args.append(em.group(0)); i+=em.end()
        i=skip(t,i)
        if li<12:
            if i>=len(t) or t[i]!=',':
                ok=False; break
            i+=1
        else:
            if i>=len(t) or t[i]!=')':
                ok=False; break
    if not ok or len(args)<13:
        continue
    total+=1
    en=decode(args[1]) if args[1]!='TAGLINE_KEY' else 'TAGLINE'
    ja=decode(args[12]) if args[12]!='TAGLINE_KEY' else 'TAGLINE'
    if re.search(r'[\u3040-\u30ff\u4e00-\u9fff]', ja):
        cjk+=1
    elif ja==en:
        same_en+=1
        if len(samples)<5:
            samples.append(en[:60])
print('Set12 parsed', total, 'JA_cjk', cjk, 'JA_same_EN', same_en)
print('samples same EN:', samples)

# direct assigns
pat=re.compile(r"GTextJapanese\.Values\['((?:[^']|'')*)'\]\s*:=\s*'((?:[^']|'')*)';")
same=0; tot=0; dcjk=0
for m in pat.finditer(t):
    tot+=1
    k=m.group(1).replace("''","'"); v=m.group(2).replace("''","'")
    if k==v: same+=1
    if re.search(r'[\u3040-\u30ff\u4e00-\u9fff]', v): dcjk+=1
print('direct JA', tot, 'same_key', same, 'cjk', dcjk)
print('cache', len(cache))
