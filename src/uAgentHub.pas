unit uAgentHub;

{
  Hub-and-spoke orchestrator for folder/file diagnosis:
  Discovery → Plan → Delegate → Evaluate → Aggregate → Synthesize.
  Uses the FastFile AI gateway (FastFileAIInvokePrompt), not Anthropic keys.
}

interface

uses
  Classes, SysUtils, uAgentPrefs, uAgentHubModel, uAgentDiscovery;

type
  THubStatusEvent = procedure(APhase: THubPhase; const ADetail: string) of object;

  THubRunOptions = record
    Request: string;
    Prefs: TAgentPrefs;
    { Empty = Planner chooses. Otherwise comma-separated role ids. }
    ForcedRoles: string;
    MaxTurnsPerAgent: Integer;
    MaxToolCallsPerAgent: Integer;
  end;

function DefaultHubRunOptions: THubRunOptions;
function HubRunSearchCommand(ARole: THubRole; const ACommand: string;
  AFiles: TStrings; ACancel: PInteger): string;

{ Owns nothing passed in. AReport must be created by the caller; cleared then filled.
  ARoots: TStrings of paths or TAgentRoot objects (same as AgentExpandRoots). }
function AgentHubRun(ARoots: TStrings; const AOptions: THubRunOptions;
  ACancel: PInteger; AOnStatus: THubStatusEvent; AReport: THubReport): Boolean;

implementation

uses
  Windows, StrUtils, Generics.Collections, uFastFileAIClient, uAgentProtocol,
  uAgentTools, uAgentDescribe, uAgentSql, uSearchCommands;

const
  HUB_MAX_TOOL_CHARS = 12000;
  HUB_MAX_PLAN_CHARS = 8000;

type
  THubDiscoverBridge = class
  public
    OnStatus: THubStatusEvent;
    procedure Progress(AListed: Integer);
  end;

function DefaultHubRunOptions: THubRunOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Prefs := DefaultAgentPrefs;
  Result.MaxTurnsPerAgent := 6;
  Result.MaxToolCallsPerAgent := 12;
end;

function Stopped(ACancel: PInteger): Boolean;
begin
  Result := Assigned(ACancel) and (ACancel^ <> 0);
end;

function HubRunSearchCommand(ARole: THubRole; const ACommand: string;
  AFiles: TStrings; ACancel: PInteger): string;
var
  C: TSearchCommand;
begin
  try
    C := ParseSearchCommand(ACommand);
    if C.Mark or C.BookmarksOnly then
      Exit('error=diagnosis is read-only and has no bookmark state; use the main window grep modal for bookmarks');
    if (ARole = hrInventory) and (C.Kind <> sckGlob) then
      Exit('error=inventory can use glob paths only, not grep content');
    Result := SearchCommandTool(ACommand, AFiles, ACancel, HUB_MAX_TOOL_CHARS);
  except
    on E: ESearchCommand do Result := 'error=' + E.Message;
  end;
end;

procedure Status(AOnStatus: THubStatusEvent; APhase: THubPhase; const ADetail: string);
begin
  if Assigned(AOnStatus) then
    AOnStatus(APhase, ADetail);
end;

function RoleAllowed(ARole: THubRole; ATool: TAgentToolKind): Boolean;
begin
  case ARole of
    hrInventory:
      Result := ATool in [atkList, atkDescribe, atkCommand];
    hrStructure:
      Result := ATool in [atkList, atkDescribe, atkRead, atkCommand];
    hrContent:
      Result := ATool in [atkList, atkDescribe, atkRead, atkSearch, atkCount, atkCommand];
    hrSql:
      Result := ATool in [atkList, atkDescribe, atkRead, atkSql, atkCommand];
    hrPrivacy:
      Result := ATool in [atkList, atkDescribe, atkRead, atkSearch, atkCount, atkCommand];
    hrActions:
      Result := ATool in [atkList, atkDescribe, atkRead, atkSearch, atkCount, atkCommand];
  else
    Result := False;
  end;
end;

