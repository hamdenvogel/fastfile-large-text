unit uFastFileScale;

{
  DPI + work-area helpers so FastFile windows and runtime-created panels
  follow Windows scale (100/125/150/200%) and stay inside the monitor.
}

interface

uses
  Windows, Messages, Types, Classes, Controls, Forms, SysUtils;

function FfCurrentPPI: Integer;
function FfPx(ADesignPx: Integer): Integer;
procedure FfWorkAreaOf(AForm: TCustomForm; out ARect: TRect);
procedure FfRelaxMinConstraints(AForm: TCustomForm);
procedure FfFitFormToWorkArea(AForm: TCustomForm);
procedure FfInstallFormLayoutManager;
procedure FfPrepareDialog(AForm: TCustomForm; ADesignClientW, ADesignClientH: Integer);
function FfCapSidePanelWidth(AHostClientW, AWantW: Integer; AMinDesign: Integer = 240): Integer;
procedure FfClampSizeToWorkArea(var ALeft, ATop, AWidth, AHeight: Integer);
{ Widens buttons, check boxes, radio buttons and fixed-width labels whose single-line
  caption is clipped (translation, font, scale). Grow-only and only into free space:
  nothing is moved over a neighbour, shrunk or moved vertically. Re-measures only when
  the language, the PPI or the layout of AForm changed, unless AForce.
  Opt-out: HelpKeyword = 'ff-nofit' on a control skips it and its children. }
procedure FfFitCaptions(AForm: TCustomForm; AForce: Boolean = False);

implementation

uses
  Math, Graphics, StdCtrls, Buttons, ComCtrls, ExtCtrls, TypInfo, uI18n;

