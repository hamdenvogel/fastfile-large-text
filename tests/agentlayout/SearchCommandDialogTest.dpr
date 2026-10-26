program SearchCommandDialogTest;

{$APPTYPE CONSOLE}

uses
  Windows, Messages, SysUtils, Classes, IOUtils, Forms, Controls, StdCtrls, ExtCtrls,
  uSearchCommands, uSearchCommandDialog, uAgentPrefs, uI18n, uBookmarkBar,
  UnDM, MainUnit, sConst, uFastFileScale, uFastFileAssistantHost,
  uFilterBar, uFindOccurrencesBar, sButton, sMemo, uAgentWorkspace, uAgentHubWorkspace,
  uFastFileAssistant, UnConsts;

type
  TDriver = class
    Mode, Stage: Integer;
    Started: UInt64;
    Paged, TimedOut: Boolean;
    LastMessage: string;
    ExpectedCommand: string;
    Launches: Integer;
    CompletedSearches: Integer;
    procedure Tick(Sender: TObject);
  end;

var
  FakeAnswer, FakeError, FakePrompt: string;
  FakeCalls: Integer;

function FakeAI(const APrompt: WideString; out AAnswer: WideString;
  out AError: string): Boolean;
begin
  Inc(FakeCalls);
  FakePrompt := APrompt;
  Sleep(200);
  AAnswer := FakeAnswer;
  AError := FakeError;
  Result := AError = '';
end;

procedure TDriver.Tick(Sender: TObject);
var
  D: TForm;
  B, OpenBtn, NextBtn: TButton;
  I: Integer;
  Generate, Run: TButton;
  Edit: TEdit;
  Choices: TComboBox;
  Body, Version: string;