function RoleToolsHint(ARole: THubRole): string;
begin
  case ARole of
    hrInventory: Result := 'list_files, describe_files';
    hrStructure: Result := 'list_files, describe_files, read_lines';
    hrContent: Result := 'list_files, describe_files, read_lines, search, count';
    hrSql: Result := 'list_files, describe_files, read_lines, sql';
    hrPrivacy: Result := 'list_files, describe_files, read_lines, search, count';
    else Result := 'list_files, describe_files, read_lines, search, count';
  end;
  Result := Result + ', search_command';
end;

function RoleFocusHint(ARole: THubRole): string;
begin
  case ARole of
    hrInventory:
      Result := 'Map folders, extensions, sizes, naming patterns; do not deep-read file bodies.';
    hrStructure:
      Result := 'Encoding, EOL, delimiter, columns, binary vs text; sample with describe_files/read_lines.';
    hrContent:
      Result := 'Content patterns, errors, empty fields, purpose of files; use search/count with evidence.';
    hrSql:
      Result := 'Delimited/tabular files: columns, SQL checks, inconsistencies; SELECT only.';
    hrPrivacy:
      Result := 'PII candidates (emails, phones, CPF/CNPJ-like, names, cards); evidence required.';
    else
      Result := 'Suggest safe next actions for the FastFile AI agent (edits/anonymize); do not invent writes.';
  end;
end;

procedure AddTaskUnique(APlan: THubPlan; ARole: THubRole; const AFocus: string);
var
  I: Integer;
  T: THubTask;
begin
  for I := 0 to APlan.Tasks.Count - 1 do
    if APlan.Tasks[I].Role = ARole then
      Exit;
  T := THubTask.Create;
  T.Role := ARole;
  T.Focus := AFocus;
  T.DependsOn := '';
  if ARole <> hrInventory then
    T.DependsOn := 'inventory';
  APlan.Tasks.Add(T);
end;

procedure BuildFallbackPlan(const ARequest: string; const AForced: string; APlan: THubPlan);
var
  R: string;
  Role: THubRole;
  Parts: TStringList;
  I: Integer;
begin
  APlan.Tasks.Clear;
  APlan.FromFallback := True;
  APlan.Objective := Trim(ARequest);
  if APlan.Objective = '' then
    APlan.Objective := 'Diagnose selected folders and files';
  APlan.Rationale := 'rule-based plan';

  if Trim(AForced) <> '' then
  begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := ',';
      Parts.DelimitedText := LowerCase(AForced);
      AddTaskUnique(APlan, hrInventory, RoleFocusHint(hrInventory));
      for I := 0 to Parts.Count - 1 do
        if HubRoleFromId(Trim(Parts[I]), Role) and (Role <> hrInventory) then
          AddTaskUnique(APlan, Role, RoleFocusHint(Role));
    finally
      Parts.Free;
    end;
    if APlan.Tasks.Count > 0 then Exit;
  end;

  R := LowerCase(ARequest);
  AddTaskUnique(APlan, hrInventory, RoleFocusHint(hrInventory));
  AddTaskUnique(APlan, hrStructure, RoleFocusHint(hrStructure));
  if (Pos('sql', R) > 0) or (Pos('csv', R) > 0) or (Pos('coluna', R) > 0) or
     (Pos('column', R) > 0) or (Pos('delimit', R) > 0) or (Pos('tabular', R) > 0) then
    AddTaskUnique(APlan, hrSql, RoleFocusHint(hrSql))
  else
    AddTaskUnique(APlan, hrContent, RoleFocusHint(hrContent));
  if (Pos('priv', R) > 0) or (Pos('pii', R) > 0) or (Pos('anonim', R) > 0) or
     (Pos('anonym', R) > 0) or (Pos('lgpd', R) > 0) or (Pos('gdpr', R) > 0) or
     (Pos('email', R) > 0) or (Pos('cpf', R) > 0) then
    AddTaskUnique(APlan, hrPrivacy, RoleFocusHint(hrPrivacy));
  if (Pos('edit', R) > 0) or (Pos('corrig', R) > 0) or (Pos('fix', R) > 0) or
     (Pos('alter', R) > 0) or (Pos('substitu', R) > 0) then
    AddTaskUnique(APlan, hrActions, RoleFocusHint(hrActions));
end;

