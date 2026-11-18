# FastFile — Índice esparso, passo a passo (`PI121106.txt`)

**Documento de referência** (16 de novembro de 2026)  
Versão de referência: **`3.0.5.269`** (Delphi 10.4.2 Win64)  
Exemplo real: leitura de `C:\Hamden\PI121106.txt`  
Unidades: `uSmoothLoading.pas`, `uLineIndexScan.pas`, `uFastFilePaths.pas`, `MainUnit.pas`, `UnConsts.pas`

> **Documentos relacionados**  
> - [DOC_INDEXACAO_F5_MMF_WRITER.md](DOC_INDEXACAO_F5_MMF_WRITER.md) — quem grava o índice na abertura (F5)  
> - [DOC_TREADFILETHREAD_EXECUTE.md](DOC_TREADFILETHREAD_EXECUTE.md) — `TReadFileThread.Execute`  
> - [ARQUITETURA_TECNICA_FASTFILE.md](ARQUITETURA_TECNICA_FASTFILE.md) — visão geral do índice

Este texto regista como o FastFile descobre as linhas e como salta para uma linha usando os ficheiros gerados por essa leitura. O intervalo do checkpoint é **1024** (`CKPT_INTERVAL`).

---

## 0. Confirmações rápidas — linha 5 do `temp_ckpt` = `1306380`

Trecho real do checkpoint (os mesmos valores aparecem em `src\Output\temp_ckpt.txt` ou ao lado do `.exe`, conforme a pasta de execução):

```text
                 1     ← linha 1 do editor = registo k=0
            326412     ← linha 2 = k=1
            653068     ← linha 3 = k=2
            979724     ← linha 4 = k=3
           1306380     ← linha 5 = k=4   ← foco
           1633036     ← linha 6 = k=5   ← próximo marcador
```

### Pergunta 1 — A linha 5 cobre as linhas 5120..6143 na ListView?

**Não.** Com “linha 5” = 5.ª linha no editor do `temp_ckpt.txt`:

| Contagem | Valor |
|----------|--------|
| Índice do registo **k** (0-based) | **4** (= linha do editor − 1) |
| Offset guardado | **1306380** (byte **1-based** no ficheiro fonte) |
| Linhas na ListView (**0-based** `LineIndex`) | **4096 .. 5119** |
| Linhas no fonte (**1-based**) | **4097 .. 5120** |

O intervalo **5120 .. 6143** (0-based) / **5121 .. 6144** (1-based) é o da **linha 6** do ckpt (`1633036`, k=5), não o da linha 5.

Fórmula:

```text
k              = (linha_no_editor_do_ckpt) - 1
LineIndex_ini  = k × 1024          (0-based; inclusivo)
LineIndex_fim  = (k + 1) × 1024 - 1
linha_fonte    = k × 1024 + 1      (1-based; início do bloco)
```

No `MainUnit` (ramo esparso da ListView):

```text
CkptIdx   := LineIndex div CKPT_INTERVAL;   // 0-based
SkipCount := LineIndex mod CKPT_INTERVAL;
```

### Pergunta 2 — Lê a partir de `1306380` até ao próximo offset?

**Sim, no sentido da fronteira de bytes do bloco**, com estes detalhes:

| Ponto | Valor | Significado |
|-------|------:|-------------|
| Início deste bloco | **1306380** | Início da linha 4097 do fonte (1-based) |
| Próximo registo no ckpt | **1633036** | Início da linha 5121 (já é o bloco seguinte) |
| Último byte deste bloco | **1633035** | Byte imediatamente anterior a `1633036` |

Ou seja: o conteúdo deste bloco no fonte ocupa **`1306380` .. `1633035`** (inclusive). O valor **`1633036` já está escrito** na linha 6 do `temp_ckpt`; não é “um depois do próximo”.

**Importante para a ListView:** ela **não** lê as 1024 linhas de uma vez a partir desse intervalo. Para cada item visível:

