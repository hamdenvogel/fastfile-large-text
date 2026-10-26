unit uAgentDescribe;

{
  describe_files tool of the agent: a short profile of each file (size, date, encoding, binary type,
  line ending, line count, delimiter and columns or fixed-width layout, first and last lines) so the model can say what the
  files are and what they are for. Reads the first 64 KB, a sample of lines (start + spread over the file) and the
  last lines; never the whole file.
}

interface

uses
  Classes;

{ ASampleLines: lines analyzed per file for the statistics (split among the files when there are more than 3). }
function AgentToolDescribe(AFiles: TStrings; ACancelFlag: PInteger; AMaxChars, ASampleLines: Integer): string;

implementation

uses
  SysUtils, StrUtils, Math, Character, Generics.Collections, Generics.Defaults, uAgentTools, uTextEncoding,
  uFastFilePaths, uEolPolicy;

const
  PROBE_BYTES = 64 * 1024;
  DESCRIBE_MAX_FILES = 40;
  DESCRIBE_LINE_CHARS = 200;
  { Few files: show sample lines whole (AgentToolReadLines already stops at 400), so a fixed-width record fits. }
  DESCRIBE_LINE_CHARS_FEW = 420;
  LINE_CUT_MARK = '...[line cut]';
  SAMPLE_LINE_MAX = 4000;
  SPREAD_BUF = 16 * 1024;
  MIN_SAMPLE_PER_FILE = 20;

function Cancelled(ACancel: PInteger): Boolean;
begin
  Result := Assigned(ACancel) and (ACancel^ <> 0);
end;

function HumanSize(ABytes: Int64): string;
begin
  if ABytes >= Int64(1024) * 1024 * 1024 then
    Result := FormatFloat('0.0', ABytes / (1024.0 * 1024 * 1024)) + ' GB'
  else if ABytes >= 1024 * 1024 then
    Result := FormatFloat('0.0', ABytes / (1024.0 * 1024)) + ' MB'
  else if ABytes >= 1024 then
    Result := FormatFloat('0.0', ABytes / 1024.0) + ' KB'
  else
    Result := IntToStr(ABytes) + ' bytes';
end;

function ReadProbe(const APath: string; out ASize: Int64): TBytes;
var
  F: TFileStream;
  N: Integer;
begin
  SetLength(Result, 0);
  ASize := 0;
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    ASize := F.Size;
    N := Integer(Min(Int64(PROBE_BYTES), ASize));
    SetLength(Result, N);
    if N > 0 then
      F.ReadBuffer(Result[0], N);
  finally
    F.Free;
  end;
end;

function StartsWithBytes(const B: TBytes; const ASig: array of Byte): Boolean;
var
  I: Integer;
begin
  Result := Length(B) >= Length(ASig);
  if not Result then Exit;
  for I := 0 to High(ASig) do
    if B[I] <> ASig[I] then
      Exit(False);
end;

function StartsWithText(const B: TBytes; const AText: AnsiString): Boolean;
var
  I: Integer;
begin
  Result := Length(B) >= Length(AText);
  if not Result then Exit;
  for I := 1 to Length(AText) do
    if B[I - 1] <> Ord(AText[I]) then
      Exit(False);
end;

