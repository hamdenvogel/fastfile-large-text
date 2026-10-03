unit uHistChangedIndex;

{ Indice da lista "Linhas alteradas" do historico de sessao, para journals de qualquer tamanho.

  - Uma thread le o journal inteiro em streaming e agrega por (linha inicial, linha final):
    contagem por tipo, ultimo tipo e offsets do primeiro/ultimo evento. Nenhum texto fica
    em memoria (~35 bytes por linha alterada).
  - Acima de cHciDiskThreshold entradas o indice ordenado vai para um ficheiro temporario
    e a UI le so' a pagina visivel (cache de cHciCachePage registos).
  - Os eventos de uma linha sao lidos sob demanda (THciEventScanThread), apenas na janela
    [primeiro evento .. ultimo evento] dessa linha. }

interface

uses
  Windows, Messages, SysUtils, Classes, Math, Generics.Collections, Generics.Defaults;

const
  cHciDiskThreshold = 1000000;
  cHciCachePage = 4096;
  cHciMaxEventsOnDemand = 2000;
  { WParam das mensagens das threads. }
  cHciMsgProgress = 0;
  cHciMsgDone = 1;

type
  { Tags: 1 EDT, 2 INS, 3 DEL, 4 RPLALL, 5 UNDO/REDO (igual a HistParseJournalTag). }
  THciRec = packed record
    Ln0, Ln1: Integer;
    Cnt: array[1..5] of Word;
    LastTag: Byte;
    FirstOfs, LastOfs: Int64;
    { yyyymmddhhnnss do primeiro e do ultimo evento (0 se a linha nao tiver data). }
    FirstTs, LastTs: Int64;
  end;
  PHciRec = ^THciRec;
  THciRecArray = array of THciRec;

  THistChangedIndex = class
  private
    FRecs: THciRecArray;
    FCount: Integer;
    FDiskPath: string;
    FDisk: TFileStream;
    FCache: THciRecArray;
    FCacheFirst: Integer;
    FJournalPath: string;
    FJournalSize: Int64;
    FJournalTime: Int64;
    procedure LoadCache(AIndex: Integer);
    function GetOnDisk: Boolean;
  public
    destructor Destroy; override;
    function Get(AIndex: Integer): THciRec;
    { Primeiro indice com Ln0 >= ALine (Count se nenhum). }
    function LowerBound(ALine: Integer): Integer;
    property Count: Integer read FCount;
    property OnDisk: Boolean read GetOnDisk;
    property JournalPath: string read FJournalPath;
    property JournalSize: Int64 read FJournalSize;
    property JournalTime: Int64 read FJournalTime;
  end;

  THciLineFunc = reference to function(P: PAnsiChar; Len: Integer; Ofs: Int64): Boolean;

  THciScanThread = class(TThread)
  protected
    FPath: string;
    FWnd: HWND;
    FMsg: UINT;
    FLastPct: Integer;
    { AProc devolve False para parar. Linhas sem o LF final; CR final removido. }
    function ScanLines(AFrom, ATo: Int64; const AProc: THciLineFunc;
      AReportProgress: Boolean): Boolean;
    procedure PostDone;
  public
    constructor Create(const AJournal: string; AWnd: HWND; AMsg: UINT);
  end;

  THciBuildThread = class(THciScanThread)
  private
    FTempDir: string;
    FResult: THistChangedIndex;
  protected
    procedure Execute; override;
  public
    constructor Create(const AJournal, ATempDir: string; AWnd: HWND; AMsg: UINT);
    destructor Destroy; override;
    function TakeResult: THistChangedIndex;
  end;

  THciEventScanThread = class(THciScanThread)
  private
    FFrom, FLastOfs: Int64;
    FLine: Integer;
    { Buffer circular: guarda so' os ultimos cHciMaxEventsOnDemand eventos. }
    FRing: array of string;
    FRingPos, FRingCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AJournal: string; AFrom, ALastOfs: Int64; ALine: Integer;
      AWnd: HWND; AMsg: UINT);
    destructor Destroy; override;
    function TakeEvents: TStringList;
    property Line: Integer read FLine;
  end;

