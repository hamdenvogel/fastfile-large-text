unit uSmoothLoading;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, DateUtils, Math, ClipBrd, CommCtrl,
  uLineEditor, uMMF, UnBufferedTextWriter, uPosBMH;

type
  TfrmSmoothLoadingForm = class(TForm)
    pnlContainer: TPanel;
    imgLogo: TImage;
    lblMessage: TLabel;
    lblDetail: TLabel;
    tmrAnimation: TTimer;
    pbProgressBar: TPaintBox;
    btnCancel: TBitBtn;
    procedure tmrAnimationTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure pbProgressBarPaint(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FCurrentProgress: Double;
    FTargetProgress: Double;
    FIsDeterminate: Boolean;
    FMarqueePos: Double;
    FMarqueeDir: Integer;
    FLastPaintedProgress: Double;
    FBackgroundBmp: TBitmap;
    // Fade-in suave ao exibir
    FFadeInActive: Boolean;
    FFadeStartTick: Cardinal;
    FFadeDurationMS: Cardinal;
    FFadeStartAlpha: Byte;
    FFadeEndAlpha: Byte;
    FFormCornerRadius: Integer;
    FRoundRgnPending: Boolean;
    procedure BuildBackground;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure ApplySmoothProgress(Percent: Integer);
    procedure ApplySmoothProgressEx(Percent: Double);
    procedure WMSmoothProgress(var Msg: TMessage); message WM_APP + 77;
    procedure WMSmoothProgressDetail(var Msg: TMessage); message WM_APP + 78;
    procedure WMSmoothDetailOnly(var Msg: TMessage); message WM_APP + 79;
    procedure CenterContainer;
    procedure AdjustLoadingMessageLayout(const MessageText: string);
    procedure LayoutCancelButton;
    procedure RoundControl(Control: TWinControl; Radius: Integer);
    procedure ApplyFormRoundCorners(Radius: Integer);
    procedure ApplyCancelButtonLook;
    procedure WMShowWindow(var Msg: TWMShowWindow); message WM_SHOWWINDOW;
    procedure WMFfApplyRoundRgn(var Msg: TMessage); message WM_APP + 120;
    procedure WMActivateApp(var Msg: TWMActivateApp); message WM_ACTIVATEAPP;
    procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;
    procedure WMWindowPosChanged(var Msg: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure QueueReapplyRoundRegions;
    procedure ReapplyRoundRegions;
    procedure PaintBackgroundTo(DC: HDC);
    procedure LoadLogo;
    procedure ForceFullScreen;
    procedure SnapFullyOpaque;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyDetailLabelLook;
      // Opera��es centralizadas (threads agora ficam nesta unit)
end;



type
  TSmoothLoadingMode = (slmReadFile, slmEditFile, slmExportLines);

  // Thread controladora: esta � a "TfrmSmoothLoading" solicitada
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

    // API p�blica (mant�m compatibilidade com o projeto)
    class procedure ShowLoading(const MessageText: String); overload;
    { AStayOnTop=False: overlay nao WS_EX_TOPMOST (Alt+Tab / outras apps menos "presas" durante carga longa). }
    class procedure ShowLoading(const MessageText: String; AStayOnTop: Boolean); overload;
    { AOwner=form modal (ex. compare/merge): overlay como filho logico do form evita bloqueio da fila de mensagens. }
    class procedure ShowLoading(AOwner: TComponent; const MessageText: String; AStayOnTop: Boolean = True); overload;
    { Overlay with pulsing bar (no known %). Reuses an already-visible overlay. }
    class procedure ShowWait(const MessageText: String; AStayOnTop: Boolean = False);
    class function IsShowing: Boolean;
    class procedure SetIndeterminate(AOn: Boolean);
    class procedure SetWaitTexts(const MessageText, DetailText: string);
    class procedure HideLoading;
    class procedure UpdateProgress(Percent: Integer);
    { Never moves the bar backwards (assistant wait / HTTP phases). }
    class procedure UpdateProgressMonotonic(Percent: Integer);
    { Slow forward-only creep toward AMaxPercent while duration is unknown. }
    class procedure CreepProgress(AMaxPercent: Integer);
    { Chamada a partir de threads de trabalho: PostMessage (nao bloqueia a worker na UI).
      UpdateProgress usa SendMessage fora da main ? util para outras threads; esta API evita
      acumular Synchronize na fila do Application durante cargas longas (ex.: historico merge). }
    class procedure PostProgressFromWorker(Percent: Integer);
    { Permille 0..1000 (ex.: 543 = 54,3%%) para animacao suave entre inteiros. }
    class procedure PostProgressFineFromWorker(Permille: Integer);
    { Posts progress + detail to the UI thread without Synchronize.
      Detail is passed as a heap PChar in lParam and disposed in the form handler. }
    class procedure PostProgressWithDetailFromWorker(Percent: Integer; const Detail: string);
    { Updates overlay detail text only (does not move the progress bar). }
    class procedure PostDetailFromWorker(const Detail: string);
    class procedure UpdateProgressWithDetail(Percent: Integer; const Detail: string);
    { Forces an immediate repaint of the loading form, bypassing deferred WM_PAINT.
      Call this after ShowLoading/UpdateProgress when the main thread is about to
      enter a blocking loop (no message pump). }    
    class procedure FlushPaint;
    { Overlay solido (sem AlphaBlend) — visivel de imediato no chat / waits longos. }
    class procedure SnapFullyOpaque;
    { Barra sem animacao lenta (macro/script em ficheiros enormes). }
    class procedure BeginScriptEngineProgress;
    class procedure EndScriptEngineProgress;
    class procedure RequestCancel;
    class function  CancelRequested: Boolean;
    class procedure ResetCancel;
    { For blocking UI-thread work: dispatches only mouse input aimed at the overlay
      (so its Cancel button works) and treats ESC as cancel. Input for other
      windows is discarded. Returns CancelRequested. }
    class function PumpCancelInput: Boolean;
    { Long UI-thread loops (language switch): throttled animation + progress
      creep toward AMaxPercent + overlay-only input. Returns CancelRequested. }
    class function KeepAlive(AMaxPercent: Integer): Boolean;
    { Language switch (and similar UI-only waits): hide Cancel; not abortable. }
    class procedure SetCancelVisible(AVisible: Boolean);
    { Bloqueio cooperativo de TReadFileThread durante replace/delete pesado (nao altera CancelRequested). }
    class procedure SetHeavyFileMutateHold(AActive: Boolean);
    class function  HeavyFileMutateHoldActive: Boolean;
    class function  IndexReadShouldStop: Boolean;
  end;

const
  //INFO_FILE_TIME = 'Filename: %s. Time to read: %s millisecs. Total lines: %d. Total Characters: %d';
  INFO_FILE_TIME = 'Time to read: %s millisecs. Total lines: %d.';
  INFO_EDIT_TIME = 'Time to execute that operation: %s millisecs.';

  OUT_BUFFER_SIZE   = 65536;
  INDEX_RECORD_SIZE = 20;
  { Sparse checkpoint interval: one checkpoint entry every CKPT_INTERVAL lines.
    temp_ckpt.txt stores these at 20 bytes each (same format as temp.txt).
    For 1 billion lines, temp_ckpt.txt = ~19 MB vs ~20 GB for the dense index. }
  CKPT_INTERVAL = 1024;
  { Acima deste tamanho: apenas temp_ckpt.txt (sem temp.txt denso) � scan SWAR mais rapido em ficheiros GB. }
  DENSE_INDEX_MAX_BYTES = Int64(2) * 1024 * 1024 * 1024;

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
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    fileName: string;
    FTotalSize: Int64;
    FBytesRead: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    totalLines: Int64;
    totalCharacters: Int64;
    FAutoDeleteDenseIndex: Boolean;  // if file > 2GB, auto-delete temp.txt after indexing
    FIsUltraLargeFile: Boolean;
    // if file > 500GB, disable word wrap
    FHitLineLimit: Boolean;
    FSkipDenseIndex: Boolean;       { > DENSE_INDEX_MAX_BYTES: ckpt esparso; nao e Zero Scan. }
    FZeroScanOnDemandIndex: Boolean; { True: indexacao sob demanda apos abertura instantanea }
    FIndexFailed: Boolean;
    FIndexErrorMsg: string;

    procedure SyncShowAirbagWarning;
    procedure SyncOfferReadFallback;
    procedure SyncReadCancelled;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    function TimerResult: string;
    procedure SyncFinishFileNameRead;
    procedure FinishThreadExecution;
    procedure SyncProgress;
  protected
    procedure Execute; override;
  public
    constructor Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AHeader: String = ''; const AFooter: String = ''; const AZeroScanOnDemandIndex: Boolean = False);
    destructor Destroy; override;
  end;

  { OCP extension: same as TReadFileThread but never shows the loading overlay.
    Use this when the caller already manages its own progress UI (e.g. after a
    batch-delete operation), so that the Synchronize(SyncShowLoading) call that
    would otherwise trigger SetWindowRgn / AlphaBlend on a partially-initialized
    window is completely avoided. TReadFileThread itself is NOT modified. }
  TReadFileThreadNoUI = class(TReadFileThread)
  public
    constructor Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean = True);
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
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FFileName: String;
    FDeltaFileName: String;
    FTotalSize: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
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
    constructor Create(const AFileName, ADeltaFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AHeader: String = ''; const AFooter: String = '');
    destructor Destroy; override;
  end;

  { Atualiza temp.txt apos inserir/apagar UMA linha (sem reindexar o ficheiro GB+). }
  TSingleLineIndexPatchThread = class(TThread)
  private
    FFileName: string;
    FOp: TOperationType;
    FTargetLine: Int64;
    FDeltaBytes: Int64;
    FSuccess: Boolean;
    FErrorMsg: string;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName: string; const AOp: TOperationType;
      const ATargetLine: Int64; const ADeltaBytes: Int64);
  end;

  TEditFileThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FFileName: String;
    FOperation: TOperationType;
    FTargetLine: Int64;
    FContent: String;
    FOldLineText: String;
    FTotalSize: Int64;
    FBytesProcessed: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    { Ultimo progresso sincronizado em mil-esimos (0..1000); mais passos que % inteiro. }
    FLastProgressThousandths: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    FQuietFinish: Boolean;
    FIsRawContent: Boolean;
    FEncoding: string;
    { V�rias linhas num �nico otInsert (ex.: Shift+Insert com clipboard multilinha). }
    FInsertLines: TStringList;
    { 0=colar, 1=autofill coluna Linha #, 2=inserir multiplas (dialogo). }
    FBatchInsertKind: Integer;
    { otDelete: apagar N linhas consecutivas a partir de FTargetLine (undo de colagem). }
    FSpanLineCount: Integer;
    FFileSizeBefore: Int64;
    FFileSizeAfter: Int64;
    FOutputLineCount: Int64;
    { Linhas efectivamente escritas (memo multilinha / WriteContentLines). }
    FWrittenLineCount: Integer;

    function ResolveEditEncoding: string;
    function ShouldOmitLineForDelete(const ACurrentLine: Int64): Boolean;
    function WriteInsertLines(DestWriter: TBufferedTextWriter): Integer;
    { otEdit/otReplace: FContent pode ter varias linhas (memo). }
    function WriteContentLines(DestWriter: TBufferedTextWriter): Integer;
    function EncodeEditText(const S: string): AnsiString;
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
    const AutoHide: Boolean = True; const ShowUI: Boolean = True;
    const AFreeOnTerminate: Boolean = True; const AQuietFinish: Boolean = False;
    const AIsRawContent: Boolean = False; const AInsertLines: TStringList = nil;
    const ASpanLineCount: Integer = 1; const ABatchInsertKind: Integer = 0);
    destructor Destroy; override;
    property EditSucceeded: Boolean read FSuccess;
    property EditErrorMsg: String read FErrorMsg;
    class function RunEditWait(const AFileName: String; const Op: TOperationType;
      const LineNum: Int64; const Txt: String; const AIsRawContent: Boolean = False;
      const AQuietFinish: Boolean = True): Boolean;
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
    FErrMsg: string;

    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncClipboard;
    procedure SyncFinish;
    procedure SyncError;
    function ParseLines(const Input: String): TList;
  protected
    procedure Execute; override;
  public
    constructor Create(const ALineParams: String; const ASaveToFile: Boolean; const AOutputFileName: String;
    const ASourceFileName: String; const ATotalLines: Int64;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AHeader: String = ''; const AFooter: String = '');
    destructor Destroy; override;
  end;

  { Exporta intervalo de linhas (Tail) com TBufferedTextWriter + progresso (sem TStringList). }
  TTailExportThread = class(TThread)
  private
    FOwner: TObject;
    FIncludeMacroResults: Boolean;
    FFromLine1, FToLine1, FTotalLines: Int64;
    FOutputFileName, FSourceFileName: String;
    FAutoHide, FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet, FPercent: Integer;
    FExportedCount: Int64;
    FCancelled, FSuccess: Boolean;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFromLine1, AToLine1, ATotalLines: Int64;
      const AOutputFileName, ASourceFileName: String;
      AOwner: TObject; AIncludeMacroResults: Boolean;
      const AutoHide: Boolean = True; const ShowUI: Boolean = True);
  end;

  TReplaceAllThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FFileName: String;
    FFindText: String;
    FReplaceText: String;
    FEncoding: string;
    FFindBytes: AnsiString;
    FReplaceBytes: AnsiString;
    FCaseSensitive: Boolean;
    FWholeWord: Boolean;
    FTotalSize: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    FReplacedCount: Int64;
    FReplacedCountSync: Int64;
    FReplaceLimitHit: Boolean;
    FDetailSync: string;
    FSegmented: Boolean;
    FIndexFileName: string;
    FLinesPerSegment: Integer;
    FOutputOverride: string;
    FSilent: Boolean;
    function TrySegmentedReplace: Boolean;
    
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncReleaseSourceHandles;
    procedure SyncCloseHandlesBeforeRename;
    function GetReplaceOutputTarget: string;
    function CommitReplaceOutputOnWorker: Boolean;
    procedure FinishThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName, AFindText, AReplaceText: String;
      const ACaseSensitive, AWholeWord: Boolean;
      const AutoHide: Boolean = True; const ShowUI: Boolean = True;
      const ASegmented: Boolean = False; const AIndexFileName: string = '';
      const ALinesPerSegment: Integer = 250000;
      const AOutputOverride: string = '';
      const ASilent: Boolean = False;
      const AFreeOnTerminate: Boolean = True);
    destructor Destroy; override;
    property ReplacedTotal: Int64 read FReplacedCountSync;
    property OperationSucceeded: Boolean read FSuccess;
    property LastErrorMsg: string read FErrorMsg;
  end;

  TSplitEntry = record
    ID: Integer;
    FileName: String;
    SourceLine: Int64;
    TargetLine: Int64;
  end;
  TSplitEntryArray = array of TSplitEntry;

  TSplitFileThread = class(TThread)
  private
    FShowLoadingUI: Boolean;
    FAutoHide: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FWordWrap: Boolean;
    FMaxChars: Integer;
    CharCount: Integer;
    FOriginalFileName: String;
    FOutputDir: String;
    FEntries: TSplitEntryArray;
    FEntryCount: Integer;
    FHeader: String;
    FFooter: String;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTimerResult: String;
    
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOriginalFileName: String; const AOutputDir: String; const AEntries: TSplitEntryArray; const AEntryCount: Integer; const AHeader: String = ''; const AFooter: String = '');
    destructor Destroy; override;
  end;

  { Defines how a regex is applied to each line when processing a file.
    roSplit   ? current behaviour: open a new output file when a line matches.
    roMatch   ? extract all regex matches from each line (like JS match).
    roTest    ? write "true" / "false" for every line (like JS test).
    roReplace ? apply regex Replace to every line (like JS replace).
    roFilter  ? keep only lines where the regex matches (like JS filter). }
  TRegexOp = (roSplit, roMatch, roTest, roReplace, roFilter);

  TSplitByPatternThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FSourceFileName: String;
    FPattern: String;
    FIsRegex: Boolean;
    FHeader: String;
    FFooter: String;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FSuccessOutputDir: String;
    FSuccessFirstPath: String;
    FSuccessLastPath: String;
    FPartCount: Integer;
    { Regex operation mode (for non-split ops) }
    FRegexOp: TRegexOp;
    FReplacement: String;
    FGlobal: Boolean;
    FIgnoreCase: Boolean;
    { Output path used by single-file regex ops }
    FResultOutputPath: String;
    
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASourceFileName, APattern: String; const AIsRegex: Boolean;
      const AutoHide: Boolean = True; const ShowUI: Boolean = True;
      const AHeader: String = ''; const AFooter: String = '';
      const ARegexOp: TRegexOp = roSplit; const AReplacement: String = '';
      const AGlobal: Boolean = False; const AIgnoreCase: Boolean = True);
    destructor Destroy; override;
  end;

  TMergeFilesThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FDestinationFileName: String;
    FSourceFileName: String;
    FInsertOffset: Int64;
    FFromLine: Int64;
    FToLine: Int64;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FProgressPostMb: Int64;
    FSuccess: Boolean;
    FErrorMsg: String;
    FTempFileName: String;
    FBackupPath: String;
    
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure FinishThread;
  protected
    procedure Execute; override;
  public
    constructor Create(const ADestinationFileName, ASourceFileName: String;
      const AInsertOffset: Int64; const AutoHide: Boolean = True;
      const ShowUI: Boolean = True; const AFromLine: Int64 = 0;
      const AToLine: Int64 = 0);
    destructor Destroy; override;
  end;

  { Reune .part001..N em um unico destino (concatenacao sequencial). }
  TJoinEqualSplitPartsThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FDestinationFileName: String;
    FPartPaths: TStringList;
    FPartCount: Integer;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FProgressPostMb: Int64;
    FSuccess: Boolean;
    FCancelled: Boolean;
    FErrorMsg: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const ADestinationFileName: String; APartPaths: TStrings;
      const AutoHide: Boolean = True; const ShowUI: Boolean = True);
    destructor Destroy; override;
  end;

  { Divide arquivo em N partes com contagem de linhas (LF #10) equilibrada;
    leitura via MMF + busca BMH (uPosBMH); nunca corta no meio de uma linha. }
  TSplitEqualPartsThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FSourceFileName: String;
    FPartCount: Integer;
    FTotalLines: Int64;
    FHeader: String;
    FFooter: String;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FSuccessOutputDir: String;
    FSuccessFirstPath: String;
    FSuccessLastPath: String;
    
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASourceFileName: String; const APartCount: Integer;
      const ATotalLines: Int64; const AutoHide: Boolean = True; const ShowUI: Boolean = True;
      const AHeader: String = ''; const AFooter: String = '');
    destructor Destroy; override;
  end;

  { Extrai uma ou mais fracoes (ex. 3/8, 4/8) com as mesmas fronteiras LF que partes iguais. }
  TSplitFileFractionThread = class(TThread)
  private
    FAutoHide: Boolean;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    sw: TStopWatch;
    FSourceFileName: String;
    FPartCount: Integer;
    FPartFrom: Integer;
    FPartTo: Integer;
    FTotalLines: Int64;
    FHeader: String;
    FFooter: String;
    FCurrentPercent: Integer;
    FPercentToSync: Integer;
    FSuccess: Boolean;
    FErrorMsg: String;
    FExportedCount: Integer;
    FSuccessOutputDir: String;
    FSuccessFirstPath: String;
    FSuccessLastPath: String;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASourceFileName: String; const APartCount, APartFrom,
      APartTo: Integer; const ATotalLines: Int64; const AutoHide: Boolean = True;
      const ShowUI: Boolean = True; const AHeader: String = ''; const AFooter: String = '');
    destructor Destroy; override;
  end;

  { Zero Scan tit�: conta LF no ficheiro inteiro para Shift+End / �ltima linha f�sica. }
  TZeroScanDiscoverLastLineThread = class(TThread)
  private
    FFileName: String;
    FLineCount: Int64;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncFinish;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFileName: String);
  end;

{ Conta linhas (LF #10) com BMH; buffer na heap. AReportProgress = True na thread de split. }
function FastFileCountLinesLf(const AFileName: String; const AReportProgress: Boolean): Int64;

{ Sufixo traduzido para ficheiros de parte: .parte_1_de_8 (palavras-chave via i18n). }
function FastFileSplitPartFileSuffix(const PartIndex1Based, TotalParts: Integer): String;

{ Line-aligned segments + merge + atomic rename. Returns False if index missing
  or a single segment (caller uses classic in-place deletes). Returns True with
  AErrorMsg set on handled failure or empty on success. }
function TrySegmentedBatchDelete(const FileName, IndexFileName: string;
  const LinesToDelete1Based: array of Int64; LinesPerSegment: Integer;
  out AErrorMsg: string): Boolean;
function CanUseSegmentedBatchDelete(const IndexFileName: string;
  LinesPerSegment: Integer): Boolean;

{ MMF full-scan delete: reads the file via memory-mapped IO, writes every line
  that is NOT in ALinesToDelete1Based to a temp file, then atomically renames
  the temp over the original.  ALinesToDelete1Based must be sorted ascending.
  Returns True on success; False + AErrorMsg on any failure.
  Never calls SetEndOfFile / Stream.Size, so it never raises EOSError.
  Also rebuilds temp_ckpt.txt in the same pass (no second full-file scan). }
function BatchDeleteLinesByMMF(const AFileName: string;
  const ALinesToDelete1Based: array of Int64;
  out AErrorMsg: string; out AFinalLineCount: Int64): Boolean;

var
  frmSmoothLoading: TfrmSmoothLoadingForm;
  FastWordWrapAtivo: Boolean;
  FastWordWrapMaxChars: Integer;
  GLastPostedDetailPtr: PChar = nil;
  GScriptEngineProgressImmediate: Boolean = False;

implementation

{$R *.dfm}

uses
  MainUnit, ThreadFileLog, uI18n, UnUtils, uFileSessionHistory, uFastFilePaths,
  uFastFileNotice, uFastFileMsgDlg, uExportDialog,
  uTemporaryFileStream, uZeroScanBlockIndex, UnConsts, uFileOpenPolicy, uDiskSpaceCheck,
  uTextEncoding, uLineIndexScan, uEolPolicy, ComObj, ActiveX;

type
  TReplaceAllBMHShiftTable = array[0..255] of Integer;

const
  REPLACE_ALL_MATCH_LIMIT = 5000000;
  { QS_ALLINPUT (WinUser): acordar MsgWait quando ha mensagens para Synchronize / pintura. }
  cQS_ALLINPUT_FOR_WAIT = $04FF;
  { Reaplica HRGN ap�s layered/AlphaBlend � SetWindowRgn costuma ser ignorado no 1� paint. }
  WM_FF_APPLYROUNDRGN = WM_APP + 120;

var
  GDownloadCancelled: Boolean = False;
  GHeavyFileMutateHold: Boolean = False;

function NewFastFileTemp(const Tag: string): string;
begin
  Result := uFastFilePaths.FastFileScratchTempPath(Tag);
end;

function NewReplaceScratchTemp(const ASourceFile, ATag: string): string;
begin
  Result := ExpandFileName(uFastFilePaths.FastFileScratchTempPathNearFile(ATag, ASourceFile));
end;

function ForceDeleteScratchPath(const FileName: string): Boolean;
var
  RetryCount: Integer;
begin
  Result := False;
  if not FileExists(FileName) then
  begin
    Result := True;
    Exit;
  end;
  for RetryCount := 1 to 5 do
  begin
    if DeleteFile(FileName) then
    begin
      Result := True;
      Break;
    end;
    Sleep(200);
  end;
  if not Result then
    Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
end;

function TryCreateEmptyScratchFile(const APath: string): Boolean;
var
  FS: TFileStream;
begin
  Result := False;
  if APath = '' then
    Exit;
  try
    FS := TFileStream.Create(APath, fmCreate);
    try
      Result := FileExists(APath);
    finally
      FS.Free;
    end;
  except
    Result := False;
  end;
end;

{ Prefer scratch beside the source (same volume rename). Fall back to fastfile_temp. }
function AllocateReplaceScratchTemp(const ASourceFile: string): string;
var
  NearPath, Fallback: string;
begin
  NearPath := NewReplaceScratchTemp(ASourceFile, 'replace');
  ForceDeleteScratchPath(NearPath);
  if TryCreateEmptyScratchFile(NearPath) then
  begin
    Result := NearPath;
    Exit;
  end;
  Fallback := ExpandFileName(NewFastFileTemp('replace'));
  ForceDeleteScratchPath(Fallback);
  if TryCreateEmptyScratchFile(Fallback) then
  begin
    Result := Fallback;
    Exit;
  end;
  Result := NearPath;
end;

function ReplaceTempOutputReady(const ATempPath: string; out ErrMsg: string): Boolean;
var
  I: Integer;
  FS: TFileStream;
begin
  Result := False;
  ErrMsg := '';
  for I := 1 to 40 do
  begin
    if ATempPath = '' then
      Break;
    if FileExists(ATempPath) then
    begin
      try
        FS := TFileStream.Create(ATempPath, fmOpenRead or fmShareDenyNone);
        try
          Result := True;
        finally
          FS.Free;
        end;
      except
        Result := False;
      end;
      if Result then
        Exit;
    end;
    Sleep(25);
  end;
  if ATempPath <> '' then
    ErrMsg := Format(TrText('Temporary output file was not created.') + ' (%s)', [ATempPath])
  else
    ErrMsg := TrText('Temporary output file was not created.');
end;

function FastFileRuntimeLogPath: string;
begin
  Result := uFastFilePaths.FastFileRuntimeLogPath;
end;

procedure ShowAppMessage(const Msg: string);
begin
  FastFileMsgInfo(TrText(Msg));
end;

function AppMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
begin
  Result := FastFileMessageDlg(TrText(Msg), DlgType, Buttons, HelpCtx);
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
{ TfrmSmoothLoading - opera��es p�blicas }
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
  // Reusa a API p�blica (mant�m singleton do form)
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
        if Assigned(frmMain) then
          Worker := TExportFileThread.Create(FParams, FSaveToFile, FOutFileName,
            frmMain.edtFileName.Text, frmMain.IndexFileLineCount, False);
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

constructor TReadFileThread.Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean; const ShowUI: Boolean; const AHeader: String; const AFooter: String; const AZeroScanOnDemandIndex: Boolean);
begin
  inherited Create(CreateSuspended);
  FZeroScanOnDemandIndex := AZeroScanOnDemandIndex;
  FWordWrap := FastWordWrapAtivo;
  FMaxChars := FastWordWrapMaxChars;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FreeOnTerminate := True;
  fileName := AFileName;

  if FShowLoadingUI then
  begin
    if Trim(AHeader) <> '' then
      FLoadingMsg := TrText(AHeader)
    else
      FLoadingMsg := TrText('Reading file...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;

  sw := TStopWatch.Create;
  sw.Start;
  Priority := tpHigher;
  if Assigned(frmMain) then
    TfrmMain(frmMain).RegisterActiveIndexReadThread(Self);
end;

destructor TReadFileThread.Destroy;
begin
  if Assigned(frmMain) then
    TfrmMain(frmMain).UnregisterActiveIndexReadThread(Self);
  FreeAndNil(sw);
  inherited;
end;

{ TReadFileThreadNoUI }

constructor TReadFileThreadNoUI.Create(const CreateSuspended: Boolean; const AFileName: String; const AutoHide: Boolean);
begin
  inherited Create(CreateSuspended, AFileName, AutoHide, {ShowUI=}False);
end;

procedure TReadFileThread.SyncShowAirbagWarning;
begin
  Windows.MessageBox(0, PChar(TrText('Memory Airbag activated! The file has more than 2 billion lines, exceeding the 32-bit Windows safe limit. Reading was automatically aborted to protect the system from crashing.')), PChar(TrText('Protection Activated (FastFile)')), 48); // 48 = MB_ICONWARNING
end;

procedure TReadFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TReadFileThread.SyncReadCancelled;
begin
  if Assigned(frmMain) then
    frmMain.SetReadCancelledStatus;
end;

procedure TReadFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TReadFileThread.SyncSetProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TReadFileThread.SyncProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FPercentToSync);
end;

{ Leitura sequencial indexada (BeginRead / F5 / reindex pos-edicao / indexacao sob demanda).
  Abertura Instant Zero Scan (>= MaxGbFileIndexed) NAO passa aqui: MainUnit.BeginRead chama
  finishFileNameRead directamente sem TReadFileThread. }
procedure TReadFileThread.Execute;
  var MMF: TMMFReader; P: PByte; Contiguous: Cardinal; AbsOffset: Int64;
    IndexWriter, CkptWriter: TBufferedTextWriter;
    IdxW: TBufferedTextWriter;
    CkptW: TBufferedTextWriter;
    BlkW: TZeroScanBlockIndexWriter;
    IndexFileName, CkptFileName, CkptTempName, DenseTempPath, RenameErr: string;
    CkptTempFile, DenseTempFile: TTemporaryFileStream;
    BlockWriter: TZeroScanBlockIndexWriter;
    LastUIUpdateTick: DWORD;
    LastProgressOffset: Int64;
    FCurrentPermille: Integer;
    ScanSliceOffset: Int64;
    RegionBase, RegionSize, SliceLen: Integer;
    CkptBufSize: Integer;
    LineOff: Int64;
    FSparseCkptOnly: Boolean;
    OnLf: TLineFeedFoundProc;
    UsedParallel: Boolean;
    Bundle: TLineIndexWriterBundle;
    DoProgress: TIndexScanProgressEvent;
    TermByte: Byte;
  begin
    inherited;
    totalLines := 0; FBytesRead := 0; FHitLineLimit := False; FIndexFailed := False;
    FIndexErrorMsg := ''; FCurrentPercent := 0; FCurrentPermille := 0;
    IndexFileName := FastFileExeDirPath(TEMPFILE);
    CkptFileName  := FastFileExeDirPath(TEMP_CKPT_FILE);
    CkptTempName := '';
    DenseTempPath := '';
    MMF := nil; IndexWriter := nil; CkptWriter := nil;
    CkptTempFile := nil; DenseTempFile := nil;
    BlockWriter := nil;
    try
      try
      begin
        UnUtils.TryDeleteFileWithRetry(IndexFileName, 3, 20);
        UnUtils.TryDeleteFileWithRetry(CkptFileName, 3, 20);
        UnUtils.TryDeleteFileWithRetry(FastFileExeDirPath(TEMP_INDEX_META), 3, 20);
        if FZeroScanOnDemandIndex then
          ZeroScanDeleteBlockIndex;
        FTotalSize := UnUtils.GetFileSize(fileName);
        TermByte := LineTermByteForFile(fileName);
        { Keep dense index (temp.txt) whenever it is built: Find/Replace, filter and
          segmented heavy ops rely on it. Previously files >1GB deleted the dense
          index after load, which broke search while the ListView still looked loaded. }
        FAutoDeleteDenseIndex := False;
        FSkipDenseIndex := (FTotalSize > DENSE_INDEX_MAX_BYTES);
        { Alinhado a MAX_GB_FILE_INDEXED (abertura Zero Scan quando > este tamanho). }
        FIsUltraLargeFile := (FTotalSize >= MaxBytesFileIndexed);
        if FZeroScanOnDemandIndex then
        begin
          CkptTempFile := TTemporaryFileStream.CreateForIndex('zsckpt');
          CkptTempName := CkptTempFile.FilePath;
          if FSkipDenseIndex then
            CkptBufSize := 16 * 1024 * 1024
          else
            CkptBufSize := 2 * 1024 * 1024;
          CkptWriter := TBufferedTextWriter.CreateFromHandle(CkptTempFile.Handle, CkptBufSize);
          if not FSkipDenseIndex then
          begin
            DenseTempFile := TTemporaryFileStream.CreateForIndex('zsdense');
            DenseTempPath := DenseTempFile.FilePath;
            IndexWriter := TBufferedTextWriter.CreateFromHandle(DenseTempFile.Handle, 16 * 1024 * 1024);
          end;
        end
        else
        begin
          CkptTempName := NewFastFileTemp('ckpti');
          UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);
          if not FSkipDenseIndex then
            IndexWriter := TBufferedTextWriter.Create(IndexFileName, 16 * 1024 * 1024);
          if FSkipDenseIndex then
            CkptBufSize := 32 * 1024 * 1024
          else
            CkptBufSize := 8 * 1024 * 1024;
          CkptWriter := TBufferedTextWriter.Create(CkptTempName, CkptBufSize);
        end;
        if FZeroScanOnDemandIndex then
          BlockWriter := TZeroScanBlockIndexWriter.Create;
        IdxW := IndexWriter;
        CkptW := CkptWriter;
        BlkW := BlockWriter;
        FSparseCkptOnly := FSkipDenseIndex and (IdxW = nil) and (BlkW = nil);
        if FTotalSize > 0 then
        begin
          if IdxW <> nil then IdxW.WriteOffsetDirect(1);
          CkptW.WriteOffsetDirect(1);
        end;
        AbsOffset := 0;
        LastUIUpdateTick := GetTickCount;
        LastProgressOffset := 0;
        DoProgress := procedure(const AtOffset: Int64)
        const
          READ_PROGRESS_INTERVAL_MS = 45;
          READ_PROGRESS_PERMILLE_CATCHUP = 12;
        var
          NewPermille: Integer;
        begin
          if not FShowLoadingUI then Exit;
          if FTotalSize <= 0 then Exit;
          NewPermille := Integer((AtOffset * 990) div FTotalSize);
          if NewPermille <= FCurrentPermille then Exit;
          if (NewPermille - FCurrentPermille < READ_PROGRESS_PERMILLE_CATCHUP) and
             (GetTickCount - LastUIUpdateTick < READ_PROGRESS_INTERVAL_MS) then Exit;
          FCurrentPermille := NewPermille;
          FCurrentPercent := NewPermille div 10;
          LastProgressOffset := AtOffset;
          LastUIUpdateTick := GetTickCount;
          TfrmSmoothLoading.PostProgressFineFromWorker(NewPermille);
          TfrmSmoothLoading.PostDetailFromWorker(
            Format('%s %s', [TrText('Total lines:'), FormatFloat('#,##0', totalLines)]));
        end;
        OnLf := procedure(const ALfPos0: Int64)
        begin
          Inc(totalLines);
          if FSparseCkptOnly then
          begin
            if (totalLines and (CKPT_INTERVAL - 1)) = 0 then
              CkptW.WriteOffsetDirect(ALfPos0 + 2);
          end
          else
          begin
            LineOff := ALfPos0 + 2;
            if IdxW <> nil then IdxW.WriteOffsetDirect(LineOff);
            if BlkW <> nil then BlkW.NoteLineStart1Based(LineOff, ALfPos0);
            if (totalLines and (CKPT_INTERVAL - 1)) = 0 then
              CkptW.WriteOffsetDirect(LineOff);
          end;
        end;
        UsedParallel := False;
        if FSparseCkptOnly and (FTotalSize > 0) then
        begin
          Bundle.IdxW := nil;
          Bundle.CkptW := CkptW;
          Bundle.BlkW := nil;
          Bundle.SparseCkptOnly := True;
          UsedParallel := TryParallelLineIndexScan(fileName, FTotalSize, totalLines,
            FHitLineLimit, Bundle,
            function: Boolean
            begin
              Result := Terminated or TfrmSmoothLoading.IndexReadShouldStop;
            end,
            DoProgress, TermByte);
        end;
        if not UsedParallel then
        begin
        MMF := TMMFReader.Create(fileName);
        while (AbsOffset < FTotalSize) and (not Terminated)
          and (not TfrmSmoothLoading.IndexReadShouldStop) do
        begin
          P := MMF.PtrAt(AbsOffset, 1, Contiguous);
          if (P = nil) or (Contiguous = 0) then Break;
          RegionSize := Integer(Contiguous);
          RegionBase := 0;
          while RegionBase < RegionSize do
          begin
            SliceLen := RegionSize - RegionBase;
            { 64 MB: AVX2/SWAR numa passagem; progresso da overlay ainda actualiza. }
            if SliceLen > 64 * 1024 * 1024 then
              SliceLen := 64 * 1024 * 1024;
            ScanSliceOffset := AbsOffset + Int64(RegionBase);
            ScanBufferForLineFeeds(PByte(PAnsiChar(P) + RegionBase), SliceLen,
              ScanSliceOffset, OnLf, TermByte);
            Inc(RegionBase, SliceLen);
            DoProgress(AbsOffset + Int64(RegionBase));
            if totalLines >= 2000000000 then
              Break;
          end;
          AbsOffset := AbsOffset + Int64(Contiguous);

          if totalLines >= 2000000000 then
          begin
            FHitLineLimit := True;
            Break;
          end;
        end;
      end;
      DoProgress(FTotalSize);
      end;
      // Application.ProcessMessages removed to avoid hangs
      { Delphi 7: ProcessMessages nao despacha TThread.Synchronize; FinishThreadExecution is enough }
      except
        on E: Exception do
        begin
          FIndexFailed := True;
          FIndexErrorMsg := E.Message;
        end;
      end;
    finally
      if Assigned(IndexWriter) then FreeAndNil(IndexWriter);
      if Assigned(CkptWriter) then FreeAndNil(CkptWriter);
      if Assigned(MMF) then FreeAndNil(MMF);
      if (not Terminated) and (not TfrmSmoothLoading.IndexReadShouldStop) then
      begin
        if FZeroScanOnDemandIndex then
        begin
          if (DenseTempPath <> '') and FileExists(DenseTempPath) then
          begin
            RenameErr := '';
            if UnUtils.TryRenameTempOverTarget(DenseTempPath, IndexFileName, RenameErr) then
              DenseTempPath := '';
          end;
          if (CkptTempName <> '') and FileExists(CkptTempName) then
          begin
            RenameErr := '';
            if UnUtils.TryRenameTempOverTarget(CkptTempName, CkptFileName, RenameErr) then
              CkptTempName := '';
          end;
        end
        else if (CkptTempName <> '') and FileExists(CkptTempName) then
        begin
          RenameErr := '';
          if not UnUtils.TryRenameTempOverTarget(CkptTempName, CkptFileName, RenameErr) then
            UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);
        end;
      end;
      FreeAndNil(DenseTempFile);
      FreeAndNil(CkptTempFile);
      if Assigned(BlockWriter) then
      begin
        if (not Terminated) and (not TfrmSmoothLoading.IndexReadShouldStop) then
          BlockWriter.FinalizeIndex;
        FreeAndNil(BlockWriter);
      end;
    end;
  FinishThreadExecution;
