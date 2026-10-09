# FastFile — Agente IA: roteiro de testes (QA)

**Data:** 2026-10-07
**Âmbito:** aba **Agente IA** (fontes, pedido, resposta, edições propostas, ações do core, barras de ferramentas, consultas SQL, 14 idiomas)
**Modo:** revisão — nada é gravado em arquivo antes de clicar em **Aceitar**.

Marque cada item com `[x]` quando passar. Se falhar, anote o número do item, tire um print e copie as últimas linhas do log do assistente que contenham `agent` (o log fica na pasta do `.exe`).

---

## 0. Preparação (antes de testar, fora da tela)

Esta seção não é um teste: ela só garante que o agente tenha arquivos para trabalhar e que os resultados esperados deste documento batam com eles.

Os arquivos de teste já estão criados em `C:\Hamden\Files\`:

| Arquivo | Conteúdo | Usado em |
|---|---|---|
| `clientes.csv` | 8 clientes + cabeçalho (UTF-8, separador `;`), listado abaixo | quase todas as seções |
| `log.txt` | 30 linhas com `INFO`, `WARN` e `ERROR` (9 linhas com `ERROR`) | contagem, resumo, split, tail |
| `unicode16.txt` | 3 linhas em UTF-16 | seção 11 (edição em UTF-16 não pode corromper o arquivo) |

Se algum teste alterar esses arquivos (edições aceitas, Substituir tudo, apagar duplicadas), peça para recriá-los antes de repetir os testes.

- [ ] O Assistente IA responde normalmente (confirma que a rede e o gateway de IA estão funcionando).
- [ ] Na aba **Agente IA**, clique em **Adicionar arquivos...** e adicione `C:\Hamden\Files\clientes.csv` e `C:\Hamden\Files\log.txt` em **Fontes**.
- [ ] Opcional: adicione também um arquivo grande seu (de preferência uma **cópia**) para os testes de desempenho e de fechamento durante uma gravação.

Conteúdo de `clientes.csv` (a linha 1 é o cabeçalho; os números de linha esperados nas tabelas contam a partir dele):

```text
id;nome;email;cidade;nascimento
1;Bianca Souza;Bianca.Souza@Gmail.com;São Paulo;12/03/1990
2;Carlos Lima;carlos.lima@hotmail.com;Rio de Janeiro;05/11/1985
3;Bianca Ferreira;BIANCA.F@GMAIL.COM;Curitiba;22/07/1992
4;Ana Paula;ana.paula@gmail.com;São Paulo;30/01/1988
5;Carlos Lima;carlos.lima@hotmail.com;Rio de Janeiro;05/11/1985
6;João Pedro;joao.pedro@yahoo.com;Belo Horizonte;14/09/1979
7;Marina Bianca Alves;marina.alves@gmail.com;São Paulo;03/04/1995
8;Pedro Henrique;pedro.h@outlook.com;Recife;19/12/1991
```

---

## 1. Barras de ferramentas (novas)

### 1.1 Pedido (caixa do prompt)

- [ ] A barra aparece logo abaixo da caixa de texto, acima de **Enviar**, no mesmo visual do Assistente IA (faixa cinza-clara, botões planos em negrito).
- [ ] **Traduzir ▾** com o pedido vazio: status "pergunta vazia", nada acontece.
- [ ] Escreva `quantas linhas tem Bianca?`, clique em **Traduzir ▾** → **English**: o texto vira inglês; o status passa por "Traduzindo…" e termina em "Traduzido".
- [ ] Selecione só uma parte do texto e traduza: **só a seleção** é substituída.
- [ ] Escreva `quero ver os emails repetido e trocar gmail` e clique em **Sugerir**: o texto é reescrito como um pedido claro, no mesmo idioma.
- [ ] **Apagar**: limpa o pedido e o foco volta para a caixa.
- [ ] **Copiar** sem seleção copia o texto todo; com seleção, copia só a seleção. O status mostra "Copiado para a área de transferência".
- [ ] **Copiar** com o pedido vazio: status "Nada para copiar".
- [ ] **Fale com a IA** com o texto `Conte as linhas com Bianca` → pergunte `Esse pedido está claro? Como melhorar?`. A resposta aparece na aba **Resposta**.

### 1.2 Fontes

- [ ] A barra aparece entre a lista e o contador de fontes.
- [ ] **Copiar** sem seleção: copia o caminho de **todas** as fontes, um por linha.
- [ ] **Copiar** com 1 fonte selecionada: copia só esse caminho.
- [ ] **Apagar** com seleção: remove só a(s) selecionada(s), sem perguntar.
- [ ] **Apagar** sem seleção: pede confirmação e remove todas. Cancele uma vez e confirme outra.
- [ ] **Fale com a IA** → `Que tipos de arquivo são esses?`: a IA responde com base apenas nos caminhos (não lê o conteúdo).

### 1.3 Resposta

- [ ] A barra aparece no rodapé da aba **Resposta**.
- [ ] **Copiar** (tudo e com seleção) funciona.
- [ ] **Fale com a IA** → `Resuma isso em uma frase`: a nova resposta substitui a anterior.
- [ ] **Apagar** limpa a resposta; feche e reabra o FastFile: a resposta continua vazia.

### 1.4 Bloqueios durante o processamento

- [ ] Durante **Fale com a IA**, **Traduzir** ou **Sugerir**, ficam desativados: Traduzir, Sugerir, Fale com a IA (nas 3 barras), Apagar da resposta e **Enviar**.
- [ ] Durante um **Enviar** (agente rodando), ficam desativados os mesmos botões e também Apagar do pedido e das fontes.
- [ ] Ao terminar, tudo volta a ficar ativo.
- [ ] Feche o FastFile enquanto **Fale com a IA** está esperando resposta: deve fechar sem erro nem access violation.

### 1.4.1 Botões sem itens ficam desativados

- [ ] Pedido vazio: Traduzir, Sugerir, Novo, Apagar, Copiar e Fale com a IA da barra do pedido ficam desativados; ao digitar, ativam na hora; ao apagar o texto, desativam de novo.
- [ ] Sem arquivos ou pastas: Novo, Apagar, Copiar e Fale com a IA da barra de fontes ficam desativados; ao adicionar um item, ativam; ao remover todos, desativam.
- [ ] Resposta vazia: Novo, Apagar, Copiar e Fale com a IA da barra da resposta ficam desativados; quando chega uma resposta, ativam; **Apagar** desativa de novo.
- [ ] **Edições propostas** vazia: **Aceitar**, **Rejeitar** e **Aceitar tudo** ficam desativados.
- [ ] Com propostas: **Aceitar tudo** ativo; **Aceitar** e **Rejeitar** ativos com um item selecionado. Ao aceitar ou rejeitar um item, o seguinte fica selecionado; ao acabar a lista (ou expirar o tempo), os três desativam.

### 1.5 Resposta antiga com JSON cru

- [ ] Se antes aparecia algo como `{"answer":"","tool":{"name":"count",...}}` na Resposta, ao reabrir agora deve aparecer só o texto da resposta, ou a área vazia.

### 1.6 O que perguntar em "Fale com a IA"

"Fale com a IA" só responde perguntas, em texto, na aba **Resposta**. Não altera arquivos e não cria edições propostas. Para mudar o arquivo (substituir, exportar, dividir), use **Enviar** no pedido.

Cada quadro tem o seu botão "Fale com a IA", e o que vale perguntar depende dele:

1. **Abaixo da lista de arquivos e pastas.** A IA vê apenas os caminhos, não o conteúdo. Exemplos:
   - "Quais desses arquivos parecem ser CSV de clientes?"
   - "Tem algum caminho repetido ou arquivo que provavelmente não deveria estar aqui?"
   - "Pela extensão, qual codificação ou formato devo esperar?"
2. **Abaixo do pedido ("Descreva o que deseja").** A IA vê o texto que você está escrevendo para o agente. É o mais útil para melhorar pedidos:
   - "Esse pedido está claro? Reescreva de forma mais objetiva para o agente."
   - "Que informação está faltando? Por exemplo, coluna, delimitador ou diferenciar maiúsculas."
   - "Divida esse pedido em passos menores."
   - "Isso dá para fazer com SQL? Me mostre a consulta."
3. **Abaixo da resposta.** A IA vê a última resposta do agente:
   - "Explique essa resposta em termos simples."
   - "Resuma em 3 tópicos."
   - "Essa resposta diz que algo foi alterado? O que eu devo fazer agora?"
   - "Traduza para o inglês."

---

## 2. Contagem

| # | Prompt | Esperado |
|---|---|---|
| 2.1 | `Quantas pessoas tem "Bianca" no nome?` | Total de linhas e contagem por arquivo (3 no CSV), com a observação de que conta **linhas**, não pessoas. |
| 2.2 | `Quantas linhas contêm "@gmail.com"?` | Contagem coerente; verifique se o resultado diferencia maiúsculas. |
| 2.3 | `Quantas linhas contêm "@gmail.com", sem diferenciar maiúsculas?` | Conta também `@GMAIL.COM` e `@Gmail.com`. |
| 2.4 | `Quantas vezes aparece "ZZZXXX"?` | 0, sem erro. |
| 2.5 | `Conte as linhas com "São Paulo" e as linhas com "Rio de Janeiro".` | Duas contagens (3 e 2) na mesma resposta. |
| 2.6 | `Quantos ERROR tem no log.txt?` | 9, contando só no `log.txt`. |

---

## 3. Busca e leitura

| # | Prompt | Esperado |
|---|---|---|
| 3.1 | `Em quais linhas aparece "Bianca" no clientes.csv?` | Números de linha reais (2, 4 e 8, contando o cabeçalho como linha 1). |
| 3.2 | `Mostre as linhas 1 a 5 do clientes.csv.` | Conteúdo exato das linhas. |
| 3.3 | `Qual é o cabeçalho de cada arquivo?` | Primeira linha de cada fonte. |
| 3.4 | `Mostre a linha 999999999 do clientes.csv.` | Diz que a linha passa do fim do arquivo, sem travar. |
| 3.5 | `Quais arquivos estão selecionados?` | Lista das fontes. |
| 3.6 | `Mostre as 5 últimas linhas do log.txt.` | Linhas finais corretas. |

---

## 4. Análise

| # | Prompt | Esperado |
|---|---|---|
| 4.1 | `Que colunas tem o CSV e qual é o separador?` | `id;nome;email;cidade;nascimento`, separador `;`. |
| 4.2 | `Existe algum e-mail repetido no CSV?` | `carlos.lima@hotmail.com` (linhas 3 e 6). |
| 4.3 | `Existe alguma linha duplicada inteira?` | Linhas do Carlos Lima (3 e 6). |
| 4.4 | `Resuma o log.txt: quantos erros e quais os principais?` | Resumo baseado no que foi lido, sem inventar. |
| 4.5 | `Qual cidade aparece mais vezes?` | São Paulo (3). |

### 4.1 Nome exato × busca parcial

| # | Prompt | Esperado |
|---|---|---|
| 4.6 | `Quantos registros têm o nome exatamente "Carlos Lima"?` | 2 (linhas 3 e 6). |
| 4.7 | `Quantos registros têm a palavra "Bianca" no nome, palavra inteira?` | 3 (linhas 2, 4 e 8); usa palavra inteira (`WORD_MATCH` ou busca de palavra inteira). |
| 4.8 | `Procura parcial por "ian" no nome.` | Busca parcial (`LIKE '%ian%'`): 3 linhas (2, 4 e 8). |
| 4.9 | `Exporte os registros com o nome exatamente "Pedro".` | **Não** usa `export_filtered` com busca parcial; pega só a palavra inteira "Pedro" (linhas 7 e 9) e propõe `export_lines` com essas linhas. |

---

## 4A. Consultas SQL (o prompt vira SQL)

O agente traduz o pedido em SQL e o FastFile executa a consulta, lendo o arquivo uma única vez. Em **todos** os itens, confira:

- no fim da resposta aparece o bloco **"Comando SQL executado pelo FastFile:"** com o SQL e a tabela de resultado (**"Resultado: N linha(s):"** ou **"Resultado: exibindo N de M linhas:"**);
- os números da tabela batem com os da coluna **Esperado** (eles vêm do FastFile, não da IA);
- durante a execução, o status mostra **"Executando SQL..."**.

O SQL da coluna **SQL provável** é só uma referência; a IA pode escrever de outro jeito, desde que o resultado seja o mesmo.

### 4A.1 Consultas (SELECT)

| # | Prompt | SQL provável | Esperado |
|---|---|---|---|
| 4A.1 | `Quantos registros tem o clientes.csv?` | `SELECT COUNT(*)` | 8 |
| 4A.2 | `Qual o somatório e a média da coluna id?` | `SELECT SUM(id), AVG(id)` | 36 e 4,5 |
| 4A.3 | `Quantos registros por cidade, do maior para o menor?` | `GROUP BY cidade ORDER BY 2 DESC` | São Paulo 3, Rio de Janeiro 2; Curitiba, Belo Horizonte e Recife 1 |
| 4A.4 | `Quantas cidades diferentes existem?` | `COUNT(DISTINCT cidade)` | 5 |
| 4A.5 | `Quantos e-mails diferentes existem?` | `COUNT(DISTINCT email)` | 7 |
| 4A.6 | `Quantos clientes por domínio de e-mail?` | `GROUP BY LOWER(SPLIT_PART(email,'@',2))` | gmail.com 4, hotmail.com 2, yahoo.com 1, outlook.com 1 (maiúsculas ignoradas) |
| 4A.7 | `Quantos clientes nasceram antes de 1990?` | `WHERE YEAR(nascimento) < 1990` | 4 (linhas 3, 5, 6 e 7) |
| 4A.8 | `Quantos clientes por ano de nascimento, ordenados pelo ano?` | `GROUP BY YEAR(nascimento) ORDER BY 1` | 1979: 1, 1985: 2, 1988: 1, 1990: 1, 1991: 1, 1992: 1, 1995: 1 |
| 4A.9 | `Liste nome e cidade dos clientes de São Paulo ordenados por nome.` | `SELECT nome, cidade WHERE cidade = 'São Paulo' ORDER BY nome` | Ana Paula, Bianca Souza, Marina Bianca Alves |
| 4A.10 | `Mostre os 3 primeiros clientes em ordem alfabética.` | `ORDER BY nome LIMIT 3` | Ana Paula, Bianca Ferreira, Bianca Souza |
| 4A.11 | `Quais cidades têm mais de 1 cliente?` | `GROUP BY cidade HAVING COUNT(*) > 1` | São Paulo (3) e Rio de Janeiro (2) |
| 4A.12 | `Classifique os clientes em "antigo" (id ≤ 4) e "novo"; quantos de cada?` | `CASE WHEN id <= 4 ...` | antigo 4, novo 4 |
| 4A.13 | `Quantos e-mails são do gmail, sem diferenciar maiúsculas?` | `WHERE email LIKE '%gmail%'` | 4 (linhas 2, 4, 5 e 8) |
| 4A.14 | `Usando SQL, quantas linhas do log.txt contêm ERROR?` | `SELECT COUNT(*) WHERE line LIKE '%ERROR%'` | 9; funciona mesmo o `log.txt` não sendo CSV (a coluna `line` é a linha inteira). |
| 4A.15 | `Liste os clientes de São Paulo e exporte para um arquivo.` | `SELECT ... WHERE cidade = 'São Paulo'` e depois `export_lines` | Proposta de exportação das linhas 2, 5 e 8 (só roda ao Aceitar). |

### 4A.2 Alterações por SQL (viram propostas para Aceitar)

`UPDATE`, `DELETE` e `INSERT` **não gravam nada**: viram propostas em **Edições propostas**. Confira a pré-visualização e use **Rejeitar** ou **Aceitar**.

| # | Prompt | SQL provável | Esperado |
|---|---|---|---|
| 4A.16 | `Troque a cidade "São Paulo" por "SP" em todos os registros.` | `UPDATE SET cidade = 'SP' WHERE cidade = 'São Paulo'` | 3 linhas alteradas (2, 5 e 8); só o campo cidade muda, o resto da linha fica igual. |
| 4A.17 | `Deixe todos os e-mails em minúsculas.` | `UPDATE SET email = LOWER(email)` | Linhas 2 e 4 alteradas; as que já estão em minúsculas não geram proposta. |
| 4A.18 | `Apague os clientes do Recife.` | `DELETE WHERE cidade = 'Recife'` | Proposta de exclusão da linha 9. |
| 4A.19 | `Apague os registros com id maior que 6.` | `DELETE WHERE id > 6` | Exclusão das linhas 8 e 9. |
| 4A.20 | `Inclua o cliente 9; Lucas Rocha; lucas@uol.com.br; Natal; 01/02/2000.` | `INSERT INTO ... VALUES (...)` | Inserção depois da última linha de dados, respeitando o separador `;`. |
| 4A.21 | `Troque a cidade para "Rio, RJ" onde for Rio de Janeiro.` | `UPDATE ... SET cidade = 'Rio, RJ'` | Nas linhas 3 e 6, o valor é gravado normalmente (o separador é `;`, então a vírgula não exige aspas). |
| 4A.22 | Rejeite todas as propostas de 4A.16 a 4A.21 e reabra o arquivo. | — | O arquivo continua idêntico ao original. |

### 4A.3 Limites do SQL

| # | Prompt | Esperado |
|---|---|---|
| 4A.23 | `Cruze o clientes.csv com o log.txt pelo nome (JOIN).` | Explica que JOIN entre arquivos não é suportado; não inventa resultado. |
| 4A.24 | `Apague a tabela clientes (DROP TABLE).` | Recusa (não apaga arquivos); pode sugerir `TRUNCATE` para esvaziar os dados. Nada é proposto sem pedir. |
| 4A.25 | `Salve a contagem por cidade num arquivo novo.` | Mostra a tabela, mas explica que exportar um resultado agrupado para um arquivo novo ainda não existe. |
| 4A.26 | `Qual a soma da coluna email?` | Responde sem erro; aparece a observação "SUM(email) ignorou 8 valor(es) não numérico(s)". |

### 4A.4 SQL digitado direto no pedido (sem IA)

Quando o pedido **é** um comando SQL válido, o FastFile executa direto, sem chamar a IA (a resposta é imediata). A resposta começa com **"Comando SQL detectado: executado diretamente pelo FastFile, sem a IA."** Se só o `clientes.csv` estiver nas fontes, o nome depois de `FROM` pode ser qualquer um.

| # | Pedido (digite exatamente) | Esperado |
|---|---|---|
| 4A.27 | `SELECT cidade, COUNT(*) AS total FROM clientes GROUP BY cidade ORDER BY total DESC` | Resposta imediata com a tabela de 4A.3, sem o status de "turno" da IA. |
| 4A.28 | `select nome from clientes where nome like '%bianca%'` (minúsculas) | 3 linhas: Bianca Souza, Bianca Ferreira, Marina Bianca Alves. |
| 4A.29 | `UPDATE clientes SET cidade = 'SP' WHERE cidade = 'São Paulo';` | Mensagem "3 linha(s) a alterar em 3 proposta(s)... clique em Aceitar"; propostas nas linhas 2, 5 e 8. |
| 4A.30 | `DELETE FROM clientes WHERE id = 8` | 1 proposta de exclusão (linha 9). |
| 4A.31 | `INSERT INTO clientes VALUES (9, 'Lucas Rocha', 'lucas@uol.com.br', 'Natal', '01/02/2000')` | 1 proposta de inserção no fim. |
| 4A.32 | `UPDATE clientes SET cidade = 'X' WHERE id = 999` | "Nenhuma linha seria alterada; nada foi proposto." |
| 4A.33 | `SELECT nme FROM clientes` (coluna errada) | A IA entra em ação: corrige para `nome` e executa, **ou** explica o erro no idioma da interface. |
| 4A.34 | `SELEC * FROM clientes` (erro de digitação) | Não começa com palavra SQL: vai para a IA como pedido normal; ela deve entender e executar. |
| 4A.35 | `Delete as linhas 5 a 7 do clientes.csv` | **Não** é tratado como SQL (frase em português): a IA propõe excluir as linhas 5 a 7. |
| 4A.36 | Com `clientes.csv` **e** `log.txt` nas fontes: `SELECT COUNT(*) FROM clientes` | Executa no `clientes.csv` (escolhido pelo nome depois de FROM). |

### 4A.5 Estrutura do arquivo (DDL) — viram propostas para Aceitar

Funciona digitando o SQL **ou** pedindo em linguagem natural. Rejeite as propostas no fim.

| # | Pedido | SQL provável | Esperado |
|---|---|---|---|
| 4A.37 | `Adicione uma coluna pais com o valor "BR" em todos os registros.` | `ALTER TABLE clientes ADD COLUMN pais DEFAULT 'BR'` | Linhas 1 a 9 alteradas: o cabeçalho ganha `;pais` e cada registro ganha `;BR`. |
| 4A.38 | `Crie uma coluna nome_maiusculo, logo depois de nome, com o nome em maiúsculas.` | `ALTER TABLE ... ADD COLUMN nome_maiusculo DEFAULT UPPER(nome) AFTER nome` | Linha 2: `1;Bianca Souza;BIANCA SOUZA;Bianca.Souza@Gmail.com;...` |
| 4A.39 | `Remova a coluna nascimento.` | `ALTER TABLE ... DROP COLUMN nascimento` | Todas as linhas perdem o último campo; o cabeçalho fica `id;nome;email;cidade`. |
| 4A.40 | `Renomeie a coluna cidade para municipio.` | `ALTER TABLE ... RENAME COLUMN cidade TO municipio` | Só a linha 1 muda. |
| 4A.41 | `Apague todos os registros, mas mantenha o cabeçalho.` | `TRUNCATE TABLE clientes` | Proposta de exclusão das linhas 2 a 9; a linha 1 fica. |
| 4A.42 | `ALTER TABLE clientes ADD COLUMN nome` | — | Erro explicado: a coluna já existe. |
| 4A.43 | `DROP TABLE clientes` / `CREATE TABLE x (a INT)` | — | Recusa explicada: o agente não apaga nem cria arquivos por SQL. |
| 4A.44 | Repita 4A.37 num CSV salvo em **UTF-8 com BOM**, aceite e abra no Bloco de Notas. | — | O cabeçalho continua correto e o BOM continua lá (o arquivo não fica corrompido). |

### 4A.6 Linguagem natural, várias formas e vários idiomas

A mesma intenção, escrita de jeitos diferentes, deve gerar o mesmo resultado (rejeite as propostas no fim de cada item).

| # | Pedidos (teste alguns de cada linha) | Esperado |
|---|---|---|
| 4A.45 | `favor atualizar a cidade do id 6 para Contagem` · `atualize ...` · `dê um update na linha 7 trocando a cidade para Contagem` · `muda a cidade do João Pedro para Contagem` | Proposta só na linha 7, mudando apenas o campo cidade. |
| 4A.46 | `favor inserir o cliente 9, Lucas Rocha, lucas@uol.com.br, Natal, 01/02/2000` · `inclua ...` · `adicione um registro ...` | Proposta de inserção no fim, com os campos na ordem das colunas. |
| 4A.47 | `apague o cliente Pedro Henrique` · `remova o registro de id 8` · `exclua quem mora em Recife` | Proposta de exclusão da linha 9. |
| 4A.48 | Inglês: `Update the city to "SP" where it is São Paulo` · Espanhol: `Actualiza la ciudad a "SP" donde sea São Paulo` · Francês: `Mettez la ville à « SP » là où c'est São Paulo` · Alemão: `Ändere die Stadt auf „SP“, wo sie São Paulo ist` | Mesmas propostas de 4A.16 (linhas 2, 5 e 8); resposta no idioma do pedido. |
| 4A.49 | Italiano: `Elimina i clienti di Recife` · Polonês: `Usuń klientów z Recife` · Romeno: `Șterge clienții din Recife` · Húngaro: `Töröld a recife-i ügyfeleket` · Tcheco: `Smaž zákazníky z Recife` | Proposta de exclusão da linha 9; resposta no idioma do pedido. |
| 4A.50 | Japonês: `都市ごとの顧客数を多い順に表示して` · Chinês simplificado: `按城市统计客户数量，从多到少排序` · Chinês tradicional: `按城市統計客戶數量，從多到少排序` | Tabela igual a 4A.3; resposta no idioma do pedido. |
| 4A.51 | Português de Portugal: `Acrescente uma coluna país com o valor PT` | Proposta igual a 4A.37 (coluna com acento no nome é aceita). |

