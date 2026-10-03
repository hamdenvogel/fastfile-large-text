# FastFile Script Engine - Delphi para Python (passo a passo tecnico)

Data: 2026-05-01
Escopo: explicar como a linha (e o contexto da linha) sai do Delphi e chega na macro Python, nos dois modos de execucao.
Arquivos principais:
- MainUnit.pas
- data-lake-duckdb-main/ScriptEngine.py

------------------------------------------------------------
1) Visao geral da arquitetura
------------------------------------------------------------

O fluxo tem 3 blocos:

1. UI/Orquestracao (Delphi)
   - Coleta script, define escopo, prepara lote de linhas.
   - Cria TScriptEngineRunThread para nao travar UI.

2. Transporte (pipe stdin/stdout)
   - Delphi escreve comandos texto em UTF-8 para o processo ScriptEngine.exe.
   - Python le stdin linha a linha e responde por stdout.

3. Execucao da macro (Python)
   - Compila o script recebido em SCRIPT:...
   - Chama transform(line, ctx) para cada linha.
   - Retorna OUT, SKIP, LINE_ERROR, PROGRESS, DONE_ACK.

Resumo operacional:
- Delphi envia SCRIPT:<base64>
- Depois envia:
  - LINE:<n>:<texto> para modo selecionado/checked, ou
  - RUNFILE:<base64 payload> para modo all visible lines (ultra rapido)
- Finaliza com DONE (ou RUNFILE faz DONE_ACK ao terminar)

------------------------------------------------------------
2) Onde a execucao comeca no Delphi
------------------------------------------------------------

Entrada principal:
- TfrmMain.ScriptEngineRunClick

Responsabilidades:
- Valida script no editor.
- Garante processo ScriptEngine ativo.
- Faz Base64 do codigo Python e envia como SCRIPT.
- Decide escopo:
  - Selected / checked lines only
  - All visible lines
- Instancia TScriptEngineRunThread com:
  - Script em Base64
  - Lista de linhas selecionadas (se houver)
  - Total de linhas
  - Paths de source e index
  - Encoding de exibicao

------------------------------------------------------------
3) Thread de envio (Delphi): TScriptEngineRunThread
------------------------------------------------------------

Classe:
- TScriptEngineRunThread

Pontos chave:
- Execute roda em background.
- Envia SCRIPT:<base64> primeiro.
- Depois escolhe 1 de 2 caminhos:

A) Modo selected/checklist (por linha)
- Para cada numero de linha:
  1. Le offset da linha no index (temp.txt, 20 bytes por registro).
  2. Le bytes da linha no arquivo fonte.
  3. Converte para texto via DisplayTextFromFileBytes.
  4. Enfileira comando:
     LINE:<line_number_1_based>:<line_text>
- Envio e batelado para pipe:
  - flush por tamanho aproximado (256 KB) ou quantidade (512 linhas)
- Ao final envia DONE.

B) Modo all visible lines (RUNFILE)
- Nao envia linha por linha no pipe.
- Envia um unico comando RUNFILE:<base64 payload> com pares chave=valor:
  - SOURCE
  - INDEX
  - ENC
  - TOTAL
  - MAX_LINE_LEN
  - opcionalmente OUTFILE e SILENT_OUT
- Nesse modo, o Python abre source+index diretamente e processa localmente.

Observacao importante de performance:
- Modo B evita milhoes de writes no pipe quando o arquivo e gigante.
- O custo de IO fica mais local ao processo Python, com menos overhead de protocolo.

------------------------------------------------------------
4) Formato exato dos comandos no protocolo
------------------------------------------------------------

Comandos Delphi -> Python (stdin):
- SCRIPT:<base64 utf8 script>
- LINE:<n>:<text>
- RUNFILE:<base64 utf8 key=value lines>
- DONE
- EXIT

Respostas Python -> Delphi (stdout):
- READY
- COMPILED_OK
- COMPILE_ERROR:<mensagem>
- OUT:<n>:<text>
- SKIP:<n>
- LINE_ERROR:<n>:<mensagem>
- PROGRESS:<percent>:<mensagem>
- DONE_STATS:<ok>:<skip>:<err>
- DONE_ACK
- STATUS:<mensagem>

------------------------------------------------------------
5) Como a linha chega na macro Python
------------------------------------------------------------

Contrato da macro:
- O script deve definir:
  transform(line: str, ctx: dict) -> str | None

No modo LINE:
- Python recebe LINE:<n>:<text>
- Faz parse de n e text
- Atualiza contexto:
  ctx['line_number'] = n
- Chama:
  result = transform(text, ctx)

No modo RUNFILE:
- Python abre source e index
- Reconstrui cada linha por offset
- Para cada linha:
  - ctx['line_number'] = line_number
  - result = transform(line_text, ctx)

Ou seja, em ambos os modos o parametro line e o numero da linha no ctx chegam para a macro.

