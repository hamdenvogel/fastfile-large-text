# FastFile — Relatório de Implementações

**Data:** 8 de outubro de 2026  
**Projeto:** FastFile (Delphi 7 / Delphi 10.4.2 Win64)  
**Pasta:** `FileReadThread-2\Src` (host D10: `delphi10_4_2\FastFile\src`)  
**Versão publicada actual:** **`3.0.5.232`** — agente de IA sobre ficheiros (SQL / linguagem natural, propostas com prazo para aceitar), anonimizar dados, detalhe de eventos do histórico, PPI personalizado (ver secções abaixo)

---

## ★ FastFile Professional — nome do produto (outubro/2026)

- **Marca:** o produto passa a apresentar-se como **FastFile Professional** (edição Professional / Profissional). Novas constantes **`UnConsts.APPLICATION_EDITION`** (`'Professional'`) e **`APPLICATION_DISPLAY_NAME`** (`'FastFile Professional'`), usadas no título da janela principal, barra de título, logótipo do ecrã vazio, **Sobre**, ecrã de boas-vindas e `Application.Title`. `APPLICATION_FULLNAME` = `'Professional editor for huge text files'`. Metadados do executável (`FileDescription` / `ProductName`) = **FastFile Professional**. **`APPLICATION_NAME`** continua `'FastFile'` porque é também a secção `[FastFile]` do `ASkin.ini` (configurações existentes preservadas). README, README técnico, apresentação e roadmap actualizados.

## ★ FastFile 3.0.5.232 — Agente de IA: prazo para decidir e respostas mais seguras (outubro/2026)

- **v3.0.5.232 (Current / Atual):** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.232`**. As edições propostas pelo agente aguardam **20 s** por **Aceitar / Rejeitar / Aceitar todas** (configurável em **Opções → Preferências**, 5..600 s; valor vazio/inválido é recusado e volta ao padrão). Distintivo de tempo com ícone (normal / urgente / expirado); a contagem pausa enquanto há uma confirmação aberta; ao expirar, as propostas são descartadas e o pedido tem de ser refeito.
- **v3.0.5.232 (interno):** Botões que actuam sobre itens (Aceitar, Rejeitar, Aceitar todas e barras de prompt, fontes e resposta) só ficam activos quando há conteúdo — reavaliados em cada alteração da lista ou do texto (`UpdateEditButtons` / `UpdateToolButtons` / `AnswerChange`). **Substituir tudo** conta as ocorrências antes: 0 ocorrências = nada é proposto e a resposta diz isso. O agente nunca afirma uma alteração que não foi colocada na fila (mensagem honesta «Nada foi alterado nem proposto…», 14 idiomas). Respostas do agente e de «Fale com a IA» no **idioma da interface** (`AssistantLangPromptName` movido para `uI18n`). Parser aceita `"tool":{"replace_all":{...}}` (teste `tests/agent/ParseShapeTest`). Janela de ficheiros gerados com rótulo traduzido **«Pasta:» / «Ficheiro:»**. Correcção: após dividir o ficheiro aberto a lista principal volta a mostrar as linhas. F1 ganha o bloco **`FF_HELP.RecentFeaturesBlock2`** (14 idiomas). Sync **HISTORY** / README / ROADMAP / `DOC_ZS_ATALHOS.md` / `DOCUMENTACAO_MODELOS_IA.md` / `DOC_AGENTE_IA_CHECKLIST_TESTES.md` (secções 1.4.1 e 1.6).

## ★ FastFile 3.0.5.231 (interno) — Agente de IA: SQL, correspondência exacta e ficheiros gerados (outubro/2026)

- **v3.0.5.231 (interno):** O pedido pode ser **SQL** ou linguagem natural em qualquer dos 14 idiomas: `SELECT` com `WHERE` / `GROUP BY` / `ORDER BY` / `SUM` / `COUNT` em ficheiros delimitados; `UPDATE` / `DELETE` / `INSERT` / `ALTER TABLE` viram propostas; SQL digitado directamente corre sem IA (**`uAgentSql`**). «Total: N registo(s) encontrado(s)» quando se aplica. Palavra inteira («não parcial», «exacto») vs procura parcial reconhecida nos 14 idiomas (**`uAgentMatchIntent`**). Janela **«Ficheiro(s) gerado(s) com sucesso»** (**`uExportDoneDlg`**): abrir no FastFile, abrir pasta, copiar caminho(s); também após dividir / exportar; **«Último ficheiro gerado»** (menu + barra da Resposta). Lista de fontes com MRU **Recentes** (procurar, excluir, limpar tudo). Painel do Assistente com modo **«Agente»**.

## ★ FastFile 3.0.5.230 (interno) — Agente sobre o core + layout (outubro/2026)

- **v3.0.5.230 (interno):** Edições aceites usam as rotinas de streaming do core (**`uAgentPatch`**; ficheiros de vários GB, progresso e Cancelar). Pré-visualização das edições propostas: antes / depois realçado, paginada (segura em RAM), duplo clique para zoom; textos cortados mostram o texto completo ao passar o rato, com Copiar. Ficheiros **UTF-16** lidos correctamente pelas ferramentas do agente. Legendas cortadas alargadas em todos os forms (`FfFitCaptions`); o layout acompanha mudanças de resolução / escala do Windows em execução (`WM_DISPLAYCHANGE`).

## ★ FastFile 3.0.5.229 (interno) — Novo: agente de IA sobre ficheiros (outubro/2026)

- **v3.0.5.229 (interno):** Barra de ferramentas, menu **Ferramentas** e **Ctrl+Alt+G**: 1) escolher ficheiros / pastas (máscara, profundidade, máx. ficheiros, filtro), 2) descrever o pedido, 3) rever: **Resposta**, **Edições propostas**, **Prompt revisto**, **Ficheiros encontrados**. Nada é gravado antes de Aceitar. Ferramentas: contar, procurar, ler, editar / inserir / excluir linhas, anonimizar e acções do core (substituir tudo, dividir, exportar, filtrar, marcadores…). MRU de pedidos recentes (procurar, excluir 1..N, limpar tudo; INI). Barras com Novo, Limpar, Copiar, Perguntar à IA, Traduzir, Sugerir. Overlay de carregamento com progresso e Cancelar. Units: `uAgentWorkspace`, `uAgentLoop`, `uAgentProtocol`, `uAgentTools`, `uAgentActions`, `uAgentBridge`, `uAgentPrefs`.

## ★ FastFile 3.0.5.228 (interno) — Histórico de sessão: detalhe do evento (outubro/2026)

- **v3.0.5.228 (interno):** Duplo clique (ou Enter) num evento da sessão (**`uHistLineDetailDlg`**): linhas completas antes / depois, alteração anterior / seguinte (**F3 / Shift+F3**), comparação campo a campo (delimitador detectado automaticamente) e resumo do evento. Copiar ou exportar um, os seleccionados ou todos os eventos de uma vez (TXT / CSV / JSON).

## ★ FastFile 3.0.5.227 (interno) — Anonimizar dados (outubro/2026)

- **v3.0.5.227 (interno):** Clique direito na lista ou menu **Ferramentas**: linhas seleccionadas (**Ctrl+Alt+D**) ou o ficheiro inteiro (**`uAnonymize`** / **`uAnonymizeDialog`**). Valores privados viram valores falsos do mesmo tipo e tamanho (números, datas, e-mails, códigos, nomes); colunas, delimitador, ignorar cabeçalho e palavras a manter; pré-visualização antes de aplicar; desfazer / refazer. Gravado no próprio ficheiro — rápido em qualquer tamanho. O histórico de sessão mostra antes / depois por linha; clique direito **«Remover anonimização do histórico»** (linha N ou todas).

## ★ FastFile 3.0.5.226 (interno) — PPI personalizado e retradução (outubro/2026)

- **v3.0.5.226 (interno):** Botão **PPI personalizado** na barra de ferramentas: escolhe a escala da interface em execução, sincronizado com o combo de zoom da barra de estado; item **«Restaurar padrão»** e PPI padrão nas Preferências; a janela permanece dentro do ecrã após redimensionar. A troca de idioma também traduz os textos já visíveis.

## ★ FastFile 3.0.5.225 (interno) — BOM UTF-8, mensagens de tempo traduzidas e sync de docs (setembro/2026)

- **v3.0.5.225 (interno):** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.225`**. Mensagens de tempo («Time to execute that operation» e afins) passam por `TrText` em 14 idiomas. 17 units gravadas em **UTF-8 com BOM** (Biblioteca, uAssistantPipelineStore, uCompareMergeUI, uFastFileAIPythonMacroHelp, uFastFileAIScreenHelp, uFastFileAssistantCatalog, uFastFileAssistantMap, uFastFileAssistantRAG, uFilterBar, uMMF_utf8, UnConsts, UnReadFileThread_utf8, UnUtils, uWelcomeScreen, uLineEditor, uHistChangedIndex, uFileSessionHistory) — sem acentos/setas/símbolos corrompidos em nenhum idioma (backup em `backup_bom_20260927_193156`).
- **v3.0.5.225 (interno):** F1 ganha o bloco traduzido **`FF_HELP.RecentFeaturesBlock`** (marcador `MK_HELP_RECENT`, 14 idiomas); `FF_HELP.AssistantBlock` → v3.0.5.225. Sync **HISTORY** / README / ROADMAP / `DOC_ZS_ATALHOS.md` / `DOCUMENTACAO_MODELOS_IA.md`.

## ★ FastFile 3.0.5.224 (interno) — Histórico de sessão: checkboxes, ordenar e filtro de datas (setembro/2026)

- **v3.0.5.224 (interno):** Em **Comparar / unir → Histórico de sessão**: listas **Eventos da sessão** e **Linhas alteradas** com checkboxes, **Selecionar todos** (estado parcial) e **excluir 1..N**; menu **Ordenar** (linha ↑/↓, data mais recente/mais antiga); **filtro por período** com `TsDateEdit` do AlphaSkins (De/Até; padrão = 1.º dia do mês até hoje; Esc limpa o campo; preenche «Até» automaticamente; no diário marca «Mostrar todo o histórico»); **Exportar TXT/CSV** e **Perguntar à IA** sobre os itens marcados. Lista de linhas alteradas em dois níveis (linha + data/hora); o item seleccionado mantém a **cor da legenda** (borda + negrito, sem fundo escuro). Filtros aplicam-se só aos itens visíveis. Novas chaves i18n `Hist.Tool.Sort*`, `Hist.SortMenu.*`, `Hist.DateFilter.*`, `Hist.ChangedLinesFiltered` (14 idiomas). `uHistChangedIndex`: `THistDateQuery` / `HciParseDateQuery` / `HciStampMatches`.

## ★ FastFile 3.0.5.223 (interno) — Editor de linha renovado (setembro/2026)

- **v3.0.5.223 (interno):** Inserir antes/depois abre **em branco**, com botões para trazer o conteúdo da **linha anterior (Alt+↑)** / **seguinte (Alt+↓)**; **Limpar** (Ctrl+Shift+Del); barra completa de **Procurar / Substituir** (Ctrl+F, Ctrl+H, F3, **F4** substituir, **Shift+F4** substituir todos, regex); pesquisa vazia bloqueada e substituição vazia pede confirmação; erros/resultados em caixas de mensagem (`FastFileMsg*`); **Desfazer/Refazer** (Ctrl+Z / Ctrl+Y); **Perguntar à IA** (Ctrl+Shift+A); **Ctrl+Enter** confirma, **Esc** cancela; atalhos visíveis nas legendas e botões dimensionados ao texto.

## ★ FastFile 3.0.5.222 (interno) — Abas reordenáveis, Opções e correcção da edição (setembro/2026)

- **v3.0.5.222 (interno):** **Arrastar e soltar** para reordenar as abas abertas (ordem gravada no INI; cursor de arraste). Diálogo **Opções** (`uUserPrefs` / `uPrefsDialog`, secção `[UserPrefs]`): tamanhos dos MRU (filtro, assistente, abas), atraso/limites da dica de linha e tamanho do trecho gravado no histórico — vazio/inválido volta ao padrão. Correcção: editar linha já não falha nem deixa a ListView em branco.

## ★ FastFile 3.0.5.221 (interno) — Diff: scroll sincronizado + aplicar rápido (setembro/2026)

- **v3.0.5.221 (interno):** Aba **Diff entre dois arquivos**: as duas listas rolam em sincronia; legendas traduzidas. **`uMergeApply`**: aplicar esquerda ↔ direita numa única passagem em thread, cancelável — copia bytes crus, só reconstrói a região entre a primeira e a última alteração (escrita no próprio ficheiro até 64 MB; caso geral temporário + `ReplaceFile` atómico); diário gravado num único append. Rápido mesmo em ficheiros de 50 GB.

## ★ FastFile 3.0.5.220 (interno) — Histórico de comparar/unir reformulado (setembro/2026)

- **v3.0.5.220 (interno):** Realce da **substring alterada**, espaçamento revisto, lista **Linhas alteradas** paginada (**`uHistChangedIndex`**: índice em thread, ~35 bytes por linha, vai para disco acima de 1M entradas — seguro em RAM), selecção sincronizada com o diário, **MRU** de ficheiros com histórico de merge, limpar lista / MRU com confirmação, ocultar/mostrar listas (duplo clique nos títulos), painéis **dockáveis** por arraste.

## ★ FastFile 3.0.5.219 (interno) — CR+LF / LF / CR em todas as rotinas (setembro/2026)

- **v3.0.5.219 (interno):** **`uEolPolicy`**: detecção de fim de linha por amostra (64 KB, cache por caminho + tamanho + data); indexação/percurso usa LF ou CR (Mac clássico); linhas novas gravadas com o EOL do ficheiro (misto/desconhecido → EOL padrão). Aplicado a indexar, procurar, editar, inserir, unir e exportar.

## ★ FastFile 3.0.5.218 (interno) — Arranque com muitas abas + troca de idioma (setembro/2026)

- **v3.0.5.218 (interno):** Arranque mais rápido ao restaurar muitas abas (mensagem «a aplicação pode parecer travada» traduzida). Troca de idioma mais rápida e **cancelável** no overlay (Cancelar já não congela). Texto do pipeline do Assistente deixa de ficar corrompido após trocar a partir do chinês. Várias correcções de tradução nos 14 idiomas.

## ★ FastFile 3.0.5.217 (interno) — Histórico em ficheiros enormes + exportar por legenda (setembro/2026)

- **v3.0.5.217 (interno):** **`uHistPagedPreview`**: pré-visualização paginada do histórico (índice esparso de offsets a cada 1024 linhas em thread, cache LRU de páginas, índice `.lidx` reutilizado em disco) — seguro em RAM para qualquer tamanho. **Ctrl+roda do rato** rola a lista do histórico. **Exportar por legenda**: Inseridas / Excluídas / Editadas / Desfazer, um ou vários tipos num único ficheiro.

## ★ FastFile 3.0.5.216 (interno) — Host Delphi 10.4: arquitectura + layout (setembro/2026)

- **v3.0.5.216 (interno):** `ARQUITETURA_TECNICA_FASTFILE.md` actualizado para o host Delphi 10.4.2; correcção de controlos sobrepostos na janela principal.

## ★ FastFile 3.0.5.215 (interno) — Guarda de excepções + watchdog (setembro/2026)

- **v3.0.5.215 (interno):** **`uFastFileAppGuard`**: guarda global de excepções VCL (log + mensagem segura, sem reentrância). **`uFastFileWatchdog`**: detecta UI sem heartbeat e pressão de memória; regista, alerta e cancela threads cooperativas (limiar maior durante operações pesadas).

## ★ FastFile 3.0.5.214 (interno) — Barra de marcadores, mensagens e Opções (setembro/2026)

- **v3.0.5.214 (interno):** **`uBookmarkBar`** (Ctrl+B): barra dockada com lista de marcadores, salto por clique, Anterior/Seguinte, remover um, limpar todos, Exportar/Copiar, ocultar/flutuar. **`uFastFileMsgDlg`**: caixas de mensagem profissionais (gradiente suave, cantos arredondados; `FastFileMsgInfo/Warn/Error/Success/YesNo`). Piloto do diálogo **Opções** (`uUserPrefs` / `uPrefsDialog`). **`uMruFind`**: procura parcial nos MRU + itens «Mais» / «Limpar tudo».

## ★ FastFile 3.0.5.213 (interno) — Detectar e converter EOL / codificação (setembro/2026)

- **v3.0.5.213 (interno):** **`uFileFormatConvert`**: detecção de fim de linha (Windows / Unix / Mac / misto) e de codificação; conversão em streaming ao estilo Notepad++ (UTF-8 com/sem BOM, UTF-16, ANSI).

## ★ FastFile 3.0.5.212 (interno) — Pipeline AI-First pós-acção (setembro/2026)

- **v3.0.5.212 (interno):** **`uAssistantPostAction`**: após procurar, filtrar, exportar, dividir, unir, comparar, etc., o Assistente oferece «E agora?» com chips contextuais + rascunho de pergunta IA. **`uAssistantPipelineStore`**: ponte em memória + disco (`assistant_pipeline.bridge`) com últimas actividades, factos e turnos do chat para continuar de onde parou.

## ★ FastFile 3.0.5.211 (interno) — Barra de ocorrências + galeria de pesquisa (setembro/2026)

- **v3.0.5.211 (interno):** **`uFindOccurrencesBar`**: após Ctrl+F, barra dockada com Anterior/Seguinte (Shift+F3 / F3), lista paginada e clicável de ocorrências e «Carregar mais» a partir do disco. **`UnitPopupFileSearchGallery`**: galeria «Ferramentas de pesquisa» na barra do ficheiro (mesmo visual de «Mais ferramentas»).

## ★ FastFile 3.0.5.210 (interno) — Lazy-load i18n + sync de docs (setembro/2026)

- **v3.0.5.210:** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.210`**. No arranque, `uI18n` preenche só **inglês + idioma activo** (INI / Windows); os restantes carregam na primeira troca do combo. `PutNV` usa allow-list de ponteiros (sem `TStringList.Tag`). Sync **HISTORY** / F1 **`FF_HELP.AssistantBlock`** / README / ROADMAP / `DOC_ZS_ATALHOS.md` / `DOCUMENTACAO_MODELOS_IA.md`.
- **v3.0.5.210 (interno):** correcções de compile (literais >255, concatenação `#13#10 +`); remoção de bloco duplicado em `uI18n.pas`.

## ★ FastFile 3.0.5.209 (interno) — Chinês simplificado + tradicional (setembro/2026)

- **v3.0.5.209 (interno):** **13.º / 14.º** idiomas de UI — **Chinese (Simplified)** `zh-CN` e **Chinese (Traditional)** `zh-TW`; `Set14` / `RegexExamples_Set14`; combo + Assistente (简体中文 / 繁體中文); detecção `LANG_CHINESE`. Cobertura completa das tabelas `G*` / `GText*`.

## ★ FastFile 3.0.5.208 (interno) — PutNV O(n) no arranque (setembro/2026)

- **v3.0.5.208 (interno):** população i18n com **`PutNV`** (append O(1)) em vez de `TStringList.Values` (O(n²)); `CollapseDuplicateKeysKeepLast` + sort para lookup binário.

## ★ FastFile 3.0.5.207 (interno) — Japonês 12.º idioma (setembro/2026)

- **v3.0.5.207 (interno):** **Japanese** como 12.º idioma (`alJapanese` / `ja`); cobertura completa em `uI18n.pas` (Set12→Set12/JA, help, RegexExamples, opções de idioma).

## ★ FastFile 3.0.5.197 (interno) — Layout adaptativo a resolução/DPI (setembro/2026)

- **v3.0.5.197 (interno):** A janela principal, os painéis laterais (Assistente, Script Engine, AI/RAG, Tail) e os diálogos de juntar/dividir passam a caber na área de trabalho e a acompanhar o DPI do Windows (100–200%). O mínimo da janela deixa de ser maior que o ecrã; ao mudar de monitor ou de escala o layout reajusta.

## ★ FastFile 3.0.5.196 (interno) — Python no Assistente + memo da pergunta (setembro/2026)

- **v3.0.5.196 (interno):** O Assistente ganha o botão **Python** junto de Traduzir/Sugerir/Limpar/Copiar (segunda linha se não couber). Abre o Script Engine já existente, que aplica o Python às linhas selecionadas ou marcadas. O memo da pergunta e o contador de caracteres deixam de ficar cortados.

## ★ FastFile 3.0.5.195 (interno) — Filtro vazio = sem filtro (setembro/2026)

- **v3.0.5.195 (interno):** No edit do Filtro/Grep, apagar o padrão (OnChange ou Aplicar com campo vazio) mostra de novo todas as linhas, como o botão **Limpar**.

## ★ FastFile 3.0.5.194 (interno) — Botão Ler (F5) ao lado do MRU (setembro/2026)

- **v3.0.5.194 (interno):** Com `edtFileName` preenchido, aparece à esquerda do MRU um botão que lê o ficheiro (o mesmo que F5). Vazio ou “Select a file …” esconde o botão.

## ★ FastFile 3.0.5.193 (interno) — Motor 100% Unicode (setembro/2026)

- **v3.0.5.193 (interno):** Localizar, filtrar, substituir, editar e as varreduras do Assistente passam a converter o texto no **encoding do ficheiro** (UTF-8 / UTF-16 / UTF-32 / ANSI), sem truncar pela code page do Windows. A vista ganha UTF-32 LE/BE. A versão publicada continua `3.0.5.100`.

## ★ FastFile 3.0.5.192 (interno) — Restaurar visualização original em 11 idiomas (setembro/2026)

- **v3.0.5.192 (interno):** O menu/dica **Restaurar visualização original** passa a ter as 11 línguas da aplicação, com acentos correctos.

## ★ FastFile 3.0.5.191 (interno) — Traduzir/Limpar/Copiar na ListView (setembro/2026)