### 4A.7 Total de registros encontrados

O total só aparece quando há um critério que seleciona registros (contagem, exportação, `SELECT` com `WHERE`). Pedidos que só alteram ou apagam **não** mostram "Total".

| # | Pedido | Esperado |
|---|---|---|
| 4A.52 | `Quantos registros aparecem como Bianca, procura parcial? Pode exportar eles pra mim?` | Proposta `export_matching_lines "Bianca"` com o título terminando em **"Total: 3 registro(s)"**; na Resposta, a linha **"Total: 3 registro(s) encontrado(s) para "Bianca"."** |
| 4A.53 | `Exporte as linhas que contêm "ZZZXXX".` | Nada é proposto; a Resposta mostra **"Total: 0 registro(s) encontrado(s) para "ZZZXXX"."** |
| 4A.54 | `Quantas linhas contêm "@gmail.com"?` | A Resposta termina com "Total: 4 registro(s) encontrado(s) para "@gmail.com"." (maiúsculas ignoradas). |
| 4A.55 | `Exporte os registros com o nome exatamente "Pedro".` | Proposta `export_lines` (linhas 7 e 9) com **"Total: 2 registro(s)"** no título. |
| 4A.56 | `SELECT nome FROM clientes WHERE cidade = 'São Paulo'` | Antes do "Resultado", a linha **"Total: 3 registro(s) encontrado(s)."** |
| 4A.57 | `SELECT cidade, COUNT(*) FROM clientes WHERE id > 2 GROUP BY cidade` | "Total: 6 registro(s) encontrado(s)." (registros que atendem ao WHERE) e o resultado agrupado. |
| 4A.58 | `SELECT COUNT(*) FROM clientes` (sem WHERE) · `DELETE FROM clientes WHERE id = 8` · `Apague a linha 5.` | **Sem** linha "Total" (não há critério de busca, ou é só uma exclusão). |
| 4A.59 | Repita 4A.52 em en, de, ja e zh-TW | "Total: …" traduzido em cada idioma (ex.: "Gesamt: 3 Datensatz/Datensätze für "Bianca" gefunden.", ""Bianca" の合計: 3 件のレコードが見つかりました。"). |

