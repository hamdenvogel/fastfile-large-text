# FastFile — Roadmap Comercial e Melhorias de Produto

> **Guia Cursor (limpeza AppData):** `GuiaLimpezaCursorAppData.md` nesta pasta, ou `Documentos\GuiaLimpezaCursorAppData.md`. Use `Ctrl+P` e digite `GuiaLimpeza`. Evite abrir `CURSOR_APPDATA_LIMPEZA.md` por link do chat (erro "Unable to resolve resource").

**Data:** 27 de setembro de 2026  
**Projeto:** FastFile (Delphi 7 / Delphi 10.4.2 Win64) — editor de arquivos de texto enormes (GB+)  
**Versão atual:** **3.0.5.225** — histórico de sessão com checkboxes/ordenar/filtro de datas, editor de linha renovado, EOL CR/LF/CRLF, merge rápido (pós-**★ FastFile 3.0.5.210** / **3.0.5.100**)  
**Objetivo deste documento:** consolidar sugestões técnicas, de UX e de negócio para tornar o FastFile um produto comercialmente competitivo.

---

## ★ Actualização 3.0.5.225 (setembro/2026)

Entrega incremental após **3.0.5.210** (trilhos internos **.211–.225**):

- **Pesquisa e navegação:** barra de **ocorrências** após Ctrl+F (F3 / Shift+F3, lista paginada clicável, «Carregar mais»); galeria **Ferramentas de pesquisa**; barra de **marcadores** dockada (Ctrl+B); procura parcial nos MRU.
- **Assistente AI-First:** após cada operação, sugestões «E agora?» + rascunho IA; memória-ponte para continuar de onde parou.
- **Ficheiros de qualquer tamanho:** CR+LF / LF / CR em todas as rotinas; detectar/converter EOL e codificação; pré-visualização paginada do histórico (pouca RAM); aplicar merge esquerda↔direita em thread, cancelável, rápido em 50 GB.
- **Comparar / unir → histórico:** realce da substring, lista paginada de **linhas alteradas**, MRU de ficheiros com histórico, painéis dockáveis, exportar por legenda; checkboxes + selecionar todos + excluir, **ordenar** por linha/data, **filtro por período** (datepicker AlphaSkins), exportar TXT/CSV, perguntar à IA.
- **Edição:** editor de linha renovado (procurar/substituir, desfazer/refazer, limpar, linha anterior/seguinte, perguntar à IA); correcção da edição que deixava a lista em branco.
- **UX / configuração:** reordenar abas por arraste (gravado no INI); diálogo **Opções** (MRU, dicas de linha, trecho do histórico); caixas de mensagem profissionais; arranque mais rápido com muitas abas; troca de idioma mais rápida e cancelável.
- **Estabilidade e qualidade:** guarda global de excepções + watchdog de travamento/memória; 17 units em UTF-8 com BOM (acentuação correcta nos 14 idiomas); F1 com bloco traduzido **`FF_HELP.RecentFeaturesBlock`**.

**Valor comercial:** reforça o posicionamento «editar e auditar ficheiros de dezenas de GB sem medo» — histórico auditável com filtros por data, merge atómico e resiliência (watchdog).

---

## ★ Actualização 3.0.5.210 (setembro/2026)

Entrega incremental após **3.0.5.100** (trilhos internos **.207–.210**):

- **14 idiomas de UI:** japonês (`ja`) + chinês simplificado (`zh-CN`) + chinês tradicional (`zh-TW`) com cobertura completa em `uI18n` (`Set14`); combo + Assistente; detecção Windows `LANG_CHINESE`.
- **Arranque mais rápido:** população i18n só de **inglês + idioma activo**; restantes sob demanda; `PutNV` O(n) + collapse/sort (desde **.208**).
- **Docs / F1 / Version History:** sync **`3.0.5.210`** — `FF_HELP.AssistantBlock`, README, ROADMAP, `DOC_ZS_ATALHOS.md`, `DOCUMENTACAO_MODELOS_IA.md`.

---

## ★ Actualização 3.0.5.100 (setembro/2026)

Entrega incremental após **3.0.5.0**:

- **FilterBar dockada (Ctrl+L):** combo de padrão, Aplicar / Continuar / Limpar / Ocultar, faixa peek; MRU dos últimos **20** filtros em `ASkin.ini` `[FilterRecentPatterns]`.
- **Status bar clicável:** Mode / Wrap / Tail / Filter / Marks / View — clique para toggle.
- **Assistente IA — chrome suave:** UI remodelada, `TsPanel` + `SkinData.CustomColor` (AlphaSkins); tool **`count_matching_lines`** (contagem local contains/parcial, AI-first).
- **Mais ferramentas:** itens com fundo azul suave em gradiente; pesquisa e ESC polidos.
- **Docs / F1:** sync interno **.101**; versão publicada **`3.0.5.100`**.

---

## ★ Actualização 3.0.5.0 (agosto/2026)

Entrega incremental após **3.0.4.0**:

