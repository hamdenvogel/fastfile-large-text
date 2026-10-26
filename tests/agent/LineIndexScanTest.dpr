program LineIndexScanTest;

{ Compara os indices gerados por TryParallelLineIndexScan e pelo caminho
  sequencial (ScanBufferForLineFeeds) com uma referencia byte a byte.
  Uso: LineIndexScanTest.exe [bench <ficheiro>] }

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, uMMF, UnBufferedTextWriter, uZeroScanBlockIndex,
  UnConsts, uLineIndexScan;

type
  TMode = (mDense, mCkptOnly, mCkptBlocks);

const
  MODE_NAMES: array[TMode] of string = ('dense+ckpt', 'ckpt-only', 'ckpt+blocks');

var
  Dir: string;
  Fails: Integer;

procedure Check(const ACond: Boolean; const AName: string);
begin
  if ACond then
    Writeln('ok   ', AName)
  else
  begin
    Writeln('FAIL ', AName);
    Inc(Fails);
  end;
end;

function SameFiles(const A, B: string): Boolean;
const
  BUF = 8 * 1024 * 1024;
var
  FA, FB: TFileStream;
  X, Y: TBytes;
  NA, NB: Integer;
begin
  FA := TFileStream.Create(A, fmOpenRead or fmShareDenyNone);
  FB := TFileStream.Create(B, fmOpenRead or fmShareDenyNone);
  try
    Result := FA.Size = FB.Size;
    SetLength(X, BUF);
    SetLength(Y, BUF);
    while Result do
    begin
      NA := FA.Read(X[0], BUF);
      NB := FB.Read(Y[0], BUF);
      Result := (NA = NB) and ((NA = 0) or CompareMem(@X[0], @Y[0], NA));
      if NA = 0 then
        Break;
    end;
  finally
    FA.Free;
    FB.Free;
  end;
end;

function Max(A, B: Integer): Integer;
begin
  if A > B then Result := A else Result := B;
end;

{ Gera um ficheiro de teste com ATotal bytes. }
procedure MakeFile(const APath: string; const ATotal: Int64; const AKind: Integer);
const
  BUF = 4 * 1024 * 1024;
var
  F: TFileStream;
  B: TBytes;
  Written: Int64;
  I, N, LineLen: Integer;
begin
  RandSeed := 12345 + AKind;
  F := TFileStream.Create(APath, fmCreate);
  try
    SetLength(B, BUF);
    Written := 0;
    LineLen := 0;
    while Written < ATotal do
    begin
      N := BUF;
      if Written + N > ATotal then
        N := Integer(ATotal - Written);
      for I := 0 to N - 1 do
      begin
        case AKind of
          0: { linhas mistas LF / CRLF, vazias, $0B logo apos LF }
            begin
              if (LineLen > 0) and (Random(Max(1, 200 - LineLen)) = 0) or (LineLen > 400) then
              begin
                B[I] := 10;
                LineLen := 0;
              end
              else
              begin
                case Random(40) of
                  0: B[I] := 13;
                  1: B[I] := $0B;
                  2: B[I] := $0A xor $01; { $0B outra vez }
                else
                  B[I] := 32 + Random(90);
                end;
                if (LineLen = 0) and (Random(50) = 0) then
                  B[I] := 10
                else
                  Inc(LineLen);
              end;
            end;
          1: { so quebras de linha }
            B[I] := 10;
          2: { terminador CR }
            if Random(80) = 0 then B[I] := 13 else B[I] := 65 + Random(26);
        end;
      end;
      F.WriteBuffer(B[0], N);
      Inc(Written, N);
    end;
  finally
    F.Free;
  end;
end;

{ Referencia: le byte a byte e aplica as mesmas regras de TReadFileThread. }
procedure BuildReference(const AFile: string; const AMode: TMode; const ATerm: Byte;
  const ADense, ACkpt: string; out ALines: Int64);
const
  BUF = 8 * 1024 * 1024;
var
  F: TFileStream;
  B: TBytes;
  Pos0, LineOff: Int64;
  N, I: Integer;
  Idx, Ck: TBufferedTextWriter;
  Blk: TZeroScanBlockIndexWriter;
