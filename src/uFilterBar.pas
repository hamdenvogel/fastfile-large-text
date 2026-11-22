unit uFilterBar;
{ Docked Filter / Grep frame: MRU dropdown (like Assistant) + pattern edit +
  Apply / Continue / Export / Copy / Clear / Close (×). }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  Menus, Buttons, IniFiles, sPanel, sLabel, sButton, sSpeedButton, ImgList,
  uFastFileFloatHost, uFastFileScale, uSearchCommands, uSoftPanelButtons;

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
    FBtnGrep, FBtnGlob, FBtnAskAI: TsButton;
    FOnCommand: TSearchCommandOpenEvent;
    FOnAskAI: TNotifyEvent;
    FBtnContinue: TsButton;
    FBtnExport: TsButton;
    FBtnCopy: TsButton;
    FBtnClear: TsButton;
    FBtnClose: TsButton;
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
    FContentHeight: Integer;
    FBtnChevron: TsSpeedButton;
    FCollapseMask: TsPanel;
    FCollapsed: Boolean;
    FOnHeaderClick: TNotifyEvent;
    procedure BuildFrame;
    procedure ChevronClick(Sender: TObject);
    procedure ForceColor(APnl: TsPanel; AColor: TColor);
    procedure LayoutFrame;
    procedure BtnApplyClick(Sender: TObject);
    procedure BtnCommandClick(Sender: TObject);
    procedure BtnAskAIClick(Sender: TObject);
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
    procedure ApplyTitleDragFrame;
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
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EnsureBuilt;
    procedure ApplyCaptions;
    procedure ApplySoftFrame;
    procedure FocusPattern;
    function PatternEditFocused: Boolean;
    function GetPattern: string;
    procedure SetPattern(const AText: string);
    procedure SetModeHint(const AModeText, AHover: string);
    procedure SetStatus(const AStatusText: string; AActive, APartial, ABusy: Boolean);
    procedure SetContinueEnabled(AEnabled: Boolean);
    procedure SetResultsActionsVisible(AVisible: Boolean);
    procedure SetIniPath(const APath: string);
    procedure SetMruFindGlyphs(AImages: TCustomImageList; AFindIndex: Integer);
    procedure RememberPattern(const APattern: string);
    procedure SetFloatingLook(AFloating: Boolean);
    procedure RelayoutAfterDock;
    { Height that fits the controls. Extra pixels below the buttons are blank. }
    function ContentHeight: Integer;
    { Height of the title row alone (collapsed accordion card). }
    function HeaderHeight: Integer;
    procedure SetCollapsed(AValue: Boolean);
    property Collapsed: Boolean read FCollapsed;
    { Docked: title clicked (not dragged) or chevron pressed. }
    property OnHeaderClick: TNotifyEvent read FOnHeaderClick write FOnHeaderClick;
    property OnTearOff: TNotifyEvent read FOnTearOff write FOnTearOff;
    property OnHeightChanged: TNotifyEvent read FOnHeightChanged write FOnHeightChanged;
    property OnApply: TFilterBarApplyEvent read FOnApply write FOnApply;
    property OnCommand: TSearchCommandOpenEvent read FOnCommand write FOnCommand;
    property OnAskAI: TNotifyEvent read FOnAskAI write FOnAskAI;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnContinue: TNotifyEvent read FOnContinue write FOnContinue;
    property OnExport: TNotifyEvent read FOnExport write FOnExport;
    property OnCopy: TNotifyEvent read FOnCopy write FOnCopy;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnFloat: TNotifyEvent read FOnFloat write FOnFloat;
  end;

  { Thin clickable strip shown when filter is active but frame is hidden. }
  TFastFileFilterPeek = class(TsPanel)
  private
    FOnRestore: TNotifyEvent;
    procedure PeekClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplySoftFrame;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
  end;

