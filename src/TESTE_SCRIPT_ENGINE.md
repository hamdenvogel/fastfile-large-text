# Guia de Teste — Script Engine (FastFile)

---

## Pré-requisitos

- Delphi 7 instalado e configurado
- Python 3.x instalado
- PyInstaller disponível (já usado por outros `.bat` do projeto)

---

## Passo 1 — Gerar o `ScriptEngine.exe`

Abra um terminal na pasta `data-lake-duckdb-main\` e execute:

```
build_exe_scriptengine.bat
```

Aguarde o PyInstaller terminar. Verifique que o arquivo `ScriptEngine.exe` apareceu na pasta raiz de `data-lake-duckdb-main\`.

---

## Passo 2 — Compilar o FastFile no Delphi 7

- Abra `FastFile.dpr` no Delphi 7
- Menu **Project → Build All**
- Certifique que compila sem erros

---

## Passo 3 — Abrir um arquivo de teste no FastFile

- Execute o FastFile compilado
- Abra qualquer arquivo `.txt` com algumas linhas  
  (ex: `arquivoTeste.txt` que já existe na pasta do projeto)

---

## Passo 4 — Abrir o painel Script Engine

- Pressione **Ctrl+Alt+E** (ou use o menu correspondente)
- O painel lateral do Script Engine deve aparecer com:
  - Editor de script (área de texto superior)
  - Painel de output (área de resultado)
  - Botões: **Run**, **Save**, **Close**

---

## Passo 5 — Escrever um script de teste simples

No editor, cole o seguinte script Python:

```python
def transform(line, ctx):
    return line.upper()
```

Este script converte cada linha para maiúsculas — fácil de verificar visualmente no output.

---

## Passo 6 — Executar o script

- Escolha o escopo: **All lines** ou **Selected lines**
- Clique em **Run**
- Observe no painel de output as linhas transformadas
- Ao terminar, deve aparecer a mensagem de resumo:

  > `Script completed: X lines processed successfully, 0 skipped, 0 errors.`

---

## Passo 7 — Testar casos extras

### 7.1 — Erro de compilação (testa `COMPILE_ERROR`)

```python
def transform(line, ctx)  # faltou o ':'
    return line
```

**Esperado:** mensagem de erro de compilação exibida no painel de output.

---

### 7.2 — Pular linhas em branco (testa `SKIP`)

```python
def transform(line, ctx):
    if line.strip() == '':
        return None  # linha em branco → SKIP
    return line
```

**Esperado:** contador de "skipped" incrementa para cada linha em branco.

---

### 7.3 — Erro em runtime (testa `LINE_ERROR`)

```python
def transform(line, ctx):
    return int(line)  # vai falhar se a linha não for um número
```

**Esperado:** contador de "errors" incrementa, mensagem `LINE_ERROR` aparece no output para cada linha não numérica.

---

### 7.4 — Adicionar prefixo com número de linha

```python
def transform(line, ctx):
    n = ctx.get('line_number', 0)
    return f"[{n:04d}] {line}"
```

**Esperado:** cada linha no output aparece prefixada com seu número, ex: `[0001] conteúdo da linha`.

---

### 7.5 — Filtrar apenas linhas que contêm uma palavra-chave

```python
KEYWORD = 'erro'

def transform(line, ctx):
    if KEYWORD.lower() in line.lower():
        return line
    return None  # linhas sem a palavra → SKIP
```

**Esperado:** apenas as linhas contendo "erro" aparecem no output; as demais incrementam o contador de "skipped".

---

### 7.6 — Remover espaços extras e normalizar linha

```python
import re

def transform(line, ctx):
    # Remove espaços duplos e strip nas bordas
    return re.sub(r' {2,}', ' ', line.strip())
```

**Esperado:** linhas com espaços múltiplos são normalizadas para espaço simples.

---

### 7.7 — Extrair e reformatar campos CSV simples

```python
def transform(line, ctx):
    parts = line.split(';')
    if len(parts) < 3:
        return None  # linha inválida → SKIP
    nome, data, valor = parts[0], parts[1], parts[2]
    return f"{nome.strip()} | {data.strip()} | R$ {valor.strip()}"
```

**Esperado:** linhas com pelo menos 3 campos separados por `;` são reformatadas; as demais são puladas.

---

### 7.8 — Contar palavras por linha

```python
def transform(line, ctx):
    words = line.split()
    return f"{len(words):3d} palavras: {line}"
