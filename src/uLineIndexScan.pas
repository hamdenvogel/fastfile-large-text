unit uLineIndexScan;

{
  Varredura de quebras de linha para TReadFileThread (indice de linhas).

  - ScanBufferForLineFeeds: varredura SWAR de um buffer, com callback por quebra
    de linha (caminho sequencial; Win32, ficheiros pequenos).
  - TryParallelLineIndexScan (Win64): pipeline por blocos de LINE_INDEX_CHUNK_BYTES.
    Workers leem blocos em ordem e geram um mapa de bits (1 bit por byte) das
    quebras de linha com SSE2; a thread chamadora junta os blocos em ordem e grava
    os indices. Memoria limitada a (2 x workers) blocos de mapa, independentemente
    do tamanho do ficheiro ou do numero de linhas.
  - Leitura directa (ficheiros grandes face a RAM): em vez de MMF por worker, um
    unico leitor sequencial com ReadFile + FILE_FLAG_NO_BUFFERING + OVERLAPPED
    mantem LINE_INDEX_DIRECT_QUEUE_DEPTH blocos em voo enquanto o bloco anterior
    e processado. Evita page-faults, MapViewOfFile por bloco e a poluicao do cache
    do sistema. Qualquer falha (flag nao suportada, leitura curta) cai no MMF.
  Explicacao completa: DOC_TREADFILETHREAD_EXECUTE.md.
}

interface

uses
  Classes, SysUtils, uMMF, UnBufferedTextWriter, uZeroScanBlockIndex, UnConsts;

const
  LINE_INDEX_PARALLEL_ENABLED = True;
  { Abaixo disto o caminho sequencial e mais rapido que arrancar threads. }
  LINE_INDEX_PARALLEL_MIN_BYTES = Int64(128) * 1024 * 1024;
  LINE_INDEX_MAX_WORKERS = 8;
  { Bloco de trabalho do pipeline paralelo (multiplo de 64 e da granularidade MMF).
    Mapa de bits por bloco = LINE_INDEX_CHUNK_BYTES / 8. }
  LINE_INDEX_CHUNK_BYTES = 32 * 1024 * 1024;

  { Leitura directa (ReadFile + FILE_FLAG_NO_BUFFERING). Usada quando o ficheiro
    e grande face a RAM fisica (>= RAM / LINE_INDEX_DIRECT_RAM_DIVISOR): abaixo
    disso o cache do sistema compensa (reabertura a quente) e o MMF e mantido. }
  LINE_INDEX_DIRECT_READ_ENABLED = True;
  LINE_INDEX_DIRECT_RAM_DIVISOR = 4;
  { Leituras em voo enquanto o bloco anterior e processado (buffers = depth + 1). }
  LINE_INDEX_DIRECT_QUEUE_DEPTH = 2;
  LINE_INDEX_DIRECT_QUEUE_DEPTH_MAX = 8;
  { Alinhamento dos pedidos sem cache: cobre qualquer tamanho de sector. }
  LINE_INDEX_DIRECT_ALIGN = 64 * 1024;

type
  TLineIndexDirectReadMode = (ldAuto, ldOff, ldOn);

var
  { Teste/bench: ldOn forca e ldOff desliga a leitura directa; ldAuto decide pelo
    tamanho do ficheiro face a RAM. }
  GLineIndexDirectReadMode: TLineIndexDirectReadMode = ldAuto;
  GLineIndexDirectQueueDepth: Integer = LINE_INDEX_DIRECT_QUEUE_DEPTH;

type
  TLineFeedFoundProc = reference to procedure(const ALfPos0: Int64);

  TLineIndexWriterBundle = record
    IdxW: TBufferedTextWriter;
    CkptW: TBufferedTextWriter;
    BlkW: TZeroScanBlockIndexWriter;
    SparseCkptOnly: Boolean;
  end;

  TIndexScanProgressEvent = reference to procedure(const Scanned: Int64);
  TIndexScanShouldStopEvent = reference to function: Boolean;

  { Gera os registos de indice (checkpoint e, se AWriters.IdxW, denso) a partir de
    bytes entregues em ordem crescente de offset, sem reler o ficheiro. Usado pela
    edicao rapida (uFastLineEdit) sobre o conteudo novo e o sufixo copiado.
    ALinesBefore = terminadores antes do primeiro byte entregue. BlkW e ignorado. }
  TLineIndexStreamBuilder = class
  private
    FWriters: TLineIndexWriterBundle;
    FTermByte: Byte;
    FLineCount: Int64;
    FBits: TArray<UInt64>;
  public
    constructor Create(const AWriters: TLineIndexWriterBundle;
      const ALinesBefore: Int64; const ATermByte: Byte);
    procedure Feed(AData: PByte; ALen: NativeInt; AOutOffset0: Int64);
    { Terminadores vistos ate agora (incluindo ALinesBefore). }
    property LineCount: Int64 read FLineCount;
  end;

function LineIndexScanHasAvx2: Boolean;
function LineIndexScanWorkerCount: Integer;
{ Tamanho a partir do qual a leitura directa e usada (RAM fisica / divisor). }
function LineIndexDirectReadThresholdBytes: Int64;
function LineIndexShouldUseDirectRead(const AFileSize: Int64): Boolean;

{ ATermByte: byte terminador de linha (10 = LF; 13 = CR em ficheiros Mac classico). }
procedure ScanBufferForLineFeeds(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc;
  const ATermByte: Byte = 10);

{ Varre o ficheiro inteiro e grava os indices em AWriters (denso, checkpoint e/ou
  blocos), acumulando ALineCount. Devolve False sem escrever nada quando o pipeline
  nao se aplica (Win32, ficheiro pequeno); o chamador usa entao o caminho sequencial.
  Devolve True quando correu (tambem apos cancelamento). A contagem segue ate
  o fim do ficheiro.
  Erros de leitura levantam excepcao (os indices ficam incompletos). }
function TryParallelLineIndexScan(const AFileName: string; const AFileSize: Int64;
  var ALineCount: Int64;
  const AWriters: TLineIndexWriterBundle;
  const AShouldStop: TIndexScanShouldStopEvent; const AOnProgress: TIndexScanProgressEvent;
  out AWorkerCount: Integer; const ATermByte: Byte = 10): Boolean;

implementation

{ Aritmetica de bits (SWAR, popcount, de Bruijn) depende de overflow sem verificacao. }
{$Q-}
{$R-}