{ Known binary formats by signature; '' when none matches. }
function BinaryKind(const B: TBytes; const AExt: string): string;
begin
  Result := '';
  if StartsWithText(B, 'PK'#3#4) then
  begin
    if (AExt = '.docx') or (AExt = '.xlsx') or (AExt = '.pptx') then
      Result := 'Office Open XML document (' + AExt + ', a ZIP container)'
    else if (AExt = '.odt') or (AExt = '.ods') or (AExt = '.odp') then
      Result := 'OpenDocument file (' + AExt + ', a ZIP container)'
    else if (AExt = '.jar') or (AExt = '.apk') then
      Result := 'Java/Android package (ZIP container)'
    else
      Result := 'ZIP archive';
  end
  else if StartsWithText(B, '%PDF') then
    Result := 'PDF document'
  else if StartsWithText(B, 'MZ') then
    Result := 'Windows executable or DLL'
  else if StartsWithBytes(B, [$89, $50, $4E, $47]) then
    Result := 'PNG image'
  else if StartsWithText(B, 'GIF8') then
    Result := 'GIF image'
  else if StartsWithBytes(B, [$FF, $D8, $FF]) then
    Result := 'JPEG image'
  else if StartsWithText(B, 'SQLite format 3') then
    Result := 'SQLite database'
  else if StartsWithBytes(B, [$D0, $CF, $11, $E0]) then
    Result := 'legacy Office document (.doc/.xls/.msg, OLE container)'
  else if StartsWithBytes(B, [$1F, $8B]) then
    Result := 'GZIP archive'
  else if StartsWithText(B, 'Rar!') then
    Result := 'RAR archive'
  else if StartsWithBytes(B, [$37, $7A, $BC, $AF]) then
    Result := '7-Zip archive';
end;

function HasNulBytes(const B: TBytes): Boolean;
var
  I, N: Integer;
begin
  N := Min(Length(B), 8192);
  for I := 0 to N - 1 do
    if B[I] = 0 then
      Exit(True);
  Result := False;
end;

function LineEndingOf(const B: TBytes): string;
var
  I, CrLf, Lf, Cr: Integer;
begin
  CrLf := 0;
  Lf := 0;
  Cr := 0;
  I := 0;
  while I < Length(B) do
  begin
    if B[I] = 13 then
    begin
      if (I + 1 < Length(B)) and (B[I + 1] = 10) then
      begin
        Inc(CrLf);
        Inc(I);
      end
      else if (I + 2 < Length(B)) and (B[I + 1] = 0) and (B[I + 2] = 10) then
      begin
        Inc(CrLf);
        Inc(I, 2);
      end
      else
        Inc(Cr);
    end
    else if B[I] = 10 then
      Inc(Lf);
    Inc(I);
  end;
  if CrLf + Lf + Cr = 0 then
    Result := 'none in the first 64 KB'
  else if (CrLf > 0) and (Lf = 0) and (Cr = 0) then
    Result := 'CRLF (Windows)'
  else if (Lf > 0) and (CrLf = 0) and (Cr = 0) then
    Result := 'LF (Unix)'
  else if (Cr > 0) and (CrLf = 0) and (Lf = 0) then
    Result := 'CR (old Mac)'
  else
    Result := 'mixed';
end;

function CountByte(const B: TBytes; AValue: Byte): Int64;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(B) do
    if B[I] = AValue then
      Inc(Result);
end;

function LineCountText(const APath: string; const B: TBytes; ASize: Int64): string;
var
  Known, Lf: Int64;
begin
  Known := FastFileKnownLineCount(APath);
  if Known > 0 then
    Exit(IntToStr(Known) + ' (exact)');
  if ASize = 0 then
    Exit('0');
  Lf := CountByte(B, 10);
  if ASize <= Length(B) then
  begin
    if B[High(B)] <> 10 then
      Inc(Lf);
    Exit(IntToStr(Lf) + ' (exact)');
  end;
  if Lf = 0 then
    Exit('unknown (no line break in the first 64 KB: very long lines or one-line file)');
  Result := 'about ' + IntToStr(Round(ASize / (Length(B) / Lf))) + ' (estimated from the first 64 KB)';
end;

{ "N|text" lines of AgentToolReadLines -> text only (AKeepNumbers keeps the "N|" prefix). }
function CleanLines(const AToolOut: string; AKeepNumbers: Boolean; out AEof: Boolean): TStringList;
var
  SL: TStringList;
  I, Bar: Integer;
  S: string;
begin
  AEof := False;
  Result := TStringList.Create;
  SL := TStringList.Create;
  try
    SL.Text := AToolOut;
    for I := 0 to SL.Count - 1 do
    begin
      S := SL[I];
      if S = 'eof=yes' then
      begin
        AEof := True;
        Continue;
      end;
      Bar := Pos('|', S);
      if (Bar < 2) or (StrToInt64Def(Copy(S, 1, Bar - 1), -1) < 0) then
        Continue;
      if not AKeepNumbers then
        S := Copy(S, Bar + 1, MaxInt);
      Result.Add(S);
    end;
  finally
    SL.Free;
  end;
end;

function CountChar(const S: string; C: Char): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(S) do
    if S[I] = C then
      Inc(Result);
end;

function HasDigit(const S: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if CharInSet(S[I], ['0'..'9']) then
      Exit(True);
  Result := False;
end;

{ Delimiter used with the same count on most of the first lines, the column count and the header. }
function DelimiterText(ALines: TStrings): string;
const
  CANDIDATES: array[0..3] of Char = (';', ',', #9, '|');
  NAMES: array[0..3] of string = ('";"', '","', 'TAB', '"|"');
var
  K, I, N, First, Same, Best, BestCount: Integer;
  Fields: TArray<string>;
  HeaderLike, DataHasDigits: Boolean;
begin
  Result := 'delimited=no (no separator repeats the same way on the first lines)';
  Best := -1;
  BestCount := 0;
  for K := 0 to High(CANDIDATES) do
  begin
    N := 0;
    Same := 0;
    First := -1;
    for I := 0 to Min(ALines.Count, 10) - 1 do
    begin
      if Trim(ALines[I]) = '' then Continue;
      Inc(N);
      if First < 0 then
        First := CountChar(ALines[I], CANDIDATES[K]);
      if (First > 0) and (CountChar(ALines[I], CANDIDATES[K]) = First) then
        Inc(Same);
    end;
    if (N >= 2) and (First > 0) and (Same * 10 >= N * 8) and (First > BestCount) then
    begin
      Best := K;
      BestCount := First;
    end;
  end;
  if Best < 0 then Exit;
  Result := 'delimited=yes delimiter=' + NAMES[Best] + ' columns=' + IntToStr(BestCount + 1);
  Fields := ALines[0].Split([CANDIDATES[Best]]);
  HeaderLike := True;
  for I := 0 to High(Fields) do
    if HasDigit(Fields[I]) and (Trim(Fields[I]) <> '') and (StrToFloatDef(Trim(Fields[I]), -1) >= 0) then
      HeaderLike := False;
  DataHasDigits := (ALines.Count > 1) and HasDigit(ALines[1]);
  if HeaderLike and DataHasDigits then
    Result := Result + ' header=probably yes, column names: ' + StringReplace(ALines[0], CANDIDATES[Best], ' | ',
      [rfReplaceAll])
  else
    Result := Result + ' header=unclear (first line looks like data)';
end;

function CutLine(const S: string; AMax: Integer): string;
begin
  if Length(S) > AMax then
    Result := Copy(S, 1, AMax) + ' ...'
  else
    Result := S;
end;

function AllDigits(const S: string; P, N: Integer): Boolean;
var
  I: Integer;
begin
  Result := P + N - 1 <= Length(S);
  if Result then
    for I := P to P + N - 1 do
      if not CharInSet(S[I], ['0'..'9']) then
        Exit(False);
end;

{ ADayFirst: DDMMYYYY, otherwise YYYYMMDD. }
function IsDateAt(const S: string; P: Integer; ADayFirst: Boolean): Boolean;
var
  D, M, Y: Integer;
begin
  Result := False;
  if not AllDigits(S, P, 8) then Exit;
  if ADayFirst then
  begin
    D := StrToInt(Copy(S, P, 2));
    M := StrToInt(Copy(S, P + 2, 2));
    Y := StrToInt(Copy(S, P + 4, 4));
  end
  else
  begin
    Y := StrToInt(Copy(S, P, 4));
    M := StrToInt(Copy(S, P + 4, 2));
    D := StrToInt(Copy(S, P + 6, 2));
  end;
  Result := (D >= 1) and (D <= 31) and (M >= 1) and (M <= 12) and (Y >= 1950) and (Y <= 2079);
end;

{ Lines of one fixed length with no separator: record length, other lengths and a guessed field layout
  (constant parts, numbers, zero-padded numbers, dates, letters) from the sample lines. '' when not fixed width. }
function FixedWidthText(ALines: TStrings): string;
const
  MAX_FIELDS = 45;
  ZERO_PAD = 15;
  MAX_OTHER_LENS = 6;
  MAX_EXAMPLES = 3;
var
  Lens: TDictionary<Integer, Integer>;
  OtherLens: TList<TPair<Integer, Integer>>;
  Recs: TStringList;
  Pair: TPair<Integer, Integer>;
  L, Best, BestN, NonEmpty, I, J, P, Fields, Start: Integer;
  Cls: array of Char;
  DateKind: array of Char;
  Others, Examples, Vals, Seg, First: string;
  Same, Digits, Letters: Boolean;
  SB: TStringBuilder;

  function DateRate(APos: Integer; ADayFirst: Boolean): Boolean;
  var
    K, Hits: Integer;
  begin
    Hits := 0;
    for K := 0 to Recs.Count - 1 do
      if IsDateAt(Recs[K], APos, ADayFirst) then
        Inc(Hits);
    Result := Hits * 10 >= Recs.Count * 9;
  end;

  { "01 x420, 02 x50" when the field has at most 8 values in the sample, otherwise ''. }
  function DistinctValues(APos, ALen: Integer): string;
  var
    K, Idx: Integer;
    V: TStringList;
  begin
    Result := '';
    V := TStringList.Create;
    try
      V.Sorted := True;
      for K := 0 to Recs.Count - 1 do
      begin
        if V.Find(Copy(Recs[K], APos, ALen), Idx) then
          V.Objects[Idx] := TObject(NativeInt(V.Objects[Idx]) + 1)
        else
        begin
          if V.Count >= 8 then
            Exit('');
          V.AddObject(Copy(Recs[K], APos, ALen), TObject(1));
        end;
      end;
      for K := 0 to V.Count - 1 do
      begin
        if K > 0 then
          Result := Result + ', ';
        Result := Result + V[K] + ' x' + IntToStr(NativeInt(V.Objects[K]));
      end;
    finally
      V.Free;
    end;
  end;

  { Earliest and latest valid date of the field in the sample, as written in the file. }
  function DateRange(APos: Integer; ADayFirst: Boolean): string;
  var
    K: Integer;
    S, Key, MinKey, MaxKey, MinTxt, MaxTxt: string;
  begin
    MinKey := '';
    MaxKey := '';
    for K := 0 to Recs.Count - 1 do
      if IsDateAt(Recs[K], APos, ADayFirst) then
      begin
        S := Copy(Recs[K], APos, 8);
        if ADayFirst then
          Key := Copy(S, 5, 4) + Copy(S, 3, 2) + Copy(S, 1, 2)
        else
          Key := S;
        if (MinKey = '') or (Key < MinKey) then
        begin
          MinKey := Key;
          MinTxt := S;
        end;
        if (MaxKey = '') or (Key > MaxKey) then
        begin
          MaxKey := Key;
          MaxTxt := S;
        end;
      end;
    if MinKey = '' then
      Result := ''
    else
      Result := ', from ' + MinTxt + ' to ' + MaxTxt + ' in the sample';
  end;

  procedure AddField(AFrom, ATo: Integer; AKind: Char);
  var
    W: Integer;
    Txt: string;
  begin
    if Fields >= MAX_FIELDS then
    begin
      if Fields = MAX_FIELDS then
        SB.Append(' | ...');
      Inc(Fields);
      Exit;
    end;
    W := ATo - AFrom + 1;
    Txt := Copy(Recs[0], AFrom, W);
    if Fields > 0 then
      SB.Append(' | ');
    SB.Append(IntToStr(AFrom) + '-' + IntToStr(ATo) + ' ');
    case AKind of
      'C':
        if StringOfChar(Txt[1], W) = Txt then
        begin
          if Txt[1] = '0' then
            SB.Append('zeros')
          else if Txt[1] = ' ' then
            SB.Append('blanks')
          else
            SB.Append('constant "' + Txt + '"');
        end
        else
          SB.Append('constant "' + Txt + '"');
      'D': SB.Append('date DDMMYYYY (' + Txt + DateRange(AFrom, True) + ')');
      'Y': SB.Append('date YYYYMMDD (' + Txt + DateRange(AFrom, False) + ')');
      'Z': SB.Append('zero-padded number (' + Txt + ')');
      'N':
        begin
          Vals := '';
          if W <= 4 then
            Vals := DistinctValues(AFrom, W);
          if Vals <> '' then
            SB.Append('code (' + Vals + ')')
          else
            SB.Append('number (' + Txt + ')');
        end;
      'A': SB.Append('text (' + Trim(Txt) + ')');
    else
      SB.Append('mixed (' + Txt + ')');
    end;
    Inc(Fields);
  end;

begin
  Result := '';
  Lens := TDictionary<Integer, Integer>.Create;
  Recs := TStringList.Create;
  try
    NonEmpty := 0;
    for I := 0 to ALines.Count - 1 do
    begin
      L := Length(ALines[I]);
      if L = 0 then Continue;
      Inc(NonEmpty);
      if Lens.ContainsKey(L) then
        Lens[L] := Lens[L] + 1
      else
        Lens.Add(L, 1);
    end;
    Best := 0;
    BestN := 0;
    for Pair in Lens do
      if Pair.Value > BestN then
      begin
        Best := Pair.Key;
        BestN := Pair.Value;
      end;
    if (NonEmpty < 3) or (Best < 20) or (BestN * 10 < NonEmpty * 6) then Exit;
    for I := 0 to ALines.Count - 1 do
      if Length(ALines[I]) = Best then
        Recs.Add(ALines[I]);

    { Other lengths, most frequent first, each with one example line. }
    Others := '';
    Examples := '';
    OtherLens := TList<TPair<Integer, Integer>>.Create;
    try
      for Pair in Lens do
        if Pair.Key <> Best then
          OtherLens.Add(Pair);
      OtherLens.Sort(TComparer<TPair<Integer, Integer>>.Construct(
        function(const A, B: TPair<Integer, Integer>): Integer
        begin
          Result := B.Value - A.Value;
        end));
      for J := 0 to Min(OtherLens.Count, MAX_OTHER_LENS) - 1 do
      begin
        Others := Others + ', ' + IntToStr(OtherLens[J].Key) + ' chars (' + IntToStr(OtherLens[J].Value) + ' line(s))';
        if J < MAX_EXAMPLES then
          for I := 0 to ALines.Count - 1 do
            if Length(ALines[I]) = OtherLens[J].Key then
            begin
              Examples := Examples + #13#10 + CutLine(ALines[I], DESCRIBE_LINE_CHARS_FEW);
              Break;
            end;
      end;
      if OtherLens.Count > MAX_OTHER_LENS then
        Others := Others + ', ' + IntToStr(OtherLens.Count - MAX_OTHER_LENS) + ' more length(s)';
    finally
      OtherLens.Free;
    end;

    SetLength(Cls, Best + 1);
    SetLength(DateKind, Best + 1);
    for P := 1 to Best do
      DateKind[P] := #0;
    P := 1;
    while P <= Best - 7 do
    begin
      if DateRate(P, True) then
      begin
        for J := P to P + 7 do
          DateKind[J] := 'D';
        Inc(P, 8);
      end
      else if DateRate(P, False) then
      begin
        for J := P to P + 7 do
          DateKind[J] := 'Y';
        Inc(P, 8);
      end
      else
        Inc(P);
    end;

    for P := 1 to Best do
    begin
      if DateKind[P] <> #0 then
      begin
        Cls[P] := DateKind[P];
        Continue;
      end;
      First := Recs[0][P];
      Same := True;
      Digits := True;
      Letters := True;
      for I := 0 to Recs.Count - 1 do
      begin
        if Recs[I][P] <> First then
          Same := False;
        if not CharInSet(Recs[I][P], ['0'..'9']) then
          Digits := False;
        if not (Recs[I][P].IsLetter or (Recs[I][P] = ' ')) then
          Letters := False;
      end;
      if Same and (Recs.Count > 1) then
        Cls[P] := 'C'
      else if Digits then
        Cls[P] := 'N'
      else if Letters then
        Cls[P] := 'A'
      else
        Cls[P] := 'X';
    end;
    { Up to ZERO_PAD constant zeros right before a varying number are its padding; longer runs are filler. }
    P := Best - 1;
    while P >= 1 do
    begin
      if (Cls[P] = 'C') and (Recs[0][P] = '0') and (Cls[P + 1] = 'N') then
      begin
        J := P;
        while (J >= 1) and (Cls[J] = 'C') and (Recs[0][J] = '0') do
          Dec(J);
        if P - J <= ZERO_PAD then
          for I := J + 1 to P do
            Cls[I] := 'Z';
        P := J;
      end
      else
        Dec(P);
    end;

    SB := TStringBuilder.Create;
    try
      SB.Append('fixed_width=probably yes record_length=' + IntToStr(Best) + ' (' + IntToStr(BestN) + ' of ' +
        IntToStr(NonEmpty) + ' sample lines)');
      if Others <> '' then
        SB.Append(' other_lengths=' + Copy(Others, 3, MaxInt) + ' (other record types, e.g. header / trailer)');
      SB.Append(#13#10'layout guessed from ' + IntToStr(Recs.Count) + ' sample records (positions 1-based; ' +
        '"constant" = same in every sample line, it may still vary further in the file): ');
      Fields := 0;
      Start := 1;
      P := 2;
      while P <= Best + 1 do
      begin
        if (P <= Best) and (Cls[Start] = 'Z') and (Cls[P] = 'N') then
        begin
          while (P <= Best) and (Cls[P] = 'N') do
            Inc(P);
          AddField(Start, P - 1, 'Z');
          Start := P;
        end
        else if (P > Best) or (Cls[P] <> Cls[Start]) or
           (CharInSet(Cls[P], ['D', 'Y']) and ((P - Start) mod 8 = 0)) then
        begin
          AddField(Start, P - 1, Cls[Start]);
          Start := P;
        end;
        Inc(P);
      end;
      if Examples <> '' then
        SB.Append(#13#10'other_record_examples (one per other length):' + Examples);
      Seg := SB.ToString;
    finally
      SB.Free;
    end;
    Result := Seg;
  finally
    Recs.Free;
    Lens.Free;
  end;
end;

{ Up to ACount lines for the statistics only (never sent as is): half from line 1, the rest spread over the file
  (the line that starts after each of ACount/2 byte offsets), so record types and dates of the whole file show
  up without a full pass. UTF-16/32 files and short files take every line from the start. }
procedure ReadSample(const APath, AEnc: string; ASize: Int64; ACount: Integer; ACancelFlag: PInteger;
  ASample: TStrings; out AFromStart, ASpread: Integer);
var
  Raw: TAgentRawLines;
  F: TFileStream;
  Buf: TBytes;
  Wide: Boolean;
  Term: Byte;
  I, K, M, N, P1, P2: Integer;
  HeadEnd, Ofs, LastLine: Int64;
  S: AnsiString;
  Txt: string;
begin
  AFromStart := 0;
  ASpread := 0;
  if ACount < 1 then Exit;
  Wide := IsUtf16LEEncoding(AEnc) or IsUtf16BEEncoding(AEnc) or IsUtf32LEEncoding(AEnc) or IsUtf32BEEncoding(AEnc);
  K := ACount;
  if not Wide then
    K := (ACount + 1) div 2;
  Raw := AgentReadRawLines(APath, 1, K, '', ACancelFlag);
  for I := 0 to High(Raw) do
  begin
    Txt := FileBytesToUnicodeText(AlignWideLine(Raw[I].Raw, AEnc), AEnc);
    if Length(Txt) <= SAMPLE_LINE_MAX then
      ASample.Add(Txt);
  end;
  AFromStart := Length(Raw);
  if Wide or (Length(Raw) < K) or Cancelled(ACancelFlag) then Exit;

  HeadEnd := Raw[High(Raw)].Ofs + Length(Raw[High(Raw)].Raw) + 1;
  M := ACount - K;
  if (M < 1) or (ASize - HeadEnd < SPREAD_BUF) then Exit;
  Term := LineTermByteForFile(APath);
  SetLength(Buf, SPREAD_BUF);
  LastLine := HeadEnd - 1;
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    for I := 1 to M do
    begin
      if Cancelled(ACancelFlag) then Break;
      Ofs := HeadEnd + (ASize - HeadEnd) * I div (M + 1);
      F.Position := Ofs;
      N := F.Read(Buf[0], SPREAD_BUF);
      P1 := 0;
      while (P1 < N) and (Buf[P1] <> Term) do
        Inc(P1);
      P2 := P1 + 1;
      while (P2 < N) and (Buf[P2] <> Term) do
        Inc(P2);
      if P2 >= N then Continue;
      if Ofs + P1 + 1 <= LastLine then Continue;
      LastLine := Ofs + P1 + 1;
      SetString(S, PAnsiChar(@Buf[P1 + 1]), P2 - P1 - 1);
      if (Length(S) > 0) and (S[Length(S)] = #13) then
        SetLength(S, Length(S) - 1);
      ASample.Add(FileBytesToUnicodeText(S, AEnc));
      Inc(ASpread);
    end;
  finally
    F.Free;
  end;
end;

function DescribeOne(const APath: string; AHead, ATail, ALineChars, ASampleLines: Integer;
  ACancelFlag: PInteger): string;
var
  SL, Head, Tail, Sample: TStringList;
  B: TBytes;
  Size: Int64;
  Ext, Enc, Kind, Delim, Fixed: string;
  Eof: Boolean;
  I, FromStart, Spread, TailN: Integer;
  TailTxt: TArray<string>;
  LastNo: Int64;
  Modified: TDateTime;
begin
  SL := TStringList.Create;
  try
    SL.Add('file=' + APath);
    if not FileExists(APath) then
    begin
      SL.Add('error=file not found');
      Exit(SL.Text);
    end;
    Ext := LowerCase(ExtractFileExt(APath));
    try
      B := ReadProbe(APath, Size);
    except
      on E: Exception do
      begin
        SL.Add('error=cannot read the file: ' + E.Message);
        Exit(SL.Text);
      end;
    end;
    if not FileAge(APath, Modified) then
      Modified := 0;
    SL.Add('name=' + ExtractFileName(APath) + ' extension=' + Ext + ' size=' + HumanSize(Size) +
      ' modified=' + FormatDateTime('yyyy-mm-dd hh:nn', Modified));
    if Size = 0 then
    begin
      SL.Add('content=empty file');
      Exit(SL.Text);
    end;
    Enc := DetectTextFileEncoding(APath);
    Kind := BinaryKind(B, Ext);
    if (Kind = '') and HasNulBytes(B) and not IsUnicodeFileEncoding(Enc) then
      Kind := 'binary data (unknown format)';
    if Kind <> '' then
    begin
      SL.Add('binary=yes type=' + Kind + ' (FastFile tools read text lines; its content cannot be listed here)');
      Exit(SL.Text);
    end;
    SL.Add('binary=no encoding=' + Enc + ' line_ending=' + LineEndingOf(B));
    SL.Add('lines=' + LineCountText(APath, B, Size));
    Head := CleanLines(AgentToolReadLines(APath, 1, AHead, ACancelFlag), False, Eof);
    Tail := nil;
    Sample := TStringList.Create;
    try
      if (not Eof) and (ATail > 0) and not Cancelled(ACancelFlag) then
      begin
        { No full pass to number them: a multi-GB file would take many seconds just to count its lines. }
        TailTxt := AgentReadTailTexts(APath, ATail, LastNo);
        Tail := TStringList.Create;
        for I := 0 to High(TailTxt) do
          if LastNo > 0 then
            Tail.Add(IntToStr(LastNo - High(TailTxt) + I) + '|' + TailTxt[I])
          else
            Tail.Add('end-' + IntToStr(High(TailTxt) - I) + '|' + TailTxt[I]);
      end;
      if Eof then
      begin
        for I := 0 to Head.Count - 1 do
          if not EndsText(LINE_CUT_MARK, Head[I]) then
            Sample.Add(Head[I]);
      end
      else
      begin
        ReadSample(APath, Enc, Size, Max(ASampleLines, Head.Count), ACancelFlag, Sample, FromStart, Spread);
        TailN := 0;
        if Assigned(Tail) then
          for I := 0 to Tail.Count - 1 do
            if Length(Tail[I]) <= SAMPLE_LINE_MAX then
            begin
              Sample.Add(Copy(Tail[I], Pos('|', Tail[I]) + 1, MaxInt));
              Inc(TailN);
            end;
        SL.Add('sample_analyzed=' + IntToStr(Sample.Count) + ' lines (' + IntToStr(FromStart) +
          ' from the start, ' + IntToStr(Spread) + ' spread through the file, ' + IntToStr(TailN) +
          ' from the end); only a few are listed below, the statistics and layout come from all of them');
      end;
      if Head.Count > 0 then
      begin
        Delim := DelimiterText(Head);
        SL.Add(Delim);
        if not StartsText('delimited=yes', Delim) then
        begin
          Fixed := FixedWidthText(Sample);
          if Fixed <> '' then
            SL.Add(Fixed);
        end;
      end;
      SL.Add('first_lines:');
      for I := 0 to Head.Count - 1 do
        SL.Add(IntToStr(I + 1) + '|' + CutLine(Head[I], ALineChars));
      if Assigned(Tail) and (Tail.Count > 0) then
      begin
        if LastNo > 0 then
          SL.Add('last_lines:')
        else
          SL.Add('last_lines (end-0 is the last line; exact line numbers are not counted here, read_lines ' +
            'with "last" gives them):');
        for I := 0 to Tail.Count - 1 do
          SL.Add(CutLine(Tail[I], ALineChars));
      end
      else if Eof then
        SL.Add('note=the whole file is shown above');
    finally
      Sample.Free;
      Tail.Free;
      Head.Free;
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function AgentToolDescribe(AFiles: TStrings; ACancelFlag: PInteger; AMaxChars, ASampleLines: Integer): string;
var
  I, N, HeadN, TailN, PerFile, LineChars, SampleN: Integer;
  One: string;
  SB: TStringBuilder;
begin
  if (AFiles = nil) or (AFiles.Count = 0) then
    Exit('error=no file to describe');
  N := Min(AFiles.Count, DESCRIBE_MAX_FILES);
  LineChars := DESCRIBE_LINE_CHARS;
  if N <= 3 then
  begin
    HeadN := 12;
    TailN := 5;
    LineChars := DESCRIBE_LINE_CHARS_FEW;
  end
  else if N <= 10 then
  begin
    HeadN := 6;
    TailN := 3;
  end
  else
  begin
    HeadN := 3;
    TailN := 0;
  end;
  PerFile := Max(600, AMaxChars div N);
  SampleN := ASampleLines;
  if N > 3 then
    SampleN := Max(MIN_SAMPLE_PER_FILE, ASampleLines div N);
  SB := TStringBuilder.Create;
  try
    SB.Append('files_described=' + IntToStr(N) + ' of ' + IntToStr(AFiles.Count) + #13#10);
    for I := 0 to N - 1 do
    begin
      if Cancelled(ACancelFlag) then
      begin
        SB.Append('stopped=yes' + #13#10);
        Break;
      end;
      One := DescribeOne(AFiles[I], HeadN, TailN, LineChars, SampleN, ACancelFlag);
      if Length(One) > PerFile then
        One := Copy(One, 1, PerFile) + #13#10 + '...[profile cut]' + #13#10;
      SB.Append('---' + #13#10 + One);
    end;
    if AFiles.Count > N then
      SB.Append('note=' + IntToStr(AFiles.Count - N) + ' more file(s) not described; send describe_files with ' +
        '"path" for a specific one' + #13#10);
    SB.Append('note=this is a profile from a few lines, not the whole content. If it is not enough to say what a ' +
      'file is for, read more lines yourself now (read_lines further into the file, search a code) before you ' +
      'answer; never ask the user to do it.');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
