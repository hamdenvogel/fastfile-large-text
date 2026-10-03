#!/usr/bin/env python3
"""Generate clean MainUnit constants fragment for UnConsts.pas."""
from __future__ import annotations

import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "tools" / "mainunit_consts_fragment.txt"

# Read original MainUnit from a snapshot is unavailable; build from known migrated set.
# Re-parse current MainUnit remaining + UnConsts corrupted section text.

CONFLICT = {
    ("GAP", "TfrmMain.EnsureSplitEqualPartsTab;"): "FF_SPLIT_EQUAL_PARTS_GAP",
    ("GAP", "TfrmMain.EnsureSplitFractionTab;"): "FF_SPLIT_FRACTION_GAP",
    ("GAP", "TfrmMain.EnsureSplitByPatternTab;"): "FF_SPLIT_BY_PATTERN_GAP",
    ("MAX_LINES", "ReadPythonMacroFileSampleForAI"): "FF_PY_MACRO_SAMPLE_MAX_LINES",
    ("MAX_LINES", "ReadSplitPatternFileSampleForAI"): "FF_SPLIT_PATTERN_SAMPLE_MAX_LINES",
    ("MAX_LINE_CH", "ReadPythonMacroFileSampleForAI"): "FF_PY_MACRO_MAX_LINE_CH",
    ("MAX_LINE_CH", "ReadSplitPatternFileFirstPhysicalLines"): "FF_SPLIT_PATTERN_MAX_LINE_CH",
    ("PROGRESS_EVERY", "TExportFilteredLinesThread.ExecuteStreamExport;"): "FF_EXPORT_STREAM_PROGRESS_EVERY",
    ("PROGRESS_EVERY", "TExportFilteredLinesThread.ExecuteOwnerLineExport;"): "FF_EXPORT_OWNER_PROGRESS_EVERY",
    ("SEP", "TfrmMain.ShowHelpDialog;"): "FF_HELP_DIALOG_SEP",
    ("SEP", "TfrmMain.TailMacroSuggestionsExtractExampleBlock:"): "FF_TAIL_MACRO_EXAMPLE_SEP",
    ("SEP", "TfrmMain.TailMacroSuggestionsLoadContent;"): "FF_TAIL_MACRO_LOAD_SEP",
    ("SEP", "TfrmMain.ScriptSuggestionsLoadContent;"): "FF_SCRIPT_SUGGESTIONS_SEP",
    ("NL", "TfrmMain.TailMacroSuggestionsLoadContent;"): "CRLF",
    ("NL", "TfrmMain.ScriptSuggestionsLoadContent;"): "CRLF",
}

KEEP_LOCAL = {"HELP_TEXT", "HISTORY", "showOtherTabs", "PPIArray", "AllModifierKeys", "TShiftTable", "KB", "MB", "GB"}


