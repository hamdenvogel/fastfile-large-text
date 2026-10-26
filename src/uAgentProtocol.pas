unit uAgentProtocol;

{
  One JSON object per model turn, carried inside the existing prompt/resposta gateway.
}

interface

uses
  Classes;

type
  TAgentToolKind = (atkNone, atkList, atkRead, atkSearch, atkCount,
    atkEdit, atkInsert, atkDelete, atkAnonymize, atkAction, atkSql, atkAssistant, atkDescribe, atkMacro,
    atkCommand, atkUnknown);

  TAgentTurn = record
    Tool: TAgentToolKind;
    { The reply asked for several tools; only the first one is run this turn. }
    MoreTools: Boolean;
    Answer: string;
    RevisedPrompt: string;
    Path: string;
    Needle: string;
    NewText: string;
    StartLine: Int64;
    EndLine: Int64;
    HasEnd: Boolean;
    Count: Integer;
    Limit: Integer;
    RawTool: string;
    { anonymize: -1 = not given, 0 = off, 1 = on }
    AnonNumbers: Integer;
    AnonDates: Integer;
    AnonEmails: Integer;
    AnonCodes: Integer;
    AnonSkipHeader: Integer;
    AnonNames: string;
    AnonColumns: string;
    AnonDelimiter: string;
    AnonKeep: string;
    { app_action: FastFile core action id and its parameters. }
    ActionId: string;
    ReplaceText: string;
    Range: string;
    LineNo: Int64;
    Parts: Integer;
    TotalParts: Integer;
    PartFrom: Integer;
    PartTo: Integer;
    ByteOffset: Int64;
    CaseSensitive: Integer;
    WholeWord: Integer;
    MergeMode: Integer;
    AfterLine: Integer;
    { sql: the statement; header -1 = auto, 0 = no header line, 1 = first line is the header. }
    Sql: string;
    SqlHeader: Integer;
    { assistant: the request handed to the Assistant panel. }
    Request: string;
    Command: string;
    { python_macro: transform(line, ctx) source, what it does, and "selected" to run on the selected lines only. }
    Script: string;
    Description: string;
    MacroSelected: Boolean;
    { JSON reply with no usable tool and no answer: the loop asks again. }
    Malformed: Boolean;
  end;

function ParseAgentTurn(const ARaw: string): TAgentTurn;
function BuildAgentOpeningPrompt(const AUserPrompt: string; AFiles: TStrings;
  ATotalFiles: Integer; const AOpenPath: string = ''): string;
function BuildAgentFollowupPrompt(const AOpening, ATranscript: string): string;
{ Intent hints in the 14 UI languages: "what is / what are these files for" and "run Python / a macro on each line". }
function AgentAsksWhatFilesAre(const APrompt: string): Boolean;
function AgentAsksLineMacro(const APrompt: string): Boolean;

implementation

uses
  SysUtils, System.JSON, uI18n;

function IsolateJsonObject(const S: string): string;
var
  A, B: Integer;
begin
  A := Pos('{', S);
  B := LastDelimiter('}', S);
  if (A > 0) and (B >= A) then
    Result := Copy(S, A, B - A + 1)
  else
    Result := '';
end;

function JsonText(O: TJSONObject; const AName: string): string;
var
  V: TJSONValue;
begin
  Result := '';
  if O = nil then Exit;
  V := O.GetValue(AName);
  if V = nil then Exit;
  if V is TJSONString then
    Result := TJSONString(V).Value
  else if not (V is TJSONNull) then
    Result := V.Value;
end;

function JsonHas(O: TJSONObject; const AName: string): Boolean;
var
  V: TJSONValue;
begin
  V := O.GetValue(AName);
  Result := (V <> nil) and not (V is TJSONNull) and (Trim(V.Value) <> '');
end;

function JsonInt64(O: TJSONObject; const AName: string; ADefault: Int64): Int64;
var
  V: TJSONValue;
begin
  Result := ADefault;
  if O = nil then Exit;
  V := O.GetValue(AName);
  if V = nil then Exit;
  if V is TJSONNumber then
    Result := Trunc(TJSONNumber(V).AsDouble)
  else
    Result := StrToInt64Def(Trim(V.Value), ADefault);
end;

function JsonFlag(O: TJSONObject; const AName: string): Integer;
var
  V: TJSONValue;
  S: string;
begin
  Result := -1;
  V := O.GetValue(AName);
  if V = nil then Exit;
  if V is TJSONTrue then
    Exit(1);
  if V is TJSONFalse then
    Exit(0);
  S := LowerCase(Trim(V.Value));
  if (S = 'true') or (S = '1') or (S = 'yes') then
    Result := 1
  else if (S = 'false') or (S = '0') or (S = 'no') then
    Result := 0;
end;

function ToolKindFromName(const AName: string): TAgentToolKind;
var
  N: string;
begin
  N := LowerCase(Trim(AName));
  if N = '' then
    Result := atkNone
  else if (N = 'list_files') or (N = 'list') then
    Result := atkList
  else if (N = 'read_lines') or (N = 'read') then
    Result := atkRead
  else if (N = 'search') or (N = 'find') then
    Result := atkSearch
  else if (N = 'count') or (N = 'count_lines') or (N = 'count_matching_lines') then
    Result := atkCount
  else if (N = 'propose_edit') or (N = 'edit') or (N = 'replace_lines') or (N = 'edit_lines') then
    Result := atkEdit
  else if (N = 'insert_lines') or (N = 'insert') then
    Result := atkInsert
  else if (N = 'delete_lines') or (N = 'delete') then
    Result := atkDelete
  else if (N = 'anonymize') or (N = 'anonymise') or (N = 'descaracterizar') then
    Result := atkAnonymize
  else if (N = 'app_action') or (N = 'action') or (N = 'run_action') or (N = 'fastfile_action') then
    Result := atkAction
  else if (N = 'sql') or (N = 'run_sql') or (N = 'sql_query') or (N = 'query') or (N = 'execute_sql') then
    Result := atkSql
  else if (N = 'assistant') or (N = 'ask_assistant') or (N = 'fastfile_assistant') or
    (N = 'compose_document') or (N = 'validate_source') then
    Result := atkAssistant
  else if (N = 'describe_files') or (N = 'describe_file') or (N = 'describe') or (N = 'file_info') or
    (N = 'files_info') or (N = 'identify_files') or (N = 'inspect_files') or (N = 'profile_files') then
    Result := atkDescribe
  else if (N = 'python_macro') or (N = 'run_python_macro') or (N = 'macro') or (N = 'run_macro') or
    (N = 'python') or (N = 'run_python') or (N = 'script_engine') or (N = 'line_macro') then
    Result := atkMacro
  else if N = 'search_command' then
    Result := atkCommand
  else
    Result := atkUnknown;
end;

procedure MergeMissing(ADest, ASrc: TJSONObject; const ASkip: array of string);
var
  I, K: Integer;
  P: TJSONPair;
  Skip: Boolean;
begin
  if ASrc = nil then Exit;
  for I := 0 to ASrc.Count - 1 do
  begin
    P := ASrc.Pairs[I];
    Skip := False;
    for K := 0 to High(ASkip) do
      if SameText(P.JsonString.Value, ASkip[K]) then
        Skip := True;
    if Skip or (ADest.GetValue(P.JsonString.Value) <> nil) then
      Continue;
    ADest.AddPair(P.JsonString.Value, TJSONValue(P.JsonValue.Clone));
  end;
