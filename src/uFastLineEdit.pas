unit uFastLineEdit;

{
  Edicao rapida de linhas em ficheiros grandes (inserir, substituir, apagar).

  Usa o indice de linhas ja existente (temp_ckpt.txt e, quando existe, temp.txt),
  validado por temp_index.meta (caminho, tamanho e data), para chegar a linha alvo
  lendo no maximo CKPT_INTERVAL linhas. Depois escolhe o modo mais barato:

  - femInPlace: o conteudo novo tem o mesmo tamanho e os terminadores nas mesmas
    posicoes; grava so esses bytes. Os indices continuam validos.
  - femShift: o sufixo (bytes depois da zona alterada) e no maximo metade do
    ficheiro; desloca-o dentro do proprio ficheiro, sem copiar o prefixo.
  - femRewrite: copia prefixo, conteudo novo e sufixo para um temporario no mesmo
    volume e renomeia por cima (o original fica intacto ate ao fim).

  femInPlace e femShift alteram o ficheiro original. Antes disso gravam um diario
  (.ffj em fastfile_temp) com os bytes originais da zona afetada ate ao fim; se a
  aplicacao cair a meio, RecoverInterruptedFastEdits (no arranque) repoe o original.

  Em femShift e femRewrite os indices sao reconstruidos na mesma passada: os
  registos antes da linha alvo sao copiados dos indices antigos e os restantes sao
  gerados por TLineIndexStreamBuilder a partir dos bytes que ja estao em memoria.
  Assim nao e preciso reindexar o ficheiro depois da edicao.
}

interface

uses
  Windows, SysUtils, Classes;

const
  { Abaixo disto o caminho completo de TEditFileThread ja e instantaneo. }
  FAST_EDIT_MIN_BYTES = Int64(32) * 1024 * 1024;

type
  TFastEditKind = (fekInsert, fekReplace, fekDelete);
  TFastEditMode = (femNone, femInPlace, femShift, femRewrite);

  EFastEditCancelled = class(Exception);

  TFastEditRequest = record
    FileName: string;
    Kind: TFastEditKind;
    { 1-based. Inserir: antes desta linha; < 1 ou alem do EOF = anexar no fim. }
    TargetLine: Int64;
    { Linhas antigas afetadas (apagar); substituir usa sempre 1. }
    SpanLines: Int64;
    { Bytes novos ja codificados, cada linha com o seu terminador. }
    Payload: RawByteString;
    TermByte: Byte;
  end;

  TFastEditResult = record
    Mode: TFastEditMode;
    { Substituir: False quando a linha alvo nao existe (nada foi alterado). }
    TargetExists: Boolean;
    { Linhas reais antes da edicao (sem a linha vazia apos o ultimo terminador). }
    ExistingLines: Int64;
    { Primeira linha afetada, sem terminador (texto antigo para historico/undo). }
    OldFirstLine: RawByteString;
    SizeBefore: Int64;
    SizeAfter: Int64;
    { Semantica do leitor (TReadFileThread): terminadores + 1. }
    LineCountAfter: Int64;
    { False: dados gravados mas os indices nao puderam ser substituidos (reindexar). }
    IndexReady: Boolean;
    LocateMs: Int64;
    DataMs: Int64;
  end;

  TFastEditProgress = reference to procedure(const ADone, ATotal: Int64);
  TFastEditShouldStop = reference to function: Boolean;

{ Devolve False sem alterar nada quando o caminho rapido nao se aplica (ficheiro
  pequeno, indice ausente ou desatualizado, linha a apagar inexistente); o chamador
  usa entao o caminho completo. Devolve True quando tratou o pedido.
  Levanta EFastEditCancelled se cancelado antes de alterar o ficheiro, e Exception
  em erro de E/S (o ficheiro fica intacto ou e reposto a partir do diario). }
function TryFastLineEdit(const AReq: TFastEditRequest; out ARes: TFastEditResult;
  const AShouldStop: TFastEditShouldStop; const AOnProgress: TFastEditProgress): Boolean;

type
  { Mesclar linhas: uma linha substituida por Payload (bytes novos com terminador). }
  TFastReplaceEntry = record
    Line: Int64;
    Payload: RawByteString;
  end;
  TFastReplaceEntries = TArray<TFastReplaceEntry>;

{ Substitui varias linhas numa so passada. AEntries ordenadas por Line, sem
  repetidos. Linhas alem do fim sao anexadas, precedidas de linhas vazias (AEol)
  ate ao numero pedido. Mesmo contrato de TryFastLineEdit. }
function TryFastMultiReplace(const AFileName: string; const ATermByte: Byte;
  const AEol: RawByteString; const AEntries: TFastReplaceEntries;
  out ARes: TFastEditResult; const AShouldStop: TFastEditShouldStop;
  const AOnProgress: TFastEditProgress): Boolean;

{ Repoe ficheiros cuja edicao no proprio ficheiro foi interrompida. Chamar no
  arranque, antes de abrir ficheiros. Devolve o numero de ficheiros repostos. }
function RecoverInterruptedFastEdits: Integer;

implementation

uses
  Math, System.Threading, UnConsts, UnBufferedTextWriter, uLineIndexScan, uFastFilePaths,
  UnUtils, ThreadFileLog;

const
  COPY_BLOCK_BYTES = 8 * 1024 * 1024;
  { ~CKPT_INTERVAL linhas tipicas; saltos curtos (mescla) nao leem 1 MB cada. }
  LOCATE_BLOCK_BYTES = 64 * 1024;
  OLD_LINE_CAPTURE_MAX = 16 * 1024 * 1024;
  IN_PLACE_MAX_BYTES = 64 * 1024 * 1024;
  FREE_SPACE_MARGIN = Int64(64) * 1024 * 1024;
  MAX_FAST_EDIT_LINES = Int64(1900000000);
  JOURNAL_MAGIC: array[0..3] of AnsiChar = 'FFJ1';
  JOURNAL_EXT = '.ffj';
  JOURNAL_STATE_OFFSET = 4;
  JOURNAL_STATE_WRITING = 0;
  JOURNAL_STATE_COMMITTED = 1;

