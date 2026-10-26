# FastFile — `TReadFileThread.Execute` passo a passo

**O que este documento explica:** como funciona a rotina `TReadFileThread.Execute` (em `uSmoothLoading.pas`), que lê o ficheiro aberto do início ao fim, conta as linhas e grava os índices de linha. É ela que corre por trás da janela "Contando linhas (aguarde)..." / "Building line index...".

> **Documentos relacionados**
>
> - [DOC_INDEXACAO_F5_MMF_WRITER.md](DOC_INDEXACAO_F5_MMF_WRITER.md) — formato dos registos de índice (20 bytes) e papel de `TMMFReader` / `TBufferedTextWriter`
> - [DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md) — como os índices são usados depois (leitura de linha, Find)

---



## 1. Para que serve

Um ficheiro de texto não diz onde começa cada linha. Para mostrar a linha 5.000.000 sem reler tudo, o FastFile precisa de saber **em que byte ela começa**. Esta rotina varre o ficheiro uma vez e anota esses inícios em ficheiros de índice junto ao executável.

No fim, a thread informa a janela principal (`FinishThreadExecution`) com o total de linhas, ou com o erro / cancelamento.

## 2. Quem chama


| Origem (MainUnit)                                                     | Parâmetros relevantes                                   | Modo                            |
| --------------------------------------------------------------------- | ------------------------------------------------------- | ------------------------------- |
| Abertura / F5 (`BeginRead`)                                           | `TReadFileThread.Create(False, fFileName)`              | Normal                          |
| Reindexação após edição                                               | `..., TrText('Updating line index...'), '', True/False` | Normal ou Zero Scan sob demanda |
| `BeginOnDemandLineIndex` (ex.: Find num ficheiro aberto em Zero Scan) | `..., TrText('Building line index...'), '', True`       | Zero Scan sob demanda           |


O último parâmetro do construtor (`AZeroScanOnDemandIndex`) liga o **modo Zero Scan sob demanda** (`FZeroScanOnDemandIndex`).

No modo automático, **toda abertura passa por esta rotina**, qualquer que seja o tamanho, para o total de linhas ser exato (`ShouldOpenWithInstantZeroScan`). `MaxGbFileIndexed` e a lista `InstantFallbackFiles` do INI já não levam ao Zero Scan. A abertura instantânea (sem contar linhas) só acontece se o utilizador escolher no menu "Open: always instant (Zero Scan)" ou "Force Zero Scan Mode", ou se aceitar a abertura instantânea depois de uma falha de indexação (ex.: mais de 2 mil milhões de linhas).

## 3. Os índices gravados


| Índice                   | Ficheiro final                         | Conteúdo                                                       | Quando é gravado                             |
| ------------------------ | -------------------------------------- | -------------------------------------------------------------- | -------------------------------------------- |
| **Denso**                | `temp.txt` (`TEMPFILE`)                | O byte de início de **todas** as linhas                        | Ficheiros até 2 GB (`DENSE_INDEX_MAX_BYTES`) |
| **Checkpoint (esparso)** | `temp_ckpt.txt` (`TEMP_CKPT_FILE`)     | O byte de início de **1 a cada 1024** linhas (`CKPT_INTERVAL`) | Sempre                                       |
| **Blocos**               | gerido por `TZeroScanBlockIndexWriter` | Índice por blocos para o Zero Scan                             | Só no modo Zero Scan sob demanda             |


- Os offsets são **base 1**: a linha 1 começa no byte 1.
- Com o denso, ir a qualquer linha é imediato.
- Só com o checkpoint, o programa salta para o checkpoint anterior e avança no máximo 1023 linhas.



## 4. Estrutura

`Execute` só encadeia os passos; cada passo é um método privado de `TReadFileThread`:

```
Execute
 ├─ ResetReadState          zera contadores e flags de erro
 ├─ try
 │   ├─ DeleteOldIndexFiles     apaga os índices da leitura anterior
 │   ├─ DetectFileLayout        mede o ficheiro, decide quais índices gravar
 │   ├─ PrepareIndexWriters     abre os escritores (direto ou em temporários)
 │   └─ ScanLineFeeds           varre o ficheiro (paralelo ou sequencial)
 │  except → FIndexFailed / FIndexErrorMsg (não derruba a thread)
 ├─ finally
 │   └─ FinalizeIndexFiles      fecha escritores, publica os índices
 └─ FinishThreadExecution    avisa a janela principal
```

Os escritores e temporários de uma leitura ficam no record `TReadIndexWriters`:


