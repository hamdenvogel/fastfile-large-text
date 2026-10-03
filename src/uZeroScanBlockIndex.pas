unit uZeroScanBlockIndex;

{
  Indice de blocos para Zero Scan (ficheiros grandes): um Int64 por bloco de 64 MB
  com offset 1-based do inicio de linha naquele bloco. Usado para saltar varreduras
  em Find / Ctrl+G sem temp.txt denso. Nao usado no modo indexado classico (<2 GB denso).
}

interface

uses
  Windows, SysUtils, Classes, uFastFilePaths, UnConsts, UnUtils;

const
  ZERO_SCAN_BLOCK_BYTES = Int64(64) * 1024 * 1024;
  ZERO_SCAN_BLOCK_MAGIC = 'FFBIDX01';
  ZERO_SCAN_BLOCK_HEADER_SIZE = 32;
  ZERO_SCAN_FILTER_HITS_MAGIC = 'FFFHITS1';

function ZeroScanBlockIndexPath: string;
function ZeroScanFilterHitsPath: string;
function ZeroScanBlockIndexTempPath: string;

function ZeroScanBlockHintPos0(const ABlockIndexPath: string; ATargetPos0: Int64): Int64;

type
  TZeroScanBlockIndexWriter = class
  private
    FStream: TFileStream;
    FTempPath: string;
    FTargetPath: string;
    FLastBlockIdx: Int64;
    FEntryBatch: array[0..255] of Int64;
    FBatchCount: Integer;
    procedure FlushBatch;
    procedure WriteEntry(const AOffset1Based: Int64);
  public
    constructor Create;
    destructor Destroy; override;
    procedure NoteLineStart1Based(const AOffset1Based: Int64; const AFilePos0: Int64);
    function FinalizeIndex: Boolean;
    property TargetPath: string read FTargetPath;
  end;

procedure ZeroScanDeleteBlockIndex;
procedure ZeroScanDeleteFilterHits;

function ZeroScanOpenFilterHitsReader(out ACount: Int64): TFileStream;
function ZeroScanReadFilterHit(AStream: TFileStream; AIndex: Int64): Int64;
function ZeroScanCreateFilterHitsWriter(out ATempPath: string): TFileStream;
function ZeroScanOpenFilterHitsAppender(out ACount: Int64): TFileStream;
function ZeroScanFinalizeFilterHitsTemp(const ATempPath: string): Boolean;

implementation

function ZeroScanBlockIndexPath: string;
begin
  Result := FastFileExeDirPath(TEMP_ZERO_SCAN_BLOCK_IDX);
end;

function ZeroScanFilterHitsPath: string;
begin
  Result := FastFileExeDirPath(TEMP_FILTER_HITS_FILE);
end;

function ZeroScanBlockIndexTempPath: string;
begin
  Result := FastFileScratchTempPathWithPrefix(FASTFILE_ZERO_SCAN_BLK_TEMP_PREFIX);
end;

procedure ZeroScanDeleteBlockIndex;
var
  P: string;
begin
  P := ZeroScanBlockIndexPath;
  if FileExists(P) then
    UnUtils.TryDeleteFileWithRetry(P, 12, 80);
end;

procedure ZeroScanDeleteFilterHits;
var
  P: string;
begin
  P := ZeroScanFilterHitsPath;
  if FileExists(P) then
    UnUtils.TryDeleteFileWithRetry(P, 12, 80);
end;

function ZeroScanBlockHintPos0(const ABlockIndexPath: string; ATargetPos0: Int64): Int64;
var
  Fs: TFileStream;
  BlockSize, Count, BlockIdx: Int64;
  Entry: Int64;
  Hdr: array[0..31] of AnsiChar;
begin
  Result := 0;
  if (ABlockIndexPath = '') or (not FileExists(ABlockIndexPath)) or (ATargetPos0 < 0) then
    Exit;
  Fs := nil;
  try
    Fs := TFileStream.Create(ABlockIndexPath, fmOpenRead or fmShareDenyNone);
    if Fs.Size < ZERO_SCAN_BLOCK_HEADER_SIZE then
      Exit;
    Fs.ReadBuffer(Hdr[0], ZERO_SCAN_BLOCK_HEADER_SIZE);
    if not (CompareMem(@Hdr[0], @ZERO_SCAN_BLOCK_MAGIC[1], 8)) then
      Exit;
    BlockSize := ZERO_SCAN_BLOCK_BYTES;
    Count := (Fs.Size - ZERO_SCAN_BLOCK_HEADER_SIZE) div SizeOf(Int64);
    if Count <= 0 then
      Exit;
    BlockIdx := ATargetPos0 div BlockSize;
    if BlockIdx >= Count then
      BlockIdx := Count - 1;
    if BlockIdx < 0 then
      BlockIdx := 0;
    Fs.Seek(ZERO_SCAN_BLOCK_HEADER_SIZE + BlockIdx * SizeOf(Int64), soFromBeginning);
    Fs.ReadBuffer(Entry, SizeOf(Int64));
    if Entry > 0 then
      Result := Entry - 1;
  except
    Result := 0;
  end;
  if Assigned(Fs) then
    Fs.Free;
end;

constructor TZeroScanBlockIndexWriter.Create;
var
  Hdr: array[0..31] of AnsiChar;
begin
  inherited Create;
  FTargetPath := ZeroScanBlockIndexPath;
  FTempPath := ZeroScanBlockIndexTempPath;
  UnUtils.TryDeleteFileWithRetry(FTempPath, 8, 40);
  UnUtils.TryDeleteFileWithRetry(FTargetPath, 8, 40);
  FStream := TFileStream.Create(FTempPath, fmCreate);
  FillChar(Hdr[0], SizeOf(Hdr), 0);
  Move(ZERO_SCAN_BLOCK_MAGIC[1], Hdr[0], 8);
  PInt64(@Hdr[8])^ := ZERO_SCAN_BLOCK_BYTES;
  FStream.WriteBuffer(Hdr[0], ZERO_SCAN_BLOCK_HEADER_SIZE);
  FLastBlockIdx := 0;
  FBatchCount := 0;
  WriteEntry(1);