const
  FILTER_BAR_HEIGHT = 96;
  FILTER_BAR_DEFAULT = 104;
  FILTER_BAR_MAX_HEIGHT = 460;
  FILTER_SPLITTER_H = 5;
  FILTER_PEEK_HEIGHT = 5;
  { Filter recent max: PrefFilterRecentMax (default 20). }
  FILTER_RECENT_VISIBLE = 10;
  FILTER_RECENT_DISPLAY_MAX = 72;
  FILTER_RECENT_CMB_H = 24;
  FILTER_HEADER_H = 26;
  FILTER_EDIT_H = 30;
  FILTER_BTN_H = 28;
  FILTER_RECENT_INI_SECTION = 'FilterRecentPatterns';

implementation

uses
  UnConsts,
  Math, uI18n, uUserPrefs, uMruFind, UnitPopupMruList, uBidiLayout;

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
  if Screen.Fonts.IndexOf(FONT_SEGOE_UI) >= 0 then
    Result := FONT_SEGOE_UI
  else
    Result := FONT_TAHOMA;
end;

{ TFastFileFilterBar }

procedure TFastFileFilterBar.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
end;

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
  FContentHeight := 0;
  FHeaderDown := False;
  FIniPath := '';
  FRecent := TStringList.Create;
  FRecent.StrictDelimiter := True;
  BevelOuter := bvNone;
  Height := FfPx(FILTER_BAR_HEIGHT);
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
  BuildFrame;
  ApplySoftFrame;
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

procedure TFastFileFilterBar.BuildFrame;
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
  ApplyTitleDragFrame;

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
  BidiKeepLtr(FEdtPattern); { regex / glob pattern stays left-to-right }

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
  FBtnApply.Height := FfPx(36);
  FBtnApply.Width := 78;
  FBtnApply.Default := True;
  FBtnApply.OnClick := BtnApplyClick;
  StyleSoftPanelBtn(FBtnApply, UiFont, spbrPrimary);

  FBtnContinue := TsButton.Create(Self);
  FBtnContinue.Parent := FBody;
  FBtnContinue.Height := FfPx(36);
  FBtnContinue.Width := 88;
  FBtnContinue.OnClick := BtnContinueClick;
  FBtnContinue.Enabled := False;
  StyleSoftPanelBtn(FBtnContinue, UiFont, spbrAction);

  FBtnExport := TsButton.Create(Self);
  FBtnExport.Parent := FBody;
  FBtnExport.Height := FfPx(36);
  FBtnExport.Width := 88;
  FBtnExport.Visible := False;
  FBtnExport.OnClick := BtnExportClick;
  StyleSoftPanelBtn(FBtnExport, UiFont, spbrAction);

  FBtnCopy := TsButton.Create(Self);
  FBtnCopy.Parent := FBody;
  FBtnCopy.Height := FfPx(36);
  FBtnCopy.Width := 88;
  FBtnCopy.Visible := False;
  FBtnCopy.OnClick := BtnCopyClick;
  StyleSoftPanelBtn(FBtnCopy, UiFont, spbrAction);

  FBtnClear := TsButton.Create(Self);
  FBtnClear.Parent := FBody;
  FBtnClear.Height := FfPx(36);
  FBtnClear.Width := 72;
  FBtnClear.OnClick := BtnClearClick;
  StyleSoftPanelBtn(FBtnClear, UiFont, spbrQuiet);

  FBtnClose := TsButton.Create(Self);
  FBtnClose.Parent := FBody;
  FBtnClose.Height := FfPx(36);
  FBtnClose.Width := 72;
  FBtnClose.OnClick := BtnHideClick;
  StyleSoftPanelBtn(FBtnClose, UiFont, spbrQuiet);

  FBtnGrep := TsButton.Create(Self);
  FBtnGrep.Name := 'SearchGrep';
  FBtnGrep.Parent := FBody;
  FBtnGrep.Caption := 'grep';
  FBtnGrep.OnClick := BtnCommandClick;
  StyleSoftPanelBtn(FBtnGrep, UiFont, spbrCommand);
  FBtnGlob := TsButton.Create(Self);
  FBtnGlob.Name := 'SearchGlob';
  FBtnGlob.Parent := FBody;
  FBtnGlob.Caption := 'glob';
  FBtnGlob.OnClick := BtnCommandClick;
  StyleSoftPanelBtn(FBtnGlob, UiFont, spbrCommand);
  FBtnAskAI := TsButton.Create(Self);
  FBtnAskAI.Name := 'SearchAskAI';
  FBtnAskAI.Parent := FBody;
  FBtnAskAI.OnClick := BtnAskAIClick;
  FBtnAskAI.Visible := False;
  StyleSoftPanelBtn(FBtnAskAI, UiFont, spbrCommand);

  FBtnHide := TsButton.Create(Self);
  FBtnHide.Parent := FBody;
  FBtnHide.Height := FfPx(36);
  FBtnHide.Width := FfPx(28);
  FBtnHide.Caption := #$00D7; { × — same frame as Assistente IA }
  FBtnHide.Hint := TrText('Close');
  FBtnHide.OnClick := BtnHideClick;
  StyleSoftPanelFrameBtn(FBtnHide, UiFont);
  FBtnHide.Font.Size := 12;

  FBtnFloat := TsButton.Create(Self);
  FBtnFloat.Parent := FBody;
  FBtnFloat.Height := FfPx(36);
  FBtnFloat.Width := FfPx(28);
  FBtnFloat.OnClick := BtnFloatClick;
  StyleSoftPanelFrameBtn(FBtnFloat, UiFont);
  FBtnFloat.Font.Size := 10;

  FBtnChevron := CreatePanelChevron(Self, FBody, ChevronClick);

  FPopDock := TPopupMenu.Create(Self);
  FMiFloat := TMenuItem.Create(FPopDock);
  FMiFloat.OnClick := BtnFloatClick;
  FPopDock.Items.Add(FMiFloat);
  PopupMenu := FPopDock;
  FBody.PopupMenu := FPopDock;

  ApplyRecentFindGlyphs;
  FBuilt := True;
  LayoutFrame;