function InvokePlain(const APrompt: string; ACancel: PInteger; out ARaw, AErr: string): Boolean;
var
  WideAns: WideString;
  Attempt: Integer;
  Prompt: string;
begin
  Result := False;
  ARaw := '';
  AErr := '';
  Prompt := APrompt;
  for Attempt := 1 to 3 do
  begin
    if Stopped(ACancel) then
    begin
      AErr := 'stopped';
      Exit;
    end;
    Result := FastFileAIInvokePrompt(WideString(Prompt), WideAns, AErr, nil);
    ARaw := HubDisplayText(Trim(string(WideAns)));
    if Result and (ARaw <> '') then
      Exit;
    Result := False;
    if Stopped(ACancel) then
    begin
      AErr := 'stopped';
      Exit;
    end;
    Prompt := APrompt + #13#10#13#10 +
      'Your previous reply was empty or invalid. Return one JSON object as plain text only.';
  end;
end;

function PlanWithLlm(const ARequest: string; ADiscovery: THubDiscovery;
  ACancel: PInteger; APlan: THubPlan): Boolean;
var
  Prompt, Raw, Err: string;
begin
  Result := False;
  Prompt :=
    'You are the Planner of FastFile folder diagnosis hub.'#13#10 +
    'Return ONLY one JSON object:'#13#10 +
    '{"objective":"...","rationale":"...","tasks":[{"agent":"inventory|structure|content|sql|privacy|actions",' +
    '"focus":"...","dependsOn":"inventory"}]}'#13#10 +
    'Rules: always include inventory first; pick 2..5 agents; specialists never talk to each other; ' +
    'focus on large files / folders / data quality, not source-code architecture. ' +
    'Read-only search_command is available: glob matches selected paths (inventory), grep searches contents ' +
    '(content/privacy). The UI has bare grep/glob launchers and AI suggestions; never plan bookmark changes ' +
    'or app actions in diagnosis. Preserve user patterns and selected-source scope.'#13#10#13#10 +
    'User request:'#13#10 + ARequest + #13#10#13#10 +
    'Discovery brief:'#13#10 + Copy(ADiscovery.BriefText(60), 1, HUB_MAX_PLAN_CHARS);
  if not InvokePlain(Prompt, ACancel, Raw, Err) then
    Exit;
  Result := HubParsePlan(Raw, APlan);
  if Result then
    APlan.FromFallback := False;
end;

function Clip(const S: string; AMax: Integer): string;
begin
  if Length(S) > AMax then
    Result := Copy(S, 1, AMax) + #13#10 + '...[truncated]'
  else
    Result := S;
end;

function RunTool(ARole: THubRole; const P: TAgentTurn; AFiles: TStrings;
  const APrefs: TAgentPrefs; ACancel: PInteger; var AToolCalls: Integer): string;
var
  Count, Limit: Integer;
  SqlRes: TAgentSqlResult;
  Sample: TStringList;
  I, N: Integer;
