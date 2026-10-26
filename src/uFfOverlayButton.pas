unit uFfOverlayButton;

{ Button for the dark loading overlay: a rounded pill in the overlay colours (navy panel, light-blue accent of
  the progress bar), with hover, pressed and disabled looks. A skinned TBitBtn painted a white box there.
  Graphic control: hover and click come through the parent panel. }

interface

uses
  Windows, Messages, Classes, Graphics, Controls;

type
  TFfOverlayButton = class(TGraphicControl)
  private
    FHover, FDown: Boolean;
    procedure SetHover(AValue: Boolean);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Msg: TMessage); message CM_TEXTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    { Hover from the real cursor position: CM_MOUSELEAVE needs the idle loop, which does not run while a long
      operation only pumps mouse and key input. }
    procedure SyncHover;
    property Caption;
    property Font;
    property ParentFont;
    property OnClick;
  end;

implementation

uses
  GDIPAPI, GDIPOBJ;

constructor TFfOverlayButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents] - [csOpaque, csDoubleClicks];
  Width := 132;
  Height := 32;
  ParentFont := False;
  Font.Name := 'Segoe UI Semibold';
  Font.Height := -13;
end;

procedure TFfOverlayButton.SetHover(AValue: Boolean);
begin
  if FHover = AValue then
    Exit;
  FHover := AValue;
  if not FHover then
    FDown := False;
  Repaint;
end;

procedure TFfOverlayButton.SyncHover;
var
  P: TPoint;
begin
  if not (Visible and Enabled and Assigned(Parent) and Parent.HandleAllocated) then
  begin
    SetHover(False);
    Exit;
  end;
  if not GetCursorPos(P) then
    Exit;
  P := ScreenToClient(P);
  SetHover((P.X >= 0) and (P.Y >= 0) and (P.X < Width) and (P.Y < Height));
end;

procedure TFfOverlayButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    SetHover(True);
end;

procedure TFfOverlayButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  SetHover(False);
end;

procedure TFfOverlayButton.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  if not Enabled then
  begin
    FHover := False;
    FDown := False;
  end;
  Invalidate;
end;

procedure TFfOverlayButton.CMTextChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TFfOverlayButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and Enabled then
  begin
    FDown := True;
    Repaint;
  end;
end;

procedure TFfOverlayButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FDown then
  begin
    FDown := False;
    Repaint;
  end;
  inherited;
end;

procedure TFfOverlayButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Enabled then
    SetHover((X >= 0) and (Y >= 0) and (X < Width) and (Y < Height));
end;

procedure TFfOverlayButton.Paint;
var
  G: TGPGraphics;
  Path: TGPGraphicsPath;
  Fill: TGPSolidBrush;
  Pen: TGPPen;
  FillColor, BorderColor: ARGB;
  TextColor: TColor;
  D: Single;
  R: TRect;
  Cap: string;
begin
  if not Enabled then
  begin
    FillColor := MakeColor(255, 36, 46, 66);
    BorderColor := MakeColor(255, 80, 100, 130);
    TextColor := RGB(150, 165, 185);
  end
  else if FDown then
  begin
    FillColor := MakeColor(255, 30, 78, 128);
    BorderColor := MakeColor(255, 64, 192, 255);
    TextColor := clWhite;
  end
  else if FHover then
  begin
    FillColor := MakeColor(255, 50, 102, 160);
    BorderColor := MakeColor(255, 128, 216, 255);
    TextColor := clWhite;
  end
  else
  begin
    FillColor := MakeColor(255, 38, 62, 100);
    BorderColor := MakeColor(255, 64, 192, 255);
    TextColor := RGB(225, 240, 255);
  end;
  D := Height - 2;
  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetPixelOffsetMode(PixelOffsetModeHalf);
    Path := TGPGraphicsPath.Create;
    try
      Path.AddArc(1.0, 1.0, D, D, 90, 180);
      Path.AddArc(Width - D - 1, 1.0, D, D, 270, 180);
      Path.CloseFigure;
      Fill := TGPSolidBrush.Create(FillColor);
      try
        G.FillPath(Fill, Path);
      finally
        Fill.Free;
      end;
      Pen := TGPPen.Create(BorderColor, 1.25);
      try
        G.DrawPath(Pen, Path);
      finally
        Pen.Free;
      end;
    finally
      Path.Free;
    end;
  finally
    G.Free;
  end;
  Cap := Caption;
  R := Rect(0, 0, Width, Height);
  Canvas.Font := Font;
  Canvas.Font.Color := TextColor;
  Canvas.Brush.Style := bsClear;
  DrawText(Canvas.Handle, PChar(Cap), Length(Cap), R,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

end.
