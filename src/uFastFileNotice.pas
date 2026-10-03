unit uFastFileNotice;
{ Shared in-app notice: green/info/warning card, X to dismiss now, 10s countdown
  + shrinking bar then auto-hide. Used by the assistant file banner, script
  export banner, and informational ShowAppMessage-style toasts. }

interface

uses
  Windows, Classes, Controls, ExtCtrls, StdCtrls, Graphics, Forms, SysUtils,
  sPanel, sSpeedButton;

const
  FASTFILE_NOTICE_SECONDS = 10;
  FASTFILE_NOTICE_TICK_MS = 16;
  FASTFILE_NOTICE_BAR_H = 5;
  FASTFILE_APP_NOTICE_W = 400;
  FASTFILE_APP_NOTICE_H = 78;

type
  TFastFileNoticeKind = (fnkSuccess, fnkInfo, fnkWarning);

  TFastFileNoticeAutoHide = class(TComponent)
  private
    FTimer: TTimer;
    FBarTrack: TsPanel;
    FBarPaint: TPaintBox;
    FLblCount: TLabel;
    FOnHide: TNotifyEvent;
    FTotalMs: Integer;
    FRemainMs: Integer;
    FFillColor: TColor;
    FStartTick: DWORD;
    FLastCountSec: Integer;
    procedure Tick(Sender: TObject);
    procedure SyncUi;
    procedure BarPaint(Sender: TObject);
    function FillWidth: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Bind(ACard, AHead: TWinControl; AOnHide: TNotifyEvent;
      AFillColor: TColor);
    procedure Start(ASeconds: Integer = FASTFILE_NOTICE_SECONDS);
    procedure Stop;
    property RemainMs: Integer read FRemainMs;
  end;

procedure ShowFastFileAppNotice(AHost: TWinControl; AKind: TFastFileNoticeKind;
  const ATitle, ADetail: string; ASeconds: Integer = FASTFILE_NOTICE_SECONDS);
procedure HideFastFileAppNotice;

implementation

uses
  uI18n;

type
  TFastFileAppNoticeCard = class
    Pnl: TsPanel;
    Inner: TsPanel;
    Accent: TsPanel;
    Content: TsPanel;
    Head: TsPanel;
    BtnX: TsSpeedButton;
    LblTitle: TLabel;
    LblDetail: TLabel;
    AutoHide: TFastFileNoticeAutoHide;
    procedure DismissClick(Sender: TObject);
    procedure AutoHideDone(Sender: TObject);
  end;

var
  GAppNotice: TFastFileAppNoticeCard = nil;

procedure NoticeColors(AKind: TFastFileNoticeKind; out ABg, AEdge, AAccent, ATitle: TColor);
begin
  case AKind of
    fnkWarning:
      begin
        ABg := TColor($00E8F3FF);
        AEdge := TColor($00B8D4F0);
        AAccent := TColor($00008CFF);
        ATitle := TColor($00006BB8);
      end;
    fnkInfo:
      begin
        ABg := TColor($00FFF4E8);
        AEdge := TColor($00E2D4C4);
        AAccent := TColor($00C87828);
        ATitle := TColor($00784818);
      end;
  else
    ABg := TColor($00E8F5E9);
    AEdge := TColor($00B7DFB9);
    AAccent := TColor($004CAF50);
    ATitle := TColor($002E7D32);
  end;
end;

procedure ForcePnl(APnl: TsPanel; AColor: TColor);
begin
  if not Assigned(APnl) then Exit;
  APnl.Caption := '';
  APnl.BevelOuter := bvNone;
  APnl.BevelInner := bvNone;
  APnl.ParentBackground := False;
  APnl.ParentColor := False;
  APnl.Color := AColor;
  try
    APnl.SkinData.CustomColor := True;
    APnl.SkinData.SkinSection := 'TRANSPARENT';
  except
  end;
end;

function MixNoticeColor(C1, C2: TColor; C2Pct: Integer): TColor;
var
  R1, G1, B1, R2, G2, B2: Integer;
begin
  C1 := ColorToRGB(C1);
  C2 := ColorToRGB(C2);
  R1 := GetRValue(C1);
  G1 := GetGValue(C1);
  B1 := GetBValue(C1);
  R2 := GetRValue(C2);
  G2 := GetGValue(C2);
  B2 := GetBValue(C2);
  Result := RGB(
    R1 + ((R2 - R1) * C2Pct) div 100,
    G1 + ((G2 - G1) * C2Pct) div 100,
    B1 + ((B2 - B1) * C2Pct) div 100);
end;

