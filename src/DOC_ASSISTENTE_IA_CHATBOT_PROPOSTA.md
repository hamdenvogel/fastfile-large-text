# FastFile — Proposta: Assistente IA (chatbot) na inicialização

**Nome curto:** `DOC_ASSISTENTE_IA.md` (este ficheiro: `DOC_ASSISTENTE_IA_CHATBOT_PROPOSTA.md`)

**Documento para análise** — não descreve código já implementado; consolida requisitos, arquitetura, riscos e plano de entrega.  
**Data:** 23 de maio de 2026  
**Versão de referência do host:** **`3.0.0.0`** — FastFile 3.0 (`UnConsts.APPLICATION_VERSION`)  
**Ambiente:** Delphi 7 / Win32  

> **Documentos relacionados**  
> - [README.md](README.md) — visão geral e unidades (`uFastFileAIClient`, Consumer AI)  
> - [DOCUMENTACAO_MODELOS_IA.md](data-lake-duckdb-main/DOCUMENTACAO_MODELOS_IA.md) — modelos Python vs gateway FastFile  
> - [DOC_ZS_ATALHOS.md](DOC_ZS_ATALHOS.md) — atalhos (parte da base de conhecimento candidata)  
> - [DOC_ASSISTENTE_IA_VALIDAR_FONTE.md](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md) — validar sintaxe de fontes (Python/JS/TS/…)  
> - [CHANGELOG_IMPLEMENTACOES.md](CHANGELOG_IMPLEMENTACOES.md) — histórico de releases  

---

## Índice

