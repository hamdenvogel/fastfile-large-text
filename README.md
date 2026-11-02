# FastFile Professional

**The professional tool to open, search and edit multi-gigabyte text files instantly on Windows.**

**FastFile Professional** is a native, professional-grade Windows desktop tool written in Delphi for working
with very large text files (logs, CSV/TSV exports, SQL dumps, data extracts) that make ordinary editors freeze
or run out of memory. Files are indexed by line and read through memory-mapped I/O, so a 10 GB file opens and
scrolls as smoothly as a 10 KB one.

> **Edition: Professional.** FastFile is not a hobby viewer: it is a professional product built for analysts,
> DBAs, developers and support teams who handle production-size data every day — with safe atomic writes,
> a full session log, an AI agent with reviewed proposals, data anonymization and 22 UI languages.

![FastFile Professional main window](Docs/screenshot-main.png)

## Professional features

- **Huge files, instantly** – line index + memory-mapped files (MMF); *Zero Scan* mode opens giant files without a full pre-scan.
- **Search and replace** – fast find, filters, Replace All in segmented mode for files larger than RAM.
- **Internal glob / grep** – path wildcards or content searches, cancellable paged results and bookmark integration; separate buttons in Find, Filter and Bookmarks. Type just `grep` or `glob` for examples and optional AI command help. Recent commands stay in a searchable list. Review generated commands before running them.
- **Line limits you can see** – Options shows the default for anonymize, merge, translate, export, insert and split. The screen that uses a limit shows the same number. An empty value returns to the default.
- **Split by lines** – preview of the range, the same line tools as the file list, and a save that scans the original file instead of loading the range as a list.
- **Edit safely** – line editing, batch delete, atomic writes (temp file + swap) and a session log.
- **File tools** – split, merge, compare (line diff engine) and extract parts of a file.
- **Navigation** – bookmarks, go to line, filtered views, zoom.
- **Python macros** – run scripts against the open file through the built-in script engine.
- **AI assistant** – ask questions about the file content (optional Python companion).
- **AI agent on files** (Ctrl+Alt+G) – describe a request in plain words or SQL (`SELECT … GROUP BY / SUM / COUNT`, `UPDATE`, `DELETE`…) over one or many files; every change is shown as a proposal and only written after you accept it, within a configurable time limit. It can profile each file, follow which files you named, and run a Python macro on each line after a preview.
- **AI diagnosis** (Ctrl+Alt+U) – read-only review of files and folders (inventory, structure, content, SQL, privacy, actions). Edits stay on the AI agent.
- **Fast line edit** – insert, replace and delete on large files through the existing line index, with a recovery log that restores the file if the app stops mid-edit, and a before/after preview of the lines that change.
- **Anonymize data** (Ctrl+Alt+D) – replace private values with fake ones of the same type and length, with preview and undo.
- **Session history details** – before/after of every change, field-by-field compare, export to TXT/CSV/JSON.
- **Source check** – JSON, HTML and SQL inside FastFile; Java, Go and C# with the compiler already on this PC.
- **Regex examples** – Filter and the line editor show a few patterns and can ask the AI for one. The proposal is not run until you use it.
- **Recent languages** – the language list keeps the ones you used first. Type to search. The list closes while the new language loads. Each name has a country flag.
- **Right to left** – Arabic and Hebrew mirror forms, dialogs and controls. File text stays left to right. In those languages the file-list columns read from the right.
- **Equal parts on the toolbar** – the button sits right after Merge files (Ctrl+Shift+P) and opens Split file into equal parts.
- **28 languages** – English, Português (BR/PT), Español, Français, Deutsch, Italiano, Polski, Română, Magyar, Čeština, 日本語, 简体中文, 繁體中文, العربية, עברית, हिन्दी, Русский, 한국어, Nederlands, Türkçe, Українська, ไทย, Ελληνικά, Norsk, Svenska, Dansk, Íslenska.
- **Unicode localization** – Hindi, Russian, Korean, Dutch, Turkish, Ukrainian, Thai, Greek, Norwegian, Swedish, Danish and Icelandic use left-to-right layouts. Translation catalogs are generated offline with checks for missing entries, format parameters and separators.
- **Skinnable UI** – AlphaSkins themes and adjustable UI scaling (PPI) for high-DPI monitors.

