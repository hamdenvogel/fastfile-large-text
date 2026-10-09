unit UnConsts;

interface

uses
  Graphics;

const
  { Also the [FastFile] section name in ASkin.ini: do not change. }
  APPLICATION_NAME = 'FastFile';
  APPLICATION_EDITION = 'Professional';
  APPLICATION_DISPLAY_NAME = APPLICATION_NAME + ' ' + APPLICATION_EDITION;
  APPLICATION_VERSION = '3.0.5.232';
  APPLICATION_FULLNAME = 'Professional editor for huge text files';
  APPLICATION_DEVELOPER = 'Copyright (c) 2025 - 2026, Hamden Vogel.' + #13#10 + 'All rights reserved.';
  ASKIN_INI = 'ASkin.ini';
  INI_OPEN_TABS_SAVED = 'OpenTabsSaved';
  INI_OPEN_TABS = 'OpenTabs';
  INI_OPEN_TABS_ACTIVE = 'OpenTabsActive';
  INI_OPEN_TABS_FILE = 'OpenTabsFile';
  INI_OPEN_TABS_MRU = 'OpenTabsMRU';
  INI_SKIN_HUE_TAB = 'SkinHueTab';
  INI_MAIN_TAB_ORDER = 'MainTabOrder';
  OPEN_TABS_MRU_MAX = 12;
  MRU_LOCATION_INI = 'mru_location.ini';
  MRU_CONTENT_INI = 'mru_content.ini';
  MRU_FILES_INI = 'mru_files.ini';
  XMLFOLDERS = 'folders.xml';
  XMLFILES = 'files.xml';
  CONSUMERAI = 'ConsumerAI.exe';
  CONSUMERRAG = 'ConsumerRAG.exe';
  SCRIPTENGINE = 'ScriptEngine.exe';
  CODECHECK = 'CodeCheck.exe';
  { Companion plugins download mirror (HTTP). Change base once for all EXEs. }
  FASTFILE_EXECUTABLES_BASE_URL = 'http://hvogel.com.br/fastfile_executables/';
  CONSUMERRAG_DOWNLOAD_URL = FASTFILE_EXECUTABLES_BASE_URL + CONSUMERRAG;
  CONSUMERAI_DOWNLOAD_URL = FASTFILE_EXECUTABLES_BASE_URL + CONSUMERAI;
  SCRIPTENGINE_DOWNLOAD_URL = FASTFILE_EXECUTABLES_BASE_URL + SCRIPTENGINE;
  CODECHECK_DOWNLOAD_URL = FASTFILE_EXECUTABLES_BASE_URL + CODECHECK;
  FASTFILE_DOWNLOAD_LOG = 'FastFile_Download.log';
  HISTORY_TITLE = 'FastFile Professional - Version History';
  HISTORY_TITLE_LINE = '  ' + HISTORY_TITLE;
  HISTORY_RULE = '=======================================================';
  HISTORY_EXPORT_FILENAME = 'FastFile_VersionHistory.txt';
  LICENSE_EXPORT_FILENAME = 'FastFile_License.txt';
  ABOUT_EXPORT_FILENAME = 'FastFile_About.txt';
  HELP_EXPORT_FILENAME = 'FastFile_Help.txt';
  FILTER_TEXT_AND_ALL_FILES = 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
  DEFAULT_TEXT_EXT = 'txt';
  { Relative dirs searched for a newer local ScriptEngine build beside the EXE. }
  FASTFILE_BUILD_DIR = 'Build';
  DATALAKE_DIR = 'data-lake-duckdb-main';
  DATALAKE_DIST_DIR = 'dist';
  SCRIPTENGINE_REL_BUILD = '..\' + FASTFILE_BUILD_DIR + '\';
  SCRIPTENGINE_REL_DIST = '..\' + DATALAKE_DIR + '\' + DATALAKE_DIST_DIR + '\';
  SCRIPTENGINE_REL_DIST_SIDECAR = DATALAKE_DIR + '\' + DATALAKE_DIST_DIR + '\';
  { One-shot validate timeout for ScriptEngine --validate / CodeCheck.exe. }
  CODECHECK_VALIDATE_TIMEOUT_MS = 120000;
  { Extensions accepted by Assistente "Validar fonte" / validate_source. }
  VALIDATABLE_SOURCE_EXTS = '.py;.js;.jsx;.ts;.tsx;.mjs;.cjs';
  TEXTURE = 'texture.bmp';
  LOGO = 'logo.bmp';
  ICON_HELP_PNG = 'icon_help.png';
  FOLDERSKIN = 'Skins';
  EXTENSIONFILES = 'extensionFiles.txt';
  TEXTFILECHUNK = 'textFileChunk.txt';
  SELECTTEXT = 'Select a file ...';
  INVALIDFILENAME = 'Invalid filename!';
  { --- Line index / filter / Zero Scan (beside the executable) --- }
  TEMPFILE = 'temp.txt';
  TEMP_CKPT_FILE = 'temp_ckpt.txt';
  { Sidecar: path + size + mtime + line count - reabertura sem re-scan quando valido. }
  TEMP_INDEX_META = 'temp_index.meta';
  { Durable sparse index in fastfile_temp (same safe-name pattern as .ffsession). }
  SOURCE_LINE_INDEX_CKPT_SUFFIX = '.ffckpt';
  SOURCE_LINE_INDEX_META_SUFFIX = '.ffmeta';
  TEMP_ZERO_SCAN_BLOCK_IDX = 'temp_blk.idx';
  TEMP_FILTER_HITS_FILE = 'temp_filter_hits.bin';
  { --- Legacy / scratch files beside the executable --- }
  TEMP_EDIT_FILE = 'temp_edit.txt';
  TEMP_MERGE_SCRATCH_FILE = 'temp_merge.txt';
  TEMP_POSTLINE_FILE = 'temp2.txt';
  EXPORT_DEFAULT_FILENAME = 'export.txt';
  { --- fastfile_temp\ work area (see FASTFILE_TEMP_DIR) --- }
  FASTFILE_TEMP_DIR = 'fastfile_temp';
  { Assistant compose outputs (generated docs/source) — not internal scratch. }
  FASTFILE_ASSISTANT_OUT_DIR = 'fastfile_assistant';
  FASTFILE_HISTORY_DIR = 'FastFileSessionHistory';
  FASTFILE_SESSION_EXT = '.ffsession';
  FASTFILE_DELTA_EXT = '.delta';
  FASTFILE_MERGE_TEMP_FILE = 'temp_merge_files.txt';
  FASTFILE_TEMP_SCRATCH_PREFIX = 'ff_';
  FASTFILE_TEMP_SCRATCH_EXT = '.tmp';
  FASTFILE_TEMP_WORK_GLOB = 'ff_*.tmp';
  FASTFILE_ZERO_SCAN_BLK_TEMP_PREFIX = 'ff_zsblk_';
  FASTFILE_ZERO_SCAN_FILTER_TEMP_PREFIX = 'ff_zsfilt_';
  FASTFILE_EM_FS_TEMP_NAME_FMT = 'ff_emfs_%d_%d.tmp';
  CONSUMERAI_SESSION_DEBUG_LOG = 'ConsumerAI_Session_Debug.log';
  ASSISTANT_LOG = 'Assistant.log';
  { ConsumerRAG / ConsumerAI scratch beside the plugin EXE (LanceDB, chunks). }
  CONSUMER_DATA_DIR = 'data';
  CONSUMERRAG_WORKSPACE_DIR = 'rag_workspace';
  CONSUMERRAG_TRANSCRIPT_PREFIX = 'consumer_rag_transcript_';
  FASTFILE_LOG_FILENAME_FORMAT = 'Log_FastFile%s.txt';
  ILLEGAL_FILENAME_CHARS = '/\:*?"<>|';
  TEMP = '-TEMP';
  CHUNKFILE = 'chunk.txt';
  //MERGED = '-merged';
  TIME_TO_READ = 'Time to read: %s millisecs.';
  TIME_TO_DELETELINES = 'Time to delete lines: %s millisecs.';
  TIME_TO_EDITLINES = 'Time to edit lines: %s milliseconds.';
  TIME_TO_CREATE_NEW_FILE = 'Time to create new file: %s milliseconds.';
  DELETE_LINES_TIP = 'Please select those checkboxes below, and after click "DEL" key to delete them.';
  STATUS_RUNNING = 'Status: Running...';
  STATUS_OK = 'Status: OK.';
  STATUS_ERROR = 'Status: Error.';
  LASTLINE_NOT_SUPPORTED = 'For this current version, editing last line is not supported.';
  SELECTTEXT_TO_READ_BEFORE = 'Please select a file and read before this writing operation.';
  MAX_100_PERCENT = 100;
  SIZEPARTFILE = 25000000;
  ELAPSEDTIME = 'Time: %s seconds' ;
  MAX_FILESIZE_MEMORY_LIMIT_BYTES = 15958207655; //14.86 GB
  { Limiar padrao (GB, inclusivo): indexado ate este tamanho; acima abre em Instant Open.
    9999 = praticamente sempre indexar (contagem real de linhas). Instant Open fica opt-in
    (Force Zero Scan / Always Instant). Valor efectivo: uFileOpenPolicy (INI). }
  MAX_GB_FILE_INDEXED_DEFAULT = 9999;
  SPLIT_BY_LINE_OPTION_SELECTED = 0;
  SPLIT_BY_FILE_OPTION_SELECTED = 1;
  TAB_READ_FILE_INDEX = 0;
  TAB_SPLIT_FILE_INDEX = 1;
  TAB_EXPORTED_LINES = 2;
  TAB_FINDFILE_INDEX = 0;
  DELETION_CONFIRMATION_ITEM = 'It will be removed from the list. Confirm ?';
  TITLE_DELETION_CONFIRMATION_ITEM = 'Delete confirmation';

  { --- FastFile AI assistant (AWS API Gateway -> Lambda) ---------------------
    Production endpoint (HTTPS POST, JSON body with "prompt", JSON response with "resposta"). }
  FASTFILE_AI_GATEWAY_URL =
    'https://avylzxs9u3.execute-api.us-east-2.amazonaws.com/default/grod_prod_lambda';
  FASTFILE_AI_GATEWAY_HOST = 'avylzxs9u3.execute-api.us-east-2.amazonaws.com';
  FASTFILE_AI_GATEWAY_PATH = '/default/grod_prod_lambda';
  FASTFILE_AI_AWS_REGION = 'us-east-2';
  FASTFILE_AI_GATEWAY_TIMEOUT_MS = 120000;
  FASTFILE_AI_USER_AGENT = 'FastFile/AI';
  FASTFILE_AI_HTTP_METHOD = 'POST';
  FASTFILE_AI_JSON_MEDIA_TYPE = 'application/json; charset=utf-8';
  FASTFILE_AI_JSON_FIELD_PROMPT = 'prompt';
  FASTFILE_AI_JSON_FIELD_RESPOSTA = 'resposta';
  FASTFILE_AI_WININET_READBUF_BYTES = 32768;
  FASTFILE_AI_ERROR_SNIPPET_HTTP_CHARS = 400;
  FASTFILE_AI_ERROR_SNIPPET_BODY_CHARS = 600;
  { Split-by-Regex "Talk with AI" UI / bundled prompt size }
  FASTFILE_AI_MAX_CONTEXT_CHARS = 14000;
  FASTFILE_AI_MIN_FOCUS_QUESTION_CHARS = 12;
  { Split-by-Pattern tab: lines sent to AI for inline regex example suggestions }
  FASTFILE_SPLIT_PATTERN_AI_LINE_COUNT = 100;

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
  { Ctrl+Shift+O export dialog: clipboard holds all lines in memory. }
  EXPORT_CLIPBOARD_MAX_LINES = 500;
  { File export streams, but line-list expansion still costs RAM. }
  EXPORT_FILE_MAX_LINES = 100000;
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
  MENU_BITMAP_SUBPATH_HOT24 = 'Images\\ImagesII\\glyphspro\\glyphspro\\24x24\\hot\\';
  MENU_BITMAP_SUBPATH_TRICH16 = 'Resources\\trichviewicons\\bitmaps\\normal\\16x16\\';
  MENU_BITMAP_SUBPATH_TRICH32 = 'Resources\\trichviewicons\\bitmaps\\normal\\32x32\\';
  MAIN_TB_ICON_SPLIT_FILES = 'grid split cells.bmp';
  MAIN_TB_ICON_MERGE_LINES = 'grid merge cells.bmp';
  MAIN_TB_ICON_MERGE_FILES = 'copy.bmp';
  MAIN_TB_ICON_COMPARE_MERGE = 'history.bmp';
  MAIN_TB_ICON_SPLIT_PATTERN = 'search.bmp';
  MAIN_TB_ICON_SPLIT_EQUAL = 'window tile vertical.bmp';
  MAIN_TB_ICON_EXTRACT_PARTS = 'cut.bmp';
  MAIN_TB_ICON_TOOLS_GALLERY = 'Tools.bmp';
  MAIN_TB_ICON_HELP = 'Help.bmp';
  MAIN_TB_ICON_FILE_AGENT = 'wizard.bmp';
  FILEBAR_ICON_READ_F5 = 'insert file-2.bmp';

  { Read toolbar quick buttons (16x16 glyphs, ~30px hit target) }
  BTN_W = 30;
  BTN_H = 30;
  BTN_GAP = 4;
  BTN_TOP = 26;
  READ_TB_ICON_ZOOM_IN = 'zoom in.bmp';
  READ_TB_ICON_ZOOM_OUT = 'zoom out.bmp';
  READ_TB_ICON_FIND = 'search.bmp';
  READ_TB_ICON_FIND_REPLACE = 'search and replace.bmp';
  READ_TB_ICON_SHOW_MARKS = 'Show All Formatting.bmp';
  READ_TB_ICON_WORD_WRAP = 'word wrap.bmp';
  READ_TB_ICON_FILTER = 'filter.bmp';
  READ_TB_ICON_COMPARE_MERGE = 'grid merge cells.bmp';

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
  { Soft page size: show first N hits, then Continue loads the next page. }
  FILTER_STREAM_PAGE_HITS = 100000;
  { Assistant-initiated stream filter uses the same page size. }
  ASSISTANT_FILTER_SOFT_MAX_HITS = FILTER_STREAM_PAGE_HITS;
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

  { Line content hover hint (ListView / Select CheckListBox) }
  LINE_HINT_MAX_WIDTH = 900;
  LINE_HINT_WRAP_CHARS = 100;
  LINE_HINT_MAX_CHARS = 4000;
  LINE_HINT_MAX_LINES = 32;
  LINE_HINT_MIN_CHARS = 48;
  { Pequeno atraso antes de mostrar o hint da linha (ListView / Select). }
  LINE_HINT_SHOW_DELAY_MS = 400;

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
  MK_HELP_WIN64_INDEX = '<<<FF_HELP_WIN64_INDEX>>>';
  MK_HELP_AICHAT_FILE = '<<<FF_HELP_AICHAT_FILE>>>';
  MK_HELP_RECENT = '<<<FF_HELP_RECENT>>>';


  { Version History dialog (Help > Version History / miVersionHistoryClick) }
  HISTORY =
    HISTORY_RULE + #13#10 +
    HISTORY_TITLE_LINE + #13#10 +
    HISTORY_RULE + #13#10 +
    ''#13#10 +
    '*******************************************************'#13#10 +
    '  ***  FASTFILE VERSION 3.0  —  MAJOR RELEASE  ***'#13#10 +
    '*******************************************************'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.232  (2026-10-08)  (current)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  AI agent - time to decide + safer answers:'#13#10 +
    '    Proposed edits wait 20 s for Accept / Reject / Accept all'#13#10 +
    '      (Options > Preferences, 5..600 s; empty or invalid value'#13#10 +
    '      is rejected and the default comes back). Timer badge with'#13#10 +
    '      icon; paused while a confirmation is open; when it runs out'#13#10 +
    '      the proposals are discarded and the request must be redone.'#13#10 +
    '    Buttons that act on items are enabled only when there is'#13#10 +
    '      something to act on (proposals, prompt, sources, answer),'#13#10 +
    '      re-checked whenever the list or the text changes.'#13#10 +
    '    Replace all counts the matches first: 0 hits = nothing is'#13#10 +
    '      proposed and the answer says so. The agent never claims a'#13#10 +
    '      change that was not queued; replies follow the UI language.'#13#10 +
    '    Generated-files window: translated "Folder:" / "File:" label.'#13#10 +
    '    Fix: after splitting the open file the main list shows the'#13#10 +
    '      lines again (no blank rows until reload).'#13#10 +
    '    Version History / F1 / CHANGELOG / README / ROADMAP /'#13#10 +
    '      DOC_ZS_ATALHOS / DOCUMENTACAO_MODELOS_IA synced to 3.0.5.232.'#13#10 +
    '    Internal v3.0.5.232: contagem regressiva + preferencia,'#13#10 +
    '      habilitar botoes, parser mais tolerante, idioma da resposta.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.231  (2026-10-07)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  AI agent - SQL, exact match and generated files:'#13#10 +
    '    The request can be SQL or plain words in any of the 14'#13#10 +
    '      languages: SELECT with WHERE / GROUP BY / ORDER BY / SUM /'#13#10 +
    '      COUNT on delimited files; UPDATE / DELETE / INSERT and'#13#10 +
    '      ALTER TABLE become proposals; SQL typed directly runs'#13#10 +
    '      without AI. "Total: N record(s) found" when it applies.'#13#10 +
    '    Whole-word ("not partial", "exact") vs partial search'#13#10 +
    '      understood in the 14 languages.'#13#10 +
    '    "File(s) generated successfully" window: open in FastFile,'#13#10 +
    '      open folder, copy path(s); also after split / export.'#13#10 +
    '      "Last generated file" (menu + Answer bar) reopens it.'#13#10 +
    '    Sources list: Recent MRU (search, delete, clear all).'#13#10 +
    '    Assistant panel: "Agent" mode sends the question to the'#13#10 +
    '      agent engine and shows its proposals.'#13#10 +
    '    Internal v3.0.5.231: uAgentSql + uAgentMatchIntent +'#13#10 +
    '      uExportDoneDlg + MRU de fontes + modo agente no assistente.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.230  (2026-10-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  AI agent on the core + layout:'#13#10 +
    '    Accepted edits use the core streaming routines (files of'#13#10 +
    '      many GB, progress and Cancel).'#13#10 +
    '    Proposed edits preview: before / after highlighted, paged'#13#10 +
    '      (RAM-safe), double-click to zoom; clipped texts show the'#13#10 +
    '      full text on hover with Copy.'#13#10 +
    '    UTF-16 files are read correctly by the agent tools.'#13#10 +
    '    Clipped captions widened on every form; layout follows'#13#10 +
    '      Windows resolution / scale changes while running.'#13#10 +
    '    Internal v3.0.5.230: uAgentPatch + preview paginado +'#13#10 +
    '      FfFitCaptions em todos os forms + WM_DISPLAYCHANGE.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.229  (2026-10-05)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  New: AI agent on files (toolbar, Tools menu, Ctrl+Alt+G):'#13#10 +
    '    1) pick files / folders (mask, depth, max files, filter),'#13#10 +
    '    2) describe the request, 3) review: Answer, Proposed edits,'#13#10 +
    '    Revised prompt, Files found. Nothing is written before'#13#10 +
    '    Accept. Tools: count, search, read, edit / insert / delete'#13#10 +
    '    lines, anonymize and FastFile core actions (replace all,'#13#10 +
    '    split, export, filter, bookmarks...).'#13#10 +
    '    Recent requests MRU (search, delete 1..N, clear all; INI).'#13#10 +
    '    Bars with New, Clear, Copy, Ask AI, Translate, Suggest.'#13#10 +
    '    Loading overlay with progress and Cancel for long requests.'#13#10 +
    '    Internal v3.0.5.229: uAgentWorkspace / uAgentLoop /'#13#10 +
    '      uAgentProtocol / uAgentTools / uAgentActions / uAgentBridge.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.228  (2026-10-04)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Session history - event details:'#13#10 +
    '    Double-click (or Enter) on a session event: full lines'#13#10 +
    '      before / after, previous / next change (F3 / Shift+F3),'#13#10 +
    '      field-by-field compare (delimiter auto-detected) and the'#13#10 +
    '      event summary. Copy or export one, the selected or all'#13#10 +
    '      events at once (TXT / CSV / JSON).'#13#10 +
    '    Internal v3.0.5.228: uHistLineDetailDlg.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.227  (2026-10-04)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Anonymize data (list right-click or Tools menu: selected'#13#10 +
    '    lines, Ctrl+Alt+D, or the whole file): private values become'#13#10 +
    '    fake ones of the same type and length (numbers, dates,'#13#10 +
    '    e-mails, codes, names); columns, delimiter, skip header and'#13#10 +
    '    words to keep;'#13#10 +
    '    preview before applying; undo / redo. Written in place, so'#13#10 +
    '    it is fast on files of any size.'#13#10 +
    '    Session history shows before / after per line; right-click'#13#10 +
    '      "Remove anonymization from history" (line N or all).'#13#10 +
    '    Internal v3.0.5.227: uAnonymize + uAnonymizeDialog.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.226  (2026-10-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Custom PPI (toolbar): choose the UI scale while running,'#13#10 +
    '    synced with the zoom combo of the status bar; "Restore'#13#10 +
    '    default" item and default PPI in Preferences; the window'#13#10 +
    '    stays inside the screen after a resize.'#13#10 +
    '  Language switch also translates texts already on screen.'#13#10 +
    '    Internal v3.0.5.226: botao PPI + preferencia + retraducao.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.225  (2026-09-27)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n + encoding: "Time to execute that operation" and other'#13#10 +
    '    timing messages translated (14 languages); 17 units saved as'#13#10 +
    '    UTF-8 with BOM (no more garbled accents / arrows / symbols in'#13#10 +
    '    any language). Version History / F1 (new "Recent features"'#13#10 +
    '    block) / CHANGELOG / README / ROADMAP / DOC_ZS_ATALHOS /'#13#10 +
    '    DOCUMENTACAO_MODELOS_IA synced to 3.0.5.225.'#13#10 +
    '    Internal v3.0.5.225: BOM UTF-8 em 17 units + mensagens de tempo'#13#10 +
    '      traduzidas + sync de docs/F1.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.224  (2026-09-27)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Session history (Compare / merge):'#13#10 +
    '    Session events and Changed lines lists with checkboxes,'#13#10 +
    '      Select all (partial state) and delete 1..N entries.'#13#10 +
    '    Sort menu: by line (asc/desc) and by date (newest/oldest).'#13#10 +
    '    Date-range filter with AlphaSkins date pickers (From / To;'#13#10 +
    '      defaults to 1st of the month .. today; Esc clears a field).'#13#10 +
    '    Export TXT / CSV and "Ask AI" about the selected entries.'#13#10 +
    '    Changed lines: two-line items with date/time; the selected'#13#10 +
    '      item keeps its legend color (border + bold, no dark fill).'#13#10 +
    '    Internal v3.0.5.224: historico — checkboxes, ordenar, filtro de'#13#10 +
    '      data (TsDateEdit), exportar/perguntar IA, cor da legenda.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.223  (2026-09-27)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Line editor (insert / duplicate / edit):'#13#10 +
    '    Insert before/after starts blank; buttons bring the previous'#13#10 +
    '      (Alt+Up) or next (Alt+Down) line content on demand.'#13#10 +
    '    Full Find / Replace bar (Ctrl+F, Ctrl+H, F3, F4 replace,'#13#10 +
    '      Shift+F4 replace all, regex); blank search blocked, empty'#13#10 +
    '      replacement asks for confirmation; results in message boxes.'#13#10 +
    '    Clear (Ctrl+Shift+Del), Undo/Redo (Ctrl+Z/Ctrl+Y), Ask AI'#13#10 +
    '      (Ctrl+Shift+A), Ctrl+Enter confirms; shortcuts on captions.'#13#10 +
    '    Internal v3.0.5.223: editor de linha — procurar/substituir,'#13#10 +
    '      desfazer, limpar, linha anterior/seguinte, atalhos.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.222  (2026-09-26)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Tabs + options + edit fixes:'#13#10 +
    '    Drag and drop to reorder the open tabs (order saved in the'#13#10 +
    '      INI; drag cursor while moving).'#13#10 +
    '    Options dialog: MRU sizes, line-hint delay/limits and history'#13#10 +
    '      excerpt size are user-configurable (blank = default).'#13#10 +
    '    Fix: editing a line no longer fails or leaves the list blank.'#13#10 +
    '    Internal v3.0.5.222: reordenar abas + preferencias + fix edicao.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.221  (2026-09-26)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Diff between two files:'#13#10 +
    '    Both lists scroll in sync; captions translated.'#13#10 +
    '    Apply left <-> right in one threaded, cancellable pass'#13#10 +
    '      (raw bytes, only the changed region is rewritten; atomic'#13#10 +
    '      replace) — fast even for 50 GB files.'#13#10 +
    '    Internal v3.0.5.221: uMergeApply + scroll sincronizado.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.220  (2026-09-26)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Session history rework (Compare / merge):'#13#10 +
    '    Substring highlight of the change, better spacing.'#13#10 +
    '    Changed lines list (paged, RAM-safe index for journals of'#13#10 +
    '      any size) with synced selection.'#13#10 +
    '    MRU of files that have merge history; clear list / MRU'#13#10 +
    '      with confirmation.'#13#10 +
    '    Hide / show lists (double-click the titles); panels dock'#13#10 +
    '      by drag.'#13#10 +
    '    Internal v3.0.5.220: uHistChangedIndex + MRU + paineis dockaveis.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.219  (2026-09-26)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Line endings: CR+LF, LF and classic Mac CR supported by all'#13#10 +
    '    routines (index, find, edit, insert, merge, export). New lines'#13#10 +
    '    use the EOL of the file; mixed/unknown use the default EOL.'#13#10 +
    '    Internal v3.0.5.219: uEolPolicy (cache por caminho/tamanho/data).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.218  (2026-09-25)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Startup + language switch:'#13#10 +
    '    Faster startup when many tabs are restored.'#13#10 +
    '    Language switch is faster and can be cancelled from the'#13#10 +
    '      loading overlay (Cancel no longer freezes).'#13#10 +
    '    Assistant pipeline text no longer garbled after switching'#13#10 +
    '      from Chinese; many translation fixes in 14 languages.'#13#10 +
    '    Internal v3.0.5.218: arranque com abas + troca de idioma.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.217  (2026-09-25)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Session history for huge files:'#13#10 +
    '    Paged preview (sparse offset index + LRU page cache, index'#13#10 +
    '      cached on disk) — RAM-safe for files of any size.'#13#10 +
    '    Ctrl+mouse wheel scrolls the history list.'#13#10 +
    '    Export by legend: Inserted / Deleted / Edited / Undo, one or'#13#10 +
    '      several types into a single file.'#13#10 +
    '    Internal v3.0.5.217: uHistPagedPreview + exportar por legenda.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.216  (2026-09-24)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Delphi 10.4 host: technical architecture document updated;'#13#10 +
    '    overlapping controls fixed on the main window.'#13#10 +
    '    Internal v3.0.5.216: ARQUITETURA_TECNICA + layout.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.215  (2026-09-22)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Stability: global exception guard (log + safe message, no'#13#10 +
    '    re-entrancy) and watchdog for UI hangs / memory pressure'#13#10 +
    '    (logs, alerts and cancels cooperative worker threads).'#13#10 +
    '    Internal v3.0.5.215: uFastFileAppGuard + uFastFileWatchdog.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.214  (2026-09-21)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Bookmarks bar (Ctrl+B): docked list, click to jump, Prev/Next,'#13#10 +
    '    remove one, clear all, Export/Copy, hide/float.'#13#10 +
    '  Professional message dialogs (soft gradient, rounded).'#13#10 +
    '  Options dialog (pilot): MRU sizes + line-hint limits.'#13#10 +
    '  MRU dropdowns: partial find, "More" and "Clear all" items.'#13#10 +
    '    Internal v3.0.5.214: uBookmarkBar + uFastFileMsgDlg +'#13#10 +
    '      uUserPrefs/uPrefsDialog + uMruFind.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.213  (2026-09-20)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Line-ending and encoding detection + streaming conversion'#13#10 +
    '    (Windows / Unix / Mac; UTF-8 with/without BOM, UTF-16, ANSI).'#13#10 +
    '    Internal v3.0.5.213: uFileFormatConvert.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.212  (2026-09-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  AI-First post-action pipeline: after find, filter, export,'#13#10 +
    '    split, merge, compare... the Assistant offers "What next?"'#13#10 +
    '    chips + an AI draft; activities and chat turns are kept in'#13#10 +
    '    a bridge store to continue where you left off.'#13#10 +
    '    Internal v3.0.5.212: uAssistantPostAction + PipelineStore.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.211  (2026-09-17)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Find Occurrences bar (after Ctrl+F): Prev/Next (Shift+F3 / F3),'#13#10 +
    '    paged clickable hit list, "Load more" from disk.'#13#10 +
    '  Search tools gallery popup on the file toolbar.'#13#10 +
    '    Internal v3.0.5.211: uFindOccurrencesBar +'#13#10 +
    '      UnitPopupFileSearchGallery.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.210  (2026-09-16)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Startup + docs: uI18n lazy-load (English + active language only;'#13#10 +
    '    other langs on first switch); PutNV allow-list (no TStringList.Tag);'#13#10 +
    '    F1 AssistantBlock / HISTORY / CHANGELOG / README / ROADMAP /'#13#10 +
    '    DOC_ZS_ATALHOS / DOCUMENTACAO_MODELOS_IA synced to 3.0.5.210.'#13#10 +
    '    Internal v3.0.5.210: lazy-load i18n + docs sync + compile fixes.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.209  (2026-09-15)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n: Chinese Simplified + Traditional as 13th/14th UI'#13#10 +
    '    languages — full uI18n coverage (Set14, zh-CN / zh-TW),'#13#10 +
    '    combo + Assistente + Windows LANG_CHINESE detection.'#13#10 +
    '    Internal v3.0.5.209: chines simplificado/tradicional 100%.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.208  (2026-09-15)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Startup: uI18n table build O(n) — PutNV append instead of'#13#10 +
    '    TStringList.Values (O(n^2) IndexOfName) during initialization;'#13#10 +
    '    collapse duplicates (last wins) then binary-search sort.'#13#10 +
    '    Internal v3.0.5.208: acelerar carga — i18n PutNV/collapse.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.207  (2026-09-15)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n: Japanese as 12th UI language — full uI18n.pas coverage:'#13#10 +
    '    alJapanese / ja, GTextJapanese, language.option.japanese,'#13#10 +
    '    combo + Assistente; TAGLINE/RegexExamples/help blocks.'#13#10 +
    '    Internal v3.0.5.207: japones completo em uI18n (12 idiomas).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.100  (2026-09-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  UX polish: docked Filter/Grep bar, assistant chrome, More tools,'#13#10 +
    '  status-bar toggles, AI-first contains-count:'#13#10 +
    '    Ctrl+L opens a docked FilterBar (pattern combo, Apply/Continue/'#13#10 +
    '      Clear/Hide, peek strip, MRU last 20 in ASkin.ini).'#13#10 +
    '    Status bar Mode/Wrap/Tail/Filter/Marks/View — click to toggle.'#13#10 +
    '    Assistant UI: soft chrome, TsPanel CustomColor, recent questions.'#13#10 +
    '    count_matching_lines — local contains/partial count (AI-first).'#13#10 +
    '    More tools gallery — soft-blue item gradient; search/ESC polish.'#13#10 +
    '    Internal v3.0.5.91: Assistente IA — UI remodelada (accent,'#13#10 +
    '      header, caixa pergunta com limpar, resposta em surface,'#13#10 +
    '      Segoe UI; ESC limpa pergunta antes de fechar).'#13#10 +
    '    Internal v3.0.5.92: count_matching_lines AI-first — contagem'#13#10 +
    '      contains/parcial local (evita ConsumerAI 500); sem dicionario'#13#10 +
    '      NL no host; IA escolhe a tool + filter_text=needle.'#13#10 +
    '    Internal v3.0.5.93: Status bar Mode/Wrap/Tail/Filter/Marks/View'#13#10 +
    '      — clique do rato faz toggle (ativar/desativar) em cada opcao.'#13#10 +
    '    Internal v3.0.5.94: Assistente IA — visual mais atraente (superficie,'#13#10 +
    '      accent, cards com borda suave, tipografia, badge atalho,'#13#10 +
    '      botoes e status coloridos).'#13#10 +
    '    Internal v3.0.5.95: Assistente IA — TsPanel + SkinData.CustomColor'#13#10 +
    '      (AlphaSkins nao engolia as cores); accent 8px e header contrastante.'#13#10 +
    '    Internal v3.0.5.96: Filtro/Grep (Ctrl+L) — barra dockada amigavel'#13#10 +
    '      com Edit da string activa, Aplicar/Continuar/Limpar/Ocultar,'#13#10 +
    '      faixa peek para reexibir e status de hits.'#13#10 +
    '    Internal v3.0.5.97: FilterBar — BuildChrome so apos Parent'#13#10 +
    '      (evita EInvalidOperation "has no parent window" no Ctrl+L).'#13#10 +
    '    Internal v3.0.5.98: FilterBar — status em linha completa (sem corte);'#13#10 +
    '      i18n 11 idiomas com acentuacao #nnn (padrao/Contem/etc.).'#13#10 +
    '    Internal v3.0.5.99: FilterBar — dropdown MRU dos ultimos 20 filtros'#13#10 +
    '      (persistido em ASkin.ini); i18n FilterBar.Recent* 11 idiomas.'#13#10 +
    '    Internal v3.0.5.100: Mais ferramentas — itens com fundo azul suave'#13#10 +
    '      em gradiente (familia $00E8F4FF); Confirmado FilterBar.Recent* 11 langs.'#13#10 +
    '    Internal v3.0.5.101: Docs sync — APPLICATION_VERSION 3.0.5.100,'#13#10 +
    '      HISTORY/CHANGELOG/README/ROADMAP/DOC_ZS/DOCUMENTACAO_MODELOS,'#13#10 +
    '      F1 Filter+Assistant help; i18n Filter Ctrl+L line (11 langs).'#13#10 +
    '    Internal v3.0.5.102: Assistente IA — chrome soft-blue (gradiente'#13#10 +
    '      header, hairline accent, badge moldura, card resposta, focus'#13#10 +
    '      na pergunta); alinhado ao Mais ferramentas / ListView.'#13#10 +
    '    Internal v3.0.5.103: Assistente IA — revert soft-blue "fantasma";'#13#10 +
    '      chrome com cores do sistema (clBtnFace/clWindow/clHighlight),'#13#10 +
    '      textos secundarios com contraste legivel, badge/focus/Resposta.'#13#10 +
    '    Internal v3.0.5.104: Assistente IA — cores das 3 areas do main UI'#13#10 +
    '      (toolbar light/mid + IDLE_WORKSPACE_GRAD left/right).'#13#10 +
    '    Internal v3.0.5.105: FilterBar — altura/labels sem corte; Ctrl+L'#13#10 +
    '      toggle (exibe/oculta a barra).'#13#10 +
    '    Internal v3.0.5.106: FilterBar — layout 2 colunas (titulo+modo |'#13#10 +
    '      recentes acima do combo); fim do corte em Contém/Filtro.'#13#10 +
    '    Internal v3.0.5.107: FilterBar — Enter=Aplicar; Exportar/Copiar'#13#10 +
    '      (visiveis so com hits); pergunta selecao vs todos.'#13#10 +
    '    Internal v3.0.5.108: File bar — Reload from disk (mata cache/indice)'#13#10 +
    '      + botao MRU (Ctrl+R) ao lado de edtFileName; i18n 11 idiomas.'#13#10 +
    '    Internal v3.0.5.109: FilterBar — Apply com padrao vazio critica e'#13#10 +
    '      nao executa (Enter/botao); i18n FilterBar.EmptyPattern.'#13#10 +
    '    Internal v3.0.5.110: FilterBar — MRU csDropDownList + edit padrao'#13#10 +
    '      (mesmo padrao visual do Assistente IA); altura 108.'#13#10 +
    '    Internal v3.0.5.111: Filter+ListView — wheel scroll via WM_VSCROLL'#13#10 +
    '      nativo; FileBar hints (ShowHint/TOOLBUTTON) + i18n DFM keys.'#13#10 +
    '    Internal v3.0.5.112: Filter/Grep + Select (checkbox) — Export/Copy'#13#10 +
    '      usa FCheckedLines; scroll range/wheel; FilterThreadDone sync.'#13#10 +
    '    Internal v3.0.5.113: Assistente IA ↔ Filter/Grep (Ctrl+L) — contexto'#13#10 +
    '      filter_text/hits/partial; continue_filter/copy_filtered; NL local.'#13#10 +
    '    Internal v3.0.5.114: MRU dropdowns (FilterBar + edtFileName) —'#13#10 +
    '      primeiros 10 itens + "..." para os restantes.'#13#10 +
    '    Internal v3.0.5.115: Assistente IA — dropdown perguntas recentes'#13#10 +
    '      tambem 10 itens + "..." (mesmo padrao do FilterBar).'#13#10 +
    '    Internal v3.0.5.116: FilterBar — persistir visivel/oculto em'#13#10 +
    '      ASkin.ini (UIPrefs.FilterBarVisible) e restaurar no startup.'#13#10 +
    '    Internal v3.0.5.117: MRU "..." — na 2a pagina o mesmo "..." no'#13#10 +
    '      topo volta aos 10 primeiros (FilterBar + Assistente).'#13#10 +
    '    Internal v3.0.5.118: Chat unico no Assistente IA — ConsumerAI/RAG'#13#10 +
    '      so via Python (sem painel/menu); respostas no Assistente.'#13#10 +
    '    Internal v3.0.5.119: Desativar atalhos Ctrl+Shift+A / menu Ctrl+Alt+R'#13#10 +
    '      dos chats SQL/avancado (Ctrl+Alt+R permanece sessao somente leitura).'#13#10 +
    '    Internal v3.0.5.120: F1 — sem linhas Chat IA (SQL) / Chat IA avancado;'#13#10 +
    '      Q&A de arquivo no Assistente (Ctrl+Alt+A); Ctrl+Alt+R so leitura.'#13#10 +
    '    Internal v3.0.5.121: MRU Find — procura parcial + limpar (Assistente,'#13#10 +
    '      FilterBar, edtFileName); mesmo padrao do "...".'#13#10 +
    '    Internal v3.0.5.122: edtFileName — MRU imediatamente a direita do'#13#10 +
    '      campo; em seguida Reload from disk.'#13#10 +
    '    Internal v3.0.5.123: MRU arquivos recentes — search, campo e ×'#13#10 +
    '      ficam dentro do dropdown (nao na barra ao lado do edtFileName).'#13#10 +
    '    Internal v3.0.5.124: MRU (ficheiros, filtro, Assistente) — procura'#13#10 +
    '      no topo do popup, igual a Mais ferramentas (icone + campo + ×).'#13#10 +
    '    Internal v3.0.5.125: MRU — linhas em cartao (gradiente, icone,'#13#10 +
    '      hover/selecao, reticencias); ficheiros com nome + pasta.'#13#10 +
    '    Internal v3.0.5.126: Assistente IA — overlay SmoothLoading'#13#10 +
    '      (processando + barra) enquanto o chat/modelo/Python corre.'#13#10 +
    '    Internal v3.0.5.127: MRU "..." — acao Mostrar mais (N) / Voltar'#13#10 +
    '      aos primeiros 10, com seta (ficheiros, filtro, Assistente).'#13#10 +
    '    Internal v3.0.5.128: MRU "Mostrar mais" — hint ao pairar'#13#10 +
    '      (perguntas, filtro, ficheiros recentes).'#13#10 +
    '    Internal v3.0.5.129: Assistente — botoes Traduzir (menu de idiomas)'#13#10 +
    '      e Sugerir texto (IA) no canto do campo da pergunta.'#13#10 +
    '    Internal v3.0.5.130: Assistente — chips premium (gradiente, icone,'#13#10 +
    '      hover) para Traduzir e Sugerir.'#13#10 +
    '    Internal v3.0.5.131: Assistente — Traduzir/Sugerir ancorados na'#13#10 +
    '      barra inferior do campo (TOOLBUTTON + legendas, nao chips).'#13#10 +
    '    Internal v3.0.5.132: Assistente — sem edtFileName, nao gera PDF'#13#10 +
    '      vazio/recusa (contagem de prefixos + compose).'#13#10 +
    '    Internal v3.0.5.133: File bar MRU+Reload; SmoothLoading wait do'#13#10 +
    '      Assistente em marquee (nao 0-100 em loop) e overlay durante scan.'#13#10 +
    '    Internal v3.0.5.134: File bar — posicao explicita edt|MRU|Reload;'#13#10 +
    '      icone clock no MRU; Assistente Traduzir a esquerda de Sugerir.'#13#10 +
    '    Internal v3.0.5.135: URLs/paths dos companions (ConsumerAI/RAG/'#13#10 +
    '      ScriptEngine) e FastFile_Download.log centralizados em UnConsts.'#13#10 +
    '    Internal v3.0.5.136: Assistente — Validar fonte (.py via ScriptEngine,'#13#10 +
    '      .js/.ts/.tsx via CodeCheck.exe) apos compose; download no FTP.'#13#10 +
    '    Internal v3.0.5.137: Assistente — chat "carregar/validar fonte";'#13#10 +
    '      lista de linguagens suportadas; validate_source + dialogo.'#13#10 +
    '    Internal v3.0.5.138: Assistente Enviar — SmoothLoading acompanha'#13#10 +
    '      o pedido HTTP (sem barra 0-100 em loop); creep + scan real.'#13#10 +
    '    Internal v3.0.5.139: Validar fonte no chat — "quais linguagens valida?"'#13#10 +
    '      (valida sem espaco); recarregar fonte; dialogo so com exts suportadas.'#13#10 +
    '    Internal v3.0.5.140: Assistente filtro+PDF — auto-Ler se edtFileName'#13#10 +
    '      preenchido; PDF com linhas filtradas (nao metadados de disco).'#13#10 +
    '    Internal v3.0.5.141: Massa Q1-20 — Find/goto auto-Ler; linhas no disco'#13#10 +
    '      se a pergunta pede total; Word como id de formato; count expoe N.'#13#10 +
    '    Internal v3.0.5.142: MRU edtFileName — icones propriedades (dialogo'#13#10 +
    '      Windows) e remover da lista (nao apaga o ficheiro).'#13#10 +
    '    Internal v3.0.5.143: MRU — icones sem reajuste no hover; propriedades'#13#10 +
    '      nao fecha a lista.'#13#10 +
    '    Internal v3.0.5.144: MRU — glifos em caixa fixa (sem CharImageList.Draw).'#13#10 +
    '    Internal v3.0.5.145: MRU — propriedades/Ler de ficheiro inexistente'#13#10 +
    '      remove o item da lista (nao apaga do disco).'#13#10 +
    '    Internal v3.0.5.146: Assistente — compostos nos 11 idiomas (pdf/docx'#13#10 +
    '      e codigo numerico nao exigem verbos em portugues).'#13#10 +
    '    Internal v3.0.5.147: Assistente Enviar 100% AI-first — NL sempre a'#13#10 +
    '      IA; host so path/pdf/aspas/digitos (nao PI121106.txt); compostos'#13#10 +
    '      (explica+linhas+PDF) geram compose_document com lines= real.'#13#10 +
    '    Internal v3.0.5.148: SmoothLoading do Assistente opaco de imediato'#13#10 +
    '      (sem fade 3,6s em alpha 6); barra mais alta e com contraste.'#13#10 +
    '    Internal v3.0.5.149: Chat — caminho completo na pergunta valida e'#13#10 +
    '      preenche edtFileName; se nao existir, recusa sem chamar a IA.'#13#10 +
    '    Internal v3.0.5.150: Pastas ConsumerRAG/data e Build em UnConsts'#13#10 +
    '      (CONSUMER_DATA_DIR, CONSUMERRAG_WORKSPACE_DIR, FASTFILE_BUILD_DIR).'#13#10 +
    '    Internal v3.0.5.151: Sidecars MRU/logs/logo/Skins passam a UnConsts'#13#10 +
    '      (MRU_*_INI, ASSISTANT_LOG, ICON_HELP_PNG, FOLDERSKIN, LOGO).'#13#10 +
    '    Internal v3.0.5.152: Chat sem ficheiro recusa local (nao chama a IA);'#13#10 +
    '      Traduzir nao dispara Enviar (Default off + popup come Enter).'#13#10 +
    '    Internal v3.0.5.153: Contagem do Assistente em blocos binarios (como F5),'#13#10 +
    '      sem ReadLn Unicode; prefixo+total numa passagem, sem scan antes da IA.'#13#10 +
    '    Internal v3.0.5.154: I/O do Assistente unificado (ForEachRawLine / cache'#13#10 +
    '      F5); qualquer tool (prefixo, contains, collect) no mesmo caminho rapido.'#13#10 +
    '      Sem dicionario NL a decidir quando ser rapido.'#13#10 +
    '    Internal v3.0.5.155: MRU do chat nao fecha no clique de abertura'#13#10 +
    '      (lock ate soltar o rato; combo nativo nao compete).'#13#10 +
    '    Internal v3.0.5.156: Traduzir — JSON Unicode (\\uXXXX) e traducao'#13#10 +
    '      completa (sem deixar tokens da lingua origem / sem ? no lugar de s/t).'#13#10 +
    '    Internal v3.0.5.157: MRU do chat — botao remover item (mesmo formato'#13#10 +
    '      do edtFileName; so tira da lista, nao apaga ficheiro).'#13#10 +
    '    Internal v3.0.5.158: MRU dropdown — i18n completo nos 11 idiomas'#13#10 +
    '      (acentos PL/RO/HU/CZ/ES/FR; HU "Tovabb" -> "Tobb megjelenitese").'#13#10 +
    '    Internal v3.0.5.159: MRU do chat nao fecha apos Enviar — ClosingForbide'#13#10 +
    '      depois do ShowPopupForm; cancela hint/balloon e capture residual.'#13#10 +
    '    Internal v3.0.5.160: MRU dropdown sem ShowPopupForm (o balao de arquivo'#13#10 +
    '      salvo deixava o AlphaControls a fechar a lista no clique seguinte).'#13#10 +
    '    Internal v3.0.5.161: Clique no balao "arquivo salvo" fecha o balao'#13#10 +
    '      (VCL era HTTRANSPARENT; o clique atravessava).'#13#10 +
    '    Internal v3.0.5.162: Balao de arquivo salvo e janela propria (clique'#13#10 +
    '      fecha; ja nao usa TBalloonHint).'#13#10 +
    '    Internal v3.0.5.163: Balao de arquivo com texto completo (abaixo do'#13#10 +
    '      banner); MRU do chat nao fecha no clique de abertura do combo.'#13#10 +
    '    Internal v3.0.5.164: MRU do chat ancora debaixo do combo (nao no 0,0);'#13#10 +
    '      frases com / ou C:\\ deixam de ser desenhadas como caminho.'#13#10 +
    '    Internal v3.0.5.165: MRU do chat sem ComboBox nativo (o clique no balao'#13#10 +
    '      atravessava e fechava a lista); balao so some no MouseUp.'#13#10 +
    '    Internal v3.0.5.166: Sem balao de arquivo salvo; aviso no painel do'#13#10 +
    '      assistente com hyperlink para abrir o ficheiro ou a pasta.'#13#10 +
    '    Internal v3.0.5.168: Assistente — cartao de arquivo salvo; Limpar/Copiar'#13#10 +
    '      na barra Traduzir/Sugerir; contador regressivo de 500 caracteres.'#13#10 +
    '    Internal v3.0.5.169: Compose "em TXT" grava .txt (nao default .md).'#13#10 +
    '    Internal v3.0.5.170: Extensao nao suportada abre dialogo com a lista;'#13#10 +
    '      botao ? ao lado de Copiar mostra os formatos que o compose grava.'#13#10 +
    '    Internal v3.0.5.171: Extensao invalida e recusada no Enviar (sem IA).'#13#10 +
    '    Internal v3.0.5.172: Botao ? a esquerda do contador 500 (sem sobrepor).'#13#10 +
    '    Internal v3.0.5.173: Contador 500 no campo da pergunta; ? depois de Copiar.'#13#10 +
    '    Internal v3.0.5.174: Acentos do modal ? e chrome do assistente (11 langs).'#13#10 +
    '    Internal v3.0.5.175: Contador 500 em faixa propria (nao corta o texto).'#13#10 +
    '    Internal v3.0.5.176: FR pente fino — filtro/tempo de leitura + acentos.'#13#10 +
    '    Internal v3.0.5.177: Overlay SmoothLoading ao trocar idioma (11 langs).'#13#10 +
    '    Internal v3.0.5.178: Alerta unificado com contagem 10s + progressbar.'#13#10 +
    '    Internal v3.0.5.179: × e Ctrl+Alt+A ao lado de O que deseja fazer.'#13#10 +
    '    Internal v3.0.5.180: Splitter de altura + paineis desprendiveis.'#13#10 +
    '    Internal v3.0.5.181: HU/PL/RO/CZ — barra Merge/Split/Edit + Export.'#13#10 +
    '    Internal v3.0.5.182: Arrastar o titulo desprende o painel; soltar na'#13#10 +
    '      borda original encaixa de novo (assistente e Filtro/Grep).'#13#10 +
    '    Internal v3.0.5.183: Filtro/Grep e Assistente mais baixos; grips topo/'#13#10 +
    '      base; reencaixe do assistente (arrastar na direita ou duplo clique).'#13#10 +
    '    Internal v3.0.5.184: Accento do filtro mais fino; texto do padrao visivel;'#13#10 +
    '      dock-on do assistente; splitters topo/base com alvos separados.'#13#10 +
    '    Internal v3.0.5.185: Filtro relayout apos redock; splitters do assistente'#13#10 +
    '      no wrapper; clique no titulo ja nao impede o encaixe.'#13#10 +
    '    Internal v3.0.5.186: Sem faixa vazia sob o filtro; assistente reordena'#13#10 +
    '      cabecalho ao voltar do float.'#13#10 +
    '    Internal v3.0.5.187: Assistente encaixa outra vez em alRight no form'#13#10 +
    '      (sem wrapper) e restabelece o stack do chat ao dock off.'#13#10 +
    '    Internal v3.0.5.188: Arrastar de qualquer sitio do painel (filtro e'#13#10 +
    '      chat) para desprender; soltar em qualquer sitio da area para encaixar.'#13#10 +
    '    Internal v3.0.5.189: Dock on so na faixa de origem; o primeiro soltar'#13#10 +
    '      apos desprender fica flutuante (ja nao volta sozinho ao sitio).'#13#10 +
    '    Internal v3.0.5.190: Filtro sem coluna vazia a esquerda; menu/botao'#13#10 +
    '      Restaurar janela flutuante com o painel encaixado.'#13#10 +
    '    Internal v3.0.5.191: ListView/Select — Traduzir, Limpar e Copiar'#13#10 +
    '      no fundo, sobre as linhas selecionadas ou assinaladas.'#13#10 +
    '    Internal v3.0.5.192: Restaurar visualizacao original nos 11 idiomas'#13#10 +
    '      (menu e dica do painel encaixado).'#13#10 +
    '    Internal v3.0.5.193: Motor 100% Unicode — Find/Filtro/Replace/Edit'#13#10 +
    '      usam o encoding do ficheiro (UTF-8/16/32), nao a code page ANSI;'#13#10 +
    '      combo de vista com UTF-32 LE/BE.'#13#10 +
    '    Internal v3.0.5.194: Botao Ler (F5) a esquerda do MRU, visivel so'#13#10 +
    '      quando edtFileName tem caminho.'#13#10 +
    '    Internal v3.0.5.195: Filtro/Grep vazio no edit = Limpar (OnChange).'#13#10 +
    '    Internal v3.0.5.196: Botao Python no Assistente abre o Script Engine'#13#10 +
    '      (linhas selecionadas/marcadas); memo da pergunta e contador visiveis.'#13#10 +
    '    Internal v3.0.5.197: Layout adaptativo a resolucao/DPI — janela,'#13#10 +
    '      paineis laterais e dialogos cabem na area de trabalho.'#13#10 +
    '    Internal v3.0.5.198: Dicas (chk "Dicas das linhas") passam a ligar/'#13#10 +
    '      desligar hints de TODOS os controlos (Assistente, filtro, barra);'#13#10 +
    '      botao Python do Assistente nao abre o painel se edtFileName vazio.'#13#10 +
    '    Internal v3.0.5.199: Barra dos alertas (10s) deixa de saltar a cada'#13#10 +
    '      100ms — pintura continua (~16ms) com tempo real, sem resize de painel.'#13#10 +
    '    Internal v3.0.5.200: Botao Ler (F5) na file bar — icone insert file-2'#13#10 +
    '      (documento + play) em vez de "normal view" (pagina).'#13#10 +
    '    Internal v3.0.5.201: Version History / About / Help — titulos e'#13#10 +
    '      ficheiros de export via constantes UnConsts (HISTORY_TITLE).'#13#10 +
    '    Internal v3.0.5.202: Historico — clique no diario mostra a alteracao'#13#10 +
    '      (INS/DEL/EDT) na linha do preview (so visual); faixa colorida da'#13#10 +
    '      legenda no diario; botao Ajuda F1 usa Help.bmp (nao o X de fechar).'#13#10 +
    '    Internal v3.0.5.203: Filtro/Grep na barra do arquivo — icone funil'#13#10 +
    '      (filter.bmp) em vez do glifo generico de find/documento.'#13#10 +
    '    Internal v3.0.5.204: Abas abertas (Ler, Recentes, Comparar/unir, etc.)'#13#10 +
    '      gravadas no ASkin.ini ao sair e restauradas no proximo arranque;'#13#10 +
    '      zero abas = arranque sem abas.'#13#10 +
    '    Internal v3.0.5.205: edtFileName gravado no INI e restaurado no'#13#10 +
    '      FormCreate (depois do ActionClear) antes das abas no FormShow;'#13#10 +
    '      vazio = nao carrega ficheiro; menu Visualizar "Abas recentes"'#13#10 +
    '      (MRU sem duplicados) + restaurar sessao; i18n 11 idiomas.'#13#10 +
    '    Internal v3.0.5.206: ListView / checklist (modo Select) dockable'#13#10 +
    '      como Filtro e Assistente — arrastar titulo, ↗ restaurar float,'#13#10 +
    '      ↙ encaixar; posicao gravada no ASkin.ini.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.5.0  (2026-08-29)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  AI Assistant: compose documents/code, Clear/Copy, safety lock,'#13#10 +
    '  multi-format export, dedicated output folder:'#13#10 +
    '    Compose standalone files via chat (Ctrl+Alt+A): Word/RTF summary'#13#10 +
    '      pipeline, DOCX/ODT/PDF writers, multi-language source (.py/.js/'#13#10 +
    '      .ts/.tsx/.go/.java/.cpp/.cs/...), intent classifier + capability'#13#10 +
    '      map (anti-phrases: Word summary vs RAG, generate .py vs Script'#13#10 +
    '      Engine). Output under fastfile_assistant\ (not fastfile_temp).'#13#10 +
    '    Clear / Copy reply buttons; saved-path message shows full path +'#13#10 +
    '      blank line before AI elapsed time.'#13#10 +
    '    Safety lock: refuse malware/virus/format-disk/OS shell; block'#13#10 +
    '      writing .exe/.bat/.vbs/.scr/etc. via compose.'#13#10 +
    '    Internal v3.0.5.1: compose_document + summarize-then-RTF; Intent'#13#10 +
    '      + Catalog + Map ingest; uFastFileAIClient resposta JSON.'#13#10 +
    '    Internal v3.0.5.2: uFastFileComposeExport (RTF/DOCX/ODT/PDF);'#13#10 +
    '      FASTFILE_ASSISTANT_OUT_DIR; multi-lang GuessComposeExtension.'#13#10 +
    '    Internal v3.0.5.3: Clear/Copy UI layout; ComposeSavedDetail path'#13#10 +
    '      only; BuildReplyWithTiming blank line before elapsed.'#13#10 +
    '    Internal v3.0.5.4: UserQuestionIsOutOfScopeOrHarmful expanded;'#13#10 +
    '      IsForbiddenComposeExtension; compose prompt refuse-malware.'#13#10 +
    '    Internal v3.0.5.5: F1 FF_HELP.AssistantBlock; i18n 11 langs;'#13#10 +
    '      CHANGELOG + README + ROADMAP + DOC_ZS + DOCUMENTACAO_MODELOS_IA.'#13#10 +
    '    Internal v3.0.5.6: ExpandComposeCStyleEscapes (literal \n in'#13#10 +
    '      compose source); PosBMH Ord and $FF (no ERangeError on Unicode);'#13#10 +
    '      harden JSON \uXXXX parse in uFastFileAIClient.'#13#10 +
    '    Internal v3.0.5.7: ReadComposeSourceSample Int64 Size +'#13#10 +
    '      Pointer(Bytes) (ERangeError on GB+ path); skip sample for pure'#13#10 +
    '      source compose.'#13#10 +
    '    Internal v3.0.5.8: PdfEscapeWinAnsi — Delphi Format has no %o;'#13#10 +
    '      build \ddd octal manually (EConvertError on PDF compose).'#13#10 +
    '    Internal v3.0.5.9: PDF word-wrap (no Copy 110 hard truncate).'#13#10 +
    '    Internal v3.0.5.10: "nos formatos word e odt" -> compose (not RAG);'#13#10 +
    '      multi-format sibling writes (.rtf+.odt).'#13#10 +
    '    Internal v3.0.5.11: Join .partNNN via TJoinEqualSplitPartsThread +'#13#10 +
    '      SmoothLoading (no UI freeze on reunite).'#13#10 +
    '    Internal v3.0.5.12: Line Editor i18n — #nnn escapes (fix NÃºmero/'#13#10 +
    '      ConteÃºdo mojibake from UTF-8 literals in Set11).'#13#10 +
    '    Internal v3.0.5.13: Assistant "esse arquivo" / open edtFileName path;'#13#10 +
    '      word parts (duas/two); SplitStarted/PartsRange accents.'#13#10 +
    '    Internal v3.0.5.14: Split/extract with empty edtFileName opens file'#13#10 +
    '      picker (ask which file) instead of only NoFileOpen error.'#13#10 +
    '    Internal v3.0.5.15: Assistente IA from idle main opens Read tab +'#13#10 +
    '      panel (idle logo no longer covers assistant).'#13#10 +
    '    Internal v3.0.5.16: "juntar esse arquivo" = merge/join like split'#13#10 +
    '      (open edtFileName / path / file picker).'#13#10 +
    '    Internal v3.0.5.17: Assistant NL multilingual (PT/EN/ES/FR/DE/IT +'#13#10 +
    '      PL/RO/HU/CZ phrases); parts words; this-file tokens; fillers.'#13#10 +
    '    Internal v3.0.5.18: Main toolbar — Equal parts + Merge files after Read.'#13#10 +
    '    Internal v3.0.5.19: "Pode juntar esse arquivo?" -> merge tab (not RAG).'#13#10 +
    '    Internal v3.0.5.20: AI disambiguates ambiguous local plans; prompt'#13#10 +
    '      + map cover all 11 UI languages for toolbar tools.'#13#10 +
    '    Internal v3.0.5.21: Fold umlauts (zusammenführen→zusammenfuehren)'#13#10 +
    '      so DE merge/join maps like EN/PT; Fold covers HU/PL/CZ/RO too.'#13#10 +
    '    Internal v3.0.5.22: export_lines reply shows full output path + name.'#13#10 +
    '    Internal v3.0.5.23: Assistant Clear/Copy only touch assistant memos;'#13#10 +
    '      no file/RAG shortcuts; UI texts refresh on language change (11 langs).'#13#10 +
    '    Internal v3.0.5.24: More tools gallery — fix clipped last item,'#13#10 +
    '      auto-size popup; caption/hint i18n (11 langs).'#13#10 +
    '    Internal v3.0.5.25: Assistant map export_lines + line-range heuristics'#13#10 +
    '      in 11 langs (FR/DE/HU/PL/RO/CZ/IT/ES); open file phrases expanded.'#13#10 +
    '    Internal v3.0.5.26: Map tail/bookmark/session/script + consumer_rag/compose'#13#10 +
    '      phrases in 11 langs; SCORING_POLITENESS_TOKENS pipe table.'#13#10 +
    '    Internal v3.0.5.27: Map view/help/consumer_ai phrases in 11 langs'#13#10 +
    '      (CSV, fullscreen, index policy, F1/about/changelog, SQL count).'#13#10 +
    '    Internal v3.0.5.28: Assistant checkbox/status layout — wrapped label,'#13#10 +
    '      dynamic panel height (no clipped i18n text).'#13#10 +
    '    Internal v3.0.5.29: NL questions (?, politeness, FR/DE/…) use LLM on Send;'#13#10 +
    '      path extract strips trailing ?/space; merge local only if AI→RAG wrong.'#13#10 +
    '    Internal v3.0.5.30: Script Engine export banner (file/folder/actions),'#13#10 +
    '      tray balloon on finish, multi-line log without horizontal scroll.'#13#10 +
    '    Internal v3.0.5.31: Assistant ConsumerGate — block Python for native tools;'#13#10 +
    '      confirm before ConsumerRAG/ConsumerAI; cautious content/SQL gate.'#13#10 +
    '    Internal v3.0.5.32: Script export toast balloon + dismiss; Output WordWrap;'#13#10 +
    '      short wrapped status (no horizontal scroll for save path).'#13#10 +
    '    Internal v3.0.5.33: "explicar… gerando PDF/Word" -> compose_document,'#13#10 +
    '      not ConsumerRAG; rich-doc phrases (gerando um pdf) + local correction.'#13#10 +
    '    Internal v3.0.5.34: AI-first assistant — NL always to LLM (shortcuts only local);'#13#10 +
    '      ConsumerGate = confirm/whitelist; structural path fill; routing in prompt.'#13#10 +
    '    Internal v3.0.5.35: Assistente IA — faixa/balão "Arquivo salvo" só quando'#13#10 +
    '      o assistente gera PDF/DOC/etc.; Abrir/Pasta/Copiar; bandeja abre o ficheiro.'#13#10 +
    '    Internal v3.0.5.36: Notify arquivo gerado via TTrayIcon.ShowBalloonHint'#13#10 +
    '      (balão nativo da bandeja, estilo DevMedia); clique abre o ficheiro.'#13#10 +
    '    Internal v3.0.5.37: Tray balloon — ícone do exe + texto truncado (limite'#13#10 +
    '      Shell 255); evita falha do ShowBalloonHint que deixava só o Hint.'#13#10 +
    '    Internal v3.0.5.38: Faixa+balão em todos os chats IA ao gerar/exportar'#13#10 +
    '      ficheiro (RAG/SQL/Script/Tail/Assistente); detecta path no OUTPUT.'#13#10 +
    '    Internal v3.0.5.39: Faixa "Arquivo salvo" — pasta encurtada + ellipsis;'#13#10 +
    '      evita "Pasta:" cortada no painel estreito do Assistente.'#13#10 +
    '    Internal v3.0.5.40: "quantas linhas neste arquivo?" (11 langs) responde'#13#10 +
    '      com totalLines do ficheiro aberto — sem ConsumerAI vago.'#13#10 +
    '    Internal v3.0.5.41: Arquivo subentendido ("esse arquivo") → exige'#13#10 +
    '      edtFileName; se preenchido, segue AI-first + path no plano.'#13#10 +
    '    Internal v3.0.5.42: Metadados do ficheiro (criacao/modificacao/tamanho)'#13#10 +
    '      + pronomes "dele/dela"; responde do disco, nao "nao consigo".'#13#10 +
    '    Internal v3.0.5.43: edtFileName preenchido = contexto com created/modified/'#13#10 +
    '      size; factos locais + AI-first usam sempre esse ficheiro.'#13#10 +
    '    Internal v3.0.5.44: Pergunta composta (linhas + criacao/etc.) responde'#13#10 +
    '      todas as partes na mesma resposta local.'#13#10 +
    '    Internal v3.0.5.45: Factos locais (linhas/datas/tamanho) so interceptam'#13#10 +
    '      quando a pergunta e so isso; qualquer mistura (explicar, gerar doc,'#13#10 +
    '      filtrar, SQL, python, etc.) vai ao LLM com CURRENT_CONTEXT + regra 8i.'#13#10 +
    '    Internal v3.0.5.46: Resposta composta explicar+linhas+PDF: forca'#13#10 +
    '      compose_document (nao ConsumerRAG), inclui contagem de linhas no'#13#10 +
    '      chat e no PDF, e mostra o banner do arquivo gerado.'#13#10 +
    '    Internal v3.0.5.47: Perguntas compostas dinamicas — sempre via IA;'#13#10 +
    '      app so enriquece factos locais e corrige rota de ferramenta;'#13#10 +
    '      nao substitui a user_message composta pela IA.'#13#10 +
    '    Internal v3.0.5.48: Contagens filtradas (iniciam com / somatorio) + PDF'#13#10 +
    '      vao ao ConsumerAI — nao inventa PDF via compose; nao injeta totalLines'#13#10 +
    '      quando a pergunta e prefixo/filtro.'#13#10 +
    '    Internal v3.0.5.49: Apos ConsumerAI responder contagens/agregados, gera'#13#10 +
    '      automaticamente o PDF/Word pedido com o resultado real (banner inclusivo).'#13#10 +
    '    Internal v3.0.5.50: Pipeline AI-first dinamico — detecta operacoes matematicas'#13#10 +
    '      no ficheiro (soma/media/%/prefixo/…) e compoe pedidos mistos (ex: calcular'#13#10 +
    '      + "e tb me gere um PDF") via ConsumerAI + documento do resultado.'#13#10 +
    '    Internal v3.0.5.51: Contagem "linhas que iniciam com X/Y" feita localmente'#13#10 +
    '      (sem Lambda NL→SQL); gera PDF com numeros reais; evita Error 500 e'#13#10 +
    '      "Concluido" sem resposta.'#13#10 +
    '    Internal v3.0.5.52: Perguntas dinamicas AI-first — count_line_prefixes e'#13#10 +
    '      ferramenta generica (prefixos em filter_text); sem frase de exemplo'#13#10 +
    '      hard-coded; PDF apos contagem quando o pedido inclui gerar documento.'#13#10 +
    '    Internal v3.0.5.53: Assistente IA — dropdown "Perguntas recentes" (MRU 20),'#13#10 +
    '      persistido em ASkin.ini; i18n 11 idiomas.'#13#10 +
    '    Internal v3.0.5.54: count_line_prefixes — nao usa fragmento NL como prefixo;'#13#10 +
    '      parse extrai todos os valores (ex. 010055102 e 2527474) e inclui total'#13#10 +
    '      de linhas quando pedido na mesma pergunta.'#13#10 +
    '    Internal v3.0.5.55: Explicar+linhas+PDF → compose_document (nao ConsumerAI);'#13#10 +
    '      "quantas linhas" total nao conta como math/SQL; evita Error 500.'#13#10 +
    '    Internal v3.0.5.56: AI-first mais robusto — prioriza intent (11 langs/parafrase);'#13#10 +
    '      sinais estruturais (prefixos); nunca rebaixa compose_document para ConsumerAI.'#13#10 +
    '    Internal v3.0.5.57: Compose PDF com datas/tamanho do disco — amostra do ficheiro'#13#10 +
    '      aberto ("esse arquivo"); KNOWN_FACTS obrigatorios; rejeita "nao consigo acessar".'#13#10 +
    '    Internal v3.0.5.58: Compose AI-first — sujeito = ficheiro aberto (edtFileName),'#13#10 +
    '      sem gate por pronome/frase; path explicito na pergunta sobrescreve o contexto.'#13#10 +
    '    Internal v3.0.5.59: Q7 tamanho/linhas+PDF → compose (exportar PDF != Export dialog);'#13#10 +
    '      Q8 filtrar+explicar → apply_filter (needle apos contem) + ConsumerRAG.'#13#10 +
    '    Internal v3.0.5.60: Auditoria Q9-20 — native tools nao sao roubados por compose;'#13#10 +
    '      Conta+prefixo; export_lines preserva factos; follow-up RAG/PDF apos split/find/merge;'#13#10 +
    '      tokens acesso/tamanho em PT.'#13#10 +
    '    Internal v3.0.5.61: Q8 filtro+explicar — detecta "representa"; soft-cap do filtro'#13#10 +
    '      do Assistente (mantem primeiros N hits, sem MessageBox que apaga resultados).'#13#10 +
    '    Internal v3.0.5.62: Filtro stream — hits sempre em disco (temp_filter_hits.bin);'#13#10 +
    '      paginas de 100k + Continuar (menu Editar / Ctrl+L pergunta se parcial).'#13#10 +
    '    Internal v3.0.5.63: Apos count_line_prefixes + PDF (ex. ES "genera un PDF")'#13#10 +
    '      grava compose mesmo se FileMathOrDataOp falhar (empiezan/cuantas).'#13#10 +
    '    Internal v3.0.5.64: AI-first compose-after-count — preserva compose_document'#13#10 +
    '      da IA + sinal estrutural pdf/docx (sem dicionario NL por idioma).'#13#10 +
    '    Internal v3.0.5.65: ApplyLocalIntentCorrection AI-first — nao sobrescreve'#13#10 +
    '      ActionId valido da IA com dicionarios NL; so enriquece params / redirects'#13#10 +
    '      estruturais (prefix digits, consumer vazio/errado -> count/compose).'#13#10 +
    '    Internal v3.0.5.66: TryCatalogEnrichActionParams — pos-IA so preenche path/'#13#10 +
    '      filter/parts; TryCatalogResolveAction fica so no caminho atalho local (sem LLM).'#13#10 +
    '    Internal v3.0.5.67: Pos-IA sem LooksLike*/UserWantsCompose* como router —'#13#10 +
    '      NativeFollowUpAction (chain AI ou pdf/docx estrutural); flatten [native,'#13#10 +
    '      compose|rag]; compose sample/pipeline por ficheiro aberto + format id.'#13#10 +
    '    Internal v3.0.5.68: count+PDF — nao sobrescreve Contagens com sample AI'#13#10 +
    '      ("amostra tem N linhas"); limpa NativeFollowUp apos count; compose'#13#10 +
    '      prefix-count grava ExecMsg; ignora "100 primeiras linhas" como prefixo.'#13#10 +
    '    Internal v3.0.5.69: Perguntas recentes — dedupe por chave normalizada'#13#10 +
    '      (CRLF/espacos/acentos) e pelo texto truncado do dropdown; limpa INI.'#13#10 +
    '    Internal v3.0.5.70: Q8 — se IA devolve action valido com intent=explain,'#13#10 +
    '      promove intent=execute (confia no ActionId); auto-RAG sem MessageBox;'#13#10 +
    '      prompt exige actions [apply_filter, consumer_rag]. Sem UserWantsApplyFilter.'#13#10 +
    '    Internal v3.0.5.71: Filtro/find + PDF — AI-first: confia na chain da IA;'#13#10 +
    '      compose so se a IA pediu compose OU hop-2 vazio + format id estrutural;'#13#10 +
    '      nao sobrescreve consumer_rag explicito da IA.'#13#10 +
    '    Internal v3.0.5.72: Compose prompt — proibe tutorial TXT→PDF (enscript/'#13#10 +
    '      ps2pdf/Imprimir>PDF); resposta e o corpo do documento que o FastFile ja grava.'#13#10 +
    '    Internal v3.0.5.73: Compose sample — 12 KB / 40 linhas; corte no ultimo LF'#13#10 +
    '      (nunca a meio da linha) + marcador sample truncated.'#13#10 +
    '    Internal v3.0.5.74: PDF com linhas filtradas — host recolhe ate N linhas'#13#10 +
    '      completas (hits do filtro / scan); anexa ao PDF; IA so resume; limite'#13#10 +
    '      estrutural (ex. 100) via digitos curtos.'#13#10 +
    '    Internal v3.0.5.75: AI-first max_lines — limite e needle vem dos params da IA'#13#10 +
    '      (max_lines/filter_text); remove scrape de digitos/NL da pergunta.'#13#10 +
    '    Internal v3.0.5.76: Compose append — nao grava no PDF o marcador de prompt'#13#10 +
    '      FILTERED_LINES (...); so as linhas recolhidas pelo host.'#13#10 +
    '    Internal v3.0.5.77: Filter+PDF — nao recolhe linhas na UI antes da IA'#13#10 +
    '      (travava no scan vs filtro async); collect no write; sem scan 2M'#13#10 +
    '      enquanto FFilterThread corre.'#13#10 +
    '    Internal v3.0.5.78: Assistente IA — largura redimensionavel (splitter)'#13#10 +
    '      + persistencia AssistantPanelWidth no ASkin.ini.'#13#10 +
    '    Internal v3.0.5.79: More tools gallery — cabecalho, grupos com'#13#10 +
    '      separadores, Segoe UI, mais padding/hover nos itens.'#13#10 +
    '    Internal v3.0.5.80: More tools — tiles TOOLBUTTON (icone em cima),'#13#10 +
    '      seccoes DIVIDIR/LOCALIZAR/APARENCIA + subtitulo.'#13#10 +
    '    Internal v3.0.5.81: More tools — itens alinhados a esquerda; largura'#13#10 +
    '      dinamica sem cortar legendas; layout menu (icone+texto) + grupos.'#13#10 +
    '    Internal v3.0.5.82: More tools — altura estavel (PrepareLayout'#13#10 +
    '      exacto + ShowPopupForm sem animacao); faixa accent + polish.'#13#10 +
    '    Internal v3.0.5.83: More tools — recria o popup a cada abertura'#13#10 +
    '      (UpdateScale AlphaSkins 96→DPI so na 1a instancia; evita height/2).'#13#10 +
    '    Internal v3.0.5.84: More tools — campo Procurar no cabecalho (filtro'#13#10 +
    '      parcial por caption/hint; esconde grupos vazios).'#13#10 +
    '    Internal v3.0.5.85: More tools — chrome alinhado a TOOLBUTTON da'#13#10 +
    '      toolbar (Blend/Reflected, Tahoma, grupos e procura reforcados).'#13#10 +
    '    Internal v3.0.5.86: More tools itens — titulo bold + atalho muted'#13#10 +
    '      a direita; MENUITEM hover; item seleccionado em clHighlight.'#13#10 +
    '    Internal v3.0.5.87: More tools — icone de procura no campo;'#13#10 +
    '      atalhos Ctrl+Shift+F (Localizar) e Ctrl+Alt+K (Skin);'#13#10 +
    '      i18n 11 idiomas com acentos corrigidos.'#13#10 +
    '    Internal v3.0.5.88: More tools — icone de procura remodelado'#13#10 +
    '      (Segoe MDL2 fino + campo unico EDIT; sem bitmap da toolbar).'#13#10 +
    '    Internal v3.0.5.89: More tools procura — caixa EDIT com lupa'#13#10 +
    '      FontAwesome 16px, placeholder proprio e Segoe UI.'#13#10 +
    '    Internal v3.0.5.90: More tools — ESC fecha a galeria; botao X'#13#10 +
    '      limpa o texto da procura (ESC no campo limpa antes).'#13#10 +
    '      (FilterBar / count_matching / status toggles / assistant chrome /'#13#10 +
    '      More tools gradient — see v3.0.5.100 current block; no dup.)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.4.0  (2026-07-16)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Advanced AI Chat (file) on GB+ files, chat scroll, preview'#13#10 +
    '  encoding, and Read/About polish:'#13#10 +
    '    Advanced AI Chat (file) (Ctrl+Alt+R) opens any-size files fast:'#13#10 +
    '      ConsumerRAG.py defaults to FastTextRAG streaming lexical search'#13#10 +
    '      (no upfront embeddings); e.g. a 3.6 GB TXT opens quickly;'#13#10 +
    '      full semantic index is opt-in (--semantic-index).'#13#10 +
    '    Cancel loading / Close no longer freeze the UI: panel hides at'#13#10 +
    '      once; ConsumerRAG.exe stopped in background (TerminateProcess +'#13#10 +
    '      timed 750 ms reader-thread wait); Cancel/Close always clickable.'#13#10 +
    '    Compare / Merge preview + session history fix mojibake: encoding'#13#10 +
    '      auto-detect (UTF-8 / ANSI / UTF-16 via uTextEncoding); journal'#13#10 +
    '      read/written as UTF-8 (uFileSessionHistory, uCompareMergeUI).'#13#10 +
    '    Mouse wheel (and Ctrl+wheel) over any AI chat sidebar (SQL,'#13#10 +
    '      Advanced, Assistant, Script) scrolls that transcript, not the'#13#10 +
    '      main ListView / zoom.'#13#10 +
    '    Read (Ctrl+1 / toolbar): with a file already open, opens the file'#13#10 +
    '      browser and loads the chosen file immediately.'#13#10 +
    '    Toolbar About button shortened to "About" (titlebar.about, 11 langs).'#13#10 +
    '    Internal v3.0.4.1: ConsumerRAG.py FastTextRAG default, lazy heavy'#13#10 +
    '      imports, overview budget; Delphi launch drops --semantic-index;'#13#10 +
    '      bridge progress %/ETA; smoke test timeout 300 s; PyInstaller fixes.'#13#10 +
    '    Internal v3.0.4.2: MainUnit StopConsumerRAGProcess non-blocking;'#13#10 +
    '      ConsumerRAGCloseClick hides panel first; Cancel/Close BringToFront;'#13#10 +
    '      title label Enabled False so buttons stay clickable.'#13#10 +
    '    Internal v3.0.4.3: uTextEncoding RawBytesToDisplayString /'#13#10 +
    '      DetectTextFileEncoding; uCompareMergeUI ReadTextFileLineSlice'#13#10 +
    '      PAnsiChar + BOM skip; uFileSessionHistory UTF8Encode journal.'#13#10 +
    '    Internal v3.0.4.4: ActionReadFileExecute TOpenDialog when loaded;'#13#10 +
    '      HwndInSideChatPanels / TryScrollSideChatWheel; FormMouseWheel +'#13#10 +
    '      ScriptMemoAppMessage route wheel to chat memos.'#13#10 +
    '    Internal v3.0.4.5: F1 FF_HELP.AIChatFileBlock; i18n 11 langs'#13#10 +
    '      (Open file, titlebar.about); CHANGELOG + README + ROADMAP +'#13#10 +
    '      DOC_ZS_ATALHOS + DOCUMENTACAO_MODELOS_IA sync.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.3.0  (2026-06-28)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Delphi 10.4.2 Win64 host + fast index scan + UI polish:'#13#10 +
    '    Win64 build (Build\Win64\FastFile.exe) alongside Win32;'#13#10 +
    '    platform Skins deploy; single-instance mutex per arch.'#13#10 +
    '    Operation timer log (upper-right): TListBox on Win64'#13#10 +
    '      (AlphaControls TsMemo repaint fix); AppendOperationTimerLog.'#13#10 +
    '    Line index SWAR scan (8-byte + AVX2-gated 32-byte wide);'#13#10 +
    '      uLineIndexScan.pas; parallel part-files disabled (sparse'#13#10 +
    '      index >2 GB regression). Smooth F5 progress ~22 Hz.'#13#10 +
    '    Internal v3.0.3.1: D10.4.2 dproj/dpr, compile_verify_win64.'#13#10 +
    '    Internal v3.0.3.2: Build\Win32\ / Build\Win64\ + Skins copy.'#13#10 +
    '    Internal v3.0.3.3: pnlTimerLog + LB_ADDSTRING timer history.'#13#10 +
    '    Internal v3.0.3.4: uLineIndexScan; LINE_INDEX_PARALLEL_ENABLED'#13#10 +
    '      False; sequential ScanCardinalAt restored in TReadFileThread.'#13#10 +
    '    Internal v3.0.3.5: PostReadProgress throttle; F1 Win64IndexBlock;'#13#10 +
    '      i18n 11 langs; CHANGELOG + README + ROADMAP + docs sync.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.2.0  (2026-06-02)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Idle workspace branding + vertical block selection fix:'#13#10 +
    '    Empty workspace: blue gradient, logo + large watermark,'#13#10 +
    '    centered FastFile title/tagline (TsFloatButtons overlay);'#13#10 +
    '    high-res PNG (1200 px), Lanczos downscale, paint cache,'#13#10 +
    '    stable layout when AI assistant opens/closes; no startup'#13#10 +
    '    rectangle flash. See DOC_IDLE_LOGO_WORKSPACE.md.'#13#10 +
    '    Ctrl/Alt+drag block select keeps your column width on'#13#10 +
    '    mouse up (ListView + checkbox list); F11 extends block'#13#10 +
    '    to full content width only when pressed (not on release).'#13#10 +
    '    Internal v3.0.2.1: IdleLogoBgFloat, ResolveBestIdleLogoPng,'#13#10 +
    '      IdleLogoStretchSmooth, FIdleLogoPaintCache, PROCESS_REV 30.'#13#10 +
    '    Internal v3.0.2.2: removed ExpandColumnBlockSelectionToContent'#13#10 +
    '      Width from MouseUp / checklist layout sync (regression).'#13#10 +
    '    Internal v3.0.2.3: F1 FF_HELP.ReadPanelBlock + IdleWorkspace;'#13#10 +
    '      i18n 11 langs; CHANGELOG + README + ROADMAP + docs sync.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.1.0  (2026-06-02)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Post-3.0 update: assistant opens Nth file from Recent'#13#10 +
    '    Files list (open_recent_file, recent_index); download'#13#10 +
    '    fixes for ConsumerAI.exe / ConsumerRAG.exe / ScriptEngine.exe'#13#10 +
    '    (PyInstaller cookie, URLMon fallback, PE validation, 1h timeout);'#13#10 +
    '    AI panels renamed Chat com IA / Chat Avancado com IA (11 langs);'#13#10 +
    '    ResolveConsumerSourceFilePath ([READ ONLY] path); assistant UI'#13#10 +
    '    MemoReply restore. See CHANGELOG_IMPLEMENTACOES.md v3.0.1.x.'#13#10 +
    '    Internal v3.0.1.1: open_recent_file + AssistantCbGetRecentFilePath,'#13#10 +
    '      ApplyLocalIntentCorrection, context recent_N in assistant prompt.'#13#10 +
    '    Internal v3.0.1.2: uFastFileExternalExe PyInstaller cookie fix;'#13#10 +
    '      DownloadExecutableDirect URLMon 3rd attempt, WinInet errors,'#13#10 +
    '      IsValidDownloadedCompanionExe PE fallback (uFastFilePaths).'#13#10 +
    '    Internal v3.0.1.3: Menu AI Chat + Advanced AI Chat i18n (11 langs);'#13#10 +
    '      F1 help shortcuts; DOC_ZS_ATALHOS; no (C)/(A) menu suffix.'#13#10 +
    '    Internal v3.0.1.4: ResolveConsumerSourceFilePath — Chat panels accept'#13#10 +
    '      file open in Read tab (strip [READ ONLY] decoration).'#13#10 +
    '    Internal v3.0.1.5: Assistant MemoReply + ApplyAssistantSoftChrome;'#13#10 +
    '      RefreshFastFileAssistantSurface; Assistant.Error.RecentListOutOfRange.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v3.0.0.0  (2026-05-23)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  FastFile reaches VERSION 3.0.0.0 — consolidated product'#13#10 +
    '    milestone: operational AI assistant (local + gateway),'#13#10 +
    '    EmEditor GB+ analytics, Zero Scan parity, menu reorg,'#13#10 +
    '    11-language i18n, temp-path constants (uFastFilePaths).'#13#10 +
    '    See CHANGELOG_IMPLEMENTACOES.md for full merge notes.'#13#10 +
    '    Internal v3.0.0.1: uFastFilePaths.pas — TEMPFILE,'#13#10 +
    '      TEMP_CKPT_FILE, filter hits, edit/merge scratch beside'#13#10 +
    '      EXE; UnConsts documents names; SysUtils.FindClose fix.'#13#10 +
    '    Internal v3.0.0.2: Assistant local planner — filter+export,'#13#10 +
    '      replace all, split equal parts, extract 1/N part, export'#13#10 +
    '      line range / matching lines to file; catalog tokens; errors'#13#10 +
    '      shown instead of silent no-op (TryHandleLocalSendQuery).'#13#10 +
    '    Internal v3.0.0.3: Delete line with filter active — physical'#13#10 +
    '      line delete (AssistantCbDeletePhysicalLine); post-edit'#13#10 +
    '      ListView refresh even when FQuietFinish (uSmoothLoading).'#13#10 +
    '    Internal v3.0.0.4: Export filtered / matching — thread for'#13#10 +
    '      large hit sets; clipboard limits; export-to-txt preference.'#13#10 +
    '    Internal v3.0.0.5: Assistant i18n — local status, popup paste,'#13#10 +
    '      delete line, export/replace/split messages (11 langs).'#13#10 +
    '    Internal v3.0.0.6: Assistant keyboard — Read shortcuts when'#13#10 +
    '      focus in assistant panel: Ctrl+H/L/F, Ctrl+Shift+L/Q/F/K,'#13#10 +
    '      Ctrl+C/V/Z/Y (file undo/redo), Ctrl+Alt+P pattern split;'#13#10 +
    '      memo paste routes to paste_lines into file; F1 block updated.'#13#10 +
    '    Internal v3.0.0.7: Merged v2.1.7.29-31 deliverables (no dup):'#13#10 +
    '      Tools/Session/Options menu, uEmEditorFeatures, assistant'#13#10 +
    '      whitelist +12 actions (filter, dedup, freq strings, etc.).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.31  (2026-05-23)  (previous — pre-3.0 track)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Assistant whitelist +12 actions: filter, export, dedup,'#13#10 +
    '    freq strings, checkboxes, goto line, char code, merge tabs,'#13#10 +
    '    word wrap; filter_text and line_no JSON params.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.30  (2026-05-23)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  FastFile operational AI assistant (phases 2-4):'#13#10 +
    '    AI menu > FastFile Assistant; optional startup (ASkin.ini);'#13#10 +
    '    JSON explain/execute/unknown; action chains (read then split);'#13#10 +
    '    Actions: open/read, tabs, help, find/replace, tail, compare,'#13#10 +
    '      split equal parts, extract parts subset; RAG help snippets;'#13#10 +
    '    Optional Assistant.log when AssistantLog=1; F1 section; 11 langs.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.29  (2026-05-23)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Main menu reorg, EmEditor tools, GB+ analytics threads:'#13#10 +
    '    Internal v2.1.7.29: Top menu Tools / Session / Options'#13#10 +
    '      (slim); Tools submenus Filter+analysis, Split/merge,'#13#10 +
    '      Lines, Tail, Automation, Export/Clear; Session RO +'#13#10 +
    '      save/load; Options = Performance (segmented ops) only;'#13#10 +
    '      RebuildMainMenu + menu icons; uI18n MainMenuReorg.'#13#10 +
    '    Internal v2.1.7.30: uEmEditorFeatures.pas - Character Code'#13#10 +
    '      Value (View); Extract Frequent Strings; Delete Duplicate'#13#10 +
    '      Lines (Tools > Filter and analysis); FastFile.dpr.'#13#10 +
    '    Internal v2.1.7.31: MMF line scan (8 MB buffer); freq'#13#10 +
    '      buckets + spill for files > 8 MB; TDiskKeySet chained'#13#10 +
    '      dedup on disk; worker threads + progress GB/MB/s/ETA;'#13#10 +
    '      UI stays responsive on 20-50 GB files.'#13#10 +
    '    Internal v2.1.7.32: ConfirmDiskSpaceForPaths before dedup;'#13#10 +
    '      AddCommonTranslationsEmEditorFeatures (11 langs); F1 help'#13#10 +
    '      Tools/EmEditor sections; menu-bar Alt+T/S hints.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.25  (2026-05-23)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Zero Scan parity, extract file parts, exit cleanup:'#13#10 +
    '    Internal v2.1.7.25: Zero Scan without dense index - Ctrl+G'#13#10 +
    '      physical line (GotoPhysicalLine1Based); Find/Replace no upfront'#13#10 +
    '      index block; Replace All streaming; batch delete MMF path;'#13#10 +
    '      F1 help Zero Scan section; regression guard when temp.txt'#13#10 +
    '      exists (UsesProportionalZeroScanScroll false).'#13#10 +
    '    Internal v2.1.7.26: On exit, delete temp.txt + temp_ckpt.txt'#13#10 +
    '      (CleanupFastFileLineIndexFiles in FormClose / shutdown).'#13#10 +
    '    Internal v2.1.7.27: Extract file parts (Ctrl+Shift+Q) - rename'#13#10 +
    '      from fraction; i18n menu/dialog (11 languages); output names'#13#10 +
    '      basename.parte_1_de_8.ext (translated keywords); scrollable'#13#10 +
    '      success dialog; Zero Scan line count for split; restore ListView'#13#10 +
    '      after export (ReopenFileStreamsOnly + saved session state).'#13#10 +
    '    Internal v2.1.7.28: Zero Scan Shift+End - discover last physical'#13#10 +
    '      line: regressive proportional list scan + full LF count thread'#13#10 +
    '      (TZeroScanDiscoverLastLineThread) for files >256 MB; works in'#13#10 +
    '      checkbox list mode; avoids O(file) scan on proportional map.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.21  (2026-05-23)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Tail macro Python, equal-parts split fix, script engine GB+:'#13#10 +
    '    Internal v2.1.7.21: Tail macro Python panel (Options menu,'#13#10 +
    '      uTailMacro.pas); transform(line, ctx) via ScriptEngine LINE;'#13#10 +
    '      examples sidebar + Talk with AI; settings in ASkin.ini.'#13#10 +
    '    Internal v2.1.7.22: Tail macro GB+ (batch stdin flush, chunked'#13#10 +
    '      queue, silent file output, reprocess Ctrl+Shift+R); include'#13#10 +
    '      macro results in tail export (Ctrl+Shift+L); uTailExportDialog'#13#10 +
    '      full i18n (11 languages); export path options in panel.'#13#10 +
    '    Internal v2.1.7.23: Split equal parts by balanced line count'#13#10 +
    '      (FastFileCountLinesLf, LF boundaries - no mid-line cuts);'#13#10 +
    '      SplitEqualParts.CountingLines progress + i18n.'#13#10 +
    '    Internal v2.1.7.24: Script engine large-file mode - sparse index'#13#10 +
    '      (temp_ckpt.txt), direct OUTFILE to disk (memo stays light);'#13#10 +
    '      Large file mode message + ENGINE_VERSION 5+ upgrade hint;'#13#10 +
    '      uI18n tail macro / script output strings (11 languages).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.17  (2026-05-19)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Line autofill, CSV after edit, undo, and delete refresh:'#13#10 +
    '    Internal v2.1.7.17: EmEditor-style line autofill - drag'#13#10 +
    '      down on Line # column (no Ctrl/Alt) inserts blank rows;'#13#10 +
    '      preview while dragging; CSV mode inserts delimiter-only'#13#10 +
    '      rows (BuildBlankInsertLineContent); Ctrl/Alt block select'#13#10 +
    '      in content column unchanged.'#13#10 +
    '    Internal v2.1.7.18: Ctrl+Z / Ctrl+Y for autofill blocks'#13#10 +
    '      (Op=3 BatchKind=1); BAUT journal + merge/history tab;'#13#10 +
    '      RecordBatchInsertForUndo keeps blank-line count (no trim);'#13#10 +
    '      RestoreBatchInsertLinesFromUndo for redo of empty rows.'#13#10 +
    '    Internal v2.1.7.19: RestoreCsvModeAfterPostEdit after edit'#13#10 +
    '      reload (session CsvMode/CsvHideHeaderRow/CsvHasHeader);'#13#10 +
    '      LineLooksDelimiterOnly skips placeholder rows in CSV'#13#10 +
    '      header detect; EndRead uses restore not full re-detect.'#13#10 +
    '    Internal v2.1.7.20: batch delete refresh drops stale'#13#10 +
    '      temp.txt (MMF delete rebuilds ckpt only); ListView shows'#13#10 +
    '      correct lines without F5; recent files auto-remove missing'#13#10 +
    '      path (MainUnit tab + Welcome screen); uI18n autofill/BAUT.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.13  (2026-05-19)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Script engine, macro panel, and distribution:'#13#10 +
    '    Internal v2.1.7.13: ScriptEngine.py byte progress on RUNFILE'#13#10 +
    '      (PROGRESS: lines); overlay progress bar on GB+ files;'#13#10 +
    '      BeginScriptEngineProgress; lblDetail readable on blue'#13#10 +
    '      background; loading modal layout/cancel fixes (form Canvas).'#13#10 +
    '    Internal v2.1.7.14: Python/Tail example panels via TrText'#13#10 +
    '      (PY_MACRO_EX_*, SCRIPT_ENGINE_EXAMPLES_*); fix mojibake;'#13#10 +
    '      Regex AI didactic titles; uI18n procedure split for Delphi 7'#13#10 +
    '      constant limit (PythonMacroExamples + UndoSearchSession).'#13#10 +
    '    Internal v2.1.7.15: EnsureExecutableAvailable downloads'#13#10 +
    '      ScriptEngine.exe / ConsumerAI.exe / ConsumerRAG.exe from'#13#10 +
    '      hvogel.com.br when missing locally; i18n download messages.'#13#10 +
    '    Internal v2.1.7.16: Ctrl+Alt+E without a loaded file: switch to'#13#10 +
    '      tabReadFile before showing panel; CanFocus guard (no'#13#10 +
    '      EInvalidOperation on SetFocus).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.11  (2026-05-16)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Undo/Redo stability and confirmation:'#13#10 +
    '    Internal v2.1.7.11: async ApplyEditWithUndo + StartAsyncUndoRedo'#13#10 +
    '      (no RunEditWait on UI thread - fixes freeze on edit/undo/redo);'#13#10 +
    '      BeginReadSilent + FFreshFileRead preserves undo stack after edit;'#13#10 +
    '      CommitPendingEditUndoIfNeeded / CommitPendingUndoRedoIfNeeded;'#13#10 +
    '      RecordForUndo only after successful disk write (paste, etc.);'#13#10 +
    '      UndoRedoBusy guard while worker edit/undo is running.'#13#10 +
    '    Internal v2.1.7.12: MB_YESNO confirmation before undo/redo with'#13#10 +
    '      line-specific message (insert/edit/delete preview); uI18n'#13#10 +
    '      AddCommonTranslationsUndoSearchSession extended (11 languages).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.9  (2026-05-16)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Search, read-only session, and Undo/Redo (initial):'#13#10 +
    '    Internal v2.1.7.9: CurrentEffectiveFilePath for disk checks'#13#10 +
    '      (Ctrl+F/H, tail, split) when tab shows [READ ONLY]; ignore-case'#13#10 +
    '      search BMH shift table + F3 continues on same line; find-match'#13#10 +
    '      highlight in Content column; SessionBlocksMutation blocks replace'#13#10 +
    '      in read-only; undo stack for edit/insert/delete/paste/replace;'#13#10 +
    '      Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z (up to 100 levels).'#13#10 +
    '    Internal v2.1.7.10: uI18n undo/redo status, Found at line %d,'#13#10 +
    '      Use Ctrl+F first... (11 languages).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.7  (2026-05-12)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Split by Pattern / Regex (embedded tab - reliability + IA bar):'#13#10 +
    '    Internal v2.1.7.7: Hosted tab gains TComboBox cmbMode (equal'#13#10 +
    '      parts vs pattern/regex) + LblEqualParts/SpnEqualParts; fixes'#13#10 +
    '      access violation on Preview/Confirm (nil cmbMode); hosted'#13#10 +
    '      Confirm uses roSplit for regex split; memo examples anchor'#13#10 +
    '      no longer reserves a button row inside TScrollBox;'#13#10 +
    '      FSplitPatternMemoGuideDefH guard in ApplySplitPatternHostedMetrics.'#13#10 +
    '    Internal v2.1.7.8: Suggest examples with AI + Talk with AI as'#13#10 +
    '      standard TButton on fixed bottom bar (PnlBottom h=80), not'#13#10 +
    '      inside TScrollBox (reliable paint with AlphaSkins);'#13#10 +
    '      responsive widths on narrow bar; uI18n shorter AI memo section'#13#10 +
    '      titles + banner text; TrText keys Split / process mode: and'#13#10 +
    '      Number of parts: (11 languages).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.6  (2026-05-09)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Split by Pattern / Regex (embedded tab + AI gateway):'#13#10 +
    '    Internal v2.1.7.3: Preview on hosted Split-by-Pattern tab'#13#10 +
    '      (EnsureSplitByPatternTab); SplitByPatternTabPreviewClick'#13#10 +
    '      mirrors modal preview / VBScript sampling;'#13#10 +
    '      TMergeFilesDialogForm.BtnPreview.'#13#10 +
    '    Internal v2.1.7.4: uVBScriptRegex.pas (NormalizeRegex+'#13#10 +
    '      TryCompileVBScriptRegexPattern); AI reply appendix from'#13#10 +
    '      gateway: paste-ready normalized patterns + reject list'#13#10 +
    '      (uFastFileAIScreenHelp); FastFile.dpr.'#13#10 +
    '    Internal v2.1.7.5: AI_PROMPT_RULES_P3 (Regex: lines);'#13#10 +
    '      i18n AI_SPLIT_VALIDATION_*; docs sync.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.2  (2026-05-06)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Smooth loading overlay - cancel & worker cooperation:'#13#10 +
    '    - TBitBtn cancel (reliable clicks with AlphaBlend / layered'#13#10 +
    '      window); link-style caption (underline + accent colour);'#13#10 +
    '    - CancelRequested polled in read / edit / merge-delta /'#13#10 +
    '      replace-all loops; FinishThread paths on edit cancel;'#13#10 +
    '    - TrText(''Cancelling...'') wired for all 11 languages.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.1  (2026-05-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Smooth loading overlay - visuals & layout:'#13#10 +
    '    - Larger client (~760x720) clamped to primary work area'#13#10 +
    '      (SPI_GETWORKAREA); centered in usable desktop;'#13#10 +
    '    - Rounded corners: SetWindowRGN + rounded clip in FormPaint'#13#10 +
    '      + outline; region reapplied after show (posted message);'#13#10 +
    '    - Alpha fade-in (smoothstep; slower duration); spacing for'#13#10 +
    '      controls including cancel below progress bar.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.7.0  (2026-05-04)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Big Data / Ultra-Large File Architecture (16TB Support):'#13#10 +
    '    - "Zero Scan" mode implemented for instant file opening'#13#10 +
    '      (0 seconds) by safely bypassing dense indexing;'#13#10 +
    '    - Memory Airbag (Safe fallback at 2 Billion Lines) to'#13#10 +
    '      prevent Integer Overflow and protect OS memory limits;'#13#10 +
    '    - SWAR (SIMD Within A Register) counting engine throughput'#13#10 +
    '      restored and optimized to peak 1.4+ GB/s;'#13#10 +
    '    - Robust boolean toggle for Force Zero Scan Mode in View menu'#13#10 +
    '      with isolated backing fields bypassing skin rendering bugs;'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.74  (2026-05-01)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Script panel shortcuts hardened (all three macro memos):'#13#10 +
    '    Ctrl+C/Ctrl+Insert, Ctrl+V/Shift+Insert, Ctrl+A/Ctrl+T'#13#10 +
    '    now intercepted pre-VCL through Application.OnMessage,'#13#10 +
    '    with safe WM_COPY/WM_PASTE/EM_SETSEL routing;'#13#10 +
    '  Script engine throughput for very large files improved:'#13#10 +
    '    bigger protocol batches, bulk OUT append in Delphi,'#13#10 +
    '    reduced protocol chatter in RUNFILE mode and rebuilt'#13#10 +
    '    ScriptEngine.exe distribution artifact;'#13#10 +
    '  Python Macro panel UX: dedicated title bar at panel top'#13#10 +
    '    (matching Script Examples), scope radio buttons now'#13#10 +
    '    auto-sync with Select/checked-line mode;'#13#10 +
    '  ConsumerAI stability: fixed invalid thread identifier'#13#10 +
    '    crash on panel close/app shutdown by owning reader'#13#10 +
    '    thread lifetime explicitly (safe WaitFor + FreeAndNil).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.73  (2026-04-28)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Compare/Merge range-diff reliability: added lookahead'#13#10 +
    '    window during line-range reads and trimmed final rows to'#13#10 +
    '    requested interval, preventing false tail mismatches'#13#10 +
    '    after early insert/delete shifts (WinMerge-aligned view);'#13#10 +
    '  Merge apply safety: when copying/inserting from a row with no'#13#10 +
    '    direct target anchor (line 0), otInsert now appends at EOF'#13#10 +
    '    instead of silently skipping, preserving right->left/left->right'#13#10 +
    '    apply behavior in edge cases; docs/version synchronized.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.72  (2026-04-28)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Compare/Merge diff (tabMerge): btnRunDiff now uses a'#13#10 +
    '    dedicated worker (TDiffWorkerThread), keeping UI responsive'#13#10 +
    '    with smooth progress updates via WM_FF_DIFF_PROGRESS_FLUSH;'#13#10 +
    '  Merge apply internal flow: added RunDiffSync for immediate'#13#10 +
    '    post-apply validation paths, while user-triggered diff stays'#13#10 +
    '    asynchronous and non-blocking;'#13#10 +
    '  Large-file strategy: dynamic force-range threshold per run'#13#10 +
    '    (computed from input file sizes), plus explicit fast-mode'#13#10 +
    '    checkbox in Diff tab and auto caption (MB threshold);'#13#10 +
    '  Diff UX/visual semantics: corrected insert/delete colors'#13#10 +
    '    (yellow = added on right, red = removed on left), legend'#13#10 +
    '    aligned, and missing-side line numbers rendered blank'#13#10 +
    '    (no more caption 0);'#13#10 +
    '  Menu organization: CSV options moved to View menu'#13#10 +
    '    (CSV/Column mode + header-as-data), consistent with View'#13#10 +
    '    behavior and i18n updates.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.71  (2026-04-27)  (previous)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Batch delete (selected lines): moved heavy paths to worker'#13#10 +
    '    threads with responsive wait loop (MsgWait + ProcessMessages),'#13#10 +
    '    keeping UI responsive and progress repainting while running;'#13#10 +
    '  Delete progress overlay: removed duplicated black detail text;'#13#10 +
    '    initial paint is forced before loop; progress now uses'#13#10 +
    '    thread-safe PostProgressFromWorker updates;'#13#10 +
    '  OCP restore: TReadFileThread behavior preserved; no functional'#13#10 +
    '    edits in the existing class. Added extension path with'#13#10 +
    '    TReadFileThreadNoUI + BeginReadSilent for delete reload only;'#13#10 +
    '  Compare / merge + session history moved from modal to tab:'#13#10 +
    '    hosted in tabMerge (embedded mode), reusing same components'#13#10 +
    '    and logic; menu action now opens/focuses the tab;'#13#10 +
    '  i18n/UI alignment: tabMerge caption bound to TrText key already'#13#10 +
    '    translated in 11 languages; menu/help labels updated to tab'#13#10 +
    '    wording; docs/changelog/version synchronized.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.70  (2026-04-26)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Recent Files startup tab: fixed startup visibility path'#13#10 +
    '    (ShowTab) and added runtime launcher in View menu;'#13#10 +
    '  Recent Files visual refresh: softer row selection (no full'#13#10 +
    '    blue highlight), cleaner grid rendering and better sizing;'#13#10 +
    '  Recent Files i18n: tagline + Close button + new menu item'#13#10 +
    '    translated for 11 languages; PT/PT-PT accents fixed in'#13#10 +
    '    startup checkbox text;'#13#10 +
    '  Tab ordering: when startup screen is enabled, Recent Files'#13#10 +
    '    stays as the first tab; when disabled, rule is not forced.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.69  (2026-04-25)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Tail/Follow: pause/resume flow hardened with pending'#13#10 +
    '    new-lines counter and highlight of appended rows;'#13#10 +
    '  Word-wrap + Select mode: fixed navigation drift in'#13#10 +
    '    Ctrl+G / F2 / Shift+F2 when checklist is active;'#13#10 +
    '    bookmark jumps now center target context and clamp'#13#10 +
    '    filtered offsets correctly;'#13#10 +
    '  Bookmark visuals: blue-row highlight with white text'#13#10 +
    '    applied in ListView and checklist owner-draw;'#13#10 +
    '  i18n: new Tail/Bookmark runtime status/messages added'#13#10 +
    '    for all 11 languages; docs/version synced.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.68  (2026-04-24)'#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  Compare/Merge UI: Right-click popup rules refined:'#13#10 +
      '    equal (green) rows show Copy selection + Go to line only;'#13#10 +
      '    differing rows show only the appropriate Apply direction;'#13#10 +
      '  Compare/Merge UI: OwnerData fix - popup + custom draw now use'#13#10 +
      '    diff row source (no false-green rows / wrong menu on full-file diff);'#13#10 +
      '  i18n: "There is no difference between the files." accented'#13#10 +
      '    translations restored (11 languages);'#13#10 +
      '  UX: Esc closes the app when pgMain is hidden.'#13#10 +
      ''#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  v2.1.6.67  (2026-04-22)'#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  Apply Merge UI: Context menus with smart row selection;'#13#10 +
      '  Apply Merge UI: Fixed missing/truncated EOF lines bug;'#13#10 +
      '  Apply Merge UI: Fixed double-encoding charset issues;'#13#10 +
      '  Apply Merge UI: Suppressed listview flickering completely;'#13#10 +
      ''#13#10 +
      '-------------------------------------------------------'#13#10 +
      '  v2.1.6.66  (2026-04-20)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Apply Merge UI: Re-engineered O(N) backward flow'#13#10 +
    '    to avoid recursive padding loops & UI freezes;'#13#10 +
    '  Progress UI: Render throttle stops AlphaControls GDI'#13#10 +
    '    exhaustion (MemDC) on transparent overlay;'#13#10 +
    '  Overlay: Alpha-bitmap fix for SmoothLoading logo;'#13#10 +
    '  Safety: File streams release to avoid Sharing Violations.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.65  (2026-04-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  APPLICATION_VERSION + CHANGELOG + HISTORY + F1 help:'#13#10 +
    '    two new TrText help lines (11 langs) for session'#13#10 +
    '    history reload (progress phases + multitasking).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.64  (2026-04-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  uSmoothLoading: ShowLoading(msg, AStayOnTop); history'#13#10 +
    '    reload uses ShowLoading(..., False) + BringToFront;'#13#10 +
    '  uCompareMergeUI: HistPumpUIMessagesAndYield (PM + MsgWait),'#13#10 +
    '    SyncApply chunks 12/12, worker Sleep in char loops,'#13#10 +
    '    SetSmoothProgress Sleep(2); D7 MsgWait THandle var fix.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.63  (2026-04-18)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Session history reload: progress 0..54% worker (tail,'#13#10 +
    '    filter, preview, color scan) then 55..99% UI apply;'#13#10 +
    '    PostMessage flush throttle; tail progress every 256KB.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.62  (2026-04-16)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  uI18n AddCommonTranslationsCompareMerge: Set11 assigns'#13#10 +
    '    every Compare/Merge dialog TrText key in all 11 langs'#13#10 +
    '    (no English fallback for ES/FR/DE/IT/PL/RO/HU/CZ);'#13#10 +
    '    PT-BR mesclar wording; extras block unchanged; guide'#13#10 +
    '    DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md;'#13#10 +
    '  CHANGELOG_IMPLEMENTACOES.md + UnConsts.APPLICATION_VERSION.'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.61  (2026-04-15)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Compare/Merge + session history modal (uCompareMergeUI):'#13#10 +
    '    diff + history tabs, lvHistFile journal colors, ctx menus,'#13#10 +
    '    ExecuteModal->RefreshFile, TabSheetDiff/ui fixes; first'#13#10 +
    '    wave of 11-lang strings for preview/context (see .62).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.60  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Host bump: CHANGELOG + UnConsts + HISTORY sync (.58-.59'#13#10 +
    '    deliverables unchanged in entries below).'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.59  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Status-bar file details: BuildLoadedFileDetailsText'#13#10 +
    '    (path, disk size, file times, lines/chars/max offset,'#13#10 +
    '    detected + list-view encoding, RO/WW/tail/segmented/'#13#10 +
    '    filter flags, list mode, status read summary);'#13#10 +
    '    ShowDetailsPopup 560x440, Tr(File details), ESC'#13#10 +
    '    (KeyPreview+DetailsPopupKeyDown), OK Default; i18n'#13#10 +
    '    for detail labels + Text copied to clipboard! (11 langs)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.58  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  View menu &View (Alt+V): Word wrap, Select, Zoom in/out'#13#10 +
    '    (Ctrl+Num+/-), bookmarks (from Options); Select removed'#13#10 +
    '    from Options; ListView popup View mirrors menu order;'#13#10 +
    '    Tools: EnsureToolsPopupBookmarkExtras between WW and RO;'#13#10 +
    '    i18n &View + zoom menu/help (11 langs); F1 Alt+V'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.57  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n (11 langs): Line-segmented &mode (heavy ops) menu'#13#10 +
    '    caption; F1 help line Ctrl+Alt+R (read-only);'#13#10 +
    '    FastFile - Version History memo title; Dialogs submenu;'#13#10 +
    '    pt-PT Version History keys; title-bar Tools extra-line'#13#10 +
    '    uses Tr(titlebar.tools)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.56  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Shortcuts: Ctrl+Alt+R = read-only session; Ctrl+R ='#13#10 +
    '    recent files only; Ctrl+W = word wrap (Ctrl alone);'#13#10 +
    '  ListView popup: Tail + Export filtered + read-only icon;'#13#10 +
    '    Tools menu items carry same shortcuts as Options'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.55  (2026-04-14)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Title-bar Tools (PopupMenu1): dynamic FastFile block'#13#10 +
    '    (word wrap, read-only, segmented, tail, filter, export);'#13#10 +
    '    FMenuBitmapImages on PopupMenu1 + PopupDialogs + icon map;'#13#10 +
    '    segmented mode in Options + list popup + Tools; OnPopup sync'#13#10 +
    '  Removed menu entries: Allow animation, Change BidiMode'#13#10 +
    '    (demo + Tools; Bidi remains on toolbar); FormShow re-sync'#13#10 +
    '    segmented checkbox -> menu checkmarks'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.54  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Line-segmented batch delete (same checkbox as Replace All):'#13#10 +
    '    merge temp + atomic rename; hint updated (i18n)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.53  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Optional line-segmented Replace All (toolbar checkbox,'#13#10 +
    '    INI SegmentHeavyOps): temp parts by index, merge +'#13#10 +
    '    atomic rename; boundary-match caveat in confirm + hint'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.52  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Large-file safety: tail-append reads growth in 64MB'#13#10 +
    '    chunks (GetMem/Read Integer limit); filter bitset'#13#10 +
    '    refuses allocation > MaxInt lines; MMF PtrAt uses'#13#10 +
    '    PAnsiChar pointer math'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.51  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  i18n: Polish/Czech Find�Replace + Duplicate line'#13#10 +
    '    strings corrected (CP1250 letters)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.50  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Options + list popup: Duplicate line (after Insert) +'#13#10 +
    '    Ctrl+Shift+U; i18n menu caption D&uplicate line'#13#10 +
    '  Find & Replace dialog: button mnemonics (Alt+N/R/L/C)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.48�49  (2026-04-13)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  Filter view: prefix / contains / VBScript regex + case Q;'#13#10 +
    '    filter build progress (lines); regex COM CoInit/Uninit on worker'#13#10 +
    '  Find: backward byte progress; Esc cancels in-flight search'#13#10 +
    '  Replace-all: streaming overlay (bytes + replacements); confirm text'#13#10 +
    '  Encoding combo [Save note]; line preview cap 256KB + dual-byte footer'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.47  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Session read-only toggle (Options + list popup):'#13#10 +
    '    guards edit / delete / merge-delta / merge-files /'#13#10 +
    '    split-by-files-lines + replace + undo-redo'#13#10 +
    '  - View encoding combo hint: default vs forced decode note'#13#10 +
    '  - Long line preview: truncation footer with total bytes'#13#10 +
    '  - i18n (11 langs) for new strings'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.46  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - CHANGELOG_IMPLEMENTACOES.md + APPLICATION_VERSION'#13#10 +
    '    (UnConsts) aligned with this in-app Version History'#13#10 +
    '  - i18n (11 langs): help memo rows (Ctrl+Shift+G /'#13#10 +
    '    Filter Ctrl+L / FILTER section note), filter status'#13#10 +
    '    (cleared / filtering / Filter n/N), Ready, line-not-'#13#10 +
    '    in-filter message; PL accelerator on Go to byte offset'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.45  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Filter / Grep: after typing needle, MessageDlg picks'#13#10 +
    '    line-prefix match vs contains-anywhere (view only)'#13#10 +
    '  - TFilterThread: FMatchMode (fmmContains / fmmPrefix);'#13#10 +
    '    StartFilter passes mode from DoFilterDialog'#13#10 +
    '  - gotoLine: Application.MessageBox uses TrText when'#13#10 +
    '    requested real line is absent from active filter'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.44  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Go to byte offset: 1-based file byte (+ $ hex);'#13#10 +
    '    Line0BasedForFileByte1Based binary search on index'#13#10 +
    '  - Edit menu + ListView popup item + Ctrl+Shift+G;'#13#10 +
    '    GetLineStartOffset parameter widened to Int64'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.43  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - About FastFile: Developed by + Hamden Vogel; Contact'#13#10 +
    '    email label (i18n); Build time: TrText; lblDevelopedBy,'#13#10 +
    '    taller pnlTop / pnlGNU layout (UnFormAboutFF)'#13#10 +
    '  - Help (F1): removed trailing Delphi 7 tagline from'#13#10 +
    '    HELP_TEXT; placeholders replaced with TrText rows'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.42  (2026-04-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - i18n: stale-file prompt, find progress, disk/rename/'#13#10 +
    '    replace-all safety messages and UnUtils atomic-save'#13#10 +
    '    errors translated in all 11 application languages'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.41  (2026-04-11)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Read tab: snapshot size+mtime after load; invalidate'#13#10 +
    '    on close streams so external edits are detectable'#13#10 +
    '  - EnsureOpenFileNotStaleForMutate before edit / replace /'#13#10 +
    '    replace-all / merge-delta / undo-redo mutating paths'#13#10 +
    '  - Find in file: status bar shows byte progress'#13#10 +
    '    (Searching ... / total) during TFindInFileThread'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.40  (2026-04-11)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - UnUtils: GetFileSizeAndWriteTime, SameFileSizeAndWriteTime,'#13#10 +
    '    TryRenameTempOverTarget (temp + retries + backup rename),'#13#10 +
    '    uDiskSpaceCheck + UnUtils.VolumeFreeBytes (GetDiskFreeSpaceExA)'#13#10 +
    '  - uSmoothLoading: disk free check before heavy writer'#13#10 +
    '    threads; atomic finalize rename; REPLACE_ALL_MATCH_LIMIT'#13#10 +
    '    (5M) with cancel / limit-hit paths; TMergeDeltaThread'#13#10 +
    '    try/except/finally structure fix (D7 compile)'#13#10 +
    '  - RegressionTests: test_snapshot_logic.py + README note'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.39  (2026-04-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Split into equal parts - finish UX + i18n:'#13#10 +
    '    Dialogs.ShowMessage summaries (success / failure /'#13#10 +
    '    interrupted) via SplitEqualParts.* Format strings,'#13#10 +
    '    all 11 languages; mmTimer log line (parts + folder)'#13#10 +
    '  - Split-equal modal: larger client height, hint label'#13#10 +
    '    with WordWrap + fixed height + left alignment'#13#10 +
    '  - Menu accelerators PT/ES/PT-PT/RO: &iguais / &iguales /'#13#10 +
    '    &egale (fixes duplicate leading i in captions)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.38  (2026-04-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Split-equal algorithm: approximate equal byte targets'#13#10 +
    '    snapped to next LF (no trailing half-lines); outputs'#13#10 +
    '    <name>.partNNN<ext> beside source; overwrite guard'#13#10 +
    '  - Pre-checks: empty file, open/share test, CountLinesInFile'#13#10 +
    '    >= part count, CloseFileStreams when splitting the'#13#10 +
    '    file currently open in Read tab'#13#10 +
    '  - SpinEdit value -> Integer(SpnParts.Value) (D7 type fix)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.37  (2026-04-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - New TSplitEqualPartsThread (`uSmoothLoading`):'#13#10 +
    '    background split with TfrmSmoothLoading progress'#13#10 +
    '  - Options menu + runtime modal (merge-style shell):'#13#10 +
    '    source TsFilenameEdit + parts 2..1000 + i18n labels'#13#10 +
    '  - Initial uI18n keys for dialog, loading text, errors'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.36  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Merge-lines delta modal (`uDeltaEditor`): layout'#13#10 +
    '    uses real button widths so Content never overlaps'#13#10 +
    '    Add/Update; BringToFront after resize/show; wider'#13#10 +
    '    Add/Update + Delete buttons'#13#10 +
    '  - ConsumerAI_LanceDB: large row-spec fetch uses temp'#13#10 +
    '    table + JOIN instead of huge IN(...) lists'#13#10 +
    '  - Bridge merge tokens: SQL fetch cap presets, page'#13#10 +
    '    size presets in pagination, INSERT position 0'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.35  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI_LanceDB query loop: single SELECT/WITH'#13#10 +
    '    without LIMIT prompts for max rows (memory cap)'#13#10 +
    '    with optional full-SELECT DB pagination/export'#13#10 +
    '    when the cap is hit'#13#10 +
    '  - `paginate_results` extended with `sql_derived_select`'#13#10 +
    '    (LIMIT/OFFSET on arbitrary subquery) + COPY export'#13#10 +
    '  - Paginated row text truncated at PAGINATE_MAX_ROW_CHARS'#13#10 +
    '    to protect bridge/terminal buffers'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.34  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI_LanceDB search & replace: COUNT(*) instead'#13#10 +
    '    of loading all matches; preview capped at 10 rows'#13#10 +
    '  - Paginated match view uses DuckDB WHERE + LIMIT/OFFSET'#13#10 +
    '    (`sql_where`) + filtered COPY export'#13#10 +
    '  - `replace_in_table` counts matches via SQL (no giant DF)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.33  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI_LanceDB bridge: interactive pagination'#13#10 +
    '    (`BRIDGE_MERGE_PAGINATE` + optional page-number'#13#10 +
    '    buttons); paginate prompt uses page-size presets'#13#10 +
    '  - Shared helpers `_build_search_where_clause`,'#13#10 +
    '    `export_sql_filtered_to_txt`, doc updates in'#13#10 +
    '    `BRIDGE_DELPHI_INPUT_MAP`'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.32  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI panel cleanup after UI experiments:'#13#10 +
    '    manual input flow kept as the single active path'#13#10 +
    '  - Awaiting-input layout tuned with taller input row'#13#10 +
    '    and stable input/status sizing in Delphi panel'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.31  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Prompt protocol hardening in Delphi bridge:'#13#10 +
    '    empty PROMPT falls back to last valid prompt'#13#10 +
    '  - Bridge transcript/status flow cleaned up and noisy'#13#10 +
    '    diagnostic lines removed from runtime flow'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.30  (2026-04-06)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI stdout reader now flushes partial'#13#10 +
    '    prompt text without trailing LF via PeekNamedPipe'#13#10 +
    '  - Fixes Python input(...) prompts waiting on stdin'#13#10 +
    '    before Delphi receives prompt metadata'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.29  (2026-04-05)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI_LanceDB bridge input updates:'#13#10 +
    '    BridgeConsole.input now routes through bridge_input'#13#10 +
    '  - Frozen-mode header prompt uses bridge-aware input'#13#10 +
    '    and option extraction improved for quoted tokens'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.28  (2026-04-05)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Delphi prompt pipeline refactor:'#13#10 +
    '    centralized ApplyPromptUI and prompt-state helpers'#13#10 +
    '  - Delphi 7 compatibility hardening for prompt parsing'#13#10 +
    '    and manual ConsumerAI input session handling'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.27  (2026-04-04)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI bridge groundwork in Delphi panel:'#13#10 +
    '    prompt metadata parsing and per-prompt state sync'#13#10 +
    '  - Manual prompt/response workflow prepared for'#13#10 +
    '    bridge-driven interaction inside the AI panel'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.26  (2026-04-04)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - AI panel header overflow fix:'#13#10 +
    '    close/export/clear/restart widths + title label'#13#10 +
    '    prevent overlap on right-aligned controls'#13#10 +
    '  - Send button now toggles by input content via'#13#10 +
    '    OnChange (empty input keeps Send disabled)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.25  (2026-04-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI migrated from direct Groq SDK'#13#10 +
    '    calls to AWS Lambda proxy (same session model as'#13#10 +
    '    ConsumerAI.py; no local API key in EXE)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.24  (2026-04-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - User-facing branding cleanup:'#13#10 +
    '    startup/status texts cleaned up'#13#10 +
    '  - ConsumerAI_Session_Debug.log writes disabled and'#13#10 +
    '    new i18n keys added for session status strings'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.23  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI onefile Windows hotfix:'#13#10 +
    '    removed PyInstaller --strip after it broke _ssl /'#13#10 +
    '    libssl runtime needed by Groq HTTPS requests'#13#10 +
    '  - Build revalidated with standalone EXE startup and'#13#10 +
    '    argparse help execution after packaging changes'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.22  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ConsumerAI onefile slimming pass:'#13#10 +
    '    pruned nonessential PyInstaller payloads while'#13#10 +
    '    keeping standalone distribution'#13#10 +
    '  - Excluded heavy optional ML/test stacks to cut EXE'#13#10 +
    '    size substantially and kept required pandas/pyarrow'#13#10 +
    '    startup dependencies for frozen mode'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.21  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Split by files thread bugfix: output path now uses'#13#10 +
    '    dedicated FOutputDir (source path no longer reused)'#13#10 +
    '  - Callers updated to pass source file and output dir'#13#10 +
    '    as separate parameters in split workflows'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.20  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Split by lines execution implemented with range'#13#10 +
    '    validation and output file name checks'#13#10 +
    '  - tabSplitFileShow now synchronizes spin limits with'#13#10 +
    '    current indexed line count'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.19  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - I/O micro-optimizations in indexed read paths:'#13#10 +
    '    reduced seek/read calls and lower heap allocations'#13#10 +
    '  - ListView data load path adjusted for faster response'#13#10 +
    '    on large files'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.18  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - New keyboard shortcuts for navigation:'#13#10 +
    '    Ctrl+Home = go top, Ctrl+End = go bottom'#13#10 +
    '  - Updated hints/help text to keep shortcut discoverability'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.17  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Split by files flow integrated in Src build:'#13#10 +
    '    btnExecuteSplitFileByFiles now launches TSplitFileThread'#13#10 +
    '  - Dataset validation and entry mapping added for batch'#13#10 +
    '    split execution'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.16  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - gotoLine visual selection hardening:'#13#10 +
    '    selection mark + ensure visible for virtual ListView'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.15  (2026-04-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Search UX update: btnSearch now executes direct lookup'#13#10 +
    '    from edtSearch text (no InputBox dependency)'#13#10 +
    '  - Enter key in search field now follows search action'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.14  (2026-04-01)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - AI panel i18n polish for Brazilian and European Portuguese'#13#10 +
    '    runtime texts:'#13#10 +
    '    normalized accents in ANSI-safe format (#nnn)'#13#10 +
    '  - Added explicit translation key for Send in all'#13#10 +
    '    supported languages and reapplied at panel show'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.13  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - AI quick action buttons repaint hotfix:'#13#10 +
    '    migrated to TsButton + forced realign/invalidate'#13#10 +
    '    to avoid overlapped captions before hover'#13#10 +
    '  - Transcript right-click popup added:'#13#10 +
    '    Select all / Copy / Export transcript'#13#10 +
    '  - AI panel strings fully localized through TrText'#13#10 +
    '    across all supported runtime languages'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.12  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Hotfix: resolved '#39'Control has no parent window'#39''#13#10 +
    '    by reordering dynamic control parenting sequence'#13#10 +
    '    (Parent assigned before handle-sensitive setup)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.11  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Flicker reduction when showing/hiding AI panel:'#13#10 +
    '    WM_SETREDRAW batching + DisableAlign/EnableAlign'#13#10 +
    '    around ListView/splitter/layout updates'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.10  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - New dynamic AI side panel opened by AI Chat'#13#10 +
    '    button and split beside ListView using splListview'#13#10 +
    '  - Close button added to hide the panel on demand'#13#10 +
    '  - Select mode checklist now parents to pnlCenter so'#13#10 +
    '    it shares space correctly with the AI side panel'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.9  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Menu icon mapping fine-tuning:'#13#10 +
    '    - About FastFile now uses the same icon as Help'#13#10 +
    '    - Exit now uses Exit.bmp explicitly'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.8  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Menu and popup icons remapped to:'#13#10 +
    '    Images\\ImagesII\\glyphspro\\glyphspro\\16x16\\hot'#13#10 +
    '  - Semantic bind updated for main menu and shared'#13#10 +
    '    ListView/CheckListBox right-click popup'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.7  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Hotfix: invalid image size resolved by normalizing'#13#10 +
    '    loaded BMPs to 16x16 before adding to TImageList'#13#10 +
    '  - StretchBlt-based resize with clFuchsia mask preserved'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.6  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Runtime bitmap menu infrastructure added:'#13#10 +
    '    FMenuBitmapImages + FMenuIconIndexByName'#13#10 +
    '  - Dynamic icon lookup by file name with fallback indices'#13#10 +
    '  - ResolveMenuBitmapDir now searches parent folders and'#13#10 +
    '    supports runtime rebuild on ApplyConfigs'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.5  (2026-03-31)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Merge files: line-range copy mode enabled'#13#10 +
    '    (checkbox, From line / To line numeric inputs)'#13#10 +
    '  - 13 validation paths: empty fields, invalid number,'#13#10 +
    '    min value, range order, file not found,'#13#10 +
    '    line count exceeded, rename/replace failures'#13#10 +
    '  - CountLinesInFile() helper for pre-validation'#13#10 +
    '  - TMergeFilesThread extended: FFromLine/FToLine,'#13#10 +
    '    GetSourceLineOffset() skips to range start'#13#10 +
    '  - Full i18n: 19 keys x 11 languages (209 entries)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.4  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - comboViewEncoding added as child inside last'#13#10 +
    '    status bar panel (Notepad++ style)'#13#10 +
    '  - Options: DEFAULT (detected) / UTF-8 / ANSI /'#13#10 +
    '    UTF-16 LE / UTF-16 BE'#13#10 +
    '  - LayoutViewEncodingCombo repositions on resize,'#13#10 +
    '    show, and AlphaSkins skin change'#13#10 +
    '  - HookedStatusBarWndProcForCombo intercepts'#13#10 +
    '    CBN_CLOSEUP for skin compatibility'#13#10 +
    '  - Hint shows detected encoding + current view mode'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.3  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - New unit uTextEncoding.pas: BOM detection +'#13#10 +
    '    statistical heuristic across first 16 KB'#13#10 +
    '  - GetLineContent: UTF-8 to Unicode to CP_ACP'#13#10 +
    '    conversion for correct Delphi 7 ANSI rendering'#13#10 +
    '  - ANSI/Latin-1 fallback for non-UTF-8 files'#13#10 +
    '  - MessageBoxW in line editor for Portuguese diacritics'#13#10 +
    '    in ANSI host'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.2  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - uLineEditor: Yes/No confirmation dialog before'#13#10 +
    '    applying insert / edit / delete operations'#13#10 +
    '  - Dialog describes operation type and target line'#13#10 +
    '  - Default button is No (MB_DEFBUTTON2) to prevent'#13#10 +
    '    accidental line modifications'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.6.1  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Export fix: IndexFileLineCount (total indexed)'#13#10 +
    '    replaces virtual Items.Count as line limit'#13#10 +
    '  - Index offsets wrapped with Abs() for negative-'#13#10 +
    '    offset segment compatibility'#13#10 +
    '  - Export progress overlay synced to IndexFileLineCount'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.6  (2026-03-30)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Visual word wrap in Content column (DT_WORDBREAK)'#13#10 +
    '    without file re-index (FastWordWrapAtivo remains False)'#13#10 +
    '  - Row height enlarged via FWordWrapRowImages dummy'#13#10 +
    '    TImageList - no side effects on other columns'#13#10 +
    '  - Search highlight suspended in word-wrap draw mode'#13#10 +
    '    (conflicts with multi-line custom draw avoided)'#13#10 +
    '  - Ctrl+W shortcut toggles word wrap checkbox'#13#10 +
    '  - Ctrl+R: missing MRU path auto-removed from list'#13#10 +
    '    and mru_files.ini with friendly user message'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.9  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - New Merge files workflow (source into destination):'#13#10 +
    '    beginning, after destination line, or end of file'#13#10 +
    '  - Dedicated merge modal with validations, Confirm/Cancel,'#13#10 +
    '    ESC close, source picker, and in-window drag and drop'#13#10 +
    '  - Merge now runs in background thread with smooth loading'#13#10 +
    '    progress and automatic destination reload after finish'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.8  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Hotfix: removed false lock on destination file during'#13#10 +
    '    pre-validation (share mode adjusted)'#13#10 +
    '  - Hotfix: closes internal read streams before merge to'#13#10 +
    '    avoid self-lock from the main screen'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.7  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Hotfix: runtime merge modal now uses CreateNew to avoid'#13#10 +
    '    missing resource/DFM exception'#13#10 +
    '  - Drag and drop isolated to merge modal lifecycle only,'#13#10 +
    '    without impacting existing main-window drag and drop'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.6  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - About FastFile updated to use UnConsts metadata:'#13#10 +
    '    APPLICATION_NAME, APPLICATION_FULLNAME, and'#13#10 +
    '    APPLICATION_DEVELOPER'#13#10 +
    '  - About version line now shows architecture suffix:'#13#10 +
    '    vX.X.X.X  (32-bit/64-bit) based on runtime bitness'#13#10 +
    '  - Contact email added with mailto action and label'#13#10 +
    '    layout alignment fix (no overlap)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.5  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - About modal caption now uses same i18n key as'#13#10 +
    '    toolbar/menu (toolbar.about_fastfile)'#13#10 +
    '  - Splash / More info close button moved from hardcoded'#13#10 +
    '    text to TrText('#39'Close'#39')'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.4  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - ESC shortcut behavior improved: closes active tabs'#13#10 +
    '    (Read File / Find Files) when key is not consumed'#13#10 +
    '    by filter or selection context'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.3  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - AlphaHints fallback changed from technical component'#13#10 +
    '    names to user-friendly guidance text'#13#10 +
    '  - Centralized simple hint builder for generic controls'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.2  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Contextual hint coverage expanded for Read, Find Files,'#13#10 +
    '    and Split File areas'#13#10 +
    '  - Added/adjusted English and Portuguese hint entries for'#13#10 +
    '    controls and actions in these tabs'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.5.1  (2026-03-29)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Portuguese (Brazil) text review for accent/terminology consistency'#13#10 +
    '    across i18n entries and hint phrases'#13#10 +
    '  - English wording harmonized for Find/Search related labels'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.5  (2026-03-28)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Language pack updated:'#13#10 +
    '    removed Japanese; added Polish, Portuguese (Portugal),'#13#10 +
    '    Romanian, Hungarian, and Czech'#13#10 +
    '  - UI localization coverage expanded (menus, tabs, controls,'#13#10 +
    '    tabFindFiles, tabSplitByLines, toolbar captions)'#13#10 +
    '  - Runtime hardcoded captions moved to TrText (dialogs,'#13#10 +
    '    progress status, help/title captions, shortcut hints)'#13#10 +
    '  - Startup language now follows Windows default when INI'#13#10 +
    '    language is empty'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.4.3  (2026-03-28)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Romanian/Czech critical captions stabilized for Delphi 7'#13#10 +
    '    ANSI rendering (File/Options/Help and Find Files area)'#13#10 +
    '  - Added missing key mapping for Read toolbar caption'#13#10 +
    '    (btnShowTabReadFile)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.4.2  (2026-03-28)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Exact-key i18n fixes for TrText variants with trailing'#13#10 +
    '    spaces/punctuation (e.g., Shortcut: , Replaced on line )'#13#10 +
    '  - i18n initialization refactored into helper blocks to avoid'#13#10 +
    '    Delphi 7 local constants limits'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.4.1  (2026-03-27)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - French menu caption encoding cleaned up'#13#10 +
    '  - Syntax and char-code literal stabilization in translation'#13#10 +
    '    tables'#13#10 +
    '  - Full translation QA pass across menu/tab/button surfaces'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.4  (2026-03)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Internationalization framework (i18n):'#13#10 +
    '    English and Portuguese (Brazil)'#13#10 +
    '  - Dynamic main menu rebuild on language switch'#13#10 +
    '  - Language preference persisted to INI file'#13#10 +
    '  - Encoding combo: DEFAULT / UTF-8 / ANSI / UTF-16'#13#10 +
    '  - Zoom combo added to status bar'#13#10 +
    '  - Runtime language change without restart'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.3  (2026-02)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Smooth loading architecture (overlapped I/O thread)'#13#10 +
    '  - Word wrap with smooth horizontal scroll'#13#10 +
    '  - Bookmarks: toggle, next, previous, clear all'#13#10 +
    '  - Go to line dialog (Ctrl+G)'#13#10 +
    '  - Status bar: line / column / encoding panels'#13#10 +
    '  - Column-block selection mode'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.2  (2026-01)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Delta File Editor'#13#10 +
    '  - Export dialog (ranges and individual lines)'#13#10 +
    '  - Find in Files (Ctrl+Shift+F)'#13#10 +
    '  - Merge lines feature (Ctrl+Shift+M)'#13#10 +
    '  - AI Consumer integration'#13#10 +
    '  - Recent files list (Ctrl+R)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.1  (2025-12)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Find & Replace dialog (Ctrl+H)'#13#10 +
    '  - Insert / Edit / Delete line operations'#13#10 +
    '  - Batch delete with checkbox list (Ctrl+Shift+S)'#13#10 +
    '  - Split Files: by line count and by file size'#13#10 +
    '  - Tail / Follow mode (Ctrl+T)'#13#10 +
    '  - Filter / Grep mode (Ctrl+L)'#13#10 +
    '  - Undo / Redo (Ctrl+Z / Ctrl+Y)'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.1.0.0  (2025-10)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Memory-Mapped File (MMF) backend for large files'#13#10 +
    '  - Multi-encoding detection: BOM/heuristics,'#13#10 +
    '    UTF-8, ANSI, UTF-16 LE/BE'#13#10 +
    '  - AlphaSkins theming support'#13#10 +
    '  - BidiMode support'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v2.0.0  (2025-08)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Virtual ListView for files exceeding physical'#13#10 +
    '    memory - O(1) scroll regardless of file size'#13#10 +
    '  - Drag & Drop file opening'#13#10 +
    '  - Line-number gutter'#13#10 +
    ''#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  v1.x  (2024 - 2025)'#13#10 +
    '-------------------------------------------------------'#13#10 +
    '  - Initial release: FileReadThread component'#13#10 +
    '  - Basic indexed file reading with progress'#13#10 +
    '  - ANSI and basic text file support'#13#10 +
    ''#13#10 +
    '======================================================='#13#10;

implementation

end.