begin
  D := Screen.ActiveForm;
  if D = nil then Exit;
  if (Mode = 15) or (Mode = 16) then
  begin
    if ((Mode = 15) and (D.Caption <> TrText('FastFile - Help & Feature Reference'))) or
      ((Mode = 16) and (D.Caption <> TrText('Version History'))) then Exit;
    Body := '';
    for I := 0 to D.ComponentCount - 1 do
      if D.Components[I] is TMemo then Body := TMemo(D.Components[I]).Text;
    if Mode = 15 then
    begin
      if (Pos('Version ' + APPLICATION_VERSION, Body) = 0) or
        (Pos(SearchCommandHelp, Body) = 0) or
        (Pos('SearchCmd.WorkflowHelp', Body) > 0) then
        raise Exception.Create('General F1 help must include current version and shared localized command help');
    end
    else
      for Version in TArray<string>.Create('3.0.5.240', '3.0.5.241', '3.0.5.242', '3.0.5.243', '3.0.5.244') do
        if (Length(Body) - Length(StringReplace(Body, '  v' + Version + ' ', '', [rfReplaceAll]))) <>
          Length('  v' + Version + ' ') then
          raise Exception.Create('Version History must contain each internal version exactly once: ' + Version);
    Inc(Launches);
    D.ModalResult := mrCancel;
    Exit;
  end;
  if GetTickCount64 - Started > 30000 then
  begin
    TimedOut := True;
    LastMessage := D.ClassName + ': ' + D.Caption;
    if D.FindComponent('SearchExplanation') is TMemo then
      LastMessage := LastMessage + ' ' + TMemo(D.FindComponent('SearchExplanation')).Text;
    for I := 0 to D.ComponentCount - 1 do
      if D.Components[I] is TLabel then
        LastMessage := LastMessage + ' ' + TLabel(D.Components[I]).Caption;
    D.ModalResult := mrCancel;
    Exit;
  end;
  if (Mode = 3) and (D.ClassName = 'TFfMsgForm') then
  begin
    LastMessage := '';
    for I := 0 to D.ComponentCount - 1 do
      if D.Components[I] is TLabel then
        LastMessage := LastMessage + ' ' + TLabel(D.Components[I]).Caption;
    D.ModalResult := mrOk;
    Exit;
  end;
  if D.Caption <> 'glob / grep' then Exit;
  if Mode = 12 then
  begin
    Edit := TEdit(D.FindComponent('SearchCommand'));
    Choices := TComboBox(D.FindComponent('SearchSuggestions'));
    if Edit.Text <> ExpectedCommand then
      raise Exception.Create('Launcher preserves selected command: ' + Edit.Text);
    if (Choices.Items.Count < 3) or
      not TButton(D.FindComponent('SearchAIGenerate')).Enabled then
      raise Exception.Create('Launcher shows mode suggestions and AI without starting scan');
    for I := 0 to Choices.Items.Count - 1 do
      if Pos(ExpectedCommand + ' ', Choices.Items[I]) <> 1 then
        raise Exception.Create('Launcher offers mode-specific examples');
    Inc(Launches);
    D.ModalResult := mrCancel;
    Exit;
  end;
  if Mode = 14 then
  begin
    if Stage = 0 then
    begin
      Stage := 1;
      TEdit(D.FindComponent('SearchCommand')).Text := ExpectedCommand;
      TButton(D.FindComponent('SearchRun')).Click;
      Exit;
    end;
  end;
  if (Mode >= 4) and (Mode <> 14) then
  begin
    Generate := TButton(D.FindComponent('SearchAIGenerate'));
    Run := TButton(D.FindComponent('SearchRun'));
    Edit := TEdit(D.FindComponent('SearchCommand'));
    if Stage = 0 then
    begin
      TEdit(D.FindComponent('SearchAIRequest')).Text := 'Find error in logs';
      Generate.Click;
      Stage := 1;
      if Mode = 7 then TButton(D.FindComponent('SearchStop')).Click;
      Exit;
    end;
    if (Stage = 1) and Generate.Enabled then
    begin
      if (Mode = 4) or (Mode = 11) then
      begin
        if ((Mode = 4) and (Edit.Text <> 'grep --mark -F "error"')) or
          ((Mode = 11) and (Edit.Text <> 'grep --bookmarks --mark -F "error"')) then
          raise Exception.Create('AI fills editable command');
        if TButton(D.FindComponent('SearchRun')).ModalResult <> mrNone then
          raise Exception.Create('AI must not execute on generation');
        Run.Click;
        Stage := 2;
      end
      else if (Mode = 9) or (Mode = 13) then
      begin
        Run.Click;
        if Mode = 9 then LastMessage := TrText('SearchCmd.Index')
        else LastMessage := TrText('SearchCmd.BookmarkUnavailable');
        if Pos(LastMessage,
          TMemo(D.FindComponent('SearchExplanation')).Text) = 0 then
          raise Exception.Create('AI bookmark command must require indexing');
        D.ModalResult := mrCancel;
      end
      else if Mode = 10 then
      begin
        Choices := TComboBox(D.FindComponent('SearchSuggestions'));
        if Choices.Items.Count <> 1 then raise Exception.Create('AI suggestions populated');
        Choices.ItemIndex := 0;
        Choices.OnChange(Choices);
        if Edit.Text <> 'grep --mark -F "error 85"' then
          raise Exception.Create('AI suggestion is editable');
        Run.Click;
        Stage := 2;
      end
      else
      begin
        if Mode = 8 then
        begin
          if Edit.Text <> '' then raise Exception.Create('Ambiguous AI request invented command');
        end
        else if (Pos(TrText('SearchCmd.AIInvalid'),
          TMemo(D.FindComponent('SearchExplanation')).Text) = 0) and
          (Pos('offline test', TMemo(D.FindComponent('SearchExplanation')).Text) = 0) then
          raise Exception.Create('AI failure must be visible');
        D.ModalResult := mrCancel;
      end;
    end;
    Exit;
  end;
  if Mode = 0 then
  begin
    D.ModalResult := mrCancel;
    Exit;
  end;
  OpenBtn := nil;
  NextBtn := nil;
  for I := 0 to D.ComponentCount - 1 do
    if D.Components[I] is TButton then
    begin
      B := TButton(D.Components[I]);
      if B.Caption = TrText('Open') then OpenBtn := B;
      if B.Caption = '>' then NextBtn := B;
    end;
  if ((Mode = 1) or (Mode = 14)) and Assigned(OpenBtn) and OpenBtn.Enabled then
  begin
    if not Paged and Assigned(NextBtn) and NextBtn.Enabled then
    begin
      NextBtn.Click;
      Paged := True;
    end;
    Inc(CompletedSearches);
    OpenBtn.Click;
  end;