---

## 5. Edições de linha (Edições propostas → Aceitar)

Em **todos** os itens, confira:

- o arquivo **não muda** antes de clicar em **Aceitar**;
- a pré-visualização mostra as linhas antigas (`-`) e as novas (`+`);
- **Rejeitar** remove a proposta sem gravar nada.

| # | Prompt | Esperado |
|---|---|---|
| 5.1 | `Troque "Bianca" por "BIANCA" na primeira linha onde aparece.` | Busca primeiro, depois propõe substituir a linha 2. |
| 5.2 | `Insira a linha "# revisado pelo agente" antes da linha 1.` | Proposta de inserção. |
| 5.3 | `Acrescente a linha "FIM" no final do clientes.csv.` | Inserção depois da última linha. |
| 5.4 | `Apague as linhas 5 a 7 do clientes.csv.` | Proposta de exclusão de 3 linhas. |
| 5.5 | `Deixe o e-mail da linha 4 em minúsculas.` | `bianca.f@gmail.com`. |
| 5.6 | `Corrija "Joao" para "João" no log.txt.` | Edição nas linhas do `log.txt` com "Usuario Joao autenticado". |

---

## 6. Várias edições e Aceitar tudo

- [ ] `Insira 3 linhas em branco antes da linha 2 e depois apague a linha 8.` Aceite **uma de cada vez**: na segunda pré-visualização, a linha a apagar já aparece deslocada (agora linha 11) e é a linha original certa.
- [ ] `Apague a linha 4 e substitua a linha 4 por "teste".` As propostas se sobrepõem: **Aceitar tudo** deve recusar e pedir para aceitar uma de cada vez.
- [ ] Peça 3 edições em lugares diferentes e use **Aceitar tudo**: as três são gravadas.
- [ ] Com edições de linha **e** ações do core na lista, **Aceitar tudo** grava só as edições e avisa que as ações devem ser aceitas uma a uma.

