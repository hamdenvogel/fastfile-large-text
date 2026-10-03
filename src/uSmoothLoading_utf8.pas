unit uSmoothLoading;


interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, DateUtils, Math, ClipBrd, CommCtrl,
  uLineEditor, uMMF, uPosBMH;

type
  TfrmSmoothLoadingForm = class(TForm)
    pnlContainer: TPanel;
    imgLogo: TImage;
    lblMessage: TLabel;
    tmrAnimation: TTimer;
    pbProgressBar: TPaintBox;
    procedure tmrAnimationTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure pbProgressBarPaint(Sender: TObject);
  private
    FCurrentProgress: Double;
    FTargetProgress: Integer;
    FIsDeterminate: Boolean;
    FLastPaintedProgress: Double;
    FBackgroundBmp: TBitmap;
        // Fade-in suave ao exibir
    FFadeInActive: Boolean;
    FFadeStartTick: Cardinal;
    FFadeDurationMS: Cardinal;
    FFadeStartAlpha: Byte;
    FFadeEndAlpha: Byte;
    procedure BuildBackground;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure ApplySmoothProgress(Percent: Integer);
    procedure WMSmoothProgress(var Msg: TMessage); message WM_APP + 77;
    procedure CenterContainer;
    procedure RoundControl(Control: TWinControl; Radius: Integer);
    procedure LoadLogo;
    procedure ForceFullScreen; // Novo método para garantir o tamanho
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
      // Operações centralizadas (threads agora ficam nesta unit)
end;
      
type
  TSmoothLoadingMode = (slmReadFile, slmEditFile, slmExportLines);

  // Thread controladora: esta é a "TfrmSmoothLoading" solicitada
  TfrmSmoothLoading = class(TThread)
  private
    FPercentToSync: Integer;
    FMode: TSmoothLoadingMode;
    FFileName: String;
    FOp: TOperationType;
    FLineNum: Int64;
    FTxt: String;
    FParams: String;
    FSaveToFile: Boolean;
    FOutFileName: String;

    FMessageText: String;

    procedure SyncShow;
    procedure SyncHide;
  protected
    procedure Execute; override;
  public
    constructor Create; reintroduce;

    // API pública (mantém compatibilidade com o projeto)
    class procedure ShowLoading(const MessageText: String);
    class procedure HideLoading;
    class procedure UpdateProgress(Percent: Integer);
  end;

const
  INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';
  INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';

  OUT_BUFFER_SIZE   = 65536;
  INDEX_RECORD_SIZE = 20;

type
  TStopWatch = class
  private
    fFrequency : TLargeInteger;
    fStartCount, fStopCount : TLargeInteger;
    procedure SetTickStamp(var lInt : TLargeInteger);
    function  GetElapsedMilliseconds: TLargeInteger;
  public
    function    FormatMillisecondsToDateTime(const ms: integer): string;
    constructor Create(const startOnCreate : boolean = false);
    procedure   Start;
    procedure   Stop;
    property    ElapsedMilliseconds : TLargeInteger read GetElapsedMilliseconds;
  end;