end;

procedure TFastFileFilterBar.LayoutFrame;
var
  L, W, X, Y, Gap, HeaderH, FrameBtnW, EditH, BtnH, ComboH, StatusH: Integer;
  TitleW, LblW, ApplyW, NeedH, OldH: Integer;
  MeasureCanvas: TControlCanvas;
  BL: IInterface;

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

begin
  if not FBuilt or not Assigned(FBody) then Exit;
  { Accordion: host owns height — do not lay out / unlock chrome while shut. }
  if FCollapsed and (not FFloating) then
  begin
    for L := 0 to FBody.ControlCount - 1 do
    begin
      if (FBody.Controls[L] = FBtnChevron) or (FBody.Controls[L] = FLblTitle) or
         (FBody.Controls[L] = FLblMode) or (FBody.Controls[L] = FBtnHide) or
         (FBody.Controls[L] = FBtnFloat) or (FBody.Controls[L] = FTitleHit) or
         (FBody.Controls[L] = FCollapseMask) then
        Continue;
      FBody.Controls[L].Visible := False;
    end;
    SyncCollapseMask(FCollapseMask, Self, FBody,
      FBody.Padding.Top + FfPx(FILTER_HEADER_H), CSurface, True);
    Exit;
  end;
  L := FBody.Padding.Left;
  W := FBody.ClientWidth - FBody.Padding.Left - FBody.Padding.Right;
  if W < 40 then Exit;
  BL := BidiLayoutScope([FBody]);

  Gap := FfPx(6);
  HeaderH := FfPx(FILTER_HEADER_H);
  FrameBtnW := FfPx(26);
  EditH := FfPx(FILTER_EDIT_H);
  BtnH := FfPx(FILTER_BTN_H);
  ComboH := FfPx(FILTER_RECENT_CMB_H);
  OldH := FContentHeight;

  MeasureCanvas := TControlCanvas.Create;
  try
    MeasureCanvas.Control := Self;
    StatusH := TextH(FLblStatus.Font) + 2;
    Y := FBody.Padding.Top;

    { Header: title and match mode on the left, float / close (×) on the right. }
    FBtnHide.Caption := #$00D7;
    FBtnHide.SetBounds(L + W - FrameBtnW, Y, FrameBtnW, HeaderH);
    FBtnFloat.SetBounds(FBtnHide.Left - FrameBtnW - FfPx(2), Y, FrameBtnW, HeaderH);
    if Assigned(FTitleHit) then
    begin
      FTitleHit.Visible := False;
      FTitleHit.SetBounds(0, 0, 0, 0);
    end;
    X := L;
    if Assigned(FBtnChevron) then
    begin
      FBtnChevron.Visible := not FFloating;
      if FBtnChevron.Visible then
      begin
        FBtnChevron.SetBounds(X, Y, FfPx(22), HeaderH);
        Inc(X, FBtnChevron.Width + FfPx(2));
      end;
    end;
    FLblTitle.Visible := True;
    FLblTitle.AutoSize := False;
    FLblTitle.Layout := tlCenter;
    TitleW := Min(TextW(FLblTitle.Font, FLblTitle.Caption) + FfPx(4),
      Max(0, FBtnFloat.Left - Gap - X));
    FLblTitle.SetBounds(X, Y, TitleW, HeaderH);
    Inc(X, TitleW + Gap);
    FLblMode.AutoSize := False;
    FLblMode.Layout := tlCenter;
    FLblMode.Visible := (Trim(FLblMode.Caption) <> '') and
      (FBtnFloat.Left - Gap - X > FfPx(24));
    if FLblMode.Visible then
      FLblMode.SetBounds(X, Y, FBtnFloat.Left - Gap - X, HeaderH);
    Inc(Y, HeaderH + FfPx(4));

    { Recent: compact label + MRU combo. Search lives inside the dropdown. }
    FLblRecent.AutoSize := False;
    FLblRecent.Layout := tlCenter;
    LblW := TextW(FLblRecent.Font, FLblRecent.Caption) + FfPx(6);
    if LblW > W div 3 then
      LblW := W div 3;
    FLblRecent.SetBounds(L, Y, LblW, ComboH);
    FCmbRecent.SetBounds(L + LblW + FfPx(4), Y, Max(FfPx(60), W - LblW - FfPx(4)), ComboH);
    if Assigned(FEdtRecentFind) then
      FEdtRecentFind.Visible := False;
    if Assigned(FBtnRecentFindClear) then
      FBtnRecentFindClear.Visible := False;
    if Assigned(FBtnRecentFind) then
      FBtnRecentFind.Visible := False;
    Inc(Y, Max(ComboH, FCmbRecent.Height) + Gap);

    { Pattern with Apply beside it. }
    ApplyW := Max(FfPx(64), TextW(FBtnApply.Font, FBtnApply.Caption) + FfPx(28));
    if ApplyW > W div 2 then
      ApplyW := W div 2;
    FBtnApply.SetBounds(L + W - ApplyW, Y, ApplyW, EditH);
    FEditShell.SetBounds(L, Y, Max(FfPx(60), W - ApplyW - Gap), EditH);
    Inc(Y, EditH + Gap);

    Inc(Y, FlowSoftPanelButtons([FBtnGrep, FBtnGlob, FBtnAskAI, FBtnContinue,
      FBtnExport, FBtnCopy, FBtnClear, FBtnClose], MeasureCanvas, L, Y, W, BtnH,
      Gap, FfPx(52), FfPx(24)));
    Inc(Y, FfPx(4));

    FLblStatus.AutoSize := False;
    FLblStatus.SetBounds(L, Y, W, StatusH);
    FLblStatus.Hint := FLblStatus.Caption;
    Inc(Y, StatusH);

    NeedH := Y + FBody.Padding.Bottom;
    { The bottom resize grip (floating only) sits outside FBody. }
    if FFloating then
      Inc(NeedH, FfPx(16));
    FContentHeight := NeedH;
    if FFloating then
    begin
      Constraints.MinHeight := NeedH;
      Constraints.MaxHeight := 0;
    end;
  finally
    MeasureCanvas.Free;
  end;
  { Docked: the host column owns the height and re-stacks on this event. }
  if (OldH <> NeedH) and (not FFloating) and (not FCollapsed) and
     Assigned(FOnHeightChanged) then
    FOnHeightChanged(Self);
