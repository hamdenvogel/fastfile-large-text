unit uTextEncoding;

{
  Texto Unicode no FastFile (Delphi 10.4: string = UTF-16).
  Disco continua em octetos; toda operacao de utilizador (ver, procurar,
  filtrar, substituir, editar) passa por FileBytes <-> WideString no encoding
  do ficheiro — nunca por truncagem silenciosa CP_ACP.
}

interface

uses
  uPosBMH,
  Windows, SysUtils, Classes;

function Utf8AnsiToWideString(const Utf8: AnsiString): WideString;
function WideStringToAnsiACP(const W: WideString): AnsiString;

function DisplayTextFromFileBytes(const Raw: AnsiString; const DisplayEncoding: string): string;
function DisplayStringToFileBytes(const S: string; const DisplayEncoding: string): AnsiString;

{ Alias explicitos: texto Unicode da UI <-> octetos do ficheiro. }
function FileBytesToUnicodeText(const Raw: AnsiString; const Enc: string): string;
function UnicodeTextToFileBytes(const S: string; const Enc: string): AnsiString;
function FileBytesToWideString(const Raw: AnsiString; const Enc: string): WideString;
function WideStringToFileBytes(const W: WideString; const Enc: string): AnsiString;
{ UTF-16 line split on the byte 0A: drops the BOM, the 00 left from the line break
  (LE: leading, BE: trailing) and the CR unit. AHadCR tells whether the break was CR LF.
  Other encodings: returned unchanged, AHadCR = False. }
function Utf16LineBytes(const Raw: AnsiString; const Enc: string; out AHadCR: Boolean): AnsiString;
{ CR LF or LF in the given UTF-16 byte order. }
function Utf16LineBreakBytes(const Enc: string; ACR: Boolean): AnsiString;

function ResolveTextEncoding(const AFileName: string; const AHint: string = ''): string;
function IsUtf8Encoding(const Enc: string): Boolean;
function IsUtf16LEEncoding(const Enc: string): Boolean;
function IsUtf16BEEncoding(const Enc: string): Boolean;
function IsUtf32LEEncoding(const Enc: string): Boolean;
function IsUtf32BEEncoding(const Enc: string): Boolean;
function IsUnicodeFileEncoding(const Enc: string): Boolean;
{ Explicit Windows / ISO / OEM code page (e.g. CP1252, Windows-1250, ISO-8859-1). }
function TryGetCodePageFromEncoding(const Enc: string; out CodePage: UINT): Boolean;
function IsCodePageEncoding(const Enc: string): Boolean;
function NormalizeCodePageEncodingId(CodePage: UINT): string;
function CodePageBytesToWideString(const Raw: AnsiString; CodePage: UINT): WideString;
function WideStringToCodePageBytes(const W: WideString; CodePage: UINT): AnsiString;
{ Trailing incomplete MBCS bytes to keep when streaming GB-sized files (0 for SBCS). }
function MbcsIncompleteTrailingBytes(const Buf: AnsiString; CodePage: UINT): Integer;
function IsAsciiOnlyText(const S: string): Boolean;
{ True se ignore-case precisa de comparar em Unicode (needle nao-ASCII + UTF). }
function EncodingNeedsWideCompare(const Enc, Needle: string): Boolean;

function UnicodeUpperCaseW(const S: string): string;
function UnicodeContainsText(const Haystack, Needle: string; ACaseSensitive: Boolean): Boolean;
function UnicodeStartsWithText(const Haystack, Needle: string; ACaseSensitive: Boolean): Boolean;
function UnicodeLineMatches(const LineRaw: AnsiString; const Needle, Enc: string;
  ACaseSensitive, APrefix: Boolean): Boolean;

procedure ClipboardSetUnicodeText(const W: WideString);
function IsProbablyUtf8(const S: AnsiString): Boolean;
function Utf8HeuristicToDisplayString(const S: string): string;
function RawBytesToDisplayString(const Raw: AnsiString): string;
function DetectTextEncodingFromBytes(const Sample: AnsiString): string;
function DetectTextFileEncoding(const AFileName: string): string;

implementation

uses
  Forms,
  ClipBrd;

function EncUpper(const Enc: string): string;
begin
  Result := UpperCase(Trim(Enc));
end;

function IsUtf8Encoding(const Enc: string): Boolean;
var
  U: string;
begin
  U := EncUpper(Enc);
  Result := (PosBMH('UTF-8', U) > 0) or (PosBMH('UTF8', U) > 0);
end;

