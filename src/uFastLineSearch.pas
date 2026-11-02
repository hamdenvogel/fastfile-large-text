unit uFastLineSearch;

{
  Varredura sequencial de arquivos grandes para Filtro / Grep / Find.
  - Busca no bloco inteiro (nao linha a linha): filtro SWAR por 2 bytes raros
    da agulha, 8 posicoes por iteracao, com verificacao exata dos candidatos.
  - Agulha com acentos e sem diferenciar maiusculas: o trecho ASCII mais longo
    da agulha serve de ancora; so as linhas candidatas sao decodificadas.
  - Contagem de quebras de linha 8 bytes por vez (SWAR).
  - Leitura com FILE_FLAG_SEQUENTIAL_SCAN.
  - Fallback Unicode so nas linhas com bytes cujo maiusculo vira uma letra
    ASCII da agulha (ex.: U+0131 -> I em alguns sistemas).
  Mesma semantica de UnicodeLineMatches (CharUpperBuffW, sem remover acentos).
}

{$Q-}
{$R-}
{$POINTERMATH ON}

interface

uses
  Windows, SysUtils, Classes, uTextEncoding;

type
  TFastLineMatcher = class
  private
    FNeedleText: string;
    FEncoding: string;
    FCaseSensitive: Boolean;
    FPrefix: Boolean;
    FByteMode: Boolean;
    FWideEncoding: Boolean;
    FAnchor: array of Byte;
    FAnchorLen: Integer;
    FFold: array[0..255] of Byte;
    FOfs1, FOfs2: Integer;
    FPat1, FPat2, FMask1, FMask2: UInt64;
    FRisk: array[0..255] of Boolean;
    FHasRisk: Boolean;
    procedure BuildRiskTable;
    procedure SetupAnchor(const ABytes: AnsiString);
    function VerifyAt(P: PByte): Boolean; inline;
  public
    constructor Create(const ANeedleText, AEncoding: string;
      ACaseSensitive, APrefix: Boolean; ATermByte: Byte);
    { Indice da ancora em Buf[AStart..AStop) ou -1. }
    function FindInBuffer(Buf: PByte; AStart, AStop: Integer): Integer;
    { Indice do primeiro byte de risco em P[0..ALen) ou -1. }
    function FindRiskByte(P: PByte; ALen: Integer): Integer;
    function UnicodeLineMatch(P: PByte; ALen: Integer): Boolean;
    { Semantica completa (igual a UnicodeLineMatches). }
    function LineMatches(P: PByte; ALen: Integer): Boolean;
    { Forca verificacao Unicode extra nesses bytes (nao altera o resultado; usado em testes). }
    procedure AddRiskBytes(AFrom, ATo: Byte);
    property ByteMode: Boolean read FByteMode;
    property AnchorLen: Integer read FAnchorLen;
    property HasRisk: Boolean read FHasRisk;
    property Prefix: Boolean read FPrefix;
    property WideEncoding: Boolean read FWideEncoding;
  end;

  { False = parar a varredura (limite de hits ou cancelamento). }
  TFastLineHitFunc = reference to function(const ALineNum, ALineStartByte: Int64): Boolean;
  TFastScanProgressFunc = reference to function(const ABytesDone: Int64): Boolean;

  TSequentialReadStream = class(THandleStream)
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
  end;

function FastFindByte(P: PByte; ALen: Integer; AByte: Byte): Integer;
function FastCountByte(P: PByte; ALen: Integer; AByte: Byte): Int64;
function FastFindLastByte(P: PByte; ALen: Integer; AByte: Byte): Integer;
function FastFileSize(const AFileName: string): Int64;

{ Varre o arquivo a partir de AStartByte (inicio de linha) / AStartLine.
  Retorna True se chegou ao fim do arquivo; False se OnHit/OnProgress pediu parada. }
function FastScanFileLines(const AFileName: string; AMatcher: TFastLineMatcher;
  ATermByte: Byte; AStartByte, AStartLine: Int64; ABufSize: Integer;
  const AOnHit: TFastLineHitFunc; const AOnProgress: TFastScanProgressFunc): Boolean;

implementation