- **Assistente IA — compose:** gerar documentos (resumo → Word/RTF/DOCX/ODT/PDF) e código multi-linguagem (Python, JS/TS/React, Go, Java, C++, …) via chat (Ctrl+Alt+A); classificador de intenção + mapa com anti-phrases.
- **Pasta `fastfile_assistant\`:** saídas do compose separadas de `fastfile_temp` (uso interno).
- **Limpar / Copiar** na resposta do assistente; mensagem de gravação só com caminho completo + tempo IA.
- **Trava de segurança:** bloqueia vírus/malware/formatar disco/shell do SO; não grava `.exe`/`.bat`/`.vbs`/etc.
- **F1 / i18n:** bloco **`FF_HELP.AssistantBlock`** actualizado nos **11 idiomas**; Version History e docs sincronizados.

---

## ★ Actualização 3.0.4.0 (julho/2026)

Entrega incremental após **3.0.3.0**:

- **Chat IA avançado (arquivo) em GB+:** `ConsumerRAG.py` usa **FastTextRAG** (busca lexical em streaming) por predefinição — abre ficheiros de qualquer tamanho (ex.: **TXT de 3,6 GB**) em segundos, sem embeddings antecipados; indexação semântica completa é **opcional** (`--semantic-index`).
- **Cancelar/Fechar sem travar:** `StopConsumerRAGProcess` não bloqueante (`TerminateProcess` + espera temporizada de 750 ms na thread leitora); o painel oculta na hora e os botões Cancelar/Fechar ficam sempre clicáveis.
- **Comparar/Mesclar — acentuação correta:** deteção automática de codificação (UTF-8 / ANSI / UTF-16 via `uTextEncoding`) na pré-visualização e no histórico de sessão; journal gravado em **UTF-8** (`uFileSessionHistory`).
- **Scroll dos chats IA:** roda do rato (e Ctrl+roda) sobre qualquer painel de chat (SQL, Avançado, Assistente, Script) rola o próprio histórico, não a lista principal.
- **Ler (Ctrl+1):** com um ficheiro já aberto, abre o seletor de ficheiros e carrega de imediato o escolhido.
- **Botão Sobre:** rótulo encurtado para «Sobre» (`titlebar.about`, 11 idiomas).
- **F1 / i18n:** bloco **`FF_HELP.AIChatFileBlock`** nos **11 idiomas**; Version History e docs sincronizados.
- **Script Engine (Ctrl+Alt+E):** com linhas selecionadas na ListView (ex. após filtro Ctrl+L), o Run pergunta se processa **todas** ou **só as selecionadas**, confirma com a contagem, e o Cancelar do overlay **aborta** o `ScriptEngine.exe` de imediato.

---

## ★ Actualização 3.0.3.0 (junho/2026)

Entrega incremental após **3.0.2.0**:

- **Host Win64 (Delphi 10.4.2):** `Build\Win64\FastFile.exe` em paralelo com Win32; mutex por arquitectura; scripts `compile_verify_win64.bat`.
- **Indexação SWAR rápida:** `uLineIndexScan.pas` — scan de LF em blocos de 8 bytes (wide 32 bytes com AVX2); leitura F5 ~3× mais rápida em ficheiros GB; índice esparso (>2 GB) mantido.
- **Barra de progresso suave:** throttle ~22 Hz durante scans rápidos (sem saltos por fatia de 8 MB).
- **Log de tempo (Win64):** canto superior direito com histórico de operações (`AppendOperationTimerLog`, `TListBox` VCL).
- **Scan paralelo:** código em `TryParallelLineIndexScan` mantido mas **desligado** (`LINE_INDEX_PARALLEL_ENABLED=False`) — part-files duplicavam I/O em índice esparso; reactivar quando workers escreverem directo nos writers.
- **F1 / i18n:** bloco **`FF_HELP.Win64IndexBlock`** nos **11 idiomas**; Version History e docs sincronizados.

---

## ★ Actualização 3.0.2.0 (junho/2026)

Entrega incremental após **3.0.1.0**:

- **Workspace vazio (marca):** gradiente azul, logo FastFile + watermark em alta resolução (PNG 1200 px), textos centralizados; posição estável ao abrir/fechar assistente IA; cache de pintura Lanczos sem flash retangular no arranque. Ver **`DOC_IDLE_LOGO_WORKSPACE.md`**.
- **Seleção vertical em bloco:** **Ctrl/Alt+arrastar** na coluna de conteúdo mantém a largura escolhida ao soltar o rato (ListView + checklist); **F11** estende até à borda direita só quando premido (não no MouseUp).
- **Autofill / F1:** blocos de ajuda **`FF_HELP.ReadPanelBlock`** e **`FF_HELP.IdleWorkspaceBlock`** nos **11 idiomas**; Version History e docs sincronizados.

---

## ★ Actualização 3.0.1.0 (junho/2026)

Entrega incremental após o marco **3.0.0.0**:

- **Assistente:** abrir o **N.º ficheiro da lista de recentes** por linguagem natural (`open_recent_file`); contexto `recent_N` no prompt; erro i18n se o índice não existir.
- **Chat com IA / Chat Avançado com IA:** renomeação de menus e painéis (11 idiomas); atalhos **Ctrl+Shift+A** e **Ctrl+Alt+R**; caminho do ficheiro activo mesmo com sufixo `[READ ONLY]` na barra.
- **Download de EXEs:** `ConsumerAI.exe`, `ConsumerRAG.exe`, `ScriptEngine.exe` — cookie PyInstaller corrigido, validação PE, fallback **URLMon**, timeouts longos; log `Build\FastFile_Download.log`.
- **UX assistente:** painel de resposta (`MemoReply`) e chrome visual restaurados.

---

## ★ Marco 3.0.0.0 (maio/2026)

O FastFile atinge a **versão 3.0** — consolidação comercial e técnica do trilho 2.1.7.x:

- **Assistente IA operacional (v3):** comandos em linguagem natural com execução local quando possível (filtrar+exportar, substituir tudo, dividir, apagar linha com filtro activo); atalhos do painel Read disponíveis com foco no assistente; F1 e i18n actualizados.
- **Menu Ferramentas / Sessão / Opções** + **uEmEditorFeatures** (valor do caractere, strings frequentes, deduplicação GB+) — já entregues em 2.1.7.29–31, integrados no marco 3.0.
- **Zero Scan**, extrair partes, Tail macro, script engine GB+, undo assíncrono — base estável documentada em `README.md` e `CHANGELOG_IMPLEMENTACOES.md`.
- **Próximo foco comercial pós-3.0:** licenciamento, site de distribuição, pacote instalador, documentação de utilizador final em PDF/vídeo, e extensão do assistente (mais acções whitelist sem rede).

---

---

## Contexto — O que o FastFile já tem

O projeto já possui uma base técnica rara e sólida:

- Leitura indexada via MMF (Memory-Mapped Files) + threads — abre arquivos de GB em segundos
- Split de arquivos (por linhas, por partes iguais em bytes com corte em LF)
- Merge de arquivos com gravação atômica (`temp + rename`)
- Busca com suporte a prefixo, contains e **regex**
- Filtro de linhas (view sobre o índice, sem reescrever arquivo)
- Diff/merge visual lado a lado com histórico de sessão (agora embutido na aba `tabMerge`, sem modal)
- Diff assíncrono no Compare/Merge (worker thread + progressbar sem travar UI)
- Fast mode dinâmico para diff de arquivos grandes (limiar em bytes calculado por execução)
- Correção de consistência no diff por faixa (lookahead + recorte da janela para evitar falso bloco no fim)
- Aplicação de merge com segurança em linha sem âncora (line 0 -> append no EOF)
- Painel de macro Python com atalhos robustos (Ctrl+C/Ctrl+Insert, Ctrl+V/Shift+Insert, Ctrl+A/Ctrl+T)
- **Menu Ferramentas / Sessão + analytics EmEditor (v2.1.7.29–32):** menu principal reorganizado (Ferramentas com Filtro/análise, Dividir/mesclar, Linhas, Tail, Automação, Exportar; Sessão RO + gravar/carregar; Opções só ops. segmentadas); **Valor do código do caractere** (Visualizar); **Extrair strings frequentes** e **Excluir linhas duplicadas** (MMF + buckets + hash em disco; progresso GB/MB/s/ETA; 11 idiomas; F1)
- **Zero Scan atalhos e última linha (v2.1.7.25–28):** Ctrl+G linha física, Replace All / delete em lote sem índice denso, F1 + `DOC_ZS_ATALHOS.md`; **Shift+End** descobre última linha (sonda regressiva + contagem LF em thread para ficheiros >256 MB); saída apaga `temp.txt` / `temp_ckpt.txt`
- **Extrair partes do arquivo (v2.1.7.27):** **Ctrl+Shift+Q** — subset LF-safe de partes iguais; nomes `parte_1_de_8` (11 idiomas); diálogo de sucesso; repõe ListView após export; funciona em Zero Scan
- **Script engine (v2.1.7.13):** progresso RUNFILE por bytes no overlay; exemplos Python/Tail traduzidos (11 idiomas, sem mojibake); download automático de `ScriptEngine.exe` / Consumer quando ausente localmente; abertura do painel macro (**Ctrl+Alt+E**) mesmo sem ficheiro carregado (muda para aba Read)
- **Tail macro Python (v2.1.7.21):** painel lateral em Opções; `transform(line, ctx)` em cada linha nova do Tail (**Ctrl+T**); exemplos + IA; reprocessar (**Ctrl+Shift+R**); resultados no export Tail (**Ctrl+Shift+L**); saída em ficheiro para logs GB+; i18n completo (11 idiomas)
- **Split partes iguais corrigido (v2.1.7.23):** divisão por **contagem de linhas** equilibrada com fronteiras LF — sem cortar registo a meio (ficheiros de linhas longas)
- **Script engine modo ficheiro grande (v2.1.7.24):** índice esparso `temp_ckpt.txt`, saída directa em disco (**OUTFILE**), memo leve em ficheiros GB+
- **Autofill de linhas + CSV pós-edição (v2.1.7.17):** arrastar coluna **Linha #** insere linhas em branco (estilo EmEditor); **Ctrl+Z/Y** no bloco; journal **BAUT** no merge/histórico; modo CSV preservado após reload (`RestoreCsvModeAfterPostEdit`); delete em lote refresca ListView sem F5; recent files remove caminho inexistente
- ScriptEngine otimizado para conjuntos muito grandes (batching maior e append em bloco no output)
- Estabilidade de encerramento do ConsumerAI (correção de lifecycle da thread de leitura)
- Overlay de progresso **Smooth loading** refinado (cantos arredondados, fade-in, área de trabalho, cancelamento cooperativo com **TBitBtn** e i18n **11 idiomas** — trilhos internos **v2.1.7.1** / **v2.1.7.2**)
- **Split por padrão / Regex (aba embutida):** pré-visualização (**Preview**) no mesmo fluxo do modal; assistente **Talk with AI** via gateway HTTPS (**uFastFileAIClient** / **uFastFileAIScreenHelp**); validação da resposta contra **VBScript.RegExp** com bloco **pronto para colar** no campo Pattern (**uVBScriptRegex**); prompt reforçado (**AI_PROMPT_RULES_P3**) para linhas `Regex:`; modo **partes iguais vs regex** (`cmbMode`), **Confirm** com **`roSplit`** no ramo regex; botões **Sugerir exemplos com a IA** / **Falar com a IA** na **barra inferior fixa** (fora do scroll, pintura fiável com AlphaSkins) — trilhos internos **v2.1.7.3**–**v2.1.7.8** (último endurecimento UI/i18n em **v2.1.7.7** / **v2.1.7.8**).
- Encoding automático com suporte a UTF-8, CRLF/LF
- i18n a **11 idiomas** (PT-BR, PT-PT, EN, ES, FR, DE, IT, PL, RO, HU, CZ)
- **Chat com IA** / **Chat Avançado com IA** (menus; executáveis `ConsumerAI.exe` / `ConsumerRAG.exe`) — ponte Delphi ↔ Python (LanceDB / DuckDB / RAG)
- Modo tail/follow, bookmarks, zoom de lista
- **Processamento segmentado por linhas (ops. pesadas):** política automática (recomendada), sempre ou nunca; opção **Forçar** em Opções (como Zero Scan); ver secção detalhada abaixo
- **Barra Read (v2.1.7.x):** cinco botões rápidos (zoom in/out, localizar, substituir, marcas) ao lado do word wrap; modo segmentado só em **Opções**
- **Undo/Redo estável (v2.1.7.11):** pilha `TUndoRecord` assíncrona (sem travar UI em GB+); confirmação **Sim/Não** antes de desfazer/refazer; preserva pilha após editar (`BeginReadSilent`); bloqueado em read-only e durante worker ativo
- **Undo/Redo + busca (v2.1.7.9–10):** **Ctrl+Z** / **Ctrl+Y** / **Ctrl+Shift+Z**; editar/colar/substituir simples; `CurrentEffectiveFilePath`; realce na coluna Conteúdo; ignore case; substituição bloqueada em read-only; i18n (11 idiomas)
- Hub inicial de Arquivos Recentes integrado na UI principal (tab), com i18n 11 idiomas,
  opcao de "nao mostrar na inicializacao" e item de menu de visualizacao para abrir a tela
- Detecção de instância única, hardware ID (`unHardwareInformation`)

O gap entre "ferramenta interna excelente" e "produto comercial" é principalmente de **embalagem, distribuição e posicionamento** — não de funcionalidade central.

---

## Apêndice — Processamento segmentado por linhas (operações pesadas)

> **Documento completo:** [DOC_SEGMENTED_HEAVY_OPS.md](DOC_SEGMENTED_HEAVY_OPS.md) (`EffectiveUseSegmentedHeavyOps`, fluxos, INI, FAQ).

### O que é

Modo alternativo para **reescrever ficheiros muito grandes** sem manter todo o conteúdo em memória de uma só vez. O ficheiro é dividido em **segmentos alinhados a linhas** (por defeito ~**250 000 linhas** por parte, com mínimo interno de 5000), cada parte é processada com ficheiros temporários e no fim tudo é **fundido** (`merge`) e substituído no original de forma atómica (`rename`), usando o índice de linhas `temp.txt` quando disponível.

### Operações afetadas

| Operação | Caminho segmentado | Fallback se falhar |
|----------|-------------------|-------------------|
| **Substituir tudo** (Find & Replace) | `TReplaceAllThread.TrySegmentedReplace` | fluxo streaming normal |
| **Apagar linhas assinaladas** (Select, lote) | `TrySegmentedBatchDelete` | delete por MMF / `TEditFileThread` |

Não altera abertura, scroll, filtro, tail nem visualização.

### Política (como Zero Scan)

Configuração em **Opções** (não na barra ao lado do word wrap):

| Item de menu | INI | Comportamento |
|--------------|-----|----------------|
| **Ops. segmentadas: automático (recomendado)** | `SegmentHeavyOpsPolicy=0` | O programa decide por heurística |
| **Ops. segmentadas: sempre usar** | `=1` | Sempre tenta segmentado quando aplicável |
| **Ops. segmentadas: nunca usar** | `=2` | Nunca segmentado (salvo forçar) |
| **Forçar modo segmentado (ops. pesadas)** | `SegmentHeavyOps=1` | Igual ao antigo checkbox ligado; sobrepõe “nunca” |

**Heurística automática** (`EffectiveUseSegmentedHeavyOps` em `MainUnit.pas`): activa segmentado quando **qualquer** condição:

- ficheiro **> 100 MB**, ou  
- **> 500 000 linhas** no total, ou  
- operação afecta **≥ 200 linhas** (ex.: muitas linhas marcadas para apagar).

### Limitações importantes (comunicar ao utilizador)

1. **Substituir tudo:** texto procurado que **atravesse o limite entre dois segmentos** pode **não ser encontrado** (aviso na caixa de confirmação quando o modo efectivo está ligado).  
2. **Disco:** exige espaço livre extra (ordem de tamanho do ficheiro + margem; verificação em `VolumeHasMinFreeBytes`).  
3. **Índice:** delete segmentado depende de `temp.txt` válido; se falhar, o código **cai automaticamente** para o caminho MMF.  
4. **Performance:** mais lento que um único passo em RAM, mas com **pico de memória menor**.

### UI (barra Ler Arquivo)

Cinco botões compactos com hints i18n (substituem o antigo checkbox na toolbar):

- Zoom in — `Ctrl+Plus`  
- Zoom out — `Ctrl+Minus`  
- Localizar — `Ctrl+F`  
- Localizar e substituir — `Ctrl+H`  
- Marcas — `Ctrl+Alt+M`  

Implementação: `SetupReadToolbarQuickButtons` / `pnlReadToolbarOptions`.

### Código de referência

- `uSmoothLoading.pas`: `TrySegmentedBatchDelete`, `TReplaceAllThread.TrySegmentedReplace`  
- `MainUnit.pas`: `EffectiveUseSegmentedHeavyOps`, `FSegmentHeavyOpsPolicy`, `FForceSegmentHeavyOps`  
- Persistência: `ASkin.ini` → `SegmentHeavyOps`, `SegmentHeavyOpsPolicy` (+ `SaveSmartSearchPrefs` / `LoadSmartSearchPrefs`)

#### `EffectiveUseSegmentedHeavyOps` (detalhe técnico)

Única função que decide **sim/não** para o caminho segmentado numa operação. Parâmetros: tamanho do ficheiro, `totalLines`, linhas afectadas (0 no Replace All; contagem no delete em lote).

Ordem: **Forçar** → política **sempre/nunca** → modo **auto** (≥200 linhas na op. **ou** ficheiro >100 MB **ou** >500 k linhas).

Chamada em: delete em lote (ramo `TrySegmentedBatchDelete` + overlay), confirmação e criação de `TReplaceAllThread` no Replace All.

Documentação de arquitectura: **`DOC_SEGMENTED_HEAVY_OPS.md`** (completo), **`ARQUITETURA_TECNICA_FASTFILE.md`** § 4.1.1 (resumo).

### Comparação com Zero Scan

| | Zero Scan | Segmentado (ops. pesadas) |
|---|-----------|---------------------------|
| **Quando** | Abrir / navegar ficheiro enorme sem índice completo | Gravar após Replace All ou delete em lote |
| **Objetivo** | Abrir rápido, scroll proporcional | Reduzir pico de RAM/disco na **escrita** |
| **Forçar manual** | View → Force Zero Scan | Opções → Forçar modo segmentado |

---

## Parte 1 — Posicionamento de Produto

### 1.1 Nicho claro

O FastFile tem um nicho definido e valioso: **editor de logs e arquivos de texto gigantes (GB+)**. Esse é um segmento onde os concorrentes populares (Notepad++, VS Code, TextPad) simplesmente travam ou se recusam a abrir o arquivo.

### 1.2 Tagline sugerida

> *"Open and edit multi-gigabyte text files instantly — where other editors give up."*

### 1.3 Benchmarks como argumento de venda

Criar e publicar benchmarks reais comparando:

| Ferramenta | Arquivo 1 GB | Arquivo 5 GB | Arquivo 10 GB |
|---|---|---|---|
| FastFile | X seg | X seg | X seg |
| Notepad++ | trava / OOM | — | — |
| VS Code | trava / OOM | — | — |
| TextPad | X seg | trava | — |
| EmEditor | X seg | X seg | X seg |

> **Nota:** EmEditor é o concorrente mais direto no segmento pago; conhecer seus preços e features é importante para posicionamento.

### 1.4 Nome e identidade visual

- Considerar um logotipo moderno com variante dark/light
- Ícone `.ico` de 256×256 com múltiplos tamanhos embutidos
- Screenshot profissional com arquivo real de GB para material de divulgação

---

## Parte 2 — Experiência Visual e UX

### 2.1 Tema visual

| Melhoria | Detalhes | Viabilidade |
|---|---|---|
| **Tema Dark por padrão** | AlphaControls já suporta; switch claro/escuro com 1 clique via `sSkinManager` | Alta (código) |
| **Welcome screen** | Tela inicial com arquivos recentes, tamanho, linhas, última abertura | Alta (código) |
| **Splash refinado** | Exibir % real de carregamento do índice, não apenas animação | Alta (código) |
| **Status bar permanente** | Encoding, CRLF/LF, linha/coluna, tamanho em disco, offset — sempre visível | Alta (código) |
| **Toolbar configurável** | Arrastar/reorganizar botões — percepção de produto premium | Média (código) |

### 2.2 Qualidade de detalhes percebida

- Atalhos de teclado consistentes e documentados no tooltip de cada botão
- Animações de abertura/fechamento de painéis (AlphaControls suporta)
- Mensagens de erro amigáveis com instrução de ação (não apenas "Error")
- Cursor de "ocupado" (relógio) substituído por barra de progresso real em todas as operações longas

---

## Parte 3 — Funcionalidades que Desbloqueiam Mercado Pago

### 3.1 Tail / Follow em tempo real robusto ⭐

**Status atual (implementado no host):**
- Modo Tail/Follow ativo com leitura incremental por crescimento do arquivo
- Highlight visual para novas linhas adicionadas
- Pause/Resume follow com contador de linhas pendentes
- Navegacao e repaint alinhados com ListView/checklist sem regressao funcional

**O que é:** monitorar um arquivo em crescimento (log de servidor, pipeline, saída de processo) e exibir automaticamente as novas linhas.

**Por que vende:** é a funcionalidade mais buscada por sysadmins e DevOps para logs de produção.

**Detalhes de implementação:**
- Thread dedicada monitorando tamanho do arquivo a cada N ms (configurável: 500ms, 1s, 5s)
- Novas linhas adicionadas ao índice incrementalmente, sem reindexar o arquivo inteiro
- **Highlight visual** das linhas novas em cor diferenciada (configurável)
- Botão "Pause follow" para navegar sem perder o tracking
- Limite de buffer: manter apenas os últimos X MB em memória quando o arquivo cresce indefinidamente

### 3.2 Column / Delimiter Mode (CSV, TSV, pipe) ⭐

**O que é:** detectar separador de colunas e exibir o arquivo em modo tabela alinhado.

**Por que vende:** analistas de dados e DBAs trabalham intensivamente com dumps CSV/TSV de GB que Excel não abre.

**Detalhes de implementação:**
- Detecção automática de separador (`,`, `;`, `\t`, `|`, espaço fixo)
- Exibição em grid virtual (não carrega tudo na RAM)
- Cabeçalho fixo com nome das colunas (primeira linha)
- Ordenação por coluna (streaming, sem carregar tudo)
- Modo leitura — não precisa suportar edição nesta primeira versão
- Exportar seleção de colunas para novo arquivo

### 3.3 Exportação Avançada

| Formato | Público-alvo |
|---|---|
| CSV / TSV | Analistas, DBAs |
| XLSX (via COM/automação) | Gestores, Excel-users |
| HTML com highlighting | Documentação, relatórios |
| JSON lines | Desenvolvedores |

- **Exportar resultado filtrado** — apenas as linhas que casam com o filtro ativo
- **Exportar seleção** com número de linha + nome do arquivo no cabeçalho
- **Exportar intervalo** de linha X até linha Y

### 3.4 Regex com Named Captures na Busca

**O que é:** extrair grupos nomeados de cada linha para uma mini-tabela de resultados.

**Exemplo:**
```
Padrão: (?P<ip>\d+\.\d+\.\d+\.\d+) .* (?P<status>\d{3}) (?P<bytes>\d+)
Resultado: tabela com colunas ip | status | bytes
```

**Por que vende:** parsear logs estruturados (Apache, nginx, JSON lines, syslog) sem precisar de scripts externos.

### 3.5 Sessões / Workspaces

**O que é:** salvar e restaurar o estado completo de trabalho.

**Estado salvo:**
- Arquivo aberto + posição (linha ou offset)
- Bookmarks ativos
- Filtro ativo (padrão + modo)
- Encoding selecionado
- Layout de painéis e zoom
- Histórico de buscas da sessão

**Implementação:** arquivo `.ffsession` em JSON ou INI na pasta do arquivo ou pasta do usuário.

### 3.6 Substituição com Preview e Confirmação

- Antes de executar Replace All, mostrar: contagem de ocorrências, primeiros N exemplos com contexto
- Opção de confirmar cada substituição individualmente (como o Find/Replace do Word)
- Limite de segurança configurável (já existe parcialmente) com mensagem clara

### 3.7 Ir para Definição / Hyperlinks em Logs

- Detectar stack traces Java/C#/.NET e tornar clicável o nome do arquivo+linha
- Detectar URLs no texto e abrir no browser com Ctrl+Click
- Detectar paths de arquivo Windows/Unix e abrir no Explorer/gerenciador

---

## Parte 4 — Chat com IA / Chat Avançado com IA — Alavancagem do Diferencial Único

**Entregue em 3.0.1.0:** menus **Chat com IA** (NL→SQL, `ConsumerAI.exe`) e **Chat Avançado com IA** (RAG, `ConsumerRAG.exe`), download automático dos EXEs, i18n 11 idiomas. O bridge Delphi ↔ Python com LanceDB/DuckDB já é raro no ecossistema. Sugestões para monetizar:

### 4.1 "Analyze this log with AI" ⭐

- Botão ou menu que envia N linhas selecionadas (ou visíveis) ao modelo
- Retorna: erros detectados, padrões, sugestão de causa raiz
- Limite de tokens documentado na UI (ex.: "Analisando 500 linhas")

### 4.2 Sumarização de Arquivo Grande

- "O que aconteceu nesse log?" — processa o arquivo em chunks sequenciais
- Barra de progresso real (bytes processados / total)
- Resultado em painel lateral ou janela separada

### 4.3 Modelo Local (Ollama) como Opção Offline

- Elimina preocupação de privacidade de dados em empresas
- Configurável: endpoint local (`http://localhost:11434`) ou API externa
- Documentar como instalar Ollama + modelo recomendado no help

