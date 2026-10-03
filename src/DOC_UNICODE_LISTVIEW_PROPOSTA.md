# FastFile — Proposta: exibição Unicode (CJK / japonês) na ListView (Delphi 7)

**Data:** 23 de maio de 2026  
**Contexto:** Limitação actual da coluna **Content** da ListView com caracteres fora da code page ANSI do Windows (ex.: japonês, chinês, coreano).

---

## 1. Diagnóstico

### Como funciona hoje

- FastFile é **Delphi 7 / VCL ANSI**: a `ListView` recebe `string` (= AnsiString), não Unicode nativo.
- Fluxo de exibição:
  1. Lê **bytes brutos** da linha (MMF + índice `temp.txt`).
  2. Converte com `DisplayTextFromFileBytes` (`uTextEncoding.pas`) conforme **encoding de exibição** (`EffectiveDisplayEncoding` — combo na status bar).
  3. Para UTF-8 / UTF-16: **bytes → WideString → `WideStringToAnsiACP` (CP_ACP) → `Item.SubItems[0]`**.

### O que quebra

O gargalo **não** é a leitura do ficheiro; é a conversão final para **CP_ACP**:

- Num Windows PT-BR / ocidental (CP1252), kanji/hiragana **não cabem** em ANSI → aparecem `?`, quadrados ou mojibake.
- A ListView VCL do D7 só pinta texto ANSI nos `SubItems`.

### Encodings suportados hoje (visualização)

| Encoding | Suporte |
|----------|---------|
| UTF-8 (BOM / heurística) | Sim |
| UTF-16 LE / BE | Sim |
| ANSI (bytes crus) | Sim |
| Shift-JIS, EUC-JP, GBK nativos | **Não** (sem opção dedicada) |
| UTF-32 | Detectado no cabeçalho, **não** convertido na exibição |

### O que já funciona parcialmente

- **Abrir e indexar** ficheiros UTF-8 com CJK (bytes preservados no disco).
- **Clipboard:** `CF_UNICODETEXT` via `ClipboardSetUnicodeText` — Unicode completo ao copiar.
- Combo **DEFAULT / UTF-8 / ANSI / UTF-16 LE / UTF-16 BE** na status bar.

---

## 2. Proposta recomendada (3 fases)

### Fase 1 — “Unicode na pintura” (melhor custo/benefício)

**Ideia:** manter leitura/indexação actuais; **não** converter para CP_ACP para exibir; pintar em **WideChar** na coluna Content.

1. **`GetLineContentWide`** (ou cache wide por página):
   - Lê bytes da linha (como hoje).
   - Converte para **`WideString`** (UTF-8 / UTF-16).
   - **Não** chama `WideStringToAnsiACP` para exibição.

2. **Owner-draw na coluna Content** (`ListView1AdvancedCustomDrawSubItem` — já usado para word wrap, bookmarks, busca):
   - Usar **`DrawTextW` / `ExtTextOutW`** com a `WideString`.
   - Fonte com cobertura CJK: Segoe UI, Yu Gothic UI, MS Gothic (fallback GDI).

3. **`SubItems[0]`** passa a secundário:
   - Placeholder ASCII, ou versão ACP “best effort” só para APIs legadas.

4. Alinhar **busca realce, CSV, filtro, undo** para operar em **WideString ou UTF-8**, não no texto ANSI truncado da coluna.

**Vantagens:** japonês/CJK visível em Windows ocidental **sem migrar Delphi**; diff localizado (`uTextEncoding`, `GetLineContent`, custom draw, cache).

**Ficheiros prováveis:** `uTextEncoding.pas`, `MainUnit.pas` (`GetLineContent`, `getLineContentsFromLineIndex`, `ListView1AdvancedCustomDrawSubItem`, cache de página).

---

### Fase 2 — Encodings de ficheiro legados

Alargar `DisplayTextFromFileBytes` + combo da status bar:

| Encoding | Code page / API |
|----------|-----------------|
| Shift-JIS (Japonês) | CP 932 — `MultiByteToWideChar(932, ...)` |
| EUC-JP | CP 20932 ou conversão dedicada |
| GBK / GB2312 | CP 936 |
| Big5 (tradicional) | CP 950 |

Resolve ficheiros **japoneses antigos** que não estão em UTF-8.

---

### Fase 3 — Opções estruturais (longo prazo)

| Opção | Prós | Contras |
|-------|------|---------|
| Migrar para **Delphi Unicode (2009+)** | `string` = UTF-16; VCL nativo | Recompilar stack, AlphaSkins, regressões |
| **Grid virtual wide** custom | Controlo total | Muito trabalho |
| Só **export / visualizador wide** | Rápido | Edição na grelha limitada |

**Recomendação:** Fase 1 + Fase 2 antes de considerar migração de IDE.

---

## 3. Fluxo técnico sugerido (Fase 1)

```
Ficheiro (bytes)
    ↓
Decode por encoding escolhido → WideString  ← fonte de verdade para UI
    ↓                              ↓
DrawTextW (ListView)          Clipboard (CF_UNICODETEXT)  ← clipboard já OK
    ↓
SubItems ANSI (opcional / legado)
```

### Refactor em `uTextEncoding.pas`

- Separar **`FileBytesToWideString(Raw, DisplayEncoding): WideString`** (sem ACP).
- Manter **`WideStringToAnsiACP`** apenas onde for inevitável (controles ANSI legados).

---

## 4. Alternativa só ambiente (sem alterar código)

**Windows 10/11:** “Beta: Use Unicode UTF-8 for worldwide language support” (locale UTF-8) pode fazer `CP_ACP` comportar-se como UTF-8 e melhorar `WideStringToAnsiACP`.

- **Frágil:** depende do SO e configuração do utilizador.
- **Não substitui** owner-draw wide de forma fiável.

---

## 5. Resumo executivo

| Pergunta | Resposta |
|----------|----------|
| A ListView “suporta Unicode”? | Parcialmente: lê UTF-8/UTF-16, mas **exibe** via ANSI (CP_ACP). |
| Japonês em UTF-8 no Windows PT-BR? | **Provavelmente mal** na grelha; clipboard pode estar correcto. |
| Solução proposta | **Fase 1:** decode wide + **`DrawTextW`** no owner-draw da coluna Content. |
| Próximo passo | Implementar Fase 1; depois Fase 2 se forem necessários Shift-JIS/EUC-JP. |

---

## 6. Referências no código

- `uTextEncoding.pas` — `DisplayTextFromFileBytes`, `Utf8AnsiToWideString`, `WideStringToAnsiACP`
- `MainUnit.pas` — `GetLineContent`, `EffectiveDisplayEncoding`, `DetectFileEncoding`, `ListView1Data`, `ListView1AdvancedCustomDrawSubItem`
- `CHANGELOG_IMPLEMENTACOES.md` — encoding v2.1.6.3 / v2.1.6.4 (detecção UTF-8, combo view encoding)