def parse_items(lines: list[str]) -> list[dict]:
    in_interface = True
    current_proc = None
    items = []
    i = 0
    while i < len(lines):
        s = lines[i].strip()
        if s == "implementation":
            in_interface = False
            current_proc = None
        m = re.match(r"^(procedure|function)\s+([\w.]+)", s)
        if m:
            current_proc = m.group(2)
        if s == "end;" and current_proc:
            current_proc = None

        if s != "const":
            i += 1
            continue

        indent = len(lines[i]) - len(lines[i].lstrip())
        scope = "interface" if in_interface else (current_proc or "implementation")
        j = i + 1
        while j < len(lines):
            ls = lines[j].strip()
            if not ls:
                j += 1
                continue
            li = len(lines[j]) - len(lines[j].lstrip())
            if li < indent:
                break
            if li == indent and re.match(r"^(var|type|begin|procedure|function)\b", ls):
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
            if re.search(r":\s*array\b", ls, re.I) or re.search(r":\s*Boolean\s*=", ls, re.I):
                # skip item until next top-level name=
                k += 1
                while k < j:
                    nxt = lines[k].strip()
                    if not nxt:
                        k += 1
                        continue
                    li = len(lines[k]) - len(lines[k].lstrip())
                    if li <= indent and re.match(r"^\w+(\s*:\s*[\w\[\].\s]+)?\s*=", re.sub(r"\{.*?\}", "", nxt)):
                        break
                    k += 1
                continue

            item_start = k
            parts = [lines[k]]
            k += 1
            while k < j:
                nxt = lines[k].strip()
                if not nxt or nxt.startswith("//") or nxt.startswith("{"):
                    parts.append(lines[k])
                    k += 1
                    continue
                li = len(lines[k]) - len(lines[k].lstrip())
                test = re.sub(r"\{.*?\}", "", nxt).strip()
                if li <= indent and re.match(r"^\w+(\s*:\s*[\w\[\].\s]+)?\s*=", test):
                    break
                parts.append(lines[k])
                k += 1

            raw = " ".join(p.strip() for p in parts)
            raw = re.sub(r"\{.*?\}", "", raw)
            raw = re.sub(r"//.*", "", raw).strip()
            if not raw or "+" in raw and ("'" in raw or "#" in raw):
                continue
            m2 = re.match(r"^(\w+)((?::\s*[\w\[\].\s]+)?)\s*=\s*(.+)$", raw)
            if not m2:
                continue
            name = m2.group(1)
            if name in KEEP_LOCAL:
                continue
            value = m2.group(3).strip().rstrip(";")
            items.append({"scope": scope, "name": name, "value": value, "typed": bool(m2.group(2).strip())})
        i = j
    return items


def canonical(scope, name, value, reg):
    key = (name, scope)
    if key in CONFLICT:
        return CONFLICT[key]
    if name == "TEMPFILE" and value == "'temp2.txt'":
        return "TEMP_POSTLINE_FILE"
    if name in reg:
        if reg[name] == value:
            return name
        if key in CONFLICT:
            return CONFLICT[key]
        sfx = scope.replace("TfrmMain.", "").replace(";", "").replace(".", "_")
        return f"FF_{sfx}_{name}" if sfx not in ("interface", "implementation", "") else f"FF_{name}_2"
    reg[name] = value
    return name