const
  LANES_01 = UInt64($0101010101010101);
  LANES_20 = UInt64($2020202020202020);
  LANES_7F = UInt64($7F7F7F7F7F7F7F7F);
  LANES_80 = UInt64($8080808080808080);
  MAX_SCAN_BUF = 1024 * 1024 * 1024;
  { Bytes mais frequentes em texto/CSV (do mais para o menos comum). }
  COMMON_BYTES: AnsiString = ' eaos0r1in2dmu3t5c4l9p876;,.-/:"vgqbfh_jxzwky';

var
  ByteFreq: array[0..255] of Integer;

{ 0x80 em cada byte de X que for zero (exato, sem falso positivo). }
function ZeroLanes(const X: UInt64): UInt64; inline;
begin
  Result := not (((X and LANES_7F) + LANES_7F) or X) and LANES_80;
end;

function FastFindByte(P: PByte; ALen: Integer; AByte: Byte): Integer;
var
  I: Integer;
  Pat, T: UInt64;
begin
  Result := -1;
  if (P = nil) or (ALen <= 0) then Exit;
  Pat := UInt64(AByte) * LANES_01;
  I := 0;
  while I + 8 <= ALen do
  begin
    T := ZeroLanes(PUInt64(P + I)^ xor Pat);
    if T <> 0 then
    begin
      while (T and $80) = 0 do
      begin
        T := T shr 8;
        Inc(I);
      end;
      Exit(I);
    end;
    Inc(I, 8);
  end;
  while I < ALen do
  begin
    if P[I] = AByte then Exit(I);
    Inc(I);
  end;
end;

function FastCountByte(P: PByte; ALen: Integer; AByte: Byte): Int64;
var
  I: Integer;
  Pat, T: UInt64;
begin
  Result := 0;
  if (P = nil) or (ALen <= 0) then Exit;
  Pat := UInt64(AByte) * LANES_01;
  I := 0;
  while I + 8 <= ALen do
  begin
    T := ZeroLanes(PUInt64(P + I)^ xor Pat);
    if T <> 0 then
      Inc(Result, ((T shr 7) * LANES_01) shr 56);
    Inc(I, 8);
  end;
  while I < ALen do
  begin
    if P[I] = AByte then Inc(Result);
    Inc(I);
  end;
end;

function FastFindLastByte(P: PByte; ALen: Integer; AByte: Byte): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (P = nil) or (ALen <= 0) then Exit;
  for I := ALen - 1 downto 0 do
    if P[I] = AByte then Exit(I);
end;

function FastFileSize(const AFileName: string): Int64;
var
  Data: TWin32FileAttributeData;
begin
  Result := 0;
  if GetFileAttributesEx(PChar(AFileName), GetFileExInfoStandard, @Data) then
    Result := (Int64(Data.nFileSizeHigh) shl 32) or Int64(Data.nFileSizeLow);
end;

{ TSequentialReadStream }

constructor TSequentialReadStream.Create(const AFileName: string);
var
  H: THandle;
