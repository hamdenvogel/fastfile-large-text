# FastFile Web — SITE HANDOFF

Pacote de trabalho para atualizar o site institucional Laravel em  
`C:\xampp\htdocs\fastfile` a partir do material do produto (build **3.0.5.274**).

Isto **não** é uma release do EXE. É o “passar o bastão” conteúdo + prints + mapa de arquivos.

---

## 1. Fontes oficiais (workspace Delphi)

| Item | Caminho |
|---|---|
| Texto + galeria (EN, site-ready) | `Docs/website-en/FastFile-Professional-Features.md` |
| Prints 01–37 | `Docs/website-en/images/*.png` |
| Este handoff | `Docs/website-en/SITE_HANDOFF.md` |
| Versão no código | `src/UnConsts.pas` → `APPLICATION_VERSION = '3.0.5.274'` |

Cópia espelhada neste handoff (quando gerada):  
`C:\xampp\htdocs\fastfile\SITE_HANDOFF.md`  
Imagens sugeridas no site:  
`C:\xampp\htdocs\fastfile\public\images\screenshots\gallery\`

---

## 2. O que está desatualizado no site hoje

| Onde | Situação atual | Alvo |
|---|---|---|
| `config/fastfile.php` | `version` default `3.0.3.0` | **3.0.5.274** |
| `resources/lang/*/site.php` | “11 languages” em vários sítios | **30 UI languages** |
| Hero / what_is / proof | Tom e claims da apresentação antiga | Pitch do Features.md (honesto, sem exagero) |
| `HomeController` + gallery | ~10 prints com nomes `app-*.png` | Galeria **01–37** (ou subset curado) |
| `TODO_EVOLUCAO_SITE.md` | Badges “11 idiomas”, changelog 3.0.4 | Alinhar ao 3.0.5.274 / 30 idiomas |

---

## 3. Arquivos Laravel a tocar

1. `config/fastfile.php` — `version` (+ `.env` `FASTFILE_VERSION` se existir)  
2. `resources/lang/en/site.php` — meta, hero, proof, what_is, features, compare, download, **screenshots**  
3. `resources/lang/pt/site.php` — espelho PT-BR dos mesmos blocos  
4. `app/Http/Controllers/HomeController.php` — mapa `key => arquivo.png` da galeria  
5. `public/images/screenshots/gallery/` — copiar os 37 PNGs (ou o subset escolhido)  
6. (opcional) `TODO_EVOLUCAO_SITE.md` — marcar itens cobertos por este handoff  

Views (`home/index.blade.php`) só mudam se a estrutura da galeria/hero precisar de mais campos; o modelo atual (`alt`, `caption`, `eyebrow`, `hint`, `summary`, `details[]`) já serve.

---

## 4. Pitch pronto (EN) — colar / adaptar em `site.php`

Use o tom de `FastFile-Professional-Features.md` (não o texto inflamado da apresentação antiga).

**Tagline / product line**

> Professional editor for huge text files

**Hero / lead (sugerido)**

> FastFile Professional is a native Windows desktop product for multi-gigabyte logs, CSV/TSV exports, SQL dumps, and other production extracts. It does not load the whole file into RAM. A compact line-offset index and memory-mapped I/O (MMF) let you open, scroll, search, and edit only the windows you need.

**Audience**

> Built for analysts, DBAs, developers, and support teams: atomic writes, session history, Python macros, an AI agent that writes only after you accept, AI diagnosis that only reads, data anonymization with preview, and a 30-language UI with RTL for Arabic and Hebrew.

**Proof chip (exemplo verificável da galeria)**

> 165,062-line CSV · ~131–144 ms open · 1 read thread · Notes Plastic · English UI

**Idiomas (substituir “11”)**

> 30 UI languages (EN, PT-BR, PT-PT, ES, FR, DE, IT, PL, RO, HU, CS, JA, ZH-CN, ZH-TW, AR, HE, HI, RU, KO, NL, TR, UK, TH, EL, NB, SV, DA, IS, FI, VI). Arabic and Hebrew use RTL chrome; file text stays LTR.

**AI — contrato claro (evitar misturar papéis)**

- **AI diagnosis** — read-only review of files/folders.  
- **AI agent** — proposes edits; nothing is written until the user accepts.  
- (Se o site ainda destacar Chat SQL / RAG antigos, manter só se o build 3.0.5.274 ainda expuser isso na UI; caso contrário, priorizar agent + diagnosis + Talk with AI nos prints novos.)

---

## 5. Checklist de implementação (workspace do site)

- [ ] Abrir workspace `C:\xampp\htdocs\fastfile`  
- [ ] Confirmar que `SITE_HANDOFF.md` e `public/images/screenshots/gallery/` existem  
- [ ] Atualizar versão em `config/fastfile.php` / `.env` → `3.0.5.274`  
- [ ] Reescrever EN `site.php` (hero, proof, what_is, features, compare rows, download meta)  
- [ ] Traduzir/espelhar PT `site.php`  
- [ ] Substituir bloco `screenshots` + `HomeController::$shotKeys`  
- [ ] Testar `http://localhost/fastfile` (EN + PT)  
- [ ] Hero carousel + secção Gallery usam os novos prints  
- [ ] Remover ou arquivar prints `app-*.png` antigos quando não forem mais referenciados  

**Prompt sugerido no Agent (site):**

> Apply `SITE_HANDOFF.md`: set version 3.0.5.274, update en/pt `site.php` from the pitch and gallery map, wire `HomeController` to `public/images/screenshots/gallery/01-….png` through `37-….png` (or the curated subset), replace “11 languages” with 30.

---

## 6. Mapa da galeria (01–37)

Cada linha: **arquivo** → título curto → caption EN sugerida (1 linha).  
Texto longo: secção correspondente em `FastFile-Professional-Features.md`.

| # | File | Title | Caption (EN) |
|---|---|---|---|
| 01 | `01-main-workspace.png` | Main form | Idle home with top toolbar, skins and Custom PPI |
| 02 | `02-recent-files.png` | Recent files | Recent files/folders with Session Saved restore |
| 03 | `03-read-file.png` | Read file | 165,062-line CSV open in ~144 ms on one thread |
| 04 | `04-word-wrap.png` | Word Wrap | Long CSV rows folded without losing line numbers |
| 05 | `05-select-checkbox.png` | Select (checkbox list) | Multi-line checkboxes for export, AI and macros |
| 06 | `06-context-menu.png` | Context menu | Right-click line actions with shortcuts |
| 07 | `07-ui-scale-ppi.png` | UI scale (PPI) | Custom PPI / Auto scaling for high-DPI monitors |
| 08 | `08-ui-languages.png` | 30 UI languages | Recent languages picker with flags and search |
| 09 | `09-rtl-ui.png` | RTL UI | Arabic chrome mirrored; file text stays LTR |
| 10 | `10-help-reference.png` | Help | Help & Feature Reference for v3.0.5.274 |
| 11 | `11-about-license.png` | About / GPL | Branded About with GNU GPL v3 text |
| 12 | `12-about-fastfile.png` | About Professional | Version, build time, developer contact |
| 13 | `13-search-tools.png` | Search tools | Find, Filter/Grep and Bookmarks in one menu |
| 14 | `14-find-occurrences.png` | Find (Occurrences) | Occurrences panel with highlighted match |
| 15 | `15-filter.png` | Filter | Filter `ana paula` keeps original line numbers |
| 16 | `16-grep-glob.png` | glob / grep | Built-in commands — no external shell |
| 17 | `17-bookmarks.png` | Bookmarks | Marked lines with Prev/Next and export |
| 18 | `18-compare-session-history.png` | Compare / merge | Session history with Apply (equal rows skipped) |
| 19 | `19-equal-parts.png` | Equal parts | Split into N LF-safe parts (`part_N_of_M`) |
| 20 | `20-split-by-lines.png` | Split by lines | Copy line range 1–20,000 without full load |
| 21 | `21-file-created.png` | File created | Shared success dialog after a write |
| 22 | `22-merge-files.png` | Merge files | Insert source into destination (or reunite parts) |
| 23 | `23-merge-lines.png` | Merge lines | Stage line replacements, then Merge |
| 24 | `24-pattern-regex.png` | Split by Pattern/Regex | VBScript.RegExp split with AI pattern help |
| 25 | `25-more-tools.png` | More tools | Pattern, equal parts, extract, Find Files, skins |
| 26 | `26-python-macro.png` | Python macros | `transform(line, ctx)` beside Script Examples |
| 27 | `27-python-preview.png` | Script preview | Original vs Result before Generate output |
| 28 | `28-tail-macro.png` | Tail mode | Follow growing files with macros / Talk with AI |
| 29 | `29-ai-diagnosis.png` | AI diagnosis | Read-only review; does not change files |
| 30 | `30-ai-agent.png` | AI agent | Proposals first — write only after accept |
| 31 | `31-extract-frequent-strings.png` | Extract Frequent Strings | Count lines/words/cells without full RAM load |
| 32 | `32-delete-duplicate-lines.png` | Delete Duplicate Lines | Keep first key (whole line or CSV column) |
| 33 | `33-anonymize.png` | Anonymize | Preview Original vs Anonymized before commit |
| 34 | `34-insert-multiple-lines.png` | Insert multiple lines | Blank, repeated, or per-line text insert |
| 35 | `35-csv-column-mode.png` | CSV / Column mode | Delimited file as a column grid |
| 36 | `36-preferences.png` | Preferences | Visible limits for MRU, AI, anonymize, export |
| 37 | `37-session-menu.png` | Session menu | Read-only, save/load, ask AI about session |

### Subset sugerido para o hero (se 37 for demais de uma vez)

Ordem recomendada no carrossel (~12 slides):

`01`, `03`, `14`, `15`, `18`, `22`, `24`, `26`, `29`, `30`, `33`, `08`  
(resto na secção Gallery completa ou “Ver todos”.)

### Exemplo de wiring no `HomeController`

```php
$shotKeys = [
    'main' => 'gallery/01-main-workspace.png',
    'recent' => 'gallery/02-recent-files.png',
    'read' => 'gallery/03-read-file.png',
    // … até 37, ou só o subset do hero
];
// asset('images/screenshots/'.$file)
```

Chaves em `site.screenshots.*` devem bater com as keys do array. Pode renomear keys para `s01_main`, `s02_recent`, etc., desde que EN e PT tenham o mesmo conjunto.

Estrutura por item (já usada no site):

```php
'key_name' => [
    'alt' => '...',
    'caption' => '...',
    'eyebrow' => '...',
    'hint' => '...',
    'summary' => '...',
    'details' => ['...', '...'],
],
```

`summary` ≈ 1º parágrafo da secção no Features.md; `details` ≈ 2–3 bullets curtos.

---

## 7. Tom e regras de copy

- Inglês americano no site EN; PT-BR no site PT.  
- Sem sensacionalismo (“imbatível”, “zero segundos” absoluto). Preferir factos mensuráveis da galeria.  
- Manter distinção **diagnosis (só lê)** vs **agent (propõe / aceita)**.  
- “11 idiomas” → **30**.  
- Skins: Notes Plastic é a usada nos prints; mencionar skins AlphaSkins + Custom PPI.  

---

## 8. Depois do handoff

1. Abrir o workspace do site.  
2. Aplicar a checklist da §5.  
3. Se faltar PT para alguma caption, traduzir a partir do EN (não inventar features).  
4. Opcional: apontar `FASTFILE_VERSION` no `.env` e documentar no README do site.

---

*Gerado a partir de FastFile Professional 3.0.5.274 · Docs/website-en*
