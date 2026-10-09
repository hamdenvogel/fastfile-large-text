unit uAgentTools;

{
  Local tools for the ask-files agent: expand folders, list, read a line
  window, search, count. Content is never loaded whole.

  Line N is located through the working line index (temp.txt / temp_ckpt.txt)
  when the file is the one open in the main form; otherwise by one binary pass.
}

interface

uses
  Classes, uAgentPrefs;

type
  TAgentRootKind = (arkFile, arkFolder);

  TAgentRoot = class
  public
    Kind: TAgentRootKind;
    Path: string;
  end;

  TAgentScanNotify = procedure(AListed: Integer; var ACancel: Boolean) of object;

  TAgentRawLine = record
    LineNo: Int64;
    Ofs: Int64;
    Raw: AnsiString;
  end;
  TAgentRawLines = TArray<TAgentRawLine>;

function AgentExpandRoots(ARoots: TStrings; const APrefs: TAgentPrefs;
  AFiles: TStrings; AOnProgress: TAgentScanNotify): Boolean;
function AgentFileAllowed(const APath: string; AFiles: TStrings): Boolean;
function AgentToolList(AFiles: TStrings; AMaxChars: Integer): string;
{ AIndexPath: working line index of APath, or '' when APath is not the open file.
  AStart < 0 reads the last ACount lines. }
function AgentToolReadLines(const APath: string; AStart: Int64; ACount: Integer;
  ACancelFlag: PInteger; const AIndexPath: string = ''): string;
{ AWholeWord: the needle must not touch a letter, digit or "_" on either side ("allyne" no longer hits "Kallyne").
  Whole-word searches also list every matching line number (line_numbers=), for export_lines. }
function AgentToolSearch(const APath, ANeedle: string; ALimit: Integer;
  ACancelFlag: PInteger; ACaseSensitive: Boolean = False; AWholeWord: Boolean = False): string;
{ hits= is the real total. shown= is only a sample. }
function AgentToolCount(AFiles: TStrings; const ANeedle: string; ASample: Integer;
  ACancelFlag: PInteger; ACaseSensitive: Boolean = False; AWholeWord: Boolean = False): string;
{ Lines of APath that contain ANeedle. False when the file is missing or the scan was stopped. }
function AgentCountMatchingLines(const APath, ANeedle: string; ACancelFlag: PInteger;
  ACaseSensitive: Boolean; out AHits: Int64): Boolean;
{ 0-based byte offset of the first byte of line ALine (1-based). Past EOF: file size, False. }
function AgentLineOffset(const APath: string; ALine: Int64; const AIndexPath: string;
  ACancelFlag: PInteger; out AOfs: Int64): Boolean;
{ Raw bytes of up to ACount lines from AStart (terminator and trailing CR removed). }
function AgentReadRawLines(const APath: string; AStart: Int64; ACount: Integer;
  const AIndexPath: string; ACancelFlag: PInteger): TAgentRawLines;
function AgentIndexPathFor(const APrefs: TAgentPrefs; const APath: string): string;
{ A line from FastFileForEachRawLine with the UTF-16 BOM, stray 00 and CR units removed. }
function AlignWideLine(const ARaw: AnsiString; const AEnc: string): AnsiString;

implementation

uses
  SysUtils, Masks, Types, Character, Generics.Collections, UnConsts, uFastFilePaths, uTextEncoding, uEolPolicy;

const
  SCAN_BUF = 4 * 1024 * 1024;
  READ_BUF = 1024 * 1024;
  SHOW_CHARS = 400;
  { Tool output is clipped near 14000 chars; this many line numbers still fit. }
  MAX_LINE_NUMBERS = 1500;

type
  TAgentCancelProbe = class
  public
    Flag: PInteger;
    procedure Tick(APercent: Integer; var ACancel: Boolean);
  end;

procedure TAgentCancelProbe.Tick(APercent: Integer; var ACancel: Boolean);
begin
  ACancel := Assigned(Flag) and (Flag^ <> 0);
end;

function NormPath(const APath: string): string;
begin
  Result := ExpandFileName(Trim(APath));
end;

function Cancelled(ACancel: PInteger): Boolean;
begin
  Result := Assigned(ACancel) and (ACancel^ <> 0);
end;

function AgentIndexPathFor(const APrefs: TAgentPrefs; const APath: string): string;
begin
  Result := '';
  if (APrefs.OpenPath = '') or (APrefs.IndexPath = '') then Exit;
  if SameText(NormPath(APrefs.OpenPath), NormPath(APath)) then
    Result := APrefs.IndexPath;
end;

function AgentFileAllowed(const APath: string; AFiles: TStrings): Boolean;
var
  I: Integer;
  P: string;
begin
  Result := False;
  P := NormPath(APath);
  if (P = '') or (AFiles = nil) then Exit;
  for I := 0 to AFiles.Count - 1 do
    if SameText(NormPath(AFiles[I]), P) then
      Exit(True);
