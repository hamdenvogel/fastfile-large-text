unit uBookmarkBar;
{ Docked Bookmarks frame (Ctrl+B): list of bookmarks, jump on click,
  Prev/Next, remove one, clear all, Export/Copy, hide + float/peek. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  Math, Buttons, sPanel, sLabel, sButton, sSpeedButton, uFastFileScale, uSearchCommands,
  uSoftPanelButtons, uPanelSearchMru;

type
  TBookmarkJumpEvent = procedure(Sender: TObject; AIndex: Integer) of object;

  TFastFileBookmarkBar = class(TsPanel)
  private
    FBuilt: Boolean;
    FAccent: TsPanel;
    FBody: TsPanel;
    FTopRow: TsPanel;
    FRecentRow: TsPanel;
    FLblRecent: TsLabel;
    FCmbRecent: TComboBox;
    FMru: TPanelSearchMru;
    FSearchRow: TsPanel;
    FEditShell: TsPanel;
    FEditFrame: TsPanel;
    FEdtFilter: TEdit;
    FBtnRow: TsPanel;
    FListHost: TsPanel;
    FListShell: TsPanel;
    FListInner: TsPanel;
    FPageBar: TsPanel;
    FLblTitle: TsLabel;
    FLblStatus: TsLabel;
    FLblPage: TsLabel;
    FBtnPrev: TsButton;
    FBtnNext: TsButton;
    FBtnRemove: TsButton;
    FBtnClear: TsButton;
    FBtnClose: TsButton;
    FBtnExport: TsButton;
    FBtnCopy: TsButton;
    FBtnGrep, FBtnGlob: TsButton;
    FBtnHide: TsButton;
    FBtnFloat: TsButton;
    FBtnPagePrev: TsButton;
    FBtnPageNext: TsButton;
    FList: TListBox;
    FPageBase: Integer;
    FOnPrev: TNotifyEvent;
    FOnNext: TNotifyEvent;
    FOnRemove: TNotifyEvent;
    FOnClear: TNotifyEvent;
    FOnExport: TNotifyEvent;
    FOnCopy: TNotifyEvent;
    FOnCommand: TSearchCommandOpenEvent;
    FOnHide: TNotifyEvent;
    FOnFloat: TNotifyEvent;
    FOnTearOff: TNotifyEvent;
    FOnJump: TBookmarkJumpEvent;
    FOnListPagePrev: TNotifyEvent;
    FOnListPageNext: TNotifyEvent;
    FOnFilterChanged: TNotifyEvent;
    FFloating: Boolean;
    FUserHeight: Integer;
    FChromeH: Integer;
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
    procedure BodyResize(Sender: TObject);
    procedure BtnPrevClick(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure BtnRemoveClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnCommandClick(Sender: TObject);
    procedure BtnHideClick(Sender: TObject);
    procedure BtnFloatClick(Sender: TObject);
    procedure BtnPagePrevClick(Sender: TObject);
    procedure BtnPageNextClick(Sender: TObject);
    procedure ListClick(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure FireJump;
    procedure TitleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SyncFloatAction;
    procedure CmbRecentDropDown(Sender: TObject);
    procedure CmbRecentChange(Sender: TObject);
    procedure CmbRecentCloseUp(Sender: TObject);
    procedure BookmarkMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure BookmarkMruClearAll(Sender: TObject);
    procedure WMBookmarkMruPopup(var Msg: TMessage); message WM_APP + 75;
    procedure EdtFilterKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RefreshRecentCombo;
    procedure FireFilterChanged;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EnsureBuilt;
    procedure SetIniPath(const APath: string);
    procedure RememberFilter(const AText: string);
    procedure ApplyCaptions;
    procedure ApplySoftFrame;
    procedure SetStatus(const AStatusText: string; AHasItems: Boolean);
    procedure SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
    procedure ClearList;
    function PreferredHeight: Integer;
    function FrameHeight: Integer;
    { Height of everything above the list, at the current width. }
    function ChromeHeight: Integer;
    property UserHeight: Integer read FUserHeight write FUserHeight;
    function GetFilterText: string;
    procedure SetFilterText(const AText: string);
    function SelectedIndexAbsolute: Integer;
    procedure SetListPage(ALines: TStrings; APageBase, APageIndex, APageCount,
      ATotal: Integer; ACanPagePrev, ACanPageNext: Boolean);
    property OnPrev: TNotifyEvent read FOnPrev write FOnPrev;
    property OnNext: TNotifyEvent read FOnNext write FOnNext;
    property OnRemove: TNotifyEvent read FOnRemove write FOnRemove;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnCopy: TNotifyEvent read FOnCopy write FOnCopy;
    property OnCommand: TSearchCommandOpenEvent read FOnCommand write FOnCommand;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnFloat: TNotifyEvent read FOnFloat write FOnFloat;
    property OnTearOff: TNotifyEvent read FOnTearOff write FOnTearOff;
    property OnJump: TBookmarkJumpEvent read FOnJump write FOnJump;
    property OnListPagePrev: TNotifyEvent read FOnListPagePrev write FOnListPagePrev;
    property OnListPageNext: TNotifyEvent read FOnListPageNext write FOnListPageNext;
    property OnFilterChanged: TNotifyEvent read FOnFilterChanged write FOnFilterChanged;
    procedure SetFloatingLook(AFloating: Boolean);
    procedure RelayoutAfterDock;
    { Height of the title row alone (collapsed accordion card). }
    function HeaderHeight: Integer;
    procedure SetCollapsed(AValue: Boolean);
    property Collapsed: Boolean read FCollapsed;
    { Docked: title clicked (not dragged) or chevron pressed. }
    property OnHeaderClick: TNotifyEvent read FOnHeaderClick write FOnHeaderClick;
  end;

  TFastFileBookmarkPeek = class(TsPanel)
  private
    FOnRestore: TNotifyEvent;
    procedure PeekClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplySoftFrame;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

const
  BOOKMARK_BAR_HEIGHT = 420;
  BOOKMARK_PEEK_HEIGHT = 5;
  BOOKMARK_BTN_H = 28;
  BOOKMARK_TOP_H = 26;
  BOOKMARK_RECENT_H = 24;
  BOOKMARK_SEARCH_H = 30;
  BOOKMARK_LIST_PAGE_SIZE = 40;
  BOOKMARK_LIST_MIN_H = 200;
  BOOKMARK_LIST_TIGHT_H = 140;
  BOOKMARK_FILE_LIST_RESERVE = 200;
  BOOKMARK_RECENT_INI_SECTION = 'BookmarkRecentPatterns';

implementation

uses
  UnConsts,
  uI18n, uBidiLayout, uMruFind, UnitPopupMruList, uUserPrefs;

const
  CAccent = TColor($00BFAF9C);
  CSurface = TColor($00F6F3EE);
  CSurfaceHi = TColor($00EDE8E1);
  CBorder = TColor($00CFC6BB);
  CWindow = TColor($00FFFCF8);
  CTitle = TColor($001C1610);
  CMuted = TColor($006B6158);
  CStatusOk = TColor($002E7D32);
  CStatusIdle = TColor($006B6158);
  CAccentW = 3;

function PreferUiFont: string;
begin
  if Screen.Fonts.IndexOf(FONT_SEGOE_UI) >= 0 then
    Result := FONT_SEGOE_UI
  else
    Result := FONT_TAHOMA;
end;

procedure TFastFileBookmarkBar.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
end;

constructor TFastFileBookmarkBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBuilt := False;
  FFloating := False;
  FUserHeight := 0;
  FChromeH := 0;
  FHeaderDown := False;
  FPageBase := 0;
  FMru := TPanelSearchMru.Create(BOOKMARK_RECENT_INI_SECTION);
  Align := alTop;
  Height := FfPx(BOOKMARK_BAR_HEIGHT);
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

destructor TFastFileBookmarkBar.Destroy;
begin
  FreeAndNil(FMru);
  inherited Destroy;
end;

procedure TFastFileBookmarkBar.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(AParent) then
    EnsureBuilt;
end;

procedure TFastFileBookmarkBar.SetIniPath(const APath: string);
begin
  if Assigned(FMru) then
    FMru.IniPath := APath;
  if FBuilt then
    RefreshRecentCombo;
end;

procedure TFastFileBookmarkBar.EnsureBuilt;
begin
  if FBuilt then Exit;
  BuildFrame;
  FBuilt := True;
  ApplySoftFrame;
  ApplyCaptions;
  RefreshRecentCombo;
  LayoutFrame;
end;

procedure TFastFileBookmarkBar.ForceColor(APnl: TsPanel; AColor: TColor);
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

procedure TFastFileBookmarkBar.StyleBtn(ABtn: TsButton; const AUiFont: string;
  ARole: TSoftPanelBtnRole);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.Height := FfPx(BOOKMARK_BTN_H);
  StyleSoftPanelBtn(ABtn, AUiFont, ARole);
end;

procedure TFastFileBookmarkBar.StyleFrameBtn(ABtn: TsButton; const AUiFont: string);
begin
  StyleSoftPanelFrameBtn(ABtn, AUiFont);
end;

procedure TFastFileBookmarkBar.BuildFrame;
var
  UiFont: string;
begin
  UiFont := PreferUiFont;

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

  FTopRow := TsPanel.Create(Self);
  FTopRow.Parent := FBody;
  FTopRow.Align := alNone;
  FTopRow.Height := FfPx(BOOKMARK_TOP_H);
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
  FLblTitle.Caption := 'Bookmarks';
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

  FLblStatus := TsLabel.Create(Self);
  FLblStatus.Parent := FBody;
  FLblStatus.AutoSize := False;
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
  FRecentRow.Height := FfPx(BOOKMARK_RECENT_H);
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
  FSearchRow.Height := FfPx(BOOKMARK_SEARCH_H);
  FSearchRow.BevelOuter := bvNone;
  FSearchRow.Caption := '';
  ForceColor(FSearchRow, CSurface);

  FEditShell := TsPanel.Create(Self);
  FEditShell.Parent := FSearchRow;
  FEditShell.Align := alClient;
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

  FEdtFilter := TEdit.Create(Self);
  FEdtFilter.Parent := FEditFrame;
  FEdtFilter.Align := alClient;
  FEdtFilter.BorderStyle := bsNone;
  FEdtFilter.ParentFont := False;
  FEdtFilter.Font.Name := UiFont;
  FEdtFilter.Font.Size := 10;
  FEdtFilter.Font.Color := CTitle;
  FEdtFilter.ParentColor := False;
  FEdtFilter.Color := CWindow;
  FEdtFilter.OnKeyDown := EdtFilterKeyDown;
  FEdtFilter.ShowHint := True;
  BidiKeepLtr(FEdtFilter);

  FBtnRow := TsPanel.Create(Self);
  FBtnRow.Parent := FBody;
  FBtnRow.Align := alNone;
  FBtnRow.Height := FfPx(BOOKMARK_BTN_H + 6);
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

  FBtnRemove := TsButton.Create(Self);
  FBtnRemove.Parent := FBtnRow;
  FBtnRemove.OnClick := BtnRemoveClick;
  StyleBtn(FBtnRemove, UiFont, spbrQuiet);

  FBtnClear := TsButton.Create(Self);
  FBtnClear.Parent := FBtnRow;
  FBtnClear.OnClick := BtnClearClick;
  StyleBtn(FBtnClear, UiFont, spbrQuiet);

  FBtnClose := TsButton.Create(Self);
  FBtnClose.Parent := FBtnRow;
  FBtnClose.OnClick := BtnHideClick;
  StyleBtn(FBtnClose, UiFont, spbrQuiet);

  FBtnExport := TsButton.Create(Self);
  FBtnExport.Parent := FBtnRow;
  FBtnExport.OnClick := BtnExportClick;
  StyleBtn(FBtnExport, UiFont, spbrAction);

  FBtnCopy := TsButton.Create(Self);
  FBtnCopy.Parent := FBtnRow;
  FBtnCopy.OnClick := BtnCopyClick;
  StyleBtn(FBtnCopy, UiFont, spbrAction);

  FBtnGrep := TsButton.Create(Self);
  FBtnGrep.Name := 'SearchGrep';
  FBtnGrep.Parent := FBtnRow;
  FBtnGrep.OnClick := BtnCommandClick;
  StyleBtn(FBtnGrep, UiFont, spbrCommand);
  FBtnGlob := TsButton.Create(Self);
  FBtnGlob.Name := 'SearchGlob';
  FBtnGlob.Parent := FBtnRow;
  FBtnGlob.OnClick := BtnCommandClick;
  StyleBtn(FBtnGlob, UiFont, spbrCommand);

  FListHost := TsPanel.Create(Self);
  FListHost.Parent := FBody;
  FListHost.Align := alNone;
  FListHost.BevelOuter := bvNone;
  FListHost.Caption := '';
  ForceColor(FListHost, CSurface);

  FPageBar := TsPanel.Create(Self);
  FPageBar.Parent := FListHost;
  FPageBar.Align := alBottom;
  FPageBar.Height := FfPx(BOOKMARK_BTN_H);
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

  FLblPage := TsLabel.Create(Self);
  FLblPage.Parent := FPageBar;
  FLblPage.Align := alClient;
  FLblPage.Transparent := True;
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

  FList := TListBox.Create(Self);
  FList.Parent := FListInner;
  FList.Align := alClient;
  FList.BorderStyle := bsNone;
  FList.ParentFont := False;
  FList.Font.Name := UiFont;
  FList.Font.Size := 9;
  FList.Font.Color := CTitle;
  FList.Color := CWindow;
  FList.OnClick := ListClick;
  FList.OnDblClick := ListDblClick;
  BidiKeepLtr(FList); { bookmark entries show raw file lines }
  HookListWheel(FList);
end;

procedure TFastFileBookmarkBar.LayoutFrame;
var
  L, Y, W, Gap, RecentLblW, RecentH, SearchH, StatusH, FlowH, ListH: Integer;
  MeasureBmp: TBitmap;
  BL: IInterface;
begin
  if not FBuilt or not Assigned(FBody) then Exit;
  { Accordion: host owns height — keep chrome hidden while shut. }
  if FCollapsed and (not FFloating) then
  begin
    if Assigned(FRecentRow) then FRecentRow.Visible := False;
    if Assigned(FSearchRow) then FSearchRow.Visible := False;
    if Assigned(FBtnRow) then FBtnRow.Visible := False;
    if Assigned(FListHost) then FListHost.Visible := False;
    if Assigned(FLblStatus) then FLblStatus.Visible := False;
    if Assigned(FTopRow) then
    begin
      L := FBody.Padding.Left;
      W := FBody.ClientWidth - FBody.Padding.Left - FBody.Padding.Right;
      if W < FfPx(120) then
        W := FfPx(120);
      FTopRow.SetBounds(L, FBody.Padding.Top, W, FfPx(BOOKMARK_TOP_H));
    end;
    SyncCollapseMask(FCollapseMask, Self, FBody,
      FBody.Padding.Top + FfPx(BOOKMARK_TOP_H), CSurface, True);
    Exit;
  end;
  BL := BidiLayoutScope([FBody, FRecentRow, FSearchRow, FBtnRow]);
  L := FBody.Padding.Left;
  W := FBody.ClientWidth - FBody.Padding.Left - FBody.Padding.Right;
  if W < FfPx(120) then
    W := FfPx(120);
  Gap := FfPx(6);
  RecentH := FfPx(BOOKMARK_RECENT_H);
  SearchH := FfPx(BOOKMARK_SEARCH_H);
  Y := FBody.Padding.Top;
  FTopRow.SetBounds(L, Y, W, FfPx(BOOKMARK_TOP_H));
  Inc(Y, FTopRow.Height + FfPx(2));

  MeasureBmp := TBitmap.Create;
  try
    MeasureBmp.SetSize(1, 1);
    MeasureBmp.Canvas.Font.Assign(FLblStatus.Font);
    StatusH := Max(FfPx(14), MeasureBmp.Canvas.TextHeight('Áy') + 2);
    FLblStatus.SetBounds(L + FfPx(2), Y, W - FfPx(2), StatusH);
    Inc(Y, StatusH + FfPx(4));

    if Assigned(FRecentRow) then
    begin
      FRecentRow.SetBounds(L, Y, W, RecentH);
      RecentLblW := FfPx(48);
      if Assigned(FLblRecent) then
      begin
        MeasureBmp.Canvas.Font.Assign(FLblRecent.Font);
        RecentLblW := Min(W div 3,
          MeasureBmp.Canvas.TextWidth(FLblRecent.Caption) + FfPx(6));
        FLblRecent.SetBounds(0, 0, RecentLblW, RecentH);
      end;
      if Assigned(FCmbRecent) then
        FCmbRecent.SetBounds(RecentLblW + FfPx(4), 0,
          Max(FfPx(60), W - RecentLblW - FfPx(4)), RecentH);
      Inc(Y, RecentH + Gap);
    end;
    if Assigned(FSearchRow) then
    begin
      FSearchRow.SetBounds(L, Y, W, SearchH);
      Inc(Y, SearchH + Gap);
    end;

    FlowH := FlowSoftPanelButtons([FBtnPrev, FBtnNext, FBtnRemove, FBtnClear,
      FBtnExport, FBtnCopy, FBtnGrep, FBtnGlob, FBtnClose], MeasureBmp.Canvas,
      0, 0, W, FfPx(BOOKMARK_BTN_H), Gap, FfPx(52), FfPx(24));
    FBtnRow.SetBounds(L, Y, W, FlowH);
    Inc(Y, FlowH + Gap);
  finally
    MeasureBmp.Free;
  end;

  FChromeH := Y + FBody.Padding.Bottom;
  { The bottom resize grip (floating only) sits outside FBody. }
  if FFloating then
  begin
    Inc(FChromeH, FfPx(16));
    Constraints.MinHeight := FChromeH + FfPx(BOOKMARK_LIST_TIGHT_H);
    Constraints.MaxHeight := 0;
  end;
  { Docked: LayoutSearchDock locks Min/MaxHeight for the accordion slot. }
  ListH := FBody.ClientHeight - Y - FBody.Padding.Bottom;
  if ListH < FfPx(48) then
    ListH := FfPx(48);
  FListHost.SetBounds(L, Y, W, ListH);
  FListHost.Visible := True;
  if Assigned(FLblStatus) then
    FLblStatus.Visible := True;
end;

function TFastFileBookmarkBar.ChromeHeight: Integer;
begin
  if FBuilt then
    LayoutFrame;
  if FChromeH > 0 then
    Result := FChromeH
  else
    Result := FrameHeight - FfPx(BOOKMARK_LIST_MIN_H);
end;

procedure TFastFileBookmarkBar.BodyResize(Sender: TObject);
begin
  LayoutFrame;
end;

procedure TFastFileBookmarkBar.Resize;
begin
  inherited Resize;
  if FBuilt and (not FFloating) and (Height >= Constraints.MinHeight) and
     (Constraints.MinHeight > 0) then
    FUserHeight := Height;
  if FBuilt then
    LayoutFrame;
end;

procedure TFastFileBookmarkBar.RelayoutAfterDock;
begin
  EnsureBuilt;
  Align := alNone;
  Constraints.MinHeight := 0;
  Constraints.MaxHeight := 0;
  LayoutFrame;
end;

procedure TFastFileBookmarkBar.ApplySoftFrame;
var
  UiFont: string;
begin
  EnsureBuilt;
  UiFont := PreferUiFont;
  ForceColor(Self, CSurface);
  ForceColor(FAccent, CAccent);
  ForceColor(FBody, CSurface);
  ForceColor(FTopRow, CSurfaceHi);
  if Assigned(FRecentRow) then ForceColor(FRecentRow, CSurface);
  if Assigned(FSearchRow) then ForceColor(FSearchRow, CSurface);
  if Assigned(FEditShell) then ForceColor(FEditShell, CBorder);
  if Assigned(FEditFrame) then ForceColor(FEditFrame, CWindow);
  ForceColor(FBtnRow, CSurface);
  ForceColor(FListHost, CSurface);
  ForceColor(FPageBar, CSurfaceHi);
  ForceColor(FListShell, CBorder);
  ForceColor(FListInner, CWindow);
  if Assigned(FCmbRecent) then
  begin
    FCmbRecent.ParentColor := False;
    FCmbRecent.Color := CWindow;
    FCmbRecent.Font.Name := UiFont;
  end;
  if Assigned(FEdtFilter) then
  begin
    FEdtFilter.ParentColor := False;
    FEdtFilter.Color := CWindow;
    FEdtFilter.Font.Name := UiFont;
    FEdtFilter.Font.Color := CTitle;
  end;
  if Assigned(FList) then
    FList.Color := CWindow;
  StyleBtn(FBtnPrev, UiFont, spbrAction);
  StyleBtn(FBtnNext, UiFont, spbrPrimary);
  StyleBtn(FBtnRemove, UiFont, spbrQuiet);
  StyleBtn(FBtnClear, UiFont, spbrQuiet);
  StyleBtn(FBtnClose, UiFont, spbrQuiet);
  StyleBtn(FBtnExport, UiFont, spbrAction);
  StyleBtn(FBtnCopy, UiFont, spbrAction);
  StyleBtn(FBtnGrep, UiFont, spbrCommand);
  StyleBtn(FBtnGlob, UiFont, spbrCommand);
  StyleFrameBtn(FBtnHide, UiFont);
  StyleFrameBtn(FBtnFloat, UiFont);
  StyleFrameBtn(FBtnPagePrev, UiFont);
  StyleFrameBtn(FBtnPageNext, UiFont);
end;

procedure TFastFileBookmarkBar.SyncFloatAction;
begin
  if not Assigned(FBtnFloat) then Exit;
  if FFloating then
  begin
    FBtnFloat.Caption := #$25A3;
    FBtnFloat.Hint := TrText('BookmarkBar.DockHint');
  end
  else
  begin
    FBtnFloat.Caption := #$2398;
    FBtnFloat.Hint := TrText('BookmarkBar.FloatHint');
  end;
end;

procedure TFastFileBookmarkBar.SetFloatingLook(AFloating: Boolean);
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

procedure TFastFileBookmarkBar.ChevronClick(Sender: TObject);
begin
  if Assigned(FOnHeaderClick) then
    FOnHeaderClick(Self);
end;

function TFastFileBookmarkBar.HeaderHeight: Integer;
begin
  if Assigned(FBody) then
    Result := FBody.Padding.Top + FfPx(BOOKMARK_TOP_H) + FBody.Padding.Bottom
  else
    Result := FfPx(BOOKMARK_TOP_H + 16);
end;

procedure TFastFileBookmarkBar.SetCollapsed(AValue: Boolean);
begin
  if FFloating then
    AValue := False;
  if FCollapsed = AValue then
  begin
    if FCollapsed then
    begin
      if Assigned(FLblStatus) then FLblStatus.Visible := False;
      if Assigned(FRecentRow) then FRecentRow.Visible := False;
      if Assigned(FSearchRow) then FSearchRow.Visible := False;
      if Assigned(FBtnRow) then FBtnRow.Visible := False;
      if Assigned(FListHost) then FListHost.Visible := False;
      SyncCollapseMask(FCollapseMask, Self, FBody,
        FBody.Padding.Top + FfPx(BOOKMARK_TOP_H), CSurface, True);
    end;
    Exit;
  end;
  FCollapsed := AValue;
  SyncPanelChevron(FBtnChevron, FCollapsed);
  if FCollapsed then
  begin
    if Assigned(FLblStatus) then FLblStatus.Visible := False;
    if Assigned(FRecentRow) then FRecentRow.Visible := False;
    if Assigned(FSearchRow) then FSearchRow.Visible := False;
    if Assigned(FBtnRow) then FBtnRow.Visible := False;
    if Assigned(FListHost) then FListHost.Visible := False;
  end
  else
  begin
    if Assigned(FLblStatus) then FLblStatus.Visible := True;
    if Assigned(FRecentRow) then FRecentRow.Visible := True;
    if Assigned(FSearchRow) then FSearchRow.Visible := True;
    if Assigned(FBtnRow) then FBtnRow.Visible := True;
    if Assigned(FListHost) then FListHost.Visible := True;
  end;
  SyncCollapseMask(FCollapseMask, Self, FBody,
    FBody.Padding.Top + FfPx(BOOKMARK_TOP_H), CSurface, FCollapsed);
end;

procedure TFastFileBookmarkBar.ApplyCaptions;
begin
  EnsureBuilt;
  FLblTitle.Caption := TrText('BookmarkBar.Title');
  SyncPanelChevron(FBtnChevron, FCollapsed);
  FBtnPrev.Caption := TrText('BookmarkBar.Prev');
  FBtnNext.Caption := TrText('BookmarkBar.Next');
  FBtnRemove.Caption := TrText('BookmarkBar.Remove');
  FBtnClear.Caption := TrText('BookmarkBar.ClearAll');
  if Assigned(FBtnClose) then
    FBtnClose.Caption := TrText('Close');
  FBtnExport.Caption := TrText('FilterBar.Export');
  FBtnCopy.Caption := TrText('Assistant.CopyReply');
  FBtnGrep.Caption := 'grep';
  FBtnGlob.Caption := 'glob';
  FBtnGrep.Hint := Format(TrText('SearchCmd.LaunchHint'), ['grep']);
  FBtnGlob.Hint := Format(TrText('SearchCmd.LaunchHint'), ['glob']);
  FBtnHide.Caption := #$00D7;
  FBtnPrev.Hint := TrText('Pr&evious bookmark');
  FBtnNext.Hint := TrText('&Next bookmark');
  FBtnRemove.Hint := TrText('BookmarkBar.RemoveHint');
  FBtnClear.Hint := TrText('Clear a&ll bookmarks');
  if Assigned(FBtnClose) then
    FBtnClose.Hint := TrText('BookmarkBar.CloseHint');
  FBtnExport.Hint := TrText('BookmarkBar.ExportHint');
  FBtnCopy.Hint := TrText('BookmarkBar.CopyHint');
  FBtnHide.Hint := TrText('Close');
  FBtnPagePrev.Hint := TrText('BookmarkBar.PagePrevHint');
  FBtnPageNext.Hint := TrText('BookmarkBar.PageNextHint');
  if Assigned(FLblRecent) then
    FLblRecent.Caption := TrText('BookmarkBar.Recent');
  if Assigned(FCmbRecent) then
  begin
    FCmbRecent.Hint := TrText('BookmarkBar.RecentHint');
    FCmbRecent.ShowHint := True;
  end;
  if Assigned(FEdtFilter) then
  begin
    FEdtFilter.TextHint := TrText('BookmarkBar.FilterHint');
    FEdtFilter.Hint := TrText('BookmarkBar.FilterHint');
  end;
  RefreshRecentCombo;
  SyncFloatAction;
  LayoutFrame;
end;

procedure TFastFileBookmarkBar.BtnCommandClick(Sender: TObject);
begin
  if not Assigned(FOnCommand) then Exit;
  if Sender = FBtnGlob then FOnCommand(Self, 'glob')
  else FOnCommand(Self, 'grep');
end;

procedure TFastFileBookmarkBar.SetStatus(const AStatusText: string; AHasItems: Boolean);
begin
  EnsureBuilt;
  if Assigned(FLblStatus) then
  begin
    FLblStatus.Caption := AStatusText;
    FLblStatus.Hint := AStatusText;
    if AHasItems then
      FLblStatus.Font.Color := CStatusOk
    else
      FLblStatus.Font.Color := CStatusIdle;
  end;
  if Assigned(FBtnRemove) then FBtnRemove.Enabled := AHasItems;
  if Assigned(FBtnClear) then FBtnClear.Enabled := AHasItems;
  if Assigned(FBtnExport) then FBtnExport.Enabled := AHasItems;
  if Assigned(FBtnCopy) then FBtnCopy.Enabled := AHasItems;
  SetNavEnabled(AHasItems, AHasItems);
  LayoutFrame;
end;

procedure TFastFileBookmarkBar.SetNavEnabled(APrevEnabled, ANextEnabled: Boolean);
begin
  EnsureBuilt;
  if Assigned(FBtnPrev) then FBtnPrev.Enabled := APrevEnabled;
  if Assigned(FBtnNext) then FBtnNext.Enabled := ANextEnabled;
end;

procedure TFastFileBookmarkBar.ClearList;
begin
  EnsureBuilt;
  if Assigned(FList) then
    FList.Items.Clear;
  FPageBase := 0;
  if Assigned(FLblPage) then
    FLblPage.Caption := '';
end;

function TFastFileBookmarkBar.FrameHeight: Integer;
begin
  Result := FfPx(8 + BOOKMARK_TOP_H + 6 + BOOKMARK_RECENT_H + 6 +
    BOOKMARK_SEARCH_H + 6 + BOOKMARK_BTN_H + 6 + BOOKMARK_LIST_MIN_H + 8 + 16);
end;

function TFastFileBookmarkBar.PreferredHeight: Integer;
var
  Cap, FloorH: Integer;
begin
  Result := FfPx(BOOKMARK_BAR_HEIGHT);
  FloorH := FrameHeight;
  if Result < FloorH then
    Result := FloorH;
  if (not FFloating) and Assigned(Parent) and (Parent.ClientHeight > 0) then
  begin
    Cap := Min((Parent.ClientHeight * 55) div 100,
      Parent.ClientHeight - FfPx(BOOKMARK_FILE_LIST_RESERVE));
    if Cap < FfPx(BOOKMARK_LIST_TIGHT_H) + FfPx(140) then
      Cap := FfPx(BOOKMARK_LIST_TIGHT_H) + FfPx(140);
    if Result > Cap then
      Result := Cap;
  end;
end;

function TFastFileBookmarkBar.GetFilterText: string;
begin
  if Assigned(FEdtFilter) then
    Result := FEdtFilter.Text
  else
    Result := '';
end;

procedure TFastFileBookmarkBar.SetFilterText(const AText: string);
begin
  EnsureBuilt;
  if not Assigned(FEdtFilter) then Exit;
  if FEdtFilter.Text = AText then Exit;
  FEdtFilter.Text := AText;
end;

procedure TFastFileBookmarkBar.RememberFilter(const AText: string);
begin
  if Assigned(FMru) then
    FMru.Remember(AText);
  RefreshRecentCombo;
end;

procedure TFastFileBookmarkBar.RefreshRecentCombo;
begin
  if not Assigned(FMru) or not Assigned(FCmbRecent) then Exit;
  FMru.RefreshCombo(FCmbRecent, TrText('BookmarkBar.RecentEmpty'));
end;

procedure TFastFileBookmarkBar.FireFilterChanged;
begin
  if Assigned(FOnFilterChanged) then
    FOnFilterChanged(Self);
end;

procedure TFastFileBookmarkBar.EdtFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  S: string;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    S := Trim(GetFilterText);
    if S <> '' then
      RememberFilter(S);
    FireFilterChanged;
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    SetFilterText('');
    FireFilterChanged;
  end;
end;

procedure TFastFileBookmarkBar.CmbRecentChange(Sender: TObject);
begin
end;

procedure TFastFileBookmarkBar.CmbRecentCloseUp(Sender: TObject);
begin
end;

procedure TFastFileBookmarkBar.CmbRecentDropDown(Sender: TObject);
begin
  if Assigned(FCmbRecent) then
    FCmbRecent.DroppedDown := False;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  PostMessage(Handle, WM_APP + 75, 0, 0);
end;

procedure TFastFileBookmarkBar.WMBookmarkMruPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
begin
  if Assigned(FCmbRecent) then
    FCmbRecent.DroppedDown := False;
  if (GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0) then
  begin
    PostMessage(Handle, WM_APP + 75, 0, 0);
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
  ShowMruListPopup(Self, TrText('BookmarkBar.Recent'),
    MruMoreCaption('BookmarkBar.RecentMore'), FMru.Items, W, P, BookmarkMruPick,
    TrText('BookmarkBar.RecentMoreHint'), nil, nil, FCmbRecent, BookmarkMruClearAll);
end;

procedure TFastFileBookmarkBar.BookmarkMruPick(Sender: TObject; const AValue: string;
  AIndex: Integer);
begin
  SetFilterText(AValue);
  if Assigned(FEdtFilter) and FEdtFilter.CanFocus then
  begin
    FEdtFilter.SetFocus;
    FEdtFilter.SelectAll;
  end;
  RememberFilter(AValue);
  FireFilterChanged;
end;

procedure TFastFileBookmarkBar.BookmarkMruClearAll(Sender: TObject);
begin
  if not Assigned(FMru) then Exit;
  FMru.ClearAll;
  RefreshRecentCombo;
end;

function TFastFileBookmarkBar.SelectedIndexAbsolute: Integer;
begin
  Result := -1;
  if not Assigned(FList) or (FList.ItemIndex < 0) then Exit;
  Result := FPageBase + FList.ItemIndex;
end;

procedure TFastFileBookmarkBar.SetListPage(ALines: TStrings; APageBase, APageIndex,
  APageCount, ATotal: Integer; ACanPagePrev, ACanPageNext: Boolean);
begin
  EnsureBuilt;
  FPageBase := APageBase;
  if Assigned(FList) then
  begin
    FList.Items.BeginUpdate;
    try
      FList.Items.Clear;
      if Assigned(ALines) then
        FList.Items.Assign(ALines);
    finally
      FList.Items.EndUpdate;
    end;
  end;
  if Assigned(FLblPage) then
  begin
    if ATotal <= 0 then
      FLblPage.Caption := ''
    else
      FLblPage.Caption := Format(TrText('BookmarkBar.PageFmt'),
        [APageIndex, Max(1, APageCount), ATotal]);
  end;
  if Assigned(FBtnPagePrev) then FBtnPagePrev.Enabled := ACanPagePrev;
  if Assigned(FBtnPageNext) then FBtnPageNext.Enabled := ACanPageNext;
  if Assigned(FPageBar) then
    FPageBar.Visible := APageCount > 1;
end;

procedure TFastFileBookmarkBar.FireJump;
var
  AbsIdx: Integer;
begin
  AbsIdx := SelectedIndexAbsolute;
  if (AbsIdx < 0) or not Assigned(FOnJump) then Exit;
  FOnJump(Self, AbsIdx);
end;

procedure TFastFileBookmarkBar.ListClick(Sender: TObject);
begin
  FireJump;
end;

procedure TFastFileBookmarkBar.ListDblClick(Sender: TObject);
begin
  FireJump;
end;

procedure TFastFileBookmarkBar.BtnPrevClick(Sender: TObject);
begin
  if Assigned(FOnPrev) then FOnPrev(Self);
end;

procedure TFastFileBookmarkBar.BtnNextClick(Sender: TObject);
begin
  if Assigned(FOnNext) then FOnNext(Self);
end;

procedure TFastFileBookmarkBar.BtnRemoveClick(Sender: TObject);
begin
  if Assigned(FOnRemove) then FOnRemove(Self);
end;

procedure TFastFileBookmarkBar.BtnClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then FOnClear(Self);
end;

procedure TFastFileBookmarkBar.BtnExportClick(Sender: TObject);
begin
  if Assigned(FOnExport) then FOnExport(Self);
end;

procedure TFastFileBookmarkBar.BtnCopyClick(Sender: TObject);
begin
  if Assigned(FOnCopy) then FOnCopy(Self);
end;

procedure TFastFileBookmarkBar.BtnHideClick(Sender: TObject);
begin
  if Assigned(FOnHide) then FOnHide(Self);
end;

procedure TFastFileBookmarkBar.BtnFloatClick(Sender: TObject);
begin
  if Assigned(FOnFloat) then FOnFloat(Self);
end;

procedure TFastFileBookmarkBar.BtnPagePrevClick(Sender: TObject);
begin
  if Assigned(FOnListPagePrev) then FOnListPagePrev(Self);
end;

procedure TFastFileBookmarkBar.BtnPageNextClick(Sender: TObject);
begin
  if Assigned(FOnListPageNext) then FOnListPageNext(Self);
end;

procedure TFastFileBookmarkBar.TitleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHeaderDown := True;
  FHeaderPt := Point(X, Y);
end;

procedure TFastFileBookmarkBar.TitleMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not FHeaderDown then Exit;
  if (Abs(X - FHeaderPt.X) < FfPx(6)) and (Abs(Y - FHeaderPt.Y) < FfPx(6)) then Exit;
  FHeaderDown := False;
  if Assigned(FOnTearOff) then
    FOnTearOff(Self);
end;

procedure TFastFileBookmarkBar.TitleMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  WasClick: Boolean;
begin
  WasClick := FHeaderDown and (Button = mbLeft);
  FHeaderDown := False;
  if WasClick and (not FFloating) and Assigned(FOnHeaderClick) then
    FOnHeaderClick(Self);
end;

{ TFastFileBookmarkPeek }

constructor TFastFileBookmarkPeek.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alTop;
  Height := FfPx(BOOKMARK_PEEK_HEIGHT);
  BevelOuter := bvNone;
  Caption := '';
  Cursor := crHandPoint;
  ParentBackground := False;
  ParentColor := False;
  Color := CAccent;
  OnClick := PeekClick;
  ShowHint := True;
  Hint := TrText('BookmarkBar.PeekHint');
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
end;

procedure TFastFileBookmarkPeek.ApplySoftFrame;
begin
  Color := CAccent;
  Hint := TrText('BookmarkBar.PeekHint');
end;

procedure TFastFileBookmarkPeek.PeekClick(Sender: TObject);
begin
  if Assigned(FOnRestore) then
    FOnRestore(Self);
end;

end.
