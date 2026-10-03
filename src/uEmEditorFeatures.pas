unit uEmEditorFeatures;

{
  EmEditor-inspired tools: Character Code Value, Extract Frequent Strings,
  Delete Duplicate Lines. Streaming via MMF + external sort for GB-scale files.
}

interface

uses
  Classes, SysUtils;

type
  TFrequentStringsMode = (fsmLines, fsmWords, fsmCsvCells);
  TDedupKeyMode = (dkmWholeLine, dkmCsvColumn);

procedure ShowCharacterCodeValueDialog(AOwner: TComponent;
  const ALine1Based: Int64; const ALineText: string;
  const ALineByteOffset1: Int64; const AInitialCharIndex1: Integer;
  const ASourcePath, ADisplayEncoding: string);

function RunExtractFrequentStringsDialog(AOwner: TComponent;
  const ASourcePath: string; const ACsvMode: Boolean;
  const ACsvDelimiter: Char; const ACsvColumnCount: Integer): Boolean;

function RunDeleteDuplicateLinesDialog(AOwner: TComponent;
  const ASourcePath: string; const ACsvMode: Boolean;
  const ACsvDelimiter: Char; const ACsvColumnCount: Integer): Boolean;

implementation

uses
  Windows, Forms, Controls, StdCtrls, ExtCtrls, Dialogs, ComCtrls, Math,
  uI18n, uMMF, uSmoothLoading, UnBufferedTextWriter, UnUtils, uFastFilePaths, UnConsts,
  uTextEncoding, uDiskSpaceCheck, uEolPolicy, MainUnit;

function EmNewFastFileTemp(const Tag: string): string; forward;
function AnsiTrim(const S: AnsiString): AnsiString; forward;
function ExtractCsvFieldAnsi(const ALine: AnsiString; const ADelim: AnsiChar;
  AColumn1Based: Integer): AnsiString; forward;
function ExtractNextCsvFieldAnsi(const ALine: AnsiString; const ADelim: AnsiChar;
  var APos: Integer): AnsiString; forward;

const
  SCAN_BUF_SIZE = 8 * 1024 * 1024;
  CHUNK_BYTE_LIMIT = 48 * 1024 * 1024;
  MAX_STATS_LINE = 2 * 1024 * 1024;
  MERGE_IO_BUF = 256 * 1024;
  FREQ_BUCKET_COUNT = 4096;
  FREQ_BUCKET_MEM_LIMIT = 8 * 1024 * 1024;
  { Ficheiros maiores usam buckets + spill (adequado a dezenas de GB). }
  FREQ_INMEM_FILE_LIMIT = 8 * 1024 * 1024;
  LINE_READ_BUF = 256 * 1024;
  DISKKEY_SLOT_COUNT = 32768;
  PROGRESS_INTERVAL_MS = 120;
  PROGRESS_MIN_ELAPSED_MS = 1500;
  PROGRESS_MIN_BYTES_FOR_ETA = 8 * 1024 * 1024;

