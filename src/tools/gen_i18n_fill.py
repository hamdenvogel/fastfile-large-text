"""Generate AddCommonTranslationsAuditFill in uI18n.pas from tools/i18n_fill/*.py.

Data files call helpers (injected into their namespace):
  A(key, pt, es, fr, de, it, pl, ro, hu, cz, ja, zhcn, zhtw)   all languages
  B(key, es, fr, de, it, pl, ro, hu, cz, ja)                     PT already exists
  C(key, pl, ro, hu, cz, ja=None)                                Western + JA gap
  J(key, ja)                                                     Japanese only
  L(key, **{lang: text})                                         explicit languages
PT-PT is derived from PT (Brazil) unless given explicitly via L(key, PTPT=...).
Only (key, language) pairs reported missing by audit_i18n_full.py are emitted.
Usage: python gen_i18n_fill.py [--apply]
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audit_i18n_full as audit  # noqa: E402

TOOLS = Path(__file__).resolve().parent
I18N = audit.I18N
LANG_TABLE = {
    "EN": "GTextEnglish", "PT": "GTextPortuguese", "ES": "GTextSpanish", "FR": "GTextFrench",
    "DE": "GTextGerman", "IT": "GTextItalian", "PL": "GTextPolish", "PTPT": "GTextPortuguesePT",
    "RO": "GTextRomanian", "HU": "GTextHungarian", "CZ": "GTextCzech", "JA": "GTextJapanese",
    "ZHCN": "GTextChineseSimplified", "ZHTW": "GTextChineseTraditional",
}
BEGIN = "{ BEGIN AUTO-GENERATED: AuditFill (tools/gen_i18n_fill.py) }"
END = "{ END AUTO-GENERATED: AuditFill }"

DATA = {}


def _put(key, **vals):
    DATA.setdefault(key, {}).update({k: v for k, v in vals.items() if v is not None})


def A(key, pt, es, fr, de, it, pl, ro, hu, cz, ja, zhcn, zhtw):
    _put(key, PT=pt, ES=es, FR=fr, DE=de, IT=it, PL=pl, RO=ro, HU=hu, CZ=cz, JA=ja, ZHCN=zhcn, ZHTW=zhtw)


def B(key, es, fr, de, it, pl, ro, hu, cz, ja):
    _put(key, ES=es, FR=fr, DE=de, IT=it, PL=pl, RO=ro, HU=hu, CZ=cz, JA=ja)


def C(key, pl, ro, hu, cz, ja=None):
    _put(key, PL=pl, RO=ro, HU=hu, CZ=cz, JA=ja)


def J(key, ja):
    _put(key, JA=ja)


def L(key, **vals):
    _put(key, **vals)


# ---------------------------------------------------------------- PT-BR -> PT-PT
PTPT_WORDS = [
    ("arquivos", "ficheiros"), ("arquivo", "ficheiro"), ("telas", "ecrãs"), ("tela", "ecrã"),
    ("usuários", "utilizadores"), ("usuário", "utilizador"), ("salvar", "guardar"),
    ("salvo", "guardado"), ("salvos", "guardados"), ("salva", "guardada"), ("salvas", "guardadas"),
    ("salvando", "a guardar"), ("registro", "registo"), ("registros", "registos"),
    ("equipe", "equipa"), ("deletar", "eliminar"), ("digite", "introduza"), ("baixar", "transferir"),
    ("ônibus", "autocarro"), ("mouse", "rato"), ("clique duplo", "duplo clique"),
    ("econômico", "económico"), ("bilhões", "mil milhões"), ("gerência", "gestão"), ("contato", "contacto"),
]
GERUND_SKIP = {"quando", "comando", "comandos", "bando", "brando", "vindo", "lindo", "bem-vindo",
               "segundo", "mundo", "fundo", "profundo", "grande", "usando", "utilizando"}


def _case_like(src, dst):
    if src.isupper() and len(src) > 1:
        return dst.upper()
    if src[:1].isupper():
        return dst[:1].upper() + dst[1:]
    return dst


def to_ptpt(s):
    for a, b in PTPT_WORDS:
        s = re.sub(r"(?<![\wÀ-ÿ])" + a + r"(?![\wÀ-ÿ])",
                   lambda m, b=b: _case_like(m.group(0), b), s, flags=re.I)

    def ger(m):
        w = m.group(0)
        if w.lower() in GERUND_SKIP or len(w) < 6:
            return w
        low = w.lower()
        for suf, inf in (("ando", "ar"), ("endo", "er"), ("indo", "ir")):
            if low.endswith(suf):
                res = "a " + low[: -len(suf)] + inf
                return _case_like(w, res)
        return w

    return re.sub(r"(?<![\wÀ-ÿ&])[A-Za-zÀ-ÿ]+(?:ando|endo|indo)(?![\wÀ-ÿ])", ger, s)


# ---------------------------------------------------------------- Delphi literal
def _is_raw(ch):
    o = ord(ch)
    return 0x2E80 <= o <= 0x9FFF or 0xF900 <= o <= 0xFAFF or 0xFF00 <= o <= 0xFFEF or 0x3000 <= o <= 0x303F


def delphi_lit(s, width=180):
    """Encode s as a Delphi string expression (never ends a quoted run with #nnn',)."""
    parts = []   # list of tokens: ('q', text) quoted run or ('c', code) char code
    for ch in s:
        o = ord(ch)
        if 32 <= o < 127 or _is_raw(ch):
            if parts and parts[-1][0] == "q":
                parts[-1] = ("q", parts[-1][1] + ch)
            else:
                parts.append(("q", ch))
        else:
            parts.append(("c", o))
    if not parts:
        return "''"
    segs, cur, cur_len = [], [], 0
    for kind, v in parts:
        if kind == "q":
            chunks = [v[i:i + width] for i in range(0, len(v), width)] or [v]
            for i, c in enumerate(chunks):
                tok = "'" + c.replace("'", "''") + "'"
                if cur and (cur_len + len(tok) > width or i > 0):
                    segs.append("".join(cur))
                    cur, cur_len = [], 0
                cur.append(tok)
                cur_len += len(tok)
        else:
            tok = "#%d" % v
            cur.append(tok)
            cur_len += len(tok)
    if cur:
        segs.append("".join(cur))
    return " +\n      ".join(segs)


# ---------------------------------------------------------------- main
def load_data():
    ns = {"A": A, "B": B, "C": C, "J": J, "L": L}
    for p in sorted((TOOLS / "i18n_fill").glob("*.py")):
        exec(compile(p.read_text(encoding="utf-8"), str(p), "exec"), dict(ns))


def main():
    apply = "--apply" in sys.argv
    sys.stdout.reconfigure(encoding="utf-8")
    load_data()
    text, _ = audit.load_tables()
    miss = json.loads((TOOLS / "i18n_missing.json").read_text(encoding="utf-8"))["text"]

    out, unresolved = {l: [] for l in LANG_TABLE}, []
    for key, info in miss.items():
        d = DATA.get(key, {})
        for lang in info["langs"]:
            v = d.get(lang)
            if v is None and lang == "PTPT":
                pt = d.get("PT", text["PT"].get(key))
                if pt is not None:
                    v = to_ptpt(pt)
            if v is None:
                unresolved.append((key, lang))
                continue
            out[lang].append((key, v))

    # Small procedures: Delphi limits literal constants per routine (E2283).
    body, names = [BEGIN], []
    for lang, rows in out.items():
        for n, i in enumerate(range(0, len(rows), 250), 1):
            name = "AuditFill_%s_%d" % (lang, n)
            names.append(name)
            body += ["procedure %s;" % name, "begin"]
            for k, v in rows[i:i + 250]:
                body.append("  PutNV(%s, %s,\n      %s);" % (LANG_TABLE[lang], delphi_lit(k), delphi_lit(v)))
            body += ["end;", ""]
    body += ["procedure AddCommonTranslationsAuditFill;", "begin"]
    body += ["  %s;" % n for n in names]
    body += ["end;", END]
    block = "\n".join(body).replace("\n", "\r\n")

    print("emitted:", sum(len(r) for r in out.values()), "unresolved:", len(unresolved))
    for k, l in unresolved[:80]:
        print("  MISSING", l, repr(k)[:100])
    for k in DATA:
        if k not in miss:
            print("  unused data key:", repr(k)[:100])
    if not apply:
        return
    raw = I18N.read_bytes()
    src = raw.decode("utf-8-sig")
    if BEGIN in src:
        a = src.index(BEGIN)
        b = src.index(END) + len(END)
        src = src[:a] + block + src[b:]
    else:
        anchor = "procedure AddCommonTranslations;"
        a = src.index(anchor)
        src = src[:a] + block + "\r\n\r\n" + src[a:]
    call = "  AddCommonTranslationsAuditFill;"
    if call not in src:
        m = re.search(r"^(\s*)AddCommonTranslationsRecentFilesTab;\s*$", src, re.M)
        src = src[:m.end()] + "\r\n" + call + src[m.end():]
    I18N.write_bytes(b"\xef\xbb\xbf" + src.encode("utf-8"))
    print("uI18n.pas updated")


if __name__ == "__main__":
    main()