end;

{ args may be an object or a JSON string holding one (OpenAI style). }
procedure MergeArgs(ADest, ASrc: TJSONObject);
const
  ARG_KEYS: array[0..4] of string = ('arguments', 'args', 'parameters', 'params', 'input');
var
  I: Integer;
  V, Parsed: TJSONValue;
begin
  if ASrc = nil then Exit;
  for I := 0 to High(ARG_KEYS) do
  begin
    V := ASrc.GetValue(ARG_KEYS[I]);
    if V is TJSONObject then
      MergeMissing(ADest, TJSONObject(V), [])
    else if (V is TJSONString) and (Pos('{', TJSONString(V).Value) > 0) then
    begin
      Parsed := TJSONObject.ParseJSONValue(TJSONString(V).Value);
      try
        if Parsed is TJSONObject then
          MergeMissing(ADest, TJSONObject(Parsed), []);
      finally
        Parsed.Free;
      end;
    end;
  end;
end;

function EscapeRawControls(const S: string): string; forward;

// First balanced JSON object in S (strings respected). ARest gets what follows it.
function FirstJsonObject(const S: string; out ARest: string): string;
var
  I, A, Depth: Integer;
  InStr, Esc: Boolean;
begin
  Result := '';
  ARest := '';
  A := Pos('{', S);
  if A = 0 then Exit;
  Depth := 0;
  InStr := False;
  Esc := False;
  for I := A to Length(S) do
  begin
    if InStr then
    begin
      if Esc then
        Esc := False
      else if S[I] = '\' then
        Esc := True
      else if S[I] = '"' then
        InStr := False;
      Continue;
    end;
    case S[I] of
      '"': InStr := True;
      '{': Inc(Depth);
      '}':
        begin
          Dec(Depth);
          if Depth = 0 then
          begin
            Result := Copy(S, A, I - A + 1);
            ARest := Copy(S, I + 1, MaxInt);
            Exit;
          end;
        end;
    end;
  end;
end;

// Accepts "tool":"count", "tool":{"name":"count",...}, "tool_calls":[{...}],
// "function":{"name":...,"arguments":"{...}"} and args nested under arguments/args/parameters.
// Returns one flat object: tool name in "tool", arguments at top level. Caller frees.
function FlattenTurn(O: TJSONObject): TJSONObject;
const
  TOOL_KEYS: array[0..4] of string = ('tool', 'action', 'function', 'tool_call', 'tool_calls');
  // "function" before "type": a tool_call has "type":"function" next to "function":{"name":...}.
  NAME_KEYS: array[0..3] of string = ('name', 'function', 'tool', 'type');
var
  I, K, FoundAt: Integer;
  V, N, Inner: TJSONValue;
  T: TJSONObject;
  Name, S: string;
  More: Boolean;

  function FirstOf(AValue: TJSONValue): TJSONValue;
  begin
    Result := AValue;
    if Result is TJSONArray then
    begin
      if TJSONArray(Result).Count > 1 then
        More := True;
      if TJSONArray(Result).Count > 0 then
        Result := TJSONArray(Result).Items[0]
      else
        Result := nil;
    end;
  end;

begin
  Result := TJSONObject.Create;
  Name := '';
  T := nil;
  FoundAt := -1;
  Inner := nil;
  More := False;
  try
  for I := 0 to High(TOOL_KEYS) do
  begin
    FoundAt := I;
    V := FirstOf(O.GetValue(TOOL_KEYS[I]));
    // "tool":"{\"tool\":\"count\",...}" or "tool":"[{...},{...}]": JSON sent as a string.
    if V is TJSONString then
    begin
      S := Trim(TJSONString(V).Value);
      if (S <> '') and CharInSet(S[1], ['{', '[']) then
      begin
        FreeAndNil(Inner);
        Inner := TJSONObject.ParseJSONValue(S);
        if Inner = nil then
          Inner := TJSONObject.ParseJSONValue(EscapeRawControls(S));
        if (Inner is TJSONObject) or (Inner is TJSONArray) then
          V := FirstOf(Inner);
      end;
    end;
    if V is TJSONString then
    begin
      S := Trim(TJSONString(V).Value);
      if S <> '' then
      begin
        // "toggle_bookmark;next_bookmark": several tools in one name. Run the first.
        K := Pos(';', S);
        if K = 0 then
          K := Pos(',', S);
        if K > 0 then
        begin
          More := True;
          S := Trim(Copy(S, 1, K - 1));
        end;
        Name := S;
        Break;
      end;
    end
    else if V is TJSONObject then
    begin
      T := TJSONObject(V);
      for K := 0 to High(NAME_KEYS) do
      begin
        N := T.GetValue(NAME_KEYS[K]);
        if N is TJSONString then
        begin
          Name := TJSONString(N).Value;
          Break;
        end
        else if N is TJSONObject then
        begin
          // "function":{"name":"count","arguments":"..."} inside a tool_call
          N := TJSONObject(N).GetValue('name');
          if N is TJSONString then
          begin
            Name := TJSONString(N).Value;
            MergeArgs(Result, TJSONObject(T.GetValue(NAME_KEYS[K])));
            Break;
          end;
        end;
      end;
      // "tool":{"replace_all":{"find":...}}: the only key is the tool name, its value holds the args.
      if (Name = '') and (T.Count = 1) and (T.Pairs[0].JsonValue is TJSONObject) then
      begin
        Name := T.Pairs[0].JsonString.Value;
        T := TJSONObject(T.Pairs[0].JsonValue);
      end;
      if Name <> '' then
        Break;
      T := nil;
    end;
  end;
  Result.AddPair('tool', Name);
  // {"tool":"app_action","action":"replace_all"}: "action" is the core action id, not the tool.
  V := O.GetValue('action');
  if (Name <> '') and (TOOL_KEYS[FoundAt] <> 'action') and (V is TJSONString) then
    Result.AddPair('action_id', TJSONString(V).Value);
  MergeMissing(Result, O, ['tool', 'action', 'function', 'tool_call', 'tool_calls']);
  if T <> nil then
  begin
    MergeMissing(Result, T, ['name', 'tool', 'type', 'function', 'id']);
    MergeArgs(Result, T);
  end;
  MergeArgs(Result, O);
  if More then
    Result.AddPair('more_tools', '1');
  finally
    Inner.Free;
  end;
end;

{ Models often put raw line breaks inside JSON strings; escape control chars found inside "...". }
function EscapeRawControls(const S: string): string;
var
  I: Integer;
  InStr, Esc: Boolean;
  Ch: Char;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create(Length(S) + 16);
  try
    InStr := False;
    Esc := False;
    for I := 1 to Length(S) do
    begin
      Ch := S[I];
      if InStr then
      begin
        if Esc then
          Esc := False
        else if Ch = '\' then
          Esc := True
        else if Ch = '"' then
          InStr := False
        else if Ch < #32 then
        begin
          case Ch of
            #10: SB.Append('\n');
            #13: SB.Append('\r');
            #9: SB.Append('\t');
          end;
          Continue;
        end;
      end
      else if Ch = '"' then
        InStr := True;
      SB.Append(Ch);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function LooksLikeAgentJson(const S: string): Boolean;