end;

function MaskAllows(const AFileName, AMask: string): Boolean;
var
  Rest, One: string;
  P: Integer;
begin
  Rest := Trim(AMask);
  if (Rest = '') or (Rest = '*') or (Rest = '*.*') then
    Exit(True);
  Result := False;
  while Rest <> '' do
  begin
    P := Pos(';', Rest);
    if P = 0 then
    begin
      One := Trim(Rest);
      Rest := '';
    end
    else
    begin
      One := Trim(Copy(Rest, 1, P - 1));
      Delete(Rest, 1, P);
    end;
    if (One <> '') and MatchesMask(AFileName, One) then
      Exit(True);
  end;
end;

function SkipDirName(const AName: string): Boolean;
var
  N: string;
begin
  N := LowerCase(AName);
  Result := (N = '.git') or (N = '.svn') or (N = 'node_modules') or (N = '__pycache__');
end;

function CapText(const S: string; AMax: Integer): string;
begin
  if (AMax > 0) and (Length(S) > AMax) then
    Result := Copy(S, 1, AMax) + #13#10 + '...[truncated]'
  else
    Result := S;
end;

function YesNo(AValue: Boolean): string;
begin
  if AValue then
    Result := 'yes'
  else
    Result := 'no';
end;

function AgentToolList(AFiles: TStrings; AMaxChars: Integer): string;
var
  I, N: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    N := AFiles.Count;
    if N > 200 then
      N := 200;
    SL.Add('count=' + IntToStr(AFiles.Count));
    for I := 0 to N - 1 do
      SL.Add(AFiles[I]);
    if AFiles.Count > N then
      SL.Add('... ' + IntToStr(AFiles.Count - N) + ' more');
    Result := CapText(SL.Text, AMaxChars);
  finally
    SL.Free;
  end;
end;

{ --- line offsets ------------------------------------------------------------ }

function ReadIndexRecord(const AIndexPath: string; ARecord: Int64; out AOfs1: Int64): Boolean;
var
  F: TFileStream;
  Buf: array[0..17] of AnsiChar;
  S: AnsiString;
begin
  Result := False;
  AOfs1 := 0;
  if ARecord < 0 then Exit;
  try
    F := TFileStream.Create(AIndexPath, fmOpenRead or fmShareDenyNone);
    try
      if (ARecord + 1) * INDEX_RECORD_SIZE > F.Size then Exit;
      F.Position := ARecord * INDEX_RECORD_SIZE;
      if F.Read(Buf, SizeOf(Buf)) <> SizeOf(Buf) then Exit;
      SetString(S, PAnsiChar(@Buf[0]), SizeOf(Buf));
      AOfs1 := Abs(StrToInt64Def(Trim(string(S)), -1));
      Result := AOfs1 >= 1;
    finally
      F.Free;
    end;
  except
    Result := False;
  end;
end;

{ From AFromOfs (start of a line), skip ASkip terminators. }
function SkipLinesFrom(F: TFileStream; AFromOfs, ASkip: Int64; ATerm: Byte;
  ACancel: PInteger; out AOfs: Int64): Boolean;
var
  Buf: TBytes;
  N, I: Integer;
  Pos0: Int64;
begin
  AOfs := AFromOfs;
  if ASkip <= 0 then
    Exit(True);
  Result := False;
  SetLength(Buf, SCAN_BUF);
  F.Position := AFromOfs;
  Pos0 := AFromOfs;
  while True do
  begin
    if Cancelled(ACancel) then Exit;
    N := F.Read(Buf[0], SCAN_BUF);
    if N <= 0 then
    begin
      AOfs := F.Size;
      Exit;
    end;
    for I := 0 to N - 1 do
      if Buf[I] = ATerm then
      begin
        Dec(ASkip);
        if ASkip = 0 then
        begin
          AOfs := Pos0 + I + 1;
          Exit(AOfs < F.Size);
        end;
      end;
    Inc(Pos0, N);
  end;
end;

function ByteBefore(F: TFileStream; AOfs: Int64; out AByte: Byte): Boolean;
begin
  Result := False;
  if AOfs <= 0 then Exit;
  F.Position := AOfs - 1;
  Result := F.Read(AByte, 1) = 1;
end;

function AgentLineOffset(const APath: string; ALine: Int64; const AIndexPath: string;
  ACancelFlag: PInteger; out AOfs: Int64): Boolean;
var
  F: TFileStream;
  Term, B: Byte;
  Ofs1, Base: Int64;
  Skip: Int64;
  Dense: Boolean;
