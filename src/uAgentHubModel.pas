unit uAgentHubModel;

{
  Typed contracts for the folder-diagnosis hub (AgentHub-style): roles, plan,
  findings with evidence, per-agent result and final report. JSON is plain text
  for the FastFile AI gateway (no native function calling).
}

interface

uses
  Classes, SysUtils, Generics.Collections;

type
  THubRole = (
    hrInventory,
    hrStructure,
    hrContent,
    hrSql,
    hrPrivacy,
    hrActions);

  THubSeverity = (hsCritical, hsHigh, hsMedium, hsLow, hsInfo);

  THubPhase = (
    hpIdle,
    hpDiscovery,
    hpPlan,
    hpDelegate,
    hpEvaluate,
    hpAggregate,
    hpSynthesize,
    hpDone,
    hpCancelled,
    hpFailed);

  THubEvidence = record
    FilePath: string;
    Lines: string;
    Excerpt: string;
  end;

  THubFinding = class
  public
    Id: string;
    Role: THubRole;
    Title: string;
    Description: string;
    Severity: THubSeverity;
    Category: string;
    Evidence: THubEvidence;
    Recommendation: string;
  end;

  THubTask = class
  public
    Role: THubRole;
    Focus: string;
    DependsOn: string; { comma-separated role ids, optional }
  end;

  THubPlan = class
  public
    Objective: string;
    Rationale: string;
    Tasks: TObjectList<THubTask>;
    FromFallback: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

  THubAgentResult = class
  public
    Role: THubRole;
    Summary: string;
    Confidence: Double; { 0..1 }
    Findings: TObjectList<THubFinding>;
    Recommendations: TStringList;
    ToolCalls: Integer;
    StatusOk: Boolean;
    StatusNote: string;
    RawAnswer: string;
    constructor Create(ARole: THubRole);
    destructor Destroy; override;
  end;

  THubExtStat = class
  public
    Ext: string;
    Count: Integer;
    Bytes: Int64;
  end;

  THubFolderStat = class
  public
    Path: string;
    FileCount: Integer;
    Bytes: Int64;
  end;

  THubDiscovery = class
  public
    Roots: TStringList;
    Files: TStringList;
    Folders: TObjectList<THubFolderStat>;
    Exts: TObjectList<THubExtStat>;
    TotalBytes: Int64;
    Truncated: Boolean;
    MaxFiles: Integer;
    MaxDepth: Integer;
    Mask: string;
    IncludeSubdirs: Boolean;
    constructor Create;
    destructor Destroy; override;
    function BriefText(AMaxFilesListed: Integer = 80): string;
    function ExtSummary(ATop: Integer = 12): string;
  end;

  THubReport = class
  public
    Request: string;
    Objective: string;
    ExecutiveSummary: string;
    InventorySection: string;
    Findings: TObjectList<THubFinding>;
    Limitations: TStringList;
    AgentResults: TObjectList<THubAgentResult>;
    Markdown: string;
    DurationMs: Int64;
    constructor Create;
    destructor Destroy; override;
  end;

function HubRoleId(ARole: THubRole): string;
function HubRoleFromId(const AId: string; out ARole: THubRole): Boolean;
function HubRoleCaptionKey(ARole: THubRole): string;
function HubSeverityId(ASev: THubSeverity): string;
function HubSeverityFromId(const AId: string): THubSeverity;
function HubPhaseId(APhase: THubPhase): string;
function HubFindingPrefix(ARole: THubRole): string;

{ Tolerant JSON helpers for gateway replies. }
function HubExtractJsonObject(const AText: string): string;
function HubJsonString(const AObj, AKey: string): string;
function HubJsonNumber(const AObj, AKey: string; ADefault: Double): Double;
function HubJsonArraySlice(const AObj, AKey: string): string;
procedure HubParseStringArray(const AArrayJson: string; AOut: TStrings);
function HubParsePlan(const AJson: string; APlan: THubPlan): Boolean;
function HubParseAgentAnalysis(const AJson: string; AResult: THubAgentResult): Boolean;
function HubBuildReportMarkdown(AReport: THubReport): string;
{ Fix UTF-8-as-ANSI mojibake and normalize line breaks for VCL memos. }
function HubDisplayText(const S: string): string;

implementation

uses
  StrUtils;