| Campo                   | Tipo                        | Conteúdo                                          |
| ----------------------- | --------------------------- | ------------------------------------------------- |
| `Dense`                 | `TBufferedTextWriter`       | Escritor do índice denso (`nil` acima de 2 GB)    |
| `Ckpt`                  | `TBufferedTextWriter`       | Escritor do checkpoint                            |
| `Blocks`                | `TZeroScanBlockIndexWriter` | Índice por blocos (só Zero Scan)                  |
| `DenseTemp`, `CkptTemp` | `TTemporaryFileStream`      | Temporários do Zero Scan                          |
| `CkptTempPath`          | `string`                    | Temporário do checkpoint no modo normal (`ckpti`) |


Constantes da rotina:


| Constante               | Valor         | Uso                                                 |
| ----------------------- | ------------- | --------------------------------------------------- |
| `READ_MAX_LINES`        | 2.000.000.000 | Limite de linhas ("airbag")                         |
| `READ_SCAN_SLICE_BYTES` | 64 MB         | Fatia máxima por chamada a `ScanBufferForLineFeeds` |
| `READ_DENSE_BUF_BYTES`  | 16 MB         | Buffer do escritor do índice denso                  |




## 5. Passo a passo



### 5.1 `ResetReadState` e `DeleteOldIndexFiles`

- Zera `totalLines`, `FBytesRead`, `FHitLineLimit`, `FIndexFailed`, `FIndexErrorMsg` e `FCurrentPercent`.
- Apaga `temp.txt`, `temp_ckpt.txt` e `temp_index.meta` (até 3 tentativas cada).
- No modo Zero Scan sob demanda, apaga também o índice de blocos (`ZeroScanDeleteBlockIndex`).



### 5.2 `DetectFileLayout`

Lê o tamanho do ficheiro (`FTotalSize`) e o byte que termina as linhas (`TermByte`, via `LineTermByteForFile`): normalmente LF (10); CR (13) em ficheiros Mac clássico. Depois decide:


| Flag                    | Regra                               | Efeito                                                                        |
| ----------------------- | ----------------------------------- | ----------------------------------------------------------------------------- |
| `FSkipDenseIndex`       | `FTotalSize > 2 GB`                 | Não grava o índice denso                                                      |
| `FIsUltraLargeFile`     | `FTotalSize >= MaxBytesFileIndexed` | Marca o ficheiro como enorme (usado depois, p. ex. para word wrap)            |
| `FAutoDeleteDenseIndex` | sempre `False`                      | O denso é mantido: Find/Replace, filtro e operações segmentadas dependem dele |




### 5.3 `PrepareIndexWriters`

**Modo normal:**

- O denso é escrito **direto** em `temp.txt` (buffer de 16 MB).
- O checkpoint é escrito num temporário `ckpti` (buffer de 8 MB, ou 32 MB se não houver denso) e renomeado para `temp_ckpt.txt` no fim.

**Modo Zero Scan sob demanda:**

- O checkpoint e o denso são escritos em temporários `TTemporaryFileStream` (`zsckpt` e `zsdense`) na pasta temporária do FastFile.
- Buffers: checkpoint de 2 MB (16 MB se não houver denso), denso de 16 MB.
- Cria também o `TZeroScanBlockIndexWriter`.

Se o ficheiro não está vazio, grava logo o offset `1` (início da linha 1) no denso e no checkpoint.

Se houver exceção a meio, o que já foi criado fica no record e é libertado em `FinalizeIndexFiles`.

### 5.4 `ScanLineFeeds` — os dois procedimentos anónimos

`IdxW`, `CkptW`, `BlkW` e `SparseCkptOnly` são **cópias locais** dos campos do record, capturadas pelos procedimentos anónimos (ver §7). `SparseCkptOnly` fica `True` quando **só** o checkpoint vai ser gravado.

`OnLf` é chamado **uma vez por quebra de linha**, por isso é o ponto mais sensível à performance:

```
Inc(totalLines)
LineOff := ALfPos0 + 2      // ALfPos0 = posição do LF a contar de 0
                            // +1 = byte seguinte; +1 = passa a base 1
se só checkpoint:
    a cada 1024 linhas → grava LineOff no checkpoint
senão:
    grava LineOff no denso (se existir)
    anota no índice de blocos (se existir)
    a cada 1024 linhas → grava LineOff no checkpoint
```

`(totalLines and (CKPT_INTERVAL - 1)) = 0` é o mesmo que "múltiplo de 1024", mas sem divisão.

