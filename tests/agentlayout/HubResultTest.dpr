program HubResultTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommDlg, System.SysUtils, System.Classes,
  System.Types, Vcl.Forms, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus,
  sMemo, sSpeedButton, sCheckBox, sScrollBox, sConst, UnDM, uI18n, uAgentHubWorkspace;

type
  THarness = class
    Workspace: TfrmAgentHubWorkspace;
    Timer: TTimer;
    SavePath: string;
    FilterIndex: Integer;
    CancelDialog: Boolean;
    CloseMenu: Boolean;
    Attempts: Integer;
    procedure Tick(Sender: TObject);
    procedure Error(Sender: TObject; E: Exception);
  end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure Pump;
var
  Deadline: UInt64;
begin
  Deadline := GetTickCount64 + 100;
  repeat
    Application.ProcessMessages;
    CheckSynchronize;
    Sleep(5);
  until GetTickCount64 >= Deadline;
end;

procedure THarness.Error(Sender: TObject; E: Exception);
begin
  Writeln('FAIL: ', E.ClassName, ': ', E.Message);
  Flush(Output);
  ExitProcess(1);
end;

function FindFilenameEdit(Wnd: HWND; Param: LPARAM): BOOL; stdcall;
var
  Kind: array[0..31] of Char;
begin
  GetClassName(Wnd, Kind, Length(Kind));
  Result := True;
  if (string(Kind) = 'Edit') and (GetDlgCtrlID(Wnd) = $047C) then
  begin
    PNativeUInt(Param)^ := NativeUInt(Wnd);
    Result := False;
  end;
end;

procedure THarness.Tick(Sender: TObject);
var
  I: Integer;
  Dlg: TSaveDialog;
  DialogWnd: HWND;
  EditWnd: HWND;
  NativeName: array[0..1023] of Char;
begin
  Inc(Attempts);
  Check(Attempts < 50, 'Timed out waiting for dialog');
  if CloseMenu then
  begin
    Timer.Enabled := False;
    EndMenu;
    Exit;
  end;
  for I := 0 to Workspace.ComponentCount - 1 do
    if Workspace.Components[I] is TSaveDialog then
    begin
      Dlg := TSaveDialog(Workspace.Components[I]);
      if Dlg.Handle = 0 then Continue;
      DialogWnd := GetAncestor(Dlg.Handle, GA_ROOT);
      if not IsWindowVisible(DialogWnd) or (Attempts < 5) then Exit;
      Timer.Enabled := False;
      if CancelDialog then
      begin
        PostMessage(DialogWnd, WM_COMMAND, IDCANCEL, 0);
        Exit;
      end;
      SendDlgItemMessage(DialogWnd, $0470, CB_SETCURSEL, FilterIndex - 1, 0);
      SendMessage(DialogWnd, WM_COMMAND, MakeWParam($0470, CBN_SELCHANGE),
        LPARAM(GetDlgItem(DialogWnd, $0470)));
      EditWnd := 0;
      EnumChildWindows(DialogWnd, @FindFilenameEdit, LPARAM(@EditWnd));
      Check(EditWnd <> 0, 'Native filename edit missing');
      Winapi.Windows.SetFocus(EditWnd);
      SendMessage(EditWnd, EM_SETSEL, 0, -1);
      SendMessage(EditWnd, EM_REPLACESEL, 1, LPARAM(PChar(SavePath)));
      GetWindowText(EditWnd, NativeName, Length(NativeName));
      Check(string(NativeName) = SavePath, 'Native filename was not set');
      PostMessage(DialogWnd, WM_COMMAND, IDOK, 0);
      Exit;
    end;
end;

procedure CheckToolbar(Btn: TsSpeedButton);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to Btn.Parent.ControlCount - 1 do
  begin
    C := Btn.Parent.Controls[I];
    Check(C.Left >= 0, 'Toolbar button outside left edge');
    Check(C.Left + C.Width <= Btn.Parent.ClientWidth, 'Toolbar button clipped horizontally');
    Check(C.Top + C.Height <= Btn.Parent.ClientHeight, 'Toolbar button clipped vertically');
  end;
end;

procedure CheckOptions(Workspace: TfrmAgentHubWorkspace);
var
  I, Count: Integer;
  C, P: TControl;
  Bottom, MousePos: TPoint;
  Scroll: TsScrollBox;