begin
  if not RoleAllowed(ARole, P.Tool) then
    Exit('error=tool not allowed for this specialist. Allowed: ' + RoleToolsHint(ARole));
  Inc(AToolCalls);
  case P.Tool of
    atkCommand:
      Result := HubRunSearchCommand(ARole, P.Command, AFiles, ACancel);
    atkList:
      Result := AgentToolList(AFiles, HUB_MAX_TOOL_CHARS);
    atkDescribe:
      begin
        Sample := TStringList.Create;
        try
          N := AFiles.Count;
          if N > 12 then N := 12;
          if P.Path <> '' then
          begin
            if AgentFileAllowed(P.Path, AFiles) then
              Sample.Add(P.Path)
            else
              Exit('error=path outside selection');
          end
          else
            for I := 0 to N - 1 do
              Sample.Add(AFiles[I]);
          Result := Clip(AgentToolDescribe(Sample, ACancel, HUB_MAX_TOOL_CHARS, 8), HUB_MAX_TOOL_CHARS);
        finally
          Sample.Free;
        end;
      end;
    atkRead:
      if not AgentFileAllowed(P.Path, AFiles) then
        Result := 'error=path outside selection'
      else
      begin
        Count := P.Count;
        if Count <= 0 then Count := 40;
        if Count > APrefs.MaxReadLines then Count := APrefs.MaxReadLines;
        Result := Clip(AgentToolReadLines(P.Path, P.StartLine, Count, ACancel,
          AgentIndexPathFor(APrefs, P.Path)), HUB_MAX_TOOL_CHARS);
      end;
    atkSearch:
      if not AgentFileAllowed(P.Path, AFiles) then
        Result := 'error=path outside selection'
      else
      begin
        Limit := P.Limit;
        if Limit <= 0 then Limit := 40;
        if Limit > APrefs.MaxSearchHits then Limit := APrefs.MaxSearchHits;
        Result := Clip(AgentToolSearch(P.Path, P.Needle, Limit, ACancel,
          P.CaseSensitive = 1, P.WholeWord = 1), HUB_MAX_TOOL_CHARS);
      end;
    atkCount:
      Result := Clip(AgentToolCount(AFiles, P.Needle, 8, ACancel,
        P.CaseSensitive = 1, P.WholeWord = 1), HUB_MAX_TOOL_CHARS);
    atkSql:
      if (P.Path = '') or not AgentFileAllowed(P.Path, AFiles) then
        Result := 'error=sql needs a path inside the selection'
      else
      begin
        SqlRes := AgentToolSql(P.Path, P.Sql, P.AnonDelimiter, P.SqlHeader, 80, ACancel);
        Result := Clip(SqlRes.Text, HUB_MAX_TOOL_CHARS);
      end;
  else
    Result := 'error=unknown or blocked tool';
  end;
end;

function BuildSpecialistOpening(ARole: THubRole; const ARequest, AFocus: string;
  ADiscovery: THubDiscovery; const ADepContext: string): string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('You are the FastFile hub specialist "' + HubRoleId(ARole) + '".');
    SL.Add(RoleFocusHint(ARole));
    if AFocus <> '' then
      SL.Add('Task focus: ' + AFocus);
    SL.Add('User request: ' + ARequest);
    SL.Add('Read-only analysis of large files/folders. Never invent paths or line numbers.');
    SL.Add('Tools (one JSON object per reply): ' + RoleToolsHint(ARole));
    SL.Add('Examples: {"tool":"list_files"}  {"tool":"describe_files"}  ' +
      '{"tool":"read_lines","path":"...","start":1,"count":40}  ' +
      '{"tool":"search","path":"...","needle":"...","limit":40}  ' +
      '{"tool":"count","needle":"..."}  {"tool":"sql","path":"...","sql":"SELECT ..."}');
    SL.Add('When finished, return ONLY:');
    SL.Add('{"summary":"...","confidence":0.0-1.0,"findings":[{"title":"...","description":"...",' +
      '"severity":"CRITICAL|HIGH|MEDIUM|LOW|INFO","category":"...","evidence":{"file":"...","lines":"12-20",' +
      '"excerpt":"..."},"recommendation":"..."}],"recommendations":["..."]}');
    SL.Add('Every important finding MUST include evidence.file (and lines when possible).');
    SL.Add('Discovery brief:');
    SL.Add(Copy(ADiscovery.BriefText(50), 1, 6000));
    if Trim(ADepContext) <> '' then
    begin
      SL.Add('Context from dependency agents:');
      SL.Add(Copy(ADepContext, 1, 4000));
    end;
    SL.Add('search_command is available read-only, e.g. {"tool":"search_command","command":"glob \"*.csv\""} ' +
      'or {"tool":"search_command","command":"grep -i -F \"error\" --glob \"*.log\" --limit 200"}. ' +
      'Inventory may use glob only. glob matches paths (* ? **), grep matches content, literal and case-sensitive ' +
      'by default. -i ignores case, -E PCRE regex, -v inverse, -w whole words, -F literal. ' +
      '--limit 1..10000 is a global hit cap, default 200. partial=True is not an exact total. ' +
      'Use only discovered files; ** does not enable recursion. No shell or external paths. ' +
      'An optional single file operand after the pattern narrows the discovered list only; ' +
      'it cannot open new files or grant access outside that list. No file operand is required. ' +
      'The tool streams GB files in blocks, stops immediately at its hit cap and reports partial results. ' +
      'Lines over 16,777,216 decoded characters fail explicitly, never silently truncate. ' +
      'Translate multilingual intent but preserve user patterns. Never use --mark or --bookmarks in diagnosis. ' +
      'Recommend the main window for bookmark operations. Bare grep/glob opens the interactive modal when ' +
      'typed by the user; the read-only tool returns help instead. Find, Filter and Bookmarks have grep/glob ' +
      'buttons; their modal offers AI suggestions that require explicit Run command. ' +
      'Named groups (?<name>...) or (?P<name>...) with -E become result-table columns.');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function RunSpecialist(ARole: THubRole; const ARequest, AFocus: string;
  ADiscovery: THubDiscovery; AFiles: TStrings; const APrefs: TAgentPrefs;
  const ADepContext: string; ACancel: PInteger; AMaxTurns, AMaxTools: Integer;
  AOnStatus: THubStatusEvent; AResult: THubAgentResult): Boolean;