`DoProgress` atualiza a barra de progresso:

- Só atua se a janela de carregamento estiver visível (`FShowLoadingUI`).
- Calcula o progresso em milésimos até **990** (99%). Os 100% são enviados só no fim, em `SyncFinishFileNameRead`.
- Só envia nova atualização se avançou pelo menos 12 milésimos (1,2%) **ou** se passaram 45 ms desde a última.
- Envia o progresso (`PostProgressFineFromWorker`) e o texto "Total lines: N" (`PostDetailFromWorker`).



### 5.5 `ScanLineFeeds` — a varredura

**Caminho paralelo** — Win64, ficheiros a partir de 128 MB (`LINE_INDEX_PARALLEL_MIN_BYTES`), **todos os modos** (denso, só checkpoint, Zero Scan com blocos). Ver §5.5.1.

- `TryParallelLineIndexScan` (em `uLineIndexScan.pas`) recebe os escritores, a função de paragem (`ReadStopRequested`) e o `DoProgress`.
- Devolve `False` **sem escrever nada** se não se aplicar (Win32, ficheiro pequeno); nesse caso segue o caminho sequencial.
- Erros de leitura levantam exceção (tratada pelo `except` de `Execute`).

**Caminho sequencial** (Win32 e ficheiros < 128 MB):

1. Mapeia o ficheiro em memória (`TMMFReader`, libertado num `try/finally` próprio).
2. Pede ao MMF a região contígua seguinte (`PtrAt`).
3. Divide a região em fatias de até **64 MB**.
4. Em cada fatia, `ScanBufferForLineFeeds` procura o `TermByte` com AVX2/SWAR e chama `OnLf` para cada ocorrência.
5. Depois de cada fatia, chama `DoProgress`.
6. Para quando:
  - chega ao fim do ficheiro;
  - o utilizador cancela (`ReadStopRequested` = `Terminated` ou `TfrmSmoothLoading.IndexReadShouldStop`);
  - o MMF não devolve mais dados;
  - passa de **2 mil milhões de linhas** → `FHitLineLimit := True`.

No fim, chama `DoProgress(FTotalSize)` e grava no log de runtime uma linha `[ReadIndex] path=parallel|sequential bytes=... lines=... ms=...`.

#### 5.5.1 Pipeline paralelo (`uLineIndexScan.pas`)

```
workers (1 a 8 threads)                       thread de TReadFileThread (junção)
 ├─ pega o próximo bloco de 32 MB (em ordem)   ├─ espera o bloco K ficar pronto
 ├─ espera o slot do bloco K-janela ser livre  ├─ grava os índices a partir do mapa
 ├─ mapa de bits: 1 bit por byte (SSE2)        ├─ liberta o slot, avança K
 └─ conta as quebras (popcount), publica       └─ progresso / cancelamento
```

- **Blocos de 32 MB** (`LINE_INDEX_CHUNK_BYTES`), lidos por MMF (uma view por bloco).
- **Mapa de bits**: para cada 64 bytes do bloco, uma palavra de 64 bits com bit 1 onde o byte é o terminador. Feito com SSE2 (`pcmpeqb` + `pmovmskb`), presente em todas as CPUs x64. Funciona para LF e CR.
- **Janela** de `2 × workers` slots: a memória fica em cerca de 4 MB por slot (até 64 MB no total), qualquer que seja o tamanho do ficheiro ou o número de linhas. Não há mais o limite de RAM que fazia a versão antiga desistir e reler o ficheiro.
- **Junção**:
  - **Sem índice denso** (ficheiros > 2 GB, incluindo o Zero Scan): só visita as linhas que vão para o checkpoint (1 em 1024, localizadas por popcount) e a primeira linha de cada bloco de 64 MB do Zero Scan. O custo deixa de ser proporcional ao número de linhas.
  - **Com índice denso** (até 2 GB): percorre todas as quebras do mapa, como o caminho sequencial.
- **HDD** (disco com seek): um só worker, para manter a leitura sequencial; a junção continua noutra thread.
- Grava no log de runtime uma linha `[LineIndexScan] parallel workers=... direct=... depth=... chunks=... ms=...`.

#### 5.5.2 Leitura directa sem cache (ficheiros grandes face à RAM)

Quando o ficheiro tem pelo menos **RAM física / 4** (`LINE_INDEX_DIRECT_RAM_DIVISOR`; ex.: 5 GB numa máquina de 20 GB), os workers MMF são substituídos por **um único leitor sequencial** (`TLineIndexDirectReader`, `DirectLoop`):