type
  EFastEditNotApplicable = class(Exception);

  TLineLoc = record
    Offset0: Int64;
    TermsBefore: Int64;
  end;

  { Linha antiga [S, E) substituida por FEntries[Entry]. }
  TReplaceSpan = record
    S: Int64;
    E: Int64;
    Entry: Integer;
  end;

  TFastLineEditor = class
  private
    FReq: TFastEditRequest;
    FPath: string;
    FSize: Int64;
    FMetaLines: Int64;
    FCkptPath: string;
    FDensePath: string;
    FUseDense: Boolean;
    FCkptCount: Int64;
    FSrc: TFileStream;
    FCkpt: TFileStream;
    FBuf: TBytes;
    FBuf2: TBytes;
    FPending: ITask;
    FWriteError: string;
    FShouldStop: TFastEditShouldStop;
    FOnProgress: TFastEditProgress;
    FProgressDone: Int64;
    FProgressTotal: Int64;
    FCkptTmp: string;
    FDenseTmp: string;
    FCkptW: TBufferedTextWriter;
    FDenseW: TBufferedTextWriter;
    FBuilder: TLineIndexStreamBuilder;
    FJournalDataOffset: Int64;
    FEntries: TFastReplaceEntries;
    FSpans: TArray<TReplaceSpan>;
    FAppend: RawByteString;
    FFirstStart: Int64;
    procedure Validate;
    function ReadIndexRecord(AStream: TStream; const AIndex: Int64): Int64;
    function ReadByteAt(const AOffset: Int64): Byte;
    procedure SkipTerms(var AOff, ATerms: Int64; ANeed: Int64);
    function LocateLine(const ALine: Int64): TLineLoc;
    function LocateLineFrom(const AFrom: TLineLoc; const ALine: Int64): TLineLoc;
    function CaptureFirstLine(const AStart, AEnd: Int64): RawByteString;
    function SameTermLayout(const AStart: Int64): Boolean;
    function SameTermLayoutAt(const AStart: Int64; const APayload: RawByteString): Boolean;
    procedure WritePiece(ADst: TStream; const APiece: RawByteString; var AOutPos: Int64);
    procedure WriteStitched(ASrc: TStream; const AShift: Int64; ADst: TStream;
      const ACancellable: Boolean);
    procedure CheckStop;
    procedure Progress(const ABytes: Int64);
    procedure BeginIndexes(const ATermsBefore: Int64);
    procedure CopyIndexPrefix(const ASrcPath: string; const ARecords: Int64;
      AWriter: TBufferedTextWriter);
    function CommitIndexes: Boolean;
    procedure DiscardIndexes;
    procedure StartWrite(ADst: TStream; const APos: Int64; const ABuf: TBytes;
      const ALen: Integer);
    procedure WaitWrite;
    procedure WaitWriteQuiet;
    procedure CopyRange(ASrc: TStream; AFrom, ATo: Int64; ADst: TStream;
      const AFeedFrom, AFeedDelta: Int64; const ACancellable: Boolean);
    function NewJournalPath: string;
    function WriteJournal(const AStart, ABackupEnd, AFeedFrom, AFeedDelta: Int64): TFileStream;
    procedure ApplyShift(ATarget: TFileStream; const AStart, AEnd, ADelta: Int64);
    procedure RestoreFailedEdit(var AJournal, ATarget: TFileStream);
    procedure RunRewrite(const AStart, AEnd: Int64);
  public
    constructor Create(const AReq: TFastEditRequest;
      const AShouldStop: TFastEditShouldStop; const AOnProgress: TFastEditProgress);
    destructor Destroy; override;
    procedure Run(var ARes: TFastEditResult);
    procedure RunMulti(const AEntries: TFastReplaceEntries; const AEol: RawByteString;
      var ARes: TFastEditResult);
  end;

{ ============================================================================ }
{ Diario                                                                       }
{ ============================================================================ }

procedure WriteJournalHeader(AStream: TStream; const ATarget: string;
  const AStart, AOldSize: Int64);
var
  State, PathLen: Integer;
begin
  AStream.WriteBuffer(JOURNAL_MAGIC[0], 4);
  State := JOURNAL_STATE_WRITING;
  AStream.WriteBuffer(State, SizeOf(State));
  AStream.WriteBuffer(AStart, SizeOf(AStart));
  AStream.WriteBuffer(AOldSize, SizeOf(AOldSize));
  PathLen := Length(ATarget);
  AStream.WriteBuffer(PathLen, SizeOf(PathLen));
  if PathLen > 0 then
    AStream.WriteBuffer(ATarget[1], PathLen * SizeOf(Char));
end;

function ReadJournalHeader(AStream: TStream; out ATarget: string;
  out AStart, AOldSize: Int64; out AState: Integer): Boolean;
var
  Magic: array[0..3] of AnsiChar;
  PathLen: Integer;
begin
  Result := False;
  ATarget := '';
  AStart := 0;
  AOldSize := 0;
  AState := JOURNAL_STATE_WRITING;
  AStream.Position := 0;
  if AStream.Read(Magic[0], 4) <> 4 then Exit;
  if not CompareMem(@Magic[0], @JOURNAL_MAGIC[0], 4) then Exit;
  if AStream.Read(AState, SizeOf(AState)) <> SizeOf(AState) then Exit;
  if AStream.Read(AStart, SizeOf(AStart)) <> SizeOf(AStart) then Exit;
  if AStream.Read(AOldSize, SizeOf(AOldSize)) <> SizeOf(AOldSize) then Exit;
  if AStream.Read(PathLen, SizeOf(PathLen)) <> SizeOf(PathLen) then Exit;
  if (PathLen <= 0) or (PathLen > 32767) then Exit;
  SetLength(ATarget, PathLen);
  if AStream.Read(ATarget[1], PathLen * SizeOf(Char)) <> PathLen * SizeOf(Char) then Exit;
  Result := (AStart >= 0) and (AOldSize >= AStart);
end;

procedure SetJournalState(AStream: THandleStream; const AState: Integer);
begin
  AStream.Position := JOURNAL_STATE_OFFSET;
  AStream.WriteBuffer(AState, SizeOf(AState));
  FlushFileBuffers(AStream.Handle);
end;

{ AJournal posicionado no inicio dos dados (logo apos o cabecalho). }
procedure RestoreFromJournal(AJournal: TStream; const ATarget: string;
  const AStart, AOldSize: Int64);
var
  T: TFileStream;
  Buf: TBytes;
  N: Integer;
  Pos: Int64;
begin
  SetLength(Buf, COPY_BLOCK_BYTES);
  T := TFileStream.Create(ATarget, fmOpenReadWrite or fmShareDenyWrite);
  try
    Pos := AStart;
    while Pos < AOldSize do
    begin
      N := Integer(Min(Int64(COPY_BLOCK_BYTES), AOldSize - Pos));
      AJournal.ReadBuffer(Buf[0], N);
      T.Position := Pos;
      T.WriteBuffer(Buf[0], N);
      Inc(Pos, N);
    end;
    T.Size := AOldSize;
    FlushFileBuffers(T.Handle);
  finally
    T.Free;
  end;
end;

function RecoverInterruptedFastEdits: Integer;
var
  Dir, JPath, Target: string;
  SR: TSearchRec;
  J: TFileStream;
  Start, OldSize: Int64;
  State: Integer;
  Restored, Drop: Boolean;
