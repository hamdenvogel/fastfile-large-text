# Plano de Execucao - Testes Regex Doctoralia

Arquivo base:
- C:\Hamden\Files\202210_doctoralia_br.csv

Duracao estimada: 15 a 20 minutos no total.

Regra geral:
- Sempre rode em modo Preview antes de OK no arquivo completo.
- Guarde os arquivos de saida para comparar com execucoes futuras.
- Os arquivos gerados ficam na mesma pasta do CSV original.

---

## Rodada 1 - Validar estrutura (modos test e filter)

Objetivo: confirmar que o CSV esta saudavel antes de qualquer transformacao.

### Passo 1.1
- Modo: Regex test
- Pattern: ^(?:[^,\r\n]*,){12}[^,\r\n]*$
- Saida: 202210_doctoralia_br.test.csv
- Criterio: quase todas as linhas devem retornar true

### Passo 1.2
- Modo: Regex test
- Pattern: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Saida: 202210_doctoralia_br.test.csv
- Criterio: todas as linhas devem retornar true (165043 linhas)

### Passo 1.3
- Modo: Regex test
- Pattern: ^\d+,(Dr\.|Dra\.|Prof\.),
- Saida: 202210_doctoralia_br.test.csv
- Criterio: maioria true; linhas false indicam outro titulo

### Passo 1.4
- Modo: Regex filter
- Pattern: Ã.
- Saida: 202210_doctoralia_br.filtered.csv
- Criterio: cerca de 80578 linhas na saida (referencia de medicao anterior)

---

## Rodada 2 - Segmentacao por dados de negocio (modo filter)

Objetivo: isolar subconjuntos uteis para analise.

### Passo 2.1
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){9}1,
- Saida: 202210_doctoralia_br.filtered.csv
- Renomear para: doctoralia_telemed_ativo.csv
- Criterio: somente medicos com telemedicina = 1 (referencia: 10557 linhas)

### Passo 2.2
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){10},http://www\.doctoralia\.com\.br/
- Saida: 202210_doctoralia_br.filtered.csv
- Renomear para: doctoralia_sem_preco.csv
- Criterio: somente linhas com preco vazio (referencia: 128352 linhas)

### Passo 2.3
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){10}Consultar valores,http://www\.doctoralia\.com\.br/
- Saida: 202210_doctoralia_br.filtered.csv
- Renomear para: doctoralia_preco_textual.csv
- Criterio: somente preco textual (referencia: 2293 linhas)

### Passo 2.4
- Modo: Regex filter
- Pattern: ,sao-paulo-sp,
- Saida: 202210_doctoralia_br.filtered.csv
- Renomear para: doctoralia_sp.csv
- Criterio: somente regiao SP (referencia: 27968 linhas)

### Passo 2.5
- Modo: Regex filter
- Pattern: ,rio-de-janeiro-rj,
- Saida: 202210_doctoralia_br.filtered.csv
- Renomear para: doctoralia_rj.csv
- Criterio: somente regiao RJ (referencia: 12416 linhas)

### Passo 2.6
- Modo: Regex filter
- Pattern: ,pediatra,
- Saida: 202210_doctoralia_br.filtered.csv
- Renomear para: doctoralia_pediatras.csv
- Criterio: somente pediatras (referencia: 5425 linhas)

---

## Rodada 3 - Extracao de tokens (modo match)

Objetivo: extrair campos individuais para analise ou indexacao.

### Passo 3.1
- Modo: Regex match
- Pattern: ^\d+
- Saida: 202210_doctoralia_br.match.csv
- Criterio: um doctor_id por linha; total deve ser 165043 linhas

### Passo 3.2
- Modo: Regex match
- Pattern: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Saida: 202210_doctoralia_br.match.csv
- Criterio: uma URL por linha; total deve ser 165043 linhas

### Passo 3.3
- Modo: Regex match
- Pattern: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-03:00
- Saida: 202210_doctoralia_br.match.csv
- Criterio: uma data por linha quando houver review date; referencia: 78120 linhas

### Passo 3.4
- Modo: Regex match
- Pattern: \d+
- Saida: 202210_doctoralia_br.match.csv
- Criterio: varias ocorrencias por linha (id, reviews, datas, preco)

---

## Rodada 4 - Transformacoes de limpeza (modo replace)

