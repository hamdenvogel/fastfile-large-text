program FastEditTest;

{ Valida uFastLineEdit: cada edicao e comparada com uma referencia em memoria
  (conteudo do ficheiro byte a byte, temp_ckpt.txt, temp.txt e numero de linhas
  gerados do zero). Tambem testa a reposicao a partir do diario.
  Uso: FastEditTest.exe            (testes de correcao, ~40 MB)
       FastEditTest.exe bench <GB> (tempos em ficheiro gerado de <GB> GB) }

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, Math, UnConsts, UnBufferedTextWriter, uFastFilePaths,
  UnUtils, uFastLineEdit;

var
  Fails: Integer;
  DataPath: string;
  Cur: TBytes;

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

function LoadFile(const APath: string): TBytes;
var
  F: TFileStream;
begin
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, F.Size);
    if F.Size > 0 then
      F.ReadBuffer(Result[0], F.Size);
  finally
    F.Free;
  end;
end;

procedure SaveFile(const APath: string; const AData: TBytes);
var
  F: TFileStream;
begin
  F := TFileStream.Create(APath, fmCreate);
  try
    if Length(AData) > 0 then
      F.WriteBuffer(AData[0], Length(AData));
  finally
    F.Free;
  end;
end;

function SameBytes(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function CountTerms(const AData: TBytes): Int64;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(AData) do
    if AData[I] = 10 then
      Inc(Result);
end;

{ Indices no formato do leitor (TReadFileThread). }
procedure BuildIndex(const AData: TBytes; const ADensePath, ACkptPath: string);
var
  D, C: TBufferedTextWriter;
  I: Integer;
  N: Int64;
begin
  D := nil;
  if ADensePath <> '' then
    D := TBufferedTextWriter.Create(ADensePath);
  C := TBufferedTextWriter.Create(ACkptPath);
  try
    if D <> nil then D.WriteOffsetDirect(1);
    C.WriteOffsetDirect(1);
    N := 0;
    for I := 0 to High(AData) do
      if AData[I] = 10 then
      begin
        Inc(N);
        if D <> nil then D.WriteOffsetDirect(Int64(I) + 2);
        if (N and (CKPT_INTERVAL - 1)) = 0 then
          C.WriteOffsetDirect(Int64(I) + 2);
      end;
  finally
    C.Free;
    D.Free;
  end;
end;

procedure Setup(const AData: TBytes; const AWithDense: Boolean);
var
  Wt: TFileTime;
  Sz: Int64;
  Dense: string;
begin
  SaveFile(DataPath, AData);
  Dense := '';
  if AWithDense then
    Dense := FastFileExeDirPath(TEMPFILE)
  else
    DeleteFile(FastFileExeDirPath(TEMPFILE));
  BuildIndex(AData, Dense, FastFileExeDirPath(TEMP_CKPT_FILE));
  GetFileSizeAndWriteTime(DataPath, Sz, Wt);
  SaveLineIndexCache(DataPath, Sz, CountTerms(AData) + 1, Wt);
end;

function LineStart(const AData: TBytes; const ALine: Int64): Int64;
var
  Need: Int64;
  I: Integer;
begin
  Need := ALine - 1;
  if Need <= 0 then Exit(0);
  for I := 0 to High(AData) do
    if AData[I] = 10 then
    begin
      Dec(Need);
      if Need = 0 then
        Exit(I + 1);
    end;
  Result := Length(AData);
end;

function Splice(const AData: TBytes; const S, E: Int64; const APayload: RawByteString): TBytes;
var
  L: Integer;
begin
  L := Length(APayload);
  SetLength(Result, Length(AData) - (E - S) + L);
  if S > 0 then Move(AData[0], Result[0], S);
  if L > 0 then Move(APayload[1], Result[S], L);
  if Length(AData) - E > 0 then
    Move(AData[E], Result[S + L], Length(AData) - E);
end;

function RefEdit(const AData: TBytes; const AKind: TFastEditKind; const ALine, ASpan: Int64;
  const APayload: RawByteString): TBytes;
var
  S, E: Int64;
begin
  if (AKind = fekInsert) and (ALine < 1) then
    S := Length(AData)
  else
    S := LineStart(AData, ALine);
  case AKind of
    fekInsert: E := S;
    fekReplace: E := LineStart(AData, ALine + 1);
  else
    E := LineStart(AData, ALine + ASpan);
  end;
  Result := Splice(AData, S, E, APayload);
end;

function MakeLines(const ATag: string; const ACount, ALen: Integer): RawByteString;
var
  I: Integer;
  S: RawByteString;
begin
  Result := '';
  for I := 1 to ACount do
  begin
    S := RawByteString(Format('%s-%d-', [ATag, I]));
    while Length(S) < ALen do
      S := S + 'x';
    Result := Result + S + #13#10;
  end;
end;

procedure CheckIndexes(const AData: TBytes; const AWithDense: Boolean; const AName: string);
var
  RefDense, RefCkpt: string;
  Wt: TFileTime;
  Sz, Lines: Int64;
begin
  RefDense := '';
  if AWithDense then
    RefDense := FastFileExeDirPath('ref_dense.txt');
  RefCkpt := FastFileExeDirPath('ref_ckpt.txt');
  BuildIndex(AData, RefDense, RefCkpt);
  Check(SameBytes(LoadFile(RefCkpt), LoadFile(FastFileExeDirPath(TEMP_CKPT_FILE))),
    AName + ': checkpoint index');
  if AWithDense then
    Check(SameBytes(LoadFile(RefDense), LoadFile(FastFileExeDirPath(TEMPFILE))),
      AName + ': dense index');
  GetFileSizeAndWriteTime(DataPath, Sz, Wt);
  Check(ReadLineIndexMetaFile(LineIndexCachePath, ExpandFileName(DataPath), Sz, Wt, Lines) and
    (Lines = CountTerms(AData) + 1), AName + ': index meta');
end;

procedure RunCase(const AName: string; const AKind: TFastEditKind; const ALine, ASpan: Int64;
  const APayload: RawByteString; const AExpect: TFastEditMode; const AWithDense: Boolean);
var
  Req: TFastEditRequest;
  Res: TFastEditResult;
  Ref, Got: TBytes;
  Ok: Boolean;
begin
  Ref := RefEdit(Cur, AKind, ALine, ASpan, APayload);
  Req.FileName := DataPath;
  Req.Kind := AKind;
  Req.TargetLine := ALine;
  Req.SpanLines := ASpan;
  Req.Payload := APayload;
  Req.TermByte := 10;
  Ok := TryFastLineEdit(Req, Res, nil, nil);
  Check(Ok, AName + ': applied');
  if not Ok then Exit;
  Check(Res.Mode = AExpect, Format('%s: mode %d (expected %d) locate=%dms data=%dms',
    [AName, Ord(Res.Mode), Ord(AExpect), Res.LocateMs, Res.DataMs]));
  Got := LoadFile(DataPath);
  Check(SameBytes(Got, Ref), AName + ': file content');
  Check(Res.LineCountAfter = CountTerms(Ref) + 1, AName + ': line count');
  CheckIndexes(Ref, AWithDense, AName);
  Cur := Ref;
end;

function LineBytes(const AData: TBytes; const ALine: Int64): RawByteString;
var
  S, E: Int64;
begin
  S := LineStart(AData, ALine);
  E := LineStart(AData, ALine + 1);
  SetLength(Result, E - S);
  if E > S then
    Move(AData[S], Result[1], E - S);
end;

procedure GenerateBase(const ABytes: Int64; out AData: TBytes);
var
  P, L, I: Integer;
begin
  RandSeed := 12345;
  SetLength(AData, ABytes + 256);
  P := 0;
  while P < ABytes do
  begin
    L := Random(121);
    for I := 0 to L - 1 do
      AData[P + I] := Ord('a') + Random(26);
    Inc(P, L);
    AData[P] := 13;
    AData[P + 1] := 10;
    Inc(P, 2);
  end;
  SetLength(AData, P);
end;

{ Referencia da mescla: o mesmo resultado que o caminho completo de TMergeDeltaThread. }
function RefMerge(const AData: TBytes; const AEntries: TFastReplaceEntries): TBytes;
var
  Starts: TArray<Int64>;
  N, I, J, Existing: Int64;
  K: Integer;
  M: TBytesStream;
  Cur, S, E: Int64;
  Eol: RawByteString;
begin
  Eol := #13#10;
  SetLength(Starts, Length(AData) + 2);
  N := 0;
  Starts[0] := 0;
  for I := 0 to High(AData) do
    if AData[I] = 10 then
    begin
      Inc(N);
      Starts[N] := I + 1;
    end;
  Existing := N;
  if (Length(AData) > 0) and (AData[High(AData)] <> 10) then
  begin
    Inc(Existing);
    Starts[Existing] := Length(AData);
  end;
  M := TBytesStream.Create;
  try
    Cur := 0;
    K := 0;
    while (K < Length(AEntries)) and (AEntries[K].Line <= Existing) do
    begin
      S := Starts[AEntries[K].Line - 1];
      E := Starts[AEntries[K].Line];
      if S > Cur then M.WriteBuffer(AData[Cur], S - Cur);
      M.WriteBuffer(AEntries[K].Payload[1], Length(AEntries[K].Payload));
      Cur := E;
      Inc(K);
    end;
    if Length(AData) > Cur then M.WriteBuffer(AData[Cur], Length(AData) - Cur);
    J := Existing + 1;
    while K < Length(AEntries) do
    begin
      while J < AEntries[K].Line do
      begin
        M.WriteBuffer(Eol[1], 2);
        Inc(J);
      end;
      M.WriteBuffer(AEntries[K].Payload[1], Length(AEntries[K].Payload));
      J := AEntries[K].Line + 1;
      Inc(K);
    end;
    Result := Copy(M.Bytes, 0, M.Size);
  finally
    M.Free;
  end;
end;

procedure RunMergeCase(const AName: string; const AEntries: TFastReplaceEntries;
  const AExpect: TFastEditMode);
var
  Res: TFastEditResult;
  Ref: TBytes;
  Ok: Boolean;
begin
  Ref := RefMerge(Cur, AEntries);
  Ok := TryFastMultiReplace(DataPath, 10, #13#10, AEntries, Res, nil, nil);
  Check(Ok, AName + ': applied');
  if not Ok then Exit;
  Check(Res.Mode = AExpect, Format('%s: mode %d (expected %d) locate=%dms data=%dms',
    [AName, Ord(Res.Mode), Ord(AExpect), Res.LocateMs, Res.DataMs]));
  Check(SameBytes(LoadFile(DataPath), Ref), AName + ': file content');
  Check(Res.LineCountAfter = CountTerms(Ref) + 1, AName + ': line count');
  CheckIndexes(Ref, True, AName);
  Cur := Ref;
end;

function Entries(const ALines: array of Int64; const ATag: string): TFastReplaceEntries;
var
  I: Integer;
begin
  SetLength(Result, Length(ALines));
  for I := 0 to High(ALines) do
  begin
    Result[I].Line := ALines[I];
    Result[I].Payload := MakeLines(ATag + IntToStr(I), 1, 10 + (I mod 50));
  end;
end;

procedure RunMergeTests;
var
  Lines: Int64;
  L: TArray<Int64>;
  E: TFastReplaceEntries;
  I: Integer;
begin
  Writeln('--- merge (multi replace) ---');
  Setup(Cur, True);
  Lines := CountTerms(Cur);
  SetLength(L, 2000);
  for I := 0 to High(L) do
    L[I] := Lines - 200000 + Int64(I) * 97;
  RunMergeCase('merge: 2000 lines in the tail', Entries(L, 'T'), femShift);

  Lines := CountTerms(Cur);
  RunMergeCase('merge: near start + end', Entries([5, 1024, 1025, 2049, Lines - 3], 'S'), femRewrite);

  Lines := CountTerms(Cur);
  SetLength(E, 300);
  for I := 0 to High(E) do
  begin
    E[I].Line := 1000 + Int64(I) * 1500;
    E[I].Payload := LineBytes(Cur, E[I].Line);
    if Length(E[I].Payload) > 2 then
      E[I].Payload[1] := '#';
  end;
  RunMergeCase('merge: same length scattered', E, femInPlace);

  Lines := CountTerms(Cur);
  RunMergeCase('merge: tail + beyond EOF padding',
    Entries([Lines - 10, Lines, Lines + 3, Lines + 7], 'P'), femShift);
  Lines := CountTerms(Cur);
  RunMergeCase('merge: only beyond EOF', Entries([Lines + 1, Lines + 2], 'B'), femShift);

  SetLength(Cur, Length(Cur) - 2);
  Setup(Cur, True);
  Lines := CountTerms(Cur) + 1;
  RunMergeCase('merge: no EOL, last line + beyond',
    Entries([Lines - 1, Lines, Lines + 2], 'N'), femShift);
end;

procedure TestJournalRecovery;
var
  J: TFileStream;
  Orig, Garbled: TBytes;
  St, OldSize: Int64;
  State, PathLen: Integer;
  Path: string;
  Magic: AnsiString;
begin
  Orig := Copy(Cur);
  St := Length(Orig) - 5000000;
  OldSize := Length(Orig);
  Path := ExpandFileName(DataPath);
  J := TFileStream.Create(EnsureFastFileTempDir + 'ff_edit_test.ffj', fmCreate);
  try
    Magic := 'FFJ1';
    J.WriteBuffer(Magic[1], 4);
    State := 1;
    J.WriteBuffer(State, 4);
    J.WriteBuffer(St, 8);
    J.WriteBuffer(OldSize, 8);
    PathLen := Length(Path);
    J.WriteBuffer(PathLen, 4);
    J.WriteBuffer(Path[1], PathLen * SizeOf(Char));
    J.WriteBuffer(Orig[St], OldSize - St);
  finally
    J.Free;
  end;
  { Simula queda a meio do deslocamento: cauda truncada e lixo no meio. }
  Garbled := Copy(Orig, 0, St + 1234567);
  FillChar(Garbled[St + 10], 1000, Ord('#'));
  SaveFile(DataPath, Garbled);
  Check(RecoverInterruptedFastEdits = 1, 'journal: one file restored');
  Check(SameBytes(LoadFile(DataPath), Orig), 'journal: original content back');
  Check(not FileExists(EnsureFastFileTempDir + 'ff_edit_test.ffj'), 'journal: removed');
end;

procedure RunCorrectness;
var
  Lines: Int64;
  P: RawByteString;
  I: Integer;
  Req: TFastEditRequest;
  Res: TFastEditResult;
  Wt: TFileTime;
begin
  GenerateBase(40 * 1024 * 1024, Cur);
  Lines := CountTerms(Cur);
  Writeln(Format('base: %d bytes, %d lines', [Length(Cur), Lines]));

  Setup(Cur, True);
  P := LineBytes(Cur, 100);
  for I := 1 to Length(P) - 2 do
    P[I] := UpCase(P[I]);
  RunCase('replace same length', fekReplace, 100, 1, P, femInPlace, True);
  RunCase('replace near start', fekReplace, 10, 1, MakeLines('R10', 1, 300), femRewrite, True);
  RunCase('replace near end', fekReplace, Lines - 1000, 1, MakeLines('RE', 1, 500), femShift, True);
  RunCase('delete span near end', fekDelete, Lines - 5000, 3000, '', femShift, True);
  RunCase('insert before line 1', fekInsert, 1, 1, MakeLines('I1', 5, 40), femRewrite, True);
  RunCase('append (line 0)', fekInsert, 0, 1, MakeLines('AP', 3, 20), femShift, True);
  Lines := CountTerms(Cur);
  RunCase('insert beyond EOF', fekInsert, Lines + 10, 1, MakeLines('BE', 2, 20), femShift, True);
  RunCase('delete line 1', fekDelete, 1, 1, '', femRewrite, True);
  Lines := CountTerms(Cur);
  RunCase('replace with 3 lines', fekReplace, Lines - 10, 1, MakeLines('M', 3, 30), femShift, True);
  RunCase('replace ckpt boundary', fekReplace, 1025, 1, MakeLines('CB', 1, 7), femRewrite, True);
  RunCase('delete across ckpts', fekDelete, Lines - 4097, 2049, '', femShift, True);

  Req.FileName := DataPath;
  Req.Kind := fekReplace;
  Req.TargetLine := CountTerms(Cur) + 5;
  Req.SpanLines := 1;
  Req.Payload := 'x'#13#10;
  Req.TermByte := 10;
  Check(TryFastLineEdit(Req, Res, nil, nil) and (Res.Mode = femNone) and
    (not Res.TargetExists) and (Res.ExistingLines = CountTerms(Cur)),
    'replace beyond EOF: reported, nothing changed');
  Check(SameBytes(LoadFile(DataPath), Cur), 'replace beyond EOF: file intact');
  Req.Kind := fekDelete;
  Req.Payload := '';
  Check(not TryFastLineEdit(Req, Res, nil, nil), 'delete beyond EOF: falls back');

  Writeln('--- checkpoint only (no dense index) ---');
  Setup(Cur, False);
  Lines := CountTerms(Cur);
  RunCase('ckpt: replace near start', fekReplace, 3, 1, MakeLines('C3', 1, 99), femRewrite, False);
  RunCase('ckpt: replace near end', fekReplace, Lines - 3, 1, MakeLines('CE', 2, 10), femShift, False);
  RunCase('ckpt: delete near end', fekDelete, Lines - 2000, 1500, '', femShift, False);
  RunCase('ckpt: append', fekInsert, 0, 1, MakeLines('CA', 1, 10), femShift, False);
  Check(not FileExists(FastFileExeDirPath(TEMPFILE)), 'ckpt: no dense index created');

  Writeln('--- last line without terminator ---');
  SetLength(Cur, Length(Cur) - 2);
  Setup(Cur, True);
  Lines := CountTerms(Cur) + 1;
  RunCase('no EOL: replace last line', fekReplace, Lines, 1, MakeLines('LL', 1, 10), femShift, True);
  SetLength(Cur, Length(Cur) - 2);
  Setup(Cur, True);
  RunCase('no EOL: append glues to last line', fekInsert, 0, 1, MakeLines('G', 1, 5), femShift, True);
  SetLength(Cur, Length(Cur) - 2);
  Setup(Cur, True);
  Lines := CountTerms(Cur) + 1;
  RunCase('no EOL: delete last line', fekDelete, Lines, 1, '', femShift, True);

  Writeln('--- stale index ---');
  Wt.dwLowDateTime := 0;
  Wt.dwHighDateTime := 0;
  SaveFile(DataPath, Cur);
  Req.Kind := fekReplace;
  Req.TargetLine := 5;
  Req.Payload := 'stale'#13#10;
  Check(not TryFastLineEdit(Req, Res, nil, nil), 'stale meta: falls back');

  RunMergeTests;

  Writeln('--- journal ---');
  Setup(Cur, True);
  TestJournalRecovery;
end;

procedure RunBench(const AGigs: Integer);
const
  LINE: RawByteString = 'bench line with some payload text 0123456789 abcdefghijklmnopqrstuvwxyz'#13#10;
var
  F: TFileStream;
  Block: TBytes;
  I, N, Reps: Integer;
  Target, Done: Int64;
  Req: TFastEditRequest;
  Res: TFastEditResult;
  Lines, T0: Int64;
  Wt: TFileTime;
  Sz: Int64;
  C, D: TBufferedTextWriter;
  Buf: TBytes;
  Rd, J: Integer;
  Pos, Term: Int64;

  procedure Edit(const AName: string; const AKind: TFastEditKind; const ALine: Int64;
    const APayload: RawByteString);
  begin
    Req.FileName := DataPath;
    Req.Kind := AKind;
    Req.TargetLine := ALine;
    Req.SpanLines := 1;
    Req.Payload := APayload;
    Req.TermByte := 10;
    T0 := GetTickCount64;
    if TryFastLineEdit(Req, Res, nil, nil) then
      Writeln(Format('%-28s mode=%d locate=%dms data=%dms total=%dms',
        [AName, Ord(Res.Mode), Res.LocateMs, Res.DataMs, Int64(GetTickCount64) - T0]))
    else
      Writeln(AName, ': not applied');
  end;

begin
  Target := Int64(AGigs) * 1024 * 1024 * 1024;
  Reps := (4 * 1024 * 1024) div Length(LINE);
  SetLength(Block, Reps * Length(LINE));
  for I := 0 to Reps - 1 do
    Move(LINE[1], Block[I * Length(LINE)], Length(LINE));
  Writeln('generating ', AGigs, ' GB ...');
  F := TFileStream.Create(DataPath, fmCreate);
  try
    Done := 0;
    while Done < Target do
    begin
      F.WriteBuffer(Block[0], Length(Block));
      Inc(Done, Length(Block));
    end;
  finally
    F.Free;
  end;
  Lines := Done div Length(LINE);
  Writeln('indexing (reference) ...');
  DeleteFile(FastFileExeDirPath(TEMPFILE));
  C := TBufferedTextWriter.Create(FastFileExeDirPath(TEMP_CKPT_FILE));
  D := nil;
  try
    C.WriteOffsetDirect(1);
    F := TFileStream.Create(DataPath, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Buf, 8 * 1024 * 1024);
      Pos := 0;
      Term := 0;
      repeat
        Rd := F.Read(Buf[0], Length(Buf));
        for J := 0 to Rd - 1 do
          if Buf[J] = 10 then
          begin
            Inc(Term);
            if (Term and (CKPT_INTERVAL - 1)) = 0 then
              C.WriteOffsetDirect(Pos + J + 2);
          end;
        Inc(Pos, Rd);
      until Rd = 0;
    finally
      F.Free;
    end;
  finally
    C.Free;
    D.Free;
  end;
  GetFileSizeAndWriteTime(DataPath, Sz, Wt);
  SaveLineIndexCache(DataPath, Sz, Lines + 1, Wt);
  Writeln(Format('file: %d bytes, %d lines', [Sz, Lines]));

  N := 0;
  Edit('replace same length (mid)', fekReplace, Lines div 2,
    'BENCH LINE WITH SOME PAYLOAD TEXT 0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ'#13#10);
  Edit('replace longer (95%)', fekReplace, (Lines div 100) * 95, 'longer replacement line ' + LINE);
  Edit('insert (95%)', fekInsert, (Lines div 100) * 95, 'inserted'#13#10);
  Edit('delete (95%)', fekDelete, (Lines div 100) * 95 + 1, '');
  Edit('append', fekInsert, 0, 'appended'#13#10);
  Edit('replace longer (60%)', fekReplace, (Lines div 100) * 60, 'longer replacement line ' + LINE);
  Edit('insert (line 10)', fekInsert, 10, 'inserted at top'#13#10);
  Inc(N);
end;

begin
  Fails := 0;
  DataPath := ExtractFilePath(ParamStr(0)) + 'fe_data.txt';
  try
    if (ParamCount >= 2) and SameText(ParamStr(1), 'bench') then
      RunBench(StrToIntDef(ParamStr(2), 4))
    else
      RunCorrectness;
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Inc(Fails);
    end;
  end;
  Writeln(Format('fails=%d', [Fails]));
  ExitCode := Fails;
end.