begin
  Result := 0;
  Dir := FastFileTempDir;
  if not DirectoryExists(Dir) then Exit;
  if FindFirst(Dir + '*' + JOURNAL_EXT, faAnyFile, SR) <> 0 then Exit;
  try
    repeat
      if (SR.Attr and faDirectory) <> 0 then Continue;
      JPath := Dir + SR.Name;
      try
        { Exclusivo: um diario ainda aberto pertence a uma edicao em curso. }
        J := TFileStream.Create(JPath, fmOpenRead or fmShareExclusive);
      except
        Continue;
      end;
      Restored := False;
      Drop := True;
      try
        try
          if ReadJournalHeader(J, Target, Start, OldSize, State) and
             (State = JOURNAL_STATE_COMMITTED) then
          begin
            if FileExists(Target) then
            begin
              RestoreFromJournal(J, Target, Start, OldSize);
              Restored := True;
            end;
          end;
        except
          on E: Exception do
          begin
            Drop := False;
            LogAsync(FastFileRuntimeLogPath, Format('[EditFast] journal restore failed %s: %s',
              [JPath, E.Message]));
          end;
        end;
      finally
        J.Free;
      end;
      if Restored then
      begin
        Inc(Result);
        UnUtils.TryDeleteFileWithRetry(LineIndexCachePath, 6, 40);
        LogAsync(FastFileRuntimeLogPath, Format('[EditFast] restored %s from journal %s',
          [Target, JPath]));
      end;
      if Drop then
        UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
    until FindNext(SR) <> 0;
  finally
    SysUtils.FindClose(SR);
  end;
end;

{ ============================================================================ }
{ TFastLineEditor                                                              }
{ ============================================================================ }

constructor TFastLineEditor.Create(const AReq: TFastEditRequest;
  const AShouldStop: TFastEditShouldStop; const AOnProgress: TFastEditProgress);
begin
  inherited Create;
  FReq := AReq;
  FPath := ExpandFileName(AReq.FileName);
  FShouldStop := AShouldStop;
  FOnProgress := AOnProgress;
  SetLength(FBuf, COPY_BLOCK_BYTES);
  SetLength(FBuf2, COPY_BLOCK_BYTES);
end;

destructor TFastLineEditor.Destroy;
begin
  DiscardIndexes;
  FCkpt.Free;
  FSrc.Free;
  inherited;
end;

function TFastLineEditor.ReadIndexRecord(AStream: TStream; const AIndex: Int64): Int64;
var
  Rec: array[0..INDEX_RECORD_BYTES - 1] of AnsiChar;
  I: Integer;
  Any: Boolean;
begin
  AStream.Position := AIndex * INDEX_RECORD_BYTES;
  AStream.ReadBuffer(Rec[0], INDEX_RECORD_BYTES);
  Result := 0;
  Any := False;
  for I := 0 to INDEX_RECORD_BYTES - 3 do
    if Rec[I] in ['0'..'9'] then
    begin
      Result := Result * 10 + (Ord(Rec[I]) - Ord('0'));
      Any := True;
    end
    else if Rec[I] <> ' ' then
      raise EFastEditNotApplicable.Create('index record is not numeric');
  if not Any then
    raise EFastEditNotApplicable.Create('empty index record');
end;

function TFastLineEditor.ReadByteAt(const AOffset: Int64): Byte;
begin
  FSrc.Position := AOffset;
  FSrc.ReadBuffer(Result, 1);
end;

procedure TFastLineEditor.Validate;
var
  Wt: TFileTime;
  CkptSize, DenseSize: Int64;
begin
  if not FileExists(FPath) then
    raise EFastEditNotApplicable.Create('file not found');
  UnUtils.GetFileSizeAndWriteTime(FPath, FSize, Wt);
  if FSize < FAST_EDIT_MIN_BYTES then
    raise EFastEditNotApplicable.Create('small file');
  if not ReadLineIndexMetaFile(LineIndexCachePath, FPath, FSize, Wt, FMetaLines) then
    raise EFastEditNotApplicable.Create('line index meta does not match the file');
  if (FMetaLines < 1) or (FMetaLines > MAX_FAST_EDIT_LINES) then
    raise EFastEditNotApplicable.Create('line count out of range');
  { Indice de blocos do Zero Scan nao e reconstruido aqui. }
  if FileExists(FastFileExeDirPath(TEMP_ZERO_SCAN_BLOCK_IDX)) then
    raise EFastEditNotApplicable.Create('zero scan block index present');

  FCkptPath := FastFileExeDirPath(TEMP_CKPT_FILE);
  if not FileExists(FCkptPath) then
    raise EFastEditNotApplicable.Create('checkpoint index missing');
  CkptSize := UnUtils.GetFileSize(FCkptPath);
  FCkptCount := CkptSize div INDEX_RECORD_BYTES;
  if (CkptSize mod INDEX_RECORD_BYTES <> 0) or
     (FCkptCount <> 1 + (FMetaLines - 1) div CKPT_INTERVAL) then
    raise EFastEditNotApplicable.Create('checkpoint index size mismatch');

  FDensePath := FastFileExeDirPath(TEMPFILE);
  FUseDense := FileExists(FDensePath);
  if FUseDense then
  begin
    DenseSize := UnUtils.GetFileSize(FDensePath);
    if DenseSize <> FMetaLines * INDEX_RECORD_BYTES then
      raise EFastEditNotApplicable.Create('dense index size mismatch');
  end;

  FSrc := TFileStream.Create(FPath, fmOpenRead or fmShareDenyNone);
  FCkpt := TFileStream.Create(FCkptPath, fmOpenRead or fmShareDenyNone);
  if ReadIndexRecord(FCkpt, 0) <> 1 then
    raise EFastEditNotApplicable.Create('checkpoint index does not start at 1');
end;

{ Inicio da linha ALine: salta pelo checkpoint e conta no maximo CKPT_INTERVAL - 1
  terminadores. Alem do EOF devolve Offset0 = FSize e o total de terminadores. }
function TFastLineEditor.LocateLine(const ALine: Int64): TLineLoc;
var
  L, K: Int64;
begin
  L := Max(ALine, Int64(1));
  K := (L - 1) div CKPT_INTERVAL;
  if K > FCkptCount - 1 then
    K := FCkptCount - 1;
  Result.Offset0 := ReadIndexRecord(FCkpt, K) - 1;
  Result.TermsBefore := K * CKPT_INTERVAL;
  if (Result.Offset0 < 0) or (Result.Offset0 > FSize) then
    raise EFastEditNotApplicable.Create('checkpoint offset out of range');
  if (Result.Offset0 > 0) and (ReadByteAt(Result.Offset0 - 1) <> FReq.TermByte) then
    raise EFastEditNotApplicable.Create('checkpoint offset is not a line start');
  SkipTerms(Result.Offset0, Result.TermsBefore, L - 1 - Result.TermsBefore);
