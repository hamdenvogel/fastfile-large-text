unit uLineIndexScan;

{
  Scan SWAR / AVX2 e indexacao paralela (Win64) para TReadFileThread.
  Ficheiros >2 GB (indice esparso): workers em paralelo, deltas em RAM, sem ff_scanpart_*.tmp.
}

interface

uses
  Classes, SysUtils, uMMF, UnBufferedTextWriter, uZeroScanBlockIndex, UnConsts;

const
  { Win64 + indice esparso (>2 GB): workers em RAM (deltas), sem ff_scanpart_*.tmp. }
  LINE_INDEX_PARALLEL_ENABLED = True;
  LINE_INDEX_PARALLEL_MIN_BYTES = Int64(128) * 1024 * 1024;
  LINE_INDEX_MAX_WORKERS = 8;
  LINE_INDEX_LINE_LIMIT = 2000000000;
  { Tecto de RAM por worker para a lista de LF (deltas 4 bytes). Acima: fallback sequencial. }
  LINE_INDEX_PARALLEL_MAX_DELTA_BYTES = Int64(256) * 1024 * 1024;

type
  TLineFeedFoundProc = reference to procedure(const ALfPos0: Int64);

  TLineFeedSink = class
  public
    procedure OnLineFeed(const ALfPos0: Int64); virtual; abstract;
  end;

  TLineIndexWriterBundle = record
    IdxW: TBufferedTextWriter;
    CkptW: TBufferedTextWriter;
    BlkW: TZeroScanBlockIndexWriter;
    SparseCkptOnly: Boolean;
  end;

  TIndexScanProgressEvent = reference to procedure(const Scanned: Int64);
  TIndexScanShouldStopEvent = reference to function: Boolean;

function LineIndexScanHasAvx2: Boolean;
function LineIndexScanWorkerCount: Integer;

{ ATermByte: byte terminador de linha (10 = LF; 13 = CR em ficheiros Mac classico). }
procedure ScanBufferForLineFeeds(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc;
  const ATermByte: Byte = 10); overload;

procedure ScanBufferForLineFeeds(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; ASink: TLineFeedSink; const ATermByte: Byte = 10); overload;

function TryParallelLineIndexScan(const AFileName: string; const AFileSize: Int64;
  var ALineCount: Int64; var AHitLineLimit: Boolean;
  const AWriters: TLineIndexWriterBundle;
  const AShouldStop: TIndexScanShouldStopEvent; const AOnProgress: TIndexScanProgressEvent;
  const ATermByte: Byte = 10): Boolean;

implementation

uses
  Windows, SyncObjs, uFastFilePaths, UnUtils;

const
  PF_AVX2_INSTRUCTIONS_AVAILABLE = 40;
  LINE_INDEX_WORKER_VIEW_BYTES = 128 * 1024 * 1024;
  IOCTL_STORAGE_QUERY_PROPERTY = $002D1400;
  StorageDeviceSeekPenaltyProperty = 7;
  PropertyStandardQuery = 0;

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

  TIndexScanProgress = class
  private
    FBytes: Int64;
  public
    procedure Add(const ADelta: Int64);
    function GetBytes: Int64;
  end;

  TRamDeltaLineFeedSink = class(TLineFeedSink)
  private
    FStream: TMemoryStream;
    FLineCount: Int64;
    FPrevNext: Int64;
    FHitLimit: Boolean;
    FTooBig: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure OnLineFeed(const ALfPos0: Int64); override;
    property LineCount: Int64 read FLineCount;
    property HitLimit: Boolean read FHitLimit;
    property TooBig: Boolean read FTooBig;
    property Stream: TMemoryStream read FStream;
  end;

  TIndexScanWorker = class(TThread)
  private
    FFileName: string;
    FChunkStart: Int64;
    FChunkEnd: Int64;
    FSkipUntilFirstLf: Boolean;
    FTermByte: Byte;
    FProgress: TIndexScanProgress;
    FShouldStop: TIndexScanShouldStopEvent;
    FSink: TRamDeltaLineFeedSink;
    FErrorMsg: string;
    procedure ScanChunk;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName: string; AChunkStart, AChunkEnd: Int64;
      ASkipUntilFirstLf: Boolean; AProgress: TIndexScanProgress;
      const AShouldStop: TIndexScanShouldStopEvent; ATermByte: Byte);
    destructor Destroy; override;
    property Sink: TRamDeltaLineFeedSink read FSink;
    property ErrorMsg: string read FErrorMsg;
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

