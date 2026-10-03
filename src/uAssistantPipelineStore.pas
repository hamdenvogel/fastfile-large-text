unit uAssistantPipelineStore;
{ Redis-like in-process + on-disk bridge for the Assistente IA pipeline.
  Remembers last activities, structured facts, and chat turns so the model
  can continue "from where we left off". }

interface

uses
  SysUtils, Classes, uI18n;

const
  PIPELINE_MAX_TURNS = 24;
  PIPELINE_MAX_ACTIVITIES = 16;
  PIPELINE_BRIDGE_FILE = 'assistant_pipeline.bridge';

procedure PipelineSetStoragePath(const AIniOrDir: string);
procedure PipelineLoad;
procedure PipelineSave;
procedure PipelineClear;

procedure PipelineRememberActivity(const AActivityId, ASummary, AFacts: string);
procedure PipelineRememberUser(const AText: string);
procedure PipelineRememberAssistant(const AText: string);
procedure PipelineRememberChip(const AActionId: string);
procedure PipelineSetFact(const AKey, AValue: string);

function PipelineLastActivityId: string;
function PipelineLastSummary: string;
function PipelineGetFact(const AKey: string): string;
function PipelineBuildBridgeContext(AMaxTurns: Integer = 12): string;
function PipelineBuildResumeDraft(const AFallbackDraft: string): string;
function PipelineHasBridge: Boolean;
{ Runtime language switch: last summary is composed UI text (feeds the resume draft). }
procedure PipelineRetranslateSummary(OldLang: TAppLanguage);

implementation

uses
  Windows, IniFiles, uFastFilePaths;

type
  TPipelineTurn = record
    Role: string;   { user | assistant | system | chip | activity }
    Text: string;
    WhenUtc: TDateTime;
  end;

  TPipelineActivity = record
    Id: string;
    Summary: string;
    Facts: string;
    WhenUtc: TDateTime;
  end;

var
  GStorageFile: string = '';
  GLoaded: Boolean = False;
  GTurns: array of TPipelineTurn;
  GActivities: array of TPipelineActivity;
  GFacts: TStringList;
  GLastActivityId: string = '';
  GLastSummary: string = '';

procedure EnsureFacts;
begin
  if not Assigned(GFacts) then
  begin
    GFacts := TStringList.Create;
    GFacts.NameValueSeparator := '=';
    GFacts.StrictDelimiter := True;
  end;
end;

