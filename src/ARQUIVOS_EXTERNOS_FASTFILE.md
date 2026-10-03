# FastFile — Arquivos externos e recursos em disco

**Projeto:** FastFile (Delphi 7)  
**Pasta de referência:** `FileReadThread-2\Src`  
**Data do documento:** março de 2026  

Este documento descreve **arquivos e pastas** que a aplicação **lê, grava ou espera encontrar** junto ao executável ou em outros locais, e **para que servem**.  
A maioria dos caminhos fixos usa: `ExtractFilePath(Application.ExeName)` ou `ExtractFilePath(ParamStr(0))` — ou seja, **a pasta onde está o `.exe`**, salvo indicação em contrário.

---

## 1. Visão geral

| Categoria | Exemplos |
|-----------|----------|
| **Índice de linhas** | `temp.txt` |
| **MRU / recentes** | `mru_files.ini`, `mru_location.ini`, `mru_content.ini` |
| **Skin e recursos visuais** | `ASkin.ini`, pasta `Skins\`, `texture.bmp`, `logo.bmp` |
| **Dados auxiliares (XML)** | `folders.xml`, `files.xml` |
| **Logs de erro** | `Log_FastFile<datahora>.txt` |
| **Arquivo do usuário** | Qualquer ficheiro aberto pela UI (`edtFileName`) |
| **Temporários do Windows** | Via `GetTempPath` em vários módulos |

Constantes de nomes conhecidos aparecem em **`UnConsts.pas`** (ex.: `TEMPFILE = 'temp.txt'`, `ASKIN_INI`, `XMLFOLDERS`, `XMLFILES`).

---

## 2. Pasta do executável — índice e leitura de ficheiros grandes

### `temp.txt` (constante `TEMPFILE`)

- **O que é:** arquivo de **índice de linhas** do ficheiro fonte aberto: registra offsets (posições) de cada linha no arquivo principal.
- **Onde fica:** mesma pasta do `.exe` (referências em `MainUnit.pas`, `UnReadFileThread_utf8.pas`, `uSmoothLoading.pas`, etc.).
- **Nota:** O nome sugere “temporário”, mas na prática é o **índice usado** para navegação, busca e operações até nova leitura do arquivo; mensagens da aplicação citam `temp.txt` quando o índice não existe.

---

## 3. Pasta do executável — MRU e recentes

### `mru_files.ini`

- **O que é:** lista de **arquivos recentes** (atalho **Ctrl+R** e menu/popup de recentes).
- **Formato:** seção típica `[RecentFiles]`, chave `Count`, entradas `File0`, `File1`, …
- **Comportamento:** se um caminho escolhido **não existir mais**, a aplicação pode **avisar** e **remover** a entrada da lista e gravar de novo o INI.

### `mru_location.ini`

- **O que é:** histórico MRU do campo de **localização** (até 25 itens), gerido por **`TMruHelper`** no `FormCreate` do `MainUnit.pas`.

### `mru_content.ini`

- **O que é:** histórico MRU de **frases / conteúdo** de busca (até 25 itens), também via **`TMruHelper`**.

---

## 4. Pasta do executável — skin AlphaControls e bitmaps

### `ASkin.ini` (constante `ASKIN_INI`)

- **O que é:** configuração do **gerenciador de skin** (ex.: diretório de skins).
- **Origem:** se não existir, pode ser extraído de **recurso embutido** `SKINSINI` (ver `UnDM.pas`).

### Pasta `Skins\` (constante `FOLDERSKIN`)

- **O que é:** diretório dos **temas visuais** (ficheiros do skin).
- **Origem:** se não existir, pode ser criada/extraída a partir do recurso `SKINS`.

### `texture.bmp` (constante `TEXTURE`)

- **O que é:** textura usada pelo tema / skin.
- **Origem:** recurso `TEXTURE` se o ficheiro não existir.

### `logo.bmp` (constante `LOGO` e uso em `uSmoothLoading.pas`)

- **O que é:** imagem de **logo** (ex.: telas de loading).
- **Origem:** recurso `LOGO` se o ficheiro não existir.

---

## 5. Pasta do executável — XML de apoio

### `folders.xml` (constante `XMLFOLDERS`)

- **O que é:** dados de **pastas** usados em fluxos de ficheiros/pastas (ex.: find-file).
- **Origem:** se não existir, extração do recurso `FOLDERS` (`UnDM.pas` / `MainUnit.pas`).

### `files.xml` (constante `XMLFILES`)

- **O que é:** lista / metadados de **ficheiros** usados em telas relacionadas (`TClientDataSet` persistido em XML).
- **Origem:** se não existir, extração do recurso `FILES`.

---

## 6. Outros ficheiros referenciados no código (pasta do `.exe` ou relativos)

### `extensionFiles_text` — na prática `extensionFiles.txt`

- Carregado a partir de **`ExtractFilePath(Application.ExeName) + 'extensionFiles.txt'`** em `MainUnit.pas` (lista de extensões para diálogos/listas).

### `textFileChunk.txt`

- **O que é:** ficheiro de **chunk** carregado em determinados fluxos (split/chunk).
- **Caminho:** junto ao `.exe`.

### Merge de linhas (delta) — `*.delta` e `temp_merge.txt`

- **Botão `Merge lines` (barra File toolbar):** igual ao fluxo do `ReadFileThread` / `UnReadFileThread.pas`: abre o formulário **`uDeltaEditor`** (ficheiro `uDeltaEditor.pas` + `uDeltaEditor.dfm` em `Src`).
- **`.delta`:** guardado em **`ExtractFilePath(ParamStr(0))`** com o nome do ficheiro aberto em `edtFileName`, extensão **`.delta`** (ex.: `meuarquivo.txt` → `meuarquivo.delta`). Pode ser reaberto para continuar edições.
- **`temp_merge.txt`:** ficheiro intermédio usado por **`TMergeDeltaThread`** em `uSmoothLoading.pas` durante o merge; fica junto ao `.exe` e é removido após sucesso quando o fluxo o permite.

### `ConsumerAI.exe` (constante `CONSUMERAI`)

- Referenciado em `UnConsts.pas` / `UnConsumerAI.pas`; em **`UnDM.pas`** a extração do recurso está **comentada** — não é obrigatório na instalação típica atual.

### `chunk.txt` (constante `CHUNKFILE` em `UnConsts.pas`)

- Nome reservado em constantes; verificar usos no projeto se precisar de rastrear um fluxo específico.

### `bd.settings` (`Biblioteca.pas`)

- Se a unidade **`Biblioteca`** fizer parte do programa ligado, pode ler/gravar **`bd.settings`** junto ao `.exe` (configurações da biblioteca).

---

## 7. Logs assíncronos

### Padrão `Log_FastFile<ddmmyyyyhhnn>.txt`

- **O que é:** ficheiro de **log** escrito por **`LogAsync`** (`ThreadFileLog.pas`), usado em erros/exceções em módulos como **`uSmoothLoading.pas`**, **`uMMF.pas`**, etc.
- **Caminho:** o código passa **apenas o nome do ficheiro** (sem pasta); o ficheiro cria-se na **diretoria de trabalho atual** do processo (em muitos casos igual à pasta do `.exe` quando o utilizador abre a aplicação pelo Explorador).

---

## 8. Ficheiros temporários do Windows

Vários módulos usam **`GetTempPath`** (ou equivalentes em `UnUtils`, `Biblioteca`, `UnTemporaryFileStream`, `DSiWin32`, etc.) para criar ficheiros **temporários** durante operações (cópia, streams, etc.). Os nomes **não são fixos**.

---

## 9. Ficheiro principal aberto pelo utilizador

- **O que é:** qualquer caminho escolhido na interface (campo `edtFileName`, diálogo de abrir, drag-and-drop, recentes).
- **Relação com o índice:** o conteúdo é o arquivo fonte; o **`temp.txt`** junto ao `.exe` guarda o **índice de linhas** correspondente após a leitura/indexação.

---

## 10. Resumo em uma frase

**Na pasta do `.exe` costumam existir:** índice **`temp.txt`**, recentes **`mru_*.ini`**, skin **`ASkin.ini` + `Skins\`**, **`folders.xml` / `files.xml`**, **`texture.bmp` / `logo.bmp`**, e possivelmente **`extensionFiles.txt`**, **`textFileChunk.txt`**, **`Log_FastFile*.txt`**. O **conteúdo editado/visualizado** é o ficheiro que o **usuário** abre; **temporários de sistema** podem aparecer na pasta temp do Windows.

---

## 11. Referências no código (unidades úteis)

| Unidade / área | Conteúdo relevante |
|----------------|-------------------|
| `UnConsts.pas` | Nomes constantes (`TEMPFILE`, `ASKIN_INI`, `XMLFOLDERS`, …) |
| `UnDM.pas` | Extração de recursos para XML, skin, bitmaps |
| `MainUnit.pas` | `mru_files.ini`, MRU helpers, `extensionFiles.txt`, `temp.txt`, XML |
| `uTextEncoding.pas` | Helpers UTF-8 / Unicode para exibição em VCL ANSI (ListView, `MessageBoxW`) |
| `ThreadFileLog.pas` | `LogAsync` / escrita em disco |
| `UnReadFileThread_utf8.pas`, `uSmoothLoading.pas` | Caminho do índice `temp.txt` |

---

*Documento gerado para arquivo local em `Src`. Pode atualizar este ficheiro quando novos INIs, índices ou recursos forem adicionados ao projeto.*
