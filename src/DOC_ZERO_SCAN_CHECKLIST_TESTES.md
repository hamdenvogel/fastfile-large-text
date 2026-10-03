# FastFile — Checklist de testes: Zero Scan

**Versão de referência:** v2.1.7.25+ (fases A–D, E1–E5; Shift+End / extrair partes v2.1.7.27–28)  
**Ambiente:** Delphi 7 / Win32  
**Documentação relacionada:**

- [DOC_ZS_ATALHOS.md](DOC_ZS_ATALHOS.md) — atalhos F1 × Zero Scan ON (referência)
- [DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md) — matriz de impactos, níveis ZS-0..3
- [DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md) — especificação técnica A–D
- [DOC_SEGMENTED_HEAVY_OPS.md](DOC_SEGMENTED_HEAVY_OPS.md) — Replace All / delete em lote (ortogonal)
- [README.md](README.md) — Force Zero Scan, F5, INI

---

## Como usar este documento

1. Marque cada item na coluna **OK** (`[x]` em Markdown ou à mão).
2. Execute primeiro a **secção B** (regressão modo indexado) — se falhar, pare antes dos testes Zero Scan.
3. Use **cópias** de ficheiros para testes de edição, Replace All e delete em lote.
4. Anote falhas na **secção O** (modelo no fim).

---

## A. Preparação

| # | Passo | OK |
|---|--------|-----|
| A1 | Compilar a versão actual (inclui fix `FlushBuffer` em `UnBufferedTextWriter.pas`). | ☐ |
| A2 | Fechar o FastFile; opcionalmente apagar junto ao `.exe`: `temp.txt`, `temp_ckpt.txt`, `temp_blk.idx`, `temp_filter_hits.bin`. | ☐ |
| A3 | Ter ficheiros de teste: **pequeno** (1–5 MB), **médio** (~80 MB), **grande** (≥15 GB ou Force Zero Scan no médio). | ☐ |
| A4 | Anotar pasta do executável (local dos `temp.*`). | ☐ |

---

## B. Regressão — modo indexado normal (SEM Zero Scan)

**Objectivo:** ficheiros “pequenos/médios” não regrediram após trabalho Zero Scan.

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| B1 | **View → Force Zero Scan Mode** — **desmarcado**. | Menu unchecked | ☐ |
| B2 | Abrir ficheiro **~80 MB** (F5 ou arrastar). | Barra “Reading file…”; **sem** stack overflow | ☐ |
| B3 | Após abrir: `temp.txt` e `temp_ckpt.txt` junto ao `.exe`. | Ficheiros criados | ☐ |
| B4 | Scroll ListView — linhas **exactas**. | Texto coerente | ☐ |
| B5 | **Ctrl+F** → termo conhecido → **F3** / **Shift+F3**. | Navegação correcta | ☐ |
| B6 | **Ctrl+L** → filtro → modo filtrado. | Filtro clássico (`TFilterThread`) | ☐ |
| B7 | **Ctrl+H** → Replace **uma** ocorrência. | Substituição OK | ☐ |
| B8 | **Ctrl+Shift+P** ou **Ctrl+Shift+Q** em **cópia** do ficheiro. | Partes LF-safe geradas | ☐ |

**Se B2 falhar:** regressão no modo normal — não avançar para Zero Scan.

**Regressão rápida pós-alterações Zero Scan:** com Force Zero Scan **OFF**, repetir B4–B8; confirmar que `UsesProportionalZeroScanScroll` está **false** (existe `temp.txt` após F5) e que Shift+End / Ctrl+G usam o caminho indexado (`gotoLine`), não `GotoPhysicalLine1Based`.

---

## C. Zero Scan — abertura instantânea (ZS-0)

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| C1 | **View → Force Zero Scan** — **marcado**. | Checked | ☐ |
| C2 | Abrir o **mesmo ficheiro ~80 MB**. | Rápido; “Instant Open (Zero Scan)” | ☐ |
| C3 | Sem indexação longa na abertura. | Sem barra de leitura completa | ☐ |
| C4 | **Sem** `temp.txt` logo após abrir. | Só scroll proporcional | ☐ |
| C5 | Scroll barra / roda. | Linhas **aproximadas** | ☐ |
| C6 | **Ctrl+G** → linha 1000 (ou outra). | Posição **estimada**; aviso na barra | ☐ |
| C7 | **Shift+Home** / **Shift+End**. | Início / fim da lista virtual | ☐ |