### 4.4 Templates de Prompt

- Biblioteca de prompts pré-definidos para casos comuns:
  - "Encontrar erros críticos"
  - "Sumarizar em 5 pontos"
  - "Extrair IPs/usuários/datas"
  - "Detectar anomalias"
- Usuário pode criar e salvar seus próprios templates

---

## Parte 5 — Monetização

### 5.1 Modelo de Licença

| Tier | Funcionalidades | Preço sugerido |
|---|---|---|
| **Free** | Abrir/visualizar arquivos de qualquer tamanho, busca, filtro básico | Gratuito |
| **Standard** | + Edição, split/merge, exportação, sessões, tail/follow | ~USD 29 perpétuo |
| **Pro** | + Column mode, regex named captures, Chat com IA / Avançado ilimitado, suporte | ~USD 59 perpétuo |
| **Enterprise** | + Múltiplas máquinas por organização, suporte prioritário, NDA | Cotação |

### 5.2 Trial

- **30 dias funcionais** sem limitação de features
- Após trial: banner discreto + prompt de compra ao abrir
- Sem bloqueio agressivo — usuário decide

### 5.3 Ativação por Hardware ID

O projeto já tem `unHardwareInformation`. Fluxo sugerido:

1. Gerar chave de licença baseada em HWID (algoritmo simétrico simples)
2. Validação offline (sem necessidade de servidor para uso básico)
3. Ativação online opcional para transferência de máquina