- Abre o ficheiro com `FILE_FLAG_NO_BUFFERING or FILE_FLAG_OVERLAPPED` e lê blocos de 32 MB com `ReadFile` para buffers alinhados (`VirtualAlloc`), mantendo `LINE_INDEX_DIRECT_QUEUE_DEPTH` (2) leituras em voo enquanto o bloco anterior é transformado em mapa de bits na mesma thread. Buffers = depth + 1 (96 MB), independentemente do tamanho do ficheiro.
- Sem page-faults de 4 KB, sem `MapViewOfFile` por bloco e **sem passar pelo cache do sistema**: um ficheiro de 80 GB deixa de expulsar o resto da RAM durante a indexação.
- Pedidos alinhados a 64 KB (`LINE_INDEX_DIRECT_ALIGN`), que cobre qualquer tamanho de sector; o último bloco é pedido arredondado e só os bytes reais são usados.
- **Fallback**: `TryCreate` lê o bloco 0 como prova; se o volume não aceitar a flag (NTFS comprimido/EFS, driver de rede, `ERROR_INVALID_PARAMETER`) ou se uma leitura falhar a meio, os blocos restantes seguem por MMF (`ScanChunk`) e nada se perde. Fica no log `direct read unavailable` / `direct read fallback to MMF`.
- Abaixo do limiar o MMF é mantido: aí o cache do sistema compensa (reabertura a quente do mesmo ficheiro em < 1 s).
- Win32: sempre MMF/sequencial.
- Para teste e bench: `GLineIndexDirectReadMode` (`ldAuto`/`ldOff`/`ldOn`) e `GLineIndexDirectQueueDepth`. `LineIndexScanTest.exe bench <ficheiro> [mmf|direct|seq|all] [depth]`.

Medição (ficheiro de 11 GB, 5,5 milhões de linhas, NVMe PCIe 3, i5-10210U, só checkpoint):

| Leitura                                   | Tempo   | Vazão      |
| ----------------------------------------- | ------- | ---------- |
| MMF, 8 workers (antes)                    | 12,2 s  | 861 MB/s   |
| **Directa, 2 em voo (padrão)**            | **7,7 s** | **1.354 MB/s** |
| Directa, 1 em voo                         | 9,5 s   | 1.098 MB/s |
| Directa, 4 em voo                         | 7,7 s   | 1.367 MB/s |
| Leitura pura do disco (sem indexar)       | 7,8 s   | 1.337 MB/s |

Com 2 em voo a indexação fica no limite do disco; mais leitores em paralelo (2 ou 4 threads) foram **mais lentos** que um leitor sequencial neste e em discos SATA/HDD, por isso o leitor é único.

Medição (ficheiro de 9 GB, 95 milhões de linhas, nesta máquina; o disco é o limite):


| Modo                                        | Antes                          | Depois      |
| ------------------------------------------- | ------------------------------ | ----------- |
| Zero Scan sob demanda (checkpoint + blocos) | 34–82 s (sequencial, 1 thread) | 11,6–16 s   |
| Só checkpoint (modo normal > 2 GB)          | 13,8–15 s                      | 12,4–14,6 s |


No modo só checkpoint a versão antiga já estava no limite do disco neste ficheiro; o ganho aparece nos ficheiros com muitas linhas, em que a versão antiga ultrapassava o limite de RAM e lia o ficheiro duas vezes.

### 5.6 Erros

O `except` de `Execute` apanha qualquer exceção, marca `FIndexFailed := True` e guarda a mensagem em `FIndexErrorMsg`. A thread continua até ao `finally` e ao `FinishThreadExecution`.

### 5.7 `FinalizeIndexFiles` (sempre, no `finally`)

1. Liberta os escritores do denso e do checkpoint. Isto despeja os buffers no disco e tem de vir **antes** de fechar os temporários do Zero Scan, que são o destino desses escritores.
2. **Zero Scan:** para cada temporário (`zsdense` → `temp.txt`, `zsckpt` → `temp_ckpt.txt`), `CommitTempIndexFile`:
  - fecha o temporário (o ficheiro é aberto sem partilha, por isso só pode ser renomeado depois de fechado);
  - se a leitura terminou **sem cancelamento e sem erro**, move-o para o nome final;
  - caso contrário, apaga-o.
3. **Normal:** se não houve cancelamento, move `ckpti` → `temp_ckpt.txt`; se cancelou ou a renomeação falhou, apaga o temporário.
4. Índice de blocos: chama `FinalizeIndex` (só sem cancelamento) e liberta-o.