### 6.1 Tempo para decidir (contagem regressiva)

- [ ] Ao terminar o pedido com propostas, aparece à direita de **Aceitar tudo** o aviso "Expira em 20 s" contando para baixo (vermelho nos últimos 5 s). A dica do aviso explica a regra.
- [ ] Sem clicar em nada até zerar: a lista de propostas é esvaziada, aparece "Tempo esgotado", o status diz que nada foi gravado e o arquivo **não** muda. Enviar de novo refaz as propostas.
- [ ] Clicar em **Aceitar** / **Rejeitar** / **Aceitar tudo** e deixar a confirmação aberta por mais de 20 s: a contagem fica parada enquanto a confirmação está aberta. Respondendo "Não", ela continua de onde parou.
- [ ] Rejeitar ou aceitar uma proposta quando há outras: a contagem recomeça do início para as restantes. Sem propostas restantes, o aviso some.
- [ ] Pré-visualização ampliada (duplo clique) aberta: o título mostra a contagem; ao zerar, a janela fecha sozinha e as propostas são descartadas.
- [ ] Pelo Assistente IA (botão Agente): ao zerar, a faixa "Aceitar tudo / Revisar no Agente / Rejeitar tudo" some e a resposta recebe a mensagem de tempo esgotado.
- [ ] **Opções → Preferências → Agente IA**: mudar para 60 e confirmar; o próximo pedido conta a partir de 60 s.
- [ ] Nas Preferências, deixar o campo vazio, digitar `abc`, `-5`, `4`, `601`, `2,5` ou `$14`: cada caso mostra a crítica, o campo volta para 20 e o diálogo continua aberto. Com OK de novo, salva 20.
- [ ] Editar `ASkin.ini` à mão (`[UserPrefs] AgentDecisionSeconds=xyz` ou `=0`): ao abrir, vale o padrão de 20 s.
- [ ] **Restaurar padrões** nas Preferências volta o campo para 20.
- [ ] Trocar o idioma durante a contagem: o aviso e a dica mudam de idioma e a contagem continua.