end;

procedure TFastFileFilterBar.BodyResize(Sender: TObject);
begin
  LayoutFrame;
end;

procedure TFastFileFilterBar.Resize;
begin
  inherited;
  LayoutFrame;
end;

procedure TFastFileFilterBar.ApplySoftFrame;
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
  StyleSoftPanelBtn(FBtnApply, UiFont, spbrPrimary);
  StyleSoftPanelBtn(FBtnContinue, UiFont, spbrAction);
  StyleSoftPanelBtn(FBtnExport, UiFont, spbrAction);
  StyleSoftPanelBtn(FBtnCopy, UiFont, spbrAction);
  StyleSoftPanelBtn(FBtnClear, UiFont, spbrQuiet);
  StyleSoftPanelBtn(FBtnClose, UiFont, spbrQuiet);
  StyleSoftPanelBtn(FBtnGrep, UiFont, spbrCommand);
  StyleSoftPanelBtn(FBtnGlob, UiFont, spbrCommand);
  StyleSoftPanelBtn(FBtnAskAI, UiFont, spbrCommand);
  StyleSoftPanelFrameBtn(FBtnHide, UiFont);
  if Assigned(FBtnHide) then
    FBtnHide.Font.Size := 12;
  StyleSoftPanelFrameBtn(FBtnFloat, UiFont);
  if Assigned(FBtnFloat) then
    FBtnFloat.Font.Size := 10;
  LayoutFrame;
