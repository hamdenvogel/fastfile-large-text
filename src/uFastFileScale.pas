unit uFastFileScale;

{
  DPI + work-area helpers so FastFile windows and runtime-created panels
  follow Windows scale (100/125/150/200%) and stay inside the monitor.
}

interface

uses
  Windows, Classes, Controls, Forms, SysUtils;

function FfCurrentPPI: Integer;
function FfPx(ADesignPx: Integer): Integer;
procedure FfWorkAreaOf(AForm: TCustomForm; out ARect: TRect);
procedure FfRelaxMinConstraints(AForm: TCustomForm);
procedure FfFitFormToWorkArea(AForm: TCustomForm);
procedure FfInstallFormLayoutManager;
procedure FfPrepareDialog(AForm: TCustomForm; ADesignClientW, ADesignClientH: Integer);
function FfCapSidePanelWidth(AHostClientW, AWantW: Integer; AMinDesign: Integer = 240): Integer;
procedure FfClampSizeToWorkArea(var ALeft, ATop, AWidth, AHeight: Integer);

implementation

type
  TFfFormLayoutManager = class
  private
    FPreviousActiveFormChange: TNotifyEvent;
    FAdjusting: Boolean;
    procedure ActiveFormChanged(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  FFFormLayoutManager: TFfFormLayoutManager;

constructor TFfFormLayoutManager.Create;
begin
  inherited Create;
  FPreviousActiveFormChange := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := ActiveFormChanged;
end;

destructor TFfFormLayoutManager.Destroy;
begin
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
  finally
    FAdjusting := False;
  end;
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

end.