end;

procedure TReadFileThread.FinishThreadExecution;
begin
  if TfrmSmoothLoading.IndexReadShouldStop then
  begin
    sw.Stop;
    if FShowLoadingUI and not TfrmSmoothLoading.HeavyFileMutateHoldActive then
      Synchronize(SyncReadCancelled);
    if FAutoHide and FShowLoadingUI then
      Synchronize(SyncHideLoading);
    TfrmSmoothLoading.ResetCancel;
    if Assigned(frmMain) then
      frmMain.EndFileReloadInProgress;
    Exit;
  end;
  sw.Stop;
  if FHitLineLimit then
    Synchronize(SyncShowAirbagWarning);
  if (FIndexFailed or FHitLineLimit) and (not FZeroScanOnDemandIndex) then
    Synchronize(SyncOfferReadFallback)
  else if Assigned(frmMain) then
    Synchronize(SyncFinishFileNameRead);
  if FAutoHide and FShowLoadingUI then
    Synchronize(SyncHideLoading);
end;

procedure TReadFileThread.SyncOfferReadFallback;
var
  Detail: string;
begin
  if not Assigned(frmMain) then Exit;
  if FHitLineLimit then
    Detail := TrText('Open.IndexFailed.TooManyLines')
  else
    Detail := FIndexErrorMsg;
  TfrmMain(frmMain).HandleReadIndexFailure(fileName, Detail);
end;

function TReadFileThread.TimerResult: string;
begin
  Result := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
end;

procedure TReadFileThread.SyncFinishFileNameRead;
var
  ActualLineCount: Int64;
  Wt: TFileTime;
  DummySize: Int64;
begin
  if FTotalSize > 0 then
    ActualLineCount := totalLines + 1
  else
    ActualLineCount := 0;
  if FShowLoadingUI then
    TfrmSmoothLoading.PostProgressFineFromWorker(1000);
  if (not FIndexFailed) and (not FHitLineLimit) and (FTotalSize > 0) and
     (ActualLineCount > 0) and FileExists(fileName) then
  begin
    UnUtils.GetFileSizeAndWriteTime(fileName, DummySize, Wt);
    SaveLineIndexCache(fileName, FTotalSize, ActualLineCount, Wt);
  end;
  if Assigned(frmMain) then
  begin
    frmMain.RememberFileReadTimer(TimerResult, ActualLineCount);
    frmMain.finishFileNameRead(Format(TrText(INFO_FILE_TIME), [TimerResult, ActualLineCount]),
      ActualLineCount, FTotalSize);
    frmMain.DeleteDenseIndexIfNeeded(FAutoDeleteDenseIndex);
  end;
end;

{ ============================================================================ }
{ THREAD 2: EDI��O }
{ ============================================================================ }

procedure SLWriteIndexRecordAt(AStream: TStream; const ARecordIndex: Int64;
  const AByteOffset: Int64);
var
  J, Digit: Integer;
  TempVal: Int64;
  OffsetBuf: array[0..19] of AnsiChar;
begin
  for J := 0 to 17 do OffsetBuf[J] := ' ';
  TempVal := AByteOffset;
  J := 17;
  repeat
    Digit := TempVal mod 10;
    OffsetBuf[J] := AnsiChar(Byte(Ord('0') + Digit));
    TempVal := TempVal div 10;
    Dec(J);
  until (TempVal = 0) or (J < 0);
  OffsetBuf[18] := #13;
  OffsetBuf[19] := #10;
  AStream.Seek(ARecordIndex * INDEX_RECORD_SIZE, soFromBeginning);
  AStream.Write(OffsetBuf, INDEX_RECORD_SIZE);
end;

function SLReadIndexRecordAt(AStream: TStream; const ARecordIndex: Int64): Int64;
var
  OffsetBuf: array[0..19] of AnsiChar;
  N: Integer;
  S: string;
begin
  Result := -1;
  AStream.Seek(ARecordIndex * INDEX_RECORD_SIZE, soFromBeginning);
  N := AStream.Read(OffsetBuf, INDEX_RECORD_SIZE);
  if N < 18 then Exit;
  SetString(S, PAnsiChar(@OffsetBuf[0]), 18);
  Result := StrToInt64Def(Trim(S), -1);
end;

constructor TSingleLineIndexPatchThread.Create(const AFileName: string;
  const AOp: TOperationType; const ATargetLine: Int64; const ADeltaBytes: Int64);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FOp := AOp;
  FTargetLine := ATargetLine;
  FDeltaBytes := ADeltaBytes;
  FSuccess := False;
  FErrorMsg := '';
  Resume;
end;

procedure TSingleLineIndexPatchThread.SyncFinish;
begin
  if Assigned(frmMain) then
    frmMain.ApplySingleLineIndexPatchDone(FOp, FTargetLine, FDeltaBytes, FSuccess, FErrorMsg);
end;

procedure TSingleLineIndexPatchThread.Execute;
var
  IndexPath: string;
  IndexFile: TFileStream;
  RecordCount, I, L0: Int64;
  Off, Shift, O2: Int64;
begin
  inherited;
  IndexFile := nil;
  try
    IndexPath := FastFileExeDirPath(TEMPFILE);
    if not FileExists(IndexPath) then
    begin
      FErrorMsg := 'Index missing';
      Exit;
    end;
    IndexFile := TFileStream.Create(IndexPath, fmOpenReadWrite or fmShareDenyNone);
    RecordCount := IndexFile.Size div INDEX_RECORD_SIZE;
    if RecordCount <= 0 then
    begin
      FErrorMsg := 'Empty index';
      Exit;
    end;
    L0 := FTargetLine - 1;
    if L0 < 0 then L0 := 0;
    if L0 >= RecordCount then L0 := RecordCount - 1;

    if FOp = otInsert then
    begin
      Shift := FDeltaBytes;
      if Shift <= 0 then
      begin
        FErrorMsg := 'Invalid insert delta';
        Exit;
      end;
      Off := SLReadIndexRecordAt(IndexFile, L0);
      if Off < 1 then Off := 1;
      IndexFile.Size := IndexFile.Size + INDEX_RECORD_SIZE;
      Inc(RecordCount);
      I := RecordCount - 2;
      while I >= L0 do
      begin
        O2 := SLReadIndexRecordAt(IndexFile, I);
        if O2 > 0 then
          SLWriteIndexRecordAt(IndexFile, I + 1, O2 + FDeltaBytes)
        else
          SLWriteIndexRecordAt(IndexFile, I + 1, 1);
        Dec(I);
      end;
      SLWriteIndexRecordAt(IndexFile, L0, Off);
    end
    else if FOp = otDelete then
    begin
      Shift := -FDeltaBytes;
      if Shift <= 0 then
      begin
        FErrorMsg := 'Invalid delete delta';
        Exit;
      end;
      I := L0 + 1;
      while I <= RecordCount - 1 do
      begin
        O2 := SLReadIndexRecordAt(IndexFile, I);
        if O2 > Shift then
          SLWriteIndexRecordAt(IndexFile, I - 1, O2 - Shift)
        else
          SLWriteIndexRecordAt(IndexFile, I - 1, 1);
        Inc(I);
      end;
      IndexFile.Size := IndexFile.Size - INDEX_RECORD_SIZE;
    end
    else
    begin
      FErrorMsg := 'Unsupported op';
      Exit;
    end;
    FSuccess := True;
  except
    on E: Exception do
    begin
      FSuccess := False;
      FErrorMsg := E.Message;
    end;
  end;
  if Assigned(IndexFile) then
    IndexFile.Free;
  Synchronize(SyncFinish);
end;

function TEditFileThread.ShouldOmitLineForDelete(const ACurrentLine: Int64): Boolean;
begin
  if FOperation <> otDelete then
  begin
    Result := False;
    Exit;
  end;
  if FSpanLineCount > 1 then
    Result := (ACurrentLine >= FTargetLine) and
              (ACurrentLine < FTargetLine + FSpanLineCount)
  else
    Result := ACurrentLine = FTargetLine;
end;

function TEditFileThread.ResolveEditEncoding: string;
begin
  Result := FEncoding;
  if Result = '' then
  begin
    if Assigned(frmMain) then
      Result := frmMain.CurrentViewEncoding;
    Result := ResolveTextEncoding(FFileName, Result);
    FEncoding := Result;
  end;
end;

function TEditFileThread.EncodeEditText(const S: string): AnsiString;
begin
  if FIsRawContent then
    Result := AnsiString(S)
  else
    Result := UnicodeTextToFileBytes(S, ResolveEditEncoding);
end;

function TEditFileThread.WriteInsertLines(DestWriter: TBufferedTextWriter): Integer;
var
  I: Integer;
  S: string;
begin
  Result := 0;
  if Assigned(FInsertLines) and (FInsertLines.Count > 0) then
  begin
    for I := 0 to FInsertLines.Count - 1 do
    begin
      S := FInsertLines[I];
      DestWriter.WriteLine(EncodeEditText(S));
      Inc(Result);
    end;
    FWrittenLineCount := Result;
  end
  else
    Result := WriteContentLines(DestWriter);
end;

function TEditFileThread.WriteContentLines(DestWriter: TBufferedTextWriter): Integer;
var
  SL: TStringList;
  I: Integer;
  S: string;
