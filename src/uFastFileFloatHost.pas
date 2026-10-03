unit uFastFileFloatHost;

{
  Tear-off host: drag a docked header to float, drag the window back over
  the original strip to dock. Edge grips resize height (docked or floating).
  Avoids VCL DragDock (unreliable with skins).
}

interface

uses
  Classes, Controls, Forms, ExtCtrls, Windows, Messages, uFastFileScale;

type
  TFastFileGripKind = (fgTop, fgBottom);

  TFastFileEdgeGrip = class(TPanel)
  private
    FKind: TFastFileGripKind;
    FTarget: TControl;
    FMinSize: Integer;
    FMaxSize: Integer;
    FDown: Boolean;
    FStartPt: TPoint;
    FStartH: Integer;
    FStartTop: Integer;
    FOnResized: TNotifyEvent;
    procedure GripMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GripMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    function ResizeHost: TControl;
  public
    constructor CreateGrip(AOwner: TComponent; AParent: TWinControl;
      AKind: TFastFileGripKind);
    procedure PlaceOn(AHost: TWinControl);
    property ResizeTarget: TControl read FTarget write FTarget;
    property MinSize: Integer read FMinSize write FMinSize;
    property MaxSize: Integer read FMaxSize write FMaxSize;
    property OnResized: TNotifyEvent read FOnResized write FOnResized;
  end;

  TFastFileFloatForm = class(TForm)
  private
    FOnRequestDock: TNotifyEvent;
    FOnUpdateDockZone: TNotifyEvent;
    FDockZone: TRect;
    FMainMagnet: TRect;
    FHasMovedAway: Boolean;
    FSuppressDock: Boolean;
    FTearOffPt: TPoint;
    FFollowTimer: TObject;
    FPreview: TForm;
    FEnterBounds: TRect;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure WMEnterSizeMove(var Msg: TMessage); message WM_ENTERSIZEMOVE;
    procedure WMExitSizeMove(var Msg: TMessage); message WM_EXITSIZEMOVE;
    procedure WMMoving(var Msg: TMessage); message WM_MOVING;
    procedure WMNCLButtonDblClk(var Msg: TWMNCLButtonDblClk); message WM_NCLBUTTONDBLCLK;
    procedure FollowTimerTick(Sender: TObject);
    procedure DoCaptionFollow;
    procedure HideDockPreview;
    procedure SyncDockPreview;
    procedure NoteMoveAway;
    function WindowDidMove: Boolean;
    function ShouldDock: Boolean;
  public
    constructor CreateHost(AOwner: TComponent; const ATitle: string);
    destructor Destroy; override;
    procedure PlaceBesideMain(ADefaultW, ADefaultH: Integer);
    procedure ApplySavedBounds(ALeft, ATop, AWidth, AHeight: Integer);
    procedure PlaceUnderCursor(ADefaultW, ADefaultH: Integer);
    procedure SetDockZone(const AZone: TRect);
    procedure SetMainMagnet(const ARect: TRect);
    procedure MarkJustTornOff;
    procedure BeginCaptionFollow;
    procedure BeginCaptionFollowNow;
    procedure RequestDock;
    property OnRequestDock: TNotifyEvent read FOnRequestDock write FOnRequestDock;
    property OnUpdateDockZone: TNotifyEvent read FOnUpdateDockZone write FOnUpdateDockZone;
  end;

function ControlIsOnFloatForm(ACtl: TControl): Boolean;
function HostFormOf(ACtl: TControl): TCustomForm;
function FloatHostOf(ACtl: TControl): TFastFileFloatForm;
procedure ReparentAligned(ACtl: TControl; ANewParent: TWinControl; AAlign: TAlign);
procedure StartCaptionFollow(AForm: TCustomForm);
function ControlBlocksPanelDrag(ACtl: TControl): Boolean;
procedure AttachPanelDrag(ARoot: TControl; ADown: TMouseEvent;
  AMove: TMouseMoveEvent; AUp: TMouseEvent; ADbl: TNotifyEvent;
  const AHint: string = '');