```

**Esperado:** cada linha recebe no início a contagem de suas palavras.

---

### 7.9 — Substituição múltipla com dicionário

```python
REPLACEMENTS = {
    'erro':    'ERROR',
    'aviso':   'WARNING',
    'info':    'INFO',
    'sucesso': 'SUCCESS',
}

def transform(line, ctx):
    result = line
    for old, new in REPLACEMENTS.items():
        result = result.replace(old, new)
    return result
```

**Esperado:** as palavras mapeadas são substituídas em todas as linhas.

---

### 7.10 — Usar variável de estado entre linhas (via `ctx`)

```python
def transform(line, ctx):
    # ctx persiste entre chamadas para o mesmo script
    count = ctx.get('count', 0) + 1
    ctx['count'] = count
    return f"#{count} {line}"
```

**Esperado:** as linhas são numeradas sequencialmente usando o dicionário `ctx` como estado persistente.

---

## Resumo dos cenários e resultados esperados

| Cenário | Resultado esperado |
|---|---|
| Script OK | Linhas aparecem no output, resumo com 0 erros |
| Compile error | Mensagem de erro de compilação no output |
| `None` retornado | Contador de "skipped" incrementa |
| Exception no `transform` | Contador de "errors" incrementa, `LINE_ERROR` exibido |

---

## Estrutura do protocolo (referência)

| Direção | Token | Significado |
|---|---|---|
| Delphi → Python | `SCRIPT:<base64>` | Envia o código do script compilado |
| Delphi → Python | `LINE:<n>:<text>` | Envia uma linha para transformar |
| Delphi → Python | `DONE` | Sinaliza fim do processamento |
| Delphi → Python | `EXIT` | Encerra o processo Python |
| Python → Delphi | `READY` | Python inicializado e aguardando |
| Python → Delphi | `COMPILED_OK` | Script compilado com sucesso |
| Python → Delphi | `COMPILE_ERROR:<msg>` | Erro na compilação do script |
| Python → Delphi | `OUT:<n>:<text>` | Resultado transformado da linha n |
| Python → Delphi | `SKIP:<n>` | Linha n foi pulada (retornou `None`) |
| Python → Delphi | `LINE_ERROR:<n>:<msg>` | Erro ao processar a linha n |
| Python → Delphi | `DONE_ACK` | Confirmação de fim do processamento |
| Python → Delphi | `STATUS:<msg>` | Mensagem informativa de status |

---

## Passo 8 — Validar i18n do uSmoothLoading (11 idiomas)

Objetivo: confirmar que as mensagens de progresso/tempo/erro do `uSmoothLoading.pas` estão traduzidas corretamente e sem problemas de acentuação/codificação.

### 8.1 — Trocar idioma da aplicação

- Altere o idioma para cada um dos 11 suportados:
    - EN, PT-BR, ES, FR, DE, IT, PL, PT-PT, RO, HU, CZ

### 8.2 — Cenário de leitura de arquivo

- Abra um arquivo grande o suficiente para exibir overlay de loading
- Verifique mensagens como:
    - `Reading file...`
    - `Time to read: %s millisecs. Total lines: %d.`

**Esperado:** texto no idioma ativo e sem caracteres quebrados.

### 8.3 — Cenário de edição de linha

- Execute operações de inserir/substituir/excluir linha
- Verifique mensagens:
    - `Editing file (insert)...`
    - `Editing file (replace)...`
    - `Editing file (delete)...`
    - `Time to execute that operation: %s millisecs.`

**Esperado:** mensagens coerentes no idioma ativo, com acentuação correta.

### 8.4 — Cenário de exportação

- Exporte linhas para arquivo e também para clipboard
- Verifique mensagens:
    - `Exporting lines...`
    - `Exporting lines to file...`
    - `Export finished! File saved to: %s`
    - `Export finished! Lines copied to clipboard.`

**Esperado:** mensagens traduzidas corretamente nos dois fluxos.

### 8.5 — Cenário de merge/split

- Execute operações de merge e split
- Verifique mensagens:
    - `Merging ...`
    - `Merge completed in: %s millisecs.`
    - `Splitting file...`
    - `Split completed. %d file(s) created in %s.`

**Esperado:** sem fallback indevido para inglês quando o idioma ativo for outro.

### 8.6 — Cenário de erro

- Force um erro controlado (arquivo bloqueado/permissão insuficiente)
- Verifique mensagens:
    - `Error: `
    - `Merge Error: `
    - `Split Error: `
    - `Operation failed or cancelled.`

**Esperado:** prefixos e mensagens no idioma ativo, sem caracteres truncados.

### Checklist final por idioma

- Overlay e mensagens visíveis estão traduzidos
- Strings de tempo aparecem corretas
- Mensagens de erro aparecem com prefixos corretos
- Não há caracteres corrompidos (acentos, cedilha, diacríticos)

---

## Matriz de Aprovação i18n — uSmoothLoading (11 idiomas)

> **Nota sobre encoding:** As strings abaixo refletem os valores reais armazenados
> em `uI18n.pas → AddSmoothLoadingTranslations` (ASCII-safe por compatibilidade com
> Delphi 7 ANSI). Idiomas com diacríticos nativos como PL, HU, CZ e RO aparecem
> **sem acentos/diacríticos** no executável (limitação de string literal ANSI/Delphi 7).
> Para PL, RO, HU, CZ, os prefixos `Error: ` e `Operation failed or cancelled.` fazem
> **fallback para inglês** (seeded via `GTextXxx.Assign(GTextEnglish)`).
> Para FR, ES, PT-BR, IT — os prefixos de erro (`Erreur:`, `Operación...`, etc.)
> **estão acentuados** pois foram definidos em seções anteriores via `#nnn`.

