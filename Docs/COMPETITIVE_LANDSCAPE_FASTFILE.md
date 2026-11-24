# Paisagem competitiva do FastFile

**Atualizado:** 24 de novembro de 2026  
**Contexto do produto:** FastFile Professional 3.0.5.280 — editor nativo Windows para arquivos de texto enormes (logs, CSV/TSV, SQL dumps, exports)  
**Relacionados:** `Docs/EMEDITOR_COMPETITIVE_FASTFILE.md`, `Docs/LNAV_INSIGHTS_FASTFILE.md`, `src/MELHORIAS_FASTFILE.md`, `src/ROADMAP_COMERCIAL_FASTFILE.md`, `Docs/website-en/FastFile-Professional-Features.md`

Este documento amplia a análise além do EmEditor e do lnav: **quem mais compete** no mesmo espaço mental do utilizador, onde o FastFile **já pode vencer**, onde só ganha com um *wedge*, e o que **não** tentar bater de frente.

---

## 1. Premissa

O FastFile não compete com “todos os editores”. Compete com o que a pessoa abre quando tem **log / CSV / dump GB+** e o Notepad++ (ou o Excel) falha.

```text
Camada 1 — Substitutos que falham em GB+     → Notepad++, VS Code, TextPad, Excel (CSV grande)
Camada 2 — Viewers que não fecham o fluxo    → klogg, glogg, LogExpert, BareTail, UwView
Camada 3 — Pagos genéricos / huge-file       → UltraEdit (wedge), EmEditor (diferencial)
Camada 4 — Especialistas a aprender          → lnav (ideias), 010 Editor (só no texto)
```

**Posicionamento-alvo (já alinhado ao roadmap):**

> *Open and edit multi-gigabyte text files instantly — where other editors give up.*

**Pacote de confiança (diferencial transversal):** review before write · AI diagnosis (só lê) + AI agent (só após aceite) · anonimização com preview · Python `transform` + Tail · 30 idiomas + RTL.

---

## 2. Matriz rápida

| Concorrente | Tipo | Dá para vencer? | Como |
|---|---|---|---|
| **Notepad++, VS Code, TextPad** | Editores do dia a dia | **Sim, fácil** no GB+ | Eles travam / OOM; FastFile abre. Benchmark na home. |
| **Excel / LibreOffice** | Planilha | **Sim em CSV grande** | Excel corta linhas; FastFile abre o export + CSV mode |
| **klogg / glogg** | Viewer de log (OSS) | **Sim** | Eles leem; FastFile **edita com segurança** + Python + AI + anonimizar |
| **LogExpert, BareTail** | Tail Windows | **Sim** | Tail + macro + filter + export/AI; não só seguir o ficheiro |
| **UwView e afins** | Viewer huge-file | **Sim** | Viewer vs editor + ops + AI |
| **UltraEdit** | Editor pago huge-file | **Sim, no wedge** | Preço + AI com aceite + anonimizar + 30 idiomas; não “IDE completa” |
| **EmEditor** | Rival direto | **Sim no diferencial**, empatar no motor | Ver `EMEDITOR_COMPETITIVE_FASTFILE.md` |
| **lnav** | Análise de log (TUI) | **Sim no Windows + edição** | Ver `LNAV_INSIGHTS_FASTFILE.md` |
| **010 Editor** | Hex / templates | **Só no texto** | Não competir em hex; sim em logs/CSV/texto GB+ |

---

## 3. Camada 1 — Substitutos que falham (vitória de categoria)

### 3.1 Notepad++, VS Code, TextPad

| | Detalhe |
|---|---|
| Papel na cabeça do utilizador | “Abro no editor que já tenho” |
| Fraqueza em GB+ | Travamento, OOM, recusa a abrir, UI lenta |
| FastFile hoje | Índice + MMF + Zero Scan / Instant Open; edição atómica |
| Como vencer | Não feature parity — **prova de categoria** |

**Ações:**

- Tabela de benchmarks 1 / 5 / 10 GB (já esboçada em `ROADMAP_COMERCIAL_FASTFILE.md`)
- Vídeo/GIF: mesmo ficheiro abre no FastFile e falha noutro editor
- Tagline: *Where other editors give up*

