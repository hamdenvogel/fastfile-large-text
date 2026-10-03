#!/usr/bin/env python3
"""Fix UnConsts MainUnit section and MainUnit broken references."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
UNCONSTS = ROOT / "UnConsts.pas"
MAIN = ROOT / "MainUnit.pas"

MAINUNIT_CONSTS = r"""
  { --- MainUnit.pas (centralized) --- }

  { Status / I/O / index }
  INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';
  INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';
  OUT_BUFFER_SIZE = 65536;
  INDEX_RECORD_SIZE = 20;
  INDEX_REC_SIZE = 20;
  CKPT_INTERVAL = 1024;

  { ListView icon / checkbox layout }
  W_64: Word = 64;
  H_64: Word = 64;
  CheckWidth: Word = 14;
  CheckHeight: Word = 14;
  CheckBiasTop: Word = 2;
  CheckBiasLeft: Word = 3;
  MAX_LINE_LEN_DISPLAY = 256 * 1024;
  ASSISTANT_FILTER_CLIPBOARD_MAX_LINES = 500;
  CHECKBOX_SCALE_PCT = 85;
  CHECKBOX_LEFT_PAD = 2;
  CHECKBOX_TEXT_GAP = 6;
  TEXT_PAD = 2;
  COL1_PAD = 2;
  COL1_LEFT_INSET = 5;
  COL_EDGE_MARGIN = 6;
  MAX_CHECKLIST_WRAP_DRAW = 2000;
  LONG_LINE_THRESH = 80000;
  MinWrapRows = 4;
  MinAutoWrapRows = 2;
  MaxAutoWrapRows = 16;
  FIND_SEL_FRAME_OUTER = $0080FF;

  { Windows language IDs (Delphi 7) }
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

  { Bookmarks, marks, menu bitmaps }
  IMAGELIST_IDX_ZOOM_LIST = 91;
  FF_MENU_BMP_ZOOM_LIST = '__ff_zoom_list.bmp';
  FF_BOOKMARK_ROW_BG = $00A05000;
  FF_BOOKMARK_ROW_FG = clWhite;
  FF_BOOKMARK_STRIPE = $006E3700;
  FF_TAIL_NEW_ROW_BG = $00C8FFC8;
  FF_CL_MARK_TAB = TColor($0000A0FF);
  FF_CL_MARK_SPACE = TColor($00808080);
  FF_CL_MARK_CR = TColor($00FF6000);
  FF_CL_MARK_LF = TColor($0000AA00);
  FF_CL_MARK_NUL = TColor($000000FF);
  FF_CL_MARK_CTRL = TColor($00AA00AA);
  MENU_BITMAP_SUBPATH_HOT16 = 'Images\\ImagesII\\glyphspro\\glyphspro\\16x16\\hot\\';
  MENU_BITMAP_SUBPATH_TRICH16 = 'Resources\\trichviewicons\\bitmaps\\normal\\16x16\\';
  MENU_BITMAP_SUBPATH_TRICH32 = 'Resources\\trichviewicons\\bitmaps\\normal\\32x32\\';

  { Read toolbar quick buttons }
  BTN_W = 28;
  BTN_H = 28;
  BTN_GAP = 4;
  BTN_TOP = 30;

  { Split / merge dialogs }
  SPLIT_PARTS_MIN = 2;
  SPLIT_PARTS_MAX = 1000;
  FF_SPLIT_EQUAL_PARTS_GAP = 10;
  FF_SPLIT_FRACTION_GAP = 10;
  FF_SPLIT_BY_PATTERN_GAP = 8;
  BANNER_ROW = 38;
  M = 12;

  { AI sample readers }
  MAX_SCAN_LINES = 400;
  MAX_PREVIEW_SCAN_LINES = 200000;
  MAX_SCAN = 1000;
  MAX_COLS = 50;
  MAX_SCAN_REF = 1000;
  FF_PY_MACRO_SAMPLE_MAX_LINES = 4;
  FF_PY_MACRO_MAX_LINE_CH = 64;
  FF_PY_MACRO_MAX_TOTAL = 900;
  FF_SPLIT_PATTERN_SAMPLE_MAX_LINES = 80;
  FF_SPLIT_PATTERN_SAMPLE_MAX_CH = 24000;
  FF_SPLIT_PATTERN_MAX_LINE_CH = 4000;
  SAMPLE_MAX_LINES = 60;

  { Consumer AI / RAG panels }
  BASE_H = 64;
  OPTIONS_EXTRA = 30;
  READ_BUF_SIZE = 32768;
  UI_UPDATE_CHUNK = 16 * READ_BUF_SIZE;
  NET_TIMEOUT_MS = 3600000;
  BRIDGE_PREFIX = 'FFBRIDGE|';
  MAX_CHARS = 120000;
  MAX_EX = 12000;

  { Python macro / tail / script stubs }
  STUB_HEADER_ONLY = 'deftransform(line,ctx):';
  STUB_RETURN_LINE = 'deftransform(line,ctx):returnline';
  STUB_RETURN_PASS = 'deftransform(line,ctx):returnlinepass';
  STUB_PASS_ONLY = 'deftransform(line,ctx):pass';
  B64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  TAIL_MACRO_CHUNK_MAX_LINES = 100000;
  TAIL_MAX_LINE = 2 * 1024 * 1024;
  ONE_MB = Int64(1024) * 1024;
  FF_TAIL_MACRO_EXAMPLE_SEP = '================================================================';
  FF_TAIL_MACRO_LOAD_SEP = '================================================================' + #13#10;
  FF_SCRIPT_SUGGESTIONS_SEP = '================================================================' + #13#10;

  { Export / filter threads }
  MAX_STORED = 50000;
  MAX_STORED_LINE_LEN = 64 * 1024;
  MAX_UI = 1500;
  UI_TRIM = 400;
  MAX_PREVIEW_LINES = 1500;
  TAIL_READ_BYTES = 2 * 1024 * 1024;
  FILTER_STREAM_MAX_HITS = 5000000;
  FILTER_STREAM_BUF_SIZE = 1024 * 1024;
  FF_EXPORT_STREAM_PROGRESS_EVERY = 256;
  FF_EXPORT_OWNER_PROGRESS_EVERY = 64;
  MESSAGE_FILENAME = 'Writing %d of %d';
  EXPORT_NOTIFY_ICON_ID = 1977;
  MAX_INSERT_LINES = 2000;
  MAX_LINE_AUTOFILL = 2000;
  BUF_SIZE = 1024 * 1024;
  COUNT_BUF_SIZE = 4 * 1024 * 1024;
  BACK_SCAN = 65536;
  WALK_BUF = 256 * 1024;
  MAX_LINE_LEN = 2 * 1024 * 1024;
  MAX_MARK_DRAW_CHARS = 24000;
  MaxLen = 80;

  { Zero Scan }
  ZERO_SCAN_SAMPLE_BYTES = 4 * 1024 * 1024;
  ZERO_SCAN_DEFAULT_AVG_LINE = 256;
  ZERO_SCAN_MAX_LINES = 2000000000;
  ZERO_SCAN_MIN_AVG_LINE = 8;
  ZERO_SCAN_TAIL_BYTES = 4 * 1024 * 1024;
  ZERO_SCAN_HEAD_BYTES = 4 * 1024 * 1024;
  ZERO_SCAN_VIRTUAL_CAP = 2000000000;
  ZERO_SCAN_START_EXACT_MAX_LINE = 2048;
  ZERO_SCAN_FULL_COUNT_MAX = 256 * 1024 * 1024;
  LVM_GETITEMCOUNT_MSG = $1000 + 4;
  LVM_GETITEMSTATE_MSG = $1000 + 44;
  LVM_SUBITEMHITTEST = $1039;

  { Zoom / wheel }
  MAX_WHEEL_ZOOM_HISTORY = 5;
  WHEEL_ZOOM_COMBO_DEBOUNCE_MS = 45;
  MAX_COMBO_ITEMS = 40;
  ZOOM_MIN_PERCENT = 50;
  ZOOM_MAX_PERCENT = 200;
  ZOOM_MIN_SIZE = 6;
  ZOOM_MAX_SIZE = 32;
  WHEEL_ONE_NOTCH = 120;

  { Idle workspace / logo }
  IDLE_LOGO_PNG = 'color1_icon_transparent_background.png';
  IDLE_LOGO_ALPHA = 188;
  IDLE_LOGO_MAX_PX = 520;
  IDLE_LOGO_SIZE_FRAC = 0.44;
  IDLE_LOGO_WATERMARK_SIZE_FRAC = 0.84;
  IDLE_LOGO_WATERMARK_BLEND = 68;
  IDLE_LOGO_STRETCH_SUPERSAMPLE = 4;
  IDLE_LOGO_SOURCE_MIN_PX = 1024;
  IDLE_LOGO_SOURCE_MAX_PX = 2048;
  IDLE_LOGO_SOURCE_LORES_PX = 512;
  IDLE_LOGO_PNG_HIRES_REL =
    '..\..\Images\Logo\package_highres_mpanlryw\color1\icon\color1_icon_transparent_background.png';
  IDLE_LOGO_BG_SIZE_FRAC = 1.0;
  IDLE_LOGO_BG_ALPHA = 255;
  IDLE_LOGO_PROCESS_REV = 30;
  IDLE_LOGO_HALO_BORDER_PX = 4;
  IDLE_LOGO_HALO_MAX_ALPHA = 52;
  IDLE_LOGO_TITLE_COLOR = TColor($00283038);
  IDLE_LOGO_TAGLINE_COLOR = TColor($00404858);
  IDLE_LOGO_TITLE_FONT_MIN = 18;
  IDLE_LOGO_TITLE_FONT_MAX = 34;
  IDLE_LOGO_TITLE_FONT_DIV = 24;
  IDLE_WORKSPACE_GRAD_LEFT = TColor($00FFF8F5);
  IDLE_WORKSPACE_GRAD_RIGHT = TColor($00E8D4B8);
  IDLE_WORKSPACE_BG_ALPHA = 255;
  RADIUS = 1;

  { Tail goto / misc UI }
  MAX_TAIL_READ_CHUNK = 64 * 1024 * 1024;
  MAX_TAIL_GOTO_LINES = 500;
  CBN_CLOSEUP = 8;
  MaxBufferSize = $F000;
  cSearchWordText = 'Search';
  Msg_Add = 1;
  WM_COPYGLOBALDATA = $49;

  { Help dialog markers }
  CRLF = #13#10;
  FF_HELP_DIALOG_SEP = '---------------------------------------------------------------';
  MK_HELP_GOTO_BYTE = '<<<FF_HELP_GOTO_BYTE>>>';
  MK_HELP_FILTER_ROW = '<<<FF_HELP_FILTER_ROW>>>';
  MK_HELP_FILTER_FEATURE = '<<<FF_HELP_FILTER_FEATURE>>>';
  MK_HELP_READONLY_ROW = '<<<FF_HELP_READONLY_ROW>>>';
  MK_HELP_COPY_INSERT_ROW = '<<<FF_HELP_COPY_INSERT_ROW>>>';
  MK_HELP_PASTE_INSERT_ROW = '<<<FF_HELP_PASTE_INSERT_ROW>>>';
  MK_HELP_MENUBAR_L1 = '<<<FF_HELP_MENUBAR_L1>>>';
  MK_HELP_MENUBAR_L2 = '<<<FF_HELP_MENUBAR_L2>>>';
  MK_HELP_VIEW_ZOOM_IN = '<<<FF_HELP_VIEW_ZOOM_IN>>>';
  MK_HELP_VIEW_ZOOM_OUT = '<<<FF_HELP_VIEW_ZOOM_OUT>>>';
  MK_HELP_COMPARE_MERGE = '<<<FF_HELP_COMPARE_MERGE>>>';
  MK_HELP_COMPARE_MERGE_RELOAD_1 = '<<<FF_HELP_COMPARE_MERGE_RELOAD_1>>>';
  MK_HELP_COMPARE_MERGE_RELOAD_2 = '<<<FF_HELP_COMPARE_MERGE_RELOAD_2>>>';
  MK_HELP_ZERO_SCAN = '<<<FF_HELP_ZERO_SCAN>>>';
  MK_HELP_EMEDITOR = '<<<FF_HELP_EMEDITOR>>>';
  MK_HELP_ASSISTANT = '<<<FF_HELP_ASSISTANT>>>';
  MK_HELP_AI_CHAT = '<<<FF_HELP_AI_CHAT>>>';
  MK_HELP_ADV_AI_CHAT = '<<<FF_HELP_ADV_AI_CHAT>>>';
  MK_HELP_VERSION = '<<<FF_HELP_VERSION>>>';
  MK_HELP_READ_PANEL = '<<<FF_HELP_READ_PANEL>>>';
  MK_HELP_IDLE_WORKSPACE = '<<<FF_HELP_IDLE_WORKSPACE>>>';