begin
  Result := 0;
  S := string(FContent);
  if (Pos(#10, S) = 0) and (Pos(#13, S) = 0) then
  begin
    DestWriter.WriteLine(EncodeEditText(S));
    Result := 1;
    FWrittenLineCount := 1;
    Exit;
  end;
  SL := TStringList.Create;
  try
    SL.Text := S;
    if SL.Count = 0 then
    begin
      DestWriter.WriteLine(EncodeEditText(''));
      Result := 1;
      FWrittenLineCount := 1;
      Exit;
    end;
    for I := 0 to SL.Count - 1 do
    begin
      DestWriter.WriteLine(EncodeEditText(SL[I]));
      Inc(Result);
    end;
    FWrittenLineCount := Result;
  finally
    SL.Free;
  end;
end;

constructor TEditFileThread.Create(const AFileName: String; const Op: TOperationType; const LineNum: Int64; const Txt: String;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True;
    const AFreeOnTerminate: Boolean = True; const AQuietFinish: Boolean = False;
    const AIsRawContent: Boolean = False; const AInsertLines: TStringList = nil;
    const ASpanLineCount: Integer = 1; const ABatchInsertKind: Integer = 0);
begin
  inherited Create(True);
  FreeOnTerminate := AFreeOnTerminate;
  FFileName := AFileName;
  FOperation := Op;
  FTargetLine := LineNum;
  FContent := Txt;
  FInsertLines := AInsertLines;
  FBatchInsertKind := ABatchInsertKind;
  if ASpanLineCount < 1 then
    FSpanLineCount := 1
  else
    FSpanLineCount := ASpanLineCount;
  FOldLineText := '';
  FQuietFinish := AQuietFinish;
  FIsRawContent := AIsRawContent;
  FEncoding := '';
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    case FOperation of
      otInsert:
        if Assigned(FInsertLines) and (FInsertLines.Count > 1) then
          FLoadingMsg := Format(TrText('Editing file (insert %d lines)...'), [FInsertLines.Count])
        else
          FLoadingMsg := TrText('Editing file (insert)...');
      otReplace: FLoadingMsg := TrText('Editing file (replace)...');
      otDelete:
        if FSpanLineCount > 1 then
          FLoadingMsg := Format(TrText('Editing file (delete %d lines)...'), [FSpanLineCount])
        else
          FLoadingMsg := TrText('Editing file (delete)...');
    else
      FLoadingMsg := TrText('Editing file...');
    end;
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  FWrittenLineCount := 1;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TEditFileThread.Destroy;
begin
  FreeAndNil(FInsertLines);
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
  ShowAppMessage(TrText('Error: ') + FErrorMsg);
end;

procedure TEditFileThread.FinishThread;
var
  TimeStr: String;
  I: Integer;
  LightSpan: Integer;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    if (Trim(FFileName) <> '') and FileExists(FFileName) then
    begin
      case FOperation of
        otInsert:
          if Assigned(FInsertLines) and (FInsertLines.Count > 0) then
          begin
            if FInsertLines.Count = 1 then
              FFHistoryAppendLineOp(FFileName, 'INS', FTargetLine, '', FInsertLines[0])
            else if FBatchInsertKind = 1 then
              FFHistoryAppendBatchAutofill(FFileName, FTargetLine, FInsertLines.Count,
                FInsertLines[0], FInsertLines[FInsertLines.Count - 1])
            else
              FFHistoryAppendBatchInsert(FFileName, FTargetLine, FInsertLines.Count,
                FInsertLines[0], FInsertLines[FInsertLines.Count - 1]);
          end
          else
            FFHistoryAppendLineOp(FFileName, 'INS', FTargetLine, '', FContent);
        otDelete:
          if FSpanLineCount > 1 then
            FFHistoryAppendBatchDelete(FFileName, FTargetLine, FSpanLineCount)
          else
            FFHistoryAppendLineOp(FFileName, 'DEL', FTargetLine, FOldLineText, '');
        otEdit, otReplace:
          FFHistoryAppendLineOp(FFileName, 'EDT', FTargetLine, FOldLineText, FContent);
      end;
      if Assigned(frmMain) then
        frmMain.NotifyHistoryTouched(FFileName);
    end;
    if Assigned(frmMain) then
    begin
      LightSpan := FSpanLineCount;
      if FWrittenLineCount > LightSpan then
        LightSpan := FWrittenLineCount;
      if not frmMain.TryScheduleLightPostEditRefresh(FOperation, FTargetLine,
        LightSpan, FInsertLines, FFileSizeBefore, FFileSizeAfter) then
      begin
        if FOperation = otDelete then
        begin
          if FSpanLineCount > 1 then
            frmMain.ApplyPostBatchDeleteRefresh(FFileName, FOutputLineCount, True, False)
          else if (FFileSizeAfter > Int64(2) * 1024 * 1024 * 1024) or
                  (totalLines > 500000) then
            frmMain.ApplyPostBatchDeleteRefresh(FFileName, FOutputLineCount, False, False)
          else
            frmMain.RequestPostEditRefresh;
        end
        else if FOperation = otInsert then
        begin
          if (LightSpan > 1) or (Assigned(FInsertLines) and (FInsertLines.Count > 1)) then
          begin
            if FOutputLineCount > 0 then
              frmMain.ApplyPostBatchInsertRefresh(FFileName, FOutputLineCount, True, False)
            else
              frmMain.RequestPostEditRefresh;
          end
          else if (FFileSizeAfter > Int64(2) * 1024 * 1024 * 1024) or
                  (totalLines > 500000) then
            frmMain.ApplyPostBatchInsertRefresh(FFileName, FOutputLineCount, False, False)
          else
            frmMain.RequestPostEditRefresh;
        end
        else
          frmMain.RequestPostEditRefresh;
      end;
      if not FQuietFinish then
      begin
        TimeStr := Format(TrText(INFO_EDIT_TIME), [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
        frmMain.AppendOperationTimerLog(TimeStr);
      end;
    end;
  end
  else
  begin
    if not FQuietFinish then
    begin
      if FErrorMsg <> '' then
        ShowAppMessage(TrText('Error: ') + FErrorMsg)
      else
        ShowAppMessage(TrText('Operation failed or cancelled.'));
    end;
    { ApplyEditWithUndo ja fechou streams; em falha e preciso reabrir o ficheiro. }
    if Assigned(frmMain) then
      frmMain.RequestPostEditRefresh;
  end;
  if Assigned(frmMain) then
  begin
    frmMain.CommitPendingEditUndoIfNeeded(FSuccess);
    frmMain.CommitPendingUndoRedoIfNeeded(FSuccess);
  end;
end;

class function TEditFileThread.RunEditWait(const AFileName: String; const Op: TOperationType;
  const LineNum: Int64; const Txt: String; const AIsRawContent: Boolean = False;
  const AQuietFinish: Boolean = True): Boolean;
var
  Th: TEditFileThread;
  H: THandle;
  wr: DWORD;
  ha: array[0..0] of THandle;
  bWaitAll: LongBool;
begin
  Th := TEditFileThread.Create(AFileName, Op, LineNum, Txt, True, False, False, AQuietFinish, AIsRawContent);
  try
    { MsgWaitForMultipleObjects(1,...): MsgWaitForSingleObject nao e' export em todas as user32 (macro C). }
    H := 0;
    bWaitAll := False;
    while True do
    begin
      if H = 0 then
        H := Th.Handle;
      if H <> 0 then
      begin
        ha[0] := H;
        wr := MsgWaitForMultipleObjects(1, ha, bWaitAll, 80, cQS_ALLINPUT_FOR_WAIT);
        if wr = WAIT_OBJECT_0 then
          Break;
        if wr = WAIT_FAILED then
        begin
          wr := WaitForSingleObject(H, 0);
          if wr = WAIT_OBJECT_0 then
            Break;
        end;
      end;
      Application.ProcessMessages;
      while CheckSynchronize do;
      if H = 0 then
        Sleep(2);
    end;
    Result := Th.EditSucceeded;
  finally
    Th.Free;
  end;
end;

procedure TEditFileThread.Execute;
var
  MMF: TMMFReader;
  DestWriter: TBufferedTextWriter;
  P, PLineStart: PAnsiChar;
  Contiguous: Cardinal;
  AbsOffset: Int64;
  CurrentLine: Int64;
  NewPercent: Integer;
  NewTh: Integer;
  ThScaled: Int64;
  i, LineLen, InsN, CkptI: Integer;
  FinalErr: string;
  RawOld: AnsiString;
  InsertDone: Boolean;
  TargetHit: Boolean;
  CkptWriter: TBufferedTextWriter;
  CkptTempName, CkptFileName: string;
  CkptCountdown: Integer;
  OutLineCount: Int64;
  CkptErr: string;
  TermCh: AnsiChar;

  function ForceDeleteFile(const FileName: string): Boolean;
  var
    RetryCount: Integer;
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

  procedure OnKeptLineWritten;
  begin
    Inc(OutLineCount);
    Dec(CkptCountdown);
    if CkptCountdown = 0 then
    begin
      CkptWriter.WriteOffsetDirect(DestWriter.CurrentFileSize + 1);
      CkptCountdown := CKPT_INTERVAL;
    end;
  end;

begin
  inherited;
  // CloseFileStreams removed
  TermCh := LineTermCharForFile(FFileName);
  FTempFileName := NewFastFileTemp('edit');
  ForceDeleteFile(FTempFileName);

  MMF := nil;
  DestWriter := nil;
  CkptWriter := nil;
  CkptTempName := '';
  try
    try
      begin
      MMF := TMMFReader.Create(FFileName);
    FTotalSize := MMF.FileSize;
    FFileSizeBefore := FTotalSize;
    FFileSizeAfter := FTotalSize;
    FOutputLineCount := 0;
    DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024);
    DestWriter.LineBreak := OutputEolForFile(FFileName);
    if FOperation in [otDelete, otInsert] then
    begin
      CkptFileName := FastFileExeDirPath(TEMP_CKPT_FILE);
      CkptTempName := NewFastFileTemp('ckpte');
      UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);
      CkptWriter := TBufferedTextWriter.Create(CkptTempName, 2 * 1024 * 1024);
      CkptCountdown := CKPT_INTERVAL;
      OutLineCount := 0;
      CkptWriter.WriteOffsetDirect(1);
    end;
    CurrentLine := 1;
    AbsOffset := 0;
    InsertDone := False;
    FCurrentPercent := 0;
    FLastProgressThousandths := -100;
    TargetHit := False;

    while (AbsOffset < FTotalSize) and (not Terminated)
      and (not TfrmSmoothLoading.CancelRequested) do
    begin
      P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));
      if (P = nil) or (Contiguous = 0) then Break;

      PLineStart := P;

      for i := 0 to Contiguous - 1 do
      begin
        if P^ = TermCh then
        begin
          LineLen := (P - PLineStart) + 1;

          if (FOperation = otDelete) and ShouldOmitLineForDelete(CurrentLine) then
          begin
            SetLength(RawOld, LineLen);
            if LineLen > 0 then
              Move(PLineStart^, RawOld[1], LineLen);
            { AnsiString + Move: never use UnicodeString here (D10+ would treat bytes as UTF-16). }
            while (Length(RawOld) > 0) and (RawOld[Length(RawOld)] in [#10, #13]) do
              SetLength(RawOld, Length(RawOld) - 1);
            FOldLineText := RawBytesToDisplayString(RawOld);
          end
          else if (CurrentLine = FTargetLine) then
          begin
            case FOperation of
              otInsert: begin
                InsN := WriteInsertLines(DestWriter);
                DestWriter.WriteRaw(PLineStart, LineLen);
                if Assigned(CkptWriter) then
                begin
                  for CkptI := 1 to InsN do
                    OnKeptLineWritten;
                  OnKeptLineWritten;
                end;
                InsertDone := True;
              end;
              otEdit, otReplace: begin
                SetLength(RawOld, LineLen);
                if LineLen > 0 then
                  Move(PLineStart^, RawOld[1], LineLen);
                while (Length(RawOld) > 0) and (RawOld[Length(RawOld)] in [#10, #13]) do
                  SetLength(RawOld, Length(RawOld) - 1);
                FOldLineText := RawBytesToDisplayString(RawOld);
                WriteContentLines(DestWriter);
                TargetHit := True;
              end;
            end;
          end
          else
          begin
            DestWriter.WriteRaw(PLineStart, LineLen);
            if Assigned(CkptWriter) then
              OnKeptLineWritten;
          end;

          Inc(CurrentLine);
          PLineStart := P + 1;
        end;
        Inc(P);
      end;

      AbsOffset := AbsOffset + Contiguous;

      { Ultima linha sem LF final: processar o resto deste view no EOF. }
      if (AbsOffset >= FTotalSize) and (PLineStart < P) and (not Terminated) and
         (not TfrmSmoothLoading.CancelRequested) then
      begin
        LineLen := P - PLineStart;
        if LineLen > 0 then
        begin
          if (FOperation = otDelete) and ShouldOmitLineForDelete(CurrentLine) then
          begin
            SetLength(RawOld, LineLen);
            Move(PLineStart^, RawOld[1], LineLen);
            while (Length(RawOld) > 0) and (RawOld[Length(RawOld)] in [#10, #13]) do
              SetLength(RawOld, Length(RawOld) - 1);
            FOldLineText := RawBytesToDisplayString(RawOld);
          end
          else if CurrentLine = FTargetLine then
          begin
            case FOperation of
              otInsert: begin
                InsN := WriteInsertLines(DestWriter);
                DestWriter.WriteRaw(PLineStart, LineLen);
                if Assigned(CkptWriter) then
                begin
                  for CkptI := 1 to InsN do
                    OnKeptLineWritten;
                  OnKeptLineWritten;
                end;
                InsertDone := True;
              end;
              otEdit, otReplace: begin
                SetLength(RawOld, LineLen);
                Move(PLineStart^, RawOld[1], LineLen);
                while (Length(RawOld) > 0) and (RawOld[Length(RawOld)] in [#10, #13]) do
                  SetLength(RawOld, Length(RawOld) - 1);
                FOldLineText := RawBytesToDisplayString(RawOld);
                WriteContentLines(DestWriter);
                TargetHit := True;
              end;
            end;
          end
          else
          begin
            DestWriter.WriteRaw(PLineStart, LineLen);
            if Assigned(CkptWriter) then
              OnKeptLineWritten;
          end;
          Inc(CurrentLine);
        end;
      end;

      if FTotalSize > 0 then
      begin
        ThScaled := (AbsOffset * 1000) div FTotalSize;
        if ThScaled > 1000 then ThScaled := 1000;
        NewTh := Integer(ThScaled);
        { ~0,4% de ficheiro por passo: mais suave que saltos de 1% em ficheiros grandes. }
        if (NewTh >= FLastProgressThousandths + 4) or (NewTh >= 1000) then
        begin
          FLastProgressThousandths := NewTh;
          NewPercent := NewTh div 10;
          if NewPercent > 100 then NewPercent := 100;
          FCurrentPercent := NewPercent;
          FPercentToSync := FCurrentPercent;
          if FShowLoadingUI then
            Synchronize(SyncProgress)
          else if Assigned(frmSmoothLoading) then
            { Merge/RunEditWait na main: evita Synchronize + fila; PostMessage nao bloqueia a worker. }
            TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
        end;
      end;
    end;

    if TfrmSmoothLoading.CancelRequested then
    begin
      FreeAndNil(DestWriter);
      FreeAndNil(MMF);
      FSuccess := False;
      FErrorMsg := '';
      Synchronize(FinishThread);
      TfrmSmoothLoading.ResetCancel;
      Exit;
    end;

    { Insercao sem linha-ancora (TargetLine=0) ou alem do EOF:
      anexar no fim para manter semantica de "copiar para o outro lado". }
    if (FOperation = otInsert) and (not InsertDone) and (not Terminated) then
    begin
      InsN := WriteInsertLines(DestWriter);
      if Assigned(CkptWriter) then
        for CkptI := 1 to InsN do
          OnKeptLineWritten;
    end;

    if (FOperation in [otEdit, otReplace]) and (not TargetHit) and (not Terminated) then
    begin
      FreeAndNil(CkptWriter);
      FreeAndNil(DestWriter);
      FreeAndNil(MMF);
      ForceDeleteFile(FTempFileName);
      FSuccess := False;
      FErrorMsg := Format(TrText('Line %d does not exist in the file. Valid range: 1..%d.'),
        [FTargetLine, CurrentLine - 1]);
      if FErrorMsg = '' then
        FErrorMsg := Format('Line %d does not exist in the file.', [FTargetLine]);
      Synchronize(FinishThread);
      Exit;
    end;

    if FOperation in [otDelete, otInsert] then
      FOutputLineCount := OutLineCount;

    FreeAndNil(CkptWriter);
    FreeAndNil(DestWriter);
    FreeAndNil(MMF);

    FSuccess := TryRenameTempOverTarget(FTempFileName, FFileName, FinalErr);
    if FSuccess then
    begin
      if FileExists(FFileName) then
        FFileSizeAfter := UnUtils.GetFileSize(FFileName)
      else
        FFileSizeAfter := FFileSizeBefore;
      if (FOperation in [otDelete, otInsert]) and (CkptTempName <> '') then
      begin
        if not UnUtils.TryRenameTempOverTarget(CkptTempName, CkptFileName, CkptErr) then
        begin
          FSuccess := False;
          FErrorMsg := CkptErr;
        end;
      end;
    end
    else
      FErrorMsg := FinalErr;
      end;

  except
    on E: Exception do begin
      FErrorMsg := DiskOperationFailureMessage(E);
      LogAsync(FastFileRuntimeLogPath, '[EditFileThread] ' + E.Message);
      if Assigned(CkptWriter) then CkptWriter.Free;
      if Assigned(MMF) then MMF.Free;
      if Assigned(DestWriter) then DestWriter.Free;
      if CkptTempName <> '' then
        UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);
    end;
  end;
  finally
    if (FTempFileName <> '') and FileExists(FTempFileName) then
      ForceDeleteFile(FTempFileName);
    if (CkptTempName <> '') and FileExists(CkptTempName) then
      UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ TMergeDeltaThread: MERGE MULTIPLE LINES (DELTA) }
{ ============================================================================ }

constructor TMergeDeltaThread.Create(const AFileName, ADeltaFileName: String; const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AHeader: String = ''; const AFooter: String = '');
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FDeltaFileName := ADeltaFileName;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Merging ...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

procedure TMergeDeltaThread.Execute;
var
  MMF: TMMFReader;
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
  ColonPos: Integer;
  sLine: String;
  LineNum: Int64;
  LineText: String;
  TermCh: AnsiChar;

  function ForceDeleteFile(const FileName: string): Boolean;
  var
    DelName: string;
    Retry: Integer;
  begin
    Result := False;
    if not FileExists(FileName) then begin Result := True; Exit; end;
    DelName := FileName + '.' + FormatDateTime('hhmmss', Now) + '.del';

    for Retry := 1 to 20 do
    begin
      if RenameFile(FileName, DelName) then
      begin
        DeleteFile(DelName);
        Result := True;
        Break;
      end
      else if DeleteFile(FileName) then
      begin
        Result := True;
        Break;
      end;
      Sleep(500);
    end;
  end;

begin
  inherited;
  // CloseFileStreams removed
  FTempFileName := NewFastFileTemp('merge');
  ForceDeleteFile(FTempFileName);

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
            if (Length(LineText) > 0) and (LineText[1] = ' ') then
              LineText := Copy(LineText, 2, Length(LineText));

            DeltaArr[DeltaCount].LineNumber := LineNum;
            DeltaArr[DeltaCount].NewText := LineText;
            Inc(DeltaCount);
          end;
        end;
      end;
      SetLength(DeltaArr, DeltaCount);
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
    FreeAndNil(DeltaLines);
  end;

  MMF := nil;
  DestWriter := nil;
  MMF := TMMFReader.Create(FFileName);
  DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024);
  DestWriter.LineBreak := OutputEolForFile(FFileName);
  TermCh := LineTermCharForFile(FFileName);
  try
    try
      begin
      FTotalSize := MMF.FileSize;
      CurrentLine := 1;
      AbsOffset := 0;
      FCurrentPercent := 0;
      dIndex := 0;

      while (AbsOffset < FTotalSize) and (not Terminated)
        and (not TfrmSmoothLoading.CancelRequested) do
      begin
        P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));
        if (P = nil) or (Contiguous = 0) then Break;

        PLineStart := P;

        for i := 0 to Contiguous - 1 do
        begin
          if P^ = TermCh then
          begin
            LineLen := (P - PLineStart) + 1;

            if (dIndex < DeltaCount) and (CurrentLine = DeltaArr[dIndex].LineNumber) then
            begin
              DestWriter.WriteLine(AnsiToUtf8(DeltaArr[dIndex].NewText));
              Inc(dIndex);
            end
            else
              DestWriter.WriteRaw(PLineStart, LineLen);

            Inc(CurrentLine);
            PLineStart := P + 1;
          end;
          Inc(P);
        end;

        AbsOffset := AbsOffset + Contiguous;

        { Last line without trailing LF: process remainder at EOF. }
        if (AbsOffset >= FTotalSize) and (PLineStart < P) and (not Terminated) and
           (not TfrmSmoothLoading.CancelRequested) then
        begin
          LineLen := P - PLineStart;
          if LineLen > 0 then
          begin
            if (dIndex < DeltaCount) and (CurrentLine = DeltaArr[dIndex].LineNumber) then
            begin
              DestWriter.WriteLine(AnsiToUtf8(DeltaArr[dIndex].NewText));
              Inc(dIndex);
            end
            else
              DestWriter.WriteRaw(PLineStart, LineLen);
            Inc(CurrentLine);
          end;
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

      if TfrmSmoothLoading.CancelRequested then
      begin
        FreeAndNil(DestWriter);
        FreeAndNil(MMF);
        sw.Stop;
        if FAutoHide and FShowLoadingUI then
          Synchronize(SyncHideLoading);
        TfrmSmoothLoading.ResetCancel;
        Exit;
      end;

      while dIndex < DeltaCount do
      begin
        while CurrentLine < DeltaArr[dIndex].LineNumber do
        begin
          DestWriter.WriteLine('');
          Inc(CurrentLine);
        end;
        DestWriter.WriteLine(AnsiToUtf8(DeltaArr[dIndex].NewText));
        Inc(CurrentLine);
        Inc(dIndex);
      end;

      FreeAndNil(DestWriter);
      FreeAndNil(MMF);

      if not TryRenameTempOverTarget(FTempFileName, FFileName, FErrorMsg) then
        raise Exception.Create(FErrorMsg);

      FSuccess := True;
      end;
    except
      on E: Exception do
      begin
        FErrorMsg := DiskOperationFailureMessage(E);
        LogAsync(FastFileRuntimeLogPath, '[MergeDeltaThread] ' + E.Message);
        if Assigned(MMF) then FreeAndNil(MMF);
        if Assigned(DestWriter) then FreeAndNil(DestWriter);
        if (FTempFileName <> '') and FileExists(FTempFileName) then
          ForceDeleteFile(FTempFileName);
        Synchronize(SyncError);
      end;
    end;
  finally
    FreeAndNil(DestWriter);
    FreeAndNil(MMF);
    if (FTempFileName <> '') and FileExists(FTempFileName) then
      ForceDeleteFile(FTempFileName);
  end;
  Synchronize(FinishThread);
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
  ShowAppMessage(TrText('Merge Error: ') + FErrorMsg);
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
    TimeStr := Format(TrText('Merge completed in: %s millisecs.'), [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) then
    begin
      frmMain.CommitPendingMergeDeltaUndoIfNeeded(True);
      frmMain.AppendOperationTimerLog(TimeStr);
      frmMain.RefreshFile;
    end;
  end
  else if Assigned(frmMain) then
    frmMain.CommitPendingMergeDeltaUndoIfNeeded(False);
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

{ ============================================================================ }
{ THREAD 3: EXPORTA��O }
{ ============================================================================ }

constructor TExportFileThread.Create(const ALineParams: String; const ASaveToFile: Boolean; const AOutputFileName: String;
    const ASourceFileName: String; const ATotalLines: Int64;
    const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AHeader: String = ''; const AFooter: String = '');
begin
  inherited Create(True);
  FAutoHide := AutoHide;
  FreeOnTerminate := True;
  FLineParams := ALineParams;
  FSaveToFile := ASaveToFile;
  FOutputFileName := AOutputFileName;
  FSourceFileName := ASourceFileName;
  FTotalLines := ATotalLines;
  FShowLoadingUI := ShowUI;
  FErrMsg := '';
  FResultList := TStringList.Create;
  if FShowLoadingUI then
  begin
    if FSaveToFile then
      FLoadingMsg := TrText('Exporting lines to file...')
    else
      FLoadingMsg := TrText('Exporting lines...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  { Nao chamar Start aqui: AfterConstruction do TThread no D10.4 volta a
    InternalStart e gera EThread "Cannot call Start on a running or suspended thread".
    Resume so decrementa o CREATE_SUSPENDED do SO (igual TEditFileThread). }
  Resume;
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
  begin
    if Assigned(frmMain) then
      ShowFastFileAppNotice(frmMain, fnkSuccess, TrText('Information'),
        Format(TrText('Export finished! File saved to: %s'), [FOutputFileName]))
    else
      FastFileMsgInfo(Format(TrText('Export finished! File saved to: %s'), [FOutputFileName]));
  end
  else if Assigned(frmMain) then
    ShowFastFileAppNotice(frmMain, fnkSuccess, TrText('Information'),
      TrText('Export finished! Lines copied to clipboard.'))
  else
    FastFileMsgInfo(TrText('Export finished! Lines copied to clipboard.'));
end;

procedure TExportFileThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FErrMsg <> '' then
  begin
    if Assigned(frmMain) then
      ShowFastFileAppNotice(frmMain, fnkWarning, TrText('Error'), FErrMsg)
    else
      FastFileMsgInfo(FErrMsg);
  end;
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
  LineNum, FromL, ToL, LineNo: Int64;
  DestWriter: TBufferedTextWriter;
  MMF: TMMFReader;
  IdxStream: TFileStream;
  IndexFileName: String;
  OffsetStr: AnsiString;
  StartOffset, EndOffset, ReadPos, FSize, StartOfLine, ScanPos: Int64;
  LineLength: Integer;
  Buffer: AnsiString;
  P: PByte;
  Contiguous: Cardinal;
  RangeContiguous: Boolean;
  B, TermB: Byte;
  Ok: Boolean;

  procedure EmitBuffer;
  begin
    while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
      SetLength(Buffer, Length(Buffer) - 1);
    if FSaveToFile then
      DestWriter.WriteLine(Buffer)
    else
      FResultList.Add(string(Buffer));
  end;

  procedure EmitOffsets(const AStart, AEnd: Int64);
  begin
    LineLength := AEnd - AStart;
    if LineLength <= 0 then
    begin
      Buffer := '';
      EmitBuffer;
      Exit;
    end;
    if LineLength > MAX_LINE_LEN then LineLength := MAX_LINE_LEN;
    ReadPos := AStart - 1;
    SetLength(Buffer, LineLength);
    P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
    if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
      Move(P^, Pointer(Buffer)^, LineLength)
    else
      MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);
    EmitBuffer;
  end;

  function LineWanted(const Ln: Int64): Boolean;
  var
    k: Integer;
  begin
    if RangeContiguous then
    begin
      Result := (Ln >= FromL) and (Ln <= ToL);
      Exit;
    end;
    Result := False;
    for k := 0 to TargetLines.Count - 1 do
      if Int64(TargetLines[k]) = Ln then
      begin
        Result := True;
        Exit;
      end;
  end;

begin
  DestWriter := nil;
  MMF := nil;
  IdxStream := nil;
  Ok := False;
  TargetLines := nil;
  try
    try
      if (Trim(FSourceFileName) = '') or (not FileExists(FSourceFileName)) then
      begin
        FErrMsg := TrText('Could not open source file: ') + FSourceFileName;
        Exit;
      end;
      LineNum := EstimateExportLineCount(FLineParams, FTotalLines);
      if LineNum <= 0 then
      begin
        FErrMsg := TrText('Nothing to export');
        Exit;
      end;
      if LineNum > ExportLineLimitForDestination(FSaveToFile) then
      begin
        FErrMsg := ExportLineLimitExceededMessage(FSaveToFile, LineNum);
        Exit;
      end;

      TargetLines := ParseLines(FLineParams);
      if TargetLines.Count <= 0 then
      begin
        FErrMsg := TrText('Nothing to export');
        Exit;
      end;

      FromL := Int64(TargetLines[0]);
      ToL := FromL;
      for i := 1 to TargetLines.Count - 1 do
      begin
        LineNum := Int64(TargetLines[i]);
        if LineNum < FromL then FromL := LineNum;
        if LineNum > ToL then ToL := LineNum;
      end;
      RangeContiguous := (ToL >= FromL) and
        ((ToL - FromL + 1) = TargetLines.Count);

      MMF := TMMFReader.Create(FSourceFileName);
      FSize := MMF.FileSize;
      TermB := LineTermByteForFile(FSourceFileName);
      if FSaveToFile then
      begin
        DestWriter := TBufferedTextWriter.Create(FOutputFileName, 4 * 1024 * 1024);
        DestWriter.LineBreak := OutputEolForFile(FSourceFileName);
      end;

      IndexFileName := ResolveWorkingLineIndexPath;
      if IndexFileName <> '' then
      begin
        IdxStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
        SetLength(OffsetStr, 18);
        for i := 0 to TargetLines.Count - 1 do
        begin
          if Terminated then Break;
          LineNum := Int64(TargetLines[i]);
          if LineNum < 1 then Continue;
          if (FTotalLines > 0) and (LineNum > FTotalLines) then Continue;

          IdxStream.Seek(Int64(LineNum - 1) * INDEX_REC_SIZE, soFromBeginning);
          IdxStream.Read(Pointer(OffsetStr)^, 18);
          StartOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
          if StartOffset = -1 then
          begin
            Buffer := '';
            EmitBuffer;
            Continue;
          end;
          StartOffset := Abs(StartOffset);
          if (Int64(LineNum) * INDEX_REC_SIZE) < IdxStream.Size then
          begin
            IdxStream.Seek(Int64(LineNum) * INDEX_REC_SIZE, soFromBeginning);
            IdxStream.Read(Pointer(OffsetStr)^, 18);
            EndOffset := StrToInt64Def(Trim(string(OffsetStr)), FSize + 1);
          end
          else
            EndOffset := FSize + 1;
          EndOffset := Abs(EndOffset);
          EmitOffsets(StartOffset, EndOffset);
          if TargetLines.Count > 0 then
            FPercent := Round(((i + 1) / TargetLines.Count) * 100)
          else
            FPercent := 100;
          TfrmSmoothLoading.PostProgressFromWorker(FPercent);
        end;
      end
      else
      begin
        { Sem temp.txt (ficheiros >2 GB usam so temp_ckpt; Zero Scan pode nao ter indice). }
        LineNo := 1;
        StartOfLine := 1;
        ScanPos := 0;
        while ScanPos < FSize do
        begin
          if Terminated then Break;
          if LineNo > ToL then Break;
          P := MMF.PtrAt(ScanPos, 1, Contiguous);
          if Assigned(P) then
            B := P^
          else
          begin
            MMF.ReadBytes(ScanPos, B, 1);
          end;
          if B = TermB then
          begin
            if LineWanted(LineNo) then
              EmitOffsets(StartOfLine, ScanPos + 1);
            Inc(LineNo);
            StartOfLine := ScanPos + 2;
            if ToL > 0 then
              FPercent := Round((LineNo / ToL) * 100);
            if (LineNo and 255) = 0 then
              TfrmSmoothLoading.PostProgressFromWorker(FPercent);
          end;
          Inc(ScanPos);
        end;
        if (not Terminated) and (LineNo <= ToL) and (StartOfLine <= FSize + 1) then
          if LineWanted(LineNo) then
            EmitOffsets(StartOfLine, FSize + 1);
        FPercent := 100;
        TfrmSmoothLoading.PostProgressFromWorker(FPercent);
      end;

      if not FSaveToFile then
        Synchronize(SyncClipboard);
      Ok := True;
    except
      on E: Exception do
      begin
        FErrMsg := E.Message;
        LogAsync(FastFileRuntimeLogPath, '[ExportFileThread] ' + E.Message);
      end;
    end;
  finally
    if Assigned(DestWriter) then FreeAndNil(DestWriter);
    FreeAndNil(IdxStream);
    FreeAndNil(MMF);
    if Assigned(TargetLines) then
      TargetLines.Free;
  end;
  if Ok then
    Synchronize(SyncFinish)
  else if FErrMsg <> '' then
    Synchronize(SyncError)
  else if FShowLoadingUI and FAutoHide then
    Synchronize(SyncHideLoading);
end;

{ ============================================================================ }
{ THREAD: EXPORTA��O TAIL (intervalo cont�guo, streaming)                       }
{ ============================================================================ }

constructor TTailExportThread.Create(const AFromLine1, AToLine1, ATotalLines: Int64;
  const AOutputFileName, ASourceFileName: String;
  AOwner: TObject; AIncludeMacroResults: Boolean;
  const AutoHide, ShowUI: Boolean);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FOwner := AOwner;
  FIncludeMacroResults := AIncludeMacroResults;
  FFromLine1 := AFromLine1;
  FToLine1 := AToLine1;
  FTotalLines := ATotalLines;
  FOutputFileName := AOutputFileName;
  FSourceFileName := ASourceFileName;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FExportedCount := 0;
  FCancelled := False;
  FSuccess := False;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Exporting tail lines to file...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
end;

procedure TTailExportThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg, False);
end;

procedure TTailExportThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TTailExportThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TTailExportThread.SyncFinish;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FCancelled then
    FastFileMessageBox(PChar(TrText('Tail export cancelled.')),
      PChar(TrText('Export tail lines')), MB_OK or MB_ICONINFORMATION)
  else if FSuccess then
    FastFileMessageBox(PChar(Format(TrText('%d tail line(s) exported to file.'),
      [FExportedCount])), PChar(TrText('Export tail lines')), MB_OK or MB_ICONINFORMATION)
  else
    FastFileMessageBox(PChar(TrText('Tail export failed.')),
      PChar(TrText('Export tail lines')), MB_OK or MB_ICONWARNING);
end;

procedure TTailExportThread.Execute;
const
  INDEX_REC_SIZE = 20;
  MAX_LINE_LEN = 2 * 1024 * 1024;
  PROGRESS_EVERY = 256;
var
  LineNum, TotalToExport, Done: Int64;
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
  LineNo, StartOfLine, ScanPos: Int64;
  B, TermB: Byte;
begin
  DestWriter := nil;
  MMF := nil;
  IdxStream := nil;
  if FToLine1 < FFromLine1 then
  begin
    Synchronize(SyncFinish);
    Exit;
  end;
  TotalToExport := FToLine1 - FFromLine1 + 1;
  IndexFileName := ResolveWorkingLineIndexPath;
  try
    try
      begin
      MMF := TMMFReader.Create(FSourceFileName);
      FSize := MMF.FileSize;
      SetLength(OffsetStr, 18);
      DestWriter := TBufferedTextWriter.Create(FOutputFileName, 4 * 1024 * 1024);
      DestWriter.LineBreak := OutputEolForFile(FSourceFileName);
      TermB := LineTermByteForFile(FSourceFileName);
      Done := 0;

      if IndexFileName <> '' then
        IdxStream := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);

      if Assigned(IdxStream) then
      begin
      LineNum := FFromLine1;
      while (LineNum <= FToLine1) and (not Terminated) do
      begin
        if TfrmSmoothLoading.CancelRequested then
        begin
          FCancelled := True;
          Break;
        end;
        if (LineNum < 1) or (LineNum > FTotalLines) then
        begin
          Inc(LineNum);
          Inc(Done);
          Continue;
        end;

        IdxStream.Seek(Int64(LineNum - 1) * INDEX_REC_SIZE, soFromBeginning);
        IdxStream.Read(Pointer(OffsetStr)^, 18);
        StartOffset := StrToInt64Def(Trim(string(OffsetStr)), -1);
        if StartOffset = -1 then
        begin
          DestWriter.WriteLine('');
          Inc(FExportedCount);
        end
        else
        begin
          StartOffset := Abs(StartOffset);
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
            DestWriter.WriteLine('')
          else
          begin
            if LineLength > MAX_LINE_LEN then
              LineLength := MAX_LINE_LEN;
            ReadPos := StartOffset - 1;
            SetLength(Buffer, LineLength);
            P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
            if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
              Move(P^, Pointer(Buffer)^, LineLength)
            else
              MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);
            while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
              SetLength(Buffer, Length(Buffer) - 1);
            DestWriter.WriteLine(Buffer);
          end;
          Inc(FExportedCount);
        end;

        Inc(Done);
        if (Done mod PROGRESS_EVERY) = 0 then
        begin
          if TotalToExport > 0 then
            FPercent := Round((Done * 100) / TotalToExport)
          else
            FPercent := 100;
          if FPercent > 100 then FPercent := 100;
          TfrmSmoothLoading.PostProgressFromWorker(FPercent);
        end;
        Inc(LineNum);
      end;
      end
      else
      begin
        { Sem temp.txt (ficheiros >2 GB / Zero Scan): varrer o ficheiro ate ToLine. }
        LineNo := 1;
        StartOfLine := 1;
        ScanPos := 0;
        while ScanPos < FSize do
        begin
          if Terminated then Break;
          if TfrmSmoothLoading.CancelRequested then
          begin
            FCancelled := True;
            Break;
          end;
          if LineNo > FToLine1 then Break;
          P := MMF.PtrAt(ScanPos, 1, Contiguous);
          if Assigned(P) then
            B := P^
          else
            MMF.ReadBytes(ScanPos, B, 1);
          if B = TermB then
          begin
            if (LineNo >= FFromLine1) and (LineNo <= FToLine1) then
            begin
              StartOffset := StartOfLine;
              EndOffset := ScanPos + 1;
              LineLength := EndOffset - StartOffset;
              if LineLength <= 0 then
                DestWriter.WriteLine('')
              else
              begin
                if LineLength > MAX_LINE_LEN then
                  LineLength := MAX_LINE_LEN;
                ReadPos := StartOffset - 1;
                SetLength(Buffer, LineLength);
                P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
                if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
                  Move(P^, Pointer(Buffer)^, LineLength)
                else
                  MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);
                while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
                  SetLength(Buffer, Length(Buffer) - 1);
                DestWriter.WriteLine(Buffer);
              end;
              Inc(FExportedCount);
            end;
            Inc(LineNo);
            StartOfLine := ScanPos + 2;
            if (LineNo and 255) = 0 then
            begin
              if FToLine1 > 0 then
                FPercent := Round((LineNo * 100) / FToLine1)
              else
                FPercent := 100;
              TfrmSmoothLoading.PostProgressFromWorker(FPercent);
            end;
          end;
          Inc(ScanPos);
        end;
        if (not Terminated) and (not FCancelled) and
           (LineNo >= FFromLine1) and (LineNo <= FToLine1) and
           (StartOfLine <= FSize + 1) then
        begin
          StartOffset := StartOfLine;
          EndOffset := FSize + 1;
          LineLength := EndOffset - StartOffset;
          if LineLength <= 0 then
            DestWriter.WriteLine('')
          else
          begin
            if LineLength > MAX_LINE_LEN then
              LineLength := MAX_LINE_LEN;
            ReadPos := StartOffset - 1;
            SetLength(Buffer, LineLength);
            P := MMF.PtrAt(ReadPos, LineLength, Contiguous);
            if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
              Move(P^, Pointer(Buffer)^, LineLength)
            else
              MMF.ReadBytes(ReadPos, Pointer(Buffer)^, LineLength);
            while (Length(Buffer) > 0) and (Buffer[Length(Buffer)] in [#10, #13]) do
              SetLength(Buffer, Length(Buffer) - 1);
            DestWriter.WriteLine(Buffer);
          end;
          Inc(FExportedCount);
        end;
      end;

      if (not FCancelled) and (FExportedCount > 0) then
        FSuccess := True;
      if FSuccess and FIncludeMacroResults and Assigned(FOwner) then
        TfrmMain(FOwner).AppendTailMacroResultsToExportFile(FOutputFileName);
      if TotalToExport > 0 then
        TfrmSmoothLoading.PostProgressFromWorker(100);
      Synchronize(SyncFinish);
      end;
    except
      on E: Exception do
      begin
        FSuccess := False;
        LogAsync(FastFileRuntimeLogPath, '[TTailExportThread] ' + E.Message);
        if FShowLoadingUI then
          Synchronize(SyncHideLoading);
        FastFileMessageBox(PChar(E.Message), PChar(TrText('Export tail lines')),
          MB_OK or MB_ICONERROR);
      end;
    end;
  finally
    if Assigned(DestWriter) then
      FreeAndNil(DestWriter);
    FreeAndNil(IdxStream);
    FreeAndNil(MMF);
  end;
end;


{ ===== Anti-flicker helpers ===== }

constructor TfrmSmoothLoadingForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackgroundBmp := TBitmap.Create;
  FLastPaintedProgress := -1;
  FMarqueeDir := 1;
  FFadeInActive   := False;
  { Fade curto a partir de um alpha ja visivel. 3,6s desde alpha 6 deixava
    a janela e a barra "fantasma" durante o Enviar do Assistente. }
  FFadeDurationMS := 180;
  FFadeStartAlpha := 220;
  FFadeEndAlpha   := 255;
  FFormCornerRadius := 48;
end;

destructor TfrmSmoothLoadingForm.Destroy;
begin
  FreeAndNil(FBackgroundBmp);
  inherited Destroy;
end;

procedure TfrmSmoothLoadingForm.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  { Pinta o fundo real (nao deixa areas sem pintura apos minimizar/Alt+Tab). }
  if Msg.DC <> 0 then
    PaintBackgroundTo(Msg.DC);
  Msg.Result := 1;
end;

procedure TfrmSmoothLoadingForm.PaintBackgroundTo(DC: HDC);
var
  Br: HBRUSH;
  R: TRect;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;
  if (FBackgroundBmp.Width <> ClientWidth) or (FBackgroundBmp.Height <> ClientHeight) then
    BuildBackground;
  if (FBackgroundBmp.Width = ClientWidth) and (FBackgroundBmp.Height = ClientHeight) then
    BitBlt(DC, 0, 0, ClientWidth, ClientHeight, FBackgroundBmp.Canvas.Handle, 0, 0, SRCCOPY)
  else
  begin
    R := ClientRect;
    Br := CreateSolidBrush(RGB(20, 30, 50));
    try
      FillRect(DC, R, Br);
    finally
      DeleteObject(Br);
    end;
  end;
end;

procedure TfrmSmoothLoadingForm.ApplySmoothProgressEx(Percent: Double);
var
  R: TRect;
begin
  FIsDeterminate := True;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  if GScriptEngineProgressImmediate then
  begin
    FCurrentProgress := Percent;
    FTargetProgress := Percent;
    FLastPaintedProgress := Percent;
  end
  else
  begin
    if Percent + 0.05 < FCurrentProgress then
      FCurrentProgress := Percent;
    FTargetProgress := Percent;
  end;
  if Assigned(tmrAnimation) and (not tmrAnimation.Enabled) then
    tmrAnimation.Enabled := True;
  if Assigned(pbProgressBar) then
  begin
    pbProgressBar.Invalidate;
    if GScriptEngineProgressImmediate and HandleAllocated then
      pbProgressBar.Repaint;
  end;
  if Assigned(pnlContainer) and Assigned(pbProgressBar) and HandleAllocated then
  begin
    R := pbProgressBar.BoundsRect;
    OffsetRect(R, pnlContainer.Left, pnlContainer.Top);
    InvalidateRect(Handle, @R, False);
  end;
end;

procedure TfrmSmoothLoadingForm.ApplySmoothProgress(Percent: Integer);
begin
  ApplySmoothProgressEx(Percent);
end;

procedure TfrmSmoothLoadingForm.WMSmoothProgress(var Msg: TMessage);
begin
  { Um passo por mensagem: fundir com PeekMessage fazia a barra saltar directo
    para o ultimo % quando a fila encheia durante trabalho CPU na worker. }
  if Msg.LParam = 1 then
    ApplySmoothProgressEx(Integer(Msg.WParam) / 10.0)
  else
    ApplySmoothProgress(Integer(Msg.WParam));
  Msg.Result := 0;
end;

procedure TfrmSmoothLoadingForm.WMSmoothProgressDetail(var Msg: TMessage);
var
  P: PChar;
  S: string;
begin
  ApplySmoothProgress(Integer(Msg.WParam));
  P := PChar(Msg.LParam);
  if Assigned(lblDetail) then
  begin
    if P <> nil then
      S := string(P)
    else
      S := '';
    lblDetail.Caption := S;
    lblDetail.Visible := Trim(S) <> '';
    ApplyDetailLabelLook;
    if Assigned(lblMessage) and (Trim(lblMessage.Caption) <> '') then
      AdjustLoadingMessageLayout(lblMessage.Caption);
  end;
  if P <> nil then
    StrDispose(P);
  Msg.Result := 0;
end;

procedure TfrmSmoothLoadingForm.WMSmoothDetailOnly(var Msg: TMessage);
var
  P: PChar;
  S: string;
begin
  P := PChar(Msg.LParam);
  if Assigned(lblDetail) then
  begin
    if P <> nil then
      S := string(P)
    else
      S := '';
    lblDetail.Caption := S;
    lblDetail.Visible := Trim(S) <> '';
    ApplyDetailLabelLook;
    if Assigned(lblMessage) and (Trim(lblMessage.Caption) <> '') then
      AdjustLoadingMessageLayout(lblMessage.Caption);
  end;
  if P <> nil then
    StrDispose(P);
  Msg.Result := 0;
end;

procedure TfrmSmoothLoadingForm.BuildBackground;
var
  Row: Integer;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then Exit;

  FBackgroundBmp.PixelFormat := pf24bit;
  FBackgroundBmp.Width  := ClientWidth;
  FBackgroundBmp.Height := ClientHeight;

  // Gradiente azul-marinho
  for Row := 0 to ClientHeight do
  begin
    FBackgroundBmp.Canvas.Pen.Color := RGB(
      20 + MulDiv(Row, 10, ClientHeight),
      30 + MulDiv(Row, 15, ClientHeight),
      50 + MulDiv(Row, 30, ClientHeight));
    FBackgroundBmp.Canvas.MoveTo(0, Row);
    FBackgroundBmp.Canvas.LineTo(ClientWidth, Row);
  end;
end;



procedure TfrmSmoothLoadingForm.ForceFullScreen;
const
  DESIRED_CLIENT_W = 760;
  DESIRED_CLIENT_H = 720;
  SCREEN_MARGIN    = 24;
  { SPI_GETWORKAREA � �rea �til da barra de tarefas (prim�rio); WinUser.h }
  SPI_GETWORKAREA_CONST = $0030;
var
  WA: TRect;
  MaxCW, MaxCH, CW, CH: Integer;
begin
  if not SystemParametersInfo(SPI_GETWORKAREA_CONST, 0, @WA, 0) then
  begin
    WA.Left := 0;
    WA.Top := 0;
    WA.Right := Screen.Width;
    WA.Bottom := Screen.Height;
  end;
  MaxCW := (WA.Right - WA.Left) - (SCREEN_MARGIN * 2);
  MaxCH := (WA.Bottom - WA.Top) - (SCREEN_MARGIN * 2);
  if MaxCW < 320 then MaxCW := (WA.Right - WA.Left) - 8;
  if MaxCH < 240 then MaxCH := (WA.Bottom - WA.Top) - 8;

  CW := DESIRED_CLIENT_W;
  CH := DESIRED_CLIENT_H;
  if CW > MaxCW then CW := MaxCW;
  if CH > MaxCH then CH := MaxCH;

  ClientWidth := CW;
  ClientHeight := CH;
  Left := WA.Left + ((WA.Right - WA.Left) - Width) div 2;
  Top := WA.Top + ((WA.Bottom - WA.Top) - Height) div 2;
end;

procedure TfrmSmoothLoadingForm.pbProgressBarPaint(Sender: TObject);
var
  W, H, BarW, BlobW, X: Integer;
begin
  W := pbProgressBar.Width;
  H := pbProgressBar.Height;
  pbProgressBar.Canvas.Brush.Color := $00201810;
  pbProgressBar.Canvas.FillRect(Rect(0, 0, W, H));
  pbProgressBar.Canvas.Brush.Color := $00FFC040;
  if FIsDeterminate then
  begin
    BarW := Round((W * FCurrentProgress) / 100);
    if BarW < 0 then
      BarW := 0;
    if BarW > W then
      BarW := W;
    pbProgressBar.Canvas.FillRect(Rect(0, 0, BarW, H));
  end
  else
  begin
    { Sliding pulse — not a 0..100 fill that restarts. }
    BlobW := W div 4;
    if BlobW < 36 then
      BlobW := 36;
    X := Round((W + BlobW) * (FMarqueePos / 100.0)) - BlobW;
    pbProgressBar.Canvas.FillRect(Rect(X, 0, X + BlobW, H));
  end;
  pbProgressBar.Canvas.Brush.Style := bsClear;
  pbProgressBar.Canvas.Pen.Color := $00FFD080;
  pbProgressBar.Canvas.Pen.Width := 1;
  pbProgressBar.Canvas.Rectangle(0, 0, W, H);
  pbProgressBar.Canvas.Brush.Style := bsSolid;
end;

procedure TfrmSmoothLoadingForm.SnapFullyOpaque;
begin
  FFadeInActive := False;
  AlphaBlendValue := 255;
  AlphaBlend := False;
  { Remover WS_EX_LAYERED exige repintura completa (senao sobram cantos sem pintura). }
  QueueReapplyRoundRegions;
end;

class function TfrmSmoothLoading.IsShowing: Boolean;
begin
  Result := Assigned(frmSmoothLoading) and frmSmoothLoading.Visible;
end;

class procedure TfrmSmoothLoading.SetIndeterminate(AOn: Boolean);
var
  WasDeterminate: Boolean;
begin
  if not Assigned(frmSmoothLoading) then Exit;
  WasDeterminate := frmSmoothLoading.FIsDeterminate;
  frmSmoothLoading.FIsDeterminate := not AOn;
  { Only reset the pulse when entering wait mode — do not restart 0..100. }
  if AOn and WasDeterminate then
  begin
    frmSmoothLoading.FMarqueePos := 0;
    frmSmoothLoading.FLastPaintedProgress := -1;
  end;
  if Assigned(frmSmoothLoading.pbProgressBar) then
    frmSmoothLoading.pbProgressBar.Invalidate;
  if Assigned(frmSmoothLoading.tmrAnimation) then
    frmSmoothLoading.tmrAnimation.Enabled := True;
end;

class procedure TfrmSmoothLoading.SetWaitTexts(const MessageText, DetailText: string);
var
  DisplayMsg, Detail: string;
begin
  if not Assigned(frmSmoothLoading) then Exit;
  DisplayMsg := Trim(MessageText);
  if DisplayMsg = '' then
    DisplayMsg := TrText('Processing...')
  else
    DisplayMsg := TrText(DisplayMsg);
  frmSmoothLoading.lblMessage.Caption := DisplayMsg;
  frmSmoothLoading.AdjustLoadingMessageLayout(DisplayMsg);
  if Assigned(frmSmoothLoading.lblDetail) then
  begin
    Detail := Trim(DetailText);
    frmSmoothLoading.lblDetail.Caption := Detail;
    frmSmoothLoading.lblDetail.Visible := Detail <> '';
    frmSmoothLoading.ApplyDetailLabelLook;
  end;
end;

class procedure TfrmSmoothLoading.ShowWait(const MessageText: String; AStayOnTop: Boolean);
begin
  if IsShowing then
  begin
    if Assigned(frmMain) then
      frmMain.SetOperationStatus(fssLoading, TrText(MessageText));
    SetWaitTexts(MessageText, '');
    SetIndeterminate(True);
    Exit;
  end;
  ShowLoading(nil, MessageText, AStayOnTop);
  SetIndeterminate(True);
end;

class procedure TfrmSmoothLoading.ShowLoading(const MessageText: String);
begin
  ShowLoading(nil, MessageText, True);
end;

class procedure TfrmSmoothLoading.ShowLoading(const MessageText: String; AStayOnTop: Boolean);
begin
  ShowLoading(nil, MessageText, AStayOnTop);
end;

class procedure TfrmSmoothLoading.ShowLoading(AOwner: TComponent; const MessageText: String; AStayOnTop: Boolean);
var
  DisplayMsg: string;
begin
  if not Assigned(frmSmoothLoading) then
  begin
    if AOwner <> nil then
      frmSmoothLoading := TfrmSmoothLoadingForm.Create(AOwner)
    else
      frmSmoothLoading := TfrmSmoothLoadingForm.Create(Application);
  end;

  frmSmoothLoading.AlphaBlendValue := frmSmoothLoading.FFadeStartAlpha;
  frmSmoothLoading.AlphaBlend      := True;
  frmSmoothLoading.FFadeInActive   := True;
  frmSmoothLoading.FIsDeterminate := True;
  frmSmoothLoading.FCurrentProgress := 0;
  frmSmoothLoading.FTargetProgress := 0;
  frmSmoothLoading.FMarqueePos := 0;
  frmSmoothLoading.FMarqueeDir := 1;
  { Reset cancel flag and update caption/style for the new operation. }
  TfrmSmoothLoading.ResetCancel;
  if Assigned(frmSmoothLoading.btnCancel) then
  begin
    frmSmoothLoading.btnCancel.Caption := TrText('Cancel');
    frmSmoothLoading.btnCancel.Enabled := True;
    frmSmoothLoading.btnCancel.Cursor := crHandPoint;
  end;

  DisplayMsg := Trim(MessageText);
  if DisplayMsg = '' then
    DisplayMsg := TrText('Processing...')
  else
    DisplayMsg := TrText(DisplayMsg);
  if Assigned(frmMain) then
    frmMain.SetOperationStatus(fssLoading, DisplayMsg);
  frmSmoothLoading.lblMessage.Caption := DisplayMsg;
  if Assigned(frmSmoothLoading.lblDetail) then
  begin
    frmSmoothLoading.lblDetail.Caption := '';
    frmSmoothLoading.lblDetail.Visible := False;
  end;
  frmSmoothLoading.AdjustLoadingMessageLayout(DisplayMsg);

  if AStayOnTop then
    frmSmoothLoading.FormStyle := fsStayOnTop
  else
    frmSmoothLoading.FormStyle := fsNormal;

  // 2) Forca fullscreen antes de mostrar (com fallback seguro)
  try
    frmSmoothLoading.ForceFullScreen;
    frmSmoothLoading.Show;
  except
    on EOSError do
    begin
      // Fallback: evita estilos/efeitos visuais e tenta exibir o overlay basico.
      try
        frmSmoothLoading.AlphaBlend := False;
        frmSmoothLoading.FormStyle := fsNormal;
        frmSmoothLoading.Show;
      except
        if Assigned(frmMain) then
          frmMain.FinishOperationStatus(fssFailed);
        Exit;
      end;
    end;
  end;

  // 3. Posicionamento/arredondamento nunca devem derrubar o fluxo.
  try
    frmSmoothLoading.CenterContainer;
    frmSmoothLoading.RoundControl(frmSmoothLoading.pnlContainer, 56);
    frmSmoothLoading.ApplyFormRoundCorners(frmSmoothLoading.FFormCornerRadius);
    if frmSmoothLoading.HandleAllocated then
      PostMessage(frmSmoothLoading.Handle, WM_FF_APPLYROUNDRGN, 0, 0);
  except
    on Exception do
    begin
      // Ignora falhas cosmeticas para manter a operacao principal.
    end;
  end;

  { Reposiciona apos arredondamento/fullscreen � evita modal "desformatado". }
  frmSmoothLoading.AdjustLoadingMessageLayout(MessageText);

  frmSmoothLoading.FLastPaintedProgress := -1;
  frmSmoothLoading.FFadeStartTick := GetTickCount;
  frmSmoothLoading.tmrAnimation.Enabled := True;
  frmSmoothLoading.lblMessage.Font.Color := $00FFF0E6;
  frmSmoothLoading.ApplyDetailLabelLook;

  { For?a apenas a pintura imediata do form de loading (sem processar a fila
    global de mensagens, o que causaria reentr?ncia perigosa se chamado dentro
    de opera??es de ficheiro em curso). }
  try
    frmSmoothLoading.Update;
  except
    on Exception do
    begin
      // Nao interrompe a operacao de leitura por falha de pintura.
    end;
  end;
  if (not AStayOnTop) and frmSmoothLoading.HandleAllocated then
  begin
    try
      frmSmoothLoading.BringToFront;
    except
      on Exception do
      begin
      end;
    end;
  end;
  if Assigned(frmSmoothLoading.imgLogo) then
  begin
    try
      frmSmoothLoading.imgLogo.Invalidate;
    except
      on Exception do
      begin
      end;
    end;
  end;
end;

procedure TfrmSmoothLoadingForm.LayoutCancelButton;
var
  R: TRect;
  Cap: string;
  BtnW: Integer;
  OldFont: HFONT;
begin
  if (not Assigned(btnCancel)) or (not Assigned(pnlContainer)) then
    Exit;
  Cap := Trim(btnCancel.Caption);
  if Cap = '' then
    Cap := TrText('Cancel');
  btnCancel.Caption := Cap;
  ApplyCancelButtonLook;
  { TBitBtn (Delphi 7) nao tem Canvas publico � medir caption no canvas do form. }
  R := Rect(0, 0, 0, 0);
  OldFont := SelectObject(Canvas.Handle, btnCancel.Font.Handle);
  try
    DrawText(Canvas.Handle, PChar(Cap), Length(Cap), R,
      DT_CALCRECT or DT_SINGLELINE or DT_NOPREFIX);
  finally
    SelectObject(Canvas.Handle, OldFont);
  end;
  BtnW := (R.Right - R.Left) + 28;
  if BtnW < 100 then
    BtnW := 100;
  if BtnW > pnlContainer.ClientWidth - 32 then
    BtnW := pnlContainer.ClientWidth - 32;
  btnCancel.Width := BtnW;
  btnCancel.Height := 26;
  btnCancel.Left := (pnlContainer.ClientWidth - BtnW) div 2;
  { TBitBtn bkCustom sem glyph pode pintar lixo � forcar repintura so com Caption. }
  btnCancel.Invalidate;
end;

procedure TfrmSmoothLoadingForm.AdjustLoadingMessageLayout(const MessageText: string);
const
  LOGO_HEIGHT     = 200;
  MSG_MIN_HEIGHT  = 25;
  DETAIL_MIN_H    = 18;
  PB_HEIGHT       = 12;
  PB_SIDE_MARGIN  = 80;
  GAP_AFTER_MSG   = 8;
  GAP_BEFORE_PB   = 12;
  GAP_PB_CANCEL   = 28;
  BOTTOM_PAD      = 22;
  MIN_CONTAINER_H = 400;
var
  R: TRect;
  CalcWidth: Integer;
  Y, NewMsgHeight, DetailHeight, NewContainerH: Integer;
  OldFont: HFONT;
begin
  if (not Assigned(lblMessage)) or (not Assigned(pnlContainer)) then
    Exit;

  { Align=alTop no DFM conflita com Top manual � layout explicito em cada ShowLoading. }
  if Assigned(imgLogo) then
  begin
    imgLogo.Align := alNone;
    imgLogo.Left := 0;
    imgLogo.Top := 0;
    imgLogo.Width := pnlContainer.ClientWidth;
    imgLogo.Height := LOGO_HEIGHT;
  end;

  lblMessage.Align := alNone;
  lblMessage.AutoSize := False;
  lblMessage.WordWrap := True;
  lblMessage.Alignment := taCenter;
  lblMessage.Layout := tlTop;
  lblMessage.Left := 0;
  lblMessage.Top := LOGO_HEIGHT;
  lblMessage.Width := pnlContainer.ClientWidth;

  CalcWidth := pnlContainer.ClientWidth - 32;
  if CalcWidth < 120 then
    CalcWidth := pnlContainer.ClientWidth - 16;

  R := Rect(0, 0, CalcWidth, 0);
  OldFont := SelectObject(lblMessage.Canvas.Handle, lblMessage.Font.Handle);
  try
    DrawText(lblMessage.Canvas.Handle, PChar(MessageText), Length(MessageText), R,
      DT_CALCRECT or DT_WORDBREAK or DT_CENTER or DT_NOPREFIX);
  finally
    SelectObject(lblMessage.Canvas.Handle, OldFont);
  end;

  NewMsgHeight := (R.Bottom - R.Top) + GAP_AFTER_MSG;
  if NewMsgHeight < MSG_MIN_HEIGHT then
    NewMsgHeight := MSG_MIN_HEIGHT;
  lblMessage.Height := NewMsgHeight;

  Y := LOGO_HEIGHT + NewMsgHeight;
  DetailHeight := 0;
  if Assigned(lblDetail) then
  begin
    lblDetail.Align := alNone;
    lblDetail.Left := 0;
    lblDetail.Width := pnlContainer.ClientWidth;
    lblDetail.Top := Y;
    if Trim(lblDetail.Caption) <> '' then
    begin
      lblDetail.Visible := True;
      lblDetail.WordWrap := True;
      lblDetail.Alignment := taCenter;
      R := Rect(0, 0, CalcWidth, 0);
      OldFont := SelectObject(lblDetail.Canvas.Handle, lblDetail.Font.Handle);
      try
        DrawText(lblDetail.Canvas.Handle, PChar(lblDetail.Caption),
          Length(lblDetail.Caption), R,
          DT_CALCRECT or DT_WORDBREAK or DT_CENTER or DT_NOPREFIX);
      finally
        SelectObject(lblDetail.Canvas.Handle, OldFont);
      end;
      DetailHeight := (R.Bottom - R.Top) + 4;
      if DetailHeight < DETAIL_MIN_H then
        DetailHeight := DETAIL_MIN_H;
      lblDetail.Height := DetailHeight;
      ApplyDetailLabelLook;
      Inc(Y, DetailHeight);
    end
    else
    begin
      lblDetail.Caption := '';
      lblDetail.Visible := False;
      lblDetail.Height := 0;
    end;
  end;

  Inc(Y, GAP_BEFORE_PB);
  if Assigned(pbProgressBar) then
  begin
    pbProgressBar.Align := alNone;
    pbProgressBar.Top := Y;
    pbProgressBar.Height := PB_HEIGHT;
    pbProgressBar.Width := pnlContainer.ClientWidth - (PB_SIDE_MARGIN * 2);
    if pbProgressBar.Width < 120 then
      pbProgressBar.Width := 120;
    pbProgressBar.Left := (pnlContainer.ClientWidth - pbProgressBar.Width) div 2;
    Inc(Y, PB_HEIGHT);
  end;

  Inc(Y, GAP_PB_CANCEL);
  if Assigned(btnCancel) then
  begin
    btnCancel.Align := alNone;
    btnCancel.Visible := True;
    LayoutCancelButton;
    btnCancel.Top := Y;
    Inc(Y, btnCancel.Height);
  end;

  NewContainerH := Y + BOTTOM_PAD;
  if NewContainerH < MIN_CONTAINER_H then
    NewContainerH := MIN_CONTAINER_H;
  pnlContainer.Width := 460;
  pnlContainer.Height := NewContainerH;
  CenterContainer;
end;

procedure TfrmSmoothLoadingForm.tmrAnimationTimer(Sender: TObject);
var
  Elapsed: Cardinal;
  NewAlpha: Integer;
  Tween: Extended;
begin
  if FFadeInActive and AlphaBlend then
  begin
    Elapsed := GetTickCount - FFadeStartTick;
    if FFadeDurationMS = 0 then
      NewAlpha := FFadeEndAlpha
    else if Elapsed >= FFadeDurationMS then
      NewAlpha := FFadeEndAlpha
    else
    begin
      { Smoothstep 0..1: acelera��o suave no in�cio e desacelera��o no fim }
      Tween := Elapsed / FFadeDurationMS;
      if Tween < 0 then Tween := 0 else if Tween > 1 then Tween := 1;
      Tween := Tween * Tween * (3.0 - 2.0 * Tween);
      NewAlpha := FFadeStartAlpha +
        Round((FFadeEndAlpha - FFadeStartAlpha) * Tween);
    end;

    if NewAlpha >= FFadeEndAlpha then
    begin
      SnapFullyOpaque;
    end
    else
    begin
      if NewAlpha < 1 then NewAlpha := 1;
      AlphaBlendValue := Byte(NewAlpha);
    end;
  end;

  if not FIsDeterminate then
  begin
    { Ping-pong pulse — never snap 0..100 (that looked like a looping bar). }
    if FMarqueeDir = 0 then
      FMarqueeDir := 1;
    FMarqueePos := FMarqueePos + (0.38 * FMarqueeDir);
    if FMarqueePos >= 100 then
    begin
      FMarqueePos := 100;
      FMarqueeDir := -1;
    end
    else if FMarqueePos <= 0 then
    begin
      FMarqueePos := 0;
      FMarqueeDir := 1;
    end;
  end
  else
  begin
    if Abs(FCurrentProgress - FTargetProgress) > 0.1 then
      FCurrentProgress := FCurrentProgress + (FTargetProgress - FCurrentProgress) * 0.15
    else if Abs(FCurrentProgress - FTargetProgress) > 0.001 then
    begin
      FCurrentProgress := FTargetProgress;
      FLastPaintedProgress := FCurrentProgress;
      if Assigned(pbProgressBar) then
        pbProgressBar.Invalidate;
    end
    else
      FCurrentProgress := FTargetProgress;
  end;

  if (not FIsDeterminate) or (Abs(FCurrentProgress - FTargetProgress) > 0.1) then
  begin
    if Abs(FLastPaintedProgress - FCurrentProgress) > 0.15 then
    begin
      FLastPaintedProgress := FCurrentProgress;
      if Assigned(pbProgressBar) then
        pbProgressBar.Invalidate;
    end;
    if not FIsDeterminate then
    begin
      if Assigned(pbProgressBar) then
        pbProgressBar.Invalidate;
    end;
  end;
end;

class procedure TfrmSmoothLoading.UpdateProgress(Percent: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  { Fora da main thread: PostMessage pode ser tratado em lote antes do
    paint visivel. SendMessage forca o proc. da janela na main thread ja
    aqui (bloqueia a worker ate pintar). }
  if GetCurrentThreadId = MainThreadID then
    frmSmoothLoading.ApplySmoothProgress(Percent)
  else if frmSmoothLoading.HandleAllocated then
    SendMessage(frmSmoothLoading.Handle, WM_APP + 77, WPARAM(Percent), 0);
end;

class procedure TfrmSmoothLoading.UpdateProgressMonotonic(Percent: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  if frmSmoothLoading.FTargetProgress > Percent then Exit;
  UpdateProgress(Percent);
end;

class procedure TfrmSmoothLoading.CreepProgress(AMaxPercent: Integer);
var
  Next: Double;
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if not frmSmoothLoading.FIsDeterminate then Exit;
  if AMaxPercent > 95 then AMaxPercent := 95;
  if AMaxPercent < 1 then Exit;
  if frmSmoothLoading.FTargetProgress >= AMaxPercent then Exit;
  Next := frmSmoothLoading.FTargetProgress + 1.15;
  if Next > AMaxPercent then
    Next := AMaxPercent;
  frmSmoothLoading.ApplySmoothProgressEx(Next);
end;

class procedure TfrmSmoothLoading.PostProgressFromWorker(Percent: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  if GetCurrentThreadId = MainThreadID then
    frmSmoothLoading.ApplySmoothProgress(Percent)
  else if frmSmoothLoading.HandleAllocated then
    PostMessage(frmSmoothLoading.Handle, WM_APP + 77, WPARAM(Percent), 0);
end;

class procedure TfrmSmoothLoading.PostProgressFineFromWorker(Permille: Integer);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Permille > 1000 then Permille := 1000;
  if Permille < 0 then Permille := 0;
  if GetCurrentThreadId = MainThreadID then
    frmSmoothLoading.ApplySmoothProgressEx(Permille / 10.0)
  else if frmSmoothLoading.HandleAllocated then
    PostMessage(frmSmoothLoading.Handle, WM_APP + 77, WPARAM(Permille), 1);
end;

class procedure TfrmSmoothLoading.PostProgressWithDetailFromWorker(Percent: Integer; const Detail: string);
var
  P: PChar;
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Percent > 100 then Percent := 100;
  if Percent < 0 then Percent := 0;
  if not frmSmoothLoading.HandleAllocated then Exit;

  { Allocate a copy for the UI thread to own. }
  P := StrNew(PChar(Detail));
  PostMessage(frmSmoothLoading.Handle, WM_APP + 78, WPARAM(Percent), LPARAM(P));
end;

class procedure TfrmSmoothLoading.PostDetailFromWorker(const Detail: string);
var
  P: PChar;
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if not frmSmoothLoading.HandleAllocated then Exit;
  P := StrNew(PChar(Detail));
  PostMessage(frmSmoothLoading.Handle, WM_APP + 79, 0, LPARAM(P));
end;

class procedure TfrmSmoothLoading.UpdateProgressWithDetail(Percent: Integer; const Detail: string);
begin
  UpdateProgress(Percent);
  if (GetCurrentThreadId = MainThreadID)
    and Assigned(frmSmoothLoading)
    and Assigned(frmSmoothLoading.lblDetail) then
  begin
    frmSmoothLoading.lblDetail.Caption := Detail;
    frmSmoothLoading.lblDetail.Visible := Trim(Detail) <> '';
    frmSmoothLoading.ApplyDetailLabelLook;
  end;
end;

class procedure TfrmSmoothLoading.FlushPaint;
begin
  { Forces all pending paints on the loading form to be processed immediately.
    Required when the caller is about to enter a blocking main-thread loop
    (e.g. BatchDeleteLinesByMMF), since the VCL message pump won't run. }
  if not Assigned(frmSmoothLoading) then Exit;
  if Assigned(frmSmoothLoading.pbProgressBar) then
    frmSmoothLoading.pbProgressBar.Repaint;
  if frmSmoothLoading.HandleAllocated then
    frmSmoothLoading.Update;
end;

class procedure TfrmSmoothLoading.SnapFullyOpaque;
begin
  if not Assigned(frmSmoothLoading) then Exit;
  frmSmoothLoading.SnapFullyOpaque;
  if frmSmoothLoading.HandleAllocated then
    frmSmoothLoading.Update;
end;

class procedure TfrmSmoothLoading.BeginScriptEngineProgress;
begin
  GScriptEngineProgressImmediate := True;
  { Wait overlay must be solid — a long fade hid the bar during RUNFILE. }
  if Assigned(frmSmoothLoading) then
    TfrmSmoothLoading.SnapFullyOpaque;
end;

class procedure TfrmSmoothLoading.EndScriptEngineProgress;
begin
  GScriptEngineProgressImmediate := False;
end;

class procedure TfrmSmoothLoading.RequestCancel;
begin
  GDownloadCancelled := True;
end;

class function TfrmSmoothLoading.CancelRequested: Boolean;
begin
  Result := GDownloadCancelled;
end;

class procedure TfrmSmoothLoading.SetCancelVisible(AVisible: Boolean);
begin
  if not Assigned(frmSmoothLoading) then Exit;
  if Assigned(frmSmoothLoading.btnCancel) then
  begin
    frmSmoothLoading.btnCancel.Visible := AVisible;
    frmSmoothLoading.btnCancel.Enabled := AVisible;
  end;
end;

class procedure TfrmSmoothLoading.ResetCancel;
begin
  GDownloadCancelled := False;
end;

class function TfrmSmoothLoading.PumpCancelInput: Boolean;
var
  Msg: TMsg;
  Wnd: HWND;
  CancelUsable: Boolean;
begin
  if Assigned(frmSmoothLoading) and frmSmoothLoading.HandleAllocated then
  begin
    Wnd := frmSmoothLoading.Handle;
    CancelUsable := Assigned(frmSmoothLoading.btnCancel) and
      frmSmoothLoading.btnCancel.Visible and frmSmoothLoading.btnCancel.Enabled;
    while PeekMessage(Msg, 0, WM_MOUSEFIRST, WM_MOUSELAST, PM_REMOVE) do
      if (Msg.hwnd = Wnd) or IsChild(Wnd, Msg.hwnd) then
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
    while PeekMessage(Msg, 0, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE) do
      if CancelUsable and (Msg.message = WM_KEYDOWN) and (Msg.wParam = VK_ESCAPE) then
        frmSmoothLoading.btnCancelClick(frmSmoothLoading.btnCancel);
    if frmSmoothLoading.HandleAllocated then
      frmSmoothLoading.Update;
  end;
  Result := GDownloadCancelled;
end;

var
  GKeepAliveTick: Cardinal = 0;
  GKeepAliveCreepTick: Cardinal = 0;

class function TfrmSmoothLoading.KeepAlive(AMaxPercent: Integer): Boolean;
var
  NowTick: Cardinal;
  Msg: TMsg;
  Wnd: HWND;
  Guard: Integer;
begin
  Result := GDownloadCancelled;
  if not Assigned(frmSmoothLoading) or not frmSmoothLoading.HandleAllocated then Exit;
  NowTick := GetTickCount;
  if NowTick - GKeepAliveTick < 30 then Exit;
  GKeepAliveTick := NowTick;
  { Skinned panels are costly to repaint: ~10 fps is enough to look alive. }
  if NowTick - GKeepAliveCreepTick < 100 then
  begin
    Result := PumpCancelInput;
    Exit;
  end;
  GKeepAliveCreepTick := NowTick;
  CreepProgress(AMaxPercent);
  frmSmoothLoading.tmrAnimationTimer(nil);
  Wnd := frmSmoothLoading.Handle;
  Guard := 0;
  while (Guard < 32) and PeekMessage(Msg, 0, WM_PAINT, WM_PAINT, PM_NOREMOVE) and
    ((Msg.hwnd = Wnd) or IsChild(Wnd, Msg.hwnd)) do
  begin
    PeekMessage(Msg, Msg.hwnd, WM_PAINT, WM_PAINT, PM_REMOVE);
    DispatchMessage(Msg);
    Inc(Guard);
  end;
  Result := PumpCancelInput;
end;

class procedure TfrmSmoothLoading.SetHeavyFileMutateHold(AActive: Boolean);
begin
  GHeavyFileMutateHold := AActive;
end;

class function TfrmSmoothLoading.HeavyFileMutateHoldActive: Boolean;
begin
  Result := GHeavyFileMutateHold;
end;

class function TfrmSmoothLoading.IndexReadShouldStop: Boolean;
begin
  Result := GDownloadCancelled or GHeavyFileMutateHold;
end;

procedure TfrmSmoothLoadingForm.btnCancelClick(Sender: TObject);
begin
  TfrmSmoothLoading.RequestCancel;
  if Assigned(btnCancel) then
  begin
    btnCancel.Caption := TrText('Cancelling...');
    btnCancel.Enabled := False;
    LayoutCancelButton;
    ApplyCancelButtonLook;
  end;
end;

procedure TfrmSmoothLoadingForm.FormPaint(Sender: TObject);
var
  ClipRgn: HRGN;
  R: Integer;
begin
  { Gradiente + borda: recorte arredondado no canvas (layered + AlphaBlend costuma ignorar s� SetWindowRgn). }
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;
  R := FFormCornerRadius;
  ClipRgn := CreateRoundRectRgn(0, 0, ClientWidth + 1, ClientHeight + 1, R, R);
  try
    SelectClipRgn(Canvas.Handle, ClipRgn);
    if (FBackgroundBmp.Width <> ClientWidth) or (FBackgroundBmp.Height <> ClientHeight) then
      BuildBackground;
    if (FBackgroundBmp.Width = ClientWidth) and (FBackgroundBmp.Height = ClientHeight) then
      Canvas.Draw(0, 0, FBackgroundBmp)
    else
    begin
      Canvas.Brush.Color := RGB(20, 30, 50);
      Canvas.FillRect(ClientRect);
    end;
  finally
    SelectClipRgn(Canvas.Handle, 0);
    DeleteObject(ClipRgn);
  end;

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Mode := pmCopy;
  Canvas.Pen.Color := RGB(120, 170, 230);
  Canvas.Pen.Width := 2;
  { Delphi 7: TCanvas n�o exp�e RoundRect � API Win32. }
  Windows.RoundRect(Canvas.Handle, 2, 2, ClientWidth - 2, ClientHeight - 2, R, R);
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

procedure TfrmSmoothLoadingForm.ApplyFormRoundCorners(Radius: Integer);
var
  Rgn: HRGN;
begin
  if (not HandleAllocated) or (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;
  Rgn := CreateRoundRectRgn(0, 0, ClientWidth + 1, ClientHeight + 1, Radius, Radius);
  SetWindowRgn(Handle, Rgn, True);
  { For�a o sistema a respeitar a regi�o com janela em camadas. }
  RedrawWindow(Handle, nil, 0, RDW_INVALIDATE or RDW_FRAME or RDW_UPDATENOW);
end;

procedure TfrmSmoothLoadingForm.ApplyCancelButtonLook;
begin
  if (not Assigned(btnCancel)) or (not Assigned(pnlContainer)) then
    Exit;
  { Estilo link: este TBitBtn (Delphi 7) n�o publica Color/Ctl3D/Flat � s� tipografia. }
  btnCancel.ParentFont := False;
  btnCancel.Font.Name := 'Segoe UI';
  btnCancel.Font.Height := -12;
  btnCancel.Font.Style := [fsUnderline];
  if btnCancel.Enabled then
    btnCancel.Font.Color := $0098ECFF
  else
    btnCancel.Font.Color := $00687888;
end;

procedure TfrmSmoothLoadingForm.ApplyDetailLabelLook;
begin
  if not Assigned(lblDetail) then
    Exit;
  lblDetail.ParentFont := False;
  lblDetail.ParentColor := False;
  lblDetail.Color := pnlContainer.Color;
  lblDetail.Font.Name := 'Segoe UI';
  lblDetail.Font.Height := -11;
  lblDetail.Font.Style := [];
  { Legivel no painel azul-escuro (evita preto apos ApplyTranslationsToForm). }
  lblDetail.Font.Color := $00D8ECFF;
end;

procedure TfrmSmoothLoadingForm.WMShowWindow(var Msg: TWMShowWindow);
begin
  inherited;
  if Msg.Show then
    QueueReapplyRoundRegions;
end;

procedure TfrmSmoothLoadingForm.WMActivateApp(var Msg: TWMActivateApp);
begin
  inherited;
  if Msg.Active then
    QueueReapplyRoundRegions;
end;

procedure TfrmSmoothLoadingForm.WMActivate(var Msg: TWMActivate);
begin
  inherited;
  if Msg.Active <> WA_INACTIVE then
    QueueReapplyRoundRegions;
end;

procedure TfrmSmoothLoadingForm.WMWindowPosChanged(var Msg: TWMWindowPosChanged);
begin
  inherited;
  if (Msg.WindowPos <> nil) and ((Msg.WindowPos^.flags and SWP_SHOWWINDOW) <> 0) then
    QueueReapplyRoundRegions;
end;

procedure TfrmSmoothLoadingForm.QueueReapplyRoundRegions;
begin
  if FRoundRgnPending or (not HandleAllocated) then
    Exit;
  FRoundRgnPending := True;
  PostMessage(Handle, WM_FF_APPLYROUNDRGN, 0, 0);
end;

procedure TfrmSmoothLoadingForm.ReapplyRoundRegions;
begin
  if (not HandleAllocated) or (not Visible) or IsIconic(Handle) then
    Exit;
  if Assigned(pnlContainer) and pnlContainer.HandleAllocated then
    RoundControl(pnlContainer, 56);
  ApplyFormRoundCorners(FFormCornerRadius);
  RedrawWindow(Handle, nil, 0,
    RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or RDW_ALLCHILDREN or RDW_UPDATENOW);
end;

procedure TfrmSmoothLoadingForm.WMFfApplyRoundRgn(var Msg: TMessage);
begin
  FRoundRgnPending := False;
  ReapplyRoundRegions;
end;

procedure TfrmSmoothLoadingForm.LoadLogo;
var PathLogo: String;
begin
  PathLogo := ExtractFilePath(Application.ExeName) + LOGO;
  if FileExists(PathLogo) then imgLogo.Picture.LoadFromFile(PathLogo);
end;

class procedure TfrmSmoothLoading.HideLoading;
begin
  GScriptEngineProgressImmediate := False;
  if Assigned(frmMain) then
    if CancelRequested then
      frmMain.FinishOperationStatus(fssCancelled)
    else
      frmMain.FinishOperationStatus(fssReady);
  if Assigned(frmSmoothLoading) then
  begin
    frmSmoothLoading.tmrAnimation.Enabled := False;
    FreeAndNil(frmSmoothLoading);
  end;
end;

procedure TfrmSmoothLoadingForm.FormShow(Sender: TObject);
begin
  ApplyTranslationsToForm(Self);
  ForceFullScreen;
  LoadLogo;
  CenterContainer;
  ApplyCancelButtonLook;
  ApplyDetailLabelLook;
  ApplyFormRoundCorners(FFormCornerRadius);
  Self.Repaint;
end;

procedure TfrmSmoothLoadingForm.FormResize(Sender: TObject);
begin
  if Assigned(lblMessage) and (Trim(lblMessage.Caption) <> '') then
    AdjustLoadingMessageLayout(lblMessage.Caption);
  ApplyFormRoundCorners(FFormCornerRadius);
  Invalidate;
end;

{ ============================================================================ }
{ TReplaceAllThread: FIND & REPLACE ALL                                        }
{ ============================================================================ }

constructor TReplaceAllThread.Create(const AFileName, AFindText, AReplaceText: String;
  const ACaseSensitive, AWholeWord: Boolean;
  const AutoHide: Boolean; const ShowUI: Boolean;
  const ASegmented: Boolean; const AIndexFileName: string;
  const ALinesPerSegment: Integer;
  const AOutputOverride: string;
  const ASilent: Boolean;
  const AFreeOnTerminate: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := AFreeOnTerminate;
  FFileName := AFileName;
  FFindText := AFindText;
  FReplaceText := AReplaceText;
  FEncoding := '';
  FFindBytes := '';
  FReplaceBytes := '';
  FCaseSensitive := ACaseSensitive;
  FWholeWord := AWholeWord;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FSegmented := ASegmented;
  FIndexFileName := AIndexFileName;
  if ALinesPerSegment < 5000 then
    FLinesPerSegment := 5000
  else
    FLinesPerSegment := ALinesPerSegment;
  FOutputOverride := AOutputOverride;
  FSilent := ASilent;
  FReplacedCount := 0;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Replacing (streaming to temp file)...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  FReplaceLimitHit := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TReplaceAllThread.Destroy;
begin
  if Assigned(sw) then sw.Free;
  inherited;
end;

procedure TReplaceAllThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TReplaceAllThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TReplaceAllThread.SyncSetProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TReplaceAllThread.SyncProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgressWithDetail(FPercentToSync, FDetailSync);
end;

procedure TReplaceAllThread.SyncError;
begin
  if (FErrorMsg <> '') and (not FSilent) then
    AppMessageDlg(TrText('[ReplaceAll] Error: ') + FErrorMsg, mtError, [mbOK], 0);
end;

procedure TReplaceAllThread.SyncReleaseSourceHandles;
begin
  { BeginHeavyFileMutate ja libertou handles; evita segundo ciclo de espera/Sleep. }
  if Assigned(frmMain) and (not TfrmSmoothLoading.HeavyFileMutateHoldActive) then
    TfrmMain(frmMain).ReleaseSourceFileHandlesBeforeMutate;
end;

procedure TReplaceAllThread.SyncCloseHandlesBeforeRename;
begin
  if Assigned(frmMain) then
    TfrmMain(frmMain).CloseSourceHandlesForRename;
end;

function TReplaceAllThread.GetReplaceOutputTarget: string;
begin
  if FOutputOverride <> '' then
    Result := FOutputOverride
  else
    Result := FFileName;
end;

function TReplaceAllThread.CommitReplaceOutputOnWorker: Boolean;
var
  Err: string;
  I: Integer;
  Target: string;
begin
  Result := False;
  FSuccess := False;
  FErrorMsg := '';
  if not ReplaceTempOutputReady(FTempFileName, FErrorMsg) then
    Exit;
  Target := GetReplaceOutputTarget;
  if (FOutputOverride = '') and Assigned(frmMain) then
    Synchronize(SyncCloseHandlesBeforeRename);
  for I := 1 to 6 do
  begin
    if UnUtils.TryRenameTempOverTarget(FTempFileName, Target, Err) then
    begin
      FSuccess := True;
      FErrorMsg := '';
      Result := True;
      Exit;
    end;
    FErrorMsg := Err;
    if I < 6 then
      Sleep(50 * I);
  end;
end;

procedure TReplaceAllThread.FinishThread;
var
  TimerStr: String;
begin
  if Assigned(frmMain) then
    TfrmMain(frmMain).EndHeavyFileMutate;
  if FShowLoadingUI then
  begin
    if FAutoHide then
      TfrmSmoothLoading.HideLoading;
  end;

  if FSuccess then
  begin
    if (Trim(FFileName) <> '') then
    begin
      FFHistoryAppendReplaceAll(FFileName, FReplacedCountSync, FReplaceLimitHit,
        Copy(FFindText, 1, 200), Copy(FReplaceText, 1, 200));
      if Assigned(frmMain) then
        frmMain.NotifyHistoryTouched(FFileName);
    end;
    sw.Stop;
    TimerStr := Format(TrText('Replace All completed. %d replacement(s). Time: %s ms.'),
      [FReplacedCountSync, IntToStr(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) and (not FSilent) then
    begin
      frmMain.AppendOperationTimerLog(TimerStr);
      frmMain.RequestPostEditRefresh;
      frmMain.AssistantOfferAfterActivity('replace', TimerStr);
    end;
  end
  else if FReplaceLimitHit and (FErrorMsg <> '') then
  begin
    if not FSilent then
      AppMessageDlg(FErrorMsg, mtWarning, [mbOK], 0);
  end
  else if (not FSuccess) and (FErrorMsg <> '') then
  begin
    if not FSilent then
      AppMessageDlg(TrText('[ReplaceAll] ') + FErrorMsg, mtError, [mbOK], 0);
  end;
end;

function ReadIndexLineStart1Based(Idx: TFileStream; LineIdx0: Int64): Int64;
var
  OffsetStr: AnsiString;
begin
  Result := -1;
  if (not Assigned(Idx)) or (LineIdx0 < 0) then Exit;
  Idx.Seek(LineIdx0 * INDEX_RECORD_SIZE, soFromBeginning);
  SetLength(OffsetStr, 18);
  if Idx.Read(Pointer(OffsetStr)^, 18) < 18 then Exit;
  Result := StrToInt64Def(Trim(string(OffsetStr)), -1);
end;

procedure CopyFileRangeToFile(const SourcePath: string; Start0, Len: Int64; const DestPath: string);
var
  FS, FD: TFileStream;
  Buf: array[0..65535] of Byte;
  Rem: Int64;
  n, r: Integer;
begin
  FS := TFileStream.Create(SourcePath, fmOpenRead or fmShareDenyNone);
  try
    FD := TFileStream.Create(DestPath, fmCreate);
    try
      FS.Position := Start0;
      Rem := Len;
      while Rem > 0 do
      begin
        if Rem > SizeOf(Buf) then
          n := SizeOf(Buf)
        else
          n := Integer(Rem);
        r := FS.Read(Buf, n);
        if r <= 0 then Break;
        FD.WriteBuffer(Buf, r);
        Dec(Rem, r);
      end;
    finally
      FD.Free;
    end;
  finally
    FS.Free;
  end;
end;

procedure AppendFileToStream(Dest: TFileStream; const FilePath: string);
var
  S: TFileStream;
begin
  S := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
  try
    Dest.CopyFrom(S, S.Size);
  finally
    S.Free;
  end;
end;

function LineInSortedInt64Array(const A: array of Int64; V: Int64): Boolean;
var
  L, H, M: Integer;
begin
  L := Low(A);
  H := High(A);
  if H < L then
  begin
    Result := False;
    Exit;
  end;
  while L <= H do
  begin
    M := (L + H) shr 1;
    if A[M] = V then
    begin
      Result := True;
      Exit;
    end;
    if A[M] < V then
      L := M + 1
    else
      H := M - 1;
  end;
  Result := False;
end;

procedure CopyStreamRangeBytes(Src: TFileStream; Dest: TFileStream; Len: Int64);
var
  Buf: array[0..65535] of Byte;
  Rem: Int64;
  n, r: Integer;
begin
  Rem := Len;
  while Rem > 0 do
  begin
    if Rem > SizeOf(Buf) then
      n := SizeOf(Buf)
    else
      n := Integer(Rem);
    r := Src.Read(Buf, n);
    if r <= 0 then
      Break;
    Dest.WriteBuffer(Buf, r);
    Dec(Rem, r);
  end;
end;

procedure WriteSegmentKeepLines(Idx: TFileStream; Src: TFileStream;
  TotalLines: Int64; LineStart, LineEnd: Int64;
  const LinesToDelete: array of Int64; const DestPath: string;
  out ALocalErr: string);
var
  OutF: TFileStream;
  L0: Int64;
  Line1: Int64;
  Start1, Next1: Int64;
  Len0: Int64;
  Start0: Int64;
begin
  ALocalErr := '';
  OutF := TFileStream.Create(DestPath, fmCreate);
  try
    L0 := LineStart;
    while L0 <= LineEnd do
    begin
      Line1 := L0 + 1;
      if LineInSortedInt64Array(LinesToDelete, Line1) then
      begin
        Inc(L0);
        Continue;
      end;
      Start1 := ReadIndexLineStart1Based(Idx, L0);
      if Start1 < 1 then
      begin
        ALocalErr := TrText('Segmented replace: invalid line index in temp.txt.');
        Exit;
      end;
      if L0 + 1 < TotalLines then
        Next1 := ReadIndexLineStart1Based(Idx, L0 + 1)
      else
        Next1 := Src.Size + 1;
      Len0 := Next1 - Start1;
      if Len0 <= 0 then
      begin
        ALocalErr := TrText('Segmented replace: invalid line index in temp.txt.');
        Exit;
      end;
      Start0 := Start1 - 1;
      Src.Position := Start0;
      CopyStreamRangeBytes(Src, OutF, Len0);
      Inc(L0);
    end;
  finally
    OutF.Free;
  end;
end;

function CanUseSegmentedBatchDelete(const IndexFileName: string;
  LinesPerSegment: Integer): Boolean;
var
  TotalLines, TotalParts: Int64;
begin
  Result := False;
  if (IndexFileName = '') or (not FileExists(IndexFileName)) then Exit;
  if LinesPerSegment < 5000 then
    LinesPerSegment := 5000;
  TotalLines := GetFileSize(IndexFileName) div INDEX_RECORD_SIZE;
  if TotalLines < 2 then Exit;
  TotalParts := (TotalLines + LinesPerSegment - 1) div LinesPerSegment;
  Result := TotalParts > 1;
end;

function TrySegmentedBatchDelete(const FileName, IndexFileName: string;
  const LinesToDelete1Based: array of Int64; LinesPerSegment: Integer;
  out AErrorMsg: string): Boolean;
var
  Idx, Src, Merge: TFileStream;
  TotalLines: Int64;
  TotalParts: Int64;
  CurrentPart: Int64;
  ProgressPct: Integer;
  LineStart, LineEnd: Int64;
  SegOut, FTempMerge: string;
  FinalErr: string;
  LocalErr: string;
  Aborted: Boolean;
begin
  Result := False;
  AErrorMsg := '';
  if (IndexFileName = '') or (not FileExists(IndexFileName)) then
    Exit;
  if High(LinesToDelete1Based) < Low(LinesToDelete1Based) then
    Exit;
  if LinesPerSegment < 5000 then
    LinesPerSegment := 5000;

  Idx := nil;
  Src := nil;
  Merge := nil;
  FTempMerge := '';
  try
    Idx := TFileStream.Create(IndexFileName, fmOpenRead or fmShareDenyNone);
    Src := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      TotalLines := Idx.Size div INDEX_RECORD_SIZE;
      if TotalLines < 2 then
        Exit;

      TotalParts := (TotalLines + LinesPerSegment - 1) div LinesPerSegment;
      if TotalParts <= 1 then
        Exit;

      if not VolumeHasSpaceForAtomicRewrite(FileName, GetFileSize(FileName)) then
      begin
        AErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
        Result := True;
        Exit;
      end;

      FTempMerge := NewFastFileTemp('bdel');
      UnUtils.TryDeleteFileWithRetry(FTempMerge, 12, 80);
      Merge := TFileStream.Create(FTempMerge, fmCreate);
      Aborted := False;
      try
        LineStart := 0;
        CurrentPart := 0;
        TfrmSmoothLoading.UpdateProgressWithDetail(0, TrText('Deleting selected lines...'));
        while LineStart < TotalLines do
        begin
          LineEnd := LineStart + LinesPerSegment - 1;
          if LineEnd >= TotalLines then
            LineEnd := TotalLines - 1;

          SegOut := NewFastFileTemp('dseg_out');
          UnUtils.TryDeleteFileWithRetry(SegOut, 12, 80);
          try
            WriteSegmentKeepLines(Idx, Src, TotalLines, LineStart, LineEnd,
              LinesToDelete1Based, SegOut, LocalErr);
            if LocalErr <> '' then
            begin
              AErrorMsg := LocalErr;
              Aborted := True;
              Break;
            end;
            AppendFileToStream(Merge, SegOut);
          finally
            UnUtils.TryDeleteFileWithRetry(SegOut, 12, 80);
          end;

          Inc(CurrentPart);
          if TotalParts > 0 then
            ProgressPct := (CurrentPart * 90) div TotalParts
          else
            ProgressPct := 90;
          TfrmSmoothLoading.UpdateProgressWithDetail(ProgressPct,
            Format(TrText('Deleting selected lines... (part %d of %d)'), [CurrentPart, TotalParts]));

          LineStart := LineEnd + 1;
        end;
      finally
        FreeAndNil(Merge);
      end;

      if Aborted then
      begin
        UnUtils.TryDeleteFileWithRetry(FTempMerge, 12, 80);
        Result := True;
        Exit;
      end;
    finally
      FreeAndNil(Idx);
      FreeAndNil(Src);
    end;

    TfrmSmoothLoading.UpdateProgressWithDetail(95, TrText('Saving file...'));
    FinalErr := '';
    if not UnUtils.TryRenameTempOverTarget(FTempMerge, FileName, FinalErr) then
      AErrorMsg := FinalErr
    else
    begin
      TfrmSmoothLoading.UpdateProgressWithDetail(100, TrText('Saving file...'));
      AErrorMsg := '';
    end;
    Result := True;
  except
    on E: Exception do
    begin
      AErrorMsg := E.Message;
      Result := True;
      FreeAndNil(Merge);
      FreeAndNil(Idx);
      FreeAndNil(Src);
      if FTempMerge <> '' then
        UnUtils.TryDeleteFileWithRetry(FTempMerge, 12, 80);
    end;
  end;
end;

{ ---------------------------------------------------------------------------
  BatchDeleteLinesByMMF
  Full MMF scan: copies every line that is NOT in ALinesToDelete1Based to a
  temp file, then atomically renames it over the original.
  ALinesToDelete1Based must be sorted ASCENDING (binary search inside).
  Same IO pattern as TEditFileThread.Execute for otDelete ? never calls
  SetEndOfFile/Stream.Size, so it never raises EOSError.
  --------------------------------------------------------------------------- }
function BatchDeleteLinesByMMF(const AFileName: string;
  const ALinesToDelete1Based: array of Int64;
  out AErrorMsg: string; out AFinalLineCount: Int64): Boolean;
var
  MMF: TMMFReader;
  DestWriter, CkptWriter: TBufferedTextWriter;
  TempFileName, CkptFileName, CkptTempName: string;
  P, PLineStart: PAnsiChar;
  Contiguous: Cardinal;
  AbsOffset: Int64;
  TotalSize: Int64;
  CurrentLine, OutLineCount: Int64;
  i, LineLen: Integer;
  FinalErr: string;
  LastPct, Pct: Integer;
  CkptCountdown: Integer;
  TermCh: AnsiChar;

  procedure OnKeptLineWritten;
  begin
    Inc(OutLineCount);
    Dec(CkptCountdown);
    if CkptCountdown = 0 then
    begin
      CkptWriter.WriteOffsetDirect(DestWriter.CurrentFileSize + 1);
      CkptCountdown := CKPT_INTERVAL;
    end;
  end;

begin
  Result := False;
  AErrorMsg := '';
  AFinalLineCount := 0;

  if High(ALinesToDelete1Based) < Low(ALinesToDelete1Based) then
  begin
    AErrorMsg := 'No lines specified for deletion.';
    Exit;
  end;

  TempFileName := NewFastFileTemp('bdel2');
  UnUtils.TryDeleteFileWithRetry(TempFileName, 12, 80);
  CkptFileName := FastFileExeDirPath(TEMP_CKPT_FILE);
  CkptTempName := NewFastFileTemp('ckptb');
  UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);

  MMF := nil;
  DestWriter := nil;
  CkptWriter := nil;
  try
    try
      begin
      MMF := TMMFReader.Create(AFileName);
      TotalSize := MMF.FileSize;

      if not VolumeHasSpaceForAtomicRewrite(AFileName, TotalSize) then
      begin
        AErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
        Exit;
      end;

      DestWriter := TBufferedTextWriter.Create(TempFileName, 16 * 1024 * 1024);
      CkptWriter := TBufferedTextWriter.Create(CkptTempName, 2 * 1024 * 1024);
      CkptCountdown := CKPT_INTERVAL;
      OutLineCount := 0;
      CkptWriter.WriteOffsetDirect(1);
      CurrentLine := 1;
      AbsOffset := 0;
      LastPct := 0;
      TermCh := LineTermCharForFile(AFileName);

      while AbsOffset < TotalSize do
      begin
        P := PAnsiChar(MMF.PtrAt(AbsOffset, 1, Contiguous));
        if (P = nil) or (Contiguous = 0) then Break;

        PLineStart := P;
        for i := 0 to Integer(Contiguous) - 1 do
        begin
          if P^ = TermCh then
          begin
            LineLen := (P - PLineStart) + 1;
            if not LineInSortedInt64Array(ALinesToDelete1Based, CurrentLine) then
            begin
              DestWriter.WriteRaw(PLineStart, LineLen);
              OnKeptLineWritten;
            end;
            Inc(CurrentLine);
            PLineStart := P + 1;
          end;
          Inc(P);
        end;
        AbsOffset := AbsOffset + Contiguous;

        { Report progress in a thread-safe way (worker or main thread).
          Keep 0..90% for scan/copy; caller reserves the tail for final save. }
        if TotalSize > 0 then
          Pct := Trunc((AbsOffset * 90.0) / TotalSize)
        else
          Pct := 0;
        if Pct > 90 then Pct := 90;
        if Pct > LastPct then
        begin
          LastPct := Pct;
          TfrmSmoothLoading.PostProgressFromWorker(Pct);
        end;
      end;

      AFinalLineCount := OutLineCount;
      FreeAndNil(CkptWriter);
      FreeAndNil(DestWriter);
      FreeAndNil(MMF);

      Result := UnUtils.TryRenameTempOverTarget(TempFileName, AFileName, FinalErr);
      if not Result then
        AErrorMsg := FinalErr
      else
      begin
        if not UnUtils.TryRenameTempOverTarget(CkptTempName, CkptFileName, FinalErr) then
        begin
          Result := False;
          AErrorMsg := FinalErr;
        end;
      end;
      end;
    except
      on E: Exception do
      begin
        AErrorMsg := E.Message;
        FreeAndNil(CkptWriter);
        FreeAndNil(DestWriter);
        FreeAndNil(MMF);
        UnUtils.TryDeleteFileWithRetry(TempFileName, 12, 80);
        UnUtils.TryDeleteFileWithRetry(CkptTempName, 12, 80);
      end;
    end;
  finally
    FreeAndNil(CkptWriter);
    FreeAndNil(DestWriter);
    FreeAndNil(MMF);
  end;
end;

function TReplaceAllThread.TrySegmentedReplace: Boolean;
var
  Idx, Src: TFileStream;
  Merge: TFileStream;
  TotalLines: Int64;
  TotalParts: Int64;
  PartI: Integer;
  LineStart, LineEnd: Int64;
  Start1, Next1: Int64;
  Len0: Int64;
  Start0: Int64;
  SegIn, SegOut: string;
  Inner: TReplaceAllThread;
  Pct: Integer;
begin
  Result := False;
  if (FIndexFileName = '') or (not FileExists(FIndexFileName)) then Exit;

  Idx := nil;
  Src := nil;
  Merge := nil;
  try
    try
    Idx := TFileStream.Create(FIndexFileName, fmOpenRead or fmShareDenyNone);
    Src := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
    TotalLines := Idx.Size div INDEX_RECORD_SIZE;
    if TotalLines < 2 then Exit;

    TotalParts := (TotalLines + FLinesPerSegment - 1) div FLinesPerSegment;
    if TotalParts <= 1 then Exit;

    if not VolumeHasSpaceForAtomicRewrite(FFileName, GetFileSize(FFileName)) then
    begin
      FErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
      FSuccess := False;
      FReplacedCountSync := 0;
      Synchronize(FinishThread);
      Result := True;
      Exit;
    end;

    FTempFileName := AllocateReplaceScratchTemp(FFileName);
    ForceDeleteScratchPath(FTempFileName);
    Merge := TFileStream.Create(FTempFileName, fmCreate);
    FSuccess := True;
    try
      FReplacedCount := 0;
      FCurrentPercent := 0;

      PartI := 0;
      LineStart := 0;
      while LineStart < TotalLines do
      begin
        if Terminated then Break;

        LineEnd := LineStart + FLinesPerSegment - 1;
        if LineEnd >= TotalLines then
          LineEnd := TotalLines - 1;

        Start1 := ReadIndexLineStart1Based(Idx, LineStart);
        if Start1 < 1 then
        begin
          FErrorMsg := TrText('Segmented replace: invalid line index in temp.txt.');
          FSuccess := False;
          Break;
        end;

        if LineEnd + 1 < TotalLines then
          Next1 := ReadIndexLineStart1Based(Idx, LineEnd + 1)
        else
          Next1 := Src.Size + 1;

        Len0 := Next1 - Start1;
        if Len0 <= 0 then
        begin
          Inc(PartI);
          LineStart := LineEnd + 1;
          Continue;
        end;

        Start0 := Start1 - 1;
        SegIn := NewReplaceScratchTemp(FFileName, 'rseg_in');
        SegOut := NewReplaceScratchTemp(FFileName, 'rseg_out');
        ForceDeleteScratchPath(SegIn);
        ForceDeleteScratchPath(SegOut);

        try
          CopyFileRangeToFile(FFileName, Start0, Len0, SegIn);

          Inner := TReplaceAllThread.Create(SegIn, FFindText, FReplaceText,
            FCaseSensitive, FWholeWord, False, False,
            False, '', FLinesPerSegment, SegOut, True, False);
          Inner.WaitFor;
          try
            if not Inner.OperationSucceeded then
            begin
              FSuccess := False;
              if Inner.LastErrorMsg <> '' then
                FErrorMsg := Inner.LastErrorMsg
              else
                FErrorMsg := TrText('[ReplaceAll] Segmented part failed.');
              Break;
            end;
            Inc(FReplacedCount, Inner.ReplacedTotal);
            if FReplacedCount >= REPLACE_ALL_MATCH_LIMIT then
            begin
              FReplaceLimitHit := True;
              FErrorMsg := Format(TrText('Replace-all stopped at the safety limit of %d matches. The file was not modified.'),
                [REPLACE_ALL_MATCH_LIMIT]);
              FSuccess := False;
              Break;
            end;
            if not FileExists(SegOut) then
            begin
              FErrorMsg := TrText('[ReplaceAll] Segmented output missing.');
              FSuccess := False;
              Break;
            end;
            AppendFileToStream(Merge, SegOut);
          finally
            Inner.Free;
          end;
        finally
          ForceDeleteScratchPath(SegIn);
          ForceDeleteScratchPath(SegOut);
        end;

        Pct := Round(((PartI + 1) * 100.0) / TotalParts);
        if Pct > 100 then Pct := 100;
        if (Pct > FCurrentPercent) or (PartI + 1 >= TotalParts) then
        begin
          FCurrentPercent := Pct;
          FPercentToSync := Pct;
          FDetailSync := Format(TrText('Replacing... (part %d of %d) - %d replacements'),
            [PartI + 1, TotalParts, FReplacedCount]);
          if FShowLoadingUI then
            TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
        end;

        Inc(PartI);
        LineStart := LineEnd + 1;
      end;
    finally
      FreeAndNil(Merge);
    end;

    if Terminated then
    begin
      FSuccess := False;
      FErrorMsg := TrText('Operation cancelled.');
      ForceDeleteScratchPath(FTempFileName);
      FReplacedCountSync := FReplacedCount;
      Synchronize(FinishThread);
      Result := True;
      Exit;
    end;

    if FReplaceLimitHit or (not FSuccess) then
    begin
      ForceDeleteScratchPath(FTempFileName);
      FReplacedCountSync := FReplacedCount;
      Synchronize(FinishThread);
      Result := True;
      Exit;
    end;

    FReplacedCountSync := FReplacedCount;
    CommitReplaceOutputOnWorker;
    Synchronize(FinishThread);
    Result := True;
    except
    on E: Exception do
    begin
      FErrorMsg := E.Message;
      FSuccess := False;
      FReplacedCountSync := FReplacedCount;
      ForceDeleteScratchPath(FTempFileName);
      Synchronize(FinishThread);
      Result := True;
    end;
    end;
  finally
    FreeAndNil(Merge);
    FreeAndNil(Idx);
    FreeAndNil(Src);
  end;
end;

procedure TReplaceAllThread.Execute;
const
  BUF_SIZE = 1024 * 1024; // 1 MB por bloco de leitura
var
  MMF: TMMFReader;
  DestWriter: TBufferedTextWriter;
  FileSize: Int64;
  NeedLen: Integer;

  // BMH tables
  Shift: TReplaceAllBMHShiftTable;
  Up: array[0..255] of Byte;
  Pat: array of Byte;
  PatU: array of Byte;

  // Buffers
  BufRaw: array of Byte;
  WorkBuf: array of Byte;
  Tail: array of Byte;
  TailLen: Integer;

  // Positions
  CurPos: Int64;
  WritePos: Int64;
  BytesRead: Integer;
  ReadSize: Integer;

  // Replace text bytes
  ReplaceBytes: AnsiString;

  // Progress
  NewPercent: Integer;
  LastProgressPos: Int64;

  FoundIdx: Integer;
  FoundBaseAbs: Int64;
  MatchAbsPos: Int64;
  SearchFrom: Integer;
  WorkLen: Integer;
  CanReplace: Boolean;
  ByteBefore, ByteAfter: Byte;
  MatchBufIdx: Integer;

  function ForceDeleteFile(const FileName: string): Boolean;
  var
    RetryCount: Integer;
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

  function IsWordBoundaryChar(Ch: Byte): Boolean;
  begin
    Result := not (AnsiChar(Ch) in ['A'..'Z', 'a'..'z', '0'..'9', '_']);
  end;

  procedure BuildUpTable;
  var i: Integer; c: AnsiChar;
  begin
    for i := 0 to 255 do
    begin
      c := AnsiChar(i);
      CharUpperBuffA(@c, 1);
      Up[i] := Byte(c);
    end;
  end;

  procedure BuildPatternBytes;
  var i: Integer; b: Byte;
  begin
    SetLength(Pat, NeedLen);
    SetLength(PatU, NeedLen);
    for i := 0 to NeedLen - 1 do
    begin
      b := Byte(AnsiChar(FFindBytes[i + 1]));
      Pat[i] := b;
      PatU[i] := Up[b];
    end;
  end;

  procedure BuildShiftTable;
  var i: Integer; b: Byte;
  begin
    for i := 0 to 255 do
      Shift[i] := NeedLen;
    for i := 0 to NeedLen - 2 do
    begin
      if FCaseSensitive then
        b := Pat[i]
      else
        b := PatU[i];
      Shift[b] := (NeedLen - 1) - i;
    end;
  end;

  function BMH_FindFirst(const Buf: PByte; const BufLen: Integer; const AStartIndex: Integer): Integer;
  var
    i, j, baseIdx: Integer;
    tb: Byte;
  begin
    Result := -1;
    if (NeedLen <= 0) or (BufLen < NeedLen) then Exit;
    i := AStartIndex + (NeedLen - 1);
    while i < BufLen do
    begin
      j := NeedLen - 1;
      if FCaseSensitive then
      begin
        while (j >= 0) do
        begin
          baseIdx := i - ((NeedLen - 1) - j);
          if PByteArray(Buf)^[baseIdx] <> PByteArray(Pat)^[j] then Break;
          Dec(j);
        end;
      end
      else
      begin
        while (j >= 0) do
        begin
          baseIdx := i - ((NeedLen - 1) - j);
          if Up[PByteArray(Buf)^[baseIdx]] <> PByteArray(PatU)^[j] then Break;
          Dec(j);
        end;
      end;
      if j < 0 then
      begin
        Result := i - (NeedLen - 1);
        Exit;
      end;
      if FCaseSensitive then
        tb := PByteArray(Buf)^[i]
      else
        tb := Up[PByteArray(Buf)^[i]];
      Inc(i, Shift[tb]);
    end;
  end;

  procedure WriteFromSource(FromPos, Count: Int64);
  var
    P: PByte;
    Cont: Cardinal;
    ToWrite: Integer;
  begin
    while Count > 0 do
    begin
      P := MMF.PtrAt(FromPos, 1, Cont);
      if P = nil then Exit;
      if Int64(Cont) > Count then ToWrite := Integer(Count)
      else ToWrite := Integer(Cont);
      DestWriter.WriteRaw(P, ToWrite);
      Inc(FromPos, ToWrite);
      Dec(Count, ToWrite);
    end;
  end;

  procedure UpdateProgressAt(AbsPos: Int64);
  begin
    if FileSize <= 0 then Exit;
    NewPercent := Round((AbsPos * 100.0) / FileSize);
    if NewPercent > 100 then NewPercent := 100;
    if NewPercent > FCurrentPercent then
      FCurrentPercent := NewPercent;
    FPercentToSync := FCurrentPercent;
    FDetailSync := UnUtils.FormatNumber(AbsPos) + ' / ' + UnUtils.FormatNumber(FileSize) + ' B' + #13#10 +
      IntToStr(FReplacedCount) + ' ' + TrText('replacements');
    if FShowLoadingUI then
      TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
  end;

begin
  inherited;
  if (FOutputOverride = '') and Assigned(frmMain) then
    Synchronize(SyncReleaseSourceHandles);
  if FSegmented and (FOutputOverride = '') and (FIndexFileName <> '') and
     FileExists(FIndexFileName) and (UnUtils.GetFileSize(FIndexFileName) >= Int64(INDEX_RECORD_SIZE) * 2) then
  begin
    if TrySegmentedReplace then
      Exit;
  end;

  FTempFileName := AllocateReplaceScratchTemp(FFileName);
  FSuccess := False;

  MMF := nil;
  DestWriter := nil;
  try
    try
      begin
      MMF := TMMFReader.Create(FFileName);
    FileSize := MMF.FileSize;
    FTotalSize := FileSize;
    if not VolumeHasSpaceForAtomicRewrite(FFileName, FileSize) then
    begin
      FErrorMsg := TrText('Not enough free disk space to complete this operation safely.');
      raise Exception.Create(FErrorMsg);
    end;
    DestWriter := TBufferedTextWriter.Create(FTempFileName, 16 * 1024 * 1024);

    FCurrentPercent := 0;
    if FEncoding = '' then
    begin
      if Assigned(frmMain) then
        FEncoding := frmMain.CurrentViewEncoding;
      FEncoding := ResolveTextEncoding(FFileName, FEncoding);
    end;
    FFindBytes := UnicodeTextToFileBytes(NormalizeTextEolForFile(FFindText, FFileName), FEncoding);
    FReplaceBytes := UnicodeTextToFileBytes(NormalizeTextEolForFile(FReplaceText, FFileName), FEncoding);
    NeedLen := Length(FFindBytes);
    ReplaceBytes := FReplaceBytes;
    WritePos := 0;

    if (NeedLen <= 0) or (FileSize = 0) then
    begin
      WriteFromSource(0, FileSize);
      if Assigned(DestWriter) then
      begin
        DestWriter.Flush;
        FreeAndNil(DestWriter);
      end;
      FreeAndNil(MMF);
      Sleep(100);
      FReplacedCountSync := 0;
      CommitReplaceOutputOnWorker;
      Synchronize(FinishThread);
      Exit;
    end;

    BuildUpTable;
    BuildPatternBytes;
    BuildShiftTable;

    SetLength(BufRaw, BUF_SIZE);
    TailLen := 0;
    SetLength(Tail, 0);
    CurPos := 0;
    LastProgressPos := 0;

    while (not Terminated) and (CurPos < FileSize)
      and (not TfrmSmoothLoading.CancelRequested) do
    begin
      ReadSize := BUF_SIZE;
      if CurPos + ReadSize > FileSize then
        ReadSize := Integer(FileSize - CurPos);
      if ReadSize <= 0 then Break;

      BytesRead := Integer(MMF.ReadBytes(CurPos, BufRaw[0], Cardinal(ReadSize)));
      if BytesRead <= 0 then Break;

      if TailLen > 0 then
      begin
        SetLength(WorkBuf, TailLen + BytesRead);
        Move(Tail[0], WorkBuf[0], TailLen);
        Move(BufRaw[0], WorkBuf[TailLen], BytesRead);
        FoundBaseAbs := CurPos - Int64(TailLen);
      end
      else
      begin
        SetLength(WorkBuf, BytesRead);
        Move(BufRaw[0], WorkBuf[0], BytesRead);
        FoundBaseAbs := CurPos;
      end;

      WorkLen := Length(WorkBuf);
      SearchFrom := 0;

      while SearchFrom <= WorkLen - NeedLen do
      begin
        if Terminated then Break;

        FoundIdx := BMH_FindFirst(@WorkBuf[0], WorkLen, SearchFrom);
        if FoundIdx < 0 then Break;

        MatchAbsPos := FoundBaseAbs + Int64(FoundIdx);
        MatchBufIdx := FoundIdx;

        CanReplace := True;
        if FWholeWord then
        begin
          if MatchBufIdx > 0 then
          begin
            ByteBefore := WorkBuf[MatchBufIdx - 1];
            if not IsWordBoundaryChar(ByteBefore) then CanReplace := False;
          end
          else if MatchAbsPos > 0 then
          begin
            MMF.ReadBytes(MatchAbsPos - 1, ByteBefore, 1);
            if not IsWordBoundaryChar(ByteBefore) then CanReplace := False;
          end;
          if CanReplace then
          begin
            if MatchBufIdx + NeedLen < WorkLen then
            begin
              ByteAfter := WorkBuf[MatchBufIdx + NeedLen];
              if not IsWordBoundaryChar(ByteAfter) then CanReplace := False;
            end
            else if MatchAbsPos + NeedLen < FileSize then
            begin
              MMF.ReadBytes(MatchAbsPos + NeedLen, ByteAfter, 1);
              if not IsWordBoundaryChar(ByteAfter) then CanReplace := False;
            end;
          end;
        end;

        if CanReplace then
        begin
          if MatchAbsPos > WritePos then
            WriteFromSource(WritePos, MatchAbsPos - WritePos);
          if Length(ReplaceBytes) > 0 then
            DestWriter.WriteRaw(PAnsiChar(ReplaceBytes), Length(ReplaceBytes));
          WritePos := MatchAbsPos + Int64(NeedLen);
          SearchFrom := FoundIdx + NeedLen;
          Inc(FReplacedCount);
          if FReplacedCount >= REPLACE_ALL_MATCH_LIMIT then
          begin
            FReplaceLimitHit := True;
            Break;
          end;
        end
        else
        begin
          SearchFrom := FoundIdx + 1;
        end;
      end;

      if FReplaceLimitHit then
        Break;

      CurPos := CurPos + Int64(BytesRead);

      if NeedLen > 1 then
      begin
        TailLen := NeedLen - 1;
        if TailLen > WorkLen then TailLen := WorkLen;
        SetLength(Tail, TailLen);
        if TailLen > 0 then
          Move(WorkBuf[WorkLen - TailLen], Tail[0], TailLen);
      end
      else
      begin
        TailLen := 0;
        SetLength(Tail, 0);
      end;

      if (CurPos - LastProgressPos >= 1024 * 1024) or (CurPos >= FileSize) then
      begin
        UpdateProgressAt(CurPos);
        LastProgressPos := CurPos;
      end;
    end;

    if Terminated or FReplaceLimitHit then
    begin
      FreeAndNil(DestWriter);
      FreeAndNil(MMF);
      ForceDeleteFile(FTempFileName);
      FReplacedCountSync := FReplacedCount;
      if FReplaceLimitHit then
        FErrorMsg := Format(TrText('Replace-all stopped at the safety limit of %d matches. The file was not modified.'),
          [REPLACE_ALL_MATCH_LIMIT])
      else if Terminated then
        FErrorMsg := TrText('Operation cancelled.');
      FSuccess := False;
      Synchronize(FinishThread);
      Exit;
    end;

    if WritePos < FileSize then
      WriteFromSource(WritePos, FileSize - WritePos);

    if Assigned(DestWriter) then
    begin
      DestWriter.Flush;
      FreeAndNil(DestWriter);
    end;
    FreeAndNil(MMF);
    Sleep(150);

    FReplacedCountSync := FReplacedCount;
    CommitReplaceOutputOnWorker;
      end;
  except
    on E: Exception do
    begin
      FErrorMsg := E.Message;
      LogAsync(FastFileRuntimeLogPath,
        '[ReplaceAllThread] ' + E.Message);
      FreeAndNil(MMF);
      FreeAndNil(DestWriter);
    end;
  end;
  finally
    if (not FSuccess) and (FTempFileName <> '') and FileExists(FTempFileName) then
      ForceDeleteScratchPath(FTempFileName);
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ THREAD: SPLIT FILE                                                           }
{ ============================================================================ }

constructor TSplitFileThread.Create(const AOriginalFileName: String; const AOutputDir: String; const AEntries: TSplitEntryArray; const AEntryCount: Integer; const AHeader: String; const AFooter: String);
var
  i: Integer;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOriginalFileName := AOriginalFileName;
  FOutputDir := AOutputDir;
  FEntryCount := AEntryCount;
  FHeader := AHeader;
  FFooter := AFooter;
  SetLength(FEntries, FEntryCount);
  for i := 0 to FEntryCount - 1 do
    FEntries[i] := AEntries[i];
  FAutoHide := True;
  FShowLoadingUI := True;
  FLoadingMsg := TrText('Splitting file...');
  FProgressToSet := 0;
  Synchronize(SyncShowLoading);
  Synchronize(SyncSetProgress);
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TSplitFileThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TSplitFileThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TSplitFileThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TSplitFileThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TSplitFileThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TSplitFileThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowAppMessage(TrText('Split Error: ') + FErrorMsg);
end;

function FormatElapsedDuration(const ElapsedMs: Int64): string;
begin
  if ElapsedMs < 0 then
    Result := '0 ms'
  else if ElapsedMs < 1000 then
    Result := Format('%d ms', [ElapsedMs])
  else if ElapsedMs < 60000 then
    Result := Format('%.2f s', [ElapsedMs / 1000.0])
  else
    Result := FormatDateTime('hh:nn:ss', ElapsedMs / MSecsPerDay);
end;

procedure TSplitFileThread.SyncFinish;
var
  Elapsed, OutPath: string;
begin
  sw.Stop;
  Elapsed := FormatElapsedDuration(sw.ElapsedMilliseconds);
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if not FSuccess then Exit;
  { Split-by-lines always creates one extract file; do not reuse the N-files message. }
  if (FEntryCount = 1) and (Length(FEntries) >= 1) then
  begin
    OutPath := FOutputDir + FEntries[0].FileName;
    ShowAppMessage(Format(TrText('SplitByLines.DoneFormat'),
      [FEntries[0].SourceLine + 1, FEntries[0].TargetLine + 1, OutPath, Elapsed]));
  end
  else
    ShowAppMessage(Format(TrText('SplitByFiles.DoneFormat'), [FEntryCount, Elapsed]));
end;

procedure TSplitFileThread.Execute;
{ Sequential LF scan — does not open temp.txt (that file is often locked by
  the UI index stream, which froze Executar on "Split By Files"). }
var
  MMF: TMMFReader;
  OutStream: TFileStream;
  FileSize, AbsOffset: Int64;
  Contiguous: Cardinal;
  P: PByte;
  EntryIdx: Integer;
  CurrentLine0: Int64;
  LFShift: TBMHByteShiftTable;
  LastProgressTick: Cardinal;
  LastPostedPercent: Integer;
  OutputPath: String;
  TermB: Byte;
  OutEol: AnsiString;

  function ForceDeleteLocal(const FileName: string): Boolean;
  var
    RetryCount: Integer;
  begin
    Result := False;
    if not FileExists(FileName) then
    begin
      Result := True;
      Exit;
    end;
    for RetryCount := 1 to 10 do
    begin
      if Windows.DeleteFile(PChar(FileName)) then
      begin
        Result := True;
        Exit;
      end;
      Sleep(150);
    end;
  end;

  procedure WriteAnsi(AOut: TFileStream; const S: AnsiString);
  begin
    if (S <> '') and Assigned(AOut) then
      AOut.WriteBuffer(Pointer(S)^, Length(S));
  end;

  procedure WriteHeader(AOut: TFileStream);
  var
    S: AnsiString;
  begin
    if FHeader = '' then Exit;
    S := FHeader;
    if not (S[Length(S)] in [#10, #13]) then
      S := S + OutEol;
    WriteAnsi(AOut, S);
  end;

  procedure WriteFooter(AOut: TFileStream);
  var
    S: AnsiString;
  begin
    if FFooter = '' then Exit;
    S := FFooter;
    WriteAnsi(AOut, S);
    if not (S[Length(S)] in [#10, #13]) then
      WriteAnsi(AOut, OutEol);
  end;

  procedure CloseCurrentOut;
  begin
    if not Assigned(OutStream) then Exit;
    WriteFooter(OutStream);
    FreeAndNil(OutStream);
  end;

  procedure OpenEntryOut(const AIndex: Integer);
  begin
    CloseCurrentOut;
    if (AIndex < 0) or (AIndex >= FEntryCount) then Exit;
    OutputPath := FOutputDir + FEntries[AIndex].FileName;
    ForceDeleteLocal(OutputPath);
    OutStream := TFileStream.Create(OutputPath, fmCreate);
    WriteHeader(OutStream);
  end;

  function LineBelongsToEntry(const ALine0: Int64; const AIndex: Integer): Boolean;
  begin
    Result := (AIndex >= 0) and (AIndex < FEntryCount) and
      (ALine0 >= FEntries[AIndex].SourceLine) and
      (ALine0 <= FEntries[AIndex].TargetLine);
  end;

  procedure EnsureOutForLine(const ALine0: Int64);
  begin
    while (EntryIdx < FEntryCount) and (ALine0 > FEntries[EntryIdx].TargetLine) do
    begin
      CloseCurrentOut;
      Inc(EntryIdx);
      if (EntryIdx < FEntryCount) and LineBelongsToEntry(ALine0, EntryIdx) then
        OpenEntryOut(EntryIdx);
    end;
    if LineBelongsToEntry(ALine0, EntryIdx) then
    begin
      if not Assigned(OutStream) then
        OpenEntryOut(EntryIdx);
    end
    else
      CloseCurrentOut;
  end;

  procedure ProcessChunk(const Chunk: PAnsiChar; const ChunkLen: Integer);
  var
    RunStart, SearchAt, LFPos: Integer;
  begin
    if (Chunk = nil) or (ChunkLen <= 0) then Exit;
    RunStart := 0;
    SearchAt := 0;
    while SearchAt < ChunkLen do
    begin
      if ((SearchAt and $FFFF) = 0) and
         (Terminated or TfrmSmoothLoading.CancelRequested) then
        Exit;
      LFPos := BMHFindBytePAnsi(Chunk, ChunkLen, SearchAt, TermB, LFShift);
      if LFPos < 0 then Break;
      EnsureOutForLine(CurrentLine0);
      if Assigned(OutStream) then
        OutStream.WriteBuffer((Chunk + RunStart)^, LFPos - RunStart + 1);
      RunStart := LFPos + 1;
      SearchAt := LFPos + 1;
      Inc(CurrentLine0);
    end;
    if RunStart < ChunkLen then
    begin
      EnsureOutForLine(CurrentLine0);
      if Assigned(OutStream) then
        OutStream.WriteBuffer((Chunk + RunStart)^, ChunkLen - RunStart);
    end;
  end;

  procedure UpdateProgressIfNeeded;
  var
    NewPercent: Integer;
  begin
    if FileSize <= 0 then Exit;
    if (GetTickCount - LastProgressTick) < 200 then Exit;
    LastProgressTick := GetTickCount;
    NewPercent := Round((AbsOffset * 100.0) / FileSize);
    if NewPercent > 100 then NewPercent := 100;
    if NewPercent > FCurrentPercent then
    begin
      FCurrentPercent := NewPercent;
      FPercentToSync := FCurrentPercent;
      if FPercentToSync <> LastPostedPercent then
      begin
        TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
        LastPostedPercent := FPercentToSync;
      end;
    end;
  end;

begin
  inherited;
  MMF := nil;
  OutStream := nil;
  BMHInitSingleByte(LFShift);
  TermB := LineTermByteForFile(FOriginalFileName);
  OutEol := OutputEolForFile(FOriginalFileName);
  EntryIdx := 0;
  CurrentLine0 := 0;
  LastProgressTick := GetTickCount;
  LastPostedPercent := -1;
  FCurrentPercent := 0;

  try
    try
      if FEntryCount < 1 then
        raise Exception.Create(TrText('Please specify an output filename.'));

      MMF := TMMFReader.Create(FOriginalFileName);
      FileSize := MMF.FileSize;
      if FileSize <= 0 then
        raise Exception.Create(TrText('Source file is empty.'));

      if LineBelongsToEntry(0, 0) then
        OpenEntryOut(0);

      AbsOffset := 0;
      while (AbsOffset < FileSize) and (not Terminated) and
            (not TfrmSmoothLoading.CancelRequested) do
      begin
        P := MMF.PtrAt(AbsOffset, 1, Contiguous);
        if (P = nil) or (Contiguous = 0) then
          Break;
        if Contiguous > Cardinal(FileSize - AbsOffset) then
          Contiguous := Cardinal(FileSize - AbsOffset);
        ProcessChunk(PAnsiChar(P), Integer(Contiguous));
        Inc(AbsOffset, Contiguous);
        UpdateProgressIfNeeded;
      end;

      CloseCurrentOut;
      FSuccess := (not Terminated) and (not TfrmSmoothLoading.CancelRequested);
    except
      on E: Exception do
      begin
        FErrorMsg := E.Message;
        LogAsync(FastFileRuntimeLogPath, '[SplitFileThread] ' + E.Message);
        Synchronize(SyncError);
      end;
    end;
  finally
    CloseCurrentOut;
    FreeAndNil(MMF);
  end;
  Synchronize(SyncFinish);
end;

{ ============================================================================ }
{ THREAD: MERGE FILES                                                          }
{ ============================================================================ }

constructor TMergeFilesThread.Create(const ADestinationFileName,
  ASourceFileName: String; const AInsertOffset: Int64;
  const AutoHide: Boolean = True; const ShowUI: Boolean = True; const AFromLine: Int64 = 0;
  const AToLine: Int64 = 0);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FDestinationFileName := ADestinationFileName;
  FSourceFileName := ASourceFileName;
  FInsertOffset := AInsertOffset;
  FFromLine := AFromLine;
  FToLine := AToLine;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Merging files...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TMergeFilesThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TMergeFilesThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TMergeFilesThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TMergeFilesThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TMergeFilesThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TMergeFilesThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  ShowAppMessage(TrText('Merge files error: ') + FErrorMsg);
end;

procedure TMergeFilesThread.FinishThread;
var
  TimeStr: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := Format(TrText('Merge files completed in: %s millisecs.'),
      [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) then
    begin
      frmMain.CommitPendingMergeFilesUndoIfNeeded(True, FDestinationFileName,
        FSourceFileName, FBackupPath);
      frmMain.AppendOperationTimerLog(TimeStr);
      frmMain.RefreshFile;
      frmMain.AssistantOfferAfterActivity('merge',
        TrText('Assistant.Offer.Summary.Merge'));
    end;
  end
  else if Assigned(frmMain) then
    frmMain.CommitPendingMergeFilesUndoIfNeeded(False, FDestinationFileName,
      FSourceFileName, FBackupPath);
end;


{ THREAD: SPLIT FILE BY PATTERN (Regex or Substring)                           }
constructor TSplitByPatternThread.Create(const ASourceFileName, APattern: String; const AIsRegex: Boolean;
  const AutoHide: Boolean; const ShowUI: Boolean; const AHeader: String; const AFooter: String;
  const ARegexOp: TRegexOp; const AReplacement: String;
  const AGlobal: Boolean; const AIgnoreCase: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSourceFileName := ASourceFileName;
  FPattern := APattern;
  FIsRegex := AIsRegex;
  FHeader := AHeader;
  FFooter := AFooter;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FRegexOp := ARegexOp;
  FReplacement := AReplacement;
  FGlobal := AGlobal;
  FIgnoreCase := AIgnoreCase;
  FResultOutputPath := '';
  FLoadingMsg := TrText('Splitting file by pattern...');
  FProgressToSet := 0;
  if FShowLoadingUI then
    Synchronize(SyncShowLoading);
  if FShowLoadingUI then
    Synchronize(SyncSetProgress);
  FSuccess := False;
  FPartCount := 0;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TSplitByPatternThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TSplitByPatternThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TSplitByPatternThread.SyncHideLoading;
begin
  if FAutoHide then
    TfrmSmoothLoading.HideLoading;
end;

procedure TSplitByPatternThread.SyncSetProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TSplitByPatternThread.SyncProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FPercentToSync);
end;

procedure TSplitByPatternThread.SyncError;
begin
  if FAutoHide then TfrmSmoothLoading.HideLoading;
  FastFileMsgInfo(TrText('Split Error: ') + FErrorMsg);
end;

procedure TSplitByPatternThread.SyncFinish;
var
  OpName: String;
begin
  if FAutoHide then TfrmSmoothLoading.HideLoading;
  if FSuccess then
  begin
    if FRegexOp = roSplit then
    begin
      frmMain.AppendOperationTimerLog(Format(TrText('Split by pattern completed. %d file(s) created in %s.'), [FPartCount, sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
      FastFileMsgInfo(Format(TrText('Split by pattern completed. %d file(s) created in %s.'), [FPartCount, sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]));
    end
    else
    begin
      case FRegexOp of
        roMatch:   OpName := TrText('match');
        roTest:    OpName := TrText('test');
        roReplace: OpName := TrText('replace');
        roFilter:  OpName := TrText('filter');
      else         OpName := TrText('regex');
      end;
      frmMain.AppendOperationTimerLog(Format(TrText('Regex %s completed. %d line(s) processed in %s. Output: %s'),
        [OpName, FPartCount, sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds), FResultOutputPath]));
      FastFileMsgInfo(Format(TrText('Regex %s completed. %d line(s) processed in %s.' + #13#10 + 'Output: %s'),
        [OpName, FPartCount, sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds), FResultOutputPath]));
    end;
  end
  else
  begin
    if FErrorMsg <> '' then
      FastFileMsgInfo(Format(TrText('Split by pattern failed: %s'), [FErrorMsg]))
    else
      FastFileMsgInfo(TrText('Split by pattern cancelled.'));
  end;
end;

procedure TSplitByPatternThread.Execute;
var
  MMF: TMMFReader;
  W: TBufferedTextWriter;
  FSize: Int64;
  Pos, ReadPos: Int64;
  LineBuffer: AnsiString;
  P: PByte;
  Contiguous: Cardinal;
  LineLength: Integer;
  PartIndex: Integer;
  IsMatch: Boolean;
  DoneLines: Int64;
  NewPercent: Integer;
  OutputPath: String;
  RegObj: Variant;
  { Single-file ops extras }
  LineStr: String;
  Matches: Variant;
  MatchIdx: Integer;
  OutLine: AnsiString;
  OpSuffix, DirPath, BaseName, ExtPart: String;
  CancelNow: Boolean;
  LastDetailTick: Cardinal;
  Detail: string;
  TermB: Byte;
  OutEol: AnsiString;

  procedure OpenNewPart;
  var
    PartDirPath, PartBaseName, PartExtPart: String;
  begin
    if Assigned(W) then
    begin
      if FFooter <> '' then
        W.WriteLine(AnsiString(FFooter));
      FreeAndNil(W);
    end;

    Inc(PartIndex);
    PartDirPath := ExtractFilePath(FSourceFileName);
    PartBaseName := ExtractFileName(FSourceFileName);
    PartExtPart := ExtractFileExt(PartBaseName);
    PartBaseName := ChangeFileExt(PartBaseName, '');
    OutputPath := IncludeTrailingPathDelimiter(PartDirPath) + PartBaseName + Format('.part%.3d', [PartIndex]) + PartExtPart;

    W := TBufferedTextWriter.Create(OutputPath, 4 * 1024 * 1024);
    W.LineBreak := OutEol;
    if FHeader <> '' then
      W.WriteLine(AnsiString(FHeader));
  end;

  { Read the next line from MMF into LineBuffer, stripping CR/LF.
    Returns False when the file is exhausted. }
  function ReadNextLine: Boolean;
  begin
    Result := False;
    LineLength := 0;
    ReadPos := Pos;
    while (ReadPos + LineLength < FSize) do
    begin
      P := MMF.PtrAt(ReadPos + LineLength, 1, Contiguous);
      if not Assigned(P) then Break;
      if P^ = TermB then
      begin
        Inc(LineLength);
        Break;
      end;
      Inc(LineLength);
    end;

    if LineLength = 0 then Exit;

    SetLength(LineBuffer, LineLength);
    P := MMF.PtrAt(Pos, LineLength, Contiguous);
    if Assigned(P) and (Contiguous >= Cardinal(LineLength)) then
      Move(P^, Pointer(LineBuffer)^, LineLength)
    else
      MMF.ReadBytes(Pos, Pointer(LineBuffer)^, LineLength);

    Inc(Pos, LineLength);

    while (Length(LineBuffer) > 0) and (LineBuffer[Length(LineBuffer)] in [#10, #13]) do
      SetLength(LineBuffer, Length(LineBuffer) - 1);

    Result := True;
  end;

begin
  inherited;
  MMF := nil;
  W := nil;
  PartIndex := 0;
  CancelNow := False;
  LastDetailTick := 0;
  TermB := LineTermByteForFile(FSourceFileName);
  OutEol := OutputEolForFile(FSourceFileName);

  if FIsRegex then
  begin
    CoInitialize(nil);
    try
      RegObj := CreateOleObject('VBScript.RegExp');
      RegObj.Pattern := FPattern;
      RegObj.IgnoreCase := FIgnoreCase;
      { For match / replace always use global mode so every occurrence is returned }
      RegObj.Global := FGlobal or (FRegexOp in [roMatch, roReplace]);
    except
      on E: Exception do
      begin
        FErrorMsg := 'Invalid Regex: ' + E.Message;
        Synchronize(SyncError);
        CoUninitialize;
        Exit;
      end;
    end;
  end;

  try
    try
      begin
      MMF := TMMFReader.Create(FSourceFileName);
      FSize := MMF.FileSize;
      Pos := 0;
      DoneLines := 0;

      { �� SPLIT MODE (original behaviour) ����������������������������������� }
      if FRegexOp = roSplit then
      begin
        OpenNewPart;

        while (Pos < FSize) and (not Terminated) and (not TfrmSmoothLoading.CancelRequested) do
        begin
          if not ReadNextLine then Break;

          IsMatch := False;
          if Length(LineBuffer) > 0 then
          begin
            if FIsRegex then
              IsMatch := RegObj.Test(String(LineBuffer))
            else
              IsMatch := PosBMH(FPattern, LineBuffer) > 0;
          end;

          if IsMatch then
            OpenNewPart;

          if Assigned(W) then
            W.WriteLine(LineBuffer);

          Inc(DoneLines);
          if (DoneLines and 2047) = 0 then
          begin
            if FSize > 0 then
            begin
              NewPercent := Round((Pos * 100.0) / FSize);
              if NewPercent > FCurrentPercent then
              begin
                FCurrentPercent := NewPercent;
                FPercentToSync := FCurrentPercent;
                Detail := Format(TrText('Line %s  |  Part %d  |  %s / %s B') + #13#10 + TrText('Output: %s'),
                  [UnUtils.FormatNumber(DoneLines), PartIndex,
                   UnUtils.FormatNumber(Pos), UnUtils.FormatNumber(FSize),
                   ExtractFileName(OutputPath)]);
                TfrmSmoothLoading.PostProgressWithDetailFromWorker(FPercentToSync, Detail);
                LastDetailTick := GetTickCount;
              end;
            end;
          end;
        end;

        if Assigned(W) then
        begin
          if FFooter <> '' then
            W.WriteLine(AnsiString(FFooter));
          FreeAndNil(W);
        end;

        FPartCount := PartIndex;
        CancelNow := TfrmSmoothLoading.CancelRequested;
        FSuccess := (not Terminated) and (not CancelNow);
      end

      { �� SINGLE-FILE REGEX OPS: match / test / replace / filter ������������ }
      else
      begin
        case FRegexOp of
          roMatch:   OpSuffix := 'match';
          roTest:    OpSuffix := 'test';
          roReplace: OpSuffix := 'replaced';
          roFilter:  OpSuffix := 'filtered';
        else         OpSuffix := 'result';
        end;

        DirPath  := ExtractFilePath(FSourceFileName);
        BaseName := ExtractFileName(FSourceFileName);
        ExtPart  := ExtractFileExt(BaseName);
        BaseName := ChangeFileExt(BaseName, '');
        FResultOutputPath :=
          IncludeTrailingPathDelimiter(DirPath) + BaseName + '.' + OpSuffix + ExtPart;

        W := TBufferedTextWriter.Create(FResultOutputPath, 4 * 1024 * 1024);
        W.LineBreak := OutEol;

        while (Pos < FSize) and (not Terminated) and (not TfrmSmoothLoading.CancelRequested) do
        begin
          if not ReadNextLine then Break;

          LineStr := String(LineBuffer);

          case FRegexOp of

            { match ? write each captured occurrence as a separate output line }
            roMatch:
            begin
              if FIsRegex then
              begin
                Matches := RegObj.Execute(LineStr);
                for MatchIdx := 0 to Matches.Count - 1 do
                begin
                  if TfrmSmoothLoading.CancelRequested then Break;
                  OutLine := AnsiString(String(Matches.Item(MatchIdx).Value));
                  W.WriteLine(OutLine);
                  Inc(FPartCount);
                end;
              end
              else
              begin
                { Substring match: no way to "extract", fall back to filter }
                if PosBMH(FPattern, LineBuffer) > 0 then
                begin
                  W.WriteLine(LineBuffer);
                  Inc(FPartCount);
                end;
              end;
            end;

            { test ? write "true" or "false" for every input line }
            roTest:
            begin
              if FIsRegex then
                IsMatch := RegObj.Test(LineStr)
              else
                IsMatch := PosBMH(FPattern, LineBuffer) > 0;
              if IsMatch then
                W.WriteLine(AnsiString('true'))
              else
                W.WriteLine(AnsiString('false'));
              Inc(FPartCount);
            end;

            { replace ? apply regex Replace to every line and write the result }
            roReplace:
            begin
              if FIsRegex then
                OutLine := AnsiString(String(RegObj.Replace(LineStr, FReplacement)))
              else
                OutLine := AnsiString(StringReplace(String(LineBuffer), FPattern, FReplacement, [rfReplaceAll]));
              W.WriteLine(OutLine);
              Inc(FPartCount);
            end;

            { filter ? keep only lines where the regex matches }
            roFilter:
            begin
              if FIsRegex then
                IsMatch := RegObj.Test(LineStr)
              else
                IsMatch := PosBMH(FPattern, LineBuffer) > 0;
              if IsMatch then
              begin
                W.WriteLine(LineBuffer);
                Inc(FPartCount);
              end;
            end;

          end; { case FRegexOp }

          Inc(DoneLines);
          if (DoneLines and 2047) = 0 then
          begin
            if FSize > 0 then
            begin
              NewPercent := Round((Pos * 100.0) / FSize);
              if NewPercent > FCurrentPercent then
              begin
                FCurrentPercent := NewPercent;
                FPercentToSync := FCurrentPercent;
                Detail := Format(TrText('Line %s  |  %s / %s B') + #13#10 + TrText('Output: %s'),
                  [UnUtils.FormatNumber(DoneLines),
                   UnUtils.FormatNumber(Pos), UnUtils.FormatNumber(FSize),
                   ExtractFileName(FResultOutputPath)]);
                TfrmSmoothLoading.PostProgressWithDetailFromWorker(FPercentToSync, Detail);
                LastDetailTick := GetTickCount;
              end;
            end;
          end;
        end; { while }

        FreeAndNil(W);
        CancelNow := TfrmSmoothLoading.CancelRequested;
        FSuccess := (not Terminated) and (not CancelNow);
      end; { single-file ops }
      end;

    except
      on E: Exception do
      begin
        FSuccess := False;
        FErrorMsg := DiskOperationFailureMessage(E);
        if Assigned(W) then FreeAndNil(W);
        Synchronize(SyncError);
      end;
    end;
  finally
    if Assigned(W) then FreeAndNil(W);
    if Assigned(MMF) then FreeAndNil(MMF);
    if FIsRegex then CoUninitialize;
    { Avoid leaking cancel state into the next operation }
    TfrmSmoothLoading.ResetCancel;
    sw.Stop;
    Synchronize(SyncFinish);
  end;
end;

procedure TMergeFilesThread.Execute;
const
  BUF_SIZE = 4 * 1024 * 1024;
  LINE_COUNTER_BUF_SIZE = 64 * 1024;
var
  SrcStream, DstStream, OutStream, BackupSrc, BackupDst: TFileStream;
  DstSize, SrcSize: Int64;
  SrcStartOffset, SrcEndOffset, SrcRangeSize: Int64;
  Processed, TotalToProcess, BackupBytes: Int64;
  RenameErr: string;
  NeedBackup, UseAppend: Boolean;

  function ForceDeleteFile(const FileName: string): Boolean;
  var
    RetryCount: Integer;
  begin
    Result := False;
    if not FileExists(FileName) then begin Result := True; Exit; end;
    for RetryCount := 1 to 10 do
    begin
      if DeleteFile(FileName) then
      begin
        Result := True;
        Break;
      end;
      Sleep(200);
    end;
    if not Result then
      Result := RenameFile(FileName, FileName + '.' + FormatDateTime('hhmmss', Now) + '.old');
  end;

  procedure CopyRangeWithProgress(AInput, AOutput: TFileStream;
    const AStartPos, ACount: Int64; var AProcessed, ATotal: Int64);
  var
    Buffer: array of Byte;
    Remaining, ToRead: Int64;
    ReadBytes: Integer;
    NewPercent: Integer;
    PostMb: Int64;
  begin
  if ACount <= 0 then Exit;
  SetLength(Buffer, BUF_SIZE);
  Remaining := ACount;
  FileStreamSeek64(AInput, AStartPos, soFromBeginning);

  while (Remaining > 0) and (not Terminated)
    and (not TfrmSmoothLoading.CancelRequested) do
  begin
    ToRead := Remaining;
    if ToRead > BUF_SIZE then
      ToRead := BUF_SIZE;

    ReadBytes := AInput.Read(Buffer[0], Integer(ToRead));
    if ReadBytes <= 0 then Break;

    AOutput.WriteBuffer(Buffer[0], ReadBytes);

    Dec(Remaining, ReadBytes);
    Inc(AProcessed, ReadBytes);

    if ATotal > 0 then
    begin
      NewPercent := Round((AProcessed * 100.0) / ATotal);
      if NewPercent > 100 then NewPercent := 100;
      if (NewPercent < 1) and (AProcessed > 0) then
        NewPercent := 1;
      PostMb := AProcessed div (32 * 1024 * 1024);
      if (NewPercent > FCurrentPercent) or (PostMb > FProgressPostMb) then
      begin
        if PostMb > FProgressPostMb then
          FProgressPostMb := PostMb;
        FCurrentPercent := NewPercent;
        FPercentToSync := FCurrentPercent;
        TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
      end;
    end;
  end;
  end;

  function GetSourceLineOffset(AStreamr: TFileStream; const ALine1Based: Int64): Int64;
  const
    SCAN_BUF = 256 * 1024;
  var
    Buffer: PAnsiChar;
    BytesRead, ScanPos, FoundAt: Integer;
    CurrentLine: Int64;
    Offset: Int64;
    LFShift: TBMHByteShiftTable;
    TermB: Byte;
  begin
  Result := -1;
  if ALine1Based < 1 then Exit;
  if ALine1Based = 1 then
  begin
    Result := 0;
    Exit;
  end;

  BMHInitSingleByte(LFShift);
  TermB := LineTermByteForFile(FSourceFileName);
  GetMem(Buffer, SCAN_BUF);
  try
    CurrentLine := 1;
    Offset := 0;
    FileStreamSeek64(AStreamr, 0, soFromBeginning);
    while True do
    begin
      if TfrmSmoothLoading.CancelRequested then Exit;
      BytesRead := AStreamr.Read(Buffer^, SCAN_BUF);
      if BytesRead <= 0 then
        Break;
      ScanPos := 0;
      while ScanPos < BytesRead do
      begin
        FoundAt := BMHFindBytePAnsi(Buffer, BytesRead, ScanPos, TermB, LFShift) - 1;
        if FoundAt < 0 then Break;
        Inc(CurrentLine);
        if CurrentLine = ALine1Based then
        begin
          Result := Offset + FoundAt + 1;
          Exit;
        end;
        ScanPos := FoundAt + 1;
      end;
      Inc(Offset, BytesRead);
    end;
    if CurrentLine >= ALine1Based then
      Result := Offset;
  finally
    FreeMem(Buffer);
  end;
  end;

  procedure RestoreDestinationFromBackup;
  var
    RenameErr: string;
    BkpSize, DummyProc, DummyTotal: Int64;
    BkpIn, BkpOut: TFileStream;
  begin
  if (FBackupPath = '') or (not FileExists(FBackupPath)) then Exit;
  if UnUtils.TryRenameTempOverTarget(FBackupPath, FDestinationFileName, RenameErr) then
  begin
    FBackupPath := '';
    Exit;
  end;
  BkpSize := GetFileSize(FBackupPath);
  ForceDeleteFile(FDestinationFileName);
  BkpIn := TFileStream.Create(FBackupPath, fmOpenRead or fmShareDenyNone);
  BkpOut := TFileStream.Create(FDestinationFileName, fmCreate);
  try
    DummyProc := 0;
    DummyTotal := BkpSize;
    if DummyTotal <= 0 then
      DummyTotal := 1;
    CopyRangeWithProgress(BkpIn, BkpOut, 0, BkpSize, DummyProc, DummyTotal);
  finally
    FreeAndNil(BkpOut);
    FreeAndNil(BkpIn);
  end;
  ForceDeleteFile(FBackupPath);
  FBackupPath := '';
  end;

begin
  inherited;
  FBackupPath := '';
  FTempFileName := FastFileTempPath(FASTFILE_MERGE_TEMP_FILE);
  ForceDeleteFile(FTempFileName);

  SrcStream := nil;
  DstStream := nil;
  OutStream := nil;
  BackupSrc := nil;
  BackupDst := nil;
  Processed := 0;
  FCurrentPercent := 0;
  FProgressPostMb := -1;
  try
    try
      begin
      UseAppend := False;
      DstSize := GetFileSize(FDestinationFileName);
      SrcSize := GetFileSize(FSourceFileName);
      NeedBackup := FileExists(FDestinationFileName);
      BackupBytes := 0;
      if NeedBackup then
        BackupBytes := DstSize;

      SrcStartOffset := 0;
      SrcRangeSize := SrcSize;
      if (FFromLine > 0) and (FToLine > 0) and (FFromLine <= FToLine) then
      begin
        SrcStream := TFileStream.Create(FSourceFileName, fmOpenRead or fmShareDenyNone);
        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressWithDetailFromWorker(0,
            TrText('MergeFiles.Progress.ScanningLines'));
        SrcStartOffset := GetSourceLineOffset(SrcStream, FFromLine);
        SrcEndOffset := GetSourceLineOffset(SrcStream, FToLine + 1);
        if SrcEndOffset <= 0 then
          SrcEndOffset := SrcSize;
        if SrcStartOffset < 0 then
          raise Exception.Create('Could not find source start line.');
        SrcRangeSize := SrcEndOffset - SrcStartOffset;
        if SrcRangeSize < 0 then
          SrcRangeSize := 0;
        FreeAndNil(SrcStream);
      end;

      if FInsertOffset < 0 then FInsertOffset := 0;
      if FInsertOffset > DstSize then FInsertOffset := DstSize;

      UseAppend := MergeFilesCanUseAppendAtEnd(DstSize, FInsertOffset, FFromLine, FToLine,
        SrcStartOffset, SrcRangeSize);
      if UseAppend then
        TotalToProcess := BackupBytes + SrcRangeSize
      else
        TotalToProcess := BackupBytes + DstSize + SrcRangeSize;
      if TotalToProcess <= 0 then
        TotalToProcess := 1;

      if NeedBackup then
      begin
        FBackupPath := NewFastFileTemp('mrgundo');
        ForceDeleteFile(FBackupPath);
        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressWithDetailFromWorker(FCurrentPercent,
            TrText('MergeFiles.Progress.Backup'));
        BackupSrc := TFileStream.Create(FDestinationFileName, fmOpenRead or fmShareDenyNone);
        BackupDst := TFileStream.Create(FBackupPath, fmCreate);
        CopyRangeWithProgress(BackupSrc, BackupDst, 0, BackupBytes,
          Processed, TotalToProcess);
        FreeAndNil(BackupDst);
        FreeAndNil(BackupSrc);
      end;

      if UseAppend then
      begin
        if not Assigned(SrcStream) then
          SrcStream := TFileStream.Create(FSourceFileName, fmOpenRead or fmShareDenyNone);
        if FileExists(FDestinationFileName) then
          DstStream := TFileStream.Create(FDestinationFileName,
            fmOpenReadWrite or fmShareDenyNone)
        else
          DstStream := TFileStream.Create(FDestinationFileName, fmCreate);

        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressWithDetailFromWorker(FCurrentPercent,
            TrText('MergeFiles.Progress.Appending'));

        FileStreamSeek64(DstStream, 0, soFromEnd);
        CopyRangeWithProgress(SrcStream, DstStream, SrcStartOffset, SrcRangeSize,
          Processed, TotalToProcess);

        FreeAndNil(DstStream);
        FreeAndNil(SrcStream);

        if TfrmSmoothLoading.CancelRequested then
        begin
          RestoreDestinationFromBackup;
          if FBackupPath <> '' then
            ForceDeleteFile(FBackupPath);
          FBackupPath := '';
          TfrmSmoothLoading.ResetCancel;
          SysUtils.Abort;
        end;

        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressFromWorker(100);

        FSuccess := True;
      end
      else
      begin
        if not Assigned(SrcStream) then
          SrcStream := TFileStream.Create(FSourceFileName, fmOpenRead or fmShareDenyNone);
        DstStream := TFileStream.Create(FDestinationFileName, fmOpenRead or fmShareDenyNone);
        OutStream := TFileStream.Create(FTempFileName, fmCreate);

        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressWithDetailFromWorker(FCurrentPercent,
            TrText('MergeFiles.Progress.Merging'));

        CopyRangeWithProgress(DstStream, OutStream, 0, FInsertOffset,
          Processed, TotalToProcess);
        CopyRangeWithProgress(SrcStream, OutStream, SrcStartOffset, SrcRangeSize,
          Processed, TotalToProcess);
        CopyRangeWithProgress(DstStream, OutStream, FInsertOffset,
          DstSize - FInsertOffset, Processed, TotalToProcess);

        FreeAndNil(OutStream);
        FreeAndNil(DstStream);
        FreeAndNil(SrcStream);

        if TfrmSmoothLoading.CancelRequested then
        begin
          ForceDeleteFile(FTempFileName);
          if FBackupPath <> '' then ForceDeleteFile(FBackupPath);
          FBackupPath := '';
          TfrmSmoothLoading.ResetCancel;
          SysUtils.Abort;
        end;

        if FShowLoadingUI then
        begin
          FCurrentPercent := 99;
          TfrmSmoothLoading.PostProgressWithDetailFromWorker(99,
            TrText('MergeFiles.Progress.Finalizing'));
        end;

        if not UnUtils.TryRenameTempOverTarget(FTempFileName, FDestinationFileName, RenameErr) then
          raise Exception.Create(RenameErr);

        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressFromWorker(100);

        FSuccess := True;
      end;
      end;
    except
      on EAbort do
        FSuccess := False;
      on E: Exception do
      begin
        FErrorMsg := DiskOperationFailureMessage(E);
        LogAsync(FastFileRuntimeLogPath,
          '[Thread de Mesclagem de Arquivos] ' + E.Message);
        if Assigned(OutStream) then FreeAndNil(OutStream);
        if Assigned(DstStream) then FreeAndNil(DstStream);
        if Assigned(SrcStream) then FreeAndNil(SrcStream);
        if Assigned(BackupDst) then FreeAndNil(BackupDst);
        if Assigned(BackupSrc) then FreeAndNil(BackupSrc);
        ForceDeleteFile(FTempFileName);
        if UseAppend then
          RestoreDestinationFromBackup
        else if (FBackupPath <> '') and FileExists(FBackupPath) then
        begin
          ForceDeleteFile(FBackupPath);
          FBackupPath := '';
        end;
        Synchronize(SyncError);
      end;
    end;
  finally
    if Assigned(OutStream) then FreeAndNil(OutStream);
    if Assigned(DstStream) then FreeAndNil(DstStream);
    if Assigned(SrcStream) then FreeAndNil(SrcStream);
    if Assigned(BackupDst) then FreeAndNil(BackupDst);
    if Assigned(BackupSrc) then FreeAndNil(BackupSrc);
  end;
  Synchronize(FinishThread);
end;

{ ============================================================================ }
{ THREAD: JOIN EQUAL-SPLIT PARTS (.part001..N -> destination)                  }
{ ============================================================================ }

constructor TJoinEqualSplitPartsThread.Create(const ADestinationFileName: String;
  APartPaths: TStrings; const AutoHide: Boolean; const ShowUI: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FDestinationFileName := ADestinationFileName;
  FPartPaths := TStringList.Create;
  if Assigned(APartPaths) then
    FPartPaths.Assign(APartPaths);
  FPartCount := FPartPaths.Count;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FSuccess := False;
  FCancelled := False;
  FErrorMsg := '';
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('MergeFiles.Join.Progress');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TJoinEqualSplitPartsThread.Destroy;
begin
  FreeAndNil(FPartPaths);
  FreeAndNil(sw);
  inherited;
end;

procedure TJoinEqualSplitPartsThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TJoinEqualSplitPartsThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TJoinEqualSplitPartsThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TJoinEqualSplitPartsThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FErrorMsg <> '' then
    ShowAppMessage(TrText('Merge files error: ') + FErrorMsg);
end;

procedure TJoinEqualSplitPartsThread.SyncFinish;
var
  TimeStr: string;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FCancelled then
  begin
    ShowAppMessage(TrText('MergeFiles.Join.Cancelled'));
    Exit;
  end;

  if FSuccess then
  begin
    TimeStr := Format(TrText('Merge files completed in: %s millisecs.'),
      [sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds)]);
    if Assigned(frmMain) then
      frmMain.AppendOperationTimerLog(TimeStr);
    ShowAppMessage(Format(TrText('MergeFiles.Join.Success'),
      [FPartCount, FDestinationFileName]));
  end;
end;

procedure TJoinEqualSplitPartsThread.Execute;
const
  BUF_SIZE = 4 * 1024 * 1024;
var
  OutS, InS: TFileStream;
  i: Integer;
  TotalBytes, Processed: Int64;
  Buffer: array of Byte;
  Remaining, ToRead: Int64;
  ReadBytes: Integer;
  NewPercent: Integer;
  PostMb: Int64;
  PartPath: string;

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
    for RetryCount := 1 to 10 do
    begin
      if DeleteFile(FileName) then
      begin
        Result := True;
        Break;
      end;
      Sleep(200);
    end;
  end;

begin
  inherited;
  OutS := nil;
  InS := nil;
  Processed := 0;
  FCurrentPercent := 0;
  FProgressPostMb := -1;
  try
    try
      if FPartCount < 1 then
        raise Exception.Create(TrText('MergeFiles.Join.NoPartsFound'));

      TotalBytes := 0;
      for i := 0 to FPartCount - 1 do
      begin
        PartPath := FPartPaths[i];
        if not FileExists(PartPath) then
          raise Exception.Create(Format(TrText('Source file not found.') + ' (%s)', [PartPath]));
        Inc(TotalBytes, UnUtils.GetFileSize(PartPath));
      end;
      if TotalBytes <= 0 then
        TotalBytes := 1;

      OutS := TFileStream.Create(FDestinationFileName, fmCreate);
      try
        SetLength(Buffer, BUF_SIZE);
        for i := 0 to FPartCount - 1 do
        begin
          if Terminated or TfrmSmoothLoading.CancelRequested then
          begin
            FCancelled := True;
            Break;
          end;

          PartPath := FPartPaths[i];
          if FShowLoadingUI then
            TfrmSmoothLoading.PostProgressWithDetailFromWorker(FCurrentPercent,
              Format(TrText('MergeFiles.Join.ProgressDetail'), [i + 1, FPartCount]));

          InS := TFileStream.Create(PartPath, fmOpenRead or fmShareDenyNone);
          try
            Remaining := InS.Size;
            while (Remaining > 0) and (not Terminated)
              and (not TfrmSmoothLoading.CancelRequested) do
            begin
              ToRead := Remaining;
              if ToRead > BUF_SIZE then
                ToRead := BUF_SIZE;
              ReadBytes := InS.Read(Buffer[0], Integer(ToRead));
              if ReadBytes <= 0 then
                Break;
              OutS.WriteBuffer(Buffer[0], ReadBytes);
              Dec(Remaining, ReadBytes);
              Inc(Processed, ReadBytes);

              NewPercent := Round((Processed * 100.0) / TotalBytes);
              if NewPercent > 100 then
                NewPercent := 100;
              if (NewPercent < 1) and (Processed > 0) then
                NewPercent := 1;
              PostMb := Processed div (32 * 1024 * 1024);
              if (NewPercent > FCurrentPercent) or (PostMb > FProgressPostMb) then
              begin
                if PostMb > FProgressPostMb then
                  FProgressPostMb := PostMb;
                FCurrentPercent := NewPercent;
                FPercentToSync := FCurrentPercent;
                TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
              end;
            end;
          finally
            FreeAndNil(InS);
          end;

          if Terminated or TfrmSmoothLoading.CancelRequested then
          begin
            FCancelled := True;
            Break;
          end;
        end;
      finally
        FreeAndNil(OutS);
      end;

      if FCancelled then
        ForceDeleteFile(FDestinationFileName)
      else
      begin
        if FShowLoadingUI then
          TfrmSmoothLoading.PostProgressFromWorker(100);
        FSuccess := True;
      end;
    except
      on E: Exception do
      begin
        FreeAndNil(InS);
        FreeAndNil(OutS);
        ForceDeleteFile(FDestinationFileName);
        FErrorMsg := DiskOperationFailureMessage(E);
        LogAsync(FastFileRuntimeLogPath,
          '[JoinEqualSplitParts] ' + E.Message);
        Synchronize(SyncError);
      end;
    end;
  finally
    FreeAndNil(InS);
    FreeAndNil(OutS);
  end;
  Synchronize(SyncFinish);
end;

{ ============================================================================ }
{ SPLIT EQUAL PARTS — line count (heap buffer, optional progress)              }
{ ============================================================================ }

function FastFileCountLinesLf(const AFileName: String; const AReportProgress: Boolean): Int64;
const
  BUF_SIZE = 256 * 1024;
  COUNT_PROGRESS_MAX = 40;
var
  F: TFileStream;
  Buffer: PAnsiChar;
  BytesRead: Integer;
  LFShift: TBMHByteShiftTable;
  LastWasLF: Boolean;
  FileSize, Processed: Int64;
  NewPct, LastPct: Integer;
  TermB: Byte;
begin
  Result := 0;
  if not FileExists(AFileName) then Exit;
  TermB := LineTermByteForFile(AFileName);

  F := nil;
  Buffer := nil;
  try
    try
      begin
      GetMem(Buffer, BUF_SIZE);
      F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
      FileSize := F.Size;
      BMHInitSingleByte(LFShift);
      LastWasLF := False;
      LastPct := -1;
      Processed := 0;
      while True do
      begin
        if TfrmSmoothLoading.CancelRequested then
        begin
          Result := -2;
          Exit;
        end;
        BytesRead := F.Read(Buffer^, BUF_SIZE);
        if BytesRead <= 0 then Break;

        Inc(Result, BMHCountBytePAnsi(Buffer, BytesRead, TermB, LFShift));
        if BytesRead > 0 then
          LastWasLF := (Byte(Buffer[BytesRead - 1]) = TermB);
        Inc(Processed, BytesRead);

        if AReportProgress and (FileSize > 0) then
        begin
          NewPct := Round((Processed * COUNT_PROGRESS_MAX) / FileSize);
          if NewPct > COUNT_PROGRESS_MAX then NewPct := COUNT_PROGRESS_MAX;
          if NewPct > LastPct then
          begin
            LastPct := NewPct;
            TfrmSmoothLoading.PostProgressWithDetailFromWorker(NewPct,
              TrText('SplitEqualParts.CountingLines'));
          end;
        end;
      end;

      if (FileSize > 0) and (not LastWasLF) then
        Inc(Result);
      end;
    except
      Result := -1;
    end;
  finally
    if Assigned(F) then
      F.Free;
    if Buffer <> nil then
      FreeMem(Buffer);
  end;
end;

function FastFileSplitPartFileSuffix(const PartIndex1Based, TotalParts: Integer): String;
begin
  Result := '.' + TrText('SplitFilePart.FilenamePart') + '_' +
    IntToStr(PartIndex1Based) + '_' + TrText('SplitFilePart.FilenameOf') + '_' +
    IntToStr(TotalParts);
end;

{ Remove trailing CR/LF so part files match FastFile line indexing (LF count + 1). }
procedure SplitPartTrimTrailingLineTerminators(AOut: TFileStream);
var
  Pos: Int64;
  B: Byte;
begin
  if not Assigned(AOut) or (AOut.Size <= 0) then Exit;
  Pos := AOut.Size - 1;
  while Pos >= 0 do
  begin
    AOut.Seek(Pos, soBeginning);
    if AOut.Read(B, 1) <> 1 then Break;
    if not (B in [10, 13]) then Break;
    Dec(Pos);
  end;
  AOut.Size := Pos + 1;
end;

{ ============================================================================ }
{ THREAD: SPLIT FILE INTO EQUAL PARTS (balanced line counts, LF boundaries)    }
{ ============================================================================ }

constructor TSplitEqualPartsThread.Create(const ASourceFileName: String;
  const APartCount: Integer; const ATotalLines: Int64; const AutoHide: Boolean;
  const ShowUI: Boolean; const AHeader: String; const AFooter: String);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSourceFileName := ASourceFileName;
  FPartCount := APartCount;
  FTotalLines := ATotalLines;
  FHeader := AHeader;
  FFooter := AFooter;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  if FShowLoadingUI then
  begin
    if FTotalLines > 0 then
      FLoadingMsg := TrText('Splitting file into equal parts...')
    else
      FLoadingMsg := TrText('SplitEqualParts.CountingLines');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  FSuccessOutputDir := '';
  FSuccessFirstPath := '';
  FSuccessLastPath := '';
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TSplitEqualPartsThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TSplitEqualPartsThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TSplitEqualPartsThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TSplitEqualPartsThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TSplitEqualPartsThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TSplitEqualPartsThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
end;

procedure TSplitEqualPartsThread.SyncFinish;
var
  TimeStr: String;
  Msg: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;

  if FSuccess then
  begin
    TimeStr := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
    Msg := Format(TrText('SplitEqualParts.SuccessFormat'),
      [FPartCount, FSuccessOutputDir, FSuccessFirstPath, FSuccessLastPath, TimeStr]);
    FastFileMsgInfo(Msg);
    if Assigned(frmMain) then
    begin
      frmMain.AppendOperationTimerLog(Format(TrText('SplitEqualParts.LogSummary'),
        [FPartCount, FSuccessOutputDir]));
      frmMain.AssistantOfferAfterActivity('split',
        Format(TrText('Assistant.Offer.Summary.Split'), [FPartCount]));
    end;
  end
  else if FErrorMsg <> '' then
    FastFileMsgInfo(Format(TrText('SplitEqualParts.FailureFormat'), [FErrorMsg]))
  else
    FastFileMsgInfo(TrText('SplitEqualParts.CancelledOrIncomplete'));
  if Assigned(frmMain) then
    frmMain.RestoreViewAfterSplitExport;
end;

procedure TSplitEqualPartsThread.Execute;
var
  MMF: TMMFReader;
  OutStream: TFileStream;
  FileSize: Int64;
  AbsOffset: Int64;
  Contiguous: Cardinal;
  P: PByte;
  PartIdx: Integer;
  LinesTarget, LinesWritten: Int64;
  PartPath: String;
  LFShift: TBMHByteShiftTable;
  LastPostedPercent: Integer;
  LastProgressTick: Cardinal;
  TermB: Byte;
  OutEol: AnsiString;

  function ForceDeleteLocal(const FileName: string): Boolean;
  var
    RetryCount: Integer;
  begin
    Result := False;
    if not FileExists(FileName) then begin Result := True; Exit; end;
    for RetryCount := 1 to 10 do
    begin
      if DeleteFile(FileName) then
      begin
        Result := True;
        Break;
      end;
      Sleep(200);
    end;
  end;

  function OutputPartPath(const PartIndex1Based: Integer): String;
  var
    DirPath, BaseName, ExtPart: String;
  begin
    DirPath := ExtractFilePath(FSourceFileName);
    BaseName := ExtractFileName(FSourceFileName);
    ExtPart := ExtractFileExt(BaseName);
    BaseName := ChangeFileExt(BaseName, '');
    Result := IncludeTrailingPathDelimiter(DirPath) + BaseName +
      Format('.part%.3d', [PartIndex1Based]) + ExtPart;
  end;

  function PartLineTarget(const PartIdx0: Integer): Int64;
  var
    Base, Rem: Int64;
  begin
    Base := FTotalLines div FPartCount;
    Rem := FTotalLines mod FPartCount;
    Result := Base;
    if PartIdx0 < Rem then
      Inc(Result);
  end;

  procedure WritePartHeader(AOut: TFileStream);
  var
    StrHeader: AnsiString;
  begin
    if FHeader = '' then Exit;
    if (Length(FHeader) > 0) and not (FHeader[Length(FHeader)] in [#10, #13]) then
      StrHeader := FHeader + OutEol
    else
      StrHeader := FHeader;
    if Length(StrHeader) > 0 then
      AOut.WriteBuffer(Pointer(StrHeader)^, Length(StrHeader));
  end;

  procedure WritePartFooter(AOut: TFileStream);
  var
    StrFooter, StrCrLf: AnsiString;
  begin
    if FFooter = '' then Exit;
    StrFooter := FFooter;
    AOut.WriteBuffer(Pointer(StrFooter)^, Length(StrFooter));
    if not (FFooter[Length(FFooter)] in [#10, #13]) then
    begin
      StrCrLf := OutEol;
      AOut.WriteBuffer(Pointer(StrCrLf)^, Length(StrCrLf));
    end;
  end;

  procedure OpenNextPart(const PartIndex1Based: Integer);
  begin
    if Assigned(OutStream) then
    begin
      SplitPartTrimTrailingLineTerminators(OutStream);
      WritePartFooter(OutStream);
      FreeAndNil(OutStream);
    end;
    PartPath := OutputPartPath(PartIndex1Based);
    ForceDeleteLocal(PartPath);
    OutStream := TFileStream.Create(PartPath, fmCreate);
    WritePartHeader(OutStream);
  end;

  procedure ProcessChunk(const Chunk: PAnsiChar; const ChunkLen: Integer);
  var
    RunStart, SearchAt, LFPos: Integer;
  begin
    if (Chunk = nil) or (ChunkLen <= 0) then Exit;
    RunStart := 0;
    SearchAt := 0;
    while SearchAt < ChunkLen do
    begin
      LFPos := BMHFindBytePAnsi(Chunk, ChunkLen, SearchAt, TermB, LFShift);
      if LFPos < 0 then Break;

      OutStream.WriteBuffer((Chunk + RunStart)^, LFPos - RunStart + 1);
      RunStart := LFPos + 1;
      SearchAt := LFPos + 1;
      Inc(LinesWritten);
      if (PartIdx < FPartCount - 1) and (LinesWritten >= LinesTarget) then
      begin
        Inc(PartIdx);
        LinesWritten := 0;
        LinesTarget := PartLineTarget(PartIdx);
        OpenNextPart(PartIdx + 1);
      end;
    end;
    if RunStart < ChunkLen then
      OutStream.WriteBuffer((Chunk + RunStart)^, ChunkLen - RunStart);
  end;

  procedure UpdateProgressIfNeeded;
  const
    SPLIT_PROGRESS_BASE = 40;
    SPLIT_PROGRESS_SPAN = 60;
  var
    NewPercent: Integer;
  begin
    if FileSize <= 0 then Exit;
    if (GetTickCount - LastProgressTick) < 200 then Exit;
    LastProgressTick := GetTickCount;
    NewPercent := SPLIT_PROGRESS_BASE +
      Round((AbsOffset * SPLIT_PROGRESS_SPAN) / FileSize);
    if NewPercent > 100 then NewPercent := 100;
    if NewPercent > FCurrentPercent then
    begin
      FCurrentPercent := NewPercent;
      FPercentToSync := FCurrentPercent;
      if FPercentToSync <> LastPostedPercent then
      begin
        TfrmSmoothLoading.PostProgressWithDetailFromWorker(FPercentToSync,
          UnUtils.FormatNumber(AbsOffset) + ' / ' + UnUtils.FormatNumber(FileSize) + ' B');
        LastPostedPercent := FPercentToSync;
      end;
    end;
  end;

begin
  inherited;
  MMF := nil;
  OutStream := nil;
  BMHInitSingleByte(LFShift);
  TermB := LineTermByteForFile(FSourceFileName);
  OutEol := OutputEolForFile(FSourceFileName);

  if FPartCount < 2 then
  begin
    FErrorMsg := TrText('Could not compute split boundaries: file too small for the requested number of parts.');
    Synchronize(SyncError);
    Synchronize(SyncFinish);
    Exit;
  end;

  try
    try
      begin
      if FTotalLines <= 0 then
      begin
        FTotalLines := FastFileCountLinesLf(FSourceFileName, FShowLoadingUI);
        { Abort (not Exit): Exit would skip Synchronize(SyncFinish) and leave the overlay up. }
        if (FTotalLines = -2) or TfrmSmoothLoading.CancelRequested then
          SysUtils.Abort;
        if FTotalLines < 0 then
          raise Exception.Create(TrText('Could not count lines in the source file.'));
        if FTotalLines < FPartCount then
          raise Exception.Create(Format(
            TrText('Not enough lines in the file for this many parts (lines: %d, parts: %d).'),
            [FTotalLines, FPartCount]));
        if FShowLoadingUI then
        begin
          FCurrentPercent := 0;
          FLoadingMsg := TrText('Splitting file into equal parts...');
          Synchronize(SyncShowLoading);
          Synchronize(SyncSetProgress);
        end;
      end;

      MMF := TMMFReader.Create(FSourceFileName);
      FileSize := MMF.FileSize;
      if FileSize <= 0 then
        raise Exception.Create(TrText('Source file is empty.'));

      FCurrentPercent := 0;
      AbsOffset := 0;
      LastPostedPercent := -1;
      LastProgressTick := 0;
      PartIdx := 0;
      LinesWritten := 0;
      LinesTarget := PartLineTarget(0);
      OpenNextPart(1);

      while (AbsOffset < FileSize) and (not Terminated) and (not TfrmSmoothLoading.CancelRequested) do
      begin
        P := MMF.PtrAt(AbsOffset, 1, Contiguous);
        if (P = nil) or (Contiguous = 0) then Break;

        ProcessChunk(PAnsiChar(P), Integer(Contiguous));
        Inc(AbsOffset, Contiguous);
        UpdateProgressIfNeeded;
      end;

      if Assigned(OutStream) then
      begin
        SplitPartTrimTrailingLineTerminators(OutStream);
        WritePartFooter(OutStream);
        FreeAndNil(OutStream);
      end;

      if (FileSize > 0) and (FCurrentPercent < 100) then
      begin
        FCurrentPercent := 100;
        FPercentToSync := 100;
        TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
      end;

      FSuccessOutputDir := IncludeTrailingPathDelimiter(ExtractFilePath(FSourceFileName));
      FSuccessFirstPath := OutputPartPath(1);
      FSuccessLastPath := OutputPartPath(FPartCount);

      FreeAndNil(MMF);
      FSuccess := not TfrmSmoothLoading.CancelRequested;
      end;
    except
      on EAbort do
        FSuccess := False;
      on E: Exception do
      begin
        FErrorMsg := DiskOperationFailureMessage(E);
        LogAsync(FastFileRuntimeLogPath,
          '[SplitEqualPartsThread] ' + E.Message);
        if Assigned(OutStream) then FreeAndNil(OutStream);
        if Assigned(MMF) then FreeAndNil(MMF);
        Synchronize(SyncError);
      end;
    end;
  finally
    if Assigned(OutStream) then FreeAndNil(OutStream);
    if Assigned(MMF) then FreeAndNil(MMF);
    { Avoid leaking cancel state into the next operation }
    TfrmSmoothLoading.ResetCancel;
  end;
  Synchronize(SyncFinish);
end;

{ ============================================================================ }
{ THREAD: SPLIT FILE FRACTION (subset of equal LF-aligned parts)               }
{ ============================================================================ }

constructor TSplitFileFractionThread.Create(const ASourceFileName: String;
  const APartCount, APartFrom, APartTo: Integer; const ATotalLines: Int64;
  const AutoHide: Boolean; const ShowUI: Boolean; const AHeader: String;
  const AFooter: String);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSourceFileName := ASourceFileName;
  FPartCount := APartCount;
  FPartFrom := APartFrom;
  FPartTo := APartTo;
  FTotalLines := ATotalLines;
  FHeader := AHeader;
  FFooter := AFooter;
  FAutoHide := AutoHide;
  FShowLoadingUI := ShowUI;
  FExportedCount := 0;
  if FShowLoadingUI then
  begin
    if FTotalLines > 0 then
      FLoadingMsg := TrText('SplitFileFraction.Extracting')
    else
      FLoadingMsg := TrText('SplitEqualParts.CountingLines');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
  end;
  FSuccess := False;
  FSuccessOutputDir := '';
  FSuccessFirstPath := '';
  FSuccessLastPath := '';
  sw := TStopWatch.Create(True);
  Resume;
end;

destructor TSplitFileFractionThread.Destroy;
begin
  FreeAndNil(sw);
  inherited;
end;

procedure TSplitFileFractionThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FLoadingMsg);
end;

procedure TSplitFileFractionThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TSplitFileFractionThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TSplitFileFractionThread.SyncProgress;
begin
  if not FShowLoadingUI then Exit;
  FProgressToSet := FPercentToSync;
  SyncSetProgress;
end;

procedure TSplitFileFractionThread.SyncError;
begin
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
end;

procedure TSplitFileFractionThread.SyncFinish;
var
  TimeStr: String;
  Msg: String;
  FirstName, LastName: String;
begin
  sw.Stop;
  if FAutoHide and FShowLoadingUI then
    SyncHideLoading;
  if FSuccess then
  begin
    TimeStr := sw.FormatMillisecondsToDateTime(sw.ElapsedMilliseconds);
    FirstName := ExtractFileName(FSuccessFirstPath);
    LastName := ExtractFileName(FSuccessLastPath);
    Msg := Format(TrText('SplitFileFraction.SuccessFormat'),
      [FExportedCount, FPartFrom, FPartTo, FPartCount, FSuccessOutputDir,
       FirstName, LastName, TimeStr]);
    if Assigned(frmMain) then
    begin
      frmMain.ShowSplitExportResultDialog(Msg);
      frmMain.AppendOperationTimerLog(Format(TrText('SplitFileFraction.LogSummary'),
        [FExportedCount, FSuccessOutputDir]));
    end
    else
      FastFileMsgInfo(Msg);
  end
  else if FErrorMsg <> '' then
    FastFileMsgInfo(Format(TrText('SplitFileFraction.FailureFormat'), [FErrorMsg]))
  else
    FastFileMsgInfo(TrText('SplitFileFraction.CancelledOrIncomplete'));
  if Assigned(frmMain) then
    frmMain.RestoreViewAfterSplitExport;
end;

procedure TSplitFileFractionThread.Execute;
var
  MMF: TMMFReader;
  OutStream: TFileStream;
  FileSize: Int64;
  AbsOffset: Int64;
  Contiguous: Cardinal;
  P: PByte;
  PartIdx: Integer;
  LinesTarget, LinesWritten: Int64;
  PartPath: String;
  LFShift: TBMHByteShiftTable;
  LastPostedPercent: Integer;
  LastProgressTick: Cardinal;
  TermB: Byte;
  OutEol: AnsiString;

  function PartShouldExport(const PartIndex1Based: Integer): Boolean;
  begin
    Result := (PartIndex1Based >= FPartFrom) and (PartIndex1Based <= FPartTo);
  end;

  function ForceDeleteLocal(const FileName: string): Boolean;
  var
    RetryCount: Integer;
  begin
    Result := False;
    if not FileExists(FileName) then begin Result := True; Exit; end;
    for RetryCount := 1 to 10 do
    begin
      if DeleteFile(FileName) then
      begin
        Result := True;
        Break;
      end;
      Sleep(200);
    end;
  end;

  function OutputFractionPath(const PartIndex1Based: Integer): String;
  var
    DirPath, BaseName, ExtPart: String;
  begin
    DirPath := ExtractFilePath(FSourceFileName);
    BaseName := ExtractFileName(FSourceFileName);
    ExtPart := ExtractFileExt(BaseName);
    BaseName := ChangeFileExt(BaseName, '');
    Result := IncludeTrailingPathDelimiter(DirPath) + BaseName +
      FastFileSplitPartFileSuffix(PartIndex1Based, FPartCount) + ExtPart;
  end;

  function PartLineTarget(const PartIdx0: Integer): Int64;
  var
    Base, Rem: Int64;
  begin
    Base := FTotalLines div FPartCount;
    Rem := FTotalLines mod FPartCount;
    Result := Base;
    if PartIdx0 < Rem then
      Inc(Result);
  end;

  procedure WritePartHeader(AOut: TFileStream);
  var
    StrHeader: AnsiString;
  begin
    if FHeader = '' then Exit;
    if (Length(FHeader) > 0) and not (FHeader[Length(FHeader)] in [#10, #13]) then
      StrHeader := FHeader + OutEol
    else
      StrHeader := FHeader;
    if Length(StrHeader) > 0 then
      AOut.WriteBuffer(Pointer(StrHeader)^, Length(StrHeader));
  end;

  procedure WritePartFooter(AOut: TFileStream);
  var
    StrFooter, StrCrLf: AnsiString;
  begin
    if FFooter = '' then Exit;
    StrFooter := FFooter;
    AOut.WriteBuffer(Pointer(StrFooter)^, Length(StrFooter));
    if not (FFooter[Length(FFooter)] in [#10, #13]) then
    begin
      StrCrLf := OutEol;
      AOut.WriteBuffer(Pointer(StrCrLf)^, Length(StrCrLf));
    end;
  end;

  procedure CloseCurrentPart;
  begin
    if not Assigned(OutStream) then Exit;
    WritePartFooter(OutStream);
    FreeAndNil(OutStream);
  end;

  procedure EnterPart(const PartIndex1Based: Integer);
  begin
    CloseCurrentPart;
    if not PartShouldExport(PartIndex1Based) then Exit;
    PartPath := OutputFractionPath(PartIndex1Based);
    ForceDeleteLocal(PartPath);
    OutStream := TFileStream.Create(PartPath, fmCreate);
    WritePartHeader(OutStream);
    if FSuccessFirstPath = '' then
      FSuccessFirstPath := PartPath;
    FSuccessLastPath := PartPath;
    Inc(FExportedCount);
  end;

  procedure ProcessChunk(const Chunk: PAnsiChar; const ChunkLen: Integer);
  var
    RunStart, SearchAt, LFPos: Integer;
  begin
    if (Chunk = nil) or (ChunkLen <= 0) then Exit;
    RunStart := 0;
    SearchAt := 0;
    while SearchAt < ChunkLen do
    begin
      LFPos := BMHFindBytePAnsi(Chunk, ChunkLen, SearchAt, TermB, LFShift);
      if LFPos < 0 then Break;
      if Assigned(OutStream) then
        OutStream.WriteBuffer((Chunk + RunStart)^, LFPos - RunStart + 1);
      RunStart := LFPos + 1;
      SearchAt := LFPos + 1;
      Inc(LinesWritten);
      if (PartIdx < FPartCount - 1) and (LinesWritten >= LinesTarget) then
      begin
        Inc(PartIdx);
        LinesWritten := 0;
        LinesTarget := PartLineTarget(PartIdx);
        EnterPart(PartIdx + 1);
      end;
    end;
    if Assigned(OutStream) and (RunStart < ChunkLen) then
      OutStream.WriteBuffer((Chunk + RunStart)^, ChunkLen - RunStart);
  end;

  procedure UpdateProgressIfNeeded;
  const
    SPLIT_PROGRESS_BASE = 40;
    SPLIT_PROGRESS_SPAN = 60;
  var
    NewPercent: Integer;
  begin
    if FileSize <= 0 then Exit;
    if (GetTickCount - LastProgressTick) < 200 then Exit;
    LastProgressTick := GetTickCount;
    NewPercent := SPLIT_PROGRESS_BASE +
      Round((AbsOffset * SPLIT_PROGRESS_SPAN) / FileSize);
    if NewPercent > 100 then NewPercent := 100;
    if NewPercent > FCurrentPercent then
    begin
      FCurrentPercent := NewPercent;
      FPercentToSync := FCurrentPercent;
      if FPercentToSync <> LastPostedPercent then
      begin
        TfrmSmoothLoading.PostProgressWithDetailFromWorker(FPercentToSync,
          UnUtils.FormatNumber(AbsOffset) + ' / ' + UnUtils.FormatNumber(FileSize) + ' B');
        LastPostedPercent := FPercentToSync;
      end;
    end;
  end;

begin
  inherited;
  MMF := nil;
  OutStream := nil;
  BMHInitSingleByte(LFShift);
  TermB := LineTermByteForFile(FSourceFileName);
  OutEol := OutputEolForFile(FSourceFileName);
  FExportedCount := 0;

  if (FPartCount < 2) or (FPartFrom < 1) or (FPartTo > FPartCount) or (FPartFrom > FPartTo) then
  begin
    FErrorMsg := TrText('SplitFileFraction.InvalidRange');
    Synchronize(SyncError);
    Synchronize(SyncFinish);
    Exit;
  end;

  try
    try
      begin
      if FTotalLines <= 0 then
      begin
        FTotalLines := FastFileCountLinesLf(FSourceFileName, FShowLoadingUI);
        if (FTotalLines = -2) or TfrmSmoothLoading.CancelRequested then
          SysUtils.Abort;
        if FTotalLines < 0 then
          raise Exception.Create(TrText('Could not count lines in the source file.'));
        if FTotalLines < FPartCount then
          raise Exception.Create(Format(
            TrText('Not enough lines in the file for this many parts (lines: %d, parts: %d).'),
            [FTotalLines, FPartCount]));
        if FShowLoadingUI then
        begin
          FCurrentPercent := 0;
          FLoadingMsg := TrText('SplitFileFraction.Extracting');
          Synchronize(SyncShowLoading);
          Synchronize(SyncSetProgress);
        end;
      end;

      MMF := TMMFReader.Create(FSourceFileName);
      FileSize := MMF.FileSize;
      if FileSize <= 0 then
        raise Exception.Create(TrText('Source file is empty.'));

      FCurrentPercent := 0;
      AbsOffset := 0;
      LastPostedPercent := -1;
      LastProgressTick := 0;
      PartIdx := 0;
      LinesWritten := 0;
      LinesTarget := PartLineTarget(0);
      EnterPart(1);

      while (AbsOffset < FileSize) and (not Terminated) and (not TfrmSmoothLoading.CancelRequested) do
      begin
        P := MMF.PtrAt(AbsOffset, 1, Contiguous);
        if (P = nil) or (Contiguous = 0) then Break;
        ProcessChunk(PAnsiChar(P), Integer(Contiguous));
        Inc(AbsOffset, Contiguous);
        UpdateProgressIfNeeded;
      end;

      CloseCurrentPart;

      if (FileSize > 0) and (FCurrentPercent < 100) then
      begin
        FCurrentPercent := 100;
        FPercentToSync := 100;
        TfrmSmoothLoading.PostProgressFromWorker(FPercentToSync);
      end;

      if FExportedCount <= 0 then
        raise Exception.Create(TrText('SplitFileFraction.NoPartsExported'));

      FSuccessOutputDir := IncludeTrailingPathDelimiter(ExtractFilePath(FSourceFileName));
      FreeAndNil(MMF);
      FSuccess := not TfrmSmoothLoading.CancelRequested;
      end;
    except
      on EAbort do
        FSuccess := False;
      on E: Exception do
      begin
        FErrorMsg := DiskOperationFailureMessage(E);
        LogAsync(FastFileRuntimeLogPath, '[SplitFileFractionThread] ' + E.Message);
        CloseCurrentPart;
        if Assigned(MMF) then FreeAndNil(MMF);
        Synchronize(SyncError);
      end;
    end;
  finally
    CloseCurrentPart;
    if Assigned(MMF) then FreeAndNil(MMF);
    TfrmSmoothLoading.ResetCancel;
  end;
  Synchronize(SyncFinish);
end;

{ ============================================================================ }
{ ZERO SCAN: discover last physical line (full LF count, titans)               }
{ ============================================================================ }

constructor TZeroScanDiscoverLastLineThread.Create(const AFileName: String);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FLineCount := 0;
  Synchronize(SyncShowLoading);
  Resume;
end;

procedure TZeroScanDiscoverLastLineThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(TrText('ZeroScan.DiscoveringLastLine'));
end;

procedure TZeroScanDiscoverLastLineThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TZeroScanDiscoverLastLineThread.SyncFinish;
begin
  SyncHideLoading;
  TfrmSmoothLoading.ResetCancel;
  if Assigned(frmMain) then
  begin
    if (FLineCount > 0) and (not TfrmSmoothLoading.CancelRequested) then
      frmMain.FinishZeroScanDiscoverLastLine(FLineCount)
    else
      frmMain.FinishZeroScanDiscoverLastLine(0);
  end;
end;

procedure TZeroScanDiscoverLastLineThread.Execute;
begin
  inherited;
  try
    try
      begin
        FLineCount := FastFileCountLinesLf(FFileName, True);
        if (FLineCount = -2) or TfrmSmoothLoading.CancelRequested then
          FLineCount := 0
        else if FLineCount < 1 then
          FLineCount := 0;
      end;
    except
      FLineCount := 0;
    end;
  finally
    Synchronize(SyncFinish);
  end;
end;

end.