begin
  Count := 0;
  Scroll := nil;
  for I := 0 to Workspace.ComponentCount - 1 do
  begin
    if not (Workspace.Components[I] is TsCheckBox) then Continue;
    C := TControl(Workspace.Components[I]);
    Inc(Count);
    P := C.Parent;
    while (P <> nil) and not (P is TsScrollBox) do P := P.Parent;
    Check(P is TsScrollBox, 'Diagnosis option has no scrollable viewport');
    Scroll := TsScrollBox(P);
    Scroll.ScrollInView(C);
    Bottom := C.ClientToScreen(Point(C.Width, C.Height));
    P := C.Parent;
    while P <> nil do
    begin
      Check(P.ScreenToClient(Bottom).Y <= P.ClientHeight,
        Format('Clipped option "%s" in %s: bottom=%d height=%d',
          [TsCheckBox(C).Caption, P.ClassName, P.ScreenToClient(Bottom).Y, P.ClientHeight]));
      Check(P.ScreenToClient(C.ClientToScreen(Point(0, 0))).Y >= 0,
        'Diagnosis option top clipped: ' + TsCheckBox(C).Caption);
      Check(P.ScreenToClient(Bottom).X <= P.ClientWidth,
        'Diagnosis option right edge clipped: ' + TsCheckBox(C).Caption);
      P := P.Parent;
    end;
  end;
  Check(Count = 7, 'Did not exercise options and all six specialists');
  Check((Scroll <> nil) and (Scroll.VertScrollBar.Position > 0),
    'Compact layout did not scroll to lower specialists');
  Scroll.VertScrollBar.Position := 0;
  Check(Scroll.VertScrollBar.Position = 0, 'Cannot return to the source controls');
  Workspace.ActiveControl := nil;
  MousePos := Scroll.ClientToScreen(Point(5, 5));
  SendMessage(Scroll.Handle, WM_MOUSEWHEEL, MakeWParam(0, Word(SmallInt(-WHEEL_DELTA))),
    MakeLParam(MousePos.X, MousePos.Y));
  Check(Scroll.VertScrollBar.Position > 0, 'Left column mouse wheel did not scroll');
  Scroll.VertScrollBar.Position := 0;
end;

var
  H: THarness;
  Host: TForm;
  Viewport: TPanel;
  Memo: TsMemo;
  ExportBtn, TranslateBtn: TsSpeedButton;
  Menu: TPopupMenu;
  Lang: TAppLanguage;
  SL: TStringList;
  I, BeforeLine, AfterLine: Integer;
  Expected, Ext: string;