`TryRenameTempOverTarget` apaga primeiro o ficheiro de destino, tenta renomear até 120 vezes (100 ms entre tentativas), tenta copiar e, se tudo falhar, apaga o temporário.

### 5.8 `FinishThreadExecution`


| Situação                                 | O que acontece                                                                          |
| ---------------------------------------- | --------------------------------------------------------------------------------------- |
| Cancelado                                | Mostra "cancelado", esconde a janela de carregamento, reinicia o pedido de cancelamento |
| Mais de 2 mil milhões de linhas          | Mostra o aviso "airbag"                                                                 |
| Falhou ou excedeu o limite (modo normal) | Oferece a leitura alternativa (`HandleReadIndexFailure`)                                |
| Sucesso (ou modo Zero Scan)              | `SyncFinishFileNameRead`: grava a cache do índice, mostra o tempo e o total de linhas   |


O total de linhas mostrado é `totalLines + 1`, porque a última linha não termina em quebra de linha.

## 6. Correções feitas na reorganização

1. **Temporários do Zero Scan nunca eram publicados.**
  - `TTemporaryFileStream` herda de `THandleStream`, que no Delphi 10.4 **não fecha o handle** ao ser libertado; o ficheiro era aberto sem partilha e a renomeação era tentada com ele ainda aberto.
  - Resultado: cerca de 12 s de tentativas por ficheiro, `temp.txt` / `temp_ckpt.txt` ausentes e temporários + handles presos até o FastFile fechar.
  - Correção: `TTemporaryFileStream.Destroy` fecha o handle; a nova propriedade `DeleteFileOnDestroy := False` mantém o ficheiro para ser renomeado depois de fechado (`CommitTempIndexFile`).
  - Teste: `tests/agent/TempStreamTest.dpr`.
2. **No Zero Scan, um índice incompleto (erro a meio) já não é publicado.**
3. **Cancelamento no modo normal** apaga agora o temporário `ckpti` em vez de o deixar na pasta temp.
4. **Falso positivo do SWAR** no caminho sequencial: um byte `$0B` logo após um LF era contado como quebra de linha (empréstimo da subtração). Agora cada bit é confirmado no byte.
5. **Zero Scan sob demanda e índice denso** passaram a usar o pipeline paralelo (antes, só o modo "só checkpoint" era paralelo).
6. Teste de equivalência: `tests/agent/LineIndexScanTest.dpr` compara paralelo e sequencial com uma referência byte a byte (denso, checkpoint, blocos; LF, CR, ficheiro só de quebras). `LineIndexScanTest.exe bench <ficheiro>` mede os tempos.
7. Removidos: `LastProgressOffset` (sem uso), o `begin ... end` sobrando após `try try`, e o prefixo `F` em variáveis locais (`FCurrentPermille` → `CurrentPermille`, `FSparseCkptOnly` → `SparseCkptOnly`).



## 7. Cuidados de performance

Ao mexer nesta rotina:

- `OnLf` **corre uma vez por linha** (milhares de milhões de vezes em ficheiros grandes). Não acrescente chamadas, strings, `Format` ou testes extra lá dentro.
- As variáveis usadas em `OnLf` (`IdxW`, `CkptW`, `BlkW`, `SparseCkptOnly`, `LineOff`) são **locais de** `ScanLineFeeds` **capturadas** pelo procedimento anónimo. Trocá-las por campos da classe ou pelo record `W` acrescenta uma indireção por linha.
- O tamanho das fatias (64 MB) e dos buffers (2–32 MB) foi escolhido para a varredura SWAR; alterá-los muda a performance.
- No pipeline paralelo, a junção corre numa só thread: não acrescente trabalho por linha em `MergeChunkSparse` (ela só visita 1 linha em 1024).
- Na leitura directa, `Acquire(K)` tem de ser chamado em ordem crescente e o buffer de K só é reutilizado por K + depth + 1; não processe o buffer depois de `Acquire(K + 1)`. Os buffers só podem ser libertados depois de `CancelIo` + espera de todos os pedidos pendentes (`CancelAll`).
- `LINE_INDEX_CHUNK_BYTES` tem de ser múltiplo de 64 e da granularidade de alocação do Windows (64 KB).
- `DoProgress` tem throttling (12 milésimos / 45 ms) para não inundar a janela de mensagens.
- A divisão em métodos acontece **fora** do laço: as chamadas extra (`PrepareIndexWriters`, `FinalizeIndexFiles`, ...) correm uma vez por leitura.