uses
  Windows, SyncObjs, Math, uFastFilePaths, UnUtils, ThreadFileLog;

const
  PF_AVX2_INSTRUCTIONS_AVAILABLE = 40;
  IOCTL_STORAGE_QUERY_PROPERTY = $002D1400;
  StorageDeviceSeekPenaltyProperty = 7;
  PropertyStandardQuery = 0;
  LINE_INDEX_CHUNK_WORDS = LINE_INDEX_CHUNK_BYTES div 64;

type
  TStoragePropertyQuery = packed record
    PropertyId: DWORD;
    QueryType: DWORD;
    AdditionalParameters: array[0..0] of Byte;
  end;
  TDeviceSeekPenaltyDescriptor = packed record
    Version: DWORD;
    Size: DWORD;
    IncursSeekPenalty: ByteBool;
  end;

var
  GAvx2Cached: Integer = -1;

function LineIndexScanHasAvx2: Boolean;
begin
  if GAvx2Cached >= 0 then
    Exit(GAvx2Cached = 1);
  {$IFDEF WIN64}
  Result := IsProcessorFeaturePresent(PF_AVX2_INSTRUCTIONS_AVAILABLE);
  {$ELSE}
  Result := False;
  {$ENDIF}
  if Result then
    GAvx2Cached := 1
  else
    GAvx2Cached := 0;
end;

function LineIndexScanWorkerCount: Integer;
var
  SysInfo: SYSTEM_INFO;
begin
  GetSystemInfo(SysInfo);
  Result := SysInfo.dwNumberOfProcessors;
  if Result < 2 then
    Result := 2;
  if Result > LINE_INDEX_MAX_WORKERS then
    Result := LINE_INDEX_MAX_WORKERS;
end;

function LineIndexDirectReadThresholdBytes: Int64;
var
  MS: TMemoryStatusEx;
begin
  FillChar(MS, SizeOf(MS), 0);
  MS.dwLength := SizeOf(MS);
  if GlobalMemoryStatusEx(MS) and (MS.ullTotalPhys > 0) then
    Result := Int64(MS.ullTotalPhys) div LINE_INDEX_DIRECT_RAM_DIVISOR
  else
    Result := Int64(2) * 1024 * 1024 * 1024;
  if Result < LINE_INDEX_PARALLEL_MIN_BYTES then
    Result := LINE_INDEX_PARALLEL_MIN_BYTES;
end;

function LineIndexShouldUseDirectRead(const AFileSize: Int64): Boolean;
begin
  {$IFDEF WIN64}
  case GLineIndexDirectReadMode of
    ldOff: Result := False;
    ldOn: Result := LINE_INDEX_DIRECT_READ_ENABLED;
  else
    Result := LINE_INDEX_DIRECT_READ_ENABLED and
      (AFileSize >= LineIndexDirectReadThresholdBytes);
  end;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

{ ============================================================================ }
{ Caminho sequencial: SWAR com callback por quebra de linha                     }
{ ============================================================================ }

{ SWAR de 4 bytes. A mascara M pode marcar falsamente um $0B logo acima de um $0A
  (emprestimo da subtraccao), por isso cada bit e confirmado no byte. So corre
  quando M <> 0, ou seja, quando ha pelo menos um LF na palavra. }
procedure ScanSwarCardinalAt(const ABase: PByte; const RegionBase, ByteIdx: Integer;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc);
var
  W, M: Cardinal;
  Q: PByte;
begin
  Q := @PByteArray(ABase)[RegionBase + ByteIdx];
  W := PCardinal(Q)^;
  M := ((W xor $0A0A0A0A) - $01010101) and not (W xor $0A0A0A0A) and $80808080;
  if M = 0 then Exit;
  if ((M and $00000080) <> 0) and (Q[0] = 10) then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx));
  if ((M and $00008000) <> 0) and (Q[1] = 10) then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx + 1));
  if ((M and $00800000) <> 0) and (Q[2] = 10) then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx + 2));
  if ((M and $80000000) <> 0) and (Q[3] = 10) then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx + 3));
end;

procedure ScanBufferSwar(const ABase: PByte; const RegionBase, Count: Integer;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc);
var
  ci: Integer;
begin
  ci := 0;
  while ci <= Count - 8 do
  begin
    ScanSwarCardinalAt(ABase, RegionBase, ci, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 4, ABaseOffset0, AOnLineFeed);
    Inc(ci, 8);
  end;
  while ci <= Count - 4 do
  begin
    ScanSwarCardinalAt(ABase, RegionBase, ci, ABaseOffset0, AOnLineFeed);
    Inc(ci, 4);
  end;
  while ci < Count do
  begin
    if PByteArray(ABase)[RegionBase + ci] = 10 then
      AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ci));
    Inc(ci);
  end;
end;

{ SWAR desenrolado em blocos de 32 bytes (8 palavras de 4 bytes). }
procedure ScanBufferWide(const ABase: PByte; const RegionBase, Count: Integer;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc);
var
  ci: Integer;
begin
  ci := 0;
  while ci <= Count - 32 do
  begin
    ScanSwarCardinalAt(ABase, RegionBase, ci, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 4, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 8, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 12, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 16, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 20, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 24, ABaseOffset0, AOnLineFeed);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 28, ABaseOffset0, AOnLineFeed);
    Inc(ci, 32);
  end;
  if ci < Count then
    ScanBufferSwar(ABase, RegionBase + ci, Count - ci, ABaseOffset0, AOnLineFeed);
end;

{ Terminador diferente de LF (CR): SWAR com padrao variavel + confirmacao por byte. }
procedure ScanBufferForTermByte(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; const ATerm: Byte; const AOnLineFeed: TLineFeedFoundProc);
var
  ci: NativeInt;
  k: Integer;
  Pat, W: Cardinal;
  Q: PByte;
begin
  Pat := Cardinal(ATerm) * $01010101;
  Q := ABase;
  ci := 0;
  while ci <= ACount - 4 do
  begin
    W := PCardinal(Q + ci)^ xor Pat;
    if ((W - $01010101) and not W and $80808080) <> 0 then
      for k := 0 to 3 do
        if Q[ci + k] = ATerm then
          AOnLineFeed(ABaseOffset0 + Int64(ci + k));
    Inc(ci, 4);
  end;
  while ci < ACount do
  begin
    if Q[ci] = ATerm then
      AOnLineFeed(ABaseOffset0 + Int64(ci));
    Inc(ci);
  end;
