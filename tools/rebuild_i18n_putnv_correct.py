# -*- coding: utf-8 -*-
"""
Rebuild uI18n.pas PutNV conversion correctly:
1) Start from bak_before_ja (clean .Values[])
2) Caller may have re-applied Japanese already
3) Convert .Values[] -> PutNV with string-aware RHS parsing
4) Inject helpers + collapse + capacity
"""
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(r"c:\Hamden\Sistemas\Backend\delphi\delphi10_4_2\FastFile")
UI18N = ROOT / "src" / "uI18n.pas"
BAK_JA = ROOT / "tools" / "uI18n.pas.bak_before_ja"
BAK_BROKEN = ROOT / "tools" / "uI18n.pas.bak_broken_putnv"

HELPERS = r"""
function ExtractKeyPart(const S: string; Sep: Char): string; forward;

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
  Keep, Seen: TStringList;
  I: Integer;
  Key: string;
begin
  if (Table = nil) or (Table.Count < 2) then Exit;
  Keep := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.CaseSensitive := False;
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Keep.Capacity := Table.Count;
    { Walk newest->oldest so the last PutNV for a key wins. }
    for I := Table.Count - 1 downto 0 do
    begin
      Key := ExtractKeyPart(Table[I], Table.NameValueSeparator);
      if Seen.IndexOf(Key) >= 0 then
        Continue;
      Seen.Add(Key);
      Keep.Add(Table[I]);
    end;
    Table.Clear;
    Table.Capacity := Keep.Count;
    for I := Keep.Count - 1 downto 0 do
      Table.Add(Keep[I]);
  finally
    Keep.Free;
    Seen.Free;
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


def parse_string_literal(s: str, i: int) -> tuple[str, int]:
    assert s[i] == "'"
    j = i + 1
    out = ["'"]
    n = len(s)
    while j < n:
        ch = s[j]
        if ch == "'":
            if j + 1 < n and s[j + 1] == "'":
                out.append("''")
                j += 2
                continue
            out.append("'")
            return "".join(out), j + 1
        out.append(ch)
        j += 1
    raise ValueError(f"Unterminated string at {i}")


def parse_bracket_key(s: str, i: int) -> tuple[str, int]:
    """Parse expression inside Values[ ... ] starting at i (first char of key)."""
    depth = 1
    start = i
    n = len(s)
    while i < n and depth:
        ch = s[i]
        if ch == "'":
            _, i = parse_string_literal(s, i)
            continue
        if ch == "[":
            depth += 1
            i += 1
            continue
        if ch == "]":
            depth -= 1
            if depth == 0:
                return s[start:i].strip(), i + 1
            i += 1
            continue
        i += 1
    raise ValueError("Unbalanced Values[")


def parse_rhs(s: str, i: int) -> tuple[str, int]:
    """Parse Delphi RHS until statement ';' not inside string/comment."""
    n = len(s)
    while i < n and s[i] in " \t\r\n":
        i += 1
    expr_start = i
    while i < n:
        ch = s[i]
        if ch == "'":
            _, i = parse_string_literal(s, i)
            continue
        if ch == "{":
            end = s.find("}", i + 1)
            if end < 0:
                raise ValueError("Unterminated { comment")
            i = end + 1
            continue
        if ch == "/" and i + 1 < n and s[i + 1] == "/":
            end = s.find("\n", i)
            i = n if end < 0 else end
            continue
        if ch == ";":
            return s[expr_start:i].strip(), i + 1
        i += 1
    raise ValueError("No ';' for RHS")


def convert_values(text: str) -> tuple[str, int]:
    pat = re.compile(r"(?P<table>\bG(?:Text)?\w+)\.Values\[")
    out = []
    i = 0
    count = 0
    while True:
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            break
        out.append(text[i : m.start()])
        table = m.group("table")
        key, j = parse_bracket_key(text, m.end())
        while j < len(text) and text[j] in " \t\r\n":
            j += 1
        if text[j : j + 2] != ":=":
            raise ValueError(f"Expected := at {j}: {text[j:j+20]!r}")
        j += 2
        val, j = parse_rhs(text, j)
        # Indent before the match is already in out via text[i:m.start()].
        out.append(f"PutNV({table}, {key}, {val});")
        count += 1
        i = j
    return "".join(out), count


def inject_helpers(text: str) -> str:
    old_create = """function CreateTable: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.NameValueSeparator := '=';
