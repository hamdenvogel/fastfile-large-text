# -*- coding: utf-8 -*-
"""Fix missing Japanese plumbing in uI18n.pas after Set12 conversion."""
from pathlib import Path
import re

UI18N = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")
text = UI18N.read_text(encoding="utf-8-sig")

# 1) vars
if "GJapanese:" not in text:
    text = text.replace(
        "  GCzech: TStringList = nil;\n",
        "  GCzech: TStringList = nil;\n  GJapanese: TStringList = nil;\n",
    )
if "GTextJapanese:" not in text:
    text = text.replace(
        "  GTextCzech: TStringList = nil;\n",
        "  GTextCzech: TStringList = nil;\n  GTextJapanese: TStringList = nil;\n",
    )

# 2) sort
if "GJapanese.CustomSort" not in text:
    text = text.replace(
        "  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);\n",
        "  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);\n"
        "  if Assigned(GJapanese)         then GJapanese.CustomSort(CompareTableByKey);\n",
    )
if "GTextJapanese.CustomSort" not in text:
    text = text.replace(
        "  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);\n",
        "  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);\n"
        "  if Assigned(GTextJapanese)     then GTextJapanese.CustomSort(CompareTableByKey);\n",
    )

# 3) create / assign / free
if "GJapanese       := CreateTable" not in text and "GJapanese := CreateTable" not in text:
    text = text.replace(
        "  GCzech          := CreateTable;\n",
        "  GCzech          := CreateTable;\n  GJapanese       := CreateTable;\n",
    )
if "GTextJapanese   := CreateTable" not in text and "GTextJapanese := CreateTable" not in text:
    text = text.replace(
        "  GTextCzech      := CreateTable;\n",
        "  GTextCzech      := CreateTable;\n  GTextJapanese   := CreateTable;\n",
    )
if "GTextJapanese.Assign" not in text:
    text = text.replace(
        "  GTextCzech.Assign(GTextEnglish);\n",
        "  GTextCzech.Assign(GTextEnglish);\n  GTextJapanese.Assign(GTextEnglish);\n",
    )
if "FreeAndNil(GJapanese)" not in text:
    text = text.replace(
        "  FreeAndNil(GCzech);\n",
        "  FreeAndNil(GCzech);\n  FreeAndNil(GJapanese);\n",
    )
if "FreeAndNil(GTextJapanese)" not in text:
    text = text.replace(
        "  FreeAndNil(GTextCzech);\n",
        "  FreeAndNil(GTextCzech);\n  FreeAndNil(GTextJapanese);\n",
    )

# 4) table lookups
if "alJapanese:     Result := GTextJapanese" not in text:
    text = text.replace(
        "    alCzech:        Result := GTextCzech;\n  else\n    Result := GTextEnglish;",
        "    alCzech:        Result := GTextCzech;\n"
        "    alJapanese:     Result := GTextJapanese;\n"
        "  else\n    Result := GTextEnglish;",
    )
if "alJapanese:     Result := GJapanese" not in text:
    text = text.replace(
        "    alCzech:        Result := GCzech;\n  else\n    Result := GEnglish;",
        "    alCzech:        Result := GCzech;\n"
        "    alJapanese:     Result := GJapanese;\n"
        "  else\n    Result := GEnglish;",
    )

# 5) language codes
if "alJapanese" not in text[text.find("function AppLanguageFromCode"): text.find("function AppLanguageFromCode") + 800]:
    text = text.replace(
        "  else if (Normalized = 'cs') or (Normalized = 'cs-cz') or (Normalized = 'czech') then\n"
        "    Result := alCzech\n"
        "  else\n"
        "    Result := alEnglish;",
        "  else if (Normalized = 'cs') or (Normalized = 'cs-cz') or (Normalized = 'czech') then\n"
        "    Result := alCzech\n"
        "  else if (Normalized = 'ja') or (Normalized = 'ja-jp') or (Normalized = 'japanese') then\n"
        "    Result := alJapanese\n"
        "  else\n"
        "    Result := alEnglish;",
    )
if "alJapanese:     Result := 'ja'" not in text:
    text = text.replace(
        "    alCzech:        Result := 'cs';\n  else\n    Result := 'en';",
        "    alCzech:        Result := 'cs';\n"
        "    alJapanese:     Result := 'ja';\n"
        "  else\n    Result := 'en';",
    )

# 6) Set12 body must assign JA
n_before = text.count("GTextJapanese.Values[K] := JA;")
text2 = re.sub(
    r"(GTextCzech\.Values\[K\]\s*:=\s*CZ;\n)(\s*end;)",
    r"\1    GTextJapanese.Values[K] := JA;\n\2",
    text,
)
# also unindented variant
text2 = re.sub(
    r"(GTextCzech\.Values\[K\]\s*:=\s*CZ;\n)(end;)",
    r"\1  GTextJapanese.Values[K] := JA;\n\2",
    text2,
)
n_after = text2.count("GTextJapanese.Values[K] := JA;")
print("JA assigns added:", n_after - n_before, "total", n_after)
text = text2

# 7) leftover Set11(TAGLINE...) -> Set12 (already has JA arg hopefully)
# Check arity of that call — if still Set11 with 11 langs, rename after ensuring JA present
if "Set11(" in text:
    print("Found leftover Set11 — renaming to Set12 if 12 langs already")
    # TAGLINE call was converted with JA at end? Check nearby
    idx = text.find("Set11(")
    print("context:", repr(text[idx:idx+80]))
    # If it still says Set11 but has japanese as last arg from previous conversion...
    # Our rewrite only did Set11->Set12 for iter_set11 matches; TAGLINE uses Set11(TAGLINE_KEY without quotes as first arg!
    # Fix manually: rename Set11 to Set12 for that one — but need JA arg.
    # Read until closing paren is hard; use simpler: if Set11(TAGLINE_KEY exists, replace name only if JA already there
    if "Set11(TAGLINE_KEY" in text:
        # Find block and ensure Japanese last string — look for pattern ending before );
        # Safer: convert Set11(TAGLINE_KEY to Set12(TAGLINE_KEY and append JA if only 11 strings
        print("TAGLINE Set11 needs special handling")

# language.option.japanese
if "language.option.japanese" not in text:
    print("WARNING: language.option.japanese missing")

UI18N.write_bytes(b"\xef\xbb\xbf" + text.encode("utf-8"))
print("Wrote fixes")
print("GJapanese var", "GJapanese:" in text)
print("Create GTextJapanese", "GTextJapanese   := CreateTable" in text)
print("Assign", "GTextJapanese.Assign" in text)
print("Lookup", "alJapanese:     Result := GTextJapanese" in text)
print("Code ja", "alJapanese:     Result := 'ja'" in text)