type
  TReadFileThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    fileName: string;
    FOutStream: TFileStream;
    FOutBuffer: array[0..OUT_BUFFER_SIZE - 1] of AnsiChar;
    FOutIndex: Integer;
    FTotalSize: Int64;
    FBytesRead: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FHitLineLimit: Boolean;
    FSkipDenseIndex: Boolean;
    FAutoDeleteDenseIndex: Boolean;
    totalLines: Int64;
    totalCharacters: Int64;

    procedure SyncShowAirbagWarning;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    function TimerResult: string;
    procedure FinishThreadExecution;
    procedure SyncProgress;
    procedure InitOutput;
    procedure WriteToBuffer(const Offset: Int64);
    procedure FlushOutput;
    procedure CloseOutput;
  protected
    procedure Execute; override;
  public
    constructor Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  TDeltaEntry = record
    LineNumber: Int64;
    NewText: String;
  end;
  TDeltaArray = array of TDeltaEntry;

  TMergeDeltaThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FFileName: String;
    FDeltaFileName: String;
    FTotalSize: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSkipDenseIndex: Boolean;
    FAutoDeleteDenseIndex: Boolean;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName, ADeltaFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  TEditFileThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FFileName: String;
    FOperation: TOperationType;
    FTargetLine: Int64;
    FContent: String;
    FTotalSize: Int64;
    FBytesProcessed: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSkipDenseIndex: Boolean;
    FAutoDeleteDenseIndex: Boolean;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;


  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName: String; const Op: TOperationType; const LineNum: Int64; const Txt: String;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  TExportFileThread = class(TThread)
  private
    FPercentToSync: Integer;
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    FLineParams: String;
    FSaveToFile: Boolean;
    FOutputFileName: String;
    FSourceFileName: String;
    FTotalLines: Int64;
    FResultList: TStringList;
    FPercent: Integer;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncClipboard;
    procedure SyncFinish;
    function ParseLines(const Input: String): TList;
  protected
    procedure Execute; override;
  public
    constructor Create(const ALineParams: String; const ASaveToFile: Boolean; const AOutputFileName: String;
    const ASourceFileName: String; const ATotalLines: Int64;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

var
  frmSmoothLoading: TfrmSmoothLoadingForm;

implementation

{$R *.dfm}

uses
  StrUtils,
  UnReadFileThread,
  UnBufferedTextWriter,
  ThreadFileLog,
  uI18n, UnConsts, uFastFilePaths;

procedure ShowAppMessage(const Msg: string);
begin
  Dialogs.ShowMessage(TrText(Msg));
end;

function AppMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
begin
  Result := Dialogs.MessageDlg(TrText(Msg), DlgType, Buttons, HelpCtx);
end;

{ ============================================================================ }
{ StopWatch }
{ ============================================================================ }

constructor TStopWatch.Create(const startOnCreate: boolean);
begin
  inherited Create;
  QueryPerformanceFrequency(fFrequency);
  if startOnCreate then Start;
end;

function TStopWatch.FormatMillisecondsToDateTime(const ms: integer): string;
var
  dt: TDateTime;
begin
  dt := ms / MSecsPerSec / SecsPerDay;
  Result := Format('%s', [FormatDateTime('hh:nn:ss.z', Frac(dt))]);
end;

function TStopWatch.GetElapsedMilliseconds: TLargeInteger;
begin
  Result := (MSecsPerSec * (fStopCount - fStartCount)) div fFrequency;
end;

procedure TStopWatch.SetTickStamp(var lInt: TLargeInteger);
begin
  QueryPerformanceCounter(lInt);
end;

procedure TStopWatch.Start;
begin
  SetTickStamp(fStartCount);
end;

procedure TStopWatch.Stop;
begin
  SetTickStamp(fStopCount);
end;

{ ============================================================================ }
{ TfrmSmoothLoading - operações públicas }
{ ============================================================================ }


{ ============================================================================ }
{ TfrmSmoothLoading (THREAD CONTROLADORA) }
{ ============================================================================ }

constructor TfrmSmoothLoading.Create;
begin
  inherited Create(True); // CreateSuspended = True
  FreeOnTerminate := True;
  Priority := tpNormal;
end;

procedure TfrmSmoothLoading.SyncShow;
begin
  // Reusa a API pública (mantém singleton do form)
  TfrmSmoothLoading.ShowLoading(FMessageText);
end;

procedure TfrmSmoothLoading.SyncHide;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TfrmSmoothLoading.Execute;
var
  Worker: TThread;
begin
  // Mostra overlay (VCL via main thread)
  Synchronize(SyncShow);

  Worker := nil;
  try
    case FMode of
      slmReadFile:
        Worker := TReadFileThread.Create(True, FFileName, False, true);
      slmEditFile:
        Worker := TEditFileThread.Create(FFileName, FOp, FLineNum, FTxt, False);
      slmExportLines:
        if Assigned(frmReadFileThread) then
          Worker := TExportFileThread.Create(FParams, FSaveToFile, FOutFileName,
            frmReadFileThread.edtFileName.Text, frmReadFileThread.ListView1.Items.Count, False);
    end;

    if Assigned(Worker) then
    begin
      Worker.FreeOnTerminate := False;
      Worker.Resume;
      Worker.WaitFor;
      Worker.Free;
    end;
  finally
    // Fecha overlay (VCL via main thread)
    Synchronize(SyncHide);
  end;
end;

{ ============================================================================ }
{ THREAD 1: LEITURA }
{ ============================================================================ }

constructor TReadFileThread.Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean; const ShowUI: Boolean);
begin
  inherited Create(CreateSuspended);
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FreeOnTerminate := True;
  fileName := AFileName;

  // Se ShowUI=True, a prpria thread cuida de abrir/fechar o SmoothLoading.
  // IMPORTANTE: esta chamada deve ocorrer no MainThread (normalmente  o caso, pois a thread  criada pela UI).
  if FShowLoadingUI then
  begin
    // Fora a criao desta thread, garantimos que a abertura do overlay ocorre sempre no MainThread.
    FLoadingMsg := 'Reading file...';
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;

  sw := TStopWatch.Create;
  sw.Start;
end;

destructor TReadFileThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TReadFileThread.InitOutput;
var
  OutputPath: String;
  RetryCount: Integer;
  IsSuccess: Boolean;
begin
  OutputPath := FastFileExeDirPath(TEMPFILE);
  IsSuccess := False;
  RetryCount := 0;

  while (not IsSuccess) and (RetryCount < 3) do
  begin
    try
      if FileExists(OutputPath) then DeleteFile(OutputPath);
      FOutStream := TFileStream.Create(OutputPath, fmCreate or fmShareDenyWrite);
      FOutIndex := 0;
      IsSuccess := True;
    except
      Inc(RetryCount);
      Sleep(200);
      if RetryCount >= 3 then raise;
    end;
  end;
end;

procedure TReadFileThread.FlushOutput;
begin
  if (FOutIndex > 0) and Assigned(FOutStream) then
  begin
    FOutStream.Write(FOutBuffer, FOutIndex);
    FOutIndex := 0;
  end;
end;

procedure TReadFileThread.WriteToBuffer(const Offset: Int64);
var
  S: AnsiString;
  Len: Integer;
begin
  S := Format('%18d', [Offset]) + #13#10;
  Len := Length(S);
  if (FOutIndex + Len) > OUT_BUFFER_SIZE then FlushOutput;
  Move(S[1], FOutBuffer[FOutIndex], Len);
  Inc(FOutIndex, Len);
end;

procedure TReadFileThread.CloseOutput;
begin
  if Assigned(FOutStream) then
  begin
    FlushOutput;
    FreeAndNil(FOutStream);
  end;
end;

procedure TReadFileThread.SyncShowLoading;
begin
  // Executa no MainThread
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TReadFileThread.SyncHideLoading;
begin
  // Executa no MainThread
  TfrmSmoothLoading.HideLoading;
end;

procedure TReadFileThread.SyncSetProgress;
begin
  // Executa no MainThread
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TReadFileThread.SyncProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FPercentToSync);
end;

procedure TReadFileThread.Execute;
function ForceDeleteFile(const FileName: string): Boolean;
var

  RetryCount: Integer;