function IsUtf16LEEncoding(const Enc: string): Boolean;
var
  U: string;
begin
  U := EncUpper(Enc);
  Result := (PosBMH('UTF-16', U) > 0) and (PosBMH('BE', U) = 0) and (PosBMH('UTF-32', U) = 0);
end;

function IsUtf16BEEncoding(const Enc: string): Boolean;
var
  U: string;
begin
  U := EncUpper(Enc);
  Result := (PosBMH('UTF-16 BE', U) > 0) or (PosBMH('UTF16 BE', U) > 0);
end;

function IsUtf32LEEncoding(const Enc: string): Boolean;
var
  U: string;
begin
  U := EncUpper(Enc);
  Result := (PosBMH('UTF-32', U) > 0) and (PosBMH('BE', U) = 0);
end;

function IsUtf32BEEncoding(const Enc: string): Boolean;
var
  U: string;
begin
  U := EncUpper(Enc);
  Result := (PosBMH('UTF-32 BE', U) > 0) or (PosBMH('UTF32 BE', U) > 0);
end;

function IsUnicodeFileEncoding(const Enc: string): Boolean;
begin
  Result := IsUtf8Encoding(Enc) or IsUtf16LEEncoding(Enc) or IsUtf16BEEncoding(Enc) or
    IsUtf32LEEncoding(Enc) or IsUtf32BEEncoding(Enc);
end;

function NormalizeCodePageEncodingId(CodePage: UINT): string;
begin
  if CodePage = 0 then
    Result := 'ANSI'
  else
    Result := 'CP' + IntToStr(CodePage);
end;

function TryGetCodePageFromEncoding(const Enc: string; out CodePage: UINT): Boolean;
var
  U, Digits: string;
  I: Integer;
  N: Integer;
begin
  Result := False;
  CodePage := 0;
  U := EncUpper(Enc);
  if (U = '') or (U = 'ANSI') or (U = 'SYSTEM') or (U = 'ACP') then
  begin
    CodePage := CP_ACP;
    Result := True;
    Exit;
  end;
  if IsUnicodeFileEncoding(U) then Exit;

  { CP1252 / CP-1252 / WINDOWS-1252 / WIN1252 }
  if (Copy(U, 1, 2) = 'CP') then
  begin
    Digits := '';
    I := 3;
    if (I <= Length(U)) and (U[I] = '-') then Inc(I);
    while (I <= Length(U)) and (U[I] >= '0') and (U[I] <= '9') do
    begin
      Digits := Digits + U[I];
      Inc(I);
    end;
    if Digits <> '' then
    begin
      N := StrToIntDef(Digits, -1);
      if (N > 0) and (N <> Integer(CP_UTF8)) then
      begin
        CodePage := UINT(N);
        Result := True;
        Exit;
      end;
    end;
  end;

  if PosBMH('WINDOWS-', U) = 1 then
  begin
    N := StrToIntDef(Copy(U, 9, MaxInt), -1);
    if N > 0 then
    begin
      CodePage := UINT(N);
      Result := True;
      Exit;
    end;
  end;
  if PosBMH('WIN', U) = 1 then
  begin
    Digits := '';
    I := 4;
    while (I <= Length(U)) and (not ((U[I] >= '0') and (U[I] <= '9'))) do Inc(I);
    while (I <= Length(U)) and (U[I] >= '0') and (U[I] <= '9') do
    begin
      Digits := Digits + U[I];
      Inc(I);
    end;
    if Digits <> '' then
    begin
      N := StrToIntDef(Digits, -1);
      if N > 0 then
      begin
        CodePage := UINT(N);
        Result := True;
        Exit;
      end;
    end;
  end;

  { ISO-8859-n }
  if PosBMH('ISO-8859-', U) > 0 then
  begin
    I := PosBMH('ISO-8859-', U) + Length('ISO-8859-');
    Digits := '';
    while (I <= Length(U)) and (U[I] >= '0') and (U[I] <= '9') do
    begin
      Digits := Digits + U[I];
      Inc(I);
    end;
    case StrToIntDef(Digits, -1) of
      1: begin CodePage := 28591; Result := True; end;
      2: begin CodePage := 28592; Result := True; end;
      3: begin CodePage := 28593; Result := True; end;
      4: begin CodePage := 28594; Result := True; end;
      5: begin CodePage := 28595; Result := True; end;
      6: begin CodePage := 28596; Result := True; end;
      7: begin CodePage := 28597; Result := True; end;
      8: begin CodePage := 28598; Result := True; end;
      9: begin CodePage := 28599; Result := True; end;
      13: begin CodePage := 28603; Result := True; end;
      15: begin CodePage := 28605; Result := True; end;
    end;
    if Result then Exit;
  end;

  if (PosBMH('KOI8-R', U) > 0) or (U = 'KOI8R') then
  begin CodePage := 20866; Result := True; Exit; end;
  if (PosBMH('KOI8-U', U) > 0) or (U = 'KOI8U') then
  begin CodePage := 21866; Result := True; Exit; end;
  if (PosBMH('SHIFT-JIS', U) > 0) or (PosBMH('SHIFT_JIS', U) > 0) or
     (PosBMH('SJIS', U) > 0) then
  begin CodePage := 932; Result := True; Exit; end;
  if (PosBMH('GB18030', U) > 0) then
  begin CodePage := 54936; Result := True; Exit; end;
  if (PosBMH('GBK', U) > 0) or (PosBMH('GB2312', U) > 0) then
  begin CodePage := 936; Result := True; Exit; end;
  if (PosBMH('BIG5', U) > 0) or (PosBMH('BIG-5', U) > 0) then
  begin CodePage := 950; Result := True; Exit; end;
  if (PosBMH('EUC-KR', U) > 0) or (PosBMH('EUCKR', U) > 0) then
  begin CodePage := 949; Result := True; Exit; end;
  if (PosBMH('OEM-US', U) > 0) or (PosBMH('CP437', U) > 0) or (U = 'IBM437') then
  begin CodePage := 437; Result := True; Exit; end;
  if (PosBMH('OEM 850', U) > 0) or (PosBMH('OEM-850', U) > 0) or
     (PosBMH('CP850', U) > 0) or (U = 'IBM850') then
  begin CodePage := 850; Result := True; Exit; end;
  if (PosBMH('OEM 866', U) > 0) or (PosBMH('OEM-866', U) > 0) or
     (PosBMH('CP866', U) > 0) or (U = 'IBM866') then
  begin CodePage := 866; Result := True; Exit; end;
  if (PosBMH('OEM 852', U) > 0) or (PosBMH('CP852', U) > 0) then
  begin CodePage := 852; Result := True; Exit; end;
  if (PosBMH('MACINTOSH', U) > 0) or (PosBMH('MAC ROMAN', U) > 0) or
     (PosBMH('MAC-ROMAN', U) > 0) then
  begin CodePage := 10000; Result := True; Exit; end;