const
  FASTFILE_TEAR_THRESHOLD = 12;
  FASTFILE_GRIP_H = 4;
  FASTFILE_UNDOCK_SLACK = 64;

implementation

uses
  SysUtils, Types, Graphics, StdCtrls;

const
  SC_DRAGMOVE = $F012;

type
  TControlAccess = class(TControl)
  public
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnDblClick;
  end;

  TFastFileDockPreview = class(TForm)
  public
    constructor CreatePreview;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

constructor TFastFileDockPreview.CreatePreview;
begin
  inherited CreateNew(nil);
  BorderStyle := bsNone;
  BorderIcons := [];
  Color := $0039B54A;
  AlphaBlend := True;
  AlphaBlendValue := 70;
  Enabled := False;
  FormStyle := fsStayOnTop;
  Position := poDesigned;
end;

procedure TFastFileDockPreview.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW or WS_EX_TRANSPARENT or
    WS_EX_NOACTIVATE or WS_EX_LAYERED;
end;

{ TFastFileEdgeGrip }

constructor TFastFileEdgeGrip.CreateGrip(AOwner: TComponent; AParent: TWinControl;
  AKind: TFastFileGripKind);
begin
  inherited Create(AOwner);
  FKind := AKind;
  FMinSize := 72;
  FMaxSize := 0;
  Parent := AParent;
  Align := alNone;
  Height := FASTFILE_GRIP_H;
  BevelOuter := bvNone;
  Caption := '';
  ParentBackground := False;
  ParentColor := False;
  Color := $00E6E0DA;
  Cursor := crVSplit;
  ShowHint := True;
  OnMouseDown := GripMouseDown;
  OnMouseMove := GripMouseMove;
  OnMouseUp := GripMouseUp;
end;

procedure TFastFileEdgeGrip.PlaceOn(AHost: TWinControl);
begin
  if not Assigned(AHost) then
    Exit;
  if FKind = fgTop then
    SetBounds(0, 0, AHost.ClientWidth, FASTFILE_GRIP_H)
  else
    SetBounds(0, AHost.ClientHeight - FASTFILE_GRIP_H, AHost.ClientWidth, FASTFILE_GRIP_H);
  BringToFront;
end;

function TFastFileEdgeGrip.ResizeHost: TControl;
var
  F: TCustomForm;
begin
  Result := FTarget;
  if not Assigned(Result) then
    Result := Parent;
  if not Assigned(Result) then
    Exit;
  F := GetParentForm(Result);
  if (F is TFastFileFloatForm) and (Result.Align = alClient) then
    Result := F;
end;

procedure TFastFileEdgeGrip.GripMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Host: TControl;
begin
  if Button <> mbLeft then
    Exit;
  Host := ResizeHost;
  if not Assigned(Host) then
    Exit;
  FDown := True;
  GetCursorPos(FStartPt);
  FStartH := Host.Height;
  FStartTop := Host.Top;
  SetCaptureControl(Self);
end;

procedure TFastFileEdgeGrip.GripMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  P: TPoint;
  Host: TControl;
  NewH, Dy: Integer;
begin
  if not FDown then
    Exit;
  Host := ResizeHost;
  if not Assigned(Host) then
    Exit;
  GetCursorPos(P);
  Dy := P.Y - FStartPt.Y;
  if FKind = fgBottom then
    NewH := FStartH + Dy
  else
    NewH := FStartH - Dy;
  if NewH < FMinSize then
    NewH := FMinSize;
  if (FMaxSize > 0) and (NewH > FMaxSize) then
    NewH := FMaxSize;
  if Host is TCustomForm then
  begin
    if FKind = fgTop then
      TCustomForm(Host).SetBounds(Host.Left, FStartTop + (FStartH - NewH),
        Host.Width, NewH)
    else
      Host.Height := NewH;
  end
  else
    Host.Height := NewH;
end;

procedure TFastFileEdgeGrip.GripMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if not FDown then
    Exit;
  FDown := False;
  SetCaptureControl(nil);
  if Assigned(FOnResized) then
    FOnResized(Self);