**Mensagem:** *Se o Notepad++ congela, use FastFile.*

### 3.2 Excel / LibreCalc (CSV “grande”)

| | Detalhe |
|---|---|
| Limite típico | ~1M linhas (Excel); dumps reais passam disso |
| FastFile hoje | CSV / Column mode; Extract Frequent Strings; Delete Duplicate Lines |
| Gap a fechar | Sort por coluna, extract columns, freeze header, join simples (ver doc EmEditor) |

**Mensagem:** *Abra o export completo; não o pedaço que coube na planilha.*

---

## 4. Camada 2 — Viewers que não fecham o fluxo (vitória de produto completo)

### 4.1 klogg / glogg

| | Detalhe |
|---|---|
| Força | Regex, follow, gratuitos, foco em log grande |
| Fraqueza | Principalmente **viewer**; pouco fluxo de edição/ops/compliance |
| FastFile | Filter + Tail + Python + AI + anonimizar + split/merge + gravação segura |

**Mensagem:** *Mais do que um log viewer: edite, automatize e peça à AI — com aceite.*

**Compare page sugerida (fluxo de suporte):**  
filtrar ERROR → extrair → anonimizar → partilhar → Tail com Python.

### 4.2 LogExpert, BareTail (e tails semelhantes)

| | Detalhe |
|---|---|
| Força | Seguir log em Windows; filtros/triggers (LogExpert) |
| Fraqueza | Pouco além de tail/monitorização |
| FastFile | Tail + macros + Talk with AI + export/select |

**Ação de marketing (baixo esforço):** print/GIF “Tail + transform” no site — pouco código novo.

**Mensagem:** *Tail que também transforma, filtra e prepara o ficheiro para partilha.*

### 4.3 UwView e viewers huge-file

| | Detalhe |
|---|---|
| Força | Ver / procurar em ficheiros muito grandes; alguns com cache agressivo |
| Fraqueza | Não são suite de edição segura + AI + anonimizar + ops |
| FastFile | Editor + review before write + automação |

**Mensagem:** *Ver não chega: edite e automatize sem arriscar o original.*

---

## 5. Camada 3 — Pagos genéricos (vitória por wedge / diferencial)

### 5.1 UltraEdit

| | Detalhe |
|---|---|
| Força | Editor profissional, huge files, compare, macros; marca “enterprise” |
| Fraqueza | Caro se o utilizador só precisa de log/CSV GB+; superfície IDE larga |
| Wedge FastFile | Preço acessível (quando houver) + anonimizar + AI com contrato + Python em linhas + 30 idiomas/RTL |

**Não tentar:** checklist de IDE (FTP, projects, LSP, skin de código).

**Mensagem:** *Pague por huge-file de produção, não por um IDE que você não usa.*

### 5.2 EmEditor

Rival **mais direto**. Análise completa: `Docs/EMEDITOR_COMPETITIVE_FASTFILE.md`.

Resumo: empatar no motor e na prova de velocidade; **sair na frente** em AI sob aceite, anonimização, review before write, Python/Tail, i18n/RTL; fechar gap em CSV sort/extract e “abrir trecho”.

---

## 6. Camada 4 — Especialistas (aprender, não clonar)

### 6.1 lnav

Análise completa: `Docs/LNAV_INSIGHTS_FASTFILE.md`.

Ideias a trazer (sem virar TUI Linux): formato de log + campos, pretty-print viewport, histograma, highlight ERROR/WARN, gzip.

### 6.2 010 Editor

| | Detalhe |
|---|---|
| Território | Hex, templates binários, parsing estruturado |
| FastFile | Texto (logs, CSV, dumps) |
| Regra | Não competir em hex; se o ficheiro for texto exportado, FastFile |

---

## 7. O que **não** tentar vencer de frente

| Alvo | Por quê |
|---|---|
| **VS Code como IDE diária** | Ecossistema / LSP; FastFile não é editor de código do dia a dia |
| **010 Editor em binário** | Outro produto |
| **Excel em pivot/tabela pequena** | Planilha ganha em UX nesse nicho |
| **EmEditor feature-a-feature** | Décadas de CSV/plug-ins; empatar motor + vencer no contrato de confiança |
| **lnav timeline/opid completo** | Nicho telemetria; custo alto (ver doc lnav) |

