unit uHistPagedPreview;

{ Preview paginado do historico de sessao para ficheiros de qualquer tamanho.

  - Indice esparso: um offset (Int64) a cada cFFPagedLinesPerBlock linhas, construido
    numa thread. 80 GB com ~400M linhas => ~400K offsets (~3 MB).
  - Cache LRU de paginas (bloco de linhas) lidas sob demanda; texto cortado para exibicao.
  - Cores do journal: intervalos achatados (sem vetor do tamanho do ficheiro); busca binaria.
  - Indice gravado em disco (<journal>.lidx) e reutilizado enquanto tamanho/data nao mudarem. }

interface

uses
  Windows, SysUtils, Classes, SyncObjs;

const
  cFFPagedLinesPerBlock = 1024;
  { Paginas em memoria (cada uma ate' 1024 linhas x cFFPagedMaxDisplayChars). }
  cFFPagedMaxCachedPages = 12;
  cFFPagedMaxDisplayChars = 1000;
  { Nunca ler mais que isto para montar uma pagina (linhas gigantes sem LF). }
  cFFPagedMaxPageReadBytes = 64 * 1024 * 1024;
  { Journal acima disto: cores omitidas (limita RAM do mapa de intervalos). }
  cFFPagedMaxJournalBytes = 16 * 1024 * 1024;
  { Ficheiros menores indexam num instante; nao vale gravar .lidx. }
  cFFPagedMinCacheFileBytes = 64 * 1024 * 1024;

type
  TFFInt64Array = array of Int64;
  TFFByteArray = array of Byte;
  { Tags da legenda: 0 igual, 1 EDT, 2 INS, 3 DEL, 4 RPLALL, 5 UNDO/REDO. }
  TFFHistKindSet = set of 0..5;

  TFFExportRange = record
    First, Last: Int64;
    Kind: Byte;
  end;
  TFFExportRangeArray = array of TFFExportRange;

  { Exporta (em streaming) as linhas cujas tags estao no conjunto pedido.
    Salta com o indice esparso ate' cada intervalo; RAM constante. }
  TFFPagedExportThread = class(TThread)
  private
    FSrcPath: string;
    FOutPath: string;
    FBomSkip: Integer;
    FOffsets: TFFInt64Array;
    FFileSize: Int64;
    FRanges: TFFExportRangeArray;
    FWithPrefix: Boolean;
    FLock: TCriticalSection;
    FLinesWritten: Int64;
    FBytesPos: Int64;
    FError: string;
    FCancelled: Boolean;
    FDone: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASrcPath, AOutPath: string; ABomSkip: Integer;
      const AOffsets: TFFInt64Array; const AFileSize: Int64;
      const ARanges: TFFExportRangeArray; AWithPrefix: Boolean);
    destructor Destroy; override;
    procedure Cancel;
    function Percent: Integer;
    function LinesWritten: Int64;
    function IsDone: Boolean;
    function ErrorText: string;
    function WasCancelled: Boolean;
    property OutPath: string read FOutPath;
  end;

  TFFPagedLineSource = class;

  TFFPagedIndexThread = class(TThread)
  private
    FOwner: TFFPagedLineSource;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TFFPagedLineSource);
  end;

  TFFPagedCachePage = class
  public
    Block: Int64;
    Stamp: Cardinal;
    Lines: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  TFFPagedLineSource = class
  private
    FPath: string;
    FJournalPath: string;
    FEnc: string;
    FBomSkip: Integer;
    FFileSize: Int64;
    FFileTime: Int64;
    FLock: TCriticalSection;
    FOffsets: TFFInt64Array;
    FOffsetCount: Integer;
    FLineCount: Int64;
    FIndexBytes: Int64;
    FIndexDone: Boolean;
    FIndexFromCache: Boolean;
    FAbort: Boolean;
    FThread: TFFPagedIndexThread;
    FPages: TList;
    FStampSeq: Cardinal;
    FKindsReady: Boolean;
    FKindBase: Byte;
    FSegStart: TFFInt64Array;
    FSegKind: TFFByteArray;
    FSegCount: Integer;
    FJournalSkipped: Boolean;
    function IndexCachePath: string;
    function TryLoadIndexCache: Boolean;
    procedure SaveIndexCache;
    procedure AddOffset(const AOffset: Int64);
    procedure PublishProgress(const ALines, ABytes: Int64);
    procedure BuildIndex;
    procedure BuildJournalKinds;
    function FindPage(const ABlock: Int64): TFFPagedCachePage;
    function LoadPage(const ABlock: Int64): TFFPagedCachePage;
    function DecodeLine(const Raw: AnsiString; Truncated: Boolean): string;
  public
    constructor Create(const APath, AJournalPath: string);
    destructor Destroy; override;
    procedure Start;
    function LineCount: Int64;
    function IndexComplete: Boolean;
    function IndexPercent: Integer;
    function KindsReady: Boolean;
    { Texto da linha (0-based). Leitura sob demanda com cache LRU. So na thread da UI. }
    function GetLineText(const AIndex0: Int64): string;
    { Tag da legenda (0..5) para a linha 1-based. }
    function LineKind(const ALine1: Int64): Byte;
    { Exportacao das linhas com as tags pedidas. nil se o indice/cores ainda nao
      estiverem prontos. ACount devolve o numero de linhas que serao exportadas. }
    function CreateExport(const AOutPath: string; const AKinds: TFFHistKindSet;
      AWithPrefix: Boolean; out ACount: Int64): TFFPagedExportThread;
    property Path: string read FPath;
    property FileSize: Int64 read FFileSize;
    property JournalSkipped: Boolean read FJournalSkipped;
    property IndexFromCache: Boolean read FIndexFromCache;
  end;

implementation

uses
  Math, uTextEncoding;

const
  cIndexMagic: array[0..7] of AnsiChar = ('F', 'F', 'L', 'I', 'D', 'X', '0', '1');
  cScanBufBytes = 1024 * 1024;
  cPageBufBytes = 64 * 1024;
  cJournalBufBytes = 64 * 1024;
  { Bytes brutos guardados por linha antes de decodificar (UTF-8 ate' 4 bytes/char). }
  cMaxRawLineBytes = cFFPagedMaxDisplayChars * 4;
  cMaxJournalLineBytes = 1024;

type
  TKindRange = record
    First, Last: Int64;
    Kind: Byte;
  end;

  { Leitura partilhada com FILE_SHARE_DELETE: o preview nunca impede que a edicao
    apague/renomeie o ficheiro de origem (fmShareDenyNone nao inclui DELETE). }
  TFFSharedReadStream = class(THandleStream)
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
  end;

constructor TFFSharedReadStream.Create(const APath: string);
var
  H: THandle;
begin
  H := CreateFile(PChar(APath), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if H = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  inherited Create(H);
end;

destructor TFFSharedReadStream.Destroy;
begin
  if (Handle <> 0) and (Handle <> INVALID_HANDLE_VALUE) then
    CloseHandle(Handle);
  inherited Destroy;
end;

function GetFileTime64(const APath: string): Int64;
var
  Data: TWin32FileAttributeData;
begin
  Result := 0;
  if GetFileAttributesEx(PChar(APath), GetFileExInfoStandard, @Data) then
    Result := (Int64(Data.ftLastWriteTime.dwHighDateTime) shl 32) or
      Int64(Data.ftLastWriteTime.dwLowDateTime);
end;

function GetFileSize64(const APath: string): Int64;
var
  Data: TWin32FileAttributeData;
begin
  Result := -1;
  if GetFileAttributesEx(PChar(APath), GetFileExInfoStandard, @Data) then
    Result := (Int64(Data.nFileSizeHigh) shl 32) or Int64(Data.nFileSizeLow);
end;

{ --- TFFPagedIndexThread ---------------------------------------------------- }

constructor TFFPagedIndexThread.Create(AOwner: TFFPagedLineSource);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpLower;
  FOwner := AOwner;
end;

procedure TFFPagedIndexThread.Execute;
begin
  try
    FOwner.BuildJournalKinds;
    if FOwner.FAbort or Terminated then Exit;
    if FOwner.TryLoadIndexCache then Exit;
    FOwner.BuildIndex;
  except
    FOwner.FLock.Enter;
    try
      FOwner.FIndexDone := True;
      FOwner.FKindsReady := True;
    finally
      FOwner.FLock.Leave;
    end;
  end;
end;

{ --- TFFPagedCachePage ------------------------------------------------------ }

constructor TFFPagedCachePage.Create;
begin
  inherited Create;
  Lines := TStringList.Create;
end;

destructor TFFPagedCachePage.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

{ --- TFFPagedLineSource ----------------------------------------------------- }

constructor TFFPagedLineSource.Create(const APath, AJournalPath: string);
begin
  inherited Create;
  FPath := APath;
  FJournalPath := AJournalPath;
  FLock := TCriticalSection.Create;
  FPages := TList.Create;
  FFileSize := GetFileSize64(APath);
  if FFileSize < 0 then FFileSize := 0;
  FFileTime := GetFileTime64(APath);
  FEnc := DetectTextFileEncoding(APath);
  FBomSkip := 0;
  if Pos('UTF-8 (BOM)', FEnc) > 0 then
    FBomSkip := 3
  else if (Pos('UTF-16 LE', FEnc) > 0) or (Pos('UTF-16 BE', FEnc) > 0) then
    FBomSkip := 2;
  if FBomSkip > FFileSize then
    FBomSkip := 0;
end;

destructor TFFPagedLineSource.Destroy;
var
  i: Integer;
begin
  FAbort := True;
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
  for i := 0 to FPages.Count - 1 do
    TObject(FPages[i]).Free;
  FPages.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TFFPagedLineSource.Start;
begin
  if Assigned(FThread) then Exit;
  FThread := TFFPagedIndexThread.Create(Self);
  FThread.Start;
end;

function TFFPagedLineSource.LineCount: Int64;
begin
  FLock.Enter;
  try
    Result := FLineCount;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedLineSource.IndexComplete: Boolean;
begin
  FLock.Enter;
  try
    Result := FIndexDone;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedLineSource.IndexPercent: Integer;
begin
  FLock.Enter;
  try
    if FIndexDone or (FFileSize <= 0) then
      Result := 100
    else
      Result := Integer((FIndexBytes * 100) div FFileSize);
  finally
    FLock.Leave;
  end;
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;

function TFFPagedLineSource.KindsReady: Boolean;
begin
  FLock.Enter;
  try
    Result := FKindsReady;
  finally
    FLock.Leave;
  end;
end;

procedure TFFPagedLineSource.AddOffset(const AOffset: Int64);
begin
  FLock.Enter;
  try
    if FOffsetCount >= Length(FOffsets) then
    begin
      if Length(FOffsets) < 1024 then
        SetLength(FOffsets, 1024)
      else
        SetLength(FOffsets, Length(FOffsets) * 2);
    end;
    FOffsets[FOffsetCount] := AOffset;
    Inc(FOffsetCount);
  finally
    FLock.Leave;
  end;
end;

procedure TFFPagedLineSource.PublishProgress(const ALines, ABytes: Int64);
begin
  FLock.Enter;
  try
    FLineCount := ALines;
    FIndexBytes := ABytes;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedLineSource.IndexCachePath: string;
begin
  if FJournalPath = '' then
    Result := ''
  else
    Result := FJournalPath + '.lidx';
end;

function TFFPagedLineSource.TryLoadIndexCache: Boolean;
var
  P: string;
  F: TFileStream;
  Magic: array[0..7] of AnsiChar;
  Sz, Tm, Lines: Int64;
  K, Bom, Cnt: Integer;
  Tmp: TFFInt64Array;
begin
  Result := False;
  P := IndexCachePath;
  if (P = '') or (not FileExists(P)) then Exit;
  try
    F := TFileStream.Create(P, fmOpenRead or fmShareDenyWrite);
    try
      if F.Read(Magic, SizeOf(Magic)) <> SizeOf(Magic) then Exit;
      if not CompareMem(@Magic[0], @cIndexMagic[0], SizeOf(Magic)) then Exit;
      F.ReadBuffer(Sz, SizeOf(Sz));
      F.ReadBuffer(Tm, SizeOf(Tm));
      F.ReadBuffer(K, SizeOf(K));
      F.ReadBuffer(Bom, SizeOf(Bom));
      F.ReadBuffer(Lines, SizeOf(Lines));
      F.ReadBuffer(Cnt, SizeOf(Cnt));
      if (Sz <> FFileSize) or (Tm <> FFileTime) or (K <> cFFPagedLinesPerBlock) or
         (Bom <> FBomSkip) or (Cnt < 1) or (Lines < 0) then Exit;
      if Int64(Cnt) * SizeOf(Int64) <> F.Size - F.Position then Exit;
      SetLength(Tmp, Cnt);
      F.ReadBuffer(Tmp[0], NativeInt(Cnt) * SizeOf(Int64));
    finally
      F.Free;
    end;
  except
    Exit;
  end;
  FLock.Enter;
  try
    FOffsets := Tmp;
    FOffsetCount := Cnt;
    FLineCount := Lines;
    FIndexBytes := FFileSize;
    FIndexDone := True;
    FIndexFromCache := True;
  finally
    FLock.Leave;
  end;
  Result := True;
end;

procedure TFFPagedLineSource.SaveIndexCache;
var
  P, TmpPath: string;
  F: TFileStream;
  K, Bom, Cnt: Integer;
  Lines: Int64;
begin
  if FFileSize < cFFPagedMinCacheFileBytes then Exit;
  P := IndexCachePath;
  if (P = '') or (not DirectoryExists(ExtractFilePath(P))) then Exit;
  { So grava se o ficheiro nao mudou durante a indexacao. }
  if (GetFileSize64(FPath) <> FFileSize) or (GetFileTime64(FPath) <> FFileTime) then Exit;
  TmpPath := P + '.tmp';
  try
    F := TFileStream.Create(TmpPath, fmCreate);
    try
      K := cFFPagedLinesPerBlock;
      Bom := FBomSkip;
      FLock.Enter;
      try
        Cnt := FOffsetCount;
        Lines := FLineCount;
        F.WriteBuffer(cIndexMagic, SizeOf(cIndexMagic));
        F.WriteBuffer(FFileSize, SizeOf(FFileSize));
        F.WriteBuffer(FFileTime, SizeOf(FFileTime));
        F.WriteBuffer(K, SizeOf(K));
        F.WriteBuffer(Bom, SizeOf(Bom));
        F.WriteBuffer(Lines, SizeOf(Lines));
        F.WriteBuffer(Cnt, SizeOf(Cnt));
        if Cnt > 0 then
          F.WriteBuffer(FOffsets[0], NativeInt(Cnt) * SizeOf(Int64));
      finally
        FLock.Leave;
      end;
    finally
      F.Free;
    end;
    if FileExists(P) then
      DeleteFile(P);
    if not RenameFile(TmpPath, P) then
      DeleteFile(TmpPath);
  except
    DeleteFile(TmpPath);
  end;
end;

procedure TFFPagedLineSource.BuildIndex;
var
  F: TStream;
  Buf: array of Byte;
  Got, k: Integer;
  Base, LineNo, NextReport: Int64;
  PendingCR, HasData: Boolean;
  b: Byte;

  procedure EndLine(const ANextStart: Int64);
  begin
    Inc(LineNo);
    HasData := False;
    if (LineNo mod cFFPagedLinesPerBlock) = 0 then
      AddOffset(ANextStart);
  end;

begin
  F := TFFSharedReadStream.Create(FPath);
  try
    SetLength(Buf, cScanBufBytes);
    Base := FBomSkip;
    F.Position := Base;
    LineNo := 0;
    PendingCR := False;
    HasData := False;
    AddOffset(Base);
    NextReport := 0;
    while not FAbort do
    begin
      Got := F.Read(Buf[0], cScanBufBytes);
      if Got <= 0 then Break;
      for k := 0 to Got - 1 do
      begin
        b := Buf[k];
        if PendingCR then
        begin
          PendingCR := False;
          if b = 10 then
          begin
            EndLine(Base + k + 1);
            Continue;
          end;
          EndLine(Base + k);
        end;
        if b = 10 then
          EndLine(Base + k + 1)
        else if b = 13 then
          PendingCR := True
        else
          HasData := True;
      end;
      Inc(Base, Got);
      if Base >= NextReport then
      begin
        PublishProgress(LineNo, Base);
        NextReport := Base + 8 * cScanBufBytes;
      end;
    end;
    if FAbort then Exit;
    if PendingCR then
      EndLine(Base)
    else if HasData then
      Inc(LineNo);
    PublishProgress(LineNo, Base);
  finally
    F.Free;
  end;
  FLock.Enter;
  try
    FIndexDone := True;
  finally
    FLock.Leave;
  end;
  SaveIndexCache;
end;

{ Campo N (0-based) de uma linha "a|b|c" sem alocar listas. }
function JournalField(const S: string; N: Integer): string;
var
  i, Start, Idx: Integer;
begin
  Result := '';
  Idx := 0;
  Start := 1;
  for i := 1 to Length(S) + 1 do
    if (i > Length(S)) or (S[i] = '|') then
    begin
      if Idx = N then
      begin
        Result := Trim(Copy(S, Start, i - Start));
        Exit;
      end;
      Inc(Idx);
      Start := i + 1;
    end;
end;

procedure TFFPagedLineSource.BuildJournalKinds;
var
  Ranges: array of TKindRange;
  RangeCount: Integer;
  Base: Byte;

  procedure AddRange(const AFirst, ALast: Int64; AKind: Byte);
  begin
    if (ALast < 1) or (ALast < AFirst) then Exit;
    if RangeCount >= Length(Ranges) then
    begin
      if Length(Ranges) < 256 then
        SetLength(Ranges, 256)
      else
        SetLength(Ranges, Length(Ranges) * 2);
    end;
    if AFirst < 1 then
      Ranges[RangeCount].First := 1
    else
      Ranges[RangeCount].First := AFirst;
    Ranges[RangeCount].Last := ALast;
    Ranges[RangeCount].Kind := AKind;
    Inc(RangeCount);
  end;

  procedure ApplyLine(const S: string);
  var
    Op: string;
    L, Cnt: Int64;
  begin
    if (S = '') or (S[1] = '#') then Exit;
    Op := UpperCase(JournalField(S, 1));
    if Op = '' then Exit;
    if Op = 'RPLALL' then
    begin
      RangeCount := 0;
      Base := 4;
      Exit;
    end;
    L := StrToInt64Def(JournalField(S, 2), 0);
    if (Op = 'BINS') or (Op = 'BAUT') or (Op = 'BDEL') or (Op = 'MDLT') then
    begin
      Cnt := StrToInt64Def(JournalField(S, 3), 1);
      if Cnt < 1 then Cnt := 1;
      if Op = 'BDEL' then
        AddRange(L, L + Cnt - 1, 3)
      else if Op = 'MDLT' then
        AddRange(L, L + Cnt - 1, 1)
      else
        AddRange(L, L + Cnt - 1, 2);
    end
    else if Op = 'MRGF' then
      AddRange(1, 1, 1)
    else if Op = 'EDT' then
      AddRange(L, L, 1)
    else if Op = 'INS' then
      AddRange(L, L, 2)
    else if Op = 'DEL' then
      AddRange(L, L, 3);
  end;

  procedure SortBounds(var A: array of Int64; L, R: Integer);
  var
    i, j: Integer;
    P, T: Int64;
  begin
    while L < R do
    begin
      i := L;
      j := R;
      P := A[(L + R) shr 1];
      repeat
        while A[i] < P do Inc(i);
        while A[j] > P do Dec(j);
        if i <= j then
        begin
          T := A[i]; A[i] := A[j]; A[j] := T;
          Inc(i);
          Dec(j);
        end;
      until i > j;
      if (j - L) < (R - i) then
      begin
        if L < j then SortBounds(A, L, j);
        L := i;
      end
      else
      begin
        if i < R then SortBounds(A, i, R);
        R := j;
      end;
    end;
  end;

  function BoundIndex(const A: array of Int64; Count: Integer; const V: Int64): Integer;
  var
    Lo, Hi, Mid: Integer;
  begin
    Lo := 0;
    Hi := Count - 1;
    while Lo < Hi do
    begin
      Mid := (Lo + Hi) shr 1;
      if A[Mid] < V then
        Lo := Mid + 1
      else
        Hi := Mid;
    end;
    Result := Lo;
  end;

var
  F: TFileStream;
  Buf: array of AnsiChar;
  Got, k, i, j, m, s, e, OutCount: Integer;
  Cur: AnsiString;
  CurLen: Integer;
  Bounds: array of Int64;
  Next: array of Integer;
  SegK: array of Byte;
  OutStart: TFFInt64Array;
  OutKind: TFFByteArray;
  Kd: Byte;

  function FindFree(X: Integer): Integer;
  var
    R, T: Integer;
  begin
    R := X;
    while Next[R] <> R do
      R := Next[R];
    while Next[X] <> R do
    begin
      T := Next[X];
      Next[X] := R;
      X := T;
    end;
    Result := R;
  end;

begin
  Base := 0;
  RangeCount := 0;
  if (FJournalPath = '') or (not FileExists(FJournalPath)) then
  begin
    FLock.Enter;
    try
      FKindBase := 0;
      FSegCount := 0;
      FKindsReady := True;
    finally
      FLock.Leave;
    end;
    Exit;
  end;
  if GetFileSize64(FJournalPath) > cFFPagedMaxJournalBytes then
  begin
    FLock.Enter;
    try
      FJournalSkipped := True;
      FKindsReady := True;
    finally
      FLock.Leave;
    end;
    Exit;
  end;

  F := TFileStream.Create(FJournalPath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Buf, cJournalBufBytes);
    SetLength(Cur, cMaxJournalLineBytes);
    CurLen := 0;
    while not FAbort do
    begin
      Got := F.Read(Buf[0], cJournalBufBytes);
      if Got <= 0 then Break;
      for k := 0 to Got - 1 do
      begin
        if Buf[k] = #10 then
        begin
          ApplyLine(Trim(string(Copy(Cur, 1, CurLen))));
          CurLen := 0;
        end
        else if (Buf[k] <> #13) and (CurLen < cMaxJournalLineBytes) then
        begin
          Inc(CurLen);
          Cur[CurLen] := Buf[k];
        end;
      end;
    end;
    if CurLen > 0 then
      ApplyLine(Trim(string(Copy(Cur, 1, CurLen))));
  finally
    F.Free;
  end;
  if FAbort then Exit;

  { Achatar: a entrada mais recente vence. Percorre de tras para a frente e cada
    segmento elementar recebe a primeira cor que o cobrir (union-find "proximo livre"). }
  OutCount := 0;
  if RangeCount > 0 then
  begin
    SetLength(Bounds, RangeCount * 2);
    for i := 0 to RangeCount - 1 do
    begin
      Bounds[i * 2] := Ranges[i].First;
      Bounds[i * 2 + 1] := Ranges[i].Last + 1;
    end;
    SortBounds(Bounds, 0, High(Bounds));
    m := 0;
    for i := 0 to High(Bounds) do
      if (m = 0) or (Bounds[i] <> Bounds[m - 1]) then
      begin
        Bounds[m] := Bounds[i];
        Inc(m);
      end;
    SetLength(Bounds, m);

    SetLength(SegK, m);
    SetLength(Next, m);
    for i := 0 to m - 1 do
    begin
      SegK[i] := 255;
      Next[i] := i;
    end;
    for i := RangeCount - 1 downto 0 do
    begin
      if FAbort then Exit;
      s := BoundIndex(Bounds, m, Ranges[i].First);
      e := BoundIndex(Bounds, m, Ranges[i].Last + 1);
      j := FindFree(s);
      while j < e do
      begin
        SegK[j] := Ranges[i].Kind;
        Next[j] := j + 1;
        j := FindFree(j + 1);
      end;
    end;
    SetLength(Ranges, 0);
    SetLength(Next, 0);

    SetLength(OutStart, m);
    SetLength(OutKind, m);
    for i := 0 to m - 1 do
    begin
      Kd := SegK[i];
      if (i = m - 1) or (Kd = 255) then
        Kd := Base;
      if (OutCount = 0) or (OutKind[OutCount - 1] <> Kd) then
      begin
        OutStart[OutCount] := Bounds[i];
        OutKind[OutCount] := Kd;
        Inc(OutCount);
      end;
    end;
    SetLength(OutStart, OutCount);
    SetLength(OutKind, OutCount);
  end;

  FLock.Enter;
  try
    FKindBase := Base;
    FSegStart := OutStart;
    FSegKind := OutKind;
    FSegCount := OutCount;
    FKindsReady := True;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedLineSource.LineKind(const ALine1: Int64): Byte;
var
  Lo, Hi, Mid: Integer;
begin
  Result := 0;
  if ALine1 < 1 then Exit;
  FLock.Enter;
  try
    if not FKindsReady then Exit;
    Result := FKindBase;
    if (FSegCount = 0) or (ALine1 < FSegStart[0]) then Exit;
    Lo := 0;
    Hi := FSegCount - 1;
    while Lo < Hi do
    begin
      Mid := (Lo + Hi + 1) shr 1;
      if FSegStart[Mid] <= ALine1 then
        Lo := Mid
      else
        Hi := Mid - 1;
    end;
    Result := FSegKind[Lo];
  finally
    FLock.Leave;
  end;
end;

function TFFPagedLineSource.DecodeLine(const Raw: AnsiString; Truncated: Boolean): string;
begin
  if Raw = '' then
    Result := ''
  else
    Result := DisplayTextFromFileBytes(Raw, FEnc);
  if Length(Result) > cFFPagedMaxDisplayChars then
  begin
    SetLength(Result, cFFPagedMaxDisplayChars);
    Truncated := True;
  end;
  if Truncated then
    Result := Result + ' ...';
end;

function TFFPagedLineSource.FindPage(const ABlock: Int64): TFFPagedCachePage;
var
  i: Integer;
begin
  for i := 0 to FPages.Count - 1 do
    if TFFPagedCachePage(FPages[i]).Block = ABlock then
    begin
      Result := TFFPagedCachePage(FPages[i]);
      Inc(FStampSeq);
      Result.Stamp := FStampSeq;
      Exit;
    end;
  Result := nil;
end;

function TFFPagedLineSource.LoadPage(const ABlock: Int64): TFFPagedCachePage;
var
  StartOfs, LinesInBlock, Total: Int64;
  Buf: array of Byte;
  Got, k, i, Oldest, RawLen: Integer;
  Raw: AnsiString;
  RawTrunc, PendingCR, Done: Boolean;
  ReadBytes: Int64;
  b: Byte;
  Page: TFFPagedCachePage;
  F: TStream;

  procedure FlushLine;
  begin
    Page.Lines.Add(DecodeLine(Copy(Raw, 1, RawLen), RawTrunc));
    RawLen := 0;
    RawTrunc := False;
    if Page.Lines.Count >= LinesInBlock then
      Done := True;
  end;

begin
  Result := nil;
  FLock.Enter;
  try
    if (ABlock < 0) or (ABlock >= FOffsetCount) then Exit;
    StartOfs := FOffsets[ABlock];
    Total := FLineCount;
  finally
    FLock.Leave;
  end;
  LinesInBlock := Total - ABlock * cFFPagedLinesPerBlock;
  if LinesInBlock > cFFPagedLinesPerBlock then
    LinesInBlock := cFFPagedLinesPerBlock;
  if LinesInBlock <= 0 then Exit;

  if FPages.Count >= cFFPagedMaxCachedPages then
  begin
    Oldest := 0;
    for i := 1 to FPages.Count - 1 do
      if TFFPagedCachePage(FPages[i]).Stamp < TFFPagedCachePage(FPages[Oldest]).Stamp then
        Oldest := i;
    TObject(FPages[Oldest]).Free;
    FPages.Delete(Oldest);
  end;

  Page := TFFPagedCachePage.Create;
  Page.Block := ABlock;
  Inc(FStampSeq);
  Page.Stamp := FStampSeq;
  FPages.Add(Page);
  Result := Page;

  F := nil;
  try
    F := TFFSharedReadStream.Create(FPath);
    F.Position := StartOfs;
    SetLength(Buf, cPageBufBytes);
    SetLength(Raw, cMaxRawLineBytes);
    RawLen := 0;
    RawTrunc := False;
    PendingCR := False;
    Done := False;
    ReadBytes := 0;
    while (not Done) and (ReadBytes < cFFPagedMaxPageReadBytes) do
    begin
      Got := F.Read(Buf[0], cPageBufBytes);
      if Got <= 0 then Break;
      Inc(ReadBytes, Got);
      k := 0;
      while (k < Got) and (not Done) do
      begin
        b := Buf[k];
        Inc(k);
        if PendingCR then
        begin
          PendingCR := False;
          FlushLine;
          if b = 10 then Continue;
          if Done then Break;
        end;
        if b = 10 then
          FlushLine
        else if b = 13 then
          PendingCR := True
        else if RawLen < cMaxRawLineBytes then
        begin
          Inc(RawLen);
          Raw[RawLen] := AnsiChar(b);
        end
        else
          RawTrunc := True;
      end;
    end;
    if (not Done) and (PendingCR or (RawLen > 0) or RawTrunc) then
      FlushLine;
  except
    { Leitura falhou (ficheiro em uso/removido): pagina fica com o que foi lido. }
  end;
  F.Free;
  while Page.Lines.Count < LinesInBlock do
    Page.Lines.Add('...');
end;

function TFFPagedLineSource.GetLineText(const AIndex0: Int64): string;
var
  Block: Int64;
  Page: TFFPagedCachePage;
  Idx: Integer;
begin
  Result := '';
  if (AIndex0 < 0) or (AIndex0 >= LineCount) then Exit;
  Block := AIndex0 div cFFPagedLinesPerBlock;
  Idx := Integer(AIndex0 mod cFFPagedLinesPerBlock);
  Page := FindPage(Block);
  if Assigned(Page) and (Idx >= Page.Lines.Count) then
  begin
    { Pagina lida enquanto o indice ainda crescia: reler com as linhas novas. }
    FPages.Remove(Page);
    Page.Free;
    Page := nil;
  end;
  if not Assigned(Page) then
    Page := LoadPage(Block);
  if not Assigned(Page) then Exit;
  if Idx < Page.Lines.Count then
    Result := Page.Lines[Idx];
end;

function TFFPagedLineSource.CreateExport(const AOutPath: string; const AKinds: TFFHistKindSet;
  AWithPrefix: Boolean; out ACount: Int64): TFFPagedExportThread;
var
  Ranges: TFFExportRangeArray;
  RangeCount, i: Integer;
  Offs: TFFInt64Array;
  Total, SegEnd: Int64;

  procedure AddR(AFirst, ALast: Int64; AKind: Byte);
  begin
    if ALast > Total then ALast := Total;
    if AFirst < 1 then AFirst := 1;
    if (ALast < AFirst) or (not (AKind in AKinds)) then Exit;
    if (RangeCount > 0) and (Ranges[RangeCount - 1].Kind = AKind) and
       (Ranges[RangeCount - 1].Last + 1 = AFirst) then
    begin
      Ranges[RangeCount - 1].Last := ALast;
      Inc(ACount, ALast - AFirst + 1);
      Exit;
    end;
    if RangeCount >= Length(Ranges) then
      SetLength(Ranges, Max(64, Length(Ranges) * 2));
    Ranges[RangeCount].First := AFirst;
    Ranges[RangeCount].Last := ALast;
    Ranges[RangeCount].Kind := AKind;
    Inc(RangeCount);
    Inc(ACount, ALast - AFirst + 1);
  end;

begin
  Result := nil;
  ACount := 0;
  RangeCount := 0;
  FLock.Enter;
  try
    if (not FIndexDone) or (not FKindsReady) then Exit;
    Total := FLineCount;
    if FSegCount = 0 then
      AddR(1, Total, FKindBase)
    else
    begin
      AddR(1, FSegStart[0] - 1, FKindBase);
      for i := 0 to FSegCount - 1 do
      begin
        if i < FSegCount - 1 then
          SegEnd := FSegStart[i + 1] - 1
        else
          SegEnd := Total;
        AddR(FSegStart[i], SegEnd, FSegKind[i]);
        if FSegStart[i] > Total then Break;
      end;
    end;
    Offs := Copy(FOffsets, 0, FOffsetCount);
  finally
    FLock.Leave;
  end;
  SetLength(Ranges, RangeCount);
  if RangeCount = 0 then Exit;
  Result := TFFPagedExportThread.Create(FPath, AOutPath, FBomSkip, Offs, FFileSize,
    Ranges, AWithPrefix);
end;

{ --- TFFPagedExportThread --------------------------------------------------- }

constructor TFFPagedExportThread.Create(const ASrcPath, AOutPath: string; ABomSkip: Integer;
  const AOffsets: TFFInt64Array; const AFileSize: Int64;
  const ARanges: TFFExportRangeArray; AWithPrefix: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Priority := tpLower;
  FSrcPath := ASrcPath;
  FOutPath := AOutPath;
  FBomSkip := ABomSkip;
  FOffsets := AOffsets;
  FFileSize := AFileSize;
  FRanges := ARanges;
  FWithPrefix := AWithPrefix;
  FLock := TCriticalSection.Create;
end;

destructor TFFPagedExportThread.Destroy;
begin
  Cancel;
  { TThread.Destroy espera o fim de Execute; so depois liberar o lock. }
  inherited Destroy;
  FLock.Free;
end;

procedure TFFPagedExportThread.Cancel;
begin
  FCancelled := True;
end;

function TFFPagedExportThread.Percent: Integer;
begin
  FLock.Enter;
  try
    if FDone then
      Result := 100
    else if FFileSize <= 0 then
      Result := 0
    else
      Result := Integer((FBytesPos * 100) div FFileSize);
  finally
    FLock.Leave;
  end;
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;

function TFFPagedExportThread.LinesWritten: Int64;
begin
  FLock.Enter;
  try
    Result := FLinesWritten;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedExportThread.IsDone: Boolean;
begin
  FLock.Enter;
  try
    Result := FDone;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedExportThread.ErrorText: string;
begin
  FLock.Enter;
  try
    Result := FError;
  finally
    FLock.Leave;
  end;
end;

function TFFPagedExportThread.WasCancelled: Boolean;
begin
  Result := FCancelled;
end;

procedure TFFPagedExportThread.Execute;
const
  cBufBytes = 1024 * 1024;
var
  InF, OutF: TStream;
  InBuf, OutBuf: array of Byte;
  InLen, InPos, OutLen, r: Integer;
  CurLine, BlkLine, Blk, Written: Int64;
  Positioned, AtEof, Wanted: Boolean;
  Prefix: AnsiString;
  Bom: array[0..3] of Byte;

  procedure FlushOut;
  begin
    if OutLen > 0 then
    begin
      OutF.WriteBuffer(OutBuf[0], OutLen);
      OutLen := 0;
    end;
  end;

  procedure PutByte(B: Byte);
  begin
    if OutLen >= cBufBytes then
      FlushOut;
    OutBuf[OutLen] := B;
    Inc(OutLen);
  end;

  procedure PutAnsi(const S: AnsiString);
  var
    k: Integer;
  begin
    for k := 1 to Length(S) do
      PutByte(Byte(S[k]));
  end;

  function Refill: Boolean;
  begin
    InLen := InF.Read(InBuf[0], cBufBytes);
    InPos := 0;
    Result := InLen > 0;
    FLock.Enter;
    try
      FBytesPos := InF.Position;
    finally
      FLock.Leave;
    end;
  end;

  { Consome uma linha do ficheiro; copia os bytes para a saida se AWrite. }
  procedure ReadLine(AWrite: Boolean);
  var
    B: Byte;
  begin
    while True do
    begin
      if InPos >= InLen then
        if not Refill then
        begin
          AtEof := True;
          Exit;
        end;
      B := InBuf[InPos];
      Inc(InPos);
      if B = 10 then Exit;
      if B = 13 then
      begin
        if InPos >= InLen then
          if not Refill then
          begin
            AtEof := True;
            Exit;
          end;
        if InBuf[InPos] = 10 then
          Inc(InPos);
        Exit;
      end;
      if AWrite then
        PutByte(B);
    end;
  end;

  function KindTag(K: Byte): AnsiString;
  begin
    case K of
      1: Result := 'EDT';
      2: Result := 'INS';
      3: Result := 'DEL';
      4: Result := 'RPLALL';
      5: Result := 'UNDO';
    else
      Result := 'EQ';
    end;
  end;

begin
  InF := nil;
  OutF := nil;
  Written := 0;
  try
    try
      InF := TFFSharedReadStream.Create(FSrcPath);
      OutF := TFileStream.Create(FOutPath, fmCreate);
      SetLength(InBuf, cBufBytes);
      SetLength(OutBuf, cBufBytes);
      OutLen := 0;
      InLen := 0;
      InPos := 0;
      AtEof := False;
      if (FBomSkip > 0) and (FBomSkip <= Length(Bom)) then
      begin
        InF.Position := 0;
        if InF.Read(Bom[0], FBomSkip) = FBomSkip then
          OutF.WriteBuffer(Bom[0], FBomSkip);
      end;

      Positioned := False;
      CurLine := 0;
      for r := 0 to High(FRanges) do
      begin
        if FCancelled or AtEof then Break;
        Blk := (FRanges[r].First - 1) div cFFPagedLinesPerBlock;
        if Blk > High(FOffsets) then Blk := High(FOffsets);
        BlkLine := Blk * cFFPagedLinesPerBlock + 1;
        if (not Positioned) or (BlkLine > CurLine) then
        begin
          InF.Position := FOffsets[Blk];
          InLen := 0;
          InPos := 0;
          CurLine := BlkLine;
          Positioned := True;
        end;
        while (CurLine <= FRanges[r].Last) and (not AtEof) and (not FCancelled) do
        begin
          Wanted := CurLine >= FRanges[r].First;
          if Wanted and FWithPrefix then
          begin
            Prefix := AnsiString(IntToStr(CurLine)) + #9 + '[' + KindTag(FRanges[r].Kind) + ']' + #9;
            PutAnsi(Prefix);
          end;
          ReadLine(Wanted);
          if Wanted then
          begin
            PutByte(13);
            PutByte(10);
            Inc(Written);
            if (Written and $3FFF) = 0 then
            begin
              FLock.Enter;
              try
                FLinesWritten := Written;
              finally
                FLock.Leave;
              end;
            end;
          end;
          Inc(CurLine);
        end;
      end;
      FlushOut;
    except
      on E: Exception do
      begin
        FLock.Enter;
        try
          FError := E.Message;
        finally
          FLock.Leave;
        end;
      end;
    end;
  finally
    InF.Free;
    OutF.Free;
    if FCancelled or (ErrorText <> '') then
      DeleteFile(FOutPath);
    FLock.Enter;
    try
      FLinesWritten := Written;
      FDone := True;
    finally
      FLock.Leave;
    end;
  end;
end;

end.
