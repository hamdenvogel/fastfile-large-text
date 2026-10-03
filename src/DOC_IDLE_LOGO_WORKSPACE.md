# FastFile — Logo idle no workspace central

**Documento de arquitetura e operação**  
Versão do produto de referência: `3.0.1.0`  
Ambiente: Delphi 7 / Win32 ou Win64, AlphaControls (AlphaSkins)  
Unidade principal: `MainUnit.pas` (aprox. linhas 35198–35895)

> **Documentos relacionados**  
> - [ARQUITETURA_TECNICA_FASTFILE.md](ARQUITETURA_TECNICA_FASTFILE.md) — visão geral do produto  
> - [README.md](README.md) — visão geral do repositório

---

## Índice

1. [Objetivo](#1-objetivo)
2. [Comportamento visível para o utilizador](#2-comportamento-visível-para-o-utilizador)
3. [Histórico de abordagens (o que não funcionou)](#3-histórico-de-abordagens-o-que-não-funcionou)
4. [Solução final — visão geral](#4-solução-final--visão-geral)
5. [Arquitetura em duas camadas](#5-arquitetura-em-duas-camadas)
6. [Carregamento e pós-processamento do bitmap](#6-carregamento-e-pós-processamento-do-bitmap)
7. [Renderização com TsFloatButtons](#7-renderização-com-tsfloatbuttons)
8. [Posicionamento e dimensionamento](#8-posicionamento-e-dimensionamento)
9. [Automatização e performance](#9-automatização-e-performance)
10. [Constantes configuráveis](#10-constantes-configuráveis)
11. [Mapa de símbolos no código](#11-mapa-de-símbolos-no-código)
12. [Pontos de integração (quem chama o quê)](#12-pontos-de-integração-quem-chama-o-quê)
13. [Ficheiros e recursos](#13-ficheiros-e-recursos)
14. [Ajustes futuros](#14-ajustes-futuros)
15. [Perguntas frequentes](#15-perguntas-frequentes)

---

## 1. Objetivo

Quando o **workspace central do FastFile está vazio** — ou seja, nenhuma aba de ficheiro está visível — o sistema exibe a **logo do produto** como *watermark*:

- Centralizada na área útil do workspace (entre toolbar e status bar)
- **Suave / semitransparente** (não deve competir com o conteúdo)
- **Sem retângulo visível** ao redor (sem “quadrado” de fundo)
- **Sem lentidão** ao abrir ou fechar abas

Esta funcionalidade é independente do watermark de demonstração `sFloatSample` (canto inferior direito, configurável no DFM). Quando a logo idle está ativa, `sFloatSample` é automaticamente ocultada para evitar sobreposição.

---

## 2. Comportamento visível para o utilizador

A logo aparece quando **todas** as condições abaixo são verdadeiras:

| Condição | Descrição |
|----------|-----------|
| Workspace vazio | `pgMain` não tem nenhuma página com `TabVisible = True` |
| Bitmap carregado | `logo.bmp` (ou PNG alternativo) foi encontrado e processado com sucesso |

A logo **desaparece** assim que qualquer aba fica visível (`ShowTab`, abertura de ficheiro, etc.).

Ao redimensionar a janela, a logo **recentraliza** e **redimensiona** proporcionalmente, mantendo-se dentro dos limites definidos pelas constantes.

---

## 3. Histórico de abordagens (o que não funcionou)

Durante o desenvolvimento foram testadas várias técnicas. Este histórico explica **por que** a solução atual usa `TsFloatButtons`.

| Abordagem | Problema encontrado |
|-----------|---------------------|
| `TsPanel` + `TPaintBox` | Quadrado cinza/azulado visível por causa do skin AlphaControls |
| `GetDC` + `AlphaBlend` direto no form | Incompatível com AlphaSkins; logo sumia ou não compunha corretamente |
| `TsImage` (`acImage`, `Transparent`) | Logo aparecia, mas quadrado de fundo persistia |
| Remoção de fundo por cor dos cantos do BMP | Melhorou parcialmente; halo retangular ainda visível |
| `TPaintBox` + `TIdleLogoPaintBox` (bloqueia `WM_ERASEBKGND`) | Logo visível, mas janela filha ainda formava retângulo claro |
| `FeatherIdleLogoAlpha` | Espalhava alpha para pixels de fundo, criando “névoa” retangular |
| `ReloadIdleLogoBitmap` em cada `UpdateIdleLogoVisibility` | **Lentidão** ao fechar abas — corrigido removendo o reload |

**Solução adotada:** `TsFloatButtons` com `fbsTransparent` e `OnPaint` customizado — o mesmo mecanismo nativo do AlphaControls usado pelo componente `sFloatSample` no DFM.

---

## 4. Solução final — visão geral

```
┌─────────────────────────────────────────────────────────────┐
│  TfrmMain (form com AlphaSkins)                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Toolbar / menus / ribbon                             │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  pgMain (área de abas — vazia quando idle)            │  │
│  │                                                       │  │
│  │         ┌─────────────────────┐                       │  │
│  │         │  FIdleLogoFloat     │  ← overlay layered  │  │
│  │         │  (TsFloatButtons)   │    WS_EX_LAYERED      │  │
│  │         │  desenha bitmap     │    sem fundo sólido   │  │
│  │         └─────────────────────┘                       │  │
│  │                                                       │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  Status bar                                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

FIdleLogoBitmap (TBitmap pf32bit) ──► usado em IdleLogoFloatPaint
     ▲
     └── carregado 1x por LoadIdleLogoBitmap + pós-processamento
```

Fluxo resumido:

1. **Detectar** se o workspace está idle (`MainWorkspaceShowsIdleLogo`)
2. **Garantir** bitmap em memória (`EnsureIdleLogoLoaded`) — só na primeira vez
3. **Garantir** overlay criado (`EnsureIdleLogoFloat`) — só na primeira vez
4. **Sincronizar** tamanho e posição (`SyncIdleLogoFloatBounds`)
5. **Mostrar** ou esconder o float button (`Visible`)
6. **Desenhar** via `IdleLogoFloatPaint` quando o AlphaControls pede repaint

---

## 5. Arquitetura em duas camadas

### Camada 1 — Bitmap preparado (`FIdleLogoBitmap`)

- Tipo: `TBitmap` com `PixelFormat := pf32bit` (cada pixel tem R, G, B e alpha em `rgbReserved`)
- Vive durante toda a sessão do form (libertado em `FormDestroy`)
- Contém a imagem **já processada**: fundo transparente, alpha suave, recorte ao conteúdo

### Camada 2 — Overlay na tela (`FIdleLogoFloat`)

- Tipo: `TsFloatButtons` (unit `acFloatCtrls`)
- Criado em runtime, não está no DFM
- Um único item (`Items[0]`) com:
  - `Style := fbsTransparent`
  - `AllowClick := False`
  - `ShowCaption := False`
  - `AllowMouseTransparency := True` (cliques passam através)
  - `OnPaint := IdleLogoFloatPaint`

O AlphaControls cria uma **janela flutuante em camada** sobre o form. O bitmap é desenhado nessa camada com alpha real, composto sobre o skin — **sem** controlo filho opaco no meio do `pgMain`.

---

## 6. Carregamento e pós-processamento do bitmap

### 6.1 Ordem de procura de ficheiros

`LoadIdleLogoBitmap` tenta, por ordem:

1. `{ExeDir}\logo.bmp`
2. `{ExeDir}\Build\logo.bmp`
3. Variantes com `ParamStr(0)`
4. `{ExeDir}\..\logo.bmp`
5. `{ExeDir}\color1_icon_transparent_background.png` (e variantes Build/..)
6. Fallback: extrair recurso `LOGO` via `UnUtils.extractResource('LOGO', Path)` → `logo.bmp`

Constante do recurso: `LOGO = 'logo.bmp'` em `UnConsts.pas`, embutido em `folders.rc`.

### 6.2 Dois caminhos de pós-processamento

#### Caminho A — PNG com alpha real

Se `IdleLogoBitmapHasRealAlpha` detectar variação significativa no canal alpha (pixels totalmente transparentes e opacos):

- Chama `ApplyIdleLogoPngFade`
- Multiplica cada alpha existente por `IDLE_LOGO_ALPHA / 255`
- **Não** aplica flood fill nem remoção agressiva de fundo
- Faz `CropIdleLogoToContent` para remover margens vazias

#### Caminho B — BMP (ou PNG sem alpha útil)

Chama `ApplyIdleLogoPostProcess`, que executa em sequência:

| Etapa | Função | Função |
|-------|--------|--------|
| 1 | `DetectIdleLogoBorderBackground` | Amostra pixels das bordas para estimar cor de fundo |
| 2 | `FloodClearIdleLogoBackground` | Flood fill a partir das bordas, limpando fundo |
| 3 | `EraseIdleLogoStrictBackground` | Remove pixels classificados como fundo |
| 4 | Loop principal | Pixels de fundo → alpha 0; pixels fracos (`ContentWeight < 28`) → limpos; restantes → `IDLE_LOGO_ALPHA` |
| 5 | `CullIdleLogoFaintAlpha` | Remove pixels com alpha < 40 |
| 6 | `TrimIdleLogoFaintEdges` | Remove linhas/colunas quase transparentes nas bordas |
| 7 | `CropIdleLogoToContent` | Recorta ao bounding box do conteúdo |
| 8 | `EraseIdleLogoStrictBackground` | Segunda passagem de limpeza |
| 9 | `FinalizeIdleLogoBitmap` | Zera pixels com alpha residual < 40 |

**Nota:** `FeatherIdleLogoAlpha` foi **removido** da pipeline final porque espalhava alpha para pixels de fundo, criando o halo retangular visível no print.

### 6.3 Critérios de classificação de pixels

- `IdleLogoIsFlatBrightPixel` — pixels claros e pouco saturados (brancos/cinzas chapados)
- `IdleLogoIsBackgroundPixel` — distância de cor ao fundo detectado nas bordas
- `IdleLogoContentWeight` — saturação + contraste de luminosidade vs. fundo; pixels abaixo do limiar são descartados

---

## 7. Renderização com TsFloatButtons

### 7.1 Criação (uma vez)

```pascal
procedure TfrmMain.EnsureIdleLogoFloat;
```

- Se `FIdleLogoFloat` já existe → retorna imediatamente
- Cria `TsFloatButtons` com `AllowMouseTransparency := True`
- Adiciona um `TacFloatBtn` com `Style := fbsTransparent` e `OnPaint := IdleLogoFloatPaint`
- Chama `EnsureIdleLogoLoaded` e `SyncIdleLogoFloatBounds`

### 7.2 Desenho

```pascal
procedure TfrmMain.IdleLogoFloatPaint(Sender: TObject; PaintData: TacCustomPaintData);
```

O AlphaControls chama este evento ao compor o overlay. O código:

1. Obtém `PaintData.DestBmp` (bitmap de destino do tamanho do float button)
2. Chama `StretchBmpRect32` (`sGraphUtils`) para esticar `FIdleLogoBitmap` ao tamanho do botão
3. O AlphaControls aplica `BlendValue` e compõe sobre o form com `WS_EX_LAYERED`

### 7.3 Texto da marca (watermark)

Abaixo da logo, no mesmo overlay `TsFloatButtons`, são desenhados:

| Linha | Texto | Fonte | Cor / opacidade |
|-------|-------|-------|-----------------|
| Título | `APPLICATION_FULLNAME` (`UnConsts`) | Segoe UI Semibold (fallback: **Tahoma** bold) | Teal escuro `$00785F19` · alpha ~82% |
| Subtítulo | `APPLICATION_DEVELOPER` (`UnConsts`) | Segoe UI (fallback: **Tahoma**) | Cinza-teal `$0069552D` · alpha ~66% |

O bloco inteiro (logo + textos) é centralizado no workspace; **logo e textos alinhados à esquerda** dentro do bloco. `APPLICATION_DEVELOPER` pode ter várias linhas (`#13#10`). Tamanhos de fonte escalam com a largura da logo. Constantes visuais: `IDLE_LOGO_TITLE_COLOR`, `IDLE_LOGO_TAGLINE_COLOR`.

### 7.4 Por que não TPaintBox?

`TPaintBox` é um controlo VCL filho com HWND próprio. Mesmo com `WM_ERASEBKGND` bloqueado e `csOpaque` removido, sobre skins AlphaControls o retângulo da janela filha continuava perceptível.

`TsFloatButtons` usa o pipeline de composição alpha **nativo** do AlphaControls — a mesma técnica do watermark `sFloatSample` definido no `MainUnit.dfm`.

---

## 8. Posicionamento e dimensionamento

### 8.1 Área útil do workspace

`GetIdleLogoWorkspaceRect` devolve o retângulo onde a logo pode ser desenhada:

- Se `pgMain` está visível e tem tamanho razoável → usa `pgMain.BoundsRect` em coordenadas do form
- Caso contrário → `ClientRect` ajustado abaixo de `sPageControl1` / `sPanel3` e acima de `sStatusBar1` / `sPanel5`

### 8.2 Tamanho da logo

`SyncIdleLogoFloatBounds` calcula:

```
MaxDim = Min(AreaW, AreaH) * IDLE_LOGO_SIZE_FRAC   // default 72%
MaxDim = Min(MaxDim, IDLE_LOGO_MAX_PX)              // teto 680 px
MaxDim = Max(MaxDim, 80)                            // piso 80 px

Scale  = MaxDim / Max(BitmapWidth, BitmapHeight)
DestW  = Round(BitmapWidth  * Scale)
DestH  = Round(BitmapHeight * Scale)
```

### 8.3 Centralização

- Horizontal: `AlignHorz := taCenter`, `OffsetX := 0`
- Vertical: `AlignVert := vaAlignTop` com `OffsetY` calculado em **coordenadas de ecrã**:

```pascal
Pt := ClientToScreen(Point(
  R.Left + (AreaW - DestW) div 2,
  R.Top  + (AreaH - DestH) div 2));
Btn.OffsetY := Pt.Y - FormR.Top;
```

Isto centra a logo na área do workspace, não no form inteiro (que incluiria a toolbar).

---

## 9. Automatização e performance

### 9.1 Princípio: criar uma vez, reutilizar sempre

| Recurso | Criado quando | Recriado ao fechar aba? |
|---------|---------------|-------------------------|
| `FIdleLogoBitmap` | Primeira necessidade (`EnsureIdleLogoLoaded`) | **Não** |
| `FIdleLogoFloat` | Primeira necessidade (`EnsureIdleLogoFloat`) | **Não** |
| Posição / tamanho | `SyncIdleLogoFloatBounds` | Recalculado (leve) |
| Visibilidade | `UpdateIdleLogoVisibility` | Apenas `Visible := True/False` |

### 9.2 Padrão Ensure (lazy initialization)

```pascal
procedure TfrmMain.EnsureIdleLogoLoaded;
begin
  if not Assigned(FIdleLogoBitmap) then
    LoadIdleLogoBitmap
  else if not IdleLogoBitmapReady then
    LoadIdleLogoBitmap;
end;

procedure TfrmMain.EnsureIdleLogoFloat;
begin
  if Assigned(FIdleLogoFloat) then Exit;
  // ... criação única ...
end;
```

`LoadIdleLogoBitmap` **não** é chamado em cada fecho de aba — apenas quando o bitmap ainda não existe ou está vazio.

### 9.3 Orquestração central

`UpdateIdleLogoVisibility` é o **único ponto de decisão** para mostrar ou esconder:

```pascal
ShowLogo := MainWorkspaceShowsIdleLogo;
if ShowLogo then
  EnsureIdleLogoLoaded;
if ShowLogo and IdleLogoBitmapReady then
begin
  EnsureIdleLogoFloat;
  SyncIdleLogoFloatBounds;
  FIdleLogoFloat.Items[0].Visible := True;
  FIdleLogoFloat.Items[0].UpdatePosition;
  FIdleLogoFloat.Items[0].Repaint;
end
else if Assigned(FIdleLogoFloat) then
  FIdleLogoFloat.Items[0].Visible := False;
```

**O que é leve** (aceitável em cada evento): recalcular bounds, `UpdatePosition`, `Repaint` do overlay.

**O que é pesado** (evitado após a primeira carga): ler ficheiro do disco, flood fill, crop, criar componentes.

### 9.4 Libertação de recursos

Em `FormDestroy` (ou equivalente de encerramento do form):

```pascal
FreeAndNil(FIdleLogoFloat);
FreeAndNil(FIdleLogoBitmap);
```

---

## 10. Constantes configuráveis

Definidas em `MainUnit.pas` (secção implementation, ~linha 35198):

| Constante | Valor atual | Significado |
|-----------|-------------|-------------|
| `IDLE_LOGO_PNG` | `'color1_icon_transparent_background.png'` | Nome do PNG alternativo |
| `IDLE_LOGO_ALPHA` | `82` | Opacidade base (~31%); anéis externos usam 58–86% deste valor |
| `IDLE_LOGO_MAX_PX` | `680` | Largura/altura máxima em pixels |
| `IDLE_LOGO_SIZE_FRAC` | `0.66` | Tamanho um pouco menor — menos dominante no workspace |

### Ajustes comuns

- **Watermark mais discreto:** diminuir `IDLE_LOGO_ALPHA` (ex.: 72) ou `IDLE_LOGO_SIZE_FRAC` (ex.: 0.62)
- **Um pouco mais visível:** aumentar `IDLE_LOGO_ALPHA` (ex.: 92) — evitar passar de ~100 para não forçar a vista
- **Menos esbranquiçado:** `IdleLogoSetWatermarkPixel` usa teal contido e alpha menor nos anéis claros (tiers 2–3)
- **Logo maior:** aumentar `IDLE_LOGO_SIZE_FRAC` ou `IDLE_LOGO_MAX_PX`
- **Logo menor:** diminuir `IDLE_LOGO_SIZE_FRAC`

No float button, `BlendValue := 255` — a suavidade é controlada pelo alpha do bitmap, não pelo blend do overlay.

---

## 11. Mapa de símbolos no código

### Campos privados (`TfrmMain`)

| Símbolo | Tipo | Descrição |
|---------|------|-----------|
| `FIdleLogoBitmap` | `TBitmap` | Imagem processada em memória |
| `FIdleLogoFloat` | `TsFloatButtons` | Overlay de renderização |

### Métodos principais

| Método | Responsabilidade |
|--------|------------------|
| `MainWorkspaceShowsIdleLogo` | True se nenhuma aba visível |
| `GetIdleLogoWorkspaceRect` | Retângulo da área útil |
| `LoadIdleLogoBitmap` | Carrega ficheiro + pós-processa |
| `EnsureIdleLogoLoaded` | Lazy load do bitmap |
| `EnsureIdleLogoFloat` | Lazy create do overlay |
| `SyncIdleLogoFloatBounds` | Tamanho e posição do float button |
| `IdleLogoFloatPaint` | Desenho no overlay |
| `UpdateIdleLogoVisibility` | Orquestra show/hide |
| `ApplyIdleLogoPostProcess` | Pipeline BMP |
| `ApplyIdleLogoPngFade` | Pipeline PNG com alpha |
| `IdleLogoBitmapReady` | Valida bitmap utilizável |

### Funções auxiliares (implementation)

`IdleLogoBitmapHasRealAlpha`, `DetectIdleLogoBorderBackground`, `IdleLogoIsBackgroundPixel`, `IdleLogoContentWeight`, `FloodClearIdleLogoBackground`, `EraseIdleLogoStrictBackground`, `CullIdleLogoFaintAlpha`, `FinalizeIdleLogoBitmap`, `IdleLogoClearPixel`, etc.

---

## 12. Pontos de integração (quem chama o quê)

| Evento / procedimento | Chamada | Motivo |
|----------------------|---------|--------|
| `FormCreate` | `EnsureIdleLogoLoaded` + `UpdateIdleLogoVisibility` | Preparar logo no arranque (abas inicialmente ocultas) |
| `FormShow` | `UpdateIdleLogoVisibility` | Sincronizar após layout inicial |
| `FormResize` | `SyncIdleLogoFloatBounds` + `Repaint` | Recentrar ao redimensionar |
| `ShowTab` | `UpdateIdleLogoVisibility` | Esconder ao abrir aba |
| `HideTabs` | `UpdateIdleLogoVisibility` | Mostrar ao esconder abas |
| Fechar aba recente | `UpdateIdleLogoVisibility` | Mostrar quando última aba fecha |
| `FormDestroy` | `FreeAndNil` bitmap e float | Libertar recursos |

---

## 13. Ficheiros e recursos

| Ficheiro | Papel |
|----------|-------|
| `MainUnit.pas` | Toda a lógica da logo idle |
| `MainUnit.dfm` | `sFloatSample` — referência de watermark (não é a logo idle) |
| `UnConsts.pas` | `LOGO = 'logo.bmp'` |
| `folders.rc` | Recurso `LOGO` embutido no executável |
| `logo.bmp` | Asset principal (exe dir ou Build) |
| `color1_icon_transparent_background.png` | PNG opcional com alpha real |
| `acFloatCtrls.pas` | `TsFloatButtons`, `TacFloatBtn`, `fbsTransparent` |
| `sGraphUtils.pas` | `StretchBmpRect32` |

---

## 14. Ajustes futuros

Possíveis melhorias sem alterar a arquitetura:

1. **Tema escuro/claro** — ajustar `IDLE_LOGO_ALPHA` conforme skin activo
2. **Preferência do utilizador** — opção em INI para intensidade ou “não mostrar logo”
3. **PNG prioritário** — colocar `color1_icon_transparent_background.png` em `Build\` para evitar processamento BMP
4. **Animação suave** — `BlendValue` animado no float button (AlphaControls suporta transições)

---

## 15. Perguntas frequentes

### A logo é recriada cada vez que fecho uma aba?

**Não.** Só se altera `Visible`, posição e repaint do overlay. O bitmap e o `TsFloatButtons` persistem em memória.

### Por que aparecia um quadrado antes?

Combinação de: (1) `TPaintBox` como HWND filho opaco sobre o skin; (2) `FeatherIdleLogoAlpha` espalhando alpha para pixels de fundo, formando névoa retangular.

### A logo bloqueia cliques?

**Não.** `AllowClick := False` e `AllowMouseTransparency := True` no `TsFloatButtons`.

### O que acontece se `logo.bmp` não existir?

`IdleLogoBitmapReady` fica `False` e a logo não é exibida. O sistema tenta recurso embutido e paths alternativos antes de desistir.

### Posso usar só PNG?

Sim. Coloque `color1_icon_transparent_background.png` na pasta do executável ou em `Build\`. Se tiver alpha real, usa o caminho `ApplyIdleLogoPngFade` (mais limpo que processar BMP).

### Compilação

Usar `compile_verify.bat` na pasta `Src`. Se falhar com *Could not create output file*, fechar o `FastFile.exe` em execução antes de recompilar.

---

*Documento gerado com base na implementação validada em Maio/2026. Código de referência: `MainUnit.pas`, linhas ~35198–35895.*