end;

procedure ScanBufferForLineFeeds(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc;
  const ATermByte: Byte);
begin
  if (ABase = nil) or (ACount <= 0) then Exit;
  if ATermByte <> 10 then
    ScanBufferForTermByte(ABase, ACount, ABaseOffset0, ATermByte, AOnLineFeed)
  else if LineIndexScanHasAvx2 and (ACount >= 32) then
    ScanBufferWide(ABase, 0, ACount, ABaseOffset0, AOnLineFeed)
  else
    ScanBufferSwar(ABase, 0, ACount, ABaseOffset0, AOnLineFeed);
end;

{ ============================================================================ }
{ Mapa de bits: 1 bit por byte do bloco (bit i da palavra w = byte w*64 + i)     }
{ ============================================================================ }

{ Grava em ADst uma palavra de 64 bits por cada 64 bytes de ASrc (AGroups grupos),
  com bit = 1 onde o byte e igual a ATerm. Win64: SSE2 (pcmpeqb + pmovmskb),
  presente em todas as CPUs x64. }
{$IFDEF WIN64}
procedure BuildTermMask64(ASrc: PByte; AGroups: NativeInt; ADst: PUInt64; ATerm: Byte);
asm
  .NOFRAME
  movzx    eax, r9b
  imul     eax, eax, $01010101
  movd     xmm1, eax
  pshufd   xmm1, xmm1, 0
  test     rdx, rdx
  jle      @done
@loop:
  movdqu   xmm0, [rcx]
  movdqu   xmm2, [rcx + 16]
  movdqu   xmm3, [rcx + 32]
  movdqu   xmm4, [rcx + 48]
  pcmpeqb  xmm0, xmm1
  pcmpeqb  xmm2, xmm1
  pcmpeqb  xmm3, xmm1
  pcmpeqb  xmm4, xmm1
  pmovmskb eax, xmm0
  pmovmskb r9d, xmm2
  pmovmskb r10d, xmm3
  pmovmskb r11d, xmm4
  shl      r9, 16
  shl      r10, 32
  shl      r11, 48
  or       rax, r9
  or       rax, r10
  or       rax, r11
  mov      [r8], rax
  add      rcx, 64
  add      r8, 8
  dec      rdx
  jnz      @loop
@done:
end;
{$ELSE}
procedure BuildTermMask64(ASrc: PByte; AGroups: NativeInt; ADst: PUInt64; ATerm: Byte);
var
  G, I: NativeInt;
  M: UInt64;
begin
  for G := 0 to AGroups - 1 do
  begin
    M := 0;
    for I := 0 to 63 do
      if ASrc[I] = ATerm then
        M := M or (UInt64(1) shl I);
    ADst^ := M;
    Inc(ASrc, 64);
    Inc(ADst);
  end;
end;
{$ENDIF}

function PopCount64(X: UInt64): Integer; inline;
begin
  X := X - ((X shr 1) and $5555555555555555);
  X := (X and $3333333333333333) + ((X shr 2) and $3333333333333333);
  X := (X + (X shr 4)) and $0F0F0F0F0F0F0F0F;
  Result := Integer((X * UInt64($0101010101010101)) shr 56);
end;

const
  DEBRUIJN64: UInt64 = $03F79D71B4CB0A89;
  DEBRUIJN64_INDEX: array[0..63] of Byte = (
     0,  1, 48,  2, 57, 49, 28,  3, 61, 58, 50, 42, 38, 29, 17,  4,
    62, 55, 59, 36, 53, 51, 43, 22, 45, 39, 33, 30, 24, 18, 12,  5,
    63, 47, 56, 27, 60, 41, 37, 16, 54, 35, 52, 21, 44, 32, 23, 11,
    46, 26, 40, 15, 34, 20, 31, 10, 25, 14, 19,  9, 13,  8,  7,  6);

{ Indice do bit 1 mais baixo (X <> 0). }
function LowBitIndex(X: UInt64): Integer; inline;
begin
  Result := DEBRUIJN64_INDEX[((X and (not X + 1)) * DEBRUIJN64) shr 58];
end;

type
  { Bloco processado por um worker e consumido pela juncao. }
  TLineIndexChunk = record
    ChunkIdx: Int64;            { bloco publicado neste slot (-1 = nenhum) }
    Len: Integer;               { bytes do bloco (o ultimo pode ser menor) }
    Words: Integer;             { palavras validas em Bits }
    LineCount: Int64;           { quebras de linha no bloco }
    Bits: TArray<UInt64>;
  end;

  TChunkWaitResult = (cwReady, cwStopped, cwError);

  { Buffer alinhado de um bloco, com o pedido overlapped associado. }
  TDirectReadBuf = record
    Mem: PByte;          { VirtualAlloc: alinhado a pagina/64 KB }
    Ov: TOverlapped;
    Chunk: Int64;        { bloco emitido/lido neste buffer; -1 = livre }
    Pending: Boolean;    { ReadFile emitido, resultado ainda nao recolhido }
    Done: Boolean;       { resultado recolhido; Got valido }
    Got: DWORD;
  end;
  PDirectReadBuf = ^TDirectReadBuf;

  { Leitor sequencial sem cache: ReadFile + FILE_FLAG_NO_BUFFERING + OVERLAPPED.
    Acquire(K) emite as leituras ate K + depth e espera K; os blocos sao pedidos
    em ordem crescente e o buffer de K e reutilizado por K + depth + 1. }
  TLineIndexDirectReader = class
  private
    FHandle: THandle;
    FFileSize: Int64;
    FChunkCount: Int64;
    FDepth: Integer;
    FBufs: array of TDirectReadBuf;
    FNextIssue: Int64;
    FFailed: Boolean;
    FLastError: string;
    function BufIndex(const AChunk: Int64): Integer; inline;
    function ExpectedLen(const AChunk: Int64): Integer;
    function Issue(const AChunk: Int64): Boolean;
    function Collect(var B: TDirectReadBuf): Boolean;
    procedure CancelAll;
  public
    constructor Create(const AFileName: string; const AFileSize: Int64; ADepth: Integer);
    destructor Destroy; override;
    { Abre o ficheiro, aloca os buffers e le o primeiro bloco (prova de que a
      flag e aceite neste volume). nil se algo falhar; a razao fica em AError. }
    class function TryCreate(const AFileName: string; const AFileSize: Int64;
      const ADepth: Integer; out AError: string): TLineIndexDirectReader;
    { Buffer com o bloco AChunk (ExpectedLen bytes validos) ou nil em erro. }
    function Acquire(const AChunk: Int64): PByte;
    property LastError: string read FLastError;
  end;

  TLineIndexPipeline = class
  private
    FFileName: string;
    FFileSize: Int64;
    FTermByte: Byte;
    FChunkCount: Int64;
    FWindow: Integer;
    FSlots: array of TLineIndexChunk;
    FNextChunk: Int64;
    FMerged: Int64;
    FStop: Boolean;
    FError: string;
    FLock: TCriticalSection;
    FCond: TConditionVariableCS;
    FDirect: TLineIndexDirectReader;
    procedure MaskRegion(const ASrc: PByte; const ARel, AAvail: Integer;
      var ASlot: TLineIndexChunk);
    procedure ScanChunk(AMMF: TMMFReader; const AChunk: Int64; var ASlot: TLineIndexChunk);
    procedure ScanBuffer(const ASrc: PByte; const AChunk: Int64; var ASlot: TLineIndexChunk);
    function WaitSlotFree(const AChunk: Int64): Boolean;
    procedure PublishChunk(const AChunk: Int64);
  public
    constructor Create(const AFileName: string; const AFileSize: Int64;
      const ATermByte: Byte; const AWindow: Integer);
    destructor Destroy; override;
    procedure WorkerLoop;
    procedure DirectLoop;
    function WaitChunkReady(const AChunk: Int64;
      const AShouldStop: TIndexScanShouldStopEvent): TChunkWaitResult;
    procedure ReleaseChunk;
    procedure RequestStop;
    procedure Fail(const AMsg: string);
    function Slot(const AChunk: Int64): Integer; inline;
    property ChunkCount: Int64 read FChunkCount;
    property ErrorMsg: string read FError;
  end;

  TLineIndexScanWorker = class(TThread)
  private
    FPipe: TLineIndexPipeline;
    FDirect: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(APipe: TLineIndexPipeline; const ADirect: Boolean);
  end;

