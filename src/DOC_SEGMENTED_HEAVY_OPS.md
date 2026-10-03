# FastFile — Processamento segmentado por linhas (operações pesadas)

**Documento de arquitetura e operação**  
Versão do produto de referência: `2.1.7.21`  
Ambiente: Delphi 7 / Win32 (processo 32-bit)  
Unidades principais: `MainUnit.pas`, `uSmoothLoading.pas`

> **Documentos relacionados**  
> - [ROADMAP_COMERCIAL_FASTFILE.md](ROADMAP_COMERCIAL_FASTFILE.md) — apêndice resumido + posicionamento de produto  
> - [ARQUITETURA_TECNICA_FASTFILE.md](ARQUITETURA_TECNICA_FASTFILE.md) § 4.1.1 — referência rápida (`EffectiveUseSegmentedHeavyOps`)  
> - [fastfile_arquitetura_bigdata.md](fastfile_arquitetura_bigdata.md) § 4.1 — contraste com Zero Scan  
> - [DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md) — abertura/navegação sem índice (tema **ortogonal**)  
> - [DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md) — impactos e compatibilidade Zero Scan × segmentado (resumo decisão)

---

## Índice

1. [Objetivo deste documento](#1-objetivo-deste-documento)
2. [Glossário](#2-glossário)
3. [O que é e o que não é](#3-o-que-é-e-o-que-não-é) — incl. [§3.3 escopo (não é só GB)](#33-escopo-exacto-duas-operações-vários-tamanhos-de-ficheiro)
4. [EffectiveUseSegmentedHeavyOps — função central](#4-effectiveusesegmentedheavyops--funcao-central)
5. [Política do utilizador (Opções e INI)](#5-política-do-utilizador-opções-e-ini)
6. [Fluxo técnico por operação](#6-fluxo-técnico-por-operação)
7. [Algoritmo de segmentação no disco](#7-algoritmo-de-segmentação-no-disco)
8. [Limitações e riscos](#8-limitações-e-riscos)
9. [Comparação com Zero Scan](#9-comparação-com-zero-scan)
10. [Interface do utilizador](#10-interface-do-utilizador)
11. [Mapa de símbolos no código](#11-mapa-de-símbolos-no-código)
12. [Perguntas frequentes](#12-perguntas-frequentes)

---

## 1. Objetivo deste documento

Registar de forma **minuciosa** o modo **processamento segmentado por linhas** usado em operações que **reescrevem** ficheiros muito grandes:

| Operação | Atalho / entrada típica |
|----------|-------------------------|
| **Substituir tudo** | Find & Replace → **Ctrl+H** → Replace All |
| **Apagar linhas assinaladas** | Modo Select (**Ctrl+Shift+S**) + delete em lote |

O documento explica:

- como o programa **decide** usar ou não o caminho segmentado (`EffectiveUseSegmentedHeavyOps`);
- como o utilizador **força** ou **desactiva** o comportamento (Opções + INI);
- limitações (fronteira de segmento, disco, índice `temp.txt`);
- onde está o código e como fazer manutenção **sem duplicar** condições espalhadas no `MainUnit.pas`.

**Não cobre:** abertura instantânea (Zero Scan), scroll, filtro visual, tail — ver documento Zero Scan.

### Resposta rápida (escopo de `EffectiveUseSegmentedHeavyOps`)

| Pergunta | Resposta |
|----------|----------|
| Serve **só** para Replace All e delete em lote? | **Sim.** São as **únicas** operações que consultam esta função. |
| Serve **só** para ficheiros na casa dos **GB**? | **Não.** GB é um caso frequente, mas o automático activa-se desde **>100 MB**, **>500 000 linhas** no ficheiro, ou **≥200 linhas** na operação (ex.: muitas linhas marcadas para apagar). |
| Abre ficheiros grandes mais rápido? | **Não.** Isso é **Zero Scan** (outra decisão: `ShouldOpenWithInstantZeroScan`). |

---

## 2. Glossário

| Termo | Significado |
|-------|-------------|
| **Modo segmentado** | Processar o ficheiro em **partes alinhadas a linhas** (segmentos), com temporários, depois **merge** + rename atómico. |
| **`EffectiveUseSegmentedHeavyOps`** | Função em `MainUnit.pas` que devolve `True`/`False` para **uma operação concreta** — hoje **só** Replace All e delete em lote; **não** mede “GB” directamente. |
| **`FForceSegmentHeavyOps`** | “Forçar modo segmentado” em Opções; quando `True`, a função acima devolve sempre `True`. |
| **`FSegmentHeavyOpsPolicy`** | `shpAuto` (recomendado), `shpAlwaysOn`, `shpAlwaysOff`. |
| **`LinesPerSegment`** | Tamanho do bloco em **linhas de índice**; Replace All usa **250 000**; delete usa o mesmo no thread. |
| **`TrySegmentedReplace`** | Método de `TReplaceAllThread` em `uSmoothLoading.pas`. |
| **`TrySegmentedBatchDelete`** | Função global em `uSmoothLoading.pas` para delete em lote. |
| **Índice denso** | `temp.txt` — 20 bytes por linha; **necessário** para o caminho segmentado (senão fallback). |
| **Fallback MMF** | Se segmentado falhar ou não for escolhido: `RunBatchDeleteLinesWait` / streaming normal no Replace. |

---

## 3. O que é e o que não é

### 3.1 O que faz

- Reduz o **pico de memória** ao aplicar Replace All ou apagar centenas/milhares de linhas em ficheiros de **centenas de MB ou milhões de linhas**.
- Trabalha por **faixas de números de linha** no índice (`LineStart` … `LineEnd`), extrai bytes do ficheiro fonte com `TFileStream`, grava partes em `NewFastFileTemp(...)`, concatena num merge e substitui o original quando possível.
- Mostra progresso no overlay **Smooth loading** quando a operação é considerada “pesada”.

### 3.2 O que não faz

| Não faz | Motivo |
|---------|--------|
| Acelerar **abertura** do ficheiro | Isso é Zero Scan / indexação SWAR |
| Melhorar **scroll** ou números de linha na ListView | Ortogonal |
| Garantir Replace All **100% completo** em todos os padrões | Match que **cruza** limite de segmento pode falhar |
| Substituir **índice** `temp.txt` | Depende dele para cortes por linha |

### 3.3 Escopo exacto: duas operações, vários tamanhos de ficheiro

**Mito comum:** “`EffectiveUseSegmentedHeavyOps` = Replace/Delete só para ficheiros de **GB**.”

**Realidade no código (v2.1.7.21):**

1. **Quais operações?** Apenas estas:
   - **Substituir tudo** (`TReplaceAllThread` + `TrySegmentedReplace`);
   - **Apagar linhas assinaladas em lote** no modo Select (`TrySegmentedBatchDelete`).

2. **Qual tamanho?** Depende da **política** e dos **três limiares** em modo automático (ver §4.3). Exemplos:
   - Ficheiro de **150 MB** + Replace All → automático pode ser `True` (>100 MB).
   - Ficheiro pequeno com **300 linhas** marcadas para apagar → automático pode ser `True` (≥200 linhas na operação).
   - Ficheiro de **2 GB** com política **nunca usar** e **Forçar** desligado → `False` (usa MMF/streaming normal).

**Operações que NÃO chamam `EffectiveUseSegmentedHeavyOps`:**

| Operação | Caminho habitual |
|----------|------------------|
| Abrir / F5 indexar | Zero Scan ou `TReadFileThread` |
| Ctrl+F / Find Next | `TFindInFileThread` (bytes no ficheiro) |
| Ctrl+L / Filtro | Bitset / índice (visualização) |
| Substituir **uma** linha (Replace, não All) | `TEditFileThread` / edição pontual |
| Insert / Edit / Duplicate / Delete **uma** linha | `TEditFileThread` |
| Export, Tail, merge de ficheiros, split | Outros workers |

Objectivo da função: **menor pico de RAM e de disco temporário** ao **reescrever** o ficheiro inteiro em operações pesadas — não é um “modo GB-only”.

---

## 4. EffectiveUseSegmentedHeavyOps — função central

### 4.1 Assinatura e contrato

```pascal
function TfrmMain.EffectiveUseSegmentedHeavyOps(
  const AFileSize, ALineCount, ALinesAffected: Int64): Boolean;
```

**Regra de manutenção:** qualquer código que precise saber “usar segmentado nesta operação?” deve chamar **só** esta função. Não repetir `if FileSize > …` noutros sítios.

### 4.2 Parâmetros nos call sites actuais

| Parâmetro | Origem típica | Replace All | Delete em lote |
|-----------|---------------|-------------|----------------|
| `AFileSize` | `GetFileSize(caminho)` | `EffPath` | `FileSizeBefore` |
| `ALineCount` | `totalLines` da sessão | `totalLines` | `totalLines` |
| `ALinesAffected` | Linhas da operação | **0** (não usa contagem de matches) | **`ToDelete.Count`** |

> **Nota:** Em Replace All, `ALinesAffected = 0` faz a heurística depender só de tamanho do ficheiro e `totalLines`, não do número de ocorrências a substituir.

### 4.3 Árvore de decisão (implementação actual)

```
┌─ FForceSegmentHeavyOps = True? ──SIM──► True   (qualquer tamanho de ficheiro)
│
NÃO
│
├─ FSegmentHeavyOpsPolicy = shpAlwaysOn? ──SIM──► True
├─ FSegmentHeavyOpsPolicy = shpAlwaysOff? ──SIM──► False   (excepto se Forçar=ON)
│
└─ shpAuto (recomendado):
      True se QUALQUER limiar abaixo (OR lógico — não precisa ser GB):
           ALinesAffected >= 200
           OR AFileSize > 100 MiB
           OR ALineCount > 500_000
```

**Nota:** não existe teste `if FileSize > 1 GB`. Ficheiros de **vários GB** quase sempre activam o automático por **>100 MB** e muitas vezes por **>500 000 linhas**, mas o critério é explícito em MB/linhas, não em “GB”.

Constantes embutidas em código (não estão no INI):

| Limiar | Valor |
|--------|-------|
| Tamanho mínimo “ficheiro grande” | `100 × 1024 × 1024` bytes |
| Linhas totais “ficheiro enorme” | `500_000` |
| Linhas afectadas na operação | `200` |

### 4.4 Tabela de call sites (MainUnit.pas)

| Procedimento / contexto | Linha de decisão | Se `True` |
|-------------------------|------------------|-----------|
| Delete linhas assinaladas | `UseSmoothProgress := EffectiveUseSegmentedHeavyOps(...)` | Overlay de progresso (também outros critérios OR) |
| Delete linhas assinaladas | `if EffectiveUseSegmentedHeavyOps(...)` | `RunSegmentedDeleteLinesWait` → `TrySegmentedBatchDelete` |
| Replace All — `MessageBox` confirmação | `iff(EffectiveUseSegmentedHeavyOps(...), aviso fronteira, '')` | Aviso extra ao utilizador |
| Replace All — thread | `TReplaceAllThread.Create(..., EffectiveUseSegmentedHeavyOps(...), ...)` | `TrySegmentedReplace` no `Execute` |

### 4.5 Função auxiliar de UI

`SegmentHeavyOpsPolicyCaption` — devolve texto legível da política (auto/sempre/nunca) para o painel de detalhes do ficheiro; **não** altera o resultado de `EffectiveUseSegmentedHeavyOps`.

---

## 5. Política do utilizador (Opções e INI)

### 5.1 Itens de menu (Opções)

| Item | Efeito |
|------|--------|
| **Forçar modo segmentado (ops. pesadas)** | Toggle `FForceSegmentHeavyOps`; persiste `SegmentHeavyOps` |
| **Ops. segmentadas: automático (recomendado)** | `FSegmentHeavyOpsPolicy := shpAuto` |
| **Ops. segmentadas: sempre usar** | Sempre `True` (excepto se código de operação ignorar — hoje não ignora) |
| **Ops. segmentadas: nunca usar** | Sempre `False`, **excepto** se **Forçar** estiver ligado |

Também disponível em: popup da ListView, menu Ferramentas (extras), sincronizado em `ApplySegmentHeavyOpsUiState`.

### 5.2 INI (`ASkin.ini`, secção da aplicação)

| Chave | Tipo | Default | Mapeamento |
|-------|------|---------|------------|
| `SegmentHeavyOps` | 0/1 | `0` | `FForceSegmentHeavyOps` |
| `SegmentHeavyOpsPolicy` | 0..2 | `0` | `0`=auto, `1`=sempre, `2`=nunca |

- **Leitura:** `FormShow` lê `SegmentHeavyOps`; `LoadSmartSearchPrefs` lê `SegmentHeavyOpsPolicy`.
- **Gravação:** toggle Forçar → `WriteIniStr`; política → `SaveSmartSearchPrefs`.

### 5.3 Tabela de decisão (utilizador + programa)

| Forçar | Política | Ficheiro 50 MB, 10k linhas, delete 5 linhas | Ficheiro 200 MB, Replace All |
|--------|----------|-----------------------------------------------|------------------------------|
| OFF | Auto | `False` (nenhum limiar) | `True` (>100 MB) |
| OFF | Sempre | `True` | `True` |
| OFF | Nunca | `False` | `False` |
| ON | qualquer | `True` | `True` |

---

## 6. Fluxo técnico por operação

### 6.1 Apagar linhas assinaladas (Select)

```
Utilizador confirma delete
    → EffectiveUseSegmentedHeavyOps(FileSize, totalLines, ToDelete.Count)
         False → CloseFileStreams → MMF / TEditFileThread (1 linha)
         True  → CloseFileStreams → TSegmentedDeleteLinesThread
                    → TrySegmentedBatchDelete(..., LinesPerSegment=250000)
                         OK → ApplyPostBatchDeleteRefresh
                         FAIL → reabre streams → fallback MMF
```

### 6.2 Substituir tudo

```
Utilizador confirma Replace All
    → EffectiveUseSegmentedHeavyOps(GetFileSize, totalLines, 0)
    → TReplaceAllThread.Create(..., UseSegmented, IndexPath=temp.txt, 250000, ...)
         Execute → se UseSegmented e índice OK → TrySegmentedReplace
              senão → fluxo streaming / MMF habitual
```

### 6.3 Dependência de `temp.txt`

Ambos os caminhos segmentados leem `IndexFileName` (tipicamente `ExtractFilePath(Exe)\temp.txt`):

- `TotalLines := Idx.Size div INDEX_RECORD_SIZE` (20 bytes por linha).
- Se `TotalLines < 2` ou `TotalParts <= 1`, **TrySegmented\*** sai sem fazer nada (`Result := False`) e o thread usa o plano B.

**Implicação:** após abertura **Zero Scan** sem F5, Replace All segmentado **não** arranca; o utilizador deve indexar ou usar fluxo não segmentado.

---

## 7. Algoritmo de segmentação no disco

### 7.1 Particionamento

```
TotalParts = ceil(TotalLines / LinesPerSegment)
Para cada Part de LineStart a LineEnd (alinhado a linhas do índice):
    SegOut = temp único (prefixo dseg_out / replace)
    Processar só linhas [LineStart..LineEnd]
    AppendFileToStream(Merge, SegOut)
    Apagar SegOut
Rename atómico / swap Merge → ficheiro original
```

### 7.2 Parâmetros fixos no código

| Constante | Valor | Onde |
|-----------|-------|------|
| Replace / delete segment size | `250000` | `TReplaceAllThread.Create`, `TSegmentedDeleteLinesThread` |
| Mínimo interno se passado menor | `5000` | `TrySegmentedBatchDelete` normaliza `LinesPerSegment` |
| Margem disco | `Src.Size + 64 MiB` | `VolumeHasMinFreeBytes` antes de começar |

### 7.3 Progresso

- Delete: `TfrmSmoothLoading.UpdateProgressWithDetail` por parte (`part %d of %d`).
- Replace: percentagem por parte em `TrySegmentedReplace`.

---

## 8. Limitações e riscos

### 8.1 Fronteira de segmento (Replace All)

Texto procurado que **começa** num segmento e **termina** no seguinte pode **não** ser encontrado, porque cada parte é processada com contexto limitado à faixa de linhas.

O produto avisa na confirmação quando `EffectiveUseSegmentedHeavyOps` devolve `True` (chave i18n `Line-segmented mode is ON: Replace All runs on line-aligned parts...`).

### 8.2 Espaço em disco

Necessário espaço livre aproximado **tamanho do ficheiro + 64 MB** (verificação antes do merge). Operação pode falhar com mensagem localizada se o volume estiver cheio.

### 8.3 Performance

Mais **lento** que um único passe em memória/MMF; troca tempo por pico de RAM menor.

### 8.4 Índice desactualizado

Se `temp.txt` não corresponder ao ficheiro no disco (edição externa, replace parcial falhado), segmentado pode falhar; delete tem **fallback automático** para MMF.

### 8.5 Win32

Mesmas limitações gerais do FastFile: streams 32-bit, `Integer` em contagens de UI; segmentado não remove o tecto de **2B linhas** da ListView (airbag).

---

## 9. Comparação com Zero Scan

| Dimensão | Zero Scan | Segmentado (ops. pesadas) |
|----------|-----------|---------------------------|
| **Fase** | Abertura / leitura | Gravação (mutação) |
| **Função decisora** | `ShouldOpenWithInstantZeroScan`, `UsesProportionalZeroScanScroll` | **`EffectiveUseSegmentedHeavyOps`** |
| **Forçar manual** | View → Force Zero Scan | Opções → Forçar modo segmentado |
| **Política auto** | Tamanho ≥ 15 GB na abertura | >100 MB, >500k linhas, ≥200 linhas na op. |
| **Precisa `temp.txt`** | Não na abertura; sim para Find exacto | **Sim** para segmentar |
| **UI barra Read** | — | Botões zoom / find / marcas (não controlam segmentado) |

**Podem estar activos em simultâneo:** ficheiro aberto em Zero Scan (navegação proporcional) e, ao fazer Replace All num ficheiro grande **já indexado**, `EffectiveUseSegmentedHeavyOps` pode ainda devolver `True` se os limiares automáticos se aplicarem.

---

## 10. Interface do utilizador

### 10.1 Onde configurar

- Menu **Opções** — política + forçar (não está na barra ao lado do word wrap).
- Persistência em `ASkin.ini`.

### 10.2 Barra Ler Arquivo (após remoção do checkbox)

Cinco botões rápidos (`SetupReadToolbarQuickButtons` em `pnlReadToolbarOptions`):

| Botão | Hint (atalho) |
|-------|----------------|
| Zoom in | Ctrl+Plus |
| Zoom out | Ctrl+Minus |
| Find | Ctrl+F |
| Find and replace | Ctrl+H |
| Marks | Ctrl+Alt+M |

Estes atalhos **não** alteram `EffectiveUseSegmentedHeavyOps`; apenas disparam acções de visualização / diálogo.

---

## 11. Mapa de símbolos no código

| Símbolo | Ficheiro | Papel |
|---------|----------|-------|
| `TSegmentHeavyOpsPolicy` | `MainUnit.pas` | Enum auto/sempre/nunca |
| `EffectiveUseSegmentedHeavyOps` | `MainUnit.pas` | **Decisão única** |
| `FForceSegmentHeavyOps` | `MainUnit.pas` | Forçar ON |
| `FSegmentHeavyOpsPolicy` | `MainUnit.pas` | Política INI |
| `ApplySegmentHeavyOpsUiState` | `MainUnit.pas` | Sync menus checked |
| `miToggleSegmentedHeavyOpsClick` | `MainUnit.pas` | Toggle forçar |
| `miSegmentHeavyOps*Click` | `MainUnit.pas` | Política |
| `TrySegmentedBatchDelete` | `uSmoothLoading.pas` | Delete por segmentos |
| `TReplaceAllThread.TrySegmentedReplace` | `uSmoothLoading.pas` | Replace por segmentos |
| `TSegmentedDeleteLinesThread` | `MainUnit.pas` | Worker delete |
| `RunSegmentedDeleteLinesWait` | `MainUnit.pas` | Espera thread delete |

---

## 12. Perguntas frequentes

### `EffectiveUseSegmentedHeavyOps` serve só para Replace All e delete em ficheiros de GB?

**Metade certa, metade errada.**

- **Certo:** a função é usada **apenas** para decidir o caminho segmentado no **Substituir tudo** e no **apagar linhas assinaladas em lote**. Nenhuma outra funcionalidade do FastFile chama esta função hoje.
- **Errado:** **não** é exclusiva de ficheiros “na casa dos GB”. No modo **automático**, basta **uma** condição: ficheiro **>100 MB**, ou **>500 000 linhas** totais, ou **≥200 linhas** envolvidas na operação. Um TXT de 120 MB ou um delete de 250 linhas já pode activar segmentado sem o ficheiro ter 1 GB.
- **GB** entra como cenário **típico** (quase sempre >100 MB e muitas linhas), não como limiar no código.

Para **forçar** segmentado num ficheiro de 1 KB, use Opções → **Forçar modo segmentado**. Para **nunca** usar num ficheiro de 5 GB, use política **nunca usar** (com Forçar desligado).

### O checkbox na barra ao lado do word wrap ainda existe?

**Não.** Foi substituído pelos cinco botões rápidos; o modo segmentado mudou para **Opções** + decisão automática.

### Por que Replace All avisa “limite de segmento”?

Porque `EffectiveUseSegmentedHeavyOps` devolveu `True` e o produto quer deixar claro que matches **a cavalo** de duas partes podem falhar.

### Posso obrigar segmentado em ficheiros pequenos?

Sim: **Forçar modo segmentado** ou política **sempre usar**.

### Posso impedir segmentado mesmo em ficheiros de 1 GB?

Sim: política **nunca usar** (Forçar OFF). O código usará MMF/streaming.

### O automático repete o antigo checkbox ligado?

**Não exactamente.** O antigo checkbox = sempre ON. O **automático** só liga quando os **limiares** (100 MB / 500k linhas / 200 linhas na op.) se verificam; **Forçar** reproduz o comportamento “sempre ON”.

### Onde alterar os limiares automáticos?

Hoje só no código, em `EffectiveUseSegmentedHeavyOps` (`MainUnit.pas`). Futuro opcional: expor em INI ou Opções avançadas.

---

*Documento criado para complementar o apêndice em ROADMAP_COMERCIAL_FASTFILE.md e a secção 4.1.1 em ARQUITETURA_TECNICA_FASTFILE.md.*
