unit uFileSessionHistory;

{
  Append-only session journal per data file (FastFile line edits).
  Format: one UTF-8-ish line per event (Delphi 7 AnsiString); fields separated by |.
  Directory: <exe>\\fastfile_temp\\FastFileSessionHistory\\
}

interface

uses
  SysUtils, Classes, SyncObjs;

procedure FFHistoryAppendLineOp(const ADataFilePath, AOp: string;
  const ALine1Based: Int64; const AOldExcerpt, ANewExcerpt: string);

{ BINS: colagem / insercao em lote (X linhas a partir da linha inicial). }
procedure FFHistoryAppendBatchInsert(const ADataFilePath: string;
  const AStartLine1Based, ALineCount: Int64;
  const AFirstExcerpt, ALastExcerpt: string);

{ BAUT: autofill na coluna Linha # (arrastar para inserir linhas em branco). }
procedure FFHistoryAppendBatchAutofill(const ADataFilePath: string;
  const AStartLine1Based, ALineCount: Int64;
  const AFirstExcerpt, ALastExcerpt: string);

{ BDEL: remocao em lote (ex.: undo de colagem). }
procedure FFHistoryAppendBatchDelete(const ADataFilePath: string;
  const AStartLine1Based, ALineCount: Int64);

{ UNDO / REDO / nota: aparece no memo do historico (sem cor de linha no preview). }
procedure FFHistoryAppendSessionNote(const ADataFilePath, AKind, ADetail: string);

procedure FFHistoryAppendReplaceAll(const ADataFilePath: string;
  const AReplacedCount: Int64; const ALimitHit: Boolean;
  const AFindExcerpt, AReplaceExcerpt: string);

{ MDLT: mesclar linhas (delta) — bloco de alteracoes em varias linhas. }
procedure FFHistoryAppendMergeDelta(const ADataFilePath: string;
  const ALineCount, AFirstLine: Int64;
  const AFirstExcerpt, ALastExcerpt: string);

{ MRGF: mesclar arquivos (insercao de trecho/arquivo). }
procedure FFHistoryAppendMergeFiles(const ADataFilePath, ASourceFile, ADetail: string);

function FFHistoryJournalPath(const ADataFilePath: string): string;

type
  TFFHistoryKeep = function(const Line: string): Boolean of object;

{ Reescreve o journal. AKeep recebe a linha ja' decodificada (sem o cabecalho #).
  Devolve False se o ficheiro nao puder ser substituido. ARemoved = linhas de dados tiradas. }
function FFHistoryRewrite(const AJournalPath: string;
  const AKeep: TFFHistoryKeep; out ARemoved: Integer): Boolean;

{ Lote: cada item ja' vem como 'OP|campos' (campos passados por FFHistorySanitizeField);
  a data e' prefixada aqui e tudo e' gravado num unico append. }
procedure FFHistoryAppendOpLines(const ADataFilePath: string; ALines: TStrings);
function FFHistorySanitizeField(const S: string; const MaxLen: Integer): string;
function FFHistoryExcerptMax: Integer;

implementation

uses
  uFastFilePaths, uUserPrefs, uTextEncoding;

var
  GFFHistLock: TCriticalSection;

function FFHistoryDir: string;
begin
  Result := EnsureFastFileSessionHistoryDir;
end;

function FFHashPath(const S: string): string;
var
  h: Cardinal;
  i: Integer;
begin
  { FNV-1a 32-bit }
  h := 2166136261;
  for i := 1 to Length(S) do
    h := (h xor Cardinal(Ord(S[i]) and $FF)) * 16777619;
  Result := IntToHex(h, 8);
end;

function SanitizeOneLine(const S: string; const MaxLen: Integer): string;
var
  j: Integer;
  c: Char;
begin
  Result := '';
  for j := 1 to Length(S) do
  begin
    c := S[j];
    if c in [#0..#31, '|'] then
      Result := Result + ' '
    else
      Result := Result + c;
    if Length(Result) >= MaxLen then
      Break;
  end;
end;

function FFHistoryJournalPath(const ADataFilePath: string): string;
var
  Base, H, Leaf: string;
begin
  Base := ExpandFileName(ADataFilePath);
  H := FFHashPath(AnsiLowerCase(Base));
  Leaf := ChangeFileExt(ExtractFileName(Base), '');
  if Leaf = '' then
    Leaf := 'file';
  if Length(Leaf) > 48 then
    Leaf := Copy(Leaf, 1, 48);
  { Windows-safe-ish: remove path chars from leaf }
  Leaf := StringReplace(Leaf, '\', '_', [rfReplaceAll]);
  Leaf := StringReplace(Leaf, '/', '_', [rfReplaceAll]);
  Leaf := StringReplace(Leaf, ':', '_', [rfReplaceAll]);
  Result := FFHistoryDir + 'ffhist_' + H + '_' + Leaf + '.log';
end;

procedure FFHistoryEnsureDir;
begin
  if not DirectoryExists(FFHistoryDir) then
    ForceDirectories(FFHistoryDir);
end;

procedure FFAppendRawLine(const ADestJournal, ALine, ASourceDataFileEcho: string);
var
  FS: TFileStream;
  Data: AnsiString;
  Created: Boolean;
  Hdr: string;
begin
  FFHistoryEnsureDir;
  { UTF-8 no journal (Unicode Delphi): evita "?" fora da ACP ao gravar excertos. }
  Data := UTF8Encode(ALine) + AnsiString(#13#10);
  Created := not FileExists(ADestJournal);
  if Created then
    FS := TFileStream.Create(ADestJournal, fmCreate)
  else
    FS := TFileStream.Create(ADestJournal, fmOpenReadWrite or fmShareDenyNone);
  try
    FS.Seek(0, soFromEnd);
    if Created then
    begin
      Hdr := '#FFHISTv1 src=' + SanitizeOneLine(ASourceDataFileEcho, 240);
      Data := UTF8Encode(Hdr) + AnsiString(#13#10) + Data;
    end;
    if Length(Data) > 0 then
      FS.Write(Data[1], Length(Data));
  finally
    FS.Free;
  end;
end;

function FFHistorySanitizeField(const S: string; const MaxLen: Integer): string;
var
  j, n: Integer;
begin
  n := Length(S);
  if n > MaxLen then
    n := MaxLen;
  SetLength(Result, n);
  for j := 1 to n do
    if (S[j] < #32) or (S[j] = '|') then
      Result[j] := ' '
    else
      Result[j] := S[j];
end;

function FFHistoryExcerptMax: Integer;
begin
  Result := PrefHistoryLineExcerptMax;
end;

procedure FFHistoryAppendOpLines(const ADataFilePath: string; ALines: TStrings);
var
  SB: TStringBuilder;
  Ts, Dest, Src: string;
  Data: UTF8String;
  FS: TFileStream;
  Created: Boolean;
  i: Integer;
begin
  if (ALines = nil) or (ALines.Count = 0) then Exit;
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  Ts := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|';
  Src := ExpandFileName(ADataFilePath);
  Dest := FFHistoryJournalPath(ADataFilePath);
  SB := TStringBuilder.Create;
  try
    for i := 0 to ALines.Count - 1 do
      SB.Append(Ts).Append(ALines[i]).Append(#13#10);
    GFFHistLock.Enter;
    try
      FFHistoryEnsureDir;
      Created := not FileExists(Dest);
      if Created then
      begin
        SB.Insert(0, '#FFHISTv1 src=' + SanitizeOneLine(Src, 240) + #13#10);
        FS := TFileStream.Create(Dest, fmCreate);
      end
      else
        FS := TFileStream.Create(Dest, fmOpenReadWrite or fmShareDenyNone);
      try
        FS.Seek(0, soFromEnd);
        Data := UTF8Encode(SB.ToString);
        if Length(Data) > 0 then
          FS.WriteBuffer(Data[1], Length(Data));
      finally
        FS.Free;
      end;
    finally
      GFFHistLock.Leave;
    end;
  finally
    SB.Free;
  end;
end;

procedure FFHistoryAppendLineOp(const ADataFilePath, AOp: string;
  const ALine1Based: Int64; const AOldExcerpt, ANewExcerpt: string);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|' +
      UpperCase(Trim(AOp)) + '|' + IntToStr(ALine1Based) + '|' +
      SanitizeOneLine(AOldExcerpt, PrefHistoryLineExcerptMax) + '|' +
      SanitizeOneLine(ANewExcerpt, PrefHistoryLineExcerptMax);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendBatchInsert(const ADataFilePath: string;
  const AStartLine1Based, ALineCount: Int64;
  const AFirstExcerpt, ALastExcerpt: string);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  if ALineCount < 1 then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|BINS|' +
      IntToStr(AStartLine1Based) + '|' + IntToStr(ALineCount) + '|' +
      SanitizeOneLine(AFirstExcerpt, 200) + '|' + SanitizeOneLine(ALastExcerpt, 200);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendBatchAutofill(const ADataFilePath: string;
  const AStartLine1Based, ALineCount: Int64;
  const AFirstExcerpt, ALastExcerpt: string);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  if ALineCount < 1 then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|BAUT|' +
      IntToStr(AStartLine1Based) + '|' + IntToStr(ALineCount) + '|' +
      SanitizeOneLine(AFirstExcerpt, 200) + '|' + SanitizeOneLine(ALastExcerpt, 200);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendBatchDelete(const ADataFilePath: string;
  const AStartLine1Based, ALineCount: Int64);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  if ALineCount < 1 then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|BDEL|' +
      IntToStr(AStartLine1Based) + '|' + IntToStr(ALineCount) + '||';
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendSessionNote(const ADataFilePath, AKind, ADetail: string);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|' +
      UpperCase(Trim(AKind)) + '|' + SanitizeOneLine(ADetail, 400);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line,
      ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendReplaceAll(const ADataFilePath: string;
  const AReplacedCount: Int64; const ALimitHit: Boolean;
  const AFindExcerpt, AReplaceExcerpt: string);
var
  Line: string;
  Lim: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  GFFHistLock.Enter;
  try
    if ALimitHit then Lim := '1' else Lim := '0';
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|RPLALL|' +
      IntToStr(AReplacedCount) + '|' + Lim + '|' +
      SanitizeOneLine(AFindExcerpt, 120) + '|' + SanitizeOneLine(AReplaceExcerpt, 120);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendMergeDelta(const ADataFilePath: string;
  const ALineCount, AFirstLine: Int64;
  const AFirstExcerpt, ALastExcerpt: string);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  if ALineCount < 1 then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|MDLT|' +
      IntToStr(AFirstLine) + '|' + IntToStr(ALineCount) + '|' +
      SanitizeOneLine(AFirstExcerpt, 200) + '|' + SanitizeOneLine(ALastExcerpt, 200);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

procedure FFHistoryAppendMergeFiles(const ADataFilePath, ASourceFile, ADetail: string);
var
  Line: string;
begin
  if Trim(ADataFilePath) = '' then Exit;
  if not FileExists(ADataFilePath) then Exit;
  GFFHistLock.Enter;
  try
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '|MRGF|' +
      SanitizeOneLine(ExtractFileName(ASourceFile), 120) + '|' +
      SanitizeOneLine(ADetail, 240);
    FFAppendRawLine(FFHistoryJournalPath(ADataFilePath), Line, ExpandFileName(ADataFilePath));
  finally
    GFFHistLock.Leave;
  end;
end;

function FFHistoryRewrite(const AJournalPath: string;
  const AKeep: TFFHistoryKeep; out ARemoved: Integer): Boolean;
const
  cBuf = 1 shl 20;
var
  Src, Dst: TFileStream;
  Tmp: string;
  Buf, Carry: TBytes;
  CarryLen, Got, i, St, n: Integer;
  Pos0, Want: Int64;
  KeptAny: Boolean;

  procedure FlushLine(P: PAnsiChar; Len: Integer);
  var
    Raw: AnsiString;
    U: string;
    NL: AnsiString;
    Keep: Boolean;
  begin
    while (Len > 0) and (P[Len - 1] = #13) do
      Dec(Len);
    if Len <= 0 then Exit;
    SetString(Raw, P, Len);
    U := RawBytesToDisplayString(Raw);
    if (U <> '') and (U[1] = #$FEFF) then
      Delete(U, 1, 1);
    U := Trim(U);
    if U = '' then Exit;
    if U[1] = '#' then
      Keep := True
    else if Assigned(AKeep) then
      Keep := AKeep(U)
    else
      Keep := True;
    if not Keep then
    begin
      Inc(ARemoved);
      Exit;
    end;
    KeptAny := True;
    Dst.WriteBuffer(P^, Len);
    NL := #13#10;
    Dst.WriteBuffer(NL[1], 2);
  end;

begin
  ARemoved := 0;
  Result := False;
  KeptAny := False;
  if not Assigned(AKeep) then Exit;
  if (AJournalPath = '') or not FileExists(AJournalPath) then Exit;
  Tmp := AJournalPath + '.tmp';
  GFFHistLock.Enter;
  try
    try
      Src := TFileStream.Create(AJournalPath, fmOpenRead or fmShareDenyNone);
      try
        Dst := TFileStream.Create(Tmp, fmCreate);
        try
          SetLength(Buf, cBuf);
          CarryLen := 0;
          Pos0 := 0;
          while Pos0 < Src.Size do
          begin
            Want := Src.Size - Pos0;
            if Want > cBuf then
              Want := cBuf;
            Got := Src.Read(Buf[0], Integer(Want));
            if Got <= 0 then Break;
            St := 0;
            i := 0;
            while i < Got do
            begin
              if Buf[i] = 10 then
              begin
                if CarryLen > 0 then
                begin
                  if CarryLen + (i - St) > Length(Carry) then
                    SetLength(Carry, CarryLen + (i - St) + 256);
                  if i > St then
                    Move(Buf[St], Carry[CarryLen], i - St);
                  n := CarryLen + (i - St);
                  FlushLine(PAnsiChar(@Carry[0]), n);
                  CarryLen := 0;
                end
                else
                  FlushLine(PAnsiChar(@Buf[St]), i - St);
                St := i + 1;
              end;
              Inc(i);
            end;
            if St < Got then
            begin
              n := Got - St;
              if CarryLen + n > Length(Carry) then
                SetLength(Carry, CarryLen + n + 256);
              Move(Buf[St], Carry[CarryLen], n);
              Inc(CarryLen, n);
            end;
            Inc(Pos0, Got);
          end;
          if CarryLen > 0 then
            FlushLine(PAnsiChar(@Carry[0]), CarryLen);
        finally
          Dst.Free;
        end;
      finally
        Src.Free;
      end;
      if not DeleteFile(AJournalPath) then
      begin
        DeleteFile(Tmp);
        Exit;
      end;
      if not KeptAny then
      begin
        DeleteFile(Tmp);
        Result := True;
        Exit;
      end;
      Result := RenameFile(Tmp, AJournalPath);
      if not Result then
        DeleteFile(Tmp);
    except
      DeleteFile(Tmp);
      Result := False;
    end;
  finally
    GFFHistLock.Leave;
  end;
end;

initialization
  GFFHistLock := TCriticalSection.Create;

finalization
  FreeAndNil(GFFHistLock);

end.