begin
  H := CreateFile(PChar(AFileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if H = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  inherited Create(H);
end;

destructor TSequentialReadStream.Destroy;
begin
  if Handle <> INVALID_HANDLE_VALUE then
    CloseHandle(Handle);
  inherited;
end;

{ TFastLineMatcher }

constructor TFastLineMatcher.Create(const ANeedleText, AEncoding: string;
  ACaseSensitive, APrefix: Boolean; ATermByte: Byte);
var
  I, RunStart, BestStart, BestLen: Integer;
  Raw, AnchorRaw: AnsiString;
  AnchorText: string;
  CodePage: UINT;
  SingleByte: Boolean;
begin
  inherited Create;
  FNeedleText := ANeedleText;
  FEncoding := AEncoding;
  FCaseSensitive := ACaseSensitive;
  FPrefix := APrefix;
  FWideEncoding := IsUtf16LEEncoding(AEncoding) or IsUtf16BEEncoding(AEncoding) or
    IsUtf32LEEncoding(AEncoding) or IsUtf32BEEncoding(AEncoding);
  for I := 0 to 255 do
    FFold[I] := I;
  if not ACaseSensitive then
    for I := Ord('a') to Ord('z') do
      FFold[I] := I - 32;

  FAnchorLen := 0;
  if (ANeedleText = '') or FWideEncoding then Exit;

  SingleByte := IsUtf8Encoding(AEncoding);
  if not SingleByte then
  begin
    if not TryGetCodePageFromEncoding(AEncoding, CodePage) then
      CodePage := GetACP;
    SingleByte := True;
    for I := 0 to 255 do
      if IsDBCSLeadByteEx(CodePage, Byte(I)) then
      begin
        SingleByte := False;
        Break;
      end;
  end;
  if not SingleByte then Exit;

  Raw := UnicodeTextToFileBytes(ANeedleText, AEncoding);
  { Exige ida e volta: caractere sem representacao na codepage (vira '?')
    nao pode virar busca por bytes. }
  FByteMode := (Raw <> '') and (ACaseSensitive or IsAsciiOnlyText(ANeedleText)) and
    (Pos(AnsiChar(ATermByte), Raw) = 0) and
    (FileBytesToUnicodeText(Raw, AEncoding) = ANeedleText);

  if FByteMode then
    SetupAnchor(Raw)
  else
  begin
    { Trecho ASCII mais longo da agulha: toda linha que casa contem esses bytes
      (salvo linhas com bytes de risco, tratadas a parte). }
    BestStart := 0;
    BestLen := 0;
    RunStart := 0;
    for I := 1 to Length(ANeedleText) + 1 do
      if (I > Length(ANeedleText)) or (Ord(ANeedleText[I]) >= $80) or
         (Ord(ANeedleText[I]) = ATermByte) then
      begin
        if (RunStart > 0) and (I - RunStart > BestLen) then
        begin
          BestStart := RunStart;
          BestLen := I - RunStart;
        end;
        RunStart := 0;
      end
      else if RunStart = 0 then
        RunStart := I;
    if BestLen > 0 then
    begin
      AnchorText := Copy(ANeedleText, BestStart, BestLen);
      AnchorRaw := UnicodeTextToFileBytes(AnchorText, AEncoding);
      if AnchorRaw = AnsiString(AnchorText) then
        SetupAnchor(AnchorRaw);
    end;
  end;

  if (not ACaseSensitive) and (FAnchorLen > 0) then
    BuildRiskTable;
end;

procedure TFastLineMatcher.SetupAnchor(const ABytes: AnsiString);
var
  I, Best1, Best2: Integer;
  B: Byte;

  procedure Lane(AOfs: Integer; out APat, AMask: UInt64);
  begin
    B := FAnchor[AOfs];
    if (not FCaseSensitive) and (B >= Ord('A')) and (B <= Ord('Z')) then
    begin
      APat := UInt64(B or $20) * LANES_01;
      AMask := LANES_20;
    end
    else
    begin
      APat := UInt64(B) * LANES_01;
      AMask := 0;
    end;
  end;

begin
  FAnchorLen := Length(ABytes);
  SetLength(FAnchor, FAnchorLen);
  for I := 0 to FAnchorLen - 1 do
    FAnchor[I] := FFold[Byte(ABytes[I + 1])];
  { Dois deslocamentos com os bytes mais raros (menos candidatos falsos). }
  Best1 := FAnchorLen - 1;
  for I := FAnchorLen - 1 downto 0 do
    if ByteFreq[FAnchor[I] or $20] < ByteFreq[FAnchor[Best1] or $20] then
      Best1 := I;
  Best2 := -1;
  for I := FAnchorLen - 1 downto 0 do
    if (I <> Best1) and ((Best2 < 0) or
       (ByteFreq[FAnchor[I] or $20] < ByteFreq[FAnchor[Best2] or $20])) then
      Best2 := I;
  if Best2 < 0 then Best2 := Best1;
  FOfs1 := Best1;
  FOfs2 := Best2;
  Lane(FOfs1, FPat1, FMask1);
  Lane(FOfs2, FPat2, FMask2);
end;

{ Ignorar maiusculas usa CharUpperBuffW (sem remover acentos). Um caractere nao
  ASCII so pode casar com letra ASCII da agulha se o maiusculo dele for ASCII. }
procedure TFastLineMatcher.BuildRiskTable;
var
  NeedleUp, Upper: string;
  W: WideString;
  I, Cp: Integer;
  CodePage: UINT;
  SrcByte: AnsiChar;
  WC: WideChar;
begin
  FillChar(FRisk, SizeOf(FRisk), 0);
  FHasRisk := False;
  NeedleUp := UnicodeUpperCaseW(FNeedleText);
  if IsUtf8Encoding(FEncoding) then
  begin
    SetLength(W, $FFFF - $80 + 1);
    for Cp := $80 to $FFFF do
      W[Cp - $80 + 1] := WideChar(Cp);
    CharUpperBuffW(PWideChar(W), Length(W));
    for Cp := $80 to $FFFF do
    begin
      if (Cp >= $D800) and (Cp <= $DFFF) then Continue;
      WC := W[Cp - $80 + 1];
      if (Ord(WC) >= $80) or (Pos(Char(WC), NeedleUp) = 0) then Continue;
      if Cp < $800 then
        FRisk[$C0 or (Cp shr 6)] := True
      else
        FRisk[$E0 or (Cp shr 12)] := True;
      FHasRisk := True;
    end;
  end
  else
  begin
    if not TryGetCodePageFromEncoding(FEncoding, CodePage) then
      CodePage := GetACP;
    for I := $80 to $FF do
    begin
      SrcByte := AnsiChar(I);
      if MultiByteToWideChar(CodePage, 0, @SrcByte, 1, @WC, 1) <> 1 then Continue;
      Upper := UnicodeUpperCaseW(string(WC));
      if (Length(Upper) <> 1) or (Ord(Upper[1]) >= $80) then Continue;
      if Pos(Upper, NeedleUp) = 0 then Continue;
      FRisk[I] := True;
      FHasRisk := True;
    end;
  end;
end;

function TFastLineMatcher.VerifyAt(P: PByte): Boolean;
var
  J: Integer;
begin
  for J := 0 to FAnchorLen - 1 do
    if FFold[P[J]] <> FAnchor[J] then
      Exit(False);
  Result := True;
end;

function TFastLineMatcher.FindInBuffer(Buf: PByte; AStart, AStop: Integer): Integer;
var
  I, LastStart, K: Integer;
  T: UInt64;
begin
  Result := -1;
  if (FAnchorLen = 0) or (Buf = nil) then Exit;
  if AStart < 0 then AStart := 0;
  LastStart := AStop - FAnchorLen;
  I := AStart;
  { 8 posicoes iniciais por vez; leituras ficam dentro de Buf[AStart..AStop). }
  while I + 7 <= LastStart do
  begin
    T := ZeroLanes((PUInt64(Buf + I + FOfs1)^ or FMask1) xor FPat1) and
         ZeroLanes((PUInt64(Buf + I + FOfs2)^ or FMask2) xor FPat2);
    K := 0;
    while T <> 0 do
    begin
      while (T and $80) = 0 do
      begin
        T := T shr 8;
        Inc(K);
      end;
      if VerifyAt(Buf + I + K) then Exit(I + K);
      T := T shr 8;
      Inc(K);
    end;
    Inc(I, 8);
  end;
  while I <= LastStart do
  begin
    if VerifyAt(Buf + I) then Exit(I);
    Inc(I);
  end;
end;

function TFastLineMatcher.FindRiskByte(P: PByte; ALen: Integer): Integer;
var
  I, J: Integer;
begin
  Result := -1;
  if (not FHasRisk) or (P = nil) or (ALen <= 0) then Exit;
  I := 0;
  while I + 8 <= ALen do
  begin
    { Bytes de risco sao sempre >= $80: pular blocos ASCII de uma vez. }
    if (PUInt64(P + I)^ and LANES_80) <> 0 then
      for J := I to I + 7 do
        if FRisk[P[J]] then Exit(J);
    Inc(I, 8);
  end;
  while I < ALen do
  begin
    if FRisk[P[I]] then Exit(I);
    Inc(I);
  end;
end;

function TFastLineMatcher.UnicodeLineMatch(P: PByte; ALen: Integer): Boolean;
var
  S: AnsiString;
begin
  if ALen > 0 then
    SetString(S, PAnsiChar(P), ALen)
  else
    S := '';
  Result := UnicodeLineMatches(S, FNeedleText, FEncoding, FCaseSensitive, FPrefix);
end;

function TFastLineMatcher.LineMatches(P: PByte; ALen: Integer): Boolean;
begin
  Result := False;
  if FNeedleText = '' then Exit;
  if not FByteMode then
  begin
    { Sem a ancora a linha nao pode casar (exceto com bytes de risco). }
    if (FAnchorLen > 0) and (FindInBuffer(P, 0, ALen) < 0) and
       ((not FHasRisk) or (FindRiskByte(P, ALen) < 0)) then
      Exit;
    Exit(UnicodeLineMatch(P, ALen));
  end;
  if FPrefix then
    Result := (ALen >= FAnchorLen) and VerifyAt(P)
  else
    Result := FindInBuffer(P, 0, ALen) >= 0;
  if (not Result) and FHasRisk and (FindRiskByte(P, ALen) >= 0) then
    Result := UnicodeLineMatch(P, ALen);
end;

procedure TFastLineMatcher.AddRiskBytes(AFrom, ATo: Byte);
var
  I: Integer;
begin
  if (FAnchorLen = 0) or (AFrom < $80) then Exit;
  for I := AFrom to ATo do
    FRisk[I] := True;
  FHasRisk := True;
end;

function FastScanFileLines(const AFileName: string; AMatcher: TFastLineMatcher;
  ATermByte: Byte; AStartByte, AStartLine: Int64; ABufSize: Integer;
  const AOnHit: TFastLineHitFunc; const AOnProgress: TFastScanProgressFunc): Boolean;
var
  Src: TSequentialReadStream;
  Buf: array of Byte;
  BufCap, Carry, ReadN, DataLen, ProcEnd, LastT: Integer;
  FileSize, FilePos, BasePos, LineNum: Int64;
  AtEof, Stop, SearchMode, AnchorExact: Boolean;

  function Hit(ALineStart: Integer): Boolean;
  begin
    Result := AOnHit(LineNum, BasePos + ALineStart);
    if not Result then Stop := True;
  end;

  { BOM UTF-8 da primeira linha nao conta para "comeca com". }
  function BomSkip(ALineStart, ALineEnd: Integer): Integer;
  begin
    Result := 0;
    if AMatcher.Prefix and (BasePos + ALineStart = 0) and (ALineEnd - ALineStart >= 3) and
       (Buf[ALineStart] = $EF) and (Buf[ALineStart + 1] = $BB) and (Buf[ALineStart + 2] = $BF) then
      Result := 3;
  end;

  function CheckLine(ALineStart, ALineEnd: Integer): Boolean;
  var
    S: Integer;
  begin
    S := BomSkip(ALineStart, ALineEnd);
    Result := AMatcher.LineMatches(@Buf[ALineStart + S], ALineEnd - ALineStart - S);
  end;

  { Linha que ja contem a ancora: so falta a verificacao Unicode completa. }
  function CheckAnchoredLine(ALineStart, ALineEnd: Integer): Boolean;
  var
    S: Integer;
  begin
    S := BomSkip(ALineStart, ALineEnd);
    Result := AMatcher.UnicodeLineMatch(@Buf[ALineStart + S], ALineEnd - ALineStart - S);
  end;

  { Linhas completas em Buf[A..B) sem ancora: conta quebras e testa so as linhas
    com bytes de risco. Retorna False se parou. }
  function AdvanceRisk(A, B: Integer): Boolean;
  var
    P, R, LS, E, S: Integer;
  begin
    Result := True;
    P := A;
    while P < B do
    begin
      R := AMatcher.FindRiskByte(@Buf[P], B - P);
      if R < 0 then
      begin
        Inc(LineNum, FastCountByte(@Buf[P], B - P, ATermByte));
        Exit;
      end;
      Inc(R, P);
      Inc(LineNum, FastCountByte(@Buf[P], R - P, ATermByte));
      LS := FastFindLastByte(@Buf[P], R - P, ATermByte);
      if LS < 0 then LS := P else LS := P + LS + 1;
      E := FastFindByte(@Buf[R], B - R, ATermByte);
      if E < 0 then Exit;
      E := R + E;
      S := BomSkip(LS, E);
      if AMatcher.UnicodeLineMatch(@Buf[LS + S], E - LS - S) then
        if not Hit(LS) then Exit(False);
      Inc(LineNum);
      P := E + 1;
    end;
  end;

  procedure ScanSearch;
  var
    P, M, E, LS: Integer;
  begin
    P := 0;
    while P < ProcEnd do
    begin
      M := AMatcher.FindInBuffer(@Buf[0], P, ProcEnd);
      if M < 0 then
      begin
        if AMatcher.HasRisk then
          AdvanceRisk(P, ProcEnd)
        else
          Inc(LineNum, FastCountByte(@Buf[P], ProcEnd - P, ATermByte));
        Exit;
      end;
      if AMatcher.HasRisk then
      begin
        if not AdvanceRisk(P, M) then Exit;
      end
      else
        Inc(LineNum, FastCountByte(@Buf[P], M - P, ATermByte));
      LS := FastFindLastByte(@Buf[0], M, ATermByte) + 1;
      if LS < P then LS := P;
      E := FastFindByte(@Buf[M], ProcEnd - M, ATermByte);
      if E < 0 then
        E := ProcEnd
      else
        E := M + E;
      if AnchorExact or CheckAnchoredLine(LS, E) then
        if not Hit(LS) then Exit;
      Inc(LineNum);
      P := E + 1;
    end;
  end;

  procedure ScanPerLine;
  var
    P, E: Integer;
  begin
    P := 0;
    while P < ProcEnd do
    begin
      E := FastFindByte(@Buf[P], ProcEnd - P, ATermByte);
      if E < 0 then E := ProcEnd - P;
      if CheckLine(P, P + E) then
        if not Hit(P) then Exit;
      Inc(LineNum);
      P := P + E + 1;
    end;
  end;

  procedure ProcessBlock;
  begin
    if SearchMode then
      ScanSearch
    else
      ScanPerLine;
  end;

begin
  Result := False;
  Stop := False;
  SearchMode := (AMatcher.AnchorLen > 0) and
    not (AMatcher.ByteMode and AMatcher.Prefix);
  AnchorExact := AMatcher.ByteMode and (not AMatcher.Prefix);
  if ABufSize < 64 * 1024 then
    ABufSize := 64 * 1024;
  Src := TSequentialReadStream.Create(AFileName);
  try
    FileSize := Src.Size;
    if AStartByte < 0 then AStartByte := 0;
    if AStartLine < 0 then AStartLine := 0;
    FilePos := AStartByte;
    LineNum := AStartLine;
    if FilePos > 0 then
      Src.Seek(FilePos, soBeginning);
    BufCap := ABufSize;
    { +8: terminador virtual no EOF e folga para leituras de 8 bytes. }
    SetLength(Buf, BufCap + 8);
    Carry := 0;
    while FilePos < FileSize do
    begin
      if Carry >= BufCap then
      begin
        if BufCap >= MAX_SCAN_BUF then
          raise EInOutError.Create('Line too long for the filter scan buffer.');
        BufCap := BufCap * 2;
        SetLength(Buf, BufCap + 8);
      end;
      ReadN := BufCap - Carry;
      if FilePos + ReadN > FileSize then
        ReadN := Integer(FileSize - FilePos);
      ReadN := Src.Read(Buf[Carry], ReadN);
      if ReadN <= 0 then Break;
      BasePos := FilePos - Carry;
      Inc(FilePos, ReadN);
      DataLen := Carry + ReadN;
      AtEof := FilePos >= FileSize;
      if AtEof then
      begin
        { Ultima linha sem quebra: terminador virtual. }
        if Buf[DataLen - 1] <> ATermByte then
        begin
          Buf[DataLen] := ATermByte;
          Inc(DataLen);
        end;
        ProcEnd := DataLen;
      end
      else
      begin
        LastT := FastFindLastByte(@Buf[0], DataLen, ATermByte);
        if LastT < 0 then
        begin
          Carry := DataLen;
          Continue;
        end;
        ProcEnd := LastT + 1;
      end;

      ProcessBlock;
      if Stop then Exit;
      if Assigned(AOnProgress) and (not AOnProgress(BasePos + ProcEnd)) then Exit;

      Carry := DataLen - ProcEnd;
      if Carry > 0 then
        Move(Buf[ProcEnd], Buf[0], Carry);
    end;
    { Restante sem quebra apos leitura curta inesperada. }
    if Carry > 0 then
    begin
      BasePos := FilePos - Carry;
      Buf[Carry] := ATermByte;
      DataLen := Carry + 1;
      ProcEnd := DataLen;
      ProcessBlock;
      if Stop then Exit;
    end;
    Result := True;
  finally
    Src.Free;
  end;
end;

procedure InitByteFreq;
var
  I, N: Integer;
begin
  N := Length(COMMON_BYTES);
  for I := 0 to 255 do
    ByteFreq[I] := 0;
  for I := 1 to N do
    ByteFreq[Byte(COMMON_BYTES[I])] := N - I + 1;
end;

initialization
  InitByteFreq;

end.
