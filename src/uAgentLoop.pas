unit uAgentLoop;

{
  Stateless gateway turns: the model asks for a tool, the host runs it, the
  next prompt carries the transcript. Nothing is written here.
}

interface

uses
  Classes, uAgentPrefs, uAgentPatch;

type
  TAgentLoopClient = class
  public
    CancelPtr: PInteger;
    function Cancelled: Boolean;
    procedure Status(const AText: string); virtual; abstract;
    { Takes ownership of AEdit. }
    procedure QueueEdit(AEdit: TAgentEdit); virtual; abstract;
    { View-only core action (AEdit.Kind = aekAction), run after the answer. Takes ownership. }
    procedure RunAfter(AEdit: TAgentEdit); virtual; abstract;
  end;

procedure AgentExecute(const AUserPrompt: string; AFiles: TStrings;
  const APrefs: TAgentPrefs; AClient: TAgentLoopClient;
  out AAnswer, ARevised, AErr: string);
{ Appends one line to Assistant.log (next to the exe). Thread-safe enough: open, append, close. }
procedure AgentLog(const AText: string);

implementation

uses
  SysUtils, StrUtils, uAgentProtocol, uAgentTools, uFastFileAIClient, uFastFilePaths, UnConsts,
  uAnonymize, uI18n, uAgentActions, uFastFileAssistantHost, uAgentMatchIntent, uAgentSql;

const
  AGENT_MAX_PROPOSAL_LINES = 5000;
  { SELECT rows shown to the user under the answer. }
  AGENT_SQL_ROWS = 200;

function BuildAnonOptions(const P: TAgentTurn; out AInfo: string): TAnonOptions;
var
  Parts: TStringList;
  I: Integer;

  procedure Flag(AValue: Integer; var ATarget: Boolean; const AName: string);
  begin
    if AValue >= 0 then
      ATarget := AValue = 1;
    if ATarget then
      Parts.Add(AName);
  end;