function HubRoleId(ARole: THubRole): string;
begin
  case ARole of
    hrInventory: Result := 'inventory';
    hrStructure: Result := 'structure';
    hrContent: Result := 'content';
    hrSql: Result := 'sql';
    hrPrivacy: Result := 'privacy';
    else Result := 'actions';
  end;
end;

function HubRoleFromId(const AId: string; out ARole: THubRole): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(AId));
  Result := True;
  if (S = 'inventory') or (S = 'inv') then ARole := hrInventory
  else if (S = 'structure') or (S = 'struct') then ARole := hrStructure
  else if (S = 'content') or (S = 'contents') then ARole := hrContent
  else if (S = 'sql') or (S = 'tabular') then ARole := hrSql
  else if (S = 'privacy') or (S = 'pii') or (S = 'anon') then ARole := hrPrivacy
  else if (S = 'actions') or (S = 'action') or (S = 'fix') then ARole := hrActions
  else
    Result := False;
end;

function HubRoleCaptionKey(ARole: THubRole): string;
begin
  Result := 'Hub.Role.' + HubRoleId(ARole);
end;

function HubSeverityId(ASev: THubSeverity): string;
begin
  case ASev of
    hsCritical: Result := 'CRITICAL';
    hsHigh: Result := 'HIGH';
    hsMedium: Result := 'MEDIUM';
    hsLow: Result := 'LOW';
    else Result := 'INFO';
  end;
end;

function HubSeverityFromId(const AId: string): THubSeverity;
var
  S: string;
begin
  S := UpperCase(Trim(AId));
  if (S = 'CRITICAL') or (S = 'CRIT') then Result := hsCritical
  else if (S = 'HIGH') then Result := hsHigh
  else if (S = 'MEDIUM') or (S = 'MED') then Result := hsMedium
  else if (S = 'LOW') then Result := hsLow
  else Result := hsInfo;
end;

function HubPhaseId(APhase: THubPhase): string;
begin
  case APhase of
    hpDiscovery: Result := 'discovery';
    hpPlan: Result := 'plan';
    hpDelegate: Result := 'delegate';
    hpEvaluate: Result := 'evaluate';
    hpAggregate: Result := 'aggregate';
    hpSynthesize: Result := 'synthesize';
    hpDone: Result := 'done';
    hpCancelled: Result := 'cancelled';
    hpFailed: Result := 'failed';
    else Result := 'idle';
  end;
end;

function HubFindingPrefix(ARole: THubRole): string;
begin
  case ARole of
    hrInventory: Result := 'INV';
    hrStructure: Result := 'STR';
    hrContent: Result := 'CNT';
    hrSql: Result := 'SQL';
    hrPrivacy: Result := 'PRI';
    else Result := 'ACT';
  end;
end;

constructor THubPlan.Create;
begin
  inherited Create;
  Tasks := TObjectList<THubTask>.Create(True);
end;

destructor THubPlan.Destroy;
begin
  Tasks.Free;
  inherited;
end;

constructor THubAgentResult.Create(ARole: THubRole);
begin
  inherited Create;
  Role := ARole;
  Findings := TObjectList<THubFinding>.Create(True);
  Recommendations := TStringList.Create;
  Confidence := 0;
  StatusOk := False;
end;

destructor THubAgentResult.Destroy;
begin
  Findings.Free;
  Recommendations.Free;
  inherited;
end;

constructor THubDiscovery.Create;
begin
  inherited Create;
  Roots := TStringList.Create;
  Files := TStringList.Create;
  Folders := TObjectList<THubFolderStat>.Create(True);
  Exts := TObjectList<THubExtStat>.Create(True);
end;

destructor THubDiscovery.Destroy;
begin
  Roots.Free;
  Files.Free;
  Folders.Free;
  Exts.Free;
  inherited;
end;

function THubDiscovery.ExtSummary(ATop: Integer): string;
var
  I, N: Integer;
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    N := Exts.Count;
    if (ATop > 0) and (N > ATop) then
      N := ATop;
    for I := 0 to N - 1 do
      Parts.Add(Format('%s=%d', [Exts[I].Ext, Exts[I].Count]));
    Result := Parts.CommaText;
  finally
    Parts.Free;
  end;
end;

function THubDiscovery.BriefText(AMaxFilesListed: Integer): string;
var
  SL: TStringList;
  I, N, FShown: Integer;
  Rel: string;