begin
  Result := (Pos('"tool"', S) > 0) or (Pos('"answer"', S) > 0) or (Pos('"tool_calls"', S) > 0) or
    (Pos('"action"', S) > 0);
end;

{ Value of "AName":"..." read by hand from JSON that does not parse (cut off, bad escapes). }
function SalvageStringField(const S, AName: string): string;
var
  P, I: Integer;
  SB: TStringBuilder;
begin
  Result := '';
  P := Pos('"' + AName + '"', S);
  if P = 0 then Exit;
  I := P + Length(AName) + 2;
  while (I <= Length(S)) and CharInSet(S[I], [' ', #9, #10, #13, ':']) do
    Inc(I);
  if (I > Length(S)) or (S[I] <> '"') then Exit;
  Inc(I);
  SB := TStringBuilder.Create;
  try
    while I <= Length(S) do
    begin
      if S[I] = '"' then
        Break;
      if (S[I] = '\') and (I < Length(S)) then
      begin
        Inc(I);
        case S[I] of
          'n': SB.Append(#13#10);
          't': SB.Append(#9);
          'r': ;
        else
          SB.Append(S[I]);
        end;
      end
      else
        SB.Append(S[I]);
      Inc(I);
    end;
    Result := Trim(SB.ToString);
  finally
    SB.Free;
  end;
end;

function ParseAgentTurn(const ARaw: string): TAgentTurn;
var
  Obj: TJSONValue;
  O: TJSONObject;
  Body, Rest: string;
  MoreAfter: Boolean;
begin
  MoreAfter := False;
  Result.MoreTools := False;
  Result.Tool := atkNone;
  Result.Answer := '';
  Result.RevisedPrompt := '';
  Result.Path := '';
  Result.Needle := '';
  Result.NewText := '';
  Result.RawTool := '';
  Result.StartLine := 1;
  Result.EndLine := 1;
  Result.HasEnd := False;
  Result.Count := 40;
  Result.Limit := 20;
  Result.AnonNumbers := -1;
  Result.AnonDates := -1;
  Result.AnonEmails := -1;
  Result.AnonCodes := -1;
  Result.AnonSkipHeader := -1;
  Result.AnonNames := '';
  Result.AnonColumns := '';
  Result.AnonDelimiter := '';
  Result.AnonKeep := '';
  Result.ActionId := '';
  Result.ReplaceText := '';
  Result.Range := '';
  Result.LineNo := 0;
  Result.Parts := 0;
  Result.TotalParts := 0;
  Result.PartFrom := 0;
  Result.PartTo := 0;
  Result.ByteOffset := 0;
  Result.CaseSensitive := -1;
  Result.WholeWord := -1;
  Result.MergeMode := -1;
  Result.AfterLine := 0;
  Result.Sql := '';
  Result.SqlHeader := -1;
  Result.Request := '';
  Result.Command := '';
  Result.Script := '';
  Result.Description := '';
  Result.MacroSelected := False;
  Result.Malformed := False;
  Body := IsolateJsonObject(ARaw);
  if Body = '' then
  begin
    Result.Answer := Trim(ARaw);
    Exit;
  end;
  Obj := TJSONObject.ParseJSONValue(Body);
  if not (Obj is TJSONObject) then
  begin
    Obj.Free;
    Obj := TJSONObject.ParseJSONValue(EscapeRawControls(Body));
  end;
  // Several objects in one reply, or text with braces after it: use the first object.
  if not (Obj is TJSONObject) then
  begin
    Obj.Free;
    Obj := TJSONObject.ParseJSONValue(EscapeRawControls(FirstJsonObject(ARaw, Rest)));
    if (Obj is TJSONObject) and (Pos('"tool"', Rest) > 0) then
      MoreAfter := True;
  end;
  if not (Obj is TJSONObject) then
  begin
    Obj.Free;
    if not LooksLikeAgentJson(Body) then
    begin
      Result.Answer := Trim(ARaw);
      Exit;
    end;
    { Broken JSON: keep a final answer if one can be read, never show the raw object. }
    if SalvageStringField(Body, 'tool') = '' then
      Result.Answer := SalvageStringField(Body, 'answer');
    Result.RevisedPrompt := SalvageStringField(Body, 'prompt');
    Result.Malformed := Result.Answer = '';
    Exit;
  end;
  O := FlattenTurn(TJSONObject(Obj));
  Obj.Free;
  try
    Result.RawTool := JsonText(O, 'tool');
    Result.Command := JsonText(O, 'command');
    Result.Tool := ToolKindFromName(Result.RawTool);
    Result.MoreTools := MoreAfter or (JsonText(O, 'more_tools') = '1');
    Result.Answer := JsonText(O, 'answer');
    Result.RevisedPrompt := JsonText(O, 'prompt');
    Result.Path := JsonText(O, 'path');
    if Result.Path = '' then
      Result.Path := JsonText(O, 'file');
    if Result.Path = '' then
      Result.Path := JsonText(O, 'file_path');
    if Result.Path = '' then
      Result.Path := JsonText(O, 'filepath');
    if Result.Path = '' then
      Result.Path := JsonText(O, 'filename');
    if Result.Path = '' then
      Result.Path := JsonText(O, 'file_name');
    Result.Needle := JsonText(O, 'needle');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'filter_text');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'query');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'term');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'pattern');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'word');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'search');
    if Result.Needle = '' then
      Result.Needle := JsonText(O, 'find');
    if (Result.Needle = '') and (Result.Tool in [atkSearch, atkCount]) then
      Result.Needle := JsonText(O, 'text');
    Result.NewText := JsonText(O, 'text');
    if Result.NewText = '' then
      Result.NewText := JsonText(O, 'new_text');
    if Result.NewText = '' then
      Result.NewText := JsonText(O, 'replacement');
    if JsonHas(O, 'before') then
      Result.StartLine := JsonInt64(O, 'before', 1)
    else if JsonHas(O, 'start') then
      Result.StartLine := JsonInt64(O, 'start', 1)
    else if JsonHas(O, 'start_line') then
      Result.StartLine := JsonInt64(O, 'start_line', 1)
    else
      Result.StartLine := JsonInt64(O, 'from', 1);
    if JsonHas(O, 'end') then
    begin
      Result.HasEnd := True;
      Result.EndLine := JsonInt64(O, 'end', Result.StartLine);
    end
    else if JsonHas(O, 'end_line') then
    begin
      Result.HasEnd := True;
      Result.EndLine := JsonInt64(O, 'end_line', Result.StartLine);
    end
    else if JsonHas(O, 'to') then
    begin
      Result.HasEnd := True;
      Result.EndLine := JsonInt64(O, 'to', Result.StartLine);
    end
    else
    begin
      Result.HasEnd := False;
      Result.EndLine := Result.StartLine;
    end;
    Result.Count := Integer(JsonInt64(O, 'count', 40));
    { read_lines given as start..end instead of start + count. }
    if (Result.Tool = atkRead) and not JsonHas(O, 'count') and Result.HasEnd and
      (Result.EndLine >= Result.StartLine) then
      Result.Count := Integer(Result.EndLine - Result.StartLine + 1);
    Result.Limit := Integer(JsonInt64(O, 'limit', 20));
    // read_lines tail: "last":5 or "start":-5. StartLine = -1 tells the tool to count from the end.
    if (Result.Tool = atkRead) and (JsonHas(O, 'last') or (Result.StartLine < 0)) then
    begin
      if JsonHas(O, 'last') then
        Result.Count := Integer(JsonInt64(O, 'last', 10))
      else
        Result.Count := Integer(-Result.StartLine);
      Result.StartLine := -1;
      Result.EndLine := -1;
    end
    // insert_lines "before":"end" appends; StartLine = -1 tells the loop to use the file's last line + 1.
    else if (Result.Tool = atkInsert) and SameText(Trim(JsonText(O, 'before')), 'end') then
    begin
      Result.StartLine := -1;
      Result.EndLine := -1;
    end
    else if Result.StartLine < 1 then
      Result.StartLine := 1;
    if Result.EndLine < Result.StartLine then
      Result.EndLine := Result.StartLine;
    Result.AnonNumbers := JsonFlag(O, 'numbers');
    Result.AnonDates := JsonFlag(O, 'dates');
    Result.AnonEmails := JsonFlag(O, 'emails');
    Result.AnonCodes := JsonFlag(O, 'codes');
    Result.AnonSkipHeader := JsonFlag(O, 'skip_header');
    Result.AnonNames := LowerCase(Trim(JsonText(O, 'names')));
    Result.AnonColumns := Trim(JsonText(O, 'columns'));
    Result.AnonDelimiter := JsonText(O, 'delimiter');
    Result.AnonKeep := JsonText(O, 'keep_words');
    Result.ActionId := JsonText(O, 'action_id');
    if Result.ActionId = '' then
      Result.ActionId := JsonText(O, 'action');
    if Result.ActionId = '' then
      Result.ActionId := JsonText(O, 'action_name');
    // The model may name a core action directly as the tool: {"tool":"replace_all",...}.
    if Result.Tool = atkUnknown then
    begin
      Result.Tool := atkAction;
      if Result.ActionId = '' then
        Result.ActionId := Result.RawTool;
    end;
    Result.ActionId := LowerCase(Trim(Result.ActionId));
    if SameText(Result.ActionId, 'sort_csv_column') then
    begin
      if JsonHas(O, 'column') then
      begin
        if StrToIntDef(Trim(JsonText(O, 'column')), 0) > 0 then
          Result.LineNo := JsonInt64(O, 'column', 0)
        else if Trim(JsonText(O, 'column')) <> '' then
          Result.Needle := Trim(JsonText(O, 'column'));
      end;
      if JsonFlag(O, 'descending') >= 0 then
        Result.CaseSensitive := JsonFlag(O, 'descending');
    end;
    Result.ReplaceText := JsonText(O, 'replace');
    if Result.ReplaceText = '' then
      Result.ReplaceText := JsonText(O, 'replace_with');
    if (Result.ReplaceText = '') and (Result.Tool = atkAction) then
      Result.ReplaceText := Result.NewText;
    Result.Range := Trim(JsonText(O, 'range'));
    Result.LineNo := JsonInt64(O, 'line', 0);
    Result.Parts := Integer(JsonInt64(O, 'parts', 0));
    Result.TotalParts := Integer(JsonInt64(O, 'total_parts', 0));
    Result.PartFrom := Integer(JsonInt64(O, 'part_from', 0));
    Result.PartTo := Integer(JsonInt64(O, 'part_to', 0));
    Result.ByteOffset := JsonInt64(O, 'byte_offset', 0);
    Result.CaseSensitive := JsonFlag(O, 'case_sensitive');
    Result.WholeWord := JsonFlag(O, 'whole_word');
    Result.MergeMode := Integer(JsonInt64(O, 'merge_mode', -1));
    Result.AfterLine := Integer(JsonInt64(O, 'after_line', 0));
    Result.Sql := JsonText(O, 'sql');
    if Result.Sql = '' then
      Result.Sql := JsonText(O, 'statement');
    if (Result.Sql = '') and (Result.Tool = atkSql) then
      Result.Sql := Result.Needle;
    Result.SqlHeader := JsonFlag(O, 'header');
    if (Result.Tool = atkSql) and (Result.Sql = Result.Needle) then
      Result.Needle := '';
    if Result.Tool = atkAssistant then
    begin
      Result.Request := JsonText(O, 'request');
      if Result.Request = '' then
        Result.Request := JsonText(O, 'question');
      if Result.Request = '' then
        Result.Request := JsonText(O, 'message');
      if Result.Request = '' then
        Result.Request := Result.NewText;
      if Result.Request = '' then
        Result.Request := Result.Needle;
    end;
    if Result.Tool = atkMacro then
    begin
      Result.Script := JsonText(O, 'script');
      if Result.Script = '' then
        Result.Script := JsonText(O, 'code');
      if Result.Script = '' then
        Result.Script := JsonText(O, 'python');
      if Result.Script = '' then
        Result.Script := JsonText(O, 'source');
      if Result.Script = '' then
        Result.Script := Result.NewText;
      Result.Description := JsonText(O, 'description');
      if Result.Description = '' then
        Result.Description := JsonText(O, 'summary');
      if Result.Description = '' then
        Result.Description := JsonText(O, 'title');
      Result.MacroSelected := SameText(Trim(JsonText(O, 'scope')), 'selected') or
        SameText(Trim(JsonText(O, 'scope')), 'selection');
    end;
    if (Result.Tool = atkNone) and (Result.Answer = '') then
    begin
      Result.Answer := JsonText(O, 'resposta');
      if Result.Answer = '' then
        Result.Answer := JsonText(O, 'Resposta');
      { Gateway already unwraps one resposta. A second object is the real turn. }
      if (Result.Answer <> '') and (Pos('{', Result.Answer) > 0) then
      begin
        Result := ParseAgentTurn(Result.Answer);
        Exit;
      end;
    end;
    { Valid JSON but neither a tool nor an answer: never show it to the user as the answer. }
    if (Result.Tool = atkNone) and (Trim(Result.Answer) = '') then
    begin
      Result.Answer := '';
      Result.Malformed := True;
    end;
  finally
    O.Free;
  end;
