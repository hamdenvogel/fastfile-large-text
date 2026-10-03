# -*- coding: utf-8 -*-
"""Rewrite uI18n bulk .Values[] writes to O(1) PutNV appends."""
from __future__ import annotations

import re
from pathlib import Path

PATH = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile\src\uI18n.pas")

HELPERS = r"""
{ Append Name=Value in O(1). Bulk build uses PutNV; duplicates are collapsed
  (last wins) before SortTablesForFastLookup. Avoid TStringList.Values during
  population — IndexOfName is O(n) and makes startup O(n^2). }
procedure PutNV(Table: TStringList; const Name, Value: string);
begin
  if Table = nil then Exit;
  Table.Add(Name + Table.NameValueSeparator + Value);
end;

procedure CollapseDuplicateKeysKeepLast(Table: TStringList);
var
  I: Integer;
  CurKey, NextKey: string;
begin
  if (Table = nil) or (Table.Count < 2) then Exit;
  Table.CustomSort(CompareTableByKey);
  I := Table.Count - 2;
  while I >= 0 do
  begin
    CurKey := ExtractKeyPart(Table[I], Table.NameValueSeparator);
    NextKey := ExtractKeyPart(Table[I + 1], Table.NameValueSeparator);
    if CompareText(CurKey, NextKey) = 0 then
      Table.Delete(I);
    Dec(I);
  end;
end;

procedure CollapseAllTranslationTables;
begin
  CollapseDuplicateKeysKeepLast(GEnglish);
  CollapseDuplicateKeysKeepLast(GPortuguese);
  CollapseDuplicateKeysKeepLast(GSpanish);
  CollapseDuplicateKeysKeepLast(GFrench);
  CollapseDuplicateKeysKeepLast(GGerman);
  CollapseDuplicateKeysKeepLast(GItalian);
  CollapseDuplicateKeysKeepLast(GPolish);
  CollapseDuplicateKeysKeepLast(GPortuguesePT);
  CollapseDuplicateKeysKeepLast(GRomanian);
  CollapseDuplicateKeysKeepLast(GHungarian);
  CollapseDuplicateKeysKeepLast(GCzech);
  CollapseDuplicateKeysKeepLast(GJapanese);
  CollapseDuplicateKeysKeepLast(GTextEnglish);
  CollapseDuplicateKeysKeepLast(GTextPortuguese);
  CollapseDuplicateKeysKeepLast(GTextSpanish);
  CollapseDuplicateKeysKeepLast(GTextFrench);
  CollapseDuplicateKeysKeepLast(GTextGerman);
  CollapseDuplicateKeysKeepLast(GTextItalian);
  CollapseDuplicateKeysKeepLast(GTextPolish);
  CollapseDuplicateKeysKeepLast(GTextPortuguesePT);
  CollapseDuplicateKeysKeepLast(GTextRomanian);
  CollapseDuplicateKeysKeepLast(GTextHungarian);
  CollapseDuplicateKeysKeepLast(GTextCzech);
  CollapseDuplicateKeysKeepLast(GTextJapanese);
end;

"""


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    orig = text

    # 1) CreateTable: preallocate capacity
    text = text.replace(
        """function CreateTable: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.NameValueSeparator := '=';
end;""",
        """function CreateTable: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.NameValueSeparator := '=';
  Result.Capacity := 4096;
end;""",
    )

    # 2) Insert helpers after CreateTable
    if "procedure PutNV(" not in text:
        needle = "Result.Capacity := 4096;\nend;\n\n{ --- Fast binary-search helpers ------------------------------------------- }"
        if needle not in text:
            raise SystemExit("CreateTable anchor not found for helpers insert")
        text = text.replace(
            needle,
            "Result.Capacity := 4096;\nend;\n"
            + HELPERS
            + "\n{ --- Fast binary-search helpers ------------------------------------------- }",
            1,
        )

    # 3) Replace Table.Values[Key] := Value with PutNV(Table, Key, Value)
    #    Supports multi-line RHS ending at ';'
    values_pat = re.compile(
        r"(?P<table>\bG(?:Text)?\w+)\.Values\[(?P<key>[^\]]+)\]\s*:=\s*(?P<val>.*?);",
        re.DOTALL,
    )

    def repl_values(m: re.Match) -> str:
        table = m.group("table")
        key = m.group("key").strip()
        val = m.group("val").strip()
        # Keep indentation of original line start by returning without leading ws
        return f"PutNV({table}, {key}, {val});"

    text2, n_values = values_pat.subn(repl_values, text)
    text = text2

    # 4) Rewrite nested Set12 bodies that still assign via Values (if any left
    #    inside Set12 — they should already be PutNV from step 3).
    #    Also rewrite any Set12 that uses G*.Values pattern for key tables.
    #    Normalize Set12 bodies that look like GTextX.Values / Gx.Values — done.

    # 5) Before SortTablesForFastLookup, collapse duplicates (last wins)
    sort_call = "  { Sort all tables by key so FastIndexOfName can use binary search. }\n  SortTablesForFastLookup;"
    collapse_call = (
        "  { Collapse duplicate keys (last write wins) then sort for binary lookup. }\n"
        "  CollapseAllTranslationTables;\n"
        "  SortTablesForFastLookup;"
    )
    if "CollapseAllTranslationTables;" not in text:
        if sort_call not in text:
            raise SystemExit("SortTablesForFastLookup anchor not found")
        text = text.replace(sort_call, collapse_call, 1)

    if text == orig:
        print("No changes made")
        return

    PATH.write_text(text, encoding="utf-8")
    print(f"Wrote {PATH}")
    print(f"Values->PutNV replacements: {n_values}")
    print(f"Remaining .Values[: {text.count('.Values[')}")


if __name__ == "__main__":
    main()