Current version: **FastFile Professional 3.0.5.268** (2026-11-02) — see [src/CHANGELOG_IMPLEMENTACOES.md](src/CHANGELOG_IMPLEMENTACOES.md).

## glob / grep quick start

```text
grep "casa"
grep -i "casa" --limit 500
glob "*.txt"
grep "casa" "C:\dados\arquivo grande.txt"
glob "*.txt" "C:\dados\arquivo grande.txt"
```

The file operand is **optional**: main-window/Assistant/typed-agent commands use
the filename field first. An explicit file is validated and loaded before the
command runs; invalid paths produce errors. `glob` matches paths, not content.
AI-generated suggestions never execute automatically; diagnosis/model tools
remain restricted to their authorized sources.

Content searches read blocks, stop at the hit cap and report partial results.
Each physical line is limited to **16,777,216 decoded characters**, with an
explicit error on overflow. Sparse **80 GiB** regression fixtures verify
64-bit positions, glob, early-hit termination, cancellation and GUI Instant
Open—not full-file throughput. The existing opening policy is preserved:
choose **Instant Open** to avoid initial indexing of giant files.

See the [full command guide](src/README.md#internal-glob--grep-commands)
and general **F1** help (28 languages). Internal history entries **.240–.244**
separate commands, modal AI, launchers, optional-file validation and column
sort. Entries **.245–.249** add compact bars, command history, split preview,
visible line limits, regex examples and recent languages. Entries **.250–.254**
add right-to-left layout, Arabic and Hebrew, language flags and Equal parts
on the main toolbar. Entries **.255–.261** expand localization to 22 languages,
keep equal-parts processing on mapped chunks, localize the editing context
menu, and add a polished, reusable next-steps guide with improved Preferences.
Entries **.262–.265** add Thai, Greek, Norwegian, Swedish, Danish and Icelandic
(28 languages), a button to the left of Copy that reopens the next-steps guide,
and next steps that follow the current activity, with more follow-up actions.

## Requirements

| Item | Details |
|------|---------|
| OS | Windows 7 or later (Win64 recommended; Win32 also supported) |
| IDE | Embarcadero Delphi 10.4.2 Sydney (`src/FastFile.dproj`). Legacy Delphi 7 build is still kept (`src/FastFile.dpr`). |
| AlphaControls | Commercial VCL suite – **not included** in this repository. Expected at `..\..\acnt_reg` relative to `src` (see `DCC_UnitSearchPath` in the project). Get it from [alphaskins.com](https://www.alphaskins.com/). |
| FindFile | Component expected at `..\..\Findfile` relative to `src`. |
| FastMM4 / FastCode | Included (`src/FastMM4-master`, `src/FastCode.Libraries-0.6.4`). |

## Building

1. Install AlphaControls and make sure the paths above resolve (or adjust the unit search path in the project options).
2. Open `src/FastFile.dproj` in Delphi 10.4.2.
3. Select platform **Win64** (or Win32) and build.
4. The executable is written to `src/Build/<Platform>/FastFile.exe`.

Command-line build:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\rsvars.bat"
cd src
msbuild FastFile.dproj /t:Build /p:Config=Release /p:Platform=Win64
```

On first run FastFile Professional extracts its default configuration (`ASkin.ini`), skins and assets from embedded
resources into the executable folder.

## Repository layout

| Path | Contents |
|------|----------|
| `src/` | Delphi sources, forms, resources and the project files |
| `src/README.md` | Detailed technical documentation (architecture, threading, indexing, INI keys, AI plugins) |
| `Skins/` | AlphaSkins themes |
| `Images/`, `Resources/` | Icons and image assets |
| `Docs/` | Notes and documentation |
| `tools/` | Helper scripts (i18n, encoding maintenance) |

## Documentation

See **[src/README.md](src/README.md)** for in-depth technical documentation: core units, threading model,
index file format, Zero Scan decision logic, atomic writes, diff engine, internationalization and
configuration keys.

## License

See [src/LICENSE](src/LICENSE).

Copyright © 2025–2026 Hamden Vogel.
