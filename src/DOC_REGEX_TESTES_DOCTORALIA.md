# Guia de testes regex - CSV Doctoralia

Arquivo de referencia:
- C:\Hamden\Files\202210_doctoralia_br.csv

Resumo rapido do dataset (amostra completa lida):
- Total de linhas de dados: 165043
- URL no formato esperado: 165043
- Preco vazio: 128352
- Preco com texto "Consultar valores": 2293
- Linhas com sinal de mojibake (padrao "A."): 80578

## Pacotes focados

Documentos complementares gerados para testes por objetivo:

1. Qualidade de dados:
   - DOC_REGEX_TESTES_DOCTORALIA_QUALIDADE.md
2. Anonimizacao e LGPD:
   - DOC_REGEX_TESTES_DOCTORALIA_ANONIMIZACAO.md
3. Sintaxe JavaScript (/pattern/flags):
   - DOC_REGEX_TESTES_DOCTORALIA_SINTAXE_JS.md
4. Plano de execucao passo a passo (ordem exata recomendada):
   - DOC_REGEX_TESTES_DOCTORALIA_PLANO_EXECUCAO.md

## Como testar no FastFile

1. Abra o menu Split file by Pattern/Regex.
2. Em Source file, selecione C:\Hamden\Files\202210_doctoralia_br.csv.
3. Escolha o modo desejado em Mode:
   - Regex match
   - Regex test
   - Regex replace
   - Regex filter
4. Cole o Pattern/Regex.
5. Se estiver em Regex replace, preencha Replacement.
6. Clique Preview para uma verificacao rapida.
7. Clique OK para processar o arquivo completo.
8. Confira o arquivo de saida na mesma pasta do CSV:
   - .match.csv
   - .test.csv
   - .replaced.csv
   - .filtered.csv

## Regras praticas

- Nos modos regex, o programa ja força uso de regex.
- Em match e replace, o processamento e global (equivalente ao g).
- Voce pode usar padrao simples ou estilo JS /padrao/gi.
- Para evitar erro de CSV, prefira regex que nao atravesse virgulas se o alvo for uma coluna especifica.

## Bateria de testes recomendada

Cada item abaixo traz:
- Objetivo
- Modo
- Pattern/Regex
- Replacement (quando aplicavel)
- Resultado esperado
- Referencia de contagem (quando levantada)

### A. Filter (manter somente linhas que baterem)

1) Telemedicina ativa
- Modo: Regex filter
- Pattern/Regex: ^(?:[^,\r\n]*,){9}1,
- Esperado: somente linhas com telemedicine = 1
- Referencia: 10557 linhas

2) Telemedicina desativada
- Modo: Regex filter
- Pattern/Regex: ^(?:[^,\r\n]*,){9}0,
- Esperado: somente linhas com telemedicine = 0
- Referencia: 154370 linhas

3) Preco vazio
- Modo: Regex filter
- Pattern/Regex: ^(?:[^,\r\n]*,){10},http://www\.doctoralia\.com\.br/
- Esperado: somente linhas sem valor numerico no preco
- Referencia: 128352 linhas

4) Preco com texto "Consultar valores"
- Modo: Regex filter
- Pattern/Regex: ^(?:[^,\r\n]*,){10}Consultar valores,http://www\.doctoralia\.com\.br/
- Esperado: somente linhas com preco textual
- Referencia: 2293 linhas

5) Especialidade pediatra
- Modo: Regex filter
- Pattern/Regex: ,pediatra,
- Esperado: somente linhas da especialidade pediatra
- Referencia: 5425 linhas

6) Especialidade especialista-em-dor
- Modo: Regex filter
- Pattern/Regex: ,especialista-em-dor,
- Esperado: somente linhas da especialidade especialista-em-dor
- Referencia: 212 linhas

7) Regiao sao-paulo-sp
- Modo: Regex filter
- Pattern/Regex: ,sao-paulo-sp,
- Esperado: somente linhas da regiao SP
- Referencia: 27968 linhas

8) Regiao rio-de-janeiro-rj
- Modo: Regex filter
- Pattern/Regex: ,rio-de-janeiro-rj,
- Esperado: somente linhas da regiao RJ
- Referencia: 12416 linhas

9) Linhas com possivel encoding quebrado
- Modo: Regex filter
- Pattern/Regex: Ã.
- Esperado: linhas com sequencias tipicas de mojibake
- Referencia: 80578 linhas

10) Cidade 1 exatamente Rio de Janeiro
- Modo: Regex filter
- Pattern/Regex: ^[^,]*,[^,]*,[^,]*,Rio de Janeiro,
- Esperado: linhas cujo city1 e Rio de Janeiro
- Referencia: 14137 linhas

### B. Test (true/false por linha)