end;"""
    new_create = """function CreateTable: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.NameValueSeparator := '=';
  Result.Capacity := 4096;
end;"""
    if "Result.Capacity := 4096;" not in text:
        if old_create not in text:
            raise SystemExit("CreateTable block not found")
        text = text.replace(old_create, new_create, 1)

    if "procedure PutNV(" not in text:
        needle = "Result.Capacity := 4096;\nend;\n\n{ --- Fast binary-search helpers ------------------------------------------- }"
        alt = "Result.Capacity := 4096;\nend;\n\r\n{ --- Fast binary-search helpers ------------------------------------------- }"
        if needle in text:
            text = text.replace(needle, "Result.Capacity := 4096;\nend;\n" + HELPERS + "\n{ --- Fast binary-search helpers ------------------------------------------- }", 1)
        elif alt in text:
            text = text.replace(alt, "Result.Capacity := 4096;\nend;\n" + HELPERS + "\n{ --- Fast binary-search helpers ------------------------------------------- }", 1)
        else:
            # try looser
            marker = "{ --- Fast binary-search helpers ------------------------------------------- }"
            pos = text.find(marker)
            if pos < 0:
                raise SystemExit("helpers marker not found")
            # insert before marker, after CreateTable end
            text = text[:pos] + HELPERS + "\n" + text[pos:]

    sort_block = (
        "  { Sort all tables by key so FastIndexOfName can use binary search. }\n"
        "  SortTablesForFastLookup;"
    )
    new_block = (
        "  { Collapse duplicate keys (last write wins) then sort for binary lookup. }\n"
        "  CollapseAllTranslationTables;\n"
        "  SortTablesForFastLookup;"
    )
    if "CollapseAllTranslationTables;" in text and "CollapseAllTranslationTables;\n  SortTablesForFastLookup" not in text:
        # only procedure decl present — still need call
        if sort_block in text:
            text = text.replace(sort_block, new_block, 1)
    elif sort_block in text:
        text = text.replace(sort_block, new_block, 1)
    elif "CollapseAllTranslationTables;\n  SortTablesForFastLookup;" not in text:
        # already converted file variant
        if "SortTablesForFastLookup;" in text and "CollapseAllTranslationTables;\n  SortTablesForFastLookup;" not in text:
            text = text.replace(
                "  SortTablesForFastLookup;",
                "  CollapseAllTranslationTables;\n  SortTablesForFastLookup;",
                1,
            )
    return text


def validate_putnv_lines(text: str) -> list[tuple[int, str]]:
    """Return list of (line_no, err) for single-line PutNV that don't close properly.
    Multi-line PutNV (ending with +) are skipped.
    """
    bad = []
    lines = text.splitlines()
    for n, line in enumerate(lines, 1):
        if "PutNV(" not in line:
            continue
        if line.rstrip().endswith("+"):
            continue
        if "procedure PutNV(" in line:
            continue
        # quick check: must end with );
        stripped = line.rstrip()
        if not stripped.endswith(");"):
            # might be multi-line start without + on same line rare
            if "PutNV(" in line and not stripped.endswith(";"):
                continue
            bad.append((n, f"does not end with ); -> {stripped[-40:]}"))
            continue
    return bad


def main() -> None:
    if not BAK_JA.exists():
        raise SystemExit(f"Missing {BAK_JA}")

    # Preserve broken file for forensics
    if UI18N.exists():
        shutil.copy2(UI18N, BAK_BROKEN)
        print(f"Saved broken file to {BAK_BROKEN}")

    # Start from pre-Japanese backup — Japanese will be reapplied by caller if needed.
    # If current already has Japanese plumbing AND we pass --from-current-clean,
    # we can't use broken current. Default: bak_before_ja.
    text = BAK_JA.read_text(encoding="utf-8")
    print(f"Loaded bak_before_ja ({len(text)} chars), Values={text.count('.Values[')}")

    text = inject_helpers(text)
    text, n = convert_values(text)
    print(f"Converted Values->PutNV: {n}")
    print(f"Remaining .Values[: {text.count('.Values[')}")

    bad = validate_putnv_lines(text)
    print(f"Suspicious PutNV endings: {len(bad)}")
    for item in bad[:20]:
        print(" ", item)

    UI18N.write_text(text, encoding="utf-8")
    print(f"Wrote {UI18N}")
    print("NOTE: Japanese not in bak_before_ja — re-run restore_japanese_i18n.py next.")


if __name__ == "__main__":
    main()