var
  Opening, Prompt, Transcript, Raw, Err, ToolOut: string;
  Turn: Integer;
  Parsed: TAgentTurn;
  Finished: Boolean;
begin
  Result := False;
  AResult.Role := ARole;
  AResult.ToolCalls := 0;
  AResult.StatusOk := False;
  Opening := BuildSpecialistOpening(ARole, ARequest, AFocus, ADiscovery, ADepContext);
  Transcript := '';
  Finished := False;
  for Turn := 1 to AMaxTurns do
  begin
    if Stopped(ACancel) then
    begin
      AResult.StatusNote := 'stopped';
      Exit;
    end;
    Status(AOnStatus, hpDelegate, HubRoleId(ARole) + ' turn ' + IntToStr(Turn));
    if Transcript = '' then
      Prompt := Opening
    else
      Prompt := Opening + #13#10#13#10 + 'Transcript so far:'#13#10 + Copy(Transcript, 1, 10000) +
        #13#10#13#10 + 'Continue: one tool JSON, or the final AgentAnalysis JSON.';
    if not InvokePlain(Prompt, ACancel, Raw, Err) then
    begin
      AResult.StatusNote := Err;
      Exit;
    end;
    if HubParseAgentAnalysis(Raw, AResult) and (Pos('"tool"', LowerCase(HubExtractJsonObject(Raw))) = 0) then
    begin
      Finished := True;
      Break;
    end;
    Parsed := ParseAgentTurn(Raw);
    if Parsed.Tool = atkNone then
    begin
      if HubParseAgentAnalysis(Raw, AResult) then
      begin
        Finished := True;
        Break;
      end;
      Transcript := Transcript + #13#10 + 'MODEL ' + Clip(Raw, 500) + #13#10 +
        'HOST error=expected a tool or AgentAnalysis JSON';
      Continue;
    end;
    if AResult.ToolCalls >= AMaxTools then
    begin
      Transcript := Transcript + #13#10 + 'HOST error=tool budget exhausted; return AgentAnalysis JSON now';
      Continue;
    end;
    ToolOut := RunTool(ARole, Parsed, AFiles, APrefs, ACancel, AResult.ToolCalls);
    Transcript := Transcript + #13#10 + 'TOOL ' + Parsed.RawTool + ' => ' + ToolOut;
  end;
  if not Finished then
  begin
    { Last chance: ask for analysis only. }
    Prompt := Opening + #13#10#13#10 + 'Transcript:'#13#10 + Copy(Transcript, 1, 10000) + #13#10#13#10 +
      'Stop using tools. Return the AgentAnalysis JSON object now.';
    if InvokePlain(Prompt, ACancel, Raw, Err) then
      Finished := HubParseAgentAnalysis(Raw, AResult);
  end;
  AResult.StatusOk := Finished and ((AResult.Findings.Count > 0) or (Trim(AResult.Summary) <> ''));
  if not AResult.StatusOk and (AResult.StatusNote = '') then
    AResult.StatusNote := 'insufficient analysis';
  Result := AResult.StatusOk;
end;

function EvaluateResult(AResult: THubAgentResult): Boolean;
var
  WithEv, I: Integer;
