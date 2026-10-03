#!/usr/bin/env python3
"""Move MainUnit.pas constants into UnConsts.pas (full pass)."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAIN = ROOT / "MainUnit.pas"
UNCONSTS = ROOT / "UnConsts.pas"

KEEP_LOCAL = {"HELP_TEXT", "HISTORY"}
SKIP_TYPED_ARRAY = re.compile(r":\s*array\b", re.I)
SKIP_BOOL_TYPED = re.compile(r":\s*Boolean\s*=", re.I)

CONFLICT_RENAMES = {
    ("GAP", "TfrmMain.EnsureSplitEqualPartsTab;"): "FF_SPLIT_EQUAL_PARTS_GAP",
    ("GAP", "TfrmMain.EnsureSplitFractionTab;"): "FF_SPLIT_FRACTION_GAP",
    ("GAP", "TfrmMain.EnsureSplitByPatternTab;"): "FF_SPLIT_BY_PATTERN_GAP",
    ("MAX_LINES", "ReadPythonMacroFileSampleForAI"): "FF_PY_MACRO_SAMPLE_MAX_LINES",
    ("MAX_LINES", "ReadSplitPatternFileSampleForAI"): "FF_SPLIT_PATTERN_SAMPLE_MAX_LINES",
    ("MAX_LINE_CH", "ReadPythonMacroFileSampleForAI"): "FF_PY_MACRO_MAX_LINE_CH",
    ("MAX_LINE_CH", "ReadSplitPatternFileFirstPhysicalLines"): "FF_SPLIT_PATTERN_MAX_LINE_CH",
    (
        "PROGRESS_EVERY",
        "TExportFilteredLinesThread.ExecuteStreamExport;",
    ): "FF_EXPORT_STREAM_PROGRESS_EVERY",
    (
        "PROGRESS_EVERY",
        "TExportFilteredLinesThread.ExecuteOwnerLineExport;",
    ): "FF_EXPORT_OWNER_PROGRESS_EVERY",
    (
        "SEP",
        "TfrmMain.ShowHelpDialog;",
    ): "FF_HELP_DIALOG_SEP",
    (
        "SEP",
        "TfrmMain.TailMacroSuggestionsExtractExampleBlock:",
    ): "FF_TAIL_MACRO_EXAMPLE_SEP",
    (
        "SEP",
        "TfrmMain.TailMacroSuggestionsLoadContent;",
    ): "FF_TAIL_MACRO_LOAD_SEP",
    (
        "SEP",
        "TfrmMain.ScriptSuggestionsLoadContent;",
    ): "FF_SCRIPT_SUGGESTIONS_SEP",
    ("NL", "TfrmMain.TailMacroSuggestionsLoadContent;"): "FF_TAIL_MACRO_NL",
    ("NL", "TfrmMain.ScriptSuggestionsLoadContent;"): "FF_SCRIPT_SUGGESTIONS_NL",
}

ALIAS_EXISTING = {
    ("TEMPFILE", "'temp2.txt'"): "TEMP_POSTLINE_FILE",
}

SKIP_VALUES = {
    "AllModifierKeys",  # depends on TModifierKey in MainUnit
}


def strip_comments(s: str) -> str:
    s = re.sub(r"\{.*?\}", "", s)
    s = re.sub(r"//.*$", "", s)
    return s.strip()


def find_proc_ranges(lines: list[str]) -> dict[str, tuple[int, int]]:
    """Map procedure name -> (start_line, end_line) 0-based inclusive start, exclusive end."""
    ranges: dict[str, tuple[int, int]] = {}
    stack: list[tuple[str, int]] = []
    for i, line in enumerate(lines):
        m = re.match(r"^(procedure|function)\s+([\w.]+)", line.strip())
        if m:
            stack.append((m.group(2), i))
        if re.match(r"^end;\s*$", line.strip()) and stack:
            name, start = stack.pop()
            ranges[name] = (start, i + 1)
    return ranges


def parse_const_name(first_line: str) -> tuple[str, str] | None:
    line = strip_comments(first_line.strip())
    m = re.match(r"^(\w+)((?::\s*[\w\[\].\s]+)?)\s*=\s*(.*)$", line)
    if not m:
        return None
    return m.group(1), m.group(3).strip()


def is_multiline_expr(item_lines: list[str]) -> bool:
    text = " ".join(strip_comments(l) for l in item_lines)
    if "+" in text and ("'" in text or "#" in text):
        return True
    if item_lines[0].strip().endswith("+") :
        return True
    return False


def extract_const_blocks(lines: list[str]) -> list[dict]:
    in_interface = True
    current_proc: str | None = None
    items: list[dict] = []

    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if stripped == "implementation":
            in_interface = False
            current_proc = None
        m = re.match(r"^(procedure|function)\s+([\w.]+)", stripped)
        if m:
            current_proc = m.group(2)
        if re.match(r"^end;\s*$", stripped) and current_proc:
            current_proc = None

        if stripped != "const" and not stripped.startswith("const "):
            i += 1
            continue

        indent = len(lines[i]) - len(lines[i].lstrip())
        scope = (
            "interface"
            if in_interface
            else (current_proc if current_proc else "implementation")
        )

        j = i + 1
        while j < len(lines):
            ls = lines[j].strip()
            if not ls:
                j += 1
                continue
            li = len(lines[j]) - len(lines[j].lstrip())
            if li < indent:
                break
            if li == indent and re.match(
                r"^(var|type|begin|procedure|function)\b", ls
            ):
                break
            j += 1

        k = i + 1
        while k < j:
            while k < j and not lines[k].strip():
                k += 1
            if k >= j:
                break
            ls = lines[k].strip()
            if ls.startswith("{") or ls.startswith("//"):
                k += 1
                continue

            item_start = k
            item_lines = [lines[k]]
            k += 1
            while k < j:
                nxt = lines[k].strip()
                if not nxt or nxt.startswith("//") or nxt.startswith("{"):
                    item_lines.append(lines[k])
                    k += 1
                    continue
                li = len(lines[k]) - len(lines[k].lstrip())
                if li <= indent:
                    test = strip_comments(nxt)
                    if re.match(r"^\w+(\s*:\s*[\w\[\].\s]+)?\s*=", test):
                        break
                item_lines.append(lines[k])
                k += 1

            parsed = parse_const_name(item_lines[0])
            if not parsed:
                continue
            name, val_part = parsed
            if name in KEEP_LOCAL or name in SKIP_VALUES:
                continue
            if SKIP_TYPED_ARRAY.search(item_lines[0]) or SKIP_BOOL_TYPED.search(
                item_lines[0]
            ):
                continue

            multiline_expr = is_multiline_expr(item_lines)
            if multiline_expr:
                continue

            # Join wrapped single expression (no +)
            full = " ".join(strip_comments(l) for l in item_lines)
            m = re.match(r"^\w+(?::\s*[\w\[\].\s]+)?\s*=\s*(.+)$", full)
            value = m.group(1).strip() if m else val_part
            value = value.rstrip(";").strip()

            typed = ":" in strip_comments(item_lines[0]).split("=")[0]

            items.append(
                {
                    "scope": scope,
                    "name": name,
                    "value": value,
                    "typed_decl": typed,
                    "item_start": item_start,
                    "item_end": k,
                    "migratable": True,
                }
            )

        i = j

    return items


def global_name(scope: str, name: str, value: str, registry: dict[str, str]) -> str:
    key = (name, scope)
    if key in CONFLICT_RENAMES:
        return CONFLICT_RENAMES[key]
    norm = re.sub(r"\s+", " ", value)
    for (n, v), existing in ALIAS_EXISTING.items():
        if n == name and norm == v:
            return existing
    if name in registry and registry[name] == value:
        return name
    if name in registry and registry[name] != value:
        return CONFLICT_RENAMES.get(key) or f"FF_{scope.split('.')[-1].replace(';','')}_{name}"
    registry[name] = value
    return name


def build_mapping(items: list[dict]) -> tuple[dict[tuple[str, str], str], dict[str, str]]:
    registry: dict[str, str] = {}
    mapping: dict[tuple[str, str], str] = {}
    values: dict[str, str] = {}
    for it in items:
        g = global_name(it["scope"], it["name"], it["value"], registry)
        mapping[(it["scope"], it["name"])] = g
        values[g] = it["value"]
    return mapping, values


def format_decl(name: str, value: str, typed: bool, original_first_line: str) -> str:
    if typed and re.search(r":\s*\w+\s*=", original_first_line):
        lhs = strip_comments(original_first_line.split("=")[0].strip())
        return f"  {lhs} = {value};"
    return f"  {name} = {value};"


def needs_graphics(values: dict[str, str]) -> bool:
    blob = " ".join(values.values())
    return "TColor(" in blob or re.search(r"\bcl[A-Z]\w*", blob)


def remove_partial_unconsts(text: str) -> str:
    marker = "  { --- MainUnit.pas (centralized) --- }"
    if marker not in text:
        return text
    start = text.index(marker)
    end = text.index("\nimplementation\n")
    return text[:start].rstrip() + "\n\n" + text[end + 1 :]


def build_unconsts_section(values: dict[str, str], items: list[dict]) -> str:
    # map global name -> original typed first line
    typed_src: dict[str, str] = {}
    for it in items:
        g = None
        for (sc, nm), gn in build_mapping([it])[0].items():
            g = gn
        typed_src[g] = items[[x["name"] for x in items].index(it["name"])]  # noqa

    lines = ["  { --- MainUnit.pas (centralized) --- }", ""]

    sections = [
        (
            "Status / I/O / index",
            [
                "INFO_FILE_TIME",
                "INFO_EDIT_TIME",
                "OUT_BUFFER_SIZE",
                "INDEX_RECORD_SIZE",
                "CKPT_INTERVAL",
                "INDEX_REC_SIZE",
            ],
        ),
        (
            "ListView icon / checkbox layout",
            [
                "W_64",
                "H_64",
                "CheckWidth",
                "CheckHeight",
                "CheckBiasTop",
                "CheckBiasLeft",
                "MAX_LINE_LEN_DISPLAY",
                "ASSISTANT_FILTER_CLIPBOARD_MAX_LINES",
            ],
        ),
        (
            "Windows language IDs (Delphi 7)",
            [
                "LANG_PORTUGUESE",
                "LANG_SPANISH",
                "LANG_FRENCH",
                "LANG_GERMAN",
                "LANG_ITALIAN",
                "LANG_POLISH",
                "LANG_ROMANIAN",
                "LANG_HUNGARIAN",
                "LANG_CZECH",
                "SUBLANG_PORTUGUESE",
                "SUBLANG_PORTUGUESE_BRAZILIAN",
            ],
        ),
        (
            "Bookmarks, marks, menu bitmaps",
            [
                "IMAGELIST_IDX_ZOOM_LIST",
                "FF_MENU_BMP_ZOOM_LIST",
                "FF_BOOKMARK_ROW_BG",
                "FF_BOOKMARK_ROW_FG",
                "FF_BOOKMARK_STRIPE",
                "FF_TAIL_NEW_ROW_BG",
                "FF_CL_MARK_TAB",
                "FF_CL_MARK_SPACE",
                "FF_CL_MARK_CR",
                "FF_CL_MARK_LF",
                "FF_CL_MARK_NUL",
                "FF_CL_MARK_CTRL",
                "MENU_BITMAP_SUBPATH_HOT16",
                "MENU_BITMAP_SUBPATH_TRICH16",
                "MENU_BITMAP_SUBPATH_TRICH32",
            ],
        ),
        (
            "Idle workspace / logo",
            [
                "IDLE_LOGO_PNG",
                "IDLE_LOGO_ALPHA",
                "IDLE_LOGO_MAX_PX",
                "IDLE_LOGO_SIZE_FRAC",
                "IDLE_LOGO_WATERMARK_SIZE_FRAC",
                "IDLE_LOGO_WATERMARK_BLEND",
                "IDLE_LOGO_STRETCH_SUPERSAMPLE",
                "IDLE_LOGO_SOURCE_MIN_PX",
                "IDLE_LOGO_SOURCE_MAX_PX",
                "IDLE_LOGO_SOURCE_LORES_PX",
                "IDLE_LOGO_PNG_HIRES_REL",
                "IDLE_LOGO_BG_SIZE_FRAC",
                "IDLE_LOGO_BG_ALPHA",
                "IDLE_LOGO_PROCESS_REV",
                "IDLE_LOGO_HALO_BORDER_PX",
                "IDLE_LOGO_HALO_MAX_ALPHA",
                "IDLE_LOGO_TITLE_COLOR",
                "IDLE_LOGO_TAGLINE_COLOR",
                "IDLE_LOGO_TITLE_FONT_MIN",
                "IDLE_LOGO_TITLE_FONT_MAX",
                "IDLE_LOGO_TITLE_FONT_DIV",
                "IDLE_WORKSPACE_GRAD_LEFT",
                "IDLE_WORKSPACE_GRAD_RIGHT",
                "IDLE_WORKSPACE_BG_ALPHA",
            ],
        ),
        (
            "Help dialog markers",
            [
                "CRLF",
                "FF_HELP_DIALOG_SEP",
                "MK_HELP_GOTO_BYTE",
                "MK_HELP_FILTER_ROW",
                "MK_HELP_FILTER_FEATURE",
                "MK_HELP_READONLY_ROW",
                "MK_HELP_COPY_INSERT_ROW",
                "MK_HELP_PASTE_INSERT_ROW",
                "MK_HELP_MENUBAR_L1",
                "MK_HELP_MENUBAR_L2",
                "MK_HELP_VIEW_ZOOM_IN",
                "MK_HELP_VIEW_ZOOM_OUT",
                "MK_HELP_COMPARE_MERGE",
                "MK_HELP_COMPARE_MERGE_RELOAD_1",
                "MK_HELP_COMPARE_MERGE_RELOAD_2",
                "MK_HELP_ZERO_SCAN",
                "MK_HELP_EMEDITOR",
                "MK_HELP_ASSISTANT",
                "MK_HELP_AI_CHAT",
                "MK_HELP_ADV_AI_CHAT",
                "MK_HELP_VERSION",
                "MK_HELP_READ_PANEL",
                "MK_HELP_IDLE_WORKSPACE",
            ],
        ),
    ]

    used: set[str] = set()
    for title, keys in sections:
        present = [k for k in keys if k in values]
        if not present:
            continue
        lines.append(f"  {{ MainUnit — {title} }}")
        for k in sorted(present):
            lines.append(f"  {k} = {values[k]};")
            used.add(k)
        lines.append("")

    rest = sorted(set(values.keys()) - used)
    if rest:
        lines.append("  { MainUnit — other }")
        for k in rest:
            lines.append(f"  {k} = {values[k]};")
        lines.append("")

    return "\n".join(lines)


def remove_migrated_lines(lines: list[str], items: list[dict]) -> list[str]:
    remove = {idx for it in items for idx in range(it["item_start"], it["item_end"])}

    i = 0
    while i < len(lines):
        st = lines[i].strip()
        if st == "const" or st.startswith("const "):
            indent = len(lines[i]) - len(lines[i].lstrip())
            j = i + 1
            has_code = False
            while j < len(lines):
                ls = lines[j].strip()
                if not ls or ls.startswith("//") or ls.startswith("{"):
                    j += 1
                    continue
                li = len(lines[j]) - len(lines[j].lstrip())
                if li <= indent and re.match(
                    r"^(var|type|begin|procedure|function)\b", ls
                ):
                    break
                if j not in remove:
                    has_code = True
                    break
                j += 1
            if not has_code:
                remove.add(i)
                k = i + 1
                while k < j:
                    remove.add(k)
                    k += 1
            i = j
            continue
        i += 1

    return [ln for idx, ln in enumerate(lines) if idx not in remove]


def apply_scoped_renames(
    lines: list[str],
    items: list[dict],
    mapping: dict[tuple[str, str], str],
    proc_ranges: dict[str, tuple[int, int]],
) -> list[str]:
    # Per item: rename old->new within scope range
    scope_ranges: dict[str, tuple[int, int]] = {"interface": (0, len(lines))}
    scope_ranges.update(proc_ranges)
    scope_ranges["implementation"] = (0, len(lines))

    result = lines[:]
    for it in items:
        old = it["name"]
        new = mapping[(it["scope"], old)]
        if old == new:
            continue
        scope = it["scope"]
        if scope == "interface":
            start, end = 0, len(result)
            for idx, ln in enumerate(result):
                if ln.strip() == "implementation":
                    end = idx
                    break
        elif scope in proc_ranges:
            start, end = proc_ranges[scope]
        else:
            impl_start = next(
                i for i, ln in enumerate(result) if ln.strip() == "implementation"
            )
            start, end = impl_start, len(result)

        for idx in range(start, end):
            result[idx] = re.sub(r"\b" + re.escape(old) + r"\b", new, result[idx])

    return result


def main():
    lines = MAIN.read_text(encoding="utf-8", errors="replace").splitlines()
    items = [x for x in extract_const_blocks(lines) if x["migratable"]]
    mapping, values = build_mapping(items)
    proc_ranges = find_proc_ranges(lines)

    un_text = remove_partial_unconsts(
        UNCONSTS.read_text(encoding="utf-8", errors="replace")
    )
    existing = set(re.findall(r"^\s*(\w+)\s*=", un_text, re.MULTILINE))
    to_add = {k: v for k, v in values.items() if k not in existing}

    if needs_graphics(to_add) and "Graphics" not in un_text:
        un_text = un_text.replace(
            "interface\n\nconst",
            "interface\n\nuses\n  Graphics;\n\nconst",
        )

    section = build_unconsts_section(to_add, items)
    un_text = un_text.replace("\nimplementation\n", "\n" + section + "\nimplementation\n")
    UNCONSTS.write_text(un_text, encoding="utf-8", newline="\n")

    new_lines = remove_migrated_lines(lines, items)
    new_lines = apply_scoped_renames(new_lines, items, mapping, proc_ranges)
    MAIN.write_text("\n".join(new_lines) + "\n", encoding="utf-8", newline="\n")

    print(f"Migrated constants: {len(items)}")
    print(f"Added to UnConsts: {len(to_add)}")
    remaining = sum(1 for ln in new_lines if ln.strip() == "const")
    print(f"Remaining const blocks in MainUnit: {remaining}")


if __name__ == "__main__":
    main()
