# FastFile — Documento de Arquitetura Técnica

**Projeto:** FastFile (Delphi 10.4 Sydney / VCL / Win32 e Win64)  
**Versão atual:** `3.0.5.225` (`UnConsts.APPLICATION_VERSION`)  
**Desenvolvedor:** Hamden Vogel  
**Data deste documento:** 24 de setembro de 2026  
**Pasta raiz do código:** `FastFile\src`

---

## Sumário

1. [Visão geral do sistema](#1-visão-geral-do-sistema)
2. [Estrutura de unidades (units)](#2-estrutura-de-unidades-units)
3. [Camada de UI — Formulários e DataModule](#3-camada-de-ui--formulários-e-datamodule)
4. [Camada de threads (operações assíncronas)](#4-camada-de-threads-operações-assíncronas)
5. [Motor de leitura de arquivo e índice de linhas](#5-motor-de-leitura-de-arquivo-e-índice-de-linhas)
6. [Memory-Mapped File (uMMF)](#6-memory-mapped-file-umm)
7. [Operações de edição, exportação e divisão](#7-operações-de-edição-exportação-e-divisão)
8. [Replace All — modo normal e segmentado](#8-replace-all--modo-normal-e-segmentado)
9. [Delete em lote — modo normal e segmentado](#9-delete-em-lote--modo-normal-e-segmentado)
10. [Comparar / Mesclar e Histórico de sessão](#10-comparar--mesclar-e-histórico-de-sessão)
11. [Motor de diff de linhas (uLineDiffCore)](#11-motor-de-diff-de-linhas-ulinediffcore)
12. [Integração com ConsumerAI](#12-integração-com-consumerai)
13. [Arquivos externos em disco](#13-arquivos-externos-em-disco)
14. [Sistema de configuração — INI files](#14-sistema-de-configuração--ini-files)
15. [Sistema de log assíncrono](#15-sistema-de-log-assíncrono)
16. [Internacionalização (uI18n)](#16-internacionalização-ui18n)
17. [MRU — Most Recently Used (MruHelper)](#17-mru--most-recently-used-mruhelper)
18. [Recursos embutidos no executável](#18-recursos-embutidos-no-executável)
19. [Bibliotecas de terceiros](#19-bibliotecas-de-terceiros)
20. [Constantes globais (UnConsts)](#20-constantes-globais-unconsts)
21. [Fluxo de inicialização da aplicação](#21-fluxo-de-inicialização-da-aplicação)
22. [Diagrama de dependências entre units](#22-diagrama-de-dependências-entre-units)

---

## 1. Visão geral do sistema

FastFile é um editor/visualizador de arquivos de texto **grandes** (testado acima de 14 GB), implementado em **Delphi 10.4 Sydney (VCL)**, compilável para **Win32 e Win64**. O design gira em torno de:

- **Leitura indexada**: o arquivo nunca é carregado inteiro em memória. Um índice de offsets por linha (`temp.txt`) é construído na abertura e consultado para navegar, pesquisar e editar.
- **Memory-Mapped File (MMF)**: leitura via janelas de mapeamento (`uMMF.TMMFReader`), respeitando o `AllocationGranularity` do Windows.
- **Threading**: todas as operações pesadas (leitura, edição, split, merge, replace-all, etc.) rodam em threads secundárias, enquanto um overlay animado (`uSmoothLoading`) fornece feedback visual.
- **Edição atômica**: toda gravação usa um arquivo temporário intermediário + `TryRenameTempOverTarget` para garantir que o arquivo original nunca fique corrompido em caso de falha.
- **Instância única**: mutex via `CreateFileMapping` na inicialização do `FastFile.dpr` impede múltiplas instâncias simultâneas.

### 1.1 Ambiente de desenvolvimento e plataformas

| Item | Valor |
|------|-------|
| IDE / compilador | Embarcadero Delphi 10.4 Sydney (Studio 21.0, `ProjectVersion` 19.2) |
| Framework | VCL |
| Plataformas | Win32 e Win64 (plataforma padrão do `FastFile.dproj`: **Win64**) |
| Projeto | `FastFile.dproj` (MSBuild); `FastFile.dof` / `FastFile.cfg` são legado da época Delphi 7 |
| Saída do executável | `Build\$(Platform)\FastFile.exe` |
| Saída das DCUs | `Dcu\$(Platform)\` |
| Namespaces de unit | `Vcl`, `System`, `Winapi`, `Data`, `Xml`, etc. (`DCC_Namespace`), o que permite `uses Windows, Forms, ...` sem prefixo |
| Strings | `string` = `UnicodeString` (UTF-16). O disco continua em octetos: a conversão bytes ↔ texto passa por `uTextEncoding` conforme o encoding do arquivo |

**Build pela linha de comando** (usam `rsvars.bat` do Studio 21.0 + `msbuild`):

- `compile_verify_d104.bat` → Win32 (`Build\Win32\FastFile.exe`)
- `compile_verify_win64.bat` → Win64 (`Build\Win64\FastFile.exe`)

**Diferenças por plataforma** (diretivas `{$IFDEF WIN64}`):

| Área | Win32 | Win64 |
|------|-------|-------|
| FastCode (`FastFile.dpr`) | Incluído (assembly x86) | Excluído; usa a RTL do Delphi |
| Indexação paralela de linhas (`uLineIndexScan`) | Desativada | Ativada (`LINE_INDEX_PARALLEL_ENABLED`); detecção de AVX2 |
| Prefetch no MMF (`uMMF`) | Desativado | Ativado (`FPrefetchEnabled`) |
| Limiares de memória do watchdog (`uFastFileWatchdog`) | Menores (espaço de endereçamento 32-bit) | Aviso 3 GB / crítico 5 GB |

---

## 2. Estrutura de unidades (units)

| Unit | Responsabilidade principal |
|------|---------------------------|
| `MainUnit.pas` | Form principal (`frmMain`). Toda a lógica de UI: menus, toolbar, ListView, filtro, atalhos, MRU, opções, undo/redo, exportação |
| `UnConsts.pas` | Constantes globais (nomes de arquivos, versão, limites) |
| `UnUtils.pas` | Utilitários gerais: I/O, diálogos, `GetTmpDir`, `extractResource`, helpers de UI |
| `UnDM.pas` | `TDataModule1` com `TsSkinManager` + `TClientDataSet` para `files.xml` / `folders.xml`; extração de recursos na inicialização |
| `uSmoothLoading.pas` | Overlay de loading + **todas as threads de operação pesada** |
| `uMMF.pas` | `TMMFReader`: acesso via Memory-Mapped File com janelas deslizantes |
| `uLineEditor.pas` | Formulário modal de edição de linha única (`TfrmLineEditor`) |
| `uDeltaEditor.pas` | Formulário modal de edição delta/merge (`TfrmDeltaEditor`) |
| `uCompareMergeUI.pas` | Formulário de comparação/mesclagem + histórico de sessão (`TfrmCompareMerge`) |
| `uLineDiffCore.pas` | Algoritmo LCS DP para diff de listas de linhas |
| `uFileSessionHistory.pas` | Journal de operações por arquivo (append-only, `FastFileSessionHistory\`) |
| `uI18n.pas` | Sistema de internacionalização (11 idiomas) |
| `MruHelper.pas` | Componente MRU (Most Recently Used) para campos de texto com popup |
| `ThreadFileLog.pas` | Log assíncrono em arquivo via thread pool |
| `ThreadUtilities.pas` | `TThreadPool` genérico (base para `ThreadFileLog`) |
| `uTextEncoding.pas` | Conversão entre os octetos do arquivo (UTF-8 / UTF-16 / ANSI) e o texto Unicode da UI (`string` UTF-16 no Delphi 10.4), para exibição, busca, edição e clipboard |
| `UnConsumerAI.pas` | Integração com `ConsumerAI.exe` (launch sem freeze) |
| `UnConsumerDialog.pas` | Formulário do painel de IA |
| `uExportDialog.pas` | Diálogo de exportação de linhas |
| `uFindReplace.pas` | Formulário Localizar e Substituir |
| `UnFormAboutFF.pas` | Tela "Sobre" do FastFile |
| `UnSearch.pas` | Formulário/lógica de busca em arquivos |
| `unSplitView.pas` | Formulário de visão dividida |
| `unMoreInfo.pas` | Formulário de detalhes extras |
| `UnSplash.pas` | Tela de splash na inicialização |
| `FolderMon.pas` | Monitor de alterações em pastas (`ReadDirectoryChangesW`) |
| `DSiWin32.pas` | Biblioteca de utilitários Win32 de terceiros |
| `StopWatch.pas` | Cronômetro de alta resolução (via `QueryPerformanceCounter`) |
| `Biblioteca.pas` | Biblioteca auxiliar (pode gravar `bd.settings`) |
| `MyObjectList.pas` | Lista de objetos tipada |
| `UnitInt64List.pas` | Lista dinâmica de `Int64` |
| `UntFields.pas` | Helpers para campos de dataset |
| `UntForm.pas` | Helpers de formulários |
| `unHardwareInformation.pas` | Detecção de informações de hardware |
| `UnTemporaryFileStream.pas` | Stream com auto-limpeza de arquivo temporário |
| `UnTextFileStream.pas` / `UnBufferedTextWriter.pas` | Streams de texto com buffer de 64 KB para I/O de alta performance |
| `TLineReader.pas` | Leitor de linhas sequencial |
| `uMMF_utf8.pas` / `UnReadFileThread_utf8.pas` / `uSmoothLoading_utf8.pas` | Variantes UTF-8 explícitas de unidades equivalentes |
| `Export.pas` | Lógica de exportação legada |
| `FastCode.Libraries-0.6.4\FastCode.pas` | FastCode: substituições de RTL otimizadas |
| `FastMM4-master\FastMM4.pas` | Gerenciador de memória FastMM4 |

---

## 3. Camada de UI — Formulários e DataModule

### `frmMain` (`MainUnit.pas`)

Form principal; contém:

- **`TPageControl` (`pgMain`)**: separa as abas "Read File" (índice 0), "Split File" (índice 1) e "Exported Lines" (índice 2).
- **`TListView` com `OwnerData`**: exibe linhas do arquivo indexado sem carregar tudo em memória. Cada item é preenchido sob demanda em `OnData` consultando o índice `temp.txt` + `TMMFReader`.
- **`TCheckListBox`**: modo seleção por checkbox para operações em lote.
- **`edtFileName`**: campo de caminho do arquivo aberto.
- **`sStatusBar`**: barra de estado com painel clicável para "detalhes do arquivo" (`BuildLoadedFileDetailsText` → `ShowDetailsPopup`).
- **Menus**: `MainMenu1` com `&File`, `&Edit`, `&View`, `&Options`, `&Tools`, `&Dialogs`, `Help`. Popup `PopupMenu1` (lista) e `PopupDialogs` (título).
- **Undo/Redo**: pilha `TUndoRecord` (op, linha, conteúdo antes/depois).
- **`TFilterMatchMode`**: enum para o modo do filtro (`fmmContains`, `fmmPrefix`, `fmmRegex`).
- **Word Wrap**: `FastWordWrapAtivo` / `FastWordWrapMaxChars` (global em `uSmoothLoading`).
- **Tail/Follow**: timer que monitora crescimento do arquivo e chama `TailAppendNewLines` em chunks de 64 MiB.
- **Modo segmentado (ops. pesadas):** `FForceSegmentHeavyOps` + `FSegmentHeavyOpsPolicy` (Opções / `ASkin.ini` → `SegmentHeavyOps`, `SegmentHeavyOpsPolicy`); decisão central em **`EffectiveUseSegmentedHeavyOps`** (ver secção 4.1.1); barra Read com botões zoom/find/marcas em `pnlReadToolbarOptions`.
- Documentação de produto / limites: **`DOC_SEGMENTED_HEAVY_OPS.md`** (completo); resumo em **`ROADMAP_COMERCIAL_FASTFILE.md`** (apêndice).

#### 4.1.1 `EffectiveUseSegmentedHeavyOps` — quando o segmentado é usado

Função em **`MainUnit.pas`** que responde, para **uma operação concreta**, se o caminho **segmentado por linhas** deve ser tentado (Replace All / delete em lote). Não é chamada na abertura do ficheiro nem no scroll.

**Assinatura:**

```pascal
function EffectiveUseSegmentedHeavyOps(
  const AFileSize, ALineCount, ALinesAffected: Int64): Boolean;
```

| Parâmetro | Significado típico nos call sites |
|-----------|-----------------------------------|
| `AFileSize` | Tamanho do ficheiro em disco (`GetFileSize` / `FileSizeBefore`) |
| `ALineCount` | `totalLines` (linhas conhecidas na sessão) |
| `ALinesAffected` | Linhas envolvidas na operação; **0** em Replace All; **`ToDelete.Count`** no delete em lote |

**Árvore de decisão (ordem no código):**

```
FForceSegmentHeavyOps = True     → Result := True   (Opções: “Forçar modo segmentado”)
FSegmentHeavyOpsPolicy = AlwaysOn → Result := True   (Opções: “sempre usar”)
FSegmentHeavyOpsPolicy = AlwaysOff → Result := False (Opções: “nunca usar”)
shpAuto (recomendado)            → Result := True se QUALQUER:
    ALinesAffected >= 200
    OR AFileSize > 100 MiB
    OR ALineCount > 500_000
```

**Pontos de chamada (única fonte de verdade — não duplicar `if` espalhados):**

| Local | `ALinesAffected` | Efeito |
|-------|------------------|--------|
| Delete linhas assinaladas (`ActionDelete` / lote) | `ToDelete.Count` | Se `True` → `RunSegmentedDeleteLinesWait` (`TrySegmentedBatchDelete`); senão MMF / `TEditFileThread` |
| Mesmo bloco | idem | Também influencia `UseSmoothProgress` (overlay) |
| Replace All — confirmação | `0` | Texto extra no `MessageBox` se segmentado efectivo |
| Replace All — `TReplaceAllThread.Create` | `0` | Último parâmetro booleano = usar `TrySegmentedReplace` |

**Persistência ligada à função:**

| Estado | Variável / INI |
|--------|----------------|
| Forçar ON | `FForceSegmentHeavyOps` ← `SegmentHeavyOps` (0/1) em `FormShow` + toggle Opções |
| Política | `FSegmentHeavyOpsPolicy` ← `SegmentHeavyOpsPolicy` (0=auto, 1=sempre, 2=nunca) em `LoadSmartSearchPrefs` |

**Relacionado:** `SegmentHeavyOpsPolicyCaption` — texto para painel de detalhes do ficheiro; não altera a lógica.

**Documento dedicado:** [DOC_SEGMENTED_HEAVY_OPS.md](DOC_SEGMENTED_HEAVY_OPS.md) — glossário, fluxos delete/Replace All, INI, limitações, FAQ.

### `TDataModule1` (`UnDM.pas`)

- Criado antes do form principal (conforme requisito do `TsSkinManager`).
- Contém: `TsSkinManager` (AlphaControls), `TClientDataSet clFiles` (dados de `files.xml`), `TClientDataSet clFolders` (dados de `folders.xml`), `TClientDataSet clFilesExclude`.
- Em `DataModuleCreate` → `LoadInternalConfigs`: extrai recursos embutidos para disco caso os arquivos não existam (`FOLDERS`, `FILES`, `SKINSINI`, `SKINS`, `TEXTURE`, `LOGO`).

### Formulários modais

| Formulário | Unit | Propósito |
|-----------|------|-----------|
| `frmLineEditor` | `uLineEditor` | Insert / Edit / Delete / Duplicate de uma linha |
| `frmDeltaEditor` | `uDeltaEditor` | Edição de lista de deltas (pares linha:texto) para merge |
| `frmCompareMerge` | `uCompareMergeUI` | Comparação/diff de dois arquivos + histórico de sessão |
| `frmSplashForm` | `UnSplash` | Splash screen na inicialização |
| `frmAboutFF` | `UnFormAboutFF` | Tela "Sobre" com histórico de versões |
| `frmSplitView` | `unSplitView` | Visão dividida de partes do arquivo |
| `frmFindReplace` | `uFindReplace` | Localizar e Substituir |
| `frmExportDialog` | `uExportDialog` | Configuração de exportação de linhas |
| `frmConsumerDialog` | `UnConsumerDialog` | Painel do ConsumerAI |

---

## 4. Camada de threads (operações assíncronas)

Todas as threads de operação pesada estão declaradas em **`uSmoothLoading.pas`** (exceto `THistoryReloadThread`, que está em `uCompareMergeUI.pas`).

### `TfrmSmoothLoading` (controller thread)

Thread orquestradora. Recebe o modo (`TSmoothLoadingMode`: `slmReadFile`, `slmEditFile`, `slmExportLines`) e cria a thread de trabalho adequada. Comunica-se com o overlay visual (`TfrmSmoothLoadingForm`) via `Synchronize`.

### `TfrmSmoothLoadingForm` (overlay visual)

Form semi-transparente (fade-in) com barra de progresso animada (`TPaintBox`), logotipo e mensagem. Controla progresso suave via `WM_APP+77` (`WMSmoothProgress`). Suporta modo `AStayOnTop=False` para operações longas que devem permitir Alt+Tab.

### Threads de trabalho

| Thread | Operação | Arquivo temporário |
|--------|----------|-------------------|
| `TReadFileThread` | Lê o arquivo fonte, constrói índice `temp.txt`, preenche a ListView | — (grava `temp.txt` diretamente) |
| `TEditFileThread` | Insert / Edit / Delete / Duplicate de linha; operação atômica | `ff_edit_<tick>_<tid>.tmp` |
| `TMergeDeltaThread` | Aplica lista de deltas (arquivo `.delta`) sobre o arquivo fonte | `temp_merge.txt` + `ff_mrgd_<tick>_<tid>.tmp` |
| `TReplaceAllThread` | Substituição global (normal ou segmentada) | Normal: `ff_rall_*.tmp`; Segmentado: `ff_rseg_*.tmp` (um por segmento) |
| `TExportFileThread` | Exporta linhas selecionadas para arquivo ou clipboard | `ff_exp_*.tmp` |
| `TSplitFileThread` | Divide arquivo em partes por linha (tabela de ranges) | Saída direta nos arquivos de destino |
| `TSplitEqualPartsThread` | Divide arquivo em N partes de tamanho aproximadamente igual (alinhado a LF) | Saída direta nos arquivos de destino |
| `TMergeFilesThread` | Mescla dois arquivos (inserção em offset específico ou range de linhas) | `ff_mrg_*.tmp` |
| `THistoryReloadThread` | Relê journal de histórico de sessão, filtra, gera preview e aplica na UI (`uCompareMergeUI`) | — |

#### Padrão de nomenclatura dos temporários

```
ff_<tag>_<GetTickCount>_<GetCurrentThreadId>.tmp
```

Função `NewFastFileTemp(tag)` em `uSmoothLoading.pas`. Criados junto ao `.exe` (`ExtractFilePath(ParamStr(0))`).

#### Gravação atômica (`TryRenameTempOverTarget`)

Todas as threads de edição seguem:
1. Abre `<arquivo>.tmp` para escrita com buffer de 64 KB (`OUT_BUFFER_SIZE`).
2. Lê o arquivo original via `TMMFReader` (evita lock total do arquivo).
3. Escreve o novo conteúdo no temporário.
4. Ao final bem-sucedido: `RenameFile(tmp, original)` — operação atômica no filesystem Windows.
5. Em caso de falha: remove o temporário; o original permanece intacto.

#### Comunicação thread → UI

- `Synchronize`: usado para atualizar a barra de progresso e labels.
- `PostMessage(WM_APP+77)` / `PostMessage(WM_FF_HIST_PROGRESS_FLUSH)`: para threads de longa duração onde `Synchronize` acumularia na fila do `Application`.
- `MsgWaitForMultipleObjects` com `QS_ALLINPUT` + `Sleep(2..5ms)`: yield periódico para manter UI responsiva sem busy-wait.

---

## 5. Motor de leitura de arquivo e índice de linhas

### `TReadFileThread` — construção do índice

Documentação canónica actualizada (formato do registo, buffers, &gt;2 GB, SWAR):  
**[DOC_INDEXACAO_F5_MMF_WRITER.md](DOC_INDEXACAO_F5_MMF_WRITER.md)**.

1. Abre o arquivo com `TMMFReader`.
2. Varre o conteúdo por regiões MMF + `ScanBufferForLineFeeds` (SWAR / AVX2), detectando LF (`#10`).
3. Para cada LF, grava via `TBufferedTextWriter.WriteOffsetDirect` um registro de **20 bytes** (`INDEX_RECORD_SIZE`):
   - 18 bytes: offset ASCII (início da linha seguinte no arquivo fonte);
   - 2 bytes: `#13#10`.
4. Em paralelo escreve checkpoints esparsos em `temp_ckpt.txt` (a cada 1024 linhas). Ficheiros **&gt; 2 GB**: só ckpt (sem `temp.txt` denso).
5. Ao final, atualiza a ListView via `Synchronize` com o total de linhas.

### `temp.txt` — uso em leitura

- Consultado em `OnData` da ListView: dado o número da linha (0-based), multiplica por `INDEX_RECORD_SIZE`, lê o registro, busca os bytes via `TMMFReader`, converte encoding (`uTextEncoding`) e exibe.
- Também usado como âncora para operações segmentadas (seção 8 e 9).

### Tail / Follow (`TailAppendNewLines`)

Quando o modo "Tail" está ativo, um timer verifica o tamanho do arquivo em disco. Se cresceu, lê o delta (bytes novos) em **chunks de 64 MiB** (`MAX_TAIL_READ_CHUNK`, mesmo valor em Win32 e Win64 para limitar o uso de memória por leitura) e acrescenta registros no índice sem reler o arquivo inteiro.

---

## 6. Memory-Mapped File (uMMF)

### `TMMFReader`

```
CreateFile(GENERIC_READ, FILE_SHARE_READ|WRITE)
→ CreateFileMapping(PAGE_READONLY)
→ MapViewOfFile(FILE_MAP_READ, offset alinhado ao AllocationGranularity)
```

- `FGranularity`: valor de `SYSTEM_INFO.dwAllocationGranularity` (tipicamente 64 KB no Windows).
- `EnsureView(AbsOffset, MinBytes)`: remapeia a janela se o offset requisitado estiver fora da janela atual. O offset de mapeamento é alinhado para baixo ao múltiplo de `FGranularity`.
- `PtrAt(AbsOffset, NeedBytes, Contiguous)`: retorna ponteiro direto para o byte no arquivo, mais quantos bytes contíguos existem a partir dali.
- `ReadBytes`: cópia segura para buffer do chamador (útil quando a leitura cruza fronteira de janela).
- Erros de abertura/mapeamento são registrados via `LogAsync` antes de lançar exceção.

---

## 7. Operações de edição, exportação e divisão

### Edição de linha única (`TEditFileThread`)

Opera com `TOperationType`: `otInsert`, `otReplace`, `otEdit`, `otDelete`, `otDuplicate`.

Fluxo:
1. Lê o arquivo original via `TMMFReader` linha a linha (usando o índice).
2. Ao chegar na linha alvo, aplica a operação (insere antes/depois, substitui, suprime, duplica).
3. Grava tudo em `ff_edit_*.tmp` com `TUnBufferedTextWriter` (buffer 64 KB).
4. Atomic rename.
5. Re-lança `TReadFileThread` para reconstruir o índice.
6. Registra no journal (`FFHistoryAppendLineOp`).

`AIsRawContent=True`: flag que controla se o conteúdo recebido já está nos bytes crus do arquivo (evita double-encoding em fluxos que leram via `TMMFReader` → `uTextEncoding`).

### Exportação (`TExportFileThread`)

- Recebe uma string `FLineParams` com os números de linha a exportar (parse via `ParseLines`).
- Lê cada linha via índice + `TMMFReader`.
- Saída para arquivo (`FSaveToFile=True`) ou clipboard (`ClipboardSetUnicodeText`).

### Split por ranges (`TSplitFileThread`)

- Recebe um array de `TSplitEntry` (ID, FileName, SourceLine, TargetLine).
- Para cada entrada, lê o intervalo de linhas do arquivo original e escreve no arquivo de destino.

### Split em partes iguais (`TSplitEqualPartsThread`)

- Divide o arquivo em `FPartCount` partes de tamanho aproximadamente igual em **bytes**.
- Ajusta o limite de cada parte para nunca cortar uma linha (busca o `#10` mais próximo).

### Merge de arquivos (`TMergeFilesThread`)

- Mescla `FSourceFileName` em `FDestinationFileName` no offset `FInsertOffset` (byte) ou no range `FFromLine..FToLine`.
- Modos: `mfmBeginning`, `mfmAfterLine`, `mfmEnd`, `mfmLineRange`.
- Atomic rename ao final.

### Merge de delta (`TMergeDeltaThread`)

- Recebe um arquivo `.delta` (lista de pares `<número>: <texto>`).
- Aplica as modificações sobre o arquivo fonte: para cada linha no delta, substitui a linha correspondente.
- Usa `temp_merge.txt` como saída intermediária + atomic rename.

---

## 8. Replace All — modo normal e segmentado

### Modo normal (`TReplaceAllThread.Execute` → `FSegmented=False`)

1. Lê o arquivo original via `TMMFReader` linha a linha.
2. Aplica `StringReplace` (respeitando `FCaseSensitive`, `FWholeWord`).
3. Limita a `REPLACE_ALL_MATCH_LIMIT` = 5.000.000 substituições (segurança contra substituição catastrófica).
4. Grava em `ff_rall_*.tmp` → atomic rename.
5. Registra no journal (`FFHistoryAppendReplaceAll`).

### Modo segmentado (`TReplaceAllThread.TrySegmentedReplace`)

Ativado quando `SegmentHeavyOps=1` (INI) e arquivo tem mais de um segmento.

1. Lê o `temp.txt` (índice) para determinar o total de linhas.
2. Divide em segmentos de `FLinesPerSegment` linhas (padrão: **250.000 linhas/segmento**).
3. Para cada segmento:
   - Cria `TEditFileThread` com `AFreeOnTerminate=False` (controlado pelo pai).
   - Aplica substituições apenas nas linhas daquele segmento.
   - Grava em `ff_rseg_<seg>_*.tmp`.
4. Concatena todos os `ff_rseg_*.tmp` em `ff_rall_*.tmp`.
5. Atomic rename do resultado final.
6. Remove os temporários de segmento.

---

## 9. Delete em lote — modo normal e segmentado

### Modo normal (`DeleteFromStream`)

Lê o arquivo original, suprime as linhas marcadas (via `TCheckListBox`), grava em temporário + atomic rename.

### Modo segmentado (`TrySegmentedBatchDelete`)

Ativado quando `SegmentHeavyOps=1` e arquivo tem mais de um segmento.

1. Lê o índice `temp.txt` para segmentar por `LinesPerSegment`.
2. Para cada segmento, gera a saída apenas com as **linhas a manter** (inverso das linhas a deletar).
3. Cada segmento é gravado em `ff_bdel_<seg>_*.tmp`.
4. Concatena em `ff_bdel_*.tmp`.
5. Atomic rename.

Se o segmentado não se aplicar (índice ausente, arquivo de segmento único), cai no `DeleteFromStream` clássico.

---

## 10. Comparar / Mesclar e Histórico de sessão

### `uFileSessionHistory.pas` — Journal

**Formato do arquivo de journal:**
```
<timestamp>|<op>|<linha>|<old_excerpt>|<new_excerpt>
```
- Separador: `|` (pipes dentro dos campos são substituídos por espaço em `SanitizeOneLine`).
- Um arquivo `.log` por arquivo de dados aberto pelo usuário.
- **Caminho:** `<exe>\FastFileSessionHistory\ffhist_<FNV1a-32-hex>_<nome_base>.log`
- **Função de hash:** FNV-1a 32-bit sobre o caminho absoluto normalizado em minúsculas.
- **Operações registradas:** `INS` (insert), `EDT` (edit), `DEL` (delete), `RPLALL` (replace all).
- Thread-safe via `GFFHistLock: TCriticalSection`.

**APIs públicas:**
```pascal
FFHistoryAppendLineOp(ADataFilePath, AOp, ALine1Based, AOldExcerpt, ANewExcerpt);
FFHistoryAppendReplaceAll(ADataFilePath, AReplacedCount, ALimitHit, AFindExcerpt, AReplaceExcerpt);
FFHistoryJournalPath(ADataFilePath): string;  // retorna o caminho do .log
```

### `TfrmCompareMerge` (`uCompareMergeUI.pas`)

Duas abas:
- **History**: lista `lvHistFile` (operações do journal coloridas por tipo INS/EDT/DEL/RPLALL) + memo `mmoJournal` (preview do texto cru do journal).
- **Diff**: dois `TListView` (`lvLeft` / `lvRight`) em modo virtual (`OwnerData`), exibindo as linhas com cores por `TFFDiffKind`. Sync scroll via `tmrSync`.

**`THistoryReloadThread`** — releitura do journal:

Progresso em duas fases:
- **0–54%**: trabalho na thread — cauda do journal (a cada 256 KiB → `PostMessage`), filtro de linhas, preview, scan de cores.
- **55–99%**: aplicação na UI (memo + lista) via `SyncApply` em fatias de **12 itens** com `Sleep` periódico.

Mecanismo de coalescing de progresso: `WM_FF_HIST_PROGRESS_FLUSH` + `FHistReloadProgLastFlushTick` / `FHistReloadProgLastPosted` — evita flood de mensagens durante cargas longas.

**Mesclagem (Apply left→right / right→left):**
- `btnApplyLeftToRightClick` / `btnApplyRightToLeft`: para cada linha com `ffdkChange/Insert/Delete`, chama `TEditFileThread.RunEditWait` sobre o arquivo de destino.
- `TouchHistoryIfSameFile`: se o arquivo editado coincidir com o aberto no form principal, dispara reload da ListView + journal.
- Sync visual: `WM_SETREDRAW` para evitar flickering durante aplicação.

---

## 11. Motor de diff de linhas (uLineDiffCore)

### `FFBuildLineDiffRows`

Algoritmo LCS DP (programação dinâmica) sobre dois `TStringList`.

**Otimizações:**
- Fast path de **prefixo comum**: consome linhas iguais no início sem entrar na matriz DP.
- Fast path de **sufixo comum**: idem para o final.
- Matriz DP em chunks para evitar alocação de matriz enorme de uma vez.
- Limite `AMaxDim` (número máximo de linhas por lado) para proteger uso de memória.

**Tipos de diferença (`TFFDiffKind`):**
- `ffdkEqual`: linhas idênticas (exibidas em verde na UI).
- `ffdkDelete`: linha presente só no lado esquerdo.
- `ffdkInsert`: linha presente só no lado direito.
- `ffdkChange`: linha diferente em ambos os lados.

---

## 12. Integração com ConsumerAI

### `TConsumerAI` (`UnConsumerAI.pas`)

Encapsula o lançamento do processo externo `ConsumerAI.exe`.

**Método `Process`:**
```
ConsumerAI.exe -file "<arquivo>" -rp -prompt
```

**`ExecuteWithoutFreezing`:**
- `CreateProcess` com `SW_HIDE` (janela oculta).
- Loop `GetExitCodeProcess` + `Application.ProcessMessages` + `Sleep(50)` até `ExitCode <> STILL_ACTIVE`.
- Evita congelamento da UI aguardando o processo externo.

### `ConsumerAI.exe` / `ConsumerAI_LanceDB.py`

Processo Python separado para análise de conteúdo com IA (LanceDB + embeddings). Comunica-se com o FastFile apenas via linha de comando e arquivos em disco. Logs próprios: `ConsumerAI_startup.log` e `ConsumerAI_LanceDB_startup.log`.

---

## 13. Arquivos externos em disco

Todos os caminhos usam `ExtractFilePath(Application.ExeName)` ou `ExtractFilePath(ParamStr(0))` — ou seja, a **pasta onde está o `.exe`**.

### Arquivos de índice e operação

| Arquivo | Constante | Descrição |
|---------|-----------|-----------|
| `temp.txt` | `TEMPFILE` | **Índice denso de linhas** do arquivo aberto. Registros de **20 bytes** por linha: offset em ASCII (18) + `#13#10`. Ver [DOC_INDEXACAO_F5_MMF_WRITER.md](DOC_INDEXACAO_F5_MMF_WRITER.md). Recriado na indexação F5 (omitido se ficheiro &gt; 2 GB). |
| `temp_ckpt.txt` | `TEMP_CKPT_FILE` | **Índice esparso** (mesmo formato de 20 bytes; tipicamente 1 entrada a cada 1024 linhas). |
| `chunk.txt` | `CHUNKFILE` | Usado em operações de chunk/split. |
| `temp_merge.txt` | — | Arquivo intermediário para `TMergeDeltaThread`. Removido após sucesso. |
| `ff_*.tmp` | — | Temporários de operações atômicas (edit, replace, split, merge). Padrão: `ff_<tag>_<tick>_<tid>.tmp`. Removidos ao final da operação. |
| `ff_rseg_*.tmp` | — | Segmentos do Replace All segmentado. |
| `ff_bdel_*.tmp` | — | Segmentos do Delete em lote segmentado. |

### Arquivos de configuração e estado

| Arquivo | Constante | Seção/Chave | Descrição |
|---------|-----------|-------------|-----------|
| `ASkin.ini` | `ASKIN_INI` | `[FastFile]` | Configuração principal do skin e preferências da aplicação (ver seção 14). |
| `mru_files.ini` | — | `[RecentFiles]` | Lista de arquivos recentes (`Count`, `File0`…`FileN`). Máximo configurável. |
| `mru_location.ini` | — | — | Histórico do campo "Location" (25 itens, via `TMruHelper`). |
| `mru_content.ini` | — | — | Histórico do campo "Phrase/Content" de busca (25 itens, via `TMruHelper`). |

### Arquivos de dados (XML)

| Arquivo | Constante | Descrição |
|---------|-----------|-----------|
| `files.xml` | `XMLFILES` | Dataset `TClientDataSet` com metadados de arquivos (campos: ID, Filename, FileSize, SourceLine, TargetLine). Extraído do recurso `FILES` se ausente. |
| `folders.xml` | `XMLFOLDERS` | Dataset `TClientDataSet` com dados de pastas. Extraído do recurso `FOLDERS` se ausente. |

### Arquivos visuais

| Arquivo | Constante | Descrição |
|---------|-----------|-----------|
| `Skins\` (pasta) | `FOLDERSKIN` | Temas visuais AlphaControls. Extraída do recurso `SKINS` se ausente. |
| `texture.bmp` | `TEXTURE` | Textura do tema. Extraído do recurso `TEXTURE` se ausente. |
| `logo.bmp` | `LOGO` | Logotipo exibido no overlay de loading. Extraído do recurso `LOGO` se ausente. |

### Arquivos de histórico de sessão

| Arquivo | Localização | Descrição |
|---------|-------------|-----------|
| `FastFileSessionHistory\ffhist_<hash>_<nome>.log` | Subpasta `FastFileSessionHistory\` junto ao `.exe` | Journal de operações por arquivo. Um arquivo por arquivo de dados aberto. |

### Outros arquivos em disco

| Arquivo | Descrição |
|---------|-----------|
| `extensionFiles.txt` | Lista de extensões para diálogos/filtros de abertura de arquivo. |
| `output.csv` | Arquivo de saída de operações de exportação para CSV. |
| `*.delta` | Arquivo de delta salvo em `ExtractFilePath(ParamStr(0))` com nome baseado no arquivo aberto. Ex.: `meuarquivo.txt` → `meuarquivo.delta`. |
| `bd.settings` | Configurações da unidade `Biblioteca.pas` (se utilizada). |
| `ConsumerAI.exe` | `CONSUMERAI` | Processo externo de IA (Python compilado). |
| `ConsumerAI_startup.log` | Log de inicialização do ConsumerAI (escrito pelo processo Python). |
| `ConsumerAI_LanceDB_startup.log` | Log de inicialização do ConsumerAI com LanceDB. |

---

## 14. Sistema de configuração — INI files

### `ASkin.ini` — arquivo principal de configuração

**Leitura/escrita:** via `sStoreUtils` (unidade AlphaControls), funções `ReadIniInteger`, `WriteIniStr`.  
**Seção:** `[FastFile]` (= `APPLICATION_NAME`).

| Chave | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `SkinDirectory` | String | `<exe>\Skins` | Caminho da pasta de skins do AlphaControls |
| `SkinName` | String | `Notes Plastic` | Nome do tema visual ativo |
| `SkinActive` | Integer (0/1) | `1` | Skin habilitado ou desabilitado |
| `Top` | Integer | — | Posição Y da janela principal |
| `Left` | Integer | — | Posição X da janela principal |
| `Language` | String | `pt-BR` | Código de idioma ativo (ver `uI18n`) |
| `SegmentHeavyOps` | Integer (0/1) | `0` | **Forçar** modo segmentado (`FForceSegmentHeavyOps`); quando `1`, `EffectiveUseSegmentedHeavyOps` devolve sempre `True` |
| `SegmentHeavyOpsPolicy` | Integer (0..2) | `0` | `0`=auto, `1`=sempre, `2`=nunca (`TSegmentHeavyOpsPolicy`); gravado com `SaveSmartSearchPrefs` |

**Gravação / leitura:**

- `miToggleSegmentedHeavyOpsClick` → alterna `FForceSegmentHeavyOps` → `WriteIniStr` (`SegmentHeavyOps`).
- `miSegmentHeavyOpsAutoClick` / `Always` / `Never` → `FSegmentHeavyOpsPolicy` → `SaveSmartSearchPrefs`.
- `FormShow`: lê `SegmentHeavyOps` → `ApplySegmentHeavyOpsUiState`.
- `LoadSmartSearchPrefs`: lê `SegmentHeavyOpsPolicy`.

**Quem consulta a decisão:** apenas `EffectiveUseSegmentedHeavyOps` (ver secção 4.1.1).

### `mru_files.ini`

Gerenciado diretamente em `MainUnit.pas` com `TIniFile`.

```ini
[RecentFiles]
Count=3
File0=C:\dados\arquivo1.txt
File1=C:\dados\arquivo2.txt
File2=C:\dados\arquivo3.txt
```

Ao selecionar um item inexistente: exibe aviso localizado, remove a entrada, regrava o INI.

### `mru_location.ini` e `mru_content.ini`

Gerenciados por `TMruHelper` (seção 17). Formato gerenciado internamente pela classe (lista de strings, até 25 itens).

### `ReadFileThread.ini`

Arquivo de configuração auxiliar presente na pasta `Src`. Pode ser usado em testes/desenvolvimento para configurar o comportamento da thread de leitura. Não é distribuído junto ao executável final.

---

## 15. Sistema de log assíncrono

### `ThreadFileLog.pas`

**`TThreadFileLog`**: wraps um `TThreadPool` de 1 thread de worker.

```
LogAsync("Log_FastFile25042026.txt", "mensagem")
  → TThreadPool.Add(PLogRequest)
    → HandleLogRequest(Data)
      → LogToFile(FileName, LogString)
        → AssignFile / Append / Writeln / CloseFile
```

**`GlobalLogThread`**: instância global lazy-initialized — criada na primeira chamada a `LogAsync`.

**Padrão de nome de arquivo:**
```
Log_FastFile<ddmmyyyyhhnn>.txt
```
ex.: `Log_FastFile25042026_1430.txt`

**Localização:** diretório de trabalho corrente do processo (em geral a pasta do `.exe`).

**Chamadores típicos:**
- `uMMF.pas`: falha ao abrir arquivo / `GetFileSize` / `CreateFileMapping`.
- `uSmoothLoading.pas`: exceções em threads de operação.
- Qualquer módulo que chame `LogAsync` diretamente.

**Nota de segurança:** `LogToFile` não usa stream compartilhado — abre, escreve, fecha a cada entrada. Com 1 thread de worker, não há condição de corrida nas gravações.

---

## 16. Internacionalização (uI18n)

### Idiomas suportados

| Enum | Código | Idioma |
|------|--------|--------|
| `alEnglish` | `en` | English (padrão) |
| `alPortuguese` | `pt-BR` | Português (Brasil) |
| `alPortuguesePT` | `pt-PT` | Português (Portugal) |
| `alSpanish` | `es` | Español |
| `alFrench` | `fr` | Français |
| `alGerman` | `de` | Deutsch |
| `alItalian` | `it` | Italiano |
| `alPolish` | `pl` | Polski |
| `alRomanian` | `ro` | Română |
| `alHungarian` | `hu` | Magyar |
| `alCzech` | `cs` | Čeština |

### Arquitetura interna

- Duas tabelas por idioma: `GEnglish` / `GPortuguese` etc. (lookup por chave) e `GTextEnglish` / `GTextPortuguese` etc. (lookup por texto inglês como chave).
- `TStringList` com `NameValueSeparator='='`, `CaseSensitive=False`.
- Busca binária (`FastIndexOfName`) após `Sort` para O(log n) em vez de O(n).
- `Tr(Key, DefaultText)`: busca por chave explícita.
- `TrText(DefaultText)`: busca usando o texto inglês como chave (mais conveniente na maioria dos casos).
- `ApplyTranslationsToForm(AForm)`: itera recursivamente os componentes do formulário e aplica traduções em `Caption`, `Hint` etc.

### Persistência do idioma

- Lido de `ASkin.ini` → chave `Language` em `FormShow`.
- Gravado em `ASkin.ini` ao alterar o idioma via menu.
- Função `AppLanguageFromCode(code)` converte string para enum.

---

## 17. MRU — Most Recently Used (MruHelper)

### `TMruHelper`

Componente que associa a um `TEdit` um histórico persistido em INI + popup de sugestões.

**Eventos interceptados no `TEdit`:**
- `OnEnter`, `OnExit`, `OnChange`, `OnKeyDown` — encadeados sobre os handlers originais.

**Comportamento:**
- Ao digitar: debounce timer (padrão: configurável) → `ApplyFilter` → filtra `FAllItems` e exibe no popup.
- `↑`/`↓`: navega no popup.
- `Enter`/`Esc`: confirma / fecha popup.
- `AddItem(S)`: adiciona ao início da lista, respeita `FMaxItems` (descarta os mais antigos), salva no INI.

**Formato do INI (gerenciado internamente):**
```ini
[Items]
Count=3
Item0=pesquisa recente 1
Item1=pesquisa recente 2
Item2=pesquisa recente 3
```

**Instâncias no `MainUnit`:**
- `mru_location` → `mru_location.ini` (25 itens) — campo de localização.
- `mru_content` → `mru_content.ini` (25 itens) — campo de busca/conteúdo.

---

## 18. Recursos embutidos no executável

Gerenciados em `UnDM.pas` via `UnUtils.extractResource` / `UnUtils.ExtractDirResource`.

| Recurso | Arquivo gerado | Quando extraído |
|---------|---------------|-----------------|
| `FOLDERS` | `folders.xml` | Se não existir |
| `FILES` | `files.xml` | Se não existir |
| `SKINSINI` | `ASkin.ini` | Se não existir |
| `SKINS` | Pasta `Skins\` | Se a pasta não existir |
| `TEXTURE` | `texture.bmp` | Se não existir |
| `LOGO` | `logo.bmp` | Se não existir |

Os recursos são compilados dentro do `.exe` via arquivos `.rc` (`files.rc`, `folders.rc`) e `FastFile.res`.

---

## 19. Bibliotecas de terceiros

| Biblioteca | Pasta | Propósito |
|-----------|-------|-----------|
| **FastMM4** | `FastMM4-master\` | Gerenciador de memória de alto desempenho para Delphi. Substitui o `System` padrão. Em `DEBUG`, `ReportMemoryLeaksOnShutdown=True`. |
| **FastCode** | `FastCode.Libraries-0.6.4\` | Substituições otimizadas de rotinas RTL (ex.: `Move`, `FillChar`, `Pos`). **Somente Win32** (assembly x86); no Win64 é excluído do `FastFile.dpr`. |
| **AlphaControls** | (via `.bpl` / `.dcp` em `Bpl\`, `Dcp\`, versão para Delphi 10.4) | Suite de componentes visuais com skinning. Inclui `TsSkinManager`, `sPanel`, `sListView`, `sMemo`, `sStatusBar`, `acTitleBar`, etc. |
| **DSiWin32** | `DSiWin32.pas` | Biblioteca de wrappers Win32 (processos, serviços, registry, eventos). |
| **MidasLib** | (link estático) | Substitui `midas.dll` externo; necessário para `TClientDataSet`. |

---

## 20. Constantes globais (UnConsts)

```pascal
APPLICATION_NAME    = 'FastFile'
APPLICATION_VERSION = '3.0.5.225'
APPLICATION_FULLNAME = 'FastFile editor'
ASKIN_INI           = 'ASkin.ini'
XMLFOLDERS          = 'folders.xml'
XMLFILES            = 'files.xml'
CONSUMERAI          = 'ConsumerAI.exe'
TEXTURE             = 'texture.bmp'
LOGO                = 'logo.bmp'
FOLDERSKIN          = 'Skins'
TEMPFILE            = 'temp.txt'
TEMP                = '-TEMP'           // sufixo de cópia temporária
CHUNKFILE           = 'chunk.txt'
OUT_BUFFER_SIZE     = 65536             // 64 KB — buffer padrão de I/O
INDEX_RECORD_SIZE   = 20               // bytes por registro no temp.txt
SIZEPARTFILE        = 25000000         // 25 MB — tamanho padrão de parte no split
MAX_FILESIZE_MEMORY_LIMIT_BYTES = 15958207655  // ~14.86 GB — limite de segurança
REPLACE_ALL_MATCH_LIMIT = 5000000      // limite de substituições no Replace All (em uSmoothLoading)
```

---

## 21. Fluxo de inicialização da aplicação

```
FastFile.dpr
  ├─ FastMM4 (substitui gerenciador de memória)
  ├─ FastCode (otimizações RTL; somente Win32)
  ├─ CreateFileMapping("MyACMap") → MUTEX de instância única
  │     └─ GetLastError = ERROR_ALREADY_EXISTS → avisa e encerra
  ├─ Application.Initialize
  ├─ TDataModule1.Create (UnDM)
  │     └─ LoadInternalConfigs
  │           ├─ Extrai folders.xml, files.xml, ASkin.ini, Skins\, texture.bmp, logo.bmp
  │           └─ sSkinManager1.SkinDirectory ← ASkin.ini
  ├─ frmSplash.Show (splash)
  ├─ frmMain.Create (MainUnit)
  │     └─ FormCreate
  │           ├─ Lê ASkin.ini → Language, SegmentHeavyOps, posição janela
  │           ├─ Inicializa TMruHelper (location, content)
  │           ├─ Carrega mru_files.ini → lista de recentes
  │           ├─ Carrega extensionFiles.txt
  │           ├─ Inicializa menus, toolbars, ImageLists
  │           └─ Aplica idioma (SetCurrentLanguage + ApplyTranslationsToForm)
  └─ Application.Run
```

---

## 22. Diagrama de dependências entre units

```
FastFile.dpr
  ├── MainUnit
  │     ├── UnConsts
  │     ├── UnUtils
  │     ├── MruHelper
  │     ├── UnConsumerDialog ──► UnConsumerAI ──► UnConsts
  │     ├── uSmoothLoading
  │     │     ├── uMMF ──► ThreadFileLog ──► ThreadUtilities
  │     │     ├── uLineEditor ──► uTextEncoding, uI18n
  │     │     ├── UnBufferedTextWriter
  │     │     ├── uFileSessionHistory
  │     │     └── uI18n
  │     ├── uDeltaEditor ──► uSmoothLoading, uI18n
  │     ├── uCompareMergeUI
  │     │     ├── uLineDiffCore
  │     │     ├── uFileSessionHistory
  │     │     ├── uSmoothLoading
  │     │     └── uI18n
  │     ├── uExportDialog ──► uI18n
  │     ├── uFindReplace ──► uI18n
  │     └── uTextEncoding
  ├── UnDM
  │     ├── UnUtils ──► UnConsts
  │     └── sSkinManager (AlphaControls)
  ├── UnFormAboutFF ──► uI18n
  ├── UnSplash
  ├── unSplitView
  └── [FastMM4, FastCode (só Win32) — sem dependências de projeto]
```

---

*Documento de arquitetura para uso interno de desenvolvimento. Atualizar sempre que novas threads, arquivos em disco ou chaves INI forem adicionados ao projeto.*
