unit uFilterBar;
{ Docked Filter / Grep chrome: MRU dropdown (like Assistant) + pattern edit +
  Apply / Continue / Export / Copy / Clear / Close (×). }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  Menus, Buttons, IniFiles, sPanel, sLabel, sButton, sSpeedButton, ImgList,
  uFastFileFloatHost, uFastFileScale;

type
  TFilterBarApplyEvent = procedure(Sender: TObject; const APattern: string) of object;

  TFastFileFilterBar = class(TsPanel)
  private
    FBuilt: Boolean;
    FAccent: TsPanel;
    FBody: TsPanel;
    FEditShell: TsPanel;
    FEditFrame: TsPanel;
    FLblTitle: TsLabel;
    FTitleHit: TsPanel;
    FLblMode: TsLabel;
    FLblRecent: TsLabel;
    FLblStatus: TsLabel;
    FCmbRecent: TComboBox;
    FBtnRecentFind: TsSpeedButton;
    FEdtRecentFind: TEdit;
    FBtnRecentFindClear: TsSpeedButton;
    FEdtPattern: TEdit;
    FBtnApply: TsButton;
    FBtnContinue: TsButton;
    FBtnExport: TsButton;
    FBtnCopy: TsButton;
    FBtnClear: TsButton;
    FBtnHide: TsButton;
    FBtnFloat: TsButton;
    FPopDock: TPopupMenu;
    FMiFloat: TMenuItem;
    FRecent: TStringList;
    FIniPath: string;
    FSuppressRecentChange: Boolean;
    FRecentExpanded: Boolean;
    FExpandingMore: Boolean;
    FFindActive: Boolean;
    FActivatingFind: Boolean;
    FFindNeedle: string;
    FFindImages: TCustomImageList;
    FFindImageIndex: Integer;
    FOnApply: TFilterBarApplyEvent;
    FOnClear: TNotifyEvent;
    FOnContinue: TNotifyEvent;
    FOnExport: TNotifyEvent;
    FOnCopy: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FOnFloat: TNotifyEvent;
    FOnTearOff: TNotifyEvent;
    FOnHeightChanged: TNotifyEvent;
    FFloating: Boolean;
    FHeaderDown: Boolean;
    FHeaderPt: TPoint;
    procedure BuildChrome;
    procedure ForceColor(APnl: TsPanel; AColor: TColor);
    procedure LayoutChrome;
    procedure BtnApplyClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnContinueClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnHideClick(Sender: TObject);
    procedure BtnFloatClick(Sender: TObject);
    procedure SyncFloatAction;
    procedure TitleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TitleMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ApplyTitleDragChrome;
    procedure TitleDblClick(Sender: TObject);
    procedure EdtPatternKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EdtPatternKeyPress(Sender: TObject; var Key: Char);
    procedure EdtPatternChange(Sender: TObject);
    procedure CmbRecentChange(Sender: TObject);
    procedure CmbRecentCloseUp(Sender: TObject);
    procedure CmbRecentDropDown(Sender: TObject);
    procedure FilterMruPick(Sender: TObject; const AValue: string; AIndex: Integer);
    procedure FilterMruClearAll(Sender: TObject);
    procedure BodyResize(Sender: TObject);
    procedure CMDialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
    procedure WMFilterRecentExpand(var Msg: TMessage); message WM_APP + 61;
    procedure WMFilterRecentCollapse(var Msg: TMessage); message WM_APP + 62;
    procedure WMFilterRecentFind(var Msg: TMessage); message WM_APP + 63;
    procedure WMFilterMruPopup(var Msg: TMessage); message WM_APP + 64;
    procedure CmbRecentFindClick(Sender: TObject);
    procedure EdtRecentFindChange(Sender: TObject);
    procedure EdtRecentFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnRecentFindClearClick(Sender: TObject);
    procedure ActivateRecentFind;
    procedure DeactivateRecentFind;
    procedure ApplyRecentFindGlyphs;
    function FormatRecentDisplay(const APattern: string): string;
    function EncodeRecentForIni(const APattern: string): string;
    function DecodeRecentFromIni(const AEncoded: string): string;
    procedure DeduplicateRecent;
    procedure RefreshRecentCombo;
    procedure LoadRecent;
    procedure SaveRecent;
  protected
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EnsureBuilt;
    procedure ApplyCaptions;
    procedure ApplySoftChrome;
    procedure FocusPattern;
    function PatternEditFocused: Boolean;
    function GetPattern: string;
    procedure SetPattern(const AText: string);
    procedure SetModeHint(const AModeText: string);
    procedure SetStatus(const AStatusText: string; AActive, APartial, ABusy: Boolean);
    procedure SetContinueEnabled(AEnabled: Boolean);
    procedure SetResultsActionsVisible(AVisible: Boolean);
    procedure SetIniPath(const APath: string);
    procedure SetMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
    procedure RememberPattern(const APattern: string);
    procedure SetFloatingLook(AFloating: Boolean);
    procedure RelayoutAfterDock;
    property OnTearOff: TNotifyEvent read FOnTearOff write FOnTearOff;
    property OnHeightChanged: TNotifyEvent read FOnHeightChanged write FOnHeightChanged;
    property OnApply: TFilterBarApplyEvent read FOnApply write FOnApply;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnContinue: TNotifyEvent read FOnContinue write FOnContinue;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnCopy: TNotifyEvent read FOnCopy write FOnCopy;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnFloat: TNotifyEvent read FOnFloat write FOnFloat;
  end;

  { Thin clickable strip shown when filter is active but chrome is hidden. }
  TFastFileFilterPeek = class(TsPanel)
  private
    FOnRestore: TNotifyEvent;
    procedure PeekClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplySoftChrome;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

const
  FILTER_BAR_HEIGHT = 86;
  FILTER_BAR_DEFAULT = 88;
  FILTER_BAR_MAX_HEIGHT = 420;
  FILTER_SPLITTER_H = 5;
  FILTER_PEEK_HEIGHT = 5;
  { Filter recent max: PrefFilterRecentMax (default 20). }
  FILTER_RECENT_VISIBLE = 10;
  FILTER_RECENT_DISPLAY_MAX = 72;
  FILTER_RECENT_CMB_H = 24;
  FILTER_RECENT_INI_SECTION = 'FilterRecentPatterns';