1. [Objetivo e motivação](#1-objetivo-e-motivacao)  
2. [Requisitos (resumo do pedido)](#2-requisitos-resumo-do-pedido)  
3. [O que o FastFile já tem hoje](#3-o-que-o-fastfile-ja-tem-hoje)  
4. [Por que não basta “só um chat” com o Lambda](#4-por-que-nao-basta-so-um-chat-com-o-lambda)  
5. [Arquitetura proposta (3 camadas)](#5-arquitetura-proposta-3-camadas)  
6. [Base de conhecimento](#6-base-de-conhecimento)  
7. [Formato de resposta e catálogo de ações](#7-formato-de-resposta-e-catalogo-de-acoes)  
8. [Executor Delphi (exemplos 2.2–2.6)](#8-executor-delphi-exemplos-22-26)  
9. [Interface: chat na inicialização](#9-interface-chat-na-inicializacao)  
10. [Integração com o endpoint AWS](#10-integracao-com-o-endpoint-aws)  
11. [Internacionalização (11 idiomas)](#11-internacionalizacao-11-idiomas)  
12. [Segurança e limites](#12-seguranca-e-limites)  
13. [“Possibilidades infinitas” — expectativa realista](#13-possibilidades-infinitas--expectativa-realista)  
14. [Plano de implementação por fases](#14-plano-de-implementacao-por-fases)  
15. [Unidades e ficheiros sugeridos](#15-unidades-e-ficheiros-sugeridos)  
16. [Riscos e perguntas em aberto](#16-riscos-e-perguntas-em-aberto)  
17. [Checklist para aprovação antes de codificar](#17-checklist-para-aprovacao-antes-de-codificar)  

---

## 1. Objetivo e motivação

Permitir que o utilizador descreva em **linguagem natural** o que pretende fazer no FastFile (por exemplo: abrir um ficheiro, ir à aba de leitura, dividir um ficheiro em N partes), e o programa:

1. **Interpreta** o pedido com apoio de IA (endpoint AWS já usado pelo produto).  
2. **Responde** apenas no âmbito do que o FastFile sabe fazer (base de conhecimento da aplicação).  
3. **Executa** ações concretas no host Delphi quando forem válidas e, se necessário, após confirmação do utilizador.

A experiência desejada inclui um diálogo ao **iniciar** a aplicação, com uma pergunta do tipo: *“O que deseja fazer?”* — opcional e configurável, para não incomodar utilizadores avançados.

---

## 2. Requisitos (resumo do pedido)

| # | Requisito |
|---|-----------|
| 1 | Chatbot (ou assistente) quando o programa é inicializado, usando IA. |
| 2 | Consumir o endpoint `https://avylzxs9u3.execute-api.us-east-2.amazonaws.com/default/grod_prod_lambda`. |
| 2.1 | Respostas **limitadas** à base de conhecimento do próprio FastFile (capacidades, menus, atalhos, fluxos). |
| 2.2 | Utilizador pede tarefas com as suas palavras. |
| 2.3 | O programa **executa** a tarefa (ex.: ler ficheiro `C:\...\arquivo.txt` de verdade). |
| 2.4 | Ex.: *“Quero que o programa abra a tela de carregar arquivos”*. |
| 2.5 | Ex.: *“Ler o ficheiro X e depois dividir em 5 partes”* (cadeia de ações). |
| 2.6 | Muitas combinações possíveis, mas sempre dentro do que o app suporta. |
| 3 | Traduzir textos do assistente (UI + prompts onde fizer sentido) para os **11 idiomas**, com acentuação/codificação corretas (`uI18n`, padrão `#231` / concatenação Delphi 7). |

---

## 3. O que o FastFile já tem hoje

### 3.1 Gateway HTTPS (mesmo endpoint do pedido)

Em `UnConsts.pas`:

```pascal
FASTFILE_AI_GATEWAY_URL =
  'https://avylzxs9u3.execute-api.us-east-2.amazonaws.com/default/grod_prod_lambda';
FASTFILE_AI_GATEWAY_HOST = 'avylzxs9u3.execute-api.us-east-2.amazonaws.com';
FASTFILE_AI_GATEWAY_PATH = '/default/grod_prod_lambda';
FASTFILE_AI_JSON_FIELD_PROMPT = 'prompt';
FASTFILE_AI_JSON_FIELD_RESPOSTA = 'resposta';
```

A unidade **`uFastFileAIClient.pas`** expõe `FastFileAIInvokePrompt(APrompt, AAnswer, AErrMsg)`:

- Transporte: **WinInet**, HTTPS POST.  
- Corpo: `{"prompt":"<texto escapado UTF-8>"}`.  
- Resposta: campo JSON `resposta` ou `Resposta`.  
- Timeout: `FASTFILE_AI_GATEWAY_TIMEOUT_MS` (120 s).

### 3.2 Usos actuais da IA no host (consultivos)

| Fluxo | Unidade | Papel |
|-------|---------|--------|
| Split por padrão / Regex — “Falar com a IA” | `uFastFileAIScreenHelp.pas` | Modal; prompt montado em código (`AI_PROMPT_RULES_*`); resposta **texto** para colar no campo Pattern |
| Macro Python / Tail — ajuda IA | `uFastFileAIPythonMacroHelp.pas` | Idem, âmbito macro/script |
| Consumer AI | `UnConsumerAI.pas`, `ConsumerAI.exe` | **NL → SQL** sobre dados tabulares; **não** opera o editor de linhas |

**Conclusão:** o canal de rede **já existe**; falta a camada **intenção → validação → execução** e a **base de conhecimento** estruturada.

### 3.3 Capacidades executáveis já no código (sem IA)

Exemplos de pontos de entrada reutilizáveis pelo executor (não exaustivo):

- Abrir / ler ficheiro: `BeginRead`, `OpenFileStreams`, `miOpenFileClick`, F5.  
- Abas: `pgMain`, `tabReadFile`, `tabSplitByPatternTab`, `tabMerge`, Recent Files, etc.  
- Dividir: partes iguais (LF), padrão/regex, extrair partes (`Ctrl+Shift+Q`).  
- Ferramentas EmEditor: extrair frequentes, remover duplicados (`uEmEditorFeatures.pas`).  
- Sessão somente leitura, Tail, Find/Replace, Zero Scan, ops. segmentadas.

O assistente deve **chamar** estes fluxos, não reimplementá-los.

---

## 4. Por que não basta “só um chat” com o Lambda

1. **Alucinação:** modelos podem inventar menus, atalhos ou ficheiros inexistentes.  
2. **Segurança:** texto livre não deve disparar escrita em disco ou paths arbitrários sem validação.  
3. **Contrato API:** hoje só se envia `prompt`; a execução tem de ser **no Delphi**, com whitelist.  
4. **Delphi 7:** prompts enormes (KB inteira + F1) podem bater limites de string/compilador — é preciso resumir ou segmentar.  

**Princípio:** a IA **sugere** um plano estruturado; o programa **valida e executa**.

---

## 5. Arquitetura proposta (3 camadas)

```
┌─────────────────────────────────────────────────────────────┐
│  Utilizador (linguagem natural, 11 idiomas na UI)           │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Camada 1 — UI (chat modal / painel)                        │
│  - Boas-vindas: "O que deseja fazer?"                       │
│  - Histórico curto da conversa                              │
│  - Confirmação antes de ações destrutivas                   │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Camada 2 — Orquestração + KB                               │
│  - Monta prompt: regras + catálogo de ações + estado app    │
│  - FastFileAIInvokePrompt → Lambda                          │
│  - Parse JSON da resposta (não texto livre para executar)   │
└───────────────────────────┬─────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Camada 3 — Validador + Executor                            │
│  - action ∈ whitelist; params tipados; paths existem?       │
│  - Chama MainUnit / handlers existentes                     │
│  - Relata sucesso/erro à UI (TrText)                        │
└─────────────────────────────────────────────────────────────┘
```

Thread em background para o POST (padrão `TAISplitRegexThread` em `uFastFileAIScreenHelp.pas`), com `Synchronize` para actualizar a UI.

---

## 6. Base de conhecimento

### 6.1 Conteúdo candidato

| Fonte | Conteúdo | Uso no prompt |
|-------|----------|----------------|
| **Catálogo de ações** (novo, mantido em código) | IDs, parâmetros, pré-condições, atalhos | Fonte da verdade para execução |
| **F1 / `FF_HELP.*`** | Atalhos, Zero Scan, Ferramentas | Explicação ao utilizador |
| **README / DOC_*.md** (trechos) | Princípios, limites GB+ | Contexto; versão resumida |
| **Estado runtime** (opcional) | Ficheiro aberto, aba, idioma, RO | Desambiguação (“este ficheiro”, “dividir o que está aberto”) |

### 6.2 Regras no prompt (exemplo)

- Responder **somente** com JSON no esquema definido (secção 7).  
- Se o pedido não corresponder a nenhuma `action` do catálogo → `action: "unknown"` + mensagem educativa.  
- Não inventar caminhos de ficheiro: extrair paths **literalmente** da frase do utilizador.  
- Não sugerir SQL, shell, ConsumerAI, nem operações fora do catálogo.  
- Idioma da mensagem ao utilizador: conforme `TrText` / instrução `AI_PROMPT_REPLY_LANG` (precedente no split).  

### 6.3 RAG (fase opcional)

Se o catálogo + resumo de ajuda não couber no prompt:

- Índice local de parágrafos (F1, DOC) com palavras-chave ou embeddings offline;  
- Enviar ao Lambda só os **top-K** trechos relevantes à pergunta.  

Para MVP, um **catálogo compacto** (2–4 KB) costuma bastar.

---

## 7. Formato de resposta e catálogo de ações

### 7.1 Resposta JSON (contrato sugerido)

**Ação simples:**

```json
{
  "action": "open_and_read_file",
  "params": {
    "path": "C:\\Hamden\\Files\\exemplo.txt"
  },
  "confirm": true,
  "user_message": "Vou abrir e ler esse ficheiro."
}
```

**Cadeia (ex. 2.5):**

```json
{
  "actions": [
    {
      "action": "open_and_read_file",
      "params": { "path": "C:\\Hamden\\Files\\xxxxxx.txt" }
    },
    {
      "action": "split_equal_parts",
      "params": { "parts": 5 }
    }
  ],
  "confirm": true,
  "user_message": "Primeiro leio o ficheiro; depois divido em 5 partes iguais (LF)."
}
```

**Fora do âmbito:**

```json
{
  "action": "unknown",
  "user_message": "Isso não é uma função do FastFile. Posso ajudar a abrir ficheiros, dividir, filtrar, Tail, etc. (F1)."
}
```

### 7.2 Exemplo de entradas no catálogo (MVP → expansão)

| `action` | Descrição | Parâmetros | Pré-condição |
|----------|-----------|------------|--------------|
| `open_and_read_file` | Abrir e ler (F5) | `path` (string) | Ficheiro existe |
| `show_tab_read` | Aba “Ler ficheiro” | — | — |
| `show_tab_recent` | Arquivos recentes | — | — |
| `show_help` | Ajuda F1 | — | — |
| `split_equal_parts` | Partes iguais LF | `parts` (int ≥ 2) | Ficheiro carregado |
| `extract_file_parts` | Subconjunto de partes | `from`, `to` | Ficheiro carregado |
| `start_tail` | Tail / Follow | — | Ficheiro carregado |
| `open_find` | Localizar Ctrl+F | — | — |
| `toggle_readonly_session` | Sessão RO | — | — |

Cada entrada no catálogo inclui: sinónimos em PT/EN, atalho associado, texto para o prompt, e método executor em Delphi.

**Importante:** IDs de `action` em **inglês estável**; mensagens ao utilizador via `TrText` ou campo `user_message` no idioma activo.

---

## 8. Executor Delphi (exemplos 2.2–2.6)

### 8.1 Mapeamento conceptual

| Pedido do utilizador | `action` | Implementação (conceito) |
|----------------------|----------|---------------------------|
| 2.2 — Ler `C:\...\PUB_MZ_....` | `open_and_read_file` | Definir path no controlo de ficheiro + `BeginRead` / fluxo de abertura existente |
| 2.4 — Abrir tela de carregar | `show_tab_read` | `pgMain.ActivePage := tabReadFile`; foco no painel Read |
| 2.5 — Ler X e dividir em 5 | Cadeia `open_and_read_file` → aguardar fim da leitura* → `split_equal_parts` | Orquestrador sequencial com estados |

\* Para cadeias, o orquestrador pode registar “pendente após `EndRead`” ou usar callback já existente em `FinishThread` — detalhe de implementação na fase 2.

### 8.2 Confirmação

- `confirm: true` → diálogo **Sim/Não** com resumo (`TrText('Assistant.ConfirmAction')` + path + ação).  
- Operações só leitura (ex. `show_help`) podem omitir confirmação via política no catálogo.

### 8.3 Integrações existentes a reutilizar

- Espaço em disco: `uDiskSpaceCheck.ConfirmDiskSpaceForPaths` antes de split/merge/dedup.  
- Sessão RO: bloquear mutações se `SessionBlocksMutation`.  
- Path efectivo: `CurrentEffectiveFilePath` quando aplicável.

---

## 9. Interface: chat na inicialização

### 9.1 Momento de exibição

Opções (decisão de produto):

| Opção | Prós | Contras |
|-------|------|---------|
| Modal após splash / `FormCreate` | Visível; cumpre “na inicialização” | Pode atrasar arranque |
| Item de menu **AI → Assistente** + opcional no startup | Flexível | Menos “automático” |
| Híbrido | Melhor UX | Mais INI |

**Sugestão:** híbrido com `ASkin.ini`:

```ini
[FastFile]
AssistantShowOnStartup=1
AssistantShowOnStartupAsked=0
```

Checkbox *“Não mostrar novamente”* no próprio chat.

### 9.2 Elementos de UI

- Título: `TrText('Assistant.Title')`  
- Pergunta inicial: `TrText('Assistant.WhatDoYouWant')` — *“O que deseja fazer?”*  
- Campo de entrada multilinha + **Enviar** / **Cancelar**  
- Área de resposta (última mensagem do assistente + estado da execução)  
- Indicador *“A pensar…”* durante o POST (thread)  

Reutilizar estilo de modais existentes (`uFastFileAIScreenHelp`) para consistência com AlphaSkins.

---

## 10. Integração com o endpoint AWS

### 10.1 Fluxo técnico

1. `BuildPromptW` ← regras + catálogo + pergunta do utilizador + (opcional) estado.  
2. `FastFileAIInvokePrompt(PromptW, AnswerW, ErrMsg)`.  
3. Extrair JSON de `AnswerW` (pode vir dentro de markdown — normalizar como em `PrepareAiMemoText`).  
4. Validar → confirmar → executar.

### 10.2 Verificações recomendadas com o backend

Confirmar com quem mantém `grod_prod_lambda`:

- Aceita **apenas** `{"prompt":"..."}` ou exige `modelo`, `pergunta`, token, etc.  
- Limite de tamanho do body.  
- Formato exacto de `resposta` (sempre JSON puro ou texto misto).  

Se o Lambda exigir outro schema, adaptar `BuildJsonPromptPayload` ou criar `FastFileAIInvokeAssistantPrompt` sem quebrar os fluxos actuais de regex/macro.

### 10.3 Offline / falha de rede

- Mensagem `TrText('Assistant.NetworkError')`.  
- Modo degradado: mostrar atalhos estáticos do catálogo (sem Lambda) — opcional.

---

## 11. Internacionalização (11 idiomas)

### 11.1 O que traduzir

| Categoria | Chaves `uI18n` (exemplo) |
|-----------|---------------------------|
| UI do chat | `Assistant.Title`, `Assistant.WhatDoYouWant`, `Assistant.Send`, `Assistant.Close`, `Assistant.Thinking` |
| Confirmação / erros | `Assistant.ConfirmAction`, `Assistant.UnknownIntent`, `Assistant.ParseError`, `Assistant.FileNotFound` |
| Execução | `Assistant.Done`, `Assistant.ActionFailed` |
| Opt-out startup | `Assistant.DontShowAgain` |

Registo: `AddCommonTranslationsAssistant` com `Set11`, como `AddCommonTranslationsEmEditorFeatures`.

### 11.2 Prompt para o Lambda

Duas estratégias:

1. **Regras em inglês** + catálogo em inglês + pedido do utilizador no idioma UI; pedir `user_message` no idioma do utilizador.  
2. **Regras via `TrText`** no idioma activo — respostas mais naturais; manter `action` IDs em inglês.

Codificação Delphi 7: preferir `#243`, `#231`, ou `'texto '#225 + 'resto'` quando um código numérico é seguido de letra (evitar *Unterminated string*).

### 11.3 Idiomas suportados

PT-BR, PT-PT, EN, ES, FR, DE, IT, PL, RO, HU, CZ — alinhado ao resto do `uI18n.pas`.

---

## 12. Segurança e limites

| Risco | Mitigação |
|-------|-----------|
| Path traversal / ficheiro inexistente | `FileExists`; normalizar path; rejeitar `..` suspeito |
| Escrita/destruição sem confirmação | `confirm: true` + diálogo |
| Sessão somente leitura | Verificar antes de split/replace/delete |
| Prompt injection (“ignore rules”) | Validador ignora texto fora do JSON; whitelist rígida |
| Timeout 120 s | Prompt compacto; progress na UI |
| Custos AWS | Rate limit opcional; não auto-disparar no startup sem opt-in |

O modelo **nunca** deve receber credenciais nem executar código arbitrário — só IDs do catálogo.

---

## 13. “Possibilidades infinitas” — expectativa realista

| Dimensão | Limitação prática |
|----------|-------------------|
| Formas de pedir | Quase ilimitadas (NL) |
| **Ações executáveis** | **Finitas** — lista mantida pela equipa |
| Combinações | Muitas, via `actions[]` (cadeias curtas) |
| Fora do catálogo | Resposta `unknown` + remissão para F1 / menus |

Crescimento: versão 1 com ~10 ações; versão 2 com ~25; testes de regressão por `action`.

---

## 14. Plano de implementação por fases

### Fase 0 — Documento e alinhamento (este ficheiro)

- Aprovar catálogo MVP e política de startup.  
- Validar contrato Lambda com backend.

### Fase 1 — MVP (sem cadeias complexas)

- UI chat (menu AI + opcional startup).  
- Catálogo: `open_and_read_file`, `show_tab_read`, `show_help`.  
- Prompt + parse JSON + executor + confirmação para `open_and_read_file`.  
- i18n UI (11 idiomas).

### Fase 2 — Operações sobre ficheiro aberto

- `split_equal_parts`, `extract_file_parts`, `open_find`, `start_tail`.  
- Estado runtime no prompt (path actual).  
- Mensagens de erro traduzidas.

### Fase 3 — Cadeias e robustez

- `actions[]` sequencial (ler → dividir).  
- Hook pós-`EndRead` para passo 2.  
- Logging (`Assistant.log` opcional).  
- RAG leve se prompt exceder tamanho.

### Fase 4 — Documentação produto

- Entrada no F1, Version History, `CHANGELOG`, README.  
- Checklist QA (`DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md` — a criar se aprovado).

---

## 15. Unidades e ficheiros sugeridos

| Ficheiro | Responsabilidade |
|----------|------------------|
| `uFastFileAssistant.pas` | Form chat, thread IA, ciclo pergunta/resposta |
| `uFastFileActionCatalog.pas` | Definições de ações, texto para prompt, validação de params |
| `uFastFileActionExecutor.pas` | Executa ações (interface com `TfrmMain` ou callbacks) |
| `uI18n.pas` | `AddCommonTranslationsAssistant` |
| `MainUnit.pas` | Registar menu AI; startup opcional; expor métodos ao executor |
| `UnConsts.pas` | (já tem URL); eventual `ASSISTANT_MAX_PROMPT_CHARS` |
| `FastFile.dpr` | Registrar novas units |

**Não** misturar com `uFastFileAIScreenHelp` (regex) — partilhar só `uFastFileAIClient`.

---

## 16. Riscos e perguntas em aberto

1. **Lambda:** confirmação do schema JSON de entrada/saída.  
2. **Startup:** modal sempre vs. só primeira execução vs. só menu.  
3. **Cadeias:** executar split antes de `EndRead` terminar — política de espera/erro.  
4. **Ficheiros enormes:** abrir 20 GB via assistente — mesmas regras Zero Scan / índice que F5 manual.  
5. **Privacidade:** enviar paths completos para AWS — aviso na UI?  
6. **Consumer AI:** deixar claro que o assistente **não** é o Consumer SQL.  

---

## 17. Checklist para aprovação antes de codificar

- [ ] Aprovar arquitectura 3 camadas (UI / orquestração / executor).  
- [ ] Aprovar resposta **JSON estruturada** (não execução por texto livre).  
- [ ] Definir lista MVP de `action` (mín. 3–10).  
- [ ] Decidir: chat no startup (sim/não/INI).  
- [ ] Validar endpoint `grod_prod_lambda` com equipa AWS.  
- [ ] Decidir política de confirmação por tipo de ação.  
- [ ] Aprovar pacote de chaves i18n `Assistant.*`.  
- [ ] Aprovar fase 1 vs. entrega monolítica.  

---

## Histórico deste documento

| Data | Nota |
|------|------|
| 2026-05-23 | Versão inicial para análise do utilizador (proposta, sem implementação). |
| 2026-05-23 | **Fase 1 implementada:** `uFastFileAssistant.pas`, `uFastFileAssistantHost.pas`; menu **AI**; arranque opcional; sem Python. |
| 2026-05-23 | **Fases 2–4 implementadas (v2.1.7.30):** cadeias `actions[]`, mais ações, RAG (`uFastFileAssistantRAG`), log opcional, F1/Version History/CHANGELOG/checklist QA. |

---

## Anexo — Implementação actual (referência rápida)

| Item | Detalhe |
|------|---------|
| Menu | **AI** → `Assistant.MenuItem` (Assistente FastFile...) |
| Arranque | `WM_USER+430` se `AssistantShowOnStartup=1` |
| INI | `AssistantShowOnStartup`, `AssistantLog=1` → `Assistant.log` |
| Endpoint | `FastFileAIInvokePrompt` → `grod_prod_lambda` |
| Prompt | Regras + catálogo + **RAG** por palavras-chave + contexto `file=` |
| JSON | `intent` + `action` ou `actions[]` (cadeia) |
| Cadeia | Ler ficheiro → passos seguintes após `finishFileNameRead` |
| Ações | Ver catálogo completo em `BuildOperationalKnowledgeBase` (abrir/ler, abas, ajuda, find/replace, tail, compare, split, extract parts, **filter**, **export**, **dedup**, **freq strings**, **checkboxes**, **goto line**, **char code**, **merge tabs**, **word wrap**) |
| QA | `DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md` |

*Sem código-fonte da aplicação no prompt nem nas respostas ao utilizador.*