11) Estrutura CSV com 13 colunas simples
- Modo: Regex test
- Pattern/Regex: ^(?:[^,\r\n]*,){12}[^,\r\n]*$
- Esperado: true para quase todas as linhas validas

12) URL no formato esperado
- Modo: Regex test
- Pattern/Regex: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Esperado: true para todas as linhas de dados

13) Campo newest_review_date em ISO com -03:00
- Modo: Regex test
- Pattern/Regex: ,\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-03:00,
- Esperado: true apenas quando houver review date preenchida
- Referencia: 78120 linhas true

14) Campo fetch_time no formato padrao
- Modo: Regex test
- Pattern/Regex: ,\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$
- Esperado: true para linhas validas do arquivo

15) Titulo profissional valido
- Modo: Regex test
- Pattern/Regex: ^\d+,(Dr\.|Dra\.|Prof\.),
- Esperado: true para linhas com um desses titulos

### C. Match (extrair ocorrencias)

16) Extrair doctor_id (primeira coluna)
- Modo: Regex match
- Pattern/Regex: ^\d+
- Esperado: uma saida por linha contendo o id

17) Extrair todos os numeros da linha
- Modo: Regex match
- Pattern/Regex: \d+
- Esperado: varias ocorrencias por linha (id, reviews, datas, preco etc.)

18) Extrair URL do perfil
- Modo: Regex match
- Pattern/Regex: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Esperado: uma URL por linha

19) Extrair slug da URL (sem dominio)
- Modo: Regex match
- Pattern/Regex: [a-z0-9-]+(?=,\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$)
- Esperado: slug final antes do fetch_time

20) Extrair datas no formato ISO
- Modo: Regex match
- Pattern/Regex: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-03:00
- Esperado: uma ocorrencia por linha quando houver newest_review_date

21) Extrair titulos Dr., Dra., Prof.
- Modo: Regex match
- Pattern/Regex: (Dr\.|Dra\.|Prof\.)
- Esperado: titulo encontrado na coluna title

22) Extrair linhas com slug terminado em -2 (como match)
- Modo: Regex match
- Pattern/Regex: http://www\.doctoralia\.com\.br/[a-z0-9-]+-2
- Esperado: apenas URLs com sufixo -2
- Referencia: 13444 ocorrencias

### D. Replace (transformar linha)

23) Anonimizar nome do medico (coluna 3)
- Modo: Regex replace
- Pattern/Regex: ^(\d+,[^,]*,)[^,]+(,.*)$
- Replacement: $1NOME_OCULTO$2
- Esperado: nomes substituidos por NOME_OCULTO

24) Anonimizar URL do perfil
- Modo: Regex replace
- Pattern/Regex: (http://www\.doctoralia\.com\.br/)[^,]+
- Replacement: $1perfil-oculto
- Esperado: slug de URL mascarado

25) Padronizar preco textual para vazio
- Modo: Regex replace
- Pattern/Regex: ,Consultar valores,
- Replacement: ,,
- Esperado: remove texto de preco e deixa coluna vazia

26) Corrigir mojibake mais comum (caso especifico)
- Modo: Regex replace
- Pattern/Regex: SÃ£o
- Replacement: Sao
- Esperado: troca sequencia quebrada por texto normalizado

27) Trocar titulo para forma neutra
- Modo: Regex replace
- Pattern/Regex: ^(\d+,)(Dr\.|Dra\.|Prof\.)(,)
- Replacement: $1Profissional$3
- Esperado: padroniza o titulo na coluna title

### E. Versao em sintaxe JS (opcional)

Se quiser testar no campo Pattern/Regex usando delimitadores e flags:
- /^(?:[^,\r\n]*,){9}1,/
- /,especialista-em-dor,/
- /http:\/\/www\.doctoralia\.com\.br\/[a-z0-9-]+/i
- /SÃ£o/g

## Sugestao de roteiro de QA (10 minutos)

1. Rodar 2 filtros (itens 1 e 3) e comparar contagem com referencias.
2. Rodar 2 testes (itens 11 e 13) e abrir arquivo .test.csv para checar distribuicao true/false.
3. Rodar 2 matches (itens 18 e 20) e validar formato das saidas.
4. Rodar 2 replaces (itens 23 e 25) e conferir se colunas se mantem alinhadas.
5. Validar que nenhuma linha ficou sem final de linha no arquivo de saida.

## Diagnostico rapido de problemas comuns

- Erro de regex invalida:
  - Remova lookbehind, atomic groups e recursos nao suportados por VBScript.RegExp.
- Resultado vazio em match:
  - Teste primeiro o mesmo padrao no modo test para ver se bate.
- Replace alterando colunas erradas:
  - Ancore o padrao com ^ e use grupos para preservar prefixo/sufixo.
- Diferenca de contagem:
  - Confirme se o arquivo fonte e exatamente o mesmo (mesma data e tamanho).