begin
  Result := False;
  AOfs := 0;
  if (ALine < 1) or (not FileExists(APath)) then Exit;
  Term := LineTermByteForFile(APath);
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    if ALine = 1 then
      Exit(F.Size > 0);
    Base := 0;
    Skip := ALine - 1;
    if (AIndexPath <> '') and FileExists(AIndexPath) then
    begin
      Dense := SameText(ExtractFileName(AIndexPath), TEMPFILE);
      if Dense then
      begin
        if ReadIndexRecord(AIndexPath, ALine - 1, Ofs1) then
        begin
          Base := Ofs1 - 1;
          Skip := 0;
        end;
      end
      else if ReadIndexRecord(AIndexPath, (ALine - 1) div CKPT_INTERVAL, Ofs1) then
      begin
        Base := Ofs1 - 1;
        Skip := (ALine - 1) mod CKPT_INTERVAL;
      end;
      { The index belongs to the open file. Reject it if it does not land on a line start. }
      if (Base > 0) and ((Base > F.Size) or (not ByteBefore(F, Base, B)) or (B <> Term)) then
      begin
        Base := 0;
        Skip := ALine - 1;
      end;
    end;
    if Skip = 0 then
    begin
      AOfs := Base;
      Exit(Base < F.Size);
    end;
    Result := SkipLinesFrom(F, Base, Skip, Term, ACancelFlag, AOfs);
  finally
    F.Free;
  end;
end;

function AgentReadRawLines(const APath: string; AStart: Int64; ACount: Integer;
  const AIndexPath: string; ACancelFlag: PInteger): TAgentRawLines;