constructor TFastFileNoticeAutoHide.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFillColor := TColor($004CAF50);
  FLastCountSec := -1;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FASTFILE_NOTICE_TICK_MS;
  FTimer.OnTimer := Tick;
end;

destructor TFastFileNoticeAutoHide.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TFastFileNoticeAutoHide.Bind(ACard, AHead: TWinControl; AOnHide: TNotifyEvent;
  AFillColor: TColor);
begin
  FOnHide := AOnHide;
  FFillColor := AFillColor;
  if AFillColor = 0 then
    FFillColor := TColor($004CAF50);
  if not Assigned(FLblCount) and Assigned(AHead) then
  begin
    FLblCount := TLabel.Create(AHead);
    FLblCount.Parent := AHead;
    FLblCount.Align := alRight;
    FLblCount.Width := 22;
    FLblCount.Alignment := taCenter;
    FLblCount.Layout := tlCenter;
    FLblCount.Transparent := True;
    FLblCount.Font.Name := 'Segoe UI';
    FLblCount.Font.Size := 8;
    FLblCount.Font.Color := TColor($00665C52);
    FLblCount.Caption := IntToStr(FASTFILE_NOTICE_SECONDS);
    FLblCount.ShowHint := True;
  end;
  if not Assigned(FBarTrack) and Assigned(ACard) then
  begin
    FBarTrack := TsPanel.Create(ACard);
    FBarTrack.Parent := ACard;
    FBarTrack.Align := alBottom;
    FBarTrack.Height := FASTFILE_NOTICE_BAR_H;
    FBarTrack.DoubleBuffered := True;
    ForcePnl(FBarTrack, MixNoticeColor(FFillColor, clWhite, 78));
    FBarPaint := TPaintBox.Create(ACard);
    FBarPaint.Parent := FBarTrack;
    FBarPaint.Align := alClient;
    FBarPaint.OnPaint := BarPaint;
  end
  else if Assigned(FBarTrack) then
    ForcePnl(FBarTrack, MixNoticeColor(FFillColor, clWhite, 78));
  if Assigned(FBarPaint) then
    FBarPaint.Invalidate;
end;

function TFastFileNoticeAutoHide.FillWidth: Integer;
var
  MaxW: Integer;
begin
  Result := 0;
  if not Assigned(FBarPaint) or (FTotalMs <= 0) then Exit;
  MaxW := FBarPaint.ClientWidth;
  if MaxW < 1 then
  begin
    if Assigned(FBarTrack) then
      MaxW := FBarTrack.ClientWidth;
    if MaxW < 1 then Exit;
  end;
  if FRemainMs <= 0 then
    Result := 0
  else if FRemainMs >= FTotalMs then
    Result := MaxW
  else
    Result := MulDiv(MaxW, FRemainMs, FTotalMs);
  if (Result < 1) and (FRemainMs > 0) then
    Result := 1;
  if Result > MaxW then
    Result := MaxW;
end;

procedure TFastFileNoticeAutoHide.BarPaint(Sender: TObject);
var
  C: TCanvas;
  R, FillR: TRect;
  W, H, Rad: Integer;
  TrackC, HiC: TColor;
begin
  if not (Sender is TPaintBox) then Exit;
  C := TPaintBox(Sender).Canvas;
  R := TPaintBox(Sender).ClientRect;
  H := R.Bottom - R.Top;
  TrackC := MixNoticeColor(FFillColor, clWhite, 78);
  C.Brush.Style := bsSolid;
  C.Brush.Color := TrackC;
  C.FillRect(R);

  W := FillWidth;
  if W <= 0 then Exit;
  FillR := Rect(R.Left, R.Top, R.Left + W, R.Bottom);
  C.Pen.Style := psSolid;
  C.Pen.Color := FFillColor;
  C.Pen.Width := 1;
  C.Brush.Color := FFillColor;
  Rad := H;
  if (W >= H) and (H >= 3) then
    RoundRect(C.Handle, FillR.Left, FillR.Top, FillR.Right, FillR.Bottom, Rad, Rad)
  else
    C.FillRect(FillR);

  if (W > 4) and (H >= 3) then
  begin
    HiC := MixNoticeColor(FFillColor, clWhite, 42);
    C.Pen.Style := psSolid;
    C.Pen.Color := HiC;
    C.MoveTo(FillR.Left + 2, FillR.Top);
    C.LineTo(FillR.Right - 2, FillR.Top);
  end;
end;

procedure TFastFileNoticeAutoHide.SyncUi;
var
  Sec: Integer;
