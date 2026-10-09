# FastFile — Atalhos e funcionalidades com Zero Scan activo (ON)

**Nome curto deste ficheiro:** `DOC_ZS_ATALHOS.md` (alias de `DOC_ZERO_SCAN_ATALHOS_E_FUNCIONALIDADES.md`)

**Documento de referência para utilizadores e QA**  
Versão de referência: **`3.0.5.232`** (FastFile 3.0.5; agente de IA Ctrl+Alt+G, anonimizar Ctrl+Alt+D, detalhe do evento do histórico **v3.0.5.226–232**; barras de ocorrências/marcadores, editor de linha, histórico de sessão com filtro de datas **v3.0.5.211–225**; **14 idiomas** UI + lazy-load i18n **v3.0.5.207–210**; FilterBar/status toggles v3.0.5.100, compose/assistente v3.0.5.0, Chat IA avançado GB+ v3.0.4.x, indexação SWAR Win64 v3.0.3.x, Zero Scan `2.1.7.25+`, bloco coluna v3.0.2.x)  
Ambiente: Delphi 7 / Win32 · Delphi 10.4.2 / Win64  
Código principal: `MainUnit.pas`, `uSmoothLoading.pas`, `uLineIndexScan.pas`, `uFastFileAssistant.pas`

> **Documentos relacionados**  
> - [DOC_ZERO_SCAN_CHECKLIST_TESTES.md](DOC_ZERO_SCAN_CHECKLIST_TESTES.md) — checklist marcável (passo a passo)  
> - [DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md) — matriz de impactos, níveis ZS-0..3, §13  
> - [DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md) — especificação técnica A–D, E1–E5  
> - [DOC_SEGMENTED_HEAVY_OPS.md](DOC_SEGMENTED_HEAVY_OPS.md) — Replace All / delete em lote (ortogonal ao Zero Scan)  
> - [README.md](README.md) — Force Zero Scan, F5, INI  

---

## Índice