- **v3.0.5.191 (interno):** A ListView e o modo Select (checkbox) ganham no fundo os botões **Traduzir**, **Limpar** e **Copiar** no mesmo estilo do Assistente, a agir só sobre as linhas selecionadas ou assinaladas.

## ★ FastFile 3.0.5.190 (interno) — Filtro à esquerda + restaurar janela flutuante (setembro/2026)

- **v3.0.5.190 (interno):** O Filtro/Grep deixa de reservar a coluna do título à esquerda. Com o painel encaixado, ↗ e o menu de contexto oferecem **Restaurar janela flutuante** (última posição gravada).

## ★ FastFile 3.0.5.189 (interno) — Dock on só na faixa de origem (setembro/2026)

- **v3.0.5.189 (interno):** Soltar o painel flutuante já não o encaixa só porque está sobre a janela principal. Encaixa só com o cursor na faixa de origem (direita / topo). O primeiro soltar depois de desprender fica onde se largou.

## ★ FastFile 3.0.5.188 (interno) — Dock em qualquer ponto do painel (setembro/2026)

- **v3.0.5.188 (interno):** Arrastar o Filtro/Grep ou o Assistente a partir de qualquer zona do painel (título, fundos, rótulos) desprende; soltar em qualquer ponto da área de origem encaixa. Campos de texto, botões e splitters continuam a receber o clique.

## ★ FastFile 3.0.5.187 (interno) — Assistente dock off sem wrapper (setembro/2026)

- **v3.0.5.187 (interno):** Ao voltar do modo flutuante, o chat encaixa outra vez à direita do form (já não entra no wrapper) e reconstrói o título / pergunta / resposta.

## ★ FastFile 3.0.5.186 (interno) — Sem vazio sob o filtro + assistente ao reencaixar (setembro/2026)

- **v3.0.5.186 (interno):** O Filtro/Grep volta compacto ao encaixar (some o espaço em branco por baixo). O assistente recoloca o título no topo e zera as faixas vazias do wrapper depois do dock on/off.

## ★ FastFile 3.0.5.185 (interno) — Relayout do filtro + dock-on + splitters no wrapper (setembro/2026)

- **v3.0.5.185 (interno):** Ao voltar o Filtro/Grep para o form, o layout é reaplicado e o aviso idle deixa de duplicar o TextHint. Splitters de altura do assistente ficam no wrapper (cima = espaço de cima, baixo = espaço de baixo). Clique no título flutuante já não inicia arrasto imediato — ↙, duplo clique e soltar sobre a janela principal encaixam.

## ★ FastFile 3.0.5.184 (interno) — Borda fina, texto visível, dock-on e splitters (setembro/2026)

- **v3.0.5.184 (interno):** Faixa esquerda do Filtro/Grep mais fina. O texto de ajuda do padrão deixa de ser cortado (`TextHint` no campo). O assistente reencaixa de verdade (já não volta a soltar ao soltar na direita / × / duplo clique). Splitter de cima mexe no espaço de cima; o de baixo mexe no espaço de baixo.

## ★ FastFile 3.0.5.183 (interno) — Altura compacta + grips + dock-on (setembro/2026)

- **v3.0.5.183 (interno):** Filtro/Grep e bloco de pergunta do Assistente ficam mais baixos. Grips no topo e na base redimensionam a altura com o painel encaixado ou flutuante. O assistente reencaixa ao soltar na faixa direita ou com duplo clique no título.

## ★ FastFile 3.0.5.182 (interno) — Arrastar para desprender / encaixar (setembro/2026)

- **v3.0.5.182 (interno):** Arrastar o título do Assistente IA ou do Filtro/Grep desprende o painel; arrastar a janela de volta à borda original (direita / topo) encaixa de novo. A faixa verde indica a zona de encaixe.

## ★ FastFile 3.0.5.181 (interno) — i18n barra + Export dos modais (setembro/2026)

- **v3.0.5.181 (interno):** Merge lines / Split Files / Edit / Select e o botão `&Export...` (Sobre, Splash, histórico) passam a ter HU, PL, RO, CZ e PT-PT. O seed em inglês já não deixa esses rótulos em inglês.

## ★ FastFile 3.0.5.180 (interno) — Splitter de altura + painéis flutuantes (setembro/2026)

- **v3.0.5.180 (interno):** Filtro/Grep ganha splitter de altura. O assistente ganha splitter entre pergunta e resposta. Os dois painéis desprendem para janela flutuante (↗) e encaixam de novo (↙ ou fechar a janela). Posição e tamanho ficam no `ASkin.ini`.

## ★ FastFile 3.0.5.179 (interno) — Chrome do assistente no prompt (setembro/2026)

- **v3.0.5.179 (interno):** O × e o atalho `Ctrl+Alt+A` passam para a linha de «O que deseja fazer?», à direita do texto. O cabeçalho fica só com o título.

## ★ FastFile 3.0.5.178 (interno) — Alerta com contagem 10s (setembro/2026)

- **v3.0.5.178 (interno):** Aviso «Arquivo salvo» (assistente e export do script) ganha contador + barra de 10 s e some sozinho; o × continua a fechar na hora. Mensagens informativas (`ShowAppMessage`, ficheiro/pasta gravados, export concluído) usam o mesmo cartão.

## ★ FastFile 3.0.5.177 (interno) — Overlay ao trocar idioma (setembro/2026)

- **v3.0.5.177 (interno):** Troca de idioma abre o SmoothLoading com progressbar; título e etapas já no idioma novo (sem Cancel).

## ★ FastFile 3.0.5.176 (interno) — Francês: pente fino + acentos (setembro/2026)

- **v3.0.5.176 (interno):** Ao mudar o idioma, a barra de filtro (Contient / saisissez un motif…) e o tempo de leitura passam a ser retraduzidos. Acentos FR via `#nnn` (Édition, Temps de lecture, Détails, etc.).

## ★ FastFile 3.0.5.175 (interno) — Contador 500 sem cortar o texto (setembro/2026)

- **v3.0.5.175 (interno):** O 500 deixa de tapar a última linha (faixa própria sob o texto). Pergunta longa ganha barra de rolagem só quando não cabe — nada fica cortado.

## ★ FastFile 3.0.5.174 (interno) — Acentos do modal ? e chrome do assistente (setembro/2026)

- **v3.0.5.174 (interno):** Modal de formatos: «extensões», «Código-fonte» e equivalentes nos 11 idiomas. Rótulos visíveis (Traduzir/Sugerir/dicas/contador/aviso de arquivo) com a mesma acentuação.

## ★ FastFile 3.0.5.173 (interno) — Contador 500 no campo da pergunta (setembro/2026)

- **v3.0.5.173 (interno):** O 500 sai da barra de ferramentas e fica no canto do campo da pergunta. O `?` volta a ficar depois de Copiar, sem cobrir o botão nem o contador.

## ★ FastFile 3.0.5.172 (interno) — ? e contador 500 sem sobrepor (setembro/2026)

- **v3.0.5.172 (interno):** O `?` deixa o fluxo da esquerda e fica à esquerda do contador, com folga — já não cobre o 500.

## ★ FastFile 3.0.5.171 (interno) — Extensão inválida bloqueia o Enviar (setembro/2026)

- **v3.0.5.171 (interno):** Pedido de formato que o compose não grava (XLSX, etc.) é recusado no **Enviar**: diálogo + exit, sem mandar a pergunta à IA.

## ★ FastFile 3.0.5.170 (interno) — Formatos suportados (? + recusa) (setembro/2026)

- **v3.0.5.170 (interno):** Pedido de extensão que o compose não grava (ex. XLSX) deixa de cair em `.md`: abre um diálogo com os tipos suportados e a resposta no chat. O `?` ao lado de Copiar mostra a mesma lista.

## ★ FastFile 3.0.5.169 (interno) — Compose TXT não vira .md (setembro/2026)

- **v3.0.5.169 (interno):** «Gerar um arquivo em TXT» deixa de gravar `compose_*.md`. O token de formato `txt` / `.txt` escolhe a extensão `.txt` (o `.md` só fica como default quando nenhum formato é pedido).

## ★ FastFile 3.0.5.168 (interno) — Cartão de arquivo + Limpar/Copiar + 500 caracteres (setembro/2026)

- **v3.0.5.168 (interno):** O aviso «arquivo salvo» passa a cartão (faixa verde, ligações e ações na horizontal). Limpar e Copiar ficam na barra do Traduzir/Sugerir, no mesmo formato. O campo da pergunta tem limite de 500 caracteres com contador regressivo (Limpar volta a 500).

## ★ FastFile 3.0.5.167 (interno) — Prefixo + contains na mesma pergunta (setembro/2026)

- **v3.0.5.167 (interno):** «Quantas linhas iniciam com 231556 e quantas têm Bianca (parcial) e o total» deixa de responder só o prefixo. O host corre `count_line_prefixes` e `count_matching_lines` na mesma resposta (agulha estrutural: aspas ou token antes de `(parcial)`).

## ★ FastFile 3.0.5.166 (interno) — Aviso de arquivo salvo no painel (setembro/2026)

- **v3.0.5.166 (interno):** O balão flutuante some. Depois de gerar um ficheiro, o assistente mostra um painel fixo: título, **nome do ficheiro** (clique abre) e **pasta** (clique seleciona no Explorer), mais Abrir / Pasta / Copiar / Validar / Fechar.

## ★ FastFile 3.0.5.165 (interno) — MRU não fecha após o balão (setembro/2026)

- **v3.0.5.165 (interno):** Depois de gerar um ficheiro e clicar no balão, a lista de recentes abria e fechava no mesmo clique. O `ComboBox` nativo e o `Hide` no `MouseDown` do balão deixavam o clique atravessar. A caixa de recentes passa a ser um painel (como o botão MRU de ficheiros); o balão só desaparece no `MouseUp`.

## ★ FastFile 3.0.5.164 (interno) — MRU ancorado no combo (setembro/2026)

- **v3.0.5.164 (interno):** A lista de perguntas recentes deixa de abrir no canto superior esquerdo (`PopupParent` recriava a janela em 0,0). Fica debaixo do combo. Frases com `/` ou um caminho no meio já não são desenhadas como ficheiro (texto colado).

## ★ FastFile 3.0.5.163 (interno) — Balão legível + MRU que fica aberto (setembro/2026)

- **v3.0.5.163 (interno):** O balão «arquivo salvo» mede título e corpo com quebra de linha e abre **abaixo** da faixa (já não corta o texto). O dropdown de perguntas recentes ignora o clique do combo nativo e só fecha com um clique novo fora da lista.

## ★ FastFile 3.0.5.162 (interno) — Balão clicável (não VCL TBalloonHint) (setembro/2026)

- **v3.0.5.162 (interno):** O balão «arquivo salvo» deixa de ser `TBalloonHint` (cliques atravessam). Passa a ser uma janela própria: clique em qualquer sítio fecha; some também aos 10 s.

## ★ FastFile 3.0.5.161 (interno) — Balão «arquivo salvo»: clique fecha (setembro/2026)

- **v3.0.5.161 (interno):** O `TBalloonHint` da VCL devolve `HTTRANSPARENT`, por isso o clique atravessava o balão. Passa a interceptar o clique na janela do balão e fecha-o.

## ★ FastFile 3.0.5.160 (interno) — MRU: independente do balloon / AlphaControls (setembro/2026)

- **v3.0.5.160 (interno):** Clicar no balão «arquivo salvo» voltava a fechar o dropdown de recentes (o controlador AlphaControls trata deactivate/CM_CANCELMODE do balloon como clique fora). A lista MRU passa a `Show` próprio, só fecha com clique fora da janela, Escape ou escolha de item. O balloon é destruído ao clicar ou ao abrir o MRU.

## ★ FastFile 3.0.5.159 (interno) — MRU do chat: não fecha após Enviar (setembro/2026)

- **v3.0.5.159 (interno):** Depois do primeiro Enviar (overlay + hint/balloon «arquivo salvo»), o dropdown de perguntas recentes abria e fechava no mesmo clique. O bloqueio de fecho passa a aplicar-se **depois** do `ShowPopupForm` (quando o AlphaControls já tem o handler), cancela hints/balloon e ignora capture residual.

## ★ FastFile 3.0.5.158 (interno) — MRU: i18n completo nos 11 idiomas (setembro/2026)

- **v3.0.5.158 (interno):** Textos do dropdown MRU (título, procura parcial, limpar, sem resultados, mostrar mais, voltar aos 10, propriedades, remover) passam a ter acentos e formas completas em ES/FR/DE/IT/PL/RO/HU/CZ. Corrigido o typo checo `nedeavne`.

## ★ FastFile 3.0.5.157 (interno) — MRU do chat: remover item (setembro/2026)

- **v3.0.5.157 (interno):** O dropdown de perguntas recentes do Assistente passa a ter o mesmo botão de remover da lista MRU do `edtFileName` (ícone à direita; não apaga ficheiros). A lista e o INI actualizam de imediato.

## ★ FastFile 3.0.5.156 (interno) — Traduzir: Unicode e tradução completa (setembro/2026)

- **v3.0.5.156 (interno):** Romeno→português deixava `și`/`fișierul`/`explicațiile` e virava `?i` / `fi?ierul`. O Traduzir passa a exigir tradução **completa** para o idioma de destino e a decodificar `\uXXXX` em Unicode (letras que não cabem em Latin-1).

## ★ FastFile 3.0.5.155 (interno) — MRU do chat não fecha ao abrir (setembro/2026)

- **v3.0.5.155 (interno):** O dropdown de perguntas recentes do Assistente abria e fechava no mesmo clique (o combo nativo + o popup AlphaControls). Passa a ignorar o clique de abertura até o rato soltar.

## ★ FastFile 3.0.5.154 (interno) — I/O do Assistente = mesmo motor do F5, AI-first (setembro/2026)

- **v3.0.5.154 (interno):** A rapidez deixa de ser um atalho só para «contar linhas». Prefixo, contains e collect usam o leitor binário de 256 KB (como o F5). O total vem do índice do Ler ou do último scan (sem reler). **Sem** teste NL a decidir quando ser rápido.

## ★ FastFile 3.0.5.153 (interno) — Contagem do Assistente tão rápida quanto o Ler/F5 (setembro/2026)

- **v3.0.5.153 (interno):** `count_line_prefixes` / total de linhas do chat deixam de usar `ReadLn` Unicode (uma alocação por linha). Passam a ler o disco em blocos de 256 KB, como o Ler (F5). Perguntas com prefixos digitais não relêem o ficheiro inteiro **antes** de chamar a IA — a passagem local já devolve o total.

## ★ FastFile 3.0.5.152 (interno) — Chat: ficheiro obrigatório antes da IA; Traduzir ≠ Enviar (setembro/2026)

- **v3.0.5.152 (interno):** Se a pergunta é sobre um ficheiro (linhas, PDF, prefixos, «fișierul»/«esse arquivo») e `edtFileName` está vazio (e sem caminho na pergunta), o chat recusa **localmente** com `NoFileOpen` — não envia à IA para depois criticar. **Traduzir** só traduz o texto da pergunta: deixa de disparar Enviar (`Default=False`; Enter no menu de idioma não envia).

## ★ FastFile 3.0.5.151 (interno) — UnConsts: sidecars MRU / logs / Skins (setembro/2026)

- **v3.0.5.151 (interno):** Ficheiros ao lado do EXE que ainda estavam literais (`mru_*.ini`, `Assistant.log`, `icon_help.png`, `Skins`, `logo.bmp`, `ConsumerAI_Session_Debug.log`) passam a constantes em `UnConsts`.

## ★ FastFile 3.0.5.150 (interno) — UnConsts: pastas ConsumerRAG / Build (setembro/2026)

- **v3.0.5.150 (interno):** Nomes de pasta/ficheiro que estavam literais (`data`, `rag_workspace`, `Build`, `data-lake-duckdb-main`, `dist`) passam a constantes em `UnConsts`, no mesmo padrão de `FASTFILE_TEMP_DIR`.

## ★ FastFile 3.0.5.149 (interno) — Chat: caminho na pergunta → edtFileName (setembro/2026)

- **v3.0.5.149 (interno):** Se a pergunta traz um caminho Windows completo, o host valida no disco e, se existir, copia para `edtFileName` (sem Ler ainda). Se o ficheiro não existir, o chat recusa e **não** chama a IA. Sem caminho na pergunta, o ficheiro do campo é o sujeito.

## ★ FastFile 3.0.5.148 (interno) — SmoothLoading visível no Enviar (setembro/2026)

- **v3.0.5.148 (interno):** O overlay do Assistente deixava de se ver: fade de **3,6 s** a partir de alpha **6** (janela e barra “fantasma”). Passa a aparecer **opaco de imediato**, com a barra mais alta e mais contraste.

## ★ FastFile 3.0.5.147 (interno) — Assistente 100% AI-first no Enviar (setembro/2026)

- **v3.0.5.147 (interno):** O chat **Enviar** deixa de interceptar NL (contagem de linhas, validar fonte, «leia o arquivo»). Perguntas compostas em qualquer dos 11 idiomas vão à IA — ex. *explica o ficheiro + quantas linhas + gera um PDF* → `compose_document`, com `lines=N` real no chat e no PDF. O host só completa path, `pdf`/`docx`/`odt`/`rtf`, aspas (nunca o nome `PI121106.txt`) e códigos numéricos. Não troca `compose_document` por contagem de prefixos.

## ★ FastFile 3.0.5.146 (interno) — Assistente: comandos iguais nos 11 idiomas (setembro/2026)

- **v3.0.5.146 (interno):** Pedido composto em romeno (`7157414` + total de linhas + PDF) deixava de ir à IA: o host via só `cate linii` (padrão PT) e respondia a contagem. `pdf`/`docx` e códigos numéricos longos passam a ser sinais **estruturais** (qualquer idioma da app), sem exigir «gera um PDF».

## ★ FastFile 3.0.5.145 (interno) — MRU: some se o ficheiro já não existe (setembro/2026)

- **v3.0.5.145 (interno):** Se o item dos recentes já não existe no disco, **propriedades** e **abrir/Ler** avisam e **removem só da lista MRU** (não apagam nada). O dropdown actualiza na hora.

## ★ FastFile 3.0.5.144 (interno) — MRU: glifos com tamanho fixo (setembro/2026)

- **v3.0.5.144 (interno):** Ícones do dropdown MRU deixam de usar `TsCharImageList.Draw` (bitmap maior na 1ª pintura, menor no hover). Passam a ser desenhados em caixa fixa `16px` (escalada) com FontAwesome + clip.

## ★ FastFile 3.0.5.143 (interno) — MRU: ícones estáveis e propriedades sem fechar (setembro/2026)

- **v3.0.5.143 (interno):** Ícones de propriedades/remover no dropdown MRU deixam de mudar de tamanho no hover. Clicar em **propriedades** mantém a lista aberta enquanto o diálogo do Windows está visível.

## ★ FastFile 3.0.5.142 (interno) — MRU edtFileName: propriedades e remover (setembro/2026)

- **v3.0.5.142 (interno):** No dropdown de ficheiros recentes (`edtFileName`), cada linha ganha dois ícones à direita: **propriedades** (diálogo do Windows do próprio ficheiro) e **remover da lista** (só o MRU / `mru_files.ini`, **não** apaga do disco). Filtro e perguntas do Assistente não mudam.

## ★ FastFile 3.0.5.141 (interno) — Massa Q1–20: mesmo erro «leia primeiro» (setembro/2026)

- **v3.0.5.141 (interno):** Pente fino **AI-first** (sem mapa Q1–20). `find_text` / `goto_line` / `apply_filter` partilham auto-Read se `edtFileName` tem path e o stream ainda não existe. Contagem de prefixos corre no disco (não precisa de Ler). Se a pergunta pede o total de linhas e o índice ainda é 0, conta LF no ficheiro. `salva em Word` é id de formato (como `pdf`), não o substantivo *word*. O resultado de `count_line_prefixes` inclui sempre o N do scan. PDF de filtro continua sem despejar metadados.

## ★ FastFile 3.0.5.140 (interno) — Filtro+PDF: auto-Ler e linhas reais (setembro/2026)

- **v3.0.5.140 (interno):** `apply_filter` com caminho em `edtFileName` deixa de pedir «Leia o arquivo primeiro» — faz o Read e aplica o filtro depois. O PDF de filtro+resumo **não** duplica criação/modificação/tamanho; o corpo é o resumo pedido e até 100 linhas que contêm o texto (scan em disco se o índice ainda não estiver pronto). `no máximo 100 registros` preenche `max_lines`.

## ★ FastFile 3.0.5.139 (interno) — Validar fonte: frases PT + diálogo filtrado (setembro/2026)

- **v3.0.5.139 (interno):** Chat *«quais linguagens que a aplicação valida?»* reconhecido (token `valida` sem espaço). *recarregar o/algum fonte* abre o diálogo. Filtro do OpenDialog **sem** `*.*` — só `.py/.js/.jsx/.ts/.tsx/.mjs/.cjs`; extensão recusada continua a listar as linguagens. `TryCatalogResolveAction` mapeia `validate_source`.

## ★ FastFile 3.0.5.138 (interno) — Assistente Enviar: progresso real no SmoothLoading (setembro/2026)

- **v3.0.5.138 (interno):** Ao clicar **Enviar**, a barra do overlay deixa de ir 0→100 em loop (marquee). Passa a **determinate**: fases WinInet (ligar / enviar / esperar modelo / receber), creep lento até 78% enquanto o modelo pensa (nunca volta a 0), e percentagem real no scan de ficheiro (`count_*`). `UpdateAssistantWait` já não reinicia a barra.

## ★ FastFile 3.0.5.136–137 (interno) — Validar fonte no Assistente (setembro/2026)