end;

function IsCodePageEncoding(const Enc: string): Boolean;
var
  CP: UINT;
begin
  Result := TryGetCodePageFromEncoding(Enc, CP);
end;

function CodePageBytesToWideString(const Raw: AnsiString; CodePage: UINT): WideString;
var
  Len: Integer;
  CP: UINT;
begin
  Result := '';
  if Raw = '' then Exit;
  CP := CodePage;
  if CP = 0 then CP := CP_ACP;
  Len := MultiByteToWideChar(CP, 0, PAnsiChar(Raw), Length(Raw), nil, 0);
  if Len <= 0 then
  begin
    if CP = CP_ACP then
      Result := WideString(string(Raw));
    Exit;
  end;
  SetLength(Result, Len);
  MultiByteToWideChar(CP, 0, PAnsiChar(Raw), Length(Raw), PWideChar(Result), Len);
end;

function WideStringToCodePageBytes(const W: WideString; CodePage: UINT): AnsiString;
var
  Len: Integer;
  CP: UINT;
begin
  Result := '';
  if W = '' then Exit;
  CP := CodePage;
  if CP = 0 then CP := CP_ACP;
  Len := WideCharToMultiByte(CP, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
  if Len <= 0 then Exit;
  SetLength(Result, Len);
  WideCharToMultiByte(CP, 0, PWideChar(W), Length(W), PAnsiChar(Result), Len, nil, nil);
end;

function MbcsIncompleteTrailingBytes(const Buf: AnsiString; CodePage: UINT): Integer;
{ Keep trailing bytes that may start an incomplete multi-byte sequence. }
var
  N: Integer;
  B: Byte;
  CP: UINT;
begin
  Result := 0;
  N := Length(Buf);
  if N = 0 then Exit;
  CP := CodePage;
  if CP = 0 then CP := CP_ACP;
  { UTF-8 handled elsewhere; SBCS Western pages need no carry. }
  case CP of
    437, 850, 852, 855, 857, 860, 861, 862, 863, 864, 865, 866, 869,
    874, 1250, 1251, 1252, 1253, 1254, 1255, 1256, 1257, 1258,
    28591, 28592, 28593, 28594, 28595, 28596, 28597, 28598, 28599,
    28603, 28605, 20866, 21866, 10000:
      Exit;
  end;
  if CP = 54936 then
  begin
    { GB18030: up to 4 bytes. Keep 1..3 if last lead-like byte. }
    B := Ord(Buf[N]);
    if (B >= $81) and (B <= $FE) then
      Result := 1
    else if N >= 2 then
    begin
      B := Ord(Buf[N - 1]);
      if (B >= $81) and (B <= $FE) then
        Result := 2
      else if N >= 3 then
      begin
        B := Ord(Buf[N - 2]);
        if (B >= $81) and (B <= $FE) then
          Result := 3;
      end;
    end;
    Exit;
  end;
  if IsDBCSLeadByteEx(CP, Byte(Buf[N])) then
    Result := 1;
end;

function IsAsciiOnlyText(const S: string): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to Length(S) do
    if Ord(S[I]) > 127 then
    begin
      Result := False;
      Exit;
    end;
end;

function EncodingNeedsWideCompare(const Enc, Needle: string): Boolean;
begin
  Result := (not IsAsciiOnlyText(Needle)) and
    (IsUnicodeFileEncoding(Enc) or IsCodePageEncoding(Enc));
end;

function ResolveTextEncoding(const AFileName: string; const AHint: string): string;
begin
  Result := Trim(AHint);
  if Result = '' then
    Result := DetectTextFileEncoding(AFileName);
  if Result = '' then
    Result := 'ANSI';
end;

function Utf8AnsiToWideString(const Utf8: AnsiString): WideString;
var
  Len: Integer;
begin
  Result := '';
  if Utf8 = '' then Exit;
  Len := MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(Utf8), Length(Utf8), nil, 0);
  if Len <= 0 then Exit;
  SetLength(Result, Len);
  MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(Utf8), Length(Utf8), PWideChar(Result), Len);