begin

  Result := False;

  if not FileExists(FileName) then

  begin

    Result := True;

    Exit;

  end;



  // 1. Tenta apagar definitivamente (não envia para lixeira para evitar overhead)

  // 2. Se falhar, faz até 5 tentativas com pequeno delay (caso o SO ainda esteja soltando o handle)

  for RetryCount := 1 to 5 do

  begin

    if DeleteFile(FileName) then

    begin

      Result := True;

      Break;

    end;

    

    // Se falhou, espera 200ms antes da próxima tentativa

    Sleep(200);

  end;



  // 3. Caso crítico: Se ainda não deletou, tenta renomear antes de desistir

  // Isso permite que um novo arquivo 'temp.txt' seja criado mesmo se o antigo estiver preso

  if not Result then

  begin

    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');

  end;

end;
var

  MMF: TMMFReader;

  LastErr: DWORD;

  P: PByte;

  Contiguous: Cardinal;

  AbsOffset: Int64;

  i: Integer;

  IndexWriter: TBufferedTextWriter;

  IndexFileName: string;

  NewPercent: Integer;

begin

  inherited;

  totalLines := 0;
  FBytesRead := 0;
  FCurrentPercent := 0;
  IndexFileName := FastFileExeDirPath(TEMPFILE);

  MMF := nil;
  IndexWriter := nil;
  try
    // Sincroniza com a MainThread para fechar arquivos abertos na UI [cite: 5, 11]
    // CloseFileStreams removed

    // Deleta arquivo anterior (Função profissional implementada anteriormente)
    ForceDeleteFile(IndexFileName);

    // Inicializa MMF (Leitura) e Buffer (Escrita) 
    MMF := TMMFReader.Create(fileName);
    FTotalSize := MMF.FileSize;
    
    // Thresholds para arquivos grandes (Regression fix for 10 GB+ hangs)
    { Keep dense index when built: Find/Replace depend on temp.txt on disk. }
    FAutoDeleteDenseIndex := False;
    FSkipDenseIndex := (FTotalSize > Int64(2) * 1024 * 1024 * 1024);
    
    if (not FSkipDenseIndex) then
      IndexWriter := TBufferedTextWriter.Create(IndexFileName, 8 * 1024 * 1024)
    else
      IndexWriter := nil;

    // Grava offset da linha 1
    if FTotalSize > 0 then begin
      if Assigned(IndexWriter) then IndexWriter.WriteOffsetDirect(1);
    end;

    AbsOffset := 0;
    while (AbsOffset < FTotalSize) and (not Terminated) do
    begin
      // Obtém ponteiro direto da memória
      P := MMF.PtrAt(AbsOffset, 1, Contiguous);
      if (P = nil) or (Contiguous = 0) then Break;

      for i := 0 to Contiguous - 1 do
      begin
        // Detecção de quebra de linha ultra-rápida
        if PAnsiChar(P)^ = #10 then
        begin
          Inc(totalLines);
          // Escrita direta no buffer sem alocar strings dinâmicas
          if Assigned(IndexWriter) then IndexWriter.WriteOffsetDirect(AbsOffset + i + 2);
          
          // Atualiza a ProgressBar do frmSmoothLoading de forma fluida 
          if (totalLines and $1FFF = 0) then 
          begin
            NewPercent := Round(((AbsOffset + i) * 100) / FTotalSize);
            if NewPercent > FCurrentPercent then
            begin
              FCurrentPercent := NewPercent;
              FPercentToSync := FCurrentPercent;
              TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync); 
            end;
          end;
        end;
        Inc(P);
      end;
      AbsOffset := AbsOffset + Contiguous;

        // --- AIRBAG (Valvula de Escape) ---
        // Checado fora do loop interno para nao perder performance do SWAR
        if totalLines >= 2000000000 then
        begin
          FHitLineLimit := True;
          Break;
        end;

        if FShowLoadingUI then begin NewPercent := Round((AbsOffset * 100) / FTotalSize); if NewPercent > FCurrentPercent then begin FCurrentPercent := NewPercent; TfrmSmoothLoading.PostProgressFromWorker(FCurrentPercent); end; end;
    end;
  finally
    if Assigned(IndexWriter) then FreeAndNil(IndexWriter);
    if Assigned(MMF) then FreeAndNil(MMF);
    Synchronize(Self.FinishThreadExecution);
  end;

end;


procedure TReadFileThread.SyncShowAirbagWarning;
begin
  Windows.MessageBox(0, PChar('Airbag de Memoria ativado! O arquivo possui mais de 2 bilhoes de linhas, o que excede o limite seguro do Windows 32-bits. A leitura das linhas foi interrompida automaticamente para proteger o sistema contra travamentos.'), PChar('Protecao Ativada (FastFile)'), 48); // 48 = MB_ICONWARNING
end;

procedure TReadFileThread.FinishThreadExecution;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    Synchronize(SyncHideLoading);
  if FHitLineLimit then
    Synchronize(SyncShowAirbagWarning);
  if Assigned(frmReadFileThread) then
    frmReadFileThread.finishFileNameRead(Format(INFO_FILE_TIME, [fileName, TimerResult, totalLines, totalCharacters]), totalLines);
end;

function TReadFileThread.TimerResult: string;
begin
  Result := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
end;

{ ============================================================================ }
{ THREAD 2: EDIÇÃO }
{ ============================================================================ }

