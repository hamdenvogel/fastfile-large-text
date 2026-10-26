program SearchAgentTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IOUtils, uAgentLoop, uAgentPrefs, uAgentPatch,
  uAgentTools, uFastFileAssistant, uSearchCommands, uI18n,
  uAgentHub, uAgentHubModel, uAICapabilitiesDlg;

type
  TClient = class(TAgentLoopClient)
    After: TAgentEdit;
    procedure Status(const AText: string); override;
    procedure QueueEdit(AEdit: TAgentEdit); override;
    procedure RunAfter(AEdit: TAgentEdit); override;
    destructor Destroy; override;
  end;

procedure TClient.Status(const AText: string);
begin
end;

procedure TClient.QueueEdit(AEdit: TAgentEdit);
begin
  AEdit.Free;
  raise Exception.Create('search must not queue content edits');
end;

procedure TClient.RunAfter(AEdit: TAgentEdit);
begin
  After.Free;
  After := AEdit;
end;

destructor TClient.Destroy;
begin
  After.Free;
  inherited;
end;

procedure Check(Ok: Boolean; const Name: string);
begin
  if not Ok then raise Exception.Create(Name);
end;

var
  Files, Roots, Lines: TStringList;
  Client: TClient;
  Prefs: TAgentPrefs;
  Path, Dir, SubDir, DeepPath, TextPath, Answer, Revised, Err, Command: string;
  Cancel, I: Integer;
  HubOptions: THubRunOptions;
  Report: THubReport;
  Language: TAppLanguage;
  CapsKind: TAICapsKind;