procedure ScanSwarCardinalAt(const ABase: PByte; const RegionBase, ByteIdx: Integer;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc); overload;
var
  W, M: Cardinal;
begin
  W := PCardinal(@PByteArray(ABase)[RegionBase + ByteIdx])^;
  M := ((W xor $0A0A0A0A) - $01010101) and not (W xor $0A0A0A0A) and $80808080;
  if M = 0 then Exit;
  if (M and $00000080) <> 0 then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx));
  if (M and $00008000) <> 0 then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx + 1));
  if (M and $00800000) <> 0 then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx + 2));
  if (M and $80000000) <> 0 then
    AOnLineFeed(ABaseOffset0 + Int64(RegionBase + ByteIdx + 3));
end;

procedure ScanSwarCardinalAt(const ABase: PByte; const RegionBase, ByteIdx: Integer;
  const ABaseOffset0: Int64; ASink: TLineFeedSink); overload;
var
  W, M: Cardinal;
  LfPos0: Int64;
begin
  W := PCardinal(@PByteArray(ABase)[RegionBase + ByteIdx])^;
  M := ((W xor $0A0A0A0A) - $01010101) and not (W xor $0A0A0A0A) and $80808080;
  if M = 0 then Exit;
  if (M and $00000080) <> 0 then
  begin
    LfPos0 := ABaseOffset0 + Int64(RegionBase + ByteIdx);
    ASink.OnLineFeed(LfPos0);
  end;
  if (M and $00008000) <> 0 then
  begin
    LfPos0 := ABaseOffset0 + Int64(RegionBase + ByteIdx + 1);
    ASink.OnLineFeed(LfPos0);
  end;
  if (M and $00800000) <> 0 then
  begin
    LfPos0 := ABaseOffset0 + Int64(RegionBase + ByteIdx + 2);
    ASink.OnLineFeed(LfPos0);
  end;
  if (M and $80000000) <> 0 then
  begin
    LfPos0 := ABaseOffset0 + Int64(RegionBase + ByteIdx + 3);
    ASink.OnLineFeed(LfPos0);
  end;
end;

procedure ScanBufferSwar(const ABase: PByte; const RegionBase, Count: Integer;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc); overload;
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

procedure ScanBufferSwar(const ABase: PByte; const RegionBase, Count: Integer;
  const ABaseOffset0: Int64; ASink: TLineFeedSink); overload;
var
  ci: Integer;
begin
  ci := 0;
  while ci <= Count - 8 do
  begin
    ScanSwarCardinalAt(ABase, RegionBase, ci, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 4, ABaseOffset0, ASink);
    Inc(ci, 8);
  end;
  while ci <= Count - 4 do
  begin
    ScanSwarCardinalAt(ABase, RegionBase, ci, ABaseOffset0, ASink);
    Inc(ci, 4);
  end;
  while ci < Count do
  begin
    if PByteArray(ABase)[RegionBase + ci] = 10 then
      ASink.OnLineFeed(ABaseOffset0 + Int64(RegionBase + ci));
    Inc(ci);
  end;
end;

{ Win64: bloco de 32 bytes (8x SWAR de 4 bytes) quando AVX2 disponivel na CPU. }
procedure ScanBufferWide(const ABase: PByte; const RegionBase, Count: Integer;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc); overload;
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

procedure ScanBufferWide(const ABase: PByte; const RegionBase, Count: Integer;
  const ABaseOffset0: Int64; ASink: TLineFeedSink); overload;
var
  ci: Integer;
begin
  ci := 0;
  while ci <= Count - 32 do
  begin
    ScanSwarCardinalAt(ABase, RegionBase, ci, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 4, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 8, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 12, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 16, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 20, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 24, ABaseOffset0, ASink);
    ScanSwarCardinalAt(ABase, RegionBase, ci + 28, ABaseOffset0, ASink);
    Inc(ci, 32);
  end;
  if ci < Count then
    ScanBufferSwar(ABase, RegionBase + ci, Count - ci, ABaseOffset0, ASink);