constructor TEditFileThread.Create(const AFileName: String; const Op: TOperationType; const LineNum: Int64; const Txt: String;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FOperation := Op;
  FTargetLine := LineNum;
  FContent := Txt;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    case FOperation of
      otInsert: FLoadingMsg := 'Editing file (insert)...';
      otReplace: FLoadingMsg := 'Editing file (replace)...';
      otDelete: FLoadingMsg := 'Editing file (delete)...';
    else
      FLoadingMsg := 'Editing file...';
    end;
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TEditFileThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TEditFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TEditFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TEditFileThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TEditFileThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TEditFileThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowAppMessage('Error: ' + FErrorMsg);
end;

procedure TEditFileThread.FinishThread;
var
  TimeStr: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := Format(INFO_EDIT_TIME, [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmReadFileThread) then
    begin
      frmReadFileThread.mmTimer.Lines.Add(TimeStr);
      frmReadFileThread.RefreshFile;
    end;
  end
  else
    ShowAppMessage('Operation failed or cancelled.');
end;

procedure TEditFileThread.Execute;
// Função interna para manter o código limpo
function ForceDeleteFile(const FileName: string): Boolean;

var RetryCount: Integer;

begin

  Result := False;

  if not FileExists(FileName) then begin Result := True; Exit; end;

  for RetryCount := 1 to 5 do begin

    if DeleteFile(FileName) then begin Result := True; Break; end;

    Sleep(200);

  end;

  if not Result then

    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');

end;
var

  MMF: TMMFReader;

  LastErr: DWORD;

  DestWriter: TBufferedTextWriter;

  P, PLineStart: PAnsiChar;

  Contiguous: Cardinal;

  AbsOffset: Int64;

  CurrentLine: Int64;

  NewPercent: Integer;

  i, LineLen: Integer;

begin

  inherited;

  FTempFileName := FastFileExeDirPath(TEMP_EDIT_FILE);

  ForceDeleteFile(FTempFileName);



  MMF := nil;

  DestWriter := nil;

  try

    // 1. Abre o arquivo original e o temporário

    MMF := TMMFReader.Create(FFileName);

    DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024); // 16MB Buffer



    FTotalSize := MMF.FileSize;

    CurrentLine := 1;

    AbsOffset := 0;

    FCurrentPercent := 0;



    while (AbsOffset < FTotalSize) and (not Terminated) do

    begin

      // Obtém o ponteiro da memória via janela MMF

      P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));

      if (P = nil) or (Contiguous = 0) then Break;

      

      PLineStart := P; 

      

      for i := 0 to Contiguous - 1 do

      begin

        if P^ = #10 then

        begin

          LineLen := (P - PLineStart) + 1;

          

          if (CurrentLine = FTargetLine) then

          begin

            case FOperation of

              otInsert: begin

                // Converte o novo conteúdo de ANSI para UTF-8 antes de gravar

                DestWriter.WriteLine(AnsiToUTF8(string(FContent)));

                DestWriter.WriteRaw(PLineStart, LineLen);

              end;

              otEdit, otReplace: begin

                // Substitui a linha original pela nova em UTF-8
                DestWriter.WriteLine(AnsiToUTF8(string(FContent)));
              end;

              otDelete: ; // Ignora a linha

            end;

          end

          else

            DestWriter.WriteRaw(PLineStart, LineLen);



          Inc(CurrentLine);

          PLineStart := P + 1;

        end;

        Inc(P);

      end;



      // Incrementa o offset absoluto lido

      AbsOffset := AbsOffset + Contiguous;

        // --- AIRBAG (Valvula de Escape) ---
        // Checado fora do loop interno para nao perder performance do SWAR
        if totalLines >= 2000000000 then
        begin
          FHitLineLimit := True;
          Break;
        end;

        if FShowLoadingUI then begin NewPercent := Round((AbsOffset * 100) / FTotalSize); if NewPercent > FCurrentPercent then begin FCurrentPercent := NewPercent; TfrmSmoothLoading.PostProgressFromWorker(FCurrentPercent); end; end;

      

      // --- ATUALIZAÇÃO DE PROGRESSO ESTRATÉGICA ---

      // Verificamos a cada bloco de leitura (mais eficiente que por linha)

      if FTotalSize > 0 then

      begin

        NewPercent := Round((AbsOffset * 100) / FTotalSize);

        // Só sincroniza se o percentual realmente mudou (evita flood de mensagens na UI)

        if NewPercent > FCurrentPercent then

        begin

          FCurrentPercent := NewPercent;

          FPercentToSync := FCurrentPercent;

          // Synchronize garante que o SmoothLoading capture o valor no MainThread [cite: 5]

          TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);

        end;

      end;

    end;



    // Flush e encerramento

    FreeAndNil(DestWriter);

    FreeAndNil(MMF);



    if ForceDeleteFile(FFileName) then

      RenameFile(FTempFileName, FFileName);



    FSuccess := True;

  except

    on E: Exception do begin

      FErrorMsg := E.Message;

      if Assigned(MMF) then MMF.Free;

      if Assigned(DestWriter) then DestWriter.Free;

      Synchronize(SyncError);

    end;

  end;

  Synchronize(FinishThread);

end;
{ ============================================================================ }
{ TMergeDeltaThread: MERGE MULTIPLE LINES (DELTA) }
{ ============================================================================ }