function SanitizeOneLine(const S: string): string;
begin
  Result := Trim(S);
  Result := StringReplace(Result, #13#10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, '|', '/', [rfReplaceAll]);
end;

function ClampText(const S: string; AMax: Integer): string;
begin
  Result := Trim(S);
  if (AMax > 0) and (Length(Result) > AMax) then
    Result := Copy(Result, 1, AMax - 3) + '...';
end;

procedure PipelineSetStoragePath(const AIniOrDir: string);
var
  Dir: string;
begin
  if Trim(AIniOrDir) = '' then
  begin
    GStorageFile := FastFileExeDirPath(PIPELINE_BRIDGE_FILE);
    Exit;
  end;
  if DirectoryExists(AIniOrDir) then
    Dir := IncludeTrailingPathDelimiter(AIniOrDir)
  else
    Dir := IncludeTrailingPathDelimiter(ExtractFilePath(AIniOrDir));
  if Dir = '' then
    Dir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  GStorageFile := Dir + PIPELINE_BRIDGE_FILE;
end;

procedure PushTurn(const ARole, AText: string);
var
  N, I: Integer;
  T: string;
begin
  T := ClampText(AText, 1200);
  if T = '' then Exit;
  N := Length(GTurns);
  SetLength(GTurns, N + 1);
  GTurns[N].Role := ARole;
  GTurns[N].Text := T;
  GTurns[N].WhenUtc := Now;
  while Length(GTurns) > PIPELINE_MAX_TURNS do
  begin
    for I := 0 to Length(GTurns) - 2 do
      GTurns[I] := GTurns[I + 1];
    SetLength(GTurns, Length(GTurns) - 1);
  end;
end;

procedure PushActivity(const AId, ASummary, AFacts: string);
var
  N, I: Integer;
begin
  N := Length(GActivities);
  SetLength(GActivities, N + 1);
  GActivities[N].Id := LowerCase(Trim(AId));
  GActivities[N].Summary := ClampText(ASummary, 400);
  GActivities[N].Facts := ClampText(AFacts, 800);
  GActivities[N].WhenUtc := Now;
  while Length(GActivities) > PIPELINE_MAX_ACTIVITIES do
  begin
    for I := 0 to Length(GActivities) - 2 do
      GActivities[I] := GActivities[I + 1];
    SetLength(GActivities, Length(GActivities) - 1);
  end;
end;

procedure MergeFactsFromCsv(const AFacts: string);
var
  SL: TStringList;
  I: Integer;
  K, V, Line: string;
  P: Integer;
begin
  EnsureFacts;
  if Trim(AFacts) = '' then Exit;
  SL := TStringList.Create;
  try
    SL.StrictDelimiter := True;
    SL.Delimiter := ';';
    SL.DelimitedText := AFacts;
    for I := 0 to SL.Count - 1 do
    begin
      Line := Trim(SL[I]);
      if Line = '' then Continue;
      P := Pos('=', Line);
      if P <= 1 then Continue;
      K := Trim(Copy(Line, 1, P - 1));
      V := Trim(Copy(Line, P + 1, MaxInt));
      if K = '' then Continue;
      GFacts.Values[K] := SanitizeOneLine(V);
    end;
  finally
    SL.Free;
  end;
end;

procedure PipelineRememberActivity(const AActivityId, ASummary, AFacts: string);
begin
  if not GLoaded then
    PipelineLoad;
  GLastActivityId := LowerCase(Trim(AActivityId));
  GLastSummary := ClampText(ASummary, 400);
  MergeFactsFromCsv(AFacts);
  EnsureFacts;
  if GLastActivityId <> '' then
    GFacts.Values['last_activity'] := GLastActivityId;
  if GLastSummary <> '' then
  begin
    GFacts.Values['last_summary'] := SanitizeOneLine(GLastSummary);
    GFacts.Values['summary_lang'] := AppLanguageCode(GetCurrentLanguage);
  end;
  PushActivity(GLastActivityId, GLastSummary, AFacts);
  PushTurn('activity', Format('[%s] %s', [GLastActivityId, GLastSummary]));
  PipelineSave;
end;

procedure PipelineRememberUser(const AText: string);
begin
  if not GLoaded then PipelineLoad;
  PushTurn('user', AText);
  PipelineSave;
end;

procedure PipelineRememberAssistant(const AText: string);
begin
  if not GLoaded then PipelineLoad;
  PushTurn('assistant', AText);
  PipelineSave;
end;

procedure PipelineRememberChip(const AActionId: string);
begin
  if not GLoaded then PipelineLoad;
  PushTurn('chip', 'clicked=' + Trim(AActionId));
  EnsureFacts;
  GFacts.Values['last_chip'] := SanitizeOneLine(AActionId);
  PipelineSave;
end;

procedure PipelineSetFact(const AKey, AValue: string);
begin
  if Trim(AKey) = '' then Exit;
  if not GLoaded then PipelineLoad;
  EnsureFacts;
  GFacts.Values[Trim(AKey)] := SanitizeOneLine(AValue);
  PipelineSave;
end;

function PipelineLastActivityId: string;
begin
  if not GLoaded then PipelineLoad;
  Result := GLastActivityId;
end;

{ The summary is persisted across sessions, so it may be in any language:
  translate from the language it was written in (summary_lang), then OldLang. }
procedure EnsureSummaryInCurrentLanguage(OldLang: TAppLanguage);
var
  NewSum, Code: string;
  SrcLang, Cur: TAppLanguage;
begin
  if Trim(GLastSummary) = '' then Exit;
  EnsureFacts;
  Cur := GetCurrentLanguage;
  Code := Trim(GFacts.Values['summary_lang']);
  if Code <> '' then
    SrcLang := AppLanguageFromCode(Code)
  else
    SrcLang := OldLang;
  if SrcLang = Cur then Exit;
  NewSum := RetranslateComposedText(GLastSummary, SrcLang);
  if (NewSum = GLastSummary) and (OldLang <> SrcLang) and (OldLang <> Cur) then
    NewSum := RetranslateComposedText(GLastSummary, OldLang);
  if NewSum = GLastSummary then Exit;
  GLastSummary := NewSum;
  GFacts.Values['last_summary'] := SanitizeOneLine(GLastSummary);
  GFacts.Values['summary_lang'] := AppLanguageCode(Cur);
  PipelineSave;
end;

procedure PipelineRetranslateSummary(OldLang: TAppLanguage);
begin
  if not GLoaded then PipelineLoad;
  EnsureSummaryInCurrentLanguage(OldLang);
end;

function PipelineLastSummary: string;
begin
  if not GLoaded then PipelineLoad;
  Result := GLastSummary;
end;

function PipelineGetFact(const AKey: string): string;
begin
  if not GLoaded then PipelineLoad;
  EnsureFacts;
  Result := GFacts.Values[AKey];
end;

function PipelineHasBridge: Boolean;
begin
  if not GLoaded then PipelineLoad;
  Result := (Length(GTurns) > 0) or (GLastActivityId <> '') or
            (Assigned(GFacts) and (GFacts.Count > 0));
end;

function PipelineBuildBridgeContext(AMaxTurns: Integer): string;
var
  SL: TStringList;
  I, StartI, N: Integer;
  Act: TPipelineActivity;
begin
  if not GLoaded then PipelineLoad;
  if (Length(GTurns) = 0) and (GLastActivityId = '') and
     ((not Assigned(GFacts)) or (GFacts.Count = 0)) then
  begin
    Result := '';
    Exit;
  end;
  if AMaxTurns < 4 then AMaxTurns := 4;
  if AMaxTurns > PIPELINE_MAX_TURNS then AMaxTurns := PIPELINE_MAX_TURNS;
  SL := TStringList.Create;
  try
    SL.Add('PIPELINE_BRIDGE (continue from here — like a session memory):');
    if GLastActivityId <> '' then
      SL.Add('last_activity=' + GLastActivityId);
    if GLastSummary <> '' then
      SL.Add('last_summary=' + SanitizeOneLine(GLastSummary));
    EnsureFacts;
    if GFacts.Count > 0 then
    begin
      SL.Add('facts:');
      for I := 0 to GFacts.Count - 1 do
        if Trim(GFacts.Names[I]) <> '' then
          SL.Add('  ' + GFacts.Names[I] + '=' + GFacts.ValueFromIndex[I]);
    end;
    if Length(GActivities) > 0 then
    begin
      SL.Add('recent_activities (oldest→newest):');
      StartI := 0;
      if Length(GActivities) > 8 then
        StartI := Length(GActivities) - 8;
      for I := StartI to High(GActivities) do
      begin
        Act := GActivities[I];
        SL.Add(Format('  - %s | %s | %s',
          [Act.Id, SanitizeOneLine(Act.Summary), SanitizeOneLine(Act.Facts)]));
      end;
    end;
    if Length(GTurns) > 0 then
    begin
      SL.Add('conversation_turns (oldest→newest):');
      N := Length(GTurns);
      StartI := 0;
      if N > AMaxTurns then
        StartI := N - AMaxTurns;
      for I := StartI to N - 1 do
        SL.Add(Format('  %s: %s', [GTurns[I].Role, SanitizeOneLine(GTurns[I].Text)]));
    end;
    SL.Add('INSTRUCTION: Continue the user workflow from the last_activity and conversation_turns. Do not restart from zero unless asked.');
    Result := Trim(SL.Text);
  finally
    SL.Free;
  end;
end;

function PipelineActivityCaption(const AActivityId: string): string;
var
  Id, Key, Cap: string;
begin
  Id := LowerCase(Trim(AActivityId));
  if Id = '' then
  begin
    Result := '';
    Exit;
  end;
  Key := 'Assistant.Pipeline.Activity.' + Id;
  Cap := TrText(Key);
  if (Cap = '') or SameText(Cap, Key) then
    Result := Id
  else
    Result := Cap;
end;

function PipelineBuildResumeDraft(const AFallbackDraft: string): string;
var
  Act, ActCap, Sum, Needle, Hits, Path, Part: string;
begin
  if not GLoaded then PipelineLoad;
  EnsureSummaryInCurrentLanguage(GetCurrentLanguage);
  Act := GLastActivityId;
  Sum := GLastSummary;
  EnsureFacts;
  Needle := GFacts.Values['find_text'];
  if Needle = '' then
    Needle := GFacts.Values['filter_text'];
  Hits := GFacts.Values['hits'];
  if Hits = '' then
    Hits := GFacts.Values['filter_hits'];
  Path := GFacts.Values['file'];

  if Act = '' then
  begin
    Result := AFallbackDraft;
    Exit;
  end;

  { The template adds its own sentence end. }
  Sum := Trim(Sum);
  while (Sum <> '') and ((Sum[Length(Sum)] = '.') or (Sum[Length(Sum)] = #$3002)) do
    Sum := Trim(Copy(Sum, 1, Length(Sum) - 1));
  ActCap := PipelineActivityCaption(Act);
  Result := Format(TrText('Assistant.Pipeline.ResumeDraft'), [ActCap, Sum]);
  if Path <> '' then
  begin
    Part := Format(TrText('Assistant.Pipeline.ResumeFile'), [Path]);
    if (Part <> '') and (Part[1] <> ' ') and (Result <> '') then
      Result := Result + ' ';
    Result := Result + Part;
  end;
  if Needle <> '' then
  begin
    Part := Format(TrText('Assistant.Pipeline.ResumeNeedle'), [Needle]);
    if (Part <> '') and (Part[1] <> ' ') and (Result <> '') then
      Result := Result + ' ';
    Result := Result + Part;
  end;
  if Hits <> '' then
  begin
    Part := Format(TrText('Assistant.Pipeline.ResumeHits'), [Hits]);
    if (Part <> '') and (Part[1] <> ' ') and (Result <> '') then
      Result := Result + ' ';
    Result := Result + Part;
  end;
  Part := Trim(TrText('Assistant.Pipeline.ResumeSuggest'));
  if Part <> '' then
    Result := Trim(Result) + ' ' + Part;
  if Trim(AFallbackDraft) <> '' then
    Result := Result + ' (' + Trim(AFallbackDraft) + ')';
end;

procedure PipelineClear;
begin
  SetLength(GTurns, 0);
  SetLength(GActivities, 0);
  EnsureFacts;
  GFacts.Clear;
  GLastActivityId := '';
  GLastSummary := '';
  GLoaded := True;
  PipelineSave;
end;

procedure PipelineLoad;
var
  Ini: TIniFile;
  N, I: Integer;
  Role, Text, Sec: string;
  WhenF: Double;
begin
  EnsureFacts;
  GLoaded := True;
  SetLength(GTurns, 0);
  SetLength(GActivities, 0);
  GFacts.Clear;
  GLastActivityId := '';
  GLastSummary := '';
  if GStorageFile = '' then
    PipelineSetStoragePath('');
  if (GStorageFile = '') or (not FileExists(GStorageFile)) then Exit;
  Ini := TIniFile.Create(GStorageFile);
  try
    GLastActivityId := Ini.ReadString('State', 'LastActivity', '');
    GLastSummary := Ini.ReadString('State', 'LastSummary', '');
    N := Ini.ReadInteger('Facts', 'Count', 0);
    for I := 0 to N - 1 do
    begin
      Role := Ini.ReadString('Facts', 'K' + IntToStr(I), '');
      Text := Ini.ReadString('Facts', 'V' + IntToStr(I), '');
      if Role <> '' then
        GFacts.Values[Role] := Text;
    end;
    N := Ini.ReadInteger('Turns', 'Count', 0);
    if N > PIPELINE_MAX_TURNS then N := PIPELINE_MAX_TURNS;
    SetLength(GTurns, N);
    for I := 0 to N - 1 do
    begin
      Sec := 'T' + IntToStr(I);
      GTurns[I].Role := Ini.ReadString('Turns', Sec + '_Role', 'user');
      GTurns[I].Text := Ini.ReadString('Turns', Sec + '_Text', '');
      WhenF := Ini.ReadFloat('Turns', Sec + '_When', 0);
      if WhenF > 0 then
        GTurns[I].WhenUtc := WhenF
      else
        GTurns[I].WhenUtc := Now;
    end;
    N := Ini.ReadInteger('Activities', 'Count', 0);
    if N > PIPELINE_MAX_ACTIVITIES then N := PIPELINE_MAX_ACTIVITIES;
    SetLength(GActivities, N);
    for I := 0 to N - 1 do
    begin
      Sec := 'A' + IntToStr(I);
      GActivities[I].Id := Ini.ReadString('Activities', Sec + '_Id', '');
      GActivities[I].Summary := Ini.ReadString('Activities', Sec + '_Summary', '');
      GActivities[I].Facts := Ini.ReadString('Activities', Sec + '_Facts', '');
      WhenF := Ini.ReadFloat('Activities', Sec + '_When', 0);
      if WhenF > 0 then
        GActivities[I].WhenUtc := WhenF
      else
        GActivities[I].WhenUtc := Now;
    end;
  finally
    Ini.Free;
  end;
end;

procedure PipelineSave;
var
  Ini: TIniFile;
  I, N: Integer;
  Sec: string;
begin
  if GStorageFile = '' then
    PipelineSetStoragePath('');
  if GStorageFile = '' then Exit;
  EnsureFacts;
  try
    ForceDirectories(ExtractFilePath(GStorageFile));
  except
  end;
  Ini := TIniFile.Create(GStorageFile);
  try
    Ini.WriteString('State', 'LastActivity', GLastActivityId);
    Ini.WriteString('State', 'LastSummary', GLastSummary);
    Ini.WriteInteger('Facts', 'Count', GFacts.Count);
    for I := 0 to GFacts.Count - 1 do
    begin
      Ini.WriteString('Facts', 'K' + IntToStr(I), GFacts.Names[I]);
      Ini.WriteString('Facts', 'V' + IntToStr(I), GFacts.ValueFromIndex[I]);
    end;
    N := Length(GTurns);
    Ini.WriteInteger('Turns', 'Count', N);
    for I := 0 to N - 1 do
    begin
      Sec := 'T' + IntToStr(I);
      Ini.WriteString('Turns', Sec + '_Role', GTurns[I].Role);
      Ini.WriteString('Turns', Sec + '_Text', GTurns[I].Text);
      Ini.WriteFloat('Turns', Sec + '_When', GTurns[I].WhenUtc);
    end;
    N := Length(GActivities);
    Ini.WriteInteger('Activities', 'Count', N);
    for I := 0 to N - 1 do
    begin
      Sec := 'A' + IntToStr(I);
      Ini.WriteString('Activities', Sec + '_Id', GActivities[I].Id);
      Ini.WriteString('Activities', Sec + '_Summary', GActivities[I].Summary);
      Ini.WriteString('Activities', Sec + '_Facts', GActivities[I].Facts);
      Ini.WriteFloat('Activities', Sec + '_When', GActivities[I].WhenUtc);
    end;
  finally
    Ini.Free;
  end;
end;

initialization
  EnsureFacts;

finalization
  FreeAndNil(GFacts);

end.
