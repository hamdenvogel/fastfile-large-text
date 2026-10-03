# FastFile: Arquitetura de Big Data e Zero Scan (Guia Técnico)

Este documento detalha as soluções de engenharia implementadas no componente `FastFile` (ambiente Delphi 7 / 32-bits) para suportar a indexação, navegação e exibição de arquivos de texto de escala gigantesca (10 GB, 500 GB, 2 TB+), ultrapassando as limitações clássicas de memória e I/O do sistema operacional.

> **Guia do usuário (menus, exemplos 10 MB vs 50 GB, INI):** veja a seção **[Open mode and Zero Scan](README.md#open-mode-and-zero-scan)** no `README.md`.  
> **Portabilidade de busca, filtro e substituir com Zero Scan ON (roadmap técnico detalhado):** [DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md](DOC_ZERO_SCAN_OPERACOES_PORTABILIDADE.md).

### Decisão automática na abertura (resumo)

| Condição (prioridade decrescente) | Abertura no F5 |
|-----------------------------------|----------------|
| **Force Zero Scan** marcado (View) | Instantânea, sem `temp.txt` |
| Menu **Abrir: sempre instantâneo** | Instantânea |
| Menu **Abrir: sempre indexar** | `TReadFileThread` (salvo Force Zero Scan) |
| **Automático** e tamanho **≥ 15 GB** | Instantânea |
| **Automático** e tamanho **< 15 GB** | Indexação normal |

A contagem de linhas **não** define o modo na abertura automática; após indexar, arquivos com **> 500 000 linhas** podem ligar `FZeroScanMode` internamente, mas **busca/filtro** continuam a usar o índice se `temp.txt` / `temp_ckpt.txt` existir.

---

## 1. O Desafio dos 32-bits
A API nativa do Windows e os componentes VCL do Delphi (como o `TListView`) utilizam inteiros de 32-bits com sinal (`Int32`) para contar itens. O limite máximo seguro desse tipo de dado é **2.147.483.647**.
Se tentarmos atribuir mais linhas do que isso ao `ListView1.Items.Count`, a aplicação sofrerá um `Integer Overflow`, resultando em falhas de renderização da barra de rolagem e eventuais travamentos (Access Violation) do Windows.

Para suportar arquivos cujas linhas excedam esse número, o sistema precisou de uma remodelação dividida em três pilares: **Motor SWAR**, **Airbag de Memória** e **Navegação Zero Scan**.

---

## 2. Motor de Leitura SWAR (Performance Extrema)
Para arquivos gigantes, contar as quebras de linha de forma sequencial byte a byte é lento. O FastFile utiliza uma técnica inspirada em instruções de processador chamada **SWAR** (*SIMD Within A Register*).

### Como funciona:
* O arquivo é mapeado em memória (`TMMFReader`) e dividido em "blocos de trabalho" de até **128 MB**.
* Em vez de checar caractere por caractere (8-bits), a CPU lê **4 bytes de uma só vez** (`PCardinal`) e, através de operações matemáticas com máscaras de bit (Bitwise XOR e AND), detecta se algum daqueles 4 bytes é uma quebra de linha (`0x0A`).
* Isso multiplicou a taxa de transferência do loop de varredura.

### O Efeito "OS File Cache" (Testes de Mesa):
Durante os testes de stress em um arquivo de 10.2 GB, observamos uma variação de performance:
* **Cold Read (Leitura Fria): 23 segundos.** Ocorre quando o arquivo não está na memória RAM. A velocidade é limitada fisicamente pela taxa de leitura do SSD/HDD (I/O Bound).
* **Hot Read (Leitura Quente): 7 segundos.** Ocorre se o Windows já tiver colocado o arquivo em cache (Standby List). Com os discos fora do caminho, o algoritmo SWAR atingiu uma taxa de contagem superior a **1.4 GB/s**.

---

## 3. O "Airbag" de Memória (Válvula de Escape)
Arquivos que possuem bilhões de quebras de linha são letais para processos 32-bits. Para garantir a estabilidade em tempo real, implementamos a lógica do **Airbag** na `TReadFileThread`.

### O Gatilho de Desarme:
Dentro do loop quente (SWAR), temos o seguinte limitador:
```pascal
if totalLines >= 2000000000 then
begin
  FHitLineLimit := True;
  Break;
end;
```
Ao atingir cravadas 2 bilhões de linhas, a Thread de leitura se auto-interrompe (desarma). O painel de interface recebe essa informação e preenche o limite de 2.000.000.000 de forma cirúrgica. Dessa forma, o `ListView` nunca transborda o buffer do sistema e o usuário recebe um aviso em tela informando que a proteção foi ativada.

---

## 4. O Modo "Zero Scan" (Bypass e Leitura Instantânea)
Ler todo o arquivo para contar linhas é rápido, mas para arquivos de proporções cósmicas (ex: 2 Terabytes), mesmo a 1.4 GB/s isso demoraria cerca de 25 minutos. 
O **Zero Scan** é uma técnica que troca "precisão microscópica de indexação" por "velocidade absoluta".

### Bypass Total:
Se a opção **"Force Zero Scan Mode"** estiver ativada (via interface ou ativada automaticamente pelo gatilho do Airbag), o sistema anula a Thread de leitura. O tempo para abrir um arquivo de 2 TB passa a ser **0 Segundos**.

### Barra de rolagem sem índice (estimativa de linhas)

Na abertura instantânea **sem** `temp.txt`, o FastFile não sabe o número exato de linhas. Em vez de fixar **2 bilhões** de degraus (`FileSize / 2B` por “linha”, o que empurrava o scroll para “linha 20 milhões” em arquivos de 10 GB já no fim do arquivo):

1. Amostra os primeiros **4 MB** e conta `#10`.
2. Estima `totalLines ≈ FileSize / (bytes por linha na amostra)` (teto 2 bilhões).
3. Refina com os últimos **4 MB** (densidade de `#10` no fim) para não inflar a barra além do EOF real.
4. Define `FZeroScanBytesPerItem = FileSize / totalLines`.
5. A roda do mouse usa só a barra externa (`Offset` ±1), não `WM_VSCROLL` na ListView (evita saltos de milhões de linhas virtuais).

**Consequência:** o arquivo abre na hora e a barra / **Shift+End** aproximam o fim real do ficheiro. A navegação continua **por blocos proporcionais**, não linha-a-linha como com índice denso.

---

## 4.1 Modo segmentado (ops. pesadas) — `EffectiveUseSegmentedHeavyOps`

Não confundir com Zero Scan: o segmentado aplica-se só a **gravação pesada** (Substituir tudo, apagar linhas em lote).

| Entrada | Papel |
|---------|--------|
| `FForceSegmentHeavyOps` | Opções → “Forçar modo segmentado” (`SegmentHeavyOps` no INI) |
| `FSegmentHeavyOpsPolicy` | Auto / sempre / nunca (`SegmentHeavyOpsPolicy` no INI) |
| **`EffectiveUseSegmentedHeavyOps(AFileSize, ALineCount, ALinesAffected)`** | Devolve `True` se essa operação deve usar `TrySegmentedReplace` ou `TrySegmentedBatchDelete` |

**Auto (recomendado):** `True` se ficheiro >100 MB **ou** `totalLines` >500 000 **ou** ≥200 linhas na operação.

Detalhe completo: **`DOC_SEGMENTED_HEAVY_OPS.md`** (documento principal), **`ROADMAP_COMERCIAL_FASTFILE.md`** (apêndice), **`ARQUITETURA_TECNICA_FASTFILE.md`** § 4.1.1.

---

## 5. Arquitetura da Flag de UI (Skinning Engine)
No Delphi 7, os componentes visuais de Menu reconstruídos dinamicamente (para suportar traduções ou motores de skins como o *AlphaControls*) sofrem interceptação do pipeline de desenho (paint bypass). 

Para garantir que a opção "Force Zero Scan Mode" (no menu *Visualizar*) funcionasse perfeitamente e mantesse a aparência booleana (`check ✓`), desenvolvemos o padrão **Blindagem por Backing Field**:
1. Removemos a propriedade nativa `AutoCheck` e a associação de Ícones (`ImageIndex`).
2. Acessamos um booleano de memória 100% privado no escopo da tela (`FForceZeroScan: Boolean`).
3. Quando o menu é montado (ou sofre re-paint), ele consulta essa variável primária para saber se desenha o `✓` ou não. Isso isolou totalmente a lógica binária dos efeitos colaterais visuais gerados pela biblioteca de skins de terceiros.