constructor TMergeDeltaThread.Create(const AFileName, ADeltaFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FDeltaFileName := ADeltaFileName;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    FLoadingMsg := 'Merging delta file...';
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TMergeDeltaThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TMergeDeltaThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TMergeDeltaThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TMergeDeltaThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TMergeDeltaThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TMergeDeltaThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowAppMessage('Merge Delta Error: ' + FErrorMsg);
end;

procedure TMergeDeltaThread.FinishThread;
var
  TimeStr: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := Format('Merge completed in: %s millisecs.', [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmReadFileThread) then
    begin
      frmReadFileThread.mmTimer.Lines.Add(TimeStr);
      // Calls btnReadFileClick to refresh
      frmReadFileThread.btnReadFile.Click;
    end;
  end;
end;

function SortDeltaLines(Item1, Item2: Pointer): Integer;
var
  L1: Int64;
  L2: Int64;
begin
  L1 := TDeltaEntry(Item1^).LineNumber;
  L2 := TDeltaEntry(Item2^).LineNumber;
  if L1 < L2 then Result := -1
  else if L1 > L2 then Result := 1
  else Result := 0;
end;

procedure TMergeDeltaThread.Execute;
// Internal function
function ForceDeleteFile(const FileName: string): Boolean;
var RetryCount: Integer;
begin
  Result := False;
  if not FileExists(FileName) then begin Result := True; Exit; end;
  for RetryCount := 1 to 5 do begin
    if DeleteFile(FileName) then begin Result := True; Break; end;
    Sleep(200);
  end;
  if not Result then
    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
end;

var
  MMF: TMMFReader;
  LastErr: DWORD;
  DestWriter: TBufferedTextWriter;
  P, PLineStart: PAnsiChar;
  Contiguous: Cardinal;
  AbsOffset: Int64;
  CurrentLine: Int64;
  NewPercent: Integer;
  i, LineLen: Integer;
  
  DeltaLines: TStringList;
  DeltaArr: TDeltaArray;
  DeltaCount, dIndex: Integer;
  DeltaParts: TStringList;
  ColonPos: Integer;
  sLine: String;
  LineNum: Int64;
  LineText: String;
begin

  inherited;

  // CloseFileStreams removed

  FTempFileName := FastFileExeDirPath(TEMP_MERGE_SCRATCH_FILE);
  ForceDeleteFile(FTempFileName);

  // 1. Read Delta File Configuration
  DeltaLines := TStringList.Create;
  DeltaCount := 0;
  SetLength(DeltaArr, 0);
  try
    if FileExists(FDeltaFileName) then
    begin
      DeltaLines.LoadFromFile(FDeltaFileName);
      SetLength(DeltaArr, DeltaLines.Count);
      for i := 0 to DeltaLines.Count - 1 do
      begin
        sLine := Trim(DeltaLines[i]);
        if sLine = '' then Continue;
        
        ColonPos := PosBMH(':', sLine);
        if ColonPos > 0 then
        begin
          LineNum := StrToInt64Def(Trim(Copy(sLine, 1, ColonPos - 1)), -1);
          if LineNum > 0 then
          begin
            LineText := Copy(sLine, ColonPos + 1, Length(sLine));
            // strip optional starting space if any:
            if (Length(LineText) > 0) and (LineText[1] = ' ') then
              LineText := Copy(LineText, 2, Length(LineText));
              
            DeltaArr[DeltaCount].LineNumber := LineNum;
            DeltaArr[DeltaCount].NewText := LineText;
            Inc(DeltaCount);
          end;
        end;
      end;
      SetLength(DeltaArr, DeltaCount);
      // Wait, TList.Sort is easy, but array sort requires custom or simple bubble sort since count is small
      // We will do a simple sort or if delta is already sorted we are fine. Let's do Bubble Sort (Delta is usually small, so it's O(K^2) and fine)
      for i := 0 to DeltaCount - 2 do
      begin
        for dIndex := i + 1 to DeltaCount - 1 do
        begin
          if DeltaArr[i].LineNumber > DeltaArr[dIndex].LineNumber then
          begin
            LineNum := DeltaArr[i].LineNumber;
            LineText := DeltaArr[i].NewText;
            DeltaArr[i] := DeltaArr[dIndex];
            DeltaArr[dIndex].LineNumber := LineNum;
            DeltaArr[dIndex].NewText := LineText;
          end;
        end;
      end;
    end
    else
    begin
      FErrorMsg := 'Delta file not found: ' + FDeltaFileName;
      FSuccess := False;
      Synchronize(SyncError);
      Exit;
    end;
  finally
    DeltaLines.Free;
  end;

  MMF := nil;
  DestWriter := nil;
  try
    // 2. Open Original and Temp
    MMF := TMMFReader.Create(FFileName);
    DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024); // 16MB Buffer

    FTotalSize := MMF.FileSize;
    CurrentLine := 1;
    AbsOffset := 0;
    FCurrentPercent := 0;
    dIndex := 0;

    while (AbsOffset < FTotalSize) and (not Terminated) do
    begin
      // Gets memory block via MMF Window
      P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));
      if (P = nil) or (Contiguous = 0) then Break;
      
      PLineStart := P; 
      
      for i := 0 to Contiguous - 1 do
      begin
        if P^ = #10 then
        begin
          LineLen := (P - PLineStart) + 1;
          
          if (dIndex < DeltaCount) and (CurrentLine = DeltaArr[dIndex].LineNumber) then
          begin
            // Substitute line content
            // Assuming UnBufferedTextWriter.WriteLine handles formatting, we might need UTF-8 conversion if necessary
            // Actually AnsiToUTF8 might be needed if original has accents, similar to EditFileThread
            DestWriter.WriteLine(DeltaArr[dIndex].NewText);
            Inc(dIndex);
          end
          else
          begin
             DestWriter.WriteRaw(PLineStart, LineLen);
          end;

          Inc(CurrentLine);
          PLineStart := P + 1;
        end;
        Inc(P);
      end;

      AbsOffset := AbsOffset + Contiguous;

        // --- AIRBAG (Valvula de Escape) ---
        // Checado fora do loop interno para nao perder performance do SWAR
        if totalLines >= 2000000000 then
        begin
          FHitLineLimit := True;
          Break;
        end;

        if FShowLoadingUI then begin NewPercent := Round((AbsOffset * 100) / FTotalSize); if NewPercent > FCurrentPercent then begin FCurrentPercent := NewPercent; TfrmSmoothLoading.PostProgressFromWorker(FCurrentPercent); end; end;
      
      // Check if we finished delta early
      if (dIndex >= DeltaCount) then
      begin
         // But we must copy the rest of the file
         // wait, the loop continues and just writes raw lines. MMF continues.
      end;
      
      if FTotalSize > 0 then
      begin
        NewPercent := Round((AbsOffset * 100) / FTotalSize);
        if NewPercent > FCurrentPercent then
        begin
          FCurrentPercent := NewPercent;
          FPercentToSync := FCurrentPercent;
          TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
        end;
      end;
    end;

    FreeAndNil(DestWriter);
    FreeAndNil(MMF);

    if ForceDeleteFile(FFileName) then
    begin
      // Windows (antivirus, iteradores de pasta, etc) pode segurar
      // o temp file por um instante após fechar. Vamos tentar renomear várias vezes
      // Capturamos o ultimo Erro
      LastErr := 0;
      for i := 1 to 20 do
      begin
        if RenameFile(FTempFileName, FFileName) then
          Break;
        LastErr := GetLastError;
        Sleep(500);
      end;
      
      if not FileExists(FFileName) then
         raise Exception.CreateFmt('File could not be renamed automatically. Error %d: %s', [LastErr, SysErrorMessage(LastErr)]);
    end;

    FSuccess := True;
  except
    on E: Exception do begin
      FErrorMsg := E.Message;
      if Assigned(MMF) then MMF.Free;
      if Assigned(DestWriter) then DestWriter.Free;
      Synchronize(SyncError);
    end;
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ THREAD 3: EXPORTAÇÃO }
{ ============================================================================ }