{ ============================================================================ }
{ TLineIndexDirectReader                                                       }
{ ============================================================================ }

constructor TLineIndexDirectReader.Create(const AFileName: string; const AFileSize: Int64;
  ADepth: Integer);
var
  I: Integer;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FFileSize := AFileSize;
  FChunkCount := (AFileSize + LINE_INDEX_CHUNK_BYTES - 1) div LINE_INDEX_CHUNK_BYTES;
  if ADepth < 1 then ADepth := 1;
  if ADepth > LINE_INDEX_DIRECT_QUEUE_DEPTH_MAX then ADepth := LINE_INDEX_DIRECT_QUEUE_DEPTH_MAX;
  FDepth := ADepth;
  FNextIssue := 0;
  FHandle := CreateFile(PChar(AFileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
    FILE_FLAG_NO_BUFFERING or FILE_FLAG_OVERLAPPED, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('CreateFile(NO_BUFFERING) failed: %d', [GetLastError]);
  SetLength(FBufs, FDepth + 1);
  for I := 0 to High(FBufs) do
  begin
    FBufs[I].Chunk := -1;
    FBufs[I].Mem := VirtualAlloc(nil, LINE_INDEX_CHUNK_BYTES, MEM_COMMIT or MEM_RESERVE,
      PAGE_READWRITE);
    if FBufs[I].Mem = nil then
      raise Exception.CreateFmt('VirtualAlloc(%d bytes) failed: %d',
        [LINE_INDEX_CHUNK_BYTES, GetLastError]);
    FBufs[I].Ov.hEvent := CreateEvent(nil, True, False, nil);
    if FBufs[I].Ov.hEvent = 0 then
      raise Exception.CreateFmt('CreateEvent failed: %d', [GetLastError]);
  end;
end;

destructor TLineIndexDirectReader.Destroy;
var
  I: Integer;
begin
  CancelAll;
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
  { So depois de nenhum pedido estar em voo e possivel libertar os buffers. }
  for I := 0 to High(FBufs) do
  begin
    if FBufs[I].Mem <> nil then
      VirtualFree(FBufs[I].Mem, 0, MEM_RELEASE);
    if FBufs[I].Ov.hEvent <> 0 then
      CloseHandle(FBufs[I].Ov.hEvent);
  end;
  FBufs := nil;
  inherited;
end;

class function TLineIndexDirectReader.TryCreate(const AFileName: string;
  const AFileSize: Int64; const ADepth: Integer; out AError: string): TLineIndexDirectReader;
begin
  Result := nil;
  AError := '';
  if AFileSize <= 0 then Exit;
  try
    Result := TLineIndexDirectReader.Create(AFileName, AFileSize, ADepth);
    { Prova: emitir e recolher o bloco 0. ERROR_INVALID_PARAMETER aqui significa
      que o volume nao aceita a flag (ex.: alinhamento, driver de rede). }
    if (not Result.Issue(0)) or (not Result.Collect(Result.FBufs[0])) then
    begin
      AError := Result.FLastError;
      FreeAndNil(Result);
    end
    else
      Result.FNextIssue := 1;
  except
    on E: Exception do
    begin
      AError := E.Message;
      FreeAndNil(Result);
    end;
  end;
end;

function TLineIndexDirectReader.BufIndex(const AChunk: Int64): Integer;
begin
  Result := Integer(AChunk mod Length(FBufs));
end;

function TLineIndexDirectReader.ExpectedLen(const AChunk: Int64): Integer;
begin
  Result := Integer(Min(Int64(LINE_INDEX_CHUNK_BYTES),
    FFileSize - AChunk * LINE_INDEX_CHUNK_BYTES));
end;

{ Emite a leitura do bloco AChunk no seu buffer (que tem de estar livre). O pedido
  e arredondado a LINE_INDEX_DIRECT_ALIGN (exigencia do NO_BUFFERING); no ultimo
  bloco o sistema devolve so os bytes ate ao fim do ficheiro. }
function TLineIndexDirectReader.Issue(const AChunk: Int64): Boolean;
var
  B: PDirectReadBuf;
  Start: Int64;
  Want, Dummy, Err: DWORD;
  Ev: THandle;
begin
  Result := False;
  if FFailed or (AChunk >= FChunkCount) then Exit;
  B := @FBufs[BufIndex(AChunk)];
  if B.Pending then
  begin
    FFailed := True;
    FLastError := Format('direct read: buffer of chunk %d still pending', [AChunk]);
    Exit;
  end;
  Start := AChunk * LINE_INDEX_CHUNK_BYTES;
  Want := DWORD(ExpectedLen(AChunk));
  Want := (Want + LINE_INDEX_DIRECT_ALIGN - 1) and not DWORD(LINE_INDEX_DIRECT_ALIGN - 1);
  Ev := B.Ov.hEvent;
  FillChar(B.Ov, SizeOf(B.Ov), 0);
  B.Ov.hEvent := Ev;
  B.Ov.Offset := DWORD(Start and $FFFFFFFF);
  B.Ov.OffsetHigh := DWORD(Start shr 32);
  ResetEvent(Ev);
  Dummy := 0;
  if not ReadFile(FHandle, B.Mem^, Want, Dummy, @B.Ov) then
  begin
    Err := GetLastError;
    if Err <> ERROR_IO_PENDING then
    begin
      FFailed := True;
      FLastError := Format('direct read: ReadFile(chunk %d) failed: %d', [AChunk, Err]);
      Exit;
    end;
  end;
  B.Chunk := AChunk;
  B.Pending := True;
  B.Done := False;
  B.Got := 0;
  Result := True;
end;

{ Espera o pedido do buffer e valida que vieram pelo menos os bytes esperados. }
function TLineIndexDirectReader.Collect(var B: TDirectReadBuf): Boolean;
var
  Got, Err: DWORD;
  Ok: Boolean;
begin
  Result := False;
  if not B.Pending then Exit(B.Done);
  Got := 0;
  Ok := GetOverlappedResult(FHandle, B.Ov, Got, True);
  Err := 0;
  if not Ok then Err := GetLastError;
  B.Pending := False;
  B.Done := True;
  B.Got := Got;
  if not Ok then
  begin
    FFailed := True;
    FLastError := Format('direct read: GetOverlappedResult(chunk %d) failed: %d', [B.Chunk, Err]);
    Exit;
  end;
  if Int64(Got) < ExpectedLen(B.Chunk) then
  begin
    FFailed := True;
    FLastError := Format('direct read: short read at chunk %d (%d < %d)',
      [B.Chunk, Got, ExpectedLen(B.Chunk)]);
    Exit;
  end;
  Result := True;
end;

procedure TLineIndexDirectReader.CancelAll;
var
  I: Integer;
  Got: DWORD;
begin
  if FHandle = INVALID_HANDLE_VALUE then Exit;
  CancelIo(FHandle);
  for I := 0 to High(FBufs) do
    if FBufs[I].Pending then
    begin
      Got := 0;
      GetOverlappedResult(FHandle, FBufs[I].Ov, Got, True);
      FBufs[I].Pending := False;
    end;
end;

function TLineIndexDirectReader.Acquire(const AChunk: Int64): PByte;
var
  B: PDirectReadBuf;
begin
  Result := nil;
  if FFailed or (AChunk >= FChunkCount) then Exit;
  { Manter FDepth leituras em voo alem de AChunk; o buffer de AChunk + FDepth e o
    do bloco AChunk - 1, ja processado pelo chamador. }
  while (not FFailed) and (FNextIssue < FChunkCount) and (FNextIssue <= AChunk + FDepth) do
  begin
    if not Issue(FNextIssue) then Break;
    Inc(FNextIssue);
  end;
  B := @FBufs[BufIndex(AChunk)];
  if B.Chunk <> AChunk then
  begin
    if FLastError = '' then
      FLastError := Format('direct read: chunk %d was not issued', [AChunk]);
    FFailed := True;
    Exit;
  end;
  if not Collect(B^) then Exit;
  Result := B.Mem;
end;

{ ============================================================================ }
{ TLineIndexPipeline                                                           }
{ ============================================================================ }

constructor TLineIndexPipeline.Create(const AFileName: string; const AFileSize: Int64;
  const ATermByte: Byte; const AWindow: Integer);
var
  I: Integer;
begin
  inherited Create;
  FFileName := AFileName;
  FFileSize := AFileSize;
  FTermByte := ATermByte;
  FChunkCount := (AFileSize + LINE_INDEX_CHUNK_BYTES - 1) div LINE_INDEX_CHUNK_BYTES;
  FWindow := AWindow;
  SetLength(FSlots, FWindow);
  for I := 0 to FWindow - 1 do
  begin
    FSlots[I].ChunkIdx := -1;
    SetLength(FSlots[I].Bits, LINE_INDEX_CHUNK_WORDS);
  end;
  FLock := TCriticalSection.Create;
  FCond := TConditionVariableCS.Create;
end;

destructor TLineIndexPipeline.Destroy;
begin
  FreeAndNil(FDirect);
  FCond.Free;
  FLock.Free;
  inherited;
end;

function TLineIndexPipeline.Slot(const AChunk: Int64): Integer;
begin
  Result := Integer(AChunk mod FWindow);
end;

procedure TLineIndexPipeline.RequestStop;
begin
  FLock.Enter;
  try
    FStop := True;
  finally
    FLock.Leave;
  end;
  FCond.ReleaseAll;
end;

procedure TLineIndexPipeline.Fail(const AMsg: string);
begin
  FLock.Enter;
  try
    if FError = '' then
      FError := AMsg;
    FStop := True;
  finally
    FLock.Leave;
  end;
  FCond.ReleaseAll;
end;

{ Marca em ASlot.Bits os terminadores de AAvail bytes a partir de ASrc, que
  correspondem aos bytes [ARel, ARel + AAvail) do bloco. Grupos completos de 64
  alinhados ao bloco vao por SSE2; as pontas (so quando ARel ou o fim nao estao
  alinhados, normalmente apenas o fim do ficheiro) byte a byte. }
procedure TLineIndexPipeline.MaskRegion(const ASrc: PByte; const ARel, AAvail: Integer;
  var ASlot: TLineIndexChunk);

  { Palavras que comecam dentro do intervalo sao zeradas antes do OR. }
  procedure MarkBytes(const ASrc: PByte; const ARel, ACount: Integer);
  var
    I, P, W: Integer;
  begin
    for W := (ARel + 63) shr 6 to (ARel + ACount - 1) shr 6 do
      ASlot.Bits[W] := 0;
    for I := 0 to ACount - 1 do
      if ASrc[I] = FTermByte then
      begin
        P := ARel + I;
        ASlot.Bits[P shr 6] := ASlot.Bits[P shr 6] or (UInt64(1) shl (P and 63));
      end;
  end;

var
  Head, Groups, Tail: Integer;
begin
  Head := (64 - (ARel and 63)) and 63;
  if Head > AAvail then
    Head := AAvail;
  if Head > 0 then
    MarkBytes(ASrc, ARel, Head);
  Groups := (AAvail - Head) shr 6;
  if Groups > 0 then
    BuildTermMask64(ASrc + Head, Groups, @ASlot.Bits[(ARel + Head) shr 6], FTermByte);
  Tail := AAvail - Head - (Groups shl 6);
  if Tail > 0 then
    MarkBytes(ASrc + Head + (Groups shl 6), ARel + Head + (Groups shl 6), Tail);
end;

{ Gera o mapa de bits do bloco AChunk (via MMF) e conta as quebras de linha. }
procedure TLineIndexPipeline.ScanChunk(AMMF: TMMFReader; const AChunk: Int64;
  var ASlot: TLineIndexChunk);
var
  Start, Off: Int64;
  P: PByte;
  Contiguous: Cardinal;
  Avail, I: Integer;
  Lines: Int64;
begin
  Start := AChunk * LINE_INDEX_CHUNK_BYTES;
  ASlot.Len := Integer(Min(Int64(LINE_INDEX_CHUNK_BYTES), FFileSize - Start));
  ASlot.Words := (ASlot.Len + 63) shr 6;
  Off := Start;
  while Off < Start + ASlot.Len do
  begin
    P := AMMF.PtrAt(Off, 1, Contiguous);
    if (P = nil) or (Contiguous = 0) then
      raise Exception.CreateFmt('Line index scan: read failed at offset %d', [Off]);
    Avail := Integer(Min(Int64(Contiguous), Start + ASlot.Len - Off));
    MaskRegion(P, Integer(Off - Start), Avail, ASlot);
    Inc(Off, Avail);
  end;
  Lines := 0;
  for I := 0 to ASlot.Words - 1 do
    Inc(Lines, PopCount64(ASlot.Bits[I]));
  ASlot.LineCount := Lines;
end;

{ Igual a ScanChunk, mas sobre um bloco inteiro ja em memoria (leitura directa). }
procedure TLineIndexPipeline.ScanBuffer(const ASrc: PByte; const AChunk: Int64;
  var ASlot: TLineIndexChunk);
var
  I: Integer;
  Lines: Int64;
begin
  ASlot.Len := Integer(Min(Int64(LINE_INDEX_CHUNK_BYTES),
    FFileSize - AChunk * LINE_INDEX_CHUNK_BYTES));
  ASlot.Words := (ASlot.Len + 63) shr 6;
  MaskRegion(ASrc, 0, ASlot.Len, ASlot);
  Lines := 0;
  for I := 0 to ASlot.Words - 1 do
    Inc(Lines, PopCount64(ASlot.Bits[I]));
  ASlot.LineCount := Lines;
end;

{ O bloco K usa o slot do bloco K - FWindow, que tem de ja ter sido juntado.
  False se foi pedida paragem entretanto. }
function TLineIndexPipeline.WaitSlotFree(const AChunk: Int64): Boolean;
begin
  FLock.Enter;
  try
    while (FMerged <= AChunk - FWindow) and (not FStop) do
      FCond.WaitFor(FLock, 100);
    Result := not FStop;
  finally
    FLock.Leave;
  end;
end;

procedure TLineIndexPipeline.PublishChunk(const AChunk: Int64);
begin
  FLock.Enter;
  try
    FSlots[Slot(AChunk)].ChunkIdx := AChunk;
  finally
    FLock.Leave;
  end;
  FCond.ReleaseAll;
end;

{ Cada worker pega o proximo bloco (ordem crescente) e espera que o slot fique livre. }
procedure TLineIndexPipeline.WorkerLoop;
var
  MMF: TMMFReader;
  K: Int64;
begin
  MMF := nil;
  try
    try
      { View = um bloco; sem prefetch da janela seguinte (pertence a outro worker). }
      MMF := TMMFReader.Create(FFileName, LINE_INDEX_CHUNK_BYTES, False);
      while True do
      begin
        K := TInterlocked.Increment(FNextChunk) - 1;
        if K >= FChunkCount then
          Break;
        if not WaitSlotFree(K) then
          Break;
        ScanChunk(MMF, K, FSlots[Slot(K)]);
        PublishChunk(K);
      end;
    except
      on E: Exception do
        Fail(E.Message);
    end;
  finally
    MMF.Free;
  end;
end;

{ Leitura directa: um unico leitor sequencial (FDirect) com blocos em voo; o
  mesmo thread gera o mapa de bits. Se a leitura directa falhar a meio, os blocos
  restantes (incluindo o que falhou) seguem por MMF, sem perder nada. }
procedure TLineIndexPipeline.DirectLoop;
var
  MMF: TMMFReader;
  K: Int64;
  P: PByte;
begin
  MMF := nil;
  try
    try
      K := 0;
      while K < FChunkCount do
      begin
        if not WaitSlotFree(K) then
          Break;
        P := nil;
        if FDirect <> nil then
        begin
          P := FDirect.Acquire(K);
          if P = nil then
          begin
            LogAsync(FastFileRuntimeLogPath, Format(
              '[LineIndexScan] direct read fallback to MMF at chunk %d: %s',
              [K, FDirect.LastError]));
            FreeAndNil(FDirect);
          end;
        end;
        if P <> nil then
          ScanBuffer(P, K, FSlots[Slot(K)])
        else
        begin
          if MMF = nil then
            MMF := TMMFReader.Create(FFileName, LINE_INDEX_CHUNK_BYTES, False);
          ScanChunk(MMF, K, FSlots[Slot(K)]);
        end;
        PublishChunk(K);
        Inc(K);
      end;
    except
      on E: Exception do
        Fail(E.Message);
    end;
  finally
    MMF.Free;
    FreeAndNil(FDirect);
  end;
end;

function TLineIndexPipeline.WaitChunkReady(const AChunk: Int64;
  const AShouldStop: TIndexScanShouldStopEvent): TChunkWaitResult;
var
  S: Integer;
begin
  S := Slot(AChunk);
  while True do
  begin
    FLock.Enter;
    try
      if FSlots[S].ChunkIdx = AChunk then
        Exit(cwReady);
      if FError <> '' then
        Exit(cwError);
      if FStop then
        Exit(cwStopped);
      FCond.WaitFor(FLock, 50);
      if FSlots[S].ChunkIdx = AChunk then
        Exit(cwReady);
    finally
      FLock.Leave;
    end;
    if Assigned(AShouldStop) and AShouldStop then
      Exit(cwStopped);
  end;
end;

procedure TLineIndexPipeline.ReleaseChunk;
begin
  FLock.Enter;
  try
    Inc(FMerged);
  finally
    FLock.Leave;
  end;
  FCond.ReleaseAll;
end;

constructor TLineIndexScanWorker.Create(APipe: TLineIndexPipeline; const ADirect: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPipe := APipe;
  FDirect := ADirect;
end;

procedure TLineIndexScanWorker.Execute;
begin
  if FDirect then
    FPipe.DirectLoop
  else
    FPipe.WorkerLoop;
end;

{ ============================================================================ }
{ Juncao: grava os indices a partir do mapa de bits de cada bloco               }
{ ============================================================================ }

{ Com indice denso: percorre todas as quebras de linha (custo por linha, como o
  caminho sequencial; o denso so existe ate 2 GB). }
procedure MergeChunkDense(const C: TLineIndexChunk; const ABase: Int64;
  const AWriters: TLineIndexWriterBundle; var ALineCount: Int64);
var
  Wi: Integer;
  X: UInt64;
  LfPos0, LineOff: Int64;
begin
  for Wi := 0 to C.Words - 1 do
  begin
    X := C.Bits[Wi];
    while X <> 0 do
    begin
      LfPos0 := ABase + (Int64(Wi) shl 6) + LowBitIndex(X);
      X := X and (X - 1);
      LineOff := LfPos0 + 2;
      Inc(ALineCount);
      AWriters.IdxW.WriteOffsetDirect(LineOff);
      if AWriters.BlkW <> nil then
        AWriters.BlkW.NoteLineStart1Based(LineOff, LfPos0);
      if (ALineCount and (CKPT_INTERVAL - 1)) = 0 then
        AWriters.CkptW.WriteOffsetDirect(LineOff);
    end;
  end;
end;

{ Primeiro bit 1 em [ALo, AHi) do bloco, ou -1. }
function FirstBitInRange(const C: TLineIndexChunk; const ALo, AHi: Integer): Integer;
var
  Wi: Integer;
  X: UInt64;
begin
  Result := -1;
  if ALo >= AHi then Exit;
  Wi := ALo shr 6;
  X := C.Bits[Wi] and (UInt64($FFFFFFFFFFFFFFFF) shl (ALo and 63));
  while X = 0 do
  begin
    Inc(Wi);
    if (Wi shl 6) >= AHi then Exit;
    X := C.Bits[Wi];
  end;
  Result := (Wi shl 6) + LowBitIndex(X);
  if Result >= AHi then
    Result := -1;
end;

{ Sem indice denso: so visita as linhas que vao para o checkpoint (1 em
  CKPT_INTERVAL, localizadas por popcount) e a primeira linha de cada bloco do
  Zero Scan. O custo deixa de ser proporcional ao numero de linhas. }
procedure MergeChunkSparse(const C: TLineIndexChunk; const ABase: Int64;
  const AWriters: TLineIndexWriterBundle; var ALineCount: Int64);
var
  Need, Before: Int64;
  Wi, Pc, R, P: Integer;
  X: UInt64;
  B, LastB, BlockLo, BlockHi: Int64;
begin
  { Need = posicao (1..LineCount) da quebra que torna ALineCount multiplo de CKPT_INTERVAL. }
  Need := CKPT_INTERVAL - (ALineCount and (CKPT_INTERVAL - 1));
  Wi := 0;
  Before := 0;
  while Need <= C.LineCount do
  begin
    while True do
    begin
      Pc := PopCount64(C.Bits[Wi]);
      if Before + Pc >= Need then
        Break;
      Inc(Before, Pc);
      Inc(Wi);
    end;
    X := C.Bits[Wi];
    for R := 1 to Integer(Need - Before - 1) do
      X := X and (X - 1);
    AWriters.CkptW.WriteOffsetDirect(ABase + (Int64(Wi) shl 6) + LowBitIndex(X) + 2);
    Inc(Need, CKPT_INTERVAL);
  end;

  if AWriters.BlkW <> nil then
  begin
    B := ABase div ZERO_SCAN_BLOCK_BYTES;
    LastB := (ABase + C.Len - 1) div ZERO_SCAN_BLOCK_BYTES;
    while B <= LastB do
    begin
      BlockLo := Max(B * ZERO_SCAN_BLOCK_BYTES, ABase) - ABase;
      BlockHi := Min((B + 1) * ZERO_SCAN_BLOCK_BYTES, ABase + C.Len) - ABase;
      P := FirstBitInRange(C, Integer(BlockLo), Integer(BlockHi));
      if P >= 0 then
        AWriters.BlkW.NoteLineStart1Based(ABase + P + 2, ABase + P);
      Inc(B);
    end;
  end;

  Inc(ALineCount, C.LineCount);
end;

{ ============================================================================ }
{ TLineIndexStreamBuilder                                                      }
{ ============================================================================ }

const
  STREAM_BUILDER_BLOCK_BYTES = 1024 * 1024;

constructor TLineIndexStreamBuilder.Create(const AWriters: TLineIndexWriterBundle;
  const ALinesBefore: Int64; const ATermByte: Byte);
begin
  inherited Create;
  FWriters := AWriters;
  FWriters.BlkW := nil;
  FLineCount := ALinesBefore;
  FTermByte := ATermByte;
  SetLength(FBits, STREAM_BUILDER_BLOCK_BYTES div 64);
end;

procedure TLineIndexStreamBuilder.Feed(AData: PByte; ALen: NativeInt; AOutOffset0: Int64);
var
  C: TLineIndexChunk;
  N, Groups, I, P: Integer;
  Lines: Int64;
begin
  C.Bits := FBits;
  while ALen > 0 do
  begin
    if ALen > STREAM_BUILDER_BLOCK_BYTES then
      N := STREAM_BUILDER_BLOCK_BYTES
    else
      N := Integer(ALen);
    Groups := N shr 6;
    if Groups > 0 then
      BuildTermMask64(AData, Groups, @FBits[0], FTermByte);
    if (N and 63) <> 0 then
    begin
      FBits[Groups] := 0;
      for I := Groups shl 6 to N - 1 do
        if AData[I] = FTermByte then
        begin
          P := I and 63;
          FBits[Groups] := FBits[Groups] or (UInt64(1) shl P);
        end;
    end;
    C.Len := N;
    C.Words := (N + 63) shr 6;
    Lines := 0;
    for I := 0 to C.Words - 1 do
      Inc(Lines, PopCount64(FBits[I]));
    C.LineCount := Lines;
    if FWriters.IdxW <> nil then
      MergeChunkDense(C, AOutOffset0, FWriters, FLineCount)
    else
      MergeChunkSparse(C, AOutOffset0, FWriters, FLineCount);
    Inc(AData, N);
    Dec(ALen, N);
    Inc(AOutOffset0, N);
  end;
end;

function FilePathIncursSeekPenalty(const AFileName: string): Boolean;
var
  Drive, DevicePath: string;
  H: THandle;
  Query: TStoragePropertyQuery;
  Desc: TDeviceSeekPenaltyDescriptor;
  Ret: DWORD;
begin
  Result := False;
  Drive := ExtractFileDrive(ExpandFileName(AFileName));
  if Length(Drive) < 2 then Exit;
  DevicePath := '\\.\' + Drive[1] + ':';
  H := CreateFile(PChar(DevicePath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then Exit;
  try
    FillChar(Query, SizeOf(Query), 0);
    Query.PropertyId := StorageDeviceSeekPenaltyProperty;
    Query.QueryType := PropertyStandardQuery;
    FillChar(Desc, SizeOf(Desc), 0);
    if DeviceIoControl(H, IOCTL_STORAGE_QUERY_PROPERTY, @Query, SizeOf(Query),
      @Desc, SizeOf(Desc), Ret, nil) then
      Result := Desc.IncursSeekPenalty;
  finally
    CloseHandle(H);
  end;
end;

function TryParallelLineIndexScan(const AFileName: string; const AFileSize: Int64;
  var ALineCount: Int64;
  const AWriters: TLineIndexWriterBundle;
  const AShouldStop: TIndexScanShouldStopEvent; const AOnProgress: TIndexScanProgressEvent;
  out AWorkerCount: Integer; const ATermByte: Byte): Boolean;
{$IFDEF WIN64}
var
  WorkerCount, I: Integer;
  Workers: array of TLineIndexScanWorker;
  Pipe: TLineIndexPipeline;
  Direct: TLineIndexDirectReader;
  DirectErr: string;
  K, Base: Int64;
  StartTick: UInt64;
  Stopped: Boolean;
  S: Integer;
{$ENDIF}
begin
  Result := False;
  AWorkerCount := 0;
  {$IFDEF WIN64}
  if not LINE_INDEX_PARALLEL_ENABLED then
    Exit;
  if AFileSize < LINE_INDEX_PARALLEL_MIN_BYTES then
    Exit;
  if not Assigned(AWriters.CkptW) then
    Exit;

  StartTick := GetTickCount64;

  { Ficheiro grande face a RAM: leitura directa sem cache, um so leitor sequencial
    (medido: 1 leitor > N leitores em NVMe/SATA/HDD) com blocos em voo. }
  Direct := nil;
  if LineIndexShouldUseDirectRead(AFileSize) then
  begin
    Direct := TLineIndexDirectReader.TryCreate(AFileName, AFileSize,
      GLineIndexDirectQueueDepth, DirectErr);
    if Direct = nil then
      LogAsync(FastFileRuntimeLogPath,
        '[LineIndexScan] direct read unavailable, using MMF: ' + DirectErr);
  end;

  if Direct <> nil then
    WorkerCount := 1
  { Disco com seek (HDD): um so worker, leitura sequencial; a juncao continua
    noutra thread e o mapa de bits evita o callback por linha. }
  else if FilePathIncursSeekPenalty(AFileName) then
    WorkerCount := 1
  else
    WorkerCount := LineIndexScanWorkerCount;
  AWorkerCount := WorkerCount;

  Stopped := False;
  try
    Pipe := TLineIndexPipeline.Create(AFileName, AFileSize, ATermByte,
      Max(4, WorkerCount * 2));
  except
    Direct.Free;
    raise;
  end;
  try
    { O pipeline passa a ser dono do leitor (libertado em DirectLoop/Destroy). }
    Pipe.FDirect := Direct;
    SetLength(Workers, WorkerCount);
    try
      for I := 0 to WorkerCount - 1 do
      begin
        Workers[I] := TLineIndexScanWorker.Create(Pipe, Direct <> nil);
        Workers[I].Start;
      end;

      K := 0;
      while K < Pipe.ChunkCount do
      begin
        case Pipe.WaitChunkReady(K, AShouldStop) of
          cwStopped:
            begin
              Stopped := True;
              Break;
            end;
          cwError:
            raise Exception.Create(Pipe.ErrorMsg);
        end;
        S := Pipe.Slot(K);
        Base := K * LINE_INDEX_CHUNK_BYTES;
        if AWriters.IdxW <> nil then
          MergeChunkDense(Pipe.FSlots[S], Base, AWriters, ALineCount)
        else
          MergeChunkSparse(Pipe.FSlots[S], Base, AWriters, ALineCount);
        Pipe.ReleaseChunk;
        Inc(K);
        if Assigned(AOnProgress) then
          AOnProgress(Min(AFileSize, K * LINE_INDEX_CHUNK_BYTES));
        if Assigned(AShouldStop) and AShouldStop then
        begin
          Stopped := True;
          Break;
        end;
      end;
    finally
      Pipe.RequestStop;
      for I := 0 to High(Workers) do
        if Workers[I] <> nil then
        begin
          Workers[I].WaitFor;
          Workers[I].Free;
        end;
    end;

    LogAsync(FastFileRuntimeLogPath, Format(
      '[LineIndexScan] parallel workers=%d direct=%s depth=%d chunks=%d/%d bytes=%d lines=%d ms=%d stopped=%s dense=%s blocks=%s',
      [WorkerCount, BoolToStr(Direct <> nil, True), GLineIndexDirectQueueDepth,
       K, Pipe.ChunkCount, AFileSize, ALineCount, Int64(GetTickCount64 - StartTick),
       BoolToStr(Stopped, True),
       BoolToStr(AWriters.IdxW <> nil, True), BoolToStr(AWriters.BlkW <> nil, True)]));
    Result := True;
  finally
    Pipe.Free;
  end;
  {$ENDIF}
end;

end.