---

## D. Pesquisa sem índice — Fase A (bytes)

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| D1 | **Ctrl+F** (sem indexar antes). | Diálogo **YES / NO / CANCEL** | ☐ |
| D2 | Escolher **NO** (busca por bytes). | Busca com progresso | ☐ |
| D3 | Termo que **existe**. | Match; ListView move | ☐ |
| D4 | **F3** e **Shift+F3**. | Próxima / anterior | ☐ |
| D5 | Barra de status: bytes + linha **~estimada**. | Valores coerentes | ☐ |
| D6 | **Ctrl+Shift+G** (se disponível). | Salto por byte | ☐ |
| D7 | Termo inexistente. | Não encontrado; sem crash | ☐ |

---

## E. Indexação sob demanda — Fase B (ZS-2 / ZS-3)

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| E1 | Reabrir com Force Zero Scan ON (estado limpo). | Instantâneo | ☐ |
| E2 | **Ctrl+F** → **YES** (indexar para busca precisa). | Barra de indexação | ☐ |
| E3 | Aguardar fim. | Sem stack overflow | ☐ |
| E4 | Disco: `temp_ckpt.txt`; em 80 MB pode haver `temp.txt`. | Ficheiros criados | ☐ |
| E5 | **Ctrl+F** + **F3** após indexar. | Linha **exacta** | ☐ |
| E6 | **Ctrl+G** → linha específica. | Linha **exacta** | ☐ |
| E7 | Scroll mais fiável com índice. | Menos “saltos” proporcionais | ☐ |
| E8 | (Opcional) `temp_blk.idx` presente → nova busca. | Find MMF + hint bloco (E1) | ☐ |

---

## F. Filtro — Fase C + E2 (ZS-1)

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| F1 | **Ctrl+L** sem `temp.txt` (só instantâneo). | Diálogo; pode pedir indexação | ☐ |
| F2 | Padrão com poucos hits. | ListView só com matches | ☐ |
| F3 | `temp_filter_hits.bin` no disco (se scroll proporcional). | Ficheiro criado | ☐ |
| F4 | Sair do filtro / exportar. | Sem crash | ☐ |
| F5 | **Ctrl+L** após secção E (com ckpt). | Filtro mais exacto | ☐ |

---

## G. Substituir — Ctrl+H (Fase B + D)

**Usar cópia do ficheiro.**

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| G1 | Zero Scan sem índice: **Ctrl+H** → Replace **uma**. | Diálogo; indexar ou bytes | ☐ |
| G2 | Substituir **uma** ocorrência única. | Uma substituição OK | ☐ |
| G3 | **Replace All** — texto raro, poucas ocorrências. | Progresso; RAM estável | ☐ |
| G4 | Após mutação: reindex (E3) ou aviso na barra. | Índice actualizado | ☐ |
| G5 | **Ctrl+F** no texto **novo**. | Encontra alteração | ☐ |

---

## H. Edição de linha (ZS-0 / ZS-2)

**Usar cópia do ficheiro.**

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| H1 | Duplo-clique numa linha (sem índice). | Editor ou pedido indexar | ☐ |
| H2 | **Ctrl+Shift+E** — editar linha. | Edição ou diálogo | ☐ |
| H3 | Alterar texto → confirmar. | Gravação sem crash | ☐ |
| H4 | **Ctrl+Z** undo. | Reverte | ☐ |
| H5 | **Ctrl+Shift+I** / **Ctrl+Shift+D** — uma linha. | OK ou pedido indexar | ☐ |
| H6 | Repetir H2–H5 **após** secção E. | Linha exacta; undo OK | ☐ |

---

## I. Bookmarks — E4

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| I1 | **Ctrl+B** ou **F2** na linha actual. | Bookmark definido | ☐ |
| I2 | Scroll longe → **Shift+F2**. | Volta ao marcador | ☐ |
| I3 | Com `temp_blk.idx`: bookmark + **Ctrl+G**. | Navegação coerente | ☐ |

---

## J. Tail / Follow — E5

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| J1 | Ficheiro log em crescimento (append externo). | — | ☐ |
| J2 | **Ctrl+T** ou menu Tail. | Tail activo | ☐ |
| J3 | Acrescentar linhas ao fim e guardar. | Detecta crescimento | ☐ |
| J4 | Novas linhas na ListView; auto-scroll. | Append visível | ☐ |
| J5 | Com `temp_ckpt` após E: append incremental. | ckpt actualizado | ☐ |
| J6 | Desactivar Tail. | Para sem crash | ☐ |