end;

procedure TZeroScanBlockIndexWriter.FlushBatch;
begin
  if (FBatchCount > 0) and Assigned(FStream) then
  begin
    FStream.WriteBuffer(FEntryBatch[0], FBatchCount * SizeOf(Int64));
    FBatchCount := 0;
  end;
end;

procedure TZeroScanBlockIndexWriter.WriteEntry(const AOffset1Based: Int64);
begin
  if FBatchCount >= Length(FEntryBatch) then
    FlushBatch;
  FEntryBatch[FBatchCount] := AOffset1Based;
  Inc(FBatchCount);
end;

procedure TZeroScanBlockIndexWriter.NoteLineStart1Based(const AOffset1Based: Int64;
  const AFilePos0: Int64);
var
  BlockIdx: Int64;
begin
  if AOffset1Based <= 0 then
    Exit;
  BlockIdx := AFilePos0 div ZERO_SCAN_BLOCK_BYTES;
  if BlockIdx > FLastBlockIdx then
  begin
    WriteEntry(AOffset1Based);
    FLastBlockIdx := BlockIdx;
  end;
end;

function TZeroScanBlockIndexWriter.FinalizeIndex: Boolean;
var
  Err: string;
begin
  Result := False;
  FlushBatch;
  if Assigned(FStream) then
  begin
    FStream.Free;
    FStream := nil;
  end;
  if (FTempPath <> '') and FileExists(FTempPath) then
    Result := UnUtils.TryRenameTempOverTarget(FTempPath, FTargetPath, Err);
end;

destructor TZeroScanBlockIndexWriter.Destroy;
begin
  FlushBatch;
  if Assigned(FStream) then
  begin
    FStream.Free;
    FStream := nil;
  end;
  if (FTempPath <> '') and FileExists(FTempPath) then
    SysUtils.DeleteFile(FTempPath);
  inherited Destroy;
end;

function ZeroScanCreateFilterHitsWriter(out ATempPath: string): TFileStream;
var
  Hdr: array[0..15] of AnsiChar;
  Tmp, FinalP: string;
begin
  FinalP := ZeroScanFilterHitsPath;
  Tmp := FastFileScratchTempPathWithPrefix(FASTFILE_ZERO_SCAN_FILTER_TEMP_PREFIX);
  ATempPath := Tmp;
  UnUtils.TryDeleteFileWithRetry(FinalP, 8, 40);
  UnUtils.TryDeleteFileWithRetry(Tmp, 8, 40);
  Result := TFileStream.Create(Tmp, fmCreate);
  FillChar(Hdr[0], SizeOf(Hdr), 0);
  Move(ZERO_SCAN_FILTER_HITS_MAGIC[1], Hdr[0], 8);
  Result.WriteBuffer(Hdr[0], 16);
end;

function ZeroScanOpenFilterHitsAppender(out ACount: Int64): TFileStream;
var
  Hdr: array[0..15] of AnsiChar;
  P: string;
begin
  ACount := 0;
  Result := nil;
  P := ZeroScanFilterHitsPath;
  if not FileExists(P) then
    Exit;
  Result := TFileStream.Create(P, fmOpenReadWrite or fmShareDenyWrite);
  if Result.Size < 16 then
  begin
    Result.Free;
    Result := nil;
    Exit;
  end;
  Result.Seek(0, soFromBeginning);
  Result.ReadBuffer(Hdr[0], 16);
  if not CompareMem(@Hdr[0], @ZERO_SCAN_FILTER_HITS_MAGIC[1], 8) then
  begin
    Result.Free;
    Result := nil;
    Exit;
  end;
  ACount := (Result.Size - 16) div SizeOf(Int64);
  Result.Seek(0, soFromEnd);
end;

function ZeroScanFinalizeFilterHitsTemp(const ATempPath: string): Boolean;
var
  Err: string;
begin
  if (ATempPath = '') or (not FileExists(ATempPath)) then
  begin
    Result := False;
    Exit;
  end;
  Result := UnUtils.TryRenameTempOverTarget(ATempPath, ZeroScanFilterHitsPath, Err);
end;

function ZeroScanOpenFilterHitsReader(out ACount: Int64): TFileStream;
var
  Hdr: array[0..15] of AnsiChar;
begin
  ACount := 0;
  Result := nil;
  if not FileExists(ZeroScanFilterHitsPath) then
    Exit;
  Result := TFileStream.Create(ZeroScanFilterHitsPath, fmOpenRead or fmShareDenyNone);
  if Result.Size < 16 then
  begin
    Result.Free;
    Result := nil;
    Exit;
  end;
  Result.ReadBuffer(Hdr[0], 16);
  if not CompareMem(@Hdr[0], @ZERO_SCAN_FILTER_HITS_MAGIC[1], 8) then
  begin
    Result.Free;
    Result := nil;
    Exit;
  end;
  ACount := (Result.Size - 16) div SizeOf(Int64);
end;

function ZeroScanReadFilterHit(AStream: TFileStream; AIndex: Int64): Int64;
begin
  Result := -1;
  if not Assigned(AStream) then
    Exit;
  if (AIndex < 0) or (AIndex * SizeOf(Int64) + 16 > AStream.Size) then
    Exit;
  AStream.Seek(16 + AIndex * SizeOf(Int64), soFromBeginning);
  AStream.ReadBuffer(Result, SizeOf(Int64));
end;

end.