var
  F: TFileStream;
  Ofs, LineStart, Pos0: Int64;
  Term: Byte;
  Buf: TBytes;
  N, I, Got, K: Integer;
  Pending: AnsiString;
  Chunk: AnsiString;

  procedure Emit(const ARaw: AnsiString);
  var
    S: AnsiString;
  begin
    S := ARaw;
    if (Length(S) > 0) and (S[Length(S)] = #13) then
      SetLength(S, Length(S) - 1);
    if (Got = 0) and (Ofs = 0) and (Length(S) >= 3) and (S[1] = #$EF) and (S[2] = #$BB) and (S[3] = #$BF) then
      Delete(S, 1, 3);
    Result[Got].LineNo := AStart + Got;
    Result[Got].Ofs := LineStart;
    Result[Got].Raw := S;
    Inc(Got);
  end;

begin
  SetLength(Result, 0);
  if (ACount < 1) or (AStart < 1) then Exit;
  if not AgentLineOffset(APath, AStart, AIndexPath, ACancelFlag, Ofs) then Exit;
  SetLength(Result, ACount);
  Got := 0;
  Term := LineTermByteForFile(APath);
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Buf, READ_BUF);
    F.Position := Ofs;
    Pos0 := Ofs;
    LineStart := Ofs;
    Pending := '';
    while Got < ACount do
    begin
      if Cancelled(ACancelFlag) then Break;
      N := F.Read(Buf[0], READ_BUF);
      if N <= 0 then
      begin
        if Pending <> '' then
          Emit(Pending);
        Break;
      end;
      K := 0;
      for I := 0 to N - 1 do
        if Buf[I] = Term then
        begin
          SetString(Chunk, PAnsiChar(@Buf[K]), I - K);
          Emit(Pending + Chunk);
          Pending := '';
          K := I + 1;
          LineStart := Pos0 + K;
          if Got >= ACount then Break;
        end;
      if (Got < ACount) and (K < N) then
      begin
        SetString(Chunk, PAnsiChar(@Buf[K]), N - K);
        Pending := Pending + Chunk;
        { One very long line: keep only what can be shown. }
        if Length(Pending) > 64 * 1024 then
          SetLength(Pending, 64 * 1024);
      end;
      Inc(Pos0, N);
    end;
  finally
    F.Free;
  end;
  SetLength(Result, Got);
end;

{ Lines are split on the single byte 0A. In UTF-16 that leaves the other half of the line
  break on the neighbouring line (LE: a leading 00; BE: a trailing 00), plus BOM and CR units. }
function AlignWideLine(const ARaw: AnsiString; const AEnc: string): AnsiString;
begin
  Result := ARaw;
  if IsUtf16LEEncoding(AEnc) then
  begin
    if (Length(Result) >= 2) and (Result[1] = #$FF) and (Result[2] = #$FE) then
      Delete(Result, 1, 2);
    if Odd(Length(Result)) and (Length(Result) > 0) and (Result[1] = #0) then
      Delete(Result, 1, 1);
    if (Length(Result) >= 2) and (Result[Length(Result) - 1] = #13) and (Result[Length(Result)] = #0) then
      SetLength(Result, Length(Result) - 2);
  end
  else if IsUtf16BEEncoding(AEnc) then
  begin
    if (Length(Result) >= 2) and (Result[1] = #$FE) and (Result[2] = #$FF) then
      Delete(Result, 1, 2);
    if Odd(Length(Result)) and (Result[Length(Result)] = #0) then
      SetLength(Result, Length(Result) - 1);
    if (Length(Result) >= 2) and (Result[Length(Result) - 1] = #0) and (Result[Length(Result)] = #13) then
      SetLength(Result, Length(Result) - 2);
  end;
end;

{ Last ACount lines, scanning backwards from the end of the file: cost depends on the tail size,
  not on the file size. ALastLineNo is the number of the last line (0 when the file is empty). }
function ReadTailLines(const APath, AEnc: string; ACount: Integer; out ALastLineNo: Int64): TArray<AnsiString>;
const
  CHUNK = 64 * 1024;
  MAX_TAIL = 8 * 1024 * 1024;
var
  F: TFileStream;
  Buf: TBytes;
  Size, Pos, EndOfs, StartOfs, ReadFrom, Abs: Int64;
  N, I, Found, Len, LineStart: Integer;
  LE, BE, EndsWithTerm, Term: Boolean;
  After, Before: Byte;
  Block, Line: AnsiString;
  List: TList<AnsiString>;

  function ByteAt(AOfs: Int64): Byte;
  begin
    Result := 0;
    if (AOfs < 0) or (AOfs >= Size) then Exit;
    F.Position := AOfs;
    F.ReadBuffer(Result, 1);
  end;

  function TermInBlock(AIdx: Integer): Boolean;
  begin
    if Block[AIdx] <> #10 then
      Exit(False);
    if LE then
      Result := (not Odd(ReadFrom + AIdx - 1)) and (AIdx < Len) and (Block[AIdx + 1] = #0)
    else if BE then
      Result := Odd(ReadFrom + AIdx - 1) and (AIdx > 1) and (Block[AIdx - 1] = #0)
    else
      Result := True;
  end;

begin
  SetLength(Result, 0);
  ALastLineNo := 0;
  LE := IsUtf16LEEncoding(AEnc);
  BE := IsUtf16BEEncoding(AEnc);
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    Size := F.Size;
    if Size = 0 then Exit;
    EndsWithTerm := False;
    EndOfs := Size;
    if LE or BE then
    begin
      if (Size >= 2) and ((LE and (ByteAt(Size - 2) = $0A) and (ByteAt(Size - 1) = 0)) or
         (BE and (ByteAt(Size - 2) = 0) and (ByteAt(Size - 1) = $0A))) then
      begin
        EndsWithTerm := True;
        EndOfs := Size - 2;
      end;
    end
    else if ByteAt(Size - 1) = $0A then
    begin
      EndsWithTerm := True;
      EndOfs := Size - 1;
    end;

    SetLength(Buf, CHUNK);
    Pos := EndOfs;
    After := ByteAt(Pos);
    Found := 0;
    StartOfs := 0;
    while (Pos > 0) and (Found < ACount) do
    begin
      N := CHUNK;
      if N > Pos then
        N := Integer(Pos);
      F.Position := Pos - N;
      F.ReadBuffer(Buf[0], N);
      for I := N - 1 downto 0 do
      begin
        Abs := Pos - N + I;
        Term := False;
        if Buf[I] = $0A then
        begin
          if LE then
            Term := (not Odd(Abs)) and (After = 0)
          else if BE then
          begin
            if I > 0 then
              Before := Buf[I - 1]
            else
              Before := ByteAt(Abs - 1);
            Term := Odd(Abs) and (Before = 0);
          end
          else
            Term := True;
        end;
        if Term then
        begin
          Inc(Found);
          if Found = ACount then
          begin
            if LE then
              StartOfs := Abs + 2
            else
              StartOfs := Abs + 1;
            Break;
          end;
        end;
        After := Buf[I];
      end;
      Pos := Pos - N;
    end;

    ReadFrom := StartOfs;
    if EndOfs - ReadFrom > MAX_TAIL then
    begin
      ReadFrom := EndOfs - MAX_TAIL;
      if (LE or BE) and Odd(ReadFrom) then
        Inc(ReadFrom);
    end;
    Len := Integer(EndOfs - ReadFrom);
    SetLength(Block, Len);
    if Len > 0 then
    begin
      F.Position := ReadFrom;
      F.ReadBuffer(Block[1], Len);
    end;
  finally
    F.Free;
  end;

  List := TList<AnsiString>.Create;
  try
    LineStart := 1;
    I := 1;
    while I <= Len do
    begin
      if TermInBlock(I) then
      begin
        if BE then
          Line := Copy(Block, LineStart, I - 1 - LineStart)
        else
          Line := Copy(Block, LineStart, I - LineStart);
        List.Add(Line);
        if LE then
          LineStart := I + 2
        else
          LineStart := I + 1;
        I := LineStart;
        Continue;
      end;
      Inc(I);
    end;
    List.Add(Copy(Block, LineStart, MaxInt));
    while List.Count > ACount do
      List.Delete(0);
    SetLength(Result, List.Count);
    for I := 0 to List.Count - 1 do
    begin
      Line := List[I];
      if LE or BE then
        Line := AlignWideLine(Line, AEnc)
      else if (Line <> '') and (Line[Length(Line)] = #13) then
        SetLength(Line, Length(Line) - 1);
      Result[I] := Line;
    end;
  finally
    List.Free;
  end;

  // FastFileCountLines counts terminators (+1 when the last byte is not one). A UTF-16 LE file that ends
  // in 0A 00 ends on 00, so it is counted once more than its real lines.
  ALastLineNo := FastFileCountLines(APath);
  if LE and EndsWithTerm then
    Dec(ALastLineNo);
end;

function AgentToolReadLines(const APath: string; AStart: Int64; ACount: Integer;
  ACancelFlag: PInteger; const AIndexPath: string): string;
var
  Lines: TAgentRawLines;
  Enc, Txt: string;
  SL: TStringList;
  I: Integer;
  TailRaw: TArray<AnsiString>;
  LastNo: Int64;
begin
  if not FileExists(APath) then
    Exit('error=file not found');
  if ACount < 1 then
    ACount := 1;
  if ACount > 200 then
    ACount := 200;
  if AStart < 0 then
  begin
    Enc := DetectTextFileEncoding(APath);
    TailRaw := ReadTailLines(APath, Enc, ACount, LastNo);
    if Length(TailRaw) = 0 then
      Exit('lines=0' + #13#10 + 'note=the file is empty');
    SL := TStringList.Create;
    try
      for I := 0 to High(TailRaw) do
      begin
        Txt := FileBytesToUnicodeText(TailRaw[I], Enc);
        if Length(Txt) > SHOW_CHARS then
          Txt := Copy(Txt, 1, SHOW_CHARS) + ' ...[line cut]';
        SL.Add(IntToStr(LastNo - High(TailRaw) + I) + '|' + Txt);
      end;
      SL.Add('eof=yes');
      Result := SL.Text;
    finally
      SL.Free;
    end;
    Exit;
  end;
  if AStart < 1 then
    AStart := 1;
  // Near the end of a big file with no index, skipping from line 1 is a full pass; read the tail instead.
  LastNo := FastFileKnownLineCount(APath);
  if (AIndexPath = '') and (LastNo > 0) and (AStart > LastNo - 200) and (AStart <= LastNo) then
  begin
    SL := TStringList.Create;
    try
      SL.Text := AgentToolReadLines(APath, -1, Integer(LastNo - AStart + 2), ACancelFlag);
      for I := SL.Count - 1 downto 0 do
        if (StrToInt64Def(Copy(SL[I], 1, Pos('|', SL[I]) - 1), -1) < AStart) or
           (StrToInt64Def(Copy(SL[I], 1, Pos('|', SL[I]) - 1), -1) >= AStart + ACount) then
          if SL[I] <> 'eof=yes' then
            SL.Delete(I);
      if (SL.Count > 0) and (SL[0] <> 'eof=yes') then
      begin
        if (SL.Count - 1 >= ACount) then
          SL.Delete(SL.Count - 1);
        Exit(SL.Text);
      end;
    finally
      SL.Free;
    end;
  end;
  Lines := AgentReadRawLines(APath, AStart, ACount, AIndexPath, ACancelFlag);
  if Length(Lines) = 0 then
    Exit('lines=0' + #13#10 + 'note=line ' + IntToStr(AStart) + ' is past the end of the file');
  Enc := DetectTextFileEncoding(APath);
  SL := TStringList.Create;
  try
    for I := 0 to High(Lines) do
    begin
      Txt := FileBytesToUnicodeText(AlignWideLine(Lines[I].Raw, Enc), Enc);
      if (Txt = '') and (I = High(Lines)) and IsUnicodeFileEncoding(Enc) and (Lines[I].Raw <> '') then
        Continue;
      if Length(Txt) > SHOW_CHARS then
        Txt := Copy(Txt, 1, SHOW_CHARS) + ' ...[line cut]';
      SL.Add(IntToStr(Lines[I].LineNo) + '|' + Txt);
    end;
    if Length(Lines) < ACount then
      SL.Add('eof=yes');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

{ --- count / search ------------------------------------------------------------ }

function IsWordChar(C: Char): Boolean;
begin
  Result := C.IsLetterOrDigit or (C = '_');
end;

function WordMatches(const AText, ANeedle: string; ACaseSensitive: Boolean): Boolean;
var
  T, N: string;
  P, E: Integer;
begin
  Result := False;
  if ACaseSensitive then
  begin
    T := AText;
    N := ANeedle;
  end
  else
  begin
    T := AnsiLowerCase(AText);
    N := AnsiLowerCase(ANeedle);
  end;
  if N = '' then Exit;
  P := Pos(N, T);
  while P > 0 do
  begin
    E := P + Length(N);
    if ((P = 1) or not IsWordChar(T[P - 1])) and ((E > Length(T)) or not IsWordChar(T[E])) then
      Exit(True);
    P := Pos(N, T, P + 1);
  end;
end;

{ Raw is already aligned (AlignWideLine). The byte-level substring test runs first; the word test only on its hits. }
function LineHits(const Raw: AnsiString; const ANeedle, AEnc: string; ACaseSensitive, AWholeWord: Boolean): Boolean;
begin
  Result := UnicodeLineMatches(Raw, ANeedle, AEnc, ACaseSensitive, False);
  if Result and AWholeWord then
    Result := WordMatches(FileBytesToUnicodeText(Raw, AEnc), ANeedle, ACaseSensitive);
end;

type
  TCaseCountState = record
    Needle: string;
    Enc: string;
    Cancel: PInteger;
    Hits: Int64;
    Lines: Int64;
    CaseSens: Boolean;
    WholeWord: Boolean;
    LineNos: TStringBuilder;
  end;
  PCaseCountState = ^TCaseCountState;

procedure CaseCountVisit(ALine: PAnsiChar; ALen: Integer; ALineNo: Int64;
  var AStop: Boolean; AUser: Pointer);
var
  St: PCaseCountState;
  Raw: AnsiString;
begin
  St := PCaseCountState(AUser);
  if Cancelled(St.Cancel) then
  begin
    AStop := True;
    Exit;
  end;
  if ALineNo > St.Lines then
    St.Lines := ALineNo;
  if (ALine = nil) or (ALen <= 0) then Exit;
  SetString(Raw, ALine, ALen);
  if LineHits(AlignWideLine(Raw, St.Enc), St.Needle, St.Enc, St.CaseSens, St.WholeWord) then
  begin
    Inc(St.Hits);
    if (St.LineNos <> nil) and (St.Hits <= MAX_LINE_NUMBERS) then
    begin
      if St.LineNos.Length > 0 then
        St.LineNos.Append(',');
      St.LineNos.Append(ALineNo);
    end;
  end;
end;

{ ALineNos (optional) receives the matching line numbers, comma separated (whole-word / case-sensitive pass only). }
function CountInFile(const APath, ANeedle: string; ACancelFlag: PInteger;
  out AHits, ALines: Int64; ACaseSensitive: Boolean = False; AWholeWord: Boolean = False;
  ALineNos: TStringBuilder = nil): Boolean;
var
  Probe: TAgentCancelProbe;
  Counts: TInt64DynArray;
  St: TCaseCountState;
begin
  AHits := 0;
  ALines := 0;
  if ACaseSensitive or AWholeWord then
  begin
    St.Needle := ANeedle;
    St.Enc := DetectTextFileEncoding(APath);
    St.Cancel := ACancelFlag;
    St.Hits := 0;
    St.Lines := 0;
    St.CaseSens := ACaseSensitive;
    St.WholeWord := AWholeWord;
    St.LineNos := ALineNos;
    Result := FastFileForEachRawLine(APath, CaseCountVisit, @St) and not Cancelled(ACancelFlag);
    AHits := St.Hits;
    ALines := St.Lines;
    Exit;
  end;
  Probe := TAgentCancelProbe.Create;
  try
    Probe.Flag := ACancelFlag;
    Result := FastFileCountLineContains(APath, [ANeedle], Counts, ALines, Probe.Tick);
    if Length(Counts) > 0 then
      AHits := Counts[0];
  finally
    Probe.Free;
  end;
  if Cancelled(ACancelFlag) then
    Result := False;
end;

type
  TSampleState = record
    Needle: string;
    Enc: string;
    MaxN: Integer;
    Cancel: PInteger;
    Out: TStringList;
    CaseSens: Boolean;
    WholeWord: Boolean;
  end;
  PSampleState = ^TSampleState;

procedure SampleVisit(ALine: PAnsiChar; ALen: Integer; ALineNo: Int64;
  var AStop: Boolean; AUser: Pointer);
var
  St: PSampleState;
  Raw: AnsiString;
  Txt: string;
begin
  St := PSampleState(AUser);
  if (St.Out.Count >= St.MaxN) or Cancelled(St.Cancel) then
  begin
    AStop := True;
    Exit;
  end;
  if (ALine = nil) or (ALen <= 0) then Exit;
  SetString(Raw, ALine, ALen);
  Raw := AlignWideLine(Raw, St.Enc);
  if not LineHits(Raw, St.Needle, St.Enc, St.CaseSens, St.WholeWord) then Exit;
  Txt := FileBytesToUnicodeText(Raw, St.Enc);
  while (Txt <> '') and CharInSet(Txt[Length(Txt)], [#10, #13]) do
    SetLength(Txt, Length(Txt) - 1);
  if Length(Txt) > SHOW_CHARS then
    Txt := Copy(Txt, 1, SHOW_CHARS) + ' ...[line cut]';
  St.Out.Add(IntToStr(ALineNo) + '|' + Txt);
  if St.Out.Count >= St.MaxN then
    AStop := True;
end;

{ First AMax matching lines, as line|text with the real 1-based line number. }
function CollectSamples(const APath, ANeedle: string; AMax: Integer; ACancelFlag: PInteger;
  ACaseSensitive: Boolean = False; AWholeWord: Boolean = False): string;
var
  St: TSampleState;
begin
  Result := '';
  if AMax < 1 then Exit;
  St.Needle := ANeedle;
  St.CaseSens := ACaseSensitive;
  St.WholeWord := AWholeWord;
  St.Enc := DetectTextFileEncoding(APath);
  St.MaxN := AMax;
  St.Cancel := ACancelFlag;
  St.Out := TStringList.Create;
  try
    FastFileForEachRawLine(APath, SampleVisit, @St);
    Result := St.Out.Text;
  finally
    St.Out.Free;
  end;
end;

function MatchModeText(ACaseSensitive, AWholeWord: Boolean): string;
begin
  if ACaseSensitive then
    Result := 'match=case-sensitive'
  else
    Result := 'match=case-insensitive';
  if AWholeWord then
    Result := Result + ' whole word'
  else
    Result := Result + ' substring (also inside longer words)';
end;

function AgentToolSearch(const APath, ANeedle: string; ALimit: Integer;
  ACancelFlag: PInteger; ACaseSensitive: Boolean; AWholeWord: Boolean): string;
var
  Hits, Lines: Int64;
  Samples: string;
  Ok: Boolean;
  Nos: TStringBuilder;
begin
  if Trim(ANeedle) = '' then
    Exit('error=empty needle');
  if not FileExists(APath) then
    Exit('error=file not found');
  if ALimit < 1 then
    ALimit := 1;
  if ALimit > 50 then
    ALimit := 50;
  Nos := nil;
  if AWholeWord then
    Nos := TStringBuilder.Create;
  try
    Ok := CountInFile(APath, ANeedle, ACancelFlag, Hits, Lines, ACaseSensitive, AWholeWord, Nos);
    Samples := '';
    if Ok and (Hits > 0) then
      Samples := CollectSamples(APath, ANeedle, ALimit, ACancelFlag, ACaseSensitive, AWholeWord);
    Result := MatchModeText(ACaseSensitive, AWholeWord) + #13#10 + 'hits=' + IntToStr(Hits) + #13#10 +
      'total_lines=' + IntToStr(Lines) + #13#10 +
      'truncated=' + YesNo(Hits > ALimit) + #13#10 +
      'path=' + APath;
    if (Nos <> nil) and (Hits > 0) then
    begin
      Result := Result + #13#10 + 'line_numbers=' + Nos.ToString;
      if Hits > MAX_LINE_NUMBERS then
        Result := Result + #13#10 + 'note=only the first ' + IntToStr(MAX_LINE_NUMBERS) +
          ' line numbers are listed; export_lines cannot take them all';
    end;
  finally
    Nos.Free;
  end;
  if not Ok then
    Result := Result + #13#10 + 'stopped=yes';
  if Samples <> '' then
    Result := Result + #13#10 + 'samples (line|text):' + #13#10 + Samples;
end;

function AgentCountMatchingLines(const APath, ANeedle: string; ACancelFlag: PInteger;
  ACaseSensitive: Boolean; out AHits: Int64): Boolean;
var
  Lines: Int64;
begin
  AHits := 0;
  Result := FileExists(APath) and (Trim(ANeedle) <> '') and
    CountInFile(APath, ANeedle, ACancelFlag, AHits, Lines, ACaseSensitive, False);
end;

function AgentToolCount(AFiles: TStrings; const ANeedle: string; ASample: Integer;
  ACancelFlag: PInteger; ACaseSensitive: Boolean; AWholeWord: Boolean): string;
var
  SL: TStringList;
  I: Integer;
  Hits, Lines, Total, AllLines: Int64;
  Stopped: Boolean;
  Samples, SamplePath: string;
begin
  if AFiles = nil then
    Exit('error=no files');
  if Trim(ANeedle) = '' then
    Exit('error=empty needle');
  if ASample < 1 then
    ASample := 1;
  if ASample > 20 then
    ASample := 20;
  SL := TStringList.Create;
  try
    Total := 0;
    AllLines := 0;
    Stopped := False;
    Samples := '';
    SamplePath := '';
    SL.Add('needle=' + ANeedle);
    SL.Add('files=' + IntToStr(AFiles.Count));
    for I := 0 to AFiles.Count - 1 do
    begin
      if Cancelled(ACancelFlag) then
      begin
        Stopped := True;
        Break;
      end;
      if not FileExists(AFiles[I]) then
      begin
        SL.Add('file missing path=' + AFiles[I]);
        Continue;
      end;
      if not CountInFile(AFiles[I], ANeedle, ACancelFlag, Hits, Lines, ACaseSensitive, AWholeWord) then
        Stopped := True;
      Total := Total + Hits;
      AllLines := AllLines + Lines;
      SL.Add('file matching_lines=' + IntToStr(Hits) + ' total_lines=' + IntToStr(Lines) +
        ' path=' + AFiles[I]);
      if (Samples = '') and (Hits > 0) and (not Stopped) then
      begin
        Samples := CollectSamples(AFiles[I], ANeedle, ASample, ACancelFlag, ACaseSensitive, AWholeWord);
        SamplePath := AFiles[I];
      end;
      if Stopped then
        Break;
    end;
    SL.Insert(2, 'matching_lines=' + IntToStr(Total));
    SL.Insert(3, 'total_lines=' + IntToStr(AllLines));
    if Stopped then
      SL.Add('stopped=yes');
    SL.Add(MatchModeText(ACaseSensitive, AWholeWord));
    SL.Add('note=matching_lines counts lines that contain the needle. ' +
      'It is not a count of distinct people or records. Quote that number.');
    if Samples <> '' then
    begin
      SL.Add('samples from ' + SamplePath + ' (line|text):');
      SL.Add(TrimRight(Samples));
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

{ --- folder expansion ------------------------------------------------------------ }

function AgentExpandRoots(ARoots: TStrings; const APrefs: TAgentPrefs;
  AFiles: TStrings; AOnProgress: TAgentScanNotify): Boolean;
var
  Listed: Integer;
  Truncated: Boolean;

  function WantStop: Boolean;
  var
    Cancel: Boolean;
  begin
    Cancel := False;
    if Assigned(AOnProgress) and ((Listed mod 25) = 0) then
      AOnProgress(Listed, Cancel);
    Result := Cancel or Truncated or (Listed >= APrefs.MaxFiles);
    if Listed >= APrefs.MaxFiles then
      Truncated := True;
  end;

  procedure AddFile(const APath: string);
  begin
    if Truncated or (Listed >= APrefs.MaxFiles) then
    begin
      Truncated := True;
      Exit;
    end;
    if not FileExists(APath) then Exit;
    AFiles.Add(NormPath(APath));
    Inc(Listed);
  end;

  procedure Walk(const ADir: string; ADepth: Integer);
  var
    SR: TSearchRec;
    Spec, Full, Name: string;
  begin
    if Truncated or WantStop then Exit;
    Spec := IncludeTrailingPathDelimiter(ADir) + '*';
    if FindFirst(Spec, faAnyFile, SR) <> 0 then Exit;
    try
      repeat
        if Truncated then Break;
        Name := SR.Name;
        if (Name = '.') or (Name = '..') then Continue;
        Full := IncludeTrailingPathDelimiter(ADir) + Name;
        if (SR.Attr and faDirectory) <> 0 then
        begin
          if (SR.Attr and faSymLink) <> 0 then Continue;
          if SkipDirName(Name) then Continue;
          if APrefs.IncludeSubdirs and (ADepth < APrefs.MaxDepth) then
            Walk(Full, ADepth + 1);
        end
        else if MaskAllows(Name, APrefs.Mask) then
          AddFile(Full);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

var
  I: Integer;
  Kind, Path: string;
  Root: TAgentRoot;
begin
  Result := False;
  Listed := 0;
  Truncated := False;
  if AFiles = nil then Exit;
  for I := 0 to ARoots.Count - 1 do
  begin
    if Truncated then Break;
    Kind := '';
    Path := '';
    if ARoots.Objects[I] is TAgentRoot then
    begin
      Root := TAgentRoot(ARoots.Objects[I]);
      Path := Root.Path;
      if Root.Kind = arkFolder then
        Kind := 'D'
      else
        Kind := 'F';
    end
    else
    begin
      Path := ARoots[I];
      if Copy(Path, 1, 2) = 'D|' then
      begin
        Kind := 'D';
        Delete(Path, 1, 2);
      end
      else if Copy(Path, 1, 2) = 'F|' then
      begin
        Kind := 'F';
        Delete(Path, 1, 2);
      end
      else if DirectoryExists(Path) then
        Kind := 'D'
      else
        Kind := 'F';
    end;
    Path := Trim(Path);
    if Path = '' then Continue;
    if Kind = 'D' then
    begin
      if DirectoryExists(Path) then
        Walk(Path, 0);
    end
    else
      AddFile(Path);
    if WantStop then Break;
  end;
  Truncated := False;
  if Assigned(AOnProgress) then
    AOnProgress(Listed, Truncated);
  Result := not Truncated;
end;

end.