---

## 8. Pacote sugerido (ordem comercial)

1. **Benchmarks vs camada 1** (Notepad++ / VS Code / TextPad) — mais conversão, menos discussão.  
2. **Compare page vs klogg / LogExpert** — “viewer vs production suite” (anonimizar + AI aceite + Tail/Python).  
3. **Wedge UltraEdit + diferencial EmEditor** — confiança + preço + i18n; CSV sort/extract; abrir trecho + gzip.  
4. **Pacote lnav** — não deixar o nicho log só para open source.

### Features de produto que batem várias frentes de uma vez

| Prioridade | Item | Bate especialmente |
|---|---|---|
| Alta | Instalador + trial + site com benchmarks | Todos |
| Alta | Abrir trecho / últimas N linhas + gzip | LogExpert, BareTail, EmEditor, admins |
| Alta | CSV sort / extract columns / freeze header | Excel, EmEditor, UltraEdit |
| Alta | Marketing Tail + Python + AI aceite | klogg, glogg, BareTail |
| Média | Histograma / highlight ERROR (lnav) | klogg, LogExpert, lnav |
| Média | Anonymize + AI na compare page | UltraEdit, EmEditor |

---

## 9. Narrativas por rival (copy curto)

| Rival | Uma linha |
|---|---|
| Notepad++ / VS Code | *Se o editor congela no GB+, use FastFile.* |
| Excel | *O export completo, não só o que coube na planilha.* |
| klogg / glogg | *Viewer de log + edição segura, Python, AI e anonimização.* |
| LogExpert / BareTail | *Tail que também transforma e prepara o ficheiro.* |
| UltraEdit | *Huge-file de produção sem pagar por um IDE inteiro.* |
| EmEditor | *Tão capaz em GB+; mais seguro a escrever e a usar AI.* |
| lnav | *Ideias de análise de log no editor Windows que já edita e anonimiza.* |

Tom de site: preferir *“typical large-file editors / log viewers”* se a política comercial evitar nomes; manter nomes neste doc interno.

---

## 10. Alinhamento com docs existentes

| Doc | Papel |
|---|---|
| `ROADMAP_COMERCIAL_FASTFILE.md` | Nicho GB+, tagline, tabela de benchmarks vs Notepad++/VS Code/TextPad/EmEditor |
| `MELHORIAS_FASTFILE.md` | Motor já compete com EmEditor/UltraEdit; gap = vender (instalador, licença, site) |
| `EMEDITOR_COMPETITIVE_FASTFILE.md` | Rival direto — CSV, controller, AI plug-in vs nativa |
| `LNAV_INSIGHTS_FASTFILE.md` | Ideias de análise de log sem clonar o TUI |
| Este ficheiro | Mapa de camadas e ordem de ataque comercial |

Restrições técnicas permanentes: índice + MMF/viewport; sem carregar GB em memória; review before write; UI nova nos **30 idiomas**.

---

## 11. Próximo passo sugerido

1. Preencher a tabela 1 / 5 / 10 GB com números reais (FastFile + 1–2 rivais da camada 1 + EmEditor).  
2. Uma compare page no site (genérica ou nomeada) com as três provas: preview→commit, anonymize, AI com papéis.  
3. RFCs dos epics já listados nos docs EmEditor e lnav — este ficheiro só ordena **quem atacar primeiro**.

Este arquivo é **pesquisa de produto / estratégia**, não especificação de build.

---

## Referências

- EmEditor: https://www.emeditor.com/  
- lnav features: https://lnav.org/features  
- Large file viewers (panorama 2026): https://sekin.in/best-large-file-viewers-for-windows-emeditor-klogg-glogg-and-more/  
- Doc EmEditor: `Docs/EMEDITOR_COMPETITIVE_FASTFILE.md`  
- Doc lnav: `Docs/LNAV_INSIGHTS_FASTFILE.md`  
- Roadmap comercial: `src/ROADMAP_COMERCIAL_FASTFILE.md`  
- Melhorias: `src/MELHORIAS_FASTFILE.md`  
- Features site: `Docs/website-en/FastFile-Professional-Features.md`
