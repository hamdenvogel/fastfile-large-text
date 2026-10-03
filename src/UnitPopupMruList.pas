unit UnitPopupMruList;

{ MRU dropdown: Mais ferramentas search chrome + card-styled rows
  (gradient, icon, hover). Shared by recent files, Filter/Grep and Assistente. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  Buttons, sSpeedButton, sPanel, sBevel, sLabel, sEdit, ExtCtrls,
  sSkinProvider, acAlphaImageList, System.ImageList, Vcl.ImgList;

type
  TMruListPickEvent = procedure(Sender: TObject; const AValue: string;
    AIndex: Integer) of object;
  TMruListPathActionEvent = procedure(Sender: TObject; const APath: string) of object;

  TFormPopupMruList = class(TForm)
    sPanel1: TsPanel;
    pnlAccent: TsPanel;
    pnlBody: TsPanel;
    pnlHeader: TsPanel;
    lblHeader: TsLabel;
    pnlSearchRow: TsPanel;
    btnSearchGlyph: TsSpeedButton;
    edtSearch: TsEdit;
    btnClearSearch: TsSpeedButton;
    sBevelHeader: TsBevel;
    lstItems: TListBox;
    sSkinProvider1: TsSkinProvider;
    imgSearchGlyphs: TsCharImageList;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtSearchChange(Sender: TObject);
    procedure edtSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSearchGlyphClick(Sender: TObject);
    procedure btnClearSearchClick(Sender: TObject);
    procedure lstItemsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lstItemsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure lstItemsMouseLeave(Sender: TObject);
    procedure lstItemsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lstItemsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure WMMruRepopulate(var Msg: TMessage); message WM_USER + 71;
  private
    FAll: TStringList;
    FItemTags: TList;
    FExpanded: Boolean;
    FFilling: Boolean;
    FIgnorePick: Boolean;
    FHotIndex: Integer;
    FHotAction: Integer;
    FOnPick: TMruListPickEvent;
    FOnProperties: TMruListPathActionEvent;
    FOnRemove: TMruListPathActionEvent;
    FOnClearAll: TNotifyEvent;
    FMoreCaption: string;
    FMoreHint: string;
    FHoldPhase: Integer;
    FHoldTicks: Integer;
    FHoldTimer: TTimer;
    FOpenHold: Boolean;
    FKeepOpenRect: TRect;
    FButtonsWereUp: Boolean;
    FArmedTick: Cardinal;
    FPinnedPos: TPoint;
    FPinnedW, FPinnedH: Integer;
    FGlyphPx: Integer;
    FGlyphLocked: Boolean;
    function ScaledPx(ADesignPx: Integer): Integer;
    function UiFontName: string;
    function ItemTag(AIndex: Integer): NativeInt;
    procedure AddItemTagged(const ACaption: string; ATag: NativeInt);
    procedure StyleSearchBox;
    procedure ApplySearchCue;
    procedure UpdateClearSearchBtn;
    procedure ClearSearchText;
    procedure PopulateList;
    procedure PickIndex(AIndex: Integer);
    function LooksLikeFilePath(const S: string): Boolean;
    function MoreRowCaption: string;
    function MoreRowHint: string;
    procedure ApplyItemHint(AIndex: Integer; AAction: Integer = 0);
    procedure InvalidateListRow(AIndex: Integer);
    function FileRowActionsVisible: Boolean;
    function IconSize: Integer;
    procedure DrawMruGlyph(ACanvas: TCanvas; X, Y, AIndex: Integer);
    procedure ActionIconRects(const ACard: TRect; out APropsR, ARemoveR: TRect);
    function RowActionAt(X, Y: Integer; out AIndex: Integer): Integer;
    procedure DropPathFromList(const APath: string; ANotifyRemove: Boolean);
    procedure RunRowAction(AIndex, AAction: Integer);
    function ForegroundIsSelf: Boolean;
    function ForegroundIsApp: Boolean;
    procedure SetPopupCloseLocked(ALock: Boolean);
    procedure LockCloseUntilMouseIdle;
    procedure PlaceAndShowStandalone(const AScreenPos: TPoint);
    procedure PinToScreenPos;
    function ScreenPointInPopup(const APt: TPoint): Boolean;
    function MouseButtonsDown: Boolean;
    procedure HoldTimerTick(Sender: TObject);
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadList(const ATitle, AMoreCaption: string; AItems: TStrings;
      const AMoreHint: string = '');
    procedure PrepareLayout(AWidth: Integer);
    procedure FocusSearch;
    procedure ClosePopup(AnimationAllowed: Boolean = False);
    property OnPick: TMruListPickEvent read FOnPick write FOnPick;
    property OnProperties: TMruListPathActionEvent read FOnProperties write FOnProperties;
    property OnRemove: TMruListPathActionEvent read FOnRemove write FOnRemove;
    property OnClearAll: TNotifyEvent read FOnClearAll write FOnClearAll;
  end;

procedure ShowMruListPopup(AOwner: TComponent; const ATitle, AMoreCaption: string;
  AItems: TStrings; AWidth: Integer; const AScreenPos: TPoint;
  AOnPick: TMruListPickEvent; const AMoreHint: string = '';
  AOnProperties: TMruListPathActionEvent = nil;
  AOnRemove: TMruListPathActionEvent = nil;
  AKeepOpen: TWinControl = nil;
  AOnClearAll: TNotifyEvent = nil);

var
  FormPopupMruList: TFormPopupMruList;

implementation

{$R *.dfm}

uses
  uI18n, uMruFind, sSkinManager, uFastFileMsgDlg;

const
  MRU_TITLE_H = 26;
  MRU_SEARCH_H = 28;
  MRU_HEADER_PAD = 4;
  MRU_HEADER_H = MRU_TITLE_H + MRU_SEARCH_H + MRU_HEADER_PAD;
  MRU_HEADER_SEP_H = 10;
  MRU_BODY_PAD = 12;
  MRU_ACCENT_W = 5;
  MRU_VISIBLE = 10;
  MRU_MAX_ROWS = 10;
  MRU_ROW_H = 40;
  MRU_GRAD_TOP = $00FFF8F2;
  MRU_GRAD_BOT = $00F4E6D6;
  MRU_GRAD_SEL_TOP = $00FFEAD8;
  MRU_GRAD_SEL_BOT = $00F0D4BC;
  MRU_GRAD_BORDER = $00E2D0BC;
  MRU_GRAD_SEL_BORDER = $00D0B898;
  MRU_TEXT = $00201810;
  MRU_MUTED = $00665C52;
  MRU_SURFACE = $00F3F0EB;
  MRU_ACT_NONE = 0;
  MRU_ACT_PROPS = 1;
  MRU_ACT_REMOVE = 2;
  GLYPH_PROPS = 6;
  GLYPH_REMOVE = 7;
  EM_SETCUEBANNER = $1501;

procedure PaintMruRowGradient(ACanvas: TCanvas; const R: TRect; ASelected: Boolean);
var
  V: array[0..1] of TTriVertex;
  GR: TGradientRect;
  C1, C2, Border: TColor;
  Rgn: HRGN;

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
  if ASelected then
  begin
    C1 := MRU_GRAD_SEL_TOP;
    C2 := MRU_GRAD_SEL_BOT;
    Border := MRU_GRAD_SEL_BORDER;
  end
  else
  begin
    C1 := MRU_GRAD_TOP;
    C2 := MRU_GRAD_BOT;
    Border := MRU_GRAD_BORDER;
  end;
  FillVertex(V[0], R.Left, R.Top, C1);
  FillVertex(V[1], R.Right, R.Bottom, C2);
  GR.UpperLeft := 0;
  GR.LowerRight := 1;
  Rgn := CreateRoundRectRgn(R.Left, R.Top, R.Right + 1, R.Bottom + 1, 8, 8);
  try
    SelectClipRgn(ACanvas.Handle, Rgn);
    GradientFill(ACanvas.Handle, @V[0], 2, @GR, 1, GRADIENT_FILL_RECT_V);
    SelectClipRgn(ACanvas.Handle, 0);
  finally
    DeleteObject(Rgn);
  end;
  ACanvas.Pen.Color := Border;
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsClear;
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
end;

constructor TFormPopupMruList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAll := TStringList.Create;
  FItemTags := TList.Create;
  FMoreCaption := '...';
  FIgnorePick := False;
  FHotIndex := -1;
  FHotAction := MRU_ACT_NONE;
  FHoldPhase := 0;
  FHoldTicks := 0;
  FOpenHold := False;
  FButtonsWereUp := False;
  FArmedTick := 0;
  FKeepOpenRect := Rect(0, 0, 0, 0);
  FGlyphPx := 16;
  FGlyphLocked := False;
  FHoldTimer := TTimer.Create(Self);
  FHoldTimer.Enabled := False;
  FHoldTimer.Interval := 100;
  FHoldTimer.OnTimer := HoldTimerTick;
  if Assigned(lstItems) then
    lstItems.OnMouseLeave := lstItemsMouseLeave;
end;

destructor TFormPopupMruList.Destroy;
begin
  if Assigned(FHoldTimer) then
    FHoldTimer.Enabled := False;
  FHoldPhase := 0;
  FOpenHold := False;
  FreeAndNil(FItemTags);
  FreeAndNil(FAll);
  inherited;
end;

function TFormPopupMruList.UiFontName: string;
begin
  if Screen.Fonts.IndexOf('Segoe UI') >= 0 then
    Result := 'Segoe UI'
  else if Assigned(Application.MainForm) and (Trim(Application.MainForm.Font.Name) <> '') then
    Result := Application.MainForm.Font.Name
  else
    Result := 'Tahoma';
end;

function TFormPopupMruList.ScaledPx(ADesignPx: Integer): Integer;
var
  PPI: Integer;
begin
  PPI := 96;
  if Assigned(sSkinProvider1) and (sSkinProvider1.SkinData.CurrentPPI > 0) then
    PPI := sSkinProvider1.SkinData.CurrentPPI;
  if PPI = 96 then
    Result := ADesignPx
  else
    Result := MulDiv(ADesignPx, PPI, 96);
end;

function TFormPopupMruList.ForegroundIsSelf: Boolean;
var
  Fg: HWND;
begin
  Result := False;
  if not HandleAllocated then Exit;
  Fg := GetForegroundWindow;
  Result := (Fg <> 0) and ((Fg = Handle) or IsChild(Handle, Fg));
end;

function TFormPopupMruList.ForegroundIsApp: Boolean;
var
  Fg, Main: HWND;
begin
  if ForegroundIsSelf then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
  Fg := GetForegroundWindow;
  if Fg = 0 then Exit;
  if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
  begin
    Main := Application.MainForm.Handle;
    Result := (Fg = Main) or IsChild(Main, Fg);
  end;
end;

procedure TFormPopupMruList.SetPopupCloseLocked(ALock: Boolean);
begin
  { Properties dialog: ignore click-outside until that window is done.
    Do not disable the timer — it also owns click-outside after open. }
  if ALock then
  begin
    FHoldPhase := 1;
    FHoldTicks := 0;
  end
  else
  begin
    FHoldPhase := 0;
    FHoldTicks := 0;
  end;
  if Assigned(FHoldTimer) and Visible then
    FHoldTimer.Enabled := True;
end;

procedure TFormPopupMruList.LockCloseUntilMouseIdle;
begin
  FOpenHold := True;
  FHoldTicks := 0;
  if Assigned(FHoldTimer) then
    FHoldTimer.Enabled := True;
end;

function TFormPopupMruList.MouseButtonsDown: Boolean;
begin
  Result := (GetAsyncKeyState(VK_LBUTTON) < 0) or (GetAsyncKeyState(VK_RBUTTON) < 0);
end;

function TFormPopupMruList.ScreenPointInPopup(const APt: TPoint): Boolean;
var
  Wnd: HWND;
begin
  Result := (not IsRectEmpty(FKeepOpenRect)) and PtInRect(FKeepOpenRect, APt);
  if Result then Exit;
  Result := PtInRect(BoundsRect, APt);
  if Result then Exit;
  Wnd := WindowFromPoint(APt);
  Result := (Wnd <> 0) and HandleAllocated and
    ((Wnd = Handle) or IsChild(Handle, Wnd));
end;

procedure TFormPopupMruList.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW;
  Params.Style := Params.Style and not WS_CHILD;
  if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
    Params.WndParent := Application.MainForm.Handle
  else if Application.Handle <> 0 then
    Params.WndParent := Application.Handle;
end;

procedure TFormPopupMruList.PinToScreenPos;
begin
  if not HandleAllocated then Exit;
  SetWindowPos(Handle, HWND_TOPMOST, FPinnedPos.X, FPinnedPos.Y, FPinnedW, FPinnedH,
    SWP_NOACTIVATE or SWP_SHOWWINDOW);
end;

procedure TFormPopupMruList.PlaceAndShowStandalone(const AScreenPos: TPoint);
var
  R: TRect;
  X, Y, W, H: Integer;
  Mon: TMonitor;
begin
  { Own Show — not AlphaControls ShowPopupForm. Do not set PopupParent after
    SetBounds: VCL RecreateWnd resets the form to DFM Left=0,Top=0. }
  W := Width;
  H := Height;
  Mon := Screen.MonitorFromPoint(AScreenPos);
  if Assigned(Mon) then
    R := Mon.WorkareaRect
  else
    R := Screen.WorkAreaRect;
  X := AScreenPos.X;
  Y := AScreenPos.Y;
  if (X = 0) and (Y = 0) then
  begin
    X := R.Left + 8;
    Y := R.Top + 8;
  end;
  if Y + H > R.Bottom then
    Y := AScreenPos.Y - H;
  if Y < R.Top then
    Y := R.Top;
  if X + W > R.Right then
    X := R.Right - W;
  if X < R.Left then
    X := R.Left;
  FPinnedPos := Point(X, Y);
  FPinnedW := W;
  FPinnedH := H;
  FormStyle := fsStayOnTop;
  HandleNeeded;
  SetBounds(X, Y, W, H);
  FButtonsWereUp := False;
  FArmedTick := GetTickCount + 700;
  Show;
  PinToScreenPos;
  LockCloseUntilMouseIdle;
end;

procedure TFormPopupMruList.HoldTimerTick(Sender: TObject);
var
  Pt: TPoint;
begin
  if csDestroying in ComponentState then
  begin
    FOpenHold := False;
    if Assigned(FHoldTimer) then
      FHoldTimer.Enabled := False;
    Exit;
  end;
  if not Visible then
  begin
    FOpenHold := False;
    if Assigned(FHoldTimer) then
      FHoldTimer.Enabled := False;
    Exit;
  end;
  if FOpenHold then
  begin
    if MouseButtonsDown then
      Exit;
    Inc(FHoldTicks);
    if FHoldTicks >= 5 then
    begin
      FOpenHold := False;
      FButtonsWereUp := True;
      FArmedTick := GetTickCount + 400;
      PinToScreenPos;
      FocusSearch;
    end;
    Exit;
  end;
  if FHoldPhase = 1 then
  begin
    Inc(FHoldTicks);
    { Wait until Properties (or another external window) takes focus. }
    if (not Application.Active) or (not ForegroundIsApp) then
    begin
      FHoldPhase := 2;
      FHoldTicks := 0;
    end
    else if FHoldTicks >= 25 then
      SetPopupCloseLocked(False);
  end
  else if FHoldPhase = 2 then
  begin
    if Application.Active and ForegroundIsApp then
    begin
      SetPopupCloseLocked(False);
      if Visible and Assigned(edtSearch) and edtSearch.CanFocus then
      begin
        SetForegroundWindow(Handle);
        FocusSearch;
      end;
    end;
  end
  else
  begin
    if GetTickCount < FArmedTick then
      Exit;
    if not MouseButtonsDown then
    begin
      FButtonsWereUp := True;
      Exit;
    end;
    if not FButtonsWereUp then
      Exit;
    GetCursorPos(Pt);
    if ScreenPointInPopup(Pt) then
      Exit;
    FButtonsWereUp := False;
    ClosePopup(False);
  end;
end;

procedure TFormPopupMruList.ClosePopup(AnimationAllowed: Boolean = False);
begin
  FOpenHold := False;
  FHoldPhase := 0;
  if Assigned(FHoldTimer) then
    FHoldTimer.Enabled := False;
  if not AnimationAllowed then
  begin
    sSkinProvider1.AllowAnimation := False;
    Close;
    sSkinProvider1.AllowAnimation := True;
  end
  else
    Close;
end;

procedure TFormPopupMruList.FocusSearch;
begin
  if Assigned(edtSearch) and edtSearch.CanFocus then
    edtSearch.SetFocus;
end;

procedure TFormPopupMruList.ApplySearchCue;
var
  Cue: WideString;
begin
  if not Assigned(edtSearch) or (not edtSearch.HandleAllocated) then Exit;
  Cue := WideString(TrText('MRU.FindHint'));
  SendMessageW(edtSearch.Handle, EM_SETCUEBANNER, 1, LPARAM(PWideChar(Cue)));
end;

procedure TFormPopupMruList.UpdateClearSearchBtn;
begin
  if not Assigned(btnClearSearch) then Exit;
  btnClearSearch.Visible := Assigned(edtSearch) and (Trim(edtSearch.Text) <> '');
end;

procedure TFormPopupMruList.ClearSearchText;
begin
  if not Assigned(edtSearch) then Exit;
  edtSearch.Text := '';
  FExpanded := False;
  UpdateClearSearchBtn;
  PopulateList;
  ApplySearchCue;
  FocusSearch;
end;

procedure TFormPopupMruList.StyleSearchBox;
begin
  if Assigned(pnlSearchRow) then
  begin
    pnlSearchRow.Align := alTop;
    pnlSearchRow.Height := ScaledPx(MRU_SEARCH_H);
    pnlSearchRow.BorderWidth := ScaledPx(3);
    pnlSearchRow.ParentBackground := False;
    pnlSearchRow.ParentColor := False;
    pnlSearchRow.Color := clWindow;
    try
      pnlSearchRow.SkinData.SkinSection := 'TRANSPARENT';
      pnlSearchRow.SkinData.CustomColor := True;
    except
    end;
  end;

  if Assigned(btnSearchGlyph) then
  begin
    btnSearchGlyph.Width := ScaledPx(22);
    btnSearchGlyph.Height := ScaledPx(MRU_SEARCH_H) - ScaledPx(6);
    btnSearchGlyph.Flat := True;
    btnSearchGlyph.Caption := '';
    btnSearchGlyph.Margin := 0;
    btnSearchGlyph.Spacing := 0;
    btnSearchGlyph.ShowHint := True;
    btnSearchGlyph.Hint := TrText('MRU.FindHint');
    if Assigned(imgSearchGlyphs) then
    begin
      btnSearchGlyph.Images := imgSearchGlyphs;
      btnSearchGlyph.ImageIndex := 0;
    end;
    try
      btnSearchGlyph.SkinData.SkinSection := 'TRANSPARENT';
      btnSearchGlyph.Blend := 0;
      btnSearchGlyph.Reflected := False;
    except
    end;
  end;

  if Assigned(btnClearSearch) then
  begin
    btnClearSearch.Width := ScaledPx(22);
    btnClearSearch.Height := ScaledPx(MRU_SEARCH_H) - ScaledPx(6);
    btnClearSearch.Flat := True;
    btnClearSearch.Caption := '';
    btnClearSearch.Margin := 0;
    btnClearSearch.Spacing := 0;
    btnClearSearch.ShowHint := True;
    btnClearSearch.Hint := TrText('MRU.ClearFind');
    if Assigned(imgSearchGlyphs) then
    begin
      btnClearSearch.Images := imgSearchGlyphs;
      btnClearSearch.ImageIndex := 1;
    end;
    try
      btnClearSearch.SkinData.SkinSection := 'TRANSPARENT';
      btnClearSearch.Blend := 0;
      btnClearSearch.Reflected := False;
    except
    end;
  end;

  if Assigned(edtSearch) then
  begin
    edtSearch.ParentFont := False;
    edtSearch.Font.Name := UiFontName;
    edtSearch.Font.Height := ScaledPx(-12);
    edtSearch.Font.Color := clWindowText;
    edtSearch.Visible := True;
    try
      edtSearch.SkinData.SkinSection := 'TRANSPARENT';
      edtSearch.BoundLabel.Active := False;
    except
    end;
  end;

  UpdateClearSearchBtn;
  ApplySearchCue;
end;

procedure TFormPopupMruList.LoadList(const ATitle, AMoreCaption: string; AItems: TStrings;
  const AMoreHint: string);
begin
  if Assigned(lblHeader) then
    lblHeader.Caption := ATitle;
  FMoreCaption := Trim(AMoreCaption);
  if FMoreCaption = '' then
    FMoreCaption := '...';
  FMoreHint := Trim(AMoreHint);
  FAll.Clear;
  if Assigned(AItems) then
    FAll.Assign(AItems);
  FExpanded := False;
  if Assigned(edtSearch) then
    edtSearch.Text := '';
  PopulateList;
end;

procedure TFormPopupMruList.AddItemTagged(const ACaption: string; ATag: NativeInt);
begin
  { Do not use TListBox.Items.Objects: LB_SETITEMDATA(-1) is LB_ERR, and
    reading Objects[10] on the "..." row raises EStringListError (10). }
  lstItems.Items.Add(ACaption);
  FItemTags.Add(Pointer(ATag));
end;

function TFormPopupMruList.ItemTag(AIndex: Integer): NativeInt;
begin
  if (AIndex < 0) or (AIndex >= FItemTags.Count) then
  begin
    Result := MRU_OBJ_NONE;
    Exit;
  end;
  Result := NativeInt(FItemTags[AIndex]);
end;

procedure TFormPopupMruList.PopulateList;
var
  I, VisibleN: Integer;
  Needle: string;
  AnyMatch: Boolean;
begin
  if not Assigned(lstItems) then Exit;
  Needle := '';
  if Assigned(edtSearch) then
    Needle := Trim(edtSearch.Text);
  FFilling := True;
  FHotIndex := -1;
  FHotAction := MRU_ACT_NONE;
  try
    lstItems.ItemIndex := -1;
    if lstItems.HandleAllocated then
      SendMessage(lstItems.Handle, LB_SETCURSEL, WPARAM(NativeInt(-1)), 0);
    FItemTags.Clear;
    lstItems.Items.BeginUpdate;
    try
      lstItems.Items.Clear;
      if Needle <> '' then
      begin
        AnyMatch := False;
        for I := 0 to FAll.Count - 1 do
          if MruTextMatches(FAll[I], Needle) or
             MruTextMatches(ExtractFileName(FAll[I]), Needle) then
          begin
            AddItemTagged(FAll[I], I);
            AnyMatch := True;
          end;
        if not AnyMatch then
          AddItemTagged(MruFindNoMatchCaption, MRU_OBJ_NONE);
      end
      else if FExpanded and (FAll.Count > MRU_VISIBLE) then
      begin
        AddItemTagged(MoreRowCaption, MRU_OBJ_MORE);
        for I := MRU_VISIBLE to FAll.Count - 1 do
          AddItemTagged(FAll[I], I);
      end
      else
      begin
        VisibleN := FAll.Count;
        if VisibleN > MRU_VISIBLE then
          VisibleN := MRU_VISIBLE;
        for I := 0 to VisibleN - 1 do
          AddItemTagged(FAll[I], I);
        if FAll.Count > MRU_VISIBLE then
          AddItemTagged(MoreRowCaption, MRU_OBJ_MORE);
      end;
      if Assigned(FOnClearAll) and (FAll.Count > 0) then
        AddItemTagged(MruClearAllCaption, MRU_OBJ_CLEAR_ALL);
    finally
      lstItems.Items.EndUpdate;
    end;
    lstItems.ItemIndex := -1;
    if lstItems.HandleAllocated then
      SendMessage(lstItems.Handle, LB_SETCURSEL, WPARAM(NativeInt(-1)), 0);
  finally
    FFilling := False;
  end;
  UpdateClearSearchBtn;
end;

procedure TFormPopupMruList.PrepareLayout(AWidth: Integer);
var
  W, N, RowH, ListH, BodyPad, NeedH: Integer;
begin
  Constraints.MinHeight := 0;
  Constraints.MaxHeight := 0;
  Constraints.MinWidth := 0;
  Constraints.MaxWidth := 0;

  W := AWidth;
  if W < 280 then
    W := 280;

  if Assigned(pnlAccent) then
  begin
    pnlAccent.Width := ScaledPx(MRU_ACCENT_W);
    try
      pnlAccent.SkinData.CustomColor := True;
    except
    end;
    pnlAccent.Color := $00E8A060;
    pnlAccent.ParentBackground := False;
  end;

  BodyPad := ScaledPx(MRU_BODY_PAD);
  if Assigned(pnlBody) then
    pnlBody.BorderWidth := BodyPad;

  if Assigned(pnlHeader) then
  begin
    pnlHeader.Align := alNone;
    pnlHeader.Top := 0;
    pnlHeader.Height := ScaledPx(MRU_HEADER_H);
    pnlHeader.Align := alTop;
    try
      pnlHeader.SkinData.SkinSection := 'TRANSPARENT';
    except
    end;
  end;

  if Assigned(lblHeader) then
  begin
    lblHeader.Align := alTop;
    lblHeader.Height := ScaledPx(MRU_TITLE_H);
    lblHeader.AutoSize := False;
    lblHeader.ParentFont := False;
    lblHeader.Font.Name := UiFontName;
    lblHeader.Font.Height := ScaledPx(-15);
    lblHeader.Font.Style := [fsBold];
    lblHeader.Font.Color := clWindowText;
  end;

  StyleSearchBox;

  if Assigned(sBevelHeader) then
  begin
    sBevelHeader.Align := alNone;
    sBevelHeader.Top := ScaledPx(MRU_HEADER_H);
    sBevelHeader.Height := ScaledPx(MRU_HEADER_SEP_H);
    sBevelHeader.Align := alTop;
  end;

  if not FGlyphLocked then
  begin
    FGlyphPx := ScaledPx(16);
    if FGlyphPx < 16 then
      FGlyphPx := 16;
  end;

  if Assigned(lstItems) then
  begin
    lstItems.Align := alClient;
    lstItems.Style := lbOwnerDrawFixed;
    lstItems.ItemHeight := ScaledPx(MRU_ROW_H);
    lstItems.Color := MRU_SURFACE;
    lstItems.ParentColor := False;
    lstItems.ParentFont := False;
    lstItems.Font.Name := UiFontName;
    lstItems.Font.Height := ScaledPx(-12);
    lstItems.Font.Color := MRU_TEXT;
    lstItems.DoubleBuffered := True;
    lstItems.ParentShowHint := False;
    lstItems.ShowHint := True;
    RowH := lstItems.ItemHeight;
    if RowH < ScaledPx(28) then
      RowH := ScaledPx(MRU_ROW_H);
    N := lstItems.Items.Count;
    if N < 1 then
      N := 1;
    if N > MRU_MAX_ROWS then
      N := MRU_MAX_ROWS;
    ListH := N * RowH + ScaledPx(6);
    if Screen.WorkAreaHeight > 0 then
    begin
      NeedH := Screen.WorkAreaHeight - ScaledPx(160);
      if (NeedH > ScaledPx(160)) and (ListH > NeedH) then
        ListH := NeedH;
    end;
  end
  else
    ListH := ScaledPx(80);

  NeedH := ScaledPx(MRU_HEADER_H) + ScaledPx(MRU_HEADER_SEP_H) + ListH + (BodyPad * 2);
  ClientWidth := W;
  ClientHeight := NeedH;
  if Assigned(sPanel1) then
    sPanel1.SetBounds(0, 0, ClientWidth, ClientHeight);
  if Assigned(pnlAccent) then
    pnlAccent.Height := ClientHeight;
end;

procedure TFormPopupMruList.WMMruRepopulate(var Msg: TMessage);
begin
  PopulateList;
  PrepareLayout(ClientWidth);
  FIgnorePick := False;
end;

procedure TFormPopupMruList.PickIndex(AIndex: Integer);
var
  Tag: NativeInt;
  Val: string;
begin
  if FFilling or FIgnorePick then Exit;
  if not Assigned(lstItems) then Exit;
  if (AIndex < 0) or (AIndex >= lstItems.Items.Count) then Exit;
  Tag := ItemTag(AIndex);
  if Tag = MRU_OBJ_MORE then
  begin
    { Rebuild after MouseUp/Click finishes — VCL keeps ItemIndex=10 and
      crashes with EStringListError if we Clear the list mid-click. }
    FIgnorePick := True;
    FExpanded := not FExpanded;
    PostMessage(Handle, WM_USER + 71, 0, 0);
    Exit;
  end;
  if Tag = MRU_OBJ_CLEAR_ALL then
  begin
    if FastFileMessageBox(
      PChar(TrText('MRU.ClearAllConfirm')),
      PChar(TrText('MRU.ClearAll')),
      MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) <> IDYES then
      Exit;
    ClosePopup(False);
    if Assigned(FOnClearAll) then
      FOnClearAll(Self);
    Exit;
  end;
  if Tag < 0 then Exit;
  if Tag >= FAll.Count then Exit;
  Val := FAll[Tag];
  ClosePopup(False);
  if Assigned(FOnPick) then
    FOnPick(Self, Val, Integer(Tag));
end;

procedure TFormPopupMruList.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    if Assigned(edtSearch) and edtSearch.Focused and (Trim(edtSearch.Text) <> '') then
      ClearSearchText
    else
      ClosePopup(False);
  end;
end;

procedure TFormPopupMruList.edtSearchChange(Sender: TObject);
begin
  FExpanded := False;
  UpdateClearSearchBtn;
  PopulateList;
end;

procedure TFormPopupMruList.edtSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_DOWN) and (Shift = []) then
  begin
    Key := 0;
    if Assigned(lstItems) and lstItems.CanFocus then
    begin
      lstItems.SetFocus;
      if (lstItems.Items.Count > 0) and (lstItems.ItemIndex < 0) then
        lstItems.ItemIndex := 0;
    end;
  end
  else if (Key = VK_RETURN) and (Shift = []) then
  begin
    Key := 0;
    if Assigned(lstItems) then
      PickIndex(lstItems.ItemIndex);
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
    Key := 0;
