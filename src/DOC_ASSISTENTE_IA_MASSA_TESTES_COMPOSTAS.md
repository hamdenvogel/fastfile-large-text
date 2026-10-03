# Assistente IA — Massa de testes (perguntas compostas)

Documento de apoio para validar perguntas **compostas e dinâmicas** no Assistente IA do FastFile (AI-first: a IA interpreta; a app enriquece factos locais e executa ferramentas).

**Ficheiro de referência (amostra lida):** `C:\Hamden\PI121106.txt`  
**Pré-requisito:** o caminho desse ficheiro em `edtFileName`. Se a tool precisar do buffer (filtro / find / goto), o host faz o **Read** sozinho. Contagens de prefixo/contains leem o disco — não dependem do ListView.

### Pente fino (v3.0.5.140–141) — falhas estruturais, não frases

A IA escolhe a tool. O host **não** tem Q1→`count_line_prefixes`, Q8→`apply_filter`, etc. O que foi reforçado é o **contrato do ficheiro aberto**:

| Falha (classe) | O que o host faz agora |
| --- | --- |
| Path em `edtFileName` mas ainda não houve Ler | `apply_filter` / `find_text` / `goto_line` / `export_lines` / RAG agendam a mesma acção após `BeginRead` — sem modal «Leia o arquivo primeiro» |
| PDF só com criação/modificação/tamanho | Metadados de disco só entram no PDF se a pergunta os pediu; o corpo é o resumo + linhas filtradas (até `max_lines` da IA) |
| «quantas linhas tem» com índice a 0 | Conta LF no path (só quando a pergunta pede o total) |
| `salva em Word` sem a palavra `pdf` | Id de formato (` em word` / `formato word`), igual a `pdf`/`odt` — não o inglês *find the word X* |
| Contagem de prefixos | Scan no disco; o N total do scan vai sempre no resultado (Q4 em qualquer língua) |

### Cautela — AI-first (sem dicionário ambulante)

O chat único (`Ctrl+Alt+A`) é só UI. **Enviar (v3.0.5.147):** a IA escolhe a tool. O host **não** intercepta «quantas linhas» / «gera PDF» / «cate linii» antes do modelo. Só preenche path, ids de formato (`pdf`/`docx`/`odt`/`rtf`), aspas e códigos numéricos.

A IA escolhe a tool. O host, em `ApplyLocalIntentCorrection` / `NativeFollowUpAction` / `count_line_prefixes` / `compose_document`, só:

- preenche params estruturais (path, prefixos digitais, aspas/backticks, `pdf`/`docx`/`odt`/`rtf`);
- redireciona quando a tool da IA é claramente errada **e** a estrutura é inequívoca (ex.: runs de dígitos → contagem local; `consumer_*` vazio + id de formato → compose);
- **não** troca um `ActionId` válido por verbos.

Q1–20 são exemplos dinâmicos. Critério de OK = partes respondidas com factos reais (contagens, PDF, filtro…), não um `action_id` fixo por frase.

`Ctrl+Shift+A` / `Ctrl+Alt+R` deixaram de ser chats (`Ctrl+Alt+R` = só leitura). Não entram no critério desta massa.

### Amostra das primeiras ~50 linhas (padrão observado)

- Layout fixo / registo financeiro-seguro (linhas longas, sem cabeçalho).
- Prefixo frequente no início do ficheiro: `010055102…`
- Mais à frente no mesmo ficheiro existem outros prefixos (ex.: `2527474…`, `010055105…`).
- Marcador literal `XXX` no meio da linha.
- Sufixos observados: `12210001`, `12220001`.
- Campo interno observado: `005500100` (maioria) vs `005501300` (ex. linha 40).
- IDs de sequência após o prefixo (ex.: `000054040`, `003148305`, `003346026`).