implementation

uses
  uI18n, uUserPrefs, uMruFind, UnitPopupMruList;

const
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

{ TFastFileFilterBar }

constructor TFastFileFilterBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBuilt := False;
  FSuppressRecentChange := False;
  FRecentExpanded := False;
  FExpandingMore := False;
  FFindActive := False;
  FActivatingFind := False;
  FFindNeedle := '';
  FFindImages := nil;
  FFindImageIndex := -1;
  FFloating := False;
  FHeaderDown := False;
  FIniPath := '';
  FRecent := TStringList.Create;
  FRecent.StrictDelimiter := True;
  BevelOuter := bvNone;
  Height := FfPx(FILTER_BAR_HEIGHT);
  Constraints.MinHeight := FfPx(FILTER_BAR_HEIGHT);
  Constraints.MaxHeight := FfPx(FILTER_BAR_MAX_HEIGHT);
  Align := alTop;
  Visible := False;
  ParentBackground := False;
  ParentColor := False;
end;

destructor TFastFileFilterBar.Destroy;
begin
  try
    SaveRecent;
  except
  end;
  FreeAndNil(FRecent);
  inherited Destroy;
end;

procedure TFastFileFilterBar.EnsureBuilt;
begin
  if FBuilt then Exit;
  if not Assigned(Parent) then Exit;
  BuildChrome;
  ApplySoftChrome;
  ApplyCaptions;
  LoadRecent;
end;

procedure TFastFileFilterBar.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(AParent) then
    EnsureBuilt;
end;

procedure TFastFileFilterBar.SetIniPath(const APath: string);
begin
  FIniPath := APath;
  if FBuilt then
    LoadRecent;
end;

procedure TFastFileFilterBar.ForceColor(APnl: TsPanel; AColor: TColor);
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

procedure TFastFileFilterBar.BuildChrome;
var
  UiFont: string;