Objetivo: padronizar dados sem alterar estrutura de colunas.

### Passo 4.1
- Modo: Regex replace
- Pattern: ,Consultar valores,
- Replacement: ,,
- Saida: 202210_doctoralia_br.replaced.csv
- Criterio: campo preco com texto convertido para vazio; 2293 substituicoes esperadas

### Passo 4.2
- Modo: Regex replace
- Pattern: (http://www\.doctoralia\.com\.br/[a-z0-9-]+)-\d+
- Replacement: $1
- Saida: 202210_doctoralia_br.replaced.csv
- Criterio: sufixos -2, -3 etc. removidos de slugs duplicados; referencia: 13444 linhas

### Passo 4.3
- Modo: Regex replace
- Pattern: SÃ£o
- Replacement: Sao
- Saida: 202210_doctoralia_br.replaced.csv
- Criterio: correto para mojibake mais frequente; testar resultado em seguida com filter

---

## Rodada 5 - Anonimizacao (modo replace)

Objetivo: gerar versao sem identificadores diretos.

### Passo 5.1
- Modo: Regex replace
- Pattern: ^(\d+,[^,]*,)[^,]+(,.*)$
- Replacement: $1NOME_OCULTO$2
- Saida: 202210_doctoralia_br.replaced.csv
- Criterio: coluna name mascarada; estrutura CSV preservada

### Passo 5.2
- Modo: Regex replace
- Pattern: (http://www\.doctoralia\.com\.br/)[^,]+
- Replacement: $1perfil-oculto
- Saida: 202210_doctoralia_br.replaced.csv
- Criterio: slug de URL removido; demais colunas intactas

### Passo 5.3 (validacao pos-anonimizacao)
- Modo: Regex test
- Arquivo: usar o .replaced.csv gerado no passo 5.2
- Pattern: ,NOME_OCULTO,
- Criterio: true para todas as linhas confirma que o replace foi aplicado

### Passo 5.4 (validacao estrutural pos-anonimizacao)
- Modo: Regex test
- Arquivo: usar o .replaced.csv gerado no passo 5.2
- Pattern: ^(?:[^,\r\n]*,){12}[^,\r\n]*$
- Criterio: true para todas as linhas confirma que colunas continuam corretas

---

## Rodada 6 - Validacao com sintaxe JS (modo test e filter)

Objetivo: confirmar que o parser de flags /pattern/flags funciona.

### Passo 6.1
- Modo: Regex test
- Pattern: /^\d+,(Dr\.|Dra\.|Prof\.),/
- Esperado: mesmo resultado do passo 1.3

### Passo 6.2
- Modo: Regex filter
- Pattern: /,pediatra,/
- Esperado: mesmo resultado do passo 2.6

### Passo 6.3
- Modo: Regex test
- Pattern: /Pediatra/i
- Esperado: mesmo resultado que /,pediatra,/ (com i ignorando caixa)

### Passo 6.4
- Modo: Regex match
- Pattern: /\d+/g
- Esperado: mesmo resultado do passo 3.4

### Passo 6.5
- Modo: Regex replace
- Pattern: /SÃ£o/g
- Replacement: Sao
- Esperado: mesmo resultado do passo 4.3

---

## Resumo de arquivos gerados esperados

1. 202210_doctoralia_br.test.csv - varios test
2. 202210_doctoralia_br.filtered.csv - varios filter
3. 202210_doctoralia_br.match.csv - varios match
4. 202210_doctoralia_br.replaced.csv - varios replace
5. doctoralia_telemed_ativo.csv - renomeado do passo 2.1
6. doctoralia_sem_preco.csv - renomeado do passo 2.2
7. doctoralia_preco_textual.csv - renomeado do passo 2.3
8. doctoralia_sp.csv - renomeado do passo 2.4
9. doctoralia_rj.csv - renomeado do passo 2.5
10. doctoralia_pediatras.csv - renomeado do passo 2.6

---

## Checklist final

- [ ] Rodada 1 concluida (estrutura validada)
- [ ] Rodada 2 concluida (segmentos gerados)
- [ ] Rodada 3 concluida (tokens extraidos)
- [ ] Rodada 4 concluida (limpeza aplicada)
- [ ] Rodada 5 concluida (anonimizacao aplicada e validada)
- [ ] Rodada 6 concluida (parser JS validado)