---

### Referência de strings esperadas em runtime

#### EN — English
| Cenário | String esperada |
|---|---|
| Leitura | `Reading file...` |
| Edição (inserir) | `Editing file (insert)...` |
| Edição (substituir) | `Editing file (replace)...` |
| Edição (excluir) | `Editing file (delete)...` |
| Merge | `Merging ...` |
| Merge concluído | `Merge completed in: %s millisecs.` |
| Merge erro | `Merge Error: ` |
| Exportar linhas | `Exporting lines...` |
| Exportar para arquivo | `Exporting lines to file...` |
| Export → arquivo | `Export finished! File saved to: %s` |
| Export → clipboard | `Export finished! Lines copied to clipboard.` |
| Replace All | `Replace All completed. %d replacement(s). Time: %s ms.` |
| Split | `Splitting file...` |
| Split concluído | `Split completed. %d file(s) created in %s.` |
| Split erro | `Split Error: ` |
| Erro genérico | `Error: ` |
| Operação falhou | `Operation failed or cancelled.` |
| Tempo de leitura | `Time to read: %s millisecs. Total lines: %d.` |
| Tempo de operação | `Time to execute that operation: %s millisecs.` |

#### PT-BR — Português (Brasil)
| Cenário | String esperada |
|---|---|
| Leitura | `Lendo arquivo...` |
| Edição (inserir) | `Editando arquivo (inserir)...` |
| Edição (substituir) | `Editando arquivo (substituir)...` |
| Edição (excluir) | `Editando arquivo (excluir)...` |
| Merge | `Mesclando ...` |
| Merge concluído | `Mesclagem concluida em: %s milissegundos.` |
| Merge erro | `Erro de mesclagem: ` |
| Exportar linhas | `Exportando linhas...` |
| Exportar para arquivo | `Exportando linhas para arquivo...` |
| Export → arquivo | `Exportacao concluida! Arquivo salvo em: %s` |
| Export → clipboard | `Exportacao concluida! Linhas copiadas para a area de transferencia.` |
| Replace All | `Substituir tudo concluido. %d substituicao(oes). Tempo: %s ms.` |
| Split | `Dividindo arquivo...` |
| Split concluído | `Divisao concluida. %d arquivo(s) criado(s) em %s.` |
| Split erro | `Erro ao dividir: ` |
| Erro genérico | `Erro: ` *(acentuado — via seção anterior `#nnn`)* |
| Operação falhou | `Operação falhou ou foi cancelada.` *(acentuado — via `#nnn`)* |
| Tempo de leitura | `Tempo de leitura: %s milissegundos. Total de linhas: %d.` |
| Tempo de operação | `Tempo para executar essa operacao: %s milissegundos.` |

