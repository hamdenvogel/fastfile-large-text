unit uAgentWorkspace;

{
  Embedded AI-agent workspace: pick files or folders, set scan options,
  send a prompt, review proposed changes and write them through the core
  engines (Compare/merge for lines, uAnonymize for anonymize).
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Contnrs, ExtCtrls, StdCtrls, Menus,
  sPanel, sLabel, sButton, sEdit, sMemo, sListBox, sCheckbox, sSplitter, sGroupBox, sPageControl,
  sSpeedButton, uAgentPrefs, uAgentTools, uAgentPatch;

type
  TAgentPathProc = procedure(const APath: string) of object;
  TAgentPathFunc = function: string of object;
  TAgentPathCheck = function(const APath: string): Boolean of object;
  TAgentActionProc = procedure(const AActionId, APath: string) of object;

  TfrmAgentWorkspace = class(TForm)
  private
    procedure WMAgentStatus(var Msg: TMessage); message WM_APP + 40;
    procedure WMAgentEdit(var Msg: TMessage); message WM_APP + 41;
    procedure WMAgentDone(var Msg: TMessage); message WM_APP + 42;
    procedure WMAgentFiles(var Msg: TMessage); message WM_APP + 43;
    procedure WMAgentMerge(var Msg: TMessage); message WM_APP + 44;
    procedure WMRecentPopup(var Msg: TMessage); message WM_APP + 45;
    procedure WMAgentRunAfter(var Msg: TMessage); message WM_APP + 46;
    procedure WMAgentPreview(var Msg: TMessage); message WM_APP + 48;
    procedure WMAskDone(var Msg: TMessage); message WM_APP + 47;
    procedure ToolNewClick(Sender: TObject);
    procedure ToolClearClick(Sender: TObject);
    procedure ToolCopyClick(Sender: TObject);
    procedure ToolAskClick(Sender: TObject);
    procedure LastFileClick(Sender: TObject);
    procedure LastFileChanged(Sender: TObject);
    function ToolAreaText(ATag: Integer; ASelectionOnly: Boolean): string;
    procedure AskAiAbout(const AContent, AWhat, AQuestion: string);
    procedure StartAiJob(const APrompt: string; AJob: Integer);
    procedure PromptTranslateClick(Sender: TObject);
    procedure PromptTranslateLangClick(Sender: TObject);
    procedure PromptSuggestClick(Sender: TObject);
    procedure StartPromptTextJob(AJob: Integer; const ALangName: string);
    procedure BeginWait(AKind: Integer; const AMsg, ADetail: string);
    procedure UpdateWaitDetail(const ADetail: string);
    procedure EndWait;
    procedure WaitTimer(Sender: TObject);
    procedure SizeToolButtons;
    procedure RunCoreActions(AList: TObjectList);
    procedure AcceptAction(AIndex: Integer);
    procedure RecentComboClick(Sender: TObject);
    procedure OpenRecentPopup;
    procedure RecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure RecentRemove(Sender: TObject; const AValue: string);
    procedure RecentClearAll(Sender: TObject);
    procedure RefreshRecentCombo;
    procedure StartRun(ARoots: TStringList);
    procedure WMRootRecentPopup(var Msg: TMessage); message WM_APP + 49;
    procedure RootRecentClick(Sender: TObject);
    procedure OpenRootRecentPopup;
    procedure RootRecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure RootRecentRemove(Sender: TObject; const AValue: string);
    procedure RootRecentProps(Sender: TObject; const AValue: string);
    procedure RootRecentClearAll(Sender: TObject);
    procedure RefreshRootRecentButton;
    procedure FlushRootRecent;
    procedure PromptKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AddFilesClick(Sender: TObject);
    procedure AddFolderClick(Sender: TObject);
    procedure OpenFileClick(Sender: TObject);
    procedure RemoveClick(Sender: TObject);
    procedure RemoveAllClick(Sender: TObject);
    procedure SelectAllRootsClick(Sender: TObject);
    procedure CopyRootsClick(Sender: TObject);
    procedure RootFindChange(Sender: TObject);
    procedure RootFindClearClick(Sender: TObject);
    procedure RootFindBoxClick(Sender: TObject);
    procedure RootFindBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure RootFindLayout(Sender: TObject);
    function Dpi(AValue: Integer): Integer;
    function TextPx(AFont: TFont; const S: string): Integer;
    function WrapPx(AFont: TFont; const S: string; AWidth: Integer): Integer;
    function RecentComboNeed: Integer;
    function SourceButtonNeed: Integer;
    procedure FitWrapped;
    procedure GuidePaint(Sender: TObject);
    function GuideHeight(ACompact: Boolean): Integer;
    procedure SetGuideFont(AFont: TFont; ACompact: Boolean);
    { Short screens: hide or fold secondary parts, level by level, until the lists and memos keep a usable height. }
    procedure FitHeights;
    procedure SetCompact(ALevel: Integer);
    procedure OptionsLinkClick(Sender: TObject);
    procedure OptionsPopupClose(Sender: TObject; var Action: TCloseAction);
    procedure OptionsPopupDeactivate(Sender: TObject);
    procedure MaskChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RootFindClearEnter(Sender: TObject);
    procedure RootFindClearLeave(Sender: TObject);
    procedure RootFindFocusChange(Sender: TObject);
    procedure RootFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RootsMenuPopup(Sender: TObject);
    procedure RefreshRootList;
    procedure LoadSession;
    procedure SaveSession;
    procedure SendClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure AcceptClick(Sender: TObject);
    procedure RejectClick(Sender: TObject);
    procedure AcceptAllClick(Sender: TObject);
    procedure EditsClick(Sender: TObject);
    procedure ThreadDone(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BuildUi;
    procedure LoadOptions;
    procedure StoreOptions;
    function ReadOptions: TAgentPrefs;
    procedure SetBusy(ABusy: Boolean);
    procedure PromptChange(Sender: TObject);
    procedure AddRoot(AKind: TAgentRootKind; const APath: string);
    procedure ClearRoots;
    function SelectedEdit: TAgentEdit;
    function EditCaption(E: TAgentEdit): string;
    procedure RefreshEditCaptions;
    procedure RemoveEditAt(AIndex: Integer);
    procedure ShowPreview;
    procedure PvAdd(AKind: Integer; const AGutter, AText: string);
    procedure FillPreview(AList: TListBox);
    procedure PreviewDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure PreviewPaneResize(Sender: TObject);
    procedure PreviewClick(Sender: TObject);
    procedure PreviewZoom(Sender: TObject);
    procedure ZoomResize(Sender: TObject);
    { "See full text" / "Copy" for texts that may not fit (note, edit list, preview). }
    procedure ShowFullText(const ATitle, AText: string);
    function FullTextOf(AComp: TComponent): string;
    procedure FullTextClick(Sender: TObject);
    procedure FullTextCopyClick(Sender: TObject);
    procedure FullTextViewClick(Sender: TObject);
    procedure EditsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure EditsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure AcceptOne(AIndex: Integer);
    procedure StartApply(AJobs: TObjectList; ASingle: TAgentEdit);
    procedure FileApplied(const APath: string; AOk: Boolean; const R: TAgentApplyResult;
      ASingle: TAgentEdit; ASingleClone: TAgentEdit);
    function IndexPathFor(const APath: string): string;
    function ApplyErrorText(const R: TAgentApplyResult): string;
    procedure SourceButtonsResize(Sender: TObject);
    procedure UpdateResultTabs;
    { Buttons that act on items are enabled only while there is something to act on. }
    procedure UpdateEditButtons;
    procedure UpdateToolButtons;
    procedure AnswerChange(Sender: TObject);
    { Proposed edits wait PrefAgentDecisionSeconds for a decision, then are discarded. }
    procedure DecisionTimer(Sender: TObject);
    procedure RestartDecision;
    procedure StopDecision;
    procedure HoldDecision;
    procedure ReleaseDecision;
    procedure UpdateDecisionLabel;
    procedure ExpireEdits;
    procedure ExpirePaint(Sender: TObject);
    function DecisionSecondsLeft: Integer;
  public
    pnlTop: TsPanel;
    lblGuide: TsLabel;
    pbGuide: TPaintBox;
    pnlCountRow: TsPanel;
    lblOptLink: TLabel;
    FOptPopup: TForm;
    FPromptHost: TWinControl;
    FStatusBar: TsPanel;
    FCompact: Integer;
    FGuideCompact: Boolean;
    FFitting: Boolean;
    FRecentRowH: Integer;
    FRecentPad: TRect;
    FOptH: Integer;
    pnlLeft: TsPanel;
    pnlClient: TsPanel;
    pnlSourceBtns: TsPanel;
    pnlSendBar: TsPanel;
    pnlActions: TsPanel;
    splLeft: TsSplitter;
    grpSources: TsGroupBox;
    lstRoots: TsListBox;
    FRoots: TObjectList;
    pnlRootFind: TsPanel;
    shpFind: TShape;
    lblFindGlyph: TLabel;
    edtRootFind: TEdit;
    btnRootFindClear: TLabel;
    { Recent sources (MRU popup: find, remove, properties, delete all). }
    btnRootRecent: TsButton;
    FRootRecent: TStringList;
    FRootRecentDirty: Boolean;
    FRootRecentPosted: Boolean;
    FRestoringSession: Boolean;
    { The current run (and its proposals) came from the Assistant panel: report through uAgentBridge. }
    FExternal: Boolean;
    lblRootCount: TLabel;
    btnRemoveAll: TsButton;
    btnSelectAll: TsButton;
    mnuRoots: TPopupMenu;
    miRootRemove: TMenuItem;
    miRootSelectAll: TMenuItem;
    miRootCopy: TMenuItem;
    miRootRemoveAll: TMenuItem;
    FLoadingSession: Boolean;
    grpResults: TsGroupBox;
    pgResults: TsPageControl;
    tabAnswer: TsTabSheet;
    tabRevised: TsTabSheet;
    tabEdits: TsTabSheet;
    tabIncluded: TsTabSheet;
    lblEditsNote: TsLabel;
    lblSendHint: TsLabel;
    lstIncluded: TsListBox;
    grpOptions: TsGroupBox;
    chkSubdirs: TsCheckBox;
    lblMask: TsLabel;
    edtMask: TsEdit;
    lblDepth: TsLabel;
    edtDepth: TsEdit;
    lblMaxFiles: TsLabel;
    edtMaxFiles: TsEdit;
    grpPrompt: TsGroupBox;
    pnlRecentRow: TsPanel;
    lblRecent: TsLabel;
    pnlRecentCombo: TPanel;
    lblRecentCombo: TLabel;
    lblRecentArrow: TLabel;
    FRecent: TStringList;
    FRecentPosted: Boolean;
    memPrompt: TsMemo;
    memAnswer: TsMemo;
    memRevised: TsMemo;
    lstEdits: TsListBox;
    { Owner-drawn, word-wrapped diff of the selected edit; FPreviewRows keeps the unwrapped rows. }
    lstPreview: TListBox;
    FPreviewRows: TStringList;
    { Preview reads run on a worker (a line deep in a huge unindexed file means a long scan). }
    FPreviewLink: TObject;
    FPreviewLinkRef: IInterface;
    FPreviewGen: Integer;
    mnuFullText: TPopupMenu;
    miFullView: TMenuItem;
    miFullCopy: TMenuItem;
    FHintItem: Integer;
    EditsTop: TsPanel;
    PreviewPane: TsPanel;
    splEdits: TsSplitter;
    lblStatus: TsLabel;
    btnAddFiles: TsButton;
    btnAddFolder: TsButton;
    btnOpenFile: TsButton;
    btnRemove: TsButton;
    btnSend: TsButton;
    btnStop: TsButton;
    btnAccept: TsButton;
    btnReject: TsButton;
    btnAcceptAll: TsButton;
    { Countdown badge: pill with a stopwatch whose filled sector is the time left. }
    pbExpire: TPaintBox;
    FExpireText: string;
    tmrDecision: TTimer;
    FDecisionLeftMs: Integer;
    FDecisionTotalMs: Integer;
    FDecisionTick: Cardinal;
    { > 0 while a confirmation is open: the countdown pauses. }
    FDecisionHold: Integer;
    FDecisionExpired: Boolean;
    FZoomForm: TForm;
    FZoomCaption: string;
    FEdits: TObjectList;
    { View-only core actions requested by the agent; run when the answer arrives. }
    FRunAfter: TObjectList;
    FCancel: Integer;
    FThread: TObject;
    { Shared with the request thread, which can outlive the form (the gateway call cannot be interrupted). }
    FLink: TObject;
    FLinkRef: IInterface;
    FApplyRunning: Boolean;
    { "Ask the AI" toolbar buttons (Tag 1 = prompt, 2 = sources, 3 = answer). }
    btnPromptNew, btnPromptClear, btnPromptCopy, btnPromptAsk: TsSpeedButton;
    btnRootsNew, btnRootsClear, btnRootsCopy, btnRootsAsk: TsSpeedButton;
    btnAnswerNew, btnAnswerClear, btnAnswerCopy, btnAnswerAsk: TsSpeedButton;
    btnPromptTranslate, btnPromptSuggest: TsSpeedButton;
    btnAnswerLastFile: TsSpeedButton;
    mnuTranslate: TPopupMenu;
    FAskLink: TObject;
    FAskLinkRef: IInterface;
    FAskBusy: Boolean;
    { 0 = question (reply goes to Answer), 1 = translate, 2 = suggest (reply replaces the prompt). }
    FAskJob: Integer;
    FAskReplaceSel: Boolean;
    { Smooth-loading overlay owned by this tab. FWaitKind: 1 = agent run, 2 = AI text job, 3 = apply. }
    tmrWait: TTimer;
    FWaitOwned: Boolean;
    FWaitKind: Integer;
    FBusy: Boolean;
    FApplyTarget: string;
    FApplyReleased: Boolean;
    FAppliedFiles: Integer;
    FDropped: Integer;
    FMissing: Integer;
    FOpenPath: string;
    FIndexPath: string;
    OnGetOpenFile: TAgentPathFunc;
    OnReleaseFile: TAgentPathProc;
    OnRefreshFile: TAgentPathProc;
    OnHistoryTouched: TAgentPathProc;
    { Return False to block a write to APath (unsaved edits, undo running...). }
    OnBeforeWrite: TAgentPathCheck;
    { Core features outside the Assistant catalog (new file, preferences...). }
    OnRunExtraAction: TAgentActionProc;
    procedure ApplyLanguage;
    { Re-measure captions and row heights (language, font or UI scale changed). }
    procedure FitTexts;
    { Requests from the Assistant panel (uAgentBridge): run on one file, then accept / reject / stop. }
    function RunExternal(const APrompt, APath: string; out AWhy: string): Boolean;
    procedure AcceptAllExternal;
    procedure RejectAllExternal;
    procedure StopExternal;
    procedure ShowEditsPage;
    { True while accepted edits are being written: closing now could leave a file half written. }
    function IsApplying: Boolean;
    class function ExecuteEmbedded(AOwner: TComponent; AHost: TWinControl): TfrmAgentWorkspace;
  end;

implementation

uses
  Types, Dialogs, FileCtrl, Math, ShellAPI, Generics.Collections, Clipbrd,
  StrUtils, uI18n, uAgentLoop, uFastFileMsgDlg, uLineDiffCore, uFastFilePaths,
  uCompareMergeUI, uMergeApply, UnitPopupMruList, uMruFind, uAgentActions, uFastFileAssistantHost,
  uFastFileAIClient, uAgentProtocol, uFastFileAssistant, uSmoothLoading, sSkinProvider, GraphUtil, uAnonymize,
  uExportDoneDlg, uAgentBridge, uUserPrefs;

const
  WM_AGENT_STATUS = WM_APP + 40;
  WM_AGENT_EDIT = WM_APP + 41;
  WM_AGENT_DONE = WM_APP + 42;
  WM_AGENT_FILES = WM_APP + 43;
  WM_AGENT_MERGE = WM_APP + 44;
  WM_AGENT_RUNAFTER = WM_APP + 46;
  WM_AGENT_ASKDONE = WM_APP + 47;
  WM_AGENT_PREVIEW = WM_APP + 48;
  TOOLBAR_MID = $00EFEAE7;
  TOOLBAR_EDGE = $00DED7D4;
  ASK_MAX_CONTENT = 15000;
  PREVIEW_LINES = 80;
  FIND_BORDER = $00C8C0B8;
  FIND_BORDER_FOCUS = $00D77800;
  { Guide banner (BGR): light blue to lavender, blue accent, navy text. }
  GUIDE_FROM = $00FCEBDC;
  GUIDE_TO = $00FDEBF0;
  GUIDE_EDGE = $00F0D4BE;
  GUIDE_ACCENT = $00D77800;
  GUIDE_TEXT = $00603A1E;

type
  TFrameAccess = class(TWinControl);

  TAgentNote = class
  public
    Text: string;
    Revised: string;
    Err: string;
    Edit: TAgentEdit;
    Files: TStringList;
    destructor Destroy; override;
  end;

  { Wnd = 0 once the form is gone; notes posted after that are freed instead of delivered. }
  TAgentLink = class(TInterfacedObject)
  public
    Wnd: HWND;
    Cancel: Integer;
  end;

  TAgentPoster = class(TAgentLoopClient)
  public
    Link: TAgentLink;
    procedure Status(const AText: string); override;
    procedure QueueEdit(AEdit: TAgentEdit); override;
    procedure RunAfter(AEdit: TAgentEdit); override;
  end;

  TAgentWorkThread = class(TThread)
  public
    Link: TAgentLink;
    LinkRef: IInterface;
    Roots: TStringList;
    Prompt: string;
    Prefs: TAgentPrefs;
    ScanFmt: string;
    procedure Execute; override;
  private
    procedure ScanTick(AListed: Integer; var ACancel: Boolean);
  end;

destructor TAgentNote.Destroy;
begin
  Edit.Free;
  Files.Free;
  inherited;
end;

{ Windows edit controls only break lines on CR LF; model text usually has bare LF. }
function MemoText(const S: string): string;
begin
  Result := AdjustLineBreaks(S, tlbsCRLF);
end;

{ Anonymize options in the UI language (AnonInfo is the English text sent to the model). }
function AnonOptionsText(const A: TAnonOptions): string;
var
  S: string;

  procedure Add(const AText: string);
  begin
    if S <> '' then
      S := S + '; ';
    S := S + AText;
  end;

begin
  S := '';
  if A.Numbers then
    Add(TrText('Anon.Numbers'));
  if A.Dates then
    Add(TrText('Anon.Dates'));
  if A.Emails then
    Add(TrText('Anon.Emails'));
  if A.Codes then
    Add(TrText('Anon.Codes'));
  case A.TextMode of
    atmNames: Add(TrText('Anon.Words.Names'));
    atmAllWords: Add(TrText('Anon.Words.All'));
  end;
  if A.Columns <> '' then
    Add(TrText('Anon.Columns') + ' ' + A.Columns);
  Result := S;
end;

{ Provider rejections where the model tried a native function call (HTTP 400 tool_use_failed). }
function FriendlyAiError(const AErr: string): string;
begin
  if (AErr = 'model_tool_call') or (Pos('tool_use_failed', AErr) > 0) or
    (Pos('Tool choice is none', AErr) > 0) then
    Result := TrText('Agent.ModelToolCall')
  else if (Pos('"resposta"', AErr) > 0) then
    Result := TrText('Agent.AskNoAnswer')
  else if AErr = 'no client' then
    Result := TrText('Assistant.Error.Network')
  else if StartsText('HTTP ', AErr) or StartsText('Internet', AErr) or StartsText('HttpOpenRequest', AErr) or
    StartsText('HttpSendRequest', AErr) or (Pos('gzip', AErr) > 0) or (Pos('UTF-8', AErr) > 0) then
    Result := TrText('Assistant.Error.Network') + ' (' + AErr + ')'
  else
    Result := AErr;
end;

procedure PostNote(AWnd: HWND; AMsg: Cardinal; ANote: TAgentNote);
begin
  if AWnd = 0 then
    ANote.Free
  else if not PostMessage(AWnd, AMsg, 0, LPARAM(ANote)) then
    ANote.Free;
end;

procedure TAgentPoster.Status(const AText: string);
var
  N: TAgentNote;
begin
  N := TAgentNote.Create;
  N.Text := AText;
  PostNote(Link.Wnd, WM_AGENT_STATUS, N);
end;

procedure TAgentPoster.QueueEdit(AEdit: TAgentEdit);
var
  N: TAgentNote;
begin
  N := TAgentNote.Create;
  N.Edit := AEdit;
  PostNote(Link.Wnd, WM_AGENT_EDIT, N);
end;

procedure TAgentPoster.RunAfter(AEdit: TAgentEdit);
var
  N: TAgentNote;
begin
  N := TAgentNote.Create;
  N.Edit := AEdit;
  PostNote(Link.Wnd, WM_AGENT_RUNAFTER, N);
end;

procedure TAgentWorkThread.ScanTick(AListed: Integer; var ACancel: Boolean);
var
  N: TAgentNote;
begin
  ACancel := Link.Cancel <> 0;
  N := TAgentNote.Create;
  N.Text := 'scan:' + Format(ScanFmt, [AListed]);
  PostNote(Link.Wnd, WM_AGENT_STATUS, N);
end;

procedure TAgentWorkThread.Execute;
var
  Files: TStringList;
  Poster: TAgentPoster;
  Note: TAgentNote;
  Ans, Rev, Err: string;
  I: Integer;
begin
  Files := TStringList.Create;
  Poster := nil;
  Ans := '';
  Rev := '';
  Err := '';
  try
    try
      AgentExpandRoots(Roots, Prefs, Files, ScanTick);
      Note := TAgentNote.Create;
      Note.Files := TStringList.Create;
      for I := 0 to Files.Count - 1 do
        Note.Files.Add(Files[I]);
      Note.Text := IntToStr(Files.Count);
      PostNote(Link.Wnd, WM_AGENT_FILES, Note);
      if Link.Cancel <> 0 then
        Err := 'stopped'
      else if Files.Count = 0 then
        Err := 'nofiles'
      else
      begin
        Poster := TAgentPoster.Create;
        Poster.Link := Link;
        Poster.CancelPtr := @Link.Cancel;
        AgentExecute(Prompt, Files, Prefs, Poster, Ans, Rev, Err);
      end;
    except
      on E: Exception do
        if Err = '' then
          Err := E.Message;
    end;
    Note := TAgentNote.Create;
    Note.Text := Ans;
    Note.Revised := Rev;
    Note.Err := Err;
    PostNote(Link.Wnd, WM_AGENT_DONE, Note);
  finally
    Poster.Free;
    Files.Free;
    Roots.Free;
  end;
end;

procedure TfrmAgentWorkspace.BuildUi;
var
  pnlStatus, Host, Line: TsPanel;

  procedure Stack(AControl: TControl; AAlign: TAlign);
  begin
    { alTop/alBottom order follows Top: push each new control past the previous ones. }
    if AAlign = alTop then
      AControl.Top := 100000
    else if AAlign = alBottom then
      AControl.Top := -100000;
    AControl.Align := AAlign;
  end;

  function MakePanel(AParent: TWinControl; AAlign: TAlign; ASize: Integer): TsPanel;
  begin
    Result := TsPanel.Create(Self);
    Result.Parent := AParent;
    Result.BevelOuter := bvNone;
    Result.ParentBackground := True;
    if AAlign in [alTop, alBottom] then
      Result.Height := ASize
    else if AAlign in [alLeft, alRight] then
      Result.Width := ASize;
    Stack(Result, AAlign);
  end;

  function MakeGroup(AParent: TWinControl; AAlign: TAlign; ASize: Integer): TsGroupBox;
  begin
    Result := TsGroupBox.Create(Self);
    Result.Parent := AParent;
    Result.AlignWithMargins := True;
    Result.Margins.SetBounds(8, 6, 8, 6);
    Result.Font.Style := [fsBold];
    if AAlign in [alTop, alBottom] then
      Result.Height := ASize;
    Stack(Result, AAlign);
  end;

  function GroupHost(AGroup: TsGroupBox): TsPanel;
  begin
    Result := TsPanel.Create(Self);
    Result.Parent := AGroup;
    Result.BevelOuter := bvNone;
    Result.ParentBackground := True;
    Result.ParentFont := False;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := 9;
    Result.Font.Style := [];
    Result.AlignWithMargins := True;
    Result.Margins.SetBounds(8, 20, 8, 8);
    Result.Align := alClient;
  end;

  function MakeButton(AParent: TWinControl; AWidth: Integer; AClick: TNotifyEvent): TsButton;
  begin
    Result := TsButton.Create(Self);
    Result.Parent := AParent;
    Result.Width := AWidth;
    Result.Height := 30;
    Result.OnClick := AClick;
  end;

  function MakeLabel(AParent: TWinControl; AAlign: TAlign; AHeight: Integer): TsLabel;
  begin
    Result := TsLabel.Create(Self);
    Result.Parent := AParent;
    Result.AutoSize := False;
    Result.WordWrap := True;
    Result.Layout := tlCenter;
    Result.Height := AHeight;
    Stack(Result, AAlign);
  end;

  function MakeMemo(AParent: TWinControl; AReadOnly, AWrap: Boolean): TsMemo;
  begin
    Result := TsMemo.Create(Self);
    Result.Parent := AParent;
    Result.ReadOnly := AReadOnly;
    Result.ScrollBars := ssVertical;
    Result.WordWrap := AWrap;
    Result.WantReturns := True;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := 10;
    Result.Align := alClient;
  end;

  function MakeList(AParent: TWinControl): TsListBox;
  begin
    Result := TsListBox.Create(Self);
    Result.Parent := AParent;
    Result.IntegralHeight := False;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := 9;
  end;

  function MakeTab(const ACaption: string): TsTabSheet;
  begin
    Result := TsTabSheet.Create(Self);
    Result.PageControl := pgResults;
    Result.Caption := ACaption;
  end;

  { Same look as the Assistant question bar (Translate / Suggest): flat bold buttons on a light strip. }
  function MakeToolBar(AParent: TWinControl): TsPanel;
  var
    Edge: TsPanel;
  begin
    Result := TsPanel.Create(Self);
    Result.Parent := AParent;
    Result.BevelOuter := bvNone;
    Result.BevelInner := bvNone;
    Result.ParentBackground := False;
    Result.Color := TOOLBAR_MID;
    Result.Caption := '';
    Result.Height := Dpi(24) + 2 * Dpi(4) + 1;
    Stack(Result, alBottom);
    Edge := TsPanel.Create(Self);
    Edge.Parent := Result;
    Edge.BevelOuter := bvNone;
    Edge.BevelInner := bvNone;
    Edge.ParentBackground := False;
    Edge.Color := TOOLBAR_EDGE;
    Edge.Caption := '';
    Edge.Height := 1;
    Edge.Align := alTop;
  end;

  function MakeToolBtn(ABar: TsPanel; ATag: Integer; AClick: TNotifyEvent): TsSpeedButton;
  begin
    Result := TsSpeedButton.Create(Self);
    Result.Parent := ABar;
    Result.Tag := ATag;
    Result.Flat := True;
    Result.ShowCaption := True;
    Result.ShowHint := True;
    Result.ParentShowHint := False;
    Result.Cursor := crHandPoint;
    Result.ParentFont := False;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := 8;
    Result.Font.Style := [fsBold];
    Result.Spacing := 6;
    try
      Result.SkinData.SkinSection := 'TOOLBUTTON';
    except
    end;
    Result.Height := Dpi(24);
    Result.Width := Dpi(60);
    Result.AlignWithMargins := True;
    Result.Margins.SetBounds(6, 4, 2, 4);
    Result.Left := 100000;
    Result.Align := alLeft;
    Result.OnClick := AClick;
  end;

  procedure MakeToolSet(AParent: TWinControl; ATag: Integer;
    out ANew, AClear, ACopy, AAsk: TsSpeedButton);
  var
    Bar: TsPanel;
  begin
    Bar := MakeToolBar(AParent);
    if ATag = 1 then
    begin
      btnPromptTranslate := MakeToolBtn(Bar, ATag, PromptTranslateClick);
      btnPromptSuggest := MakeToolBtn(Bar, ATag, PromptSuggestClick);
    end;
    ANew := MakeToolBtn(Bar, ATag, ToolNewClick);
    AClear := MakeToolBtn(Bar, ATag, ToolClearClick);
    ACopy := MakeToolBtn(Bar, ATag, ToolCopyClick);
    AAsk := MakeToolBtn(Bar, ATag, ToolAskClick);
    if ATag = 3 then
      btnAnswerLastFile := MakeToolBtn(Bar, ATag, LastFileClick);
  end;

  procedure FieldRow(AParent: TWinControl; ALabelWidth, AEditWidth: Integer;
    out ALabel: TsLabel; out AEdit: TsEdit);
  begin
    Line := MakePanel(AParent, alTop, 28);
    Line.AlignWithMargins := True;
    Line.Margins.SetBounds(0, 4, 0, 0);
    ALabel := TsLabel.Create(Self);
    ALabel.Parent := Line;
    ALabel.AutoSize := False;
    ALabel.Layout := tlCenter;
    ALabel.Width := ALabelWidth;
    ALabel.Align := alLeft;
    AEdit := TsEdit.Create(Self);
    AEdit.Parent := Line;
    AEdit.AlignWithMargins := True;
    AEdit.Margins.SetBounds(4, 3, 0, 3);
    if AEditWidth > 0 then
    begin
      AEdit.Width := AEditWidth;
      AEdit.Left := ALabelWidth + 10;
      AEdit.Align := alLeft;
    end
    else
      AEdit.Align := alClient;
  end;

begin
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  DoubleBuffered := True;

  { Guide line: tells the user the order of the steps. }
  { Drawn by GuidePaint (gradient card, accent bar, icon) so the skin cannot repaint it; lblGuide only holds text, font and margins. }
  pnlTop := MakePanel(Self, alTop, 48);
  pnlTop.Padding.SetBounds(Dpi(10), Dpi(8), Dpi(10), Dpi(2));
  pbGuide := TPaintBox.Create(Self);
  pbGuide.Parent := pnlTop;
  pbGuide.Align := alClient;
  pbGuide.OnPaint := GuidePaint;
  lblGuide := TsLabel.Create(Self);
  lblGuide.Parent := pnlTop;
  lblGuide.Visible := False;
  lblGuide.AutoSize := False;
  lblGuide.WordWrap := True;
  lblGuide.Margins.SetBounds(Dpi(44), Dpi(7), Dpi(14), Dpi(7));
  lblGuide.ParentFont := False;
  lblGuide.Font.Name := 'Segoe UI';
  lblGuide.Font.Size := 10;
  lblGuide.Font.Color := GUIDE_TEXT;

  pnlStatus := MakePanel(Self, alBottom, 28);
  FStatusBar := pnlStatus;
  lblStatus := TsLabel.Create(Self);
  lblStatus.Parent := pnlStatus;
  lblStatus.AutoSize := False;
  lblStatus.AlignWithMargins := True;
  lblStatus.Margins.SetBounds(14, 2, 14, 2);
  lblStatus.Layout := tlCenter;
  lblStatus.Align := alClient;

  { Left column: step 1 (what the agent may read) and options. }
  pnlLeft := MakePanel(Self, alLeft, 380);
  pnlLeft.Constraints.MinWidth := 300;

  grpOptions := MakeGroup(pnlLeft, alBottom, 168);
  grpOptions.Margins.SetBounds(10, 4, 4, 8);
  Host := GroupHost(grpOptions);
  chkSubdirs := TsCheckBox.Create(Self);
  chkSubdirs.Parent := Host;
  chkSubdirs.AutoSize := False;
  chkSubdirs.Height := 24;
  Stack(chkSubdirs, alTop);
  FieldRow(Host, 120, 0, lblMask, edtMask);
  edtMask.ShowHint := True;
  edtMask.OnChange := MaskChange;
  FieldRow(Host, 120, 70, lblDepth, edtDepth);
  FieldRow(Host, 120, 70, lblMaxFiles, edtMaxFiles);

  grpSources := MakeGroup(pnlLeft, alClient, 0);
  grpSources.Margins.SetBounds(10, 6, 4, 4);
  Host := GroupHost(grpSources);
  pnlSourceBtns := MakePanel(Host, alTop, 108);
  pnlSourceBtns.OnResize := SourceButtonsResize;
  btnAddFiles := MakeButton(pnlSourceBtns, 150, AddFilesClick);
  btnAddFolder := MakeButton(pnlSourceBtns, 150, AddFolderClick);
  btnOpenFile := MakeButton(pnlSourceBtns, 150, OpenFileClick);
  btnRemove := MakeButton(pnlSourceBtns, 150, RemoveClick);
  btnSelectAll := MakeButton(pnlSourceBtns, 150, SelectAllRootsClick);
  btnRemoveAll := MakeButton(pnlSourceBtns, 150, RemoveAllClick);

  { Search box. TShape draws border + white fill (the skin repaints TPanel colours);
    glyph, borderless edit and clear x sit on top, placed in RootFindLayout. }
  pnlRootFind := MakePanel(Host, alTop, Dpi(36));
  pnlRootFind.OnResize := RootFindLayout;

  shpFind := TShape.Create(Self);
  shpFind.Parent := pnlRootFind;
  shpFind.Shape := stRoundRect;
  shpFind.Pen.Color := FIND_BORDER;
  shpFind.Brush.Color := clWindow;
  shpFind.OnMouseDown := RootFindBoxMouseDown;

  lblFindGlyph := TLabel.Create(Self);
  lblFindGlyph.Parent := pnlRootFind;
  lblFindGlyph.AutoSize := False;
  lblFindGlyph.Alignment := taCenter;
  lblFindGlyph.Layout := tlCenter;
  lblFindGlyph.Transparent := True;
  lblFindGlyph.ParentFont := False;
  if Screen.Fonts.IndexOf('Segoe MDL2 Assets') >= 0 then
  begin
    lblFindGlyph.Font.Name := 'Segoe MDL2 Assets';
    lblFindGlyph.Font.Size := 9;
    lblFindGlyph.Caption := #$E721;
  end
  else
  begin
    lblFindGlyph.Font.Name := 'Segoe UI Symbol';
    lblFindGlyph.Font.Size := 9;
    lblFindGlyph.Caption := #$2315;
  end;
  lblFindGlyph.Font.Color := clGrayText;
  lblFindGlyph.OnClick := RootFindBoxClick;

  btnRootFindClear := TLabel.Create(Self);
  btnRootFindClear.Parent := pnlRootFind;
  btnRootFindClear.AutoSize := False;
  btnRootFindClear.Alignment := taCenter;
  btnRootFindClear.Layout := tlCenter;
  btnRootFindClear.Transparent := True;
  btnRootFindClear.ParentFont := False;
  btnRootFindClear.Font.Name := 'Segoe UI';
  btnRootFindClear.Font.Size := 11;
  btnRootFindClear.Font.Color := clGrayText;
  btnRootFindClear.Caption := #$00D7;
  btnRootFindClear.Cursor := crHandPoint;
  btnRootFindClear.Visible := False;
  btnRootFindClear.OnClick := RootFindClearClick;
  btnRootFindClear.OnMouseEnter := RootFindClearEnter;
  btnRootFindClear.OnMouseLeave := RootFindClearLeave;

  edtRootFind := TEdit.Create(Self);
  edtRootFind.Parent := pnlRootFind;
  edtRootFind.BorderStyle := bsNone;
  edtRootFind.ParentColor := False;
  edtRootFind.Color := clWindow;
  edtRootFind.ParentFont := False;
  edtRootFind.Font.Name := 'Segoe UI';
  edtRootFind.Font.Size := 9;
  edtRootFind.OnChange := RootFindChange;
  edtRootFind.OnEnter := RootFindFocusChange;
  edtRootFind.OnExit := RootFindFocusChange;
  edtRootFind.OnKeyDown := RootFindKeyDown;

  btnRootRecent := MakeButton(pnlRootFind, 100, RootRecentClick);
  btnRootRecent.ShowHint := True;

  { Count on its own full-width line under the list, so long texts are never clipped. }
  pnlCountRow := MakePanel(Host, alBottom, Dpi(18));
  lblRootCount := TLabel.Create(Self);
  lblRootCount.Parent := pnlCountRow;
  lblRootCount.AutoSize := False;
  lblRootCount.Layout := tlCenter;
  lblRootCount.Alignment := taRightJustify;
  lblRootCount.Transparent := True;
  lblRootCount.ParentFont := False;
  lblRootCount.Font.Name := 'Segoe UI';
  lblRootCount.Font.Size := 8;
  lblRootCount.Font.Color := clGrayText;
  lblRootCount.Align := alClient;
  { Short screens only: the Options group moves to a popup opened by this link. }
  lblOptLink := TLabel.Create(Self);
  lblOptLink.Parent := pnlCountRow;
  lblOptLink.AutoSize := True;
  lblOptLink.Layout := tlCenter;
  lblOptLink.Transparent := True;
  lblOptLink.ParentFont := False;
  lblOptLink.Font.Name := 'Segoe UI';
  lblOptLink.Font.Size := 8;
  lblOptLink.Font.Color := $00D77800;
  lblOptLink.Font.Style := [fsUnderline];
  lblOptLink.Cursor := crHandPoint;
  lblOptLink.Align := alLeft;
  lblOptLink.Visible := False;
  lblOptLink.OnClick := OptionsLinkClick;
  MakeToolSet(Host, 2, btnRootsNew, btnRootsClear, btnRootsCopy, btnRootsAsk);

  lstRoots := MakeList(Host);
  lstRoots.AlignWithMargins := True;
  lstRoots.Margins.SetBounds(0, 4, 0, 0);
  lstRoots.Align := alClient;
  lstRoots.MultiSelect := True;
  lstRoots.ExtendedSelect := True;

  mnuRoots := TPopupMenu.Create(Self);
  mnuRoots.OnPopup := RootsMenuPopup;
  miRootRemove := TMenuItem.Create(mnuRoots);
  miRootRemove.ShortCut := ShortCut(VK_DELETE, []);
  miRootRemove.OnClick := RemoveClick;
  mnuRoots.Items.Add(miRootRemove);
  miRootSelectAll := TMenuItem.Create(mnuRoots);
  miRootSelectAll.ShortCut := ShortCut(Ord('A'), [ssCtrl]);
  miRootSelectAll.OnClick := SelectAllRootsClick;
  mnuRoots.Items.Add(miRootSelectAll);
  miRootCopy := TMenuItem.Create(mnuRoots);
  miRootCopy.ShortCut := ShortCut(Ord('C'), [ssCtrl]);
  miRootCopy.OnClick := CopyRootsClick;
  mnuRoots.Items.Add(miRootCopy);
  mnuRoots.Items.Add(NewLine);
  miRootRemoveAll := TMenuItem.Create(mnuRoots);
  miRootRemoveAll.OnClick := RemoveAllClick;
  mnuRoots.Items.Add(miRootRemoveAll);
  lstRoots.PopupMenu := mnuRoots;

  splLeft := TsSplitter.Create(Self);
  splLeft.Parent := Self;
  splLeft.Left := pnlLeft.Left + pnlLeft.Width + 1;
  splLeft.Width := 6;
  splLeft.Align := alLeft;
  splLeft.MinSize := 260;

  pnlClient := MakePanel(Self, alClient, 0);

  { Step 2: the request. Send sits right under the text box. }
  grpPrompt := MakeGroup(pnlClient, alTop, 204 + Dpi(24) + 2 * Dpi(4) + 1);
  grpPrompt.Margins.SetBounds(4, 6, 10, 4);
  Host := GroupHost(grpPrompt);
  FPromptHost := Host;
  pnlSendBar := MakePanel(Host, alBottom, 40);
  btnStop := MakeButton(pnlSendBar, 110, StopClick);
  btnStop.AlignWithMargins := True;
  btnStop.Margins.SetBounds(6, 6, 0, 2);
  btnStop.Align := alRight;
  btnSend := MakeButton(pnlSendBar, 140, SendClick);
  btnSend.AlignWithMargins := True;
  btnSend.Margins.SetBounds(6, 6, 0, 2);
  btnSend.Left := 0;
  btnSend.Align := alRight;
  btnSend.Font.Style := [fsBold];
  lblSendHint := TsLabel.Create(Self);
  lblSendHint.Parent := pnlSendBar;
  lblSendHint.AutoSize := False;
  lblSendHint.Layout := tlCenter;
  lblSendHint.AlignWithMargins := True;
  lblSendHint.Margins.SetBounds(0, 6, 6, 2);
  lblSendHint.Align := alClient;
  MakeToolSet(Host, 1, btnPromptNew, btnPromptClear, btnPromptCopy, btnPromptAsk);

  { Recent prompts: same MRU popup as the Assistant (find, remove, delete all). }
  pnlRecentRow := MakePanel(Host, alTop, 30);
  pnlRecentRow.Padding.SetBounds(0, 2, 0, 4);
  lblRecent := TsLabel.Create(Self);
  lblRecent.Parent := pnlRecentRow;
  lblRecent.AutoSize := False;
  lblRecent.Layout := tlCenter;
  lblRecent.Width := 130;
  lblRecent.Align := alLeft;
  pnlRecentCombo := TPanel.Create(Self);
  pnlRecentCombo.Parent := pnlRecentRow;
  pnlRecentCombo.BevelOuter := bvNone;
  pnlRecentCombo.BevelInner := bvNone;
  pnlRecentCombo.BorderStyle := bsSingle;
  pnlRecentCombo.Caption := '';
  pnlRecentCombo.ParentColor := False;
  pnlRecentCombo.ParentBackground := False;
  pnlRecentCombo.Color := clWindow;
  pnlRecentCombo.Cursor := crHandPoint;
  pnlRecentCombo.ShowHint := True;
  pnlRecentCombo.Align := alClient;
  pnlRecentCombo.OnClick := RecentComboClick;
  lblRecentArrow := TLabel.Create(Self);
  lblRecentArrow.Parent := pnlRecentCombo;
  lblRecentArrow.Align := alRight;
  lblRecentArrow.AutoSize := False;
  lblRecentArrow.Width := 18;
  lblRecentArrow.Alignment := taCenter;
  lblRecentArrow.Layout := tlCenter;
  lblRecentArrow.Caption := #$25BE;
  lblRecentArrow.Transparent := True;
  lblRecentArrow.OnClick := RecentComboClick;
  lblRecentCombo := TLabel.Create(Self);
  lblRecentCombo.Parent := pnlRecentCombo;
  lblRecentCombo.Align := alClient;
  lblRecentCombo.AlignWithMargins := True;
  lblRecentCombo.Margins.SetBounds(4, 0, 0, 0);
  lblRecentCombo.Layout := tlCenter;
  lblRecentCombo.AutoSize := False;
  lblRecentCombo.EllipsisPosition := epEndEllipsis;
  lblRecentCombo.Caption := '';
  lblRecentCombo.Transparent := True;
  lblRecentCombo.OnClick := RecentComboClick;

  memPrompt := MakeMemo(Host, False, True);
  memPrompt.OnKeyDown := PromptKeyDown;
  memPrompt.OnChange := PromptChange;

  { Step 3: results, one tab each so nothing is squeezed. }
  grpResults := MakeGroup(pnlClient, alClient, 0);
  grpResults.Margins.SetBounds(4, 4, 10, 8);
  Host := GroupHost(grpResults);
  pgResults := TsPageControl.Create(Self);
  pgResults.Parent := Host;
  pgResults.Align := alClient;

  tabAnswer := MakeTab('Answer');
  MakeToolSet(tabAnswer, 3, btnAnswerNew, btnAnswerClear, btnAnswerCopy, btnAnswerAsk);
  memAnswer := MakeMemo(tabAnswer, True, True);
  memAnswer.AlignWithMargins := True;
  memAnswer.Margins.SetBounds(6, 6, 6, 6);
  memAnswer.OnChange := AnswerChange;

  { Edits tab: buttons on top (always visible on short screens), note + list on the left, preview on the right. }
  tabEdits := MakeTab('Proposed edits');
  pnlActions := MakePanel(tabEdits, alTop, 42);
  pnlActions.DoubleBuffered := True;
  btnAccept := MakeButton(pnlActions, 120, AcceptClick);
  btnAccept.SetBounds(6, 6, 120, 30);
  btnReject := MakeButton(pnlActions, 120, RejectClick);
  btnReject.SetBounds(132, 6, 120, 30);
  btnAcceptAll := MakeButton(pnlActions, 150, AcceptAllClick);
  btnAcceptAll.SetBounds(258, 6, 150, 30);

  pbExpire := TPaintBox.Create(Self);
  pbExpire.Parent := pnlActions;
  pbExpire.ParentFont := False;
  if Screen.Fonts.IndexOf('Segoe UI Semibold') >= 0 then
    pbExpire.Font.Name := 'Segoe UI Semibold'
  else
  begin
    pbExpire.Font.Name := 'Segoe UI';
    pbExpire.Font.Style := [fsBold];
  end;
  pbExpire.Font.Size := 9;
  pbExpire.ShowHint := True;
  pbExpire.OnPaint := ExpirePaint;
  pbExpire.Visible := False;

  { 100 ms steps: the stopwatch sector shrinks smoothly; the seconds shown are rounded up. }
  tmrDecision := TTimer.Create(Self);
  tmrDecision.Enabled := False;
  tmrDecision.Interval := 100;
  tmrDecision.OnTimer := DecisionTimer;

  { The note sits right of the buttons; its left margin follows the buttons' width (FitTexts). }
  lblEditsNote := TsLabel.Create(Self);
  lblEditsNote.Parent := pnlActions;
  lblEditsNote.AutoSize := False;
  lblEditsNote.WordWrap := False;
  lblEditsNote.EllipsisPosition := epEndEllipsis;
  lblEditsNote.ShowHint := True;
  lblEditsNote.Cursor := crHandPoint;
  lblEditsNote.OnClick := FullTextClick;
  lblEditsNote.Layout := tlCenter;
  lblEditsNote.ParentFont := False;
  lblEditsNote.Font.Name := 'Segoe UI';
  lblEditsNote.Font.Size := 9;
  lblEditsNote.Font.Color := $00707070;
  lblEditsNote.AlignWithMargins := True;
  lblEditsNote.Margins.SetBounds(420, 2, 8, 2);
  lblEditsNote.Align := alClient;

  EditsTop := MakePanel(tabEdits, alLeft, 240);
  lstEdits := MakeList(EditsTop);
  lstEdits.AlignWithMargins := True;
  lstEdits.Margins.SetBounds(6, 0, 0, 6);
  lstEdits.Align := alClient;
  lstEdits.ItemHeight := 20;
  lstEdits.OnClick := EditsClick;
  lstEdits.OnDblClick := PreviewZoom;

  splEdits := TsSplitter.Create(Self);
  splEdits.Parent := tabEdits;
  splEdits.Left := EditsTop.Left + EditsTop.Width + 1;
  splEdits.Width := 5;
  splEdits.Align := alLeft;
  splEdits.MinSize := 120;

  PreviewPane := MakePanel(tabEdits, alClient, 0);
  PreviewPane.OnResize := PreviewPaneResize;
  lstPreview := TListBox.Create(Self);
  lstPreview.Parent := PreviewPane;
  lstPreview.AlignWithMargins := True;
  lstPreview.Margins.SetBounds(0, 0, 6, 6);
  lstPreview.Align := alClient;
  lstPreview.Style := lbOwnerDrawFixed;
  lstPreview.IntegralHeight := False;
  lstPreview.TabStop := False;
  lstPreview.ParentFont := False;
  lstPreview.Font.Name := 'Consolas';
  lstPreview.Font.Size := 10;
  lstPreview.Color := clWhite;
  lstPreview.DoubleBuffered := True;
  lstPreview.ShowHint := True;
  lstPreview.OnDrawItem := PreviewDrawItem;
  lstPreview.OnClick := PreviewClick;
  lstPreview.OnDblClick := PreviewZoom;
  FPreviewRows := TStringList.Create;

  mnuFullText := TPopupMenu.Create(Self);
  miFullView := TMenuItem.Create(Self);
  miFullView.OnClick := FullTextViewClick;
  mnuFullText.Items.Add(miFullView);
  miFullCopy := TMenuItem.Create(Self);
  miFullCopy.OnClick := FullTextCopyClick;
  mnuFullText.Items.Add(miFullCopy);
  lblEditsNote.PopupMenu := mnuFullText;
  lstEdits.PopupMenu := mnuFullText;
  lstPreview.PopupMenu := mnuFullText;
  FHintItem := -2;
  lstEdits.OnMouseMove := EditsMouseMove;
  lstEdits.OnMouseDown := EditsMouseDown;

  tabRevised := MakeTab('Revised prompt');
  memRevised := MakeMemo(tabRevised, True, True);
  memRevised.AlignWithMargins := True;
  memRevised.Margins.SetBounds(6, 6, 6, 6);

  tabIncluded := MakeTab('Files found');
  lstIncluded := MakeList(tabIncluded);
  lstIncluded.AlignWithMargins := True;
  lstIncluded.Margins.SetBounds(6, 6, 6, 6);
  lstIncluded.Align := alClient;

  pgResults.ActivePage := tabAnswer;

  tmrWait := TTimer.Create(Self);
  tmrWait.Enabled := False;
  tmrWait.Interval := 200;
  tmrWait.OnTimer := WaitTimer;

  FEdits := TObjectList.Create(True);
  FRunAfter := TObjectList.Create(True);
  FRoots := TObjectList.Create(True);
  FRecent := TStringList.Create;
  LoadAgentRecent(FRecent);
  FRootRecent := TStringList.Create;
  LoadAgentRootRecent(FRootRecent);
  OnDestroy := FormDestroy;
  OnResize := FormResize;
  AddLastGeneratedFileListener(LastFileChanged);
  LoadOptions;
  ApplyLanguage;
  SetBusy(False);
  LoadSession;
end;

function TfrmAgentWorkspace.TextPx(AFont: TFont; const S: string): Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(AFont);
    Result := Bmp.Canvas.TextWidth(StripHotkey(S));
  finally
    Bmp.Free;
  end;
end;

function TfrmAgentWorkspace.RecentComboNeed: Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(lblRecentCombo.Font);
    Result := Bmp.Canvas.TextHeight('Wg');
    Bmp.Canvas.Font.Assign(lblRecentArrow.Font);
    Result := Max(Result, Bmp.Canvas.TextHeight(lblRecentArrow.Caption));
  finally
    Bmp.Free;
  end;
  Inc(Result, Dpi(6) + 2 * GetSystemMetrics(SM_CYEDGE));
end;

function TfrmAgentWorkspace.WrapPx(AFont: TFont; const S: string; AWidth: Integer): Integer;
var
  Bmp: TBitmap;
  R: TRect;
begin
  Result := 0;
  if (S = '') or (AWidth <= 0) then Exit;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(AFont);
    R := Rect(0, 0, AWidth, 0);
    DrawText(Bmp.Canvas.Handle, PChar(S), -1, R, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
    Result := R.Bottom - R.Top;
  finally
    Bmp.Free;
  end;
end;

{ Widths follow the translated captions: no language may clip a label or button. }
procedure TfrmAgentWorkspace.FitTexts;
var
  W, X, Gap: Integer;

  function BtnW(B: TsButton; AMin: Integer): Integer;
  begin
    Result := Max(Dpi(AMin), TextPx(B.Font, B.Caption) + Dpi(28));
  end;

begin
  if btnSend = nil then Exit;
  SizeToolButtons;
  W := Max(TextPx(lblMask.Font, lblMask.Caption),
    Max(TextPx(lblDepth.Font, lblDepth.Caption), TextPx(lblMaxFiles.Font, lblMaxFiles.Caption))) + Dpi(10);
  W := Max(W, Dpi(90));
  lblMask.Width := W;
  lblDepth.Width := W;
  lblMaxFiles.Width := W;
  edtDepth.Width := Dpi(70);
  edtMaxFiles.Width := Dpi(70);

  lblRecent.Width := TextPx(lblRecent.Font, lblRecent.Caption) + Dpi(12);
  { The fake combo is a bordered panel: tall enough for its font at any PPI, or the text is clipped. }
  W := RecentComboNeed;
  if pnlRecentRow.Parent = FPromptHost then
  begin
    W := Max(Dpi(30), W + pnlRecentRow.Padding.Top + pnlRecentRow.Padding.Bottom);
    if pnlRecentRow.Height <> W then
      pnlRecentRow.Height := W;
  end
  else
  begin
    FRecentRowH := Max(FRecentRowH, W + FRecentPad.Top + FRecentPad.Bottom);
    W := Max(Dpi(40), W + pnlRecentRow.Padding.Top + pnlRecentRow.Padding.Bottom);
    if pnlSendBar.Height < W then
      pnlSendBar.Height := W;
  end;

  btnSend.Width := BtnW(btnSend, 120);
  btnStop.Width := BtnW(btnStop, 96);

  Gap := Dpi(6);
  X := Gap;
  btnAccept.SetBounds(X, Gap, BtnW(btnAccept, 110), Dpi(30));
  Inc(X, btnAccept.Width + Gap);
  btnReject.SetBounds(X, Gap, BtnW(btnReject, 110), Dpi(30));
  Inc(X, btnReject.Width + Gap);
  btnAcceptAll.SetBounds(X, Gap, BtnW(btnAcceptAll, 130), Dpi(30));
  pnlActions.Height := Dpi(42);
  X := btnAcceptAll.Left + btnAcceptAll.Width + Dpi(10);
  if (pbExpire <> nil) and pbExpire.Visible then
  begin
    { Widest caption this language can show, so the badge does not jump while counting down.
      Padding + stopwatch + gap + text + padding (see ExpirePaint). }
    W := Max(TextPx(pbExpire.Font, Format(TrText('Agent.ExpireIn'), [MAX_AGENT_DECISION_SECONDS])),
      TextPx(pbExpire.Font, TrText('Agent.ExpiredShort'))) + Dpi(12) + Dpi(18) + Dpi(7) + Dpi(14);
    pbExpire.SetBounds(X, Gap, W, Dpi(30));
    Inc(X, W + Dpi(10));
  end;
  lblEditsNote.Margins.Left := X;
  { Narrow window: shrink the list so the preview keeps most of the room (only shrinks; the splitter still works). }
  if (splEdits <> nil) and (EditsTop <> nil) and (tabEdits.ClientWidth > Dpi(300)) then
  begin
    X := Max(Dpi(140), (tabEdits.ClientWidth - splEdits.Width) * 2 div 5);
    if EditsTop.Width > X then
      EditsTop.Width := X;
  end;

  lblSendHint.ShowHint := True;
  lblSendHint.Hint := lblSendHint.Caption;

  { Left column: wide enough for two source buttons side by side in this language. }
  X := pnlLeft.Width - pnlSourceBtns.ClientWidth;
  if (pnlSourceBtns.ClientWidth <= 0) or (X < 0) or (X > Dpi(100)) then
    X := Dpi(44);
  W := 2 * SourceButtonNeed + Dpi(5) + X;
  { ...and for the whole New / Clear / Copy / Ask toolbar under the source list, without clipping. }
  if (btnRootsNew <> nil) and (btnRootsAsk <> nil) then
    W := Max(W, btnRootsNew.Width + btnRootsClear.Width + btnRootsCopy.Width + btnRootsAsk.Width +
      4 * (btnRootsAsk.Margins.Left + btnRootsAsk.Margins.Right) + Dpi(8) + X);
  W := Max(W, 300);
  pnlLeft.Constraints.MinWidth := W;
  if pnlLeft.Width < W then
    pnlLeft.Width := W;
  splLeft.MinSize := W;
  SourceButtonsResize(nil);
  FitWrapped;
end;

{ Height of the word-wrapped guide line follows the text and the width. }
procedure TfrmAgentWorkspace.FitWrapped;
begin
  if lblGuide = nil then Exit;
  if ClientWidth >= Dpi(260) then
    pnlTop.Height := GuideHeight(FGuideCompact);
  pbGuide.Invalidate;
  FitHeights;
end;

procedure TfrmAgentWorkspace.SetGuideFont(AFont: TFont; ACompact: Boolean);
begin
  AFont.Assign(lblGuide.Font);
  if ACompact then
    AFont.Size := 9;
end;

{ Banner height for the current width; the compact one has a smaller font and tighter padding. }
function TfrmAgentWorkspace.GuideHeight(ACompact: Boolean): Integer;
var
  W, H: Integer;
  F: TFont;
begin
  { Measured on the form: the panel keeps a stale width while hidden by FitHeights. }
  W := ClientWidth - Dpi(20) - lblGuide.Margins.Left - lblGuide.Margins.Right;
  F := TFont.Create;
  try
    SetGuideFont(F, ACompact);
    H := WrapPx(F, lblGuide.Caption, Max(W, Dpi(100)));
  finally
    F.Free;
  end;
  if ACompact then
    Result := Max(Dpi(28), H + Dpi(4) + Dpi(1) + 2 * Dpi(4))
  else
    Result := Max(Dpi(44), H + Dpi(8) + Dpi(2) + 2 * Dpi(7));
end;

procedure TfrmAgentWorkspace.GuidePaint(Sender: TObject);
var
  C: TCanvas;
  R, T: TRect;
  H, IconW: Integer;
begin
  C := pbGuide.Canvas;
  R := pbGuide.ClientRect;
  GradientFillCanvas(C, GUIDE_FROM, GUIDE_TO, R, gdHorizontal);
  C.Pen.Color := GUIDE_EDGE;
  C.Brush.Style := bsClear;
  C.Rectangle(R);
  C.Brush.Style := bsSolid;
  C.Brush.Color := GUIDE_ACCENT;
  C.FillRect(Rect(R.Left, R.Top, R.Left + Dpi(4), R.Bottom));

  { Info glyph, centred in the space left of the text. }
  IconW := lblGuide.Margins.Left;
  C.Brush.Style := bsClear;
  C.Font.Color := GUIDE_ACCENT;
  if Screen.Fonts.IndexOf('Segoe MDL2 Assets') >= 0 then
  begin
    C.Font.Name := 'Segoe MDL2 Assets';
    if FGuideCompact then
      C.Font.Size := 11
    else
      C.Font.Size := 14;
    T := Rect(R.Left + Dpi(4), R.Top, R.Left + IconW, R.Bottom);
    DrawText(C.Handle, PChar(string(#$E946)), -1, T, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  SetGuideFont(C.Font, FGuideCompact);
  C.Font.Color := GUIDE_TEXT;
  T := Rect(R.Left + IconW, 0, R.Right - lblGuide.Margins.Right, 0);
  DrawText(C.Handle, PChar(lblGuide.Caption), -1, T, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  H := T.Bottom - T.Top;
  T := Rect(R.Left + IconW, R.Top + (R.Height - H) div 2, R.Right - lblGuide.Margins.Right, R.Bottom);
  DrawText(C.Handle, PChar(lblGuide.Caption), -1, T, DT_WORDBREAK or DT_NOPREFIX);
end;

procedure TfrmAgentWorkspace.FormResize(Sender: TObject);
begin
  FitWrapped;
end;

procedure TfrmAgentWorkspace.SetCompact(ALevel: Integer);
var
  Bar: TWinControl;
begin
  FCompact := ALevel;
  { Level 1: smaller banner. Level 2: no banner (the group titles keep the step numbers). }
  FGuideCompact := ALevel = 1;
  if FGuideCompact then
    pnlTop.Padding.SetBounds(Dpi(10), Dpi(4), Dpi(10), Dpi(1))
  else
    pnlTop.Padding.SetBounds(Dpi(10), Dpi(8), Dpi(10), Dpi(2));
  if ClientWidth >= Dpi(260) then
    pnlTop.Height := GuideHeight(FGuideCompact);
  pnlTop.Visible := ALevel < 2;
  pbGuide.Invalidate;

  { Level 3: the recent-requests combo moves into the Send row (frees a whole row). }
  if ALevel >= 3 then
  begin
    if pnlRecentRow.Parent <> pnlSendBar then
    begin
      FRecentRowH := pnlRecentRow.Height;
      FRecentPad := Rect(pnlRecentRow.Padding.Left, pnlRecentRow.Padding.Top,
        pnlRecentRow.Padding.Right, pnlRecentRow.Padding.Bottom);
      lblSendHint.Visible := False;
      lblRecent.Visible := False;
      pnlRecentRow.Parent := pnlSendBar;
      pnlRecentRow.Padding.SetBounds(0, Dpi(8), Dpi(6), Dpi(4));
      pnlRecentRow.Align := alClient;
    end;
  end
  else if pnlRecentRow.Parent <> FPromptHost then
  begin
    pnlRecentRow.Align := alNone;
    pnlRecentRow.Parent := FPromptHost;
    pnlRecentRow.Padding.SetBounds(FRecentPad.Left, FRecentPad.Top, FRecentPad.Right, FRecentPad.Bottom);
    pnlRecentRow.SetBounds(0, 0, FPromptHost.ClientWidth, FRecentRowH);
    pnlRecentRow.Align := alTop;
    lblRecent.Visible := True;
    lblSendHint.Visible := True;
  end;

  { Level 4: Options open from a link (popup); the answer toolbar is hidden (copy stays in the memo menu). }
  lblOptLink.Visible := ALevel >= 4;
  if (ALevel < 4) and (FOptPopup <> nil) and FOptPopup.Visible then
    FOptPopup.Close;
  if grpOptions.Parent = pnlLeft then
    grpOptions.Visible := ALevel < 4;
  btnAnswerNew.Parent.Visible := ALevel < 4;

  { Level 5: the sources toolbar is hidden (its actions are also in the list's context menu). }
  Bar := btnRootsNew.Parent;
  if Bar.Visible <> (ALevel < 5) then
  begin
    Bar.Visible := ALevel < 5;
    if Bar.Visible then
      Bar.Top := pnlCountRow.Top - Bar.Height;
  end;
end;

procedure TfrmAgentWorkspace.FitHeights;
const
  MAX_LEVEL = 5;
var
  L, Avail, H, RecentH, PromptFixed, ResFrame, ResMin, SrcFixed, OptH, RightFree, LeftFree: Integer;
  GuideFull, GuideSmall: Integer;

  { Same rect the VCL aligns children in: the skinned group box reserves its caption band here. }
  function Frame(G: TWinControl; AHost: TControl): Integer;
  var
    R: TRect;
  begin
    R := G.ClientRect;
    TFrameAccess(G).AdjustClientRect(R);
    Result := (G.Height - (R.Bottom - R.Top)) + AHost.Margins.Top + AHost.Margins.Bottom;
  end;

  function Gap(C: TControl): Integer;
  begin
    Result := C.Margins.Top + C.Margins.Bottom;
  end;

begin
  if FFitting or (FStatusBar = nil) or (btnRootsNew = nil) then Exit;
  Avail := ClientHeight - FStatusBar.Height;
  if (Avail <= 0) or (ClientWidth < Dpi(200)) then Exit;
  FFitting := True;
  try
    if pnlRecentRow.Parent = FPromptHost then
      RecentH := pnlRecentRow.Height
    else
      RecentH := FRecentRowH;
    PromptFixed := Frame(grpPrompt, FPromptHost) + pnlSendBar.Height + btnPromptNew.Parent.Height + RecentH;
    ResFrame := Frame(grpResults, pgResults.Parent);
    SrcFixed := Frame(grpSources, lstRoots.Parent) + pnlSourceBtns.Height + pnlRootFind.Height +
      pnlCountRow.Height + Gap(lstRoots);
    if grpOptions.Parent = pnlLeft then
      FOptH := grpOptions.Height;
    OptH := FOptH + Gap(grpOptions);
    GuideFull := GuideHeight(False);
    GuideSmall := GuideHeight(True);

    L := 0;
    while True do
    begin
      H := Avail;
      if L = 0 then
        Dec(H, GuideFull)
      else if L = 1 then
        Dec(H, GuideSmall);
      ResMin := Dpi(100);
      if L < 4 then
        Inc(ResMin, btnAnswerNew.Parent.Height);
      RightFree := H - Gap(grpPrompt) - Gap(grpResults) - ResFrame - ResMin - PromptFixed;
      if L >= 3 then
        Inc(RightFree, RecentH);
      LeftFree := H - Gap(grpSources) - SrcFixed;
      if L < 4 then
        Dec(LeftFree, OptH);
      if L < 5 then
        Dec(LeftFree, btnRootsNew.Parent.Height);
      if ((RightFree >= Dpi(36)) and (LeftFree >= Dpi(56))) or (L >= MAX_LEVEL) then
        Break;
      Inc(L);
    end;

    if L <> FCompact then
      SetCompact(L);
    if L >= 3 then
      Dec(PromptFixed, RecentH);
    { The prompt box takes up to ~5 lines; the rest goes to the results. }
    grpPrompt.Height := PromptFixed + Max(Dpi(36), Min(Dpi(90), RightFree));
  finally
    FFitting := False;
  end;
end;

procedure TfrmAgentWorkspace.MaskChange(Sender: TObject);
begin
  edtMask.Hint := edtMask.Text;
end;

procedure TfrmAgentWorkspace.OptionsLinkClick(Sender: TObject);
var
  P: TPoint;
  R: TRect;
  Skin: TsSkinProvider;
begin
  if FOptPopup = nil then
  begin
    FOptPopup := TForm.CreateNew(Self);
    Skin := TsSkinProvider.Create(FOptPopup);
    Skin.SkinData.SkinSection := 'DIALOG';
    FOptPopup.BorderStyle := bsToolWindow;
    FOptPopup.BorderIcons := [biSystemMenu];
    FOptPopup.Position := poDesigned;
    FOptPopup.Font.Assign(Font);
    FOptPopup.OnClose := OptionsPopupClose;
    FOptPopup.OnDeactivate := OptionsPopupDeactivate;
  end;
  if FOptPopup.Visible then
  begin
    FOptPopup.Close;
    Exit;
  end;
  FOptPopup.Caption := Trim(grpOptions.Caption);
  FOptPopup.ClientWidth := pnlLeft.ClientWidth;
  FOptPopup.ClientHeight := FOptH + grpOptions.Margins.Top + grpOptions.Margins.Bottom;
  grpOptions.Parent := FOptPopup;
  grpOptions.Align := alClient;
  grpOptions.Visible := True;
  { Opens above the link (the link sits at the bottom of the column), kept on the monitor. }
  P := lblOptLink.ClientToScreen(Point(0, 0));
  R := Screen.MonitorFromPoint(P).WorkareaRect;
  FOptPopup.Left := Max(R.Left, Min(P.X, R.Right - FOptPopup.Width));
  FOptPopup.Top := Max(R.Top, P.Y - FOptPopup.Height - Dpi(4));
  FOptPopup.Show;
end;

procedure TfrmAgentWorkspace.OptionsPopupClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
  grpOptions.Visible := False;
  grpOptions.Align := alNone;
  grpOptions.Parent := pnlLeft;
  grpOptions.Height := FOptH;
  grpOptions.Top := pnlLeft.ClientHeight;
  grpOptions.Align := alBottom;
  grpOptions.Visible := FCompact < 3;
end;

procedure TfrmAgentWorkspace.OptionsPopupDeactivate(Sender: TObject);
begin
  if (FOptPopup <> nil) and FOptPopup.Visible then
    FOptPopup.Close;
end;

function TfrmAgentWorkspace.SourceButtonNeed: Integer;
var
  Btns: array[0..5] of TsButton;
  I: Integer;
begin
  Btns[0] := btnAddFiles;
  Btns[1] := btnAddFolder;
  Btns[2] := btnOpenFile;
  Btns[3] := btnRemove;
  Btns[4] := btnSelectAll;
  Btns[5] := btnRemoveAll;
  Result := 0;
  for I := 0 to High(Btns) do
    Result := Max(Result, TextPx(Btns[I].Font, Btns[I].Caption) + Dpi(16));
end;

{ Always a 2 x 3 grid. FitTexts widens the left column when a language needs more room. }
procedure TfrmAgentWorkspace.SourceButtonsResize(Sender: TObject);
var
  W, Gap, BH, H: Integer;
begin
  if btnRemoveAll = nil then Exit;
  Gap := Dpi(5);
  BH := Dpi(24);
  W := (pnlSourceBtns.ClientWidth - Gap) div 2;
  if W < Dpi(60) then
    W := Dpi(60);
  btnAddFiles.SetBounds(0, Dpi(2), W, BH);
  btnAddFolder.SetBounds(W + Gap, Dpi(2), W, BH);
  btnOpenFile.SetBounds(0, Dpi(2) + BH + Gap, W, BH);
  btnRemove.SetBounds(W + Gap, Dpi(2) + BH + Gap, W, BH);
  btnSelectAll.SetBounds(0, Dpi(2) + 2 * (BH + Gap), W, BH);
  btnRemoveAll.SetBounds(W + Gap, Dpi(2) + 2 * (BH + Gap), W, BH);
  H := Dpi(2) + 3 * (BH + Gap);
  if pnlSourceBtns.Height <> H then
    pnlSourceBtns.Height := H;
end;

procedure TfrmAgentWorkspace.UpdateResultTabs;
begin
  tabAnswer.Caption := TrText('Answer');
  tabRevised.Caption := TrText('Revised prompt');
  if lstEdits.Items.Count > 0 then
    tabEdits.Caption := Format('%s (%d)', [TrText('Proposed edits'), lstEdits.Items.Count])
  else
    tabEdits.Caption := TrText('Proposed edits');
  if lstIncluded.Items.Count > 0 then
    tabIncluded.Caption := Format('%s (%d)', [TrText('Files found'), lstIncluded.Items.Count])
  else
    tabIncluded.Caption := TrText('Files found');
  if FExternal and not FBusy then
    AgentBridgeNotify(abeEditsChanged, '', '', lstEdits.Items.Count);
  UpdateEditButtons;
  UpdateToolButtons;
end;

{ Accept / Reject need a selected proposal; Accept all needs at least one. }
procedure TfrmAgentWorkspace.UpdateEditButtons;
var
  Has, Sel: Boolean;
begin
  if (btnAccept = nil) or (lstEdits = nil) then Exit;
  Has := (FEdits <> nil) and (FEdits.Count > 0) and (lstEdits.Items.Count > 0);
  Sel := Has and (lstEdits.ItemIndex >= 0);
  btnAccept.Enabled := Sel and not FBusy;
  btnReject.Enabled := Sel and not FBusy;
  btnAcceptAll.Enabled := Has and not FBusy;
end;

{ Each tool bar (prompt, sources, answer) acts on its own area: an empty area disables its bar. }
procedure TfrmAgentWorkspace.UpdateToolButtons;
var
  Idle, HasPrompt, HasRoots, HasAnswer: Boolean;
begin
  if (btnPromptAsk = nil) or (memPrompt = nil) or (memAnswer = nil) then Exit;
  Idle := not (FBusy or FAskBusy);
  HasPrompt := Trim(memPrompt.Text) <> '';
  HasRoots := (FRoots <> nil) and (FRoots.Count > 0);
  HasAnswer := Trim(memAnswer.Text) <> '';
  btnPromptNew.Enabled := HasPrompt and not FBusy;
  btnPromptClear.Enabled := HasPrompt and not FBusy;
  btnPromptCopy.Enabled := HasPrompt;
  btnPromptAsk.Enabled := HasPrompt and Idle;
  btnPromptTranslate.Enabled := HasPrompt and Idle;
  btnPromptSuggest.Enabled := HasPrompt and Idle;
  btnRootsNew.Enabled := HasRoots and not FBusy;
  btnRootsClear.Enabled := HasRoots and not FBusy;
  btnRootsCopy.Enabled := HasRoots;
  btnRootsAsk.Enabled := HasRoots and Idle;
  btnAnswerNew.Enabled := HasAnswer and Idle;
  btnAnswerClear.Enabled := HasAnswer and Idle;
  btnAnswerCopy.Enabled := HasAnswer;
  btnAnswerAsk.Enabled := HasAnswer and Idle;
end;

procedure TfrmAgentWorkspace.AnswerChange(Sender: TObject);
begin
  UpdateToolButtons;
end;

procedure TfrmAgentWorkspace.FormDestroy(Sender: TObject);
var
  M: TMsg;
  Until0: Cardinal;
begin
  if tmrDecision <> nil then
    tmrDecision.Enabled := False;
  RemoveLastGeneratedFileListener(LastFileChanged);
  if FExternal then
    AgentBridgeNotify(abeEditsChanged, '', '', 0);
  EndWait;
  FCancel := 1;
  if FLink <> nil then
  begin
    TAgentLink(FLink).Wnd := 0;
    TAgentLink(FLink).Cancel := 1;
  end;
  if FThread <> nil then
    TThread(FThread).OnTerminate := nil;
  FThread := nil;
  FLink := nil;
  FLinkRef := nil;
  if FAskLink <> nil then
    TAgentLink(FAskLink).Wnd := 0;
  FAskLink := nil;
  if FPreviewLink <> nil then
  begin
    TAgentLink(FPreviewLink).Wnd := 0;
    TAgentLink(FPreviewLink).Cancel := 1;
  end;
  FPreviewLink := nil;
  FPreviewLinkRef := nil;
  FAskLinkRef := nil;
  { The apply thread calls back into this form; let it reach a safe point (the host blocks close meanwhile). }
  Until0 := GetTickCount;
  while FApplyRunning and (GetTickCount - Until0 < 120000) do
  begin
    PeekMessage(M, 0, 0, 0, PM_NOREMOVE);
    CheckSynchronize(20);
  end;
  SaveSession;
  ClearRoots;
  FreeAndNil(FRoots);
  FreeAndNil(FEdits);
  FreeAndNil(FPreviewRows);
  FreeAndNil(FRunAfter);
  FreeAndNil(FRecent);
  FreeAndNil(FRootRecent);
end;

procedure TfrmAgentWorkspace.LoadOptions;
var
  P: TAgentPrefs;
begin
  P := LoadAgentPrefs;
  chkSubdirs.Checked := P.IncludeSubdirs;
  edtMask.Text := P.Mask;
  edtDepth.Text := IntToStr(P.MaxDepth);
  edtMaxFiles.Text := IntToStr(P.MaxFiles);
end;

function TfrmAgentWorkspace.ReadOptions: TAgentPrefs;
begin
  Result := DefaultAgentPrefs;
  Result.IncludeSubdirs := chkSubdirs.Checked;
  Result.Mask := Trim(edtMask.Text);
  if Result.Mask = '' then
    Result.Mask := DefaultAgentPrefs.Mask;
  Result.MaxDepth := ClampAgentInt(StrToIntDef(Trim(edtDepth.Text), Result.MaxDepth), 0, 32, Result.MaxDepth);
  Result.MaxFiles := ClampAgentInt(StrToIntDef(Trim(edtMaxFiles.Text), Result.MaxFiles), 1, 20000, Result.MaxFiles);
  edtDepth.Text := IntToStr(Result.MaxDepth);
  edtMaxFiles.Text := IntToStr(Result.MaxFiles);
end;

procedure TfrmAgentWorkspace.StoreOptions;
begin
  SaveAgentPrefs(ReadOptions);
end;

{ Send needs a prompt: an empty (or blank) request stays disabled. }
procedure TfrmAgentWorkspace.PromptChange(Sender: TObject);
begin
  if (btnSend = nil) or (memPrompt = nil) then Exit;
  btnSend.Enabled := not (FBusy or FAskBusy) and (Trim(memPrompt.Text) <> '');
  UpdateToolButtons;
end;

procedure TfrmAgentWorkspace.SetBusy(ABusy: Boolean);
begin
  FBusy := ABusy;
  PromptChange(nil);
  btnAddFiles.Enabled := not ABusy;
  btnAddFolder.Enabled := not ABusy;
  btnOpenFile.Enabled := not ABusy;
  btnRemove.Enabled := not ABusy;
  RefreshRootRecentButton;
  if FRoots <> nil then
  begin
    btnRemoveAll.Enabled := (FRoots.Count > 0) and not ABusy;
    btnSelectAll.Enabled := (lstRoots.Items.Count > 0) and not ABusy;
  end;
  btnStop.Enabled := ABusy;
  UpdateEditButtons;
  UpdateToolButtons;
  RefreshRecentCombo;
end;

function RootCaption(ARoot: TAgentRoot): string;
begin
  if ARoot.Kind = arkFolder then
    Result := Format(TrText('[folder] %s'), [ARoot.Path])
  else
    Result := Format(TrText('[file] %s'), [ARoot.Path]);
end;

procedure TfrmAgentWorkspace.AddRoot(AKind: TAgentRootKind; const APath: string);
var
  I: Integer;
  Root: TAgentRoot;
  Full: string;
begin
  Full := ExpandFileName(Trim(APath));
  if Full = '' then Exit;
  if not FRestoringSession and (FRootRecent <> nil) then
  begin
    RememberAgentRoot(FRootRecent, Full);
    FRootRecentDirty := True;
  end;
  for I := 0 to FRoots.Count - 1 do
    if SameText(TAgentRoot(FRoots[I]).Path, Full) then
      Exit;
  Root := TAgentRoot.Create;
  Root.Kind := AKind;
  Root.Path := Full;
  FRoots.Add(Root);
  if not FLoadingSession then
  begin
    RefreshRootList;
    SaveSession;
  end;
end;

procedure TfrmAgentWorkspace.ClearRoots;
begin
  if FRoots <> nil then
    FRoots.Clear;
  if lstRoots <> nil then
    lstRoots.Items.Clear;
end;

{ Shows FRoots filtered by the find box. Items point at FRoots entries; FRoots owns them. }
procedure TfrmAgentWorkspace.RefreshRootList;
var
  I: Integer;
  Root: TAgentRoot;
  Needle, Cap: string;
begin
  if (lstRoots = nil) or (FRoots = nil) then Exit;
  Needle := Trim(edtRootFind.Text);
  lstRoots.Items.BeginUpdate;
  try
    lstRoots.Items.Clear;
    for I := 0 to FRoots.Count - 1 do
    begin
      Root := TAgentRoot(FRoots[I]);
      Cap := RootCaption(Root);
      if MruTextMatches(Cap, Needle) then
        lstRoots.Items.AddObject(Cap, Root);
    end;
  finally
    lstRoots.Items.EndUpdate;
  end;
  btnRootFindClear.Visible := Needle <> '';
  if (Needle <> '') and (lstRoots.Items.Count = 0) then
  begin
    lblRootCount.Caption := TrText('Agent.FindNoMatch');
    lblRootCount.Font.Color := $003030C0;
  end
  else
  begin
    if Needle <> '' then
      lblRootCount.Caption := Format(TrText('Agent.FindCount'), [lstRoots.Items.Count, FRoots.Count])
    else
      lblRootCount.Caption := Format(TrText('Agent.ItemCount'), [FRoots.Count]);
    lblRootCount.Font.Color := clGrayText;
  end;
  btnRemoveAll.Enabled := (FRoots.Count > 0) and not FBusy;
  btnSelectAll.Enabled := (lstRoots.Items.Count > 0) and not FBusy;
  UpdateToolButtons;
end;

procedure TfrmAgentWorkspace.RootFindChange(Sender: TObject);
begin
  RefreshRootList;
end;

procedure TfrmAgentWorkspace.RootFindClearClick(Sender: TObject);
begin
  edtRootFind.Text := '';
  if edtRootFind.CanFocus then
    edtRootFind.SetFocus;
end;

procedure TfrmAgentWorkspace.RootFindBoxClick(Sender: TObject);
begin
  if edtRootFind.CanFocus then
    edtRootFind.SetFocus;
end;

procedure TfrmAgentWorkspace.RootFindClearEnter(Sender: TObject);
begin
  btnRootFindClear.Font.Color := clWindowText;
end;

procedure TfrmAgentWorkspace.RootFindClearLeave(Sender: TObject);
begin
  btnRootFindClear.Font.Color := clGrayText;
end;

procedure TfrmAgentWorkspace.RootFindFocusChange(Sender: TObject);
begin
  if edtRootFind.Focused then
  begin
    shpFind.Pen.Color := FIND_BORDER_FOCUS;
    lblFindGlyph.Font.Color := FIND_BORDER_FOCUS;
  end
  else
  begin
    shpFind.Pen.Color := FIND_BORDER;
    lblFindGlyph.Font.Color := clGrayText;
  end;
end;

function TfrmAgentWorkspace.Dpi(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

procedure TfrmAgentWorkspace.RootFindBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  RootFindBoxClick(Sender);
end;

procedure TfrmAgentWorkspace.RootFindLayout(Sender: TObject);
var
  W, Top, H, GlyphW, ClearW, EdH, BtnW: Integer;
begin
  if (shpFind = nil) or (edtRootFind = nil) then Exit;
  W := pnlRootFind.ClientWidth;
  Top := Dpi(5);
  H := pnlRootFind.ClientHeight - Top - Dpi(2);
  if H < Dpi(20) then
    H := Dpi(20);
  if btnRootRecent <> nil then
  begin
    BtnW := Min(btnRootRecent.Width, W div 2);
    btnRootRecent.SetBounds(W - BtnW, Top, BtnW, H);
    W := W - BtnW - Dpi(6);
  end;
  GlyphW := Dpi(26);
  ClearW := Dpi(24);
  shpFind.SetBounds(0, Top, W, H);
  lblFindGlyph.SetBounds(1, Top + 1, GlyphW, H - 2);
  btnRootFindClear.SetBounds(W - ClearW - 1, Top + 1, ClearW, H - 2);
  EdH := edtRootFind.Height;
  edtRootFind.SetBounds(GlyphW + 1, Top + (H - EdH) div 2, Max(Dpi(40), W - GlyphW - ClearW - 4), EdH);
end;

procedure TfrmAgentWorkspace.RootFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    Key := 0;
    OpenRootRecentPopup;
    Exit;
  end;
  case Key of
    VK_ESCAPE:
      if edtRootFind.Text <> '' then
      begin
        Key := 0;
        edtRootFind.Text := '';
      end;
    VK_DOWN, VK_RETURN:
      if lstRoots.Items.Count > 0 then
      begin
        Key := 0;
        lstRoots.SetFocus;
        if lstRoots.ItemIndex < 0 then
        begin
          lstRoots.ItemIndex := 0;
          lstRoots.Selected[0] := True;
        end;
      end;
  end;
end;

procedure TfrmAgentWorkspace.SelectAllRootsClick(Sender: TObject);
begin
  if lstRoots.Items.Count = 0 then Exit;
  lstRoots.SelectAll;
  if lstRoots.CanFocus then
    lstRoots.SetFocus;
end;

procedure TfrmAgentWorkspace.CopyRootsClick(Sender: TObject);
var
  SL: TStringList;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    for I := 0 to lstRoots.Items.Count - 1 do
      if lstRoots.Selected[I] then
        SL.Add(TAgentRoot(lstRoots.Items.Objects[I]).Path);
    if SL.Count = 0 then Exit;
    Clipboard.AsText := TrimRight(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TfrmAgentWorkspace.SizeToolButtons;

  procedure Fit(B: TsSpeedButton);
  begin
    if B <> nil then
      B.Width := Min(Dpi(200), Max(Dpi(56), TextPx(B.Font, B.Caption) + Dpi(28)));
  end;

begin
  Fit(btnPromptTranslate);
  Fit(btnPromptSuggest);
  Fit(btnPromptNew);
  Fit(btnPromptClear);
  Fit(btnPromptCopy);
  Fit(btnPromptAsk);
  Fit(btnRootsNew);
  Fit(btnRootsClear);
  Fit(btnRootsCopy);
  Fit(btnRootsAsk);
  Fit(btnAnswerNew);
  Fit(btnAnswerClear);
  Fit(btnAnswerCopy);
  Fit(btnAnswerAsk);
  Fit(btnAnswerLastFile);
end;

{ ATag: 1 = prompt, 2 = sources (selected ones, or all), 3 = answer. Memos give the selection when asked. }
function TfrmAgentWorkspace.ToolAreaText(ATag: Integer; ASelectionOnly: Boolean): string;
var
  SL: TStringList;
  I: Integer;
  Memo: TsMemo;
begin
  Result := '';
  case ATag of
    1, 3:
      begin
        if ATag = 1 then
          Memo := memPrompt
        else
          Memo := memAnswer;
        if ASelectionOnly and (Memo.SelLength > 0) then
          Result := Memo.SelText
        else
          Result := Memo.Text;
      end;
    2:
      begin
        SL := TStringList.Create;
        try
          for I := 0 to lstRoots.Items.Count - 1 do
            if lstRoots.Selected[I] then
              SL.Add(TAgentRoot(lstRoots.Items.Objects[I]).Path);
          if SL.Count = 0 then
            for I := 0 to FRoots.Count - 1 do
              SL.Add(TAgentRoot(FRoots[I]).Path);
          Result := SL.Text;
        finally
          SL.Free;
        end;
      end;
  end;
  Result := Trim(Result);
end;

{ "New": keep what the area has (prompt -> recent requests; sources and answer -> a text file in
  AgentHistory beside the exe), then clear it like "Clear" does. }
procedure TfrmAgentWorkspace.ToolNewClick(Sender: TObject);
var
  Tag, I: Integer;
  Body, Dir, FileName: string;
  SL: TStringList;
begin
  Tag := TComponent(Sender).Tag;
  Body := '';
  case Tag of
    1:
      Body := Trim(memPrompt.Text);
    2:
      begin
        SL := TStringList.Create;
        try
          for I := 0 to FRoots.Count - 1 do
            SL.Add(TAgentRoot(FRoots[I]).Path);
          Body := Trim(SL.Text);
        finally
          SL.Free;
        end;
      end;
    3:
      if Trim(memAnswer.Text) <> '' then
        Body := TrText('Prompt') + ':' + sLineBreak + Trim(memPrompt.Text) + sLineBreak + sLineBreak +
          TrText('Answer') + ':' + sLineBreak + Trim(memAnswer.Text);
  end;

  if Body = '' then
    lblStatus.Caption := TrText('Agent.NewNothingToSave')
  else if Tag = 1 then
  begin
    RememberAgentPrompt(FRecent, memPrompt.Text);
    SaveAgentRecent(FRecent);
    RefreshRecentCombo;
    lblStatus.Caption := TrText('Agent.NewPromptSaved');
  end
  else
  begin
    Dir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'AgentHistory');
    if Tag = 2 then
      FileName := Dir + FormatDateTime('yyyymmdd_hhnnss', Now) + '_sources.txt'
    else
      FileName := Dir + FormatDateTime('yyyymmdd_hhnnss', Now) + '_answer.txt';
    SL := TStringList.Create;
    try
      SL.Text := Body;
      try
        ForceDirectories(Dir);
        SL.SaveToFile(FileName, TEncoding.UTF8);
      except
        on E: Exception do
        begin
          { Not saved: keep the area as it is so nothing is lost. }
          lblStatus.Caption := TrText('Agent.NewSaveFailed') + ' ' + E.Message;
          Exit;
        end;
      end;
    finally
      SL.Free;
    end;
    lblStatus.Caption := Format(TrText('Agent.NewSaved'), [FileName]);
  end;

  case Tag of
    1:
      begin
        memPrompt.Clear;
        PromptChange(nil);
        if memPrompt.CanFocus then
          memPrompt.SetFocus;
      end;
    2:
      RemoveAllClick(Sender);
    3:
      begin
        memAnswer.Clear;
        memRevised.Clear;
        UpdateToolButtons;
        SaveSession;
      end;
  end;
end;

procedure TfrmAgentWorkspace.ToolClearClick(Sender: TObject);
begin
  case TComponent(Sender).Tag of
    1:
      begin
        memPrompt.Clear;
        PromptChange(nil);
        if memPrompt.CanFocus then
          memPrompt.SetFocus;
      end;
    2:
      if lstRoots.SelCount > 0 then
        RemoveClick(Sender)
      else
        RemoveAllClick(Sender);
    3:
      begin
        memAnswer.Clear;
        UpdateToolButtons;
        SaveSession;
      end;
  end;
end;

procedure TfrmAgentWorkspace.ToolCopyClick(Sender: TObject);
var
  S: string;
begin
  S := ToolAreaText(TComponent(Sender).Tag, True);
  if S = '' then
  begin
    lblStatus.Caption := TrText('Agent.NothingToCopy');
    Exit;
  end;
  Clipboard.AsText := S;
  lblStatus.Caption := TrText('Agent.Copied');
end;

procedure TfrmAgentWorkspace.LastFileClick(Sender: TObject);
begin
  ShowLastGeneratedFileDialog;
end;

procedure TfrmAgentWorkspace.LastFileChanged(Sender: TObject);
var
  Path: string;
  Recs: Int64;
begin
  if btnAnswerLastFile = nil then Exit;
  if LastGeneratedFile(Path, Recs) then
    btnAnswerLastFile.Hint := TrText('ExportDone.ShowLastHint') + #13#10 + Path
  else
    btnAnswerLastFile.Hint := TrText('ExportDone.ShowLastHint');
  btnAnswerLastFile.Enabled := (Path <> '') and FileExists(Path);
end;

procedure TfrmAgentWorkspace.ToolAskClick(Sender: TObject);
var
  Content, What, Q: string;
begin
  if FBusy or FAskBusy then Exit;
  Content := ToolAreaText(TComponent(Sender).Tag, True);
  if Content = '' then
  begin
    lblStatus.Caption := TrText('Agent.AskEmptyArea');
    Exit;
  end;
  case TComponent(Sender).Tag of
    1: What := 'the request the user is writing for the FastFile AI agent';
    2: What := 'the files and folders selected as sources in FastFile (paths only, contents not included)';
  else
    What := 'the last answer given by the FastFile AI agent';
  end;
  Q := '';
  if not InputQuery(TrText('Agent.ToolAsk'), TrText('Agent.AskQuestion'), Q) then Exit;
  Q := Trim(Q);
  if Q = '' then Exit;
  AskAiAbout(Content, What, Q);
end;

procedure TfrmAgentWorkspace.AskAiAbout(const AContent, AWhat, AQuestion: string);
var
  C, P: string;
begin
  C := AContent;
  if Length(C) > ASK_MAX_CONTENT then
    C := Copy(C, 1, ASK_MAX_CONTENT) + sLineBreak + '[...]';
  P := 'You are the AI assistant inside FastFile, a viewer/editor for very large text files.' + sLineBreak +
    'Answer the question about the content below. Reply in ' + AssistantLangPromptName(GetCurrentLanguage) +
    ' (the app UI language), even when the question is written in another language, unless the question ' +
    'asks for a specific language. Use plain text (no JSON).' + sLineBreak + sLineBreak +
    'Content (' + AWhat + '):' + sLineBreak + '"""' + sLineBreak + C + sLineBreak + '"""' + sLineBreak + sLineBreak +
    'Question:' + sLineBreak + AQuestion;
  StartAiJob(P, 0);
end;

procedure TfrmAgentWorkspace.PromptTranslateClick(Sender: TObject);
var
  Lang: TAppLanguage;
  It: TMenuItem;
  Pt: TPoint;
begin
  if FBusy or FAskBusy then Exit;
  if Trim(memPrompt.Text) = '' then
  begin
    lblStatus.Caption := TrText('Assistant.Error.EmptyQuestion');
    Exit;
  end;
  if mnuTranslate = nil then
  begin
    mnuTranslate := TPopupMenu.Create(Self);
    mnuTranslate.AutoHotkeys := maManual;
  end;
  mnuTranslate.Items.Clear;
  for Lang := Low(TAppLanguage) to High(TAppLanguage) do
  begin
    It := TMenuItem.Create(mnuTranslate);
    It.Caption := AssistantLangMenuCaption(Lang);
    It.Tag := Ord(Lang);
    It.OnClick := PromptTranslateLangClick;
    mnuTranslate.Items.Add(It);
  end;
  Pt := btnPromptTranslate.ClientToScreen(Point(0, btnPromptTranslate.Height));
  mnuTranslate.Popup(Pt.X, Pt.Y);
end;

procedure TfrmAgentWorkspace.PromptTranslateLangClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    StartPromptTextJob(1, AssistantLangPromptName(TAppLanguage(TMenuItem(Sender).Tag)));
end;

procedure TfrmAgentWorkspace.PromptSuggestClick(Sender: TObject);
begin
  StartPromptTextJob(2, '');
end;

{ Translate / suggest work on the prompt selection when there is one, else on the whole prompt. }
procedure TfrmAgentWorkspace.StartPromptTextJob(AJob: Integer; const ALangName: string);
var
  Src, P: string;
begin
  if FBusy or FAskBusy then Exit;
  FAskReplaceSel := memPrompt.SelLength > 0;
  if FAskReplaceSel then
    Src := Trim(memPrompt.SelText)
  else
    Src := Trim(memPrompt.Text);
  if Src = '' then
  begin
    lblStatus.Caption := TrText('Assistant.Error.EmptyQuestion');
    Exit;
  end;
  if AJob = 1 then
    P := string(BuildAssistantTranslatePromptW(Src, ALangName))
  else
    P := 'You help the user write a clearer request for the FastFile AI agent.' + sLineBreak +
      'The agent reads the files and folders the user selected, searches and counts in them, ' +
      'answers questions and proposes edits (written only after the user accepts them).' + sLineBreak +
      'Rewrite USER_DRAFT as one clear, complete request the agent can run.' + sLineBreak +
      'Keep the user intent and the language of the draft. Improve grammar and structure.' + sLineBreak +
      'Keep paths, numbers, codes, names, prefixes and filenames.' + sLineBreak +
      'If the draft is already clear, only polish it lightly.' + sLineBreak +
      'Reply with ONE JSON object only (no markdown):' + sLineBreak +
      '{"resposta":"<improved request only>"}' + sLineBreak +
      'In JSON, encode any non-ASCII letter as \\uXXXX (UTF-16), not raw bytes.' + sLineBreak + sLineBreak +
      'USER_DRAFT:' + sLineBreak + Src;
  StartAiJob(P, AJob);
end;

procedure TfrmAgentWorkspace.StartAiJob(const APrompt: string; AJob: Integer);
var
  Link: TAgentLink;
  LinkRef: IInterface;
  P, NoAnswer: string;
begin
  NoAnswer := TrText('Agent.AskNoAnswer');
  P := APrompt;
  FAskJob := AJob;
  Link := TAgentLink.Create;
  LinkRef := Link;
  Link.Wnd := Handle;
  FAskLink := Link;
  FAskLinkRef := LinkRef;
  FAskBusy := True;
  SetBusy(FBusy);
  case AJob of
    1: lblStatus.Caption := TrText('Assistant.Translating');
    2: lblStatus.Caption := TrText('Assistant.Rewriting');
  else
    lblStatus.Caption := TrText('Assistant.Thinking');
  end;
  BeginWait(2, lblStatus.Caption, TrText('Assistant.ProcessingDetail'));

  TThread.CreateAnonymousThread(
    procedure
    var
      Ans: WideString;
      Err: string;
      Note: TAgentNote;
    begin
      Ans := '';
      Err := '';
      try
        if not FastFileAIInvokePrompt(WideString(P), Ans, Err) and (Err = '') then
          Err := NoAnswer;
      except
        on E: Exception do
          Err := E.Message;
      end;
      Note := TAgentNote.Create;
      Note.Text := string(Ans);
      Note.Err := Err;
      PostNote(Link.Wnd, WM_AGENT_ASKDONE, Note);
      LinkRef := nil;
    end).Start;
end;

procedure TfrmAgentWorkspace.WMAskDone(var Msg: TMessage);
var
  Note: TAgentNote;
  S, Parsed: string;
begin
  Note := TAgentNote(Msg.LParam);
  if FWaitKind = 2 then
    EndWait;
  try
    FAskBusy := False;
    FAskLink := nil;
    FAskLinkRef := nil;
    SetBusy(FBusy);
    if Note.Err <> '' then
    begin
      lblStatus.Caption := Format(TrText('Agent.AskFailed'), [FriendlyAiError(Note.Err)]);
      Exit;
    end;
    S := Trim(string(UnescapeJsonUnicodeWide(WideString(Note.Text))));
    if Copy(S, 1, 1) = '{' then
    begin
      Parsed := Trim(string(ExtractJsonStringFieldWide(WideString(S), 'resposta')));
      if Parsed = '' then
        Parsed := Trim(ParseAgentTurn(S).Answer);
      if Parsed <> '' then
        S := Trim(string(UnescapeJsonUnicodeWide(WideString(Parsed))));
    end;
    S := MemoText(S);
    if S = '' then
    begin
      lblStatus.Caption := TrText('Agent.AskNoAnswer');
      Exit;
    end;
    if FAskJob in [1, 2] then
    begin
      if FAskReplaceSel and (memPrompt.SelLength > 0) then
        memPrompt.SelText := S
      else
      begin
        memPrompt.Text := S;
        memPrompt.SelStart := Length(memPrompt.Text);
        memPrompt.SelLength := 0;
      end;
      PromptChange(nil);
      if memPrompt.CanFocus then
        memPrompt.SetFocus;
      if FAskJob = 1 then
        lblStatus.Caption := TrText('Assistant.Translated')
      else
        lblStatus.Caption := TrText('Assistant.Rewritten');
      SaveSession;
      Exit;
    end;
    memAnswer.Text := S;
    pgResults.ActivePage := tabAnswer;
    lblStatus.Caption := TrText('Ready.');
    SaveSession;
  finally
    Note.Free;
  end;
end;

procedure TfrmAgentWorkspace.RootsMenuPopup(Sender: TObject);
begin
  miRootRemove.Enabled := (lstRoots.SelCount > 0) and not FBusy;
  miRootCopy.Enabled := lstRoots.SelCount > 0;
  miRootSelectAll.Enabled := lstRoots.Items.Count > 0;
  miRootRemoveAll.Enabled := (FRoots.Count > 0) and not FBusy;
end;

procedure TfrmAgentWorkspace.RemoveAllClick(Sender: TObject);
begin
  if FBusy or (FRoots.Count = 0) then Exit;
  if not MessageBoxTrYesNo(Format(TrText('Agent.RemoveAllConfirm'), [FRoots.Count]), TrText('AI agent')) then
    Exit;
  ClearRoots;
  RefreshRootList;
  SaveSession;
end;

procedure TfrmAgentWorkspace.LoadSession;
var
  S: TAgentSession;
  I: Integer;
  Line: string;
begin
  S := LoadAgentSession;
  FLoadingSession := True;
  FRestoringSession := True;
  try
    for I := 0 to S.Roots.Count - 1 do
    begin
      Line := S.Roots[I];
      if Copy(Line, 1, 2) = 'D|' then
        AddRoot(arkFolder, Copy(Line, 3, MaxInt))
      else if Copy(Line, 1, 2) = 'F|' then
        AddRoot(arkFile, Copy(Line, 3, MaxInt));
    end;
    { First run with this feature: start the recent list from the sources already in use. }
    if (FRootRecent <> nil) and (FRootRecent.Count = 0) and (FRoots.Count > 0) then
    begin
      for I := FRoots.Count - 1 downto 0 do
        RememberAgentRoot(FRootRecent, TAgentRoot(FRoots[I]).Path);
      FRootRecentDirty := True;
    end;
    FRestoringSession := False;
    lstIncluded.Items.Assign(S.Included);
    if Trim(memPrompt.Text) = '' then
      memPrompt.Text := MemoText(S.Prompt);
    PromptChange(nil);
    { Older builds could save the raw model JSON as the answer; keep only its text. }
    if Copy(TrimLeft(S.Answer), 1, 1) = '{' then
      memAnswer.Text := MemoText(StringReplace(ParseAgentTurn(S.Answer).Answer, '**', '', [rfReplaceAll]))
    else
      memAnswer.Text := MemoText(S.Answer);
    memRevised.Text := MemoText(S.Revised);
    if (S.Tab >= 0) and (S.Tab < pgResults.PageCount) and (pgResults.Pages[S.Tab] <> tabEdits) then
      pgResults.ActivePageIndex := S.Tab;
  finally
    FLoadingSession := False;
    FRestoringSession := False;
    S.Roots.Free;
    S.Included.Free;
  end;
  RefreshRootList;
  UpdateResultTabs;
  FlushRootRecent;
end;

procedure TfrmAgentWorkspace.SaveSession;
var
  S: TAgentSession;
  I: Integer;
  Root: TAgentRoot;
begin
  if not FLoadingSession then
    FlushRootRecent;
  if FLoadingSession or (FRoots = nil) or (lstIncluded = nil) then Exit;
  S.Roots := TStringList.Create;
  S.Included := TStringList.Create;
  try
    for I := 0 to FRoots.Count - 1 do
    begin
      Root := TAgentRoot(FRoots[I]);
      if Root.Kind = arkFolder then
        S.Roots.Add('D|' + Root.Path)
      else
        S.Roots.Add('F|' + Root.Path);
    end;
    S.Included.Assign(lstIncluded.Items);
    S.Prompt := memPrompt.Text;
    S.Answer := memAnswer.Text;
    S.Revised := memRevised.Text;
    S.Tab := pgResults.ActivePageIndex;
    SaveAgentSession(S);
  finally
    S.Roots.Free;
    S.Included.Free;
  end;
end;

procedure TfrmAgentWorkspace.AddFilesClick(Sender: TObject);
var
  Dlg: TOpenDialog;
  I: Integer;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Options := Dlg.Options + [ofAllowMultiSelect, ofFileMustExist, ofEnableSizing];
    Dlg.Title := TrText('Agent.PickFilesTitle');
    Dlg.Filter := TrText('Text files (*.txt)|*.txt|All files (*.*)|*.*');
    { Agent reads any text-like file (csv, log, json...); open on "All files". }
    Dlg.FilterIndex := 2;
    if Dlg.Execute then
    begin
      FLoadingSession := True;
      try
        for I := 0 to Dlg.Files.Count - 1 do
          AddRoot(arkFile, Dlg.Files[I]);
      finally
        FLoadingSession := False;
      end;
      RefreshRootList;
      SaveSession;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmAgentWorkspace.AddFolderClick(Sender: TObject);
var
  Dlg: TFileOpenDialog;
  Dir: string;
  I: Integer;
begin
  { Vista+ shell picker: our title/labels are translated; the shell chrome follows Windows. }
  if Win32MajorVersion < 6 then
  begin
    Dir := '';
    if SelectDirectory(TrText('Agent.PickFolderTitle'), '', Dir, [sdNewUI, sdNewFolder], Self) then
      AddRoot(arkFolder, Dir);
    Exit;
  end;
  Dlg := TFileOpenDialog.Create(Self);
  try
    Dlg.Options := [fdoPickFolders, fdoAllowMultiSelect, fdoPathMustExist, fdoForceFileSystem];
    Dlg.Title := TrText('Agent.PickFolderTitle');
    Dlg.OkButtonLabel := TrText('Agent.PickFolderOk');
    Dlg.FileNameLabel := TrText('Agent.PickFolderLabel');
    if (FRoots.Count > 0) and (TAgentRoot(FRoots[FRoots.Count - 1]).Kind = arkFolder) then
      Dlg.DefaultFolder := ExtractFileDir(ExcludeTrailingPathDelimiter(TAgentRoot(FRoots[FRoots.Count - 1]).Path));
    if not Dlg.Execute(Handle) then Exit;
    FLoadingSession := True;
    try
      if Dlg.Files.Count > 0 then
        for I := 0 to Dlg.Files.Count - 1 do
          AddRoot(arkFolder, Dlg.Files[I])
      else if Dlg.FileName <> '' then
        AddRoot(arkFolder, Dlg.FileName);
    finally
      FLoadingSession := False;
    end;
    RefreshRootList;
    SaveSession;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmAgentWorkspace.OpenFileClick(Sender: TObject);
var
  P: string;
begin
  P := '';
  if Assigned(OnGetOpenFile) then
    P := Trim(OnGetOpenFile());
  if (P <> '') and FileExists(P) then
    AddRoot(arkFile, P)
  else
    lblStatus.Caption := TrText('Select a file or folder first.');
end;

procedure TfrmAgentWorkspace.RemoveClick(Sender: TObject);
var
  I, First: Integer;
begin
  if FBusy or (lstRoots.SelCount = 0) then Exit;
  First := -1;
  for I := lstRoots.Items.Count - 1 downto 0 do
    if lstRoots.Selected[I] then
    begin
      FRoots.Remove(lstRoots.Items.Objects[I]);
      First := I;
    end;
  RefreshRootList;
  if First >= lstRoots.Items.Count then
    First := lstRoots.Items.Count - 1;
  if First >= 0 then
  begin
    lstRoots.Selected[First] := True;
    lstRoots.ItemIndex := First;
  end;
  SaveSession;
end;

procedure TfrmAgentWorkspace.PromptKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    SendClick(Sender);
  end
  else if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    Key := 0;
    OpenRecentPopup;
  end;
end;

procedure TfrmAgentWorkspace.RefreshRecentCombo;
begin
  if (pnlRecentCombo = nil) or (FRecent = nil) then Exit;
  pnlRecentCombo.Enabled := (FRecent.Count > 0) and not FBusy;
  if FRecent.Count = 0 then
  begin
    lblRecentCombo.Caption := TrText('Agent.RecentEmpty');
    lblRecentCombo.Font.Color := clGrayText;
  end
  else
  begin
    lblRecentCombo.Caption := Format(TrText('Agent.RecentCount'), [FRecent.Count]);
    lblRecentCombo.Font.Color := clWindowText;
  end;
  pnlRecentCombo.Hint := TrText('Agent.RecentHint');
end;

procedure TfrmAgentWorkspace.RecentComboClick(Sender: TObject);
begin
  Application.CancelHint;
  ReleaseCapture;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    Exit;
  end;
  OpenRecentPopup;
end;

procedure TfrmAgentWorkspace.OpenRecentPopup;
begin
  if (pnlRecentCombo = nil) or not pnlRecentCombo.Enabled then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if FRecentPosted then Exit;
  Application.CancelHint;
  ReleaseCapture;
  FRecentPosted := True;
  PostMessage(Handle, WM_APP + 45, 0, 0);
end;

procedure TfrmAgentWorkspace.WMRecentPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
  OwnerComp: TComponent;
begin
  FRecentPosted := False;
  ReleaseCapture;
  { Wait for the click that opened it to finish, or the popup closes at once. }
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    FRecentPosted := True;
    PostMessage(Handle, WM_APP + 45, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if (FRecent = nil) or (FRecent.Count = 0) or not pnlRecentCombo.Enabled then Exit;
  if pnlRecentCombo.HandleAllocated then
  begin
    GetWindowRect(pnlRecentCombo.Handle, CR);
    W := CR.Right - CR.Left;
    P := Point(CR.Left, CR.Bottom);
  end
  else
  begin
    W := pnlRecentCombo.Width;
    P := pnlRecentCombo.ClientToScreen(Point(0, pnlRecentCombo.Height));
  end;
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('Agent.Recent'), MruMoreCaption('Assistant.RecentQuestionsMore'),
    FRecent, W, P, RecentPick, TrText('Assistant.RecentQuestionsMoreHint'),
    nil, RecentRemove, pnlRecentCombo, RecentClearAll);
end;

procedure TfrmAgentWorkspace.RecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
begin
  memPrompt.Text := MemoText(AValue);
  PromptChange(nil);
  memPrompt.SelStart := Length(memPrompt.Text);
  memPrompt.SelLength := 0;
  if memPrompt.CanFocus then
    memPrompt.SetFocus;
end;

procedure TfrmAgentWorkspace.RecentRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
begin
  if FRecent = nil then Exit;
  for I := FRecent.Count - 1 downto 0 do
    if FRecent[I] = AValue then
    begin
      FRecent.Delete(I);
      Break;
    end;
  SaveAgentRecent(FRecent);
  RefreshRecentCombo;
end;

procedure TfrmAgentWorkspace.RecentClearAll(Sender: TObject);
begin
  if FRecent = nil then Exit;
  FRecent.Clear;
  SaveAgentRecent(FRecent);
  RefreshRecentCombo;
end;

procedure TfrmAgentWorkspace.FlushRootRecent;
begin
  if FRootRecentDirty and (FRootRecent <> nil) then
  begin
    FRootRecentDirty := False;
    SaveAgentRootRecent(FRootRecent);
  end;
  RefreshRootRecentButton;
end;

procedure TfrmAgentWorkspace.RefreshRootRecentButton;
begin
  if (btnRootRecent = nil) or (FRootRecent = nil) then Exit;
  btnRootRecent.Enabled := (FRootRecent.Count > 0) and not FBusy;
end;

procedure TfrmAgentWorkspace.RootRecentClick(Sender: TObject);
begin
  Application.CancelHint;
  ReleaseCapture;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
  begin
    FormPopupMruList.ClosePopup(False);
    Exit;
  end;
  OpenRootRecentPopup;
end;

procedure TfrmAgentWorkspace.OpenRootRecentPopup;
begin
  if (btnRootRecent = nil) or not btnRootRecent.Enabled then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if FRootRecentPosted then Exit;
  Application.CancelHint;
  ReleaseCapture;
  FRootRecentPosted := True;
  PostMessage(Handle, WM_APP + 49, 0, 0);
end;

procedure TfrmAgentWorkspace.WMRootRecentPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
  OwnerComp: TComponent;
begin
  FRootRecentPosted := False;
  ReleaseCapture;
  { Wait for the click that opened it to finish, or the popup closes at once. }
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    FRootRecentPosted := True;
    PostMessage(Handle, WM_APP + 49, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if (FRootRecent = nil) or (FRootRecent.Count = 0) or not btnRootRecent.Enabled then Exit;
  if pnlRootFind.HandleAllocated then
  begin
    GetWindowRect(pnlRootFind.Handle, CR);
    W := CR.Right - CR.Left;
    P := Point(CR.Left, CR.Bottom);
  end
  else
  begin
    W := pnlRootFind.Width;
    P := pnlRootFind.ClientToScreen(Point(0, pnlRootFind.Height));
  end;
  W := Max(W, Dpi(420));
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('Agent.RootRecentTitle'), MruMoreCaption('RecentFiles.More'),
    FRootRecent, W, P, RootRecentPick, TrText('RecentFiles.MoreHint'),
    RootRecentProps, RootRecentRemove, btnRootRecent, RootRecentClearAll);
end;

procedure TfrmAgentWorkspace.RootRecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
var
  P: string;
  I: Integer;
begin
  if FBusy then Exit;
  P := Trim(AValue);
  if DirectoryExists(P) then
    AddRoot(arkFolder, P)
  else if FileExists(P) then
    AddRoot(arkFile, P)
  else
  begin
    RootRecentRemove(Sender, AValue);
    FastFileMsgInfo(Format(TrText('Agent.RootRecentMissing'), [P]), TrText('Agent.RootRecentTitle'));
    Exit;
  end;
  { Already in the list: AddRoot did not save, but the item still moves to the top. }
  FlushRootRecent;
  for I := 0 to lstRoots.Items.Count - 1 do
    if SameText(TAgentRoot(lstRoots.Items.Objects[I]).Path, ExpandFileName(P)) then
    begin
      lstRoots.ClearSelection;
      lstRoots.ItemIndex := I;
      lstRoots.Selected[I] := True;
      Break;
    end;
end;

procedure TfrmAgentWorkspace.RootRecentRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
begin
  if FRootRecent = nil then Exit;
  for I := FRootRecent.Count - 1 downto 0 do
    if SameText(FRootRecent[I], AValue) then
      FRootRecent.Delete(I);
  FRootRecentDirty := True;
  FlushRootRecent;
end;

procedure TfrmAgentWorkspace.RootRecentProps(Sender: TObject; const AValue: string);
var
  Info: TShellExecuteInfo;
  P: string;
begin
  P := Trim(AValue);
  if not (FileExists(P) or DirectoryExists(P)) then
  begin
    FastFileMsgInfo(Format(TrText('Agent.RootRecentMissing'), [P]), TrText('Agent.RootRecentTitle'));
    RootRecentRemove(Sender, AValue);
    Exit;
  end;
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_INVOKEIDLIST;
  Info.Wnd := Handle;
  Info.lpVerb := 'properties';
  Info.lpFile := PChar(P);
  Info.nShow := SW_SHOW;
  ShellExecuteEx(@Info);
end;

procedure TfrmAgentWorkspace.RootRecentClearAll(Sender: TObject);
begin
  if FRootRecent = nil then Exit;
  FRootRecent.Clear;
  FRootRecentDirty := True;
  FlushRootRecent;
end;

function TfrmAgentWorkspace.IndexPathFor(const APath: string): string;
begin
  Result := '';
  if (FOpenPath = '') or (FIndexPath = '') then Exit;
  if SameText(ExpandFileName(FOpenPath), ExpandFileName(APath)) then
    Result := FIndexPath;
end;

procedure TfrmAgentWorkspace.SendClick(Sender: TObject);
var
  Roots: TStringList;
  I: Integer;
  Root: TAgentRoot;
begin
  if FBusy or FAskBusy then Exit;
  if FRoots.Count = 0 then
  begin
    lblStatus.Caption := TrText('Select a file or folder first.');
    Exit;
  end;
  if Trim(memPrompt.Text) = '' then
  begin
    lblStatus.Caption := TrText('Write a prompt first.');
    Exit;
  end;
  { Plain strings: FRoots entries can be freed while the thread still scans. }
  Roots := TStringList.Create;
  for I := 0 to FRoots.Count - 1 do
  begin
    Root := TAgentRoot(FRoots[I]);
    if Root.Kind = arkFolder then
      Roots.Add('D|' + Root.Path)
    else
      Roots.Add('F|' + Root.Path);
  end;
  FExternal := False;
  StartRun(Roots);
end;

function TfrmAgentWorkspace.RunExternal(const APrompt, APath: string; out AWhy: string): Boolean;
var
  Roots: TStringList;
begin
  Result := False;
  AWhy := '';
  if FBusy or FAskBusy or FApplyRunning then
  begin
    AWhy := TrText('Agent.Bridge.Busy');
    Exit;
  end;
  if (Trim(APath) = '') or not FileExists(APath) then
  begin
    AWhy := TrText('Assistant.Error.NoFileOpen');
    Exit;
  end;
  if Trim(APrompt) = '' then Exit;
  memPrompt.Text := MemoText(Trim(APrompt));
  PromptChange(nil);
  Roots := TStringList.Create;
  Roots.Add('F|' + ExpandFileName(Trim(APath)));
  FExternal := True;
  AgentLog('assistant -> agent: ' + Trim(APrompt) + ' | ' + APath);
  StartRun(Roots);
  Result := True;
end;

procedure TfrmAgentWorkspace.AcceptAllExternal;
begin
  if (FEdits = nil) or (FEdits.Count = 0) or FBusy then Exit;
  if FEdits.Count = 1 then
    AcceptOne(0)
  else
    AcceptAllClick(nil);
end;

procedure TfrmAgentWorkspace.RejectAllExternal;
begin
  if (FEdits = nil) or (FEdits.Count = 0) or FBusy then Exit;
  HoldDecision;
  try
    if not MessageBoxTrYesNo(Format(TrText('Agent.Bridge.RejectConfirm'), [FEdits.Count]), TrText('AI agent')) then
      Exit;
  finally
    ReleaseDecision;
  end;
  if FEdits.Count = 0 then Exit;
  StopDecision;
  FEdits.Clear;
  lstEdits.Items.Clear;
  ShowPreview;
  UpdateResultTabs;
  lblStatus.Caption := TrText('Ready.');
end;

procedure TfrmAgentWorkspace.StopExternal;
begin
  if FBusy and not FApplyRunning then
    StopClick(nil);
end;

procedure TfrmAgentWorkspace.ShowEditsPage;
begin
  if (FEdits <> nil) and (FEdits.Count > 0) then
  begin
    pgResults.ActivePage := tabEdits;
    if lstEdits.ItemIndex < 0 then
    begin
      lstEdits.ItemIndex := 0;
      ShowPreview;
    end;
  end
  else
    pgResults.ActivePage := tabAnswer;
  UpdateEditButtons;
end;

procedure TfrmAgentWorkspace.StartRun(ARoots: TStringList);
var
  P: TAgentPrefs;
  Thr: TAgentWorkThread;
  Link: TAgentLink;
begin
  StoreOptions;
  RememberAgentPrompt(FRecent, memPrompt.Text);
  SaveAgentRecent(FRecent);
  RefreshRecentCombo;
  P := ReadOptions;
  FOpenPath := '';
  FIndexPath := '';
  if Assigned(OnGetOpenFile) then
    FOpenPath := Trim(OnGetOpenFile());
  if FOpenPath <> '' then
    FIndexPath := ResolveWorkingLineIndexPath;
  if (FIndexPath <> '') and not FileExists(FIndexPath) then
    FIndexPath := '';
  P.OpenPath := FOpenPath;
  P.IndexPath := FIndexPath;
  FDecisionExpired := False;
  StopDecision;
  FEdits.Clear;
  FRunAfter.Clear;
  lstEdits.Items.Clear;
  ShowPreview;
  FCancel := 0;
  Link := TAgentLink.Create;
  Link.Wnd := Handle;
  FLink := Link;
  FLinkRef := Link;
  lstIncluded.Items.Clear;
  memAnswer.Clear;
  memRevised.Clear;
  UpdateResultTabs;
  pgResults.ActivePage := tabAnswer;
  SaveSession;
  SetBusy(True);
  lblStatus.Caption := TrText('Working...');
  Thr := TAgentWorkThread.Create(True);
  FThread := Thr;
  Thr.FreeOnTerminate := True;
  Thr.Link := Link;
  Thr.LinkRef := Link;
  Thr.Roots := ARoots;
  Thr.Prompt := memPrompt.Text;
  Thr.Prefs := P;
  Thr.ScanFmt := TrText('Scanning sources... %d');
  Thr.OnTerminate := ThreadDone;
  Thr.Start;
  BeginWait(1, TrText('AI agent') + ' - ' + TrText('Working...'), TrText('Working...'));
end;

procedure TfrmAgentWorkspace.StopClick(Sender: TObject);
begin
  EndWait;
  FCancel := 1;
  if FLink <> nil then
    TAgentLink(FLink).Cancel := 1;
  lblStatus.Caption := TrText('Request stopped.');
end;

procedure TfrmAgentWorkspace.ThreadDone(Sender: TObject);
begin
  if FThread = Sender then
  begin
    FThread := nil;
    FLink := nil;
    FLinkRef := nil;
  end;
  if FWaitKind = 1 then
    EndWait;
  SetBusy(False);
end;

function TfrmAgentWorkspace.IsApplying: Boolean;
begin
  Result := FApplyRunning;
end;

{ Same overlay as the Assistant: never steal an overlay another operation already shows. }
procedure TfrmAgentWorkspace.BeginWait(AKind: Integer; const AMsg, ADetail: string);
begin
  FWaitKind := AKind;
  if FWaitOwned and TfrmSmoothLoading.IsShowing then
    TfrmSmoothLoading.SetWaitTexts(AMsg, ADetail)
  else if not TfrmSmoothLoading.IsShowing then
  begin
    TfrmSmoothLoading.ShowLoading(AMsg, True);
    TfrmSmoothLoading.SnapFullyOpaque;
    TfrmSmoothLoading.SetWaitTexts(AMsg, ADetail);
    TfrmSmoothLoading.SetIndeterminate(False);
    TfrmSmoothLoading.SetCancelVisible(True);
    TfrmSmoothLoading.UpdateProgress(4);
    FWaitOwned := True;
  end;
  if FWaitOwned then
  begin
    tmrWait.Enabled := True;
    TfrmSmoothLoading.FlushPaint;
  end;
end;

procedure TfrmAgentWorkspace.UpdateWaitDetail(const ADetail: string);
begin
  if FWaitOwned and TfrmSmoothLoading.IsShowing and (ADetail <> '') then
    TfrmSmoothLoading.PostDetailFromWorker(ADetail);
end;

procedure TfrmAgentWorkspace.EndWait;
begin
  if tmrWait <> nil then
    tmrWait.Enabled := False;
  if FWaitOwned then
  begin
    FWaitOwned := False;
    if TfrmSmoothLoading.IsShowing then
      TfrmSmoothLoading.HideLoading;
  end;
  FWaitKind := 0;
end;

procedure TfrmAgentWorkspace.WaitTimer(Sender: TObject);
begin
  if not FWaitOwned or not TfrmSmoothLoading.IsShowing then
  begin
    FWaitOwned := False;
    tmrWait.Enabled := False;
    Exit;
  end;
  if TfrmSmoothLoading.CancelRequested then
  begin
    case FWaitKind of
      1:
        StopClick(nil);
      2:
        if FAskBusy then
        begin
          { The gateway call cannot be interrupted: drop its reply instead. }
          if FAskLink <> nil then
            TAgentLink(FAskLink).Wnd := 0;
          FAskLink := nil;
          FAskLinkRef := nil;
          FAskBusy := False;
          SetBusy(FBusy);
        end;
      3:
        FCancel := 1;
    end;
    EndWait;
    lblStatus.Caption := TrText('Assistant.Cancelled');
    Exit;
  end;
  { Model replies have no known duration: creep forward, never wrap to 0. Apply reports real progress. }
  if FWaitKind in [1, 2] then
    TfrmSmoothLoading.CreepProgress(78);
end;

procedure TfrmAgentWorkspace.WMAgentStatus(var Msg: TMessage);
var
  N: TAgentNote;
  TurnNo: Integer;
begin
  N := TAgentNote(Msg.LParam);
  try
    if Copy(N.Text, 1, 5) = 'scan:' then
      lblStatus.Caption := Copy(N.Text, 6, MaxInt)
    else if Copy(N.Text, 1, 5) = 'turn:' then
    begin
      TurnNo := StrToIntDef(Copy(N.Text, 6, MaxInt), 1);
      lblStatus.Caption := Format(TrText('Agent.AskingStep'), [TurnNo]);
    end
    else if N.Text = 'count' then
      lblStatus.Caption := TrText('Counting matches...')
    else if N.Text = 'search' then
      lblStatus.Caption := TrText('Searching...')
    else if N.Text = 'read' then
      lblStatus.Caption := TrText('Reading lines...')
    else if N.Text = 'sql' then
      lblStatus.Caption := TrText('Agent.SqlRunning')
    else if N.Text = 'retry' then
      lblStatus.Caption := TrText('Asking the model again...')
    else if N.Text <> '' then
      lblStatus.Caption := N.Text;
    if FWaitKind = 1 then
      UpdateWaitDetail(lblStatus.Caption);
    if FExternal then
      AgentBridgeNotify(abeStatus, lblStatus.Caption);
  finally
    N.Free;
  end;
end;

procedure TfrmAgentWorkspace.WMAgentFiles(var Msg: TMessage);
var
  N: TAgentNote;
  I: Integer;
begin
  N := TAgentNote(Msg.LParam);
  try
    lstIncluded.Items.BeginUpdate;
    try
      lstIncluded.Items.Clear;
      if N.Files <> nil then
        for I := 0 to N.Files.Count - 1 do
          lstIncluded.Items.Add(N.Files[I]);
    finally
      lstIncluded.Items.EndUpdate;
    end;
    UpdateResultTabs;
    lblStatus.Caption := Format(TrText('Files ready: %d'), [lstIncluded.Items.Count]);
    if (lstIncluded.Items.Count > 0) and (lstIncluded.Items.Count >= StrToIntDef(edtMaxFiles.Text, MaxInt)) then
      lblStatus.Caption := lblStatus.Caption + '  ' + TrText('List capped at the max file count.');
  finally
    N.Free;
  end;
end;

function ShortQuoted(const S: string): string;
begin
  if Length(S) > 60 then
    Result := '"' + Copy(S, 1, 60) + '..."'
  else
    Result := '"' + S + '"';
end;

function ActionSummary(const S: TAssistantChainStep): string;
var
  Id: string;
begin
  Id := LowerCase(S.ActionId);
  Result := TrText('Agent.Action') + ': ' + Id;
  if Id = 'replace_all' then
    Result := Result + ' ' + ShortQuoted(S.FilterText) + ' -> ' + ShortQuoted(S.ReplaceText)
  else if Id = 'split_equal_parts' then
    Result := Result + Format(' (%d)', [S.Parts])
  else if Id = 'extract_file_parts' then
    Result := Result + Format(' (%d-%d / %d)', [S.PartFrom, S.PartTo, S.TotalParts])
  else if Id = 'goto_line' then
    Result := Result + ' ' + IntToStr(S.LineNo)
  else if S.FilterText <> '' then
    Result := Result + ' ' + ShortQuoted(S.FilterText);
end;

function TfrmAgentWorkspace.EditCaption(E: TAgentEdit): string;
var
  What: string;
begin
  if E.Kind = aekAction then
  begin
    Result := ActionSummary(E.Action);
    if E.Path <> '' then
      Result := ExtractFileName(E.Path) + '  -  ' + Result;
    if E.MatchCount >= 0 then
      Result := Result + '  -  ' + Format(TrText('Agent.TotalShort'), [E.MatchCount]);
    Exit;
  end;
  case E.Kind of
    aekReplace:
      if (E.LineStart = E.LineEnd) and (E.NewLineCount = 1) then
        What := Format(TrText('Agent.ChangeLine'), [E.LineStart])
      else
        What := Format(TrText('Replace lines %d-%d with %d line(s)'), [E.LineStart, E.LineEnd, E.NewLineCount]);
    aekInsert:
      What := Format(TrText('Insert %d line(s) before line %d'), [E.NewLineCount, E.LineStart]);
    aekDelete:
      if E.LineStart = E.LineEnd then
        What := Format(TrText('Agent.DeleteLine'), [E.LineStart])
      else
        What := Format(TrText('Delete lines %d-%d'), [E.LineStart, E.LineEnd]);
  else
    if E.LineEnd > 0 then
      What := Format(TrText('Anonymize lines %d-%d'), [E.LineStart, E.LineEnd])
    else if E.LineStart > 1 then
      What := Format(TrText('Anonymize from line %d to the end'), [E.LineStart])
    else
      What := TrText('Anonymize the whole file');
  end;
  Result := ExtractFileName(E.Path) + '  -  ' + What;
end;

procedure TfrmAgentWorkspace.RefreshEditCaptions;
var
  I, Keep: Integer;
begin
  Keep := lstEdits.ItemIndex;
  lstEdits.Items.BeginUpdate;
  try
    lstEdits.Items.Clear;
    for I := 0 to FEdits.Count - 1 do
      lstEdits.Items.Add(EditCaption(TAgentEdit(FEdits[I])));
  finally
    lstEdits.Items.EndUpdate;
  end;
  if Keep >= lstEdits.Items.Count then
    Keep := lstEdits.Items.Count - 1;
  lstEdits.ItemIndex := Keep;
  UpdateResultTabs;
end;

procedure TfrmAgentWorkspace.WMAgentEdit(var Msg: TMessage);
var
  N: TAgentNote;
begin
  N := TAgentNote(Msg.LParam);
  try
    if (N.Edit = nil) or (FEdits = nil) then Exit;
    FEdits.Add(N.Edit);
    lstEdits.Items.Add(EditCaption(N.Edit));
    N.Edit := nil;
    UpdateResultTabs;
  finally
    N.Free;
  end;
end;

procedure TfrmAgentWorkspace.WMAgentRunAfter(var Msg: TMessage);
var
  N: TAgentNote;
begin
  N := TAgentNote(Msg.LParam);
  try
    if (N.Edit = nil) or (FRunAfter = nil) then Exit;
    FRunAfter.Add(N.Edit);
    N.Edit := nil;
  finally
    N.Free;
  end;
end;

{ Main thread. Each item is a TAgentEdit of kind aekAction. A step that needs another file
  loaded first opens it and leaves itself and the rest to the Assistant chain (runs after Read). }
procedure TfrmAgentWorkspace.RunCoreActions(AList: TObjectList);
var
  I, K, N: Integer;
  E: TAgentEdit;
  Cur: string;
  Chain: array[0..ASSISTANT_MAX_CHAIN - 1] of TAssistantChainStep;
  OpenStep: TAssistantChainStep;
begin
  if (AList = nil) or (AList.Count = 0) then Exit;
  Cur := '';
  if Assigned(OnGetOpenFile) then
    Cur := Trim(OnGetOpenFile());
  for I := 0 to AList.Count - 1 do
  begin
    E := TAgentEdit(AList[I]);
    if AgentActionIsExtra(E.Action.ActionId) then
    begin
      if Assigned(OnRunExtraAction) then
        OnRunExtraAction(E.Action.ActionId, E.Action.Path);
      Continue;
    end;
    if SameText(E.Action.ActionId, 'open_and_read_file') or
       (AgentActionNeedsOpenFile(E.Action.ActionId) and (E.Action.Path <> '') and
        ((Cur = '') or not SameText(ExpandFileName(Cur), ExpandFileName(E.Action.Path)))) then
    begin
      N := 0;
      if SameText(E.Action.ActionId, 'open_and_read_file') then
        K := I + 1
      else
        K := I;
      while (K < AList.Count) and (N < ASSISTANT_MAX_CHAIN) do
      begin
        Chain[N] := TAgentEdit(AList[K]).Action;
        Inc(N);
        Inc(K);
      end;
      OpenStep := Default(TAssistantChainStep);
      OpenStep.ActionId := 'open_and_read_file';
      OpenStep.Path := E.Action.Path;
      AgentLog('run action ' + E.Action.ActionId + ': open ' + E.Action.Path + ' first (open=' + Cur + ')');
      AssistantHostSetChain(Chain, N, N > 0);
      AssistantHostExecuteAction(OpenStep);
      Exit;
    end;
    AgentLog('run action ' + E.Action.ActionId + ' needle=' + E.Action.FilterText);
    AssistantHostExecuteAction(E.Action);
  end;
end;

procedure TfrmAgentWorkspace.AcceptAction(AIndex: Integer);
var
  E: TAgentEdit;
  One: TObjectList;
  I, Dropped: Integer;
  Path: string;
begin
  E := TAgentEdit(FEdits[AIndex]);
  { replace_all asks its own confirmation (with the "cannot be undone" warning). }
  if not SameText(E.Action.ActionId, 'replace_all') then
    if not MessageBoxTrYesNo(TrText('Agent.ActionConfirm') + #13#10#13#10 + EditCaption(E),
      TrText('AI agent')) then
      Exit;
  Path := E.Path;
  if (Path <> '') and Assigned(OnBeforeWrite) and AgentActionMutatesFile(E.Action.ActionId) and
     not OnBeforeWrite(Path) then
    Exit;
  One := TObjectList.Create(True);
  try
    One.Add(E.Clone);
    FEdits.Delete(AIndex);
    Dropped := 0;
    if (Path <> '') and AgentActionMutatesFile(TAgentEdit(One[0]).Action.ActionId) then
    begin
      { Lines in the file will move: line proposals on it no longer point at the right text. }
      for I := FEdits.Count - 1 downto 0 do
        if (TAgentEdit(FEdits[I]).Kind <> aekAction) and SameText(TAgentEdit(FEdits[I]).Path, Path) then
        begin
          FEdits.Delete(I);
          Inc(Dropped);
        end;
      if IndexPathFor(Path) <> '' then
        FIndexPath := '';
    end;
    RefreshEditCaptions;
    ShowPreview;
    RestartDecision;
    lblStatus.Caption := TrText('Agent.ActionStarted');
    if Dropped > 0 then
      lblStatus.Caption := lblStatus.Caption + '  ' +
        Format(TrText('%d proposal(s) overlapped the applied change and were removed.'), [Dropped]);
    RunCoreActions(One);
  finally
    One.Free;
  end;
end;

procedure TfrmAgentWorkspace.WMAgentDone(var Msg: TMessage);
var
  N: TAgentNote;
  Q: Integer;
begin
  N := TAgentNote(Msg.LParam);
  if FWaitKind = 1 then
    EndWait;
  try
    if Copy(N.Text, 1, 17) = 'proposals_queued=' then
    begin
      Q := StrToIntDef(Copy(N.Text, 18, MaxInt), 0);
      memAnswer.Text := Format(TrText('%d change(s) proposed. Review them in Proposed edits.'), [Q]);
    end
    else if N.Text <> '' then
      memAnswer.Text := MemoText(StringReplace(N.Text, '**', '', [rfReplaceAll]))
    else if (N.Err <> '') and (N.Err <> 'stopped') and (N.Err <> 'nofiles') and (N.Err <> 'turn limit') then
      memAnswer.Text := MemoText(FriendlyAiError(N.Err));
    if N.Revised <> '' then
      memRevised.Text := MemoText(N.Revised);
    if N.Err = '' then
      lblStatus.Caption := TrText('Ready.')
    else if N.Err = 'stopped' then
      lblStatus.Caption := TrText('Request stopped.')
    else if N.Err = 'nofiles' then
      lblStatus.Caption := TrText('No files in the selection.')
    else if N.Err = 'turn limit' then
      lblStatus.Caption := TrText('The model stopped after the turn limit.')
    else
      lblStatus.Caption := FriendlyAiError(N.Err);
    if lstEdits.Items.Count > 0 then
    begin
      pgResults.ActivePage := tabEdits;
      if lstEdits.ItemIndex < 0 then
      begin
        lstEdits.ItemIndex := 0;
        ShowPreview;
      end;
    end
    else
      pgResults.ActivePage := tabAnswer;
    SetBusy(False);
    RestartDecision;
    SaveSession;
    if FExternal then
    begin
      if N.Err = '' then
        AgentBridgeNotify(abeDone, memAnswer.Text, '', FEdits.Count)
      else
        AgentBridgeNotify(abeDone, memAnswer.Text, lblStatus.Caption, FEdits.Count);
    end;
    if (FRunAfter <> nil) and (FRunAfter.Count > 0) then
    begin
      if (N.Err = '') or (N.Err = 'turn limit') then
      begin
        lblStatus.Caption := Format(TrText('Agent.ActionsRun'), [FRunAfter.Count]);
        RunCoreActions(FRunAfter);
      end;
      FRunAfter.Clear;
    end;
  finally
    N.Free;
  end;
end;

function TfrmAgentWorkspace.SelectedEdit: TAgentEdit;
begin
  Result := nil;
  if (lstEdits.ItemIndex < 0) or (lstEdits.ItemIndex >= FEdits.Count) then Exit;
  Result := TAgentEdit(FEdits[lstEdits.ItemIndex]);
end;

function StripLineNumbers(const AText: string): TStringList;
var
  I, Bar: Integer;
begin
  Result := TStringList.Create;
  Result.Text := AText;
  for I := Result.Count - 1 downto 0 do
  begin
    Bar := Pos('|', Result[I]);
    if (Bar > 0) and (Bar < 14) and (StrToInt64Def(Trim(Copy(Result[I], 1, Bar - 1)), -1) >= 0) then
      Result[I] := Copy(Result[I], Bar + 1, MaxInt)
    else
      Result.Delete(I);
  end;
end;

const
  { Preview row kinds (Objects of FPreviewRows / list items); PV_CONT marks a wrapped continuation. }
  PV_HEAD = 0;
  PV_CTX = 1;
  PV_DEL = 2;
  PV_ADD = 3;
  PV_INFO = 4;
  PV_CONT = 16;

  { One preview row as text: kind digit, gutter, TAB, line text (cut so a giant line cannot flood the view). }
  PV_MAX_CHARS = 2000;

type
  TPreviewThread = class(TThread)
  public
    Link: TAgentLink;
    LinkRef: IInterface;
    Edit: TAgentEdit;
    IndexPath: string;
    Key: string;
    Gen: Integer;
    destructor Destroy; override;
    procedure Execute; override;
  end;

procedure PvRow(AList: TStrings; AKind: Integer; const AGutter, AText: string);
var
  T: string;
begin
  T := StringReplace(AText, #9, '    ', [rfReplaceAll]);
  if Length(T) > PV_MAX_CHARS then
    T := Copy(T, 1, PV_MAX_CHARS) + ' ...';
  AList.Add(Chr(Ord('0') + AKind) + AGutter + #9 + T);
end;

procedure PvMore(AList: TStrings; AMore: Int64);
begin
  if AMore > 0 then
    PvRow(AList, PV_INFO, '', Format(TrText('Agent.PreviewMore'), [FormatFloat('#,##0', AMore)]));
end;

{ File version + line range: a cached preview is reused only while both are unchanged. }
function PreviewKeyFor(E: TAgentEdit): string;
var
  Fad: TWin32FileAttributeData;
begin
  Result := Format('%s|%d|%d|%d', [E.Path, Ord(E.Kind), E.LineStart, E.LineEnd]);
  if GetFileAttributesEx(PChar(E.Path), GetFileExInfoStandard, @Fad) then
    Result := Result + Format('|%d|%d|%d', [Fad.nFileSizeHigh, Fad.nFileSizeLow,
      Int64(Fad.ftLastWriteTime.dwHighDateTime) shl 32 or Fad.ftLastWriteTime.dwLowDateTime]);
end;

{ Rows for the change preview. Reads at most a few hundred lines; runs on a worker thread. }
function BuildPreviewRows(E: TAgentEdit; const Ip: string; ACancel: PInteger): string;
var
  SL, LeftL, RightL: TStringList;
  Diff: TList;
  I, Shown, Bar: Integer;
  LNo, Total: Int64;
  Rec: PFFDiffRow;
  S: string;
begin
  SL := TStringList.Create;
  try
    SL.LineBreak := #10;
    case E.Kind of
      aekAction:
        PvRow(SL, PV_INFO, '', TrText('Agent.ActionPreview'));
      aekInsert:
        begin
          if E.LineStart > 1 then
          begin
            LeftL := StripLineNumbers(AgentReadLineWindow(E.Path, E.LineStart - 1, E.LineStart - 1, 1, Ip, ACancel));
            try
              for I := 0 to LeftL.Count - 1 do
                PvRow(SL, PV_CTX, IntToStr(E.LineStart - 1), LeftL[I]);
            finally
              LeftL.Free;
            end;
          end;
          RightL := AgentSplitLines(E.NewText);
          try
            if RightL.Count = 0 then
              RightL.Add('');
            for I := 0 to Min(RightL.Count, PREVIEW_LINES) - 1 do
              PvRow(SL, PV_ADD, '', RightL[I]);
            PvMore(SL, RightL.Count - PREVIEW_LINES);
          finally
            RightL.Free;
          end;
          LeftL := StripLineNumbers(AgentReadLineWindow(E.Path, E.LineStart, E.LineStart, 1, Ip, ACancel));
          try
            for I := 0 to LeftL.Count - 1 do
              PvRow(SL, PV_CTX, IntToStr(E.LineStart), LeftL[I]);
          finally
            LeftL.Free;
          end;
        end;
      aekDelete:
        begin
          LeftL := StripLineNumbers(AgentReadLineWindow(E.Path, E.LineStart, E.LineEnd, PREVIEW_LINES, Ip, ACancel));
          try
            for I := 0 to LeftL.Count - 1 do
              PvRow(SL, PV_DEL, IntToStr(E.LineStart + I), LeftL[I]);
            PvMore(SL, (E.LineEnd - E.LineStart + 1) - LeftL.Count);
          finally
            LeftL.Free;
          end;
        end;
      aekAnonymize:
        begin
          if AnonOptionsText(E.Anon) <> '' then
            PvRow(SL, PV_INFO, '', Format(TrText('Options: %s'), [AnonOptionsText(E.Anon)]));
          LeftL := TStringList.Create;
          try
            LeftL.Text := AgentAnonPreview(E, Ip, PREVIEW_LINES, ACancel);
            { "- N| old", "+ N| new", "  N| same" }
            for I := 0 to LeftL.Count - 1 do
            begin
              S := LeftL[I];
              Bar := Pos('| ', S);
              if (Length(S) < 3) or (Bar < 3) then
                PvRow(SL, PV_CTX, '', S)
              else if S[1] = '-' then
                PvRow(SL, PV_DEL, Trim(Copy(S, 3, Bar - 3)), Copy(S, Bar + 2, MaxInt))
              else if S[1] = '+' then
                PvRow(SL, PV_ADD, '', Copy(S, Bar + 2, MaxInt))
              else
                PvRow(SL, PV_CTX, Trim(Copy(S, 3, Bar - 3)), Copy(S, Bar + 2, MaxInt));
            end;
            if E.LineEnd > 0 then
              PvMore(SL, (E.LineEnd - E.LineStart + 1) - PREVIEW_LINES);
          finally
            LeftL.Free;
          end;
        end;
    else
      begin
        Total := E.LineEnd - E.LineStart + 1;
        LeftL := StripLineNumbers(AgentReadLineWindow(E.Path, E.LineStart, E.LineEnd, PREVIEW_LINES, Ip, ACancel));
        RightL := AgentSplitLines(E.NewText);
        Diff := TList.Create;
        try
          while RightL.Count > PREVIEW_LINES do
            RightL.Delete(RightL.Count - 1);
          FFBuildLineDiffRows(LeftL, RightL, 200, Diff);
          Shown := Min(Diff.Count, PREVIEW_LINES * 2);
          LNo := E.LineStart;
          for I := 0 to Shown - 1 do
          begin
            Rec := PFFDiffRow(Diff[I]);
            case Rec.Kind of
              ffdkInsert:
                PvRow(SL, PV_ADD, '', Rec.RText);
              ffdkDelete:
                begin
                  PvRow(SL, PV_DEL, IntToStr(LNo), Rec.LText);
                  Inc(LNo);
                end;
              ffdkChange:
                begin
                  PvRow(SL, PV_DEL, IntToStr(LNo), Rec.LText);
                  PvRow(SL, PV_ADD, '', Rec.RText);
                  Inc(LNo);
                end;
            else
              PvRow(SL, PV_CTX, IntToStr(LNo), Rec.LText);
              Inc(LNo);
            end;
          end;
          PvMore(SL, Max(Total - LeftL.Count, Int64(Diff.Count - Shown)));
        finally
          for I := 0 to Diff.Count - 1 do
            Dispose(PFFDiffRow(Diff[I]));
          Diff.Free;
          LeftL.Free;
          RightL.Free;
        end;
      end;
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

destructor TPreviewThread.Destroy;
begin
  Edit.Free;
  inherited;
end;

procedure TPreviewThread.Execute;
var
  N: TAgentNote;
begin
  N := TAgentNote.Create;
  try
    N.Text := BuildPreviewRows(Edit, IndexPath, @Link.Cancel);
    N.Err := Key;
    N.Revised := IntToStr(Gen);
  except
    on Ex: Exception do
    begin
      N.Text := Chr(Ord('0') + PV_INFO) + #9 + Ex.Message;
      N.Revised := IntToStr(Gen);
    end;
  end;
  if Link.Cancel <> 0 then
    N.Free
  else
    PostNote(Link.Wnd, WM_AGENT_PREVIEW, N);
end;

procedure TfrmAgentWorkspace.PvAdd(AKind: Integer; const AGutter, AText: string);
begin
  FPreviewRows.AddObject(AGutter + #9 + AText, TObject(AKind));
end;

{ Loads serialized rows (see PvRow) under the header line and redraws. }
procedure LoadPreviewRows(ARows: TStringList; const AText: string);
var
  SL: TStringList;
  I: Integer;
  S: string;
begin
  SL := TStringList.Create;
  try
    SL.LineBreak := #10;
    SL.Text := AText;
    for I := 0 to SL.Count - 1 do
    begin
      S := SL[I];
      if S <> '' then
        ARows.AddObject(Copy(S, 2, MaxInt), TObject(Ord(S[1]) - Ord('0')));
    end;
  finally
    SL.Free;
  end;
end;

procedure TfrmAgentWorkspace.WMAgentPreview(var Msg: TMessage);
var
  N: TAgentNote;
  E: TAgentEdit;
begin
  N := TAgentNote(Msg.LParam);
  try
    if StrToIntDef(N.Revised, -1) <> FPreviewGen then Exit;
    E := SelectedEdit;
    if E = nil then Exit;
    if N.Err <> '' then
    begin
      E.PreviewText := N.Text;
      E.PreviewKey := N.Err;
    end;
    FPreviewRows.Clear;
    PvAdd(PV_HEAD, '', EditCaption(E));
    LoadPreviewRows(FPreviewRows, N.Text);
    FillPreview(lstPreview);
  finally
    N.Free;
  end;
end;

procedure TfrmAgentWorkspace.ShowPreview;
var
  E: TAgentEdit;
  Key: string;
  Link: TAgentLink;
  T: TPreviewThread;
begin
  if (FPreviewRows = nil) or (lstPreview = nil) then Exit;
  Inc(FPreviewGen);
  if FPreviewLink <> nil then
    TAgentLink(FPreviewLink).Cancel := 1;
  FPreviewLink := nil;
  FPreviewLinkRef := nil;
  FPreviewRows.Clear;
  E := SelectedEdit;
  if E = nil then
  begin
    FillPreview(lstPreview);
    Exit;
  end;
  lstPreview.Hint := E.Path + #13#10 + TrText('Agent.PreviewZoomHint');
  PvAdd(PV_HEAD, '', EditCaption(E));
  if E.Kind = aekAction then
  begin
    PvAdd(PV_INFO, '', TrText('Agent.ActionPreview'));
    FillPreview(lstPreview);
    Exit;
  end;
  Key := PreviewKeyFor(E);
  if (E.PreviewKey = Key) and (E.PreviewText <> '') then
  begin
    LoadPreviewRows(FPreviewRows, E.PreviewText);
    FillPreview(lstPreview);
    Exit;
  end;
  PvAdd(PV_INFO, '', TrText('Agent.PreviewLoading'));
  FillPreview(lstPreview);
  Link := TAgentLink.Create;
  Link.Wnd := Handle;
  FPreviewLink := Link;
  FPreviewLinkRef := Link;
  T := TPreviewThread.Create(True);
  T.FreeOnTerminate := True;
  T.Link := Link;
  T.LinkRef := Link;
  T.Edit := E.Clone;
  T.IndexPath := IndexPathFor(E.Path);
  T.Key := Key;
  T.Gen := FPreviewGen;
  T.Start;
end;

{ Wraps FPreviewRows to the list width: no horizontal scrolling, long lines continue on the next rows. }
procedure TfrmAgentWorkspace.FillPreview(AList: TListBox);
var
  I, Kind, P, Fit, Avail, W, MaxG: Integer;
  S, G, T: string;
  Sz: TSize;
  First: Boolean;
  C: TCanvas;
begin
  if (AList = nil) or (FPreviewRows = nil) or (AList.Parent = nil) then Exit;
  AList.HandleNeeded;
  C := AList.Canvas;
  C.Font.Assign(AList.Font);
  AList.ItemHeight := C.TextHeight('Wg') + Dpi(6);
  MaxG := 3;
  for I := 0 to FPreviewRows.Count - 1 do
    MaxG := Max(MaxG, Pos(#9, FPreviewRows[I]) - 1);
  AList.Tag := C.TextWidth(StringOfChar('0', MaxG)) + Dpi(26);
  W := AList.ClientWidth - GetSystemMetrics(SM_CXVSCROLL) - Dpi(10);
  AList.Items.BeginUpdate;
  try
    AList.Items.Clear;
    for I := 0 to FPreviewRows.Count - 1 do
    begin
      Kind := NativeInt(FPreviewRows.Objects[I]);
      S := FPreviewRows[I];
      P := Pos(#9, S);
      G := Copy(S, 1, P - 1);
      T := Copy(S, P + 1, MaxInt);
      C.Font.Assign(AList.Font);
      if Kind = PV_HEAD then
      begin
        C.Font.Name := 'Segoe UI';
        C.Font.Style := [fsBold];
      end;
      if Kind in [PV_HEAD, PV_INFO] then
        Avail := W
      else
        Avail := W - AList.Tag;
      Avail := Max(Avail, Dpi(60));
      First := True;
      repeat
        Fit := Length(T);
        if Fit > 0 then
        begin
          GetTextExtentExPoint(C.Handle, PChar(T), Length(T), Avail, @Fit, nil, Sz);
          if Fit < 1 then
            Fit := 1;
          if Fit < Length(T) then
          begin
            P := Fit;
            while (P > Fit div 2) and not CharInSet(T[P], [' ', ';', ',', '\', '/', '|']) do
              Dec(P);
            if P > Fit div 2 then
              Fit := P;
          end;
        end;
        if First then
          AList.Items.AddObject(G + #9 + Copy(T, 1, Fit), TObject(Kind))
        else
          AList.Items.AddObject(#9 + Copy(T, 1, Fit), TObject(Kind or PV_CONT));
        Delete(T, 1, Fit);
        First := False;
      until T = '';
    end;
  finally
    AList.Items.EndUpdate;
  end;
end;

procedure TfrmAgentWorkspace.PreviewDrawItem(Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var
  LB: TListBox;
  C: TCanvas;
  Code, Kind, P, Y, GW: Integer;
  S, G, T, Sign: string;
  Bg, GBg, SignColor: TColor;
  GR: TRect;
begin
  LB := TListBox(Control);
  C := LB.Canvas;
  Code := NativeInt(LB.Items.Objects[Index]);
  Kind := Code and 15;
  S := LB.Items[Index];
  P := Pos(#9, S);
  G := Copy(S, 1, P - 1);
  T := Copy(S, P + 1, MaxInt);
  C.Font.Assign(LB.Font);
  Y := Rect.Top + Dpi(3);
  Sign := '';
  SignColor := clGray;
  GBg := $00F4F4F4;
  case Kind of
    PV_HEAD: Bg := $00F7EEE6;
    PV_DEL:
      begin
        Bg := $00EEEEFF;
        GBg := $00DADAFF;
        Sign := '-';
        SignColor := $002828B4;
      end;
    PV_ADD:
      begin
        Bg := $00E6F8E8;
        GBg := $00C8EECB;
        Sign := '+';
        SignColor := $00287D28;
      end;
  else
    Bg := clWhite;
  end;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Bg;
  C.FillRect(Rect);
  if Kind in [PV_HEAD, PV_INFO] then
  begin
    C.Brush.Style := bsClear;
    if Kind = PV_HEAD then
    begin
      C.Font.Name := 'Segoe UI';
      C.Font.Style := [fsBold];
      C.Font.Color := $00703C1E;
    end
    else
    begin
      C.Font.Style := [fsItalic];
      C.Font.Color := $00707070;
    end;
    C.TextOut(Rect.Left + Dpi(6), Y, T);
    Exit;
  end;
  GW := LB.Tag;
  GR := Rect;
  GR.Right := Rect.Left + GW;
  C.Brush.Color := GBg;
  C.FillRect(GR);
  C.Brush.Style := bsClear;
  if (Code and PV_CONT) = 0 then
  begin
    C.Font.Color := $00909090;
    C.TextOut(GR.Right - Dpi(20) - C.TextWidth(G), Y, G);
    if Sign <> '' then
    begin
      C.Font.Color := SignColor;
      C.Font.Style := [fsBold];
      C.TextOut(GR.Right - Dpi(14), Y, Sign);
      C.Font.Style := [];
    end;
  end;
  if Kind = PV_CTX then
    C.Font.Color := $00606060
  else
    C.Font.Color := $00202020;
  C.TextOut(GR.Right + Dpi(6), Y, T);
end;

procedure TfrmAgentWorkspace.PreviewPaneResize(Sender: TObject);
begin
  FillPreview(lstPreview);
end;

procedure TfrmAgentWorkspace.PreviewClick(Sender: TObject);
begin
  TListBox(Sender).ItemIndex := -1;
end;

procedure TfrmAgentWorkspace.ZoomResize(Sender: TObject);
begin
  FillPreview(TListBox(TForm(Sender).FindComponent('lstZoom')));
end;

{ Large read-only view of the selected change, with Accept / Reject right there. }
procedure TfrmAgentWorkspace.PreviewZoom(Sender: TObject);
var
  E: TAgentEdit;
  F: TForm;
  Bar: TsPanel;
  L: TListBox;
  B: TsButton;
  R, X: Integer;

  function AddBtn(const ACaption: string; AResult: Integer): TsButton;
  begin
    Result := TsButton.Create(F);
    Result.Parent := Bar;
    Result.Caption := ACaption;
    Result.ModalResult := AResult;
    Result.Width := Max(Dpi(110), TextPx(Result.Font, ACaption) + Dpi(30));
    Result.Height := Dpi(32);
    Dec(X, Result.Width + Dpi(8));
    Result.SetBounds(X, Dpi(8), Result.Width, Result.Height);
    Result.Anchors := [akTop, akRight];
  end;

begin
  E := SelectedEdit;
  if E = nil then Exit;
  F := TForm.Create(nil);
  try
    F.Caption := TrText('Edit preview') + '  -  ' + EditCaption(E);
    F.Position := poScreenCenter;
    F.BorderIcons := [biSystemMenu, biMaximize];
    F.Width := Screen.WorkAreaWidth * 3 div 4;
    F.Height := Screen.WorkAreaHeight * 2 div 3;
    F.Font.Name := 'Segoe UI';
    F.Font.Size := 9;

    Bar := TsPanel.Create(F);
    Bar.Parent := F;
    Bar.BevelOuter := bvNone;
    Bar.Align := alBottom;
    Bar.Height := Dpi(48);
    X := Bar.ClientWidth;
    B := AddBtn(TrText('Close'), mrCancel);
    B.Cancel := True;
    B := AddBtn(btnReject.Caption, mrNo);
    B.Enabled := btnReject.Enabled;
    B := AddBtn(btnAccept.Caption, mrYes);
    B.Enabled := btnAccept.Enabled;
    B.Default := B.Enabled;

    L := TListBox.Create(F);
    L.Name := 'lstZoom';
    L.Parent := F;
    L.AlignWithMargins := True;
    L.Margins.SetBounds(8, 8, 8, 0);
    L.Align := alClient;
    L.Style := lbOwnerDrawFixed;
    L.IntegralHeight := False;
    L.TabStop := False;
    L.ParentFont := False;
    L.Font.Name := 'Consolas';
    L.Font.Size := 11;
    L.Color := clWhite;
    L.DoubleBuffered := True;
    L.OnDrawItem := PreviewDrawItem;
    L.OnClick := PreviewClick;
    FillPreview(L);
    F.OnResize := ZoomResize;

    FZoomForm := F;
    FZoomCaption := F.Caption;
    UpdateDecisionLabel;
    R := F.ShowModal;
  finally
    FZoomForm := nil;
    F.Free;
  end;
  if R = mrYes then
    AcceptClick(Self)
  else if R = mrNo then
    RejectClick(Self);
end;

procedure TfrmAgentWorkspace.ShowFullText(const ATitle, AText: string);
var
  F: TForm;
  Bar: TsPanel;
  M: TsMemo;
  B: TsButton;
  X: Integer;

  function AddBtn(const ACaption: string; AResult: Integer): TsButton;
  begin
    Result := TsButton.Create(F);
    Result.Parent := Bar;
    Result.Caption := ACaption;
    Result.ModalResult := AResult;
    Result.Width := Max(Dpi(100), TextPx(Result.Font, ACaption) + Dpi(30));
    Result.Height := Dpi(30);
    Dec(X, Result.Width + Dpi(8));
    Result.SetBounds(X, Dpi(8), Result.Width, Result.Height);
    Result.Anchors := [akTop, akRight];
  end;

begin
  if Trim(AText) = '' then Exit;
  F := TForm.Create(nil);
  try
    F.Caption := ATitle;
    F.Position := poScreenCenter;
    F.BorderIcons := [biSystemMenu, biMaximize];
    F.Width := Min(Dpi(640), Screen.WorkAreaWidth - Dpi(40));
    F.Height := Min(Dpi(360), Screen.WorkAreaHeight - Dpi(40));
    F.Font.Name := 'Segoe UI';
    F.Font.Size := 9;
    Bar := TsPanel.Create(F);
    Bar.Parent := F;
    Bar.BevelOuter := bvNone;
    Bar.Align := alBottom;
    Bar.Height := Dpi(46);
    X := Bar.ClientWidth;
    B := AddBtn(TrText('Close'), mrCancel);
    B.Cancel := True;
    B := AddBtn(TrText('Agent.ToolCopy'), mrOk);
    B.Default := True;
    M := TsMemo.Create(F);
    M.Parent := F;
    M.AlignWithMargins := True;
    M.Margins.SetBounds(8, 8, 8, 0);
    M.Align := alClient;
    M.ReadOnly := True;
    M.WordWrap := True;
    M.ScrollBars := ssVertical;
    M.Font.Name := 'Segoe UI';
    M.Font.Size := 10;
    M.Text := MemoText(AText);
    if F.ShowModal = mrOk then
    begin
      Clipboard.AsText := AText;
      lblStatus.Caption := TrText('Agent.Copied');
    end;
  finally
    F.Free;
  end;
end;

{ Whole text behind a control that may show it cut: the note, the edit under the mouse, the preview rows. }
function TfrmAgentWorkspace.FullTextOf(AComp: TComponent): string;
var
  SL: TStringList;
  I, P: Integer;
  S: string;
begin
  Result := '';
  if AComp = lblEditsNote then
    Result := lblEditsNote.Caption
  else if AComp = lstEdits then
  begin
    if (lstEdits.ItemIndex >= 0) and (lstEdits.ItemIndex < lstEdits.Items.Count) then
      Result := lstEdits.Items[lstEdits.ItemIndex];
  end
  else if (AComp = lstPreview) and (FPreviewRows <> nil) then
  begin
    SL := TStringList.Create;
    try
      for I := 0 to FPreviewRows.Count - 1 do
      begin
        S := FPreviewRows[I];
        P := Pos(#9, S);
        case NativeInt(FPreviewRows.Objects[I]) of
          PV_DEL: S := '- ' + Copy(S, 1, P - 1) + ' | ' + Copy(S, P + 1, MaxInt);
          PV_ADD: S := '+ ' + Copy(S, P + 1, MaxInt);
          PV_CTX: S := '  ' + Copy(S, 1, P - 1) + ' | ' + Copy(S, P + 1, MaxInt);
        else
          S := Copy(S, P + 1, MaxInt);
        end;
        SL.Add(S);
      end;
      Result := SL.Text;
    finally
      SL.Free;
    end;
  end;
end;

procedure TfrmAgentWorkspace.FullTextClick(Sender: TObject);
begin
  ShowFullText(TrText('Agent.FullText'), FullTextOf(TComponent(Sender)));
end;

procedure TfrmAgentWorkspace.FullTextViewClick(Sender: TObject);
begin
  ShowFullText(TrText('Agent.FullText'), FullTextOf(mnuFullText.PopupComponent));
end;

procedure TfrmAgentWorkspace.FullTextCopyClick(Sender: TObject);
var
  S: string;
begin
  S := FullTextOf(mnuFullText.PopupComponent);
  if S = '' then Exit;
  Clipboard.AsText := S;
  lblStatus.Caption := TrText('Agent.Copied');
end;

{ Hint with the whole caption when an edit does not fit the list width. }
procedure TfrmAgentWorkspace.EditsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  I := lstEdits.ItemAtPos(Point(X, Y), True);
  if I = FHintItem then Exit;
  FHintItem := I;
  lstEdits.Canvas.Font.Assign(lstEdits.Font);
  if (I >= 0) and (lstEdits.Canvas.TextWidth(lstEdits.Items[I]) + Dpi(10) > lstEdits.ClientWidth) then
    lstEdits.Hint := lstEdits.Items[I] + #13#10 + TrText('Agent.PreviewZoomHint')
  else
    lstEdits.Hint := TrText('Agent.PreviewZoomHint');
  Application.CancelHint;
end;

{ Right-click selects the edit under the mouse, so the menu acts on it. }
procedure TfrmAgentWorkspace.EditsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  I: Integer;
begin
  if Button <> mbRight then Exit;
  I := lstEdits.ItemAtPos(Point(X, Y), True);
  if (I >= 0) and (I <> lstEdits.ItemIndex) then
  begin
    lstEdits.ItemIndex := I;
    ShowPreview;
  end;
end;

procedure TfrmAgentWorkspace.EditsClick(Sender: TObject);
begin
  ShowPreview;
  UpdateEditButtons;
end;

procedure TfrmAgentWorkspace.RemoveEditAt(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FEdits.Count) then Exit;
  FEdits.Delete(AIndex);
  lstEdits.Items.Delete(AIndex);
  if AIndex < lstEdits.Items.Count then
    lstEdits.ItemIndex := AIndex
  else
    lstEdits.ItemIndex := lstEdits.Items.Count - 1;
  ShowPreview;
  UpdateResultTabs;
  RestartDecision;
end;

procedure TfrmAgentWorkspace.RestartDecision;
begin
  if (tmrDecision = nil) or (FEdits = nil) then Exit;
  if FEdits.Count = 0 then
  begin
    StopDecision;
    Exit;
  end;
  FDecisionExpired := False;
  FDecisionTotalMs := PrefAgentDecisionSeconds * 1000;
  FDecisionLeftMs := FDecisionTotalMs;
  FDecisionTick := GetTickCount;
  tmrDecision.Enabled := False;
  tmrDecision.Enabled := True;
  UpdateDecisionLabel;
end;

procedure TfrmAgentWorkspace.StopDecision;
begin
  if tmrDecision <> nil then
    tmrDecision.Enabled := False;
  FDecisionLeftMs := 0;
  UpdateDecisionLabel;
end;

function TfrmAgentWorkspace.DecisionSecondsLeft: Integer;
begin
  Result := (Max(FDecisionLeftMs, 0) + 999) div 1000;
end;

procedure TfrmAgentWorkspace.HoldDecision;
begin
  Inc(FDecisionHold);
end;

procedure TfrmAgentWorkspace.ReleaseDecision;
begin
  if FDecisionHold > 0 then
    Dec(FDecisionHold);
end;

procedure TfrmAgentWorkspace.UpdateDecisionLabel;
var
  Show, Counting: Boolean;
  S: string;
begin
  if (pbExpire = nil) or (tmrDecision = nil) then Exit;
  Counting := tmrDecision.Enabled and (FDecisionLeftMs > 0) and not FDecisionExpired;
  Show := Counting or FDecisionExpired;
  if FDecisionExpired then
  begin
    FExpireText := TrText('Agent.ExpiredShort');
    pbExpire.Hint := Format(TrText('Agent.EditsExpired'), [PrefAgentDecisionSeconds]);
  end
  else if Counting then
  begin
    FExpireText := Format(TrText('Agent.ExpireIn'), [DecisionSecondsLeft]);
    pbExpire.Hint := Format(TrText('Agent.ExpireHint'), [PrefAgentDecisionSeconds]);
  end;
  if pbExpire.Visible <> Show then
  begin
    pbExpire.Visible := Show;
    FitTexts;
  end;
  if Show then
    pbExpire.Invalidate;
  if FZoomForm <> nil then
  begin
    if Counting then
      S := FZoomCaption + '  -  ' + #$23F1 + ' ' + FExpireText
    else
      S := FZoomCaption;
    if FZoomForm.Caption <> S then
      FZoomForm.Caption := S;
  end;
end;

procedure TfrmAgentWorkspace.DecisionTimer(Sender: TObject);
var
  Tick: Cardinal;
  Delta: Integer;
begin
  if (csDestroying in ComponentState) or (FEdits = nil) then Exit;
  if FEdits.Count = 0 then
  begin
    StopDecision;
    Exit;
  end;
  Tick := GetTickCount;
  Delta := Integer(Tick - FDecisionTick);
  FDecisionTick := Tick;
  { Writing, or a confirmation is open: the user is acting, keep the time left. }
  if FBusy or (FDecisionHold > 0) then Exit;
  Dec(FDecisionLeftMs, Max(Delta, 0));
  if FDecisionLeftMs <= 0 then
    ExpireEdits
  else
    UpdateDecisionLabel;
end;

{ Drawn 4x larger and scaled down with HALFTONE so the pill and the stopwatch get smooth edges;
  the text is drawn afterwards at normal size (ClearType). }
procedure TfrmAgentWorkspace.ExpirePaint(Sender: TObject);
const
  SS = 4;
var
  C: TCanvas;
  Small, Big: TBitmap;
  W, H, Pad, IconD, TextL: Integer;
  CX, CY, Rad, Inner, Stroke: Integer;
  Fill, Edge, Ink: TColor;
  Frac, A: Double;
  T: TRect;
begin
  C := pbExpire.Canvas;
  W := pbExpire.Width;
  H := pbExpire.Height;
  if (W <= 0) or (H <= 0) then Exit;
  Frac := 0;
  if FDecisionExpired then
  begin
    Fill := $00F4F2F2;
    Edge := $00CEC8C8;
    Ink := $00736969;
  end
  else
  begin
    if FDecisionTotalMs > 0 then
      Frac := EnsureRange(FDecisionLeftMs / FDecisionTotalMs, 0, 1);
    if FDecisionLeftMs <= 5000 then
    begin
      { Last seconds: red, with a soft pulse every second. }
      if (FDecisionLeftMs mod 1000) >= 500 then
        Fill := $00DCDCFF
      else
        Fill := $00EEEEFF;
      Edge := $007878EB;
      Ink := $001E1EBE;
    end
    else
    begin
      Fill := $00E9F6FF;
      Edge := $006EB9F5;
      Ink := $000054A8;
    end;
  end;

  Pad := Dpi(12);
  IconD := Dpi(18);
  Small := TBitmap.Create;
  Big := TBitmap.Create;
  try
    Small.PixelFormat := pf24bit;
    Small.SetSize(W, H);
    BitBlt(Small.Canvas.Handle, 0, 0, W, H, C.Handle, 0, 0, SRCCOPY);
    Big.PixelFormat := pf24bit;
    Big.SetSize(W * SS, H * SS);
    SetStretchBltMode(Big.Canvas.Handle, COLORONCOLOR);
    StretchBlt(Big.Canvas.Handle, 0, 0, W * SS, H * SS, Small.Canvas.Handle, 0, 0, W, H, SRCCOPY);

    with Big.Canvas do
    begin
      { Pill. }
      Pen.Width := SS;
      Pen.Color := Edge;
      Brush.Style := bsSolid;
      Brush.Color := Fill;
      RoundRect(SS div 2, SS + SS div 2, W * SS - SS div 2, (H - 1) * SS - SS div 2,
        (H - 2) * SS, (H - 2) * SS);

      { Stopwatch: ring, crown and side button; the filled sector is the time left (clockwise from 12). }
      Stroke := Max(SS, Dpi(2) * SS * 3 div 4);
      Rad := IconD * SS div 2 - Stroke;
      CX := (Pad + IconD div 2) * SS;
      CY := (H * SS) div 2 + Dpi(1) * SS;
      Pen.Color := Ink;
      Brush.Color := Ink;
      Pen.Width := 1;
      Rectangle(CX - Dpi(2) * SS, CY - Rad - Stroke - Dpi(3) * SS, CX + Dpi(2) * SS, CY - Rad - Stroke - Dpi(1) * SS);
      A := Pi / 4;
      Pen.Width := Stroke;
      MoveTo(CX + Round(Sin(A) * (Rad + Stroke)), CY - Round(Cos(A) * (Rad + Stroke)));
      LineTo(CX + Round(Sin(A) * (Rad + Stroke + Dpi(2) * SS)), CY - Round(Cos(A) * (Rad + Stroke + Dpi(2) * SS)));
      Brush.Color := clWhite;
      Ellipse(CX - Rad, CY - Rad, CX + Rad, CY + Rad);

      Inner := Rad - Stroke div 2 - Dpi(2) * SS;
      Pen.Width := 1;
      Brush.Color := Ink;
      if FDecisionExpired then
      begin
        Pen.Width := Stroke;
        MoveTo(CX, CY);
        LineTo(CX, CY - Inner);
        MoveTo(CX, CY);
        LineTo(CX + Inner * 3 div 4, CY);
      end
      else if Frac >= 0.999 then
        Ellipse(CX - Inner, CY - Inner, CX + Inner, CY + Inner)
      else if Frac > 0.001 then
      begin
        A := Frac * 2 * Pi;
        { Pie runs counter-clockwise: from the end of the remaining arc back to 12 o'clock. }
        Pie(CX - Inner, CY - Inner, CX + Inner, CY + Inner,
          CX + Round(Sin(A) * Inner * 2), CY - Round(Cos(A) * Inner * 2), CX, CY - Inner * 2);
      end;
    end;

    SetStretchBltMode(Small.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(Small.Canvas.Handle, 0, 0, nil);
    StretchBlt(Small.Canvas.Handle, 0, 0, W, H, Big.Canvas.Handle, 0, 0, W * SS, H * SS, SRCCOPY);

    TextL := Pad + IconD + Dpi(7);
    Small.Canvas.Font.Assign(pbExpire.Font);
    Small.Canvas.Font.Color := Ink;
    Small.Canvas.Brush.Style := bsClear;
    T := Rect(TextL, 0, W - Dpi(8), H);
    DrawText(Small.Canvas.Handle, PChar(FExpireText), -1, T,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
    C.Draw(0, 0, Small);
  finally
    Big.Free;
    Small.Free;
  end;
end;

{ Time is up with no decision: drop every proposal, nothing was written. The user sends the request again. }
procedure TfrmAgentWorkspace.ExpireEdits;
var
  S: string;
begin
  tmrDecision.Enabled := False;
  FDecisionLeftMs := 0;
  if (FEdits = nil) or (FEdits.Count = 0) then
  begin
    UpdateDecisionLabel;
    Exit;
  end;
  if FZoomForm <> nil then
    FZoomForm.ModalResult := mrCancel;
  FDecisionExpired := True;
  FEdits.Clear;
  lstEdits.Items.Clear;
  ShowPreview;
  UpdateResultTabs;
  S := Format(TrText('Agent.EditsExpired'), [PrefAgentDecisionSeconds]);
  lblStatus.Caption := S;
  UpdateDecisionLabel;
  AgentLog('proposed edits expired after ' + IntToStr(PrefAgentDecisionSeconds) + ' s');
  if FExternal then
    AgentBridgeNotify(abeApplied, S, '', 0);
end;

{ Lines covered, as [AFrom, ATo]. Insert covers nothing: [S, S-1]. Open-ended anonymize: ATo = High(Int64). }
procedure EditSpan(E: TAgentEdit; out AFrom, ATo: Int64);
begin
  AFrom := E.LineStart;
  case E.Kind of
    aekInsert: ATo := E.LineStart - 1;
    aekAnonymize:
      if E.LineEnd > 0 then
        ATo := E.LineEnd
      else
        ATo := High(Int64);
  else
    ATo := E.LineEnd;
  end;
end;

function EditsOverlap(A, B: TAgentEdit): Boolean;
var
  A1, A2, B1, B2: Int64;
begin
  if (A.Kind in [aekAnonymize, aekAction]) or (B.Kind in [aekAnonymize, aekAction]) then
    Exit(False);
  EditSpan(A, A1, A2);
  EditSpan(B, B1, B2);
  if (A.Kind = aekInsert) and (B.Kind = aekInsert) then
    Exit(False);
  if A.Kind = aekInsert then
    Exit((A1 > B1) and (A1 <= B2));
  if B.Kind = aekInsert then
    Exit((B1 > A1) and (B1 <= A2));
  Result := (A1 <= B2) and (B1 <= A2);
end;

function TfrmAgentWorkspace.ApplyErrorText(const R: TAgentApplyResult): string;
var
  Parts: TArray<string>;
begin
  if R.Cancelled then
    Exit(TrText('Request stopped.'));
  if R.Err = 'changed' then
    Exit(TrText('The file changed on disk. Ask the agent again.'));
  if Copy(R.Err, 1, 6) = 'space|' then
  begin
    Parts := R.Err.Split(['|']);
    if Length(Parts) >= 3 then
      Exit(Format(TrText('Not enough disk space: need %s, free %s.'), [Parts[1], Parts[2]]));
  end;
  Result := TrText('Could not apply the edit.');
  if R.Err <> '' then
    Result := Result + ' ' + R.Err;
end;

procedure TfrmAgentWorkspace.WMAgentMerge(var Msg: TMessage);
begin
  case Msg.WParam of
    cMaMsgRelease:
      begin
        if Assigned(GFFCompareMergeFileHook) then
          GFFCompareMergeFileHook(FApplyTarget, cFFMergeHookRelease)
        else if Assigned(OnReleaseFile) then
          OnReleaseFile(FApplyTarget);
        FApplyReleased := True;
        Msg.Result := 1;
      end;
    cMaMsgProgress:
      begin
        lblStatus.Caption := Format(TrText('Applying edits... %d%%'), [Integer(Msg.LParam) div 10]);
        if (FWaitKind = 3) and FWaitOwned then
        begin
          TfrmSmoothLoading.UpdateProgressMonotonic(Integer(Msg.LParam) div 10);
          TfrmSmoothLoading.PostDetailFromWorker(lblStatus.Caption + '  ' + ExtractFileName(FApplyTarget));
        end;
      end;
  end;
end;

{ Main thread, after one file was written (or failed). }
procedure TfrmAgentWorkspace.FileApplied(const APath: string; AOk: Boolean; const R: TAgentApplyResult;
  ASingle: TAgentEdit; ASingleClone: TAgentEdit);
var
  I, Stage: Integer;
  B: TAgentEdit;
  A1, A2, B1, B2, Delta: Int64;
begin
  if FApplyReleased or (AOk and not R.SameLayout) then
    Stage := cFFMergeHookReload
  else
    Stage := cFFMergeHookRepaint;
  if Assigned(GFFCompareMergeFileHook) then
    GFFCompareMergeFileHook(APath, Stage)
  else if Assigned(OnRefreshFile) then
    OnRefreshFile(APath);
  { Lines moved: the open file's line index may be rebuilt later; an old one still lands on line
    starts and would point previews/anonymize at the wrong lines. Scan the file instead. }
  if (Stage = cFFMergeHookReload) and (IndexPathFor(APath) <> '') then
    FIndexPath := '';
  if (R.Applied > 0) and Assigned(OnHistoryTouched) then
    OnHistoryTouched(APath);
  Inc(FMissing, R.Missing);
  if not AOk then Exit;
  Inc(FAppliedFiles);
  if FEdits = nil then Exit;

  if ASingle = nil then
  begin
    for I := FEdits.Count - 1 downto 0 do
      if (TAgentEdit(FEdits[I]).Kind <> aekAction) and SameText(TAgentEdit(FEdits[I]).Path, APath) then
        FEdits.Delete(I);
  end
  else
  begin
    I := FEdits.IndexOf(ASingle);
    if I >= 0 then
      FEdits.Delete(I);
    if ASingleClone.Kind <> aekAnonymize then
    begin
      EditSpan(ASingleClone, A1, A2);
      Delta := ASingleClone.LineDelta;
      for I := FEdits.Count - 1 downto 0 do
      begin
        B := TAgentEdit(FEdits[I]);
        if (B.Kind = aekAction) or not SameText(B.Path, APath) then Continue;
        EditSpan(B, B1, B2);
        if B1 > A2 then
        begin
          B.LineStart := B.LineStart + Delta;
          if (B.Kind <> aekAnonymize) or (B.LineEnd > 0) then
            B.LineEnd := B.LineEnd + Delta;
        end
        else if B2 < A1 then
          Continue
        else if B.Kind = aekAnonymize then
        begin
          if B.LineEnd > 0 then
            B.LineEnd := Max(B.LineStart, B.LineEnd + Delta);
        end
        else
        begin
          FEdits.Delete(I);
          Inc(FDropped);
        end;
      end;
    end;
  end;
  RefreshEditCaptions;
  ShowPreview;
end;

procedure TfrmAgentWorkspace.StartApply(AJobs: TObjectList; ASingle: TAgentEdit);
var
  Paths: TStringList;
  I, J: Integer;
  E: TAgentEdit;
  Wnd: HWND;
begin
  Wnd := Handle;
  Paths := TStringList.Create;
  try
    for I := 0 to AJobs.Count - 1 do
    begin
      E := TAgentEdit(AJobs[I]);
      if Paths.IndexOf(E.Path) < 0 then
        Paths.Add(E.Path);
    end;
    for I := 0 to AJobs.Count - 1 do
      for J := I + 1 to AJobs.Count - 1 do
        if SameText(TAgentEdit(AJobs[I]).Path, TAgentEdit(AJobs[J]).Path) and
           EditsOverlap(TAgentEdit(AJobs[I]), TAgentEdit(AJobs[J])) then
        begin
          MessageBoxTrInfo(Format(TrText('Proposals on %s overlap. Accept them one at a time.'),
            [ExtractFileName(TAgentEdit(AJobs[I]).Path)]), TrText('AI agent'));
          AJobs.Free;
          Exit;
        end;
    for I := 0 to Paths.Count - 1 do
      if Assigned(OnBeforeWrite) and not OnBeforeWrite(Paths[I]) then
      begin
        AJobs.Free;
        Exit;
      end;
  finally
    Paths.Free;
  end;

  FCancel := 0;
  FAppliedFiles := 0;
  FDropped := 0;
  FMissing := 0;
  FApplyRunning := True;
  SetBusy(True);
  lblStatus.Caption := TrText('Working...');
  TThread.CreateAnonymousThread(
    procedure
    var
      Order: TStringList;
      Batch: TList<TAgentEdit>;
      K, M: Integer;
      Path, Ip: string;
      Ok, Failed: Boolean;
      R: TAgentApplyResult;
      FailText: string;
    begin
      Order := TStringList.Create;
      Batch := TList<TAgentEdit>.Create;
      Failed := False;
      FailText := '';
      try
        try
          for K := 0 to AJobs.Count - 1 do
            if Order.IndexOf(TAgentEdit(AJobs[K]).Path) < 0 then
              Order.Add(TAgentEdit(AJobs[K]).Path);
          for K := 0 to Order.Count - 1 do
          begin
            if FCancel <> 0 then
            begin
              Failed := True;
              FailText := TrText('Request stopped.');
              Break;
            end;
            Path := Order[K];
            Batch.Clear;
            for M := 0 to AJobs.Count - 1 do
              if SameText(TAgentEdit(AJobs[M]).Path, Path) then
                Batch.Add(TAgentEdit(AJobs[M]));
            TThread.Synchronize(nil,
              procedure
              begin
                FApplyTarget := Path;
                FApplyReleased := False;
                Ip := IndexPathFor(Path);
                lblStatus.Caption := Format(TrText('Applying edits... %d%%'), [0]) + '  ' + ExtractFileName(Path);
                BeginWait(3, TrText('AI agent') + ' - ' + TrText('Working...'), lblStatus.Caption);
                if FWaitOwned then
                  TfrmSmoothLoading.UpdateProgress(0);
              end);
            Ok := AgentApplyFileEdits(Path, Ip, Batch, Wnd, WM_AGENT_MERGE,
              function: Boolean
              begin
                Result := FCancel <> 0;
              end, R);
            TThread.Synchronize(nil,
              procedure
              begin
                if FWaitKind = 3 then
                  EndWait;
                FileApplied(Path, Ok, R, ASingle, TAgentEdit(Batch[0]));
                if not Ok then
                  FailText := ApplyErrorText(R);
              end);
            if not Ok then
            begin
              Failed := True;
              Break;
            end;
          end;
        except
          on Ex: Exception do
          begin
            Failed := True;
            FailText := TrText('Could not apply the edit.') + ' ' + Ex.Message;
          end;
        end;
      finally
        Batch.Free;
        Order.Free;
      end;
      TThread.Queue(nil,
        procedure
        var
          S: string;
        begin
          if Failed then
            S := FailText
          else if FAppliedFiles > 1 then
            S := Format(TrText('Edits applied: %d file(s).'), [FAppliedFiles])
          else
            S := TrText('Edit applied.');
          if FMissing > 0 then
            S := S + '  ' + Format(TrText('%d line(s) were past the end of the file and were skipped.'), [FMissing]);
          if FDropped > 0 then
            S := S + '  ' + Format(TrText('%d proposal(s) overlapped the applied change and were removed.'), [FDropped]);
          AJobs.Free;
          FApplyRunning := False;
          if csDestroying in ComponentState then
            Exit;
          if FWaitKind = 3 then
            EndWait;
          lblStatus.Caption := S;
          SetBusy(False);
          RestartDecision;
          if FExternal then
            AgentBridgeNotify(abeApplied, S, '', FEdits.Count);
          if Failed then
            MessageBoxTrInfo(S, TrText('AI agent'));
        end);
    end).Start;
end;

procedure TfrmAgentWorkspace.AcceptOne(AIndex: Integer);
var
  E: TAgentEdit;
  Jobs: TObjectList;
begin
  if (AIndex < 0) or (AIndex >= FEdits.Count) or FBusy then Exit;
  HoldDecision;
  try
    E := TAgentEdit(FEdits[AIndex]);
    if E.Kind = aekAction then
    begin
      AcceptAction(AIndex);
      Exit;
    end;
    if not MessageBoxTrYesNo(Format(TrText('Apply the edit to %s?'), [E.Path]) + #13#10#13#10 +
      EditCaption(E), TrText('AI agent')) then
      Exit;
    Jobs := TObjectList.Create(True);
    Jobs.Add(E.Clone);
    StartApply(Jobs, E);
  finally
    ReleaseDecision;
  end;
end;

procedure TfrmAgentWorkspace.AcceptClick(Sender: TObject);
begin
  AcceptOne(lstEdits.ItemIndex);
end;

procedure TfrmAgentWorkspace.RejectClick(Sender: TObject);
begin
  if lstEdits.ItemIndex < 0 then Exit;
  HoldDecision;
  try
    if not MessageBoxTrYesNo(TrText('Discard this edit?'), TrText('AI agent')) then Exit;
    RemoveEditAt(lstEdits.ItemIndex);
  finally
    ReleaseDecision;
  end;
end;

procedure TfrmAgentWorkspace.AcceptAllClick(Sender: TObject);
var
  Jobs: TObjectList;
  I, Actions: Integer;
begin
  if (FEdits.Count = 0) or FBusy then Exit;
  Actions := 0;
  for I := 0 to FEdits.Count - 1 do
    if TAgentEdit(FEdits[I]).Kind = aekAction then
      Inc(Actions);
  HoldDecision;
  try
    { Core actions can open their own windows and run in the background: accept them one at a time. }
    if Actions = FEdits.Count then
    begin
      MessageBoxTrInfo(TrText('Agent.ActionsOneByOne'), TrText('AI agent'));
      Exit;
    end;
    if not MessageBoxTrYesNo(TrText('Apply every proposed edit?'), TrText('AI agent')) then Exit;
    Jobs := TObjectList.Create(True);
    for I := 0 to FEdits.Count - 1 do
      if TAgentEdit(FEdits[I]).Kind <> aekAction then
        Jobs.Add(TAgentEdit(FEdits[I]).Clone);
    StartApply(Jobs, nil);
  finally
    ReleaseDecision;
  end;
  if Actions > 0 then
    lblStatus.Caption := lblStatus.Caption + '  ' + TrText('Agent.ActionsOneByOne');
end;

procedure TfrmAgentWorkspace.ApplyLanguage;
begin
  Caption := TrText('AI agent');
  btnAddFiles.Caption := TrText('Add files...');
  btnAddFolder.Caption := TrText('Add folder...');
  btnOpenFile.Caption := TrText('Open file');
  btnRemove.Caption := TrText('Agent.RemoveSelected');
  btnSelectAll.Caption := TrText('Agent.SelectAll');
  btnRemoveAll.Caption := TrText('Agent.RemoveAll');
  edtRootFind.TextHint := TrText('Agent.FindRootsHint');
  edtRootFind.Hint := TrText('MRU.FindHint');
  edtRootFind.ShowHint := True;
  btnRootFindClear.Hint := TrText('MRU.ClearFind');
  btnRootFindClear.ShowHint := True;
  btnRootRecent.Caption := TrText('Agent.RootRecent') + ' ' + #$25BE;
  btnRootRecent.Width := TextPx(btnRootRecent.Font, btnRootRecent.Caption) + Dpi(24);
  btnRootRecent.Hint := TrText('Agent.RootRecentHint');
  RefreshRootRecentButton;
  RootFindLayout(nil);
  lstRoots.ShowHint := True;
  lstRoots.Hint := TrText('Agent.RootsHint');
  miRootRemove.Caption := TrText('Agent.RemoveSelected');
  miRootSelectAll.Caption := TrText('Agent.SelectAll');
  miRootCopy.Caption := TrText('Agent.CopyPaths');
  miRootRemoveAll.Caption := TrText('Agent.RemoveAll');
  RefreshRootList;
  btnSend.Caption := TrText('Send');
  btnSend.ShowHint := True;
  btnSend.Hint := TrText('Agent.SendHint');
  btnStop.Caption := TrText('Stop');
  btnAccept.Caption := #$2713 + '  ' + TrText('Accept');
  btnReject.Caption := #$2715 + '  ' + TrText('Reject');
  btnAcceptAll.Caption := #$2713#$2713 + '  ' + TrText('Accept all');
  lblGuide.Caption := TrText('Agent.Guide');
  grpSources.Caption := ' ' + TrText('Agent.Step1') + ' ';
  grpPrompt.Caption := ' ' + TrText('Agent.Step2') + ' ';
  grpResults.Caption := ' ' + TrText('Agent.Step3') + ' ';
  grpOptions.Caption := ' ' + TrText('Options') + ' ';
  lblOptLink.Caption := TrText('Options') + '...';
  if FOptPopup <> nil then
    FOptPopup.Caption := TrText('Options');
  chkSubdirs.Caption := TrText('Include subfolders');
  lblMask.Caption := TrText('File mask');
  lblDepth.Caption := TrText('Max folder depth');
  lblMaxFiles.Caption := TrText('Max files');
  memPrompt.TextHint := TrText('Describe what you want from these files.');
  lblSendHint.Caption := TrText('Agent.SendHint');
  lblRecent.Caption := TrText('Agent.Recent');
  RefreshRecentCombo;
  lblEditsNote.Caption := TrText('Agent.EditsNote');
  lblEditsNote.Hint := lblEditsNote.Caption;
  miFullView.Caption := TrText('Agent.FullText');
  miFullCopy.Caption := TrText('Agent.ToolCopy');
  FHintItem := -2;
  lstEdits.Hint := TrText('Agent.PreviewZoomHint');
  lstEdits.ShowHint := True;
  lstPreview.Hint := TrText('Agent.PreviewZoomHint');
  btnPromptTranslate.Caption := TrText('Assistant.TranslateBtn') + ' ' + #$25BE;
  btnPromptTranslate.Hint := TrText('Assistant.TranslateHint');
  btnPromptSuggest.Caption := TrText('Assistant.RewriteBtn');
  btnPromptSuggest.Hint := TrText('Assistant.RewriteHint');
  btnPromptNew.Caption := TrText('Agent.ToolNew');
  btnRootsNew.Caption := btnPromptNew.Caption;
  btnAnswerNew.Caption := btnPromptNew.Caption;
  btnPromptNew.Hint := TrText('Agent.ToolNewPromptHint');
  btnRootsNew.Hint := TrText('Agent.ToolNewRootsHint');
  btnAnswerNew.Hint := TrText('Agent.ToolNewAnswerHint');
  btnPromptClear.Caption := TrText('Agent.ToolClear');
  btnRootsClear.Caption := btnPromptClear.Caption;
  btnAnswerClear.Caption := btnPromptClear.Caption;
  btnPromptCopy.Caption := TrText('Agent.ToolCopy');
  btnRootsCopy.Caption := btnPromptCopy.Caption;
  btnAnswerCopy.Caption := btnPromptCopy.Caption;
  btnPromptAsk.Caption := TrText('Agent.ToolAsk');
  btnRootsAsk.Caption := btnPromptAsk.Caption;
  btnAnswerAsk.Caption := btnPromptAsk.Caption;
  btnPromptClear.Hint := TrText('Agent.ToolClearPromptHint');
  btnRootsClear.Hint := TrText('Agent.ToolClearRootsHint');
  btnAnswerClear.Hint := TrText('Agent.ToolClearAnswerHint');
  btnPromptCopy.Hint := TrText('Agent.ToolCopyHint');
  btnRootsCopy.Hint := TrText('Agent.ToolCopyRootsHint');
  btnAnswerCopy.Hint := btnPromptCopy.Hint;
  btnPromptAsk.Hint := TrText('Agent.ToolAskHint');
  btnRootsAsk.Hint := btnPromptAsk.Hint;
  btnAnswerAsk.Hint := btnPromptAsk.Hint;
  btnAnswerLastFile.Caption := #$2197 + ' ' + TrText('ExportDone.ShowLast');
  LastFileChanged(nil);
  if FEdits <> nil then
    RefreshEditCaptions
  else
    UpdateResultTabs;
  if not FBusy then
    lblStatus.Caption := TrText('Ready.');
  UpdateDecisionLabel;
  FitTexts;
end;

class function TfrmAgentWorkspace.ExecuteEmbedded(AOwner: TComponent; AHost: TWinControl): TfrmAgentWorkspace;
begin
  { CreateNew skips the DFM resource. This form is built in code. }
  Result := TfrmAgentWorkspace.CreateNew(AOwner);
  Result.BuildUi;
  Result.BorderStyle := bsNone;
  Result.Parent := AHost;
  Result.Align := alClient;
  Result.Visible := True;
  Result.FitTexts;
  Result.PromptChange(nil);
end;

end.