### 5.4 Plataformas de Venda

| Plataforma | Taxa | Notas |
|---|---|---|
| **Gumroad** | 10% | Mais simples, aceita cartão + PayPal |
| **Paddle** | ~5% | Melhor para vendas internacionais, lida com impostos |
| **FastSpring** | ~8.9% | Focada em software, boa para licenças |

> Não é necessário montar e-commerce próprio nesta fase.

---

## Parte 6 — Robustez para Venda a Empresas

### 6.1 Assinatura de Código (Authenticode) ⭐ CRÍTICO

**Sem assinatura de código, o Windows SmartScreen bloqueia a instalação e o usuário desiste.**

- Custo: ~USD 200-400/ano para certificado EV (Extended Validation)
- Provedores: DigiCert, Sectigo, GlobalSign
- Com certificado EV, o SmartScreen passa a confiar imediatamente (sem acúmulo de reputação)

### 6.2 Instalador Profissional

- **Inno Setup** (gratuito, amplamente usado em Delphi) com:
  - Ícone e branding da aplicação
  - Associação de extensão de arquivo (`.ffsession`, opcionalmente `.log`, `.txt`)
  - Shortcut no Desktop e Menu Iniciar
  - Desinstalação limpa
  - Registro de versão no registro do Windows

### 6.3 Log de Erros e Crash Report

