unit uFastFileAssistant;

{
  FastFile operational assistant: docked right panel (no modal), operational KB only.
}

interface

uses
  Classes, Messages, Controls, Windows, ImgList, uI18n;

procedure CreateFastFileAssistantUI(AOwner: TComponent; AHostPanel: TWinControl);
procedure ShowFastFileAssistantPanel;
procedure HideFastFileAssistantPanel;
procedure ToggleFastFileAssistantPanel;
function FastFileAssistantPanelVisible: Boolean;
function FastFileAssistantFocusInPanel(const AFocusHwnd: HWND): Boolean;
function FastFileAssistantHandleShortcut(var Key: Word; Shift: TShiftState): Boolean;
{ Enter no campo da pergunta dispara Enviar; Shift+Enter insere nova linha. }
function FastFileAssistantHandleEnter(var Key: Word; Shift: TShiftState): Boolean;
procedure NotifyAssistantGeneratedFile(const AFileName: string);
procedure NotifyAssistantDelegatedReply(const AText: string; AAppend: Boolean);
procedure NotifyAssistantDelegatedStatus(const AStatus: string);
{ Prefill the question box and focus the assistant (e.g. Ask AI about selected lines). }
procedure AssistantPrefillQuestion(const AText: string);
procedure AssistantSubmitQuestion;
{ Post-action offer: summary + "What do you want to do next?" + action chips.
  Optional AAiDraft is kept as a clickable suggestion (not typed into the question box). }
procedure NotifyAssistantOfferNext(const ASummary, AActionIdsCsv: string); overload;
procedure NotifyAssistantOfferNext(const ASummary, AActionIdsCsv,
  AAiDraft: string); overload;
procedure AssistantComposeSavedDocumentFromText(const AQuestion, ABody: string);
function NormalizeAssistantFilterNeedle(const AUserQ, ARawPattern: string): string;

function ShouldShowAssistantOnStartup(const AIniPath: string): Boolean;
procedure SaveAssistantShowOnStartup(const AIniPath: string; AShow: Boolean);
procedure RefreshFastFileAssistantSurface;
{ After a runtime language switch: re-translate composed texts (offer summary,
  AI draft suggestion, reply placeholder, status) that ApplyAssistantUiTexts
  does not rebuild. Call before RefreshFastFileAssistantSurface. }
procedure RetranslateFastFileAssistant(OldLang: TAppLanguage);
procedure SetFastFileAssistantMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
procedure SetFastFileAssistantOnFloat(AHandler: TNotifyEvent);
procedure SetFastFileAssistantOnTearOff(AHandler: TNotifyEvent);
procedure SetFastFileAssistantOnPython(AHandler: TNotifyEvent);
procedure SetFastFileAssistantFloatingState(AFloating: Boolean);
procedure RelayoutFastFileAssistantAfterDock;
procedure PersistAssistantLayout;
function AssistantLangMenuCaption(ALang: TAppLanguage): string;
function BuildAssistantTranslatePromptW(const AText, ALangName: string;
  AKeepLineCount: Boolean = False): WideString;

implementation

uses
  SysUtils, Types, Math, Forms, Dialogs, StdCtrls, ExtCtrls, Graphics, Menus, Clipbrd, Buttons,
  acntUtils, sPanel, sSpeedButton, sSplitter, IniFiles, UnConsts, uPosBMH, uFastFileAIClient,
  uFastFileAssistantHost, uFastFileAssistantRAG, uFastFileAssistantCatalog, uFastFileAssistantMap,
  uFastFileAssistantIntent,   uFastFilePaths, uFastFileComposeExport, ShellAPI, uMruFind,
  UnitPopupMruList, uSmoothLoading, uFastFileNotice, uFastFileMsgDlg, uFastFileFloatHost,
  uFastFileScale, uAssistantPipelineStore, uAssistantPostAction, uUserPrefs, uExportDoneDlg,
  uAgentBridge;

type
  { Plain TMemo + ssVertical always paints a track. Strip WS_VSCROLL so empty
    Resposta/pergunta never show a dead scrollbar; keyboard/wheel still scroll. }
  TAssistantMemo = class(TMemo)
  private
    FAllowVertScroll: Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    procedure ForceHideVertScrollBar;
    procedure SyncVertScrollBar(AShow: Boolean);
    property AllowVertScroll: Boolean read FAllowVertScroll write FAllowVertScroll;
  end;

  { Soft vertical gradient header — tones derived from system colors. }
  TAssistantHeaderPanel = class(TsPanel)
  private
    FGradTop: TColor;
    FGradBot: TColor;
  protected
    procedure PaintWindow(DC: HDC); override;
  public
    property GradTop: TColor read FGradTop write FGradTop;
    property GradBot: TColor read FGradBot write FGradBot;
  end;

const
  WM_FF_ASSISTANT_RESET_BUSY = WM_USER + 429;
  WM_FF_ASSISTANT_DEFER_FOCUS = WM_USER + 431;
  WM_FF_IDLE_LOGO_LAYOUT = WM_USER + 433;
  WM_FF_ASSISTANT_RECENT_EXPAND = WM_USER + 435;
  WM_FF_ASSISTANT_RECENT_COLLAPSE = WM_USER + 437;
  WM_FF_ASSISTANT_RECENT_FIND = WM_USER + 438;
  WM_FF_ASSISTANT_RECENT_POPUP = WM_USER + 439;
  ASSISTANT_INI_KEY = 'AssistantShowOnStartup';
  ASSISTANT_RECENT_INI_SECTION = 'AssistantRecentQuestions';
  { Assistant recent max: PrefAssistantRecentMax (default 20). }
  ASSISTANT_RECENT_VISIBLE = 10;
  ASSISTANT_RECENT_DISPLAY_MAX = 72;
  ASSISTANT_PANEL_WIDTH = 400;
  { Layout + FastFile chrome sampled from main UI (toolbars + idle workspace).
    Delphi BGR: sel1 toolbar light, sel2 toolbar mid, sel3 IDLE_WORKSPACE_*. }
  ASSISTANT_PAD = 14;
  ASSISTANT_TOOLBAR_LIGHT = TColor($00FEFCFB); { ~#FBFCFE — top toolbar }
  ASSISTANT_TOOLBAR_MID = TColor($00EFEAE7);   { ~#E7EAEF — mid toolbar }
  ASSISTANT_TOOLBAR_EDGE = TColor($00DED7D4);  { ~#D4D7DE — toolbar shade }
  ASSISTANT_BADGE_BG = TColor($00FFF4E8);     { ~#E8F4FF — recent-files header / sel.1 }
  ASSISTANT_ACCENT_W = 0; { full-height left strip looked like a scrollbar track }
  ASSISTANT_CAP_ACCENT_W = 3;
  ASSISTANT_HEADER_H = 36;
  ASSISTANT_HIDE_BTN_W = 28;
  ASSISTANT_SHORTCUT_BADGE_W = 88;
  ASSISTANT_CHK_GLYPH_W = 18;
  ASSISTANT_CHAR_COUNT_H = 20;
  ASSISTANT_INPUT_MIN_H = 300;
  ASSISTANT_INPUT_DEFAULT_H = 340;
  ASSISTANT_INPUT_SPLIT_H = 6;
  ASSISTANT_QUESTION_FRAME_H = 148;
  ASSISTANT_DRAFT_HINT_H = 56;
  ASSISTANT_TOOLS_BAR_H = 40;
  ASSISTANT_TOOLS_BAR_H2 = 70;
  ASSISTANT_QUESTION_SHELL_H = ASSISTANT_QUESTION_FRAME_H + ASSISTANT_TOOLS_BAR_H;
  ASSISTANT_CLEAR_BTN_W = 26;
  ASSISTANT_TOOL_BTN_H = 24;
  ASSISTANT_TOOL_BTN_PAD_Y = 6;
  ASSISTANT_TRANSLATE_BTN_W = 82;
  ASSISTANT_REWRITE_BTN_W = 74;
  ASSISTANT_AGENT_BTN_W = 70;
  { Offer chips that drive the AI agent's proposed edits (uAgentBridge), not catalog actions. }
  AGENT_CHIP_ACCEPT = 'agent_accept_all';
  AGENT_CHIP_REVIEW = 'agent_review';
  AGENT_CHIP_REJECT = 'agent_reject_all';
  AGENT_TASK_ACTION = 'agent_task';
  ASSISTANT_CLEAR_TOOL_BTN_W = 68;
  ASSISTANT_COPY_TOOL_BTN_W = 68;
  ASSISTANT_PYTHON_BTN_W = 72;
  ASSISTANT_HELP_TOOL_BTN_W = 26;
  ASSISTANT_QUESTION_MAX_CHARS = 500;
  ASSISTANT_FILE_NOTICE_H = 102;
  ASSISTANT_FILE_NOTICE_BG = TColor($00E8F5E9);
  ASSISTANT_FILE_NOTICE_EDGE = TColor($00B7DFB9);
  ASSISTANT_FILE_NOTICE_ACCENT = TColor($004CAF50);
  ATJ_TRANSLATE = 0;
  ATJ_REWRITE = 1;
  ASSISTANT_STATUS_OK = $002E7D32;
  { Memo reply limits — avoid OOM if the model dumps file/transform output in user_message. }
  ASSISTANT_MAX_REPLY_CHARS = 16384;
  ASSISTANT_MAX_REPLY_LINES = 120;
  ASSISTANT_MAX_RAW_FALLBACK_CHARS = 4096;
  COMPOSE_MAX_BYTES = 256 * 1024;
  COMPOSE_SAMPLE_MAX_BYTES = 12000;
  COMPOSE_SAMPLE_MAX_LINES = 40;

function IsAgentChipId(const AId: string): Boolean;
begin
  Result := SameText(AId, AGENT_CHIP_ACCEPT) or SameText(AId, AGENT_CHIP_REVIEW) or
    SameText(AId, AGENT_CHIP_REJECT);
end;

function AssistantBlendColor(C1, C2: TColor; APctTowardC2: Integer): TColor;
var
  R1, G1, B1, R2, G2, B2: Integer;
  RGB1, RGB2: COLORREF;
begin
  if APctTowardC2 <= 0 then
  begin
    Result := ColorToRGB(C1);
    Exit;
  end;
  if APctTowardC2 >= 100 then
  begin
    Result := ColorToRGB(C2);
    Exit;
  end;
  RGB1 := ColorToRGB(C1);
  RGB2 := ColorToRGB(C2);
  R1 := GetRValue(RGB1);
  G1 := GetGValue(RGB1);
  B1 := GetBValue(RGB1);
  R2 := GetRValue(RGB2);
  G2 := GetGValue(RGB2);
  B2 := GetBValue(RGB2);
  Result := RGB(
    R1 + ((R2 - R1) * APctTowardC2) div 100,
    G1 + ((G2 - G1) * APctTowardC2) div 100,
    B1 + ((B2 - B1) * APctTowardC2) div 100);
end;

procedure PaintAssistantSoftGradient(ACanvas: TCanvas; const R: TRect; C1, C2: TColor);
var
  V: array[0..1] of TTriVertex;
  GR: TGradientRect;

  procedure FillVertex(var Vert: TTriVertex; AX, AY: Integer; AColor: TColor);
  var
    RGB: COLORREF;
  begin
    RGB := ColorToRGB(AColor);
    Vert.X := AX;
    Vert.Y := AY;
    Vert.Red := GetRValue(RGB) shl 8;
    Vert.Green := GetGValue(RGB) shl 8;
    Vert.Blue := GetBValue(RGB) shl 8;
    Vert.Alpha := 0;
  end;

begin
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;
  FillVertex(V[0], R.Left, R.Top, C1);
  FillVertex(V[1], R.Right, R.Bottom, C2);
  GR.UpperLeft := 0;
  GR.LowerRight := 1;
  GradientFill(ACanvas.Handle, @V[0], 2, @GR, 1, GRADIENT_FILL_RECT_V);
end;

procedure TAssistantHeaderPanel.PaintWindow(DC: HDC);
var
  C: TCanvas;
  R: TRect;
  TopC, BotC: TColor;
begin
  TopC := FGradTop;
  BotC := FGradBot;
  if TopC = 0 then
    TopC := ColorToRGB(clBtnFace);
  if BotC = 0 then
    BotC := AssistantBlendColor(TopC, clBtnShadow, 18);
  C := TCanvas.Create;
  try
    C.Handle := DC;
    R := ClientRect;
    PaintAssistantSoftGradient(C, R, TopC, BotC);
  finally
    C.Handle := 0;
    C.Free;
  end;
end;

procedure TAssistantMemo.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style and not WS_HSCROLL;
  if not FAllowVertScroll then
    Params.Style := Params.Style and not WS_VSCROLL;
end;

procedure TAssistantMemo.ForceHideVertScrollBar;
var
  Style: Longint;
begin
  ScrollBars := ssNone;
  if not HandleAllocated then Exit;
  Style := GetWindowLong(Handle, GWL_STYLE);
  if (Style and WS_VSCROLL) <> 0 then
  begin
    SetWindowLong(Handle, GWL_STYLE, Style and not WS_VSCROLL);
    SetWindowPos(Handle, 0, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
  end;
  ShowScrollBar(Handle, SB_VERT, False);
end;

procedure TAssistantMemo.SyncVertScrollBar(AShow: Boolean);
var
  Style: Longint;
begin
  if not FAllowVertScroll then
  begin
    ForceHideVertScrollBar;
    Exit;
  end;
  if not HandleAllocated then Exit;
  Style := GetWindowLong(Handle, GWL_STYLE);
  if AShow then
  begin
    if (Style and WS_VSCROLL) = 0 then
    begin
      SetWindowLong(Handle, GWL_STYLE, Style or WS_VSCROLL);
      SetWindowPos(Handle, 0, 0, 0, 0, 0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
    end;
    ShowScrollBar(Handle, SB_VERT, True);
  end
  else if (Style and WS_VSCROLL) <> 0 then
    ForceHideVertScrollBar
  else
    ShowScrollBar(Handle, SB_VERT, False);
end;

procedure TAssistantMemo.CreateWnd;
begin
  inherited CreateWnd;
  if not FAllowVertScroll then
    ForceHideVertScrollBar;
end;

type
  TAssistantIntent = (aiExplain, aiExecute, aiUnknown);

  TAssistantPlan = record
    Intent: TAssistantIntent;
    ActionId: string;
    Path: string;
    Parts: Integer;
    TotalParts: Integer;
    PartFrom: Integer;
    PartTo: Integer;
    FilterText: string;
    ReplaceText: string;
    LineNo: Integer;
    MaxLines: Integer; { AI params.max_lines / limit — filtered lines to put in compose PDF }
    CaseSensitive: Boolean;
    ByteOffset: Int64;
    UserMessage: string;
    NeedConfirm: Boolean;
    { AI asked for a saved PDF/Word/…; keep that after redirect to count_line_prefixes. }
    ComposeAfterCount: Boolean;
    { Second hop after filter/split/find/merge — from AI chain or structural pdf/docx. }
    NativeFollowUpAction: string;
    { Extra local counts kept when a compound chain is flattened to hop-1. }
    AlsoCountMatching: string;
    AlsoCountPrefixes: string;
    ChainCount: Integer;
    Chain: array[0..ASSISTANT_MAX_CHAIN - 1] of TAssistantChainStep;
  end;

  TFastFileAssistantCtrl = class(TsPanel)
  private
    FHostPanel: TWinControl;
    PnlAccent: TsPanel;
    PnlHeader: TAssistantHeaderPanel;
    PnlHeaderSep: TsPanel;
    PnlShortcutBadgeShell: TsPanel;
    PnlShortcutBadge: TsPanel;
    LblTitle: TLabel;
    LblShortcut: TLabel;
    BtnHide: TButton;
    PnlInput: TsPanel;
    SplInputReply: TsSplitter;
    BtnFloat: TButton;
    FPopDock: TPopupMenu;
    FMiFloat: TMenuItem;
    FOnFloatClick: TNotifyEvent;
    FOnTearOff: TNotifyEvent;
    FOnPythonClick: TNotifyEvent;
    FFloating: Boolean;
    FHeaderDown: Boolean;
    FHeaderPt: TPoint;
    FGripInputBot: TFastFileEdgeGrip;
    LblPrompt: TLabel;
    MemoDraftHint: TMemo;
    BtnClearHint: TsSpeedButton;
    BtnCopyHint: TsSpeedButton;
    LblRecentQuestions: TLabel;
    PnlRecentCombo: TPanel;
    LblRecentCombo: TLabel;
    LblRecentComboArrow: TLabel;
    BtnRecentFind: TsSpeedButton;
    EdtRecentFind: TEdit;
    BtnRecentFindClear: TsSpeedButton;
    PnlQuestionShell: TsPanel;
    PnlQuestionFrame: TsPanel;
    PnlQuestionTools: TsPanel;
    PnlQuestionToolsSep: TsPanel;
    MemoQuestion: TMemo;
    BtnClearQuestion: TButton;
    BtnTranslate: TsSpeedButton;
    BtnRewrite: TsSpeedButton;
    { Down = send the question to the AI agent engine (reads the open file, proposes edits for review). }
    BtnAgentMode: TsSpeedButton;
    BtnClearReply: TsSpeedButton;
    BtnCopyReply: TsSpeedButton;
    BtnPython: TsSpeedButton;
    BtnComposeFormats: TsSpeedButton;
    LblQuestionCharCount: TLabel;
    PopupTranslateLang: TPopupMenu;
    BtnSend: TButton;
    BtnExecute: TButton;
    ChkDontShowAgain: TCheckBox;
    LblDontShowAgain: TLabel;
    LblStatus: TLabel;
    PnlReply: TsPanel;
    PnlReplyCapRow: TsPanel;
    PnlReplyCapAccent: TsPanel;
    LblReplyCaption: TLabel;
    PnlReplyStyleRow: TsPanel;
    LblReplyStyle: TLabel;
    CmbReplyStyle: TComboBox;
    BtnReplyStyleEdit: TsSpeedButton;
    PnlReplyShell: TsPanel;
    PnlReplySurface: TsPanel;
    MemoReply: TMemo;
    PnlFileNotice: TsPanel;
    PnlFileNoticeInner: TsPanel;
    PnlFileNoticeAccent: TsPanel;
    PnlFileNoticeContent: TsPanel;
    PnlFileNoticeHead: TsPanel;
    PnlFileNoticeActions: TsPanel;
    LblFileNoticeTitle: TLabel;
    LblFileNoticeFile: TLabel;
    LblFileNoticeDir: TLabel;
    LblFileNoticeHint: TLabel;
    BtnFileNoticeOpen: TsSpeedButton;
    BtnFileNoticeValidate: TsSpeedButton;
    BtnFileNoticeFolder: TsSpeedButton;
    BtnFileNoticeCopy: TsSpeedButton;
    BtnFileNoticeDismiss: TsSpeedButton;
    BtnFileNoticeDetails: TsSpeedButton;
    FGeneratedFilePath: string;
    FFileNoticeAutoHide: TFastFileNoticeAutoHide;
    PnlOfferNext: TsPanel;
    PnlOfferHead: TsPanel;
    LblOfferWhatNext: TLabel;
    LblOfferNext: TLabel;
    LblOfferMoreInfo: TLabel;
    BtnOfferDismiss: TsSpeedButton;
    PnlOfferActions: TsPanel;
    FOfferActionIds: TStringList;
    FOfferAiDraft: string;
    FOfferInfoPath: string;

    FPopupQuestion: TPopupMenu;
    FPopupReply: TPopupMenu;
    FBusy: Boolean;
    { An agent run started from this panel is in progress (FBusy stays True until it reports back). }
    FAgentRunning: Boolean;
    FPopupMenuOpen: Boolean;
    FRecentPopupPosted: Boolean;
    FWaitOverlayOwned: Boolean;
    FWaitAllowCreep: Boolean;
    FAiCancelled: Boolean;
    FCountProgLastTick: Cardinal;
    FCountProgLastPct: Integer;
    FTmrWaitCancel: TTimer;
    FTextJobReplaceSel: Boolean;
    FLastPlan: TAssistantPlan;
    FHasPlan: Boolean;
    FIniPath: string;
    FLayoutBuilt: Boolean;
    FLastReplyBody: string;
    FReplyStylePresetId: string;
    FReplyStyleCustom: string;
    FReplyStyleUserPresets: TStringList; { Name=Body reusable user templates }
    FStyleDlgMemo: TMemo;
    FStyleDlgCmb: TComboBox;
    FStyleDlgExIds: TStringList;
    FTickAiStart: Cardinal;
    FMsLastAi: Cardinal;
    FMsLastExec: Cardinal;
    FComposeAwaitingBody: Boolean;
    FComposeDestPath: string;
    FComposeIsFix: Boolean;
    FComposeSourceBody: string;
    FComposeAppendBody: string; { Host-complete filtered lines appended after AI summary. }
    FComposeAppendFiltered: Boolean; { Collect filter lines at write time (not before AI). }
    FComposeSummarizePhase: Boolean;
    FComposePipelineWord: Boolean;
    FLastAssistantMemo: TMemo;
    FRecentQuestions: TStringList;
    FSuppressRecentChange: Boolean;
    FRecentQuestionsExpanded: Boolean;
    FExpandingRecentMore: Boolean;
    FRecentFindActive: Boolean;
    FActivatingRecentFind: Boolean;
    FRecentFindNeedle: string;
    FFindImages: TCustomImageList;
    FFindImageIndex: Integer;
    FChromeSurf: TColor;
    FChromeCard: TColor;
    FChromeBorder: TColor;
    FChromeAccent: TColor;
    FChromeMuted: TColor;
    FChromeTitle: TColor;
    procedure BuildMemoPopupMenus;
    procedure AssistantMemoSelectAll(AMemo: TMemo);
    procedure AssistantMemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AssistantMemoEnter(Sender: TObject);
    procedure AssistantMemoExit(Sender: TObject);
    procedure UpdateQuestionFocusChrome(AFocused: Boolean);
    function CopyAssistantMemoToClipboard(AMemo: TMemo): Boolean;
    function HandleEnterKey(var Key: Word; Shift: TShiftState): Boolean;
    procedure AssistantMemoPopupSelectAll(Sender: TObject);
    procedure AssistantMemoPopupCopy(Sender: TObject);
    procedure AssistantMemoPopupCut(Sender: TObject);
    procedure AssistantMemoPopupPaste(Sender: TObject);
    procedure AssistantMemoPopupPasteFile(Sender: TObject);
    procedure AssistantMemoPopupUndoFile(Sender: TObject);
    procedure AssistantMemoPopupRedoFile(Sender: TObject);
    procedure AssistantInvokeFileUndo;
    procedure AssistantInvokeFileRedo;
    procedure AssistantInvokeAction(const AActionId: string);
    function AssistantFocusedMemo: TMemo;
    procedure AssistantMemoPopupPopup(Sender: TObject);
    function FormatAssistantElapsedMs(AMs: Cardinal): string;
    function BuildReplyWithTiming(const ABody: string; AIncludeExec: Boolean): string;
    procedure ApplyAssistantSoftChrome;
    procedure RefreshAssistantSurfaceColor;
    procedure BuildFormLayout;
    procedure LayoutInputControls(Sender: TObject);
    procedure SyncMemoAutoVertScroll(AMemo: TMemo);
    procedure SyncAssistantMemoScrollBars;
    procedure SetStatusCaption(const ACaption: string);
    procedure BeginAssistantWait(const AMsg: string);
    procedure UpdateAssistantWait(const AMsg: string);
    procedure ApplyAiNetProgress(APercent: Integer; const APhase: string);
    procedure EndAssistantWait;
    procedure BeginFileCountWait;
    procedure CountScanProgress(APercent: Integer; var ACancel: Boolean);
    function AssistantActionHasOwnSmoothLoading(const AActionId: string): Boolean;
    procedure TmrWaitCancelTimer(Sender: TObject);
    function ConsumerWaitCaption(const AActionId: string): string;
    procedure LblDontShowAgainClick(Sender: TObject);
    procedure BtnHideClick(Sender: TObject);
    procedure BtnFloatClick(Sender: TObject);
    procedure SyncFloatAction;
    procedure HeaderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HeaderMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HeaderMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HeaderDblClick(Sender: TObject);
    procedure ApplyHeaderDragChrome;
    procedure PlaceAssistantGrips;
    procedure AssistantGripResized(Sender: TObject);
    procedure RestoreDockedStack;
    procedure LoadAssistantInputHeight;
    procedure SaveAssistantInputHeight;
    procedure BtnSendClick(Sender: TObject);
    procedure BtnClearReplyClick(Sender: TObject);
    procedure BtnClearQuestionClick(Sender: TObject);
    procedure MemoQuestionChange(Sender: TObject);
    procedure MemoReplyChange(Sender: TObject);
    procedure ClearQuestionText;
    procedure UpdateClearQuestionBtn;
    procedure UpdateQuestionCharCount;
    procedure ClampQuestionToMaxChars;
    procedure SizeQuestionToolBtn(ABtn: TsSpeedButton; AMinW: Integer);
    procedure StyleQuestionToolBtn(ABtn: TsSpeedButton);
    procedure LayoutFileNoticeActions;
    procedure BuildTranslateLangMenu;
    procedure UpdateQuestionToolButtons;
    procedure BtnTranslateClick(Sender: TObject);
    procedure BtnRewriteClick(Sender: TObject);
    procedure BtnAgentModeClick(Sender: TObject);
    procedure LocalizeAgentModeBtn;
    function StartAgentTask(const AUserQ: string): Boolean;
    procedure AgentBridgeEvent(AEvent: TAgentBridgeEvent; const AText, AExtra: string; ACount: Integer);
    procedure ShowAgentProposals(ACount: Integer);
    procedure TranslateLangClick(Sender: TObject);
    procedure StartQuestionTextJob(AJob: Integer; const ALangName: string);
    procedure ApplyTextJobFinished(AJob: Integer; AOk: Boolean;
      const AAns: WideString; const AErr: string);
    function BuildTranslatePromptW(const AText, ALangName: string): WideString;
    function BuildRewritePromptW(const AText: string): WideString;
    procedure BtnCopyReplyClick(Sender: TObject);
    procedure BtnPythonClick(Sender: TObject);
    procedure BtnComposeFormatsClick(Sender: TObject);
    procedure ShowComposeFormatsDialog(const AUnsupportedExt: string);
    function RejectUnsupportedComposeFormat(const AQuestion: string): Boolean;
    procedure FillReplyStyleCombo;
    procedure LoadReplyStylePrefs;
    procedure SaveReplyStylePrefs;
    function CurrentReplyStyleInstructions: string;
    function ReplyStylePresetBody(const AId: string): string;
    procedure CmbReplyStyleChange(Sender: TObject);
    procedure BtnReplyStyleEditClick(Sender: TObject);
    procedure EditReplyStyleTemplate;
    procedure StyleDlgExampleChange(Sender: TObject);
    procedure StyleDlgSaveAsClick(Sender: TObject);
    procedure BtnExecuteClick(Sender: TObject);
    procedure WMResetBusy(var Msg: TMessage); message WM_FF_ASSISTANT_RESET_BUSY;
    procedure WMDeferFocus(var Msg: TMessage); message WM_FF_ASSISTANT_DEFER_FOCUS;
    procedure RequestInputFocus;
    procedure ApplyAiFinished(const Ok: Boolean; const Ans: WideString; const Err: string);
    function RunPlanWithOptionalConfirm(const Plan: TAssistantPlan; AAskConfirm: Boolean): string;
    function TryHandleLocalSendQuery: Boolean;
    function BuildPromptW: WideString;
    function BuildComposePromptW: WideString;
    function BuildComposeSummarizePromptW: WideString;
    function StartComposeGeneration: Boolean;
    procedure AbortComposeWrite(const AMsg: string);
    procedure EnsureComposeFilteredAppendBody;
    procedure ComposeSavedDocumentFromText(const AQuestion, ABody: string);
    procedure MaybeComposeDocAfterCountPrefixes(const AQuestion, AActionId, AExecMsg: string);
    procedure FinishComposeWithBody(const ABody: string);
    procedure FinishComposeSummaryThenWrite(const ASummary: string);
    procedure EnsureFileNoticeBanner;
    procedure LocalizeFileNoticeBanner;
    procedure ShowGeneratedFileNotice(const AFileName: string);
    procedure HideGeneratedFileNotice;
    procedure EnsureOfferNextBanner;
    procedure LocalizeOfferNextBanner;
    procedure LayoutOfferHeadRow;
    procedure OfferHeadResize(Sender: TObject);
    procedure ShowOfferNext(const ASummary, AActionIdsCsv: string;
      const AAiDraft: string = '');
    procedure HideOfferNext;
    procedure ClearOfferActionButtons;
    procedure LayoutOfferActionButtons;
    procedure OfferActionClick(Sender: TObject);
    procedure OfferDismissClick(Sender: TObject);
    procedure OfferQuestionHintClick(Sender: TObject);
    procedure BtnClearHintClick(Sender: TObject);
    procedure BtnCopyHintClick(Sender: TObject);
    procedure UpdateOfferQuestionHint;
    procedure OfferMoreInfoClick(Sender: TObject);
    procedure OfferWindowsPropsClick(Sender: TObject);
    procedure ShowOfferFileInfoDialog;
    function OfferActionCaption(const AActionId: string): string;
    procedure StyleFileNoticeHyperlink(ALbl: TLabel);
    procedure FileNoticeOpenClick(Sender: TObject);
    procedure FileNoticeFolderClick(Sender: TObject);
    procedure FileNoticeCopyClick(Sender: TObject);
    procedure FileNoticeDetailsClick(Sender: TObject);
    procedure FileNoticeValidateClick(Sender: TObject);
    function IsValidatableComposeSource(const APath: string): Boolean;
    function TryPickSourceToValidate(out APath: string): Boolean;
    function ResolveValidateSourcePath(const AUserQ: string; AAllowDialog: Boolean;
      out APath: string; out AMsg: string): Boolean;
    function FormatValidateSourceReport(const APath: string; AOk: Boolean;
      const AReport: string): string;
    function RunValidateSourcePath(const APath: string; AOpenInEditor: Boolean): string;
    function TryHandleValidateSourceChat: Boolean;
    procedure FileNoticeDismissClick(Sender: TObject);
    procedure FileNoticeAutoHideDone(Sender: TObject);
    function AssistantNormalizeShortcutKey(Key: Word): Word;
    function AssistantHandleShortcut(var Key: Word; Shift: TShiftState): Boolean;
    function FormatRecentQuestionDisplay(const AQuestion: string): string;
    function NormalizeRecentQuestionKey(const AQuestion: string): string;
    function EncodeRecentQuestionForIni(const AQuestion: string): string;
    function DecodeRecentQuestionFromIni(const AEncoded: string): string;
    procedure LoadRecentQuestions;
    procedure SaveRecentQuestions;
    procedure DeduplicateRecentQuestions;
    procedure RememberQuestion(const AQuestion: string);
    procedure RefreshRecentQuestionsCombo;
    procedure RecentComboClick(Sender: TObject);
    procedure OpenRecentQuestionsPopup;
    procedure AssistantMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure AssistantMruRemove(Sender: TObject; const AValue: string);
    procedure AssistantMruClearAll(Sender: TObject);
    procedure WMRecentQuestionsExpand(var Msg: TMessage); message WM_FF_ASSISTANT_RECENT_EXPAND;
    procedure WMRecentQuestionsCollapse(var Msg: TMessage); message WM_FF_ASSISTANT_RECENT_COLLAPSE;
    procedure WMRecentQuestionsFind(var Msg: TMessage); message WM_FF_ASSISTANT_RECENT_FIND;
    procedure WMRecentQuestionsPopup(var Msg: TMessage); message WM_FF_ASSISTANT_RECENT_POPUP;
    procedure BtnRecentFindClick(Sender: TObject);
    procedure EdtRecentFindChange(Sender: TObject);
    procedure EdtRecentFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnRecentFindClearClick(Sender: TObject);
    procedure ActivateRecentFind;
    procedure DeactivateRecentFind;
    procedure ApplyRecentFindGlyphs;
    procedure SetMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SyncDontShowStartupCheckbox;
    procedure PersistStartupPreference;
    procedure ApplyAssistantUiTexts;
    procedure RetranslateRuntimeTexts(OldLang: TAppLanguage);
    procedure ReceiveDelegatedReply(const AText: string; AAppend: Boolean);
    procedure ReceiveDelegatedStatus(const AStatus: string);
    function HandleShortcut(var Key: Word; Shift: TShiftState): Boolean;
  end;

  TFastFileAssistantThread = class(TThread)
  private
    FOwnerDlg: TFastFileAssistantCtrl;
    FPrompt: WideString;
    FAns: WideString;
    FErr: string;
    FOk: Boolean;
    FProgPct: Integer;
    FProgPhase: string;
    procedure UISync;
    procedure SyncProgress;
    procedure NotifyProgress(APercent: Integer; const APhase: string);
  protected
    procedure Execute; override;
  public
    constructor Create(ADlg: TFastFileAssistantCtrl; const PromptW: WideString);
  end;

  { 0=translate, 1=rewrite — keeps the question box, does not run a plan. }
  TFastFileAssistantTextJobThread = class(TThread)
  private
    FOwnerDlg: TFastFileAssistantCtrl;
    FPrompt: WideString;
    FAns: WideString;
    FErr: string;
    FOk: Boolean;
    FJob: Integer;
    FProgPct: Integer;
    FProgPhase: string;
    procedure UISync;
    procedure SyncProgress;
    procedure NotifyProgress(APercent: Integer; const APhase: string);
  protected
    procedure Execute; override;
  public
    constructor Create(ADlg: TFastFileAssistantCtrl; const PromptW: WideString;
      AJob: Integer);
  end;

var
  GAssistantCtrl: TFastFileAssistantCtrl;
  GAssistantHostPanel: TWinControl;
  GLastComposePath: string;

function WidePosBMH(const SubStr, Str: WideString): Integer;
var
  i, Ls, L: Integer;
begin
  Result := 0;
  Ls := Length(SubStr);
  L := Length(Str);
  if (Ls = 0) or (Ls > L) then Exit;
  for i := 1 to L - Ls + 1 do
    if Copy(Str, i, Ls) = SubStr then
    begin
      Result := i;
      Exit;
    end;
end;

function WideLower(const W: WideString): WideString;
var
  i: Integer;
  c: WideChar;
begin
  SetLength(Result, Length(W));
  for i := 1 to Length(W) do
  begin
    c := W[i];
    if (c >= 'A') and (c <= 'Z') then
      Result[i] := WideChar(Ord(c) + 32)
    else
      Result[i] := c;
  end;
end;

function ExtractComposeAnswerText(const ABody: string): string; forward;

function ExtractJsonStringFieldAnsi(const Json: string; const KeyName: string): string;
var
  Key, Tail: string;
  p, i, k, H, Code: Integer;
  InStr, Esc, OkU: Boolean;
  Ch: Char;

  function HexDigitVal(C: Char): Integer;
  begin
    case C of
      '0'..'9': Result := Ord(C) - Ord('0');
      'a'..'f': Result := 10 + Ord(C) - Ord('a');
      'A'..'F': Result := 10 + Ord(C) - Ord('A');
    else
      Result := -1;
    end;
  end;
begin
  Result := '';
  Key := '"' + KeyName + '"';
  p := PosBMH(Key, Json);
  if p = 0 then Exit;
  Tail := Copy(Json, p + Length(Key), MaxInt);
  i := 1;
  while (i <= Length(Tail)) and (Tail[i] in [#9, #10, #13, ' ']) do Inc(i);
  if (i > Length(Tail)) or (Tail[i] <> ':') then Exit;
  Inc(i);
  while (i <= Length(Tail)) and (Tail[i] in [#9, #10, #13, ' ']) do Inc(i);
  if (i > Length(Tail)) or (Tail[i] <> '"') then Exit;
  Inc(i);
  InStr := True;
  Esc := False;
  while InStr and (i <= Length(Tail)) do
  begin
    Ch := Tail[i];
    if Esc then
    begin
      case Ch of
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        't': Result := Result + #9;
        '\': Result := Result + '\';
        '"': Result := Result + '"';
        'u':
          begin
            if (i + 4 <= Length(Tail)) then
            begin
              Code := 0;
              OkU := True;
              for k := 1 to 4 do
              begin
                H := HexDigitVal(Tail[i + k]);
                if H < 0 then
                begin
                  OkU := False;
                  Break;
                end;
                Code := Code * 16 + H;
              end;
              if OkU then
              begin
                Result := Result + Char(Word(Code));
                Inc(i, 5);
                Esc := False;
                Continue;
              end;
            end;
            Result := Result + 'u';
          end;
      else
        Result := Result + Ch;
      end;
      Esc := False;
      Inc(i);
      Continue;
    end;
    if Ch = '\' then
    begin
      Esc := True;
      Inc(i);
      Continue;
    end;
    if Ch = '"' then
    begin
      InStr := False;
      Break;
    end;
    Result := Result + Ch;
    Inc(i);
  end;
end;

function StripMarkdownFences(const S: string): string;
var
  T: string;
  p: Integer;
begin
  T := Trim(S);
  if Copy(T, 1, 3) = '```' then
  begin
    Delete(T, 1, 3);
    if (Length(T) >= 4) and (Copy(T, 1, 4) = 'json') then
      Delete(T, 1, 4);
    T := Trim(T);
    p := PosBMH('```', T);
    if p > 0 then
      T := Trim(Copy(T, 1, p - 1));
  end;
  Result := T;
end;

function JsonUnescape(const S: string): string;
begin
  Result := StringReplace(S, '\"', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);
  Result := StringReplace(Result, '\/', '/', [rfReplaceAll]);
end;

function ParseJsonIntField(const Json, KeyName: string): Integer;
var
  Key, Tail, Num: string;
  p, i: Integer;
begin
  Result := 0;
  Key := '"' + KeyName + '"';
  p := PosBMHCi(Key, Json);
  if p = 0 then Exit;
  Tail := Copy(Json, p + Length(Key), MaxInt);
  i := 1;
  while (i <= Length(Tail)) and (Tail[i] in [#9, #10, #13, ' ']) do Inc(i);
  if (i > Length(Tail)) or (Tail[i] <> ':') then Exit;
  Inc(i);
  while (i <= Length(Tail)) and (Tail[i] in [#9, #10, #13, ' ']) do Inc(i);
  if i > Length(Tail) then Exit;
  if Tail[i] = '"' then
  begin
    Num := ExtractJsonStringFieldAnsi(Tail, KeyName);
    Result := StrToIntDef(Trim(Num), 0);
    Exit;
  end;
  Num := '';
  while (i <= Length(Tail)) and (Tail[i] in ['0'..'9']) do
  begin
    Num := Num + Tail[i];
    Inc(i);
  end;
  Result := StrToIntDef(Num, 0);
end;

procedure AssistantWriteLog(const ALine: string);
var
  Ini: TIniFile;
  LogOn: Boolean;
  F: TextFile;
  LogPath, IniPath: string;
begin
  IniPath := ExtractFilePath(Application.ExeName) + ASKIN_INI;
  LogOn := False;
  if FileExists(IniPath) then
  begin
    Ini := TIniFile.Create(IniPath);
    try
      LogOn := Ini.ReadInteger(APPLICATION_NAME, 'AssistantLog', 0) <> 0;
    finally
      Ini.Free;
    end;
  end;
  if not LogOn then Exit;
  LogPath := ExtractFilePath(Application.ExeName) + ASSISTANT_LOG;
  try
    AssignFile(F, LogPath);
    if FileExists(LogPath) then
      Append(F)
    else
      Rewrite(F);
    try
      WriteLn(F, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' ' + ALine);
    finally
      CloseFile(F);
    end;
  except
  end;
end;

function TryParseActionsChain(const S: string; var APlan: TAssistantPlan): Boolean;
var
  Idx, ObjStart, Brace, j: Integer;
  Low, Block, Act: string;
  St: TAssistantChainStep;
begin
  Result := False;
  APlan.ChainCount := 0;
  Low := LowerCase(S);
  Idx := PosBMH('"actions"', Low);
  if Idx = 0 then Exit;
  Idx := Idx + Length('"actions"');
  while (Idx <= Length(S)) and (S[Idx] <> '[') do Inc(Idx);
  if Idx > Length(S) then Exit;
  Inc(Idx);
  while (Idx <= Length(S)) and (APlan.ChainCount < ASSISTANT_MAX_CHAIN) do
  begin
    while (Idx <= Length(S)) and (S[Idx] in [#9, #10, #13, ' ', ',']) do Inc(Idx);
    if Idx > Length(S) then Break;
    if S[Idx] = ']' then Break;
    if S[Idx] <> '{' then Break;
    ObjStart := Idx;
    Brace := 1;
    Inc(Idx);
    while (Idx <= Length(S)) and (Brace > 0) do
    begin
      if S[Idx] = '{' then Inc(Brace)
      else if S[Idx] = '}' then Dec(Brace);
      Inc(Idx);
    end;
    Block := Copy(S, ObjStart, Idx - ObjStart);
    FillChar(St, SizeOf(St), 0);
    Act := LowerCase(ExtractJsonStringFieldAnsi(Block, 'action'));
    St.ActionId := Act;
    St.Path := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Block, 'path')));
    if St.Path = '' then
    begin
      j := PosBMH('"params"', LowerCase(Block));
      if j > 0 then
        St.Path := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Copy(Block, j, MaxInt), 'path')));
    end;
    St.Parts := ParseJsonIntField(Block, 'parts');
    if St.Parts = 0 then
    begin
      j := PosBMH('"params"', LowerCase(Block));
      if j > 0 then
        St.Parts := ParseJsonIntField(Copy(Block, j, MaxInt), 'parts');
    end;
    St.TotalParts := ParseJsonIntField(Block, 'total_parts');
    if St.TotalParts = 0 then
      St.TotalParts := St.Parts;
    St.PartFrom := ParseJsonIntField(Block, 'part_from');
    St.PartTo := ParseJsonIntField(Block, 'part_to');
    if St.PartFrom = 0 then St.PartFrom := 1;
    if St.PartTo = 0 then St.PartTo := St.PartFrom;
    St.FilterText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Block, 'filter_text')));
    if St.FilterText = '' then
      St.FilterText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Block, 'filter')));
    St.LineNo := ParseJsonIntField(Block, 'line_no');
    if St.LineNo = 0 then
      St.LineNo := ParseJsonIntField(Block, 'line');
    St.MaxLines := ParseJsonIntField(Block, 'max_lines');
    if St.MaxLines = 0 then
      St.MaxLines := ParseJsonIntField(Block, 'limit');
    if St.MaxLines = 0 then
      St.MaxLines := ParseJsonIntField(Block, 'max_records');
    if (St.LineNo = 0) or (Act = 'open_recent_file') then
    begin
      j := ParseJsonIntField(Block, 'recent_index');
      if j <> 0 then
        St.LineNo := j;
      if St.LineNo = 0 then
      begin
        j := PosBMH('"params"', LowerCase(Block));
        if j > 0 then
        begin
          St.LineNo := ParseJsonIntField(Copy(Block, j, MaxInt), 'recent_index');
          if St.MaxLines = 0 then
          begin
            St.MaxLines := ParseJsonIntField(Copy(Block, j, MaxInt), 'max_lines');
            if St.MaxLines = 0 then
              St.MaxLines := ParseJsonIntField(Copy(Block, j, MaxInt), 'limit');
          end;
        end;
      end;
    end;
    if St.FilterText = '' then
      St.FilterText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Block, 'search_text')));
    St.ReplaceText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Block, 'replace_text')));
    if St.ReplaceText = '' then
      St.ReplaceText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(Block, 'replacement')));
    if PosBMH('"case_sensitive":true', LowerCase(Block)) > 0 then
      St.CaseSensitive := True
    else if PosBMH('"case_sensitive":false', LowerCase(Block)) > 0 then
      St.CaseSensitive := False;
    St.ByteOffset := StrToInt64Def(Trim(ExtractJsonStringFieldAnsi(Block, 'byte_offset')), 0);
    if Act <> '' then
    begin
      APlan.Chain[APlan.ChainCount] := St;
      Inc(APlan.ChainCount);
      Result := True;
    end;
  end;
end;

procedure PlanFromFirstChainItem(var APlan: TAssistantPlan);
var
  St: TAssistantChainStep;
begin
  if APlan.ChainCount <= 0 then Exit;
  St := APlan.Chain[0];
  APlan.ActionId := St.ActionId;
  APlan.Path := St.Path;
  APlan.Parts := St.Parts;
  APlan.TotalParts := St.TotalParts;
  APlan.PartFrom := St.PartFrom;
  APlan.PartTo := St.PartTo;
  APlan.FilterText := St.FilterText;
  APlan.ReplaceText := St.ReplaceText;
  APlan.LineNo := St.LineNo;
  APlan.MaxLines := St.MaxLines;
  APlan.CaseSensitive := St.CaseSensitive;
  APlan.ByteOffset := St.ByteOffset;
  if APlan.Intent = aiUnknown then
    APlan.Intent := aiExecute;
end;

function IsAllowedActionId(const AId: string): Boolean; forward;
function BuildOpenFileLocalFactsText(const UserQ: string): string; forward;
function BuildComposeKnownFactsBlock(const UserQ: string): string; forward;
function ComposeBodyLooksLikeAccessRefusal(const S: string): Boolean; forward;
function MergeComposeChatParts(const AFacts, ASummary, ASaved: string): string; forward;
function ResolveStructuralFilterNeedle(const UserQ, PlanFilter: string): string; forward;
function ExtractPartialMarkerNeedles(const AQuestion: string): string; forward;
function IsComposeDestExtension(const AExt: string; AAllowTxt: Boolean): Boolean; forward;
function TryRequestedComposeFormat(const AQuestion: string; out AExt: string): Boolean; forward;
function MergePipeNeedles(const A, B: string): string; forward;
function SubtractPipeNeedles(const ASrc, ADrop: string): string; forward;

procedure TrimTrailingPathPunct(var S: string);
begin
  while (Length(S) > 0) and (S[Length(S)] in [',', '.', ';', ':', ')', ']', '}', '"', '''']) do
    SetLength(S, Length(S) - 1);
end;

function MergePipeNeedles(const A, B: string): string;
var
  OutL, InL: TStringList;
  Pass, j: Integer;
  Src, U: string;
begin
  Result := '';
  OutL := TStringList.Create;
  InL := TStringList.Create;
  try
    OutL.CaseSensitive := False;
    InL.StrictDelimiter := True;
    InL.Delimiter := '|';
    for Pass := 1 to 2 do
    begin
      if Pass = 1 then
        Src := Trim(A)
      else
        Src := Trim(B);
      if Src = '' then Continue;
      InL.DelimitedText := StringReplace(Src, ',', '|', [rfReplaceAll]);
      for j := 0 to InL.Count - 1 do
      begin
        U := Trim(InL[j]);
        if (U <> '') and (OutL.IndexOf(U) < 0) then
          OutL.Add(U);
      end;
    end;
    for j := 0 to OutL.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + '|';
      Result := Result + OutL[j];
    end;
  finally
    InL.Free;
    OutL.Free;
  end;
end;

function SubtractPipeNeedles(const ASrc, ADrop: string): string;
var
  SrcL, DropL: TStringList;
  j: Integer;
  U: string;
begin
  Result := '';
  if Trim(ASrc) = '' then Exit;
  SrcL := TStringList.Create;
  DropL := TStringList.Create;
  try
    SrcL.StrictDelimiter := True;
    SrcL.Delimiter := '|';
    DropL.CaseSensitive := False;
    DropL.StrictDelimiter := True;
    DropL.Delimiter := '|';
    SrcL.DelimitedText := StringReplace(Trim(ASrc), ',', '|', [rfReplaceAll]);
    DropL.DelimitedText := StringReplace(Trim(ADrop), ',', '|', [rfReplaceAll]);
    for j := 0 to SrcL.Count - 1 do
    begin
      U := Trim(SrcL[j]);
      if (U = '') or (DropL.IndexOf(U) >= 0) then Continue;
      if Result <> '' then
        Result := Result + '|';
      Result := Result + U;
    end;
  finally
    DropL.Free;
    SrcL.Free;
  end;
end;

function ExtractPartialMarkerNeedles(const AQuestion: string): string;
var
  FoldQ, Src, Tok: string;
  Markers: array[0..2] of string;
  i, At, j, TokEnd: Integer;
begin
  { Structural: the token immediately before (parcial)/(partial)/(substring). }
  Result := '';
  Src := Trim(AQuestion);
  if Src = '' then Exit;
  FoldQ := FoldDiacriticsForMatch(Src);
  Markers[0] := '(parcial)';
  Markers[1] := '(partial)';
  Markers[2] := '(substring)';
  for i := 0 to High(Markers) do
  begin
    At := PosBMH(Markers[i], FoldQ);
    if At <= 1 then Continue;
    j := At - 1;
    while (j >= 1) and (Src[j] <= ' ') do
      Dec(j);
    TokEnd := j;
    while (j >= 1) and (Src[j] > ' ') and
          (not CharInSet(Src[j], ['(', ')', ',', ';', ':', '"', ''''])) do
      Dec(j);
    Tok := Trim(Copy(Src, j + 1, TokEnd - j));
    while (Length(Tok) > 0) and CharInSet(Tok[Length(Tok)], ['.', ',', ';', ':']) do
      SetLength(Tok, Length(Tok) - 1);
    if (Tok <> '') and (Length(Tok) <= 64) then
      Result := MergePipeNeedles(Result, Tok);
  end;
end;

{ Unquoted "C:\file.txt em duas partes" must stop after the extension. }
function PathSoFarLooksComplete(const PathSoFar: string): Boolean;
var
  Dot, Slash, j: Integer;
  Ext: string;
begin
  Result := False;
  if PathSoFar = '' then Exit;
  Slash := LastDelimiter('\/', PathSoFar);
  Dot := LastDelimiter('.', PathSoFar);
  if (Dot <= 0) or (Dot <= Slash) or (Dot >= Length(PathSoFar)) then Exit;
  Ext := Copy(PathSoFar, Dot + 1, MaxInt);
  if (Length(Ext) < 1) or (Length(Ext) > 10) then Exit;
  for j := 1 to Length(Ext) do
    if not (Ext[j] in ['A'..'Z', 'a'..'z', '0'..'9']) then Exit;
  Result := True;
end;

procedure ClampExtractedFilePath(var Path: string);
var
  L: string;
  CutAt, p: Integer;
begin
  TrimTrailingPathPunct(Path);
  if Path = '' then Exit;
  L := LowerCase(Path);
  CutAt := 0;
  p := PosBMH(' em ', L);
  if p > 0 then CutAt := p;
  p := PosBMH(' into ', L);
  if (p > 0) and ((CutAt = 0) or (p < CutAt)) then CutAt := p;
  p := PosBMH(' in ', L);
  if (p > 0) and PathSoFarLooksComplete(Copy(Path, 1, p - 1)) and
     ((CutAt = 0) or (p < CutAt)) then
    CutAt := p;
  if CutAt > 1 then
  begin
    Path := Trim(Copy(Path, 1, CutAt - 1));
    TrimTrailingPathPunct(Path);
  end;
end;

function ExtractPathFromUserText(const S: string): string;
var
  i, p, EndPos: Integer;
  Ch: Char;
  T: string;
begin
  Result := '';
  for i := 1 to Length(S) do
    if S[i] in ['"', ''''] then
    begin
      Ch := S[i];
      p := i + 1;
      EndPos := p;
      while (EndPos <= Length(S)) and (S[EndPos] <> Ch) do Inc(EndPos);
      if EndPos > Length(S) then Continue;
      T := Trim(Copy(S, p, EndPos - p));
      if (Length(T) >= 3) and (T[2] = ':') and (T[3] in ['\', '/']) then
      begin
        Result := T;
        ClampExtractedFilePath(Result);
        Exit;
      end;
      if (Length(T) >= 2) and (T[1] = '\') and (T[2] = '\') then
      begin
        Result := T;
        ClampExtractedFilePath(Result);
        Exit;
      end;
    end;
  for i := 1 to Length(S) - 2 do
    if (S[i] in ['A'..'Z', 'a'..'z']) and (S[i + 1] = ':') and (S[i + 2] in ['\', '/']) then
    begin
      p := i;
      EndPos := p;
      while EndPos <= Length(S) do
      begin
        if S[EndPos] in [#0..#31, '"', ''''] then Break;
        if (S[EndPos] = ' ') and PathSoFarLooksComplete(Copy(S, p, EndPos - p)) then
          Break;
        Inc(EndPos);
      end;
      Result := Trim(Copy(S, p, EndPos - p));
      ClampExtractedFilePath(Result);
      Exit;
    end;
end;

function PathLooksLikeComposeOutputNotSource(const APath: string): Boolean;
{ AI often puts the intended PDF/Word output path into params.path. }
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(Trim(APath)));
  Result := (Ext = '.pdf') or (Ext = '.docx') or (Ext = '.odt') or
    (Ext = '.rtf') or (Ext = '.doc') or (Ext = '.md') or (Ext = '.html') or
    (Ext = '.htm');
end;

function PathLooksLikeGeneratedDestNotSource(const APath: string): Boolean;
var
  Ext: string;
begin
  Result := PathLooksLikeComposeOutputNotSource(APath);
  if Result then Exit;
  Ext := LowerCase(ExtractFileExt(Trim(APath)));
  Result := (Ext = '.py') or (Ext = '.js') or (Ext = '.ts') or (Ext = '.tsx') or
    (Ext = '.jsx') or (Ext = '.go') or (Ext = '.java') or (Ext = '.cpp') or
    (Ext = '.cs') or (Ext = '.rb') or (Ext = '.php');
end;

function TryBindChatQuestionSourceFile(const UserQ: string; out AErr: string): Boolean;
var
  Paths: TStringDynArray;
  i: Integer;
  P, BindPath: string;
begin
  { Full path in the question: must exist on disk (except generated dest).
    Existing source path is copied into edtFileName. No path → keep the box. }
  Result := True;
  AErr := '';
  BindPath := '';
  if not CollectWindowsFullPathsFromText(UserQ, Paths) then
    Exit;
  for i := 0 to High(Paths) do
  begin
    P := Trim(Paths[i]);
    if P = '' then Continue;
    if DirectoryExists(P) then
    begin
      AErr := Format(TrText('Assistant.Error.ChatPathIsFolder'), [P]);
      Result := False;
      Exit;
    end;
    if FileExists(P) then
    begin
      if BindPath = '' then
        BindPath := P;
      Continue;
    end;
    if PathLooksLikeGeneratedDestNotSource(P) then
      Continue;
    AErr := Format(TrText('Assistant.Error.ChatFileMissing'), [P]);
    Result := False;
    Exit;
  end;
  if BindPath <> '' then
    AssistantHostSetFileNameBox(BindPath);
end;

function ChatResolvedSourcePath(const UserQ: string): string;
begin
  Result := Trim(ExtractPathFromUserText(UserQ));
  if Result = '' then
    Result := Trim(AssistantHostGetOpenFilePath);
  if (Result = '') or (Result = SELECTTEXT) then
    Result := '';
end;

function ChatHasUsableSourceFile(const UserQ: string): Boolean;
var
  P: string;
begin
  P := ChatResolvedSourcePath(UserQ);
  Result := (P <> '') and FileExists(P) and (not DirectoryExists(P));
end;

function ChatQuestionIsStandaloneWithoutSource(const AQuestion: string): Boolean;
begin
  { App help, write-from-scratch, validate picker, recent-list open — no edtFileName. }
  Result := UserWantsComposeSourceCode(AQuestion) or
    UserWantsLoadSourceToValidate(AQuestion) or
    UserAsksValidateSupportedLanguages(AQuestion) or
    UserQuestionRefersToRecentFilesList(AQuestion) or
    UserQuestionIsExplicitLocalShortcut(AQuestion);
end;

function ChatQuestionRequiresBoundSourceFile(const AQuestion: string): Boolean;
var
  L: string;
  Prefs: TStringDynArray;
begin
  { Structural only: pronouns / line count / disk meta / digit needles.
    No ActionId steal — just "this ask needs a real file". }
  Result := False;
  if Trim(AQuestion) = '' then Exit;
  if ChatQuestionIsStandaloneWithoutSource(AQuestion) then Exit;
  L := FoldDiacriticsForMatch(AQuestion);
  Result := UserQuestionRefersToOpenFile(AQuestion) or
    TryParseLinePrefixCountAsk(AQuestion, Prefs) or
    QuestionHasLongDigitNeedle(AQuestion) or
    LooksLikeFilePurposeQuestion(AQuestion) or
    LooksLikeSemanticFileQuestion(L) or
    UserWantsFileSummaryToDocument(AQuestion) or
    UserWantsConsumerRAGContentQuestion(AQuestion) or
    UserWantsConsumerAIContentQuestion(AQuestion) or
    LooksLikeFileMathOrDataOp(AQuestion);
end;

procedure SanitizeCountSourcePath(var Plan: TAssistantPlan);
var
  OpenPath: string;
begin
  if not (SameText(Plan.ActionId, 'count_line_prefixes') or
          SameText(Plan.ActionId, 'count_matching_lines')) then
    Exit;
  OpenPath := Trim(AssistantHostGetOpenFilePath);
  if Trim(Plan.Path) <> '' then
  begin
    if PathLooksLikeComposeOutputNotSource(Plan.Path) then
      Plan.Path := ''
    else if not FileExists(Plan.Path) then
      Plan.Path := '';
  end;
  if Trim(Plan.Path) = '' then
    Plan.Path := OpenPath;
end;

function PartsCountFromWordToken(const W: string): Integer;
var
  T: string;
begin
  Result := 0;
  T := LowerCase(Trim(W));
  if T = '' then Exit;
  if (T = 'dois') or (T = 'duas') or (T = 'two') or (T = 'dos') or
     (T = 'deux') or (T = 'zwei') or (T = 'due') or (T = 'dwa') or
     (T = 'dwie') or (T = 'doua') or (T = 'ket') or (T = 'ketto') or
     (T = 'kett'#337) or (T = 'dva') or (T = 'dve') then
    Result := 2
  else if (T = 'tres') or (T = 'tr'#234's') or (T = 'three') or (T = 'trois') or
          (T = 'drei') or (T = 'tre') or (T = 'trzy') or (T = 'trei') or
          (T = 'harom') or (T = 'h'#225'rom') or (T = 'tri') then
    Result := 3
  else if (T = 'quatro') or (T = 'four') or (T = 'cuatro') or (T = 'quatre') or
          (T = 'vier') or (T = 'quattro') or (T = 'cztery') or (T = 'patru') or
          (T = 'negy') or (T = 'n'#233'gy') or (T = 'ctyri') then
    Result := 4
  else if (T = 'cinco') or (T = 'five') or (T = 'cinq') or (T = 'funf') or
          (T = 'f'#252'nf') or (T = 'cinque') or (T = 'piec') or (T = 'cinci') or
          (T = 'ot') or (T = #246't') or (T = 'pet') then
    Result := 5
  else if (T = 'seis') or (T = 'six') or (T = 'sechs') or (T = 'sei') or
          (T = 'szesc') or (T = 'sase') or (T = 'hat') or (T = 'sest') then
    Result := 6
  else if (T = 'sete') or (T = 'seven') or (T = 'siete') or (T = 'sept') or
          (T = 'sieben') or (T = 'sette') or (T = 'siedem') or (T = 'sapte') or
          (T = 'het') or (T = 'sedm') then
    Result := 7
  else if (T = 'oito') or (T = 'eight') or (T = 'ocho') or (T = 'huit') or
          (T = 'acht') or (T = 'otto') or (T = 'osiem') or (T = 'opt') or
          (T = 'nyolc') or (T = 'osm') then
    Result := 8
  else if (T = 'nove') or (T = 'nine') or (T = 'nueve') or (T = 'neuf') or
          (T = 'neun') or (T = 'dziewiec') or (T = 'noua') or (T = 'kilenc') or
          (T = 'devet') then
    Result := 9
  else if (T = 'dez') or (T = 'ten') or (T = 'diez') or (T = 'dix') or
          (T = 'zehn') or (T = 'dieci') or (T = 'dziesiec') or (T = 'zece') or
          (T = 'tiz') or (T = 't'#237'z') or (T = 'deset') then
    Result := 10;
end;

function ExtractPartsCountFromText(const Q: string): Integer;
var
  L, Word: string;
  i, p, WordEdge: Integer;
  Num: string;

  function FindPartsKeywordPos(const S: string): Integer;
  begin
    Result := PosBMH(' partes', S);
    if Result = 0 then Result := PosBMH(' parts', S);
    if Result = 0 then Result := PosBMH(' parte', S);
    if Result = 0 then Result := PosBMH(' part', S);
    if Result = 0 then Result := PosBMH(' parties', S);
    if Result = 0 then Result := PosBMH(' teile', S);
    if Result = 0 then
    begin
      { " parti" matches Italian/RO; skip Portuguese "partir". }
      Result := PosBMH(' parti', S);
      if (Result > 0) and (Result + 6 <= Length(S)) and (S[Result + 6] = 'r') then
        Result := 0;
    end;
    if Result = 0 then Result := PosBMH(' czesci', S);
    if Result = 0 then Result := PosBMH(' casti', S);
    if Result = 0 then Result := PosBMH(' reszek', S);
  end;

begin
  Result := 0;
  L := LowerCase(Q);
  p := FindPartsKeywordPos(L);
  if p > 0 then
  begin
    i := p - 1;
    while (i >= 1) and (L[i] = ' ') do Dec(i);
    Num := '';
    while (i >= 1) and (L[i] in ['0'..'9']) do
    begin
      Num := L[i] + Num;
      Dec(i);
    end;
    Result := StrToIntDef(Num, 0);
    if Result >= 2 then Exit;

    { Local WordEdge — never use "q": Delphi is case-insensitive vs const Q. }
    WordEdge := i;
    while (WordEdge >= 1) and (L[WordEdge] in ['a'..'z', #128..#255]) do Dec(WordEdge);
    Word := Copy(L, WordEdge + 1, i - WordEdge);
    Result := PartsCountFromWordToken(Word);
    if Result >= 2 then Exit;
  end;

  p := PosBMH(' into ', L);
  if p > 0 then
    i := p + 6
  else
  begin
    p := PosBMH(' em ', L);
    if p > 0 then
      i := p + 4
    else
    begin
      p := PosBMH(' en ', L);
      if p > 0 then
        i := p + 4
      else
      begin
        p := PosBMH(' in ', L);
        if p = 0 then
        begin
          p := PosBMH(' na ', L);
          if p = 0 then Exit;
          i := p + 4;
        end
        else
          i := p + 4;
      end;
    end;
  end;
  while (i <= Length(L)) and (L[i] = ' ') do Inc(i);
  Num := '';
  while (i <= Length(L)) and (L[i] in ['0'..'9']) do
  begin
    Num := Num + L[i];
    Inc(i);
  end;
  Result := StrToIntDef(Num, 0);
  if Result >= 2 then Exit;
  WordEdge := i;
  while (WordEdge <= Length(L)) and (L[WordEdge] in ['a'..'z', #128..#255]) do Inc(WordEdge);
  Word := Copy(L, i, WordEdge - i);
  Result := PartsCountFromWordToken(Word);
end;

function UserWantsOpenAndRead(const Q: string): Boolean;
var
  L, P: string;
begin
  P := ExtractPathFromUserText(Q);
  if P = '' then
  begin
    Result := False;
    Exit;
  end;
  if UserWantsShowScriptEngine(Q) or UserWantsShowTailMacro(Q) or
     UserHasSpecificToolIntent(Q) then
  begin
    Result := False;
    Exit;
  end;
  L := LowerCase(Q);
  if (PosBMH('como ', L) = 1) or (PosBMH('how ', L) = 1) or (PosBMH('como eu', L) > 0) or
     (PosBMH('como fa', L) > 0) or (PosBMH('how do', L) > 0) or (PosBMH('how can', L) > 0) then
  begin
    Result := False;
    Exit;
  end;
  Result :=
    (PosBMH('ler', L) > 0) or (PosBMH('leia', L) > 0) or
    (PosBMH('carregar', L) > 0) or (PosBMH('carrega', L) > 0) or (PosBMH('abrir', L) > 0) or
    (PosBMH('abra', L) > 0) or (PosBMH('read', L) > 0) or (PosBMH('load', L) > 0) or
    (PosBMH('open', L) > 0);
end;

function UserWantsShowTabRead(const Q: string): Boolean;
var
  L: string;
  HasScreen, HasLoad: Boolean;
begin
  L := LowerCase(Q);
  if ExtractPathFromUserText(Q) <> '' then
  begin
    Result := False;
    Exit;
  end;
  HasScreen := (PosBMH('tela', L) > 0) or (PosBMH('aba', L) > 0) or (PosBMH('tab', L) > 0) or
    (PosBMH('ecr', L) > 0) or (PosBMH('screen', L) > 0);
  HasLoad := (PosBMH('carregar', L) > 0) or (PosBMH('ler', L) > 0) or (PosBMH('leitura', L) > 0) or
    (PosBMH('read', L) > 0) or (PosBMH('load', L) > 0) or (PosBMH('abrir', L) > 0);
  Result := (HasScreen and HasLoad) or
    ((PosBMH('abrir', L) > 0) and (PosBMH('carregar', L) > 0)) or
    (PosBMH('show_tab_read', L) > 0);
end;

function UserRequestedCaseSensitive(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  if (PosBMH('insensitive', L) > 0) or (PosBMH('ignorar mai', L) > 0) or
     (PosBMH('sem diferenciar', L) > 0) or (PosBMH('case insensitive', L) > 0) then
    Result := False
  else if ((PosBMH('sensitive', L) > 0) and (PosBMH('insensitive', L) = 0)) or
     (PosBMH('maiuscul', L) > 0) or (PosBMH('match case', L) > 0) then
    Result := True
  else
    Result := False;
end;

{ Pedidos fora do FastFile ou que pedem SO / malware / destruicao — nunca executar nem compor. }
function UserQuestionIsOutOfScopeOrHarmful(const AQuestion: string): Boolean;
var
  L: string;

  function Hit(const Tok: string): Boolean;
  begin
    Result := PosBMH(Tok, L) > 0;
  end;

begin
  Result := False;
  L := LowerCase(Trim(AQuestion));
  if L = '' then Exit;

  { Disk / OS destruction }
  if Hit('formatar disco') or Hit('formatar o disco') or Hit('formatar hd') or
     Hit('formatar o hd') or Hit('formatar o pc') or Hit('formatar o computador') or
     Hit('formatar computador') or Hit('formatar windows') or Hit('formatar o windows') or
     Hit('format hd') or Hit('format c:') or Hit('format d:') or Hit('format drive') or
     Hit('format computer') or Hit('format the pc') or Hit('format the computer') or
     Hit('wipe disk') or Hit('wipe drive') or Hit('wipe pc') or Hit('apagar disco') or
     Hit('apagar o disco') or Hit('apagar o windows') or Hit('deletar windows') or
     Hit('diskpart') or Hit('fdisk') or Hit('clean all') then
  begin
    Result := True;
    Exit;
  end;

  { Run / launch OS executables and shells (not FastFile Script Engine phrasing alone) }
  if Hit('executar .exe') or Hit('executar o .exe') or Hit('executar programa') or
     Hit('executar aplicativo') or Hit('executar arquivo execut') or
     Hit('executar ficheiro execut') or Hit('executar ficheiro .exe') or
     Hit('rodar o .exe') or Hit('rodar programa') or Hit('run executable') or
     Hit('launch .exe') or Hit('abrir e executar') or Hit('shellexecute') or
     Hit('winexec') or Hit('createprocess') or Hit('cmd.exe') or
     Hit('powershell.exe') or Hit('comando do sistema') or Hit('comando do so') or
     Hit('comando do windows') or Hit('linha de comando do so') or
     Hit('executar comando') or Hit('rodar comando') or Hit('run shell command') or
     Hit('system command') or Hit('rm -rf') or Hit('del /f /s') or Hit('del /s /q') or
     Hit('rd /s /q') or Hit('shutdown /s') or Hit('shutdown -s') or
     Hit('reiniciar o computador') or Hit('desligar o computador') then
  begin
    Result := True;
    Exit;
  end;

  { Malware / abuse — criar, gerar ou ensinar }
  if Hit('criar virus') or Hit('crie um virus') or Hit('gere um virus') or
     Hit('gerar virus') or Hit('escreva um virus') or Hit('escrever um virus') or
     Hit('make a virus') or Hit('create a virus') or Hit('write a virus') or
     Hit('generate a virus') or Hit('baixar virus') or Hit('instalar virus') or
     Hit('criar malware') or Hit('gere malware') or Hit('gerar malware') or
     Hit('instalar malware') or Hit('create malware') or Hit('write malware') or
     Hit('ransomware') or Hit('keylogger') or Hit('key logger') or
     Hit('trojan') or Hit('backdoor') or Hit('rootkit') or Hit('botnet') or
     Hit('spyware') or Hit('steal password') or Hit('roubar senha') or
     Hit('credential dump') or Hit('mimikatz') or Hit('meterpreter') or
     Hit('reverse shell') or Hit('bind shell') or Hit('fork bomb') or
     Hit('criptografar todos os arquivos') or Hit('encrypt all files') or
     Hit('peca resgate') or Hit('peça resgate') or Hit('pedir resgate') or
     Hit('disable antivirus') or Hit('desativar antivirus') or
     Hit('desativar o windows defender') or Hit('disable windows defender') or
     (Hit('system32') and (Hit('apagar') or Hit('deletar') or Hit('delete ') or
      Hit('remover'))) then
  begin
    Result := True;
    Exit;
  end;

  { Build + malwareable payload language }
  if (Hit('gere um') or Hit('gera um') or Hit('gerar um') or Hit('escreva um') or
      Hit('criar um') or Hit('crie um') or Hit('write a') or Hit('create a') or
      Hit('generate a')) and
     (Hit('um virus') or Hit('a virus') or Hit('o virus') or Hit('malware') or
      Hit('ransomware') or Hit('keylogger') or Hit('trojan') or Hit('backdoor') or
      Hit('rootkit') or Hit('spyware') or Hit('botnet') or Hit('worm')) then
  begin
    Result := True;
    Exit;
  end;
end;

function IsForbiddenComposeExtension(const AExt: string): Boolean;
var
  E: string;
begin
  { Never write these via assistant compose (even if the model asks). }
  E := LowerCase(AExt);
  Result := (E = '.exe') or (E = '.dll') or (E = '.bat') or (E = '.cmd') or
    (E = '.com') or (E = '.vbs') or (E = '.vbe') or (E = '.wsf') or
    (E = '.scr') or (E = '.msi') or (E = '.cpl') or (E = '.pif') or
    (E = '.hta') or (E = '.lnk');
end;

function ExtractLineNumberFromText(const AQuestion: string): Integer;
var
  L: string;
  i, p, StartAt: Integer;
  Num: string;
begin
  Result := 0;
  L := LowerCase(AQuestion);
  p := PosBMH('linha', L);
  if p = 0 then p := PosBMH('line', L);
  if p = 0 then Exit;
  if p > 1 then
    StartAt := p
  else
    StartAt := 1;
  i := StartAt + 4;
  while (i <= Length(L)) and not (L[i] in ['0'..'9']) do Inc(i);
  Num := '';
  while (i <= Length(L)) and (L[i] in ['0'..'9']) do
  begin
    Num := Num + L[i];
    Inc(i);
  end;
  Result := StrToIntDef(Num, 0);
end;

function StripFilterHintParentheses(const S: string): string;
var
  L, T: string;
  p, q, Depth: Integer;
begin
  Result := Trim(S);
  if Result = '' then Exit;
  L := LowerCase(Result);
  p := PosBMH('(insensitive)', L);
  if p > 0 then
    Result := Trim(Copy(Result, 1, p - 1))
  else
  begin
    p := PosBMH('(case insensitive)', L);
    if p > 0 then
      Result := Trim(Copy(Result, 1, p - 1))
    else
    begin
      p := PosBMH('(ignorar mai', L);
      if p > 0 then
        Result := Trim(Copy(Result, 1, p - 1));
    end;
  end;
  T := '';
  p := 1;
  while p <= Length(Result) do
  begin
    if Result[p] = '(' then
    begin
      Depth := 1;
      q := p + 1;
      while (q <= Length(Result)) and (Depth > 0) do
      begin
        if Result[q] = '(' then Inc(Depth)
        else if Result[q] = ')' then Dec(Depth);
        Inc(q);
      end;
      Inc(p);
      Continue;
    end;
    T := T + Result[p];
    Inc(p);
  end;
  Result := Trim(T);
  p := PosBMH(' e exportar', LowerCase(Result));
  if p > 0 then
    Result := Trim(Copy(Result, 1, p - 1));
end;

function ExtractSearchTextFromText(const AQuestion: string): string;
var
  L: string;
  i, p, q, StartPos: Integer;
  Ch: Char;
  T: string;
begin
  Result := '';
  for i := 1 to Length(AQuestion) do
    if AQuestion[i] in ['"', ''''] then
    begin
      Ch := AQuestion[i];
      p := i + 1;
      q := p;
      while (q <= Length(AQuestion)) and (AQuestion[q] <> Ch) do Inc(q);
      if q > Length(AQuestion) then Continue;
      T := Trim(Copy(AQuestion, p, q - p));
      if (Length(T) >= 3) and (T[2] = ':') and (T[3] in ['\', '/']) then
        Continue;
      if T <> '' then
      begin
        Result := T;
        Exit;
      end;
    end;
  L := LowerCase(AQuestion);
  p := PosBMH('palavra ', L);
  if p > 0 then
    StartPos := p + Length('palavra ')
  else
  begin
    p := PosBMH('word ', L);
    if p > 0 then
      StartPos := p + Length('word ')
    else
      StartPos := 0;
  end;
  if StartPos > 0 then
  begin
    T := Trim(Copy(AQuestion, StartPos, MaxInt));
    p := PosBMH('(', T);
    if p > 0 then
      T := Trim(Copy(T, 1, p - 1));
    while (Length(T) > 0) and (T[Length(T)] in [' ', ',', ';']) do
      SetLength(T, Length(T) - 1);
    if T <> '' then
    begin
      Result := T;
      Exit;
    end;
  end;
  p := PosBMH('procurar ', L);
  if p = 0 then p := PosBMH('buscar ', L);
  if p = 0 then p := PosBMH('search ', L);
  if p = 0 then p := PosBMH('find ', L);
  if p > 0 then
  begin
    T := Trim(Copy(AQuestion, p, MaxInt));
    if PosBMH('pela palavra ', LowerCase(T)) = 1 then
      T := Trim(Copy(T, Length('pela palavra ') + 1, MaxInt))
    else if PosBMH('por ', LowerCase(T)) = 1 then
      T := Trim(Copy(T, Length('por ') + 1, MaxInt));
    p := PosBMH('(', T);
    if p > 0 then
      T := Trim(Copy(T, 1, p - 1));
    if (T <> '') and (PosBMH('palavra', LowerCase(T)) <> 1) then
      Result := T;
  end;
end;

function NormalizeAssistantFilterNeedle(const AUserQ, ARawPattern: string): string;
var
  T: string;
begin
  T := Trim(ExtractSearchTextFromText(AUserQ));
  if T = '' then
    T := Trim(ARawPattern);
  T := StripFilterHintParentheses(T);
  if (Length(T) > 80) and (PosBMH('exportar', LowerCase(T)) > 0) then
    T := Trim(ExtractSearchTextFromText(T));
  Result := StripFilterHintParentheses(T);
end;

function UserWantsFindText(const AQuestion: string; out ASearchText: string): Boolean;
var
  L, FoldL, Src, T: string;
  At, k: Integer;

  procedure TryAfter(const ANeedle: string);
  begin
    if ASearchText <> '' then Exit;
    At := PosBMH(ANeedle, FoldL);
    if At <= 0 then Exit;
    k := At + Length(ANeedle);
    while (k <= Length(Src)) and (Src[k] in [' ', #9, '"', '''', '=', ':']) do
      Inc(k);
    T := '';
    while (k <= Length(Src)) and (Src[k] in ['0'..'9', 'A'..'Z', 'a'..'z', '_', '-', '.']) do
    begin
      T := T + Src[k];
      Inc(k);
    end;
    if Length(T) >= 2 then
      ASearchText := T;
  end;

begin
  Result := False;
  ASearchText := '';
  L := LowerCase(AQuestion);
  FoldL := FoldDiacriticsForMatch(L);
  Src := AQuestion;
  if (PosBMH('procur', FoldL) = 0) and (PosBMH('busc', FoldL) = 0) and
     (PosBMH('search', FoldL) = 0) and (PosBMH('find', FoldL) = 0) and
     (PosBMH('localiz', FoldL) = 0) then
    Exit;
  ASearchText := ExtractSearchTextFromText(AQuestion);
  if ASearchText = '' then
  begin
    TryAfter('o texto ');
    TryAfter('texto ');
    TryAfter('the text ');
    TryAfter('text ');
    TryAfter('por ');
    TryAfter('for ');
    TryAfter('procurar ');
    TryAfter('procura ');
    TryAfter('buscar ');
    TryAfter('search ');
    TryAfter('find ');
  end;
  Result := ASearchText <> '';
end;

function UserWantsGotoLine(const AQuestion: string; out ALineNo: Integer): Boolean;
var
  L, RangeParams: string;
begin
  Result := False;
  ALineNo := ExtractLineNumberFromText(AQuestion);
  if ALineNo < 1 then Exit;
  if TryParseLineRangeParams(AQuestion, RangeParams) then Exit;
  L := LowerCase(AQuestion);
  Result := (PosBMH('ir para', L) > 0) or (PosBMH('vai para', L) > 0) or (PosBMH('goto', L) > 0) or
    (PosBMH('go to', L) > 0) or
    (((PosBMH('linha', L) > 0) or (PosBMH('line', L) > 0)) and
     ((PosBMH('ir ', L) > 0) or (PosBMH('vai ', L) > 0) or (PosBMH('go ', L) > 0)));
end;

function UserWantsEditLine(const AQuestion: string; out ALineNo: Integer): Boolean;
var
  L: string;
begin
  Result := False;
  ALineNo := ExtractLineNumberFromText(AQuestion);
  if ALineNo < 1 then Exit;
  L := LowerCase(AQuestion);
  Result := (PosBMH('editar', L) > 0) or (PosBMH('edit', L) > 0) or (PosBMH('alterar', L) > 0) or
    (PosBMH('modificar', L) > 0);
end;

function UserWantsApplyFilter(const AQuestion: string; out APattern: string): Boolean;
var
  L, FoldL, Src, T: string;
  At, k: Integer;

  procedure TryAfter(const ANeedle: string);
  begin
    if APattern <> '' then Exit;
    At := PosBMH(ANeedle, FoldL);
    while At > 0 do
    begin
      k := At + Length(ANeedle);
      while (k <= Length(Src)) and (Src[k] in [' ', #9, '"', '''', '=', ':']) do
        Inc(k);
      T := '';
      while (k <= Length(Src)) and (Src[k] in ['0'..'9', 'A'..'Z', 'a'..'z', '_', '-', '.']) do
      begin
        T := T + Src[k];
        Inc(k);
      end;
      if Length(T) >= 1 then
      begin
        APattern := T;
        Exit;
      end;
      At := PosBMHFrom(ANeedle, FoldL, At + Length(ANeedle));
    end;
  end;

begin
  Result := False;
  APattern := '';
  L := LowerCase(AQuestion);
  FoldL := FoldDiacriticsForMatch(L);
  Src := AQuestion;
  if (PosBMH('filtr', FoldL) = 0) and (PosBMH('filter', FoldL) = 0) and
     (PosBMH('grep', FoldL) = 0) then
    Exit;
  if (PosBMH('limpar', FoldL) > 0) or (PosBMH('clear', FoldL) > 0) then Exit;
  APattern := ExtractSearchTextFromText(AQuestion);
  if APattern = '' then
  begin
    TryAfter('contem ');
    TryAfter('containing ');
    TryAfter('contain ');
    TryAfter('mit ');
    TryAfter('avec ');
    TryAfter('con ');
    TryAfter('com o texto ');
    TryAfter('com texto ');
    TryAfter('com ');
    TryAfter('que contem ');
    TryAfter('linhas com ');
    TryAfter('lines with ');
    TryAfter('filtro ');
    TryAfter('filter ');
  end;
  if APattern = '' then
  begin
    At := PosBMH('filtro ', FoldL);
    if At > 0 then
      APattern := Trim(Copy(AQuestion, At + 7, MaxInt));
  end;
  APattern := Trim(NormalizeAssistantFilterNeedle(AQuestion, APattern));
  { Avoid swallowing the rest of a compound sentence as the needle. }
  if Pos(' ', APattern) > 0 then
    APattern := Trim(Copy(APattern, 1, Pos(' ', APattern) - 1));
  Result := APattern <> '';
end;

function UserWantsClearFilter(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result := ((PosBMH('limpar', L) > 0) or (PosBMH('clear', L) > 0) or
    (PosBMH('remover', L) > 0) or (PosBMH('tirar', L) > 0) or
    (PosBMH('desativar', L) > 0) or (PosBMH('apagar', L) > 0)) and
    ((PosBMH('filtro', L) > 0) or (PosBMH('filter', L) > 0));
end;

function UserWantsContinueFilter(const AQuestion: string): Boolean;
var
  L, FoldL: string;
begin
  L := LowerCase(AQuestion);
  FoldL := FoldDiacriticsForMatch(L);
  Result := False;
  if (PosBMH('filtr', FoldL) = 0) and (PosBMH('filter', FoldL) = 0) and
     (PosBMH('grep', FoldL) = 0) and (PosBMH('hits', FoldL) = 0) then
    Exit;
  Result :=
    (PosBMH('continuar', FoldL) > 0) or (PosBMH('continue', FoldL) > 0) or
    (PosBMH('mais hits', FoldL) > 0) or (PosBMH('more hits', FoldL) > 0) or
    (PosBMH('carregar mais', FoldL) > 0) or (PosBMH('load more', FoldL) > 0) or
    (PosBMH('mais resultados', FoldL) > 0) or (PosBMH('more filter', FoldL) > 0) or
    (PosBMH('seguir filtrando', FoldL) > 0) or
    (PosBMH('continuar stream', FoldL) > 0) or (PosBMH('filter stream', FoldL) > 0);
end;

function UserWantsCopyFiltered(const AQuestion: string): Boolean;
var
  L, FoldL: string;
begin
  L := LowerCase(AQuestion);
  FoldL := FoldDiacriticsForMatch(L);
  Result := False;
  if (PosBMH('copiar', FoldL) = 0) and (PosBMH('copy', FoldL) = 0) and
     (PosBMH('clipboard', FoldL) = 0) then
    Exit;
  Result := (PosBMH('filtr', FoldL) > 0) or (PosBMH('filter', FoldL) > 0) or
    (PosBMH('grep', FoldL) > 0) or (PosBMH('hits', FoldL) > 0);
end;

function UserWantsOpenFilterBar(const AQuestion: string): Boolean;
var
  L, FoldL, Dummy: string;
begin
  L := LowerCase(AQuestion);
  FoldL := FoldDiacriticsForMatch(L);
  Result := False;
  if UserWantsClearFilter(AQuestion) or UserWantsContinueFilter(AQuestion) or
     UserWantsCopyFiltered(AQuestion) then
    Exit;
  if UserWantsApplyFilter(AQuestion, Dummy) then
    Exit;
  if (PosBMH('ctrl+l', FoldL) > 0) or (PosBMH('ctrl + l', FoldL) > 0) then
  begin
    Result := True;
    Exit;
  end;
  if ((PosBMH('abrir', FoldL) > 0) or (PosBMH('mostrar', FoldL) > 0) or
      (PosBMH('open', FoldL) > 0) or (PosBMH('show', FoldL) > 0)) and
     ((PosBMH('filtr', FoldL) > 0) or (PosBMH('filter', FoldL) > 0) or
      (PosBMH('grep', FoldL) > 0)) then
    Result := True;
end;

function UserAsksAboutActiveFilter(const AQuestion: string): Boolean;
var
  L, FoldL, Dummy: string;
begin
  L := LowerCase(AQuestion);
  FoldL := FoldDiacriticsForMatch(L);
  Result := False;
  if (PosBMH('filtr', FoldL) = 0) and (PosBMH('filter', FoldL) = 0) and
     (PosBMH('grep', FoldL) = 0) then
    Exit;
  if UserWantsClearFilter(AQuestion) or UserWantsContinueFilter(AQuestion) or
     UserWantsCopyFiltered(AQuestion) or UserWantsOpenFilterBar(AQuestion) or
     UserWantsApplyFilter(AQuestion, Dummy) then
    Exit;
  if (PosBMH('export', FoldL) > 0) or (PosBMH('exportar', FoldL) > 0) or
     (PosBMH('salvar', FoldL) > 0) or (PosBMH('save', FoldL) > 0) then
    Exit;
  Result :=
    (PosBMH('status', FoldL) > 0) or (PosBMH('atual', FoldL) > 0) or
    (PosBMH('activo', FoldL) > 0) or (PosBMH('ativo', FoldL) > 0) or
    (PosBMH('active', FoldL) > 0) or (PosBMH('current', FoldL) > 0) or
    (PosBMH('quantos', FoldL) > 0) or (PosBMH('how many', FoldL) > 0) or
    (PosBMH('hits', FoldL) > 0) or
    (PosBMH('sobre o filtro', FoldL) > 0) or (PosBMH('sobre o filter', FoldL) > 0) or
    (PosBMH('falar do filtro', FoldL) > 0) or (PosBMH('falar do filter', FoldL) > 0) or
    (PosBMH('qual o filtro', FoldL) > 0) or (PosBMH('which filter', FoldL) > 0) or
    (PosBMH('filtro atual', FoldL) > 0) or (PosBMH('esse filtro', FoldL) > 0) or
    (PosBMH('este filtro', FoldL) > 0) or (PosBMH('that filter', FoldL) > 0) or
    (PosBMH('the filter', FoldL) > 0) or (PosBMH('o filtro ativo', FoldL) > 0) or
    (PosBMH('filtro activo', FoldL) > 0);
end;

function FormatActiveFilterStatusMessage: string;
var
  Pat, PartialNote: string;
  Hits: Int64;
begin
  Pat := Trim(AssistantHostGetActiveFilterText);
  Hits := AssistantHostGetFilteredHitCount;
  if Pat = '' then
  begin
    Result := TrText('Assistant.Status.FilterInactive');
    Exit;
  end;
  if AssistantHostGetFilterPartial then
    PartialNote := TrText('Assistant.Status.FilterPartialNote')
  else
    PartialNote := '';
  Result := Format(TrText('Assistant.Status.FilterActiveInfo'),
    [Pat, IntToStr(Hits), PartialNote]);
end;

function UserWantsStartTail(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result := (PosBMH('tail', L) > 0) or (PosBMH('seguir', L) > 0) or (PosBMH('follow', L) > 0) or
    ((PosBMH('monitor', L) > 0) and (PosBMH('arquivo', L) > 0));
end;

function UserWantsExport(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result := (PosBMH('export', L) > 0) or (PosBMH('exportar', L) > 0);
end;

function ExtractTwoQuotedStrings(const AQuestion: string; out S1, S2: string): Boolean;
var
  i, p, q: Integer;
  Ch: Char;
  Found: Integer;
begin
  Result := False;
  S1 := '';
  S2 := '';
  Found := 0;
  i := 1;
  while (i <= Length(AQuestion)) and (Found < 2) do
  begin
    if not (AQuestion[i] in ['"', '''']) then
    begin
      Inc(i);
      Continue;
    end;
    Ch := AQuestion[i];
    p := i + 1;
    q := p;
    while (q <= Length(AQuestion)) and (AQuestion[q] <> Ch) do Inc(q);
    if q > Length(AQuestion) then Break;
    if Found = 0 then
      S1 := Copy(AQuestion, p, q - p)
    else
      S2 := Copy(AQuestion, p, q - p);
    Inc(Found);
    i := q + 1;
  end;
  Result := (Found >= 2) and (S1 <> '') and (S2 <> '');
end;

function ExtractReplacePairFromText(const AQuestion: string; out AFind, AReplace: string): Boolean;
var
  L: string;
  pPor, pSub, LenSub, LenPor: Integer;

  function StripOuterQuotes(const S: string): string;
  var
    T: string;
  begin
    T := Trim(S);
    if (Length(T) >= 2) and (T[1] in ['"', '''']) and (T[Length(T)] = T[1]) then
      Result := Copy(T, 2, Length(T) - 2)
    else
      Result := T;
  end;

  function TryDeParaPair(const L, Q: string; pPor: Integer; LenAfterPor: Integer): Boolean;
  var
    pDe, I: Integer;
  begin
    Result := False;
    AFind := '';
    AReplace := '';
    if pPor <= 0 then Exit;
    pDe := 0;
    I := pPor - 1;
    while I >= 1 do
    begin
      if (I + 3 <= Length(L)) and (Copy(L, I, 4) = ' de ') then
      begin
        pDe := I;
        Break;
      end;
      Dec(I);
    end;
    if pDe = 0 then Exit;
    AFind := StripOuterQuotes(Trim(Copy(Q, pDe + 4, pPor - (pDe + 4))));
    AReplace := StripOuterQuotes(Trim(Copy(Q, pPor + LenAfterPor, MaxInt)));
    Result := (AFind <> '') and (AReplace <> '');
  end;

begin
  Result := False;
  AFind := '';
  AReplace := '';
  L := LowerCase(AQuestion);
  if (PosBMH('substitu', L) = 0) and (PosBMH('trocar', L) = 0) and (PosBMH('replace', L) = 0) and
     (PosBMH('alterar', L) = 0) and (PosBMH('altere', L) = 0) then
    Exit;
  if ExtractTwoQuotedStrings(AQuestion, AFind, AReplace) then
  begin
    AFind := StripOuterQuotes(AFind);
    AReplace := StripOuterQuotes(AReplace);
    Result := True;
    Exit;
  end;
  pPor := PosBMH(' para ', L);
  LenPor := 6;
  if pPor = 0 then
  begin
    pPor := PosBMH(' por ', L);
    LenPor := 5;
  end;
  if pPor = 0 then
  begin
    pPor := PosBMH(' by ', L);
    LenPor := 4;
  end;
  if pPor = 0 then
  begin
    pPor := PosBMH(' with ', L);
    LenPor := 6;
  end;
  if pPor = 0 then Exit;

  if (PosBMH('alterar', L) > 0) or (PosBMH('ocorr', L) > 0) then
  begin
    if TryDeParaPair(L, AQuestion, pPor, LenPor) then
    begin
      Result := True;
      Exit;
    end;
  end;

  pSub := PosBMH('substituir ', L);
  LenSub := Length('substituir ');
  if pSub = 0 then
  begin
    pSub := PosBMH('trocar ', L);
    LenSub := Length('trocar ');
  end;
  if pSub = 0 then
  begin
    pSub := PosBMH('replace ', L);
    LenSub := Length('replace ');
  end;
  if pSub = 0 then
  begin
    pSub := PosBMH('alterar ', L);
    LenSub := Length('alterar ');
  end;
  if (pSub = 0) or (pSub >= pPor) then
  begin
    if TryDeParaPair(L, AQuestion, pPor, LenPor) then
      Result := True;
    Exit;
  end;
  AFind := StripOuterQuotes(Trim(Copy(AQuestion, pSub + LenSub, pPor - (pSub + LenSub))));
  AReplace := StripOuterQuotes(Trim(Copy(AQuestion, pPor + LenPor, MaxInt)));
  Result := (AFind <> '') and (AReplace <> '');
end;

function UserWantsReplaceAll(const AQuestion: string; out AFind, AReplace: string): Boolean;
begin
  Result := ExtractReplacePairFromText(AQuestion, AFind, AReplace);
end;

function ExtractExportLineRangeParams(const AQuestion: string; out AParams: string): Boolean;
begin
  Result := UserWantsCatalogExportLineRange(AQuestion, AParams);
end;

function UserWantsExportLineRange(const AQuestion: string; out ALineParams: string): Boolean;
begin
  Result := ExtractExportLineRangeParams(AQuestion, ALineParams);
end;

function UserWantsExportToFile(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result := (PosBMH('.txt', L) > 0) or (PosBMH('para um txt', L) > 0) or (PosBMH('para txt', L) > 0) or
    (PosBMH('para um ficheiro', L) > 0) or (PosBMH('para um arquivo', L) > 0) or
    (PosBMH('para ficheiro', L) > 0) or (PosBMH('para arquivo', L) > 0) or
    (PosBMH('to a file', L) > 0) or (PosBMH('to file', L) > 0);
end;

function UserWantsExportLinesContaining(const AQuestion: string; out APattern: string): Boolean;
var
  L: string;
  p: Integer;
begin
  Result := False;
  APattern := '';
  L := LowerCase(AQuestion);
  if (PosBMH('export', L) = 0) and (PosBMH('exportar', L) = 0) then Exit;
  if (PosBMH('tenham', L) = 0) and (PosBMH('tenha', L) = 0) and (PosBMH('conten', L) = 0) and
     (PosBMH('com ', L) = 0) and (PosBMH('matching', L) = 0) and (PosBMH('que tenham', L) = 0) and
     (PosBMH('with ', L) = 0) and (PosBMH('somente', L) = 0) and (PosBMH('apenas', L) = 0) and
     (PosBMH('only', L) = 0) and (PosBMH('filtr', L) = 0) and (PosBMH('palavra', L) = 0) and
     (PosBMH('procur', L) = 0) and (PosBMH('busc', L) = 0) and (PosBMH('localiz', L) = 0) then
    Exit;
  APattern := ExtractSearchTextFromText(AQuestion);
  if APattern = '' then
  begin
    p := PosBMH('tenham ', L);
    if p = 0 then p := PosBMH('tenha ', L);
    if p = 0 then p := PosBMH('contendo ', L);
    if p = 0 then p := PosBMH('com ', L);
    if p > 0 then
      APattern := Trim(Copy(AQuestion, p, MaxInt));
  end;
  Result := Trim(APattern) <> '';
end;

function ExtractPartFraction(const AQuestion: string; out APartNum, ATotalParts: Integer): Boolean;
var
  L: string;
  p, i, j, n1, n2: Integer;
begin
  Result := False;
  APartNum := 0;
  ATotalParts := 0;
  L := LowerCase(AQuestion);
  if (PosBMH('part', L) = 0) and (PosBMH('parte', L) = 0) and (PosBMH('frac', L) = 0) then Exit;
  p := 1;
  while p <= Length(L) do
  begin
    if not (L[p] in ['0'..'9']) then
    begin
      Inc(p);
      Continue;
    end;
    i := p;
    while (i <= Length(L)) and (L[i] in ['0'..'9']) do Inc(i);
    if (i <= Length(L)) and (L[i] = '/') then
    begin
      n1 := StrToIntDef(Copy(L, p, i - p), 0);
      Inc(i);
      j := i;
      while (j <= Length(L)) and (L[j] in ['0'..'9']) do Inc(j);
      n2 := StrToIntDef(Copy(L, i, j - i), 0);
      if (n1 >= 1) and (n2 >= 2) and (n1 <= n2) then
      begin
        APartNum := n1;
        ATotalParts := n2;
        Result := True;
        Exit;
      end;
      p := j;
      Continue;
    end;
    p := i;
  end;
end;

function UserWantsSplitEqualParts(const AQuestion: string; out AParts: Integer): Boolean;
var
  L: string;
begin
  Result := False;
  AParts := 0;
  L := LowerCase(AQuestion);
  if (PosBMH('divid', L) = 0) and (PosBMH('split', L) = 0) and (PosBMH('particion', L) = 0) and
     (PosBMH('separar', L) = 0) and (PosBMH('partes iguais', L) = 0) then
    Exit;
  AParts := ExtractPartsCountFromText(AQuestion);
  Result := AParts >= 2;
end;

function ActionStatusMessage(const AActionId: string): string; forward;

function TryResolveLocalPlan(const UserQ: string; var Plan: TAssistantPlan): Boolean;
var
  L, Path, SearchTxt, FilterPat, ActId, LineParams, FindTxt, ReplTxt: string;
  Parts, LineN: Integer;
  St: TAssistantChainStep;
  Kind: TAssistantIntentKind;
  Hint: string;
begin
  Result := False;
  FillChar(Plan, SizeOf(Plan), 0);
  Plan.Intent := aiUnknown;
  L := LowerCase(Trim(UserQ));
  if L = '' then Exit;

  { Join/merge before intent classifier — "?" + "esse arquivo" must not become RAG. }
  if TryCatalogResolveAction(UserQ, ActId, St) and
     SameText(St.ActionId, 'show_tab_merge_files') then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := St.ActionId;
    Plan.Path := St.Path;
    Plan.Parts := St.Parts;
    Plan.LineNo := St.LineNo;
    Plan.NeedConfirm := True;
    Plan.UserMessage := TrText('Assistant.Local.WillMergeFiles');
    Result := True;
    Exit;
  end;

  { Intent classifier: decide the slot before greedy RAG/open. }
  if ClassifyAssistantIntent(UserQ, GLastComposePath <> '', Kind, Hint) then
  begin
    case Kind of
      aikComposeFix:
        begin
          Plan.Intent := aiExecute;
          Plan.ActionId := 'compose_document';
          Plan.Path := ExtractPathFromUserText(UserQ);
          Plan.NeedConfirm := False;
          Plan.UserMessage := TrText('Assistant.Local.WillFixDocument');
          Result := True;
          Exit;
        end;
      aikCompose:
        begin
          Plan.Intent := aiExecute;
          Plan.ActionId := 'compose_document';
          Plan.Path := ExtractPathFromUserText(UserQ);
          Plan.NeedConfirm := False;
          if UserWantsFileSummaryToDocument(UserQ) then
            Plan.UserMessage := TrText('Assistant.Local.WillComposeFileSummary')
          else
            Plan.UserMessage := TrText('Assistant.Local.WillComposeDocument');
          Result := True;
          Exit;
        end;
      aikConsumerSQL:
        begin
          Plan.Intent := aiExecute;
          Plan.ActionId := 'consumer_ai';
          Plan.Path := ExtractPathFromUserText(UserQ);
          if UserWantsConsumerAIContentQuestion(UserQ) then
            Plan.FilterText := SanitizeQuestionForConsumerPython(UserQ, False);
          Plan.UserMessage := TrText('Assistant.Local.WillShowConsumerAI');
          Result := True;
          Exit;
        end;
      aikConsumerRAG:
        begin
          Plan.Intent := aiExecute;
          Plan.ActionId := 'consumer_rag';
          Plan.Path := ExtractPathFromUserText(UserQ);
          if UserWantsConsumerRAGContentQuestion(UserQ) then
            Plan.FilterText := SanitizeQuestionForConsumerPython(UserQ, True);
          Plan.UserMessage := TrText('Assistant.Local.WillShowConsumerRAG');
          Result := True;
          Exit;
        end;
      aikNativeTool:
        { fall through — detectors + improved capability map score };
    end;
  end;

  if UserWantsShowScriptEngine(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'show_script_engine';
    Plan.Path := ExtractPathFromUserText(UserQ);
    Plan.UserMessage := TrText('Assistant.Local.WillShowScriptEngine');
    Result := True;
    Exit;
  end;

  if UserWantsShowTailMacro(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'show_tail_macro';
    Plan.Path := ExtractPathFromUserText(UserQ);
    Plan.UserMessage := TrText('Assistant.Local.WillShowTailMacro');
    Result := True;
    Exit;
  end;

  if UserWantsComposeDocument(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'compose_document';
    Plan.Path := ExtractPathFromUserText(UserQ);
    Plan.NeedConfirm := False;
    Plan.UserMessage := TrText('Assistant.Local.WillComposeDocument');
    Result := True;
    Exit;
  end;

  if UserWantsShowConsumerRAG(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'consumer_rag';
    Plan.Path := ExtractPathFromUserText(UserQ);
    if UserWantsConsumerRAGContentQuestion(UserQ) then
      Plan.FilterText := SanitizeQuestionForConsumerPython(UserQ, True);
    Plan.UserMessage := TrText('Assistant.Local.WillShowConsumerRAG');
    Result := True;
    Exit;
  end;

  if UserWantsShowConsumerAI(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'consumer_ai';
    Plan.Path := ExtractPathFromUserText(UserQ);
    if UserWantsConsumerAIContentQuestion(UserQ) then
      Plan.FilterText := SanitizeQuestionForConsumerPython(UserQ, False);
    Plan.UserMessage := TrText('Assistant.Local.WillShowConsumerAI');
    Result := True;
    Exit;
  end;

  if UserWantsReplaceAll(UserQ, FindTxt, ReplTxt) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'replace_all';
    Plan.FilterText := FindTxt;
    Plan.ReplaceText := ReplTxt;
    Plan.CaseSensitive := UserRequestedCaseSensitive(UserQ);
    Plan.NeedConfirm := True;
    Plan.UserMessage := TrText('Assistant.Local.WillReplaceAll');
    Result := True;
    Exit;
  end;

  if UserWantsExportLineRange(UserQ, LineParams) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'export_lines';
    Plan.FilterText := LineParams;
    Plan.Path := ExtractPathFromUserText(UserQ);
    Plan.UserMessage := TrText('Assistant.Local.WillExportLines');
    Result := True;
    Exit;
  end;

  if UserWantsExportLinesContaining(UserQ, FilterPat) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'export_matching_lines';
    Plan.FilterText := NormalizeAssistantFilterNeedle(UserQ, FilterPat);
    Plan.CaseSensitive := UserRequestedCaseSensitive(UserQ);
    Plan.UserMessage := TrText('Assistant.Local.WillExportMatching');
    Result := True;
    Exit;
  end;

  if UserWantsSplitEqualParts(UserQ, Parts) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'split_equal_parts';
    Plan.Parts := Parts;
    Plan.Path := ExtractPathFromUserText(UserQ);
    if Plan.Path = '' then
      Plan.Path := AssistantHostGetOpenFilePath;
    Plan.NeedConfirm := True;
    Plan.UserMessage := TrText('Assistant.Local.WillSplitEqual');
    Result := True;
    Exit;
  end;

  if ExtractPartFraction(UserQ, Parts, LineN) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'extract_file_parts';
    Plan.TotalParts := Parts;
    Plan.PartFrom := LineN;
    Plan.PartTo := LineN;
    Plan.Path := ExtractPathFromUserText(UserQ);
    if Plan.Path = '' then
      Plan.Path := AssistantHostGetOpenFilePath;
    Plan.NeedConfirm := True;
    Plan.UserMessage := TrText('Assistant.Local.WillExtractPart');
    Result := True;
    Exit;
  end;

  if TryCatalogResolveAction(UserQ, ActId, St) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := St.ActionId;
    Plan.Path := St.Path;
    Plan.Parts := St.Parts;
    Plan.TotalParts := St.TotalParts;
    Plan.PartFrom := St.PartFrom;
    Plan.PartTo := St.PartTo;
    Plan.FilterText := St.FilterText;
    Plan.ReplaceText := St.ReplaceText;
    Plan.LineNo := St.LineNo;
    Plan.CaseSensitive := St.CaseSensitive;
    Plan.ByteOffset := St.ByteOffset;
    Plan.UserMessage := ActionStatusMessage(St.ActionId);
    Result := True;
    Exit;
  end;

  if UserWantsFindText(UserQ, SearchTxt) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'find_text';
    Plan.FilterText := SearchTxt;
    Plan.CaseSensitive := UserRequestedCaseSensitive(UserQ);
    Plan.UserMessage := TrText('Assistant.Local.WillFindText');
    Result := True;
    Exit;
  end;

  if UserWantsGotoLine(UserQ, LineN) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'goto_line';
    Plan.LineNo := LineN;
    Plan.UserMessage := TrText('Assistant.Local.WillGotoLine');
    Result := True;
    Exit;
  end;

  if UserWantsEditLine(UserQ, LineN) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'edit_line';
    Plan.LineNo := LineN;
    Plan.UserMessage := TrText('Assistant.Local.WillEditLine');
    Result := True;
    Exit;
  end;

  if UserWantsClearFilter(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'clear_filter';
    Plan.UserMessage := TrText('Assistant.Status.FilterCleared');
    Result := True;
    Exit;
  end;

  if UserWantsContinueFilter(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'continue_filter';
    Plan.UserMessage := TrText('Assistant.Status.FilterContinued');
    Result := True;
    Exit;
  end;

  if UserWantsCopyFiltered(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'copy_filtered';
    Plan.UserMessage := TrText('Assistant.Status.FilterCopied');
    Result := True;
    Exit;
  end;

  if UserAsksAboutActiveFilter(UserQ) then
  begin
    Plan.Intent := aiExplain;
    Plan.ActionId := '';
    Plan.UserMessage := FormatActiveFilterStatusMessage;
    Result := True;
    Exit;
  end;

  if UserWantsOpenFilterBar(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'open_filter';
    Plan.UserMessage := TrText('Assistant.Status.FilterDialog');
    Result := True;
    Exit;
  end;

  if UserWantsApplyFilter(UserQ, FilterPat) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'apply_filter';
    Plan.FilterText := FilterPat;
    Plan.UserMessage := TrText('Assistant.Local.WillApplyFilter');
    Result := True;
    Exit;
  end;

  if UserWantsStartTail(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'start_tail';
    Plan.UserMessage := TrText('Assistant.Status.Tail');
    Result := True;
    Exit;
  end;

  if UserWantsExport(UserQ) then
  begin
    Plan.Intent := aiExecute;
    if UserWantsExportLineRange(UserQ, LineParams) then
    begin
      Plan.ActionId := 'export_lines';
      Plan.FilterText := LineParams;
      Plan.Path := ExtractPathFromUserText(UserQ);
      Plan.UserMessage := TrText('Assistant.Local.WillExportLines');
    end
    else if UserWantsExportLinesContaining(UserQ, FilterPat) then
    begin
      Plan.ActionId := 'export_matching_lines';
      Plan.FilterText := NormalizeAssistantFilterNeedle(UserQ, FilterPat);
      Plan.CaseSensitive := UserRequestedCaseSensitive(UserQ);
      Plan.UserMessage := TrText('Assistant.Local.WillExportMatching');
    end
    else if (PosBMH('filtr', L) > 0) or (PosBMH('filter', L) > 0) or (PosBMH('tail', L) > 0) then
    begin
      Plan.ActionId := 'export_filtered';
      Plan.UserMessage := TrText('Assistant.Status.ExportFiltered');
    end
    else
    begin
      Plan.ActionId := 'export_file';
      Plan.UserMessage := TrText('Assistant.Status.Export');
    end;
    Result := True;
    Exit;
  end;

  Path := ExtractPathFromUserText(UserQ);
  Parts := ExtractPartsCountFromText(UserQ);

  if (Path <> '') and UserWantsOpenAndRead(UserQ) and (Parts >= 2) and
     ((PosBMH('depois', L) > 0) or (PosBMH('entao', L) > 0) or
      (PosBMH('e depois', L) > 0) or (PosBMH('then', L) > 0) or (PosBMH('divid', L) > 0) or
      (PosBMH('split', L) > 0) or (PosBMH('part', L) > 0)) then
  begin
    Plan.Intent := aiExecute;
    Plan.ChainCount := 2;
    Plan.Chain[0].ActionId := 'open_and_read_file';
    Plan.Chain[0].Path := Path;
    Plan.Chain[1].ActionId := 'split_equal_parts';
    Plan.Chain[1].Path := Path;
    Plan.Chain[1].Parts := Parts;
    PlanFromFirstChainItem(Plan);
    Plan.NeedConfirm := True;
    Plan.UserMessage := TrText('Assistant.Local.ChainReadSplit');
    Result := True;
    Exit;
  end;

  if (Path <> '') and UserWantsOpenAndRead(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'open_and_read_file';
    Plan.Path := Path;
    Plan.NeedConfirm := True;
    Plan.UserMessage := TrText('Assistant.Local.WillReadFile');
    Result := True;
    Exit;
  end;

  if UserWantsShowTabRead(UserQ) then
  begin
    Plan.Intent := aiExecute;
    Plan.ActionId := 'show_tab_read';
    Plan.NeedConfirm := False;
    Plan.UserMessage := TrText('Assistant.Local.WillShowReadTab');
    Result := True;
    Exit;
  end;
end;

procedure ApplyConsumerGate(const UserQ: string; var Plan: TAssistantPlan);
begin
  { Structural only: never reclassify NL. Python chats always need confirm. }
  if Plan.Intent <> aiExecute then Exit;
  if SameText(Plan.ActionId, 'consumer_rag') or SameText(Plan.ActionId, 'consumer_ai') then
  begin
    if not CatalogIsAllowedActionId(Plan.ActionId) then
    begin
      Plan.Intent := aiExplain;
      Plan.ActionId := '';
      Plan.NeedConfirm := False;
      if Trim(Plan.UserMessage) = '' then
        Plan.UserMessage := TrText('Assistant.ConsumerGate.Blocked');
      Exit;
    end;
    Plan.NeedConfirm := True;
  end;
end;

function QuestionSignalsSavedRichDocument(const AQuestion: string): Boolean;
begin
  Result := LooksLikeRichDocFormatAsk(AQuestion);
end;

function PlanSignalsComposeDocument(const Plan: TAssistantPlan): Boolean;
var
  i: Integer;
begin
  Result := SameText(Plan.ActionId, 'compose_document');
  if Result then Exit;
  for i := 0 to Plan.ChainCount - 1 do
    if SameText(Plan.Chain[i].ActionId, 'compose_document') then
    begin
      Result := True;
      Exit;
    end;
end;

function IsNativeFirstHopAction(const AId: string): Boolean;
begin
  Result := SameText(AId, 'apply_filter') or SameText(AId, 'split_equal_parts') or
    SameText(AId, 'find_text') or SameText(AId, 'show_tab_merge_files') or
    SameText(AId, 'count_line_prefixes') or SameText(AId, 'count_matching_lines') or
    SameText(AId, 'export_lines') or SameText(AId, 'export_matching_lines');
end;

procedure CaptureNativeFollowUpFromAi(var Plan: TAssistantPlan; const UserQ: string);
var
  i: Integer;
  Id, Primary, Id0, Follow: string;
  WantSavedDoc: Boolean;
begin
  { AI-first: trust the model's chain for hop-2. Host only:
    - flattens [native, …] so auto-exec can run hop-1
    - if hop-2 is still empty and the question has a format id (pdf/docx/…),
      set compose_document (structural param — not NL verb routing)
    Never override an explicit AI consumer_rag with compose. }
  WantSavedDoc := QuestionSignalsSavedRichDocument(UserQ);
  for i := 0 to Plan.ChainCount - 1 do
  begin
    Id := Trim(Plan.Chain[i].ActionId);
    if SameText(Id, 'count_matching_lines') and (Trim(Plan.Chain[i].FilterText) <> '') then
      Plan.AlsoCountMatching := MergePipeNeedles(Plan.AlsoCountMatching,
        Plan.Chain[i].FilterText)
    else if SameText(Id, 'count_line_prefixes') and (Trim(Plan.Chain[i].FilterText) <> '') then
      Plan.AlsoCountPrefixes := MergePipeNeedles(Plan.AlsoCountPrefixes,
        Plan.Chain[i].FilterText);
  end;

  if Trim(Plan.NativeFollowUpAction) = '' then
  begin
    Primary := Trim(Plan.ActionId);
    Follow := '';
    for i := 0 to Plan.ChainCount - 1 do
    begin
      Id := Trim(Plan.Chain[i].ActionId);
      if Id = '' then Continue;
      if SameText(Id, Primary) then Continue;
      { Prefer compose if the AI put it anywhere in the chain. }
      if SameText(Id, 'compose_document') then
      begin
        Follow := Id;
        Break;
      end;
      if SameText(Id, 'consumer_rag') and (Follow = '') then
        Follow := Id;
    end;
    Plan.NativeFollowUpAction := Follow;
  end;

  { Flatten multi-step native chains so ShouldAutoExecute can run hop-1. }
  if Plan.ChainCount >= 2 then
  begin
    Id0 := Trim(Plan.Chain[0].ActionId);
    if IsNativeFirstHopAction(Id0) then
    begin
      Follow := Trim(Plan.NativeFollowUpAction);
      if Follow = '' then
        for i := 1 to Plan.ChainCount - 1 do
        begin
          Id := Trim(Plan.Chain[i].ActionId);
          if SameText(Id, 'compose_document') then
          begin
            Follow := Id;
            Break;
          end;
          if SameText(Id, 'consumer_rag') and (Follow = '') then
            Follow := Id;
        end;
      { Keep AI max_lines from the compose step if present. }
      for i := 1 to Plan.ChainCount - 1 do
        if SameText(Trim(Plan.Chain[i].ActionId), 'compose_document') and
           (Plan.Chain[i].MaxLines > 0) then
        begin
          Plan.MaxLines := Plan.Chain[i].MaxLines;
          Break;
        end;
      PlanFromFirstChainItem(Plan);
      Plan.ActionId := Id0;
      if SameText(Follow, 'compose_document') and SameText(Id0, 'count_line_prefixes') then
      begin
        Plan.ComposeAfterCount := True;
        Plan.NativeFollowUpAction := '';
      end
      else
        Plan.NativeFollowUpAction := Follow;
      Plan.ChainCount := 0;
    end;
  end;

  { Structural format id only when the AI left hop-2 empty. }
  if (Trim(Plan.NativeFollowUpAction) = '') and IsNativeFirstHopAction(Plan.ActionId) and
     WantSavedDoc then
  begin
    if SameText(Plan.ActionId, 'count_line_prefixes') or
       SameText(Plan.ActionId, 'count_matching_lines') then
    begin
      Plan.ComposeAfterCount := True;
      Plan.NativeFollowUpAction := '';
    end
    else
      Plan.NativeFollowUpAction := 'compose_document';
  end;

  { count + PDF: PDF comes from ExecMsg, not sample compose. }
  if SameText(Plan.ActionId, 'count_line_prefixes') and
     (Plan.ComposeAfterCount or WantSavedDoc) then
    Plan.NativeFollowUpAction := '';
end;

procedure ApplyLocalIntentCorrection(const UserQ: string; var Plan: TAssistantPlan);
var
  Path, Joined, AiAction, Quoted: string;
  RecentIdx, i: Integer;
  Prefs: TStringDynArray;
  St: TAssistantChainStep;
  WantDocAfterCount, AiTrusted: Boolean;
  List: TStringList;
begin
  { AI-first: the model chooses the tool. Delphi only:
    - fills structural params (path, digit prefixes, quoted/backtick needles, line ranges)
    - redirects clearly wrong host picks (consumer_* / empty) when structure is unambiguous
    - never re-routes via NL verb dictionaries (LooksLike*/UserWantsApplyFilter/…). }

  AiAction := Trim(Plan.ActionId);
  AiTrusted := (AiAction <> '') and CatalogIsAllowedActionId(AiAction);
  CaptureNativeFollowUpFromAi(Plan, UserQ);

  { AI returned a valid tool id but marked intent=explain (describes the plan in prose).
    Trust the action id — do not invent a tool from PT/ES verb lists. }
  if (Plan.Intent <> aiExecute) and AiTrusted then
  begin
    Plan.Intent := aiExecute;
    Plan.NeedConfirm := False;
  end;

  { --- Structural prefix counts (digit runs) --- }
  if TryParseLinePrefixCountAsk(UserQ, Prefs) then
  begin
    WantDocAfterCount := Plan.ComposeAfterCount or PlanSignalsComposeDocument(Plan) or
      QuestionSignalsSavedRichDocument(UserQ) or
      SameText(Plan.NativeFollowUpAction, 'compose_document');
    Joined := '';
    for i := 0 to High(Prefs) do
    begin
      if Joined <> '' then
        Joined := Joined + '|';
      Joined := Joined + Prefs[i];
    end;
    if SameText(AiAction, 'count_line_prefixes') then
    begin
      Plan.FilterText := Joined;
      Plan.ComposeAfterCount := WantDocAfterCount;
    end
    else if (not AiTrusted) or
            SameText(AiAction, 'consumer_ai') or
            SameText(AiAction, 'consumer_rag') or
            SameText(AiAction, 'open_and_read_file') then
    begin
      { Local count is authoritative for startswith prefixes. Never steal compose/filter. }
      Plan.Intent := aiExecute;
      Plan.ActionId := 'count_line_prefixes';
      Plan.ChainCount := 0;
      Plan.NeedConfirm := False;
      Plan.ComposeAfterCount := WantDocAfterCount;
      if WantDocAfterCount then
        Plan.NativeFollowUpAction := 'compose_document'
      else
        Plan.NativeFollowUpAction := '';
      Plan.FilterText := Joined;
    end;
    { else: AI chose compose/filter/find/… — do not steal. }
    if SameText(Plan.ActionId, 'count_matching_lines') then
      Plan.AlsoCountPrefixes := MergePipeNeedles(Plan.AlsoCountPrefixes, Joined);
  end;

  if SameText(Plan.ActionId, 'count_line_prefixes') and (Trim(Plan.FilterText) = '') then
  begin
    if CollectDigitRunNeedles(UserQ, Prefs) then
    begin
      Joined := '';
      for i := 0 to High(Prefs) do
      begin
        if Joined <> '' then
          Joined := Joined + '|';
        Joined := Joined + Prefs[i];
      end;
      Plan.FilterText := Joined;
    end;
  end;

  if SameText(Plan.ActionId, 'count_line_prefixes') and (Trim(Plan.FilterText) <> '') then
  begin
    Joined := '';
    Quoted := '';
    List := TStringList.Create;
    try
      List.StrictDelimiter := True;
      List.Delimiter := '|';
      List.DelimitedText := StringReplace(Trim(Plan.FilterText), ',', '|', [rfReplaceAll]);
      for i := 0 to List.Count - 1 do
      begin
        Quoted := Trim(List[i]);
        if Quoted = '' then Continue;
        if (Length(Quoted) >= 2) and CharInSet(Quoted[1], ['0'..'9']) then
        begin
          if Joined <> '' then Joined := Joined + '|';
          Joined := Joined + Quoted;
        end
        else
          Plan.AlsoCountMatching := MergePipeNeedles(Plan.AlsoCountMatching, Quoted);
      end;
    finally
      List.Free;
    end;
    if Joined <> '' then
      Plan.FilterText := Joined;
  end;

  { --- count_matching_lines: AI chose the tool; host only fills structural gaps --- }
  if SameText(Plan.ActionId, 'count_matching_lines') then
  begin
    Plan.Intent := aiExecute;
    Plan.NeedConfirm := False;
    WantDocAfterCount := Plan.ComposeAfterCount or PlanSignalsComposeDocument(Plan) or
      QuestionSignalsSavedRichDocument(UserQ) or
      SameText(Plan.NativeFollowUpAction, 'compose_document');
    Plan.ComposeAfterCount := WantDocAfterCount;
    if Trim(Plan.FilterText) = '' then
    begin
      Quoted := ExtractQuotedNeedlesFromText(UserQ);
      if Quoted = '' then
        Quoted := ExtractPartialMarkerNeedles(UserQ);
      if Quoted = '' then
      begin
        if CollectDigitRunNeedles(UserQ, Prefs) then
        begin
          for i := 0 to High(Prefs) do
          begin
            if Quoted <> '' then
              Quoted := Quoted + '|';
            Quoted := Quoted + Prefs[i];
          end;
        end;
      end;
      if Quoted <> '' then
        Plan.FilterText := Quoted;
    end;
  end;

  { Structural extra needles (quotes / token before (parcial)) — do not steal ActionId. }
  Quoted := MergePipeNeedles(ExtractQuotedNeedlesFromText(UserQ),
    ExtractPartialMarkerNeedles(UserQ));
  Quoted := SubtractPipeNeedles(Quoted, Plan.FilterText);
  Quoted := SubtractPipeNeedles(Quoted, Plan.AlsoCountPrefixes);
  if Quoted <> '' then
    Plan.AlsoCountMatching := MergePipeNeedles(Plan.AlsoCountMatching, Quoted);

  { --- Param enrich only (never changes a trusted AI ActionId via Resolve) --- }
  if CatalogIsAllowedActionId(Plan.ActionId) then
  begin
    FillChar(St, SizeOf(St), 0);
    St.ActionId := Plan.ActionId;
    St.Path := Plan.Path;
    St.Parts := Plan.Parts;
    St.TotalParts := Plan.TotalParts;
    St.PartFrom := Plan.PartFrom;
    St.PartTo := Plan.PartTo;
    St.FilterText := Plan.FilterText;
    St.ReplaceText := Plan.ReplaceText;
    St.LineNo := Plan.LineNo;
    St.CaseSensitive := Plan.CaseSensitive;
    St.ByteOffset := Plan.ByteOffset;
    if TryCatalogEnrichActionParams(UserQ, Plan.ActionId, St) then
    begin
      if Trim(Plan.Path) = '' then
        Plan.Path := St.Path;
      if Trim(Plan.FilterText) = '' then
        Plan.FilterText := St.FilterText;
      if Plan.Parts < 2 then
        Plan.Parts := St.Parts;
      if Plan.TotalParts < 1 then
        Plan.TotalParts := St.TotalParts;
      if Plan.PartFrom < 1 then
        Plan.PartFrom := St.PartFrom;
      if Plan.PartTo < 1 then
        Plan.PartTo := St.PartTo;
      if Plan.LineNo <= 0 then
        Plan.LineNo := St.LineNo;
      if Plan.ByteOffset <= 0 then
        Plan.ByteOffset := St.ByteOffset;
      if Plan.MaxLines < 1 then
        Plan.MaxLines := St.MaxLines;
      Plan.CaseSensitive := St.CaseSensitive;
    end;
  end;

  if Plan.MaxLines < 1 then
    Plan.MaxLines := ExtractMaxRecordsFromText(UserQ);

  if Trim(Plan.FilterText) = '' then
    if SameText(Plan.ActionId, 'apply_filter') or
       SameText(Plan.ActionId, 'compose_document') or
       SameText(Plan.ActionId, 'export_matching_lines') or
       SameText(Plan.ActionId, 'find_text') or
       SameText(Plan.NativeFollowUpAction, 'compose_document') then
    begin
      Quoted := ExtractQuotedNeedlesFromText(UserQ);
      { Digit codes are needles only when this is NOT a startswith-prefix count
        (those digits belong to count_line_prefixes, not compose filter). }
      if (Quoted = '') and (not TryParseLinePrefixCountAsk(UserQ, Prefs)) then
      begin
        if CollectDigitRunNeedles(UserQ, Prefs) then
        begin
          Quoted := '';
          for i := 0 to High(Prefs) do
          begin
            if Quoted <> '' then
              Quoted := Quoted + '|';
            Quoted := Quoted + Prefs[i];
          end;
        end;
      end;
      if Quoted <> '' then
        Plan.FilterText := Quoted;
    end;

  { --- Soft redirect: empty/wrong consumer + structural format id → compose --- }
  if QuestionSignalsSavedRichDocument(UserQ) and
     (not SameText(Plan.ActionId, 'count_line_prefixes')) and
     (not SameText(Plan.ActionId, 'count_matching_lines')) and
     (not IsNativeFirstHopAction(Plan.ActionId)) then
  begin
    if (not AiTrusted) or SameText(Plan.ActionId, 'consumer_ai') or
       SameText(Plan.ActionId, 'consumer_rag') or (Trim(Plan.ActionId) = '') then
    begin
      Plan.Intent := aiExecute;
      Plan.ActionId := 'compose_document';
      Plan.ChainCount := 0;
      Plan.NeedConfirm := False;
      if Trim(Plan.UserMessage) = '' then
        Plan.UserMessage := TrText('Assistant.Local.WillComposeFileSummary');
    end;
  end;

  if (Trim(Plan.FilterText) = '') and SameText(Plan.ActionId, 'compose_document') then
  begin
    Quoted := ExtractQuotedNeedlesFromText(UserQ);
    if (Quoted = '') and (not TryParseLinePrefixCountAsk(UserQ, Prefs)) then
    begin
      if CollectDigitRunNeedles(UserQ, Prefs) then
      begin
        for i := 0 to High(Prefs) do
        begin
          if Quoted <> '' then
            Quoted := Quoted + '|';
          Quoted := Quoted + Prefs[i];
        end;
      end;
    end;
    if Quoted <> '' then
      Plan.FilterText := Quoted;
  end;
  { No LooksLike*/UserWantsApplyFilter ActionId overrides after AI. }

  RecentIdx := ExtractRecentListIndexFromText(UserQ);
  if SameText(Plan.ActionId, 'open_recent_file') and (Plan.LineNo = 0) and
     (RecentIdx <> 0) then
    Plan.LineNo := RecentIdx;

  Path := ExtractPathFromUserText(UserQ);
  if Path = '' then
    Path := AssistantHostGetOpenFilePath;

  if Plan.Intent = aiExecute then
  begin
    if (Trim(Plan.Path) = '') and (Path <> '') then
    begin
      if CatalogIsAllowedActionId(Plan.ActionId) then
        Plan.Path := Path;
    end;

    if SameText(Plan.ActionId, 'consumer_rag') or SameText(Plan.ActionId, 'consumer_ai') then
    begin
      if Trim(Plan.FilterText) = '' then
        Plan.FilterText := Trim(UserQ);
      if SameText(Plan.ActionId, 'consumer_ai') and QuestionSignalsSavedRichDocument(UserQ) then
        Plan.FilterText := StripRichDocAskFromQuestion(Plan.FilterText);
      Plan.NeedConfirm := True;
    end;
    if SameText(Plan.ActionId, 'count_line_prefixes') and
       TryParseLinePrefixCountAsk(UserQ, Prefs) then
    begin
      Joined := '';
      for i := 0 to High(Prefs) do
      begin
        if Joined <> '' then
          Joined := Joined + '|';
        Joined := Joined + Prefs[i];
      end;
      Plan.FilterText := Joined;
      if QuestionSignalsSavedRichDocument(UserQ) or PlanSignalsComposeDocument(Plan) or
         SameText(Plan.NativeFollowUpAction, 'compose_document') then
        Plan.ComposeAfterCount := True;
    end;
    if SameText(Plan.ActionId, 'count_matching_lines') then
    begin
      if Trim(Plan.FilterText) = '' then
      begin
        Quoted := ExtractQuotedNeedlesFromText(UserQ);
        if Quoted = '' then
        begin
          if CollectDigitRunNeedles(UserQ, Prefs) then
          begin
            for i := 0 to High(Prefs) do
            begin
              if Quoted <> '' then
                Quoted := Quoted + '|';
              Quoted := Quoted + Prefs[i];
            end;
          end;
        end;
        if Quoted <> '' then
          Plan.FilterText := Quoted;
      end;
      if QuestionSignalsSavedRichDocument(UserQ) or PlanSignalsComposeDocument(Plan) or
         SameText(Plan.NativeFollowUpAction, 'compose_document') then
        Plan.ComposeAfterCount := True;
    end;
  end;
  SanitizeCountSourcePath(Plan);
end;

function ShouldAutoExecutePlan(const Plan: TAssistantPlan; const UserQ: string): Boolean;
begin
  if Plan.Intent <> aiExecute then
  begin
    Result := False;
    Exit;
  end;
  if Plan.ChainCount > 1 then
  begin
    Result := SameText(Plan.Chain[0].ActionId, 'open_and_read_file') and
      (ExtractPathFromUserText(UserQ) <> '');
    Exit;
  end;
  if SameText(Plan.ActionId, 'open_and_read_file') then
    Result := ExtractPathFromUserText(UserQ) <> ''
  else if SameText(Plan.ActionId, 'open_recent_file') then
    Result := Plan.LineNo <> 0
  else if SameText(Plan.ActionId, 'find_text') then
    Result := Trim(Plan.FilterText) <> ''
  else if SameText(Plan.ActionId, 'goto_line') or SameText(Plan.ActionId, 'edit_line') then
    Result := Plan.LineNo > 0
  else if SameText(Plan.ActionId, 'delete_line') or
          SameText(Plan.ActionId, 'clear_file') or
          SameText(Plan.ActionId, 'delete_duplicate_lines') then
    Result := False
  else if SameText(Plan.ActionId, 'apply_filter') then
    Result := Trim(Plan.FilterText) <> ''
  else if SameText(Plan.ActionId, 'export_lines') then
    Result := Trim(Plan.FilterText) <> ''
  else if SameText(Plan.ActionId, 'export_matching_lines') then
    Result := Trim(Plan.FilterText) <> ''
  else if SameText(Plan.ActionId, 'replace_all') then
    Result := (Trim(Plan.FilterText) <> '') and (Trim(Plan.ReplaceText) <> '')
  else if SameText(Plan.ActionId, 'split_equal_parts') then
    Result := Plan.Parts >= 2
  else if SameText(Plan.ActionId, 'extract_file_parts') then
    Result := (Plan.TotalParts >= 2) and (Plan.PartFrom >= 1) and (Plan.PartFrom <= Plan.TotalParts)
  else if SameText(Plan.ActionId, 'compose_document') then
    Result := False
  else if SameText(Plan.ActionId, 'consumer_rag') then
    Result := False
  else if SameText(Plan.ActionId, 'consumer_ai') then
    Result := (Trim(Plan.FilterText) <> '') or QuestionSignalsSavedRichDocument(UserQ)
  else if SameText(Plan.ActionId, 'count_line_prefixes') or
          SameText(Plan.ActionId, 'count_matching_lines') then
    Result := Trim(Plan.FilterText) <> ''
  else if SameText(Plan.ActionId, 'validate_source') then
    Result := True
  else if SameText(Plan.ActionId, 'paste_lines') or SameText(Plan.ActionId, 'insert_line') or
    SameText(Plan.ActionId, 'duplicate_line') or SameText(Plan.ActionId, 'insert_multiple_lines') then
    Result := False
  else if CatalogIsAllowedActionId(Plan.ActionId) then
    Result := True
  else
    Result := False;
end;

{ High-confidence local plans skip the LLM — only explicit shortcuts / terse labels. }
function LocalPlanIsHighConfidence(const Plan: TAssistantPlan; const UserQ: string): Boolean;
begin
  Result := False;
  if Plan.Intent <> aiExecute then Exit;
  if not CatalogIsAllowedActionId(Plan.ActionId) then Exit;
  { Never skip LLM for Python chats, compose, or dynamic data tools — AI decides those. }
  if SameText(Plan.ActionId, 'consumer_rag') or
     SameText(Plan.ActionId, 'consumer_ai') or
     SameText(Plan.ActionId, 'compose_document') or
     SameText(Plan.ActionId, 'count_line_prefixes') or
     SameText(Plan.ActionId, 'count_matching_lines') then
    Exit;
  Result := UserQuestionIsExplicitLocalShortcut(UserQ);
end;

procedure PlanToChainStep(const APlan: TAssistantPlan; var St: TAssistantChainStep);
begin
  FillChar(St, SizeOf(St), 0);
  St.ActionId := APlan.ActionId;
  St.Path := APlan.Path;
  St.Parts := APlan.Parts;
  St.TotalParts := APlan.TotalParts;
  St.PartFrom := APlan.PartFrom;
  St.PartTo := APlan.PartTo;
  St.FilterText := APlan.FilterText;
  St.ReplaceText := APlan.ReplaceText;
  St.LineNo := APlan.LineNo;
  St.MaxLines := APlan.MaxLines;
  St.CaseSensitive := APlan.CaseSensitive;
  St.ByteOffset := APlan.ByteOffset;
end;

function ActionStatusMessage(const AActionId: string): string;
begin
  if SameText(AActionId, 'open_and_read_file') then Result := TrText('Assistant.Status.OpenStarted')
  else if SameText(AActionId, 'validate_source') then Result := TrText('Assistant.Validate.Running')
  else if SameText(AActionId, 'find_text') then Result := TrText('Assistant.Status.FindStarted')
  else if SameText(AActionId, 'edit_line') then Result := TrText('Assistant.Status.EditLine')
  else if SameText(AActionId, 'delete_line') then Result := TrText('Assistant.Status.DeleteLine')
  else if SameText(AActionId, 'goto_line') then Result := TrText('Assistant.Status.GotoLine')
  else if SameText(AActionId, 'find_next') or SameText(AActionId, 'find_previous') then
    Result := TrText('Assistant.Status.FindStarted')
  else if SameText(AActionId, 'apply_filter') then Result := TrText('Assistant.Status.FilterStarted')
  else if SameText(AActionId, 'clear_filter') then Result := TrText('Assistant.Status.FilterCleared')
  else if SameText(AActionId, 'continue_filter') then Result := TrText('Assistant.Status.FilterContinued')
  else if SameText(AActionId, 'copy_filtered') then Result := TrText('Assistant.Status.FilterCopied')
  else if SameText(AActionId, 'open_filter') then Result := TrText('Assistant.Status.FilterDialog')
  else if SameText(AActionId, 'show_tab_read') then Result := TrText('Assistant.Status.TabRead')
  else if SameText(AActionId, 'show_tab_recent') then Result := TrText('Assistant.Status.TabRecent')
  else if SameText(AActionId, 'show_help') then Result := TrText('Assistant.Status.Help')
  else if SameText(AActionId, 'start_tail') then Result := TrText('Assistant.Status.Tail')
  else if SameText(AActionId, 'export_file') then Result := TrText('Assistant.Status.Export')
  else if SameText(AActionId, 'export_lines') then Result := TrText('Assistant.Status.ExportLines')
  else if SameText(AActionId, 'export_matching_lines') then Result := TrText('Assistant.Status.ExportMatching')
  else if SameText(AActionId, 'show_script_engine') then Result := TrText('Assistant.Local.WillShowScriptEngine')
  else if SameText(AActionId, 'show_tail_macro') then Result := TrText('Assistant.Local.WillShowTailMacro')
  else if SameText(AActionId, 'consumer_ai') then Result := TrText('Assistant.Local.WillShowConsumerAI')
  else if SameText(AActionId, 'consumer_rag') then Result := TrText('Assistant.Local.WillShowConsumerRAG')
  else if SameText(AActionId, 'compose_document') then Result := TrText('Assistant.Local.WillComposeDocument')
  else if SameText(AActionId, 'replace_all') then Result := TrText('Assistant.Status.ReplaceAll')
  else if SameText(AActionId, 'split_equal_parts') then Result := TrText('Assistant.Status.SplitStarted')
  else Result := TrText('Assistant.Done');
end;

function BuildOperationalKnowledgeBase: string;
begin
  Result :=
    'FASTFILE OPERATIONAL KNOWLEDGE (user help only — no source code):' + #13#10 +
    'FastFile is a large text file viewer/editor (GB+). Main areas:' + #13#10 +
    '- File menu: open file (Ctrl+O), recent (Ctrl+R), exit.' + #13#10 +
    '- Read tab: file path field + Read/Load (F5) loads the file into the list.' + #13#10 +
    '- Tools menu: Filter/analysis (find, filter, extract frequent strings, delete duplicate lines),' + #13#10 +
    '  Split/merge, Line operations, Tail/follow, Automation (script macro), Export/clear.' + #13#10 +
    '- View menu: word wrap, select/checkboxes, zoom, bookmarks, encoding, Zero Scan for huge files.' + #13#10 +
    '- Session menu: read-only session, save/load session.' + #13#10 +
    '- Options menu: segmented heavy-ops policy (Replace All / batch delete on huge files).' + #13#10 +
    '- Edit: find Ctrl+F, replace Ctrl+H, undo Ctrl+Z, redo Ctrl+Y.' + #13#10 +
    '- Split equal parts: Ctrl+Shift+P or Tools > Split/merge (LF-safe line boundaries).' + #13#10 +
    '- Extract file parts subset: Ctrl+Shift+Q.' + #13#10 +
    '- Compare/merge tab: Ctrl+Shift+H.' + #13#10 +
    '- Help F1: shortcuts reference.' + #13#10 +
    '- Tabular SQL and advanced file-content questions are delegated to Python (ConsumerAI / ConsumerRAG); answers stay in this Assistant chat.' + #13#10 +
    #13#10 +
    'ALLOWED execute action ids (use exactly these ids):' + #13#10 +
    'open_and_read_file — params: path (full Windows path). Opens Read tab and loads file (F5).' + #13#10 +
    'open_recent_file — params: recent_index (1-based row on Recent Files tab grid; use CURRENT_CONTEXT recent_N). Opens and loads that file.' + #13#10 +
    'show_tab_read — Open Read / load file screen (no file read).' + #13#10 +
    'show_tab_recent — Open Recent Files welcome tab.' + #13#10 +
    'show_help — Open F1 help dialog.' + #13#10 +
    'open_find — Open Find dialog only (Ctrl+F); prefer find_text when user gives search text.' + #13#10 +
    'find_text — params: search_text or filter_text, case_sensitive (default false). Runs Ctrl+F search, first match highlighted in ListView.' + #13#10 +
    'edit_line — params: line_no (1-based). Goes to line and opens line editor (like double-click).' + #13#10 +
    'split_equal_parts — params: path (optional if a file is open in edtFileName), parts (integer 2..1000 or words: duas/two/dos/deux/zwei/due/...). LF-safe split.' + #13#10 +
    'extract_file_parts — params: path, total_parts, part_from, part_to (subset of equal LF parts).' + #13#10 +
    'open_replace — Open Find & Replace dialog (Ctrl+H); prefer replace_all when user gives find+replace text.' + #13#10 +
    'replace_all — params: search_text/filter_text, replace_text, case_sensitive (default false). Streaming replace all in file (Ctrl+H Replace All).' + #13#10 +
    'start_tail — Enable Tail/Follow mode (Ctrl+T).' + #13#10 +
    'show_tab_compare — Open Compare/merge + history tab (Ctrl+Shift+H).' + #13#10 +
    'open_filter — Open Filter/Grep bar/dialog (Ctrl+L). Use when user asks to open/show the filter UI.' + #13#10 +
    'apply_filter — params: filter_text (required). Starts filter on open file.' + #13#10 +
    'continue_filter — Continue loading more hits when CURRENT_CONTEXT has filter_partial=1.' + #13#10 +
    'copy_filtered — Copy current filter hits to clipboard (active filter required).' + #13#10 +
    'count_line_prefixes — params: filter_text = prefixes separated by | (e.g. "ABC|XYZ"), ' +
    'path optional. Counts how many lines START WITH each prefix (one local scan — no SQL/Lambda). ' +
    'Use for ANY dynamic startswith/prefix-count question in ANY language; put the user''s real prefixes in filter_text. ' +
    'If user also asked PDF/Word, FastFile saves the count result after this action.' + #13#10 +
    'count_matching_lines — params: filter_text = substring needle(s) separated by | (e.g. "Bianca"), ' +
    'path optional. Counts how many lines CONTAIN each needle (case-insensitive substring / partial match; ' +
    'one local scan — no SQL/Lambda). Use for ANY language when the user wants a line count by contains/' +
    'partial text (not startswith, not column SQL). Put the real search term(s) in filter_text — ' +
    'not the full NL question. Prefer this over consumer_ai for simple contains counts. ' +
    'If user also asked PDF/Word, FastFile saves the count result after this action.' + #13#10 +
    'clear_filter — Clear active line filter.' + #13#10 +
    'export_file — Export dialog (Ctrl+Shift+O).' + #13#10 +
    'export_lines — params: line_range in filter_text (e.g. "3-10" or "3,5,9"), path optional.' + #13#10 +
    '  If the user names a file and asks to generate/create/export a NEW file with lines N to M (inclusive),' + #13#10 +
    '  use export_lines (filter_text=N-M, params.path=that file). Do NOT use goto_line.' + #13#10 +
    'export_matching_lines — params: filter_text (substring). Applies filter then exports matching lines to a .txt file when filter completes (never clipboard).' + #13#10 +
    'export_filtered — Export current filter/tail hits (Ctrl+Shift+L). Prefer when filter_active=1.' + #13#10 +
    'delete_duplicate_lines — Tools > Delete duplicate lines (needs writable file).' + #13#10 +
    'extract_frequent_strings — Tools > Extract frequent strings (needs open file).' + #13#10 +
    'show_checkboxes — Checkbox selection list (Ctrl+Shift+S).' + #13#10 +
    'goto_line — params: line_no (1-based); 0 opens goto dialog (Ctrl+G).' + #13#10 +
    'character_code_value — View > Character code value for current line.' + #13#10 +
    'show_tab_merge_lines — Merge lines tab (Ctrl+Shift+M).' + #13#10 +
    'show_tab_merge_files — Merge files tab (Ctrl+Shift+J). Pass params.path for destination ' +
    '(or base name of .part001/.part002 files). Optional: beginning / after line N / end.' + #13#10 +
    'toggle_word_wrap — Toggle word wrap (Ctrl+W).' + #13#10 +
    'show_script_engine — Open Macros with Python / Script Engine panel (Ctrl+Alt+E). Optional params.path to load that file first.' + #13#10 +
    'show_tail_macro — Tail macro (Python) panel for follow mode. Optional params.path.' + #13#10 +
    'consumer_ai — Delegate tabular/SQL questions to ConsumerAI/DuckDB Python. ' +
    'Do NOT open a second chat UI; answers return in this Assistant panel. ' +
    'Use for complex tabular/SQL (distinct, sum, avg, columns, WHERE, group by). ' +
    'NOT for simple line startswith/prefix counts (use count_line_prefixes). ' +
    'NOT for simple line contains/partial substring counts (use count_matching_lines). ' +
    'Optional params.path; filter_text = original question forwarded at Question:.' + #13#10 +
    'consumer_rag — Delegate file-meaning/content questions to ConsumerRAG Python. ' +
    'Do NOT open a second chat UI; answers return in this Assistant panel. ' +
    'Use for ANY natural-language question about file meaning/content. ' +
    'Optional params.path; filter_text = original question forwarded at Question>.' + #13#10 +
    'compose_document — Generate a standalone document or source file ' +
    '(.txt, .md, .pas, .py, .js, .ts, .go, .java, .cpp, .rtf, .docx, .odt, .pdf, README). ' +
    'Format id TXT/txt/.txt MUST be a .txt file — never default to .md. ' +
    'FastFile writes the file; do NOT put the body in user_message. ' +
    'Optional params: filter_text (needle for lines to append), max_lines (cap, e.g. 100).' + #13#10 +
    'validate_source — Syntax-check a source file (does NOT run it). ' +
    'Supported ONLY: Python (.py), JavaScript (.js/.mjs/.cjs), JSX (.jsx), ' +
    'TypeScript (.ts), TSX/React (.tsx). params.path optional (full Windows path); ' +
    'if missing, FastFile may use last composed file or ask the user to pick one. ' +
    'If user asks which languages are validated: intent=explain and list those ' +
    'extensions in user_message (do not invent others).' + #13#10 +
    #13#10 +
    BuildAssistantZsAtalhosCatalogKB + #13#10 +
    'Chains: use "actions":[{...},{...}] for sequential steps (e.g. open_and_read_file then apply_filter).' + #13#10 +
    'Compound native + explain/PDF: put the native tool FIRST, then compose_document or consumer_rag ' +
    'in "actions" (e.g. [apply_filter, consumer_rag] or [find_text, compose_document]). ' +
    'FastFile runs hop-1 then the follow-up. Prefer format ids (.pdf/.docx/.txt/…) when a saved file is wanted.' + #13#10 +
    'NEVER use intent=explain when the user asked FastFile to DO something (filter/split/find/count/merge). ' +
    'Describing the plan in user_message without action/actions is WRONG — return intent=execute.' + #13#10 +
    'For filter+meaning (any language): actions:[{apply_filter, filter_text=<exact needle>}, {consumer_rag}]. ' +
    'Put the needle EXACTLY in filter_text (e.g. XXX).' + #13#10 +
    'For filter/find/split + saved PDF/DOCX/ODT/RTF (with or without explain): ' +
    'actions:[{native tool…}, {compose_document}] — FastFile writes the file. ' +
    'When PDF/DOCX is requested, hop-2 MUST be compose_document (not consumer_rag alone).' + #13#10 +
    'When the PDF must include filtered/found lines: set compose params.filter_text=<needle> ' +
    'and params.max_lines=N (e.g. 100). FastFile appends those complete lines; do not invent them.' + #13#10 +
    'For "how do I read a file?" without path: intent=explain (short steps, no execute).' + #13#10 +
    'For "open load file screen" without path: intent=execute, action=show_tab_read.' + #13#10 +
    #13#10 +
    'LANGUAGE: The user may write in ANY of FastFile UI languages — English, ' +
    'Portuguese (BR), Spanish, French, German, Italian, Polish, Portuguese (PT), ' +
    'Romanian, Hungarian, Czech — independent of the current UI language. ' +
    'Same meaning => same action_id in all 11 languages. Do not require Portuguese wording. ' +
    'Keep paths, line numbers, filter_text and search_text EXACTLY as the user wrote them. ' +
    'A digit run such as 7157414 is filter_text/find_text (not a line number) unless they said line N. ' +
    '"generezi un PDF" / "gera um PDF" / "generate a PDF" => compose_document. ' +
    'Write user_message in the user language.' + #13#10 +
    'ROUTING (critical — choose ONE family):' + #13#10 +
    'A) Native TOOL — user wants FastFile to DO an editor action ' +
    '(merge/join/split/filter/export/replace/goto/edit/compare/script engine/tail). ' +
    'Never use consumer_rag or consumer_ai for these.' + #13#10 +
    'B) compose_document — user wants a SAVED file written by FastFile ' +
    '(.pdf/.docx/.rtf/.odt/.md/.py/…). Includes explain/summarize/purpose WHEN they also ask ' +
    'to generate/save Word/PDF/ODT/RTF. Example: "explicar pra que serve… gerando um PDF" ' +
    '-> compose_document, NOT consumer_rag.' + #13#10 +
    'C) consumer_rag — meaning/purpose/summary of file CONTENT with NO request to save a document.' + #13#10 +
    'D) consumer_ai — tabular/SQL only (counts, distinct, sum, avg, columns, WHERE).' + #13#10 +
    'E) intent=explain — how-to / unclear; suggest the right tool. Do NOT invent file answers.' + #13#10 +
    'A question mark alone does NOT mean RAG. Prefer native TOOL over Python chat when both fit.' + #13#10 +
    #13#10 +
    'INTENT MAP (user language -> JSON; YOU do not read files — FastFile executes):' + #13#10 +
    '"Quero ler arquivo C:\x.txt" / "read this file C:\x" -> intent=execute, action=open_and_read_file, params.path=C:\x' + #13#10 +
    '"Abrir tela de carregar arquivos" -> intent=execute, action=show_tab_read' + #13#10 +
    '"Abrir o segundo arquivo da lista de recentes" / "open 2nd recent file" -> intent=execute, action=open_recent_file, params.recent_index=2' + #13#10 +
    '"Ler C:\a.csv e dividir em 5 partes" -> actions:[open_and_read_file+path, split_equal_parts parts=5]' + #13#10 +
    '"Como leio um arquivo?" (no path) -> intent=explain (Ctrl+O, F5)' + #13#10 +
    '"Procurar palavra Rocha insensitive" -> find_text search_text=Rocha case_sensitive=false' + #13#10 +
    '"Ir para linha 4444" -> goto_line line_no=4444' + #13#10 +
    '"Editar linha 5" -> edit_line line_no=5' + #13#10 +
    '"Exportar linhas entre 3 a 10" -> export_lines filter_text=3-10' + #13#10 +
    '"Com relacao ao arquivo C:\x.txt, gerar um novo somente com as linhas entre 500 a 1000 (inclusive)"' + #13#10 +
    '  -> export_lines filter_text=500-1000 params.path=C:\x.txt (open that file first if it is not already loaded)' + #13#10 +
    '"Exportar linhas que tenham sao-paulo" -> export_matching_lines filter_text=sao-paulo' + #13#10 +
    '"Com relacao ao arquivo C:\x.txt, quero rodar um python para certas linhas"' + #13#10 +
    '  -> show_script_engine (Ctrl+Alt+E Macros with Python; open that file first if not loaded)' + #13#10 +
    '"Gere um programa em python deste arquivo para ler as dez primeiras linhas"' + #13#10 +
    '  -> compose_document (.py file written to disk), NOT show_script_engine' + #13#10 +
    '"Com relacao ao arquivo C:\x.txt, pra que ele serve?" / "resuma o arquivo" / "explique o conteudo"' + #13#10 +
    '  (NO saved-document request) -> consumer_rag; filter_text=original question.' + #13#10 +
    '"Pode me explicar pra que serve este arquivo, gerando um PDF?" / ' +
    '"Explain what this file is for, generating a PDF" / "Resume en Word" ' +
    '-> compose_document (rich-doc pipeline), NOT consumer_rag.' + #13#10 +
    '"Com relacao ao arquivo C:\x.txt, quantas linhas ele tem?" / "valores unicos" / "soma / media"' + #13#10 +
    '  -> consumer_ai; filter_text=original question.' + #13#10 +
    'NEVER route merge/split/filter/export/replace/script engine to consumer_rag or consumer_ai.' + #13#10 +
    'If unclear between tool and chat -> intent=explain (suggest options), not consumer_*.' + #13#10 +
    '"Quero filtrar as linhas com ERROR no arquivo C:\x.txt" -> apply_filter filter_text=ERROR (open file first if needed)' + #13#10 +
    '"Dividir o arquivo C:\x.txt em 5 partes" -> split_equal_parts parts=5 path=C:\x.txt' + #13#10 +
    '"Eu quero dividir esse arquivo em duas partes" (file already open) -> split_equal_parts parts=2 path=open file' + #13#10 +
    '"Split this file into two parts" / "Dividir este archivo en dos partes" /' + #13#10 +
    ' "Teile diese Datei in zwei Teile" / "Dividi questo file in due parti" /' + #13#10 +
    ' "Podziel ten plik na dwie czesci" / "Imparte acest fisier in doua parti" /' + #13#10 +
    ' "Oszd ket reszre ezt a fajlt" / "Rozdel tento soubor na dve casti" -> split_equal_parts' + #13#10 +
    '"Unir / mesclar / juntar arquivos" / "Merge/join files" / "Fusionner fichiers" /' + #13#10 +
    ' "Dateien zusammenfuehren" / "Unisci file" / "Scal pliki" / "Uneste fisiere" /' + #13#10 +
    ' "Fajlok egyesitese" / "Sloucit soubory" -> show_tab_merge_files' + #13#10 +
    '"Kannst du diese Datei zusammenfuehren?" / "Koennen Sie diese Datei zusammenfuehren?" ' +
    '(German: zusammenführen) -> show_tab_merge_files' + #13#10 +
    '"Pouvez-vous fusionner ce fichier C:\x.csv ?" -> show_tab_merge_files path=C:\x.csv' + #13#10 +
    '"Eu quero juntar esse arquivo" (file open or .part001 siblings) -> show_tab_merge_files path=open file' + #13#10 +
    '"Eu quero juntar esse arquivo C:\x.txt" -> show_tab_merge_files path=C:\x.txt' + #13#10 +
    '"Comparar arquivos" / "Compare files" / "Comparer fichiers" / "Dateien vergleichen" /' + #13#10 +
    ' "Confronta file" / "Porownaj pliki" / "Compara fisiere" / "Porovnat soubory" -> show_tab_compare' + #13#10 +
    '"Ativar modo CSV" -> toggle_csv_mode' + #13#10 +
    '"Iniciar tail / follow" -> start_tail' + #13#10 +
    '"Substituir pedro por pedrinho" -> replace_all search_text=pedro replace_text=pedrinho' + #13#10 +
    '"Gere um README em markdown" / "write a .pas unit" -> compose_document. ' +
    '"Arruma esse codigo" / "fix the generated file" -> compose_document (same file). ' +
    'Never dump the generated body in user_message; FastFile writes a file.' + #13#10 +
    'NEVER pretend to search/goto/edit in user_message only; return execute JSON.' + #13#10 +
    'NEVER dump file lines or bulk output in user_message (memory limit); use execute actions (export, filter, replace_all, etc.).';
end;

function ClampAssistantDisplayText(const S: string): string;
const
  MAX_CHARS = ASSISTANT_MAX_REPLY_CHARS;
  MAX_LINES = ASSISTANT_MAX_REPLY_LINES;
var
  i, LineNo, CutPos: Integer;
begin
  Result := S;
  if Result = '' then Exit;
  if Length(Result) > MAX_CHARS then
  begin
    Result := Copy(Result, 1, MAX_CHARS) + #13#10#13#10 + TrText('Assistant.ReplyTruncated');
    Exit;
  end;
  LineNo := 1;
  CutPos := 0;
  for i := 1 to Length(Result) do
  begin
    if Result[i] = #10 then
    begin
      Inc(LineNo);
      if LineNo > MAX_LINES then
      begin
        CutPos := i - 1;
        Break;
      end;
    end
    else if (Result[i] = #13) and ((i = Length(Result)) or (Result[i + 1] <> #10)) then
    begin
      Inc(LineNo);
      if LineNo > MAX_LINES then
      begin
        CutPos := i - 1;
        Break;
      end;
    end;
  end;
  if CutPos > 0 then
    Result := Copy(Result, 1, CutPos) + #13#10#13#10 + TrText('Assistant.ReplyTruncated');
end;

procedure SanitizeAssistantUserMessage(var APlan: TAssistantPlan);
begin
  APlan.UserMessage := ClampAssistantDisplayText(APlan.UserMessage);
end;

function BuildAssistantRulesBlock: string;
begin
  Result :=
    'RULES:' + #13#10 +
    '0) AI-FIRST DYNAMIC PIPELINE: the USER question is open-ended in ANY of the 11 UI languages. ' +
    'You choose action_id from meaning, never from a Portuguese sample sentence. ' +
    'Compose a complete reply for EVERY part (explain, line count from CURRENT_CONTEXT lines=N, ' +
    'filter/find needles, saved PDF/DOCX/ODT/RTF). Never answer only one clause. ' +
    'Never invent file aggregates from a sample. Host only fills path / pdf / digit codes / quotes.' + #13#10 +
    '1) You are an intent router for FastFile. You NEVER read/open files yourself; return execute JSON so the app runs actions.' + #13#10 +
    '2) Answer ONLY about FastFile capabilities in KNOWLEDGE. Never discuss source code.' + #13#10 +
    '0b) Same meaning => same action_id in EN/PT/ES/FR/DE/IT/PL/PT-PT/RO/HU/CS. ' +
    'Example compound: explain file purpose + total lines + generate PDF ' +
    '(PT: "Explica pra que serve… quantas linhas… gera um PDF"; ' +
    'RO: "explica… cate linii… generezi un PDF") -> compose_document, ' +
    'user_message includes purpose + exact lines=N from CURRENT_CONTEXT. FastFile writes the PDF.' + #13#10 +
    '3) Reply with ONE JSON object only (no markdown). Schema:' + #13#10 +
    '   {"intent":"explain"|"execute"|"unknown",' + #13#10 +
    '    "action":"<id or empty>",' + #13#10 +
    '    "params":{"path":"...","parts":N,"total_parts":N,"part_from":N,"part_to":N,' + #13#10 +
    '              "filter_text":"...","search_text":"...","line_no":N,"recent_index":N,"case_sensitive":true|false},' + #13#10 +
    '    "actions":[{"action":"...","params":{...}}, ...]  (optional chain),' + #13#10 +
    '    "confirm":true|false,' + #13#10 +
    '    "user_message":"<short reply in user language, max ~' + IntToStr(ASSISTANT_MAX_REPLY_LINES) +
    ' lines / ' + IntToStr(ASSISTANT_MAX_REPLY_CHARS div 1024) + ' KB>"}' + #13#10 +
    '4) intent=explain: operational help only (menus/shortcuts), action empty, confirm false. No step-by-step pretending you loaded a file.' + #13#10 +
    '9) NEVER put file contents, line listings, or bulk transformed text in user_message (no printing millions of lines). Use intent=execute so FastFile runs tools; the assistant panel only shows short status text.' + #13#10 +
    '5) intent=execute: action MUST be an allowed id; put Windows paths in params.path exactly as user wrote. confirm true for file IO.' + #13#10 +
    '6) If user gives a full path and asks ONLY to read/load/open that file -> intent=execute open_and_read_file (not explain).' + #13#10 +
    '6c) Path AND another task (filter, split, python, export, merge, compare, tail, CSV, ' +
    'SQL chat, purpose/summary, line count, saved PDF) -> that tool (or a chain), ' +
    'not open_and_read_file alone. Open first in a chain if the file is not loaded.' + #13#10 +
    '6d) When CURRENT_CONTEXT has file= filled (FastFile file name box), ANY question about ' +
    'that file (size, creation/modified/access dates, lines, properties, "dele"/"dela"/"this file") ' +
    'refers to that path. Use created=/modified=/accessed=/size_bytes=/lines= from CURRENT_CONTEXT ' +
    'in user_message when the user asks those facts — NEVER say you cannot obtain them. ' +
    'If file= is empty and the user implies a file, FastFile already rejected the ' +
    'question locally — it never reaches you. The user must fill the file name box ' +
    'or put a full existing path in the question.' + #13#10 +
    '6f) A full Windows path in USER_QUESTION is bound by FastFile into the file name box ' +
    'when that file exists. If the path is missing on disk, or file= is empty and the ' +
    'question is about a file (lines, PDF, explain, prefixes), FastFile rejects the ' +
    'question before you run. If there is no path in the question, the file name box (file=) is the subject.' + #13#10 +
    '6e) FILTER/GREP bridge (Ctrl+L): CURRENT_CONTEXT may include filter_active=, filter_text=, ' +
    'filter_hits=, filter_partial=, filter_bar_visible=, select_mode=. ' +
    'When filter_active=1, the user may say "the filter", "esse filtro", "os resultados", "hits", ' +
    '"Ctrl+L" without restating the pattern — reuse filter_text= and filter_hits=. ' +
    'Status / how many / what pattern -> intent=explain with those values (do NOT re-apply). ' +
    'Continue / more hits when filter_partial=1 -> continue_filter. ' +
    'Export those results -> export_filtered. Copy to clipboard -> copy_filtered. ' +
    'Clear -> clear_filter. Open/show filter UI -> open_filter. ' +
    'Never ask again for the pattern if filter_text is present.' + #13#10 +
    '6b) If user asks to open the Nth file in the Recent Files tab list (e.g. second in the list) -> intent=execute open_recent_file, params.recent_index=N (1-based row as shown in lvRecentFiles).' + #13#10 +
    '7) intent=unknown: cannot map to FastFile (OS commands, format disk, run .exe, malware, unrelated topics).' + #13#10 +
    '10) NEVER return execute for: format/wipe disk, shell/CMD/PowerShell OS, run/launch .exe, ' +
    'delete Windows/system, malware, virus, ransomware, keylogger, reverse shell.' + #13#10 +
    '    NEVER compose/generate malware, viruses, ransomware, keyloggers, or OS wipe scripts.' + #13#10 +
    '    FastFile Script Engine (Ctrl+Alt+E, show_script_engine) IS in-app Python on file lines and IS allowed.' + #13#10 +
    '    Other OS commands / launching executables are not.' + #13#10 +
    '8) Multi-step requests use "actions" array; first step open_and_read_file when a path is given.' + #13#10 +
    '8b) Path + generate/create/export a NEW file + inclusive line range (N to M / N-M) -> export_lines, not goto_line.' + #13#10 +
    '8c) Path + run in-app Python on lines of that file -> show_script_engine (Ctrl+Alt+E), not an OS command, not open_and_read_file only.' + #13#10 +
    '8c2) "Gere/escreva um programa/classe/script" in Python/JS/TS/Go/Java/C++/etc ' +
    '(standalone source file) -> compose_document, NOT show_script_engine. ' +
    'Script Engine is only for running transform(line) on the open file.' + #13#10 +
    '8v) "Validar fonte" / "carregar o fonte pra validar" / check syntax of .py/.js/.ts/.tsx ' +
    '-> validate_source (syntax only; never run). Unsupported extensions: explain supported ' +
    'list (Python/JS/JSX/TS/TSX). "Quais linguagens valida?" -> intent=explain with that list.' + #13#10 +
    '8d) Path + filter/grep lines by a needle -> apply_filter. Path + split into N equal parts -> split_equal_parts. ' +
    'Path + merge/join files (incl. reassemble .part001+) -> show_tab_merge_files with params.path. ' +
    'Optional merge mode: start/beginning, after line N, end. Path + compare files -> show_tab_compare.' + #13#10 +
    '8e) Path + a question about file meaning/content/summary/analysis ' +
    '(pra que serve, resumo, explique) WITHOUT asking to save Word/PDF/ODT/RTF ' +
    '-> consumer_rag. Forward original question in filter_text. Answer stays in this Assistant chat.' + #13#10 +
    '8f) Path + ANY math/data op on the file (soma, média, %, distinct, WHERE, ' +
    'calcular, frequência) -> consumer_ai for complex SQL/aggregates. ' +
    'For line startswith/prefix counts in ANY language -> count_line_prefixes ' +
    'with filter_text=prefix1|prefix2|… (local scan; no Lambda). ' +
    'For line contains/partial/substring counts in ANY language ' +
    '(how many lines have/contain X, procura parcial, …) -> count_matching_lines ' +
    'with filter_text=needle1|needle2|… (local scan; no Lambda). Do NOT use consumer_ai for that. ' +
    'Compound asks that also want a saved PDF/DOCX/ODT/RTF: prefer action=compose_document ' +
    'OR an actions chain [count_line_prefixes|count_matching_lines, compose_document]; FastFile will count locally ' +
    'and then save the document. Do not invent counts. ' +
    'Never invent numbers with compose_document from a sample. ' +
    'EXCEPTION: if CURRENT_CONTEXT already has lines=N and the user ONLY asks the ' +
    'total line/row count of this/open file with NO filter/prefix/value/math -> intent=explain and put that exact N in user_message. ' +
    'Do NOT open consumer_ai for that alone. Never send merge/split/filter/export to consumer_*.' + #13#10 +
    '8g) If unclear between a native tool and Python chat -> intent=explain (suggest options), ' +
    'not consumer_rag/consumer_ai by default.' + #13#10 +
    '8h) Explain/summarize/purpose of the file WITH saved Word/PDF/ODT/RTF ' +
    '(any of 11 languages — not a fixed phrase) -> compose_document, NOT consumer_rag. ' +
    'Put exact total line count from CURRENT_CONTEXT lines=N in user_message when asked. ' +
    'NEVER put the generated PDF body in user_message. ' +
    'NOT for filtered prefix/SQL aggregates (those are 8f even with PDF). ' +
    'File-content questions without file-output stay consumer_rag. ' +
    'Export line-range stays export_lines.' + #13#10 +
    '8i) COMPOUND / multi-part questions are DYNAMIC — any mix, any of 11 languages. ' +
    'Always write ONE complete user_message covering every asked part. ' +
    'Put exact lines=/created=/modified=/accessed=/size_bytes= from CURRENT_CONTEXT only for ' +
    'TOTAL open-file facts (not filtered math). ' +
    'actions: open_and_read_file first if needed; ' +
    'line startswith/prefix counts = count_line_prefixes (filter_text=real prefixes); ' +
    'line contains/partial counts = count_matching_lines (filter_text=real needles); ' +
    'other file math/data = consumer_ai; file meaning+saved PDF = compose_document; ' +
    'native tool + explain (no saved doc) = actions:[apply_filter|split_equal_parts|find_text|…, consumer_rag]; ' +
    'native tool + saved PDF/DOCX = actions:[native, compose_document] (or count_* + compose); ' +
    'native tools keep their action ids. Never answer only one part. ' +
    'Prefix-count AND contains/partial-count in the SAME question ' +
    '(startswith code + word Bianca (parcial) + total lines, any language) ' +
    'MUST use actions:[{count_line_prefixes, filter_text=real prefixes}, ' +
    '{count_matching_lines, filter_text=real needles}]. FastFile runs BOTH. ' +
    'Never omit the contains hop. Total lines come from the scan. ' +
    'Never rely on one Portuguese example sentence — follow the user wording.' + #13#10;
end;

function ParseAssistantPlan(const RawAnswer: WideString): TAssistantPlan;
var
  S, Low, Act, IntentS, PathS, PartsS: string;
  p, RecentIdx: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Intent := aiUnknown;
  Result.Parts := 0;
  Result.NeedConfirm := False;
  Result.AlsoCountMatching := '';
  Result.AlsoCountPrefixes := '';
  S := Trim(string(RawAnswer));
  S := StripMarkdownFences(S);
  Low := LowerCase(S);
  IntentS := LowerCase(ExtractJsonStringFieldAnsi(S, 'intent'));
  if IntentS = '' then
  begin
    if PosBMH('"intent":', Low) > 0 then
      IntentS := 'unknown';
  end;
  if IntentS = 'explain' then
    Result.Intent := aiExplain
  else if IntentS = 'execute' then
    Result.Intent := aiExecute
  else
    Result.Intent := aiUnknown;

  Result.UserMessage := JsonUnescape(ExtractJsonStringFieldAnsi(S, 'user_message'));
  if Result.UserMessage = '' then
    Result.UserMessage := JsonUnescape(ExtractJsonStringFieldAnsi(S, 'message'));
  if Result.UserMessage = '' then
  begin
    if Length(S) > ASSISTANT_MAX_RAW_FALLBACK_CHARS then
      Result.UserMessage := TrText('Assistant.ReplyTooLargeFallback')
    else
      Result.UserMessage := S;
  end;
  SanitizeAssistantUserMessage(Result);

  Act := LowerCase(ExtractJsonStringFieldAnsi(S, 'action'));
  Result.ActionId := Act;

  PathS := JsonUnescape(ExtractJsonStringFieldAnsi(S, 'path'));
  if PathS = '' then
  begin
    p := PosBMH('"path"', Low);
    if p > 0 then
      PathS := JsonUnescape(ExtractJsonStringFieldAnsi(Copy(S, p, MaxInt), 'path'));
  end;
  if PathS = '' then
  begin
    p := PosBMH('"params"', Low);
    if p > 0 then
      PathS := JsonUnescape(ExtractJsonStringFieldAnsi(Copy(S, p, MaxInt), 'path'));
  end;
  Result.Path := Trim(PathS);

  PartsS := ExtractJsonStringFieldAnsi(S, 'parts');
  if PartsS = '' then
  begin
    p := PosBMH('"params"', Low);
    if p > 0 then
      PartsS := ExtractJsonStringFieldAnsi(Copy(S, p, MaxInt), 'parts');
  end;
  Result.Parts := StrToIntDef(Trim(PartsS), 0);
  if Result.Parts = 0 then
    Result.Parts := ParseJsonIntField(S, 'parts');
  Result.TotalParts := ParseJsonIntField(S, 'total_parts');
  if Result.TotalParts = 0 then
    Result.TotalParts := Result.Parts;
  Result.PartFrom := ParseJsonIntField(S, 'part_from');
  Result.PartTo := ParseJsonIntField(S, 'part_to');
  if Result.PartFrom = 0 then Result.PartFrom := 1;
  if Result.PartTo = 0 then Result.PartTo := Result.PartFrom;
  Result.FilterText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(S, 'filter_text')));
  if Result.FilterText = '' then
    Result.FilterText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(S, 'filter')));
  if Result.FilterText = '' then
    Result.FilterText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(S, 'search_text')));
  Result.ReplaceText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(S, 'replace_text')));
  if Result.ReplaceText = '' then
    Result.ReplaceText := Trim(JsonUnescape(ExtractJsonStringFieldAnsi(S, 'replacement')));
  Result.LineNo := ParseJsonIntField(S, 'line_no');
  if PosBMH('"case_sensitive":true', Low) > 0 then
    Result.CaseSensitive := True
  else
    Result.CaseSensitive := False;
  if Result.LineNo = 0 then
    Result.LineNo := ParseJsonIntField(S, 'line');
  if (Result.LineNo = 0) or SameText(Result.ActionId, 'open_recent_file') then
  begin
    RecentIdx := ParseJsonIntField(S, 'recent_index');
    if RecentIdx <> 0 then
      Result.LineNo := RecentIdx;
    if Result.LineNo = 0 then
    begin
      p := PosBMH('"params"', Low);
      if p > 0 then
      begin
        RecentIdx := ParseJsonIntField(Copy(S, p, MaxInt), 'recent_index');
        if RecentIdx <> 0 then
          Result.LineNo := RecentIdx;
      end;
    end;
  end;
  Result.ByteOffset := StrToInt64Def(Trim(ExtractJsonStringFieldAnsi(S, 'byte_offset')), 0);
  if Result.ByteOffset = 0 then
    Result.ByteOffset := StrToInt64Def(Trim(ExtractJsonStringFieldAnsi(S, 'byte_pos')), 0);
  Result.MaxLines := ParseJsonIntField(S, 'max_lines');
  if Result.MaxLines = 0 then
    Result.MaxLines := ParseJsonIntField(S, 'limit');
  if Result.MaxLines = 0 then
    Result.MaxLines := ParseJsonIntField(S, 'max_records');
  if Result.MaxLines = 0 then
  begin
    p := PosBMH('"params"', Low);
    if p > 0 then
    begin
      Result.MaxLines := ParseJsonIntField(Copy(S, p, MaxInt), 'max_lines');
      if Result.MaxLines = 0 then
        Result.MaxLines := ParseJsonIntField(Copy(S, p, MaxInt), 'limit');
      if Result.MaxLines = 0 then
        Result.MaxLines := ParseJsonIntField(Copy(S, p, MaxInt), 'max_records');
    end;
  end;

  if TryParseActionsChain(S, Result) then
  begin
    PlanFromFirstChainItem(Result);
    if Result.Intent <> aiExplain then
      Result.Intent := aiExecute;
  end;

  if PosBMH('"confirm":true', Low) > 0 then
    Result.NeedConfirm := True
  else if PosBMH('"confirm": true', Low) > 0 then
    Result.NeedConfirm := True;

  if (Result.Intent = aiExecute) and (Result.ActionId = '') and (Result.ChainCount <= 1) then
    Result.Intent := aiUnknown;
end;

function IsAllowedActionId(const AId: string): Boolean;
begin
  Result := CatalogIsAllowedActionId(AId);
end;

function ValidatePlan(var APlan: TAssistantPlan): string; forward;

function ValidateChainStep(const St: TAssistantChainStep): string;
var
  P: TAssistantPlan;
begin
  FillChar(P, SizeOf(P), 0);
  P.Intent := aiExecute;
  P.ActionId := St.ActionId;
  P.Path := St.Path;
  P.Parts := St.Parts;
  P.TotalParts := St.TotalParts;
  P.PartFrom := St.PartFrom;
  P.PartTo := St.PartTo;
  P.FilterText := St.FilterText;
  P.ReplaceText := St.ReplaceText;
  P.LineNo := St.LineNo;
  P.CaseSensitive := St.CaseSensitive;
  Result := ValidatePlan(P);
end;

function ValidatePlan(var APlan: TAssistantPlan): string;
var
  i: Integer;
  E: string;
begin
  Result := '';
  if APlan.Intent = aiExplain then
  begin
    APlan.NeedConfirm := False;
    Exit;
  end;
  if APlan.Intent = aiUnknown then
  begin
    APlan.NeedConfirm := False;
    Exit;
  end;
  if APlan.ChainCount > 1 then
  begin
    for i := 0 to APlan.ChainCount - 1 do
    begin
      E := ValidateChainStep(APlan.Chain[i]);
      if E <> '' then
      begin
        Result := E;
        APlan.Intent := aiUnknown;
        Exit;
      end;
    end;
    APlan.NeedConfirm := True;
    Exit;
  end;
  if not IsAllowedActionId(APlan.ActionId) then
  begin
    Result := TrText('Assistant.Error.UnknownAction');
    APlan.Intent := aiUnknown;
    Exit;
  end;
  if SameText(APlan.ActionId, 'open_and_read_file') then
  begin
    if APlan.Path = '' then
      Result := TrText('Assistant.Error.PathRequired')
    else if not FileExists(APlan.Path) then
      Result := TrText('Assistant.Error.FileNotFound') + ' ' + APlan.Path;
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'open_recent_file') then
  begin
    if APlan.LineNo = 0 then
      Result := Format(TrText('Assistant.Error.RecentListOutOfRange'), [0])
    else if Trim(AssistantHostGetRecentFilePathByListIndex(APlan.LineNo)) = '' then
      Result := Format(TrText('Assistant.Error.RecentListOutOfRange'), [APlan.LineNo]);
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'split_equal_parts') then
  begin
    if APlan.Parts < 2 then
      Result := TrText('Assistant.Error.PartsRange');
    if Trim(APlan.Path) = '' then
      APlan.Path := AssistantHostGetOpenFilePath;
    if Result = '' then
    begin
      if (APlan.Path <> '') and (not FileExists(APlan.Path)) then
        Result := TrText('Assistant.Error.FileNotFound') + ' ' + APlan.Path;
      { Path vazio = arquivo ainda nao aberto: host pedira o ficheiro no Execute. }
    end;
    if (Result = '') and (Trim(APlan.Path) = '') then
      APlan.UserMessage := TrText('Assistant.Local.WillSplitEqualAskFile');
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'extract_file_parts') then
  begin
    if APlan.TotalParts < 2 then
      Result := TrText('Assistant.Error.PartsRange');
    if (APlan.PartFrom < 1) or (APlan.PartTo > APlan.TotalParts) or (APlan.PartFrom > APlan.PartTo) then
      Result := TrText('Assistant.Error.ExtractRange');
    if Trim(APlan.Path) = '' then
      APlan.Path := AssistantHostGetOpenFilePath;
    if Result = '' then
    begin
      if (APlan.Path <> '') and (not FileExists(APlan.Path)) then
        Result := TrText('Assistant.Error.FileNotFound') + ' ' + APlan.Path;
    end;
    if (Result = '') and (Trim(APlan.Path) = '') then
      APlan.UserMessage := TrText('Assistant.Local.WillExtractPartAskFile');
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'show_tab_merge_files') then
  begin
    if Trim(APlan.Path) = '' then
      APlan.Path := AssistantHostGetOpenFilePath;
    if Result = '' then
    begin
      if (APlan.Path <> '') and (not FileExists(APlan.Path)) then
        Result := TrText('Assistant.Error.FileNotFound') + ' ' + APlan.Path;
    end;
    if (Result = '') and (Trim(APlan.Path) = '') then
      APlan.UserMessage := TrText('Assistant.Local.WillMergeFilesAskFile')
    else if Result = '' then
      APlan.UserMessage := TrText('Assistant.Local.WillMergeFiles');
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'apply_filter') then
  begin
    if Trim(APlan.FilterText) = '' then
      Result := TrText('Assistant.Error.FilterTextRequired');
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'validate_source') then
  begin
    if Trim(APlan.Path) <> '' then
    begin
      if not IsValidatableComposeSourcePath(APlan.Path) then
        Result := TrText('Assistant.Validate.Unsupported') + #13#10#13#10 +
          TrText('Assistant.Validate.SupportedLanguages')
      else if not FileExists(APlan.Path) then
        Result := TrText('Assistant.Error.FileNotFound') + ' ' + APlan.Path;
    end;
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'count_line_prefixes') or
     SameText(APlan.ActionId, 'count_matching_lines') then
  begin
    if Trim(APlan.FilterText) = '' then
      Result := TrText('Assistant.Error.FilterTextRequired');
    if Result = '' then
    begin
      if Trim(APlan.Path) = '' then
        APlan.Path := AssistantHostGetOpenFilePath;
      if (Trim(APlan.Path) = '') or (not FileExists(APlan.Path)) then
        Result := TrText('Assistant.Error.NoFileOpen');
    end;
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'find_text') then
  begin
    if Trim(APlan.FilterText) = '' then
      Result := TrText('Enter search text.');
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'edit_line') then
  begin
    if APlan.LineNo < 1 then
      Result := TrText('Assistant.Error.LineOutOfRange');
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'delete_line') then
  begin
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'goto_line') then
  begin
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'export_lines') then
  begin
    if Trim(APlan.FilterText) = '' then
      Result := TrText('Assistant.Error.LineRangeRequired');
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'export_matching_lines') then
  begin
    if Trim(APlan.FilterText) = '' then
      Result := TrText('Assistant.Error.FilterTextRequired');
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'replace_all') then
  begin
    if Trim(APlan.FilterText) = '' then
      Result := TrText('Enter search text.')
    else if Trim(APlan.ReplaceText) = '' then
      Result := TrText('Assistant.Error.ReplaceTextRequired');
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'delete_duplicate_lines') then
  begin
    APlan.NeedConfirm := True;
    Exit;
  end;
  if SameText(APlan.ActionId, 'compose_document') then
  begin
    APlan.NeedConfirm := False;
    Exit;
  end;
  if SameText(APlan.ActionId, 'consumer_rag') or SameText(APlan.ActionId, 'consumer_ai') then
  begin
    APlan.NeedConfirm := True;
    Exit;
  end;
  APlan.NeedConfirm := False;
end;

function AppendLineContainsCounts(const APath, ANeedles: string;
  var ABody: string): Boolean;
var
  List: TStringList;
  Prefs: TStringDynArray;
  Counts: TInt64DynArray;
  TotalScanned: Int64;
  i, n: Integer;
  Part: string;
begin
  Result := False;
  if (Trim(APath) = '') or (Trim(ANeedles) = '') or (not FileExists(APath)) then Exit;
  List := TStringList.Create;
  n := 0;
  try
    List.StrictDelimiter := True;
    List.Delimiter := '|';
    List.DelimitedText := StringReplace(Trim(ANeedles), ',', '|', [rfReplaceAll]);
    for i := 0 to List.Count - 1 do
    begin
      Part := Trim(List[i]);
      if (Part = '') or (Pos('?', Part) > 0) or (Length(Part) > 64) then Continue;
      SetLength(Prefs, n + 1);
      Prefs[n] := Part;
      Inc(n);
    end;
  finally
    List.Free;
  end;
  if n = 0 then Exit;
  if Assigned(GAssistantCtrl) then
  begin
    if not FastFileCountLineContains(APath, Prefs, Counts, TotalScanned,
      GAssistantCtrl.CountScanProgress) then Exit;
  end
  else if not FastFileCountLineContains(APath, Prefs, Counts, TotalScanned) then
    Exit;
  for i := 0 to High(Prefs) do
  begin
    Part := Format(TrText('Assistant.Reply.LineContainsCount'),
      [Prefs[i], IntToStr(Counts[i])]);
    if ABody <> '' then
      ABody := ABody + #13#10;
    ABody := ABody + Part;
  end;
  Result := True;
end;

function AppendLinePrefixCounts(const APath, ANeedles: string;
  var ABody: string): Boolean;
var
  List: TStringList;
  Prefs: TStringDynArray;
  Counts: TInt64DynArray;
  TotalScanned: Int64;
  i, n: Integer;
  Part: string;
begin
  Result := False;
  if (Trim(APath) = '') or (Trim(ANeedles) = '') or (not FileExists(APath)) then Exit;
  List := TStringList.Create;
  n := 0;
  try
    List.StrictDelimiter := True;
    List.Delimiter := '|';
    List.DelimitedText := StringReplace(Trim(ANeedles), ',', '|', [rfReplaceAll]);
    for i := 0 to List.Count - 1 do
    begin
      Part := Trim(List[i]);
      if (Part = '') or (Pos(' ', Part) > 0) or (Pos('?', Part) > 0) or
         (Length(Part) > 64) then Continue;
      SetLength(Prefs, n + 1);
      Prefs[n] := Part;
      Inc(n);
    end;
  finally
    List.Free;
  end;
  if n = 0 then Exit;
  if Assigned(GAssistantCtrl) then
  begin
    if not FastFileCountLineStartPrefixes(APath, Prefs, Counts, TotalScanned,
      GAssistantCtrl.CountScanProgress) then Exit;
  end
  else if not FastFileCountLineStartPrefixes(APath, Prefs, Counts, TotalScanned) then
    Exit;
  for i := 0 to High(Prefs) do
  begin
    Part := Format(TrText('Assistant.Reply.LinePrefixCount'),
      [Prefs[i], IntToStr(Counts[i])]);
    if ABody <> '' then
      ABody := ABody + #13#10;
    ABody := ABody + Part;
  end;
  Result := True;
end;

function ExecuteAssistantPlan(const APlan: TAssistantPlan): string;
var
  St: TAssistantChainStep;
  ExportPath, OpenPath, Body, Part: string;
  Prefs: TStringDynArray;
  Counts: TInt64DynArray;
  TotalScanned: Int64;
  i, n: Integer;
  List: TStringList;
  PlanLocal: TAssistantPlan;
begin
  Result := '';
  if not FastFileAssistantHostReady then
  begin
    Result := TrText('Assistant.Error.HostNotReady');
    Exit;
  end;
  if APlan.Intent <> aiExecute then
    Exit;
  if SameText(APlan.ActionId, 'compose_document') then
  begin
    Result := TrText('Assistant.Local.WillComposeDocument');
    Exit;
  end;
  if SameText(APlan.ActionId, 'validate_source') then
  begin
    OpenPath := Trim(APlan.Path);
    if Assigned(GAssistantCtrl) then
    begin
      if OpenPath <> '' then
      begin
        if not IsValidatableComposeSourcePath(OpenPath) then
        begin
          Result := TrText('Assistant.Validate.Unsupported') + #13#10#13#10 +
            TrText('Assistant.Validate.SupportedLanguages');
          Exit;
        end;
        if not FileExists(OpenPath) then
        begin
          Result := TrText('Assistant.Validate.FileMissing') + ' ' + OpenPath;
          Exit;
        end;
      end
      else if not GAssistantCtrl.ResolveValidateSourcePath(
        Trim(GAssistantCtrl.MemoQuestion.Text), True, OpenPath, Body) then
      begin
        if Body <> '' then
          Result := Body
        else
          Result := TrText('Assistant.Validate.NeedPath');
        Exit;
      end;
      Result := GAssistantCtrl.RunValidateSourcePath(OpenPath,
        UserWantsLoadSourceToValidate(Trim(GAssistantCtrl.MemoQuestion.Text)) or
        (Trim(APlan.Path) <> ''));
    end
    else
    begin
      if OpenPath = '' then
        OpenPath := AssistantHostGetOpenFilePath;
      if not IsValidatableComposeSourcePath(OpenPath) then
      begin
        Result := TrText('Assistant.Validate.Unsupported') + #13#10#13#10 +
          TrText('Assistant.Validate.SupportedLanguages');
        Exit;
      end;
      if (OpenPath = '') or (not FileExists(OpenPath)) then
      begin
        Result := TrText('Assistant.Validate.FileMissing');
        Exit;
      end;
      if AssistantHostValidateComposedSource(OpenPath, Body) then
        Result := OpenPath + #13#10 + TrText('Assistant.Validate.Ok') + #13#10 + Body
      else
        Result := OpenPath + #13#10 + TrText('Assistant.Validate.Failed') + #13#10 + Body;
    end;
    Exit;
  end;
  if SameText(APlan.ActionId, 'count_line_prefixes') then
  begin
    PlanLocal := APlan;
    SanitizeCountSourcePath(PlanLocal);
    OpenPath := Trim(PlanLocal.Path);
    if OpenPath = '' then
      OpenPath := AssistantHostGetOpenFilePath;
    if (OpenPath = '') or (not FileExists(OpenPath)) then
    begin
      Result := TrText('Assistant.Error.NoFileOpen');
      Exit;
    end;
    List := TStringList.Create;
    try
      List.StrictDelimiter := True;
      List.Delimiter := '|';
      List.DelimitedText := StringReplace(Trim(PlanLocal.FilterText), ',', '|', [rfReplaceAll]);
      n := 0;
      for i := 0 to List.Count - 1 do
      begin
        Part := Trim(List[i]);
        { Reject NL fragments the model sometimes puts in filter_text. }
        if (Part = '') or (Pos(' ', Part) > 0) or (Pos('?', Part) > 0) or
           (Length(Part) > 64) then
          Continue;
        SetLength(Prefs, n + 1);
        Prefs[n] := Part;
        Inc(n);
      end;
    finally
      List.Free;
    end;
    if (n = 0) and Assigned(GAssistantCtrl) and Assigned(GAssistantCtrl.MemoQuestion) and
       TryParseLinePrefixCountAsk(Trim(GAssistantCtrl.MemoQuestion.Text), Prefs) then
      n := Length(Prefs);
    if n = 0 then
    begin
      Result := TrText('Assistant.Error.FilterTextRequired');
      Exit;
    end;
    if Assigned(GAssistantCtrl) then
      GAssistantCtrl.BeginFileCountWait;
    if Assigned(GAssistantCtrl) then
    begin
      if not FastFileCountLineStartPrefixes(OpenPath, Prefs, Counts, TotalScanned,
        GAssistantCtrl.CountScanProgress) then
      begin
        if GAssistantCtrl.FAiCancelled or TfrmSmoothLoading.CancelRequested then
          Result := TrText('Assistant.Cancelled')
        else
          Result := TrText('Assistant.Reply.OpenFileMetaUnavailable');
        Exit;
      end;
    end
    else if not FastFileCountLineStartPrefixes(OpenPath, Prefs, Counts, TotalScanned) then
    begin
      Result := TrText('Assistant.Reply.OpenFileMetaUnavailable');
      Exit;
    end;
    Body := '';
    for i := 0 to High(Prefs) do
    begin
      Part := Format(TrText('Assistant.Reply.LinePrefixCount'),
        [Prefs[i], IntToStr(Counts[i])]);
      if Body = '' then
        Body := Part
      else
        Body := Body + #13#10 + Part;
    end;
    if Trim(APlan.AlsoCountMatching) <> '' then
      AppendLineContainsCounts(OpenPath, APlan.AlsoCountMatching, Body);
    Body := Body + #13#10 + Format(TrText('Assistant.Reply.LinePrefixCountScanned'),
      [IntToStr(TotalScanned)]);
    { Same pass: host already knows the file length. Always expose it (Q4 "no total"
      in any language) — not an NL phrase list. }
    Part := ExtractFileName(OpenPath);
    if Part = '' then
      Part := OpenPath;
    Body := Body + #13#10 + Format(TrText('Assistant.Reply.OpenFileLineCount'),
      [Part, IntToStr(TotalScanned)]);
    Result := Body;
    AssistantWriteLog('count_line_prefixes: ' + OpenPath + ' n=' + IntToStr(n));
    Exit;
  end;
  if SameText(APlan.ActionId, 'count_matching_lines') then
  begin
    PlanLocal := APlan;
    SanitizeCountSourcePath(PlanLocal);
    OpenPath := Trim(PlanLocal.Path);
    if OpenPath = '' then
      OpenPath := AssistantHostGetOpenFilePath;
    if (OpenPath = '') or (not FileExists(OpenPath)) then
    begin
      Result := TrText('Assistant.Error.NoFileOpen');
      Exit;
    end;
    List := TStringList.Create;
    try
      List.StrictDelimiter := True;
      List.Delimiter := '|';
      List.DelimitedText := StringReplace(Trim(PlanLocal.FilterText), ',', '|', [rfReplaceAll]);
      n := 0;
      for i := 0 to List.Count - 1 do
      begin
        Part := Trim(List[i]);
        { AI supplies needles; reject empty / question-mark / overlong junk. }
        if (Part = '') or (Pos('?', Part) > 0) or (Length(Part) > 64) then
          Continue;
        SetLength(Prefs, n + 1);
        Prefs[n] := Part;
        Inc(n);
      end;
    finally
      List.Free;
    end;
    if (n = 0) and Assigned(GAssistantCtrl) and Assigned(GAssistantCtrl.MemoQuestion) then
    begin
      Part := ExtractQuotedNeedlesFromText(Trim(GAssistantCtrl.MemoQuestion.Text));
      if Part <> '' then
      begin
        List := TStringList.Create;
        try
          List.StrictDelimiter := True;
          List.Delimiter := '|';
          List.DelimitedText := Part;
          n := 0;
          for i := 0 to List.Count - 1 do
          begin
            Part := Trim(List[i]);
            if (Part = '') or (Length(Part) > 64) then Continue;
            SetLength(Prefs, n + 1);
            Prefs[n] := Part;
            Inc(n);
          end;
        finally
          List.Free;
        end;
      end;
    end;
    if n = 0 then
    begin
      Result := TrText('Assistant.Error.FilterTextRequired');
      Exit;
    end;
    if Assigned(GAssistantCtrl) then
      GAssistantCtrl.BeginFileCountWait;
    if Assigned(GAssistantCtrl) then
    begin
      if not FastFileCountLineContains(OpenPath, Prefs, Counts, TotalScanned,
        GAssistantCtrl.CountScanProgress) then
      begin
        if GAssistantCtrl.FAiCancelled or TfrmSmoothLoading.CancelRequested then
          Result := TrText('Assistant.Cancelled')
        else
          Result := TrText('Assistant.Reply.OpenFileMetaUnavailable');
        Exit;
      end;
    end
    else if not FastFileCountLineContains(OpenPath, Prefs, Counts, TotalScanned) then
    begin
      Result := TrText('Assistant.Reply.OpenFileMetaUnavailable');
      Exit;
    end;
    Body := '';
    for i := 0 to High(Prefs) do
    begin
      Part := Format(TrText('Assistant.Reply.LineContainsCount'),
        [Prefs[i], IntToStr(Counts[i])]);
      if Body = '' then
        Body := Part
      else
        Body := Body + #13#10 + Part;
    end;
    if Trim(APlan.AlsoCountPrefixes) <> '' then
    begin
      Part := '';
      if AppendLinePrefixCounts(OpenPath, APlan.AlsoCountPrefixes, Part) then
        Body := Part + #13#10 + Body;
    end;
    Body := Body + #13#10 + Format(TrText('Assistant.Reply.LinePrefixCountScanned'),
      [IntToStr(TotalScanned)]);
    Part := ExtractFileName(OpenPath);
    if Part = '' then
      Part := OpenPath;
    Body := Body + #13#10 + Format(TrText('Assistant.Reply.OpenFileLineCount'),
      [Part, IntToStr(TotalScanned)]);
    Result := Body;
    AssistantWriteLog('count_matching_lines: ' + OpenPath + ' n=' + IntToStr(n));
    Exit;
  end;
  if not IsAllowedActionId(APlan.ActionId) then
    Exit;
  PlanToChainStep(APlan, St);
  if SameText(APlan.ActionId, 'export_lines') then
    AssistantHostSetLastExportPath('');
  AssistantHostExecuteAction(St);
  Result := ActionStatusMessage(APlan.ActionId);
  if SameText(APlan.ActionId, 'export_lines') then
  begin
    ExportPath := AssistantHostGetLastExportPath;
    if ExportPath <> '' then
      Result := Format(TrText('Assistant.Status.ExportLinesDetail'),
        [Trim(APlan.FilterText), ExportPath])
    else if Trim(APlan.FilterText) <> '' then
      Result := Format(TrText('Assistant.Local.WillExportLinesRange'),
        [Trim(APlan.FilterText)]);
  end;
end;

function ExecutePlanOrChain(const APlan: TAssistantPlan): string;
var
  Tmp: array[0..ASSISTANT_MAX_CHAIN - 1] of TAssistantChainStep;
  i, n: Integer;
  P: TAssistantPlan;
begin
  Result := '';
  if APlan.ChainCount > 1 then
  begin
    if SameText(APlan.Chain[0].ActionId, 'open_and_read_file') then
    begin
      n := APlan.ChainCount - 1;
      if n > 0 then
      begin
        for i := 0 to n - 1 do
          Tmp[i] := APlan.Chain[i + 1];
        AssistantHostSetChain(Tmp, n, True);
      end;
      FillChar(P, SizeOf(P), 0);
      P.Intent := aiExecute;
      P.ActionId := 'open_and_read_file';
      P.Path := APlan.Chain[0].Path;
      Result := ExecuteAssistantPlan(P);
      if Result = '' then
        Result := TrText('Assistant.Status.ChainReadThenMore');
      AssistantWriteLog('chain: open then ' + IntToStr(n) + ' deferred step(s)');
      Exit;
    end;
    for i := 0 to APlan.ChainCount - 1 do
    begin
      if not IsAllowedActionId(APlan.Chain[i].ActionId) then
        Exit;
      AssistantHostExecuteAction(APlan.Chain[i]);
    end;
    Result := TrText('Assistant.Status.ChainDone');
    AssistantWriteLog('chain: ' + IntToStr(APlan.ChainCount) + ' step(s) sync');
    Exit;
  end;
  Result := ExecuteAssistantPlan(APlan);
end;

function PlanNeedsExecuteButton(const APlan: TAssistantPlan): Boolean;
begin
  if APlan.Intent <> aiExecute then
  begin
    Result := False;
    Exit;
  end;
  if APlan.ChainCount > 1 then
    Result := True
  else
    Result := IsAllowedActionId(APlan.ActionId);
end;

{ TFastFileAssistantThread }

constructor TFastFileAssistantThread.Create(ADlg: TFastFileAssistantCtrl; const PromptW: WideString);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOwnerDlg := ADlg;
  FPrompt := PromptW;
end;

procedure TFastFileAssistantThread.Execute;
begin
  FOk := FastFileAIInvokePrompt(FPrompt, FAns, FErr, NotifyProgress);
  Synchronize(UISync);
end;

procedure TFastFileAssistantThread.NotifyProgress(APercent: Integer; const APhase: string);
begin
  FProgPct := APercent;
  FProgPhase := APhase;
  if Terminated then Exit;
  if GetCurrentThreadId = MainThreadID then
    SyncProgress
  else
    Synchronize(SyncProgress);
end;

procedure TFastFileAssistantThread.SyncProgress;
begin
  if Assigned(FOwnerDlg) then
    FOwnerDlg.ApplyAiNetProgress(FProgPct, FProgPhase);
end;

procedure TFastFileAssistantThread.UISync;
begin
  if Assigned(FOwnerDlg) then
    FOwnerDlg.ApplyAiFinished(FOk, FAns, FErr);
end;

constructor TFastFileAssistantTextJobThread.Create(ADlg: TFastFileAssistantCtrl;
  const PromptW: WideString; AJob: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FOwnerDlg := ADlg;
  FPrompt := PromptW;
  FJob := AJob;
end;

procedure TFastFileAssistantTextJobThread.Execute;
begin
  FOk := FastFileAIInvokePrompt(FPrompt, FAns, FErr, NotifyProgress);
  Synchronize(UISync);
end;

procedure TFastFileAssistantTextJobThread.NotifyProgress(APercent: Integer; const APhase: string);
begin
  FProgPct := APercent;
  FProgPhase := APhase;
  if Terminated then Exit;
  if GetCurrentThreadId = MainThreadID then
    SyncProgress
  else
    Synchronize(SyncProgress);
end;

procedure TFastFileAssistantTextJobThread.SyncProgress;
begin
  if Assigned(FOwnerDlg) then
    FOwnerDlg.ApplyAiNetProgress(FProgPct, FProgPhase);
end;

procedure TFastFileAssistantTextJobThread.UISync;
begin
  if Assigned(FOwnerDlg) then
    FOwnerDlg.ApplyTextJobFinished(FJob, FOk, FAns, FErr);
end;

{ TFastFileAssistantCtrl }

constructor TFastFileAssistantCtrl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLayoutBuilt := False;
  FFloating := False;
  FOnFloatClick := nil;
  FOnTearOff := nil;
  FOnPythonClick := nil;
  FHeaderDown := False;
  FHostPanel := nil;
  FComposeAwaitingBody := False;
  FComposeDestPath := '';
  FComposeIsFix := False;
  FComposeSourceBody := '';
  FComposeSummarizePhase := False;
  FComposePipelineWord := False;
  FComposeAppendFiltered := False;
  FSuppressRecentChange := False;
  FRecentQuestionsExpanded := False;
  FExpandingRecentMore := False;
  FRecentFindActive := False;
  FActivatingRecentFind := False;
  FRecentFindNeedle := '';
  FFindImages := nil;
  FFindImageIndex := -1;
  FWaitOverlayOwned := False;
  FWaitAllowCreep := False;
  FAiCancelled := False;
  FTextJobReplaceSel := False;
  FPopupMenuOpen := False;
  FRecentPopupPosted := False;
  FTmrWaitCancel := TTimer.Create(Self);
  FTmrWaitCancel.Enabled := False;
  FTmrWaitCancel.Interval := 200;
  FTmrWaitCancel.OnTimer := TmrWaitCancelTimer;
  FRecentQuestions := TStringList.Create;
  FRecentQuestions.StrictDelimiter := True;
  FOfferActionIds := TStringList.Create;
  FOfferActionIds.StrictDelimiter := True;
  FReplyStyleUserPresets := TStringList.Create;
  FReplyStyleUserPresets.NameValueSeparator := '=';
  FReplyStylePresetId := 'default';
  FReplyStyleCustom := '';
  BevelOuter := bvNone;
  BevelInner := bvNone;
  Caption := '';
  ParentColor := False;
  //Color := FastFileWorkspaceSurfaceColor;
  DoubleBuffered := True;
end;

destructor TFastFileAssistantCtrl.Destroy;
begin
  AgentBridgeSetListener(nil);
  EndAssistantWait;
  FTmrWaitCancel := nil;
  FreeAndNil(FRecentQuestions);
  FreeAndNil(FOfferActionIds);
  FreeAndNil(FReplyStyleUserPresets);
  inherited Destroy;
end;

procedure TFastFileAssistantCtrl.SyncDontShowStartupCheckbox;
begin
  if not Assigned(ChkDontShowAgain) then Exit;
  ChkDontShowAgain.Visible := True;
  if FIniPath <> '' then
    ChkDontShowAgain.Checked := not ShouldShowAssistantOnStartup(FIniPath);
end;

procedure TFastFileAssistantCtrl.PersistStartupPreference;
begin
  if Assigned(ChkDontShowAgain) and (FIniPath <> '') then
    SaveAssistantShowOnStartup(FIniPath, not ChkDontShowAgain.Checked);
  SaveRecentQuestions;
end;

procedure TFastFileAssistantCtrl.ApplyAssistantUiTexts;
begin
  if not FLayoutBuilt then Exit;
  if Assigned(LblTitle) then
    LblTitle.Caption := TrText('Assistant.Title');
  if Assigned(LblShortcut) then
    LblShortcut.Caption := 'Ctrl+Alt+A';
  if Assigned(BtnHide) then
  begin
    BtnHide.Caption := #$00D7; { × }
    BtnHide.Hint := TrText('Close');
    BtnHide.ShowHint := True;
  end;
  SyncFloatAction;
  ApplyHeaderDragChrome;
  if Assigned(FGripInputBot) then
    FGripInputBot.Hint := TrText('Assistant.SplitHint');
  if Assigned(LblPrompt) then
    LblPrompt.Caption := TrText('Assistant.WhatDoYouWant');
  if Assigned(LblRecentQuestions) then
    LblRecentQuestions.Caption := TrText('Assistant.RecentQuestions');
  if Assigned(PnlRecentCombo) then
  begin
    PnlRecentCombo.ShowHint := False;
    PnlRecentCombo.ParentShowHint := False;
    RefreshRecentQuestionsCombo;
  end;
  if Assigned(BtnRecentFind) then
  begin
    BtnRecentFind.Hint := TrText('MRU.FindHint');
    BtnRecentFind.ShowHint := True;
  end;
  if Assigned(EdtRecentFind) then
  begin
    EdtRecentFind.Hint := TrText('MRU.FindHint');
    EdtRecentFind.ShowHint := True;
  end;
  if Assigned(BtnRecentFindClear) then
  begin
    BtnRecentFindClear.Caption := #$00D7;
    BtnRecentFindClear.Hint := TrText('MRU.ClearFind');
    BtnRecentFindClear.ShowHint := True;
  end;
  if Assigned(BtnClearQuestion) then
  begin
    BtnClearQuestion.Caption := #$00D7;
    BtnClearQuestion.Hint := TrText('Assistant.ClearQuestion');
    BtnClearQuestion.ShowHint := True;
  end;
  if Assigned(BtnClearHint) then
  begin
    BtnClearHint.Caption := TrText('Assistant.ClearReply');
    BtnClearHint.Hint := TrText('Assistant.Offer.DraftClearHint');
    BtnClearHint.ShowHint := True;
    SizeQuestionToolBtn(BtnClearHint, ASSISTANT_CLEAR_TOOL_BTN_W);
  end;
  if Assigned(BtnCopyHint) then
  begin
    BtnCopyHint.Caption := TrText('Assistant.CopyReply');
    BtnCopyHint.Hint := TrText('Assistant.Offer.DraftCopyHint');
    BtnCopyHint.ShowHint := True;
    SizeQuestionToolBtn(BtnCopyHint, ASSISTANT_COPY_TOOL_BTN_W);
  end;
  if Assigned(BtnTranslate) then
  begin
    BtnTranslate.Caption := TrText('Assistant.TranslateBtn') + ' ' + #$25BE;
    BtnTranslate.Hint := TrText('Assistant.TranslateHint');
    BtnTranslate.ShowHint := True;
    SizeQuestionToolBtn(BtnTranslate, ASSISTANT_TRANSLATE_BTN_W);
  end;
  if Assigned(BtnRewrite) then
  begin
    BtnRewrite.Caption := TrText('Assistant.RewriteBtn');
    BtnRewrite.Hint := TrText('Assistant.RewriteHint');
    BtnRewrite.ShowHint := True;
    SizeQuestionToolBtn(BtnRewrite, ASSISTANT_REWRITE_BTN_W);
  end;
  LocalizeAgentModeBtn;
  if Assigned(BtnClearReply) then
  begin
    BtnClearReply.Caption := TrText('Assistant.ClearReply');
    BtnClearReply.Hint := TrText('Assistant.ClearReply');
    BtnClearReply.ShowHint := True;
    SizeQuestionToolBtn(BtnClearReply, ASSISTANT_CLEAR_TOOL_BTN_W);
  end;
  if Assigned(BtnCopyReply) then
  begin
    BtnCopyReply.Caption := TrText('Assistant.CopyReply');
    BtnCopyReply.Hint := TrText('Assistant.CopyReply');
    BtnCopyReply.ShowHint := True;
    SizeQuestionToolBtn(BtnCopyReply, ASSISTANT_COPY_TOOL_BTN_W);
  end;
  if Assigned(BtnPython) then
  begin
    BtnPython.Caption := TrText('Assistant.PythonBtn');
    BtnPython.Hint := TrText('Assistant.PythonHint');
    BtnPython.ShowHint := True;
    SizeQuestionToolBtn(BtnPython, ASSISTANT_PYTHON_BTN_W);
  end;
  if Assigned(BtnComposeFormats) then
  begin
    BtnComposeFormats.Caption := '?';
    BtnComposeFormats.Hint := TrText('Assistant.ComposeFormats.Hint');
    BtnComposeFormats.ShowHint := True;
    BtnComposeFormats.Width := ASSISTANT_HELP_TOOL_BTN_W;
    BtnComposeFormats.Height := ASSISTANT_TOOL_BTN_H;
  end;
  if Assigned(LblQuestionCharCount) then
  begin
    LblQuestionCharCount.Hint := TrText('Assistant.CharCountHint');
    LblQuestionCharCount.ShowHint := True;
  end;
  BuildTranslateLangMenu;
  if Assigned(BtnSend) then
    BtnSend.Caption := TrText('Assistant.Send');
  if Assigned(BtnExecute) then
    BtnExecute.Caption := TrText('Assistant.Execute');
  if Assigned(LblDontShowAgain) then
    LblDontShowAgain.Caption := TrText('Assistant.DontShowAgain');
  if Assigned(LblReplyCaption) then
    LblReplyCaption.Caption := TrText('Assistant.Reply');
  if Assigned(LblReplyStyle) then
    LblReplyStyle.Caption := TrText('Assistant.ReplyStyle.Label');
  if Assigned(BtnReplyStyleEdit) then
  begin
    BtnReplyStyleEdit.Caption := TrText('Assistant.ReplyStyle.Edit');
    BtnReplyStyleEdit.Hint := TrText('Assistant.ReplyStyle.EditHint');
    BtnReplyStyleEdit.ShowHint := True;
  end;
  FillReplyStyleCombo;
  LocalizeFileNoticeBanner;
  LocalizeOfferNextBanner;
  UpdateClearQuestionBtn;
  UpdateQuestionCharCount;
  LayoutInputControls(nil);
end;

procedure TFastFileAssistantCtrl.RetranslateRuntimeTexts(OldLang: TAppLanguage);
var
  OldDraft, NewDraft, Cur, NewText, OldSummary: string;
begin
  if OldLang = GetCurrentLanguage then Exit;
  OldSummary := PipelineLastSummary;
  PipelineRetranslateSummary(OldLang);
  if Assigned(LblOfferNext) and (Trim(LblOfferNext.Caption) <> '') then
  begin
    if (OldSummary <> '') and (Trim(LblOfferNext.Caption) = Trim(OldSummary)) then
      LblOfferNext.Caption := PipelineLastSummary
    else
      LblOfferNext.Caption := RetranslateComposedText(LblOfferNext.Caption, OldLang);
  end;
  LayoutOfferActionButtons;
  if Assigned(LblStatus) and (Trim(LblStatus.Caption) <> '') then
  begin
    if (OldSummary <> '') and (Trim(LblStatus.Caption) = Trim(OldSummary)) then
      NewText := PipelineLastSummary
    else
      NewText := RetranslateComposedText(LblStatus.Caption, OldLang);
    if NewText <> LblStatus.Caption then
      SetStatusCaption(NewText);
  end;

  OldDraft := FOfferAiDraft;
  if Trim(OldDraft) <> '' then
  begin
    { Re-render from the structured offer data; text-based retranslation of
      this long composed draft left fragments in the old language. }
    if not AssistantRebuildLastOfferDraft(NewDraft) or (Trim(NewDraft) = '') then
      NewDraft := RetranslateComposedText(OldDraft, OldLang);
    FOfferAiDraft := Trim(NewDraft);
    NewDraft := FOfferAiDraft;
  end
  else
    NewDraft := '';

  { Only auto-filled question text is replaced — never what the user typed. }
  if Assigned(MemoQuestion) then
  begin
    Cur := Trim(MemoQuestion.Text);
    if (Cur <> '') and (OldDraft <> '') and (Cur = Trim(OldDraft)) then
      MemoQuestion.Text := NewDraft
    else if (Cur <> '') and (Length(Cur) <= 400) then
    begin
      NewText := RetranslateComposedText(Cur, OldLang);
      if SameText(NewText, TrText('Assistant.Offer.Draft.Generic')) or
         SameText(NewText, TrText('Assistant.Offer.Draft.Read')) then
        MemoQuestion.Text := NewText;
    end;
  end;

  { Placeholder only; a real AI reply is left untouched. }
  if Assigned(MemoReply) then
  begin
    Cur := Trim(MemoReply.Text);
    if (Cur <> '') and (Length(Cur) <= 400) then
    begin
      NewText := RetranslateComposedText(Cur, OldLang);
      if SameText(NewText, TrText('Assistant.ReplyPlaceholder')) then
        MemoReply.Text := NewText;
    end;
  end;

  if Assigned(PnlOfferNext) then
    LayoutOfferHeadRow;
  UpdateOfferQuestionHint;
end;

procedure TFastFileAssistantCtrl.LblDontShowAgainClick(Sender: TObject);
begin
  if Assigned(ChkDontShowAgain) then
    ChkDontShowAgain.Checked := not ChkDontShowAgain.Checked;
end;

function TFastFileAssistantCtrl.FormatRecentQuestionDisplay(const AQuestion: string): string;
var
  OneLine: string;
begin
  OneLine := StringReplace(Trim(AQuestion), #13#10, ' ', [rfReplaceAll]);
  OneLine := StringReplace(OneLine, #13, ' ', [rfReplaceAll]);
  OneLine := StringReplace(OneLine, #10, ' ', [rfReplaceAll]);
  OneLine := StringReplace(OneLine, #9, ' ', [rfReplaceAll]);
  while Pos('  ', OneLine) > 0 do
    OneLine := StringReplace(OneLine, '  ', ' ', [rfReplaceAll]);
  if Length(OneLine) > ASSISTANT_RECENT_DISPLAY_MAX then
    Result := Copy(OneLine, 1, ASSISTANT_RECENT_DISPLAY_MAX - 3) + '...'
  else
    Result := OneLine;
end;

function TFastFileAssistantCtrl.NormalizeRecentQuestionKey(const AQuestion: string): string;
var
  i: Integer;
  c: Char;
  S: string;
begin
  { Collapse whitespace + fold accents so MRU dedupe survives CRLF vs LF and
    precomposed vs combining diacritics (também vs tambe + U+0301). }
  S := StringReplace(Trim(AQuestion), #13#10, ' ', [rfReplaceAll]);
  S := StringReplace(S, #13, ' ', [rfReplaceAll]);
  S := StringReplace(S, #10, ' ', [rfReplaceAll]);
  S := StringReplace(S, #9, ' ', [rfReplaceAll]);
  while Pos('  ', S) > 0 do
    S := StringReplace(S, '  ', ' ', [rfReplaceAll]);
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if (Ord(c) >= $0300) and (Ord(c) <= $036F) then
      Continue;
    Result := Result + c;
  end;
  Result := LowerCase(FoldDiacriticsForMatch(Result));
end;

function TFastFileAssistantCtrl.EncodeRecentQuestionForIni(const AQuestion: string): string;
begin
  Result := StringReplace(AQuestion, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

function TFastFileAssistantCtrl.DecodeRecentQuestionFromIni(const AEncoded: string): string;
var
  i: Integer;
  S: string;
begin
  Result := '';
  S := AEncoded;
  i := 1;
  while i <= Length(S) do
  begin
    if (S[i] = '\') and (i < Length(S)) then
    begin
      if S[i + 1] = 'n' then
      begin
        Result := Result + #13#10;
        Inc(i, 2);
      end
      else if S[i + 1] = '\' then
      begin
        Result := Result + '\';
        Inc(i, 2);
      end
      else
      begin
        Result := Result + S[i];
        Inc(i);
      end;
    end
    else
    begin
      Result := Result + S[i];
      Inc(i);
    end;
  end;
end;

procedure TFastFileAssistantCtrl.LoadRecentQuestions;
var
  Ini: TIniFile;
  n, i: Integer;
  S: string;
begin
  if not Assigned(FRecentQuestions) then Exit;
  FRecentQuestions.Clear;
  if FIniPath = '' then
  begin
    RefreshRecentQuestionsCombo;
    Exit;
  end;
  Ini := TIniFile.Create(FIniPath);
  try
    n := Ini.ReadInteger(ASSISTANT_RECENT_INI_SECTION, 'Count', 0);
    if n > PrefAssistantRecentMax then
      n := PrefAssistantRecentMax;
    for i := 0 to n - 1 do
    begin
      S := DecodeRecentQuestionFromIni(
        Ini.ReadString(ASSISTANT_RECENT_INI_SECTION, 'Q' + IntToStr(i), ''));
      if Trim(S) <> '' then
        FRecentQuestions.Add(S);
    end;
  finally
    Ini.Free;
  end;
  DeduplicateRecentQuestions;
  FRecentQuestionsExpanded := False;
  RefreshRecentQuestionsCombo;
  SaveRecentQuestions;
end;

procedure TFastFileAssistantCtrl.SaveRecentQuestions;
var
  Ini: TIniFile;
  i, n: Integer;
begin
  if (FIniPath = '') or (not Assigned(FRecentQuestions)) then Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    n := FRecentQuestions.Count;
    if n > PrefAssistantRecentMax then
      n := PrefAssistantRecentMax;
    Ini.WriteInteger(ASSISTANT_RECENT_INI_SECTION, 'Count', n);
    for i := 0 to PrefAssistantRecentMax - 1 do
    begin
      if i < n then
        Ini.WriteString(ASSISTANT_RECENT_INI_SECTION, 'Q' + IntToStr(i),
          EncodeRecentQuestionForIni(FRecentQuestions[i]))
      else
        Ini.DeleteKey(ASSISTANT_RECENT_INI_SECTION, 'Q' + IntToStr(i));
    end;
  finally
    Ini.Free;
  end;
end;

procedure TFastFileAssistantCtrl.DeduplicateRecentQuestions;
var
  i, j: Integer;
  KeyI, KeyJ, DispI, DispJ: string;
begin
  if not Assigned(FRecentQuestions) then Exit;
  i := 0;
  while i < FRecentQuestions.Count do
  begin
    KeyI := NormalizeRecentQuestionKey(FRecentQuestions[i]);
    DispI := FormatRecentQuestionDisplay(FRecentQuestions[i]);
    j := i + 1;
    while j < FRecentQuestions.Count do
    begin
      KeyJ := NormalizeRecentQuestionKey(FRecentQuestions[j]);
      DispJ := FormatRecentQuestionDisplay(FRecentQuestions[j]);
      if (KeyI <> '') and (KeyI = KeyJ) then
        FRecentQuestions.Delete(j)
      else if (DispI <> '') and SameText(DispI, DispJ) then
        FRecentQuestions.Delete(j)
      else
        Inc(j);
    end;
    Inc(i);
  end;
  while FRecentQuestions.Count > PrefAssistantRecentMax do
    FRecentQuestions.Delete(FRecentQuestions.Count - 1);
end;

procedure TFastFileAssistantCtrl.RememberQuestion(const AQuestion: string);
var
  Q, Key, Disp: string;
  i: Integer;
begin
  Q := Trim(AQuestion);
  if (Q = '') or (not Assigned(FRecentQuestions)) then Exit;
  Key := NormalizeRecentQuestionKey(Q);
  Disp := FormatRecentQuestionDisplay(Q);
  for i := FRecentQuestions.Count - 1 downto 0 do
    if (Key <> '') and (NormalizeRecentQuestionKey(FRecentQuestions[i]) = Key) then
      FRecentQuestions.Delete(i)
    else if (Disp <> '') and
            SameText(FormatRecentQuestionDisplay(FRecentQuestions[i]), Disp) then
      FRecentQuestions.Delete(i);
  FRecentQuestions.Insert(0, Q);
  while FRecentQuestions.Count > PrefAssistantRecentMax do
    FRecentQuestions.Delete(FRecentQuestions.Count - 1);
  FRecentQuestionsExpanded := False;
  DeactivateRecentFind;
  RefreshRecentQuestionsCombo;
  SaveRecentQuestions;
end;

procedure TFastFileAssistantCtrl.RefreshRecentQuestionsCombo;
begin
  if not Assigned(PnlRecentCombo) or (not Assigned(FRecentQuestions)) then Exit;
  FSuppressRecentChange := True;
  try
    if FRecentQuestions.Count = 0 then
    begin
      PnlRecentCombo.Enabled := False;
      if Assigned(LblRecentCombo) then
      begin
        LblRecentCombo.Caption := TrText('Assistant.RecentQuestionsEmpty');
        LblRecentCombo.Font.Color := clGrayText;
      end;
      FRecentQuestionsExpanded := False;
      FRecentFindActive := False;
    end
    else
    begin
      PnlRecentCombo.Enabled := True;
      if Assigned(LblRecentCombo) then
      begin
        LblRecentCombo.Caption := '';
        LblRecentCombo.Font.Color := clWindowText;
      end;
    end;
  finally
    FSuppressRecentChange := False;
  end;
end;

procedure TFastFileAssistantCtrl.OpenRecentQuestionsPopup;
begin
  if not Assigned(PnlRecentCombo) or (not PnlRecentCombo.Enabled) then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if FRecentPopupPosted then
    Exit;
  Application.CancelHint;
  ReleaseCapture;
  FRecentPopupPosted := True;
  PostMessage(Handle, WM_FF_ASSISTANT_RECENT_POPUP, 0, 0);
end;

procedure TFastFileAssistantCtrl.RecentComboClick(Sender: TObject);
begin
  Application.CancelHint;
  ReleaseCapture;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    Exit;
  end;
  OpenRecentQuestionsPopup;
end;

procedure TFastFileAssistantCtrl.WMRecentQuestionsPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
  OwnerComp: TComponent;
begin
  FRecentPopupPosted := False;
  ReleaseCapture;
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    FRecentPopupPosted := True;
    PostMessage(Handle, WM_FF_ASSISTANT_RECENT_POPUP, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if not Assigned(FRecentQuestions) or (FRecentQuestions.Count = 0) then Exit;
  if not Assigned(PnlRecentCombo) or (not PnlRecentCombo.Enabled) then Exit;
  if PnlRecentCombo.HandleAllocated then
  begin
    GetWindowRect(PnlRecentCombo.Handle, CR);
    W := CR.Right - CR.Left;
    P := Point(CR.Left, CR.Bottom);
  end
  else
  begin
    W := PnlRecentCombo.Width;
    P := PnlRecentCombo.ClientToScreen(Point(0, PnlRecentCombo.Height));
  end;
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  FPopupMenuOpen := True;
  try
    ShowMruListPopup(OwnerComp, TrText('Assistant.RecentQuestions'),
      MruMoreCaption('Assistant.RecentQuestionsMore'), FRecentQuestions, W, P,
      AssistantMruPick, TrText('Assistant.RecentQuestionsMoreHint'),
      nil, AssistantMruRemove, PnlRecentCombo, AssistantMruClearAll);
  finally
    FPopupMenuOpen := False;
  end;
end;

procedure TFastFileAssistantCtrl.AssistantMruPick(Sender: TObject; const AValue: string;
  AIndex: Integer);
begin
  if not Assigned(MemoQuestion) then Exit;
  MemoQuestion.Text := AValue;
  MemoQuestion.SelStart := Length(MemoQuestion.Text);
  MemoQuestion.SelLength := 0;
  ClampQuestionToMaxChars;
  UpdateClearQuestionBtn;
  UpdateQuestionCharCount;
  if MemoQuestion.CanFocus then
    MemoQuestion.SetFocus;
end;

procedure TFastFileAssistantCtrl.AssistantMruRemove(Sender: TObject; const AValue: string);
var
  i, Idx: Integer;
begin
  { Lista MRU only — never deletes files on disk. }
  if Trim(AValue) = '' then Exit;
  if not Assigned(FRecentQuestions) then Exit;
  Idx := FRecentQuestions.IndexOf(AValue);
  if Idx < 0 then
    for i := 0 to FRecentQuestions.Count - 1 do
      if SameText(FRecentQuestions[i], AValue) then
      begin
        Idx := i;
        Break;
      end;
  if Idx < 0 then Exit;
  FRecentQuestions.Delete(Idx);
  SaveRecentQuestions;
  RefreshRecentQuestionsCombo;
end;

procedure TFastFileAssistantCtrl.AssistantMruClearAll(Sender: TObject);
begin
  if not Assigned(FRecentQuestions) then Exit;
  FRecentQuestions.Clear;
  FRecentQuestionsExpanded := False;
  SaveRecentQuestions;
  RefreshRecentQuestionsCombo;
end;

procedure TFastFileAssistantCtrl.WMRecentQuestionsExpand(var Msg: TMessage);
begin
  OpenRecentQuestionsPopup;
end;

procedure TFastFileAssistantCtrl.WMRecentQuestionsCollapse(var Msg: TMessage);
begin
  if not FRecentQuestionsExpanded then Exit;
  FRecentQuestionsExpanded := False;
  RefreshRecentQuestionsCombo;
end;

procedure TFastFileAssistantCtrl.WMRecentQuestionsFind(var Msg: TMessage);
begin
  if Assigned(EdtRecentFind) and EdtRecentFind.Visible and EdtRecentFind.CanFocus then
    EdtRecentFind.SetFocus
  else
    OpenRecentQuestionsPopup;
end;

procedure TFastFileAssistantCtrl.ApplyRecentFindGlyphs;
begin
  if not Assigned(BtnRecentFind) then Exit;
  if Assigned(FFindImages) and (FFindImageIndex >= 0) then
  begin
    BtnRecentFind.Images := FFindImages;
    BtnRecentFind.ImageIndex := FFindImageIndex;
    BtnRecentFind.ShowCaption := False;
    BtnRecentFind.Caption := '';
  end
  else
  begin
    BtnRecentFind.Images := nil;
    BtnRecentFind.ShowCaption := True;
    BtnRecentFind.Caption := '...';
  end;
end;

procedure TFastFileAssistantCtrl.SetMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
begin
  FFindImages := AImages;
  FFindImageIndex := AFindIndex;
  ApplyRecentFindGlyphs;
end;

procedure TFastFileAssistantCtrl.ActivateRecentFind;
begin
  FActivatingRecentFind := True;
  FRecentFindActive := True;
  FRecentQuestionsExpanded := False;
  LayoutInputControls(nil);
  RefreshRecentQuestionsCombo;
  PostMessage(Handle, WM_FF_ASSISTANT_RECENT_FIND, 0, 0);
end;

procedure TFastFileAssistantCtrl.DeactivateRecentFind;
begin
  if (not FRecentFindActive) and (FRecentFindNeedle = '') then Exit;
  FRecentFindActive := False;
  FRecentFindNeedle := '';
  if Assigned(EdtRecentFind) then
    EdtRecentFind.Text := '';
  LayoutInputControls(nil);
  RefreshRecentQuestionsCombo;
end;

procedure TFastFileAssistantCtrl.BtnRecentFindClick(Sender: TObject);
begin
  if FRecentFindActive then
    DeactivateRecentFind
  else
    ActivateRecentFind;
end;

procedure TFastFileAssistantCtrl.EdtRecentFindChange(Sender: TObject);
begin
  if not Assigned(EdtRecentFind) then Exit;
  FRecentFindNeedle := Trim(EdtRecentFind.Text);
  RefreshRecentQuestionsCombo;
  OpenRecentQuestionsPopup;
end;

procedure TFastFileAssistantCtrl.EdtRecentFindKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    DeactivateRecentFind;
  end;
end;

procedure TFastFileAssistantCtrl.BtnRecentFindClearClick(Sender: TObject);
begin
  DeactivateRecentFind;
end;

function TFastFileAssistantCtrl.ConsumerWaitCaption(const AActionId: string): string;
begin
  if SameText(AActionId, 'consumer_rag') then
    Result := TrText('Assistant.Status.DelegatingRAG')
  else if SameText(AActionId, 'consumer_ai') then
    Result := TrText('Assistant.Status.DelegatingSQL')
  else
    Result := TrText('Assistant.Processing');
end;

procedure TFastFileAssistantCtrl.BeginAssistantWait(const AMsg: string);
var
  Msg, Detail: string;
begin
  Msg := Trim(AMsg);
  if Msg = '' then
    Msg := TrText('Assistant.Processing');
  Detail := TrText('Assistant.ProcessingDetail');
  if FWaitOverlayOwned and TfrmSmoothLoading.IsShowing then
  begin
    TfrmSmoothLoading.SetWaitTexts(Msg, Detail);
    TfrmSmoothLoading.SetIndeterminate(False);
  end
  else if TfrmSmoothLoading.IsShowing then
  begin
    { Another file/op overlay is up — do not steal it. }
  end
  else
  begin
    TfrmSmoothLoading.ShowLoading(Msg, True);
    TfrmSmoothLoading.SnapFullyOpaque;
    TfrmSmoothLoading.SetWaitTexts(Msg, Detail);
    TfrmSmoothLoading.SetIndeterminate(False);
    TfrmSmoothLoading.UpdateProgress(4);
    FWaitOverlayOwned := True;
    FWaitAllowCreep := True;
  end;
  if FWaitOverlayOwned then
    FWaitAllowCreep := True;
  if FWaitOverlayOwned and Assigned(FTmrWaitCancel) then
    FTmrWaitCancel.Enabled := True;
  TfrmSmoothLoading.FlushPaint;
end;

procedure TFastFileAssistantCtrl.UpdateAssistantWait(const AMsg: string);
begin
  if not FWaitOverlayOwned then Exit;
  if not TfrmSmoothLoading.IsShowing then
  begin
    FWaitOverlayOwned := False;
    FWaitAllowCreep := False;
    if Assigned(FTmrWaitCancel) then
      FTmrWaitCancel.Enabled := False;
    Exit;
  end;
  { Texts only — never reset the bar to marquee/0 (that looped 0..100). }
  TfrmSmoothLoading.SetWaitTexts(AMsg, TrText('Assistant.ProcessingDetail'));
end;

procedure TFastFileAssistantCtrl.ApplyAiNetProgress(APercent: Integer; const APhase: string);
var
  Detail: string;
  Pct: Integer;
begin
  if not FWaitOverlayOwned then Exit;
  if not TfrmSmoothLoading.IsShowing then Exit;
  Pct := APercent;
  if Pct < 0 then Pct := 0;
  if Pct > 99 then Pct := 99;
  if SameText(APhase, 'connect') then
    Detail := TrText('Assistant.Wait.Connecting')
  else if SameText(APhase, 'send') then
    Detail := TrText('Assistant.Wait.Sending')
  else if SameText(APhase, 'wait') then
    Detail := TrText('Assistant.Wait.WaitingModel')
  else if SameText(APhase, 'recv') then
    Detail := TrText('Assistant.Wait.Receiving')
  else
    Detail := TrText('Assistant.ProcessingDetail');
  { After headers/body start arriving, stop the unknown-wait creep. }
  if Pct >= 40 then
    FWaitAllowCreep := False;
  TfrmSmoothLoading.SetWaitTexts(TrText('Assistant.Processing'), Detail);
  TfrmSmoothLoading.SetIndeterminate(False);
  TfrmSmoothLoading.UpdateProgressMonotonic(Pct);
end;

procedure TFastFileAssistantCtrl.EndAssistantWait;
begin
  if Assigned(FTmrWaitCancel) then
    FTmrWaitCancel.Enabled := False;
  FWaitAllowCreep := False;
  if FWaitOverlayOwned then
  begin
    FWaitOverlayOwned := False;
    if TfrmSmoothLoading.IsShowing then
      TfrmSmoothLoading.HideLoading;
  end;
end;

function TFastFileAssistantCtrl.AssistantActionHasOwnSmoothLoading(const AActionId: string): Boolean;
begin
  Result := SameText(AActionId, 'open_and_read_file') or
    SameText(AActionId, 'apply_filter') or
    SameText(AActionId, 'split_equal_parts') or
    SameText(AActionId, 'extract_file_parts') or
    SameText(AActionId, 'show_tab_merge_files') or
    SameText(AActionId, 'export_lines') or
    SameText(AActionId, 'export_matching_lines') or
    SameText(AActionId, 'replace_all') or
    SameText(AActionId, 'clear_file');
end;

procedure TFastFileAssistantCtrl.BeginFileCountWait;
begin
  FCountProgLastTick := 0;
  FCountProgLastPct := -1;
  FWaitAllowCreep := False;
  if not FWaitOverlayOwned then
    BeginAssistantWait(TrText('Assistant.CountingFile'))
  else
    UpdateAssistantWait(TrText('Assistant.CountingFile'));
  FWaitAllowCreep := False;
  if FWaitOverlayOwned and TfrmSmoothLoading.IsShowing then
  begin
    TfrmSmoothLoading.SetWaitTexts(TrText('Assistant.CountingFile'),
      TrText('Assistant.CountingDetail'));
    TfrmSmoothLoading.SetIndeterminate(False);
    TfrmSmoothLoading.UpdateProgress(0);
    TfrmSmoothLoading.FlushPaint;
  end;
end;

procedure TFastFileAssistantCtrl.CountScanProgress(APercent: Integer; var ACancel: Boolean);
var
  NowTick: Cardinal;
begin
  ACancel := FAiCancelled or TfrmSmoothLoading.CancelRequested;
  if ACancel then Exit;
  NowTick := GetTickCount;
  if (APercent = FCountProgLastPct) and (FCountProgLastTick <> 0) and
     ((NowTick - FCountProgLastTick) < 120) then
    Exit;
  FCountProgLastPct := APercent;
  FCountProgLastTick := NowTick;
  FWaitAllowCreep := False;
  if FWaitOverlayOwned and TfrmSmoothLoading.IsShowing then
  begin
    TfrmSmoothLoading.SetIndeterminate(False);
    TfrmSmoothLoading.UpdateProgress(APercent);
  end;
  Application.ProcessMessages;
  ACancel := FAiCancelled or TfrmSmoothLoading.CancelRequested;
end;

procedure TFastFileAssistantCtrl.TmrWaitCancelTimer(Sender: TObject);
begin
  if not FWaitOverlayOwned then
  begin
    if Assigned(FTmrWaitCancel) then
      FTmrWaitCancel.Enabled := False;
    Exit;
  end;
  if TfrmSmoothLoading.CancelRequested then
  begin
    FAiCancelled := True;
    EndAssistantWait;
    SetStatusCaption(TrText('Assistant.Cancelled'));
    if Assigned(MemoReply) and (Trim(MemoReply.Text) = '') then
      MemoReply.Lines.Text := TrText('Assistant.Cancelled');
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  { Unknown-duration wait (model thinking): creep forward, never wrap to 0. }
  if FWaitAllowCreep and TfrmSmoothLoading.IsShowing then
    TfrmSmoothLoading.CreepProgress(78);
end;

procedure TFastFileAssistantCtrl.SetStatusCaption(const ACaption: string);
var
  Cap: string;
begin
  if not Assigned(LblStatus) then Exit;
  Cap := Trim(ACaption);
  LblStatus.Caption := Cap;
  if Cap = '' then
    LblStatus.Font.Color := FChromeMuted
  else if SameText(Cap, TrText('Assistant.Done')) or
          SameText(Cap, TrText('Assistant.ReplyReady')) then
    LblStatus.Font.Color := ASSISTANT_STATUS_OK
  else
    LblStatus.Font.Color := ColorToRGB(clHighlight);
  LayoutInputControls(nil);
end;

function MeasureAssistantWrappedTextHeight(AControl: TControl; const AText: string;
  AWidth: Integer; AMinH: Integer): Integer;
var
  R: TRect;
  Canvas: TControlCanvas;
  Flags: Longint;
begin
  Result := AMinH;
  if not Assigned(AControl) or (AWidth <= 0) then Exit;
  if Trim(AText) = '' then Exit;
  Canvas := TControlCanvas.Create;
  try
    Canvas.Control := AControl;
    R := Rect(0, 0, AWidth, 0);
    Flags := DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX or DT_LEFT;
    DrawText(Canvas.Handle, PChar(AText), -1, R, Flags);
    if R.Bottom - R.Top > Result then
      Result := R.Bottom - R.Top;
  finally
    Canvas.Free;
  end;
end;

procedure ForceAssistantPanelColor(APnl: TsPanel; AColor: TColor);
begin
  if not Assigned(APnl) then Exit;
  try
    APnl.SkinData.CustomColor := True;
    APnl.SkinData.SkinSection := 'TRANSPARENT';
  except
  end;
  APnl.ParentBackground := False;
  APnl.ParentColor := False;
  APnl.Color := AColor;
end;

procedure TFastFileAssistantCtrl.UpdateQuestionFocusChrome(AFocused: Boolean);
begin
  if not Assigned(PnlQuestionShell) then Exit;
  if AFocused then
    ForceAssistantPanelColor(PnlQuestionShell, ColorToRGB(clHighlight))
  else
    ForceAssistantPanelColor(PnlQuestionShell, FChromeBorder);
end;

procedure TFastFileAssistantCtrl.ApplyAssistantSoftChrome;
var
  UiFont: string;
  HdrTop, HdrBot: TColor;
begin
  if not FLayoutBuilt then Exit;
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    UiFont := 'Segoe UI'
  else
    UiFont := 'Tahoma';

  { Match main window: toolbar greys (sel 1–2) + idle workspace blue (sel 3). }
  FChromeSurf := ColorToRGB(ASSISTANT_TOOLBAR_MID);
  FChromeCard := ColorToRGB(IDLE_WORKSPACE_GRAD_LEFT); { soft blue-white, not stark }
  FChromeTitle := ColorToRGB(clWindowText);
  FChromeAccent := ColorToRGB(IDLE_WORKSPACE_GRAD_RIGHT); { soft sky accent }
  FChromeBorder := ColorToRGB(ASSISTANT_TOOLBAR_EDGE);
  FChromeMuted := AssistantBlendColor(FChromeTitle, FChromeSurf, 35);
  HdrTop := ColorToRGB(ASSISTANT_TOOLBAR_LIGHT);
  HdrBot := ColorToRGB(ASSISTANT_TOOLBAR_MID);

  Font.Name := UiFont;
  Font.Size := 9;
  ForceAssistantPanelColor(Self, FChromeSurf);

  ForceAssistantPanelColor(PnlAccent, FChromeAccent);
  if Assigned(PnlAccent) then
  begin
    PnlAccent.Width := ASSISTANT_ACCENT_W;
    PnlAccent.Visible := ASSISTANT_ACCENT_W > 0;
  end;
  ForceAssistantPanelColor(PnlHeader, HdrBot);
  if Assigned(PnlHeader) then
  begin
    PnlHeader.GradTop := HdrTop;
    PnlHeader.GradBot := HdrBot;
    PnlHeader.Invalidate;
  end;
  ForceAssistantPanelColor(PnlHeaderSep, FChromeBorder);
  ForceAssistantPanelColor(PnlShortcutBadgeShell, FChromeBorder);
  ForceAssistantPanelColor(PnlShortcutBadge, ColorToRGB(ASSISTANT_BADGE_BG));
  ForceAssistantPanelColor(PnlInput, FChromeSurf);
  if Assigned(MemoQuestion) and MemoQuestion.Focused then
    ForceAssistantPanelColor(PnlQuestionShell, ColorToRGB(clHighlight))
  else
    ForceAssistantPanelColor(PnlQuestionShell, FChromeBorder);
  { Question edit stays true window white for typing clarity. }
  ForceAssistantPanelColor(PnlQuestionFrame, ColorToRGB(clWindow));
  ForceAssistantPanelColor(PnlQuestionTools, ColorToRGB(ASSISTANT_TOOLBAR_MID));
  ForceAssistantPanelColor(PnlQuestionToolsSep, FChromeBorder);
  ForceAssistantPanelColor(PnlReply, FChromeSurf);
  ForceAssistantPanelColor(PnlReplyCapRow, FChromeSurf);
  ForceAssistantPanelColor(PnlReplyStyleRow, FChromeSurf);
  ForceAssistantPanelColor(PnlReplyCapAccent, FChromeAccent);
  if Assigned(PnlReplyCapAccent) then
  begin
    PnlReplyCapAccent.Width := ASSISTANT_CAP_ACCENT_W;
    PnlReplyCapAccent.Visible := ASSISTANT_CAP_ACCENT_W > 0;
  end;
  ForceAssistantPanelColor(PnlReplyShell, FChromeBorder);
  ForceAssistantPanelColor(PnlReplySurface, FChromeCard);

  if Assigned(LblTitle) then
  begin
    LblTitle.ParentFont := False;
    LblTitle.Font.Name := UiFont;
    LblTitle.Font.Size := 13;
    LblTitle.Font.Style := [fsBold];
    LblTitle.Font.Color := FChromeTitle;
  end;
  if Assigned(LblShortcut) then
  begin
    LblShortcut.ParentFont := False;
    LblShortcut.Font.Name := UiFont;
    LblShortcut.Font.Size := 8;
    LblShortcut.Font.Style := [];
    LblShortcut.Font.Color := FChromeMuted;
  end;
  if Assigned(BtnHide) then
  begin
    BtnHide.ParentFont := False;
    BtnHide.Font.Name := UiFont;
    BtnHide.Font.Size := 13;
    BtnHide.Font.Style := [];
    BtnHide.Font.Color := FChromeMuted;
  end;
  if Assigned(BtnFloat) then
  begin
    BtnFloat.ParentFont := False;
    BtnFloat.Font.Name := UiFont;
    BtnFloat.Font.Size := 11;
    BtnFloat.Font.Style := [];
    BtnFloat.Font.Color := FChromeMuted;
  end;
  if Assigned(LblPrompt) then
  begin
    LblPrompt.ParentFont := False;
    LblPrompt.Font.Name := UiFont;
    LblPrompt.Font.Size := 11;
    LblPrompt.Font.Style := [fsBold];
    LblPrompt.Font.Color := FChromeTitle;
  end;
  if Assigned(MemoDraftHint) then
  begin
    MemoDraftHint.ParentFont := False;
    MemoDraftHint.Font.Name := UiFont;
    MemoDraftHint.Font.Size := 8;
    MemoDraftHint.Font.Style := [fsItalic];
    MemoDraftHint.Font.Color := clGrayText;
  end;
  if Assigned(LblRecentQuestions) then
  begin
    LblRecentQuestions.ParentFont := False;
    LblRecentQuestions.Font.Name := UiFont;
    LblRecentQuestions.Font.Size := 8;
    LblRecentQuestions.Font.Style := [];
    LblRecentQuestions.Font.Color := FChromeMuted;
  end;
  if Assigned(LblReplyCaption) then
  begin
    LblReplyCaption.ParentFont := False;
    LblReplyCaption.Font.Name := UiFont;
    LblReplyCaption.Font.Size := 9;
    LblReplyCaption.Font.Style := [fsBold];
    LblReplyCaption.Font.Color := FChromeTitle;
  end;
  if Assigned(LblStatus) then
  begin
    LblStatus.ParentFont := False;
    LblStatus.Font.Name := UiFont;
    LblStatus.Font.Size := 8;
    if Trim(LblStatus.Caption) = '' then
      LblStatus.Font.Color := FChromeMuted;
  end;
  if Assigned(MemoQuestion) then
  begin
    MemoQuestion.ParentColor := False;
    MemoQuestion.Color := clWindow;
    MemoQuestion.BorderStyle := bsNone;
    MemoQuestion.ParentFont := False;
    MemoQuestion.Font.Name := UiFont;
    MemoQuestion.Font.Size := 10;
    MemoQuestion.Font.Charset := DEFAULT_CHARSET;
    MemoQuestion.Font.Color := FChromeTitle;
  end;
  if Assigned(BtnClearQuestion) then
  begin
    BtnClearQuestion.ParentFont := False;
    BtnClearQuestion.Font.Name := UiFont;
    BtnClearQuestion.Font.Size := 11;
    BtnClearQuestion.Font.Color := FChromeMuted;
  end;
  StyleQuestionToolBtn(BtnTranslate);
  StyleQuestionToolBtn(BtnRewrite);
  StyleQuestionToolBtn(BtnReplyStyleEdit);
  StyleQuestionToolBtn(BtnClearReply);
  StyleQuestionToolBtn(BtnCopyReply);
  StyleQuestionToolBtn(BtnClearHint);
  StyleQuestionToolBtn(BtnCopyHint);
  StyleQuestionToolBtn(BtnPython);
  StyleQuestionToolBtn(BtnComposeFormats);
  if Assigned(LblQuestionCharCount) then
  begin
    LblQuestionCharCount.ParentFont := False;
    LblQuestionCharCount.Font.Name := UiFont;
    LblQuestionCharCount.Font.Size := 8;
    LblQuestionCharCount.Font.Style := [];
    LblQuestionCharCount.Font.Color := FChromeMuted;
  end;
  if Assigned(PnlRecentCombo) then
  begin
    PnlRecentCombo.ParentColor := False;
    PnlRecentCombo.ParentBackground := False;
    PnlRecentCombo.Color := clWindow;
  end;
  if Assigned(LblRecentCombo) then
  begin
    LblRecentCombo.ParentFont := False;
    LblRecentCombo.Font.Name := UiFont;
    LblRecentCombo.Font.Size := 9;
  end;
  if Assigned(EdtRecentFind) then
  begin
    EdtRecentFind.ParentColor := False;
    EdtRecentFind.Color := clWindow;
    EdtRecentFind.ParentFont := False;
    EdtRecentFind.Font.Name := UiFont;
    EdtRecentFind.Font.Size := 9;
  end;
  if Assigned(BtnSend) then
  begin
    BtnSend.ParentFont := False;
    BtnSend.Font.Name := UiFont;
    BtnSend.Font.Size := 10;
    BtnSend.Font.Style := [fsBold];
    BtnSend.Default := False;
  end;
  if Assigned(BtnExecute) then
  begin
    BtnExecute.ParentFont := False;
    BtnExecute.Font.Name := UiFont;
    BtnExecute.Font.Size := 9;
    BtnExecute.Font.Style := [fsBold];
  end;
  if Assigned(LblDontShowAgain) then
  begin
    LblDontShowAgain.ParentFont := False;
    LblDontShowAgain.Font.Name := UiFont;
    LblDontShowAgain.Font.Size := 8;
    LblDontShowAgain.Font.Color := FChromeMuted;
  end;
  if Assigned(MemoReply) then
  begin
    MemoReply.ParentColor := False;
    MemoReply.Color := FChromeCard;
    MemoReply.BorderStyle := bsNone;
    MemoReply.ParentFont := False;
    MemoReply.Font.Name := UiFont;
    MemoReply.Font.Size := 10;
    MemoReply.Font.Color := FChromeTitle;
  end;
  ForceAssistantPanelColor(PnlFileNotice, ColorToRGB(ASSISTANT_FILE_NOTICE_EDGE));
  ForceAssistantPanelColor(PnlFileNoticeInner, ColorToRGB(ASSISTANT_FILE_NOTICE_BG));
  ForceAssistantPanelColor(PnlFileNoticeAccent, ColorToRGB(ASSISTANT_FILE_NOTICE_ACCENT));
  ForceAssistantPanelColor(PnlFileNoticeContent, ColorToRGB(ASSISTANT_FILE_NOTICE_BG));
  ForceAssistantPanelColor(PnlFileNoticeHead, ColorToRGB(ASSISTANT_FILE_NOTICE_BG));
  ForceAssistantPanelColor(PnlFileNoticeActions, ColorToRGB(ASSISTANT_FILE_NOTICE_BG));
  StyleQuestionToolBtn(BtnFileNoticeOpen);
  StyleQuestionToolBtn(BtnFileNoticeFolder);
  StyleQuestionToolBtn(BtnFileNoticeCopy);
  StyleQuestionToolBtn(BtnFileNoticeValidate);
  StyleQuestionToolBtn(BtnFileNoticeDismiss);
  if Assigned(LblFileNoticeTitle) then
  begin
    LblFileNoticeTitle.ParentFont := False;
    LblFileNoticeTitle.Font.Name := UiFont;
    LblFileNoticeTitle.Font.Size := 9;
    LblFileNoticeTitle.Font.Style := [fsBold];
    LblFileNoticeTitle.Font.Color := ASSISTANT_STATUS_OK;
  end;
  if Assigned(LblFileNoticeFile) then
  begin
    LblFileNoticeFile.ParentFont := False;
    LblFileNoticeFile.Font.Name := UiFont;
    LblFileNoticeFile.Font.Size := 8;
    StyleFileNoticeHyperlink(LblFileNoticeFile);
  end;
  if Assigned(LblFileNoticeDir) then
  begin
    LblFileNoticeDir.ParentFont := False;
    LblFileNoticeDir.Font.Name := UiFont;
    LblFileNoticeDir.Font.Size := 8;
    StyleFileNoticeHyperlink(LblFileNoticeDir);
  end;
  if Assigned(LblFileNoticeHint) then
  begin
    LblFileNoticeHint.ParentFont := False;
    LblFileNoticeHint.Font.Name := UiFont;
    LblFileNoticeHint.Font.Size := 7;
    LblFileNoticeHint.Font.Color := FChromeMuted;
  end;
  LayoutFileNoticeActions;
  UpdateQuestionCharCount;
  SyncAssistantMemoScrollBars;
end;

procedure TFastFileAssistantCtrl.RefreshAssistantSurfaceColor;
begin
  ApplyAssistantSoftChrome;
end;

procedure TFastFileAssistantCtrl.AssistantMemoSelectAll(AMemo: TMemo);
begin
  if not Assigned(AMemo) then Exit;
  AMemo.SelStart := 0;
  AMemo.SelLength := Length(AMemo.Text);
end;

function TFastFileAssistantCtrl.CopyAssistantMemoToClipboard(AMemo: TMemo): Boolean;
begin
  Result := False;
  if not Assigned(AMemo) then Exit;
  if AMemo.SelLength > 0 then
  begin
    AMemo.CopyToClipboard;
    Result := True;
    Exit;
  end;
  if Trim(AMemo.Text) <> '' then
  begin
    Clipboard.AsText := AMemo.Text;
    Result := True;
  end;
end;

procedure TFastFileAssistantCtrl.AssistantMemoEnter(Sender: TObject);
begin
  if Sender is TMemo then
    FLastAssistantMemo := TMemo(Sender);
  if Sender = MemoQuestion then
    UpdateQuestionFocusChrome(True);
end;

procedure TFastFileAssistantCtrl.AssistantMemoExit(Sender: TObject);
begin
  if Sender = MemoQuestion then
    UpdateQuestionFocusChrome(False);
end;

function TFastFileAssistantCtrl.AssistantFocusedMemo: TMemo;
var
  H: HWND;
begin
  Result := nil;
  H := GetFocus;
  if Assigned(MemoQuestion) and (H = MemoQuestion.Handle) then
    Result := MemoQuestion
  else if Assigned(MemoReply) and (H = MemoReply.Handle) then
    Result := MemoReply;
end;

procedure TFastFileAssistantCtrl.AssistantInvokeAction(const AActionId: string);
var
  St: TAssistantChainStep;
begin
  if not FastFileAssistantHostReady then Exit;
  if Trim(AActionId) = '' then Exit;
  FillChar(St, SizeOf(St), 0);
  St.ActionId := AActionId;
  AssistantHostExecuteAction(St);
end;

procedure TFastFileAssistantCtrl.AssistantInvokeFileUndo;
begin
  AssistantInvokeAction('undo');
end;

procedure TFastFileAssistantCtrl.AssistantInvokeFileRedo;
begin
  AssistantInvokeAction('redo');
end;

function TFastFileAssistantCtrl.AssistantNormalizeShortcutKey(Key: Word): Word;
begin
  Result := Key;
  if (Result >= Ord('a')) and (Result <= Ord('z')) then
    Result := Result - Ord('a') + Ord('A');
end;

function TFastFileAssistantCtrl.AssistantHandleShortcut(var Key: Word; Shift: TShiftState): Boolean;
var
  K: Word;
  M: TMemo;
  ActId: string;
begin
  Result := False;
  if not Visible then Exit;

  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    { Typing in question: first ESC clears; second ESC closes panel. }
    if Assigned(MemoQuestion) and (GetFocus = MemoQuestion.Handle) and
      (Trim(MemoQuestion.Text) <> '') then
      ClearQuestionText
    else
      HideFastFileAssistantPanel;
    Result := True;
    Key := 0;
    Exit;
  end;

  if not FastFileAssistantHostReady then Exit;

  K := AssistantNormalizeShortcutKey(Key);

  if Key = VK_INSERT then
  begin
    if Shift = [ssCtrl] then
    begin
      { Ctrl+Insert: copy from assistant memo only — never ListView selection. }
      M := AssistantFocusedMemo;
      if not Assigned(M) then
        M := MemoReply;
      if Assigned(M) then
      begin
        if M.SelLength > 0 then
          M.CopyToClipboard
        else if Trim(M.Text) <> '' then
          Clipboard.AsText := M.Text;
      end;
      Result := True;
      Key := 0;
    end;
    Exit;
  end;

  if not (ssCtrl in Shift) or (ssAlt in Shift) then Exit;

  { Ctrl+V / Shift+Insert no memo do assistente: colar no memo, NUNCA no ficheiro aberto. }
  if ((K = Ord('V')) and not (ssShift in Shift)) or
     ((Key = VK_INSERT) and (ssShift in Shift) and not (ssCtrl in Shift)) then
  begin
    M := AssistantFocusedMemo;
    if Assigned(M) and (not M.ReadOnly) then
    begin
      M.PasteFromClipboard;
      Result := True;
      Key := 0;
      Exit;
    end;
    { Swallow paste when reply (read-only) focused — do not paste into open file. }
    if Assigned(M) then
    begin
      Result := True;
      Key := 0;
    end;
    Exit;
  end;

  if (ssShift in Shift) then
  begin
    { Ctrl+Shift+* tool shortcuts while assistant focused: do not steal — leave to main form
      only when not editing assistant text. Swallow while typing in question memo. }
    M := AssistantFocusedMemo;
    if Assigned(M) and (not M.ReadOnly) then
    begin
      Result := False;
      Exit;
    end;
    case K of
      Ord('L'): ActId := 'export_filtered';
      Ord('F'): ActId := 'find_in_files';
      Ord('K'): ActId := 'split_files';
      Ord('P'): ActId := 'split_equal_parts';
      Ord('Q'): ActId := 'extract_file_parts';
      Ord('M'): ActId := 'show_tab_merge_lines';
      Ord('J'): ActId := 'show_tab_merge_files';
      Ord('H'): ActId := 'show_tab_compare';
      Ord('O'): ActId := 'export_file';
      Ord('S'): ActId := 'show_checkboxes';
      Ord('T'): ActId := 'pause_tail';
      Ord('N'): ActId := 'insert_multiple_lines';
      else ActId := '';
    end;
  end
  else
  begin
    case K of
      Ord('Z'), Ord('Y'):
        begin
          { Never undo/redo the open file from the assistant panel. }
          Result := True;
          Key := 0;
          Exit;
        end;
      Ord('H'): ActId := 'open_replace';
      Ord('F'): ActId := 'open_find';
      Ord('L'): ActId := 'open_filter';
      Ord('T'): ActId := 'start_tail';
      Ord('G'): ActId := 'goto_line';
      Ord('B'): ActId := 'toggle_bookmark';
      Ord('W'): ActId := 'toggle_word_wrap';
      Ord('C'):
        begin
          M := AssistantFocusedMemo;
          if not Assigned(M) then
            M := MemoReply;
          if Assigned(M) then
          begin
            if M.SelLength > 0 then
              M.CopyToClipboard
            else if Trim(M.Text) <> '' then
              Clipboard.AsText := M.Text;
          end;
          Result := True;
          Key := 0;
          Exit;
        end;
      Ord('V'): ActId := '';
      Ord('A'):
        begin
          M := AssistantFocusedMemo;
          if Assigned(M) then
            AssistantMemoSelectAll(M);
          Result := True;
          Key := 0;
          Exit;
        end;
      Ord('X'):
        begin
          { Sempre consumir Ctrl+X no memo do assistente (evita ActionList Sair/Fechar). }
          M := AssistantFocusedMemo;
          if Assigned(M) then
          begin
            if (not M.ReadOnly) and (M.SelLength > 0) then
              M.CutToClipboard;
            Result := True;
            Key := 0;
          end;
          Exit;
        end;
      else ActId := '';
    end;
  end;

  if (K = Ord('P')) and (ssCtrl in Shift) and (ssAlt in Shift) then
    ActId := 'pattern_split';

  if ActId = '' then Exit;

  AssistantInvokeAction(ActId);
  Result := True;
  Key := 0;
end;

function TFastFileAssistantCtrl.HandleEnterKey(var Key: Word; Shift: TShiftState): Boolean;
var
  H: HWND;
begin
  Result := False;
  if Key <> VK_RETURN then Exit;
  if ssAlt in Shift then Exit;
  { Traduzir / MRU popups: Enter selects the item — never Enviar. }
  if FPopupMenuOpen then Exit;
  if FBusy then
  begin
    Result := True;
    Key := 0;
    Exit;
  end;
  if not Assigned(MemoQuestion) or (not MemoQuestion.HandleAllocated) then Exit;
  H := GetFocus;
  if (H <> MemoQuestion.Handle) and (not MemoQuestion.Focused) then Exit;

  Result := True;
  Key := 0;
  if ssShift in Shift then
  begin
    MemoQuestion.SelText := #13#10;
    Exit;
  end;
  if Assigned(BtnSend) and BtnSend.Enabled then
    BtnSend.Click;
end;

procedure TFastFileAssistantCtrl.AssistantMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  M: TMemo;
begin
  if HandleEnterKey(Key, Shift) then Exit;
  if (Key = VK_TAB) and (not (ssShift in Shift)) and (Sender = MemoQuestion) and
     Assigned(BtnSend) and BtnSend.Visible and BtnSend.Enabled and BtnSend.CanFocus then
  begin
    BtnSend.SetFocus;
    Key := 0;
    Exit;
  end;
  if AssistantHandleShortcut(Key, Shift) then Exit;
  if (ssCtrl in Shift) and not (ssShift in Shift) and not (ssAlt in Shift) and
     (AssistantNormalizeShortcutKey(Key) = Ord('X')) and (Sender is TMemo) then
  begin
    M := TMemo(Sender);
    if (not M.ReadOnly) and (M.SelLength > 0) then
      M.CutToClipboard;
    Key := 0;
  end;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupUndoFile(Sender: TObject);
begin
  AssistantInvokeFileUndo;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupRedoFile(Sender: TObject);
begin
  AssistantInvokeFileRedo;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupSelectAll(Sender: TObject);
var
  M: TMemo;
begin
  if Sender is TMenuItem then
    M := TMemo(TMenuItem(Sender).Tag)
  else
    M := nil;
  AssistantMemoSelectAll(M);
  if Assigned(M) then
    M.SetFocus;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupCopy(Sender: TObject);
var
  M: TMemo;
begin
  if Sender is TMenuItem then
    M := TMemo(TMenuItem(Sender).Tag)
  else
    M := nil;
  if Assigned(M) and (M.SelLength > 0) then
    M.CopyToClipboard;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupCut(Sender: TObject);
var
  M: TMemo;
begin
  if Sender is TMenuItem then
    M := TMemo(TMenuItem(Sender).Tag)
  else
    M := nil;
  if Assigned(M) and (not M.ReadOnly) and (M.SelLength > 0) then
    M.CutToClipboard;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupPaste(Sender: TObject);
var
  M: TMemo;
begin
  if Sender is TMenuItem then
    M := TMemo(TMenuItem(Sender).Tag)
  else
    M := nil;
  if Assigned(M) and (not M.ReadOnly) then
    M.PasteFromClipboard;
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupPasteFile(Sender: TObject);
begin
  AssistantInvokeAction('paste_lines');
end;

procedure TFastFileAssistantCtrl.AssistantMemoPopupPopup(Sender: TObject);
var
  M: TMemo;
  Pop: TPopupMenu;
  i: Integer;
begin
  if not (Sender is TPopupMenu) then Exit;
  Pop := TPopupMenu(Sender);
  M := nil;
  for i := 0 to Pop.Items.Count - 1 do
    if Pop.Items[i].Tag <> 0 then
    begin
      M := TMemo(Pop.Items[i].Tag);
      Break;
    end;
  if not Assigned(M) then Exit;
  { 0=SelectAll 2=Copy 4=Cut 6=Paste }
  if Pop.Items.Count > 0 then
    Pop.Items[0].Enabled := Length(M.Text) > 0;
  if Pop.Items.Count > 2 then
    Pop.Items[2].Enabled := M.SelLength > 0;
  if Pop.Items.Count > 4 then
    Pop.Items[4].Enabled := (not M.ReadOnly) and (M.SelLength > 0);
  if Pop.Items.Count > 6 then
    Pop.Items[6].Enabled := not M.ReadOnly;
end;

procedure TFastFileAssistantCtrl.BuildMemoPopupMenus;
  function AddMemoPopupItem(APop: TPopupMenu; const ACaption: string; AClick: TNotifyEvent;
    AMemo: TMemo): TMenuItem;
  begin
    Result := TMenuItem.Create(APop);
    Result.Caption := ACaption;
    Result.OnClick := AClick;
    Result.Tag := Integer(AMemo);
    APop.Items.Add(Result);
  end;
  procedure BuildOne(AMemo: TMemo; var APop: TPopupMenu);
  var
    Sep: TMenuItem;
  begin
    if Assigned(APop) then
    begin
      APop.Free;
      APop := nil;
    end;
    APop := TPopupMenu.Create(Self);
    APop.OnPopup := AssistantMemoPopupPopup;
    { Memo-local only — never paste/undo the open file from assistant context menu. }
    AddMemoPopupItem(APop, TrText('Select all') + ' (Ctrl+A)', AssistantMemoPopupSelectAll, AMemo);
    Sep := TMenuItem.Create(APop);
    APop.Items.Add(Sep);
    Sep.Caption := '-';
    AddMemoPopupItem(APop, TrText('Copy') + ' (Ctrl+C)', AssistantMemoPopupCopy, AMemo);
    Sep := TMenuItem.Create(APop);
    APop.Items.Add(Sep);
    Sep.Caption := '-';
    AddMemoPopupItem(APop, TrText('Cut') + ' (Ctrl+X)', AssistantMemoPopupCut, AMemo);
    Sep := TMenuItem.Create(APop);
    APop.Items.Add(Sep);
    Sep.Caption := '-';
    AddMemoPopupItem(APop, TrText('Paste') + ' (Ctrl+V)', AssistantMemoPopupPaste, AMemo);
    AMemo.PopupMenu := APop;
    AMemo.OnKeyDown := AssistantMemoKeyDown;
    AMemo.OnEnter := AssistantMemoEnter;
    AMemo.OnExit := AssistantMemoExit;
  end;
begin
  BuildOne(MemoQuestion, FPopupQuestion);
  if Assigned(MemoReply) then
    BuildOne(MemoReply, FPopupReply);
end;

function TFastFileAssistantCtrl.FormatAssistantElapsedMs(AMs: Cardinal): string;
begin
  if AMs < 1000 then
    Result := IntToStr(AMs) + ' ms'
  else if AMs < 60000 then
    Result := Format('%.2f s', [AMs / 1000])
  else
    Result := Format('%.1f min', [AMs / 60000]);
end;

function TFastFileAssistantCtrl.BuildReplyWithTiming(const ABody: string;
  AIncludeExec: Boolean): string;
begin
  Result := ClampAssistantDisplayText(ABody);
  if FMsLastAi > 0 then
    Result := Result + #13#10#13#10 + Format(TrText('Assistant.ElapsedAi'),
      [FormatAssistantElapsedMs(FMsLastAi)]);
  if AIncludeExec and (FMsLastExec > 0) then
    Result := Result + #13#10 + Format(TrText('Assistant.ElapsedExecute'),
      [FormatAssistantElapsedMs(FMsLastExec)]);
end;

procedure TFastFileAssistantCtrl.SyncMemoAutoVertScroll(AMemo: TMemo);
var
  LineCount, LineH: Integer;
  NeedBar: Boolean;
begin
  if not Assigned(AMemo) then Exit;
  if (AMemo = MemoQuestion) and (AMemo is TAssistantMemo) and
     TAssistantMemo(AMemo).AllowVertScroll then
  begin
    NeedBar := False;
    if AMemo.HandleAllocated and (AMemo.Text <> '') then
    begin
      LineCount := SendMessage(AMemo.Handle, EM_GETLINECOUNT, 0, 0);
      LineH := Abs(AMemo.Font.Height);
      if LineH < 12 then
        LineH := 16
      else
        Inc(LineH, 3);
      NeedBar := (LineCount * LineH) > (AMemo.ClientHeight + 2);
    end;
    TAssistantMemo(AMemo).SyncVertScrollBar(NeedBar);
    Exit;
  end;
  if AMemo is TAssistantMemo then
    TAssistantMemo(AMemo).ForceHideVertScrollBar
  else
  begin
    if AMemo.ScrollBars <> ssNone then
      AMemo.ScrollBars := ssNone;
    if AMemo.HandleAllocated then
      ShowScrollBar(AMemo.Handle, SB_VERT, False);
  end;
end;

procedure TFastFileAssistantCtrl.SyncAssistantMemoScrollBars;
begin
  SyncMemoAutoVertScroll(MemoQuestion);
  SyncMemoAutoVertScroll(MemoReply);
end;

procedure TFastFileAssistantCtrl.LayoutInputControls(Sender: TObject);
const
  BH = 32;
  RECENT_LBL_H = 15;
  RECENT_CMB_H = 24;
  CHK_ROW_GAP = 10;
  STATUS_GAP = 6;
  FRAME_PAD = 8;
  SHELL_BORDER = 1;
var
  W, BtnRowTop, PromptH, HideW, BadgeW, ToolsGap, PromptToolsW, PromptW: Integer;
  ChkTop, ChkBlockH, LblChkH, StatusTop, StatusH: Integer;
  LblChkW, RecentTop, MemoTop, FrameInnerW, ClearSlot, ShellInner: Integer;
  ComboW, MemoH, QuestionH, ToolX, ToolY, ToolsBarH, CharW, HintH: Integer;
  PromptTextW, ToolsTop, HintBtnX, HintMemoW, HintBtnColW: Integer;
  ToolsBelow: Boolean;
  PromptTitle: string;

  function S(const A: Integer): Integer;
  begin
    Result := FfPx(A);
  end;

  procedure PlaceTool(ABtn: TsSpeedButton; AMinW: Integer);
  begin
    if not Assigned(ABtn) or not Assigned(PnlQuestionTools) then Exit;
    SizeQuestionToolBtn(ABtn, S(AMinW));
    if (ToolX > 6) and (ToolX + ABtn.Width > PnlQuestionTools.ClientWidth - 6) then
    begin
      ToolX := 6;
      Inc(ToolY, S(ASSISTANT_TOOL_BTN_H) + 4);
    end;
    ABtn.Align := alNone;
    ABtn.SetBounds(ToolX, ToolY, ABtn.Width, S(ASSISTANT_TOOL_BTN_H));
    Inc(ToolX, ABtn.Width + 4);
  end;
begin
  if not Assigned(PnlInput) then Exit;
  W := PnlInput.ClientWidth - 2 * S(ASSISTANT_PAD);
  if W < 120 then Exit;

  PromptH := S(28);
  if Assigned(LblPrompt) then
    PromptH := Max(PromptH, LblPrompt.Canvas.TextHeight('Qg') + 10);
  HideW := S(ASSISTANT_HIDE_BTN_W);
  BadgeW := S(ASSISTANT_SHORTCUT_BADGE_W);
  ToolsGap := 6;
  PromptToolsW := 0;
  if Assigned(BtnHide) then
    PromptToolsW := PromptToolsW + HideW;
  if Assigned(PnlShortcutBadgeShell) then
  begin
    if PromptToolsW > 0 then
      PromptToolsW := PromptToolsW + ToolsGap;
    PromptToolsW := PromptToolsW + BadgeW;
  end;
  if PromptToolsW > 0 then
    PromptToolsW := PromptToolsW + ToolsGap;

  PromptTitle := '';
  if Assigned(LblPrompt) then
    PromptTitle := Trim(LblPrompt.Caption);
  if PromptTitle = '' then
    PromptTitle := TrText('Assistant.WhatDoYouWant');
  PromptTextW := 0;
  if Assigned(LblPrompt) then
    PromptTextW := LblPrompt.Canvas.TextWidth(PromptTitle) + 6;

  { Keep the full question (incl. "?") visible: same row when it fits, else
    title uses full width and shortcut/close go on the next line. }
  ToolsBelow := (PromptToolsW > 0) and (PromptTextW + PromptToolsW > W);
  if ToolsBelow then
    PromptW := W
  else
  begin
    PromptW := W - PromptToolsW;
    if PromptW < 80 then
      PromptW := 80;
  end;

  if Assigned(LblPrompt) then
  begin
    LblPrompt.Caption := PromptTitle;
    LblPrompt.AutoSize := False;
    LblPrompt.WordWrap := False;
    LblPrompt.Layout := tlCenter;
    LblPrompt.ShowAccelChar := False;
    LblPrompt.SetBounds(ASSISTANT_PAD, ASSISTANT_PAD, PromptW, PromptH);
  end;

  if ToolsBelow then
    ToolsTop := ASSISTANT_PAD + PromptH + 4
  else
    ToolsTop := ASSISTANT_PAD;
  ToolX := ASSISTANT_PAD + W;
  if Assigned(BtnHide) then
  begin
    BtnHide.Align := alNone;
    BtnHide.SetBounds(ToolX - HideW, ToolsTop, HideW, PromptH);
    ToolX := BtnHide.Left - ToolsGap;
  end;
  if Assigned(PnlShortcutBadgeShell) then
  begin
    PnlShortcutBadgeShell.Align := alNone;
    PnlShortcutBadgeShell.SetBounds(ToolX - BadgeW, ToolsTop, BadgeW, PromptH);
    PnlShortcutBadgeShell.BringToFront;
  end;
  if Assigned(BtnHide) then
    BtnHide.BringToFront;

  if ToolsBelow then
    RecentTop := ToolsTop + PromptH + 6
  else
    RecentTop := ASSISTANT_PAD + PromptH + 6;
  if Assigned(LblRecentQuestions) then
    LblRecentQuestions.SetBounds(ASSISTANT_PAD, RecentTop, W, RECENT_LBL_H);
  ComboW := W;
  if ComboW < 80 then
    ComboW := 80;
  if Assigned(PnlRecentCombo) then
    PnlRecentCombo.SetBounds(ASSISTANT_PAD, RecentTop + RECENT_LBL_H + 2, ComboW, RECENT_CMB_H);
  if Assigned(EdtRecentFind) then
    EdtRecentFind.Visible := False;
  if Assigned(BtnRecentFindClear) then
    BtnRecentFindClear.Visible := False;
  if Assigned(BtnRecentFind) then
    BtnRecentFind.Visible := False;

  MemoTop := RecentTop + RECENT_LBL_H + 2 + RECENT_CMB_H + 10;
  HintH := 0;
  if Assigned(MemoDraftHint) and MemoDraftHint.Visible and
     (Trim(MemoDraftHint.Text) <> '') then
  begin
    { Fixed compact height + vertical scroll; Clear/Copy stacked on the right. }
    HintH := S(ASSISTANT_DRAFT_HINT_H);
    if Assigned(BtnClearHint) then
      SizeQuestionToolBtn(BtnClearHint, S(ASSISTANT_CLEAR_TOOL_BTN_W));
    if Assigned(BtnCopyHint) then
      SizeQuestionToolBtn(BtnCopyHint, S(ASSISTANT_COPY_TOOL_BTN_W));
    HintBtnColW := 0;
    if Assigned(BtnClearHint) then
      HintBtnColW := Max(HintBtnColW, BtnClearHint.Width);
    if Assigned(BtnCopyHint) then
      HintBtnColW := Max(HintBtnColW, BtnCopyHint.Width);
    if HintBtnColW > 0 then
      HintMemoW := W - HintBtnColW - 6
    else
      HintMemoW := W;
    if HintMemoW < 80 then
      HintMemoW := 80;
    MemoDraftHint.SetBounds(ASSISTANT_PAD, MemoTop, HintMemoW, HintH);
    HintBtnX := ASSISTANT_PAD + HintMemoW + 6;
    if Assigned(BtnClearHint) then
    begin
      BtnClearHint.Visible := True;
      BtnClearHint.SetBounds(HintBtnX, MemoTop, HintBtnColW, S(ASSISTANT_TOOL_BTN_H));
      BtnClearHint.BringToFront;
    end;
    if Assigned(BtnCopyHint) then
    begin
      BtnCopyHint.Visible := True;
      BtnCopyHint.SetBounds(HintBtnX, MemoTop + S(ASSISTANT_TOOL_BTN_H) + 2,
        HintBtnColW, S(ASSISTANT_TOOL_BTN_H));
      BtnCopyHint.BringToFront;
    end;
    MemoTop := MemoTop + HintH + 6;
  end
  else
  begin
    if Assigned(BtnClearHint) then
      BtnClearHint.Visible := False;
    if Assigned(BtnCopyHint) then
      BtnCopyHint.Visible := False;
  end;
  ClearSlot := 0;
  if Assigned(BtnClearQuestion) and BtnClearQuestion.Visible then
    ClearSlot := ASSISTANT_CLEAR_BTN_W + 4;

  QuestionH := S(ASSISTANT_QUESTION_FRAME_H) + S(ASSISTANT_TOOLS_BAR_H);
  if Assigned(PnlQuestionShell) then
    PnlQuestionShell.SetBounds(S(ASSISTANT_PAD), MemoTop, W, QuestionH)
  else if Assigned(PnlQuestionFrame) then
    PnlQuestionFrame.SetBounds(S(ASSISTANT_PAD), MemoTop, W, S(ASSISTANT_QUESTION_FRAME_H));

  if Assigned(PnlQuestionTools) then
  begin
    PnlQuestionTools.Align := alBottom;
    PnlQuestionTools.Height := S(ASSISTANT_TOOLS_BAR_H);
    PnlQuestionTools.Visible := True;
  end;
  if Assigned(PnlQuestionToolsSep) then
  begin
    PnlQuestionToolsSep.Align := alTop;
    PnlQuestionToolsSep.Height := 1;
  end;

  ToolX := 6;
  ToolY := S(ASSISTANT_TOOL_BTN_PAD_Y);
  PlaceTool(BtnTranslate, ASSISTANT_TRANSLATE_BTN_W);
  PlaceTool(BtnRewrite, ASSISTANT_REWRITE_BTN_W);
  PlaceTool(BtnAgentMode, ASSISTANT_AGENT_BTN_W);
  PlaceTool(BtnClearReply, ASSISTANT_CLEAR_TOOL_BTN_W);
  PlaceTool(BtnCopyReply, ASSISTANT_COPY_TOOL_BTN_W);
  PlaceTool(BtnPython, ASSISTANT_PYTHON_BTN_W);
  if Assigned(BtnComposeFormats) then
  begin
    if (ToolX > 6) and Assigned(PnlQuestionTools) and
       (ToolX + ASSISTANT_HELP_TOOL_BTN_W > PnlQuestionTools.ClientWidth - 6) then
    begin
      ToolX := 6;
      Inc(ToolY, S(ASSISTANT_TOOL_BTN_H) + 4);
    end;
    BtnComposeFormats.Align := alNone;
    BtnComposeFormats.SetBounds(ToolX, ToolY, S(ASSISTANT_HELP_TOOL_BTN_W), S(ASSISTANT_TOOL_BTN_H));
  end;
  { Top sep (1) + top pad + button + bottom pad — avoid clipped button borders. }
  ToolsBarH := 1 + ToolY + S(ASSISTANT_TOOL_BTN_H) + S(ASSISTANT_TOOL_BTN_PAD_Y);
  if ToolsBarH < S(ASSISTANT_TOOLS_BAR_H) then
    ToolsBarH := S(ASSISTANT_TOOLS_BAR_H);
  if Assigned(PnlQuestionTools) then
    PnlQuestionTools.Height := ToolsBarH;
  QuestionH := S(ASSISTANT_QUESTION_FRAME_H) + ToolsBarH;
  if Assigned(PnlQuestionShell) then
    PnlQuestionShell.SetBounds(S(ASSISTANT_PAD), MemoTop, W, QuestionH);

  ShellInner := S(ASSISTANT_QUESTION_FRAME_H) - (SHELL_BORDER * 2);
  if ShellInner < 40 then
    ShellInner := 40;
  FrameInnerW := W - (SHELL_BORDER * 2) - (FRAME_PAD * 2) - ClearSlot;
  if FrameInnerW < 60 then
    FrameInnerW := 60;

  if Assigned(BtnClearQuestion) and Assigned(PnlQuestionFrame) and
     (BtnClearQuestion.Parent = PnlQuestionFrame) then
    BtnClearQuestion.SetBounds(
      PnlQuestionFrame.ClientWidth - FRAME_PAD - ASSISTANT_CLEAR_BTN_W,
      FRAME_PAD, ASSISTANT_CLEAR_BTN_W, ASSISTANT_CLEAR_BTN_W);

  MemoH := ShellInner - (FRAME_PAD * 2) - S(ASSISTANT_CHAR_COUNT_H);
  if MemoH < S(56) then
    MemoH := S(56);
  { Own strip under the memo — never clips the last typed line. }
  CharW := S(56);
  if Assigned(LblQuestionCharCount) and Assigned(PnlQuestionFrame) then
  begin
    LblQuestionCharCount.Parent := PnlQuestionFrame;
    LblQuestionCharCount.AutoSize := False;
    LblQuestionCharCount.Alignment := taRightJustify;
    LblQuestionCharCount.Layout := tlCenter;
    LblQuestionCharCount.SetBounds(
      PnlQuestionFrame.ClientWidth - FRAME_PAD - CharW,
      FRAME_PAD + MemoH, CharW, S(ASSISTANT_CHAR_COUNT_H) - 2);
    LblQuestionCharCount.BringToFront;
  end;

  if Assigned(MemoQuestion) then
  begin
    if Assigned(PnlQuestionFrame) and (MemoQuestion.Parent = PnlQuestionFrame) then
      MemoQuestion.SetBounds(FRAME_PAD, FRAME_PAD, FrameInnerW, MemoH)
    else
      MemoQuestion.SetBounds(S(ASSISTANT_PAD), MemoTop, W, S(ASSISTANT_QUESTION_FRAME_H));
    SyncMemoAutoVertScroll(MemoQuestion);
  end;

  BtnRowTop := MemoTop + QuestionH + 12;
  if Assigned(BtnSend) then
    BtnSend.SetBounds(ASSISTANT_PAD, BtnRowTop, BtnSend.Width, BH);
  if Assigned(BtnExecute) then
    BtnExecute.SetBounds(ASSISTANT_PAD + W - BtnExecute.Width, BtnRowTop, BtnExecute.Width, BH);

  ChkTop := BtnRowTop + BH + CHK_ROW_GAP;
  ChkBlockH := 17;
  LblChkW := W - ASSISTANT_CHK_GLYPH_W;
  if LblChkW < 40 then
    LblChkW := 40;

  if Assigned(LblDontShowAgain) then
  begin
    LblChkH := MeasureAssistantWrappedTextHeight(LblDontShowAgain, LblDontShowAgain.Caption,
      LblChkW, 14);
    if LblChkH < 14 then
      LblChkH := 14;
    if Assigned(ChkDontShowAgain) then
      ChkDontShowAgain.SetBounds(ASSISTANT_PAD, ChkTop, ASSISTANT_CHK_GLYPH_W, 17);
    LblDontShowAgain.SetBounds(ASSISTANT_PAD + ASSISTANT_CHK_GLYPH_W, ChkTop, LblChkW, LblChkH);
    if LblChkH > ChkBlockH then
      ChkBlockH := LblChkH;
  end
  else if Assigned(ChkDontShowAgain) then
  begin
    ChkBlockH := MeasureAssistantWrappedTextHeight(ChkDontShowAgain, ChkDontShowAgain.Caption,
      W - ASSISTANT_CHK_GLYPH_W, 17);
    ChkDontShowAgain.SetBounds(ASSISTANT_PAD, ChkTop, W, ChkBlockH);
  end;

  StatusTop := ChkTop + ChkBlockH + STATUS_GAP;
  StatusH := 14;
  if Assigned(LblStatus) then
  begin
    if Trim(LblStatus.Caption) <> '' then
      StatusH := MeasureAssistantWrappedTextHeight(LblStatus, LblStatus.Caption, W, 14);
    if StatusH < 14 then
      StatusH := 14;
    LblStatus.SetBounds(ASSISTANT_PAD, StatusTop, W, StatusH);
  end;

  PnlInput.Constraints.MinHeight := S(ASSISTANT_INPUT_MIN_H);
  if PnlInput.Height < S(ASSISTANT_INPUT_MIN_H) then
    PnlInput.Height := S(ASSISTANT_INPUT_MIN_H);
  PlaceAssistantGrips;
  SyncAssistantMemoScrollBars;
end;

procedure TFastFileAssistantCtrl.StyleFileNoticeHyperlink(ALbl: TLabel);
begin
  if not Assigned(ALbl) then Exit;
  ALbl.Font.Color := clHotLight;
  ALbl.Font.Style := [fsUnderline];
  ALbl.Cursor := crHandPoint;
end;

procedure TFastFileAssistantCtrl.LayoutFileNoticeActions;
var
  X: Integer;

  procedure Place(ABtn: TsSpeedButton; AMinW: Integer);
  begin
    if not Assigned(ABtn) or not ABtn.Visible then Exit;
    SizeQuestionToolBtn(ABtn, AMinW);
    ABtn.Align := alNone;
    ABtn.SetBounds(X, 2, ABtn.Width, ASSISTANT_TOOL_BTN_H);
    Inc(X, ABtn.Width + 4);
  end;

begin
  X := 0;
  Place(BtnFileNoticeOpen, 56);
  Place(BtnFileNoticeFolder, 56);
  Place(BtnFileNoticeCopy, 56);
  Place(BtnFileNoticeDetails, 56);
  Place(BtnFileNoticeValidate, 56);
end;

procedure TFastFileAssistantCtrl.EnsureFileNoticeBanner;

  procedure PrepPanel(APnl: TsPanel; AParent: TWinControl; AAlign: TAlign;
    AColor: TColor);
  begin
    APnl.Parent := AParent;
    APnl.Align := AAlign;
    APnl.BevelOuter := bvNone;
    APnl.Caption := '';
    APnl.ParentBackground := False;
    APnl.ParentColor := False;
    APnl.Color := AColor;
    try
      APnl.SkinData.CustomColor := True;
      APnl.SkinData.SkinSection := 'TRANSPARENT';
    except
    end;
  end;

begin
  if Assigned(PnlFileNotice) then Exit;

  PnlFileNotice := TsPanel.Create(Self);
  PrepPanel(PnlFileNotice, Self, alTop, ASSISTANT_FILE_NOTICE_EDGE);
  PnlFileNotice.Height := 0;
  PnlFileNotice.Visible := False;
  PnlFileNotice.Padding.Left := 1;
  PnlFileNotice.Padding.Top := 1;
  PnlFileNotice.Padding.Right := 1;
  PnlFileNotice.Padding.Bottom := 1;
  PnlFileNotice.ShowHint := True;

  PnlFileNoticeInner := TsPanel.Create(Self);
  PrepPanel(PnlFileNoticeInner, PnlFileNotice, alClient, ASSISTANT_FILE_NOTICE_BG);

  PnlFileNoticeAccent := TsPanel.Create(Self);
  PrepPanel(PnlFileNoticeAccent, PnlFileNoticeInner, alLeft, ASSISTANT_FILE_NOTICE_ACCENT);
  PnlFileNoticeAccent.Width := 4;

  PnlFileNoticeContent := TsPanel.Create(Self);
  PrepPanel(PnlFileNoticeContent, PnlFileNoticeInner, alClient, ASSISTANT_FILE_NOTICE_BG);
  PnlFileNoticeContent.Padding.Left := 10;
  PnlFileNoticeContent.Padding.Top := 6;
  PnlFileNoticeContent.Padding.Right := 8;
  PnlFileNoticeContent.Padding.Bottom := 4;
  PnlFileNoticeContent.ShowHint := True;

  PnlFileNoticeHead := TsPanel.Create(Self);
  PrepPanel(PnlFileNoticeHead, PnlFileNoticeContent, alTop, ASSISTANT_FILE_NOTICE_BG);
  PnlFileNoticeHead.Height := 22;

  BtnFileNoticeDismiss := TsSpeedButton.Create(Self);
  BtnFileNoticeDismiss.Parent := PnlFileNoticeHead;
  BtnFileNoticeDismiss.Align := alRight;
  BtnFileNoticeDismiss.Width := 22;
  BtnFileNoticeDismiss.Caption := #$00D7;
  BtnFileNoticeDismiss.OnClick := FileNoticeDismissClick;
  StyleQuestionToolBtn(BtnFileNoticeDismiss);

  LblFileNoticeTitle := TLabel.Create(Self);
  LblFileNoticeTitle.Parent := PnlFileNoticeHead;
  LblFileNoticeTitle.Align := alClient;
  LblFileNoticeTitle.Layout := tlCenter;
  LblFileNoticeTitle.Font.Style := [fsBold];
  LblFileNoticeTitle.Font.Color := ASSISTANT_STATUS_OK;
  LblFileNoticeTitle.Transparent := True;
  LblFileNoticeTitle.ShowHint := True;

  LblFileNoticeFile := TLabel.Create(Self);
  LblFileNoticeFile.Parent := PnlFileNoticeContent;
  LblFileNoticeFile.Align := alTop;
  LblFileNoticeFile.Height := 18;
  LblFileNoticeFile.AutoSize := False;
  LblFileNoticeFile.WordWrap := False;
  LblFileNoticeFile.EllipsisPosition := epEndEllipsis;
  LblFileNoticeFile.Layout := tlCenter;
  LblFileNoticeFile.Transparent := True;
  LblFileNoticeFile.ShowHint := True;
  StyleFileNoticeHyperlink(LblFileNoticeFile);
  LblFileNoticeFile.OnClick := FileNoticeOpenClick;

  LblFileNoticeDir := TLabel.Create(Self);
  LblFileNoticeDir.Parent := PnlFileNoticeContent;
  LblFileNoticeDir.Align := alTop;
  LblFileNoticeDir.Height := 16;
  LblFileNoticeDir.AutoSize := False;
  LblFileNoticeDir.WordWrap := False;
  LblFileNoticeDir.EllipsisPosition := epPathEllipsis;
  LblFileNoticeDir.Layout := tlCenter;
  LblFileNoticeDir.Transparent := True;
  LblFileNoticeDir.ShowHint := True;
  StyleFileNoticeHyperlink(LblFileNoticeDir);
  LblFileNoticeDir.OnClick := FileNoticeFolderClick;

  PnlFileNoticeActions := TsPanel.Create(Self);
  PrepPanel(PnlFileNoticeActions, PnlFileNoticeContent, alBottom, ASSISTANT_FILE_NOTICE_BG);
  PnlFileNoticeActions.Height := 28;

  BtnFileNoticeOpen := TsSpeedButton.Create(Self);
  BtnFileNoticeOpen.Parent := PnlFileNoticeActions;
  BtnFileNoticeOpen.OnClick := FileNoticeOpenClick;
  StyleQuestionToolBtn(BtnFileNoticeOpen);

  BtnFileNoticeFolder := TsSpeedButton.Create(Self);
  BtnFileNoticeFolder.Parent := PnlFileNoticeActions;
  BtnFileNoticeFolder.OnClick := FileNoticeFolderClick;
  StyleQuestionToolBtn(BtnFileNoticeFolder);

  BtnFileNoticeCopy := TsSpeedButton.Create(Self);
  BtnFileNoticeCopy.Parent := PnlFileNoticeActions;
  BtnFileNoticeCopy.OnClick := FileNoticeCopyClick;
  StyleQuestionToolBtn(BtnFileNoticeCopy);

  BtnFileNoticeDetails := TsSpeedButton.Create(Self);
  BtnFileNoticeDetails.Parent := PnlFileNoticeActions;
  BtnFileNoticeDetails.OnClick := FileNoticeDetailsClick;
  StyleQuestionToolBtn(BtnFileNoticeDetails);

  BtnFileNoticeValidate := TsSpeedButton.Create(Self);
  BtnFileNoticeValidate.Parent := PnlFileNoticeActions;
  BtnFileNoticeValidate.OnClick := FileNoticeValidateClick;
  StyleQuestionToolBtn(BtnFileNoticeValidate);

  LocalizeFileNoticeBanner;
  if not Assigned(FFileNoticeAutoHide) then
    FFileNoticeAutoHide := TFastFileNoticeAutoHide.Create(Self);
  FFileNoticeAutoHide.Bind(PnlFileNotice, PnlFileNoticeHead, FileNoticeAutoHideDone,
    ASSISTANT_FILE_NOTICE_ACCENT);
end;

procedure TFastFileAssistantCtrl.LocalizeFileNoticeBanner;
begin
  if not Assigned(PnlFileNotice) then Exit;
  if Assigned(BtnFileNoticeDismiss) then
  begin
    BtnFileNoticeDismiss.Caption := '×';
    BtnFileNoticeDismiss.Hint := TrText('Close');
    BtnFileNoticeDismiss.ShowHint := True;
  end;
  if Assigned(BtnFileNoticeOpen) then
  begin
    BtnFileNoticeOpen.Caption := TrText('Assistant.FileNoticeOpen');
    BtnFileNoticeOpen.Hint := TrText('Open file');
    BtnFileNoticeOpen.ShowHint := True;
  end;
  if Assigned(BtnFileNoticeValidate) then
  begin
    BtnFileNoticeValidate.Caption := TrText('Assistant.ValidateSource');
    BtnFileNoticeValidate.Hint := TrText('Assistant.ValidateHint');
    BtnFileNoticeValidate.ShowHint := True;
  end;
  if Assigned(BtnFileNoticeFolder) then
  begin
    BtnFileNoticeFolder.Caption := TrText('Assistant.FileNoticeFolder');
    BtnFileNoticeFolder.Hint := TrText('SCRIPT_EXPORT_OPEN_FOLDER');
    BtnFileNoticeFolder.ShowHint := True;
  end;
  if Assigned(BtnFileNoticeCopy) then
  begin
    BtnFileNoticeCopy.Caption := TrText('Assistant.FileNoticeCopy');
    BtnFileNoticeCopy.Hint := TrText('SCRIPT_EXPORT_COPY_PATH');
    BtnFileNoticeCopy.ShowHint := True;
  end;
  if Assigned(BtnFileNoticeDetails) then
  begin
    BtnFileNoticeDetails.Caption := TrText('ExportDone.Details');
    BtnFileNoticeDetails.Hint := TrText('ExportDone.ShowLastHint');
    BtnFileNoticeDetails.ShowHint := True;
  end;
  if Assigned(LblFileNoticeHint) then
    LblFileNoticeHint.Caption := TrText('SCRIPT_EXPORT_LINK_HINT');
  if (FGeneratedFilePath <> '') and Assigned(PnlFileNotice) and PnlFileNotice.Visible then
  begin
    if Assigned(LblFileNoticeTitle) then
      LblFileNoticeTitle.Caption := #$2713 + '  ' + TrText('SCRIPT_EXPORT_SAVED_TITLE');
    if Assigned(LblFileNoticeFile) then
      LblFileNoticeFile.Caption := ExtractFileName(FGeneratedFilePath);
    if Assigned(LblFileNoticeDir) then
      LblFileNoticeDir.Caption := FastFileShortenPathForUi(
        ExtractFileDir(FGeneratedFilePath), 52);
  end;
  LayoutFileNoticeActions;
end;

procedure TFastFileAssistantCtrl.ShowGeneratedFileNotice(const AFileName: string);
var
  FileName, DirPath, DirShown: string;
begin
  EnsureFileNoticeBanner;
  FileName := Trim(AFileName);
  if (FileName = '') or not Assigned(PnlFileNotice) then Exit;
  FGeneratedFilePath := FileName;
  DirPath := ExtractFileDir(FileName);
  if DirPath = '' then
    DirPath := FileName;
  DirShown := FastFileShortenPathForUi(DirPath, 56);
  if Assigned(LblFileNoticeTitle) then
    LblFileNoticeTitle.Caption := #$2713 + '  ' + TrText('SCRIPT_EXPORT_SAVED_TITLE');
  if Assigned(LblFileNoticeFile) then
  begin
    LblFileNoticeFile.Caption := ExtractFileName(FileName);
    LblFileNoticeFile.Hint := FileName;
  end;
  if Assigned(LblFileNoticeDir) then
  begin
    LblFileNoticeDir.Caption := DirShown;
    LblFileNoticeDir.Hint := DirPath;
  end;
  if Assigned(LblFileNoticeHint) then
    LblFileNoticeHint.Caption := TrText('SCRIPT_EXPORT_LINK_HINT');
  PnlFileNotice.Hint := FileName;
  if Assigned(BtnFileNoticeOpen) then
    BtnFileNoticeOpen.Enabled := FileExists(FileName);
  if Assigned(BtnFileNoticeDetails) then
    BtnFileNoticeDetails.Enabled := FileExists(FileName);
  if Assigned(BtnFileNoticeValidate) then
  begin
    BtnFileNoticeValidate.Visible := IsValidatableComposeSource(FileName);
    BtnFileNoticeValidate.Enabled := BtnFileNoticeValidate.Visible and FileExists(FileName) and (not FBusy);
  end;
  LayoutFileNoticeActions;
  PnlFileNotice.Height := ASSISTANT_FILE_NOTICE_H;
  PnlFileNotice.Visible := True;
  if Assigned(FFileNoticeAutoHide) then
    FFileNoticeAutoHide.Start(FASTFILE_NOTICE_SECONDS);
end;

procedure TFastFileAssistantCtrl.HideGeneratedFileNotice;
begin
  if Assigned(FFileNoticeAutoHide) then
    FFileNoticeAutoHide.Stop;
  FGeneratedFilePath := '';
  if not Assigned(PnlFileNotice) then Exit;
  PnlFileNotice.Visible := False;
  PnlFileNotice.Height := 0;
  PnlFileNotice.Hint := '';
end;

procedure TFastFileAssistantCtrl.FileNoticeAutoHideDone(Sender: TObject);
begin
  HideGeneratedFileNotice;
end;

procedure TFastFileAssistantCtrl.EnsureOfferNextBanner;
var
  UiFont: string;
begin
  if Assigned(PnlOfferNext) then Exit;
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    UiFont := 'Segoe UI'
  else
    UiFont := 'Tahoma';

  PnlOfferNext := TsPanel.Create(Self);
  PnlOfferNext.Parent := Self;
  PnlOfferNext.Align := alTop;
  PnlOfferNext.Height := 0;
  PnlOfferNext.Visible := False;
  PnlOfferNext.BevelOuter := bvNone;
  PnlOfferNext.Caption := '';
  PnlOfferNext.Padding.Left := 8;
  PnlOfferNext.Padding.Top := 4;
  PnlOfferNext.Padding.Right := 6;
  PnlOfferNext.Padding.Bottom := 6;
  try
    PnlOfferNext.SkinData.CustomColor := True;
    PnlOfferNext.Color := ColorToRGB(ASSISTANT_FILE_NOTICE_BG);
  except
  end;

  { Summary first (top), then the WhatNext / MoreInfo / × row. }
  LblOfferNext := TLabel.Create(Self);
  LblOfferNext.Parent := PnlOfferNext;
  LblOfferNext.Align := alTop;
  LblOfferNext.AutoSize := True;
  LblOfferNext.WordWrap := True;
  LblOfferNext.Transparent := True;
  LblOfferNext.Font.Name := UiFont;
  LblOfferNext.Font.Size := 8;
  LblOfferNext.Font.Color := ASSISTANT_STATUS_OK;

  PnlOfferHead := TsPanel.Create(Self);
  PnlOfferHead.Parent := PnlOfferNext;
  PnlOfferHead.Align := alTop;
  PnlOfferHead.Height := 22;
  PnlOfferHead.BevelOuter := bvNone;
  PnlOfferHead.Caption := '';
  try
    PnlOfferHead.SkinData.CustomColor := True;
    PnlOfferHead.Color := ColorToRGB(ASSISTANT_FILE_NOTICE_BG);
  except
  end;
  PnlOfferHead.OnResize := OfferHeadResize;

  { Same row: WhatNext + MoreInfo (close together) …… × }
  LblOfferWhatNext := TLabel.Create(Self);
  LblOfferWhatNext.Parent := PnlOfferHead;
  LblOfferWhatNext.AutoSize := True;
  LblOfferWhatNext.Transparent := True;
  LblOfferWhatNext.Layout := tlCenter;
  LblOfferWhatNext.Font.Name := UiFont;
  LblOfferWhatNext.Font.Size := 8;
  LblOfferWhatNext.Font.Style := [fsBold];
  LblOfferWhatNext.Font.Color := ASSISTANT_STATUS_OK;

  LblOfferMoreInfo := TLabel.Create(Self);
  LblOfferMoreInfo.Parent := PnlOfferHead;
  LblOfferMoreInfo.AutoSize := True;
  LblOfferMoreInfo.Transparent := True;
  LblOfferMoreInfo.Layout := tlCenter;
  LblOfferMoreInfo.ShowHint := True;
  LblOfferMoreInfo.Font.Name := UiFont;
  LblOfferMoreInfo.Font.Size := 8;
  StyleFileNoticeHyperlink(LblOfferMoreInfo);
  LblOfferMoreInfo.OnClick := OfferMoreInfoClick;

  BtnOfferDismiss := TsSpeedButton.Create(Self);
  BtnOfferDismiss.Parent := PnlOfferHead;
  BtnOfferDismiss.Width := 22;
  BtnOfferDismiss.Height := 20;
  BtnOfferDismiss.Caption := '×';
  BtnOfferDismiss.Flat := True;
  BtnOfferDismiss.OnClick := OfferDismissClick;
  StyleQuestionToolBtn(BtnOfferDismiss);

  PnlOfferActions := TsPanel.Create(Self);
  PnlOfferActions.Parent := PnlOfferNext;
  PnlOfferActions.Align := alClient;
  PnlOfferActions.BevelOuter := bvNone;
  PnlOfferActions.Caption := '';
  try
    PnlOfferActions.SkinData.CustomColor := True;
    PnlOfferActions.Color := ColorToRGB(ASSISTANT_FILE_NOTICE_BG);
  except
  end;

  LocalizeOfferNextBanner;
end;

procedure TFastFileAssistantCtrl.OfferHeadResize(Sender: TObject);
begin
  LayoutOfferHeadRow;
end;

procedure TFastFileAssistantCtrl.LayoutOfferHeadRow;
var
  X, Y, Gap, AvailW, WhatW, MoreW: Integer;
begin
  if not Assigned(PnlOfferHead) then Exit;
  Gap := 10;
  Y := Max(0, (PnlOfferHead.ClientHeight - 18) div 2);
  if Assigned(BtnOfferDismiss) then
  begin
    BtnOfferDismiss.SetBounds(
      Max(0, PnlOfferHead.ClientWidth - BtnOfferDismiss.Width),
      Max(0, (PnlOfferHead.ClientHeight - BtnOfferDismiss.Height) div 2),
      BtnOfferDismiss.Width, BtnOfferDismiss.Height);
    AvailW := BtnOfferDismiss.Left - 4;
  end
  else
    AvailW := PnlOfferHead.ClientWidth;

  WhatW := 0;
  MoreW := 0;
  if Assigned(LblOfferWhatNext) then
  begin
    LblOfferWhatNext.AutoSize := True;
    WhatW := LblOfferWhatNext.Width;
  end;
  if Assigned(LblOfferMoreInfo) then
  begin
    LblOfferMoreInfo.AutoSize := True;
    MoreW := LblOfferMoreInfo.Width;
  end;

  X := 0;
  if Assigned(LblOfferWhatNext) then
  begin
    if WhatW > AvailW then
      WhatW := Max(40, AvailW);
    LblOfferWhatNext.SetBounds(X, Y, WhatW, 18);
    Inc(X, WhatW + Gap);
  end;
  if Assigned(LblOfferMoreInfo) then
  begin
    if X + MoreW > AvailW then
      MoreW := Max(40, AvailW - X);
    if MoreW > 0 then
      LblOfferMoreInfo.SetBounds(X, Y, MoreW, 18);
  end;
end;

procedure TFastFileAssistantCtrl.LocalizeOfferNextBanner;
var
  Cap, WhatNext: string;
begin
  if not Assigned(PnlOfferNext) then Exit;
  if Assigned(BtnOfferDismiss) then
  begin
    BtnOfferDismiss.Caption := '×';
    BtnOfferDismiss.Hint := TrText('Assistant.Offer.CloseHint');
    BtnOfferDismiss.ShowHint := True;
  end;
  if Assigned(LblOfferWhatNext) then
  begin
    WhatNext := TrText('Assistant.Offer.WhatNext');
    if WhatNext = 'Assistant.Offer.WhatNext' then
      WhatNext := TrText('FindOcc.Assistant.WhatNext');
    LblOfferWhatNext.Caption := WhatNext;
    LblOfferWhatNext.Hint := WhatNext;
    LblOfferWhatNext.ShowHint := True;
  end;
  if Assigned(LblOfferMoreInfo) then
  begin
    Cap := TrText('Assistant.Offer.MoreInfo');
    LblOfferMoreInfo.Caption := Cap;
    LblOfferMoreInfo.Hint := TrText('Assistant.Offer.MoreInfoHint');
    LblOfferMoreInfo.ShowHint := True;
    StyleFileNoticeHyperlink(LblOfferMoreInfo);
  end;
  LayoutOfferHeadRow;
end;

procedure TFastFileAssistantCtrl.ClearOfferActionButtons;
var
  I: Integer;
  C: TControl;
begin
  if not Assigned(PnlOfferActions) then Exit;
  for I := PnlOfferActions.ControlCount - 1 downto 0 do
  begin
    C := PnlOfferActions.Controls[I];
    C.Parent := nil;
    C.Free;
  end;
  if Assigned(FOfferActionIds) then
    FOfferActionIds.Clear;
end;

function TFastFileAssistantCtrl.OfferActionCaption(const AActionId: string): string;
begin
  if SameText(AActionId, 'ask_ai') then
    Result := TrText('Assistant.Offer.AskAI')
  else if SameText(AActionId, 'view_find_occurrences') then
    Result := TrText('FindOcc.ViewAllInList')
  else if SameText(AActionId, 'find_next') then
    Result := TrText('FindOcc.Next')
  else if SameText(AActionId, 'find_previous') then
    Result := TrText('FindOcc.Prev')
  else if SameText(AActionId, 'open_replace') then
    Result := TrText('FindOcc.Assistant.Btn.Replace')
  else if SameText(AActionId, 'clear_find') then
    Result := TrText('FindOcc.Clear')
  else if SameText(AActionId, 'clear_filter') then
    Result := TrText('FilterBar.Clear')
  else if SameText(AActionId, 'export_matching_lines') then
    Result := TrText('FindOcc.Export')
  else if SameText(AActionId, 'apply_filter') then
    Result := TrText('Filter / Grep')
  else if SameText(AActionId, 'open_find') then
    Result := TrText('FindOcc.Assistant.Btn.Find')
  else if SameText(AActionId, 'continue_filter') then
    Result := TrText('FilterBar.Continue')
  else if SameText(AActionId, 'open_filter') then
    Result := TrText('Filter / Grep')
  else if SameText(AActionId, 'export_file') then
    Result := TrText('Assistant.Offer.Chip.Export')
  else if SameText(AActionId, 'show_tab_read') then
    Result := TrText('Read view')
  else if SameText(AActionId, 'show_tab_merge_files') then
    Result := TrText('Assistant.Offer.Chip.Merge')
  else if SameText(AActionId, 'show_tab_compare') then
    Result := TrText('Assistant.Offer.Chip.Compare')
  else if SameText(AActionId, 'show_script_engine') then
    Result := TrText('Assistant.Offer.Chip.Script')
  else if SameText(AActionId, 'open_and_read_file') then
    Result := TrText('Assistant.Offer.Chip.OpenRead')
  else if SameText(AActionId, 'consumer_ai') then
    Result := TrText('Assistant.Offer.Chip.ConsumerAI')
  else if SameText(AActionId, 'consumer_rag') then
    Result := TrText('Assistant.Offer.Chip.ConsumerRAG')
  else if SameText(AActionId, 'force_index_file') then
    Result := TrText('Assistant.Offer.Chip.Index')
  else if SameText(AActionId, AGENT_CHIP_ACCEPT) then
    Result := TrText('Assistant.Agent.Chip.Accept')
  else if SameText(AActionId, AGENT_CHIP_REVIEW) then
    Result := TrText('Assistant.Agent.Chip.Review')
  else if SameText(AActionId, AGENT_CHIP_REJECT) then
    Result := TrText('Assistant.Agent.Chip.Reject')
  else
    Result := AActionId;
end;

procedure TFastFileAssistantCtrl.OfferActionClick(Sender: TObject);
var
  Btn: TsSpeedButton;
  St: TAssistantChainStep;
  Idx: Integer;
  ActionId: string;
begin
  if not (Sender is TsSpeedButton) then Exit;
  Btn := TsSpeedButton(Sender);
  Idx := Btn.Tag;
  ActionId := '';
  if Assigned(FOfferActionIds) and (Idx >= 0) and (Idx < FOfferActionIds.Count) then
    ActionId := FOfferActionIds[Idx];
  if ActionId = '' then Exit;

  PipelineRememberChip(ActionId);

  { AI-First: focus the question box with the contextual draft (and send). }
  if SameText(ActionId, 'ask_ai') then
  begin
    HideOfferNext;
    if Assigned(MemoQuestion) then
    begin
      if Trim(FOfferAiDraft) <> '' then
        MemoQuestion.Text := FOfferAiDraft
      else if Trim(MemoQuestion.Text) = '' then
        MemoQuestion.Text := TrText('Assistant.Offer.Draft.Generic');
      ClampQuestionToMaxChars;
      UpdateClearQuestionBtn;
      UpdateQuestionCharCount;
      RequestInputFocus;
    end;
    Exit;
  end;

  if SameText(ActionId, AGENT_CHIP_ACCEPT) then
  begin
    if Assigned(AgentBridgeAcceptAll) then AgentBridgeAcceptAll;
    Exit;
  end;
  if SameText(ActionId, AGENT_CHIP_REJECT) then
  begin
    if Assigned(AgentBridgeRejectAll) then AgentBridgeRejectAll;
    Exit;
  end;
  if SameText(ActionId, AGENT_CHIP_REVIEW) then
  begin
    if Assigned(AgentBridgeReview) then AgentBridgeReview;
    Exit;
  end;

  St := Default(TAssistantChainStep);
  St.ActionId := ActionId;
  HideOfferNext;
  AssistantHostExecuteAction(St);
end;

procedure TFastFileAssistantCtrl.HideOfferNext;
begin
  ClearOfferActionButtons;
  if Assigned(PnlOfferNext) then
  begin
    PnlOfferNext.Visible := False;
    PnlOfferNext.Height := 0;
  end;
  UpdateOfferQuestionHint;
end;

procedure TFastFileAssistantCtrl.OfferDismissClick(Sender: TObject);
begin
  HideOfferNext;
end;

procedure TFastFileAssistantCtrl.UpdateOfferQuestionHint;
var
  ShowHint: Boolean;
  Cur: string;
begin
  ShowHint := Assigned(PnlOfferNext) and PnlOfferNext.Visible and
    (Trim(FOfferAiDraft) <> '');
  if Assigned(MemoDraftHint) then
  begin
    if ShowHint then
    begin
      MemoDraftHint.Text := FOfferAiDraft;
      MemoDraftHint.Hint := TrText('Assistant.Offer.DraftClickHint');
      MemoDraftHint.Visible := True;
      MemoDraftHint.SelStart := 0;
      MemoDraftHint.SelLength := 0;
    end
    else
    begin
      MemoDraftHint.Clear;
      MemoDraftHint.Hint := '';
      MemoDraftHint.Visible := False;
    end;
  end;
  if Assigned(BtnClearHint) then
  begin
    BtnClearHint.Visible := ShowHint;
    BtnClearHint.Enabled := ShowHint;
  end;
  if Assigned(BtnCopyHint) then
  begin
    BtnCopyHint.Visible := ShowHint;
    BtnCopyHint.Enabled := ShowHint;
  end;
  { If the memo still holds an auto-seeded draft from older builds, clear it
    so the user is not forced to edit/delete suggestion text. }
  if Assigned(MemoQuestion) and ShowHint then
  begin
    Cur := Trim(MemoQuestion.Text);
    if (Cur <> '') and
       ((Cur = Trim(FOfferAiDraft)) or
        SameText(Cur, TrText('Assistant.Offer.Draft.Generic')) or
        SameText(Cur, TrText('Assistant.Offer.Draft.Read'))) then
    begin
      MemoQuestion.Clear;
      ClampQuestionToMaxChars;
      UpdateClearQuestionBtn;
      UpdateQuestionCharCount;
    end;
  end;
  if Assigned(PnlInput) then
    LayoutInputControls(PnlInput);
end;

procedure TFastFileAssistantCtrl.OfferQuestionHintClick(Sender: TObject);
begin
  if not Assigned(MemoQuestion) then Exit;
  if Trim(FOfferAiDraft) = '' then Exit;
  MemoQuestion.Text := FOfferAiDraft;
  ClampQuestionToMaxChars;
  UpdateClearQuestionBtn;
  UpdateQuestionCharCount;
  RequestInputFocus;
end;

procedure TFastFileAssistantCtrl.BtnClearHintClick(Sender: TObject);
begin
  FOfferAiDraft := '';
  UpdateOfferQuestionHint;
end;

procedure TFastFileAssistantCtrl.BtnCopyHintClick(Sender: TObject);
var
  S: string;
begin
  S := Trim(FOfferAiDraft);
  if S = '' then
  begin
    if Assigned(MemoDraftHint) then
      S := Trim(MemoDraftHint.Text);
  end;
  if S = '' then Exit;
  Clipboard.AsText := S;
  SetStatusCaption(TrText('Assistant.Status.CopiedToClipboard'));
end;

function FormatOfferFileSizeBytes(ABytes: Int64): string;
begin
  if ABytes < 1024 then
    Result := IntToStr(ABytes) + ' B'
  else if ABytes < 1024 * 1024 then
    Result := Format('%.1f KB', [ABytes / 1024.0])
  else if ABytes < Int64(1024) * 1024 * 1024 then
    Result := Format('%.2f MB', [ABytes / (1024.0 * 1024.0)])
  else
    Result := Format('%.2f GB', [ABytes / (1024.0 * 1024.0 * 1024.0)]);
end;

procedure TFastFileAssistantCtrl.ShowOfferFileInfoDialog;
var
  Dlg: TForm;
  Memo: TMemo;
  BtnOk, BtnWinProps: TButton;
  Path: string;
  Lines: Int64;
  CreatedAt, AccessedAt, ModifiedAt: TDateTime;
  SizeBytes: Int64;
  HaveDisk: Boolean;
  SL: TStringList;
begin
  Path := Trim(AssistantHostGetOpenFilePath);
  if (Path = '') or (not FileExists(Path)) then
  begin
    FastFileMessageBox(PChar(TrText('Assistant.Offer.FileInfo.NoFile')),
      PChar(TrText('Assistant.Offer.FileInfo.Title')), MB_OK or MB_ICONINFORMATION);
    Exit;
  end;

  FOfferInfoPath := Path;
  Lines := AssistantHostGetOpenFileLineCount;
  HaveDisk := AssistantHostGetOpenFileDiskInfo(CreatedAt, AccessedAt, ModifiedAt, SizeBytes);

  SL := TStringList.Create;
  try
    SL.Add(TrText('Assistant.Offer.FileInfo.Path') + ':');
    SL.Add(Path);
    SL.Add('');
    if Lines > 0 then
      SL.Add(TrText('Assistant.Offer.FileInfo.Lines') + ': ' + IntToStr(Lines));
    if HaveDisk then
    begin
      SL.Add(TrText('Assistant.Offer.FileInfo.Size') + ': ' +
        FormatOfferFileSizeBytes(SizeBytes) + ' (' + IntToStr(SizeBytes) + ' B)');
      if CreatedAt > 0 then
        SL.Add(TrText('Assistant.Offer.FileInfo.Created') + ': ' +
          FormatDateTime('yyyy-mm-dd hh:nn:ss', CreatedAt));
      if ModifiedAt > 0 then
        SL.Add(TrText('Assistant.Offer.FileInfo.Modified') + ': ' +
          FormatDateTime('yyyy-mm-dd hh:nn:ss', ModifiedAt));
      if AccessedAt > 0 then
        SL.Add(TrText('Assistant.Offer.FileInfo.Accessed') + ': ' +
          FormatDateTime('yyyy-mm-dd hh:nn:ss', AccessedAt));
    end;

    Dlg := TForm.CreateNew(Self);
    try
      Dlg.BorderStyle := bsDialog;
      Dlg.BorderIcons := [biSystemMenu];
      Dlg.Caption := TrText('Assistant.Offer.FileInfo.Title');
      Dlg.Position := poOwnerFormCenter;
      Dlg.ClientWidth := 460;
      Dlg.ClientHeight := 300;
      Dlg.Font.Name := 'Segoe UI';
      Dlg.Font.Size := 9;

      Memo := TMemo.Create(Dlg);
      Memo.Parent := Dlg;
      Memo.SetBounds(12, 12, Dlg.ClientWidth - 24, Dlg.ClientHeight - 56);
      Memo.ReadOnly := True;
      Memo.ScrollBars := ssVertical;
      Memo.WordWrap := True;
      Memo.Lines.Text := Trim(SL.Text);
      Memo.WantReturns := False;

      BtnWinProps := TButton.Create(Dlg);
      BtnWinProps.Parent := Dlg;
      BtnWinProps.Caption := TrText('Assistant.Offer.FileInfo.WindowsProps');
      BtnWinProps.SetBounds(12, Dlg.ClientHeight - 36, 220, 25);
      BtnWinProps.OnClick := OfferWindowsPropsClick;

      BtnOk := TButton.Create(Dlg);
      BtnOk.Parent := Dlg;
      BtnOk.Caption := TrText('OK');
      BtnOk.Default := True;
      BtnOk.Cancel := True;
      BtnOk.ModalResult := mrOk;
      BtnOk.SetBounds(Dlg.ClientWidth - 100, Dlg.ClientHeight - 36, 88, 25);

      Dlg.ShowModal;
    finally
      Dlg.Free;
    end;
  finally
    SL.Free;
  end;
end;

procedure TFastFileAssistantCtrl.OfferWindowsPropsClick(Sender: TObject);
var
  Info: TShellExecuteInfo;
  Path: string;
  OwnerWnd: HWND;
begin
  Path := Trim(FOfferInfoPath);
  if (Path = '') or (not FileExists(Path)) then Exit;
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_INVOKEIDLIST;
  if (Sender is TControl) and Assigned(TControl(Sender).Owner) and
     (TControl(Sender).Owner is TWinControl) then
    OwnerWnd := TWinControl(TControl(Sender).Owner).Handle
  else if HandleAllocated then
    OwnerWnd := Handle
  else
    OwnerWnd := 0;
  Info.Wnd := OwnerWnd;
  Info.lpVerb := 'properties';
  Info.lpFile := PChar(Path);
  Info.nShow := SW_SHOW;
  ShellExecuteEx(@Info);
end;

procedure TFastFileAssistantCtrl.OfferMoreInfoClick(Sender: TObject);
begin
  ShowOfferFileInfoDialog;
end;

procedure TFastFileAssistantCtrl.ShowOfferNext(const ASummary, AActionIdsCsv: string;
  const AAiDraft: string);
var
  Parts: TStringList;
  I: Integer;
  Id, Cap, Body, WhatNext: string;
  Btn: TsSpeedButton;
begin
  EnsureOfferNextBanner;
  if not Assigned(PnlOfferNext) then Exit;
  LocalizeOfferNextBanner;
  ClearOfferActionButtons;
  FOfferAiDraft := Trim(AAiDraft);

  WhatNext := TrText('Assistant.Offer.WhatNext');
  if WhatNext = 'Assistant.Offer.WhatNext' then
    WhatNext := TrText('FindOcc.Assistant.WhatNext');

  Body := Trim(ASummary);
  if Assigned(LblOfferWhatNext) then
    LblOfferWhatNext.Caption := WhatNext;
  if Assigned(LblOfferNext) then
    LblOfferNext.Caption := Body;
  LayoutOfferHeadRow;
  { Operational summary stays in the offer banner / status — not in the AI reply box. }
  if Trim(Body) <> '' then
    SetStatusCaption(Body)
  else
    SetStatusCaption(WhatNext);
  if Assigned(LblStatus) and (Trim(Body) <> '') then
    LblStatus.Font.Color := ASSISTANT_STATUS_OK;

  { Clear leftover offer dumps that older builds put into the reply memo. }
  if Assigned(MemoReply) then
  begin
    Cap := Trim(MemoReply.Text);
    if (Cap <> '') and (not SameText(Cap, TrText('Assistant.ReplyPlaceholder'))) and
       (((Body <> '') and ((Cap = Body) or (Pos(Body, Cap) = 1))) or
        (Pos(WhatNext, Cap) > 0)) then
    begin
      MemoReply.Clear;
      FLastReplyBody := '';
    end;
    if Trim(MemoReply.Text) = '' then
      MemoReply.Text := TrText('Assistant.ReplyPlaceholder');
  end;

  UpdateOfferQuestionHint;

  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ',';
    Parts.DelimitedText := AActionIdsCsv;
    for I := 0 to Parts.Count - 1 do
    begin
      Id := Trim(Parts[I]);
      if Id = '' then Continue;
      if not SameText(Id, 'ask_ai') and not IsAgentChipId(Id) and not CatalogIsAllowedActionId(Id) then
        Continue;
      Btn := TsSpeedButton.Create(Self);
      Btn.Parent := PnlOfferActions;
      Btn.Flat := True;
      Btn.ShowCaption := True;
      Btn.ShowHint := True;
      Btn.Tag := FOfferActionIds.Add(Id);
      Btn.OnClick := OfferActionClick;
      StyleQuestionToolBtn(Btn);
    end;
  finally
    Parts.Free;
  end;
  LayoutOfferActionButtons;
  PnlOfferNext.Visible := True;
  PnlOfferNext.BringToFront;
end;

{ Captions come from the action ids, so this also re-localizes the chips. }
procedure TFastFileAssistantCtrl.LayoutOfferActionButtons;
var
  I, X, Y, Gap, RowH, NeedH: Integer;
  Cap: string;
  Btn: TsSpeedButton;
begin
  if not Assigned(PnlOfferActions) or not Assigned(FOfferActionIds) then Exit;
  Gap := 6;
  X := 0;
  Y := 2;
  RowH := 26;
  for I := 0 to PnlOfferActions.ControlCount - 1 do
  begin
    if not (PnlOfferActions.Controls[I] is TsSpeedButton) then Continue;
    Btn := TsSpeedButton(PnlOfferActions.Controls[I]);
    if (Btn.Tag < 0) or (Btn.Tag >= FOfferActionIds.Count) then Continue;
    Cap := OfferActionCaption(FOfferActionIds[Btn.Tag]);
    Btn.Caption := Cap;
    Btn.Hint := Cap;
    { Largura pelo texto completo; se nao couber na linha, wrap (sem cortar "Exportar"). }
    Btn.Width := Max(72, Canvas.TextWidth(Cap) + 18);
    if Btn.Width > Max(100, PnlOfferActions.ClientWidth - 8) then
      Btn.Width := Max(100, PnlOfferActions.ClientWidth - 8);
    if X + Btn.Width > Max(120, PnlOfferActions.ClientWidth - 4) then
    begin
      X := 0;
      Inc(Y, RowH + 4);
    end;
    Btn.SetBounds(X, Y, Btn.Width, RowH);
    Inc(X, Btn.Width + Gap);
  end;
  if Assigned(PnlOfferNext) and Assigned(LblOfferNext) then
  begin
    NeedH := 22 + LblOfferNext.Height + Y + RowH + 18;
    if NeedH < 88 then NeedH := 88;
    if NeedH > 220 then NeedH := 220;
    PnlOfferNext.Height := NeedH;
  end;
end;

procedure TFastFileAssistantCtrl.FileNoticeOpenClick(Sender: TObject);
begin
  if (FGeneratedFilePath = '') or (not FileExists(FGeneratedFilePath)) then Exit;
  ShellExecute(0, 'open', PChar(FGeneratedFilePath), nil, nil, SW_SHOWDEFAULT);
end;

procedure TFastFileAssistantCtrl.FileNoticeFolderClick(Sender: TObject);
var
  Param, DirPath: string;
begin
  if FGeneratedFilePath = '' then Exit;
  DirPath := ExtractFileDir(FGeneratedFilePath);
  if DirPath = '' then Exit;
  if FileExists(FGeneratedFilePath) then
    Param := Format('/select,"%s"', [FGeneratedFilePath])
  else
    Param := Format('"%s"', [DirPath]);
  ShellExecute(0, 'open', 'explorer.exe', PChar(Param), nil, SW_SHOWDEFAULT);
end;

procedure TFastFileAssistantCtrl.FileNoticeCopyClick(Sender: TObject);
begin
  if FGeneratedFilePath = '' then Exit;
  Clipboard.AsText := FGeneratedFilePath;
  SetStatusCaption(TrText('Assistant.Status.CopiedToClipboard'));
end;

procedure TFastFileAssistantCtrl.FileNoticeDetailsClick(Sender: TObject);
var
  LastPath: string;
  Recs: Int64;
begin
  if (FGeneratedFilePath = '') or (not FileExists(FGeneratedFilePath)) then Exit;
  if LastGeneratedFile(LastPath, Recs) and SameFileName(LastPath, FGeneratedFilePath) then
    ShowLastGeneratedFileDialog
  else
    ShowGeneratedFileDialog(FGeneratedFilePath, -1);
end;

function TFastFileAssistantCtrl.IsValidatableComposeSource(const APath: string): Boolean;
begin
  Result := IsValidatableComposeSourcePath(APath);
end;

function TFastFileAssistantCtrl.TryPickSourceToValidate(out APath: string): Boolean;
var
  Dlg: TOpenDialog;
begin
  Result := False;
  APath := '';
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Title := TrText('Assistant.Validate.PickTitle');
    Dlg.Filter := ValidatableSourceOpenDialogFilter;
    Dlg.FilterIndex := 1;
    Dlg.Options := Dlg.Options + [ofFileMustExist, ofPathMustExist, ofHideReadOnly,
      ofEnableSizing];
    if not Dlg.Execute then
      Exit;
    APath := Trim(Dlg.FileName);
    Result := APath <> '';
  finally
    Dlg.Free;
  end;
end;

function TFastFileAssistantCtrl.ResolveValidateSourcePath(const AUserQ: string;
  AAllowDialog: Boolean; out APath: string; out AMsg: string): Boolean;
var
  WantLoad: Boolean;
begin
  Result := False;
  APath := '';
  AMsg := '';
  WantLoad := UserWantsLoadSourceToValidate(AUserQ);
  APath := Trim(ExtractPathFromUserText(AUserQ));
  if APath = '' then
  begin
    APath := Trim(FGeneratedFilePath);
    if APath = '' then
      APath := Trim(GLastComposePath);
    if (APath = '') or WantLoad then
    begin
      if (not WantLoad) and IsValidatableComposeSourcePath(AssistantHostGetOpenFilePath) then
        APath := Trim(AssistantHostGetOpenFilePath)
      else if AAllowDialog and (WantLoad or (APath = '') or
        (not IsValidatableComposeSourcePath(APath))) then
      begin
        if not TryPickSourceToValidate(APath) then
        begin
          AMsg := TrText('Assistant.Validate.Cancelled');
          Exit;
        end;
      end;
    end;
  end;
  if Trim(APath) = '' then
  begin
    AMsg := TrText('Assistant.Validate.NeedPath') + #13#10#13#10 +
      TrText('Assistant.Validate.SupportedLanguages');
    Exit;
  end;
  { Extension gate first — before FileExists / companion download. }
  if not IsValidatableComposeSourcePath(APath) then
  begin
    AMsg := TrText('Assistant.Validate.Unsupported') + #13#10#13#10 +
      TrText('Assistant.Validate.SupportedLanguages');
    Exit;
  end;
  if not FileExists(APath) then
  begin
    AMsg := TrText('Assistant.Validate.FileMissing') + ' ' + APath;
    Exit;
  end;
  Result := True;
end;

function TFastFileAssistantCtrl.FormatValidateSourceReport(const APath: string;
  AOk: Boolean; const AReport: string): string;
var
  Report: string;
begin
  Report := Trim(AReport);
  if Report = '' then
  begin
    if AOk then
      Report := TrText('Assistant.Validate.Ok')
    else
      Report := TrText('Assistant.Validate.Failed');
  end
  else if AOk and ((Report = 'OK') or (Copy(Report, 1, 2) = 'OK')) then
    Report := TrText('Assistant.Validate.Ok') + #13#10 + Report
  else if not AOk then
    Report := TrText('Assistant.Validate.Failed') + #13#10 + Report;
  Result := APath + #13#10 + Report;
end;

function TFastFileAssistantCtrl.RunValidateSourcePath(const APath: string;
  AOpenInEditor: Boolean): string;
var
  Report: string;
  Ok: Boolean;
begin
  Result := '';
  if AOpenInEditor and FileExists(APath) then
    AssistantHostOpenAndRead(APath);
  FBusy := True;
  if Assigned(BtnFileNoticeValidate) then
    BtnFileNoticeValidate.Enabled := False;
  BtnSend.Enabled := False;
  SetStatusCaption(TrText('Assistant.Validate.Running'));
  BeginAssistantWait(TrText('Assistant.Validate.Running'));
  try
    Ok := AssistantHostValidateComposedSource(APath, Report);
  except
    on E: Exception do
    begin
      Ok := False;
      Report := E.Message;
    end;
  end;
  EndAssistantWait;
  FBusy := False;
  BtnSend.Enabled := True;
  if Assigned(BtnFileNoticeValidate) then
    BtnFileNoticeValidate.Enabled := True;
  Result := FormatValidateSourceReport(APath, Ok, Report);
  FLastReplyBody := Result;
  if Assigned(MemoReply) then
    MemoReply.Lines.Text := Result;
  if Ok then
    SetStatusCaption(TrText('Assistant.Validate.Ok'))
  else
    SetStatusCaption(TrText('Assistant.Validate.Failed'));
  AssistantWriteLog('validate-source: ' + APath + ' ok=' + BoolToStr(Ok, True));
end;

function TFastFileAssistantCtrl.TryHandleValidateSourceChat: Boolean;
var
  UserQ, Path, Msg: string;
  OpenInEditor: Boolean;
begin
  Result := False;
  UserQ := Trim(MemoQuestion.Text);
  if UserQ = '' then Exit;

  if UserAsksValidateSupportedLanguages(UserQ) and
     not UserWantsValidateSource(UserQ) then
  begin
    FLastReplyBody := TrText('Assistant.Validate.SupportedLanguages');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    AssistantWriteLog('validate-source: list supported languages');
    Result := True;
    Exit;
  end;

  if not UserWantsValidateSource(UserQ) then Exit;

  OpenInEditor := UserWantsLoadSourceToValidate(UserQ) or
    (ExtractPathFromUserText(UserQ) <> '');
  if not ResolveValidateSourcePath(UserQ, True, Path, Msg) then
  begin
    FLastReplyBody := Msg;
    if FLastReplyBody = '' then
      FLastReplyBody := TrText('Assistant.Validate.NeedPath');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Result := True;
    Exit;
  end;

  RunValidateSourcePath(Path, OpenInEditor);
  Result := True;
end;

procedure TFastFileAssistantCtrl.FileNoticeValidateClick(Sender: TObject);
var
  Path, Msg: string;
begin
  if FBusy then Exit;
  Path := Trim(FGeneratedFilePath);
  if Path = '' then
    Path := Trim(GLastComposePath);
  if not IsValidatableComposeSource(Path) then
  begin
    Msg := TrText('Assistant.Validate.Unsupported') + #13#10#13#10 +
      TrText('Assistant.Validate.SupportedLanguages');
    FLastReplyBody := Msg;
    if Assigned(MemoReply) then
      MemoReply.Lines.Text := Msg;
    SetStatusCaption(TrText('Assistant.Validate.Unsupported'));
    Exit;
  end;
  if not FileExists(Path) then
  begin
    SetStatusCaption(TrText('Assistant.Validate.FileMissing'));
    Exit;
  end;
  RunValidateSourcePath(Path, False);
end;

procedure TFastFileAssistantCtrl.FileNoticeDismissClick(Sender: TObject);
begin
  HideGeneratedFileNotice;
end;

procedure TFastFileAssistantCtrl.BuildFormLayout;
const
  BH = 32;
begin
  if FLayoutBuilt then Exit;
  FLayoutBuilt := True;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color := ASSISTANT_TOOLBAR_MID;
  ParentBackground := False;
  BevelOuter := bvNone;
  OnResize := LayoutInputControls;

  PnlAccent := TsPanel.Create(Self);
  PnlAccent.Parent := Self;
  PnlAccent.Align := alLeft;
  PnlAccent.Width := ASSISTANT_ACCENT_W;
  PnlAccent.Visible := ASSISTANT_ACCENT_W > 0;
  PnlAccent.BevelOuter := bvNone;
  PnlAccent.Caption := '';
  PnlAccent.ParentBackground := False;
  PnlAccent.Color := IDLE_WORKSPACE_GRAD_RIGHT;

  PnlHeader := TAssistantHeaderPanel.Create(Self);
  PnlHeader.Parent := Self;
  PnlHeader.Align := alTop;
  PnlHeader.Height := ASSISTANT_HEADER_H;
  PnlHeader.BevelOuter := bvNone;
  PnlHeader.Caption := '';
  PnlHeader.ParentBackground := False;
  PnlHeader.Color := ASSISTANT_TOOLBAR_MID;
  PnlHeader.GradTop := ASSISTANT_TOOLBAR_LIGHT;
  PnlHeader.GradBot := ASSISTANT_TOOLBAR_MID;
  PnlHeader.Padding.Left := 12;
  PnlHeader.Padding.Right := 6;
  PnlHeader.Padding.Top := 4;
  PnlHeader.Padding.Bottom := 4;

  BtnFloat := TButton.Create(Self);
  BtnFloat.Parent := PnlHeader;
  BtnFloat.Align := alRight;
  BtnFloat.Width := 28;
  BtnFloat.Caption := #$2197;
  BtnFloat.Hint := TrText('Panel.UndockHint');
  BtnFloat.ShowHint := True;
  BtnFloat.TabStop := False;
  BtnFloat.OnClick := BtnFloatClick;

  FPopDock := TPopupMenu.Create(Self);
  FMiFloat := TMenuItem.Create(FPopDock);
  FMiFloat.OnClick := BtnFloatClick;
  FPopDock.Items.Add(FMiFloat);
  PnlHeader.PopupMenu := FPopDock;

  LblTitle := TLabel.Create(Self);
  LblTitle.Parent := PnlHeader;
  LblTitle.Align := alClient;
  LblTitle.Layout := tlCenter;
  LblTitle.Caption := TrText('Assistant.Title');
  LblTitle.Font.Style := [fsBold];
  LblTitle.Transparent := True;
  ApplyHeaderDragChrome;

  PnlHeaderSep := TsPanel.Create(Self);
  PnlHeaderSep.Parent := Self;
  PnlHeaderSep.Align := alTop;
  PnlHeaderSep.Height := 1;
  PnlHeaderSep.BevelOuter := bvNone;
  PnlHeaderSep.Caption := '';
  PnlHeaderSep.ParentBackground := False;
  PnlHeaderSep.Color := ASSISTANT_TOOLBAR_EDGE;

  EnsureFileNoticeBanner;

  PnlInput := TsPanel.Create(Self);
  PnlInput.Parent := Self;
  PnlInput.Align := alTop;
  PnlInput.Height := FfPx(ASSISTANT_INPUT_DEFAULT_H);
  PnlInput.BevelOuter := bvNone;
  PnlInput.Caption := '';
  PnlInput.ParentBackground := False;
  PnlInput.Color := ASSISTANT_TOOLBAR_MID;
  PnlInput.OnResize := LayoutInputControls;

  LblPrompt := TLabel.Create(Self);
  LblPrompt.Parent := PnlInput;
  LblPrompt.AutoSize := False;
  LblPrompt.Layout := tlCenter;
  LblPrompt.Caption := TrText('Assistant.WhatDoYouWant');

  MemoDraftHint := TMemo.Create(Self);
  MemoDraftHint.Parent := PnlInput;
  MemoDraftHint.BorderStyle := bsSingle;
  MemoDraftHint.ReadOnly := True;
  MemoDraftHint.WordWrap := True;
  MemoDraftHint.ScrollBars := ssVertical;
  MemoDraftHint.WantReturns := True;
  MemoDraftHint.WantTabs := False;
  MemoDraftHint.Visible := False;
  MemoDraftHint.Cursor := crHandPoint;
  MemoDraftHint.ShowHint := True;
  MemoDraftHint.ParentColor := False;
  MemoDraftHint.Color := ASSISTANT_BADGE_BG;
  MemoDraftHint.TabStop := False;
  MemoDraftHint.OnDblClick := OfferQuestionHintClick;

  BtnClearHint := TsSpeedButton.Create(Self);
  BtnClearHint.Parent := PnlInput;
  BtnClearHint.Visible := False;
  BtnClearHint.OnClick := BtnClearHintClick;
  StyleQuestionToolBtn(BtnClearHint);
  BtnClearHint.Caption := TrText('Assistant.ClearReply');
  BtnClearHint.Hint := TrText('Assistant.Offer.DraftClearHint');
  SizeQuestionToolBtn(BtnClearHint, ASSISTANT_CLEAR_TOOL_BTN_W);

  BtnCopyHint := TsSpeedButton.Create(Self);
  BtnCopyHint.Parent := PnlInput;
  BtnCopyHint.Visible := False;
  BtnCopyHint.OnClick := BtnCopyHintClick;
  StyleQuestionToolBtn(BtnCopyHint);
  BtnCopyHint.Caption := TrText('Assistant.CopyReply');
  BtnCopyHint.Hint := TrText('Assistant.Offer.DraftCopyHint');
  SizeQuestionToolBtn(BtnCopyHint, ASSISTANT_COPY_TOOL_BTN_W);

  PnlShortcutBadgeShell := TsPanel.Create(Self);
  PnlShortcutBadgeShell.Parent := PnlInput;
  PnlShortcutBadgeShell.Align := alNone;
  PnlShortcutBadgeShell.Width := ASSISTANT_SHORTCUT_BADGE_W;
  PnlShortcutBadgeShell.Height := 24;
  PnlShortcutBadgeShell.BevelOuter := bvNone;
  PnlShortcutBadgeShell.Caption := '';
  PnlShortcutBadgeShell.ParentBackground := False;
  PnlShortcutBadgeShell.Color := ASSISTANT_TOOLBAR_EDGE;
  PnlShortcutBadgeShell.Padding.Left := 1;
  PnlShortcutBadgeShell.Padding.Top := 1;
  PnlShortcutBadgeShell.Padding.Right := 1;
  PnlShortcutBadgeShell.Padding.Bottom := 1;

  PnlShortcutBadge := TsPanel.Create(Self);
  PnlShortcutBadge.Parent := PnlShortcutBadgeShell;
  PnlShortcutBadge.Align := alClient;
  PnlShortcutBadge.BevelOuter := bvNone;
  PnlShortcutBadge.Caption := '';
  PnlShortcutBadge.ParentBackground := False;
  PnlShortcutBadge.Color := ASSISTANT_BADGE_BG;
  PnlShortcutBadge.Padding.Left := 6;
  PnlShortcutBadge.Padding.Right := 6;

  LblShortcut := TLabel.Create(Self);
  LblShortcut.Parent := PnlShortcutBadge;
  LblShortcut.Align := alClient;
  LblShortcut.Alignment := taCenter;
  LblShortcut.Layout := tlCenter;
  LblShortcut.Caption := 'Ctrl+Alt+A';
  LblShortcut.Transparent := True;
  LblShortcut.Font.Color := clGrayText;

  BtnHide := TButton.Create(Self);
  BtnHide.Parent := PnlInput;
  BtnHide.Align := alNone;
  BtnHide.Width := ASSISTANT_HIDE_BTN_W;
  BtnHide.Height := 24;
  BtnHide.Caption := #$00D7;
  BtnHide.Hint := TrText('Close');
  BtnHide.ShowHint := True;
  BtnHide.TabStop := False;
  BtnHide.OnClick := BtnHideClick;

  LblRecentQuestions := TLabel.Create(Self);
  LblRecentQuestions.Parent := PnlInput;
  LblRecentQuestions.AutoSize := False;
  LblRecentQuestions.Caption := TrText('Assistant.RecentQuestions');
  LblRecentQuestions.Font.Color := clGrayText;

  PnlRecentCombo := TPanel.Create(Self);
  PnlRecentCombo.Parent := PnlInput;
  PnlRecentCombo.BevelOuter := bvNone;
  PnlRecentCombo.BevelInner := bvNone;
  PnlRecentCombo.BorderStyle := bsSingle;
  PnlRecentCombo.Caption := '';
  PnlRecentCombo.ParentColor := False;
  PnlRecentCombo.ParentBackground := False;
  PnlRecentCombo.Color := clWindow;
  PnlRecentCombo.ShowHint := False;
  PnlRecentCombo.ParentShowHint := False;
  PnlRecentCombo.OnClick := RecentComboClick;
  LblRecentComboArrow := TLabel.Create(Self);
  LblRecentComboArrow.Parent := PnlRecentCombo;
  LblRecentComboArrow.Align := alRight;
  LblRecentComboArrow.AutoSize := False;
  LblRecentComboArrow.Width := 18;
  LblRecentComboArrow.Alignment := taCenter;
  LblRecentComboArrow.Layout := tlCenter;
  LblRecentComboArrow.Caption := #$25BE;
  LblRecentComboArrow.Transparent := True;
  LblRecentComboArrow.OnClick := RecentComboClick;
  LblRecentCombo := TLabel.Create(Self);
  LblRecentCombo.Parent := PnlRecentCombo;
  LblRecentCombo.Align := alClient;
  LblRecentCombo.Layout := tlCenter;
  LblRecentCombo.AutoSize := False;
  LblRecentCombo.Caption := '';
  LblRecentCombo.Transparent := True;
  LblRecentCombo.OnClick := RecentComboClick;

  BtnRecentFind := TsSpeedButton.Create(Self);
  BtnRecentFind.Parent := PnlInput;
  BtnRecentFind.Flat := True;
  BtnRecentFind.ShowCaption := False;
  BtnRecentFind.ShowHint := True;
  BtnRecentFind.ParentShowHint := False;
  BtnRecentFind.Width := MRU_FIND_BTN_W;
  BtnRecentFind.Height := 24;
  try
    BtnRecentFind.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
  BtnRecentFind.Hint := TrText('MRU.FindHint');
  BtnRecentFind.Visible := False;
  BtnRecentFind.OnClick := BtnRecentFindClick;

  EdtRecentFind := TEdit.Create(Self);
  EdtRecentFind.Parent := PnlInput;
  EdtRecentFind.Visible := False;
  EdtRecentFind.Hint := TrText('MRU.FindHint');
  EdtRecentFind.ShowHint := True;
  EdtRecentFind.OnChange := EdtRecentFindChange;
  EdtRecentFind.OnKeyDown := EdtRecentFindKeyDown;

  BtnRecentFindClear := TsSpeedButton.Create(Self);
  BtnRecentFindClear.Parent := PnlInput;
  BtnRecentFindClear.Flat := True;
  BtnRecentFindClear.ShowCaption := True;
  BtnRecentFindClear.Caption := #$00D7;
  BtnRecentFindClear.ShowHint := True;
  BtnRecentFindClear.ParentShowHint := False;
  BtnRecentFindClear.Hint := TrText('MRU.ClearFind');
  BtnRecentFindClear.Width := MRU_FIND_BTN_W;
  BtnRecentFindClear.Height := 24;
  BtnRecentFindClear.Visible := False;
  try
    BtnRecentFindClear.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
  BtnRecentFindClear.OnClick := BtnRecentFindClearClick;

  PnlQuestionShell := TsPanel.Create(Self);
  PnlQuestionShell.Parent := PnlInput;
  PnlQuestionShell.BevelOuter := bvNone;
  PnlQuestionShell.Caption := '';
  PnlQuestionShell.ParentBackground := False;
  PnlQuestionShell.Color := ASSISTANT_TOOLBAR_EDGE;
  PnlQuestionShell.Padding.Left := 1;
  PnlQuestionShell.Padding.Top := 1;
  PnlQuestionShell.Padding.Right := 1;
  PnlQuestionShell.Padding.Bottom := 1;

  PnlQuestionTools := TsPanel.Create(Self);
  PnlQuestionTools.Parent := PnlQuestionShell;
  PnlQuestionTools.Align := alBottom;
  PnlQuestionTools.Height := ASSISTANT_TOOLS_BAR_H;
  PnlQuestionTools.BevelOuter := bvNone;
  PnlQuestionTools.BevelInner := bvNone;
  PnlQuestionTools.Caption := '';
  PnlQuestionTools.ParentBackground := False;
  PnlQuestionTools.Color := ASSISTANT_TOOLBAR_MID;

  PnlQuestionToolsSep := TsPanel.Create(Self);
  PnlQuestionToolsSep.Parent := PnlQuestionTools;
  PnlQuestionToolsSep.Align := alTop;
  PnlQuestionToolsSep.Height := 1;
  PnlQuestionToolsSep.BevelOuter := bvNone;
  PnlQuestionToolsSep.Caption := '';
  PnlQuestionToolsSep.ParentBackground := False;
  PnlQuestionToolsSep.Color := ASSISTANT_TOOLBAR_EDGE;

  BtnTranslate := TsSpeedButton.Create(Self);
  BtnTranslate.Parent := PnlQuestionTools;
  BtnTranslate.Caption := TrText('Assistant.TranslateBtn') + ' ' + #$25BE;
  BtnTranslate.Hint := TrText('Assistant.TranslateHint');
  BtnTranslate.OnClick := BtnTranslateClick;
  StyleQuestionToolBtn(BtnTranslate);
  SizeQuestionToolBtn(BtnTranslate, ASSISTANT_TRANSLATE_BTN_W);
  BtnTranslate.AlignWithMargins := True;
  BtnTranslate.Margins.SetBounds(6, 4, 2, 4);
  BtnTranslate.Align := alLeft;

  BtnRewrite := TsSpeedButton.Create(Self);
  BtnRewrite.Parent := PnlQuestionTools;
  BtnRewrite.Caption := TrText('Assistant.RewriteBtn');
  BtnRewrite.Hint := TrText('Assistant.RewriteHint');
  BtnRewrite.OnClick := BtnRewriteClick;
  StyleQuestionToolBtn(BtnRewrite);
  SizeQuestionToolBtn(BtnRewrite, ASSISTANT_REWRITE_BTN_W);
  BtnRewrite.AlignWithMargins := True;
  BtnRewrite.Margins.SetBounds(2, 4, 4, 4);
  BtnRewrite.Align := alLeft;

  BtnAgentMode := TsSpeedButton.Create(Self);
  BtnAgentMode.Parent := PnlQuestionTools;
  BtnAgentMode.GroupIndex := 7101;
  BtnAgentMode.AllowAllUp := True;
  BtnAgentMode.OnClick := BtnAgentModeClick;
  StyleQuestionToolBtn(BtnAgentMode);
  LocalizeAgentModeBtn;
  AgentBridgeSetListener(AgentBridgeEvent);

  BtnClearReply := TsSpeedButton.Create(Self);
  BtnClearReply.Parent := PnlQuestionTools;
  BtnClearReply.Caption := TrText('Assistant.ClearReply');
  BtnClearReply.Hint := TrText('Assistant.ClearReply');
  BtnClearReply.OnClick := BtnClearReplyClick;
  StyleQuestionToolBtn(BtnClearReply);
  SizeQuestionToolBtn(BtnClearReply, ASSISTANT_CLEAR_TOOL_BTN_W);

  BtnCopyReply := TsSpeedButton.Create(Self);
  BtnCopyReply.Parent := PnlQuestionTools;
  BtnCopyReply.Caption := TrText('Assistant.CopyReply');
  BtnCopyReply.Hint := TrText('Assistant.CopyReply');
  BtnCopyReply.OnClick := BtnCopyReplyClick;
  StyleQuestionToolBtn(BtnCopyReply);
  SizeQuestionToolBtn(BtnCopyReply, ASSISTANT_COPY_TOOL_BTN_W);

  BtnPython := TsSpeedButton.Create(Self);
  BtnPython.Parent := PnlQuestionTools;
  BtnPython.Caption := TrText('Assistant.PythonBtn');
  BtnPython.Hint := TrText('Assistant.PythonHint');
  BtnPython.ShowHint := True;
  BtnPython.OnClick := BtnPythonClick;
  StyleQuestionToolBtn(BtnPython);
  SizeQuestionToolBtn(BtnPython, ASSISTANT_PYTHON_BTN_W);

  BtnComposeFormats := TsSpeedButton.Create(Self);
  BtnComposeFormats.Parent := PnlQuestionTools;
  BtnComposeFormats.Caption := '?';
  BtnComposeFormats.Hint := TrText('Assistant.ComposeFormats.Hint');
  BtnComposeFormats.OnClick := BtnComposeFormatsClick;
  StyleQuestionToolBtn(BtnComposeFormats);
  BtnComposeFormats.Width := ASSISTANT_HELP_TOOL_BTN_W;
  BtnComposeFormats.Height := ASSISTANT_TOOL_BTN_H;

  PnlQuestionFrame := TsPanel.Create(Self);
  PnlQuestionFrame.Parent := PnlQuestionShell;
  PnlQuestionFrame.Align := alClient;
  PnlQuestionFrame.BevelOuter := bvNone;
  PnlQuestionFrame.BevelInner := bvNone;
  PnlQuestionFrame.BorderWidth := 0;
  PnlQuestionFrame.Caption := '';
  PnlQuestionFrame.ParentBackground := False;
  PnlQuestionFrame.Color := clWindow;

  BtnClearQuestion := TButton.Create(Self);
  BtnClearQuestion.Parent := PnlQuestionFrame;
  BtnClearQuestion.Caption := #$00D7;
  BtnClearQuestion.Hint := TrText('Assistant.ClearQuestion');
  BtnClearQuestion.ShowHint := True;
  BtnClearQuestion.TabStop := False;
  BtnClearQuestion.Visible := False;
  BtnClearQuestion.OnClick := BtnClearQuestionClick;

  BuildTranslateLangMenu;

  MemoQuestion := TAssistantMemo.Create(Self);
  TAssistantMemo(MemoQuestion).AllowVertScroll := True;
  MemoQuestion.Parent := PnlQuestionFrame;
  MemoQuestion.ScrollBars := ssNone;
  MemoQuestion.WordWrap := True;
  MemoQuestion.WantReturns := False;
  MemoQuestion.WantTabs := False;
  MemoQuestion.BorderStyle := bsNone;
  MemoQuestion.MaxLength := ASSISTANT_QUESTION_MAX_CHARS;
  MemoQuestion.OnChange := MemoQuestionChange;
  FLastAssistantMemo := MemoQuestion;

  LblQuestionCharCount := TLabel.Create(Self);
  LblQuestionCharCount.Parent := PnlQuestionFrame;
  LblQuestionCharCount.AutoSize := False;
  LblQuestionCharCount.Alignment := taRightJustify;
  LblQuestionCharCount.Layout := tlCenter;
  LblQuestionCharCount.Caption := IntToStr(ASSISTANT_QUESTION_MAX_CHARS);
  LblQuestionCharCount.Hint := TrText('Assistant.CharCountHint');
  LblQuestionCharCount.ShowHint := True;
  LblQuestionCharCount.Transparent := True;

  BtnSend := TButton.Create(Self);
  BtnSend.Parent := PnlInput;
  BtnSend.Caption := TrText('Assistant.Send');
  BtnSend.Width := 96;
  BtnSend.Height := BH;
  BtnSend.Default := False;
  BtnSend.OnClick := BtnSendClick;

  BtnExecute := TButton.Create(Self);
  BtnExecute.Parent := PnlInput;
  BtnExecute.Caption := TrText('Assistant.Execute');
  BtnExecute.Width := 110;
  BtnExecute.Height := BH;
  BtnExecute.Enabled := False;
  BtnExecute.OnClick := BtnExecuteClick;

  ChkDontShowAgain := TCheckBox.Create(Self);
  ChkDontShowAgain.Parent := PnlInput;
  ChkDontShowAgain.Caption := '';
  ChkDontShowAgain.Width := ASSISTANT_CHK_GLYPH_W;

  LblDontShowAgain := TLabel.Create(Self);
  LblDontShowAgain.Parent := PnlInput;
  LblDontShowAgain.Caption := TrText('Assistant.DontShowAgain');
  LblDontShowAgain.WordWrap := True;
  LblDontShowAgain.AutoSize := False;
  LblDontShowAgain.Cursor := crHandPoint;
  LblDontShowAgain.OnClick := LblDontShowAgainClick;

  LblStatus := TLabel.Create(Self);
  LblStatus.Parent := PnlInput;
  LblStatus.AutoSize := False;
  LblStatus.WordWrap := True;
  LblStatus.Caption := '';

  FGripInputBot := TFastFileEdgeGrip.CreateGrip(Self, Self, fgBottom);
  FGripInputBot.Align := alTop;
  FGripInputBot.Height := ASSISTANT_INPUT_SPLIT_H;
  FGripInputBot.ResizeTarget := PnlInput;
  FGripInputBot.MinSize := FfPx(ASSISTANT_INPUT_MIN_H);
  FGripInputBot.MaxSize := 700;
  FGripInputBot.Hint := TrText('Assistant.SplitHint');
  FGripInputBot.OnResized := AssistantGripResized;

  SplInputReply := TsSplitter.Create(Self);
  SplInputReply.Parent := Self;
  SplInputReply.Align := alNone;
  SplInputReply.Height := 0;
  SplInputReply.Visible := False;

  PnlReply := TsPanel.Create(Self);
  PnlReply.Parent := Self;
  PnlReply.Align := alClient;
  PnlReply.BevelOuter := bvNone;
  PnlReply.Caption := '';
  PnlReply.ParentBackground := False;
  PnlReply.Color := ASSISTANT_TOOLBAR_MID;
  PnlReply.Padding.Left := ASSISTANT_PAD;
  PnlReply.Padding.Right := ASSISTANT_PAD;
  PnlReply.Padding.Bottom := ASSISTANT_PAD;
  PnlReply.Padding.Top := 8;

  PnlReplyCapRow := TsPanel.Create(Self);
  PnlReplyCapRow.Parent := PnlReply;
  PnlReplyCapRow.Align := alTop;
  PnlReplyCapRow.Height := 30;
  PnlReplyCapRow.BevelOuter := bvNone;
  PnlReplyCapRow.Caption := '';
  PnlReplyCapRow.ParentBackground := False;
  PnlReplyCapRow.Color := ASSISTANT_TOOLBAR_MID;
  PnlReplyCapRow.Padding.Left := 4;
  PnlReplyCapRow.Padding.Right := 4;
  PnlReplyCapRow.Padding.Top := 2;
  PnlReplyCapRow.Padding.Bottom := 2;

  PnlReplyCapAccent := TsPanel.Create(Self);
  PnlReplyCapAccent.Parent := PnlReplyCapRow;
  PnlReplyCapAccent.Align := alLeft;
  PnlReplyCapAccent.Width := ASSISTANT_CAP_ACCENT_W;
  PnlReplyCapAccent.Visible := ASSISTANT_CAP_ACCENT_W > 0;
  PnlReplyCapAccent.BevelOuter := bvNone;
  PnlReplyCapAccent.Caption := '';
  PnlReplyCapAccent.ParentBackground := False;
  PnlReplyCapAccent.Color := IDLE_WORKSPACE_GRAD_RIGHT;

  LblReplyCaption := TLabel.Create(Self);
  LblReplyCaption.Parent := PnlReplyCapRow;
  LblReplyCaption.Align := alClient;
  LblReplyCaption.Layout := tlCenter;
  LblReplyCaption.AutoSize := False;
  LblReplyCaption.Caption := TrText('Assistant.Reply');
  LblReplyCaption.Font.Style := [fsBold];
  LblReplyCaption.Font.Color := clWindowText;
  LblReplyCaption.Transparent := True;

  PnlReplyStyleRow := TsPanel.Create(Self);
  PnlReplyStyleRow.Parent := PnlReply;
  PnlReplyStyleRow.Align := alTop;
  PnlReplyStyleRow.Height := 30;
  PnlReplyStyleRow.BevelOuter := bvNone;
  PnlReplyStyleRow.Caption := '';
  PnlReplyStyleRow.ParentBackground := False;
  PnlReplyStyleRow.Color := ASSISTANT_TOOLBAR_MID;
  PnlReplyStyleRow.Padding.Left := 4;
  PnlReplyStyleRow.Padding.Right := 4;

  LblReplyStyle := TLabel.Create(Self);
  LblReplyStyle.Parent := PnlReplyStyleRow;
  LblReplyStyle.Align := alLeft;
  LblReplyStyle.AutoSize := False;
  LblReplyStyle.Width := 48;
  LblReplyStyle.Layout := tlCenter;
  LblReplyStyle.Caption := TrText('Assistant.ReplyStyle.Label');
  LblReplyStyle.Transparent := True;

  BtnReplyStyleEdit := TsSpeedButton.Create(Self);
  BtnReplyStyleEdit.Parent := PnlReplyStyleRow;
  BtnReplyStyleEdit.Align := alRight;
  BtnReplyStyleEdit.Width := 78;
  BtnReplyStyleEdit.Flat := True;
  BtnReplyStyleEdit.ShowCaption := True;
  BtnReplyStyleEdit.Caption := TrText('Assistant.ReplyStyle.Edit');
  BtnReplyStyleEdit.Hint := TrText('Assistant.ReplyStyle.EditHint');
  BtnReplyStyleEdit.ShowHint := True;
  BtnReplyStyleEdit.OnClick := BtnReplyStyleEditClick;

  CmbReplyStyle := TComboBox.Create(Self);
  CmbReplyStyle.Parent := PnlReplyStyleRow;
  CmbReplyStyle.Align := alClient;
  CmbReplyStyle.Style := csDropDownList;
  CmbReplyStyle.OnChange := CmbReplyStyleChange;

  { Soft card border around reply memo. }
  PnlReplyShell := TsPanel.Create(Self);
  PnlReplyShell.Parent := PnlReply;
  PnlReplyShell.Align := alClient;
  PnlReplyShell.BevelOuter := bvNone;
  PnlReplyShell.Caption := '';
  PnlReplyShell.ParentBackground := False;
  PnlReplyShell.Color := ASSISTANT_TOOLBAR_EDGE;
  PnlReplyShell.Padding.Left := 1;
  PnlReplyShell.Padding.Top := 1;
  PnlReplyShell.Padding.Right := 1;
  PnlReplyShell.Padding.Bottom := 1;

  PnlReplySurface := TsPanel.Create(Self);
  PnlReplySurface.Parent := PnlReplyShell;
  PnlReplySurface.Align := alClient;
  PnlReplySurface.BevelOuter := bvNone;
  PnlReplySurface.BevelInner := bvNone;
  PnlReplySurface.Caption := '';
  PnlReplySurface.ParentBackground := False;
  PnlReplySurface.Color := IDLE_WORKSPACE_GRAD_LEFT;
  PnlReplySurface.Padding.Left := 8;
  PnlReplySurface.Padding.Right := 6;
  PnlReplySurface.Padding.Top := 6;
  PnlReplySurface.Padding.Bottom := 6;

  MemoReply := TAssistantMemo.Create(Self);
  MemoReply.Parent := PnlReplySurface;
  MemoReply.Align := alClient;
  MemoReply.ReadOnly := True;
  MemoReply.ScrollBars := ssNone;
  MemoReply.WordWrap := True;
  MemoReply.WantReturns := True;
  MemoReply.WantTabs := False;
  MemoReply.BorderStyle := bsNone;
  MemoReply.ParentColor := False;
  MemoReply.Color := IDLE_WORKSPACE_GRAD_LEFT;
  MemoReply.OnChange := MemoReplyChange;

  BuildMemoPopupMenus;
  SyncDontShowStartupCheckbox;
  LoadRecentQuestions;
  LoadReplyStylePrefs;
  FillReplyStyleCombo;
  ApplyRecentFindGlyphs;
  ApplyAssistantUiTexts;
  ApplyAssistantSoftChrome;
  LoadAssistantInputHeight;
  LayoutInputControls(nil);
end;

procedure TFastFileAssistantCtrl.BtnHideClick(Sender: TObject);
begin
  HideFastFileAssistantPanel;
end;

procedure TFastFileAssistantCtrl.BtnFloatClick(Sender: TObject);
begin
  if Assigned(FOnFloatClick) then
    FOnFloatClick(Self);
end;

procedure TFastFileAssistantCtrl.SyncFloatAction;
begin
  if Assigned(BtnFloat) then
  begin
    if FFloating then
    begin
      BtnFloat.Caption := #$2199;
      BtnFloat.Hint := TrText('Panel.DockHint');
    end
    else
    begin
      BtnFloat.Caption := #$2197;
      BtnFloat.Hint := TrText('Panel.RestoreFloatHint');
    end;
    BtnFloat.ShowHint := True;
  end;
  if Assigned(FMiFloat) then
  begin
    if FFloating then
      FMiFloat.Caption := TrText('Panel.Dock')
    else
      FMiFloat.Caption := TrText('Panel.RestoreFloat');
  end;
end;

procedure TFastFileAssistantCtrl.ApplyHeaderDragChrome;
var
  HintTxt: string;
begin
  if FFloating then
    HintTxt := TrText('Panel.DragDockHint')
  else
    HintTxt := TrText('Panel.DragUndockHint');
  if Assigned(PnlHeader) then
  begin
    PnlHeader.Cursor := crSizeAll;
    PnlHeader.ShowHint := True;
    PnlHeader.Hint := HintTxt;
    PnlHeader.OnMouseDown := HeaderMouseDown;
    PnlHeader.OnMouseMove := HeaderMouseMove;
    PnlHeader.OnMouseUp := HeaderMouseUp;
    PnlHeader.OnDblClick := HeaderDblClick;
  end;
  if Assigned(LblTitle) then
  begin
    LblTitle.Cursor := crSizeAll;
    LblTitle.ShowHint := True;
    LblTitle.Hint := HintTxt;
    LblTitle.OnMouseDown := HeaderMouseDown;
    LblTitle.OnMouseMove := HeaderMouseMove;
    LblTitle.OnMouseUp := HeaderMouseUp;
    LblTitle.OnDblClick := HeaderDblClick;
  end;
  AttachPanelDrag(Self, HeaderMouseDown, HeaderMouseMove, HeaderMouseUp,
    HeaderDblClick, HintTxt);
end;

procedure TFastFileAssistantCtrl.RestoreDockedStack;
begin
  DisableAlign;
  try
    if Assigned(PnlHeader) then
    begin
      PnlHeader.Align := alTop;
      PnlHeader.Height := ASSISTANT_HEADER_H;
      PnlHeader.Top := 0;
    end;
    if Assigned(PnlHeaderSep) then
    begin
      PnlHeaderSep.Align := alTop;
      PnlHeaderSep.Top := 1;
    end;
    if Assigned(PnlFileNotice) and PnlFileNotice.Visible then
    begin
      PnlFileNotice.Align := alTop;
      PnlFileNotice.Top := 2;
    end;
    if Assigned(PnlInput) then
    begin
      PnlInput.Align := alTop;
      PnlInput.Top := 10;
    end;
    if Assigned(FGripInputBot) then
    begin
      FGripInputBot.Align := alTop;
      FGripInputBot.Height := ASSISTANT_INPUT_SPLIT_H;
      FGripInputBot.Top := 11;
    end;
    if Assigned(PnlReply) then
      PnlReply.Align := alClient;
    Align := alClient;
  finally
    EnableAlign;
  end;
  if Assigned(PnlInput) then
  begin
    if PnlInput.Height < FfPx(ASSISTANT_INPUT_MIN_H) then
      PnlInput.Height := FfPx(ASSISTANT_INPUT_DEFAULT_H);
  end;
  ApplyAssistantSoftChrome;
  LayoutInputControls(nil);
end;

procedure TFastFileAssistantCtrl.PlaceAssistantGrips;
begin
  if Assigned(FGripInputBot) then
  begin
    FGripInputBot.Align := alTop;
    FGripInputBot.Height := ASSISTANT_INPUT_SPLIT_H;
    FGripInputBot.BringToFront;
  end;
end;

procedure TFastFileAssistantCtrl.AssistantGripResized(Sender: TObject);
begin
  PlaceAssistantGrips;
  SaveAssistantInputHeight;
end;

procedure TFastFileAssistantCtrl.HeaderDblClick(Sender: TObject);
begin
  if FFloating and Assigned(FOnFloatClick) then
    FOnFloatClick(Self);
end;

procedure TFastFileAssistantCtrl.HeaderMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHeaderDown := True;
  FHeaderPt := Point(X, Y);
  if Sender is TControl then
    SetCaptureControl(TControl(Sender));
end;

procedure TFastFileAssistantCtrl.HeaderMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not FHeaderDown then Exit;
  if (Abs(X - FHeaderPt.X) < FASTFILE_TEAR_THRESHOLD) and
     (Abs(Y - FHeaderPt.Y) < FASTFILE_TEAR_THRESHOLD) then
    Exit;
  FHeaderDown := False;
  SetCaptureControl(nil);
  if Assigned(FOnTearOff) then
    FOnTearOff(Self);
end;

procedure TFastFileAssistantCtrl.HeaderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FHeaderDown := False;
  SetCaptureControl(nil);
end;

procedure TFastFileAssistantCtrl.LoadAssistantInputHeight;
var
  Ini: TIniFile;
  H, MaxH: Integer;
begin
  if (FIniPath = '') or not Assigned(PnlInput) then Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    H := Ini.ReadInteger(APPLICATION_NAME, 'AssistantInputHeight', 0);
  finally
    Ini.Free;
  end;
  if H < FfPx(ASSISTANT_INPUT_MIN_H) then Exit;
  { Old builds locked this at 336+; start compact and let the user grow it. }
  if H >= FfPx(336) then
    H := FfPx(ASSISTANT_INPUT_DEFAULT_H);
  MaxH := ClientHeight - FfPx(160);
  if MaxH < FfPx(ASSISTANT_INPUT_MIN_H) then
    MaxH := FfPx(ASSISTANT_INPUT_MIN_H);
  if H > MaxH then
    H := MaxH;
  PnlInput.Height := H;
end;

procedure TFastFileAssistantCtrl.SaveAssistantInputHeight;
var
  Ini: TIniFile;
  H: Integer;
begin
  if (FIniPath = '') or not Assigned(PnlInput) then Exit;
  H := PnlInput.Height;
  if H < FfPx(ASSISTANT_INPUT_MIN_H) then
    H := FfPx(ASSISTANT_INPUT_MIN_H);
  Ini := TIniFile.Create(FIniPath);
  try
    Ini.WriteInteger(APPLICATION_NAME, 'AssistantInputHeight', H);
  finally
    Ini.Free;
  end;
end;

procedure TFastFileAssistantCtrl.MemoQuestionChange(Sender: TObject);
begin
  ClampQuestionToMaxChars;
  UpdateClearQuestionBtn;
  UpdateQuestionCharCount;
  SyncMemoAutoVertScroll(MemoQuestion);
end;

procedure TFastFileAssistantCtrl.MemoReplyChange(Sender: TObject);
begin
  SyncMemoAutoVertScroll(MemoReply);
end;

procedure TFastFileAssistantCtrl.BtnClearQuestionClick(Sender: TObject);
begin
  ClearQuestionText;
end;

procedure TFastFileAssistantCtrl.ClearQuestionText;
begin
  if not Assigned(MemoQuestion) then Exit;
  MemoQuestion.Clear;
  UpdateClearQuestionBtn;
  UpdateQuestionCharCount;
  if MemoQuestion.CanFocus then
    MemoQuestion.SetFocus;
end;

procedure TFastFileAssistantCtrl.UpdateClearQuestionBtn;
var
  HasText: Boolean;
begin
  if Assigned(BtnClearQuestion) then
  begin
    HasText := Assigned(MemoQuestion) and (Trim(MemoQuestion.Text) <> '');
    if BtnClearQuestion.Visible <> HasText then
    begin
      BtnClearQuestion.Visible := HasText;
      LayoutInputControls(nil);
    end;
  end;
  UpdateQuestionToolButtons;
end;

procedure TFastFileAssistantCtrl.ClampQuestionToMaxChars;
var
  S: string;
  OldChange: TNotifyEvent;
begin
  if not Assigned(MemoQuestion) then Exit;
  if Length(MemoQuestion.Text) <= ASSISTANT_QUESTION_MAX_CHARS then Exit;
  S := Copy(MemoQuestion.Text, 1, ASSISTANT_QUESTION_MAX_CHARS);
  OldChange := MemoQuestion.OnChange;
  MemoQuestion.OnChange := nil;
  try
    MemoQuestion.Text := S;
    MemoQuestion.SelStart := Length(S);
    MemoQuestion.SelLength := 0;
  finally
    MemoQuestion.OnChange := OldChange;
  end;
end;

procedure TFastFileAssistantCtrl.UpdateQuestionCharCount;
var
  Remain: Integer;
begin
  if not Assigned(LblQuestionCharCount) then Exit;
  Remain := ASSISTANT_QUESTION_MAX_CHARS;
  if Assigned(MemoQuestion) then
    Remain := ASSISTANT_QUESTION_MAX_CHARS - Length(MemoQuestion.Text);
  if Remain < 0 then
    Remain := 0;
  LblQuestionCharCount.Caption := IntToStr(Remain);
  if Remain <= 0 then
    LblQuestionCharCount.Font.Color := clRed
  else if Remain <= 20 then
    LblQuestionCharCount.Font.Color := $000080FF
  else
    LblQuestionCharCount.Font.Color := FChromeMuted;
end;

function AssistantLangMenuCaption(ALang: TAppLanguage): string;
begin
  case ALang of
    alPortuguese:   Result := 'Portugu'#234's (Brasil)';
    alSpanish:      Result := 'Espa'#241'ol';
    alFrench:       Result := 'Fran'#231'ais';
    alGerman:       Result := 'Deutsch';
    alItalian:      Result := 'Italiano';
    alPolish:       Result := 'Polski';
    alPortuguesePT: Result := 'Portugu'#234's (Portugal)';
    alRomanian:     Result := 'Rom'#226'n'#259;
    alHungarian:    Result := 'Magyar';
    alCzech:        Result := #268'e'#353'tina';
    alJapanese:     Result := '日本語';
    alChineseSimplified:  Result := '简体中文';
    alChineseTraditional: Result := '繁體中文';
  else
    Result := 'English';
  end;
end;

procedure TFastFileAssistantCtrl.SizeQuestionToolBtn(ABtn: TsSpeedButton; AMinW: Integer);
var
  Cap: string;
  NeedW: Integer;
  C: TControlCanvas;
begin
  if not Assigned(ABtn) then Exit;
  Cap := StringReplace(ABtn.Caption, '&', '', [rfReplaceAll]);
  NeedW := AMinW;
  C := TControlCanvas.Create;
  try
    C.Control := ABtn;
    C.Font.Assign(ABtn.Font);
    NeedW := C.TextWidth(Cap) + 20;
  finally
    C.Free;
  end;
  if NeedW < AMinW then
    NeedW := AMinW;
  Inc(NeedW, 8);
  if NeedW > 160 then
    NeedW := 160;
  ABtn.Width := NeedW;
  ABtn.Height := ASSISTANT_TOOL_BTN_H;
end;

procedure TFastFileAssistantCtrl.StyleQuestionToolBtn(ABtn: TsSpeedButton);
var
  UiFont: string;
begin
  if not Assigned(ABtn) then Exit;
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    UiFont := 'Segoe UI'
  else
    UiFont := 'Tahoma';
  ABtn.Flat := True;
  ABtn.ShowCaption := True;
  ABtn.ShowHint := True;
  ABtn.ParentShowHint := False;
  ABtn.Cursor := crHandPoint;
  ABtn.ParentFont := False;
  ABtn.Font.Name := UiFont;
  ABtn.Font.Size := 8;
  ABtn.Font.Style := [fsBold];
  ABtn.Spacing := 6;
  try
    ABtn.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
end;

procedure TFastFileAssistantCtrl.BuildTranslateLangMenu;
var
  Lang: TAppLanguage;
  It: TMenuItem;
begin
  if not Assigned(PopupTranslateLang) then
  begin
    PopupTranslateLang := TPopupMenu.Create(Self);
    PopupTranslateLang.AutoHotkeys := maManual;
  end;
  PopupTranslateLang.Items.Clear;
  for Lang := Low(TAppLanguage) to High(TAppLanguage) do
  begin
    It := TMenuItem.Create(PopupTranslateLang);
    It.Caption := AssistantLangMenuCaption(Lang);
    It.Tag := Ord(Lang);
    It.RadioItem := True;
    It.OnClick := TranslateLangClick;
    PopupTranslateLang.Items.Add(It);
  end;
end;

procedure TFastFileAssistantCtrl.UpdateQuestionToolButtons;
var
  CanUse, HasQ, HasR: Boolean;
begin
  HasQ := Assigned(MemoQuestion) and (Trim(MemoQuestion.Text) <> '');
  HasR := Assigned(MemoReply) and (Trim(MemoReply.Text) <> '');
  CanUse := (not FBusy) and HasQ;
  if Assigned(BtnTranslate) then
    BtnTranslate.Enabled := CanUse;
  if Assigned(BtnRewrite) then
    BtnRewrite.Enabled := CanUse;
  if Assigned(BtnAgentMode) then
    BtnAgentMode.Enabled := (not FBusy) and AgentBridgeAvailable;
  if Assigned(BtnClearReply) then
    BtnClearReply.Enabled := (not FBusy) and (HasQ or HasR);
  if Assigned(BtnCopyReply) then
    BtnCopyReply.Enabled := HasQ or HasR or (Trim(FLastReplyBody) <> '');
  if Assigned(BtnPython) then
    BtnPython.Enabled := not FBusy;
end;

function BuildAssistantTranslatePromptW(const AText, ALangName: string;
  AKeepLineCount: Boolean): WideString;
begin
  Result :=
    WideString('You translate text for FastFile.') + #13#10 +
    WideString('Reply with ONE JSON object only (no markdown):') + #13#10 +
    WideString('{"resposta":"<translated text>"}') + #13#10 +
    WideString('Translate USER_TEXT fully into TARGET_LANGUAGE.') + #13#10 +
    WideString('Every word must be in TARGET_LANGUAGE, including small words') + #13#10 +
    WideString('(conjunctions, articles, "the file", "and"). Do not leave mixed') + #13#10 +
    WideString('source-language tokens (e.g. Romanian si/fisierul/explicatiile).') + #13#10 +
    WideString('Keep file paths, numbers, codes, prefixes, regex, filenames and') + #13#10 +
    WideString('FastFile action meaning unchanged. Do not add quotes or explanations.') + #13#10;
  if AKeepLineCount then
    Result := Result +
      WideString('Keep the same number of lines as USER_TEXT (one output line per') + #13#10 +
      WideString('input line). Do not merge, drop or insert lines.') + #13#10;
  Result := Result +
    WideString('In JSON, encode any non-ASCII letter as \\uXXXX (UTF-16), not raw bytes.') + #13#10 +
    WideString('TARGET_LANGUAGE: ') + WideString(ALangName) + #13#10#13#10 +
    WideString('USER_TEXT:') + #13#10 + WideString(AText);
end;

function TFastFileAssistantCtrl.BuildTranslatePromptW(const AText, ALangName: string): WideString;
begin
  Result := BuildAssistantTranslatePromptW(AText, ALangName, False);
end;

function TFastFileAssistantCtrl.BuildRewritePromptW(const AText: string): WideString;
begin
  Result :=
    WideString('You help the user write a clearer FastFile AI Assistant question.') + #13#10 +
    WideString('The user may be unsure what they want or how to phrase it.') + #13#10 +
    WideString('Rewrite USER_DRAFT as one clear, complete request the assistant can run.') + #13#10 +
    WideString('Keep the user intent. Improve grammar and structure.') + #13#10 +
    WideString('Keep paths, numbers, codes, prefixes and filenames.') + #13#10 +
    WideString('If the draft is already clear, only polish it lightly.') + #13#10 +
    WideString('Reply with ONE JSON object only (no markdown):') + #13#10 +
    WideString('{"resposta":"<improved question only>"}') + #13#10#13#10 +
    WideString('USER_DRAFT:') + #13#10 + WideString(AText);
end;

procedure TFastFileAssistantCtrl.StartQuestionTextJob(AJob: Integer; const ALangName: string);
var
  Src: string;
  Th: TFastFileAssistantTextJobThread;
  PromptW: WideString;
begin
  if FBusy then Exit;
  if not Assigned(MemoQuestion) then Exit;
  FTextJobReplaceSel := MemoQuestion.SelLength > 0;
  if FTextJobReplaceSel then
    Src := MemoQuestion.SelText
  else
    Src := MemoQuestion.Text;
  Src := Trim(Src);
  if Src = '' then
  begin
    SetStatusCaption(TrText('Assistant.Error.EmptyQuestion'));
    Exit;
  end;
  if UserQuestionIsOutOfScopeOrHarmful(Src) then
  begin
    SetStatusCaption(TrText('Assistant.Error.OutOfScopeHarmful'));
    Exit;
  end;
  if AJob = ATJ_TRANSLATE then
    PromptW := BuildTranslatePromptW(Src, ALangName)
  else
    PromptW := BuildRewritePromptW(Src);
  FBusy := True;
  FAiCancelled := False;
  if Assigned(BtnSend) then
    BtnSend.Enabled := False;
  UpdateQuestionToolButtons;
  SetStatusCaption(TrText('Assistant.Thinking'));
  if AJob = ATJ_TRANSLATE then
    BeginAssistantWait(TrText('Assistant.Translating'))
  else
    BeginAssistantWait(TrText('Assistant.Rewriting'));
  Th := TFastFileAssistantTextJobThread.Create(Self, PromptW, AJob);
  Th.Resume;
end;

procedure TFastFileAssistantCtrl.ApplyTextJobFinished(AJob: Integer; AOk: Boolean;
  const AAns: WideString; const AErr: string);
var
  Body: string;
  W, Inner: WideString;
begin
  if FAiCancelled then
  begin
    FAiCancelled := False;
    EndAssistantWait;
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  EndAssistantWait;
  if not AOk then
  begin
    if Trim(AErr) <> '' then
      SetStatusCaption(ClampAssistantDisplayText(AErr))
    else
      SetStatusCaption(TrText('Assistant.Error.Network'));
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  W := UnescapeJsonUnicodeWide(AAns);
  Inner := Trim(W);
  if (Inner <> '') and (Inner[1] = '{') then
  begin
    Inner := ExtractJsonStringFieldWide(W, 'resposta');
    if Inner = '' then
      Inner := ExtractJsonStringFieldWide(W, 'user_message');
    if Inner <> '' then
      W := UnescapeJsonUnicodeWide(Inner);
  end;
  Body := ExtractComposeAnswerText(string(W));
  if Trim(Body) = '' then
  begin
    SetStatusCaption(TrText('Assistant.Error.Network'));
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  if Assigned(MemoQuestion) then
  begin
    if FTextJobReplaceSel and (MemoQuestion.SelLength > 0) then
      MemoQuestion.SelText := Body
    else
    begin
      MemoQuestion.Text := Body;
      MemoQuestion.SelStart := Length(MemoQuestion.Text);
      MemoQuestion.SelLength := 0;
    end;
    UpdateClearQuestionBtn;
    UpdateQuestionCharCount;
    SyncMemoAutoVertScroll(MemoQuestion);
    if MemoQuestion.CanFocus then
      MemoQuestion.SetFocus;
  end;
  if AJob = ATJ_TRANSLATE then
    SetStatusCaption(TrText('Assistant.Translated'))
  else
    SetStatusCaption(TrText('Assistant.Rewritten'));
  PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
end;

procedure TFastFileAssistantCtrl.BtnTranslateClick(Sender: TObject);
var
  P: TPoint;
begin
  if FBusy then Exit;
  if not Assigned(MemoQuestion) or (Trim(MemoQuestion.Text) = '') then
  begin
    SetStatusCaption(TrText('Assistant.Error.EmptyQuestion'));
    Exit;
  end;
  if not Assigned(PopupTranslateLang) then
    BuildTranslateLangMenu;
  if not Assigned(BtnTranslate) then Exit;
  P := BtnTranslate.ClientToScreen(Point(0, BtnTranslate.Height));
  FPopupMenuOpen := True;
  try
    PopupTranslateLang.Popup(P.X, P.Y);
  finally
    FPopupMenuOpen := False;
  end;
end;

procedure TFastFileAssistantCtrl.TranslateLangClick(Sender: TObject);
var
  Lang: TAppLanguage;
begin
  if not (Sender is TMenuItem) then Exit;
  Lang := TAppLanguage(TMenuItem(Sender).Tag);
  TMenuItem(Sender).Checked := True;
  StartQuestionTextJob(ATJ_TRANSLATE, AssistantLangPromptName(Lang));
end;

procedure TFastFileAssistantCtrl.BtnRewriteClick(Sender: TObject);
begin
  if FBusy then Exit;
  if not Assigned(MemoQuestion) or (Trim(MemoQuestion.Text) = '') then
  begin
    SetStatusCaption(TrText('Assistant.Error.EmptyQuestion'));
    Exit;
  end;
  StartQuestionTextJob(ATJ_REWRITE, '');
end;

procedure TFastFileAssistantCtrl.LocalizeAgentModeBtn;
begin
  if not Assigned(BtnAgentMode) then Exit;
  BtnAgentMode.Caption := TrText('Assistant.AgentMode');
  BtnAgentMode.Hint := TrText('Assistant.AgentModeHint');
  BtnAgentMode.ShowHint := True;
  SizeQuestionToolBtn(BtnAgentMode, ASSISTANT_AGENT_BTN_W);
end;

procedure TFastFileAssistantCtrl.BtnAgentModeClick(Sender: TObject);
begin
  if not Assigned(BtnAgentMode) then Exit;
  if BtnAgentMode.Down then
    SetStatusCaption(TrText('Assistant.AgentModeOn'))
  else
    SetStatusCaption(TrText('Assistant.AgentModeOff'));
  RequestInputFocus;
end;

function TFastFileAssistantCtrl.StartAgentTask(const AUserQ: string): Boolean;
var
  Path, Why: string;
begin
  Result := False;
  if FAgentRunning or not AgentBridgeAvailable then Exit;
  Path := Trim(AssistantHostGetOpenFilePath);
  if (Path = '') or not FileExists(Path) then
  begin
    FLastReplyBody := TrText('Assistant.Error.NoFileOpen');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  HideOfferNext;
  FBusy := True;
  FAgentRunning := True;
  FHasPlan := False;
  FMsLastAi := 0;
  FMsLastExec := 0;
  FTickAiStart := GetTickCount;
  BtnExecute.Enabled := False;
  BtnSend.Enabled := False;
  UpdateQuestionToolButtons;
  FLastReplyBody := Format(TrText('Assistant.Agent.Running'), [ExtractFileName(Path)]);
  MemoReply.Lines.Text := FLastReplyBody;
  SetStatusCaption(FLastReplyBody);
  AssistantWriteLog('agent_task start path=' + Path);
  if not AgentBridgeRun(AUserQ, Path, Why) then
  begin
    FAgentRunning := False;
    if Trim(Why) = '' then
      Why := TrText('Assistant.Agent.CannotStart');
    FLastReplyBody := Why;
    MemoReply.Lines.Text := Why;
    SetStatusCaption(Why);
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  Result := True;
end;

procedure TFastFileAssistantCtrl.ShowAgentProposals(ACount: Integer);
begin
  ShowOfferNext(Format(TrText('Assistant.Agent.Proposed'), [ACount]),
    AGENT_CHIP_ACCEPT + ',' + AGENT_CHIP_REVIEW + ',' + AGENT_CHIP_REJECT, '');
end;

procedure TFastFileAssistantCtrl.AgentBridgeEvent(AEvent: TAgentBridgeEvent; const AText, AExtra: string;
  ACount: Integer);
var
  Body: string;
  OfferIsAgent: Boolean;
begin
  if (Handle = 0) or (csDestroying in ComponentState) then Exit;
  OfferIsAgent := Assigned(PnlOfferNext) and PnlOfferNext.Visible and Assigned(FOfferActionIds) and
    (FOfferActionIds.IndexOf(AGENT_CHIP_ACCEPT) >= 0);
  case AEvent of
    abeStatus:
      if FAgentRunning and (Trim(AText) <> '') then
        SetStatusCaption(AText);
    abeDone:
      begin
        FAgentRunning := False;
        FMsLastAi := GetTickCount - FTickAiStart;
        Body := Trim(AText);
        if Trim(AExtra) <> '' then
        begin
          if Body = '' then
            Body := Trim(AExtra)
          else if Pos(Trim(AExtra), Body) = 0 then
            Body := Body + #13#10#13#10 + Trim(AExtra);
        end;
        if Body = '' then
          Body := TrText('Assistant.Agent.NoChanges');
        FLastReplyBody := ClampAssistantDisplayText(Body);
        MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
        PipelineRememberAssistant(FLastReplyBody);
        AssistantWriteLog('agent_task done edits=' + IntToStr(ACount) + ' ms=' + IntToStr(FMsLastAi));
        FBusy := False;
        if Assigned(BtnSend) then BtnSend.Enabled := True;
        UpdateQuestionToolButtons;
        if ACount > 0 then
          ShowAgentProposals(ACount)
        else if Trim(AExtra) <> '' then
          SetStatusCaption(Trim(AExtra))
        else
          SetStatusCaption(TrText('Assistant.ReplyReady'));
      end;
    abeEditsChanged:
      if FAgentRunning then
        Exit
      else if ACount > 0 then
      begin
        if OfferIsAgent then
          ShowAgentProposals(ACount);
      end
      else if OfferIsAgent then
        HideOfferNext;
    abeApplied:
      begin
        if Trim(AText) <> '' then
        begin
          if Pos(Trim(AText), FLastReplyBody) = 0 then
            FLastReplyBody := ClampAssistantDisplayText(FLastReplyBody + #13#10#13#10 + Trim(AText));
          MemoReply.Lines.Text := FLastReplyBody;
        end;
        if ACount > 0 then
          ShowAgentProposals(ACount)
        else
        begin
          if OfferIsAgent then
            HideOfferNext;
          if Trim(AText) <> '' then
            SetStatusCaption(Trim(AText));
        end;
      end;
  end;
end;

procedure TFastFileAssistantCtrl.BtnClearReplyClick(Sender: TObject);
begin
  { Only the Assistente IA memos — never ConsumerRAG / ConsumerAI transcript. }
  if Assigned(MemoReply) then
    MemoReply.Clear;
  if Assigned(MemoQuestion) then
    MemoQuestion.Clear;
  UpdateClearQuestionBtn;
  UpdateQuestionCharCount;
  FLastReplyBody := '';
  FHasPlan := False;
  FLastPlan := Default(TAssistantPlan);
  HideGeneratedFileNotice;
  if Assigned(BtnExecute) then
    BtnExecute.Enabled := False;
  if Assigned(LblStatus) then
    SetStatusCaption(TrText('Assistant.Status.ReplyCleared'));
  if Assigned(MemoQuestion) and MemoQuestion.CanFocus then
    MemoQuestion.SetFocus;
end;

procedure TFastFileAssistantCtrl.BtnPythonClick(Sender: TObject);
begin
  if FBusy then
    Exit;
  if Assigned(FOnPythonClick) then
    FOnPythonClick(Self);
end;

procedure TFastFileAssistantCtrl.BtnCopyReplyClick(Sender: TObject);
var
  M: TMemo;
  T: string;
begin
  { Copy from assistant memos only — never ListView / RAG. Button click steals focus,
    so use last focused memo (question or reply), same rules as Ctrl+C. }
  M := AssistantFocusedMemo;
  if not Assigned(M) then
    M := FLastAssistantMemo;
  if CopyAssistantMemoToClipboard(M) then
  begin
    SetStatusCaption(TrText('Assistant.Status.CopiedToClipboard'));
    Exit;
  end;
  T := '';
  if Assigned(MemoReply) then
    T := MemoReply.Text;
  if Trim(T) = '' then
    T := FLastReplyBody;
  if SameText(Trim(T), TrText('Assistant.ReplyPlaceholder')) then
    T := '';
  if Trim(T) = '' then
  begin
    SetStatusCaption(TrText('Assistant.Status.NothingToCopy'));
    Exit;
  end;
  Clipboard.AsText := T;
  SetStatusCaption(TrText('Assistant.Status.CopiedToClipboard'));
end;

procedure TFastFileAssistantCtrl.BtnComposeFormatsClick(Sender: TObject);
begin
  ShowComposeFormatsDialog('');
end;

function TFastFileAssistantCtrl.RejectUnsupportedComposeFormat(const AQuestion: string): Boolean;
var
  Ext: string;
begin
  Result := False;
  if not TryRequestedComposeFormat(AQuestion, Ext) then Exit;
  if IsComposeDestExtension(Ext, True) then Exit;
  ShowComposeFormatsDialog(Ext);
  AbortComposeWrite(Format(TrText('Assistant.Error.ComposeFormatUnsupported'), [Ext]));
  Result := True;
end;

procedure TFastFileAssistantCtrl.ShowComposeFormatsDialog(const AUnsupportedExt: string);
var
  F: TForm;
  Memo: TMemo;
  Btn: TButton;
  Body, Ext: string;
begin
  Body := '';
  Ext := Trim(AUnsupportedExt);
  if Ext <> '' then
  begin
    if Ext[1] <> '.' then
      Ext := '.' + Ext;
    Body := Format(TrText('Assistant.Error.ComposeFormatUnsupported'), [Ext]) +
      #13#10#13#10;
  end;
  Body := Body + TrText('Assistant.ComposeFormats.Intro') + #13#10#13#10 +
    TrText('Assistant.ComposeFormats.Docs') + #13#10 +
    '  .pdf   .docx   .odt   .rtf' + #13#10#13#10 +
    TrText('Assistant.ComposeFormats.Text') + #13#10 +
    '  .txt   .md   .html   .json   .sql' + #13#10#13#10 +
    TrText('Assistant.ComposeFormats.Code') + #13#10 +
    '  .pas  .dpr  .pp  .inc  .py  .js  .ts  .tsx  .jsx' + #13#10 +
    '  .go   .java .cpp .cc   .c   .cs  .rs  .php' + #13#10 +
    '  .rb   .kt   .swift';
  F := TForm.Create(GetParentForm(Self));
  try
    F.BorderStyle := bsDialog;
    F.Caption := TrText('Assistant.ComposeFormats.Title');
    F.Position := poOwnerFormCenter;
    F.ClientWidth := 420;
    F.ClientHeight := 360;
    F.Font.Name := 'Segoe UI';
    F.Font.Size := 9;
    Memo := TMemo.Create(F);
    Memo.Parent := F;
    Memo.SetBounds(12, 12, F.ClientWidth - 24, F.ClientHeight - 56);
    Memo.ReadOnly := True;
    Memo.WantReturns := True;
    Memo.ScrollBars := ssVertical;
    Memo.WordWrap := True;
    Memo.Text := Body;
    Memo.SelStart := 0;
    Btn := TButton.Create(F);
    Btn.Parent := F;
    Btn.Caption := TrText('OK');
    Btn.Default := True;
    Btn.ModalResult := mrOk;
    Btn.SetBounds(F.ClientWidth - 100, F.ClientHeight - 36, 88, 26);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TFastFileAssistantCtrl.WMResetBusy(var Msg: TMessage);
begin
  FBusy := False;
  if Assigned(BtnSend) then BtnSend.Enabled := True;
  if Assigned(BtnHide) then BtnHide.Enabled := True;
  UpdateQuestionToolButtons;
end;

procedure TFastFileAssistantCtrl.WMDeferFocus(var Msg: TMessage);
begin
  if not Visible then Exit;
  if Assigned(FHostPanel) and (not FHostPanel.Visible) then Exit;
  if not Assigned(MemoQuestion) then Exit;
  if not MemoQuestion.Enabled or not MemoQuestion.Visible then Exit;
  if MemoQuestion.CanFocus then
    try
      MemoQuestion.SetFocus;
    except
    end;
end;

procedure TFastFileAssistantCtrl.RequestInputFocus;
begin
  if Handle <> 0 then
    PostMessage(Handle, WM_FF_ASSISTANT_DEFER_FOCUS, 0, 0);
end;

function NormalizeComposeExtToken(const S: string): string;
begin
  Result := LowerCase(Trim(S));
  if Result = '' then Exit;
  if Result[1] <> '.' then
    Result := '.' + Result;
end;

function IsComposeExtWordChar(C: Char): Boolean;
begin
  Result := CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

function MapComposeFormatWord(const ATok: string): string;
var
  T: string;
begin
  { Format ids only (supported + common unsupported). Not NL verbs. }
  T := LowerCase(Trim(ATok));
  if (T = '') or (T[1] = '.') then
    T := Copy(T, 2, MaxInt);
  Result := '';
  if T = '' then Exit;
  if (T = 'txt') or (T = 'text') then Result := '.txt'
  else if T = 'pdf' then Result := '.pdf'
  else if T = 'docx' then Result := '.docx'
  else if T = 'odt' then Result := '.odt'
  else if (T = 'rtf') or (T = 'word') or (T = 'doc') then Result := '.rtf'
  else if (T = 'md') or (T = 'markdown') or (T = 'readme') then Result := '.md'
  else if T = 'html' then Result := '.html'
  else if T = 'json' then Result := '.json'
  else if T = 'sql' then Result := '.sql'
  else if (T = 'pas') or (T = 'pascal') or (T = 'delphi') then Result := '.pas'
  else if T = 'dpr' then Result := '.dpr'
  else if (T = 'pp') or (T = 'inc') then Result := '.inc'
  else if (T = 'py') or (T = 'python') then Result := '.py'
  else if (T = 'js') or (T = 'javascript') then Result := '.js'
  else if (T = 'ts') or (T = 'typescript') then Result := '.ts'
  else if T = 'tsx' then Result := '.tsx'
  else if T = 'jsx' then Result := '.jsx'
  else if (T = 'go') or (T = 'golang') then Result := '.go'
  else if T = 'java' then Result := '.java'
  else if (T = 'cpp') or (T = 'c++') or (T = 'cc') or (T = 'c') then Result := '.cpp'
  else if (T = 'cs') or (T = 'csharp') or (T = 'c#') then Result := '.cs'
  else if (T = 'rs') or (T = 'rust') then Result := '.rs'
  else if T = 'php' then Result := '.php'
  else if (T = 'rb') or (T = 'ruby') then Result := '.rb'
  else if (T = 'kt') or (T = 'kotlin') then Result := '.kt'
  else if T = 'swift' then Result := '.swift'
  else if (T = 'xlsx') or (T = 'xls') or (T = 'xlsm') or (T = 'xlsb') or
          (T = 'excel') then Result := '.xlsx'
  else if T = 'csv' then Result := '.csv'
  else if T = 'xml' then Result := '.xml'
  else if (T = 'yaml') or (T = 'yml') then Result := '.yaml'
  else if (T = 'zip') or (T = 'rar') or (T = '7z') then Result := '.' + T
  else if (T = 'pptx') or (T = 'ppt') or (T = 'ppsx') or (T = 'powerpoint') then
    Result := '.pptx'
  else if (T = 'ods') or (T = 'odp') then Result := '.' + T
  else if (T = 'png') or (T = 'jpg') or (T = 'jpeg') or (T = 'gif') or
          (T = 'bmp') or (T = 'svg') or (T = 'webp') or (T = 'tiff') then
    Result := '.' + T
  else if (T = 'mp3') or (T = 'mp4') or (T = 'wav') or (T = 'avi') then
    Result := '.' + T
  else if (T = 'exe') or (T = 'dll') or (T = 'bat') or (T = 'cmd') then
    Result := '.' + T
  else if T = 'parquet' then Result := '.parquet'
  else if T = 'epub' then Result := '.epub';
end;

function TryRequestedComposeFormat(const AQuestion: string; out AExt: string): Boolean;
var
  L, Tok, Mapped: string;
  i, j, p, StartAt: Integer;
  Markers: array[0..7] of string;

  procedure SkipSpaces(var Idx: Integer);
  begin
    while (Idx <= Length(L)) and (L[Idx] <= ' ') do
      Inc(Idx);
  end;

  function ReadToken(var Idx: Integer): string;
  var
    A: Integer;
  begin
    Result := '';
    SkipSpaces(Idx);
    if (Idx <= Length(L)) and (L[Idx] = '.') then
      Inc(Idx);
    A := Idx;
    while (Idx <= Length(L)) and IsComposeExtWordChar(L[Idx]) do
      Inc(Idx);
    Result := Copy(L, A, Idx - A);
  end;

  function SkipFiller(var Idx: Integer): Boolean;
  var
    W: string;
    Save: Integer;
  begin
    Result := False;
    Save := Idx;
    W := LowerCase(ReadToken(Idx));
    if (W = 'um') or (W = 'uma') or (W = 'un') or (W = 'una') or (W = 'uno') or
       (W = 'a') or (W = 'an') or (W = 'the') or (W = 'arquivo') or
       (W = 'ficheiro') or (W = 'file') or (W = 'documento') or
       (W = 'document') or (W = 'fichero') or (W = 'tipo') or (W = 'type') then
      Result := True
    else
      Idx := Save;
  end;

  procedure ConsiderToken(const ATok: string);
  var
    E: string;
  begin
    E := MapComposeFormatWord(ATok);
    if E = '' then Exit;
    AExt := E;
    Result := True;
  end;

  function HasLooseFormatToken(const Tok: string): Boolean;
  var
    At, NextFrom: Integer;
  begin
    Result := False;
    At := PosBMH(Tok, L);
    while At > 0 do
    begin
      if ((At = 1) or not IsComposeExtWordChar(L[At - 1])) and
         ((At + Length(Tok) - 1 = Length(L)) or
          not IsComposeExtWordChar(L[At + Length(Tok)])) then
      begin
        if not ((At > 2) and (L[At - 1] = '.') and
                IsComposeExtWordChar(L[At - 2])) then
        begin
          Result := True;
          Exit;
        end;
      end;
      NextFrom := At + Length(Tok);
      if NextFrom > Length(L) then Break;
      At := PosBMH(Tok, Copy(L, NextFrom, MaxInt));
      if At > 0 then
        Inc(At, NextFrom - 1);
    end;
  end;

begin
  Result := False;
  AExt := '';
  L := LowerCase(FoldDiacriticsForMatch(Trim(AQuestion)));
  if L = '' then Exit;

  { Standalone ".xlsx" (space/punct before the dot) — not filename.csv }
  i := 1;
  while i <= Length(L) do
  begin
    if (L[i] = '.') and (i < Length(L)) and CharInSet(L[i + 1], ['a'..'z', '0'..'9']) and
       ((i = 1) or (not IsComposeExtWordChar(L[i - 1]))) then
    begin
      j := i + 1;
      while (j <= Length(L)) and CharInSet(L[j], ['a'..'z', '0'..'9']) do
        Inc(j);
      Tok := Copy(L, i, j - i);
      if (Length(Tok) >= 3) and (Length(Tok) <= 9) then
      begin
        Mapped := MapComposeFormatWord(Tok);
        if Mapped <> '' then
          AExt := Mapped
        else
          AExt := Tok;
        Result := True;
      end;
      i := j;
    end
    else
      Inc(i);
  end;

  Markers[0] := ' em ';
  Markers[1] := ' en ';
  Markers[2] := ' in ';
  Markers[3] := ' as ';
  Markers[4] := 'formato ';
  Markers[5] := 'format ';
  Markers[6] := 'extensao ';
  Markers[7] := 'extension ';
  for i := 0 to High(Markers) do
  begin
    StartAt := 1;
    repeat
      p := PosBMH(Markers[i], Copy(L, StartAt, MaxInt));
      if p = 0 then Break;
      p := p + StartAt - 1 + Length(Markers[i]);
      while SkipFiller(p) do
        SkipSpaces(p);
      Tok := ReadToken(p);
      if Tok <> '' then
        ConsiderToken(Tok);
      StartAt := p;
      if StartAt <= 1 then
        Inc(StartAt);
    until False;
  end;

  if AExt = '' then
  begin
    if HasLooseFormatToken('xlsx') or HasLooseFormatToken('xls') or
       HasLooseFormatToken('excel') then
      ConsiderToken('xlsx')
    else if HasLooseFormatToken('csv') then
      ConsiderToken('csv')
    else if HasLooseFormatToken('pptx') then
      ConsiderToken('pptx')
    else if HasLooseFormatToken('xml') then
      ConsiderToken('xml')
    else if HasLooseFormatToken('zip') then
      ConsiderToken('zip')
    else if HasLooseFormatToken('parquet') then
      ConsiderToken('parquet')
    else if HasLooseFormatToken('epub') then
      ConsiderToken('epub');
  end;
end;

function GuessComposeExtension(const AQuestion: string): string;
var
  L: string;
  BestPos: Integer;

  procedure Consider(const Needle, Ext: string);
  var
    p: Integer;
  begin
    p := PosBMH(Needle, L);
    if (p > 0) and (p < BestPos) then
    begin
      BestPos := p;
      Result := Ext;
    end;
  end;

begin
  L := LowerCase(AQuestion);
  BestPos := MaxInt;
  Result := '';
  { Format ids / extensions — language-agnostic (AI-first; not NL verb lists). }
  if ContainsTokenAsWord(L, 'pdf') or (Pos('.pdf', L) > 0) then
  begin
    Result := '.pdf';
    Exit;
  end;
  if ContainsTokenAsWord(L, 'docx') or (Pos('.docx', L) > 0) then
  begin
    Result := '.docx';
    Exit;
  end;
  if ContainsTokenAsWord(L, 'odt') or (Pos('.odt', L) > 0) then
  begin
    Result := '.odt';
    Exit;
  end;
  if ContainsTokenAsWord(L, 'rtf') or (Pos('.rtf', L) > 0) then
  begin
    Result := '.rtf';
    Exit;
  end;
  { Rich docs: earliest mention wins ("word e odt" → .rtf). }
  Consider('.pdf', '.pdf');
  Consider('formato pdf', '.pdf');
  Consider('formatos pdf', '.pdf');
  Consider('em pdf', '.pdf');
  Consider('arquivo pdf', '.pdf');
  Consider('documento pdf', '.pdf');
  Consider('gerando um pdf', '.pdf');
  Consider('gerar um pdf', '.pdf');
  Consider('gerar pdf', '.pdf');
  Consider('gere um pdf', '.pdf');
  Consider('um pdf', '.pdf');
  Consider('un pdf', '.pdf');
  Consider('genera un pdf', '.pdf');
  Consider('crear un pdf', '.pdf');
  Consider('to pdf', '.pdf');
  Consider('as pdf', '.pdf');
  Consider('e pdf', '.pdf');
  Consider('y pdf', '.pdf');
  Consider('.odt', '.odt');
  Consider('formato odt', '.odt');
  Consider('formatos odt', '.odt');
  Consider('em odt', '.odt');
  Consider('e odt', '.odt');
  Consider('openoffice', '.odt');
  Consider('libreoffice', '.odt');
  Consider('.docx', '.docx');
  Consider('em docx', '.docx');
  Consider('e docx', '.docx');
  Consider('arquivo docx', '.docx');
  Consider('.rtf', '.rtf');
  Consider('formato word', '.rtf');
  Consider('formatos word', '.rtf');
  Consider('microsoft word', '.rtf');
  Consider('em word', '.rtf');
  Consider('e word', '.rtf');
  Consider('documento word', '.rtf');
  Consider('word pra mim', '.rtf');
  Consider('word para mim', '.rtf');
  if (Result = '') and UserWantsComposeAsSavedDocument(AQuestion) then
    Consider('word', '.rtf');
  if Result <> '' then
    Exit;

  if (PosBMH('.tsx', L) > 0) or (PosBMH('react', L) > 0) then
    Result := '.tsx'
  else if (PosBMH('.jsx', L) > 0) then
    Result := '.jsx'
  else if (PosBMH('.ts', L) > 0) or (PosBMH('typescript', L) > 0) or
     (PosBMH('angular', L) > 0) then
    Result := '.ts'
  else if (PosBMH('.js', L) > 0) or (PosBMH('javascript', L) > 0) then
    Result := '.js'
  else if (PosBMH('.go', L) > 0) or (PosBMH('golang', L) > 0) or
     (PosBMH('em go', L) > 0) then
    Result := '.go'
  else if (PosBMH('.java', L) > 0) or (PosBMH('java', L) > 0) then
    Result := '.java'
  else if (PosBMH('.cpp', L) > 0) or (PosBMH('c++', L) > 0) or
     (PosBMH('cplusplus', L) > 0) then
    Result := '.cpp'
  else if (PosBMH('.cs', L) > 0) or (PosBMH('csharp', L) > 0) or
     (PosBMH('c#', L) > 0) then
    Result := '.cs'
  else if (PosBMH('.rs', L) > 0) or (PosBMH('rust', L) > 0) then
    Result := '.rs'
  else if (PosBMH('.php', L) > 0) or (PosBMH('php', L) > 0) then
    Result := '.php'
  else if (PosBMH('.rb', L) > 0) or (PosBMH('ruby', L) > 0) then
    Result := '.rb'
  else if (PosBMH('.kt', L) > 0) or (PosBMH('kotlin', L) > 0) then
    Result := '.kt'
  else if (PosBMH('.swift', L) > 0) or (PosBMH('swift', L) > 0) then
    Result := '.swift'
  else if (PosBMH('.md', L) > 0) or (PosBMH('markdown', L) > 0) or
     (PosBMH('readme', L) > 0) then
    Result := '.md'
  else if (PosBMH('.pas', L) > 0) or (PosBMH('pascal', L) > 0) or
     (PosBMH('delphi', L) > 0) then
    Result := '.pas'
  else if (PosBMH('.dpr', L) > 0) then
    Result := '.dpr'
  else if (PosBMH('.pp', L) > 0) or (PosBMH('.inc', L) > 0) then
    Result := '.inc'
  else if (PosBMH('.py', L) > 0) or (PosBMH('python', L) > 0) then
    Result := '.py'
  else if (PosBMH('.json', L) > 0) then
    Result := '.json'
  else if (PosBMH('.html', L) > 0) then
    Result := '.html'
  else if (PosBMH('.sql', L) > 0) then
    Result := '.sql'
  else if ContainsTokenAsWord(L, 'txt') or (PosBMH('.txt', L) > 0) then
    Result := '.txt'
  else
    Result := '.md';
end;

function ListRequestedRichComposeExts(const AQuestion: string): TArray<string>;
var
  L: string;

  procedure AddExt(const Ext: string);
  var
    i: Integer;
  begin
    for i := 0 to High(Result) do
      if SameText(Result[i], Ext) then
        Exit;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Ext;
  end;

begin
  SetLength(Result, 0);
  L := LowerCase(AQuestion);
  if (PosBMH('word', L) > 0) or (PosBMH('.rtf', L) > 0) or
     (PosBMH('microsoft word', L) > 0) then
    AddExt('.rtf');
  if (PosBMH('odt', L) > 0) or (PosBMH('openoffice', L) > 0) or
     (PosBMH('libreoffice', L) > 0) then
    AddExt('.odt');
  if (PosBMH('pdf', L) > 0) then
    AddExt('.pdf');
  if (PosBMH('docx', L) > 0) then
    AddExt('.docx');
end;

function UserAskedComposeSaveAs(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result := (PosBMH('salve em', L) > 0) or (PosBMH('salvar em', L) > 0) or
    (PosBMH('salva em', L) > 0) or (PosBMH('save as', L) > 0) or
    (PosBMH('save to', L) > 0) or (PosBMH('save in', L) > 0);
end;

function UserAskedComposeTempFolder(const AQuestion: string): Boolean;
var
  L: string;
begin
  L := LowerCase(AQuestion);
  Result := (PosBMH('pasta temp', L) > 0) or (PosBMH('temp folder', L) > 0) or
    (PosBMH('fastfile_temp', L) > 0) or (PosBMH('fastfile_assistant', L) > 0) or
    (PosBMH('na temp', L) > 0);
end;

function IsComposeDestExtension(const AExt: string; AAllowTxt: Boolean): Boolean;
var
  E: string;
begin
  E := LowerCase(AExt);
  Result := (E = '.md') or (E = '.pas') or (E = '.pp') or (E = '.dpr') or
    (E = '.inc') or (E = '.py') or (E = '.json') or (E = '.html') or (E = '.sql') or
    (E = '.rtf') or (E = '.docx') or (E = '.odt') or (E = '.pdf') or
    (E = '.js') or (E = '.ts') or (E = '.tsx') or (E = '.jsx') or
    (E = '.go') or (E = '.java') or (E = '.cpp') or (E = '.cc') or (E = '.c') or
    (E = '.cs') or (E = '.rs') or (E = '.php') or (E = '.rb') or (E = '.kt') or
    (E = '.swift');
  if Result and IsForbiddenComposeExtension(E) then
    Result := False;
  if (not Result) and AAllowTxt and (E = '.txt') then
    Result := True;
end;

function PathIsInsideFastFileTemp(const APath: string): Boolean;
var
  T, P: string;
begin
  Result := False;
  if Trim(APath) = '' then Exit;
  T := LowerCase(IncludeTrailingPathDelimiter(ExpandFileName(FastFileTempDir)));
  P := LowerCase(ExpandFileName(APath));
  Result := (Length(P) >= Length(T)) and (Copy(P, 1, Length(T)) = T);
end;

function PathIsInsideAssistantOutDir(const APath: string): Boolean;
var
  T, P: string;
begin
  Result := False;
  if Trim(APath) = '' then Exit;
  T := LowerCase(IncludeTrailingPathDelimiter(ExpandFileName(FastFileAssistantOutDir)));
  P := LowerCase(ExpandFileName(APath));
  Result := (Length(P) >= Length(T)) and (Copy(P, 1, Length(T)) = T);
end;

function PathIsInsideComposeDefaultOut(const APath: string): Boolean;
begin
  { Default compose folder is fastfile_assistant. Legacy files under fastfile_temp
    still count as in-app output (no "outside" confirm when fixing). }
  Result := PathIsInsideAssistantOutDir(APath) or PathIsInsideFastFileTemp(APath);
end;

function GuessComposeOutputPath(const AQuestion: string): string;
var
  Path, Ext, DestExt: string;
begin
  DestExt := GuessComposeExtension(AQuestion);
  if DestExt = '' then
    DestExt := '.md';
  if IsForbiddenComposeExtension(DestExt) then
    DestExt := '.md';
  Path := ExtractPathFromUserText(AQuestion);
  Ext := ExtractFileExt(Path);
  { Only honor an explicit path when the user asked "save as/to …". Never treat
    an AI-invented path (e.g. C:\Hamden\prefix_counts.pdf) as the destination. }
  if UserAskedComposeSaveAs(AQuestion) and (Path <> '') and
     IsComposeDestExtension(Ext, True) and
     (not UserAskedComposeTempFolder(AQuestion)) then
  begin
    Result := Path;
    Exit;
  end;
  Result := FastFileAssistantOutPath('compose_' + FormatDateTime('yyyymmdd_hhnnss', Now) + DestExt);
end;

function ReadComposeSourceSample(const APath: string): string;
var
  FS: TFileStream;
  Bytes: TBytes;
  Sz: Int64;
  n, i, Lines, LastLf: Integer;
  S: string;
  Truncated: Boolean;
begin
  Result := '';
  if not FileExists(APath) then Exit;
  try
    FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      { FS.Size is Int64 — never assign directly to Integer under $R+ (ERangeError on GB+ files). }
      Sz := FS.Size;
      if Sz <= 0 then
        n := 0
      else if Sz > COMPOSE_SAMPLE_MAX_BYTES then
        n := COMPOSE_SAMPLE_MAX_BYTES
      else
        n := Integer(Sz);
      SetLength(Bytes, n);
      if n > 0 then
        FS.ReadBuffer(Pointer(Bytes)^, n);
      Truncated := Sz > n;
    finally
      FS.Free;
    end;
    S := TEncoding.UTF8.GetString(Bytes);
    Lines := 0;
    LastLf := 0;
    for i := 1 to Length(S) do
      if S[i] = #10 then
      begin
        Inc(Lines);
        LastLf := i;
        if Lines >= COMPOSE_SAMPLE_MAX_LINES then
        begin
          Result := Copy(S, 1, i) + #13#10 + '[... sample truncated ...]';
          Exit;
        end;
      end;
    { Byte cap often lands mid-line on fixed-width GB files — snap to last LF. }
    if Truncated and (LastLf > 0) and (LastLf < Length(S)) then
      Result := Copy(S, 1, LastLf) + #13#10 + '[... sample truncated ...]'
    else if Truncated then
      Result := S + #13#10 + '[... sample truncated ...]'
    else
      Result := S;
  except
    Result := '';
  end;
end;

function StripComposeBody(const S: string): string;
var
  T: string;
  p: Integer;
begin
  T := Trim(S);
  if Copy(T, 1, 3) = '```' then
  begin
    Delete(T, 1, 3);
    p := 1;
    while (p <= Length(T)) and not (T[p] in [#13, #10]) do
      Inc(p);
    if p <= Length(T) then
      Delete(T, 1, p);
    T := Trim(T);
    p := PosBMH('```', T);
    if p > 0 then
      T := Trim(Copy(T, 1, p - 1));
  end;
  Result := T;
end;

function ReadComposeDocument(const APath: string; out AText, AErr: string): Boolean;
begin
  Result := False;
  AText := '';
  AErr := '';
  if not FileExists(APath) then
  begin
    AErr := TrText('Assistant.Error.ComposeNothingToFix');
    Exit;
  end;
  if SameText(ExtractFileExt(APath), '.pdf') then
  begin
    AErr := TrText('Assistant.Error.ComposeNothingToFix');
    Exit;
  end;
  if TryExtractComposePlainText(APath, AText) then
  begin
    Result := True;
    Exit;
  end;
  AErr := TrText('Assistant.Error.ComposeNothingToFix');
end;

function ResolveComposeFixPath(const AQuestion, ALastPath: string): string;
var
  Path, Ext: string;
begin
  Result := '';
  Path := ExtractPathFromUserText(AQuestion);
  Ext := ExtractFileExt(Path);
  if (Path <> '') and IsComposeDestExtension(Ext, True) and FileExists(Path) then
  begin
    Result := Path;
    Exit;
  end;
  if (ALastPath <> '') and FileExists(ALastPath) then
    Result := ALastPath;
end;

function WriteComposeDocument(const APath, ABody: string; out AErr: string): Boolean;
var
  Dir: string;
  Bytes: TBytes;
  FS: TFileStream;
  n: Integer;
  Ext: string;
begin
  Result := False;
  AErr := '';
  Dir := ExtractFilePath(APath);
  if (Dir <> '') and (not DirectoryExists(Dir)) then
  begin
    if not ForceDirectories(Dir) then
    begin
      AErr := TrText('Assistant.Error.ComposeWriteFailed') + ' ' + Dir;
      Exit;
    end;
  end;
  Ext := ExtractFileExt(APath);
  if IsForbiddenComposeExtension(Ext) then
  begin
    AErr := TrText('Assistant.Error.OutOfScopeHarmful');
    Exit;
  end;
  try
    Bytes := EncodeComposePayload(Ext, ABody);
  except
    on E: EPdfUnsupportedUnicode do
    begin
      AErr := TrText('Assistant.Error.PdfUnicodeUnsupported');
      Exit;
    end;
    on E: Exception do
    begin
      AErr := TrText('Assistant.Error.ComposeWriteFailed') + ' ' + E.Message;
      Exit;
    end;
  end;
  n := Length(Bytes);
  if (n > COMPOSE_MAX_BYTES) and (not IsRichComposeExtension(Ext)) then
    SetLength(Bytes, COMPOSE_MAX_BYTES);
  try
    FS := TFileStream.Create(APath, fmCreate);
    try
      if Length(Bytes) > 0 then
        FS.WriteBuffer(Pointer(Bytes)^, Length(Bytes));
    finally
      FS.Free;
    end;
    Result := True;
  except
    on E: Exception do
      AErr := TrText('Assistant.Error.ComposeWriteFailed') + ' ' + E.Message;
  end;
end;

procedure AppendSiblingComposeWrites(const APrimaryPath, ABody, AQuestion: string;
  var ASavedMsg: string);
var
  Exts: TArray<string>;
  PrimExt, Alt, Err: string;
  i: Integer;
begin
  PrimExt := LowerCase(ExtractFileExt(APrimaryPath));
  Exts := ListRequestedRichComposeExts(AQuestion);
  for i := 0 to High(Exts) do
  begin
    if SameText(Exts[i], PrimExt) then
      Continue;
    Alt := ChangeFileExt(APrimaryPath, Exts[i]);
    if WriteComposeDocument(Alt, ABody, Err) then
    begin
      ASavedMsg := ASavedMsg + #13#10 +
        Format(TrText('Assistant.Status.ComposeSavedDetail'), [Alt]);
      AssistantHostNotifyGeneratedFile(Alt);
      AssistantWriteLog('compose-sibling: ' + Alt);
    end;
  end;
end;

function TFastFileAssistantCtrl.ReplyStylePresetBody(const AId: string): string;
var
  U: string;
begin
  U := LowerCase(Trim(AId));
  if U = 'concise' then
    Result := TrText('Assistant.ReplyStyle.Body.Concise')
  else if U = 'bullets' then
    Result := TrText('Assistant.ReplyStyle.Body.Bullets')
  else if U = 'steps' then
    Result := TrText('Assistant.ReplyStyle.Body.Steps')
  else if U = 'technical' then
    Result := TrText('Assistant.ReplyStyle.Body.Technical')
  else if U = 'friendly' then
    Result := TrText('Assistant.ReplyStyle.Body.Friendly')
  else if U = 'custom' then
    Result := Trim(FReplyStyleCustom)
  else if Assigned(FReplyStyleUserPresets) and (FReplyStyleUserPresets.IndexOfName(AId) >= 0) then
    Result := FReplyStyleUserPresets.Values[AId]
  else
    Result := '';
end;

function TFastFileAssistantCtrl.CurrentReplyStyleInstructions: string;
begin
  Result := Trim(ReplyStylePresetBody(FReplyStylePresetId));
  if (Result = '') and SameText(FReplyStylePresetId, 'custom') then
    Result := Trim(FReplyStyleCustom);
end;

procedure TFastFileAssistantCtrl.FillReplyStyleCombo;
var
  I, Sel: Integer;
  WantId, Cap: string;
  Code: NativeInt;
begin
  if not Assigned(CmbReplyStyle) then Exit;
  WantId := LowerCase(Trim(FReplyStylePresetId));
  if WantId = '' then
    WantId := 'default';
  Sel := 0;
  CmbReplyStyle.Items.BeginUpdate;
  try
    CmbReplyStyle.Items.Clear;
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Default'), TObject(1));
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Concise'), TObject(2));
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Bullets'), TObject(3));
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Steps'), TObject(4));
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Technical'), TObject(5));
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Friendly'), TObject(6));
    CmbReplyStyle.Items.AddObject(TrText('Assistant.ReplyStyle.Custom'), TObject(7));
    if Assigned(FReplyStyleUserPresets) then
      for I := 0 to FReplyStyleUserPresets.Count - 1 do
      begin
        Cap := FReplyStyleUserPresets.Names[I];
        if Cap = '' then Continue;
        CmbReplyStyle.Items.AddObject(Cap, TObject(100 + I));
      end;
  finally
    CmbReplyStyle.Items.EndUpdate;
  end;
  for I := 0 to CmbReplyStyle.Items.Count - 1 do
  begin
    case NativeInt(CmbReplyStyle.Items.Objects[I]) of
      1: Cap := 'default';
      2: Cap := 'concise';
      3: Cap := 'bullets';
      4: Cap := 'steps';
      5: Cap := 'technical';
      6: Cap := 'friendly';
      7: Cap := 'custom';
    else
      begin
        Code := NativeInt(CmbReplyStyle.Items.Objects[I]);
        Cap := '';
        if (Code >= 100) and Assigned(FReplyStyleUserPresets) and
           (Code - 100 >= 0) and (Code - 100 < FReplyStyleUserPresets.Count) then
          Cap := FReplyStyleUserPresets.Names[Code - 100];
      end;
    end;
    if SameText(Cap, WantId) then
    begin
      Sel := I;
      Break;
    end;
  end;
  CmbReplyStyle.ItemIndex := Sel;
  if Assigned(BtnReplyStyleEdit) then
    BtnReplyStyleEdit.Enabled := True;
end;

procedure TFastFileAssistantCtrl.LoadReplyStylePrefs;
var
  Ini: TIniFile;
  N, I: Integer;
  Name, Body: string;
begin
  FReplyStylePresetId := 'default';
  FReplyStyleCustom := '';
  if Assigned(FReplyStyleUserPresets) then
    FReplyStyleUserPresets.Clear;
  if FIniPath = '' then
    FIniPath := ExtractFilePath(Application.ExeName) + ASKIN_INI;
  Ini := TIniFile.Create(FIniPath);
  try
    FReplyStylePresetId := Ini.ReadString('AssistantReplyStyle', 'PresetId', 'default');
    FReplyStyleCustom := Ini.ReadString('AssistantReplyStyle', 'Custom', '');
    FReplyStyleCustom := StringReplace(FReplyStyleCustom, '\n', sLineBreak, [rfReplaceAll]);
    N := Ini.ReadInteger('AssistantReplyStyle', 'UserCount', 0);
    if N > 24 then N := 24;
    for I := 0 to N - 1 do
    begin
      Name := Trim(Ini.ReadString('AssistantReplyStyle', 'UserName' + IntToStr(I), ''));
      Body := Ini.ReadString('AssistantReplyStyle', 'UserBody' + IntToStr(I), '');
      Body := StringReplace(Body, '\n', sLineBreak, [rfReplaceAll]);
      if (Name <> '') and (Body <> '') then
        FReplyStyleUserPresets.Values[Name] := Body;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TFastFileAssistantCtrl.SaveReplyStylePrefs;
var
  Ini: TIniFile;
  I, N: Integer;
  Name, Body: string;
begin
  if FIniPath = '' then
    FIniPath := ExtractFilePath(Application.ExeName) + ASKIN_INI;
  Ini := TIniFile.Create(FIniPath);
  try
    Ini.WriteString('AssistantReplyStyle', 'PresetId', FReplyStylePresetId);
    Ini.WriteString('AssistantReplyStyle', 'Custom',
      StringReplace(FReplyStyleCustom, sLineBreak, '\n', [rfReplaceAll]));
    N := 0;
    if Assigned(FReplyStyleUserPresets) then
      for I := 0 to FReplyStyleUserPresets.Count - 1 do
      begin
        Name := FReplyStyleUserPresets.Names[I];
        Body := FReplyStyleUserPresets.ValueFromIndex[I];
        if (Name = '') or (Body = '') then Continue;
        Ini.WriteString('AssistantReplyStyle', 'UserName' + IntToStr(N), Name);
        Ini.WriteString('AssistantReplyStyle', 'UserBody' + IntToStr(N),
          StringReplace(Body, sLineBreak, '\n', [rfReplaceAll]));
        Inc(N);
        if N >= 24 then Break;
      end;
    Ini.WriteInteger('AssistantReplyStyle', 'UserCount', N);
  finally
    Ini.Free;
  end;
end;

procedure TFastFileAssistantCtrl.CmbReplyStyleChange(Sender: TObject);
var
  Idx: Integer;
  Code: NativeInt;
begin
  if not Assigned(CmbReplyStyle) then Exit;
  Idx := CmbReplyStyle.ItemIndex;
  if Idx < 0 then Exit;
  Code := NativeInt(CmbReplyStyle.Items.Objects[Idx]);
  case Code of
    1: FReplyStylePresetId := 'default';
    2: FReplyStylePresetId := 'concise';
    3: FReplyStylePresetId := 'bullets';
    4: FReplyStylePresetId := 'steps';
    5: FReplyStylePresetId := 'technical';
    6: FReplyStylePresetId := 'friendly';
    7: FReplyStylePresetId := 'custom';
  else
    if (Code >= 100) and Assigned(FReplyStyleUserPresets) and
       (Code - 100 < FReplyStyleUserPresets.Count) then
      FReplyStylePresetId := FReplyStyleUserPresets.Names[Code - 100];
  end;
  SaveReplyStylePrefs;
  if SameText(FReplyStylePresetId, 'custom') and (Trim(FReplyStyleCustom) = '') then
    EditReplyStyleTemplate;
end;

procedure TFastFileAssistantCtrl.BtnReplyStyleEditClick(Sender: TObject);
begin
  EditReplyStyleTemplate;
end;

procedure TFastFileAssistantCtrl.StyleDlgExampleChange(Sender: TObject);
var
  Ix: Integer;
begin
  if (FStyleDlgMemo = nil) or (FStyleDlgCmb = nil) or (FStyleDlgExIds = nil) then Exit;
  Ix := FStyleDlgCmb.ItemIndex;
  if (Ix >= 0) and (Ix < FStyleDlgExIds.Count) then
    FStyleDlgMemo.Text := ReplyStylePresetBody(FStyleDlgExIds[Ix]);
end;

procedure TFastFileAssistantCtrl.StyleDlgSaveAsClick(Sender: TObject);
var
  Name: string;
begin
  if FStyleDlgMemo = nil then Exit;
  Name := Trim(InputBox(TrText('Assistant.ReplyStyle.SaveAsTitle'),
    TrText('Assistant.ReplyStyle.SaveAsPrompt'), ''));
  if Name = '' then Exit;
  FReplyStyleUserPresets.Values[Name] := Trim(FStyleDlgMemo.Text);
  FReplyStylePresetId := Name;
  FReplyStyleCustom := Trim(FStyleDlgMemo.Text);
  SaveReplyStylePrefs;
  FillReplyStyleCombo;
  SetStatusCaption(TrText('Assistant.ReplyStyle.Saved'));
end;

procedure TFastFileAssistantCtrl.EditReplyStyleTemplate;
var
  Dlg: TForm;
  Memo: TMemo;
  CmbEx: TComboBox;
  LblEx, LblHint: TLabel;
  BtnOk, BtnCancel, BtnSaveAs: TButton;
  Body: string;
  ExIds: TStringList;

  procedure AddEx(const AId, ACap: string);
  begin
    ExIds.Add(AId);
    CmbEx.Items.Add(ACap);
  end;

begin
  Body := CurrentReplyStyleInstructions;
  if Body = '' then
    Body := ReplyStylePresetBody('bullets');

  ExIds := TStringList.Create;
  Dlg := TForm.CreateNew(Self);
  FStyleDlgMemo := nil;
  FStyleDlgCmb := nil;
  FStyleDlgExIds := ExIds;
  try
    Dlg.Caption := TrText('Assistant.ReplyStyle.EditTitle');
    Dlg.BorderStyle := bsDialog;
    Dlg.Position := poScreenCenter;
    Dlg.ClientWidth := 480;
    Dlg.ClientHeight := 400;
    Dlg.Font.Name := 'Segoe UI';
    Dlg.Font.Size := 9;

    { AutoSize=True (TLabel default) shrinks width to one word and stacks
      the caption down the dialog — overlaps Examples / Save. }
    LblHint := TLabel.Create(Dlg);
    LblHint.Parent := Dlg;
    LblHint.AutoSize := False;
    LblHint.WordWrap := True;
    LblHint.Transparent := True;
    LblHint.SetBounds(12, 10, 456, 48);
    LblHint.Caption := TrText('Assistant.ReplyStyle.EditIntro');

    LblEx := TLabel.Create(Dlg);
    LblEx.Parent := Dlg;
    LblEx.AutoSize := False;
    LblEx.Transparent := True;
    LblEx.SetBounds(12, 64, 456, 16);
    LblEx.Caption := TrText('Assistant.ReplyStyle.Examples');

    CmbEx := TComboBox.Create(Dlg);
    CmbEx.Parent := Dlg;
    CmbEx.SetBounds(12, 82, 456, 22);
    CmbEx.Style := csDropDownList;
    AddEx('concise', TrText('Assistant.ReplyStyle.Concise'));
    AddEx('bullets', TrText('Assistant.ReplyStyle.Bullets'));
    AddEx('steps', TrText('Assistant.ReplyStyle.Steps'));
    AddEx('technical', TrText('Assistant.ReplyStyle.Technical'));
    AddEx('friendly', TrText('Assistant.ReplyStyle.Friendly'));
    CmbEx.ItemIndex := 1;

    Memo := TMemo.Create(Dlg);
    Memo.Parent := Dlg;
    Memo.SetBounds(12, 112, 456, 230);
    Memo.ScrollBars := ssVertical;
    Memo.WantReturns := True;
    Memo.Text := Body;

    FStyleDlgMemo := Memo;
    FStyleDlgCmb := CmbEx;
    CmbEx.OnChange := StyleDlgExampleChange;

    BtnSaveAs := TButton.Create(Dlg);
    BtnSaveAs.Parent := Dlg;
    BtnSaveAs.SetBounds(12, 356, 150, 28);
    BtnSaveAs.Caption := TrText('Assistant.ReplyStyle.SaveAs');
    BtnSaveAs.OnClick := StyleDlgSaveAsClick;

    BtnOk := TButton.Create(Dlg);
    BtnOk.Parent := Dlg;
    BtnOk.SetBounds(292, 356, 88, 28);
    BtnOk.Caption := 'OK';
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;

    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Dlg;
    BtnCancel.SetBounds(388, 356, 80, 28);
    BtnCancel.Caption := TrText('Cancel');
    if BtnCancel.Caption = 'Cancel' then
      BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;

    if Dlg.ShowModal = mrOk then
    begin
      FReplyStyleCustom := Trim(Memo.Text);
      if FReplyStyleCustom <> '' then
        FReplyStylePresetId := 'custom';
      SaveReplyStylePrefs;
      FillReplyStyleCombo;
      SetStatusCaption(TrText('Assistant.ReplyStyle.Applied'));
    end;
  finally
    FStyleDlgMemo := nil;
    FStyleDlgCmb := nil;
    FStyleDlgExIds := nil;
    Dlg.Free;
    ExIds.Free;
  end;
end;

function TFastFileAssistantCtrl.BuildPromptW: WideString;
var
  Ctx, Rag, OpenPath, Bridge, StyleInstr: string;
  LineCount: Int64;
begin
  Ctx := AssistantHostGetContext;
  { lines=N from F5 / prior binary scan (cache). Never TextFile/ReadLn.
    No NL test — if we already know N, the model gets it. }
  if Pos('lines=', Ctx) = 0 then
  begin
    LineCount := AssistantHostGetOpenFileLineCount;
    if LineCount <= 0 then
    begin
      OpenPath := AssistantHostGetOpenFilePath;
      if OpenPath = '' then
        OpenPath := ExtractPathFromUserText(Trim(MemoQuestion.Text));
      if (OpenPath <> '') and FileExists(OpenPath) then
        LineCount := FastFileKnownLineCount(OpenPath);
    end;
    if LineCount > 0 then
      Ctx := Ctx + ';lines=' + IntToStr(LineCount);
  end;
  Rag := BuildAssistantHelpRAG(Trim(MemoQuestion.Text));
  Result :=
    WideString(BuildAssistantRulesBlock) + #13#10#13#10 +
    WideString(BuildOperationalKnowledgeBase) + #13#10#13#10;
  if Rag <> '' then
    Result := Result + WideString(Rag) + #13#10#13#10;
  Bridge := PipelineBuildBridgeContext(12);
  if Bridge <> '' then
    Result := Result + WideString(Bridge) + #13#10#13#10;
  StyleInstr := CurrentReplyStyleInstructions;
  if StyleInstr <> '' then
    Result := Result +
      WideString('RESPONSE_FORMAT_INSTRUCTIONS:') + #13#10 +
      WideString(StyleInstr) + #13#10#13#10 +
      WideString('Follow RESPONSE_FORMAT_INSTRUCTIONS when writing user_message.') + #13#10#13#10;
  Result := Result +
    WideString('CURRENT_CONTEXT: ') + WideString(Ctx) + #13#10#13#10 +
    WideString('USER_QUESTION: ') + WideString(Trim(MemoQuestion.Text));
end;

function BuildOpenFileLocalFactsText(const UserQ: string): string;
{ Lines / disk meta asked in UserQ, answered from the open file / edtFileName. }
var
  Body, OpenPath, OtherPath, MetaText: string;
  LineCount: Int64;
  MetaKinds: TAssistantOpenFileMetaKinds;
  MetaKind: TAssistantOpenFileMetaKind;
  CreatedAt, AccessedAt, ModifiedAt: TDateTime;
  SizeBytes: Int64;
  WantLines, HaveDisk: Boolean;

  procedure AppendBodyLine(const S: string);
  begin
    if S = '' then Exit;
    if Body = '' then
      Body := S
    else
      Body := Body + #13#10 + S;
  end;

begin
  Result := '';
  WantLines := UserAsksOpenFileTotalLineCount(UserQ);
  MetaKinds := CollectOpenFileDiskMetaAsks(UserQ);
  if (not WantLines) and (MetaKinds = []) then Exit;

  OpenPath := AssistantHostGetOpenFilePath;
  OtherPath := ExtractPathFromUserText(UserQ);
  if (OtherPath <> '') and (OpenPath <> '') and (not SameText(OtherPath, OpenPath)) then
    OpenPath := OtherPath
  else if OpenPath = '' then
    OpenPath := OtherPath;

  Body := '';
  if WantLines then
  begin
    LineCount := AssistantHostGetOpenFileLineCount;
    if (LineCount <= 0) and (OpenPath <> '') and FileExists(OpenPath) then
      LineCount := FastFileCountLines(OpenPath);
    if LineCount > 0 then
    begin
      if OpenPath = '' then
        OpenPath := '?';
      AppendBodyLine(Format(TrText('Assistant.Reply.OpenFileLineCount'),
        [ExtractFileName(OpenPath), IntToStr(LineCount)]));
    end
    else
      AppendBodyLine(TrText('Assistant.Reply.OpenFileLineCountUnknown'));
  end;

  if MetaKinds <> [] then
  begin
    HaveDisk := False;
    if (OpenPath = '') or (not FileExists(OpenPath)) then
      AppendBodyLine(TrText('Assistant.Error.NoFileOpen'))
    else if not AssistantHostGetOpenFileDiskInfo(CreatedAt, AccessedAt, ModifiedAt, SizeBytes) then
      AppendBodyLine(TrText('Assistant.Reply.OpenFileMetaUnavailable'))
    else
      HaveDisk := True;

    if HaveDisk then
    begin
      if aofmProps in MetaKinds then
      begin
        MetaText := Format(TrText('Assistant.Reply.OpenFileProps'),
          [ExtractFileName(OpenPath),
           FormatDateTime('dd/mm/yyyy hh:nn:ss', CreatedAt),
           FormatDateTime('dd/mm/yyyy hh:nn:ss', ModifiedAt),
           FormatDateTime('dd/mm/yyyy hh:nn:ss', AccessedAt),
           IntToStr(SizeBytes)]);
        AppendBodyLine(MetaText);
      end
      else
        for MetaKind in MetaKinds do
          case MetaKind of
            aofmCreated:
              AppendBodyLine(Format(TrText('Assistant.Reply.OpenFileCreated'),
                [ExtractFileName(OpenPath), FormatDateTime('dd/mm/yyyy hh:nn:ss', CreatedAt)]));
            aofmModified:
              AppendBodyLine(Format(TrText('Assistant.Reply.OpenFileModified'),
                [ExtractFileName(OpenPath), FormatDateTime('dd/mm/yyyy hh:nn:ss', ModifiedAt)]));
            aofmAccessed:
              AppendBodyLine(Format(TrText('Assistant.Reply.OpenFileAccessed'),
                [ExtractFileName(OpenPath), FormatDateTime('dd/mm/yyyy hh:nn:ss', AccessedAt)]));
            aofmSize:
              AppendBodyLine(Format(TrText('Assistant.Reply.OpenFileSize'),
                [ExtractFileName(OpenPath), IntToStr(SizeBytes)]));
          end;
    end;
  end;
  Result := Body;
end;

function BuildComposeKnownFactsBlock(const UserQ: string): string;
{ Disk + line facts for the compose LLM prompt only — not the PDF body. }
var
  OpenPath, Asked: string;
  LineCount: Int64;
  CreatedAt, AccessedAt, ModifiedAt: TDateTime;
  SizeBytes: Int64;
begin
  Result := '';
  Asked := BuildOpenFileLocalFactsText(UserQ);
  OpenPath := AssistantHostGetOpenFilePath;
  if OpenPath = '' then
    OpenPath := ExtractPathFromUserText(UserQ);
  if (OpenPath <> '') and FileExists(OpenPath) and
     AssistantHostGetOpenFileDiskInfo(CreatedAt, AccessedAt, ModifiedAt, SizeBytes) then
  begin
    Result := Format(TrText('Assistant.Reply.OpenFileProps'),
      [ExtractFileName(OpenPath),
       FormatDateTime('dd/mm/yyyy hh:nn:ss', CreatedAt),
       FormatDateTime('dd/mm/yyyy hh:nn:ss', ModifiedAt),
       FormatDateTime('dd/mm/yyyy hh:nn:ss', AccessedAt),
       IntToStr(SizeBytes)]);
    LineCount := AssistantHostGetOpenFileLineCount;
    if (LineCount <= 0) and (OpenPath <> '') and FileExists(OpenPath) then
      LineCount := FastFileCountLines(OpenPath);
    if LineCount > 0 then
      Result := Result + #13#10 + Format(TrText('Assistant.Reply.OpenFileLineCount'),
        [ExtractFileName(OpenPath), IntToStr(LineCount)]);
  end;
  if Asked <> '' then
  begin
    if Result = '' then
      Result := Asked
    else if Pos(Asked, Result) = 0 then
      Result := Asked + #13#10#13#10 + Result;
  end;
end;

function ResolveStructuralFilterNeedle(const UserQ, PlanFilter: string): string;
var
  Prefs: TStringDynArray;
  i: Integer;
begin
  { Plan filter first; else quotes/backticks (not filenames); else digit codes
    that are not startswith-prefix counts. No NL verb dictionaries. }
  Result := Trim(PlanFilter);
  if Result <> '' then Exit;
  Result := ExtractQuotedNeedlesFromText(UserQ);
  if Result <> '' then Exit;
  if TryParseLinePrefixCountAsk(UserQ, Prefs) then Exit;
  if not CollectDigitRunNeedles(UserQ, Prefs) then Exit;
  Result := '';
  for i := 0 to High(Prefs) do
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + Prefs[i];
  end;
end;

function ComposeQuestionNeedsExistingFile(const AQuestion: string): Boolean;
var
  Prefs: TStringDynArray;
begin
  { Open-file jobs need edtFileName. Standalone source compose does not. }
  Result := False;
  if UserWantsComposeSourceCode(AQuestion) then Exit;
  Result := TryParseLinePrefixCountAsk(AQuestion, Prefs) or
    UserQuestionRefersToOpenFile(AQuestion);
end;

function AssistantComposeSourcePath(const AQuestion: string): string;
begin
  Result := Trim(ExtractPathFromUserText(AQuestion));
  if Result = '' then
    Result := Trim(AssistantHostGetOpenFilePath);
end;

function ComposeBodyLooksLikeAccessRefusal(const S: string): Boolean;
var
  L: string;
begin
  L := LowerCase(FoldDiacriticsForMatch(Trim(S)));
  Result := False;
  if L = '' then Exit;
  Result := (PosBMH('nao consigo', L) > 0) or (PosBMH('nao posso', L) > 0) or
    (PosBMH('cannot access', L) > 0) or (PosBMH('can''t access', L) > 0) or
    (PosBMH('unable to access', L) > 0) or (PosBMH('no puedo acceder', L) > 0) or
    (PosBMH('no puedo obtener', L) > 0) or (PosBMH('je ne peux pas acceder', L) > 0) or
    (PosBMH('kein zugriff', L) > 0) or (PosBMH('keinen zugriff', L) > 0) or
    (PosBMH('keinen zugriff auf', L) > 0) or (PosBMH('keine datei', L) > 0) or
    (PosBMH('non posso accedere', L) > 0) or
    (PosBMH('nie moge uzyskac', L) > 0) or (PosBMH('nu pot accesa', L) > 0) or
    ((PosBMH('nicht zahlen', L) > 0) and (PosBMH('zugriff', L) > 0));
end;

function StripComposeHostFactsEcho(const ABody, AFacts: string): string;
var
  L: string;
begin
  Result := Trim(ABody);
  if Result = '' then Exit;
  if (Trim(AFacts) <> '') and (Pos(AFacts, Result) > 0) then
    Result := Trim(StringReplace(Result, AFacts, '', [rfReplaceAll]));
  L := LowerCase(FoldDiacriticsForMatch(Result));
  if Length(Result) > 900 then Exit;
  if ((PosBMH('criacao:', L) > 0) or (PosBMH('creation:', L) > 0) or
      (PosBMH('erstellt:', L) > 0) or (PosBMH('creacion:', L) > 0)) and
     ((PosBMH('tamanho:', L) > 0) or (PosBMH('size:', L) > 0) or
      (PosBMH('bytes', L) > 0)) then
    Result := '';
end;

function MergeComposeChatParts(const AFacts, ASummary, ASaved: string): string;
var
  Preview: string;
  CutPos, i, Lines: Integer;
begin
  Result := '';
  if Trim(AFacts) <> '' then
    Result := Trim(AFacts);
  Preview := Trim(ASummary);
  if Preview <> '' then
  begin
    { Keep a short chat preview; full text is in the generated PDF/Word. }
    CutPos := 0;
    Lines := 0;
    for i := 1 to Length(Preview) do
    begin
      if Preview[i] = #10 then
      begin
        Inc(Lines);
        if Lines >= 18 then
        begin
          CutPos := i;
          Break;
        end;
      end;
      if i >= 1600 then
      begin
        CutPos := i;
        Break;
      end;
    end;
    if CutPos > 0 then
      Preview := Trim(Copy(Preview, 1, CutPos)) + #13#10 + '…';
    if Result <> '' then
      Result := Result + #13#10#13#10;
    Result := Result + Preview;
  end;
  if Trim(ASaved) <> '' then
  begin
    if Result <> '' then
      Result := Result + #13#10#13#10;
    Result := Result + Trim(ASaved);
  end;
end;

function TFastFileAssistantCtrl.BuildComposeSummarizePromptW: WideString;
var
  Facts: string;
  LineCount: Int64;
begin
  Result :=
    WideString('You summarize a data file sample for FastFile.') + #13#10 +
    WideString('Reply with ONE JSON object only (no markdown):') + #13#10 +
    WideString('{"resposta":"<the FULL summary text in the user language>"}') + #13#10 +
    WideString('The field resposta MUST be non-empty.') + #13#10 +
    WideString('Write a clear structured summary: overview, columns/fields, patterns, quality, uses.') + #13#10 +
    WideString('KNOWN_FACTS below are orientation only (disk dates, size, line count). ') +
    WideString('Do NOT copy creation/modified/access dates or byte size into resposta ') +
    WideString('unless USER_REQUEST explicitly asked for those properties. ') +
    WideString('NEVER say you cannot access the file, dates, or size when KNOWN_FACTS is present.') + #13#10 +
    WideString('Do not invent other row counts beyond what the sample supports; say "sample-based".') + #13#10 +
    WideString('Do not tell the user to copy into Word. Do not emit RTF/DOCX/PDF markup.') + #13#10 +
    WideString('CRITICAL: FastFile ALREADY saves this text as the final PDF/Word/ODT/RTF. ') +
    WideString('resposta is the DOCUMENT BODY only (what the file represents / analysis). ') +
    WideString('NEVER dump file-system metadata as the whole document. ') +
    WideString('NEVER include how-to sections about creating/converting/exporting PDF ') +
    WideString('(no enscript, ps2pdf, "Imprimir > Salvar como PDF", LibreOffice, pandoc, shell). ') +
    WideString('NEVER tell the user to run commands or open another app to produce the PDF.') + #13#10 +
    WideString('If FILTERED_LINES are mentioned in the task: write a SHORT overview only. ') +
    WideString('Do NOT paste, renumber, or truncate filtered records — FastFile appends them verbatim.') + #13#10 +
    WideString('Do not use intent/action/user_message.') + #13#10#13#10 +
    WideString('USER_REQUEST: ') + WideString(Trim(MemoQuestion.Text)) + #13#10#13#10;
  LineCount := AssistantHostGetOpenFileLineCount;
  Facts := BuildComposeKnownFactsBlock(Trim(MemoQuestion.Text));
  if (LineCount > 0) or (Facts <> '') then
  begin
    Result := Result + WideString('KNOWN_FACTS from FastFile (orientation; do not dump as the document):') + #13#10;
    if Facts <> '' then
      Result := Result + WideString(Facts) + #13#10
    else if LineCount > 0 then
      Result := Result + WideString('lines=') + WideString(IntToStr(LineCount)) + #13#10;
    Result := Result + #13#10;
  end;
  Result := Result +
    WideString('SOURCE_FILE_SAMPLE:') + #13#10 + WideString(FComposeSourceBody);
end;

function TFastFileAssistantCtrl.BuildComposePromptW: WideString;
var
  Facts: string;
begin
  Result :=
    WideString('You generate or revise ONE standalone document for FastFile.') + #13#10 +
    WideString('Reply with ONE JSON object only (no markdown):') + #13#10 +
    WideString('{"resposta":"<the FULL document text>"}') + #13#10 +
    WideString('The field resposta MUST be non-empty. Put the whole document there.') + #13#10 +
    WideString('Use normal JSON escaping once (newlines as \n inside the JSON string).') + #13#10 +
    WideString('Never double-escape (do not put literal backslash-n sequences as the document).') + #13#10 +
    WideString('For source code, resposta must be the real source with real line breaks after JSON decode.') + #13#10 +
    WideString('Do not use intent/action/user_message. Do not emit RTF or Word XML.') + #13#10 +
    WideString('Do not tell the user to copy/paste into Word. FastFile writes the file ') +
    WideString('(.rtf/.docx/.odt/.pdf or source).') + #13#10 +
    WideString('CRITICAL: This resposta IS the content FastFile will save as the final document. ') +
    WideString('NEVER write tutorials on how to convert TXT→PDF, Print→Save as PDF, enscript, ') +
    WideString('ps2pdf, pandoc, LibreOffice, or any shell/OS export steps. ') +
    WideString('If the user asked for a PDF, write the analysis/summary itself — not instructions to make one.') + #13#10 +
    WideString('If the host will append FILTERED_LINES: write ONLY a short summary; ') +
    WideString('do not list or truncate those records in resposta.') + #13#10 +
    WideString('Do not compile or run anything. This is not a general chatbot.') + #13#10 +
    WideString('REFUSE malware: never write viruses, ransomware, keyloggers, reverse shells, ') +
    WideString('or OS-destructive scripts. If asked, put a short refusal in resposta.') + #13#10 +
    WideString('When KNOWN_FACTS is present: use those dates/sizes/line counts verbatim. ') +
    WideString('NEVER claim you cannot access the open file or its metadata.') + #13#10#13#10;
  if FComposeIsFix then
  begin
    Result := Result +
      WideString('TASK: revise the current file. Keep the same file type.') + #13#10 +
      WideString('USER_FIX_REQUEST: ') + WideString(Trim(MemoQuestion.Text)) + #13#10#13#10 +
      WideString('CURRENT_FILE:') + #13#10 + WideString(FComposeSourceBody);
    Exit;
  end;
  Facts := BuildComposeKnownFactsBlock(Trim(MemoQuestion.Text));
  Result := Result +
    WideString('TASK: write the requested document from USER_REQUEST');
  if FComposeSourceBody <> '' then
    Result := Result + WideString(' and the sample');
  Result := Result +
    WideString('.') + #13#10 +
    WideString('USER_REQUEST: ') + WideString(Trim(MemoQuestion.Text));
  if Facts <> '' then
    Result := Result + #13#10#13#10 +
      WideString('KNOWN_FACTS from FastFile (orientation; do not dump as the document):') + #13#10 + WideString(Facts);
  if FComposeSourceBody <> '' then
    Result := Result + #13#10#13#10 +
      WideString('SOURCE_FILE_SAMPLE (header + first rows only; summarize from this):') + #13#10 +
      WideString(FComposeSourceBody);
end;

function ExpandComposeCStyleEscapes(const S: string): string;
{ Gateway/AI sometimes leave literal \n\r\t in the body (double-escaped JSON).
  Expand only when the blob is essentially one physical line with many \n sequences.
  Keep \\ as-is so Java/C# Windows paths stay valid. }
var
  i, RealNL, EscNL: Integer;
  Ch: Char;
begin
  RealNL := 0;
  EscNL := 0;
  for i := 1 to Length(S) do
  begin
    if S[i] in [#10, #13] then
      Inc(RealNL)
    else if (S[i] = '\') and (i < Length(S)) and (S[i + 1] = 'n') then
      Inc(EscNL);
  end;
  if (RealNL > 1) or (EscNL < 2) then
  begin
    Result := S;
    Exit;
  end;
  Result := '';
  i := 1;
  while i <= Length(S) do
  begin
    if (S[i] = '\') and (i < Length(S)) then
    begin
      Ch := S[i + 1];
      case Ch of
        'n':
          begin
            Result := Result + #10;
            Inc(i, 2);
            Continue;
          end;
        'r':
          begin
            Result := Result + #13;
            Inc(i, 2);
            Continue;
          end;
        't':
          begin
            Result := Result + #9;
            Inc(i, 2);
            Continue;
          end;
        '"':
          begin
            Result := Result + '"';
            Inc(i, 2);
            Continue;
          end;
        '\':
          begin
            Result := Result + '\\';
            Inc(i, 2);
            Continue;
          end;
      end;
    end;
    Result := Result + S[i];
    Inc(i);
  end;
end;

function ExtractComposeAnswerText(const ABody: string): string;
var
  Body, Inner: string;
begin
  Body := StripComposeBody(ABody);
  Inner := Trim(Body);
  if (Inner <> '') and (Inner[1] = '{') then
  begin
    Inner := ExtractJsonStringFieldAnsi(Body, 'resposta');
    if Inner = '' then
      Inner := ExtractJsonStringFieldAnsi(Body, 'user_message');
    if Inner <> '' then
      Body := Inner;
  end;
  Result := Trim(ExpandComposeCStyleEscapes(Body));
end;

procedure TFastFileAssistantCtrl.AbortComposeWrite(const AMsg: string);
begin
  if Trim(AMsg) <> '' then
    FLastReplyBody := AMsg
  else
    FLastReplyBody := TrText('Assistant.Error.NoFileOpen');
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
  SetStatusCaption(TrText('Assistant.ReplyReady'));
  FComposeDestPath := '';
  FComposeAwaitingBody := False;
  FComposeIsFix := False;
  FComposeSourceBody := '';
  FComposeAppendBody := '';
  FComposeAppendFiltered := False;
  FComposePipelineWord := False;
  FComposeSummarizePhase := False;
end;

function TFastFileAssistantCtrl.StartComposeGeneration: Boolean;
var
  Dest, Msg, UserQ, ReadErr, Src, Facts, Prior, StatusMsg, DestNote: string;
  Joined, ExecMsg, Needle: string;
  Prefs: TStringDynArray;
  CountPlan: TAssistantPlan;
  i: Integer;
  Th: TFastFileAssistantThread;
  PromptW: WideString;
begin
  Result := False;
  UserQ := Trim(MemoQuestion.Text);
  if UserQuestionIsOutOfScopeOrHarmful(UserQ) then
  begin
    FLastReplyBody := TrText('Assistant.Error.OutOfScopeHarmful');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Exit;
  end;
  if ComposeQuestionNeedsExistingFile(UserQ) then
  begin
    Src := AssistantComposeSourcePath(UserQ);
    if (Src = '') or (not FileExists(Src)) then
    begin
      AbortComposeWrite(TrText('Assistant.Error.NoFileOpen'));
      Exit;
    end;
  end;
  FComposeIsFix := UserWantsFixComposedDocument(UserQ) or
    ((GLastComposePath <> '') and UserWantsShortComposeFix(UserQ));
  FComposeSourceBody := '';
  FComposeAppendBody := '';
  FComposeAppendFiltered := False;
  FComposeSummarizePhase := False;
  FComposePipelineWord := False;
  if FComposeIsFix then
  begin
    Dest := ResolveComposeFixPath(UserQ, GLastComposePath);
    if Trim(Dest) = '' then
    begin
      FLastReplyBody := TrText('Assistant.Error.ComposeNothingToFix');
      MemoReply.Lines.Text := FLastReplyBody;
      SetStatusCaption(TrText('Assistant.ReplyReady'));
      FComposeIsFix := False;
      Exit;
    end;
    if not ReadComposeDocument(Dest, FComposeSourceBody, ReadErr) then
    begin
      FLastReplyBody := ReadErr;
      if FLastReplyBody = '' then
        FLastReplyBody := TrText('Assistant.Error.ComposeNothingToFix');
      MemoReply.Lines.Text := FLastReplyBody;
      SetStatusCaption(TrText('Assistant.ReplyReady'));
      FComposeIsFix := False;
      Exit;
    end;
  end
  else
  begin
    if RejectUnsupportedComposeFormat(UserQ) then
      Exit;
    Dest := GuessComposeOutputPath(UserQ);
  end;
  if Trim(Dest) = '' then
  begin
    FLastReplyBody := TrText('Assistant.Error.ComposeWriteFailed');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    Exit;
  end;
  if not FComposeIsFix then
  begin
    { AI-first + host context: the open edtFileName file is the default subject
      for any wording/language. Only an explicit path in the question overrides. }
    Src := ExtractPathFromUserText(UserQ);
    if Src = '' then
      Src := AssistantHostGetOpenFilePath;
    FComposeSourceBody := '';
    FComposePipelineWord := False;
    FComposeSummarizePhase := False;
    { Prefix counts + PDF: never feed a file sample to the model — it invents
      "sample has N lines" and overwrites host counts. Write ExecMsg directly. }
    if TryParseLinePrefixCountAsk(UserQ, Prefs) then
    begin
      Joined := '';
      for i := 0 to High(Prefs) do
      begin
        if Joined <> '' then
          Joined := Joined + '|';
        Joined := Joined + Prefs[i];
      end;
      CountPlan := FLastPlan;
      CountPlan.Intent := aiExecute;
      CountPlan.ActionId := 'count_line_prefixes';
      CountPlan.FilterText := Joined;
      CountPlan.Path := AssistantHostGetOpenFilePath;
      CountPlan.NeedConfirm := False;
      CountPlan.ComposeAfterCount := True;
      CountPlan.NativeFollowUpAction := '';
      CountPlan.ChainCount := 0;
      CountPlan.AlsoCountMatching := FLastPlan.AlsoCountMatching;
      CountPlan.AlsoCountPrefixes := FLastPlan.AlsoCountPrefixes;
      SanitizeCountSourcePath(CountPlan);
      ExecMsg := ExecuteAssistantPlan(CountPlan);
      if SameText(Trim(ExecMsg), TrText('Assistant.Error.NoFileOpen')) or
         SameText(Trim(ExecMsg), TrText('Assistant.Error.FilterTextRequired')) or
         SameText(Trim(ExecMsg), TrText('Assistant.Reply.OpenFileMetaUnavailable')) or
         SameText(Trim(ExecMsg), TrText('Assistant.Error.HostNotReady')) then
      begin
        if Trim(ExecMsg) <> '' then
          AbortComposeWrite(ExecMsg)
        else
          AbortComposeWrite(TrText('Assistant.Error.NoFileOpen'));
        Exit;
      end;
      if Trim(ExecMsg) <> '' then
      begin
        if Trim(FLastReplyBody) = '' then
          FLastReplyBody := ExecMsg
        else if Pos(ExecMsg, FLastReplyBody) = 0 then
          FLastReplyBody := FLastReplyBody + #13#10#13#10 + ExecMsg;
        ComposeSavedDocumentFromText(UserQ, ExecMsg);
        FComposeIsFix := False;
        EndAssistantWait;
        Result := True;
        Exit;
      end;
      { Count returned empty — do not invent a sample PDF. }
      AbortComposeWrite(TrText('Assistant.Error.NoFileOpen'));
      Exit;
    end
    else
    begin
      { Filter + PDF: mark deferred host append. Do NOT collect lines here —
        apply_filter is async and a sync scan freezes the UI on multi-GB files.
        Collect runs after the AI summary returns (filter usually has hits by then). }
      Needle := ResolveStructuralFilterNeedle(UserQ, FLastPlan.FilterText);
      if Needle <> '' then
        FLastPlan.FilterText := Needle;
      if (Needle <> '') and QuestionSignalsSavedRichDocument(UserQ) then
      begin
        FComposeAppendFiltered := True;
        if (Src <> '') and FileExists(Src) and
           not SameText(ExpandFileName(Src), ExpandFileName(Dest)) then
          FComposeSourceBody := ReadComposeSourceSample(Src);
        FComposePipelineWord := True;
        FComposeSummarizePhase := True;
      end;
      if (not FComposeAppendFiltered) and (Src <> '') and FileExists(Src) and
         not SameText(ExpandFileName(Src), ExpandFileName(Dest)) then
      begin
        FComposeSourceBody := ReadComposeSourceSample(Src);
        FComposePipelineWord := (Trim(FComposeSourceBody) <> '') and
          QuestionSignalsSavedRichDocument(UserQ);
        FComposeSummarizePhase := FComposePipelineWord;
      end;
    end;
  end;
  if not PathIsInsideComposeDefaultOut(Dest) then
  begin
    Msg := Format(TrText('Assistant.Confirm.ComposeWriteOutsideTemp'), [Dest]);
    if FastFileMessageBox(PChar(Msg), PChar(TrText('Assistant.Title')),
      MB_YESNO or MB_ICONQUESTION) <> IDYES then
    begin
      FLastReplyBody := TrText('Assistant.Error.ComposeCancelled');
      MemoReply.Lines.Text := FLastReplyBody;
      SetStatusCaption(TrText('Assistant.ReplyReady'));
      BtnExecute.Enabled := False;
      FComposeIsFix := False;
      FComposeSummarizePhase := False;
      FComposePipelineWord := False;
      FComposeAppendFiltered := False;
      Exit;
    end;
  end;
  FComposeDestPath := Dest;
  FComposeAwaitingBody := True;
  FBusy := True;
  FHasPlan := True;
  FMsLastAi := 0;
  FMsLastExec := 0;
  { Keep the AI-composed reply when present; only fall back to a short status. }
  Prior := Trim(FLastReplyBody);
  if Prior = '' then
    Prior := Trim(FLastPlan.UserMessage);
  if FComposeIsFix then
    StatusMsg := TrText('Assistant.Local.WillFixDocument')
  else if FComposePipelineWord then
    StatusMsg := TrText('Assistant.Local.WillComposeFileSummary')
  else
    StatusMsg := TrText('Assistant.Local.WillComposeDocument');
  if Prior <> '' then
    FLastReplyBody := Prior
  else
    FLastReplyBody := StatusMsg;
  Facts := BuildOpenFileLocalFactsText(UserQ);
  if (Facts <> '') and (Pos(Facts, FLastReplyBody) = 0) then
    FLastReplyBody := Facts + #13#10#13#10 + FLastReplyBody;
  DestNote := Format(TrText('Assistant.Status.ComposeWillSaveTo'), [Dest]);
  if Pos(DestNote, FLastReplyBody) = 0 then
    FLastReplyBody := FLastReplyBody + #13#10#13#10 + DestNote;
  if FComposeSummarizePhase then
  begin
    StatusMsg := TrText('Assistant.Status.ComposePipelineStep1');
    if Pos(StatusMsg, FLastReplyBody) = 0 then
      FLastReplyBody := FLastReplyBody + #13#10#13#10 + StatusMsg;
  end;
  FTickAiStart := GetTickCount;
  BtnExecute.Enabled := False;
  BtnSend.Enabled := False;
  SetStatusCaption(TrText('Assistant.Thinking'));
  BeginAssistantWait(TrText('Assistant.Processing'));
  MemoReply.Lines.Text := FLastReplyBody;
  if FComposeSummarizePhase then
    PromptW := BuildComposeSummarizePromptW
  else
    PromptW := BuildComposePromptW;
  Th := TFastFileAssistantThread.Create(Self, PromptW);
  Th.Resume;
  Result := True;
end;

procedure TFastFileAssistantCtrl.EnsureComposeFilteredAppendBody;
var
  Needle, Lines: string;
  LineLimit: Integer;
begin
  if not FComposeAppendFiltered then Exit;
  FComposeAppendFiltered := False;
  if Trim(FComposeAppendBody) <> '' then Exit;
  Needle := ResolveStructuralFilterNeedle(Trim(MemoQuestion.Text), FLastPlan.FilterText);
  if Needle = '' then Exit;
  LineLimit := FLastPlan.MaxLines;
  if LineLimit < 1 then
    LineLimit := ExtractMaxRecordsFromText(Trim(MemoQuestion.Text));
  if LineLimit < 1 then
    LineLimit := 100;
  if LineLimit > 500 then
    LineLimit := 500;
  Lines := AssistantHostCollectMatchingLines(Needle, LineLimit, FLastPlan.CaseSensitive);
  if Trim(Lines) <> '' then
    FComposeAppendBody := Lines;
end;

procedure TFastFileAssistantCtrl.FinishComposeSummaryThenWrite(const ASummary: string);
var
  Body, Doc, Err, Saved, SrcName, Facts, AiChat, Dump: string;
begin
  Dump := BuildComposeKnownFactsBlock(Trim(MemoQuestion.Text));
  Body := StripComposeHostFactsEcho(ExtractComposeAnswerText(ASummary), Dump);
  if ComposeBodyLooksLikeAccessRefusal(Body) then
    Body := '';
  EnsureComposeFilteredAppendBody;
  { PDF body: only user-asked disk meta (dates/size/lines), never a full props dump. }
  Facts := BuildOpenFileLocalFactsText(Trim(MemoQuestion.Text));
  SrcName := ExtractFileName(AssistantHostGetOpenFilePath);
  if SrcName = '' then
    SrcName := ExtractFileName(ExtractPathFromUserText(Trim(MemoQuestion.Text)));
  if SrcName = '' then
    SrcName := 'arquivo';
  if (Trim(Body) = '') and (Trim(Facts) = '') and (Trim(FComposeAppendBody) = '') then
  begin
    FLastReplyBody := TrText('Assistant.Error.ComposeEmpty');
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    FComposeDestPath := '';
    FComposePipelineWord := False;
    FComposeSourceBody := '';
    FComposeAppendBody := '';
    FComposeAppendFiltered := False;
    Exit;
  end;
  Doc := TrText('Assistant.Compose.SummaryDocTitle') + ' ' + SrcName + #13#10#13#10;
  if Facts <> '' then
    Doc := Doc + Facts + #13#10#13#10;
  if Trim(Body) <> '' then
    Doc := Doc + Body;
  if Trim(FComposeAppendBody) <> '' then
    Doc := Doc + #13#10#13#10 + FComposeAppendBody;
  FLastReplyBody := TrText('Assistant.Status.ComposePipelineStep2') + #13#10#13#10 +
    Format(TrText('Assistant.Status.ComposeWillSaveTo'), [FComposeDestPath]);
  MemoReply.Lines.Text := FLastReplyBody;
  if not WriteComposeDocument(FComposeDestPath, Doc, Err) then
  begin
    FLastReplyBody := Format(TrText('Assistant.Error.ComposeWriteFailedAt'), [FComposeDestPath]);
    if Err <> '' then
      FLastReplyBody := FLastReplyBody + #13#10#13#10 + Err;
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    FComposeDestPath := '';
    FComposePipelineWord := False;
    FComposeSourceBody := '';
    FComposeAppendBody := '';
    Exit;
  end;
  Saved := Format(TrText('Assistant.Status.ComposeSavedDetail'),
    [FComposeDestPath]);
  Saved := TrText('Assistant.Status.ComposePipelineDone') + #13#10#13#10 + Saved;
  AppendSiblingComposeWrites(FComposeDestPath, Doc, Trim(MemoQuestion.Text), Saved);
  if IsRichComposeExtension(ExtractFileExt(FComposeDestPath)) then
    Saved := Saved + #13#10#13#10 + TrText('Assistant.Status.ComposeOpenInWord');
  { Prefer the router's AI chat text when it already answered parts of the ask;
    always merge AI document summary + local facts + saved path. }
  AiChat := Trim(FLastPlan.UserMessage);
  if (AiChat <> '') and
     (Pos(LowerCase(TrText('Assistant.Local.WillComposeFileSummary')), LowerCase(AiChat)) = 0) and
     (Pos(LowerCase(TrText('Assistant.Local.WillComposeDocument')), LowerCase(AiChat)) = 0) then
  begin
    if (Facts <> '') and (Pos(Facts, AiChat) = 0) then
      AiChat := Facts + #13#10#13#10 + AiChat;
    FLastReplyBody := MergeComposeChatParts(AiChat, Body, Saved);
  end
  else
    FLastReplyBody := MergeComposeChatParts(Facts, Body, Saved);
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
  SetStatusCaption(Format(TrText('Assistant.Status.ComposeSavedShort'),
    [ExtractFileName(FComposeDestPath)]));
  BtnExecute.Enabled := False;
  GLastComposePath := FComposeDestPath;
  AssistantHostNotifyGeneratedFile(FComposeDestPath);
  ShowGeneratedFileNotice(FComposeDestPath);
  AssistantWriteLog('compose-pipeline: ' + FComposeDestPath);
  FComposeDestPath := '';
  FComposeIsFix := False;
  FComposeSourceBody := '';
  FComposeAppendBody := '';
  FComposeAppendFiltered := False;
  FComposePipelineWord := False;
  FComposeSummarizePhase := False;
end;

procedure TFastFileAssistantCtrl.ComposeSavedDocumentFromText(const AQuestion, ABody: string);
var
  Dest, Doc, Err, Saved, SrcName, Q: string;
begin
  Q := Trim(AQuestion);
  if Q = '' then
    Q := Trim(MemoQuestion.Text);
  if Trim(ABody) = '' then Exit;
  if ComposeBodyLooksLikeAccessRefusal(ABody) or
     SameText(Trim(ABody), TrText('Assistant.Error.NoFileOpen')) or
     SameText(Trim(ABody), TrText('Assistant.Error.FilterTextRequired')) or
     SameText(Trim(ABody), TrText('Assistant.Reply.OpenFileMetaUnavailable')) or
     SameText(Trim(ABody), TrText('Assistant.Error.HostNotReady')) then
  begin
    AbortComposeWrite(TrText('Assistant.Error.NoFileOpen'));
    Exit;
  end;
  if ComposeQuestionNeedsExistingFile(Q) and
     ((AssistantComposeSourcePath(Q) = '') or (not FileExists(AssistantComposeSourcePath(Q)))) then
  begin
    AbortComposeWrite(TrText('Assistant.Error.NoFileOpen'));
    Exit;
  end;
  if RejectUnsupportedComposeFormat(Q) then
    Exit;
  Dest := GuessComposeOutputPath(Q);
  if Trim(Dest) = '' then
  begin
    FLastReplyBody := TrText('Assistant.Error.ComposeWriteFailed');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    Exit;
  end;
  SrcName := ExtractFileName(AssistantHostGetOpenFilePath);
  if SrcName = '' then
    SrcName := ExtractFileName(ExtractPathFromUserText(Q));
  if SrcName = '' then
    SrcName := 'arquivo';
  Doc := TrText('Assistant.Compose.SummaryDocTitle') + ' ' + SrcName + #13#10#13#10 +
    Trim(ABody);
  if not WriteComposeDocument(Dest, Doc, Err) then
  begin
    FLastReplyBody := Format(TrText('Assistant.Error.ComposeWriteFailedAt'), [Dest]);
    if Err <> '' then
      FLastReplyBody := FLastReplyBody + #13#10#13#10 + Err;
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    Exit;
  end;
  Saved := Format(TrText('Assistant.Status.ComposeSavedDetail'), [Dest]);
  Saved := TrText('Assistant.Status.ComposePipelineDone') + #13#10#13#10 + Saved;
  if IsRichComposeExtension(ExtractFileExt(Dest)) then
    Saved := Saved + #13#10#13#10 + TrText('Assistant.Status.ComposeOpenInWord');
  FLastReplyBody := MergeComposeChatParts(Trim(ABody), '', Saved);
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, True);
  SetStatusCaption(Format(TrText('Assistant.Status.ComposeSavedShort'),
    [ExtractFileName(Dest)]));
  BtnExecute.Enabled := False;
  GLastComposePath := Dest;
  AssistantHostNotifyGeneratedFile(Dest);
  ShowGeneratedFileNotice(Dest);
  AssistantWriteLog('compose-from-consumer-ai: ' + Dest);
end;

procedure TFastFileAssistantCtrl.MaybeComposeDocAfterCountPrefixes(const AQuestion, AActionId,
  AExecMsg: string);
begin
  if not (SameText(AActionId, 'count_line_prefixes') or
          SameText(AActionId, 'count_matching_lines')) then Exit;
  if Trim(AExecMsg) = '' then Exit;
  { AI-first: compose when the model chose compose_document (preserved on the plan)
    or the question carries a format id (pdf/docx/…) — not NL verb dictionaries. }
  if not (FLastPlan.ComposeAfterCount or QuestionSignalsSavedRichDocument(AQuestion)) then
    Exit;
  if SameText(Trim(AExecMsg), TrText('Assistant.Error.NoFileOpen')) or
     SameText(Trim(AExecMsg), TrText('Assistant.Error.FilterTextRequired')) or
     SameText(Trim(AExecMsg), TrText('Assistant.Reply.OpenFileMetaUnavailable')) or
     SameText(Trim(AExecMsg), TrText('Assistant.Error.HostNotReady')) then
    Exit;
  ComposeSavedDocumentFromText(AQuestion, AExecMsg);
end;

procedure TFastFileAssistantCtrl.FinishComposeWithBody(const ABody: string);
var
  Body, Err, Saved, Facts, Doc, SrcName, Dump: string;
begin
  Dump := BuildComposeKnownFactsBlock(Trim(MemoQuestion.Text));
  Body := StripComposeHostFactsEcho(ExtractComposeAnswerText(ABody), Dump);
  if ComposeBodyLooksLikeAccessRefusal(Body) then
    Body := '';
  EnsureComposeFilteredAppendBody;
  Facts := BuildOpenFileLocalFactsText(Trim(MemoQuestion.Text));
  if (Trim(Body) = '') and (Trim(Facts) = '') and (Trim(FComposeAppendBody) = '') then
  begin
    FLastReplyBody := TrText('Assistant.Error.ComposeEmpty');
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    FComposeDestPath := '';
    FComposeIsFix := False;
    FComposeSourceBody := '';
    FComposeAppendBody := '';
    FComposeAppendFiltered := False;
    FComposePipelineWord := False;
    FComposeSummarizePhase := False;
    Exit;
  end;
  SrcName := ExtractFileName(AssistantHostGetOpenFilePath);
  if SrcName = '' then
    SrcName := ExtractFileName(ExtractPathFromUserText(Trim(MemoQuestion.Text)));
  if SrcName = '' then
    SrcName := 'arquivo';
  if (Facts <> '') or FComposePipelineWord or
     QuestionSignalsSavedRichDocument(Trim(MemoQuestion.Text)) then
  begin
    Doc := TrText('Assistant.Compose.SummaryDocTitle') + ' ' + SrcName + #13#10#13#10;
    if Facts <> '' then
      Doc := Doc + Facts + #13#10#13#10;
    if Trim(Body) <> '' then
      Doc := Doc + Body;
    Body := Doc;
  end;
  if Trim(FComposeAppendBody) <> '' then
  begin
    if Trim(Body) <> '' then
      Body := Body + #13#10#13#10;
    Body := Body + FComposeAppendBody;
  end;
  if not WriteComposeDocument(FComposeDestPath, Body, Err) then
  begin
    FLastReplyBody := Format(TrText('Assistant.Error.ComposeWriteFailedAt'), [FComposeDestPath]);
    if Err <> '' then
      FLastReplyBody := FLastReplyBody + #13#10#13#10 + Err;
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    FComposeDestPath := '';
    FComposeIsFix := False;
    FComposeSourceBody := '';
    FComposeAppendBody := '';
    FComposeAppendFiltered := False;
    FComposePipelineWord := False;
    FComposeSummarizePhase := False;
    Exit;
  end;
  Saved := Format(TrText('Assistant.Status.ComposeSavedDetail'),
    [FComposeDestPath]);
  AppendSiblingComposeWrites(FComposeDestPath, Body, Trim(MemoQuestion.Text), Saved);
  if IsRichComposeExtension(ExtractFileExt(FComposeDestPath)) then
    Saved := Saved + #13#10#13#10 + TrText('Assistant.Status.ComposeOpenInWord');
  FLastReplyBody := MergeComposeChatParts(Facts, ExtractComposeAnswerText(ABody), Saved);
  if ComposeBodyLooksLikeAccessRefusal(ExtractComposeAnswerText(ABody)) and (Facts <> '') then
    FLastReplyBody := MergeComposeChatParts(Facts, '', Saved);
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
  SetStatusCaption(Format(TrText('Assistant.Status.ComposeSavedShort'),
    [ExtractFileName(FComposeDestPath)]));
  BtnExecute.Enabled := False;
  GLastComposePath := FComposeDestPath;
  AssistantHostNotifyGeneratedFile(FComposeDestPath);
  ShowGeneratedFileNotice(FComposeDestPath);
  AssistantWriteLog('compose: ' + FComposeDestPath);
  FComposeDestPath := '';
  FComposeIsFix := False;
  FComposeSourceBody := '';
  FComposeAppendBody := '';
  FComposeAppendFiltered := False;
  FComposePipelineWord := False;
  FComposeSummarizePhase := False;
end;

function TFastFileAssistantCtrl.TryHandleLocalSendQuery: Boolean;
var
  Plan: TAssistantPlan;
  UserQ, ValErr, ExecMsg, Body: string;
begin
  Result := False;
  UserQ := Trim(MemoQuestion.Text);
  if UserQ = '' then Exit;
  if UserQuestionIsOutOfScopeOrHarmful(UserQ) then
  begin
    FLastReplyBody := TrText('Assistant.Error.OutOfScopeHarmful');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Result := True;
    Exit;
  end;

  { AI-first: never answer NL locally. Line/date/size facts live in CURRENT_CONTEXT
    and are merged after the model returns. Only Ctrl/F-key shortcuts skip the LLM. }
  if not UserQuestionIsExplicitLocalShortcut(UserQ) then
    Exit;
  if not TryResolveLocalPlan(UserQ, Plan) then Exit;
  if not LocalPlanIsHighConfidence(Plan, UserQ) then Exit;
  ValErr := ValidatePlan(Plan);
  if ValErr <> '' then
  begin
    FLastReplyBody := Plan.UserMessage;
    if FLastReplyBody <> '' then
      FLastReplyBody := FLastReplyBody + #13#10#13#10;
    FLastReplyBody := FLastReplyBody + ValErr;
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := PlanNeedsExecuteButton(Plan);
    Result := True;
    Exit;
  end;
  if SameText(Plan.ActionId, 'compose_document') then
  begin
    Result := True;
    FLastPlan := Plan;
    if not StartComposeGeneration then
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;
  if not ShouldAutoExecutePlan(Plan, UserQ) then Exit;
  Result := True;
  FBusy := True;
  FHasPlan := False;
  FMsLastAi := 0;
  FMsLastExec := 0;
  FLastReplyBody := '';
  FTickAiStart := GetTickCount;
  BtnExecute.Enabled := False;
  BtnSend.Enabled := False;
  SetStatusCaption(TrText('Assistant.Thinking'));
  MemoReply.Clear;
  FLastPlan := Plan;
  FHasPlan := True;
  Body := Plan.UserMessage;
  if SameText(Plan.ActionId, 'consumer_ai') or SameText(Plan.ActionId, 'consumer_rag') then
    BeginAssistantWait(ConsumerWaitCaption(Plan.ActionId));
  ExecMsg := RunPlanWithOptionalConfirm(Plan, Plan.NeedConfirm);
  if ExecMsg <> '' then
  begin
    if Trim(Body) = '' then
      Body := ExecMsg
    else if Pos(ExecMsg, Body) = 0 then
      Body := Body + #13#10#13#10 + ExecMsg;
  end;
  FLastReplyBody := Body;
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, True);
  PipelineRememberAssistant(Body);
  SetStatusCaption(TrText('Assistant.Done'));
  BtnExecute.Enabled := False;
  AssistantWriteLog('local-send: ' + Plan.ActionId);
  MaybeComposeDocAfterCountPrefixes(UserQ, Plan.ActionId, ExecMsg);
  if not (SameText(Plan.ActionId, 'consumer_ai') or SameText(Plan.ActionId, 'consumer_rag')) then
    EndAssistantWait;
  PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
end;

procedure TFastFileAssistantCtrl.BtnSendClick(Sender: TObject);
var
  Th: TFastFileAssistantThread;
  UserQ, BindErr: string;
begin
  if FBusy then Exit;
  UserQ := Trim(MemoQuestion.Text);
  if UserQ = '' then
  begin
    FastFileMessageBox(PChar(TrText('Assistant.Error.EmptyQuestion')), PChar(TrText('Assistant.Title')),
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  { Unsupported dest format: criticize here — never send the question to the LLM. }
  if RejectUnsupportedComposeFormat(UserQ) then
    Exit;
  RememberQuestion(UserQ);
  PipelineRememberUser(UserQ);
  if UserQuestionIsOutOfScopeOrHarmful(UserQ) then
  begin
    FLastReplyBody := TrText('Assistant.Error.OutOfScopeHarmful');
    MemoReply.Lines.Text := FLastReplyBody;
    PipelineRememberAssistant(FLastReplyBody);
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Exit;
  end;
  if Assigned(BtnAgentMode) and BtnAgentMode.Down and AgentBridgeAvailable then
  begin
    StartAgentTask(UserQ);
    Exit;
  end;
  if not TryBindChatQuestionSourceFile(UserQ, BindErr) then
  begin
    FLastReplyBody := BindErr;
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Exit;
  end;
  if ChatQuestionRequiresBoundSourceFile(UserQ) and
     (not ChatHasUsableSourceFile(UserQ)) then
  begin
    FLastReplyBody := TrText('Assistant.Error.NoFileOpen');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Exit;
  end;
  { AI-first: NL always goes to the model. Ctrl/F-key shortcuts may skip it. }
  if TryHandleLocalSendQuery then Exit;
  FBusy := True;
  FHasPlan := False;
  FMsLastAi := 0;
  FMsLastExec := 0;
  FLastReplyBody := '';
  FTickAiStart := GetTickCount;
  BtnExecute.Enabled := False;
  BtnSend.Enabled := False;
  SetStatusCaption(TrText('Assistant.Thinking'));
  BeginAssistantWait(TrText('Assistant.Processing'));
  MemoReply.Clear;
  Th := TFastFileAssistantThread.Create(Self, BuildPromptW);
  Th.Resume;
end;

function TFastFileAssistantCtrl.RunPlanWithOptionalConfirm(const Plan: TAssistantPlan;
  AAskConfirm: Boolean): string;
var
  Msg, UserQ: string;
  T0: Cardinal;
  ExecPlan: TAssistantPlan;
begin
  Result := '';
  FMsLastExec := 0;
  ExecPlan := Plan;
  if ExecPlan.Intent <> aiExecute then Exit;
  UserQ := Trim(MemoQuestion.Text);
  if SameText(ExecPlan.ActionId, AGENT_TASK_ACTION) then
  begin
    if not FBusy then
      StartAgentTask(UserQ);
    Exit;
  end;
  if SameText(ExecPlan.ActionId, 'consumer_rag') or SameText(ExecPlan.ActionId, 'consumer_ai') then
  begin
    ApplyConsumerGate(UserQ, ExecPlan);
    if ExecPlan.Intent <> aiExecute then Exit;
    { Honor AAskConfirm from caller (False = auto-exec / NativeFollowUp, no MessageBox). }
  end;
  AssistantSetExportPreferFile(UserWantsExportToFile(UserQ));
  if AAskConfirm then
  begin
    Msg := ClampAssistantDisplayText(ExecPlan.UserMessage) + #13#10#13#10 + TrText('Assistant.ConfirmRun');
    if FastFileMessageBox(PChar(Msg), PChar(TrText('Assistant.Title')),
      MB_YESNO or MB_ICONQUESTION) <> IDYES then
      Exit;
  end;
  T0 := GetTickCount;
  Result := ExecutePlanOrChain(ExecPlan);
  FMsLastExec := GetTickCount - T0;
end;

procedure TFastFileAssistantCtrl.ApplyAiFinished(const Ok: Boolean; const Ans: WideString; const Err: string);
var
  Plan: TAssistantPlan;
  ValErr, Body, UserQ, ExecMsg, Facts: string;
begin
  if Handle = 0 then Exit;
  FMsLastAi := GetTickCount - FTickAiStart;
  if FAiCancelled then
  begin
    FAiCancelled := False;
    FComposeAwaitingBody := False;
    FComposeDestPath := '';
    FComposeIsFix := False;
    FComposeSourceBody := '';
    FComposeAppendBody := '';
    FComposeAppendFiltered := False;
    FComposeSummarizePhase := False;
    FComposePipelineWord := False;
    EndAssistantWait;
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;

  if FComposeAwaitingBody then
  begin
    FComposeAwaitingBody := False;
    if not Ok then
    begin
      EndAssistantWait;
      SetStatusCaption(TrText('Assistant.Error.ComposeGatewayEmpty'));
      if Err <> '' then
        FLastReplyBody := ClampAssistantDisplayText(
          TrText('Assistant.Error.ComposeGatewayEmpty') + #13#10#13#10 + Err)
      else
        FLastReplyBody := TrText('Assistant.Error.ComposeGatewayEmpty');
      MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
      FComposeDestPath := '';
      FComposeIsFix := False;
      FComposeSourceBody := '';
      FComposeAppendBody := '';
      FComposeAppendFiltered := False;
      FComposeSummarizePhase := False;
      FComposePipelineWord := False;
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
      Exit;
    end;
    if FComposeSummarizePhase then
    begin
      FComposeSummarizePhase := False;
      FinishComposeSummaryThenWrite(string(Ans));
      EndAssistantWait;
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
      Exit;
    end;
    FinishComposeWithBody(string(Ans));
    EndAssistantWait;
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    Exit;
  end;

  if not Ok then
  begin
    EndAssistantWait;
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    SetStatusCaption(TrText('Assistant.Error.Network'));
    if Err <> '' then
      FLastReplyBody := ClampAssistantDisplayText(Err)
    else
      FLastReplyBody := TrText('Assistant.Error.Network');
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    Exit;
  end;
  UserQ := Trim(MemoQuestion.Text);
  if UserQuestionIsOutOfScopeOrHarmful(UserQ) then
  begin
    EndAssistantWait;
    PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    FLastReplyBody := TrText('Assistant.Error.OutOfScopeHarmful');
    MemoReply.Lines.Text := FLastReplyBody;
    SetStatusCaption(TrText('Assistant.ReplyReady'));
    BtnExecute.Enabled := False;
    Exit;
  end;
  Plan := ParseAssistantPlan(Ans);
  ApplyLocalIntentCorrection(UserQ, Plan);
  ApplyConsumerGate(UserQ, Plan);
  SanitizeAssistantUserMessage(Plan);
  ValErr := ValidatePlan(Plan);
  FLastPlan := Plan;
  FHasPlan := True;
  Body := Plan.UserMessage;
  Facts := BuildOpenFileLocalFactsText(UserQ);
  if (Facts <> '') and (Pos(Facts, Body) = 0) then
  begin
    if Trim(Body) = '' then
      Body := Facts
    else
      Body := Facts + #13#10#13#10 + Body;
  end;
  if ValErr <> '' then
    Body := Body + #13#10#13#10 + ValErr;
  FLastReplyBody := Body;
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
  PipelineRememberAssistant(Body);
  AssistantWriteLog('reply intent=' + IntToStr(Ord(Plan.Intent)) + ' chain=' +
    IntToStr(Plan.ChainCount) + ' action=' + Plan.ActionId + ' ai_ms=' + IntToStr(FMsLastAi));

  if SameText(Plan.ActionId, 'compose_document') and (ValErr = '') then
  begin
    if ComposeQuestionNeedsExistingFile(UserQ) and
       ((AssistantComposeSourcePath(UserQ) = '') or
        (not FileExists(AssistantComposeSourcePath(UserQ)))) then
    begin
      EndAssistantWait;
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
      FLastReplyBody := TrText('Assistant.Error.NoFileOpen');
      MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
      SetStatusCaption(TrText('Assistant.ReplyReady'));
      BtnExecute.Enabled := False;
      Exit;
    end;
    if not StartComposeGeneration then
    begin
      EndAssistantWait;
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    end
    else if not FComposeAwaitingBody then
    begin
      EndAssistantWait;
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    end;
    Exit;
  end;

  if SameText(Plan.ActionId, AGENT_TASK_ACTION) and AgentBridgeAvailable then
  begin
    EndAssistantWait;
    { StartAgentTask keeps FBusy until the agent reports back; on failure it clears it. }
    FBusy := False;
    StartAgentTask(UserQ);
    Exit;
  end;

  if ShouldAutoExecutePlan(Plan, UserQ) and (ValErr = '') then
  begin
    { File ops that already show SmoothLoading take over the overlay.
      Count/compose stay on this wait so the UI does not freeze without a bar. }
    if AssistantActionHasOwnSmoothLoading(Plan.ActionId) then
      EndAssistantWait
    else if SameText(Plan.ActionId, 'consumer_ai') or SameText(Plan.ActionId, 'consumer_rag') then
      BeginAssistantWait(ConsumerWaitCaption(Plan.ActionId));
    ExecMsg := RunPlanWithOptionalConfirm(Plan, False);
    if ExecMsg <> '' then
    begin
      { Keep prior facts (e.g. total lines) — never wipe them on export_lines. }
      if Trim(FLastReplyBody) = '' then
        FLastReplyBody := ExecMsg
      else if Pos(ExecMsg, FLastReplyBody) = 0 then
        FLastReplyBody := FLastReplyBody + #13#10#13#10 + ExecMsg;
    end;
    MaybeComposeDocAfterCountPrefixes(UserQ, Plan.ActionId, ExecMsg);
    { After host counts + PDF, never start the AI sample compose pipeline. }
    if SameText(Plan.ActionId, 'count_line_prefixes') or
       SameText(Plan.ActionId, 'count_matching_lines') then
      Plan.NativeFollowUpAction := '';
    { Compound native + PDF/explain: second hop from AI chain / structural format id. }
    if IsNativeFirstHopAction(Plan.ActionId) and (Trim(Plan.NativeFollowUpAction) <> '') then
    begin
      if SameText(Plan.NativeFollowUpAction, 'compose_document') then
      begin
        { Keep AI filter_text + max_lines for host line collect into the PDF. }
        Plan.ActionId := 'compose_document';
        Plan.NeedConfirm := False;
        Plan.NativeFollowUpAction := '';
        FLastPlan := Plan;
        if not StartComposeGeneration then
        begin
          EndAssistantWait;
          PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
        end;
      end
      else if SameText(Plan.NativeFollowUpAction, 'consumer_rag') then
      begin
        Plan.ActionId := 'consumer_rag';
        Plan.FilterText := SanitizeQuestionForConsumerPython(UserQ, True);
        Plan.NeedConfirm := False;
        Plan.NativeFollowUpAction := '';
        if Trim(Plan.Path) = '' then
          Plan.Path := AssistantHostGetOpenFilePath;
        FLastPlan := Plan;
        BeginAssistantWait(ConsumerWaitCaption('consumer_rag'));
        ExecMsg := RunPlanWithOptionalConfirm(Plan, False);
        if ExecMsg <> '' then
          FLastReplyBody := FLastReplyBody + #13#10#13#10 + ExecMsg;
      end;
    end;
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, True);
    if SameText(FLastPlan.ActionId, 'compose_document') and FComposeAwaitingBody then
      SetStatusCaption(TrText('Assistant.Thinking'))
    else
    begin
      SetStatusCaption(TrText('Assistant.Done'));
      EndAssistantWait;
      PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
    end;
    BtnExecute.Enabled := False;
    AssistantWriteLog('auto-execute follow-up: ' + FLastPlan.ActionId);
    Exit;
  end;

  EndAssistantWait;
  PostMessage(Handle, WM_FF_ASSISTANT_RESET_BUSY, 0, 0);
  SetStatusCaption(TrText('Assistant.ReplyReady'));
  BtnExecute.Enabled := PlanNeedsExecuteButton(Plan) and (ValErr = '');
end;

procedure TFastFileAssistantCtrl.BtnExecuteClick(Sender: TObject);
var
  Plan: TAssistantPlan;
  ValErr, ExecMsg: string;
begin
  if not FHasPlan then Exit;
  Plan := FLastPlan;
  ApplyConsumerGate(Trim(MemoQuestion.Text), Plan);
  FLastPlan := Plan;
  if Plan.Intent <> aiExecute then
  begin
    FLastReplyBody := Plan.UserMessage;
    MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, False);
    BtnExecute.Enabled := False;
    Exit;
  end;
  ValErr := ValidatePlan(Plan);
  if ValErr <> '' then
  begin
    FastFileMessageBox(PChar(ValErr), PChar(TrText('Assistant.Title')), MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if Plan.Intent <> aiExecute then Exit;
  if SameText(Plan.ActionId, 'compose_document') then
  begin
    if FBusy then Exit;
    if not StartComposeGeneration then
      EndAssistantWait;
    Exit;
  end;
  if UserQuestionIsOutOfScopeOrHarmful(Trim(MemoQuestion.Text)) then
  begin
    FastFileMessageBox(PChar(TrText('Assistant.Error.OutOfScopeHarmful')),
      PChar(TrText('Assistant.Title')), MB_OK or MB_ICONWARNING);
    Exit;
  end;

  if SameText(Plan.ActionId, 'consumer_ai') or SameText(Plan.ActionId, 'consumer_rag') then
    BeginAssistantWait(ConsumerWaitCaption(Plan.ActionId));
  ExecMsg := RunPlanWithOptionalConfirm(Plan, True);
  if ExecMsg = '' then Exit;
  if Trim(FLastReplyBody) = '' then
    FLastReplyBody := ExecMsg
  else if Pos(ExecMsg, FLastReplyBody) = 0 then
    FLastReplyBody := FLastReplyBody + #13#10#13#10 + ExecMsg;
  MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, True);
  SetStatusCaption(TrText('Assistant.Done'));
  BtnExecute.Enabled := False;
  AssistantWriteLog('execute: ' + Plan.ActionId);
  MaybeComposeDocAfterCountPrefixes(Trim(MemoQuestion.Text), Plan.ActionId, ExecMsg);
  if SameText(Plan.ActionId, 'count_line_prefixes') or
     SameText(Plan.ActionId, 'count_matching_lines') then
    Plan.NativeFollowUpAction := '';
  if IsNativeFirstHopAction(Plan.ActionId) and (Trim(Plan.NativeFollowUpAction) <> '') then
  begin
    if SameText(Plan.NativeFollowUpAction, 'compose_document') then
    begin
      Plan.ActionId := 'compose_document';
      Plan.NeedConfirm := False;
      Plan.NativeFollowUpAction := '';
      FLastPlan := Plan;
      StartComposeGeneration;
    end
    else if SameText(Plan.NativeFollowUpAction, 'consumer_rag') then
    begin
      Plan.ActionId := 'consumer_rag';
      Plan.FilterText := SanitizeQuestionForConsumerPython(Trim(MemoQuestion.Text), True);
      Plan.NeedConfirm := False;
      Plan.NativeFollowUpAction := '';
      if Trim(Plan.Path) = '' then
        Plan.Path := AssistantHostGetOpenFilePath;
        FLastPlan := Plan;
        BeginAssistantWait(ConsumerWaitCaption('consumer_rag'));
        ExecMsg := RunPlanWithOptionalConfirm(Plan, True);
        if ExecMsg <> '' then
        begin
          FLastReplyBody := FLastReplyBody + #13#10#13#10 + ExecMsg;
          MemoReply.Lines.Text := BuildReplyWithTiming(FLastReplyBody, True);
        end;
    end;
  end;
end;

procedure CreateFastFileAssistantUI(AOwner: TComponent; AHostPanel: TWinControl);
begin
  GAssistantHostPanel := AHostPanel;
  if not Assigned(AHostPanel) then Exit;
  if Assigned(GAssistantCtrl) then Exit;
  if AHostPanel is TsPanel then
  begin
    try
      TsPanel(AHostPanel).SkinData.CustomColor := True;
      TsPanel(AHostPanel).SkinData.SkinSection := '';
    except
    end;
    TsPanel(AHostPanel).ParentBackground := False;
    TsPanel(AHostPanel).ParentColor := False;
    TsPanel(AHostPanel).Color := ASSISTANT_TOOLBAR_MID;
  end;
  GAssistantCtrl := TFastFileAssistantCtrl.Create(AOwner);
  GAssistantCtrl.FHostPanel := AHostPanel;
  GAssistantCtrl.FIniPath := ExtractFilePath(Application.ExeName) + ASKIN_INI;
  PipelineSetStoragePath(GAssistantCtrl.FIniPath);
  PipelineLoad;
  GAssistantCtrl.Parent := AHostPanel;
  GAssistantCtrl.Align := alClient;
  GAssistantCtrl.Visible := True;
  GAssistantCtrl.BringToFront;
  GAssistantCtrl.BuildFormLayout;
  GAssistantCtrl.ApplyAssistantSoftChrome;
end;

procedure ShowFastFileAssistantPanel;
var
  HostForm: TCustomForm;
begin
  if not Assigned(GAssistantHostPanel) then Exit;
  if not Assigned(GAssistantCtrl) then
    CreateFastFileAssistantUI(Application.MainForm, GAssistantHostPanel);
  if GAssistantHostPanel is TsPanel then
  begin
    try
      TsPanel(GAssistantHostPanel).SkinData.CustomColor := True;
    except
    end;
    TsPanel(GAssistantHostPanel).Color := ASSISTANT_TOOLBAR_MID;
  end;
  GAssistantHostPanel.Visible := True;
  GAssistantHostPanel.BringToFront;
  HostForm := HostFormOf(GAssistantHostPanel);
  if Assigned(HostForm) and (HostForm <> Application.MainForm) then
  begin
    HostForm.Show;
    HostForm.BringToFront;
  end;
  AssistantHostNotifyPanelVisible(True);
  if (GAssistantHostPanel.Parent is TForm) then
    TForm(GAssistantHostPanel.Parent).Realign
  else if Assigned(GAssistantHostPanel.Parent) then
    GAssistantHostPanel.Parent.Realign;
  if Assigned(GAssistantCtrl) then
  begin
    GAssistantCtrl.Visible := True;
    GAssistantCtrl.BringToFront;
    GAssistantCtrl.SyncDontShowStartupCheckbox;
    GAssistantCtrl.ApplyAssistantUiTexts;
    GAssistantCtrl.ApplyAssistantSoftChrome;
    GAssistantCtrl.LayoutInputControls(nil);
    GAssistantCtrl.RequestInputFocus;
    if Assigned(Application.MainForm) then
    begin
      PostMessage(Application.MainForm.Handle, WM_USER + 432, 0, 0);
      PostMessage(Application.MainForm.Handle, WM_FF_IDLE_LOGO_LAYOUT, 0, 0);
    end;
  end;
end;

procedure AssistantPrefillQuestion(const AText: string);
begin
  ShowFastFileAssistantPanel;
  if not Assigned(GAssistantCtrl) or not Assigned(GAssistantCtrl.MemoQuestion) then Exit;
  GAssistantCtrl.MemoQuestion.Text := AText;
  GAssistantCtrl.ClampQuestionToMaxChars;
  GAssistantCtrl.UpdateClearQuestionBtn;
  GAssistantCtrl.UpdateQuestionCharCount;
  GAssistantCtrl.RequestInputFocus;
end;

procedure AssistantSubmitQuestion;
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.BtnSendClick(nil);
end;

procedure NotifyAssistantGeneratedFile(const AFileName: string);
begin
  if Trim(AFileName) = '' then Exit;
  if not Assigned(GAssistantCtrl) then Exit;
  if not FastFileAssistantPanelVisible then Exit;
  GAssistantCtrl.ShowGeneratedFileNotice(AFileName);
end;

procedure NotifyAssistantOfferNext(const ASummary, AActionIdsCsv: string);
begin
  NotifyAssistantOfferNext(ASummary, AActionIdsCsv, '');
end;

procedure NotifyAssistantOfferNext(const ASummary, AActionIdsCsv, AAiDraft: string);
begin
  if Trim(AActionIdsCsv) = '' then Exit;
  if not Assigned(GAssistantCtrl) then
  begin
    if not Assigned(GAssistantHostPanel) then Exit;
    CreateFastFileAssistantUI(Application.MainForm, GAssistantHostPanel);
  end;
  if not FastFileAssistantPanelVisible then
    ShowFastFileAssistantPanel;
  if Assigned(GAssistantCtrl) then
    GAssistantCtrl.ShowOfferNext(ASummary, AActionIdsCsv, AAiDraft);
end;

procedure TFastFileAssistantCtrl.ReceiveDelegatedReply(const AText: string; AAppend: Boolean);
var
  S: string;
begin
  EndAssistantWait;
  S := Trim(AText);
  if S = '' then Exit;
  if not Assigned(MemoReply) then Exit;
  if AAppend and (Trim(MemoReply.Text) <> '') then
  begin
    if (MemoReply.Text <> '') and (MemoReply.Text[Length(MemoReply.Text)] <> #10) then
      MemoReply.Lines.Add('');
    MemoReply.Lines.Add(S);
  end
  else
    MemoReply.Lines.Text := S;
  FLastReplyBody := MemoReply.Text;
  PipelineRememberAssistant(S);
  MemoReply.SelStart := Length(MemoReply.Text);
  MemoReply.SelLength := 0;
  SyncMemoAutoVertScroll(MemoReply);
end;

procedure TFastFileAssistantCtrl.ReceiveDelegatedStatus(const AStatus: string);
begin
  SetStatusCaption(AStatus);
  if FWaitOverlayOwned then
    UpdateAssistantWait(AStatus)
  else if SameText(AStatus, TrText('Assistant.Status.DelegatingSQL')) or
          SameText(AStatus, TrText('Assistant.Status.DelegatingRAG')) then
    BeginAssistantWait(AStatus);
end;

procedure NotifyAssistantDelegatedReply(const AText: string; AAppend: Boolean);
begin
  if Trim(AText) = '' then Exit;
  if not Assigned(GAssistantCtrl) then
  begin
    if not Assigned(GAssistantHostPanel) then Exit;
    CreateFastFileAssistantUI(Application.MainForm, GAssistantHostPanel);
  end;
  if not FastFileAssistantPanelVisible then
    ShowFastFileAssistantPanel;
  if Assigned(GAssistantCtrl) then
    GAssistantCtrl.ReceiveDelegatedReply(AText, AAppend);
end;

procedure NotifyAssistantDelegatedStatus(const AStatus: string);
begin
  if Trim(AStatus) = '' then Exit;
  if not Assigned(GAssistantCtrl) then Exit;
  if not FastFileAssistantPanelVisible then
    ShowFastFileAssistantPanel;
  GAssistantCtrl.ReceiveDelegatedStatus(AStatus);
end;

procedure AssistantComposeSavedDocumentFromText(const AQuestion, ABody: string);
begin
  if Trim(ABody) = '' then Exit;
  if not Assigned(GAssistantCtrl) then Exit;
  ShowFastFileAssistantPanel;
  GAssistantCtrl.ComposeSavedDocumentFromText(AQuestion, ABody);
end;

procedure HideFastFileAssistantPanel;
var
  HostForm: TCustomForm;
begin
  if Assigned(GAssistantCtrl) then
  begin
    GAssistantCtrl.PersistStartupPreference;
    GAssistantCtrl.SaveAssistantInputHeight;
  end;
  if Assigned(GAssistantHostPanel) then
  begin
    AssistantHostNotifyPanelVisible(False);
    HostForm := HostFormOf(GAssistantHostPanel);
    if Assigned(HostForm) and (HostForm <> Application.MainForm) then
      HostForm.Hide
    else
    begin
      GAssistantHostPanel.Visible := False;
      if (GAssistantHostPanel.Parent is TForm) then
        TForm(GAssistantHostPanel.Parent).Realign
      else if Assigned(GAssistantHostPanel.Parent) then
        GAssistantHostPanel.Parent.Realign;
    end;
    if Assigned(Application.MainForm) then
      PostMessage(Application.MainForm.Handle, WM_FF_IDLE_LOGO_LAYOUT, 0, 0);
  end;
end;

procedure ToggleFastFileAssistantPanel;
begin
  if FastFileAssistantPanelVisible then
    HideFastFileAssistantPanel
  else
    ShowFastFileAssistantPanel;
end;

function FastFileAssistantPanelVisible: Boolean;
var
  HostForm: TCustomForm;
begin
  Result := Assigned(GAssistantHostPanel) and GAssistantHostPanel.Visible;
  if not Result then Exit;
  HostForm := HostFormOf(GAssistantHostPanel);
  if Assigned(HostForm) and (HostForm <> Application.MainForm) then
    Result := HostForm.Visible;
end;

function FastFileAssistantFocusInPanel(const AFocusHwnd: HWND): Boolean;
begin
  Result := False;
  if not Assigned(GAssistantCtrl) or not GAssistantCtrl.Visible then Exit;
  if AFocusHwnd = 0 then Exit;
  if AFocusHwnd = GAssistantCtrl.Handle then
  begin
    Result := True;
    Exit;
  end;
  Result := IsChild(GAssistantCtrl.Handle, AFocusHwnd);
end;

function TFastFileAssistantCtrl.HandleShortcut(var Key: Word; Shift: TShiftState): Boolean;
begin
  Result := AssistantHandleShortcut(Key, Shift);
end;

function FastFileAssistantHandleShortcut(var Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
  if Assigned(GAssistantCtrl) then
    Result := GAssistantCtrl.HandleShortcut(Key, Shift);
end;

function FastFileAssistantHandleEnter(var Key: Word; Shift: TShiftState): Boolean;
begin
  Result := False;
  if Assigned(GAssistantCtrl) then
    Result := GAssistantCtrl.HandleEnterKey(Key, Shift);
end;

function ShouldShowAssistantOnStartup(const AIniPath: string): Boolean;
var
  Ini: TIniFile;
begin
  Result := True;
  if not FileExists(AIniPath) then Exit;
  Ini := TIniFile.Create(AIniPath);
  try
    Result := Ini.ReadInteger(APPLICATION_NAME, ASSISTANT_INI_KEY, 1) <> 0;
  finally
    Ini.Free;
  end;
end;

procedure SaveAssistantShowOnStartup(const AIniPath: string; AShow: Boolean);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AIniPath);
  try
    if AShow then
      Ini.WriteInteger(APPLICATION_NAME, ASSISTANT_INI_KEY, 1)
    else
      Ini.WriteInteger(APPLICATION_NAME, ASSISTANT_INI_KEY, 0);
  finally
    Ini.Free;
  end;
end;

procedure RetranslateFastFileAssistant(OldLang: TAppLanguage);
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.RetranslateRuntimeTexts(OldLang);
end;

procedure RefreshFastFileAssistantSurface;
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.ApplyAssistantUiTexts;
  GAssistantCtrl.BuildMemoPopupMenus;
  GAssistantCtrl.RefreshAssistantSurfaceColor;
  if Assigned(GAssistantCtrl.PnlInput) then
    GAssistantCtrl.LayoutInputControls(nil);
end;

procedure SetFastFileAssistantMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.SetMruFindGlyphs(AImages, AFindIndex);
end;

procedure SetFastFileAssistantOnFloat(AHandler: TNotifyEvent);
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.FOnFloatClick := AHandler;
end;

procedure SetFastFileAssistantOnTearOff(AHandler: TNotifyEvent);
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.FOnTearOff := AHandler;
end;

procedure SetFastFileAssistantOnPython(AHandler: TNotifyEvent);
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.FOnPythonClick := AHandler;
end;

procedure SetFastFileAssistantFloatingState(AFloating: Boolean);
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.FFloating := AFloating;
  GAssistantCtrl.ApplyAssistantUiTexts;
end;

procedure RelayoutFastFileAssistantAfterDock;
begin
  if not Assigned(GAssistantCtrl) then Exit;
  GAssistantCtrl.Align := alClient;
  GAssistantCtrl.RestoreDockedStack;
  GAssistantCtrl.ApplyAssistantUiTexts;
end;

procedure PersistAssistantLayout;
begin
  if Assigned(GAssistantCtrl) then
    GAssistantCtrl.SaveAssistantInputHeight;
end;

end.