begin
  Sec := (FRemainMs + 999) div 1000;
  if Sec < 0 then
    Sec := 0;
  if Assigned(FLblCount) and (Sec <> FLastCountSec) then
  begin
    FLastCountSec := Sec;
    FLblCount.Caption := IntToStr(Sec);
    FLblCount.Hint := Format(TrText('Notice.ClosesIn'), [Sec]);
    FLblCount.ShowHint := True;
  end;
  if Assigned(FBarPaint) then
    FBarPaint.Invalidate;
end;

procedure TFastFileNoticeAutoHide.Tick(Sender: TObject);
var
  Elapsed: Integer;
begin
  Elapsed := Integer(GetTickCount - FStartTick);
  if Elapsed < 0 then
    Elapsed := 0;
  FRemainMs := FTotalMs - Elapsed;
  if FRemainMs <= 0 then
  begin
    FRemainMs := 0;
    SyncUi;
    Stop;
    if Assigned(FOnHide) then
      FOnHide(Self);
    Exit;
  end;
  SyncUi;
end;

procedure TFastFileNoticeAutoHide.Start(ASeconds: Integer);
begin
  if ASeconds < 1 then
    ASeconds := FASTFILE_NOTICE_SECONDS;
  FTotalMs := ASeconds * 1000;
  FRemainMs := FTotalMs;
  FStartTick := GetTickCount;
  FLastCountSec := -1;
  SyncUi;
  if Assigned(FTimer) then
  begin
    FTimer.Interval := FASTFILE_NOTICE_TICK_MS;
    FTimer.Enabled := True;
  end;
end;

procedure TFastFileNoticeAutoHide.Stop;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;
end;

procedure HideFastFileAppNotice;
begin
  if not Assigned(GAppNotice) then Exit;
  if Assigned(GAppNotice.AutoHide) then
    GAppNotice.AutoHide.Stop;
  if Assigned(GAppNotice.Pnl) then
  begin
    GAppNotice.Pnl.Visible := False;
    GAppNotice.Pnl.Height := 0;
  end;
end;

procedure TFastFileAppNoticeCard.DismissClick(Sender: TObject);
begin
  HideFastFileAppNotice;
end;

procedure TFastFileAppNoticeCard.AutoHideDone(Sender: TObject);
begin
  HideFastFileAppNotice;
end;

procedure EnsureAppNotice(AHost: TWinControl);
var
  DummyBg, DummyEdge, DummyAccent, DummyTitle: TColor;
begin
  NoticeColors(fnkSuccess, DummyBg, DummyEdge, DummyAccent, DummyTitle);
  if Assigned(GAppNotice) then
  begin
    if Assigned(GAppNotice.Pnl) and Assigned(AHost) and
       (GAppNotice.Pnl.Parent <> AHost) then
      GAppNotice.Pnl.Parent := AHost;
    Exit;
  end;
  if not Assigned(AHost) then Exit;

  GAppNotice := TFastFileAppNoticeCard.Create;
  GAppNotice.Pnl := TsPanel.Create(AHost);
  GAppNotice.Pnl.Parent := AHost;
  GAppNotice.Pnl.Align := alNone;
  GAppNotice.Pnl.Anchors := [akTop, akRight];
  GAppNotice.Pnl.Visible := False;
  GAppNotice.Pnl.Height := 0;
  GAppNotice.Pnl.Width := FASTFILE_APP_NOTICE_W;
  GAppNotice.Pnl.Padding.Left := 1;
  GAppNotice.Pnl.Padding.Top := 1;
  GAppNotice.Pnl.Padding.Right := 1;
  GAppNotice.Pnl.Padding.Bottom := 1;
  ForcePnl(GAppNotice.Pnl, DummyEdge);

  GAppNotice.Inner := TsPanel.Create(AHost);
  GAppNotice.Inner.Parent := GAppNotice.Pnl;
  GAppNotice.Inner.Align := alClient;
  ForcePnl(GAppNotice.Inner, DummyBg);

  GAppNotice.Accent := TsPanel.Create(AHost);
  GAppNotice.Accent.Parent := GAppNotice.Inner;
  GAppNotice.Accent.Align := alLeft;
  GAppNotice.Accent.Width := 4;
  ForcePnl(GAppNotice.Accent, DummyAccent);

  GAppNotice.Content := TsPanel.Create(AHost);
  GAppNotice.Content.Parent := GAppNotice.Inner;
  GAppNotice.Content.Align := alClient;
  GAppNotice.Content.Padding.Left := 10;
  GAppNotice.Content.Padding.Top := 6;
  GAppNotice.Content.Padding.Right := 8;
  GAppNotice.Content.Padding.Bottom := 4;
  ForcePnl(GAppNotice.Content, DummyBg);

  GAppNotice.Head := TsPanel.Create(AHost);
  GAppNotice.Head.Parent := GAppNotice.Content;
  GAppNotice.Head.Align := alTop;
  GAppNotice.Head.Height := 22;
  ForcePnl(GAppNotice.Head, DummyBg);

  GAppNotice.BtnX := TsSpeedButton.Create(AHost);
  GAppNotice.BtnX.Parent := GAppNotice.Head;
  GAppNotice.BtnX.Align := alRight;
  GAppNotice.BtnX.Width := 22;
  GAppNotice.BtnX.Caption := #$00D7;
  GAppNotice.BtnX.Flat := True;
  GAppNotice.BtnX.OnClick := GAppNotice.DismissClick;
  try
    GAppNotice.BtnX.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;

  GAppNotice.LblTitle := TLabel.Create(AHost);
  GAppNotice.LblTitle.Parent := GAppNotice.Head;
  GAppNotice.LblTitle.Align := alClient;
  GAppNotice.LblTitle.Layout := tlCenter;
  GAppNotice.LblTitle.Transparent := True;
  GAppNotice.LblTitle.Font.Name := 'Segoe UI';
  GAppNotice.LblTitle.Font.Size := 9;
  GAppNotice.LblTitle.Font.Style := [fsBold];
  GAppNotice.LblTitle.EllipsisPosition := epEndEllipsis;

  GAppNotice.LblDetail := TLabel.Create(AHost);
  GAppNotice.LblDetail.Parent := GAppNotice.Content;
  GAppNotice.LblDetail.Align := alClient;
  GAppNotice.LblDetail.Transparent := True;
  GAppNotice.LblDetail.WordWrap := True;
  GAppNotice.LblDetail.Font.Name := 'Segoe UI';
  GAppNotice.LblDetail.Font.Size := 8;
  GAppNotice.LblDetail.Font.Color := TColor($00403830);

  GAppNotice.AutoHide := TFastFileNoticeAutoHide.Create(GAppNotice.Pnl);
  GAppNotice.AutoHide.Bind(GAppNotice.Pnl, GAppNotice.Head, GAppNotice.AutoHideDone, DummyAccent);