begin
  if FBuilt then Exit;
  UiFont := PreferUiFont;

  FAccent := TsPanel.Create(Self);
  FAccent.Parent := Self;
  FAccent.Align := alLeft;
  FAccent.Width := CAccentW;
  FAccent.BevelOuter := bvNone;

  FBody := TsPanel.Create(Self);
  FBody.Parent := Self;
  FBody.Align := alClient;
  FBody.BevelOuter := bvNone;
  FBody.OnResize := BodyResize;
  FBody.Padding.Left := 8;
  FBody.Padding.Right := 8;
  FBody.Padding.Top := 6;
  FBody.Padding.Bottom := 6;

  FTitleHit := TsPanel.Create(Self);
  FTitleHit.Parent := FBody;
  FTitleHit.BevelOuter := bvNone;
  FTitleHit.Caption := '';
  FTitleHit.ParentBackground := True;

  FLblTitle := TsLabel.Create(Self);
  FLblTitle.Parent := FBody;
  FLblTitle.ParentFont := False;
  FLblTitle.Font.Name := UiFont;
  FLblTitle.Font.Size := 10;
  FLblTitle.Font.Style := [fsBold];
  FLblTitle.Font.Color := CTitle;
  FLblTitle.Transparent := True;
  FLblTitle.Caption := 'Filter / Grep';
  FLblTitle.AutoSize := False;
  ApplyTitleDragChrome;

  FLblMode := TsLabel.Create(Self);
  FLblMode.Parent := FBody;
  FLblMode.ParentFont := False;
  FLblMode.Font.Name := UiFont;
  FLblMode.Font.Size := 8;
  FLblMode.Font.Color := CMuted;
  FLblMode.Transparent := True;
  FLblMode.Caption := '';

  FLblRecent := TsLabel.Create(Self);
  FLblRecent.Parent := FBody;
  FLblRecent.ParentFont := False;
  FLblRecent.Font.Name := UiFont;
  FLblRecent.Font.Size := 8;
  FLblRecent.Font.Color := CMuted;
  FLblRecent.Transparent := True;
  FLblRecent.Caption := '';
  FLblRecent.AutoSize := False;

  { MRU dropdown — same pattern as Assistant CmbRecentQuestions. }
  FCmbRecent := TComboBox.Create(Self);
  FCmbRecent.Parent := FBody;
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

  FBtnRecentFind := TsSpeedButton.Create(Self);
  FBtnRecentFind.Parent := FBody;
  FBtnRecentFind.Flat := True;
  FBtnRecentFind.ShowCaption := False;
  FBtnRecentFind.ShowHint := True;
  FBtnRecentFind.ParentShowHint := False;
  FBtnRecentFind.Width := MRU_FIND_BTN_W;
  FBtnRecentFind.Height := FILTER_RECENT_CMB_H;
  try
    FBtnRecentFind.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
  FBtnRecentFind.Visible := False;
  FBtnRecentFind.OnClick := CmbRecentFindClick;

  FEdtRecentFind := TEdit.Create(Self);
  FEdtRecentFind.Parent := FBody;
  FEdtRecentFind.ParentFont := False;
  FEdtRecentFind.Font.Name := UiFont;
  FEdtRecentFind.Font.Size := 9;
  FEdtRecentFind.ParentColor := False;
  FEdtRecentFind.Color := CWindow;
  FEdtRecentFind.Visible := False;
  FEdtRecentFind.OnChange := EdtRecentFindChange;
  FEdtRecentFind.OnKeyDown := EdtRecentFindKeyDown;

  FBtnRecentFindClear := TsSpeedButton.Create(Self);
  FBtnRecentFindClear.Parent := FBody;
  FBtnRecentFindClear.Flat := True;
  FBtnRecentFindClear.ShowCaption := True;
  FBtnRecentFindClear.Caption := #$00D7;
  FBtnRecentFindClear.ShowHint := True;
  FBtnRecentFindClear.ParentShowHint := False;
  FBtnRecentFindClear.Width := MRU_FIND_BTN_W;
  FBtnRecentFindClear.Height := FILTER_RECENT_CMB_H;
  FBtnRecentFindClear.Visible := False;
  try
    FBtnRecentFindClear.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
  FBtnRecentFindClear.OnClick := BtnRecentFindClearClick;

  FEditShell := TsPanel.Create(Self);
  FEditShell.Parent := FBody;
  FEditShell.BevelOuter := bvNone;
  FEditShell.Height := 28;

  FEditFrame := TsPanel.Create(Self);
  FEditFrame.Parent := FEditShell;
  FEditFrame.Align := alClient;
  FEditFrame.BevelOuter := bvNone;
  FEditFrame.Padding.Left := 6;
  FEditFrame.Padding.Top := 3;
  FEditFrame.Padding.Right := 6;
  FEditFrame.Padding.Bottom := 3;

  FEdtPattern := TEdit.Create(Self);
  FEdtPattern.Parent := FEditFrame;
  FEdtPattern.Align := alClient;
  FEdtPattern.BorderStyle := bsNone;
  FEdtPattern.ParentFont := False;
  FEdtPattern.Font.Name := UiFont;
  FEdtPattern.Font.Size := 10;
  FEdtPattern.Font.Color := CTitle;
  FEdtPattern.ParentColor := False;
  FEdtPattern.Color := CWindow;
  FEdtPattern.OnKeyDown := EdtPatternKeyDown;
  FEdtPattern.OnKeyPress := EdtPatternKeyPress;
  FEdtPattern.OnChange := EdtPatternChange;

  FLblStatus := TsLabel.Create(Self);
  FLblStatus.Parent := FBody;
  FLblStatus.ParentFont := False;
  FLblStatus.Font.Name := UiFont;
  FLblStatus.Font.Size := 8;
  FLblStatus.Font.Color := CStatusIdle;
  FLblStatus.Transparent := True;
  FLblStatus.Caption := '';
  FLblStatus.ShowHint := True;

  FBtnApply := TsButton.Create(Self);
  FBtnApply.Parent := FBody;
  FBtnApply.ParentFont := False;
  FBtnApply.Font.Name := UiFont;
  FBtnApply.Font.Size := 9;
  FBtnApply.Font.Style := [fsBold];
  FBtnApply.Height := 26;
  FBtnApply.Width := 78;
  FBtnApply.Default := True;
  FBtnApply.OnClick := BtnApplyClick;

  FBtnContinue := TsButton.Create(Self);
  FBtnContinue.Parent := FBody;
  FBtnContinue.ParentFont := False;
  FBtnContinue.Font.Name := UiFont;
  FBtnContinue.Font.Size := 9;
  FBtnContinue.Height := 26;
  FBtnContinue.Width := 88;
  FBtnContinue.OnClick := BtnContinueClick;
  FBtnContinue.Enabled := False;

  FBtnExport := TsButton.Create(Self);
  FBtnExport.Parent := FBody;
  FBtnExport.ParentFont := False;
  FBtnExport.Font.Name := UiFont;
  FBtnExport.Font.Size := 9;
  FBtnExport.Height := 26;
  FBtnExport.Width := 88;
  FBtnExport.Visible := False;
  FBtnExport.OnClick := BtnExportClick;

  FBtnCopy := TsButton.Create(Self);
  FBtnCopy.Parent := FBody;
  FBtnCopy.ParentFont := False;
  FBtnCopy.Font.Name := UiFont;
  FBtnCopy.Font.Size := 9;
  FBtnCopy.Height := 26;
  FBtnCopy.Width := 88;
  FBtnCopy.Visible := False;
  FBtnCopy.OnClick := BtnCopyClick;

  FBtnClear := TsButton.Create(Self);
  FBtnClear.Parent := FBody;
  FBtnClear.ParentFont := False;
  FBtnClear.Font.Name := UiFont;
  FBtnClear.Font.Size := 9;
  FBtnClear.Height := 26;
  FBtnClear.Width := 72;
  FBtnClear.OnClick := BtnClearClick;

  FBtnHide := TsButton.Create(Self);
  FBtnHide.Parent := FBody;
  FBtnHide.ParentFont := False;
  FBtnHide.Font.Name := UiFont;
  FBtnHide.Font.Size := 12;
  FBtnHide.Font.Style := [];
  FBtnHide.Font.Color := CMuted;
  FBtnHide.Height := 26;
  FBtnHide.Width := 28;
  FBtnHide.Caption := #$00D7; { × — same chrome as Assistente IA }
  FBtnHide.Hint := TrText('Close');
  FBtnHide.ShowHint := True;
  FBtnHide.TabStop := False;
  FBtnHide.OnClick := BtnHideClick;
  try
    FBtnHide.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;

  FBtnFloat := TsButton.Create(Self);
  FBtnFloat.Parent := FBody;
  FBtnFloat.ParentFont := False;
  FBtnFloat.Font.Name := UiFont;
  FBtnFloat.Font.Size := 10;
  FBtnFloat.Font.Color := CMuted;
  FBtnFloat.Height := 26;
  FBtnFloat.Width := 28;
  FBtnFloat.OnClick := BtnFloatClick;
  try
    FBtnFloat.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;

  FPopDock := TPopupMenu.Create(Self);
  FMiFloat := TMenuItem.Create(FPopDock);
  FMiFloat.OnClick := BtnFloatClick;
  FPopDock.Items.Add(FMiFloat);
  PopupMenu := FPopDock;
  FBody.PopupMenu := FPopDock;

  ApplyRecentFindGlyphs;
  FBuilt := True;
  LayoutChrome;
end;