end;

procedure TFastFileFilterBar.ApplyCaptions;
begin
  if not FBuilt then Exit;
  FLblTitle.Caption := TrText('Filter / Grep');
  SyncPanelChevron(FBtnChevron, FCollapsed);
  if Assigned(FLblRecent) then
    FLblRecent.Caption := TrText('FilterBar.Recent');
  FBtnApply.Caption := TrText('FilterBar.Apply');
  FBtnContinue.Caption := TrText('FilterBar.Continue');
  if Assigned(FBtnExport) then
    FBtnExport.Caption := TrText('FilterBar.Export');
  if Assigned(FBtnCopy) then
    FBtnCopy.Caption := TrText('FilterBar.Copy');
  FBtnClear.Caption := TrText('FilterBar.Clear');
  if Assigned(FBtnClose) then
    FBtnClose.Caption := TrText('Close');
  FBtnGrep.Hint := Format(TrText('SearchCmd.LaunchHint'), ['grep']);
  FBtnGlob.Hint := Format(TrText('SearchCmd.LaunchHint'), ['glob']);
  FBtnGrep.ShowHint := True;
  FBtnGlob.ShowHint := True;
  if Assigned(FBtnAskAI) then
  begin
    FBtnAskAI.Caption := TrText('Assistant.Offer.AskAI');
    FBtnAskAI.Hint := TrText('Regex.ExamplesHint');
    FBtnAskAI.ShowHint := True;
  end;
  FBtnHide.Caption := #$00D7; { × }
  SyncFloatAction;
  ApplyTitleDragFrame;
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
  if Assigned(FBtnClose) then
  begin
    FBtnClose.Hint := TrText('FilterBar.CloseHint');
    FBtnClose.ShowHint := True;
  end;
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
    FEdtPattern.TextHint := TrText('SearchCmd.Hint');
    FEdtPattern.Hint := TrText('FilterBar.PatternHint') + #13#10 + TrText('SearchCmd.Hint');
    FEdtPattern.ShowHint := True;
  end;
  RefreshRecentCombo;
  LayoutFrame;
end;

procedure TFastFileFilterBar.BtnCommandClick(Sender: TObject);
begin
  if not Assigned(FOnCommand) then Exit;
  if Sender = FBtnGlob then FOnCommand(Self, 'glob')
  else FOnCommand(Self, 'grep');
end;

procedure TFastFileFilterBar.BtnAskAIClick(Sender: TObject);
begin
  if Assigned(FOnAskAI) then
    FOnAskAI(Self);
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