end;

function WideStringToAnsiACP(const W: WideString): AnsiString;
var
  Len: Integer;
begin
  Result := '';
  if W = '' then Exit;
  Len := WideCharToMultiByte(CP_ACP, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
  if Len <= 0 then Exit;
  SetLength(Result, Len);
  WideCharToMultiByte(CP_ACP, 0, PWideChar(W), Length(W), PAnsiChar(Result), Len, nil, nil);
end;

function WideStringToUtf8Bytes(const W: WideString): AnsiString;
var
  Len: Integer;
begin
  Result := '';
  if W = '' then Exit;
  Len := WideCharToMultiByte(CP_UTF8, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
  if Len <= 0 then Exit;
  SetLength(Result, Len);
  WideCharToMultiByte(CP_UTF8, 0, PWideChar(W), Length(W), PAnsiChar(Result), Len, nil, nil);
end;

function AcpBytesToWideString(const Raw: AnsiString): WideString;
var
  Len: Integer;
begin
  Result := '';
  if Raw = '' then Exit;
  Len := MultiByteToWideChar(CP_ACP, 0, PAnsiChar(Raw), Length(Raw), nil, 0);
  if Len <= 0 then
  begin
    Result := WideString(string(Raw));
    Exit;
  end;
  SetLength(Result, Len);
  MultiByteToWideChar(CP_ACP, 0, PAnsiChar(Raw), Length(Raw), PWideChar(Result), Len);
end;

{ Lines are split on the byte 0A, so in UTF-16 LE every line after the first starts with
  the 00 left over from the previous line break (odd length): skip it to stay aligned. }
function Utf16LEToWideString(const Raw: AnsiString): WideString;
var
  n, i, Ofs: Integer;
begin
  Result := '';
  if Raw = '' then Exit;
  Ofs := 0;
  if Odd(Length(Raw)) and (Raw[1] = #0) then
    Ofs := 1;
  n := (Length(Raw) - Ofs) div 2;
  if n <= 0 then Exit;
  SetLength(Result, n);
  for i := 1 to n do
    Result[i] := WideChar(Word(Ord(Raw[Ofs + 2 * i - 1])) or (Word(Ord(Raw[Ofs + 2 * i])) shl 8));
end;

{ BE: the line break is 00 0A, so the stray 00 ends the previous line (dropped by div 2). }
function Utf16BEToWideString(const Raw: AnsiString): WideString;
var
  n, i: Integer;
begin
  Result := '';
  if Raw = '' then Exit;
  n := Length(Raw) div 2;
  if n <= 0 then Exit;
  SetLength(Result, n);
  for i := 1 to n do
    Result[i] := WideChar((Word(Ord(Raw[2 * i - 1])) shl 8) or Word(Ord(Raw[2 * i])));
end;

function Utf32CodeToWide(const Cp: LongWord; var Dest: WideString): Integer;
begin
  Result := 0;
  if Cp <= $FFFF then
  begin
    if (Cp >= $D800) and (Cp <= $DFFF) then Exit;
    Dest := Dest + WideChar(Cp);
    Result := 1;
  end
  else if Cp <= $10FFFF then
  begin
    Dest := Dest + WideChar($D800 + ((Cp - $10000) shr 10)) +
      WideChar($DC00 + ((Cp - $10000) and $3FF));
    Result := 2;
  end;
end;

function Utf32LEToWideString(const Raw: AnsiString): WideString;
var
  n, i: Integer;
  Cp: LongWord;
begin
  Result := '';
  n := Length(Raw) div 4;
  if n <= 0 then Exit;
  for i := 0 to n - 1 do
  begin
    Cp := LongWord(Ord(Raw[4 * i + 1])) or
      (LongWord(Ord(Raw[4 * i + 2])) shl 8) or
      (LongWord(Ord(Raw[4 * i + 3])) shl 16) or
      (LongWord(Ord(Raw[4 * i + 4])) shl 24);
    Utf32CodeToWide(Cp, Result);
  end;
end;

function Utf32BEToWideString(const Raw: AnsiString): WideString;
var
  n, i: Integer;
  Cp: LongWord;
begin
  Result := '';
  n := Length(Raw) div 4;
  if n <= 0 then Exit;
  for i := 0 to n - 1 do
  begin
    Cp := (LongWord(Ord(Raw[4 * i + 1])) shl 24) or
      (LongWord(Ord(Raw[4 * i + 2])) shl 16) or
      (LongWord(Ord(Raw[4 * i + 3])) shl 8) or
      LongWord(Ord(Raw[4 * i + 4]));
    Utf32CodeToWide(Cp, Result);
  end;
end;

function WideToDisplayString(const W: WideString): string;
begin
  {$IFDEF UNICODE}
  Result := string(W);
  {$ELSE}
  Result := string(WideStringToAnsiACP(W));
  {$ENDIF}
end;

function FileBytesToWideString(const Raw: AnsiString; const Enc: string): WideString;
var
  U: string;
  CP: UINT;
begin
  Result := '';
  if Raw = '' then Exit;
  U := EncUpper(Enc);
  if IsUtf32BEEncoding(U) then
  begin
    Result := Utf32BEToWideString(Raw);
    Exit;
  end;
  if IsUtf32LEEncoding(U) then
  begin
    Result := Utf32LEToWideString(Raw);
    Exit;
  end;
  if IsUtf16BEEncoding(U) then
  begin
    Result := Utf16BEToWideString(Raw);
    Exit;
  end;
  if (PosBMH('UTF-16', U) > 0) or (PosBMH('UTF16', U) > 0) then
  begin
    Result := Utf16LEToWideString(Raw);
    Exit;
  end;
  if IsUtf8Encoding(U) then
  begin
    Result := Utf8AnsiToWideString(Raw);
    Exit;
  end;
  if TryGetCodePageFromEncoding(U, CP) then
  begin
    Result := CodePageBytesToWideString(Raw, CP);
    Exit;
  end;
  Result := AcpBytesToWideString(Raw);
end;

function Utf16LineBytes(const Raw: AnsiString; const Enc: string; out AHadCR: Boolean): AnsiString;
begin
  Result := Raw;
  AHadCR := False;
  if IsUtf16BEEncoding(Enc) then
  begin
    if (Length(Result) >= 2) and (Result[1] = #$FE) and (Result[2] = #$FF) then
      Delete(Result, 1, 2);
    if Odd(Length(Result)) and (Result[Length(Result)] = #0) then
      SetLength(Result, Length(Result) - 1);
    if (Length(Result) >= 2) and (Result[Length(Result) - 1] = #0) and (Result[Length(Result)] = #13) then
    begin
      SetLength(Result, Length(Result) - 2);
      AHadCR := True;
    end;
  end
  else if IsUtf16LEEncoding(Enc) then
  begin
    if (Length(Result) >= 2) and (Result[1] = #$FF) and (Result[2] = #$FE) then
      Delete(Result, 1, 2);
    if Odd(Length(Result)) and (Result[1] = #0) then
      Delete(Result, 1, 1);
    if (Length(Result) >= 2) and (Result[Length(Result) - 1] = #13) and (Result[Length(Result)] = #0) then
    begin
      SetLength(Result, Length(Result) - 2);
      AHadCR := True;
    end;
  end;
end;

function Utf16LineBreakBytes(const Enc: string; ACR: Boolean): AnsiString;
begin
  if IsUtf16BEEncoding(Enc) then
  begin
    if ACR then
      Result := #0#13#0#10
    else
      Result := #0#10;
  end
  else if ACR then
    Result := #13#0#10#0
  else
    Result := #10#0;
end;

function FileBytesToUnicodeText(const Raw: AnsiString; const Enc: string): string;
begin
  Result := WideToDisplayString(FileBytesToWideString(Raw, Enc));
end;

function DisplayTextFromFileBytes(const Raw: AnsiString; const DisplayEncoding: string): string;
var
  W: WideString;
  U: string;
  CP: UINT;
begin
  if Raw = '' then
  begin
    Result := '';
    Exit;
  end;
  U := EncUpper(DisplayEncoding);
  if IsUnicodeFileEncoding(U) then
  begin
    W := FileBytesToWideString(Raw, U);
    if W <> '' then
      Result := WideToDisplayString(W)
    else
      Result := string(Raw);
    Exit;
  end;
  if TryGetCodePageFromEncoding(U, CP) and (CP <> CP_ACP) then
  begin
    W := CodePageBytesToWideString(Raw, CP);
    Result := WideToDisplayString(W);
    Exit;
  end;
  { ANSI / ACP: octetos via code page do sistema (D10.4: string(Raw) ja e Unicode). }
  Result := string(Raw);
end;

function WideStringToUtf16LEBytes(const W: WideString): AnsiString;
var
  I, N: Integer;
  C: Word;
begin
  Result := '';
  N := Length(W);
  if N <= 0 then Exit;
  SetLength(Result, N * 2);
  for I := 1 to N do
  begin
    C := Word(W[I]);
    Result[2 * I - 1] := AnsiChar(Byte(C and $FF));
    Result[2 * I] := AnsiChar(Byte(C shr 8));
  end;
end;

function WideStringToUtf16BEBytes(const W: WideString): AnsiString;
var
  I, N: Integer;
  C: Word;
begin
  Result := '';
  N := Length(W);
  if N <= 0 then Exit;
  SetLength(Result, N * 2);
  for I := 1 to N do
  begin
    C := Word(W[I]);
    Result[2 * I - 1] := AnsiChar(Byte(C shr 8));
    Result[2 * I] := AnsiChar(Byte(C and $FF));
  end;
end;

procedure AppendUtf32LE(var Dest: AnsiString; const Cp: LongWord);
var
  N: Integer;
begin
  N := Length(Dest);
  SetLength(Dest, N + 4);
  Dest[N + 1] := AnsiChar(Byte(Cp and $FF));
  Dest[N + 2] := AnsiChar(Byte((Cp shr 8) and $FF));
  Dest[N + 3] := AnsiChar(Byte((Cp shr 16) and $FF));
  Dest[N + 4] := AnsiChar(Byte((Cp shr 24) and $FF));
end;

procedure AppendUtf32BE(var Dest: AnsiString; const Cp: LongWord);
var
  N: Integer;
begin
  N := Length(Dest);
  SetLength(Dest, N + 4);
  Dest[N + 1] := AnsiChar(Byte((Cp shr 24) and $FF));
  Dest[N + 2] := AnsiChar(Byte((Cp shr 16) and $FF));
  Dest[N + 3] := AnsiChar(Byte((Cp shr 8) and $FF));
  Dest[N + 4] := AnsiChar(Byte(Cp and $FF));
end;

function WideToUtf32Codes(const W: WideString; Be: Boolean): AnsiString;
var
  I, N: Integer;
  C, C2: Word;
  Cp: LongWord;
begin
  Result := '';
  N := Length(W);
  I := 1;
  while I <= N do
  begin
    C := Word(W[I]);
    if (C >= $D800) and (C <= $DBFF) and (I < N) then
    begin
      C2 := Word(W[I + 1]);
      if (C2 >= $DC00) and (C2 <= $DFFF) then
      begin
        Cp := $10000 + (LongWord(C - $D800) shl 10) + LongWord(C2 - $DC00);
        Inc(I, 2);
        if Be then AppendUtf32BE(Result, Cp) else AppendUtf32LE(Result, Cp);
        Continue;
      end;
    end;
    if Be then AppendUtf32BE(Result, C) else AppendUtf32LE(Result, C);
    Inc(I);
  end;
end;

function WideStringToFileBytes(const W: WideString; const Enc: string): AnsiString;
var
  U: string;
  CP: UINT;
begin
  Result := '';
  if W = '' then Exit;
  U := EncUpper(Enc);
  if IsUtf8Encoding(U) then
  begin
    Result := WideStringToUtf8Bytes(W);
    Exit;
  end;
  if IsUtf16BEEncoding(U) then
  begin
    Result := WideStringToUtf16BEBytes(W);
    Exit;
  end;
  if (PosBMH('UTF-16', U) > 0) or (PosBMH('UTF16', U) > 0) then
  begin
    Result := WideStringToUtf16LEBytes(W);
    Exit;
  end;
  if IsUtf32BEEncoding(U) then
  begin
    Result := WideToUtf32Codes(W, True);
    Exit;
  end;
  if IsUtf32LEEncoding(U) then
  begin
    Result := WideToUtf32Codes(W, False);
    Exit;
  end;
  if TryGetCodePageFromEncoding(U, CP) then
  begin
    Result := WideStringToCodePageBytes(W, CP);
    Exit;
  end;
  Result := WideStringToAnsiACP(W);
end;

function UnicodeTextToFileBytes(const S: string; const Enc: string): AnsiString;
begin
  Result := WideStringToFileBytes(WideString(S), Enc);
end;

function DisplayStringToFileBytes(const S: string; const DisplayEncoding: string): AnsiString;
begin
  Result := UnicodeTextToFileBytes(S, DisplayEncoding);
end;

procedure ClipboardSetUnicodeText(const W: WideString);
var
  hMem: HGLOBAL;
  P: Pointer;
  N: Integer;
  HWin: HWND;
  Ok: Boolean;
begin
  N := (Length(W) + 1) * SizeOf(WideChar);
  if N < Integer(SizeOf(WideChar)) then Exit;
  hMem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, N);
  if hMem = 0 then Exit;
  P := GlobalLock(hMem);
  if P = nil then
  begin
    GlobalFree(hMem);
    Exit;
  end;
  try
    FillChar(P^, N, 0);
    if Length(W) > 0 then
      Move(PWideChar(W)^, P^, Length(W) * SizeOf(WideChar));
  finally
    GlobalUnlock(hMem);
  end;

  HWin := 0;
  if Assigned(Application) and (Application.Handle <> 0) then
    HWin := Application.Handle;

  Ok := OpenClipboard(HWin);
  if not Ok then
    Ok := OpenClipboard(0);

  if not Ok then
  begin
    GlobalFree(hMem);
    try
      Clipboard.AsText := string(W);
    except
    end;
    Exit;
  end;
  try
    EmptyClipboard;
    if SetClipboardData(CF_UNICODETEXT, hMem) <> 0 then
      hMem := 0
    else
    begin
      GlobalFree(hMem);
      try
        Clipboard.AsText := string(W);
      except
      end;
    end;
  finally
    CloseClipboard;
  end;
end;

function IsProbablyUtf8(const S: AnsiString): Boolean;
var
  i, L, b: Integer;
  Need: Integer;
begin
  Result := False;
  L := Length(S);
  i := 1;
  while i <= L do
  begin
    b := Ord(S[i]);
    if b < $80 then
    begin
      Inc(i);
      Continue;
    end;
    if (b and $E0) = $C0 then
    begin
      Need := 1;
      if (b and $FE) = $C0 then Exit;
    end
    else if (b and $F0) = $E0 then
      Need := 2
    else if (b and $F8) = $F0 then
      Need := 3
    else
      Exit;
    if i + Need > L then Exit;
    while Need > 0 do
    begin
      Inc(i);
      if (Ord(S[i]) and $C0) <> $80 then Exit;
      Dec(Need);
    end;
    Inc(i);
    Result := True;
  end;
end;

function Utf8HeuristicToDisplayString(const S: string): string;
var
  A: AnsiString;
  W: WideString;
  I: Integer;
begin
  if S = '' then
  begin
    Result := '';
    Exit;
  end;
  for I := 1 to Length(S) do
    if Ord(S[I]) > 255 then
    begin
      Result := S;
      Exit;
    end;
  A := AnsiString(S);
  if IsProbablyUtf8(A) then
  begin
    W := Utf8AnsiToWideString(A);
    if W <> '' then
      Result := WideToDisplayString(W)
    else
      Result := S;
  end
  else
    Result := S;
end;

function RawBytesToDisplayString(const Raw: AnsiString): string;
var
  W: WideString;
begin
  if Raw = '' then
  begin
    Result := '';
    Exit;
  end;
  if IsProbablyUtf8(Raw) then
  begin
    W := Utf8AnsiToWideString(Raw);
    if W <> '' then
    begin
      Result := WideToDisplayString(W);
      Exit;
    end;
  end;
  Result := string(Raw);
end;

function UnicodeUpperCaseW(const S: string): string;
var
  W: WideString;
begin
  Result := S;
  if S = '' then Exit;
  W := WideString(S);
  if Length(W) > 0 then
    CharUpperBuffW(PWideChar(W), Length(W));
  Result := string(W);
end;

function UnicodeContainsText(const Haystack, Needle: string; ACaseSensitive: Boolean): Boolean;
begin
  Result := False;
  if Needle = '' then Exit;
  if ACaseSensitive then
    Result := Pos(Needle, Haystack) > 0
  else
    Result := Pos(UnicodeUpperCaseW(Needle), UnicodeUpperCaseW(Haystack)) > 0;
end;

function UnicodeStartsWithText(const Haystack, Needle: string; ACaseSensitive: Boolean): Boolean;
var
  N: Integer;
begin
  Result := False;
  N := Length(Needle);
  if N = 0 then Exit;
  if Length(Haystack) < N then Exit;
  if ACaseSensitive then
    Result := CompareStr(Copy(Haystack, 1, N), Needle) = 0
  else
    Result := CompareStr(UnicodeUpperCaseW(Copy(Haystack, 1, N)), UnicodeUpperCaseW(Needle)) = 0;
end;

function UnicodeLineMatches(const LineRaw: AnsiString; const Needle, Enc: string;
  ACaseSensitive, APrefix: Boolean): Boolean;
var
  LineTxt: string;
begin
  Result := False;
  if Needle = '' then Exit;
  LineTxt := FileBytesToUnicodeText(LineRaw, Enc);
  if APrefix then
    Result := UnicodeStartsWithText(LineTxt, Needle, ACaseSensitive)
  else
    Result := UnicodeContainsText(LineTxt, Needle, ACaseSensitive);
end;

function DetectTextEncodingFromBytes(const Sample: AnsiString): string;
var
  N: Integer;
  B0, B1, B2, B3: Byte;
begin
  Result := 'ANSI';
  N := Length(Sample);
  if N < 2 then Exit;
  B0 := Ord(Sample[1]);
  B1 := Ord(Sample[2]);
  if N >= 3 then
    B2 := Ord(Sample[3])
  else
    B2 := 0;
  if N >= 4 then
    B3 := Ord(Sample[4])
  else
    B3 := 0;
  if (N >= 3) and (B0 = $EF) and (B1 = $BB) and (B2 = $BF) then
  begin
    Result := 'UTF-8 (BOM)';
    Exit;
  end;
  if (B0 = $FF) and (B1 = $FE) then
  begin
    if (N >= 4) and (B2 = $00) and (B3 = $00) then
      Result := 'UTF-32 LE'
    else
      Result := 'UTF-16 LE';
    Exit;
  end;
  if (B0 = $FE) and (B1 = $FF) then
  begin
    Result := 'UTF-16 BE';
    Exit;
  end;
  if (N >= 4) and (B0 = $00) and (B1 = $00) and (B2 = $FE) and (B3 = $FF) then
  begin
    Result := 'UTF-32 BE';
    Exit;
  end;
  if IsProbablyUtf8(Sample) then
    Result := 'UTF-8 (no BOM)'
  else
    Result := 'ANSI';
end;

function DetectTextFileEncoding(const AFileName: string): string;
var
  F: TFileStream;
  Sample: AnsiString;
  SampleLen: Integer;
  n: Integer;
  Sz: Int64;
begin
  Result := 'ANSI';
  if (AFileName = '') or (not FileExists(AFileName)) then Exit;
  try
    F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      Sz := F.Size;
      if Sz <= 0 then Exit;
      if Sz > 16384 then
        SampleLen := 16384
      else
        SampleLen := Integer(Sz);
      SetLength(Sample, SampleLen);
      n := F.Read(Pointer(Sample)^, SampleLen);
      SetLength(Sample, n);
      Result := DetectTextEncodingFromBytes(Sample);
    finally
      F.Free;
    end;
  except
    Result := 'ANSI';
  end;
end;

end.