begin
  Result := AnonDefaultOptions;
  Parts := TStringList.Create;
  try
    Flag(P.AnonNumbers, Result.Numbers, 'numbers');
    Flag(P.AnonDates, Result.Dates, 'dates');
    Flag(P.AnonEmails, Result.Emails, 'emails');
    Flag(P.AnonCodes, Result.Codes, 'codes');
    if (P.AnonNames = 'all') or (P.AnonNames = 'all_words') or (P.AnonNames = 'words') then
      Result.TextMode := atmAllWords
    else if (P.AnonNames = 'none') or (P.AnonNames = 'off') or (P.AnonNames = 'false') then
      Result.TextMode := atmNone
    else if P.AnonNames <> '' then
      Result.TextMode := atmNames;
    case Result.TextMode of
      atmNames: Parts.Add('names');
      atmAllWords: Parts.Add('all words');
    end;
    if P.AnonSkipHeader >= 0 then
      Result.SkipHeader := P.AnonSkipHeader = 1;
    if P.AnonDelimiter <> '' then
    begin
      if SameText(P.AnonDelimiter, 'tab') or (P.AnonDelimiter = '\t') then
        Result.Delimiter := #9
      else
        Result.Delimiter := P.AnonDelimiter[1];
    end;
    if (P.AnonColumns <> '') and AnonColumnsValid(P.AnonColumns) and (Result.Delimiter <> #0) then
    begin
      Result.Columns := P.AnonColumns;
      Parts.Add('columns ' + P.AnonColumns);
    end;
    Result.KeepWords := P.AnonKeep;
    AInfo := '';
    for I := 0 to Parts.Count - 1 do
    begin
      if AInfo <> '' then
        AInfo := AInfo + ', ';
      AInfo := AInfo + Parts[I];
    end;
  finally
    Parts.Free;
  end;
end;

function TAgentLoopClient.Cancelled: Boolean;
begin
  Result := Assigned(CancelPtr) and (CancelPtr^ <> 0);
end;

procedure AgentLog(const AText: string);
var
  FN: string;
  F: TFileStream;
  Line: AnsiString;
begin
  try
    FN := FastFileExeDirPath(ASSISTANT_LOG);
    if FileExists(FN) then
      F := TFileStream.Create(FN, fmOpenReadWrite or fmShareDenyNone)
    else
      F := TFileStream.Create(FN, fmCreate or fmShareDenyNone);
    try
      F.Seek(0, soEnd);
      Line := AnsiString(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' agent ' + AText + #13#10);
      if Line <> '' then
        F.WriteBuffer(Line[1], Length(Line));
    finally
      F.Free;
    end;
  except
  end;
end;

function Clip(const S: string; AMax: Integer): string;
begin
  if Length(S) > AMax then
    Result := Copy(S, 1, AMax) + #13#10 + '...[truncated]'
  else
    Result := S;
end;

{ The provider rejects replies where the model tried a native function call (HTTP 400 tool_use_failed). }
function IsNativeToolCallError(const AErr: string): Boolean;
begin
  Result := (Pos('tool_use_failed', AErr) > 0) or (Pos('Tool choice is none', AErr) > 0);
end;

function InvokeAgentTurn(const APrompt: string; AClient: TAgentLoopClient;
  out ARaw, AErr: string): Boolean;
var
  WideAns: WideString;
  Attempt, ToolCallMisses, EmptyRetries: Integer;
  Prompt: string;
begin
  Result := False;
  ARaw := '';
  AErr := '';
  Prompt := APrompt;
  ToolCallMisses := 0;
  EmptyRetries := 0;
  for Attempt := 1 to 5 do
  begin
    if AClient.Cancelled then
    begin
      AErr := 'stopped';
      Exit;
    end;
    if Attempt > 1 then
      AClient.Status('retry');
    Result := FastFileAIInvokePrompt(WideString(Prompt), WideAns, AErr, nil);
    ARaw := Trim(string(WideAns));
    if Result and (ARaw <> '') then
      Exit;
    Result := False;
    if AClient.Cancelled then
    begin
      AErr := 'stopped';
      Exit;
    end;
    if IsNativeToolCallError(AErr) then
    begin
      Inc(ToolCallMisses);
      AgentLog('native tool call rejected (' + IntToStr(ToolCallMisses) + '): ' + Clip(AErr, 300));
      if ToolCallMisses >= 3 then
      begin
        AErr := 'model_tool_call';
        Exit;
      end;
      Prompt := APrompt + #13#10#13#10 +
        'IMPORTANT: your previous reply was rejected because you tried to call a function ' +
        '(container.exec / python / bash). You CANNOT call functions or run code here. ' +
        'Write exactly one JSON object as plain text, for example ' +
        '{"tool":"count","needle":"Bianca"} or ' +
        '{"answer":"<text in the app UI language>","prompt":"<short plan>","tool":""}.';
      Continue;
    end;
    // Empty resposta is a model miss, not a transport failure. Ask twice more, the second time for a short reply.
    if (EmptyRetries < 2) and (Pos('No "resposta" field', AErr) > 0) then
    begin
      Inc(EmptyRetries);
      AgentLog('empty resposta, retry ' + IntToStr(EmptyRetries));
      Prompt := APrompt + #13#10 +
        'Your previous reply was empty. Return one non-empty JSON object now. ' +
        'For a count: {"tool":"count","needle":"<text from the user request>"}. ' +
        'To finish: {"answer":"<text in the app UI language>","prompt":"<short plan>","tool":""}.';
      if EmptyRetries = 2 then
        Prompt := Prompt + ' Keep the whole reply under 800 characters; one tool or a short answer.';
      Continue;
    end;
    AgentLog('gateway ' + AErr);
    Exit;
  end;
  if AErr = '' then
    AErr := 'No "resposta" field.';
  AgentLog('gateway ' + AErr);
end;

{ Readable answer from the count tool output, used when the model gives up after counting. }
function CountAnswerText(const AOut: string): string;
var
  SL, Res: TStringList;
  I, P: Integer;
  Line, Needle, Files, Matching, Hits, Path: string;
begin
  SL := TStringList.Create;
  Res := TStringList.Create;
  try
    SL.Text := AOut;
    Needle := '';
    Files := '0';
    Matching := '0';
    for I := 0 to SL.Count - 1 do
    begin
      Line := SL[I];
      if Copy(Line, 1, 7) = 'needle=' then
        Needle := Copy(Line, 8, MaxInt)
      else if Copy(Line, 1, 6) = 'files=' then
        Files := Copy(Line, 7, MaxInt)
      else if Copy(Line, 1, 15) = 'matching_lines=' then
        Matching := Copy(Line, 16, MaxInt);
    end;
    Res.Add(Format(TrText('Agent.CountAnswer'), [Matching, Needle, Files]));
    for I := 0 to SL.Count - 1 do
    begin
      Line := SL[I];
      if Copy(Line, 1, 20) <> 'file matching_lines=' then Continue;
      P := Pos(' ', Copy(Line, 21, MaxInt));
      if P = 0 then Continue;
      Hits := Copy(Line, 21, P - 1);
      P := Pos(' path=', Line);
      if P = 0 then Continue;
      Path := Copy(Line, P + 6, MaxInt);
      Res.Add('  - ' + ExtractFileName(Path) + ': ' + Hits);
    end;
    Res.Add('');
    Res.Add(TrText('Agent.CountNote'));
    Result := TrimRight(Res.Text);
  finally
    Res.Free;
    SL.Free;
  end;
end;

function QueueProposal(const P: TAgentTurn; AClient: TAgentLoopClient): string;
var
  E: TAgentEdit;
  Info: string;
begin
  E := TAgentEdit.Create;
  try
    E.Path := ExpandFileName(Trim(P.Path));
    E.LineStart := P.StartLine;
    E.LineEnd := P.EndLine;
    E.NewText := P.NewText;
    case P.Tool of
      atkEdit:
        E.Kind := aekReplace;
      atkInsert:
        begin
          E.Kind := aekInsert;
          E.LineEnd := E.LineStart - 1;
        end;
      atkDelete:
        E.Kind := aekDelete;
    else
      begin
        E.Kind := aekAnonymize;
        if not P.HasEnd then
          E.LineEnd := 0;
        E.Anon := BuildAnonOptions(P, Info);
        E.AnonInfo := Info;
      end;
    end;
    if (E.Kind in [aekReplace, aekInsert]) and (E.NewLineCount > AGENT_MAX_PROPOSAL_LINES) then
      Exit('error=text has more than ' + IntToStr(AGENT_MAX_PROPOSAL_LINES) + ' lines; split it into smaller proposals');
    case E.Kind of
      aekReplace:
        Result := Format('queued replace lines %d-%d with %d line(s); not written until the user accepts',
          [E.LineStart, E.LineEnd, E.NewLineCount]);
      aekInsert:
        Result := Format('queued insert of %d line(s) before line %d; not written until the user accepts',
          [E.NewLineCount, E.LineStart]);
      aekDelete:
        Result := Format('queued delete of lines %d-%d (%d line(s)); not written until the user accepts',
          [E.LineStart, E.LineEnd, E.LineEnd - E.LineStart + 1]);
    else
      if E.LineEnd > 0 then
        Result := Format('queued anonymize of lines %d-%d (%s); not written until the user accepts',
          [E.LineStart, E.LineEnd, E.AnonInfo])
      else
        Result := Format('queued anonymize from line %d to the end of the file (%s); not written until the user accepts',
          [E.LineStart, E.AnonInfo]);
    end;
    AClient.QueueEdit(E);
    E := nil;
  finally
    E.Free;
  end;
end;

{ "100-200", "13,12089,31023" or a mix ("1-4,10"), as the Export lines dialog takes them. }
function ValidRange(const S: string): Boolean;
var
  Parts: TArray<string>;
  Part: string;
  P: Integer;
begin
  Result := False;
  if Trim(S) = '' then Exit;
  Parts := S.Split([',', ';']);
  for Part in Parts do
  begin
    P := Pos('-', Part);
    if P = 0 then
    begin
      if StrToInt64Def(Trim(Part), 0) < 1 then Exit;
    end
    else if not ((P > 1) and (StrToInt64Def(Trim(Copy(Part, 1, P - 1)), 0) >= 1) and
      (StrToInt64Def(Trim(Copy(Part, P + 1, MaxInt)), 0) >= StrToInt64Def(Trim(Copy(Part, 1, P - 1)), 0))) then
      Exit;
  end;
  Result := True;
end;

{ Models often send only the file name ("clientes.csv") or a quoted path. Map it to the one
  selected file it names; anything ambiguous or unknown is returned unchanged and fails validation. }
function ResolveSelectedPath(const APath: string; AFiles: TStrings): string;
var
  S, Name: string;
  I, Hit: Integer;
begin
  S := Trim(APath);
  if (Length(S) >= 2) and CharInSet(S[1], ['"', '''']) and (S[Length(S)] = S[1]) then
    S := Copy(S, 2, Length(S) - 2);
  S := StringReplace(S, '/', '\', [rfReplaceAll]);
  Result := S;
  if (S = '') or (AFiles = nil) or AgentFileAllowed(S, AFiles) then Exit;
  Name := ExtractFileName(S);
  if Name = '' then Exit;
  Hit := -1;
  for I := 0 to AFiles.Count - 1 do
    if SameText(ExtractFileName(AFiles[I]), Name) then
    begin
      if Hit >= 0 then
        Exit;
      Hit := I;
    end;
  if Hit >= 0 then
    Result := AFiles[Hit];
end;

{ Tell the model which exact paths it may use, so it retries instead of giving up. }
function SelectedPathsText(AFiles: TStrings): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to AFiles.Count - 1 do
  begin
    if I >= 20 then
    begin
      Result := Result + #13#10 + '... (' + IntToStr(AFiles.Count - 20) + ' more; use list_files)';
      Break;
    end;
    Result := Result + #13#10 + AFiles[I];
  end;
end;

function OutsideSelectionError(const APath: string; AFiles: TStrings): string;
begin
  Result := 'error=file "' + APath + '" is not in the selection. If the user named that file, tell them it is ' +
    'not selected and do not use another file in its place. Otherwise retry with one of these exact paths:' +
    SelectedPathsText(AFiles);
end;

{ FastFile, not the model, decides whole word: only an explicit "exact / not partial" in the request turns it on.
  An exact name typed with capitals ("Allyne") is also matched with case, so "/allyne-bacelar" in a URL is not a hit. }
procedure ApplyMatchIntent(var P: TAgentTurn; AExact: Boolean);
begin
  if AExact then
  begin
    P.WholeWord := 1;
    if P.Needle <> AnsiLowerCase(P.Needle) then
      P.CaseSensitive := 1;
  end
  else
    P.WholeWord := 0;
end;

{ "I will do it" / "I am reading it" / "please wait" (14 languages), or text that trails off: the model
  stopped before doing the work. }
function AnswerPromisesWork(const S: string): Boolean;
var
  T: string;
begin
  T := TrimRight(S);
  Result := AgentAnswerPromisesWork(S) or (Copy(T, Length(T) - 2, 3) = '...') or
    (Copy(T, Length(T), 1) = #$2026);
end;

{ Phrases that report work as done or queued; false when no tool ran. }
function AnswerClaimsWork(const S: string): Boolean;
begin
  Result := AgentAnswerClaimsWork(S);
end;

{ Phrases that say something waits for Accept; false when nothing was queued. }
function AnswerClaimsQueue(const S: string): Boolean;
begin
  Result := AgentAnswerClaimsQueue(S);
end;

{ Text of line ALine as the tool shows it, without the "N|" prefix. }
function CurrentLineText(const APath: string; ALine: Int64; const AIndexPath: string): string;
var
  P: Integer;
begin
  Result := AgentToolReadLines(APath, ALine, 1, nil, AIndexPath);
  P := Pos('|', Result);
  if (P = 0) or (Copy(Result, 1, 6) = 'error=') or (Copy(Result, 1, 6) = 'lines=') then
    Exit('');
  Result := Copy(Result, P + 1, MaxInt);
  P := Pos(#13, Result);
  if P = 0 then
    P := Pos(#10, Result);
  if P > 0 then
    SetLength(Result, P - 1);
end;

function ProposalKey(const P: TAgentTurn): string;
begin
  Result := Format('%d|%s|%s|%d|%d|%s|%s|%s|%d|%s', [Ord(P.Tool), P.ActionId, LowerCase(P.Path),
    P.StartLine, P.EndLine, P.Needle, P.NewText, P.ReplaceText, P.Parts, P.Sql]);
end;

{ The selected file named after FROM / UPDATE / INTO ("clientes" or "clientes.csv"); '' when none matches. }
function SqlFromPath(const ASql: string; AFiles: TStrings): string;
var
  N, F: string;
  I: Integer;
begin
  Result := '';
  N := ExtractFileName(Trim(AgentSqlFromName(ASql)));
  if N = '' then Exit;
  for I := 0 to AFiles.Count - 1 do
  begin
    F := ExtractFileName(AFiles[I]);
    if SameText(F, N) or SameText(ChangeFileExt(F, ''), N) then
      Exit(AFiles[I]);
  end;
end;

{ UPDATE / DELETE / INSERT: one proposal per block of consecutive lines. }
function QueueSqlChanges(const APath: string; const R: TAgentSqlResult; AClient: TAgentLoopClient;
  var AQueued: Integer): string;
var
  I: Integer;
  E: TAgentEdit;
begin
  if Length(R.Changes) = 0 then
    Exit(R.Text + #13#10 + 'note=no line would change, so nothing was queued');
  for I := 0 to High(R.Changes) do
  begin
    E := TAgentEdit.Create;
    E.Path := ExpandFileName(APath);
    E.LineStart := R.Changes[I].LineStart;
    E.LineEnd := R.Changes[I].LineEnd;
    E.NewText := R.Changes[I].Text;
    case R.Kind of
      askUpdate, askAlter: E.Kind := aekReplace;
      askDelete: E.Kind := aekDelete;
    else
      E.Kind := aekInsert;
    end;
    AClient.QueueEdit(E);
    Inc(AQueued);
  end;
  Result := R.Text + #13#10 + 'queued ' + IntToStr(Length(R.Changes)) +
    ' proposal(s); not written until the user accepts them' + #13#10 + 'proposals_queued=' + IntToStr(AQueued);
end;

{ Shown under the model's answer: the statement FastFile ran and, for a SELECT, its result table. }
function SqlAnswerBlock(const R: TAgentSqlResult): string;
var
  I: Integer;
begin
  Result := StringOfChar('-', 40) + #13#10 + TrText('Agent.SqlQuery') + #13#10 + R.Sql + #13#10#13#10;
  if R.Kind <> askSelect then
  begin
    if Length(R.Changes) = 0 then
      Result := Result + TrText('Agent.SqlNoChange')
    else
      Result := Result + Format(TrText('Agent.SqlChanges'), [R.ChangedLines, Length(R.Changes)]);
    Exit;
  end;
  if R.HasWhere then
    Result := Result + Format(TrText('Agent.TotalFound'), [R.MatchedRows]) + #13#10;
  if R.ShownRows < R.TotalRows then
    Result := Result + Format(TrText('Agent.SqlRowsSome'), [R.ShownRows, R.TotalRows])
  else
    Result := Result + Format(TrText('Agent.SqlRowsAll'), [R.TotalRows]);
  Result := Result + #13#10 + R.Table;
  for I := 0 to High(R.Skipped) do
    Result := Result + #13#10#13#10 + Format(TrText('Agent.SqlSkipped'), [R.Skipped[I].Expr, R.Skipped[I].Count]);
end;

{ The request is itself a SQL statement: run it without the model. False (with ANote for the model) when it
  does not parse, the file is unclear or it fails, so the model can fix it or explain it in the app UI language. }
function TryDirectSql(const AUserPrompt: string; AFiles: TStrings; const APrefs: TAgentPrefs;
  AClient: TAgentLoopClient; out AAnswer, ANote: string): Boolean;
var
  Sql, Err, Path: string;
  R: TAgentSqlResult;
  Queued: Integer;
begin
  Result := False;
  AAnswer := '';
  ANote := '';
  Sql := Trim(AUserPrompt);
  if not AgentSqlStartsLikeSql(Sql) then Exit;
  if not AgentSqlParses(Sql, Err) then
  begin
    ANote := 'The request starts like SQL, but FastFile could not parse it: ' + Err + '. If it is meant as SQL, ' +
      'fix it and run it with the sql tool, then tell the user what you changed (answer in the app UI language: ' +
      AppLanguageCode(GetCurrentLanguage) + '). If it is a plain sentence, handle it as a normal request.';
    Exit;
  end;
  if AFiles.Count = 1 then
    Path := AFiles[0]
  else
  begin
    Path := SqlFromPath(Sql, AFiles);
    if (Path = '') and (AgentSqlFromName(Sql) = '') and (APrefs.OpenPath <> '') and
      AgentFileAllowed(APrefs.OpenPath, AFiles) then
      Path := ExpandFileName(APrefs.OpenPath);
  end;
  if Path = '' then
  begin
    ANote := 'The user typed this SQL statement, but it does not name one of the selected files. Run it with ' +
      'the sql tool on the right file (ask the user only if it is really unclear).';
    Exit;
  end;
  AClient.Status('sql');
  R := AgentToolSql(Path, Sql, '', -1, AGENT_SQL_ROWS, AClient.CancelPtr);
  if AClient.Cancelled then Exit;
  if not R.Ok then
  begin
    ANote := 'The user typed SQL and FastFile ran it on ' + Path + '; it failed:' + #13#10 +
      Clip(R.Text, 4000) + #13#10 + 'Fix the statement (for example the column names) and run it with the sql ' +
      'tool, then say what you changed; or explain the problem to the user. The request is only SQL, so write ' +
      'answer in the app UI language: ' + AppLanguageCode(GetCurrentLanguage) + '.';
    Exit;
  end;
  if R.Kind <> askSelect then
  begin
    Queued := 0;
    QueueSqlChanges(Path, R, AClient, Queued);
  end;
  AgentLog('direct sql ' + Clip(StringReplace(R.Text, #10, ' ', [rfReplaceAll]), 300));
  AAnswer := TrText('Agent.SqlDirect') + #13#10#13#10 + SqlAnswerBlock(R);
  Result := True;
end;

{ Lines in an export_lines range such as "100-200" or "13,12089,31023-31030". }
function RangeLineCount(const ARange: string): Int64;
var
  Parts: TArray<string>;
  S: string;
  P: Integer;
  A, B: Int64;
begin
  Result := 0;
  Parts := ARange.Split([',']);
  for S in Parts do
  begin
    P := Pos('-', S);
    if P = 0 then
    begin
      if StrToInt64Def(Trim(S), 0) > 0 then
        Inc(Result);
    end
    else
    begin
      A := StrToInt64Def(Trim(Copy(S, 1, P - 1)), 0);
      B := StrToInt64Def(Trim(Copy(S, P + 1, MaxInt)), 0);
      if (A > 0) and (B >= A) then
        Inc(Result, B - A + 1);
    end;
  end;
end;

{ "Total: N record(s) found [for X]." once per criterion, shown under the answer. }
procedure AddTotal(ATotals: TStrings; ACount: Int64; const ACriterion: string);
var
  S: string;
begin
  if ACriterion = '' then
    S := Format(TrText('Agent.TotalFound'), [ACount])
  else
    S := Format(TrText('Agent.TotalFoundFor'), [ACount, ACriterion]);
  if ATotals.IndexOf(S) < 0 then
    ATotals.Add(S);
end;

function ToolInt64(const AText, AKey: string): Int64;
var
  P, I: Integer;
begin
  Result := -1;
  P := Pos(#10 + AKey, #10 + AText);
  if P = 0 then Exit;
  I := P + Length(AKey);
  P := I;
  while (I <= Length(AText)) and CharInSet(AText[I], ['0'..'9']) do
    Inc(I);
  Result := StrToInt64Def(Copy(AText, P, I - P), -1);
end;

{ app_action: validate, then run after the answer (view) or queue for Accept (review). }
function HandleAction(const P: TAgentTurn; AFiles: TStrings; const APrefs: TAgentPrefs;
  AClient: TAgentLoopClient; var AQueued: Integer; ATotals: TStrings): string;
var
  Id, Path: string;
  Cls: TAgentActionClass;
  NeedsPath: Boolean;
  Step: TAssistantChainStep;
  E: TAgentEdit;
  Hits: Int64;
  Verb, CaseNote: string;
begin
  Id := P.ActionId;
  { export_filtered exports the filter already on screen and asks for lines; with a word it means export_matching_lines. }
  if SameText(Id, 'export_filtered') and ((Trim(P.Needle) <> '') or (Trim(P.NewText) <> '')) then
    Id := 'export_matching_lines';
  if SameText(Id, 'export_matching_lines') and (P.WholeWord = 1) then
    Exit('error=export_matching_lines also matches inside longer words. For whole words: send search with ' +
      '"whole_word":true, then export_lines with "range" = the line_numbers it returns.');
  if Id = '' then
    Exit('error=missing action id. Send {"tool":"app_action","action":"<id>",...}');
  Cls := AgentActionClass(Id);
  if Cls = aacUnsupported then
    Exit('error=unknown action "' + Id + '". Check the name: the read and change tools are count, search, ' +
      'read_lines, list_files, propose_edit, insert_lines, delete_lines, anonymize; core actions go in ' +
      '{"tool":"app_action","action":"<id from the list>"}. Only if no tool or listed action fits, tell the user plainly.');
  if Cls = aacBlocked then
    Exit('error=' + Id + ': ' + AgentActionBlockedHint(Id));
  NeedsPath := AgentActionNeedsOpenFile(Id) or (Id = 'split_equal_parts') or
    (Id = 'extract_file_parts') or (Id = 'export_lines') or (Id = 'open_and_read_file');
  Path := Trim(P.Path);
  if Path <> '' then
  begin
    if not AgentFileAllowed(Path, AFiles) then
      Exit(OutsideSelectionError(Path, AFiles));
    Path := ExpandFileName(Path);
  end
  else if NeedsPath then
  begin
    if (APrefs.OpenPath <> '') and AgentFileAllowed(APrefs.OpenPath, AFiles) then
      Path := ExpandFileName(APrefs.OpenPath)
    else if AFiles.Count = 1 then
      Path := AFiles[0]
    else
      Exit('error="path" is required for ' + Id + '. Retry the same tool with one of these exact paths:' +
        SelectedPathsText(AFiles));
  end;
  Step := Default(TAssistantChainStep);
  Step.ActionId := Id;
  Step.Path := Path;
  Step.FilterText := P.Needle;
  if (Step.FilterText = '') and (Id <> 'replace_all') then
    Step.FilterText := P.NewText;
  Step.ReplaceText := P.ReplaceText;
  Step.CaseSensitive := P.CaseSensitive = 1;
  Step.LineNo := Integer(P.LineNo);
  Step.Parts := P.Parts;
  Step.TotalParts := P.TotalParts;
  Step.PartFrom := P.PartFrom;
  Step.PartTo := P.PartTo;
  Step.ByteOffset := P.ByteOffset;
  if (Id = 'replace_all') and (Trim(P.Needle) = '') then
    Exit('error=replace_all needs "find" (text to replace) and "replace"');
  if ((Id = 'find_text') or (Id = 'apply_filter') or (Id = 'export_matching_lines')) and
     (Trim(Step.FilterText) = '') then
    Exit('error=' + Id + ' needs "needle"');
  if Id = 'export_lines' then
  begin
    if P.Range <> '' then
      Step.FilterText := StringReplace(P.Range, ' ', '', [rfReplaceAll])
    else if P.HasEnd then
      Step.FilterText := IntToStr(P.StartLine) + '-' + IntToStr(P.EndLine)
    else
      Step.FilterText := '';
    if not ValidRange(Step.FilterText) then
      Exit('error=export_lines needs "range":"<first>-<last>"');
  end;
  if (Id = 'split_equal_parts') and ((P.Parts < 2) or (P.Parts > 1000)) then
    Exit('error=split_equal_parts needs "parts" between 2 and 1000');
  if (Id = 'extract_file_parts') and ((P.TotalParts < 2) or (P.PartFrom < 1) or
     (P.PartTo < P.PartFrom) or (P.PartTo > P.TotalParts)) then
    Exit('error=extract_file_parts needs total_parts >= 2 and 1 <= part_from <= part_to <= total_parts');
  if Id = 'goto_line' then
  begin
    if Step.LineNo < 1 then
      Step.LineNo := Integer(P.StartLine);
    if Step.LineNo < 1 then
      Exit('error=goto_line needs "line"');
  end;
  if (Id = 'goto_byte_offset') and (P.ByteOffset <= 0) then
    Exit('error=goto_byte_offset needs "byte_offset" > 0');
  if Id = 'show_tab_merge_files' then
  begin
    Step.LineNo := P.MergeMode;
    Step.Parts := P.AfterLine;
  end;
  Hits := -1;
  if ((Id = 'export_matching_lines') or (Id = 'replace_all')) and (Path <> '') then
  begin
    AClient.Status('count');
    if not AgentCountMatchingLines(Path, Step.FilterText, AClient.CancelPtr, Step.CaseSensitive, Hits) then
      Hits := -1
    else
    begin
      AddTotal(ATotals, Hits, '"' + Step.FilterText + '"');
      if Hits = 0 then
      begin
        Verb := 'export';
        if Id = 'replace_all' then
          Verb := 'replace';
        CaseNote := '';
        if Step.CaseSensitive then
          CaseNote := ' (case-sensitive)';
        Exit('error=matching_lines=0: no line of ' + ExtractFileName(Path) + ' contains "' + Step.FilterText +
          '"' + CaseNote + ', so there is nothing to ' + Verb + ' and nothing was queued. Tell the user.');
      end;
    end;
  end
  else if Id = 'export_lines' then
  begin
    Hits := RangeLineCount(Step.FilterText);
    AddTotal(ATotals, Hits, '');
  end;
  E := TAgentEdit.Create;
  E.Kind := aekAction;
  E.Path := Path;
  E.Action := Step;
  E.MatchCount := Hits;
  if Cls = aacView then
  begin
    AClient.RunAfter(E);
    Exit('ok=' + Id + ' will run in the main window after your answer');
  end;
  AClient.QueueEdit(E);
  Inc(AQueued);
  Result := 'queued action ' + Id + '; it runs only when the user accepts it in Proposed edits' + #13#10 +
    'proposals_queued=' + IntToStr(AQueued);
  if Hits >= 0 then
    Result := Result + #13#10 + 'records_to_export=' + IntToStr(Hits) +
      ' (FastFile shows this total to the user; quote it)';
end;

procedure AgentExecute(const AUserPrompt: string; AFiles: TStrings;
  const APrefs: TAgentPrefs; AClient: TAgentLoopClient;
  out AAnswer, ARevised, AErr: string);
var
  Opening, Transcript, Prompt, ToolOut, Raw, LastCount, Seen, Warned, Key, Orig, DirectNote: string;
  Turn: Integer;
  Parsed: TAgentTurn;
  Count, Limit, Queued, ToolsOk, RunAfters: Integer;
  Nudged, Exact, HasSql: Boolean;
  RunPrefs: TAgentPrefs;
  SqlRes, LastSql: TAgentSqlResult;
  Totals: TStringList;
begin
  HasSql := False;
  Exact := AgentWantsExactMatch(AUserPrompt);
  Queued := 0;
  ToolsOk := 0;
  RunAfters := 0;
  RunPrefs := APrefs;
  Nudged := False;
  Seen := '';
  Warned := '';
  AAnswer := '';
  ARevised := '';
  AErr := '';
  if (AClient = nil) or (AFiles = nil) then
  begin
    AErr := 'no client';
    Exit;
  end;
  if TryDirectSql(AUserPrompt, AFiles, APrefs, AClient, AAnswer, DirectNote) then
    Exit;
  if AClient.Cancelled then
  begin
    AErr := 'stopped';
    Exit;
  end;
  if (APrefs.OpenPath <> '') and AgentFileAllowed(APrefs.OpenPath, AFiles) then
    Opening := BuildAgentOpeningPrompt(AUserPrompt, AFiles, AFiles.Count, ExpandFileName(APrefs.OpenPath))
  else
    Opening := BuildAgentOpeningPrompt(AUserPrompt, AFiles, AFiles.Count);
  if Exact then
    Opening := Opening + #13#10 + 'Match mode: EXACT. The user asked for a whole-word, not partial match: count and ' +
      'search find the word only as a whole word ("Allyne" does not find "Kallyne"). To export those lines use ' +
      'search, then export_lines with range = line_numbers. Say in the answer that the match is exact. ' +
      'In sql use WORD_MATCH(col, ''Allyne'') for a whole word, or col = ''Allyne'' for the whole field.'
  else
    Opening := Opening + #13#10 + 'Match mode: PARTIAL. count, search and export_matching_lines also find the word ' +
      'inside longer words ("Allyne" also finds "Kallyne"). This is what the user asked for; do not filter it out. ' +
      'In sql use col LIKE ''%Allyne%''.';
  if DirectNote <> '' then
    Opening := Opening + #13#10 + DirectNote;
  Transcript := '';
  LastCount := '';
  Totals := TStringList.Create;
  try
  for Turn := 1 to AGENT_MAX_TURNS do
  begin
    if AClient.Cancelled then
    begin
      AErr := 'stopped';
      AgentLog('stopped turn ' + IntToStr(Turn));
      Exit;
    end;
    AClient.Status('turn:' + IntToStr(Turn));
    if Transcript = '' then
      Prompt := Opening
    else
      Prompt := BuildAgentFollowupPrompt(Opening, Transcript);
    if not InvokeAgentTurn(Prompt, AClient, Raw, AErr) then
    begin
      if (AAnswer = '') and (LastCount <> '') and (AErr <> 'stopped') then
      begin
        AAnswer := CountAnswerText(LastCount);
        AErr := '';
      end
      else if (AAnswer = '') and (Queued > 0) then
        AAnswer := 'proposals_queued=' + IntToStr(Queued);
      Exit;
    end;
    AgentLog('model turn ' + IntToStr(Turn) + ': ' + Clip(StringReplace(Raw, #10, ' ', [rfReplaceAll]), 400));
    Parsed := ParseAgentTurn(Raw);
    { Text sent next to a tool call is a plan ("I will count..."), not the final answer. }
    if (Parsed.Tool = atkNone) and (Parsed.Answer <> '') then
      AAnswer := Parsed.Answer;
    if Parsed.RevisedPrompt <> '' then
      ARevised := Parsed.RevisedPrompt;
    Transcript := Transcript + #13#10 + 'MODEL ' + Raw;
    if (Parsed.Tool = atkNone) and Parsed.Malformed then
    begin
      AgentLog('malformed turn ' + IntToStr(Turn) + ': ' + Clip(Raw, 300));
      AClient.Status('retry');
      Transcript := Transcript + #13#10 +
        'TOOL error=reply was not one valid JSON object with an answer or a tool. Send exactly one of: ' +
        '{"tool":"count","needle":"<word>"} | {"tool":"search","path":"<path>","needle":"<word>"} | ' +
        '{"answer":"<final text in the app UI language>","prompt":"<plan>","tool":""}';
      Continue;
    end;
    if (Parsed.Tool = atkNone) and (not Nudged) and (Turn < AGENT_MAX_TURNS) and
      (Copy(TrimRight(Parsed.Answer), Length(TrimRight(Parsed.Answer)), 1) <> '?') and
      (AnswerPromisesWork(Parsed.Answer) or ((ToolsOk = 0) and AnswerClaimsWork(Parsed.Answer)) or
       ((Queued = 0) and (RunAfters = 0) and AnswerClaimsQueue(Parsed.Answer))) then
    begin
      Nudged := True;
      AAnswer := '';
      AgentLog('answer claims work without a tool result; asking again');
      AClient.Status('retry');
      if ToolsOk = 0 then
        Transcript := Transcript + #13#10 + 'TOOL error=no tool has run in this conversation, so nothing was ' +
          'done, queued, enabled or opened. If a tool or app_action can do the request, send that JSON now. ' +
          'Otherwise answer plainly that the agent cannot do it.'
      else if (Queued = 0) and (RunAfters = 0) and not AnswerPromisesWork(Parsed.Answer) then
        Transcript := Transcript + #13#10 + 'TOOL error=proposals_queued=0: nothing was queued, so nothing waits ' +
          'for Accept. Send the change tool now, or answer without saying anything was queued or marked.'
      else
        Transcript := Transcript + #13#10 + 'TOOL error=your answer says the work is still to be done. ' +
          'Send the tool JSON for it now, or give the final answer with the results you already have.';
      Continue;
    end;
    if Parsed.Tool = atkNone then
    begin
      if Nudged and (Queued = 0) and (RunAfters = 0) and
        (AnswerClaimsQueue(AAnswer) or ((ToolsOk = 0) and AnswerClaimsWork(AAnswer))) then
      begin
        AgentLog('answer still claims work without a tool result; replaced');
        AAnswer := TrText('Nothing was changed or proposed: the model did not send a valid command. ' +
          'Rephrase the request and try again.');
      end;
      AgentLog('answer turns=' + IntToStr(Turn));
      Exit;
    end;
    if AClient.Cancelled then
    begin
      AErr := 'stopped';
      AgentLog('stopped turn ' + IntToStr(Turn));
      Exit;
    end;
    ToolOut := '';
    if Parsed.Path <> '' then
      Parsed.Path := ResolveSelectedPath(Parsed.Path, AFiles)
    else if (Parsed.Tool in [atkRead, atkSearch, atkEdit, atkInsert, atkDelete, atkAnonymize, atkSql]) and
      (AFiles.Count = 1) then
      Parsed.Path := AFiles[0]
    else if Parsed.Tool = atkSql then
      Parsed.Path := SqlFromPath(Parsed.Sql, AFiles);
    if Parsed.Tool in [atkCount, atkSearch, atkAction] then
      ApplyMatchIntent(Parsed, Exact);
    Key := '';
    if Parsed.Tool in [atkEdit, atkInsert, atkDelete, atkAnonymize, atkAction, atkSql] then
      Key := #1 + ProposalKey(Parsed) + #1;
    if (Key <> '') and (Pos(Key, Seen) > 0) then
      ToolOut := 'ok=this exact ' + Parsed.RawTool + ' already ran or was queued earlier in this request; ' +
        'it was not repeated. Do not send it again; continue or finish with the answer.'
    else if (Parsed.Tool = atkEdit) and (Parsed.StartLine = Parsed.EndLine) and (Parsed.NewText <> '') and
      (Pos(#10, Parsed.NewText) = 0) and AgentFileAllowed(Parsed.Path, AFiles) and (Pos(Key, Warned) = 0) then
    begin
      Orig := CurrentLineText(Parsed.Path, Parsed.StartLine, AgentIndexPathFor(APrefs, Parsed.Path));
      if (Length(Parsed.NewText) < Length(Orig)) and EndsText(Parsed.NewText, Orig) then
      begin
        Warned := Warned + Key;
        ToolOut := 'error=line ' + IntToStr(Parsed.StartLine) + ' is now "' + Orig + '". Your text drops its ' +
          'beginning "' + Copy(Orig, 1, Length(Orig) - Length(Parsed.NewText)) + '". In read_lines output only the ' +
          'number before the first "|" is the line number. Resend propose_edit with the whole line ' +
          '(send the same text again only if dropping that part is intended).';
      end;
    end;
    if ToolOut = '' then
    case Parsed.Tool of
      atkList:
        ToolOut := AgentToolList(AFiles, AGENT_TOOL_CHARS);
      atkRead:
        if not AgentFileAllowed(Parsed.Path, AFiles) then
          ToolOut := OutsideSelectionError(Parsed.Path, AFiles)
        else
        begin
          Count := Parsed.Count;
          if Count > APrefs.MaxReadLines then
            Count := APrefs.MaxReadLines;
          AClient.Status('read');
          ToolOut := Clip(AgentToolReadLines(Parsed.Path, Parsed.StartLine, Count, AClient.CancelPtr,
            AgentIndexPathFor(APrefs, Parsed.Path)), AGENT_TOOL_CHARS);
        end;
      atkSearch:
        if not AgentFileAllowed(Parsed.Path, AFiles) then
          ToolOut := OutsideSelectionError(Parsed.Path, AFiles)
        else
        begin
          Limit := Parsed.Limit;
          if Limit > APrefs.MaxSearchHits then
            Limit := APrefs.MaxSearchHits;
          AClient.Status('search');
          ToolOut := Clip(AgentToolSearch(Parsed.Path, Parsed.Needle, Limit, AClient.CancelPtr,
            Parsed.CaseSensitive = 1, Parsed.WholeWord = 1), AGENT_TOOL_CHARS);
          if AFiles.Count > 1 then
            ToolOut := ToolOut + #13#10 +
              'note=one file only. tool count scans every selected file and returns matching_lines.';
        end;
      atkCount:
        begin
          AClient.Status('count');
          ToolOut := Clip(AgentToolCount(AFiles, Parsed.Needle, 8, AClient.CancelPtr,
            Parsed.CaseSensitive = 1, Parsed.WholeWord = 1), AGENT_TOOL_CHARS);
          if Copy(ToolOut, 1, 6) <> 'error=' then
          begin
            LastCount := ToolOut;
            if (Pos(#10'stopped=yes', ToolOut) = 0) and (ToolInt64(ToolOut, 'matching_lines=') >= 0) then
              AddTotal(Totals, ToolInt64(ToolOut, 'matching_lines='), '"' + Parsed.Needle + '"');
          end;
        end;
      atkEdit, atkInsert, atkDelete, atkAnonymize:
        if not AgentFileAllowed(Parsed.Path, AFiles) then
          ToolOut := OutsideSelectionError(Parsed.Path, AFiles)
        else
        begin
          ToolOut := QueueProposal(Parsed, AClient);
          if Copy(ToolOut, 1, 6) <> 'error=' then
          begin
            Inc(Queued);
            ToolOut := ToolOut + #13#10 + 'proposals_queued=' + IntToStr(Queued);
          end;
        end;
      atkAction:
        begin
          ToolOut := HandleAction(Parsed, AFiles, RunPrefs, AClient, Queued, Totals);
          if Pos('will run in the main window', ToolOut) > 0 then
          begin
            Inc(RunAfters);
            // Later actions without a path follow the file this one opened, not the one open before.
            if (Parsed.ActionId = 'open_and_read_file') and (Parsed.Path <> '') then
            begin
              RunPrefs.OpenPath := ExpandFileName(Parsed.Path);
              RunPrefs.IndexPath := '';
            end;
          end;
        end;
      atkSql:
        if Parsed.Path = '' then
          ToolOut := 'error="path" is required for sql when several files are selected. Retry with one of these ' +
            'exact paths:' + SelectedPathsText(AFiles)
        else if not AgentFileAllowed(Parsed.Path, AFiles) then
          ToolOut := OutsideSelectionError(Parsed.Path, AFiles)
        else
        begin
          AClient.Status('sql');
          SqlRes := AgentToolSql(Parsed.Path, Parsed.Sql, Parsed.AnonDelimiter, Parsed.SqlHeader,
            AGENT_SQL_ROWS, AClient.CancelPtr);
          if not SqlRes.Ok then
            ToolOut := Clip(SqlRes.Text, AGENT_TOOL_CHARS)
          else if SqlRes.Kind = askSelect then
          begin
            ToolOut := Clip(SqlRes.Text, AGENT_TOOL_CHARS);
            LastSql := SqlRes;
            HasSql := True;
          end
          else
          begin
            ToolOut := Clip(QueueSqlChanges(Parsed.Path, SqlRes, AClient, Queued), AGENT_TOOL_CHARS);
            LastSql := SqlRes;
            HasSql := True;
          end;
        end;
    else
      ToolOut := 'error=unknown tool ' + Parsed.RawTool + '. Valid tools: count, search, read_lines, ' +
        'list_files, sql, propose_edit, insert_lines, delete_lines, anonymize, app_action. ' +
        'They ARE available: retry with one of them.';
    end;
    if AClient.Cancelled then
    begin
      AErr := 'stopped';
      AgentLog('stopped during ' + Parsed.RawTool);
      Exit;
    end;
    if (Copy(ToolOut, 1, 6) <> 'error=') and (Copy(ToolOut, 1, 7) <> 'ok=this') then
    begin
      Inc(ToolsOk);
      if Key <> '' then
        Seen := Seen + Key;
    end;
    if Parsed.MoreTools then
      ToolOut := ToolOut + #13#10 +
        'note=your reply listed several tools; only the first one ran. Send the next tool now (one per reply).';
    Transcript := Transcript + #13#10 + 'TOOL ' + ToolOut;
    AgentLog('tool ' + Parsed.RawTool + ' turn ' + IntToStr(Turn) + ': ' +
      Clip(StringReplace(ToolOut, #10, ' ', [rfReplaceAll]), 300));
  end;
  AgentLog('turn limit');
  if AAnswer <> '' then
    Exit;
  if LastCount <> '' then
    AAnswer := CountAnswerText(LastCount)
  else if Queued > 0 then
    AAnswer := 'proposals_queued=' + IntToStr(Queued)
  else if not HasSql then
    AErr := 'turn limit';
  finally
    if (Totals.Count > 0) and ((AErr = '') or (AErr = 'turn limit')) then
    begin
      if Copy(AAnswer, 1, 17) = 'proposals_queued=' then
        AAnswer := Format(TrText('%d change(s) proposed. Review them in Proposed edits.'),
          [StrToIntDef(Copy(AAnswer, 18, MaxInt), 0)]);
      if AAnswer <> '' then
        AAnswer := TrimRight(AAnswer) + #13#10#13#10;
      AAnswer := AAnswer + TrimRight(Totals.Text);
      AErr := '';
    end;
    if HasSql and (AErr <> 'stopped') and (Copy(AAnswer, 1, 17) <> 'proposals_queued=') then
    begin
      if AAnswer = '' then
      begin
        AAnswer := SqlAnswerBlock(LastSql);
        AErr := '';
      end
      else
        AAnswer := TrimRight(AAnswer) + #13#10#13#10 + SqlAnswerBlock(LastSql);
    end;
    Totals.Free;
  end;
end;

end.