| #   | OK? | Pergunta                                                                                                                                                         |
| --- | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | ☐   | Quantas linhas começam com `010055102` e também com `2527474`, e gera um PDF com o resultado.                                                                    |
| 2   | ☐   | Faz o somatório de quantas linhas se iniciam pelo valor `010055102` e pelo valor `010055105`; salva em Word.                                                     |
| 3   | ☐   | Conta as linhas que começam com `010055102000054040`, `010055102003148305` e `010055102003346026` e me gera um PDF.                                              |
| 4   | ☐   | Quantas linhas iniciam com `010055102` e quantas com `2527474`, e também me diga quantas linhas tem o arquivo no total.                                          |
| 5   | ☐   | Explica pra que serve esse arquivo `PI121106.txt`, diz quantas linhas ele tem e gera um PDF.                                                                     |
| 6   | ☐   | Me dá a data de criação e a data de modificação desse arquivo e também um resumo curto em PDF do padrão das linhas (prefixo + XXX).                              |
| 7   | ☐   | Qual o tamanho do arquivo em bytes, quantas linhas tem, e exporta um PDF com essas informações.                                                                  |
| 8   | ☐   | Filtra as linhas que contêm XXX e me diz aproximadamente o que esse arquivo representa. E por último salve num PDF as linhas filtradas, no máximo 100 registros. |
| 9   | ☐   | Divide esse arquivo em 3 partes iguais e depois me explica o que ele parece armazenar.                                                                           |
| 10  | ☐   | Junta esse arquivo (merge das partes) e gera um PDF dizendo o que foi feito.                                                                                     |
| 11  | ☐   | Exporta as linhas de 10 a 50 para um arquivo novo e me diga quantas linhas o arquivo original tem.                                                               |
| 12  | ☐   | Procura o texto `2527474` no arquivo e me gera um PDF com a explicação do conteúdo encontrado.                                                                   |
| 13  | ☐   | Calcula quantas linhas começam com `010055102` e também com `083403734`; se possível, gera ODT.                                                                  |
| 14  | ☐   | Quantas linhas se iniciam por `010055102003334796` e por `252747400000004446`, e tb me gere um PDF; não precisa abrir o ConsumerAI.                              |
| 15  | ☐   | Me diga quando o arquivo foi acessado pela última vez, o tamanho, e se ele parece ser um log ou um cadastro/registo fixo.                                        |
| 16  | ☐   | Conta linhas com prefixo `010055102` e `123145734`, gera PDF, e no chat resume o resultado em uma frase.                                                         |
| 17  | ☐   | Explica o propósito do arquivo, gera PDF, e também informa a data de criação.                                                                                    |
| 18  | ☐   | How many lines start with `010055102` and with `2527474`, and also generate a PDF with the counts.                                                               |
| 19  | ☐   | Cuántas líneas empiezan con `010055102` y con `010055105`, y genera un PDF con el resultado.                                                                     |
| 20  | ☐   | Soma/conta linhas que começam com `010055102` e `2527474`, gera PDF, e no final confirma o caminho do arquivo gerado.                                            |




## Critérios rápidos de validação


| Grupo                            | Perguntas             | Esperado                                                                                                      |
| -------------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------- |
| Contagem por prefixo + documento | 1–4, 13–14, 16, 18–20 | Contagens reais no chat e no PDF (`ExecMsg`); **sem** texto de “amostra tem N linhas”; banner “Arquivo salvo” |
| Factos locais + IA / PDF         | 5–7, 15, 17           | Todas as partes respondidas (linhas/datas/tamanho + texto/PDF)                                                |
| Ferramentas nativas misturadas   | 8–12                  | Rota correcta (filtro / split / merge / export / find) + resto da pergunta                                    |




## Texto pronto para colar (1–20)

```
1. Quantas linhas começam com 010055102 e também com 2527474, e gera um PDF com o resultado.
2. Faz o somatório de quantas linhas se iniciam pelo valor 010055102 e pelo valor 010055105; salva em Word.
3. Conta as linhas que começam com 010055102000054040, 010055102003148305 e 010055102003346026 e me gera um PDF.
4. Quantas linhas iniciam com 010055102 e quantas com 2527474, e também me diga quantas linhas tem o arquivo no total.
5. Explica pra que serve esse arquivo PI121106.txt, diz quantas linhas ele tem e gera um PDF.
6. Me dá a data de criação e a data de modificação desse arquivo e também um resumo curto em PDF do padrão das linhas (prefixo + XXX).
7. Qual o tamanho do arquivo em bytes, quantas linhas tem, e exporta um PDF com essas informações.
8. Filtra as linhas que contêm XXX e me diz aproximadamente o que esse arquivo representa. E por último salve num PDF as linhas filtradas, no máximo 100 registros.
9. Divide esse arquivo em 3 partes iguais e depois me explica o que ele parece armazenar.
10. Junta esse arquivo (merge das partes) e gera um PDF dizendo o que foi feito.
11. Exporta as linhas de 10 a 50 para um arquivo novo e me diga quantas linhas o arquivo original tem.
12. Procura o texto 2527474 no arquivo e me gera um PDF com a explicação do conteúdo encontrado.
13. Calcula quantas linhas começam com 010055102 e também com 083403734; se possível, gera ODT.
14. Quantas linhas se iniciam por 010055102003334796 e por 252747400000004446, e tb me gere um PDF; não precisa abrir o ConsumerAI.
15. Me diga quando o arquivo foi acessado pela última vez, o tamanho, e se ele parece ser um log ou um cadastro/registo fixo.
16. Conta linhas com prefixo 010055102 e 123145734, gera PDF, e no chat resume o resultado em uma frase.
17. Explica o propósito do arquivo, gera PDF, e também informa a data de criação.
18. How many lines start with 010055102 and with 2527474, and also generate a PDF with the counts.
19. Cuántas líneas empiezan con 010055102 y con 010055105, y genera un PDF con el resultado.
20. Soma/conta linhas que começam com 010055102 e 2527474, gera PDF, e no final confirma o caminho do arquivo gerado.
```



