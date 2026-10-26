# Documentação: modelos de IA nos programas Consumer AI / host FastFile

Este documento descreve **qual modelo de linguagem** cada variante do programa utiliza, **como a autenticação funciona** e **como alterar o modelo**. Não inclua chaves reais em repositórios públicos; use variáveis de ambiente ou `.env` local (e mantenha `.env` fora do Git).

Para o guia detalhado dos EXEs Python (ConsumerAI / ConsumerRAG / parâmetros CLI), ver também `data-lake-duckdb-main\DOCUMENTACAO_MODELOS_IA.md` quando a pasta de fontes Python estiver presente.

---

## 1. Papel da IA nos diferentes programas

| Programa | Papel da IA |
|----------|-------------|
| `ConsumerAI.py` / `ConsumerAI.exe` | **NL → SQL (DuckDB)** sobre dados tabulares; o programa executa o SQL. |
| `ConsumerRAG.py` / `ConsumerRAG.exe` | **Resposta em linguagem natural** com trechos recuperados (RAG / FastTextRAG). **Não usa SQL.** |
| Assistente FastFile (Ctrl+Alt+A) | Comandos locais + compose (docs/código) via gateway HTTPS opcional; **não** é Consumer SQL. |

### 1.1 Aplicação host FastFile (Delphi)

O editor **FastFile.exe** não executa estes modelos Python directamente; serve como **host** para integrações (`ConsumerAI.exe` / `ConsumerRAG.exe` / `ScriptEngine.exe`) e para o **Assistente IA** (`uFastFileAssistant*.pas`, `uFastFileAIClient.pas`).

