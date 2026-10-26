program ReadTabLayoutTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, Vcl.Forms, Vcl.Controls, Vcl.ComCtrls,
  sPageControl, sSpeedButton, sConst,
  UnDM, MainUnit, uFastFileScale;

type
  TPageAccess = class(TsPageControl);
  TLayoutProbe = class
  private
    FControl: TWinControl;
    FOriginal: TWndMethod;
    procedure WindowProc(var Msg: TMessage);
  public
    SizeCount: Integer;
    EraseCount: Integer;
    constructor Create(AControl: TWinControl);
    destructor Destroy; override;
    procedure Reset;
  end;
  THarness = class
    procedure HandleException(Sender: TObject; E: Exception);
  end;

var
  ReadMainBounds, ReadCenterBounds, ReadListBounds: TRect;

constructor TLayoutProbe.Create(AControl: TWinControl);
begin
  inherited Create;
  FControl := AControl;
  FOriginal := FControl.WindowProc;
  FControl.WindowProc := WindowProc;
end;

destructor TLayoutProbe.Destroy;
begin
  FControl.WindowProc := FOriginal;
  inherited;
end;

procedure TLayoutProbe.Reset;
begin
  SizeCount := 0;
  EraseCount := 0;
end;

procedure TLayoutProbe.WindowProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_SIZE: Inc(SizeCount);
    WM_ERASEBKGND: Inc(EraseCount);
  end;
  FOriginal(Msg);
end;

procedure THarness.HandleException(Sender: TObject; E: Exception);
begin
  Writeln('FAIL (message loop): ', E.ClassName, ': ', E.Message);
  Flush(Output);
  Halt(1);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure CheckStableLayout(PageProbe, MainProbe, ListProbe: TLayoutProbe);
begin
  Check(PageProbe.SizeCount = 0, 'Activation resized the page control');
  Check(MainProbe.SizeCount = 0, 'Activation resized the read workspace');
  Check(ListProbe.SizeCount = 0, 'Activation resized the file list');
end;

procedure Settle;
var
  UntilTick: UInt64;
begin
  UntilTick := GetTickCount64 + 700;
  repeat
    Application.ProcessMessages;
    CheckSynchronize;
    Sleep(10);
  until GetTickCount64 >= UntilTick;
end;

procedure LoadFixture;
var
  Lines: TStringList;
  I: Integer;
  FixturePath: string;
  Deadline: UInt64;
begin
  FixturePath := ExtractFilePath(ParamStr(0)) + 'read-tab-fixture.txt';
  Lines := TStringList.Create;
  try
    for I := 1 to 200 do
      Lines.Add(Format('Row %d: read tab layout regression fixture', [I]));
    Lines.SaveToFile(FixturePath);
  finally
    Lines.Free;
  end;
  frmMain.edtFileName.Text := FixturePath;
  frmMain.btnReadClick(nil);
  Deadline := GetTickCount64 + 15000;
  repeat
    Settle;
  until ((totalLines = 201) and (frmMain.ListView1.Items.Count > 0)) or
    (GetTickCount64 >= Deadline);
  Check((totalLines = 201) and (frmMain.ListView1.Items.Count > 0),
    Format('Fixture was not loaded: %d lines, %d visual items',
      [totalLines, frmMain.ListView1.Items.Count]));
end;

procedure DumpControl(C: TControl; const AIndent: string);
var
  I: Integer;
  R: TRect;
begin
  Writeln(AIndent, C.Name, ' ', C.ClassName, ' visible=', C.Visible,
    ' bounds=', C.Left, ',', C.Top, ',', C.Width, ',', C.Height);
  if C is TWinControl then
  begin
    if TWinControl(C).HandleAllocated then
    begin
      GetWindowRect(TWinControl(C).Handle, R);
      Writeln(AIndent, ' HWND=', NativeUInt(TWinControl(C).Handle),
        ' visible=', IsWindowVisible(TWinControl(C).Handle),
        ' rect=', R.Left, ',', R.Top, ',', R.Right, ',', R.Bottom);
    end;
    if Length(AIndent) < 12 then
      for I := 0 to TWinControl(C).ControlCount - 1 do
        DumpControl(TWinControl(C).Controls[I], AIndent + '  ');
  end;