procedure TFastFileFilterBar.SetModeHint(const AModeText, AHover: string);
begin
  if Assigned(FBtnAskAI) then
    FBtnAskAI.Visible := AHover <> '';
  if Assigned(FLblMode) then
  begin
    FLblMode.Caption := AModeText;
    FLblMode.Hint := AHover;
    FLblMode.ShowHint := AHover <> '';
  end;
  LayoutFrame;
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
  LayoutFrame;
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
  LayoutFrame;
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

procedure TFastFileFilterBar.ApplyTitleDragFrame;
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
var
  WasClick: Boolean;
  P: TPoint;
begin
  WasClick := FHeaderDown and (Button = mbLeft);
  FHeaderDown := False;
  SetCaptureControl(nil);
  if not WasClick or FFloating or not Assigned(FBody) then Exit;
  { The whole panel drags; only a click on the title row toggles. }
  P := FBody.ScreenToClient(Mouse.CursorPos);
  if (P.Y >= 0) and (P.Y < FBody.Padding.Top + FfPx(FILTER_HEADER_H)) and
     Assigned(FOnHeaderClick) then
    FOnHeaderClick(Self);
end;

procedure TFastFileFilterBar.ChevronClick(Sender: TObject);
begin
  if Assigned(FOnHeaderClick) then
    FOnHeaderClick(Self);
end;

function TFastFileFilterBar.HeaderHeight: Integer;
begin
  if Assigned(FBody) then
    Result := FBody.Padding.Top + FfPx(FILTER_HEADER_H) + FBody.Padding.Bottom
  else
    Result := FfPx(FILTER_HEADER_H + 12);
end;

procedure TFastFileFilterBar.SetCollapsed(AValue: Boolean);

  procedure SetBodyChromeVisible(AShow: Boolean);
  var
    I: Integer;
    C: TControl;
  begin
    if not Assigned(FBody) then Exit;
    for I := 0 to FBody.ControlCount - 1 do
    begin
      C := FBody.Controls[I];
      if (C = FBtnChevron) or (C = FLblTitle) or (C = FLblMode) or
         (C = FBtnHide) or (C = FBtnFloat) or (C = FTitleHit) or
         (C = FCollapseMask) then
        Continue;
      C.Visible := AShow;
    end;
  end;

begin
  if FFloating then
    AValue := False;
  if FCollapsed = AValue then
  begin
    if FCollapsed then
    begin
      SetBodyChromeVisible(False);
      SyncCollapseMask(FCollapseMask, Self, FBody,
        FBody.Padding.Top + FfPx(FILTER_HEADER_H), CSurface, True);
    end;
    Exit;
  end;
  FCollapsed := AValue;
  SyncPanelChevron(FBtnChevron, FCollapsed);
  if FCollapsed then
    SetBodyChromeVisible(False)
  else
  begin
    SetBodyChromeVisible(True);
    LayoutFrame;
  end;
  SyncCollapseMask(FCollapseMask, Self, FBody,
    FBody.Padding.Top + FfPx(FILTER_HEADER_H), CSurface, FCollapsed);
end;

procedure TFastFileFilterBar.SetFloatingLook(AFloating: Boolean);
begin
  FFloating := AFloating;
  if AFloating then
  begin
    SetCollapsed(False);
    Constraints.MinHeight := 0;
    Constraints.MaxHeight := 0;
  end;
  ApplyCaptions;
  LayoutFrame;
end;

function TFastFileFilterBar.ContentHeight: Integer;
begin
  if FBuilt then
    LayoutFrame;
  if FContentHeight > 0 then
    Result := FContentHeight
  else
    Result := FfPx(FILTER_BAR_HEIGHT);
end;

procedure TFastFileFilterBar.RelayoutAfterDock;
begin
  Align := alNone;
  Constraints.MinHeight := 0;
  Constraints.MaxHeight := 0;
  ApplySoftFrame;
  LayoutFrame;
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
  LayoutFrame;
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
  LayoutFrame;
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
  ApplySoftFrame;
end;

procedure TFastFileFilterPeek.ApplySoftFrame;
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
