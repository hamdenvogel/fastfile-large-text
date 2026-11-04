unit uBidiLayout;

{ Right-to-left (BiDiMode) support for the whole application.

  Direction
    BidiIsRtl follows the UI language (Arabic / Hebrew = right-to-left) unless the
    hidden "Change BidiMode" toolbar button forced a manual override.
    Application.BiDiMode drives the text direction / alignment / reading order of
    every control that has ParentBiDiMode = True (VCL does the rest, including the
    VCL message dialogs).

  Layout
    VCL never mirrors positions by itself. This unit mirrors the geometry of every
    control inside its parent (Left, alLeft <-> alRight, akLeft <-> akRight, Margins,
    Padding, status-bar panels, AlphaControls "reflect layout") exactly once: each
    mirrored control carries a TBidiMark (owned component), so the pass is idempotent
    and can be repeated for controls created later.

  Usage
    * Form with all controls built:         BidiApplyForm(Self);
    * Panel/controls built after the form:  BidiApplyControl(APanel);
    * Code that (re)positions children with absolute Left values / Align / Anchors
      in left-to-right terms (layout procedures, OnResize handlers):
          var BL: IInterface;
          BL := BidiLayoutScope([Panel1, Panel2]);   // left in LTR picture ... mirrored again on exit
    * Content views (file text, editors of raw data) keep LTR:  BidiKeepLtr(Control);
    * Custom painting: BidiX / BidiRect / BidiDrawFlags / BidiAlignment.
    * Native Windows message boxes:  Flags or BidiMsgBoxFlags. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, uI18n;

type
  TBidiMark = class(TComponent)
  public
    Geo: Boolean;    { geometry of this control is mirrored inside its parent }
    Inner: Boolean;  { padding / inner structure of this container is mirrored }
    Keep: Boolean;   { content control: text direction forced to left-to-right }
    Scope: Integer;  { nesting depth of BidiBeginLayout (children shown left-to-right) }
  end;

{ --- direction ------------------------------------------------------------- }
function BidiIsRtl: Boolean;
{ Manual override of the language-driven direction (hidden toolbar button). }
procedure BidiSetManual(ARtl: Boolean);
procedure BidiClearManual;
function BidiHasManual: Boolean;

{ Application.BiDiMode + Screen hook (call once after Application.Initialize and
  again when the language changes). }
procedure BidiSyncApplication;

{ Pause the periodic re-apply timer (language switch, heavy layout, shutdown).
  Nestable; each Suspend needs a matching Resume. }
procedure BidiSuspendUpdates;
procedure BidiResumeUpdates;
{ Kill the BiDi timer for good (application shutdown). }
procedure BidiShutdown;

{ --- layout ---------------------------------------------------------------- }
procedure BidiApplyForm(AForm: TCustomForm);
procedure BidiApplyControl(AContainer: TWinControl);
procedure BidiApplyAllForms;

{ The control and its descendants keep a left-to-right text direction (file
  content, code editors); its position inside the parent is still mirrored. }
procedure BidiKeepLtr(AControl: TControl);

procedure BidiBeginLayout(AContainer: TWinControl);
procedure BidiEndLayout(AContainer: TWinControl);

{ Scope form: keep the returned interface in a local variable. Begin runs now and
  End runs when the variable goes out of scope (also on Exit / exceptions):
      var BL: IInterface;
      begin
        BL := BidiLayoutScope([pnlTop, pnlBottom]);
        ... positions with absolute left-to-right Left values ... }
function BidiLayoutScope(const AContainers: array of TWinControl): IInterface;

{ Parent of a control that may be nil (convenient inside BidiLayoutScope([...])). }
function BidiParentOf(AControl: TControl): TWinControl;

{ --- helpers for custom painting / positioning ----------------------------- }
function BidiX(AWidth, X: Integer): Integer;
function BidiLeft(AParentWidth, ALeft, AWidth: Integer): Integer;
function BidiRect(const R: TRect; AWidth: Integer): TRect;
function BidiDrawFlags(AFlags: UINT): UINT;
function BidiAlignment(AAlignment: TAlignment): TAlignment;
function BidiAlignFor(AAlign: TAlign): TAlign;
function BidiMsgBoxFlags: UINT;

{ False when AControl (or an ancestor) was forced to left-to-right. }
function BidiControlIsRtl(AControl: TControl): Boolean;

implementation

uses
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Menus,
  sMessages, sStatusBar;

const
  cMarkName = 'FfBidiMark';

type
  TControlAccess = class(TControl);

var
  GManual: Integer = -1;  { -1 = follow language, 0 = LTR, 1 = RTL }
  GManualLang: TAppLanguage = alEnglish;
  GPrevActiveFormChange: TNotifyEvent = nil;
  GHooked: Boolean = False;

{ --- direction ------------------------------------------------------------- }

function BidiIsRtl: Boolean;
begin
  { choosing another UI language drops the manual override }
  if (GManual >= 0) and (GetCurrentLanguage <> GManualLang) then
    GManual := -1;
  case GManual of
    0: Result := False;
    1: Result := True;
  else
    Result := IsRtlLanguage(GetCurrentLanguage);
  end;
end;

procedure BidiSetManual(ARtl: Boolean);
begin
  if ARtl then GManual := 1 else GManual := 0;
  GManualLang := GetCurrentLanguage;
end;

procedure BidiClearManual;
begin
  GManual := -1;
end;

function BidiHasManual: Boolean;
begin
  Result := GManual >= 0;
end;

{ --- marks ----------------------------------------------------------------- }

function FindMark(AComp: TComponent; ACreate: Boolean): TBidiMark;
var
  C: TComponent;
begin
  Result := nil;
  if AComp = nil then Exit;
  C := AComp.FindComponent(cMarkName);
  if C is TBidiMark then
    Result := TBidiMark(C)
  else if ACreate and not (csDestroying in AComp.ComponentState) then
  begin
    Result := TBidiMark.Create(AComp);
    Result.Name := cMarkName;
  end;
end;

{ --- geometry -------------------------------------------------------------- }

procedure FlipAnchors(C: TControl);
var
  A: TAnchors;
begin
  A := C.Anchors;
  if (akLeft in A) and not (akRight in A) then
    C.Anchors := A - [akLeft] + [akRight]
  else if (akRight in A) and not (akLeft in A) then
    C.Anchors := A - [akRight] + [akLeft];
end;

procedure FlipMargins(C: TControl);
var
  L, R: Integer;
begin
  L := C.Margins.Left;
  R := C.Margins.Right;
  if L <> R then
  begin
    C.Margins.Left := R;
    C.Margins.Right := L;
  end;
end;

{ Parents whose children are positioned by the parent itself. }
function ChildrenArePositionedByParent(P: TWinControl): Boolean;
begin
  Result := P is TCustomTabControl;
end;

procedure FlipChild(C: TControl; W: Integer);
begin
  case C.Align of
    alNone:
      begin
        C.Left := W - C.Left - C.Width;
        FlipAnchors(C);
      end;
    alLeft:
      begin
        C.Left := W - C.Left - C.Width;
        C.Align := alRight;
      end;
    alRight:
      begin
        C.Left := W - C.Left - C.Width;
        C.Align := alLeft;
      end;
  end;
  FlipMargins(C);
  C.Perform(SM_ALPHACMD, MakeWParam(0, AC_REFLECTLAYOUT), 0);
end;

procedure FlipInner(C: TWinControl);
var
  L, R: Integer;
begin
  L := C.Padding.Left;
  R := C.Padding.Right;
  if L <> R then
  begin
    C.Padding.Left := R;
    C.Padding.Right := L;
  end;
  if C is TsStatusBar then
    TsStatusBar(C).ReflectPanels;
end;

{ Mirrors (ARtl = True) or restores (ARtl = False) the direct children of C. Only
  children whose mark differs from the wanted state are touched. }
procedure MirrorChildren(C: TWinControl; ARtl: Boolean);
var
  I, W: Integer;
  Ctl: TControl;
  CM: TBidiMark;
  HaveMirrored, HavePlain: Boolean;
begin
  if (C = nil) or (csDestroying in C.ComponentState) or (C.ControlCount = 0) then Exit;

  if ChildrenArePositionedByParent(C) then
  begin
    { tab sheets etc. are placed by the parent: only remember the state }
    for I := 0 to C.ControlCount - 1 do
    begin
      CM := FindMark(C.Controls[I], ARtl);
      if CM <> nil then
        CM.Geo := ARtl;
    end;
    Exit;
  end;

  HaveMirrored := False;
  HavePlain := False;
  for I := 0 to C.ControlCount - 1 do
  begin
    CM := FindMark(C.Controls[I], False);
    if (CM <> nil) and CM.Geo then
      HaveMirrored := True
    else
      HavePlain := True;
  end;
  if (not ARtl) and (not HaveMirrored) then Exit;
  if ARtl and (not HavePlain) then Exit;

  W := C.ClientWidth;
  C.DisableAlign;
  try
    { Mixed state (controls created after the first pass): go back to the
      left-to-right picture first so VCL aligns old and new siblings together. }
    if ARtl and HaveMirrored and HavePlain then
      for I := 0 to C.ControlCount - 1 do
      begin
        Ctl := C.Controls[I];
        CM := FindMark(Ctl, False);
        if (CM <> nil) and CM.Geo then
        begin
          FlipChild(Ctl, W);
          CM.Geo := False;
        end;
      end;
    for I := 0 to C.ControlCount - 1 do
    begin
      Ctl := C.Controls[I];
      CM := FindMark(Ctl, ARtl);
      if (CM <> nil) and (CM.Geo <> ARtl) then
      begin
        FlipChild(Ctl, W);
        CM.Geo := ARtl;
      end;
    end;
  finally
    C.EnableAlign;
  end;
end;

procedure ApplyContainer(C: TWinControl; ARtl: Boolean);
var
  I: Integer;
  M: TBidiMark;
begin
  if (C = nil) or (csDestroying in C.ComponentState) then Exit;

  { Marks are only created when something is mirrored (nothing to remember in LTR). }
  M := FindMark(C, ARtl);
  if (M <> nil) and (M.Inner <> ARtl) then
  begin
    FlipInner(C);
    M.Inner := ARtl;
  end;

  { inside a layout scope the children are deliberately shown left-to-right }
  if (M = nil) or (M.Scope = 0) or (not ARtl) then
    MirrorChildren(C, ARtl);

  for I := 0 to C.ControlCount - 1 do
    if C.Controls[I] is TWinControl then
      ApplyContainer(TWinControl(C.Controls[I]), ARtl);
end;

{ --- text direction -------------------------------------------------------- }

procedure ApplyKeepLtr(C: TControl);
var
  I: Integer;
begin
  if C = nil then Exit;
  TControlAccess(C).ParentBiDiMode := False;
  TControlAccess(C).BiDiMode := bdLeftToRight;
  if C is TWinControl then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      ApplyKeepLtr(TWinControl(C).Controls[I]);
end;

procedure BidiKeepLtr(AControl: TControl);
var
  M: TBidiMark;
begin
  if AControl = nil then Exit;
  M := FindMark(AControl, True);
  if M <> nil then
    M.Keep := True;
  ApplyKeepLtr(AControl);
end;

procedure ReapplyKeepLtr(C: TWinControl);
var
  I: Integer;
  M: TBidiMark;
begin
  for I := 0 to C.ControlCount - 1 do
  begin
    M := FindMark(C.Controls[I], False);
    if (M <> nil) and M.Keep then
      ApplyKeepLtr(C.Controls[I])
    else if C.Controls[I] is TWinControl then
      ReapplyKeepLtr(TWinControl(C.Controls[I]));
  end;
end;

{ Safety net: any form that reaches the screen without an explicit BidiApplyForm
  (ad-hoc dialogs) is mirrored when it first becomes active. }
type
  TBidiHooks = class
    procedure ActiveFormChanged(Sender: TObject);
  end;

var
  GHooks: TBidiHooks = nil;
  GWndHook: HHOOK = 0;
  GTimer: UINT_PTR = 0;
  GInPass: Boolean = False;
  GSuspendCount: Integer = 0;

procedure TBidiHooks.ActiveFormChanged(Sender: TObject);
begin
  if Assigned(GPrevActiveFormChange) then
    GPrevActiveFormChange(Sender);
  if (GSuspendCount > 0) then Exit;
  if (Screen.ActiveForm <> nil) and BidiIsRtl and
     (FindMark(Screen.ActiveForm, False) = nil) then
    BidiApplyForm(Screen.ActiveForm);
end;

{ Every form (including ad-hoc dialogs and VCL message boxes) is mirrored right
  before Windows shows it: WM_SHOWWINDOW sent by ShowWindow (lParam = 0). }
function BidiCallWndHook(Code: Integer; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  P: PCWPStruct;
  C: TWinControl;
begin
  if (Code = HC_ACTION) and (GSuspendCount = 0) then
  begin
    P := PCWPStruct(LParam);
    if (P <> nil) and (P^.message = WM_SHOWWINDOW) and (P^.wParam <> 0) and
       (P^.lParam = 0) then
    begin
      C := FindControl(P^.hwnd);
      if (C is TCustomForm) and BidiIsRtl then
      try
        BidiApplyForm(TCustomForm(C));
      except
      end;
    end;
  end;
  Result := CallNextHookEx(GWndHook, Code, WParam, LParam);
end;

procedure UpdateTimer; forward;

procedure BidiSuspendUpdates;
begin
  Inc(GSuspendCount);
  if GTimer <> 0 then
  begin
    KillTimer(0, GTimer);
    GTimer := 0;
  end;
end;

procedure BidiResumeUpdates;
begin
  if GSuspendCount > 0 then
    Dec(GSuspendCount);
  UpdateTimer;
end;

procedure BidiShutdown;
begin
  Inc(GSuspendCount); { stay suspended; no matching Resume on exit }
  if GTimer <> 0 then
  begin
    KillTimer(0, GTimer);
    GTimer := 0;
  end;
end;

procedure RedrawUnlock(AHwnd: HWND);
begin
  if AHwnd = 0 then Exit;
  SendMessage(AHwnd, WM_SETREDRAW, 1, 0);
  RedrawWindow(AHwnd, nil, 0,
    RDW_ERASE or RDW_INVALIDATE or RDW_ALLCHILDREN);
end;

{ Safety net for controls created in code after the form was mirrored (dynamic
  bars, side docks, popups): visible forms are re-checked a few times a second
  while the UI is right-to-left. A pass over an already mirrored form changes
  nothing (marks), so it is cheap. }
procedure BidiTimerProc(Wnd: HWND; Msg: UINT; IdEvent: UINT_PTR; Time: DWORD); stdcall;
var
  I: Integer;
  F: TCustomForm;
begin
  if (GSuspendCount > 0) or GInPass or (Screen = nil) or (not BidiIsRtl) then Exit;
  GInPass := True;
  try
    try
      for I := 0 to Screen.CustomFormCount - 1 do
      begin
        F := Screen.CustomForms[I];
        if F.Visible and not (csLoading in F.ComponentState) and
           not (fsCreating in F.FormState) and not (csDestroying in F.ComponentState) then
          BidiApplyForm(F);
      end;
    except
    end;
  finally
    GInPass := False;
  end;
end;

procedure UpdateTimer;
begin
  if (GSuspendCount > 0) then
  begin
    if GTimer <> 0 then
    begin
      KillTimer(0, GTimer);
      GTimer := 0;
    end;
    Exit;
  end;
  if BidiIsRtl then
  begin
    { 400 ms: enough as a safety net for late-created controls; 150 ms caused
      visible flicker on dense forms (compare/merge history) during layout. }
    if GTimer = 0 then
      GTimer := SetTimer(0, 0, 400, @BidiTimerProc);
  end
  else if GTimer <> 0 then
  begin
    KillTimer(0, GTimer);
    GTimer := 0;
  end;
end;

procedure BidiSyncApplication;
var
  Want: TBiDiMode;
begin
  if BidiIsRtl then Want := bdRightToLeft else Want := bdLeftToRight;
  if Application.BiDiMode <> Want then
    Application.BiDiMode := Want;
  UpdateTimer;
  if not GHooked then
  begin
    GHooked := True;
    GWndHook := SetWindowsHookEx(WH_CALLWNDPROC, @BidiCallWndHook, 0, GetCurrentThreadId);
    GPrevActiveFormChange := Screen.OnActiveFormChange;
    GHooks := TBidiHooks.Create;
    Screen.OnActiveFormChange := GHooks.ActiveFormChanged;
  end;
end;

function SelfMirroringForm(AForm: TCustomForm): Boolean;
begin
  Result := (AForm <> nil) and
    ((AForm.ClassName = 'TMessageForm') or (AForm.ClassName = 'TInputQueryForm'));
end;

procedure BidiApplyForm(AForm: TCustomForm);
var
  Rtl: Boolean;
  Want: TBiDiMode;
  H: HWND;
begin
  if (AForm = nil) or (csDestroying in AForm.ComponentState) then Exit;
  Rtl := BidiIsRtl;
  if Rtl then Want := bdRightToLeft else Want := bdLeftToRight;
  if Application.BiDiMode <> Want then
    Application.BiDiMode := Want;
  { Forms that opted out of ParentBiDiMode keep their own value in sync. }
  if (not TControlAccess(AForm).ParentBiDiMode) and (AForm.BiDiMode <> Want) then
    AForm.BiDiMode := Want;
  { VCL's own message / input dialogs already place icon, text and buttons
    according to Application.BiDiMode. }
  if SelfMirroringForm(AForm) then Exit;
  { Left-to-right and never mirrored: nothing to do (and no marks to create). }
  if (not Rtl) and (FindMark(AForm, False) = nil) then Exit;
  H := 0;
  if AForm.HandleAllocated then
  begin
    H := AForm.Handle;
    SendMessage(H, WM_SETREDRAW, 0, 0);
  end;
  try
    ApplyContainer(AForm, Rtl);
    if Rtl then
      ReapplyKeepLtr(AForm);
  finally
    if H <> 0 then
      RedrawUnlock(H);
  end;
end;

procedure BidiApplyControl(AContainer: TWinControl);
var
  Rtl: Boolean;
begin
  if (AContainer = nil) or (csDestroying in AContainer.ComponentState) then Exit;
  Rtl := BidiIsRtl;
  if (not Rtl) and (FindMark(AContainer, False) = nil) then Exit;
  ApplyContainer(AContainer, Rtl);
  if Rtl then
    ReapplyKeepLtr(AContainer);
end;

procedure BidiApplyAllForms;
var
  I: Integer;
  Frms: TList;
begin
  { Pause the periodic timer so it does not re-enter while we mirror. }
  BidiSuspendUpdates;
  try
    BidiSyncApplication;
    Frms := TList.Create;
    try
      for I := 0 to Screen.CustomFormCount - 1 do
        Frms.Add(Screen.CustomForms[I]);
      for I := 0 to Frms.Count - 1 do
        BidiApplyForm(TCustomForm(Frms[I]));
    finally
      Frms.Free;
    end;
  finally
    BidiResumeUpdates;
  end;
end;

{ --- re-layout of children in left-to-right terms --------------------------- }

procedure BidiBeginLayout(AContainer: TWinControl);
var
  M: TBidiMark;
begin
  if (AContainer = nil) or (not BidiIsRtl) then Exit;
  M := FindMark(AContainer, True);
  if M = nil then Exit;
  Inc(M.Scope);
  if M.Scope = 1 then
    MirrorChildren(AContainer, False);
end;

procedure BidiEndLayout(AContainer: TWinControl);
var
  M: TBidiMark;
begin
  if AContainer = nil then Exit;
  M := FindMark(AContainer, False);
  if (M = nil) or (M.Scope <= 0) then Exit;
  Dec(M.Scope);
  if (M.Scope = 0) and BidiIsRtl and not (csDestroying in AContainer.ComponentState) then
    MirrorChildren(AContainer, True);
end;

type
  TBidiLayoutScope = class(TInterfacedObject)
  private
    FList: array of TWinControl;
    FRedrawHwnd: HWND;
  public
    constructor Create(const AContainers: array of TWinControl);
    destructor Destroy; override;
  end;

constructor TBidiLayoutScope.Create(const AContainers: array of TWinControl);
var
  I, N: Integer;
begin
  inherited Create;
  FRedrawHwnd := 0;
  N := 0;
  SetLength(FList, Length(AContainers));
  for I := 0 to High(AContainers) do
    if AContainers[I] <> nil then
    begin
      FList[N] := AContainers[I];
      Inc(N);
    end;
  SetLength(FList, N);
  { One coherent paint after un-mirror → layout → re-mirror (cuts RTL flicker). }
  if BidiIsRtl and (N > 0) and FList[0].HandleAllocated then
  begin
    FRedrawHwnd := FList[0].Handle;
    SendMessage(FRedrawHwnd, WM_SETREDRAW, 0, 0);
  end;
  for I := 0 to N - 1 do
    BidiBeginLayout(FList[I]);
end;

destructor TBidiLayoutScope.Destroy;
var
  I: Integer;
begin
  for I := High(FList) downto 0 do
    try
      BidiEndLayout(FList[I]);
    except
    end;
  if FRedrawHwnd <> 0 then
    RedrawUnlock(FRedrawHwnd);
  inherited;
end;

function BidiLayoutScope(const AContainers: array of TWinControl): IInterface;
begin
  Result := TBidiLayoutScope.Create(AContainers);
end;

function BidiParentOf(AControl: TControl): TWinControl;
begin
  if AControl = nil then Result := nil else Result := AControl.Parent;
end;

{ --- painting helpers ------------------------------------------------------ }

function BidiX(AWidth, X: Integer): Integer;
begin
  if BidiIsRtl then Result := AWidth - X else Result := X;
end;

function BidiLeft(AParentWidth, ALeft, AWidth: Integer): Integer;
begin
  if BidiIsRtl then
    Result := AParentWidth - ALeft - AWidth
  else
    Result := ALeft;
end;

function BidiRect(const R: TRect; AWidth: Integer): TRect;
begin
  if BidiIsRtl then
    Result := Rect(AWidth - R.Right, R.Top, AWidth - R.Left, R.Bottom)
  else
    Result := R;
end;

function BidiDrawFlags(AFlags: UINT): UINT;
begin
  Result := AFlags;
  if not BidiIsRtl then Exit;
  Result := Result or DT_RTLREADING;
  if (Result and DT_CENTER) = 0 then
  begin
    if (Result and DT_RIGHT) <> 0 then
      Result := Result and not UINT(DT_RIGHT)
    else
      Result := Result or DT_RIGHT;
  end;
end;

function BidiAlignment(AAlignment: TAlignment): TAlignment;
begin
  Result := AAlignment;
  if not BidiIsRtl then Exit;
  case AAlignment of
    taLeftJustify: Result := taRightJustify;
    taRightJustify: Result := taLeftJustify;
  end;
end;

function BidiAlignFor(AAlign: TAlign): TAlign;
begin
  Result := AAlign;
  if not BidiIsRtl then Exit;
  case AAlign of
    alLeft: Result := alRight;
    alRight: Result := alLeft;
  end;
end;

function BidiMsgBoxFlags: UINT;
begin
  if BidiIsRtl then
    Result := MB_RTLREADING or MB_RIGHT
  else
    Result := 0;
end;

function BidiControlIsRtl(AControl: TControl): Boolean;
var
  C: TControl;
begin
  Result := BidiIsRtl;
  C := AControl;
  while Result and (C <> nil) do
  begin
    if (not TControlAccess(C).ParentBiDiMode) and
       (TControlAccess(C).BiDiMode = bdLeftToRight) then
    begin
      Result := False;
      Exit;
    end;
    C := C.Parent;
  end;
end;

initialization
  uI18n.BidiApplyAllProc := BidiApplyAllForms;

finalization
  if GTimer <> 0 then
  begin
    KillTimer(0, GTimer);
    GTimer := 0;
  end;
  if GWndHook <> 0 then
  begin
    UnhookWindowsHookEx(GWndHook);
    GWndHook := 0;
  end;
  if Assigned(GHooks) then
  begin
    if Assigned(Screen) and (TMethod(Screen.OnActiveFormChange).Data = Pointer(GHooks)) then
      Screen.OnActiveFormChange := GPrevActiveFormChange;
    FreeAndNil(GHooks);
  end;

end.
