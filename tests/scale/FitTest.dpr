program FitTest;

{$APPTYPE CONSOLE}

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, StdCtrls, ExtCtrls, uFastFileScale;

var
  F: TForm;
  Fails: Integer;

function Btn(AParent: TWinControl; const ACap: string; L, T, W: Integer): TButton;
begin
  Result := TButton.Create(F);
  Result.Parent := AParent;
  Result.Caption := ACap;
  Result.SetBounds(L, T, W, 25);
end;

procedure Check(const AName: string; ACond: Boolean; const AInfo: string);
begin
  if ACond then
    Writeln('ok   ', AName, '  ', AInfo)
  else
  begin
    Writeln('FAIL ', AName, '  ', AInfo);
    Inc(Fails);
  end;
end;

function PostDisplayChange(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
begin
  PostMessage(AWnd, WM_DISPLAYCHANGE, 32, 0);
  Result := True;
end;

function Info(C: TControl): string;
begin
  Result := Format('L=%d W=%d R=%d', [C.Left, C.Width, C.Left + C.Width]);
end;

var
  A, B, Edge, RightA, Both, Fits: TButton;
  Row: TPanel;
  D1, D2: TButton;
  Cl: TPanel;
  Lbl: TLabel;
  Chk: TCheckBox;
  T0: Cardinal;
  I: Integer;
begin
  Fails := 0;
  Application.Initialize;
  F := TForm.CreateNew(nil);
  F.SetBounds(100, 100, 700, 400);
  F.Show;

  { 1. Clipped button with a neighbour 10 px to the right: grows only up to the neighbour. }
  A := Btn(F, 'A very long translated caption here', 10, 10, 60);
  B := Btn(F, 'B', 80, 10, 60);
  { 2. Clipped button with free space: grows to fit. }
  Edge := Btn(F, 'Another long caption for testing', 10, 50, 60);
  { 3. Right-anchored: grows to the left, right edge fixed. }
  RightA := Btn(F, 'Right anchored long caption', 600, 90, 60);
  RightA.Anchors := [akTop, akRight];
  { 4. Anchored both sides: untouched. }
  Both := Btn(F, 'Stretched long caption text', 10, 130, 60);
  Both.Anchors := [akLeft, akTop, akRight];
  { 5. Caption already fits: untouched. }
  Fits := Btn(F, 'Ok', 10, 170, 80);
  { 6. Docked row with a client panel: row may not squeeze the client below 120 px. }
  Row := TPanel.Create(F);
  Row.Parent := F;
  Row.SetBounds(0, 210, 300, 30);
  D1 := Btn(Row, 'Docked left with long caption', 0, 0, 60);
  D1.Align := alLeft;
  D2 := Btn(Row, 'Second docked long caption', 100, 0, 60);
  D2.Align := alLeft;
  Cl := TPanel.Create(F);
  Cl.Parent := Row;
  Cl.Align := alClient;
  { 7. Auto-size label and a fixed label next to a check box. }
  Lbl := TLabel.Create(F);
  Lbl.Parent := F;
  Lbl.AutoSize := False;
  Lbl.SetBounds(10, 260, 40, 15);
  Lbl.Caption := 'Fixed width label clipped';
  Chk := TCheckBox.Create(F);
  Chk.Parent := F;
  Chk.SetBounds(300, 258, 60, 17);
  Chk.Caption := 'Check box with long text';
  Application.ProcessMessages;

  T0 := GetTickCount;
  FfFitCaptions(F, True);
  Writeln('first fit ms: ', GetTickCount - T0);

  Check('neighbour', (A.Left + A.Width <= B.Left) and (A.Width > 60), Info(A) + ' B.L=' + IntToStr(B.Left));
  Check('neighbour unmoved', (B.Left = 80) and (B.Width = 60), Info(B));
  Check('free space', Edge.Width > 150, Info(Edge));
  Check('right anchored', (RightA.Left + RightA.Width = 660) and (RightA.Width > 60), Info(RightA));
  Check('both anchors', Both.Width = 60, Info(Both));
  Check('fits', Fits.Width = 80, Info(Fits));
  Check('docked row', Cl.Width >= 118, 'client W=' + IntToStr(Cl.Width) + ' D1 ' + Info(D1) + ' D2 ' + Info(D2));
  Check('label grows to check box', (Lbl.Width > 40) and (Lbl.Left + Lbl.Width <= Chk.Left), Info(Lbl));
  Check('check box', Chk.Width > 60, Info(Chk));
  Check('vertical untouched', (A.Top = 10) and (Edge.Top = 50) and (Lbl.Top = 260), '');

  { Second call with nothing changed must be skipped (signature) and cheap. }
  T0 := GetTickCount;
  for I := 1 to 1000 do
    FfFitCaptions(F);
  Writeln('1000 unchanged calls ms: ', GetTickCount - T0);
  Check('stable', B.Left = 80, Info(A));

  { Still clipped (neighbour too close): full caption as hint; a hint set by the form is kept. }
  Check('auto hint on clipped', (A.Hint = A.Caption) and A.ShowHint, 'hint="' + A.Hint + '"');
  Both.Hint := 'own hint';
  FfFitCaptions(F, True);
  Check('own hint kept', Both.Hint = 'own hint', 'hint="' + Both.Hint + '"');
  Check('fits: no hint', Fits.Hint = '', 'hint="' + Fits.Hint + '"');
  A.Caption := 'Short';
  FfFitCaptions(F, True);
  Check('auto hint removed when it fits', A.Hint = '', 'hint="' + A.Hint + '"');
  A.Caption := 'A very long translated caption here';
  FfFitCaptions(F, True);
  Check('auto hint follows caption', A.Hint = A.Caption, 'hint="' + A.Hint + '"');

  { Resolution change: a window bigger than the screen comes back inside the work area. }
  FfInstallFormLayoutManager;
  F.SetBounds(-50, -50, Screen.WorkAreaWidth + 900, Screen.WorkAreaHeight + 700);
  Edge.Caption := 'Caption changed after the display switch, longer';
  Edge.Width := 60;
  EnumThreadWindows(GetCurrentThreadId, @PostDisplayChange, 0);
  T0 := GetTickCount;
  while GetTickCount - T0 < 1500 do
  begin
    Application.ProcessMessages;
    Sleep(10);
  end;
  Check('display change: inside work area',
    (F.Width <= Screen.WorkAreaWidth) and (F.Height <= Screen.WorkAreaHeight) and (F.Left >= Screen.WorkAreaLeft),
    Format('L=%d W=%d H=%d work=%dx%d', [F.Left, F.Width, F.Height, Screen.WorkAreaWidth, Screen.WorkAreaHeight]));
  Check('display change: captions re-fitted', Edge.Width > 150, Info(Edge));

  F.Free;
  Writeln('fails=', Fails);
  ExitCode := Fails;
end.