end;

{ Avanca AOff para depois de ANeed terminadores (ou ate FSize). }
procedure TFastLineEditor.SkipTerms(var AOff, ATerms: Int64; ANeed: Int64);
var
  N, I: Integer;
  Term: Byte;
begin
  Term := FReq.TermByte;
  while (ANeed > 0) and (AOff < FSize) do
  begin
    N := Integer(Min(Int64(LOCATE_BLOCK_BYTES), FSize - AOff));
    FSrc.Position := AOff;
    FSrc.ReadBuffer(FBuf[0], N);
    I := 0;
    while I < N do
    begin
      if FBuf[I] = Term then
      begin
        Inc(ATerms);
        Dec(ANeed);
        if ANeed = 0 then
        begin
          AOff := AOff + I + 1;
          Exit;
        end;
      end;
      Inc(I);
    end;
    Inc(AOff, N);
  end;
end;

{ Como LocateLine, mas continua a partir de AFrom (linha anterior ja localizada)
  quando nenhum checkpoint fica mais perto da linha pedida. }
function TFastLineEditor.LocateLineFrom(const AFrom: TLineLoc; const ALine: Int64): TLineLoc;
begin
  if (ALine - 1 < AFrom.TermsBefore) or
     (((ALine - 1) div CKPT_INTERVAL) * CKPT_INTERVAL > AFrom.TermsBefore) then
    Exit(LocateLine(ALine));
  Result := AFrom;
  SkipTerms(Result.Offset0, Result.TermsBefore, ALine - 1 - AFrom.TermsBefore);
end;

function TFastLineEditor.CaptureFirstLine(const AStart, AEnd: Int64): RawByteString;
var
  Len, I: Integer;