end;

procedure Check(Ok: Boolean; const Name: string);
begin
  if not Ok then raise Exception.Create(Name);
end;

procedure Settle;
var
  UntilTick: UInt64;
begin
  UntilTick := GetTickCount64 + 100;
  repeat
    Application.ProcessMessages;
    CheckSynchronize;
    Sleep(5);
  until GetTickCount64 >= UntilTick;
end;

function LabelText(Host: TWinControl): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Host.ControlCount - 1 do
    if Host.Controls[I] is TLabel then
      Result := Result + ' ' + TLabel(Host.Controls[I]).Caption
    else if Host.Controls[I] is TWinControl then
      Result := Result + LabelText(TWinControl(Host.Controls[I]));
end;

procedure CheckLauncherLayout;
var
  Host: TForm;
  Filter: TFastFileFilterBar;
  Find: TFastFileFindOccBar;
  Marks: TFastFileBookmarkBar;
  Bar: TWinControl;
  Language: TAppLanguage;
  Width: Integer;
  Name: string;
  Button: TsButton;
  Other: TControl;
  I: Integer;
  Overlap: TRect;
begin
  Host := TForm.CreateNew(nil);
  try
    Host.ClientWidth := FfPx(1200);
    Host.ClientHeight := FfPx(900);
    Filter := TFastFileFilterBar.Create(Host);
    Filter.Parent := Host;
    Filter.Align := alNone;
    Filter.Visible := True;
    Filter.SetResultsActionsVisible(True);
    Find := TFastFileFindOccBar.Create(Host);
    Find.Parent := Host;
    Find.Align := alNone;
    Find.Visible := True;
    Marks := TFastFileBookmarkBar.Create(Host);
    Marks.Parent := Host;
    Marks.Align := alNone;
    Marks.Visible := True;
    for Language := Low(TAppLanguage) to High(TAppLanguage) do
    begin
      SetCurrentLanguage(Language);
      Filter.ApplyCaptions;
      Find.ApplyCaptions;
      Marks.ApplyCaptions;
      for Width in TArray<Integer>.Create(600, 800, 1200) do
        for Bar in TArray<TWinControl>.Create(Filter, Find, Marks) do
        begin
          Bar.Width := FfPx(Width);
          for Name in TArray<string>.Create('SearchGrep', 'SearchGlob') do
          begin
            Button := TsButton(Bar.FindComponent(Name));
            Check(Assigned(Button) and Button.Visible and Button.Enabled,
              'launcher remains available in empty bars');
            Check((Button.Left >= 0) and
              (Button.Left + Button.Width <= Button.Parent.ClientWidth) and
              (Button.Top + Button.Height <= Button.Parent.ClientHeight),
              Format('%s fits %s at %d in %s', [Name, Bar.ClassName, Width, AppLanguageCode(Language)]));
            for I := 0 to Button.Parent.ControlCount - 1 do
            begin
              Other := Button.Parent.Controls[I];
              if (Other <> Button) and Other.Visible then
                Check(not IntersectRect(Overlap, Button.BoundsRect, Other.BoundsRect),
                  'launcher overlaps ' + Other.ClassName + ' in ' + Bar.ClassName);
            end;
          end;
        end;
    end;
  finally
    Host.Free;
    SetCurrentLanguage(alEnglish);
  end;
end;