constructor TExportFileThread.Create(const ALineParams: String; const ASaveToFile: Boolean; const AOutputFileName: String;
    const ASourceFileName: String; const ATotalLines: Int64;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True);
begin
  inherited Create(False);
  FAutoHide := AutoHide;
  FreeOnTerminate := True;
  FLineParams := ALineParams;
  FSaveToFile := ASaveToFile;
  FOutputFileName := AOutputFileName;
  FSourceFileName := ASourceFileName;
  FTotalLines := ATotalLines;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    if FSaveToFile then
      FLoadingMsg := 'Exporting lines to file...'
    else
      FLoadingMsg := 'Exporting lines...';
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FResultList := TStringList.Create;
end;

destructor TExportFileThread.Destroy;
begin
  FResultList.Free;
  inherited;
end;

procedure TExportFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TExportFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TExportFileThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TExportFileThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercent;
  SyncSetProgress;
end;

procedure TExportFileThread.SyncClipboard;
begin
  Clipboard.AsText := FResultList.Text;
end;

procedure TExportFileThread.SyncFinish;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FSaveToFile then
    ShowAppMessage('Export finished! File saved to: ' + FOutputFileName)
  else
    ShowAppMessage('Export finished! Lines copied to clipboard.');
end;

function TExportFileThread.ParseLines(const Input: String): TList;
var
  S: String;
  i, j: Integer;
  Parts, Range: TStringList;
  V1, V2: Int64;
begin
  Result := TList.Create;
  Parts := TStringList.Create;
  Range := TStringList.Create;
  try
    S := StringReplace(Input, ' ', '', [rfReplaceAll]);
    S := StringReplace(S, ';', ',', [rfReplaceAll]);
    Parts.Delimiter := ',';
    Parts.DelimitedText := S;

    for i := 0 to Parts.Count - 1 do
    begin
      if PosBMH('-', Parts[i]) > 0 then
      begin
        Range.Delimiter := '-';
        Range.DelimitedText := Parts[i];
        if Range.Count = 2 then
        begin
          V1 := StrToInt64Def(Range[0], 0);
          V2 := StrToInt64Def(Range[1], 0);
          for j := Min(V1, V2) to Max(V1, V2) do
            if j > 0 then Result.Add(Pointer(j));
        end;
      end
      else if Trim(Parts[i]) <> '' then
        Result.Add(Pointer(StrToInt64Def(Parts[i], 0)));
    end;
  finally
    Parts.Free;
    Range.Free;
  end;
end;

procedure TExportFileThread.Execute;
const
  INDEX_REC_SIZE = 20;
  MAX_LINE_LEN = 2 * 1024 * 1024;
var
  TargetLines: TList;
  i: Integer;
  LineNum: Int64;
  DestWriter: TBufferedTextWriter;
  MMF: TMMFReader;
  IdxStream: TFileStream;
  IndexFileName: String;
  OffsetStr: AnsiString;
  StartOffset, EndOffset, ReadPos: Int64;
  FSize: Int64;
  LineLength: Integer;
  Buffer: AnsiString;
  P: PByte;
  Contiguous: Cardinal;
