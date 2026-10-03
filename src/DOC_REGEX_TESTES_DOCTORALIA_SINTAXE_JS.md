# Testes Regex - Foco Sintaxe JavaScript

Arquivo base:
- C:\Hamden\Files\202210_doctoralia_br.csv

Objetivo:
- Testar no FastFile padroes escritos no estilo JS: /pattern/flags.

Observacao:
- O FastFile converte padrao JS para VBScript.RegExp.
- Flags mais usuais:
  - g: global (match/replace ja sao globais por modo)
  - i: case-insensitive
  - m: multiline

## Mapeamento rapido de modos

1. Regex match ~= string.match(/.../g)
2. Regex test ~= regex.test(string)
3. Regex replace ~= string.replace(/.../g, "...")
4. Regex filter ~= array.filter(item => regex.test(item))

## Pacote de testes em sintaxe JS

### A. Filter (JS style)

1) Telemedicina ativa
- Pattern: /^(?:[^,\r\n]*,){9}1,/
- Esperado: linhas com telemedicine = 1

2) Preco vazio
- Pattern: /^(?:[^,\r\n]*,){10},http:\/\/www\.doctoralia\.com\.br\//
- Esperado: linhas com preco vazio

3) Especialidade pediatra
- Pattern: /,pediatra,/
- Esperado: apenas pediatras

4) Encoding suspeito
- Pattern: /Ã./
- Esperado: linhas com potencial mojibake

### B. Test (JS style)

5) Estrutura CSV simples
- Pattern: /^(?:[^,\r\n]*,){12}[^,\r\n]*$/
- Esperado: true para linhas validas

6) URL valida com i
- Pattern: /http:\/\/www\.doctoralia\.com\.br\/[a-z0-9-]+/i
- Esperado: true nas linhas de dados

7) Review date ISO
- Pattern: /,\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-03:00,/
- Esperado: true quando houver review date

8) Titulo permitido
- Pattern: /^\d+,(Dr\.|Dra\.|Prof\.),/
- Esperado: true quando title estiver no conjunto

### C. Match (JS style)

9) Extrair todos os numeros
- Pattern: /\d+/g
- Esperado: varias ocorrencias por linha

10) Extrair URLs
- Pattern: /http:\/\/www\.doctoralia\.com\.br\/[a-z0-9-]+/g
- Esperado: uma URL por linha

11) Extrair titulos
- Pattern: /(Dr\.|Dra\.|Prof\.)/g
- Esperado: ocorrencia do titulo

12) Extrair timestamps
- Pattern: /\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/g
- Esperado: newest_review_date e fetch_time quando casar

### D. Replace (JS style)

13) Mascarar nome
- Pattern: /^(\d+,[^,]*,)[^,]+(,.*)$/
- Replacement: $1NOME_OCULTO$2
- Esperado: nome anonimizado

14) Trocar Consultar valores por vazio
- Pattern: /,Consultar valores,/
- Replacement: ,,
- Esperado: preco textual limpo

15) Mascarar URL
- Pattern: /(http:\/\/www\.doctoralia\.com\.br\/)[^,]+/
- Replacement: $1perfil-oculto
- Esperado: slug removido

16) Corrigir trecho comum de mojibake
- Pattern: /SÃ£o/g
- Replacement: Sao
- Esperado: normalizacao basica

## Casos de flags para validar parser

17) Sem flag: /pediatra/
- Esperado: comportamento padrao

18) Com i: /Pediatra/i
- Esperado: ignora caixa

19) Com g: /\d+/g
- Esperado: no modo match/replace, varias ocorrencias

20) Com gi: /doctoralia/i
- Esperado: match case-insensitive

21) Com m: /^\d+/m
- Esperado: ainda util por linha, validar sem erro

## Dicas de depuracao

1. Se der erro de regex invalida, teste primeiro sem delimitadores /.../.
2. Evite recursos de engines modernas nao suportados por VBScript.RegExp.
3. Se um replace afetar coluna errada, ancore com ^ e grupos.
4. Para confirmar comportamento, rode o mesmo padrao em test antes de filter/replace.

## Mini roteiro de execucao

1. Rodar 4 filtros (1 a 4).
2. Rodar 4 testes (5 a 8).
3. Rodar 4 matches (9 a 12).
4. Rodar 4 replaces (13 a 16).
5. Validar parser de flags (17 a 21).