def main():
    # Use backup-like source: merge interface constants from known list + parse current MainUnit
    interface_consts = """
INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';
INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';
OUT_BUFFER_SIZE = 65536;
INDEX_RECORD_SIZE = 20;
CKPT_INTERVAL = 1024;
W_64: Word = 64;
H_64: Word = 64;
CheckWidth: Word = 14;
CheckHeight: Word = 14;
CheckBiasTop: Word = 2;
CheckBiasLeft: Word = 3;
MAX_LINE_LEN_DISPLAY = 256 * 1024;
ASSISTANT_FILTER_CLIPBOARD_MAX_LINES = 500;
LANG_PORTUGUESE = $16;
LANG_SPANISH = $0A;
LANG_FRENCH = $0C;
LANG_GERMAN = $07;
LANG_ITALIAN = $10;
LANG_POLISH = $15;
LANG_ROMANIAN = $18;
LANG_HUNGARIAN = $0E;
LANG_CZECH = $05;
SUBLANG_PORTUGUESE = 2;
SUBLANG_PORTUGUESE_BRAZILIAN = 1;
"""

    reg: dict[str, str] = OrderedDict()
    ordered_names: list[str] = []

    def add(name, value, scope="interface"):
        g = canonical(scope, name, value, reg)
        if g not in ordered_names:
            ordered_names.append(g)
        reg[g] = value

    for line in interface_consts.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        m = re.match(r"^(\w+)((?::\s*[\w\[\].\s]+)?)\s*=\s*(.+);?$", line)
        if m:
            add(m.group(1), m.group(3).strip())

    main_lines = (ROOT / "MainUnit.pas").read_text(encoding="utf-8", errors="replace").splitlines()
    for it in parse_items(main_lines):
        g = canonical(it["scope"], it["name"], it["value"], reg)
        if g not in ordered_names:
            ordered_names.append(g)
        reg[g] = it["value"]

    # Add constants already referenced in UnConsts first pass (from corrupted block parsing manually)
    extras = {
        "IMAGELIST_IDX_ZOOM_LIST": "91",
        "FF_MENU_BMP_ZOOM_LIST": "'__ff_zoom_list.bmp'",
        "FF_BOOKMARK_ROW_BG": "$00A05000",
        "FF_BOOKMARK_ROW_FG": "clWhite",
        "FF_BOOKMARK_STRIPE": "$006E3700",
        "FF_TAIL_NEW_ROW_BG": "$00C8FFC8",
        "FF_CL_MARK_TAB": "TColor($0000A0FF)",
        "FF_CL_MARK_SPACE": "TColor($00808080)",
        "FF_CL_MARK_CR": "TColor($00FF6000)",
        "FF_CL_MARK_LF": "TColor($0000AA00)",
        "FF_CL_MARK_NUL": "TColor($000000FF)",
        "FF_CL_MARK_CTRL": "TColor($00AA00AA)",
        "MENU_BITMAP_SUBPATH_HOT16": "'Images\\\\ImagesII\\\\glyphspro\\\\glyphspro\\\\16x16\\\\hot\\\\'",
        "MENU_BITMAP_SUBPATH_TRICH16": "'Resources\\\\trichviewicons\\\\bitmaps\\\\normal\\\\16x16\\\\'",
        "MENU_BITMAP_SUBPATH_TRICH32": "'Resources\\\\trichviewicons\\\\bitmaps\\\\normal\\\\32x32\\\\'",
        "IDLE_LOGO_PNG": "'color1_icon_transparent_background.png'",
        "IDLE_LOGO_ALPHA": "188",
        "IDLE_LOGO_MAX_PX": "520",
        "IDLE_LOGO_SIZE_FRAC": "0.44",
        "IDLE_LOGO_WATERMARK_SIZE_FRAC": "0.84",
        "IDLE_LOGO_WATERMARK_BLEND": "68",
        "IDLE_LOGO_STRETCH_SUPERSAMPLE": "4",
        "IDLE_LOGO_SOURCE_MIN_PX": "1024",
        "IDLE_LOGO_SOURCE_MAX_PX": "2048",
        "IDLE_LOGO_SOURCE_LORES_PX": "512",
        "IDLE_LOGO_PNG_HIRES_REL": "'..\\..\\Images\\Logo\\package_highres_mpanlryw\\color1\\icon\\color1_icon_transparent_background.png'",
        "IDLE_LOGO_BG_SIZE_FRAC": "1.0",
        "IDLE_LOGO_BG_ALPHA": "255",
        "IDLE_LOGO_PROCESS_REV": "30",
        "IDLE_LOGO_HALO_BORDER_PX": "4",
        "IDLE_LOGO_HALO_MAX_ALPHA": "52",
        "IDLE_LOGO_TITLE_COLOR": "TColor($00283038)",
        "IDLE_LOGO_TAGLINE_COLOR": "TColor($00404858)",
        "IDLE_LOGO_TITLE_FONT_MIN": "18",
        "IDLE_LOGO_TITLE_FONT_MAX": "34",
        "IDLE_LOGO_TITLE_FONT_DIV": "24",
        "IDLE_WORKSPACE_GRAD_LEFT": "TColor($00FFF8F5)",
        "IDLE_WORKSPACE_GRAD_RIGHT": "TColor($00E8D4B8)",
        "IDLE_WORKSPACE_BG_ALPHA": "255",
        "CRLF": "#13#10",
        "FF_HELP_DIALOG_SEP": "'---------------------------------------------------------------'",
        "MK_HELP_GOTO_BYTE": "'<<<FF_HELP_GOTO_BYTE>>>'",
        "MK_HELP_FILTER_ROW": "'<<<FF_HELP_FILTER_ROW>>>'",
        "MK_HELP_FILTER_FEATURE": "'<<<FF_HELP_FILTER_FEATURE>>>'",
        "MK_HELP_READONLY_ROW": "'<<<FF_HELP_READONLY_ROW>>>'",
        "MK_HELP_COPY_INSERT_ROW": "'<<<FF_HELP_COPY_INSERT_ROW>>>'",
        "MK_HELP_PASTE_INSERT_ROW": "'<<<FF_HELP_PASTE_INSERT_ROW>>>'",
        "MK_HELP_MENUBAR_L1": "'<<<FF_HELP_MENUBAR_L1>>>'",
        "MK_HELP_MENUBAR_L2": "'<<<FF_HELP_MENUBAR_L2>>>'",
        "MK_HELP_VIEW_ZOOM_IN": "'<<<FF_HELP_VIEW_ZOOM_IN>>>'",
        "MK_HELP_VIEW_ZOOM_OUT": "'<<<FF_HELP_VIEW_ZOOM_OUT>>>'",
        "MK_HELP_COMPARE_MERGE": "'<<<FF_HELP_COMPARE_MERGE>>>'",
        "MK_HELP_COMPARE_MERGE_RELOAD_1": "'<<<FF_HELP_COMPARE_MERGE_RELOAD_1>>>'",
        "MK_HELP_COMPARE_MERGE_RELOAD_2": "'<<<FF_HELP_COMPARE_MERGE_RELOAD_2>>>'",
        "MK_HELP_ZERO_SCAN": "'<<<FF_HELP_ZERO_SCAN>>>'",
        "MK_HELP_EMEDITOR": "'<<<FF_HELP_EMEDITOR>>>'",
        "MK_HELP_ASSISTANT": "'<<<FF_HELP_ASSISTANT>>>'",
        "MK_HELP_AI_CHAT": "'<<<FF_HELP_AI_CHAT>>>'",
        "MK_HELP_ADV_AI_CHAT": "'<<<FF_HELP_ADV_AI_CHAT>>>'",
        "MK_HELP_VERSION": "'<<<FF_HELP_VERSION>>>'",
        "MK_HELP_READ_PANEL": "'<<<FF_HELP_READ_PANEL>>>'",
        "MK_HELP_IDLE_WORKSPACE": "'<<<FF_HELP_IDLE_WORKSPACE>>>'",
        "B64Chars": "'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/''",
        "BRIDGE_PREFIX": "'FFBRIDGE|'",
        "ONE_MB": "Int64(1024) * 1024",
        "TAIL_MACRO_CHUNK_MAX_LINES": "100000",
        "MAX_TAIL_READ_CHUNK": "64 * 1024 * 1024",
        "MAX_TAIL_GOTO_LINES": "500",
        "MAX_SCAN_REF": "1000",
        "FF_TAIL_MACRO_LOAD_SEP": "'================================================================' + #13#10",
        "FF_SCRIPT_SUGGESTIONS_SEP": "'================================================================' + #13#10",
    }
    for n, v in extras.items():
        if n not in reg:
            ordered_names.append(n)
            reg[n] = v

    # first pass valid constants from original migration
    first_pass = """
AllModifierKeys B64Chars BACK_SCAN BRIDGE_PREFIX BUF_SIZE CBN_CLOSEUP COL1_PAD COL_EDGE_MARGIN
COUNT_BUF_SIZE EXPORT_NOTIFY_ICON_ID FF_EXPORT_OWNER_PROGRESS_EVERY FF_EXPORT_STREAM_PROGRESS_EVERY
FF_SPLIT_PATTERN_MAX_LINE_CH FF_TAIL_MACRO_EXAMPLE_SEP FIND_SEL_FRAME_OUTER INDEX_REC_SIZE
LVM_SUBITEMHITTEST M MAX_CHARS MAX_EX MAX_INSERT_LINES MAX_LINE_AUTOFILL MAX_LINE_LEN
MAX_MARK_DRAW_CHARS MAX_PREVIEW_SCAN_LINES MAX_SCAN_LINES MAX_UI MESSAGE_FILENAME MaxBufferSize
MaxLen MinWrapRows RADIUS SAMPLE_MAX_LINES TAIL_MAX_LINE WALK_BUF ZERO_SCAN_FULL_COUNT_MAX
ZERO_SCAN_START_EXACT_MAX_LINE ZERO_SCAN_VIRTUAL_CAP cSearchWordText
""".split()
    first_vals = {
        "B64Chars": "'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/''",
        "BACK_SCAN": "65536",
        "BRIDGE_PREFIX": "'FFBRIDGE|'",
        "BUF_SIZE": "1024 * 1024",
        "CBN_CLOSEUP": "8",
        "COL1_PAD": "2",
        "COL_EDGE_MARGIN": "6",
        "COUNT_BUF_SIZE": "4 * 1024 * 1024",
        "EXPORT_NOTIFY_ICON_ID": "1977",
        "FF_EXPORT_OWNER_PROGRESS_EVERY": "64",
        "FF_EXPORT_STREAM_PROGRESS_EVERY": "256",
        "FF_SPLIT_PATTERN_MAX_LINE_CH": "4000",
        "FF_TAIL_MACRO_EXAMPLE_SEP": "'================================================================'",
        "FIND_SEL_FRAME_OUTER": "$0080FF",
        "INDEX_REC_SIZE": "20",
        "LVM_SUBITEMHITTEST": "$1039",
        "M": "12",
        "MAX_CHARS": "120000",
        "MAX_EX": "12000",
        "MAX_INSERT_LINES": "2000",
        "MAX_LINE_AUTOFILL": "2000",
        "MAX_LINE_LEN": "2 * 1024 * 1024",
        "MAX_MARK_DRAW_CHARS": "24000",
        "MAX_PREVIEW_SCAN_LINES": "200000",
        "MAX_SCAN_LINES": "400",
        "MAX_UI": "1500",
        "MESSAGE_FILENAME": "'Writing %d of %d'",
        "MaxBufferSize": "$F000",
        "MaxLen": "80",
        "MinWrapRows": "4",
        "RADIUS": "1",
        "SAMPLE_MAX_LINES": "60",
        "TAIL_MAX_LINE": "2 * 1024 * 1024",
        "WALK_BUF": "256 * 1024",
        "ZERO_SCAN_FULL_COUNT_MAX": "256 * 1024 * 1024",
        "ZERO_SCAN_START_EXACT_MAX_LINE": "2048",
        "ZERO_SCAN_VIRTUAL_CAP": "2000000000",
        "cSearchWordText": "'Search'",
    }
    for n in first_pass:
        if n == "AllModifierKeys":
            continue
        if n not in reg and n in first_vals:
            ordered_names.append(n)
            reg[n] = first_vals[n]

    lines_out = ["  { --- MainUnit.pas (centralized) --- }", ""]
    for n in ordered_names:
        v = reg[n]
        if n in ("W_64", "H_64", "CheckWidth", "CheckHeight", "CheckBiasTop", "CheckBiasLeft"):
            type_map = {"W_64": "Word", "H_64": "Word", "CheckWidth": "Word", "CheckHeight": "Word", "CheckBiasTop": "Word", "CheckBiasLeft": "Word"}
            lines_out.append(f"  {n}: {type_map[n]} = {v};")
        else:
            lines_out.append(f"  {n} = {v};")
    lines_out.append("")
    OUT.write_text("\n".join(lines_out), encoding="utf-8")
    print(f"Wrote {len(ordered_names)} constants to {OUT}")


if __name__ == "__main__":
    main()