------------------------------------------------------------
6) Contexto (ctx) disponivel na macro
------------------------------------------------------------

No desenho atual, o contrato garantido explicitamente e:
- ctx['line_number']

Notas:
- O dicionario ctx e reutilizado durante o processamento.
- Isso permite estado incremental se o script quiser acumular dados entre linhas.
- A chave line_number e atualizada a cada iteracao.

Exemplo de uso de estado:
- script guarda contadores em ctx e usa no retorno.

------------------------------------------------------------
7) Encoding e seguranca de texto
------------------------------------------------------------

Delphi -> Python:
- Comandos saem em UTF-8 via ScriptEngineWriteLine (AText + LF).

Python:
- stdin/stdout sao forçados para UTF-8.
- RUNFILE converte bytes da linha para texto com base em ENC:
  - UTF-16 BE
  - UTF-16 LE
  - UTF-8
  - fallback ANSI (mbcs)

Delphi ao ler arquivo no modo LINE:
- Usa index + leitura de bytes e DisplayTextFromFileBytes com encoding selecionado.

------------------------------------------------------------
8) Diferencas praticas entre LINE e RUNFILE
------------------------------------------------------------

LINE (selected/checklist):
- Pro:
  - Processa subconjunto exato (linhas selecionadas/marcadas)
  - Simples de rastrear por comando
- Contra:
  - Mais overhead de pipe em lotes grandes

RUNFILE (all visible lines):
- Pro:
  - Muito mais rapido em arquivos grandes
  - Menos chatter de protocolo
- Contra:
  - Maior dependencia de leitura correta de source/index no lado Python

Regra operacional:
- Escopo total grande: prefira RUNFILE.
- Escopo parcial/seletivo: use LINE.

------------------------------------------------------------
9) Tratamento de erros
------------------------------------------------------------

Erros de compilacao de script:
- Python responde COMPILE_ERROR:...
- Delphi atualiza status e mostra no output.

Erros por linha (runtime do transform):
- Python responde LINE_ERROR:<n>:...
- Processamento continua para outras linhas.

Pipe quebrado durante envio:
- Delphi marca erro Broken pipe while sending lines.

Finalizacao:
- DONE_ACK confirma processamento completo.
- DONE_STATS resume total ok/skip/error (principalmente no RUNFILE).

------------------------------------------------------------
10) Caminho de resposta de volta para UI Delphi
------------------------------------------------------------

Leitura de stdout:
- TScriptEngineReaderThread agrega lotes e sincroniza para UI.

Interpretacao de protocolo:
- HandleScriptEngineProtocolBatch
- HandleScriptEngineProtocolLine

Acoes tipicas:
- OUT vira append no memo de saida.
- PROGRESS alimenta barra de progresso.
- DONE_STATS monta resumo final.
- DONE_ACK encerra ciclo e reabilita botoes.

------------------------------------------------------------
11) Checklist de debug para dev
------------------------------------------------------------

Quando a macro nao processa como esperado, validar nesta ordem:

1. Processo e pipe
- ScriptEngine.exe iniciou?
- READY apareceu?
- ScriptEngineWriteLine retorna True?

2. Compilacao
- COMPILED_OK chegou apos SCRIPT?
- Ha COMPILE_ERROR no output?

3. Escopo
- Radio button esta em selected ou all visible?
- SelectedLines realmente contem itens?

4. Protocolo
- No modo selected, comandos LINE estao sendo enfileirados?
- No modo all, payload RUNFILE contem SOURCE/INDEX/TOTAL corretos?

5. Index e offsets
- temp.txt existe e corresponde ao arquivo aberto?
- Offsets retornados por TryReadIndexOffsetByLineNumber estao validos?

6. Runtime Python
- transform existe e e callable?
- Exceptions por linha aparecem como LINE_ERROR?

7. Retorno UI
- Reader thread esta ativa?
- HandleScriptEngineProtocolLine esta tratando OUT/PROGRESS/DONE?

------------------------------------------------------------
12) Exemplo mental de ponta a ponta
------------------------------------------------------------

Cenario A (selected):
1. Usuario marca 3 linhas e roda script.
2. Delphi envia SCRIPT.
3. Delphi envia 3 comandos LINE.
4. Python executa transform para cada line text.
5. Python responde OUT/SKIP por linha.
6. Delphi mostra output e resumo.

Cenario B (all visible):
1. Usuario escolhe all visible lines.
2. Delphi envia SCRIPT.
3. Delphi envia RUNFILE com paths e metadata.
4. Python percorre source/index internamente com mmap.
5. Python retorna OUT em lote, PROGRESS periodico e DONE_STATS.
6. Delphi atualiza UI e encerra com DONE_ACK.

------------------------------------------------------------
13) Sugestoes de evolucao (opcional)
------------------------------------------------------------

