# FastFile — Comparar / mesclar + histórico da sessão (guia passo a passo)

Este documento descreve, em sequência, como funcionam o diff entre dois ficheiros, a colorização nas listas, a aplicação da **mesclagem** em disco e a pré-visualização por journal na primeira aba.

**Unidades principais:** `uLineDiffCore.pas`, `uCompareMergeUI.pas`, `uFileSessionHistory.pas`, `uSmoothLoading.pas` (threads de edição).

---

## Parte A — Abrir o diálogo e carregar dados

### Passo 1 — Abrir o modal

No menu **Opções**, escolhe-se **Comparar / mesclar + histórico…**. O formulário `TfrmCompareMerge` (`uCompareMergeUI`) abre em modo modal.

### Passo 2 — Caminhos predefinidos

O ficheiro **esquerdo** (`edtLeftFile`) pode vir preenchido com o mesmo caminho que o ficheiro aberto na janela principal (parâmetro passado em `ExecuteModal`).

### Passo 3 — Duas abas

- **Primeira aba — Histórico da sessão:** texto do journal (memo) + lista de pré-visualização do ficheiro com cores (ver Parte D).
- **Segunda aba — Diff entre dois ficheiros:** campos de ficheiro esquerdo/direito, intervalo de linhas, botão para gerar o diff e duas `TListView` lado a lado.

---

## Parte B — Gerar o diff (comparação linha a linha)

### Passo 1 — Escolher ficheiros e janela

Na segunda aba, indicam-se:

- caminho do **ficheiro esquerdo** e do **ficheiro direito** (ambos devem existir em disco);
- **primeira** e **última** linha do intervalo a comparar (limitado internamente, por exemplo até `FF_DIFF_MAX_LINES` linhas no total).

### Passo 2 — Ler trechos do disco

A função **`ReadTextFileLineSlice`** (em `uCompareMergeUI.pas`):

- abre o ficheiro em streaming;
- lê por blocos (buffer);
- constrói duas `TStringList` só com as linhas do intervalo pedido.

Assim não carrega ficheiros enormes inteiros em memória para o diff.

### Passo 3 — Chamar o núcleo do diff

Chama-se **`FFBuildLineDiffRows(Left, Right, AMaxDim, ADiff)`** em **`uLineDiffCore.pas`**.

### Passo 4 — O que o algoritmo faz (resumo)

1. Trunca `n` e `m` ao máximo permitido (`AMaxDim`) se preciso.
2. Reserva uma matriz plana de inteiros `(n+1)×(m+1)` (programação dinâmica estilo **LCS** — maior subsequência comum de linhas **iguais**).
3. Preenche a matriz: se `Left[i-1] = Right[j-1]` incrementa a diagonal; senão toma o máximo da célula “acima” ou “à esquerda”.
4. **Percorre para trás** a partir de `(n, m)` até esvaziar os índices, emitindo registos **`TFFDiffRow`** com:
   - **`Kind`:** `ffdkEqual`, `ffdkDelete`, `ffdkInsert`, ou (depois) `ffdkChange`;
   - **`LNum` / `RNum`:** número de linha 1-based no ficheiro esquerdo/direito (0 quando não aplicável);
   - **`LText` / `RText`:** texto desse lado.
5. No fim, **agrupa** pares consecutivos **delete + insert** num único **`ffdkChange`** quando faz sentido para a UI.

O resultado fica numa **`TList`** de ponteiros **`PFFDiffRow`** (lista `ADiff`).

### Passo 5 — Preencher as duas ListViews

Para cada entrada em `FDiffRows`:

1. Cria-se um item em **`lvLeft`** e outro em **`lvRight`**.
2. **Os dois** partilham o **mesmo** `Item.Data := Rr` (mesmo `PFFDiffRow`).
3. **`Caption`** da primeira coluna: número de linha (`LNum` ou `RNum`) ou vazio onde não há linha desse lado.
4. **Primeiro subitem:** texto da linha (`LText` ou `RText`).

Assim cada **linha do diff** é uma linha visual alinhada; não há mesclagem **entre** listas na memória — há **duas vistas** do mesmo registo lógico.

---

## Parte C — Colorir o diff (CustomDraw)

### Passo 1 — Evento de desenho

Ambas as listas usam **`OnCustomDrawItem`** (por exemplo `lvLeftCustomDrawItem`; a direita pode chamar a mesma rotina).

### Passo 2 — Ler o tipo de linha

- Se `Item.Data` é `nil`, trata-se como linha “igual” (cor neutra / igual).
- Senão, lê-se **`PFFDiffRow(Item.Data)^.Kind`**.

### Passo 3 — Cor de fundo

A função **`BrushForKind`** devolve uma `TColor` por `TFFDiffKind`:

- **Igual** — verde claro;
- **Alteração** — azul claro;
- **Removido no diff (só esquerda)** — lilás;
- **Inserido no diff (só direita)** — amarelo claro.

### Passo 4 — Desenho manual