end;

{ TFastFileFloatForm }

constructor TFastFileFloatForm.CreateHost(AOwner: TComponent; const ATitle: string);
var
  OwnerForm: TCustomForm;
  TargetPPI: Integer;
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsSizeToolWin;
  BorderIcons := [biSystemMenu];
  Caption := ATitle;
  Position := poDesigned;
  KeyPreview := True;
  DoubleBuffered := True;
  PopupMode := pmExplicit;
  if AOwner is TCustomForm then
  begin
    OwnerForm := TCustomForm(AOwner);
    PopupParent := OwnerForm;
    { Match owner PPI before any child is reparented — avoids VCL ScaleForPPI
      blowing up ListView/Filter fonts on undock/dock. }
    TargetPPI := OwnerForm.CurrentPPI;
    if TargetPPI <= 0 then
      TargetPPI := FfCurrentPPI;
    if TargetPPI > 0 then
      ScaleForPPI(TargetPPI);
  end;
  OnClose := FormClose;
  Constraints.MinWidth := 280;
  Constraints.MinHeight := 120;
  FHasMovedAway := True;
  FSuppressDock := False;
  FDockZone := Rect(0, 0, 0, 0);
  FMainMagnet := Rect(0, 0, 0, 0);
  FFollowTimer := nil;
  FPreview := nil;
end;

destructor TFastFileFloatForm.Destroy;
begin
  HideDockPreview;
  FreeAndNil(FPreview);
  inherited Destroy;
end;

procedure TFastFileFloatForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  HideDockPreview;
  Action := caHide;
  { Hide after a successful dock reparents children first — do not dock twice. }
  if ControlCount > 0 then
    RequestDock;
end;

procedure TFastFileFloatForm.RequestDock;
begin
  if Assigned(FOnRequestDock) then
    FOnRequestDock(Self);
end;

procedure TFastFileFloatForm.HideDockPreview;
begin
  if Assigned(FPreview) then
    FPreview.Hide;
end;

procedure TFastFileFloatForm.NoteMoveAway;
var
  P: TPoint;
begin
  if FHasMovedAway then
    Exit;
  GetCursorPos(P);
  if (Abs(P.X - FTearOffPt.X) >= FASTFILE_UNDOCK_SLACK) or
     (Abs(P.Y - FTearOffPt.Y) >= FASTFILE_UNDOCK_SLACK) then
    FHasMovedAway := True;
end;

procedure TFastFileFloatForm.SyncDockPreview;
begin
  NoteMoveAway;
  if FSuppressDock or not FHasMovedAway or not ShouldDock then
  begin
    HideDockPreview;
    Exit;
  end;
  if not Assigned(FPreview) then
    FPreview := TFastFileDockPreview.CreatePreview;
  FPreview.SetBounds(FDockZone.Left, FDockZone.Top,
    FDockZone.Right - FDockZone.Left, FDockZone.Bottom - FDockZone.Top);
  if not FPreview.Visible then
    ShowWindow(FPreview.Handle, SW_SHOWNOACTIVATE);
end;

function TFastFileFloatForm.WindowDidMove: Boolean;
begin
  Result := (Abs(Left - FEnterBounds.Left) >= 8) or
    (Abs(Top - FEnterBounds.Top) >= 8);
end;

function TFastFileFloatForm.ShouldDock: Boolean;
var
  P: TPoint;
  Hit: TRect;
begin
  Result := False;
  if FDockZone.Right <= FDockZone.Left then
    Exit;
  GetCursorPos(P);
  Hit := FDockZone;
  InflateRect(Hit, 28, 28);
  Result := PtInRect(Hit, P);
end;

procedure TFastFileFloatForm.WMEnterSizeMove(var Msg: TMessage);
begin
  inherited;
  FEnterBounds := BoundsRect;
end;

procedure TFastFileFloatForm.WMMoving(var Msg: TMessage);
begin
  inherited;
  if Assigned(FOnUpdateDockZone) then
    FOnUpdateDockZone(Self);
  NoteMoveAway;
  SyncDockPreview;