end;

function FoldIntentText(const S: string): string;
var
  I: Integer;
begin
  Result := AnsiLowerCase(S);
  for I := 1 to Length(Result) do
    case Ord(Result[I]) of
      $C0..$C5, $E0..$E5, $0103, $0105: Result[I] := 'a';
      $C7, $E7, $0107, $010D: Result[I] := 'c';
      $C8..$CB, $E8..$EB, $0119, $011B: Result[I] := 'e';
      $CC..$CF, $EC..$EF: Result[I] := 'i';
      $D2..$D6, $F2..$F6, $0151: Result[I] := 'o';
      $D9..$DC, $F9..$FC, $016F, $0171: Result[I] := 'u';
      $FD: Result[I] := 'y';
      $0142: Result[I] := 'l';
      $0144: Result[I] := 'n';
      $0159: Result[I] := 'r';
      $015B, $015F, $0161, $0219: Result[I] := 's';
      $0163, $021B: Result[I] := 't';
      $017A, $017C, $017E: Result[I] := 'z';
      $2019: Result[I] := '''';
    end;
end;

function HasAnyToken(const AFolded: string; const ATokens: array of string): Boolean;
var
  T: string;
begin
  for T in ATokens do
    if Pos(T, AFolded) > 0 then
      Exit(True);
  Result := False;
end;

function AgentAsksWhatFilesAre(const APrompt: string): Boolean;
var
  F: string;
begin
  F := FoldIntentText(APrompt);
  Result := HasAnyToken(F, [
    'para que serve', 'para que sirve', 'o que e este arquivo', 'o que e esse arquivo', 'o que sao estes',
    'o que sao esses', 'o que e este ficheiro', 'o que contem', 'que es este archivo', 'que son estos',
    'what is this file', 'what are these files', 'what is the file', 'what are the files', 'what does this file',
    'what do these files', 'what''s this file', 'purpose of this', 'purpose of these', 'what is it for',
    'what are they for', 'identify these', 'identify this', 'explain this file', 'explain these files',
    'describe this file', 'describe these files', 'a quoi sert', 'a quoi servent', 'que contient',
    'wozu dient', 'wozu dienen', 'was ist diese datei', 'was sind diese dateien', 'a cosa serve',
    'a cosa servono', 'cos''e questo file', 'do czego sluz', 'co to za plik', 'co to za pliki',
    'la ce serveste', 'la ce servesc', 'ce este acest fisier', 'ce sunt aceste fisiere', 'mire valo',
    'mi ez a fajl', 'mik ezek a fajlok', 'k cemu slouz', 'co je tento soubor', 'co jsou tyto soubory',
    'explique este', 'explique estes', 'explique esse', 'descreva este', 'descreva estes', 'identifique',
    #$7528#$9014, #$4F55#$306E#$305F#$3081, #$4F55#$306E#$30D5#$30A1#$30A4#$30EB, #$4F55#$306B#$4F7F#$3046,
    #$662F#$4EC0#$4E48, #$662F#$4EC0#$9EBC, #$505A#$4EC0#$4E48#$7528, #$505A#$4EC0#$9EBC#$7528, #$4F5C#$7528]);
end;

function AgentAsksLineMacro(const APrompt: string): Boolean;
var
  F: string;
begin
  F := FoldIntentText(APrompt);
  Result := HasAnyToken(F, ['python', 'macro', 'makro', 'script', 'skript', 'skrypt',
    #$30DE#$30AF#$30ED, #$30B9#$30AF#$30EA#$30D7#$30C8, #$5B8F, #$5DE8#$96C6, #$811A#$672C]) and
    HasAnyToken(F, ['each line', 'every line', 'all lines', 'per line', 'line by line', 'cada linha',
      'todas as linhas', 'linha a linha', 'cada linea', 'todas las lineas', 'chaque ligne', 'toutes les lignes',
      'jede zeile', 'jeder zeile', 'alle zeilen', 'ogni riga', 'tutte le righe', 'kazdej linii', 'kazdego wiersza',
      'wszystkie linie', 'fiecare linie', 'toate liniile', 'minden sor', 'kazdy radek', 'kazdem radku',
      'vsechny radky', #$5404#$884C, #$5168#$884C, #$6BCF#$884C, #$6BCF#$4E00#$884C, #$9010#$884C,
      'execut', 'rodar', 'rode ', 'aplicar', 'aplique', 'run ', 'apply', 'ejecut', 'ausfuhr', 'fuhre',
      'esegu', 'uruchom', 'wykonaj', 'ruleaz', 'futtas', 'spust', #$5B9F#$884C, #$6267#$884C, #$57F7#$884C,
      #$8FD0#$884C]);
end;

function BuildAgentOpeningPrompt(const AUserPrompt: string; AFiles: TStrings;
  ATotalFiles: Integer; const AOpenPath: string): string;
var
  I, N: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('You are the FastFile agent. You DO the work on the selected files; you do not only explain.');
    SL.Add('Files can be many GB. You cannot see contents until a tool runs. Never ask for a whole file.');
    SL.Add('Return ONE JSON object only. No markdown, no code fence, no empty object.');
    SL.Add('There is NO function calling and NO code execution by you (no python, bash, container.exec, browser); ' +
      'Python on the lines of a file only runs through the python_macro tool below, after the user accepts it.');
    SL.Add('The "tools" below are JSON you WRITE as plain text in your reply; FastFile runs them.');
    SL.Add('');
    SL.Add('Read tools (run now, result comes back to you):');
    SL.Add('{"tool":"count","needle":"<word>"}  lines that contain the word, in every selected file');
    SL.Add('{"tool":"search","path":"<path>","needle":"<word>","limit":20}  matching lines with line numbers, one file');
    SL.Add('  count and search ignore upper/lower case. Add "case_sensitive":true only when the user asks to match case.');
    SL.Add('  count and search match parts of words ("Allyne" also finds "Kallyne"). FastFile sets whole-word matching ' +
      'itself, only when the user asks for an exact / not partial match; see "Match mode" below.');
    SL.Add('{"tool":"read_lines","path":"<path>","start":1,"count":40}  a line range');
    SL.Add('{"tool":"read_lines","path":"<path>","last":5}  the last 5 lines of the file');
    SL.Add('  Output lines are N|text: N is the line number, the line text starts right after the first "|".');
    SL.Add('{"tool":"list_files"}');
    SL.Add('{"tool":"search_command","command":"glob \"**\\*.log\""}');
    SL.Add('  Bare "grep" and "glob" open the interactive modal with AI help, editable command and ' +
      'suggestions; use app_action apply_filter with needle="grep" or needle="glob" for such requests, ' +
      'not search_command. Find, Filter and Bookmarks each have separate grep and glob launch buttons. ' +
      'Generating an AI suggestion in the modal never runs it; the user clicks Run command. ' +
      'search_command with a bare name or --help returns help only, without opening UI.');
    SL.Add('{"tool":"search_command","command":"grep -i -E \"error|failure\" --glob \"**\\*.log\" --limit 200"}');
    SL.Add('  These are INTERNAL commands, never shell commands. glob matches file paths, NOT content. ' +
      '* matches within one path component, ? one character, ** crosses folders. Only the selected files ' +
      '(already expanded under the user scan settings) are eligible, never invent or expand other paths.');
    SL.Add('  grep defaults to case-sensitive literal text (-F). -E uses Delphi PCRE regex; -i ignores case; ' +
      '-s matches case; -v inverts; -w requires whole words; -n is accepted (line numbers always shown). ' +
      '--glob limits eligible file paths. Quote patterns containing spaces. Backslashes are literal. ' +
      '--limit 1..10000 bounds the GLOBAL result set (default 200). partial=true is NOT an exact total.');
    SL.Add('  An optional single file operand after the pattern restricts search_command to that authorized file; ' +
      'it NEVER authorizes a new source. Do not invent file operands. Main-window apply_filter uses its filename ' +
      'field before agent sources when the operand is omitted. A user-supplied explicit file is validated and ' +
      'loaded before the GUI command runs. GB files are streamed; 16,777,216 decoded characters per line maximum, ' +
      'with explicit errors rather than incomplete matches. Scanning stops immediately at the hit limit.');
    SL.Add('  Translate natural-language requests in ANY of the 14 UI languages into the correct command. ' +
      'For "logs containing errors", use grep -i "error" --glob "**\*.log", not glob "*error*". ' +
      'For "find CSV files", use glob "*.csv". Preserve the user''s actual search text, do not translate it. ' +
      'When the user wants captured fields as columns (ip and status, name and amount), use grep -E with ' +
      'named groups (?<name>...) or (?P<name>...). FastFile shows one result column per group.');
    SL.Add('  To mark matching lines in the OPEN file, or search only its bookmarks, use app_action ' +
      'apply_filter with needle="grep ... --mark" or needle="grep ... --bookmarks"; ' +
      'search_command itself is read-only and has no bookmark state. --mark adds bookmarks, never toggles ' +
      'existing ones. Other-file hits are skipped explicitly. Explain results in the app UI language.');
    SL.Add('{"tool":"describe_files"}  a profile of every file of the request: size, date, encoding, binary type, ' +
      'line ending, line count, delimiter and columns, first and last lines. Add "path" for one file only.');
    SL.Add('  Use it first for "what is this file / what are these files for", "explain / identify / summarize these ' +
      'files", "which format / encoding / separator", "do they have a header", "are they the same layout", ' +
      '"which one is the log / the export / the config".');
    SL.Add('{"tool":"sql","path":"<path>","sql":"SELECT cidade, COUNT(*) AS total FROM clientes GROUP BY cidade ORDER BY total DESC"}');
    SL.Add('  SQL over one delimited file (CSV, TSV, ...; any size, one streaming pass). Translate the user request ' +
      'into SQL yourself, whatever its kind: counts, sums, averages, min/max, grouping, ordering, top N, distinct ' +
      'values, filters on columns, computed columns, and also changes to the data.');
    SL.Add('  SELECT [DISTINCT] ... [FROM file] [WHERE] [GROUP BY] [HAVING] [ORDER BY .. ASC|DESC] [LIMIT n [OFFSET m]] runs now.');
    SL.Add('  UPDATE file SET col = expr, ... [WHERE] | DELETE FROM file [WHERE] | INSERT INTO file (cols) VALUES (..), (..) ' +
      'are queued for Accept like the change tools (UPDATE rewrites only the assigned fields; the header line is never changed).');
    SL.Add('  ALTER TABLE file ADD COLUMN col [DEFAULT expr] [FIRST | AFTER col] | ALTER TABLE file DROP COLUMN col | ' +
      'ALTER TABLE file RENAME COLUMN col TO new | TRUNCATE TABLE file (removes every data line, keeps the header) ' +
      'are queued for Accept too. DEFAULT may use other columns: ADD COLUMN nome_upper DEFAULT UPPER(nome).');
    SL.Add('  The user may write SQL or say it in words, in any language and with any phrasing. Map the intent: ' +
      'show / list / count / sum / average / group / sort / top / distinct -> SELECT; update / change / set / fix / ' +
      'correct / replace a value -> UPDATE; insert / add / include a record -> INSERT; delete / remove / erase / ' +
      'exclude records -> DELETE; add / remove / rename a column -> ALTER TABLE; empty / clear all records -> TRUNCATE. ' +
      'A line number given by the user is WHERE line_no = N (or line_no BETWEEN a AND b).');
    SL.Add('  Columns: the header names; "Double Quotes" for names with spaces or accents; c1, c2, ... by position; ' +
      'line = whole line text; line_no = line number. Text values in single quotes.');
    SL.Add('  Text compare (=, <>, <, LIKE, IN) ignores case. Empty field = NULL (test with IS NULL). Numbers in text ' +
      'such as 1.234,56 or R$ 10,50 are read as numbers by SUM, AVG, MIN, MAX, NUM() and comparisons.');
    SL.Add('  Operators: AND OR NOT = <> < <= > >= + - * / % || LIKE IN BETWEEN IS NULL CASE WHEN. Functions: COUNT(*) ' +
      'COUNT(DISTINCT x) SUM AVG MIN MAX UPPER LOWER TRIM LENGTH SUBSTR LEFT RIGHT REPLACE INSTR SPLIT_PART CONCAT ' +
      'COALESCE NULLIF IIF ABS ROUND FLOOR CEIL NUM INT TEXT CAST DATE YEAR MONTH DAY CONTAINS WORD_MATCH STARTS_WITH ENDS_WITH.');
    SL.Add('  Not supported: JOIN, UNION, subqueries, CREATE, DROP TABLE, column types, keys and indexes. ' +
      'Optional "delimiter":";" and "header":false.');
    SL.Add('  Every sql result lists the columns; if you do not know them, send SELECT * LIMIT 3 first. Rows of a SELECT ' +
      'without GROUP BY come with line_numbers=, usable as export_lines range.');
    SL.Add('  FastFile shows your SELECT and its full result table to the user under your answer: in answer give the ' +
      'conclusion and the key numbers, do not copy the whole table.');
    SL.Add('');
    SL.Add('Change tools (queued as proposals; FastFile writes them when the user clicks Accept):');
    SL.Add('{"tool":"propose_edit","path":"<path>","start":10,"end":12,"text":"new line 10\nnew line 11"}  replace lines start..end with text (any number of lines)');
    SL.Add('{"tool":"insert_lines","path":"<path>","before":50,"text":"line A\nline B"}  insert before line 50; "before":"end" appends after the last line');
    SL.Add('{"tool":"delete_lines","path":"<path>","start":100,"end":250}');
    SL.Add('{"tool":"anonymize","path":"<path>","start":1,"end":1000,"numbers":true,"dates":true,"emails":true,"codes":true,"names":"names","columns":"","delimiter":"","skip_header":false,"keep_words":""}');
    SL.Add('  anonymize keeps the same length and character type. Omit start/end for the whole file. names = names | all | none. columns like "2,5-7" with delimiter like ";".');
    SL.Add('');
    SL.Add('Python macro on each line (queued; runs when the user accepts it, in the Python macro panel of the main ' +
      'window, with a preview of the first lines before the full run):');
    SL.Add('{"tool":"python_macro","path":"<path>","description":"<what it does, short, in the app UI language>",' +
      '"script":"import re\ndef transform(line, ctx):\n    return line.upper()"}');
    SL.Add('  The script MUST define transform(line, ctx): line is the text of one line without the line break; ' +
      'return the new text, or None to drop the line from the output. ctx[''line_number''] is the line number; ' +
      'ctx is a dict kept between lines (counters, totals, seen values). Standard library only (re, json, csv, ' +
      'datetime, decimal, hashlib, unicodedata...); no files, network or input().');
    SL.Add('  The output goes to the macro panel and can be saved as a new file; the original file is never ' +
      'changed. "scope":"selected" runs only on the lines selected in the main window; default is every line.');
    SL.Add('  Use it for "run / apply / execute a Python (macro, script) on each line", and for per-line ' +
      'transformations that replace_all, sql and anonymize cannot do (reformat dates, convert each line to JSON, ' +
      'extract or reorder fields, mask with rules, compute values, number lines, keep lines by complex rules, ' +
      'running totals). Read or describe the file first so the script fits the real layout (delimiter, ' +
      'header: return the header line unchanged or None).');
    SL.Add('  Several files: one python_macro per file, each with its own path. To WRITE a standalone .py file ' +
      'instead, use the assistant tool.');
    SL.Add('');
    SL.Add('FastFile core actions: {"tool":"app_action","action":"<id>","path":"<path>", ...params}');
    SL.Add('Queued for Accept (they write files or change settings):');
    SL.Add('  replace_all find, replace, case_sensitive  - every occurrence in the file');
    SL.Add('  delete_duplicate_lines | extract_frequent_strings | split_files | export_file  - opens the FastFile tool on that file');
    SL.Add('  pattern_split needle  - new file each time a line contains needle');
    SL.Add('  export_lines range:"100-200" or range:"13,12089,31023"  - new file with those lines (ranges and lists, up to 100000 lines)');
    SL.Add('  export_matching_lines needle, case_sensitive  - new file with the lines that contain needle (part of a word also matches)');
    SL.Add('  To export whole-word matches: search with "whole_word":true and a limit above hits, then export_lines with ' +
      'range = the line numbers found, comma separated. Do not use export_matching_lines for that.');
    SL.Add('  split_equal_parts parts:4  - "divide / split into 4 parts": writes ALL the parts');
    SL.Add('  extract_file_parts total_parts:10, part_from:2, part_to:3  - only when the user asks for SOME parts ' +
      '("extract parts 2 to 3 of 10"); one step, never split_equal_parts first');
    SL.Add('  Several files in the request ("split the file" with no file named, "export the lines with X"): ' +
      'send the action once for EACH of them, each with its own "path". Never only the file open in the main window.');
    SL.Add('  force_index_file  - builds the line index of that file now ("force/index the file") | save_session | ' +
      'load_session | toggle_readonly_session');
    SL.Add('  save_session writes one .ffsession for the open file: file, line, active filter, bookmarks and view ' +
      'encoding. load_session reopens that state. Both are global: send them once, without path.');
    SL.Add('  clear_bookmarks  - removes ALL bookmarks of the file at once ("limpe todos os marcadores")');
    SL.Add('  open_policy_auto | open_policy_index | open_policy_instant  - only the setting for how files open later ' +
      '(not indexing a file now) | segment_ops_auto | segment_ops_always | segment_ops_never');
    SL.Add('Run after your answer (view only):');
    SL.Add('  open_and_read_file | goto_line line | goto_byte_offset byte_offset | goto_file_start | goto_file_end');
    SL.Add('  find_text needle | find_next | find_previous | view_find_occurrences | apply_filter needle | clear_filter | copy_filtered');
    SL.Add('  filter_match_contains | filter_match_prefix | filter_match_regex | toggle_csv_mode | toggle_csv_header | toggle_word_wrap');
    SL.Add('  sort_csv_column column:<1-based index or header name> descending:true  - sort the open delimited view ' +
      'by that column. The file is not loaded or rewritten. A second request with the opposite descending value ' +
      'reverses the order. clear_csv_sort restores file order. Refuse while a filter is active: clear_filter first. ' +
      'Turn CSV mode on yourself; do not ask the user to click the header.');
    SL.Add('  toggle_whitespace_marks | zoom_in | zoom_out | toggle_bookmark | next_bookmark | start_tail | pause_tail');
    SL.Add('  show_tab_compare | show_tab_merge_lines | show_tab_merge_files path, merge_mode, after_line | show_tab_recent');
    SL.Add('  open_find | open_filter | open_replace | find_in_files | show_script_engine | show_tail_macro | show_version_history');
    SL.Add('  open_options | open_preferences | show_help | show_about | new_file | toggle_fullscreen | toggle_bookmark_bar | restore_session_tabs');
    SL.Add('  open_anonymize_dialog  - the anonymize window for the file open in the main window (prefer the anonymize tool)');
    SL.Add('  open_file_dialog  - the Open file window | copy_selection | cancel_search  - stops a running Find');
    SL.Add('  consumer_ai path, needle:"<question>"  - SQL chat window on that file | consumer_rag path, needle:"<question>"  - ' +
      'chat about the meaning of that file');
    SL.Add('  edit_line line | insert_multiple_lines  - open the line editor window (only when the user asks for that window; ' +
      'otherwise use propose_edit / insert_lines)');
    SL.Add('Queued for Accept, they change the file open in the main window:');
    SL.Add('  undo | redo  - undo / redo the last change made in the main window | paste_lines  - paste the clipboard lines ' +
      'at the selected line | duplicate_line line | tail_macro_reprocess');
    SL.Add('');
    SL.Add('FastFile Assistant (the chat panel of the main window): {"tool":"assistant","request":"<request>"}');
    SL.Add('  Runs after your answer; the Assistant reply is added under your answer. Use it ONLY for what the tools ' +
      'above cannot do:');
    SL.Add('  - write a new document or source file from the data (Word, PDF, HTML, TXT, Markdown, a report, a summary ' +
      'file, Python / JS / SQL code) or fix the last generated one;');
    SL.Add('  - validate the syntax of a source file (.py, .js, .jsx, .ts, .tsx, .json, .html, .sql, and .java / .go / ' +
      '.cs when javac / gofmt / csc are installed);');
    SL.Add('  - fix a source file that failed validation: put the path and the errors in request ("fix the errors of ' +
      '<path>: <errors>"); the Assistant rewrites the file.');
    SL.Add('  - questions about how to use FastFile itself (menus, shortcuts, features, F1 help).');
    SL.Add('  request: the user''s request in the user''s words and language, self-contained, with the full path of ' +
      'every file it needs. Send it once; do not also describe the result as done: say it was handed to the Assistant.');
    SL.Add('  The files in request do NOT need to be selected (a .py to validate may be anywhere). Nothing goes to ' +
      'Proposed edits and nothing waits for Accept: never mention Accept for it.');
    SL.Add('Not available in FastFile (say so): encoding conversion, line-ending (EOL) conversion, rewriting a file into ' +
      'sorted line order, editing binary data. Sorting the open delimited view is sort_csv_column and does not rewrite the file.');
    SL.Add('');
    SL.Add('To finish: {"answer":"<what you found or what you queued, in the app UI language>","prompt":"<one short plan>","tool":""}');
    SL.Add('');
    SL.Add('Rules:');
    SL.Add('- When the user asks to change, fix, insert, remove or anonymize data, queue the change tools. Do not just describe the change.');
    SL.Add('- Before editing specific lines, read or search them so the line numbers are real.');
    SL.Add('- All line numbers refer to the file as it is now. Queued proposals do not shift each other. Do not queue overlapping proposals.');
    SL.Add('- A how-many question must call count or sql first. count finds text anywhere in the line and counts lines; ' +
      'for a value in a column, a sum, a group or a ranking of a delimited file use sql. Quote the tool numbers.');
    SL.Add('- Data changes by condition on columns ("set X where Y", "remove the records with ...", "add a record") ' +
      'are sql UPDATE / DELETE / INSERT; column changes are sql ALTER TABLE. For a delimited file prefer sql to ' +
      'propose_edit, also for one line (UPDATE ... WHERE line_no = N keeps the other fields intact).');
    SL.Add('- path must be copied from the selected files (not for the assistant tool).');
    SL.Add('- A question about how to use FastFile (where a feature is, which menu or shortcut, how to do X in the ' +
      'program) goes to the assistant tool. Never answer it from memory: menus and shortcuts you guess are wrong.');
    SL.Add('- The user asks for a document, report, PDF, Word, HTML, Markdown or code file: first gather the data ' +
      'with the read tools if needed, then send the assistant tool with the request and the key facts you found. ' +
      'Never finish such a request without sending the assistant tool; you cannot write those files yourself.');
    SL.Add('- Prefer replace_all for "replace every X with Y" in a whole file; use propose_edit for specific lines.');
    SL.Add('- An app_action acts on one file. For several files send one action per file, one per reply.');
    SL.Add('- "Filter"/"filtre"/"filtrar" on screen means apply_filter (or filter_match_regex for a regex), not search.');
    SL.Add('- propose_edit text is the whole new line. Keep every column you did not mean to change.');
    SL.Add('- Anonymize, mask, redact, descaracterizar or anonimizar lines N to M: tool anonymize with start and end. ' +
      'Never propose_edit and never edit_line (those only open or rewrite the text).');
    SL.Add('- anonymize: "keep X" -> keep_words, "only columns" -> columns + delimiter, "not the header" -> skip_header:true, ' +
      'only names -> numbers/dates/emails/codes false. Turn on only the kinds the user names ("the e-mails" -> ' +
      'emails true, the rest false and names "none"); all kinds only when none is named.');
    SL.Add('- Every id listed above is usable by you through app_action (new_file, toggle_fullscreen, show_help, ...). ' +
      'open_policy_*, segment_ops_*, save_session and load_session are global: send them once, without path.');
    SL.Add('- Which files: infer them from the request. By name ("log.txt"), by position in the Selected files list ' +
      '("leia o primeiro arquivo", "leia somente o último", "the last two files", "file 2"), by type ("the CSV"), ' +
      'all ("todos os arquivos") or all but some ("todos menos o último"). With no file named, it is ALL selected ' +
      'files. The line "Files for this request" below is FastFile''s reading of it: follow it.');
    SL.Add('- For each file of the request: ' +
      'read_lines, search, propose_edit, insert_lines, delete_lines, anonymize and the queued app_actions (also ' +
      'clear_bookmarks) are sent once per file, each with its own path and its own line numbers ("first line" is ' +
      'line 1 of each file; to append use insert_lines "before":"end"). Only view actions (goto, find, ' +
      'filter, toggle_bookmark, CSV mode, tail) use the file open in the main window, since it shows one file.');
    SL.Add('- An action with "path" opens that file in the main window first, so it works on any selected file.');
    SL.Add('- For questions about content (duplicates, most frequent, summary), read or search the real lines first; ' +
      'a file with few lines can be read whole with read_lines.');
    SL.Add('- "What is this file for?" / "what are these files?": send describe_files. If the profile leaves the ' +
      'purpose unclear, read more yourself first (read_lines further into the file, the other record types, ' +
      'search a code). Then answer for EACH file, concrete and grounded in what you saw:');
    SL.Add('  1) what it is: format (delimited with columns / fixed-width records of N chars / log / code / ...), ' +
      'size, lines, encoding;');
    SL.Add('  2) how a record is built: the main fields with their positions or columns and an example value ' +
      '(dates and their format, amounts, codes, ids, constant or masked parts such as XXX), the record types ' +
      '(lines of another length or prefix, header / trailer) and the period the dates cover;');
    SL.Add('  3) what it is most likely for, as a clear inference with the evidence that supports it; name a ' +
      'standard (CNAB, EDI, SPED, ...) only when the evidence matches it (e.g. CNAB records are 240 or 400 chars), ' +
      'otherwise say the layout is proprietary; and how the files relate when there are several;');
    SL.Add('  4) 2 or 3 next steps the user can do in FastFile, named as features of the app (filter, find, ' +
      'export lines, split, SQL on a delimited file, Python macro...), never as tool names or JSON ids ' +
      '(read_lines, search, sql, python_macro...), and never "read more lines" or other checks you can do yourself.');
    SL.Add('  Short paragraphs or a short list, no filler, no generic sentences that fit any file.');
    SL.Add('- A request to run Python / a macro / a script "for each line" is python_macro, never assistant and ' +
      'never app_action show_script_engine (that only opens the empty panel).');
    SL.Add('- Write "answer" in ' + AssistantLangPromptName(GetCurrentLanguage) + ' (the app UI language), ' +
      'even when the User request is written in another language. Keep quoted data, file names and paths as they are.');
    SL.Add('- "answer" is read by the user, not by FastFile: no tool names or JSON ids (read_lines, describe_files, ' +
      'search, sql, python_macro, app_action...); say what you did or suggest in plain words.');
    SL.Add('- Never say something was done, queued, enabled or opened unless a tool result in this conversation confirmed it.');
    SL.Add('- If no tool or action above can do what the user asks, say so plainly in answer ("the agent cannot do X yet") and suggest the closest FastFile feature. Never claim something was done when it was only queued or not possible.');
    SL.Add('- Queued items run only after the user clicks "' + TrText('Accept') + '" in the "' +
      TrText('Proposed edits') + '" tab; say that in answer with exactly these names (the app UI language).');
    SL.Add('- "prompt" is a short plan of what you did, never an instruction to the user.');
    SL.Add('- One JSON object per reply. answer must be non-empty when you finish.');
    SL.Add('');
    if ATotalFiles = 0 then
      SL.Add('- No file is selected: file tools cannot run. Answer FastFile questions through the assistant tool, ' +
        'run view actions without path, or ask the user to add a file in Sources.');
    if AgentAsksWhatFilesAre(AUserPrompt) then
      SL.Add('- This request asks what the file(s) are or are for: start with describe_files.');
    if AgentAsksLineMacro(AUserPrompt) then
      SL.Add('- This request asks to run Python / a macro on the lines: describe or read the file, then send ' +
        'python_macro (one per file of the request).');
    SL.Add('Selected files: ' + IntToStr(ATotalFiles) + ' (in the order of the Sources list: "the first file" is ' +
      'the first one below, "the last file" the last one)');
    N := AFiles.Count;
    if N > 80 then
      N := 80;
    for I := 0 to N - 1 do
      SL.Add(AFiles[I]);
    if AFiles.Count > N then
      SL.Add('... ' + IntToStr(AFiles.Count - N) + ' more. Use list_files.');
    if AOpenPath <> '' then
      SL.Add('File open in the main window: ' + AOpenPath)
    else
      SL.Add('File open in the main window: none');
    SL.Add('User request:');
    SL.Add(AUserPrompt);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function BuildAgentFollowupPrompt(const AOpening, ATranscript: string): string;
var
  Tail: string;
begin
  Tail := ATranscript;
  if Length(Tail) > 20000 then
    Tail := Copy(Tail, Length(Tail) - 20000, MaxInt);
  Result := AOpening + #13#10 + 'Transcript:' + #13#10 + Tail + #13#10 +
    'Reply with ONE JSON object only. No markdown and no empty object.' + #13#10 +
    'Next step: another tool, or {"answer":"<text in ' + AssistantLangPromptName(GetCurrentLanguage) + '>","prompt":"<short plan>","tool":""}.' + #13#10 +
    'Quote tool numbers exactly. Do not invent data you did not read.';
end;

end.