begin
  try
    Application.Initialize;
    if GetEnvironmentVariable('FASTFILE_TEST_PPI') <> '' then
    begin
      Application.CreateForm(TDataModule1, DataModule1);
      DataModule1.sSkinManager1.Options.PixelsPerInch :=
        StrToInt(GetEnvironmentVariable('FASTFILE_TEST_PPI'));
      DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
    end;
    UseLatestCommonDialogs := False;
    H := THarness.Create;
    Application.OnException := H.Error;
    Host := TForm.Create(nil);
    Host.SetBounds(0, 0, 1100, 760);
    Viewport := TPanel.Create(Host);
    Viewport.Parent := Host;
    Viewport.BevelOuter := bvNone;
    Viewport.SetBounds(0, 0, 1100, 760);
    H.Workspace := TfrmAgentHubWorkspace.ExecuteEmbedded(Host, Viewport);
    H.Workspace.Show;
    Host.Show;
    Pump;
    Memo := H.Workspace.FindComponent('memAnswer') as TsMemo;
    ExportBtn := H.Workspace.FindComponent('btnAnswerExport') as TsSpeedButton;
    TranslateBtn := H.Workspace.FindComponent('btnAnswerTranslate') as TsSpeedButton;
    Check(not ExportBtn.Enabled and not TranslateBtn.Enabled, 'Empty answer actions enabled');
    SL := TStringList.Create;
    for I := 1 to 300 do
      SL.Add(Format('Line %d: ', [I]) + #$00E7#$00E3#$00E9 + ' ' + #$65E5#$672C#$8A9E);
    Memo.Text := SL.Text;
    SL.Free;
    Expected := Memo.Text;
    Check(ExportBtn.Enabled and TranslateBtn.Enabled, 'Answer actions not enabled');
    Memo.SelStart := 0;
    SendMessage(Memo.Handle, EM_SCROLLCARET, 0, 0);
    BeforeLine := SendMessage(Memo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
    SendMessage(Memo.Handle, WM_MOUSEWHEEL, MakeWParam(0, Word(SmallInt(-WHEEL_DELTA))), 0);
    AfterLine := SendMessage(Memo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
    Check(AfterLine > BeforeLine, 'Mouse wheel did not scroll down');
    SendMessage(Memo.Handle, WM_MOUSEWHEEL, MakeWParam(0, WHEEL_DELTA), 0);
    Check(SendMessage(Memo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0) = BeforeLine,
      'Mouse wheel did not scroll up');
    SendMessage(Memo.Handle, WM_MOUSEWHEEL, MakeWParam(0, Word(SmallInt(-60))), 0);
    Check(SendMessage(Memo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0) = BeforeLine,
      'Partial wheel delta scrolled too early');
    SendMessage(Memo.Handle, WM_MOUSEWHEEL, MakeWParam(0, Word(SmallInt(-60))), 0);
    Check(SendMessage(Memo.Handle, EM_GETFIRSTVISIBLELINE, 0, 0) = AfterLine,
      'Partial wheel deltas were not accumulated');
    Writeln('PASS: mouse wheel up/down and high-resolution deltas');

    H.Timer := TTimer.Create(nil);
    H.Timer.Enabled := False;
    H.Timer.Interval := 100;
    H.Timer.OnTimer := H.Tick;
    for Lang := Low(TAppLanguage) to High(TAppLanguage) do
    begin
      SetCurrentLanguage(Lang);
      H.Workspace.ApplyLanguage;
      Check(ExportBtn.Caption = TrText('AICaps.Export'), 'Export caption not translated');
      Check(ExportBtn.Hint = TrText('Hub.ExportAnswerHint'), 'Export hint not translated');
      Check(ExportBtn.Hint <> 'Hub.ExportAnswerHint', 'Export hint key missing');
      if Lang <> alEnglish then
        Check(Pos('Save the diagnosis', ExportBtn.Hint) = 0, 'Export hint fell back to English');
      Check(TranslateBtn.Caption = TrText('Assistant.TranslateBtn') + ' ' + #$25BE,
        'Translate caption not localized');
      Viewport.Width := 900;
      Viewport.Constraints.MaxHeight := 400;
      Viewport.Constraints.MinHeight := 400;
      Viewport.Height := 400;
      Pump;
      H.Workspace.FitTexts;
      CheckToolbar(ExportBtn);
      Check(H.Workspace.Height = Viewport.ClientHeight, 'Diagnosis exceeds its viewport');
      Check(Viewport.Height = 400, Format('Viewport height changed unexpectedly: %d, min=%d, auto=%s',
        [Viewport.Height, Viewport.Constraints.MinHeight, BoolToStr(Viewport.AutoSize, True)]));
      CheckOptions(H.Workspace);
      Viewport.Width := 1300;
      Pump;
      H.Workspace.FitTexts;
      CheckToolbar(ExportBtn);
    end;
    Writeln('PASS: captions, hints and wrapped toolbar in all 14 languages');
    Writeln('PASS: compact layout, all six specialists reachable and left-column wheel in 14 languages');

    H.CloseMenu := True;
    H.Attempts := 0;
    H.Timer.Enabled := True;
    TranslateBtn.Click;
    Menu := H.Workspace.FindComponent('mnuTranslate') as TPopupMenu;
    Check(Menu.Items.Count = 14, 'Translation menu does not contain 14 languages');
    for Lang := Low(TAppLanguage) to High(TAppLanguage) do
    begin
      Check(Menu.Items[Ord(Lang)].Tag = Ord(Lang), 'Translation language mismatch');
      Check(Menu.Items[Ord(Lang)].HelpContext = 4, 'Translation targets prompt instead of answer');
    end;
    H.CloseMenu := False;
    Writeln('PASS: answer translation menu targets all 14 languages');

    for I := 1 to 2 do
    begin
      if I = 1 then Ext := '.txt' else Ext := '.md';
      H.SavePath := ExtractFilePath(ParamStr(0)) + 'hub-result-test' + Ext;
      Check(not FileExists(H.SavePath), 'Export fixture already exists');
      H.FilterIndex := I;
      H.Attempts := 0;
      H.Timer.Enabled := True;
      ExportBtn.Click;
      Check(FileExists(H.SavePath), 'Export file not created');
      SL := TStringList.Create;
      try
        SL.LoadFromFile(H.SavePath, TEncoding.UTF8);
        Check(SL.Text = Expected, 'Export changed Unicode or answer content');
      finally
        SL.Free;
      end;
      Check(DeleteFile(H.SavePath), 'Could not clean up export fixture');
    end;
    H.CancelDialog := True;
    H.Attempts := 0;
    H.Timer.Enabled := True;
    ExportBtn.Click;
    Check(not FileExists(H.SavePath), 'Cancel created an export');
    Check(Memo.Text = Expected, 'Export or cancel modified the answer');
    Writeln('PASS: TXT/Markdown Unicode round trips and export cancellation');
    for I := 0 to ExportBtn.Parent.ControlCount - 1 do
      if (ExportBtn.Parent.Controls[I] is TsSpeedButton) and
        (TsSpeedButton(ExportBtn.Parent.Controls[I]).Caption = TrText('Agent.ToolClear')) then
        TsSpeedButton(ExportBtn.Parent.Controls[I]).Click;
    Pump;
    Check(Memo.Text = '', 'Clear answer button did not clear text');
    Check(not ExportBtn.Enabled and not TranslateBtn.Enabled, 'Cleared answer actions enabled');
    H.Timer.Free;
    Host.Free;
    DataModule1.Free;
    DataModule1 := nil;
    Application.OnException := nil;
    H.Free;
    Writeln('PASS: all diagnosis result tests');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Flush(Output);
      ExitProcess(1);
    end;
  end;
end.