Documento: [`DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md) · atalhos [`DOC_ZS_ATALHOS.md`](DOC_ZS_ATALHOS.md) §18.

- **v3.0.5.136 (interno):** Botão **Validar** após compose; `.py` via `ScriptEngine.exe --validate`; `.js`/`.jsx`/`.ts`/`.tsx`/`.mjs`/`.cjs` via `CodeCheck.exe`; URLs em `UnConsts`; timeout `CODECHECK_VALIDATE_TIMEOUT_MS`.
- **v3.0.5.137 (interno):** Chat `validate_source` / *carregar o fonte pra validar* (diálogo filtrado); gate `VALIDATABLE_SOURCE_EXTS` **antes** do companion; resposta *quais linguagens valida?*; i18n `Assistant.Validate.SupportedLanguages` (+ NeedPath / PickTitle / Cancelled); prompt regra **8v**.

| Pedido | Resultado esperado |
|--------|-------------------|
| Validar após gerar `.py` / `.tsx` | Relatório OK ou ERROR:linha |
| `carregar o fonte pra validar` | OpenDialog → sintaxe |
| Extensão não suportada | Lista Python/JS/JSX/TS/TSX |

**Deploy:** republicar `ScriptEngine.exe` (com `--validate`) e `CodeCheck.exe` no FTP `fastfile_executables/`.

---

## ★ FastFile 3.0.5.100 — FilterBar dockada, toggles na status bar, chrome do assistente e count_matching (setembro/2026)

### Versão publicada
- **v3.0.5.100 (Current / Atual — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.100`**. **Ctrl+L** abre **FilterBar** dockada (combo de padrão, Aplicar/Continuar/Limpar/Ocultar, faixa peek, MRU dos últimos **20** filtros em `ASkin.ini` `[FilterRecentPatterns]`). Clique na status bar em **Mode/Wrap/Tail/Filter/Marks/View** faz toggle. **Assistente IA:** chrome suave, `TsPanel` + `SkinData.CustomColor`, tool **`count_matching_lines`** (contagem local contains/parcial, AI-first). Galeria **Mais ferramentas:** fundo azul suave em gradiente; pesquisa/ESC polidos. Sync de docs interno **.101**.

### Versões internas (diluídas, sem duplicar 3.0.5.0)
- **v3.0.5.91 (interno):** Assistente — UI remodelada (accent, header, limpar pergunta, Segoe UI; ESC limpa pergunta antes de fechar).
- **v3.0.5.92 (interno):** **`count_matching_lines`** AI-first — contagem contains/parcial local (evita ConsumerAI 500); IA escolhe a tool + `filter_text`.
- **v3.0.5.93 (interno):** Status bar Mode/Wrap/Tail/Filter/Marks/View — clique do rato faz toggle.
- **v3.0.5.94 (interno):** Assistente — superfície, accent, cards com borda suave, tipografia, badge de atalho, botões/status coloridos.
- **v3.0.5.95 (interno):** Assistente — `TsPanel` + `CustomColor` (AlphaSkins); accent 8 px e header contrastante.
- **v3.0.5.96 (interno):** Filtro/Grep (Ctrl+L) — barra dockada (Edit da string, Aplicar/Continuar/Limpar/Ocultar, peek, status de hits).
- **v3.0.5.97 (interno):** FilterBar — `BuildChrome` só após `Parent` (evita `EInvalidOperation` no Ctrl+L).
- **v3.0.5.98 (interno):** FilterBar — status em linha completa; i18n 11 idiomas (acentos `#nnn`).
- **v3.0.5.99 (interno):** FilterBar — dropdown MRU últimos 20 (`ASkin.ini`); i18n `FilterBar.Recent*` 11 idiomas.
- **v3.0.5.100 (interno):** Mais ferramentas — itens com gradiente azul suave (`$00E8F4FF`); FilterBar.Recent* confirmado.
- **v3.0.5.101 (interno):** Docs sync — `APPLICATION_VERSION` 3.0.5.100, CHANGELOG/README/ROADMAP/`DOC_ZS_ATALHOS`/`DOCUMENTACAO_MODELOS_IA`, F1 Filter+Assistant, i18n linha Ctrl+L.

### Como usar
| Item | Detalhe |
|------|---------|
| Filtro / Grep | **Ctrl+L** — FilterBar dockada; combo MRU; Aplicar / Continuar / Limpar / Ocultar |
| Status bar | Clique em Mode, Wrap, Tail, Filter, Marks ou View para alternar |
| Contar ocorrências | Assistente: «quantas linhas contêm X» → `count_matching_lines` (local) |
| Mais ferramentas | Itens com fundo azul suave; pesquisa e ESC melhorados |

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **3.0.5.91–101** / publicada **3.0.5.100**; **compose / trava / `fastfile_assistant`** permanecem na secção **3.0.5.0** seguinte.

---

## ★ FastFile 3.0.5.0 — Assistente IA: compose (docs/código), Clear/Copy, trava de segurança e pasta `fastfile_assistant` (agosto/2026)

### Versão publicada
- **v3.0.5.0 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.0`**. O **Assistente IA** (Ctrl+Alt+A) passa a **gerar ficheiros** (compose): resumo → Word/RTF/DOCX/ODT/PDF; código em várias linguagens (Python, JS/TS/React, Go, Java, C++, C#, …); classificador de intenção + mapa de capacidades com *anti-phrases* (resumo Word ≠ RAG; gerar `.py` ≠ Script Engine). Saída em **`fastfile_assistant\`** (não misturar com `fastfile_temp`). Botões **Limpar** / **Copiar** na resposta; mensagem de gravação só com caminho completo + linha em branco antes do tempo IA. **Trava de segurança:** recusa vírus/malware/formatar disco/shell do SO; bloqueia gravação de `.exe`/`.bat`/`.vbs`/etc.

### Versões internas (diluídas, sem duplicar 3.0.4.x)
- **v3.0.5.1 (interno):** **`compose_document`** — pipeline resumo→RTF; **`uFastFileAssistantIntent`**, Catalog (`UserWantsComposeSourceCode` / Word/PDF/ODT), Map ingest + anti-phrases; gateway JSON `resposta` (`uFastFileAIClient`).
- **v3.0.5.2 (interno):** **`uFastFileComposeExport.pas`** — RTF/DOCX/ODT/PDF; **`FASTFILE_ASSISTANT_OUT_DIR`** / `FastFileAssistantOutPath`; extensões multi-linguagem em `GuessComposeExtension`.
- **v3.0.5.3 (interno):** UI **Limpar** / **Copiar** (`LayoutInputControls`); **`ComposeSavedDetail`** só caminho; **`BuildReplyWithTiming`** com linha em branco antes do elapsed.
- **v3.0.5.4 (interno):** **`UserQuestionIsOutOfScopeOrHarmful`** alargado; **`IsForbiddenComposeExtension`**; prompts de compose recusam malware.
- **v3.0.5.5 (interno):** F1 **`FF_HELP.AssistantBlock`**; i18n **11 idiomas**; Version History + README + ROADMAP + `DOC_ZS_ATALHOS.md` + `DOCUMENTACAO_MODELOS_IA.md`.

### Internacionalização (11 idiomas)
- UI assistente: Limpar/Copiar, estados clipboard, compose salvo, trava de segurança, abrir em Word/PDF.
- F1: bloco Assistente actualizado (compose, pasta `fastfile_assistant`, segurança).
- Version History (`miVersionHistoryClick`) actualizado.

### Como usar
| Item | Detalhe |
|------|---------|
| Assistente IA | **Ctrl+Alt+A** — perguntar em linguagem natural |
| Resumo → documento | Ex.: «resumo … formato word / .docx / .pdf / .odt» |
| Gerar código | Ex.: «gere uma classe em Java…» → ficheiro em `fastfile_assistant\` |
| Limpar / Copiar | Botões entre Enviar e Executar ação |
| Segurança | Pedidos de vírus/formatar disco/shell são bloqueados |

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **3.0.5.x**; **3.0.4.0** e trilhos **3.0.4.1–6** permanecem na secção seguinte.

---

## ★ FastFile 3.0.4.0 — Chat IA avançado (arquivo) em GB+, scroll dos chats e correção de acentuação (julho/2026)

### Versão publicada
- **v3.0.4.0 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.4.0`**. **Chat IA avançado (arquivo)** (Ctrl+Alt+R) abre ficheiros de qualquer tamanho rapidamente — **`ConsumerRAG.py`** usa por predefinição **FastTextRAG** (busca lexical em streaming, sem embeddings antecipados), pelo que um **TXT de 3,6 GB** abre depressa; indexação semântica completa passa a ser **opcional** (`--semantic-index`). **Cancelar carga** / **Fechar** deixam de bloquear a UI. **Comparar/Mesclar** e histórico de sessão corrigem *mojibake* (acentuação). A **roda do rato** sobre qualquer painel de chat IA rola o próprio histórico. **Ler** (Ctrl+1) com ficheiro já aberto abre o seletor e carrega o novo ficheiro. Botão **Sobre** da barra encurtado (`titlebar.about`, 11 idiomas).

### Versões internas (diluídas, sem duplicar 3.0.3.x)
- **v3.0.4.1 (interno):** **`data-lake-duckdb-main/ConsumerRAG.py`** — **FastTextRAG** como modo predefinido (streaming lexical, sem embeddings imediatos); imports pesados (lancedb/numpy) preguiçosos; parâmetros de chunk/overlap/max-chunks e *overview budget*; lançamento a partir do Delphi deixa de forçar `--semantic-index`/`--keep-workspace`; progresso `%`/ETA na bridge; **`smoke_test_consumer_rag_exe.py`** timeout **300 s** (extração onefile a frio); correcções de empacotamento PyInstaller (`build_exe_consumer_rag.bat`).
- **v3.0.4.2 (interno):** **`MainUnit.pas`** — **`StopConsumerRAGProcess`** não bloqueante (`TerminateProcess` imediato, fecho de pipes, `WaitForSingleObject` 750 ms na thread leitora, liberta objecto se preso); **`ConsumerRAGCloseClick`** oculta o painel primeiro; **`ConsumerRAGCancelClick`** protege excepções em `StopConsumerRAGProcess` / `PurgeConsumerRAGTempData` e desactiva o botão; `FConsumerRAGCloseButton`/`FConsumerRAGCancelButton` `BringToFront`; `FConsumerRAGTitleLabel.Enabled := False` (não intercepta cliques).
- **v3.0.4.3 (interno):** **`uTextEncoding.pas`** — `RawBytesToDisplayString`, `DetectTextEncodingFromBytes`, `DetectTextFileEncoding`; **`uCompareMergeUI.pas`** — `ReadTextFileLineSlice` lê bytes como `AnsiString` (`SetString(seg, PAnsiChar(@Buf[AStart]), ALen)`), detecta encoding + salta BOM e converte para exibição (`DisplayTextFromFileBytes`); `ScanSessionJournalStream`/`StreamJournalTailLinesIntoList` usam `RawBytesToDisplayString`; **`uFileSessionHistory.pas`** — `FFAppendRawLine` escreve journal em **UTF-8** (`UTF8Encode`).
- **v3.0.4.4 (interno):** **`ActionReadFileExecute`** — com ficheiro carregado abre `TOpenDialog` e carrega de imediato (`DoShowPanelReadFile` + `DoRead`); **`HwndInSideChatPanels`**, **`PointInSideChatPanels`**, **`TryScrollSideChatWheel`**; **`FormMouseWheel`** e **`ScriptMemoAppMessage`** encaminham `WM_MOUSEWHEEL` para o memo do chat sob o rato (RAG/SQL/Assistente/Script) antes de scroll/zoom da ListView; `btnSplash.Caption := Tr('titlebar.about', 'About')` (+ `MainUnit.dfm`).
- **v3.0.4.5 (interno):** F1 **`FF_HELP.AIChatFileBlock`**; i18n **11 idiomas** (`Open file`, `titlebar.about` já existente, `Cancel loading`/`Loading cancelled`/`Cancelled`/`Temporary RAG index cleared`, `AI Chat (SQL)`/`Advanced AI Chat (file)`); Version History + README + ROADMAP + `DOC_ZS_ATALHOS.md` + `DOCUMENTACAO_MODELOS_IA.md`.
- **v3.0.4.6 (interno):** **Script Engine** — Run Script respeita seleção da ListView (não força o ficheiro inteiro após filtro); diálogo **todas vs selecionadas** (só quando há seleção) + confirmação com contagem (`SCRIPT_ENGINE_SCOPE_PROMPT` / `CONFIRM_SEL` / `CONFIRM_ALL`, 11 idiomas); **Cancelar** no overlay chama `AbortScriptEngineRunOnCancel` (`TerminateProcess` + limpeza diferida `WM_USER+438`).

### Internacionalização (11 idiomas)
- F1: bloco **`FF_HELP.AIChatFileBlock`** (Chat IA avançado em GB+, cancelar/fechar sem travar, scroll dos chats, Ler abre seletor, acentuação em comparar/mesclar).
- UI: **`Open file`** (título do diálogo de Ler) traduzido; strings de cancelar/fechar RAG e nomes de menu Chat IA já cobertos.
- Version History (`miVersionHistoryClick`) actualizado.

### Como usar
| Item | Detalhe |
|------|---------|
| Chat IA avançado (arquivo) | **Ctrl+Alt+R** — perguntas sobre o ficheiro aberto; abre rápido mesmo em GB+ |
| Ficheiros grandes | FastTextRAG (streaming) por defeito; `--semantic-index` só quando quiser embeddings |
| Cancelar/Fechar | Painel oculta na hora; plugin parado em segundo plano |
| Scroll do chat | Roda (ou Ctrl+roda) sobre o painel de chat rola o histórico, não a lista |
| Ler (Ctrl+1) | Com ficheiro aberto, abre o seletor e carrega o escolhido |

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **3.0.4.x**; **3.0.3.0** e trilhos **3.0.3.1–5** permanecem na secção seguinte.

---

## ★ FastFile 3.0.3.0 — Host Win64, scan SWAR rápido e log de tempo (junho/2026)

### Versão publicada
- **v3.0.3.0 (Current / Atual — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.3.0`**. Port **Delphi 10.4.2 Win64** (`Build\Win64\FastFile.exe`) em paralelo com Win32; saída por plataforma + cópia `Skins\`; **log de operações** (canto superior direito) fiável no Win64 (`TListBox` + `AppendOperationTimerLog`); indexação **SWAR** (8 bytes; wide 32 bytes com AVX2) via **`uLineIndexScan.pas`**; barra de progresso **suave ~22 Hz** em leituras rápidas; scan paralelo com part-files **desligado** (`LINE_INDEX_PARALLEL_ENABLED=False`) após regressão em índice esparso (>2 GB).

### Versões internas (diluídas, sem duplicar 3.0.2.x)
- **v3.0.3.1 (interno):** **`FastFile.dproj`** / **`FastFile.dpr`** — plataforma Win64; `INVALID_HANDLE_VALUE`, mutex single-instance por arquitectura; `compile_verify_win64.bat`; `uSmoothLoading` ponteiro Win64 em scan.
- **v3.0.3.2 (interno):** build **Win32 → `Build\Win32\`**, **Win64 → `Build\Win64\`**; pre/post-build copia `Skins\` para pasta da plataforma.
- **v3.0.3.3 (interno):** **`MainUnit`** — `pnlTimerLog` + `TListBox` (substitui `TsMemo` AlphaControls no Win64); `AppendOperationTimerLog` centraliza escrita; log ao fim de `finishFileNameRead`.
- **v3.0.3.4 (interno):** **`uLineIndexScan.pas`** — `ScanBufferForLineFeeds` SWAR/wide; `TryParallelLineIndexScan` mantido mas desactivado; loop sequencial inline `ScanCardinalAt` em `TReadFileThread`.
- **v3.0.3.5 (interno):** **`PostReadProgress`** — throttle ~45 ms / catch-up permille; F1 **`FF_HELP.Win64IndexBlock`**; i18n **11 idiomas**; Version History + README + ROADMAP + `DOC_ZS_ATALHOS.md` + `DOCUMENTACAO_MODELOS_IA.md`.

### Internacionalização (11 idiomas)
- F1: bloco **`FF_HELP.Win64IndexBlock`** (host Win64, indexação SWAR, log de tempo, progresso suave).
- Version History (`miVersionHistoryClick`) actualizado.

### Como usar
| Item | Detalhe |
|------|---------|
| Build Win64 | Delphi 10.4 Sydney: `msbuild FastFile.dproj /p:Platform=Win64` ou `compile_verify_win64.bat` |
| Ler ficheiro (F5) | Scan SWAR rápido; ficheiros >2 GB só `temp_ckpt.txt` |
| Log de tempo | Canto superior direito — histórico de operações com duração |
| Progresso | Barra animada suave durante indexação (não salta em blocos de 8 MB) |

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **3.0.3.x**; **3.0.2.0** e trilhos **3.0.2.1–3** permanecem na secção seguinte.

---

## ★ FastFile 3.0.2.0 — Workspace vazio (logo) e seleção vertical em bloco (junho/2026)

### Versão publicada
- **v3.0.2.0 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.2.0`**. **Workspace vazio** com gradiente azul, logo FastFile + watermark em alta resolução (PNG 1200 px), textos centralizados, posição estável ao abrir/fechar assistente IA; **seleção vertical em bloco** (Ctrl/Alt+arrastar na coluna 2) mantém a largura escolhida ao soltar o rato — **F11** estende até ao fim da coluna só quando premido; i18n **11 idiomas** + F1 + docs.

### Versões internas (diluídas, sem duplicar 3.0.1.x)
- **v3.0.2.1 (interno):** **`MainUnit.pas`** — `IdleLogoBgFloat`, `PaintIdleLogoContent`, `ResolveBestIdleLogoPngPath` (escolhe maior PNG entre Build/Images), upscale Lanczos + cache `FIdleLogoPaintCache`, blend sem Mitchell 1:1, `IDLE_LOGO_PROCESS_REV` 30; PNG **`color1_icon_transparent_background.png`** 1200×867 em `Build\`.
- **v3.0.2.2 (interno):** correcção **regressão seleção vertical** — removido `ExpandColumnBlockSelectionToContentWidth` de `ListView1MouseUp`, `CheckListBox1MouseUp` e `SyncCheckListLayoutAfterSelectMode`; F11 mantém extensão opcional.
- **v3.0.2.3 (interno):** i18n **`FF_HELP.ReadPanelBlock`**, **`FF_HELP.IdleWorkspaceBlock`**; ajuda F1; **`DOC_IDLE_LOGO_WORKSPACE.md`**; sync README / ROADMAP / `DOC_ZS_ATALHOS.md` / `DOCUMENTACAO_MODELOS_IA.md`.

### Internacionalização (11 idiomas)
- F1: blocos **Read panel block/autofill** e **Idle workspace brand**.
- Version History (`miVersionHistoryClick`) actualizado.

### Como usar
| Item | Detalhe |
|------|---------|
| Workspace vazio | Abrir FastFile sem abas visíveis — logo + watermark + textos |
| Bloco vertical | Coluna conteúdo: **Ctrl** ou **Alt** + arrastar; **Ctrl+C** copia |
| Estender bloco | Com bloco activo: **F11** até largura total; sem bloco: **F11** = ecrã completo |
| Autofill | Coluna **Linha #**: arrastar para baixo (sem Ctrl/Alt) |

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **3.0.2.x**; **3.0.1.0** e trilhos **3.0.1.1–5** permanecem na secção seguinte.

---

## ★ FastFile 3.0.1.0 — Assistente (lista recentes), download de EXEs e Chat com IA (junho/2026)

### Versão publicada
- **v3.0.1.0 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.1.0`**. Comandos do assistente para **abrir o N.º ficheiro da lista de recentes** (`open_recent_file`, `recent_index`); correção de download automático de **ConsumerAI.exe**, **ConsumerRAG.exe** e **ScriptEngine.exe**; renomeação de UI **Chat com IA** / **Chat Avançado com IA** (11 idiomas); painéis Chat aceitam ficheiro aberto com sufixo `[READ ONLY]`; painel do assistente com **MemoReply** restaurado.

### Versões internas (diluídas, sem duplicar 3.0.0.x)
- **v3.0.1.1 (interno):** **`uFastFileAssistantCatalog.pas`** / **`uFastFileAssistant.pas`** — `ExtractRecentListIndexFromText`, `UserQuestionRefersToRecentFilesList`, `ApplyLocalIntentCorrection`; **`MainUnit`**: `AssistantCbGetRecentFilePathByListIndex`, `AssistantCbOpenRecentFileByIndex`, `open_recent_file` em `AssistantCbExecuteAction`; contexto `recent_N` em `AssistantCbGetContext`.
- **v3.0.1.2 (interno):** **`uFastFileExternalExe.pas`** — cookie PyInstaller corrigido (`MEI` + bytes binários); `IsValidDownloadedCompanionExe` (PyInstaller ou PE ≥ 4 MB); **`MainUnit.DownloadExecutableDirect`** — timeouts 1 h, erros WinInet explícitos, 3.ª tentativa **URLMon** (`URLDownloadToFile`).
- **v3.0.1.3 (interno):** i18n — menus **AI Chat** / **Advanced AI Chat** (11 langs); mensagens RAG/Chat, ajuda F1 (`Help shortcut:*`, `FF_HELP.AssistantBlock`); **`DOC_ZS_ATALHOS.md`**; remoção de sufixos `(C)`/`(A)` nos títulos de menu.
- **v3.0.1.4 (interno):** **`ResolveConsumerSourceFilePath`** — `CurrentEffectiveFilePath` + `fFileName` para iniciar Chat com IA / Chat Avançado sem falso “ficheiro inválido”.
- **v3.0.1.5 (interno):** **`uFastFileAssistant.pas`** — `MemoReply`, `PnlReply`, `ApplyAssistantSoftChrome`, `RefreshFastFileAssistantSurface`; **`Assistant.Error.RecentListOutOfRange`** (11 langs).

### Internacionalização (11 idiomas)
- `AI Chat`, `Advanced AI Chat`, títulos de painel com atalhos, mensagens de download/erro de motor, lista recentes fora de intervalo, bloco F1 do assistente actualizado.

### Como usar
| Item | Detalhe |
|------|---------|
| Assistente | Ex.: «quero ler o terceiro arquivo da lista» → abre a 3.ª linha de **Arquivos recentes** |
| Menu IA | **Chat com IA** (Ctrl+Shift+A), **Chat Avançado com IA** (Ctrl+Alt+R) |
| Download | EXEs em `hvogel.com.br/fastfile_executables/`; log em `Build\FastFile_Download.log` |

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **3.0.1.x**; o marco **3.0.0.0** e trilhos **3.0.0.1–7** permanecem na secção seguinte.

---

## ★ FastFile 3.0.0.0 — Marco de versão 3.0 (maio/2026)

### Versão publicada
- **v3.0.0.0 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`3.0.0.0`**. **Chegámos finalmente à versão 3.0** — consolidação do produto: assistente IA operacional maduro (comandos locais + gateway), reorganização do menu **Ferramentas/Sessão/Opções**, ferramentas **EmEditor** em ficheiros GB+, paridade **Zero Scan**, i18n **11 idiomas**, constantes de ficheiros temporários centralizadas.

### Versões internas (diluídas, sem duplicar o histórico 2.1.7.x)
- **v3.0.0.1 (interno):** **`uFastFilePaths.pas`** — caminhos `TEMPFILE`, `TEMP_CKPT_FILE`, `temp_filter_hits.bin`, scratch edit/merge junto ao EXE; **`UnConsts`** documenta nomes; correcção **`SysUtils.FindClose`** vs `Windows.FindClose`.
- **v3.0.0.2 (interno):** **`uFastFileAssistant.pas`** / **`uFastFileAssistantCatalog.pas`** — plano local alargado: filtrar+exportar, substituir tudo, dividir partes iguais, extrair 1/N, exportar intervalo ou linhas com texto; erros visíveis em **`TryHandleLocalSendQuery`** (sem falha silenciosa).
- **v3.0.0.3 (interno):** apagar linha com **filtro activo** — **`AssistantCbDeletePhysicalLine`** (linha física); **`uSmoothLoading`**: refresco da ListView após edição mesmo com **`FQuietFinish`**.
- **v3.0.0.4 (interno):** exportar filtrado / correspondências — thread para conjuntos grandes; preferência exportar para **.txt**; limites de área de transferência.
- **v3.0.0.5 (interno):** i18n assistente — mensagens locais, popup colar linhas, apagar linha, exportar/substituir/dividir (**`Set11`**, 11 idiomas, acentuação).
- **v3.0.0.6 (interno):** atalhos no painel do assistente — paridade com painel Read (**Ctrl+H/L/F**, **Ctrl+Shift+L/Q**, **Ctrl+Z/Y** desfazer ficheiro, **Ctrl+C/V**); bloco **F1** **`FF_HELP.AssistantBlock`** actualizado (v3.0).
- **v3.0.0.7 (interno):** merge do trilho **v2.1.7.29–31** (menu, **`uEmEditorFeatures`**, whitelist +12 acções do assistente) — detalhes mantidos nas secções **2.1.7.29/30/31** abaixo, não repetidos aqui linha a linha.

### Internacionalização (11 idiomas)
- Ajuda F1: **`FF_HELP.AssistantBlock`** (v3.0, atalhos com foco no assistente).
- Assistente: **`Assistant.Local.*`**, **`Assistant.Status.*`**, **`Assistant.Popup.PasteLinesFile`**, erros de validação local.

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas o salto **3.0** e trilhos **3.0.0.1–7**; o conteúdo equivalente já descrito em **v2.1.7.29–31** permanece nas secções seguintes como histórico pré-3.0.

### Como usar (Assistente v3.0)
| Item | Detalhe |
|------|---------|
| Menu | **IA → Assistente FastFile...** |
| Texto | Ex.: «filtrar linhas com X e exportar para txt», «substituir tudo A por B», «apagar última linha», «dividir em 3 partes» |
| Atalhos | Com foco no painel do assistente: mesmos atalhos do Read (**Ctrl+H**, **Ctrl+L**, **Ctrl+Shift+L**, **Ctrl+Z/Y**, etc.) |
| Versão | **Ajuda → Histórico de versões** destaca **VERSION 3.0** |

---

## Atualização incremental — Assistente: mais ações na whitelist (maio/2026) — trilho 2.1.7.31 (pré-3.0)

### Versão publicada
- **v2.1.7.31 (Anterior — incorporado em 3.0.0.0):** assistente com **+12 ações**: filtro (`open_filter`, `apply_filter`, `clear_filter`), exportar, deduplicar linhas, strings frequentes, checkboxes, ir para linha, código do caractere, abas merge, word wrap; parâmetros `filter_text`, `line_no`; contexto `lines=` / `filter_active=` / `tail_active=`.

---

## Atualização incremental — Assistente IA operacional Fases 2–4 (maio/2026)

### Versão publicada
- **v2.1.7.30 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.30`**; assistente **AI → Assistente FastFile** com JSON `explain`/`execute`/`unknown`, cadeias `actions[]` (ex.: abrir ficheiro e dividir em N partes após fim da leitura), acções adicionais (substituir, tail, comparar, extrair subset de partes), RAG leve por tópicos F1 (`uFastFileAssistantRAG.pas`), log opcional `Assistant.log` (`AssistantLog=1`), i18n 11 idiomas, secção F1 e Version History.

### Como usar
| Item | Detalhe |
|------|---------|
| Menu | **AI → Assistente FastFile...** |
| Arranque | `AssistantShowOnStartup=1` em `ASkin.ini` (predefinido) |
| Log | `AssistantLog=1` na secção `[FastFile]` |
| Testes | `DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md` |

---

## Atualização incremental — Reorganização do menu, ferramentas EmEditor e análise GB+ (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.29 (Current / Atual — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.29`**; **`MainUnit.pas`**: barra de menus reorganizada — **Ferramentas** (Filtro/análise, Dividir/mesclar, Linhas, Tail, Automação, Exportar/limpar), **Sessão** (somente leitura, gravar/carregar sessão), **Opções** reduzido (apenas desempenho / ops. segmentadas); **`RebuildMainMenu`** + ícones; **`uI18n.AddCommonTranslationsMainMenuReorg`** (11 idiomas, acentuação corrigida).
- **v2.1.7.30 (interno):** **`uEmEditorFeatures.pas`** + **`FastFile.dpr`**: **Valor do código do caractere** (menu Visualizar); **Extrair strings frequentes** e **Excluir linhas duplicadas** (Ferramentas › Filtro e análise); diálogos e handlers em **`MainUnit`**.
- **v2.1.7.31 (interno):** desempenho em ficheiros **20–50 GB** sem congelar a UI — varredura **MMF** (`ScanFileLinesMMF`, buffer 8 MB); frequências com **buckets** + spill (> 8 MB); deduplicação com **`TDiskKeySet`** (hash encadeado em disco, offsets **Int64**); thread **`TEmEditorStatsThread`**; barra de progresso com **GB | MB/s | ~ETA** (~120 ms).
- **v2.1.7.32 (interno):** **`ConfirmDiskSpaceForPaths`** antes de reescrever ficheiro (dedup); **`AddCommonTranslationsEmEditorFeatures`** + bloco **F1** **`FF_HELP.EmEditorBlock`**; atalhos de menu **Alt+F,E,V,T,S,O** (11 idiomas); versão **F1** usa **`APPLICATION_VERSION`**.

### Internacionalização (11 idiomas)
- Menu: `Menu.Tools`, `Menu.Tools.*`, `Menu.Session`, `Menu.Options.Performance`.
- EmEditor: `Character Code Value...`, `Extract Frequent Strings...`, `Delete Duplicate Lines...`, `CharCode.*`, `EmEditor.*` (progresso, modos CSV, dedup, mensagens).
- Ajuda F1: `FF_HELP.EmEditorBlock`; texto da barra de menus actualizado (Tools / Session).

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.29**–**.32**; Zero Scan / extrair partes **v2.1.7.25**–**.28** permanecem abaixo.

### Como usar (Ferramentas › Filtro e análise)
| Acção | Resultado |
|--------|-----------|
| **Visualizar › Valor do código do caractere** | Unicode U+, decimal, UTF-8 e offset na linha seleccionada (sem scan do ficheiro) |
| **Extrair strings frequentes** | Gera CSV `string,count`; modos linha/palavra/célula CSV; progresso em ficheiros GB+ |
| **Excluir linhas duplicadas** | Mantém a 1.ª ocorrência; chave linha inteira ou coluna CSV; confirma espaço em disco |

---

## Atualização incremental — Zero Scan (atalhos), extrair partes e última linha (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.25 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.25`**; **`MainUnit.pas`**: portabilidade **Zero Scan** sem índice denso — **Ctrl+G** linha física (`GotoPhysicalLine1Based`); **Ctrl+F/H** sem bloqueio de índice no arranque; **Replace All** em streaming; delete em lote via MMF; secção **F1** Zero Scan; regressão quando existe `temp.txt` (`UsesProportionalZeroScanScroll` = false). Documentação: **`DOC_ZS_ATALHOS.md`**, checklist **`DOC_ZERO_SCAN_CHECKLIST_TESTES.md`**.
- **v2.1.7.26 (interno):** ao sair da aplicação remove **`temp.txt`** + **`temp_ckpt.txt`** (`CleanupFastFileLineIndexFiles` em `FormClose` / `ShutdownApplicationWork`); constante **`TEMP_CKPT_FILE`** em **`UnConsts.pas`**.
- **v2.1.7.27 (interno):** **Extrair partes do arquivo** (**Ctrl+Shift+Q**, antes “fração”) — menu/aba/diálogo nos **11 idiomas**; ficheiros `basename.parte_1_de_8.ext` (`SplitFilePart.FilenamePart` / `FilenameOf`); diálogo de sucesso com scroll (`ShowSplitExportResultDialog`); **Zero Scan** passa contagem física à thread; **`RestoreViewAfterSplitExport`** + **`ReopenFileStreamsOnly`** repõe ListView após exportar com ficheiro aberto.
- **v2.1.7.28 (interno):** **Shift+End** em Zero Scan — **`DiscoverZeroScanLastPhysicalLine1Based`**: sonda regressiva na lista proporcional + **`TZeroScanDiscoverLastLineThread`** (`FastFileCountLinesLf` com progresso para ficheiros **> 256 MB**, ex. 20 GB); modo **checkbox** incluído; **`PhysicalLine1BasedForListLine0`** evita varredura O(ficheiro) no mapa proporcional; **`ZeroScan.DiscoveringLastLine`** i18n.

### Internacionalização (11 idiomas)
- Extrair partes: `E&xtract file parts...`, `Extract file parts from file`, `SplitFileFraction.*`, `SplitFilePart.FilenamePart` / `FilenameOf`, `SplitFileFraction.ResultTitle`.
- Zero Scan última linha: **`ZeroScan.DiscoveringLastLine`**.

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.25**–**.28**; Tail macro / split LF / script engine **v2.1.7.21**–**.24** permanecem abaixo.

### Como usar (Zero Scan + partes)
| Acção | Resultado |
|--------|-----------|
| **Shift+End** (Zero Scan, sem `temp.txt`) | 1.ª vez: progresso “localizar última linha”; depois vai ao fim físico |
| **Ctrl+Shift+Q** | Exporta partes LF-safe; nomes traduzidos; ListView reposta se o fonte estava aberto |
| **Sair do FastFile** | Apaga `temp.txt` e `temp_ckpt.txt` na pasta do EXE |

---

## Atualização incremental — Tail macro Python, split por linhas e script engine GB+ (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.21 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.21`**; **`uTailMacro.pas`** + **`MainUnit.pas`**: painel **Tail macro (Python)** (Opções); **`transform(line, ctx)`** via **ScriptEngine** modo **LINE**; exemplos laterais + **Falar com a IA**; definições em **`ASkin.ini`** (`TailMacro`).
- **v2.1.7.22 (interno):** macro Tail em ficheiros GB+ — flush em lote no stdin do ScriptEngine, fila chunked, saída silenciosa em ficheiro; **Reprocessar linhas novas** (**Ctrl+Shift+R**); incluir resultados no export Tail (**Ctrl+Shift+L**); **`uTailExportDialog.pas`** traduzido nos **11 idiomas**; opções de caminho de resultados no painel.
- **v2.1.7.23 (interno):** **`TSplitEqualPartsThread`** / **`FastFileCountLinesLf`**: divisão em partes iguais por **contagem de linhas** (fronteiras **LF**, sem cortar registo a meio); progresso **`SplitEqualParts.CountingLines`** + i18n.
- **v2.1.7.24 (interno):** Script engine modo ficheiro grande — índice esparso **`temp_ckpt.txt`**, saída directa **`OUTFILE`** em disco (memo leve); mensagem **`Large file mode enabled...`** + aviso **`SCRIPT_ENGINE_UPDATE_FOR_OUTFILE`** (ENGINE_VERSION 5+); **`uI18n`**: pacote Tail macro / export / script output nos **11 idiomas** + **`Create blank lines`**.

### Internacionalização (11 idiomas)
- Tail macro: painel, estados, reprocessar, export, exemplos, erros (**`AddCommonTranslationsPythonMacroExamples`** / blocos Tail em **`uI18n.pas`**).
- Export Tail: **`uTailExportDialog`** via **`TrText`** + **`Set11`**.
- Split partes iguais: **`SplitEqualParts.CountingLines`**; inserção múltipla: **`Create blank lines`**, **`Insert multiple lines`**.

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.21**–**.24**; autofill/CSV/delete **v2.1.7.17**–**.20** e script engine **v2.1.7.13**–**.16** permanecem abaixo.

### Como usar Tail macro Python
| Acção | Resultado |
|--------|-----------|
| **Ctrl+T** (Tail ON) + Opções → **Macro tail (Python)...** | Abre painel lateral; activar **Usar macros Python em linhas novas** |
| Cada linha nova no fim do ficheiro | **`transform(line, ctx)`** executada via ScriptEngine |
| **Ctrl+Shift+R** | Reprocessa linhas novas da sessão Tail actual |
| **Ctrl+Shift+L** | Export Tail; opcionalmente inclui resultados da macro |

---

## Atualização incremental — Autofill de linhas, CSV pós-edição, undo e delete (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.17 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.17`**; **`MainUnit.pas`**: **autofill estilo EmEditor** — arrastar para baixo na coluna **Linha #** (sem Ctrl/Alt) insere linhas em branco com pré-visualização; **Ctrl/Alt** na coluna de conteúdo mantém seleção vertical em bloco; **`BuildBlankInsertLineContent`** gera linhas CSV com delimitadores vazios quando **Ctrl+Alt+V** está activo.
- **v2.1.7.18 (interno):** **Ctrl+Z / Ctrl+Y** para blocos de autofill (`Op=3`, `BatchKind=1`); journal **`BAUT`** em **`uFileSessionHistory.pas`** / aba merge **`uCompareMergeUI.pas`**; **`RecordBatchInsertForUndo`** preserva contagem de linhas vazias (não aplica `TrimTrailingEmptyClipboardLines`); **`RestoreBatchInsertLinesFromUndo`** para redo.
- **v2.1.7.19 (interno):** **`RestoreCsvModeAfterPostEdit`** após reload pós-edição — restaura **`CsvMode`**, **`CsvHasHeader`**, **`CsvHideHeaderRow`** da sessão sem re-detectar cabeçalho sobre linhas `;;;` inseridas; **`LineLooksDelimiterOnly`** ignora linhas só-delimitador na detecção CSV; **`EndRead`** chama restore em vez de **`DetectAndApplyCsvMode`** cego.
- **v2.1.7.20 (interno):** **`ApplyPostBatchDeleteRefresh`** descarta **`temp.txt`** obsoleto após delete MMF (reconstrói só **`temp_ckpt.txt`**) — ListView correcta sem **F5**; entrada **Recent files** removida automaticamente se ficheiro não existe (**`MainUnit`**, **`uWelcomeScreen`**); **`uI18n`**: cadeias autofill/BAUT com acentuação nos **11 idiomas** + **`File not found:`** + legenda do journal merge.

### Internacionalização (11 idiomas)
- Autofill: status, confirmação undo/redo, notas journal (**`AddCommonTranslationsUndoSearchSessionPart1/Part2`**); **`File not found:`**; legenda **`Logged: INS/EDT/DEL, BINS/BAUT/BDEL...`** na aba histórico/merge.

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.17**–**.20**; script engine **v2.1.7.13**–**.16** e undo assíncrono **v2.1.7.11**–**.12** permanecem abaixo.

### Como usar autofill de linhas
| Acção | Resultado |
|--------|-----------|
| Arrastar **Linha #** para baixo (sem Ctrl/Alt) | Insere N linhas em branco após a linha de ancoragem |
| **Ctrl+Z** / **Ctrl+Y** | Desfaz/refaz o bloco inteiro (após reload terminar) |
| **Ctrl+Alt+V** (CSV) | Linhas novas com células vazias alinhadas às colunas |
| **Del** em linhas seleccionadas | Delete em lote; ListView actualiza sem **F5** |

---

## Atualização incremental — Script engine, exemplos Python e distribuição (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.13 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.13`**; **`ScriptEngine.py`**: progresso por bytes em **RUNFILE** (`PROGRESS:` com detalhe *Byte scan*); **`uSmoothLoading.pas`**: barra de progresso actualiza em ficheiros GB+ (`BeginScriptEngineProgress`, `UpdateProgressWithDetail`, `PostProgressWithDetailFromWorker`); **`lblDetail`** legível no fundo azul (`ApplyDetailLabelLook`); correcções de layout do modal de carregamento e botão cancelar (`LayoutCancelButton` usa `Canvas` do form no Delphi 7).
- **v2.1.7.14 (interno):** painéis de exemplos macro Python/Tail via **`TrText`** (`PY_MACRO_EX_01`…`10`, `SCRIPT_ENGINE_EXAMPLES_HEADER`/`DOC`); correcção de mojibake (`ï¿½` → ` - `); títulos didácticos Regex IA; **`uI18n.pas`**: `AddCommonTranslationsPythonMacroExamples` + `AddCommonTranslationsUndoSearchSessionPart1/Part2` (limite de constantes locais do compilador D7).
- **v2.1.7.15 (interno):** **`EnsureExecutableAvailable`** / **`ResolveExecutableUrl`**: descarrega **`ScriptEngine.exe`**, **`ConsumerAI.exe`**, **`ConsumerRAG.exe`** de `http://hvogel.com.br/fastfile_executables/` só quando o ficheiro local não existe; mensagens de transferência nos **11 idiomas**.
- **v2.1.7.16 (interno):** **Ctrl+Alt+E** sem ficheiro na listview: **`ShowTab(tabReadFile)`** antes de mostrar o painel; **`SetFocus`** só com **`CanFocus`** (corrige **`EInvalidOperation`** *Cannot focus a disabled or invisible window*).

### Internacionalização (11 idiomas)
- Chaves novas: **`PY_MACRO_EX_*`**, **`SCRIPT_ENGINE_EXAMPLES_*`**, **`Running script over file lines...`**, **`SCRIPT_ENGINE_OVERLAY_START`**, mensagens de **download** de executáveis, entradas Regex didácticas em **`AddCommonTranslationsRegexExamplesPart4`** (ver **`uI18n.pas`**).

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.13**–**.16**; undo/redo, split/IA e smooth loading anteriores permanecem nas secções abaixo.

---

## Atualização incremental — Undo/Redo estável e confirmação (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.11 (Anterior - host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.7.11`**; **`MainUnit.pas`** + **`uSmoothLoading.pas`**: **edição e undo/redo assíncronos** (`TEditFileThread.Create` em vez de **`RunEditWait`** na thread da UI — elimina congelamento em ficheiros grandes); **`ApplyEditWithUndo`** com **`CommitPendingEditUndoIfNeeded`** em **`FinishThread`**; **`StartAsyncUndoRedo`** + **`CommitPendingUndoRedoIfNeeded`** (pilha atualizada só após gravação em disco); **`RefreshFile`** → **`BeginReadSilent`** + **`FFreshFileRead`** preserva a pilha após editar/desfazer (F5 / nova leitura continua a limpar); **`RecordForUndo`** apenas após sucesso (ex.: colar); **`UndoRedoBusy`** bloqueia sobreposição de operações.
- **v2.1.7.12 (interno):** confirmação **Sim/Não** antes de **Ctrl+Z** / **Ctrl+Y** com mensagem por tipo de operação (inserir/editar/apagar, pré-visualização do texto); **`uI18n.pas`**: **`AddCommonTranslationsUndoSearchSession`** — confirmações, **`Undo failed.`**, **`Redo failed.`**, **`Replace failed.`**, **`Another edit or undo is still in progress...`** nos **11 idiomas**.

### Internacionalização (11 idiomas)
- Ver **v2.1.7.12**; trilho **v2.1.7.10** mantém mensagens de estado e busca (sem repetir aqui).

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.11**–**.12**; busca/read-only e undo inicial estão em **v2.1.7.9**–**.10** abaixo.

### Como usar Undo/Redo
| Atalho | Ação |
|--------|------|
| **Ctrl+Z** | Pede confirmação, depois desfaz a última edição registada |
| **Ctrl+Y** ou **Ctrl+Shift+Z** | Pede confirmação, depois refaz |
| Menu **Editar** / popup | **Undo** / **Redo** |

Regista: editar/inserir/apagar linha, colar, substituir simples (Ctrl+H). **Não** regista: Substituir tudo, split, regex em massa. Requer sessão **gravável** (**Ctrl+Alt+R**). Aguarde o overlay de edição terminar antes de novo undo.

---

## Atualização incremental — Busca, sessão read-only e Undo/Redo (inicial) (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.9 (Anterior — host FastFile):** **`CurrentEffectiveFilePath`** (remove sufixo ` [READ ONLY]`) — corrige **Ctrl+F** / **Ctrl+H** / tail em sessão só leitura; busca **ignore case** (BMH) + **F3** na mesma linha; realce na coluna **Conteúdo**; **`SessionBlocksMutation`** bloqueia substituição em read-only; pilha **Undo/Redo** (até **100**); **Ctrl+Z** / **Ctrl+Y** / **Ctrl+Shift+Z**.
- **v2.1.7.10 (interno):** **`uI18n`**: **`Nothing to undo`**, **`Undo:`** / **`Redo:`**, **`Found at line %d`**, etc. (11 idiomas).

### Merge aplicado (sem duplicidade)
- Estabilidade assíncrona e confirmação: ver **v2.1.7.11**–**.12** acima; **não** repetir o pacote **Split v2.1.7.7**–**.8** na secção seguinte.

---

## Atualização incremental — Split embutido: modo, barra de IA e i18n (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.7 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** referência **`2.1.7.7`**; **`MainUnit.pas`**: aba embutida **Split by Pattern/Regex** com **`TComboBox` cmbMode** (índice **0** = partes iguais, **1** = padrão/regex), **`LblEqualParts`** + **`TsSpinEdit` SpnEqualParts**; correcção de **access violation** em **Preview** / **Confirm** (`Frm.cmbMode` inexistente); **Confirm** no modo regex passa a usar **`roSplit`**; **`ApplySplitPatternHostedMetrics`**: âncora do memo de exemplos **sem** linha de botões no **`TScrollBox`**; protecção de altura mínima do memo; botões **Sugerir exemplos com a IA** e **Falar com a IA** como **`TButton`** na **barra inferior fixa** (`PnlBottom` altura **80**), fora do scroll (pintura fiável com **AlphaSkins**); larguras dos botões ajustadas quando a barra é estreita; **`HISTORY`** (`miVersionHistoryClick`) + docs sincronizados.
- **v2.1.7.8 (interno):** **`uI18n.pas`**: títulos curtos da secção de sugestões IA no memo e texto do banner alinhados; novas chaves **`Split / process mode:`** e **`Number of parts:`** com **`RegexExamples_Set11`** nos **11 idiomas**.

### Internacionalização (11 idiomas)
- Entradas novas listadas em **v2.1.7.8**; demais chaves de IA / exemplos Regex mantêm-se nas entregas **v2.1.7.5**–**.6**.

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **v2.1.7.7**–**.8**; **não** repetir o pacote **v2.1.7.3**–**.6** na secção seguinte.

---

## Atualização incremental — Split por padrão / Regex + assistente IA (gateway) (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.6 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** referência de build **`2.1.7.6`**; **`CHANGELOG_IMPLEMENTACOES.md`** + **`HISTORY`** (`miVersionHistoryClick`) + **`README.md`** + **`ROADMAP_COMERCIAL_FASTFILE.md`** + **`DOCUMENTACAO_MODELOS_IA.md`**. Consolida os incrementos internos **v2.1.7.3**–**v2.1.7.5** num único número de build publicado antes de **v2.1.7.7**.
- **v2.1.7.5 (interno):** **`uI18n.pas`**: chave **`AI_PROMPT_RULES_P3`** (pedido explícito de linhas `Regex:` na resposta); chaves **`AI_SPLIT_VALIDATION_PASTE_HDR`**, **`AI_SPLIT_VALIDATION_REJECT_HDR`**, **`AI_SPLIT_VALIDATION_NONE_PASTE`**; revisão de acentuação/codificação nos **11 idiomas** onde aplicável.
- **v2.1.7.4 (interno):** novo **`uVBScriptRegex.pas`** (**`NormalizeRegexPatternForVBScript`**, **`TryCompileVBScriptRegexPattern`**); **`MainUnit.pas`** passa a consumir a unidade partilhada; **`uFastFileAIScreenHelp.pas`**: apêndice na resposta do gateway com bloco **pronto para colar** no campo Pattern (padrões normalizados aceites pelo **VBScript.RegExp**) + secção opcional de sugestões rejeitadas; **`FastFile.dpr`**: **`uVBScriptRegex`** no uses.
- **v2.1.7.3 (interno):** **`MainUnit.pas`** / **`TMergeFilesDialogForm`**: botão **Preview** na aba embutida **Split file by Pattern/Regex**; **`SplitByPatternTabPreviewClick`** (prévia de partes iguais vs. amostra regex), alinhado ao comportamento do modal.

### Internacionalização (11 idiomas)
- Novas entradas **`RegexExamples_Set11`** / **`TrText`** listadas acima; mensagens de pré-visualização e UI relacionadas reutilizam chaves existentes (ex.: **`Preview`**) já traduzidas.

### Merge aplicado (sem duplicidade)
- Esta secção cobre apenas **Split/Regex + IA**; **não** repetir o pacote **Smooth loading** **v2.1.7.1**/**v2.1.7.2** documentado na secção seguinte.

---

## Atualização incremental — Overlay Smooth Loading / progresso (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.2 (Anterior — Smooth loading track):** **`UnConsts.APPLICATION_VERSION`** referência histórica **`2.1.7.2`**; **`uSmoothLoading.pas`** / **`.dfm`**: controlo **Cancelar** como **`TBitBtn`** (hit-test fiável com **AlphaBlend** / janela em camadas); **`ApplyCancelButtonLook`** (tipografia estilo link; compatível com Delphi 7 sem propriedades `Flat`/`Color` no `TBitBtn`); **`CancelRequested`** (`GDownloadCancelled`) consultado em laços principais (**`TReadFileThread`**, **`TEditFileThread`**, **`TMergeDeltaThread`**, replace-all); encerramento seguro na leitura (**`FinishThreadExecution`**) e feedback na edição (**`Synchronize(FinishThread)`**); **`TrText('Cancelling...')`** nos **11 idiomas** em **`uI18n.pas`**.
- **v2.1.7.1 (Anterior):** **`uSmoothLoading`**: área cliente maior (~760×720) limitada à área de trabalho do monitor primário (**`SPI_GETWORKAREA`**); cantos arredondados (**`HRGN`** + recorte na pintura + contorno **`Windows.RoundRect`**); fade-in em alpha com **smoothstep** e duração mais longa; **`PostMessage`** para reaplicar região após exibição; reposicionamento do cancel face à barra de progresso.

### Internacionalização (11 idiomas)
- Nova chave **`Cancelling...`** em **`uI18n.pas`** (ao lado das entradas base de **`Cancel`**), com codificação segura para ANSI / caracteres acentuados por idioma.

### Merge aplicado (sem duplicidade)
- Esta entrada cobre apenas o overlay de progresso **Smooth loading**; **não** repetir o bloco **Big Data / Zero Scan** já documentado em **v2.1.7.0** abaixo.

---

## Visão Geral

Este documento foi consolidado com merge de histórico para evitar duplicidade entre blocos descritivos e o histórico in-app (`miVersionHistoryClick`).

As entregas recentes de **busca, navegação, split por arquivos/linhas, atalhos, otimizações de I/O, empacotamento standalone, evolução do bridge/painel de IA, paginação SQL no ConsumerAI, modal de mesclar linhas (delta), divisão do arquivo em partes aproximadamente iguais (LF), gravação atómica com deteção de alteração externa e limite de segurança em substituir tudo, About/ajuda, ir para offset em bytes, filtro (prefixo / contém / regex), duplicar linha no menu e mnemónicos no Localizar e substituir, substituir tudo opcional por segmentos de linhas, exclusão em lote em modo segmentado, menus Tools/Dialogs (ícones e atalhos alinhados às Opções), atalhos Ctrl+Alt+R / Ctrl+R / Ctrl+W, menu **Visualizar** (View) com **Selecionar** e **zoom da lista**, marcadores no popup Tools, modal **detalhes do ficheiro** na barra de estado (texto alargado, ESC, i18n), modal **Comparar / mesclar + histórico** (diff, histórico, i18n a 11 línguas), **recarregar histórico** (barra de progresso alinhada ao trabalho, overlay sem topmost, multitarefa), **tail/follow com pausa e contador de pendentes**, **destaque de bookmark em azul + fonte branca**, **navegação precisa em word-wrap + checklist (Ctrl+G/F2/Shift+F2)**, **polimento da aba de Arquivos Recentes**, **diff assíncrono com modo rápido dinâmico para ficheiros grandes** e **correções de alinhamento no diff por faixa + insert em EOF quando alvo=linha 0** foram diluídas em versões internas sequenciais `v2.1.6.15` a `v2.1.6.74`; o refinamento do overlay de progresso **Smooth loading** aparece em **`v2.1.7.1`** / **`v2.1.7.2`**; o pacote **Split por padrão / Regex + assistente IA (gateway)** aparece na secção incremental **`v2.1.7.3`**–**`v2.1.7.6`**; o endurecimento da **aba embutida** (modo, **Preview/Confirm**, barra fixa de botões IA, **`roSplit`**, i18n de rótulos) aparece em **`v2.1.7.7`** / **`v2.1.7.8`**; **busca, sessão read-only e Undo/Redo** em **`v2.1.7.9`** / **`v2.1.7.10`**; **script engine, exemplos Python, download de executáveis e abertura do painel macro sem ficheiro** em **`v2.1.7.13`**–**`v2.1.7.16`**; **autofill de linhas, CSV pós-edição, undo BAUT e refresh pós-delete** em **`v2.1.7.17`**–**`v2.1.7.20`**; **Tail macro Python, split partes iguais por contagem de linhas e script engine modo ficheiro grande** em **`v2.1.7.21`**–**`v2.1.7.24`**.

---

## Atualização incremental — Arquitetura Big Data 16TB e Zero Scan (maio/2026)

### Versões internas (diluídas)
- **v2.1.7.0 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** referência de lançamento **`2.1.7.0`**; **`MainUnit.pas`**: implementação do modo **"Force Zero Scan Mode (Ultra Large Files)"** no menu **Visualizar**, permitindo a abertura instantânea (0 segundos) de arquivos de escala titânica (ex: 2 Terabytes) burlando a `TReadFileThread` e substituindo a contagem de linhas por um limite virtual matemático de 2.000.000.000 para mapeamento do `TListView`; **Proteção Airbag 32-bits**: implementação de desarme automático da thread ao atingir o teto de 2 bilhões de linhas para prevenir Integer Overflow, ativando automaticamente o bypass; **Motor SWAR**: limpeza e restauração de throughput do laço de varredura (atingindo picos de 1.4+ GB/s em *hot reads*); correção de bug no menu dinâmico da UI através da técnica de "Backing Field" (`FForceZeroScan: Boolean`), isolando o estado booleano nativo contra o engine de skins `AlphaControls` (garantindo a renderização do checkmark); **Correção de UI**: "Total de caracteres" na barra de status agora usa `FileSize` diretamente, marcando a contagem de bytes sem penalidade de I/O.
- **v2.1.6.74 (Anterior - host FastFile):** mantém as rotinas do painel de macro Python detalhadas na seção seguinte.

### Internacionalização (11 idiomas)
- **`uI18n.pas`** atualizado com chaves e textos traduzidos para a nova feature **"Force Zero Scan Mode (Ultra Large Files)"** em PT-BR, PT-PT, EN, ES, FR, DE, IT, PL, RO, HU, CS (garantindo codificação Windows-1250/ANSI safe).
- Mensagens do Airbag de Memória devidamente traduzidas.

### Merge aplicado (sem duplicidade)
- Esta entrada foca exclusivamente no salto arquitetural para Big Data (limites de 32-bits vencidos), não repetindo as entregas do fluxo de scripts.

---

## Atualização incremental — Painel de macro Python, atalhos e estabilidade ConsumerAI (maio/2026)

### Versões internas (diluídas)
- **v2.1.6.74 (Current / Atual - host FastFile):** **`UnConsts.APPLICATION_VERSION`** atualizado para **`2.1.6.74`**; **`MainUnit.pas`**: atalhos de edição no painel de macro Python robustecidos no ponto mais confiável de captura (`Application.OnMessage`) para os 3 memos (Ctrl+C/Ctrl+Insert, Ctrl+V/Shift+Insert, Ctrl+A/Ctrl+T), com roteamento por `HWND` e mensagens Win32 (`WM_COPY`, `WM_PASTE`, `EM_SETSEL`); **otimização de performance** no fluxo ScriptEngine para ficheiros grandes (batch maior no reader, append em bloco no memo de saída, redução de chatter de protocolo em `RUNFILE`, rebuild do `ScriptEngine.exe`); **UX** do painel de macro: título movido para barra superior dedicada e sincronismo automático dos radio buttons de escopo com o modo **Select/checked lines**; **estabilidade ConsumerAI**: correção de crash "thread error: identificador inválido" em fechar painel e destruir aplicação (lifetime explícito da thread de leitura: `FreeOnTerminate=False` + `WaitFor/FreeAndNil` seguro).
- **v2.1.6.73 (Anterior - host FastFile):** mantém os ajustes de consistência do Compare/Merge por faixa + insert em EOF já detalhados na secção seguinte.

### Internacionalização (11 idiomas)
- **`uI18n.pas`** validado para as novas labels do painel de macro (`Python Macro Integration`, `All visible lines`, `Selected / checked lines only`, `Apply to:`, `Script Examples`, etc.).
- A ajuda (F1) ganhou internacionalização explícita para as linhas novas de atalho **Ctrl+Insert** e **Shift+Insert** usando `TrText` + chaves em 11 idiomas.

### Merge aplicado (sem duplicidade)
- Esta entrada consolida apenas os deltas de macro panel / ScriptEngine / ConsumerAI e i18n da ajuda, sem repetir os blocos já registados em **`.73`** e anteriores.

---

## Atualização incremental — Correções de consistência no Compare/Merge (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.73 (Current / Atual - host FastFile):** **`UnConsts.APPLICATION_VERSION`** atualizado para **`2.1.6.73`**; **`uCompareMergeUI.pas`**: no diff por faixa, leitura com lookahead (`FF_DIFF_RANGE_LOOKAHEAD`) e poda final para a janela pedida, reduzindo falsos blocos de diferença no fim do scroll após inserções/remoções no início da faixa; **`uSmoothLoading.pas`** (`TEditFileThread`): para `otInsert` sem âncora de linha (caso `TargetLine=0` ou além do EOF), conteúdo passa a ser anexado no fim do arquivo em vez de ser perdido; comportamento de apply left↔right mais previsível nos cenários de linhas sem correspondente.
- **v2.1.6.72 (Anterior - host FastFile):** mantém o pacote do diff assíncrono + fast mode dinâmico + semântica visual/cores já consolidado na seção seguinte.

### Merge aplicado (sem duplicidade)
- Esta entrada cobre apenas os dois ajustes finais de consistência (tail falso em faixa e insert EOF para linha 0), sem repetir os blocos de **`.72`**.

---

## Atualização incremental — Diff assíncrono + fast mode dinâmico (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.72 (Anterior - host FastFile):** **`UnConsts.APPLICATION_VERSION`** atualizado para **`2.1.6.72`**; **`uCompareMergeUI.pas`**: execução de diff em worker thread dedicado (`TDiffWorkerThread`) com barra de progresso não bloqueante (`WM_FF_DIFF_PROGRESS_FLUSH`) e reabilitação segura de UI; introdução de `RunDiffSync` para fluxos internos de apply-merge que precisam do resultado imediatamente, mantendo o botão de diff assíncrono para o utilizador; estratégia de desempenho para ficheiros grandes com limiar dinâmico por execução (`FFComputeDynamicForceRangeBytes`) e fallback automático para diff por faixa quando fast mode está ativo; novo checkbox explícito **Fast mode for large files** na aba de diff, com caption em MB atualizado conforme os ficheiros selecionados; melhoria semântica da visualização de diff (linhas ausentes mostram número em branco em vez de `0`) e correção de cores/legenda para manter coerência: **amarelo = adicionado à direita**, **vermelho = removido da esquerda**; **`MainUnit.pas`**: itens CSV movidos de **Options** para **View** (CSV/Column mode + header as data), alinhando organização de menu ao comportamento de visualização; **`uI18n.pas`** + docs sincronizados.
- **v2.1.6.71 (Anterior - host FastFile):** mantém a rodada de exclusão em lote responsiva + migração do Compare/Merge modal para `tabMerge` já consolidada na seção seguinte.

### Merge aplicado (sem duplicidade)
- Esta entrada concentra apenas o delta de desempenho/UX do diff e organização de menu CSV, sem repetir o pacote entregue em **`.71`** (delete responsivo + tabMerge embutido).

---

## Atualização incremental — Exclusão em lote responsiva + Compare/Merge em aba (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.71 (Anterior - host FastFile):** **`UnConsts.APPLICATION_VERSION`** atualizado para **`2.1.6.71`**; **`MainUnit.pas`** + **`uSmoothLoading.pas`**: exclusão de linhas selecionadas em lote executada em worker thread (incluindo rota segmentada), com espera responsiva no main thread (`MsgWaitForMultipleObjects` + `ProcessMessages` + `CheckSynchronize`), eliminando congelamento da UI durante o processamento; progresso do modal de exclusão atualizado de forma thread-safe (`PostProgressFromWorker`) e pintura inicial forçada; texto duplicado em preto removido. **OCP aplicado:** fluxo original de `TReadFileThread` preservado, com extensão específica (`TReadFileThreadNoUI` + `BeginReadSilent`) para recarga pós-operação sem overlay extra. **`uCompareMergeUI.pas`** + **`MainUnit.pas`** + **`MainUnit.dfm`**: tela **Compare / merge + history** migrada do modal para a nova aba `tabMerge` (modo embutido), mantendo componentes e funções; ação de menu passa a abrir/focar a aba. **`uI18n`/UI:** caption da `tabMerge` ligado a `TrText('Compare / merge + session history')` (11 idiomas) e textos de menu/ajuda ajustados para semântica de aba.
- **v2.1.6.70 (Anterior - host FastFile):** mantém o polimento da aba inicial de Arquivos Recentes (visual + i18n + ordenação de tabs) já consolidado na seção seguinte.

### Merge aplicado (sem duplicidade)
- Esta entrada concentra apenas o delta da rodada atual (delete responsivo + migração modal→tab + alinhamento i18n/versionamento), sem repetir os blocos já documentados em **`.61`–`.70`**.

---

## Atualização incremental — Hub de Arquivos Recentes (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.70 (Current / Atual - host FastFile):** **`UnConsts.APPLICATION_VERSION`** atualizado para **`2.1.6.70`**; **`MainUnit.pas`**: aba Recent Files com refinamento visual (selecao mais suave sem fundo azul persistente), alinhamento/reajuste da grade para leitura mais limpa e traducao do botao **Close** + tagline; nova acao de menu em **Visualizar (grupo View do menu contextual da lista)** para abrir a tela de Arquivos Recentes; regra de ordenacao de abas: quando `WelcomeScreenShow=1`, a aba Recent Files permanece como primeira (`PageIndex=0`), e quando desativada (`WelcomeScreenShow=0`) essa regra nao e forçada; **`uI18n.pas`**: traducao da tagline e do novo item de menu para os 11 idiomas e ajuste de acentuacao do texto da checkbox em PT-BR/PT-PT.

### Merge aplicado (sem duplicidade)
- Esta entrada cobre apenas o refinamento da tela inicial de Arquivos Recentes e sincronia de i18n/menu/docs; os blocos de Tail/Bookmarks/Compare-Merge permanecem nas entradas **`.61`-.69** sem duplicacao.

---

## Atualização incremental — Tail/Follow, bookmarks e navegação em word-wrap (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.69 (Current / Atual - host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.6.69`**; **`CHANGELOG_IMPLEMENTACOES.md`** + **`HISTORY`** (`miVersionHistoryClick`) + docs técnicas atualizados. **`MainUnit.pas`**: Tail/Follow com status de pausa/retomada e contador de linhas pendentes; destaque visual de bookmarks em **ListView** e **checklist** (fundo azul + fonte branca); nova rota de navegação com âncora configurável para manter seleção precisa em Word Wrap; F2/Shift+F2 com centralização de contexto e clamp correto no modo filtrado + checklist; bloqueio de recálculo dinâmico de altura quando a ListView está oculta (evita desvio de offset/visibleItems). **`uI18n.pas`**: traduções das novas mensagens de Tail e bookmark para os 11 idiomas.
- **v2.1.6.68 (Anterior - host FastFile):** mantém as entregas de Compare/Merge registradas abaixo (sem duplicação).

### Merge aplicado (sem duplicidade)
- Esta entrada agrega apenas o delta funcional de navegação/word-wrap/checklist, Tail/Follow e visual de bookmarks. As entregas de Compare/Merge da trilha **`.61`-.68** permanecem nas seções já consolidadas.

---

## Atualização incremental — Recarregar histórico (Comparar/mesclar): progresso, responsividade, F1 (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.68 (Anterior - host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.6.68`**; **`CHANGELOG_IMPLEMENTACOES.md`** + **`HISTORY`** (`miVersionHistoryClick`) atualizados; **`uCompareMergeUI.pas`**: popup-menu do diff refinado (linhas verdes/iguais mostram apenas **Copiar seleção** + **Ir para linha...**; linhas diferentes mostram apenas **Copiar** + o **Aplicar** no sentido correto); correção de modo virtual/`OwnerData` para popup e pintura (usar `FDiffRows[Item.Index]` em vez de `Item.Data`, evitando linhas falsamente verdes e menus errados no diff de arquivo completo); mensagem **"There is no difference between the files."** com acentos restaurados e corrigida para os **11 idiomas**; **`MainUnit.pas`**: **ESC** fecha a aplicação quando `pgMain.Visible = False`.
- **v2.1.6.67 (Anterior - host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.6.67`**; **`CHANGELOG_IMPLEMENTACOES.md`** + **`HISTORY`** (`miVersionHistoryClick`); **`uCompareMergeUI.pas`**: menus de contexto dinamicos (**Apply left to right** / **Apply right to left**) ativados apenas nas linhas com diferencas (`ffdkChange`, `ffdkInsert`, `ffdkDelete`); sync visual de ListView durante a aplicacao de mesclagem (resolvido problema de *flickering* atraves de `WM_SETREDRAW`); calculo correto de offset para evitar loops O(N^2). **`uSmoothLoading.pas`**: correcoes criticas na `TEditFileThread` incluindo `AIsRawContent = True` (evita double-encoding que corrompia as linhas) e leitura total de EOF sem quebra de linha (evitando truncamento do ultimo registro no merge). Traducoes completas destas funcoes nos 11 idiomas via **`uI18n.pas`**.
- **v2.1.6.66 (Anterior — host FastFile):** **`UnConsts.APPLICATION_VERSION`** **`2.1.6.65`**; **`CHANGELOG_IMPLEMENTACOES.md`** + **`HISTORY`** (`miVersionHistoryClick`); **`MainUnit.ShowHelpDialog`**: marcadores **`<<<FF_HELP_COMPARE_MERGE_RELOAD_1>>>`** e **`<<<FF_HELP_COMPARE_MERGE_RELOAD_2>>>`** com **`TrText`** nas **duas** linhas de ajuda (progresso em duas fases + overlay / Alt+Tab) nos **11 idiomas** via **`uI18n.AddCommonTranslationsCompareMerge`** (`Set11`). *Não repetir* aqui o detalhe técnico já listado em **`.63`–`.64`** nem o pacote i18n completo do diálogo em **`.62`**.
- **v2.1.6.64:** **`uSmoothLoading.pas`**: overload **`ShowLoading(const Msg; AStayOnTop: Boolean)`** (predefinição **`True`**); **`uCompareMergeUI.pas`**: reload com **`ShowLoading(..., False)`** + **`BringToFront`**; **`HistPumpUIMessagesAndYield`** (`Application.ProcessMessages` + **`MsgWaitForMultipleObjects`**, 5 ms, **`QS_ALLINPUT`**); segundo argumento **`THandle`** local (Delphi 7 não aceita **`nil`** em **`var`**); **`SyncApply`** em fatias de **12** linhas / **12** itens; **`Sleep`** periódico nos loops de carateres da worker; **`SetSmoothProgress`** com **`Sleep(2)`**; **`SyncPumpPostedProgress`** usa o mesmo *pump+yield*.
- **v2.1.6.63:** **`THistoryReloadThread` / `uCompareMergeUI`**: escala de progresso **0–54%** fases em thread (cauda do journal, filtro, preview, scan de cores) e **55–99%** aplicação na UI (memo + lista); remoção de saltos prematuros para **~96–98%** antes do trabalho pesado na main; **throttle** de **`PostMessage`** (`WM_FF_HIST_PROGRESS_FLUSH`); progresso da cauda a cada **256 KiB**; campos **`FHistReloadProgLastFlushTick` / `FHistReloadProgLastPosted`**.

### Merge aplicado (sem duplicidade)
- A trilha **`.62`** abaixo mantém o registo do **Set11 completo** do modal Comparar/mesclar; **`.63`–`.65`** documentam só o **reload do histórico**, overlay e ajuda F1, sem reenumerar cada chave `TrText` do diálogo.

---

## Atualização incremental — Comparar / mesclar + histórico (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.62:** **`uI18n.pas`** — **`AddCommonTranslationsCompareMerge`**: rotina interna **`Set11`** (11 parâmetros por idioma) substitui o antigo **`X`** (que deixava **ES/FR/DE/IT/PL/RO/HU/CZ** com texto inglês); **todas** as chaves `TrText` do diálogo Comparar/mesclar + histórico passam a ter tradução explícita nos **onze** idiomas; **pt-BR** reforça **«mesclar»** em rótulos/mensagens; guia **`DOC_COMPARAR_MESCLAR_HISTORICO_PASSO_A_PASSO.md`** alinhado ao vocabulário; sincronia de documentação com a série **`.61`** (versão publicada do EXE na época: **`2.1.6.62`**). *Não repetir* o detalhe de UI já descrito em **`.61`**.
- **v2.1.6.61:** **`uCompareMergeUI`** + **`.dfm`**: segunda aba — colunas **Text** alargadas; rótulos com espaçamento; **Sync scroll** por defeito; **menus de contexto** nas duas `TListView`; primeira aba — **`lvHistFile`** + cores pelo journal (**INS/EDT/DEL/RPLALL**); **`ExecuteModal`**: **`Boolean`** → **`RefreshFile`** quando o ficheiro gravado coincide com o aberto na janela principal; **`TouchHistoryIfSameFile`**; **`TabSheetDiff`** na declaração da classe; correções **`uLineDiffCore`** (acesso DP), **`Buf`/`BUF`** no slice de leitura. **`uI18n`**: **pt-BR** *arquivo* / **pt-PT** *ficheiro* onde aplicável; bloco «extras» (pré-visualização + contexto) já nos **11** idiomas — complementado em **`.62`** com o restante do diálogo.

## Atualização incremental — Menu View, detalhes do ficheiro e alinhamento de versão (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.60:** alinhamento de versão/changelog do host (entregas **`.58`–`.59`** documentadas nas entradas seguintes).
- **v2.1.6.59:** **`BuildLoadedFileDetailsText`** + **`ShowDetailsPopup`**: painel da barra de estado com metadados alargados (caminho, tamanho em disco, datas, linhas/carateres/offset máximo, codificações, opções de sessão e de vista, modo de lista, resumo de leitura); janela maior; título **`TrText('File details')`**; **ESC** fecha (**`KeyPreview`** + **`DetailsPopupKeyDown`**); **OK** como botão predefinido (**Enter**); **`uI18n`**: chaves do bloco «detalhes do ficheiro» + **`Text copied to clipboard!`** nos **11 idiomas**.
- **v2.1.6.58:** Menu principal **&View** (**Alt+V**): **Word wrap** e **marcadores** saem de **Opções** para **Visualizar**; **Selecionar (lista de checkbox)** só em **Visualizar** (removido de **Opções**); **Zoom in/out (lista)** no **Visualizar** (**Ctrl+Num+** / **Ctrl+Num-**) e no **popup da ListView**; **popup Tools** da title bar: **`EnsureToolsPopupBookmarkExtras`** entre **Word wrap** e **só leitura**; **`TrText('&View')`** nos **11 idiomas**; **F1**: **Alt+V**, atalhos de zoom da lista.

### Merge aplicado (sem duplicidade)
- **`.57`** continua a documentar apenas **i18n modo segmentado**, **Dialogs** / **pt-PT**, memo do histórico e **`titlebar.tools`** (secção seguinte); **não** duplicar aqui o texto de **`.55`–`.56`** (Tools/popup/atalhos).

---

## Atualização incremental — i18n e rótulos da barra de título (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.57:** **`uI18n`**: chave **`Dialogs`** (submenu do título **Dialogs** / `SysSubMenu`) nos 11 idiomas; **`&Version History` / `Version History`** para **pt-PT**; cabeçalho **`FastFile - Version History`** no memo do histórico via **`TrText`** + **`StringReplace`**; linhas de ajuda e menu já entregues em **.56** e **.55** consolidadas na documentação; **`sSkinManager1GetMenuExtraLineData`**: legenda extra do popup **Tools** com **`Tr('titlebar.tools')`**.

---

## Atualização incremental — Atalhos e paridade do popup da lista (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.56:** **`ApplyReadPanelKey`**: **Ctrl+Alt+R** alterna sessão só leitura; **Ctrl+R** apenas com **Ctrl** (lista MRU); **Ctrl+W** apenas com **Ctrl** (word wrap); **`ShowHelpDialog`**: linha **Ctrl+Alt+R** via placeholder + **`TrText`**; itens de menu / popup / bloco Tools com o mesmo **`ShortCut`** onde aplicável; popup da **ListView**: **Tail / Follow**, **Exportar resultados filtrados**, ícone de só leitura alinhados ao menu **Opções**.

---

## Atualização incremental — Menu Tools, ícones e limpeza de itens demo (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.55:** **`PopupMenu1`**: bloco dinâmico **FastFile** (word wrap, só leitura, modo segmentado pesado, tail, filtro, exportar filtrados) inserido antes do separador final; **`BuildMenuBitmapImageList`**: **`FMenuBitmapImages`** também em **`PopupMenu1`** e **`PopupDialogs`**; **`ApplySkinRelatedPopupMenuIcons`**; **`PopupMenu1Popup`**: sincronização de **Checked** (incl. filtro ativo); **Opções** + popup da lista: item **modo segmentado**; **`.dfm`**: remoção de **Allow animation**, **Change BidiMode** nos menus (mantém **`sSpeedButton10`** / **`changeBidiMode`**); remoção de **C2** em **PopupDialogs**; **`FormShow`**: após INI no **`chkSegmentedHeavyOps`**, **`chkSegmentedHeavyOpsClick`** para alinhar menus; **`LocalizeTopToolbar`**: **`SysSubMenu.Caption`** via **`TrText('Dialogs')`**.

### Merge aplicado (sem duplicidade)
- **v2.1.6.54–.53** permanecem como registo técnico de **exclusão em lote segmentada** e **Replace All segmentado** (checkbox + INI **`SegmentHeavyOps`**); a trilha **.55–.60** cobre UX/menus/atalhos/i18n (incl. **View**, **detalhes do ficheiro**, **Tools** com marcadores) sem repetir bullets de merge de ficheiros ou de threads onde já documentados acima.

---

## Atualização incremental — Exclusão em lote segmentada (mesmo checkbox) — 2.1.6.54 (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.54:** **`uSmoothLoading.TrySegmentedBatchDelete`**: com o mesmo **`SegmentHeavyOps`** ativo, **Eliminar linhas (lote)** em ficheiros com mais de uma parte (~250k linhas) gera saída por segmentos (linhas a manter), concatena em temporário **`bdel`** e **`TryRenameTempOverTarget`**; se o segmentado não se aplicar (ou índice em falta), mantém-se o caminho clássico em **`DeleteFromStream`**; **`uI18n`**: hint do checkbox alargado (11 idiomas).

---

## Atualização incremental — Substituir tudo por segmentos de linhas (opcional) — 2.1.6.53 (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.53:** **`MainUnit`**: checkbox **Line-segmented processing for heavy operations** (**desligado** por predefinição), persistência **`SegmentHeavyOps`** em `ASkin.ini`; **`TReplaceAllThread`**: modo segmentado — partes alinhadas ao índice `temp.txt` (~250k linhas por parte), ficheiros temporários `ff_rseg_*.tmp`, substituição por parte com threads internas (`FreeOnTerminate` controlado), junção por concatenação e **`TryRenameTempOverTarget`** no ficheiro original; aviso no diálogo **Substituir tudo** e hint quando o modo está ativo; **`uI18n`**: chaves nos 11 idiomas.

---

## Atualização incremental — Grandes ficheiros / limites 32-bit (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.52:** **`TailAppendNewLines`**: leitura do delta de crescimento em **chunks de 64 MiB** para não passar `Int64` truncado a `Integer` em `GetMem`/`TStream.Read` (Delphi 7); **`TFilterThread`**: cálculo do bitset em **`Int64`** — se `(linhas+7) div 8` **> MaxInt**, não aloca e falha com mensagem traduzida; **`uMMF.PtrAt`**: aritmética de ponteiro via **`PAnsiChar`** em vez de `Integer(FViewPtr)`; **`uI18n`**: chave para a mensagem de limite do filtro (11 idiomas).

---

## Atualização incremental — i18n PL/CZ (Localizar e substituir / duplicar) — 2.1.6.51 (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.51:** **`UnConsts.APPLICATION_VERSION`** + histórico in-app + este changelog; **`uI18n.pas`**: correção de literais **Windows-1250** nas chaves **Find &Next**, **&Replace**, **Replace A&ll**, **&Close**, **D&uplicate line** para **polaco** (`Zamień` / «substituir tudo») e **checo** (`další`, `vše`, `Zavřít`, `řádek`).

---

## Atualização incremental — Duplicar linha, Localizar e substituir (mnemónicos) e versão 2.1.6.50 (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.50:** **`UnConsts.APPLICATION_VERSION`** + histórico in-app (`miVersionHistoryClick`) + este changelog; **Opções** e **popup da lista**: item **D&uplicate line** a seguir a **Inserir linha**, atalho **Ctrl+Shift+U** e `miDuplicateLineClick` → `editFile(otDuplicate)` (mesmo fluxo do modal do duplo clique); **Ajuda (F1)**: linha de atalho Ctrl+Shift+U e nota **Alt+N/R/L/C** no diálogo Localizar e substituir; **`uFindReplace.dfm`**: `Find &Next`, `&Replace`, `Replace A&ll`, `&Close`; **`uI18n.pas`**: chaves `TrText` para esses botões e para **D&uplicate line** nos **11 idiomas**.

---

## Atualização incremental — Filtro regex COM, busca, replace-all, encoding e linhas longas (abril/2026)

### Versões internas (diluídas, agregadas 2.1.6.48–49)
- **v2.1.6.49:** **`TFilterThread`**: `CoInitialize` / `CoUninitialize` na thread ao usar **VBScript.RegExp** (corrige *CoInitialize não foi chamado*); mensagem **`Could not initialize COM for the regex filter.`** com i18n.
- **v2.1.6.48:** **Filtro** (`Ctrl+L`): modos prefixo, contém e **regex**; progresso `Filtering … / … lines`; **busca** (`TFindInFileThread`): progresso em bytes também na direção inversa; **Esc** cancela busca em curso; **Substituir tudo**: texto de confirmação alargado, overlay **`lblDetail`** (bytes + substituições), título *streaming*; **encoding**: nota `[Save note]` no hint do combo; **`GetLineContent`**: limite de pré-visualização **256 KB** e mensagem com dois totais em bytes; **i18n** e **F1** atualizados para filtro/regex.

---

## Atualização incremental — Sessão só leitura, encoding na vista e linhas longas (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.47:** **`UnConsts.APPLICATION_VERSION`** + histórico in-app + este changelog; **sessão só leitura** (`FFileSessionReadOnly`): item em **Opções** e no popup da lista, desativa Editar/Eliminar/Mesclar linhas/Dividir e bloqueia `editFile`, eliminação em lote, localizar-substituir (substituir / substituir tudo), undo/redo, merge de ficheiros, merge delta, split por ficheiros/linhas e split em partes iguais quando o ficheiro aberto é o mesmo; **`UpdateInfoPanels`**: dicas extra no combo de encoding (vista por defeito vs forçada); **`GetLineContent`**: rodapé com bytes totais quando a linha excede o limite de pré-visualização; **i18n (11 idiomas)** para as novas cadeias.

---

## Atualização incremental — About, ajuda, offset em bytes, filtro-prefixo e i18n (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.46:** alinhamento de **`UnConsts.APPLICATION_VERSION`**, **`CHANGELOG_IMPLEMENTACOES.md`** e histórico in-app (`miVersionHistoryClick`); **i18n (11 idiomas)** para linhas injetadas na ajuda (F1), estados da barra de estado do filtro (`Filter cleared.` / `Filtering...` / `Filter: %d/%d` / `Ready`), mensagem «linha fora do filtro» em `gotoLine`, correção do acelerador PL em **Ir para offset em bytes**.
- **v2.1.6.45:** segundo passo do **Filter / Grep**: `MessageDlg` escolhe **prefixo de linha** vs **contém em qualquer sítio**; `TFilterMatchMode` + `TFilterThread`; `StartFilter` com modo; caixa de diálogo traduzida para os 11 idiomas.
- **v2.1.6.44:** **Ir para offset em bytes** (`DoGotoByteOffset`, `Line0BasedForFileByte1Based`, busca binária no índice), atalho **Ctrl+Shift+G**, itens de menu/popup, `GetLineStartOffset` com índice **`Int64`**.
- **v2.1.6.43:** **Sobre o FastFile**: «Desenvolvido por», «Email de contacto», prefixo de data de compilação com `TrText`, `lblDevelopedBy`, ajuste de layout (`UnFormAboutFF` + `.dfm`); **Ajuda (F1)**: remoção da linha final de marketing; `<<<FF_HELP_*>>>` em `HELP_TEXT` + `StringReplace` com `TrText` em `ShowHelpDialog`.

### Merge aplicado (sem duplicidade)
- As entradas **v2.1.6.43–.46** complementam **v2.1.6.42** (secção seguinte — gravação segura / stale / i18n associado) e **v2.1.5.6** (About histórico): a evolução do About/contacto/developer encontra-se detalhada em **.43**; a linha antiga do About em **v2.1.5.6** permanece como registo histórico da primeira entrega de metadados.

---

## Atualização incremental — Gravação segura, ficheiro stale e i18n (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.42:** `uI18n.pas` — mensagens novas (pesquisa em ficheiros, alteração em disco, espaço em disco, erros de rename atómico, limite de substituir tudo) nos **11 idiomas** (ver também secção «About, ajuda…» acima para o contexto agregado da série .42–.46).
- **v2.1.6.41:** `MainUnit.pas` — snapshot de tamanho + `ftLastWriteTime` após carregar; invalidação ao fechar streams; `EnsureOpenFileNotStaleForMutate` antes de caminhos que alteram o ficheiro; barra de estado com progresso em **bytes** na pesquisa em ficheiros (`TFindInFileThread`).
- **v2.1.6.40:** `UnUtils.pas` — `GetFileSizeAndWriteTime`, `SameFileSizeAndWriteTime`, `TryRenameTempOverTarget`, `VolumeHasMinFreeBytes` (API `GetDiskFreeSpaceExA` declada localmente); `uSmoothLoading.pas` — verificação de espaço livre antes de threads pesadas, finalize atómico, `REPLACE_ALL_MATCH_LIMIT` (5M), correção de estrutura `try/except/finally` em `TMergeDeltaThread`; `RegressionTests/test_snapshot_logic.py` + `README.txt`.

### Merge aplicado (sem duplicidade)
- Esta trilha **complementa** `v2.1.6.37`–`v2.1.6.39` (split em partes iguais) sem repetir bullets do histórico in-app; o detalhe por versão encontra-se em `miVersionHistoryClick` (`MainUnit.pas`).

---

## Atualização incremental — Split em partes iguais (LF) + UX (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.39:** mensagens de **conclusão profissionais** (`Dialogs.ShowMessage`) com chaves `SplitEqualParts.SuccessFormat`, `FailureFormat`, `CancelledOrIncomplete` e `LogSummary` traduzidas nos **11 idiomas**; resumo no `mmTimer`. **Modal:** `ClientHeight` maior, label explicativo com `WordWrap`, altura fixa e alinhamento à esquerda; botões reposicionados. **Menu:** correção de aceleradores PT/ES/PT-PT/RO (`&iguais` / `&iguales` / `&egale`) para evitar “iiguais”.
- **v2.1.6.38:** alvo por **bytes** com ajuste ao próximo **LF** (sem cortar linha no fim da parte); saída `<nome>.partNNN<ext>` na pasta do fonte; validações (vazio, abertura, linhas ≥ partes); `CloseFileStreams` se o arquivo dividido for o aberto na aba Read; correção de tipo **`Integer(SpnParts.Value)`** (Delphi 7).
- **v2.1.6.37:** nova **`TSplitEqualPartsThread`** em `uSmoothLoading.pas` com **`TfrmSmoothLoading`** (mesmo padrão do merge); item **Opções → Dividir arquivo em partes iguais**; modal runtime estilo merge (`ShowSplitEqualPartsDialog`, `TsFilenameEdit`, 2..1000 partes); primeiras chaves **i18n** do fluxo.

### Merge aplicado (sem duplicidade)
- Esta trilha **não substitui** o histórico de split por **linhas/arquivos** (`TSplitFileThread`, v2.1.6.17–.21): é recurso **complementar** (partes de tamanho semelhante em bytes com cortes em LF).
- O histórico in-app (`miVersionHistoryClick`) e este changelog foram atualizados em conjunto; a versão publicada do EXE segue **`UnConsts.APPLICATION_VERSION`** (atualmente **`2.1.7.25`** — ver secções acima).

---

## Atualização incremental — ConsumerAI bridge + prompt flow + onefile (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.36:** modal **Mesclar linhas** (`uDeltaEditor`): `FormResize` alinha `edtContent` pela largura real dos botões (sem sobrepor Add/Update), `BringToFront` após show/resize, botões Add/Update e Delete mais largos. **ConsumerAI_LanceDB:** muitos números em “linhas específicas” passam a usar temp table + `JOIN` (evita `IN` gigante). Bridge: presets de teto para `SELECT` sem `LIMIT`, presets de tamanho de página na paginação, token `0` em `BRIDGE_MERGE_INSERT_POS`, documentação em `BRIDGE_DELPHI_INPUT_MAP`.
- **v2.1.6.35:** **ConsumerAI_LanceDB — query loop:** `SELECT`/`WITH` sem `LIMIT` solicita teto de linhas (`BRIDGE_MERGE_SQL_FETCH_CAP`) e envolve em subselect; se o retorno enche o teto, paginação/export usam o SELECT completo no DuckDB (`sql_derived_select`, `export_sql_derived_to_txt`). Truncagem de linhas longas na view paginada (`PAGINATE_MAX_ROW_CHARS`). Aviso para resultados muito grandes já carregados na memória.
- **v2.1.6.34:** **ConsumerAI_LanceDB — busca/substituição:** contagem com `COUNT(*)`; pré-visualização com no máximo 10 linhas; listagem paginada via `WHERE` + `LIMIT/OFFSET` e export filtrado com `COPY`; `replace_in_table` não carrega mais todos os matches só para contar.
- **v2.1.6.33:** **ConsumerAI_LanceDB — bridge + paginação:** laço de `paginate_results` em modo bridge com `BRIDGE_MERGE_PAGINATE` e números de página opcionais; prompt de tamanho de página com presets; helpers `_build_search_where_clause`, `export_sql_filtered_to_txt` e extensões de `paginate_results` com `sql_where`.
- **v2.1.6.32:** limpeza do painel ConsumerAI após experimentos de UI, preservando o fluxo manual de input como caminho ativo e ajustando a altura da área `Awaiting input`.
- **v2.1.6.31:** endurecimento do protocolo Delphi do ConsumerAI: `PROMPT` vazio passa a reutilizar o último prompt válido, limpeza do transcript/status e remoção de logs ruidosos em runtime.
- **v2.1.6.30:** hotfix no leitor stdout do bridge Delphi para despachar prompts parciais sem `LF` usando `PeekNamedPipe`, permitindo que prompts de `input(...)` do Python cheguem antes da resposta do usuário.
- **v2.1.6.29:** atualização do bridge Python em `ConsumerAI_LanceDB.py`: `BridgeConsole.input()` roteado para `bridge_input()`, prompt inicial em frozen mode migrado para caminho bridge-aware e extração de opções ampliada para tokens entre aspas.
- **v2.1.6.28:** refatoração da pipeline Delphi de prompt com `ApplyPromptUI`, helpers de estado e reforço de compatibilidade Delphi 7 para a sessão manual de pergunta/resposta no painel IA.
- **v2.1.6.27:** groundwork do bridge ConsumerAI no painel Delphi, com parsing de metadados de prompt e sincronização de estado por pergunta.
- **v2.1.6.26:** correção de layout do header do painel IA (sobreposição no botão Close) com redistribuição de largura dos botões + label de título dedicada; botão `Send` passou a obedecer estado do input (`OnChange`, vazio => desabilitado).
- **v2.1.6.25:** migração de `ConsumerAI_LanceDB.py` para arquitetura de proxy AWS Lambda (mesmo modelo do `ConsumerAI.py`), removendo dependência de chave local embutida no EXE.
- **v2.1.6.24:** limpeza de branding no runtime (mensagens sem exposição de `LanceDB`), novas chaves i18n de status/bridge e desativação de escrita no `ConsumerAI_Bridge_Debug.log`.
- **v2.1.6.23:** hotfix Windows no build onefile do `ConsumerAI_LanceDB.exe`: remoção de `--strip` no PyInstaller após falha de `_ssl`/`libssl` que quebrava chamadas HTTPS do Groq (`Groq / AI Error: DLL load failed while importing _ssl`).
- **v2.1.6.22:** slimming controlado do `build_exe_lancedb.bat`, reduzindo o tamanho do executável standalone com exclusão de stacks opcionais pesados de ML/testes e manutenção dos imports necessários de `pandas`/`pyarrow` em modo frozen.

### Implementações realizadas (extensão abril/2026 — v2.1.6.33–36)
- **Mesclar linhas (delta):** correção de layout e Z-order no formulário `TfrmDeltaEditor` para o botão Add/Update não “misturar” com o campo Content até um resize manual; largura dos botões aumentada.
- **ConsumerAI — memória e UI em conjuntos grandes:** busca com paginação e export no servidor; query principal com teto configurável quando falta `LIMIT`; visualização de muitas linhas específicas sem montar SQL `IN` enorme.
- **Bridge Delphi:** novos tokens de merge documentados e presets para paginação e teto de linhas em `SELECT`.

### Implementações realizadas (bloco bridge anterior — mantido)
- **Entrega de prompts sem quebra de linha:** o leitor Delphi do bridge passou a liberar texto parcial de prompt quando o Python escreve `input(...)` sem `CR/LF`, evitando que a UI só receba a pergunta depois da resposta do usuário.
- **Pipeline robusta de prompt no Delphi:** consolidação de `ApplyPromptUI`, fallback para `FConsumerAILastPrompt` quando `PROMPT` chega vazio e sincronização refinada entre `OUTPUT`/`PROMPT` no bridge.
- **Ajustes de layout do painel IA:** aumento da altura da área `Awaiting input`, ajuste do `InputHost` e limpeza da UI experimental para manter apenas o input manual no container do painel.
- **Bridge Python orientado a opções reais:** `BridgeConsole.input()` passou a emitir via `bridge_input()`, o prompt inicial em frozen mode usa caminho compatível com bridge e a extração de opções foi ampliada para grupos e tokens entre aspas.
- **Metadados de prompt no bridge:** o Python extrai opções do prompt e as envia como metadados internos do bridge; no Delphi, essa informação passou a integrar a camada de estado do prompt mesmo com o fluxo manual mantido como interface ativa.
- **UX do painel IA aprimorada:** correção de sobreposição visual no header, título desacoplado do caption do painel e ativação/desativação coerente dos atalhos com o estado da entrada.
- **Fluxo de input mais seguro:** `Send` não dispara com input vazio e o campo de resposta passa a ser habilitado/desabilitado de forma coerente ao estado da sessão.
- **Migração de integração de IA para proxy:** substituição de chamada direta ao provedor por endpoint Lambda com token de proxy, alinhando o fluxo de credenciais ao padrão já usado no projeto.
- **Mensagens e telemetria local:** remoção de termos técnicos de armazenamento nas mensagens ao usuário e desativação de log de debug local do bridge por padrão.
- **Slim do onefile standalone:** limpeza do comando PyInstaller para manter apenas dependências necessárias ao fluxo principal LanceDB/DuckDB/Groq, removendo carga de pacotes opcionais como `torch`, `transformers`, `sentence_transformers`, `sklearn`, `scipy`, `tensorflow` e derivados.
- **Preservação de compatibilidade em runtime:** mantidos os imports/metadata necessários para `lancedb`, `lance`, `pyarrow`, `pyarrow.dataset` e dependências de inicialização do `pandas` em executável frozen.
- **Hotfix de SSL no Windows:** identificado que `--strip` corrompia DLLs PE relevantes (`libssl-3.dll`, `libcrypto-3.dll`, `_ssl.pyd`) no build Windows; a flag foi removida para restaurar o fluxo de IA via Groq.
- **Validação pós-build:** `ConsumerAI_LanceDB.exe -h` revalidado com sucesso após os ajustes, confirmando inicialização e help do executável standalone.

### Merge aplicado (sem duplicidade)
- Esta seção consolida as mudanças recentes de bridge/UX/painel IA, transporte de prompt sem `LF`, endurecimento do fluxo manual de entrada, empacotamento do utilitário `ConsumerAI_LanceDB` e as entregas **v2.1.6.33–v2.1.6.36** (paginação SQL, teto em `SELECT`, modal delta) em uma trilha única de versões internas do host FastFile. **Não** inclui **v2.1.6.37–v2.1.6.39** (split em partes iguais — ver seção dedicada acima); a versão publicada do EXE segue **`UnConsts.APPLICATION_VERSION`**.
- O utilitário Python expõe histórico próprio em `VERSION` / `hist` (**2.0.1.4** alinhado a esta rodada de entregas).
- As seções históricas de UI/Read/Split do FastFile permanecem inalteradas e sem sobreposição funcional com este bloco.

---

## Atualização incremental — Read/Split produtividade e robustez (abril/2026)

### Versões internas (diluídas)
- **v2.1.6.21:** bugfix de `TSplitFileThread` para separar caminho do arquivo fonte e diretório de saída (`FOutputDir`), com ajuste dos dois chamadores.
- **v2.1.6.20:** execução de split por linhas (`btnExecuteSplitFileByLinesClick`) com validações de faixa/saída e sincronização de limites no `tabSplitFileShow`.
- **v2.1.6.19:** otimizações em leitura indexada (`GetLineContent`, `GetLineStartOffset`, `ListView1Data`) com redução de seeks/reads e menos alocações.
- **v2.1.6.18:** atalhos `Ctrl+Home` e `Ctrl+End` para navegação rápida (topo/final), com hints/ajuda atualizados.
- **v2.1.6.17:** integração completa do split por arquivos no projeto `Src` via `btnExecuteSplitFileByFilesClick` + `TSplitFileThread`.
- **v2.1.6.16:** robustez visual no `gotoLine` com `ListView_SetSelectionMark` e `ListView_EnsureVisible`.
- **v2.1.6.15:** busca direta via `btnSearchClick` usando `edtSearch.Text` e Enter no campo de busca apontando para a ação de busca.

### Merge aplicado (sem duplicidade)
- Os itens acima foram consolidados no histórico in-app e neste changelog com granularidade por versão interna.
- Quando houver descrição extensa da mesma entrega em seções antigas, considerar esta seção como a referência principal de rastreabilidade por versão.

---

## Atualização incremental — Merge Files + Hotfixes (março/2026)

### Contexto
Nesta etapa, o foco foi entregar o recurso de **Merge files** (incluir arquivo origem no destino) no padrão arquitetural do FastFile, com modal próprio, validações, i18n e execução em thread com progresso.

### Versões internas (diluídas)
- **v2.1.5.9:** entrega funcional completa de Merge files (menu, modal, validações, thread, progresso e recarga do destino).
- **v2.1.5.8:** hotfix de lock do arquivo destino (remoção de validação excessivamente restritiva + fechamento preventivo de streams internos antes do merge).
- **v2.1.5.7:** hotfix de modal runtime (`CreateNew`) e isolamento de drag and drop somente no ciclo de vida do modal.

### Implementações realizadas
- **Menu e navegação:** novo item no menu Options para acionar o merge de arquivos.
- **Modal de merge:**
  - seleção de arquivo origem por picker, entrada manual ou drag and drop;
  - modos de inserção: inicio, apos linha especificada, fim do arquivo;
  - botoes Confirm/Cancel e fechamento por ESC.
- **Validações críticas:**
  - destino em `edtFileName.Text` obrigatorio e existente;
  - origem obrigatoria, existente e diferente do destino;
  - linha valida no modo "apos linha" (faixa `1..totalLines-1`) e resolucao segura do offset via indice.
- **Execucao em thread (`uSmoothLoading.pas`):**
  - nova `TMergeFilesThread` com UI de loading e atualizacao de progresso;
  - merge com arquivo temporario + rename atomico de resultado;
  - recarga automatica do arquivo destino ao final (via `RefreshFile`/`TReadFileThread`).
- **i18n completa:**
  - traducao do item de menu, labels do modal e mensagens de processo/erro para os idiomas da aplicacao.

### Hotfixes aplicados
- **Lock indevido no destino:**
  - removido pre-check com `share exclusive` que bloqueava o proprio fluxo;
  - merge passou a fechar streams internos da UI antes da thread para evitar auto-lock.
- **Resource not found no modal:**
  - troca de `Create` por `CreateNew` no formulario runtime sem DFM.
- **Drag and drop sem efeito colateral:**
  - habilitado apenas no handle do modal e desligado ao fechar;
  - sem impacto no drag and drop da tela principal.

---

## Atualização incremental — i18n e Version History / Historico de Versoes (março/2026)

### Contexto
Nesta etapa, o foco foi consolidar internacionalização completa da UI (menus, tabs e controles internos), corrigir estabilidade de renderização em Delphi 7 (ANSI) e atualizar o histórico de versões exibido no aplicativo, mantendo a versão final atual.

### Versões registradas no histórico in-app
- **v2.1.5.6:** About FastFile usa metadados centralizados (`APPLICATION_NAME`, `APPLICATION_FULLNAME`, `APPLICATION_DEVELOPER`), exibe bitness na versão (`32-bit/64-bit`) e adiciona e-mail clicável via `mailto` com ajuste de layout do label.
- **v2.1.5.5:** caption do About padronizado com a mesma chave i18n do menu/toolbar e botão Close do Splash migrado para `TrText('Close')`.
- **v2.1.5.4:** comportamento de `ESC` ampliado para fechar abas ativas (Read/Find) quando a tecla não é consumida por contexto interno.
- **v2.1.5.3:** fallback de hints alterado de nomes técnicos de componentes para textos amigáveis ao usuário.
- **v2.1.5.2:** expansão de cobertura de hints contextuais nas áreas Read, Find Files e Split File.
- **v2.1.5.1:** revisão de acentuação/terminologia PT e harmonização EN para termos de Find/Search.
- **v2.1.0.5:** pacote de idiomas atualizado e cobertura ampla de tradução em UI.
- **v2.1.4.3:** estabilização crítica de captions RO/CS e ajuste de mapeamento para botão de leitura.
- **v2.1.4.2:** correções de chaves `TrText` com variantes exatas (incluindo espaços finais) e refatoração para limites do Delphi 7.
- **v2.1.4.1:** limpeza de encoding em captions de menu e estabilização de literais de tradução.

### Implementações realizadas
- **About FastFile (metadados e contato):**
  - Dados institucionais agora são lidos de constantes centralizadas em `UnConsts`.
  - Linha de versão passou a exibir arquitetura (`vX.X.X.X  (32-bit/64-bit)`).
  - E-mail de contato clicável no About (`mailto`) com reposicionamento dinâmico para evitar sobreposição visual.
- **Pacote de idiomas:** removido Japonês; adicionados **Polonês, Português (Portugal), Romeno, Húngaro e Tcheco**.
- **Cobertura de tradução ampliada:**
  - Menus principais (`&File`, `&Edit`, `&Options`, `&Help` e itens internos).
  - Tabs principais e subtabs (`tabFindFiles`, `tabSplitByLines`, `tabSplitByFiles`, etc.).
  - Componentes internos de tabs (labels, checkboxes, botões e captions de colunas).
- **Runtime localization:** textos hardcoded de execução/diálogos/progresso migrados para `TrText(...)` em pontos críticos do `MainUnit.pas`.
- **Inicialização de idioma:** quando o INI estiver sem idioma definido, o app passa a usar o **idioma padrão do Windows**.
- **Robustez Delphi 7:**
  - Ajustes para evitar erro **Too many local constants** em blocos extensos de tradução.
  - Segmentação em helpers de inicialização de i18n para manter estabilidade de compilação.
- **Correção de chave faltante:** inclusão de mapeamento para `Read` (impactando `btnShowTabReadFile`).
- **Correções de chave exata:** inclusão de variantes com espaço final (ex.: `Shortcut: ` e `Replaced on line `) para eliminar gaps de lookup.
- **Version History in-app:** atualização e diluição dos updates recentes em versões internas `v2.1.5.1` até `v2.1.5.6`, mantendo rastreabilidade por entrega.

### Estabilidade de caracteres (RO/CS)
- Foi aplicada estratégia de **overrides finais ASCII-safe** para captions críticos em Romeno/Tcheco, priorizando exibição estável em ambiente ANSI do Delphi 7.
- O ajuste usa a regra de inicialização **last assignment wins**, garantindo que os valores finais estáveis prevaleçam sobre entradas anteriores.

### Arquivos impactados nesta etapa
| Arquivo | Alteração principal |
|---|---|
| `MainUnit.pas` | Localização runtime com `TrText`, ajuste de inicialização de idioma por default do Windows, atualização do bloco `HISTORY` |
| `uI18n.pas` | Expansão de dicionários para novos idiomas, cobertura de menus/tabs/controles, correções de chaves exatas, overrides finais de estabilidade RO/CS |

### Resultado de QA (conversa atual)
- Auditoria de cobertura `TrText(...)` para PL/RO/HU/CS: **0 faltantes**.
- Correção pontual adicional: título de menu **Arquivo** em Romeno (`&File`) estabilizado para evitar caractere desformatado.

---

## Atualização incremental — Visual Word Wrap, Export, Encoding e Line Editor (março/2026)

### Contexto
Esta etapa adicionou word wrap puramente visual na ListView (sem reindexar), corrigiu o export para usar a contagem real do índice, melhorou o UX do editor de linha e introduziu detecção e conversão de encoding (UTF-8 → ANSI) via nova unit `uTextEncoding.pas`. Uma nova UI de seleção de encoding foi adicionada ao status bar no estilo Notepad++.

### Versões internas (diluídas)
- **v2.1.0.6 (2026-03-30):** word wrap visual com `DT_WORDBREAK` na coluna Content (sem reindexar); altura da linha via `FWordWrapRowImages` (TImageList dummy); atalho `Ctrl+W`; fix de MRU (`Ctrl+R`) para caminhos inexistentes (remoção automática + mensagem).
- **v2.1.6.1 (2026-03-30):** fix do Export — usa `IndexFileLineCount` (total real indexado) em vez de `Items.Count` do virtual list; offsets com `Abs()` para segmentos de offset negativo; overlay `slmExportLines` sincronizado.
- **v2.1.6.2 (2026-03-30):** `uLineEditor` — caixa de confirmação Sim/Não antes de aplicar inserir/editar/excluir, descrevendo a operação e o número da linha; botão padrão é **Não** (`MB_DEFBUTTON2`).
- **v2.1.6.3 (2026-03-30):** nova unit `uTextEncoding.pas` — detecção BOM + heurística estatística nos primeiros 16 KB; conversão UTF-8 → Unicode → CP_ACP em `GetLineContent`; fallback ANSI/Latin-1 para arquivos sem padrões UTF-8; `MessageBoxW` no editor de linha para diacríticos PT.
- **v2.1.6.4 (2026-03-30):** `comboViewEncoding` no último painel do `sStatusBar1` (filho do control); opções DEFAULT/UTF-8/ANSI/UTF-16 LE/BE; layout dinâmico via `LayoutViewEncodingCombo` em resize/show/skin; hook `HookedStatusBarWndProcForCombo` para compatibilidade com AlphaSkins (`CBN_CLOSEUP`); hint resume encoding detectado + vista atual.

### Implementações realizadas

- **Word wrap visual:** renderização da coluna Content com `DT_WORDBREAK` em `ListView1AdvancedCustomDrawSubItem`; altura da linha controlada por `FWordWrapRowImages` (TImageList dummy, sem alterar o índice do arquivo). Busca highlight desativada nesse modo para evitar conflito de draw de linha única vs. múltipla.
- **Atalho e MRU:** `Ctrl+W` alterna o checkbox de word wrap com hint e linha na ajuda (F1). `Ctrl+R` valida existência do caminho; caminhos inválidos são removidos de `FRecentFiles` e do `mru_files.ini` com mensagem informativa.
- **Export corrigido:** `TExportFileThread` e overlay `slmExportLines` agora usam `frmMain.IndexFileLineCount` (total real indexado). Offsets passam por `Abs()` para compatibilidade com segmentos com offset negativo no arquivo de índice.
- **Editor de linha (UX):** `uLineEditor` exibe caixa Sim/Não descrevendo a operação (inserir/editar/excluir) e o número da linha antes de aplicar; botão padrão é **Não** (`MB_DEFBUTTON2`) para prevenir alterações acidentais.
- **Encoding detection:** `uTextEncoding.pas` detecta UTF-8 por BOM ou por análise estatística dos primeiros 16 KB. `GetLineContent` em `uMMF.pas` converte UTF-8 → Unicode → CP_ACP para display correto em ANSI/Delphi 7. Arquivos sem padrões UTF-8 ficam como ANSI/Latin-1.
- **Encoding combo:** `comboViewEncoding` inserido como filho do painel final de `sStatusBar1`, posicionado dinamicamente por `LayoutViewEncodingCombo` em resize/show/troca de skin. Hook `HookedStatusBarWndProcForCombo` intercepta `CBN_CLOSEUP` para compatibilidade com AlphaSkins. Hint resume encoding detectado + modo de vista atual. Opção `DEFAULT (detected)` segue a detecção automática.

### Arquivos impactados nesta etapa
| Arquivo | Alteração principal |
|---|---|
| `MainUnit.pas` | Word wrap draw, `Ctrl+W`, MRU fix, export fix, encoding combo layout e hook |
| `uLineEditor.pas` | Caixa de confirmação Sim/Não com `MB_DEFBUTTON2` |
| `uTextEncoding.pas` | **Nova unit** — detecção BOM/heurística e conversão UTF-8 → CP_ACP |
| `uMMF.pas` | `GetLineContent` com conversão UTF-8 → Unicode → CP_ACP |

---

## Atualização incremental — Merge Files Line Range (março/2026)

### Contexto
Extensão do workflow de Merge Files para suportar cópia de apenas um intervalo específico de linhas do arquivo de origem, sem copiar o arquivo inteiro. Inclui UI dedicada no modal, 13 caminhos de validação e i18n completa em todos os 11 idiomas suportados.

### Versões internas (diluídas)
- **v2.1.6.5 (2026-03-31):** line-range mode no merge modal: checkbox de ativação, campos "Da linha:"/"Até a linha:", 13 caminhos de validação, `CountLinesInFile()`, extensão de `TMergeFilesThread` com `FFromLine`/`FToLine` e `GetSourceLineOffset()`, e 209 novas traduções em `uI18n.pas` (19 chaves × 11 idiomas).

### Implementações realizadas

- **UI do modal:** checkbox _"Copiar apenas um intervalo específico de linhas do arquivo de origem"_; campos numéricos **"Da linha:"** e **"Até a linha:"** habilitados condicionalmente ao checkbox.
- **`CountLinesInFile()`:** função helper que conta o total de linhas do arquivo de origem via leitura sequencial antes de executar a validação do intervalo.
- **Validações (13 caminhos):**
  - Campos vazios: From line vazio, To line vazio.
  - Número inválido: From line não numérico, To line não numérico.
  - Valor mínimo: From line < 1, To line < 1.
  - Ordem: From line > To line.
  - Arquivo: arquivo de origem não encontrado, falha ao contar linhas.
  - Limites: From line excede total de linhas, To line excede total de linhas.
  - Erros de execução: erro na validação do intervalo, falha ao substituir destino, falha no rename final.
- **`TMergeFilesThread`:** recebe `FFromLine` / `FToLine` no construtor; no modo line-range usa `GetSourceLineOffset()` para navegar ao offset de início pelo índice e interrompe a leitura ao atingir o offset de término, sem ler o arquivo inteiro.
- **i18n:** 19 chaves novas × 11 idiomas = **209 traduções** adicionadas em `AddRuntimeDialogProgressTranslations()` no `uI18n.pas`. Idiomas: EN, PT-BR, ES, FR, DE, IT, PL, PT-PT, RO, HU, CS.

### Arquivos impactados nesta etapa
| Arquivo | Alteração principal |
|---|---|
| `MainUnit.pas` | Enum `mfmLineRange`, `CountLinesInFile()`, UI modal com checkbox/inputs, validações |
| `uSmoothLoading.pas` | `TMergeFilesThread` com `FFromLine`/`FToLine`, `GetSourceLineOffset()` |
| `uI18n.pas` | 209 novas traduções em `AddRuntimeDialogProgressTranslations()` |

---

## Atualização incremental — Bind de ícones dos menus (março/2026)

### Contexto
Nesta etapa, o foco foi vincular os itens do menu principal e do submenu de contexto (botão direito na ListView e na CheckListBox da ListView) a bitmaps externos por semântica de função, com fallback seguro para evitar regressão visual quando um arquivo não existir.

### Versões internas (diluídas)
- **v2.1.6.6 (2026-03-31):** infraestrutura runtime de ícones adicionada (`FMenuBitmapImages` + `FMenuIconIndexByName`), resolução dinâmica de pasta (`ResolveMenuBitmapDir`) e bind por nome com fallback de índice em `BuildClassicMainMenu` e `BuildListViewPopupMenu`.
- **v2.1.6.7 (2026-03-31):** hotfix de `invalid image size` no carregamento: normalização de BMP para 16x16 via `StretchBlt` em bitmap intermediário com máscara `clFuchsia` antes de `AddMasked`.
- **v2.1.6.8 (2026-03-31):** mapeamento migrado para `Images\ImagesII\glyphspro\glyphspro\16x16\hot` e atualização dos nomes semânticos dos arquivos (ex.: `search.bmp`, `search and replace.bmp`, `word wrap.bmp`, `save as.bmp`, etc.).
- **v2.1.6.9 (2026-03-31):** ajuste fino solicitado: `About FastFile` com a mesma figurinha de `Help` e `Exit` usando `Exit.bmp`.

### Implementações realizadas

- **Infraestrutura de bind por nome:** menus deixaram de depender apenas de índices fixos; agora usam resolução por arquivo (`MenuIconIndex('nome.bmp', fallback)`).
- **Escopo coberto:** menu principal (`File/Edit/Options/Help`) e popup compartilhado entre `ListView` e `CheckListBox` (modo Select).
- **Resolução de diretório robusta:** busca da pasta de ícones subindo níveis a partir da pasta do executável para suportar layouts de execução diferentes.
- **Robustez de carregamento:** qualquer bitmap fora de 16x16 é redimensionado antes de entrar no `TImageList`, eliminando exceção de tamanho inválido.
- **Ajustes finais de UX visual:** harmonização de ícones em `Help`/`About` e padronização de `Exit.bmp` para saída.

### Arquivos impactados nesta etapa
| Arquivo | Alteração principal |
|---|---|
| `MainUnit.pas` | Resolver de diretório de ícones, carga/redimensionamento de BMP, binds semânticos no menu principal e popup, ajustes finos de ícones |

---

## Atualização incremental — Painel lateral de IA no Read (março/2026)

### Contexto
Nesta etapa, o botão `btnConsumerAIClick` passou a abrir um painel lateral dinâmico de IA, dividindo espaço com a ListView no `pnlCenter` usando o `splListview`. Também foram aplicados hotfixes visuais e de robustez de criação de controles.

### Versões internas (diluídas)
- **v2.1.6.10 (2026-03-31):** criação dinâmica de painel lateral de IA (`FConsumerAIPanel`) alinhado à direita, com header, área de conteúdo e botão `Close`; integração com `splListview`; checklist do modo Select reparent para `pnlCenter` para coexistência correta do layout.
- **v2.1.6.11 (2026-03-31):** redução de flicker na abertura/fechamento do painel via batching de layout (`DisableAlign/EnableAlign`) e redraw (`WM_SETREDRAW`) na área central/ListView, com repintura final controlada.
- **v2.1.6.12 (2026-03-31):** hotfix de `Control has no parent window` com ajuste da ordem de inicialização dos controles dinâmicos (definir `Parent` antes de propriedades que podem forçar handle).

### Implementações realizadas

- **Painel IA dinâmico:** métodos `EnsureConsumerAIPanel`, `ShowConsumerAIPanel`, `HideConsumerAIPanel` e `ConsumerAICloseClick` adicionados em `MainUnit.pas`.
- **Abertura por botão:** `btnConsumerAIClick` agora aciona a exibição do painel lateral em vez de permanecer vazio/comentado.
- **Divisão de espaço com ListView:** painel fixado em `alRight` dentro de `pnlCenter`, separado pelo `splListview` (comportamento solicitado: ListView ao centro e painel IA na lateral direita).
- **Fechamento por botão:** botão `Close` no header oculta o painel sem destruir estrutura, permitindo reabertura rápida.
- **Estabilidade visual e de janela:** mitigação de flicker e correção da exceção de parent window em cenários Delphi 7 + AlphaSkins.

### Arquivos impactados nesta etapa
| Arquivo | Alteração principal |
|---|---|
| `MainUnit.pas` | Painel IA dinâmico lateral, integração com splitter/layout do Read, botão Close, anti-flicker e hotfix de parent window |

---

## Atualização incremental — Refinos do painel IA (popup, repaint e i18n) (março/2026)

### Contexto
Esta etapa refinou a experiência do painel de IA: correção visual dos 4 botões rápidos com sobreposição de caption, novo menu de contexto no transcript e cobertura total de tradução para os textos de runtime do recurso.

### Versões internas (diluídas)
- **v2.1.6.13 (2026-03-31):** hotfix de repaint dos botões rápidos, menu de contexto no transcript (Selecionar tudo/Copiar/Exportar transcrição) e i18n completa dos textos do painel IA e mensagens de bridge.
- **v2.1.6.14 (2026-04-01):** refinamento i18n do painel IA para PT-BR/PT-PT com acentuação ANSI-safe (`#nnn`), inclusão explícita da chave `Send` para os 11 idiomas e reaplicação do caption do botão `Send` ao exibir o painel.

### Implementações realizadas

- **Hotfix visual dos botões rápidos:** troca para `TsButton` e reforço de ciclo de redraw (`Realign`, `Invalidate`, `Update`) para eliminar sobreposição de texto até hover.
- **Menu de contexto no transcript:** adicionados itens de popup com estado dinâmico (habilita/desabilita por seleção/conteúdo):
  - `Select all`
  - `Copy`
  - `Export transcript`
- **i18n completa do recurso IA:** textos do painel, status e erros de bridge convertidos para `TrText(...)` e registrados em todos os 11 idiomas suportados em `uI18n.pas`.
- **Consistência de runtime:** captions e labels do painel são reaplicados ao abrir/exibir, garantindo atualização correta após troca de idioma.

### Arquivos impactados nesta etapa
| Arquivo | Alteração principal |
|---|---|
| `MainUnit.pas` | Hotfix de repaint dos quick buttons, popup no transcript, handlers de copiar/selecionar/exportar, reaplicação de captions localizadas |
| `uI18n.pas` | Novas chaves e traduções do painel IA/bridge em todos os idiomas |

---

## 1. Botão de Busca (`btnSearch`) — Busca Direta pelo Texto

### Problema
O botão `btnSearch` não tinha evento `OnClick` atribuído. A busca exigia uso de `InputBox` (caixa de diálogo), o que era lento e pouco prático.

### Solução
- **Novo procedimento `btnSearchClick`** em `MainUnit.pas`:
  - Lê o texto diretamente de `edtSearch.Text` (sem `InputBox`).
  - Na primeira chamada, busca a partir do início do arquivo (posição 0).
  - Em chamadas subsequentes (como o F3), continua a busca a partir da última posição encontrada.
  - Define `FFindText` e `FFindCaseSensitive` e chama `StartFindFromPos`.
- **`edtSearchKeyPress`** foi atualizado: ao pressionar Enter no campo de busca, agora chama `btnSearchClick(Self)` em vez de `btnRead.Click`.
- **DFM:** Adicionado `OnClick = btnSearchClick` e `Hint = 'Search (Enter in search box)'` ao `btnSearch`.

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `MainUnit.pas` | Declaração e implementação de `btnSearchClick`; alteração em `edtSearchKeyPress` |
| `MainUnit.dfm` | `OnClick` e `Hint` do `btnSearch` |

---

## 2. Seleção Visual na `gotoLine`

### Problema
O procedimento `gotoLine` atribuía `ListView1.ItemIndex`, mas isso não garantia que o item ficasse visualmente selecionado e visível no ListView virtual.

### Solução
- Adicionada variável `TargetVisibleIdx`.
- Chamadas à API do Windows:
  - `ListView_SetSelectionMark` — marca o item como selecionado visualmente.
  - `ListView_EnsureVisible` — scrolla o ListView para que o item fique visível na tela.

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `MainUnit.pas` | Procedimento `gotoLine` aprimorado |

---

## 3. Divisão por Arquivos (`tabSplitByFiles`) — Merge de Lógica

### Problema
O botão `btnExecuteSplitFileByFiles` não tinha funcionalidade. A lógica já existia no arquivo `UnReadFileThread.pas` (pasta pai), no procedimento `btnExecuteFilesClick`, mas não estava integrada ao projeto `Src`.

### Solução
- **Novos tipos em `uSmoothLoading.pas`:**
  - `TSplitEntry` — record com campos `ID`, `FileName`, `SourceLine`, `TargetLine`.
  - `TSplitEntryArray` — `array of TSplitEntry`.
  - `TSplitFileThread` — thread completa para divisão de arquivos.
- **`TSplitFileThread` implementa:**
  - Construtor que recebe o caminho do arquivo fonte, diretório de saída, array de entradas e contagem.
  - `Execute` que usa `TMMFReader` (leitura mapeada em memória) + `TFileStream` (leitura do índice) + `TBufferedTextWriter` (escrita com buffer de 4 MB).
  - Progresso atualizado via `Synchronize` a cada 1024 linhas.
  - Tratamento de erros com `LogAsync` e exibição via `ShowMessage`.
  - Métodos sincronizados: `SyncShowLoading`, `SyncHideLoading`, `SyncSetProgress`, `SyncProgress`, `SyncError`, `SyncFinish`.
- **Novo procedimento `btnExecuteSplitFileByFilesClick`** em `MainUnit.pas`:
  - Lê os dados do dataset `clFiles` (campos `ID`, `Filename`, `SourceLine`, `TargetLine`).
  - Valida que SourceLine ≤ TargetLine e que os campos não estão vazios.
  - Monta o `TSplitEntryArray` e cria a thread.
- **DFM:** Adicionado `OnClick = btnExecuteSplitFileByFilesClick`.

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `uSmoothLoading.pas` | Tipos `TSplitEntry`, `TSplitEntryArray`, classe `TSplitFileThread` (declaração + implementação completa ~180 linhas) |
| `MainUnit.pas` | Declaração e implementação de `btnExecuteSplitFileByFilesClick` |
| `MainUnit.dfm` | `OnClick` do `btnExecuteSplitFileByFiles` |

---

## 4. Atalhos de Teclado para `btnUp` e `btnDown`

### Problema
Os botões `btnUp` (ir ao topo) e `btnDown` (ir ao final) só podiam ser acionados por clique com o mouse.

### Solução
- **`FormKeyDown`** em `MainUnit.pas`:
  - `Ctrl+Home` → chama `btnUpClick` (vai para a primeira linha).
  - `Ctrl+End` → chama `btnDownClick` (vai para a última linha).
- **Texto de ajuda** atualizado para incluir os novos atalhos.
- **DFM:** Adicionados `Hint` aos botões:
  - `btnUp`: `Hint = 'Go to top (Ctrl+Home)'`
  - `btnDown`: `Hint = 'Go to bottom (Ctrl+End)'`

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `MainUnit.pas` | `FormKeyDown` com tratamento de `Ctrl+Home`/`Ctrl+End`; texto de ajuda |
| `MainUnit.dfm` | `Hint` em `btnUp` e `btnDown` |

---

## 5. Otimização de Performance

### Problema
As funções de leitura do arquivo e do índice faziam múltiplos `Seek` e `Read` por chamada, e usavam alocação dinâmica de strings desnecessariamente.

### Otimizações realizadas

#### 5.1. `GetLineContent`
- **Antes:** 2 chamadas separadas de `Seek` + `Read` para ler os offsets da linha atual e da próxima.
- **Depois:** Uma única chamada `Seek` + `Read` de 40 bytes (2 registros de 20 bytes consecutivos).
- **Buffer:** Trocada alocação dinâmica (`string`) por buffer em stack: `OffsetBuf: array[0..39] of AnsiChar`.

#### 5.2. `GetLineStartOffset`
- **Antes:** Alocação dinâmica de string para o offset.
- **Depois:** Buffer em stack: `OffsetBuf: array[0..19] of AnsiChar`.

#### 5.3. `ListView1Data`
- Adicionado early exit se `FSourceFileStream` não estiver atribuído.
- Pré-construção do conteúdo antes de atribuir aos `SubItems`, evitando processamento desnecessário.

### Impacto
Redução significativa de chamadas ao sistema de arquivos e de alocações no heap, resultando em scroll mais suave e resposta mais rápida em arquivos grandes.

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `MainUnit.pas` | `GetLineContent`, `GetLineStartOffset`, `ListView1Data` |

---

## 6. Divisão por Linhas (`tabSplitByLines`)

### Problema
A aba `tabSplitByLines` existia no form mas não tinha funcionalidade implementada para o botão de execução.

### Solução
- **Novo procedimento `btnExecuteSplitFileByLinesClick`** em `MainUnit.pas`:
  - Lê os valores de `spnFromSplitByLine` (linha inicial) e `spnToSplitByLine` (linha final).
  - Lê o nome do arquivo de saída de `edtOutputSplitByLineText`.
  - Valida os inputs (arquivo existe, linhas válidas, nome de saída não vazio).
  - Resolve o diretório de saída: usa o caminho do arquivo de saída se especificado, senão usa o diretório do arquivo fonte.
  - Cria uma entrada `TSplitEntry` única e chama `TSplitFileThread.Create`.
- **`tabSplitFileShow`** atualizado para definir `MinValue` e `MaxValue` dos spin edits (`spnFromSplitByLine`, `spnToSplitByLine`) baseado no total de linhas do arquivo carregado.
- **DFM:** Adicionado `OnClick = btnExecuteSplitFileByLinesClick`.

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `MainUnit.pas` | Declaração e implementação de `btnExecuteSplitFileByLinesClick`; `tabSplitFileShow` |
| `MainUnit.dfm` | `OnClick` do `btnExecuteSplitFileByLines` |

---

## 7. Correção de Bug — `TSplitFileThread` (Caminho de Saída)

### Problema identificado durante verificação
O `TSplitFileThread` usava `FOriginalFileName` para **duas finalidades distintas**:
1. Abrir o arquivo fonte via `TMMFReader.Create(FOriginalFileName)`.
2. Derivar o diretório de saída via `ExtractFilePath(FOriginalFileName) + FEntries[e].FileName`.

Isso significava que, se o chamador passasse um caminho diferente do arquivo real (por exemplo, para direcionar a saída a outro diretório), o `TMMFReader` falharia ao tentar abrir o arquivo.

### Solução
- Adicionado campo `FOutputDir: String` à classe `TSplitFileThread`.
- Construtor atualizado para receber o parâmetro `AOutputDir` separadamente.
- `Execute` agora usa `FOutputDir + FEntries[e].FileName` para o caminho de saída.
- `FOriginalFileName` é usado **exclusivamente** para abrir o arquivo fonte.
- Ambos os chamadores (`btnExecuteSplitFileByFilesClick` e `btnExecuteSplitFileByLinesClick`) atualizados para passar os parâmetros corretos.

### Arquivos alterados
| Arquivo | Alteração |
|---|---|
| `uSmoothLoading.pas` | Campo `FOutputDir`, construtor, `Execute` |
| `MainUnit.pas` | Ambos os chamadores de `TSplitFileThread.Create` |

---

## Resumo das Dependências

O `TSplitFileThread` utiliza componentes já existentes no projeto:

| Componente | Arquivo | Função |
|---|---|---|
| `TMMFReader` | `uMMF.pas` | Leitura de arquivo via memory-mapped file |
| `TBufferedTextWriter` | `UnBufferedTextWriter.pas` | Escrita em buffer de 4 MB |
| `LogAsync` | `ThreadFileLog.pas` | Log assíncrono de erros |
| `ForceDeleteFile` | `uSmoothLoading.pas` | Remoção segura de arquivos |
| `TfrmSmoothLoading` | `uSmoothLoading.pas` | UI de loading com barra de progresso |
| `INDEX_REC_SIZE` | `MainUnit.pas` | Constante = 20 (tamanho do registro no índice) |

---

## Arquitetura do Índice de Linhas

Para referência, o FastFile mantém um arquivo de índice (`temp.txt`) onde cada linha do arquivo fonte é representada por um registro de 20 bytes:

```
[18 chars: offset em texto] + [2 bytes: padding (CR+LF)]
```

- **Offset**: posição em bytes do início da linha no arquivo fonte (1-based no arquivo, convertido para 0-based na leitura com `StartOffset - 1`).
- **Leitura**: `Seek(LineIndex * 20)` + `Read(18 bytes)` → `StrToInt64` → posição no arquivo fonte.
- **Constante**: `INDEX_REC_SIZE = 20`.

---

## Tabela Resumo de Alterações por Arquivo

| Arquivo | Qtd. de alterações | Principais mudanças |
|---|---|---|
| `MainUnit.pas` | ~12 edições | 3 novos procedimentos, 3 otimizações, atalhos de teclado, ajuda, correções |
| `MainUnit.dfm` | ~5 edições | `OnClick` e `Hint` em 5 botões |
| `uSmoothLoading.pas` | ~6 edições | Novos tipos (`TSplitEntry`, `TSplitEntryArray`), classe `TSplitFileThread` completa (~180 linhas), campo `FOutputDir` |

---

## Word wrap visual no ListView — v2.1.0.6 / v2.1.6.1 / v2.1.6.2 / v2.1.6.3 / v2.1.6.4 (março/2026)

### Objetivo
Quebra de linha **só visual** na coluna **Content**, sem reindexar o arquivo (`FastWordWrapAtivo` permanece desligado nesse modo).

### Abordagem
- **`TImageList` “dummy”** (`FWordWrapRowImages`) em `SmallImages` com altura ~4 linhas (`ApplyWordWrapRowHeight`) para o ListView aumentar a altura da linha.
- **`ListView1AdvancedCustomDrawSubItem`**: na coluna 1 (Content), `Windows.DrawText` com `DT_WORDBREAK` + cores de seleção/bookmark.
- **`ListView1Data`**: ordem normal `Line #` | `Content`; `Item.ImageIndex := 0` quando o wrap visual está ativo (para alinhar com o `SmallImages`).
- **Destaque de busca** no modo wrap visual: desativado na coluna Content (o desenho de uma linha só conflita com o texto quebrado).

### Ajustes adicionais (MRU e atalho)
- **Arquivos recentes (Ctrl+R):** se o caminho escolhido não existir mais, mensagem em português + remoção da entrada em `FRecentFiles` e gravação do `mru_files.ini`.
- **Word wrap:** atalho **Ctrl+W** alterna o checkbox; hint no `chkWordWrap` e linha na ajuda (F1).

### Exportação (`btnExport`) e editor de linha (março/2026)
- **Export:** `TExportFileThread` passava `ListView1.Items.Count` (linhas **visíveis** no virtual list) como limite; corrigido para o total indexado (`totalLines` / `IndexFileLineCount`). Offsets do índice passam a usar **`Abs`** como em `GetLineContent` (segmentos negativos no índice). Overlay `slmExportLines` usa `frmMain.IndexFileLineCount`.
- **`uLineEditor`:** ao confirmar, caixa **Sim/Não** descrevendo a operação (inserir/editar/excluir) e linha; **Não** como botão por omissão (`MB_DEFBUTTON2`).
- **Codificação (Delphi 7 / ANSI):** nova unit `uTextEncoding.pas` — confirmação do editor com **`MessageBoxW`** e textos PT em **UTF-8 literal**; `GetLineContent` usa conversão **UTF-8 → Unicode → CP_ACP** quando o ficheiro é detectado como UTF-8 (BOM ou heurística nos primeiros 16 KB). Sem BOM, ficheiros só ASCII ou Latin-1 válido sem sequências UTF-8 ficam como **ANSI**.
- **Exibição dinâmica (estilo Notepad++):** combo **`comboViewEncoding`** no **último painel da `sStatusBar1`** (filho do control), posicionado por **`LayoutViewEncodingCombo`** em resize/show/skin — evita duplicar com texto no painel. Opção **`DEFAULT (detected)`** segue a detecção; força **UTF-8**, **ANSI**, **UTF-16 LE/BE** só na **ListView**. **Hook** `HookedStatusBarWndProcForCombo` na status bar para **`CBN_CLOSEUP`** (skins / mesmo item). *Hint* do combo resume ficheiro detectado + vista.
- ~~Clique no painel para ciclar encoding~~ removido: uso direto do combo no painel.