- **`DefaultDraw := False`** para o controlo não pintar o item por defeito.
- Preenche-se o retângulo com a cor da escova e desenha-se o número e o texto com **`Canvas.TextRect`**.

A **legenda** no formulário explica o esquema (igual / inserido / removido / alterado).

---

## Parte D — Aba “Histórico”: memo + lista colorida pelo journal

### Passo 1 — Journal em texto

O memo mostra o conteúdo do ficheiro de log devolvido por **`FFHistoryJournalPath(caminhoDoFicheiroDeDados)`** (pasta `FastFileSessionHistory`, formato linha com campos separados por `|`).

### Passo 2 — Construir a pré-visualização (`BuildHistoryFilePreview`)

1. Lê-se até um limite de linhas do **ficheiro de dados** atual (streaming, como no diff).
2. Lê-se o **mesmo** ficheiro de journal linha a linha.
3. Linhas que começam por `#` ou estão vazias são ignoradas.
4. As restantes são **partidas por `|`** (`HistSplitPipeFields`).
5. Consoante a operação (**INS**, **EDT**, **DEL**, **RPLALL**):
   - para **INS/EDT/DEL** atualiza-se um “tag” por **número de linha** indicado no journal (última ocorrência ganha, ao percorrer em ordem);
   - para **RPLALL** pode marcar-se todas as linhas da pré-visualização com um tipo “bulk” (substituição global).

### Passo 3 — Cores na lista do histórico

Cada item guarda o tag em **`Item.Data`** e **`lvHistFileCustomDrawItem`** usa **`BrushForHistTag`** (esquema de cores **separado** do diff LCS).

**Nota:** os números de linha no journal são os da **altura da operação**. Depois de muitas inserções ou remoções, a cor por linha pode não refletir com precisão absoluta o estado histórico — é uma **pré-visualização orientada ao log**, não um replay completo do ficheiro.

---

## Parte E — Aplicar mesclagem no disco (botões e menu de contexto)

### Passo 1 — Selecionar linhas

O utilizador escolhe uma ou mais linhas na lista esquerda **ou** direita (desde que exista seleção). O código percorre os itens selecionados com `Item.Data <> nil` e obtém o **`PFFDiffRow`**.

### Passo 2 — Classificar operações

Consoante `Kind`, os ponteiros são colocados em listas auxiliares (por exemplo delete / change / insert), com **significados diferentes** conforme o sentido da mesclagem (esquerda→direita vs direita→esquerda). A implementação mapeia cada `Kind` para **`otDelete`**, **`otEdit`**, **`otInsert`** no ficheiro **alvo**.

### Passo 3 — Ordenar antes de aplicar

As operações são ordenadas com **`SortDiffPtrList`** e comparadores por número de linha (ascendente ou descendente) para que **apagar antes de inserir/editar** não corrompa os números de linha seguintes.

### Passo 4 — Escrita em disco

Para cada operação chama-se **`TEditFileThread.RunEditWait`**, que reutiliza o mesmo pipeline de edição do editor (sem deadlock com `Application.ProcessMessages`, etc.).

### Passo 5 — Sentidos

- **Aplicar esquerda → direita:** ficheiro alvo = **direito** (`edtRightFile`).
- **Aplicar direita → esquerda:** ficheiro alvo = **esquerdo** (`edtLeftFile`).

### Passo 6 — Depois do sucesso

- Se o ficheiro gravado for o **mesmo** que o aberto na janela principal, o modal pode sinalizar **recarregar** (`RefreshFile`).
- Se o caminho gravado for o da **sessão** (`FDefaultLeft`), pode atualizar-se memo + pré-visualização do histórico.

---

## Parte F — Ficheiros e constantes úteis

| Ficheiro | Papel |
|----------|--------|
| `uLineDiffCore.pas` | Tipos `TFFDiffKind`, `FFBuildLineDiffRows` |
| `uCompareMergeUI.pas` | UI, `ReadTextFileLineSlice`, listas, mesclagem em disco, journal preview |
| `uFileSessionHistory.pas` | Caminho e append do journal |
| `uSmoothLoading.pas` | `TEditFileThread.RunEditWait` e histórico de operações de linha |

Constantes típicas: `FF_DIFF_MAX_LINES`, limite de linhas na pré-visualização do histórico no código (`cHistPreviewMaxLines` ou nome semelhante).

---

## Glossário rápido

| Termo | Significado |
|--------|-------------|
| **LCS (neste contexto)** | Maior cadeia de linhas **iguais** entre os dois lados; base do preenchimento da matriz. |
| **`PFFDiffRow`** | Uma linha lógica do diff (tipo + números + textos). |
| **CustomDraw** | Desenho manual da linha da lista com cores por `Kind` ou por tag de histórico. |
| **Mesclagem aplicada** | Alterações gravadas no ficheiro escolhido com as mesmas operações que o editor usa. |

---

*Documento gerado para acompanhar o código em `FileReadThread-2\Src`. Alinhar com `CHANGELOG_IMPLEMENTACOES.md` e versão em `UnConsts.pas` quando houver alterações de comportamento.*