end;

{ Terminador diferente de LF (CR): SWAR com padrao variavel + confirmacao por byte. }
procedure ScanBufferForTermByte(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; const ATerm: Byte; ASink: TLineFeedSink;
  const AOnLineFeed: TLineFeedFoundProc);
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
        begin
          if ASink <> nil then
            ASink.OnLineFeed(ABaseOffset0 + Int64(ci + k))
          else
            AOnLineFeed(ABaseOffset0 + Int64(ci + k));
        end;
    Inc(ci, 4);
  end;
  while ci < ACount do
  begin
    if Q[ci] = ATerm then
    begin
      if ASink <> nil then
        ASink.OnLineFeed(ABaseOffset0 + Int64(ci))
      else
        AOnLineFeed(ABaseOffset0 + Int64(ci));
    end;
    Inc(ci);
  end;
end;

procedure ScanBufferForLineFeeds(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; const AOnLineFeed: TLineFeedFoundProc;
  const ATermByte: Byte); overload;
begin
  if (ABase = nil) or (ACount <= 0) then Exit;
  if ATermByte <> 10 then
    ScanBufferForTermByte(ABase, ACount, ABaseOffset0, ATermByte, nil, AOnLineFeed)
  else if LineIndexScanHasAvx2 and (ACount >= 32) then
    ScanBufferWide(ABase, 0, ACount, ABaseOffset0, AOnLineFeed)
  else
    ScanBufferSwar(ABase, 0, ACount, ABaseOffset0, AOnLineFeed);
end;

procedure ScanBufferForLineFeeds(const ABase: PByte; const ACount: NativeInt;
  const ABaseOffset0: Int64; ASink: TLineFeedSink; const ATermByte: Byte); overload;
begin
  if (ABase = nil) or (ACount <= 0) or (ASink = nil) then Exit;
  if ATermByte <> 10 then
    ScanBufferForTermByte(ABase, ACount, ABaseOffset0, ATermByte, ASink, nil)
  else if LineIndexScanHasAvx2 and (ACount >= 32) then
    ScanBufferWide(ABase, 0, ACount, ABaseOffset0, ASink)
  else
    ScanBufferSwar(ABase, 0, ACount, ABaseOffset0, ASink);
end;

procedure TIndexScanProgress.Add(const ADelta: Int64);
begin
  if ADelta = 0 then Exit;
  TInterlocked.Add(FBytes, ADelta);
end;

function TIndexScanProgress.GetBytes: Int64;
begin
  Result := TInterlocked.Add(FBytes, 0);
end;

constructor TRamDeltaLineFeedSink.Create;
begin
  inherited Create;
  FStream := TMemoryStream.Create;
  FLineCount := 0;
  FPrevNext := 0;
  FHitLimit := False;
  FTooBig := False;
end;

destructor TRamDeltaLineFeedSink.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TRamDeltaLineFeedSink.OnLineFeed(const ALfPos0: Int64);
var
  NextLineStart: Int64;
  D: Cardinal;
  Marker: Cardinal;
begin
  if FHitLimit or FTooBig then Exit;
  Inc(FLineCount);
  if FLineCount >= LINE_INDEX_LINE_LIMIT then
  begin
    FHitLimit := True;
    Exit;
  end;
  NextLineStart := ALfPos0 + 2;
  if FLineCount = 1 then
  begin
    FStream.WriteBuffer(NextLineStart, SizeOf(Int64));
    FPrevNext := NextLineStart;
    Exit;
  end;
  if FStream.Size + 12 > LINE_INDEX_PARALLEL_MAX_DELTA_BYTES then
  begin
    FTooBig := True;
    Exit;
  end;
  if (NextLineStart > FPrevNext) and ((NextLineStart - FPrevNext) < Int64($FFFFFFFF)) then
  begin
    D := Cardinal(NextLineStart - FPrevNext);
    FStream.WriteBuffer(D, SizeOf(Cardinal));
  end
  else
  begin
    Marker := $FFFFFFFF;
    FStream.WriteBuffer(Marker, SizeOf(Cardinal));
    FStream.WriteBuffer(NextLineStart, SizeOf(Int64));
  end;
  FPrevNext := NextLineStart;
