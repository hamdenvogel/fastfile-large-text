unit uCompareMergeUI;

interface

uses
  uPosBMH,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Menus, Grids,
  uLineDiffCore, uHistPagedPreview, sSpeedButton, sPanel, uFastFileFloatHost,
  uHistChangedIndex, uMergeApply, System.Generics.Collections, System.Generics.Defaults,
  sToolEdit;

const
  { Worker -> main: pintar overlay ja' (coalesce em WMHistProgressFlush); complementa o TTimer. }
  WM_FF_HIST_PROGRESS_FLUSH = WM_APP + 92;
  { Worker -> main: progresso do diff (TDiffWorkerThread). }
  WM_FF_DIFF_PROGRESS_FLUSH = WM_APP + 93;
  { Apos LVM_SETTOPINDEX: limpar selecao nativa (o Win32 marca o topo como Selected). }
  WM_FF_HIST_CLEAR_SEL = WM_APP + 94;
  { Adiar ApplyJournalDisplayMode / jump apos click (evita AV no AlphaControls WndProc). }
  WM_FF_APPLY_JOURNAL_VIEW = WM_APP + 95;
  WM_FF_JOURNAL_JUMP = WM_APP + 96;
  { Abrir o MRU de ficheiros com historico depois de soltar o botao do rato. }
  WM_FF_HIST_SOURCE_MRU = WM_APP + 97;
  WM_FF_CHG_INDEX = WM_APP + 98;
  WM_FF_CHG_EVENTS = WM_APP + 99;
  WM_FF_MERGE_APPLY = WM_APP + 100;
  cHistPaneSplitterH = 5;
  cHistPaneMinH = 64;
  { Etapas do hook do merge (so' quando APath e' o ficheiro aberto no form principal). }
  cFFMergeHookRelease = 0; { libertar o handle: o ficheiro vai ser trocado (ReplaceFile) }
  cFFMergeHookReload = 1;  { linhas mudaram de posicao ou handle foi libertado: reindexar }
  cFFMergeHookRepaint = 2; { so' edicoes do mesmo tamanho: indice valido, so' reler o texto }

type
  TFFCompareMergeFileHook = procedure(const APath: string; AStage: Integer) of object;

var
  GFFCompareMergeFileHook: TFFCompareMergeFileHook = nil;

type
  THistCtlSnap = record
    Ctl: TControl;
    FontH: Integer;
    H: Integer;
    RowH: Integer;
    Bounds: TRect;
  end;
  THistCtlSnaps = array of THistCtlSnap;

  TfrmCompareMerge = class(TForm)
    PageControl1: TPageControl;
    TabSheetHistory: TTabSheet;
    TabSheetDiff: TTabSheet;
    lblHistPreview: TLabel;
    lvHistFile: TListView;
    lblHistPath: TLabel;
    btnReloadHist: TButton;
    btnClearHist: TButton;
    lblJournalHint: TLabel;
    mmoJournal: TMemo;
    lblLeft: TLabel;
    lblRight: TLabel;
    lblFirst: TLabel;
    lblLast: TLabel;
    lblLegend: TLabel;
    edtLeftFile: TEdit;
    btnBrowseLeft: TButton;
    edtRightFile: TEdit;
    btnBrowseRight: TButton;
    edtFirstLine: TEdit;
    edtLastLine: TEdit;
    btnRunDiff: TButton;
    chkSyncScroll: TCheckBox;
    btnCopyLeft: TButton;
    btnCopyRight: TButton;
    btnApplyLeftToRight: TButton;
    btnApplyRightToLeft: TButton;
    chkDiffByLines: TCheckBox;
    chkFastLargeFiles: TCheckBox;
    lvLeft: TListView;
    lvRight: TListView;
    Panel1: TPanel;
    lblNote: TLabel;
    btnClose: TButton;
    OpenDialog1: TOpenDialog;
    tmrSync: TTimer;
    popLvLeft: TPopupMenu;
    mnuLCopy: TMenuItem;
    mnuLApplyToRight: TMenuItem;
    mnuLApplyToLeft: TMenuItem;
    mnuLSelectAll: TMenuItem;
    mnuLGoToLine: TMenuItem;
    popLvRight: TPopupMenu;
    mnuRCopy: TMenuItem;
    mnuRApplyToRight: TMenuItem;
    mnuRApplyToLeft: TMenuItem;
    mnuRSelectAll: TMenuItem;
    mnuRGoToLine: TMenuItem;
    popLvHist: TPopupMenu;
    mnuHistCopyLine: TMenuItem;
    mnuHistCopyText: TMenuItem;
    mnuHistGotoLine: TMenuItem;
    mnuHistSelectAll: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnReloadHistClick(Sender: TObject);
    procedure btnClearHistClick(Sender: TObject);
    procedure btnBrowseLeftClick(Sender: TObject);
    procedure btnBrowseRightClick(Sender: TObject);
    procedure btnRunDiffClick(Sender: TObject);
    procedure btnCopyLeftClick(Sender: TObject);
    procedure btnCopyRightClick(Sender: TObject);
    procedure btnApplyLeftToRightClick(Sender: TObject);
    procedure btnApplyRightToLeftClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure lvLeftCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvRightCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure chkSyncScrollClick(Sender: TObject);
    procedure chkDiffByLinesClick(Sender: TObject);
    procedure tmrSyncTimer(Sender: TObject);
    procedure TabSheetDiffResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TabSheetHistoryResize(Sender: TObject);
    procedure lvHistFileCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvHistFileCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvHistFileAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
    procedure popLvLeftPopup(Sender: TObject);
    procedure popLvRightPopup(Sender: TObject);
    procedure mnuLCopyClick(Sender: TObject);
    procedure mnuLApplyToRightClick(Sender: TObject);
    procedure mnuLApplyToLeftClick(Sender: TObject);
    procedure mnuLSelectAllClick(Sender: TObject);
    procedure mnuRCopyClick(Sender: TObject);
    procedure mnuRApplyToRightClick(Sender: TObject);
    procedure mnuRApplyToLeftClick(Sender: TObject);
    procedure mnuRSelectAllClick(Sender: TObject);
    procedure mnuLGoToLineClick(Sender: TObject);
    procedure mnuRGoToLineClick(Sender: TObject);
    procedure mmoJournalClick(Sender: TObject);
    procedure mmoJournalMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure chkHistShowAllClick(Sender: TObject);
    procedure lvHistFileSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvHistFileMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure popLvHistPopup(Sender: TObject);
    procedure mnuHistCopyLineClick(Sender: TObject);
    procedure mnuHistCopyTextClick(Sender: TObject);
    procedure mnuHistGotoLineClick(Sender: TObject);
    procedure mnuHistSelectAllClick(Sender: TObject);
    procedure lvMergeListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvLeftData(Sender: TObject; Item: TListItem);
    procedure lvRightData(Sender: TObject; Item: TListItem);
    procedure lvHistFileData(Sender: TObject; Item: TListItem);
  private
    FDefaultLeft: string;
    FMainOpenPath: string;
    FNeedMainReload: Boolean;
    FDiffRows: TList;
    FClosing: Boolean;
    FHistoryLoaded: Boolean;
    FClosePosted: Boolean;
    { Linha-alvo no preview (1-based) por linha do mmoJournal; evita TListBox+skin (Items[-1]). }
    FJournalLineNums: TList;
    { Tag da legenda (0..5) e excerto do journal, alinhados com FJournalLineNums. }
    FJournalTags: TList;
    FJournalExcerpts: TStringList;
    { Cache completo do journal (antes do filtro por selecao). }
    FJournalCacheLines: TStringList;
    FJournalCacheLineNums: TList;
    FJournalCacheLineEnds: TList;
    FJournalCacheTags: TList;
    FJournalCacheExcerpts: TStringList;
    FHistShowAllJournal: Boolean;
    FchkHistShowAll: TCheckBox;
    FchkHistChangedList: TCheckBox;
    FbtnChangedCollapse: TButton;
    FbtnChangedClear: TButton;
    FbtnChangedExpand: TButton;
    FpnlJournalBox: TPanel;
    FpnlJournalHdr: TPanel;
    FlblJournalHdr: TLabel;
    FbtnJournalFloat: TButton;
    FpnlPreviewBox: TPanel;
    FpnlPreviewHdr: TPanel;
    FbtnPreviewFloat: TButton;
    FHistPaneSplitter: TPanel;
    FHistJournalRatio: Integer;
    FHistSplitterUserMoved: Boolean;
    FHistSplitStartY: Integer;
    FHistSplitStartH: Integer;
    FHistJournalHost: TFastFileFloatForm;
    FHistPreviewHost: TFastFileFloatForm;
    FHistHdrDown: Boolean;
    FHistHdrPt: TPoint;
    FJournalSnap: THistCtlSnaps;
    FPreviewSnap: THistCtlSnaps;
    FedtHistSource: TEdit;
    FbtnHistSourceMru: TButton;
    FHistSourceItems: TStringList;
    { Lista das linhas com eventos no journal (navegacao rapida). }
    FlblChangedLines: TLabel;
    FlbChangedLines: TListBox;
    FSyncingChangedLines: Boolean;
    { Indice completo das linhas alteradas (thread) + pagina visivel da lista virtual. }
    FChgIdx: THistChangedIndex;
    FChgBuilder: THciBuildThread;
    FChgDirty: Boolean;
    FChgBuildPct: Integer;
    FChgPage: Integer;
    FChgEvtScan: THciEventScanThread;
    FChgEvtLine: Integer;
    FChgEvtRaw: TStringList;
    { Selecao da lista "Linhas alteradas": tudo, ou so' as chaves marcadas. }
    FChgSelAll: Boolean;
    FChgSel, FChgUnsel: TDictionary<Int64, Byte>;
    FChgSort: Integer;
    FChgOrder, FChgOrderRev: TArray<Integer>;
    FChgSuppressNav: Boolean;
    { Seleciona o 1.o registo das linhas alteradas (e o evento no historico) na
      primeira carga do diario, se ainda nada estiver selecionado. }
    FChgAutoSelPending: Boolean;
    FpmChgCtx: TPopupMenu;
    FpmJrnCtx: TPopupMenu;
    FJrnPopRow: Integer;
    FChgToolsH: Integer;
    FChgWhenH: Integer;
    FbtnChgAll, FbtnChgDel, FbtnChgSort, FbtnChgExport, FbtnChgAI: TButton;
    { Eventos do diario: linha crua (vazia = nao e' cabecalho) e marcacao. }
    FJournalRaws, FJournalCacheRaws: TStringList;
    FJrnSel: TDictionary<string, Byte>;
    { Chaves a descartar na reescrita (nil = usar a selecao das linhas alteradas). }
    FRewriteDrop: TDictionary<string, Byte>;
    { Exclusao de eventos de descaracterizacao: FAnonDropLine 0 = todos. }
    FAnonDrop: Boolean;
    FAnonDropLine: Integer;
    FJrnSort: Integer;
    FpnJrnTools: TPanel;
    FbtnJrnAll, FbtnJrnDel, FbtnJrnSort, FbtnJrnExport, FbtnJrnAI: TButton;
    { Pesquisa por data: lista "Linhas alteradas" e eventos da sessao. }
    FdeChgFrom, FdeChgTo, FdeJrnFrom, FdeJrnTo: TsDateEdit;
    FlblChgFrom, FlblChgTo, FlblJrnFrom, FlblJrnTo: TLabel;
    FbtnChgDateClr, FbtnJrnDateClr: TButton;
    FDateSyncing: Boolean;
    FChgDateQ, FJrnDateQ: THistDateQuery;
    FChgFiltered: Boolean;
    FpmHistSort: TPopupMenu;
    FSortMenuTarget: Integer;
    FbtnChgFirst, FbtnChgPrev, FbtnChgNext, FbtnChgLast: TButton;
    FlblChgPage: TLabel;
    FedtChgGoto: TEdit;
    FbtnChgGoto: TButton;
    { Janela propria das threads do indice: o Handle do form muda ao encaixar/desencaixar. }
    FChgWnd: HWND;
    FApplyingJournalView: Boolean;
    FApplyJournalViewPosted: Boolean;
    FJournalJumpPosted: Boolean;
    FPendingJournalJumpCp: Integer;
    FPendingJournalJumpLine: Integer;
    { Overlay temporario no preview: mostra o texto do journal na linha alvo (nao grava). }
    FHistOverlayActive: Boolean;
    FHistOverlayIdx: Integer;
    FHistOverlayTag: Integer;
    FHistOverlayText: string;
    { Delphi 7: nao usar forward class como tipo de campo; guardar como TThread. }
    FHistoryReloadThread: TThread;
    FHistReloadWasTmrSync: Boolean;
    FHistReloadDeferredFinish: Boolean;
    { Progresso do reload: worker escreve FHistReloadProgTarget; timer na main actualiza a overlay (ShowModal). }
    FHistReloadProgTarget: Integer;
    { Throttle PostMessage(WM_FF_HIST_PROGRESS_FLUSH): fila nao enche; timer 20ms reflecte o alvo. }
    FHistReloadProgLastFlushTick: Cardinal;
    FHistReloadProgLastPosted: Integer;
    FHistReloadUITimer: TTimer;
    { Worker thread do btnRunDiff (nao bloqueia a UI durante leitura + diff). }
    FDiffWorkerThread: TThread;
    FMergeThread: TMergeApplyThread;
    FMergeTarget: string;
    FMergeLv: TListView;
    FMergeMainHooked: Boolean;
    FMergeOps: TArray<TMaOp>;
    FMergeL2R: Boolean;
    { Reposicao da vista apos o novo diff assincrono que se segue a um merge. }
    FDiffRestoreTop: Integer;
    FDiffRestoreSel: Integer;
    FDiffRestoreLv: TListView;
    FDiffMergeOkMsg: Boolean;
    { Primeira linha (absoluta) do diff atual: LNum/RNum das linhas sao relativos a ela. }
    FDiffLo: Int64;
    FDiffProgTarget: Integer;
    FDiffProgLastFlushTick: Cardinal;
    FDiffProgLastPosted: Integer;
    { Ultimo LVM_GETTOPINDEX alinhado entre os dois paineis do diff. }
    FDiffSyncLastTopL: Integer;
    FDiffSyncLastTopR: Integer;
    { Ultimo painel que originou scroll (1=esq, 2=dir); timer reconcilia o par. }
    FDiffScrollLastSource: Integer;
    { True durante arrasto do thumb da barra vertical (evita timer a "piscar" o par). }
    FDiffThumbScroll: Boolean;
    FSyncingDiffScroll: Boolean;
    { Historico: sincronizar rolagem journal (memo) <-> preview (ListView); contagens diferentes => proporcional. }
    FSyncingHistScroll: Boolean;
    FOldMemoJournalWndProc: TWndMethod;
    FMemoJournalHooked: Boolean;
    FOldLvHistWndProc: TWndMethod;
    FOldLvLeftWndProc: TWndMethod;
    FOldLvRightWndProc: TWndMethod;
    { ListView que abriu o popLvHist (preview ou diff); resolvido em popLvHistPopup. }
    FPopupHistTargetLV: TListView;
    { Indice 0-based no lvHistFile apos clique no diario (-1 = nenhum realce extra). }
    FJournalPreviewHiliteIdx: Integer;
    { Linha (1-based) cujos eventos a lista mostra; 0 = todos / nenhuma. }
    FJrnViewLine: Integer;
    { True enquanto JournalJump faz scroll — ignora/desfaz selecao nativa do Win32. }
    FHistJumpIgnoreSel: Boolean;
    FHistClearSelTicks: Integer;
    FHistClearSelTimer: TTimer;
    { Preview: TDrawGrid sem celulas (texto vem de FHistPaged / FHistPreviewLines);
      aguenta centenas de milhoes de linhas sem RAM por linha. }
    FsgHist: TDrawGrid;
    { Preview paginado (indice esparso + cache LRU) do ficheiro inteiro. }
    FHistPaged: TFFPagedLineSource;
    FHistPagedTimer: TTimer;
    FHistPagedShownCount: Int64;
    { Barra "Exportar" por cor da legenda (abaixo do preview). }
    FHistExportBar: TsPanel;
    FHistExportLbl: TLabel;
    FHistExportKindBtns: array[0..4] of TsSpeedButton;
    FHistExportPrefixBtn: TsSpeedButton;
    FHistExportBtn: TsSpeedButton;
    FHistExportStatus: TLabel;
    FHistExportThread: TFFPagedExportThread;
    FHistExportTimer: TTimer;
    { Ultimo resultado (0 nenhum, 1 concluido, 2 cancelado, 3 falha) — refeito na troca de idioma. }
    FHistExportLastKind: Integer;
    FHistExportLastLines: Int64;
    FHistExportLastArg: string;
    FOldSgHistWndProc: TWndMethod;
    { Journal colorido (TStringGrid) — evita TRichEdit/RICHED20 + skin. }
    FsgJournal: TStringGrid;
    FJournalGridSelLine: Integer;
    FJournalMaxChars: Integer;
    { Legenda colorida do journal (PaintBox — TLabel.Color e' ignorado pelo skin). }
    FpbHistLegend: TPaintBox;
    { Preview do historico: linhas em FHistPreviewLines + itens reais no ListView. }
    FHistPreviewLines: TStringList;
    FHistLineKinds: array of Byte;
    { True quando o form esta embutido numa aba (nao modal). }
    FEmbeddedMode: Boolean;
    FOnEscapeEmbedded: TNotifyEvent;
    function HistPreviewLineTag(const AIndex: Integer): Integer;
    procedure PaintHistPreviewItem(Sender: TCustomListView; Item: TListItem);
    procedure EnsureHistPreviewItemText(const AIndex: Integer);
    procedure HistClearNativeSelection;
    procedure EnsureHistPreviewGrid;
    procedure EnsureJournalGrid;
    procedure UpdateJournalColWidth;
    procedure sgHistDrawCell(Sender: TObject; ACol, ARow: Longint;
      Rect: TRect; State: TGridDrawState);
    procedure sgHistMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgHistSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure sgJournalDrawCell(Sender: TObject; ACol, ARow: Longint;
      Rect: TRect; State: TGridDrawState);
    procedure sgJournalMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgJournalSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure sgJournalDblClick(Sender: TObject);
    procedure sgJournalKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ShowJournalLineDetail(ARow: Integer);
    procedure SgHistWndProc(var Message: TMessage);
    procedure StartHistPagedPreview(const APath: string);
    procedure StopHistPagedPreview;
    procedure HistPagedTimerTick(Sender: TObject);
    procedure UpdateHistPagedView;
    procedure EnsureHistExportBar;
    procedure LayoutHistExportBar;
    procedure ApplyHistExportCaptions;
    procedure UpdateHistExportGlyph(ABtn: TsSpeedButton; AColor: TColor);
    procedure HistExportKindClick(Sender: TObject);
    procedure HistExportClick(Sender: TObject);
    procedure HistExportTimerTick(Sender: TObject);
    procedure StopHistExport;
    function HistExportLastStatusText: string;
    function HistPreviewDataCount: Integer;
    procedure HistPreviewJumpToDataRow(const DataIdx: Integer);
    procedure ClearHistPreviewListView;
    procedure ApplyHistPreviewToListView(const APreview: TStringList;
      const ALineKinds: array of Byte; AClearOnly: Boolean);
    procedure LvDiffLeftWndProc(var Message: TMessage);
    procedure LvDiffRightWndProc(var Message: TMessage);
    procedure MemoJournalWndProc(var Message: TMessage);
    procedure HookMemoJournalWndProc;
    procedure UnhookMemoJournalWndProc;
    procedure UnhookAllSubclassedWndProcs;
    procedure LvHistWndProc(var Message: TMessage);
    procedure HistApplyMemoScrollToList;
    procedure HistApplyListScrollToMemo;
    procedure DiffApplyTopIndexToPeer(const Source: TListView);
    function ResolveHistPopupListView: TListView;
    function ResolveHistTargetListView: TListView;
    procedure SyncDiffScrollPeerFrom(const Source: TListView);
    procedure JournalSelectMemoFullLine(const LineIndex: Integer);
    function JournalDisplayLineCount: Integer;
    procedure ApplyMergeListViewColumnCaptions;
    procedure tmrHistReloadUITimer(Sender: TObject);
    procedure WMHistProgressFlush(var Msg: TMessage); message WM_FF_HIST_PROGRESS_FLUSH;
    procedure WMDiffProgressFlush(var Msg: TMessage); message WM_FF_DIFF_PROGRESS_FLUSH;
    procedure WMHistClearSel(var Msg: TMessage); message WM_FF_HIST_CLEAR_SEL;
    procedure WMApplyJournalView(var Msg: TMessage); message WM_FF_APPLY_JOURNAL_VIEW;
    procedure WMJournalJump(var Msg: TMessage); message WM_FF_JOURNAL_JUMP;
    procedure WMHistSourceMru(var Msg: TMessage); message WM_FF_HIST_SOURCE_MRU;
    procedure WMChgIndex(var Msg: TMessage); message WM_FF_CHG_INDEX;
    procedure WMChgEvents(var Msg: TMessage); message WM_FF_CHG_EVENTS;
    procedure StopChgThreads;
    procedure ChgWndProc(var Msg: TMessage);
    procedure ApplyChgPagerCaptions;
    function ChgPageCount: Integer;
    function ChgRecAt(AItem: Integer; out R: THciRec): Boolean;
    function ChgItemText(const R: THciRec): string;
    function ChgFormatWhen(const ATs: Int64): string;
    function ChgViewCount: Integer;
    function ChgViewIndex(AView: Integer): Integer;
    procedure HistSortMenuClick(Sender: TObject);
    procedure ShowHistSortMenu(ATarget: Integer; ABtn: TButton);
    procedure edtHistDateChange(Sender: TObject);
    procedure edtHistDateKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HistDateClearClick(Sender: TObject);
    function HistDateQueryOf(ADFrom, ADTo: TsDateEdit): THistDateQuery;
    procedure ApplyHistDateFilterHints;
    procedure CreateHistDateRow(AParent: TWinControl; out AFrom, ATo: TsDateEdit;
      out ALblFrom, ALblTo: TLabel; out AClr: TButton);
    function LayoutHistDateRow(AX, AY, AW, AH: Integer; ALblFrom, ALblTo: TLabel;
      AFrom, ATo: TsDateEdit; AClr: TButton): Integer;
    procedure RefreshChangedLinesView;
    function ChgSelectLine(ALine: Integer; ANearest: Boolean): Boolean;
    procedure ChgPagerClick(Sender: TObject);
    procedure ChgTryAutoSelectFirst;
    procedure ChgWheelScroll(WheelDelta: Integer);
    function ChgLinesText(AOnlyChecked: Boolean): string;
    procedure ChgCtxPopup(Sender: TObject);
    procedure ChgCtxClick(Sender: TObject);
    procedure ChgCtxSortClick(Sender: TObject);
    function JrnCellText(ARow: Integer): string;
    function JrnEventStart(ARow: Integer): Integer;
    function JrnEventText(ARow: Integer): string;
    function JrnAllEventsText: string;
    procedure JrnCtxPopup(Sender: TObject);
    procedure JrnCtxClick(Sender: TObject);
    procedure JrnCtxSortClick(Sender: TObject);
    procedure edtChgGotoKeyPress(Sender: TObject; var Key: Char);
    procedure btnChgGotoClick(Sender: TObject);
    procedure ChgGotoLine;
    procedure LayoutChgPager(AX, AY, AW: Integer);
    function ChgPagerHeight: Integer;
    procedure ChgRequestLineEvents(ALine: Integer);
    procedure tmrHistClearSelTimer(Sender: TObject);
    procedure WMTimer(var Msg: TMessage); message WM_TIMER;
    { = uI18n.WM_FF_LANGUAGE_CHANGED (uI18n is only in the implementation uses). }
    procedure WMFfLanguageChanged(var Msg: TMessage); message $8000 + $3A1;
    procedure ApplyUiLanguage;
    procedure FreeDiffRows;
    procedure LayoutDiffListViews;
    procedure LayoutDiffHeaderControls;
    procedure UpdateFastLargeFilesCaption;
    procedure LayoutHistoryTab;
    procedure FitToMonitorWorkArea;
    procedure HistPaneSplitterMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HistPaneSplitterMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure HistPaneSplitterMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ReloadHistoryMemo(AWithProgress: Boolean = True);
    procedure ReloadHistoryMemoEx(AWithProgress: Boolean; ADelayedTimerFinish: Boolean;
      ANoSmoothLoading: Boolean = False);
    procedure HistoryReloadThreadDone(Sender: TObject);
    procedure DiffWorkerThreadDone(Sender: TObject);
    procedure RunDiffSync;
    procedure LoadJournalIntoListBox(const JournalPath: string; AllowPump: Boolean);
    function TruncateJournalLine(const S: string; MaxLen: Integer): string;
    function ParseJournalPrimaryLine(const S: string): Integer;
    procedure BuildLegendLabels;
    procedure BuildHistoryJournalLegend;
    procedure EnsureHistLegendPaintBox;
    procedure pbHistLegendPaint(Sender: TObject);
      procedure BuildHistoryFilePreview(AllowPump: Boolean);
    procedure NoteMergeWroteDisk(const PathWritten: string);
    procedure TouchHistoryIfSameFile(const PathTouched: string);
    function BrushForKind(const K: TFFDiffKind): TColor;
    function BrushForHistTag(const Tag: Integer): TColor;
    procedure ApplyMergeUseLeftOnRight;
    procedure ApplyMergeUseRightOnLeft;
    procedure ApplyMergeDir(ALeftToRight: Boolean);
    procedure WMMergeApply(var Msg: TMessage);
    procedure StopMergeThread;
    procedure SetDiffBusyUi(ABusy: Boolean);
    function PatchDiffAfterMerge: Boolean;
    procedure NotifyMainAfterMerge(T: TMergeApplyThread);
    procedure JournalListEnterMutation(out ASavedOnClick: TNotifyEvent; out ASavedOnMouseUp: TMouseEvent);
    procedure JournalListLeaveMutation(const ASavedOnClick: TNotifyEvent; const ASavedOnMouseUp: TMouseEvent);
    procedure JournalMetaClear;
    procedure JournalMetaAdd(const ALine, ATag: Integer; const AExcerpt: string); overload;
    procedure JournalMetaAdd(const ALine, ALineEnd, ATag: Integer;
      const AExcerpt: string; const ARaw: string = ''); overload;
    procedure JournalCacheClear;
    procedure JournalCacheAdd(const AText: string; const ALine, ALineEnd, ATag: Integer;
      const AExcerpt: string; const ARaw: string = '');
    procedure ApplyJournalDisplayMode;
    procedure RequestApplyJournalDisplayMode;
    procedure RequestJournalJumpFromCp(const ACp: Integer);
    procedure RequestJournalJumpFromLine(const ALineIx: Integer);
    procedure ColorizeJournalRichText;
    procedure SetJournalSelBackColor(const AColor: TColor);
    procedure EnsureHistShowAllCheckBox;
    procedure EnsureChangedLinesList;
    procedure SyncChangedLinesFromJournalRow(ARow: Integer);
    procedure UpdateHistPreviewColWidths(ACw: Integer);
    function HistJournalFloating: Boolean;
    function HistPreviewFloating: Boolean;
    function HistTextW(const S: string): Integer;
    function HistBoxIsJournal(Sender: TObject): Boolean;
    function HistHostFor(AJournal: Boolean): TFastFileFloatForm;
    procedure EnsureHistDockBoxes;
    function SnapHistBox(ABox: TWinControl): THistCtlSnaps;
    procedure RestoreHistBox(const ASnaps: THistCtlSnaps);
    procedure FloatHistBox(AJournal, AFollowCursor: Boolean);
    procedure DockHistBox(AJournal: Boolean);
    procedure HistHostRequestDock(Sender: TObject);
    procedure UpdateHistDockZone(Sender: TObject);
    procedure HistBoxResize(Sender: TObject);
    procedure HistHdrMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HistHdrMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HistHdrMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HistHdrDblClick(Sender: TObject);
    procedure HistFloatBtnClick(Sender: TObject);
    procedure EnsureHistDockControls;
    procedure UpdateHistDockCaptions;
    procedure chkHistChangedListClick(Sender: TObject);
    procedure SetChangedListVisible(AVisible: Boolean);
    procedure btnChangedListToggleClick(Sender: TObject);
    procedure EnsureHistSourceMru;
    procedure LayoutHistSourceMru;
    procedure UpdateHistSourceEdit;
    procedure CollectHistorySourceFiles(AList: TStrings);
    procedure btnHistSourceMruClick(Sender: TObject);
    procedure edtHistSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HistSourceMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure HistSourceMruRemove(Sender: TObject; const APath: string);
    procedure HistSourceMruClearAll(Sender: TObject);
    procedure HistMruHide(const APaths: array of string);
    procedure btnChangedClearClick(Sender: TObject);
    procedure RebuildChangedLinesList;
    procedure lbChangedLinesClick(Sender: TObject);
    procedure lbChangedLinesDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbChangedLinesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChgToolClick(Sender: TObject);
    procedure JrnToolClick(Sender: TObject);
    procedure ApplyHistToolCaptions;
    procedure LayoutChgTools(AX, AY, AW: Integer);
    procedure LayoutJrnTools;
    procedure RebuildChgOrder;
    procedure ChgToggleAt(AItem: Integer);
    function ChgIsSel(const AKey: Int64): Boolean;
    function ChgSelectedCount: Integer;
    function ChgAllChecked: Boolean;
    procedure ChgSelectAllToggle;
    procedure ChgClearSelection;
    function HistKeepLine(const Line: string): Boolean;
    procedure RewriteJournal(const AConfirmMsg: string);
    procedure DeleteCheckedChangedLines;
    procedure DeleteCheckedJournalEvents;
    function HistIsAnonDropLine(const Line: string): Boolean;
    procedure DeleteAnonJournalEvents(ALine: Integer);
    function PickHistExportPath(out ACsv: Boolean): string;
    procedure ExportChangedLines;
    procedure ExportJournalEvents;
    function BuildJournalText(AForAi: Boolean): string;
    procedure AskAiAboutHistory(const AContext: string);
    function PromptHistAiGoal(out AGoal: string): Boolean;
    procedure SortJournalBlocks(Buf: TStringList);
    function JrnRawAt(ARow: Integer): string;
    function JrnHasEvents: Boolean;
    function JrnAllChecked: Boolean;
    procedure JrnToggleRow(ARow: Integer);
    procedure JrnSelectAllToggle;
    procedure ClearHistJournalOverlay;
    procedure PaintJournalOpGutter;
    procedure EnsureJournalLeftGutterMargin;
    function HistPreviewCellText(const DataIdx: Integer): string;
    procedure JournalJumpPreviewFromCp(const Cp: Integer);
    procedure JournalJumpPreviewFromLine(const LineIx: Integer);
    function WheelOverControl(ACtrl: TWinControl; const ScreenPt: TPoint): Boolean;
    procedure WheelScrollControl(ACtrl: TWinControl; WheelDelta: Integer);
  public
    property OnEscapeEmbedded: TNotifyEvent read FOnEscapeEmbedded write FOnEscapeEmbedded;
    class function ExecuteModal(AOwner: TComponent; const ADefaultLeftPath, AMainOpenPath: string): Boolean;
    class function ExecuteEmbedded(AOwner: TComponent; AHost: TWinControl;
      const ADefaultLeftPath, AMainOpenPath: string): TfrmCompareMerge;
    procedure ResetContext(const ADefaultLeftPath, AMainOpenPath: string);
    procedure NotifyExternalHistoryTouch(const PathTouched: string);
    { Roda (incl. Ctrl+roda) sobre o preview / journal / diff: desloca essa lista. }
    function TryScrollWheelAt(const ScreenPt: TPoint; WheelDelta: Integer): Boolean;
  end;

implementation

{$R *.dfm}

uses
  Math, ClipBrd, CommCtrl, sDateUtils,
  uI18n, uFileSessionHistory, uSmoothLoading, uLineEditor, UnConsts,
  StrUtils, uAnonymize, uDiskSpaceCheck, uTextEncoding, uFastFileMsgDlg, uUserPrefs,
  uFastFilePaths, uMruFind, UnitPopupMruList, uFastFileScale, uEolPolicy,
  uFastFileAssistant, uAssistantPipelineStore, uHistLineDetailDlg, uExportDoneDlg;

function SetWindowTheme(hwnd: HWND; pszSubAppName, pszSubIdList: PWideChar): HRESULT; stdcall;
  external 'uxtheme.dll' name 'SetWindowTheme';

const
  { Etiquetas dinamicas da legenda do diff (limpeza em BuildLegendLabels). }
  cFFDiffLegendLblTag = $5F4411;
  cFFHistLegendLblTag = $5F4412;
  cHistJournalLegendRowH = 20;
  { Mesma altura da barra de botoes sob a ListView do frmMain (FLvTools). }
  cHistExportBarH = 34;
  cChgCheckW = 18;
  cJrnCheckColW = 22;
  cHistAiMaxChars = 12000;
  { Botoes da barra Exportar -> tag da legenda (Editado tambem leva RPLALL = 4). }
  cHistExportBtnTag: array[0..4] of Byte = (2, 3, 1, 5, 0);

const
  FF_DIFF_MAX_LINES = 2500;
  { Janela extra para ressincronizar o diff por faixa quando ha insercoes/remocoes
    no inicio do intervalo, evitando falsos blocos de diferenca no final. }
  FF_DIFF_RANGE_LOOKAHEAD = 512;
  cOneMB = Int64(1024) * 1024;
  cOneGB = Int64(1024) * 1024 * 1024;
  { Threshold base quando os ficheiros ainda sao pequenos/medios. }
  cDiffForceRangeDefaultBytes = 32 * cOneMB;
  cHistPreviewMaxLines = 1200;
  { Limite de bytes ao procurar as primeiras N linhas do preview (evita ler ficheiros GB inteiros). }
  cHistPreviewMaxReadBytes = 64 * 1024 * 1024;
  { Linha sem LF/CR acima disto e' cortada (evita Cur gigante e O(n^2) por char). }
  cHistPreviewMaxLineChars = 256 * 1024;
  cHistJournalMaxLines = 5000;
  { Limite de linhas do journal no memo apos reload (equilibrio UX / custo UI). }
  cHistJournalThreadMaxLines = 600;
  cHistJournalDisplayChars = 320;
  cHistJournalDetailChars = 96;
  { Janela em disco para o memo e para o scan de cores: acima disto nunca se le o journal inteiro no Reload. }
  cHistJournalTailBytes = 4 * 1024 * 1024;
  { Limite para ScanSessionJournalStream no preview (alinhar com a cauda lida no memo). }
  cHistJournalMaxPreviewScanBytes = 4 * 1024 * 1024;
  cHistJournalStreamBuf = 65536;
  { ProcessMessages espacado na carga: UI responde sem reentrancia excessiva no skin. }
  cJournalProgressEveryLines = 8192;
  cTailWindowMaxLines = 12000;
  { Timer one-shot: deixa o ShowModal pintar antes da leitura pesada (evita "nao abre"). }
  cDeferHistTimerId = 9201;
  cDeferHistTimerMs = 15;
  { SyncApply em fatias: com overlay usa fatias moderadas; sem overlay nao bombeia a cada fatia (preview rapido). }
  cHistSyncApplyMemoChunkLines = 400;
  cHistSyncApplyListChunkItems = 400;
  { Barra: worker/pre-UI ate' cHistProgWorkerEnd; SyncApply consome cHistProgWorkerEnd+1 .. 99. }
  cHistProgWorkerEnd = 54;

procedure FFListViewSetExactTopIndex(ALV: TListView; TopIdx: Integer);
const
  LVM_SETTOPINDEX = LVM_FIRST + 67;
  LVM_SCROLL = LVM_FIRST + 20;
  LVIR_BOUNDS = 0;
var
  mx, cur, dy, rowH: Integer;
  r: TRect;
begin
  if (ALV = nil) or (not ALV.HandleAllocated) or (ALV.Items.Count < 1) then Exit;
  mx := ALV.Items.Count - 1;
  if TopIdx < 0 then TopIdx := 0;
  if TopIdx > mx then TopIdx := mx;
  
  SendMessage(ALV.Handle, LVM_SETTOPINDEX, TopIdx, 0);
  cur := Integer(SendMessage(ALV.Handle, LVM_GETTOPINDEX, 0, 0));
  if cur < 0 then cur := 0;
  if cur = TopIdx then Exit;
  
  FillChar(r, SizeOf(r), 0);
  r.Left := LVIR_BOUNDS;
  if LongBool(SendMessage(ALV.Handle, LVM_GETITEMRECT, 0, LPARAM(@r))) then
    rowH := Max(1, r.Bottom - r.Top)
  else
    rowH := 16;
    
  { Salto direto em pixels sem loop de SB_LINEDOWN (que causava o "giro" infinito) }
  dy := (TopIdx - cur) * rowH;
  SendMessage(ALV.Handle, LVM_SCROLL, 0, dy);
end;   

function FFGetFileSize64(const APath: string): Int64;
var
  SR: TSearchRec;
begin
  Result := -1;
  if (APath = '') or (FindFirst(APath, faAnyFile, SR) <> 0) then
    Exit;
  try
    Result := SR.Size;
  finally
    FindClose(SR);
  end;
end;

procedure FFHistPreviewBudget(const AFileSize: Int64; out AMaxLines: Integer;
  out AMaxReadBytes: Int64; out AMaxLineChars, AMaxDisplayChars: Integer);
begin
  if AFileSize >= 2 * cOneGB then
  begin
    AMaxLines := 120;
    AMaxReadBytes := 1 * cOneMB;
    AMaxLineChars := 8 * 1024;
    AMaxDisplayChars := 400;
  end
  else if AFileSize >= cOneGB then
  begin
    AMaxLines := 180;
    AMaxReadBytes := 2 * cOneMB;
    AMaxLineChars := 16 * 1024;
    AMaxDisplayChars := 600;
  end
  else if AFileSize >= 256 * cOneMB then
  begin
    AMaxLines := 350;
    AMaxReadBytes := 4 * cOneMB;
    AMaxLineChars := 32 * 1024;
    AMaxDisplayChars := 1000;
  end
  else if AFileSize >= 16 * cOneMB then
  begin
    AMaxLines := 600;
    AMaxReadBytes := 8 * cOneMB;
    AMaxLineChars := 64 * 1024;
    AMaxDisplayChars := 1500;
  end
  else
  begin
    AMaxLines := cHistPreviewMaxLines;
    AMaxReadBytes := cHistPreviewMaxReadBytes;
    AMaxLineChars := cHistPreviewMaxLineChars;
    AMaxDisplayChars := 2000;
  end;
end;

function FFComputeDynamicForceRangeBytes(const LPath, RPath: string): Int64;
var
  LSize, RSize, MaxSize: Int64;
begin
  LSize := FFGetFileSize64(LPath);
  RSize := FFGetFileSize64(RPath);
  MaxSize := LSize;
  if RSize > MaxSize then MaxSize := RSize;

  { Ajuste dinamico por escala: quanto maior o ficheiro, menor o limiar para
    forcar diff por faixa e evitar carga completa em memoria. }
  if MaxSize >= (20 * cOneGB) then
    Result := 1 * cOneMB
  else if MaxSize >= (10 * cOneGB) then
    Result := 2 * cOneMB
  else if MaxSize >= (4 * cOneGB) then
    Result := 4 * cOneMB
  else if MaxSize >= (1 * cOneGB) then
    Result := 8 * cOneMB
  else if MaxSize >= (256 * cOneMB) then
    Result := 16 * cOneMB
  else
    Result := cDiffForceRangeDefaultBytes;
end;

function FFShouldForceRangeDiff(const LPath, RPath: string; AAutoFastEnabled: Boolean;
  const AForceRangeBytes: Int64): Boolean;
const
  { Diff completo carrega os dois ficheiros em memoria: acima disto e' sempre por intervalo. }
  cHardRangeBytes = Int64(512) * 1024 * 1024;
var
  LSize, RSize: Int64;
begin
  LSize := FFGetFileSize64(LPath);
  RSize := FFGetFileSize64(RPath);
  if (LSize >= cHardRangeBytes) or (RSize >= cHardRangeBytes) then
    Exit(True);
  if not AAutoFastEnabled then
  begin
    Result := False;
    Exit;
  end;
  Result := ((LSize >= 0) and (LSize >= AForceRangeBytes)) or
            ((RSize >= 0) and (RSize >= AForceRangeBytes));
end;

procedure FFTrimDiffRowsToWindow(ADiff: TList; const AWindowLines: Int64);
var
  i: Integer;
  Rr: PFFDiffRow;
  KeepL, KeepR: Boolean;
begin
  if not Assigned(ADiff) then Exit;
  for i := ADiff.Count - 1 downto 0 do
  begin
    Rr := PFFDiffRow(ADiff[i]);
    KeepL := (Rr^.LNum > 0) and (Rr^.LNum <= AWindowLines);
    KeepR := (Rr^.RNum > 0) and (Rr^.RNum <= AWindowLines);
    if not (KeepL or KeepR) then
    begin
      Dispose(Rr);
      ADiff.Delete(i);
    end;
  end;
end;

type
  THistoryReloadThread = class(TThread)
  private
    FForm: TfrmCompareMerge;
    FJournalPath: string;
    FDataPath: string;
    FMemoLines: TStringList;
    FMemoRaws: TStringList;
    FPreviewSL: TStringList;
    FMemoLineNums: array of Integer;
    FMemoLineEnds: array of Integer;
    FMemoTags: array of Integer;
    FMemoExcerpts: TStringList;
    FLineKinds: array of Byte;
    FSkipJournalColors: Boolean;
    FClearListViewOnly: Boolean;
    FPreviewLimited: Boolean;
    FPreviewBudgetLines: Integer;
    FPreviewReadWindowMB: Integer;
    FShowLoadingUI: Boolean;
    FLoadingMsg: string;
    FProgressToSet: Integer;
    FLastProgressSynced: Integer;
    procedure SyncApply;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncPumpPostedProgress;
    procedure SetSmoothProgress(const Pct: Integer);
    procedure ReportTailStreamProgress(const BytesReadInTail, TailByteSpan: Int64);
    procedure ReportFilterKeepProgress(const Index, TotalLines: Integer);
    procedure ReportReadPreviewProgress(const FilePos, FileSize: Int64);
    procedure ReportScanJournalProgress(const FilePos, FileSize: Int64);
  protected
    procedure Execute; override;
  public
    constructor Create(AForm: TfrmCompareMerge; const AJPath, ADPath: string;
      AShowSmoothLoading: Boolean);
    destructor Destroy; override;
  end;

  { Background worker para btnRunDiff: executa leitura de ficheiros + FFBuildLineDiffRows
    numa thread separada, mantendo a UI responsiva durante o processamento. }
  TDiffWorkerThread = class(TThread)
  private
    FForm: TfrmCompareMerge;
    FLPath, FRPath: string;
    FLo, FHi: Int64;
    FByLines: Boolean;
    FAutoFastEnabled: Boolean;
    FForceRangeBytes: Int64;
    FResultRows: TList;
    FProgressToSet: Integer;
    FLastProgressSynced: Integer;
    procedure SyncApply;
    procedure SyncShowLoading;
    procedure SyncHideLoading;
    procedure SyncSetProgress;
    procedure SyncReEnableButton;
    procedure SetSmoothProgress(const Pct: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(AForm: TfrmCompareMerge; const ALPath, ARPath: string;
      ALo, AHi: Int64; AByLines: Boolean; AAutoFastEnabled: Boolean;
      AForceRangeBytes: Int64);
    destructor Destroy; override;
  end;

function FFRowCmpRNumDesc(Item1, Item2: Pointer): Integer;
var
  a, b: PFFDiffRow;
begin
  a := PFFDiffRow(Item1);
  b := PFFDiffRow(Item2);
  if a^.RNum > b^.RNum then Result := -1
  else if a^.RNum < b^.RNum then Result := 1
  else Result := 0;
end;

function FFRowCmpLNumDesc(Item1, Item2: Pointer): Integer;
var
  a, b: PFFDiffRow;
begin
  a := PFFDiffRow(Item1);
  b := PFFDiffRow(Item2);
  if a^.LNum > b^.LNum then Result := -1
  else if a^.LNum < b^.LNum then Result := 1
  else Result := 0;
end;

function FFRowCmpRNumAsc(Item1, Item2: Pointer): Integer;
var
  a, b: PFFDiffRow;
begin
  a := PFFDiffRow(Item1);
  b := PFFDiffRow(Item2);
  if a^.RNum < b^.RNum then Result := -1
  else if a^.RNum > b^.RNum then Result := 1
  else Result := 0;
end;

function FFRowCmpLNumAsc(Item1, Item2: Pointer): Integer;
var
  a, b: PFFDiffRow;
begin
  a := PFFDiffRow(Item1);
  b := PFFDiffRow(Item2);
  if a^.LNum < b^.LNum then Result := -1
  else if a^.LNum > b^.LNum then Result := 1
  else Result := 0;
end;

procedure SortDiffPtrList(AList: TList; Cmp: TListSortCompare);
var
  i, j: Integer;
  t: Pointer;
begin
  if not Assigned(AList) or (AList.Count < 2) then Exit;
  for i := 0 to AList.Count - 2 do
    for j := i + 1 to AList.Count - 1 do
      if Cmp(AList[i], AList[j]) > 0 then
      begin
        t := AList[i];
        AList[i] := AList[j];
        AList[j] := t;
      end;
end;

{ Main thread: ProcessMessages + pequena espera com mascara de input (cede quantum a outras apps). }
procedure HistPumpUIMessagesAndYield;
var
  hNull: THandle;
begin
  Application.ProcessMessages;
  while CheckSynchronize do;
  { Delphi 7: segundo parametro e' var (nao aceita nil com nCount=0). }
  hNull := 0;
  MsgWaitForMultipleObjects(0, hNull, False, 5, QS_ALLINPUT);
end;

{ Posicao do byte B em P[0..Len-1] ou -1 (SWAR: 8 bytes por iteracao). }
function FFFindByte(P: PByte; Len: NativeInt; B: Byte): NativeInt;
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
    W := PUInt64(PByte(NativeUInt(P) + NativeUInt(i)))^ xor Pat;
    if ((W - cLo) and (not W) and cHi) <> 0 then
      Break;
    Inc(i, 8);
  end;
  while i < Len do
  begin
    if PByte(NativeUInt(P) + NativeUInt(i))^ = B then
      Exit(i);
    Inc(i);
  end;
  Result := -1;
end;

{ Linhas AFirst1..ALast1 (1-based) para exibicao.
  Separa pelo mesmo byte terminador do resto da aplicacao (uEolPolicy), para que os numeros
  de linha coincidam com os usados pelo merge em disco. Linhas antes do intervalo sao saltadas
  sem alocacao; linhas longas sao truncadas so' na exibicao (sem desalinhar a numeracao). }
procedure ReadTextFileLineSlice(const AFileName: string; const AFirst1, ALast1: Int64;
  ADest: TStringList; AbortFlag: PBoolean; ProcessUIMessages: Boolean;
  ProgressWorker: THistoryReloadThread = nil; AMaxReadBytes: Int64 = 0;
  AMaxLineChars: Integer = 0; AMaxDisplayChars: Integer = 0);
const
  cReadBufSize = 4 * 1024 * 1024;
var
  F: TFileStream;
  Buf: TBytes;
  Got, k, lineStart, n: Integer;
  idx: NativeInt;
  CurLine: Int64;
  Cur, seg: AnsiString;
  BytesSinceProgress: Int64;
  Pct: Integer;
  Done: Boolean;
  maxRead: Int64;
  maxLineChars: Integer;
  Enc: string;
  BomSkip: Integer;
  FirstChunk: Boolean;
  Term: Byte;

  procedure AppendSeg(AStart, ALen: Integer);
  begin
    if ALen <= 0 then Exit;
    if Length(Cur) >= maxLineChars then Exit;
    if Length(Cur) + ALen > maxLineChars then
      ALen := maxLineChars - Length(Cur);
    { PAnsiChar + Length em bytes. PChar (Wide) reinterpretaria pares de bytes como CJK. }
    SetString(seg, PAnsiChar(@Buf[AStart]), ALen);
    Cur := Cur + seg;
  end;

  procedure FlushLine;
  var
    S: string;
  begin
    if (CurLine >= AFirst1) and (CurLine <= ALast1) then
    begin
      if (Term = 10) and (Cur <> '') and (Cur[Length(Cur)] = #13) then
        SetLength(Cur, Length(Cur) - 1);
      if Enc <> '' then
        S := DisplayTextFromFileBytes(Cur, Enc)
      else
        S := RawBytesToDisplayString(Cur);
      if (AMaxDisplayChars > 0) and (Length(S) > AMaxDisplayChars) then
        S := Copy(S, 1, AMaxDisplayChars);
      ADest.Add(S);
    end;
    Cur := '';
    Inc(CurLine);
    if CurLine > ALast1 then
      Done := True;
  end;

begin
  ADest.Clear;
  if not FileExists(AFileName) then Exit;

  maxRead := AMaxReadBytes;
  if maxRead <= 0 then maxRead := cHistPreviewMaxReadBytes;
  maxLineChars := AMaxLineChars;
  if maxLineChars <= 0 then maxLineChars := cHistPreviewMaxLineChars;

  Enc := DetectTextFileEncoding(AFileName);
  BomSkip := 0;
  if Pos('UTF-8 (BOM)', Enc) > 0 then
    BomSkip := 3
  else if (Pos('UTF-16 LE', Enc) > 0) or (Pos('UTF-16 BE', Enc) > 0) then
    BomSkip := 2;
  Term := Byte(LineTermCharForFile(AFileName));

  F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    if Assigned(ProgressWorker) and (F.Size > 0) then
    begin
      ProgressWorker.ReportReadPreviewProgress(0, F.Size);
      Sleep(0);
    end;
    SetLength(Buf, cReadBufSize);
    CurLine := 1;
    Cur := '';
    BytesSinceProgress := 0;
    Done := ALast1 < AFirst1;
    FirstChunk := True;
    while not Done do
    begin
      if Assigned(AbortFlag) and AbortFlag^ then Exit;
      if F.Position >= maxRead then
        Break;
      Got := F.Read(Buf[0], cReadBufSize);
      if Got <= 0 then Break;

      lineStart := 0;
      if FirstChunk then
      begin
        FirstChunk := False;
        if Got >= BomSkip then
          lineStart := BomSkip;
      end;

      Inc(BytesSinceProgress, Got);
      if BytesSinceProgress >= 16 * 1024 * 1024 then
      begin
        BytesSinceProgress := 0;
        if ProcessUIMessages then
        begin
          if F.Size > 0 then
          begin
            Pct := Min(99, Round((F.Position / F.Size) * 100));
            TfrmSmoothLoading.UpdateProgressWithDetail(Pct, IntToStr(CurLine));
          end;
          Application.ProcessMessages;
          if Assigned(AbortFlag) and AbortFlag^ then Exit;
        end
        else if Assigned(ProgressWorker) and (F.Size > 0) then
        begin
          ProgressWorker.ReportReadPreviewProgress(F.Position, F.Size);
          Sleep(0);
        end;
      end;

      k := lineStart;
      while k < Got do
      begin
        idx := FFFindByte(@Buf[k], Got - k, Term);
        if CurLine < AFirst1 then
        begin
          { Antes do intervalo: so' contar linhas. }
          if idx < 0 then Break;
          Inc(CurLine);
          Inc(k, Integer(idx) + 1);
          Continue;
        end;
        if idx < 0 then
        begin
          AppendSeg(k, Got - k);
          Break;
        end;
        n := Integer(idx);
        AppendSeg(k, n);
        FlushLine;
        if Done then Break;
        Inc(k, n + 1);
      end;

      if Assigned(ProgressWorker) then
        Sleep(0);
    end;

    { Ultima linha sem terminador. }
    if (not Done) and (Cur <> '') and (CurLine >= AFirst1) and (CurLine <= ALast1) then
      FlushLine;
    if Assigned(ProgressWorker) and (F.Size > 0) then
    begin
      ProgressWorker.ReportReadPreviewProgress(F.Size, F.Size);
      Sleep(0);
    end;
  finally
    F.Free;
  end;
end;

type
  TFFDiffRowGarbageCollector = class(TThread)
  private
    FList: TList;
  protected
    procedure Execute; override;
  public
    constructor Create(AList: TList);
  end;

constructor TFFDiffRowGarbageCollector.Create(AList: TList);
begin
  FList := AList;
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TFFDiffRowGarbageCollector.Execute;
var
  i: Integer;
begin
  if Assigned(FList) then
  begin
    for i := 0 to FList.Count - 1 do
      Dispose(PFFDiffRow(FList[i]));
    FList.Free;
  end;
end;

procedure TfrmCompareMerge.FreeDiffRows;
var
  i: Integer;
begin
  if not Assigned(FDiffRows) then Exit;
  for i := 0 to FDiffRows.Count - 1 do
    Dispose(PFFDiffRow(FDiffRows[i]));
  FDiffRows.Clear;
end;

function TfrmCompareMerge.BrushForKind(const K: TFFDiffKind): TColor;
begin
  case K of
    ffdkEqual: Result := RGB(230, 253, 230);
    ffdkChange: Result := RGB(230, 242, 255);
    ffdkDelete: Result := RGB(255, 230, 230);
    ffdkInsert: Result := RGB(255, 255, 230);
  else
    Result := clWindow;
  end;
end;

function TfrmCompareMerge.BrushForHistTag(const Tag: Integer): TColor;
begin
  { 0 equal, 1 EDT, 2 INS, 3 DEL, 4 RPLALL bulk, 5 UNDO/REDO note
    Cores um pouco mais saturadas para destacar no preview (nao parecer "tudo verde"). }
  case Tag of
    1: Result := RGB(140, 190, 255);  { EDT — azul mais forte }
    2: Result := RGB(255, 240, 140);  { INS }
    3: Result := RGB(255, 170, 170);  { DEL }
    4: Result := RGB(190, 190, 255);  { RPLALL }
    5: Result := RGB(220, 220, 220);  { UNDO/REDO }
  else
    Result := RGB(236, 248, 236);     { equal }
  end;
end;

const
  { Selection must not reuse any journal legend color (see BrushForHistTag). }
  cHistSelFill = clWhite;
  cHistSelInk = $00303030;
  cHistChangeBg = $0080FFFF;

procedure DrawHistCheckBox(C: TCanvas; const R: TRect; AChecked: Boolean;
  APartial: Boolean = False);
var
  B: TRect;
  Y0: Integer;
begin
  Y0 := R.Top + (R.Bottom - R.Top - 13) div 2;
  B := Rect(R.Left + 3, Y0, R.Left + 16, Y0 + 13);
  C.Brush.Color := clWhite;
  C.Brush.Style := bsSolid;
  C.Pen.Color := RGB(90, 90, 90);
  C.Pen.Width := 1;
  C.Rectangle(B);
  if AChecked then
  begin
    C.Pen.Color := RGB(20, 90, 20);
    C.Pen.Width := 2;
    C.MoveTo(B.Left + 2, B.Top + 6);
    C.LineTo(B.Left + 5, B.Top + 10);
    C.LineTo(B.Left + 11, B.Top + 3);
    C.Pen.Width := 1;
  end
  else if APartial then
  begin
    C.Brush.Color := RGB(20, 90, 20);
    C.FillRect(Rect(B.Left + 3, B.Top + 3, B.Right - 3, B.Bottom - 3));
    C.Brush.Color := clWhite;
  end;
end;

procedure DrawHistSelectionMarker(C: TCanvas; const R: TRect);
var
  Bar: TRect;
begin
  C.Brush.Style := bsClear;
  C.Pen.Color := cHistSelInk;
  C.Pen.Width := 2;
  C.Rectangle(R.Left + 1, R.Top + 1, R.Right, R.Bottom);
  C.Pen.Width := 1;
  Bar := R;
  Bar.Right := Bar.Left + 4;
  C.Brush.Style := bsSolid;
  C.Brush.Color := cHistSelInk;
  C.FillRect(Bar);
end;

var
  GHistChangedListVisible: Boolean = True;

procedure TfrmCompareMerge.LayoutHistoryTab;
begin
  TabSheetHistoryResize(TabSheetHistory);
end;

procedure TfrmCompareMerge.FitToMonitorWorkArea;
var
  M: TMonitor;
  WorkArea: TRect;
  WorkWidth, WorkHeight: Integer;
begin
  if FEmbeddedMode or not HandleAllocated then Exit;
  M := Screen.MonitorFromWindow(Handle, mdNearest);
  if not Assigned(M) then Exit;
  WorkArea := M.WorkareaRect;

  WorkWidth := WorkArea.Right - WorkArea.Left;
  WorkHeight := WorkArea.Bottom - WorkArea.Top;
  if Width > WorkWidth then Width := WorkWidth;
  if Height > WorkHeight then Height := WorkHeight;
  if Left < WorkArea.Left then Left := WorkArea.Left;
  if Top < WorkArea.Top then Top := WorkArea.Top;
  if Left + Width > WorkArea.Right then
    Left := WorkArea.Right - Width;
  if Top + Height > WorkArea.Bottom then
    Top := WorkArea.Bottom - Height;
end;

procedure TfrmCompareMerge.HistPaneSplitterMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
begin
  if Button <> mbLeft then Exit;
  GetCursorPos(Pt);
  FHistSplitStartY := Pt.Y;
  FHistSplitStartH := FHistPaneSplitter.Top - (lblJournalHint.Top +
    lblJournalHint.Height + 4 + cHistJournalLegendRowH);
  SetCapture(FHistPaneSplitter.Handle);
end;

procedure TfrmCompareMerge.HistPaneSplitterMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
  hAvail, hHint, hLegend, paneAvail, hJournal: Integer;
begin
  if GetCapture <> FHistPaneSplitter.Handle then Exit;
  GetCursorPos(Pt);
  hAvail := TabSheetHistory.ClientHeight - lblJournalHint.Top - 8 - cHistExportBarH;
  hHint := lblJournalHint.Height + 4;
  hLegend := cHistJournalLegendRowH;
  paneAvail := hAvail - hHint - hLegend - 22 - cHistPaneSplitterH;
  if paneAvail <= 0 then Exit;
  hJournal := FHistSplitStartH + Pt.Y - FHistSplitStartY;
  if paneAvail >= 2 * cHistPaneMinH then
  begin
    if hJournal < cHistPaneMinH then hJournal := cHistPaneMinH;
    if hJournal > paneAvail - cHistPaneMinH then
      hJournal := paneAvail - cHistPaneMinH;
  end
  else
    hJournal := paneAvail div 2;
  FHistJournalRatio := hJournal * 100 div paneAvail;
  FHistSplitterUserMoved := True;
  TabSheetHistoryResize(TabSheetHistory);
end;

procedure TfrmCompareMerge.HistPaneSplitterMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if GetCapture = FHistPaneSplitter.Handle then
    ReleaseCapture;
end;

procedure TfrmCompareMerge.TabSheetHistoryResize(Sender: TObject);
var
  topBase, hAvail, hHint, hLegend, hJournal, hLv, paneAvail, desiredJournalH,
    cw, y, yP, wList, xJ: Integer;
  listVis, jDocked, pDocked, topArea: Boolean;
begin
  if not Assigned(TabSheetHistory) or not Assigned(mmoJournal) then Exit;
  cw := TabSheetHistory.ClientWidth - 16;
  topBase := lblJournalHint.Top;
  hAvail := TabSheetHistory.ClientHeight - topBase - 8 - cHistExportBarH;
  if hAvail < 120 then Exit;
  EnsureJournalGrid;
  EnsureChangedLinesList;
  EnsureHistPreviewGrid;
  EnsureHistDockBoxes;
  listVis := GHistChangedListVisible and Assigned(FlbChangedLines);
  jDocked := not HistJournalFloating;
  pDocked := not HistPreviewFloating;
  topArea := listVis or jDocked;
  hHint := lblJournalHint.Height + 4;
  hLegend := cHistJournalLegendRowH;
  wList := Min(300, Max(236, cw div 4));
  if not jDocked then
    wList := cw;
  if listVis then
    LayoutChgTools(8, 0, wList);
  if topArea and pDocked then
  begin
    paneAvail := hAvail - hHint - hLegend - 22 - cHistPaneSplitterH;
    if not FHistSplitterUserMoved then
    begin
      if listVis then
        desiredJournalH := 16 + FChgToolsH + ChgPagerHeight +
          3 * FlbChangedLines.ItemHeight + 4
      else
        desiredJournalH := paneAvail div 2;
      if paneAvail >= 2 * cHistPaneMinH then
      begin
        if desiredJournalH < cHistPaneMinH then
          desiredJournalH := cHistPaneMinH;
        if desiredJournalH > paneAvail - cHistPaneMinH then
          desiredJournalH := paneAvail - cHistPaneMinH;
      end
      else
        desiredJournalH := paneAvail div 2;
      hJournal := desiredJournalH;
      if paneAvail > 0 then
        FHistJournalRatio := hJournal * 100 div paneAvail;
    end
    else
    begin
      if FHistJournalRatio <= 0 then FHistJournalRatio := 50;
      hJournal := paneAvail * FHistJournalRatio div 100;
    end;
    if paneAvail >= 2 * cHistPaneMinH then
    begin
      if hJournal < cHistPaneMinH then hJournal := cHistPaneMinH;
      if hJournal > paneAvail - cHistPaneMinH then
        hJournal := paneAvail - cHistPaneMinH;
    end
    else
      hJournal := paneAvail div 2;
    hLv := paneAvail - hJournal;
  end
  else if topArea then
  begin
    hJournal := Max(64, hAvail - hHint - hLegend + cHistExportBarH);
    hLv := 0;
  end
  else
  begin
    hJournal := 0;
    hLv := Max(64, hAvail - hHint - hLegend - 16);
  end;
  lblJournalHint.SetBounds(8, topBase, cw, lblJournalHint.Height);
  LayoutHistSourceMru;
  y := topBase + hHint + hLegend;
  if Assigned(FlbChangedLines) then
  begin
    FlblChangedLines.Visible := listVis;
    FlbChangedLines.Visible := listVis;
    if listVis then
    begin
      FlblChangedLines.SetBounds(8, y, wList - 44, 16);
      LayoutChgTools(8, y + 16, wList);
      FlbChangedLines.SetBounds(8, y + 16 + FChgToolsH, wList,
        Max(32, hJournal - 16 - FChgToolsH - ChgPagerHeight));
      LayoutChgPager(8, FlbChangedLines.Top + FlbChangedLines.Height + 2, wList);
    end
    else
    begin
      LayoutChgTools(0, 0, 0);
      LayoutChgPager(0, 0, 0);
    end;
  end;
  if Assigned(FbtnChangedCollapse) then
  begin
    FbtnChangedCollapse.Visible := listVis;
    if listVis then
      FbtnChangedCollapse.SetBounds(8 + wList - 20, y - 1, 20, 17);
  end;
  if Assigned(FbtnChangedClear) then
  begin
    FbtnChangedClear.Visible := listVis;
    if listVis then
      FbtnChangedClear.SetBounds(8 + wList - 42, y - 1, 20, 17);
  end;
  if Assigned(FbtnChangedExpand) then
  begin
    FbtnChangedExpand.Visible := (not listVis) and jDocked;
    if FbtnChangedExpand.Visible then
      FbtnChangedExpand.SetBounds(8, y, 16, Max(32, hJournal));
  end;
  if Assigned(FHistPaneSplitter) then
  begin
    FHistPaneSplitter.Visible := topArea and pDocked;
    if FHistPaneSplitter.Visible then
      FHistPaneSplitter.SetBounds(8, y + hJournal, cw, cHistPaneSplitterH);
  end;
  if listVis then
    xJ := 8 + wList + 6
  else if Assigned(FbtnChangedExpand) and FbtnChangedExpand.Visible then
    xJ := 8 + 16 + 4
  else
    xJ := 8;
  if Assigned(FpnlJournalBox) and jDocked then
  begin
    FpnlJournalBox.SetBounds(xJ, y, cw - (xJ - 8), hJournal);
    HistBoxResize(FpnlJournalBox);
  end;
  if Assigned(mmoJournal) then
  begin
    mmoJournal.Visible := False;
    mmoJournal.SetBounds(xJ, y, Max(32, cw - (xJ - 8)), Max(32, hJournal));
  end;
  if topArea then
    yP := y + hJournal + 4
  else
    yP := y;
  if topArea and pDocked then
    Inc(yP, cHistPaneSplitterH);
  if Assigned(FpnlPreviewBox) and pDocked then
    FpnlPreviewBox.SetBounds(8, yP, cw, hLv + 16 + cHistExportBarH);
  if Assigned(FpnlPreviewBox) then
    HistBoxResize(FpnlPreviewBox);
  if Assigned(lvHistFile) then
    lvHistFile.Visible := False;
  BuildHistoryJournalLegend;
end;

procedure TfrmCompareMerge.UpdateHistPreviewColWidths(ACw: Integer);
begin
  if not Assigned(FsgHist) then Exit;
  FsgHist.ColWidths[0] := Max(56, FsgHist.Canvas.TextWidth(IntToStr(Max(1, HistPreviewDataCount))) + 16);
  FsgHist.ColWidths[1] := Max(200, ACw - FsgHist.ColWidths[0] - 12 - GetSystemMetrics(SM_CXVSCROLL));
end;

function TfrmCompareMerge.HistJournalFloating: Boolean;
begin
  Result := Assigned(FHistJournalHost) and Assigned(FpnlJournalBox) and
    (FpnlJournalBox.Parent = FHistJournalHost);
end;

function TfrmCompareMerge.HistPreviewFloating: Boolean;
begin
  Result := Assigned(FHistPreviewHost) and Assigned(FpnlPreviewBox) and
    (FpnlPreviewBox.Parent = FHistPreviewHost);
end;

function TfrmCompareMerge.HistTextW(const S: string): Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Font);
    Result := Bmp.Canvas.TextWidth(StringReplace(S, '&', '', [rfReplaceAll]));
  finally
    Bmp.Free;
  end;
end;

function TfrmCompareMerge.HistBoxIsJournal(Sender: TObject): Boolean;
begin
  Result := (Sender = FpnlJournalHdr) or (Sender = FlblJournalHdr) or
    (Sender = FbtnJournalFloat) or (Sender = FpnlJournalBox) or
    (Sender = FHistJournalHost);
end;

function TfrmCompareMerge.HistHostFor(AJournal: Boolean): TFastFileFloatForm;
var
  OwnerForm: TCustomForm;
begin
  if AJournal then
    Result := FHistJournalHost
  else
    Result := FHistPreviewHost;
  if Assigned(Result) then Exit;
  OwnerForm := GetParentForm(Self);
  if not Assigned(OwnerForm) then
    OwnerForm := Application.MainForm;
  if AJournal then
    Result := TFastFileFloatForm.CreateHost(OwnerForm, TrText('Hist.DockEventsTitle'))
  else
    Result := TFastFileFloatForm.CreateHost(OwnerForm, lblHistPreview.Caption);
  Result.OnRequestDock := HistHostRequestDock;
  Result.OnUpdateDockZone := UpdateHistDockZone;
  Result.Constraints.MinWidth := FfPx(360);
  Result.Constraints.MinHeight := FfPx(160);
  if AJournal then
    FHistJournalHost := Result
  else
    FHistPreviewHost := Result;
end;

procedure TfrmCompareMerge.EnsureHistDockBoxes;
var
  Btn: TButton;

  function NewBox: TPanel;
  begin
    Result := TPanel.Create(Self);
    Result.Parent := TabSheetHistory;
    Result.BevelOuter := bvNone;
    Result.Caption := '';
    Result.ParentBackground := False;
    Result.Color := clBtnFace;
    Result.OnResize := HistBoxResize;
  end;

  function NewHdr(ABox: TPanel): TPanel;
  begin
    Result := TPanel.Create(Self);
    Result.Parent := ABox;
    Result.Align := alTop;
    Result.Height := 18;
    Result.BevelOuter := bvNone;
    Result.Caption := '';
    Result.ParentBackground := False;
    Result.Color := $00EDE6DE;
    Result.Cursor := crSizeAll;
    Result.ShowHint := True;
    Result.OnMouseDown := HistHdrMouseDown;
    Result.OnMouseMove := HistHdrMouseMove;
    Result.OnMouseUp := HistHdrMouseUp;
    Result.OnDblClick := HistHdrDblClick;
  end;

  function NewFloatBtn(AHdr: TPanel): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := AHdr;
    Result.Align := alRight;
    Result.Width := 22;
    Result.Caption := #$2197;
    Result.ShowHint := True;
    Result.OnClick := HistFloatBtnClick;
  end;

  procedure HookLabel(ALbl: TLabel);
  begin
    ALbl.Cursor := crSizeAll;
    ALbl.ShowHint := True;
    ALbl.OnMouseDown := HistHdrMouseDown;
    ALbl.OnMouseMove := HistHdrMouseMove;
    ALbl.OnMouseUp := HistHdrMouseUp;
    ALbl.OnDblClick := HistHdrDblClick;
  end;

begin
  if Assigned(FpnlJournalBox) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  EnsureJournalGrid;
  EnsureHistPreviewGrid;
  EnsureHistExportBar;
  if not Assigned(FsgJournal) or not Assigned(FsgHist) then Exit;

  FHistPaneSplitter := TPanel.Create(Self);
  FHistPaneSplitter.Parent := TabSheetHistory;
  FHistPaneSplitter.Caption := '';
  FHistPaneSplitter.BevelOuter := bvLowered;
  FHistPaneSplitter.ParentBackground := False;
  FHistPaneSplitter.Color := clBtnFace;
  FHistPaneSplitter.Cursor := crVSplit;
  FHistPaneSplitter.ShowHint := True;
  FHistPaneSplitter.OnMouseDown := HistPaneSplitterMouseDown;
  FHistPaneSplitter.OnMouseMove := HistPaneSplitterMouseMove;
  FHistPaneSplitter.OnMouseUp := HistPaneSplitterMouseUp;

  FpnlJournalBox := NewBox;
  FpnlJournalHdr := NewHdr(FpnlJournalBox);
  FlblJournalHdr := TLabel.Create(Self);
  FlblJournalHdr.Parent := FpnlJournalHdr;
  FlblJournalHdr.Font.Style := [fsBold];
  FlblJournalHdr.SetBounds(4, 2, 300, 14);
  HookLabel(FlblJournalHdr);
  FbtnJournalFloat := NewFloatBtn(FpnlJournalHdr);
  if not Assigned(FpnJrnTools) then
  begin
    FpnJrnTools := TPanel.Create(Self);
    FpnJrnTools.Parent := FpnlJournalBox;
    FpnJrnTools.Align := alTop;
    FpnJrnTools.Height := 26;
    FpnJrnTools.BevelOuter := bvNone;
    FpnJrnTools.Caption := '';
    FpnJrnTools.ParentBackground := False;
    FpnJrnTools.Color := clBtnFace;
    FbtnJrnAll := TButton.Create(Self);
    FbtnJrnDel := TButton.Create(Self);
    FbtnJrnSort := TButton.Create(Self);
    FbtnJrnExport := TButton.Create(Self);
    FbtnJrnAI := TButton.Create(Self);
    FbtnJrnAll.Tag := 1;
    FbtnJrnDel.Tag := 2;
    FbtnJrnSort.Tag := 3;
    FbtnJrnExport.Tag := 4;
    FbtnJrnAI.Tag := 5;
    for Btn in TArray<TButton>.Create(FbtnJrnAll, FbtnJrnDel, FbtnJrnSort, FbtnJrnExport, FbtnJrnAI) do
    begin
      Btn.Parent := FpnJrnTools;
      Btn.OnClick := JrnToolClick;
      Btn.ShowHint := True;
      Btn.ParentFont := False;
      if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
        Btn.Font.Name := 'Segoe UI'
      else
        Btn.Font.Name := 'Tahoma';
      Btn.Font.Size := 8;
    end;
    CreateHistDateRow(FpnJrnTools, FdeJrnFrom, FdeJrnTo, FlblJrnFrom, FlblJrnTo,
      FbtnJrnDateClr);
    FJrnDateQ := HistDateQueryOf(FdeJrnFrom, FdeJrnTo);
    FpnlJournalHdr.Top := 0;
    FpnJrnTools.Top := FpnlJournalHdr.Height;
  end;
  FsgJournal.Anchors := [akLeft, akTop];
  ReparentAligned(FsgJournal, FpnlJournalBox, alClient);

  FpnlPreviewBox := NewBox;
  FpnlPreviewHdr := NewHdr(FpnlPreviewBox);
  lblHistPreview.Parent := FpnlPreviewHdr;
  lblHistPreview.SetBounds(4, 2, lblHistPreview.Width, lblHistPreview.Height);
  lblHistPreview.Visible := True;
  HookLabel(lblHistPreview);
  FbtnPreviewFloat := NewFloatBtn(FpnlPreviewHdr);
  if Assigned(FHistExportBar) then
  begin
    FHistExportBar.Anchors := [akLeft, akTop];
    ReparentAligned(FHistExportBar, FpnlPreviewBox, alBottom);
    FHistExportBar.Height := cHistExportBarH;
  end;
  FsgHist.Anchors := [akLeft, akTop];
  ReparentAligned(FsgHist, FpnlPreviewBox, alClient);
  UpdateHistDockCaptions;
end;

procedure TfrmCompareMerge.HistBoxResize(Sender: TObject);
begin
  if Sender = FpnlJournalBox then
  begin
    LayoutJrnTools;
    UpdateJournalColWidth;
  end
  else if Sender = FpnlPreviewBox then
  begin
    LayoutHistExportBar;
    UpdateHistPreviewColWidths(FpnlPreviewBox.ClientWidth);
  end;
end;

const
  { Linha separadora entre eventos no diario (altura reduzida, sem meta). }
  cHistSpacerRow = #3;
  cHistSpacerRowH = 7;

type
  THistCtlAccess = class(TControl);
  THistGridAccess = class(TCustomGrid);

{ SetParent chama ScaleForPPI com o DPI do form de destino; o host flutuante e o
  form embutido nem sempre concordam, e fontes/alturas cresciam a cada ida e volta. }
function TfrmCompareMerge.SnapHistBox(ABox: TWinControl): THistCtlSnaps;
var
  n: Integer;

  procedure Walk(C: TControl);
  var
    i: Integer;
  begin
    if n >= Length(Result) then
      SetLength(Result, Max(32, n * 2));
    Result[n].Ctl := C;
    Result[n].FontH := THistCtlAccess(C).Font.Height;
    Result[n].H := C.Height;
    Result[n].Bounds := C.BoundsRect;
    if C is TCustomGrid then
      Result[n].RowH := THistGridAccess(C).DefaultRowHeight
    else
      Result[n].RowH := 0;
    Inc(n);
    if C is TWinControl then
      for i := 0 to TWinControl(C).ControlCount - 1 do
        Walk(TWinControl(C).Controls[i]);
  end;

var
  i: Integer;
begin
  n := 0;
  SetLength(Result, 0);
  if not Assigned(ABox) then Exit;
  for i := 0 to ABox.ControlCount - 1 do
    Walk(ABox.Controls[i]);
  SetLength(Result, n);
end;

procedure TfrmCompareMerge.RestoreHistBox(const ASnaps: THistCtlSnaps);
var
  i, r: Integer;
  C: TControl;
begin
  for i := 0 to High(ASnaps) do
  begin
    C := ASnaps[i].Ctl;
    if not THistCtlAccess(C).ParentFont and
       (THistCtlAccess(C).Font.Height <> ASnaps[i].FontH) then
      THistCtlAccess(C).Font.Height := ASnaps[i].FontH;
    if C.Align in [alTop, alBottom] then
    begin
      if C.Height <> ASnaps[i].H then
        C.Height := ASnaps[i].H;
    end
    else if C.Align = alNone then
      C.BoundsRect := ASnaps[i].Bounds;
    if (ASnaps[i].RowH > 0) and (C is TCustomGrid) and
       (THistGridAccess(C).DefaultRowHeight <> ASnaps[i].RowH) then
      THistGridAccess(C).DefaultRowHeight := ASnaps[i].RowH;
  end;
  if Assigned(FsgJournal) and (FsgJournal.ColCount > 1) then
    for r := 0 to FsgJournal.RowCount - 1 do
      if FsgJournal.Cells[1, r] = cHistSpacerRow then
      begin
        if FsgJournal.RowHeights[r] <> cHistSpacerRowH then
          FsgJournal.RowHeights[r] := cHistSpacerRowH;
      end
      else if FsgJournal.RowHeights[r] <> FsgJournal.DefaultRowHeight then
        FsgJournal.RowHeights[r] := FsgJournal.DefaultRowHeight;
end;

procedure TfrmCompareMerge.FloatHistBox(AJournal, AFollowCursor: Boolean);
var
  Box: TPanel;
  Host: TFastFileFloatForm;
  P: TPoint;
  W, H: Integer;
begin
  if FClosing then Exit;
  EnsureHistDockBoxes;
  if AJournal then
    Box := FpnlJournalBox
  else
    Box := FpnlPreviewBox;
  if not Assigned(Box) then Exit;
  if (AJournal and HistJournalFloating) or ((not AJournal) and HistPreviewFloating) then Exit;
  Host := HistHostFor(AJournal);
  W := Max(FfPx(480), Box.Width);
  H := Max(FfPx(260), Box.Height + FfPx(40));
  if Box.HandleAllocated and Box.Showing then
    P := Box.ClientToScreen(Point(0, 0))
  else
    P := Point(Screen.WorkAreaLeft + 80, Screen.WorkAreaTop + 80);
  if AJournal then
    FJournalSnap := SnapHistBox(Box)
  else
    FPreviewSnap := SnapHistBox(Box);
  ReparentAligned(Box, Host, alClient);
  if AJournal then
    RestoreHistBox(FJournalSnap)
  else
    RestoreHistBox(FPreviewSnap);
  if AFollowCursor then
    Host.PlaceUnderCursor(W, H)
  else
    Host.ApplySavedBounds(P.X + 24, P.Y + 24, W, H);
  UpdateHistDockZone(Host);
  Host.Show;
  Host.BringToFront;
  UpdateHistDockCaptions;
  TabSheetHistoryResize(TabSheetHistory);
  if AFollowCursor then
  begin
    Host.MarkJustTornOff;
    Host.BeginCaptionFollow;
  end;
end;

procedure TfrmCompareMerge.DockHistBox(AJournal: Boolean);
var
  Box: TPanel;
  Host: TFastFileFloatForm;
begin
  if AJournal then
  begin
    if not HistJournalFloating then Exit;
    Box := FpnlJournalBox;
    Host := FHistJournalHost;
  end
  else
  begin
    if not HistPreviewFloating then Exit;
    Box := FpnlPreviewBox;
    Host := FHistPreviewHost;
  end;
  Box.Align := alNone;
  Box.Parent := TabSheetHistory;
  Box.Visible := True;
  if AJournal then
    RestoreHistBox(FJournalSnap)
  else
    RestoreHistBox(FPreviewSnap);
  if Assigned(Host) and Host.Visible then
    Host.Hide;
  if FClosing then Exit;
  UpdateHistDockCaptions;
  TabSheetHistoryResize(TabSheetHistory);
end;

procedure TfrmCompareMerge.HistHostRequestDock(Sender: TObject);
begin
  DockHistBox(Sender = FHistJournalHost);
end;

procedure TfrmCompareMerge.UpdateHistDockZone(Sender: TObject);
var
  yTop, yBot, yMid, cw: Integer;
  P1, P2: TPoint;
  Host: TFastFileFloatForm;
begin
  if not (Sender is TFastFileFloatForm) then Exit;
  Host := TFastFileFloatForm(Sender);
  if not Assigned(TabSheetHistory) or not TabSheetHistory.Showing then
  begin
    Host.SetDockZone(Rect(0, 0, 0, 0));
    Exit;
  end;
  { Slot de origem: metade de cima (eventos) ou de baixo (pre-visualizacao) do tab. }
  cw := TabSheetHistory.ClientWidth - 16;
  yTop := lblJournalHint.Top + lblJournalHint.Height + 4 + cHistJournalLegendRowH;
  yBot := TabSheetHistory.ClientHeight - 4;
  yMid := (yTop + yBot) div 2;
  if Sender = FHistJournalHost then
  begin
    P1 := TabSheetHistory.ClientToScreen(Point(8, yTop));
    P2 := TabSheetHistory.ClientToScreen(Point(8 + cw, yMid));
  end
  else
  begin
    P1 := TabSheetHistory.ClientToScreen(Point(8, yMid));
    P2 := TabSheetHistory.ClientToScreen(Point(8 + cw, yBot));
  end;
  Host.SetDockZone(Rect(P1.X, P1.Y, P2.X, P2.Y));
  Host.SetMainMagnet(Rect(0, 0, 0, 0));
end;

procedure TfrmCompareMerge.HistHdrMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHistHdrDown := True;
  FHistHdrPt := Point(X, Y);
  if Sender is TControl then
    SetCaptureControl(TControl(Sender));
end;

procedure TfrmCompareMerge.HistHdrMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  IsJ: Boolean;
  Host: TFastFileFloatForm;
begin
  if not FHistHdrDown then Exit;
  if (Abs(X - FHistHdrPt.X) < FASTFILE_TEAR_THRESHOLD) and
     (Abs(Y - FHistHdrPt.Y) < FASTFILE_TEAR_THRESHOLD) then
    Exit;
  FHistHdrDown := False;
  SetCaptureControl(nil);
  IsJ := HistBoxIsJournal(Sender);
  if (IsJ and HistJournalFloating) or ((not IsJ) and HistPreviewFloating) then
  begin
    if IsJ then Host := FHistJournalHost else Host := FHistPreviewHost;
    UpdateHistDockZone(Host);
    Host.BeginCaptionFollowNow;
  end
  else
    FloatHistBox(IsJ, True);
end;

procedure TfrmCompareMerge.HistHdrMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FHistHdrDown := False;
  SetCaptureControl(nil);
end;

procedure TfrmCompareMerge.HistHdrDblClick(Sender: TObject);
var
  IsJ: Boolean;
begin
  IsJ := HistBoxIsJournal(Sender);
  if IsJ and HistJournalFloating then
    DockHistBox(True)
  else if IsJ then
    SetChangedListVisible(not GHistChangedListVisible)
  else if (not IsJ) and HistPreviewFloating then
    DockHistBox(False);
end;

procedure TfrmCompareMerge.HistFloatBtnClick(Sender: TObject);
var
  IsJ: Boolean;
begin
  IsJ := HistBoxIsJournal(Sender);
  if IsJ then
  begin
    if HistJournalFloating then DockHistBox(True) else FloatHistBox(True, False);
  end
  else
  begin
    if HistPreviewFloating then DockHistBox(False) else FloatHistBox(False, False);
  end;
end;

procedure TfrmCompareMerge.EnsureHistDockControls;
begin
  if Assigned(FchkHistChangedList) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FchkHistChangedList := TCheckBox.Create(Self);
  FchkHistChangedList.Parent := TabSheetHistory;
  FchkHistChangedList.Name := 'chkHistChangedList';
  FchkHistChangedList.Checked := GHistChangedListVisible;
  FchkHistChangedList.OnClick := chkHistChangedListClick;
  FchkHistChangedList.ShowHint := True;
  FbtnChangedCollapse := TButton.Create(Self);
  FbtnChangedCollapse.Parent := TabSheetHistory;
  FbtnChangedCollapse.Name := 'btnChangedCollapse';
  FbtnChangedCollapse.Caption := #$00AB;
  FbtnChangedCollapse.OnClick := btnChangedListToggleClick;
  FbtnChangedCollapse.ShowHint := True;
  FbtnChangedClear := TButton.Create(Self);
  FbtnChangedClear.Parent := TabSheetHistory;
  FbtnChangedClear.Name := 'btnChangedClear';
  FbtnChangedClear.Font.Name := 'Segoe UI Symbol';
  FbtnChangedClear.Caption := #$D83D#$DDD1;
  FbtnChangedClear.OnClick := btnChangedClearClick;
  FbtnChangedClear.ShowHint := True;
  FbtnChangedExpand := TButton.Create(Self);
  FbtnChangedExpand.Parent := TabSheetHistory;
  FbtnChangedExpand.Name := 'btnChangedExpand';
  FbtnChangedExpand.Caption := #$00BB;
  FbtnChangedExpand.OnClick := btnChangedListToggleClick;
  FbtnChangedExpand.ShowHint := True;
  FbtnChangedExpand.Visible := False;
  UpdateHistDockCaptions;
end;

procedure TfrmCompareMerge.UpdateHistDockCaptions;
begin
  if not Assigned(FchkHistChangedList) then Exit;
  FchkHistChangedList.Caption := TrText('Hist.ShowChangedLines');
  FchkHistChangedList.Hint := TrText('Hist.ShowChangedLinesHint');
  if Assigned(FbtnChangedCollapse) then
    FbtnChangedCollapse.Hint := TrText('Hist.HideChangedLines');
  if Assigned(FbtnChangedClear) then
    FbtnChangedClear.Hint := TrText('Hist.ClearChangedHint');
  if Assigned(FlblChangedLines) then
    FlblChangedLines.Hint := TrText('Hist.ChangedLinesHint') + #13#10 +
      TrText('Hist.ChangedWhenHint') + #13#10 +
      TrText('Hist.CheckHint') + #13#10 +
      TrText('Hist.DblClickToggleList');
  if Assigned(FlbChangedLines) then
    FlbChangedLines.Hint := TrText('Hist.ChangedLinesHint') + #13#10 +
      TrText('Hist.ChangedWhenHint') + #13#10 + TrText('Hist.CheckHint');
  ApplyHistToolCaptions;
  if Assigned(FbtnChangedExpand) then
    FbtnChangedExpand.Hint := TrText('Hist.ShowChangedLinesBtn');
  ApplyChgPagerCaptions;
  if Assigned(FpnlJournalHdr) then
  begin
    FlblJournalHdr.Caption := TrText('Hist.DockEventsTitle');
    if HistJournalFloating then
    begin
      FbtnJournalFloat.Caption := #$2199;
      FbtnJournalFloat.Hint := TrText('Panel.DockHint');
      FpnlJournalHdr.Hint := TrText('Panel.DragDockHint');
    end
    else
    begin
      FbtnJournalFloat.Caption := #$2197;
      FbtnJournalFloat.Hint := TrText('Panel.RestoreFloatHint');
      FpnlJournalHdr.Hint := TrText('Panel.DragUndockHint') + #13#10 +
        TrText('Hist.DblClickToggleList');
    end;
    FlblJournalHdr.Hint := FpnlJournalHdr.Hint;
  end;
  if Assigned(FpnlPreviewHdr) then
  begin
    if HistPreviewFloating then
    begin
      FbtnPreviewFloat.Caption := #$2199;
      FbtnPreviewFloat.Hint := TrText('Panel.DockHint');
      FpnlPreviewHdr.Hint := TrText('Panel.DragDockHint');
    end
    else
    begin
      FbtnPreviewFloat.Caption := #$2197;
      FbtnPreviewFloat.Hint := TrText('Panel.RestoreFloatHint');
      FpnlPreviewHdr.Hint := TrText('Panel.DragUndockHint');
    end;
    lblHistPreview.Hint := FpnlPreviewHdr.Hint;
  end;
  if Assigned(FHistJournalHost) then
    FHistJournalHost.Caption := TrText('Hist.DockEventsTitle');
  if Assigned(FHistPreviewHost) and Assigned(lblHistPreview) then
    FHistPreviewHost.Caption := lblHistPreview.Caption;
  LayoutHistSourceMru;
end;

procedure TfrmCompareMerge.chkHistChangedListClick(Sender: TObject);
begin
  if not Assigned(FchkHistChangedList) then Exit;
  SetChangedListVisible(FchkHistChangedList.Checked);
end;

procedure TfrmCompareMerge.SetChangedListVisible(AVisible: Boolean);
begin
  if Assigned(FchkHistChangedList) and (FchkHistChangedList.Checked <> AVisible) then
    FchkHistChangedList.Checked := AVisible;
  if GHistChangedListVisible = AVisible then Exit;
  GHistChangedListVisible := AVisible;
  TabSheetHistoryResize(TabSheetHistory);
end;

procedure TfrmCompareMerge.btnChangedListToggleClick(Sender: TObject);
begin
  SetChangedListVisible(not GHistChangedListVisible);
end;

procedure HistSplitPipeFields(const S: string; Parts: TStringList);
var
  p: Integer;
  rest, one: string;
begin
  Parts.Clear;
  rest := S;
  while rest <> '' do
  begin
    { SysUtils.Pos — fiavel em Unicode (PosBMH usa Byte(WideChar) no ramo multi-char). }
    p := Pos('|', rest);
    if p = 0 then
    begin
      Parts.Add(rest);
      Break;
    end;
    one := Copy(rest, 1, p - 1);
    Parts.Add(one);
    Delete(rest, 1, p);
  end;
end;

function HistTruncateJournalLine(const S: string; const MaxLen: Integer): string;
begin
  Result := S;
  if Length(Result) > MaxLen then
    Result := Copy(Result, 1, MaxLen) + '...';
end;

{ Preserve Unicode journal text while removing control characters. }
function HistSanitizeText(const S: string): string;
var
  i, C, N: Integer;
begin
  SetLength(Result, Length(S));
  N := 0;
  for i := 1 to Length(S) do
  begin
    C := Ord(S[i]);
    if (C >= 32) and not ((C >= $7F) and (C <= $9F)) then
    begin
      Inc(N);
      Result[N] := S[i];
    end;
  end;
  SetLength(Result, N);
  Result := Trim(Result);
end;

function HistSanitizeJournalExcerpt(const S: string; const MaxLen: Integer): string;
var
  T: string;
begin
  T := HistSanitizeText(S);
  if T = '' then
  begin
    Result := TrText('(text unavailable)');
    Exit;
  end;
  Result := HistTruncateJournalLine(T, MaxLen);
end;

{ Resume old→new: divergencia, tamanho e final — bloco multilinha para o journal. }
function HistClipChangeFrag(const S: string; const HeadN, TailN: Integer): string;
begin
  if Length(S) <= HeadN + TailN + 3 then
    Result := S
  else
    Result := Copy(S, 1, HeadN) + '...' + Copy(S, Length(S) - TailN + 1, TailN);
end;

procedure HistDescribeEditParts(const AOldRaw, ANewRaw: string;
  out APos: Integer; out AOldFrag, ANewFrag, ALenNote, AEndsNote, AKindNote: string);
var
  AOld, ANew: string;
  Lo, HiOld, HiNew, DLen, HeadN, TailN: Integer;
begin
  APos := 0;
  AOldFrag := '';
  ANewFrag := '';
  ALenNote := '';
  AEndsNote := '';
  AKindNote := '';

  AOld := HistSanitizeText(AOldRaw);
  ANew := HistSanitizeText(ANewRaw);
  if (AOld = '') and (ANew = '') then
  begin
    AKindNote := TrText('(text unavailable)');
    Exit;
  end;
  if AOld = '' then
  begin
    AKindNote := 'INS';
    ANewFrag := HistClipChangeFrag(ANew, 40, 40);
    ALenNote := Format(TrText('Hist.LenDeltaPlus: size %d -> %d (+%d)'),
      [0, Length(ANew), Length(ANew)]);
    Exit;
  end;
  if ANew = '' then
  begin
    AKindNote := 'DEL';
    AOldFrag := HistClipChangeFrag(AOld, 40, 40);
    ALenNote := Format(TrText('Hist.LenDeltaMinus: size %d -> %d (%d)'),
      [Length(AOld), 0, -Length(AOld)]);
    Exit;
  end;
  if AOld = ANew then
  begin
    AKindNote := 'SAME';
    ANewFrag := HistClipChangeFrag(ANew, 40, 40);
    ALenNote := Format(TrText('Hist.LenSame: size %d'), [Length(AOld)]);
    Exit;
  end;

  if (Length(ANew) > Length(AOld)) and (Copy(ANew, 1, Length(AOld)) = AOld) then
  begin
    AKindNote := 'APPEND';
    APos := Length(AOld) + 1;
    ANewFrag := HistClipChangeFrag(Copy(ANew, Length(AOld) + 1, MaxInt), 40, 40);
    ALenNote := Format(TrText('Hist.LenDeltaPlus: size %d -> %d (+%d)'),
      [Length(AOld), Length(ANew), Length(ANew) - Length(AOld)]);
    AEndsNote := Format(TrText('Hist.LineEnds: end "%s" -> "%s"'),
      [HistClipChangeFrag(Copy(AOld, Max(1, Length(AOld) - 23), MaxInt), 12, 12),
       HistClipChangeFrag(Copy(ANew, Max(1, Length(ANew) - 23), MaxInt), 12, 12)]);
    Exit;
  end;

  if (Length(AOld) > Length(ANew)) and (Copy(AOld, 1, Length(ANew)) = ANew) then
  begin
    AKindNote := 'TRIM';
    APos := Length(ANew) + 1;
    AOldFrag := HistClipChangeFrag(Copy(AOld, Length(ANew) + 1, MaxInt), 40, 40);
    ALenNote := Format(TrText('Hist.LenDeltaMinus: size %d -> %d (%d)'),
      [Length(AOld), Length(ANew), Length(ANew) - Length(AOld)]);
    AEndsNote := Format(TrText('Hist.LineEnds: end "%s" -> "%s"'),
      [HistClipChangeFrag(Copy(AOld, Max(1, Length(AOld) - 23), MaxInt), 12, 12),
       HistClipChangeFrag(Copy(ANew, Max(1, Length(ANew) - 23), MaxInt), 12, 12)]);
    Exit;
  end;

  Lo := 0;
  while (Lo < Length(AOld)) and (Lo < Length(ANew)) and
        (AOld[Lo + 1] = ANew[Lo + 1]) do
    Inc(Lo);
  HiOld := Length(AOld);
  HiNew := Length(ANew);
  while (HiOld > Lo) and (HiNew > Lo) and (AOld[HiOld] = ANew[HiNew]) do
  begin
    Dec(HiOld);
    Dec(HiNew);
  end;

  HeadN := 36;
  TailN := 24;
  APos := Lo + 1;
  AOldFrag := HistClipChangeFrag(Copy(AOld, Lo + 1, HiOld - Lo), HeadN, TailN);
  ANewFrag := HistClipChangeFrag(Copy(ANew, Lo + 1, HiNew - Lo), HeadN, TailN);
  if AOldFrag = '' then
    AOldFrag := TrText('(empty)');
  if ANewFrag = '' then
    ANewFrag := TrText('(empty)');
  AKindNote := 'EDIT';

  DLen := Length(ANew) - Length(AOld);
  if DLen > 0 then
    ALenNote := Format(TrText('Hist.LenDeltaPlus: size %d -> %d (+%d)'),
      [Length(AOld), Length(ANew), DLen])
  else if DLen < 0 then
    ALenNote := Format(TrText('Hist.LenDeltaMinus: size %d -> %d (%d)'),
      [Length(AOld), Length(ANew), DLen])
  else
    ALenNote := Format(TrText('Hist.LenSame: size %d'), [Length(AOld)]);

  if DLen <> 0 then
    AEndsNote := Format(TrText('Hist.LineEnds: end "%s" -> "%s"'),
      [HistClipChangeFrag(Copy(AOld, Max(1, Length(AOld) - 23), MaxInt), 12, 12),
       HistClipChangeFrag(Copy(ANew, Max(1, Length(ANew) - 23), MaxInt), 12, 12)]);
end;

const
  { Corte fixo das entradas gravadas antes de existir a preferencia HistoryLineExcerptMax. }
  cHistJournalLegacyExcerptMax = 1200;
  { Delimitam o trecho alterado nas linhas completas; sgJournalDrawCell destaca-o. }
  cHistMarkOn = #1;
  cHistMarkOff = #2;

  { Trechos iguais mais curtos que isto entre duas diferencas sao absorvidos (evita
    realce "picotado" caractere a caractere). }
  cHistDiffMergeGap = 3;
  { Alinhamento por maior substring comum so ate' este produto de tamanhos (custo O(n*m)). }
  cHistDiffLcsMaxCells = 4000000;
  cHistDiffMinAnchor = 4;
  cHistDiffMaxDepth = 12;

type
  THistDiffRun = record
    Start0, Len: Integer;
  end;
  THistDiffRuns = array of THistDiffRun;

procedure HistAddRun(var Runs: THistDiffRuns; AStart0, ALen: Integer);
var
  n: Integer;
begin
  n := Length(Runs);
  if (n > 0) and (ALen > 0) and (Runs[n - 1].Len > 0) and
     (AStart0 - (Runs[n - 1].Start0 + Runs[n - 1].Len) < cHistDiffMergeGap) then
  begin
    Runs[n - 1].Len := AStart0 + ALen - Runs[n - 1].Start0;
    Exit;
  end;
  SetLength(Runs, n + 1);
  Runs[n].Start0 := AStart0;
  Runs[n].Len := ALen;
end;

procedure HistLongestCommonSubstring(const A, B: string; out APos0, BPos0, ALen: Integer);
var
  Prev, Cur, Tmp: array of Integer;
  i, j, m, n: Integer;
begin
  APos0 := 0;
  BPos0 := 0;
  ALen := 0;
  m := Length(A);
  n := Length(B);
  SetLength(Prev, n + 1);
  SetLength(Cur, n + 1);
  for i := 1 to m do
  begin
    Cur[0] := 0;
    for j := 1 to n do
      if A[i] = B[j] then
      begin
        Cur[j] := Prev[j - 1] + 1;
        if Cur[j] > ALen then
        begin
          ALen := Cur[j];
          APos0 := i - ALen;
          BPos0 := j - ALen;
        end;
      end
      else
        Cur[j] := 0;
    Tmp := Prev;
    Prev := Cur;
    Cur := Tmp;
  end;
end;

procedure HistDiffSpans(const AOld, ANew: string; AOldOff, ANewOff, ADepth: Integer;
  var OldRuns, NewRuns: THistDiffRuns);
var
  Lo, HiO, HiN, i, RunStart, pA, pB, L: Integer;
  mO, mN: string;
begin
  Lo := 0;
  while (Lo < Length(AOld)) and (Lo < Length(ANew)) and (AOld[Lo + 1] = ANew[Lo + 1]) do
    Inc(Lo);
  HiO := Length(AOld);
  HiN := Length(ANew);
  while (HiO > Lo) and (HiN > Lo) and (AOld[HiO] = ANew[HiN]) do
  begin
    Dec(HiO);
    Dec(HiN);
  end;
  if (HiO = Lo) and (HiN = Lo) then Exit;
  mO := Copy(AOld, Lo + 1, HiO - Lo);
  mN := Copy(ANew, Lo + 1, HiN - Lo);
  if (mO = '') or (mN = '') then
  begin
    HistAddRun(OldRuns, AOldOff + Lo, Length(mO));
    HistAddRun(NewRuns, ANewOff + Lo, Length(mN));
    Exit;
  end;
  if Length(mO) = Length(mN) then
  begin
    RunStart := -1;
    for i := 1 to Length(mO) + 1 do
      if (i <= Length(mO)) and (mO[i] <> mN[i]) then
      begin
        if RunStart < 0 then RunStart := i - 1;
      end
      else if RunStart >= 0 then
      begin
        HistAddRun(OldRuns, AOldOff + Lo + RunStart, i - 1 - RunStart);
        HistAddRun(NewRuns, ANewOff + Lo + RunStart, i - 1 - RunStart);
        RunStart := -1;
      end;
    Exit;
  end;
  if (ADepth < cHistDiffMaxDepth) and
     (Int64(Length(mO)) * Length(mN) <= cHistDiffLcsMaxCells) then
  begin
    HistLongestCommonSubstring(mO, mN, pA, pB, L);
    if L >= cHistDiffMinAnchor then
    begin
      HistDiffSpans(Copy(mO, 1, pA), Copy(mN, 1, pB), AOldOff + Lo, ANewOff + Lo,
        ADepth + 1, OldRuns, NewRuns);
      HistDiffSpans(Copy(mO, pA + L + 1, MaxInt), Copy(mN, pB + L + 1, MaxInt),
        AOldOff + Lo + pA + L, ANewOff + Lo + pB + L, ADepth + 1, OldRuns, NewRuns);
      Exit;
    end;
  end;
  HistAddRun(OldRuns, AOldOff + Lo, Length(mO));
  HistAddRun(NewRuns, ANewOff + Lo, Length(mN));
end;

function HistMarkRuns(const S: string; const Runs: THistDiffRuns): string;
var
  i, Pos0, Start0, End0: Integer;
begin
  Result := '';
  Pos0 := 0;
  for i := 0 to High(Runs) do
  begin
    Start0 := Runs[i].Start0;
    End0 := Start0 + Runs[i].Len;
    if (Start0 > 0) and (Start0 < Length(S)) and
       (Ord(S[Start0]) >= $D800) and (Ord(S[Start0]) <= $DBFF) and
       (Ord(S[Start0 + 1]) >= $DC00) and (Ord(S[Start0 + 1]) <= $DFFF) then
      Dec(Start0);
    if (End0 > 0) and (End0 < Length(S)) and
       (Ord(S[End0]) >= $D800) and (Ord(S[End0]) <= $DBFF) and
       (Ord(S[End0 + 1]) >= $DC00) and (Ord(S[End0 + 1]) <= $DFFF) then
      Inc(End0);
    if Start0 < Pos0 then
      Start0 := Pos0;
    if End0 <= Start0 then Continue;
    Result := Result + Copy(S, Pos0 + 1, Start0 - Pos0) + cHistMarkOn +
      Copy(S, Start0 + 1, End0 - Start0) + cHistMarkOff;
    Pos0 := End0;
  end;
  Result := Result + Copy(S, Pos0 + 1, MaxInt);
end;

procedure HistMarkChangedFragments(var AOldFrag, ANewFrag: string);
var
  OldRuns, NewRuns: THistDiffRuns;
begin
  SetLength(OldRuns, 0);
  SetLength(NewRuns, 0);
  HistDiffSpans(AOldFrag, ANewFrag, 0, 0, 0, OldRuns, NewRuns);
  AOldFrag := HistMarkRuns(AOldFrag, OldRuns);
  ANewFrag := HistMarkRuns(ANewFrag, NewRuns);
end;

procedure HistAddFullLineRows(const AOldRaw, ANewRaw: string; OutLines: TStrings);
var
  AOld, ANew: string;
  RawMax: Integer;
  OldRuns, NewRuns: THistDiffRuns;
begin
  AOld := HistSanitizeText(AOldRaw);
  ANew := HistSanitizeText(ANewRaw);
  if (AOld = '') and (ANew = '') then Exit;
  if (AOld = '') or (ANew = '') or (AOld = ANew) then
  begin
    if AOld = '' then
      OutLines.Add('  ' + Format(TrText('Hist.Detail.FullLine: %s'), [ANew]))
    else
      OutLines.Add('  ' + Format(TrText('Hist.Detail.FullLine: %s'), [AOld]));
  end
  else
  begin
    SetLength(OldRuns, 0);
    SetLength(NewRuns, 0);
    HistDiffSpans(AOld, ANew, 0, 0, 0, OldRuns, NewRuns);
    OutLines.Add('  ' + Format(TrText('Hist.Detail.FullBefore: %s'),
      [HistMarkRuns(AOld, OldRuns)]));
    OutLines.Add('  ' + Format(TrText('Hist.Detail.FullAfter: %s'),
      [HistMarkRuns(ANew, NewRuns)]));
  end;
  RawMax := Max(Length(AOldRaw), Length(ANewRaw));
  if (RawMax = cHistJournalLegacyExcerptMax) or (RawMax >= PrefHistoryLineExcerptMax) then
    OutLines.Add('  ' + Format(TrText('Hist.Detail.ExcerptLimit: %d'), [RawMax]));
end;

function HistEditChangeSummary(const AOldRaw, ANewRaw: string): string;
var
  PosN: Integer;
  OldFrag, NewFrag, LenNote, EndsNote, KindNote: string;
begin
  HistDescribeEditParts(AOldRaw, ANewRaw, PosN, OldFrag, NewFrag, LenNote, EndsNote, KindNote);
  if KindNote = 'INS' then
  begin
    Result := Format(TrText('Hist.InsertedText: %s'), [NewFrag]);
    Exit;
  end;
  if KindNote = 'DEL' then
  begin
    Result := Format(TrText('Hist.DeletedText: %s'), [OldFrag]);
    Exit;
  end;
  if KindNote = 'SAME' then
  begin
    Result := NewFrag;
    Exit;
  end;
  if KindNote = 'APPEND' then
  begin
    Result := Format(TrText('Hist.AppendedAtEnd: +%d chars: "%s"'),
      [Length(HistSanitizeText(ANewRaw)) - Length(HistSanitizeText(AOldRaw)), NewFrag]);
    if EndsNote <> '' then
      Result := Result + ' | ' + EndsNote;
    Exit;
  end;
  if KindNote = 'TRIM' then
  begin
    Result := Format(TrText('Hist.RemovedFromEnd: -%d chars: "%s"'),
      [Length(HistSanitizeText(AOldRaw)) - Length(HistSanitizeText(ANewRaw)), OldFrag]);
    if EndsNote <> '' then
      Result := Result + ' | ' + EndsNote;
    Exit;
  end;
  Result := Format(TrText('Hist.ChangedAt: at %d: "%s" -> "%s"'),
    [PosN, OldFrag, NewFrag]);
  if LenNote <> '' then
    Result := Result + ' | ' + LenNote;
  if EndsNote <> '' then
    Result := Result + ' | ' + EndsNote;
end;

procedure FormatHistJournalLinesForDisplay(const S: string; OutLines: TStrings);
var
  Parts: TStringList;
  op, ts, oldEx, newEx: string;
  cnt, L, PosN: Integer;
  OldFrag, NewFrag, LenNote, EndsNote, KindNote, Head: string;
begin
  OutLines.Clear;
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(S, Parts);
    if Parts.Count < 3 then
    begin
      OutLines.Add(HistSanitizeJournalExcerpt(S, cHistJournalDisplayChars));
      Exit;
    end;
    ts := HistSanitizeText(Parts[0]);
    op := UpperCase(HistSanitizeText(Parts[1]));

    if op = 'BINS' then
    begin
      L := StrToIntDef(Trim(Parts[2]), 0);
      cnt := StrToIntDef(Trim(Parts[3]), 1);
      OutLines.Add(Format(TrText('Batch insert: %d line(s) at line %d'), [cnt, L]));
      Exit;
    end;
    if op = 'BAUT' then
    begin
      L := StrToIntDef(Trim(Parts[2]), 0);
      cnt := StrToIntDef(Trim(Parts[3]), 1);
      OutLines.Add(Format(TrText('Line autofill: %d blank line(s) at line %d'), [cnt, L]));
      Exit;
    end;
    if op = 'BDEL' then
    begin
      L := StrToIntDef(Trim(Parts[2]), 0);
      cnt := StrToIntDef(Trim(Parts[3]), 1);
      OutLines.Add(Format(TrText('Batch delete: %d line(s) at line %d'), [cnt, L]));
      Exit;
    end;
    if op = 'MDLT' then
    begin
      L := StrToIntDef(Trim(Parts[2]), 0);
      cnt := StrToIntDef(Trim(Parts[3]), 1);
      OutLines.Add(Format(TrText('Merge lines (delta): %d line(s) from line %d'), [cnt, L]));
      Exit;
    end;
    if op = 'ANON' then
    begin
      L := StrToIntDef(Trim(Parts[2]), 0);
      cnt := 0;
      if Parts.Count >= 4 then
        cnt := StrToIntDef(Trim(Parts[3]), 0);
      if L <= 0 then
        OutLines.Add(ts + '  [ANON]  ' + HistSanitizeJournalExcerpt(Parts[2], 160))
      else if cnt <= 0 then
        OutLines.Add(TrText('Anon.Hist.WholeFile'))
      else
        OutLines.Add(Format(TrText('Anon.Hist.Lines'), [cnt, L]));
      OutLines.Add('  ' + TrText('Anon.Hist.NoDetail'));
      Exit;
    end;
    if op = 'MRGF' then
    begin
      if Parts.Count >= 4 then
        OutLines.Add(Format(TrText('Merge files: %s — %s'),
          [HistSanitizeJournalExcerpt(Parts[2], 80),
           HistSanitizeJournalExcerpt(Parts[3], 80)]))
      else
        OutLines.Add(TrText('Merge files'));
      Exit;
    end;
    if (op = 'UNDO') or (op = 'REDO') then
    begin
      if Parts.Count >= 3 then
        OutLines.Add(op + ': ' + HistSanitizeJournalExcerpt(Parts[2], 160))
      else
        OutLines.Add(op);
      Exit;
    end;
    if op = 'RPLALL' then
    begin
      if Parts.Count >= 5 then
        OutLines.Add(Format('%s  [RPLALL]  %s -> %s',
          [ts, HistSanitizeJournalExcerpt(Parts[3], 40),
           HistSanitizeJournalExcerpt(Parts[4], 40)]))
      else
        OutLines.Add(ts + '  [RPLALL]');
      Exit;
    end;

    if (op = 'EDT') or (op = 'INS') or (op = 'DEL') or (op = 'ANOL') then
    begin
      L := StrToIntDef(HistSanitizeText(Parts[2]), 0);
      oldEx := '';
      newEx := '';
      if Parts.Count >= 4 then
        oldEx := Parts[3];
      if Parts.Count >= 5 then
        newEx := Parts[4];
      HistDescribeEditParts(oldEx, newEx, PosN, OldFrag, NewFrag, LenNote, EndsNote, KindNote);
      if op = 'ANOL' then
        Head := Format(TrText('Hist.EventHead: %s  [%s]  line %d'), [ts, TrText('Anon.Hist.Tag'), L])
      else
        Head := Format(TrText('Hist.EventHead: %s  [%s]  line %d'), [ts, op, L]);
      OutLines.Add(Head);
      if KindNote = 'APPEND' then
      begin
        OutLines.Add('  ' + Format(TrText('Hist.Detail.Appended: %s'), [NewFrag]));
        if LenNote <> '' then
          OutLines.Add('  ' + LenNote);
        if EndsNote <> '' then
          OutLines.Add('  ' + EndsNote);
      end
      else if KindNote = 'TRIM' then
      begin
        OutLines.Add('  ' + Format(TrText('Hist.Detail.Removed: %s'), [OldFrag]));
        if LenNote <> '' then
          OutLines.Add('  ' + LenNote);
        if EndsNote <> '' then
          OutLines.Add('  ' + EndsNote);
      end
      else if KindNote = 'INS' then
        OutLines.Add('  ' + Format(TrText('Hist.Detail.Inserted: %s'), [NewFrag]))
      else if KindNote = 'DEL' then
        OutLines.Add('  ' + Format(TrText('Hist.Detail.Deleted: %s'), [OldFrag]))
      else if KindNote = 'SAME' then
        OutLines.Add('  ' + NewFrag)
      else
      begin
        if KindNote = 'EDIT' then
          HistMarkChangedFragments(OldFrag, NewFrag);
        if PosN > 0 then
          OutLines.Add('  ' + Format(TrText('Hist.Detail.AtPos: %d'), [PosN]));
        OutLines.Add('  ' + Format(TrText('Hist.Detail.Before: %s'), [OldFrag]));
        OutLines.Add('  ' + Format(TrText('Hist.Detail.After: %s'), [NewFrag]));
        if LenNote <> '' then
          OutLines.Add('  ' + LenNote);
        if EndsNote <> '' then
          OutLines.Add('  ' + EndsNote);
      end;
      HistAddFullLineRows(oldEx, newEx, OutLines);
      Exit;
    end;

    OutLines.Add(Format('%s  [%s]  %s', [ts, op, HistSanitizeJournalExcerpt(
      Copy(S, Pos('|', S) + 1, MaxInt), 160)]));
  finally
    Parts.Free;
  end;
end;

function FormatHistJournalLineForDisplay(const S: string): string;
var
  SL: TStringList;
  i: Integer;
begin
  SL := TStringList.Create;
  try
    FormatHistJournalLinesForDisplay(S, SL);
    if SL.Count = 0 then
      Result := ''
    else if SL.Count = 1 then
      Result := SL[0]
    else
    begin
      Result := SL[0];
      for i := 1 to SL.Count - 1 do
        Result := Result + sLineBreak + SL[i];
    end;
  finally
    SL.Free;
  end;
end;

function HistParseJournalPrimaryLine(const S: string): Integer;
var
  Parts: TStringList;
  op: string;
begin
  Result := 0;
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(S, Parts);
    if Parts.Count < 3 then Exit;
    op := UpperCase(Trim(Parts[1]));
    if (op = 'EDT') or (op = 'INS') or (op = 'DEL') or (op = 'BINS') or (op = 'BAUT') or (op = 'BDEL') or
       (op = 'MDLT') or (op = 'MRGF') or (op = 'ANON') or (op = 'ANOL') then
      Result := StrToIntDef(Trim(Parts[2]), 0)
    else if op = 'RPLALL' then
      Result := 1;
  finally
    Parts.Free;
  end;
end;

{ Start/end (1-based, inclusive) of file lines touched by a journal event. }
procedure HistParseJournalLineSpan(const S: string; out AStart, AEnd: Integer);
var
  Parts: TStringList;
  op: string;
  cnt: Integer;
begin
  AStart := 0;
  AEnd := 0;
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(S, Parts);
    if Parts.Count < 3 then Exit;
    op := UpperCase(Trim(Parts[1]));
    if (op = 'EDT') or (op = 'INS') or (op = 'DEL') or (op = 'MRGF') or (op = 'ANOL') then
    begin
      AStart := StrToIntDef(Trim(Parts[2]), 0);
      AEnd := AStart;
    end
    else if (op = 'BINS') or (op = 'BAUT') or (op = 'BDEL') or (op = 'MDLT') then
    begin
      AStart := StrToIntDef(Trim(Parts[2]), 0);
      cnt := 1;
      if Parts.Count >= 4 then
        cnt := StrToIntDef(Trim(Parts[3]), 1);
      if cnt < 1 then cnt := 1;
      AEnd := AStart + cnt - 1;
      if AEnd < AStart then AEnd := AStart;
    end
    else if op = 'ANON' then
    begin
      AStart := StrToIntDef(Trim(Parts[2]), 0);
      cnt := 0;
      if Parts.Count >= 4 then
        cnt := StrToIntDef(Trim(Parts[3]), 0);
      if AStart <= 0 then
        AStart := 0
      else if cnt <= 0 then
      begin
        AStart := 1;
        AEnd := MaxInt div 4;
      end
      else
        AEnd := AStart + cnt - 1;
    end
    else if op = 'RPLALL' then
    begin
      AStart := 1;
      AEnd := MaxInt div 4;
    end;
  finally
    Parts.Free;
  end;
end;

{ 0 equal, 1 EDT, 2 INS, 3 DEL, 4 RPLALL, 5 UNDO/REDO — igual a BrushForHistTag. }
function HistParseJournalTag(const S: string): Integer;
var
  Parts: TStringList;
  op: string;
begin
  Result := 0;
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(S, Parts);
    if Parts.Count < 2 then Exit;
    op := UpperCase(HistSanitizeText(Parts[1]));
    if (op = 'EDT') or (op = 'MDLT') or (op = 'MRGF') or (op = 'ANON') or (op = 'ANOL') then
      Result := 1
    else if (op = 'INS') or (op = 'BINS') or (op = 'BAUT') then
      Result := 2
    else if (op = 'DEL') or (op = 'BDEL') then
      Result := 3
    else if op = 'RPLALL' then
      Result := 4
    else if (op = 'UNDO') or (op = 'REDO') then
      Result := 5;
  finally
    Parts.Free;
  end;
end;

function HistParseJournalExcerpt(const S: string): string;
var
  Parts: TStringList;
  op, oldEx, newEx: string;
begin
  Result := '';
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(S, Parts);
    if Parts.Count < 2 then
    begin
      Result := HistSanitizeJournalExcerpt(S, 160);
      if Result = TrText('(text unavailable)') then
        Result := '';
      Exit;
    end;
    op := UpperCase(HistSanitizeText(Parts[1]));
    if (op = 'EDT') or (op = 'INS') or (op = 'DEL') or (op = 'ANOL') then
    begin
      oldEx := '';
      newEx := '';
      if Parts.Count >= 4 then
        oldEx := Parts[3];
      if Parts.Count >= 5 then
        newEx := Parts[4];
      Result := HistEditChangeSummary(oldEx, newEx);
      Result := HistTruncateJournalLine(Result, 160);
    end
    else
      Result := FormatHistJournalLineForDisplay(S);
  finally
    Parts.Free;
  end;
end;

function HistOverlayCaption(const Tag: Integer; const Excerpt: string): string;
var
  lab: string;
begin
  case Tag of
    1: lab := 'EDT';
    2: lab := 'INS';
    3: lab := 'DEL';
    4: lab := 'RPLALL';
    5: lab := 'UNDO';
  else
    lab := '';
  end;
  if lab = '' then
    Result := Excerpt
  else if Excerpt = '' then
    Result := '[' + lab + ']'
  else
    Result := '[' + lab + '] ' + Excerpt;
end;

procedure HistFilterKeepJournalLines(Keep: TStringList; AbortFlag: PBoolean;
  ProgressWorker: THistoryReloadThread = nil);
var
  i: Integer;
  S: string;
begin
  i := 0;
  while i < Keep.Count do
  begin
    if Assigned(AbortFlag) and AbortFlag^ then Exit;
    if Assigned(ProgressWorker) then
    begin
      if (i and $3FF) = 0 then
        Sleep(1);
      if ((i and $FFF) = 0) and (Keep.Count > 0) then
        ProgressWorker.ReportFilterKeepProgress(i, Keep.Count);
    end;
    S := Trim(Keep[i]);
    if (S = '') or ((Length(S) >= 1) and (S[1] = '#')) then
      Keep.Delete(i)
    else
    begin
      Keep[i] := S;
      Inc(i);
    end;
  end;
  if Assigned(ProgressWorker) and (Keep.Count > 0) then
  begin
    ProgressWorker.ReportFilterKeepProgress(Keep.Count - 1, Keep.Count);
    Sleep(0);
  end;
end;

procedure ApplyJournalLineToLineKinds(const S: string; const maxL: Integer;
  var LineKinds: array of Byte; Parts: TStringList);
var
  op: string;
  L, cnt, j: Integer;
begin
  if maxL <= 0 then Exit;
  if (S = '') or ((Length(S) >= 1) and (S[1] = '#')) then Exit;
  HistSplitPipeFields(S, Parts);
  if Parts.Count < 3 then Exit;
  op := UpperCase(Trim(Parts[1]));
  if op = 'RPLALL' then
  begin
    FillChar(LineKinds[1], maxL, 4);
    Exit;
  end;
  if op = 'BINS' then
  begin
    L := StrToIntDef(Trim(Parts[2]), 0);
    cnt := StrToIntDef(Trim(Parts[3]), 1);
    if cnt < 1 then cnt := 1;
    for j := L to L + cnt - 1 do
      if (j >= 1) and (j <= maxL) then
        LineKinds[j] := 2;
    Exit;
  end;
  if op = 'BAUT' then
  begin
    L := StrToIntDef(Trim(Parts[2]), 0);
    cnt := StrToIntDef(Trim(Parts[3]), 1);
    if cnt < 1 then cnt := 1;
    for j := L to L + cnt - 1 do
      if (j >= 1) and (j <= maxL) then
        LineKinds[j] := 2;
    Exit;
  end;
  if op = 'BDEL' then
  begin
    L := StrToIntDef(Trim(Parts[2]), 0);
    cnt := StrToIntDef(Trim(Parts[3]), 1);
    if cnt < 1 then cnt := 1;
    for j := L to L + cnt - 1 do
      if (j >= 1) and (j <= maxL) then
        LineKinds[j] := 3;
    Exit;
  end;
  if op = 'MDLT' then
  begin
    L := StrToIntDef(Trim(Parts[2]), 0);
    cnt := StrToIntDef(Trim(Parts[3]), 1);
    if cnt < 1 then cnt := 1;
    for j := L to L + cnt - 1 do
      if (j >= 1) and (j <= maxL) then
        LineKinds[j] := 1;
    Exit;
  end;
  if op = 'MRGF' then
  begin
    if maxL >= 1 then
      LineKinds[1] := 1;
    Exit;
  end;
  if op = 'ANON' then
  begin
    L := StrToIntDef(Trim(Parts[2]), 0);
    cnt := 0;
    if Parts.Count >= 4 then
      cnt := StrToIntDef(Trim(Parts[3]), 0);
    if L <= 0 then
      Exit
    else if cnt <= 0 then
      FillChar(LineKinds[1], maxL, 1)
    else
      for j := Max(L, 1) to Min(Int64(L) + cnt - 1, maxL) do
        LineKinds[j] := 1;
    Exit;
  end;
  if (op = 'EDT') or (op = 'INS') or (op = 'DEL') or (op = 'ANOL') then
  begin
    L := StrToIntDef(Trim(Parts[2]), 0);
    if (L >= 1) and (L <= maxL) then
    begin
      if (op = 'EDT') or (op = 'ANOL') then
        LineKinds[L] := 1
      else if op = 'INS' then
        LineKinds[L] := 2
      else
        LineKinds[L] := 3;
    end;
  end;
end;

procedure ScanSessionJournalStream(const JournalPath: string; const maxL: Integer;
  var LineKinds: array of Byte; Parts: TStringList; AbortFlag: PBoolean;
  ProcessUIMessages: Boolean; ProgressWorker: THistoryReloadThread = nil);
var
  F: TFileStream;
  Buf: array[0..cHistJournalStreamBuf - 1] of AnsiChar;
  Got, k: Integer;
  Cur: AnsiString;
  lineCount: Integer;
begin
  if (JournalPath = '') or (not FileExists(JournalPath)) or (maxL <= 0) then Exit;
  lineCount := 0;
  F := TFileStream.Create(JournalPath, fmOpenRead or fmShareDenyNone);
  try
    if Assigned(ProgressWorker) and (F.Size > 0) then
    begin
      ProgressWorker.ReportScanJournalProgress(0, F.Size);
      Sleep(0);
    end;
    Cur := '';
    while True do
    begin
      if Assigned(AbortFlag) and AbortFlag^ then Exit;
      Got := F.Read(Buf, cHistJournalStreamBuf);
      if Got <= 0 then Break;
      for k := 0 to Got - 1 do
      begin
        if Buf[k] = #10 then
        begin
          Inc(lineCount);
          if Assigned(ProgressWorker) and (F.Size > 0) and
            ((lineCount mod 4096) = 0) then
          begin
            ProgressWorker.ReportScanJournalProgress(F.Position, F.Size);
            Sleep(0);
          end;
          if ProcessUIMessages and ((lineCount mod cJournalProgressEveryLines) = 0) then
          begin
            Application.ProcessMessages;
            if Assigned(AbortFlag) and AbortFlag^ then Exit;
          end;
          ApplyJournalLineToLineKinds(Trim(RawBytesToDisplayString(Cur)), maxL, LineKinds, Parts);
          Cur := '';
        end
        else if Buf[k] <> #13 then
          Cur := Cur + Buf[k];
      end;
      if Assigned(ProgressWorker) then
        Sleep(0);
    end;
    if Trim(Cur) <> '' then
      ApplyJournalLineToLineKinds(Trim(RawBytesToDisplayString(Cur)), maxL, LineKinds, Parts);
    if Assigned(ProgressWorker) and (F.Size > 0) then
    begin
      ProgressWorker.ReportScanJournalProgress(F.Size, F.Size);
      Sleep(0);
    end;
  finally
    F.Free;
  end;
end;

procedure SkipToFirstLineFeed(F: TFileStream);
var
  b: AnsiChar;
  n: Integer;
begin
  while F.Position < F.Size do
  begin
    n := F.Read(b, 1);
    if n <= 0 then Break;
    if b = #10 then Break;
  end;
end;

{ Le a partir de StartOffset (tipicamente cauda do ficheiro) e mantem apenas as ultimas
  cTailWindowMaxLines linhas completas em Dest (evita crescer sem limite). }
procedure StreamJournalTailLinesIntoList(const JournalPath: string; const StartOffset: Int64;
  Dest: TStringList; AbortFlag: PBoolean; ProcessUIMessages: Boolean;
  ProgressWorker: THistoryReloadThread = nil);
var
  F: TFileStream;
  Buf: array[0..cHistJournalStreamBuf - 1] of AnsiChar;
  Got, k: Integer;
  Cur: AnsiString;
  lineCount: Integer;
  tailStart: Int64;
  tailSpan: Int64;
  readB: Int64;
  lastTailReport: Int64;
begin
  Dest.Clear;
  if (JournalPath = '') or (not FileExists(JournalPath)) then Exit;
  F := TFileStream.Create(JournalPath, fmOpenRead or fmShareDenyNone);
  try
    if StartOffset > 0 then
    begin
      F.Seek(StartOffset, soFromBeginning);
      SkipToFirstLineFeed(F);
    end;
    tailStart := F.Position;
    tailSpan := F.Size - tailStart;
    if tailSpan < 1 then tailSpan := 1;
    if Assigned(ProgressWorker) then
    begin
      ProgressWorker.ReportTailStreamProgress(0, tailSpan);
      Sleep(0);
    end;
    Cur := '';
    lineCount := 0;
    lastTailReport := -1;
    while True do
    begin
      if Assigned(AbortFlag) and AbortFlag^ then Exit;
      Got := F.Read(Buf, cHistJournalStreamBuf);
      if Got <= 0 then Break;
      if Assigned(ProgressWorker) then
      begin
        readB := F.Position - tailStart;
        if (lastTailReport < 0) or (readB >= tailSpan) or (readB - lastTailReport >= 256 * 1024) then
        begin
          lastTailReport := readB;
          ProgressWorker.ReportTailStreamProgress(readB, tailSpan);
          Sleep(0);
        end;
      end;
      for k := 0 to Got - 1 do
      begin
        if Buf[k] = #10 then
        begin
          Inc(lineCount);
          if ProcessUIMessages and ((lineCount mod cJournalProgressEveryLines) = 0) then
          begin
            Application.ProcessMessages;
            if Assigned(AbortFlag) and AbortFlag^ then Exit;
          end;
          Dest.Add(Trim(RawBytesToDisplayString(Cur)));
          Cur := '';
          while Dest.Count > cTailWindowMaxLines do
            Dest.Delete(0);
        end
        else if Buf[k] <> #13 then
          Cur := Cur + Buf[k];
      end;
    end;
    if Trim(Cur) <> '' then
    begin
      Dest.Add(Trim(RawBytesToDisplayString(Cur)));
      while Dest.Count > cTailWindowMaxLines do
        Dest.Delete(0);
    end;
    if Assigned(ProgressWorker) then
    begin
      ProgressWorker.ReportTailStreamProgress(tailSpan, tailSpan);
      Sleep(0);
    end;
  finally
    F.Free;
  end;
end;

constructor THistoryReloadThread.Create(AForm: TfrmCompareMerge; const AJPath, ADPath: string;
  AShowSmoothLoading: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  { Menos prioridade que a UI / outras threads: melhor multitarefa no SO. }
  Priority := tpLower;
  FForm := AForm;
  FForm.FHistoryReloadThread := Self;
  FJournalPath := AJPath;
  FDataPath := ADPath;
  FMemoLines := TStringList.Create;
  FMemoRaws := TStringList.Create;
  FMemoExcerpts := TStringList.Create;
  FPreviewSL := TStringList.Create;
  SetLength(FMemoLineNums, 0);
  SetLength(FMemoLineEnds, 0);
  SetLength(FMemoTags, 0);
  FSkipJournalColors := False;
  FClearListViewOnly := False;
  FShowLoadingUI := AShowSmoothLoading;
  FLastProgressSynced := -1;
  if FShowLoadingUI then
  begin
    FLoadingMsg := TrText('Reloading session history...');
    FProgressToSet := 0;
    Synchronize(SyncShowLoading);
    Synchronize(SyncSetProgress);
    FLastProgressSynced := 0;
  end;
  OnTerminate := AForm.HistoryReloadThreadDone;
  Resume;
end;

procedure THistoryReloadThread.SyncShowLoading;
begin
  { Sem fsStayOnTop: evita WS_EX_TOPMOST a competir com o switcher de tarefas (Alt+Tab). }
  TfrmSmoothLoading.ShowLoading(FLoadingMsg, False);
end;

procedure THistoryReloadThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure THistoryReloadThread.SyncSetProgress;
begin
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure THistoryReloadThread.SyncPumpPostedProgress;
begin
  { Garante fila Win32 limpa antes do SyncApply (paints / timers pendentes). }
  if FShowLoadingUI then
    HistPumpUIMessagesAndYield;
end;

procedure THistoryReloadThread.SetSmoothProgress(const Pct: Integer);
var
  v: Integer;
  tick: Cardinal;
  doPost: Boolean;
begin
  if not FShowLoadingUI then Exit;
  if Pct < 0 then v := 0 else if Pct > 100 then v := 100 else v := Pct;
  if v < FLastProgressSynced then Exit;
  { Nao ignorar v = FLastProgressSynced: em leituras longas o % inteiro repete-se e a barra deixava
    de ser repintada ate' saltar de fase. }
  FLastProgressSynced := v;
  FProgressToSet := v;
  { Timer na main + PostMessage espacado: FHistReloadProgTarget e' sempre actualizado; o timer
    reflecte; PostMessage com throttle curto (evita fila cheia sem "barra parada"). }
  if (FForm <> nil) and (not FForm.FClosing) then
  begin
    FForm.FHistReloadProgTarget := v;
    tick := GetTickCount;
    doPost := (FForm.FHistReloadProgLastPosted < 0) or (v >= 99) or
      (Cardinal(tick - FForm.FHistReloadProgLastFlushTick) >= 22) or
      (v > FForm.FHistReloadProgLastPosted);
    if doPost and FForm.HandleAllocated then
    begin
      FForm.FHistReloadProgLastFlushTick := tick;
      FForm.FHistReloadProgLastPosted := v;
      PostMessage(FForm.Handle, WM_FF_HIST_PROGRESS_FLUSH, 0, 0);
    end;
    Sleep(2);
  end
  else
    Synchronize(SyncSetProgress);
end;

procedure THistoryReloadThread.ReportTailStreamProgress(const BytesReadInTail, TailByteSpan: Int64);
var
  v: Integer;
  span, readB: Int64;
begin
  if not FShowLoadingUI then Exit;
  span := TailByteSpan;
  if span < 1 then span := 1;
  readB := BytesReadInTail;
  if readB < 0 then readB := 0 else if readB > span then readB := span;
  { 8..22: cauda do journal; fase pesada fica para SyncApply ( > cHistProgWorkerEnd ). }
  v := 8 + Integer(Min(14, (readB * 14) div span));
  SetSmoothProgress(v);
end;

procedure THistoryReloadThread.ReportFilterKeepProgress(const Index, TotalLines: Integer);
var
  v: Integer;
  denom: Integer;
begin
  if not FShowLoadingUI or (TotalLines <= 0) then Exit;
  if TotalLines <= 1 then
    v := 28
  else
  begin
    denom := TotalLines - 1;
    if denom < 1 then denom := 1;
    v := 22 + MulDiv(Index, 6, denom);
  end;
  if (Index >= TotalLines - 1) then v := 28;
  SetSmoothProgress(v);
end;

procedure THistoryReloadThread.ReportReadPreviewProgress(const FilePos, FileSize: Int64);
var
  v: Integer;
  sz, pos: Int64;
begin
  if not FShowLoadingUI then Exit;
  sz := FileSize;
  if sz <= 0 then Exit;
  pos := FilePos;
  if pos < 0 then pos := 0 else if pos > sz then pos := sz;
  { 35..48: leitura do ficheiro de preview (antes da aplicacao na UI). }
  v := 35 + Integer(Min(13, (pos * 13) div sz));
  SetSmoothProgress(v);
end;

procedure THistoryReloadThread.ReportScanJournalProgress(const FilePos, FileSize: Int64);
var
  v: Integer;
  sz, pos: Int64;
begin
  if not FShowLoadingUI then Exit;
  sz := FileSize;
  if sz <= 0 then Exit;
  pos := FilePos;
  if pos < 0 then pos := 0 else if pos > sz then pos := sz;
  { 48..54: scan do journal de cores (fim = cHistProgWorkerEnd). }
  v := 48 + Integer(Min(6, (pos * 6) div sz));
  SetSmoothProgress(v);
end;

destructor THistoryReloadThread.Destroy;
begin
  if Assigned(FForm) and (FForm.FHistoryReloadThread = Self) then
    FForm.FHistoryReloadThread := nil;
  FMemoLines.Free;
  FMemoRaws.Free;
  FMemoExcerpts.Free;
  FPreviewSL.Free;
  inherited Destroy;
end;

procedure THistoryReloadThread.SyncApply;
var
  j, LnStart, LnEnd: Integer;
  Raw: string;
begin
  if (FForm = nil) or FForm.FClosing then Exit;
  if Assigned(FForm.FHistReloadUITimer) then
  begin
    if FShowLoadingUI then
      TfrmSmoothLoading.UpdateProgress(FForm.FHistReloadProgTarget);
    FForm.FHistReloadUITimer.Enabled := False;
  end;
  if Assigned(FForm.btnReloadHist) then
    FForm.btnReloadHist.Enabled := True;
  FForm.lblHistPath.Caption := TrText('History log path:') + ' ' + FJournalPath;

  FForm.JournalCacheClear;
  if FMemoLines.Count = 0 then
    FForm.JournalCacheAdd(TrText('No session history file yet. Edits will append here.'), 0, 0, 0, '')
  else
    for j := 0 to FMemoLines.Count - 1 do
    begin
      LnStart := 0;
      LnEnd := 0;
      if j < Length(FMemoLineNums) then
        LnStart := FMemoLineNums[j];
      if j < Length(FMemoLineEnds) then
        LnEnd := FMemoLineEnds[j]
      else
        LnEnd := LnStart;
      if j < Length(FMemoTags) then
      begin
        if Assigned(FMemoExcerpts) and (j < FMemoExcerpts.Count) then
        begin
          Raw := '';
          if Assigned(FMemoRaws) and (j < FMemoRaws.Count) then
            Raw := FMemoRaws[j];
          FForm.JournalCacheAdd(FMemoLines[j], LnStart, LnEnd, FMemoTags[j], FMemoExcerpts[j], Raw);
        end
        else
          FForm.JournalCacheAdd(FMemoLines[j], LnStart, LnEnd, FMemoTags[j], '');
      end
      else
        FForm.JournalCacheAdd(FMemoLines[j], LnStart, LnEnd, 0, '');
    end;
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(cHistProgWorkerEnd + 24);

  FForm.FJournalPreviewHiliteIdx := -1;
  FForm.ApplyJournalDisplayMode;

  if FForm.FClosing then Exit;

  FForm.lblHistPreview.Caption := TrText('History file preview (colors from journal; line numbers are as at edit time).');

  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(80);
  if FClearListViewOnly then
    FForm.ApplyHistPreviewToListView(nil, FLineKinds, True)
  else
    FForm.StartHistPagedPreview(FDataPath);
  if FShowLoadingUI then
    TfrmSmoothLoading.UpdateProgress(99);
end;

{ --- TDiffWorkerThread ------------------------------------------------------ }

constructor TDiffWorkerThread.Create(AForm: TfrmCompareMerge;
  const ALPath, ARPath: string; ALo, AHi: Int64; AByLines: Boolean;
  AAutoFastEnabled: Boolean; AForceRangeBytes: Int64);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  Priority := tpLower;
  FForm := AForm;
  FForm.FDiffWorkerThread := Self;
  FLPath := ALPath;
  FRPath := ARPath;
  FLo := ALo;
  FHi := AHi;
  FByLines := AByLines;
  FAutoFastEnabled := AAutoFastEnabled;
  FForceRangeBytes := AForceRangeBytes;
  FResultRows := TList.Create;
  FProgressToSet := 0;
  FLastProgressSynced := -1;
  FForm.FDiffProgTarget := 0;
  FForm.FDiffProgLastPosted := -1;
  FForm.FDiffProgLastFlushTick := 0;
  OnTerminate := AForm.DiffWorkerThreadDone;
  Synchronize(SyncShowLoading);
  Resume;
end;

destructor TDiffWorkerThread.Destroy;
var
  i: Integer;
begin
  if Assigned(FForm) and (FForm.FDiffWorkerThread = Self) then
    FForm.FDiffWorkerThread := nil;
  if Assigned(FResultRows) then
  begin
    for i := 0 to FResultRows.Count - 1 do
      Dispose(PFFDiffRow(FResultRows[i]));
    FResultRows.Free;
    FResultRows := nil;
  end;
  inherited Destroy;
end;

procedure TDiffWorkerThread.SyncShowLoading;
begin
  TfrmSmoothLoading.ShowLoading(FForm, TrText('Processing diff...'), False);
end;

procedure TDiffWorkerThread.SyncHideLoading;
begin
  TfrmSmoothLoading.HideLoading;
end;

procedure TDiffWorkerThread.SyncSetProgress;
begin
  TfrmSmoothLoading.UpdateProgress(FProgressToSet);
end;

procedure TDiffWorkerThread.SyncReEnableButton;
begin
  if Assigned(FForm) and Assigned(FForm.btnRunDiff) then
    FForm.btnRunDiff.Enabled := True;
end;

procedure TDiffWorkerThread.SetSmoothProgress(const Pct: Integer);
var
  v: Integer;
  tick: Cardinal;
  doPost: Boolean;
begin
  v := Pct;
  if v < 0 then v := 0 else if v > 100 then v := 100;
  if v < FLastProgressSynced then Exit;
  FLastProgressSynced := v;
  FProgressToSet := v;
  if (FForm <> nil) and (not FForm.FClosing) then
  begin
    FForm.FDiffProgTarget := v;
    tick := GetTickCount;
    doPost := (FForm.FDiffProgLastPosted < 0) or (v >= 99) or
      (Cardinal(tick - FForm.FDiffProgLastFlushTick) >= 22) or
      (v > FForm.FDiffProgLastPosted);
    if doPost and FForm.HandleAllocated then
    begin
      FForm.FDiffProgLastFlushTick := tick;
      FForm.FDiffProgLastPosted := v;
      PostMessage(FForm.Handle, WM_FF_DIFF_PROGRESS_FLUSH, 0, 0);
    end;
    Sleep(2);
  end
  else
    Synchronize(SyncSetProgress);
end;

procedure TDiffWorkerThread.SyncApply;
var
  OldRows: TList;
  i: Integer;
  hasDiff: Boolean;
begin
  if (FForm = nil) or FForm.FClosing then Exit;

  TfrmSmoothLoading.UpdateProgress(99);

  { Troca os resultados na main thread: FResultRows -> FForm.FDiffRows. }
  OldRows := FForm.FDiffRows;
  FForm.FDiffRows := FResultRows;
  FResultRows := TList.Create; { evita double-free no destructor }

  { Liberta as linhas antigas numa thread de GC para nao bloquear a UI. }
  TFFDiffRowGarbageCollector.Create(OldRows);

  FForm.lvLeft.Items.Clear;
  FForm.lvRight.Items.Clear;
  FForm.lvLeft.OwnerData := not FByLines;
  FForm.lvRight.OwnerData := not FByLines;

  if FByLines then
  begin
    for i := 0 to FForm.FDiffRows.Count - 1 do
    begin
      with FForm.lvLeft.Items.Add do
      begin
        Caption := IntToStr(PFFDiffRow(FForm.FDiffRows[i])^.LNum);
        SubItems.Add(PFFDiffRow(FForm.FDiffRows[i])^.LText);
        Data := FForm.FDiffRows[i];
      end;
      with FForm.lvRight.Items.Add do
      begin
        Caption := IntToStr(PFFDiffRow(FForm.FDiffRows[i])^.RNum);
        SubItems.Add(PFFDiffRow(FForm.FDiffRows[i])^.RText);
        Data := FForm.FDiffRows[i];
      end;
    end;
  end
  else
  begin
    FForm.lvLeft.Items.Count := FForm.FDiffRows.Count;
    FForm.lvRight.Items.Count := FForm.FDiffRows.Count;
  end;

  if FByLines then
    FForm.FDiffLo := FLo
  else
    FForm.FDiffLo := 1;
  if (FForm.FDiffRestoreTop >= 0) and Assigned(FForm.FDiffRestoreLv) then
  begin
    i := FForm.FDiffRestoreSel;
    if (i >= 0) and (i < FForm.FDiffRestoreLv.Items.Count) then
    begin
      FForm.FDiffRestoreLv.Items[i].Selected := True;
      FForm.FDiffRestoreLv.Items[i].Focused := True;
    end;
    FFListViewSetExactTopIndex(FForm.lvLeft, FForm.FDiffRestoreTop);
    FFListViewSetExactTopIndex(FForm.lvRight, FForm.FDiffRestoreTop);
    FForm.FDiffSyncLastTopL := FForm.FDiffRestoreTop;
  end;
  FForm.FDiffRestoreTop := -1;
  FForm.FDiffRestoreLv := nil;

  hasDiff := False;
  for i := 0 to FForm.FDiffRows.Count - 1 do
    if PFFDiffRow(FForm.FDiffRows[i])^.Kind <> ffdkEqual then
    begin
      hasDiff := True;
      Break;
    end;
  if not hasDiff then
    MessageDlg(TrText('There is no difference between the files.'), mtInformation, [mbOK], 0)
  else if FForm.FDiffMergeOkMsg then
    MessageDlg(TrText('Merge apply finished OK.'), mtInformation, [mbOK], 0);
  FForm.FDiffMergeOkMsg := False;

  if FForm.FDiffSyncLastTopL < 0 then FForm.FDiffSyncLastTopL := 0;
  FForm.FDiffSyncLastTopR := FForm.FDiffSyncLastTopL;
  FForm.FDiffScrollLastSource := 1;
  FForm.FHistoryLoaded := True;
  if not FForm.FClosing and FForm.chkSyncScroll.Checked then
    FForm.DiffApplyTopIndexToPeer(FForm.lvLeft);
  FForm.tmrSync.Enabled := not FForm.FClosing and FForm.chkSyncScroll.Checked;

  if Assigned(FForm.btnRunDiff) then
    FForm.btnRunDiff.Enabled := True;

  TfrmSmoothLoading.HideLoading;
end;

procedure TDiffWorkerThread.Execute;
var
  Left, Right: TStringList;
  UseByLines: Boolean;
  ReadHi: Int64;
  WindowLines: Int64;
begin
  try
    try
      if (FForm = nil) or FForm.FClosing or Terminated then Exit;

      Left := TStringList.Create;
      Right := TStringList.Create;
      try
        UseByLines := FByLines or
          FFShouldForceRangeDiff(FLPath, FRPath, FAutoFastEnabled, FForceRangeBytes);
        SetSmoothProgress(5);
        if UseByLines then
        begin
          ReadHi := FHi + FF_DIFF_RANGE_LOOKAHEAD;
          WindowLines := FHi - FLo + 1;
          if WindowLines < 1 then WindowLines := 1;
          { Worker: sem ProcessMessages; sem tecto de bytes (para no fim do intervalo). }
          ReadTextFileLineSlice(FLPath, FLo, ReadHi, Left, @FForm.FClosing, False, nil,
            High(Int64));
          if FForm.FClosing or Terminated then Exit;
          SetSmoothProgress(15);
          ReadTextFileLineSlice(FRPath, FLo, ReadHi, Right, @FForm.FClosing, False, nil,
            High(Int64));
          if FForm.FClosing or Terminated then Exit;
          SetSmoothProgress(30);
          FFBuildLineDiffRows(Left, Right, FF_DIFF_MAX_LINES, FResultRows);
          FFTrimDiffRowsToWindow(FResultRows, WindowLines);
        end
        else
        begin
          ReadTextFileLineSlice(FLPath, 1, High(Int64), Left, @FForm.FClosing, False, nil,
            High(Int64));
          if FForm.FClosing or Terminated then Exit;
          SetSmoothProgress(15);
          ReadTextFileLineSlice(FRPath, 1, High(Int64), Right, @FForm.FClosing, False, nil,
            High(Int64));
          if FForm.FClosing or Terminated then Exit;
          SetSmoothProgress(30);
          FFBuildLineDiffRows(Left, Right, MaxInt, FResultRows);
        end;
      finally
        Right.Free;
        Left.Free;
      end;

      SetSmoothProgress(80);
      if FForm.FClosing or Terminated then Exit;

      Synchronize(SyncApply);
    except
      { Swallow exceptions in thread; re-enable button + hide overlay. }
      Synchronize(SyncHideLoading);
      Synchronize(SyncReEnableButton);
    end;
  finally
    { nada: FreeOnTerminate := True }
  end;
end;

{ --- fim TDiffWorkerThread -------------------------------------------------- }

procedure THistoryReloadThread.Execute;
var
  Keep: TStringList;
  sz, start: Int64;
  F: TFileStream;
  firstIdx, j, cnt, k, LnStart, LnEnd, Tg: Integer;
  S, Ex: string;
  DispSL: TStringList;
begin
  try
    try
      if (FForm = nil) or FForm.FClosing or Terminated then Exit;

      SetSmoothProgress(8);

    Keep := TStringList.Create;
    try
      if (FJournalPath <> '') and FileExists(FJournalPath) then
      begin
        F := TFileStream.Create(FJournalPath, fmOpenRead or fmShareDenyNone);
        try
          sz := F.Size;
        finally
          F.Free;
        end;
        if sz <= Int64(cHistJournalTailBytes) then
          StreamJournalTailLinesIntoList(FJournalPath, 0, Keep, @FForm.FClosing, False, Self)
        else
        begin
          start := sz - Min(sz, Int64(cHistJournalTailBytes));
          StreamJournalTailLinesIntoList(FJournalPath, start, Keep, @FForm.FClosing, False, Self);
        end;
        HistFilterKeepJournalLines(Keep, @FForm.FClosing, Self);
        firstIdx := 0;
        if Keep.Count > cHistJournalMaxLines then
          firstIdx := Keep.Count - cHistJournalMaxLines;
        cnt := Keep.Count - firstIdx;
        if cnt < 0 then cnt := 0;
        if cnt > cHistJournalThreadMaxLines then
        begin
          firstIdx := firstIdx + (cnt - cHistJournalThreadMaxLines);
          cnt := cHistJournalThreadMaxLines;
        end;
        SetLength(FMemoLineNums, 0);
        SetLength(FMemoLineEnds, 0);
        SetLength(FMemoTags, 0);
        FMemoLines.Clear;
        FMemoRaws.Clear;
        FMemoExcerpts.Clear;
        for j := 0 to cnt - 1 do
        begin
          if FForm.FClosing or Terminated then Exit;
          S := Keep[firstIdx + j];
          DispSL := TStringList.Create;
          try
            FormatHistJournalLinesForDisplay(S, DispSL);
            if DispSL.Count = 0 then
              DispSL.Add('');
            HistParseJournalLineSpan(S, LnStart, LnEnd);
            Tg := HistParseJournalTag(S);
            Ex := HistParseJournalExcerpt(S);
            for k := 0 to DispSL.Count - 1 do
            begin
              FMemoLines.Add(DispSL[k]);
              SetLength(FMemoLineNums, FMemoLines.Count);
              SetLength(FMemoLineEnds, FMemoLines.Count);
              SetLength(FMemoTags, FMemoLines.Count);
              FMemoLineNums[FMemoLines.Count - 1] := LnStart;
              if LnStart = 0 then
                FMemoLineEnds[FMemoLines.Count - 1] := 0
              else
                FMemoLineEnds[FMemoLines.Count - 1] := LnEnd;
              FMemoTags[FMemoLines.Count - 1] := Tg;
              if k = 0 then
              begin
                FMemoExcerpts.Add(Ex);
                FMemoRaws.Add(S);
              end
              else
              begin
                FMemoExcerpts.Add('');
                FMemoRaws.Add('');
              end;
            end;
          finally
            DispSL.Free;
          end;
          { Progresso gradual 28..34% durante montagem do memo (apos stream/filtro). }
          if FShowLoadingUI and (cnt > 0) and
            (((j and $FF) = $FF) or (j = cnt - 1)) then
            SetSmoothProgress(28 + Min(6, MulDiv(j + 1, 6, cnt)));
        end;
      end;
      SetSmoothProgress(35);
    finally
      Keep.Free;
    end;

    if FForm.FClosing or Terminated then Exit;

    if not FileExists(FDataPath) then
    begin
      FClearListViewOnly := True;
      SetLength(FLineKinds, 0);
      FPreviewSL.Clear;
      SetSmoothProgress(cHistProgWorkerEnd);
      if not (FForm.FClosing or Terminated) then
      begin
        Synchronize(SyncPumpPostedProgress);
        Synchronize(SyncApply);
      end;
      Exit;
    end;

    { Preview do ficheiro: paginado (TFFPagedLineSource) arrancado em SyncApply —
      indice esparso + cores do journal na propria thread do preview, sem limite de linhas. }
    if not (FForm.FClosing or Terminated) then
    begin
      SetSmoothProgress(cHistProgWorkerEnd);
      Synchronize(SyncPumpPostedProgress);
      Synchronize(SyncApply);
    end;
    except
    end;
  finally
    if FShowLoadingUI then
    begin
      { Esvazia WM_APP+77 pendentes antes de libertar o overlay (PostProgressFromWorker). }
      Synchronize(SyncPumpPostedProgress);
      Synchronize(SyncHideLoading);
    end;
  end;
end;

function TfrmCompareMerge.TruncateJournalLine(const S: string; MaxLen: Integer): string;
begin
  Result := HistTruncateJournalLine(S, MaxLen);
end;

function TfrmCompareMerge.ParseJournalPrimaryLine(const S: string): Integer;
begin
  Result := HistParseJournalPrimaryLine(S);
end;

procedure TfrmCompareMerge.JournalListEnterMutation(out ASavedOnClick: TNotifyEvent;
  out ASavedOnMouseUp: TMouseEvent);
begin
  ASavedOnClick := mmoJournal.OnClick;
  ASavedOnMouseUp := mmoJournal.OnMouseUp;
  mmoJournal.OnClick := nil;
  mmoJournal.OnMouseUp := nil;
  if Assigned(FsgJournal) then
  begin
    FsgJournal.OnMouseUp := nil;
    FsgJournal.OnSelectCell := nil;
  end;
end;

procedure TfrmCompareMerge.JournalListLeaveMutation(const ASavedOnClick: TNotifyEvent;
  const ASavedOnMouseUp: TMouseEvent);
begin
  mmoJournal.OnClick := ASavedOnClick;
  mmoJournal.OnMouseUp := ASavedOnMouseUp;
  if Assigned(FsgJournal) then
  begin
    FsgJournal.OnMouseUp := sgJournalMouseUp;
    FsgJournal.OnSelectCell := sgJournalSelectCell;
  end;
end;

procedure TfrmCompareMerge.JournalMetaClear;
begin
  if Assigned(FJournalLineNums) then
    FJournalLineNums.Clear;
  if Assigned(FJournalTags) then
    FJournalTags.Clear;
  if Assigned(FJournalExcerpts) then
    FJournalExcerpts.Clear;
  if Assigned(FJournalRaws) then
    FJournalRaws.Clear;
  ClearHistJournalOverlay;
end;

procedure TfrmCompareMerge.JournalMetaAdd(const ALine, ATag: Integer; const AExcerpt: string);
begin
  JournalMetaAdd(ALine, ALine, ATag, AExcerpt);
end;

procedure TfrmCompareMerge.JournalMetaAdd(const ALine, ALineEnd, ATag: Integer;
  const AExcerpt: string; const ARaw: string);
begin
  if Assigned(FJournalLineNums) then
    FJournalLineNums.Add(Pointer(ALine));
  if Assigned(FJournalTags) then
    FJournalTags.Add(Pointer(ATag));
  if Assigned(FJournalExcerpts) then
    FJournalExcerpts.Add(AExcerpt);
  if Assigned(FJournalRaws) then
    FJournalRaws.Add(ARaw);
end;

procedure TfrmCompareMerge.JournalCacheClear;
begin
  if Assigned(FJournalCacheLines) then
    FJournalCacheLines.Clear;
  if Assigned(FJournalCacheLineNums) then
    FJournalCacheLineNums.Clear;
  if Assigned(FJournalCacheLineEnds) then
    FJournalCacheLineEnds.Clear;
  if Assigned(FJournalCacheTags) then
    FJournalCacheTags.Clear;
  if Assigned(FJournalCacheExcerpts) then
    FJournalCacheExcerpts.Clear;
  if Assigned(FJournalCacheRaws) then
    FJournalCacheRaws.Clear;
end;

procedure TfrmCompareMerge.JournalCacheAdd(const AText: string; const ALine, ALineEnd, ATag: Integer;
  const AExcerpt: string; const ARaw: string);
begin
  if not Assigned(FJournalCacheLines) then Exit;
  FJournalCacheLines.Add(AText);
  if Assigned(FJournalCacheLineNums) then
    FJournalCacheLineNums.Add(Pointer(ALine));
  if Assigned(FJournalCacheLineEnds) then
    FJournalCacheLineEnds.Add(Pointer(ALineEnd));
  if Assigned(FJournalCacheTags) then
    FJournalCacheTags.Add(Pointer(ATag));
  if Assigned(FJournalCacheExcerpts) then
    FJournalCacheExcerpts.Add(AExcerpt);
  if Assigned(FJournalCacheRaws) then
    FJournalCacheRaws.Add(ARaw);
end;

procedure TfrmCompareMerge.EnsureHistShowAllCheckBox;
begin
  if Assigned(FchkHistShowAll) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FchkHistShowAll := TCheckBox.Create(Self);
  FchkHistShowAll.Parent := TabSheetHistory;
  FchkHistShowAll.Name := 'chkHistShowAll';
  FchkHistShowAll.Left := 264;
  FchkHistShowAll.Top := 36;
  FchkHistShowAll.Width := 400;
  FchkHistShowAll.Height := 17;
  FchkHistShowAll.Anchors := [akLeft, akTop];
  FchkHistShowAll.Checked := FHistShowAllJournal;
  FchkHistShowAll.OnClick := chkHistShowAllClick;
  FchkHistShowAll.Caption := TrText('Hist.ShowAllJournal');
  FchkHistShowAll.Hint := TrText('Hist.ShowAllJournalHint');
  FchkHistShowAll.ShowHint := True;
end;

procedure TfrmCompareMerge.chkHistShowAllClick(Sender: TObject);
begin
  if FApplyingJournalView then Exit;
  FHistShowAllJournal := Assigned(FchkHistShowAll) and FchkHistShowAll.Checked;
  ApplyJournalDisplayMode;
end;

procedure TfrmCompareMerge.EnsureHistSourceMru;
begin
  if Assigned(FedtHistSource) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FedtHistSource := TEdit.Create(Self);
  FedtHistSource.Parent := TabSheetHistory;
  FedtHistSource.Name := 'edtHistSource';
  FedtHistSource.Text := '';
  FedtHistSource.ReadOnly := True;
  FedtHistSource.Color := clWindow;
  FedtHistSource.TextHint := TrText('Hist.SourceMruCue');
  FedtHistSource.Hint := TrText('Hist.SourceMruHint');
  FedtHistSource.ShowHint := True;
  FedtHistSource.OnDblClick := btnHistSourceMruClick;
  FedtHistSource.OnKeyDown := edtHistSourceKeyDown;
  FbtnHistSourceMru := TButton.Create(Self);
  FbtnHistSourceMru.Parent := TabSheetHistory;
  FbtnHistSourceMru.Name := 'btnHistSourceMru';
  FbtnHistSourceMru.Caption := #$25BC;
  FbtnHistSourceMru.Hint := TrText('Hist.SourceMruHint');
  FbtnHistSourceMru.ShowHint := True;
  FbtnHistSourceMru.OnClick := btnHistSourceMruClick;
  { Linha do MRU no topo; caminho do journal e dica descem uma linha. }
  if Assigned(lblHistPath) then
    lblHistPath.Top := 62;
  if Assigned(lblJournalHint) then
    lblJournalHint.Top := 80;
  LayoutHistSourceMru;
  UpdateHistSourceEdit;
end;

procedure TfrmCompareMerge.LayoutHistSourceMru;
var
  cw, x, w: Integer;
begin
  if not Assigned(FedtHistSource) or not Assigned(TabSheetHistory) then Exit;
  cw := TabSheetHistory.ClientWidth - 16;
  if cw < 120 then Exit;
  FedtHistSource.SetBounds(8, 5, cw - 30, 22);
  FbtnHistSourceMru.SetBounds(8 + cw - 28, 4, 28, 24);
  if not Assigned(FchkHistShowAll) or not Assigned(FchkHistChangedList) then Exit;
  FchkHistShowAll.Width := HistTextW(FchkHistShowAll.Caption) + 28;
  x := FchkHistShowAll.Left + FchkHistShowAll.Width + 12;
  w := HistTextW(FchkHistChangedList.Caption) + 28;
  FchkHistChangedList.SetBounds(x, FchkHistShowAll.Top, w, FchkHistShowAll.Height);
end;

procedure TfrmCompareMerge.UpdateHistSourceEdit;
begin
  if not Assigned(FedtHistSource) then Exit;
  if FedtHistSource.Text <> Trim(FDefaultLeft) then
    FedtHistSource.Text := Trim(FDefaultLeft);
end;

{ Entradas removidas do MRU do historico: o journal fica intacto; a entrada so'
  volta se o journal receber eventos novos (data de escrita posterior). }
function HistMruHiddenFile: string;
begin
  Result := IncludeTrailingPathDelimiter(EnsureFastFileSessionHistoryDir) + 'mru_hidden.txt';
end;

function HistMruKey(const APath: string): string;
begin
  Result := AnsiLowerCase(ExpandFileName(Trim(APath)));
end;

function HistFileTimeStamp(const AFt: TFileTime): Int64;
begin
  Result := (Int64(AFt.dwHighDateTime) shl 32) or AFt.dwLowDateTime;
end;

function HistJournalStamp(const AJournal: string): Int64;
var
  Data: TWin32FileAttributeData;
begin
  Result := 0;
  if GetFileAttributesEx(PChar(AJournal), GetFileExInfoStandard, @Data) then
    Result := HistFileTimeStamp(Data.ftLastWriteTime);
end;

procedure HistMruLoadHidden(ADict: TDictionary<string, Int64>);
var
  SL: TStringList;
  i, p: Integer;
  S: string;
begin
  if not FileExists(HistMruHiddenFile) then Exit;
  SL := TStringList.Create;
  try
    try
      SL.LoadFromFile(HistMruHiddenFile, TEncoding.UTF8);
    except
      Exit;
    end;
    for i := 0 to SL.Count - 1 do
    begin
      S := SL[i];
      p := Pos(#9, S);
      if p > 1 then
        ADict.AddOrSetValue(Copy(S, p + 1, MaxInt), StrToInt64Def(Copy(S, 1, p - 1), 0));
    end;
  finally
    SL.Free;
  end;
end;

procedure HistMruSaveHidden(ADict: TDictionary<string, Int64>);
var
  SL: TStringList;
  Pair: TPair<string, Int64>;
begin
  SL := TStringList.Create;
  try
    for Pair in ADict do
      if Pair.Value > 0 then
        SL.Add(IntToStr(Pair.Value) + #9 + Pair.Key);
    try
      if SL.Count = 0 then
        DeleteFile(HistMruHiddenFile)
      else
        SL.SaveToFile(HistMruHiddenFile, TEncoding.UTF8);
    except
    end;
  finally
    SL.Free;
  end;
end;

procedure TfrmCompareMerge.HistMruHide(const APaths: array of string);
var
  D: TDictionary<string, Int64>;
  i: Integer;
begin
  D := TDictionary<string, Int64>.Create;
  try
    HistMruLoadHidden(D);
    for i := 0 to High(APaths) do
      if Trim(APaths[i]) <> '' then
        D.AddOrSetValue(HistMruKey(APaths[i]),
          HistJournalStamp(FFHistoryJournalPath(Trim(APaths[i]))));
    HistMruSaveHidden(D);
  finally
    D.Free;
  end;
end;

procedure TfrmCompareMerge.HistSourceMruRemove(Sender: TObject; const APath: string);
var
  i: Integer;
begin
  if FClosing then Exit;
  HistMruHide([APath]);
  if Assigned(FHistSourceItems) then
    for i := FHistSourceItems.Count - 1 downto 0 do
      if SameText(FHistSourceItems[i], APath) then
        FHistSourceItems.Delete(i);
end;

procedure TfrmCompareMerge.HistSourceMruClearAll(Sender: TObject);
begin
  if FClosing or not Assigned(FHistSourceItems) then Exit;
  HistMruHide(FHistSourceItems.ToStringArray);
  FHistSourceItems.Clear;
end;

procedure TfrmCompareMerge.CollectHistorySourceFiles(AList: TStrings);
type
  TSrcEntry = record
    Path: string;
    Stamp: TDateTime;
  end;
const
  cHdr = '#FFHISTv1 src=';
var
  Dir, Src, Line: string;
  SR: TSearchRec;
  FS: TFileStream;
  Buf: TBytes;
  Raw: RawByteString;
  n, p, i, j: Integer;
  Seen: TStringList;
  Entries: array of TSrcEntry;
  Tmp: TSrcEntry;
  Hidden: TDictionary<string, Int64>;
  HidStamp: Int64;
begin
  AList.Clear;
  Dir := IncludeTrailingPathDelimiter(EnsureFastFileSessionHistoryDir);
  Hidden := TDictionary<string, Int64>.Create;
  Seen := TStringList.Create;
  try
    HistMruLoadHidden(Hidden);
    Seen.Sorted := True;
    Seen.CaseSensitive := False;
    Seen.Duplicates := dupIgnore;
    if FindFirst(Dir + 'ffhist_*.log', faAnyFile and not faDirectory, SR) = 0 then
    try
      repeat
        if not SameText(ExtractFileExt(SR.Name), '.log') then Continue;
        if SR.Size <= 0 then Continue;
        Src := '';
        try
          FS := TFileStream.Create(Dir + SR.Name, fmOpenRead or fmShareDenyNone);
          try
            n := Min(Int64(1024), FS.Size);
            SetLength(Buf, n);
            if n > 0 then
              n := FS.Read(Buf[0], n);
            SetLength(Buf, n);
          finally
            FS.Free;
          end;
          p := 0;
          while (p < n) and (Buf[p] <> 10) and (Buf[p] <> 13) do
            Inc(p);
          SetLength(Raw, p);
          if p > 0 then
            Move(Buf[0], Raw[1], p);
          { UTF8ToString nao levanta excecao; journals antigos em ANSI caem no fallback. }
          Line := UTF8ToString(Raw);
          if Pos(#$FFFD, Line) > 0 then
            Line := string(AnsiString(Raw));
          Line := TrimRight(Line);
          if (Length(Line) > 0) and (Line[1] = #$FEFF) then
            Delete(Line, 1, 1);
          if SameText(Copy(Line, 1, Length(cHdr)), cHdr) then
            Src := Trim(Copy(Line, Length(cHdr) + 1, MaxInt));
        except
          Src := '';
        end;
        if (Src = '') or (not FileExists(Src)) then Continue;
        if Hidden.TryGetValue(HistMruKey(Src), HidStamp) and
           (HistFileTimeStamp(SR.FindData.ftLastWriteTime) <= HidStamp) then
          Continue;
        if Seen.IndexOf(Src) >= 0 then Continue;
        Seen.Add(Src);
        SetLength(Entries, Length(Entries) + 1);
        Entries[High(Entries)].Path := Src;
        Entries[High(Entries)].Stamp := SR.TimeStamp;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  finally
    Seen.Free;
    Hidden.Free;
  end;
  for i := 1 to High(Entries) do
  begin
    Tmp := Entries[i];
    j := i - 1;
    while (j >= 0) and (Entries[j].Stamp < Tmp.Stamp) do
    begin
      Entries[j + 1] := Entries[j];
      Dec(j);
    end;
    Entries[j + 1] := Tmp;
  end;
  for i := 0 to High(Entries) do
    AList.Add(Entries[i].Path);
end;

procedure TfrmCompareMerge.btnHistSourceMruClick(Sender: TObject);
begin
  if FClosing then Exit;
  { O popup e' partilhado (MRU principal, filtro, assistente): so' alterna o nosso;
    um popup de outro dono e' fechado e substituido pelo nosso. }
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    if TMethod(FormPopupMruList.OnPick).Data = Pointer(Self) then
      Exit;
  end;
  if HandleAllocated then
    PostMessage(Handle, WM_FF_HIST_SOURCE_MRU, 0, 0);
end;

procedure TfrmCompareMerge.edtHistSourceKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F4) or ((Key = VK_DOWN) and (ssAlt in Shift)) or (Key = VK_RETURN) then
  begin
    Key := 0;
    btnHistSourceMruClick(Sender);
  end;
end;

procedure TfrmCompareMerge.WMHistSourceMru(var Msg: TMessage);
var
  CR: TRect;
  P: TPoint;
  W: Integer;
  OwnerComp: TComponent;
begin
  Msg.Result := 0;
  if FClosing or not Assigned(FedtHistSource) then Exit;
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    PostMessage(Handle, WM_FF_HIST_SOURCE_MRU, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if not Assigned(FHistSourceItems) then
    FHistSourceItems := TStringList.Create;
  Screen.Cursor := crHourGlass;
  try
    CollectHistorySourceFiles(FHistSourceItems);
  finally
    Screen.Cursor := crDefault;
  end;
  if FHistSourceItems.Count = 0 then
  begin
    FastFileMessageBox(PChar(TrText('Hist.SourceMruEmpty')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if FedtHistSource.HandleAllocated then
  begin
    GetWindowRect(FedtHistSource.Handle, CR);
    W := FbtnHistSourceMru.BoundsRect.Right - FedtHistSource.Left;
    P := Point(CR.Left, CR.Bottom);
  end
  else
  begin
    W := FedtHistSource.Width;
    P := FedtHistSource.ClientToScreen(Point(0, FedtHistSource.Height));
  end;
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('Hist.SourceMruTitle'),
    MruMoreCaption('RecentFiles.More'), FHistSourceItems, W, P,
    HistSourceMruPick, TrText('Hist.SourceMruMoreHint'),
    nil, HistSourceMruRemove, FbtnHistSourceMru, HistSourceMruClearAll);
end;

procedure TfrmCompareMerge.HistSourceMruPick(Sender: TObject; const AValue: string;
  AIndex: Integer);
var
  P: string;
begin
  if FClosing then Exit;
  P := Trim(AValue);
  if (P = '') or (not FileExists(P)) then Exit;
  if SameText(ExpandFileName(P), ExpandFileName(Trim(FDefaultLeft))) and FHistoryLoaded then
    Exit;
  if Assigned(FHistoryReloadThread) then Exit;
  FDefaultLeft := P;
  if Assigned(edtLeftFile) then
    edtLeftFile.Text := P;
  FJournalPreviewHiliteIdx := -1;
  ClearHistJournalOverlay;
  UpdateHistSourceEdit;
  ReloadHistoryMemo(True);
end;

procedure TfrmCompareMerge.EnsureChangedLinesList;
var
  B: TButton;
  Bmp: TBitmap;
  th: Integer;
begin
  if Assigned(FlbChangedLines) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FlblChangedLines := TLabel.Create(Self);
  FlblChangedLines.Parent := TabSheetHistory;
  FlblChangedLines.AutoSize := False;
  FlblChangedLines.Font.Style := [fsBold];
  FlblChangedLines.Caption := Format(TrText('Hist.ChangedLines: %d'), [0]);
  FlblChangedLines.Hint := TrText('Hist.ChangedLinesHint') + #13#10 +
    TrText('Hist.DblClickToggleList');
  FlblChangedLines.ShowHint := True;
  FlblChangedLines.OnDblClick := btnChangedListToggleClick;
  FlbChangedLines := TListBox.Create(Self);
  FlbChangedLines.Parent := TabSheetHistory;
  { Virtual: so' a contagem; o texto e' montado no desenho a partir do indice. }
  FlbChangedLines.Style := lbVirtualOwnerDraw;
  FlbChangedLines.Font.Name := 'Consolas';
  if FlbChangedLines.Font.Name <> 'Consolas' then
    FlbChangedLines.Font.Name := 'Courier New';
  FlbChangedLines.Font.Size := 9;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FlbChangedLines.Font);
    th := Bmp.Canvas.TextHeight('Ag');
    Bmp.Canvas.Font.Name := 'Segoe UI';
    Bmp.Canvas.Font.Size := 8;
    FChgWhenH := Bmp.Canvas.TextHeight('Ag');
  finally
    Bmp.Free;
  end;
  FlbChangedLines.ItemHeight := th + FChgWhenH + 6;
  FlbChangedLines.Hint := TrText('Hist.ChangedLinesHint');
  FlbChangedLines.ShowHint := True;
  FlbChangedLines.OnClick := lbChangedLinesClick;
  FlbChangedLines.OnMouseDown := lbChangedLinesMouseDown;
  FlbChangedLines.OnDrawItem := lbChangedLinesDrawItem;
  FpmChgCtx := TPopupMenu.Create(Self);
  FpmChgCtx.OnPopup := ChgCtxPopup;
  FlbChangedLines.PopupMenu := FpmChgCtx;

  FbtnChgFirst := TButton.Create(Self);
  FbtnChgFirst.Caption := #$23EE;
  FbtnChgPrev := TButton.Create(Self);
  FbtnChgPrev.Caption := #$25C0;
  FbtnChgNext := TButton.Create(Self);
  FbtnChgNext.Caption := #$25B6;
  FbtnChgLast := TButton.Create(Self);
  FbtnChgLast.Caption := #$23ED;
  for B in TArray<TButton>.Create(FbtnChgFirst, FbtnChgPrev, FbtnChgNext, FbtnChgLast) do
  begin
    B.Parent := TabSheetHistory;
    B.Font.Name := 'Segoe UI Symbol';
    B.OnClick := ChgPagerClick;
    B.ShowHint := True;
    B.Visible := False;
  end;
  FlblChgPage := TLabel.Create(Self);
  FlblChgPage.Parent := TabSheetHistory;
  FlblChgPage.AutoSize := False;
  FlblChgPage.Alignment := taCenter;
  FlblChgPage.Layout := tlCenter;
  FlblChgPage.ShowHint := True;
  FlblChgPage.Visible := False;
  FedtChgGoto := TEdit.Create(Self);
  FedtChgGoto.Parent := TabSheetHistory;
  FedtChgGoto.ShowHint := True;
  FedtChgGoto.OnKeyPress := edtChgGotoKeyPress;
  FbtnChgGoto := TButton.Create(Self);
  FbtnChgGoto.Parent := TabSheetHistory;
  FbtnChgGoto.OnClick := btnChgGotoClick;
  FbtnChgGoto.ShowHint := True;
  CreateHistDateRow(TabSheetHistory, FdeChgFrom, FdeChgTo, FlblChgFrom, FlblChgTo,
    FbtnChgDateClr);
  FChgDateQ := HistDateQueryOf(FdeChgFrom, FdeChgTo);

  FbtnChgAll := TButton.Create(Self);
  FbtnChgDel := TButton.Create(Self);
  FbtnChgSort := TButton.Create(Self);
  FbtnChgExport := TButton.Create(Self);
  FbtnChgAI := TButton.Create(Self);
  FbtnChgAll.Tag := 1;
  FbtnChgDel.Tag := 2;
  FbtnChgSort.Tag := 3;
  FbtnChgExport.Tag := 4;
  FbtnChgAI.Tag := 5;
  for B in TArray<TButton>.Create(FbtnChgAll, FbtnChgDel, FbtnChgSort, FbtnChgExport, FbtnChgAI) do
  begin
    B.Parent := TabSheetHistory;
    B.OnClick := ChgToolClick;
    B.ShowHint := True;
    B.Visible := False;
    B.ParentFont := False;
    if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
      B.Font.Name := 'Segoe UI'
    else
      B.Font.Name := 'Tahoma';
    B.Font.Size := 7;
  end;
  ApplyChgPagerCaptions;
end;

procedure TfrmCompareMerge.ApplyChgPagerCaptions;
begin
  if not Assigned(FbtnChgFirst) then Exit;
  FbtnChgFirst.Hint := TrText('Hist.ChgFirstPage');
  FbtnChgPrev.Hint := TrText('Hist.ChgPrevPage');
  FbtnChgNext.Hint := TrText('Hist.ChgNextPage');
  FbtnChgLast.Hint := TrText('Hist.ChgLastPage');
  FlblChgPage.Hint := TrText('Hist.ChgPageHint');
  FedtChgGoto.TextHint := TrText('Hist.ChgGotoCue');
  FedtChgGoto.Hint := TrText('Hist.ChgGotoHint');
  FbtnChgGoto.Caption := TrText('Hist.ChgGotoButton');
  FbtnChgGoto.Hint := TrText('Hist.ChgGotoHint');
end;

const
  { Itens por pagina da lista "Linhas alteradas" (lista virtual: o custo e' so' a pagina visivel). }
  cChgPageSize = 1000;

procedure TfrmCompareMerge.ChgWndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_FF_CHG_INDEX: WMChgIndex(Msg);
    WM_FF_CHG_EVENTS: WMChgEvents(Msg);
    WM_FF_MERGE_APPLY: WMMergeApply(Msg);
  else
    Msg.Result := DefWindowProc(FChgWnd, Msg.Msg, Msg.WParam, Msg.LParam);
  end;
end;

procedure TfrmCompareMerge.StopChgThreads;
begin
  if Assigned(FChgBuilder) then
  begin
    FChgBuilder.Terminate;
    FChgBuilder.WaitFor;
    FreeAndNil(FChgBuilder);
  end;
  if Assigned(FChgEvtScan) then
  begin
    FChgEvtScan.Terminate;
    FChgEvtScan.WaitFor;
    FreeAndNil(FChgEvtScan);
  end;
end;

function TfrmCompareMerge.ChgPageCount: Integer;
begin
  Result := 1;
  if ChgViewCount > 0 then
    Result := (ChgViewCount + cChgPageSize - 1) div cChgPageSize;
end;

function TfrmCompareMerge.ChgRecAt(AItem: Integer; out R: THciRec): Boolean;
var
  g: Integer;
begin
  Result := False;
  FillChar(R, SizeOf(R), 0);
  if (AItem < 0) or not Assigned(FChgIdx) then Exit;
  g := FChgPage * cChgPageSize + AItem;
  if g >= ChgViewCount then Exit;
  g := ChgViewIndex(g);
  if g >= FChgIdx.Count then Exit;
  R := FChgIdx.Get(g);
  Result := True;
end;

function TfrmCompareMerge.ChgItemText(const R: THciRec): string;
const
  TagNames: array[1..5] of string = ('EDT', 'INS', 'DEL', 'RPLALL', 'UNDO');
var
  Tg: Integer;
begin
  if R.Ln1 > R.Ln0 then
    Result := Format(TrText('Hist.ChangedRangeItem: %d %d'), [R.Ln0, R.Ln1])
  else
    Result := Format(TrText('Hist.ChangedLineItem: %d'), [R.Ln0]);
  Result := Result + ' ';
  for Tg := 1 to 5 do
    if R.Cnt[Tg] > 0 then
    begin
      Result := Result + ' ' + TagNames[Tg];
      if R.Cnt[Tg] > 1 then
        Result := Result + 'x' + IntToStr(R.Cnt[Tg]);
    end;
end;

procedure TfrmCompareMerge.RebuildChangedLinesList;
var
  P: string;
  Sz, Tm: Int64;
begin
  EnsureChangedLinesList;
  if FClosing or not Assigned(FlbChangedLines) then Exit;
  P := '';
  if Trim(FDefaultLeft) <> '' then
    P := FFHistoryJournalPath(FDefaultLeft);
  if Assigned(FChgIdx) and not SameText(FChgIdx.JournalPath, P) then
  begin
    FreeAndNil(FChgIdx);
    FreeAndNil(FChgEvtRaw);
    FChgEvtLine := 0;
    FChgPage := 0;
    ChgClearSelection;
    FChgOrder := nil;
    FChgOrderRev := nil;
    FChgAutoSelPending := True;
    if Assigned(FJrnSel) then
      FJrnSel.Clear;
  end;
  if (P = '') or not HciJournalStamp(P, Sz, Tm) or (Sz = 0) then
  begin
    if Assigned(FChgBuilder) then
      FChgDirty := True
    else if Assigned(FChgIdx) then
    begin
      FreeAndNil(FChgIdx);
      FreeAndNil(FChgEvtRaw);
      FChgEvtLine := 0;
      FChgPage := 0;
    end;
    RefreshChangedLinesView;
    Exit;
  end;
  { Chamado a cada mudanca do diario: sem alteracao no ficheiro nao ha' trabalho. }
  if Assigned(FChgIdx) and (FChgIdx.JournalSize = Sz) and (FChgIdx.JournalTime = Tm) then
  begin
    RefreshChangedLinesView;
    Exit;
  end;
  if Assigned(FChgBuilder) then
  begin
    FChgDirty := True;
    Exit;
  end;
  if FChgWnd = 0 then Exit;
  FChgBuildPct := 0;
  FChgBuilder := THciBuildThread.Create(P, EnsureFastFileTempSubDir('chgidx'),
    FChgWnd, WM_FF_CHG_INDEX);
  FChgBuilder.Start;
  RefreshChangedLinesView;
end;

procedure TfrmCompareMerge.WMChgIndex(var Msg: TMessage);
var
  T: THciBuildThread;
  NewIdx: THistChangedIndex;
  R: THciRec;
  SelLn: Integer;
begin
  Msg.Result := 0;
  if not Assigned(FChgBuilder) then Exit;
  if Msg.WParam = cHciMsgProgress then
  begin
    if FChgBuildPct <> Integer(Msg.LParam) then
    begin
      FChgBuildPct := Integer(Msg.LParam);
      if Assigned(FlblChangedLines) then
        FlblChangedLines.Caption := Format(TrText('Hist.ChangedLinesIndexing: %d'),
          [FChgBuildPct]);
    end;
    Exit;
  end;
  if Msg.LParam <> LPARAM(FChgBuilder) then Exit;
  T := FChgBuilder;
  FChgBuilder := nil;
  T.WaitFor;
  NewIdx := T.TakeResult;
  T.Free;
  FChgBuildPct := -1;
  if FClosing then
  begin
    NewIdx.Free;
    Exit;
  end;
  SelLn := 0;
  if Assigned(FlbChangedLines) and ChgRecAt(FlbChangedLines.ItemIndex, R) then
    SelLn := R.Ln0;
  FreeAndNil(FChgIdx);
  FChgIdx := NewIdx;
  RebuildChgOrder;
  FreeAndNil(FChgEvtRaw);
  FChgEvtLine := 0;
  if (SelLn = 0) or not ChgSelectLine(SelLn, False) then
    RefreshChangedLinesView;
  if SelLn = 0 then
    ChgTryAutoSelectFirst;
  if FChgDirty then
  begin
    FChgDirty := False;
    RebuildChangedLinesList;
  end;
  { Linha ja' selecionada no diario: pode agora ter eventos fora da janela em cache. }
  if FJournalPreviewHiliteIdx >= 0 then
    RequestApplyJournalDisplayMode;
end;

procedure TfrmCompareMerge.RefreshChangedLinesView;
var
  total, pages, n, sel: Integer;
  wantPager: Boolean;
begin
  if not Assigned(FlbChangedLines) then Exit;
  total := ChgViewCount;
  pages := ChgPageCount;
  if FChgPage >= pages then FChgPage := pages - 1;
  if FChgPage < 0 then FChgPage := 0;
  n := Max(0, Min(cChgPageSize, total - FChgPage * cChgPageSize));
  { LB_SETCOUNT limpa a selecao: so' quando a contagem muda. }
  if FlbChangedLines.Count <> n then
  begin
    sel := FlbChangedLines.ItemIndex;
    FlbChangedLines.Count := n;
    if (sel >= 0) and (sel < n) then
      FlbChangedLines.ItemIndex := sel;
  end;
  FlbChangedLines.Invalidate;
  if Assigned(FChgBuilder) and (FChgBuildPct >= 0) then
    FlblChangedLines.Caption := Format(TrText('Hist.ChangedLinesIndexing: %d'), [FChgBuildPct])
  else if FChgFiltered and Assigned(FChgIdx) then
    FlblChangedLines.Caption := Format(TrText('Hist.ChangedLinesFiltered: %s %s'),
      [FormatFloat('#,##0', total), FormatFloat('#,##0', FChgIdx.Count)])
  else
    FlblChangedLines.Caption := StringReplace(TrText('Hist.ChangedLines: %d'), '%d',
      FormatFloat('#,##0', total), []);
  if not Assigned(FlblChgPage) then Exit;
  FlblChgPage.Caption := FormatFloat('#,##0', FChgPage + 1) + ' / ' + FormatFloat('#,##0', pages);
  FbtnChgFirst.Enabled := FChgPage > 0;
  FbtnChgPrev.Enabled := FChgPage > 0;
  FbtnChgNext.Enabled := FChgPage < pages - 1;
  FbtnChgLast.Enabled := FChgPage < pages - 1;
  wantPager := FlbChangedLines.Visible;
  if FbtnChgFirst.Visible <> wantPager then
    TabSheetHistoryResize(TabSheetHistory);
  ApplyHistToolCaptions;
end;

function TfrmCompareMerge.ChgPagerHeight: Integer;
begin
  Result := 47;
end;

procedure TfrmCompareMerge.LayoutChgPager(AX, AY, AW: Integer);
var
  pager: Boolean;
  bw: Integer;
begin
  if not Assigned(FedtChgGoto) then Exit;
  { Sempre visivel com a lista: com uma pagina so' os botoes ficam desativados ("1 / 1"). }
  pager := AW > 0;
  FbtnChgFirst.Visible := pager;
  FbtnChgPrev.Visible := pager;
  FbtnChgNext.Visible := pager;
  FbtnChgLast.Visible := pager;
  FlblChgPage.Visible := pager;
  FedtChgGoto.Visible := AW > 0;
  FbtnChgGoto.Visible := AW > 0;
  if AW <= 0 then Exit;
  if pager then
  begin
    bw := 22;
    FbtnChgFirst.SetBounds(AX, AY, bw, 21);
    FbtnChgPrev.SetBounds(AX + bw, AY, bw, 21);
    FbtnChgNext.SetBounds(AX + AW - 2 * bw, AY, bw, 21);
    FbtnChgLast.SetBounds(AX + AW - bw, AY, bw, 21);
    FlblChgPage.SetBounds(AX + 2 * bw + 2, AY, Max(10, AW - 4 * bw - 4), 21);
    Inc(AY, 23);
  end;
  FedtChgGoto.SetBounds(AX, AY, AW - 48, 21);
  FbtnChgGoto.SetBounds(AX + AW - 44, AY, 44, 21);
end;

function TfrmCompareMerge.ChgSelectLine(ALine: Integer; ANearest: Boolean): Boolean;
var
  g, pg, disp: Integer;
begin
  Result := False;
  if not Assigned(FChgIdx) or (FChgIdx.Count = 0) or not Assigned(FlbChangedLines) then Exit;
  g := FChgIdx.LowerBound(ALine);
  if (g >= FChgIdx.Count) or (FChgIdx.Get(g).Ln0 <> ALine) then
  begin
    if not ANearest then Exit;
    if g >= FChgIdx.Count then
      g := FChgIdx.Count - 1;
  end;
  if (g >= 0) and (g < Length(FChgOrderRev)) then
    disp := FChgOrderRev[g]
  else
    disp := g;
  if disp < 0 then Exit;
  pg := disp div cChgPageSize;
  FSyncingChangedLines := True;
  try
    if pg <> FChgPage then
    begin
      FChgPage := pg;
      RefreshChangedLinesView;
    end;
    FlbChangedLines.ItemIndex := disp mod cChgPageSize;
  finally
    FSyncingChangedLines := False;
  end;
  Result := True;
end;

procedure TfrmCompareMerge.ChgPagerClick(Sender: TObject);
var
  pg: Integer;
begin
  pg := FChgPage;
  if Sender = FbtnChgFirst then pg := 0
  else if Sender = FbtnChgPrev then Dec(pg)
  else if Sender = FbtnChgNext then Inc(pg)
  else if Sender = FbtnChgLast then pg := ChgPageCount - 1;
  pg := Max(0, Min(pg, ChgPageCount - 1));
  if pg = FChgPage then Exit;
  FChgPage := pg;
  FlbChangedLines.ItemIndex := -1;
  RefreshChangedLinesView;
  FlbChangedLines.TopIndex := 0;
end;

procedure TfrmCompareMerge.ChgTryAutoSelectFirst;
begin
  if not FChgAutoSelPending or FClosing or not Assigned(FlbChangedLines) then Exit;
  if not Assigned(FChgIdx) or Assigned(FChgBuilder) or (ChgViewCount < 1) then Exit;
  { Com o diario ainda a carregar o evento nao teria onde ser mostrado: tenta-se no fim da carga. }
  if Assigned(FHistoryReloadThread) then Exit;
  FChgAutoSelPending := False;
  if FlbChangedLines.ItemIndex >= 0 then Exit;
  if FChgPage <> 0 then
  begin
    FChgPage := 0;
    RefreshChangedLinesView;
  end;
  if FlbChangedLines.Count < 1 then Exit;
  FlbChangedLines.ItemIndex := 0;
  FlbChangedLines.TopIndex := 0;
  lbChangedLinesClick(FlbChangedLines);
end;

procedure TfrmCompareMerge.ChgWheelScroll(WheelDelta: Integer);
var
  lb: TListBox;
  oldTop: Integer;
begin
  lb := FlbChangedLines;
  if not Assigned(lb) or (WheelDelta = 0) then Exit;
  oldTop := lb.TopIndex;
  WheelScrollControl(lb, WheelDelta);
  if lb.TopIndex <> oldTop then Exit;
  { No fim / inicio da pagina a roda continua na pagina seguinte / anterior. }
  if (WheelDelta < 0) and (FChgPage < ChgPageCount - 1) then
  begin
    Inc(FChgPage);
    lb.ItemIndex := -1;
    RefreshChangedLinesView;
    lb.TopIndex := 0;
  end
  else if (WheelDelta > 0) and (FChgPage > 0) and (oldTop = 0) then
  begin
    Dec(FChgPage);
    lb.ItemIndex := -1;
    RefreshChangedLinesView;
    lb.TopIndex := Max(0, lb.Count - 1);
  end;
end;

procedure TfrmCompareMerge.edtChgGotoKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    ChgGotoLine;
  end
  else if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure TfrmCompareMerge.btnChgGotoClick(Sender: TObject);
begin
  ChgGotoLine;
end;

procedure TfrmCompareMerge.ChgGotoLine;
var
  n: Integer;
begin
  n := StrToIntDef(StringReplace(StringReplace(Trim(FedtChgGoto.Text), '.', '', [rfReplaceAll]),
    ',', '', [rfReplaceAll]), 0);
  if n <= 0 then Exit;
  if ChgSelectLine(n, False) then
  begin
    lbChangedLinesClick(FlbChangedLines);
    Exit;
  end;
  if n > HistPreviewDataCount then Exit;

  FSyncingChangedLines := True;
  try
    FlbChangedLines.ItemIndex := -1;
  finally
    FSyncingChangedLines := False;
  end;
  ClearHistJournalOverlay;
  FJournalPreviewHiliteIdx := n - 1;
  if FHistShowAllJournal and Assigned(FchkHistShowAll) then
  begin
    FchkHistShowAll.Checked := False;
    FHistShowAllJournal := False;
  end;
  HistPreviewJumpToDataRow(n - 1);
end;

procedure TfrmCompareMerge.ChgRequestLineEvents(ALine: Integer);
var
  g: Integer;
  R: THciRec;
  FirstOfs, LastOfs: Int64;
begin
  if not Assigned(FChgIdx) or (FChgWnd = 0) then Exit;
  if Assigned(FChgEvtScan) then
  begin
    if FChgEvtScan.Line = ALine then Exit;
    FChgEvtScan.Terminate;
    FChgEvtScan.WaitFor;
    FreeAndNil(FChgEvtScan);
  end;
  FirstOfs := -1;
  LastOfs := -1;
  g := FChgIdx.LowerBound(ALine);
  while g < FChgIdx.Count do
  begin
    R := FChgIdx.Get(g);
    if R.Ln0 <> ALine then Break;
    if (FirstOfs < 0) or (R.FirstOfs < FirstOfs) then FirstOfs := R.FirstOfs;
    if R.LastOfs > LastOfs then LastOfs := R.LastOfs;
    Inc(g);
  end;
  if FirstOfs < 0 then Exit;
  FChgEvtScan := THciEventScanThread.Create(FChgIdx.JournalPath, FirstOfs, LastOfs, ALine,
    FChgWnd, WM_FF_CHG_EVENTS);
  FChgEvtScan.Start;
end;

procedure TfrmCompareMerge.WMChgEvents(var Msg: TMessage);
var
  T: THciEventScanThread;
begin
  Msg.Result := 0;
  if (Msg.WParam <> cHciMsgDone) or not Assigned(FChgEvtScan) or
     (Msg.LParam <> LPARAM(FChgEvtScan)) then Exit;
  T := FChgEvtScan;
  FChgEvtScan := nil;
  T.WaitFor;
  FreeAndNil(FChgEvtRaw);
  FChgEvtRaw := T.TakeEvents;
  FChgEvtLine := T.Line;
  T.Free;
  if FClosing then Exit;
  if FJournalPreviewHiliteIdx + 1 = FChgEvtLine then
    RequestApplyJournalDisplayMode;
end;

procedure TfrmCompareMerge.ApplyHistToolCaptions;
begin
  if Assigned(FbtnChgAll) then
  begin
    if ChgAllChecked then
      FbtnChgAll.Caption := TrText('Hist.Tool.None')
    else
      FbtnChgAll.Caption := TrText('Hist.Tool.All');
    FbtnChgAll.Hint := TrText('Hist.Tool.AllHint');
    FbtnChgDel.Caption := TrText('Hist.Tool.Delete');
    FbtnChgDel.Hint := TrText('Hist.Tool.DeleteHint');
    case FChgSort of
      1: FbtnChgSort.Caption := TrText('Hist.Tool.SortNew') + ' ▾';
      2: FbtnChgSort.Caption := TrText('Hist.Tool.SortOld') + ' ▾';
      3: FbtnChgSort.Caption := TrText('Hist.Tool.SortLineDesc') + ' ▾';
    else
      FbtnChgSort.Caption := TrText('Hist.Tool.SortLine') + ' ▾';
    end;
    FbtnChgSort.Hint := TrText('Hist.Tool.SortHint');
    FbtnChgExport.Caption := TrText('Hist.Tool.Export');
    FbtnChgExport.Hint := TrText('Hist.Tool.ExportHint');
    FbtnChgAI.Caption := TrText('Hist.Tool.AI');
    FbtnChgAI.Hint := TrText('Hist.Tool.AIHint');
    ApplyHistDateFilterHints;
    if FbtnChgAll.Visible and (FbtnChgAll.Width > 0) then
      LayoutChgTools(FbtnChgAll.Left, FbtnChgAll.Top,
        FbtnChgAI.Left + FbtnChgAI.Width - FbtnChgAll.Left);
    if Assigned(FlbChangedLines) and FlbChangedLines.Visible and
       (FlbChangedLines.Top <> FbtnChgAll.Top + FChgToolsH) and FbtnChgAll.Visible then
      TabSheetHistoryResize(TabSheetHistory);
  end;
  if Assigned(FbtnJrnAll) then
  begin
    if JrnAllChecked then
      FbtnJrnAll.Caption := TrText('Hist.Tool.None')
    else
      FbtnJrnAll.Caption := TrText('Hist.Tool.All');
    FbtnJrnAll.Hint := TrText('Hist.Tool.AllHint');
    FbtnJrnDel.Caption := TrText('Hist.Tool.Delete');
    FbtnJrnDel.Hint := TrText('Hist.Tool.DeleteHint');
    case FJrnSort of
      1: FbtnJrnSort.Caption := TrText('Hist.Tool.SortNew') + ' ▾';
      2: FbtnJrnSort.Caption := TrText('Hist.Tool.SortOld') + ' ▾';
    else
      FbtnJrnSort.Caption := TrText('Hist.Tool.SortLog') + ' ▾';
    end;
    FbtnJrnSort.Hint := TrText('Hist.Tool.SortHint');
    FbtnJrnExport.Caption := TrText('Hist.Tool.Export');
    FbtnJrnExport.Hint := TrText('Hist.Tool.ExportHint');
    FbtnJrnAI.Caption := TrText('Hist.Tool.AI');
    FbtnJrnAI.Hint := TrText('Hist.Tool.AIHint');
    ApplyHistDateFilterHints;
    LayoutJrnTools;
  end;
  if Assigned(FsgJournal) then
    FsgJournal.Hint := TrText('HistDetail.GridHint');
end;

procedure TfrmCompareMerge.LayoutChgTools(AX, AY, AW: Integer);
var
  Btns: array[0..4] of TButton;
  Widths: array[0..4] of Integer;
  i, x, w, row, first, last, used, extra: Integer;
  Bmp: TBitmap;
begin
  FChgToolsH := 0;
  Btns[0] := FbtnChgAll;
  Btns[1] := FbtnChgDel;
  Btns[2] := FbtnChgSort;
  Btns[3] := FbtnChgExport;
  Btns[4] := FbtnChgAI;
  if not Assigned(Btns[0]) then Exit;
  if AW <= 0 then
  begin
    for i := 0 to 4 do
      if Assigned(Btns[i]) then
        Btns[i].Visible := False;
    LayoutHistDateRow(0, 0, 0, 0, FlblChgFrom, FlblChgTo, FdeChgFrom, FdeChgTo,
      FbtnChgDateClr);
    Exit;
  end;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Btns[0].Font);
    for i := 0 to 4 do
      Widths[i] := Min(AW, Bmp.Canvas.TextWidth(Btns[i].Caption) + 14);
  finally
    Bmp.Free;
  end;
  { Quebra em linhas; cada linha estica os botões para ocupar a largura toda. }
  row := 0;
  first := 0;
  while first <= 4 do
  begin
    last := first;
    used := Widths[first];
    while (last < 4) and (used + 2 + Widths[last + 1] <= AW) do
    begin
      Inc(last);
      Inc(used, 2 + Widths[last]);
    end;
    extra := AW - used;
    x := AX;
    for i := first to last do
    begin
      w := Widths[i] + extra div (last - first + 1);
      if i = last then
        w := AX + AW - x;
      Btns[i].Visible := True;
      Btns[i].SetBounds(x, AY + row * 22, w, 20);
      Inc(x, w + 2);
    end;
    Inc(row);
    first := last + 1;
  end;
  FChgToolsH := row * 22;
  Inc(FChgToolsH, LayoutHistDateRow(AX, AY + FChgToolsH, AW, 21, FlblChgFrom, FlblChgTo,
    FdeChgFrom, FdeChgTo, FbtnChgDateClr));
end;

procedure TfrmCompareMerge.LayoutJrnTools;
var
  Btns: array[0..4] of TButton;
  i, x, w: Integer;
  Bmp: TBitmap;
begin
  if not Assigned(FpnJrnTools) or not Assigned(FbtnJrnAll) then Exit;
  Btns[0] := FbtnJrnAll;
  Btns[1] := FbtnJrnDel;
  Btns[2] := FbtnJrnSort;
  Btns[3] := FbtnJrnExport;
  Btns[4] := FbtnJrnAI;
  x := 4;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FbtnJrnAll.Font);
    for i := 0 to 4 do
    begin
      w := Bmp.Canvas.TextWidth(Btns[i].Caption) + 18;
      if w < 52 then
        w := 52;
      Btns[i].SetBounds(x, 2, w, FpnJrnTools.ClientHeight - 4);
      Inc(x, w + 4);
    end;
  finally
    Bmp.Free;
  end;
  LayoutHistDateRow(x + 6, 2, Max(230, Min(330, FpnJrnTools.ClientWidth - x - 10)),
    FpnJrnTools.ClientHeight - 4, FlblJrnFrom, FlblJrnTo, FdeJrnFrom, FdeJrnTo, FbtnJrnDateClr);
end;

procedure TfrmCompareMerge.RebuildChgOrder;
var
  i, n, m: Integer;
  R: THciRec;
  Ts: TArray<Int64>;
  Ln: TArray<Integer>;
begin
  FChgOrder := nil;
  FChgOrderRev := nil;
  FChgFiltered := FChgDateQ.Active;
  if ((FChgSort = 0) and not FChgFiltered) or not Assigned(FChgIdx) or
     (FChgIdx.Count < 1) then Exit;
  n := FChgIdx.Count;
  SetLength(FChgOrder, n);
  SetLength(Ts, n);
  SetLength(Ln, n);
  m := 0;
  for i := 0 to n - 1 do
  begin
    R := FChgIdx.Get(i);
    Ts[i] := R.LastTs;
    Ln[i] := R.Ln0;
    if FChgFiltered and not HciStampMatches(FChgDateQ, R.LastTs) and
       not HciStampMatches(FChgDateQ, R.FirstTs) then
      Continue;
    FChgOrder[m] := i;
    Inc(m);
  end;
  SetLength(FChgOrder, m);
  if FChgSort <> 0 then
    TArray.Sort<Integer>(FChgOrder, TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      begin
        case FChgSort of
          1: Result := CompareValue(Ts[B], Ts[A]);
          2: Result := CompareValue(Ts[A], Ts[B]);
        else
          Result := CompareValue(Ln[B], Ln[A]);
        end;
        if Result = 0 then
          Result := CompareValue(Ln[A], Ln[B]);
      end));
  SetLength(FChgOrderRev, n);
  for i := 0 to n - 1 do
    FChgOrderRev[i] := -1;
  for i := 0 to m - 1 do
    FChgOrderRev[FChgOrder[i]] := i;
end;

function TfrmCompareMerge.ChgViewCount: Integer;
begin
  Result := 0;
  if not Assigned(FChgIdx) then Exit;
  if FChgFiltered or (FChgSort <> 0) then
    Result := Length(FChgOrder)
  else
    Result := FChgIdx.Count;
end;

function TfrmCompareMerge.ChgViewIndex(AView: Integer): Integer;
begin
  if FChgFiltered or (FChgSort <> 0) then
    Result := FChgOrder[AView]
  else
    Result := AView;
end;

function TfrmCompareMerge.ChgIsSel(const AKey: Int64): Boolean;
begin
  if FChgSelAll then
    Result := not (Assigned(FChgUnsel) and FChgUnsel.ContainsKey(AKey))
  else
    Result := Assigned(FChgSel) and FChgSel.ContainsKey(AKey);
end;

function TfrmCompareMerge.ChgSelectedCount: Integer;
begin
  Result := 0;
  if not Assigned(FChgIdx) then Exit;
  if FChgSelAll then
    Result := FChgIdx.Count - FChgUnsel.Count
  else if Assigned(FChgSel) then
    Result := FChgSel.Count;
end;

function TfrmCompareMerge.ChgAllChecked: Boolean;
var
  i: Integer;
  R: THciRec;
begin
  if FChgFiltered then
  begin
    Result := ChgViewCount > 0;
    for i := 0 to ChgViewCount - 1 do
    begin
      R := FChgIdx.Get(ChgViewIndex(i));
      if not ChgIsSel(HciSpanKey(R.Ln0, R.Ln1)) then
        Exit(False);
    end;
    Exit;
  end;
  Result := FChgSelAll and Assigned(FChgUnsel) and (FChgUnsel.Count = 0) and
    Assigned(FChgIdx) and (FChgIdx.Count > 0);
end;

procedure TfrmCompareMerge.ChgClearSelection;
begin
  FChgSelAll := False;
  if Assigned(FChgSel) then
    FChgSel.Clear;
  if Assigned(FChgUnsel) then
    FChgUnsel.Clear;
end;

procedure TfrmCompareMerge.ChgToggleAt(AItem: Integer);
var
  R: THciRec;
  Key: Int64;
begin
  if not ChgRecAt(AItem, R) then Exit;
  Key := HciSpanKey(R.Ln0, R.Ln1);
  if FChgSelAll then
  begin
    if FChgUnsel.ContainsKey(Key) then
      FChgUnsel.Remove(Key)
    else
      FChgUnsel.Add(Key, 0);
  end
  else if FChgSel.ContainsKey(Key) then
    FChgSel.Remove(Key)
  else
    FChgSel.Add(Key, 0);
end;

procedure TfrmCompareMerge.ChgSelectAllToggle;
var
  i: Integer;
  TurnOn: Boolean;
  R: THciRec;
  Key: Int64;
begin
  if FChgFiltered then
  begin
    TurnOn := not ChgAllChecked;
    for i := 0 to ChgViewCount - 1 do
    begin
      R := FChgIdx.Get(ChgViewIndex(i));
      Key := HciSpanKey(R.Ln0, R.Ln1);
      if FChgSelAll then
      begin
        if TurnOn then
          FChgUnsel.Remove(Key)
        else
          FChgUnsel.AddOrSetValue(Key, 0);
      end
      else if TurnOn then
        FChgSel.AddOrSetValue(Key, 0)
      else
        FChgSel.Remove(Key);
    end;
  end
  else if ChgAllChecked then
    ChgClearSelection
  else
  begin
    FChgSelAll := True;
    if Assigned(FChgSel) then
      FChgSel.Clear;
    if Assigned(FChgUnsel) then
      FChgUnsel.Clear;
  end;
  if Assigned(FlbChangedLines) then
    FlbChangedLines.Invalidate;
  ApplyHistToolCaptions;
end;

procedure TfrmCompareMerge.lbChangedLinesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ix: Integer;
begin
  if Button <> mbLeft then Exit;
  if X >= cChgCheckW then Exit;
  if not Assigned(FlbChangedLines) then Exit;
  ix := FlbChangedLines.ItemAtPos(Point(X, Y), True);
  if ix < 0 then Exit;
  ChgToggleAt(ix);
  FChgSuppressNav := True;
  FlbChangedLines.Invalidate;
  ApplyHistToolCaptions;
end;

function TfrmCompareMerge.JrnRawAt(ARow: Integer): string;
begin
  Result := '';
  if Assigned(FJournalRaws) and (ARow >= 0) and (ARow < FJournalRaws.Count) then
    Result := FJournalRaws[ARow];
end;

function TfrmCompareMerge.JrnHasEvents: Boolean;
var
  i: Integer;
begin
  Result := False;
  if not Assigned(FJournalRaws) then Exit;
  for i := 0 to FJournalRaws.Count - 1 do
    if FJournalRaws[i] <> '' then
      Exit(True);
end;

function TfrmCompareMerge.JrnAllChecked: Boolean;
var
  i, n: Integer;
begin
  Result := False;
  n := 0;
  if not Assigned(FJournalRaws) or not Assigned(FJrnSel) then Exit;
  for i := 0 to FJournalRaws.Count - 1 do
    if FJournalRaws[i] <> '' then
    begin
      Inc(n);
      if not FJrnSel.ContainsKey(FJournalRaws[i]) then Exit;
    end;
  Result := n > 0;
end;

procedure TfrmCompareMerge.JrnToggleRow(ARow: Integer);
var
  S: string;
begin
  S := JrnRawAt(ARow);
  if (S = '') or not Assigned(FJrnSel) then Exit;
  if FJrnSel.ContainsKey(S) then
    FJrnSel.Remove(S)
  else
    FJrnSel.Add(S, 0);
  ApplyHistToolCaptions;
end;

procedure TfrmCompareMerge.JrnSelectAllToggle;
var
  i: Integer;
  TurnOn: Boolean;
begin
  if not Assigned(FJournalRaws) or not Assigned(FJrnSel) then Exit;
  TurnOn := not JrnAllChecked;
  FJrnSel.Clear;
  if TurnOn then
    for i := 0 to FJournalRaws.Count - 1 do
      if FJournalRaws[i] <> '' then
        FJrnSel.AddOrSetValue(FJournalRaws[i], 0);
  if Assigned(FsgJournal) then
    FsgJournal.Invalidate;
  ApplyHistToolCaptions;
end;

function TfrmCompareMerge.HistKeepLine(const Line: string): Boolean;
var
  Utf: UTF8String;
  L0, L1: Integer;
  Tg: Byte;
begin
  if FAnonDrop then
    Exit(not HistIsAnonDropLine(Line));
  if Assigned(FRewriteDrop) then
    Exit(not FRewriteDrop.ContainsKey(Line));
  Utf := UTF8Encode(Line);
  if (Utf = '') or not HciParseLine(PAnsiChar(Utf), Length(Utf), L0, L1, Tg) then
    Exit(True);
  Result := not ChgIsSel(HciSpanKey(L0, L1));
end;

procedure TfrmCompareMerge.RewriteJournal(const AConfirmMsg: string);
var
  LogPath: string;
  Removed: Integer;
begin
  if FClosing or Assigned(FHistoryReloadThread) then Exit;
  if Trim(FDefaultLeft) = '' then Exit;
  LogPath := FFHistoryJournalPath(FDefaultLeft);
  if not FileExists(LogPath) then
  begin
    FastFileMessageBox(PChar(TrText('Hist.DeleteNone')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if FastFileMessageBox(PChar(AConfirmMsg), PChar(TrText('Hist.ClearTitle')),
       MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) <> IDYES then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    StopChgThreads;
    if not FFHistoryRewrite(LogPath, HistKeepLine, Removed) then
    begin
      FastFileMessageBox(
        PChar(Format(TrText('Hist.DeleteFailed: %s'), [SysErrorMessage(GetLastError)])),
        PChar(Caption), MB_OK or MB_ICONERROR);
      Exit;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  ChgClearSelection;
  if Assigned(FJrnSel) then
    FJrnSel.Clear;
  ReloadHistoryMemo(True);
  if FAnonDrop then
    FastFileMessageBox(PChar(Format(TrText('Anon.Hist.Deleted'), [Removed])),
      PChar(Caption), MB_OK or MB_ICONINFORMATION);
end;

procedure TfrmCompareMerge.DeleteCheckedChangedLines;
var
  n: Integer;
begin
  n := ChgSelectedCount;
  if n < 1 then
  begin
    FastFileMessageBox(PChar(TrText('Hist.DeleteNone')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  FRewriteDrop := nil;
  RewriteJournal(Format(TrText('Hist.DeleteSelConfirm: %d'), [n]));
end;

procedure TfrmCompareMerge.DeleteCheckedJournalEvents;
var
  n: Integer;
begin
  if not Assigned(FJrnSel) or (FJrnSel.Count < 1) then
  begin
    FastFileMessageBox(PChar(TrText('Hist.DeleteNone')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  n := FJrnSel.Count;
  FRewriteDrop := FJrnSel;
  try
    RewriteJournal(Format(TrText('Hist.DeleteEventsConfirm: %d'), [n]));
  finally
    FRewriteDrop := nil;
  end;
end;

{ ANON (bloco) / ANOL (linha com antes/depois) e as notas UNDO/REDO marcadas como
  descaracterizacao. Com FAnonDropLine > 0 so' os eventos que incluem essa linha. }
function TfrmCompareMerge.HistIsAnonDropLine(const Line: string): Boolean;
var
  Parts: TStringList;
  op, Legacy: string;
  L0, L1: Integer;
begin
  Result := False;
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(Line, Parts);
    if Parts.Count < 3 then Exit;
    op := UpperCase(Trim(Parts[1]));
    if (op = 'UNDO') or (op = 'REDO') then
    begin
      if FAnonDropLine <> 0 then Exit;
      Legacy := TrText('Anon.HistoryNote');
      if Pos('%', Legacy) > 0 then
        Legacy := Copy(Legacy, 1, Pos('%', Legacy) - 1);
      Result := StartsText(ANON_HIST_NOTE_MARK, TrimLeft(Parts[2])) or
        ((Trim(Legacy) <> '') and StartsText(Legacy, TrimLeft(Parts[2])));
      Exit;
    end;
    if (op <> 'ANON') and (op <> 'ANOL') then Exit;
    if FAnonDropLine = 0 then Exit(True);
    HistParseJournalLineSpan(Line, L0, L1);
    Result := (L0 > 0) and (FAnonDropLine >= L0) and (FAnonDropLine <= L1);
  finally
    Parts.Free;
  end;
end;

procedure TfrmCompareMerge.DeleteAnonJournalEvents(ALine: Integer);
begin
  FAnonDrop := True;
  FAnonDropLine := ALine;
  try
    if ALine > 0 then
      RewriteJournal(Format(TrText('Anon.Hist.DeleteLineConfirm'), [ALine]))
    else
      RewriteJournal(TrText('Anon.Hist.DeleteAllConfirm'));
  finally
    FAnonDrop := False;
    FAnonDropLine := 0;
  end;
end;

{ Controlos C0 (SOH, STX, ...) e DEL viram espaco; TAB/CR/LF ficam, fazem parte do layout. }
function HistPrintableText(const S: string): string;
var
  i: Integer;
  C: Char;
begin
  Result := S;
  for i := 1 to Length(Result) do
  begin
    C := Result[i];
    if ((C < #32) and (C <> #9) and (C <> #10) and (C <> #13)) or (C = #127) then
      Result[i] := ' ';
  end;
end;

function TfrmCompareMerge.PickHistExportPath(out ACsv: Boolean): string;
var
  Dlg: TSaveDialog;
begin
  Result := '';
  ACsv := False;
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := TrText('Hist.ExportFilter');
    Dlg.FilterIndex := 1;
    Dlg.DefaultExt := 'txt';
    Dlg.FileName := 'session-history';
    Dlg.Options := [ofOverwritePrompt, ofPathMustExist];
    if not Dlg.Execute then Exit;
    Result := Dlg.FileName;
    ACsv := (Dlg.FilterIndex = 2) or SameText(ExtractFileExt(Result), '.csv');
  finally
    Dlg.Free;
  end;
end;

procedure TfrmCompareMerge.ExportChangedLines;
var
  Path: string;
  Csv, OnlyChecked, UseCurrent: Boolean;
  i, g, nOut: Integer;
  R: THciRec;
  SW: TStreamWriter;

  procedure WriteRec(const ARec: THciRec);
  var
    When: string;
  begin
    When := HciFormatStamp(ARec.LastTs);
    if Csv then
      SW.WriteLine(Format('%d;%d;%s;%d;%d;%d;%d;%d',
        [ARec.Ln0, ARec.Ln1, When, ARec.Cnt[1], ARec.Cnt[2], ARec.Cnt[3], ARec.Cnt[4], ARec.Cnt[5]]))
    else
      SW.WriteLine(Trim(ChgItemText(ARec) + '  ' + When));
    Inc(nOut);
  end;

begin
  if not Assigned(FChgIdx) or (FChgIdx.Count < 1) then
  begin
    FastFileMessageBox(PChar(TrText('Hist.ExportEmpty')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  OnlyChecked := ChgSelectedCount > 0;
  UseCurrent := (not OnlyChecked) and Assigned(FlbChangedLines) and (FlbChangedLines.ItemIndex >= 0);
  Path := PickHistExportPath(Csv);
  if Path = '' then Exit;
  nOut := 0;
  SW := TStreamWriter.Create(Path, False, TEncoding.UTF8);
  try
    if Csv then
      SW.WriteLine(TrText('Hist.ExportCsvHeader'));
    if UseCurrent then
    begin
      if ChgRecAt(FlbChangedLines.ItemIndex, R) then
        WriteRec(R);
    end
    else
      for i := 0 to ChgViewCount - 1 do
      begin
        g := ChgViewIndex(i);
        R := FChgIdx.Get(g);
        if OnlyChecked and not ChgIsSel(HciSpanKey(R.Ln0, R.Ln1)) then
          Continue;
        WriteRec(R);
      end;
  finally
    SW.Free;
  end;
  if nOut < 1 then
    FastFileMessageBox(PChar(TrText('Hist.ExportEmpty')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION)
  else
    ShowGeneratedFileDialog(Path, nOut);
end;

function TfrmCompareMerge.BuildJournalText(AForAi: Boolean): string;
var
  i, j, nSkip: Integer;
  AnyChecked, Take, Saw: Boolean;
  Block, Cell: string;
  SL: TStringList;

  function CellText(ARow: Integer): string;
  begin
    Result := '';
    if not Assigned(FsgJournal) or (ARow < 0) or (ARow >= FsgJournal.RowCount) then Exit;
    if FsgJournal.ColCount > 1 then
      Result := FsgJournal.Cells[1, ARow]
    else
      Result := FsgJournal.Cells[0, ARow];
  end;

begin
  Result := '';
  if not Assigned(FJournalRaws) then Exit;
  AnyChecked := Assigned(FJrnSel) and (FJrnSel.Count > 0);
  Saw := False;
  nSkip := 0;
  SL := TStringList.Create;
  try
    i := 0;
    while i < FJournalRaws.Count do
    begin
      if FJournalRaws[i] = '' then
      begin
        Inc(i);
        Continue;
      end;
      Take := False;
      if AnyChecked then
        Take := FJrnSel.ContainsKey(FJournalRaws[i])
      else if (FJournalGridSelLine >= 0) then
        Take := False
      else
        Take := True;
      j := i + 1;
      Block := CellText(i);
      while j < FJournalRaws.Count do
      begin
        if FJournalRaws[j] <> '' then Break;
        Cell := CellText(j);
        if Cell = cHistSpacerRow then
        begin
          Inc(j);
          Continue;
        end;
        if Cell <> '' then
          Block := Block + #13#10 + Cell;
        Inc(j);
      end;
      if (not AnyChecked) and (FJournalGridSelLine >= i) and (FJournalGridSelLine < j) then
        Take := True;
      if Take and (Block <> '') then
      begin
        if AForAi and (Length(SL.Text) + Length(Block) > cHistAiMaxChars) then
          Inc(nSkip)
        else
        begin
          SL.Add(Block);
          SL.Add('');
          Saw := True;
        end;
      end;
      i := j;
    end;
    Result := HistPrintableText(Trim(SL.Text));
    if AForAi and (nSkip > 0) then
      Result := Result + #13#10 + Format(TrText('Hist.AskAI.More: %d'), [nSkip]);
    if not Saw then
      Result := '';
  finally
    SL.Free;
  end;
end;

procedure TfrmCompareMerge.ExportJournalEvents;
var
  Path, Body: string;
  Csv: Boolean;
  SW: TStreamWriter;
begin
  Body := BuildJournalText(False);
  if Body = '' then
  begin
    FastFileMessageBox(PChar(TrText('Hist.ExportEmpty')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  Path := PickHistExportPath(Csv);
  if Path = '' then Exit;
  SW := TStreamWriter.Create(Path, False, TEncoding.UTF8);
  try
    if Csv then
    begin
      SW.WriteLine(TrText('Hist.Tool.Export'));
      SW.WriteLine('"' + StringReplace(StringReplace(Body, '"', '""', [rfReplaceAll]),
        #13#10, ' | ', [rfReplaceAll]) + '"');
    end
    else
      SW.Write(Body);
  finally
    SW.Free;
  end;
  ShowGeneratedFileDialog(Path);
end;

function TfrmCompareMerge.PromptHistAiGoal(out AGoal: string): Boolean;
var
  Frm: TForm;
  Lbl: TLabel;
  Memo: TMemo;
  Footer: TPanel;
  BtnOk, BtnCancel: TButton;
begin
  Result := False;
  AGoal := '';
  Frm := TForm.CreateNew(nil);
  try
    Frm.BorderStyle := bsDialog;
    Frm.Position := poOwnerFormCenter;
    Frm.Caption := TrText('Hist.AskAI.GoalTitle');
    Frm.Font.Name := 'Segoe UI';
    Frm.Font.Size := 9;
    Frm.Color := clBtnFace;
    FfPrepareDialog(Frm, 460, 240);
    Footer := TPanel.Create(Frm);
    Footer.Parent := Frm;
    Footer.Align := alBottom;
    Footer.Height := 44;
    Footer.BevelOuter := bvNone;
    Footer.ParentBackground := False;
    Footer.Color := clBtnFace;
    BtnCancel := TButton.Create(Frm);
    BtnCancel.Parent := Footer;
    BtnCancel.Caption := TrText('Cancel');
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;
    BtnCancel.SetBounds(Footer.ClientWidth - 100, 8, 88, 28);
    BtnCancel.Anchors := [akTop, akRight];
    BtnOk := TButton.Create(Frm);
    BtnOk.Parent := Footer;
    BtnOk.Caption := TrText('OK');
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;
    BtnOk.SetBounds(BtnCancel.Left - 96, 8, 88, 28);
    BtnOk.Anchors := [akTop, akRight];
    Lbl := TLabel.Create(Frm);
    Lbl.Parent := Frm;
    Lbl.Caption := TrText('Hist.AskAI.GoalLabel');
    Lbl.AutoSize := False;
    Lbl.WordWrap := True;
    Lbl.SetBounds(12, 12, Frm.ClientWidth - 24, 36);
    Memo := TMemo.Create(Frm);
    Memo.Parent := Frm;
    Memo.ScrollBars := ssVertical;
    Memo.WantReturns := True;
    Memo.SetBounds(12, 52, Frm.ClientWidth - 24, Frm.ClientHeight - Footer.Height - 64);
    if Frm.ShowModal <> mrOk then Exit;
    AGoal := Trim(Memo.Text);
    Result := AGoal <> '';
    if not Result then
      FastFileMessageBox(PChar(TrText('Hist.AskAI.NeedGoal')), PChar(Caption),
        MB_OK or MB_ICONINFORMATION);
  finally
    Frm.Free;
  end;
end;

procedure TfrmCompareMerge.AskAiAboutHistory(const AContext: string);
var
  Goal, Prompt: string;
begin
  if Trim(AContext) = '' then
  begin
    FastFileMessageBox(PChar(TrText('Hist.AskAI.NeedSel')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if not PromptHistAiGoal(Goal) then Exit;
  PipelineSetFact('session_history_file', Trim(FDefaultLeft));
  PipelineRememberUser(TrText('Hist.AskAI.PipelineNote') + ' ' + Goal);
  Prompt := Format(TrText('Hist.AskAI.QuestionTemplate'),
    [Goal, ExtractFileName(Trim(FDefaultLeft)), AContext]);
  AssistantPrefillQuestion(Prompt);
end;

procedure TfrmCompareMerge.ChgToolClick(Sender: TObject);
var
  R: THciRec;
  Ctx: string;
  i, g, nSkip: Integer;
  SL: TStringList;
  Line: string;
begin
  if not (Sender is TButton) then Exit;
  case TButton(Sender).Tag of
    1: ChgSelectAllToggle;
    2: DeleteCheckedChangedLines;
    3: ShowHistSortMenu(1, FbtnChgSort);
    4: ExportChangedLines;
    5:
      begin
        SL := TStringList.Create;
        try
          nSkip := 0;
          if Assigned(FChgIdx) then
            for i := 0 to ChgViewCount - 1 do
            begin
              g := ChgViewIndex(i);
              R := FChgIdx.Get(g);
              if (ChgSelectedCount > 0) and not ChgIsSel(HciSpanKey(R.Ln0, R.Ln1)) then
                Continue;
              if (ChgSelectedCount = 0) and Assigned(FlbChangedLines) and
                 (FlbChangedLines.ItemIndex >= 0) then
              begin
                if not ChgRecAt(FlbChangedLines.ItemIndex, R) then Break;
                Line := Trim(ChgItemText(R) + '  ' + HciFormatStamp(R.LastTs));
                SL.Add(Line);
                Break;
              end;
              Line := Trim(ChgItemText(R) + '  ' + HciFormatStamp(R.LastTs));
              if Length(SL.Text) + Length(Line) > cHistAiMaxChars then
                Inc(nSkip)
              else
                SL.Add(Line);
            end;
          Ctx := Trim(SL.Text);
          if nSkip > 0 then
            Ctx := Ctx + #13#10 + Format(TrText('Hist.AskAI.More: %d'), [nSkip]);
        finally
          SL.Free;
        end;
        AskAiAboutHistory(Ctx);
      end;
  end;
end;

procedure TfrmCompareMerge.ShowHistSortMenu(ATarget: Integer; ABtn: TButton);

  procedure AddItem(AMode: Integer; const AKey: string; ACur: Integer);
  var
    Mi: TMenuItem;
  begin
    Mi := TMenuItem.Create(FpmHistSort);
    Mi.Caption := TrText(AKey);
    Mi.Tag := AMode;
    Mi.RadioItem := True;
    Mi.GroupIndex := 1;
    Mi.Checked := AMode = ACur;
    Mi.OnClick := HistSortMenuClick;
    FpmHistSort.Items.Add(Mi);
  end;

var
  P: TPoint;
begin
  if not Assigned(ABtn) then Exit;
  if not Assigned(FpmHistSort) then
    FpmHistSort := TPopupMenu.Create(Self);
  FpmHistSort.Items.Clear;
  FSortMenuTarget := ATarget;
  if ATarget = 1 then
  begin
    AddItem(1, 'Hist.SortMenu.DateDesc', FChgSort);
    AddItem(2, 'Hist.SortMenu.DateAsc', FChgSort);
    AddItem(0, 'Hist.SortMenu.LineAsc', FChgSort);
    AddItem(3, 'Hist.SortMenu.LineDesc', FChgSort);
  end
  else
  begin
    AddItem(1, 'Hist.SortMenu.DateDesc', FJrnSort);
    AddItem(2, 'Hist.SortMenu.DateAsc', FJrnSort);
    AddItem(0, 'Hist.SortMenu.LogOrder', FJrnSort);
  end;
  P := ABtn.ClientToScreen(Point(0, ABtn.Height));
  FpmHistSort.Popup(P.X, P.Y);
end;

procedure TfrmCompareMerge.HistSortMenuClick(Sender: TObject);
var
  Ln: Integer;
  R: THciRec;
begin
  if not (Sender is TMenuItem) then Exit;
  if FSortMenuTarget = 1 then
  begin
    Ln := 0;
    if Assigned(FlbChangedLines) and ChgRecAt(FlbChangedLines.ItemIndex, R) then
      Ln := R.Ln0;
    FChgSort := TMenuItem(Sender).Tag;
    RebuildChgOrder;
    FChgPage := 0;
    RefreshChangedLinesView;
    if Ln > 0 then
      ChgSelectLine(Ln, False);
  end
  else
  begin
    FJrnSort := TMenuItem(Sender).Tag;
    RequestApplyJournalDisplayMode;
  end;
  ApplyHistToolCaptions;
end;

procedure TfrmCompareMerge.CreateHistDateRow(AParent: TWinControl; out AFrom, ATo: TsDateEdit;
  out ALblFrom, ALblTo: TLabel; out AClr: TButton);

  function NewLbl: TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.AutoSize := False;
    Result.Layout := tlCenter;
    Result.Transparent := True;
    Result.Visible := False;
  end;

  function NewDate: TsDateEdit;
  begin
    Result := TsDateEdit.Create(Self);
    Result.Parent := AParent;
    Result.ShowHint := True;
    Result.ShowTodayBtn := True;
    Result.DefaultToday := False;
    Result.CheckOnExit := False;
    Result.Visible := False;
    Result.OnChange := edtHistDateChange;
    Result.OnKeyDown := edtHistDateKeyDown;
  end;

var
  Y, M, D: Word;
begin
  ALblFrom := NewLbl;
  AFrom := NewDate;
  ALblTo := NewLbl;
  ATo := NewDate;
  AClr := TButton.Create(Self);
  AClr.Parent := AParent;
  AClr.Caption := '×';
  AClr.ShowHint := True;
  AClr.Visible := False;
  AClr.OnClick := HistDateClearClick;
  { Periodo inicial: do primeiro dia do mes atual ate' hoje. }
  DecodeDate(Date, Y, M, D);
  FDateSyncing := True;
  try
    AFrom.Date := EncodeDate(Y, M, 1);
    ATo.Date := Date;
  finally
    FDateSyncing := False;
  end;
  AFrom.Color := $00DDFFFF;
  ATo.Color := $00DDFFFF;
end;

function TfrmCompareMerge.LayoutHistDateRow(AX, AY, AW, AH: Integer; ALblFrom, ALblTo: TLabel;
  AFrom, ATo: TsDateEdit; AClr: TButton): Integer;
var
  wF, wT, wE, x, cw: Integer;
  Bmp: TBitmap;
begin
  Result := 0;
  if not Assigned(AFrom) then Exit;
  if AW <= 0 then
  begin
    ALblFrom.Visible := False;
    ALblTo.Visible := False;
    AFrom.Visible := False;
    ATo.Visible := False;
    AClr.Visible := False;
    Exit;
  end;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(ALblFrom.Font);
    wF := Bmp.Canvas.TextWidth(ALblFrom.Caption) + 3;
    wT := Bmp.Canvas.TextWidth(ALblTo.Caption) + 3;
  finally
    Bmp.Free;
  end;
  cw := AH;
  wE := Max(70, (AW - wF - wT - cw - 8) div 2);
  x := AX;
  ALblFrom.SetBounds(x, AY, wF, AH);
  Inc(x, wF);
  AFrom.SetBounds(x, AY, wE, AH);
  Inc(x, wE + 4);
  ALblTo.SetBounds(x, AY, wT, AH);
  Inc(x, wT);
  ATo.SetBounds(x, AY, wE, AH);
  Inc(x, wE + 4);
  AClr.SetBounds(x, AY, cw, AH);
  ALblFrom.Visible := True;
  ALblTo.Visible := True;
  AFrom.Visible := True;
  ATo.Visible := True;
  AClr.Visible := True;
  Result := AH + 2;
end;

function TfrmCompareMerge.HistDateQueryOf(ADFrom, ADTo: TsDateEdit): THistDateQuery;

  function DayOf(DE: TsDateEdit): Integer;
  var
    Y, M, D: Word;
  begin
    Result := 0;
    if DE.Date = NullDate then Exit;
    DecodeDate(DE.Date, Y, M, D);
    Result := Y * 10000 + M * 100 + D;
  end;

var
  t: Integer;
begin
  Result := Default(THistDateQuery);
  Result.DayFrom := DayOf(ADFrom);
  Result.DayTo := DayOf(ADTo);
  if (Result.DayFrom <> 0) and (Result.DayTo <> 0) and (Result.DayFrom > Result.DayTo) then
  begin
    t := Result.DayFrom;
    Result.DayFrom := Result.DayTo;
    Result.DayTo := t;
  end;
  Result.Active := (Result.DayFrom <> 0) or (Result.DayTo <> 0);
  Result.Valid := True;
end;

procedure TfrmCompareMerge.edtHistDateChange(Sender: TObject);
var
  Ln: Integer;
  R: THciRec;
  Q: THistDateQuery;
  DFrom, DTo: TsDateEdit;

  procedure Tint(DE: TsDateEdit);
  begin
    if (DE.Date = NullDate) and (Pos(' ', DE.Text) = 0) and (Trim(DE.Text) <> '') then
      DE.Color := $00DDDDFF
    else if DE.Date <> NullDate then
      DE.Color := $00DDFFFF
    else
      DE.Color := clWindow;
  end;

begin
  if FDateSyncing or not (Sender is TsDateEdit) then Exit;
  if (Sender = FdeChgFrom) or (Sender = FdeChgTo) then
  begin
    DFrom := FdeChgFrom;
    DTo := FdeChgTo;
  end
  else if (Sender = FdeJrnFrom) or (Sender = FdeJrnTo) then
  begin
    DFrom := FdeJrnFrom;
    DTo := FdeJrnTo;
  end
  else
    Exit;
  { Escolher so' o "De" filtra esse dia; o "Ate'" pode depois alargar o intervalo. }
  if (Sender = DFrom) and (DFrom.Date <> NullDate) and (DTo.Date = NullDate) then
  begin
    FDateSyncing := True;
    try
      DTo.Date := DFrom.Date;
    finally
      FDateSyncing := False;
    end;
  end;
  Tint(DFrom);
  Tint(DTo);
  Q := HistDateQueryOf(DFrom, DTo);
  if DFrom = FdeChgFrom then
  begin
    Ln := 0;
    if Assigned(FlbChangedLines) and ChgRecAt(FlbChangedLines.ItemIndex, R) then
      Ln := R.Ln0;
    FChgDateQ := Q;
    RebuildChgOrder;
    FChgPage := 0;
    RefreshChangedLinesView;
    if (Ln = 0) or not ChgSelectLine(Ln, False) then
      if Assigned(FlbChangedLines) then
        FlbChangedLines.ItemIndex := -1;
  end
  else
  begin
    FJrnDateQ := Q;
    { A vista por linha raramente tem eventos no periodo: filtrar sobre toda a sessao. }
    if Q.Active and Assigned(FchkHistShowAll) and not FchkHistShowAll.Checked then
      FchkHistShowAll.Checked := True
    else
      RequestApplyJournalDisplayMode;
  end;
  ApplyHistToolCaptions;
end;

procedure TfrmCompareMerge.edtHistDateKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Sender is TsDateEdit) and
     (TsDateEdit(Sender).Date <> NullDate) then
  begin
    TsDateEdit(Sender).Date := NullDate;
    Key := 0;
  end;
end;

procedure TfrmCompareMerge.HistDateClearClick(Sender: TObject);
var
  DFrom, DTo: TsDateEdit;
begin
  if Sender = FbtnChgDateClr then
  begin
    DFrom := FdeChgFrom;
    DTo := FdeChgTo;
  end
  else
  begin
    DFrom := FdeJrnFrom;
    DTo := FdeJrnTo;
  end;
  if not Assigned(DFrom) then Exit;
  FDateSyncing := True;
  try
    DFrom.Date := NullDate;
  finally
    FDateSyncing := False;
  end;
  DTo.Date := NullDate;
  edtHistDateChange(DTo);
end;

procedure TfrmCompareMerge.ApplyHistDateFilterHints;

  procedure Apply(LF, LT: TLabel; DF, DT: TsDateEdit; B: TButton; const AHint: string);
  begin
    if not Assigned(DF) then Exit;
    LF.Caption := TrText('Hist.DateFilter.From');
    LT.Caption := TrText('Hist.DateFilter.To');
    DF.Hint := TrText('Hist.DateFilter.FromHint') + #13#10 + AHint;
    DT.Hint := TrText('Hist.DateFilter.ToHint') + #13#10 + AHint;
    LF.Hint := DF.Hint;
    LT.Hint := DT.Hint;
    LF.ShowHint := True;
    LT.ShowHint := True;
    B.Hint := TrText('Hist.DateFilter.ClearHint');
  end;

begin
  Apply(FlblChgFrom, FlblChgTo, FdeChgFrom, FdeChgTo, FbtnChgDateClr,
    TrText('Hist.DateFilter.ChgHint'));
  Apply(FlblJrnFrom, FlblJrnTo, FdeJrnFrom, FdeJrnTo, FbtnJrnDateClr,
    TrText('Hist.DateFilter.JrnHint'));
end;

function AddHistCtxItem(AParent: TMenuItem; const AKey: string; ATag: Integer;
  AClick: TNotifyEvent; AEnabled: Boolean = True): TMenuItem;
begin
  Result := TMenuItem.Create(AParent);
  if AKey = '-' then
    Result.Caption := '-'
  else
    Result.Caption := TrText(AKey);
  Result.Tag := ATag;
  Result.OnClick := AClick;
  Result.Enabled := AEnabled;
  AParent.Add(Result);
end;

function TfrmCompareMerge.ChgLinesText(AOnlyChecked: Boolean): string;
var
  i: Integer;
  R: THciRec;
  SB: TStringBuilder;
begin
  Result := '';
  if not Assigned(FChgIdx) then Exit;
  SB := TStringBuilder.Create;
  try
    for i := 0 to ChgViewCount - 1 do
    begin
      R := FChgIdx.Get(ChgViewIndex(i));
      if AOnlyChecked and not ChgIsSel(HciSpanKey(R.Ln0, R.Ln1)) then
        Continue;
      SB.Append(Trim(ChgItemText(R) + '  ' + HciFormatStamp(R.LastTs))).Append(#13#10);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TfrmCompareMerge.ChgCtxPopup(Sender: TObject);
var
  P: TPoint;
  ix, m: Integer;
  R: THciRec;
  HasSel, HasItems: Boolean;
  Root, Sub, Mi: TMenuItem;
const
  SortKeys: array[0..3] of string = ('Hist.SortMenu.LineAsc', 'Hist.SortMenu.DateDesc',
    'Hist.SortMenu.DateAsc', 'Hist.SortMenu.LineDesc');
  SortOrder: array[0..3] of Integer = (1, 2, 0, 3);
begin
  FpmChgCtx.Items.Clear;
  if not Assigned(FlbChangedLines) then Exit;
  { Botao direito sobre um item: passa a ser o selecionado (e mostra o evento). }
  P := FlbChangedLines.ScreenToClient(Mouse.CursorPos);
  ix := FlbChangedLines.ItemAtPos(P, True);
  if (ix >= 0) and (ix <> FlbChangedLines.ItemIndex) then
  begin
    FlbChangedLines.ItemIndex := ix;
    lbChangedLinesClick(FlbChangedLines);
  end;
  HasSel := ChgRecAt(FlbChangedLines.ItemIndex, R);
  HasItems := ChgViewCount > 0;
  Root := FpmChgCtx.Items;
  AddHistCtxItem(Root, 'Hist.Ctx.CopyItem', 1, ChgCtxClick, HasSel);
  AddHistCtxItem(Root, 'Hist.Ctx.CopyLineNo', 2, ChgCtxClick, HasSel);
  AddHistCtxItem(Root, 'Hist.Ctx.CopyChecked', 3, ChgCtxClick, ChgSelectedCount > 0);
  AddHistCtxItem(Root, 'Hist.Ctx.CopyAll', 4, ChgCtxClick, HasItems);
  AddHistCtxItem(Root, '-', 0, nil);
  AddHistCtxItem(Root, 'Hist.Ctx.ShowInHistory', 10, ChgCtxClick, HasSel);
  AddHistCtxItem(Root, 'Hist.Ctx.GotoLine', 11, ChgCtxClick,
    HasItems and Assigned(FedtChgGoto) and FedtChgGoto.Visible);
  AddHistCtxItem(Root, '-', 0, nil);
  AddHistCtxItem(Root, 'Hist.Ctx.ToggleCheck', 20, ChgCtxClick, HasSel);
  if ChgAllChecked then
    AddHistCtxItem(Root, 'Hist.Ctx.UncheckAll', 21, ChgCtxClick, HasItems)
  else
    AddHistCtxItem(Root, 'Hist.Ctx.CheckAll', 21, ChgCtxClick, HasItems);
  AddHistCtxItem(Root, 'Hist.Ctx.DeleteChecked', 22, ChgCtxClick, ChgSelectedCount > 0);
  Sub := AddHistCtxItem(Root, 'Anon.Hist.DeleteMenu', 0, nil, HasItems);
  Mi := AddHistCtxItem(Sub, 'Anon.Hist.DeleteLine', 40, ChgCtxClick, HasSel);
  if HasSel then
    Mi.Caption := Format(TrText('Anon.Hist.DeleteLine'), [R.Ln0]);
  AddHistCtxItem(Sub, 'Anon.Hist.DeleteAll', 41, ChgCtxClick);
  AddHistCtxItem(Root, '-', 0, nil);
  Sub := AddHistCtxItem(Root, 'Hist.Ctx.Sort', 0, nil, HasItems);
  for m in SortOrder do
  begin
    Mi := AddHistCtxItem(Sub, SortKeys[m], m, ChgCtxSortClick);
    Mi.RadioItem := True;
    Mi.GroupIndex := 1;
    Mi.Checked := m = FChgSort;
  end;
  AddHistCtxItem(Root, 'Hist.Ctx.ClearDateFilter', 32, ChgCtxClick, Assigned(FbtnChgDateClr));
  AddHistCtxItem(Root, '-', 0, nil);
  AddHistCtxItem(Root, 'Hist.Ctx.Export', 30, ChgCtxClick, HasItems);
  AddHistCtxItem(Root, 'Hist.Ctx.AskAI', 31, ChgCtxClick, HasItems);
end;

procedure TfrmCompareMerge.ChgCtxClick(Sender: TObject);
var
  R: THciRec;
  HasSel: Boolean;
  S: string;
begin
  if not (Sender is TMenuItem) or not Assigned(FlbChangedLines) then Exit;
  HasSel := ChgRecAt(FlbChangedLines.ItemIndex, R);
  case TMenuItem(Sender).Tag of
    1: if HasSel then
         Clipboard.AsText := Trim(ChgItemText(R) + '  ' + HciFormatStamp(R.LastTs));
    2: if HasSel then
       begin
         if R.Ln1 > R.Ln0 then
           Clipboard.AsText := IntToStr(R.Ln0) + '-' + IntToStr(R.Ln1)
         else
           Clipboard.AsText := IntToStr(R.Ln0);
       end;
    3, 4:
      begin
        S := ChgLinesText(TMenuItem(Sender).Tag = 3);
        if S <> '' then
          Clipboard.AsText := S;
      end;
    10: lbChangedLinesClick(FlbChangedLines);
    11: if Assigned(FedtChgGoto) and FedtChgGoto.CanFocus then
        begin
          FedtChgGoto.SetFocus;
          FedtChgGoto.SelectAll;
        end;
    20: if HasSel then
        begin
          ChgToggleAt(FlbChangedLines.ItemIndex);
          FlbChangedLines.Invalidate;
          ApplyHistToolCaptions;
        end;
    21: ChgSelectAllToggle;
    22: DeleteCheckedChangedLines;
    40: if HasSel then DeleteAnonJournalEvents(R.Ln0);
    41: DeleteAnonJournalEvents(0);
    30: ExportChangedLines;
    31: ChgToolClick(FbtnChgAI);
    32: if Assigned(FbtnChgDateClr) then FbtnChgDateClr.Click;
  end;
end;

procedure TfrmCompareMerge.ChgCtxSortClick(Sender: TObject);
begin
  FSortMenuTarget := 1;
  HistSortMenuClick(Sender);
end;

function TfrmCompareMerge.JrnCellText(ARow: Integer): string;
begin
  Result := '';
  if not Assigned(FsgJournal) or (ARow < 0) or (ARow >= FsgJournal.RowCount) then Exit;
  if FsgJournal.ColCount > 1 then
    Result := FsgJournal.Cells[1, ARow]
  else
    Result := FsgJournal.Cells[0, ARow];
  if Result = cHistSpacerRow then
    Result := '';
end;

function TfrmCompareMerge.JrnEventStart(ARow: Integer): Integer;
begin
  Result := ARow;
  while (Result >= 0) and (JrnRawAt(Result) = '') do
    Dec(Result);
end;

function TfrmCompareMerge.JrnEventText(ARow: Integer): string;
var
  s, j: Integer;
  Cell: string;
begin
  s := JrnEventStart(ARow);
  if s < 0 then
    Exit(HistPrintableText(JrnCellText(ARow)));
  Result := JrnCellText(s);
  j := s + 1;
  while Assigned(FsgJournal) and (j < FsgJournal.RowCount) and (JrnRawAt(j) = '') do
  begin
    Cell := JrnCellText(j);
    if Cell <> '' then
      Result := Result + #13#10 + Cell;
    Inc(j);
  end;
  Result := HistPrintableText(Result);
end;

function TfrmCompareMerge.JrnAllEventsText: string;
var
  SaveSel: TDictionary<string, Byte>;
  SaveLine: Integer;
begin
  { BuildJournalText sem marcas nem linha selecionada devolve todos os eventos visiveis. }
  SaveSel := FJrnSel;
  SaveLine := FJournalGridSelLine;
  FJrnSel := nil;
  FJournalGridSelLine := -1;
  try
    Result := BuildJournalText(False);
  finally
    FJrnSel := SaveSel;
    FJournalGridSelLine := SaveLine;
  end;
end;

procedure TfrmCompareMerge.JrnCtxPopup(Sender: TObject);
var
  P: TPoint;
  c, r: Integer;
  HasEv, HasRow: Boolean;
  Root, Sub, Mi: TMenuItem;
  m: Integer;
const
  SortKeys: array[0..2] of string = ('Hist.SortMenu.LogOrder', 'Hist.SortMenu.DateDesc',
    'Hist.SortMenu.DateAsc');
  SortOrder: array[0..2] of Integer = (1, 2, 0);
begin
  FpmJrnCtx.Items.Clear;
  if not Assigned(FsgJournal) then Exit;
  P := FsgJournal.ScreenToClient(Mouse.CursorPos);
  FsgJournal.MouseToCell(P.X, P.Y, c, r);
  if r >= 0 then
  begin
    FJrnPopRow := r;
    if (FJournalGridSelLine <> r) and Assigned(FJournalLineNums) and (r < FJournalLineNums.Count) then
    begin
      FJournalGridSelLine := r;
      FsgJournal.Invalidate;
      SyncChangedLinesFromJournalRow(r);
      RequestJournalJumpFromLine(r);
    end;
  end
  else
    FJrnPopRow := FJournalGridSelLine;
  HasRow := JrnCellText(FJrnPopRow) <> '';
  HasEv := JrnEventStart(FJrnPopRow) >= 0;
  Root := FpmJrnCtx.Items;
  Mi := AddHistCtxItem(Root, 'Hist.Ctx.ShowDetail', 5, JrnCtxClick, HasEv and HasRow);
  Mi.Default := True;
  AddHistCtxItem(Root, '-', 0, nil);
  AddHistCtxItem(Root, 'Hist.Ctx.CopyEvent', 1, JrnCtxClick, HasEv);
  AddHistCtxItem(Root, 'Hist.Ctx.CopyRow', 2, JrnCtxClick, HasRow);
  AddHistCtxItem(Root, 'Hist.Ctx.CopyChecked', 3, JrnCtxClick,
    Assigned(FJrnSel) and (FJrnSel.Count > 0));
  AddHistCtxItem(Root, 'Hist.Ctx.CopyAll', 4, JrnCtxClick, JrnHasEvents);
  AddHistCtxItem(Root, '-', 0, nil);
  AddHistCtxItem(Root, 'Hist.Ctx.ToggleCheck', 20, JrnCtxClick, HasEv);
  if JrnAllChecked then
    AddHistCtxItem(Root, 'Hist.Ctx.UncheckAll', 21, JrnCtxClick, JrnHasEvents)
  else
    AddHistCtxItem(Root, 'Hist.Ctx.CheckAll', 21, JrnCtxClick, JrnHasEvents);
  AddHistCtxItem(Root, 'Hist.Ctx.DeleteChecked', 22, JrnCtxClick,
    Assigned(FJrnSel) and (FJrnSel.Count > 0));
  Sub := AddHistCtxItem(Root, 'Anon.Hist.DeleteMenu', 0, nil, JrnHasEvents);
  Mi := AddHistCtxItem(Sub, 'Anon.Hist.DeleteLine', 40, JrnCtxClick, FJrnViewLine > 0);
  if FJrnViewLine > 0 then
    Mi.Caption := Format(TrText('Anon.Hist.DeleteLine'), [FJrnViewLine]);
  AddHistCtxItem(Sub, 'Anon.Hist.DeleteAll', 41, JrnCtxClick);
  AddHistCtxItem(Root, '-', 0, nil);
  Sub := AddHistCtxItem(Root, 'Hist.Ctx.Sort', 0, nil, JrnHasEvents);
  for m in SortOrder do
  begin
    Mi := AddHistCtxItem(Sub, SortKeys[m], m, JrnCtxSortClick);
    Mi.RadioItem := True;
    Mi.GroupIndex := 1;
    Mi.Checked := m = FJrnSort;
  end;
  if Assigned(FchkHistShowAll) then
  begin
    Mi := AddHistCtxItem(Root, 'Hist.Ctx.ShowAll', 33, JrnCtxClick, FchkHistShowAll.Enabled);
    Mi.Checked := FchkHistShowAll.Checked;
  end;
  AddHistCtxItem(Root, 'Hist.Ctx.ClearDateFilter', 32, JrnCtxClick, Assigned(FbtnJrnDateClr));
  AddHistCtxItem(Root, '-', 0, nil);
  AddHistCtxItem(Root, 'Hist.Ctx.Export', 30, JrnCtxClick, JrnHasEvents);
  AddHistCtxItem(Root, 'Hist.Ctx.AskAI', 31, JrnCtxClick, JrnHasEvents);
end;

procedure TfrmCompareMerge.JrnCtxClick(Sender: TObject);
var
  S: string;
  st: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  S := '';
  case TMenuItem(Sender).Tag of
    1: S := JrnEventText(FJrnPopRow);
    2: S := HistPrintableText(JrnCellText(FJrnPopRow));
    3: S := BuildJournalText(False);
    4: S := JrnAllEventsText;
    5: ShowJournalLineDetail(FJrnPopRow);
    20:
      begin
        st := JrnEventStart(FJrnPopRow);
        if st >= 0 then
        begin
          JrnToggleRow(st);
          if Assigned(FsgJournal) then FsgJournal.Invalidate;
        end;
      end;
    21: JrnSelectAllToggle;
    22: DeleteCheckedJournalEvents;
    40: if FJrnViewLine > 0 then DeleteAnonJournalEvents(FJrnViewLine);
    41: DeleteAnonJournalEvents(0);
    30: ExportJournalEvents;
    31: AskAiAboutHistory(BuildJournalText(True));
    32: if Assigned(FbtnJrnDateClr) then FbtnJrnDateClr.Click;
    33: if Assigned(FchkHistShowAll) then
          FchkHistShowAll.Checked := not FchkHistShowAll.Checked;
  end;
  if S <> '' then
    Clipboard.AsText := S;
end;

procedure TfrmCompareMerge.JrnCtxSortClick(Sender: TObject);
begin
  FSortMenuTarget := 2;
  HistSortMenuClick(Sender);
end;

procedure HistBuildDetailItem(const ARaw, ASummary: string; out AItem: THistDetailItem);
var
  Parts: TStringList;
  op: string;
  OldRuns, NewRuns: THistDiffRuns;
  RawMax, i: Integer;
begin
  AItem := Default(THistDetailItem);
  AItem.Summary := ASummary;
  Parts := TStringList.Create;
  try
    HistSplitPipeFields(ARaw, Parts);
    if Parts.Count > 0 then
      AItem.Stamp := HistSanitizeText(Parts[0]);
    if Parts.Count > 1 then
      op := UpperCase(HistSanitizeText(Parts[1]));
    if op = 'ANOL' then
      AItem.Op := TrText('Anon.Hist.Tag')
    else
      AItem.Op := op;
    if Parts.Count > 2 then
      AItem.Line := StrToIntDef(HistSanitizeText(Parts[2]), 0);
    if (op = 'EDT') or (op = 'INS') or (op = 'DEL') or (op = 'ANOL') then
    begin
      AItem.HasLines := True;
      if Parts.Count > 3 then
        AItem.Before := HistPrintableText(Parts[3]);
      if Parts.Count > 4 then
        AItem.After := HistPrintableText(Parts[4]);
      RawMax := Max(Length(AItem.Before), Length(AItem.After));
      if (RawMax = cHistJournalLegacyExcerptMax) or (RawMax >= PrefHistoryLineExcerptMax) then
        AItem.TruncLimit := RawMax;
      if (AItem.Before <> '') and (AItem.After <> '') and (AItem.Before <> AItem.After) then
      begin
        SetLength(OldRuns, 0);
        SetLength(NewRuns, 0);
        HistDiffSpans(AItem.Before, AItem.After, 0, 0, 0, OldRuns, NewRuns);
        SetLength(AItem.BeforeRuns, Length(OldRuns));
        for i := 0 to High(OldRuns) do
        begin
          AItem.BeforeRuns[i].Start0 := OldRuns[i].Start0;
          AItem.BeforeRuns[i].Len := OldRuns[i].Len;
        end;
        SetLength(AItem.AfterRuns, Length(NewRuns));
        for i := 0 to High(NewRuns) do
        begin
          AItem.AfterRuns[i].Start0 := NewRuns[i].Start0;
          AItem.AfterRuns[i].Len := NewRuns[i].Len;
        end;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

{ Abre o detalhe com todos os eventos visiveis; ficam pre-selecionados os marcados
  (se o evento clicado estiver entre eles) ou so' o clicado. }
procedure TfrmCompareMerge.ShowJournalLineDetail(ARow: Integer);
var
  st, i, n, StartIx: Integer;
  Items: THistDetailItems;
  UseChecked: Boolean;
begin
  if FClosing or not Assigned(FsgJournal) or not Assigned(FJournalRaws) then Exit;
  if JrnCellText(ARow) = '' then Exit;
  st := JrnEventStart(ARow);
  if st < 0 then Exit;
  UseChecked := Assigned(FJrnSel) and FJrnSel.ContainsKey(JrnRawAt(st));
  SetLength(Items, 0);
  n := 0;
  StartIx := 0;
  for i := 0 to FJournalRaws.Count - 1 do
  begin
    if FJournalRaws[i] = '' then Continue;
    SetLength(Items, n + 1);
    HistBuildDetailItem(FJournalRaws[i], JrnEventText(i), Items[n]);
    if i = st then
    begin
      StartIx := n;
      Items[n].Selected := True;
    end
    else
      Items[n].Selected := UseChecked and FJrnSel.ContainsKey(FJournalRaws[i]);
    Inc(n);
  end;
  if n = 0 then Exit;
  ShowHistLineDetailDialog(Self, Trim(FDefaultLeft), Items, StartIx);
end;

procedure TfrmCompareMerge.sgJournalDblClick(Sender: TObject);
var
  P: TPoint;
  ACol, ARow: Integer;
begin
  if FClosing or not Assigned(FsgJournal) then Exit;
  P := FsgJournal.ScreenToClient(Mouse.CursorPos);
  FsgJournal.MouseToCell(P.X, P.Y, ACol, ARow);
  if (ARow < 0) or ((ACol = 0) and (FsgJournal.ColCount > 1)) then Exit;
  ShowJournalLineDetail(ARow);
end;

procedure TfrmCompareMerge.sgJournalKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and Assigned(FsgJournal) then
  begin
    Key := 0;
    if FJournalGridSelLine >= 0 then
      ShowJournalLineDetail(FJournalGridSelLine)
    else
      ShowJournalLineDetail(FsgJournal.Row);
  end;
end;

procedure TfrmCompareMerge.JrnToolClick(Sender: TObject);
begin
  if not (Sender is TButton) then Exit;
  case TButton(Sender).Tag of
    1: JrnSelectAllToggle;
    2: DeleteCheckedJournalEvents;
    3: ShowHistSortMenu(2, FbtnJrnSort);
    4: ExportJournalEvents;
    5: AskAiAboutHistory(BuildJournalText(True));
  end;
end;

procedure TfrmCompareMerge.SortJournalBlocks(Buf: TStringList);
var
  n, i, g0, gi, nAll, nKeep, nShown: Integer;
  Idx: TArray<Integer>;
  Keys: TArray<string>;
  Starts, Counts: TArray<Integer>;
  NewBuf, NewEx, NewRaw: TStringList;
  NewNums, NewTags: TList;

  procedure AppendRow(AIdx: Integer);
  begin
    NewBuf.Add(Buf[AIdx]);
    if Assigned(FJournalExcerpts) and (AIdx < FJournalExcerpts.Count) then
      NewEx.Add(FJournalExcerpts[AIdx])
    else
      NewEx.Add('');
    if AIdx < FJournalRaws.Count then
      NewRaw.Add(FJournalRaws[AIdx])
    else
      NewRaw.Add('');
    if Assigned(FJournalLineNums) and (AIdx < FJournalLineNums.Count) then
      NewNums.Add(FJournalLineNums[AIdx])
    else
      NewNums.Add(nil);
    if Assigned(FJournalTags) and (AIdx < FJournalTags.Count) then
      NewTags.Add(FJournalTags[AIdx])
    else
      NewTags.Add(nil);
  end;

begin
  if ((FJrnSort = 0) and not FJrnDateQ.Active) or (Buf = nil) or (Buf.Count < 2) then Exit;
  if not Assigned(FJournalRaws) or (FJournalRaws.Count <> Buf.Count) then Exit;
  n := 0;
  i := 1;
  while i < Buf.Count do
  begin
    if Buf[i] = cHistSpacerRow then
    begin
      Inc(i);
      Continue;
    end;
    g0 := i;
    Inc(i);
    while (i < Buf.Count) and (Buf[i] <> cHistSpacerRow) do
      Inc(i);
    SetLength(Starts, n + 1);
    SetLength(Counts, n + 1);
    SetLength(Keys, n + 1);
    SetLength(Idx, n + 1);
    Starts[n] := g0;
    Counts[n] := i - g0;
    Idx[n] := n;
    if (g0 < FJournalRaws.Count) and (Length(FJournalRaws[g0]) >= 10) and
       CharInSet(FJournalRaws[g0][1], ['0'..'9']) then
      Keys[n] := Copy(FJournalRaws[g0], 1, 19)
    else
      Keys[n] := '';
    Inc(n);
  end;
  if (n < 2) and not FJrnDateQ.Active then Exit;
  nAll := 0;
  nKeep := 0;
  for gi := 0 to n - 1 do
  begin
    if Keys[gi] <> '' then
      Inc(nAll);
    if FJrnDateQ.Active and (Keys[gi] <> '') and
       not HciStampMatches(FJrnDateQ, HciStampFromText(Keys[gi])) then
      Continue;
    Idx[nKeep] := gi;
    Inc(nKeep);
  end;
  SetLength(Idx, nKeep);
  if FJrnSort <> 0 then
    TArray.Sort<Integer>(Idx, TComparer<Integer>.Construct(
      function(const A, B: Integer): Integer
      begin
        if FJrnSort = 1 then
          Result := CompareStr(Keys[B], Keys[A])
        else
          Result := CompareStr(Keys[A], Keys[B]);
        if Result = 0 then
          Result := CompareValue(Starts[A], Starts[B]);
      end));
  nShown := 0;
  for gi := 0 to nKeep - 1 do
    if Keys[Idx[gi]] <> '' then
      Inc(nShown);
  NewBuf := TStringList.Create;
  NewEx := TStringList.Create;
  NewRaw := TStringList.Create;
  NewNums := TList.Create;
  NewTags := TList.Create;
  try
    AppendRow(0);
    if FJrnDateQ.Active then
      NewBuf[0] := NewBuf[0] + '   ' +
        Format(TrText('Hist.DateFilter.Shown: %d %d'), [nShown, nAll]);
    for gi := 0 to nKeep - 1 do
    begin
      if gi > 0 then
      begin
        NewBuf.Add(cHistSpacerRow);
        NewEx.Add('');
        NewRaw.Add('');
        NewNums.Add(nil);
        NewTags.Add(nil);
      end;
      for i := 0 to Counts[Idx[gi]] - 1 do
        AppendRow(Starts[Idx[gi]] + i);
    end;
    if FJrnDateQ.Active and (nShown = 0) then
    begin
      if FJrnDateQ.Valid then
        NewBuf.Add(TrText('Hist.DateFilter.NoMatch'))
      else
        NewBuf.Add(TrText('Hist.DateFilter.Invalid'));
      NewEx.Add('');
      NewRaw.Add('');
      NewNums.Add(nil);
      NewTags.Add(nil);
    end;
    Buf.Assign(NewBuf);
    if Assigned(FJournalExcerpts) then
      FJournalExcerpts.Assign(NewEx);
    FJournalRaws.Assign(NewRaw);
    if Assigned(FJournalLineNums) then
    begin
      FJournalLineNums.Clear;
      for i := 0 to NewNums.Count - 1 do
        FJournalLineNums.Add(NewNums[i]);
    end;
    if Assigned(FJournalTags) then
    begin
      FJournalTags.Clear;
      for i := 0 to NewTags.Count - 1 do
        FJournalTags.Add(NewTags[i]);
    end;
  finally
    NewBuf.Free;
    NewEx.Free;
    NewRaw.Free;
    NewNums.Free;
    NewTags.Free;
  end;
end;

procedure TfrmCompareMerge.lbChangedLinesClick(Sender: TObject);
var
  Ln0: Integer;
  R: THciRec;
begin
  if FChgSuppressNav then
  begin
    FChgSuppressNav := False;
    Exit;
  end;
  if FClosing or FSyncingChangedLines or not Assigned(FlbChangedLines) then Exit;
  if not ChgRecAt(FlbChangedLines.ItemIndex, R) then Exit;
  Ln0 := R.Ln0;
  if Ln0 < 1 then Exit;
  ClearHistJournalOverlay;
  if FHistShowAllJournal and Assigned(FchkHistShowAll) then
  begin
    FJournalPreviewHiliteIdx := Ln0 - 1;
    FchkHistShowAll.Checked := False;
  end;
  if (Ln0 - 1) < HistPreviewDataCount then
    HistPreviewJumpToDataRow(Ln0 - 1)
  else
  begin
    FJournalPreviewHiliteIdx := Ln0 - 1;
    if Assigned(FsgHist) then FsgHist.Invalidate;
    RequestApplyJournalDisplayMode;
  end;
end;

procedure TfrmCompareMerge.lbChangedLinesDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  R: THciRec;
  Has: Boolean;
  Txt, When: string;
  xWhen: Integer;
  RWhen: TRect;
begin
  C := FlbChangedLines.Canvas;
  Has := ChgRecAt(Index, R);
  C.Brush.Color := BrushForHistTag(R.LastTag);
  C.Font.Color := clBlack;
  C.FillRect(Rect);
  if not Has then Exit;
  if odSelected in State then
  begin
    C.Brush.Style := bsClear;
    C.Pen.Color := cHistSelInk;
    C.Pen.Width := 2;
    C.Rectangle(Rect.Left + 1, Rect.Top + 1, Rect.Right, Rect.Bottom);
    C.Pen.Width := 1;
    C.Brush.Style := bsSolid;
    C.Font.Style := [fsBold];
  end
  else
    C.Font.Style := [];
  DrawHistCheckBox(C, Rect, ChgIsSel(HciSpanKey(R.Ln0, R.Ln1)));
  C.Brush.Style := bsClear;
  C.Font.Color := clBlack;
  Txt := ChgItemText(R);
  xWhen := Rect.Left + cChgCheckW + 4;
  C.TextOut(xWhen, Rect.Top + 2, Txt);
  When := ChgFormatWhen(R.LastTs);
  if When = '' then Exit;
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := RGB(80, 80, 80);
  RWhen := Rect;
  RWhen.Left := xWhen;
  RWhen.Top := Rect.Bottom - FChgWhenH - 3;
  RWhen.Right := Rect.Right - 2;
  C.TextRect(RWhen, xWhen, RWhen.Top, When);
  C.Font.Assign(FlbChangedLines.Font);
end;

function TfrmCompareMerge.ChgFormatWhen(const ATs: Int64): string;
var
  S: string;
  Y, Mo, D, H, Mi: Word;
begin
  Result := '';
  if ATs <= 0 then Exit;
  S := IntToStr(ATs);
  if Length(S) < 14 then Exit;
  Y := StrToIntDef(Copy(S, 1, 4), 0);
  Mo := StrToIntDef(Copy(S, 5, 2), 0);
  D := StrToIntDef(Copy(S, 7, 2), 0);
  H := StrToIntDef(Copy(S, 9, 2), 0);
  Mi := StrToIntDef(Copy(S, 11, 2), 0);
  try
    Result := FormatDateTime('ddddd hh:nn', EncodeDate(Y, Mo, D) + EncodeTime(H, Mi, 0, 0));
  except
    Result := HciFormatStamp(ATs);
  end;
end;

procedure TfrmCompareMerge.RequestApplyJournalDisplayMode;
begin
  if FClosing or FApplyingJournalView then Exit;
  if not HandleAllocated then Exit;
  if FApplyJournalViewPosted then Exit;
  FApplyJournalViewPosted := True;
  PostMessage(Handle, WM_FF_APPLY_JOURNAL_VIEW, 0, 0);
end;

procedure TfrmCompareMerge.RequestJournalJumpFromCp(const ACp: Integer);
begin
  if FClosing then Exit;
  if not HandleAllocated then Exit;
  FPendingJournalJumpCp := ACp;
  if FJournalJumpPosted then Exit;
  FJournalJumpPosted := True;
  PostMessage(Handle, WM_FF_JOURNAL_JUMP, 0, 0);
end;

procedure TfrmCompareMerge.RequestJournalJumpFromLine(const ALineIx: Integer);
begin
  if FClosing then Exit;
  if not HandleAllocated then Exit;
  FPendingJournalJumpLine := ALineIx;
  FPendingJournalJumpCp := -1;
  if FJournalJumpPosted then Exit;
  FJournalJumpPosted := True;
  PostMessage(Handle, WM_FF_JOURNAL_JUMP, 0, 0);
end;

procedure TfrmCompareMerge.WMApplyJournalView(var Msg: TMessage);
begin
  FApplyJournalViewPosted := False;
  Msg.Result := 0;
  if FClosing then Exit;
  ApplyJournalDisplayMode;
end;

procedure TfrmCompareMerge.WMJournalJump(var Msg: TMessage);
begin
  FJournalJumpPosted := False;
  Msg.Result := 0;
  if FClosing then Exit;
  if FPendingJournalJumpCp < 0 then
    JournalJumpPreviewFromLine(FPendingJournalJumpLine)
  else
    JournalJumpPreviewFromCp(FPendingJournalJumpCp);
end;

procedure TfrmCompareMerge.ApplyJournalDisplayMode;
var
  i, k, g, wantLine, Ln0, Ln1, Tg, nEvents, nExact, idxTotal: Integer;
  Ex, S: string;
  R: THciRec;
  DispSL: TStringList;
  saveJC: TNotifyEvent;
  saveMU: TMouseEvent;
  any: Boolean;
  Buf: TStringList;

  function CacheRaw(AIdx: Integer): string;
  begin
    if Assigned(FJournalCacheRaws) and (AIdx >= 0) and (AIdx < FJournalCacheRaws.Count) then
      Result := FJournalCacheRaws[AIdx]
    else
      Result := '';
  end;

  procedure AddEventLine(const S: string; ALn0, ALn1, ATag: Integer;
    const AEx, ARaw: string);
  var
    T: string;
  begin
    T := S;
    if Copy(S, 1, 1) <> ' ' then
    begin
      if nEvents > 0 then
      begin
        Buf.Add(cHistSpacerRow);
        JournalMetaAdd(0, 0, '');
      end;
      Inc(nEvents);
      if (FJrnViewLine > 0) and (ALn1 > ALn0) then
        T := S + '  ' + Format(TrText('Hist.EventCoversLine: %d %d %d'),
          [ALn0, ALn1, FJrnViewLine]);
    end;
    Buf.Add(T);
    JournalMetaAdd(ALn0, ALn1, ATag, AEx, ARaw);
  end;

begin
  if FClosing or FApplyingJournalView then Exit;
  if not Assigned(mmoJournal) or not Assigned(FJournalCacheLines) then Exit;
  FApplyingJournalView := True;
  Buf := TStringList.Create;
  try
    if Assigned(FchkHistShowAll) then
    begin
      FchkHistShowAll.Caption := TrText('Hist.ShowAllJournal');
      FchkHistShowAll.Hint := TrText('Hist.ShowAllJournalHint');
      FHistShowAllJournal := FchkHistShowAll.Checked;
    end;

    JournalMetaClear;
    FJrnViewLine := 0;

    if FJournalCacheLines.Count = 0 then
    begin
      Buf.Add(TrText('No session history file yet. Edits will append here.'));
      JournalMetaAdd(0, 0, '');
    end
    else if FHistShowAllJournal then
    begin
      Buf.Add('');
      JournalMetaAdd(0, 0, '');
      nEvents := 0;
      for i := 0 to FJournalCacheLines.Count - 1 do
      begin
        Ln0 := Integer(FJournalCacheLineNums[i]);
        Ln1 := Integer(FJournalCacheLineEnds[i]);
        Tg := Integer(FJournalCacheTags[i]);
        Ex := FJournalCacheExcerpts[i];
        AddEventLine(FJournalCacheLines[i], Ln0, Ln1, Tg, Ex, CacheRaw(i));
      end;
      Buf[0] := Format(TrText('Hist.JournalHeaderAll: %d'), [nEvents]);
    end
    else if FJournalPreviewHiliteIdx < 0 then
    begin
      Buf.Add(TrText('Hist.SelectLineHint'));
      JournalMetaAdd(0, 0, '');
    end
    else
    begin
      wantLine := FJournalPreviewHiliteIdx + 1;
      FJrnViewLine := wantLine;
      any := False;
      Buf.Add('');
      JournalMetaAdd(0, 0, '');
      nEvents := 0;
      if (FChgEvtLine = wantLine) and Assigned(FChgEvtRaw) and (FChgEvtRaw.Count > 0) then
      begin
        { Eventos lidos do diario inteiro (a cache so' guarda o fim do ficheiro). }
        DispSL := TStringList.Create;
        try
          for i := 0 to FChgEvtRaw.Count - 1 do
          begin
            S := FChgEvtRaw[i];
            HistParseJournalLineSpan(S, Ln0, Ln1);
            if Ln0 <= 0 then Continue;
            Tg := HistParseJournalTag(S);
            Ex := HistParseJournalExcerpt(S);
            DispSL.Clear;
            FormatHistJournalLinesForDisplay(S, DispSL);
            if DispSL.Count = 0 then
              DispSL.Add('');
            for k := 0 to DispSL.Count - 1 do
              if k = 0 then
                AddEventLine(DispSL[k], Ln0, Ln1, Tg, Ex, S)
              else
                AddEventLine(DispSL[k], Ln0, Ln1, Tg, '', '');
            any := True;
          end;
        finally
          DispSL.Free;
        end;
        if FChgEvtRaw.Count >= cHciMaxEventsOnDemand then
        begin
          Buf.Add(Format(TrText('Hist.LineEventsCapped: %d'), [cHciMaxEventsOnDemand]));
          JournalMetaAdd(0, 0, '');
        end;
      end
      else
      begin
        nExact := 0;
        for i := 0 to FJournalCacheLines.Count - 1 do
        begin
          Ln0 := Integer(FJournalCacheLineNums[i]);
          Ln1 := Integer(FJournalCacheLineEnds[i]);
          if Ln0 <= 0 then Continue;
          if (wantLine < Ln0) or (wantLine > Ln1) then Continue;
          Tg := Integer(FJournalCacheTags[i]);
          Ex := FJournalCacheExcerpts[i];
          if (Ln0 = wantLine) and (Copy(FJournalCacheLines[i], 1, 1) <> ' ') then
            Inc(nExact);
          AddEventLine(FJournalCacheLines[i], Ln0, Ln1, Tg, Ex, CacheRaw(i));
          any := True;
        end;
        { Mais eventos no indice do que na cache: ler o resto do diario em segundo plano. }
        idxTotal := 0;
        if Assigned(FChgIdx) then
        begin
          g := FChgIdx.LowerBound(wantLine);
          while g < FChgIdx.Count do
          begin
            R := FChgIdx.Get(g);
            if R.Ln0 <> wantLine then Break;
            Inc(idxTotal, HciTotalEvents(R));
            Inc(g);
          end;
        end;
        if (idxTotal > nExact) and
           not ((FChgEvtLine = wantLine) and Assigned(FChgEvtRaw)) then
        begin
          ChgRequestLineEvents(wantLine);
          Buf.Add(Format(TrText('Hist.LoadingLineEvents: %d'), [idxTotal]));
          JournalMetaAdd(0, 0, '');
        end;
      end;
      Buf[0] := Format(TrText('Hist.JournalHeaderLine: %d %d'), [wantLine, nEvents]);
      if not any then
      begin
        Buf.Add(Format(TrText('Hist.NoEventsForLine: %d'), [wantLine]));
        JournalMetaAdd(wantLine, wantLine, 0, '');
      end;
    end;

    SortJournalBlocks(Buf);

    FJournalMaxChars := 0;
    for i := 0 to Buf.Count - 1 do
      if Length(Buf[i]) > FJournalMaxChars then
        FJournalMaxChars := Length(Buf[i]);

    { Assign outside skin/RichEdit paint path; grid colorido + memo oculto (meta/sync). }
    JournalListEnterMutation(saveJC, saveMU);
    try
      mmoJournal.Lines.BeginUpdate;
      try
        mmoJournal.Lines.Assign(Buf);
      finally
        mmoJournal.Lines.EndUpdate;
      end;
      EnsureJournalGrid;
      if Assigned(FsgJournal) then
      begin
        if Buf.Count < 1 then
        begin
          FsgJournal.RowCount := 1;
          FsgJournal.Cells[0, 0] := '';
          if FsgJournal.ColCount > 1 then
            FsgJournal.Cells[1, 0] := '';
        end
        else
        begin
          FsgJournal.RowCount := Buf.Count;
          for i := 0 to Buf.Count - 1 do
          begin
            if FsgJournal.ColCount > 1 then
            begin
              FsgJournal.Cells[0, i] := '';
              FsgJournal.Cells[1, i] := Buf[i];
            end
            else
              FsgJournal.Cells[0, i] := Buf[i];
            if Buf[i] = cHistSpacerRow then
              FsgJournal.RowHeights[i] := cHistSpacerRowH
            else if FsgJournal.RowHeights[i] <> FsgJournal.DefaultRowHeight then
              FsgJournal.RowHeights[i] := FsgJournal.DefaultRowHeight;
          end;
        end;
        UpdateJournalColWidth;
        FsgJournal.LeftCol := FsgJournal.FixedCols;
        FJournalGridSelLine := -1;
        FsgJournal.Invalidate;
      end;
      RebuildChangedLinesList;
    finally
      JournalListLeaveMutation(saveJC, saveMU);
    end;
  finally
    Buf.Free;
    FApplyingJournalView := False;
  end;
end;

function HistJournalQuoteFragTag(const ALine: string; const AQuoteStart, ALineTag: Integer): Integer;
var
  LowLine: string;
  ArrowPos, p: Integer;
begin
  Result := ALineTag;
  if Result = 0 then Result := 1;
  LowLine := AnsiLowerCase(ALine);

  if (Pos('antes:', LowLine) > 0) or (Pos('before:', LowLine) > 0) or
     (Pos('vorher:', LowLine) > 0) or (Pos('prima:', LowLine) > 0) or
     (Pos('przed:', LowLine) > 0) or (Pos('pred:', LowLine) > 0) or
     (Pos('exclu', LowLine) > 0) or (Pos('deleted:', LowLine) > 0) or
     (Pos('removed:', LowLine) > 0) or (Pos('removido:', LowLine) > 0) or
     (Pos('eliminat', LowLine) > 0) or (Pos('entfernt:', LowLine) > 0) then
  begin
    Result := 3;
    Exit;
  end;
  if (Pos('depois:', LowLine) > 0) or (Pos('after:', LowLine) > 0) or
     (Pos('nachher:', LowLine) > 0) or (Pos('dopo:', LowLine) > 0) or
     (Pos('appended:', LowLine) > 0) or (Pos('acrescent', LowLine) > 0) or
     (Pos('inserted:', LowLine) > 0) or (Pos('inserid', LowLine) > 0) or
     (Pos('ajout', LowLine) > 0) or (Pos('eingef', LowLine) > 0) then
  begin
    Result := 2;
    Exit;
  end;

  ArrowPos := Pos('->', ALine);
  if ArrowPos > 0 then
  begin
    p := 1;
    while p <= Length(ALine) do
    begin
      if ALine[p] = '"' then
      begin
        if p = AQuoteStart then
        begin
          if p < ArrowPos then
            Result := 3
          else
            Result := 2;
          Exit;
        end;
        Inc(p);
        while (p <= Length(ALine)) and (ALine[p] <> '"') do
          Inc(p);
      end;
      Inc(p);
    end;
  end;

  case ALineTag of
    2: Result := 2;
    3: Result := 3;
    4: Result := 4;
    5: Result := 5;
  else
    Result := 1;
  end;
end;

procedure TfrmCompareMerge.SetJournalSelBackColor(const AColor: TColor);
begin
  { Intentionally empty: EM_SETCHARFORMAT/CHARFORMAT2 was unstable with PlainText
    RichEdit (ACCESS_VIOLATION). Colors come from PaintJournalOpGutter + preview. }
  if AColor = TColor($FFFFFFFF) then Exit;
end;

procedure TfrmCompareMerge.ColorizeJournalRichText;
begin
  { Disabled: see SetJournalSelBackColor. Gutter + preview grid keep the legend colors. }
  if FClosing then Exit;
end;

procedure TfrmCompareMerge.ClearHistJournalOverlay;
begin
  FHistOverlayActive := False;
  FHistOverlayIdx := -1;
  FHistOverlayTag := 0;
  FHistOverlayText := '';
  if Assigned(FsgHist) then
    FsgHist.Invalidate;
end;

procedure TfrmCompareMerge.EnsureJournalLeftGutterMargin;
begin
  { No-op with TMemo (was RichEdit EM_SETMARGINS). }
end;

procedure TfrmCompareMerge.PaintJournalOpGutter;
begin
  { Disabled: custom GDI paint raced with AlphaControls WM_PAINT on the journal
    HWND and contributed to ACCESS_VIOLATION. Preview grid keeps line colors. }
end;

function TfrmCompareMerge.HistPreviewCellText(const DataIdx: Integer): string;
begin
  if FHistOverlayActive and (DataIdx = FHistOverlayIdx) and (FHistOverlayText <> '') then
  begin
    Result := FHistOverlayText;
    Exit;
  end;
  if (DataIdx >= 0) and Assigned(FHistPaged) then
    Result := FHistPaged.GetLineText(DataIdx)
  else if (DataIdx >= 0) and Assigned(FHistPreviewLines) and (DataIdx < FHistPreviewLines.Count) then
    Result := FHistPreviewLines[DataIdx]
  else
    Result := '';
end;

procedure TfrmCompareMerge.LoadJournalIntoListBox(const JournalPath: string; AllowPump: Boolean);
var
  Keep: TStringList;
  i, firstIdx, k, Tg, LnStart, LnEnd: Integer;
  S, Ex: string;
  F: TFileStream;
  sz, start: Int64;
  DispSL: TStringList;
begin
  if FClosing then Exit;

  if (JournalPath = '') or (not FileExists(JournalPath)) then
  begin
    JournalCacheClear;
    JournalCacheAdd(TrText('No session history file yet. Edits will append here.'), 0, 0, 0, '');
    FJournalPreviewHiliteIdx := -1;
    ApplyJournalDisplayMode;
    Exit;
  end;

  Keep := TStringList.Create;
  try
    F := TFileStream.Create(JournalPath, fmOpenRead or fmShareDenyNone);
    try
      sz := F.Size;
    finally
      F.Free;
    end;
    if sz <= Int64(cHistJournalTailBytes) then
      StreamJournalTailLinesIntoList(JournalPath, 0, Keep, @FClosing, AllowPump)
    else
    begin
      start := sz - Min(sz, Int64(cHistJournalTailBytes));
      StreamJournalTailLinesIntoList(JournalPath, start, Keep, @FClosing, AllowPump);
    end;
    HistFilterKeepJournalLines(Keep, @FClosing);

    if FClosing then Exit;

    JournalCacheClear;
    firstIdx := 0;
    if Keep.Count > cHistJournalMaxLines then
      firstIdx := Keep.Count - cHistJournalMaxLines;
    for i := firstIdx to Keep.Count - 1 do
    begin
      if FClosing then Break;
      S := Keep[i];
      HistParseJournalLineSpan(S, LnStart, LnEnd);
      Tg := HistParseJournalTag(S);
      Ex := HistParseJournalExcerpt(S);
      DispSL := TStringList.Create;
      try
        FormatHistJournalLinesForDisplay(S, DispSL);
        if DispSL.Count = 0 then
          DispSL.Add('');
        for k := 0 to DispSL.Count - 1 do
        begin
          if k = 0 then
            JournalCacheAdd(DispSL[k], LnStart, LnEnd, Tg, Ex, S)
          else
            JournalCacheAdd(DispSL[k], LnStart, LnEnd, Tg, '');
        end;
      finally
        DispSL.Free;
      end;
    end;
    if FJournalCacheLines.Count = 0 then
      JournalCacheAdd(TrText('No session history file yet. Edits will append here.'), 0, 0, 0, '');
    FJournalPreviewHiliteIdx := -1;
    ApplyJournalDisplayMode;
  finally
    Keep.Free;
  end;
end;

procedure TfrmCompareMerge.BuildLegendLabels;
var
  L: TLabel;
  x, y, ci: Integer;
begin
  if Assigned(lblLegend.Parent) then
    for ci := lblLegend.Parent.ControlCount - 1 downto 0 do
      if (lblLegend.Parent.Controls[ci] is TLabel) and
        (TLabel(lblLegend.Parent.Controls[ci]).Tag = cFFDiffLegendLblTag) then
        lblLegend.Parent.Controls[ci].Free;

  lblLegend.Caption := ''; 
  x := lblLegend.Left;
  y := lblLegend.Top;

  L := TLabel.Create(Self);
  L.Parent := lblLegend.Parent;
  L.Left := x;
  L.Top := y;
  L.Tag := cFFDiffLegendLblTag;
  L.Caption := TrText('Legend:') + '  ';
  L.AutoSize := True;

  x := x + L.Width;
  L := TLabel.Create(Self);
  L.Parent := lblLegend.Parent;
  L.Left := x;
  L.Top := y;
  L.Tag := cFFDiffLegendLblTag;
  L.Caption := ' ' + TrText('green: equal') + ' ';
  L.ParentColor := False;
  L.Color := RGB(230, 253, 230);
  L.Transparent := False;
  L.Font.Color := clBlack;
  L.AutoSize := True;

  x := x + L.Width + 8;
  L := TLabel.Create(Self);
  L.Parent := lblLegend.Parent;
  L.Left := x;
  L.Top := y;
  L.Tag := cFFDiffLegendLblTag;
  L.Caption := ' ' + TrText('yellow: added (right)') + ' ';
  L.ParentColor := False;
  L.Color := RGB(255, 255, 230);
  L.Transparent := False;
  L.Font.Color := clBlack;
  L.AutoSize := True;

  x := x + L.Width + 8;
  L := TLabel.Create(Self);
  L.Parent := lblLegend.Parent;
  L.Left := x;
  L.Top := y;
  L.Tag := cFFDiffLegendLblTag;
  L.Caption := ' ' + TrText('red: removed (left)') + ' ';
  L.ParentColor := False;
  L.Color := RGB(255, 230, 230);
  L.Transparent := False;
  L.Font.Color := clBlack;
  L.AutoSize := True;

  x := x + L.Width + 8;
  L := TLabel.Create(Self);
  L.Parent := lblLegend.Parent;
  L.Left := x;
  L.Top := y;
  L.Tag := cFFDiffLegendLblTag;
  L.Caption := ' ' + TrText('blue: changed') + ' ';
  L.ParentColor := False;
  L.Color := $00FDE6E6; 
  L.Transparent := False;
  L.Font.Color := clBlack;
  L.AutoSize := True;
end;

procedure TfrmCompareMerge.EnsureHistLegendPaintBox;
begin
  if Assigned(FpbHistLegend) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FpbHistLegend := TPaintBox.Create(Self);
  FpbHistLegend.Parent := TabSheetHistory;
  FpbHistLegend.Height := cHistJournalLegendRowH;
  FpbHistLegend.OnPaint := pbHistLegendPaint;
end;

procedure TfrmCompareMerge.pbHistLegendPaint(Sender: TObject);
var
  C: TCanvas;
  x, h, w: Integer;
  R: TRect;
  procedure Chip(const Cap: string; Bg: TColor);
  begin
    w := C.TextWidth(Cap) + 12;
    R := Rect(x, 1, x + w, h - 2);
    C.Brush.Color := Bg;
    C.Brush.Style := bsSolid;
    C.Pen.Color := RGB(160, 160, 160);
    C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
    C.Brush.Style := bsClear;
    C.Font.Color := clBlack;
    C.TextOut(R.Left + 6, R.Top + 1, Cap);
    Inc(x, w + 6);
  end;
begin
  if not (Sender is TPaintBox) then Exit;
  C := TPaintBox(Sender).Canvas;
  h := TPaintBox(Sender).ClientHeight;
  C.Brush.Color := clBtnFace;
  C.FillRect(TPaintBox(Sender).ClientRect);
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 8;
  C.Font.Color := clWindowText;
  x := 0;
  C.Brush.Style := bsClear;
  C.TextOut(x, 2, TrText('Journal colors:') + ' ');
  Inc(x, C.TextWidth(TrText('Journal colors:') + ' ') + 4);
  Chip(' ' + TrText('HistLegend.Inserted') + ' (INS/BINS/BAUT) ', BrushForHistTag(2));
  Chip(' ' + TrText('HistLegend.Deleted') + ' (DEL/BDEL) ', BrushForHistTag(3));
  Chip(' ' + TrText('HistLegend.Edited') + ' (EDT) ', BrushForHistTag(1));
  Chip(' ' + TrText('HistLegend.UndoRedo') + ' ', BrushForHistTag(5));
  Chip(' ' + TrText('HistLegend.Equal') + ' ', BrushForHistTag(0));
end;

procedure TfrmCompareMerge.BuildHistoryJournalLegend;
var
  ci, x, y, cw: Integer;
begin
  if not Assigned(lblJournalHint) or not Assigned(lblJournalHint.Parent) then Exit;
  { Remover chips antigos (TLabel) se ainda existirem. }
  for ci := lblJournalHint.Parent.ControlCount - 1 downto 0 do
    if (lblJournalHint.Parent.Controls[ci] is TLabel) and
      (TLabel(lblJournalHint.Parent.Controls[ci]).Tag = cFFHistLegendLblTag) then
      lblJournalHint.Parent.Controls[ci].Free;

  EnsureHistLegendPaintBox;
  if not Assigned(FpbHistLegend) then Exit;
  x := lblJournalHint.Left;
  y := lblJournalHint.Top + lblJournalHint.Height + 2;
  cw := TabSheetHistory.ClientWidth - 16;
  if cw < 200 then cw := 200;
  FpbHistLegend.SetBounds(x, y, cw, cHistJournalLegendRowH);
  FpbHistLegend.BringToFront;
  FpbHistLegend.Invalidate;
end;

procedure TfrmCompareMerge.BuildHistoryFilePreview(AllowPump: Boolean);
begin
  if FClosing then Exit;
  if Trim(FDefaultLeft) = '' then Exit;
  if not FileExists(FDefaultLeft) then
  begin
    ClearHistPreviewListView;
    Exit;
  end;
  StartHistPagedPreview(FDefaultLeft);
end;

procedure TfrmCompareMerge.NoteMergeWroteDisk(const PathWritten: string);
var
  A, B: string;
begin
  A := Trim(FMainOpenPath);
  if (A = '') or SameText(A, SELECTTEXT) then Exit;
  if not FileExists(PathWritten) then Exit;
  B := ExpandFileName(A);
  if AnsiSameText(ExpandFileName(PathWritten), B) then
    FNeedMainReload := True;
end;

procedure TfrmCompareMerge.TouchHistoryIfSameFile(const PathTouched: string);
begin
  if Trim(FDefaultLeft) = '' then Exit;
  if not AnsiSameText(ExpandFileName(Trim(PathTouched)), ExpandFileName(Trim(FDefaultLeft))) then
    Exit;
  { Disparado ao fim de uma edicao na janela principal, que a seguir mostra o seu
    proprio overlay (reindexacao); o overlay e' partilhado, entao nao o usar aqui. }
  ReloadHistoryMemoEx(False, False, True);
end;

procedure TfrmCompareMerge.NotifyExternalHistoryTouch(const PathTouched: string);
begin
  TouchHistoryIfSameFile(PathTouched);
end;

function TfrmCompareMerge.ResolveHistPopupListView: TListView;
var
  WC: TWinControl;
  HW: HWND;
  P: TPoint;
begin
  Result := nil;
  if GetFocus <> 0 then
  begin
    WC := FindControl(GetFocus);
    while WC <> nil do
    begin
      if (WC is TListView) and ((WC = lvHistFile) or (WC = lvLeft) or (WC = lvRight)) then
      begin
        Result := TListView(WC);
        Exit;
      end;
      WC := WC.Parent;
    end;
  end;
  GetCursorPos(P);
  HW := WindowFromPoint(P);
  if HW <> 0 then
  begin
    WC := FindControl(HW);
    while WC <> nil do
    begin
      if (WC is TListView) and ((WC = lvHistFile) or (WC = lvLeft) or (WC = lvRight)) then
      begin
        Result := TListView(WC);
        Exit;
      end;
      WC := WC.Parent;
    end;
  end;
end;

function TfrmCompareMerge.ResolveHistTargetListView: TListView;
var
  C: TWinControl;
begin
  C := Screen.ActiveControl;
  if C = lvHistFile then
    Result := lvHistFile
  else if C = lvLeft then
    Result := lvLeft
  else if C = lvRight then
    Result := lvRight
  else if (FPopupHistTargetLV <> nil) and
    ((FPopupHistTargetLV = lvHistFile) or (FPopupHistTargetLV = lvLeft) or (FPopupHistTargetLV = lvRight)) then
    Result := FPopupHistTargetLV
  else if PageControl1.ActivePage = TabSheetHistory then
    Result := lvHistFile
  else
    Result := lvLeft;
end;

procedure TfrmCompareMerge.SyncDiffScrollPeerFrom(const Source: TListView);
begin
  DiffApplyTopIndexToPeer(Source);
end;

procedure TfrmCompareMerge.DiffApplyTopIndexToPeer(const Source: TListView);
var
  Peer: TListView;
  ti, mx: Integer;
begin
  if FClosing or not chkSyncScroll.Checked or FSyncingDiffScroll then Exit;
  { Nao exigir FHistoryLoaded: diff pode estar preenchido sem journal (ex. sem FDefaultLeft). }
  if (Source <> lvLeft) and (Source <> lvRight) then Exit;
  if not Source.HandleAllocated then Exit;
  if (lvLeft.Items.Count < 1) or (lvRight.Items.Count < 1) then Exit;
  if Source = lvRight then
    Peer := lvLeft
  else
    Peer := lvRight;
  if not Peer.HandleAllocated then Exit;
  ti := Integer(SendMessage(Source.Handle, LVM_GETTOPINDEX, 0, 0));
  if ti < 0 then ti := 0;
  mx := Peer.Items.Count - 1;
  if ti > mx then ti := mx;
  if Integer(SendMessage(Peer.Handle, LVM_GETTOPINDEX, 0, 0)) = ti then
  begin
    FDiffSyncLastTopL := Integer(SendMessage(lvLeft.Handle, LVM_GETTOPINDEX, 0, 0));
    if FDiffSyncLastTopL < 0 then FDiffSyncLastTopL := 0;
    FDiffSyncLastTopR := Integer(SendMessage(lvRight.Handle, LVM_GETTOPINDEX, 0, 0));
    if FDiffSyncLastTopR < 0 then FDiffSyncLastTopR := 0;
    Exit;
  end;
  FSyncingDiffScroll := True;
  try
    { Sem WM_SETREDRAW no par: com redraw=0 o ListView pode nao aplicar LVM_SETTOPINDEX/WM_VSCROLL. }
    FFListViewSetExactTopIndex(Peer, ti);
    FDiffSyncLastTopL := Integer(SendMessage(lvLeft.Handle, LVM_GETTOPINDEX, 0, 0));
    if FDiffSyncLastTopL < 0 then FDiffSyncLastTopL := 0;
    FDiffSyncLastTopR := Integer(SendMessage(lvRight.Handle, LVM_GETTOPINDEX, 0, 0));
    if FDiffSyncLastTopR < 0 then FDiffSyncLastTopR := 0;
  finally
    FSyncingDiffScroll := False;
  end;
end;

procedure TfrmCompareMerge.LvDiffLeftWndProc(var Message: TMessage);
begin
  if not Assigned(FOldLvLeftWndProc) then Exit;
  if FSyncingDiffScroll then
  begin
    FOldLvLeftWndProc(Message);
    Exit;
  end;
  if Message.Msg = WM_VSCROLL then
    case LoWord(Message.WParam) of
      SB_THUMBTRACK:
        FDiffThumbScroll := True;
      SB_THUMBPOSITION, SB_ENDSCROLL:
        FDiffThumbScroll := False;
    end;
  FOldLvLeftWndProc(Message);
  if FClosing then Exit;
  case Message.Msg of
    WM_VSCROLL:
      if chkSyncScroll.Checked then
      begin
        FDiffScrollLastSource := 1;
        DiffApplyTopIndexToPeer(lvLeft);
      end;
  end;
end;

procedure TfrmCompareMerge.LvDiffRightWndProc(var Message: TMessage);
begin
  if not Assigned(FOldLvRightWndProc) then Exit;
  if FSyncingDiffScroll then
  begin
    FOldLvRightWndProc(Message);
    Exit;
  end;
  if Message.Msg = WM_VSCROLL then
    case LoWord(Message.WParam) of
      SB_THUMBTRACK:
        FDiffThumbScroll := True;
      SB_THUMBPOSITION, SB_ENDSCROLL:
        FDiffThumbScroll := False;
    end;
  FOldLvRightWndProc(Message);
  if FClosing then Exit;
  case Message.Msg of
    WM_VSCROLL:
      if chkSyncScroll.Checked then
      begin
        FDiffScrollLastSource := 2;
        DiffApplyTopIndexToPeer(lvRight);
      end;
  end;
end;

procedure TfrmCompareMerge.HistApplyMemoScrollToList;
var
  mf, ml, lvn, ti, cur: Integer;
begin
  if FClosing or FSyncingHistScroll then Exit;
  EnsureHistPreviewGrid;
  EnsureJournalGrid;
  if (not Assigned(FsgJournal)) or (not Assigned(FsgHist)) then Exit;
  ml := JournalDisplayLineCount;
  lvn := HistPreviewDataCount;
  if (ml < 1) or (lvn < 1) then Exit;
  mf := FsgJournal.TopRow;
  if mf < 0 then mf := 0;
  if ml <= 1 then
    ti := 0
  else
    ti := MulDiv(mf, lvn - 1, ml - 1);
  if ti < 0 then ti := 0;
  if ti > lvn - 1 then ti := lvn - 1;
  cur := FsgHist.TopRow - 1;
  if cur < 0 then cur := 0;
  if cur = ti then Exit;
  FSyncingHistScroll := True;
  try
    FsgHist.TopRow := ti + 1;
  finally
    FSyncingHistScroll := False;
  end;
end;

procedure TfrmCompareMerge.HistApplyListScrollToMemo;
var
  ti, lvn, ml, tgt, cur: Integer;
begin
  if FClosing or FSyncingHistScroll then Exit;
  EnsureHistPreviewGrid;
  EnsureJournalGrid;
  if (not Assigned(FsgJournal)) or (not Assigned(FsgHist)) then Exit;
  ml := JournalDisplayLineCount;
  lvn := HistPreviewDataCount;
  if (ml < 1) or (lvn < 1) then Exit;
  ti := FsgHist.TopRow - 1;
  if ti < 0 then ti := 0;
  if lvn <= 1 then
    tgt := 0
  else
    tgt := MulDiv(ti, ml - 1, lvn - 1);
  if tgt < 0 then tgt := 0;
  if tgt > ml - 1 then tgt := ml - 1;
  cur := FsgJournal.TopRow;
  if cur < 0 then cur := 0;
  if cur = tgt then Exit;
  FSyncingHistScroll := True;
  try
    FsgJournal.TopRow := tgt;
  finally
    FSyncingHistScroll := False;
  end;
end;

procedure TfrmCompareMerge.UnhookMemoJournalWndProc;
begin
  { No-op safety: if a previous build left a hook, restore once. }
  if not FMemoJournalHooked then Exit;
  FMemoJournalHooked := False;
  if Assigned(mmoJournal) and Assigned(FOldMemoJournalWndProc) then
    mmoJournal.WindowProc := FOldMemoJournalWndProc;
  FOldMemoJournalWndProc := nil;
end;

procedure TfrmCompareMerge.HookMemoJournalWndProc;
begin
  { Disabled: subclassing TRichEdit.WindowProc caused ACCESS_VIOLATION
    (Self inaccessible after handle recreate / teardown). Scroll sync still
    works from the preview grid (SgHistWndProc); gutter paints on demand. }
  UnhookMemoJournalWndProc;
end;

procedure TfrmCompareMerge.UnhookAllSubclassedWndProcs;
begin
  UnhookMemoJournalWndProc;
  if Assigned(FsgHist) and Assigned(FOldSgHistWndProc) then
  begin
    FsgHist.WindowProc := FOldSgHistWndProc;
    FOldSgHistWndProc := nil;
  end;
  if Assigned(lvLeft) and Assigned(FOldLvLeftWndProc) then
  begin
    lvLeft.WindowProc := FOldLvLeftWndProc;
    FOldLvLeftWndProc := nil;
  end;
  if Assigned(lvRight) and Assigned(FOldLvRightWndProc) then
  begin
    lvRight.WindowProc := FOldLvRightWndProc;
    FOldLvRightWndProc := nil;
  end;
end;

procedure TfrmCompareMerge.MemoJournalWndProc(var Message: TMessage);
begin
  { Hook disabled — should never run. Forward if somehow still installed. }
  if Assigned(FOldMemoJournalWndProc) then
    FOldMemoJournalWndProc(Message);
end;

procedure TfrmCompareMerge.LvHistWndProc(var Message: TMessage);
var
  nm: PNMListView;
begin
  { NUNCA permitir LVIS_SELECTED no preview: o Win32 pinta barra azul ESCURA sem
    texto (linha "em branco"). Realce so via FJournalPreviewHiliteIdx + CustomDraw. }
  if (Message.Msg = CN_NOTIFY) and (Message.LParam <> 0) and
     (PNMHdr(Message.LParam)^.code = LVN_ITEMCHANGING) then
  begin
    nm := PNMListView(Message.LParam);
    if ((nm^.uNewState and LVIS_SELECTED) <> 0) and
      ((nm^.uOldState and LVIS_SELECTED) = 0) then
    begin
      Message.Result := 1;
      Exit;
    end;
  end;

  if FSyncingHistScroll then
  begin
    FOldLvHistWndProc(Message);
    Exit;
  end;
  FOldLvHistWndProc(Message);
  if FClosing then Exit;
  case Message.Msg of
    WM_VSCROLL, WM_MOUSEWHEEL:
      HistApplyListScrollToMemo;
  end;
end;

procedure TfrmCompareMerge.JournalSelectMemoFullLine(const LineIndex: Integer);
var
  vis: Integer;
begin
  EnsureJournalGrid;
  if not Assigned(FsgJournal) then Exit;
  if (LineIndex < 0) or (LineIndex >= JournalDisplayLineCount) then Exit;
  FJournalGridSelLine := LineIndex;
  FSyncingHistScroll := True;
  try
    FsgJournal.Row := LineIndex;
    vis := FsgJournal.VisibleRowCount;
    if vis < 1 then vis := 1;
    if LineIndex < FsgJournal.TopRow then
      FsgJournal.TopRow := LineIndex
    else if LineIndex > FsgJournal.TopRow + vis - 1 then
    begin
      if LineIndex - vis + 1 < 0 then
        FsgJournal.TopRow := 0
      else
        FsgJournal.TopRow := LineIndex - vis + 1;
    end;
  finally
    FSyncingHistScroll := False;
  end;
  FsgJournal.Invalidate;
end;

function TfrmCompareMerge.JournalDisplayLineCount: Integer;
begin
  if Assigned(FJournalTags) then
    Result := FJournalTags.Count
  else if Assigned(mmoJournal) then
    Result := mmoJournal.Lines.Count
  else
    Result := 0;
end;

procedure TfrmCompareMerge.ApplyMergeListViewColumnCaptions;
begin
  EnsureHistPreviewGrid;
  if Assigned(FsgHist) then
    FsgHist.Invalidate;
  if Assigned(lvLeft) and (lvLeft.Columns.Count >= 2) then
  begin
    lvLeft.Columns[0].Caption := TrText('Line #');
    lvLeft.Columns[1].Caption := TrText('Content');
  end;
  if Assigned(lvRight) and (lvRight.Columns.Count >= 2) then
  begin
    lvRight.Columns[0].Caption := TrText('Line #');
    lvRight.Columns[1].Caption := TrText('Content');
  end;
end;

function TfrmCompareMerge.HistPreviewLineTag(const AIndex: Integer): Integer;
begin
  Result := 0;
  if (AIndex >= 0) and Assigned(FHistPaged) then
    Result := FHistPaged.LineKind(Int64(AIndex) + 1)
  else if (AIndex >= 0) and (AIndex + 1 <= High(FHistLineKinds)) then
    Result := FHistLineKinds[AIndex + 1];
end;

function TfrmCompareMerge.HistPreviewDataCount: Integer;
begin
  if Assigned(FHistPaged) then
    { Linhas ja' visiveis na grelha (cresce com a indexacao; limite do TDrawGrid). }
    Result := Integer(FHistPagedShownCount)
  else if Assigned(FHistPreviewLines) then
    Result := FHistPreviewLines.Count
  else
    Result := 0;
end;

procedure TfrmCompareMerge.EnsureJournalGrid;
begin
  if Assigned(FsgJournal) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FsgJournal := TStringGrid.Create(Self);
  FsgJournal.Parent := TabSheetHistory;
  FsgJournal.Anchors := [akLeft, akTop, akRight];
  FsgJournal.ColCount := 2;
  FsgJournal.RowCount := 1;
  FsgJournal.FixedRows := 0;
  FsgJournal.FixedCols := 1;
  FsgJournal.ColWidths[0] := cJrnCheckColW;
  FsgJournal.DefaultRowHeight := 18;
  FsgJournal.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
    goRowSelect, goThumbTracking];
  FsgJournal.DefaultDrawing := False;
  FsgJournal.Font.Name := 'Consolas';
  if FsgJournal.Font.Name <> 'Consolas' then
    FsgJournal.Font.Name := 'Courier New';
  FsgJournal.Font.Size := 9;
  FsgJournal.Font.Color := clBlack;
  FsgJournal.Font.Charset := DEFAULT_CHARSET;
  FsgJournal.TabOrder := 1;
  FsgJournal.OnDrawCell := sgJournalDrawCell;
  FsgJournal.OnMouseUp := sgJournalMouseUp;
  FsgJournal.OnSelectCell := sgJournalSelectCell;
  FsgJournal.OnDblClick := sgJournalDblClick;
  FsgJournal.OnKeyDown := sgJournalKeyDown;
  FsgJournal.Hint := TrText('HistDetail.GridHint');
  FsgJournal.ShowHint := True;
  FpmJrnCtx := TPopupMenu.Create(Self);
  FpmJrnCtx.OnPopup := JrnCtxPopup;
  FsgJournal.PopupMenu := FpmJrnCtx;
  FJrnPopRow := -1;
  FJournalGridSelLine := -1;
  if Assigned(mmoJournal) then
  begin
    mmoJournal.Visible := False;
    mmoJournal.SendToBack;
  end;
end;

procedure TfrmCompareMerge.UpdateJournalColWidth;
var
  W, CharW: Integer;
begin
  if not Assigned(FsgJournal) then Exit;
  if FsgJournal.ColCount > 1 then
    FsgJournal.ColWidths[0] := cJrnCheckColW;
  W := Max(120, FsgJournal.ClientWidth - cJrnCheckColW - GetSystemMetrics(SM_CXVSCROLL) - 4);
  if FJournalMaxChars > 0 then
  begin
    { Fonte monoespacada: largura = caracteres x largura de um caractere (linhas completas rolam na horizontal). }
    FsgJournal.Canvas.Font := FsgJournal.Font;
    CharW := FsgJournal.Canvas.TextWidth('0');
    if CharW < 1 then CharW := 7;
    W := Max(W, FJournalMaxChars * CharW + 24);
  end;
  if FsgJournal.ColCount > 1 then
    FsgJournal.ColWidths[1] := W
  else
    FsgJournal.ColWidths[0] := W;
end;

procedure TfrmCompareMerge.sgJournalDrawCell(Sender: TObject; ACol, ARow: Longint;
  Rect: TRect; State: TGridDrawState);
var
  tag: Integer;
  bg: TColor;
  R, RMid: TRect;
  txt, sPre, sMid, sPost: string;
  IsSel: Boolean;
  pOn, pOff, x: Integer;
begin
  if not Assigned(FsgJournal) then Exit;
  tag := 0;
  if Assigned(FJournalTags) and (ARow >= 0) and (ARow < FJournalTags.Count) then
    tag := Integer(FJournalTags[ARow]);
  bg := BrushForHistTag(tag);
  IsSel := (ARow = FJournalGridSelLine) or (gdSelected in State) or (gdFocused in State);

  R := Rect;
  if FsgJournal.ColCount > 1 then
    txt := FsgJournal.Cells[1, ARow]
  else
    txt := FsgJournal.Cells[ACol, ARow];
  if txt = cHistSpacerRow then
  begin
    FsgJournal.Canvas.Brush.Color := clBtnFace;
    FsgJournal.Canvas.FillRect(R);
    FsgJournal.Canvas.Pen.Color := clGray;
    FsgJournal.Canvas.Pen.Width := 1;
    FsgJournal.Canvas.MoveTo(R.Left, (R.Top + R.Bottom) div 2);
    FsgJournal.Canvas.LineTo(R.Right, (R.Top + R.Bottom) div 2);
    Exit;
  end;
  FsgJournal.Canvas.Brush.Color := bg;
  FsgJournal.Canvas.Font.Color := clBlack;
  FsgJournal.Canvas.FillRect(R);
  if (ACol = 0) and (FsgJournal.ColCount > 1) then
  begin
    if Assigned(FJrnSel) then
    begin
      if (ARow = 0) and JrnHasEvents then
        DrawHistCheckBox(FsgJournal.Canvas, R, JrnAllChecked, FJrnSel.Count > 0)
      else if JrnRawAt(ARow) <> '' then
        DrawHistCheckBox(FsgJournal.Canvas, R, FJrnSel.ContainsKey(JrnRawAt(ARow)));
    end;
    if IsSel then
    begin
      FsgJournal.Canvas.Pen.Color := cHistSelInk;
      FsgJournal.Canvas.Pen.Width := 2;
      FsgJournal.Canvas.MoveTo(R.Right - 2, R.Top + 1);
      FsgJournal.Canvas.LineTo(R.Right - 2, R.Bottom);
      FsgJournal.Canvas.Pen.Width := 1;
    end;
    Exit;
  end;
  if Copy(txt, 1, 1) <> ' ' then
    FsgJournal.Canvas.Font.Style := [fsBold]
  else
    FsgJournal.Canvas.Font.Style := [];
  FsgJournal.Canvas.FillRect(R);
  R.Left := R.Left + 4;
  pOn := Pos(cHistMarkOn, txt);
  pOff := Pos(cHistMarkOff, txt);
  if (pOn > 0) and (pOff > pOn) then
  begin
    x := R.Left;
    sPost := txt;
    while (pOn > 0) and (pOff > pOn) and (x < R.Right) do
    begin
      sPre := Copy(sPost, 1, pOn - 1);
      sMid := Copy(sPost, pOn + 1, pOff - pOn - 1);
      sPost := Copy(sPost, pOff + 1, MaxInt);
      if sPre <> '' then
      begin
        RMid := R;
        RMid.Left := x;
        FsgJournal.Canvas.TextRect(RMid, x, R.Top + 2, sPre);
        Inc(x, FsgJournal.Canvas.TextWidth(sPre));
      end;
      if x >= R.Right then Break;
      if sMid <> '' then
      begin
        FsgJournal.Canvas.Font.Style := [fsBold];
        FsgJournal.Canvas.Font.Color := clRed;
        FsgJournal.Canvas.Brush.Color := cHistChangeBg;
        RMid.Left := x;
        RMid.Top := R.Top + 1;
        RMid.Right := x + FsgJournal.Canvas.TextWidth(sMid);
        RMid.Bottom := R.Bottom - 1;
        if RMid.Right > R.Right then RMid.Right := R.Right;
        FsgJournal.Canvas.TextRect(RMid, x, R.Top + 2, sMid);
        Inc(x, FsgJournal.Canvas.TextWidth(sMid));
        FsgJournal.Canvas.Font.Style := [];
        FsgJournal.Canvas.Font.Color := clBlack;
        FsgJournal.Canvas.Brush.Color := bg;
      end
      else
      begin
        FsgJournal.Canvas.Pen.Color := clRed;
        FsgJournal.Canvas.Pen.Width := 2;
        FsgJournal.Canvas.MoveTo(x, R.Top + 2);
        FsgJournal.Canvas.LineTo(x, R.Bottom - 2);
        FsgJournal.Canvas.Pen.Width := 1;
        Inc(x, 2);
      end;
      pOn := Pos(cHistMarkOn, sPost);
      pOff := Pos(cHistMarkOff, sPost);
    end;
    if (x < R.Right) and (sPost <> '') then
    begin
      RMid := R;
      RMid.Left := x;
      FsgJournal.Canvas.TextRect(RMid, x, R.Top + 2, sPost);
    end;
  end
  else
    FsgJournal.Canvas.TextRect(R, R.Left, R.Top + 2, txt);

  if IsSel then
  begin
    if ACol = 0 then
      DrawHistSelectionMarker(FsgJournal.Canvas, Rect)
    else
    begin
      FsgJournal.Canvas.Brush.Style := bsClear;
      FsgJournal.Canvas.Pen.Color := cHistSelInk;
      FsgJournal.Canvas.Pen.Width := 2;
      FsgJournal.Canvas.Rectangle(Rect.Left, Rect.Top + 1, Rect.Right - 1, Rect.Bottom);
      FsgJournal.Canvas.Pen.Width := 1;
    end;
    FsgJournal.Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TfrmCompareMerge.sgJournalMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
begin
  if Button <> mbLeft then Exit;
  if FClosing then Exit;
  if not Assigned(FsgJournal) then Exit;
  FsgJournal.MouseToCell(X, Y, ACol, ARow);
  if ARow < 0 then Exit;
  if (ACol = 0) and (ARow = 0) and JrnHasEvents then
  begin
    JrnSelectAllToggle;
    Exit;
  end;
  if (ACol = 0) and (JrnRawAt(ARow) <> '') then
  begin
    JrnToggleRow(ARow);
    FsgJournal.Invalidate;
    Exit;
  end;
  if (FJournalLineNums = nil) or (ARow >= FJournalLineNums.Count) then Exit;
  FJournalGridSelLine := ARow;
  FsgJournal.Invalidate;
  SyncChangedLinesFromJournalRow(ARow);
  RequestJournalJumpFromLine(ARow);
end;

procedure TfrmCompareMerge.sgJournalSelectCell(Sender: TObject; ACol, ARow: Longint;
  var CanSelect: Boolean);
begin
  if ARow < 0 then Exit;
  if FJournalGridSelLine <> ARow then
  begin
    FJournalGridSelLine := ARow;
    if Assigned(FsgJournal) then
      FsgJournal.Invalidate;
  end;
  SyncChangedLinesFromJournalRow(ARow);
end;

procedure TfrmCompareMerge.SyncChangedLinesFromJournalRow(ARow: Integer);
var
  Ln0: Integer;
  R: THciRec;
begin
  if FClosing or FSyncingChangedLines then Exit;
  if not Assigned(FlbChangedLines) or (FlbChangedLines.Count = 0) then Exit;
  if (FJournalLineNums = nil) or (ARow < 0) or (ARow >= FJournalLineNums.Count) then Exit;
  { Linhas de espaco/estado (0) nao mudam a selecao da lista. }
  Ln0 := Integer(FJournalLineNums[ARow]);
  if Ln0 < 1 then Exit;
  { A lista mostra os eventos de uma linha: todos a incluem, a selecao fica nela. }
  if FJrnViewLine > 0 then Exit;
  if ChgRecAt(FlbChangedLines.ItemIndex, R) and (R.Ln0 = Ln0) then Exit;
  FSyncingChangedLines := True;
  try
    ChgSelectLine(Ln0, False);
  finally
    FSyncingChangedLines := False;
  end;
end;

procedure TfrmCompareMerge.EnsureHistPreviewGrid;
begin
  if Assigned(FsgHist) then Exit;
  if not Assigned(TabSheetHistory) then Exit;
  FsgHist := TDrawGrid.Create(Self);
  FsgHist.Parent := TabSheetHistory;
  FsgHist.Anchors := [akLeft, akTop, akRight, akBottom];
  FsgHist.ColCount := 2;
  FsgHist.RowCount := 2;
  FsgHist.FixedRows := 1;
  FsgHist.FixedCols := 0;
  FsgHist.DefaultRowHeight := 18;
  FsgHist.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
    goRowSelect, goThumbTracking, goColSizing];
  FsgHist.DefaultDrawing := False;
  FsgHist.Font.Name := 'Segoe UI';
  FsgHist.Font.Size := 9;
  FsgHist.Font.Color := clBlack;
  FsgHist.Font.Charset := DEFAULT_CHARSET;
  FsgHist.PopupMenu := popLvHist;
  FsgHist.TabOrder := 2;
  FsgHist.OnDrawCell := sgHistDrawCell;
  FsgHist.OnMouseDown := sgHistMouseDown;
  FsgHist.OnSelectCell := sgHistSelectCell;
  { No WindowProc subclass — see FormCreate comment. }
  if Assigned(lvHistFile) then
  begin
    lvHistFile.Visible := False;
    lvHistFile.Enabled := False;
    lvHistFile.SendToBack;
  end;
end;

procedure TfrmCompareMerge.sgHistDrawCell(Sender: TObject; ACol, ARow: Longint;
  Rect: TRect; State: TGridDrawState);
var
  bg: TColor;
  tag: Integer;
  txt: string;
  dataIdx: Integer;
  IsHilite: Boolean;
  R: TRect;
begin
  if not (Sender is TDrawGrid) then Exit;
  R := Rect;
  if ARow = 0 then
  begin
    FsgHist.Canvas.Brush.Color := clBtnFace;
    FsgHist.Canvas.Font.Color := clWindowText;
    FsgHist.Canvas.FillRect(R);
    if ACol = 0 then
      txt := TrText('Line #')
    else
      txt := TrText('Content');
    FsgHist.Canvas.TextRect(R, R.Left + 3, R.Top + 2, txt);
    Exit;
  end;

  dataIdx := ARow - 1;
  if FHistOverlayActive and (dataIdx = FHistOverlayIdx) then
    tag := FHistOverlayTag
  else
    tag := HistPreviewLineTag(dataIdx);
  IsHilite := (FJournalPreviewHiliteIdx >= 0) and (dataIdx = FJournalPreviewHiliteIdx);

  if FHistOverlayActive and (dataIdx = FHistOverlayIdx) then
    bg := BrushForHistTag(tag)
  else if tag <> 0 then
    bg := BrushForHistTag(tag)
  else if IsHilite then
    bg := cHistSelFill
  else
    bg := BrushForHistTag(0);

  FsgHist.Canvas.Brush.Color := bg;
  FsgHist.Canvas.Font.Color := clBlack;
  FsgHist.Canvas.FillRect(R);

  if ACol = 0 then
    txt := IntToStr(dataIdx + 1)
  else
    txt := HistPreviewCellText(dataIdx);
  FsgHist.Canvas.TextRect(R, R.Left + 3, R.Top + 2, txt);

  if IsHilite then
  begin
    if ACol = 0 then
      DrawHistSelectionMarker(FsgHist.Canvas, R)
    else
    begin
      FsgHist.Canvas.Brush.Style := bsClear;
      FsgHist.Canvas.Pen.Color := cHistSelInk;
      FsgHist.Canvas.Pen.Width := 2;
      FsgHist.Canvas.Rectangle(R.Left, R.Top + 1, R.Right - 1, R.Bottom);
      FsgHist.Canvas.Pen.Width := 1;
    end;
    FsgHist.Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TfrmCompareMerge.sgHistMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
begin
  if Button <> mbLeft then Exit;
  if not Assigned(FsgHist) then Exit;
  FsgHist.MouseToCell(X, Y, ACol, ARow);
  if ARow < 1 then Exit;
  ClearHistJournalOverlay;
  FJournalPreviewHiliteIdx := ARow - 1;
  FsgHist.Invalidate;
  if not FHistShowAllJournal then
    RequestApplyJournalDisplayMode;
end;

procedure TfrmCompareMerge.sgHistSelectCell(Sender: TObject; ACol, ARow: Longint;
  var CanSelect: Boolean);
begin
  { goRowSelect muda Row — sincronizar realce sem esconder texto (grid pinta sempre). }
  if ARow >= 1 then
  begin
    if FHistOverlayActive and ((ARow - 1) <> FHistOverlayIdx) then
      ClearHistJournalOverlay;
    if FJournalPreviewHiliteIdx <> (ARow - 1) then
    begin
      FJournalPreviewHiliteIdx := ARow - 1;
      if not FHistShowAllJournal then
        RequestApplyJournalDisplayMode;
    end
    else
      FJournalPreviewHiliteIdx := ARow - 1;
  end;
end;

procedure TfrmCompareMerge.SgHistWndProc(var Message: TMessage);
begin
  if not Assigned(FOldSgHistWndProc) then Exit;
  if FSyncingHistScroll then
  begin
    FOldSgHistWndProc(Message);
    Exit;
  end;
  FOldSgHistWndProc(Message);
  if FClosing then Exit;
  case Message.Msg of
    WM_VSCROLL, WM_MOUSEWHEEL:
      HistApplyListScrollToMemo;
  end;
end;

procedure TfrmCompareMerge.HistPreviewJumpToDataRow(const DataIdx: Integer);
var
  gridRow, vis: Integer;
begin
  EnsureHistPreviewGrid;
  if not Assigned(FsgHist) then Exit;
  if (DataIdx < 0) or (DataIdx >= HistPreviewDataCount) then Exit;
  FJournalPreviewHiliteIdx := DataIdx;
  gridRow := DataIdx + 1;
  FSyncingHistScroll := True;
  try
    FsgHist.Row := gridRow;
    vis := FsgHist.VisibleRowCount;
    if vis < 1 then vis := 1;
    if gridRow < FsgHist.TopRow then
      FsgHist.TopRow := gridRow
    else if gridRow > FsgHist.TopRow + vis - 1 then
    begin
      if gridRow - vis + 1 < 1 then
        FsgHist.TopRow := 1
      else
        FsgHist.TopRow := gridRow - vis + 1;
    end;
  finally
    FSyncingHistScroll := False;
  end;
  FsgHist.Invalidate;
  if not FHistShowAllJournal then
    RequestApplyJournalDisplayMode;
end;

procedure TfrmCompareMerge.ClearHistPreviewListView;
var
  EmptyKinds: array of Byte;
begin
  SetLength(EmptyKinds, 0);
  ApplyHistPreviewToListView(nil, EmptyKinds, True);
end;

procedure TfrmCompareMerge.ApplyHistPreviewToListView(const APreview: TStringList;
  const ALineKinds: array of Byte; AClearOnly: Boolean);
var
  maxL, j: Integer;
begin
  if not Assigned(FHistPreviewLines) then Exit;
  StopHistPagedPreview;
  EnsureHistPreviewGrid;
  FHistPreviewLines.Clear;
  if Assigned(lvHistFile) then
  begin
    lvHistFile.Visible := False;
    lvHistFile.Items.BeginUpdate;
    try
      lvHistFile.Items.Clear;
    finally
      lvHistFile.Items.EndUpdate;
    end;
  end;

  if AClearOnly or (not Assigned(APreview)) or (APreview.Count < 1) then
  begin
    SetLength(FHistLineKinds, 0);
    if Assigned(FsgHist) then
    begin
      FsgHist.RowCount := 2;
      FsgHist.Invalidate;
    end;
    Exit;
  end;

  FHistPreviewLines.Assign(APreview);
  maxL := FHistPreviewLines.Count;
  SetLength(FHistLineKinds, maxL + 1);
  for j := 1 to maxL do
    if j <= High(ALineKinds) then
      FHistLineKinds[j] := ALineKinds[j]
    else
      FHistLineKinds[j] := 0;

  if Assigned(FsgHist) then
  begin
    FsgHist.RowCount := maxL + 1;
    FsgHist.Invalidate;
  end;
end;

procedure TfrmCompareMerge.StartHistPagedPreview(const APath: string);
begin
  ClearHistPreviewListView;
  if FClosing or (Trim(APath) = '') or (not FileExists(APath)) then Exit;
  EnsureHistPreviewGrid;
  FHistPaged := TFFPagedLineSource.Create(APath, FFHistoryJournalPath(APath));
  FHistPagedShownCount := 0;
  FHistPaged.Start;
  if not Assigned(FHistPagedTimer) then
  begin
    FHistPagedTimer := TTimer.Create(Self);
    FHistPagedTimer.Interval := 400;
    FHistPagedTimer.OnTimer := HistPagedTimerTick;
  end;
  FHistPagedTimer.Enabled := True;
  UpdateHistPagedView;
end;

procedure TfrmCompareMerge.StopHistPagedPreview;
begin
  if Assigned(FHistPagedTimer) then
    FHistPagedTimer.Enabled := False;
  FHistPagedShownCount := 0;
  FreeAndNil(FHistPaged);
end;

procedure TfrmCompareMerge.HistPagedTimerTick(Sender: TObject);
begin
  if FClosing or (not Assigned(FHistPaged)) then
  begin
    if Assigned(FHistPagedTimer) then
      FHistPagedTimer.Enabled := False;
    Exit;
  end;
  UpdateHistPagedView;
  if FHistPaged.IndexComplete and FHistPaged.KindsReady then
    FHistPagedTimer.Enabled := False;
end;

procedure TfrmCompareMerge.UpdateHistPagedView;
const
  { TDrawGrid.RowCount e' Integer: reserva a linha de cabecalho. }
  cMaxGridDataRows = MaxInt - 2;
var
  Total, Shown: Int64;
  Cap: string;
begin
  if (not Assigned(FHistPaged)) or (not Assigned(FsgHist)) then Exit;
  Total := FHistPaged.LineCount;
  Shown := Total;
  if Shown > cMaxGridDataRows then
    Shown := cMaxGridDataRows;
  if Shown <> FHistPagedShownCount then
  begin
    FHistPagedShownCount := Shown;
    if Shown < 1 then
      FsgHist.RowCount := 2
    else
      FsgHist.RowCount := Integer(Shown) + 1;
    if Assigned(TabSheetHistory) and
       (FsgHist.Canvas.TextWidth(IntToStr(Max(Int64(1), Shown))) + 16 > FsgHist.ColWidths[0]) then
      TabSheetHistoryResize(TabSheetHistory);
  end;
  FsgHist.Invalidate;

  Cap := TrText('History file preview (colors from journal; line numbers are as at edit time).');
  if FHistPaged.IndexComplete then
    Cap := Cap + ' ' + Format(TrText('Whole file available: %s lines (paged reading, low memory).'),
      [FormatFloat('#,##0', Total)])
  else
    Cap := Cap + ' ' + Format(TrText('Indexing file for paged preview: %d%% (%s lines so far)...'),
      [FHistPaged.IndexPercent, FormatFloat('#,##0', Total)]);
  if Total > cMaxGridDataRows then
    Cap := Cap + ' ' + Format(TrText('Only the first %s lines can be shown in the grid.'),
      [FormatFloat('#,##0', cMaxGridDataRows)]);
  if FHistPaged.JournalSkipped then
    Cap := Cap + ' ' + TrText('Journal too large; line colors omitted on preview.');
  lblHistPreview.Caption := Cap;
  if Assigned(FHistPreviewHost) and (FHistPreviewHost.Caption <> Cap) then
    FHistPreviewHost.Caption := Cap;
end;

procedure StyleHistExportBtn(ABtn: TsSpeedButton);
begin
  { Mesmo estilo de TfrmMain.StyleListViewLineToolBtn (Limpar / Copiar / Exportar). }
  ABtn.Flat := True;
  ABtn.ShowCaption := True;
  ABtn.ShowHint := True;
  ABtn.ParentShowHint := False;
  ABtn.Cursor := crHandPoint;
  ABtn.ParentFont := False;
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    ABtn.Font.Name := 'Segoe UI'
  else
    ABtn.Font.Name := 'Tahoma';
  ABtn.Font.Size := 8;
  ABtn.Font.Style := [fsBold];
  ABtn.Spacing := 6;
  ABtn.Height := 24;
  try
    ABtn.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
end;

procedure TfrmCompareMerge.UpdateHistExportGlyph(ABtn: TsSpeedButton; AColor: TColor);
const
  cSz = 16;
var
  Bmp: TBitmap;
begin
  { Quadrado com a cor da legenda; visto (V) quando o tipo esta' marcado para exportar. }
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(cSz, cSz);
    Bmp.Canvas.Brush.Color := clFuchsia;
    Bmp.Canvas.FillRect(Rect(0, 0, cSz, cSz));
    Bmp.Canvas.Brush.Color := AColor;
    Bmp.Canvas.Pen.Color := RGB(110, 110, 110);
    Bmp.Canvas.Rectangle(1, 1, cSz - 1, cSz - 1);
    if ABtn.Down then
    begin
      Bmp.Canvas.Pen.Color := RGB(20, 20, 20);
      Bmp.Canvas.Pen.Width := 2;
      Bmp.Canvas.MoveTo(4, 8);
      Bmp.Canvas.LineTo(7, 11);
      Bmp.Canvas.LineTo(12, 4);
    end;
    Bmp.Transparent := True;
    Bmp.TransparentColor := clFuchsia;
    ABtn.Glyph.Assign(Bmp);
    ABtn.NumGlyphs := 1;
  finally
    Bmp.Free;
  end;
  ABtn.Invalidate;
end;

procedure TfrmCompareMerge.EnsureHistExportBar;
var
  i: Integer;

  function NewBtn(AGroup: Integer; AOnClick: TNotifyEvent): TsSpeedButton;
  begin
    Result := TsSpeedButton.Create(Self);
    Result.Parent := FHistExportBar;
    StyleHistExportBtn(Result);
    if AGroup > 0 then
    begin
      Result.GroupIndex := AGroup;
      Result.AllowAllUp := True;
    end;
    Result.OnClick := AOnClick;
  end;

begin
  if Assigned(FHistExportBar) or (not Assigned(TabSheetHistory)) then Exit;
  FHistExportBar := TsPanel.Create(Self);
  FHistExportBar.Parent := TabSheetHistory;
  FHistExportBar.BevelOuter := bvNone;
  FHistExportBar.Caption := '';
  FHistExportBar.Anchors := [akLeft, akRight, akBottom];

  FHistExportLbl := TLabel.Create(Self);
  FHistExportLbl.Parent := FHistExportBar;
  FHistExportLbl.Font.Style := [fsBold];

  for i := 0 to High(FHistExportKindBtns) do
  begin
    FHistExportKindBtns[i] := NewBtn(900 + i, HistExportKindClick);
    FHistExportKindBtns[i].Tag := i;
    { Por omissao: so' linhas alteradas (tudo menos "Igual"). }
    FHistExportKindBtns[i].Down := cHistExportBtnTag[i] <> 0;
  end;
  FHistExportPrefixBtn := NewBtn(910, HistExportKindClick);
  FHistExportPrefixBtn.Tag := -1;
  FHistExportBtn := NewBtn(0, HistExportClick);

  FHistExportStatus := TLabel.Create(Self);
  FHistExportStatus.Parent := FHistExportBar;
  FHistExportStatus.AutoSize := False;
  FHistExportStatus.EllipsisPosition := epEndEllipsis;
  FHistExportStatus.Caption := '';

  FHistExportTimer := TTimer.Create(Self);
  FHistExportTimer.Enabled := False;
  FHistExportTimer.Interval := 300;
  FHistExportTimer.OnTimer := HistExportTimerTick;

  ApplyHistExportCaptions;
end;

procedure TfrmCompareMerge.LayoutHistExportBar;
var
  i, x, h: Integer;

  procedure Place(ACtrl: TControl; AWidth: Integer);
  begin
    ACtrl.SetBounds(x, (h - 24) div 2, AWidth, 24);
    Inc(x, AWidth + 4);
  end;

  function BtnW(ABtn: TsSpeedButton; AGlyph: Boolean): Integer;
  var
    Bmp: TBitmap;
  begin
    Bmp := TBitmap.Create;
    try
      Bmp.Canvas.Font.Assign(ABtn.Font);
      Result := Bmp.Canvas.TextWidth(ABtn.Caption) + 24;
    finally
      Bmp.Free;
    end;
    if AGlyph then Inc(Result, 16 + ABtn.Spacing);
  end;

begin
  if not Assigned(FHistExportBar) then Exit;
  h := FHistExportBar.ClientHeight;
  x := 0;
  FHistExportLbl.SetBounds(x, (h - FHistExportLbl.Height) div 2, FHistExportLbl.Width, FHistExportLbl.Height);
  Inc(x, FHistExportLbl.Width + 6);
  for i := 0 to High(FHistExportKindBtns) do
    Place(FHistExportKindBtns[i], BtnW(FHistExportKindBtns[i], True));
  Inc(x, 8);
  Place(FHistExportPrefixBtn, BtnW(FHistExportPrefixBtn, False));
  Place(FHistExportBtn, Max(80, BtnW(FHistExportBtn, False)));
  Inc(x, 4);
  FHistExportStatus.SetBounds(x, (h - FHistExportStatus.Height) div 2,
    Max(40, FHistExportBar.ClientWidth - x), FHistExportStatus.Height);
end;

procedure TfrmCompareMerge.ApplyHistExportCaptions;
const
  cKeys: array[0..4] of string = ('HistLegend.Inserted', 'HistLegend.Deleted',
    'HistLegend.Edited', 'HistLegend.UndoRedo', 'HistLegend.Equal');
var
  i: Integer;
begin
  if not Assigned(FHistExportBar) then Exit;
  FHistExportLbl.Caption := TrText('HistExport.Label');
  for i := 0 to High(FHistExportKindBtns) do
  begin
    FHistExportKindBtns[i].Caption := TrText(cKeys[i]);
    FHistExportKindBtns[i].Hint := TrText('HistExport.KindHint');
    UpdateHistExportGlyph(FHistExportKindBtns[i], BrushForHistTag(cHistExportBtnTag[i]));
  end;
  FHistExportPrefixBtn.Caption := TrText('HistExport.WithLineNo');
  FHistExportPrefixBtn.Hint := TrText('HistExport.WithLineNoHint');
  if Assigned(FHistExportThread) then
    FHistExportBtn.Caption := TrText('Cancel')
  else
  begin
    FHistExportBtn.Caption := TrText('FilterBar.Export');
    FHistExportStatus.Caption := HistExportLastStatusText;
  end;
  FHistExportBtn.Hint := TrText('HistExport.ButtonHint');
  LayoutHistExportBar;
end;

function TfrmCompareMerge.HistExportLastStatusText: string;
begin
  case FHistExportLastKind of
    1: Result := Format(TrText('HistExport.Done'),
         [FormatFloat('#,##0', FHistExportLastLines), FHistExportLastArg]);
    2: Result := TrText('HistExport.Cancelled');
    3: Result := Format(TrText('HistExport.Failed'), [FHistExportLastArg]);
  else
    Result := '';
  end;
end;

procedure TfrmCompareMerge.HistExportKindClick(Sender: TObject);
var
  Btn: TsSpeedButton;
begin
  if not (Sender is TsSpeedButton) then Exit;
  Btn := TsSpeedButton(Sender);
  if (Btn.Tag >= 0) and (Btn.Tag <= High(cHistExportBtnTag)) then
    UpdateHistExportGlyph(Btn, BrushForHistTag(cHistExportBtnTag[Btn.Tag]));
end;

procedure TfrmCompareMerge.HistExportClick(Sender: TObject);
var
  Kinds: TFFHistKindSet;
  i: Integer;
  Cnt: Int64;
  Dlg: TSaveDialog;
  OutPath: string;
begin
  if FClosing then Exit;
  if Assigned(FHistExportThread) then
  begin
    FHistExportThread.Cancel;
    Exit;
  end;
  Kinds := [];
  for i := 0 to High(FHistExportKindBtns) do
    if FHistExportKindBtns[i].Down then
    begin
      Include(Kinds, cHistExportBtnTag[i]);
      if cHistExportBtnTag[i] = 1 then
        Include(Kinds, 4);
    end;
  if Kinds = [] then
  begin
    FastFileMsgWarn(TrText('HistExport.NoneSelected'));
    Exit;
  end;
  if not Assigned(FHistPaged) then
  begin
    FastFileMsgWarn(TrText('HistExport.NoFile'));
    Exit;
  end;
  if not (FHistPaged.IndexComplete and FHistPaged.KindsReady) then
  begin
    FastFileMsgInfo(TrText('HistExport.WaitIndex'));
    Exit;
  end;

  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Title := TrText('HistExport.SaveTitle');
    Dlg.Filter := TrText('HistExport.FilterText') + ' (*.txt)|*.txt|' +
      TrText('HistExport.FilterAll') + ' (*.*)|*.*';
    Dlg.DefaultExt := 'txt';
    Dlg.Options := Dlg.Options + [ofOverwritePrompt, ofPathMustExist];
    Dlg.InitialDir := ExtractFilePath(FHistPaged.Path);
    Dlg.FileName := ChangeFileExt(ExtractFileName(FHistPaged.Path), '') + '_history_export.txt';
    if not Dlg.Execute then Exit;
    OutPath := Dlg.FileName;
  finally
    Dlg.Free;
  end;
  if AnsiSameText(ExpandFileName(OutPath), ExpandFileName(FHistPaged.Path)) then
  begin
    FastFileMsgWarn(TrText('HistExport.SameFile'));
    Exit;
  end;

  FHistExportThread := FHistPaged.CreateExport(OutPath, Kinds, FHistExportPrefixBtn.Down, Cnt);
  if not Assigned(FHistExportThread) then
  begin
    FastFileMsgInfo(TrText('HistExport.NoLines'));
    Exit;
  end;
  FHistExportThread.Start;
  FHistExportBtn.Caption := TrText('Cancel');
  LayoutHistExportBar;
  FHistExportStatus.Caption := Format(TrText('HistExport.Progress'), [0, '0']);
  FHistExportTimer.Enabled := True;
end;

procedure TfrmCompareMerge.HistExportTimerTick(Sender: TObject);
var
  T: TFFPagedExportThread;
  Lines: Int64;
  Err, OutPath: string;
  Cancelled: Boolean;
begin
  T := FHistExportThread;
  if not Assigned(T) then
  begin
    FHistExportTimer.Enabled := False;
    Exit;
  end;
  if not T.IsDone then
  begin
    FHistExportStatus.Caption := Format(TrText('HistExport.Progress'),
      [T.Percent, FormatFloat('#,##0', T.LinesWritten)]);
    Exit;
  end;
  FHistExportTimer.Enabled := False;
  Lines := T.LinesWritten;
  Err := T.ErrorText;
  Cancelled := T.WasCancelled;
  OutPath := T.OutPath;
  FHistExportThread := nil;
  T.Free;
  FHistExportBtn.Caption := TrText('FilterBar.Export');
  LayoutHistExportBar;
  if FClosing then Exit;
  FHistExportLastLines := Lines;
  if Err <> '' then
  begin
    FHistExportLastKind := 3;
    FHistExportLastArg := Err;
  end
  else if Cancelled then
  begin
    FHistExportLastKind := 2;
    FHistExportLastArg := '';
  end
  else
  begin
    FHistExportLastKind := 1;
    FHistExportLastArg := OutPath;
  end;
  FHistExportStatus.Caption := HistExportLastStatusText;
  if FHistExportLastKind = 3 then
    FastFileMsgError(FHistExportStatus.Caption)
  else if FHistExportLastKind = 1 then
    FastFileMsgSuccess(FHistExportStatus.Caption);
end;

procedure TfrmCompareMerge.StopHistExport;
begin
  if Assigned(FHistExportTimer) then
    FHistExportTimer.Enabled := False;
  if Assigned(FHistExportThread) then
  begin
    FHistExportThread.Cancel;
    FreeAndNil(FHistExportThread);
  end;
end;

procedure TfrmCompareMerge.lvHistFileData(Sender: TObject; Item: TListItem);
begin
  { Preview ja nao usa OwnerData; mantido por compatibilidade de assinatura. }
end;

procedure TfrmCompareMerge.EnsureHistPreviewItemText(const AIndex: Integer);
var
  i, a, b: Integer;
  It: TListItem;
begin
  if not Assigned(lvHistFile) or not Assigned(FHistPreviewLines) then Exit;
  if lvHistFile.Items.Count < 1 then Exit;
  a := AIndex - 2;
  if a < 0 then a := 0;
  b := AIndex + 40;
  if b >= lvHistFile.Items.Count then b := lvHistFile.Items.Count - 1;
  for i := a to b do
  begin
    It := lvHistFile.Items[i];
    if It = nil then Continue;
    It.Caption := IntToStr(i + 1);
    while It.SubItems.Count < 1 do
      It.SubItems.Add('');
    if i < FHistPreviewLines.Count then
      It.SubItems[0] := FHistPreviewLines[i];
  end;
end;

procedure TfrmCompareMerge.HistClearNativeSelection;
begin
  if not Assigned(lvHistFile) then Exit;
  if lvHistFile.HandleAllocated then
    ListView_SetItemState(lvHistFile.Handle, -1, 0, LVIS_SELECTED or LVIS_FOCUSED);
  lvHistFile.ClearSelection;
  lvHistFile.ItemIndex := -1;
  lvHistFile.Selected := nil;
end;

procedure TfrmCompareMerge.WMHistClearSel(var Msg: TMessage);
begin
  if FClosing then Exit;
  HistClearNativeSelection;
  if Assigned(lvHistFile) then
  begin
    if FJournalPreviewHiliteIdx >= 0 then
      EnsureHistPreviewItemText(FJournalPreviewHiliteIdx);
    lvHistFile.Invalidate;
  end;
end;

procedure TfrmCompareMerge.tmrHistClearSelTimer(Sender: TObject);
begin
  if FClosing or (FHistClearSelTicks <= 0) then
  begin
    if Assigned(FHistClearSelTimer) then
      FHistClearSelTimer.Enabled := False;
    FHistClearSelTicks := 0;
    FHistJumpIgnoreSel := False;
    Exit;
  end;
  Dec(FHistClearSelTicks);
  HistClearNativeSelection;
  if Assigned(lvHistFile) and (FJournalPreviewHiliteIdx >= 0) then
  begin
    EnsureHistPreviewItemText(FJournalPreviewHiliteIdx);
    lvHistFile.Invalidate;
  end;
  if FHistClearSelTicks <= 0 then
  begin
    FHistClearSelTimer.Enabled := False;
    FHistJumpIgnoreSel := False;
  end;
end;

procedure TfrmCompareMerge.PaintHistPreviewItem(Sender: TCustomListView; Item: TListItem);
var
  RAll, R0, R1: TRect;
  tag: Integer;
  LV: TListView;
  cw0: Integer;
  Bg: TColor;
  txt, lineNo: string;
  IsJournalHilite: Boolean;
  DC: HDC;
begin
  if (Item = nil) or (Item.Index < 0) then Exit;
  LV := TListView(Sender);
  if Item.Index >= LV.Items.Count then Exit;

  tag := HistPreviewLineTag(Item.Index);
  if tag = 0 then
    tag := Integer(Item.Data);
  IsJournalHilite := (FJournalPreviewHiliteIdx >= 0) and (Item.Index = FJournalPreviewHiliteIdx);

  { Selecao nativa (barra azul escura) NAO usa clHighlight — senão o tema cobre o texto
    e a linha fica "selecionada em branco". Sempre pastel da legenda + tinta preta.
    Item.Selected e' ignorado: selecao nativa esta bloqueada no preview. }
  if tag <> 0 then
    Bg := BrushForHistTag(tag)
  else if IsJournalHilite then
    Bg := cHistSelFill
  else
    Bg := BrushForHistTag(0);

  RAll := Item.DisplayRect(drBounds);
  if (RAll.Right <= RAll.Left) or (RAll.Bottom <= RAll.Top) then Exit;

  Sender.Canvas.Brush.Color := Bg;
  Sender.Canvas.Brush.Style := bsSolid;
  Sender.Canvas.Font.Color := clBlack;
  Sender.Canvas.Font.Charset := DEFAULT_CHARSET;
  Sender.Canvas.FillRect(RAll);

  DC := Sender.Canvas.Handle;
  SetBkMode(DC, TRANSPARENT);
  SetTextColor(DC, ColorToRGB(clBlack));

  cw0 := 56;
  if LV.Columns.Count > 0 then
    cw0 := LV.Columns[0].Width;
  R0 := RAll;
  R0.Right := Min(RAll.Left + cw0, RAll.Right);
  R1 := RAll;
  R1.Left := R0.Right;

  lineNo := IntToStr(Item.Index + 1);
  ExtTextOut(DC, R0.Left + 3, R0.Top + 2, ETO_CLIPPED, @R0, PChar(lineNo), Length(lineNo), nil);

  { Texto SEMPRE de FHistPreviewLines — Caption/SubItems podem estar vazios no paint
    da linha que o Win32 acabou de marcar Selected apos LVM_SETTOPINDEX. }
  if (Item.Index >= 0) and (Item.Index < FHistPreviewLines.Count) then
    txt := FHistPreviewLines[Item.Index]
  else if Item.SubItems.Count > 0 then
    txt := Item.SubItems[0]
  else
    txt := '';
  SetTextColor(DC, ColorToRGB(clBlack));
  ExtTextOut(DC, R1.Left + 3, R1.Top + 2, ETO_CLIPPED, @R1, PChar(txt), Length(txt), nil);

  if IsJournalHilite then
  begin
    DrawHistSelectionMarker(Sender.Canvas, RAll);
    Sender.Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TfrmCompareMerge.lvHistFileCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if (Item = nil) or (Item.Index < 0) or (Item.Index >= TListView(Sender).Items.Count) then
  begin
    DefaultDraw := True;
    Exit;
  end;
  DefaultDraw := False;
  PaintHistPreviewItem(Sender, Item);
end;

procedure TfrmCompareMerge.lvHistFileCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DefaultDraw := False;
  if SubItem = 0 then
    PaintHistPreviewItem(Sender, Item);
end;

procedure TfrmCompareMerge.lvHistFileAdvancedCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
  var DefaultDraw: Boolean);
begin
  { PostPaint: selecao/tema do Win32 pode pintar barra sem texto por cima do PrePaint. }
  if Stage = cdPostPaint then
    PaintHistPreviewItem(Sender, Item)
  else if Stage = cdPrePaint then
  begin
    DefaultDraw := False;
    PaintHistPreviewItem(Sender, Item);
  end;
end;

procedure TfrmCompareMerge.popLvLeftPopup(Sender: TObject);
var
  Differs: Boolean;
  Rr: PFFDiffRow;
begin
  mnuLCopy.Caption := TrText('Copy selection');
  mnuLApplyToRight.Caption := TrText('Apply left to right (disk)');
  mnuLApplyToLeft.Caption := TrText('Apply right to left (disk)');
  mnuLSelectAll.Caption := TrText('Select all');
  mnuLGoToLine.Caption := TrText('&Go to line...');

  Differs := False;
  if (lvLeft.Selected <> nil) and Assigned(FDiffRows) and
    (lvLeft.Selected.Index >= 0) and (lvLeft.Selected.Index < FDiffRows.Count) then
  begin
    Rr := PFFDiffRow(FDiffRows[lvLeft.Selected.Index]);
    Differs := Rr^.Kind <> ffdkEqual;
  end;

  if Differs then
  begin
    mnuLCopy.Visible := True;
    mnuLApplyToRight.Visible := True;
    mnuLApplyToLeft.Visible := False;
    mnuLSelectAll.Visible := False;
    mnuLGoToLine.Visible := True;
  end
  else
  begin
    { Linhas verdes (iguais): so' copiar e ir para linha. }
    mnuLCopy.Visible := True;
    mnuLApplyToRight.Visible := False;
    mnuLApplyToLeft.Visible := False;
    mnuLSelectAll.Visible := False;
    mnuLGoToLine.Visible := True;
  end;

  mnuLCopy.Enabled := lvLeft.SelCount > 0;
  mnuLApplyToRight.Enabled := Differs and ((lvLeft.SelCount > 0) or (lvRight.SelCount > 0));
  mnuLApplyToLeft.Enabled := False;
  mnuLSelectAll.Enabled := False;
  mnuLGoToLine.Enabled := lvLeft.Items.Count > 0;
end;

procedure TfrmCompareMerge.popLvRightPopup(Sender: TObject);
var
  Differs: Boolean;
  Rr: PFFDiffRow;
begin
  mnuRCopy.Caption := TrText('Copy selection');
  mnuRApplyToRight.Caption := TrText('Apply left to right (disk)');
  mnuRApplyToLeft.Caption := TrText('Apply right to left (disk)');
  mnuRSelectAll.Caption := TrText('Select all');
  mnuRGoToLine.Caption := TrText('&Go to line...');

  Differs := False;
  if (lvRight.Selected <> nil) and Assigned(FDiffRows) and
    (lvRight.Selected.Index >= 0) and (lvRight.Selected.Index < FDiffRows.Count) then
  begin
    Rr := PFFDiffRow(FDiffRows[lvRight.Selected.Index]);
    Differs := Rr^.Kind <> ffdkEqual;
  end;

  if Differs then
  begin
    mnuRCopy.Visible := True;
    mnuRApplyToLeft.Visible := True;
    mnuRApplyToRight.Visible := False;
    mnuRSelectAll.Visible := False;
    mnuRGoToLine.Visible := True;
  end
  else
  begin
    { Linhas verdes (iguais): so' copiar e ir para linha. }
    mnuRCopy.Visible := True;
    mnuRApplyToRight.Visible := False;
    mnuRApplyToLeft.Visible := False;
    mnuRSelectAll.Visible := False;
    mnuRGoToLine.Visible := True;
  end;

  mnuRCopy.Enabled := lvRight.SelCount > 0;
  mnuRApplyToRight.Enabled := False;
  mnuRApplyToLeft.Enabled := Differs and ((lvLeft.SelCount > 0) or (lvRight.SelCount > 0));
  mnuRSelectAll.Enabled := False;
  mnuRGoToLine.Enabled := lvRight.Items.Count > 0;
end;

procedure TfrmCompareMerge.mnuLCopyClick(Sender: TObject);
begin
  btnCopyLeftClick(nil);
end;

procedure TfrmCompareMerge.mnuLApplyToRightClick(Sender: TObject);
begin
  btnApplyLeftToRightClick(nil);
end;

procedure TfrmCompareMerge.mnuLApplyToLeftClick(Sender: TObject);
begin
  btnApplyRightToLeftClick(nil);
end;

procedure TfrmCompareMerge.mnuLSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvLeft.Items.Count - 1 do
    lvLeft.Items[i].Selected := True;
end;

procedure TfrmCompareMerge.mnuRCopyClick(Sender: TObject);
begin
  btnCopyRightClick(nil);
end;

procedure TfrmCompareMerge.mnuRApplyToRightClick(Sender: TObject);
begin
  btnApplyLeftToRightClick(nil);
end;

procedure TfrmCompareMerge.mnuRApplyToLeftClick(Sender: TObject);
begin
  btnApplyRightToLeftClick(nil);
end;

procedure TfrmCompareMerge.mnuRSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to lvRight.Items.Count - 1 do
    lvRight.Items[i].Selected := True;
end;

procedure TfrmCompareMerge.mnuLGoToLineClick(Sender: TObject);
var
  S: string;
  N: Integer;
begin
  if lvLeft.Items.Count < 1 then Exit;
  S := '';
  if not InputQuery(TrText('Ir para linha'), TrText('Numero da linha (1..') + IntToStr(lvLeft.Items.Count) + '):', S) then Exit;
  N := StrToIntDef(Trim(S), -1);
  if (N >= 1) and (N <= lvLeft.Items.Count) then
  begin
    lvLeft.Items[N - 1].Selected := True;
    lvLeft.Items[N - 1].Focused := True;
    lvLeft.Items[N - 1].MakeVisible(False);
    lvLeft.Invalidate;
    FDiffScrollLastSource := 1;
    SyncDiffScrollPeerFrom(lvLeft);
  end;
end;

procedure TfrmCompareMerge.mnuRGoToLineClick(Sender: TObject);
var
  S: string;
  N: Integer;
begin
  if lvRight.Items.Count < 1 then Exit;
  S := '';
  if not InputQuery(TrText('Ir para linha'), TrText('Numero da linha (1..') + IntToStr(lvRight.Items.Count) + '):', S) then Exit;
  N := StrToIntDef(Trim(S), -1);
  if (N >= 1) and (N <= lvRight.Items.Count) then
  begin
    lvRight.Items[N - 1].Selected := True;
    lvRight.Items[N - 1].Focused := True;
    lvRight.Items[N - 1].MakeVisible(False);
    lvRight.Invalidate;
    FDiffScrollLastSource := 2;
    SyncDiffScrollPeerFrom(lvRight);
  end;
end;

procedure TfrmCompareMerge.JournalJumpPreviewFromCp(const Cp: Integer);
var
  lineIx: Integer;
begin
  if not Assigned(mmoJournal) or (mmoJournal.Lines.Count <= 0) then Exit;
  if not Assigned(FJournalLineNums) or (FJournalLineNums.Count <> mmoJournal.Lines.Count) then Exit;
  lineIx := mmoJournal.Perform(EM_LINEFROMCHAR, Cp, 0);
  JournalJumpPreviewFromLine(lineIx);
end;

procedure TfrmCompareMerge.JournalJumpPreviewFromLine(const LineIx: Integer);
var
  Ln, found, tag: Integer;
  excerpt: string;
begin
  if (LineIx < 0) or (not Assigned(FJournalLineNums)) or
    (LineIx >= FJournalLineNums.Count) then Exit;
  EnsureHistPreviewGrid;
  if HistPreviewDataCount < 1 then Exit;
  JournalSelectMemoFullLine(LineIx);
  Ln := Integer(FJournalLineNums[LineIx]);
  tag := 0;
  excerpt := '';
  if Assigned(FJournalTags) and (LineIx < FJournalTags.Count) then
    tag := Integer(FJournalTags[LineIx]);
  if Assigned(FJournalExcerpts) and (LineIx < FJournalExcerpts.Count) then
    excerpt := FJournalExcerpts[LineIx];
  if Ln <= 0 then
  begin
    ClearHistJournalOverlay;
    FJournalPreviewHiliteIdx := -1;
    if Assigned(FsgHist) then FsgHist.Invalidate;
    Exit;
  end;
  if FJrnViewLine > 0 then
    Ln := FJrnViewLine;
  if (Ln >= 1) and (Ln <= HistPreviewDataCount) then
    found := Ln - 1
  else
    found := -1;
  if found < 0 then
  begin
    ClearHistJournalOverlay;
    FJournalPreviewHiliteIdx := -1;
    if Assigned(FsgHist) then FsgHist.Invalidate;
    Exit;
  end;
  FHistOverlayActive := True;
  FHistOverlayIdx := found;
  FHistOverlayTag := tag;
  FHistOverlayText := HistOverlayCaption(tag, excerpt);
  HistPreviewJumpToDataRow(found);
end;

procedure TfrmCompareMerge.mmoJournalClick(Sender: TObject);
begin
  { Click is also followed by MouseUp — do the jump only once, deferred
    (AlphaControls TacMainWnd AV if memo is rebuilt inside the skin WndProc). }
end;

procedure TfrmCompareMerge.mmoJournalMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  cp: Integer;
begin
  if Button <> mbLeft then Exit;
  if FClosing then Exit;
  if (mmoJournal.Lines.Count <= 0) or (FJournalLineNums.Count <> mmoJournal.Lines.Count) then Exit;
  cp := LongInt(SendMessage(mmoJournal.Handle, EM_CHARFROMPOS, 0, MakeLParam(LoWord(X), LoWord(Y))));
  if cp < 0 then cp := 0;
  RequestJournalJumpFromCp(cp);
end;

procedure TfrmCompareMerge.lvHistFileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  It: TListItem;
begin
  if Button <> mbLeft then Exit;
  It := lvHistFile.GetItemAt(X, Y);
  if It = nil then Exit;
  FJournalPreviewHiliteIdx := It.Index;
  EnsureHistPreviewItemText(It.Index);
  HistClearNativeSelection;
  lvHistFile.Invalidate;
end;

procedure TfrmCompareMerge.lvHistFileSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if not (Sender is TListView) then Exit;
  { Qualquer Selected que escape do LVN_ITEMCHANGING: limpar e manter texto. }
  if Selected and (Item <> nil) then
  begin
    EnsureHistPreviewItemText(Item.Index);
    if lvHistFile.HandleAllocated then
      ListView_SetItemState(lvHistFile.Handle, Item.Index, 0, LVIS_SELECTED or LVIS_FOCUSED);
    if FJournalPreviewHiliteIdx < 0 then
      FJournalPreviewHiliteIdx := Item.Index;
  end;
  TListView(Sender).Invalidate;
end;

procedure TfrmCompareMerge.popLvHistPopup(Sender: TObject);
var
  LV: TListView;
  hasHistFocus: Boolean;
begin
  if PageControl1.ActivePage = TabSheetHistory then
  begin
    FPopupHistTargetLV := nil;
    hasHistFocus := (FJournalPreviewHiliteIdx >= 0) and
      (FJournalPreviewHiliteIdx < HistPreviewDataCount);
    mnuHistCopyLine.Caption := TrText('Copy preview line (number and text)');
    mnuHistCopyText.Caption := TrText('Copy preview text only');
    mnuHistGotoLine.Caption := TrText('&Go to line...');
    mnuHistSelectAll.Caption := TrText('Select all');
    mnuHistCopyLine.Enabled := hasHistFocus;
    mnuHistCopyText.Enabled := hasHistFocus;
    mnuHistGotoLine.Enabled := HistPreviewDataCount > 0;
    mnuHistSelectAll.Enabled := False;
    Exit;
  end;
  LV := ResolveHistPopupListView;
  if LV = nil then
    LV := lvLeft;
  FPopupHistTargetLV := LV;
  mnuHistCopyLine.Caption := TrText('Copy preview line (number and text)');
  mnuHistCopyText.Caption := TrText('Copy preview text only');
  mnuHistGotoLine.Caption := TrText('&Go to line...');
  mnuHistSelectAll.Caption := TrText('Select all');
  mnuHistCopyLine.Enabled := LV.Selected <> nil;
  mnuHistCopyText.Enabled := (LV.Selected <> nil) and (LV.Selected.SubItems.Count > 0);
  mnuHistGotoLine.Enabled := LV.Items.Count > 0;
  mnuHistSelectAll.Enabled := LV.Items.Count > 0;
end;

procedure TfrmCompareMerge.mnuHistCopyLineClick(Sender: TObject);
var
  It: TListItem;
  LV: TListView;
  idx: Integer;
begin
  if PageControl1.ActivePage = TabSheetHistory then
  begin
    idx := FJournalPreviewHiliteIdx;
    if (idx < 0) or (idx >= HistPreviewDataCount) then Exit;
    Clipboard.AsText := IntToStr(idx + 1) + #9 + HistPreviewCellText(idx);
    Exit;
  end;
  LV := ResolveHistTargetListView;
  if LV.Selected = nil then Exit;
  It := LV.Selected;
  if It.SubItems.Count > 0 then
    Clipboard.AsText := It.Caption + #9 + It.SubItems[0]
  else
    Clipboard.AsText := It.Caption;
end;

procedure TfrmCompareMerge.mnuHistCopyTextClick(Sender: TObject);
var
  LV: TListView;
  idx: Integer;
begin
  if PageControl1.ActivePage = TabSheetHistory then
  begin
    idx := FJournalPreviewHiliteIdx;
    if (idx < 0) or (idx >= HistPreviewDataCount) then Exit;
    Clipboard.AsText := HistPreviewCellText(idx);
    Exit;
  end;
  LV := ResolveHistTargetListView;
  if LV.Selected = nil then Exit;
  if LV.Selected.SubItems.Count = 0 then Exit;
  Clipboard.AsText := LV.Selected.SubItems[0];
end;

procedure TfrmCompareMerge.mnuHistGotoLineClick(Sender: TObject);
var
  LV: TListView;
  S: string;
  N: Integer;
begin
  if PageControl1.ActivePage = TabSheetHistory then
  begin
    if HistPreviewDataCount < 1 then Exit;
    S := '';
    if not InputQuery(TrText('Ir para linha'), TrText('Numero da linha (1..') +
      IntToStr(HistPreviewDataCount) + '):', S) then Exit;
    N := StrToIntDef(Trim(S), -1);
    if (N >= 1) and (N <= HistPreviewDataCount) then
      HistPreviewJumpToDataRow(N - 1);
    Exit;
  end;
  LV := ResolveHistTargetListView;
  if LV.Items.Count < 1 then Exit;
  S := '';
  if not InputQuery(TrText('Ir para linha'), TrText('Numero da linha (1..') + IntToStr(LV.Items.Count) + '):', S) then Exit;
  N := StrToIntDef(Trim(S), -1);
  if (N < 1) or (N > LV.Items.Count) then Exit;
  LV.Items[N - 1].Selected := True;
  LV.Items[N - 1].Focused := True;
  LV.Items[N - 1].MakeVisible(False);
  LV.Invalidate;
  if (LV = lvLeft) or (LV = lvRight) then
  begin
    if LV = lvLeft then FDiffScrollLastSource := 1 else FDiffScrollLastSource := 2;
    SyncDiffScrollPeerFrom(LV);
  end;
end;

procedure TfrmCompareMerge.mnuHistSelectAllClick(Sender: TObject);
var
  i: Integer;
  LV: TListView;
begin
  if PageControl1.ActivePage = TabSheetHistory then Exit;
  LV := ResolveHistTargetListView;
  if (LV = nil) or (LV = lvHistFile) then Exit;
  for i := 0 to LV.Items.Count - 1 do
    LV.Items[i].Selected := True;
  LV.Invalidate;
end;

procedure TfrmCompareMerge.lvMergeListSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  LV: TListView;
begin
  if not (Sender is TListView) then Exit;
  LV := TListView(Sender);
  LV.Invalidate;
  if not Selected or (Item = nil) then Exit;
  if (LV = lvLeft) or (LV = lvRight) then
  begin
    if LV = lvLeft then FDiffScrollLastSource := 1 else FDiffScrollLastSource := 2;
    { Nao sincronizar scroll aqui: MakeVisible/WM_VSCROLL ja' passam pelo LvDiff*WndProc;
      DiffApply no OnSelectItem podia reentrar e travar a UI ao combinar com copiar/aplicar. }
  end;
end;

procedure TfrmCompareMerge.lvLeftData(Sender: TObject; Item: TListItem);
var
  Rr: PFFDiffRow;
begin
  if (Item.Index >= 0) and (Item.Index < FDiffRows.Count) then
  begin
    Rr := PFFDiffRow(FDiffRows[Item.Index]);
    Item.Data := Rr;
    if Rr^.LNum > 0 then Item.Caption := IntToStr(Rr^.LNum) else Item.Caption := '';
    if Item.SubItems.Count = 0 then Item.SubItems.Add(Rr^.LText) else Item.SubItems[0] := Rr^.LText;
  end;
end;

procedure TfrmCompareMerge.lvRightData(Sender: TObject; Item: TListItem);
var
  Rr: PFFDiffRow;
begin
  if (Item.Index >= 0) and (Item.Index < FDiffRows.Count) then
  begin
    Rr := PFFDiffRow(FDiffRows[Item.Index]);
    Item.Data := Rr;
    if Rr^.RNum > 0 then Item.Caption := IntToStr(Rr^.RNum) else Item.Caption := '';
    if Item.SubItems.Count = 0 then Item.SubItems.Add(Rr^.RText) else Item.SubItems[0] := Rr^.RText;
  end;
end;

procedure TfrmCompareMerge.lvLeftCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  RAll, R0, R1: TRect;
  K: TFFDiffKind;
  LV: TListView;
  cw0: Integer;
begin
  LV := TListView(Sender);
  if (Item = nil) or (Item.Index < 0) or (Item.Index >= LV.Items.Count) then
  begin
    DefaultDraw := True;
    Exit;
  end;
  DefaultDraw := False;
  { OwnerData: Item.Data nem sempre preenchido; FDiffRows e' a fonte de verdade. }
  if Assigned(FDiffRows) and (Item.Index >= 0) and (Item.Index < FDiffRows.Count) then
    K := PFFDiffRow(FDiffRows[Item.Index])^.Kind
  else if Item.Data <> nil then
    K := PFFDiffRow(Item.Data)^.Kind
  else
    K := ffdkEqual;
  if Item.Selected then
  begin
    Sender.Canvas.Brush.Color := clHighlight;
    Sender.Canvas.Font.Color := clHighlightText;
  end
  else
  begin
    Sender.Canvas.Brush.Color := BrushForKind(K);
    Sender.Canvas.Font.Color := clWindowText;
  end;
  RAll := Item.DisplayRect(drBounds);
  Sender.Canvas.FillRect(RAll);
  cw0 := 56;
  if LV.Columns.Count > 0 then
    cw0 := LV.Columns[0].Width;
  R0 := RAll;
  R0.Right := Min(RAll.Left + cw0, RAll.Right);
  R1 := RAll;
  R1.Left := R0.Right;
  Sender.Canvas.TextRect(R0, R0.Left + 3, R0.Top + 2, Item.Caption);
  if Item.SubItems.Count > 0 then
    Sender.Canvas.TextRect(R1, R1.Left + 3, R1.Top + 2, Item.SubItems[0]);
end;

procedure TfrmCompareMerge.lvRightCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  lvLeftCustomDrawItem(Sender, Item, State, DefaultDraw);
end;

procedure TfrmCompareMerge.UpdateFastLargeFilesCaption;
var
  forceMB: Integer;
begin
  if not Assigned(chkFastLargeFiles) then Exit;
  forceMB := Integer(FFComputeDynamicForceRangeBytes(Trim(edtLeftFile.Text), Trim(edtRightFile.Text)) div cOneMB);
  if forceMB < 1 then forceMB := 1;
  chkFastLargeFiles.Caption :=
    Format(TrText('Fast mode for large files (auto range above %d MB)'), [forceMB]);
end;

procedure TfrmCompareMerge.LayoutDiffHeaderControls;
var
  RightEdge, CapW, RowTop, BtnH, Gap, LvTop: Integer;
begin
  if not Assigned(TabSheetDiff) then Exit;
  RightEdge := TabSheetDiff.ClientWidth - 8;
  if RightEdge < 200 then RightEdge := 200;

  if Assigned(chkSyncScroll) then
  begin
    if chkSyncScroll.Width < 160 then
      chkSyncScroll.Width := 160;
    if chkSyncScroll.Left + chkSyncScroll.Width > RightEdge then
      chkSyncScroll.Width := Max(120, RightEdge - chkSyncScroll.Left);
  end;
  if Assigned(chkDiffByLines) then
  begin
    chkDiffByLines.Width := Max(160, RightEdge - chkDiffByLines.Left);
  end;
  if Assigned(chkFastLargeFiles) then
  begin
    chkFastLargeFiles.WordWrap := True;
    CapW := Max(220, RightEdge - chkFastLargeFiles.Left);
    chkFastLargeFiles.Width := CapW;
    { Altura suficiente para 2 linhas do caption traduzido (sem cortar nos botoes). }
    chkFastLargeFiles.Height := Max(28, Canvas.TextHeight('Ag') * 2 + 6);
  end;

  RowTop := 112;
  if Assigned(lblLegend) then
    RowTop := Max(RowTop, lblLegend.Top + 18);
  if Assigned(chkDiffByLines) then
    RowTop := Max(RowTop, chkDiffByLines.Top + chkDiffByLines.Height + 4);
  if Assigned(chkFastLargeFiles) then
    RowTop := Max(RowTop, chkFastLargeFiles.Top + chkFastLargeFiles.Height + 6);

  BtnH := 25;
  Gap := 8;
  if Assigned(btnCopyLeft) then
  begin
    btnCopyLeft.Top := RowTop;
    btnCopyLeft.Height := BtnH;
  end;
  if Assigned(btnCopyRight) then
  begin
    btnCopyRight.Top := RowTop;
    btnCopyRight.Height := BtnH;
  end;
  if Assigned(btnApplyLeftToRight) then
  begin
    btnApplyLeftToRight.Top := RowTop;
    btnApplyLeftToRight.Height := BtnH;
  end;
  if Assigned(btnApplyRightToLeft) then
  begin
    btnApplyRightToLeft.Top := RowTop;
    btnApplyRightToLeft.Height := BtnH;
  end;

  LvTop := RowTop + BtnH + Gap;
  if Assigned(lvLeft) then
    lvLeft.Top := LvTop;
  if Assigned(lvRight) then
    lvRight.Top := LvTop;
end;

procedure TfrmCompareMerge.LayoutDiffListViews;
var
  W, H, Lw, tw: Integer;
begin
  if not Assigned(TabSheetDiff) then Exit;
  LayoutDiffHeaderControls;
  W := TabSheetDiff.ClientWidth - 16;
  H := TabSheetDiff.ClientHeight - lvLeft.Top - 8;
  if H < 80 then H := 80;
  Lw := (W div 2) - 6;
  lvLeft.SetBounds(8, lvLeft.Top, Lw, H);
  lvRight.SetBounds(8 + Lw + 8, lvRight.Top, W - Lw - 8, H);
  if lvLeft.Columns.Count >= 2 then
  begin
    lvLeft.Columns[0].Width := 56;
    tw := Lw - 68;
    if tw < 160 then tw := 160;
    lvLeft.Columns[1].Width := tw;
  end;
  if lvRight.Columns.Count >= 2 then
  begin
    lvRight.Columns[0].Width := 56;
    tw := (W - Lw - 8) - 68;
    if tw < 160 then tw := 160;
    lvRight.Columns[1].Width := tw;
  end;
end;

procedure TfrmCompareMerge.TabSheetDiffResize(Sender: TObject);
begin
  LayoutDiffListViews;
end;

procedure TfrmCompareMerge.FormCreate(Sender: TObject);
begin
  FDiffRows := TList.Create;
  FJournalLineNums := TList.Create;
  FJournalTags := TList.Create;
  FJournalExcerpts := TStringList.Create;
  FJournalCacheLines := TStringList.Create;
  FJournalCacheLineNums := TList.Create;
  FJournalCacheLineEnds := TList.Create;
  FJournalCacheTags := TList.Create;
  FJournalCacheExcerpts := TStringList.Create;
  FJournalRaws := TStringList.Create;
  FJournalCacheRaws := TStringList.Create;
  FChgSel := TDictionary<Int64, Byte>.Create;
  FChgUnsel := TDictionary<Int64, Byte>.Create;
  FJrnSel := TDictionary<string, Byte>.Create;
  FHistPreviewLines := TStringList.Create;
  FHistShowAllJournal := False;
  FApplyingJournalView := False;
  FApplyJournalViewPosted := False;
  FJournalJumpPosted := False;
  FPendingJournalJumpCp := 0;
  FPendingJournalJumpLine := -1;
  FchkHistShowAll := nil;
  FlblChangedLines := nil;
  FlbChangedLines := nil;
  FedtHistSource := nil;
  FbtnHistSourceMru := nil;
  FchkHistChangedList := nil;
  FbtnChangedCollapse := nil;
  FbtnChangedClear := nil;
  FbtnChangedExpand := nil;
  FpnlJournalBox := nil;
  FpnlJournalHdr := nil;
  FlblJournalHdr := nil;
  FbtnJournalFloat := nil;
  FpnlPreviewBox := nil;
  FpnlPreviewHdr := nil;
  FbtnPreviewFloat := nil;
  FHistJournalHost := nil;
  FHistPreviewHost := nil;
  FHistHdrDown := False;
  FHistSourceItems := nil;
  FChgIdx := nil;
  FChgBuilder := nil;
  FChgDirty := False;
  FChgAutoSelPending := True;
  FChgBuildPct := -1;
  FChgPage := 0;
  FChgEvtScan := nil;
  FChgEvtLine := 0;
  FChgEvtRaw := nil;
  FbtnChgFirst := nil;
  FbtnChgPrev := nil;
  FbtnChgNext := nil;
  FbtnChgLast := nil;
  FlblChgPage := nil;
  FedtChgGoto := nil;
  FbtnChgGoto := nil;
  FChgWnd := AllocateHWnd(ChgWndProc);
  FMergeThread := nil;
  FDiffRestoreTop := -1;
  FDiffRestoreSel := -1;
  FDiffRestoreLv := nil;
  FDiffMergeOkMsg := False;
  FDiffLo := 1;
  FDiffSyncLastTopL := -1;
  FDiffSyncLastTopR := -1;
  FDiffScrollLastSource := 0;
  FDiffThumbScroll := False;
  FNeedMainReload := False;
  FClosing := False;
  FHistoryLoaded := False;
  FClosePosted := False;
  FHistReloadProgTarget := 0;
  FHistReloadProgLastPosted := -1;
  FHistReloadProgLastFlushTick := 0;
  FJournalPreviewHiliteIdx := -1;
  FHistOverlayActive := False;
  FHistOverlayIdx := -1;
  FHistOverlayTag := 0;
  FHistOverlayText := '';
  FHistJumpIgnoreSel := False;
  FHistClearSelTicks := 0;
  FHistClearSelTimer := TTimer.Create(Self);
  FHistClearSelTimer.Enabled := False;
  FHistClearSelTimer.Interval := 30;
  FHistClearSelTimer.OnTimer := tmrHistClearSelTimer;
  FHistReloadUITimer := TTimer.Create(Self);
  FHistReloadUITimer.Enabled := False;
  FHistReloadUITimer.Interval := 16;
  FHistReloadUITimer.OnTimer := tmrHistReloadUITimer;
  chkSyncScroll.Checked := True;
  if Assigned(chkFastLargeFiles) then
    chkFastLargeFiles.Checked := True;
  { Modo por faixa e' o default para manter desempenho previsivel em ficheiros grandes. }
  chkDiffByLines.Checked := True;
  { tmrSync: alinhamento Diff L/R sem WindowProc (subclass causava ACCESS_VIOLATION). }
  tmrSync.Enabled := True;
  FSyncingDiffScroll := False;
  FSyncingHistScroll := False;
  FMemoJournalHooked := False;
  FOldMemoJournalWndProc := nil;
  FOldLvLeftWndProc := nil;
  FOldLvRightWndProc := nil;
  FOldSgHistWndProc := nil;
  FOldLvHistWndProc := nil;
  { Do not subclass ListView/RichEdit WindowProc — unstable with handle recreate / skins. }
  FsgHist := nil;
  FsgJournal := nil;
  FJournalGridSelLine := -1;
  FJournalMaxChars := 0;
  FpbHistLegend := nil;
  EnsureJournalGrid;
  EnsureHistPreviewGrid;
  if Assigned(lvHistFile) then
  begin
    lvHistFile.Visible := False;
    lvHistFile.Enabled := False;
  end;
  mmoJournal.Visible := False;
  mmoJournal.Font.Charset := DEFAULT_CHARSET;
  mmoJournal.Font.Name := 'Consolas';
  if mmoJournal.Font.Name <> 'Consolas' then
    mmoJournal.Font.Name := 'Courier New';
  mmoJournal.Font.Color := clBlack;
  EnsureHistShowAllCheckBox;
  EnsureHistDockControls;
  EnsureHistSourceMru;
  EnsureJournalLeftGutterMargin;
  lvLeft.OnData := lvLeftData;
  lvRight.OnData := lvRightData;
  tmrSync.Interval := 200;
  { OnClick / OnMouseUp repostos após carga diferida. }
  mmoJournal.OnClick := nil;
  mmoJournal.OnMouseUp := nil;
  FPopupHistTargetLV := nil;
  FEmbeddedMode := False;
  lvLeft.MultiSelect := False;
  lvRight.MultiSelect := False;
  chkDiffByLinesClick(nil);
end;

procedure TfrmCompareMerge.tmrHistReloadUITimer(Sender: TObject);
var
  p: Integer;
begin
  if FClosing then Exit;
  p := FHistReloadProgTarget;
  if p < 0 then p := 0 else if p > 100 then p := 100;
  TfrmSmoothLoading.UpdateProgress(p);
end;

procedure TfrmCompareMerge.WMHistProgressFlush(var Msg: TMessage);
var
  M: TMsg;
  p: Integer;
begin
  if FClosing then Exit;
  while PeekMessage(M, Handle, WM_FF_HIST_PROGRESS_FLUSH, WM_FF_HIST_PROGRESS_FLUSH, PM_REMOVE) do ;
  p := FHistReloadProgTarget;
  if p < 0 then p := 0 else if p > 100 then p := 100;
  TfrmSmoothLoading.UpdateProgress(p);
  Msg.Result := 0;
end;

procedure TfrmCompareMerge.WMDiffProgressFlush(var Msg: TMessage);
var
  M: TMsg;
  p: Integer;
begin
  if FClosing then Exit;
  while PeekMessage(M, Handle, WM_FF_DIFF_PROGRESS_FLUSH, WM_FF_DIFF_PROGRESS_FLUSH, PM_REMOVE) do ;
  p := FDiffProgTarget;
  if p < 0 then p := 0 else if p > 100 then p := 100;
  TfrmSmoothLoading.UpdateProgress(p);
  Msg.Result := 0;
end;

procedure TfrmCompareMerge.DiffWorkerThreadDone(Sender: TObject);
begin
  if Sender = FDiffWorkerThread then
    FDiffWorkerThread := nil;
  { Botao re-habilitado em SyncApply (ou no except handler). Se FClosing, garante re-enable. }
  if FClosing then Exit;
  if Assigned(btnRunDiff) then
    btnRunDiff.Enabled := True;
end;

function TfrmCompareMerge.WheelOverControl(ACtrl: TWinControl; const ScreenPt: TPoint): Boolean;
var
  P: TPoint;
begin
  Result := False;
  if not Assigned(ACtrl) or (not ACtrl.HandleAllocated) or (not IsWindowVisible(ACtrl.Handle)) then Exit;
  P := ACtrl.ScreenToClient(ScreenPt);
  Result := PtInRect(ACtrl.ClientRect, P);
end;

procedure TfrmCompareMerge.WheelScrollControl(ACtrl: TWinControl; WheelDelta: Integer);
var
  i: Integer;
  ScrollCode: WPARAM;
begin
  if not Assigned(ACtrl) or (not ACtrl.HandleAllocated) or (WheelDelta = 0) then Exit;
  if WheelDelta < 0 then
    ScrollCode := SB_LINEDOWN
  else
    ScrollCode := SB_LINEUP;
  for i := 1 to 3 do
    ACtrl.Perform(WM_VSCROLL, ScrollCode, 0);
end;

function TfrmCompareMerge.TryScrollWheelAt(const ScreenPt: TPoint; WheelDelta: Integer): Boolean;
var
  C: TWinControl;
begin
  { Ctrl+roda: o frmMain consome a mensagem para zoom da ListView principal.
    Sobre o preview do historico a mesma roda desloca as linhas. }
  Result := False;
  if FClosing or (WheelDelta = 0) or (not Visible) then Exit;
  if not Assigned(PageControl1) then Exit;

  if PageControl1.ActivePage = TabSheetDiff then
  begin
    if WheelOverControl(lvLeft, ScreenPt) then
    begin
      WheelScrollControl(lvLeft, WheelDelta);
      DiffApplyTopIndexToPeer(lvLeft);
      Result := True;
    end
    else if WheelOverControl(lvRight, ScreenPt) then
    begin
      WheelScrollControl(lvRight, WheelDelta);
      DiffApplyTopIndexToPeer(lvRight);
      Result := True;
    end;
  end
  else if PageControl1.ActivePage = TabSheetHistory then
  begin
    if WheelOverControl(FlbChangedLines, ScreenPt) then
    begin
      ChgWheelScroll(WheelDelta);
      Result := True;
    end
    else if WheelOverControl(FsgJournal, ScreenPt) then
    begin
      WheelScrollControl(FsgJournal, WheelDelta);
      Result := True;
    end
    else if WheelOverControl(FsgHist, ScreenPt) and (HistPreviewDataCount > 0) then
    begin
      WheelScrollControl(FsgHist, WheelDelta);
      Result := True;
    end;
  end;
  if Result then Exit;
  { Qualquer outra lista/memo com barra vertical sob o rato rola sem precisar de foco. }
  C := FindVCLWindow(ScreenPt);
  if (C = nil) or (C = FsgHist) or not ContainsControl(C) or not C.HandleAllocated then Exit;
  if (GetWindowLong(C.Handle, GWL_STYLE) and WS_VSCROLL) = 0 then Exit;
  WheelScrollControl(C, WheelDelta);
  Result := True;
end;

procedure TfrmCompareMerge.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  { Mesmo padrao que TfrmMain.FormMouseWheel: roda -> Perform(WM_VSCROLL) na lista sob o rato.
    O LvDiff*WndProc trata cada WM_VSCROLL e, com chkSyncScroll, alinha o par. }
  Handled := TryScrollWheelAt(MousePos, WheelDelta);
end;

procedure TfrmCompareMerge.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FEmbeddedMode and (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    if Assigned(FOnEscapeEmbedded) then
      FOnEscapeEmbedded(Self);
    Exit;
  end;
  if FClosing or FClosePosted then Exit;
  { ESC: WM_CLOSE na fila seguinte evita fecho sincrono dentro do KeyDown (skin/AlphaControls). }
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    FClosePosted := True;
    PostMessage(Handle, WM_CLOSE, 0, 0);
  end;
end;

procedure TfrmCompareMerge.FormShow(Sender: TObject);
begin
  ApplyTranslationsToForm(Self);
  { Ctrl+Alt+* : não coincide com o frmMain (Ctrl+G, Ctrl+C, …); válidos com o modal em foco. }
  mnuHistGotoLine.ShortCut := ShortCut(Ord('G'), [ssCtrl, ssAlt]);
  mnuHistCopyLine.ShortCut := ShortCut(Ord('C'), [ssCtrl, ssAlt]);
  mnuHistCopyText.ShortCut := ShortCut(Ord('T'), [ssCtrl, ssAlt]);
  mnuHistSelectAll.ShortCut := ShortCut(Ord('A'), [ssCtrl, ssAlt]);
  ApplyUiLanguage;
  FitToMonitorWorkArea;
  if Assigned(btnClose) then
    btnClose.Visible := not FEmbeddedMode;
  { One-shot: após ~1 ciclo da fila a janela pinta; só então lemos journal/preview (evita UI "morta"). }
  SetTimer(Handle, cDeferHistTimerId, cDeferHistTimerMs, nil);
end;

procedure TfrmCompareMerge.WMFfLanguageChanged(var Msg: TMessage);
var
  i: Integer;
  OldLang: TAppLanguage;
begin
  if FClosing then Exit;
  OldLang := TAppLanguage(Msg.WParam);
  if Assigned(TabSheetHistory) then
    TabSheetHistory.Caption := TrText('Session history');
  if Assigned(TabSheetDiff) then
    TabSheetDiff.Caption := TrText('Two-file diff');
  if Assigned(btnReloadHist) then
    btnReloadHist.Caption := TrText('Reload');
  if Assigned(btnClearHist) then
    btnClearHist.Caption := TrText('Clear history');
  if Assigned(lblHistPath) then
    lblHistPath.Caption := RetranslateComposedText(lblHistPath.Caption, OldLang);
  { Status rows (line 0) were cached already translated. }
  if Assigned(FJournalCacheLines) and Assigned(FJournalCacheLineNums) then
    for i := 0 to FJournalCacheLines.Count - 1 do
      if (i < FJournalCacheLineNums.Count) and (Integer(FJournalCacheLineNums[i]) <= 0) then
        FJournalCacheLines[i] := RetranslateComposedText(FJournalCacheLines[i], OldLang);
  if FHistoryLoaded and Assigned(mmoJournal) then
    ApplyJournalDisplayMode;
  ApplyUiLanguage;
  if Assigned(FHistPaged) then
    UpdateHistPagedView;
  ApplyHistExportCaptions;
  if Assigned(FpbHistLegend) then
    FpbHistLegend.Invalidate;
  if Assigned(FsgHist) then
    FsgHist.Invalidate;
  if Assigned(FsgJournal) then
    FsgJournal.Invalidate;
  { Os eventos do diario sao formatados (TrText) na carga e ficam em cache ja traduzidos. }
  FreeAndNil(FChgEvtRaw);
  FChgEvtLine := 0;
  RebuildChangedLinesList;
  if FHistoryLoaded and not Assigned(FHistoryReloadThread) then
    ReloadHistoryMemoEx(False, False, True);
end;

procedure TfrmCompareMerge.ApplyUiLanguage;

  procedure SetMenu(AItem: TMenuItem; const AKey: string);
  begin
    if Assigned(AItem) then
      AItem.Caption := TrText(AKey);
  end;

begin
  { Chaves inglesas explicitas: a traducao generica por texto atual falha ao trocar de idioma. }
  lblLeft.Caption := TrText('Left file');
  lblRight.Caption := TrText('Right file');
  lblFirst.Caption := TrText('First line');
  lblLast.Caption := TrText('Last line');
  btnBrowseLeft.Caption := TrText('Browse...');
  btnBrowseRight.Caption := TrText('Browse...');
  btnRunDiff.Caption := TrText('Build diff');
  chkSyncScroll.Caption := TrText('Sync scroll');
  btnCopyLeft.Caption := TrText('Copy selected left');
  btnCopyRight.Caption := TrText('Copy selected right');
  btnApplyLeftToRight.Caption := TrText('Apply left to right (disk)');
  btnApplyRightToLeft.Caption := TrText('Apply right to left (disk)');
  btnClose.Caption := TrText('Close');
  if Assigned(TabSheetHistory) then
    TabSheetHistory.Caption := TrText('Session history');
  if Assigned(TabSheetDiff) then
    TabSheetDiff.Caption := TrText('Two-file diff');
  btnReloadHist.Caption := TrText('Reload');
  btnClearHist.Caption := TrText('Clear history');
  if not FEmbeddedMode then
    Caption := TrText('Compare / merge + session history');
  SetMenu(mnuLCopy, 'Copy selection');
  SetMenu(mnuRCopy, 'Copy selection');
  SetMenu(mnuLApplyToRight, 'Apply left to right (disk)');
  SetMenu(mnuRApplyToRight, 'Apply left to right (disk)');
  SetMenu(mnuLApplyToLeft, 'Apply right to left (disk)');
  SetMenu(mnuRApplyToLeft, 'Apply right to left (disk)');
  SetMenu(mnuLSelectAll, 'Select all');
  SetMenu(mnuRSelectAll, 'Select all');
  SetMenu(mnuHistSelectAll, 'Select all');
  SetMenu(mnuLGoToLine, '&Go to line...');
  SetMenu(mnuRGoToLine, '&Go to line...');
  SetMenu(mnuHistGotoLine, '&Go to line...');
  SetMenu(mnuHistCopyLine, 'Copy preview line');
  SetMenu(mnuHistCopyText, 'Copy preview text only');
  BuildLegendLabels;
  chkDiffByLines.Caption := TrText('Diff by lines (range)');
  UpdateFastLargeFilesCaption;
  lblNote.Caption := TrText('Use Apply buttons to save merged lines to disk (batched). Green (equal) rows are ignored.');
  lblHistPreview.Caption := TrText('History file preview (colors from journal; line numbers are as at edit time).');
  lblJournalHint.WordWrap := True;
  lblJournalHint.Caption :=
    Format(TrText('Hist.JournalHintFiltered: %d'), [cHistJournalMaxLines]) + #13#10 +
    TrText('Logged: INS/EDT/DEL, BINS/BAUT/BDEL (batch insert/autofill/delete), UNDO/REDO. Read panel: Ctrl+V / Shift+Insert paste X lines; drag Line # column to autofill blank rows; Ctrl+Shift+N insert multiple; Ctrl+Z / Ctrl+Y undo/redo the whole block.');
  lblJournalHint.Height := 34;
  EnsureHistShowAllCheckBox;
  if Assigned(FchkHistShowAll) then
  begin
    FchkHistShowAll.Caption := TrText('Hist.ShowAllJournal');
    FchkHistShowAll.Hint := TrText('Hist.ShowAllJournalHint');
  end;
  EnsureHistSourceMru;
  if Assigned(FedtHistSource) then
  begin
    FedtHistSource.TextHint := TrText('Hist.SourceMruCue');
    FedtHistSource.Hint := TrText('Hist.SourceMruHint');
    FbtnHistSourceMru.Hint := TrText('Hist.SourceMruHint');
  end;
  EnsureHistDockControls;
  UpdateHistDockCaptions;
  BuildHistoryJournalLegend;
  LayoutDiffListViews;
  LayoutHistoryTab;
  ApplyMergeListViewColumnCaptions;
  EnsureJournalLeftGutterMargin;
end;

procedure TfrmCompareMerge.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Th: TThread;
  tlim: Cardinal;
begin
  { Antes do teardown: aborta cargas e evita LVM_* no timer durante destruição. }
  FClosing := True;
  UnhookAllSubclassedWndProcs;
  KillTimer(Handle, cDeferHistTimerId);
  tmrSync.Enabled := False;
  Th := FHistoryReloadThread;
  if Assigned(Th) then
  begin
    Th.Terminate;
    { WaitFor bloqueava a fila do modal. Espera com bomba de mensagens ate OnTerminate
      limpar FHistoryReloadThread (Delphi 7: TThread sem WaitFor com timeout). }
    tlim := GetTickCount + 180000;
    while Assigned(FHistoryReloadThread) do
    begin
      Application.ProcessMessages;
      if Integer(GetTickCount - tlim) >= 0 then
        Break;
      Sleep(5);
    end;
  end;
end;

procedure TfrmCompareMerge.WMTimer(var Msg: TMessage);
begin
  if Msg.WParam <> cDeferHistTimerId then
  begin
    inherited;
    Exit;
  end;
  KillTimer(Handle, cDeferHistTimerId);
  try
    if not FClosing then
    begin
      try
        { Carga assincrona: FHistoryLoaded / tmrSync / OnClick ficam a cargo de HistoryReloadThreadDone. }
        ReloadHistoryMemoEx(False, True);
      except
        Application.HandleException(Self);
      end;
    end;
  finally
    if FClosing or not Assigned(FHistoryReloadThread) then
    begin
      FHistoryLoaded := True;
      mmoJournal.OnClick := mmoJournalClick;
      mmoJournal.OnMouseUp := mmoJournalMouseUp;
    end;
  end;
end;

procedure TfrmCompareMerge.FormClose(Sender: TObject; var Action: TCloseAction);
var
  saveJC: TNotifyEvent;
  saveMU: TMouseEvent;
begin
  FClosing := True;
  UnhookAllSubclassedWndProcs;
  StopHistExport;
  StopHistPagedPreview;
  StopChgThreads;
  StopMergeThread;
  FHistReloadUITimer.Enabled := False;
  tmrSync.Enabled := False;
  { Bloqueia repaints dos filhos durante Clear (reduz reentrancia no skin ao fechar). }
  if HandleAllocated then
    LockWindowUpdate(Handle);
  try
    lvLeft.Items.BeginUpdate;
    lvRight.Items.BeginUpdate;
    lvHistFile.Items.BeginUpdate;
    try
              { Fast clear for huge lists: switch to virtual mode instantly purges physical items }
        lvLeft.OwnerData := True;
        lvRight.OwnerData := True;
        lvLeft.Items.Count := 0;
        lvRight.Items.Count := 0;
        FHistPreviewLines.Clear;
        SetLength(FHistLineKinds, 0);
        lvHistFile.Items.Count := 0;
        if Assigned(FsgHist) then
          FsgHist.RowCount := 2;
    finally
      lvHistFile.Items.EndUpdate;
      lvRight.Items.EndUpdate;
      lvLeft.Items.EndUpdate;
    end;
    JournalListEnterMutation(saveJC, saveMU);
    try
      JournalCacheClear;
      JournalMetaClear;
      mmoJournal.Lines.Clear;
      if Assigned(FsgJournal) then
      begin
        FsgJournal.RowCount := 1;
        FsgJournal.Cells[0, 0] := '';
        if FsgJournal.ColCount > 1 then
          FsgJournal.Cells[1, 0] := '';
        FJournalGridSelLine := -1;
        FJournalMaxChars := 0;
        UpdateJournalColWidth;
      end;
    finally
      JournalListLeaveMutation(saveJC, saveMU);
    end;
  finally
    if HandleAllocated then
      LockWindowUpdate(0);
  end;
end;

procedure TfrmCompareMerge.FormDestroy(Sender: TObject);
begin
  FClosing := True;
  UnhookAllSubclassedWndProcs;
  StopHistExport;
  StopHistPagedPreview;
  StopChgThreads;
  StopMergeThread;
  if FChgWnd <> 0 then
  begin
    DeallocateHWnd(FChgWnd);
    FChgWnd := 0;
  end;
  FreeAndNil(FChgIdx);
  FreeAndNil(FChgEvtRaw);
  if Assigned(FormPopupMruList) and
     (TMethod(FormPopupMruList.OnPick).Data = Pointer(Self)) then
  begin
    FormPopupMruList.OnPick := nil;
    if FormPopupMruList.Visible then
      FormPopupMruList.ClosePopup(False);
  end;
  FreeAndNil(FHistSourceItems);
  { Os hosts pertencem ao form principal: devolver os paineis e liberta-los aqui. }
  if HistJournalFloating then
    FpnlJournalBox.Parent := TabSheetHistory;
  if HistPreviewFloating then
    FpnlPreviewBox.Parent := TabSheetHistory;
  if Assigned(FHistJournalHost) then
    FHistJournalHost.OnRequestDock := nil;
  if Assigned(FHistPreviewHost) then
    FHistPreviewHost.OnRequestDock := nil;
  FreeAndNil(FHistJournalHost);
  FreeAndNil(FHistPreviewHost);
  
  if Assigned(FDiffRows) and (FDiffRows.Count > 5000) then
  begin
    { Fast teardown for huge diffs: dispose records in a background thread to return UI instantly }
    TFFDiffRowGarbageCollector.Create(FDiffRows);
    FDiffRows := nil;
  end
  else
  begin
    FreeDiffRows;
    FreeAndNil(FDiffRows);
  end;
  
  FreeAndNil(FJournalLineNums);
  FreeAndNil(FJournalTags);
  FreeAndNil(FJournalExcerpts);
  FreeAndNil(FJournalCacheLines);
  FreeAndNil(FJournalCacheLineNums);
  FreeAndNil(FJournalCacheLineEnds);
  FreeAndNil(FJournalCacheTags);
  FreeAndNil(FJournalCacheExcerpts);
  FreeAndNil(FJournalRaws);
  FreeAndNil(FJournalCacheRaws);
  FreeAndNil(FChgSel);
  FreeAndNil(FChgUnsel);
  FreeAndNil(FJrnSel);
  FreeAndNil(FHistPreviewLines);
end;

procedure TfrmCompareMerge.ReloadHistoryMemo(AWithProgress: Boolean);
begin
  ReloadHistoryMemoEx(AWithProgress, False);
end;

procedure TfrmCompareMerge.ReloadHistoryMemoEx(AWithProgress: Boolean; ADelayedTimerFinish: Boolean;
  ANoSmoothLoading: Boolean);
var
  P: string;
  wasTmr: Boolean;
  ShowUI: Boolean;
begin
  if FClosing then Exit;
  if Assigned(FHistoryReloadThread) then Exit;
  UpdateHistSourceEdit;

  if Trim(FDefaultLeft) = '' then
  begin
    wasTmr := tmrSync.Enabled;
    tmrSync.Enabled := False;
    if Assigned(btnReloadHist) then
      btnReloadHist.Enabled := False;
    try
      if AWithProgress then
        Screen.Cursor := crHourGlass;
      try
        if FClosing then Exit;
        lblHistPath.Caption := TrText('No session history file yet. Edits will append here.');
        ClearHistPreviewListView;
        LoadJournalIntoListBox('', False);
      finally
        if AWithProgress then
          Screen.Cursor := crDefault;
      end;
    finally
      if not FClosing then
        tmrSync.Enabled := wasTmr
      else
        tmrSync.Enabled := False;
      if Assigned(btnReloadHist) and not FClosing then
        btnReloadHist.Enabled := True;
    end;
    Exit;
  end;

  FHistReloadDeferredFinish := ADelayedTimerFinish;
  FHistReloadWasTmrSync := tmrSync.Enabled;
  tmrSync.Enabled := False;
  { Nao desactivar Reload: o trabalho pesado e na thread + fatias; desactivar faz parecer "travado". }

  P := FFHistoryJournalPath(FDefaultLeft);
  { Smooth loading no Reload e na abertura embedded (ficheiros grandes podem demorar na thread). }
  ShowUI := ((not ADelayedTimerFinish) or FEmbeddedMode) and (not ANoSmoothLoading);
  THistoryReloadThread.Create(Self, P, Trim(FDefaultLeft), ShowUI);
  if ShowUI then
  begin
    FHistReloadProgTarget := 0;
    FHistReloadProgLastPosted := -1;
    FHistReloadProgLastFlushTick := 0;
    FHistReloadUITimer.Enabled := True;
  end;
end;

procedure TfrmCompareMerge.HistoryReloadThreadDone(Sender: TObject);
var
  defer: Boolean;
begin
  FHistReloadUITimer.Enabled := False;
  defer := FHistReloadDeferredFinish;
  if Sender = FHistoryReloadThread then
    FHistoryReloadThread := nil;
  if FClosing then Exit;
  if Assigned(btnReloadHist) then
    btnReloadHist.Enabled := True;
  if defer then
  begin
    FHistReloadDeferredFinish := False;
    FHistoryLoaded := True;
  end
  else
    FHistReloadDeferredFinish := False;
  mmoJournal.OnClick := mmoJournalClick;
  mmoJournal.OnMouseUp := mmoJournalMouseUp;
  ChgTryAutoSelectFirst;
end;

procedure TfrmCompareMerge.btnChangedClearClick(Sender: TObject);
begin
  btnClearHistClick(Sender);
end;

procedure TfrmCompareMerge.btnClearHistClick(Sender: TObject);
var
  LogPath: string;
begin
  if FClosing then Exit;
  if Assigned(FHistoryReloadThread) then Exit;
  if Trim(FDefaultLeft) = '' then Exit;
  LogPath := FFHistoryJournalPath(FDefaultLeft);
  if not FileExists(LogPath) then
  begin
    FastFileMessageBox(PChar(TrText('Hist.ClearNothing')), PChar(Caption),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  { A pasta de historico e' partilhada por todos os ficheiros: apaga-se so' o journal deste. }
  if FastFileMessageBox(
       PChar(Format(TrText('Hist.ClearConfirm: %s'), [ExtractFileName(Trim(FDefaultLeft))])),
       PChar(TrText('Hist.ClearTitle')),
       MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = IDYES then
  begin
    if not DeleteFile(LogPath) then
    begin
      FastFileMessageBox(
        PChar(Format(TrText('Hist.ClearFailed: %s'), [SysErrorMessage(GetLastError)])),
        PChar(Caption), MB_OK or MB_ICONERROR);
      Exit;
    end;
    FreeAndNil(FHistSourceItems);
    ClearHistJournalOverlay;

    mmoJournal.Lines.BeginUpdate;
    try
      JournalCacheClear;
      JournalCacheAdd(TrText('No session history file yet. Edits will append here.'), 0, 0, 0, '');
      FJournalPreviewHiliteIdx := -1;
      ApplyJournalDisplayMode;
    finally
      mmoJournal.Lines.EndUpdate;
    end;

    ClearHistPreviewListView;
    lblHistPath.Caption := TrText('No session history file yet. Edits will append here.');
  end;
end;


procedure TfrmCompareMerge.btnReloadHistClick(Sender: TObject);
begin
  ReloadHistoryMemo(True);
end;

procedure TfrmCompareMerge.btnBrowseLeftClick(Sender: TObject);
begin
  OpenDialog1.FileName := edtLeftFile.Text;
  if OpenDialog1.Execute then
  begin
    edtLeftFile.Text := OpenDialog1.FileName;
    FDefaultLeft := OpenDialog1.FileName;
  end;
end;

procedure TfrmCompareMerge.btnBrowseRightClick(Sender: TObject);
begin
  OpenDialog1.FileName := edtRightFile.Text;
  if OpenDialog1.Execute then
  begin
    edtRightFile.Text := OpenDialog1.FileName;
  end;
end;

procedure TfrmCompareMerge.btnRunDiffClick(Sender: TObject);
var
  Lo, Hi: Int64;
  LPath, RPath: string;
  UseByLines: Boolean;
  AutoFastEnabled: Boolean;
  ForceRangeBytes: Int64;
begin
  if FClosing then Exit;
  { Nao permite duplo clique enquanto o worker anterior ainda esta a correr. }
  if Assigned(FDiffWorkerThread) then Exit;

  LPath := Trim(edtLeftFile.Text);
  RPath := Trim(edtRightFile.Text);
  if (LPath = '') or (RPath = '') then
  begin
    MessageDlg(TrText('Please select both Left and Right files.'), mtWarning, [mbOK], 0);
    Exit;
  end;
  if not FileExists(LPath) then
  begin
    MessageDlg(TrText('Please choose an existing left file.'), mtWarning, [mbOK], 0);
    Exit;
  end;
  if not FileExists(RPath) then
  begin
    MessageDlg(TrText('Please choose an existing right file.'), mtWarning, [mbOK], 0);
    Exit;
  end;
  Lo := StrToIntDef(edtFirstLine.Text, 1);
  Hi := StrToIntDef(edtLastLine.Text, Lo + FF_DIFF_MAX_LINES);
  UseByLines := chkDiffByLines.Checked;
  AutoFastEnabled := Assigned(chkFastLargeFiles) and chkFastLargeFiles.Checked;
  ForceRangeBytes := FFComputeDynamicForceRangeBytes(LPath, RPath);
  UpdateFastLargeFilesCaption;
  LayoutDiffHeaderControls;
  if (not UseByLines) and FFShouldForceRangeDiff(LPath, RPath, AutoFastEnabled, ForceRangeBytes) then
  begin
    UseByLines := True;
    chkDiffByLines.Checked := True;
    chkDiffByLinesClick(nil);
    edtFirstLine.Text := '1';
    edtLastLine.Text := IntToStr(FF_DIFF_MAX_LINES);
    Lo := 1;
    Hi := FF_DIFF_MAX_LINES;
  end;

  { Desabilita o botao durante o processamento; TDiffWorkerThread re-habilita em SyncApply. }
  if Assigned(btnRunDiff) then
    btnRunDiff.Enabled := False;

  { Arranca a thread; UI permanece responsiva durante leitura + diff. }
  TDiffWorkerThread.Create(Self, LPath, RPath, Lo, Hi, UseByLines, AutoFastEnabled,
    ForceRangeBytes);
end;

procedure TfrmCompareMerge.RunDiffSync;
{ Executa o diff de forma sincrona, sem thread nem overlay.
  Usado internamente apos operacoes de merge que necessitam dos resultados imediatamente. }
var
  Left, Right: TStringList;
  Lo, Hi: Int64;
  LPath, RPath: string;
  i: Integer;
  UseByLines: Boolean;
  AutoFastEnabled: Boolean;
  ForceRangeBytes: Int64;
  ReadHi: Int64;
  WindowLines: Int64;
begin
  if FClosing then Exit;
  LPath := Trim(edtLeftFile.Text);
  RPath := Trim(edtRightFile.Text);
  if (LPath = '') or (RPath = '') or
     (not FileExists(LPath)) or (not FileExists(RPath)) then Exit;

  Lo := StrToIntDef(edtFirstLine.Text, 1);
  Hi := StrToIntDef(edtLastLine.Text, Lo + FF_DIFF_MAX_LINES);
  UseByLines := chkDiffByLines.Checked;
  AutoFastEnabled := Assigned(chkFastLargeFiles) and chkFastLargeFiles.Checked;
  ForceRangeBytes := FFComputeDynamicForceRangeBytes(LPath, RPath);
  if (not UseByLines) and FFShouldForceRangeDiff(LPath, RPath, AutoFastEnabled, ForceRangeBytes) then
  begin
    UseByLines := True;
    Lo := 1;
    Hi := FF_DIFF_MAX_LINES;
  end;

  Left := TStringList.Create;
  Right := TStringList.Create;
  try
    if UseByLines then
    begin
      ReadHi := Hi + FF_DIFF_RANGE_LOOKAHEAD;
      WindowLines := Hi - Lo + 1;
      if WindowLines < 1 then WindowLines := 1;
      ReadTextFileLineSlice(LPath, Lo, ReadHi, Left, @FClosing, True, nil, High(Int64));
      ReadTextFileLineSlice(RPath, Lo, ReadHi, Right, @FClosing, True, nil, High(Int64));
      if FClosing then Exit;
      FFBuildLineDiffRows(Left, Right, FF_DIFF_MAX_LINES, FDiffRows);
      FFTrimDiffRowsToWindow(FDiffRows, WindowLines);
    end
    else
    begin
      ReadTextFileLineSlice(LPath, 1, High(Int64), Left, @FClosing, True, nil, High(Int64));
      ReadTextFileLineSlice(RPath, 1, High(Int64), Right, @FClosing, True, nil, High(Int64));
      if FClosing then Exit;
      FFBuildLineDiffRows(Left, Right, MaxInt, FDiffRows);
    end;
  finally
    Right.Free;
    Left.Free;
  end;

  if UseByLines then
    FDiffLo := Lo
  else
    FDiffLo := 1;
  lvLeft.Items.Clear;
  lvRight.Items.Clear;
  lvLeft.OwnerData := not UseByLines;
  lvRight.OwnerData := not UseByLines;

  if UseByLines then
  begin
    for i := 0 to FDiffRows.Count - 1 do
    begin
      with lvLeft.Items.Add do
      begin
        if PFFDiffRow(FDiffRows[i])^.LNum > 0 then
          Caption := IntToStr(PFFDiffRow(FDiffRows[i])^.LNum)
        else
          Caption := '';
        SubItems.Add(PFFDiffRow(FDiffRows[i])^.LText);
        Data := FDiffRows[i];
      end;
      with lvRight.Items.Add do
      begin
        if PFFDiffRow(FDiffRows[i])^.RNum > 0 then
          Caption := IntToStr(PFFDiffRow(FDiffRows[i])^.RNum)
        else
          Caption := '';
        SubItems.Add(PFFDiffRow(FDiffRows[i])^.RText);
        Data := FDiffRows[i];
      end;
    end;
  end
  else
  begin
    lvLeft.Items.Count := FDiffRows.Count;
    lvRight.Items.Count := FDiffRows.Count;
  end;

  if FDiffSyncLastTopL < 0 then FDiffSyncLastTopL := 0;
  FDiffSyncLastTopR := FDiffSyncLastTopL;
  FDiffScrollLastSource := 1;
  FHistoryLoaded := True;
  if not FClosing and chkSyncScroll.Checked then
    DiffApplyTopIndexToPeer(lvLeft);
  tmrSync.Enabled := not FClosing and chkSyncScroll.Checked;
end;

procedure TfrmCompareMerge.btnCopyLeftClick(Sender: TObject);
var
  It, Next: TListItem;
  SL: TStringList;
  n, lim: Integer;
begin
  if lvLeft.SelCount = 0 then
  begin
    MessageDlg(TrText('Nothing selected.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  SL := TStringList.Create;
  try
    lim := Max(1, lvLeft.Items.Count);
    n := 0;
    It := lvLeft.Selected;
    while It <> nil do
    begin
      Inc(n);
      if n > lim then Break;
      if (It.Index >= 0) and (It.Index < FDiffRows.Count) then
      begin
        if PFFDiffRow(FDiffRows[It.Index])^.LNum > 0 then
          SL.Add(IntToStr(PFFDiffRow(FDiffRows[It.Index])^.LNum) + #9 + PFFDiffRow(FDiffRows[It.Index])^.LText)
        else
          SL.Add(PFFDiffRow(FDiffRows[It.Index])^.LText);
      end;
      Next := lvLeft.GetNextItem(It, sdAll, [isSelected]);
      if Next = It then Break;
      It := Next;
    end;
    if SL.Count > 0 then Clipboard.AsText := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure TfrmCompareMerge.btnCopyRightClick(Sender: TObject);
var
  It, Next: TListItem;
  SL: TStringList;
  n, lim: Integer;
begin
  if lvRight.SelCount = 0 then
  begin
    MessageDlg(TrText('Nothing selected.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  SL := TStringList.Create;
  try
    lim := Max(1, lvRight.Items.Count);
    n := 0;
    It := lvRight.Selected;
    while It <> nil do
    begin
      Inc(n);
      if n > lim then Break;
      if (It.Index >= 0) and (It.Index < FDiffRows.Count) then
      begin
        if PFFDiffRow(FDiffRows[It.Index])^.RNum > 0 then
          SL.Add(IntToStr(PFFDiffRow(FDiffRows[It.Index])^.RNum) + #9 + PFFDiffRow(FDiffRows[It.Index])^.RText)
        else
          SL.Add(PFFDiffRow(FDiffRows[It.Index])^.RText);
      end;
      Next := lvRight.GetNextItem(It, sdAll, [isSelected]);
      if Next = It then Break;
      It := Next;
    end;
    if SL.Count > 0 then Clipboard.AsText := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure TfrmCompareMerge.btnApplyLeftToRightClick(Sender: TObject);
begin
  ApplyMergeUseLeftOnRight;
end;

procedure TfrmCompareMerge.btnApplyRightToLeftClick(Sender: TObject);
begin
  ApplyMergeUseRightOnLeft;
end;

procedure TfrmCompareMerge.ApplyMergeUseLeftOnRight;
begin
  ApplyMergeDir(True);
end;

procedure TfrmCompareMerge.ApplyMergeUseRightOnLeft;
begin
  ApplyMergeDir(False);
end;

procedure TfrmCompareMerge.SetDiffBusyUi(ABusy: Boolean);
begin
  btnApplyLeftToRight.Enabled := not ABusy;
  btnApplyRightToLeft.Enabled := not ABusy;
  btnRunDiff.Enabled := not ABusy;
  mnuLApplyToRight.Enabled := not ABusy;
  mnuLApplyToLeft.Enabled := not ABusy;
  mnuRApplyToRight.Enabled := not ABusy;
  mnuRApplyToLeft.Enabled := not ABusy;
end;

function TfrmCompareMerge.PatchDiffAfterMerge: Boolean;
{ Reflete o merge ja' gravado nas linhas do diff em memoria, sem reler nem recomparar
  os ficheiros: O(linhas do diff). As linhas do destino sao renumeradas pela ordem. }
var
  Act: TArray<Byte>;
  NewRows: TList;
  Rr: PFFDiffRow;
  i, k, OldSel, NewSel, Top: Integer;
  c: Int64;
  ByLines, hasDiff: Boolean;
  TgtKind: TFFDiffKind;
begin
  Result := False;
  if not Assigned(FDiffRows) or (Length(FMergeOps) = 0) then Exit;
  SetLength(Act, FDiffRows.Count);
  for k := 0 to High(FMergeOps) do
  begin
    i := FMergeOps[k].Seq;
    if (i < 0) or (i >= FDiffRows.Count) then Exit;
    case FMergeOps[k].Kind of
      makDelete: Act[i] := 2;
    else
      Act[i] := 1;
    end;
  end;
  if FMergeL2R then TgtKind := ffdkInsert else TgtKind := ffdkDelete;

  c := 0;
  for i := 0 to FDiffRows.Count - 1 do
  begin
    Rr := PFFDiffRow(FDiffRows[i]);
    if FMergeL2R then c := Rr^.RNum else c := Rr^.LNum;
    if c > 0 then Break;
  end;
  if c <= 0 then c := 1;

  OldSel := FDiffRestoreSel;
  NewSel := -1;
  NewRows := TList.Create;
  NewRows.Capacity := FDiffRows.Count;
  for i := 0 to FDiffRows.Count - 1 do
  begin
    Rr := PFFDiffRow(FDiffRows[i]);
    if Act[i] = 2 then
    begin
      Dispose(Rr);
      Continue;
    end;
    if i = OldSel then NewSel := NewRows.Count;
    if Act[i] = 1 then
    begin
      if FMergeL2R then Rr^.RText := Rr^.LText else Rr^.LText := Rr^.RText;
      Rr^.Kind := ffdkEqual;
    end;
    if (Rr^.Kind = ffdkEqual) or (Rr^.Kind = ffdkChange) or (Rr^.Kind = TgtKind) then
    begin
      if FMergeL2R then Rr^.RNum := c else Rr^.LNum := c;
      Inc(c);
    end;
    NewRows.Add(Rr);
  end;
  if (NewSel < 0) and (NewRows.Count > 0) and (OldSel >= 0) then
    NewSel := Min(OldSel, NewRows.Count - 1);
  FDiffRows.Free;
  FDiffRows := NewRows;
  SetLength(FMergeOps, 0);

  Top := FDiffRestoreTop;
  ByLines := not lvLeft.OwnerData;
  lvLeft.Items.BeginUpdate;
  lvRight.Items.BeginUpdate;
  try
    if ByLines then
    begin
      lvLeft.Items.Clear;
      lvRight.Items.Clear;
      for i := 0 to FDiffRows.Count - 1 do
      begin
        Rr := PFFDiffRow(FDiffRows[i]);
        with lvLeft.Items.Add do
        begin
          if Rr^.LNum > 0 then Caption := IntToStr(Rr^.LNum) else Caption := '';
          SubItems.Add(Rr^.LText);
          Data := Rr;
        end;
        with lvRight.Items.Add do
        begin
          if Rr^.RNum > 0 then Caption := IntToStr(Rr^.RNum) else Caption := '';
          SubItems.Add(Rr^.RText);
          Data := Rr;
        end;
      end;
    end
    else
    begin
      lvLeft.Items.Count := FDiffRows.Count;
      lvRight.Items.Count := FDiffRows.Count;
    end;
  finally
    lvRight.Items.EndUpdate;
    lvLeft.Items.EndUpdate;
  end;
  if not ByLines then
  begin
    lvLeft.Invalidate;
    lvRight.Invalidate;
  end;
  if Assigned(FDiffRestoreLv) and (NewSel >= 0) and (NewSel < FDiffRestoreLv.Items.Count) then
  begin
    FDiffRestoreLv.ClearSelection;
    FDiffRestoreLv.Items[NewSel].Selected := True;
    FDiffRestoreLv.Items[NewSel].Focused := True;
  end;
  if Top >= 0 then
  begin
    Top := Min(Top, Max(0, FDiffRows.Count - 1));
    FFListViewSetExactTopIndex(lvLeft, Top);
    FFListViewSetExactTopIndex(lvRight, Top);
    FDiffSyncLastTopL := Top;
    FDiffSyncLastTopR := Top;
  end;
  FDiffRestoreTop := -1;
  FDiffRestoreLv := nil;
  Result := True;

  hasDiff := False;
  for i := 0 to FDiffRows.Count - 1 do
    if PFFDiffRow(FDiffRows[i])^.Kind <> ffdkEqual then
    begin
      hasDiff := True;
      Break;
    end;
  if not hasDiff then
    MessageDlg(TrText('There is no difference between the files.'), mtInformation, [mbOK], 0)
  else
    MessageDlg(TrText('Merge apply finished OK.'), mtInformation, [mbOK], 0);
end;

procedure TfrmCompareMerge.ApplyMergeDir(ALeftToRight: Boolean);
var
  SrcPath, TgtPath: string;
  Lo, SrcN, TgtN, Anchor: Int64;
  lv: TListView;
  It: TListItem;
  Rr: PFFDiffRow;
  Ops: TArray<TMaOp>;
  NextNum, PrevNum: TArray<Int64>;
  nOps, i: Integer;
  SrcOnly, TgtOnly: TFFDiffKind;

  function TgtNumAt(AIdx: Integer): Int64;
  begin
    if ALeftToRight then
      Result := PFFDiffRow(FDiffRows[AIdx])^.RNum
    else
      Result := PFFDiffRow(FDiffRows[AIdx])^.LNum;
  end;

  { Ancora de insercao: proxima linha do destino no diff (ou a seguinte a' anterior), O(n) uma vez. }
  procedure BuildAnchors;
  var
    k, cnt: Integer;
    v: Int64;
  begin
    if Length(NextNum) > 0 then Exit;
    cnt := FDiffRows.Count;
    SetLength(NextNum, cnt + 1);
    SetLength(PrevNum, cnt + 1);
    v := 0;
    for k := cnt - 1 downto 0 do
    begin
      if TgtNumAt(k) > 0 then v := TgtNumAt(k);
      NextNum[k] := v;
    end;
    v := 0;
    for k := 0 to cnt - 1 do
    begin
      PrevNum[k] := v;
      if TgtNumAt(k) > 0 then v := TgtNumAt(k);
    end;
  end;

  procedure AddOp(AKind: TMaKind; ATgt, ASrc: Int64; ASeq: Integer);
  begin
    if nOps >= Length(Ops) then
      SetLength(Ops, Max(256, Length(Ops) * 2));
    Ops[nOps].Kind := AKind;
    Ops[nOps].TgtLine := ATgt;
    Ops[nOps].SrcLine := ASrc;
    Ops[nOps].Seq := ASeq;
    Inc(nOps);
  end;

begin
  if FClosing or Assigned(FMergeThread) or Assigned(FDiffWorkerThread) then Exit;
  if not Assigned(FDiffRows) or (FDiffRows.Count = 0) then
  begin
    MessageDlg(TrText('Nothing selected.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  Lo := Max(Int64(1), FDiffLo);
  if ALeftToRight then
  begin
    SrcPath := Trim(edtLeftFile.Text);
    TgtPath := Trim(edtRightFile.Text);
    SrcOnly := ffdkDelete;
    TgtOnly := ffdkInsert;
  end
  else
  begin
    SrcPath := Trim(edtRightFile.Text);
    TgtPath := Trim(edtLeftFile.Text);
    SrcOnly := ffdkInsert;
    TgtOnly := ffdkDelete;
  end;
  if (SrcPath = '') or not FileExists(SrcPath) or (TgtPath = '') or not FileExists(TgtPath) then
  begin
    if ALeftToRight = ((TgtPath = '') or not FileExists(TgtPath)) then
      MessageDlg(TrText('Please choose an existing right file.'), mtInformation, [mbOK], 0)
    else
      MessageDlg(TrText('Please choose an existing left file.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  if lvLeft.SelCount > 0 then
    lv := lvLeft
  else if lvRight.SelCount > 0 then
    lv := lvRight
  else
  begin
    MessageDlg(TrText('Nothing selected.'), mtInformation, [mbOK], 0);
    Exit;
  end;

  nOps := 0;
  It := lv.Selected;
  while It <> nil do
  begin
    i := It.Index;
    if (i >= 0) and (i < FDiffRows.Count) then
    begin
      Rr := PFFDiffRow(FDiffRows[i]);
      if ALeftToRight then
      begin
        SrcN := Rr^.LNum;
        TgtN := Rr^.RNum;
      end
      else
      begin
        SrcN := Rr^.RNum;
        TgtN := Rr^.LNum;
      end;
      if Rr^.Kind = TgtOnly then
      begin
        if TgtN > 0 then
          AddOp(makDelete, TgtN + Lo - 1, 0, i);
      end
      else if Rr^.Kind = ffdkChange then
      begin
        if (TgtN > 0) and (SrcN > 0) then
          AddOp(makEdit, TgtN + Lo - 1, SrcN + Lo - 1, i);
      end
      else if Rr^.Kind = SrcOnly then
      begin
        if SrcN > 0 then
        begin
          BuildAnchors;
          Anchor := NextNum[i];
          if Anchor <= 0 then
            Anchor := PrevNum[i] + 1;
          AddOp(makInsert, Anchor + Lo - 1, SrcN + Lo - 1, i);
        end;
      end;
    end;
    It := lv.GetNextItem(It, sdAll, [isSelected]);
  end;
  SetLength(Ops, nOps);
  if nOps = 0 then
  begin
    MessageDlg(TrText('No mergeable diff rows selected.'), mtInformation, [mbOK], 0);
    Exit;
  end;

  if ALeftToRight then
  begin
    if FastFileMessageBox(
      PChar(Format(TrText('Apply %d change(s) to the right file on disk?'), [nOps])),
      PChar(TrText('Confirm')), MB_YESNO or MB_ICONQUESTION) <> IDYES then
      Exit;
  end
  else if FastFileMessageBox(
    PChar(Format(TrText('Apply %d change(s) to the left file on disk?'), [nOps])),
    PChar(TrText('Confirm')), MB_YESNO or MB_ICONQUESTION) <> IDYES then
    Exit;
  if FClosing or Assigned(FMergeThread) or (FChgWnd = 0) then Exit;

  FMergeTarget := TgtPath;
  FMergeOps := Copy(Ops);
  FMergeL2R := ALeftToRight;
  FMergeLv := lv;
  FDiffRestoreLv := lv;
  FDiffRestoreTop := Max(0, Integer(SendMessage(lv.Handle, LVM_GETTOPINDEX, 0, 0)));
  if Assigned(lv.Selected) then
    FDiffRestoreSel := lv.Selected.Index
  else
    FDiffRestoreSel := -1;
  FMergeMainHooked := False;
  TfrmSmoothLoading.ResetCancel;
  TfrmSmoothLoading.ShowLoading(Self, TrText('Applying merge...'));
  SetDiffBusyUi(True);
  { Origem sem codificacao: copia de bytes crus (sem risco de dupla conversao). }
  FMergeThread := TMergeApplyThread.Create(SrcPath, TgtPath, EnsureFastFileTempSubDir('merge'),
    '', DetectTextFileEncoding(TgtPath),
    Byte(LineTermCharForFile(SrcPath)), Byte(LineTermCharForFile(TgtPath)),
    RawByteString(OutputEolForFile(TgtPath)), Ops, FChgWnd, WM_FF_MERGE_APPLY);
  FMergeThread.CancelPoll :=
    function: Boolean
    begin
      Result := TfrmSmoothLoading.CancelRequested;
    end;
  FMergeThread.Start;
end;

procedure TfrmCompareMerge.WMMergeApply(var Msg: TMessage);

  function Mb(const V: Int64): string;
  begin
    Result := FormatFloat('#,##0.0', V / (1024 * 1024)) + ' MB';
  end;

var
  T: TMergeApplyThread;
  Parts: TArray<string>;
  Tgt, Txt: string;
  Ico: UINT;
begin
  Msg.Result := 0;
  if not Assigned(FMergeThread) then Exit;
  if Msg.WParam = cMaMsgRelease then
  begin
    if (Msg.LParam = LPARAM(FMergeThread)) and Assigned(GFFCompareMergeFileHook) then
    begin
      GFFCompareMergeFileHook(FMergeTarget, cFFMergeHookRelease);
      FMergeMainHooked := True;
    end;
    Msg.Result := 1;
    Exit;
  end;
  if Msg.WParam = cMaMsgProgress then
  begin
    if TfrmSmoothLoading.CancelRequested then
      FMergeThread.Terminate;
    if FMergeThread.BytesTotal > 0 then
      TfrmSmoothLoading.UpdateProgressWithDetail(Integer(Msg.LParam) div 10,
        Mb(FMergeThread.BytesDone) + ' / ' + Mb(FMergeThread.BytesTotal))
    else
      TfrmSmoothLoading.UpdateProgress(Integer(Msg.LParam) div 10);
    Exit;
  end;
  if Msg.LParam <> LPARAM(FMergeThread) then Exit;
  T := FMergeThread;
  FMergeThread := nil;
  T.WaitFor;
  try
    TfrmSmoothLoading.HideLoading;
    TfrmSmoothLoading.ResetCancel;
    SetDiffBusyUi(False);
    Tgt := FMergeTarget;
    NotifyMainAfterMerge(T);
    if FClosing then Exit;
    if T.Succeeded and (T.AppliedCount > 0) then
    begin
      NoteMergeWroteDisk(Tgt);
      TouchHistoryIfSameFile(Tgt);
      if T.MissingLines > 0 then
        FastFileMessageBox(PChar(Format(TrText('Merge.LinesMissing: %d'), [T.MissingLines])),
          PChar(Caption), MB_OK or MB_ICONWARNING);
      if (T.MissingLines = 0) and PatchDiffAfterMerge then
        Exit;
      FDiffMergeOkMsg := True;
      btnRunDiffClick(nil);
      Exit;
    end;
    FDiffRestoreTop := -1;
    FDiffRestoreLv := nil;
    Ico := MB_ICONWARNING;
    if T.Cancelled then
    begin
      Txt := TrText('Merge.Cancelled');
      Ico := MB_ICONINFORMATION;
    end
    else if T.ErrorMsg = '*changed*' then
      Txt := TrText('Merge.FileChanged')
    else if Copy(T.ErrorMsg, 1, 8) = '*space*|' then
    begin
      Parts := T.ErrorMsg.Split(['|']);
      Txt := Format(TrText('Merge.NoDiskSpace: %s %s'),
        [Mb(StrToInt64Def(Parts[1], 0)), Mb(StrToInt64Def(Parts[2], 0))]);
    end
    else if T.ErrorMsg <> '' then
      Txt := Format(TrText('Merge.WriteFailed: %s'), [T.ErrorMsg])
    else if T.MissingLines > 0 then
      Txt := Format(TrText('Merge.LinesMissing: %d'), [T.MissingLines])
    else
      Txt := TrText('No mergeable diff rows selected.');
    FastFileMessageBox(PChar(Txt), PChar(Caption), MB_OK or Ico);
  finally
    T.Free;
  end;
end;

procedure TfrmCompareMerge.StopMergeThread;
begin
  if not Assigned(FMergeThread) then Exit;
  FMergeThread.Terminate;
  { WaitFor na thread principal atende o SendMessage(cMaMsgRelease): sem deadlock. }
  FMergeThread.WaitFor;
  NotifyMainAfterMerge(FMergeThread);
  FreeAndNil(FMergeThread);
  TfrmSmoothLoading.HideLoading;
  TfrmSmoothLoading.ResetCancel;
end;

procedure TfrmCompareMerge.NotifyMainAfterMerge(T: TMergeApplyThread);
var
  Stage: Integer;
begin
  Stage := -1;
  if T.Succeeded and (T.AppliedCount > 0) then
  begin
    if T.SameLayout and not FMergeMainHooked then
      Stage := cFFMergeHookRepaint
    else
      Stage := cFFMergeHookReload;
  end
  else if FMergeMainHooked then
    Stage := cFFMergeHookReload;
  FMergeMainHooked := False;
  if (Stage >= 0) and Assigned(GFFCompareMergeFileHook) then
    GFFCompareMergeFileHook(FMergeTarget, Stage);
end;

procedure TfrmCompareMerge.btnCloseClick(Sender: TObject);
begin
  if FEmbeddedMode then
  begin
    Hide;
    Exit;
  end;
  if FClosing or FClosePosted then Exit;
  FClosePosted := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmCompareMerge.chkDiffByLinesClick(Sender: TObject);
begin
  edtFirstLine.Enabled := chkDiffByLines.Checked;
  edtLastLine.Enabled := chkDiffByLines.Checked;
end;

procedure TfrmCompareMerge.chkSyncScrollClick(Sender: TObject);
begin
  if chkSyncScroll.Checked and (lvLeft.Items.Count > 0) then
    DiffApplyTopIndexToPeer(lvLeft);
  tmrSync.Enabled := chkSyncScroll.Checked;
end;

procedure TfrmCompareMerge.tmrSyncTimer(Sender: TObject);
var
  nL, nR: Integer;
  Src: TListView;
begin
  if FClosing or not chkSyncScroll.Checked then Exit;
  if FDiffThumbScroll or FSyncingDiffScroll then Exit;
  if Assigned(PageControl1) and (PageControl1.ActivePage <> TabSheetDiff) then Exit;
  if not lvLeft.HandleAllocated or not lvRight.HandleAllocated then Exit;
  if (lvLeft.Items.Count = 0) or (lvRight.Items.Count = 0) then Exit;
  nL := Integer(SendMessage(lvLeft.Handle, LVM_GETTOPINDEX, 0, 0));
  nR := Integer(SendMessage(lvRight.Handle, LVM_GETTOPINDEX, 0, 0));
  if nL < 0 then nL := 0;
  if nR < 0 then nR := 0;
  { Nada rolou desde o ultimo alinhamento (inclui o par que nao alcanca a mesma
    linha por ser mais curto): nao reaplicar a cada tick. }
  if (nL = FDiffSyncLastTopL) and (nR = FDiffSyncLastTopR) then Exit;
  if nL = nR then
  begin
    FDiffSyncLastTopL := nL;
    FDiffSyncLastTopR := nR;
    Exit;
  end;
  { Barra de rolagem, teclado ou roda: segue a lista que se moveu. }
  if (nR <> FDiffSyncLastTopR) and (nL = FDiffSyncLastTopL) then
    Src := lvRight
  else
    Src := lvLeft;
  if Src = lvRight then
    FDiffScrollLastSource := 2
  else
    FDiffScrollLastSource := 1;
  DiffApplyTopIndexToPeer(Src);
  FDiffSyncLastTopL := Max(0, Integer(SendMessage(lvLeft.Handle, LVM_GETTOPINDEX, 0, 0)));
  FDiffSyncLastTopR := Max(0, Integer(SendMessage(lvRight.Handle, LVM_GETTOPINDEX, 0, 0)));
end;

class function TfrmCompareMerge.ExecuteModal(AOwner: TComponent; const ADefaultLeftPath,
  AMainOpenPath: string): Boolean;
var
  F: TfrmCompareMerge;
begin
  Result := False;
  F := TfrmCompareMerge.Create(AOwner);
  try
    F.FMainOpenPath := Trim(AMainOpenPath);
    F.FNeedMainReload := False;
    F.FDefaultLeft := ADefaultLeftPath;
    if Trim(ADefaultLeftPath) <> '' then
    begin
      F.edtLeftFile.Text := ADefaultLeftPath;
      F.edtRightFile.Text := '';
    end;
    F.ShowModal;
    Result := F.FNeedMainReload;
  finally
    F.Free;
  end;
end;

procedure TfrmCompareMerge.ResetContext(const ADefaultLeftPath, AMainOpenPath: string);
begin
  FClosing := False;
  FClosePosted := False;
  FJournalPreviewHiliteIdx := -1;
  ClearHistJournalOverlay;
  FMainOpenPath := Trim(AMainOpenPath);
  FNeedMainReload := False;
  FDefaultLeft := Trim(ADefaultLeftPath);
  if FDefaultLeft <> '' then
  begin
    edtLeftFile.Text := FDefaultLeft;
    edtRightFile.Text := '';
  end;

  if HandleAllocated and Visible and (not FClosing) then
  begin
    KillTimer(Handle, cDeferHistTimerId);
    SetTimer(Handle, cDeferHistTimerId, cDeferHistTimerMs, nil);
  end;
end;

class function TfrmCompareMerge.ExecuteEmbedded(AOwner: TComponent; AHost: TWinControl;
  const ADefaultLeftPath, AMainOpenPath: string): TfrmCompareMerge;
begin
  Result := TfrmCompareMerge.Create(AOwner);
  Result.FEmbeddedMode := True;
  Result.ResetContext(ADefaultLeftPath, AMainOpenPath);

  if Assigned(AHost) then
  begin
    Result.BorderStyle := bsNone;
    Result.Parent := AHost;
    Result.Align := alClient;
    Result.KeyPreview := True;
    Result.Visible := True;
    Result.BringToFront;
  end
  else
    Result.Show;
end;

end.
