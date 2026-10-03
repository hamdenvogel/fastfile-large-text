unit uFastFilePaths;

interface

uses
  Windows, SysUtils, Classes, UnConsts, Types;

type
  { Optional scan heartbeat (percent 0..100). Set ACancel to abort. }
  TFastFileScanProgress = procedure(APercent: Integer; var ACancel: Boolean) of object;
  { One sequential 256 KB pass (same I/O class as F5). ALine is raw bytes, not Unicode. }
  TFastFileRawLineCallback = procedure(ALine: PAnsiChar; ALen: Integer;
    ALineNo: Int64; var AStop: Boolean; AUser: Pointer);

function FastFileBaseDir: string;
function FastFileTempDir: string;
function EnsureFastFileTempDir: string;
function EnsureFastFileTempSubDir(const ASubDir: string): string;
function FastFileTempPath(const AFileName: string): string;
{ Folder for AI assistant generated files (beside exe), not fastfile_temp. }
function FastFileAssistantOutDir: string;
function EnsureFastFileAssistantOutDir: string;
function FastFileAssistantOutPath(const AFileName: string): string;
{ Path to a file beside ParamStr(0) (working line index: temp.txt / temp_ckpt.txt). }
function FastFileExeDirPath(const AFileName: string): string;
{ Dense temp.txt if present, else sparse temp_ckpt.txt. Empty if neither exists. }
function ResolveWorkingLineIndexPath: string;
{ Unique scratch file in fastfile_temp: ff_<Tag>_<tick>_<tid>.tmp }
function FastFileScratchTempPath(const ATag: string): string;
{ Scratch temp beside AReferenceFile (same volume — replace/save rename and free-space check). }
function FastFileScratchTempPathNearFile(const ATag, AReferenceFile: string): string;
{ Same pattern with a fixed prefix (ff_zsblk_, ff_zsfilt_, etc.). }
function FastFileScratchTempPathWithPrefix(const APrefix: string): string;
function EnsureFastFileSessionHistoryDir: string;
function FastFileSessionPath(const ASafeSessionBaseName: string): string;
{ Encode a full source path into a Windows-safe base name (same rule as .ffsession).
  C:\Hamden\PI121106.txt -> C__Hamden_PI121106.txt }
function FastFileSafeNameFromPath(const ASourcePath: string): string;
{ Short path for narrow UI banners; full path stays in Hint. }
function FastFileShortenPathForUi(const APath: string; AMaxLen: Integer = 52): string;
{ Count how many lines start with each prefix (one pass). }
function FastFileCountLineStartPrefixes(const APath: string;
  const APrefixes: array of string; out ACounts: TInt64DynArray;
  out ATotalLines: Int64; AOnProgress: TFastFileScanProgress = nil): Boolean;
{ Count how many lines contain each needle (substring, case-insensitive, one pass). }
function FastFileCountLineContains(const APath: string;
  const ANeedles: array of string; out ACounts: TInt64DynArray;
  out ATotalLines: Int64; AOnProgress: TFastFileScanProgress = nil): Boolean;
{ First AMaxLines matching lines (1-based numbered). Stops as soon as the cap is reached. }
function FastFileCollectMatchingLines(const APath, ANeedle: string;
  AMaxLines: Integer; ACaseSensitive: Boolean): string;
{ Walk every line with the F5-class binary reader. Assistant tools must use this
  (or CountLines / prefix / contains) — never TextFile/ReadLn. }
function FastFileForEachRawLine(const APath: string;
  ACallback: TFastFileRawLineCallback; AUser: Pointer;
  AOnProgress: TFastFileScanProgress = nil): Boolean;
{ Count LF-terminated lines on disk. Uses F5 index if valid, else one binary pass. }
function FastFileCountLines(const APath: string): Int64;
{ Instant: F5 index or a previous binary scan of the same path/size/mtime. 0 if unknown. }
function FastFileKnownLineCount(const APath: string): Int64;
function FastFileRuntimeLogPath: string;
{ Remove work copies (ff_*.tmp, merge scratch) from fastfile_temp. Keeps .ffsession,
  .ffckpt, .ffmeta, .delta, logs, and FastFileSessionHistory. Safe at app exit or startup (orphans). }
function CleanupFastFileTempWorkFiles: Integer;
{ Remove line index files beside the executable (temp.txt, temp_ckpt.txt).
  Call only after CloseFileStreams / handles released. }
function CleanupFastFileLineIndexFiles: Integer;
function SaveLineIndexCache(const ASourcePath: string; AFileSize, ALineCount: Int64;
  const AWriteTime: TFileTime): Boolean;
function LoadLineIndexCache(const ASourcePath: string; AFileSize: Int64;
  const AWriteTime: TFileTime; out ALineCount: Int64): Boolean;
function LineIndexCacheFilesReady(AFileSize: Int64): Boolean;

implementation

uses
  Forms,
  UnUtils,
  uPosBMH,
  uEolPolicy,
  uTextEncoding;

function FastFileBaseDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function FastFileTempDir: string;
begin
  Result := IncludeTrailingPathDelimiter(FastFileBaseDir + FASTFILE_TEMP_DIR);
end;

