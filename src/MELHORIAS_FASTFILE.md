# Melhorias FastFile — o que ainda faz sentido

**Atualizado:** 29 de agosto de 2026  
**Host:** Delphi 10.4.2 Win64 (`Build\Win64\FastFile.exe`) + Win32  
**Versão publicada:** `3.0.5.0` (`UnConsts.APPLICATION_VERSION`)  
**Código principal:** `src/MainUnit.pas` (~42k linhas)

Este arquivo **substitui** o rascunho de 2024. Aquele texto **não procedia**: sugeria Virtual ListView, MMF, índice de linhas, encoding, bookmarks, filtro, diff/merge, sessão e busca em background como se ainda faltassem. O FastFile já tem tudo isso (e muito mais). Também misturava conselhos perigosos para GB+ (`TFile.ReadAllLines`, `GetFileSize` 32-bit) e priorizava MVVM/DI no form monolítico — o caminho errado neste código.

Histórico de versões: `CHANGELOG_IMPLEMENTACOES.md`.  
Produto / licença / site: `ROADMAP_COMERCIAL_FASTFILE.md`.  
Arquitetura (ainda útil, datas/versão no topo podem estar atrasadas): `ARQUITETURA_TECNICA_FASTFILE.md`.

---

## O que o FastFile já é (não reinventar)

Editor/visualizador de **texto enorme** (testado acima de 14 GB): o arquivo **não** entra inteiro na RAM.

| Já existe | Onde / como |
|-----------|-------------|
| Índice de offsets por linha | `temp.txt` (denso) / `temp_ckpt.txt` (esparso, >2 GB) |
| Leitura por janelas MMF | `uMMF.pas` |
| Scan de LF rápido (SWAR/AVX2) | `uLineIndexScan.pas` |
| ListView virtual (só viewport) | `OwnerData` + cache de linhas |
| Threads + overlay + cancelar | `uSmoothLoading`, workers |
| Gravação atômica | temp + rename |
| Replace All / delete em lote | streaming + ops. segmentadas |
| BMH + regex + filtro (view) | Find/Replace, Ctrl+L |
| Encoding / BOM / UTF-8 | `uTextEncoding.pas`, combo na barra Ler |
| Undo/Redo assíncrono (~100 níveis) | `TUndoRecord` + `TEditFileThread` |
| Bookmarks, zoom, word wrap visual | aba Ler |
| Hints de linha (opt-in, INI) | `chkShowLineHints` / `[UIPrefs] ShowLineHoverHints` |
| Tail + macro Python | `transform(line, ctx)`, IA do Tail |
| Script Engine GB+ | `ScriptEngine.exe`, OUTFILE |
| Comparar / Mesclar + journal | `uCompareMergeUI`, `uLineDiffCore` |
| Assistente IA + Chat SQL + RAG | ConsumerAI / ConsumerRAG (FastTextRAG em GB+) |
| i18n 11 idiomas | `uI18n.pas` |
| Sessão por arquivo | `.ffsession` em `fastfile_temp` |
| Preferências globais | `ASkin.ini` (`IniName`) |

O diferencial **não** é “abrir TXT”. É **abrir, filtrar, editar, automatizar e perguntar à IA em GB+** sem virar Notepad++.

---

## O que eu sugeriria agora (por ordem)

### 1. Produto comercial (maior gap)

O motor já compete com EmEditor/UltraEdit em arquivos gigantes. O que falta para vender:

1. **Instalador** (Inno Setup / equivalente): EXE + Skins + EXEs Python (ou download na 1ª execução, já existe), atalhos, associação `.txt` opcional.
2. **Licença** (trial N dias / chave / hardware ID já existe em `unHardwareInformation`).
3. **Site + PDF/vídeo** de “abrir 3 GB em 10 segundos” — o ROADMAP já aponta isso.
4. **Um único “o que há de novo”** para o utilizador (F1 já ajuda; um changelog curto na UI também).

Sem isso, cada feature nova (IA, macros) só aumenta a ferramenta interna.

### 2. Quebrar `MainUnit.pas` **por extração**, não por MVVM

42k linhas no form é o maior risco de manutenção. **Não** começar por interfaces `IFileReader` / Service Locator. Extraia unidades que **já estão isoladas na prática**:

| Extrair primeiro | Porquê |
|------------------|--------|
| Tail Macro (painel + settings INI) | Já tem `uTailMacro.pas` / settings; o glue ainda está no Main |
| Script Engine (painel, run, scope) | Painel grande + threads |
| Hints de linha (ListView + CheckList) | Bloco recente, bem delimitado |
| Barra Ler (zoom, wrap, hints, layout) | `LayoutReadToolbarQuickButtons` |
| Consumer AI / RAG UI | Painéis laterais |

Regra: **mover código que já funciona**, manter `frmMain` como orquestrador. MVP/MVVM só depois de units com testes (DUnitX) nos algoritmos (`uLineDiffCore`, encoding, BMH).

### 3. Qualidade e regressão (GB+)