begin
  TargetLines := ParseLines(FLineParams);
  DestWriter := nil;
  MMF := nil;
  IdxStream := nil;
  IndexFileName := FastFileExeDirPath(TEMPFILE);
  try
    try
      MMF := TMMFReader.Create(FSourceFileName);
      IdxStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
      FSize := MMF.FileSize;
      SetLength(OffsetStr, 18);

      if FSaveToFile then
        DestWriter := TBufferedTextWriter.Create(FOutputFileName, 4 * 1024 * 1024);

      for i := 0 to TargetLines.Count - 1 do
      begin
        if Terminated then Break;
        LineNum := Int64(TargetLines[i]);
        if (LineNum < 1) or (LineNum > FTotalLines) then Continue;

        // Read start offset from index
        IdxStream.Seek(Int64(LineNum - 1) * INDEX_REC_SIZE, soFromBeginning);
        IdxStream.Read(Pointer(OffsetStr)^, 18);
        StartOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
        if StartOffset = -1 then
        begin
          if FSaveToFile then
            DestWriter.WriteLine('')
          else
            FResultList.Add('');
          Continue;
        end;
        StartOffset := Abs(StartOffset);

        // Read end offset (next line's offset or EOF)
        if (Int64(LineNum) * INDEX_REC_SIZE) < IdxStream.Size then
        begin
          IdxStream.Seek(Int64(LineNum) * INDEX_REC_SIZE, soFromBeginning);
          IdxStream.Read(Pointer(OffsetStr)^, 18);
          EndOffset := StrToInt64Def(Trim(string(OffsetStr)), FSize + 1);
        end
        else
          EndOffset := FSize + 1;
        EndOffset := Abs(EndOffset);

        LineLength := EndOffset - StartOffset;
        if LineLength <= 0 then
        begin
          if FSaveToFile then
            DestWriter.WriteLine('')
          else
            FResultList.Add('');
          Continue;
        end;
        if LineLength > MAX_LINE_LEN then LineLength := MAX_LINE_LEN;

        // Read raw bytes via own MMF
        ReadPos := StartOffset - 1;
        SetLength(Buffer, LineLength);
        P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
        if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
          Move(P^, Pointer(Buffer)^, LineLength)
        else
          MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);

        // Strip trailing CR/LF
        while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
          SetLength(Buffer, Length(Buffer) - 1);

        if FSaveToFile then
          DestWriter.WriteLine(Buffer)
        else
          FResultList.Add(string(Buffer));

        if TargetLines.Count > 0 then
          FPercent := Round(((i + 1) / TargetLines.Count) * 100)
        else
          FPercent := 100;
        TfrmSmoothLoading.PostProgressFromWorker(FPercent);
      end;

      if (not FSaveToFile) then
        Synchronize(SyncClipboard);

      Synchronize(SyncFinish);
    except
      on E: Exception do
        LogAsync(Format('Log_FastFile%s.txt', [FormatDateTime('ddmmyyyyhhnn', Now)]),
          '[ExportFileThread] ' + E.Message);
    end;
  finally
    if Assigned(DestWriter) then FreeAndNil(DestWriter);
    FreeAndNil(IdxStream);
    FreeAndNil(MMF);
    TargetLines.Free;
  end;
end;

{ ===== Anti-flicker helpers ===== }

constructor TfrmSmoothLoadingForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackgroundBmp := TBitmap.Create;
  FLastPaintedProgress := -1;
  // Fade-in padrão (ms)
  FFadeInActive := False;
  FFadeDurationMS := 1200;
  FFadeStartAlpha := 20;
  FFadeEndAlpha := 230; // mantém o visual atual
end;

destructor TfrmSmoothLoadingForm.Destroy;
begin
  FreeAndNil(FBackgroundBmp);
  inherited Destroy;
end;

procedure TfrmSmoothLoadingForm.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  // Evita o "apagão" de fundo (flicker) antes do repaint
  Msg.Result := 1;
end;

procedure TfrmSmoothLoadingForm.ApplySmoothProgress(Percent: Integer);
var
  R: TRect;
begin
  FIsDeterminate := True;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  FTargetProgress := Percent;
  FCurrentProgress := Percent;
  FLastPaintedProgress := Percent;
  pbProgressBar.Repaint;
  if Assigned(pnlContainer) then
  begin
    R := pbProgressBar.BoundsRect;
    OffsetRect(R, pnlContainer.Left, pnlContainer.Top);
    InvalidateRect(Handle, @R, False);
    UpdateWindow(Handle);
  end;
end;

procedure TfrmSmoothLoadingForm.WMSmoothProgress(var Msg: TMessage);
begin
  ApplySmoothProgress(Msg.WParam);
  Msg.Result := 0;
end;

procedure TfrmSmoothLoadingForm.BuildBackground;
var
  Row: Integer;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  FBackgroundBmp.PixelFormat := pf24bit;
  FBackgroundBmp.Width := ClientWidth;
  FBackgroundBmp.Height := ClientHeight;

  // Gradiente de fundo (desenhado 1x e cacheado)
  for Row := 0 to ClientHeight do
  begin
    FBackgroundBmp.Canvas.Pen.Color := RGB(20 + MulDiv(Row, 10, ClientHeight),
                                           30 + MulDiv(Row, 15, ClientHeight),
                                           50 + MulDiv(Row, 30, ClientHeight));
    FBackgroundBmp.Canvas.MoveTo(0, Row);
    FBackgroundBmp.Canvas.LineTo(ClientWidth, Row);
  end;
end;

procedure TfrmSmoothLoadingForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
    // WS_EX_COMPOSITED removido: causava flicker com AlphaBlend/atualização por timer
end;

procedure TfrmSmoothLoadingForm.ForceFullScreen;
begin
  // Força o formulário a ocupar a área total do monitor principal
  Self.Left := 0;
  Self.Top := 0;
  Self.Width := Screen.Width;
  Self.Height := Screen.Height;
end;

procedure TfrmSmoothLoadingForm.pbProgressBarPaint(Sender: TObject);
var
  W, H, BarW: Integer;
begin
  W := pbProgressBar.Width;
  H := pbProgressBar.Height;
  pbProgressBar.Canvas.Brush.Color := $00504C3C;
  pbProgressBar.Canvas.FillRect(Rect(0, 0, W, H));
  BarW := Round((W * FCurrentProgress) / 100);
  pbProgressBar.Canvas.Brush.Color := $00FFDB80;
  pbProgressBar.Canvas.FillRect(Rect(0, 0, BarW, H));
end;