begin
  Len := Integer(Min(AEnd - AStart, Int64(OLD_LINE_CAPTURE_MAX)));
  SetLength(Result, Len);
  if Len = 0 then Exit;
  FSrc.Position := AStart;
  FSrc.ReadBuffer(Result[1], Len);
  for I := 1 to Len do
    if Byte(Result[I]) = FReq.TermByte then
    begin
      SetLength(Result, I - 1);
      Break;
    end;
  while (Length(Result) > 0) and (Result[Length(Result)] in [#10, #13]) do
    SetLength(Result, Length(Result) - 1);
end;

{ Bytes antigos em [AStart, AStart + Length(Payload)) com terminadores nas mesmas
  posicoes que o conteudo novo: os inicios de linha nao mudam. }
function TFastLineEditor.SameTermLayout(const AStart: Int64): Boolean;
begin
  Result := SameTermLayoutAt(AStart, FReq.Payload);
end;

function TFastLineEditor.SameTermLayoutAt(const AStart: Int64;
  const APayload: RawByteString): Boolean;
var
  Old: TBytes;
  Len, I: Integer;
  Term: Byte;
  P: PByte;
begin
  Result := False;
  Len := Length(APayload);
  if (Len = 0) or (Len > IN_PLACE_MAX_BYTES) then Exit;
  SetLength(Old, Len);
  FSrc.Position := AStart;
  FSrc.ReadBuffer(Old[0], Len);
  Term := FReq.TermByte;
  P := PByte(PAnsiChar(APayload));
  for I := 0 to Len - 1 do
    if (Old[I] = Term) <> (P[I] = Term) then
      Exit;
  Result := True;
end;

procedure TFastLineEditor.CheckStop;
begin
  if Assigned(FShouldStop) and FShouldStop then
    raise EFastEditCancelled.Create('cancelled');
end;

procedure TFastLineEditor.Progress(const ABytes: Int64);
begin
  Inc(FProgressDone, ABytes);
  if Assigned(FOnProgress) and (FProgressTotal > 0) then
    FOnProgress(Min(FProgressDone, FProgressTotal), FProgressTotal);
end;

procedure TFastLineEditor.CopyIndexPrefix(const ASrcPath: string; const ARecords: Int64;
  AWriter: TBufferedTextWriter);
var
  S: TFileStream;
  Left: Int64;
  N: Integer;
begin
  S := TFileStream.Create(ASrcPath, fmOpenRead or fmShareDenyNone);
  try
    Left := ARecords * INDEX_RECORD_BYTES;
    if S.Size < Left then
      raise EFastEditNotApplicable.Create('index shorter than expected');
    while Left > 0 do
    begin
      N := Integer(Min(Int64(COPY_BLOCK_BYTES), Left));
      S.ReadBuffer(FBuf[0], N);
      AWriter.WriteRaw(@FBuf[0], N);
      Dec(Left, N);
    end;
  finally
    S.Free;
  end;
end;

{ Registos que nao mudam: checkpoint ate a linha ATermsBefore + 1 e, no denso,
  todas as linhas ate essa. O resto vem do TLineIndexStreamBuilder. }
procedure TFastLineEditor.BeginIndexes(const ATermsBefore: Int64);
var
  Bundle: TLineIndexWriterBundle;
begin
  FCkptTmp := FCkptPath + '.edit';
  UnUtils.TryDeleteFileWithRetry(FCkptTmp, 4, 30);
  FCkptW := TBufferedTextWriter.Create(FCkptTmp, 2 * 1024 * 1024);
  CopyIndexPrefix(FCkptPath, ATermsBefore div CKPT_INTERVAL + 1, FCkptW);
  if FUseDense then
  begin
    FDenseTmp := FDensePath + '.edit';
    UnUtils.TryDeleteFileWithRetry(FDenseTmp, 4, 30);
    FDenseW := TBufferedTextWriter.Create(FDenseTmp, 8 * 1024 * 1024);
    CopyIndexPrefix(FDensePath, ATermsBefore + 1, FDenseW);
  end;
  Bundle.IdxW := FDenseW;
  Bundle.CkptW := FCkptW;
  Bundle.BlkW := nil;
  Bundle.SparseCkptOnly := not FUseDense;
  FBuilder := TLineIndexStreamBuilder.Create(Bundle, ATermsBefore, FReq.TermByte);
end;

procedure TFastLineEditor.DiscardIndexes;
begin
  FreeAndNil(FBuilder);
  FreeAndNil(FCkptW);
  FreeAndNil(FDenseW);
  if FCkptTmp <> '' then
    UnUtils.TryDeleteFileWithRetry(FCkptTmp, 4, 30);
  if FDenseTmp <> '' then
    UnUtils.TryDeleteFileWithRetry(FDenseTmp, 4, 30);
  FCkptTmp := '';
  FDenseTmp := '';
end;

function TFastLineEditor.CommitIndexes: Boolean;
var
  Err: string;
begin
  FreeAndNil(FBuilder);
  FreeAndNil(FCkptW);
  FreeAndNil(FDenseW);
  FreeAndNil(FCkpt);
  Result := UnUtils.TryRenameTempOverTarget(FCkptTmp, FCkptPath, Err);
  if Result then
    FCkptTmp := ''
  else
    LogAsync(FastFileRuntimeLogPath, '[EditFast] checkpoint replace failed: ' + Err);
  if Result and FUseDense then
  begin
    Result := UnUtils.TryRenameTempOverTarget(FDenseTmp, FDensePath, Err);
    if Result then
      FDenseTmp := ''
    else
      LogAsync(FastFileRuntimeLogPath, '[EditFast] dense index replace failed: ' + Err);
  end;
  if not Result then
  begin
    DiscardIndexes;
    UnUtils.TryDeleteFileWithRetry(FCkptPath, 6, 40);
    if FUseDense then
      UnUtils.TryDeleteFileWithRetry(FDensePath, 6, 40);
  end;
end;

{ Copia [AFrom, ATo) de ASrc para ADst (posicao atual de ADst). Bytes a partir de
  AFeedFrom alimentam o indice com offset de saida = offset de origem + AFeedDelta. }
{ Escrita de um bloco noutra thread, para ler o bloco seguinte ao mesmo tempo.
  APos < 0 = posicao atual de ADst. ADst nao pode ser usado ate WaitWrite. }
procedure TFastLineEditor.StartWrite(ADst: TStream; const APos: Int64; const ABuf: TBytes;
  const ALen: Integer);
begin
  FPending := TTask.Run(
    procedure
    begin
      try
        if APos >= 0 then
          ADst.Position := APos;
        ADst.WriteBuffer(ABuf[0], ALen);
      except
        on E: Exception do
          FWriteError := E.Message;
      end;
    end);
end;

procedure TFastLineEditor.WaitWrite;
begin
  if FPending = nil then Exit;
  FPending.Wait;
  FPending := nil;
  if FWriteError <> '' then
    raise Exception.Create(FWriteError);
end;

{ Em erro ja a propagar: so esperar (o buffer pode estar em uso pela escrita). }
procedure TFastLineEditor.WaitWriteQuiet;
begin
  try
    WaitWrite;
  except
  end;
end;

procedure TFastLineEditor.CopyRange(ASrc: TStream; AFrom, ATo: Int64; ADst: TStream;
  const AFeedFrom, AFeedDelta: Int64; const ACancellable: Boolean);
var
  N, Skip, Cur: Integer;
  Bufs: array[0..1] of TBytes;
begin
  Bufs[0] := FBuf;
  Bufs[1] := FBuf2;
  Cur := 0;
  ASrc.Position := AFrom;
  try
    while AFrom < ATo do
    begin
      if ACancellable then
        CheckStop;
      N := Integer(Min(Int64(COPY_BLOCK_BYTES), ATo - AFrom));
      ASrc.ReadBuffer(Bufs[Cur][0], N);
      if Assigned(FBuilder) and (AFrom + N > AFeedFrom) then
      begin
        Skip := Integer(Max(Int64(0), AFeedFrom - AFrom));
        FBuilder.Feed(@Bufs[Cur][Skip], N - Skip, AFrom + Skip + AFeedDelta);
      end;
      WaitWrite;
      StartWrite(ADst, -1, Bufs[Cur], N);
      Cur := 1 - Cur;
      Inc(AFrom, N);
      Progress(N);
    end;
    WaitWrite;
  except
    WaitWriteQuiet;
    raise;
  end;
end;

function TFastLineEditor.NewJournalPath: string;
begin
  Result := EnsureFastFileTempDir + 'ff_edit_' + IntToStr(GetTickCount64) + '_' +
    IntToStr(GetCurrentThreadId) + JOURNAL_EXT;
end;

{ Grava os bytes originais [AStart, ABackupEnd) e marca o diario como valido. O
  diario fica aberto (exclusivo) ate a edicao terminar. }
function TFastLineEditor.WriteJournal(const AStart, ABackupEnd, AFeedFrom,
  AFeedDelta: Int64): TFileStream;
var
  JPath: string;
begin
  JPath := NewJournalPath;
  Result := TFileStream.Create(JPath, fmCreate or fmShareExclusive);
  try
    WriteJournalHeader(Result, FPath, AStart, ABackupEnd);
    FJournalDataOffset := Result.Position;
    CopyRange(FSrc, AStart, ABackupEnd, Result, AFeedFrom, AFeedDelta, True);
    FlushFileBuffers(Result.Handle);
    SetJournalState(Result, JOURNAL_STATE_COMMITTED);
  except
    Result.Free;
    UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
    raise;
  end;
end;

{ Desloca [AEnd, FSize) de ADelta bytes. Com ADelta > 0 copia do fim para o inicio,
  com ADelta < 0 do inicio para o fim: o bloco gravado nunca cobre bytes ainda por
  ler, por isso a leitura do bloco seguinte pode correr durante a escrita. }
procedure TFastLineEditor.ApplyShift(ATarget: TFileStream; const AStart, AEnd, ADelta: Int64);
var
  Pos, OldSize: Int64;
  N, Cur: Integer;
  Bufs: array[0..1] of TBytes;
  Reader: TFileStream;
begin
  OldSize := FSize;
  Bufs[0] := FBuf;
  Bufs[1] := FBuf2;
  Cur := 0;
  if ADelta > 0 then
    ATarget.Size := OldSize + ADelta;
  Reader := TFileStream.Create(FPath, fmOpenRead or fmShareDenyNone);
  try
    try
      if ADelta > 0 then
      begin
        Pos := OldSize;
        while Pos > AEnd do
        begin
          N := Integer(Min(Int64(COPY_BLOCK_BYTES), Pos - AEnd));
          Dec(Pos, N);
          Reader.Position := Pos;
          Reader.ReadBuffer(Bufs[Cur][0], N);
          WaitWrite;
          StartWrite(ATarget, Pos + ADelta, Bufs[Cur], N);
          Cur := 1 - Cur;
          Progress(N);
        end;
      end
      else if ADelta < 0 then
      begin
        Pos := AEnd;
        while Pos < OldSize do
        begin
          N := Integer(Min(Int64(COPY_BLOCK_BYTES), OldSize - Pos));
          Reader.Position := Pos;
          Reader.ReadBuffer(Bufs[Cur][0], N);
          WaitWrite;
          StartWrite(ATarget, Pos + ADelta, Bufs[Cur], N);
          Cur := 1 - Cur;
          Inc(Pos, N);
          Progress(N);
        end;
      end;
      WaitWrite;
    except
      WaitWriteQuiet;
      raise;
    end;
  finally
    Reader.Free;
  end;
  if Length(FReq.Payload) > 0 then
  begin
    ATarget.Position := AStart;
    ATarget.WriteBuffer(FReq.Payload[1], Length(FReq.Payload));
  end;
  if ADelta < 0 then
    ATarget.Size := OldSize + ADelta;
  FlushFileBuffers(ATarget.Handle);
end;

{ Falha depois de comecar a alterar o ficheiro: repoe a partir do diario. Se nem
  isso for possivel, o diario fica em disco para RecoverInterruptedFastEdits. }
procedure TFastLineEditor.RestoreFailedEdit(var AJournal, ATarget: TFileStream);
var
  JPath, Path: string;
  St, OldSize: Int64;
  State: Integer;
begin
  JPath := AJournal.FileName;
  FreeAndNil(ATarget);
  try
    if ReadJournalHeader(AJournal, Path, St, OldSize, State) then
    begin
      RestoreFromJournal(AJournal, Path, St, OldSize);
      FreeAndNil(AJournal);
      UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
      LogAsync(FastFileRuntimeLogPath, '[EditFast] edit failed, original restored: ' + Path);
    end;
  except
    on E: Exception do
      LogAsync(FastFileRuntimeLogPath, Format('[EditFast] restore failed, journal kept %s: %s',
        [JPath, E.Message]));
  end;
  FreeAndNil(AJournal);
end;

procedure TFastLineEditor.RunRewrite(const AStart, AEnd: Int64);
var
  Tmp, Err: string;
  Dst: TFileStream;
  Delta, FreeBytes: Int64;
  Done: Boolean;
begin
  Delta := Int64(Length(FReq.Payload)) - (AEnd - AStart);
  Tmp := FastFileScratchTempPathNearFile('edit', FPath);
  if UnUtils.VolumeFreeBytes(Tmp, FreeBytes) and
     (FreeBytes < FSize + Delta + FREE_SPACE_MARGIN) then
    raise Exception.CreateFmt('Not enough free disk space to save the edit ' +
      '(%d MB needed, %d MB free).', [(FSize + Delta) shr 20, FreeBytes shr 20]);
  Done := False;
  Dst := TFileStream.Create(Tmp, fmCreate);
  try
    try
      CopyRange(FSrc, 0, AStart, Dst, High(Int64), 0, True);
      if Length(FReq.Payload) > 0 then
      begin
        Dst.WriteBuffer(FReq.Payload[1], Length(FReq.Payload));
        FBuilder.Feed(PByte(PAnsiChar(FReq.Payload)), Length(FReq.Payload), AStart);
      end;
      CopyRange(FSrc, AEnd, FSize, Dst, AEnd, Delta, True);
      FreeAndNil(Dst);
      FreeAndNil(FSrc);
      if not UnUtils.TryRenameTempOverTarget(Tmp, FPath, Err) then
        raise Exception.Create(Err);
      Done := True;
    finally
      Dst.Free;
    end;
  finally
    if not Done then
      UnUtils.TryDeleteFileWithRetry(Tmp, 6, 40);
  end;
end;

procedure TFastLineEditor.Run(var ARes: TFastEditResult);
var
  Loc: TLineLoc;
  S, E, Delta, Suffix, FreeBytes: Int64;
  T0: UInt64;
  Target, Journal: TFileStream;
  JPath: string;
  Wt: TFileTime;
  Sz: Int64;
  LastTerm: Boolean;
begin
  T0 := GetTickCount64;
  JPath := '';
  Validate;
  ARes.SizeBefore := FSize;
  LastTerm := ReadByteAt(FSize - 1) = FReq.TermByte;
  ARes.ExistingLines := FMetaLines - 1;
  if not LastTerm then
    Inc(ARes.ExistingLines);

  if (FReq.Kind = fekInsert) and (FReq.TargetLine < 1) then
  begin
    Loc.Offset0 := FSize;
    Loc.TermsBefore := FMetaLines - 1;
  end
  else
    Loc := LocateLine(FReq.TargetLine);
  ARes.TargetExists := (FReq.TargetLine >= 1) and (Loc.Offset0 < FSize);
  S := Loc.Offset0;
  case FReq.Kind of
    fekInsert:
      E := S;
    fekReplace:
      begin
        if not ARes.TargetExists then
        begin
          ARes.Mode := femNone;
          ARes.LocateMs := Int64(GetTickCount64 - T0);
          Exit;
        end;
        E := LocateLine(FReq.TargetLine + 1).Offset0;
      end;
  else
    begin
      if not ARes.TargetExists then
        raise EFastEditNotApplicable.Create('delete target beyond EOF');
      E := LocateLine(FReq.TargetLine + Max(FReq.SpanLines, Int64(1))).Offset0;
    end;
  end;
  if FReq.Kind <> fekInsert then
    ARes.OldFirstLine := CaptureFirstLine(S, E);
  Delta := Int64(Length(FReq.Payload)) - (E - S);
  Suffix := FSize - E;
  ARes.LocateMs := Int64(GetTickCount64 - T0);
  T0 := GetTickCount64;

  if (Delta = 0) and SameTermLayout(S) then
    ARes.Mode := femInPlace
  else if Suffix * 2 <= FSize then
    ARes.Mode := femShift
  else
    ARes.Mode := femRewrite;

  { Diario fica em fastfile_temp: sem espaco para a copia do sufixo, reescrever. }
  if (ARes.Mode = femShift) and UnUtils.VolumeFreeBytes(EnsureFastFileTempDir, FreeBytes) and
     (FreeBytes < (FSize - S) + FREE_SPACE_MARGIN) then
    ARes.Mode := femRewrite;

  Target := nil;
  if ARes.Mode in [femInPlace, femShift] then
  begin
    try
      Target := TFileStream.Create(FPath, fmOpenReadWrite or fmShareDenyWrite);
    except
      on E1: Exception do
      begin
        LogAsync(FastFileRuntimeLogPath, '[EditFast] in-place open failed, rewriting: ' + E1.Message);
        if ARes.Mode = femInPlace then
          raise EFastEditNotApplicable.Create('file busy');
        ARes.Mode := femRewrite;
      end;
    end;
  end;

  try
    if ARes.Mode = femInPlace then
    begin
      FProgressTotal := E - S;
      Journal := WriteJournal(S, E, High(Int64), 0);
      try
        JPath := Journal.FileName;
        Target.Position := S;
        Target.WriteBuffer(FReq.Payload[1], Length(FReq.Payload));
        FlushFileBuffers(Target.Handle);
      except
        RestoreFailedEdit(Journal, Target);
        raise;
      end;
      FreeAndNil(Target);
      FreeAndNil(Journal);
      UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
      ARes.LineCountAfter := FMetaLines;
      ARes.IndexReady := True;
    end
    else
    begin
      BeginIndexes(Loc.TermsBefore);
      if ARes.Mode = femShift then
      begin
        FProgressTotal := (FSize - S) + Suffix;
        if Length(FReq.Payload) > 0 then
          FBuilder.Feed(PByte(PAnsiChar(FReq.Payload)), Length(FReq.Payload), S);
        Journal := WriteJournal(S, FSize, E, Delta);
        try
          JPath := Journal.FileName;
          FreeAndNil(FSrc);
          ApplyShift(Target, S, E, Delta);
        except
          RestoreFailedEdit(Journal, Target);
          raise;
        end;
        FreeAndNil(Target);
        FreeAndNil(Journal);
      end
      else
      begin
        FProgressTotal := FSize;
        RunRewrite(S, E);
      end;
      ARes.LineCountAfter := FBuilder.LineCount + 1;
      ARes.IndexReady := CommitIndexes;
      if JPath <> '' then
        UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
    end;
  finally
    Target.Free;
  end;

  UnUtils.GetFileSizeAndWriteTime(FPath, Sz, Wt);
  ARes.SizeAfter := Sz;
  if ARes.IndexReady then
    SaveLineIndexCache(FPath, Sz, ARes.LineCountAfter, Wt)
  else
    UnUtils.TryDeleteFileWithRetry(LineIndexCachePath, 6, 40);
  ARes.DataMs := Int64(GetTickCount64 - T0);
end;

{ Concatena bytes sem conversao de codepage. }
procedure AppendBytes(var ADst: RawByteString; const ASrc: RawByteString);
var
  L: Integer;
begin
  if Length(ASrc) = 0 then Exit;
  L := Length(ADst);
  SetLength(ADst, L + Length(ASrc));
  Move(ASrc[1], ADst[L + 1], Length(ASrc));
end;

procedure TFastLineEditor.WritePiece(ADst: TStream; const APiece: RawByteString;
  var AOutPos: Int64);
begin
  if Length(APiece) = 0 then Exit;
  ADst.WriteBuffer(APiece[1], Length(APiece));
  FBuilder.Feed(PByte(PAnsiChar(APiece)), Length(APiece), AOutPos);
  Inc(AOutPos, Length(APiece));
end;

{ Grava em ADst (a partir da posicao atual = FFirstStart no ficheiro final) os
  bytes originais intercalados com as linhas novas, e alimenta o indice.
  Byte original X do ficheiro esta em ASrc na posicao X + AShift. }
procedure TFastLineEditor.WriteStitched(ASrc: TStream; const AShift: Int64; ADst: TStream;
  const ACancellable: Boolean);
var
  I: Integer;
  Pos, OutPos: Int64;

  procedure CopySeg(const AFrom, ATo: Int64);
  begin
    if ATo <= AFrom then Exit;
    CopyRange(ASrc, AFrom + AShift, ATo + AShift, ADst, 0, OutPos - (AFrom + AShift),
      ACancellable);
    Inc(OutPos, ATo - AFrom);
  end;

begin
  Pos := FFirstStart;
  OutPos := FFirstStart;
  for I := 0 to High(FSpans) do
  begin
    CopySeg(Pos, FSpans[I].S);
    WritePiece(ADst, FEntries[FSpans[I].Entry].Payload, OutPos);
    Pos := FSpans[I].E;
  end;
  CopySeg(Pos, FSize);
  WritePiece(ADst, FAppend, OutPos);
end;

procedure TFastLineEditor.RunMulti(const AEntries: TFastReplaceEntries;
  const AEol: RawByteString; var ARes: TFastEditResult);
var
  I, NSpans: Integer;
  Loc, Prev, Next, FirstLoc: TLineLoc;
  HavePrev, AllSame: Boolean;
  LastEnd, CurLine, Delta, FreeBytes, Sz: Int64;
  T0: UInt64;
  Target, Journal, Dst: TFileStream;
  JPath, Tmp, Err: string;
  Wt: TFileTime;
  Done: Boolean;
begin
  T0 := GetTickCount64;
  JPath := '';
  FEntries := AEntries;
  Validate;
  ARes.SizeBefore := FSize;
  ARes.ExistingLines := FMetaLines - 1;
  if ReadByteAt(FSize - 1) <> FReq.TermByte then
    Inc(ARes.ExistingLines);

  SetLength(FSpans, Length(FEntries));
  NSpans := 0;
  HavePrev := False;
  FirstLoc.Offset0 := FSize;
  FirstLoc.TermsBefore := FMetaLines - 1;
  I := 0;
  while (I < Length(FEntries)) and (FEntries[I].Line <= ARes.ExistingLines) do
  begin
    if (I > 0) and (FEntries[I].Line <= FEntries[I - 1].Line) then
      raise EFastEditNotApplicable.Create('entries not sorted');
    if HavePrev then
      Loc := LocateLineFrom(Prev, FEntries[I].Line)
    else
      Loc := LocateLine(FEntries[I].Line);
    Next := LocateLineFrom(Loc, FEntries[I].Line + 1);
    if NSpans = 0 then
      FirstLoc := Loc;
    FSpans[NSpans].S := Loc.Offset0;
    FSpans[NSpans].E := Next.Offset0;
    FSpans[NSpans].Entry := I;
    Inc(NSpans);
    Prev := Next;
    HavePrev := True;
    if (I and 1023) = 0 then
      CheckStop;
    Inc(I);
  end;
  SetLength(FSpans, NSpans);

  { Alem do fim: linhas vazias ate ao numero pedido (como o caminho completo). }
  FAppend := '';
  CurLine := ARes.ExistingLines + 1;
  while I < Length(FEntries) do
  begin
    while CurLine < FEntries[I].Line do
    begin
      AppendBytes(FAppend, AEol);
      Inc(CurLine);
    end;
    AppendBytes(FAppend, FEntries[I].Payload);
    CurLine := FEntries[I].Line + 1;
    Inc(I);
  end;

  FFirstStart := FirstLoc.Offset0;
  Delta := Length(FAppend);
  AllSame := FAppend = '';
  LastEnd := FFirstStart;
  for I := 0 to NSpans - 1 do
  begin
    Inc(Delta, Int64(Length(FEntries[FSpans[I].Entry].Payload)) - (FSpans[I].E - FSpans[I].S));
    LastEnd := FSpans[I].E;
  end;
  if AllSame and (LastEnd - FFirstStart <= 4 * IN_PLACE_MAX_BYTES) then
    for I := 0 to NSpans - 1 do
      if not ((Length(FEntries[FSpans[I].Entry].Payload) = FSpans[I].E - FSpans[I].S) and
              SameTermLayoutAt(FSpans[I].S, FEntries[FSpans[I].Entry].Payload)) then
      begin
        AllSame := False;
        Break;
      end;
  ARes.TargetExists := True;
  ARes.LocateMs := Int64(GetTickCount64 - T0);
  T0 := GetTickCount64;

  if NSpans + Length(FAppend) = 0 then
  begin
    ARes.Mode := femInPlace;
    ARes.SizeAfter := FSize;
    ARes.LineCountAfter := FMetaLines;
    ARes.IndexReady := True;
    Exit;
  end;

  if AllSame and (LastEnd - FFirstStart <= 4 * IN_PLACE_MAX_BYTES) then
    ARes.Mode := femInPlace
  else if (FSize - FFirstStart) * 2 <= FSize then
    ARes.Mode := femShift
  else
    ARes.Mode := femRewrite;
  if (ARes.Mode = femShift) and UnUtils.VolumeFreeBytes(EnsureFastFileTempDir, FreeBytes) and
     (FreeBytes < (FSize - FFirstStart) + FREE_SPACE_MARGIN) then
    ARes.Mode := femRewrite;

  Target := nil;
  if ARes.Mode in [femInPlace, femShift] then
  begin
    try
      Target := TFileStream.Create(FPath, fmOpenReadWrite or fmShareDenyWrite);
    except
      on E1: Exception do
      begin
        LogAsync(FastFileRuntimeLogPath, '[EditFast] merge in-place open failed, rewriting: ' +
          E1.Message);
        ARes.Mode := femRewrite;
      end;
    end;
  end;

  try
    case ARes.Mode of
      femInPlace:
        begin
          FProgressTotal := LastEnd - FFirstStart;
          Journal := WriteJournal(FFirstStart, LastEnd, High(Int64), 0);
          try
            JPath := Journal.FileName;
            for I := 0 to NSpans - 1 do
            begin
              Target.Position := FSpans[I].S;
              Target.WriteBuffer(FEntries[FSpans[I].Entry].Payload[1],
                Length(FEntries[FSpans[I].Entry].Payload));
            end;
            FlushFileBuffers(Target.Handle);
          except
            RestoreFailedEdit(Journal, Target);
            raise;
          end;
          FreeAndNil(Target);
          FreeAndNil(Journal);
          UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
          JPath := '';
          ARes.LineCountAfter := FMetaLines;
          ARes.IndexReady := True;
        end;
      femShift:
        begin
          { A cauda nova e escrita a partir do diario (copia dos bytes originais),
            por isso nunca le bytes do alvo ja sobrescritos. }
          FProgressTotal := 2 * (FSize - FFirstStart);
          BeginIndexes(FirstLoc.TermsBefore);
          Journal := WriteJournal(FFirstStart, FSize, High(Int64), 0);
          try
            JPath := Journal.FileName;
            Target.Position := FFirstStart;
            WriteStitched(Journal, FJournalDataOffset - FFirstStart, Target, False);
            Target.Size := Target.Position;
            FlushFileBuffers(Target.Handle);
          except
            RestoreFailedEdit(Journal, Target);
            raise;
          end;
          FreeAndNil(Target);
          FreeAndNil(Journal);
          ARes.LineCountAfter := FBuilder.LineCount + 1;
          ARes.IndexReady := CommitIndexes;
        end;
    else
      begin
        FProgressTotal := FSize;
        BeginIndexes(FirstLoc.TermsBefore);
        Tmp := FastFileScratchTempPathNearFile('merge', FPath);
        if UnUtils.VolumeFreeBytes(Tmp, FreeBytes) and
           (FreeBytes < FSize + Delta + FREE_SPACE_MARGIN) then
          raise Exception.CreateFmt('Not enough free disk space to save the merge ' +
            '(%d MB needed, %d MB free).', [(FSize + Delta) shr 20, FreeBytes shr 20]);
        Done := False;
        Dst := TFileStream.Create(Tmp, fmCreate);
        try
          try
            CopyRange(FSrc, 0, FFirstStart, Dst, High(Int64), 0, True);
            WriteStitched(FSrc, 0, Dst, True);
            FreeAndNil(Dst);
            FreeAndNil(FSrc);
            if not UnUtils.TryRenameTempOverTarget(Tmp, FPath, Err) then
              raise Exception.Create(Err);
            Done := True;
          finally
            Dst.Free;
          end;
        finally
          if not Done then
            UnUtils.TryDeleteFileWithRetry(Tmp, 6, 40);
        end;
        ARes.LineCountAfter := FBuilder.LineCount + 1;
        ARes.IndexReady := CommitIndexes;
      end;
    end;
    if JPath <> '' then
      UnUtils.TryDeleteFileWithRetry(JPath, 6, 40);
  finally
    Target.Free;
  end;

  UnUtils.GetFileSizeAndWriteTime(FPath, Sz, Wt);
  ARes.SizeAfter := Sz;
  if ARes.IndexReady then
    SaveLineIndexCache(FPath, Sz, ARes.LineCountAfter, Wt)
  else
    UnUtils.TryDeleteFileWithRetry(LineIndexCachePath, 6, 40);
  ARes.DataMs := Int64(GetTickCount64 - T0);
end;

function TryFastMultiReplace(const AFileName: string; const ATermByte: Byte;
  const AEol: RawByteString; const AEntries: TFastReplaceEntries;
  out ARes: TFastEditResult; const AShouldStop: TFastEditShouldStop;
  const AOnProgress: TFastEditProgress): Boolean;
var
  Req: TFastEditRequest;
  Ed: TFastLineEditor;
begin
  ARes := Default(TFastEditResult);
  Result := False;
  Req := Default(TFastEditRequest);
  Req.FileName := AFileName;
  Req.Kind := fekReplace;
  Req.TermByte := ATermByte;
  Ed := TFastLineEditor.Create(Req, AShouldStop, AOnProgress);
  try
    try
      Ed.RunMulti(AEntries, AEol, ARes);
      Result := True;
    except
      on E: EFastEditNotApplicable do
      begin
        LogAsync(FastFileRuntimeLogPath, '[EditFast] merge not applicable: ' + E.Message);
        ARes := Default(TFastEditResult);
      end;
    end;
  finally
    Ed.Free;
  end;
end;

function TryFastLineEdit(const AReq: TFastEditRequest; out ARes: TFastEditResult;
  const AShouldStop: TFastEditShouldStop; const AOnProgress: TFastEditProgress): Boolean;
var
  Ed: TFastLineEditor;
begin
  ARes := Default(TFastEditResult);
  Result := False;
  Ed := TFastLineEditor.Create(AReq, AShouldStop, AOnProgress);
  try
    try
      Ed.Run(ARes);
      Result := True;
    except
      on E: EFastEditNotApplicable do
      begin
        LogAsync(FastFileRuntimeLogPath, '[EditFast] not applicable: ' + E.Message);
        ARes := Default(TFastEditResult);
      end;
    end;
  finally
    Ed.Free;
  end;
end;

end.