---

## 7. Descaracterização

- [ ] `Descaracterize os e-mails e as datas das linhas 2 a 9 do CSV.`
- [ ] `Descaracterize os nomes do arquivo inteiro, mantendo a palavra "Bianca".`
- [ ] `Descaracterize só as colunas 2 e 3 (separador ;), sem mexer no cabeçalho.`
- [ ] Na pré-visualização, o tamanho e o tipo dos caracteres são mantidos (letra vira letra, dígito vira dígito).
- [ ] Depois de **Aceitar**, o arquivo é alterado e o FastFile recarrega o arquivo aberto.

---

## 8. Ações do core executadas depois da resposta (só visualização)

Essas ações **não alteram arquivos**. Elas rodam automaticamente na janela principal **depois** que a resposta chega, e não durante a conversa. Se a ação for sobre um arquivo diferente do que está aberto, o FastFile abre esse arquivo primeiro.

| # | Prompt | Esperado |
|---|---|---|
| 8.1 | `Abra o clientes.csv e vá para a linha 5.` | Abre na aba Ler e posiciona na linha 5. |
| 8.2 | `Vá para o fim do log.txt.` | Abre o log e vai para o final. |
| 8.3 | `Vá para o byte 100 do clientes.csv.` | Posiciona no byte 100. |
| 8.4 | `Procure "Carlos" no clientes.csv.` | Busca na tela e destaca a ocorrência. |
| 8.5 | `Procure "bianca" diferenciando maiúsculas.` | Busca case-sensitive (não acha "Bianca"). |
| 8.6 | `Filtre na tela as linhas com "São Paulo".` | Filtro aplicado (3 linhas). |
| 8.7 | `Filtre com regex as linhas que terminam em 19\d\d.` | Filtro regex. |
| 8.8 | `Limpe o filtro.` | Filtro removido. |
| 8.9 | `Ative o modo CSV com cabeçalho.` | Modo CSV ligado, com cabeçalho. |
| 8.10 | `Ligue a quebra de linha e aumente o zoom.` | Word wrap ligado e zoom maior. |
| 8.11 | `Mostre os espaços e tabulações.` | Marcas de espaço em branco visíveis. |
| 8.12 | `Marque a linha atual e vá para o próximo marcador.` | Marcador criado e navegação. |
| 8.13 | `Inicie o tail no log.txt` / `Pause o tail.` | Tail liga e pausa. |
| 8.14 | `Recarregue o arquivo.` | Recarrega o arquivo aberto. |
| 8.15 | `Abra a aba Comparar.` / `Abra Recentes.` | Troca de aba. |
| 8.16 | `Abra a ajuda` / `Mostre o Sobre` / `Mostre o histórico de versões.` | Abre a tela pedida. |
| 8.17 | `Abra Localizar` / `Abra Substituir` / `Abra Localizar em arquivos.` | Abre o diálogo correspondente. |
| 8.18 | `Coloque em tela cheia.` | Alterna tela cheia. |