procedure TFastFileFilterBar.LayoutChrome;
var
  X, EditTop, RecentTop, EditW, RightEdge, EditLeft, StatusW: Integer;
  BtnGap, Tw, ModeH, RecentH, BtnH: Integer;
  ComboW: Integer;
  MeasureCanvas: TControlCanvas;

  function TextW(AFont: TFont; const AText: string): Integer;
  begin
    MeasureCanvas.Font.Assign(AFont);
    Result := MeasureCanvas.TextWidth(AText);
  end;

  function TextH(AFont: TFont): Integer;
  begin
    MeasureCanvas.Font.Assign(AFont);
    Result := MeasureCanvas.TextHeight('Áy');
    if Result < 12 then
      Result := 12;
  end;

  procedure SizeBtn(ABtn: TsButton; AMinW: Integer);
  var
    W: Integer;
  begin
    if not Assigned(ABtn) then Exit;
    W := TextW(ABtn.Font, ABtn.Caption) + 22;
    if W < FfPx(AMinW) then
      W := FfPx(AMinW);
    if W > FfPx(130) then
      W := FfPx(130);
    ABtn.Width := W;
    ABtn.Height := BtnH;
  end;

begin
  if not FBuilt or not Assigned(FBody) then Exit;
  if Self.Height < FfPx(FILTER_BAR_HEIGHT) then
    Self.Height := FfPx(FILTER_BAR_HEIGHT);

  BtnGap := 5;
  BtnH := FfPx(28);
  RightEdge := FBody.ClientWidth - FBody.Padding.Right;
  if RightEdge < 40 then Exit;

  MeasureCanvas := TControlCanvas.Create;
  try
    MeasureCanvas.Control := Self;

    ModeH := TextH(FLblMode.Font) + 2;
    RecentH := TextH(FLblRecent.Font) + 1;

    SizeBtn(FBtnApply, 72);
    SizeBtn(FBtnContinue, 80);
    SizeBtn(FBtnExport, 80);
    SizeBtn(FBtnCopy, 72);
    SizeBtn(FBtnClear, 68);
    { Close (×) is fixed square like Assistente IA — not SizeBtn text width. }
    FBtnHide.Width := FfPx(28);
    FBtnHide.Height := BtnH;
    FBtnHide.Caption := #$00D7;
    if Assigned(FBtnFloat) then
    begin
      FBtnFloat.Width := FfPx(28);
      FBtnFloat.Height := BtnH;
    end;

    X := FBody.Padding.Left;
    { No reserved title column — recent + pattern start at the left. }
    if Assigned(FLblTitle) then
      FLblTitle.Visible := False;
    if Assigned(FTitleHit) then
    begin
      FTitleHit.Visible := False;
      FTitleHit.SetBounds(0, 0, 0, 0);
    end;
    if Assigned(FLblMode) then
    begin
      FLblMode.AutoSize := False;
      FLblMode.Visible := Trim(FLblMode.Caption) <> '';
    end;

    EditLeft := X;
    EditW := RightEdge - EditLeft;
    if EditW < 120 then
      EditW := 120;

    { Label + MRU combo. Search lives inside the dropdown (Mais ferramentas). }
    FLblRecent.AutoSize := False;
    Tw := TextW(FLblRecent.Font, FLblRecent.Caption) + 4;
    FLblRecent.SetBounds(EditLeft, 2, Tw, RecentH);
    if Assigned(FLblMode) and FLblMode.Visible then
      FLblMode.SetBounds(EditLeft + Tw + 8, 2,
        TextW(FLblMode.Font, FLblMode.Caption) + 8, ModeH);
    RecentTop := 2 + RecentH + 2;
    ComboW := EditW;
    if ComboW < 80 then
      ComboW := 80;
    if Assigned(FCmbRecent) then
      FCmbRecent.SetBounds(EditLeft, RecentTop, ComboW, FILTER_RECENT_CMB_H);
    if Assigned(FEdtRecentFind) then
      FEdtRecentFind.Visible := False;
    if Assigned(FBtnRecentFindClear) then
      FBtnRecentFindClear.Visible := False;
    if Assigned(FBtnRecentFind) then
      FBtnRecentFind.Visible := False;

    EditTop := RecentTop + FILTER_RECENT_CMB_H + 6;
    { × close outermost (right), then float — same corner role as Assistente. }
    Dec(RightEdge, FBtnHide.Width);
    FBtnHide.SetBounds(RightEdge, EditTop, FBtnHide.Width, FBtnHide.Height);
    Dec(RightEdge, BtnGap);
    if Assigned(FBtnFloat) then
    begin
      Dec(RightEdge, FBtnFloat.Width);
      FBtnFloat.SetBounds(RightEdge, EditTop, FBtnFloat.Width, FBtnFloat.Height);
      Dec(RightEdge, BtnGap);
    end;
    Dec(RightEdge, BtnGap + FBtnClear.Width);
    FBtnClear.SetBounds(RightEdge, EditTop, FBtnClear.Width, FBtnClear.Height);
    if Assigned(FBtnCopy) and FBtnCopy.Visible then
    begin
      Dec(RightEdge, BtnGap + FBtnCopy.Width);
      FBtnCopy.SetBounds(RightEdge, EditTop, FBtnCopy.Width, FBtnCopy.Height);
    end;
    if Assigned(FBtnExport) and FBtnExport.Visible then
    begin
      Dec(RightEdge, BtnGap + FBtnExport.Width);
      FBtnExport.SetBounds(RightEdge, EditTop, FBtnExport.Width, FBtnExport.Height);
    end;
    Dec(RightEdge, BtnGap + FBtnContinue.Width);
    FBtnContinue.SetBounds(RightEdge, EditTop, FBtnContinue.Width, FBtnContinue.Height);
    Dec(RightEdge, BtnGap + FBtnApply.Width);
    FBtnApply.SetBounds(RightEdge, EditTop, FBtnApply.Width, FBtnApply.Height);
    Dec(RightEdge, BtnGap);

    EditW := RightEdge - EditLeft;
    if EditW < 120 then
      EditW := 120;
    FEditShell.SetBounds(EditLeft, EditTop, EditW, BtnH);

    StatusW := FBody.ClientWidth - FBody.Padding.Right - EditLeft;
    if StatusW < 80 then
      StatusW := 80;
    FLblStatus.AutoSize := False;
    FLblStatus.SetBounds(EditLeft, EditTop + BtnH + 4, StatusW, ModeH);
    FLblStatus.Hint := FLblStatus.Caption;
  finally
    MeasureCanvas.Free;
  end;
