unit uFindOccurrencesBar;
{ Docked Find Occurrences frame after Ctrl+F.
  Prev/Next (Shift+F3 / F3), collect hits into a paginated clickable list
  (click → jump ListView/CheckList), Load more for next hit page from disk. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  Math, Buttons, Menus, sPanel, sLabel, sButton, sSpeedButton, uFastFileScale, uSearchCommands,
  uSoftPanelButtons, uPanelSearchMru;

type
  TFindOccHitEvent = procedure(Sender: TObject; AHitIndex: Int64) of object;
  TFindOccPageExportEvent = procedure(Sender: TObject;
    AAllMatches, AToClipboard: Boolean) of object;

  TFastFileFindOccBar = class(TsPanel)
  private
    FBuilt: Boolean;
    FExpanded: Boolean;
    FShown: Boolean;
    FStacking: Boolean;
    FAccent: TsPanel;
    FBody: TsPanel;
    FTopRow: TsPanel;
    FStatusRow: TsPanel;
    FSearchRow: TsPanel;
    FBtnRow: TsPanel;
    FListHost: TsPanel;
    FListShell: TsPanel;
    FListInner: TsPanel;
    FPageBar: TsPanel;
    FLblTitle: TsLabel;
    FLblStatus: TsLabel;
    FLblPage: TsLabel;
    FRecentRow: TsPanel;
    FLblRecent: TsLabel;
    FCmbRecent: TComboBox;
    FMru: TPanelSearchMru;
    FEditShell: TsPanel;
    FEditFrame: TsPanel;
    FEdtFind: TEdit;
    FBtnGo: TsButton;
    FBtnGrep, FBtnGlob: TsButton;
    FOnCommand: TSearchCommandOpenEvent;
    FBtnPrev: TsButton;
    FBtnNext: TsButton;
    FBtnCollect: TsButton;
    FBtnLoadMore: TsButton;
    FBtnExport: TsButton;
    FBtnCopy: TsButton;
    FBtnClear: TsButton;
    FBtnClose: TsButton;
    FBtnHide: TsButton;
    FBtnFloat: TsButton;
    FBtnListToggle: TsButton;
    FListCollapsed: Boolean;
    FOnListToggled: TNotifyEvent;
    FBtnPagePrev: TsButton;
    FBtnPageNext: TsButton;
    FBtnPageExport: TsButton;
    FPageMenu: TPopupMenu;
    FTotalHits: Integer;
    FPageIndex: Integer;
    FPageCount: Integer;
    FOnPageExport: TFindOccPageExportEvent;
    FHitList: TListBox;
    FHitTimer: TTimer;
    FPendingHit: Int64;
    FLastFiredHit: Int64;
    FLastFireTick: Cardinal;
    FHitPageBase: Int64;
    FOnPrev: TNotifyEvent;
    FOnNext: TNotifyEvent;
    FOnSearch: TNotifyEvent;
    FOnCollect: TNotifyEvent;
    FOnLoadMore: TNotifyEvent;
    FOnExport: TNotifyEvent;
    FOnCopy: TNotifyEvent;
    FOnClear: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FOnFloat: TNotifyEvent;
    FOnTearOff: TNotifyEvent;
    FOnHitClick: TFindOccHitEvent;
    FOnListPagePrev: TNotifyEvent;
    FOnListPageNext: TNotifyEvent;
    FFloating: Boolean;
    FUserHeight: Integer;
    FChromeH: Integer;
    FOnHeightChanged: TNotifyEvent;
    FHeaderDown: Boolean;
    FHeaderPt: TPoint;
    FBtnChevron: TsSpeedButton;
    FCollapseMask: TsPanel;
    FCollapsed: Boolean;
    FOnHeaderClick: TNotifyEvent;
    procedure BuildFrame;
    procedure ChevronClick(Sender: TObject);
    procedure ForceColor(APnl: TsPanel; AColor: TColor);
    procedure StyleBtn(ABtn: TsButton; const AUiFont: string;
      ARole: TSoftPanelBtnRole = spbrAction);
    procedure StyleFrameBtn(ABtn: TsButton; const AUiFont: string);
    procedure LayoutFrame;
    procedure StackChromeRows;
    procedure BodyResize(Sender: TObject);
    procedure BtnPrevClick(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure BtnGoClick(Sender: TObject);
    procedure BtnCommandClick(Sender: TObject);
    procedure EdtFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnCollectClick(Sender: TObject);
    procedure BtnLoadMoreClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnHideClick(Sender: TObject);
    procedure BtnFloatClick(Sender: TObject);
    procedure BtnListToggleClick(Sender: TObject);
    procedure SyncListToggle;
    procedure BtnPagePrevClick(Sender: TObject);
    procedure BtnPageNextClick(Sender: TObject);
    procedure HitListDblClick(Sender: TObject);
    procedure HitListClick(Sender: TObject);
    procedure QueueHitClick;
    procedure HitTimerTick(Sender: TObject);
    procedure BtnPageExportClick(Sender: TObject);
    procedure PageMenuClick(Sender: TObject);
    procedure SyncPageExportWidth;
    procedure TitleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SyncFloatAction;
    procedure CmbRecentDropDown(Sender: TObject);
    procedure CmbRecentChange(Sender: TObject);
    procedure CmbRecentCloseUp(Sender: TObject);
    procedure FindOccMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure FindOccMruClearAll(Sender: TObject);
    procedure WMFindOccMruPopup(var Msg: TMessage); message WM_APP + 74;
    procedure RefreshRecentCombo;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EnsureBuilt;
    procedure SetIniPath(const APath: string);
    procedure RememberSearch(const AText: string);
    procedure ApplyCaptions;
    procedure ApplySoftFrame;
    procedure SetStatus(const AStatusText: string; ABusy, AHasHits, APartial: Boolean);
    procedure SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
    procedure SetCollectEnabled(AEnabled: Boolean);
    procedure SetExpanded(AExpanded: Boolean);
    procedure SetChromeShown(AShown: Boolean);
    procedure ClearHitList;
    function PreferredExpandedHeight: Integer;
    function FrameHeight: Integer;
    function ExpandedMinHeight: Integer;
    property Expanded: Boolean read FExpanded;
    { User hid the hit list (title-bar toggle) while hits still exist. }
    property ListCollapsed: Boolean read FListCollapsed;
    procedure ToggleHitList;
    property OnListToggled: TNotifyEvent read FOnListToggled write FOnListToggled;
    { Docked: chrome height changed (buttons wrapped or appeared). }
    property OnHeightChanged: TNotifyEvent read FOnHeightChanged write FOnHeightChanged;
    { Last height the user chose while the hit list was open. 0 = not yet. }
    property UserHeight: Integer read FUserHeight write FUserHeight;
    function GetSearchText: string;
    procedure SetSearchText(const AText: string);
    procedure FocusSearchEdit;
    function SearchEditFocused: Boolean;
    procedure SetHitListPage(ALines: TStrings; APageBase: Int64;
      APageIndex, APageCount, ATotalHits: Integer; ACanPagePrev, ACanPageNext: Boolean);
    property OnPrev: TNotifyEvent read FOnPrev write FOnPrev;
    property OnNext: TNotifyEvent read FOnNext write FOnNext;
    property OnSearch: TNotifyEvent read FOnSearch write FOnSearch;
    property OnCommand: TSearchCommandOpenEvent read FOnCommand write FOnCommand;
    property OnCollect: TNotifyEvent read FOnCollect write FOnCollect;
    property OnLoadMore: TNotifyEvent read FOnLoadMore write FOnLoadMore;
    property OnContinue: TNotifyEvent read FOnLoadMore write FOnLoadMore;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnCopy: TNotifyEvent read FOnCopy write FOnCopy;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnFloat: TNotifyEvent read FOnFloat write FOnFloat;
    property OnTearOff: TNotifyEvent read FOnTearOff write FOnTearOff;
    property OnHitClick: TFindOccHitEvent read FOnHitClick write FOnHitClick;
    property OnListPagePrev: TNotifyEvent read FOnListPagePrev write FOnListPagePrev;
    property OnListPageNext: TNotifyEvent read FOnListPageNext write FOnListPageNext;
    { Page bar menu: export or copy the shown page or every match. }
    property OnPageExport: TFindOccPageExportEvent read FOnPageExport write FOnPageExport;
    function HitListFocused: Boolean;
    { A hit click is waiting for the debounce to run. }
    function HitJumpPending: Boolean;
    procedure SetFloatingLook(AFloating: Boolean);
    procedure RelayoutAfterDock;
    { Height of the title row alone (collapsed accordion card). }
    function HeaderHeight: Integer;
    procedure SetCollapsed(AValue: Boolean);
    property Collapsed: Boolean read FCollapsed;
    { Docked: title clicked (not dragged) or chevron pressed. }
    property OnHeaderClick: TNotifyEvent read FOnHeaderClick write FOnHeaderClick;
  end;

  TFastFileFindOccPeek = class(TsPanel)
  private
    FOnRestore: TNotifyEvent;
    procedure PeekClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplySoftFrame;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

const
  FIND_OCC_BAR_HEIGHT = 148;
  { Default expanded height — ~4–5 hit rows; File list keeps most of the center pane. }
  FIND_OCC_BAR_EXPANDED = 300;
  FIND_OCC_PEEK_HEIGHT = 5;
  FIND_OCC_BTN_H = 28;
  FIND_OCC_BTN_PAD_X = 28;
  FIND_OCC_TOP_H = 26;
  FIND_OCC_STATUS_H = 18;
  FIND_OCC_RECENT_H = 24;
  FIND_OCC_SEARCH_H = 30;
  FIND_OCC_LIST_PAGE_SIZE = 40;
  FIND_OCC_RECENT_INI_SECTION = 'FindOccRecentPatterns';
  { Page bar + ~4 visible hit rows. }
  FIND_OCC_LIST_MIN_H = 120;
  { Absolute floor when the window is short: page bar + ~2–3 rows. }
  FIND_OCC_LIST_TIGHT_H = 88;
  { Prefer leaving most of the center pane to the file ListView. }
  FIND_OCC_FILE_LIST_RESERVE = 320;

implementation

uses
  uI18n, uBidiLayout, uMruFind, UnitPopupMruList, uUserPrefs;

const
  { Soft warm frame shared with Filter bar. }
  CAccent = TColor($00BFAF9C);
  CSurface = TColor($00F6F3EE);
  CSurfaceHi = TColor($00EDE8E1);
  CBorder = TColor($00CFC6BB);
  CWindow = TColor($00FFFCF8);
  CTitle = TColor($001C1610);
  CMuted = TColor($006B6158);
  CStatusOk = TColor($002E7D32);
  CStatusBusy = TColor($00B15A1A);
  CStatusIdle = TColor($006B6158);
  CAccentW = 3;

function PreferUiFont: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else
    Result := 'Tahoma';
end;

{ TFastFileFindOccBar }

constructor TFastFileFindOccBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBuilt := False;
  FExpanded := False;
  FShown := True;
  FStacking := False;
  FFloating := False;
  FUserHeight := 0;
  FChromeH := 0;
  FHeaderDown := False;
  FHitPageBase := 0;
  FPendingHit := -1;
  FLastFiredHit := -1;
  FLastFireTick := 0;
  FTotalHits := 0;
  FPageIndex := 0;
  FPageCount := 0;
  FMru := TPanelSearchMru.Create(FIND_OCC_RECENT_INI_SECTION);
  Align := alTop;
  Height := FrameHeight;
  BevelOuter := bvNone;
  Caption := '';
  ParentBackground := False;
  ParentColor := False;
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  Color := CSurface;
end;

destructor TFastFileFindOccBar.Destroy;
begin
  FreeAndNil(FMru);
  inherited Destroy;
end;

procedure TFastFileFindOccBar.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
end;

procedure TFastFileFindOccBar.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(AParent) then
    EnsureBuilt;
end;

procedure TFastFileFindOccBar.SetIniPath(const APath: string);
begin
  if Assigned(FMru) then
    FMru.IniPath := APath;
  if FBuilt then
    RefreshRecentCombo;
end;

procedure TFastFileFindOccBar.EnsureBuilt;
begin
  if FBuilt then Exit;
  BuildFrame;
  FBuilt := True;
  ApplySoftFrame;
  ApplyCaptions;
  RefreshRecentCombo;
  LayoutFrame;
end;

procedure TFastFileFindOccBar.ForceColor(APnl: TsPanel; AColor: TColor);
begin
  if not Assigned(APnl) then Exit;
  try
    APnl.SkinData.CustomColor := True;
    APnl.SkinData.SkinSection := '';
  except
  end;
  APnl.ParentBackground := False;
  APnl.ParentColor := False;
  APnl.Color := AColor;
end;

procedure TFastFileFindOccBar.StyleBtn(ABtn: TsButton; const AUiFont: string;
  ARole: TSoftPanelBtnRole);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.Height := FfPx(FIND_OCC_BTN_H);
  StyleSoftPanelBtn(ABtn, AUiFont, ARole);
end;

procedure TFastFileFindOccBar.StyleFrameBtn(ABtn: TsButton; const AUiFont: string);
begin
  StyleSoftPanelFrameBtn(ABtn, AUiFont);
end;

procedure TFastFileFindOccBar.BuildFrame;
var
  UiFont: string;
begin
  UiFont := PreferUiFont;

  { Clip so hit list / page bar never paint over the File list below. }
  ControlStyle := ControlStyle + [csOpaque];

  FAccent := TsPanel.Create(Self);
  FAccent.Parent := Self;
  FAccent.Align := alLeft;
  FAccent.Width := CAccentW;
  FAccent.BevelOuter := bvNone;
  FAccent.Caption := '';
  ForceColor(FAccent, CAccent);

  FBody := TsPanel.Create(Self);
  FBody.Parent := Self;
  FBody.Align := alClient;
  FBody.BevelOuter := bvNone;
  FBody.Caption := '';
  FBody.Padding.Left := FfPx(10);
  FBody.Padding.Right := FfPx(8);
  FBody.Padding.Top := FfPx(8);
  FBody.Padding.Bottom := FfPx(8);
  FBody.OnResize := BodyResize;
  ForceColor(FBody, CSurface);
  FBody.HandleNeeded;
  SetWindowLong(FBody.Handle, GWL_STYLE,
    GetWindowLong(FBody.Handle, GWL_STYLE) or WS_CLIPCHILDREN);

  FTopRow := TsPanel.Create(Self);
  FTopRow.Parent := FBody;
  FTopRow.Align := alNone;
  FTopRow.Height := FfPx(FIND_OCC_TOP_H);
  FTopRow.BevelOuter := bvNone;
  FTopRow.Caption := '';
  ForceColor(FTopRow, CSurfaceHi);
  FTopRow.Cursor := crSizeAll;
  FTopRow.OnMouseDown := TitleMouseDown;
  FTopRow.OnMouseMove := TitleMouseMove;
  FTopRow.OnMouseUp := TitleMouseUp;

  FBtnChevron := CreatePanelChevron(Self, FTopRow, ChevronClick);
  FBtnChevron.Align := alLeft;

  FLblTitle := TsLabel.Create(Self);
  FLblTitle.Parent := FTopRow;
  FLblTitle.Left := FBtnChevron.Width + 1;
  FLblTitle.Align := alLeft;
  FLblTitle.AutoSize := True;
  FLblTitle.Transparent := True;
  FLblTitle.ParentFont := False;
  FLblTitle.Font.Name := UiFont;
  FLblTitle.Font.Size := 10;
  FLblTitle.Font.Style := [fsBold];
  FLblTitle.Font.Color := CTitle;
  FLblTitle.Caption := 'Occurrences';
  FLblTitle.Layout := tlCenter;
  FLblTitle.Cursor := crSizeAll;
  FLblTitle.OnMouseDown := TitleMouseDown;
  FLblTitle.OnMouseMove := TitleMouseMove;
  FLblTitle.OnMouseUp := TitleMouseUp;

  FBtnHide := TsButton.Create(Self);
  FBtnHide.Parent := FTopRow;
  FBtnHide.Align := alRight;
  FBtnHide.Width := FfPx(28);
  FBtnHide.OnClick := BtnHideClick;
  StyleFrameBtn(FBtnHide, UiFont);

  FBtnFloat := TsButton.Create(Self);
  FBtnFloat.Parent := FTopRow;
  FBtnFloat.Align := alRight;
  FBtnFloat.Width := FfPx(28);
  FBtnFloat.OnClick := BtnFloatClick;
  StyleFrameBtn(FBtnFloat, UiFont);

  FBtnListToggle := TsButton.Create(Self);
  FBtnListToggle.Parent := FTopRow;
  FBtnListToggle.Align := alRight;
  FBtnListToggle.Width := FfPx(28);
  FBtnListToggle.OnClick := BtnListToggleClick;
  StyleFrameBtn(FBtnListToggle, UiFont);
  FBtnListToggle.Visible := False;

  FStatusRow := TsPanel.Create(Self);
  FStatusRow.Parent := FBody;
  FStatusRow.Align := alNone;
  FStatusRow.Height := FfPx(FIND_OCC_STATUS_H);
  FStatusRow.BevelOuter := bvNone;
  FStatusRow.Caption := '';
  FStatusRow.Padding.Left := FfPx(2);
  ForceColor(FStatusRow, CSurface);

  FLblStatus := TsLabel.Create(Self);
  FLblStatus.Parent := FStatusRow;
  FLblStatus.Align := alClient;
  FLblStatus.Transparent := True;
  FLblStatus.ParentFont := False;
  FLblStatus.Font.Name := UiFont;
  FLblStatus.Font.Size := 8;
  FLblStatus.Font.Color := CMuted;
  FLblStatus.Caption := '';
  FLblStatus.Layout := tlCenter;
  FLblStatus.ShowHint := True;

  FRecentRow := TsPanel.Create(Self);
  FRecentRow.Parent := FBody;
  FRecentRow.Align := alNone;
  FRecentRow.Height := FfPx(FIND_OCC_RECENT_H);
  FRecentRow.BevelOuter := bvNone;
  FRecentRow.Caption := '';
  ForceColor(FRecentRow, CSurface);

  FLblRecent := TsLabel.Create(Self);
  FLblRecent.Parent := FRecentRow;
  FLblRecent.ParentFont := False;
  FLblRecent.Font.Name := UiFont;
  FLblRecent.Font.Size := 8;
  FLblRecent.Font.Color := CMuted;
  FLblRecent.Transparent := True;
  FLblRecent.Caption := '';
  FLblRecent.Layout := tlCenter;

  FCmbRecent := TComboBox.Create(Self);
  FCmbRecent.Parent := FRecentRow;
  FCmbRecent.Style := csDropDownList;
  FCmbRecent.DropDownCount := PrefFilterRecentMax;
  FCmbRecent.ParentFont := False;
  FCmbRecent.Font.Name := UiFont;
  FCmbRecent.Font.Size := 9;
  FCmbRecent.ParentColor := False;
  FCmbRecent.Color := CWindow;
  FCmbRecent.OnChange := CmbRecentChange;
  FCmbRecent.OnCloseUp := CmbRecentCloseUp;
  FCmbRecent.OnDropDown := CmbRecentDropDown;
  FCmbRecent.ShowHint := True;
  BidiKeepLtr(FCmbRecent);

  FSearchRow := TsPanel.Create(Self);
  FSearchRow.Parent := FBody;
  FSearchRow.Align := alNone;
  FSearchRow.Height := FfPx(FIND_OCC_SEARCH_H);
  FSearchRow.BevelOuter := bvNone;
  FSearchRow.Caption := '';
  ForceColor(FSearchRow, CSurface);

  FEditShell := TsPanel.Create(Self);
  FEditShell.Parent := FSearchRow;
  FEditShell.BevelOuter := bvNone;
  FEditShell.Caption := '';
  ForceColor(FEditShell, CBorder);

  FEditFrame := TsPanel.Create(Self);
  FEditFrame.Parent := FEditShell;
  FEditFrame.Align := alClient;
  FEditFrame.BevelOuter := bvNone;
  FEditFrame.Caption := '';
  FEditFrame.Padding.Left := FfPx(6);
  FEditFrame.Padding.Right := FfPx(6);
  FEditFrame.Padding.Top := FfPx(3);
  FEditFrame.Padding.Bottom := FfPx(3);
  ForceColor(FEditFrame, CWindow);

  FEdtFind := TEdit.Create(Self);
  FEdtFind.Parent := FEditFrame;
  FEdtFind.Align := alClient;
  FEdtFind.BorderStyle := bsNone;
  FEdtFind.ParentFont := False;
  FEdtFind.Font.Name := UiFont;
  FEdtFind.Font.Size := 10;
  FEdtFind.Font.Color := CTitle;
  FEdtFind.ParentColor := False;
  FEdtFind.Color := CWindow;
  FEdtFind.OnKeyDown := EdtFindKeyDown;
  FEdtFind.ShowHint := True;
  BidiKeepLtr(FEdtFind); { search text / regex stays left-to-right }

  FBtnGo := TsButton.Create(Self);
  FBtnGo.Parent := FSearchRow;
  FBtnGo.OnClick := BtnGoClick;
  StyleBtn(FBtnGo, UiFont, spbrPrimary);

  FBtnRow := TsPanel.Create(Self);
  FBtnRow.Parent := FBody;
  FBtnRow.Align := alNone;
  FBtnRow.Height := FfPx(FIND_OCC_BTN_H + 6);
  FBtnRow.BevelOuter := bvNone;
  FBtnRow.Caption := '';
  ForceColor(FBtnRow, CSurface);

  FBtnPrev := TsButton.Create(Self);
  FBtnPrev.Parent := FBtnRow;
  FBtnPrev.OnClick := BtnPrevClick;
  StyleBtn(FBtnPrev, UiFont, spbrAction);

  FBtnNext := TsButton.Create(Self);
  FBtnNext.Parent := FBtnRow;
  FBtnNext.OnClick := BtnNextClick;
  StyleBtn(FBtnNext, UiFont, spbrPrimary);

  FBtnCollect := TsButton.Create(Self);
  FBtnCollect.Parent := FBtnRow;
  FBtnCollect.OnClick := BtnCollectClick;
  StyleBtn(FBtnCollect, UiFont, spbrAction);

  FBtnLoadMore := TsButton.Create(Self);
  FBtnLoadMore.Parent := FBtnRow;
  FBtnLoadMore.OnClick := BtnLoadMoreClick;
  FBtnLoadMore.Enabled := False;
  FBtnLoadMore.Visible := False;
  StyleBtn(FBtnLoadMore, UiFont, spbrAction);

  FBtnExport := TsButton.Create(Self);
  FBtnExport.Parent := FBtnRow;
  FBtnExport.OnClick := BtnExportClick;
  FBtnExport.Visible := False;
  StyleBtn(FBtnExport, UiFont, spbrAction);

  FBtnCopy := TsButton.Create(Self);
  FBtnCopy.Parent := FBtnRow;
  FBtnCopy.OnClick := BtnCopyClick;
  FBtnCopy.Visible := False;
  StyleBtn(FBtnCopy, UiFont, spbrAction);

  FBtnClear := TsButton.Create(Self);
  FBtnClear.Parent := FBtnRow;
  FBtnClear.OnClick := BtnClearClick;
  StyleBtn(FBtnClear, UiFont, spbrQuiet);

  FBtnClose := TsButton.Create(Self);
  FBtnClose.Parent := FBtnRow;
  FBtnClose.OnClick := BtnHideClick;
  StyleBtn(FBtnClose, UiFont, spbrQuiet);

  FBtnGrep := TsButton.Create(Self);
  FBtnGrep.Name := 'SearchGrep';
  FBtnGrep.Parent := FBtnRow;
  FBtnGrep.Caption := 'grep';
  FBtnGrep.OnClick := BtnCommandClick;
  StyleBtn(FBtnGrep, UiFont, spbrCommand);
  FBtnGlob := TsButton.Create(Self);
  FBtnGlob.Name := 'SearchGlob';
  FBtnGlob.Parent := FBtnRow;
  FBtnGlob.Caption := 'glob';
  FBtnGlob.OnClick := BtnCommandClick;
  StyleBtn(FBtnGlob, UiFont, spbrCommand);

  FListHost := TsPanel.Create(Self);
  FListHost.Parent := FBody;
  FListHost.Align := alClient;
  FListHost.BevelOuter := bvNone;
  FListHost.Caption := '';
  FListHost.Visible := False;
  ForceColor(FListHost, CSurface);

  FPageBar := TsPanel.Create(Self);
  FPageBar.Parent := FListHost;
  FPageBar.Align := alBottom;
  FPageBar.Height := FfPx(FIND_OCC_BTN_H);
  FPageBar.BevelOuter := bvNone;
  FPageBar.Caption := '';
  ForceColor(FPageBar, CSurfaceHi);

  FBtnPagePrev := TsButton.Create(Self);
  FBtnPagePrev.Parent := FPageBar;
  FBtnPagePrev.Align := alLeft;
  FBtnPagePrev.Width := FfPx(32);
  FBtnPagePrev.OnClick := BtnPagePrevClick;
  StyleFrameBtn(FBtnPagePrev, UiFont);
  FBtnPagePrev.Caption := '<';

  FBtnPageNext := TsButton.Create(Self);
  FBtnPageNext.Parent := FPageBar;
  FBtnPageNext.Align := alRight;
  FBtnPageNext.Width := FfPx(32);
  FBtnPageNext.OnClick := BtnPageNextClick;
  StyleFrameBtn(FBtnPageNext, UiFont);
  FBtnPageNext.Caption := '>';

  FBtnPageExport := TsButton.Create(Self);
  FBtnPageExport.Parent := FPageBar;
  FBtnPageExport.Width := FfPx(76);
  FBtnPageExport.Left := FBtnPageNext.Left - FBtnPageExport.Width;
  FBtnPageExport.Align := alRight;
  FBtnPageExport.OnClick := BtnPageExportClick;
  StyleBtn(FBtnPageExport, UiFont, spbrQuiet);
  FBtnPageExport.WordWrap := False;

  FPageMenu := TPopupMenu.Create(Self);

  FLblPage := TsLabel.Create(Self);
  FLblPage.Parent := FPageBar;
  FLblPage.Align := alClient;
  FLblPage.Transparent := False;
  FLblPage.ParentColor := False;
  FLblPage.Color := CSurfaceHi;
  FLblPage.ParentFont := False;
  FLblPage.Font.Name := UiFont;
  FLblPage.Font.Size := 8;
  FLblPage.Font.Color := CMuted;
  FLblPage.Caption := '';
  FLblPage.Alignment := taCenter;
  FLblPage.Layout := tlCenter;

  FListShell := TsPanel.Create(Self);
  FListShell.Parent := FListHost;
  FListShell.Align := alClient;
  FListShell.BevelOuter := bvNone;
  FListShell.Caption := '';
  FListShell.Padding.Left := 1;
  FListShell.Padding.Top := 1;
  FListShell.Padding.Right := 1;
  FListShell.Padding.Bottom := 1;
  ForceColor(FListShell, CBorder);

  FListInner := TsPanel.Create(Self);
  FListInner.Parent := FListShell;
  FListInner.Align := alClient;
  FListInner.BevelOuter := bvNone;
  FListInner.Caption := '';
  ForceColor(FListInner, CWindow);

  FHitList := TListBox.Create(Self);
  FHitList.Parent := FListInner;
  FHitList.Align := alClient;
  FHitList.BorderStyle := bsNone;
  FHitList.ParentFont := False;
  FHitList.Font.Name := UiFont;
  FHitList.Font.Size := 9;
  FHitList.Font.Color := CTitle;
  FHitList.ParentColor := False;
  FHitList.Color := CWindow;
  FHitList.IntegralHeight := False;
  FHitList.OnDblClick := HitListDblClick;
  FHitList.OnClick := HitListClick;
  BidiKeepLtr(FHitList); { hit lines are raw file text }
  HookListWheel(FHitList);

  FHitTimer := TTimer.Create(Self);
  FHitTimer.Enabled := False;
  FHitTimer.Interval := 60;
  FHitTimer.OnTimer := HitTimerTick;

  { Stack with Align so the hit list can only occupy the body — never the File list. }
  FTopRow.Top := 0;
  FStatusRow.Top := 1;
  FRecentRow.Top := 2;
  FSearchRow.Top := 3;
  FBtnRow.Top := 4;
  FTopRow.Align := alTop;
  FStatusRow.Align := alTop;
  FRecentRow.Align := alTop;
  FSearchRow.Align := alTop;
  FBtnRow.Align := alTop;
  FListHost.Align := alClient;
end;

procedure TFastFileFindOccBar.LayoutFrame;
var
  Gap, InnerW, RecentH, SearchH, GoW, RecentLblW, FlowH, NewChromeH: Integer;
  MeasureBmp: TBitmap;
  BL: IInterface;
begin
  if not FBuilt or not Assigned(FBody) or not Assigned(FBtnRow) or not Assigned(FTopRow) then Exit;
  if not FShown then Exit;
  { Accordion: host owns height. Never re-show chrome or clear MaxHeight here. }
  if FCollapsed and (not FFloating) then
  begin
    if Assigned(FStatusRow) then FStatusRow.Visible := False;
    if Assigned(FRecentRow) then FRecentRow.Visible := False;
    if Assigned(FSearchRow) then FSearchRow.Visible := False;
    if Assigned(FBtnRow) then FBtnRow.Visible := False;
    if Assigned(FListHost) then FListHost.Visible := False;
    if Assigned(FTopRow) then
      FTopRow.Height := FfPx(FIND_OCC_TOP_H);
    SyncCollapseMask(FCollapseMask, Self, FBody,
      FBody.Padding.Top + FfPx(FIND_OCC_TOP_H), CSurface, True);
    Exit;
  end;
  StackChromeRows;
  BL := BidiLayoutScope([FBody, FRecentRow, FSearchRow, FBtnRow]);

  RecentH := FfPx(FIND_OCC_RECENT_H);
  SearchH := FfPx(FIND_OCC_SEARCH_H);
  Gap := FfPx(6);

  InnerW := FBody.ClientWidth - FBody.Padding.Left - FBody.Padding.Right;
  if InnerW < FfPx(160) then
    InnerW := FfPx(160);

  { Rows are alTop / list is alClient — height only. SetBounds here used to
    spill the hit list over the File list. Each row carries its own gap. }
  FTopRow.Height := FfPx(FIND_OCC_TOP_H);
  if Assigned(FStatusRow) then
    FStatusRow.Height := FfPx(FIND_OCC_STATUS_H + 2);
  if Assigned(FRecentRow) then
    FRecentRow.Height := RecentH + Gap;
  if Assigned(FSearchRow) then
    FSearchRow.Height := SearchH + Gap;
  if Assigned(FListHost) then
  begin
    if FListHost.Align <> alClient then
      FListHost.Align := alClient;
    FListHost.Visible := FExpanded;
  end;

  if Assigned(FBtnHide) then
    FBtnHide.Width := FfPx(26);
  if Assigned(FBtnFloat) then
    FBtnFloat.Width := FfPx(26);
  if Assigned(FBtnListToggle) then
    FBtnListToggle.Width := FfPx(26);

  MeasureBmp := TBitmap.Create;
  try
    MeasureBmp.SetSize(8, 8);

    if Assigned(FRecentRow) and Assigned(FLblRecent) and Assigned(FCmbRecent) then
    begin
      MeasureBmp.Canvas.Font.Assign(FLblRecent.Font);
      RecentLblW := Min(InnerW div 3,
        MeasureBmp.Canvas.TextWidth(FLblRecent.Caption) + FfPx(6));
      FLblRecent.SetBounds(0, 0, RecentLblW, RecentH);
      FCmbRecent.SetBounds(RecentLblW + FfPx(4), 0,
        Max(FfPx(60), InnerW - RecentLblW - FfPx(4)), RecentH);
    end;

    if Assigned(FSearchRow) and Assigned(FEditShell) and Assigned(FBtnGo) then
    begin
      MeasureBmp.Canvas.Font.Assign(FBtnGo.Font);
      GoW := Max(FfPx(64), MeasureBmp.Canvas.TextWidth(FBtnGo.Caption) +
        FfPx(FIND_OCC_BTN_PAD_X));
      if GoW > InnerW div 2 then
        GoW := InnerW div 2;
      FEditShell.SetBounds(0, 0, InnerW - GoW - Gap, SearchH);
      FBtnGo.SetBounds(InnerW - GoW, 0, GoW, SearchH);
    end;

    FlowH := FlowSoftPanelButtons([FBtnPrev, FBtnNext, FBtnCollect, FBtnLoadMore,
      FBtnExport, FBtnCopy, FBtnGrep, FBtnGlob, FBtnClear, FBtnClose],
      MeasureBmp.Canvas, 0, 0, InnerW, FfPx(FIND_OCC_BTN_H), Gap, FfPx(52),
      FfPx(FIND_OCC_BTN_PAD_X) - FfPx(4));
    FBtnRow.Height := FlowH + Gap;
  finally
    MeasureBmp.Free;
  end;

  NewChromeH := FBody.Padding.Top + FTopRow.Height + FBtnRow.Height + FBody.Padding.Bottom;
  if Assigned(FStatusRow) then
    Inc(NewChromeH, FStatusRow.Height);
  if Assigned(FRecentRow) then
    Inc(NewChromeH, FRecentRow.Height);
  if Assigned(FSearchRow) then
    Inc(NewChromeH, FSearchRow.Height);
  { The bottom resize grip (floating only) sits outside FBody. }
  if FFloating then
  begin
    Inc(NewChromeH, FfPx(16));
    Constraints.MinHeight := NewChromeH;
    Constraints.MaxHeight := 0;
  end;
  { Docked: LayoutSearchDock locks Min/MaxHeight for the accordion slot. }
  if NewChromeH <> FChromeH then
  begin
    FChromeH := NewChromeH;
    if (not FFloating) and (not FCollapsed) and Assigned(FOnHeightChanged) then
      FOnHeightChanged(Self);
  end;
end;

procedure TFastFileFindOccBar.BodyResize(Sender: TObject);
begin
  { Mid-align Body.ClientHeight is temporarily full-bar; laying out then
    leaves FListHost taller than the final client and spills onto File list. }
  if (csAligning in ControlState) or (csAligning in FBody.ControlState) then
    Exit;
  LayoutFrame;
end;

procedure TFastFileFindOccBar.Resize;
begin
  inherited;
  if FExpanded and (not FFloating) and
     (Height >= FrameHeight + FfPx(FIND_OCC_LIST_TIGHT_H)) then
    FUserHeight := Height;
  LayoutFrame;
end;

procedure TFastFileFindOccBar.ApplySoftFrame;
var
  UiFont: string;
begin
  UiFont := PreferUiFont;
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  ParentBackground := False;
  ParentColor := False;
  Color := CSurface;
  ForceColor(Self, CSurface);
  if Assigned(FAccent) then
  begin
    ForceColor(FAccent, CAccent);
    FAccent.Width := CAccentW;
  end;
  if Assigned(FBody) then ForceColor(FBody, CSurface);
  if Assigned(FTopRow) then ForceColor(FTopRow, CSurfaceHi);
  if Assigned(FStatusRow) then ForceColor(FStatusRow, CSurface);
  if Assigned(FRecentRow) then ForceColor(FRecentRow, CSurface);
  if Assigned(FSearchRow) then ForceColor(FSearchRow, CSurface);
  if Assigned(FBtnRow) then ForceColor(FBtnRow, CSurface);
  if Assigned(FListHost) then ForceColor(FListHost, CSurface);
  if Assigned(FPageBar) then ForceColor(FPageBar, CSurfaceHi);
  if Assigned(FEditShell) then ForceColor(FEditShell, CBorder);
  if Assigned(FEditFrame) then ForceColor(FEditFrame, CWindow);
  if Assigned(FListShell) then ForceColor(FListShell, CBorder);
  if Assigned(FListInner) then ForceColor(FListInner, CWindow);
  if Assigned(FLblTitle) then
  begin
    FLblTitle.Font.Name := UiFont;
    FLblTitle.Font.Color := CTitle;
  end;
  if Assigned(FLblStatus) then
  begin
    FLblStatus.Font.Name := UiFont;
    FLblStatus.Font.Color := CMuted;
  end;
  if Assigned(FLblPage) then
  begin
    FLblPage.Font.Name := UiFont;
    FLblPage.Font.Color := CMuted;
  end;
  if Assigned(FLblRecent) then
  begin
    FLblRecent.Font.Name := UiFont;
    FLblRecent.Font.Color := CMuted;
  end;
  if Assigned(FCmbRecent) then
  begin
    FCmbRecent.ParentColor := False;
    FCmbRecent.Color := CWindow;
    FCmbRecent.ParentFont := False;
    FCmbRecent.Font.Name := UiFont;
    FCmbRecent.Font.Size := 9;
  end;
  if Assigned(FEdtFind) then
  begin
    FEdtFind.ParentColor := False;
    FEdtFind.Color := CWindow;
    FEdtFind.ParentFont := False;
    FEdtFind.Font.Name := UiFont;
    FEdtFind.Font.Size := 10;
    FEdtFind.Font.Color := CTitle;
  end;
  if Assigned(FHitList) then
  begin
    FHitList.ParentColor := False;
    FHitList.Color := CWindow;
    FHitList.ParentFont := False;
    FHitList.Font.Name := UiFont;
    FHitList.Font.Size := 9;
    FHitList.Font.Color := CTitle;
  end;
  StyleBtn(FBtnGo, UiFont, spbrPrimary);
  StyleBtn(FBtnGrep, UiFont, spbrCommand);
  StyleBtn(FBtnGlob, UiFont, spbrCommand);
  StyleBtn(FBtnPrev, UiFont, spbrAction);
  StyleBtn(FBtnNext, UiFont, spbrPrimary);
  StyleBtn(FBtnCollect, UiFont, spbrAction);
  StyleBtn(FBtnLoadMore, UiFont, spbrAction);
  StyleBtn(FBtnExport, UiFont, spbrAction);
  StyleBtn(FBtnCopy, UiFont, spbrAction);
  StyleBtn(FBtnClear, UiFont, spbrQuiet);
  StyleBtn(FBtnClose, UiFont, spbrQuiet);
  StyleFrameBtn(FBtnHide, UiFont);
  StyleFrameBtn(FBtnFloat, UiFont);
  StyleFrameBtn(FBtnListToggle, UiFont);
  StyleFrameBtn(FBtnPagePrev, UiFont);
  StyleFrameBtn(FBtnPageNext, UiFont);
  StyleBtn(FBtnPageExport, UiFont, spbrQuiet);
end;

procedure TFastFileFindOccBar.ApplyCaptions;
begin
  if not FBuilt then Exit;
  FLblTitle.Caption := TrText('FindOcc.Title');
  SyncPanelChevron(FBtnChevron, FCollapsed);
  FBtnPrev.Caption := TrText('FindOcc.Prev');
  FBtnNext.Caption := TrText('FindOcc.Next');
  FBtnCollect.Caption := TrText('FindOcc.ViewAllInList');
  FBtnLoadMore.Caption := TrText('FindOcc.LoadMore');
  FBtnExport.Caption := TrText('FindOcc.Export');
  FBtnCopy.Caption := TrText('FindOcc.Copy');
  FBtnClear.Caption := TrText('FindOcc.Clear');
  if Assigned(FBtnClose) then
    FBtnClose.Caption := TrText('Close');
  FBtnGrep.Hint := Format(TrText('SearchCmd.LaunchHint'), ['grep']);
  FBtnGlob.Hint := Format(TrText('SearchCmd.LaunchHint'), ['glob']);
  if Assigned(FBtnGo) then
    FBtnGo.Caption := TrText('FindOcc.Go');
  FBtnHide.Caption := #$00D7;
  FBtnPagePrev.Caption := '<';
  FBtnPageNext.Caption := '>';
  FBtnPrev.Hint := TrText('FindOcc.PrevHint');
  FBtnNext.Hint := TrText('FindOcc.NextHint');
  FBtnCollect.Hint := TrText('FindOcc.ViewAllInListHint');
  FBtnLoadMore.Hint := TrText('FindOcc.LoadMoreHint');
  FBtnExport.Hint := TrText('FindOcc.ExportHint');
  FBtnCopy.Hint := TrText('FindOcc.CopyHint');
  FBtnClear.Hint := TrText('FindOcc.ClearHint');
  if Assigned(FBtnClose) then
    FBtnClose.Hint := TrText('FindOcc.CloseHint');
  if Assigned(FBtnGo) then
    FBtnGo.Hint := TrText('FindOcc.GoHint');
  if Assigned(FLblRecent) then
    FLblRecent.Caption := TrText('FindOcc.Recent');
  if Assigned(FCmbRecent) then
  begin
    FCmbRecent.Hint := TrText('FindOcc.RecentHint');
    FCmbRecent.ShowHint := True;
  end;
  if Assigned(FEdtFind) then
  begin
    FEdtFind.TextHint := TrText('SearchCmd.Hint');
    FEdtFind.Hint := TrText('FindOcc.SearchHint') + #13#10 + TrText('SearchCmd.Hint');
  end;
  FBtnHide.Hint := TrText('Close');
  RefreshRecentCombo;
  SyncListToggle;
  FBtnPagePrev.Hint := TrText('FindOcc.ListPagePrevHint');
  FBtnPageNext.Hint := TrText('FindOcc.ListPageNextHint');
  FBtnPageExport.Caption := TrText('FindOcc.Export') + ' ' + #$25BE;
  FBtnPageExport.Hint := TrText('FindOcc.PageExportHint');
  FBtnPageExport.ShowHint := True;
  SyncPageExportWidth;
  { Page caption is set in SetHitListPage — refresh it on language change. }
  if Assigned(FLblPage) then
  begin
    if (FPageIndex > 0) and (FPageCount > 0) then
      FLblPage.Caption := Format(TrText('FindOcc.ListPageStatus'),
        [FPageIndex, FPageCount, FTotalHits])
    else
      FLblPage.Caption := '';
  end;
  SyncFloatAction;
  LayoutFrame;
end;

procedure TFastFileFindOccBar.BtnCommandClick(Sender: TObject);
begin
  if not Assigned(FOnCommand) then Exit;
  if Sender = FBtnGlob then FOnCommand(Self, 'glob')
  else FOnCommand(Self, 'grep');
end;

procedure TFastFileFindOccBar.SetStatus(const AStatusText: string; ABusy, AHasHits, APartial: Boolean);
var
  NeedLayout: Boolean;
  Vis: Boolean;
begin
  EnsureBuilt;
  NeedLayout := False;
  if Assigned(FLblStatus) then
  begin
    if FLblStatus.Caption <> AStatusText then
    begin
      FLblStatus.Caption := AStatusText;
      FLblStatus.Hint := AStatusText;
    end;
    if ABusy then
      FLblStatus.Font.Color := CStatusBusy
    else if AHasHits then
      FLblStatus.Font.Color := CStatusOk
    else
      FLblStatus.Font.Color := CStatusIdle;
  end;
  if Assigned(FBtnLoadMore) then
  begin
    Vis := APartial or AHasHits;
    if FBtnLoadMore.Visible <> Vis then
      NeedLayout := True;
    FBtnLoadMore.Visible := Vis;
    FBtnLoadMore.Enabled := APartial and (not ABusy);
  end;
  if Assigned(FBtnExport) then
  begin
    Vis := AHasHits;
    if FBtnExport.Visible <> Vis then
      NeedLayout := True;
    FBtnExport.Visible := Vis;
    FBtnExport.Enabled := AHasHits and (not ABusy);
  end;
  if Assigned(FBtnCopy) then
  begin
    Vis := AHasHits;
    if FBtnCopy.Visible <> Vis then
      NeedLayout := True;
    FBtnCopy.Visible := Vis;
    FBtnCopy.Enabled := AHasHits and (not ABusy);
  end;
  if Assigned(FBtnCollect) then
    FBtnCollect.Enabled := not ABusy;
  { F3 only changes the status caption — restacking the chrome flickers the dock. }
  if NeedLayout then
    LayoutFrame;
end;

procedure TFastFileFindOccBar.SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
begin
  EnsureBuilt;
  if Assigned(FBtnPrev) then FBtnPrev.Enabled := APrevEnabled;
  if Assigned(FBtnNext) then FBtnNext.Enabled := ANextEnabled;
end;

procedure TFastFileFindOccBar.SetCollectEnabled(AEnabled: Boolean);
begin
  EnsureBuilt;
  if Assigned(FBtnCollect) then
    FBtnCollect.Enabled := AEnabled;
end;

function TFastFileFindOccBar.FrameHeight: Integer;
begin
  if FChromeH > 0 then
    Result := FChromeH
  else
    { Title + status + recent MRU + search + one button row (before first layout). }
    Result := FfPx(8 + FIND_OCC_TOP_H + FIND_OCC_STATUS_H + 2 + FIND_OCC_RECENT_H + 6 +
      FIND_OCC_SEARCH_H + 6 + FIND_OCC_BTN_H + 6 + 8);
end;

function TFastFileFindOccBar.ExpandedMinHeight: Integer;
begin
  Result := FrameHeight + FfPx(4 + FIND_OCC_LIST_MIN_H);
end;

procedure TFastFileFindOccBar.StackChromeRows;
begin
  if FStacking or not FBuilt or not Assigned(FBody) or not Assigned(FTopRow) or
     not Assigned(FBtnRow) then Exit;
  FStacking := True;
  try
    { One align pass. Tops decide the order: title, recent, search, buttons.
      Setting alTop one-by-one put each new row above the previous one. }
    FBody.DisableAlign;
    try
      if Assigned(FListHost) then
      begin
        FListHost.Align := alNone;
        FListHost.Top := 4000;
        FListHost.Height := 0;
      end;
      FBtnRow.Align := alNone;
      FBtnRow.Top := 3000;
      if Assigned(FSearchRow) then
      begin
        FSearchRow.Align := alNone;
        FSearchRow.Top := 2000;
      end;
      if Assigned(FRecentRow) then
      begin
        FRecentRow.Align := alNone;
        FRecentRow.Top := 1000;
      end;
      if Assigned(FStatusRow) then
      begin
        FStatusRow.Align := alNone;
        FStatusRow.Top := 500;
      end;
      FTopRow.Align := alNone;
      FTopRow.Top := 0;
      FBtnRow.Align := alTop;
      if Assigned(FSearchRow) then
        FSearchRow.Align := alTop;
      if Assigned(FRecentRow) then
        FRecentRow.Align := alTop;
      if Assigned(FStatusRow) then
        FStatusRow.Align := alTop;
      FTopRow.Align := alTop;
      if Assigned(FListHost) then
        FListHost.Align := alClient;
    finally
      FBody.EnableAlign;
    end;
  finally
    FStacking := False;
  end;
end;

procedure TFastFileFindOccBar.SetChromeShown(AShown: Boolean);

  procedure ShowCtl(ACtl: TControl);
  begin
    if Assigned(ACtl) then
      ACtl.Visible := True;
  end;

begin
  EnsureBuilt;
  FShown := AShown;
  if not AShown then
  begin
    Visible := False;
    if HandleAllocated then
      ShowWindow(Handle, SW_HIDE);
    Exit;
  end;

  { Docked height/align come from the search-dock host (accordion). }
  if not FFloating then
  begin
    Align := alNone;
    Constraints.MaxHeight := 0;
    Constraints.MinHeight := 0;
  end
  else if Align <> alClient then
    Align := alClient;
  ShowCtl(FAccent);
  ShowCtl(FBody);
  ShowCtl(FTopRow);
  if not FCollapsed then
  begin
    ShowCtl(FStatusRow);
    ShowCtl(FRecentRow);
    ShowCtl(FSearchRow);
    ShowCtl(FBtnRow);
  end;
  ShowCtl(FBtnPrev);
  ShowCtl(FBtnNext);
  ShowCtl(FBtnCollect);
  ShowCtl(FBtnClear);
  ShowCtl(FBtnClose);
  ShowCtl(FBtnHide);
  ShowCtl(FBtnFloat);
  ShowCtl(FBtnGo);
  ShowCtl(FBtnGrep);
  ShowCtl(FBtnGlob);
  ShowCtl(FBtnPagePrev);
  ShowCtl(FBtnPageNext);
  ShowCtl(FBtnPageExport);
  if Assigned(FListHost) then
    FListHost.Visible := (not FCollapsed) and FExpanded;
  Visible := True;
  if FCollapsed and (not FFloating) then
  begin
    if Assigned(FStatusRow) then FStatusRow.Visible := False;
    if Assigned(FRecentRow) then FRecentRow.Visible := False;
    if Assigned(FSearchRow) then FSearchRow.Visible := False;
    if Assigned(FBtnRow) then FBtnRow.Visible := False;
    if Assigned(FListHost) then FListHost.Visible := False;
    SyncCollapseMask(FCollapseMask, Self, FBody,
      FBody.Padding.Top + FfPx(FIND_OCC_TOP_H), CSurface, True);
  end
  else
  begin
    StackChromeRows;
    SyncListToggle;
    LayoutFrame;
  end;
end;

procedure TFastFileFindOccBar.SetExpanded(AExpanded: Boolean);
var
  WasExpanded: Boolean;
begin
  EnsureBuilt;
  WasExpanded := FExpanded;
  FExpanded := AExpanded;
  if AExpanded then
    FListCollapsed := False;
  Constraints.MaxHeight := 0;
  SyncListToggle;
  LayoutFrame;
  { Docked: the host column re-splits its height when the list opens/closes. }
  if (WasExpanded <> FExpanded) and (not FFloating) and Assigned(FOnListToggled) then
    FOnListToggled(Self);
end;

procedure TFastFileFindOccBar.SyncListToggle;
var
  HasHits: Boolean;
begin
  if not Assigned(FBtnListToggle) then Exit;
  HasHits := Assigned(FHitList) and (FHitList.Items.Count > 0);
  { Keep header chrome quiet while the card is accordion-collapsed. }
  FBtnListToggle.Visible := HasHits and (not FCollapsed);
  if not FBtnListToggle.Visible then Exit;
  if FExpanded then
  begin
    FBtnListToggle.Caption := #$25B4;
    FBtnListToggle.Hint := TrText('FindOcc.HideListHint');
  end
  else
  begin
    FBtnListToggle.Caption := #$25BE;
    FBtnListToggle.Hint := TrText('FindOcc.ShowListHint');
  end;
  FBtnListToggle.ShowHint := True;
  { Keep it left of the float / close buttons. }
  if Assigned(FBtnFloat) then
    FBtnListToggle.Left := FBtnFloat.Left - FBtnListToggle.Width;
end;

procedure TFastFileFindOccBar.ToggleHitList;
begin
  EnsureBuilt;
  if not Assigned(FHitList) or (FHitList.Items.Count = 0) then Exit;
  FListCollapsed := FExpanded;
  { SetExpanded fires OnListToggled when docked height changes. }
  SetExpanded(not FListCollapsed);
end;

procedure TFastFileFindOccBar.BtnListToggleClick(Sender: TObject);
begin
  ToggleHitList;
end;

function TFastFileFindOccBar.PreferredExpandedHeight: Integer;
var
  Cap, ParentH, FileMin, HitMin: Integer;
begin
  { Chrome + ~3 hit rows. File list keeps at least ~55% of the center. }
  Result := FrameHeight + FfPx(96);
  if Result > FfPx(FIND_OCC_BAR_EXPANDED) then
    Result := FfPx(FIND_OCC_BAR_EXPANDED);
  HitMin := FrameHeight + FfPx(56);
  if (not FFloating) and Assigned(Parent) and (Parent.ClientHeight > 0) then
  begin
    ParentH := Parent.ClientHeight;
    FileMin := Max(FfPx(240), (ParentH * 55) div 100);
    Cap := ParentH - FileMin;
    if Cap < HitMin then
      Cap := HitMin;
    if Cap > ParentH - FfPx(180) then
      Cap := ParentH - FfPx(180);
    if Cap < HitMin then
      Cap := Min(HitMin, Max(FrameHeight + FfPx(40), ParentH - FfPx(140)));
    if Result > Cap then
      Result := Cap;
    if Result < HitMin then
      Result := Min(HitMin, Cap);
  end;
end;

procedure TFastFileFindOccBar.ClearHitList;
begin
  EnsureBuilt;
  FHitPageBase := 0;
  FTotalHits := 0;
  FPageIndex := 0;
  FPageCount := 0;
  if Assigned(FHitList) then
    FHitList.Items.Clear;
  if Assigned(FLblPage) then
    FLblPage.Caption := '';
  FListCollapsed := False;
  SetExpanded(False);
end;

function TFastFileFindOccBar.GetSearchText: string;
begin
  EnsureBuilt;
  if Assigned(FEdtFind) then
    Result := FEdtFind.Text
  else
    Result := '';
end;

procedure TFastFileFindOccBar.SetSearchText(const AText: string);
begin
  EnsureBuilt;
  if not Assigned(FEdtFind) then Exit;
  if FEdtFind.Text = AText then Exit;
  FEdtFind.Text := AText;
end;

procedure TFastFileFindOccBar.FocusSearchEdit;
begin
  EnsureBuilt;
  if not Assigned(FEdtFind) then Exit;
  if not Visible then Exit;
  if not HandleAllocated then Exit;
  if FEdtFind.CanFocus then
  begin
    FEdtFind.SetFocus;
    FEdtFind.SelectAll;
  end;
end;

function TFastFileFindOccBar.SearchEditFocused: Boolean;
begin
  Result := Assigned(FEdtFind) and FEdtFind.Focused;
end;

procedure TFastFileFindOccBar.SetHitListPage(ALines: TStrings; APageBase: Int64;
  APageIndex, APageCount, ATotalHits: Integer; ACanPagePrev, ACanPageNext: Boolean);
var
  KeepListCollapsed: Boolean;
begin
  EnsureBuilt;
  { Language retranslate rebuilds the page without undoing a user-collapsed list. }
  KeepListCollapsed := FListCollapsed and FExpanded;
  FHitPageBase := APageBase;
  FTotalHits := ATotalHits;
  FPageIndex := APageIndex;
  FPageCount := APageCount;
  FPendingHit := -1;
  if Assigned(FHitTimer) then
    FHitTimer.Enabled := False;
  if Assigned(FHitList) then
  begin
    FHitList.Items.BeginUpdate;
    try
      FHitList.Items.Clear;
      if Assigned(ALines) then
        FHitList.Items.Assign(ALines);
    finally
      FHitList.Items.EndUpdate;
    end;
  end;
  if Assigned(FLblPage) then
    FLblPage.Caption := Format(TrText('FindOcc.ListPageStatus'),
      [FPageIndex, FPageCount, FTotalHits]);
  if Assigned(FBtnPagePrev) then
    FBtnPagePrev.Enabled := ACanPagePrev;
  if Assigned(FBtnPageNext) then
    FBtnPageNext.Enabled := ACanPageNext;
  if Assigned(FBtnPageExport) then
    FBtnPageExport.Enabled := ATotalHits > 0;
  if KeepListCollapsed then
    Exit;
  { Fresh Collect / Load more / paging opens the hit list. }
  FListCollapsed := False;
  SetExpanded(True);
end;

{ The jump into a multi-million-line file is heavy; run it after the list has
  painted its new selection, and only for the last of a burst of clicks or
  arrow keys. }
procedure TFastFileFindOccBar.QueueHitClick;
var
  Idx: Integer;
begin
  if not Assigned(FOnHitClick) or not Assigned(FHitList) then Exit;
  Idx := FHitList.ItemIndex;
  if Idx < 0 then Exit;
  FPendingHit := FHitPageBase + Idx;
  FHitTimer.Enabled := False;
  FHitTimer.Enabled := True;
end;

procedure TFastFileFindOccBar.HitTimerTick(Sender: TObject);
var
  Hit: Int64;
begin
  FHitTimer.Enabled := False;
  Hit := FPendingHit;
  FPendingHit := -1;
  if (Hit < 0) or not Assigned(FOnHitClick) then Exit;
  FLastFiredHit := Hit;
  FLastFireTick := GetTickCount;
  FOnHitClick(Self, Hit);
end;

procedure TFastFileFindOccBar.HitListClick(Sender: TObject);
begin
  QueueHitClick;
end;

procedure TFastFileFindOccBar.HitListDblClick(Sender: TObject);
begin
  { The first click of the pair already jumped to this hit. }
  if (not FHitTimer.Enabled) and (FHitList.ItemIndex >= 0) and
     (FHitPageBase + FHitList.ItemIndex = FLastFiredHit) and
     (GetTickCount - FLastFireTick < Cardinal(GetDoubleClickTime) * 2) then
    Exit;
  QueueHitClick;
end;

function TFastFileFindOccBar.HitListFocused: Boolean;
begin
  Result := Assigned(FHitList) and FHitList.Focused;
end;

function TFastFileFindOccBar.HitJumpPending: Boolean;
begin
  Result := Assigned(FHitTimer) and FHitTimer.Enabled;
end;

procedure TFastFileFindOccBar.SyncPageExportWidth;
var
  Bmp: TBitmap;
begin
  if not Assigned(FBtnPageExport) then Exit;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FBtnPageExport.Font);
    FBtnPageExport.Width := Max(FfPx(56),
      MulDiv(Bmp.Canvas.TextWidth(FBtnPageExport.Caption), FfPx(100), 100) + FfPx(18));
  finally
    Bmp.Free;
  end;
end;

procedure TFastFileFindOccBar.BtnPageExportClick(Sender: TObject);

  procedure AddItem(const ACaption: string; ATag: Integer);
  var
    Item: TMenuItem;
  begin
    Item := TMenuItem.Create(FPageMenu);
    Item.Caption := ACaption;
    Item.Tag := ATag;
    Item.OnClick := PageMenuClick;
    FPageMenu.Items.Add(Item);
  end;

var
  PageN: Integer;
  P: TPoint;
begin
  if not Assigned(FOnPageExport) or not Assigned(FHitList) then Exit;
  PageN := FHitList.Items.Count;
  FPageMenu.Items.Clear;
  AddItem(Format(TrText('FindOcc.PageMenu.ExportPage'), [PageN]), 0);
  AddItem(Format(TrText('FindOcc.PageMenu.ExportAll'), [FTotalHits]), 1);
  FPageMenu.Items.Add(NewLine);
  AddItem(Format(TrText('FindOcc.PageMenu.CopyPage'), [PageN]), 2);
  AddItem(Format(TrText('FindOcc.PageMenu.CopyAll'), [FTotalHits]), 3);
  P := FBtnPageExport.ClientToScreen(Point(0, FBtnPageExport.Height));
  FPageMenu.Popup(P.X, P.Y);
end;

procedure TFastFileFindOccBar.PageMenuClick(Sender: TObject);
var
  Tag: Integer;
begin
  if not Assigned(FOnPageExport) or not (Sender is TMenuItem) then Exit;
  Tag := TMenuItem(Sender).Tag;
  FOnPageExport(Self, Odd(Tag), Tag >= 2);
end;

procedure TFastFileFindOccBar.BtnPrevClick(Sender: TObject);
begin
  if Assigned(FOnPrev) then FOnPrev(Self);
end;

procedure TFastFileFindOccBar.BtnNextClick(Sender: TObject);
begin
  if Assigned(FOnNext) then FOnNext(Self);
end;

procedure TFastFileFindOccBar.BtnGoClick(Sender: TObject);
begin
  if Assigned(FOnSearch) then FOnSearch(Self);
end;

procedure TFastFileFindOccBar.RememberSearch(const AText: string);
begin
  if Assigned(FMru) then
    FMru.Remember(AText);
  RefreshRecentCombo;
end;

procedure TFastFileFindOccBar.RefreshRecentCombo;
begin
  if not Assigned(FMru) or not Assigned(FCmbRecent) then Exit;
  FMru.RefreshCombo(FCmbRecent, TrText('FindOcc.RecentEmpty'));
end;

procedure TFastFileFindOccBar.CmbRecentChange(Sender: TObject);
begin
  { Picks come from the in-popup list, not the native combo. }
end;

procedure TFastFileFindOccBar.CmbRecentCloseUp(Sender: TObject);
begin
end;

procedure TFastFileFindOccBar.CmbRecentDropDown(Sender: TObject);
begin
  if Assigned(FCmbRecent) then
    FCmbRecent.DroppedDown := False;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  PostMessage(Handle, WM_APP + 74, 0, 0);
end;

procedure TFastFileFindOccBar.WMFindOccMruPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
begin
  if Assigned(FCmbRecent) then
    FCmbRecent.DroppedDown := False;
  if (GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0) then
  begin
    PostMessage(Handle, WM_APP + 74, 0, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if not Assigned(FMru) or (FMru.Items.Count = 0) then Exit;
  if not Assigned(FCmbRecent) then Exit;
  if FCmbRecent.HandleAllocated then
  begin
    GetWindowRect(FCmbRecent.Handle, CR);
    W := CR.Right - CR.Left;
    P := Point(CR.Left, CR.Bottom);
  end
  else
  begin
    W := FCmbRecent.Width;
    P := FCmbRecent.ClientToScreen(Point(0, FCmbRecent.Height));
  end;
  ShowMruListPopup(Self, TrText('FindOcc.Recent'),
    MruMoreCaption('FindOcc.RecentMore'), FMru.Items, W, P, FindOccMruPick,
    TrText('FindOcc.RecentMoreHint'), nil, nil, FCmbRecent, FindOccMruClearAll);
end;

procedure TFastFileFindOccBar.FindOccMruPick(Sender: TObject; const AValue: string;
  AIndex: Integer);
begin
  if Assigned(FEdtFind) then
  begin
    FEdtFind.Text := AValue;
    FocusSearchEdit;
  end;
end;

procedure TFastFileFindOccBar.FindOccMruClearAll(Sender: TObject);
begin
  if not Assigned(FMru) then Exit;
  FMru.ClearAll;
  RefreshRecentCombo;
end;

procedure TFastFileFindOccBar.EdtFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    if Assigned(FOnSearch) then FOnSearch(Self);
  end;
end;

procedure TFastFileFindOccBar.BtnCollectClick(Sender: TObject);
begin
  if Assigned(FOnCollect) then FOnCollect(Self);
end;

procedure TFastFileFindOccBar.BtnLoadMoreClick(Sender: TObject);
begin
  if Assigned(FOnLoadMore) then FOnLoadMore(Self);
end;

procedure TFastFileFindOccBar.BtnExportClick(Sender: TObject);
begin
  if Assigned(FOnExport) then FOnExport(Self);
end;

procedure TFastFileFindOccBar.BtnCopyClick(Sender: TObject);
begin
  if Assigned(FOnCopy) then FOnCopy(Self);
end;

procedure TFastFileFindOccBar.BtnClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then FOnClear(Self);
end;

procedure TFastFileFindOccBar.BtnHideClick(Sender: TObject);
begin
  if Assigned(FOnHide) then FOnHide(Self);
end;

procedure TFastFileFindOccBar.BtnFloatClick(Sender: TObject);
begin
  if Assigned(FOnFloat) then FOnFloat(Self);
end;

procedure TFastFileFindOccBar.SyncFloatAction;
begin
  if not Assigned(FBtnFloat) then Exit;
  if FFloating then
  begin
    FBtnFloat.Caption := #$2199;
    FBtnFloat.Hint := TrText('Panel.DockHint');
  end
  else
  begin
    FBtnFloat.Caption := #$2197;
    FBtnFloat.Hint := TrText('Panel.RestoreFloatHint');
  end;
  FBtnFloat.ShowHint := True;
end;

procedure TFastFileFindOccBar.SetFloatingLook(AFloating: Boolean);
begin
  FFloating := AFloating;
  if AFloating then
  begin
    SetCollapsed(False);
    Constraints.MinHeight := 0;
    Constraints.MaxHeight := 0;
  end;
  if Assigned(FBtnChevron) then
    FBtnChevron.Visible := not AFloating;
  SyncFloatAction;
  LayoutFrame;
end;

procedure TFastFileFindOccBar.ChevronClick(Sender: TObject);
begin
  if Assigned(FOnHeaderClick) then
    FOnHeaderClick(Self);
end;

function TFastFileFindOccBar.HeaderHeight: Integer;
begin
  if Assigned(FBody) then
    Result := FBody.Padding.Top + FfPx(FIND_OCC_TOP_H) + FBody.Padding.Bottom
  else
    Result := FfPx(FIND_OCC_TOP_H + 16);
end;

procedure TFastFileFindOccBar.SetCollapsed(AValue: Boolean);
begin
  if FFloating then
    AValue := False;
  if FCollapsed = AValue then
  begin
    { Still refresh chrome: layout may have re-shown rows under a short card. }
    if FCollapsed then
    begin
      if Assigned(FStatusRow) then FStatusRow.Visible := False;
      if Assigned(FRecentRow) then FRecentRow.Visible := False;
      if Assigned(FSearchRow) then FSearchRow.Visible := False;
      if Assigned(FBtnRow) then FBtnRow.Visible := False;
      if Assigned(FListHost) then FListHost.Visible := False;
      SyncCollapseMask(FCollapseMask, Self, FBody,
        FBody.Padding.Top + FfPx(FIND_OCC_TOP_H), CSurface, True);
    end;
    Exit;
  end;
  FCollapsed := AValue;
  SyncPanelChevron(FBtnChevron, FCollapsed);
  if FCollapsed then
  begin
    if Assigned(FStatusRow) then FStatusRow.Visible := False;
    if Assigned(FRecentRow) then FRecentRow.Visible := False;
    if Assigned(FSearchRow) then FSearchRow.Visible := False;
    if Assigned(FBtnRow) then FBtnRow.Visible := False;
    if Assigned(FListHost) then FListHost.Visible := False;
  end
  else
  begin
    if Assigned(FStatusRow) then FStatusRow.Visible := True;
    if Assigned(FRecentRow) then FRecentRow.Visible := True;
    if Assigned(FSearchRow) then FSearchRow.Visible := True;
    if Assigned(FBtnRow) then FBtnRow.Visible := True;
    if Assigned(FListHost) then
      FListHost.Visible := FExpanded;
    SyncListToggle;
  end;
  SyncCollapseMask(FCollapseMask, Self, FBody,
    FBody.Padding.Top + FfPx(FIND_OCC_TOP_H), CSurface, FCollapsed);
end;

procedure TFastFileFindOccBar.RelayoutAfterDock;
begin
  Align := alNone;
  Constraints.MinHeight := 0;
  Constraints.MaxHeight := 0;
  LayoutFrame;
end;

procedure TFastFileFindOccBar.TitleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHeaderDown := True;
  FHeaderPt := Point(X, Y);
end;

procedure TFastFileFindOccBar.TitleMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not FHeaderDown then Exit;
  if (Abs(X - FHeaderPt.X) < FfPx(6)) and (Abs(Y - FHeaderPt.Y) < FfPx(6)) then Exit;
  FHeaderDown := False;
  if (not FFloating) and Assigned(FOnTearOff) then
    FOnTearOff(Self);
end;

procedure TFastFileFindOccBar.TitleMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  WasClick: Boolean;
begin
  WasClick := FHeaderDown and (Button = mbLeft);
  FHeaderDown := False;
  if WasClick and (not FFloating) and Assigned(FOnHeaderClick) then
    FOnHeaderClick(Self);
end;

procedure TFastFileFindOccBar.BtnPagePrevClick(Sender: TObject);
begin
  if Assigned(FOnListPagePrev) then FOnListPagePrev(Self);
end;

procedure TFastFileFindOccBar.BtnPageNextClick(Sender: TObject);
begin
  if Assigned(FOnListPageNext) then FOnListPageNext(Self);
end;

{ TFastFileFindOccPeek }

constructor TFastFileFindOccPeek.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  Height := FIND_OCC_PEEK_HEIGHT;
  BevelOuter := bvNone;
  Caption := '';
  Cursor := crHandPoint;
  ShowHint := True;
  OnClick := PeekClick;
  ApplySoftFrame;
end;

procedure TFastFileFindOccPeek.ApplySoftFrame;
begin
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  ParentBackground := False;
  ParentColor := False;
  Color := CAccent;
  Hint := TrText('FindOcc.PeekHint');
end;

procedure TFastFileFindOccPeek.PeekClick(Sender: TObject);
begin
  if Assigned(FOnRestore) then FOnRestore(Self);
end;

end.