## Pré-auditoria de rotas (Q9–20)


| #            | Risco antes                     | Correção aplicada                                                                                                 |
| ------------ | ------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 8            | Filter hit limit + sem explicar | Hits em disco + Continuar; PDF com linhas filtradas = host anexa até N linhas completas (v3.0.5.74); IA só resume |
| 9            | Split sem explicar              | Após `split_equal_parts` → RAG se a IA pedir `consumer_rag` na chain                                              |
| 10           | Merge roubado por compose       | `show_tab_merge_files` primeiro; PDF depois se format id / chain                                                  |
| 11           | Export apagava total de linhas  | `export_lines` **anexa** ao chat (não substitui)                                                                  |
| 12           | Find roubado por compose        | `find_text` primeiro; PDF depois se format id / chain                                                             |
| 13–14, 18–20 | OK                              | `count_line_prefixes` + documento                                                                                 |
| 15           | Meta PT frágil                  | Tokens `foi acessado` / `o tamanho`                                                                               |
| 16           | `Conta`+`prefixo` → ConsumerAI  | Cue `conta` no parse de prefixos                                                                                  |
| 17           | OK (compose + data criação)     | —                                                                                                                 |
| 19 ES        | Contou mas sem PDF              | AI-first: preservar `compose_document` + formato `pdf` (v3.0.5.64+)                                               |




### AI-first (v3.0.5.65–70)

- `ApplyLocalIntentCorrection` **não** troca mais um `ActionId` válido da IA por listas NL (`filtrar`/`juntar`/`gerar`…).
- Pós-IA: `TryCatalogEnrichActionParams` só preenche path / filter_text / parts / line (nunca muda a tool).
- `TryCatalogResolveAction` fica **apenas** no caminho de atalho local (`TryResolveLocalPlan` + `UserQuestionIsExplicitLocalShortcut`) — **sem** LLM.
- Redirects estruturais: prefixos digitais → `count_line_prefixes`; consumer vazio/errado + `pdf` → compose.
- Auto-exec follow-up (Q8–12): **não** usa `LooksLikeExplain`* / `UserWantsApplyFilter` — usa `NativeFollowUpAction` (chain da IA ou `pdf`/`docx`/… estrutural).
- Compose: amostra do ficheiro aberto + pipeline rich-doc por `QuestionSignalsSavedRichDocument` (não verbos NL).
- **v3.0.5.68:** count + PDF — PDF = contagens locais; **não** sobrescrever com resumo de amostra.
- **v3.0.5.70:** se a IA mandou `action` válido com `intent=explain`, promove só o `intent`; prompt reforça chains. Sem dicionário de verbos.
- **v3.0.5.74–75:** PDF com linhas filtradas — host anexa linhas completas; **N** e needle vêm de `params.max_lines` / `filter_text` da IA (não scrape NL da pergunta).



## Observações

- Valores alinhados com `C:\Hamden\PI121106.txt` (amostra das primeiras 50 linhas + ocorrências reais de `2527474` / `010055105` / etc. no ficheiro).
- As frases continuam a ser **exemplos dinâmicos**, não frases “hard-coded” na aplicação.
- Falhas úteis a anotar: responde só uma parte; inventa contagens; não gera PDF; Error 500; dispara o motor SQL/Python (`consumer_ai`) para contagem simples de prefixo (Q14). O painel lateral Chat IA (SQL) já não deve aparecer.
- Ver também: `DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md`.
- **Validar fonte (v3.0.5.136+):** ver [`DOC_ASSISTENTE_IA_VALIDAR_FONTE.md`](DOC_ASSISTENTE_IA_VALIDAR_FONTE.md) — linguagens Python/JS/JSX/TS/TSX; chat *carregar o fonte pra validar* / *quais linguagens valida?*.

### Exemplos rápidos — validar fonte (fora da massa PI121106)

| # | OK? | Pergunta |
|---|-----|----------|
| V1 | ☐ | Quais linguagens de programação a aplicação valida? |
| V2 | ☐ | Carregar o fonte pra validar |
| V3 | ☐ | (Após gerar um `.py`) Validar o fonte |
| V4 | ☐ | Validar `C:\caminho\para\app.tsx` |
| V5 | ☐ | Validar `C:\caminho\para\Unit1.pas` → deve recusar e listar só as suportadas |

