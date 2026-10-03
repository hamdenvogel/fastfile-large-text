# -*- coding: utf-8 -*-
"""Bump FF_HELP.AssistantBlock version and append 14-language note."""
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
p = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
raw = p.read_bytes()
bom = raw.startswith(b"\xef\xbb\xbf")
text = raw.decode("utf-8-sig")
nl = "\r\n" if "\r\n" in text else "\n"
text_n = text.replace("\r\n", "\n")

start = text_n.find("procedure AddCommonTranslationsHelpAssistantBlock;")
end = text_n.find("procedure AddCommonTranslationsHelpEmEditorBlock;")
if start < 0 or end < 0 or end <= start:
    raise SystemExit("AssistantBlock procedure bounds not found")

block = text_n[start:end]
old_count = block.count("v3.0.5.100")
block2 = block.replace("v3.0.5.100", "v3.0.5.210")
print(f"version replacements in AssistantBlock: {old_count}")

# Append a short UI-languages sentence before the closing of each language
# argument that ends with AssistantLog / ASkin.ini lines — safer: inject after version bump only.
# Add dedicated sentence after first sentence in EN and mirrors via replacements:

extras = [
    (
        "Optional startup (ASkin.ini: AssistantShowOnStartup). AssistantLog=1 appends Assistant.log.",
        "UI languages: 14 (incl. Japanese, Chinese Simplified/Traditional). "
        "Optional startup (ASkin.ini: AssistantShowOnStartup). AssistantLog=1 appends Assistant.log.",
    ),
    (
        "Arranque opcional (ASkin.ini). AssistantLog=1.",
        "UI em 14 idiomas (incl. japones e chines simplificado/tradicional). "
        "Arranque opcional (ASkin.ini). AssistantLog=1.",
    ),
    (
        "Inicio opcional (ASkin.ini).",
        "Idiomas de UI: 14 (incl. japones y chino simplificado/tradicional). "
        "Inicio opcional (ASkin.ini).",
    ),
    (
        "Demarrage optionnel (ASkin.ini).",
        "14 langues d''interface (jap. + chinois simplifie/traditionnel). "
        "Demarrage optionnel (ASkin.ini).",
    ),
    (
        "Optionaler Start (ASkin.ini).",
        "14 UI-Sprachen (inkl. Japanisch, Chin. vereinfacht/traditionell). "
        "Optionaler Start (ASkin.ini).",
    ),
    (
        "Avvio opzionale (ASkin.ini).",
        "14 lingue UI (incl. giapponese e cinese semplificato/tradizionale). "
        "Avvio opzionale (ASkin.ini).",
    ),
    (
        "Opcjonalny start (ASkin.ini).",
        "14 jezykow UI (wl. japonski oraz chinski uproszczony/tradycyjny). "
        "Opcjonalny start (ASkin.ini).",
    ),
    # PT-PT may share PT ending — try both
    (
        "Arranque opcional (ASkin.ini).",
        "UI em 14 idiomas (incl. japones e chines simplificado/tradicional). "
        "Arranque opcional (ASkin.ini).",
    ),
]

applied = 0
for a, b in extras:
    if a in block2 and b not in block2:
        block2 = block2.replace(a, b, 1)
        applied += 1
        print(f"extra OK: {a[:40]!r}...")

# RO / HU / CZ / JA / ZH — find endings
more = [
    (
        "Pornire optionala (ASkin.ini).",
        "14 limbi UI (incl. japoneza si chineza simplificata/traditionala). "
        "Pornire optionala (ASkin.ini).",
    ),
    (
        "Inditas opcionalis (ASkin.ini).",
        "14 UI nyelv (japan + egyszerusitett/hagyomanyos kinai). "
        "Inditas opcionalis (ASkin.ini).",
    ),
    (
        "Volitelne pri startu (ASkin.ini).",
        "14 jazyku UI (vc. japonstiny a cinstiny zjednodusene/tradicni). "
        "Volitelne pri startu (ASkin.ini).",
    ),
    (
        "AssistantLog=1でAssistant.logに追記。",
        "UI言語は14（日本語・簡体字/繁体字中国語を含む）。AssistantLog=1でAssistant.logに追記。",
    ),
    (
        "AssistantLog=1 会追加到 Assistant.log。",
        "界面语言共 14 种（含日语、简体/繁体中文）。AssistantLog=1 会追加到 Assistant.log。",
    ),
    (
        "AssistantLog=1 會附加到 Assistant.log。",
        "介面語言共 14 種（含日語、簡體/繁體中文）。AssistantLog=1 會附加到 Assistant.log。",
    ),
]
for a, b in more:
    if a in block2 and b not in block2:
        block2 = block2.replace(a, b, 1)
        applied += 1
        print(f"extra2 OK: {a[:40]!r}")

print(f"extra sentences applied: {applied}")

# Italian may use different ending - check
if "14 lingue UI" not in block2:
    # try alternate IT ending from file
    m = re.search(r"Avvio opzionale \(ASkin\.ini\)\.[^']*", block2)
    print("IT snippet:", m.group(0)[:80] if m else "not found")

text_n = text_n[:start] + block2 + text_n[end:]
out = text_n.replace("\n", nl)
data = out.encode("utf-8")
if bom:
    data = b"\xef\xbb\xbf" + data
p.write_bytes(data)
print("Wrote uI18n.pas")

# verify no literal > 255 in that block
bad = 0
for li, line in enumerate(block2.splitlines(), 1):
    i = 0
    while i < len(line):
        if line[i] != "'":
            i += 1
            continue
        i += 1
        buf = []
        while i < len(line):
            if line[i] == "'":
                if i + 1 < len(line) and line[i + 1] == "'":
                    buf.append("'")
                    i += 2
                    continue
                break
            buf.append(line[i])
            i += 1
        if i < len(line) and line[i] == "'":
            i += 1
        if len(buf) > 255:
            bad += 1
            print(f"BAD lit len {len(buf)} near AssistantBlock relative line {li}")
print(f"bad literals in block: {bad}")