end;

procedure ShowFastFileAppNotice(AHost: TWinControl; AKind: TFastFileNoticeKind;
  const ATitle, ADetail: string; ASeconds: Integer);
var
  Bg, Edge, Accent, TitleC: TColor;
  TopY: Integer;
begin
  if not Assigned(AHost) then Exit;
  EnsureAppNotice(AHost);
  if not Assigned(GAppNotice) or not Assigned(GAppNotice.Pnl) then Exit;
  NoticeColors(AKind, Bg, Edge, Accent, TitleC);
  ForcePnl(GAppNotice.Pnl, Edge);
  ForcePnl(GAppNotice.Inner, Bg);
  ForcePnl(GAppNotice.Accent, Accent);
  ForcePnl(GAppNotice.Content, Bg);
  ForcePnl(GAppNotice.Head, Bg);
  if Assigned(GAppNotice.LblTitle) then
  begin
    GAppNotice.LblTitle.Caption := ATitle;
    GAppNotice.LblTitle.Font.Color := TitleC;
    GAppNotice.LblTitle.Hint := ATitle;
  end;
  if Assigned(GAppNotice.LblDetail) then
  begin
    GAppNotice.LblDetail.Caption := ADetail;
    GAppNotice.LblDetail.Hint := ADetail;
    GAppNotice.LblDetail.Visible := Trim(ADetail) <> '';
  end;
  if Assigned(GAppNotice.BtnX) then
  begin
    GAppNotice.BtnX.Hint := TrText('Close');
    GAppNotice.BtnX.ShowHint := True;
  end;
  if Assigned(GAppNotice.AutoHide) then
    GAppNotice.AutoHide.Bind(GAppNotice.Pnl, GAppNotice.Head, GAppNotice.AutoHideDone, Accent);
  GAppNotice.Pnl.Width := FASTFILE_APP_NOTICE_W;
  if Trim(ADetail) = '' then
    GAppNotice.Pnl.Height := 52
  else
    GAppNotice.Pnl.Height := FASTFILE_APP_NOTICE_H;
  TopY := 56;
  if TopY + GAppNotice.Pnl.Height > AHost.ClientHeight then
    TopY := 8;
  GAppNotice.Pnl.SetBounds(
    AHost.ClientWidth - GAppNotice.Pnl.Width - 12,
    TopY, GAppNotice.Pnl.Width, GAppNotice.Pnl.Height);
  GAppNotice.Pnl.Visible := True;
  GAppNotice.Pnl.BringToFront;
  if Assigned(GAppNotice.AutoHide) then
    GAppNotice.AutoHide.Start(ASeconds);
end;

end.