begin
  try
    Dir := TPath.Combine(TPath.GetTempPath, TPath.GetRandomFileName);
    SubDir := TPath.Combine(Dir, 'nested');
    ForceDirectories(SubDir);
    Path := TPath.Combine(Dir, 'root.log');
    DeepPath := TPath.Combine(SubDir, 'deep.log');
    TextPath := TPath.Combine(Dir, 'notes.txt');
    Files := TStringList.Create;
    Roots := TStringList.Create;
    Lines := TStringList.Create;
    Client := TClient.Create;
    try
      TFile.WriteAllText(Path, 'error'#13#10'ERROR'#13#10'normal', TEncoding.UTF8);
      Files.Add(Path);
      Roots.Add('F|' + Path);
      Cancel := 0;
      Client.CancelPtr := @Cancel;
      Prefs := DefaultAgentPrefs;
      Prefs.OpenPath := Path;
      for Language := Low(TAppLanguage) to High(TAppLanguage) do
      begin
        SetCurrentLanguage(Language);
        Check(TrText('AICaps.Item.SearchCommands') <> 'AICaps.Item.SearchCommands',
          'localized search capability');
        for CapsKind := Low(TAICapsKind) to High(TAICapsKind) do
          Check(Pos('glob "*.log"', AICapabilitiesText(CapsKind)) > 0,
            'search commands discoverable on all AI surfaces');
      end;
      SetCurrentLanguage(alEnglish);
      AgentExecute('grep', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and Assigned(Client.After) and
        (Client.After.Action.ActionId = 'apply_filter') and
        (Client.After.Action.FilterText = 'grep'), 'bare grep schedules modal without provider');
      Prefs.OpenPath := '';
      AgentExecute(' Glob ', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and Assigned(Client.After) and
        (Client.After.Action.FilterText = ' Glob '), 'bare glob works without open file');
      Prefs.OpenPath := Path;
      AgentExecute('grep -i "error"', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and (Pos('shown=2', Answer) > 0), 'direct grep without AI');
      AgentExecute('glob "*.log"', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and (Pos('shown=1', Answer) > 0), 'direct glob without AI');
      AgentExecute('grep "error" "' + Path + '"', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and Assigned(Client.After) and
        (Client.After.Action.ActionId = 'apply_filter') and
        SameFileName(Client.After.Action.Path, Path), 'user explicit file uses GUI load bridge');
      Answer := HubRunSearchCommand(hrContent, 'grep "error" "' + Path + '"', Files, @Cancel);
      Check(Pos('shown=1', Answer) > 0, 'diagnosis optional authorized operand');
      Check(Pos('error=', HubRunSearchCommand(hrContent,
        'glob "*.txt" "' + TextPath + '"', Files, @Cancel)) = 1,
        'diagnosis explicit file cannot expand authorized sources');
      Answer := SearchCommandTool('grep "error" "' + TextPath + '"', Files, @Cancel, 14000);
      Check(Pos('error=', Answer) = 1, 'model tool cannot grant itself arbitrary file access');
      Answer := HubRunSearchCommand(hrInventory, 'glob "*.log"', Files, @Cancel);
      Check(Pos('shown=1', Answer) > 0, 'diagnosis inventory glob');
      Answer := HubRunSearchCommand(hrContent, 'grep -i "error"', Files, @Cancel);
      Check(Pos('shown=2', Answer) > 0, 'diagnosis content grep');
      Check(Pos('error=', HubRunSearchCommand(hrInventory, 'grep "error"', Files, @Cancel)) = 1,
        'inventory cannot read content via grep');
      Check(Pos('error=', HubRunSearchCommand(hrActions, 'grep --mark "error"', Files, @Cancel)) = 1,
        'diagnosis cannot mutate bookmarks');
      Check(Pos('error=', HubRunSearchCommand(hrContent, 'grep --bookmarks "error"', Files, @Cancel)) = 1,
        'diagnosis does not invent bookmark state');
      Check(Pos('shown=0', HubRunSearchCommand(hrContent,
        'glob "C:\outside\*.log"', Files, @Cancel)) > 0, 'diagnosis honors selected files');
      Report := THubReport.Create;
      try
        HubOptions := DefaultHubRunOptions;
        HubOptions.Request := 'grep -i "error"';
        Check(AgentHubRun(Roots, HubOptions, @Cancel, nil, Report) and
          (Pos('shown=2', Report.ExecutiveSummary) > 0),
          'diagnosis executes complete typed command locally without provider');
        HubOptions.Request := 'grep --mark "error"';
        Check(not AgentHubRun(Roots, HubOptions, @Cancel, nil, Report) and
          (Pos('error=', Report.ExecutiveSummary) = 1), 'diagnosis rejects writes in direct commands');
        Roots.Clear;
        Check(not AgentHubRun(Roots, HubOptions, @Cancel, nil, Report) and
          (Pos('error=', Report.ExecutiveSummary) = 1), 'empty sources cannot hide invalid diagnosis command');
        HubOptions.Request := 'glob "*.log"';
        Check(AgentHubRun(Roots, HubOptions, @Cancel, nil, Report) and
          (Pos('shown=0', Report.ExecutiveSummary) > 0), 'empty diagnosis search reports zero hits locally');
        Roots.Add('F|' + Path);
      finally
        Report.Free;
      end;
      AgentExecute('grep --mark "error"', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and Assigned(Client.After) and
        (Client.After.Action.ActionId = 'apply_filter') and
        (Client.After.Action.FilterText = 'grep --mark "error"'), 'bookmark main-thread bridge');
      Command := 'grep -E "(error|failure)" --glob "**\*.log"';
      Check(NormalizeAssistantFilterNeedle('search for "wrong"', Command) = Command,
        'assistant preserves command flags, regex and quotes');
      Check(NormalizeAssistantFilterNeedle(Command, '') = Command, 'assistant direct command');
      Prefs.MaxFiles := 1;
      Files.Clear;
      Check(not AgentExpandRoots(Roots, Prefs, Files, nil), 'source cap reported');
      Check(Files.Count = 1, 'source cap respected');
      Prefs.MaxFiles := 1000;
      for I := 1 to 500 do Lines.Add(StringOfChar('x', 400) + 'error');
      Lines.SaveToFile(Path, TEncoding.UTF8);
      AgentExecute('grep "error" --limit 10000', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and (Length(Answer) <= AGENT_TOOL_CHARS) and
        (Pos('partial=True', Answer) > 0), 'bounded AI output reports partial');
      Answer := HubRunSearchCommand(hrContent, 'grep "error" --limit 10000', Files, @Cancel);
      Check((Length(Answer) <= 12000) and (Pos('partial=True', Answer) > 0),
        'diagnosis preserves bounded output and partial status');
      TFile.WriteAllText(DeepPath, 'error', TEncoding.UTF8);
      TFile.WriteAllText(TextPath, 'error', TEncoding.UTF8);
      Roots.Clear;
      Roots.Add('D|' + Dir);
      Files.Clear;
      Prefs.IncludeSubdirs := True;
      Check(AgentExpandRoots(Roots, Prefs, Files, nil, True) and
        (Files.Count = 3), 'recursive selected source expansion');
      AgentExecute('glob "**\*.log"', Files, Prefs, Client, Answer, Revised, Err);
      Check((Err = '') and (Pos('shown=2', Answer) > 0) and
        (Pos(TextPath, Answer) = 0), 'multi-file glob excludes text files');
      Files.Clear;
      Prefs.Mask := '*.none';
      Check(AgentExpandRoots(Roots, Prefs, Files, nil, True) and
        (Files.Count = 0), 'nonmatching entries still advance enumeration');
    finally
      Client.Free;
      Roots.Free;
      Files.Free;
      Lines.Free;
      DeleteFile(Path);
      DeleteFile(DeepPath);
      DeleteFile(TextPath);
      RemoveDir(SubDir);
      RemoveDir(Dir);
    end;
    Writeln('PASS: local agent commands, launch routing, read-only diagnosis and AI capability discovery');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