end;

procedure ClickTab(APage: TTabSheet);
var
  R: TRect;
  P: TPoint;
begin
  R := frmMain.pgMain.TabRect(APage.TabIndex);
  P := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  SendMessage(frmMain.pgMain.Handle, WM_LBUTTONDOWN, MK_LBUTTON,
    MakeLParam(P.X, P.Y));
  SendMessage(frmMain.pgMain.Handle, WM_LBUTTONUP, 0, MakeLParam(P.X, P.Y));
  Settle;
  Check(frmMain.pgMain.ActivePage = APage, 'Tab click did not activate ' + APage.Name);
end;

procedure CheckReadBounds(const AStage: string);
var
  R, NativeR: TRect;
  P: TPoint;
begin
  Check(frmMain.pgMain.ActivePage = frmMain.tabReadFile, 'Read page not active');
  R := TPageAccess(frmMain.pgMain).DisplayRect;
  Writeln(AStage, ': display=', R.Left, ',', R.Top, ',', R.Right, ',', R.Bottom,
    ' page=', frmMain.tabReadFile.Width, 'x', frmMain.tabReadFile.Height);
  Check(EqualRect(frmMain.tabReadFile.BoundsRect, R), AStage + ': page bounds differ');
  GetWindowRect(frmMain.tabReadFile.Handle, NativeR);
  P := frmMain.pgMain.ClientToScreen(R.TopLeft);
  Check((NativeR.Left = P.X) and (NativeR.Top = P.Y) and
    (NativeR.Width = R.Width) and (NativeR.Height = R.Height),
    AStage + ': native page bounds differ');
  Check(EqualRect(frmMain.pnlMain.BoundsRect, ReadMainBounds),
    AStage + ': read workspace changed size');
  Check(EqualRect(frmMain.pnlCenter.BoundsRect, ReadCenterBounds),
    AStage + ': read center changed size');
  Check(EqualRect(frmMain.ListView1.BoundsRect, ReadListBounds),
    AStage + ': list view changed size');
  Check(ChildWindowFromPointEx(frmMain.pgMain.Handle,
    Point((R.Left + R.Right) div 2, R.Bottom - 2),
    CWP_SKIPINVISIBLE or CWP_SKIPTRANSPARENT) = frmMain.tabReadFile.Handle,
    AStage + ': another page covers the bottom of the read workspace');
  Check(totalLines = 201, AStage + ': loaded file changed');
end;

var
  Btn: TsSpeedButton;
  Hub: TTabSheet;
  Cycle, PPI, ButtonIndex: Integer;
  Harness: THarness;
  Hosted: TForm;
  PageProbe, MainProbe, ListProbe: TLayoutProbe;
const
  ButtonNames: array[0..1] of string = ('btnMainAgentHub', 'btnMainAskFiles');
  PageNames: array[0..1] of string = ('tabAgentHub', 'tabAskFiles');
