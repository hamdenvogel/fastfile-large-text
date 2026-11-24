# Insights do lnav para o FastFile

**Atualizado:** 23 de novembro de 2026  
**Fonte:** [https://lnav.org/features](https://lnav.org/features)  
**Contexto do produto:** FastFile Professional 3.0.5.280 — editor nativo Windows para arquivos de texto enormes (logs, CSV/TSV, SQL dumps, exports)  
**Relacionados:** `src/MELHORIAS_FASTFILE.md`, `Docs/website-en/FastFile-Professional-Features.md`

Este documento registra a conversa de produto sobre o que o FastFile poderia aprender do **lnav** (Logfile Navigator): o que já se sobrepõe, o que vale implementar, o que evitar, e um pacote sugerido de prioridade.

---

## 1. Premissa: produtos diferentes

| | **lnav** | **FastFile** |
|---|---|---|
| Papel | Navegador / analisador de **logs** (TUI, tipicamente Linux) | **Editor** de texto enorme (Win32/Win64, Delphi) |
| Foco | Correlacionar timestamps, formatos de log, SQL, histograma, timeline | Abrir GB/TB sem carregar tudo na RAM; editar com segurança; Python; AI com aceite; anonimizar |
| Motor | Processamento orientado a mensagens de log | Índice de offsets por linha + MMF + viewport virtual |
| Escrita | Análise / consultas / headless | Gravação atômica, undo/sessão, preview antes de escrever |

**Conclusão:** usar o lnav como **fonte de ideias de análise de log**, não como roadmap para virar um clone. O FastFile não deve diluir o diferencial de edição segura + AI + Python + anonimização + 30 idiomas.

---

## 2. Features do lnav (resumo da página oficial)

1. **Single Log View** — vários arquivos mesclados numa vista única por timestamp; barras de cor por arquivo de origem.  
2. **Automatic Log Format Detection** — ~70 formatos built-in (syslog, access log, logfmt, journald JSON, OTLP, Bunyan/Pino, MongoDB/MySQL/PostgreSQL, “generic” com timestamp, etc.); formatos custom via JSON/PCRE; GZIP/BZIP on-the-fly.  
3. **Filters** — mostrar só linhas que batem / não batem com regex.  
4. **Histogram View** — contagem em buckets no tempo; warnings/errors destacados; tecla volta à mensagem correspondente.  
5. **Timeline View** — operações no tempo por opid / thread / tag / arquivo; sparklines de erro.  
6. **Pretty-Print View** — reformata XML/JSON das linhas exibidas (ex.: SHIFT+P).  
7. **Query Logs Using SQL** — arquivos como tabelas virtuais SQLite; agregações sem importar para DB externo.  
8. **“Live” Operation** — busca enquanto digita; novas linhas entram e são filtradas/pesquisadas; SQL validado ao digitar.  
9. **Themes** — UI customizável.  
10. **Syntax Highlighting** — ERROR/WARN coloridos; SQL, XML, backtraces Java, strings; prompt com highlight.  
11. **Tab-completion** — completar palavras da tela no prompt.  
12. **Custom Keymaps** — atalhos → comandos/scripts lnav.  
13. **Sessions** — posição, bookmarks e filtros restaurados para o mesmo conjunto de arquivos.  
14. **Headless Mode** (`-n` + `-c`) — processar logs em scripts (ex.: top IPs em CSV no stdout).

---

## 3. O que o FastFile já cobre (sobreposição)

| Feature lnav | No FastFile hoje | Observação |
|---|---|---|
| Filters | Filter, Occurrences, glob/grep, bookmarks | Já no fluxo Read File |
| Live / novas linhas | Tail + Tail macros Python | Transform em linhas que chegam |
| Themes | AlphaSkins (ex.: Notes Plastic), Custom PPI | Desktop nativo, não TUI |
| Sessions | `.ffsession` (cursor, bookmarks, filter, encoding) | Por arquivo; Recent Files mostra Session |
| Bookmarks | Ctrl+B, painel, grep em marcados | Até 10k por arquivo indexado |
| “SQL” / agregação | CSV / Column mode; Extract Frequent Strings; AI agent/diagnosis (incl. SQL tabular) | **Não** há tabela virtual SQLite sobre o arquivo |
| Busca embutida | Find, Filter, glob/grep sem shell externo | AI pode redigir comando; usuário confirma Run |
| Multi-arquivo | Merge files, Compare/merge, Find Files | **Não** há merge cronológico por timestamp numa vista única |

O FastFile já ganha em: **edição atômica**, **review before write**, **Python `transform`**, **AI diagnosis (só lê) + AI agent (só escreve após aceite)**, **anonimização com preview**, **split/merge/equal parts**, **30 idiomas + RTL**.

---

## 4. O que faria sentido implementar

### 4.1 Alta prioridade (encaixa no DNA e no público)

| # | Ideia inspirada no lnav | Por quê | Notas de desenho |
|---|---|---|---|
| 1 | **Detecção de formato de log + campos** | Reforça o pitch “logs / dumps / exports” sem virar IDE | Detectar syslog, access log, JSON-lines, “linha começa com timestamp”; expor nível, hora, logger para filtro/coluna; **sem** carregar o arquivo inteiro |
| 2 | **Pretty-print só no viewport** | Barato, útil em JSONL/XML embutido | Como SHIFT+P: só linhas visíveis ou selecionadas; alinhado a `MELHORIAS_FASTFILE.md` (highlight só no que está na tela) |
| 3 | **Histograma de densidade / erros no tempo** | Alternativa realista a minimap em 14 GB | Buckets por timestamp (ou por offset); picos ERROR/WARN; clique → jump para a linha |
| 4 | **Abrir `.gz` / `.bz2` on-the-fly** | Fluxo típico de log rotacionado | Fase 1: descompactar para temp + abrir; streaming puro é mais caro |
| 5 | **Highlight de severidade no viewport** | Leitura rápida de incidentes | Vermelho/amarelo em ERROR/WARN/FATAL só nas linhas desenhadas — sem Scintilla no arquivo todo |

### 4.2 Média prioridade (se o foco em log crescer)

| # | Ideia | Por quê | Cuidado |
|---|---|---|---|
| 6 | **Vista única por timestamp (vários arquivos)** | Single Log View do lnav; correlacionar `.log` / `.1` / `.2` | Ferramenta dedicada, **não** N abas tipo IDE (`MELHORIAS` já rejeita abas pesadas); índice virtual por timestamp + cor por origem |
| 7 | **SQL leve sobre amostra / filtro / CSV** | Agregações tipo “top IP” sem DB externo | **Não** copiar “arquivo inteiro = tabela SQLite virtual” em TB; sim GROUP BY / top-N sobre hits do Filter, colunas CSV ou sample — espírito do Extract Frequent Strings + headless do lnav |
| 8 | **Formatos definidos pelo usuário (JSON/PCRE)** | Extensível sem manter 70 formatos oficiais | Poucos built-in + usuário define o resto; custom format como no lnav |

### 4.3 Baixa prioridade / não priorizar agora

| Ideia lnav | Por quê não (agora) |
|---|---|
| **Timeline com opid / thread / tag** | Poderoso e nichado (OTLP/telemetria); custo alto; só se esse mercado for estratégico |
| **Tab-completion de prompt TUI** | UI diferente; atalhos Windows + macros Python já cobrem |
| **Custom keymaps estilo lnav** | Pode vir depois; não diferencia o core |
| **Headless CLI completo** (`-n` / `-c`) | Outro produto; Python + scripts externos já atendem parte |
| **Syntax highlight “de IDE” no arquivo inteiro** | Contradiz motor MMF/viewport |
| **~70 formatos oficiais mantidos pela equipe** | Manutenção pesada; preferir set curado + custom |

---

## 5. Pacote sugerido (“inspirado no lnav” sem diluir o produto)

Ordem prática se for um único epic:

1. Formato de log + campos (detect + custom)  
2. Pretty-print viewport (JSON/XML)  
3. Histograma temporal / densidade + jump  
4. Highlight ERROR/WARN no viewport  
5. Abrir gzip (depois bz2)

Isso diferencia o FastFile de “Notepad++ grande” e de “só editor”, sem competir de frente com o lnav no terminal Linux — e reforça o público já descrito no site: analistas, DBAs, developers e suporte.

---

## 6. Alinhamento com restrições já documentadas

De `src/MELHORIAS_FASTFILE.md` (secção “O que **não** faria agora”):

| Ideia antiga / tentadora | Posição |
|---|---|
| Scintilla / syntax highlight no arquivo todo | Não; no máximo highlight **só nas linhas visíveis** |
| Minimap do arquivo inteiro | Não em 14 GB; se fizer, **só histograma de densidade** |
| Múltiplos arquivos em abas tipo IDE | Evitar; MRU + recentes; merge cronológico seria ferramenta à parte |
| Carregar GB em `TArray<string>` / `ReadAllLines` | Mata o produto — qualquer feature lnav-like deve respeitar índice + MMF |

Qualquer implementação acima deve:

- operar sobre **índice + janela**, não buffer completo;  
- manter **review before write** onde houver alteração;  
- registrar UI nova nos **30 idiomas** (regra i18n do projeto);  
- não enviar textos da aplicação a serviços externos de tradução.

---

## 7. Posicionamento de marketing (se/quando existir)

Não vender “somos o lnav no Windows”. Vender, se as features existirem:

- *Abra logs multi-GB e veja erros no tempo sem carregar o arquivo na RAM.*  
- *JSON/XML legível na linha em que você está; edição só depois de aceitar.*  
- *Filtro, histograma e campos de log — no mesmo editor que já anonimiza, faz Python e AI com aceite.*

O material de site atual (`Docs/website-en/FastFile-Professional-Features.md`) já cita logs como caso de uso; estas features tornariam essa claim mais concreta.

---

## 8. Próximo passo sugerido

Quando for implementar: RFC curto só para o pacote da secção 5 (escopo, onde no índice/sidecar, UI, i18n, riscos em Zero Scan / Instant Open). Este arquivo é **pesquisa de produto**, não especificação de build.

---

## Referências

- Features lnav: https://lnav.org/features  
- Features produto (site): `Docs/website-en/FastFile-Professional-Features.md`  
- Melhorias / o que não fazer: `src/MELHORIAS_FASTFILE.md`  
- Handoff site: `Docs/website-en/SITE_HANDOFF.md`