end;

procedure TFastFileFilterBar.BodyResize(Sender: TObject);
begin
  LayoutChrome;
end;

procedure TFastFileFilterBar.Resize;
begin
  inherited;
  LayoutChrome;
end;

procedure TFastFileFilterBar.ApplySoftChrome;
var
  UiFont: string;
begin
  if not FBuilt then Exit;
  UiFont := PreferUiFont;
  Font.Name := UiFont;
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  ParentBackground := False;
  ParentColor := False;
  Color := CSurface;
  ForceColor(Self, CSurface);
  ForceColor(FAccent, CAccent);
  if Assigned(FAccent) then
    FAccent.Width := CAccentW;
  ForceColor(FBody, CSurface);
  ForceColor(FEditShell, CBorder);
  ForceColor(FEditFrame, CWindow);
  if Assigned(FLblTitle) then
  begin
    FLblTitle.Font.Name := UiFont;
    FLblTitle.Font.Color := CTitle;
    FLblTitle.Font.Style := [fsBold];
  end;
  if Assigned(FLblMode) then
  begin
    FLblMode.Font.Name := UiFont;
    FLblMode.Font.Color := CMuted;
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
    FCmbRecent.Font.Color := CTitle;
  end;
  if Assigned(FEdtRecentFind) then
  begin
    FEdtRecentFind.ParentColor := False;
    FEdtRecentFind.Color := CWindow;
    FEdtRecentFind.ParentFont := False;
    FEdtRecentFind.Font.Name := UiFont;
    FEdtRecentFind.Font.Size := 9;
    FEdtRecentFind.Font.Color := CTitle;
  end;
  if Assigned(FEdtPattern) then
  begin
    FEdtPattern.ParentColor := False;
    FEdtPattern.Color := CWindow;
    FEdtPattern.ParentFont := False;
    FEdtPattern.Font.Name := UiFont;
    FEdtPattern.Font.Size := 10;
    FEdtPattern.Font.Color := CTitle;
  end;
  if Assigned(FBtnApply) then
  begin
    FBtnApply.ParentFont := False;
    FBtnApply.Font.Name := UiFont;
    FBtnApply.Font.Size := 9;
    FBtnApply.Font.Style := [fsBold];
    FBtnApply.Font.Color := CTitle;
  end;
  LayoutChrome;
end;

procedure TFastFileFilterBar.ApplyCaptions;
begin
  if not FBuilt then Exit;
  FLblTitle.Caption := TrText('Filter / Grep');
  if Assigned(FLblRecent) then
    FLblRecent.Caption := TrText('FilterBar.Recent');
  FBtnApply.Caption := TrText('FilterBar.Apply');
  FBtnContinue.Caption := TrText('FilterBar.Continue');
  if Assigned(FBtnExport) then
    FBtnExport.Caption := TrText('FilterBar.Export');
  if Assigned(FBtnCopy) then
    FBtnCopy.Caption := TrText('FilterBar.Copy');
  FBtnClear.Caption := TrText('FilterBar.Clear');
  FBtnHide.Caption := #$00D7; { × }
  SyncFloatAction;
  ApplyTitleDragChrome;
  FBtnApply.Hint := TrText('FilterBar.ApplyHint');
  FBtnContinue.Hint := TrText('FilterBar.ContinueHint');
  if Assigned(FBtnExport) then
  begin
    FBtnExport.Hint := TrText('FilterBar.ExportHint');
    FBtnExport.ShowHint := True;
  end;
  if Assigned(FBtnCopy) then
  begin
    FBtnCopy.Hint := TrText('FilterBar.CopyHint');
    FBtnCopy.ShowHint := True;
  end;
  FBtnClear.Hint := TrText('FilterBar.ClearHint');
  FBtnHide.Hint := TrText('Close');
  FBtnApply.ShowHint := True;
  FBtnContinue.ShowHint := True;
  FBtnClear.ShowHint := True;
  FBtnHide.ShowHint := True;
  if Assigned(FCmbRecent) then
  begin
    FCmbRecent.Hint := TrText('FilterBar.RecentHint');
    FCmbRecent.ShowHint := True;
  end;
  if Assigned(FBtnRecentFind) then
  begin
    FBtnRecentFind.Hint := TrText('MRU.FindHint');
    FBtnRecentFind.ShowHint := True;
  end;
  if Assigned(FEdtRecentFind) then
  begin
    FEdtRecentFind.Hint := TrText('MRU.FindHint');
    FEdtRecentFind.ShowHint := True;
  end;
  if Assigned(FBtnRecentFindClear) then
  begin
    FBtnRecentFindClear.Hint := TrText('MRU.ClearFind');
    FBtnRecentFindClear.ShowHint := True;
    FBtnRecentFindClear.Caption := #$00D7;
  end;
  if Assigned(FEdtPattern) then
  begin
    FEdtPattern.TextHint := TrText('FilterBar.PatternHint');
    FEdtPattern.Hint := TrText('FilterBar.PatternHint');
    FEdtPattern.ShowHint := True;
  end;
  RefreshRecentCombo;
  LayoutChrome;
end;

procedure TFastFileFilterBar.FocusPattern;
begin
  EnsureBuilt;
  if not Assigned(FEdtPattern) then Exit;
  if not Visible then Exit;
  if not HandleAllocated then Exit;
  if FEdtPattern.CanFocus then
  begin
    FEdtPattern.SetFocus;
    FEdtPattern.SelectAll;
  end;
end;

function TFastFileFilterBar.GetPattern: string;
begin
  if Assigned(FEdtPattern) then
    Result := Trim(FEdtPattern.Text)
  else
    Result := '';
end;

procedure TFastFileFilterBar.SetPattern(const AText: string);
begin
  if not Assigned(FEdtPattern) then Exit;
  FSuppressRecentChange := True;
  try
    FEdtPattern.Text := AText;
    if Assigned(FCmbRecent) then
      FCmbRecent.ItemIndex := -1;
  finally
    FSuppressRecentChange := False;
  end;