**Versão publicada do EXE:** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.243`** (23/10/2026).

Trilhos recentes no host Delphi (IA / i18n / arranque):

- **★ v3.0.5.243:** arquivo opcional em `grep "casa"` / `glob "*.txt"` usa o campo principal; um caminho explícito é validado/carregado antes da execução GUI. Ferramentas do modelo/diagnóstico só podem restringir suas fontes autorizadas, nunca ampliá-las. Leitura por blocos, cancelamento, limite de resultados e erro explícito acima de 16.777.216 caracteres decodificados por linha. Testes esparsos de 80 GiB, não benchmark de leitura integral.
- **★ v3.0.5.242:** `grep`/`glob` isolados abrem exemplos sem provedor/varredura; botões próprios em Localizar, Filtro e Marcadores. Comandos digitados no Assistente/agente usam a ponte local; diagnóstico mantém suas fontes/configurações e é somente leitura (inventário só glob; sem `--mark`/`--bookmarks`). «O que posso fazer?» e F1 cobrem o recurso nos 14 idiomas.
- **★ v3.0.5.241:** IA no modal (`SearchCommandPrompt` / `ParseSearchCommandAdvice`): mesmo gateway, nenhum modelo/provedor novo; só pedido e comando atual enviados, sem conteúdo/lista de fontes. JSON estrito com comando, explicação e até três sugestões; ambiguidade pede esclarecimento. Gerar não executa: revisão e **Executar comando** obrigatórios; erros visíveis. Testes usam provedor injetado, sem chamada remota.
- **★ v3.0.5.240:** comandos internos `glob` para caminhos e `grep` para conteúdo literal ou PCRE; `search_command` somente leitura no agente/diagnóstico e `apply_filter` no Assistente/janela principal. Sem shell; limites globais e resultado parcial não significam total exato. [Guia de comandos](README.md#internal-glob--grep-commands).
- **★ v3.0.5.239:** **Diagnóstico IA** (Ctrl+Alt+U; `uAgentHub` / `uAgentHubWorkspace` / `uAgentDiscovery`): especialistas somente leitura (inventário, estrutura, conteúdo, SQL, privacidade, ações) via o mesmo gateway (`FastFileAIInvokePrompt`). Nada é gravado; edições ficam no agente. «O que posso fazer?» também nesta aba. F1 `FF_HELP.RecentFeaturesBlock3`.
- **★ v3.0.5.238:** seletor de várias pastas (`uFolderPickDlg`); lista **«O que posso fazer?»** (`uAICapabilitiesDlg`) no Assistente, no agente e no diagnóstico — exemplo por capacidade, Usar exemplo / Perguntar à IA.
- **★ v3.0.5.237:** `describe_files` (`uAgentDescribe`) perfil do ficheiro sem leitura integral; o pedido escolhe os ficheiros por nome, posição ou tipo nos 14 idiomas (`uAgentTargets`); macro Python por linha após Aceitar, com prévia, sem alterar o original.
- **★ v3.0.5.236:** validação de código sem os companions do ScriptEngine (`uSourceValidators`): JSON / HTML / SQL no processo; Java (`javac`), Go (`gofmt`) e C# (`csc`) no compilador local, sem executar o código. Ajuda **«Código-fonte com IA»** (`uSourceCodeHelpDlg`).
- **★ v3.0.5.232:** agente — prazo para Aceitar/Rejeitar (20 s, 5..600 s nas Preferências) com distintivo de tempo; «Substituir tudo» conta antes (0 ocorrências = nada proposto); mensagem honesta quando o modelo afirma trabalho que não colocou na fila; respostas do agente e de «Fale com a IA» no idioma da UI (`AssistantLangPromptName` em `uI18n`); parser aceita `"tool":{"<nome>":{...}}`; F1 `FF_HELP.RecentFeaturesBlock2`.
- **★ v3.0.5.231:** agente — SQL directo sem IA (`uAgentSql`: SELECT/GROUP BY/ORDER BY/SUM/COUNT; UPDATE/DELETE/INSERT/ALTER como propostas); palavra inteira vs parcial em 14 idiomas (`uAgentMatchIntent`); modo «Agente» no painel do Assistente.
- **★ v3.0.5.230:** edições aceites pelo streaming do core (`uAgentPatch`); ferramentas do agente lêem UTF-16.
- **★ v3.0.5.229:** novo **agente de IA sobre ficheiros** (Ctrl+Alt+G; `uAgentWorkspace` / `uAgentLoop` / `uAgentProtocol` / `uAgentTools` / `uAgentActions` / `uAgentBridge`): ciclo modelo → ferramenta (contar, procurar, ler, editar, anonimizar, acções do core) → propostas revistas pelo utilizador; separador «Prompt revisto».
- **★ v3.0.5.227:** anonimizar dados (`uAnonymize`) — também disponível como ferramenta do agente.
- **★ v3.0.5.225:** sync F1 (`FF_HELP.RecentFeaturesBlock`) / Version History / docs; 17 units UTF-8 com BOM; mensagens de tempo traduzidas.
- **★ v3.0.5.224:** histórico de sessão — **Perguntar à IA** sobre os eventos / linhas alteradas marcados (além de exportar TXT/CSV, ordenar e filtro por período).
- **★ v3.0.5.223:** editor de linha — botão **Perguntar à IA** (Ctrl+Shift+A) sobre o conteúdo da linha.
- **★ v3.0.5.218:** texto do pipeline do Assistente correcto após trocar a partir do chinês.
- **★ v3.0.5.212:** pipeline **AI-First pós-acção** (`uAssistantPostAction`): chips «E agora?» + rascunho de pergunta IA; memória-ponte `uAssistantPipelineStore` (`assistant_pipeline.bridge`, até 24 turnos / 16 actividades) para o modelo continuar de onde parou.
- **★ v3.0.5.210:** lazy-load i18n (inglês + idioma activo no arranque); sync F1 / Version History / docs; **14 idiomas** de UI.
- **★ v3.0.5.209:** chinês simplificado (`zh-CN`) + tradicional (`zh-TW`) — 13.º/14.º idiomas; cobertura completa `Set14`.
- **★ v3.0.5.208:** `PutNV` O(n) + collapse/sort (arranque sem `TStringList.Values` O(n²)).
- **★ v3.0.5.207:** japonês (`ja`) — 12.º idioma UI.
- **★ v3.0.5.100:** FilterBar (Ctrl+L), toggles na status bar, `count_matching_lines`, chrome do assistente.
- **★ v3.0.5.0:** compose (Word/RTF/DOCX/ODT/PDF + código), `fastfile_assistant\`, trava de segurança; F1 **`FF_HELP.AssistantBlock`**.
- **★ v3.0.4.0:** Chat IA avançado (arquivo) em GB+ (FastTextRAG); scroll dos chats; acentuação comparar/mesclar.
- **★ v3.0.3.0:** host Win64 + indexação SWAR; F1 **`FF_HELP.Win64IndexBlock`**.

Idiomas de UI (combo + Assistente):  
`en | pt-BR | pt-PT | es | fr | de | it | pl | ro | hu | cs | ja | zh-CN | zh-TW`.

Ver **`CHANGELOG_IMPLEMENTACOES.md`**, **`README.md`**, **`ROADMAP_COMERCIAL_FASTFILE.md`**.

---

## 2. Notas de autenticação / modelo (resumo)

- **Gateway FastFile AI** (assistente / Talk with AI): HTTPS POST JSON (`prompt` → `resposta`); URL e regras em **`UnConsts`** / **`uFastFileAIClient.pas`**.
- **ConsumerAI / ConsumerRAG:** modelos e chaves via variáveis de ambiente / `.env` nos fontes Python — **não** gravar segredos no repositório Git do host.

---

## 3. Histórico de sync deste documento

| Data | Versão host | Nota |
|------|-------------|------|
| 2026-10-23 | **3.0.5.243** | Trilhas .240–.243: glob/grep, IA no modal, acesso local, arquivo opcional, limites GB e autorização das fontes; F1 e histórico sincronizados |
| 2026-10-22 | **3.0.5.239** | Diagnóstico IA somente leitura; describe_files e alvos do pedido; macro Python por linha; validação JSON/HTML/SQL/Java/Go/C#; «O que posso fazer?» |
| 2026-10-08 | **3.0.5.232** | Agente de IA sobre ficheiros (SQL / linguagem natural, propostas com prazo, respostas no idioma da UI); anonimizar dados |
| 2026-09-27 | 3.0.5.225 | Pipeline pós-acção + memória-ponte; Perguntar à IA no editor de linha e no histórico de sessão |
| 2026-09-16 | 3.0.5.210 | 14 idiomas + lazy-load; ponteiro para pasta `data-lake-duckdb-main` se existir |
| 2026-09-06 | 3.0.5.100 | FilterBar / assistente polish |
| 2026-08-29 | 3.0.5.0 | Compose + `FF_HELP.AssistantBlock` |