#### ES — Español
| Cenário | String esperada |
|---|---|
| Leitura | `Leyendo archivo...` |
| Edição (inserir) | `Editando archivo (insertar)...` |
| Edição (substituir) | `Editando archivo (reemplazar)...` |
| Edição (excluir) | `Editando archivo (eliminar)...` |
| Merge | `Combinando ...` |
| Merge concluído | `Combinacion completada en: %s milisegundos.` |
| Merge erro | `Error de combinacion: ` |
| Exportar linhas | `Exportando lineas...` |
| Exportar para arquivo | `Exportando lineas a archivo...` |
| Export → arquivo | `Exportacion finalizada. Archivo guardado en: %s` |
| Export → clipboard | `Exportacion finalizada. Lineas copiadas al portapapeles.` |
| Replace All | `Reemplazar todo completado. %d reemplazo(s). Tiempo: %s ms.` |
| Split | `Dividiendo archivo...` |
| Split concluído | `Division completada. %d archivo(s) creado(s) en %s.` |
| Split erro | `Error al dividir: ` |
| Erro genérico | `Error: ` |
| Operação falhou | `Operación fallida o cancelada.` *(acentuado — via `#nnn`)* |
| Tempo de leitura | `Tiempo de lectura: %s milisegundos. Lineas totales: %d.` |
| Tempo de operação | `Tiempo para ejecutar esa operacion: %s milisegundos.` |

#### FR — Français
| Cenário | String esperada |
|---|---|
| Leitura | `Lecture du fichier...` |
| Edição (inserir) | `Edition du fichier (insertion)...` |
| Edição (substituir) | `Edition du fichier (remplacement)...` |
| Edição (excluir) | `Edition du fichier (suppression)...` |
| Merge | `Fusion ...` |
| Merge concluído | `Fusion terminee en : %s millisecondes.` |
| Merge erro | `Erreur de fusion : ` |
| Exportar linhas | `Export des lignes...` |
| Exportar para arquivo | `Export des lignes vers le fichier...` |
| Export → arquivo | `Export termine ! Fichier enregistre dans : %s` |
| Export → clipboard | `Export termine ! Lignes copiees dans le presse-papiers.` |
| Replace All | `Remplacement global termine. %d remplacement(s). Temps : %s ms.` |
| Split | `Decoupage du fichier...` |
| Split concluído | `Decoupage termine. %d fichier(s) cree(s) en %s.` |
| Split erro | `Erreur de decoupage : ` |
| Erro genérico | `Erreur: ` *(via seção anterior)* |
| Operação falhou | `Opération échouée ou annulée.` *(acentuado — via `#nnn`)* |
| Tempo de leitura | `Temps de lecture : %s millisecondes. Total des lignes : %d.` |
| Tempo de operação | `Temps pour executer cette operation : %s millisecondes.` |

#### DE — Deutsch
| Cenário | String esperada |
|---|---|
| Leitura | `Datei wird gelesen...` |
| Edição (inserir) | `Datei wird bearbeitet (Einfuegen)...` |
| Edição (substituir) | `Datei wird bearbeitet (Ersetzen)...` |
| Edição (excluir) | `Datei wird bearbeitet (Loeschen)...` |
| Merge | `Zusammenfuehren ...` |
| Merge concluído | `Zusammenfuehren abgeschlossen in: %s Millisekunden.` |
| Merge erro | `Zusammenfuehrungsfehler: ` |
| Exportar linhas | `Zeilen werden exportiert...` |
| Exportar para arquivo | `Zeilen werden in Datei exportiert...` |
| Export → arquivo | `Export abgeschlossen! Datei gespeichert unter: %s` |
| Export → clipboard | `Export abgeschlossen! Zeilen in Zwischenablage kopiert.` |
| Replace All | `Alle ersetzen abgeschlossen. %d Ersetzung(en). Zeit: %s ms.` |
| Split | `Datei wird aufgeteilt...` |
| Split concluído | `Aufteilung abgeschlossen. %d Datei(en) in %s erstellt.` |
| Split erro | `Aufteilungsfehler: ` |
| Erro genérico | `Fehler: ` *(via seção anterior)* |
| Operação falhou | `Vorgang fehlgeschlagen oder abgebrochen.` |
| Tempo de leitura | `Lesezeit: %s Millisekunden. Gesamtzeilen: %d.` |
| Tempo de operação | `Ausfuehrungszeit dieser Operation: %s Millisekunden.` |

#### IT — Italiano
| Cenário | String esperada |
|---|---|
| Leitura | `Lettura file...` |
| Edição (inserir) | `Modifica file (inserimento)...` |
| Edição (substituir) | `Modifica file (sostituzione)...` |
| Edição (excluir) | `Modifica file (eliminazione)...` |
| Merge | `Unione ...` |
| Merge concluído | `Unione completata in: %s millisecondi.` |
| Merge erro | `Errore di unione: ` |
| Exportar linhas | `Esportazione righe...` |
| Exportar para arquivo | `Esportazione righe su file...` |
| Export → arquivo | `Esportazione completata! File salvato in: %s` |
| Export → clipboard | `Esportazione completata! Righe copiate negli appunti.` |
| Replace All | `Sostituisci tutto completato. %d sostituzione(i). Tempo: %s ms.` |
| Split | `Suddivisione file...` |
| Split concluído | `Suddivisione completata. %d file creato(i) in %s.` |
| Split erro | `Errore di suddivisione: ` |
| Erro genérico | `Errore: ` *(via seção anterior)* |
| Operação falhou | `Operazione fallita o annullata.` |
| Tempo de leitura | `Tempo di lettura: %s millisecondi. Righe totali: %d.` |
| Tempo de operação | `Tempo per eseguire questa operazione: %s millisecondi.` |

