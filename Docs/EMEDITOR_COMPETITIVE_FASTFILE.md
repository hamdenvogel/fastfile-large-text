# Análise competitiva: EmEditor × FastFile

**Atualizado:** 24 de novembro de 2026  
**Fonte:** [https://www.emeditor.com/](https://www.emeditor.com/), [Feature list](https://www.emeditor.com/text-editor-features/), [Chat with AI](https://www.emeditor.com/text-editor-features/extensibility/chat-with-ai/)  
**Contexto do produto:** FastFile Professional 3.0.5.280 — editor nativo Windows para arquivos de texto enormes (logs, CSV/TSV, SQL dumps, exports)  
**Relacionados:** `Docs/LNAV_INSIGHTS_FASTFILE.md`, `src/MELHORIAS_FASTFILE.md`, `Docs/website-en/FastFile-Professional-Features.md`

Este documento registra a conversa de produto sobre como o FastFile pode **competir** e **sair na frente** do **EmEditor** (Emurasoft): onde o concorrente ganha, onde o FastFile já diferencia, o que implementar, o que não perseguir (armadilha de feature parity), e um pacote sugerido de prioridade.

---

## 1. Premissa: concorrente direto, produtos não idênticos

| | **EmEditor** | **FastFile** |
|---|---|---|
| Papel | Editor **geral** Windows: código + CSV + huge files | Ferramenta **de produção** para logs / CSV / dumps GB+ |
| Promessa | “World’s fastest”, até **16 TB**, CSV estilo Excel | Abrir sem carregar tudo na RAM + **editar com segurança** + Python + AI com aceite |
| Extensão | Plug-ins, macros JS, LSP, abas, outline, ecossistema Free/Pro | Suite embutida (split/merge, anonimizar, Tail, AI diagnosis/agent) |
| AI | ChatAI como **plug-in separado** (removido do core na v25 por preocupação corporativa) | **Nativa**: diagnosis (só lê) + agent (só escreve após aceite) |
| Motor | Multithread + SIMD (AVX-2/AVX-512); Large File Controller | Índice de offsets + MMF + viewport virtual; Zero Scan / Instant Open |

O `MELHORIAS_FASTFILE.md` já afirma: *o motor já compete com EmEditor/UltraEdit em arquivos gigantes; o que falta para vender é instalador, licença, site e prova.*

**Conclusão:** não ganhar “feature a feature”. EmEditor tem décadas de superfície (HTML, snippets, LSP, pivot CSV…). O FastFile ganha se for o melhor **fluxo de trabalho em arquivos de produção**, não o melhor Notepad++ / editor de código diário.

```text
EmEditor  = velocidade + CSV Excel-like + editor geral + ecossistema
lnav      = análise profunda de log
FastFile  = huge file + edição segura + AI sob aceite + anonimizar + Python + i18n
```

---

## 2. Features do EmEditor (resumo do site / feature list)

### 2.1 Large files e performance

- Abrir arquivos muito grandes (claim até **16 TB**)
- **Large File Controller** — abrir só um trecho (ex.: fim do log)
- Split / Combine files
- Multithread + SIMD; benchmarks públicos (ex.: 10 GB open ~1,067 s; replace ~0,271 s; sort ~7,3 s; delete dup ~4,3 s — máquina declarada no site)
- Design leve, single-process, multithreaded

### 2.2 CSV “nível Excel”

- Até 64 formatos CSV custom; delimitador longo
- Sort (incl. multi-coluna / advanced), Delete Duplicate Lines
- Extract Columns, Extract Frequent Strings, Combine/Split Columns
- Join CSV, Pivot / Unpivot, Transpose, Flash Fill, Autofill
- Freeze header, Manage Columns, Numbering, CSV Converter
- Cell selection mode; detectar CSV na abertura

### 2.3 Edição e UX de editor geral

- Multiple selection, vertical editing, Narrowing
- Filter Bar, Find/Replace, Batch Replace, Fuzzy Matching
- Markers, Bookmarks, Compare Documents, Clipboard History
- Syntax highlighting, Syntax Checker (HTML/CSS/JSON/XML)
- Tabbed design, Workspace Memory, Quick Launch, Outline
- Configurations, toolbars customizáveis, Start Window

### 2.4 Extensibilidade e AI

- Plug-ins (Projects, Snippets, Explorer, Web Preview, Word Complete, Word Count, HTML Bar, CommitList, Search, …)
- Scriptable macros (JS)
- External tools; Language Server Protocol
- **AI Assisted Writing / AI Toolbar / Chat with AI** via plug-in ChatAI (Anthropic, OpenAI, Deepseek, Google, LM Studio); tool calling no editor; upload de ficheiros
- Desde v25: AI **fora do core** — admins corporativos pediram redução de risco de leak

### 2.5 Público e go-to-market

- Personas no site: HTML designer, programmer, editor/publisher, **DBA**, **server admin**
- EmEditor Free + Professional; Installer / Portable / Store
- ROI calculator, business case, prêmios, suporte maduro
- Narrativa dominante: **velocidade** + CSV + huge files

---

## 3. Sobreposição e gaps

### 3.1 Onde já se sobrepõe (FastFile cobre de forma útil)

| Área EmEditor | No FastFile hoje | Observação |
|---|---|---|
| Huge files | Índice + MMF; Zero Scan / Instant Open | Motor compete; falta narrativa/benchmark GB no site |
| Filter / Find | Filter, Occurrences, glob/grep | Já no Read File |
| Split / Combine | Equal parts, Split by lines/pattern, Merge files | Suite forte; review before write |
| Delete duplicates / Extract frequent | Delete Duplicate Lines; Extract Frequent Strings | EmEditor tem mais ops CSV em volta |
| CSV básico | CSV / Column mode; AI sobre colunas | EmEditor muito à frente em sort/join/pivot |
| Bookmarks / sessão | Bookmarks; `.ffsession` | Workspace/abas EmEditor são mais “IDE” |
| Themes / DPI | AlphaSkins, Custom PPI | Desktop nativo |
| Macros | Python `transform(line, ctx)` + Tail | Diferente de macro JS genérica — foco em linhas GB+ |
| AI | Diagnosis + Agent nativos | Contrato mais claro que chat genérico; EmEditor exige plug-in |
| Compare | Compare / merge + session history | EmEditor também tem compare de documentos |

### 3.2 Onde o EmEditor está à frente hoje

1. **CSV nível Excel** — sort multi-coluna, join, pivot, freeze, Flash Fill, 64 formatos.  
2. **Benchmarks públicos e marketing de velocidade** — tabelas, máquina, claims; FastFile tem prova menor (ex.: 165k linhas ~144 ms) e menos números GB publicados.  
3. **Edição “de editor”** — multi-seleção, vertical edit, markers, narrowing, clipboard history, syntax highlight, abas.  
4. **Ecossistema** — Free + Pro, portable/Store, plug-ins, suporte/prêmios.  
5. **Large File Controller** — abrir só um trecho sem varrer tudo; pitch muito claro para admins.

### 3.3 Onde o FastFile já pode sair na frente (e enfatizar)

1. **AI com contrato claro** — diagnosis read-only + agent com propostas; nada no disco até aceitar. EmEditor: chat via plug-in; core sem AI por medo corporativo. Pitch: *“AI sob revisão humana, desenhada para dados sensíveis.”*  
2. **Anonimização com preview + undo** — EmEditor não compete como produto; ouro para suporte, DBA, compliance.  
3. **Python `transform` + Tail macros** — automação no arquivo que cresce, com preview.  
4. **Review before write em tudo** — split, merge, anonimizar, Python, AI. EmEditor é rápido a escrever; FastFile é **seguro a escrever**.  
5. **30 idiomas + RTL (AR/HE)** — chrome RTL com texto do ficheiro LTR; diferencial global / MENA.  
6. **Suite ops de ficheiro num fluxo** — equal parts, split by pattern, merge files/lines, select/checkbox → export/AI/macro; menos dependência de plug-ins.

---

## 4. Estratégia: competir vs sair na frente

### 4.1 Não competir no território errado

Não tentar igualar: LSP, Zen Coding, HTML Bar, pivot table completo, dezenas de plug-ins, “editor de código diário”. Isso dilui o produto e nunca alcança o EmEditor/VS Code.

### 4.2 Competir (fechar a distância onde dói na escolha)

| Prioridade | O quê | Por quê vs EmEditor |
|---|---|---|
| Alta | **Produto comercial** — instalador, trial/licença, página de download | Já prioridade #1 em `MELHORIAS_FASTFILE.md`; sem isto features não vendem |
| Alta | **Benchmarks honestos** (abrir N GB, replace, delete dup, filtro) + vídeo/GIF | Neutraliza a narrativa “somos os mais rápidos” |
| Alta | **CSV mais forte** — sort por coluna, extract columns, freeze header, join simples | DBA/analista hoje escolhe EmEditor por CSV |
| Alta | **Abrir trecho / “Large File Controller”** (últimas N linhas, range por offset/linha) + gzip | Pitch de admin de servidor; EmEditor vende isto bem |
| Média | Números de performance na UI/status após ops pesadas | Prova no produto, não só no marketing |

### 4.3 Sair na frente (dobrar o diferencial)

| Prioridade | O quê | Por quê |
|---|---|---|
| Alta | Dobrar **review-before-write** + anonimização + AI com papéis separados na comunicação e no site | EmEditor não tem o mesmo pacote |
| Alta | Pacote **lnav** (formato de log, histograma, pretty-print viewport, ERROR highlight) — ver `LNAV_INSIGHTS_FASTFILE.md` | EmEditor é editor genérico; FastFile vira “huge file + log/ops” |
| Média | Receitas Python one-click (CSV col N, JSONL, anonimizar) | Menos fricção que ChatAI genérico |
| Baixa | Multi-seleção / markers leves | Conforto; não é o diferencial |

### 4.4 Baixa prioridade / não perseguir agora

| Ideia estilo EmEditor | Por quê não (agora) |
|---|---|
| LSP / Projects / outline de código | Público errado; VS Code/EmEditor dominam |
| HTML Bar, Zen Coding, Web Preview | Não é o caso de uso FastFile |
| Pivot/Unpivot CSV completo | Caro; join + sort + extract cobrem a maior parte do DBA |
| Ecossistema de plug-ins aberto | Manutenção e segurança; preferir suite embutida |
| Syntax highlight no arquivo inteiro | Contradiz MMF/viewport (`MELHORIAS`) |
| Abas tipo IDE com N ficheiros GB+ | Peso; MRU + recentes + ferramentas dedicadas |

---

## 5. Pacote sugerido (epic “competir com EmEditor”)

Ordem prática se for um único epic comercial + produto:

1. **Instalador + licença/trial + página de download**  
2. **Benchmarks públicos** (método, máquina, 1–3 vídeos) alinhados ao tom do Features.md  
3. **CSV: sort por coluna + extract columns + freeze header** (join simples a seguir)  
4. **Abrir trecho / últimas N linhas** (+ gzip, alinhado ao pacote lnav)  
5. **Site/pitch**: três provas que o EmEditor não empacota igual — (a) preview → commit atômico, (b) anonymize + undo, (c) agent + diagnosis com papéis separados — e uma prova de velocidade em GB

Paralelo (não misturar no mesmo sprint): pacote lnav da secção 5 de `Docs/LNAV_INSIGHTS_FASTFILE.md`.

---

## 6. Alinhamento com restrições já documentadas

De `src/MELHORIAS_FASTFILE.md`:

| Tema | Posição |
|---|---|
| Motor vs EmEditor/UltraEdit | Já compete em huge files; gap é **vender** (instalador, licença, site, prova) |
| Scintilla / highlight no arquivo todo | Não; no máximo viewport |
| Abas tipo IDE / multi-ficheiro GB+ | Evitar |
| Minimap | Não; histograma de densidade se precisar de “mapa” |
| Diferencial do produto | *Abrir, filtrar, editar, automatizar e perguntar à IA em GB+* — sem virar Notepad++ |

Qualquer implementação acima deve:

- operar sobre **índice + janela**, não buffer completo;  
- manter **review before write** onde houver alteração;  
- registrar UI nova nos **30 idiomas**;  
- não enviar textos da aplicação a serviços externos de tradução.

---

## 7. Posicionamento de marketing

**EmEditor:** *“o editor mais rápido do Windows.”*  

**FastFile (alvo):** *“o editor seguro para arquivos de produção enormes — com AI que só escreve depois que você aceita, anonimização e Python.”*

Mensagens concretas (site / compare page):

- *Abra multi-GB sem encher a RAM; edite com gravação atômica e histórico de sessão.*  
- *AI diagnosis só lê; AI agent só propõe — você aceita antes de escrever.*  
- *Anonimize com preview lado a lado; compartilhe dumps sem vazar PII.*  
- *Python `transform` e Tail no mesmo fluxo que split, merge e CSV.*  
- *30 idiomas, incluindo árabe e hebraico com UI RTL.*

Não vender “somos o EmEditor mais barato” nem “temos mais features”. Vender o **contrato de confiança** em dados de produção + prova de velocidade suficiente.

---

## 8. Próximo passo sugerido

1. RFC curto para o pacote da secção 5 (comercial + CSV + abrir trecho), com critérios de aceite e i18n.  
2. Manter `LNAV_INSIGHTS_FASTFILE.md` como epic paralelo de diferenciação em logs.  
3. No site: página Compare (FastFile vs “typical large-file editors”) com as três provas + um benchmark — sem nomear concorrentes se a política comercial preferir tom genérico.

Este arquivo é **pesquisa de produto / estratégia**, não especificação de build.

---

## Referências

- EmEditor home: https://www.emeditor.com/  
- EmEditor feature list: https://www.emeditor.com/text-editor-features/  
- Chat with AI (plug-in): https://www.emeditor.com/text-editor-features/extensibility/chat-with-ai/  
- Nota v25 (AI fora do core): https://www.emeditor.com/emeditor-core/emeditor-v25-0-0-released-removed-ai-features-from-emeditor-core-markdown-and-html-conversions/  
- Insights lnav: `Docs/LNAV_INSIGHTS_FASTFILE.md`  
- Features produto (site): `Docs/website-en/FastFile-Professional-Features.md`  
- Melhorias / o que não fazer: `src/MELHORIAS_FASTFILE.md`  
- Handoff site: `Docs/website-en/SITE_HANDOFF.md`