begin
  if not AResult.StatusOk then
    Exit(False);
  if AResult.Confidence < 0.35 then
    Exit(False);
  if AResult.Findings.Count = 0 then
    Exit(Trim(AResult.Summary) <> '');
  WithEv := 0;
  for I := 0 to AResult.Findings.Count - 1 do
    if Trim(AResult.Findings[I].Evidence.FilePath) <> '' then
      Inc(WithEv);
  Result := (WithEv * 2 >= AResult.Findings.Count) or (AResult.Findings.Count <= 1);
end;

function DepContextFor(APlan: THubPlan; ATask: THubTask;
  ADone: TObjectDictionary<THubRole, THubAgentResult>): string;
var
  Parts: TStringList;
  I: Integer;
  Role: THubRole;
  AR: THubAgentResult;
  S: string;
begin
  Result := '';
  if Trim(ATask.DependsOn) = '' then Exit;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ',';
    Parts.DelimitedText := LowerCase(ATask.DependsOn);
    S := '';
    for I := 0 to Parts.Count - 1 do
      if HubRoleFromId(Trim(Parts[I]), Role) and ADone.TryGetValue(Role, AR) then
        S := S + HubRoleId(Role) + ': ' + AR.Summary + #13#10;
    Result := S;
  finally
    Parts.Free;
  end;
end;

function RoleReady(ATask: THubTask; ADone: TObjectDictionary<THubRole, THubAgentResult>): Boolean;
var
  Parts: TStringList;
  I: Integer;
  Role: THubRole;
begin
  Result := True;
  if Trim(ATask.DependsOn) = '' then Exit;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ',';
    Parts.DelimitedText := LowerCase(ATask.DependsOn);
    for I := 0 to Parts.Count - 1 do
      if HubRoleFromId(Trim(Parts[I]), Role) and not ADone.ContainsKey(Role) then
        Exit(False);
  finally
    Parts.Free;
  end;
end;

procedure Aggregate(AReport: THubReport; AResults: TObjectList<THubAgentResult>);
var
  I, J, Seq: Integer;
  AR: THubAgentResult;
  F, CopyF: THubFinding;
  Pref: string;
begin
  AReport.Findings.Clear;
  for I := 0 to AResults.Count - 1 do
  begin
    AR := AResults[I];
    Pref := HubFindingPrefix(AR.Role);
    Seq := 0;
    for J := 0 to AR.Findings.Count - 1 do
    begin
      F := AR.Findings[J];
      Inc(Seq);
      CopyF := THubFinding.Create;
      CopyF.Id := Format('%s-%.3d', [Pref, Seq]);
      CopyF.Role := F.Role;
      CopyF.Title := F.Title;
      CopyF.Description := F.Description;
      CopyF.Severity := F.Severity;
      CopyF.Category := F.Category;
      CopyF.Evidence := F.Evidence;
      CopyF.Recommendation := F.Recommendation;
      AReport.Findings.Add(CopyF);
    end;
  end;
end;

function Synthesize(const ARequest: string; ADiscovery: THubDiscovery;
  AReport: THubReport; ACancel: PInteger): string;
var
  Prompt, Raw, Err, Draft: string;
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('files=' + IntToStr(ADiscovery.Files.Count));
    SL.Add('bytes=' + IntToStr(ADiscovery.TotalBytes));
    SL.Add('ext=' + ADiscovery.ExtSummary(10));
    for I := 0 to AReport.Findings.Count - 1 do
      if I < 40 then
        SL.Add(AReport.Findings[I].Id + ' ' + HubSeverityId(AReport.Findings[I].Severity) +
          ' ' + AReport.Findings[I].Title);
    Draft := SL.Text;
  finally
    SL.Free;
  end;
  Prompt :=
    'You are the Report Synthesizer for FastFile folder diagnosis.'#13#10 +
    'Write a concise executive summary (5-10 sentences) in the same language as the user request.'#13#10 +
    'Return ONLY JSON: {"executiveSummary":"...","keyRecommendations":["..."]}'#13#10#13#10 +
    'User request: ' + ARequest + #13#10#13#10 +
    'Facts:'#13#10 + Draft;
  if InvokePlain(Prompt, ACancel, Raw, Err) then
  begin
    Result := HubJsonString(HubExtractJsonObject(Raw), 'executiveSummary');
    if Result = '' then
      Result := HubJsonString(HubExtractJsonObject(Raw), 'summary');
  end
  else
    Result := '';
  if Trim(Result) = '' then
    Result := Format('Diagnosis of %d file(s) (%d bytes). %d finding(s).',
      [ADiscovery.Files.Count, ADiscovery.TotalBytes, AReport.Findings.Count]);
