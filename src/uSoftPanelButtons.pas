unit uSoftPanelButtons;
{ Shared soft-chrome styling for Find Occ / Filter / Bookmark action buttons.
  Warm cream faces via SkinData.ColorTone (TControl.Color is protected outside
  the control hierarchy), role hierarchy, hand cursor, extra content margin. }

interface

uses
  Classes, Graphics, Controls, StdCtrls, sButton, sSpeedButton, sPanel;

type
  TSoftPanelBtnRole = (
    spbrPrimary,  { Go / Apply / Next — emphasized warm face + bold }
    spbrAction,   { Prev, Collect, Export, Copy — standard cream }
    spbrCommand,  { grep / glob — compact secondary }
    spbrQuiet     { Clear / Close — muted face }
  );

procedure StyleSoftPanelBtn(ABtn: TsButton; const AUiFont: string;
  ARole: TSoftPanelBtnRole = spbrAction);
procedure StyleSoftPanelFrameBtn(ABtn: TsButton; const AUiFont: string);
{ Lays the visible buttons out left to right from (ALeft, ATop), wrapping
  inside AWidth. Rows that are at least two thirds full stretch to the full
  width so a narrow column reads as an even grid. Returns the height used. }
function FlowSoftPanelButtons(const ABtns: array of TsButton; ACanvas: TCanvas;
  ALeft, ATop, AWidth, ABtnH, AGap, AMinW, APadX: Integer): Integer;
{ Flat chevron shown left of a docked panel title (accordion expand / collapse). }
function CreatePanelChevron(AOwner: TComponent; AParent: TWinControl;
  AOnClick: TNotifyEvent): TsSpeedButton;
procedure SyncPanelChevron(ABtn: TsSpeedButton; ACollapsed: Boolean);
{ Opaque cover below a collapsed panel's title row, so rows that fall in the
  bottom padding neither show nor take clicks. Created on first collapse. }
procedure SyncCollapseMask(var AMask: TsPanel; AOwner: TComponent;
  AParent: TWinControl; ATop: Integer; AColor: TColor; ACollapsed: Boolean);
{ The main form's wheel handler scrolls the file list for any wheel that bubbles
  up to it; this makes the list box scroll itself under the mouse instead.
  Ctrl+wheel still bubbles so zoom keeps working. }
procedure HookListWheel(AList: TCustomListBox);

implementation

uses
  UnConsts,
  Windows, Messages, Math, Forms, uFastFileScale, uI18n, uBidiLayout;

type
  TListWheelHook = class(TComponent)
  private
    FList: TCustomListBox;
    FOldProc: TWndMethod;
    FAccum: Integer;
    procedure ListWndProc(var Msg: TMessage);
  end;

procedure TListWheelHook.ListWndProc(var Msg: TMessage);
var
  Lines: UINT;
  Steps, Page: Integer;
begin
  if (Msg.Msg = WM_MOUSEWHEEL) and (GetKeyState(VK_CONTROL) >= 0) then
  begin
    Inc(FAccum, SmallInt(HiWord(Msg.WParam)));
    Steps := FAccum div WHEEL_DELTA;
    FAccum := FAccum mod WHEEL_DELTA;
    if Steps <> 0 then
    begin
      Page := Max(1, FList.ClientHeight div
        Max(1, Integer(FList.Perform(LB_GETITEMHEIGHT, 0, 0))));
      Lines := 3;
      SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @Lines, 0);
      if (Lines = 0) or (Lines > UINT(Page)) then
        Lines := Page;
      FList.TopIndex := Max(0, FList.TopIndex - Steps * Integer(Lines));
    end;
    Msg.Result := 0;
    Exit;
  end;
  FOldProc(Msg);
end;

procedure HookListWheel(AList: TCustomListBox);
var
  Hook: TListWheelHook;
begin
  if not Assigned(AList) then Exit;
  Hook := TListWheelHook.Create(AList);
  Hook.FList := AList;
  Hook.FOldProc := AList.WindowProc;
  AList.WindowProc := Hook.ListWndProc;
end;

