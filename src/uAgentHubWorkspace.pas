unit uAgentHubWorkspace;

{
  UI for AI diagnosis (hub): pick files/folders, run Discovery->...->Synthesize,
  show answer / findings / revised objective / files found - chrome aligned with Agente IA.
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Contnrs,
  ExtCtrls, StdCtrls, Dialogs, Menus, Clipbrd,
  sSkinProvider, sPanel, sLabel, sButton, sCheckBox, sEdit, sGroupBox, sMemo,
  sListBox, sSplitter, sPageControl, sSpeedButton, sScrollBox,
  uAgentTools, uAgentPrefs, uAgentHubModel;

type
  TAgentHubPathFunc = function: string of object;

  TfrmAgentHubWorkspace = class(TForm)
  private
    FRoots: TObjectList;
    FRecent: TStringList;
    FRootRecent: TStringList;
    FBusy: Boolean;
    FAskBusy: Boolean;
    FCancel: Integer;
    FReport: THubReport;
    FPhase: THubPhase;
    FRecentPosted: Boolean;
    FRootRecentPosted: Boolean;
    FRootRecentDirty: Boolean;
    FLeftLayoutBusy: Boolean;

    pnlGuide: TsPanel;
    pbGuide: TPaintBox;
    lblGuide: TsLabel;
    pnlLeft: TsPanel;
    scrLeft: TsScrollBox;
    splLeft: TsSplitter;
    grpSources: TsGroupBox;
    lstRoots: TsListBox;
    pnlSourceBtns: TsPanel;
    btnAddFiles: TsButton;
    btnAddFolder: TsButton;
    btnOpenFile: TsButton;
    btnRemove: TsButton;
    btnSelectAll: TsButton;
    btnRemoveAll: TsButton;
    pnlRootFind: TsPanel;
    edtRootFind: TsEdit;
    btnRootRecent: TsButton;
    pnlRootsTools: TsPanel;
    btnRootsNew, btnRootsClear, btnRootsCopy, btnRootsAsk: TsSpeedButton;
    grpOptions: TsGroupBox;
    grpAgents: TsGroupBox;
    pnlOptHost: TsPanel;
    pnlAgentHost: TsPanel;
    chkSubdirs: TsCheckBox;
    lblMask: TsLabel;
    edtMask: TsEdit;
    lblDepth: TsLabel;
    edtDepth: TsEdit;
    lblMaxFiles: TsLabel;
    edtMaxFiles: TsEdit;
    pnlMaskRow: TsPanel;
    pnlDepthRow: TsPanel;
    pnlMaxFilesRow: TsPanel;
    chkInv: TsCheckBox;
    chkStruct: TsCheckBox;
    chkContent: TsCheckBox;
    chkSql: TsCheckBox;
    chkPrivacy: TsCheckBox;
    chkActions: TsCheckBox;
    pnlRight: TsPanel;
    grpPrompt: TsGroupBox;
    pnlRecentRow: TsPanel;
    pnlRecentCombo: TPanel;
    lblRecentCombo: TLabel;
    lblRecentArrow: TLabel;
    memPrompt: TsMemo;
    pnlPromptTools: TsPanel;
    btnPromptTranslate, btnPromptSuggest, btnPromptHelp: TsSpeedButton;
    btnPromptNew, btnPromptClear, btnPromptCopy, btnPromptAsk: TsSpeedButton;
    pnlSend: TsPanel;
    btnSend: TsButton;
    btnStop: TsButton;
    lblSendHint: TsLabel;
    lblStatus: TsLabel;
    grpResults: TsGroupBox;
    pcMain: TsPageControl;
    tabAnswer: TsTabSheet;
    tabEdits: TsTabSheet;
    tabRevised: TsTabSheet;
    tabFiles: TsTabSheet;
    memAnswer: TsMemo;
    memEdits: TsMemo;
    memRevised: TsMemo;
    memFiles: TsMemo;
    pnlAnswerTools: TsPanel;
    btnAnswerNew, btnAnswerClear, btnAnswerCopy, btnAnswerAsk: TsSpeedButton;
    btnAnswerExport, btnAnswerTranslate: TsSpeedButton;
    mnuRoots: TPopupMenu;
    miRootRemove: TMenuItem;
    miRootSelectAll: TMenuItem;
    miRootRemoveAll: TMenuItem;
    mnuTranslate: TPopupMenu;
    dlgOpen: TOpenDialog;

    function Dpi(AValue: Integer): Integer;
    function TextPx(AFont: TFont; const S: string): Integer;
    procedure BuildUi;
    procedure SourceButtonsResize(Sender: TObject);
    procedure LayoutSendBar;
    procedure LayoutGuide;
    procedure LayoutAgents;
    function AgentsContentHeight: Integer;
    procedure LayoutLeftColumn;
    procedure LeftColumnResize(Sender: TObject);
    procedure LayoutToolBar(ABar: TsPanel);
    procedure ToolBarResize(Sender: TObject);
    procedure RefreshRootList;
    procedure AddRoot(AKind: TAgentRootKind; const APath: string);
    procedure ClearRoots;
    function ReadPrefs: TAgentPrefs;
    function ForcedRolesText: string;
    procedure SetBusy(AValue: Boolean);
    procedure AppendTimeline(const ALine: string);
    procedure ShowReport;
    procedure UpdateResultTabs;
    procedure RefreshRecentCombo;
    procedure RefreshRootRecentButton;
    procedure FlushRootRecent;
    procedure AddFilesClick(Sender: TObject);
    procedure AddFolderClick(Sender: TObject);
    procedure OpenFileClick(Sender: TObject);
    procedure RemoveClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure RemoveAllClick(Sender: TObject);
    procedure RootFindChange(Sender: TObject);
    procedure RootRecentClick(Sender: TObject);
    procedure OpenRootRecentPopup;
    procedure RootRecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure RootRecentRemove(Sender: TObject; const AValue: string);
    procedure RootRecentClearAll(Sender: TObject);
    procedure RecentComboClick(Sender: TObject);
    procedure OpenRecentPopup;
    procedure RecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure RecentRemove(Sender: TObject; const AValue: string);
    procedure RecentClearAll(Sender: TObject);
    procedure SendClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure PromptKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PromptTranslateClick(Sender: TObject);
    procedure PromptTranslateLangClick(Sender: TObject);
    procedure PromptSuggestClick(Sender: TObject);
    procedure PromptHelpClick(Sender: TObject);
    procedure ToolNewClick(Sender: TObject);
    procedure ToolClearClick(Sender: TObject);
    procedure ToolCopyClick(Sender: TObject);
    procedure ToolAskClick(Sender: TObject);
    procedure AnswerExportClick(Sender: TObject);
    procedure AnswerExportTypeChange(Sender: TObject);
    procedure AnswerChange(Sender: TObject);
    procedure StartPromptTextJob(AJob: Integer; const ALangName: string);
    procedure GuidePaint(Sender: TObject);
    procedure WMHubStatus(var Msg: TMessage); message WM_APP + 70;
    procedure WMHubDone(var Msg: TMessage); message WM_APP + 71;
    procedure WMAskDone(var Msg: TMessage); message WM_APP + 72;
    procedure WMRecentPopup(var Msg: TMessage); message WM_APP + 45;
    procedure WMRootRecentPopup(var Msg: TMessage); message WM_APP + 49;
  public
    OnGetOpenFile: TAgentHubPathFunc;
    destructor Destroy; override;
    procedure ApplyLanguage;
    procedure FitTexts;
    procedure ShowCapabilities;
    class function ExecuteEmbedded(AOwner: TComponent; AHost: TWinControl): TfrmAgentHubWorkspace;
  end;

implementation

uses
  Types, Math, uI18n, uAgentHub, uFastFileMsgDlg, uFastFileAIClient,
  uFastFileAssistant, uAICapabilitiesDlg, UnitPopupMruList, uMruFind,
  uFastFileAssistantHost, uFolderPickDlg, uSearchCommands, uSearchCommandDialog;

type
  THubResultMemo = class(TsMemo)
  private
    FWheelRemainder: Integer;
  protected
    procedure WndProc(var Message: TMessage); override;
  end;

  THubNote = class
  public
    Phase: THubPhase;
    Detail: string;
    Report: THubReport;
    Ok: Boolean;
  end;

  TAskNote = class
  public
    Job: Integer;
    Text: string;
    Ok: Boolean;
    Err: string;
  end;

  THubWorker = class(TThread)
  private
    FWnd: HWND;
    FRoots: TStringList;
    FOptions: THubRunOptions;
    FCancel: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(AWnd: HWND; ARoots: TStringList; const AOptions: THubRunOptions;
      ACancel: PInteger);
    destructor Destroy; override;
  end;

  TAskWorker = class(TThread)
  private
    FWnd: HWND;
    FJob: Integer;
    FPrompt: string;
  protected
    procedure Execute; override;
  public
    constructor Create(AWnd: HWND; AJob: Integer; const APrompt: string);
  end;

  THubStatusPoster = class
  public
    Wnd: HWND;
    procedure OnStatus(APhase: THubPhase; const ADetail: string);
  end;

constructor THubWorker.Create(AWnd: HWND; ARoots: TStringList;
  const AOptions: THubRunOptions; ACancel: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FWnd := AWnd;
  FRoots := ARoots;
  FOptions := AOptions;
  FCancel := ACancel;
end;

destructor THubWorker.Destroy;
var
  I: Integer;
begin
  if Assigned(FRoots) then
  begin
    for I := 0 to FRoots.Count - 1 do
      FRoots.Objects[I].Free;
    FRoots.Free;
  end;
  inherited;
end;

constructor TAskWorker.Create(AWnd: HWND; AJob: Integer; const APrompt: string);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FWnd := AWnd;
  FJob := AJob;
  FPrompt := APrompt;
  Start;
end;

procedure TAskWorker.Execute;
var
  Ans: WideString;
  Why: string;
  N: TAskNote;
begin
  N := TAskNote.Create;
  N.Job := FJob;
  try
    N.Ok := FastFileAIInvokePrompt(WideString(FPrompt), Ans, Why);
    if N.Ok then
      N.Text := string(Ans)
    else
      N.Err := Why;
  except
    on E: Exception do
    begin
      N.Ok := False;
      N.Err := E.Message;
    end;
  end;
  if not PostMessage(FWnd, WM_APP + 72, 0, LPARAM(N)) then
    N.Free;
end;

procedure THubStatusPoster.OnStatus(APhase: THubPhase; const ADetail: string);
var
  N: THubNote;
begin
  N := THubNote.Create;
  N.Phase := APhase;
  N.Detail := ADetail;
  if not PostMessage(Wnd, WM_APP + 70, 0, LPARAM(N)) then
    N.Free;
end;

procedure THubWorker.Execute;
var
  Report: THubReport;
  Poster: THubStatusPoster;
  Note: THubNote;
  Ok: Boolean;
begin
  Report := THubReport.Create;
  Poster := THubStatusPoster.Create;
  try
    Poster.Wnd := FWnd;
    Ok := AgentHubRun(FRoots, FOptions, FCancel, Poster.OnStatus, Report);
    Note := THubNote.Create;
    Note.Ok := Ok;
    Note.Report := Report;
    Report := nil;
    if not PostMessage(FWnd, WM_APP + 71, 0, LPARAM(Note)) then
    begin
      Note.Report.Free;
      Note.Free;
    end;
  finally
    Report.Free;
    Poster.Free;
  end;
end;

procedure THubResultMemo.WndProc(var Message: TMessage);
var
Steps, I, Direction: Integer;
Lines: UINT;
begin
if Message.Msg = WM_MOUSEWHEEL then
begin
  Inc(FWheelRemainder, SmallInt(HiWord(Message.WParam)));
  Steps := FWheelRemainder div WHEEL_DELTA;
  FWheelRemainder := FWheelRemainder mod WHEEL_DELTA;
  if Steps <> 0 then
  begin
    Lines := 3;
    SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @Lines, 0);
    if Lines = WHEEL_PAGESCROLL then
    begin
      if Steps > 0 then Direction := SB_PAGEUP else Direction := SB_PAGEDOWN;
      for I := 1 to Abs(Steps) do
        Perform(WM_VSCROLL, Direction, 0);
    end
    else
      Perform(EM_LINESCROLL, 0, -Steps * Integer(Lines));
  end;
  Message.Result := 0;
  Exit;
end;
inherited;
end;

destructor TfrmAgentHubWorkspace.Destroy;
begin
  FlushRootRecent;
  FReport.Free;
  FRoots.Free;
  FRecent.Free;
  FRootRecent.Free;
  inherited;
end;

function TfrmAgentHubWorkspace.Dpi(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

function TfrmAgentHubWorkspace.TextPx(AFont: TFont; const S: string): Integer;
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

procedure TfrmAgentHubWorkspace.BuildUi;
var
  Host: TsPanel;
  Def: TAgentPrefs;

  procedure Stack(AControl: TControl; AAlign: TAlign);
  begin
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
    Result.Margins.SetBounds(Dpi(8), Dpi(4), Dpi(6), Dpi(4));
    Result.Font.Style := [fsBold];
    if AAlign in [alTop, alBottom] then
      Result.Height := ASize;
    Stack(Result, AAlign);
  end;

  function GroupHost(AGroup: TsGroupBox; ATight: Boolean = False): TsPanel;
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
    if ATight then
      Result.Margins.SetBounds(Dpi(6), Dpi(12), Dpi(6), Dpi(4))
    else
      Result.Margins.SetBounds(Dpi(8), Dpi(14), Dpi(8), Dpi(6));
    Result.Align := alClient;
  end;

  function MakeButton(AParent: TWinControl; AWidth: Integer; AClick: TNotifyEvent): TsButton;
  begin
    Result := TsButton.Create(Self);
    Result.Parent := AParent;
    Result.Width := AWidth;
    Result.Height := Dpi(26);
    Result.OnClick := AClick;
  end;

  function MakeCheckFree(AParent: TWinControl; AChecked: Boolean = False): TsCheckBox;
  begin
    Result := TsCheckBox.Create(Self);
    Result.Parent := AParent;
    Result.AutoSize := False;
    Result.Height := Dpi(22);
    Result.Checked := AChecked;
  end;

  function MakeTab(const ACaption: string): TsTabSheet;
  begin
    Result := TsTabSheet.Create(Self);
    Result.PageControl := pcMain;
    Result.Caption := ACaption;
  end;

  function MakeMemo(AParent: TWinControl; AReadOnly: Boolean): TsMemo;
  begin
    Result := THubResultMemo.Create(Self);
    Result.Parent := AParent;
    Result.Align := alClient;
    Result.ScrollBars := ssBoth;
    Result.WordWrap := True;
    Result.ReadOnly := AReadOnly;
    Result.Font.Name := 'Consolas';
    Result.Font.Size := 10;
    Result.AlignWithMargins := True;
    Result.Margins.SetBounds(Dpi(4), Dpi(4), Dpi(4), Dpi(4));
  end;

  function MakeToolBtn(AParent: TWinControl; AClick: TNotifyEvent): TsSpeedButton;
  begin
    Result := TsSpeedButton.Create(Self);
    Result.Parent := AParent;
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
    Result.Height := Dpi(26);
    Result.Width := Dpi(60);
    Result.AlignWithMargins := False;
    Result.Margins.SetBounds(0, 0, 0, 0);
    Result.Left := 100000;
    Result.Align := alLeft;
    Result.OnClick := AClick;
  end;

  function MakeToolBar(AParent: TWinControl): TsPanel;
  begin
    { Tall enough for bold Segoe UI 8 at PPI 120+; LayoutToolBar keeps this height. }
    Result := MakePanel(AParent, alBottom, Dpi(36));
    Result.Padding.SetBounds(0, 0, 0, 0);
    Result.Constraints.MinHeight := Dpi(34);
    Result.OnResize := ToolBarResize;
  end;

begin
  Color := clBtnFace;
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  DoubleBuffered := True;
  FRoots := TObjectList.Create(True);
  FRecent := TStringList.Create;
  FRootRecent := TStringList.Create;
  LoadAgentRecent(FRecent);
  LoadAgentRootRecent(FRootRecent);
  FReport := nil;
  FBusy := False;
  FAskBusy := False;
  FCancel := 0;
  Def := DefaultAgentPrefs;

  pnlGuide := MakePanel(Self, alTop, Dpi(56));
  pnlGuide.Padding.SetBounds(Dpi(10), Dpi(6), Dpi(10), Dpi(4));
  pbGuide := TPaintBox.Create(Self);
  pbGuide.Parent := pnlGuide;
  pbGuide.Align := alClient;
  pbGuide.OnPaint := GuidePaint;
  lblGuide := TsLabel.Create(Self);
  lblGuide.Parent := pnlGuide;
  lblGuide.Visible := False;
  lblGuide.AutoSize := False;
  lblGuide.WordWrap := True;
  lblGuide.ParentFont := False;
  lblGuide.Font.Name := 'Segoe UI';
  lblGuide.Font.Size := 9;
  lblGuide.Font.Color := $00603A1E;

  scrLeft := TsScrollBox.Create(Self);
  scrLeft.Parent := Self;
  scrLeft.Align := alLeft;
  scrLeft.Width := Dpi(400);
  scrLeft.Constraints.MinWidth := Dpi(320);
  scrLeft.BorderStyle := bsNone;
  scrLeft.AutoMouseWheel := True;
  scrLeft.HorzScrollBar.Visible := False;
  scrLeft.VertScrollBar.Tracking := True;
  scrLeft.OnResize := LeftColumnResize;
  pnlLeft := MakePanel(scrLeft, alTop, Dpi(600));

  grpAgents := MakeGroup(pnlLeft, alBottom, Dpi(168));
  grpAgents.Margins.SetBounds(Dpi(6), Dpi(2), Dpi(4), Dpi(10));
  grpAgents.Constraints.MinHeight := Dpi(140);
  pnlAgentHost := GroupHost(grpAgents, True);
  chkInv := MakeCheckFree(pnlAgentHost, True);
  chkInv.Enabled := False;
  chkStruct := MakeCheckFree(pnlAgentHost, True);
  chkContent := MakeCheckFree(pnlAgentHost, True);
  chkSql := MakeCheckFree(pnlAgentHost, False);
  chkPrivacy := MakeCheckFree(pnlAgentHost, False);
  chkActions := MakeCheckFree(pnlAgentHost, False);

  grpOptions := MakeGroup(pnlLeft, alBottom, Dpi(168));
  grpOptions.Margins.SetBounds(Dpi(6), Dpi(2), Dpi(4), Dpi(2));
  pnlOptHost := GroupHost(grpOptions, True);
  chkSubdirs := MakeCheckFree(pnlOptHost, True);
  pnlMaskRow := TsPanel.Create(Self);
  pnlMaskRow.Parent := pnlOptHost;
  pnlMaskRow.BevelOuter := bvNone;
  pnlMaskRow.ParentBackground := True;
  pnlMaskRow.Height := Dpi(26);
  lblMask := TsLabel.Create(Self);
  lblMask.Parent := pnlMaskRow;
  lblMask.AutoSize := False;
  lblMask.Layout := tlCenter;
  edtMask := TsEdit.Create(Self);
  edtMask.Parent := pnlMaskRow;
  edtMask.Text := Def.Mask;
  pnlDepthRow := TsPanel.Create(Self);
  pnlDepthRow.Parent := pnlOptHost;
  pnlDepthRow.BevelOuter := bvNone;
  pnlDepthRow.ParentBackground := True;
  pnlDepthRow.Height := Dpi(26);
  lblDepth := TsLabel.Create(Self);
  lblDepth.Parent := pnlDepthRow;
  lblDepth.AutoSize := False;
  lblDepth.Layout := tlCenter;
  edtDepth := TsEdit.Create(Self);
  edtDepth.Parent := pnlDepthRow;
  edtDepth.Text := IntToStr(Def.MaxDepth);
  pnlMaxFilesRow := TsPanel.Create(Self);
  pnlMaxFilesRow.Parent := pnlOptHost;
  pnlMaxFilesRow.BevelOuter := bvNone;
  pnlMaxFilesRow.ParentBackground := True;
  pnlMaxFilesRow.Height := Dpi(26);
  lblMaxFiles := TsLabel.Create(Self);
  lblMaxFiles.Parent := pnlMaxFilesRow;
  lblMaxFiles.AutoSize := False;
  lblMaxFiles.Layout := tlCenter;
  edtMaxFiles := TsEdit.Create(Self);
  edtMaxFiles.Parent := pnlMaxFilesRow;
  edtMaxFiles.Text := IntToStr(Def.MaxFiles);

  grpSources := MakeGroup(pnlLeft, alClient, 0);
  grpSources.Margins.SetBounds(Dpi(6), Dpi(4), Dpi(4), Dpi(2));
  Host := GroupHost(grpSources);
  pnlSourceBtns := MakePanel(Host, alTop, Dpi(96));
  pnlSourceBtns.OnResize := SourceButtonsResize;
  btnAddFiles := MakeButton(pnlSourceBtns, Dpi(150), AddFilesClick);
  btnAddFolder := MakeButton(pnlSourceBtns, Dpi(150), AddFolderClick);
  btnOpenFile := MakeButton(pnlSourceBtns, Dpi(150), OpenFileClick);
  btnRemove := MakeButton(pnlSourceBtns, Dpi(150), RemoveClick);
  btnSelectAll := MakeButton(pnlSourceBtns, Dpi(150), SelectAllClick);
  btnRemoveAll := MakeButton(pnlSourceBtns, Dpi(150), RemoveAllClick);

  pnlRootFind := MakePanel(Host, alTop, Dpi(32));
  edtRootFind := TsEdit.Create(Self);
  edtRootFind.Parent := pnlRootFind;
  edtRootFind.AlignWithMargins := True;
  edtRootFind.Margins.SetBounds(0, Dpi(4), Dpi(4), Dpi(4));
  edtRootFind.Align := alClient;
  edtRootFind.OnChange := RootFindChange;
  btnRootRecent := MakeButton(pnlRootFind, Dpi(90), RootRecentClick);
  btnRootRecent.AlignWithMargins := True;
  btnRootRecent.Margins.SetBounds(0, Dpi(3), 0, Dpi(3));
  btnRootRecent.Align := alRight;
  btnRootRecent.ShowHint := True;

  pnlRootsTools := MakeToolBar(Host);
  btnRootsNew := MakeToolBtn(pnlRootsTools, ToolNewClick);
  btnRootsNew.Tag := 2;
  btnRootsClear := MakeToolBtn(pnlRootsTools, ToolClearClick);
  btnRootsClear.Tag := 2;
  btnRootsCopy := MakeToolBtn(pnlRootsTools, ToolCopyClick);
  btnRootsCopy.Tag := 2;
  btnRootsAsk := MakeToolBtn(pnlRootsTools, ToolAskClick);
  btnRootsAsk.Tag := 2;

  lstRoots := TsListBox.Create(Self);
  lstRoots.Parent := Host;
  lstRoots.Align := alClient;
  lstRoots.AlignWithMargins := True;
  lstRoots.Margins.SetBounds(0, Dpi(4), 0, Dpi(2));
  lstRoots.Constraints.MinHeight := Dpi(72);
  lstRoots.MultiSelect := True;
  lstRoots.ExtendedSelect := True;

  splLeft := TsSplitter.Create(Self);
  splLeft.Parent := Self;
  splLeft.Left := scrLeft.Width;
  splLeft.Align := alLeft;
  splLeft.Width := Dpi(5);
  splLeft.MinSize := Dpi(260);

  pnlRight := MakePanel(Self, alClient, 0);

  grpPrompt := MakeGroup(pnlRight, alTop, Dpi(180));
  grpPrompt.Margins.SetBounds(Dpi(4), Dpi(4), Dpi(8), Dpi(4));
  Host := GroupHost(grpPrompt);

  pnlSend := MakePanel(Host, alBottom, Dpi(38));
  btnSend := MakeButton(pnlSend, Dpi(110), SendClick);
  btnSend.Name := 'btnSend';
  btnSend.Font.Style := [fsBold];
  btnStop := MakeButton(pnlSend, Dpi(90), StopClick);
  btnStop.Enabled := False;
  lblSendHint := TsLabel.Create(Self);
  lblSendHint.Parent := pnlSend;
  lblSendHint.AutoSize := False;
  lblSendHint.Layout := tlCenter;
  lblSendHint.EllipsisPosition := epEndEllipsis;
  lblSendHint.ShowHint := True;

  pnlPromptTools := MakeToolBar(Host);
  btnPromptTranslate := MakeToolBtn(pnlPromptTools, PromptTranslateClick);
  btnPromptSuggest := MakeToolBtn(pnlPromptTools, PromptSuggestClick);
  btnPromptHelp := MakeToolBtn(pnlPromptTools, PromptHelpClick);
  btnPromptNew := MakeToolBtn(pnlPromptTools, ToolNewClick);
  btnPromptNew.Tag := 1;
  btnPromptClear := MakeToolBtn(pnlPromptTools, ToolClearClick);
  btnPromptClear.Tag := 1;
  btnPromptCopy := MakeToolBtn(pnlPromptTools, ToolCopyClick);
  btnPromptCopy.Tag := 1;
  btnPromptAsk := MakeToolBtn(pnlPromptTools, ToolAskClick);
  btnPromptAsk.Tag := 1;

  pnlRecentRow := MakePanel(Host, alTop, Dpi(30));
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
  lblRecentArrow.Width := Dpi(18);
  lblRecentArrow.Alignment := taCenter;
  lblRecentArrow.Layout := tlCenter;
  lblRecentArrow.Caption := #$25BE;
  lblRecentArrow.Transparent := True;
  lblRecentArrow.OnClick := RecentComboClick;
  lblRecentCombo := TLabel.Create(Self);
  lblRecentCombo.Parent := pnlRecentCombo;
  lblRecentCombo.Align := alClient;
  lblRecentCombo.AlignWithMargins := True;
  lblRecentCombo.Margins.SetBounds(Dpi(4), 0, 0, 0);
  lblRecentCombo.Layout := tlCenter;
  lblRecentCombo.AutoSize := False;
  lblRecentCombo.EllipsisPosition := epEndEllipsis;
  lblRecentCombo.Transparent := True;
  lblRecentCombo.OnClick := RecentComboClick;

  memPrompt := TsMemo.Create(Self);
  memPrompt.Parent := Host;
  memPrompt.Align := alClient;
  memPrompt.ScrollBars := ssVertical;
  memPrompt.WantReturns := True;
  memPrompt.Font.Name := 'Segoe UI';
  memPrompt.Font.Size := 10;
  memPrompt.Name := 'memPrompt';
  { SetName copies the name into Text while the memo is still empty. }
  if memPrompt.Text = memPrompt.Name then
    memPrompt.Clear;
  memPrompt.OnKeyDown := PromptKeyDown;

  lblStatus := TsLabel.Create(Self);
  lblStatus.Parent := pnlRight;
  lblStatus.Align := alBottom;
  lblStatus.Height := Dpi(22);
  lblStatus.AlignWithMargins := True;
  lblStatus.Margins.SetBounds(Dpi(10), Dpi(2), Dpi(10), Dpi(6));
  lblStatus.Layout := tlCenter;
  lblStatus.EllipsisPosition := epEndEllipsis;

  grpResults := MakeGroup(pnlRight, alClient, 0);
  grpResults.Margins.SetBounds(Dpi(4), 0, Dpi(8), Dpi(4));
  Host := GroupHost(grpResults);
  pcMain := TsPageControl.Create(Self);
  pcMain.Parent := Host;
  pcMain.Align := alClient;
  tabAnswer := MakeTab('Answer');
  pnlAnswerTools := MakeToolBar(tabAnswer);
  btnAnswerNew := MakeToolBtn(pnlAnswerTools, ToolNewClick);
  btnAnswerNew.Tag := 3;
  btnAnswerClear := MakeToolBtn(pnlAnswerTools, ToolClearClick);
  btnAnswerClear.Tag := 3;
  btnAnswerCopy := MakeToolBtn(pnlAnswerTools, ToolCopyClick);
  btnAnswerCopy.Tag := 3;
  btnAnswerExport := MakeToolBtn(pnlAnswerTools, AnswerExportClick);
  btnAnswerExport.Name := 'btnAnswerExport';
  btnAnswerTranslate := MakeToolBtn(pnlAnswerTools, PromptTranslateClick);
  btnAnswerTranslate.Name := 'btnAnswerTranslate';
  btnAnswerAsk := MakeToolBtn(pnlAnswerTools, ToolAskClick);
  btnAnswerAsk.Tag := 3;
  memAnswer := MakeMemo(tabAnswer, True);
  memAnswer.Name := 'memAnswer';
  memAnswer.Clear;
  memAnswer.OnChange := AnswerChange;
  tabEdits := MakeTab('Proposed edits');
  memEdits := MakeMemo(tabEdits, True);
  tabRevised := MakeTab('Revised prompt');
  memRevised := MakeMemo(tabRevised, True);
  tabFiles := MakeTab('Files found');
  memFiles := MakeMemo(tabFiles, True);

  dlgOpen := TOpenDialog.Create(Self);
  dlgOpen.Options := [ofFileMustExist, ofAllowMultiSelect, ofPathMustExist];
  dlgOpen.Filter := 'All files (*.*)|*.*';

  mnuRoots := TPopupMenu.Create(Self);
  miRootRemove := TMenuItem.Create(mnuRoots);
  miRootRemove.OnClick := RemoveClick;
  mnuRoots.Items.Add(miRootRemove);
  miRootSelectAll := TMenuItem.Create(mnuRoots);
  miRootSelectAll.OnClick := SelectAllClick;
  mnuRoots.Items.Add(miRootSelectAll);
  miRootRemoveAll := TMenuItem.Create(mnuRoots);
  miRootRemoveAll.OnClick := RemoveAllClick;
  mnuRoots.Items.Add(miRootRemoveAll);
  lstRoots.PopupMenu := mnuRoots;

  ApplyLanguage;
  SetBusy(False);
  FitTexts;
end;

procedure TfrmAgentHubWorkspace.GuidePaint(Sender: TObject);
var
  R, T: TRect;
  C: TCanvas;
begin
  if pbGuide = nil then Exit;
  R := pbGuide.ClientRect;
  C := pbGuide.Canvas;
  C.Brush.Color := $00FCEBDC;
  C.FillRect(R);
  C.Pen.Color := $00D77800;
  C.Pen.Width := 3;
  C.MoveTo(0, 0);
  C.LineTo(0, R.Bottom);
  C.Pen.Width := 1;
  C.Pen.Color := $00F0D4BE;
  C.MoveTo(0, R.Bottom - 1);
  C.LineTo(R.Right, R.Bottom - 1);
  if Trim(lblGuide.Caption) = '' then Exit;
  C.Font.Assign(lblGuide.Font);
  C.Brush.Style := bsClear;
  T := Rect(Dpi(14), Dpi(8), R.Right - Dpi(12), R.Bottom - Dpi(6));
  DrawText(C.Handle, PChar(lblGuide.Caption), -1, T, DT_WORDBREAK or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

procedure TfrmAgentHubWorkspace.LayoutGuide;
var
  R: TRect;
  H: Integer;
begin
  if (pnlGuide = nil) or (lblGuide = nil) or (pbGuide = nil) then Exit;
  R := Rect(0, 0, Max(Dpi(120), pbGuide.ClientWidth - Dpi(26)), 0);
  pbGuide.Canvas.Font.Assign(lblGuide.Font);
  DrawText(pbGuide.Canvas.Handle, PChar(lblGuide.Caption), -1, R,
    DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  H := (R.Bottom - R.Top) + Dpi(16) + pnlGuide.Padding.Top + pnlGuide.Padding.Bottom;
  H := Max(Dpi(40), Min(Dpi(64), H));
  if pnlGuide.Height <> H then
    pnlGuide.Height := H;
  pbGuide.Invalidate;
end;

procedure TfrmAgentHubWorkspace.SourceButtonsResize(Sender: TObject);
var
  W, Gap, BH, H: Integer;
begin
  if (pnlSourceBtns = nil) or (btnRemoveAll = nil) then Exit;
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

procedure TfrmAgentHubWorkspace.LayoutToolBar(ABar: TsPanel);
var
  I, X, Y, Gap, BH, BarH, PadY: Integer;
  C: TControl;
begin
  if ABar = nil then Exit;
  Gap := Dpi(4);
  BH := Dpi(26);
  PadY := Dpi(5);
  X := Dpi(4);
  Y := PadY;
  for I := 0 to ABar.ControlCount - 1 do
  begin
    C := ABar.Controls[I];
    if not (C is TsSpeedButton) then Continue;
    C.Align := alNone;
    C.AlignWithMargins := False;
    C.Height := BH;
    C.Width := Max(Dpi(56), TextPx(TsSpeedButton(C).Font, TsSpeedButton(C).Caption) + Dpi(20));
    if (X > Dpi(4)) and (ABar.ClientWidth > 0) and
      (X + C.Width > ABar.ClientWidth - Dpi(4)) then
    begin
      X := Dpi(4);
      Inc(Y, BH + Gap);
    end;
    C.SetBounds(X, Y, C.Width, BH);
    Inc(X, C.Width + Gap);
  end;
  BarH := Y + BH + PadY;
  if ABar.Height <> BarH then
    ABar.Height := BarH;
end;

procedure TfrmAgentHubWorkspace.ToolBarResize(Sender: TObject);
begin
  LayoutToolBar(Sender as TsPanel);
end;

function TfrmAgentHubWorkspace.AgentsContentHeight: Integer;
var
  RowH, Gap: Integer;
  Bmp: TBitmap;
begin
  Gap := Dpi(3);
  Bmp := TBitmap.Create;
  try
    if chkInv <> nil then
      Bmp.Canvas.Font.Assign(chkInv.Font)
    else
      Bmp.Canvas.Font.Assign(Font);
    RowH := Max(Dpi(22), Bmp.Canvas.TextHeight('Hg') + Dpi(6));
  finally
    Bmp.Free;
  end;
  { 3 rows of checkboxes + host margins + skinned GroupBox chrome (caption/frame). }
  Result := 3 * (RowH + Gap) - Gap;
  if pnlAgentHost <> nil then
    Result := Result + pnlAgentHost.Margins.Top + pnlAgentHost.Margins.Bottom;
  Result := Result + Dpi(56);
end;

procedure TfrmAgentHubWorkspace.LayoutAgents;
var
  ColW, RowH, Gap, Y, I, HostW: Integer;
  Checks: array[0..5] of TsCheckBox;
  Bmp: TBitmap;
begin
  if (pnlAgentHost = nil) or (chkInv = nil) then Exit;
  Checks[0] := chkInv;
  Checks[1] := chkStruct;
  Checks[2] := chkContent;
  Checks[3] := chkSql;
  Checks[4] := chkPrivacy;
  Checks[5] := chkActions;
  Gap := Dpi(3);
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(chkInv.Font);
    RowH := Max(Dpi(22), Bmp.Canvas.TextHeight('Hg') + Dpi(6));
  finally
    Bmp.Free;
  end;
  HostW := pnlAgentHost.ClientWidth;
  if HostW < Dpi(100) then
    HostW := Max(Dpi(100), grpAgents.ClientWidth - Dpi(20));
  ColW := Max(Dpi(100), (HostW - Gap) div 2);
  for I := 0 to High(Checks) do
  begin
    Checks[I].AutoSize := False;
    Checks[I].Height := RowH;
    Y := (I div 2) * (RowH + Gap);
    if (I mod 2) = 0 then
      Checks[I].SetBounds(0, Y, ColW, RowH)
    else
      Checks[I].SetBounds(ColW + Gap, Y, ColW, RowH);
  end;
end;

procedure TfrmAgentHubWorkspace.LayoutLeftColumn;
var
  OptH, AgH, LabelW, DepthLW, MaxLW, EditW, RowH, RowGap, Y, HostW, EdH: Integer;
  MinSrc, LeftH, ContentOpt, NeedHost, Gap, Half: Integer;
  OptMarg, AgMarg: Integer;
  Bmp: TBitmap;
begin
  if (pnlLeft = nil) or (grpSources = nil) or (pnlOptHost = nil) then Exit;
  if (pnlDepthRow = nil) or (pnlMaxFilesRow = nil) or (grpAgents = nil) then Exit;
  if FLeftLayoutBusy or (scrLeft.ClientHeight < Dpi(80)) then Exit;
  FLeftLayoutBusy := True;
  try
    SourceButtonsResize(nil);
    LayoutToolBar(pnlRootsTools);

    Bmp := TBitmap.Create;
    try
      Bmp.Canvas.Font.Assign(Font);
      RowH := Max(Dpi(22), Bmp.Canvas.TextHeight('Hg') + Dpi(6));
    finally
      Bmp.Free;
    end;
    RowGap := Dpi(3);
    HostW := pnlOptHost.ClientWidth;
    if HostW < Dpi(120) then
      HostW := Max(Dpi(120), grpOptions.ClientWidth - Dpi(24));

    Y := 0;
    chkSubdirs.Align := alNone;
    chkSubdirs.SetBounds(0, Y, HostW, RowH);
    Inc(Y, RowH + RowGap);

    LabelW := Max(TextPx(lblMask.Font, lblMask.Caption), Dpi(64)) + Dpi(8);
    LabelW := Max(Dpi(64), Min(Dpi(110), LabelW));
    EdH := Max(Dpi(22), RowH - Dpi(2));
    EditW := Dpi(70);

    pnlMaskRow.Align := alNone;
    pnlMaskRow.SetBounds(0, Y, HostW, EdH + Dpi(2));
    lblMask.SetBounds(0, 0, LabelW, pnlMaskRow.Height);
    edtMask.SetBounds(LabelW + Dpi(4), Dpi(1), Max(Dpi(80), HostW - LabelW - Dpi(4)), EdH);
    Inc(Y, pnlMaskRow.Height + RowGap);

    { Depth + Max files on one row, each with its own label width (no clipping). }
    Gap := Dpi(8);
    Half := (HostW - Gap) div 2;
    DepthLW := Max(Dpi(56), TextPx(lblDepth.Font, lblDepth.Caption) + Dpi(6));
    MaxLW := Max(Dpi(56), TextPx(lblMaxFiles.Font, lblMaxFiles.Caption) + Dpi(6));
    if DepthLW + EditW > Half then
      DepthLW := Max(Dpi(48), Half - EditW - Dpi(4));
    if MaxLW + EditW > Half then
      MaxLW := Max(Dpi(48), Half - EditW - Dpi(4));

    pnlDepthRow.Align := alNone;
    pnlDepthRow.SetBounds(0, Y, Half, EdH + Dpi(2));
    lblDepth.SetBounds(0, 0, DepthLW, pnlDepthRow.Height);
    edtDepth.SetBounds(DepthLW + Dpi(2), Dpi(1), EditW, EdH);

    pnlMaxFilesRow.Align := alNone;
    pnlMaxFilesRow.SetBounds(Half + Gap, Y, HostW - Half - Gap, EdH + Dpi(2));
    lblMaxFiles.SetBounds(0, 0, MaxLW, pnlMaxFilesRow.Height);
    edtMaxFiles.SetBounds(MaxLW + Dpi(2), Dpi(1), EditW, EdH);
    Inc(Y, EdH + Dpi(2));

    ContentOpt := Y + pnlOptHost.Margins.Top + pnlOptHost.Margins.Bottom + Dpi(38);
    AgH := Max(AgentsContentHeight, grpAgents.Constraints.MinHeight);
    OptH := ContentOpt;

    OptMarg := grpOptions.Margins.Top + grpOptions.Margins.Bottom;
    AgMarg := grpAgents.Margins.Top + grpAgents.Margins.Bottom;
    MinSrc := pnlSourceBtns.Height + pnlRootFind.Height + pnlRootsTools.Height +
      lstRoots.Constraints.MinHeight + lstRoots.Margins.Top + lstRoots.Margins.Bottom +
      grpSources.Margins.Top + grpSources.Margins.Bottom +
      lstRoots.Parent.Margins.Top + lstRoots.Parent.Margins.Bottom + Dpi(38);
    LeftH := Max(scrLeft.ClientHeight, OptH + OptMarg + AgH + AgMarg + MinSrc);
    pnlLeft.Height := LeftH;

    if grpOptions.Height <> OptH then
      grpOptions.Height := OptH;
    if grpAgents.Height <> AgH then
      grpAgents.Height := AgH;

    LayoutAgents;

    { Skin chrome varies: grow the group until the last checkbox fits in the host. }
    if (chkActions <> nil) and pnlAgentHost.HandleAllocated then
    begin
      NeedHost := chkActions.Top + chkActions.Height + Dpi(6);
      if pnlAgentHost.ClientHeight < NeedHost then
      begin
        AgH := AgH + (NeedHost - pnlAgentHost.ClientHeight);
        pnlLeft.Height := Max(scrLeft.ClientHeight,
          OptH + OptMarg + AgH + AgMarg + MinSrc);
        if grpAgents.Height <> AgH then
          grpAgents.Height := AgH;
        LayoutAgents;
      end;
    end;
  finally
    FLeftLayoutBusy := False;
  end;
  if (pnlOptHost.ClientWidth >= Dpi(120)) and (HostW <> pnlOptHost.ClientWidth) then
    LayoutLeftColumn;
end;

procedure TfrmAgentHubWorkspace.LeftColumnResize(Sender: TObject);
begin
  LayoutLeftColumn;
end;

procedure TfrmAgentHubWorkspace.LayoutSendBar;
var
  Gap, X, H: Integer;

  function BtnW(B: TsButton; AMin: Integer): Integer;
  begin
    Result := Max(Dpi(AMin), TextPx(B.Font, B.Caption) + Dpi(28));
  end;

begin
  if (pnlSend = nil) or (btnSend = nil) then Exit;
  Gap := Dpi(6);
  H := Max(Dpi(32), btnSend.Height + Dpi(8));
  if pnlSend.Height <> H then
    pnlSend.Height := H;
  btnSend.Width := BtnW(btnSend, 100);
  btnStop.Width := BtnW(btnStop, 80);
  btnSend.Height := Dpi(26);
  btnStop.Height := Dpi(26);
  X := pnlSend.ClientWidth - Gap;
  Dec(X, btnSend.Width);
  btnSend.SetBounds(X, (pnlSend.ClientHeight - btnSend.Height) div 2, btnSend.Width, btnSend.Height);
  Dec(X, Gap + btnStop.Width);
  btnStop.SetBounds(X, (pnlSend.ClientHeight - btnStop.Height) div 2, btnStop.Width, btnStop.Height);
  lblSendHint.SetBounds(Dpi(4), 0, Max(Dpi(40), X - Dpi(10)), pnlSend.ClientHeight);
  lblSendHint.Hint := lblSendHint.Caption;
end;

procedure TfrmAgentHubWorkspace.ApplyLanguage;
begin
  lblGuide.Caption := TrText('Hub.Guide');
  grpSources.Caption := TrText('Hub.Sources');
  grpOptions.Caption := ' ' + TrText('Options') + ' ';
  grpAgents.Caption := TrText('Hub.Agents');
  grpPrompt.Caption := TrText('Hub.Step2');
  grpResults.Caption := TrText('Hub.Step3');
  btnAddFiles.Caption := TrText('Hub.AddFiles');
  btnAddFolder.Caption := TrText('Hub.AddFolder');
  btnOpenFile.Caption := TrText('Hub.OpenFile');
  btnRemove.Caption := TrText('Hub.Remove');
  btnSelectAll.Caption := TrText('Hub.SelectAll');
  btnRemoveAll.Caption := TrText('Hub.RemoveAll');
  edtRootFind.TextHint := TrText('Agent.FindRootsHint');
  edtRootFind.Hint := TrText('Agent.FindRootsHint');
  btnRootRecent.Caption := TrText('Agent.RootRecent') + ' ' + #$25BE;
  btnRootRecent.Width := TextPx(btnRootRecent.Font, btnRootRecent.Caption) + Dpi(24);
  btnRootRecent.Hint := TrText('Agent.RootRecentHint');
  btnSend.Caption := TrText('Hub.Analyze');
  btnStop.Caption := TrText('Hub.Stop');
  lblSendHint.Caption := TrText('Hub.SendHint');
  chkSubdirs.Caption := TrText('Hub.IncludeSubdirs');
  lblMask.Caption := TrText('Hub.Mask');
  lblDepth.Caption := TrText('Hub.Depth');
  lblMaxFiles.Caption := TrText('Hub.MaxFiles');
  chkInv.Checked := True;
  chkInv.Enabled := False;
  chkInv.Caption := TrText('Hub.Role.inventory');
  chkStruct.Caption := TrText('Hub.Role.structure');
  chkContent.Caption := TrText('Hub.Role.content');
  chkSql.Caption := TrText('Hub.Role.sql');
  chkPrivacy.Caption := TrText('Hub.Role.privacy');
  chkActions.Caption := TrText('Hub.Role.actions');
  UpdateResultTabs;
  miRootRemove.Caption := TrText('Hub.Remove');
  miRootSelectAll.Caption := TrText('Hub.SelectAll');
  miRootRemoveAll.Caption := TrText('Hub.RemoveAll');

  btnPromptTranslate.Caption := TrText('Assistant.TranslateBtn') + ' ' + #$25BE;
  btnPromptTranslate.Hint := TrText('Assistant.TranslateHint');
  btnPromptSuggest.Caption := TrText('Assistant.RewriteBtn');
  btnPromptSuggest.Hint := TrText('Assistant.RewriteHint');
  btnPromptHelp.Caption := TrText('AICaps.Button');
  btnPromptHelp.Hint := TrText('AICaps.ButtonHint.Hub');

  btnPromptNew.Caption := TrText('Agent.ToolNew');
  btnRootsNew.Caption := TrText('Agent.ToolNew');
  btnAnswerNew.Caption := TrText('Agent.ToolNew');
  btnPromptClear.Caption := TrText('Agent.ToolClear');
  btnRootsClear.Caption := TrText('Agent.ToolClear');
  btnAnswerClear.Caption := TrText('Agent.ToolClear');
  btnPromptCopy.Caption := TrText('Agent.ToolCopy');
  btnRootsCopy.Caption := TrText('Agent.ToolCopy');
  btnAnswerCopy.Caption := TrText('Agent.ToolCopy');
  btnAnswerExport.Caption := TrText('AICaps.Export');
  btnAnswerExport.Hint := TrText('Hub.ExportAnswerHint');
  btnAnswerTranslate.Caption := TrText('Assistant.TranslateBtn') + ' ' + #$25BE;
  btnAnswerTranslate.Hint := TrText('Assistant.TranslateHint');
  btnPromptAsk.Caption := TrText('Agent.ToolAsk');
  btnRootsAsk.Caption := TrText('Agent.ToolAsk');
  btnAnswerAsk.Caption := TrText('Agent.ToolAsk');
  btnPromptNew.Hint := TrText('Agent.ToolNewPromptHint');
  btnRootsNew.Hint := TrText('Agent.ToolNewRootsHint');
  btnAnswerNew.Hint := TrText('Agent.ToolNewAnswerHint');
  btnPromptClear.Hint := TrText('Agent.ToolClearPromptHint');
  btnRootsClear.Hint := TrText('Agent.ToolClearRootsHint');
  btnAnswerClear.Hint := TrText('Agent.ToolClearAnswerHint');
  btnPromptCopy.Hint := TrText('Agent.ToolCopyHint');
  btnRootsCopy.Hint := TrText('Agent.ToolCopyRootsHint');
  btnAnswerCopy.Hint := TrText('Agent.ToolCopyHint');
  btnPromptAsk.Hint := TrText('Agent.ToolAskHint');
  btnRootsAsk.Hint := TrText('Agent.ToolAskHint');
  btnAnswerAsk.Hint := TrText('Agent.ToolAskHint');

  RefreshRecentCombo;
  RefreshRootRecentButton;
  if not FBusy then
    lblStatus.Caption := TrText('Hub.Status.Ready');
  FitTexts;
end;

procedure TfrmAgentHubWorkspace.UpdateResultTabs;
var
  N: Integer;
begin
  if tabAnswer = nil then Exit;
  tabAnswer.Caption := TrText('Answer');
  tabRevised.Caption := TrText('Revised prompt');
  N := 0;
  if (FReport <> nil) then
    N := FReport.Findings.Count;
  if N > 0 then
    tabEdits.Caption := Format('%s (%d)', [TrText('Proposed edits'), N])
  else
    tabEdits.Caption := TrText('Proposed edits');
  N := 0;
  if memFiles <> nil then
    N := memFiles.Lines.Count;
  if N > 0 then
    tabFiles.Caption := Format('%s (%d)', [TrText('Files found'), N])
  else
    tabFiles.Caption := TrText('Files found');
end;

procedure TfrmAgentHubWorkspace.FitTexts;
begin
  if btnSend = nil then Exit;
  chkSubdirs.AutoSize := False;
  chkSubdirs.Height := Dpi(22);
  LayoutToolBar(pnlRootsTools);
  LayoutToolBar(pnlPromptTools);
  LayoutToolBar(pnlAnswerTools);
  LayoutLeftColumn;
  LayoutSendBar;
  LayoutGuide;
  if HandleAllocated then
  begin
    Realign;
    if (lstRoots <> nil) and (lstRoots.Parent <> nil) then
    begin
      lstRoots.Align := alClient;
      lstRoots.Parent.Realign;
    end;
  end;
end;

procedure TfrmAgentHubWorkspace.RefreshRootList;
var
  I: Integer;
  R: TAgentRoot;
  Cap, Find: string;
begin
  Find := Trim(edtRootFind.Text);
  lstRoots.Items.BeginUpdate;
  try
    lstRoots.Items.Clear;
    for I := 0 to FRoots.Count - 1 do
    begin
      R := TAgentRoot(FRoots[I]);
      if R.Kind = arkFolder then
        Cap := '[D] ' + R.Path
      else
        Cap := '[F] ' + R.Path;
      if (Find = '') or (Pos(AnsiLowerCase(Find), AnsiLowerCase(Cap)) > 0) then
        lstRoots.Items.AddObject(Cap, R);
    end;
  finally
    lstRoots.Items.EndUpdate;
  end;
end;

procedure TfrmAgentHubWorkspace.AddRoot(AKind: TAgentRootKind; const APath: string);
var
  R: TAgentRoot;
  Full: string;
  I: Integer;
begin
  Full := ExpandFileName(Trim(APath));
  if Full = '' then Exit;
  for I := 0 to FRoots.Count - 1 do
    if SameText(TAgentRoot(FRoots[I]).Path, Full) then
      Exit;
  R := TAgentRoot.Create;
  R.Kind := AKind;
  R.Path := Full;
  FRoots.Add(R);
  RememberAgentRoot(FRootRecent, Full);
  FRootRecentDirty := True;
  RefreshRootList;
  RefreshRootRecentButton;
end;

procedure TfrmAgentHubWorkspace.ClearRoots;
begin
  FRoots.Clear;
  RefreshRootList;
end;

function TfrmAgentHubWorkspace.ReadPrefs: TAgentPrefs;
begin
  Result := DefaultAgentPrefs;
  Result.IncludeSubdirs := chkSubdirs.Checked;
  Result.Mask := Trim(edtMask.Text);
  if Result.Mask = '' then
    Result.Mask := DefaultAgentPrefs.Mask;
  Result.MaxDepth := StrToIntDef(Trim(edtDepth.Text), Result.MaxDepth);
  Result.MaxFiles := StrToIntDef(Trim(edtMaxFiles.Text), Result.MaxFiles);
  if Result.MaxDepth < 0 then Result.MaxDepth := 0;
  if Result.MaxFiles < 1 then Result.MaxFiles := 1;
  if Result.MaxFiles > 20000 then Result.MaxFiles := 20000;
end;

function TfrmAgentHubWorkspace.ForcedRolesText: string;
var
  SL: TStringList;
  I: Integer;
begin
  if chkStruct.Checked and chkContent.Checked and not chkSql.Checked and
     not chkPrivacy.Checked and not chkActions.Checked then
    Exit('');
  SL := TStringList.Create;
  try
    SL.Add('inventory');
    if chkStruct.Checked then SL.Add('structure');
    if chkContent.Checked then SL.Add('content');
    if chkSql.Checked then SL.Add('sql');
    if chkPrivacy.Checked then SL.Add('privacy');
    if chkActions.Checked then SL.Add('actions');
    Result := '';
    for I := 0 to SL.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + SL[I];
    end;
  finally
    SL.Free;
  end;
end;

procedure TfrmAgentHubWorkspace.SetBusy(AValue: Boolean);
begin
  FBusy := AValue;
  btnSend.Enabled := not AValue and not FAskBusy;
  btnStop.Enabled := AValue;
  btnAddFiles.Enabled := not AValue;
  btnAddFolder.Enabled := not AValue;
  btnOpenFile.Enabled := not AValue;
  btnRemove.Enabled := not AValue;
  btnSelectAll.Enabled := not AValue;
  btnRemoveAll.Enabled := not AValue;
  btnRootRecent.Enabled := (FRootRecent.Count > 0) and not AValue;
  pnlRecentCombo.Enabled := (FRecent.Count > 0) and not AValue and not FAskBusy;
  memPrompt.ReadOnly := AValue or FAskBusy;
  btnPromptTranslate.Enabled := not AValue and not FAskBusy;
  btnPromptSuggest.Enabled := not AValue and not FAskBusy;
  btnPromptHelp.Enabled := not AValue and not FAskBusy;
  btnAnswerNew.Enabled := not AValue and not FAskBusy;
  btnAnswerClear.Enabled := not AValue and not FAskBusy;
  if memAnswer <> nil then
  begin
    btnAnswerExport.Enabled := Trim(memAnswer.Text) <> '';
    btnAnswerTranslate.Enabled := btnAnswerExport.Enabled and not AValue and not FAskBusy;
  end;
end;

procedure TfrmAgentHubWorkspace.AnswerChange(Sender: TObject);
begin
  SetBusy(FBusy);
end;

procedure TfrmAgentHubWorkspace.AnswerExportClick(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  if Trim(memAnswer.Text) = '' then
  begin
    lblStatus.Caption := TrText('Nothing to export');
    Exit;
  end;
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Title := TrText('AICaps.Export');
    Dlg.Filter := TrText('AICaps.ExportFilter');
    Dlg.DefaultExt := 'txt';
    Dlg.OnTypeChange := AnswerExportTypeChange;
    Dlg.Options := Dlg.Options + [ofOverwritePrompt, ofPathMustExist];
    Dlg.FileName := 'FastFile-AI-diagnosis';
    if not Dlg.Execute(Handle) then Exit;
    memAnswer.Lines.SaveToFile(Dlg.FileName, TEncoding.UTF8);
    lblStatus.Caption := TrText('AICaps.Saved');
  finally
    Dlg.Free;
  end;
end;

procedure TfrmAgentHubWorkspace.AnswerExportTypeChange(Sender: TObject);
begin
  if TSaveDialog(Sender).FilterIndex = 2 then
    TSaveDialog(Sender).DefaultExt := 'md'
  else
    TSaveDialog(Sender).DefaultExt := 'txt';
end;

procedure TfrmAgentHubWorkspace.AppendTimeline(const ALine: string);
begin
  { Timeline lines feed the revised tab while a run is in progress. }
  if memRevised <> nil then
    memRevised.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + ALine);
end;

procedure TfrmAgentHubWorkspace.ShowReport;
var
  I: Integer;
  F: THubFinding;
  SL: TStringList;
begin
  if FReport = nil then Exit;
  memAnswer.Text := HubDisplayText(FReport.Markdown);
  if FReport.Findings.Count = 0 then
    memEdits.Text := TrText('Hub.EditsEmpty')
  else
  begin
    SL := TStringList.Create;
    try
      for I := 0 to FReport.Findings.Count - 1 do
      begin
        F := FReport.Findings[I];
        SL.Add(Format('[%s] %s ' + #$2014 + ' %s',
          [HubSeverityId(F.Severity), HubDisplayText(F.Title), F.Evidence.FilePath]));
        if Trim(F.Description) <> '' then
          SL.Add('  ' + HubDisplayText(F.Description));
        if Trim(F.Recommendation) <> '' then
          SL.Add('  -> ' + HubDisplayText(F.Recommendation));
        SL.Add('');
      end;
      memEdits.Text := HubDisplayText(SL.Text);
    finally
      SL.Free;
    end;
  end;
  if Trim(FReport.Objective) <> '' then
    memRevised.Text := HubDisplayText(FReport.Objective + sLineBreak + sLineBreak +
      FReport.ExecutiveSummary)
  else
    memRevised.Text := HubDisplayText(FReport.ExecutiveSummary);
  memFiles.Text := HubDisplayText(FReport.InventorySection);
  UpdateResultTabs;
  pcMain.ActivePage := tabAnswer;
end;

procedure TfrmAgentHubWorkspace.RefreshRecentCombo;
begin
  if (pnlRecentCombo = nil) or (FRecent = nil) then Exit;
  pnlRecentCombo.Enabled := (FRecent.Count > 0) and not FBusy and not FAskBusy;
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

procedure TfrmAgentHubWorkspace.RefreshRootRecentButton;
begin
  if (btnRootRecent = nil) or (FRootRecent = nil) then Exit;
  btnRootRecent.Enabled := (FRootRecent.Count > 0) and not FBusy;
end;

procedure TfrmAgentHubWorkspace.FlushRootRecent;
begin
  if FRootRecentDirty and (FRootRecent <> nil) then
  begin
    FRootRecentDirty := False;
    SaveAgentRootRecent(FRootRecent);
  end;
end;

procedure TfrmAgentHubWorkspace.AddFilesClick(Sender: TObject);
var
  I: Integer;
begin
  if FBusy then Exit;
  if not dlgOpen.Execute then Exit;
  for I := 0 to dlgOpen.Files.Count - 1 do
    AddRoot(arkFile, dlgOpen.Files[I]);
  FlushRootRecent;
end;

procedure TfrmAgentHubWorkspace.AddFolderClick(Sender: TObject);
var
  Picked: TStringList;
  Start: string;
  I: Integer;
begin
  if FBusy then Exit;
  Start := '';
  for I := FRoots.Count - 1 downto 0 do
    if TAgentRoot(FRoots[I]).Kind = arkFolder then
    begin
      Start := TAgentRoot(FRoots[I]).Path;
      Break;
    end;
  Picked := TStringList.Create;
  try
    if not PickFolders(Self, fpkHub, Picked, Start) then Exit;
    for I := 0 to Picked.Count - 1 do
      AddRoot(arkFolder, Picked[I]);
    FlushRootRecent;
  finally
    Picked.Free;
  end;
end;

procedure TfrmAgentHubWorkspace.OpenFileClick(Sender: TObject);
var
  P: string;
begin
  if FBusy then Exit;
  P := '';
  if Assigned(OnGetOpenFile) then
    P := Trim(OnGetOpenFile())
  else
    P := Trim(AssistantHostGetOpenFilePath);
  if (P <> '') and FileExists(P) then
    AddRoot(arkFile, P)
  else
    lblStatus.Caption := TrText('Select a file or folder first.');
end;

procedure TfrmAgentHubWorkspace.RemoveClick(Sender: TObject);
var
  I: Integer;
  Obj: TObject;
begin
  if FBusy or (lstRoots.SelCount = 0) then Exit;
  for I := lstRoots.Items.Count - 1 downto 0 do
    if lstRoots.Selected[I] then
    begin
      Obj := lstRoots.Items.Objects[I];
      if Obj <> nil then
        FRoots.Remove(Obj);
    end;
  RefreshRootList;
end;

procedure TfrmAgentHubWorkspace.SelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lstRoots.Items.Count - 1 do
    lstRoots.Selected[I] := True;
end;

procedure TfrmAgentHubWorkspace.RemoveAllClick(Sender: TObject);
begin
  if FBusy then Exit;
  ClearRoots;
end;

procedure TfrmAgentHubWorkspace.RootFindChange(Sender: TObject);
begin
  RefreshRootList;
end;

procedure TfrmAgentHubWorkspace.RootRecentClick(Sender: TObject);
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

procedure TfrmAgentHubWorkspace.OpenRootRecentPopup;
begin
  if (btnRootRecent = nil) or not btnRootRecent.Enabled then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if FRootRecentPosted then Exit;
  Application.CancelHint;
  ReleaseCapture;
  FRootRecentPosted := True;
  PostMessage(Handle, WM_APP + 49, 0, 0);
end;

procedure TfrmAgentHubWorkspace.WMRootRecentPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  OwnerComp: TComponent;
begin
  FRootRecentPosted := False;
  if ((GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0)) and
     (Msg.WParam < 20) then
  begin
    FRootRecentPosted := True;
    PostMessage(Handle, WM_APP + 49, Msg.WParam + 1, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if (FRootRecent = nil) or (FRootRecent.Count = 0) then Exit;
  W := Max(Dpi(280), btnRootRecent.Width + edtRootFind.Width);
  P := btnRootRecent.ClientToScreen(Point(btnRootRecent.Width - W, btnRootRecent.Height));
  if Assigned(Application.MainForm) then
    OwnerComp := Application.MainForm
  else
    OwnerComp := Self;
  ShowMruListPopup(OwnerComp, TrText('Agent.RootRecentTitle'), MruMoreCaption('RecentFiles.More'),
    FRootRecent, W, P, RootRecentPick, '', nil, RootRecentRemove, btnRootRecent, RootRecentClearAll);
end;

procedure TfrmAgentHubWorkspace.RootRecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
begin
  if DirectoryExists(AValue) then
    AddRoot(arkFolder, AValue)
  else if FileExists(AValue) then
    AddRoot(arkFile, AValue)
  else
    lblStatus.Caption := Format(TrText('Agent.RootRecentMissing'), [AValue]);
  FlushRootRecent;
end;

procedure TfrmAgentHubWorkspace.RootRecentRemove(Sender: TObject; const AValue: string);
var
  I: Integer;
begin
  if FRootRecent = nil then Exit;
  for I := FRootRecent.Count - 1 downto 0 do
    if SameText(FRootRecent[I], AValue) then
      FRootRecent.Delete(I);
  FRootRecentDirty := True;
  FlushRootRecent;
  RefreshRootRecentButton;
end;

procedure TfrmAgentHubWorkspace.RootRecentClearAll(Sender: TObject);
begin
  if FRootRecent = nil then Exit;
  FRootRecent.Clear;
  FRootRecentDirty := True;
  FlushRootRecent;
  RefreshRootRecentButton;
end;

procedure TfrmAgentHubWorkspace.RecentComboClick(Sender: TObject);
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

procedure TfrmAgentHubWorkspace.OpenRecentPopup;
begin
  if (pnlRecentCombo = nil) or not pnlRecentCombo.Enabled then Exit;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then Exit;
  if FRecentPosted then Exit;
  Application.CancelHint;
  ReleaseCapture;
  FRecentPosted := True;
  PostMessage(Handle, WM_APP + 45, 0, 0);
end;

procedure TfrmAgentHubWorkspace.WMRecentPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
  OwnerComp: TComponent;
begin
  FRecentPosted := False;
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

procedure TfrmAgentHubWorkspace.RecentPick(Sender: TObject; const AValue: string; AIndex: Integer);
begin
  memPrompt.Text := AValue;
  memPrompt.SelStart := Length(memPrompt.Text);
  if memPrompt.CanFocus then
    memPrompt.SetFocus;
end;

procedure TfrmAgentHubWorkspace.RecentRemove(Sender: TObject; const AValue: string);
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

procedure TfrmAgentHubWorkspace.RecentClearAll(Sender: TObject);
begin
  if FRecent = nil then Exit;
  FRecent.Clear;
  SaveAgentRecent(FRecent);
  RefreshRecentCombo;
end;

procedure TfrmAgentHubWorkspace.PromptKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    SendClick(nil);
  end
  else if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    Key := 0;
    OpenRecentPopup;
  end;
end;

procedure TfrmAgentHubWorkspace.PromptTranslateClick(Sender: TObject);
var
  Lang: TAppLanguage;
  It: TMenuItem;
  Pt: TPoint;
  Target: TsMemo;
begin
  if FBusy or FAskBusy then Exit;
  Target := memPrompt;
  if Sender = btnAnswerTranslate then
    Target := memAnswer;
  if Trim(Target.Text) = '' then
  begin
    lblStatus.Caption := TrText('Assistant.Error.EmptyQuestion');
    Exit;
  end;
  if mnuTranslate = nil then
  begin
    mnuTranslate := TPopupMenu.Create(Self);
    mnuTranslate.Name := 'mnuTranslate';
    mnuTranslate.AutoHotkeys := maManual;
  end;
  mnuTranslate.Items.Clear;
  for Lang := Low(TAppLanguage) to High(TAppLanguage) do
  begin
    It := TMenuItem.Create(mnuTranslate);
    It.Caption := AssistantLangMenuCaption(Lang);
    It.Tag := Ord(Lang);
    if Target = memAnswer then
      It.HelpContext := 4
    else
      It.HelpContext := 1;
    It.OnClick := PromptTranslateLangClick;
    mnuTranslate.Items.Add(It);
  end;
  if Target = memAnswer then
    Pt := btnAnswerTranslate.ClientToScreen(Point(0, btnAnswerTranslate.Height))
  else
    Pt := btnPromptTranslate.ClientToScreen(Point(0, btnPromptTranslate.Height));
  mnuTranslate.Popup(Pt.X, Pt.Y);
end;

procedure TfrmAgentHubWorkspace.PromptTranslateLangClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    StartPromptTextJob(TMenuItem(Sender).HelpContext,
      AssistantLangPromptName(TAppLanguage(TMenuItem(Sender).Tag)));
end;

procedure TfrmAgentHubWorkspace.PromptSuggestClick(Sender: TObject);
begin
  StartPromptTextJob(2, '');
end;

procedure TfrmAgentHubWorkspace.StartPromptTextJob(AJob: Integer; const ALangName: string);
var
  Src, P: string;
begin
  if FBusy or FAskBusy then Exit;
  if AJob = 4 then
    Src := Trim(memAnswer.Text)
  else if memPrompt.SelLength > 0 then
    Src := Trim(memPrompt.SelText)
  else
    Src := Trim(memPrompt.Text);
  if Src = '' then
  begin
    lblStatus.Caption := TrText('Assistant.Error.EmptyQuestion');
    Exit;
  end;
  if AJob in [1, 4] then
    P := string(BuildAssistantTranslatePromptW(Src, ALangName))
  else
    P := 'You help the user write a clearer diagnosis request for FastFile AI diagnosis.' + sLineBreak +
      'The hub inventories folders/files and runs specialist analyses (read-only).' + sLineBreak +
      'Rewrite USER_DRAFT as one clear, complete diagnosis request.' + sLineBreak +
      'Keep the user intent and the language of the draft.' + sLineBreak +
      'Reply with ONE JSON object only (no markdown):' + sLineBreak +
      '{"resposta":"<improved request only>"}' + sLineBreak +
      'In JSON, encode any non-ASCII letter as \\uXXXX (UTF-16), not raw bytes.' + sLineBreak + sLineBreak +
      'USER_DRAFT:' + sLineBreak + Src;
  FAskBusy := True;
  SetBusy(FBusy);
  lblStatus.Caption := TrText('Assistant.Thinking');
  TAskWorker.Create(Handle, AJob, P);
end;

procedure TfrmAgentHubWorkspace.PromptHelpClick(Sender: TObject);
begin
  ShowCapabilities;
end;

procedure TfrmAgentHubWorkspace.ShowCapabilities;
var
  Ex, Q: string;
begin
  case ShowAICapabilities(ackHub, Ex, Q) of
    accExample:
      begin
        memPrompt.Text := Ex;
        if memPrompt.CanFocus then
          memPrompt.SetFocus;
        lblStatus.Caption := TrText('AICaps.ExampleReady');
      end;
    accAsk:
      begin
        if Trim(Q) <> '' then
          memPrompt.Text := Q
        else if Trim(Ex) <> '' then
          memPrompt.Text := Ex;
      end;
  end;
end;

procedure TfrmAgentHubWorkspace.ToolNewClick(Sender: TObject);
var
  Tag: Integer;
begin
  if Sender is TControl then
    Tag := TControl(Sender).Tag
  else
    Tag := 1;
  case Tag of
    1:
      if Trim(memPrompt.Text) <> '' then
      begin
        RememberAgentPrompt(FRecent, memPrompt.Text);
        SaveAgentRecent(FRecent);
        RefreshRecentCombo;
        memPrompt.Clear;
        lblStatus.Caption := TrText('Agent.NewPromptSaved');
      end;
    2:
      ClearRoots;
    3:
      memAnswer.Clear;
  end;
  SetBusy(FBusy);
end;

procedure TfrmAgentHubWorkspace.ToolClearClick(Sender: TObject);
var
  Tag: Integer;
begin
  if Sender is TControl then
    Tag := TControl(Sender).Tag
  else
    Tag := 1;
  case Tag of
    1: memPrompt.Clear;
    2: ClearRoots;
    3:
      begin
        memAnswer.Clear;
        memEdits.Clear;
        memRevised.Clear;
        memFiles.Clear;
        UpdateResultTabs;
      end;
  end;
  SetBusy(FBusy);
end;

procedure TfrmAgentHubWorkspace.ToolCopyClick(Sender: TObject);
var
  Tag: Integer;
  S: string;
  I: Integer;
begin
  if Sender is TControl then
    Tag := TControl(Sender).Tag
  else
    Tag := 1;
  S := '';
  case Tag of
    1: S := memPrompt.Text;
    2:
      for I := 0 to FRoots.Count - 1 do
      begin
        if S <> '' then S := S + sLineBreak;
        S := S + TAgentRoot(FRoots[I]).Path;
      end;
    3: S := memAnswer.Text;
  end;
  if S <> '' then
  begin
    Clipboard.AsText := S;
    lblStatus.Caption := TrText('Agent.Copied');
  end;
end;

procedure TfrmAgentHubWorkspace.ToolAskClick(Sender: TObject);
var
  Q, Body, P: string;
  Tag, I: Integer;
begin
  if FBusy or FAskBusy then Exit;
  if not InputQuery(TrText('Agent.ToolAsk'), TrText('Agent.AskQuestion'), Q) then Exit;
  Q := Trim(Q);
  if Q = '' then Exit;
  if Sender is TControl then
    Tag := TControl(Sender).Tag
  else
    Tag := 1;
  case Tag of
    2:
      begin
        Body := '';
        for I := 0 to FRoots.Count - 1 do
          Body := Body + TAgentRoot(FRoots[I]).Path + sLineBreak;
      end;
    3: Body := memAnswer.Text;
  else
    Body := memPrompt.Text;
  end;
  P := 'Answer the user question about the FastFile AI diagnosis context below.' + sLineBreak +
    'Reply in the same language as the question.' + sLineBreak +
    'Question: ' + Q + sLineBreak + sLineBreak +
    'Context:' + sLineBreak + Copy(Body, 1, 12000);
  FAskBusy := True;
  SetBusy(FBusy);
  lblStatus.Caption := TrText('Assistant.Thinking');
  TAskWorker.Create(Handle, 3, P);
end;

procedure TfrmAgentHubWorkspace.WMAskDone(var Msg: TMessage);
var
  N: TAskNote;
  S, Resp: string;
  P1, P2: Integer;
begin
  N := TAskNote(Msg.LParam);
  if N = nil then Exit;
  try
    FAskBusy := False;
    SetBusy(FBusy);
    if not N.Ok then
    begin
      lblStatus.Caption := N.Err;
      Exit;
    end;
    S := HubDisplayText(Trim(string(UnescapeJsonUnicodeWide(WideString(N.Text)))));
    if N.Job in [1, 2, 4] then
    begin
      Resp := S;
      P1 := Pos('"resposta"', LowerCase(S));
      if P1 = 0 then
        P1 := Pos('"answer"', LowerCase(S));
      if P1 > 0 then
      begin
        P1 := Pos(':', S, P1);
        if P1 > 0 then
        begin
          while (P1 <= Length(S)) and (S[P1] <> '"') do Inc(P1);
          if (P1 > 0) and (P1 <= Length(S)) then
          begin
            Inc(P1);
            P2 := P1;
            while (P2 <= Length(S)) and (S[P2] <> '"') do
            begin
              if (S[P2] = '\') and (P2 < Length(S)) then
                Inc(P2);
              Inc(P2);
            end;
            if P2 > P1 then
              Resp := Copy(S, P1, P2 - P1);
          end;
        end;
      end;
      Resp := StringReplace(Resp, '\n', sLineBreak, [rfReplaceAll]);
      Resp := StringReplace(Resp, '\"', '"', [rfReplaceAll]);
      if N.Job = 4 then
        memAnswer.Text := HubDisplayText(Resp)
      else
        memPrompt.Text := HubDisplayText(Resp);
      lblStatus.Caption := TrText('Hub.Status.Ready');
    end
    else
    begin
      memAnswer.Text := HubDisplayText(S);
      pcMain.ActivePage := tabAnswer;
      lblStatus.Caption := TrText('Hub.Status.Ready');
    end;
  finally
    N.Free;
  end;
end;

procedure TfrmAgentHubWorkspace.StopClick(Sender: TObject);
begin
  FCancel := 1;
  lblStatus.Caption := TrText('Hub.Status.Stopping');
end;

procedure TfrmAgentHubWorkspace.SendClick(Sender: TObject);
var
  Roots: TStringList;
  Opt: THubRunOptions;
  I: Integer;
  R: TAgentRoot;
  CopyRoot: TAgentRoot;
  Data: TSearchResult;
  Hit: TSearchHit;
  Mark: Boolean;
  Pending: array[0..0] of TAssistantChainStep;
begin
  if FBusy or FAskBusy then Exit;
  if IsSearchCommandLauncher(memPrompt.Text) then
  begin
    Roots := TStringList.Create;
    try
      for I := 0 to FRoots.Count - 1 do
      begin
        R := TAgentRoot(FRoots[I]);
        if R.Kind = arkFolder then Roots.Add('D|' + R.Path)
        else Roots.Add('F|' + R.Path);
      end;
      if ShowSearchCommand(Self, Trim(memPrompt.Text), Roots, ReadPrefs, '', nil,
        Data, Hit, Mark, nil, False) and (Hit.Path <> '') then
      begin
        if (Hit.Line > 0) and (Hit.Line <= MaxInt) then
        begin
          Pending[0] := Default(TAssistantChainStep);
          Pending[0].ActionId := 'goto_line';
          Pending[0].Path := Hit.Path;
          Pending[0].LineNo := Integer(Hit.Line);
          AssistantHostSetChain(Pending, 1, True);
        end;
        AssistantHostOpenAndRead(Hit.Path);
      end;
    finally
      Roots.Free;
    end;
    Exit;
  end;
  if FRoots.Count = 0 then
  begin
    FastFileMsgInfo(TrText('Hub.NeedSources'));
    Exit;
  end;
  if Trim(memPrompt.Text) = '' then
  begin
    FastFileMsgInfo(TrText('Hub.NeedPrompt'));
    Exit;
  end;
  RememberAgentPrompt(FRecent, memPrompt.Text);
  SaveAgentRecent(FRecent);
  RefreshRecentCombo;
  FlushRootRecent;

  FCancel := 0;
  FreeAndNil(FReport);
  memAnswer.Clear;
  memEdits.Clear;
  memRevised.Clear;
  memFiles.Clear;
  AppendTimeline(TrText('Hub.Status.Starting'));
  SetBusy(True);
  lblStatus.Caption := TrText('Hub.Status.Running');

  Roots := TStringList.Create;
  for I := 0 to FRoots.Count - 1 do
  begin
    R := TAgentRoot(FRoots[I]);
    CopyRoot := TAgentRoot.Create;
    CopyRoot.Kind := R.Kind;
    CopyRoot.Path := R.Path;
    Roots.AddObject(CopyRoot.Path, CopyRoot);
  end;
  Opt := DefaultHubRunOptions;
  Opt.Request := Trim(memPrompt.Text);
  Opt.Prefs := ReadPrefs;
  Opt.ForcedRoles := ForcedRolesText;
  THubWorker.Create(Handle, Roots, Opt, @FCancel);
end;

procedure TfrmAgentHubWorkspace.WMHubStatus(var Msg: TMessage);
var
  N: THubNote;
  PhaseKey, Line: string;
begin
  N := THubNote(Msg.LParam);
  if N = nil then Exit;
  try
    FPhase := N.Phase;
    PhaseKey := 'Hub.Phase.' + HubPhaseId(N.Phase);
    Line := TrText(PhaseKey);
    if Line = PhaseKey then
      Line := HubPhaseId(N.Phase);
    if N.Detail <> '' then
      Line := Line + ' ' + #$2014 + ' ' + HubDisplayText(N.Detail);
    AppendTimeline(Line);
    lblStatus.Caption := Line;
  finally
    N.Free;
  end;
end;

procedure TfrmAgentHubWorkspace.WMHubDone(var Msg: TMessage);
var
  N: THubNote;
begin
  N := THubNote(Msg.LParam);
  if N = nil then Exit;
  try
    FreeAndNil(FReport);
    FReport := N.Report;
    N.Report := nil;
    SetBusy(False);
    if FCancel <> 0 then
    begin
      lblStatus.Caption := TrText('Hub.Status.Cancelled');
      AppendTimeline(TrText('Hub.Status.Cancelled'));
    end
    else if (FReport <> nil) and N.Ok then
    begin
      ShowReport;
      lblStatus.Caption := Format(TrText('Hub.Status.Done'), [FReport.Findings.Count]);
    end
    else
    begin
      lblStatus.Caption := TrText('Hub.Status.Failed');
      AppendTimeline(TrText('Hub.Status.Failed'));
    end;
  finally
    N.Free;
  end;
end;

class function TfrmAgentHubWorkspace.ExecuteEmbedded(AOwner: TComponent;
  AHost: TWinControl): TfrmAgentHubWorkspace;
begin
  Result := TfrmAgentHubWorkspace.CreateNew(AOwner);
  { Parent/BorderStyle BEFORE BuildUi — otherwise the first child Parent:=Self
    allocates a top-level HWND that later paints through Ler Arquivo. }
  Result.BorderStyle := bsNone;
  Result.AutoScroll := False;
  Result.Visible := False;
  if AHost <> nil then
  begin
    Result.Parent := AHost;
    Result.Align := alClient;
  end;
  Result.BuildUi;
  Result.FitTexts;
end;

end.