Ações extras (fora do catálogo do Assistente):

| # | Prompt | Esperado |
|---|---|---|
| 8.19 | `Crie um arquivo novo.` | Mesmo efeito do menu Novo arquivo. |
| 8.20 | `Abra as preferências.` | Abre as preferências do usuário. |
| 8.21 | `Mostre a barra de marcadores.` | Alterna a barra de marcadores. |
| 8.22 | `Restaure as abas da última sessão.` | Restaura as abas. |
| 8.23 | `Abra a tela de descaracterização.` | Vai para a aba Ler e abre o diálogo. |

---

## 9. Ações do core propostas para Aceitar

Essas ações aparecem em **Edições propostas** e **só rodam ao clicar em Aceitar**, uma de cada vez. Cada uma pede confirmação antes de rodar; **Substituir tudo** usa a confirmação própria.

### 9.1 Alteram o arquivo

| # | Prompt | Esperado |
|---|---|---|
| 9.1 | `Substitua todos os "@hotmail.com" por "@email.com" no clientes.csv.` | Proposta "Substituir tudo"; ao Aceitar, confirmação e gravação. |
| 9.2 | `Substitua todos os "gmail" por "GMAIL" diferenciando maiúsculas.` | Só troca as ocorrências em minúsculas. |
| 9.3 | `Apague as linhas duplicadas do clientes.csv.` | Proposta; ao Aceitar, remove a linha repetida do Carlos. |
| 9.4 | Peça uma edição de linha **e** `Substitua todos...` no mesmo arquivo; aceite a ação. | As propostas de linha do mesmo arquivo são descartadas (ficariam com números de linha errados). |
| 9.5 | Com edições não salvas no arquivo aberto, aceite um "Substituir tudo". | A gravação é bloqueada com aviso. |

### 9.2 Geram arquivos novos (o original não muda)

| # | Prompt | Esperado |
|---|---|---|
| 9.6 | `Divida o log.txt em 3 partes iguais.` | Split em 3 arquivos. |
| 9.7 | `Divida o arquivo grande em 5000 partes.` | Recusa: o limite é de 2 a 1000 partes. |
| 9.8 | `Extraia as partes 2 a 4 de 10 do log.txt.` | Extração das partes pedidas. |
| 9.9 | `Divida o log.txt por padrão sempre que aparecer "ERROR".` | Split por padrão. |
| 9.10 | `Exporte as linhas 2 a 5 do clientes.csv.` | Exporta o intervalo. |
| 9.11 | `Exporte as linhas que contêm "São Paulo".` | Exporta as linhas correspondentes. |
| 9.12 | `Filtre "ERROR" e exporte o resultado do filtro.` | Exporta o filtrado. |
| 9.13 | `Exporte o clientes.csv.` | Exportação do arquivo. |
| 9.14 | `Extraia as strings mais frequentes do log.txt.` | Extração de frequentes. |

### 9.2.1 Janela "Arquivo gerado com sucesso"

Quando uma exportação termina, abre uma janela com o arquivo gerado. Isso vale para as exportações do agente (9.10 a 9.13, 4A.52, 4A.55) e para as exportações manuais da aba Ler.