#### PL — Polski *(diacríticos polacos ausentes — ASCII-safe no executável)*
| Cenário | String esperada |
|---|---|
| Leitura | `Odczytywanie pliku...` |
| Edição (inserir) | `Edycja pliku (wstawianie)...` |
| Edição (substituir) | `Edycja pliku (zastepowanie)...` |
| Edição (excluir) | `Edycja pliku (usuwanie)...` |
| Merge | `Scalanie ...` |
| Merge concluído | `Scalanie zakonczone w: %s ms.` |
| Merge erro | `Blad scalania: ` |
| Exportar linhas | `Eksport linii...` |
| Exportar para arquivo | `Eksport linii do pliku...` |
| Export → arquivo | `Eksport zakonczony! Plik zapisano w: %s` |
| Export → clipboard | `Eksport zakonczony! Linie skopiowano do schowka.` |
| Replace All | `Zamien wszystko zakonczono. %d podmiana(y). Czas: %s ms.` |
| Split | `Dzielenie pliku...` |
| Split concluído | `Dzielenie zakonczone. Utworzono %d plik(ow) w %s.` |
| Split erro | `Blad dzielenia: ` |
| Erro genérico | `Error: ` *(fallback EN — não sobrescrito)* |
| Operação falhou | `Operation failed or cancelled.` *(fallback EN — não sobrescrito)* |
| Tempo de leitura | `Czas odczytu: %s ms. Laczna liczba linii: %d.` |
| Tempo de operação | `Czas wykonania tej operacji: %s ms.` |

#### PT-PT — Português (Portugal)
| Cenário | String esperada |
|---|---|
| Leitura | `A ler ficheiro...` |
| Edição (inserir) | `A editar ficheiro (inserir)...` |
| Edição (substituir) | `A editar ficheiro (substituir)...` |
| Edição (excluir) | `A editar ficheiro (eliminar)...` |
| Merge | `A mesclar ...` |
| Merge concluído | `Mesclagem concluida em: %s milissegundos.` |
| Merge erro | `Erro de mesclagem: ` |
| Exportar linhas | `A exportar linhas...` |
| Exportar para arquivo | `A exportar linhas para ficheiro...` |
| Export → arquivo | `Exportacao concluida! Ficheiro guardado em: %s` |
| Export → clipboard | `Exportacao concluida! Linhas copiadas para a area de transferencia.` |
| Replace All | `Substituir tudo concluido. %d substituicao(oes). Tempo: %s ms.` |
| Split | `A dividir ficheiro...` |
| Split concluído | `Divisao concluida. %d ficheiro(s) criado(s) em %s.` |
| Split erro | `Erro ao dividir: ` |
| Erro genérico | `Erro: ` *(herdado de PT-BR via seed)* |
| Operação falhou | `Operação falhou ou foi cancelada.` *(herdado de PT-BR — acentuado)* |
| Tempo de leitura | `Tempo de leitura: %s milissegundos. Total de linhas: %d.` |
| Tempo de operação | `Tempo para executar essa operacao: %s milissegundos.` |

#### RO — Română *(diacríticos romenos ausentes — ASCII-safe no executável)*
| Cenário | String esperada |
|---|---|
| Leitura | `Se citeste fisierul...` |
| Edição (inserir) | `Editare fisier (inserare)...` |
| Edição (substituir) | `Editare fisier (inlocuire)...` |
| Edição (excluir) | `Editare fisier (stergere)...` |
| Merge | `Combinare ...` |
| Merge concluído | `Combinare finalizata in: %s milisecunde.` |
| Merge erro | `Eroare la combinare: ` |
| Exportar linhas | `Se exporta linii...` |
| Exportar para arquivo | `Se exporta linii in fisier...` |
| Export → arquivo | `Export finalizat! Fisier salvat in: %s` |
| Export → clipboard | `Export finalizat! Liniile au fost copiate in clipboard.` |
| Replace All | `Inlocuire tot finalizata. %d inlocuire(i). Timp: %s ms.` |
| Split | `Se imparte fisierul...` |
| Split concluído | `Impartire finalizata. %d fisier(e) creat(e) in %s.` |
| Split erro | `Eroare la impartire: ` |
| Erro genérico | `Error: ` *(fallback EN — não sobrescrito)* |
| Operação falhou | `Operation failed or cancelled.` *(fallback EN — não sobrescrito)* |
| Tempo de leitura | `Timp de citire: %s milisecunde. Linii totale: %d.` |
| Tempo de operação | `Timp pentru executarea acestei operatii: %s milisecunde.` |