end;

constructor TIndexScanWorker.Create(const AFileName: string; AChunkStart, AChunkEnd: Int64;
  ASkipUntilFirstLf: Boolean; AProgress: TIndexScanProgress;
  const AShouldStop: TIndexScanShouldStopEvent; ATermByte: Byte);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FFileName := AFileName;
  FChunkStart := AChunkStart;
  FChunkEnd := AChunkEnd;
  FSkipUntilFirstLf := ASkipUntilFirstLf;
  FTermByte := ATermByte;
  FProgress := AProgress;
  FShouldStop := AShouldStop;
  FSink := TRamDeltaLineFeedSink.Create;
end;

destructor TIndexScanWorker.Destroy;
begin
  FSink.Free;
  inherited;
end;

procedure TIndexScanWorker.ScanChunk;
var
  MMF: TMMFReader;
  AbsOffset: Int64;
  P: PByte;
  Contiguous: Cardinal;
  RegionBase, RegionSize, SliceLen: Integer;
  Skipping: Boolean;
begin
  MMF := TMMFReader.Create(FFileName, LINE_INDEX_WORKER_VIEW_BYTES, False);
  try
    Skipping := FSkipUntilFirstLf;
    AbsOffset := FChunkStart;
    while (AbsOffset < FChunkEnd) and (not Terminated) and (not FSink.HitLimit) and
      (not FSink.TooBig) do
    begin
      if Assigned(FShouldStop) and FShouldStop then
        Break;
      P := MMF.PtrAt(AbsOffset, 1, Contiguous);
      if (P = nil) or (Contiguous = 0) then Break;
      if Int64(Contiguous) > FChunkEnd - AbsOffset then
        Contiguous := Cardinal(FChunkEnd - AbsOffset);
      RegionSize := Integer(Contiguous);
      RegionBase := 0;
      while RegionBase < RegionSize do
      begin
        if Skipping then
        begin
          while (RegionBase < RegionSize) and (PByteArray(P)[RegionBase] <> FTermByte) do
            Inc(RegionBase);
          if RegionBase >= RegionSize then
            Break;
          Skipping := False;
        end;
        SliceLen := RegionSize - RegionBase;
        if SliceLen > 64 * 1024 * 1024 then
          SliceLen := 64 * 1024 * 1024;
        ScanBufferForLineFeeds(@PByteArray(P)[RegionBase], SliceLen,
          AbsOffset + Int64(RegionBase), FSink, FTermByte);
        Inc(RegionBase, SliceLen);
        if Assigned(FProgress) then
          FProgress.Add(SliceLen);
      end;
      AbsOffset := AbsOffset + Int64(Contiguous);
    end;
  finally
    MMF.Free;
  end;
end;

procedure TIndexScanWorker.Execute;
begin
  try
    ScanChunk;
  except
    on E: Exception do
      FErrorMsg := E.Message;
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

function MergeDeltaSink(ASink: TRamDeltaLineFeedSink; var ALineCount: Int64;
  var AHitLineLimit: Boolean; const AWriters: TLineIndexWriterBundle): Boolean;
var
  NextLineStart: Int64;
  D: Cardinal;
  Remain: Int64;
begin
  Result := False;
  if (ASink = nil) or (ASink.LineCount <= 0) then
  begin
    Result := True;
    Exit;
  end;
  ASink.Stream.Position := 0;
  if ASink.Stream.Read(NextLineStart, SizeOf(Int64)) <> SizeOf(Int64) then Exit;
  Remain := ASink.LineCount;
  while Remain > 0 do
  begin
    Inc(ALineCount);
    if ALineCount >= LINE_INDEX_LINE_LIMIT then
    begin
      AHitLineLimit := True;
      Result := True;
      Exit;
    end;
    if AWriters.SparseCkptOnly then
    begin
      if (ALineCount and (CKPT_INTERVAL - 1)) = 0 then
        AWriters.CkptW.WriteOffsetDirect(NextLineStart);
    end
    else
    begin
      if AWriters.IdxW <> nil then
        AWriters.IdxW.WriteOffsetDirect(NextLineStart);
      if AWriters.BlkW <> nil then
        AWriters.BlkW.NoteLineStart1Based(NextLineStart, NextLineStart - 2);
      if (ALineCount and (CKPT_INTERVAL - 1)) = 0 then
        AWriters.CkptW.WriteOffsetDirect(NextLineStart);
    end;
    Dec(Remain);
    if Remain <= 0 then Break;
    if ASink.Stream.Read(D, SizeOf(Cardinal)) <> SizeOf(Cardinal) then Exit;
    if D = $FFFFFFFF then
    begin
      if ASink.Stream.Read(NextLineStart, SizeOf(Int64)) <> SizeOf(Int64) then Exit;
    end
    else
      Inc(NextLineStart, D);
  end;
  Result := True;