"""

MAINUNIT_FIXES = [
    # ReadPythonMacroFileSampleForAI
    (
        r"function ReadPythonMacroFileSampleForAI",
        r"function ReadSplitPatternFileSampleForAI",
        [("MAX_LINES", "FF_PY_MACRO_SAMPLE_MAX_LINES"), ("MAX_CH", "FF_PY_MACRO_MAX_LINE_CH"), ("MAX_TOTAL", "FF_PY_MACRO_MAX_TOTAL")],
    ),
    (
        r"function ReadSplitPatternFileSampleForAI",
        r"function ReadSplitPatternFileFirstPhysicalLines",
        [
            ("MAX_LINES", "FF_SPLIT_PATTERN_SAMPLE_MAX_LINES"),
            ("MAX_CH", "FF_SPLIT_PATTERN_SAMPLE_MAX_CH"),
        ],
    ),
    (
        r"function ReadSplitPatternFileFirstPhysicalLines",
        r"^function ",
        [("MAX_LINE_CH", "FF_SPLIT_PATTERN_MAX_LINE_CH")],
    ),
    (
        r"procedure TExportFilteredLinesThread\.ExecuteStreamExport",
        r"procedure TExportFilteredLinesThread\.ExecuteOwnerLineExport",
        [("PROGRESS_EVERY", "FF_EXPORT_STREAM_PROGRESS_EVERY")],
    ),
    (
        r"procedure TExportFilteredLinesThread\.ExecuteOwnerLineExport",
        r"procedure TExportFilteredLinesThread\.Execute;",
        [("PROGRESS_EVERY", "FF_EXPORT_OWNER_PROGRESS_EVERY")],
    ),
    (
        r"procedure TfrmMain\.EnsureSplitEqualPartsTab",
        r"procedure TfrmMain\.EnsureSplitFractionTab",
        [("GAP", "FF_SPLIT_EQUAL_PARTS_GAP")],
    ),
    (
        r"procedure TfrmMain\.EnsureSplitFractionTab",
        r"procedure TfrmMain\.EnsureSplitByPatternTab",
        [("GAP", "FF_SPLIT_FRACTION_GAP")],
    ),
    (
        r"procedure TfrmMain\.EnsureSplitByPatternTab",
        r"^procedure TfrmMain\.",
        [("GAP", "FF_SPLIT_BY_PATTERN_GAP")],
    ),
]


def replace_section(text: str, start_marker: str, end_marker: str, new_block: str) -> str:
    if start_marker not in text:
        raise SystemExit(f"Marker not found: {start_marker}")
    s = text.index(start_marker)
    e = text.index(end_marker, s)
    return text[:s] + new_block.strip() + "\n\n" + text[e:]


def scoped_replace(content: str, start_pat: str, end_pat: str, pairs: list[tuple[str, str]]) -> str:
    m1 = re.search(start_pat, content, re.MULTILINE)
    if not m1:
        return content
    m2 = re.search(end_pat, content[m1.end() :], re.MULTILINE)
    if not m2:
        return content
    before = content[: m1.start()]
    block = content[m1.start() : m1.end() + m2.start()]
    after = content[m1.end() + m2.start() :]
    for old, new in pairs:
        block = re.sub(r"\b" + re.escape(old) + r"\b", new, block)
    return before + block + after


def remove_simple_const_blocks(content: str) -> str:
    lines = content.splitlines()
    out = []
    i = 0
    skip_names = KEEP = {"HELP_TEXT", "HISTORY", "showOtherTabs", "PPIArray", "B64Chars", "ONE_MB", "TAIL_MACRO_CHUNK_MAX_LINES", "NL", "CRLF", "MK_HELP_", "FF_HELP", "FF_TAIL", "FF_SCRIPT"}
    while i < len(lines):
        if lines[i].strip() != "const":
            out.append(lines[i])
            i += 1
            continue
        indent = len(lines[i]) - len(lines[i].lstrip())
        j = i + 1
        block_lines = []
        while j < len(lines):
            ls = lines[j].strip()
            if not ls:
                block_lines.append((j, lines[j]))
                j += 1
                continue
            li = len(lines[j]) - len(lines[j].lstrip())
            if li <= indent and re.match(r"^(var|type|begin|procedure|function)\b", ls):
                break
            block_lines.append((j, lines[j]))
            j += 1
        keep_block = False
        for _, bl in block_lines:
            t = bl.strip()
            if not t or t.startswith("{") or t.startswith("//"):
                continue
            if any(t.startswith(k) if not k.endswith("_") else k in t for k in KEEP):
                keep_block = True
                break
            if re.search(r":\s*array\b", t, re.I) or re.search(r":\s*Boolean\s*=", t, re.I):
                keep_block = True
                break
            if t.endswith("+") or "HELP_TEXT" in t or "HISTORY" in t:
                keep_block = True
                break
        if keep_block:
            out.append(lines[i])
            for _, bl in block_lines:
                out.append(bl)
        i = j
    return "\n".join(out) + "\n"


def main():
    un = UNCONSTS.read_text(encoding="utf-8", errors="replace")
    if "uses\n  Graphics;" not in un:
        un = un.replace("interface\n\nconst", "interface\n\nuses\n  Graphics;\n\nconst")
    un = replace_section(un, "  { --- MainUnit.pas (centralized) --- }", "implementation", MAINUNIT_CONSTS)
    UNCONSTS.write_text(un, encoding="utf-8", newline="\n")

    main = MAIN.read_text(encoding="utf-8", errors="replace")
    for start, end, pairs in MAINUNIT_FIXES:
        main = scoped_replace(main, start, end, pairs)

    # ShowHelpDialog: use UnConsts names
    main = re.sub(
        r"(procedure TfrmMain\.ShowHelpDialog;\r?\n)const\r?\n(?:  .*?\r?\n)+?(?=  HELP_TEXT)",
        r"\1",
        main,
        count=1,
        flags=re.DOTALL,
    )
    main = main.replace("FF_TAIL_MACRO_EXAMPLE_SEP = '---", "REMOVED")
    # fix wrong sep name in help if still present
    main = re.sub(
        r"  FF_TAIL_MACRO_EXAMPLE_SEP = '[-=]+';\r?\n",
        "",
        main,
    )
    main = re.sub(
        r"  (CRLF|MK_HELP_[A-Z0-9_]+) = '[^']*';\r?\n",
        "",
        main,
    )

    # Tail/script suggestion loaders
    for proc, sep in [
        ("TailMacroSuggestionsLoadContent", "FF_TAIL_MACRO_LOAD_SEP"),
        ("ScriptSuggestionsLoadContent", "FF_SCRIPT_SUGGESTIONS_SEP"),
    ]:
        main = re.sub(
            rf"(procedure TfrmMain\.{proc};\r?\n)const\r?\n  NL  = #13#10;\r?\n  FF_TAIL_MACRO_EXAMPLE_SEP = '[^']+' \+ #13#10;\r?\n",
            rf"\1const\r\n  NL  = CRLF;\r\n  FF_TAIL_MACRO_EXAMPLE_SEP = {sep};\r\n",
            main,
            count=1,
        )

    # Remove duplicate B64Chars local const (use UnConsts)
    main = re.sub(
        r"const\r?\n  B64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\+/';\r?\n",
        "",
        main,
    )

    # Remove MAX_SCAN_REF local if present
    main = re.sub(r"const\r?\n  MAX_SCAN_REF = 1000;\r?\n\r?\n", "", main)

    # Remove tail const block duplicate ONE_MB etc - careful
    main = re.sub(
        r"const\r?\n  B64Chars = '[^']+';\r?\n  ONE_MB = Int64\(1024\) \* 1024;\r?\n",
        "",
        main,
    )

    # Remove MAX_TAIL const block
    main = re.sub(
        r"const\r?\n  MAX_TAIL_READ_CHUNK = 64 \* 1024 \* 1024;\r?\n  MAX_TAIL_GOTO_LINES = 500;\r?\n",
        "",
        main,
    )

    # AllModifierKeys stays local
    if "AllModifierKeys" not in main:
        main = main.replace(
            "function ModifierKeyState(Shift: TShiftState): TModifierKeyState;\r\nbegin",
            "function ModifierKeyState(Shift: TShiftState): TModifierKeyState;\r\nconst\r\n  AllModifierKeys = [low(TModifierKey)..high(TModifierKey)];\r\nbegin",
        )

    MAIN.write_text(main, encoding="utf-8", newline="\n")
    print("Fixed UnConsts and MainUnit")


if __name__ == "__main__":
    main()