#### HU — Magyar *(diacríticos húngaros ausentes — ASCII-safe no executável)*
| Cenário | String esperada |
|---|---|
| Leitura | `Fajl olvasasa...` |
| Edição (inserir) | `Fajl szerkesztese (beszuras)...` |
| Edição (substituir) | `Fajl szerkesztese (csere)...` |
| Edição (excluir) | `Fajl szerkesztese (torles)...` |
| Merge | `Osszefuzes ...` |
| Merge concluído | `Osszefuzes befejezve: %s ms.` |
| Merge erro | `Osszefuzesi hiba: ` |
| Exportar linhas | `Sorok exportalasa...` |
| Exportar para arquivo | `Sorok exportalasa fajlba...` |
| Export → arquivo | `Export kesz! A fajl ide lett mentve: %s` |
| Export → clipboard | `Export kesz! A sorok a vagolapra lettek masolva.` |
| Replace All | `Csere mind befejezve. %d csere. Ido: %s ms.` |
| Split | `Fajl felosztasa...` |
| Split concluído | `Felosztas befejezve. %d fajl keszult %s alatt.` |
| Split erro | `Felosztasi hiba: ` |
| Erro genérico | `Error: ` *(fallback EN — não sobrescrito)* |
| Operação falhou | `Operation failed or cancelled.` *(fallback EN — não sobrescrito)* |
| Tempo de leitura | `Beolvasasi ido: %s ms. Sorok osszesen: %d.` |
| Tempo de operação | `A muvelet vegrehajtasi ideje: %s ms.` |

#### CZ — Čeština *(diacríticos tchecos ausentes — ASCII-safe no executável)*
| Cenário | String esperada |
|---|---|
| Leitura | `Cteni souboru...` |
| Edição (inserir) | `Uprava souboru (vlozeni)...` |
| Edição (substituir) | `Uprava souboru (nahrazeni)...` |
| Edição (excluir) | `Uprava souboru (smazani)...` |
| Merge | `Slucovani ...` |
| Merge concluído | `Slouceni dokonceno za: %s ms.` |
| Merge erro | `Chyba slouceni: ` |
| Exportar linhas | `Export radku...` |
| Exportar para arquivo | `Export radku do souboru...` |
| Export → arquivo | `Export dokoncen! Soubor ulozen do: %s` |
| Export → clipboard | `Export dokoncen! Radky byly zkopirovany do schranky.` |
| Replace All | `Nahradit vse dokonceno. %d nahrad(a). Cas: %s ms.` |
| Split | `Rozdelovani souboru...` |
| Split concluído | `Rozdeleni dokonceno. Vytvoreno %d souboru za %s.` |
| Split erro | `Chyba rozdeleni: ` |
| Erro genérico | `Error: ` *(fallback EN — não sobrescrito)* |
| Operação falhou | `Operation failed or cancelled.` *(fallback EN — não sobrescrito)* |
| Tempo de leitura | `Doba cteni: %s ms. Celkem radku: %d.` |
| Tempo de operação | `Cas provedeni operace: %s ms.` |

---

### Tabela de aprovação por cenário × idioma

Marque **✓** (aprovado) ou **✗** (falhou/fallback indevido/caractere corrompido).

| Cenário | EN | PT-BR | ES | FR | DE | IT | PL | PT-PT | RO | HU | CZ |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Leitura de arquivo (overlay) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Tempo de leitura (`Time to read`) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Edição — inserir linha | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Edição — substituir linha | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Edição — excluir linha | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Tempo de operação (`Time to execute`) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Replace All (overlay + conclusão) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Exportar → arquivo | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Exportar → clipboard | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Merge (overlay + conclusão) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Split (overlay + conclusão) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Erro genérico (`Error: `) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Erro de merge (`Merge Error: `) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Erro de split (`Split Error: `) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Operação cancelada/falhou | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