end;

function TryParallelLineIndexScan(const AFileName: string; const AFileSize: Int64;
  var ALineCount: Int64; var AHitLineLimit: Boolean;
  const AWriters: TLineIndexWriterBundle;
  const AShouldStop: TIndexScanShouldStopEvent; const AOnProgress: TIndexScanProgressEvent;
  const ATermByte: Byte): Boolean;
var
  WorkerCount, I, DoneCount: Integer;
  ChunkSize: Int64;
  Workers: array of TIndexScanWorker;
  Progress: TIndexScanProgress;
  LastProgressTick: Cardinal;
  ChunkStart, ChunkEnd: Int64;
begin
  Result := False;
  {$IFNDEF WIN64}
  Exit;
  {$ENDIF}
  if not LINE_INDEX_PARALLEL_ENABLED then
    Exit;
  if not AWriters.SparseCkptOnly then
    Exit;
  if AFileSize < LINE_INDEX_PARALLEL_MIN_BYTES then
    Exit;
  if not Assigned(AWriters.CkptW) then
    Exit;
  if FilePathIncursSeekPenalty(AFileName) then
    Exit;

  WorkerCount := LineIndexScanWorkerCount;
  if WorkerCount < 2 then
    Exit;

  ChunkSize := AFileSize div WorkerCount;
  if ChunkSize < 16 * 1024 * 1024 then
  begin
    WorkerCount := Integer(AFileSize div (16 * 1024 * 1024));
    if WorkerCount < 2 then
      Exit;
    ChunkSize := AFileSize div WorkerCount;
  end;

  SetLength(Workers, WorkerCount);
  Progress := TIndexScanProgress.Create;
  LastProgressTick := GetTickCount;

  try
    for I := 0 to WorkerCount - 1 do
    begin
      ChunkStart := I * ChunkSize;
      if I = WorkerCount - 1 then
        ChunkEnd := AFileSize
      else
        ChunkEnd := ChunkStart + ChunkSize;
      Workers[I] := TIndexScanWorker.Create(AFileName, ChunkStart, ChunkEnd,
        I > 0, Progress, AShouldStop, ATermByte);
      Workers[I].Start;
    end;

    while True do
    begin
      if Assigned(AShouldStop) and AShouldStop then
        Break;
      DoneCount := 0;
      for I := 0 to WorkerCount - 1 do
        if Workers[I].Finished then
          Inc(DoneCount);
      if DoneCount >= WorkerCount then
        Break;
      if Assigned(AOnProgress) and (GetTickCount - LastProgressTick >= 150) then
      begin
        AOnProgress(Progress.GetBytes);
        LastProgressTick := GetTickCount;
      end;
      Sleep(10);
    end;

    for I := 0 to WorkerCount - 1 do
    begin
      Workers[I].WaitFor;
      if Workers[I].ErrorMsg <> '' then
        Exit;
      if Workers[I].Sink.TooBig then
        Exit;
      if Workers[I].Sink.HitLimit then
        AHitLineLimit := True;
    end;

    if Assigned(AShouldStop) and AShouldStop then
      Exit;

    for I := 0 to WorkerCount - 1 do
      if not MergeDeltaSink(Workers[I].Sink, ALineCount, AHitLineLimit, AWriters) then
        Exit;

    if Assigned(AOnProgress) then
      AOnProgress(AFileSize);
    Result := True;
  finally
    for I := 0 to WorkerCount - 1 do
      Workers[I].Free;
    Progress.Free;
  end;
end;

end.