end;

procedure TFastFileFilterBar.SetModeHint(const AModeText: string);
begin
  if Assigned(FLblMode) then
  begin
    FLblMode.Caption := AModeText;
    LayoutChrome;
  end;
end;

procedure TFastFileFilterBar.SetStatus(const AStatusText: string; AActive, APartial, ABusy: Boolean);
begin
  if not Assigned(FLblStatus) then Exit;
  FLblStatus.Caption := AStatusText;
  FLblStatus.Hint := AStatusText;
  if ABusy then
    FLblStatus.Font.Color := CStatusBusy
  else if AActive then
    FLblStatus.Font.Color := CStatusOk
  else
    FLblStatus.Font.Color := CStatusIdle;
  SetContinueEnabled(AActive and APartial and (not ABusy));
  LayoutChrome;
end;

procedure TFastFileFilterBar.SetContinueEnabled(AEnabled: Boolean);
begin
  if Assigned(FBtnContinue) then
    FBtnContinue.Enabled := AEnabled;
end;

procedure TFastFileFilterBar.SetResultsActionsVisible(AVisible: Boolean);
begin
  if Assigned(FBtnExport) then
    FBtnExport.Visible := AVisible;
  if Assigned(FBtnCopy) then
    FBtnCopy.Visible := AVisible;
  LayoutChrome;
end;

function TFastFileFilterBar.PatternEditFocused: Boolean;
begin
  Result := Assigned(FEdtPattern) and FEdtPattern.HandleAllocated and FEdtPattern.Focused;
end;

function TFastFileFilterBar.FormatRecentDisplay(const APattern: string): string;
var
  OneLine: string;