1. escolhe o registo `CkptIdx` (`LineIndex div 1024`);
2. se `SkipCount > 0`, conta esse número de fins de linha no fonte a partir do offset do marcador;
3. lê **só essa linha** até ao próximo fim de linha.

O próximo marcador define a fronteira do bloco; não é o fim de uma única leitura em massa.

### Armadilha comum (off-by-one)

| Confusão | Correcção |
|----------|-----------|
| “Linha 5 do ckpt ⇒ 5 × 1024 = 5120” | No editor a linha 5 é **k=4** ⇒ 4 × 1024 = **4096** (0-based) |
| “Próximo offset é 1633035” | **1633035** é o último byte do bloco; o **próximo marcador** é **1633036** |
| “O ckpt é o índice completo” | Acima de 2 GB só existe o ckpt; até 2 GB o denso `temp.txt` (1 offset por linha) tem prioridade |

Se existir `temp.txt` válido, `ResolveWorkingLineIndexPath` e o ramo `FIndexFileStream` preferem o denso: a ListView **não** usa este cálculo do ckpt.

---

## 1. Os dois ficheiros desta leitura

Os ficheiros de trabalho ficam ao lado do `.exe` (`FastFileExeDirPath` = `ExtractFilePath(ParamStr(0))`). Conforme a pasta de execução, o mesmo conteúdo pode aparecer em `src\Build\Win64\`, `src\Output\`, etc.

| Ficheiro | Exemplo de caminho | Papel |
|----------|---------------------|--------|
| `temp_index.meta` | `…\temp_index.meta` | Identifica o fonte e guarda o total de linhas |
| `temp_ckpt.txt` | `…\temp_ckpt.txt` (ex.: `src\Output\temp_ckpt.txt`) | Marcadores: o byte onde começa 1 linha em cada 1024 |

O `PI121106.txt` tem **2.959.579.235 bytes** (cerca de 2,96 GB), acima do corte de 2 GB (`DENSE_INDEX_MAX_BYTES`). Por isso **não** existe `temp.txt` denso. Um denso teria cerca de 9,2 milhões × 20 bytes ≈ 177 MB. O checkpoint ficou com **181.220 bytes**.

---

## 2. `temp_index.meta` — o que é cada linha

Conteúdo gravado por `WriteLineIndexMetaFile` (`uFastFilePaths.pas`), cinco linhas de texto:

```text
V1
C:\Hamden\PI121106.txt
2959579235
134371439539462525
9277689
```

| Linha | Valor neste ficheiro | Significado |
|-------|----------------------|-------------|
| 1 | `V1` | Versão deste formato. `ReadLineIndexMetaFile` só aceita o cache se a primeira linha for exactamente `V1`. |
| 2 | `C:\Hamden\PI121106.txt` | Caminho completo do ficheiro fonte. Tem de coincidir (`SameText`) com o ficheiro que se está a abrir. |
| 3 | `2959579235` | Tamanho do fonte, em bytes. |
| 4 | `134371439539462525` | Data da última gravação do fonte, em `FILETIME` do Windows: tiques de 100 ns desde 01/01/1601. Neste caso, **22/10/2026 08:59:13** (horário de Brasília). O valor guardado é `(dwHighDateTime shl 32) or dwLowDateTime`. |
| 5 | `9277689` | **Total de linhas: 9.277.689.** Veio da passagem completa que conta cada fim de linha. Não é uma estimativa. |

O cache só é reutilizado se versão, caminho, tamanho, data de gravação e total de linhas (maior que zero) baterem certo. Se o ficheiro for alterado, o meta deixa de valer e o índice é refeito.

---

## 3. `temp_ckpt.txt` — formato de cada marcador

Cada marcador é um registo de texto de **20 bytes**, o mesmo formato do `temp.txt` denso (`INDEX_RECORD_SIZE`):

| Bytes | Conteúdo |
|-------|----------|
| 0..17 | Offset **1-based** do início da linha, em ASCII, alinhado à direita com espaços |
| 18..19 | CR LF |

Não é um `Int64` binário. A leitura faz `Seek(indice * 20)`, lê 18 caracteres e converte com `StrToInt64Def(Trim(...))`.

Nesta leitura: **181.220 ÷ 20 = 9.061 registos**, sem resto.

Os primeiros marcadores medidos:

| Índice do registo (0-based) | Offset (byte 1-based) | Linha onde o bloco começa |
|-----------------------------|------------------------|---------------------------|
| 0 | 1 | 1 |
| 1 | 326412 | 1025 |
| 2 | 653068 | 2049 |
| 3 | 979724 | 3073 |
| 4 | 1306380 | 4097 |
| 5 | 1633036 | 5121 |

O número no registo é a **posição em bytes** no `PI121106.txt`, não o número da linha.

---

## 4. Como o FastFile descobre as linhas

Na indexação (`TReadFileThread`) o fonte é lido por completo. Cada fim de linha encontrado soma 1 ao total. O texto das linhas **não** é copiado para o índice.

De 1024 em 1024 linhas grava-se um marcador com o byte onde a linha seguinte começa. No código, «múltiplo de 1024» é testado com máscara de bits, porque 1024 é potência de 2:

```text
(totalLines and (CKPT_INTERVAL - 1)) = 0
```

`CKPT_INTERVAL = 1024` está em `UnConsts.pas` e também como constante local em `uSmoothLoading.pas`.

Cada linha do `temp_ckpt.txt`, contada a partir de **0**, multiplicada por 1024 e somada 1, é a linha do fonte onde esse bloco começa:

```text
linha do fonte = índice do marcador × 1024 + 1
```

| Linha do `temp_ckpt.txt` (a contar de 0) | Conta | Linha do fonte |
|------------------------------------------|--------|----------------|
| 0 | 0 × 1024 + 1 | 1 |
| 1 | 1 × 1024 + 1 | 1025 |
| 2 | 2 × 1024 + 1 | 2049 |
| 9060 | 9060 × 1024 + 1 | 9.277.441 |

Num editor, as linhas do `temp_ckpt.txt` aparecem a contar de 1. Aí a conta é `(linha do ckpt - 1) × 1024 + 1`. A primeira linha do checkpoint é a linha 1 do fonte; a segunda é a linha 1025.

O valor escrito nessa linha continua a ser o **byte** de início, não o número da linha. No registo 1 está `326412`: é o byte da linha 1025.

Cada bloco completo cobre 1024 linhas. O último bloco pode ficar incompleto: o ficheiro acaba antes de chegar ao próximo múltiplo.

---

## 5. Como saltar para uma linha

(As confirmações com o valor `1306380` estão na [secção 0](#0-confirmações-rápidas--linha-5-do-temp_ckpt--1306380).)

A fórmula, com a linha **1-based**:

```text
bloco     = (LINHA - 1) div 1024
resto     = (LINHA - 1) mod 1024
```

`div` é a divisão inteira. O resto é quantos fins de linha ainda faltam contar a partir do marcador.

1. Lê o registo `bloco` em `temp_ckpt.txt` (`Seek(bloco * 20)`).
2. Esse offset é o início da primeira linha do bloco.
3. Se `resto > 0`, percorre o **ficheiro fonte** a contar `resto` fins de linha. O byte seguinte é o início da linha pedida.
4. Mais um fim de linha marca o fim dessa linha. O texto lido é só essa linha.

O próximo marcador é a fronteira do bloco, não o fim da leitura. A aplicação não lê as 1024 linhas do bloco para achar uma.

### Linha 400

- bloco = `(400 - 1) div 1024` = **0**
- resto = **399**
- parte do byte 1 e conta 399 fins de linha

### Linha 1024

- bloco = `(1024 - 1) div 1024` = **0**
- resto = **1023**
- ainda é o primeiro bloco; é o salto mais longo possível dentro dele

### Linha 1025

- bloco = `(1025 - 1) div 1024` = **1**
- resto = **0**
- o marcador já é o início da linha: byte **326412**, sem contar mais nenhum fim de linha

### Linha 2500

- bloco = `(2500 - 1) div 1024` = **2**
- resto = **451**
- parte do byte **653068** (linha 2049) e conta 451 fins de linha

No caminho da lista, `LineIndex` já é 0-based, então a conta é `LineIndex div 1024` e `LineIndex mod 1024` (`MainUnit`, ramo esparso). No script, a linha é 1-based e a conta é `(linha - 1) div / mod` (`TryReadSparseLineStartOffset`). O resultado é o mesmo.

---

## 6. A lista não carrega o bloco

A `ListView` é *owner-data*: só as linhas visíveis pedem texto, uma de cada vez. Ir à linha 400 não preenche a lista com as 1024 linhas do bloco 0. Cada pedido repete o salto: marcador do bloco e, se preciso, a contagem dos fins de linha que faltam.

---

## 7. Por que 9.061 registos não são 9.278.464 linhas

A última linha do meta diz **9.277.689** linhas. O checkpoint tem **9.061** registos. Esses 9.061 são a **quantidade** de marcadores, numerados de **0 a 9060**.

O último bloco é o **9060** porque o primeiro é o 0 (a linha 1). Não existe um bloco 9061.

```text
9060 × 1024 + 1 = 9.277.441
```

O último marcador é o início da linha **9.277.441**. O ficheiro acaba na linha **9.277.689**.

Conferência com a fórmula:

```text
(9.277.689 - 1) div 1024 = 9.277.688 div 1024 = 9060
(9.277.689 - 1) mod 1024 = 248
```

A última linha está 248 fins de linha depois do início desse bloco. O bloco contém as linhas **9.277.441 até 9.277.689**: **249 linhas**, não 1024.

`9061 × 1024 = 9.278.464` conta um bloco a mais e trata esse bloco como se estivesse cheio. A diferença é 775 linhas:

```text
9.278.464 - 9.277.689 = 775
1024 - 249 = 775
```

Quantidade de registos = último índice + 1 = `9060 + 1` = **9061**, porque `(total - 1) div 1024` do último linha é 9060 e os índices 0..9060 são 9061 posições.

---

## 8. Onde o checkpoint fica depois de fechar

Enquanto a sessão está aberta, o ficheiro de trabalho é `temp_ckpt.txt` na pasta do executável, junto com `temp_index.meta`.

Ao sair, `CleanupFastFileLineIndexFiles` apaga da pasta do exe `temp.txt`, `temp_ckpt.txt` e `temp_index.meta`.

Para ficheiros **acima de 2 GB**, `SaveLineIndexCache` copia antes o checkpoint para um sidecar, para a próxima abertura do mesmo ficheiro (inalterado) não repetir a passagem de 2,96 GB:

| Peça | Caminho neste exemplo |
|------|------------------------|
| Pasta | `src\Build\Win64\fastfile_temp\` |
| Checkpoint | `C__Hamden_PI121106.txt.ffckpt` |
| Meta | `C__Hamden_PI121106.txt.ffmeta` |

O nome seguro troca os caracteres ilegais do caminho (`:` e `\`) por `_`: `C:\Hamden\PI121106.txt` → `C__Hamden_PI121106.txt`. Sufixos: `SOURCE_LINE_INDEX_CKPT_SUFFIX = '.ffckpt'` e `SOURCE_LINE_INDEX_META_SUFFIX = '.ffmeta'`.

Na abertura seguinte, se caminho, tamanho e `FILETIME` ainda coincidirem, `TryRestoreSourceSidecarToExeCache` copia o sidecar de volta para `temp_ckpt.txt` e regrava o `temp_index.meta` ao lado do exe.