- Log local de erros em `%APPDATA%\FastFile\logs\`
- Dialog de crash com opção "Enviar relatório" (opt-in)
- Endpoint simples (pode ser e-mail ou webhook) para receber os relatórios

### 6.4 Documentação Completa

- **Help integrado (F1)** — já existe estrutura; completar todas as seções
- **Manual PDF** — para empresas que exigem documentação formal
- **Vídeos curtos** (2-3 min) mostrando casos de uso reais: abrir log de 5 GB, filtrar erros, exportar para CSV

### 6.5 Política de Privacidade

- Documento simples declarando que o app não coleta dados sem opt-in
- URL pública acessível — exigida por lojas e clientes corporativos
- Gerador gratuito: privacypolicygenerator.info

---

## Parte 7 — Distribuição e Descoberta

### 7.1 Portais de Software (tráfego orgânico)

| Portal | Público | Ação |
|---|---|---|
| **Softpedia** | Usuários gerais | Submeter versão gratuita/trial |
| **MajorGeeks** | Técnicos avançados | Submeter com descrição técnica |
| **SourceForge** | Desenvolvedores | Criar página de projeto |
| **Chocolatey** | Sysadmins Windows | Publicar package |
| **Scoop** | Desenvolvedores | Publicar manifest |

### 7.2 Comunidades Online

| Comunidade | Abordagem |
|---|---|
| **r/DataEngineering** | Post mostrando "abri um CSV de 8 GB em 3 segundos" |
| **r/sysadmin** | Post "tail -f em arquivo de log de 15 GB no Windows" |
| **r/commandline** | Comparativo FastFile vs ferramentas Unix no Windows |
| **Hacker News (Show HN)** | Post técnico sobre a arquitetura MMF |
| **Product Hunt** | Launch planejado com screenshots e vídeo demo |

### 7.3 GitHub / Página de Produto

- Repositório GitHub com **código fechado** mas:
  - README profissional com screenshots
  - Changelog público
  - Issues habilitadas para feedback
  - Link para download/compra
- GitHub Actions pode gerar builds automaticamente

---

## Parte 8 — Acessibilidade e Compatibilidade

| Sugestão | Detalhes |
|---|---|
| **Suporte a Windows 10/11** | Testar e documentar compatibilidade explícita |
| **Manifesto de aplicação** | `requestedExecutionLevel asInvoker` com `uiAccess=false` no manifesto |
| **DPI Awareness** | Para monitores 4K/HiDPI — fontes e ícones não borrados |
| **Acessibilidade básica** | Tab order correto, tooltips em todos os controles, contraste mínimo WCAG AA |

---

## Parte 9 — Infraestrutura de Qualidade

### 9.1 Testes de Regressão Automatizados

Arquivos de teste sintéticos cobrindo:
- Arquivo de 10 MB, 100 MB, 1 GB, 5 GB
- Encoding: ANSI, UTF-8 com BOM, UTF-8 sem BOM, UTF-16
- Quebras de linha: LF, CRLF, CR, misto
- Linhas extremamente longas (> 1 MB por linha)
- Arquivo vazio, arquivo de 1 linha, arquivo de 1 byte

### 9.2 Checklist de Release

- [x] Versão atualizada em `UnConsts.APPLICATION_VERSION` (**3.0.0.0**)
- [ ] CHANGELOG atualizado
- [ ] Todos os testes de regressão passando
- [ ] Build em modo Release (não Debug)
- [ ] FastMM4 configurado sem mensagens de debug em produção
- [ ] Assinatura do executável
- [ ] Instalador gerado e testado em máquina limpa
- [ ] Upload para portais de distribuição

---

## Parte 10 — Priorização de Execução

### Onda 1 — Pré-requisitos para venda (1-2 semanas)
1. **Assinatura de código** — sem isso, SmartScreen bloqueia tudo
2. **Instalador profissional** (Inno Setup)
3. **Política de privacidade** publicada
4. **Benchmarks documentados** (abrir FastFile + concorrentes em arquivos reais)

### Onda 2 — Diferencial técnico (3-6 semanas)
5. **Tail/follow robusto** com highlight de novas linhas (**concluído no host 2.1.6.69**)
6. **Column/CSV mode** básico (leitura, visualização em grid)
7. **Sessões** (salvar/restaurar estado)
8. **Status bar expandida** sempre visível

Atualizacao recente de Onda 2 (host 2.1.6.69):
- Bookmarks com destaque visual (fundo azul + fonte branca) na ListView e no modo Select (checklist)
- Navegacao de bookmarks (F2/Shift+F2) com centralizacao e precisao em cenarios com Word Wrap + filtro + checklist

### Onda 3 — Monetização (paralelo às ondas anteriores)
9. **Modelo de licença** + validação por HWID
10. **Trial de 30 dias** com banner
11. **Página de produto** (GitHub ou site simples)
12. **Submissão aos portais**

### Onda 4 — Expansão de mercado (2-3 meses)
13. **Chat com IA / Avançado** — "Analyze this log" + sumarização (expandir templates e limites na UI)
14. **Regex named captures** na busca
15. **Exportação avançada** (CSV, XLSX)
16. **Ollama / modelo local**
17. **Product Hunt launch**

---

## Resumo Executivo

O FastFile já tem a parte mais difícil: um motor de I/O extremamente performático para arquivos de GB, construído em Delphi 7 com técnicas avançadas (MMF, threads, índice incremental). Isso é o que os concorrentes não têm.

O caminho para comercialização não exige reescrita — exige:

1. **Confiança do usuário** → assinatura de código + instalador profissional
2. **Descoberta** → portais, redes sociais, benchmarks públicos
3. **Conversão** → trial funcional + página de produto clara
4. **Retenção** → sessões, tail/follow, Column mode — features que criam hábito diário

**Investimento estimado de tempo de desenvolvimento** (excluindo assinatura de código e marketing):
- Onda 1 (código): ~1 semana
- Onda 2 (código): ~4 semanas  
- Onda 3 (código): ~2 semanas
- Onda 4 (código): ~6 semanas

**Total estimado: ~13 semanas de desenvolvimento** para um produto completo e comercializável.

---

*Documento atualizado em 27/04/2026. Referências: `CHANGELOG_IMPLEMENTACOES.md`, `SUGESTOES_MELHORIAS_FASTFILE.md`, `COMUNICACAO_DELPHI_PYTHON_CONSUMER_AI.md`.*