begin
  OneLine := StringReplace(Trim(APattern), #13#10, ' ', [rfReplaceAll]);
  OneLine := StringReplace(OneLine, #10, ' ', [rfReplaceAll]);
  OneLine := StringReplace(OneLine, #13, ' ', [rfReplaceAll]);
  while Pos('  ', OneLine) > 0 do
    OneLine := StringReplace(OneLine, '  ', ' ', [rfReplaceAll]);
  if Length(OneLine) > FILTER_RECENT_DISPLAY_MAX then
    Result := Copy(OneLine, 1, FILTER_RECENT_DISPLAY_MAX - 3) + '...'
  else
    Result := OneLine;
end;

function TFastFileFilterBar.EncodeRecentForIni(const APattern: string): string;
begin
  Result := StringReplace(APattern, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

function TFastFileFilterBar.DecodeRecentFromIni(const AEncoded: string): string;
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

procedure TFastFileFilterBar.DeduplicateRecent;
var
  i, j: Integer;
  A, B: string;
begin
  if not Assigned(FRecent) then Exit;
  i := 0;
  while i < FRecent.Count do
  begin
    A := AnsiLowerCase(Trim(FRecent[i]));
    j := i + 1;
    while j < FRecent.Count do
    begin
      B := AnsiLowerCase(Trim(FRecent[j]));
      if (A <> '') and (A = B) then
        FRecent.Delete(j)
      else
        Inc(j);
    end;
    Inc(i);
  end;
  while FRecent.Count > PrefFilterRecentMax do
    FRecent.Delete(FRecent.Count - 1);
end;

procedure TFastFileFilterBar.RefreshRecentCombo;
var
  EmptyHint: string;
begin
  if not Assigned(FCmbRecent) or (not Assigned(FRecent)) then Exit;
  FSuppressRecentChange := True;
  try
    FCmbRecent.Items.BeginUpdate;
    try
      FCmbRecent.Items.Clear;
      if FRecent.Count = 0 then
      begin
        EmptyHint := TrText('FilterBar.RecentEmpty');
        FCmbRecent.Items.Add(EmptyHint);
        FCmbRecent.ItemIndex := 0;
        FCmbRecent.Enabled := False;
        FCmbRecent.DropDownCount := 1;
        FRecentExpanded := False;
        FFindActive := False;
      end
      else
      begin
        FCmbRecent.Items.Add('');
        FCmbRecent.ItemIndex := -1;
        FCmbRecent.Enabled := True;
        FCmbRecent.DropDownCount := 1;
      end;
    finally
      FCmbRecent.Items.EndUpdate;
    end;
  finally
    FSuppressRecentChange := False;
  end;
end;

procedure TFastFileFilterBar.LoadRecent;
var
  Ini: TIniFile;
  n, i: Integer;
  S: string;
begin
  if not Assigned(FRecent) then Exit;
  FRecent.Clear;
  if FIniPath = '' then
  begin
    RefreshRecentCombo;
    Exit;
  end;
  Ini := TIniFile.Create(FIniPath);
  try
    n := Ini.ReadInteger(FILTER_RECENT_INI_SECTION, 'Count', 0);
    if n > PrefFilterRecentMax then
      n := PrefFilterRecentMax;
    for i := 0 to n - 1 do
    begin
      S := DecodeRecentFromIni(
        Ini.ReadString(FILTER_RECENT_INI_SECTION, 'P' + IntToStr(i), ''));
      if Trim(S) <> '' then
        FRecent.Add(S);
    end;
  finally
    Ini.Free;
  end;
  DeduplicateRecent;
  FRecentExpanded := False;
  RefreshRecentCombo;
  SaveRecent;
end;

procedure TFastFileFilterBar.SaveRecent;
var
  Ini: TIniFile;
  i, n: Integer;
begin
  if (FIniPath = '') or (not Assigned(FRecent)) then Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    n := FRecent.Count;
    if n > PrefFilterRecentMax then
      n := PrefFilterRecentMax;
    Ini.WriteInteger(FILTER_RECENT_INI_SECTION, 'Count', n);
    for i := 0 to PrefFilterRecentMax - 1 do
    begin
      if i < n then
        Ini.WriteString(FILTER_RECENT_INI_SECTION, 'P' + IntToStr(i),
          EncodeRecentForIni(FRecent[i]))
      else
        Ini.DeleteKey(FILTER_RECENT_INI_SECTION, 'P' + IntToStr(i));
    end;
  finally
    Ini.Free;
  end;
end;

procedure TFastFileFilterBar.RememberPattern(const APattern: string);
var
  S, Key: string;
  i: Integer;
begin
  S := Trim(APattern);
  if (S = '') or (not Assigned(FRecent)) then Exit;
  Key := AnsiLowerCase(S);
  for i := FRecent.Count - 1 downto 0 do
    if AnsiLowerCase(Trim(FRecent[i])) = Key then
      FRecent.Delete(i);
  FRecent.Insert(0, S);
  while FRecent.Count > PrefFilterRecentMax do
    FRecent.Delete(FRecent.Count - 1);
  FRecentExpanded := False;
  DeactivateRecentFind;
  RefreshRecentCombo;
  SaveRecent;
end;

procedure TFastFileFilterBar.BtnApplyClick(Sender: TObject);
begin
  if Trim(GetPattern) = '' then
  begin
    if Assigned(FOnClear) then
      FOnClear(Self);
    Exit;
  end;
  if Assigned(FOnApply) then
    FOnApply(Self, GetPattern);
end;

procedure TFastFileFilterBar.EdtPatternChange(Sender: TObject);
begin
  if FSuppressRecentChange then Exit;
  if Trim(GetPattern) <> '' then Exit;
  if Assigned(FOnClear) then
    FOnClear(Self);
end;

procedure TFastFileFilterBar.BtnClearClick(Sender: TObject);
begin
  if Assigned(FOnClear) then
    FOnClear(Self);
end;

procedure TFastFileFilterBar.BtnContinueClick(Sender: TObject);
begin
  if Assigned(FOnContinue) then
    FOnContinue(Self);
end;

procedure TFastFileFilterBar.BtnExportClick(Sender: TObject);
begin
  if Assigned(FOnExport) then
    FOnExport(Self);
end;

procedure TFastFileFilterBar.BtnCopyClick(Sender: TObject);
begin
  if Assigned(FOnCopy) then
    FOnCopy(Self);
end;

procedure TFastFileFilterBar.BtnHideClick(Sender: TObject);
begin
  if Assigned(FOnHide) then
    FOnHide(Self);
end;

procedure TFastFileFilterBar.BtnFloatClick(Sender: TObject);
begin
  if Assigned(FOnFloat) then
    FOnFloat(Self);
end;

procedure TFastFileFilterBar.SyncFloatAction;
begin
  if Assigned(FBtnFloat) then
  begin
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
  if Assigned(FMiFloat) then
  begin
    if FFloating then
      FMiFloat.Caption := TrText('Panel.Dock')
    else
      FMiFloat.Caption := TrText('Panel.RestoreFloat');
  end;
end;

procedure TFastFileFilterBar.ApplyTitleDragChrome;
var
  HintTxt: string;
begin
  if FFloating then
    HintTxt := TrText('Panel.DragDockHint')
  else
    HintTxt := TrText('Panel.DragUndockHint');
  if Assigned(FTitleHit) then
  begin
    FTitleHit.Cursor := crSizeAll;
    FTitleHit.ShowHint := True;
    FTitleHit.Hint := HintTxt;
    FTitleHit.OnMouseDown := TitleMouseDown;
    FTitleHit.OnMouseMove := TitleMouseMove;
    FTitleHit.OnMouseUp := TitleMouseUp;
    FTitleHit.OnDblClick := TitleDblClick;
  end;
  if Assigned(FLblTitle) then
  begin
    FLblTitle.Cursor := crSizeAll;
    FLblTitle.ShowHint := True;
    FLblTitle.Hint := HintTxt;
    FLblTitle.OnMouseDown := TitleMouseDown;
    FLblTitle.OnMouseMove := TitleMouseMove;
    FLblTitle.OnMouseUp := TitleMouseUp;
    FLblTitle.OnDblClick := TitleDblClick;
  end;
  if Assigned(FLblMode) then
  begin
    FLblMode.Cursor := crSizeAll;
    FLblMode.OnMouseDown := TitleMouseDown;
    FLblMode.OnMouseMove := TitleMouseMove;
    FLblMode.OnMouseUp := TitleMouseUp;
  end;
  if Assigned(FAccent) then
  begin
    FAccent.Cursor := crSizeAll;
    FAccent.OnMouseDown := TitleMouseDown;
    FAccent.OnMouseMove := TitleMouseMove;
    FAccent.OnMouseUp := TitleMouseUp;
  end;
  AttachPanelDrag(Self, TitleMouseDown, TitleMouseMove, TitleMouseUp,
    TitleDblClick, HintTxt);
end;

procedure TFastFileFilterBar.TitleDblClick(Sender: TObject);
begin
  if FFloating and Assigned(FOnFloat) then
    FOnFloat(Self);
end;

procedure TFastFileFilterBar.TitleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FHeaderDown := True;
  FHeaderPt := Point(X, Y);
  if Sender is TControl then
    SetCaptureControl(TControl(Sender));
end;

procedure TFastFileFilterBar.TitleMouseMove(Sender: TObject; Shift: TShiftState;
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

procedure TFastFileFilterBar.TitleMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FHeaderDown := False;
  SetCaptureControl(nil);
end;

procedure TFastFileFilterBar.SetFloatingLook(AFloating: Boolean);
begin
  FFloating := AFloating;
  ApplyCaptions;
end;

procedure TFastFileFilterBar.RelayoutAfterDock;
begin
  Align := alTop;
  Constraints.MinHeight := FfPx(FILTER_BAR_HEIGHT);
  Constraints.MaxHeight := FfPx(FILTER_BAR_MAX_HEIGHT);
  Height := FfPx(FILTER_BAR_DEFAULT);
  ApplySoftChrome;
  LayoutChrome;
end;

procedure TFastFileFilterBar.CMDialogKey(var Msg: TCMDialogKey);
begin
  if (Msg.CharCode = VK_RETURN) and PatternEditFocused then
  begin
    BtnApplyClick(Self);
    Msg.Result := 1;
    Exit;
  end;
  inherited;
end;

procedure TFastFileFilterBar.EdtPatternKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    Key := 0;
    BtnApplyClick(Self);
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    BtnHideClick(Self);
  end;
end;

procedure TFastFileFilterBar.EdtPatternKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    BtnApplyClick(Self);
  end;
end;

procedure TFastFileFilterBar.CmbRecentChange(Sender: TObject);
begin
  { Picks come from the in-popup list, not the native combo. }
end;

procedure TFastFileFilterBar.CmbRecentCloseUp(Sender: TObject);
begin
  FExpandingMore := False;
  FActivatingFind := False;
end;

procedure TFastFileFilterBar.CmbRecentDropDown(Sender: TObject);
begin
  if Assigned(FCmbRecent) then
    FCmbRecent.DroppedDown := False;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  PostMessage(Handle, WM_APP + 64, 0, 0);
end;

procedure TFastFileFilterBar.WMFilterMruPopup(var Msg: TMessage);
var
  P: TPoint;
  W: Integer;
  CR: TRect;
begin
  if Assigned(FCmbRecent) then
    FCmbRecent.DroppedDown := False;
  if (GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0) then
  begin
    PostMessage(Handle, WM_APP + 64, 0, 0);
    Exit;
  end;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if not Assigned(FRecent) or (FRecent.Count = 0) then Exit;
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
  ShowMruListPopup(Self, TrText('FilterBar.Recent'),
    MruMoreCaption('FilterBar.RecentMore'), FRecent, W, P, FilterMruPick,
    TrText('FilterBar.RecentMoreHint'), nil, nil, FCmbRecent, FilterMruClearAll);
end;

procedure TFastFileFilterBar.FilterMruPick(Sender: TObject; const AValue: string;
  AIndex: Integer);
begin
  if Assigned(FEdtPattern) then
  begin
    FEdtPattern.Text := AValue;
    FocusPattern;
  end;
end;

procedure TFastFileFilterBar.FilterMruClearAll(Sender: TObject);
begin
  if not Assigned(FRecent) then Exit;
  FRecent.Clear;
  FRecentExpanded := False;
  SaveRecent;
  RefreshRecentCombo;
end;

procedure TFastFileFilterBar.WMFilterRecentExpand(var Msg: TMessage);
begin
  if Assigned(FCmbRecent) and FCmbRecent.Enabled then
    FCmbRecent.DroppedDown := True;
end;

procedure TFastFileFilterBar.WMFilterRecentCollapse(var Msg: TMessage);
begin
  if not FRecentExpanded then Exit;
  FRecentExpanded := False;
  RefreshRecentCombo;
end;

procedure TFastFileFilterBar.WMFilterRecentFind(var Msg: TMessage);
begin
  if Assigned(FEdtRecentFind) and FEdtRecentFind.Visible and FEdtRecentFind.CanFocus then
    FEdtRecentFind.SetFocus
  else if Assigned(FCmbRecent) and FCmbRecent.Enabled then
    FCmbRecent.DroppedDown := True;
end;

procedure TFastFileFilterBar.ApplyRecentFindGlyphs;
begin
  if not Assigned(FBtnRecentFind) then Exit;
  if Assigned(FFindImages) and (FFindImageIndex >= 0) then
  begin
    FBtnRecentFind.Images := FFindImages;
    FBtnRecentFind.ImageIndex := FFindImageIndex;
    FBtnRecentFind.ShowCaption := False;
    FBtnRecentFind.Caption := '';
  end
  else
  begin
    FBtnRecentFind.Images := nil;
    FBtnRecentFind.ShowCaption := True;
    FBtnRecentFind.Caption := '...';
  end;
end;

procedure TFastFileFilterBar.SetMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
begin
  FFindImages := AImages;
  FFindImageIndex := AFindIndex;
  if FBuilt then
    ApplyRecentFindGlyphs;
end;

procedure TFastFileFilterBar.ActivateRecentFind;
begin
  FActivatingFind := True;
  FFindActive := True;
  FRecentExpanded := False;
  LayoutChrome;
  RefreshRecentCombo;
  PostMessage(Handle, WM_APP + 63, 0, 0);
end;

procedure TFastFileFilterBar.DeactivateRecentFind;
begin
  if not FFindActive and (FFindNeedle = '') then Exit;
  FFindActive := False;
  FFindNeedle := '';
  if Assigned(FEdtRecentFind) then
    FEdtRecentFind.Text := '';
  LayoutChrome;
  RefreshRecentCombo;
end;

procedure TFastFileFilterBar.CmbRecentFindClick(Sender: TObject);
begin
  if FFindActive then
    DeactivateRecentFind
  else
    ActivateRecentFind;
end;

procedure TFastFileFilterBar.EdtRecentFindChange(Sender: TObject);
begin
  if not Assigned(FEdtRecentFind) then Exit;
  FFindNeedle := Trim(FEdtRecentFind.Text);
  RefreshRecentCombo;
  if Assigned(FCmbRecent) and FCmbRecent.Enabled then
    FCmbRecent.DroppedDown := True;
end;

procedure TFastFileFilterBar.EdtRecentFindKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    DeactivateRecentFind;
  end;
end;

procedure TFastFileFilterBar.BtnRecentFindClearClick(Sender: TObject);
begin
  DeactivateRecentFind;
end;

{ TFastFileFilterPeek }

constructor TFastFileFilterPeek.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Height := FILTER_PEEK_HEIGHT;
  Align := alTop;
  Visible := False;
  Cursor := crHandPoint;
  ShowHint := True;
  Hint := TrText('FilterBar.PeekHint');
  OnClick := PeekClick;
  ApplySoftChrome;
end;

procedure TFastFileFilterPeek.ApplySoftChrome;
begin
  try
    SkinData.CustomColor := True;
    SkinData.SkinSection := '';
  except
  end;
  ParentBackground := False;
  ParentColor := False;
  Color := CAccent;
  Hint := TrText('FilterBar.PeekHint');
end;

procedure TFastFileFilterPeek.PeekClick(Sender: TObject);
begin
  if Assigned(FOnRestore) then
    FOnRestore(Self);
end;

end.
