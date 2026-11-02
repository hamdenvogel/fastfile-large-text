program BidiMirrorTest;

{$APPTYPE CONSOLE}

{ Verifies uBidiLayout: the same layout is built twice (LTR twin / RTL form).
  Every control rectangle of the RTL form must be the mirror image of its twin,
  also after resizing the form, after controls created later, inside a layout
  scope, and after going back to left-to-right. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types,
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, uI18n, uBidiLayout;

var
  Fails: Integer = 0;
  Checks: Integer = 0;

procedure Check(const What: string; Ok: Boolean);
begin
  Inc(Checks);
  if not Ok then
  begin
    Inc(Fails);
    Writeln('FAIL: ', What);
  end;
end;

function NewPanel(AOwner: TComponent; AParent: TWinControl; AAlign: TAlign;
  AWidth, AHeight: Integer): TPanel;
begin
  Result := TPanel.Create(AOwner);
  Result.Parent := AParent;
  Result.Align := AAlign;
  if AWidth > 0 then Result.Width := AWidth;
  if AHeight > 0 then Result.Height := AHeight;
end;

function BuildLayout: TForm;
var
  F: TForm;
  Client, Inner: TPanel;
  B: TButton;
begin
  F := TForm.CreateNew(nil);
  F.ClientWidth := 800;
  F.ClientHeight := 500;
  NewPanel(F, F, alTop, 0, 40);
  NewPanel(F, F, alLeft, 120, 0);
  NewPanel(F, F, alLeft, 60, 0);
  NewPanel(F, F, alRight, 90, 0);
  NewPanel(F, F, alRight, 50, 0);
  Client := NewPanel(F, F, alClient, 0, 0);

  B := TButton.Create(F);
  B.Parent := Client;
  B.SetBounds(10, 10, 80, 24);
  B := TButton.Create(F);
  B.Parent := Client;
  B.SetBounds(100, 10, 80, 24);
  B := TButton.Create(F);
  B.Parent := Client;
  B.Anchors := [akTop, akRight];
  B.SetBounds(Client.ClientWidth - 90, 50, 80, 24);

  Inner := TPanel.Create(F);
  Inner.Parent := Client;
  Inner.SetBounds(10, 100, 300, 100);
  Inner.Anchors := [akLeft, akTop, akRight];
  Inner.Padding.Left := 12;
  Inner.Padding.Right := 2;
  NewPanel(F, Inner, alLeft, 40, 0);
  NewPanel(F, Inner, alLeft, 30, 0);
  NewPanel(F, Inner, alRight, 25, 0);
  NewPanel(F, Inner, alClient, 0, 0);

  B := TButton.Create(F);
  B.Parent := Inner;
  B.Anchors := [akLeft, akTop];
  B.SetBounds(5, 5, 20, 20);
  B.Align := alNone;

  with TLabel.Create(F) do
  begin
    Parent := Client;
    SetBounds(20, 300, 60, 14);
    Caption := 'x';
  end;
  with TPanel.Create(F) do
  begin
    Parent := Client;
    Align := alBottom;
    Height := 30;
    Margins.Left := 3;
    Margins.Right := 11;
    AlignWithMargins := True;
  end;
  Result := F;
end;

procedure RealignAll(C: TWinControl);
var
  I: Integer;
begin
  C.Realign;
  for I := 0 to C.ControlCount - 1 do
    if C.Controls[I] is TWinControl then
      RealignAll(TWinControl(C.Controls[I]));
end;

procedure Prepare(F: TForm);

  procedure Need(C: TWinControl);
  var
    I: Integer;
    Ctl: TControl;
    A: TAnchors;
  begin
    for I := 0 to C.ControlCount - 1 do
    begin
      Ctl := C.Controls[I];
      { anchor rules recorded while the parent was still being built are stale:
        re-record them from the aligned geometry }
      if (Ctl.Align = alNone) and (Ctl.Anchors <> [akLeft, akTop]) then
      begin
        A := Ctl.Anchors;
        Ctl.Anchors := [akLeft, akTop];
        Ctl.Anchors := A;
      end;
      if Ctl is TWinControl then
        Need(TWinControl(Ctl));
    end;
  end;

  procedure Handles(C: TWinControl);
  var
    I: Integer;
  begin
    C.HandleNeeded;
    for I := 0 to C.ControlCount - 1 do
      if C.Controls[I] is TWinControl then
        Handles(TWinControl(C.Controls[I]));
  end;

begin
  F.Left := -4000;
  F.Top := -4000;
  F.Show;
  Application.ProcessMessages;
  Handles(F);
  RealignAll(F);
  Need(F);
  RealignAll(F);
  Application.ProcessMessages;
end;

procedure Collect(C: TWinControl; List: TList);
var
  I: Integer;
begin
  for I := 0 to C.ControlCount - 1 do
  begin
    List.Add(C.Controls[I]);
    if C.Controls[I] is TWinControl then
      Collect(TWinControl(C.Controls[I]), List);
  end;
end;

{ Rect of every control of B must be the mirror of the one in A. }
procedure CompareMirrored(const What: string; A, B: TForm);
var
  LA, LB: TList;
  I, Wp: Integer;
  CA, CB: TControl;
  Bad: Integer;
begin
  LA := TList.Create;
  LB := TList.Create;
  try
    Collect(A, LA);
    Collect(B, LB);
    Check(What + ': same control count', LA.Count = LB.Count);
    Bad := 0;
    for I := 0 to LA.Count - 1 do
    begin
      CA := TControl(LA[I]);
      CB := TControl(LB[I]);
      Wp := CB.Parent.ClientWidth;
      if (CB.Left <> Wp - CA.Left - CA.Width) or (CB.Width <> CA.Width) or
         (CB.Top <> CA.Top) or (CB.Height <> CA.Height) then
      begin
        Inc(Bad);
        Writeln('   ', What, ' #', I, ' ', CA.ClassName, ' LTR=(', CA.Left, ',', CA.Top, ',', CA.Width, ',',
          CA.Height, ') RTL=(', CB.Left, ',', CB.Top, ',', CB.Width, ',', CB.Height, ') parentW=', Wp);
      end;
    end;
    Check(What + ': all rects mirrored', Bad = 0);
  finally
    LA.Free;
    LB.Free;
  end;
end;

procedure CompareEqual(const What: string; A, B: TForm);
var
  LA, LB: TList;
  I, Bad: Integer;
  CA, CB: TControl;
begin
  LA := TList.Create;
  LB := TList.Create;
  try
    Collect(A, LA);
    Collect(B, LB);
    Check(What + ': same control count', LA.Count = LB.Count);
    Bad := 0;
    for I := 0 to LA.Count - 1 do
    begin
      CA := TControl(LA[I]);
      CB := TControl(LB[I]);
      if (CB.Left <> CA.Left) or (CB.Width <> CA.Width) or (CB.Top <> CA.Top) or
         (CB.Height <> CA.Height) or (CB.Align <> CA.Align) then
      begin
        Inc(Bad);
        Writeln('   ', What, ' #', I, ' ', CA.ClassName, ' A=(', CA.Left, ',', CA.Top, ',', CA.Width, ',',
          CA.Height, ') B=(', CB.Left, ',', CB.Top, ',', CB.Width, ',', CB.Height, ')');
      end;
    end;
    Check(What + ': identical', Bad = 0);
  finally
    LA.Free;
    LB.Free;
  end;
end;

procedure AddLate(F: TForm; Mirrored: Boolean);
var
  I: Integer;
  Client: TWinControl;
begin
  Client := nil;
  for I := 0 to F.ControlCount - 1 do
    if F.Controls[I].Align = alClient then
      Client := TWinControl(F.Controls[I]);
  with TPanel.Create(F) do
  begin
    Parent := Client;
    Align := alLeft;
    Width := 33;
  end;
  with TButton.Create(F) do
  begin
    Parent := Client;
    SetBounds(200, 60, 70, 22);
  end;
  if Mirrored then
    BidiApplyControl(Client);
end;

var
  A, B: TForm;
begin
  try
    A := BuildLayout;
    B := BuildLayout;
    Prepare(A);
    Prepare(B);
    CompareEqual('twins before', A, B);

    BidiSetManual(True);
    BidiApplyForm(B);
    RealignAll(B);
    CompareMirrored('rtl', A, B);
    Check('Application.BiDiMode is RTL', Application.BiDiMode = bdRightToLeft);

    { idempotent }
    BidiApplyForm(B);
    CompareMirrored('rtl idempotent', A, B);

    { resize both }
    A.ClientWidth := 1000;
    B.ClientWidth := 1000;
    Application.ProcessMessages;
    RealignAll(A);
    RealignAll(B);
    CompareMirrored('rtl after resize', A, B);

    { controls created later }
    AddLate(A, False);
    AddLate(B, True);
    RealignAll(A);
    RealignAll(B);
    CompareMirrored('rtl late controls', A, B);

    { back to left-to-right }
    BidiSetManual(False);
    BidiApplyForm(B);
    RealignAll(B);
    CompareEqual('back to ltr', A, B);
    Check('Application.BiDiMode is LTR', Application.BiDiMode = bdLeftToRight);

    { and mirrored again }
    BidiSetManual(True);
    BidiApplyForm(B);
    RealignAll(B);
    CompareMirrored('rtl again', A, B);

    Writeln(Format('%d checks, %d failed', [Checks, Fails]));
    A.Free;
    B.Free;
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
  if Fails > 0 then Halt(1);
end.