O projeto tem `RegressionTests\` e docs de checklist (Zero Scan, Assistente, Regex). Vale:

- Suite **mínima automática** em cada build Win64: abrir fixture 50–200 MB, Ctrl+G, filtro, Replace All cancelável, fechar sem deixar `temp.txt`.
- Fixture **UTF-8 / ANSI / UTF-16 / só LF / linha de 50 MB** (UI já limita; garantir mensagem, não freeze).
- Reativar **scan paralelo** de índice (`LINE_INDEX_PARALLEL_ENABLED`) só quando workers escreverem direto nos writers — hoje está desligado por regressão em índice esparso.

### 4. UX que ainda “raspa” (alto valor, baixo risco)

Coisas que o utilizador sente todos os dias:

- **Arquivo mudou em disco** (outro processo / Tail): avisar recarregar sem perder linha/offset.
- **Save principal** com as mesmas mensagens claras do merge (espaço em disco, “salvando…”).
- **Linhas enormes**: teto de caracteres na célula + “linha truncada na vista” (já há word wrap; o risco é uma linha de centenas de MB).
- **Painéis laterais vs ListView**: já há regras de hint; generalizar “um painel de ferramenta de cada vez” (script vs Tail vs RAG) para não empilhar UI.
- **Assistente IA:** mais ações **whitelist locais** (sem rede) — o ROADMAP 3.0 já pede isso.
- **Colar da IA** (Tail/Script): garantir sempre `def transform` + strip de markdown (trabalho recente; manter testes manuais).

### 5. IA e automação (evoluir o que já existe)

Não um “ChatGPT genérico”. Sim:

- RAG: FastTextRAG default em GB+ já está certo; **índice semântico só opt-in** (já é). Próximo: memória de perguntas úteis por arquivo (sidecar), sem reindexar.
- Macro Tail/Script: biblioteca de **receitas** (CSV coluna N, anonimizar, JSONL) com um clique — menos depender do modelo.
- Assistente: encadear “filtrar → exportar → abrir pasta” de forma fiável (já há JSON chains; endurecer timeouts e cancelar).

### 6. O que **não** faria agora

| Ideia do doc antigo | Porquê não |
|---------------------|------------|
| MVVM / DI no `frmMain` | Custo enorme, ganho zero para o utilizador |
| `TFile.ReadAllLines` / carregar GB em `TArray<string>` | Mata o produto |
| Scintilla / syntax highlight no arquivo todo | Contradiz viewport virtual; no máximo highlight **só nas linhas visíveis** (CSV já é um modo) |
| Git blame / stage | Não é o público (logs, dumps, exports) |
| Múltiplos arquivos em abas tipo IDE | Um arquivo GB+ + índice já é pesado; MRU + recentes cobrem o fluxo |
| Minimap do arquivo inteiro | Impossível em 14 GB sem amostragem; se fizer, só histograma de densidade |
| Aho-Corasick / índice invertido de palavras | BMH + filtro + RAG cobrem; índice extra é outro ficheiro para manter |

---

## Prioridade (realista)

| Prioridade | Item | Impacto |
|------------|------|---------|
| Alta | Instalador + licença + página de download | Vira produto |
| Alta | Extração incremental do `MainUnit` (Tail / Script / hints) | Velocidade de evolução |
| Alta | Fixture de regressão Win64 (abrir / filtrar / save / sair) | Não quebrar GB+ |
| Média | Reload se o ficheiro mudou no disco | Confiança em logs |
| Média | Mais ações locais no Assistente | Menos “chat” e mais ferramenta |
| Média | Receitas prontas de macro Python | Menos fricção da IA |
| Baixa | Highlight só no viewport (CSV/JSONL) | Nice-to-have |
| Baixa | Scan paralelo de índice (quando o bug esparso estiver resolvido) | Tempo de F5 |

---

## Quick wins (compatíveis com o código atual)

1. Documentar no F1 o checkbox **Dicas das linhas** (já i18n 11 idiomas).
2. Gravar **Word Wrap** também em `ASkin.ini` / `[UIPrefs]` (hoje o wrap vai no `.ffsession` por arquivo; o hint já é global).
3. Um item de menu **Ajuda → O que há de novo** apontando para o bloco da versão atual.
4. Checklist de 10 cliques pós-build (Ler, filtro, Tail IA colar, hints on/off, fechar).

---

## Relação com outros docs

| Arquivo | Papel |
|---------|--------|
| `CHANGELOG_IMPLEMENTACOES.md` | O que **já foi** entregue, por versão |
| `ROADMAP_COMERCIAL_FASTFILE.md` | Embalagem, preço, site |
| `ARQUITETURA_TECNICA_FASTFILE.md` | Como o motor funciona (atualizar cabeçalho D7/versão quando tocar) |
| `SUGESTOES_MELHORIAS_FASTFILE.md` | Lista antiga (D7); vários itens já feitos (bookmarks, filtro, RO) |
| **Este arquivo** | O que **ainda** vale a pena fazer no host 10.4 |

---

*Não usar o rascunho 2024 como backlog. Qualquer item novo deve respeitar: nunca carregar o arquivo inteiro; UI só viewport; escrita atômica; i18n 11 idiomas; Win64.*