type
  TFfFormLayoutManager = class
  private
    FPreviousActiveFormChange: TNotifyEvent;
    FAdjusting: Boolean;
    FTimer: TTimer;
    { Hidden top-level window: receives the WM_DISPLAYCHANGE / WM_SETTINGCHANGE broadcasts. }
    FWnd: HWND;
    FDisplayTimer: TTimer;
    procedure ActiveFormChanged(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure WndProc(var Msg: TMessage);
    procedure DisplayTimerTick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { Last fitted layout signature per form; entries leave with their form (free notification). }
  TFfFitSigs = class(TComponent)
  public
    Sigs: TStringList;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Get(AForm: TComponent): string;
    procedure Put(AForm: TComponent; const ASig: string);
    procedure Remove(AForm: TComponent);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  end;

  THackControl = class(TControl);

var
  FFFormLayoutManager: TFfFormLayoutManager;
  FFMeasure: TBitmap;
  FFFitSigs: TFfFitSigs;
  { Controls whose Hint was set here (text = that hint), so it can follow the caption or be removed. }
  FFAutoHints: TFfFitSigs;

constructor TFfFitSigs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Sigs := TStringList.Create;
end;

destructor TFfFitSigs.Destroy;
begin
  FreeAndNil(Sigs);
  inherited Destroy;
end;

function TFfFitSigs.Get(AForm: TComponent): string;
var
  I: Integer;
begin
  I := Sigs.IndexOfObject(AForm);
  if I >= 0 then
    Result := Sigs[I]
  else
    Result := '';
end;

procedure TFfFitSigs.Put(AForm: TComponent; const ASig: string);
var
  I: Integer;
begin
  I := Sigs.IndexOfObject(AForm);
  if I >= 0 then
    Sigs[I] := ASig
  else
  begin
    Sigs.AddObject(ASig, AForm);
    AForm.FreeNotification(Self);
  end;
end;

procedure TFfFitSigs.Remove(AForm: TComponent);
var
  I: Integer;
begin
  I := Sigs.IndexOfObject(AForm);
  if I >= 0 then
  begin
    Sigs.Delete(I);
    AForm.RemoveFreeNotification(Self);
  end;
end;

procedure TFfFitSigs.Notification(AComponent: TComponent; Operation: TOperation);
var
  I: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(Sigs) then
  begin
    I := Sigs.IndexOfObject(AComponent);
    if I >= 0 then
      Sigs.Delete(I);
  end;
end;

constructor TFfFormLayoutManager.Create;
begin
  inherited Create;
  FPreviousActiveFormChange := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := ActiveFormChanged;
  { Tabs and panels created later inside an already active form (and language / scale
    switches) are picked up here; a tick that finds nothing changed only counts controls. }
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1500;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
  { Windows sends several messages while it switches resolution: act once, after they settle. }
  FDisplayTimer := TTimer.Create(nil);
  FDisplayTimer.Enabled := False;
  FDisplayTimer.Interval := 600;
  FDisplayTimer.OnTimer := DisplayTimerTick;
  FWnd := AllocateHWnd(WndProc);
end;

destructor TFfFormLayoutManager.Destroy;
begin
  if FWnd <> 0 then
    DeallocateHWnd(FWnd);
  FWnd := 0;
  FreeAndNil(FDisplayTimer);
  FreeAndNil(FTimer);
  Screen.OnActiveFormChange := FPreviousActiveFormChange;
  inherited Destroy;
end;

procedure TFfFormLayoutManager.ActiveFormChanged(Sender: TObject);
var
  ActiveForm: TCustomForm;
begin
  if Assigned(FPreviousActiveFormChange) then
    FPreviousActiveFormChange(Sender);
  if FAdjusting then Exit;
  ActiveForm := Screen.ActiveForm;
  if not Assigned(ActiveForm) or not ActiveForm.Visible then Exit;
  FAdjusting := True;
  try
    FfFitFormToWorkArea(ActiveForm);
    FfFitCaptions(ActiveForm);
  finally
    FAdjusting := False;
  end;
end;

procedure TFfFormLayoutManager.TimerTick(Sender: TObject);
var
  F: TCustomForm;
begin
  { Not while the user drags a splitter / window edge. }
  if FAdjusting or (GetKeyState(VK_LBUTTON) < 0) then Exit;
  F := Screen.ActiveForm;
  if not Assigned(F) or not F.Visible or (csDestroying in F.ComponentState) then Exit;
  FAdjusting := True;
  try
    FfFitCaptions(F);
  finally
    FAdjusting := False;
  end;
end;

procedure TFfFormLayoutManager.WndProc(var Msg: TMessage);
begin
  if (Msg.Msg = WM_DISPLAYCHANGE) or
     ((Msg.Msg = WM_SETTINGCHANGE) and (Msg.WParam = SPI_SETWORKAREA)) then
  begin
    { Restart the debounce on every message of the burst. }
    FDisplayTimer.Enabled := False;
    FDisplayTimer.Enabled := True;
  end;
  Msg.Result := DefWindowProc(FWnd, Msg.Msg, Msg.WParam, Msg.LParam);
end;

{ New resolution or work area: every visible top-level form back inside its monitor, captions re-fitted. }
procedure TFfFormLayoutManager.DisplayTimerTick(Sender: TObject);
var
  I: Integer;
  F: TCustomForm;
begin
  FDisplayTimer.Enabled := False;
  if FAdjusting then
  begin
    FDisplayTimer.Enabled := True;
    Exit;
  end;
  FAdjusting := True;
  try
    for I := Screen.CustomFormCount - 1 downto 0 do
    begin
      F := Screen.CustomForms[I];
      if (F = nil) or (csDestroying in F.ComponentState) or not F.Visible then Continue;
      try
        if F.Parent = nil then
          FfFitFormToWorkArea(F);
        FfFitCaptions(F, True);
      except
        { One form failing must not stop the others. }
      end;
    end;
  finally
    FAdjusting := False;
  end;
end;

{ ---- caption fitting ---- }

function PropOrd(AObj: TObject; const AName: string; out AValue: Integer): Boolean;
var
  PI: PPropInfo;
begin
  Result := False;
  AValue := 0;
  PI := GetPropInfo(AObj, AName);
  if (PI = nil) or not (PI^.PropType^^.Kind in [tkEnumeration, tkInteger, tkSet]) then Exit;
  AValue := GetOrdProp(AObj, PI);
  Result := True;
end;

function PropIsTrue(AObj: TObject; const AName: string): Boolean;
var
  V: Integer;
begin
  Result := PropOrd(AObj, AName, V) and (V <> 0);
end;

function PropIsFalse(AObj: TObject; const AName: string): Boolean;
var
  V: Integer;
begin
  Result := PropOrd(AObj, AName, V) and (V = 0);
end;

{ Glyph beside the text (not above / below it). }
function HasSideGlyph(C: TControl): Boolean;
var
  V: Integer;
  PI: PPropInfo;
  O: TObject;
begin
  Result := False;
  if PropOrd(C, 'Layout', V) and (V in [Ord(blGlyphTop), Ord(blGlyphBottom)]) then Exit;
  PI := GetPropInfo(C, 'Images');
  if (PI <> nil) and (PI^.PropType^^.Kind = tkClass) and (GetObjectProp(C, PI) <> nil) and
     PropOrd(C, 'ImageIndex', V) and (V >= 0) then
    Exit(True);
  PI := GetPropInfo(C, 'Glyph');
  if (PI <> nil) and (PI^.PropType^^.Kind = tkClass) then
  begin
    O := GetObjectProp(C, PI);
    if (O is TBitmap) and not TBitmap(O).Empty then
      Exit(True);
  end;
end;

function Px(AValue, APPI: Integer): Integer;
begin
  Result := MulDiv(AValue, APPI, 96);
end;

function OverlapsVert(A, B: TControl): Boolean;
begin
  Result := (A.Top < B.Top + B.Height) and (A.Top + A.Height > B.Top);
end;

{ Clipped even after growing: the full caption as hint. A hint set by the form itself is never touched. }
procedure AutoHint(C: TControl; const ACap: string; AClipped: Boolean);
var
  Ours: string;
begin
  if FFAutoHints = nil then
    FFAutoHints := TFfFitSigs.Create(nil);
  Ours := FFAutoHints.Get(C);
  if AClipped then
  begin
    if (C.Hint = '') or ((Ours <> '') and (C.Hint = Ours)) then
    begin
      C.Hint := ACap;
      C.ShowHint := True;
      FFAutoHints.Put(C, ACap);
    end;
  end
  else if (Ours <> '') and (C.Hint = Ours) then
  begin
    C.Hint := '';
    FFAutoHints.Remove(C);
  end;
end;

procedure GrowInto(C: TControl; AIsLabel: Boolean; ANeed, APPI: Integer);
var
  Grow, Free, Limit, I, Used, V: Integer;
  P: TWinControl;
  S: TControl;
  HasClient, GrowLeft: Boolean;
begin
  P := C.Parent;
  Grow := ANeed - C.Width;
  if Grow <= 0 then Exit;

  GrowLeft := False;
  if C.Align = alNone then
  begin
    { Right-anchored, or a right-justified label: its right edge stays put. }
    GrowLeft := ((akRight in C.Anchors) and not (akLeft in C.Anchors)) or
      (AIsLabel and PropOrd(C, 'Alignment', V) and (V = Ord(taRightJustify)));
    if AIsLabel and PropOrd(C, 'Alignment', V) and (V = Ord(taCenter)) then Exit;
    if GrowLeft then
    begin
      Limit := Px(2, APPI);
      for I := 0 to P.ControlCount - 1 do
      begin
        S := P.Controls[I];
        if (S <> C) and OverlapsVert(S, C) and (S.Left + S.Width <= C.Left + 1) then
          Limit := Max(Limit, S.Left + S.Width + Px(4, APPI));
      end;
      Free := C.Left - Limit;
    end
    else
    begin
      Limit := P.ClientWidth - Px(2, APPI);
      for I := 0 to P.ControlCount - 1 do
      begin
        S := P.Controls[I];
        if (S <> C) and OverlapsVert(S, C) and (S.Left >= C.Left + C.Width - 1) then
          Limit := Min(Limit, S.Left - Px(4, APPI));
      end;
      Free := Limit - (C.Left + C.Width);
    end;
  end
  else
  begin
    { Docked in a row: the row may not overflow, and a client-aligned neighbour keeps some room. }
    Used := 0;
    HasClient := False;
    for I := 0 to P.ControlCount - 1 do
    begin
      S := P.Controls[I];
      if not S.Visible then Continue;
      if S.Align in [alLeft, alRight] then
        Inc(Used, S.Width + S.Margins.Left * Ord(S.AlignWithMargins) + S.Margins.Right * Ord(S.AlignWithMargins))
      else if S.Align = alClient then
        HasClient := True;
    end;
    Free := P.ClientWidth - Used;
    if HasClient then
      Dec(Free, Px(120, APPI));
  end;
  Grow := Min(Grow, Free);
  if Grow <= 0 then Exit;
  if GrowLeft then
    C.SetBounds(C.Left - Grow, C.Top, C.Width + Grow, C.Height)
  else
    C.Width := C.Width + Grow;
end;

procedure FitControl(C: TControl; APPI: Integer);
type
  TKind = (kLabel, kCheck, kButton);
var
  Kind: TKind;
  Cap: string;
  R: TRect;
  Need: Integer;
  P: TWinControl;
  CanGrow: Boolean;
begin
  P := C.Parent;
  if (P = nil) or (P.ClientWidth <= 0) or not C.Visible then Exit;
  if C is TCustomLabel then
    Kind := kLabel
  else if (C is TCustomCheckBox) or (C is TRadioButton) or SameText(C.ClassName, 'TsCheckBox') or
    SameText(C.ClassName, 'TsRadioButton') then
    Kind := kCheck
  else if (C is TButtonControl) or (C is TSpeedButton) then
    Kind := kButton
  else
    Exit;
  if PropIsTrue(C, 'AutoSize') or PropIsTrue(C, 'WordWrap') or PropIsFalse(C, 'ShowCaption') then Exit;
  Cap := THackControl(C).Caption;
  if (Trim(Cap) = '') or (Pos(#10, Cap) > 0) or (Pos(#13, Cap) > 0) then Exit;
  { Stretched or client-aligned controls are sized by their parent: hint only, never resized here. }
  CanGrow := (C.Align in [alNone, alLeft, alRight]) and
    not ((C.Align = alNone) and (akLeft in C.Anchors) and (akRight in C.Anchors));

  FFMeasure.Canvas.Font.Assign(THackControl(C).Font);
  R := Rect(0, 0, 0, 0);
  DrawText(FFMeasure.Canvas.Handle, PChar(Cap), Length(Cap), R, DT_CALCRECT or DT_SINGLELINE);
  Need := R.Right - R.Left;
  case Kind of
    kLabel: Inc(Need, Px(2, APPI));
    kCheck: Inc(Need, Px(24, APPI));
  else
    Inc(Need, Px(18, APPI));
    if HasSideGlyph(C) then
      Inc(Need, Px(22, APPI));
  end;
  try
    if CanGrow then
      if C.Constraints.MaxWidth > 0 then
        GrowInto(C, Kind = kLabel, Min(Need, C.Constraints.MaxWidth), APPI)
      else
        GrowInto(C, Kind = kLabel, Need, APPI);
  finally
    AutoHint(C, Cap, Need > C.Width);
  end;
end;

procedure FitTree(AParent: TWinControl; APPI: Integer);
var
  I: Integer;
  C: TControl;
begin
  if (AParent is TToolBar) or SameText(AParent.HelpKeyword, 'ff-nofit') then Exit;
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    if SameText(C.HelpKeyword, 'ff-nofit') then Continue;
    try
      FitControl(C, APPI);
    except
      { A third-party control refusing a width must not break the form. }
    end;
    if C is TWinControl then
      FitTree(TWinControl(C), APPI);
  end;
end;

{$Q-}{$R-}
{ Cheap (no window messages): control count and geometry of the whole tree. }
procedure LayoutSig(AParent: TWinControl; var ACount: Integer; var AHash: Int64);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    Inc(ACount);
    AHash := AHash * 31 + C.Width * 7 + C.Left + Ord(C.Visible);
    if C is TWinControl then
      LayoutSig(TWinControl(C), ACount, AHash);
  end;
end;

function FormSig(AForm: TCustomForm): string;
var
  N: Integer;
  H: Int64;
begin
  N := 0;
  H := 0;
  LayoutSig(AForm, N, H);
  Result := Format('%d|%d|%d|%d', [AForm.CurrentPPI, Ord(GetCurrentLanguage), N, H]);
end;

procedure FfFitCaptions(AForm: TCustomForm; AForce: Boolean);
var
  PPI: Integer;
begin
  if not Assigned(AForm) or (csDestroying in AForm.ComponentState) or
     (csDesigning in AForm.ComponentState) or not AForm.HandleAllocated then Exit;
  if FFFitSigs = nil then
    FFFitSigs := TFfFitSigs.Create(nil);
  if (not AForce) and (FFFitSigs.Get(AForm) = FormSig(AForm)) then Exit;
  if FFMeasure = nil then
    FFMeasure := TBitmap.Create;
  PPI := AForm.CurrentPPI;
  if PPI < 96 then
    PPI := 96;
  try
    FitTree(AForm, PPI);
  except
  end;
  FFFitSigs.Put(AForm, FormSig(AForm));
end;

procedure FfInstallFormLayoutManager;
begin
  if not Assigned(FFFormLayoutManager) then
    FFFormLayoutManager := TFfFormLayoutManager.Create;
end;

function FfCurrentPPI: Integer;
var
  F: TCustomForm;
begin
  Result := 96;
  F := Application.MainForm;
  if Assigned(F) and (F.CurrentPPI > 0) then
    Result := F.CurrentPPI
  else if Screen.PixelsPerInch > 0 then
    Result := Screen.PixelsPerInch;
  if Result < 96 then
    Result := 96;
end;

function FfPx(ADesignPx: Integer): Integer;
begin
  if ADesignPx <= 0 then
  begin
    Result := ADesignPx;
    Exit;
  end;
  Result := MulDiv(ADesignPx, FfCurrentPPI, 96);
end;

procedure FfWorkAreaOf(AForm: TCustomForm; out ARect: TRect);
var
  M: TMonitor;
begin
  M := nil;
  if Assigned(AForm) and AForm.HandleAllocated then
    M := Screen.MonitorFromWindow(AForm.Handle)
  else if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
    M := Screen.MonitorFromWindow(Application.MainForm.Handle);
  if Assigned(M) then
    ARect := M.WorkareaRect
  else
    ARect := Rect(0, 0, Screen.WorkAreaWidth, Screen.WorkAreaHeight);
end;

procedure FfRelaxMinConstraints(AForm: TCustomForm);
var
  R: TRect;
  MaxW, MaxH: Integer;
begin
  if not Assigned(AForm) then Exit;
  FfWorkAreaOf(AForm, R);
  MaxW := (R.Right - R.Left) - 8;
  MaxH := (R.Bottom - R.Top) - 8;
  if MaxW < 320 then MaxW := 320;
  if MaxH < 240 then MaxH := 240;
  if (AForm.Constraints.MinWidth > 0) and (AForm.Constraints.MinWidth > MaxW) then
    AForm.Constraints.MinWidth := MaxW;
  if (AForm.Constraints.MinHeight > 0) and (AForm.Constraints.MinHeight > MaxH) then
    AForm.Constraints.MinHeight := MaxH;
  if AForm.Width > MaxW then
    AForm.Width := MaxW;
  if AForm.Height > MaxH then
    AForm.Height := MaxH;
end;

procedure FfFitFormToWorkArea(AForm: TCustomForm);
var
  L, T, W, H: Integer;
  R: TRect;
  MaxW, MaxH: Integer;
  NeedsScroll: Boolean;
begin
  if not Assigned(AForm) then Exit;
  FfWorkAreaOf(AForm, R);
  MaxW := (R.Right - R.Left) - 8;
  MaxH := (R.Bottom - R.Top) - 8;
  NeedsScroll := (AForm.Width > MaxW) or (AForm.Height > MaxH);
  if (AForm = Application.MainForm) or (AForm.WindowState = wsMaximized) then
    TForm(AForm).AutoScroll := False
  else if NeedsScroll then
    TForm(AForm).AutoScroll := True;
  FfRelaxMinConstraints(AForm);
  if AForm.WindowState = wsMaximized then Exit;
  L := AForm.Left;
  T := AForm.Top;
  W := AForm.Width;
  H := AForm.Height;
  FfClampSizeToWorkArea(L, T, W, H);
  if (L <> AForm.Left) or (T <> AForm.Top) or (W <> AForm.Width) or (H <> AForm.Height) then
    AForm.SetBounds(L, T, W, H);
end;

procedure FfPrepareDialog(AForm: TCustomForm; ADesignClientW, ADesignClientH: Integer);
var
  R: TRect;
  WorkW, WorkH, ChromeW, ChromeH, MaxCW, MaxCH, W, H, L, T: Integer;
begin
  if not Assigned(AForm) then Exit;
  FfWorkAreaOf(AForm, R);
  WorkW := R.Right - R.Left;
  WorkH := R.Bottom - R.Top;
  ChromeW := AForm.Width - AForm.ClientWidth;
  ChromeH := AForm.Height - AForm.ClientHeight;
  if ChromeW < 16 then ChromeW := 16;
  if ChromeH < 40 then ChromeH := 40;
  MaxCW := WorkW - ChromeW - 16;
  MaxCH := WorkH - ChromeH - 16;
  if MaxCW < 200 then MaxCW := 200;
  if MaxCH < 160 then MaxCH := 160;
  W := FfPx(ADesignClientW);
  H := FfPx(ADesignClientH);
  if W > MaxCW then W := MaxCW;
  if H > MaxCH then H := MaxCH;
  AForm.ClientWidth := W;
  AForm.ClientHeight := H;
  L := R.Left + (WorkW - AForm.Width) div 2;
  T := R.Top + (WorkH - AForm.Height) div 2;
  AForm.SetBounds(L, T, AForm.Width, AForm.Height);
  FfFitFormToWorkArea(AForm);
end;

function FfCapSidePanelWidth(AHostClientW, AWantW: Integer; AMinDesign: Integer): Integer;
var
  MinW, MaxW: Integer;
begin
  MinW := FfPx(AMinDesign);
  Result := AWantW;
  if Result < MinW then
    Result := MinW;
  if AHostClientW <= 0 then Exit;
  MaxW := AHostClientW * 42 div 100;
  if MaxW < MinW then
    MaxW := AHostClientW * 55 div 100;
  if MaxW < MinW then
    MaxW := MinW;
  if Result > MaxW then
    Result := MaxW;
end;

procedure FfClampSizeToWorkArea(var ALeft, ATop, AWidth, AHeight: Integer);
var
  R: TRect;
  WorkW, WorkH: Integer;
  M: TMonitor;
begin
  M := Screen.MonitorFromPoint(Point(ALeft + AWidth div 2, ATop + AHeight div 2));
  if Assigned(M) then
    R := M.WorkareaRect
  else
    R := Rect(0, 0, Screen.WorkAreaWidth, Screen.WorkAreaHeight);
  WorkW := R.Right - R.Left;
  WorkH := R.Bottom - R.Top;
  if AWidth > WorkW then
    AWidth := WorkW;
  if AHeight > WorkH then
    AHeight := WorkH;
  if AWidth < 160 then
    AWidth := 160;
  if AHeight < 120 then
    AHeight := 120;
  if ALeft + AWidth > R.Right then
    ALeft := R.Right - AWidth;
  if ATop + AHeight > R.Bottom then
    ATop := R.Bottom - AHeight;
  if ALeft < R.Left then
    ALeft := R.Left;
  if ATop < R.Top then
    ATop := R.Top;
end;

initialization

finalization
  FreeAndNil(FFFormLayoutManager);
  FreeAndNil(FFFitSigs);
  FreeAndNil(FFAutoHints);
  FreeAndNil(FFMeasure);

end.