var
  Driver: TDriver;
  Timer: TTimer;
  Roots, Lines: TStringList;
  Prefs: TAgentPrefs;
  Data: TSearchResult;
  Hit: TSearchHit;
  Mark, Ok: Boolean;
  Path, OtherPath, LargePath: string;
  I: Integer;
  Deadline: UInt64;
  Step: TAssistantChainStep;
  Bar: TWinControl;
  Cmd: string;
  J, OldLaunches, BarCount: Integer;
  LaunchButton: TsButton;
  WorkspaceHost: TForm;
  Agent: TfrmAgentWorkspace;
  Hub: TfrmAgentHubWorkspace;
  Stream: TFileStream;
  BytesReturned: DWORD;
  Bytes: TBytes;
  Started: UInt64;
begin
  try
    Application.Initialize;
    SetCurrentLanguage(alEnglish);
    CheckLauncherLayout;
    Path := TPath.Combine(TPath.GetTempPath, TPath.GetRandomFileName + '.log');
    Driver := TDriver.Create;
    Timer := TTimer.Create(nil);
    Roots := TStringList.Create;
    Lines := TStringList.Create;
    try
      for I := 1 to 105 do Lines.Add('error ' + IntToStr(I));
      Lines.SaveToFile(Path, TEncoding.UTF8);
      Roots.Add('F|' + Path);
      Prefs := DefaultAgentPrefs;
      Timer.Interval := 50;
      Timer.OnTimer := Driver.Tick;
      Driver.Started := GetTickCount64;
      Driver.Mode := 0;
      Ok := ShowSearchCommand(nil, 'grep --help', Roots, Prefs, Path, nil, Data, Hit, Mark);
      Check(not Ok and not Driver.TimedOut, 'help opens and closes');
      for Cmd in TArray<string>.Create('grep', 'glob') do
      begin
        Driver.Mode := 12;
        Driver.ExpectedCommand := Cmd;
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.Launches;
        Roots.Clear;
        Ok := ShowSearchCommand(nil, Cmd, Roots, Prefs, '', nil, Data, Hit, Mark);
        Check(not Ok and (Length(Data.Hits) = 0) and
          (Driver.Launches = OldLaunches + 1), 'bare command opens without sources or scan');
      end;
      Roots.Add('F|' + Path);
      FakeAnswer := '{"command":"grep --mark -F \"error\"","explanation":"Mark matching lines",' +
        '"suggestions":["grep --mark -F \"error 85\""]}';
      Driver.Mode := 4;
      Driver.Stage := 0;
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep --help', Roots, Prefs, Path, nil,
        Data, Hit, Mark, FakeAI);
      Check(Ok and Mark and (Length(Data.Hits) = 105) and not Driver.TimedOut and
        (Driver.Stage = 2),
        'AI preview then explicit execution');
      Check((FakeCalls = 1) and (Pos(Path, FakePrompt) = 0) and
        (Pos('Find error in logs', FakePrompt) > 0), 'AI receives request, not source paths');
      Driver.Mode := 10;
      Driver.Stage := 0;
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep --help', Roots, Prefs, Path, nil,
        Data, Hit, Mark, FakeAI);
      Check(Ok and Mark and (Length(Data.Hits) = 1) and (Data.Hits[0].Line = 85) and
        (Driver.Stage = 2),
        'AI suggestion executes selected command only');
      Driver.Mode := 9;
      Driver.Stage := 0;
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep --help', Roots, Prefs, Path, nil,
        Data, Hit, Mark, FakeAI, False);
      Check(not Ok and (Length(Data.Hits) = 0), 'AI cannot bypass bookmark index guard');
      Driver.Mode := 13;
      Driver.Stage := 0;
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep', Roots, Prefs, '', nil,
        Data, Hit, Mark, FakeAI, False);
      Check(not Ok and (Length(Data.Hits) = 0), 'read-only modal explains bookmark restriction');
      FakeAnswer := '{"command":"grep --bookmarks --mark -F \"error\"",' +
        '"explanation":"Search bookmarked lines","suggestions":[]}';
      Driver.Mode := 11;
      Driver.Stage := 0;
      Driver.Started := GetTickCount64;
      Roots[0] := 'F|' + Path + '.outside';
      Ok := ShowSearchCommand(nil, 'grep --help', Roots, Prefs, Path,
        TArray<Int64>.Create(2, 85), Data, Hit, Mark, FakeAI);
      Check(Ok and Mark and (Length(Data.Hits) = 2) and (Data.Hits[1].Line = 85),
        'AI bookmark searches use open file snapshot, not other sources');
      Roots[0] := 'F|' + Path;
      for I := 5 to 8 do
      begin
        Driver.Mode := I;
        Driver.Stage := 0;
        Driver.Started := GetTickCount64;
        FakeError := '';
        FakeAnswer := 'invalid reply';
        if I = 6 then FakeError := 'offline test';
        if I = 8 then FakeAnswer :=
          '{"command":"","explanation":"Which text?","suggestions":[]}';
        Ok := ShowSearchCommand(nil, 'grep --help', Roots, Prefs, Path, nil,
          Data, Hit, Mark, FakeAI);
        Check(not Ok and not Mark and not Driver.TimedOut and (Length(Data.Hits) = 0),
          'AI error, cancellation or clarification never executes');
      end;
      Driver.Mode := 1;
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep "error"', Roots, Prefs, Path, nil, Data, Hit, Mark);
      Check(Ok and not Mark and Driver.Paged and (Hit.Line = 41) and
        (Length(Data.Hits) = 105), 'paged open retains physical line');
      Driver.Mode := 2;
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep "error" --mark', Roots, Prefs, Path, nil, Data, Hit, Mark);
      Check(Ok and Mark and (Length(Data.Hits) = 105) and not Driver.TimedOut,
        'mark command returns completed result');
      Driver.Started := GetTickCount64;
      Ok := ShowSearchCommand(nil, 'grep "error" --bookmarks --mark', Roots, Prefs,
        Path, TArray<Int64>.Create(2, 85), Data, Hit, Mark);
      Check(Ok and Mark and (Length(Data.Hits) = 2) and
        (Data.Hits[1].Line = 85), 'bookmark snapshot reaches worker');
      Timer.Enabled := False;
      FfInstallFormLayoutManager;
      Application.CreateForm(TDataModule1, DataModule1);
      DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
      DataModule1.sSkinManager1.Options.PixelsPerInch := 120;
      Application.CreateForm(TfrmMain, frmMain);
      frmMain.Show;
      Deadline := GetTickCount64 + 1500;
      repeat Settle until GetTickCount64 >= Deadline;
      frmMain.btnShowTabReadFileClick(nil);
      Settle;
      Step := Default(TAssistantChainStep);
      Step.ActionId := 'open_policy_auto';
      AssistantHostExecuteAction(Step);
      frmMain.edtFileName.Text := Path;
      frmMain.btnReadClick(nil);
      Deadline := GetTickCount64 + 15000;
      repeat
        Settle;
      until (totalLines >= 105) or (GetTickCount64 >= Deadline);
      Step := Default(TAssistantChainStep);
      Step.ActionId := 'force_index_file';
      Step.Path := Path;
      AssistantHostExecuteAction(Step);
      Deadline := GetTickCount64 + 1500;
      repeat Settle until GetTickCount64 >= Deadline;
      Check(totalLines >= 105,
        Format('main file loaded: rows=%d total=%d path=%s',
          [frmMain.ListView1.Items.Count, totalLines, frmMain.edtFileName.Text]));
      SetCurrentLanguage(alEnglish);
      Driver.Mode := 15;
      Driver.Started := GetTickCount64;
      Timer.Enabled := True;
      OldLaunches := Driver.Launches;
      frmMain.BtnHelpClick(frmMain.btnHelp);
      Check(Driver.Launches = OldLaunches + 1, 'General F1 dialog displays current shared command help');
      Driver.Mode := 16;
      Driver.Started := GetTickCount64;
      OldLaunches := Driver.Launches;
      frmMain.miVersionHistoryClick(nil);
      Check(Driver.Launches = OldLaunches + 1, 'Version History dialog merges new internal releases without duplicates');
      Driver.Mode := 3;
      Driver.Started := GetTickCount64;
      Timer.Enabled := True;
      AssistantHostApplyFilter('grep --mark "never-match"', True);
      AssistantHostFindFirst('error 1', True);
      Deadline := GetTickCount64 + 1000;
      repeat Settle until GetTickCount64 >= Deadline;
      AssistantHostOpenFilterDialog;
      Settle;
      BarCount := 0;
      for J := 0 to frmMain.ComponentCount - 1 do
        if (frmMain.Components[J] is TFastFileFilterBar) or
          (frmMain.Components[J] is TFastFileFindOccBar) or
          (frmMain.Components[J] is TFastFileBookmarkBar) then
        begin
          Inc(BarCount);
          Bar := TWinControl(frmMain.Components[J]);
          for Cmd in TArray<string>.Create('grep', 'glob') do
          begin
            if Cmd = 'grep' then LaunchButton := TsButton(Bar.FindComponent('SearchGrep'))
            else LaunchButton := TsButton(Bar.FindComponent('SearchGlob'));
            Check(Assigned(LaunchButton) and LaunchButton.Enabled and LaunchButton.Visible,
              'dedicated ' + Cmd + ' button on ' + Bar.ClassName);
            Check((LaunchButton.Left >= 0) and
              (LaunchButton.Left + LaunchButton.Width <= LaunchButton.Parent.ClientWidth),
              'launcher fits bar ' + Bar.ClassName);
            Driver.Mode := 12;
            Driver.ExpectedCommand := Cmd;
            Driver.Started := GetTickCount64;
            Timer.Enabled := True;
            OldLaunches := Driver.Launches;
            LaunchButton.Click;
            Check(Driver.Launches = OldLaunches + 1, 'launcher wired to main modal: ' + Bar.ClassName);
          end;
        end;
      Check(BarCount = 3, 'all three search bars expose launch buttons: ' + IntToStr(BarCount));
      for Cmd in TArray<string>.Create('grep', 'glob') do
      begin
        Driver.ExpectedCommand := Cmd;
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.Launches;
        AssistantHostApplyFilter(Cmd, True);
        AssistantHostFindFirst(Cmd, True);
        Check(Driver.Launches = OldLaunches + 2, 'bare commands via Filter and Find callbacks');
      end;
      WorkspaceHost := TForm.CreateNew(nil);
      try
        WorkspaceHost.ClientWidth := FfPx(1200);
        WorkspaceHost.ClientHeight := FfPx(800);
        Agent := TfrmAgentWorkspace.ExecuteEmbedded(WorkspaceHost, WorkspaceHost);
        for Cmd in TArray<string>.Create('grep', 'glob') do
        begin
          Driver.ExpectedCommand := Cmd;
          Driver.Started := GetTickCount64;
          OldLaunches := Driver.Launches;
          TsMemo(Agent.FindComponent('memPrompt')).Text := Cmd;
          TsButton(Agent.FindComponent('btnSend')).Click;
          Check(Driver.Launches = OldLaunches + 1, 'AI agent UI opens bare command directly');
        end;
        Agent.Free;
        Hub := TfrmAgentHubWorkspace.ExecuteEmbedded(WorkspaceHost, WorkspaceHost);
        for Cmd in TArray<string>.Create('grep', 'glob') do
        begin
          Driver.ExpectedCommand := Cmd;
          Driver.Started := GetTickCount64;
          OldLaunches := Driver.Launches;
          TsMemo(Hub.FindComponent('memPrompt')).Text := Cmd;
          TsButton(Hub.FindComponent('btnSend')).Click;
          Check(Driver.Launches = OldLaunches + 1, 'AI diagnosis UI opens bare command without sources or provider');
        end;
      finally
        WorkspaceHost.Free;
      end;
      Driver.Mode := 3;
      Driver.Started := GetTickCount64;
      Timer.Enabled := True;
      AssistantHostApplyFilter('grep --mark "error"', True);
      Driver.LastMessage := LabelText(frmMain);
      Check(Pos('105 bookmarks added', Driver.LastMessage) > 0,
        'main adds physical bookmarks: ' + Driver.LastMessage);
      Driver.Started := GetTickCount64;
      AssistantHostApplyFilter('grep --mark "error"', True);
      Driver.LastMessage := LabelText(frmMain);
      Check(Pos('0 bookmarks added', Driver.LastMessage) > 0, 'mark is idempotent, not toggle');
      Driver.Mode := 1;
      Driver.Paged := True;
      Driver.Started := GetTickCount64;
      AssistantHostFindFirst('grep --bookmarks -F "error 85"', True);
      Settle;
      Check(Assigned(frmMain.ListView1.Selected), 'Find selects a visible row');
      Check((frmMain.ListView1.Selected.SubItems.Count > 0) and
        (frmMain.ListView1.Selected.SubItems[0] = 'error 85'),
        'Find selected content: ' + frmMain.ListView1.Selected.Caption + ' ' +
        frmMain.ListView1.Selected.SubItems.Text);
      Driver.Mode := 12;
      SendMessage(frmMain.Handle, WM_USER + 430, 0, 0);
      for Cmd in TArray<string>.Create('grep', 'glob') do
      begin
        Driver.ExpectedCommand := Cmd;
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.Launches;
        AssistantPrefillQuestion(Cmd);
        AssistantSubmitQuestion;
        Check(Driver.Launches = OldLaunches + 1, 'Assistant opens bare command without provider');
      end;
      OtherPath := Path + '.other.txt';
      try
        TFile.WriteAllText(OtherPath, 'header'#13#10'target-only'#13#10, TEncoding.UTF8);
        Driver.Mode := 1;
        Driver.Paged := True;
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.CompletedSearches;
        AssistantHostApplyFilter('grep "target-only" "' + OtherPath + '"', True);
        Deadline := GetTickCount64 + 15000;
        repeat Settle until (Driver.CompletedSearches > OldLaunches) or (GetTickCount64 >= Deadline);
        Check((Driver.CompletedSearches = OldLaunches + 1) and
          SameFileName(frmMain.edtFileName.Text, OtherPath) and not AssistantHostHasPendingChain,
          'explicit file is loaded before executing deferred grep');
        Check(Assigned(frmMain.ListView1.Selected) and
          (frmMain.ListView1.Selected.SubItems[0] = 'target-only'),
          'explicit other-file result navigates correct loaded file');

        frmMain.edtFileName.Text := Path;
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.CompletedSearches;
        AssistantHostApplyFilter('grep -F "error 85"', True);
        Deadline := GetTickCount64 + 15000;
        repeat Settle until (Driver.CompletedSearches > OldLaunches) or (GetTickCount64 >= Deadline);
        Check((Driver.CompletedSearches = OldLaunches + 1) and
          SameFileName(frmMain.edtFileName.Text, Path),
          'omitted operand uses filename field even when another file was loaded');
        Check(Assigned(frmMain.ListView1.Selected) and
          (frmMain.ListView1.Selected.SubItems[0] = 'error 85'), 'default file grep content');

        Driver.Mode := 14;
        Driver.Stage := 0;
        Driver.ExpectedCommand := 'glob "*.txt" "' + OtherPath + '"';
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.CompletedSearches;
        AssistantHostApplyFilter('glob', True);
        Deadline := GetTickCount64 + 15000;
        repeat Settle until (Driver.CompletedSearches > OldLaunches) or (GetTickCount64 >= Deadline);
        Check((Driver.CompletedSearches = OldLaunches + 1) and
          SameFileName(frmMain.edtFileName.Text, OtherPath),
          'file edited in glob modal is validated, loaded and searched');

        Driver.Mode := 3;
        Driver.Started := GetTickCount64;
        AssistantHostApplyFilter('grep "x" "' + OtherPath + '.missing"', True);
        Check((Pos('Could not read', LabelText(frmMain)) > 0) and
          not AssistantHostHasPendingChain, 'missing explicit operand fails without deferred execution');
        frmMain.edtFileName.Text := OtherPath + '.missing';
        AssistantHostApplyFilter('grep "target-only"', True);
        Check((Pos('Could not read', LabelText(frmMain)) > 0) and
          not AssistantHostHasPendingChain, 'invalid filename field never falls back to loaded sources');

        LargePath := Path + '.80g.txt';
        Stream := TFileStream.Create(LargePath, fmCreate);
        try
          Check(DeviceIoControl(Stream.Handle, $000900C4, nil, 0, nil, 0,
            BytesReturned, nil), 'VCL sparse fixture support');
          Stream.Size := Int64(80) * 1024 * 1024 * 1024;
          Stream.Position := 0;
          Bytes := TEncoding.UTF8.GetPreamble;
          Stream.WriteBuffer(Bytes[0], Length(Bytes));
          Bytes := TEncoding.UTF8.GetBytes('early-hit'#13#10);
          Stream.WriteBuffer(Bytes[0], Length(Bytes));
          Bytes := TEncoding.UTF8.GetBytes(StringOfChar('x', 120) + #13#10);
          for I := 1 to 40000 do Stream.WriteBuffer(Bytes[0], Length(Bytes));
        finally
          Stream.Free;
        end;
        Step := Default(TAssistantChainStep);
        Step.ActionId := 'open_policy_instant';
        AssistantHostExecuteAction(Step);
        Writeln('Checking 80 GiB GUI Instant Open and glob...');
        Flush(Output);
        Driver.Mode := 1;
        Driver.Started := GetTickCount64;
        Started := Driver.Started;
        OldLaunches := Driver.CompletedSearches;
        AssistantHostApplyFilter('glob "*.txt" "' + LargePath + '"', True);
        Deadline := GetTickCount64 + 15000;
        repeat Settle until (Driver.CompletedSearches > OldLaunches) or (GetTickCount64 >= Deadline);
        Check((Driver.CompletedSearches = OldLaunches + 1) and
          SameFileName(frmMain.edtFileName.Text, LargePath) and
          (GetTickCount64 - Started < 5000),
          Format('80 GiB main-window validation, Instant Open and glob: completed=%d expected=%d elapsed=%d path=%s status=%s',
            [Driver.CompletedSearches, OldLaunches + 1, GetTickCount64 - Started,
             frmMain.edtFileName.Text, Driver.LastMessage + LabelText(frmMain)]));
        Writeln('PASS: 80 GiB GUI validation, Instant Open and path-only glob');
        Flush(Output);
        Driver.Started := GetTickCount64;
        OldLaunches := Driver.CompletedSearches;
        AssistantHostApplyFilter('grep "early-hit" --limit 1', True);
        Check((Driver.CompletedSearches = OldLaunches + 1) and
          (GetTickCount64 - Driver.Started < 5000), '80 GiB loaded-file grep early limit');
        Writeln('PASS: 80 GiB GUI grep stops at requested first hit');
      finally
        Step := Default(TAssistantChainStep);
        Step.ActionId := 'open_policy_auto';
        AssistantHostExecuteAction(Step);
        FreeAndNil(frmMain);
        DeleteFile(OtherPath);
        if LargePath <> '' then DeleteFile(LargePath);
      end;
      Timer.Enabled := False;
      FreeAndNil(frmMain);
      FreeAndNil(DataModule1);
    finally
      FreeAndNil(frmMain);
      FreeAndNil(DataModule1);
      Timer.Free;
      Driver.Free;
      Lines.Free;
      Roots.Free;
      DeleteFile(Path);
    end;
    Writeln('PASS: modal AI preview, suggestions, explicit execution, errors, cancellation and index guard');
    Writeln('PASS: search dialog help, pagination, navigation and bookmark command');
    Writeln('PASS: six launcher buttons, bare commands, Assistant/agent/diagnosis UI and 14-language layouts');
    Writeln('PASS: optional filename precedence, explicit deferred loading, edited modal file and invalid file');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