---

## K. F5 e política de abertura

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| K1 | Force Zero Scan **ON** → **F5**. | Continua instantâneo | ☐ |
| K2 | Force Zero Scan **OFF** → **F5** (80 MB). | Indexação completa (B) | ☐ |
| K3 | Ficheiro ≥15 GB, Force Zero Scan **OFF** (se disponível). | Instantâneo automático | ☐ |

---

## L. Apagar em lote + segmentado (limitações conhecidas)

| # | Passo | Resultado esperado | OK |
|---|--------|-------------------|-----|
| L1 | Zero Scan **sem** `temp.txt`: Select + delete lote. | Pode pedir indexação — **anotar** | ☐ |
| L2 | Com **`temp.txt` denso**: delete lote grande. | Segmentado ou fallback | ☐ |
| L3 | Replace All grande com `temp.txt`. | `EffectiveUseSegmentedHeavyOps` | ☐ |

---

## M. Ficheiros em disco — referência

| Ficheiro | Quando deve existir |
|----------|---------------------|
| `temp.txt` | Modo indexado (B) ou indexação sob demanda com denso (E) |
| `temp_ckpt.txt` | Indexação normal ou sob demanda |
| `temp_blk.idx` | Indexação Zero Scan sob demanda (E1, blocos 64 MB) |
| `temp_filter_hits.bin` | Após **Ctrl+L** em scroll proporcional (E2) |

---

## N. Resumo dos níveis ZS

| Nível | Capacidades validadas | OK |
|-------|----------------------|-----|
| **ZS-0** | Instantâneo + Ctrl+F (NO) + scroll proporcional | ☐ |
| **ZS-1** | + Ctrl+L + `temp_filter_hits.bin` | ☐ |
| **ZS-2** | + YES indexar + `temp_ckpt` + Find exacto | ☐ |
| **ZS-3** | + `temp.txt` + filtro clássico / segmentado | ☐ |

---

## O. Registo de problemas

| Data | Passo | Ficheiro | Force ZS | temp.* no disco | Comportamento / erro |
|------|-------|----------|----------|-----------------|----------------------|
| | | | ON / OFF | | |
| | | | | | |
| | | | | | |

---

## P. Ordem sugerida (1 sessão, ~45–90 min)

| Ordem | Secção | Tempo aprox. |
|-------|--------|--------------|
| 1 | **B** — Regressão modo normal | 15 min |
| 2 | **C** — Abertura Zero Scan | 5 min |
| 3 | **D** — Find bytes | 10 min |
| 4 | **E** — Indexar sob demanda | 15 min |
| 5 | **F** — Filtro | 10 min |
| 6 | **G** — Replace (cópia) | 10 min |
| 7 | **H, I, J** | conforme tempo |
| 8 | **K, L** | 10 min |

---

## Q. Fora do âmbito Zero Scan (testar à parte)

Estas funcionalidades **não** dependem do modo Zero Scan; validar na secção **B8** ou em sessão separada:

| Atalho | Função |
|--------|--------|
| **Ctrl+Shift+P** | Dividir em partes iguais (LF-safe) |
| **Ctrl+Shift+Q** | Extrair partes do arquivo |
| Merge / split / export | Operações em ficheiro |

---

## R. Atalhos Zero Scan (referência rápida)

| Atalho | Zero Scan sem índice |
|--------|----------------------|
| **Ctrl+F** / **F3** / **Shift+F3** | Busca; YES=indexar / NO=bytes |
| **Ctrl+H** | Replace; Replace All streaming |
| **Ctrl+L** | `TFilterStreamThread` |
| **Ctrl+G** | Linha estimada |
| **Ctrl+Shift+G** | Posição byte |
| **Ctrl+Z / Ctrl+Y** | Undo/redo |
| **Ctrl+Shift+E/I/U/D** | Edição (pode pedir indexar) |
| **Ctrl+B / F2 / Shift+F2** | Bookmarks |
| **Ctrl+T** | Tail |
| **F5** | Instantâneo se Force Zero Scan ON |

Detalhe completo: [DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md §13](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md#13-atalhos-do-painel-read-com-zero-scan).

---

*Histórico: 2026-05-23 — checklist inicial para QA Zero Scan.*