function EnsureFastFileTempDir: string;
begin
  Result := FastFileTempDir;
  if not DirectoryExists(Result) then
  begin
    if not ForceDirectories(Result) then
      raise Exception.CreateFmt('Cannot create temp folder: %s', [Result]);
  end;
end;

function EnsureFastFileTempSubDir(const ASubDir: string): string;
begin
  Result := IncludeTrailingPathDelimiter(EnsureFastFileTempDir + ASubDir);
  if not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

function FastFileTempPath(const AFileName: string): string;
begin
  Result := EnsureFastFileTempDir + AFileName;
end;

function FastFileAssistantOutDir: string;
begin
  Result := IncludeTrailingPathDelimiter(FastFileBaseDir + FASTFILE_ASSISTANT_OUT_DIR);
end;

function EnsureFastFileAssistantOutDir: string;
begin
  Result := FastFileAssistantOutDir;
  if not DirectoryExists(Result) then
  begin
    if not ForceDirectories(Result) then
      raise Exception.CreateFmt('Cannot create assistant output folder: %s', [Result]);
  end;
end;

function FastFileAssistantOutPath(const AFileName: string): string;
begin
  Result := EnsureFastFileAssistantOutDir + AFileName;
end;

function FastFileExeDirPath(const AFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + AFileName;
end;

function ResolveWorkingLineIndexPath: string;
var
  Dense, Ckpt: string;
begin
  Dense := FastFileExeDirPath(TEMPFILE);
  if FileExists(Dense) and (UnUtils.GetFileSize(Dense) >= 20) then
  begin
    Result := Dense;
    Exit;
  end;
  Ckpt := FastFileExeDirPath(TEMP_CKPT_FILE);
  if FileExists(Ckpt) and (UnUtils.GetFileSize(Ckpt) >= 20) then
  begin
    Result := Ckpt;
    Exit;
  end;
  Result := '';
end;

function FastFileScratchTempPath(const ATag: string): string;
var
  Tag: string;
begin
  Tag := ATag;
  if Tag = '' then
    Tag := 'tmp';
  Result := EnsureFastFileTempDir + FASTFILE_TEMP_SCRATCH_PREFIX + Tag + '_' +
    IntToStr(Windows.GetTickCount) + '_' + IntToStr(Windows.GetCurrentThreadId) +
    FASTFILE_TEMP_SCRATCH_EXT;
end;

function FastFileScratchTempPathWithPrefix(const APrefix: string): string;
begin
  Result := EnsureFastFileTempDir + APrefix +
    IntToStr(Windows.GetTickCount) + '_' + IntToStr(Windows.GetCurrentThreadId) +
    FASTFILE_TEMP_SCRATCH_EXT;
end;

function FastFileScratchTempPathNearFile(const ATag, AReferenceFile: string): string;
var
  Tag, Dir: string;
begin
  Tag := ATag;
  if Tag = '' then
    Tag := 'tmp';
  Dir := ExtractFilePath(ExpandFileName(AReferenceFile));
  if Dir = '' then
    Result := FastFileScratchTempPath(Tag)
  else
  begin
    if (not DirectoryExists(Dir)) and (not ForceDirectories(Dir)) then
    begin
      Result := FastFileScratchTempPath(Tag);
      Exit;
    end;
    Result := Dir + FASTFILE_TEMP_SCRATCH_PREFIX + Tag + '_' +
      IntToStr(Windows.GetTickCount) + '_' + IntToStr(Windows.GetCurrentThreadId) +
      FASTFILE_TEMP_SCRATCH_EXT;
  end;
end;

function EnsureFastFileSessionHistoryDir: string;
begin
  Result := EnsureFastFileTempSubDir(FASTFILE_HISTORY_DIR);
end;

function FastFileSafeNameFromPath(const ASourcePath: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := ExpandFileName(Trim(ASourcePath));
  if Result = '' then Exit;
  for I := 1 to Length(Result) do
  begin
    C := Result[I];
    if Pos(C, ILLEGAL_FILENAME_CHARS) > 0 then
      Result[I] := '_';
  end;
end;

function FastFileShortenPathForUi(const APath: string; AMaxLen: Integer): string;
var
  S, Tail, ParentDir: string;
  KeepHead: Integer;
begin
  S := Trim(APath);
  if AMaxLen < 16 then
    AMaxLen := 16;
  if Length(S) <= AMaxLen then
  begin
    Result := S;
    Exit;
  end;
  Tail := ExtractFileName(ExcludeTrailingPathDelimiter(S));
  ParentDir := ExtractFileDir(ExcludeTrailingPathDelimiter(S));
  if ParentDir <> '' then
    Tail := ExtractFileName(ParentDir) + PathDelim + Tail;
  KeepHead := AMaxLen - Length(Tail) - 3;
  if KeepHead < 8 then
  begin
    Result := '...' + Copy(S, Length(S) - AMaxLen + 4, MaxInt);
    Exit;
  end;
  Result := Copy(S, 1, KeepHead) + '...' + Tail;
end;

function FileSize64ForScan(const APath: string): Int64;
var
  Rec: TSearchRec;
begin
  Result := 0;
  if FindFirst(APath, faAnyFile, Rec) = 0 then
  begin
    Result := Rec.Size;
    FindClose(Rec);
  end;
end;

procedure ReportScanProgress(AOnProgress: TFastFileScanProgress;
  ABytes, ASize: Int64; var ACancel: Boolean);
var
  Pct: Integer;
begin
  if not Assigned(AOnProgress) then Exit;
  if ASize > 0 then
    Pct := Integer((ABytes * 100) div ASize)
  else
    Pct := 0;
  if Pct < 0 then Pct := 0;
  if Pct > 100 then Pct := 100;
  AOnProgress(Pct, ACancel);
end;

type
  TFastFileLineCountMem = record
    Path: string;
    Size: Int64;
    WriteTime: TFileTime;
    Count: Int64;
  end;

var
  GLineCountMem: TFastFileLineCountMem;

function TryFileIdentity(const APath: string; out ASize: Int64;
  out AWrite: TFileTime): Boolean;
var
  Rec: TSearchRec;
begin
  Result := False;
  ASize := 0;
  FillChar(AWrite, SizeOf(AWrite), 0);
  if FindFirst(APath, faAnyFile, Rec) <> 0 then Exit;
  ASize := Rec.Size;
  AWrite := Rec.FindData.ftLastWriteTime;
  SysUtils.FindClose(Rec);
  Result := True;
end;

procedure RememberScannedLineCount(const APath: string; ACount: Int64);
var
  Sz: Int64;
  Wt: TFileTime;
begin
  if (ACount <= 0) or not TryFileIdentity(APath, Sz, Wt) then Exit;
  GLineCountMem.Path := ExpandFileName(APath);
  GLineCountMem.Size := Sz;
  GLineCountMem.WriteTime := Wt;
  GLineCountMem.Count := ACount;
end;

function FastFileKnownLineCount(const APath: string): Int64;
var
  Sz: Int64;
  Wt: TFileTime;
begin
  Result := 0;
  if not TryFileIdentity(APath, Sz, Wt) then Exit;
  if LoadLineIndexCache(APath, Sz, Wt, Result) and (Result > 0) then
    Exit;
  if (GLineCountMem.Count > 0) and
     SameFileName(GLineCountMem.Path, ExpandFileName(APath)) and
     (GLineCountMem.Size = Sz) and
     (CompareFileTime(GLineCountMem.WriteTime, Wt) = 0) then
    Result := GLineCountMem.Count;
end;

function FastFileForEachRawLine(const APath: string;
  ACallback: TFastFileRawLineCallback; AUser: Pointer;
  AOnProgress: TFastFileScanProgress): Boolean;
const
  BUF_SIZE = 256 * 1024;
var
  F: TFileStream;
  Buffer: PAnsiChar;
  LineBuf: array of AnsiChar;
  LineLen, LineCap, BytesRead, i, LastPct: Integer;
  FileSize, Processed, LineNo: Int64;
  LastWasLF, Stop, Cancel: Boolean;
  TermB: Byte;

  procedure EnsureLineCap(ANeed: Integer);
  begin
    if ANeed <= LineCap then Exit;
    if LineCap < 8192 then
      LineCap := 8192;
    while LineCap < ANeed do
      LineCap := LineCap * 2;
    SetLength(LineBuf, LineCap);
  end;

  procedure EmitLine;
  var
    P: PAnsiChar;
    N: Integer;
  begin
    Inc(LineNo);
    P := nil;
    N := LineLen;
    if (N > 0) and (Byte(LineBuf[N - 1]) = 13) then
      Dec(N);
    if N > 0 then
      P := @LineBuf[0];
    if Assigned(ACallback) then
      ACallback(P, N, LineNo, Stop, AUser);
    LineLen := 0;
  end;

begin
  Result := False;
  if not Assigned(ACallback) or (APath = '') or (not FileExists(APath)) then Exit;
  F := nil;
  Buffer := nil;
  Stop := False;
  Cancel := False;
  LineCap := 0;
  LineLen := 0;
  LineNo := 0;
  EnsureLineCap(8192);
  TermB := LineTermByteForFile(APath);
  try
    GetMem(Buffer, BUF_SIZE);
    F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    FileSize := F.Size;
    Processed := 0;
    LastPct := -1;
    LastWasLF := False;
    while True do
    begin
      BytesRead := F.Read(Buffer^, BUF_SIZE);
      if BytesRead <= 0 then Break;
      for i := 0 to BytesRead - 1 do
      begin
        if Byte(Buffer[i]) = TermB then
        begin
          EmitLine;
          LastWasLF := True;
          if Stop then
            Break;
        end
        else
        begin
          LastWasLF := False;
          EnsureLineCap(LineLen + 1);
          LineBuf[LineLen] := Buffer[i];
          Inc(LineLen);
        end;
      end;
      if Stop then
        Break;
      Inc(Processed, BytesRead);
      if Assigned(AOnProgress) and (FileSize > 0) then
      begin
        i := Integer((Processed * 100) div FileSize);
        if i > 100 then i := 100;
        if i > LastPct then
        begin
          LastPct := i;
          ReportScanProgress(AOnProgress, Processed, FileSize, Cancel);
          if Cancel then
          begin
            Result := False;
            Exit;
          end;
        end;
      end;
    end;
    if (not Stop) and (FileSize > 0) and (not LastWasLF) and (LineLen > 0) then
      EmitLine;
    if (not Stop) and (not Cancel) then
      RememberScannedLineCount(APath, LineNo);
    if Assigned(AOnProgress) then
      ReportScanProgress(AOnProgress, FileSize, FileSize, Cancel);
    Result := not Cancel;
  except
    Result := False;
  end;
  if Assigned(F) then
    F.Free;
  if Buffer <> nil then
    FreeMem(Buffer);
end;

function AsciiSameTextP(P: PAnsiChar; const S: RawByteString; Len: Integer): Boolean;
var
  k: Integer;
  a, b: Byte;
begin
  Result := False;
  if (P = nil) or (Len <= 0) or (Length(S) < Len) then Exit;
  for k := 1 to Len do
  begin
    a := Byte(P[k - 1]);
    b := Byte(S[k]);
    if (a >= 65) and (a <= 90) then Inc(a, 32);
    if (b >= 65) and (b <= 90) then Inc(b, 32);
    if a <> b then Exit;
  end;
  Result := True;
end;

function AsciiContainsRaw(const Line, Needle: RawByteString): Boolean;
var
  i, nLen, lLen: Integer;
begin
  Result := False;
  nLen := Length(Needle);
  lLen := Length(Line);
  if (nLen = 0) or (lLen < nLen) then Exit;
  for i := 1 to lLen - nLen + 1 do
    if AsciiSameTextP(@Line[i], Needle, nLen) then
    begin
      Result := True;
      Exit;
    end;
end;

function FastFileCountLineStartPrefixes(const APath: string;
  const APrefixes: array of string; out ACounts: TInt64DynArray;
  out ATotalLines: Int64; AOnProgress: TFastFileScanProgress): Boolean;
{ Same I/O as F5 / FastFileCountLinesLf: 256 KB binary blocks, no ReadLn. }
const
  BUF_SIZE = 256 * 1024;
  HEAD_MAX = 64;
var
  F: TFileStream;
  Buffer: PAnsiChar;
  PrefA: array of RawByteString;
  PrefLen: array of Integer;
  Head: array[0..HEAD_MAX] of AnsiChar;
  HeadLen, BytesRead, i, n, maxPref, LastPct: Integer;
  FileSize, Processed: Int64;
  Enc: string;
  AtLineStart, HeadDone, LastWasLF, Cancel: Boolean;
  TermB: Byte;

  procedure CheckHead;
  var
    k: Integer;
  begin
    if HeadLen <= 0 then Exit;
    for k := 0 to n - 1 do
      if (PrefLen[k] > 0) and (HeadLen >= PrefLen[k]) and
         AsciiSameTextP(@Head[0], PrefA[k], PrefLen[k]) then
        Inc(ACounts[k]);
  end;

  procedure FinishLine;
  begin
    if not HeadDone then
      CheckHead;
    Inc(ATotalLines);
    HeadLen := 0;
    HeadDone := False;
    AtLineStart := True;
  end;

begin
  Result := False;
  ATotalLines := 0;
  n := Length(APrefixes);
  SetLength(ACounts, n);
  SetLength(PrefA, n);
  SetLength(PrefLen, n);
  maxPref := 0;
  Enc := DetectTextFileEncoding(APath);
  for i := 0 to n - 1 do
  begin
    ACounts[i] := 0;
    PrefA[i] := UnicodeTextToFileBytes(APrefixes[i], Enc);
    PrefLen[i] := Length(PrefA[i]);
    if PrefLen[i] > HEAD_MAX then
      PrefLen[i] := 0
    else if PrefLen[i] > maxPref then
      maxPref := PrefLen[i];
  end;
  if (APath = '') or (not FileExists(APath)) or (n = 0) then Exit;

  F := nil;
  Buffer := nil;
  Cancel := False;
  try
    GetMem(Buffer, BUF_SIZE);
    F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    FileSize := F.Size;
    Processed := 0;
    LastPct := -1;
    AtLineStart := True;
    HeadDone := False;
    HeadLen := 0;
    LastWasLF := False;
    TermB := LineTermByteForFile(APath);
    while True do
    begin
      BytesRead := F.Read(Buffer^, BUF_SIZE);
      if BytesRead <= 0 then Break;
      for i := 0 to BytesRead - 1 do
      begin
        if Byte(Buffer[i]) = TermB then
        begin
          FinishLine;
          LastWasLF := True;
        end
        else
        begin
          LastWasLF := False;
          if AtLineStart and (not HeadDone) then
          begin
            if HeadLen < HEAD_MAX then
            begin
              Head[HeadLen] := Buffer[i];
              Inc(HeadLen);
            end;
            if (maxPref > 0) and (HeadLen >= maxPref) then
            begin
              CheckHead;
              HeadDone := True;
              AtLineStart := False;
            end;
          end;
        end;
      end;
      Inc(Processed, BytesRead);
      if Assigned(AOnProgress) and (FileSize > 0) then
      begin
        i := Integer((Processed * 100) div FileSize);
        if i > 100 then i := 100;
        if i > LastPct then
        begin
          LastPct := i;
          ReportScanProgress(AOnProgress, Processed, FileSize, Cancel);
          if Cancel then
          begin
            Result := False;
            Exit;
          end;
        end;
      end;
    end;
    if (FileSize > 0) and (not LastWasLF) and ((HeadLen > 0) or (not AtLineStart)) then
      FinishLine;
    if Assigned(AOnProgress) then
      ReportScanProgress(AOnProgress, FileSize, FileSize, Cancel);
    Result := not Cancel;
    if Result then
      RememberScannedLineCount(APath, ATotalLines);
  except
    Result := False;
  end;
  if Assigned(F) then
    F.Free;
  if Buffer <> nil then
    FreeMem(Buffer);
end;

function FastFileCountLineContains(const APath: string;
  const ANeedles: array of string; out ACounts: TInt64DynArray;
  out ATotalLines: Int64; AOnProgress: TFastFileScanProgress): Boolean;
const
  BUF_SIZE = 256 * 1024;
var
  F: TFileStream;
  Buffer: PAnsiChar;
  NeedA: array of RawByteString;
  LineBuf: array of AnsiChar;
  LineLen, LineCap, BytesRead, i, n, LastPct: Integer;
  FileSize, Processed: Int64;
  Enc: string;
  NeedUnicode: Boolean;
  LastWasLF, Cancel: Boolean;
  TermB: Byte;

  procedure EnsureLineCap(ANeed: Integer);
  begin
    if ANeed <= LineCap then Exit;
    if LineCap < 8192 then
      LineCap := 8192;
    while LineCap < ANeed do
      LineCap := LineCap * 2;
    SetLength(LineBuf, LineCap);
  end;

  procedure FlushLine;
  var
    Line: RawByteString;
    k: Integer;
  begin
    Inc(ATotalLines);
    if LineLen > 0 then
    begin
      SetString(Line, PAnsiChar(@LineBuf[0]), LineLen);
      for k := 0 to n - 1 do
        if NeedA[k] <> '' then
        begin
          if NeedUnicode then
          begin
            if UnicodeLineMatches(Line, ANeedles[k], Enc, False, False) then
              Inc(ACounts[k]);
          end
          else if AsciiContainsRaw(Line, NeedA[k]) then
            Inc(ACounts[k]);
        end;
    end;
    LineLen := 0;
  end;

begin
  Result := False;
  ATotalLines := 0;
  n := Length(ANeedles);
  SetLength(ACounts, n);
  SetLength(NeedA, n);
  Enc := DetectTextFileEncoding(APath);
  NeedUnicode := False;
  for i := 0 to n - 1 do
  begin
    ACounts[i] := 0;
    NeedA[i] := UnicodeTextToFileBytes(ANeedles[i], Enc);
    if EncodingNeedsWideCompare(Enc, ANeedles[i]) then
      NeedUnicode := True;
  end;
  if (APath = '') or (not FileExists(APath)) or (n = 0) then Exit;

  F := nil;
  Buffer := nil;
  Cancel := False;
  LineCap := 0;
  LineLen := 0;
  EnsureLineCap(8192);
  try
    GetMem(Buffer, BUF_SIZE);
    F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    FileSize := F.Size;
    Processed := 0;
    LastPct := -1;
    LastWasLF := False;
    TermB := LineTermByteForFile(APath);
    while True do
    begin
      BytesRead := F.Read(Buffer^, BUF_SIZE);
      if BytesRead <= 0 then Break;
      for i := 0 to BytesRead - 1 do
      begin
        if Byte(Buffer[i]) = TermB then
        begin
          FlushLine;
          LastWasLF := True;
        end
        else
        begin
          LastWasLF := False;
          EnsureLineCap(LineLen + 1);
          LineBuf[LineLen] := Buffer[i];
          Inc(LineLen);
        end;
      end;
      Inc(Processed, BytesRead);
      if Assigned(AOnProgress) and (FileSize > 0) then
      begin
        i := Integer((Processed * 100) div FileSize);
        if i > 100 then i := 100;
        if i > LastPct then
        begin
          LastPct := i;
          ReportScanProgress(AOnProgress, Processed, FileSize, Cancel);
          if Cancel then
          begin
            Result := False;
            Exit;
          end;
        end;
      end;
    end;
    if (FileSize > 0) and (not LastWasLF) and (LineLen > 0) then
      FlushLine;
    if Assigned(AOnProgress) then
      ReportScanProgress(AOnProgress, FileSize, FileSize, Cancel);
    Result := not Cancel;
    if Result then
      RememberScannedLineCount(APath, ATotalLines);
  except
    Result := False;
  end;
  if Assigned(F) then
    F.Free;
  if Buffer <> nil then
    FreeMem(Buffer);
end;

type
  PCollectMatchState = ^TCollectMatchState;
  TCollectMatchState = record
    Needle: RawByteString;
    NeedleText: string;
    Enc: string;
    WideCmp: Boolean;
    CaseSensitive: Boolean;
    MaxN, Got: Integer;
    Body: string;
  end;

function RawLineToUnicode(ALine: PAnsiChar; ALen: Integer; const Enc: string): string;
var
  A: AnsiString;
begin
  if (ALine = nil) or (ALen <= 0) then
  begin
    Result := '';
    Exit;
  end;
  SetString(A, ALine, ALen);
  Result := FileBytesToUnicodeText(A, Enc);
end;

procedure CollectMatchVisit(ALine: PAnsiChar; ALen: Integer; ALineNo: Int64;
  var AStop: Boolean; AUser: Pointer);
var
  St: PCollectMatchState;
  Raw: RawByteString;
  Hit: Boolean;
begin
  St := PCollectMatchState(AUser);
  if St.Got >= St.MaxN then
  begin
    AStop := True;
    Exit;
  end;
  if St.NeedleText = '' then Exit;
  if (ALine = nil) or (ALen <= 0) then Exit;
  SetString(Raw, ALine, ALen);
  if St.WideCmp then
    Hit := UnicodeLineMatches(Raw, St.NeedleText, St.Enc, St.CaseSensitive, False)
  else if St.CaseSensitive then
    Hit := Pos(St.Needle, Raw) > 0
  else
    Hit := AsciiContainsRaw(Raw, St.Needle);
  if not Hit then Exit;
  Inc(St.Got);
  if St.Body <> '' then
    St.Body := St.Body + #13#10;
  St.Body := St.Body + IntToStr(St.Got) + '. ' + RawLineToUnicode(ALine, ALen, St.Enc);
  if St.Got >= St.MaxN then
    AStop := True;
end;

function FastFileCollectMatchingLines(const APath, ANeedle: string;
  AMaxLines: Integer; ACaseSensitive: Boolean): string;
var
  St: TCollectMatchState;
begin
  Result := '';
  St.NeedleText := Trim(ANeedle);
  St.Enc := DetectTextFileEncoding(APath);
  St.Needle := UnicodeTextToFileBytes(St.NeedleText, St.Enc);
  St.CaseSensitive := ACaseSensitive;
  St.WideCmp := EncodingNeedsWideCompare(St.Enc, St.NeedleText) or (not ACaseSensitive);
  if (APath = '') or (not FileExists(APath)) or (St.NeedleText = '') then Exit;
  St.MaxN := AMaxLines;
  if St.MaxN < 1 then St.MaxN := 100;
  if St.MaxN > 500 then St.MaxN := 500;
  St.Got := 0;
  St.Body := '';
  FastFileForEachRawLine(APath, CollectMatchVisit, @St);
  Result := St.Body;
end;

function FastFileCountLines(const APath: string): Int64;
{ F5 index / prior assistant scan if valid; else one binary LF pass. }
const
  BUF_SIZE = 256 * 1024;
var
  F: TFileStream;
  Buffer: PAnsiChar;
  BytesRead: Integer;
  FileSize: Int64;
  LastWasLF: Boolean;
  LFShift: TBMHByteShiftTable;
  TermB: Byte;
begin
  Result := FastFileKnownLineCount(APath);
  if Result > 0 then Exit;
  if (APath = '') or (not FileExists(APath)) then Exit;
  F := nil;
  Buffer := nil;
  try
    GetMem(Buffer, BUF_SIZE);
    F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    FileSize := F.Size;
    BMHInitSingleByte(LFShift);
    LastWasLF := False;
    TermB := LineTermByteForFile(APath);
    while True do
    begin
      BytesRead := F.Read(Buffer^, BUF_SIZE);
      if BytesRead <= 0 then Break;
      Inc(Result, BMHCountBytePAnsi(Buffer, BytesRead, TermB, LFShift));
      LastWasLF := Byte(Buffer[BytesRead - 1]) = TermB;
    end;
    if (FileSize > 0) and (not LastWasLF) then
      Inc(Result);
    if Result > 0 then
      RememberScannedLineCount(APath, Result);
  except
    Result := 0;
  end;
  if Assigned(F) then
    F.Free;
  if Buffer <> nil then
    FreeMem(Buffer);
end;

function FastFileSessionPath(const ASafeSessionBaseName: string): string;
begin
  Result := FastFileTempPath(ASafeSessionBaseName + FASTFILE_SESSION_EXT);
end;

function FastFileRuntimeLogPath: string;
begin
  Result := FastFileTempPath(Format(FASTFILE_LOG_FILENAME_FORMAT,
    [FormatDateTime('ddmmyyyyhhnn', Now)]));
end;

function CleanupFastFileTempWorkFiles: Integer;
var
  Dir, Path: string;
  SR: TSearchRec;
  Found: Integer;

  procedure TryDeleteFile(const APath: string);
  begin
    if FileExists(APath) then
    begin
      if UnUtils.TryDeleteFileWithRetry(APath, 8, 60) then
        Inc(Result);
    end;
  end;

begin
  Result := 0;
  Dir := FastFileTempDir;
  if not DirectoryExists(Dir) then
    Exit;

  Found := FindFirst(Dir + FASTFILE_TEMP_WORK_GLOB, faAnyFile, SR);
  try
    while Found = 0 do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') and
         ((SR.Attr and faDirectory) = 0) then
        TryDeleteFile(Dir + SR.Name);
      Found := FindNext(SR);
    end;
  finally
    SysUtils.FindClose(SR);
  end;

  TryDeleteFile(FastFileTempPath(FASTFILE_MERGE_TEMP_FILE));
end;

function FileTimeToInt64(const FT: TFileTime): Int64;
begin
  Result := (Int64(FT.dwHighDateTime) shl 32) or FT.dwLowDateTime;
end;

function LineIndexCachePath: string;
begin
  Result := FastFileExeDirPath(TEMP_INDEX_META);
end;

function SourceSidecarCkptPath(const ASourcePath: string): string;
begin
  Result := FastFileTempPath(FastFileSafeNameFromPath(ASourcePath) +
    SOURCE_LINE_INDEX_CKPT_SUFFIX);
end;

function SourceSidecarMetaPath(const ASourcePath: string): string;
begin
  Result := FastFileTempPath(FastFileSafeNameFromPath(ASourcePath) +
    SOURCE_LINE_INDEX_META_SUFFIX);
end;

function LegacyBesideSourceCkptPath(const ASourcePath: string): string;
begin
  Result := ExpandFileName(ASourcePath) + SOURCE_LINE_INDEX_CKPT_SUFFIX;
end;

function LegacyBesideSourceMetaPath(const ASourcePath: string): string;
begin
  Result := ExpandFileName(ASourcePath) + SOURCE_LINE_INDEX_META_SUFFIX;
end;

procedure DeleteLegacyBesideSourceSidecars(const ASourcePath: string);
begin
  UnUtils.TryDeleteFileWithRetry(LegacyBesideSourceCkptPath(ASourcePath), 4, 30);
  UnUtils.TryDeleteFileWithRetry(LegacyBesideSourceMetaPath(ASourcePath), 4, 30);
end;

function WriteLineIndexMetaFile(const AMetaPath, ASourcePath: string;
  AFileSize, ALineCount: Int64; const AWriteTime: TFileTime): Boolean;
var
  SL: TStringList;
begin
  Result := False;
  SL := TStringList.Create;
  try
    SL.Add('V1');
    SL.Add(ASourcePath);
    SL.Add(IntToStr(AFileSize));
    SL.Add(IntToStr(FileTimeToInt64(AWriteTime)));
    SL.Add(IntToStr(ALineCount));
    SL.SaveToFile(AMetaPath);
    Result := True;
  except
    Result := False;
  end;
  SL.Free;
end;

function ReadLineIndexMetaFile(const AMetaPath, AExpectedPath: string;
  AFileSize: Int64; const AWriteTime: TFileTime; out ALineCount: Int64): Boolean;
var
  SL: TStringList;
  CachedSize, CachedTime, CachedLines: Int64;
begin
  Result := False;
  ALineCount := 0;
  if (AMetaPath = '') or (not FileExists(AMetaPath)) then Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AMetaPath);
    if SL.Count < 5 then Exit;
    if Trim(SL[0]) <> 'V1' then Exit;
    if not SameText(Trim(SL[1]), AExpectedPath) then Exit;
    CachedSize := StrToInt64Def(Trim(SL[2]), -1);
    CachedTime := StrToInt64Def(Trim(SL[3]), -1);
    CachedLines := StrToInt64Def(Trim(SL[4]), -1);
    if (CachedSize <> AFileSize) or (CachedLines <= 0) then Exit;
    if CachedTime <> FileTimeToInt64(AWriteTime) then Exit;
    ALineCount := CachedLines;
    Result := True;
  except
    Result := False;
    ALineCount := 0;
  end;
  SL.Free;
end;

function LineIndexCacheFilesReady(AFileSize: Int64): Boolean;
var
  CkptPath, DensePath: string;
begin
  CkptPath := FastFileExeDirPath(TEMP_CKPT_FILE);
  Result := FileExists(CkptPath) and (UnUtils.GetFileSize(CkptPath) >= 20);
  if not Result then Exit;
  if AFileSize > Int64(2) * 1024 * 1024 * 1024 then
    Exit;
  DensePath := FastFileExeDirPath(TEMPFILE);
  Result := FileExists(DensePath) and (UnUtils.GetFileSize(DensePath) >= 20);
end;

function CopyFileOverwrite(const AFrom, ATo: string): Boolean;
begin
  Result := False;
  if (AFrom = '') or (ATo = '') or (not FileExists(AFrom)) then Exit;
  Result := Windows.CopyFile(PChar(AFrom), PChar(ATo), False);
end;

function TryRestoreSourceSidecarToExeCache(const ASourcePath: string; AFileSize: Int64;
  const AWriteTime: TFileTime; out ALineCount: Int64): Boolean;
var
  Path, SideCkpt, SideMeta, ExeCkpt: string;
  UsedLegacy: Boolean;
begin
  Result := False;
  ALineCount := 0;
  UsedLegacy := False;
  { Dense temp.txt is too large to sidecar; persist only sparse ckpt for GB+ files. }
  if AFileSize <= Int64(2) * 1024 * 1024 * 1024 then Exit;
  Path := ExpandFileName(ASourcePath);
  SideCkpt := SourceSidecarCkptPath(Path);
  SideMeta := SourceSidecarMetaPath(Path);
  if not ReadLineIndexMetaFile(SideMeta, Path, AFileSize, AWriteTime, ALineCount) then
  begin
    SideCkpt := LegacyBesideSourceCkptPath(Path);
    SideMeta := LegacyBesideSourceMetaPath(Path);
    if not ReadLineIndexMetaFile(SideMeta, Path, AFileSize, AWriteTime, ALineCount) then
      Exit;
    UsedLegacy := True;
  end;
  if (not FileExists(SideCkpt)) or (UnUtils.GetFileSize(SideCkpt) < 20) then
  begin
    ALineCount := 0;
    Exit;
  end;
  ExeCkpt := FastFileExeDirPath(TEMP_CKPT_FILE);
  UnUtils.TryDeleteFileWithRetry(ExeCkpt, 6, 40);
  UnUtils.TryDeleteFileWithRetry(FastFileExeDirPath(TEMPFILE), 3, 20);
  if not CopyFileOverwrite(SideCkpt, ExeCkpt) then
  begin
    ALineCount := 0;
    Exit;
  end;
  WriteLineIndexMetaFile(LineIndexCachePath, Path, AFileSize, ALineCount, AWriteTime);
  Result := LineIndexCacheFilesReady(AFileSize);
  if not Result then
  begin
    ALineCount := 0;
    Exit;
  end;
  if UsedLegacy then
  begin
    CopyFileOverwrite(SideCkpt, SourceSidecarCkptPath(Path));
    WriteLineIndexMetaFile(SourceSidecarMetaPath(Path), Path, AFileSize, ALineCount, AWriteTime);
    DeleteLegacyBesideSourceSidecars(Path);
  end;
end;

function SaveLineIndexCache(const ASourcePath: string; AFileSize, ALineCount: Int64;
  const AWriteTime: TFileTime): Boolean;
var
  Path, CkptPath: string;
begin
  Result := False;
  Path := ExpandFileName(ASourcePath);
  if (Path = '') or (ALineCount <= 0) or (AFileSize <= 0) then Exit;
  Result := WriteLineIndexMetaFile(LineIndexCachePath, Path, AFileSize, ALineCount, AWriteTime);
  if not Result then Exit;
  if AFileSize <= Int64(2) * 1024 * 1024 * 1024 then Exit;
  CkptPath := FastFileExeDirPath(TEMP_CKPT_FILE);
  if not FileExists(CkptPath) then Exit;
  EnsureFastFileTempDir;
  CopyFileOverwrite(CkptPath, SourceSidecarCkptPath(Path));
  WriteLineIndexMetaFile(SourceSidecarMetaPath(Path), Path, AFileSize, ALineCount, AWriteTime);
  DeleteLegacyBesideSourceSidecars(Path);
end;

function LoadLineIndexCache(const ASourcePath: string; AFileSize: Int64;
  const AWriteTime: TFileTime; out ALineCount: Int64): Boolean;
var
  Path, MetaPath: string;
begin
  Result := False;
  ALineCount := 0;
  Path := ExpandFileName(ASourcePath);
  if Path = '' then Exit;
  MetaPath := LineIndexCachePath;
  if FileExists(MetaPath) and LineIndexCacheFilesReady(AFileSize) then
    Result := ReadLineIndexMetaFile(MetaPath, Path, AFileSize, AWriteTime, ALineCount);
  if Result then Exit;
  Result := TryRestoreSourceSidecarToExeCache(Path, AFileSize, AWriteTime, ALineCount);
end;

function CleanupFastFileLineIndexFiles: Integer;

  procedure TryDeleteIndexInDir(const ADir: string);
  var
  P: string;
  begin
    if ADir = '' then Exit;
    P := IncludeTrailingPathDelimiter(ADir) + TEMPFILE;
    if FileExists(P) and UnUtils.TryDeleteFileWithRetry(P, 12, 80) then
      Inc(Result);
    P := IncludeTrailingPathDelimiter(ADir) + TEMP_CKPT_FILE;
    if FileExists(P) and UnUtils.TryDeleteFileWithRetry(P, 12, 80) then
      Inc(Result);
    P := IncludeTrailingPathDelimiter(ADir) + TEMP_ZERO_SCAN_BLOCK_IDX;
    if FileExists(P) and UnUtils.TryDeleteFileWithRetry(P, 12, 80) then
      Inc(Result);
    P := IncludeTrailingPathDelimiter(ADir) + TEMP_FILTER_HITS_FILE;
    if FileExists(P) and UnUtils.TryDeleteFileWithRetry(P, 12, 80) then
      Inc(Result);
    P := IncludeTrailingPathDelimiter(ADir) + TEMP_INDEX_META;
    if FileExists(P) and UnUtils.TryDeleteFileWithRetry(P, 12, 80) then
      Inc(Result);
  end;

begin
  Result := 0;
  TryDeleteIndexInDir(ExtractFilePath(ParamStr(0)));
  if CompareText(ExtractFilePath(ParamStr(0)), ExtractFilePath(Application.ExeName)) <> 0 then
    TryDeleteIndexInDir(ExtractFilePath(Application.ExeName));
end;

end.