| # | Ação | Esperado |
|---|---|---|
| 9.21 | Aceite a proposta de 4A.52. | A janela abre com o ícone verde, o título **"Arquivo gerado com sucesso"**, a linha **"3 registro(s) exportado(s) · tamanho"** e um cartão com o nome do arquivo e a pasta. |
| 9.22 | Clique no cartão **ou** no link **"▶ Clique aqui para abrir o arquivo gerado"**. | A janela fecha e o arquivo abre na aba Ler do FastFile. |
| 9.23 | Clique em **"Abrir com o programa padrão do Windows"**. | O arquivo abre no programa associado (por exemplo, o Excel para `.csv`). |
| 9.24 | Clique em **Abrir pasta**. | O Explorer abre com o arquivo selecionado. |
| 9.25 | Clique em **Copiar caminho**. | O botão mostra **"✓ Copiado!"** por cerca de 1,5 s e depois volta ao texto normal; o caminho completo fica na área de transferência. |
| 9.26 | Pressione **Esc** ou clique em **Fechar**. | A janela fecha e nada é aberto. Pressionar **Enter** equivale a **Abrir no FastFile**. |
| 9.27 | Arraste a janela por uma área vazia. | A janela se move. |
| 9.28 | Exporte linhas manualmente pela aba Ler (sem o agente): botão **Exportar** da barra de filtro, Ctrl+Shift+L, **Exportar** da lista e da barra de marcadores. | Aparece a mesma janela em todos. |
| 9.29 | Abra um arquivo grande **recém-aberto** (ainda sem índice de linhas), peça `Exporte as linhas com "Allyne"` e aceite. | O índice é criado, o filtro roda e **em seguida** o arquivo é gerado e a janela abre. Antes, nesse caso, o filtro rodava e a exportação era perdida. |
| 9.30 | Depois de 9.21, feche a janela e clique em **↗ Último arquivo gerado** (barra da aba **Resposta** do Agente IA). | A mesma janela reabre, com o mesmo arquivo e a mesma contagem de registros. |
| 9.31 | Pressione **Ctrl+Alt+O** ou use **Ferramentas → Exportar → Último arquivo gerado...** ou o menu **Mais** da barra do arquivo. | Reabre a janela. |
| 9.32 | No painel do Assistente, no aviso "Arquivo salvo", clique em **Detalhes**. | Reabre a janela daquele arquivo. |
| 9.33 | Feche e reabra o FastFile; repita 9.30. | Funciona: o último arquivo é lembrado entre sessões. |
| 9.34 | Apague o arquivo gerado no Explorer e pressione **Ctrl+Alt+O**. | Aviso traduzido "O último arquivo gerado não existe mais: ..." com o caminho. |
| 9.35 | Numa instalação sem nenhuma exportação, pressione **Ctrl+Alt+O**. | Aviso "Nenhum arquivo foi gerado ainda."; o botão **↗ Último arquivo gerado** fica desabilitado. |
| 9.36 | Troque o idioma (en, de, ja, zh-TW) e passe o mouse sobre o botão **↗ Último arquivo gerado**. | Legenda, dica (com o caminho do arquivo), item de menu e botão **Detalhes** traduzidos e com acentuação correta. |
| 9.37 | Divida o arquivo em 3 partes iguais (Dividir arquivo ou "divida em 3 partes" no Agente IA). | Abre a janela "3 arquivos gerados com sucesso": tamanho total, tempo, cartão da pasta e as 3 partes listadas (nome cortado no meio, `.part001.csv` visível, tamanho à direita). |
| 9.38 | Na janela de 9.37, clique na segunda parte. | A janela fecha e a `.part002` abre no FastFile. |
| 9.39 | Divida em 12 partes. | Mostra 8 partes e "... e mais 4 arquivo(s) na pasta"; **Abrir pasta** abre o Explorer com a primeira parte selecionada; **Copiar caminhos** copia os 12 caminhos (um por linha). |
| 9.40 | Depois de 9.37, pressione **Ctrl+Alt+O** (também após reabrir o FastFile). | Reabre a janela com as 3 partes. |
| 9.41 | Extrair só algumas partes (ex.: partes 2 a 3 de 5), dividir por linhas, dividir por padrão, Regex Match/Replace/Filter, juntar partes, exportar linhas finais (tail), exportar do histórico (aba Comparar e janela de detalhe). | Todas terminam com a mesma janela (um arquivo ou lista de arquivos), em vez da mensagem de texto antiga. |
| 9.42 | Passo 1: botão **Recentes ▾** ao lado da busca → escolher pasta/arquivo; Alt+↓ na busca; filtrar, apagar um item (X), "Limpar tudo", Propriedades de uma pasta. | Item escolhido entra na lista de fontes e fica selecionado; item inexistente some da lista com aviso; pasta continua na lista depois de Propriedades; lista persiste após reiniciar. |
| 9.43 | Assistente IA → ligar o botão **Agente** (fica pressionado) → com `clientes.csv` aberto: "troque Ltda por LTDA em todas as linhas". | Resposta mostra "O Agente IA está trabalhando em clientes.csv…", o status acompanha o progresso; ao terminar aparece a faixa "N edição(ões) proposta(s) - nada foi gravado ainda" com **Aceitar tudo / Revisar no Agente / Rejeitar tudo**. Arquivo **não** muda. |
| 9.44 | Na faixa do item 9.43: clicar **Revisar no Agente**. | Abre a aba Agente IA já na aba "Edições propostas", com a primeira edição em pré-visualização. |
| 9.45 | Na faixa: **Aceitar tudo** → confirmar. | Pede confirmação; grava; a resposta do Assistente ganha o resultado ("aplicado…"); a faixa some; o arquivo aberto é recarregado. |
| 9.46 | Repetir 9.43 e clicar **Rejeitar tudo** → confirmar. | Pergunta "Descartar a(s) N edição(ões)…?"; nada é gravado; a faixa some; a aba Agente fica sem edições. |
| 9.47 | Com o botão **Agente** ligado, sem arquivo aberto. | Mensagem "nenhum arquivo aberto"; nada é enviado. |
| 9.48 | Botão **Agente** desligado: "quantas linhas tem o arquivo?" e "modo agente: corrija as datas para AAAA-MM-DD". | A 1ª continua rápida como antes (Assistente normal); a 2ª é encaminhada ao Agente (mesmo fluxo do 9.43). |
| 9.49 | Durante o 9.43, clicar **Cancelar** na tela de espera. | Pedido é interrompido; Assistente mostra "Pedido interrompido" e volta a aceitar perguntas. |
| 9.50 | Trocar o idioma (ex.: 日本語, Deutsch) com o painel aberto. | Botão Agente, dica, faixa e botões aparecem traduzidos. |

### 9.3 Sessão e configurações

| # | Prompt | Esperado |
|---|---|---|
| 9.15 | `Salve a sessão` / `Carregue a sessão.` | Proposta; roda ao Aceitar. |
| 9.16 | `Limpe todos os marcadores.` | Proposta; roda ao Aceitar. |
| 9.17 | `Force a indexação do arquivo.` | Proposta; roda ao Aceitar. |
| 9.18 | `Ative o modo somente leitura.` | Proposta; roda ao Aceitar. |
| 9.19 | `Mude a política de abertura para instantânea` / `para índice` / `automática.` | Proposta; roda ao Aceitar. |
| 9.20 | `Ative o Zero Scan` / `Ative as operações segmentadas sempre.` | Proposta; roda ao Aceitar. |

---

## 10. Recusas (o agente deve dizer claramente que não faz)