begin
  SL := TStringList.Create;
  try
    SL.Add(Format('files=%d bytes=%d truncated=%s maxFiles=%d maxDepth=%d mask=%s subdirs=%s',
      [Files.Count, TotalBytes, BoolToStr(Truncated, True), MaxFiles, MaxDepth, Mask,
       BoolToStr(IncludeSubdirs, True)]));
    SL.Add('extensions: ' + ExtSummary(16));
    SL.Add('roots:');
    for I := 0 to Roots.Count - 1 do
      SL.Add('  ' + Roots[I]);
    SL.Add('folders (sample):');
    N := Folders.Count;
    if N > 40 then N := 40;
    for I := 0 to N - 1 do
      SL.Add(Format('  %s files=%d bytes=%d', [Folders[I].Path, Folders[I].FileCount, Folders[I].Bytes]));
    SL.Add('files (sample):');
    FShown := Files.Count;
    if (AMaxFilesListed > 0) and (FShown > AMaxFilesListed) then
      FShown := AMaxFilesListed;
    for I := 0 to FShown - 1 do
    begin
      Rel := Files[I];
      SL.Add('  ' + Rel);
    end;
    if Files.Count > FShown then
      SL.Add(Format('  ... %d more files', [Files.Count - FShown]));
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

constructor THubReport.Create;
begin
  inherited Create;
  Findings := TObjectList<THubFinding>.Create(True);
  Limitations := TStringList.Create;
  AgentResults := TObjectList<THubAgentResult>.Create(True);
end;

destructor THubReport.Destroy;
begin
  Findings.Free;
  Limitations.Free;
  AgentResults.Free;
  inherited;
end;

function SkipWs(const S: string; var I: Integer): Boolean;
begin
  while (I <= Length(S)) and (S[I] <= ' ') do
    Inc(I);
  Result := I <= Length(S);
end;

function HubExtractJsonObject(const AText: string): string;
var
  S: string;
  Start, I, Depth: Integer;
  InStr, Esc: Boolean;
  C: Char;
