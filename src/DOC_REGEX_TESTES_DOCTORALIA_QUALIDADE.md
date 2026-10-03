# Testes Regex - Foco Qualidade de Dados

Arquivo base:
- C:\Hamden\Files\202210_doctoralia_br.csv

Objetivo:
- Validar estrutura, padrao de campos e identificar dados suspeitos.

## Como usar (resumo)

1. Abra Split file by Pattern/Regex.
2. Selecione o arquivo CSV.
3. Escolha o modo (filter, test, match, replace).
4. Execute o pattern.
5. Valide a saida gerada.

## Bloco A - Estrutura e formato (modo test)

1) CSV com 13 colunas simples
- Modo: Regex test
- Pattern: ^(?:[^,\r\n]*,){12}[^,\r\n]*$
- Esperado: true para linhas validas

2) URL com formato esperado
- Modo: Regex test
- Pattern: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Esperado: true para linhas de dados

3) newest_review_date em ISO (-03:00)
- Modo: Regex test
- Pattern: ,\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-03:00,
- Esperado: true quando houver review date preenchida

4) fetch_time no final da linha
- Modo: Regex test
- Pattern: ,\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$
- Esperado: true para linhas consistentes

5) title dentro do conjunto esperado
- Modo: Regex test
- Pattern: ^\d+,(Dr\.|Dra\.|Prof\.),
- Esperado: true para titulos esperados

## Bloco B - Segmentacao para auditoria (modo filter)

6) telemedicine = 1
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){9}1,
- Esperado: subconjunto de atendimento remoto

7) telemedicine = 0
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){9}0,
- Esperado: subconjunto sem remoto

8) preco vazio
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){10},http://www\.doctoralia\.com\.br/
- Esperado: linhas sem preco numerico

9) preco textual (Consultar valores)
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){10}Consultar valores,http://www\.doctoralia\.com\.br/
- Esperado: linhas com preco textual

10) reviews muito altos (>=1000)
- Modo: Regex filter
- Pattern: ^(?:[^,\r\n]*,){7}[1-9]\d{3,},
- Esperado: casos raros para auditoria

11) possivel mojibake
- Modo: Regex filter
- Pattern: Ã.
- Esperado: linhas com potencial problema de encoding

## Bloco C - Extracao para analise (modo match)

12) extrair doctor_id
- Modo: Regex match
- Pattern: ^\d+
- Esperado: um id por linha

13) extrair specialization
- Modo: Regex match
- Pattern: ^(?:[^,\r\n]*,){6}([^,\r\n]+)
- Esperado: valor da especialidade

14) extrair region
- Modo: Regex match
- Pattern: ^(?:[^,\r\n]*,){5}([^,\r\n]+)
- Esperado: valor da regiao

15) extrair slug de URL
- Modo: Regex match
- Pattern: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Esperado: URL de perfil por linha

## Bloco D - Normalizacao leve (modo replace)

16) padronizar Consultar valores para vazio
- Modo: Regex replace
- Pattern: ,Consultar valores,
- Replacement: ,,
- Esperado: preco textual convertido para vazio

17) normalizar espacos repetidos
- Modo: Regex replace
- Pattern: \s{2,}
- Replacement:  
- Esperado: reduzir espacos duplicados

18) reduzir sufixo -2 no slug (teste tecnico)
- Modo: Regex replace
- Pattern: (http://www\.doctoralia\.com\.br/[a-z0-9-]+)-2(,)
- Replacement: $1$2
- Esperado: slug sem -2 (quando existir)

## Checklist de aprovacao

1. Arquivo final abre sem quebrar colunas principais.
2. Linhas esperadas aparecem no filtro.
3. true/false do modo test fazem sentido para o campo alvo.
4. Replace nao move delimitadores de coluna.
5. Match retorna apenas os tokens esperados.