Para enriquecer a macro sem quebrar compatibilidade:
- Adicionar em ctx:
  - file_path
  - total_lines
  - selected_scope (bool)
  - display_encoding
- Expor modo dry-run para medir custo sem materializar output.
- Adicionar versao do protocolo no primeiro handshake (exemplo STATUS:PROTO=v1).

------------------------------------------------------------
14) Diagrama de sequencia (ASCII)
------------------------------------------------------------

14.1) Fluxo selected/checklist (LINE)

Usuario/UI            Delphi Thread                     ScriptEngine.py
   |                      |                                   |
   | clicar Run           |                                   |
   |--------------------->|                                   |
   |                      | SCRIPT:<base64 script>            |
   |                      |---------------------------------->| 
   |                      |                         compile/exec transform
   |                      |<----------------------------------| COMPILED_OK
   |                      |                                   |
   |                      | LINE:10:<texto_l10>              |
   |                      |---------------------------------->| transform(line, ctx)
   |                      |<----------------------------------| OUT:10:<resultado>
   |                      |                                   |
   |                      | LINE:25:<texto_l25>              |
   |                      |---------------------------------->| transform(line, ctx)
   |                      |<----------------------------------| SKIP:25
   |                      |                                   |
   |                      | DONE                              |
   |                      |---------------------------------->| 
   |                      |<----------------------------------| DONE_ACK
   | atualiza memo/status |                                   |
   |<---------------------|                                   |


14.2) Fluxo all visible lines (RUNFILE)

Usuario/UI            Delphi Thread                     ScriptEngine.py
   |                      |                                   |
   | clicar Run           |                                   |
   |--------------------->|                                   |
   |                      | SCRIPT:<base64 script>            |
   |                      |---------------------------------->| 
   |                      |<----------------------------------| COMPILED_OK
   |                      |                                   |
   |                      | RUNFILE:<base64 payload>          |
   |                      |---------------------------------->| parse payload
   |                      |                                   | abre SOURCE+INDEX
   |                      |                                   | loop mmap por linha
   |                      |<----------------------------------| PROGRESS:...
   |                      |<----------------------------------| OUT:<n>:<texto>
   |                      |<----------------------------------| DONE_STATS:o:s:e
   |                      |<----------------------------------| DONE_ACK
   | atualiza memo/status |                                   |
   |<---------------------|                                   |

Observacao:
- Em RUNFILE, o Delphi nao manda cada linha. O Python reconstrui internamente
  usando SOURCE + INDEX e chama transform para cada linha.

------------------------------------------------------------
15) Exemplos reais de macro (copiar e usar)
------------------------------------------------------------

15.1) Filtro simples: manter apenas linhas com ERROR

```python
def transform(line, ctx):
  return line if 'ERROR' in line else None
```

15.2) Prefixar numero da linha no resultado

```python
def transform(line, ctx):
  n = ctx.get('line_number', 0)
  return f"{n:08d} | {line}"
```

15.3) Normalizacao de espacos e TABs

```python
import re

def transform(line, ctx):
  s = line.replace('\t', ' ')
  s = re.sub(r'\s+', ' ', s).strip()
  return s
```

15.4) Exemplo com estado em ctx (contador por nivel)

```python
def transform(line, ctx):
  # Inicializa estado na primeira linha processada
  if 'counts' not in ctx:
    ctx['counts'] = {'ERROR': 0, 'WARN': 0, 'INFO': 0}

  if 'ERROR' in line:
    ctx['counts']['ERROR'] += 1
    tag = f"E{ctx['counts']['ERROR']}"
  elif 'WARN' in line:
    ctx['counts']['WARN'] += 1
    tag = f"W{ctx['counts']['WARN']}"
  elif 'INFO' in line:
    ctx['counts']['INFO'] += 1
    tag = f"I{ctx['counts']['INFO']}"
  else:
    tag = 'N'

  return f"[{tag}] {line}"
```

15.5) Ignorar cabecalho e linhas vazias

```python
def transform(line, ctx):
  n = ctx.get('line_number', 0)
  if n <= 1:
    return None
  if not line.strip():
    return None
  return line
```

15.6) Capturar erro por linha sem parar o processamento

```python
def transform(line, ctx):
  # Exemplo didatico: converte ultimo campo para inteiro
  parts = line.split(';')
  value = int(parts[-1])  # pode levantar excecao
  return f"{line};parsed={value}"
```

Comportamento esperado:
- Se uma linha falhar, o engine gera LINE_ERROR:<n>:... para aquela linha.
- As demais linhas continuam sendo processadas normalmente.

15.7) Boas praticas para macro em arquivo gigante

- Evite regex muito pesada em toda linha sem necessidade.
- Evite criar objetos grandes por linha.
- Prefira logica de string simples quando possivel.
- Use estado em ctx com parcimonia (somente dados pequenos).
- Se o objetivo for filtrar massivamente, retorne None cedo.

------------------------------------------------------------
Fim.