end;

procedure TFormPopupMruList.btnSearchGlyphClick(Sender: TObject);
begin
  FocusSearch;
end;

procedure TFormPopupMruList.btnClearSearchClick(Sender: TObject);
begin
  ClearSearchText;
end;

function TFormPopupMruList.LooksLikeFilePath(const S: string): Boolean;
var
  T: string;
begin
  { Only a real path — not a chat sentence with "pdf/docx", "01/02" or "C:\..." inside. }
  T := Trim(S);
  Result := False;
  if Length(T) < 3 then Exit;
  if (T[2] = ':') and CharInSet(T[1], ['A'..'Z', 'a'..'z']) and
     ((T[3] = '\') or (T[3] = '/')) then
  begin
    Result := True;
    Exit;
  end;
  Result := (T[1] = '\') and (T[2] = '\');
end;

function TFormPopupMruList.MoreRowCaption: string;
var
  Rest: Integer;
begin
  if FExpanded then
  begin
    Result := Trim(TrText('MRU.ShowFirst'));
    if Result = '' then
      Result := 'Show first 10';
  end
  else
  begin
    Result := Trim(TrText('MRU.ShowMore'));
    if Result = '' then
      Result := 'Show more';
    Rest := FAll.Count - MRU_VISIBLE;
    if Rest > 0 then
      Result := Result + '  (' + IntToStr(Rest) + ')';
  end;
end;

function TFormPopupMruList.MoreRowHint: string;
begin
  if FExpanded then
  begin
    Result := Trim(TrText('MRU.ShowFirstHint'));
    if Result = '' then
      Result := MoreRowCaption;
  end
  else
  begin
    Result := Trim(FMoreHint);
    if Result = '' then
      Result := Trim(TrText('MRU.ShowMoreHint'));
    if Result = '' then
      Result := MoreRowCaption;
  end;
end;

procedure TFormPopupMruList.ApplyItemHint(AIndex: Integer; AAction: Integer);
var
  NewHint: string;
begin
  if not Assigned(lstItems) then Exit;
  NewHint := '';
  if (AIndex >= 0) and (AIndex < lstItems.Items.Count) then
  begin
    if ItemTag(AIndex) = MRU_OBJ_MORE then
      NewHint := MoreRowHint
    else if ItemTag(AIndex) = MRU_OBJ_CLEAR_ALL then
    begin
      NewHint := Trim(TrText('MRU.ClearAllHint'));
      if NewHint = '' then
        NewHint := MruClearAllCaption;
    end
    else if AAction = MRU_ACT_PROPS then
    begin
      NewHint := Trim(TrText('MRU.FilePropertiesHint'));
      if NewHint = '' then
        NewHint := Trim(TrText('MRU.FileProperties'));
    end
    else if AAction = MRU_ACT_REMOVE then
    begin
      if LooksLikeFilePath(lstItems.Items[AIndex]) then
        NewHint := Trim(TrText('MRU.RemoveFromListHint'))
      else
        NewHint := Trim(TrText('MRU.RemoveItemHint'));
      if NewHint = '' then
        NewHint := Trim(TrText('MRU.RemoveFromList'));
    end;
  end;
  if NewHint = lstItems.Hint then Exit;
  lstItems.Hint := NewHint;
  Application.CancelHint;
  if NewHint <> '' then
    Application.ActivateHint(Mouse.CursorPos);
end;

procedure TFormPopupMruList.InvalidateListRow(AIndex: Integer);
var
  R: TRect;
begin
  if not Assigned(lstItems) or (not lstItems.HandleAllocated) then Exit;
  if (AIndex < 0) or (AIndex >= lstItems.Items.Count) then Exit;
  if lstItems.Perform(LB_GETITEMRECT, AIndex, LPARAM(@R)) <> LB_ERR then
    InvalidateRect(lstItems.Handle, @R, False);
end;

function TFormPopupMruList.FileRowActionsVisible: Boolean;
begin
  Result := Assigned(FOnProperties) or Assigned(FOnRemove);
end;

function TFormPopupMruList.IconSize: Integer;
begin
  Result := FGlyphPx;
  if Result <= 0 then
    Result := 16;
end;

procedure TFormPopupMruList.DrawMruGlyph(ACanvas: TCanvas; X, Y, AIndex: Integer);
var
  Sz, SavedDC: Integer;
  Ch: WideString;
  R: TRect;
  SavedName: TFontName;
  SavedHeight: Integer;
  SavedColor: TColor;
  SavedStyle: TFontStyles;
  SavedCharset: TFontCharset;
  Col: TColor;
  FontName: string;
begin
  { Paint FontAwesome into a fixed Sz×Sz clip. Do not use TsCharImageList.Draw:
    GetImage/DoDraw blit the cached bitmap at its own size, which is larger on
    the first paint and shrinks after the first hover invalidate. }
  Sz := IconSize;
  FGlyphLocked := True;
  if (ACanvas = nil) or (Sz <= 0) then Exit;
  if not Assigned(imgSearchGlyphs) then Exit;
  if (AIndex < 0) or (AIndex >= imgSearchGlyphs.Count) then Exit;

  FontName := imgSearchGlyphs.Items[AIndex].FontName;
  if FontName = '' then
    FontName := 'FontAwesome';
  Col := imgSearchGlyphs.Items[AIndex].Color;
  if (Col = clNone) or (Col = clDefault) then
    Col := MRU_TEXT;
  Ch := WideChar(imgSearchGlyphs.Items[AIndex].Char);

  SavedName := ACanvas.Font.Name;
  SavedHeight := ACanvas.Font.Height;
  SavedColor := ACanvas.Font.Color;
  SavedStyle := ACanvas.Font.Style;
  SavedCharset := ACanvas.Font.Charset;
  SavedDC := SaveDC(ACanvas.Handle);
  try
    IntersectClipRect(ACanvas.Handle, X, Y, X + Sz, Y + Sz);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Name := FontName;
    ACanvas.Font.Charset := DEFAULT_CHARSET;
    ACanvas.Font.Style := [];
    ACanvas.Font.Height := -Sz;
    ACanvas.Font.Color := Col;
    R := Classes.Rect(X, Y, X + Sz, Y + Sz);
    DrawTextW(ACanvas.Handle, PWideChar(Ch), Length(Ch), R,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
  finally
    RestoreDC(ACanvas.Handle, SavedDC);
    ACanvas.Font.Name := SavedName;
    ACanvas.Font.Height := SavedHeight;
    ACanvas.Font.Color := SavedColor;
    ACanvas.Font.Style := SavedStyle;
    ACanvas.Font.Charset := SavedCharset;
  end;
end;

procedure TFormPopupMruList.ActionIconRects(const ACard: TRect; out APropsR, ARemoveR: TRect);
var
  Sz, Gap, Pad, Mid, X: Integer;
begin
  Sz := IconSize;
  Gap := ScaledPx(4);
  Pad := ScaledPx(8);
  Mid := ACard.Top + (ACard.Bottom - ACard.Top - Sz) div 2;
  X := ACard.Right - Pad;
  ARemoveR := Classes.Rect(0, 0, 0, 0);
  APropsR := Classes.Rect(0, 0, 0, 0);
  if Assigned(FOnRemove) then
  begin
    ARemoveR := Classes.Rect(X - Sz, Mid, X, Mid + Sz);
    X := ARemoveR.Left - Gap;
  end;
  if Assigned(FOnProperties) then
    APropsR := Classes.Rect(X - Sz, Mid, X, Mid + Sz);
end;

function TFormPopupMruList.RowActionAt(X, Y: Integer; out AIndex: Integer): Integer;
var
  R, Card, PropsR, RemoveR: TRect;
  Tag: NativeInt;
  Pt: TPoint;
begin
  Result := MRU_ACT_NONE;
  AIndex := -1;
  if not Assigned(lstItems) then Exit;
  AIndex := lstItems.ItemAtPos(Point(X, Y), True);
  if AIndex < 0 then Exit;
  if not FileRowActionsVisible then Exit;
  Tag := ItemTag(AIndex);
  if Tag < 0 then Exit;
  if lstItems.Perform(LB_GETITEMRECT, AIndex, LPARAM(@R)) = LB_ERR then Exit;
  Card := R;
  InflateRect(Card, -ScaledPx(3), -ScaledPx(3));
  ActionIconRects(Card, PropsR, RemoveR);
  Pt := Point(X, Y);
  if Assigned(FOnRemove) and PtInRect(RemoveR, Pt) then
    Result := MRU_ACT_REMOVE
  else if Assigned(FOnProperties) and LooksLikeFilePath(lstItems.Items[AIndex]) and
    PtInRect(PropsR, Pt) then
    Result := MRU_ACT_PROPS;
end;

procedure TFormPopupMruList.DropPathFromList(const APath: string; ANotifyRemove: Boolean);
var
  I: Integer;
begin
  if Trim(APath) = '' then Exit;
  if ANotifyRemove and Assigned(FOnRemove) then
    FOnRemove(Self, APath);
  I := 0;
  while I < FAll.Count do
  begin
    if SameText(FAll[I], APath) then
      FAll.Delete(I)
    else
      Inc(I);
  end;
  if FAll.Count = 0 then
  begin
    ClosePopup(False);
    Exit;
  end;
  if FExpanded and (FAll.Count <= MRU_VISIBLE) then
    FExpanded := False;
  PopulateList;
  PrepareLayout(ClientWidth);
end;

procedure TFormPopupMruList.RunRowAction(AIndex, AAction: Integer);
var
  Tag: NativeInt;
  Path: string;
begin
  if FFilling or FIgnorePick then Exit;
  if (AIndex < 0) or (AIndex >= lstItems.Items.Count) then Exit;
  Tag := ItemTag(AIndex);
  if Tag < 0 then Exit;
  if Tag >= FAll.Count then Exit;
  Path := FAll[Tag];
  if AAction = MRU_ACT_PROPS then
  begin
    if Assigned(FOnProperties) then
    begin
      SetPopupCloseLocked(True);
      FOnProperties(Self, Path);
    end;
    if not FileExists(Path) then
    begin
      SetPopupCloseLocked(False);
      DropPathFromList(Path, False);
    end;
    Exit;
  end;
  if AAction <> MRU_ACT_REMOVE then Exit;
  DropPathFromList(Path, True);
end;

procedure TFormPopupMruList.lstItemsMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Idx, Act: Integer;
begin
  if FFilling or FIgnorePick then Exit;
  if Button <> mbLeft then Exit;
  if not Assigned(lstItems) then Exit;
  Act := RowActionAt(X, Y, Idx);
  if (Idx >= 0) and (Act <> MRU_ACT_NONE) then
  begin
    RunRowAction(Idx, Act);
    Exit;
  end;
  if Idx >= 0 then
    PickIndex(Idx);
end;

procedure TFormPopupMruList.lstItemsMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  Idx, Prev, Act: Integer;
begin
  if not Assigned(lstItems) then Exit;
  Act := RowActionAt(X, Y, Idx);
  if (Idx = FHotIndex) and (Act = FHotAction) then Exit;
  Prev := FHotIndex;
  FHotIndex := Idx;
  FHotAction := Act;
  InvalidateListRow(Prev);
  InvalidateListRow(FHotIndex);
  if Act <> MRU_ACT_NONE then
    lstItems.Cursor := crHandPoint
  else
    lstItems.Cursor := crDefault;
  ApplyItemHint(Idx, Act);
end;

procedure TFormPopupMruList.lstItemsMouseLeave(Sender: TObject);
var
  Prev: Integer;
begin
  if (FHotIndex < 0) and (FHotAction = MRU_ACT_NONE) then Exit;
  Prev := FHotIndex;
  FHotIndex := -1;
  FHotAction := MRU_ACT_NONE;
  if Assigned(lstItems) then
    lstItems.Cursor := crDefault;
  InvalidateListRow(Prev);
  ApplyItemHint(-1);
end;

procedure TFormPopupMruList.lstItemsDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
const
  GLYPH_CLOCK = 2;
  GLYPH_FILE = 3;
  GLYPH_MORE_DOWN = 4;
  GLYPH_MORE_UP = 5;
  GLYPH_SEARCH = 0;
  MRU_MORE_TEXT = $00B06828;
  MRU_CLEAR_ALL_TEXT = $00C04040;
var
  LB: TListBox;
  C: TCanvas;
  Card, IconR, TextR, TitleR, SubR, PropsR, RemoveR: TRect;
  Tag: NativeInt;
  Raw, Title, Sub: string;
  Selected, Hot, IsMore, IsNone, IsClearAll, IsPath, ShowActs, ShowRemove, ShowProps: Boolean;
  IconIdx, Pad, IconSz, Gap, Mid: Integer;
  Flags: UINT;

  procedure DrawActionGlyph(const R: TRect; AGlyph: Integer);
  begin
    if (R.Right <= R.Left) then Exit;
    DrawMruGlyph(C, R.Left, R.Top, AGlyph);
  end;

begin
  LB := Control as TListBox;
  C := LB.Canvas;
  C.Brush.Color := MRU_SURFACE;
  C.Brush.Style := bsSolid;
  C.Pen.Style := psSolid;
  C.FillRect(Rect);
  if (Index < 0) or (Index >= LB.Items.Count) then Exit;

  Tag := ItemTag(Index);
  Raw := LB.Items[Index];
  IsMore := Tag = MRU_OBJ_MORE;
  IsNone := Tag = MRU_OBJ_NONE;
  IsClearAll := Tag = MRU_OBJ_CLEAR_ALL;
  IsPath := (not IsMore) and (not IsNone) and (not IsClearAll) and LooksLikeFilePath(Raw);
  Selected := (odSelected in State) or (LB.ItemIndex = Index);
  Hot := (Index = FHotIndex) and not Selected;

  Card := Rect;
  InflateRect(Card, -ScaledPx(3), -ScaledPx(3));
  if Card.Right <= Card.Left + 8 then Exit;
  PaintMruRowGradient(C, Card, Selected or Hot);

  Pad := ScaledPx(10);
  IconSz := IconSize;
  Gap := ScaledPx(10);
  Mid := Card.Top + (Card.Bottom - Card.Top - IconSz) div 2;
  IconR := Classes.Rect(Card.Left + Pad, Mid, Card.Left + Pad + IconSz, Mid + IconSz);

  if IsMore then
  begin
    if FExpanded then
      IconIdx := GLYPH_MORE_UP
    else
      IconIdx := GLYPH_MORE_DOWN;
  end
  else if IsClearAll then
    IconIdx := GLYPH_REMOVE
  else if IsNone then
    IconIdx := GLYPH_SEARCH
  else if IsPath then
    IconIdx := GLYPH_FILE
  else
    IconIdx := GLYPH_CLOCK;

  DrawMruGlyph(C, IconR.Left, IconR.Top, IconIdx);

  TextR := Card;
  TextR.Left := IconR.Right + Gap;
  TextR.Right := Card.Right - Pad;
  ShowRemove := (not IsMore) and (not IsNone) and (not IsClearAll) and Assigned(FOnRemove);
  ShowProps := IsPath and Assigned(FOnProperties);
  ShowActs := ShowRemove or ShowProps;
  if ShowActs then
  begin
    ActionIconRects(Card, PropsR, RemoveR);
    if ShowProps and (PropsR.Left > TextR.Left) then
      TextR.Right := PropsR.Left - ScaledPx(6)
    else if ShowRemove and (RemoveR.Left > TextR.Left) then
      TextR.Right := RemoveR.Left - ScaledPx(6);
  end;
  if TextR.Right <= TextR.Left then Exit;

  C.Font.Name := UiFontName;
  C.Brush.Style := bsClear;
  Flags := DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX or DT_LEFT;

  if IsMore or IsClearAll then
  begin
    C.Font.Height := ScaledPx(-12);
    C.Font.Style := [fsBold];
    if Selected or Hot then
      C.Font.Color := clHighlight
    else if IsClearAll then
      C.Font.Color := MRU_CLEAR_ALL_TEXT
    else
      C.Font.Color := MRU_MORE_TEXT;
    DrawText(C.Handle, PChar(Raw), Length(Raw), TextR, Flags or DT_VCENTER);
  end
  else if IsPath then
  begin
    Title := ExtractFileName(Raw);
    if Title = '' then
      Title := Raw;
    Sub := ExcludeTrailingPathDelimiter(ExtractFilePath(Raw));
    TitleR := TextR;
    TitleR.Bottom := TitleR.Top + ((TextR.Bottom - TextR.Top) div 2) + ScaledPx(1);
    SubR := TextR;
    SubR.Top := TitleR.Bottom - ScaledPx(1);
    C.Font.Height := ScaledPx(-12);
    C.Font.Style := [fsBold];
    if Selected then
      C.Font.Color := clHighlight
    else
      C.Font.Color := MRU_TEXT;
    DrawText(C.Handle, PChar(Title), Length(Title), TitleR, Flags or DT_BOTTOM);
    C.Font.Height := ScaledPx(-11);
    C.Font.Style := [];
    C.Font.Color := MRU_MUTED;
    if Sub <> '' then
      DrawText(C.Handle, PChar(Sub), Length(Sub), SubR, Flags or DT_TOP);
  end
  else
  begin
    C.Font.Height := ScaledPx(-12);
    if IsNone then
    begin
      C.Font.Style := [];
      C.Font.Color := MRU_MUTED;
    end
    else
    begin
      C.Font.Style := [];
      if Selected then
        C.Font.Color := clHighlight
      else
        C.Font.Color := MRU_TEXT;
    end;
    DrawText(C.Handle, PChar(Raw), Length(Raw), TextR, Flags or DT_VCENTER);
  end;

  if ShowActs then
  begin
    if ShowProps then
      DrawActionGlyph(PropsR, GLYPH_PROPS);
    if ShowRemove then
      DrawActionGlyph(RemoveR, GLYPH_REMOVE);
  end;
end;

procedure TFormPopupMruList.lstItemsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    Key := 0;
    PickIndex(lstItems.ItemIndex);
  end
  else if (Key = VK_DELETE) and (Shift = []) and Assigned(FOnRemove) then
  begin
    Key := 0;
    RunRowAction(lstItems.ItemIndex, MRU_ACT_REMOVE);
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
    Key := 0;
end;

procedure ShowMruListPopup(AOwner: TComponent; const ATitle, AMoreCaption: string;
  AItems: TStrings; AWidth: Integer; const AScreenPos: TPoint;
  AOnPick: TMruListPickEvent; const AMoreHint: string;
  AOnProperties: TMruListPathActionEvent;
  AOnRemove: TMruListPathActionEvent;
  AKeepOpen: TWinControl;
  AOnClearAll: TNotifyEvent);
var
  KeepR: TRect;
begin
  if not Assigned(AItems) or (AItems.Count = 0) then Exit;
  Application.CancelHint;
  if Assigned(FormPopupMruList) and FormPopupMruList.Visible then
    Exit;
  if Assigned(FormPopupMruList) then
  begin
    FormPopupMruList.OnPick := nil;
    FormPopupMruList.OnProperties := nil;
    FormPopupMruList.OnRemove := nil;
    FormPopupMruList.OnClearAll := nil;
    FreeAndNil(FormPopupMruList);
  end;
  FormPopupMruList := TFormPopupMruList.Create(AOwner);
  FormPopupMruList.ShowHint := True;
  FormPopupMruList.OnPick := AOnPick;
  FormPopupMruList.OnProperties := AOnProperties;
  FormPopupMruList.OnRemove := AOnRemove;
  FormPopupMruList.OnClearAll := AOnClearAll;
  if Assigned(AKeepOpen) and AKeepOpen.HandleAllocated then
  begin
    GetWindowRect(AKeepOpen.Handle, KeepR);
    InflateRect(KeepR, 4, 4);
    FormPopupMruList.FKeepOpenRect := KeepR;
  end
  else
    FormPopupMruList.FKeepOpenRect := Rect(0, 0, 0, 0);
  FormPopupMruList.LoadList(ATitle, AMoreCaption, AItems, AMoreHint);
  FormPopupMruList.PrepareLayout(AWidth);
  FormPopupMruList.HandleNeeded;
  if DefaultManager <> nil then
    DefaultManager.UpdateScale(FormPopupMruList);
  FormPopupMruList.PrepareLayout(AWidth);
  FormPopupMruList.PlaceAndShowStandalone(AScreenPos);
  if Assigned(FormPopupMruList.lstItems) and FormPopupMruList.lstItems.HandleAllocated then
    FormPopupMruList.lstItems.Invalidate;
end;

end.