begin
  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    FfInstallFormLayoutManager;
    Writeln('Creating data module');
    Flush(Output);
    Application.CreateForm(TDataModule1, DataModule1);
    PPI := StrToIntDef(GetEnvironmentVariable('FASTFILE_TEST_PPI'), 120);
    DataModule1.sSkinManager1.Options.PixelsPerInch := PPI;
    DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
    Writeln('Creating main form');
    Flush(Output);
    Application.CreateForm(TfrmMain, frmMain);
    Harness := THarness.Create;
    Application.OnException := Harness.HandleException;
    Writeln('Showing main form');
    Flush(Output);
    frmMain.Show;
    frmMain.WindowState := wsMaximized;
    if GetEnvironmentVariable('FASTFILE_TEST_COMPACT') = '1' then
    begin
      frmMain.WindowState := wsNormal;
      frmMain.SetBounds(0, 0, 1420, 800);
    end;
    Settle;
    begin
      frmMain.btnShowTabReadFileClick(nil);
      Settle;
      PageProbe := TLayoutProbe.Create(frmMain.pgMain);
      MainProbe := TLayoutProbe.Create(frmMain.pnlMain);
      ListProbe := TLayoutProbe.Create(frmMain.ListView1);
      try
        frmMain.btnShowTabReadFileClick(nil);
        Settle;
        CheckStableLayout(PageProbe, MainProbe, ListProbe);
        Writeln('PASS: empty read view activation does not resize controls');
        LoadFixture;
        ReadMainBounds := frmMain.pnlMain.BoundsRect;
        ReadCenterBounds := frmMain.pnlCenter.BoundsRect;
        ReadListBounds := frmMain.ListView1.BoundsRect;
        CheckReadBounds('initial ' + IntToStr(PPI));
        PageProbe.Reset;
        MainProbe.Reset;
        ListProbe.Reset;
        for Cycle := 1 to 3 do
        begin
          frmMain.btnShowTabReadFileClick(nil);
          Settle;
        end;
        Writeln('Repeated read activation: page sizes=', PageProbe.SizeCount,
          ', workspace sizes=', MainProbe.SizeCount, ', list sizes=', ListProbe.SizeCount,
          ', list erases=', ListProbe.EraseCount);
        CheckStableLayout(PageProbe, MainProbe, ListProbe);
        CheckReadBounds('repeated activation');
        for ButtonIndex := Low(ButtonNames) to High(ButtonNames) do
        begin
          Btn := frmMain.FindComponent(ButtonNames[ButtonIndex]) as TsSpeedButton;
          Check(Assigned(Btn), 'Hosted tab button missing');
          Btn.Click;
          Settle;
          Hub := frmMain.pgMain.ActivePage;
          Check(Hub.Name = PageNames[ButtonIndex], 'Hosted page not active');
          Check((Hub.ControlCount > 0) and (Hub.Controls[0] is TForm),
            'Hosted form missing');
          Hosted := TForm(Hub.Controls[0]);
          for Cycle := 1 to 3 do
          begin
            PageProbe.Reset;
            MainProbe.Reset;
            ListProbe.Reset;
            ClickTab(frmMain.tabReadFile);
            Writeln('Return repaints: page sizes=', PageProbe.SizeCount,
              ', workspace sizes=', MainProbe.SizeCount, ', list sizes=', ListProbe.SizeCount,
              ', list erases=', ListProbe.EraseCount);
            CheckStableLayout(PageProbe, MainProbe, ListProbe);
            try
              CheckReadBounds(Format('%s return %d PPI %d', [Hub.Name, Cycle, PPI]));
              Check(Hosted.Parent <> Hub, 'Inactive form is still hosted in the tab');
              Check(not Hosted.Visible, 'Inactive hosted form is visible');
              if Hosted.HandleAllocated then
                Check(not IsWindowVisible(Hosted.Handle), 'Inactive hosted HWND visible');
            except
              DumpControl(frmMain.pgMain, '');
              raise;
            end;
            PageProbe.Reset;
            MainProbe.Reset;
            ListProbe.Reset;
            Settle;
            CheckStableLayout(PageProbe, MainProbe, ListProbe);
            Check(ListProbe.EraseCount = 0, 'Settled read view keeps erasing its background');
            Writeln('PASS: no activation size oscillations or delayed background erases');
            ClickTab(Hub);
            Check(Hosted.Parent = Hub, 'Hosted form not restored to tab');
            Check(IsWindowVisible(Hosted.Handle), 'Active hosted HWND not visible');
            Check((GetWindowLong(Hosted.Handle, GWL_STYLE) and WS_CHILD) <> 0,
              'Hosted form is not a child window');
          end;
          ClickTab(frmMain.tabReadFile);
        end;
      finally
        ListProbe.Free;
        MainProbe.Free;
        PageProbe.Free;
      end;
    end;
    Writeln('PASS: diagnostic/read tab cycles at ', PPI, ' PPI');
    frmMain.Free;
    frmMain := nil;
    DataModule1.Free;
    DataModule1 := nil;
    if not DeleteFile(ExtractFilePath(ParamStr(0)) + 'read-tab-fixture.txt') then
      RaiseLastOSError;
    Application.OnException := nil;
    Harness.Free;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Writeln('Exception RVA: ', IntToHex(NativeUInt(ExceptAddr) - HInstance, 16));
      Flush(Output);
      Halt(1);
    end;
  end;
end.
