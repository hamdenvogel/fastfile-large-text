# FastFile Professional

**Professional high-performance text file editor for large files — Delphi 7 / Win32**

> Edition: **Professional** — FastFile is a professional-grade product for production-size data.  
> Version: **`3.0.5.232`** — **FastFile Professional 3.0.5** (14 UI languages; AI agent on files with SQL / natural language and reviewed proposals; anonymize data; session-history event details; custom PPI)  
> Developer: Hamden Vogel  
> Copyright © 2025–2026. All rights reserved.

---

## Table of Contents

1. [Overview](#overview)
2. [Key design principles](#key-design-principles)
3. [Building the project](#building-the-project)
4. [Project structure](#project-structure)
5. [Core units reference](#core-units-reference)
6. [Threading model](#threading-model)
7. [File indexing and MMF](#file-indexing-and-mmf)
8. [Open mode and Zero Scan](#open-mode-and-zero-scan)
9. [Atomic write pattern](#atomic-write-pattern)
10. [Segmented heavy operations](#segmented-heavy-operations)
11. [Session history journal](#session-history-journal)
12. [Compare / Merge and diff engine](#compare--merge-and-diff-engine)
13. [Internationalization](#internationalization)
14. [Files on disk](#files-on-disk)
15. [INI configuration keys (ASkin.ini)](#ini-configuration-keys-askinini)
16. [Async log](#async-log)
17. [AI Chat plugins (ConsumerAI / ConsumerRAG)](#ai-chat-plugins-consumerai--consumerrag)
18. [Third-party libraries](#third-party-libraries)
19. [Global constants (UnConsts)](#global-constants-unconsts)

---

## Overview

FastFile Professional is a **professional viewer and line editor** designed for very large plain-text files (tested above 14 GB on 32-bit Windows). It never loads the full file into memory: instead it builds a compact **line-offset index** (`temp.txt`) on first open and uses **Memory-Mapped File** windows for all subsequent reads. All heavy operations run in background threads and write atomically to a temporary file before replacing the original. Optional Python companions add **SQL AI chat** (DuckDB) and **semantic RAG Q&A** (local embeddings + LanceDB + Groq) over the open file.

Product overview (PT-BR marketing): [`apresentacao_fastfile.md`](apresentacao_fastfile.md).

### Latest releases (**3.0.5.232** · 3.0.5.225 · 3.0.5.210 · 3.0.5.100 · 3.0.5.0 · 3.0.4.0 · 3.0.3.0 · 3.0.2.0 · 3.0.1.0 · 3.0.0.0 · 2.1.7.31 · 2.1.7.30 · 2.1.7.29 · 2.1.7.25 · 2.1.7.21 · 2.1.7.17 · 2.1.7.13 · 2.1.7.11 · 2.1.7.9 · 2.1.7.7)

- **★ 3.0.5.232 (release) — AI agent on files, anonymize, history details, custom PPI:** new **AI agent** (toolbar, Tools menu, **Ctrl+Alt+G**; `uAgentWorkspace` / `uAgentLoop` / `uAgentProtocol` / `uAgentTools` / `uAgentActions` / `uAgentBridge` / `uAgentPrefs`): pick files/folders, describe the request in plain words (14 languages) or **SQL** (`uAgentSql`: SELECT with WHERE / GROUP BY / ORDER BY / SUM / COUNT; UPDATE / DELETE / INSERT / ALTER become proposals; typed SQL runs without AI), whole-word vs partial matching (`uAgentMatchIntent`); tabs Answer / Proposed edits / Revised prompt / Files found; nothing is written before **Accept**, accepted edits use the core streaming routines (`uAgentPatch`, GB files, Cancel); **time to decide** (20 s, 5..600 s in Preferences) with timer badge; replace-all pre-count (0 hits = nothing proposed); no false "done" claims; replies in the UI language; buttons enabled only when there is content; "File(s) generated successfully" window (`uExportDoneDlg`, "Folder:" / "File:") + "Last generated file"; UTF-16 read fix. **Anonymize data** (`uAnonymize` / `uAnonymizeDialog`, **Ctrl+Alt+D** or whole file; same type and length, preview, undo/redo, before/after in history). Session-history **event details** (`uHistLineDetailDlg`: double-click/Enter, F3 / Shift+F3, field-by-field compare, export TXT/CSV/JSON). **Custom PPI** toolbar button synced with the status-bar zoom; language switch retranslates on-screen texts; layout follows display changes (`FfFitCaptions`, `WM_DISPLAYCHANGE`); split-view refresh fix. Internal tracks **3.0.5.226–232** in `CHANGELOG_IMPLEMENTACOES.md` · F1 `FF_HELP.RecentFeaturesBlock2`.
- **★ 3.0.5.225 (previous within 3.0.5) — session history, Line editor, EOL policy, fast merge, stability:** **Find Occurrences** bar after Ctrl+F (F3 / Shift+F3, paged clickable hits, Load more) and **Search tools** gallery (`uFindOccurrencesBar`, `UnitPopupFileSearchGallery`); AI-First **post-action pipeline** ("What next?" chips + bridge memory, `uAssistantPostAction` / `uAssistantPipelineStore`); EOL/encoding detect + convert (`uFileFormatConvert`); docked **Bookmarks** bar (Ctrl+B, `uBookmarkBar`); professional message boxes (`uFastFileMsgDlg`); **Options** dialog (`uUserPrefs` / `uPrefsDialog`); MRU partial find (`uMruFind`); exception guard + hang/memory **watchdog** (`uFastFileAppGuard` / `uFastFileWatchdog`); **paged RAM-safe history preview** (`uHistPagedPreview`), Ctrl+wheel in history, export by legend; faster startup with many tabs and cancellable language switch; **CR+LF / LF / CR** in all routines (`uEolPolicy`); compare/merge history rework (substring highlight, paged **Changed lines** index `uHistChangedIndex`, merge-history MRU, dockable panels); diff synced scroll + threaded cancellable **apply left↔right** for 50 GB files (`uMergeApply`); **drag-to-reorder tabs**; renewed **Line editor** (find/replace F3/F4/Shift+F4, undo/redo, clear, previous/next line Alt+↑/↓, Ask AI); session history **checkboxes / select all / delete**, sort by line or date, **date range** with AlphaSkins `TsDateEdit`, export TXT/CSV, Ask AI, legend-colored selection; time messages translated and **17 units saved as UTF-8 with BOM** (no garbled accents). Internal tracks **3.0.5.211–225** in `CHANGELOG_IMPLEMENTACOES.md` · F1 `FF_HELP.RecentFeaturesBlock`.
- **★ 3.0.5.210 (previous within 3.0.5) — 14 UI languages + lazy-load i18n:** **Japanese** (12th) and **Chinese Simplified / Traditional** (13th/14th, `zh-CN` / `zh-TW`) with full `uI18n` **Set14** coverage; language combo + Assistente + Windows `LANG_CHINESE` detection. Startup fills **English + active language only** (`PutNV` allow-list; other languages load on first switch). Internal tracks **3.0.5.207–210** in `CHANGELOG_IMPLEMENTACOES.md` · F1 `FF_HELP.AssistantBlock`.
- **★ 3.0.5.100 (previous within 3.0.5) — FilterBar MRU, status-bar toggles, assistant polish, count_matching, More tools gradient:** **Ctrl+L** opens a docked **FilterBar** (pattern combo, Apply/Continue/Clear/Hide, peek strip; MRU last **20** patterns in `ASkin.ini` `[FilterRecentPatterns]`). Click status-bar **Mode/Wrap/Tail/Filter/Marks/View** to toggle. Assistant soft chrome (`TsPanel` CustomColor); AI-first local **`count_matching_lines`** (contains/partial). **More tools** gallery soft-blue gradient items; search/ESC polish. Internal tracks **3.0.5.91–101** in `CHANGELOG_IMPLEMENTACOES.md`. Internal **3.0.5.136–137:** Assistente **Validar fonte** (Python/JS/JSX/TS/TSX; chat *carregar o fonte pra validar*) — see [`DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md).
- **★ 3.0.5.0 (previous within 3.0.5) — AI Assistant compose (docs/code), Clear/Copy, safety lock, `fastfile_assistant`:** generate Word/RTF/DOCX/ODT/PDF summaries and multi-language source via Ctrl+Alt+A; outputs in **`fastfile_assistant\`**; Clear/Copy; safety lock blocks malware/OS shell and `.exe`/`.bat`/`.vbs`. Internal tracks **3.0.5.1–5** · F1 `FF_HELP.AssistantBlock` · `uFastFileComposeExport`.
- **★ 3.0.4.0 (release) — Advanced AI Chat (file) on GB+ files, chat scroll, preview encoding, Read/About polish:** **Advanced AI Chat (file)** (Ctrl+Alt+R) opens any-size files fast — `ConsumerRAG.py` defaults to **FastTextRAG** streaming lexical search (no upfront embeddings), so a **3.6 GB TXT** opens quickly; full semantic index is **opt-in** (`--semantic-index`). **Cancel loading** / **Close** no longer freeze the UI (non-blocking `StopConsumerRAGProcess`: `TerminateProcess` + timed 750 ms reader wait; panel hides at once; buttons always clickable). **Compare / Merge** preview and session history fix mojibake via encoding auto-detect (UTF-8 / ANSI / UTF-16, `uTextEncoding`) and **UTF-8** journal (`uFileSessionHistory`). **Mouse wheel** (and Ctrl+wheel) over any AI chat sidebar (SQL, Advanced, Assistant, Script) scrolls that transcript, not the main list. **Read** (Ctrl+1 / toolbar) with a file already open now opens the file browser and loads the chosen file. Toolbar **About** button shortened (`titlebar.about`, 11 languages). Internal tracks **3.0.4.1–5** in `CHANGELOG_IMPLEMENTACOES.md` · F1 `FF_HELP.AIChatFileBlock`. Rebuild FastFile (Delphi) + `data-lake-duckdb-main\build_exe_consumer_rag.bat`. See [AI Chat plugins](#ai-chat-plugins-consumerai--consumerrag).
- **★ 3.0.3.0 (release) — Win64 host + fast SWAR index + timer log:** Delphi **10.4.2 Sydney Win64** build (`Build\Win64\FastFile.exe`) alongside Delphi 7 Win32 (`Build\Win32\`); per-platform `Skins\` deploy; **operation timer log** (upper-right) fixed on Win64 (`TListBox` + `AppendOperationTimerLog`); **`uLineIndexScan.pas`** SWAR LF scan (8-byte; 32-byte wide when AVX2); smooth F5 progress ~22 Hz; parallel part-file scan **disabled** after sparse-index regression. Internal tracks **3.0.3.1–5** in `CHANGELOG_IMPLEMENTACOES.md` · F1 `FF_HELP.Win64IndexBlock`.
- **★ 3.0.2.0 (release) — Idle workspace brand + vertical block selection fix:** empty workspace shows blue gradient, high-res logo/watermark (1200 px PNG), centered title text, stable layout when AI assistant toggles; **Ctrl/Alt+drag** column block keeps selected width on mouse up (ListView + checklist); **F11** extends block to full content width only when pressed; Lanczos paint cache, no startup rectangle flash. Internal tracks **3.0.2.1–3** in `CHANGELOG_IMPLEMENTACOES.md` · `DOC_IDLE_LOGO_WORKSPACE.md`.
- **★ 3.0.1.0 (release) — Assistant recent files, companion EXE download, AI Chat panels:** natural-language **open Nth recent file** (`open_recent_file`); reliable auto-download of `ConsumerAI.exe` / `ConsumerRAG.exe` / `ScriptEngine.exe` (PyInstaller cookie, URLMon fallback, PE validation); UI **AI Chat** / **Advanced AI Chat** introduced (later renamed to **AI Chat (SQL)** / **Advanced AI Chat (file)**); `ResolveConsumerSourceFilePath` for `[READ ONLY]` tabs; assistant `MemoReply` panel restored. Internal tracks **3.0.1.1–5** in `CHANGELOG_IMPLEMENTACOES.md`.
- **★ 3.0.0.0 (release) — FastFile VERSION 3.0:** major milestone consolidating the 2.1.7.x track: operational **AI Assistant** with local command parsing (filter+export, replace all, split, delete line with filter active), Read-panel shortcuts when the assistant panel has focus, post-edit ListView refresh fix, `uFastFilePaths` temp-file constants, expanded i18n and F1 help (`FF_HELP.AssistantBlock`); merges menu reorg (2.1.7.29), EmEditor GB+ tools (2.1.7.29–31), and assistant whitelist (2.1.7.30–31). See `CHANGELOG_IMPLEMENTACOES.md` internal tracks **3.0.0.1–7**.
- **2.1.7.31 (release, pre-3.0) — Assistant action whitelist expanded:** filter (dialog/apply/clear), export, export filtered, delete duplicate lines, extract frequent strings, checkboxes, goto line, character code value, merge tabs, word wrap; `filter_text` / `line_no` JSON params.
- **2.1.7.30 (release) — FastFile operational AI assistant:** menu **AI → FastFile Assistant**; natural-language help and whitelisted actions (open/read, tabs, F1, find/replace, tail, compare, split, extract parts); JSON chains (e.g. read file then split in N parts after load completes); optional startup (`AssistantShowOnStartup`); optional `Assistant.log` (`AssistantLog=1`); F1 section; 11 languages. See `DOC_ASSISTENTE_IA_CHATBOT_PROPOSTA.md` and `DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md`.
- **2.1.7.29 (release) — Menu reorg & EmEditor analytics (GB+):** top-level **Tools** / **Session** / slim **Options** (`RebuildMainMenu`, `uI18n` menu keys, 11 languages); **`uEmEditorFeatures.pas`** — **Character Code Value** (View), **Extract Frequent Strings**, **Delete Duplicate Lines** (Tools › Filter and analysis); MMF scan + bucket spill + on-disk dedup hash; worker threads with progress **GB | MB/s | ETA**; disk-space check before dedup rewrite; F1 help block `FF_HELP.EmEditorBlock`; menu-bar hints **Alt+T / Alt+S**.
- **2.1.7.25 (release) — Zero Scan shortcuts, extract file parts & last line:** **Zero Scan** without dense index now supports **Ctrl+G** (physical line), **Replace All** streaming, batch delete via MMF, and F1 help section (`DOC_ZS_ATALHOS.md`); **Shift+End** discovers the last physical line (regressive proportional scan; files **> 256 MB** use background LF count with progress); **Ctrl+Shift+Q** **Extract file parts** (renamed from fraction) with translated output names `parte_1_de_8`, scrollable success dialog, Zero Scan line count, and ListView restore after export; on exit **`temp.txt`** + **`temp_ckpt.txt`** are deleted from the app folder.
- **2.1.7.21 (release) — Tail macro Python, split fix & script engine GB+:** **Tail macro (Python)** panel (`uTailMacro.pas`) runs `transform(line, ctx)` on each new tail line via ScriptEngine; examples + Talk with AI; reprocess new lines (**Ctrl+Shift+R**); include macro results in tail export (**Ctrl+Shift+L**); `uTailExportDialog` fully i18n (11 languages); **split equal parts** now uses balanced **line count** with LF boundaries (`FastFileCountLinesLf` — no mid-record cuts); **script engine large-file mode** — sparse index (`temp_ckpt.txt`), direct **OUTFILE** to disk, lightweight memo; i18n for tail macro / export / `Create blank lines`.
- **2.1.7.17 (release) — Line autofill & edit polish:** EmEditor-style **drag on Line # column** inserts blank rows (preview while dragging); does not interfere with **Ctrl/Alt** vertical block select in the content column; **Ctrl+Z / Ctrl+Y** for whole autofill blocks (`BatchKind=1`, journal **BAUT**); CSV mode inserts delimiter-only blank rows; **`RestoreCsvModeAfterPostEdit`** keeps CSV/hide-header after post-edit reload; batch **Delete** refreshes ListView without F5 (drops stale `temp.txt`, uses rebuilt `temp_ckpt.txt`); missing paths auto-removed from **Recent files**; i18n autofill/BAUT strings (11 languages).
- **2.1.7.13 (release) — Script engine & macro panel:** `ScriptEngine.py` byte-level `PROGRESS:` on RUNFILE (GB+ files); smooth-loading overlay updates progress/detail (`BeginScriptEngineProgress`, readable `lblDetail`); Python/Tail example titles via `TrText` (`PY_MACRO_EX_*`, `SCRIPT_ENGINE_EXAMPLES_*`) — fixes mojibake in suggestion panels; auto-download `ScriptEngine.exe` / `ConsumerAI.exe` / `ConsumerRAG.exe` from `hvogel.com.br/fastfile_executables/` when missing locally; **Ctrl+Alt+E** without a loaded file switches to Read tab + safe `SetFocus` (no `EInvalidOperation`); `uI18n` split into smaller procedures for Delphi 7 compiler limits.
- **2.1.7.11 (release) — Undo/Redo stability:** async line edit and undo/redo via `TEditFileThread` (no UI-thread `RunEditWait` freeze on large files); `BeginReadSilent` + `FFreshFileRead` keeps the undo stack after edits; **Yes/No confirmation** before Ctrl+Z / Ctrl+Y with line-specific message and content preview; `UndoRedoBusy` while a worker is running; undo recorded only after successful disk write.
- **2.1.7.9 (release) — Search, read-only session, Undo/Redo (initial):** `CurrentEffectiveFilePath` when tab shows `[READ ONLY]` (fixes Ctrl+F / Ctrl+H / tail); case-insensitive find (BMH + F3 on same line); find-match highlight in Content column; read-only blocks Replace/Replace All; undo stack for edit/insert/delete/paste/single replace — **Ctrl+Z**, **Ctrl+Y**, **Ctrl+Shift+Z** (up to 100 levels); i18n for undo/redo status (11 languages).
- **2.1.7.7 (release) — Embedded Split tab polish:** hosted **Split by Pattern/Regex** gains **`cmbMode`** (equal parts vs pattern/regex) + spin/label; fixes **Preview/Confirm** AV; **Confirm** uses **`roSplit`** for regex split; **Suggest examples with AI** / **Talk with AI** as standard **`TButton`** on a **fixed bottom bar** (outside **`TScrollBox`**) for reliable painting with AlphaSkins; memo layout metrics adjusted; **`uI18n`**: shorter AI memo section titles + **`Split / process mode:`** / **`Number of parts:`** (11 languages).
- **2.1.7.6 (release) — Split / Regex AI:** consolidates internal tracks **.3–.5**: **Preview** on embedded Split-by-Pattern tab (`MainUnit`); shared **`uVBScriptRegex.pas`** (VBScript normalize + compile check); **`uFastFileAIClient`** HTTPS gateway + **`uFastFileAIScreenHelp`** modal (“Talk with AI”): response footer with **paste-ready** regex lines plus optional reject list; **`AI_PROMPT_RULES_P3`** asks the model for `Regex:` lines; i18n **`AI_SPLIT_VALIDATION_*`** etc. (11 languages).
- **2.1.7.2 — Smooth loading:** `TBitBtn` cancel control (reliable with layered/AlphaBlend windows); cooperative cancel (`CancelRequested`) in read / edit / merge-delta / replace-all worker loops; `TrText('Cancelling...')` for all 11 languages (`uI18n`).
- **2.1.7.1 — Smooth loading:** larger progress overlay clamped to primary monitor work area (`SPI_GETWORKAREA`); rounded corners (region + paint clip + outline); smoother alpha fade-in; refined spacing for cancel vs. progress bar (`uSmoothLoading` / `.dfm`).

### Previous highlight (2.1.6.74)

- Script macro panel shortcuts hardened in all three memos via `Application.OnMessage` (Ctrl+C/Ctrl+Insert, Ctrl+V/Shift+Insert, Ctrl+A/Ctrl+T).
- ScriptEngine large-file throughput improved (larger protocol/read batches, reduced protocol noise, bulk output append in Delphi).
- Python Macro panel UX updated: dedicated top title bar and automatic scope radio sync with Select/checked-lines mode.
- ConsumerAI shutdown stability improved (reader thread lifetime fix to prevent invalid-thread-handle crashes on close/destroy).

---

## Key design principles

| Principle | Implementation |
|-----------|---------------|
| **No full load** | Line index (`temp.txt`, 20 bytes/line) + `TMMFReader` sliding windows |
| **Atomic writes** | Temp file `ff_<tag>_<tick>_<tid>.tmp` → `RenameFile` |
| **Non-blocking UI** | All I/O on worker threads; progress via `Synchronize` / `PostMessage` |
| **Single instance** | `CreateFileMapping("MyACMap")` mutex in `FastFile.dpr` |
| **Segmented ops** | Optional chunked Replace All / batch delete (~250 k lines/segment) |
| **Undo / Redo** | `TUndoRecord` stack (up to 100); async apply via `TEditFileThread`; **Yes/No** confirm before undo/redo; **Ctrl+Z** / **Ctrl+Y** / **Ctrl+Shift+Z**; line edit, insert, delete, paste, single replace, **line autofill blocks** (not Replace All) |
| **14-language i18n** | Runtime lookup tables in `uI18n`; language persisted in `ASkin.ini`; lazy-load at startup |
| **Append-only journal** | Per-file edit history in `FastFileSessionHistory\*.log` |
| **Smart open / search** | Automatic index vs. Zero Scan by file size; manual overrides in **View** / **Edit** menus; prefs in `ASkin.ini` |

**See also:** [Open mode and Zero Scan](#open-mode-and-zero-scan) · technical deep-dive: [`fastfile_arquitetura_bigdata.md`](fastfile_arquitetura_bigdata.md) · **Zero Scan operations portability (Find/Filter/Replace roadmap):** [`DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md`](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md) · **impact summary (Zero Scan + segmented ops):** [`DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md`](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md) · **Zero Scan shortcuts (F1 map):** [`DOC_ZS_ATALHOS.md`](DOC_ZS_ATALHOS.md) · Unicode ListView proposal: [`DOC_UNICODE_LISTVIEW_PROPOSTA.md`](DOC_UNICODE_LISTVIEW_PROPOSTA.md)

---

## Building the project

### Win32 (Delphi 7)

- **IDE:** Delphi 7 (Win32, 32-bit)
- **Main project file:** `FastFile.dpr`
- **Output directory:** `Build\Win32\` (or `Build\` on legacy D7 project)
- **Required packages:** AlphaControls (`.bpl` / `.dcp` in `Bpl\` / `Dcp\`); MidasLib (linked statically, eliminates `midas.dll` dependency)
- **Third-party source:** `FastMM4-master\`, `FastCode.Libraries-0.6.4\` — must be present before compilation
- **Resources:** compiled via `files.rc` / `folders.rc` into `FastFile.res`

#### Build steps (Win32)

1. Open `FastFile.dpr` in Delphi 7.
2. Ensure `Bpl\` and `Dcp\` paths are in the library search path.
3. Compile. The output `FastFile.exe` goes to `Build\Win32\` (or `Build\` on older configs).
4. On first run, the application self-extracts `ASkin.ini`, `Skins\`, `folders.xml`, `files.xml`, `texture.bmp`, and `logo.bmp` from embedded resources into the same folder as the exe.

### Win64 (Delphi 10.4.2 Sydney)

- **IDE:** Embarcadero Delphi 10.4.2 (Win64)
- **Project:** `FastFile.dproj`
- **Output:** `Build\Win64\FastFile.exe`
- **Scripts:** `compile_verify_win64.bat`, `compile_verify_d104.bat`
- Pre/post-build copies `Skins\` to `Build\<Platform>\Skins\`

#### Build steps (Win64)

1. Open `FastFile.dproj` in Delphi 10.4 or run `compile_verify_win64.bat`.
2. Select platform **Win64**, config **Base**.
3. Build. Output: `Build\Win64\FastFile.exe`.

> **Note:** Win64 uses native `Int64` pointers, separate single-instance mutex, and VCL fixes for AlphaControls on 64-bit (e.g. operation timer `TListBox`). Line indexing uses **`uLineIndexScan.pas`** (SWAR; parallel scan disabled by default).

---

## Project structure

```
Src\
├── FastFile.dpr          — Application entry point, single-instance mutex
├── UnConsts.pas          — All global constants (file names, version, limits)
├── MainUnit.pas          — Main form (frmMain): UI, menus, ListView, filter, undo/redo
├── UnDM.pas              — TDataModule1: TsSkinManager + TClientDataSet; resource extraction
├── UnUtils.pas           — General utilities: I/O, dialogs, extractResource, GetTmpDir
├── uSmoothLoading.pas    — Loading overlay form + ALL heavy-operation worker threads
├── uMMF.pas              — TMMFReader: Memory-Mapped File with sliding windows
├── uLineIndexScan.pas    — SWAR / AVX2-gated wide LF scan; parallel index scaffold (disabled)
├── uLineEditor.pas       — Modal dialog: single-line edit (insert/edit/delete/duplicate)
├── uDeltaEditor.pas      — Modal dialog: delta list editor for merge
├── uCompareMergeUI.pas   — Compare/Merge form + THistoryReloadThread
├── uFastFileAIClient.pas — HTTPS POST to FastFile AI gateway (WinInet, JSON)
├── uFastFileAIScreenHelp.pas — “Talk with AI” modal for Split-by-Regex tab + prompt assembly
├── uVBScriptRegex.pas    — VBScript.RegExp normalize / compile-check (shared with MainUnit)
├── uLineDiffCore.pas     — LCS DP diff engine for two TStringList instances
├── uFileSessionHistory.pas — Append-only session journal per data file
├── uI18n.pas             — Internationalization (14 languages, lazy-load + runtime lookup)
├── uTextEncoding.pas     — UTF-8 / UTF-16 / ANSI helpers for Delphi 7 ANSI VCL
├── MruHelper.pas         — MRU popup component (persists to .ini)
├── ThreadFileLog.pas     — Async file logger via 1-thread pool
├── ThreadUtilities.pas   — Generic TThreadPool base
├── UnConsumerAI.pas      — ConsumerAI.exe launcher (non-freezing CreateProcess loop)
├── UnConsumerDialog.pas  — ConsumerAI UI panel
├── uExportDialog.pas     — Export dialog
├── uFindReplace.pas      — Find & Replace dialog
├── UnFormAboutFF.pas     — About / version history screen
├── UnSearch.pas          — Find-in-files form
├── unSplitView.pas       — Split view form
├── FolderMon.pas         — Directory watcher (ReadDirectoryChangesW)
├── StopWatch.pas         — High-resolution timer (QueryPerformanceCounter)
├── DSiWin32.pas          — Win32 utility library (third-party)
├── data-lake-duckdb-main\ — Python sources + PyInstaller scripts for ConsumerAI / ConsumerRAG / ScriptEngine
│   ├── ConsumerAI_LanceDB.py — SQL / DuckDB AI chat (built as ConsumerAI.exe)
│   ├── ConsumerRAG.py        — Text RAG Q&A (built as ConsumerRAG.exe)
│   ├── rag_engine.py         — Chunking, local embeddings, LanceDB, answer pipeline
│   ├── build_exe_lancedb.bat / build_exe_consumer_rag.bat
│   └── bridge_*.py           — FFBRIDGE pipe protocol helpers for Delphi
├── FastMM4-master\       — FastMM4 memory manager
├── FastCode.Libraries-*\ — FastCode RTL replacements
├── Build\                — Compiled output (exe, ini, xml, bitmaps, Skins\)
├── RegressionTests\      — Regression test suite
├── apresentacao_fastfile.md — Product presentation (PT-BR)
└── ARQUITETURA_TECNICA_FASTFILE.md — Full technical architecture document
```

---

## Core units reference

### `MainUnit.pas`

Main form `frmMain`. Responsibilities:

- **`TListView` (OwnerData / virtual mode):** items fetched on demand via `OnData` → index lookup in `temp.txt` → `TMMFReader` → `uTextEncoding` decode.
- **`TPageControl`:** includes Read File, Split File, Exported Lines, Find Files, Recent Files, embedded Compare/Merge + History (`tabMerge`), and embedded **Split by Pattern/Regex** (`tabSplitByPatternTab`) with Preview + optional **Talk with AI** (gateway JSON).
- **Filter (`TFilterMatchMode`):** `fmmContains`, `fmmPrefix`, `fmmRegex`. A bitset over all indexed lines marks which lines pass; `TFilterThread` builds it (Int64 arithmetic to stay within 32-bit limits).
- **Tail/Follow:** timer detects file growth → `TailAppendNewLines` reads delta in 64 MiB chunks to append index records without full re-read, with pause/resume and pending-lines status.
- **Recent Files startup hub:** integrated startup tab with recent files/folders, i18n labels (11 languages), and "don't show on startup" persistence in `ASkin.ini` (`WelcomeScreenShow`).
- **Recent Files UX:** softer selection rendering (no persistent blue fill), translated tagline/close/menu launcher, and optional "keep as first tab" ordering when startup hub is enabled.
- **Bookmark rendering:** bookmarked rows use blue background + white text in both virtual ListView and Select-mode checklist.
- **Word-wrap navigation precision:** Ctrl+G/F2/Shift+F2 keep exact target selection in checklist mode with filtered/clamped offsets.
- **Undo/Redo:** `TUndoRecord` stack; `ApplyEditWithUndo` / `StartAsyncUndoRedo` (async workers); `CommitPendingEditUndoIfNeeded` / `CommitPendingUndoRedoIfNeeded` in `TEditFileThread.FinishThread`; confirmation dialogs; `RefreshFile` → `BeginReadSilent` preserves stack (F5 clears via `FFreshFileRead`).
- **Segmented heavy ops:** `EffectiveUseSegmentedHeavyOps` + policy in **Options**; full spec: **[DOC_SEGMENTED_HEAVY_OPS.md](DOC_SEGMENTED_HEAVY_OPS.md)**; summary: `ROADMAP_COMERCIAL_FASTFILE.md` appendix, `ARQUITETURA_TECNICA_FASTFILE.md` § 4.1.1. Read toolbar: zoom/find/marks quick buttons beside word wrap.

### `uEmEditorFeatures.pas`

EmEditor-style analytics on very large files (worker thread `TEmEditorStatsThread`, no UI freeze on GB+ sources):

- **Character Code Value** — inspect Unicode code point, decimal, UTF-8 bytes, and byte offsets for one character on the current line (View menu).
- **Extract Frequent Strings** — MMF line scan (`ScanFileLinesMMF`); count lines, words, or CSV cells; in-memory map for files ≤ 8 MB, **bucket spill** for larger files; CSV output `string,count`.
- **Delete Duplicate Lines** — keeps first occurrence; whole-line or CSV-column key; **`TDiskKeySet`** chained hash on disk; temp file + atomic rename; **`ConfirmDiskSpaceForPaths`** before write.
- Progress overlay: scanned GB, MB/s, ETA (~120 ms refresh).

### `uSmoothLoading.pas`

Central hub for all async operations. Contains:

- `TfrmSmoothLoadingForm` — animated semi-transparent overlay (`TPaintBox` progress bar, fade-in, `WM_APP+77`).
- `TfrmSmoothLoading` — orchestrator thread that creates the correct worker.
- All worker thread classes (see [Threading model](#threading-model)).

### `uMMF.pas` — `TMMFReader`

```
CreateFile(GENERIC_READ, FILE_SHARE_READ|WRITE)
→ CreateFileMapping(PAGE_READONLY)
→ MapViewOfFile(FILE_MAP_READ, aligned offset)
```

`EnsureView(AbsOffset, MinBytes)` remaps the window when the requested offset falls outside the current view, always aligning the mapping offset to `SYSTEM_INFO.dwAllocationGranularity` (typically 64 KB).  
`PtrAt` returns a direct pointer + `Contiguous` byte count.  
`ReadBytes` copies safely across window boundaries.

### `uFileSessionHistory.pas`

Append-only journal, one file per data file opened. Thread-safe via `GFFHistLock: TCriticalSection`.

- **Path:** `<exe>\FastFileSessionHistory\ffhist_<FNV1a-32>_<basename>.log`
- **FNV-1a 32-bit hash** over the lowercased absolute path (collision-resistant naming).
- **Record format:** `<timestamp>|<op>|<line>|<old_excerpt>|<new_excerpt>` (pipes inside fields replaced with space).

### `uLineDiffCore.pas`

`FFBuildLineDiffRows(Left, Right, AMaxDim, ADiff)`:

- Trims matching **prefix** and **suffix** lines in O(n) before entering DP.
- Bounded LCS DP matrix (`AMaxDim × AMaxDim`).
- Output: list of `PFFDiffRow` records with `TFFDiffKind` (`ffdkEqual`, `ffdkDelete`, `ffdkInsert`, `ffdkChange`).

---

## Threading model

All worker threads follow the same lifecycle: show overlay → do work → atomic rename → reload index → hide overlay.

| Thread | Operation | Temp file tag |
|--------|-----------|--------------|
| `TReadFileThread` | Index file, populate ListView | writes `temp.txt` directly |
| `TEditFileThread` | Insert / Edit / Delete / Duplicate line | `edit` |
| `TMergeDeltaThread` | Apply `.delta` patch to source file | `mrgd` + `temp_merge.txt` |
| `TReplaceAllThread` | Global replace (normal or segmented) | `rall` / `rseg` |
| `TExportFileThread` | Export selected lines to file or clipboard | `exp` |
| `TSplitFileThread` | Split file by line ranges | direct output files |
| `TSplitEqualPartsThread` | Split file into N equal-size parts (LF-aligned) | direct output files |
| `TMergeFilesThread` | Merge two files at byte offset or line range | `mrg` |
| `THistoryReloadThread` | Reload session journal for Compare/Merge UI | — |

### Temp file naming

```pascal
'ff_' + Tag + '_' + IntToStr(GetTickCount) + '_' + IntToStr(GetCurrentThreadId) + '.tmp'
```

Created in `ExtractFilePath(ParamStr(0))` (exe folder).

### Thread → UI communication

- **`Synchronize`:** progress updates for short operations.
- **`PostMessage(WM_APP+77)`** and **`PostMessage(WM_FF_HIST_PROGRESS_FLUSH)`:** coalesced progress for long operations (avoids flooding `Application.ProcessMessages`).
- **`MsgWaitForMultipleObjects(QS_ALLINPUT, 5 ms)`** + `Sleep(2 ms)`: yield inside worker loops to keep UI responsive without busy-wait.
- `SyncApply` in `THistoryReloadThread`: batches UI updates in slices of 12 items to prevent stall.

---

## File indexing and MMF

### Index record layout (`temp.txt`, `INDEX_RECORD_SIZE = 20` bytes)

| Offset | Size | Type | Content |
|--------|------|------|---------|
| 0 | 8 | Int64 | Byte offset of line start in source file |
| 8 | 8 | Int64 | Byte length of line |
| 16 | 4 | DWORD | Flags / reserved |

`TReadFileThread` scans the source file via `TMMFReader`, emitting one record per `#10` delimiter.

On `OnData` (ListView virtual mode): `LineIndex × 20` → seek in `temp.txt` → read record → `TMMFReader.ReadBytes(offset, length)` → `DisplayTextFromFileBytes(raw, encoding)` → display.

Sparse fallback: `temp_ckpt.txt` (one offset every `CKPT_INTERVAL` lines) when the dense index is not built (very large files).

---

## Open mode and Zero Scan

FastFile can open a file in two fundamentally different ways:

| Mode | What happens on **F5 / Read** | Line index (`temp.txt`) | Typical use |
|------|------------------------------|-------------------------|-------------|
| **Indexed open** | `TReadFileThread` scans the file (SWAR / MMF) | Built on disk | Normal editing, **Ctrl+F**, filter/grep, exact line numbers |
| **Zero Scan (instant)** | No scan thread; **~estimated** line count from a 4 MB sample (not 2 B fake rows) | **Not** built | Huge files (**≥ 15 GB** auto, or Force Zero Scan) where full indexing would take too long |

### What “Force Zero Scan” is for

Menu: **View → Force Zero Scan Mode (Ultra Large Files)**.

When checked, **every** open uses instant Zero Scan, even a 10 MB file. Use it when you **know** you do not need a line index and only want to scroll through raw bytes quickly.

It overrides the automatic size rule until you uncheck it and read the file again (**F5**).

### Automatic decision (default)

Menu: **View → Open: automatic (recommended)** (default).

On **F5**, `ShouldOpenWithInstantZeroScan` in `MainUnit.pas` chooses:

```
IF Force Zero Scan is checked          → instant open (Zero Scan)
ELSE IF menu "Open: always instant"   → instant open
ELSE IF menu "Open: always index"      → always run TReadFileThread
ELSE (automatic)
     IF file size >= 15 GB            → instant open
     ELSE                             → index normally
```

**Constant today:** `ZeroScanAutoOpenMinFileSize` = **15 × 1024³** (15 GB). Line count is **not** used for this open-time gate—only file size in bytes.

#### Examples

| File | Auto open (default) | Ctrl+F / filter |
|------|---------------------|-----------------|
| 10 MB, 50 k lines | Index (seconds) | Works (uses `temp.txt` / ckpt) |
| 500 MB, 600 k lines | Index (longer) | Works after index finishes |
| 5 GB | Index | Works after index |
| 10 GB | Index (normal scroll, real line count) | Works after index |
| 50 GB | **Instant** Zero Scan | No index unless you disable instant mode and F5 |
| 2 TB | **Instant** (or Force Zero Scan) | Browse-only; search needs index |

### After index: “large file” flag (`FZeroScanMode`)

Even when the file **was** indexed, FastFile may set internal `FZeroScanMode` only when there is **no** line index and line count **> 500 000**, or when the **2 billion** airbag fired during scan, or when **Force Zero Scan** / instant open (≥ 15 GB) was used.

If `temp.txt` or `temp_ckpt.txt` exists, scroll and **Shift+End** use the **real** line count (`UsesProportionalZeroScanScroll` is false). **Find** and **Filter** use the index (`HasLineSearchIndex`). True instant Zero Scan (no index) is only when the open path skipped `TReadFileThread`.

### Manual overrides (menus + INI)

Preferences are saved in **`ASkin.ini`** under `[FastFile]`:

| INI key | Values | Menu (approx.) |
|---------|--------|----------------|
| `OpenFilePolicy` | `0` auto, `1` always index, `2` always instant | **View** → Open: automatic / always index / always instant |
| `ForceZeroScan` | `0` / `1` | **View** → Force Zero Scan |
| `FindCasePolicy` | `0` auto, `1` match case, `2` ignore case | **Edit** → Search: … |
| `FilterMatchPolicy` | `0` auto … `3` regex | **Edit** → Filter: … |
| `FilterCasePolicy` | `0` auto, `1` match case, `2` ignore case | **Edit** → Filter: … |

**Search / filter defaults (automatic, no extra dialogs):**

- Find case: sensitive only if the search text contains **uppercase** letters.  
- Filter mode: **contains**; `^…` / `( ) [ ] | ? \` → regex; trailing `*` → line **starts with**.  
- If you search without an index but the file is indexable (&lt; 10 GB and not forced instant), FastFile starts **F5** and continues the search when indexing completes.

### Scroll in instant Zero Scan (fix)

Without an index, the scrollbar is **proportional**, not exact line-by-line. Older builds used **2 B** virtual steps (`fileSize ÷ 2B` bytes per step), so scrolling to “line 20 000 000” on a 10 GB file already pointed past EOF (empty rows). Current builds call `EstimateZeroScanLineCount` (sample first 4 MB, count `#10`, refine with last 4 MB) so `totalLines` and the vertical bar approximate the real end of the file. **Shift+End** (v2.1.7.28+) runs a regressive scan on the proportional list and, for files **> 256 MB**, a full LF count in a background thread with progress — then updates `totalLines` and jumps to the last physical line. The mouse wheel drives only the external scrollbar (`Offset` ±1 per notch), not `WM_VSCROLL` on the ListView (which jumped millions of virtual rows).

**Files &lt; 15 GB** (e.g. your 10 GB file) open with a **real index** by default: normal line-by-line scroll, **Shift+End**, and Ctrl+F — unless **Force Zero Scan** is checked.

### 2 billion line airbag

While indexing, if the line counter reaches **2 000 000 000** (`TReadFileThread`), the scan stops to avoid Win32 `Integer` overflow in the ListView. The UI then behaves like Zero Scan with a virtual 2 B line cap. See [`fastfile_arquitetura_bigdata.md`](fastfile_arquitetura_bigdata.md) for SWAR, MMF, and scrollbar math.

For a **full technical specification** of why Find/Filter/Replace require a line index today, what can be ported to instant Zero Scan, sparse vs. dense index, 32-bit limits, and phased implementation (A–D), see [`DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md`](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md). For a **consolidated impact summary** (feature matrix, Zero Scan + `EffectiveUseSegmentedHeavyOps`), see [`DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md`](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md).

---

## Atomic write pattern

Used by every thread that modifies a file:

```
1. Open  ff_<tag>_<tick>_<tid>.tmp  for write  (OUT_BUFFER_SIZE = 64 KB buffer)
2. Read source via TMMFReader (does not lock the original)
3. Write transformed content to temp file
4. SUCCESS → RenameFile(tmp, original)   ← atomic on NTFS
5. FAILURE → DeleteFile(tmp)             ← original intact
6. Launch TReadFileThread to rebuild index
```

`UnBufferedTextWriter` provides the 64 KB buffered writer used in steps 1–3.

---

## Segmented heavy operations

Full specification: **[DOC_SEGMENTED_HEAVY_OPS.md](DOC_SEGMENTED_HEAVY_OPS.md)** (same folder as this README).

Controlled by **`SegmentHeavyOps`** (force) and **`SegmentHeavyOpsPolicy`** (auto / always / never) in **`ASkin.ini`**, configured under **Options** menu. Automatic mode uses **`EffectiveUseSegmentedHeavyOps`** in `MainUnit.pas` (file >100 MB, >500k lines, or ≥200 lines in the operation).

### Replace All — segmented mode (`TReplaceAllThread.TrySegmentedReplace`)

1. Reads `temp.txt` to get total line count.
2. Divides into segments of `FLinesPerSegment` lines (default **250,000**).
3. For each segment: creates an inner `TEditFileThread` (`FreeOnTerminate=False`) → writes `ff_rseg_<n>_*.tmp`.
4. Concatenates all segment temps into `ff_rall_*.tmp`.
5. Atomic rename → original file updated.
6. Cleans up segment temps.

Limit: `REPLACE_ALL_MATCH_LIMIT = 5,000,000` substitutions across the whole file (safety guard).

### Batch delete — segmented mode (`TrySegmentedBatchDelete`)

Same segmentation strategy: for each segment, writes only the **lines to keep** (inverse of selected), concatenates, atomic rename. Falls back to classic `DeleteFromStream` if index is missing or the file has only one segment.

---

## Session history journal

```
FastFileSessionHistory\
    ffhist_<FNV1a-32-hex>_<basename>.log
```

Each line in the log:

```
2026-04-25 14:30:00|EDT|42|old text excerpt|new text excerpt
```

Operations logged: `INS`, `EDT`, `DEL`, `RPLALL`.

Read back by `THistoryReloadThread` in `uCompareMergeUI`: scans the tail of the journal (256 KiB progress granularity), filters to the currently open file, colorizes entries by operation type, displays in `lvHistFile`.

---

## Compare / Merge and diff engine

`TfrmCompareMerge` (`uCompareMergeUI.pas`) has two tabs and is now hosted in the main `tabMerge` (embedded mode, non-modal):

- **History tab:** `lvHistFile` (journal entries colored by INS/EDT/DEL/RPLALL) + `mmoJournal` (raw journal preview).
- **Diff tab:** two virtual `TListView` (`lvLeft` / `lvRight`) showing `TFFDiffRow` records. Sync-scroll via `tmrSync`. Context menus show "Apply left→right" / "Apply right→left" **only on changed lines** (`ffdkChange`, `ffdkInsert`, `ffdkDelete`).
- **Async diff run:** `btnRunDiff` uses `TDiffWorkerThread` + `TfrmSmoothLoading` progress updates, keeping the UI responsive while reading and building diff rows.
- **Large-file fast mode:** dynamic force-range threshold (`FFComputeDynamicForceRangeBytes`) auto-switches to bounded range diff when files are large; an explicit **Fast mode for large files** checkbox controls this behavior.
- **Range consistency:** line-range diff uses a lookahead window then trims back to the requested range, reducing false tail mismatches after early insert/delete shifts.
- **Apply edge-case safety:** when an insert operation has no direct anchor line (`line 0` / beyond EOF), the content is appended at file end (no silent loss).
- **Visual semantics:** missing-side rows render blank line number (not `0`); colors/legend aligned to meaning: green=equal, yellow=added on right, red=removed on left, blue=changed.

Merging: `TEditFileThread.RunEditWait` is called per changed line. `TouchHistoryIfSameFile` triggers a ListView + journal reload if the edited file is the one open in the main form. `WM_SETREDRAW` prevents flickering during batch apply.

---

## Internationalization

`uI18n.pas` supports **14 languages** resolved at runtime:

```
en | pt-BR | pt-PT | es | fr | de | it | pl | ro | hu | cs | ja | zh-CN | zh-TW
```

Two lookup tables per language (key-based and English-text-based), stored as sorted `TStringList` for O(log n) binary search (`FastIndexOfName`). At startup only **English + the active language** are populated (`PutNV` allow-list); other languages load on first switch.

```pascal
Tr('key', 'Default text')   // explicit key lookup
TrText('Default text')      // English text as key (most common)
ApplyTranslationsToForm(AForm)  // iterates all components recursively
```

Language code stored in `ASkin.ini → Language` (e.g. `pt-BR`, `zh-CN`, `zh-TW`). Changed via language combo → persisted immediately.

---

## Files on disk

All paths relative to `ExtractFilePath(Application.ExeName)` unless noted.

### Always present after first run

| File / Folder | Constant | Description |
|--------------|----------|-------------|
| `ASkin.ini` | `ASKIN_INI` | Main configuration (skin, language, window position, flags) |
| `Skins\` | `FOLDERSKIN` | AlphaControls skin theme files |
| `texture.bmp` | `TEXTURE` | Skin texture bitmap |
| `logo.bmp` | `LOGO` | Logo shown on loading overlay |
| `folders.xml` | `XMLFOLDERS` | TClientDataSet — folder data |
| `files.xml` | `XMLFILES` | TClientDataSet — file metadata |

### Created at runtime

| File | Constant | Description |
|------|----------|-------------|
| `temp.txt` | `TEMPFILE` | Line-offset index (20 bytes/line). Rebuilt on every file open. |
| `mru_files.ini` | — | Recent files list |
| `mru_location.ini` | — | MRU for the location field (25 items) |
| `mru_content.ini` | — | MRU for the search/content field (25 items) |
| `ff_*.tmp` | — | Atomic operation temporaries; cleaned up after each operation |
| `FastFileSessionHistory\ffhist_*.log` | — | Session edit journals (one per data file) |
| `Log_FastFile<ddmmyyyyhhnn>.txt` | — | Async error log (written by `LogAsync`) |
| `<name>.delta` | — | Delta patch file saved by the Delta Editor |
| `extensionFiles.txt` | — | Extension list for open-file dialogs |
| `ConsumerAI.exe` | `CONSUMERAI` | External **AI Chat (SQL)** plugin (Python / PyInstaller, optional) |
| `ConsumerRAG.exe` | `CONSUMERRAG` | External **Advanced AI Chat (file)** RAG plugin (optional) |
| `ScriptEngine.exe` | `SCRIPTENGINE` | External Python script / tail-macro engine (optional) |
| `data\rag_workspace\` | — | LanceDB vector index for ConsumerRAG (kept when `--keep-workspace`; **purged on Cancel loading**) |
| `data\rag_answers\` | — | Optional Markdown exports of long RAG answers |
| `ConsumerRAG_startup.log` | — | Frozen-exe startup diagnostics (written by ConsumerRAG) |

---

## INI configuration keys (ASkin.ini)

Section: `[FastFile]`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `SkinDirectory` | String | `<exe>\Skins` | Path to AlphaControls skin folder |
| `SkinName` | String | `Notes Plastic` | Active theme name |
| `SkinActive` | 0 / 1 | `1` | Enable / disable skinning |
| `Top` | Integer | — | Main window Y position |
| `Left` | Integer | — | Main window X position |
| `Language` | String | `pt-BR` | Active language code |
| `SegmentHeavyOps` | 0 / 1 | `0` | Enable segmented Replace All and batch delete |
| `OpenFilePolicy` | 0 / 1 / 2 | `0` | `0` = auto (≥10 GB → instant), `1` = always index, `2` = always instant |
| `ForceZeroScan` | 0 / 1 | `0` | Force instant Zero Scan on every open (strongest override) |
| `FindCasePolicy` | 0 / 1 / 2 | `0` | Find: auto / match case / ignore case |
| `FilterMatchPolicy` | 0 … 3 | `0` | Filter: auto / contains / prefix / regex |
| `FilterCasePolicy` | 0 / 1 / 2 | `0` | Filter: auto / match case / ignore case |

Read/written via `sStoreUtils.ReadIniInteger` / `WriteIniStr` (AlphaControls). Open/search/filter prefs use `TIniFile` in `LoadSmartSearchPrefs` / `SaveSmartSearchPrefs` (`MainUnit.pas`).

---

## Async log

`ThreadFileLog.pas` — `LogAsync(FileName, Text)`:

```
GlobalLogThread (TThreadFileLog, lazy init)
  └── TThreadPool (1 worker thread)
        └── HandleLogRequest → LogToFile (AssignFile / Append / Writeln / CloseFile)
```

Log file name pattern: `Log_FastFile<ddmmyyyyhhnn>.txt` (e.g. `Log_FastFile25042026_1430.txt`).  
Written to the current working directory (usually the exe folder).  
Called from `uMMF` on mapping errors and from thread exception handlers.

---

## AI Chat plugins (ConsumerAI / ConsumerRAG)

Side panels and companions talk to FastFile over the **FFBRIDGE** pipe protocol (`FFBRIDGE|STATUS|…`, `PROMPT`, `OPTIONS`, `OUTPUT`). Binaries may be auto-downloaded from `hvogel.com.br/fastfile_executables/` when missing (see **v3.0.1.0**). Rebuild Python with `data-lake-duckdb-main\build_exe_lancedb.bat` / `build_exe_consumer_rag.bat`.

| UI (EN key → typical PT) | Shortcut | Plugin | Role |
|--------------------------|----------|--------|------|
| **AI Chat (SQL)** → *Chat IA (SQL)* | `Ctrl+Shift+A` | `ConsumerAI.exe` ← `ConsumerAI_LanceDB.py` | Ingest tabular / text into **DuckDB**; natural language → **SQL**; analytics / counts / filters |
| **Advanced AI Chat (file)** → *Chat IA avançado (arquivo)* | `Ctrl+Alt+R` | `ConsumerRAG.exe` ← `ConsumerRAG.py` + `rag_engine.py` | **RAG** over plain text/logs: stream **chunks**, local **embeddings** (`sentence-transformers`, vectors in **LanceDB**), generative answers via **Groq** (not SQL) |

Separate from both: menu **AI → FastFile Assistant** (`Ctrl+Alt+A`) — operational help / whitelisted editor actions (not the SQL or RAG chats).

### Advanced AI Chat (file) — bridge launch (current)

`StartConsumerRAGProcess` in `MainUnit.pas` runs approximately:

```
ConsumerRAG.exe -file "<path>" --bridge
  --answer-depth forensic --overview-depth thorough
  --top-k 32 --chunk-context-chars 8000 --max-context-chars 160000
  --max-answer-tokens 12000 --profile-scan-lines 2000000
  --overview-budget-seconds 45 --precision-mode aggressive
```

Optional slow path: add `--semantic-index --keep-workspace` for full local embeddings.
- **`--bridge` (default from FastFile):** **fast streaming** (`FastTextRAG`) — opens **any size** (MB…GB) in seconds; lexical retrieval + on-demand sampling. No full local embeddings at startup.
- **`--semantic-index` (opt-in):** full vector embeddings for the file (high quality, **slow** on large files / CPU). Use with `--keep-workspace` to reuse LanceDB under `data\rag_workspace`.
- **Status bar:** `Preparing...` / `Indexing... NN% · ETA …` then `Ready`.
- **Cancel loading:** stops the process, then `PurgeConsumerRAGTempData` deletes `data\rag_workspace` and `data\` beside the plugin so a new session starts clean.
- **Tokens vs embeddings:** embeddings (when enabled) are **local** (CPU/GPU time). Groq / LLM tokens are only for the answer context (top‑k excerpts), not the whole multi‑GB file.

### ConsumerAI (SQL chat)

Embedded panel path uses bridge similarly; older helper `TConsumerAI` (`UnConsumerAI.pas`) can also launch:

```
ConsumerAI.exe -file "<path>" -rp -prompt
```

Own logs: `ConsumerAI_startup.log`, `ConsumerAI_LanceDB_startup.log`, `ConsumerRAG_startup.log`.

Requires `GROQ_API_KEY` (and optional `GROQ_MODEL`, `EMBEDDING_MODEL`) via `.env` embedded in the PyInstaller build or the process environment.

---

## Third-party libraries

| Library | Location | Purpose |
|---------|----------|---------|
| **FastMM4** | `FastMM4-master\FastMM4.pas` | High-performance memory manager. Replaces the default Delphi allocator. `ReportMemoryLeaksOnShutdown=True` in DEBUG builds. |
| **FastCode** | `FastCode.Libraries-0.6.4\FastCode.pas` | Optimized RTL replacements (`Move`, `FillChar`, `Pos`, etc.). |
| **AlphaControls** | `Bpl\`, `Dcp\` | Visual component suite with runtime skinning (`TsSkinManager`, `sPanel`, `sListView`, `acTitleBar`, …). |
| **DSiWin32** | `DSiWin32.pas` | Win32 wrappers (processes, registry, services, events). |
| **MidasLib** | linked statically | Eliminates `midas.dll` dependency for `TClientDataSet`. |

---

## Global constants (UnConsts)

```pascal
APPLICATION_NAME              = 'FastFile'                 // also the [FastFile] INI section
APPLICATION_EDITION           = 'Professional'
APPLICATION_DISPLAY_NAME      = 'FastFile Professional'    // window title, About, idle logo
APPLICATION_VERSION           = '3.0.5.232'
ASKIN_INI                     = 'ASkin.ini'
XMLFOLDERS                    = 'folders.xml'
XMLFILES                      = 'files.xml'
CONSUMERAI                    = 'ConsumerAI.exe'
CONSUMERRAG                   = 'ConsumerRAG.exe'
SCRIPTENGINE                  = 'ScriptEngine.exe'
TEXTURE                       = 'texture.bmp'
LOGO                          = 'logo.bmp'
FOLDERSKIN                    = 'Skins'
TEMPFILE                      = 'temp.txt'
CHUNKFILE                     = 'chunk.txt'
OUT_BUFFER_SIZE               = 65536        // 64 KB I/O buffer
INDEX_RECORD_SIZE             = 20           // bytes per record in temp.txt
SIZEPARTFILE                  = 25000000     // 25 MB default split part size
MAX_FILESIZE_MEMORY_LIMIT_BYTES = 15958207655 // ~14.86 GB safety ceiling
```

---

## See also

- [apresentacao_fastfile.md](apresentacao_fastfile.md) — product presentation (PT-BR)
- [ARQUITETURA_TECNICA_FASTFILE.md](ARQUITETURA_TECNICA_FASTFILE.md) — full technical architecture document (PT-BR)
- [CHANGELOG_IMPLEMENTACOES.md](CHANGELOG_IMPLEMENTACOES.md) — implementation changelog (v2.1.6.x series)
- [ARQUIVOS_EXTERNOS_FASTFILE.md](ARQUIVOS_EXTERNOS_FASTFILE.md) — external files and resources reference
- [DOC_INDEXACAO_F5_MMF_WRITER.md](DOC_INDEXACAO_F5_MMF_WRITER.md) — F5 indexed open: `TMMFReader` + `TBufferedTextWriter` → `temp.txt` / `temp_ckpt.txt`
- [DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md](DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md) — Compare/Merge step-by-step guide