function HciJournalStamp(const APath: string; out ASize, ATime: Int64): Boolean;
function HciParseLine(P: PAnsiChar; Len: Integer; out ALn0, ALn1: Integer;
  out ATag: Byte): Boolean;
function HciTotalEvents(const R: THciRec): Integer;
{ Data no inicio da linha do journal (yyyy-mm-dd hh:nn:ss) como inteiro yyyymmddhhnnss. }
function HciParseStamp(P: PAnsiChar; Len: Integer): Int64;
function HciFormatStamp(const ATs: Int64): string;
function HciSpanKey(ALn0, ALn1: Integer): Int64;

type
  { Pesquisa por data digitada pelo usuario; campos 0 / '' = qualquer valor. }
  THistDateQuery = record
    Active, Valid: Boolean;
    Y, M, D: Integer;
    TimeDigits: string;
    { Intervalo de dias yyyymmdd (inclusivo). }
    DayFrom, DayTo: Integer;
  end;

{ Aceita partes de data e/ou hora: "2026-09-25", "25/09/2026", "25/09", "2026", "21:30",
  "25/09/2026 21:30". A ordem de d/m/a com "/" ou "." segue o formato curto do sistema. }
function HciParseDateQuery(const S: string): THistDateQuery;
function HciStampMatches(const Q: THistDateQuery; const ATs: Int64): Boolean;
{ "yyyy-mm-dd hh:nn:ss..." -> yyyymmddhhnnss (0 se nao comecar por uma data). }
function HciStampFromText(const S: string): Int64;

implementation

uses
  uTextEncoding;

function HciJournalStamp(const APath: string; out ASize, ATime: Int64): Boolean;
var
  Data: TWin32FileAttributeData;
begin
  ASize := 0;
  ATime := 0;
  Result := (APath <> '') and
    GetFileAttributesEx(PChar(APath), GetFileExInfoStandard, @Data);
  if not Result then Exit;
  ASize := (Int64(Data.nFileSizeHigh) shl 32) or Data.nFileSizeLow;
  ATime := (Int64(Data.ftLastWriteTime.dwHighDateTime) shl 32) or
    Data.ftLastWriteTime.dwLowDateTime;
end;

function HciTotalEvents(const R: THciRec): Integer;
var
  k: Integer;
begin
  Result := 0;
  for k := 1 to 5 do
    Inc(Result, R.Cnt[k]);
end;

function HciParseStamp(P: PAnsiChar; Len: Integer): Int64;
var
  i, n, d: Integer;
  Digs: array[0..13] of Integer;
  c: AnsiChar;