end;

procedure TFastFileFloatForm.WMExitSizeMove(var Msg: TMessage);
var
  Skip: Boolean;
begin
  inherited;
  if Assigned(FOnUpdateDockZone) then
    FOnUpdateDockZone(Self);
  NoteMoveAway;
  Skip := FSuppressDock;
  if FSuppressDock then
    FSuppressDock := False;
  try
    { First drop after tear-off stays floating. Later drops dock only when
      the cursor is on the home slot and the window actually moved. }
    if (not Skip) and FHasMovedAway and WindowDidMove and ShouldDock then
      RequestDock;
  finally
    HideDockPreview;
  end;
end;

procedure TFastFileFloatForm.WMNCLButtonDblClk(var Msg: TWMNCLButtonDblClk);
begin
  if Msg.HitTest = HTCAPTION then
    RequestDock
  else
    inherited;
end;

procedure TFastFileFloatForm.PlaceBesideMain(ADefaultW, ADefaultH: Integer);
var
  R: TRect;
  Main: TCustomForm;
  X, Y, W, H: Integer;
begin
  W := ADefaultW;
  H := ADefaultH;
  if W < Constraints.MinWidth then
    W := Constraints.MinWidth;
  if H < Constraints.MinHeight then
    H := Constraints.MinHeight;
  Main := Application.MainForm;
  if Assigned(Main) then
  begin
    X := Main.Left + Main.Width;
    Y := Main.Top;
    if Assigned(Screen.MonitorFromWindow(Main.Handle, mdNearest)) then
    begin
      R := Screen.MonitorFromWindow(Main.Handle, mdNearest).WorkareaRect;
      if X + W > R.Right then
        X := R.Right - W;
      if X < R.Left then
        X := R.Left;
      if Y + H > R.Bottom then
        H := R.Bottom - Y;
      if Y < R.Top then
        Y := R.Top;
    end;
    SetBounds(X, Y, W, H);
  end
  else
    SetBounds(100, 100, W, H);
end;

procedure TFastFileFloatForm.ApplySavedBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if AWidth < Constraints.MinWidth then
    AWidth := Constraints.MinWidth;
  if AHeight < Constraints.MinHeight then
    AHeight := Constraints.MinHeight;
  FfClampSizeToWorkArea(ALeft, ATop, AWidth, AHeight);
  SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TFastFileFloatForm.PlaceUnderCursor(ADefaultW, ADefaultH: Integer);
var
  P: TPoint;
  W, H: Integer;
begin
  W := ADefaultW;
  H := ADefaultH;
  if W < Constraints.MinWidth then
    W := Constraints.MinWidth;
  if H < Constraints.MinHeight then
    H := Constraints.MinHeight;
  GetCursorPos(P);
  SetBounds(P.X - 56, P.Y - 16, W, H);
end;

procedure TFastFileFloatForm.SetDockZone(const AZone: TRect);
begin
  FDockZone := AZone;
end;

procedure TFastFileFloatForm.SetMainMagnet(const ARect: TRect);
begin
  FMainMagnet := ARect;
end;

procedure TFastFileFloatForm.MarkJustTornOff;
begin
  GetCursorPos(FTearOffPt);
  FHasMovedAway := False;
  FSuppressDock := True;
  HideDockPreview;
end;

procedure TFastFileFloatForm.DoCaptionFollow;
begin
  if not HandleAllocated or not Visible then
    Exit;
  if (GetAsyncKeyState(VK_LBUTTON) and $8000) = 0 then
    Exit;
  StartCaptionFollow(Self);
end;

procedure TFastFileFloatForm.FollowTimerTick(Sender: TObject);
begin
  if FFollowTimer is TTimer then
    TTimer(FFollowTimer).Enabled := False;
  DoCaptionFollow;
end;

procedure TFastFileFloatForm.BeginCaptionFollow;
var
  Tm: TTimer;