const
  SoftBtnFacePrimary = TColor($00D9B896); { richer sand accent }
  SoftBtnFaceAction  = TColor($00FFF8F0); { bright cream }
  SoftBtnFaceCommand = TColor($00F5EDE3); { soft taupe }
  SoftBtnFaceQuiet   = TColor($00EBE4DB); { muted surface }
  SoftBtnText        = TColor($001A1410);
  SoftBtnTextPrimary = TColor($0019100C);
  SoftBtnTextMuted   = TColor($005C534C);

procedure ApplySoftFace(ABtn: TsButton; AFace: TColor);
begin
  if not Assigned(ABtn) then Exit;
  try
    { ColorTone tints the skinned BUTTON face (keeps hover/press). CustomFont
      keeps role text colours. Do not touch TControl.Color (protected). }
    ABtn.SkinData.SkinSection := 'BUTTON';
    ABtn.SkinData.CustomFont := True;
    ABtn.SkinData.CustomColor := False;
    ABtn.SkinData.ColorTone := AFace;
  except
  end;
end;

procedure StyleSoftPanelBtn(ABtn: TsButton; const AUiFont: string;
  ARole: TSoftPanelBtnRole);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.ParentFont := False;
  ABtn.Font.Name := AUiFont;
  ABtn.Font.Size := 9;
  ABtn.ShowHint := True;
  ABtn.Cursor := crHandPoint;
  try
    ABtn.ContentMargin := 10;
  except
  end;
  case ARole of
    spbrPrimary:
      begin
        ABtn.Font.Style := [fsBold];
        ABtn.Font.Color := SoftBtnTextPrimary;
        ApplySoftFace(ABtn, SoftBtnFacePrimary);
      end;
    spbrCommand:
      begin
        ABtn.Font.Style := [];
        ABtn.Font.Color := SoftBtnTextMuted;
        ApplySoftFace(ABtn, SoftBtnFaceCommand);
      end;
    spbrQuiet:
      begin
        ABtn.Font.Style := [];
        ABtn.Font.Color := SoftBtnTextMuted;
        ApplySoftFace(ABtn, SoftBtnFaceQuiet);
      end;
  else
    { spbrAction }
    ABtn.Font.Style := [];
    ABtn.Font.Color := SoftBtnText;
    ApplySoftFace(ABtn, SoftBtnFaceAction);
  end;
end;

procedure StyleSoftPanelFrameBtn(ABtn: TsButton; const AUiFont: string);
begin
  if not Assigned(ABtn) then Exit;
  ABtn.ParentFont := False;
  ABtn.Font.Name := AUiFont;
  ABtn.Font.Size := 11;
  ABtn.Font.Style := [];
  ABtn.Font.Color := SoftBtnTextMuted;
  ABtn.ShowHint := True;
  ABtn.TabStop := False;
  ABtn.Cursor := crHandPoint;
  try
    ABtn.SkinData.SkinSection := 'TOOLBUTTON';
    ABtn.SkinData.CustomFont := True;
    ABtn.SkinData.CustomColor := False;
    ABtn.SkinData.ColorTone := SoftBtnFaceQuiet;
  except
  end;
end;

function ChevronUsesIconFont: Boolean;
begin
  Result := Screen.Fonts.IndexOf('Segoe MDL2 Assets') >= 0;
end;

function CreatePanelChevron(AOwner: TComponent; AParent: TWinControl;
  AOnClick: TNotifyEvent): TsSpeedButton;
begin
  Result := TsSpeedButton.Create(AOwner);
  Result.Parent := AParent;
  Result.Flat := True;
  Result.ShowCaption := True;
  Result.ShowHint := True;
  Result.ParentShowHint := False;
  Result.Cursor := crHandPoint;
  Result.ParentFont := False;
  if ChevronUsesIconFont then
  begin
    Result.Font.Name := 'Segoe MDL2 Assets';
    Result.Font.Size := 8;
  end
  else
  begin
    Result.Font.Name := FONT_SEGOE_UI;
    Result.Font.Size := 9;
  end;
  Result.Font.Color := SoftBtnTextMuted;
  Result.Width := FfPx(22);
  try
    Result.SkinData.SkinSection := 'TOOLBUTTON';
  except
  end;
  Result.OnClick := AOnClick;
  SyncPanelChevron(Result, False);
end;