begin
  Result := 0;
  n := 0;
  i := 0;
  if (Len >= 3) and (P[0] = #$EF) and (P[1] = #$BB) and (P[2] = #$BF) then
    i := 3;
  while (i < Len) and (n < 14) do
  begin
    c := P[i];
    if c = '|' then Break;
    if (c >= '0') and (c <= '9') then
    begin
      Digs[n] := Ord(c) - Ord('0');
      Inc(n);
    end;
    Inc(i);
  end;
  if n < 14 then Exit;
  for d := 0 to 13 do
    Result := Result * 10 + Digs[d];
end;

function HciFormatStamp(const ATs: Int64): string;
var
  S: string;
begin
  if ATs <= 0 then
    Exit('');
  S := IntToStr(ATs);
  if Length(S) < 14 then
    S := StringOfChar('0', 14 - Length(S)) + S;
  Result := Copy(S, 1, 4) + '-' + Copy(S, 5, 2) + '-' + Copy(S, 7, 2) + ' ' +
    Copy(S, 9, 2) + ':' + Copy(S, 11, 2) + ':' + Copy(S, 13, 2);
end;

function HciSpanKey(ALn0, ALn1: Integer): Int64;
begin
  Result := (Int64(ALn0) shl 32) or Cardinal(ALn1);
end;

function HciParseDateQuery(const S: string): THistDateQuery;
var
  Tokens, Parts: TArray<string>;
  Tok, Fmt, Order: string;
  i, k, v: Integer;
  Q: THistDateQuery;

  function AllDigits(const T: string): Boolean;
  var
    c: Char;
  begin
    Result := T <> '';
    for c in T do
      if not CharInSet(c, ['0'..'9']) then
        Exit(False);
  end;

  function SetPart(AKind: Char; const T: string): Boolean;
  begin
    Result := AllDigits(T);
    if not Result then Exit;
    v := StrToInt(T);
    case AKind of
      'd':
        begin
          Result := (v >= 1) and (v <= 31);
          Q.D := v;
        end;
      'm':
        begin
          Result := (v >= 1) and (v <= 12);
          Q.M := v;
        end;
      'y':
        begin
          if Length(T) <= 2 then
            Inc(v, 2000);
          Result := (v >= 1900) and (v <= 9999);
          Q.Y := v;
        end;
    end;
  end;

begin
  Q := Default(THistDateQuery);
  Q.Active := Trim(S) <> '';
  Result := Q;
  if not Q.Active then Exit;
  Result.Valid := False;
  { Ordem d/m/a do formato curto do sistema, para datas com "/" ou ".". }
  Order := '';
  Fmt := LowerCase(FormatSettings.ShortDateFormat);
  for i := 1 to Length(Fmt) do
    if CharInSet(Fmt[i], ['d', 'm', 'y']) and (Pos(Fmt[i], Order) = 0) then
      Order := Order + Fmt[i];
  if Length(Order) <> 3 then
    Order := 'dmy';
  Tokens := Trim(S).Split([' '], TStringSplitOptions.ExcludeEmpty);
  for Tok in Tokens do
  begin
    if Pos(':', Tok) > 0 then
    begin
      Parts := Tok.Split([':']);
      Q.TimeDigits := '';
      for k := 0 to High(Parts) do
      begin
        if not AllDigits(Parts[k]) or (Length(Parts[k]) > 2) then Exit;
        Q.TimeDigits := Q.TimeDigits + StringOfChar('0', 2 - Length(Parts[k])) + Parts[k];
      end;
    end
    else if Pos('-', Tok) > 0 then
    begin
      Parts := Tok.Split(['-']);
      if Length(Parts) > 3 then Exit;
      if Length(Parts[0]) = 4 then
      begin
        if not SetPart('y', Parts[0]) then Exit;
        if (Length(Parts) > 1) and not SetPart('m', Parts[1]) then Exit;
        if (Length(Parts) > 2) and not SetPart('d', Parts[2]) then Exit;
      end
      else
        for k := 0 to High(Parts) do
          if not SetPart('dmy'[k + 1], Parts[k]) then Exit;
    end
    else if (Pos('/', Tok) > 0) or (Pos('.', Tok) > 0) then
    begin
      Parts := Tok.Split(['/', '.']);
      if Length(Parts) > 3 then Exit;
      for k := 0 to High(Parts) do
        if not SetPart(Order[k + 1], Parts[k]) then Exit;
    end
    else if AllDigits(Tok) and (Length(Tok) = 8) then
    begin
      if not SetPart('y', Copy(Tok, 1, 4)) or not SetPart('m', Copy(Tok, 5, 2)) or
         not SetPart('d', Copy(Tok, 7, 2)) then Exit;
    end
    else if AllDigits(Tok) and (Length(Tok) = 4) then
    begin
      if not SetPart('y', Tok) then Exit;
    end
    else if AllDigits(Tok) and (Length(Tok) <= 2) then
    begin
      if not SetPart('d', Tok) then Exit;
    end
    else
      Exit;
  end;
  Result := Q;
  Result.Valid := True;
end;

function HciStampMatches(const Q: THistDateQuery; const ATs: Int64): Boolean;
var
  T: string;
begin
  if not Q.Active then Exit(True);
  if not Q.Valid or (ATs <= 0) then Exit(False);
  if (Q.DayFrom <> 0) and (ATs div 1000000 < Q.DayFrom) then Exit(False);
  if (Q.DayTo <> 0) and (ATs div 1000000 > Q.DayTo) then Exit(False);
  if (Q.Y <> 0) and (ATs div 10000000000 <> Q.Y) then Exit(False);
  if (Q.M <> 0) and ((ATs div 100000000) mod 100 <> Q.M) then Exit(False);
  if (Q.D <> 0) and ((ATs div 1000000) mod 100 <> Q.D) then Exit(False);
  if Q.TimeDigits <> '' then
  begin
    T := IntToStr(ATs mod 1000000);
    T := StringOfChar('0', 6 - Length(T)) + T;
    if Copy(T, 1, Length(Q.TimeDigits)) <> Q.TimeDigits then Exit(False);
  end;
  Result := True;
end;

function HciStampFromText(const S: string): Int64;
var
  i: Integer;
  c: Char;
begin
  Result := 0;
  if (Length(S) < 19) or (S[5] <> '-') or (S[8] <> '-') or (S[14] <> ':') then Exit;
  for i := 1 to 19 do
  begin
    c := S[i];
    if CharInSet(c, ['0'..'9']) then
      Result := Result * 10 + (Ord(c) - Ord('0'))
    else if not CharInSet(c, ['-', ' ', ':']) then
      Exit(0);
  end;
end;

{ Mesmo significado que HistParseJournalLineSpan + HistParseJournalTag, sem TStringList. }
function HciParseLine(P: PAnsiChar; Len: Integer; out ALn0, ALn1: Integer;
  out ATag: Byte): Boolean;
var
  FStart, FLen: array[0..3] of Integer;
  nF, i, s, OpS, OpL: Integer;

  function IsOp(const AName: AnsiString): Boolean;
  var
    j: Integer;
    c: AnsiChar;
  begin
    Result := OpL = Length(AName);
    if not Result then Exit;
    for j := 1 to OpL do
    begin
      c := P[OpS + j - 1];
      if (c >= 'a') and (c <= 'z') then
        Dec(c, 32);
      if c <> AName[j] then
        Exit(False);
    end;
  end;

  function FieldInt(AIdx, ADef: Integer): Integer;
  var
    j, e: Integer;
    v: Int64;
    neg, any: Boolean;
  begin
    Result := ADef;
    if AIdx >= nF then Exit;
    j := FStart[AIdx];
    e := j + FLen[AIdx];
    while (j < e) and (P[j] = ' ') do Inc(j);
    neg := (j < e) and (P[j] = '-');
    if neg then Inc(j);
    v := 0;
    any := False;
    while (j < e) and (P[j] >= '0') and (P[j] <= '9') do
    begin
      v := v * 10 + (Ord(P[j]) - Ord('0'));
      if v > MaxInt then Exit;
      any := True;
      Inc(j);
    end;
    while (j < e) and (P[j] = ' ') do Inc(j);
    if (not any) or (j <> e) then Exit;
    if neg then v := -v;
    Result := Integer(v);
  end;

var
  cnt: Integer;
begin
  Result := False;
  ALn0 := 0;
  ALn1 := 0;
  ATag := 0;
  while (Len > 0) and ((P[Len - 1] = #13) or (P[Len - 1] = ' ')) do Dec(Len);
  s := 0;
  if (Len >= 3) and (P[0] = #$EF) and (P[1] = #$BB) and (P[2] = #$BF) then s := 3;
  while (s < Len) and (P[s] = ' ') do Inc(s);
  if (s >= Len) or (P[s] = '#') then Exit;
  nF := 0;
  FStart[0] := s;
  for i := s to Len - 1 do
    if P[i] = '|' then
    begin
      FLen[nF] := i - FStart[nF];
      Inc(nF);
      if nF > 3 then Break;
      FStart[nF] := i + 1;
    end;
  if nF <= 3 then
  begin
    FLen[nF] := Len - FStart[nF];
    Inc(nF);
  end;
  if nF < 3 then Exit;
  OpS := FStart[1];
  OpL := FLen[1];
  while (OpL > 0) and (P[OpS] = ' ') do
  begin
    Inc(OpS);
    Dec(OpL);
  end;
  while (OpL > 0) and (P[OpS + OpL - 1] = ' ') do Dec(OpL);
  if (OpL < 3) or (OpL > 6) then Exit;
  if IsOp('EDT') or IsOp('INS') or IsOp('DEL') or IsOp('MRGF') then
  begin
    if IsOp('EDT') or IsOp('MRGF') then ATag := 1
    else if IsOp('INS') then ATag := 2
    else ATag := 3;
    ALn0 := FieldInt(2, 0);
    ALn1 := ALn0;
  end
  else if IsOp('BINS') or IsOp('BAUT') or IsOp('BDEL') or IsOp('MDLT') then
  begin
    if IsOp('MDLT') then ATag := 1
    else if IsOp('BDEL') then ATag := 3
    else ATag := 2;
    ALn0 := FieldInt(2, 0);
    cnt := FieldInt(3, 1);
    if cnt < 1 then cnt := 1;
    ALn1 := ALn0 + cnt - 1;
    if ALn1 < ALn0 then ALn1 := ALn0;
  end
  else if IsOp('RPLALL') then
  begin
    ATag := 4;
    ALn0 := 1;
    ALn1 := MaxInt div 4;
  end;
  Result := ALn0 > 0;
end;

{ THistChangedIndex }

destructor THistChangedIndex.Destroy;
begin
  FreeAndNil(FDisk);
  if FDiskPath <> '' then
    DeleteFile(FDiskPath);
  inherited;
end;

function THistChangedIndex.GetOnDisk: Boolean;
begin
  Result := Assigned(FDisk);
end;

procedure THistChangedIndex.LoadCache(AIndex: Integer);
var
  n: Integer;
begin
  FCacheFirst := (AIndex div cHciCachePage) * cHciCachePage;
  n := Min(cHciCachePage, FCount - FCacheFirst);
  SetLength(FCache, n);
  if n <= 0 then Exit;
  FDisk.Position := Int64(FCacheFirst) * SizeOf(THciRec);
  FDisk.ReadBuffer(FCache[0], n * SizeOf(THciRec));
end;

function THistChangedIndex.Get(AIndex: Integer): THciRec;
begin
  FillChar(Result, SizeOf(Result), 0);
  if (AIndex < 0) or (AIndex >= FCount) then Exit;
  if not Assigned(FDisk) then
    Exit(FRecs[AIndex]);
  if (Length(FCache) = 0) or (AIndex < FCacheFirst) or
     (AIndex >= FCacheFirst + Length(FCache)) then
    LoadCache(AIndex);
  Result := FCache[AIndex - FCacheFirst];
end;

function THistChangedIndex.LowerBound(ALine: Integer): Integer;
var
  lo, hi, mid: Integer;
begin
  lo := 0;
  hi := FCount;
  while lo < hi do
  begin
    mid := (lo + hi) shr 1;
    if Get(mid).Ln0 < ALine then
      lo := mid + 1
    else
      hi := mid;
  end;
  Result := lo;
end;

{ THciScanThread }

constructor THciScanThread.Create(const AJournal: string; AWnd: HWND; AMsg: UINT);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpLower;
  FPath := AJournal;
  FWnd := AWnd;
  FMsg := AMsg;
  FLastPct := -1;
end;

procedure THciScanThread.PostDone;
begin
  if FWnd <> 0 then
    PostMessage(FWnd, FMsg, cHciMsgDone, LPARAM(Self));
end;

function THciScanThread.ScanLines(AFrom, ATo: Int64; const AProc: THciLineFunc;
  AReportProgress: Boolean): Boolean;
const
  cBuf = 1 shl 20;
var
  F: TFileStream;
  Buf, Carry: TBytes;
  CarryLen, Got, i, St, n, Pct: Integer;
  Pos0, LineOfs, Total: Int64;
  Stop: Boolean;

  procedure AddCarry(ASrc: Integer; ALen: Integer);
  begin
    if ALen <= 0 then Exit;
    if CarryLen + ALen > Length(Carry) then
      SetLength(Carry, Max(CarryLen + ALen, Length(Carry) * 2 + 256));
    Move(Buf[ASrc], Carry[CarryLen], ALen);
    Inc(CarryLen, ALen);
  end;

begin
  Result := False;
  try
    F := TFileStream.Create(FPath, fmOpenRead or fmShareDenyNone);
  except
    Exit;
  end;
  try
    if (ATo < 0) or (ATo > F.Size) then ATo := F.Size;
    if AFrom < 0 then AFrom := 0;
    if AFrom >= ATo then Exit(True);
    F.Position := AFrom;
    Total := ATo - AFrom;
    SetLength(Buf, cBuf);
    CarryLen := 0;
    LineOfs := AFrom;
    Pos0 := AFrom;
    Stop := False;
    while (Pos0 < ATo) and not Terminated and not Stop do
    begin
      Got := F.Read(Buf[0], Integer(Min(Int64(cBuf), ATo - Pos0)));
      if Got <= 0 then Break;
      St := 0;
      i := 0;
      while i < Got do
      begin
        if Buf[i] = 10 then
        begin
          if CarryLen > 0 then
          begin
            AddCarry(St, i - St);
            n := CarryLen;
            CarryLen := 0;
            Stop := not AProc(PAnsiChar(@Carry[0]), n, LineOfs);
          end
          else if i > St then
            Stop := not AProc(PAnsiChar(@Buf[St]), i - St, LineOfs)
          else
            Stop := not AProc(PAnsiChar(@Buf[0]), 0, LineOfs);
          St := i + 1;
          LineOfs := Pos0 + St;
          if Stop then Break;
        end;
        Inc(i);
      end;
      if not Stop then
        AddCarry(St, Got - St);
      Inc(Pos0, Got);
      if AReportProgress and (FWnd <> 0) then
      begin
        Pct := Integer((Pos0 - AFrom) * 100 div Total);
        if Pct <> FLastPct then
        begin
          FLastPct := Pct;
          PostMessage(FWnd, FMsg, cHciMsgProgress, Pct);
        end;
      end;
    end;
    if (CarryLen > 0) and not Terminated and not Stop then
      AProc(PAnsiChar(@Carry[0]), CarryLen, LineOfs);
    Result := not Terminated;
  finally
    F.Free;
  end;
end;

{ THciBuildThread }

constructor THciBuildThread.Create(const AJournal, ATempDir: string; AWnd: HWND; AMsg: UINT);
begin
  inherited Create(AJournal, AWnd, AMsg);
  FTempDir := ATempDir;
end;

destructor THciBuildThread.Destroy;
begin
  FResult.Free;
  inherited;
end;

function THciBuildThread.TakeResult: THistChangedIndex;
begin
  Result := FResult;
  FResult := nil;
end;

procedure THciBuildThread.Execute;
var
  Dict: TDictionary<Int64, Integer>;
  Recs: THciRecArray;
  N: Integer;
  Idx: THistChangedIndex;
  Size0, Time0: Int64;
  FS: TFileStream;
  DiskPath: string;
begin
  try
    if not HciJournalStamp(FPath, Size0, Time0) then Exit;
    N := 0;
    SetLength(Recs, 1024);
    Dict := TDictionary<Int64, Integer>.Create;
    try
      if not ScanLines(0, Size0,
        function(P: PAnsiChar; Len: Integer; Ofs: Int64): Boolean
        var
          L0, L1, Ix: Integer;
          Tg: Byte;
          Ts, K: Int64;
          R: PHciRec;
        begin
          Result := True;
          if not HciParseLine(P, Len, L0, L1, Tg) then Exit;
          Ts := HciParseStamp(P, Len);
          K := (Int64(L0) shl 32) or Cardinal(L1);
          if not Dict.TryGetValue(K, Ix) then
          begin
            if N = Length(Recs) then
              SetLength(Recs, N * 2);
            Ix := N;
            Inc(N);
            FillChar(Recs[Ix], SizeOf(THciRec), 0);
            Recs[Ix].Ln0 := L0;
            Recs[Ix].Ln1 := L1;
            Recs[Ix].FirstOfs := Ofs;
            Dict.Add(K, Ix);
          end;
          R := @Recs[Ix];
          if (Tg >= 1) and (Tg <= 5) and (R^.Cnt[Tg] < High(Word)) then
            Inc(R^.Cnt[Tg]);
          R^.LastTag := Tg;
          R^.LastOfs := Ofs;
          if Ts > 0 then
          begin
            if (R^.FirstTs = 0) or (Ts < R^.FirstTs) then
              R^.FirstTs := Ts;
            if Ts > R^.LastTs then
              R^.LastTs := Ts;
          end;
        end, True) then
        Exit;
    finally
      Dict.Free;
    end;
    if Terminated then Exit;
    SetLength(Recs, N);
    TArray.Sort<THciRec>(Recs, TComparer<THciRec>.Construct(
      function(const A, B: THciRec): Integer
      begin
        if A.Ln0 <> B.Ln0 then
          Result := CompareValue(A.Ln0, B.Ln0)
        else
          Result := CompareValue(A.Ln1, B.Ln1);
      end));
    if Terminated then Exit;

    Idx := THistChangedIndex.Create;
    try
      Idx.FJournalPath := FPath;
      Idx.FJournalSize := Size0;
      Idx.FJournalTime := Time0;
      Idx.FCount := N;
      if (N > cHciDiskThreshold) and (FTempDir <> '') then
      begin
        DiskPath := IncludeTrailingPathDelimiter(FTempDir) +
          Format('ffchg_%x_%x.bin', [GetCurrentProcessId, GetTickCount]);
        FS := TFileStream.Create(DiskPath, fmCreate);
        try
          FS.WriteBuffer(Recs[0], N * SizeOf(THciRec));
        finally
          FS.Free;
        end;
        Recs := nil;
        Idx.FDiskPath := DiskPath;
        Idx.FDisk := TFileStream.Create(DiskPath, fmOpenRead or fmShareDenyWrite);
      end
      else
        Idx.FRecs := Recs;
      FResult := Idx;
      Idx := nil;
    finally
      Idx.Free;
    end;
  finally
    PostDone;
  end;
end;

{ THciEventScanThread }

constructor THciEventScanThread.Create(const AJournal: string; AFrom, ALastOfs: Int64;
  ALine: Integer; AWnd: HWND; AMsg: UINT);
begin
  inherited Create(AJournal, AWnd, AMsg);
  FFrom := AFrom;
  FLastOfs := ALastOfs;
  FLine := ALine;
  SetLength(FRing, cHciMaxEventsOnDemand);
end;

destructor THciEventScanThread.Destroy;
begin
  FRing := nil;
  inherited;
end;

function THciEventScanThread.TakeEvents: TStringList;
var
  i, first: Integer;
begin
  Result := TStringList.Create;
  Result.Capacity := FRingCount;
  first := (FRingPos - FRingCount + cHciMaxEventsOnDemand) mod cHciMaxEventsOnDemand;
  for i := 0 to FRingCount - 1 do
    Result.Add(FRing[(first + i) mod cHciMaxEventsOnDemand]);
  FRing := nil;
  FRingCount := 0;
end;

procedure THciEventScanThread.Execute;
begin
  try
    ScanLines(FFrom, -1,
      function(P: PAnsiChar; Len: Integer; Ofs: Int64): Boolean
      var
        L0, L1: Integer;
        Tg: Byte;
        Raw: AnsiString;
      begin
        Result := Ofs <= FLastOfs;
        if not Result then Exit;
        if not HciParseLine(P, Len, L0, L1, Tg) then Exit;
        if (FLine < L0) or (FLine > L1) then Exit;
        SetString(Raw, P, Len);
        FRing[FRingPos] := Trim(RawBytesToDisplayString(Raw));
        FRingPos := (FRingPos + 1) mod cHciMaxEventsOnDemand;
        if FRingCount < cHciMaxEventsOnDemand then
          Inc(FRingCount);
      end, False);
  finally
    PostDone;
  end;
end;

end.