begin
  Result := '';
  S := Trim(AText);
  if S = '' then Exit;
  { Strip markdown fences. }
  if StartsText('```', S) then
  begin
    I := Pos(#10, S);
    if I > 0 then
      Delete(S, 1, I);
    for I := Length(S) - 2 downto 1 do
      if Copy(S, I, 3) = '```' then
      begin
        S := Copy(S, 1, I - 1);
        Break;
      end;
    S := Trim(S);
  end;
  Start := Pos('{', S);
  if Start = 0 then Exit;
  Depth := 0;
  InStr := False;
  Esc := False;
  for I := Start to Length(S) do
  begin
    C := S[I];
    if InStr then
    begin
      if Esc then
        Esc := False
      else if C = '\' then
        Esc := True
      else if C = '"' then
        InStr := False;
      Continue;
    end;
    if C = '"' then
      InStr := True
    else if C = '{' then
      Inc(Depth)
    else if C = '}' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        Result := Copy(S, Start, I - Start + 1);
        Exit;
      end;
    end;
  end;
end;

function UnescapeJson(const S: string): string;
var
  I: Integer;
  C: Char;
  Hex: string;
  Code: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    C := S[I];
    if (C = '\') and (I < Length(S)) then
    begin
      Inc(I);
      C := S[I];
      case C of
        '"', '\', '/': Result := Result + C;
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        't': Result := Result + #9;
        'u':
          begin
            Hex := Copy(S, I + 1, 4);
            if TryStrToInt('$' + Hex, Code) and (Code >= 0) and (Code <= $FFFF) then
            begin
              Result := Result + WideChar(Word(Code));
              Inc(I, 4);
            end
            else
              Result := Result + 'u';
          end;
      else
        Result := Result + C;
      end;
    end
    else
      Result := Result + C;
    Inc(I);
  end;
end;

{ UTF-8 bytes misread as ANSI/CP1252 (e.g. E2 80 94 -> â€"). Rebuild as UTF-8 when clear. }
function HubRepairMojibake(const S: string): string;
var
  B: TBytes;
  I: Integer;
  T: string;
  Suspicious: Boolean;
begin
  Result := S;
  Suspicious := (Pos('â€', S) > 0) or (Pos('Ã', S) > 0) or (Pos('Â', S) > 0) or
    (Pos('ã€', S) > 0) or (Pos('â€™', S) > 0) or (Pos('â€œ', S) > 0);
  if not Suspicious then Exit;
  SetLength(B, Length(S));
  for I := 1 to Length(S) do
  begin
    if Ord(S[I]) > 255 then Exit;
    B[I - 1] := Byte(Ord(S[I]));
  end;
  try
    T := TEncoding.UTF8.GetString(B);
  except
    Exit;
  end;
  if (T = '') or (Pos(#$FFFD, T) > 0) then Exit;
  if Length(T) >= Length(S) then Exit;
  Result := T;
end;

function HubDisplayText(const S: string): string;
begin
  Result := AdjustLineBreaks(HubRepairMojibake(S), tlbsCRLF);
end;

function HubJsonString(const AObj, AKey: string): string;
var
  Needle, S: string;
  P, I, Start: Integer;
  Esc: Boolean;
begin
  Result := '';
  Needle := '"' + AKey + '"';
  P := Pos(Needle, AObj);
  if P = 0 then Exit;
  I := P + Length(Needle);
  if not SkipWs(AObj, I) then Exit;
  if AObj[I] <> ':' then Exit;
  Inc(I);
  if not SkipWs(AObj, I) then Exit;
  if AObj[I] <> '"' then Exit;
  Inc(I);
  Start := I;
  Esc := False;
  while I <= Length(AObj) do
  begin
    if Esc then
      Esc := False
    else if AObj[I] = '\' then
      Esc := True
    else if AObj[I] = '"' then
    begin
      S := Copy(AObj, Start, I - Start);
      Result := HubRepairMojibake(UnescapeJson(S));
      Exit;
    end;
    Inc(I);
  end;
end;

function HubJsonNumber(const AObj, AKey: string; ADefault: Double): Double;
var
  Needle, Num: string;
  P, I: Integer;
  FS: TFormatSettings;
begin
  Result := ADefault;
  Needle := '"' + AKey + '"';
  P := Pos(Needle, AObj);
  if P = 0 then Exit;
  I := P + Length(Needle);
  if not SkipWs(AObj, I) then Exit;
  if AObj[I] <> ':' then Exit;
  Inc(I);
  if not SkipWs(AObj, I) then Exit;
  Num := '';
  while (I <= Length(AObj)) and (CharInSet(AObj[I], ['0'..'9', '.', '-', '+', 'e', 'E'])) do
  begin
    Num := Num + AObj[I];
    Inc(I);
  end;
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  if Num <> '' then
    Result := StrToFloatDef(Num, ADefault, FS);
end;

function HubJsonArraySlice(const AObj, AKey: string): string;
var
  Needle: string;
  P, I, Depth: Integer;
  InStr, Esc: Boolean;
  C: Char;
begin
  Result := '';
  Needle := '"' + AKey + '"';
  P := Pos(Needle, AObj);
  if P = 0 then Exit;
  I := P + Length(Needle);
  if not SkipWs(AObj, I) then Exit;
  if AObj[I] <> ':' then Exit;
  Inc(I);
  if not SkipWs(AObj, I) then Exit;
  if AObj[I] <> '[' then Exit;
  Depth := 0;
  InStr := False;
  Esc := False;
  P := I;
  while I <= Length(AObj) do
  begin
    C := AObj[I];
    if InStr then
    begin
      if Esc then Esc := False
      else if C = '\' then Esc := True
      else if C = '"' then InStr := False;
    end
    else if C = '"' then
      InStr := True
    else if C = '[' then
      Inc(Depth)
    else if C = ']' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        Result := Copy(AObj, P, I - P + 1);
        Exit;
      end;
    end;
    Inc(I);
  end;
end;

procedure HubParseStringArray(const AArrayJson: string; AOut: TStrings);
var
  I: Integer;
  InStr, Esc: Boolean;
  Start: Integer;
  C: Char;
  Item: string;
begin
  if AOut = nil then Exit;
  AOut.Clear;
  if AArrayJson = '' then Exit;
  I := 1;
  while I <= Length(AArrayJson) do
  begin
    if AArrayJson[I] = '"' then
    begin
      Inc(I);
      Start := I;
      InStr := True;
      Esc := False;
      while (I <= Length(AArrayJson)) and InStr do
      begin
        C := AArrayJson[I];
        if Esc then
          Esc := False
        else if C = '\' then
          Esc := True
        else if C = '"' then
        begin
          Item := HubRepairMojibake(UnescapeJson(Copy(AArrayJson, Start, I - Start)));
          if Trim(Item) <> '' then
            AOut.Add(Item);
          InStr := False;
        end;
        Inc(I);
      end;
    end
    else
      Inc(I);
  end;
end;

function ExtractObjectAt(const S: string; AFrom: Integer; out AObj: string; out ANext: Integer): Boolean;
var
  I, Depth: Integer;
  InStr, Esc: Boolean;
  C: Char;
begin
  Result := False;
  AObj := '';
  ANext := AFrom;
  I := AFrom;
  if not SkipWs(S, I) then Exit;
  if S[I] <> '{' then Exit;
  Depth := 0;
  InStr := False;
  Esc := False;
  AFrom := I;
  while I <= Length(S) do
  begin
    C := S[I];
    if InStr then
    begin
      if Esc then Esc := False
      else if C = '\' then Esc := True
      else if C = '"' then InStr := False;
    end
    else if C = '"' then
      InStr := True
    else if C = '{' then
      Inc(Depth)
    else if C = '}' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        AObj := Copy(S, AFrom, I - AFrom + 1);
        ANext := I + 1;
        Result := True;
        Exit;
      end;
    end;
    Inc(I);
  end;
end;

function HubParsePlan(const AJson: string; APlan: THubPlan): Boolean;
var
  Obj, Arr, TaskObj, Agent, Focus, Deps: string;
  I: Integer;
  Role: THubRole;
  Task: THubTask;
begin
  Result := False;
  if APlan = nil then Exit;
  APlan.Tasks.Clear;
  APlan.Objective := '';
  APlan.Rationale := '';
  APlan.FromFallback := False;
  Obj := HubExtractJsonObject(AJson);
  if Obj = '' then Exit;
  APlan.Objective := HubJsonString(Obj, 'objective');
  APlan.Rationale := HubJsonString(Obj, 'rationale');
  Arr := HubJsonArraySlice(Obj, 'tasks');
  if Arr = '' then Exit;
  I := 2; { skip '[' }
  while ExtractObjectAt(Arr, I, TaskObj, I) do
  begin
    Agent := HubJsonString(TaskObj, 'agent');
    if Agent = '' then
      Agent := HubJsonString(TaskObj, 'role');
    if not HubRoleFromId(Agent, Role) then
      Continue;
    Focus := HubJsonString(TaskObj, 'focus');
    Deps := HubJsonString(TaskObj, 'dependsOn');
    if Deps = '' then
      Deps := HubJsonString(TaskObj, 'depends_on');
    Task := THubTask.Create;
    Task.Role := Role;
    Task.Focus := Focus;
    Task.DependsOn := Deps;
    APlan.Tasks.Add(Task);
  end;
  Result := APlan.Tasks.Count > 0;
end;

function ExtractEvidenceObject(const AFindingObj: string): string;
var
  P, J: Integer;
  Ev: string;
begin
  Result := '';
  P := Pos('"evidence"', AFindingObj);
  if P = 0 then Exit;
  J := P + Length('"evidence"');
  if not SkipWs(AFindingObj, J) then Exit;
  if AFindingObj[J] <> ':' then Exit;
  Inc(J);
  if ExtractObjectAt(AFindingObj, J, Ev, J) then
    Result := Ev;
end;

function HubParseAgentAnalysis(const AJson: string; AResult: THubAgentResult): Boolean;
var
  Obj, Arr, FObj, EvObj: string;
  I: Integer;
  F: THubFinding;
  Recs: TStringList;
begin
  Result := False;
  if AResult = nil then Exit;
  AResult.Findings.Clear;
  AResult.Recommendations.Clear;
  Obj := HubExtractJsonObject(AJson);
  if Obj = '' then Exit;
  AResult.Summary := HubJsonString(Obj, 'summary');
  AResult.Confidence := HubJsonNumber(Obj, 'confidence', 0.5);
  if AResult.Confidence < 0 then AResult.Confidence := 0;
  if AResult.Confidence > 1 then AResult.Confidence := 1;
  Arr := HubJsonArraySlice(Obj, 'findings');
  I := 2;
  if Arr <> '' then
    while ExtractObjectAt(Arr, I, FObj, I) do
    begin
      F := THubFinding.Create;
      F.Role := AResult.Role;
      F.Title := HubJsonString(FObj, 'title');
      F.Description := HubJsonString(FObj, 'description');
      F.Severity := HubSeverityFromId(HubJsonString(FObj, 'severity'));
      F.Category := HubJsonString(FObj, 'category');
      F.Recommendation := HubJsonString(FObj, 'recommendation');
      EvObj := ExtractEvidenceObject(FObj);
      if EvObj <> '' then
      begin
        F.Evidence.FilePath := HubJsonString(EvObj, 'file');
        if F.Evidence.FilePath = '' then
          F.Evidence.FilePath := HubJsonString(EvObj, 'path');
        F.Evidence.Lines := HubJsonString(EvObj, 'lines');
        F.Evidence.Excerpt := HubJsonString(EvObj, 'excerpt');
      end
      else
      begin
        F.Evidence.FilePath := HubJsonString(FObj, 'file');
        F.Evidence.Lines := HubJsonString(FObj, 'lines');
        F.Evidence.Excerpt := HubJsonString(FObj, 'excerpt');
      end;
      if Trim(F.Title) = '' then
        F.Free
      else
        AResult.Findings.Add(F);
    end;
  Recs := TStringList.Create;
  try
    HubParseStringArray(HubJsonArraySlice(Obj, 'recommendations'), Recs);
    AResult.Recommendations.Assign(Recs);
  finally
    Recs.Free;
  end;
  AResult.RawAnswer := Obj;
  Result := (Trim(AResult.Summary) <> '') or (AResult.Findings.Count > 0);
end;

function HubBuildReportMarkdown(AReport: THubReport): string;
var
  SL: TStringList;
  I, J: Integer;
  F: THubFinding;
  AR: THubAgentResult;
begin
  SL := TStringList.Create;
  try
    { #$2014 = em dash; avoid UTF-8 literals in .pas without BOM (compiler ANSI). }
    SL.Add('# FastFile ' + #$2014 + ' ' + Trim(AReport.Objective));
    SL.Add('');
    SL.Add('## 1. Executive summary');
    SL.Add(HubDisplayText(AReport.ExecutiveSummary));
    SL.Add('');
    SL.Add('## 2. Inventory');
    SL.Add(HubDisplayText(AReport.InventorySection));
    SL.Add('');
    SL.Add('## 3. Findings');
    if AReport.Findings.Count = 0 then
      SL.Add('_No findings._')
    else
      for I := 0 to AReport.Findings.Count - 1 do
      begin
        F := AReport.Findings[I];
        SL.Add(Format('### %s ' + #$2014 + ' %s [%s]',
          [F.Id, HubDisplayText(F.Title), HubSeverityId(F.Severity)]));
        SL.Add(HubDisplayText(F.Description));
        if F.Evidence.FilePath <> '' then
          SL.Add(Format('- Evidence: `%s` %s',
            [F.Evidence.FilePath, HubDisplayText(F.Evidence.Lines)]));
        if F.Evidence.Excerpt <> '' then
          SL.Add('  > ' + StringReplace(HubDisplayText(F.Evidence.Excerpt), #13#10, ' ',
            [rfReplaceAll]));
        if F.Recommendation <> '' then
          SL.Add('- Recommendation: ' + HubDisplayText(F.Recommendation));
        SL.Add('');
      end;
    SL.Add('## 4. Per-agent notes');
    for I := 0 to AReport.AgentResults.Count - 1 do
    begin
      AR := AReport.AgentResults[I];
      SL.Add(Format('### %s (confidence %.0f%%, tools=%d)',
        [HubRoleId(AR.Role), AR.Confidence * 100, AR.ToolCalls]));
      SL.Add(HubDisplayText(AR.Summary));
      for J := 0 to AR.Recommendations.Count - 1 do
        SL.Add('- ' + HubDisplayText(AR.Recommendations[J]));
      SL.Add('');
    end;
    SL.Add('## 5. Limitations');
    if AReport.Limitations.Count = 0 then
      SL.Add('_None recorded._')
    else
      for I := 0 to AReport.Limitations.Count - 1 do
        SL.Add('- ' + HubDisplayText(AReport.Limitations[I]));
    SL.Add('');
    SL.Add(Format('_Duration: %d ms. Request: %s_',
      [AReport.DurationMs, StringReplace(HubDisplayText(AReport.Request), #13#10, ' ',
        [rfReplaceAll])]));
    Result := HubDisplayText(SL.Text);
  finally
    SL.Free;
  end;
end;

end.