class procedure TfrmSmoothLoading.ShowLoading(const MessageText: String);
begin
  if not Assigned(frmSmoothLoading) then
    frmSmoothLoading := TfrmSmoothLoadingForm.Create(Application);

  // 1. Configurações de estado inicial (ainda invisível)
  frmSmoothLoading.AlphaBlend := True;
  // Fade-in suave: começa mais transparente e vai até o alpha "normal"
  frmSmoothLoading.FFadeEndAlpha := 230; // mantém o visual atual
  frmSmoothLoading.AlphaBlendValue := frmSmoothLoading.FFadeStartAlpha;
  frmSmoothLoading.FFadeInActive := True;
  frmSmoothLoading.FFadeStartTick := GetTickCount;
  { Ver comentário em uSmoothLoading.pas ShowLoading: evita barra cheia
    antes do primeiro UpdateProgress (timer 15 ms + modo indeterminado). }
  frmSmoothLoading.FIsDeterminate := True;
  frmSmoothLoading.FCurrentProgress := 0;
  frmSmoothLoading.FTargetProgress := 0;
  frmSmoothLoading.lblMessage.Caption := MessageText;

  // 2) Força fullscreen antes de mostrar
  frmSmoothLoading.ForceFullScreen;

  frmSmoothLoading.Show;
  
  // 3. Posicionamento e arredondamento
  frmSmoothLoading.CenterContainer;
  frmSmoothLoading.RoundControl(frmSmoothLoading.pnlContainer, 50);
  
  frmSmoothLoading.tmrAnimation.Enabled := True;
  frmSmoothLoading.lblMessage.Font.Color := $00FFF0E6;
  
  // Força o Windows a processar a exibição imediatamente
  // Application.ProcessMessages removed to avoid hangs
end;

procedure TfrmSmoothLoadingForm.tmrAnimationTimer(Sender: TObject);
var
  Elapsed: Cardinal;
  NewAlpha: Integer;
begin
  // Fade-in suave (opcional) ao exibir
  if FFadeInActive then
  begin
    Elapsed := GetTickCount - FFadeStartTick;
    if (FFadeDurationMS = 0) then
      NewAlpha := FFadeEndAlpha
    else
      NewAlpha := FFadeStartAlpha +
        Round((FFadeEndAlpha - FFadeStartAlpha) * (Elapsed / FFadeDurationMS));   


    if NewAlpha >= FFadeEndAlpha then
    begin
      AlphaBlendValue := FFadeEndAlpha;
      FFadeInActive := False;
    end
    else if NewAlpha <= 1 then
      AlphaBlendValue := 2 // nunca deixe "invisível" total
    else
      AlphaBlendValue := Byte(NewAlpha);
  end;

  if not FIsDeterminate then
  begin
    FCurrentProgress := FCurrentProgress + 1.5;
    if FCurrentProgress > 100 then FCurrentProgress := 0;
  end
  else
  begin
    if Abs(FCurrentProgress - FTargetProgress) > 0.1 then
      FCurrentProgress := FCurrentProgress + (FTargetProgress - FCurrentProgress) * 0.15;
  end;

  if (not FIsDeterminate) or (Abs(FCurrentProgress - FTargetProgress) > 0.1) then
  begin
    if Abs(FLastPaintedProgress - FCurrentProgress) > 0.2 then
    begin
      FLastPaintedProgress := FCurrentProgress;
      pbProgressBar.Invalidate;
    end;
    if not FIsDeterminate then
      pbProgressBar.Invalidate;
  end;
end;

class procedure TfrmSmoothLoading.UpdateProgress(Percent: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  if GetCurrentThreadId = MainThreadID then
    frmSmoothLoading.ApplySmoothProgress(Percent)
  else if frmSmoothLoading.HandleAllocated then
    SendMessage(frmSmoothLoading.Handle, WM_APP + 77, WPARAM(Percent), 0);
end;

procedure TfrmSmoothLoadingForm.FormPaint(Sender: TObject);
var Row: Integer;
begin
  // Gradiente de fundo
  for Row := 0 to ClientHeight do
  begin
    Canvas.Pen.Color := RGB(20 + MulDiv(Row, 10, ClientHeight), 
                            30 + MulDiv(Row, 15, ClientHeight), 
                            50 + MulDiv(Row, 30, ClientHeight));
    Canvas.MoveTo(0, Row);
    Canvas.LineTo(ClientWidth, Row);
  end;
end;

procedure TfrmSmoothLoadingForm.CenterContainer;
begin
  if Assigned(pnlContainer) then
  begin
    pnlContainer.Left := (Self.ClientWidth - pnlContainer.Width) div 2;
    pnlContainer.Top := (Self.ClientHeight - pnlContainer.Height) div 2;
  end;
end;

procedure TfrmSmoothLoadingForm.RoundControl(Control: TWinControl; Radius: Integer);
var Rgn: HRGN;
begin
  Rgn := CreateRoundRectRgn(0, 0, Control.Width + 1, Control.Height + 1, Radius, Radius);
  SetWindowRgn(Control.Handle, Rgn, True);
end;

procedure TfrmSmoothLoadingForm.LoadLogo;
var PathLogo: String;
begin
  PathLogo := ExtractFilePath(Application.ExeName) + 'logo.bmp';
  if FileExists(PathLogo) then imgLogo.Picture.LoadFromFile(PathLogo);
end;

class procedure TfrmSmoothLoading.HideLoading;
begin
  if Assigned(frmSmoothLoading) then
  begin
    frmSmoothLoading.tmrAnimation.Enabled := False;
    FreeAndNil(frmSmoothLoading);
  end;
end;

procedure TfrmSmoothLoadingForm.FormShow(Sender: TObject);
begin
  ApplyTranslationsToForm(Self);
  // Reforça o tamanho total
  Self.BoundsRect := Screen.DesktopRect;
  LoadLogo;
  CenterContainer;
  // Dá um "toque" no Windows para pintar o fundo
  Self.Repaint;
end;

procedure TfrmSmoothLoadingForm.FormResize(Sender: TObject);
begin
  CenterContainer;
  // Não chamamos Repaint aqui para evitar loops, Invalidate é suficiente
  Invalidate;
end;

end.