end;

procedure THubDiscoverBridge.Progress(AListed: Integer);
begin
  Status(OnStatus, hpDiscovery, IntToStr(AListed));
end;

function AgentHubRun(ARoots: TStrings; const AOptions: THubRunOptions;
  ACancel: PInteger; AOnStatus: THubStatusEvent; AReport: THubReport): Boolean;
var
  Discovery: THubDiscovery;
  Plan: THubPlan;
  Prefs: TAgentPrefs;
  Tick: Cardinal;
  I, MaxTurns, MaxTools: Integer;
  AR: THubAgentResult;
  DoneMap: TObjectDictionary<THubRole, THubAgentResult>;
  Results: TObjectList<THubAgentResult>;
  Pending: TList<THubTask>;
  Task: THubTask;
  Ok: Boolean;
  Waves: Integer;
  Bridge: THubDiscoverBridge;
begin
  Result := False;
  if (ARoots = nil) or (AReport = nil) then Exit;
  Tick := GetTickCount;
  AReport.Request := AOptions.Request;
  AReport.Findings.Clear;
  AReport.Limitations.Clear;
  AReport.AgentResults.Clear;
  AReport.Markdown := '';
  AReport.ExecutiveSummary := '';
  AReport.InventorySection := '';
  Prefs := AOptions.Prefs;
  MaxTurns := AOptions.MaxTurnsPerAgent;
  if MaxTurns < 2 then MaxTurns := 2;
  if MaxTurns > 10 then MaxTurns := 10;
  MaxTools := AOptions.MaxToolCallsPerAgent;
  if MaxTools < 3 then MaxTools := 3;
  if MaxTools > 25 then MaxTools := 25;

  Discovery := THubDiscovery.Create;
  Plan := THubPlan.Create;
  Results := TObjectList<THubAgentResult>.Create(True);
  DoneMap := TObjectDictionary<THubRole, THubAgentResult>.Create([]);
  Pending := TList<THubTask>.Create;
  Bridge := THubDiscoverBridge.Create;
  try
    Bridge.OnStatus := AOnStatus;
    Status(AOnStatus, hpDiscovery, 'scanning');
    if not AgentHubDiscover(ARoots, Prefs, Discovery, ACancel, Bridge.Progress) then
    begin
      if Stopped(ACancel) then
        Status(AOnStatus, hpCancelled, 'cancelled')
      else
        Status(AOnStatus, hpFailed, 'discovery');
      Exit;
    end;
    if (Discovery.Files.Count = 0) and not IsSearchCommand(AOptions.Request) then
    begin
      AReport.Limitations.Add('No files matched the current mask/depth limits.');
      AReport.ExecutiveSummary := 'No files found to diagnose.';
      AReport.InventorySection := Discovery.BriefText(20);
      AReport.Objective := AOptions.Request;
      AReport.Markdown := HubBuildReportMarkdown(AReport);
      Status(AOnStatus, hpDone, 'empty');
      Result := True;
      Exit;
    end;
    AReport.InventorySection := Discovery.BriefText(100);
    if Discovery.Truncated then
      AReport.Limitations.Add(Format('File list truncated at MaxFiles=%d.', [Discovery.MaxFiles]));

    if IsSearchCommand(AOptions.Request) then
    begin
      AReport.Objective := AOptions.Request;
      AReport.ExecutiveSummary := HubRunSearchCommand(hrContent, AOptions.Request,
        Discovery.Files, ACancel);
      AReport.DurationMs := GetTickCount - Tick;
      AReport.Markdown := HubBuildReportMarkdown(AReport);
      Result := not Stopped(ACancel) and
        not StartsText('error=', AReport.ExecutiveSummary);
      if Stopped(ACancel) then Status(AOnStatus, hpCancelled, 'cancelled')
      else if Result then Status(AOnStatus, hpDone, 'search_command')
      else Status(AOnStatus, hpFailed, 'search_command');
      Exit;
    end;

    Status(AOnStatus, hpPlan, 'planning');
    if Stopped(ACancel) then
    begin
      Status(AOnStatus, hpCancelled, 'cancelled');
      Exit;
    end;
    if Trim(AOptions.ForcedRoles) <> '' then
      BuildFallbackPlan(AOptions.Request, AOptions.ForcedRoles, Plan)
    else if not PlanWithLlm(AOptions.Request, Discovery, ACancel, Plan) then
      BuildFallbackPlan(AOptions.Request, '', Plan);
    AReport.Objective := Plan.Objective;
    if Plan.FromFallback then
      AReport.Limitations.Add('Planner used rule-based fallback.');

    for I := 0 to Plan.Tasks.Count - 1 do
      Pending.Add(Plan.Tasks[I]);

    Waves := 0;
    while Pending.Count > 0 do
    begin
      Inc(Waves);
      if Waves > 12 then Break;
      if Stopped(ACancel) then
      begin
        Status(AOnStatus, hpCancelled, 'cancelled');
        Exit;
      end;
      Ok := False;
      for I := Pending.Count - 1 downto 0 do
      begin
        Task := Pending[I];
        if not RoleReady(Task, DoneMap) then
          Continue;
        if DoneMap.ContainsKey(Task.Role) then
        begin
          Pending.Delete(I);
          Continue;
        end;
        Status(AOnStatus, hpDelegate, HubRoleId(Task.Role));
        AR := THubAgentResult.Create(Task.Role);
        if not RunSpecialist(Task.Role, AOptions.Request, Task.Focus, Discovery,
          Discovery.Files, Prefs, DepContextFor(Plan, Task, DoneMap), ACancel,
          MaxTurns, MaxTools, AOnStatus, AR) then
        begin
          { one re-delegate with feedback }
          Status(AOnStatus, hpEvaluate, 're-delegate ' + HubRoleId(Task.Role));
          AR.Free;
          AR := THubAgentResult.Create(Task.Role);
          RunSpecialist(Task.Role, AOptions.Request,
            Task.Focus + ' Previous attempt lacked evidence or confidence. Be concrete.',
            Discovery, Discovery.Files, Prefs, DepContextFor(Plan, Task, DoneMap),
            ACancel, MaxTurns, MaxTools, AOnStatus, AR);
        end;
        Status(AOnStatus, hpEvaluate, HubRoleId(Task.Role));
        if not EvaluateResult(AR) then
        begin
          AR.StatusOk := False;
          if AR.StatusNote = '' then
            AR.StatusNote := 'evaluation failed';
          AReport.Limitations.Add(HubRoleId(Task.Role) + ': ' + AR.StatusNote);
        end;
        Results.Add(AR);
        DoneMap.AddOrSetValue(Task.Role, AR);
        Pending.Delete(I);
        Ok := True;
      end;
      if not Ok then
      begin
        { break dependency deadlock }
        if Pending.Count > 0 then
        begin
          Task := Pending[0];
          Task.DependsOn := '';
        end
        else
          Break;
      end;
    end;

    Status(AOnStatus, hpAggregate, IntToStr(Results.Count));
    Aggregate(AReport, Results);
    for I := 0 to Results.Count - 1 do
      AReport.AgentResults.Add(Results[I]);
    Results.OwnsObjects := False;
    Results.Clear;

    Status(AOnStatus, hpSynthesize, 'summary');
    AReport.ExecutiveSummary := Synthesize(AOptions.Request, Discovery, AReport, ACancel);
    AReport.DurationMs := GetTickCount - Tick;
    AReport.Markdown := HubBuildReportMarkdown(AReport);
    Status(AOnStatus, hpDone, IntToStr(AReport.Findings.Count));
    Result := True;
  finally
    Bridge.Free;
    Pending.Free;
    DoneMap.Free;
    Results.Free;
    Plan.Free;
    Discovery.Free;
  end;
end;

end.
