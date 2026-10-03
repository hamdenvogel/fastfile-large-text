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

**Versão publicada do EXE:** **`UnConsts.APPLICATION_VERSION`** **`3.0.5.225`** (27/09/2026).

Trilhos recentes no host Delphi (IA / i18n / arranque):

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
| 2026-09-27 | **3.0.5.225** | Pipeline pós-acção + memória-ponte; Perguntar à IA no editor de linha e no histórico de sessão |
| 2026-09-16 | 3.0.5.210 | 14 idiomas + lazy-load; ponteiro para pasta `data-lake-duckdb-main` se existir |
| 2026-09-06 | 3.0.5.100 | FilterBar / assistente polish |
| 2026-08-29 | 3.0.5.0 | Compose + `FF_HELP.AssistantBlock` |