begin
  ALines := 0;
  Idx := nil;
  Blk := nil;
  if AMode = mDense then
    Idx := TBufferedTextWriter.Create(ADense, 16 * 1024 * 1024);
  Ck := TBufferedTextWriter.Create(ACkpt, 8 * 1024 * 1024);
  if AMode = mCkptBlocks then
    Blk := TZeroScanBlockIndexWriter.Create;
  F := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
  try
    if F.Size > 0 then
    begin
      if Idx <> nil then Idx.WriteOffsetDirect(1);
      Ck.WriteOffsetDirect(1);
    end;
    SetLength(B, BUF);
    Pos0 := 0;
    repeat
      N := F.Read(B[0], BUF);
      for I := 0 to N - 1 do
        if B[I] = ATerm then
        begin
          Inc(ALines);
          LineOff := Pos0 + I + 2;
          if Idx <> nil then Idx.WriteOffsetDirect(LineOff);
          if Blk <> nil then Blk.NoteLineStart1Based(LineOff, Pos0 + I);
          if (ALines and (CKPT_INTERVAL - 1)) = 0 then
            Ck.WriteOffsetDirect(LineOff);
        end;
      Inc(Pos0, N);
    until N = 0;
  finally
    F.Free;
    Idx.Free;
    Ck.Free;
    if Blk <> nil then
    begin
      Blk.FinalizeIndex;
      Blk.Free;
    end;
  end;
end;

type
  { pSeq: caminho sequencial de producao (ScanBufferForLineFeeds);
    pMmf: pipeline paralelo com MMF; pDirect: pipeline com leitura directa forcada. }
  TPath = (pSeq, pMmf, pDirect);

const
  PATH_NAMES: array[TPath] of string = ('sequential', 'mmf', 'direct');

function BuildIndex(const AFile: string; const AMode: TMode; const ATerm: Byte;
  const ADense, ACkpt: string; const APath: TPath; out ALines: Int64;
  out AUsedParallel: Boolean): Cardinal;
var
  Idx, Ck: TBufferedTextWriter;
  Blk: TZeroScanBlockIndexWriter;
  Bundle: TLineIndexWriterBundle;
  Size, Abs: Int64;
  MMF: TMMFReader;
  P: PByte;
  Contig: Cardinal;
  Lines: Int64;
  Workers: Integer;
  T0: Cardinal;
  Fs: TFileStream;
begin
  T0 := GetTickCount;
  Lines := 0;
  Idx := nil;
  Blk := nil;
  if AMode = mDense then
    Idx := TBufferedTextWriter.Create(ADense, 16 * 1024 * 1024);
  Ck := TBufferedTextWriter.Create(ACkpt, 8 * 1024 * 1024);
  if AMode = mCkptBlocks then
    Blk := TZeroScanBlockIndexWriter.Create;
  try
    Fs := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
    try
      Size := Fs.Size;
    finally
      Fs.Free;
    end;
    if Size > 0 then
    begin
      if Idx <> nil then Idx.WriteOffsetDirect(1);
      Ck.WriteOffsetDirect(1);
    end;
    Bundle.IdxW := Idx;
    Bundle.CkptW := Ck;
    Bundle.BlkW := Blk;
    Bundle.SparseCkptOnly := AMode = mCkptOnly;
    case APath of
      pMmf: GLineIndexDirectReadMode := ldOff;
      pDirect: GLineIndexDirectReadMode := ldOn;
    end;
    AUsedParallel := (APath <> pSeq) and TryParallelLineIndexScan(AFile, Size, Lines,
      Bundle, nil, nil, Workers, ATerm);
    GLineIndexDirectReadMode := ldAuto;
    if not AUsedParallel then
    begin
      MMF := TMMFReader.Create(AFile);
      try
        Abs := 0;
        while Abs < Size do
        begin
          P := MMF.PtrAt(Abs, 1, Contig);
          ScanBufferForLineFeeds(P, Contig, Abs,
            procedure(const ALf: Int64)
            begin
              Inc(Lines);
              if Idx <> nil then Idx.WriteOffsetDirect(ALf + 2);
              if Blk <> nil then Blk.NoteLineStart1Based(ALf + 2, ALf);
              if (Lines and (CKPT_INTERVAL - 1)) = 0 then
                Ck.WriteOffsetDirect(ALf + 2);
            end, ATerm);
          Inc(Abs, Contig);
        end;
      finally
        MMF.Free;
      end;
    end;
  finally
    Idx.Free;
    Ck.Free;
    if Blk <> nil then
    begin
      Blk.FinalizeIndex;
      Blk.Free;
    end;
  end;
  ALines := Lines;
  Result := GetTickCount - T0;
end;

procedure RunCase(const AName, AFile: string; const ATerm: Byte);
var
  M: TMode;
  RefLines, Lines: Int64;
  Used: Boolean;
  Ms: Cardinal;
  P: TPath;