type
  TAnsiLineCallback = procedure(const ALine: AnsiString);

  TBucketFreq = class
  private
    FKeys: TStringList;
    FSpillPath: string;
    FSpill: TFileStream;
    FMemBytes: Int64;
    procedure FlushMemToSpill;
    procedure MergeSpillCounts;
    procedure LoadSpillIntoKeys;
    procedure IncKey(const Key: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddAnsiKey(const Key: AnsiString);
    function WriteCounts(W: TBufferedTextWriter; AMinCount: Integer): Int64;
  end;

  TDiskKeySet = class
  private
    FTablePath, FDataPath: string;
    FTable, FData: TFileStream;
    function EnsureOpen: Boolean;
    function ReadTableSlot(SlotIdx: Integer): Int64;
    procedure WriteTableSlot(SlotIdx: Integer; HeadOff: Int64);
    function ReadKeyRecord(Offset: Int64; out Len: Integer; out NextOff: Int64;
      out Key: AnsiString): Boolean;
    procedure WriteKeyRecord(const Key: AnsiString; out WrittenOff: Int64);
    procedure LinkNext(RecordOff, NextOff: Int64);
  public
    constructor Create(AIndex: Integer);
    destructor Destroy; override;
    function IsFirstSeen(const Key: AnsiString): Boolean;
  end;

  TSeenKeyCollector = class
  private
    FSets: array[0..FREQ_BUCKET_COUNT - 1] of TDiskKeySet;
    function GetSet(AHash: Cardinal): TDiskKeySet;
  public
    constructor Create;
    destructor Destroy; override;
    function IsFirstSeen(const Key: AnsiString): Boolean;
  end;

  TBucketFreqCollector = class
  private
    FBuckets: array[0..FREQ_BUCKET_COUNT - 1] of TBucketFreq;
    function GetBucket(AHash: Cardinal): TBucketFreq;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddAnsiKey(const Key: AnsiString);
    function WriteOutput(const AOutPath: string; AMinCount: Integer): Int64;
  end;

  TBufferedAnsiLineReader = class
  private
    FStream: TFileStream;
    FBuf: PAnsiChar;
    FBufSize, FBufPos, FBufLen: Integer;
    FEOF: Boolean;
    function Refill: Boolean;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
    function ReadLine(var ALine: AnsiString): Boolean;
  end;

  TLineChunkCollector = class
  private
    FPartPaths: TStringList;
    FChunk: TStringList;
    FChunkBytes: Int64;
    FWorkDir: string;
    FPartIndex: Integer;
    function MakePartPath: string;
    procedure FlushChunk;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddKey(const AKey: AnsiString);
    function PartCount: Integer;
    property PartPaths: TStringList read FPartPaths;
  end;

function Fnv1aAnsi(const S: AnsiString): Cardinal;
var
  I, L: Integer;
  H: Cardinal;
begin
  H := 2166136261;
  L := Length(S);
  for I := 1 to L do
  begin
    H := H xor Byte(S[I]);
    H := H * 16777619;
  end;
  Result := H;
end;

var
  G_ProgressStartTick: DWORD;
  G_ProgressLastTick: DWORD;
  G_ProgressFileSize: Int64;
  G_ProgressWriteStartTick: DWORD;
  G_ProgressWriteLastTick: DWORD;

procedure ResetEmEditorProgress(AFileSize: Int64);
begin
  G_ProgressStartTick := GetTickCount;
  G_ProgressLastTick := G_ProgressStartTick;
  G_ProgressFileSize := AFileSize;
  G_ProgressWriteStartTick := 0;
  G_ProgressWriteLastTick := 0;
end;

procedure ResetEmEditorWriteProgress;
begin
  G_ProgressWriteStartTick := GetTickCount;
  G_ProgressWriteLastTick := G_ProgressWriteStartTick;
end;

function FormatEtaSeconds(ASec: Int64): string;
var
  H, M, S: Integer;
begin
  if ASec < 0 then
    ASec := 0;
  H := ASec div 3600;
  M := (ASec mod 3600) div 60;
  S := ASec mod 60;
  if H > 0 then
    Result := Format('%.2d:%.2d:%.2d', [H, M, S])
  else
    Result := Format('%.2d:%.2d', [M, S]);
end;

function CalcScanSpeedMBps(CurPos: Int64): Double;
var
  ElapsedMs: DWORD;
begin
  Result := 0;
  ElapsedMs := GetTickCount - G_ProgressStartTick;
  if (ElapsedMs < 400) or (CurPos <= 0) then
    Exit;
  Result := (CurPos / (1024 * 1024)) / (ElapsedMs / 1000);
end;

function CalcScanEtaText(CurPos, FileSize: Int64): string;
var
  ElapsedMs: DWORD;
  SpeedBps, RemainSec: Double;
begin
  Result := TrText('EmEditor.Progress.EtaCalc');
  if (FileSize <= 0) or (CurPos >= FileSize) then
  begin
    Result := TrText('EmEditor.Progress.EtaSoon');
    Exit;
  end;
  ElapsedMs := GetTickCount - G_ProgressStartTick;
  if (ElapsedMs < PROGRESS_MIN_ELAPSED_MS) or
    (CurPos < PROGRESS_MIN_BYTES_FOR_ETA) then
    Exit;
  SpeedBps := CurPos / (ElapsedMs / 1000);
  if SpeedBps <= 0 then
    Exit;
  RemainSec := (FileSize - CurPos) / SpeedBps;
  if RemainSec >= 86400 then
    Result := TrText('EmEditor.Progress.EtaLong')
  else
    Result := FormatEtaSeconds(Round(RemainSec));
end;

function FormatStatProgressDetail(CurPos, FileSize: Int64; const APhaseResId: string): string;
var
  CurGB, TotGB, Speed: Double;
begin
  if FileSize <= 0 then
    TotGB := 0
  else
    TotGB := FileSize / (1024 * 1024 * 1024);
  CurGB := CurPos / (1024 * 1024 * 1024);
  Speed := CalcScanSpeedMBps(CurPos);
  Result := Format(TrText('EmEditor.Progress.ScanDetail'),
    [TrText(APhaseResId), CurGB, TotGB, Speed, CalcScanEtaText(CurPos, FileSize)]);
end;

function CalcWriteEtaText(Done, Active: Integer): string;
var
  ElapsedMs: DWORD;
  Rate, RemainSec: Double;
begin
  Result := TrText('EmEditor.Progress.EtaCalc');
  if Active <= 0 then
    Exit;
  if Done >= Active then
  begin
    Result := TrText('EmEditor.Progress.EtaSoon');
    Exit;
  end;
  if G_ProgressWriteStartTick = 0 then
    Exit;
  ElapsedMs := GetTickCount - G_ProgressWriteStartTick;
  if (ElapsedMs < PROGRESS_MIN_ELAPSED_MS) or (Done < 1) then
    Exit;
  Rate := Done / (ElapsedMs / 1000);
  if Rate <= 0 then
    Exit;
  RemainSec := (Active - Done) / Rate;
  if RemainSec >= 86400 then
    Result := TrText('EmEditor.Progress.EtaLong')
  else
    Result := FormatEtaSeconds(Round(RemainSec));
end;

procedure PostWriteProgress(Done, Active: Integer);
var
  T, Pct: DWORD;
begin
  if Active <= 0 then
    Active := 1;
  if G_ProgressWriteStartTick = 0 then
    ResetEmEditorWriteProgress;
  T := GetTickCount;
  if (Done < Active) and (T - G_ProgressWriteLastTick < PROGRESS_INTERVAL_MS) then
    Exit;
  G_ProgressWriteLastTick := T;
  Pct := 90 + DWORD((Done * 9) div Active);
  if Pct > 99 then
    Pct := 99;
  TfrmSmoothLoading.PostProgressWithDetailFromWorker(Pct,
    Format(TrText('EmEditor.Progress.WriteDetail'),
      [TrText('EmEditor.Progress.Writing'), Done, Active, CalcWriteEtaText(Done, Active)]));
end;

function KeyCountFromObj(AObj: TObject): Integer;
begin
  Result := Integer(AObj);
  if Result < 1 then
    Result := 0;
end;

procedure KeyCountInc(Keys: TStringList; const Key: string);
var
  Idx: Integer;
begin
  if Key = '' then Exit;
  Idx := Keys.IndexOf(Key);
  if Idx >= 0 then
    Keys.Objects[Idx] := TObject(KeyCountFromObj(Keys.Objects[Idx]) + 1)
  else
    Keys.AddObject(Key, TObject(1));
end;

procedure PostScanProgress(CurPos, FileSize: Int64; const APhaseResId: string);
var
  T: DWORD;
  Pct: Integer;
begin
  T := GetTickCount;
  if (CurPos < FileSize) and (T - G_ProgressLastTick < PROGRESS_INTERVAL_MS) then Exit;
  G_ProgressLastTick := T;
  if FileSize <= 0 then
    Pct := 0
  else
    Pct := Integer((CurPos * 88) div FileSize);
  if Pct > 88 then Pct := 88;
  TfrmSmoothLoading.PostProgressWithDetailFromWorker(Pct,
    FormatStatProgressDetail(CurPos, FileSize, APhaseResId));
end;

{ --- Disk hash set (dedup, GB-scale) ---------------------------------------- }

constructor TDiskKeySet.Create(AIndex: Integer);
var
  Z: Int64;
  N: Integer;
begin
  inherited Create;
  FTable := nil;
  FData := nil;
  FTablePath := EmNewFastFileTemp('emkt' + IntToStr(AIndex));
  FDataPath := EmNewFastFileTemp('emkd' + IntToStr(AIndex));
  UnUtils.TryDeleteFileWithRetry(FTablePath, 8, 60);
  UnUtils.TryDeleteFileWithRetry(FDataPath, 8, 60);
  FTable := TFileStream.Create(FTablePath, fmCreate);
  try
    Z := 0;
    N := DISKKEY_SLOT_COUNT * SizeOf(Int64);
    while N > 0 do
    begin
      if N > SizeOf(Z) then
      begin
        FTable.WriteBuffer(Z, SizeOf(Z));
        Dec(N, SizeOf(Z));
      end
      else
      begin
        FTable.WriteBuffer(Z, N);
        N := 0;
      end;
    end;
  finally
    FreeAndNil(FTable);
  end;
  FData := TFileStream.Create(FDataPath, fmCreate);
end;

destructor TDiskKeySet.Destroy;
begin
  FreeAndNil(FTable);
  FreeAndNil(FData);
  if FTablePath <> '' then
    UnUtils.TryDeleteFileWithRetry(FTablePath, 8, 60);
  if FDataPath <> '' then
    UnUtils.TryDeleteFileWithRetry(FDataPath, 8, 60);
  inherited;
end;

function TDiskKeySet.EnsureOpen: Boolean;
begin
  Result := True;
  if not Assigned(FTable) then
    FTable := TFileStream.Create(FTablePath, fmOpenReadWrite or fmShareDenyNone);
  if not Assigned(FData) then
    FData := TFileStream.Create(FDataPath, fmOpenReadWrite or fmShareDenyNone);
end;

function TDiskKeySet.ReadTableSlot(SlotIdx: Integer): Int64;
begin
  Result := 0;
  if not EnsureOpen then Exit;
  FileStreamSeek64(FTable, Int64(SlotIdx) * SizeOf(Int64), soFromBeginning);
  if FTable.Read(Result, SizeOf(Result)) <> SizeOf(Result) then
    Result := 0;
end;

procedure TDiskKeySet.WriteTableSlot(SlotIdx: Integer; HeadOff: Int64);
begin
  if not EnsureOpen then Exit;
  FileStreamSeek64(FTable, Int64(SlotIdx) * SizeOf(Int64), soFromBeginning);
  FTable.WriteBuffer(HeadOff, SizeOf(HeadOff));
end;

function TDiskKeySet.ReadKeyRecord(Offset: Int64; out Len: Integer;
  out NextOff: Int64; out Key: AnsiString): Boolean;
var
  DataSize, Need: Int64;
begin
  Result := False;
  Key := '';
  Len := 0;
  NextOff := 0;
  if not EnsureOpen then Exit;
  DataSize := UnUtils.FileStreamSize64(FData);
  if (Offset < 0) or (Offset + SizeOf(Integer) + SizeOf(Int64) > DataSize) then Exit;
  FileStreamSeek64(FData, Offset, soFromBeginning);
  if FData.Read(Len, SizeOf(Len)) <> SizeOf(Len) then Exit;
  if (Len <= 0) or (Len > MAX_STATS_LINE) then Exit;
  Need := Offset + SizeOf(Integer) + SizeOf(Int64) + Len;
  if Need > DataSize then Exit;
  if FData.Read(NextOff, SizeOf(NextOff)) <> SizeOf(NextOff) then Exit;
  SetLength(Key, Len);
  if Len > 0 then
    if FData.Read(Key[1], Len) <> Len then Exit;
  Result := True;
end;

procedure TDiskKeySet.WriteKeyRecord(const Key: AnsiString; out WrittenOff: Int64);
var
  Len: Integer;
  NextZero: Int64;
begin
  Len := Length(Key);
  NextZero := 0;
  WrittenOff := UnUtils.FileStreamSize64(FData);
  FileStreamSeek64(FData, WrittenOff, soFromBeginning);
  FData.WriteBuffer(Len, SizeOf(Len));
  FData.WriteBuffer(NextZero, SizeOf(NextZero));
  if Len > 0 then
    FData.WriteBuffer(Key[1], Len);
end;

procedure TDiskKeySet.LinkNext(RecordOff, NextOff: Int64);
begin
  FileStreamSeek64(FData, RecordOff + SizeOf(Integer), soFromBeginning);
  FData.WriteBuffer(NextOff, SizeOf(NextOff));
end;

function TDiskKeySet.IsFirstSeen(const Key: AnsiString): Boolean;
var
  H: Cardinal;
  SlotIdx: Integer;
  HeadOff, NodeOff, NextOff, NewOff, LastValidOff: Int64;
  Len: Integer;
  Stored: AnsiString;
begin
  Result := False;
  if Key = '' then Exit;
  if Length(Key) > MAX_STATS_LINE then Exit;
  if not EnsureOpen then Exit;
  H := Fnv1aAnsi(Key);
  SlotIdx := H mod DISKKEY_SLOT_COUNT;
  HeadOff := ReadTableSlot(SlotIdx);
  NodeOff := HeadOff;
  LastValidOff := -1;
  while NodeOff <> 0 do
  begin
    if not ReadKeyRecord(NodeOff, Len, NextOff, Stored) then
      Break;
    if Stored = Key then
      Exit;
    LastValidOff := NodeOff;
    NodeOff := NextOff;
  end;
  WriteKeyRecord(Key, NewOff);
  if HeadOff = 0 then
    WriteTableSlot(SlotIdx, NewOff)
  else if LastValidOff >= 0 then
    LinkNext(LastValidOff, NewOff)
  else
    WriteTableSlot(SlotIdx, NewOff);
  Result := True;
end;

{ --- Buffered line I/O ------------------------------------------------------ }

constructor TBufferedAnsiLineReader.Create(const APath: string);
begin
  inherited Create;
  FBufSize := LINE_READ_BUF;
  GetMem(FBuf, FBufSize);
  FStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  FBufPos := 0;
  FBufLen := 0;
  FEOF := False;
end;

destructor TBufferedAnsiLineReader.Destroy;
begin
  if Assigned(FStream) then FreeAndNil(FStream);
  if FBuf <> nil then FreeMem(FBuf);
  inherited;
end;

function TBufferedAnsiLineReader.Refill: Boolean;
begin
  if FEOF then
  begin
    Result := False;
    Exit;
  end;
  FBufPos := 0;
  FBufLen := FStream.Read(FBuf^, FBufSize);
  FEOF := FBufLen <= 0;
  Result := FBufLen > 0;
end;

function TBufferedAnsiLineReader.ReadLine(var ALine: AnsiString): Boolean;
var
  I, Start: Integer;
  Ch: AnsiChar;
begin
  ALine := '';
  Result := False;
  while True do
  begin
    if FBufPos >= FBufLen then
      if not Refill then Exit;
    Start := FBufPos;
    I := FBufPos;
    while I < FBufLen do
    begin
      if FBuf[I] = #10 then
      begin
        SetString(ALine, PChar(@FBuf[Start]), I - Start);
        FBufPos := I + 1;
        if (Length(ALine) > 0) and (ALine[Length(ALine)] = #13) then
          SetLength(ALine, Length(ALine) - 1);
        Result := True;
        Exit;
      end;
      Inc(I);
    end;
    if I > Start then
      ALine := ALine + Copy(string(PChar(@FBuf[Start])), 1, I - Start);
    FBufPos := I;
    if FEOF then
    begin
      if ALine <> '' then
        Result := True;
      Exit;
    end;
  end;
end;

{ --- Bucket frequency counter ----------------------------------------------- }

constructor TBucketFreq.Create;
begin
  inherited Create;
  FKeys := TStringList.Create;
  FKeys.Sorted := True;
  FKeys.Duplicates := dupError;
  FSpillPath := '';
  FSpill := nil;
  FMemBytes := 0;
end;

destructor TBucketFreq.Destroy;
begin
  if Assigned(FSpill) then FreeAndNil(FSpill);
  if (FSpillPath <> '') and FileExists(FSpillPath) then
    UnUtils.TryDeleteFileWithRetry(FSpillPath, 8, 60);
  FKeys.Free;
  inherited;
end;

procedure TBucketFreq.FlushMemToSpill;
var
  I, L, Cnt: Integer;
  Len: Integer;
  B: AnsiString;
begin
  if FKeys.Count = 0 then Exit;
  if FSpillPath = '' then
  begin
    FSpillPath := EmNewFastFileTemp('emfbkt');
    UnUtils.TryDeleteFileWithRetry(FSpillPath, 8, 60);
    FSpill := TFileStream.Create(FSpillPath, fmCreate);
  end;
  for I := 0 to FKeys.Count - 1 do
  begin
    B := AnsiString(FKeys[I]);
    L := Length(B);
    Len := L;
    Cnt := KeyCountFromObj(FKeys.Objects[I]);
    if Cnt < 1 then
      Cnt := 1;
    FSpill.WriteBuffer(Len, SizeOf(Len));
    FSpill.WriteBuffer(Cnt, SizeOf(Cnt));
    if L > 0 then
      FSpill.WriteBuffer(B[1], L);
  end;
  FKeys.Clear;
  FMemBytes := 0;
end;

procedure TBucketFreq.IncKey(const Key: string);
var
  Idx: Integer;
begin
  if Key = '' then Exit;
  Idx := FKeys.IndexOf(Key);
  if Idx >= 0 then
    FKeys.Objects[Idx] := TObject(KeyCountFromObj(FKeys.Objects[Idx]) + 1)
  else
  begin
    FKeys.AddObject(Key, TObject(1));
    Inc(FMemBytes, Length(Key) + 32);
  end;
end;

procedure TBucketFreq.AddAnsiKey(const Key: AnsiString);
begin
  if Key = '' then Exit;
  IncKey(string(Key));
  if FMemBytes >= FREQ_BUCKET_MEM_LIMIT then
    FlushMemToSpill;
end;

procedure TBucketFreq.MergeSpillCounts;
var
  Len, Cnt, Idx: Integer;
  B: AnsiString;
  S: string;
begin
  if not Assigned(FSpill) then
  begin
    if (FSpillPath = '') or (not FileExists(FSpillPath)) then Exit;
    FSpill := TFileStream.Create(FSpillPath, fmOpenRead or fmShareDenyNone);
  end
  else
    FileStreamSeek64(FSpill, 0, soFromBeginning);
  try
    while FSpill.Read(Len, SizeOf(Len)) = SizeOf(Len) do
    begin
      if (Len <= 0) or (Len > MAX_STATS_LINE) then Break;
      if FSpill.Read(Cnt, SizeOf(Cnt)) <> SizeOf(Cnt) then Break;
      if Cnt < 1 then
        Cnt := 1;
      SetLength(B, Len);
      if (Len > 0) and (FSpill.Read(B[1], Len) <> Len) then Break;
      S := string(B);
      Idx := FKeys.IndexOf(S);
      if Idx >= 0 then
        FKeys.Objects[Idx] := TObject(KeyCountFromObj(FKeys.Objects[Idx]) + Cnt)
      else
      begin
        FKeys.AddObject(S, TObject(Cnt));
        Inc(FMemBytes, Length(S) + 32);
      end;
    end;
  finally
    FreeAndNil(FSpill);
    UnUtils.TryDeleteFileWithRetry(FSpillPath, 8, 60);
    FSpillPath := '';
  end;
end;

procedure TBucketFreq.LoadSpillIntoKeys;
begin
  MergeSpillCounts;
end;

function TBucketFreq.WriteCounts(W: TBufferedTextWriter; AMinCount: Integer): Int64;
var
  I, C: Integer;
  Line: AnsiString;
begin
  Result := 0;
  if Assigned(FSpill) or (FSpillPath <> '') then
    LoadSpillIntoKeys;
  for I := 0 to FKeys.Count - 1 do
  begin
    C := KeyCountFromObj(FKeys.Objects[I]);
    if C >= AMinCount then
    begin
      Line := AnsiString(FKeys[I]) + AnsiChar(',') + AnsiString(IntToStr(C));
      W.WriteLine(Line);
      Inc(Result);
    end;
  end;
end;

destructor TBucketFreqCollector.Destroy;
var
  I: Integer;
begin
  for I := 0 to FREQ_BUCKET_COUNT - 1 do
    FreeAndNil(FBuckets[I]);
  inherited;
end;

constructor TBucketFreqCollector.Create;
var
  I: Integer;
begin
  inherited Create;
  for I := 0 to FREQ_BUCKET_COUNT - 1 do
    FBuckets[I] := nil;
end;

function TBucketFreqCollector.GetBucket(AHash: Cardinal): TBucketFreq;
begin
  Result := FBuckets[AHash mod FREQ_BUCKET_COUNT];
  if Result = nil then
  begin
    Result := TBucketFreq.Create;
    FBuckets[AHash mod FREQ_BUCKET_COUNT] := Result;
  end;
end;

procedure TBucketFreqCollector.AddAnsiKey(const Key: AnsiString);
begin
  if Key = '' then Exit;
  GetBucket(Fnv1aAnsi(Key)).AddAnsiKey(Key);
end;

function TBucketFreqCollector.WriteOutput(const AOutPath: string;
  AMinCount: Integer): Int64;
var
  W: TBufferedTextWriter;
  I, Done, Active: Integer;
begin
  Result := 0;
  Active := 0;
  for I := 0 to FREQ_BUCKET_COUNT - 1 do
    if FBuckets[I] <> nil then
      Inc(Active);
  if Active <= 0 then Active := 1;
  Done := 0;
  W := TBufferedTextWriter.Create(AOutPath, 4 * 1024 * 1024);
  try
    W.WriteLine(AnsiString(TrText('EmEditor.FreqOutputHeader')));
    for I := 0 to FREQ_BUCKET_COUNT - 1 do
      if FBuckets[I] <> nil then
      begin
        Inc(Done);
        PostWriteProgress(Done, Active);
        Inc(Result, FBuckets[I].WriteCounts(W, AMinCount));
        if TfrmSmoothLoading.CancelRequested then Break;
      end;
  finally
    W.Free;
  end;
end;

{ --- Seen keys (dedup, preserve file order) --------------------------------- }

constructor TSeenKeyCollector.Create;
var
  I: Integer;
begin
  inherited Create;
  for I := 0 to FREQ_BUCKET_COUNT - 1 do
    FSets[I] := nil;
end;

destructor TSeenKeyCollector.Destroy;
var
  I: Integer;
begin
  for I := 0 to FREQ_BUCKET_COUNT - 1 do
    FreeAndNil(FSets[I]);
  inherited;
end;

function TSeenKeyCollector.GetSet(AHash: Cardinal): TDiskKeySet;
var
  Idx: Integer;
begin
  Idx := AHash mod FREQ_BUCKET_COUNT;
  Result := FSets[Idx];
  if Result = nil then
  begin
    Result := TDiskKeySet.Create(Idx);
    FSets[Idx] := Result;
  end;
end;

function TSeenKeyCollector.IsFirstSeen(const Key: AnsiString): Boolean;
begin
  Result := GetSet(Fnv1aAnsi(Key)).IsFirstSeen(Key);
end;

type
  TDedupScanContext = record
    KeyMode: TDedupKeyMode;
    CsvDelimiter: Char;
    CsvColumn1: Integer;
    SeenMap: TStringList;
    SeenBuckets: TSeenKeyCollector;
    UseBuckets: Boolean;
    Writer: TBufferedTextWriter;
    OutCount: Int64;
  end;

  TFreqScanContext = record
    Mode: TFrequentStringsMode;
    CsvDelimiter: Char;
    CsvColumn1: Integer;
    Map: TStringList;
    Buckets: TBucketFreqCollector;
    UseBuckets: Boolean;
  end;

  PFreqScanContext = ^TFreqScanContext;
  PDedupScanContext = ^TDedupScanContext;

procedure FreqCtxAddKey(var Ctx: TFreqScanContext; const Key: AnsiString);
begin
  if Key = '' then Exit;
  if Ctx.UseBuckets then
    Ctx.Buckets.AddAnsiKey(Key)
  else
    KeyCountInc(Ctx.Map, string(Key));
end;

procedure ProcessLineForFreq(var Ctx: TFreqScanContext; const ALine: AnsiString);
var
  Key: AnsiString;
  I, L, Start: Integer;
begin
  case Ctx.Mode of
    fsmLines:
      FreqCtxAddKey(Ctx, ALine);
    fsmWords:
      begin
        L := Length(ALine);
        I := 1;
        while I <= L do
        begin
          while (I <= L) and (ALine[I] <= ' ') do Inc(I);
          if I > L then Break;
          Start := I;
          while (I <= L) and (ALine[I] > ' ') do Inc(I);
          SetString(Key, PChar(@ALine[Start]), I - Start);
          FreqCtxAddKey(Ctx, Key);
        end;
      end;
    fsmCsvCells:
      begin
        I := 1;
        while I <= Length(ALine) do
        begin
          Key := ExtractNextCsvFieldAnsi(ALine, AnsiChar(Ctx.CsvDelimiter), I);
          if Key <> '' then
            FreqCtxAddKey(Ctx, AnsiTrim(Key));
        end;
      end;
  end;
end;

var
  G_FreqScanCtx: PFreqScanContext;
  G_DedupScanCtx: PDedupScanContext;

procedure ScanLineHandlerFreq(const ALine: AnsiString);
begin
  if G_FreqScanCtx <> nil then
    ProcessLineForFreq(G_FreqScanCtx^, ALine);
end;

function DedupIsFirstSeen(var Ctx: TDedupScanContext; const Key: AnsiString): Boolean;
var
  S: string;
begin
  Result := False;
  if Key = '' then Exit;
  if Ctx.UseBuckets then
    Result := Ctx.SeenBuckets.IsFirstSeen(Key)
  else
  begin
    S := string(Key);
    if Ctx.SeenMap.IndexOf(S) >= 0 then
      Exit;
    Ctx.SeenMap.Add(S);
    Result := True;
  end;
end;

procedure ProcessLineForDedup(var Ctx: TDedupScanContext; const ALine: AnsiString);
var
  Key: AnsiString;
begin
  if Ctx.KeyMode = dkmCsvColumn then
    Key := ExtractCsvFieldAnsi(ALine, AnsiChar(Ctx.CsvDelimiter), Ctx.CsvColumn1)
  else
    Key := ALine;
  if DedupIsFirstSeen(Ctx, Key) then
  begin
    Ctx.Writer.WriteLine(ALine);
    Inc(Ctx.OutCount);
  end;
end;

procedure ScanLineHandlerDedup(const ALine: AnsiString);
begin
  if G_DedupScanCtx <> nil then
    ProcessLineForDedup(G_DedupScanCtx^, ALine);
end;

procedure ScanFileLinesMMF(const ASourcePath: string; AOnLine: TAnsiLineCallback);
var
  MMF: TMMFReader;
  FileSize, CurPos: Int64;
  Buf: AnsiString;
  BytesRead, I, LineLen, Cap: Integer;
  LineBuf: array of AnsiChar;
  TermCh: AnsiChar;

  procedure AppendLineChar(const C: AnsiChar);
  begin
    if LineLen >= Cap then
    begin
      Cap := Cap + 65536;
      SetLength(LineBuf, Cap);
    end;
    LineBuf[LineLen] := C;
    Inc(LineLen);
  end;

  procedure FlushLineAcc;
  var
    L: AnsiString;
  begin
    if LineLen <= 0 then Exit;
    SetString(L, PChar(@LineBuf[0]), LineLen);
    while (Length(L) > 0) and (L[Length(L)] in [#13]) do
      SetLength(L, Length(L) - 1);
    AOnLine(L);
    LineLen := 0;
  end;

begin
  TermCh := LineTermCharForFile(ASourcePath);
  MMF := TMMFReader.Create(ASourcePath);
  try
    FileSize := MMF.FileSize;
    CurPos := 0;
    LineLen := 0;
    Cap := 65536;
    SetLength(LineBuf, Cap);
    ResetEmEditorProgress(FileSize);
    SetLength(Buf, SCAN_BUF_SIZE);
    while (CurPos < FileSize) and (not TfrmSmoothLoading.CancelRequested) do
    begin
      BytesRead := Integer(MMF.ReadBytes(CurPos, Buf[1], SCAN_BUF_SIZE));
      if BytesRead <= 0 then Break;
      for I := 1 to BytesRead do
      begin
        if Buf[I] = TermCh then
          FlushLineAcc
        else if LineLen < MAX_STATS_LINE then
          AppendLineChar(Buf[I]);
      end;
      Inc(CurPos, BytesRead);
      PostScanProgress(CurPos, FileSize, 'EmEditor.Progress.Scanning');
    end;
    PostScanProgress(FileSize, FileSize, 'EmEditor.Progress.Scanning');
    if LineLen > 0 then
      FlushLineAcc;
  finally
    MMF.Free;
  end;
end;

function RunDeleteDuplicateLines(const ASourcePath, ATempOutPath: string;
  AKeyMode: TDedupKeyMode; ACsvDelimiter: Char; ACsvColumn1: Integer): Int64;
var
  Ctx: TDedupScanContext;
  FileSize: Int64;
begin
  Result := 0;
  FileSize := UnUtils.GetFileSize(ASourcePath);
  FillChar(Ctx, SizeOf(Ctx), 0);
  Ctx.KeyMode := AKeyMode;
  Ctx.CsvDelimiter := ACsvDelimiter;
  Ctx.CsvColumn1 := ACsvColumn1;
  Ctx.UseBuckets := FileSize > FREQ_INMEM_FILE_LIMIT;
  Ctx.Writer := TBufferedTextWriter.Create(ATempOutPath, 4 * 1024 * 1024);
  Ctx.Writer.LineBreak := OutputEolForFile(ASourcePath);
  try
    if Ctx.UseBuckets then
      Ctx.SeenBuckets := TSeenKeyCollector.Create
    else
    begin
      Ctx.SeenMap := TStringList.Create;
      Ctx.SeenMap.Sorted := True;
    end;
    try
      G_DedupScanCtx := @Ctx;
      try
        ScanFileLinesMMF(ASourcePath, ScanLineHandlerDedup);
      finally
        G_DedupScanCtx := nil;
      end;
      Result := Ctx.OutCount;
      TfrmSmoothLoading.PostProgressWithDetailFromWorker(89,
        TrText('EmEditor.Progress.Writing'));
    finally
      if Ctx.UseBuckets then
        FreeAndNil(Ctx.SeenBuckets)
      else
        FreeAndNil(Ctx.SeenMap);
    end;
  finally
    Ctx.Writer.Free;
  end;
end;

procedure ScanFileForFreq(const ASourcePath: string; var Ctx: TFreqScanContext);
begin
  G_FreqScanCtx := @Ctx;
  try
    ScanFileLinesMMF(ASourcePath, ScanLineHandlerFreq);
  finally
    G_FreqScanCtx := nil;
  end;
end;

function WriteInMemFreqOutput(const AMap: TStringList; const AOutPath: string;
  AMinCount: Integer): Int64;
var
  W: TBufferedTextWriter;
  I, C: Integer;
  Line: AnsiString;
begin
  Result := 0;
  W := TBufferedTextWriter.Create(AOutPath, 4 * 1024 * 1024);
  try
    W.WriteLine(AnsiString(TrText('EmEditor.FreqOutputHeader')));
    for I := 0 to AMap.Count - 1 do
    begin
      C := KeyCountFromObj(AMap.Objects[I]);
      if C >= AMinCount then
      begin
        Line := AnsiString(AMap[I]) + AnsiChar(',') + AnsiString(IntToStr(C));
        W.WriteLine(Line);
        Inc(Result);
      end;
    end;
  finally
    W.Free;
  end;
end;

function RunExtractFrequentStrings(const ASourcePath, AOutputPath: string;
  AMode: TFrequentStringsMode; ACsvDelimiter: Char; ACsvColumn1, AMinCount: Integer): Int64;
var
  Ctx: TFreqScanContext;
  FileSize: Int64;
begin
  Result := 0;
  FileSize := UnUtils.GetFileSize(ASourcePath);
  FillChar(Ctx, SizeOf(Ctx), 0);
  Ctx.Mode := AMode;
  Ctx.CsvDelimiter := ACsvDelimiter;
  Ctx.CsvColumn1 := ACsvColumn1;
  Ctx.UseBuckets := FileSize > FREQ_INMEM_FILE_LIMIT;
  if Ctx.UseBuckets then
    Ctx.Buckets := TBucketFreqCollector.Create
  else
  begin
    Ctx.Map := TStringList.Create;
    Ctx.Map.Sorted := True;
    Ctx.Map.Duplicates := dupError;
  end;
  try
    ScanFileForFreq(ASourcePath, Ctx);
    if TfrmSmoothLoading.CancelRequested then Exit;
    ResetEmEditorWriteProgress;
    TfrmSmoothLoading.PostProgressWithDetailFromWorker(89,
      TrText('EmEditor.Progress.Writing'));
    if Ctx.UseBuckets then
      Result := Ctx.Buckets.WriteOutput(AOutputPath, AMinCount)
    else
      Result := WriteInMemFreqOutput(Ctx.Map, AOutputPath, AMinCount);
    if not TfrmSmoothLoading.CancelRequested then
      TfrmSmoothLoading.PostProgressFromWorker(100);
  finally
    if Ctx.UseBuckets then
      FreeAndNil(Ctx.Buckets)
    else
      FreeAndNil(Ctx.Map);
  end;
end;

{ --- Chunk collector (dedup / fallback) ------------------------------------- }

function EmNewFastFileTemp(const Tag: string): string;
begin
  Result := FastFileScratchTempPath(Tag);
end;

function AnsiTrim(const S: AnsiString): AnsiString;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  while (L >= I) and (S[L] <= ' ') do Dec(L);
  if L >= I then
    SetString(Result, PChar(@S[I]), L - I + 1)
  else
    Result := '';
end;

function ExtractCsvFieldAnsi(const ALine: AnsiString; const ADelim: AnsiChar;
  AColumn1Based: Integer): AnsiString;
var
  I, Col, L: Integer;
  InQuote: Boolean;
  Cur: AnsiString;
begin
  Result := '';
  if AColumn1Based < 1 then Exit;
  Col := 1;
  Cur := '';
  InQuote := False;
  L := Length(ALine);
  I := 1;
  while I <= L do
  begin
    if InQuote then
    begin
      if ALine[I] = '"' then
      begin
        if (I < L) and (ALine[I + 1] = '"') then
        begin
          Cur := Cur + '"';
          Inc(I, 2);
          Continue;
        end;
        InQuote := False;
      end
      else
        Cur := Cur + ALine[I];
    end
    else
    begin
      if ALine[I] = '"' then
        InQuote := True
      else if ALine[I] = ADelim then
      begin
        if Col = AColumn1Based then
        begin
          Result := Cur;
          Exit;
        end;
        Cur := '';
        Inc(Col);
      end
      else
        Cur := Cur + ALine[I];
    end;
    Inc(I);
  end;
  if Col = AColumn1Based then
    Result := Cur;
end;

function ExtractNextCsvFieldAnsi(const ALine: AnsiString; const ADelim: AnsiChar;
  var APos: Integer): AnsiString;
var
  I, L: Integer;
  InQuote: Boolean;
  Cur: AnsiString;
begin
  Result := '';
  L := Length(ALine);
  if APos < 1 then
    APos := 1;
  if APos > L then
  begin
    APos := L + 1;
    Exit;
  end;
  Cur := '';
  InQuote := False;
  I := APos;
  while I <= L do
  begin
    if InQuote then
    begin
      if ALine[I] = '"' then
      begin
        if (I < L) and (ALine[I + 1] = '"') then
        begin
          Cur := Cur + '"';
          Inc(I, 2);
          Continue;
        end;
        InQuote := False;
      end
      else
        Cur := Cur + ALine[I];
    end
    else
    begin
      if ALine[I] = '"' then
        InQuote := True
      else if ALine[I] = ADelim then
      begin
        Result := Cur;
        APos := I + 1;
        Exit;
      end
      else
        Cur := Cur + ALine[I];
    end;
    Inc(I);
  end;
  Result := Cur;
  APos := L + 1;
end;

function GeneralCategoryName(const W: WideChar): string;
var
  C: Word;
begin
  C := Word(W);
  if C = 0 then Result := TrText('CharCode.Category.Null')
  else if (C >= $30) and (C <= $39) then Result := TrText('CharCode.Category.Number')
  else if ((C >= $41) and (C <= $5A)) or ((C >= $61) and (C <= $7A)) then
    Result := TrText('CharCode.Category.Letter')
  else if (C >= $3400) and (C <= $4DBF) then Result := TrText('CharCode.Category.Ideograph')
  else if (C = $09) or (C = $0A) or (C = $0D) or (C = $20) then
    Result := TrText('CharCode.Category.Separator')
  else if (C < $20) or (C = $7F) then Result := TrText('CharCode.Category.Control')
  else Result := TrText('CharCode.Category.Other');
end;

function Utf8CharAt(const S: AnsiString; ACharIndex1: Integer;
  out ACharUtf8: AnsiString; out ACodePoint: Cardinal; out ACharByteLen: Integer): Boolean;
var
  I, L, Need: Integer;
  B0: Byte;
begin
  Result := False;
  ACharUtf8 := '';
  ACodePoint := 0;
  ACharByteLen := 0;
  if ACharIndex1 < 1 then Exit;
  L := Length(S);
  I := 1;
  while (I <= L) and (ACharIndex1 > 1) do
  begin
    B0 := Byte(S[I]);
    if B0 < $80 then Need := 1
    else if (B0 and $E0) = $C0 then Need := 2
    else if (B0 and $F0) = $E0 then Need := 3
    else if (B0 and $F8) = $F0 then Need := 4
    else Need := 1;
    if I + Need - 1 > L then Need := 1;
    Inc(I, Need);
    Dec(ACharIndex1);
  end;
  if I > L then Exit;
  B0 := Byte(S[I]);
  if B0 < $80 then
  begin
    Need := 1;
    ACodePoint := B0;
  end
  else if (B0 and $E0) = $C0 then
  begin
    Need := 2;
    if I + 1 <= L then
      ACodePoint := ((B0 and $1F) shl 6) or (Byte(S[I + 1]) and $3F)
    else
      ACodePoint := B0;
  end
  else if (B0 and $F0) = $E0 then
  begin
    Need := 3;
    if I + 2 <= L then
      ACodePoint := ((B0 and $0F) shl 12) or ((Byte(S[I + 1]) and $3F) shl 6) or
        (Byte(S[I + 2]) and $3F)
    else
      ACodePoint := B0;
  end
  else if (B0 and $F8) = $F0 then
  begin
    Need := 4;
    if I + 3 <= L then
      ACodePoint := ((B0 and $07) shl 18) or ((Byte(S[I + 1]) and $3F) shl 12) or
        ((Byte(S[I + 2]) and $3F) shl 6) or (Byte(S[I + 3]) and $3F)
    else
      ACodePoint := B0;
  end
  else
  begin
    Need := 1;
    ACodePoint := B0;
  end;
  if I + Need - 1 > L then Need := L - I + 1;
  SetString(ACharUtf8, PChar(@S[I]), Need);
  ACharByteLen := Need;
  Result := True;
end;

function BytesToHexSpaced(const Buf: AnsiString): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Buf) do
  begin
    if Result <> '' then Result := Result + ' ';
    Result := Result + IntToHex(Byte(Buf[I]), 2);
  end;
end;

function ReadRawLineBytesAtOffset(const ASourcePath: string;
  const ALineByteOffset1, ACharIndex1: Integer; out ALineRaw: AnsiString): Boolean;
var
  FS: TFileStream;
  FileSize, Pos0, End0, ReadN: Int64;
  Buf: array of Byte;
  I: Integer;
  TermB: Byte;
begin
  Result := False;
  ALineRaw := '';
  if not FileExists(ASourcePath) then Exit;
  FS := TFileStream.Create(ASourcePath, fmOpenRead or fmShareDenyNone);
  try
    FileSize := FS.Size;
    if ALineByteOffset1 < 1 then Exit;
    Pos0 := ALineByteOffset1 - 1;
    if Pos0 >= FileSize then Exit;
    SetLength(Buf, Max(4096, Min(Int64(MAX_STATS_LINE), FileSize - Pos0)));
    FileStreamSeek64(FS, Pos0, soFromBeginning);
    ReadN := FS.Read(Buf[0], Length(Buf));
    if ReadN <= 0 then Exit;
    End0 := ReadN;
    TermB := LineTermByteForFile(ASourcePath);
    for I := 0 to ReadN - 1 do
      if Buf[I] = TermB then
      begin
        End0 := I;
        Break;
      end;
    SetString(ALineRaw, PChar(@Buf[0]), End0);
    while (Length(ALineRaw) > 0) and (ALineRaw[Length(ALineRaw)] in [#10, #13]) do
      SetLength(ALineRaw, Length(ALineRaw) - 1);
    Result := True;
  finally
    FS.Free;
  end;
end;

type
  TCharacterCodeForm = class(TForm)
  private
    EdCharIdx: TEdit;
    Memo: TMemo;
    FLine1Based: Int64;
    FLineByteOffset1: Int64;
    FLineRaw: AnsiString;
    procedure EdCharIdxChange(Sender: TObject);
    procedure RefreshInfo;
  end;

procedure TCharacterCodeForm.EdCharIdxChange(Sender: TObject);
begin
  RefreshInfo;
end;

procedure TCharacterCodeForm.RefreshInfo;
var
  CharIdx, CharByteLen, I, BytePosInLine: Integer;
  CharUtf8: AnsiString;
  CodePoint: Cardinal;
  W: WideString;
  DisplayChar, Info: string;
  CharByteOffset1: Int64;
begin
  CharIdx := StrToIntDef(Trim(EdCharIdx.Text), 1);
  if CharIdx < 1 then CharIdx := 1;
  if not Utf8CharAt(FLineRaw, CharIdx, CharUtf8, CodePoint, CharByteLen) then
  begin
    Memo.Lines.Text := TrText('CharCode.InvalidIndex');
    Exit;
  end;
  BytePosInLine := 0;
  I := 1;
  while I < CharIdx do
  begin
    if not Utf8CharAt(FLineRaw, I, CharUtf8, CodePoint, CharByteLen) then Break;
    Inc(BytePosInLine, CharByteLen);
    Inc(I);
  end;
  CharByteOffset1 := FLineByteOffset1 + BytePosInLine;
  if Length(CharUtf8) = 1 then
    DisplayChar := string(CharUtf8)
  else
  begin
    W := Utf8AnsiToWideString(CharUtf8);
    DisplayChar := string(W);
  end;
  if DisplayChar = '' then
    DisplayChar := TrText('CharCode.NonPrintable');
  Info :=
    Format(TrText('CharCode.Line'), [FLine1Based]) + #13#10 +
    Format(TrText('CharCode.CharIndex'), [CharIdx]) + #13#10 +
    Format(TrText('CharCode.DisplayChar'), [DisplayChar]) + #13#10 +
    Format(TrText('CharCode.CodePoint'), [CodePoint]) + #13#10 +
    Format(TrText('CharCode.Decimal'), [CodePoint]) + #13#10 +
    Format(TrText('CharCode.Utf8Bytes'), [BytesToHexSpaced(CharUtf8)]) + #13#10 +
    Format(TrText('CharCode.ByteOffset'), [CharByteOffset1]) + #13#10 +
    Format(TrText('CharCode.Category'), [GeneralCategoryName(WideChar(CodePoint))]) + #13#10 +
    Format(TrText('CharCode.LineByteOffset'), [FLineByteOffset1]);
  Memo.Lines.Text := Info;
end;

procedure ShowCharacterCodeValueDialog(AOwner: TComponent;
  const ALine1Based: Int64; const ALineText: string;
  const ALineByteOffset1: Int64; const AInitialCharIndex1: Integer;
  const ASourcePath, ADisplayEncoding: string);
var
  Dlg: TCharacterCodeForm;
  BtnClose: TButton;
  LineRaw: AnsiString;
begin
  LineRaw := DisplayStringToFileBytes(ALineText, ADisplayEncoding);
  if (Length(LineRaw) = 0) and (ALineByteOffset1 > 0) then
    ReadRawLineBytesAtOffset(ASourcePath, ALineByteOffset1, AInitialCharIndex1, LineRaw);
  if Length(LineRaw) = 0 then
    LineRaw := AnsiString(ALineText);

  Dlg := TCharacterCodeForm.Create(AOwner);
  try
    Dlg.Caption := TrText('Character Code Value...');
    Dlg.BorderStyle := bsDialog;
    Dlg.Position := poOwnerFormCenter;
    Dlg.Width := 520;
    Dlg.Height := 420;
    Dlg.FLine1Based := ALine1Based;
    Dlg.FLineByteOffset1 := ALineByteOffset1;
    Dlg.FLineRaw := LineRaw;

    with TLabel.Create(Dlg) do
    begin
      Parent := Dlg;
      Left := 12;
      Top := 12;
      Caption := TrText('CharCode.CharIndexLabel');
    end;
    Dlg.EdCharIdx := TEdit.Create(Dlg);
    Dlg.EdCharIdx.Parent := Dlg;
    Dlg.EdCharIdx.Left := 160;
    Dlg.EdCharIdx.Top := 10;
    Dlg.EdCharIdx.Width := 80;
    Dlg.EdCharIdx.Text := IntToStr(Max(1, AInitialCharIndex1));
    Dlg.EdCharIdx.OnChange := Dlg.EdCharIdxChange;

    Dlg.Memo := TMemo.Create(Dlg);
    Dlg.Memo.Parent := Dlg;
    Dlg.Memo.Left := 12;
    Dlg.Memo.Top := 40;
    Dlg.Memo.Width := Dlg.ClientWidth - 24;
    Dlg.Memo.Height := Dlg.ClientHeight - 90;
    Dlg.Memo.Anchors := [akLeft, akTop, akRight, akBottom];
    Dlg.Memo.ReadOnly := True;
    Dlg.Memo.ScrollBars := ssVertical;
    Dlg.Memo.WordWrap := False;

    BtnClose := TButton.Create(Dlg);
    BtnClose.Parent := Dlg;
    BtnClose.Caption := TrText('Close');
    BtnClose.ModalResult := mrCancel;
    BtnClose.Left := Dlg.ClientWidth - BtnClose.Width - 16;
    BtnClose.Top := Dlg.ClientHeight - BtnClose.Height - 12;
    BtnClose.Anchors := [akRight, akBottom];

    Dlg.RefreshInfo;
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

{ --- Chunk collector + external sort ---------------------------------------- }

constructor TLineChunkCollector.Create;
begin
  inherited Create;
  FPartPaths := TStringList.Create;
  FChunk := TStringList.Create;
  FChunk.Sorted := True;
  FChunk.Duplicates := dupAccept;
  FWorkDir := EnsureFastFileTempDir;
  FPartIndex := 0;
  FChunkBytes := 0;
end;

destructor TLineChunkCollector.Destroy;
var
  I: Integer;
begin
  FlushChunk;
  for I := 0 to FPartPaths.Count - 1 do
    UnUtils.TryDeleteFileWithRetry(FPartPaths[I], 8, 60);
  FPartPaths.Free;
  FChunk.Free;
  inherited;
end;

function TLineChunkCollector.MakePartPath: string;
begin
  Inc(FPartIndex);
  Result := FWorkDir + Format(FASTFILE_EM_FS_TEMP_NAME_FMT, [GetTickCount, FPartIndex]);
end;

procedure TLineChunkCollector.FlushChunk;
var
  Path: string;
  W: TBufferedTextWriter;
  I: Integer;
begin
  if FChunk.Count = 0 then Exit;
  FChunk.Sort;
  Path := MakePartPath;
  W := TBufferedTextWriter.Create(Path, 4 * 1024 * 1024);
  try
    for I := 0 to FChunk.Count - 1 do
      W.WriteLine(AnsiString(FChunk[I]));
  finally
    W.Free;
  end;
  FPartPaths.Add(Path);
  FChunk.Clear;
  FChunkBytes := 0;
end;

procedure TLineChunkCollector.AddKey(const AKey: AnsiString);
begin
  if AKey = '' then Exit;
  FChunk.Add(string(AKey));
  Inc(FChunkBytes, Length(AKey));
  if FChunkBytes >= CHUNK_BYTE_LIMIT then
    FlushChunk;
end;

function TLineChunkCollector.PartCount: Integer;
begin
  FlushChunk;
  Result := FPartPaths.Count;
end;

function MergeTwoSortedPartFiles(const ALeft, ARight, AOut: string): Boolean;
var
  FL, FR, FO: TFileStream;
  RL, RR: TBufferedAnsiLineReader;
  LineL, LineR: AnsiString;
  PickLeft: Boolean;
  DoneL, DoneR: Boolean;

  procedure WriteLine(const ALine: AnsiString);
  var
    Ch: AnsiChar;
  begin
    if Length(ALine) > 0 then
      FO.WriteBuffer(ALine[1], Length(ALine));
    Ch := #10;
    FO.WriteBuffer(Ch, 1);
  end;

begin
  Result := False;
  RL := TBufferedAnsiLineReader.Create(ALeft);
  try
    RR := TBufferedAnsiLineReader.Create(ARight);
    try
      FO := TFileStream.Create(AOut, fmCreate);
      try
        DoneL := not RL.ReadLine(LineL);
        DoneR := not RR.ReadLine(LineR);
        while not (DoneL and DoneR) do
        begin
          if TfrmSmoothLoading.CancelRequested then Exit;
          if DoneR then PickLeft := True
          else if DoneL then PickLeft := False
          else PickLeft := CompareStr(string(LineL), string(LineR)) <= 0;
          if PickLeft then
          begin
            WriteLine(LineL);
            DoneL := not RL.ReadLine(LineL);
          end
          else
          begin
            WriteLine(LineR);
            DoneR := not RR.ReadLine(LineR);
          end;
        end;
        Result := True;
      finally
        FO.Free;
      end;
    finally
      RR.Free;
    end;
  finally
    RL.Free;
  end;
end;

function MergeAllParts(AParts: TStringList): string;
var
  I: Integer;
  Next, Temp: string;
begin
  if AParts.Count = 0 then
  begin
    Result := '';
    Exit;
  end;
  Result := AParts[0];
  for I := 1 to AParts.Count - 1 do
  begin
    Next := AParts[I];
    Temp := Result + '.mrg';
    if not MergeTwoSortedPartFiles(Result, Next, Temp) then
      raise Exception.Create(TrText('EmEditor.MergeFailed'));
    UnUtils.TryDeleteFileWithRetry(Result, 8, 60);
    UnUtils.TryDeleteFileWithRetry(Next, 8, 60);
    Result := Temp;
  end;
end;

procedure SplitWordsFromLine(const ALine: AnsiString; ACollector: TLineChunkCollector);
var
  I, L, Start: Integer;
  W: AnsiString;
  Ch: AnsiChar;
begin
  L := Length(ALine);
  I := 1;
  while I <= L do
  begin
    while (I <= L) and (ALine[I] <= ' ') do Inc(I);
    if I > L then Break;
    Start := I;
    while (I <= L) and (ALine[I] > ' ') do Inc(I);
    SetString(W, PChar(@ALine[Start]), I - Start);
    if W <> '' then
      ACollector.AddKey(W);
  end;
end;

const
  DEDUP_KEY_SEP = #1;

function SortKeyFromStored(const AStored: AnsiString): AnsiString;
var
  P: Integer;
begin
  P := Pos(DEDUP_KEY_SEP, AStored);
  if P > 0 then
    Result := Copy(AStored, 1, P - 1)
  else
    Result := AStored;
end;

function OutputLineFromStored(const AStored: AnsiString): AnsiString;
var
  P: Integer;
begin
  P := Pos(DEDUP_KEY_SEP, AStored);
  if P > 0 then
    Result := Copy(AStored, P + 1, MaxInt)
  else
    Result := AStored;
end;

procedure ScanSourceKeys(const ASourcePath: string; AMode: TFrequentStringsMode;
  const ACsvDelimiter: Char; ACollector: TLineChunkCollector;
  const AKeyFromLine: TDedupKeyMode; ACsvColumn1: Integer; ADedupStoreFullLine: Boolean);
var
  MMF: TMMFReader;
  FileSize, CurPos: Int64;
  Buf: AnsiString;
  BytesRead, I, LineLen, Cap, ProgressPct, LastPct: Integer;
  Line, Key, Stored: AnsiString;
  LineBuf: array of AnsiChar;
  TermCh: AnsiChar;

  procedure AppendLineChar(const C: AnsiChar);
  begin
    if LineLen >= Cap then
    begin
      Cap := Cap + 65536;
      SetLength(LineBuf, Cap);
    end;
    LineBuf[LineLen] := C;
    Inc(LineLen);
  end;

  procedure ProcessLine(const ALine: AnsiString);
  begin
    if AMode = fsmLines then
    begin
      if AKeyFromLine = dkmCsvColumn then
        Key := ExtractCsvFieldAnsi(ALine, AnsiChar(ACsvDelimiter), ACsvColumn1)
      else
        Key := ALine;
      if ADedupStoreFullLine and (AKeyFromLine = dkmCsvColumn) then
      begin
        Stored := Key + DEDUP_KEY_SEP + ALine;
        ACollector.AddKey(Stored);
      end
      else
        ACollector.AddKey(Key);
    end
    else if AMode = fsmWords then
      SplitWordsFromLine(ALine, ACollector)
    else
    begin
      I := 1;
      while I <= Length(ALine) do
      begin
        Key := ExtractNextCsvFieldAnsi(ALine, AnsiChar(ACsvDelimiter), I);
        if Key <> '' then
          ACollector.AddKey(AnsiTrim(Key));
      end;
    end;
  end;

  procedure FlushLineAcc;
  var
    L: AnsiString;
  begin
    if LineLen <= 0 then Exit;
    SetString(L, PChar(@LineBuf[0]), LineLen);
    while (Length(L) > 0) and (L[Length(L)] in [#13]) do
      SetLength(L, Length(L) - 1);
    ProcessLine(L);
    LineLen := 0;
  end;

begin
  TermCh := LineTermCharForFile(ASourcePath);
  MMF := TMMFReader.Create(ASourcePath);
  try
    FileSize := MMF.FileSize;
    CurPos := 0;
    LineLen := 0;
    Cap := 65536;
    SetLength(LineBuf, Cap);
    LastPct := -1;
    SetLength(Buf, SCAN_BUF_SIZE);
    while (CurPos < FileSize) and (not TfrmSmoothLoading.CancelRequested) do
    begin
      BytesRead := Integer(MMF.ReadBytes(CurPos, Buf[1], SCAN_BUF_SIZE));
      if BytesRead <= 0 then Break;
      for I := 1 to BytesRead do
      begin
        if Buf[I] = TermCh then
          FlushLineAcc
        else if LineLen < MAX_STATS_LINE then
          AppendLineChar(Buf[I]);
      end;
      Inc(CurPos, BytesRead);
      if FileSize > 0 then
      begin
        ProgressPct := Integer((CurPos * 45) div FileSize);
        if ProgressPct <> LastPct then
        begin
          LastPct := ProgressPct;
          TfrmSmoothLoading.PostProgressWithDetailFromWorker(ProgressPct,
            TrText('EmEditor.Progress.Scanning'));
        end;
      end;
    end;
    if LineLen > 0 then
      FlushLineAcc;
  finally
    MMF.Free;
  end;
end;

function WriteUniqueLinesFromSorted(const ASortedPath, ADestPath: string): Int64;
var
  FO: TFileStream;
  R: TBufferedAnsiLineReader;
  Line, PrevKey, OutLine: AnsiString;
  Ch: AnsiChar;
  OutCount: Int64;

begin
  OutCount := 0;
  R := TBufferedAnsiLineReader.Create(ASortedPath);
  try
    FO := TFileStream.Create(ADestPath, fmCreate);
    try
      if R.ReadLine(Line) then
      begin
        PrevKey := SortKeyFromStored(Line);
        OutLine := OutputLineFromStored(Line);
        if Length(OutLine) > 0 then
        begin
          FO.WriteBuffer(OutLine[1], Length(OutLine));
          Ch := #10;
          FO.WriteBuffer(Ch, 1);
          Inc(OutCount);
        end;
        while R.ReadLine(Line) do
        begin
          if TfrmSmoothLoading.CancelRequested then Break;
          if CompareStr(string(SortKeyFromStored(Line)), string(PrevKey)) <> 0 then
          begin
            PrevKey := SortKeyFromStored(Line);
            OutLine := OutputLineFromStored(Line);
            if Length(OutLine) > 0 then
            begin
              FO.WriteBuffer(OutLine[1], Length(OutLine));
              Ch := #10;
              FO.WriteBuffer(Ch, 1);
              Inc(OutCount);
            end;
          end;
        end;
      end;
    finally
      FO.Free;
    end;
  finally
    R.Free;
  end;
  Result := OutCount;
end;

function WriteFrequentFromSorted(const ASortedPath, ADestPath: string;
  AMinCount: Integer): Int64;
var
  FS, FO: TFileStream;
  Line, Prev: AnsiString;
  B: Byte;
  RunCount, OutRows: Int64;
  OutLine: AnsiString;

  function ReadLine(var ALine: AnsiString): Boolean;
  begin
    ALine := '';
    Result := False;
    while FS.Read(B, 1) = 1 do
    begin
      if B = 10 then
      begin
        Result := True;
        Exit;
      end;
      ALine := ALine + AnsiChar(B);
    end;
    Result := Length(ALine) > 0;
  end;

  procedure FlushRun;
  var
    Ch: AnsiChar;
  begin
    if (RunCount >= AMinCount) and (Prev <> '') then
    begin
      OutLine := Prev + AnsiChar(',') + AnsiString(IntToStr(RunCount)) + #10;
      FO.WriteBuffer(OutLine[1], Length(OutLine));
      Inc(OutRows);
    end;
  end;

begin
  OutRows := 0;
  RunCount := 0;
  Prev := '';
  FS := TFileStream.Create(ASortedPath, fmOpenRead or fmShareDenyNone);
  try
    FO := TFileStream.Create(ADestPath, fmCreate);
    try
      OutLine := AnsiString(TrText('EmEditor.FreqOutputHeader')) + #10;
      FO.WriteBuffer(OutLine[1], Length(OutLine));
      if ReadLine(Line) then
      begin
        Prev := Line;
        RunCount := 1;
        while ReadLine(Line) do
        begin
          if TfrmSmoothLoading.CancelRequested then Break;
          if CompareStr(string(Line), string(Prev)) = 0 then
            Inc(RunCount)
          else
          begin
            FlushRun;
            Prev := Line;
            RunCount := 1;
          end;
        end;
        FlushRun;
      end;
    finally
      FO.Free;
    end;
  finally
    FS.Free;
  end;
  Result := OutRows;
end;

type
  TEmEditorStatsThread = class(TThread)
  private
    FSourcePath, FOutputPath, FTempSorted: string;
    FMode: TFrequentStringsMode;
    FDedup: Boolean;
    FKeyMode: TDedupKeyMode;
    FCsvDelimiter: Char;
    FCsvColumn1: Integer;
    FMinCount: Integer;
    FSuccess: Boolean;
    FErrorMsg: string;
    FResultCount: Int64;
    FLoadingMsg: string;
    procedure SyncShow;
    procedure SyncHide;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASource, AOutput: string; AMode: TFrequentStringsMode;
      ADedup: Boolean; AKeyMode: TDedupKeyMode; ACsvDel: Char; ACsvCol1, AMinCount: Integer);
  end;

constructor TEmEditorStatsThread.Create(const ASource, AOutput: string;
  AMode: TFrequentStringsMode; ADedup: Boolean; AKeyMode: TDedupKeyMode;
  ACsvDel: Char; ACsvCol1, AMinCount: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSourcePath := ASource;
  FOutputPath := AOutput;
  FMode := AMode;
  FDedup := ADedup;
  FKeyMode := AKeyMode;
  FCsvDelimiter := ACsvDel;
  FCsvColumn1 := ACsvCol1;
  FMinCount := AMinCount;
  if FDedup then
    FLoadingMsg := TrText('Deleting duplicate lines...')
  else
    FLoadingMsg := TrText('Extracting frequent strings...');
  Synchronize(SyncShow);
  Resume;
end;

procedure TEmEditorStatsThread.SyncShow;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
  TfrmSmoothLoading.UpdateProgress(0);
  ResetEmEditorProgress(UnUtils.GetFileSize(FSourcePath));
end;

procedure TEmEditorStatsThread.SyncHide;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TEmEditorStatsThread.SyncError;
begin
  SyncHide;
  MessageDlg(TrText('EmEditor.ErrorPrefix') + FErrorMsg, mtError, [mbOK], 0);
end;

procedure TEmEditorStatsThread.SyncFinish;
begin
  SyncHide;
  if FSuccess then
  begin
    if FDedup then
    begin
      if Assigned(frmMain) then
      begin
        frmMain.CloseFileStreams;
        frmMain.BeginReadSilent;
        MessageDlg(Format(TrText('EmEditor.DedupDone'), [FResultCount]),
          mtInformation, [mbOK], 0);
        frmMain.AssistantOfferAfterActivity('dedupe',
          Format(TrText('EmEditor.DedupDone'), [FResultCount]));
      end;
    end
    else
      MessageDlg(Format(TrText('EmEditor.FreqDone'), [FOutputPath, FResultCount]),
        mtInformation, [mbOK], 0);
  end
  else if FErrorMsg <> '' then
    SyncError;
end;

procedure TEmEditorStatsThread.Execute;
begin
  FSuccess := False;
  FErrorMsg := '';
  FTempSorted := '';
  try
    try
      if not FDedup then
      begin
        FResultCount := RunExtractFrequentStrings(FSourcePath, FOutputPath, FMode,
          FCsvDelimiter, FCsvColumn1, FMinCount);
        FSuccess := not TfrmSmoothLoading.CancelRequested;
        Exit;
      end;

      FResultCount := RunDeleteDuplicateLines(FSourcePath, FOutputPath, FKeyMode,
        FCsvDelimiter, FCsvColumn1);
      if TfrmSmoothLoading.CancelRequested then
      begin
        FErrorMsg := TrText('Operation cancelled.');
        UnUtils.TryDeleteFileWithRetry(FOutputPath, 8, 60);
        Exit;
      end;
      TfrmSmoothLoading.PostProgressWithDetailFromWorker(96,
        TrText('EmEditor.Progress.Finalizing'));
      if not UnUtils.TryRenameTempOverTarget(FOutputPath, FSourcePath, FErrorMsg) then
        Exit;
      TfrmSmoothLoading.PostProgressFromWorker(100);
      FSuccess := True;
    except
      on E: Exception do
        FErrorMsg := E.Message;
    end;
  finally
    TfrmSmoothLoading.ResetCancel;
    Synchronize(SyncFinish);
  end;
end;

function PromptSavePath(const ATitle, ADefaultName: string): string;
var
  Dlg: TSaveDialog;
begin
  Result := '';
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Title := ATitle;
    Dlg.FileName := ADefaultName;
    Dlg.Filter := TrText('EmEditor.SaveFilter');
    Dlg.DefaultExt := 'csv';
    if Dlg.Execute then
      Result := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

function RunExtractFrequentStringsDialog(AOwner: TComponent;
  const ASourcePath: string; const ACsvMode: Boolean;
  const ACsvDelimiter: Char; const ACsvColumnCount: Integer): Boolean;
var
  Dlg: TForm;
  RgMode: TRadioGroup;
  EdMin: TEdit;
  BtnOk, BtnCancel: TButton;
  Mode: TFrequentStringsMode;
  OutPath: string;
  MinCount: Integer;
begin
  Result := False;
  Dlg := TForm.Create(AOwner);
  try
    Dlg.Caption := TrText('Extract Frequent Strings...');
    Dlg.BorderStyle := bsDialog;
    Dlg.Position := poOwnerFormCenter;
    Dlg.Width := 440;
    Dlg.Height := 280;

    RgMode := TRadioGroup.Create(Dlg);
    RgMode.Parent := Dlg;
    RgMode.Left := 12;
    RgMode.Top := 12;
    RgMode.Width := Dlg.ClientWidth - 24;
    RgMode.Height := 120;
    RgMode.Caption := TrText('EmEditor.FreqModeGroup');
    RgMode.Items.Add(TrText('EmEditor.FreqModeLines'));
    RgMode.Items.Add(TrText('EmEditor.FreqModeWords'));
    RgMode.Items.Add(TrText('EmEditor.FreqModeCells'));
    RgMode.ItemIndex := 0;
    if not ACsvMode then
      RgMode.Items.Strings[2] := RgMode.Items.Strings[2] + ' (' + TrText('EmEditor.CsvNotActive') + ')';

    with TLabel.Create(Dlg) do
    begin
      Parent := Dlg;
      Left := 12;
      Top := 140;
      Caption := TrText('EmEditor.MinCountLabel');
    end;
    EdMin := TEdit.Create(Dlg);
    EdMin.Parent := Dlg;
    EdMin.Left := 200;
    EdMin.Top := 138;
    EdMin.Width := 80;
    EdMin.Text := '1';

    BtnOk := TButton.Create(Dlg);
    BtnOk.Parent := Dlg;
    BtnOk.Caption := TrText('OK');
    BtnOk.ModalResult := mrOk;
    BtnOk.Left := Dlg.ClientWidth - 180;
    BtnOk.Top := Dlg.ClientHeight - 36;

    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Dlg;
    BtnCancel.Caption := TrText('Cancel');
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Left := Dlg.ClientWidth - 90;
    BtnCancel.Top := BtnOk.Top;

    if Dlg.ShowModal <> mrOk then Exit;
    case RgMode.ItemIndex of
      1: Mode := fsmWords;
      2: if ACsvMode then Mode := fsmCsvCells else Mode := fsmLines;
    else Mode := fsmLines;
    end;
    MinCount := StrToIntDef(Trim(EdMin.Text), 1);
    if MinCount < 1 then MinCount := 1;
    OutPath := PromptSavePath(TrText('Extract Frequent Strings...'),
      ChangeFileExt(ExtractFileName(ASourcePath), '_frequent.csv'));
    if OutPath = '' then Exit;
    TEmEditorStatsThread.Create(ASourcePath, OutPath, Mode, False, dkmWholeLine,
      ACsvDelimiter, 1, MinCount);
    Result := True;
  finally
    Dlg.Free;
  end;
end;

function RunDeleteDuplicateLinesDialog(AOwner: TComponent;
  const ASourcePath: string; const ACsvMode: Boolean;
  const ACsvDelimiter: Char; const ACsvColumnCount: Integer): Boolean;
var
  Dlg: TForm;
  RgKey: TRadioGroup;
  EdCol: TEdit;
  BtnOk, BtnCancel: TButton;
  KeyMode: TDedupKeyMode;
  Col1: Integer;
  TempOut: string;
begin
  Result := False;
  if not ConfirmDiskSpaceForPaths(TrText('Delete Duplicate Lines...'),
    ASourcePath, UnUtils.GetFileSize(ASourcePath)) then
    Exit;

  Dlg := TForm.Create(AOwner);
  try
    Dlg.Caption := TrText('Delete Duplicate Lines...');
    Dlg.BorderStyle := bsDialog;
    Dlg.Position := poOwnerFormCenter;
    Dlg.Width := 440;
    Dlg.Height := 260;

    RgKey := TRadioGroup.Create(Dlg);
    RgKey.Parent := Dlg;
    RgKey.Left := 12;
    RgKey.Top := 12;
    RgKey.Width := Dlg.ClientWidth - 24;
    RgKey.Height := 100;
    RgKey.Caption := TrText('EmEditor.DedupKeyGroup');
    RgKey.Items.Add(TrText('EmEditor.DedupWholeLine'));
    RgKey.Items.Add(TrText('EmEditor.DedupCsvColumn'));
    RgKey.ItemIndex := 0;

    with TLabel.Create(Dlg) do
    begin
      Parent := Dlg;
      Left := 12;
      Top := 120;
      Caption := TrText('EmEditor.DedupColumnLabel');
    end;
    EdCol := TEdit.Create(Dlg);
    EdCol.Parent := Dlg;
    EdCol.Left := 200;
    EdCol.Top := 118;
    EdCol.Width := 60;
    EdCol.Text := '1';
    EdCol.Enabled := ACsvMode;

    BtnOk := TButton.Create(Dlg);
    BtnOk.Parent := Dlg;
    BtnOk.Caption := TrText('OK');
    BtnOk.ModalResult := mrOk;
    BtnOk.Left := Dlg.ClientWidth - 180;
    BtnOk.Top := Dlg.ClientHeight - 36;

    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Dlg;
    BtnCancel.Caption := TrText('Cancel');
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Left := Dlg.ClientWidth - 90;
    BtnCancel.Top := BtnOk.Top;

    if Dlg.ShowModal <> mrOk then Exit;
    if RgKey.ItemIndex = 1 then
    begin
      if not ACsvMode then
      begin
        MessageDlg(TrText('EmEditor.DedupNeedCsv'), mtWarning, [mbOK], 0);
        Exit;
      end;
      KeyMode := dkmCsvColumn;
    end
    else
      KeyMode := dkmWholeLine;
    Col1 := StrToIntDef(Trim(EdCol.Text), 1);
    if Col1 < 1 then Col1 := 1;

    TempOut := EmNewFastFileTemp('emdedup');
    UnUtils.TryDeleteFileWithRetry(TempOut, 8, 60);
    TEmEditorStatsThread.Create(ASourcePath, TempOut, fsmLines, True, KeyMode,
      ACsvDelimiter, Col1, 1);
    Result := True;
  finally
    Dlg.Free;
  end;
end;

end.
