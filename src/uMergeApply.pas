unit uMergeApply;

{
  Aplicacao do merge do "Diff entre dois arquivos" numa unica passagem, em thread.

  - Copia os bytes crus das linhas da origem (nunca o texto de exibicao, que pode
    estar truncado ou convertido); converte so' se as codificacoes forem diferentes.
  - So' reconstroi a regiao entre a primeira e a ultima linha alterada:
      linhas intactas entre alteracoes nao sao copiadas (so' as posicoes);
      ate' 64 MB a regravar -> escrita no proprio ficheiro (mesmo tamanho: instantaneo);
      caso geral          -> temporario na mesma pasta + ReplaceFile (troca atomica).
  - O diario de sessao e' gravado num unico append no fim.
}

{$POINTERMATH ON}
{$Q-}
{$R-}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  System.Generics.Collections, System.Generics.Defaults;

const
  cMaMsgProgress = 0;
  cMaMsgDone = 1;
  { SendMessage (sincrono) antes de trocar o ficheiro: quem o tiver aberto deve liberta'-lo. }
  cMaMsgRelease = 2;

type
  TMaKind = (makEdit, makDelete, makInsert);

  { TgtLine/SrcLine: 1-based, absolutos. Insert: inserir antes de TgtLine (alem do EOF = anexar). }
  TMaOp = record
    Kind: TMaKind;
    TgtLine: Int64;
    SrcLine: Int64;
    Seq: Integer;
  end;

  TMergeApplyThread = class(TThread)
  private
    FSrcPath, FTgtPath, FSpillDir: string;
    FSrcEnc, FTgtEnc: string;
    FSrcTerm, FTgtTerm: Byte;
    FTgtEol: RawByteString;
    FOps: TArray<TMaOp>;
    FValid: TArray<Boolean>;
    FNewBytes: TArray<RawByteString>;
    FOldBytes: TArray<RawByteString>;
    FWnd: HWND;
    FMsg: UINT;
    FSucceeded: Boolean;
    FCancelled: Boolean;
    FErrorMsg: string;
    FMissing: Integer;
    FApplied: Integer;
    FLastPermille: Integer;
    FBytesDone: Int64;
    FBytesTotal: Int64;
    FPhaseMs: array[0..3] of Cardinal;
    FMode: string;
    FCancelPoll: TFunc<Boolean>;
    FSameLayout: Boolean;
    function Stopped: Boolean;
    procedure Progress(APermille: Integer);
    procedure LoadSourceLines;
    procedure BuildAndCommit;
    procedure WriteJournal;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASrcPath, ATgtPath, ASpillDir, ASrcEnc, ATgtEnc: string;
      ASrcTerm, ATgtTerm: Byte; const ATgtEol: RawByteString; const AOps: TArray<TMaOp>;
      AWnd: HWND; AMsg: UINT);
    property Succeeded: Boolean read FSucceeded;
    property Cancelled: Boolean read FCancelled;
    property ErrorMsg: string read FErrorMsg;
    property MissingLines: Integer read FMissing;
    property AppliedCount: Integer read FApplied;
    { So' edicoes com o mesmo numero de bytes: offsets das linhas (indice) continuam validos. }
    property SameLayout: Boolean read FSameLayout;
    property BytesDone: Int64 read FBytesDone;
    property BytesTotal: Int64 read FBytesTotal;
    { Consultado pela propria thread (a cada bloco de 8 MB): cancela sem depender da UI. }
    property CancelPoll: TFunc<Boolean> read FCancelPoll write FCancelPoll;
    { Diagnostico: ms por fase (origem, varrimento do destino, gravacao, diario) e modo usado. }
    function TimingText: string;
  end;

  EMaNoDiskSpace = class(Exception)
  public
    Needed, FreeBytes: Int64;
  end;
  EMaFileChanged = class(Exception);

implementation

uses
  uTextEncoding, uFileSessionHistory;

const
  cMaReadBuf = 8 * 1024 * 1024;
  cMaCopyBuf = 8 * 1024 * 1024;
  cMaInPlaceTail = Int64(64) * 1024 * 1024;
  cMaExcerptBytes = 1024;
  cMaReplaceIgnoreMergeErrors = $00000002;

function MaFindByte(P: PByte; Len: NativeInt; B: Byte): NativeInt;
const
  cLo = UInt64($0101010101010101);
  cHi = UInt64($8080808080808080);
var
  i: NativeInt;
  Pat, W: UInt64;
begin
  i := 0;
  Pat := cLo * B;
  while i + 8 <= Len do
  begin
    W := PUInt64(P + i)^ xor Pat;
    if ((W - cLo) and (not W) and cHi) <> 0 then
      Break;
    Inc(i, 8);
  end;
  while i < Len do
  begin
    if P[i] = B then
      Exit(i);
    Inc(i);
  end;
  Result := -1;
end;

function MaOpenRead(const APath: string): THandle;
begin
  Result := CreateFile(PChar(APath), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if Result = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
end;

procedure MaSeek(H: THandle; AOfs: Int64);
var
  Hi: Longint;
begin
  Hi := Longint(AOfs shr 32);
  if (SetFilePointer(H, Longint(AOfs and $FFFFFFFF), @Hi, FILE_BEGIN) = DWORD($FFFFFFFF)) and
     (GetLastError <> NO_ERROR) then
    RaiseLastOSError;
end;

function MaRaw(const S: RawByteString): RawByteString;
begin
  Result := S;
  if Result <> '' then
    SetCodePage(Result, DefaultSystemCodePage, False);
end;

procedure MaWriteAll(H: THandle; P: PByte; Len: NativeInt);
var
  Chunk, Got: DWORD;
begin
  while Len > 0 do
  begin
    Chunk := DWORD(Min(Len, NativeInt(64 * 1024 * 1024)));
    if not WriteFile(H, P^, Chunk, Got, nil) then
      RaiseLastOSError;
    if Got = 0 then
      RaiseLastOSError;
    Inc(P, Got);
    Dec(Len, Got);
  end;
end;

function MaReadAll(H: THandle; P: PByte; Len: NativeInt): NativeInt;
var
  Chunk, Got: DWORD;
begin
  Result := 0;
  while Len > 0 do
  begin
    Chunk := DWORD(Min(Len, NativeInt(64 * 1024 * 1024)));
    if not ReadFile(H, P^, Chunk, Got, nil) then
      RaiseLastOSError;
    if Got = 0 then
      Break;
    Inc(P, Got);
    Inc(Result, Got);
    Dec(Len, Got);
  end;
end;

procedure MaFileStamp(H: THandle; out ASize: Int64; out ATime: Int64);
var
  FI: TByHandleFileInformation;
begin
  if not GetFileInformationByHandle(H, FI) then
    RaiseLastOSError;
  ASize := Int64(FI.nFileSizeHigh) shl 32 or FI.nFileSizeLow;
  ATime := Int64(FI.ftLastWriteTime.dwHighDateTime) shl 32 or FI.ftLastWriteTime.dwLowDateTime;
end;

function MaLastByte(H: THandle; ASize: Int64): Integer;
var
  B: Byte;
begin
  Result := -1;
  if ASize <= 0 then Exit;
  MaSeek(H, ASize - 1);
  if MaReadAll(H, @B, 1) = 1 then
    Result := B;
end;

function MaBomLen(H: THandle): Integer;
var
  B: array[0..2] of Byte;
begin
  Result := 0;
  MaSeek(H, 0);
  if (MaReadAll(H, @B[0], 3) = 3) and (B[0] = $EF) and (B[1] = $BB) and (B[2] = $BF) then
    Result := 3;
end;

function MaEncKey(const S: string): string;
begin
  Result := UpperCase(Trim(StringReplace(S, '(BOM)', '', [rfIgnoreCase])));
end;

type
  TMaLineReader = class
  private
    FH: THandle;
    FBuf: TBytes;
    FPos, FLen: NativeInt;
    FBufOfs: Int64;
    FEof: Boolean;
    FPartial: Boolean;
    FTerm: Byte;
    procedure Fill;
  public
    constructor Create(AH: THandle; AStartOfs: Int64; ATerm: Byte);
    function Offset: Int64;
    { Linha seguinte (Len inclui o terminador). P so' e' valido ate' a proxima chamada. }
    function NextLine(out P: PByte; out Len: NativeInt; out HasTerm: Boolean): Boolean;
    { Salta N linhas; devolve quantas saltou (menos que N = EOF). ACheck=False interrompe. }
    function SkipLines(N: Int64; const ACheck: TFunc<Int64, Boolean>): Int64;
  end;

constructor TMaLineReader.Create(AH: THandle; AStartOfs: Int64; ATerm: Byte);
begin
  inherited Create;
  FH := AH;
  FTerm := ATerm;
  SetLength(FBuf, cMaReadBuf);
  FBufOfs := AStartOfs;
  MaSeek(FH, AStartOfs);
end;

procedure TMaLineReader.Fill;
var
  Got: DWORD;
begin
  if FPos > 0 then
  begin
    if FLen > FPos then
      Move(FBuf[FPos], FBuf[0], FLen - FPos);
    Inc(FBufOfs, FPos);
    Dec(FLen, FPos);
    FPos := 0;
  end;
  if FLen >= Length(FBuf) then
    SetLength(FBuf, Length(FBuf) * 2);
  if not ReadFile(FH, FBuf[FLen], DWORD(Length(FBuf) - FLen), Got, nil) then
    RaiseLastOSError;
  if Got = 0 then
    FEof := True;
  Inc(FLen, Got);
end;

function TMaLineReader.Offset: Int64;
begin
  Result := FBufOfs + FPos;
end;

function TMaLineReader.NextLine(out P: PByte; out Len: NativeInt; out HasTerm: Boolean): Boolean;
var
  Idx, From: NativeInt;
begin
  From := 0;
  while True do
  begin
    Idx := MaFindByte(@FBuf[FPos + From], FLen - FPos - From, FTerm);
    if Idx >= 0 then
    begin
      P := @FBuf[FPos];
      Len := From + Idx + 1;
      HasTerm := True;
      Inc(FPos, Len);
      Exit(True);
    end;
    if FEof then
    begin
      if FPos < FLen then
      begin
        P := @FBuf[FPos];
        Len := FLen - FPos;
        HasTerm := False;
        FPos := FLen;
        Exit(True);
      end;
      Exit(False);
    end;
    From := FLen - FPos;
    Fill;
  end;
end;

function TMaLineReader.SkipLines(N: Int64; const ACheck: TFunc<Int64, Boolean>): Int64;
var
  Idx: NativeInt;
begin
  Result := 0;
  while Result < N do
  begin
    Idx := MaFindByte(@FBuf[FPos], FLen - FPos, FTerm);
    if Idx >= 0 then
    begin
      Inc(FPos, Idx + 1);
      FPartial := False;
      Inc(Result);
      Continue;
    end;
    if FEof then
    begin
      if (FPos < FLen) or FPartial then
      begin
        FPos := FLen;
        FPartial := False;
        Inc(Result);
      end;
      Exit;
    end;
    if FLen > FPos then
      FPartial := True;
    FPos := FLen;
    Fill;
    if Assigned(ACheck) and not ACheck(Offset) then
      Exit;
  end;
end;

type
  { Troco da regiao reconstruida: bytes novos (FMem) ou trecho intacto do original. }
  TMaPiece = record
    Gap: Boolean;
    Ofs: Int64;
    Len: Int64;
  end;

  { Regiao reconstruida sem copiar as linhas intactas: guarda so' as posicoes delas. }
  TMaRegion = class
  private
    FMem: TBytes;
    FMemLen: NativeInt;
    FPieces: TArray<TMaPiece>;
    FCount: Integer;
    FSize: Int64;
    procedure AddPiece(AGap: Boolean; AOfs, ALen: Int64);
    function GetPiece(I: Integer): TMaPiece;
  public
    procedure Write(P: PByte; Len: NativeInt); overload;
    procedure Write(const S: RawByteString); overload;
    procedure Keep(AOfs, ALen: Int64);
    function MemPtr(AOfs: Int64): PByte;
    property Size: Int64 read FSize;
    property Count: Integer read FCount;
    property Pieces[I: Integer]: TMaPiece read GetPiece;
  end;

procedure TMaRegion.AddPiece(AGap: Boolean; AOfs, ALen: Int64);
begin
  if ALen <= 0 then Exit;
  Inc(FSize, ALen);
  if (FCount > 0) and (FPieces[FCount - 1].Gap = AGap) and
     (FPieces[FCount - 1].Ofs + FPieces[FCount - 1].Len = AOfs) then
  begin
    Inc(FPieces[FCount - 1].Len, ALen);
    Exit;
  end;
  if FCount >= Length(FPieces) then
    SetLength(FPieces, Max(64, FCount * 2));
  FPieces[FCount].Gap := AGap;
  FPieces[FCount].Ofs := AOfs;
  FPieces[FCount].Len := ALen;
  Inc(FCount);
end;

function TMaRegion.GetPiece(I: Integer): TMaPiece;
begin
  Result := FPieces[I];
end;

procedure TMaRegion.Write(P: PByte; Len: NativeInt);
begin
  if Len <= 0 then Exit;
  if FMemLen + Len > Length(FMem) then
    SetLength(FMem, Max(Max(NativeInt(Length(FMem)) * 2, FMemLen + Len), NativeInt(1024 * 1024)));
  Move(P^, FMem[FMemLen], Len);
  AddPiece(False, FMemLen, Len);
  Inc(FMemLen, Len);
end;

procedure TMaRegion.Write(const S: RawByteString);
begin
  if S <> '' then
    Write(PByte(Pointer(S)), Length(S));
end;

procedure TMaRegion.Keep(AOfs, ALen: Int64);
begin
  AddPiece(True, AOfs, ALen);
end;

function TMaRegion.MemPtr(AOfs: Int64): PByte;
begin
  Result := @FMem[AOfs];
end;

{ TMergeApplyThread }

constructor TMergeApplyThread.Create(const ASrcPath, ATgtPath, ASpillDir, ASrcEnc,
  ATgtEnc: string; ASrcTerm, ATgtTerm: Byte; const ATgtEol: RawByteString;
  const AOps: TArray<TMaOp>; AWnd: HWND; AMsg: UINT);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSrcPath := ASrcPath;
  FTgtPath := ATgtPath;
  FSpillDir := ASpillDir;
  FSrcEnc := ASrcEnc;
  FTgtEnc := ATgtEnc;
  FSrcTerm := ASrcTerm;
  FTgtTerm := ATgtTerm;
  FTgtEol := ATgtEol;
  FOps := Copy(AOps);
  FWnd := AWnd;
  FMsg := AMsg;
  FLastPermille := -1;
end;

function TMergeApplyThread.Stopped: Boolean;
begin
  if not Terminated and Assigned(FCancelPoll) and FCancelPoll() then
    Terminate;
  Result := Terminated;
end;

procedure TMergeApplyThread.Progress(APermille: Integer);
begin
  APermille := EnsureRange(APermille, 0, 1000);
  if APermille - FLastPermille < 3 then Exit;
  FLastPermille := APermille;
  PostMessage(FWnd, FMsg, cMaMsgProgress, APermille);
end;

procedure TMergeApplyThread.LoadSourceLines;
var
  Order: TArray<Integer>;
  H: THandle;
  R: TMaLineReader;
  i, k, n: Integer;
  Cur, L, SrcSize, LastLine: Int64;
  LastBytes: RawByteString;
  P: PByte;
  Len: NativeInt;
  HasTerm, Convert: Boolean;
  S: RawByteString;
  Tm: Int64;
  Check: TFunc<Int64, Boolean>;
begin
  n := 0;
  SetLength(Order, Length(FOps));
  for i := 0 to High(FOps) do
    if FOps[i].Kind <> makDelete then
    begin
      Order[n] := i;
      Inc(n);
    end;
  SetLength(Order, n);
  if n = 0 then Exit;
  TArray.Sort<Integer>(Order, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := CompareValue(FOps[A].SrcLine, FOps[B].SrcLine);
    end));
  Convert := (FSrcEnc <> '') and (FTgtEnc <> '') and (MaEncKey(FSrcEnc) <> MaEncKey(FTgtEnc));
  H := MaOpenRead(FSrcPath);
  try
    MaFileStamp(H, SrcSize, Tm);
    SrcSize := Max(Int64(1), SrcSize);
    R := TMaLineReader.Create(H, MaBomLen(H), FSrcTerm);
    try
      Check :=
        function(AOfs: Int64): Boolean
        begin
          Progress(Integer(AOfs * 250 div SrcSize));
          Result := not Stopped;
        end;
      Cur := 1;
      LastLine := 0;
      for k := 0 to n - 1 do
      begin
        if Stopped then Exit;
        i := Order[k];
        L := FOps[i].SrcLine;
        if L < 1 then
        begin
          FValid[i] := False;
          Continue;
        end;
        if L = LastLine then
        begin
          FNewBytes[i] := LastBytes;
          Continue;
        end;
        if L > Cur then
          Inc(Cur, R.SkipLines(L - Cur, Check));
        if Stopped then Exit;
        if (Cur <> L) or not R.NextLine(P, Len, HasTerm) then
        begin
          FValid[i] := False;
          Continue;
        end;
        Inc(Cur);
        if HasTerm then
        begin
          Dec(Len);
          if (FSrcTerm = 10) and (Len > 0) and (P[Len - 1] = 13) then
            Dec(Len);
        end
        else if (Len > 0) and (P[Len - 1] = 13) then
          Dec(Len);
        SetString(S, PAnsiChar(P), Len);
        S := MaRaw(S);
        if Convert then
          S := MaRaw(RawByteString(UnicodeTextToFileBytes(
            DisplayTextFromFileBytes(AnsiString(S), FSrcEnc), FTgtEnc)));
        FNewBytes[i] := S;
        LastLine := L;
        LastBytes := S;
        Progress(Integer(R.Offset * 250 div SrcSize));
      end;
    finally
      R.Free;
    end;
  finally
    CloseHandle(H);
  end;
end;

procedure TMergeApplyThread.BuildAndCommit;
var
  H, HW, HT: THandle;
  R: TMaLineReader;
  Region: TMaRegion;
  n, i: Integer;
  Cur, L, Sz0, Tm0, Sz1, Tm1, FirstChange, PrefixEnd, OldLen, NewLen, Tail, Delta,
    Need, Done, TotalCopy: Int64;
  P: PByte;
  Len: NativeInt;
  HasTerm, AtEof, PendingEol, EndsWithTerm: Boolean;
  TailBuf, Buf: TBytes;
  FreeAvail, TotalB: Int64;
  BomLen: Integer;
  TmpPath, Dir: string;
  Check, CopyCheck: TFunc<Int64, Boolean>;

  procedure EmitNew(AIdx: Integer; AWithEol: Boolean);
  begin
    if PendingEol then
    begin
      Region.Write(FTgtEol);
      PendingEol := False;
    end;
    Region.Write(FNewBytes[AIdx]);
    if AWithEol then
      Region.Write(FTgtEol)
    else
      PendingEol := True;
    Inc(FApplied);
  end;

  procedure KeepOld(AIdx: Integer);
  var
    k: NativeInt;
  begin
    k := Len;
    if HasTerm then Dec(k);
    if (k > 0) and (P[k - 1] = 13) then Dec(k);
    if k > cMaExcerptBytes then k := cMaExcerptBytes;
    SetString(FOldBytes[AIdx], PAnsiChar(P), k);
    FOldBytes[AIdx] := MaRaw(FOldBytes[AIdx]);
  end;

  procedure CopyRange(ASrc, ADst: THandle; AFrom, ACount: Int64);
  var
    Got: NativeInt;
  begin
    if ACount <= 0 then Exit;
    MaSeek(ASrc, AFrom);
    while ACount > 0 do
    begin
      if Stopped then Exit;
      Got := MaReadAll(ASrc, @Buf[0], Min(ACount, Int64(Length(Buf))));
      if Got <= 0 then
        raise EInOutError.Create('Unexpected end of file');
      MaWriteAll(ADst, @Buf[0], Got);
      Dec(ACount, Got);
      CopyCheck(Got);
    end;
  end;

  procedure CheckUnchanged(AH: THandle);
  begin
    MaFileStamp(AH, Sz1, Tm1);
    if (Sz1 <> Sz0) or (Tm1 <> Tm0) then
      raise EMaFileChanged.Create('');
  end;

var
  E: EMaNoDiskSpace;
  Replaced: Boolean;
  Tries, k: Integer;
  t0: Cardinal;
  GapStart, Moved, Cost, Dst, MPos: Int64;
  Pc: TMaPiece;
begin
  n := Length(FOps);
  t0 := GetTickCount;
  FSameLayout := True;
  Region := TMaRegion.Create;
  try
    H := MaOpenRead(FTgtPath);
    try
      MaFileStamp(H, Sz0, Tm0);
      EndsWithTerm := MaLastByte(H, Sz0) = FTgtTerm;
      BomLen := MaBomLen(H);
      R := TMaLineReader.Create(H, BomLen, FTgtTerm);
      try
        Check :=
          function(AOfs: Int64): Boolean
          begin
            Progress(250 + Integer(AOfs * 250 div Max(Int64(1), Sz0)));
            Result := not Stopped;
          end;
        i := 0;
        while (i < n) and not FValid[i] do
          Inc(i);
        if i >= n then Exit;
        Cur := 1;
        if FOps[i].TgtLine > 1 then
          Inc(Cur, R.SkipLines(FOps[i].TgtLine - 1, Check));
        if Stopped then Exit;
        FirstChange := R.Offset;
        AtEof := False;
        { Tudo alem do EOF e a ultima linha (sem terminador) ficou antes da regiao. }
        PendingEol := (FirstChange >= Sz0) and (Sz0 > BomLen) and not EndsWithTerm;
        while i < n do
        begin
          if Stopped then Exit;
          if not FValid[i] then
          begin
            Inc(i);
            Continue;
          end;
          L := FOps[i].TgtLine;
          { Linhas intactas entre duas alteracoes: so' a posicao (SWAR, sem copiar bytes). }
          if (not AtEof) and (Cur < L) then
          begin
            GapStart := R.Offset;
            Inc(Cur, R.SkipLines(L - Cur, Check));
            if Stopped then Exit;
            Region.Keep(GapStart, R.Offset - GapStart);
            if (R.Offset >= Sz0) and (R.Offset > GapStart) and not EndsWithTerm then
              PendingEol := True;
            if Cur < L then
              AtEof := True;
          end;
          if AtEof then
          begin
            { Alem do fim: inserts anexam; edits/deletes apontam para linhas inexistentes. }
            if FOps[i].Kind = makInsert then
            begin
              FSameLayout := False;
              FOps[i].TgtLine := Cur;
              EmitNew(i, True);
            end
            else
            begin
              FValid[i] := False;
              Inc(FMissing);
            end;
            Inc(i);
            Continue;
          end;
          if FOps[i].Kind = makInsert then
          begin
            FSameLayout := False;
            EmitNew(i, True);
            Inc(i);
            Continue;
          end;
          if not R.NextLine(P, Len, HasTerm) then
          begin
            AtEof := True;
            Continue;
          end;
          Inc(Cur);
          KeepOld(i);
          if FOps[i].Kind = makEdit then
          begin
            if PendingEol or
               (Length(FNewBytes[i]) + Ord(HasTerm) * Length(FTgtEol) <> Len) then
              FSameLayout := False;
            EmitNew(i, HasTerm);
          end
          else
          begin
            FSameLayout := False;
            Inc(FApplied);
          end;
          Inc(i);
          { Mesmo destino repetido: so' a primeira alteracao conta. }
          while (i < n) and (FOps[i].Kind <> makInsert) and (FOps[i].TgtLine = L) do
          begin
            FValid[i] := False;
            Inc(i);
          end;
        end;
        if AtEof then
          PrefixEnd := Sz0
        else
          PrefixEnd := R.Offset;
      finally
        R.Free;
      end;
    finally
      CloseHandle(H);
    end;

    if FApplied = 0 then
    begin
      FSucceeded := FMissing = 0;
      Exit;
    end;
    if Stopped then Exit;

    FPhaseMs[1] := GetTickCount - t0;
    t0 := GetTickCount;
    NewLen := Region.Size;
    OldLen := PrefixEnd - FirstChange;
    Tail := Sz0 - PrefixEnd;
    Delta := NewLen - OldLen;
    SetLength(Buf, cMaCopyBuf);
    Progress(500);

    { Custo no proprio ficheiro: bytes novos + trechos intactos que mudam de posicao
      + cauda deslocada. Trechos que ficam no mesmo sitio nao sao regravados. }
    Moved := 0;
    Cost := 0;
    Dst := FirstChange;
    for k := 0 to Region.Count - 1 do
    begin
      Pc := Region.Pieces[k];
      if not Pc.Gap then
        Inc(Cost, Pc.Len)
      else if Pc.Ofs <> Dst then
        Inc(Moved, Pc.Len);
      Inc(Dst, Pc.Len);
    end;
    if Delta <> 0 then
      Inc(Moved, Tail);
    Inc(Cost, Moved);

    if Cost <= cMaInPlaceTail then
    begin
      HW := CreateFile(PChar(FTgtPath), GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL, 0);
      if HW = INVALID_HANDLE_VALUE then
        RaiseLastOSError;
      try
        CheckUnchanged(HW);
        { Le antes tudo o que muda de sitio: a escrita pode sobrepor-se a' origem. }
        SetLength(TailBuf, Moved);
        MPos := 0;
        Dst := FirstChange;
        for k := 0 to Region.Count - 1 do
        begin
          Pc := Region.Pieces[k];
          if Pc.Gap and (Pc.Ofs <> Dst) then
          begin
            MaSeek(HW, Pc.Ofs);
            if MaReadAll(HW, @TailBuf[MPos], Pc.Len) <> Pc.Len then
              raise EInOutError.Create('Read failed');
            Inc(MPos, Pc.Len);
          end;
          Inc(Dst, Pc.Len);
        end;
        if (Delta <> 0) and (Tail > 0) then
        begin
          MaSeek(HW, PrefixEnd);
          if MaReadAll(HW, @TailBuf[MPos], Tail) <> Tail then
            raise EInOutError.Create('Tail read failed');
        end;
        if Stopped then Exit;
        { A partir daqui nao ha' cancelamento: o ficheiro esta' a ser escrito (<= 64 MB). }
        MPos := 0;
        Dst := FirstChange;
        for k := 0 to Region.Count - 1 do
        begin
          Pc := Region.Pieces[k];
          if not Pc.Gap then
          begin
            MaSeek(HW, Dst);
            MaWriteAll(HW, Region.MemPtr(Pc.Ofs), Pc.Len);
          end
          else if Pc.Ofs <> Dst then
          begin
            MaSeek(HW, Dst);
            MaWriteAll(HW, @TailBuf[MPos], Pc.Len);
            Inc(MPos, Pc.Len);
          end;
          Inc(Dst, Pc.Len);
        end;
        if (Delta <> 0) and (Tail > 0) then
        begin
          MaSeek(HW, Dst);
          MaWriteAll(HW, @TailBuf[MPos], Tail);
        end;
        if Delta < 0 then
        begin
          MaSeek(HW, Sz0 + Delta);
          if not SetEndOfFile(HW) then
            RaiseLastOSError;
        end;
      finally
        CloseHandle(HW);
      end;
      if Delta = 0 then FMode := 'in-place' else FMode := 'tail-shift';
      FPhaseMs[2] := GetTickCount - t0;
      FSucceeded := True;
      Progress(1000);
      Exit;
    end;

    { Caso geral: temporario na mesma pasta (troca sem copia entre volumes). }
    Need := Sz0 + Delta;
    Dir := ExtractFilePath(ExpandFileName(FTgtPath));
    if GetDiskFreeSpaceEx(PChar(Dir), FreeAvail, TotalB, nil) and
       (FreeAvail < Need + Int64(64) * 1024 * 1024) then
    begin
      E := EMaNoDiskSpace.Create('');
      E.Needed := Need;
      E.FreeBytes := FreeAvail;
      raise E;
    end;
    TmpPath := Dir + '~' + ChangeFileExt(ExtractFileName(FTgtPath), '') +
      Format('.ffmerge_%x.tmp', [GetTickCount]);
    FBytesTotal := Need;
    FBytesDone := 0;
    Done := 0;
    TotalCopy := Max(Int64(1), Need);
    CopyCheck :=
      function(ADelta: Int64): Boolean
      begin
        Inc(Done, ADelta);
        FBytesDone := Done;
        Progress(500 + Integer(Done * 490 div TotalCopy));
        Result := not Stopped;
      end;
    HT := CreateFile(PChar(TmpPath), GENERIC_WRITE, 0, nil, CREATE_NEW,
      FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, 0);
    if HT = INVALID_HANDLE_VALUE then
      RaiseLastOSError;
    Replaced := False;
    try
      try
        { Reserva o espaco de uma vez: menos fragmentacao e falha cedo sem disco. }
        MaSeek(HT, Need);
        SetEndOfFile(HT);
        MaSeek(HT, 0);
        H := MaOpenRead(FTgtPath);
        try
          CheckUnchanged(H);
          CopyRange(H, HT, 0, FirstChange);
          for k := 0 to Region.Count - 1 do
          begin
            if Stopped then Exit;
            Pc := Region.Pieces[k];
            if Pc.Gap then
              CopyRange(H, HT, Pc.Ofs, Pc.Len)
            else
            begin
              MaWriteAll(HT, Region.MemPtr(Pc.Ofs), Pc.Len);
              CopyCheck(Pc.Len);
            end;
          end;
          if Stopped then Exit;
          CopyRange(H, HT, PrefixEnd, Tail);
          if Stopped then Exit;
          CheckUnchanged(H);
        finally
          CloseHandle(H);
        end;
      finally
        CloseHandle(HT);
      end;
      Progress(995);
      if Stopped then Exit;
      if FWnd <> 0 then
        SendMessage(FWnd, FMsg, cMaMsgRelease, LPARAM(Self));
      for Tries := 1 to 40 do
      begin
        { ReplaceFile preserva atributos/ACL/data de criacao do original. }
        if ReplaceFile(PChar(FTgtPath), PChar(TmpPath), nil,
             cMaReplaceIgnoreMergeErrors, nil, nil) or
           MoveFileEx(PChar(TmpPath), PChar(FTgtPath), MOVEFILE_REPLACE_EXISTING) then
        begin
          Replaced := True;
          Break;
        end;
        if Tries = 40 then
          RaiseLastOSError;
        { Original intacto: cancelar aqui so' descarta o temporario. }
        if Stopped then Exit;
        Sleep(100);
      end;
      FMode := 'temp-copy';
      FPhaseMs[2] := GetTickCount - t0;
      FSucceeded := True;
      Progress(1000);
    finally
      if not Replaced then
        DeleteFile(TmpPath);
    end;
  finally
    Region.Free;
  end;
end;

procedure TMergeApplyThread.WriteJournal;
var
  Lines: TStringList;
  i, j, k: Integer;
  Mx: Integer;

  function NewTxt(AIdx: Integer): string;
  begin
    Result := DisplayTextFromFileBytes(AnsiString(Copy(FNewBytes[AIdx], 1, cMaExcerptBytes)), FTgtEnc);
  end;

  function OldTxt(AIdx: Integer): string;
  begin
    Result := DisplayTextFromFileBytes(AnsiString(FOldBytes[AIdx]), FTgtEnc);
  end;

begin
  Mx := FFHistoryExcerptMax;
  Lines := TStringList.Create;
  try
    { Ordem descendente: cada numero de linha vale no estado do ficheiro naquele passo. }
    i := High(FOps);
    while i >= 0 do
    begin
      if not FValid[i] then
      begin
        Dec(i);
        Continue;
      end;
      case FOps[i].Kind of
        makEdit:
          begin
            Lines.Add('EDT|' + IntToStr(FOps[i].TgtLine) + '|' +
              FFHistorySanitizeField(OldTxt(i), Mx) + '|' + FFHistorySanitizeField(NewTxt(i), Mx));
            Dec(i);
          end;
        makDelete:
          begin
            j := i;
            while (j > 0) and FValid[j - 1] and (FOps[j - 1].Kind = makDelete) and
                  (FOps[j - 1].TgtLine = FOps[j].TgtLine - 1) do
              Dec(j);
            k := i - j + 1;
            if k = 1 then
              Lines.Add('DEL|' + IntToStr(FOps[i].TgtLine) + '|' +
                FFHistorySanitizeField(OldTxt(i), Mx) + '|')
            else
              Lines.Add('BDEL|' + IntToStr(FOps[j].TgtLine) + '|' + IntToStr(k) + '||');
            i := j - 1;
          end;
        makInsert:
          begin
            j := i;
            while (j > 0) and FValid[j - 1] and (FOps[j - 1].Kind = makInsert) and
                  (FOps[j - 1].TgtLine = FOps[i].TgtLine) do
              Dec(j);
            k := i - j + 1;
            if k = 1 then
              Lines.Add('INS|' + IntToStr(FOps[i].TgtLine) + '||' +
                FFHistorySanitizeField(NewTxt(i), Mx))
            else
              Lines.Add('BINS|' + IntToStr(FOps[i].TgtLine) + '|' + IntToStr(k) + '|' +
                FFHistorySanitizeField(NewTxt(j), 200) + '|' + FFHistorySanitizeField(NewTxt(i), 200));
            i := j - 1;
          end;
      end;
      if Stopped and (Lines.Count > 0) then
        Break;
    end;
    FFHistoryAppendOpLines(FTgtPath, Lines);
  finally
    Lines.Free;
  end;
end;

function TMergeApplyThread.TimingText: string;
begin
  Result := Format('src=%dms scan=%dms write=%dms(%s) journal=%dms',
    [FPhaseMs[0], FPhaseMs[1], FPhaseMs[2], FMode, FPhaseMs[3]]);
end;

procedure TMergeApplyThread.Execute;
var
  i: Integer;
  t0: Cardinal;
begin
  t0 := GetTickCount;
  try
    SetLength(FValid, Length(FOps));
    SetLength(FNewBytes, Length(FOps));
    SetLength(FOldBytes, Length(FOps));
    for i := 0 to High(FValid) do
      FValid[i] := True;
    { Mesmo destino: inserts antes da edicao/remocao da propria linha; depois ordem do diff. }
    TArray.Sort<TMaOp>(FOps, TComparer<TMaOp>.Construct(
      function(const A, B: TMaOp): Integer
      begin
        Result := CompareValue(A.TgtLine, B.TgtLine);
        if Result = 0 then
          Result := CompareValue(Ord(A.Kind <> makInsert), Ord(B.Kind <> makInsert));
        if Result = 0 then
          Result := CompareValue(A.Seq, B.Seq);
      end));
    Progress(0);
    LoadSourceLines;
    FPhaseMs[0] := GetTickCount - t0;
    for i := 0 to High(FOps) do
      if (not FValid[i]) and (FOps[i].Kind <> makDelete) then
        Inc(FMissing);
    if not Stopped then
      BuildAndCommit;
    t0 := GetTickCount;
    if FSucceeded and (FApplied > 0) then
    begin
      WriteJournal;
      FPhaseMs[3] := GetTickCount - t0;
    end
    else if Stopped and not FSucceeded then
      FCancelled := True;
  except
    on E: EMaNoDiskSpace do
    begin
      FSucceeded := False;
      FErrorMsg := Format('*space*|%d|%d', [E.Needed, E.FreeBytes]);
    end;
    on E: EMaFileChanged do
    begin
      FSucceeded := False;
      FErrorMsg := '*changed*';
    end;
    on E: Exception do
    begin
      FSucceeded := False;
      FErrorMsg := E.Message;
      if FErrorMsg = '' then
        FErrorMsg := E.ClassName;
    end;
  end;
  PostMessage(FWnd, FMsg, cMaMsgDone, LPARAM(Self));
end;

end.