procedure SyncPanelChevron(ABtn: TsSpeedButton; ACollapsed: Boolean);
begin
  if not Assigned(ABtn) then Exit;
  if ChevronUsesIconFont then
  begin
    if not ACollapsed then
      ABtn.Caption := #$E70D            { chevron down }
    else if BidiIsRtl then
      ABtn.Caption := #$E76B            { chevron left }
    else
      ABtn.Caption := #$E76C;           { chevron right }
  end
  else if not ACollapsed then
    ABtn.Caption := #$25BE
  else if BidiIsRtl then
    ABtn.Caption := #$25C2
  else
    ABtn.Caption := #$25B8;
  if ACollapsed then
    ABtn.Hint := TrText('SearchDock.Expand')
  else
    ABtn.Hint := TrText('SearchDock.Collapse');
end;

procedure SyncCollapseMask(var AMask: TsPanel; AOwner: TComponent;
  AParent: TWinControl; ATop: Integer; AColor: TColor; ACollapsed: Boolean);
begin
  if not Assigned(AParent) then Exit;
  if not ACollapsed then
  begin
    if Assigned(AMask) then
      AMask.Visible := False;
    Exit;
  end;
  if not Assigned(AMask) then
  begin
    AMask := TsPanel.Create(AOwner);
    AMask.Parent := AParent;
    AMask.BevelOuter := bvNone;
    AMask.Caption := '';
    AMask.ParentBackground := False;
    AMask.ParentColor := False;
    try
      AMask.SkinData.CustomColor := True;
      AMask.SkinData.SkinSection := '';
    except
    end;
  end;
  AMask.Color := AColor;
  { Oversized so it needs no update when the card is resized. }
  AMask.SetBounds(0, ATop, 8000, 8000);
  AMask.Visible := True;
  AMask.BringToFront;
end;

function FlowSoftPanelButtons(const ABtns: array of TsButton; ACanvas: TCanvas;
  ALeft, ATop, AWidth, ABtnH, AGap, AMinW, APadX: Integer): Integer;
var
  Vis: array of TsButton;
  Nat: array of Integer;
  I, N, W, Y, RowStart, RowW: Integer;

  procedure PlaceRow(AFrom, ATo: Integer);
  var
    K, Used, Slack, Add, X, BW: Integer;
  begin
    Used := (ATo - AFrom) * AGap;
    for K := AFrom to ATo do
      Inc(Used, Nat[K]);
    Slack := AWidth - Used;
    if (Slack < 0) or (Slack * 3 > AWidth) then
      Slack := 0;
    X := ALeft;
    for K := AFrom to ATo do
    begin
      BW := Nat[K];
      if Slack > 0 then
      begin
        Add := Slack div (ATo - K + 1);
        Inc(BW, Add);
        Dec(Slack, Add);
      end;
      Vis[K].SetBounds(X, Y, BW, ABtnH);
      Inc(X, BW + AGap);
    end;
  end;

begin
  Result := 0;
  if (AWidth <= 0) or not Assigned(ACanvas) then Exit;
  SetLength(Vis, Length(ABtns));
  SetLength(Nat, Length(ABtns));
  N := 0;
  for I := 0 to High(ABtns) do
  begin
    if not Assigned(ABtns[I]) or not ABtns[I].Visible then Continue;
    ACanvas.Font.Assign(ABtns[I].Font);
    { The measuring canvas uses screen DPI; the skinned face draws at the
      app PPI, so scale the text to match. }
    W := MulDiv(ACanvas.TextWidth(ABtns[I].Caption), FfPx(100), 100) + APadX;
    if W < AMinW then
      W := AMinW;
    if W > AWidth then
      W := AWidth;
    Vis[N] := ABtns[I];
    Nat[N] := W;
    Inc(N);
  end;
  if N = 0 then Exit;
  Y := ATop;
  RowStart := 0;
  RowW := Nat[0];
  for I := 1 to N - 1 do
  begin
    if RowW + AGap + Nat[I] > AWidth then
    begin
      PlaceRow(RowStart, I - 1);
      Inc(Y, ABtnH + AGap);
      RowStart := I;
      RowW := Nat[I];
    end
    else
      Inc(RowW, AGap + Nat[I]);
  end;
  PlaceRow(RowStart, N - 1);
  Result := Y + ABtnH - ATop;
end;

end.