begin
  if not Assigned(FFollowTimer) then
  begin
    Tm := TTimer.Create(Self);
    Tm.Enabled := False;
    Tm.Interval := 15;
    Tm.OnTimer := FollowTimerTick;
    FFollowTimer := Tm;
  end;
  Tm := TTimer(FFollowTimer);
  Tm.Enabled := False;
  Tm.Enabled := True;
end;

procedure TFastFileFloatForm.BeginCaptionFollowNow;
begin
  DoCaptionFollow;
end;

procedure StartCaptionFollow(AForm: TCustomForm);
begin
  if not Assigned(AForm) or not AForm.HandleAllocated then
    Exit;
  ReleaseCapture;
  SendMessage(AForm.Handle, WM_SYSCOMMAND, SC_DRAGMOVE, 0);
end;

function HostFormOf(ACtl: TControl): TCustomForm;
begin
  Result := nil;
  if Assigned(ACtl) then
    Result := GetParentForm(ACtl);
end;

function ControlIsOnFloatForm(ACtl: TControl): Boolean;
begin
  Result := HostFormOf(ACtl) is TFastFileFloatForm;
end;

function FloatHostOf(ACtl: TControl): TFastFileFloatForm;
var
  F: TCustomForm;
begin
  F := HostFormOf(ACtl);
  if F is TFastFileFloatForm then
    Result := TFastFileFloatForm(F)
  else
    Result := nil;
end;

procedure ReparentAligned(ACtl: TControl; ANewParent: TWinControl; AAlign: TAlign);
begin
  if not Assigned(ACtl) or not Assigned(ANewParent) then
    Exit;
  ACtl.Align := alNone;
  ACtl.Parent := ANewParent;
  ACtl.Align := AAlign;
  ACtl.Visible := True;
end;

function ControlBlocksPanelDrag(ACtl: TControl): Boolean;
var
  C: string;
begin
  Result := False;
  if not Assigned(ACtl) then
    Exit;
  if (ACtl is TCustomEdit) or (ACtl is TCustomComboBox) or
     (ACtl is TCustomButton) or (ACtl is TButtonControl) or
     (ACtl is TCustomListBox) or (ACtl is TFastFileEdgeGrip) or
     (ACtl is TSplitter) then
  begin
    Result := True;
    Exit;
  end;
  C := UpperCase(ACtl.ClassName);
  Result := (Pos('EDIT', C) > 0) or (Pos('MEMO', C) > 0) or
    (Pos('COMBO', C) > 0) or (Pos('BUTTON', C) > 0) or
    (Pos('CHECK', C) > 0) or (Pos('RADIO', C) > 0) or
    (Pos('SCROLL', C) > 0) or (Pos('SPLIT', C) > 0) or
    (Pos('GRIP', C) > 0) or (Pos('TRACK', C) > 0);
end;

procedure AttachPanelDrag(ARoot: TControl; ADown: TMouseEvent;
  AMove: TMouseMoveEvent; AUp: TMouseEvent; ADbl: TNotifyEvent;
  const AHint: string);

  procedure Walk(ACtl: TControl);
  var
    I: Integer;
    W: TWinControl;
  begin
    if not Assigned(ACtl) then
      Exit;
    if ControlBlocksPanelDrag(ACtl) then
      Exit;
    if not Assigned(TControlAccess(ACtl).OnMouseDown) or
       (TMethod(TControlAccess(ACtl).OnMouseDown).Code = TMethod(ADown).Code) then
    begin
      TControlAccess(ACtl).OnMouseDown := ADown;
      TControlAccess(ACtl).OnMouseMove := AMove;
      TControlAccess(ACtl).OnMouseUp := AUp;
      if Assigned(ADbl) then
        TControlAccess(ACtl).OnDblClick := ADbl;
      ACtl.Cursor := crSizeAll;
      if AHint <> '' then
      begin
        ACtl.ShowHint := True;
        ACtl.Hint := AHint;
      end;
    end;
    if ACtl is TWinControl then
    begin
      W := TWinControl(ACtl);
      for I := 0 to W.ControlCount - 1 do
        Walk(W.Controls[I]);
    end;
  end;

begin
  Walk(ARoot);
end;

end.
