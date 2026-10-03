# FastFile Assistant — Checklist de testes (QA)

**Versão:** **3.0.0.0** (FastFile 3.0)  
**Data:** 2026-05-23  
**Âmbito:** assistente operacional (sem código-fonte no prompt/resposta)

---

## Pré-requisitos

- [ ] Rede e endpoint `grod_prod_lambda` acessível
- [ ] `ASkin.ini` na pasta do EXE (opcional: `AssistantShowOnStartup`, `AssistantLog`)
- [ ] Ficheiro de teste pequeno (ex. alguns MB) com caminho completo Windows

---

## Arranque e menu

- [ ] **AI → Assistente FastFile...** abre o diálogo
- [ ] Com `AssistantShowOnStartup=1`, assistente no arranque (boas-vindas)
- [ ] Checkbox *Não mostrar na inicialização* grava `AssistantShowOnStartup=0`
- [ ] F1 inclui linha sobre o assistente (bloco `FF_HELP.AssistantBlock`)

---

## Intenção explain

- [ ] Pergunta: *Como divido um ficheiro em partes iguais?* → resposta operacional, sem botão Executar
- [ ] Pergunta sobre Consumer SQL → explica que é **Ctrl+Shift+A** / **Ctrl+Alt+R**, distinto do assistente

---

## Ações simples (execute + confirmação)

- [ ] `show_tab_read` — abre ecrã Ler ficheiro
- [ ] `show_tab_recent` — abre Recentes
- [ ] `show_help` — F1
- [ ] `open_find` — Localizar
- [ ] `open_replace` — Substituir
- [ ] `start_tail` — activa Tail (se já activo, não deve falhar)
- [ ] `show_tab_compare` — aba Comparar/mesclar

---

## Ficheiro e split

- [ ] `open_and_read_file` com path válido → leitura inicia
- [ ] Path inválido → mensagem traduzida, Executar desactivado
- [ ] `split_equal_parts` com ficheiro aberto, `parts=5` → diálogo de split
- [ ] `extract_file_parts` com `total_parts=10`, `part_from=2`, `part_to=4` → extracção

---

## Cadeia (ler → dividir)

- [ ] Pedido: *Abrir C:\...\ficheiro.txt e dividir em 5 partes iguais*
- [ ] Após confirmação: leitura começa; mensagem *ação seguinte após leitura*
- [ ] Quando a leitura termina, split inicia automaticamente (sem segundo clique)

---

## Erros e robustez

- [ ] Sem rede → `Assistant.Error.Network`
- [ ] Resposta IA fora de JSON → mensagem legível / validação falha
- [ ] `AssistantLog=1` → `Assistant.log` com entradas de reply/execute

---

## FastFile 3.0 — comandos locais e atalhos

- [ ] «filtrar linhas com X e exportar para txt» → filtro + export (ficheiro se grande)
- [ ] «substituir tudo A por B» → Replace All (confirmação)
- [ ] «apagar última linha» com filtro activo → apaga linha física; ListView actualiza sem F5
- [ ] «dividir em 3 partes» / «extrair 1/3» → diálogo ou acção local
- [ ] Foco no memo do assistente: **Ctrl+H**, **Ctrl+L**, **Ctrl+Shift+L**, **Ctrl+Z/Y** (undo ficheiro)
- [ ] **Ctrl+V** no memo → colar linhas no ficheiro (não só texto do memo)

## Ações expandidas (v2.1.7.31+, integradas em 3.0)

- [ ] `open_filter` / `apply_filter` com `filter_text` (ex. *ERROR*)
- [ ] `clear_filter` com filtro activo
- [ ] `export_file` e `export_filtered`
- [ ] `delete_duplicate_lines` (ficheiro gravável)
- [ ] `extract_frequent_strings`
- [ ] `show_checkboxes`, `goto_line` com `line_no`, `character_code_value`
- [ ] `show_tab_merge_lines`, `show_tab_merge_files`, `toggle_word_wrap`
- [ ] Cadeia: abrir ficheiro → `apply_filter` com texto

## Validar fonte (v3.0.5.136+)

Ver [`DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md).

- [ ] Compose `.py` → botão **Validar** → OK / ERROR com linha (`ScriptEngine --validate`)
- [ ] Compose `.js` / `.ts` / `.tsx` → **Validar** → `CodeCheck.exe`
- [ ] Compose `.pas` / `.java` → botão **Validar** oculto
- [ ] Chat: *quais linguagens valida?* → lista Python / JS / JSX / TS / TSX
- [ ] Chat: *carregar o fonte pra validar* → diálogo filtrado → validação
- [ ] Chat: path com extensão não suportada → Unsupported + lista (sem companion)
- [ ] Chat: `validar C:\...\ficheiro.py` existente → relatório no reply
- [ ] Sem `CodeCheck.exe` / `ScriptEngine.exe` → download FTP ou `ExeMissing`

## i18n

- [ ] Alterar idioma da app → títulos/botões/erros do assistente traduzidos (11 idiomas)

---

## Regressão

- [ ] Consumer AI (Chat/RAG) inalterado
- [ ] Leitura F5 manual normal após usar assistente