1. [Quando o Zero Scan está ON](#1-quando-o-zero-scan-esta-on)  
2. [Legenda de estados](#2-legenda-de-estados)  
3. [Níveis ZS-0 a ZS-3](#3-niveis-zs-0-a-zs-3)  
4. [Atalhos gerais (menu / edição / navegação)](#4-atalhos-gerais)  
5. [Painel Read e barra de ferramentas](#5-painel-read)  
6. [Diálogos YES / NO / CANCEL](#6-dialogos-yes-no-cancel)  
7. [Ficheiros temporários por atalho](#7-ficheiros-temporarios)  
8. [Limitações residuais](#8-limitacoes)  
9. [Roteiro de testes — Zero Scan ON](#9-roteiro-testes)  
10. [Roteiro titã (ex.: 20 GB)](#10-roteiro-titan-20gb)  
11. [Regressão modo normal](#11-regressao-modo-normal)  
12. [Assistente IA (v3.0) — atalhos com foco no painel](#12-assistente-ia-v30-atalhos)  
13. [Painel Read — bloco em coluna, autofill e workspace vazio (v3.0.2+)](#13-painel-read-bloco-autofill-idle)  
14. [Win64, indexação SWAR e log de tempo (v3.0.3+)](#14-win64-indexacao-log)  
15. [Chat IA avançado (arquivo) em GB+, scroll dos chats e Ler (v3.0.4+)](#15-aichat-file-scroll-ler)  
16. [Assistente IA — compose, Limpar/Copiar e pasta fastfile_assistant (v3.0.5+)](#16-assistente-compose-305)
17. [FilterBar, status bar e count_matching (v3.0.5.100+)](#17-filterbar-status-count)
18. [Assistente IA — Validar fonte (v3.0.5.136+)](#18-assistente-validar-fonte)
19. [Ocorrências, marcadores, editor de linha e histórico de sessão (v3.0.5.211+)](#19-novidades-3-0-5-225)

---

## 12. Assistente IA (v3.0) — atalhos com foco no painel {#12-assistente-ia-v30-atalhos}

Com o painel **IA → Assistente FastFile** aberto e o foco no memo do assistente, os atalhos do painel **Read** são reencaminhados para acções do ficheiro (não undo de texto do memo):

| Atalho | Acção (resumo) |
|--------|----------------|
| **Ctrl+H** | Substituir / Replace All |
| **Ctrl+L** | Filtro de linhas — **FilterBar** dockada (combo MRU, Aplicar/Continuar/Limpar/Ocultar; ver §17) |
| **Ctrl+Shift+L** | Exportar linhas filtradas |
| **Ctrl+F** | Localizar |
| **Ctrl+Z / Ctrl+Y** | Desfazer / refazer **edição do ficheiro** |
| **Ctrl+C / Ctrl+V** | Copiar selecção ou colar linhas no ficheiro |
| **Ctrl+Shift+Q** | Extrair parte do ficheiro |
| **Ctrl+Shift+F/K/P/M/J/H** | Outras acções whitelist (ver F1) |

Comandos em linguagem natural (ex.: «filtrar X e exportar para txt», «apagar última linha», «abrir o terceiro arquivo da lista» → ficheiro na posição N em **Arquivos recentes**; «quantas linhas contêm X» → **`count_matching_lines`**) podem executar localmente sem rede quando o padrão é reconhecido. Ver **`DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md`** e F1 **`FF_HELP.AssistantBlock`**.

**Menu IA (não Zero Scan):** **Chat com IA** (**Ctrl+Shift+A**), **Chat Avançado com IA** (**Ctrl+Alt+R**) — requer ficheiro aberto na aba Read (caminho efectivo mesmo com `[READ ONLY]` na barra).

---

## 13. Painel Read — bloco em coluna, autofill e workspace vazio (v3.0.2+) {#13-painel-read-bloco-autofill-idle}

Funcionalidades **independentes do Zero Scan** (modo indexado e ZS ON):

| Gesto / atalho | Comportamento |
|----------------|---------------|
| **Ctrl/Alt + arrastar** na coluna **Conteúdo** (col. 2) | Seleção vertical em **bloco**; a largura segue o arrasto; **Ctrl+C** copia o bloco |
| **F11** com bloco activo | Estende a seleção até à borda direita do conteúdo |
| **F11** sem bloco | Alterna ecrã completo |
| **Arrastar para baixo** na coluna **Linha #** (sem Ctrl/Alt) | **Autofill** de linhas em branco (pré-visualização ao vivo) |
| Lista com **checkboxes** | Mesmas regras Ctrl/Alt na área de texto |

**Regressão corrigida em v3.0.2.2:** soltar o rato **não** estende mais o bloco até ao fim da linha — só **F11** faz essa extensão.

**Workspace vazio:** sem abas de documento visíveis, o centro mostra gradiente azul, logo FastFile, watermark grande e textos (título, subtítulo, copyright). Posição fixa ao abrir/fechar o assistente IA. Detalhe técnico: **`DOC_IDLE_LOGO_WORKSPACE.md`**. Ajuda F1: **`FF_HELP.ReadPanelBlock`**, **`FF_HELP.IdleWorkspaceBlock`**.

---

## 14. Win64, indexação SWAR e log de tempo (v3.0.3+) {#14-win64-indexacao-log}

Funcionalidades do **host Win64** e da **leitura indexada (F5)** — aplicam-se em modo normal e Zero Scan OFF (não alteram atalhos ZS):

| Item | Comportamento |
|------|----------------|
| **Build Win64** | `Build\Win64\FastFile.exe` (Delphi 10.4.2); Win32 em `Build\Win32\` |
| **F5 / Ler** | Scan SWAR de LF (8 bytes; wide 32 bytes se CPU tem AVX2) — `uLineIndexScan.pas` |
| **Ficheiros > 2 GB** | Só `temp_ckpt.txt` esparso (sem `temp.txt` denso) — política existente |
| **Barra de progresso** | Actualização suave ~22 Hz durante indexação rápida |
| **Log de tempo** | Canto superior direito — histórico de operações com duração (`AppendOperationTimerLog`) |
| **Scan paralelo** | Desligado por defeito (regressão I/O em índice esparso); sequencial SWAR activo |

Ajuda F1: **`FF_HELP.Win64IndexBlock`** (14 idiomas). Ver **`CHANGELOG_IMPLEMENTACOES.md`** secção **3.0.3.x**.  
Detalhe do pipeline F5 (`TMMFReader` + `TBufferedTextWriter`): **[DOC_INDEXACAO_F5_MMF_WRITER.md](DOC_INDEXACAO_F5_MMF_WRITER.md)**.

---

## 15. Chat IA avançado (arquivo) em GB+, scroll dos chats e Ler (v3.0.4+) {#15-aichat-file-scroll-ler}

Funcionalidades da barra IA e do painel Read — aplicam-se em modo normal e Zero Scan (não alteram os atalhos ZS):

| Item | Comportamento |
|------|----------------|
| **Ctrl+Alt+R** | **Chat IA avançado (arquivo)** — perguntas sobre o ficheiro aberto; abre rápido mesmo em GB+ |
| **Ficheiros grandes** | `ConsumerRAG.py` usa **FastTextRAG** (busca lexical em streaming) por defeito; ex.: TXT de **3,6 GB** abre em segundos, sem embeddings antecipados |
| **Indexação semântica** | Opcional (`--semantic-index`); só quando quiser embeddings completos (lento em ficheiros grandes) |
| **Cancelar carga / Fechar** | Ocultam o painel na hora; plugin (`ConsumerRAG.exe`) parado em segundo plano (`TerminateProcess` + espera 750 ms); botões sempre clicáveis |
| **Roda do rato / Ctrl+roda** | Sobre um painel de chat IA (SQL, Avançado, Assistente, Script) rola aquele histórico, **não** a lista principal nem o zoom |
| **Ler (Ctrl+1 / barra)** | Com um ficheiro já aberto, abre o seletor de ficheiros e carrega de imediato o escolhido |
| **Comparar/Mesclar** | Pré-visualização e histórico de sessão com acentuação correta (UTF-8 / ANSI / UTF-16 auto; journal em UTF-8) |
| **Botão Sobre** | Rótulo curto «Sobre» (`titlebar.about`, 14 idiomas) |

Ajuda F1: **`FF_HELP.AIChatFileBlock`** (14 idiomas). Ver **`CHANGELOG_IMPLEMENTACOES.md`** secção **3.0.4.x**.

---

## 16. Assistente IA — compose, Limpar/Copiar e pasta fastfile_assistant (v3.0.5+) {#16-assistente-compose-305}

| Item | Detalhe |
|------|---------|
| **Ctrl+Alt+A** | Painel Assistente IA |
| **Compose** | Pedidos do tipo «gere um resumo em Word/PDF/DOCX», «gere uma classe em Java…» → ficheiro em **`fastfile_assistant\`** (ao lado do EXE; **não** usa `fastfile_temp`) |
| **Limpar / Copiar** | Botões na linha Enviar / Executar ação — limpam ou copiam a resposta do chat |
| **Trava** | Recusa vírus/malware/formatar disco/comandos do SO; não grava `.exe`/`.bat`/`.vbs`/… |
| **Deploy** | Compose/gateway no `FastFile.exe`; `ConsumerAI.exe` / `ConsumerRAG.exe` / `ScriptEngine.exe` / `CodeCheck.exe` continuam opcionais ao lado |
| **Validar fonte** | Após compose (extensões suportadas) ou via chat — ver **§18** e [`DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md) |

Ajuda F1: **`FF_HELP.AssistantBlock`** (14 idiomas). Ver **`CHANGELOG_IMPLEMENTACOES.md`** secção **3.0.5.x** / **3.0.5.210**.

---

## 17. FilterBar, status bar e count_matching (v3.0.5.100+) {#17-filterbar-status-count}

UX do filtro e da barra de estado — aplicam-se em modo normal e Zero Scan (não alteram os atalhos ZS em si):

| Item | Comportamento |
|------|----------------|
| **Ctrl+L** | Abre **FilterBar** dockada: combo de padrão, **Aplicar** / **Continuar** / **Limpar** / **Ocultar**, faixa **peek** para reexibir, status de hits |
| **MRU** | Últimos **20** padrões no dropdown; persistidos em `ASkin.ini` secção **`[FilterRecentPatterns]`** |
| **Status bar** | Clique em **Mode** / **Wrap** / **Tail** / **Filter** / **Marks** / **View** para activar/desactivar |
| **count_matching_lines** | Pedido ao assistente do tipo «quantas linhas contêm X» — contagem **local** contains/parcial (AI-first; host Delphi, sem ConsumerAI) |
| **Mais ferramentas** | Galeria com fundo azul suave em gradiente; pesquisa e **ESC** polidos |

Ver **`CHANGELOG_IMPLEMENTACOES.md`** secção **3.0.5.100** (internos **.91–.101**).

---

## 18. Assistente IA — Validar fonte (v3.0.5.136+) {#18-assistente-validar-fonte}

Checagem de **sintaxe apenas** (não interpreta / não corre o programa).

| Linguagens | Extensões |
|------------|-----------|
| Python | `.py` → `ScriptEngine.exe --validate` |
| JavaScript | `.js` / `.mjs` / `.cjs` → `CodeCheck.exe` |
| JSX | `.jsx` → `CodeCheck.exe` |
| TypeScript | `.ts` → `CodeCheck.exe` |
| TSX / React | `.tsx` → `CodeCheck.exe` |

| Como pedir | Detalhe |
|------------|---------|
| Botão **Validar** | No banner do ficheiro gerado (só se a extensão for validável) |
| Chat | `validar o fonte`, `validar C:\...\x.py`, `carregar o fonte pra validar` (diálogo filtrado) |
| Lista | `quais linguagens valida?` → resposta com a tabela acima |
| Action id | `validate_source` |
| Gate | Extensão verificada **antes** de abrir companion; constante `VALIDATABLE_SOURCE_EXTS` |

Documento completo (fluxo, i18n, deploy, QA): [`DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md).

---

## 19. Ocorrências, marcadores, editor de linha e histórico de sessão (v3.0.5.211+) {#19-novidades-3-0-5-225}

Aplicam-se em modo normal; em Zero Scan valem as regras de §4 para Ctrl+F / F3 (a barra só lista ocorrências já encontradas).

### 19.1 Janela principal

| Atalho / acção | Comportamento |
|----------------|---------------|
| **Ctrl+F** | Após a pesquisa, abre a **barra de ocorrências** dockada: Anterior/Seguinte, lista paginada e clicável, **Carregar mais** (próxima página lida do disco) |
| **F3** / **Shift+F3** | Próxima / anterior ocorrência (também pelos botões da barra) |
| **Ctrl+B** | Marca/desmarca a linha e mostra a **barra de marcadores**: clique salta, Anterior/Seguinte, remover um, limpar todos, Exportar/Copiar, ocultar/flutuar |
| **Arrastar aba** | Reordena as abas abertas; a ordem é gravada no INI |
| **Opções** | Tamanhos dos MRU, atraso/limites da dica de linha, tamanho do trecho do histórico (`[UserPrefs]`; vazio = padrão) |

### 19.2 Editor de linha (inserir / duplicar / editar — Ctrl+Shift+I / U / E)

| Atalho | Acção |
|--------|-------|
| **Ctrl+F** / **Ctrl+H** | Procurar / Procurar e substituir no texto da linha |
| **F3** | Próxima ocorrência |
| **F4** / **Shift+F4** | Substituir / Substituir todos (substituição vazia pede confirmação) |
| **Alt+↑** / **Alt+↓** | Trazer o conteúdo da linha anterior / seguinte (inserir abre em branco) |
| **Ctrl+Z** / **Ctrl+Y** | Desfazer / Refazer |
| **Ctrl+Shift+Del** | Limpar o texto |
| **Ctrl+Shift+A** | Perguntar à IA sobre a linha |
| **Ctrl+A** / **Ctrl+C** / **Ctrl+V** | Selecionar tudo / Copiar / Colar |
| **Ctrl+Enter** / **Esc** | Confirmar / Cancelar |

### 19.3 Comparar / unir → Histórico de sessão (Ctrl+Shift+H)

| Acção | Comportamento |
|-------|---------------|
| **Checkboxes** | Em **Eventos da sessão** e **Linhas alteradas**; linha 0 = **Selecionar todos** (estado parcial); excluir 1..N |
| **Ordenar ▾** | Por linha (↑/↓) ou por data (mais recente / mais antiga) |
| **De / Até** | Filtro por período (datepicker AlphaSkins); padrão = 1.º dia do mês até hoje; **Esc** limpa o campo; «Até» preenche-se sozinho; no diário activa «Mostrar todo o histórico» |
| **Exportar** | TXT / CSV dos itens marcados; exportar por legenda (Inseridas / Excluídas / Editadas / Desfazer) |
| **Perguntar à IA** | Envia os itens marcados ao Assistente |
| **Ctrl+roda do rato** | Rola a lista do histórico |
| **Duplo clique no título** | Oculta / mostra a lista; painéis dockáveis por arraste |

### 19.4 Diff entre dois arquivos

| Acção | Comportamento |
|-------|---------------|
| **Scroll** | As duas listas rolam sincronizadas |
| **Aplicar ← / →** | Uma passagem em thread, cancelável; só reescreve a região alterada (rápido em 50 GB) |

### 19.5 Histórico de sessão → detalhe do evento (v3.0.5.228)

| Tecla / acção | Comportamento |
|---------------|---------------|
| **Duplo clique** / **Enter** num evento | Abre o detalhe: linhas completas antes / depois, comparação campo a campo, resumo |
| **F3** / **Shift+F3** | Alteração seguinte / anterior |
| **Copiar / Exportar** | Um, os seleccionados ou todos os eventos (TXT / CSV / JSON) |

### 19.6 Anonimizar dados (v3.0.5.227)

| Tecla / acção | Comportamento |
|---------------|---------------|
| **Ctrl+Alt+D** | Anonimizar as linhas seleccionadas (também no clique direito da lista) |
| **Ferramentas → Anonimizar** | Linhas seleccionadas ou o ficheiro inteiro; pré-visualização antes de aplicar; desfazer / refazer |
| Clique direito no histórico | «Remover anonimização do histórico» (linha N ou todas) |

### 19.7 Agente de IA sobre ficheiros (v3.0.5.229–232)

| Tecla / acção | Comportamento |
|---------------|---------------|
| **Ctrl+Alt+G** | Abre o agente (também na barra de ferramentas e no menu Ferramentas) |
| **Aceitar / Rejeitar / Aceitar todas** | Decidir as edições propostas dentro do prazo (20 s por omissão; 5..600 s em Opções → Preferências); ao expirar, as propostas são descartadas |
| Botões sem itens | Desactivados até haver conteúdo (propostas, prompt, fontes, resposta) |
| **Duplo clique** na pré-visualização | Zoom do antes / depois |
| **Último ficheiro gerado** | Reabre o último ficheiro criado (menu + barra da Resposta) |

Ajuda F1: **`FF_HELP.RecentFeaturesBlock2`** (v3.0.5.226–232) + **`FF_HELP.RecentFeaturesBlock`** (14 idiomas). Ver **`CHANGELOG_IMPLEMENTACOES.md`** secções **3.0.5.211–232**.

---

## 0. Regressão — modo indexado normal (não Zero Scan)

Toda a lógica nova está atrás de **`UsesProportionalZeroScanScroll`**  
(=`FZeroScanMode` **e** `HasLineSearchIndex = false`).

| Com `temp.txt` / `temp_ckpt` após F5 normal | Comportamento |
|---------------------------------------------|---------------|
| `UsesProportionalZeroScanScroll` | **false** |
| Shift+End, Ctrl+G | Caminho **antigo** (`gotoLine` / scroll indexado) |
| `GotoPhysicalLine1Based` / `DiscoverZeroScan…` | Saem logo ou delegam para `gotoLine` |
| `TryStartAutoIndexForSearch` | Retorna **false** (continua busca; não bloqueia) |

**Teste mínimo:** secção **B** do [checklist](DOC_ZERO_SCAN_CHECKLIST_TESTES.md) (Force Zero Scan OFF, ~80 MB, F5).

---

## 1. Quando o Zero Scan está ON {#1-quando-o-zero-scan-esta-on}

| Condição | Efeito na abertura |
|----------|-------------------|
| **View → Force Zero Scan Mode** marcado | Próxima abertura **instantânea** (sem `TReadFileThread` na abertura) |
| Ficheiro **> limite GB** (`MaxGbFileIndexed` no INI; padrao **50 GB**) | Instantâneo automático (política *Auto*) |
| Ficheiro **≤ limite GB** | Indexado (`temp.txt` / ckpt) em política *Auto* |
| **View → Open: always build line index** (`fopAlwaysIndex`) | Sempre indexa (ignora tamanho) |
| **Options → Open: always instant** (`fopAlwaysInstant`) | Sempre instantâneo |
| **F5** com Force Zero Scan ON | Reabre **instantâneo** (não indexa de novo) |

**Runtime:** `FZeroScanMode` activo e, inicialmente, **`HasLineSearchIndex = False`** (sem `temp.txt` / `temp_ckpt.txt` abertos) → scroll **proporcional** (`UsesProportionalZeroScanScroll`).

**Importante:** depois de **indexar sob demanda** (YES no diálogo) ou se existirem `temp.txt` / `temp_ckpt.txt` de sessão anterior, muitas funções passam a comportar-se como no **modo indexado** (ZS-2 / ZS-3), mesmo com Force Zero Scan ainda marcado no menu.

---

## 2. Legenda de estados {#2-legenda-de-estados}

| Símbolo | Significado |
|---------|-------------|
| **OK** | Funciona como no modo indexado (ou não depende do mapa de linhas) |
| **~** | Funciona com **limitações** (linha estimada, busca por bytes, scan lento) |
| **?** | Pode mostrar diálogo **indexar agora / continuar sem índice / cancelar** |
| **!** | Exige **`temp.txt` denso** (ou indexação completa) para comportamento pleno |
| **—** | **Inalterado** — operação em ficheiro ou UI que não usa índice denso na abertura |

*(Nas tabelas abaixo usam-se também ✅ ⚡ 📋 ⚠️ ➖ como na versão impressa.)*

---

## 3. Níveis ZS-0 a ZS-3 {#3-niveis-zs-0-a-zs-3}

| Nível | Ficheiros em disco (típico) | Scroll / linhas | Find / F3 | Filtro Ctrl+L | Ir para linha Ctrl+G |
|-------|----------------------------|-----------------|-----------|---------------|----------------------|
| **ZS-0** | Só ficheiro fonte | Proporcional; `totalLines` estimado (amostra 4 MB início+fim) | ? → **NO** = bytes + linha ~ na barra | **Stream** (`TFilterStreamThread`) | ~ estimativa + aviso na barra |
| **ZS-1** | + `temp_filter_hits.bin` | Idem ZS-0 na lista filtrada | Idem | Lista só hits | Idem |
| **ZS-2** | + `temp_ckpt.txt` (+ opcional `temp_blk.idx`) | Mais fiável; Find com hint 64 MB | Exacto após ckpt | Stream ou clássico se denso | ~ ou exacto conforme ckpt |
| **ZS-3** | + `temp.txt` denso | **Exacto** (`UsesProportionalZeroScanScroll = False`) | Motor clássico | `TFilterThread` (índice) | OK exacto |

---

## 4. Atalhos gerais (menu / edição / navegação) {#4-atalhos-gerais}

Alinhado à ajuda **F1** do FastFile. Coluna **ZS-0** = Zero Scan instantâneo **sem** índice. Coluna **Após índice** = após YES no diálogo ou `temp.txt`/`temp_ckpt` presentes.

### 4.1 Ficheiro, visualização e ajuda

| Atalho | Descrição (F1) | ZS-0 (sem índice) | Após índice (ZS-2/3) |
|--------|----------------|-------------------|----------------------|
| **Alt+letra** | Menu barra | — | — |
| **Ctrl+P** | Menu Opções | — | — |
| **Ctrl+O** | Abrir ficheiro | ~ instantâneo se Force ZS / &gt;40 GB / política instant | OK indexa (padrão *Auto*) se ≤40 GB |
| **Ctrl+R** | Ficheiros recentes | — | — |
| **Ctrl+Alt+R** | Sessão só leitura (Read) | — bloqueia gravações na aba Read | — |
| **Ctrl+W** | Word Wrap | — | — |
| **Encoding combo** | UTF-8 / ANSI / UTF-16 | — decode na ListView | — |
| **F1** | Ajuda | OK secção **ZERO SCAN / INSTANT OPEN** | — |

### 4.2 Pesquisa e navegação

| Atalho | Descrição (F1) | ZS-0 (sem índice) | Após índice |
|--------|----------------|-------------------|-------------|
| **Ctrl+F** | Procurar texto | ? **YES** = `BeginOnDemandLineIndex` · **NO** = `StartFindFromPos` por **bytes** · **CANCEL** = aborta | OK find clássico por linha |
| **Ctrl+H** | Procurar e substituir | ? mesmo diálogo no início; Replace **uma** linha usa contagem física até ao byte | OK |
| **F3** | Próxima ocorrência | ~ continua busca por bytes; status com byte + linha **~estimada** | OK |
| **Shift+F3** | Ocorrência anterior | ~ idem | OK |
| **Ctrl+G** | Ir para linha | OK linha **física** (scan); byte na barra | OK linha exacta |
| **Ctrl+Shift+G** | Ir para offset byte (1-based; `$` hex) | OK **`ScrollToFileBytePos`** — recomendado em ZS-0 | OK |
| **Esc** | Cancelar Find; senão limpar filtro/seleção | OK cancela thread de busca | OK |

### 4.3 Edição, clipboard, filtro

| Atalho | Descrição (F1) | ZS-0 (sem índice) | Após índice |
|--------|----------------|-------------------|-------------|
| **Ctrl+Z** | Undo | OK após edições na sessão | OK |
| **Ctrl+Y** | Redo | OK | OK |
| **Ctrl+C** / **Ctrl+Insert** | Copiar seleção | OK conteúdo da viewport | OK |
| **Ctrl+V** / **Shift+Insert** | Colar linhas no ficheiro | ? **`TryStartAutoIndexForMutation`**: YES / NO / CANCEL | OK |
| **Ctrl+L** | Filtro / Grep — **FilterBar** dockada (combo, Aplicar/Continuar/Limpar/Ocultar, peek, MRU 20) | ? pode pedir indexação; senão **`StartFilterStream`** → `temp_filter_hits.bin` | OK `StartFilter` clássico se `FIndexFileStream` |
| **Ctrl+Shift+L** | Exportar tail ou resultados filtrados | OK | OK |

> **Nota F1:** a ajuda diz *"View over index"* para o filtro; com Zero Scan puro o motor é **stream no ficheiro**, não bitmap por linha do `temp.txt`.

### 4.4 Bookmarks e extremos

| Atalho | Descrição (F1) | ZS-0 (sem índice) | Após índice / `temp_blk.idx` |
|--------|----------------|-------------------|------------------------------|
| **Ctrl+B** | Toggle bookmark | ~ linha da ListView; E4: **`FBookmarkBytes`** | OK |
| **F2** / **Shift+F2** | Próximo / anterior bookmark | ~ | OK |
| **Ctrl+Shift+B** | Limpar bookmarks | OK | OK |
| **Shift+Home** / **Shift+End** | Topo / fim do ficheiro | **Shift+End:** regressão na lista proporcional + contagem LF (≤256 MB sync; **>256 MB** thread com progresso) → `GotoPhysicalLine1Based` | OK |

### 4.5 Tail / Follow

| Atalho | Descrição (F1) | ZS-0 (sem índice) | Após índice |
|--------|----------------|-------------------|-------------|
| **Ctrl+T** | Tail / Follow | OK activa follow | OK |
| **Ctrl+Shift+T** | Pausar / retomar Tail | OK | OK |
| **Tail (timer)** | Novas linhas no fim | OK **E5:** sem `temp.txt`, conta `#10` no **delta**; pode append em `temp_ckpt.txt` | OK |

### 4.6 Modo Select (checklist)

| Atalho | Descrição (F1) | ZS-0 (sem índice) | Após índice |
|--------|----------------|-------------------|-------------|
| **Ctrl+Shift+S** | Select (checkboxes) | OK abre checklist | OK |
| Atalhos com foco na checklist | Mesmos atalhos Read | ~ delete em lote pode pedir índice | ! segmentado se `temp.txt` denso |

---

## 5. Painel Read e barra de ferramentas {#5-painel-read}

| Atalho | Descrição (F1) | Com Zero Scan ON |
|--------|----------------|------------------|
| **Ctrl+1** | Aba Read | — |
| **F5** | Read / carregar | ~ instantâneo se Force ZS / &gt;40 GB; senão indexação normal |
| **Ctrl+Shift+X** | Clear | — |
| **Ctrl+Shift+F** | Find in Files | — |
| **Ctrl+Shift+K** | Split Files | — |
| **Ctrl+Alt+P** | Split por padrão/regex | — |
| **Ctrl+Shift+M** | Merge linhas | — |
| **Ctrl+Shift+J** | Merge ficheiros | — |
| **Ctrl+Shift+H** | Compare / merge + histórico | — |
| **Ctrl+Shift+P** | Partes iguais (LF-safe) | — |
| **Ctrl+Shift+Q** | Extrair partes do arquivo (LF-safe) | — |
| **Ctrl+Shift+S** | Select | Ver §4.6 |
| **Ctrl+Num+** / **Ctrl+Num-** | Zoom fonte ListView | — |
| **Ctrl + roda** | Zoom fonte (ListView) | — |
| **Ctrl+Shift+I/U/E/D** | Inserir / duplicar / editar / apagar linha | ? `TryStartAutoIndexForMutation` |
| **Ctrl+Shift+O** | Export | — |
| **Ctrl+Shift+W** | Close (Return visível) | — |
| **Ctrl+Shift+A** | Chat com IA | — |
| **Ctrl+Alt+R** (toolbar) | Chat Avançado com IA | — *(não confundir com read-only)* |
| **Ctrl/Alt + arrastar** (col. conteúdo) | Seleção vertical em bloco | **OK** — largura do arrasto mantida no MouseUp (v3.0.2+) |
| **F11** (com bloco activo) | Estender bloco à largura total | **OK** — só quando F11 premido (não no soltar rato) |
| **F11** (sem bloco) | Ecrã completo | — |
| **Arrastar col. Linha #** (sem Ctrl/Alt) | Autofill linhas em branco | **OK** — pré-visualização; CSV = só delimitadores |
| **Duplo-clique** | Editar linha seleccionada | ? `editFile` |
| **Drag & Drop** | Abrir ficheiro | ~ mesma política que Ctrl+O / F5 |

---

## 6. Diálogos YES / NO / CANCEL {#6-dialogos-yes-no-cancel}

| Botão | Acção |
|-------|--------|
| **YES** | `BeginOnDemandLineIndex` — passagem completa no disco; cria `temp_ckpt.txt` e, conforme tamanho, `temp.txt` / `temp_blk.idx` |
| **NO** | Continua **sem** índice: busca por bytes, filtro stream, edição com contagem física lenta, etc. |
| **CANCEL** | Aborta a operação (Find, filtro, mutação) |

**Busca:** `TryStartAutoIndexForSearch` — **Ctrl+F**, **Ctrl+H**, **Ctrl+L**, **F3**.  
**Mutação:** `TryStartAutoIndexForMutation` — colar, inserir/duplicar/editar/apagar linha, duplo-clique.

---

## 7. Ficheiros temporários por atalho {#7-ficheiros-temporarios}

| Ficheiro | Criado por (típico) |
|----------|---------------------|
| `temp_ckpt.txt` | YES no diálogo; Tail E5; indexação sob demanda |
| `temp.txt` | Indexação sob demanda ou F5 sem Force ZS |
| `temp_blk.idx` | Indexação ZS sob demanda (E1, blocos 64 MB) |
| `temp_filter_hits.bin` | **Ctrl+L** em scroll proporcional (E2) |

Pasta: junto ao executável (`ExtractFilePath(ParamStr(0))`).

---

## 8. Limitações residuais (após v2.1.7.21+)

| Funcionalidade | Estado com Zero Scan ON (sem `temp.txt` denso) |
|----------------|------------------------------------------------|
| **Ctrl+G** | **OK** — salto por linha física (`GotoPhysicalLine1Based`, scan no ficheiro) |
| **Scroll / ListView** | **~** — roda/barra proporcionais até descobrir N; **Shift+End** conta linhas (≤256 MB) ou sonda binária na lista |
| **Delete em lote** | **OK** via MMF (`BatchDeleteLinesByMMF`); diálogo opcional para indexar; segmentado só com `temp.txt` |
| **Replace All** | **OK** streaming sem índice; segmentado só com `temp.txt` denso |
| **Ajuda F1** | **OK** — secção ZERO SCAN / INSTANT OPEN |
| **Paridade 100%** | Indexar (YES) ou `temp.txt` denso — filtro clássico + segmentado pesado |

Detalhe: [DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md](DOC_ZERO_SCAN_IMPACTOS_E_SEGMENTADO.md) §§3–9.

---

## 9. Roteiro de testes — Zero Scan ON {#9-roteiro-testes}

Checklist marcável completa: [DOC_ZERO_SCAN_CHECKLIST_TESTES.md](DOC_ZERO_SCAN_CHECKLIST_TESTES.md).

### 9.1 Preparação (qualquer tamanho)

| # | Passo | OK |
|---|--------|-----|
| P1 | Compilar a versão actual do FastFile. | ☐ |
| P2 | Opcional: apagar junto ao `.exe` — `temp.txt`, `temp_ckpt.txt`, `temp_blk.idx`, `temp_filter_hits.bin`. | ☐ |
| P3 | **View → Force Zero Scan Mode** — opcional (ficheiros ≥40 GB abrem instantâneo em política *Auto*). | ☐ |
| P4 | **F5** ou arrastar o ficheiro de teste. | ☐ |
| P5 | Abertura rápida; sem barra longa de indexação na abertura. | ☐ |
| P6 | Sem `temp.txt` logo após abrir (ZS-0 puro). | ☐ |

### 9.2 Ordem sugerida (~80 MB ou médio)

| # | Atalho | O que verificar | OK |
|---|--------|-----------------|-----|
| T1 | Scroll / roda | Linhas aproximadas na ListView | ☐ |
| T2 | **Shift+Home** | Topo da lista | ☐ |
| T3 | **Shift+End** | Fim real; barra pode actualizar `totalLines` | ☐ |
| T4 | **Ctrl+Shift+G** | Byte `1` ou `$` + hex — salto exacto | ☐ |
| T5 | **Ctrl+G** | Ex.: linha `1000` — linha física + byte na barra | ☐ |
| T6 | **Ctrl+F** → **NO** | Busca por bytes | ☐ |
| T7 | **F3** / **Shift+F3** | Próxima / anterior; status `byte … (~line …)` | ☐ |
| T8 | **Ctrl+L** | Filtro stream ou diálogo indexar | ☐ |
| T9 | **Esc** | Limpar filtro / cancelar Find | ☐ |
| T10 | **Ctrl+H** | Diálogo abre; Replace All sem índice prévio | ☐ |
| T11 | **Ctrl+F** → **YES** | Indexação sob demanda; depois F3 exacto | ☐ |
| T12 | **F1** | Secção ZERO SCAN no fim da ajuda | ☐ |

**Edição / delete:** usar **cópia** do ficheiro — **Ctrl+Shift+E**, **Ctrl+Z**, **Ctrl+Shift+S** + delete (poucas linhas).

---

## 10. Roteiro titã (ex.: 20 GB) {#10-roteiro-titan-20gb}

Ficheiros acima do limite GB (View → **Open: indexed file size limit**; padrão **50 GB**) entram em **abertura rápida**. O ficheiro de teste ~19 GB indexa por defeito. Se a indexação falhar, o programa pode oferecer abertura rápida e memorizar o ficheiro (menu **Open: build line index for this file** força nova indexação).

### 10.1 Abertura

| Esperado | OK |
|----------|-----|
| Abertura em segundos (não minutos de indexação) | ☐ |
| Mensagem / timer: “Instant Open (Zero Scan)” ou equivalente | ☐ |
| `UsesProportionalZeroScanScroll` activo (sem `temp.txt` / `temp_ckpt` no início) | ☐ |

### 10.2 Navegação (prioridade alta)

| Atalho | O que testar | Resultado esperado | OK |
|--------|----------------|-------------------|-----|
| Scroll / roda | Mover na lista | Linhas **aproximadas** | ☐ |
| **Shift+Home** | Início | Topo | ☐ |
| **Shift+End** | Fim do ficheiro | **1.ª vez pode demorar** (descobre última linha: sonda binária na lista em titãs); vai ao fim físico; scroll pode “encolher” | ☐ |
| **Ctrl+Shift+G** | Byte `1` ou offset hex (`$…`) | Salto **exacto** por byte — **recomendado** em 20 GB | ☐ |
| **Ctrl+G** | Linha grande (ex. `100000`) | Scan até linha física; byte na barra de status | ☐ |

### 10.3 Pesquisa

| Atalho | O que testar | Resultado esperado | OK |
|--------|----------------|-------------------|-----|
| **Ctrl+F** | Termo que **existe** | Diálogo **YES / NO / CANCEL** | ☐ |
| **Ctrl+F** → **NO** | Continuar sem indexar | Progresso na barra; match move a lista | ☐ |
| **F3** / **Shift+F3** | Após Ctrl+F (NO) | Próxima / anterior por bytes | ☐ |
| **Ctrl+F** → **YES** | Indexar 20 GB inteiro | **Muito lento** — só se quiser testar indexação completa | ☐ |

### 10.4 Filtro e ajuda

| Atalho | O que testar | OK |
|--------|----------------|-----|
| **Ctrl+L** | Padrão com **poucos** hits; pode criar `temp_filter_hits.bin` | ☐ |
| **Esc** | Limpar filtro activo | ☐ |
| **F1** | Secção **ZERO SCAN / INSTANT OPEN** | ☐ |

### 10.5 Substituição e edição (só em **cópia** do ficheiro)

| Atalho | O que testar | Nota em 20 GB | OK |
|--------|----------------|---------------|-----|
| **Ctrl+H** | Abrir diálogo | Não exige índice ao abrir | ☐ |
| **Ctrl+H** → Find Next (**NO**) | Busca | | ☐ |
| **Ctrl+H** → Replace **uma** | Uma ocorrência | Pode pedir indexar | ☐ |
| **Ctrl+H** → Replace **All** | Termo **raro** | Streaming; pode levar muito tempo | ☐ |
| Duplo-clique / **Ctrl+Shift+E** | Editar uma linha | Diálogo YES/NO/CANCEL | ☐ |
| **Ctrl+Z** | Undo após editar | | ☐ |
| **Ctrl+Shift+S** + delete | **2–5 linhas** marcadas | **NO** no diálogo indexar; MMF — não testar milhares de linhas | ☐ |

### 10.6 Tail (opcional)

| Atalho | O que testar | OK |
|--------|----------------|-----|
| **Ctrl+T** | Activar follow | ☐ |
| **Ctrl+Shift+T** | Pausar / retomar | ☐ |
| Append externo ao fim do ficheiro | Novas linhas na lista | ☐ |

### 10.7 Barra Read (independentes do mapa de linhas)

| Atalho | Funcionalidade | OK |
|--------|----------------|-----|
| **Ctrl+Shift+F** | Find in Files | ☐ |
| **Ctrl+Shift+K** | Split Files | ☐ |
| **Ctrl+Shift+P** | Partes iguais (LF-safe) | ☐ |
| **Ctrl+Shift+Q** | Extrair partes do arquivo | ☐ |
| **Ctrl+Shift+O** | Export | ☐ |
| **F5** | Reabrir (continua instantâneo com Force ZS) | ☐ |

### 10.8 Evitar no primeiro teste de 20 GB

| Operação | Motivo |
|----------|--------|
| **Ctrl+F** → **YES** (indexar tudo) | Uma passagem completa no disco — horas possíveis |
| **Delete em lote** grande sem indexar | MMF em 20 GB — usar poucas linhas só |
| **Replace All** em termo muito frequente | Milhões de ocorrências — disco e tempo |

### 10.9 Registo de falhas (20 GB)

| # | Atalho / passo | Esperado | Obtido |
|---|----------------|----------|--------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

---

## 11. Regressão modo normal {#11-regressao-modo-normal}

Garantir que o modo indexado **não** regrediu (ver também §0).

| # | Passo | OK |
|---|--------|-----|
| R1 | **Force Zero Scan OFF** | ☐ |
| R2 | F5 em ficheiro **~80 MB** | ☐ |
| R3 | `temp.txt` / `temp_ckpt.txt` criados | ☐ |
| R4 | **Shift+End** / **Ctrl+G** — caminho indexado (`gotoLine`), sem scan longo de titã | ☐ |
| R5 | **Ctrl+F** / **Ctrl+L** — sem diálogo Zero Scan | ☐ |

---

## Histórico

| Data | Nota |
|------|------|
| 2026-05-23 | Documento inicial. |
| 2026-05-25 | Alias `DOC_ZS_ATALHOS.md`; âncoras ASCII para preview Markdown. |
| 2026-05-26 | Ctrl+G físico, Replace All sem índice obrigatório, delete lote + diálogo, F1 Zero Scan. |
| 2026-05-26 | §9–11: roteiros de teste QA, roteiro titã 20 GB, regressão. |
| 2026-06-02 | **v3.0.2.0:** §13 bloco coluna/autofill; tabela §5 F11/Ctrl+Alt; workspace vazio. |
| 2026-06-28 | **v3.0.3.0:** §14 Win64 + indexação SWAR + log de tempo; F1 `FF_HELP.Win64IndexBlock`. |
| 2026-07-16 | **v3.0.4.0:** §15 Chat IA avançado (arquivo) em GB+, scroll dos chats, Ler abre seletor, acentuação comparar/mesclar; F1 `FF_HELP.AIChatFileBlock`. |
| 2026-08-29 | **v3.0.5.0:** §16 Assistente compose (docs/código), Limpar/Copiar, `fastfile_assistant\`, trava de segurança; F1 `FF_HELP.AssistantBlock`. |
| 2026-09-06 | **v3.0.5.100:** §17 FilterBar dockada (MRU 20, Aplicar/Continuar/Limpar/Ocultar), toggles na status bar, `count_matching_lines`; Ctrl+L actualizado em §4.3 / §12. |
| 2026-09-09 | **v3.0.5.136–137:** §18 Validar fonte (Python/JS/JSX/TS/TSX); chat carregar/validar; `DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`; `CodeCheck.exe`. |
| 2026-09-16 | **v3.0.5.210:** 14 idiomas UI (JA + zh-CN/zh-TW); lazy-load i18n; Version History / F1 / docs sync. |
| 2026-10-08 | **v3.0.5.226–232:** §19.5 detalhe do evento do histórico (Enter, F3/Shift+F3), §19.6 anonimizar (Ctrl+Alt+D), §19.7 agente de IA (Ctrl+Alt+G, prazo para aceitar, botões por conteúdo); F1 `FF_HELP.RecentFeaturesBlock2`. |
| 2026-09-27 | **v3.0.5.211–225:** §19 barra de ocorrências (Ctrl+F/F3), barra de marcadores (Ctrl+B), abas reordenáveis, Opções, atalhos do editor de linha, histórico de sessão (checkboxes, ordenar, filtro De/Até, exportar, Perguntar à IA), diff sincronizado; F1 `FF_HELP.RecentFeaturesBlock`. |

---

*Implementação: `MainUnit.pas` (`ApplyReadPanelKey` ~35422, `TryStartAutoIndexForSearch` ~29975).*