begin
  for M := Low(TMode) to High(TMode) do
  begin
    BuildReference(AFile, M, ATerm, Dir + 'ref_dense.txt', Dir + 'ref_ckpt.txt', RefLines);
    if M = mCkptBlocks then
      CopyFile(PChar(ZeroScanBlockIndexPath), PChar(Dir + 'ref_blk.bin'), False);
    for P := Low(TPath) to High(TPath) do
    begin
      Ms := BuildIndex(AFile, M, ATerm, Dir + 'got_dense.txt', Dir + 'got_ckpt.txt',
        P, Lines, Used);
      Check(Used = (P <> pSeq), Format('%s %s %s parallel used=%s',
        [AName, MODE_NAMES[M], PATH_NAMES[P], BoolToStr(Used, True)]));
      Check(Lines = RefLines, Format('%s %s %s lines %d = %d (%d ms)',
        [AName, MODE_NAMES[M], PATH_NAMES[P], Lines, RefLines, Ms]));
      Check(SameFiles(Dir + 'ref_ckpt.txt', Dir + 'got_ckpt.txt'),
        Format('%s %s %s ckpt', [AName, MODE_NAMES[M], PATH_NAMES[P]]));
      if M = mDense then
        Check(SameFiles(Dir + 'ref_dense.txt', Dir + 'got_dense.txt'),
          Format('%s %s %s dense', [AName, MODE_NAMES[M], PATH_NAMES[P]]));
      if M = mCkptBlocks then
        Check(SameFiles(Dir + 'ref_blk.bin', ZeroScanBlockIndexPath),
          Format('%s %s %s blocks', [AName, MODE_NAMES[M], PATH_NAMES[P]]));
    end;
  end;
end;

function GetFileSizeOf(const AFile: string): Int64;
var
  F: TFileStream;
begin
  F := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
  try
    Result := F.Size;
  finally
    F.Free;
  end;
end;

{ Uso: bench <ficheiro> [mmf|direct|seq|all] [depth]  (default: mmf e direct, ckpt-only) }
procedure Bench(const AFile: string);
var
  Lines: Int64;
  Used: Boolean;
  Ms: Cardinal;
  P: TPath;
  What: string;
  Depth: Integer;
begin
  What := LowerCase(ParamStr(3));
  Depth := StrToIntDef(ParamStr(4), 0);
  if Depth > 0 then
    GLineIndexDirectQueueDepth := Depth;
  Writeln(Format('threshold(direct)=%d MB  depth=%d',
    [LineIndexDirectReadThresholdBytes div (1024 * 1024), GLineIndexDirectQueueDepth]));
  for P := Low(TPath) to High(TPath) do
  begin
    if (What = '') and (P = pSeq) then Continue;
    if (What <> '') and (What <> 'all') and (Pos(What, PATH_NAMES[P]) <> 1) then Continue;
    Ms := BuildIndex(AFile, mCkptOnly, 10, Dir + 'got_dense.txt', Dir + 'got_ckpt.txt',
      P, Lines, Used);
    Writeln(Format('bench %-10s %-10s used=%-5s lines=%d ms=%d  (%d MB/s)',
      [MODE_NAMES[mCkptOnly], PATH_NAMES[P], BoolToStr(Used, True), Lines, Ms,
       GetFileSizeOf(AFile) div (1024 * 1024) * 1000 div Int64(Max(1, Integer(Ms)))]));
  end;
end;

var
  F1, F2, F3: string;
begin
  Fails := 0;
  Dir := ExtractFilePath(ParamStr(0)) + 'lisdata\';
  ForceDirectories(Dir);
  try
    if (ParamCount >= 2) and SameText(ParamStr(1), 'bench') then
    begin
      Bench(ParamStr(2));
      Exit;
    end;
    F1 := Dir + 'mixed.txt';
    F2 := Dir + 'allnl.txt';
    F3 := Dir + 'cr.txt';
    MakeFile(F1, Int64(300) * 1024 * 1024 + 37, 0);
    MakeFile(F2, Int64(140) * 1024 * 1024 + 5, 1);
    MakeFile(F3, Int64(150) * 1024 * 1024 + 63, 2);
    RunCase('mixed', F1, 10);
    RunCase('allnl', F2, 10);
    RunCase('cr', F3, 13);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Inc(Fails);
    end;
  end;
  Writeln('fails=', Fails);
  ExitCode := Fails;
end.
