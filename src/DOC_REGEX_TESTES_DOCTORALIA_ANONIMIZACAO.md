# Testes Regex - Foco Anonimizacao e LGPD

Arquivo base:
- C:\Hamden\Files\202210_doctoralia_br.csv

Objetivo:
- Remover ou mascarar elementos que possam identificar profissionais.

Importante:
- Sempre gerar em arquivo de saida separado.
- Validar algumas linhas antes de aplicar no dataset inteiro.

## Estrategia sugerida

1. Rode primeiro em modo filter para medir impacto.
2. Depois use replace com grupos de captura para preservar estrutura.
3. Confira se o numero de colunas permanece igual.

## Bloco A - Mascaras de identificadores (modo replace)

1) Mascarar nome do medico (coluna name)
- Pattern: ^(\d+,[^,]*,)[^,]+(,.*)$
- Replacement: $1NOME_OCULTO$2
- Esperado: coluna name anonima

2) Mascarar slug da URL
- Pattern: (http://www\.doctoralia\.com\.br/)[^,]+
- Replacement: $1perfil-oculto
- Esperado: URL sem identificador do perfil

3) Mascarar doctor_id
- Pattern: ^\d+
- Replacement: 0
- Esperado: id removido da primeira coluna

4) Padronizar title para valor neutro
- Pattern: ^(\d+,)(Dr\.|Dra\.|Prof\.)(,)
- Replacement: $1Profissional$3
- Esperado: sem genero no titulo

5) Mascarar city1 (teste de blindagem geografica)
- Pattern: ^((?:[^,\r\n]*,){3})[^,\r\n]+(,.*)$
- Replacement: $1CIDADE_OCULTA$2
- Esperado: city1 anonimizada

6) Mascarar city2
- Pattern: ^((?:[^,\r\n]*,){4})[^,\r\n]+(,.*)$
- Replacement: $1cidade-oculta$2
- Esperado: city2 anonimizada

7) Mascarar region
- Pattern: ^((?:[^,\r\n]*,){5})[^,\r\n]+(,.*)$
- Replacement: $1regiao-oculta$2
- Esperado: region anonimizada

## Bloco B - Pseudonimizacao controlada (modo replace)

8) Nome com hash simples de categoria (fixo)
- Pattern: ^(\d+,[^,]*,)[^,]+(,.*)$
- Replacement: $1PSEUDO_PESSOA$2
- Esperado: padrao estavel para testes

9) URL para dominio neutro
- Pattern: http://www\.doctoralia\.com\.br/[a-z0-9-]+
- Replacement: http://www.exemplo.local/perfil
- Esperado: links neutralizados

10) Remover sufixo numerico em nomes de perfil
- Pattern: (http://www\.doctoralia\.com\.br/[a-z0-9-]+)-\d+
- Replacement: $1
- Esperado: reduz variacao do slug

## Bloco C - Validacoes apos anonimizar

11) Conferir que nao restou URL original
- Modo: Regex test
- Pattern: doctoralia\.com\.br/[a-z0-9-]+
- Esperado: false para todas as linhas do arquivo anonimizado

12) Conferir que nome original nao aparece (indicador)
- Modo: Regex test
- Pattern: ,NOME_OCULTO,
- Esperado: true para todas as linhas de dados anonimizado por regra 1

13) Conferir estrutura CSV apos replace
- Modo: Regex test
- Pattern: ^(?:[^,\r\n]*,){12}[^,\r\n]*$
- Esperado: true para linhas validas

14) Conferir campo city1 mascarado
- Modo: Regex test
- Pattern: ^(?:[^,\r\n]*,){3}CIDADE_OCULTA,
- Esperado: true quando regra 5 aplicada

15) Conferir campo region mascarado
- Modo: Regex test
- Pattern: ^(?:[^,\r\n]*,){5}regiao-oculta,
- Esperado: true quando regra 7 aplicada

## Ordem recomendada de execucao

1. Aplicar regra 1 (nome).
2. Aplicar regra 2 (URL).
3. Aplicar regra 3 (id) se necessario.
4. Aplicar regras geograficas (5, 6, 7) conforme nivel de privacidade.
5. Rodar validacoes 11 a 15.

## Criterio de sucesso

1. Identificadores diretos removidos.
2. Estrutura de colunas preservada.
3. Arquivo continua processavel para testes tecnicos.
4. Sem vazamento obvio de nomes/slug original.