| # | Prompt | Esperado |
|---|---|---|
| 10.1 | `Converta o clientes.csv para UTF-16.` | Diz que conversão de encoding não existe no FastFile. |
| 10.2 | `Converta as quebras de linha para LF (Unix).` | Diz que conversão de EOL não existe. |
| 10.3 | `Ordene as linhas do CSV por nome.` | Mostra o resultado ordenado por SQL (`ORDER BY nome`), mas diz que reordenar o próprio arquivo não existe. |
| 10.4 | `Edite os bytes do arquivo binário.` | Recusa. |
| 10.5 | `Desfaça a última alteração.` | Diz que desfazer não está disponível para o agente. |
| 10.6 | `Apague todo o conteúdo do arquivo.` | Recusa (`clear_file` bloqueado) ou propõe algo seguro, sem gravar sem Aceitar. |
| 10.7 | `Abra o Consumer AI` / `Rode o RAG.` | Recusa com explicação. |
| 10.8 | `Leia o arquivo C:\Windows\win.ini.` | Recusa: o arquivo está fora das fontes. |
| 10.9 | `Divida o C:\Windows\win.ini em 2 partes.` | Recusa pelo mesmo motivo. |

---

## 11. Casos-limite e robustez

- [ ] `oi`: resposta curta e normal, sem JSON cru.
- [ ] Pergunta em inglês (`How many lines contain "Bianca"?`): resposta em inglês.
- [ ] Pergunta em espanhol: resposta em espanhol.
- [ ] Clique em **Parar** durante uma pergunta: status "Requisição interrompida", sem erro.
- [ ] Pedido muito longo (cole umas 50 linhas de texto): funciona ou dá um aviso claro.
- [ ] Sem fontes, clique em **Enviar**: "Selecione um arquivo ou pasta primeiro".
- [ ] Com o pedido vazio, clique em **Enviar**: "Escreva um pedido primeiro".
- [ ] Pasta com muitos arquivos como fonte (respeitando máscara, profundidade e máximo de arquivos em **Opções**): aba **Arquivos encontrados** com a contagem.
- [ ] Feche o FastFile **durante um Aceitar** com o arquivo grande: aparece o aviso de espera e nada fica gravado pela metade.
- [ ] Feche o FastFile durante uma pergunta (antes da resposta): fecha sem access violation.
- [ ] Adicione `C:\Hamden\Files\unicode16.txt` às fontes e peça `Troque "Bianca" por "BIANCA" no unicode16.txt.`: ao Aceitar, grava corretamente ou falha com mensagem clara. Em nenhum caso o arquivo pode ficar corrompido (abra-o no Bloco de Notas para conferir).
- [ ] Um pedido que exija muitos passos (por exemplo, `conte Bianca, Carlos, Ana, Pedro, João e Marina separadamente`): termina com resposta, ou com a contagem parcial e aviso de limite de passos, sem erro.

---

## 12. Persistência, recentes e idioma

- [ ] Envie alguns prompts e abra **Recentes**: pesquisar, apagar um e apagar todos.
- [ ] Feche e reabra o FastFile: fontes, pedido, resposta e aba ativa voltam.
- [ ] Troque o idioma (por exemplo, es, fr, de, cs, ja): nenhum botão das barras fica cortado e as legendas Apagar, Copiar, Fale com a IA, Traduzir e Sugerir aparecem traduzidas.
- [ ] Com o idioma trocado, o menu **Traduzir ▾** continua listando os 14 idiomas.

### 12.1 Os 14 idiomas

Idiomas: en, pt-BR, es, fr, de, it, pl, pt-PT, ro, hu, cs, ja, zh-CN, zh-TW. Teste pelo menos en, de, ja e zh-TW, e os outros se houver tempo.

- [ ] Com o FastFile em cada idioma, passe o mouse sobre **Enviar**: a dica aparece traduzida.
- [ ] Rode uma consulta SQL (por exemplo 4A.3): o título **"Comando SQL executado pelo FastFile:"**, a linha **"Resultado: ..."** e o status **"Executando SQL..."** aparecem no idioma da interface.
- [ ] Digite um SQL direto (4A.27 e 4A.29): as mensagens **"Comando SQL detectado..."**, **"N linha(s) a alterar em N proposta(s)..."** (com os nomes da aba e do botão no idioma da interface) e **"Nenhuma linha seria alterada..."** (4A.32) aparecem traduzidas e com acentuação correta.
- [ ] 4A.26 no idioma testado: a observação sobre valores não numéricos aparece traduzida.
- [ ] 4A.33 no idioma testado: a explicação do erro vem no idioma da interface.
- [ ] Abra a descaracterização pelo agente (seção 7): o resumo de opções na pré-visualização (números, datas, e-mails, códigos, nomes, colunas) aparece traduzido.
- [ ] Desligue a rede e clique em **Enviar**: a mensagem de erro de conexão aparece traduzida (pode trazer o detalhe técnico entre parênteses).
- [ ] Faça o pedido **no idioma** da interface (por exemplo, em alemão `Wie viele Kunden pro Stadt?`, em japonês `都市ごとの顧客数は?`): a IA responde no mesmo idioma e mostra a tabela correta (igual a 4A.3).
- [ ] Peça uma alteração no idioma testado (por exemplo, em francês `Remplacez la ville "Recife" par "PE"`): a proposta aparece em **Edições propostas** e a resposta **não diz** que já gravou nada.
- [ ] Peça algo que exija várias ferramentas, no idioma testado: o agente não para numa resposta do tipo "vou contar…" sem ter contado.
- [ ] Repita 9.21 no idioma testado: o título, a contagem, os dois links, os quatro botões e o "✓ Copiado!" aparecem traduzidos, com acentuação correta e sem texto cortado (em de: "Datei erfolgreich erstellt", "Hier klicken, um die erstellte Datei zu öffnen"; em zh-TW: "檔案已成功產生").
- [ ] Peça um nome exato no idioma testado (por exemplo, em inglês `How many records have exactly the name "Carlos Lima"?`): 2, sem pegar resultados parciais.

---

## 13. Resumo da execução

| Seção | Passou | Falhou | Observações |
|---|---|---|---|
| 1. Barras de ferramentas | | | |
| 2. Contagem | | | |
| 3. Busca e leitura | | | |
| 4. Análise (e nome exato × parcial) | | | |
| 4A. Consultas SQL | | | |
| 5. Edições de linha | | | |
| 6. Várias edições | | | |
| 7. Descaracterização | | | |
| 8. Ações de visualização | | | |
| 9. Ações para Aceitar | | | |
| 10. Recusas | | | |
| 11. Casos-limite | | | |
| 12. Persistência e 14 idiomas | | | |
