unit uAgentProtocol;

{
  One JSON object per model turn, carried inside the existing prompt/resposta gateway.
}

interface

uses
  Classes;

type
  TAgentToolKind = (atkNone, atkList, atkRead, atkSearch, atkCount,
    atkEdit, atkInsert, atkDelete, atkAnonymize, atkAction, atkSql, atkUnknown);

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
    { JSON reply with no usable tool and no answer: the loop asks again. }
    Malformed: Boolean;
  end;

function ParseAgentTurn(const ARaw: string): TAgentTurn;
function BuildAgentOpeningPrompt(const AUserPrompt: string; AFiles: TStrings;
  ATotalFiles: Integer; const AOpenPath: string = ''): string;
function BuildAgentFollowupPrompt(const AOpening, ATranscript: string): string;

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
    SL.Add('There is NO function calling and NO code execution here (no python, bash, container.exec, browser).');
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
    SL.Add('{"tool":"insert_lines","path":"<path>","before":50,"text":"line A\nline B"}  insert before line 50; before = last line + 1 appends');
    SL.Add('{"tool":"delete_lines","path":"<path>","start":100,"end":250}');
    SL.Add('{"tool":"anonymize","path":"<path>","start":1,"end":1000,"numbers":true,"dates":true,"emails":true,"codes":true,"names":"names","columns":"","delimiter":"","skip_header":false,"keep_words":""}');
    SL.Add('  anonymize keeps the same length and character type. Omit start/end for the whole file. names = names | all | none. columns like "2,5-7" with delimiter like ";".');
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
    SL.Add('  split_equal_parts parts:4  | extract_file_parts total_parts:10, part_from:2, part_to:3');
    SL.Add('  force_index_file | save_session | load_session | toggle_readonly_session');
    SL.Add('  clear_bookmarks  - removes ALL bookmarks of the file at once ("limpe todos os marcadores")');
    SL.Add('  open_policy_auto | open_policy_index | open_policy_instant | segment_ops_auto | segment_ops_always | segment_ops_never');
    SL.Add('Run after your answer (view only):');
    SL.Add('  open_and_read_file | goto_line line | goto_byte_offset byte_offset | goto_file_start | goto_file_end');
    SL.Add('  find_text needle | find_next | find_previous | view_find_occurrences | apply_filter needle | clear_filter | copy_filtered');
    SL.Add('  filter_match_contains | filter_match_prefix | filter_match_regex | toggle_csv_mode | toggle_csv_header | toggle_word_wrap');
    SL.Add('  toggle_whitespace_marks | zoom_in | zoom_out | toggle_bookmark | next_bookmark | start_tail | pause_tail');
    SL.Add('  show_tab_compare | show_tab_merge_lines | show_tab_merge_files path, merge_mode, after_line | show_tab_recent');
    SL.Add('  open_find | open_filter | open_replace | find_in_files | show_script_engine | show_tail_macro | show_version_history');
    SL.Add('  open_options | open_preferences | show_help | show_about | new_file | toggle_fullscreen | toggle_bookmark_bar | restore_session_tabs');
    SL.Add('  open_anonymize_dialog  - the anonymize window for the file open in the main window (prefer the anonymize tool)');
    SL.Add('Not available in FastFile (say so): encoding conversion, line-ending (EOL) conversion, sorting lines, editing binary data.');
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
    SL.Add('- path must be copied from the selected files.');
    SL.Add('- Prefer replace_all for "replace every X with Y" in a whole file; use propose_edit for specific lines.');
    SL.Add('- An app_action acts on one file. For several files send one action per file, one per reply.');
    SL.Add('- "Filter"/"filtre"/"filtrar" on screen means apply_filter (or filter_match_regex for a regex), not search.');
    SL.Add('- propose_edit text is the whole new line. Keep every column you did not mean to change.');
    SL.Add('- anonymize: "keep X" -> keep_words, "only columns" -> columns + delimiter, "not the header" -> skip_header:true, ' +
      'only names -> numbers/dates/emails/codes false.');
    SL.Add('- Every id listed above is usable by you through app_action (new_file, toggle_fullscreen, show_help, ...). ' +
      'open_policy_*, segment_ops_*, save_session and load_session are global: send them once, without path.');
    SL.Add('- If several files are selected and the request does not name a file: view actions (goto, find, filter, ' +
      'bookmarks, CSV mode, tail) use the file open in the main window; a line edit asks which file.');
    SL.Add('- An action with "path" opens that file in the main window first, so it works on any selected file.');
    SL.Add('- For questions about content (duplicates, most frequent, summary), read or search the real lines first; ' +
      'a file with few lines can be read whole with read_lines.');
    SL.Add('- Write "answer" in ' + AssistantLangPromptName(GetCurrentLanguage) + ' (the app UI language), ' +
      'even when the User request is written in another language. Keep quoted data, file names and paths as they are.');
    SL.Add('- Never say something was done, queued, enabled or opened unless a tool result in this conversation confirmed it.');
    SL.Add('- If no tool or action above can do what the user asks, say so plainly in answer ("the agent cannot do X yet") and suggest the closest FastFile feature. Never claim something was done when it was only queued or not possible.');
    SL.Add('- Queued items run only after the user clicks "' + TrText('Accept') + '" in the "' +
      TrText('Proposed edits') + '" tab; say that in answer with exactly these names (the app UI language).');
    SL.Add('- "prompt" is a short plan of what you did, never an instruction to the user.');
    SL.Add('- One JSON object per reply. answer must be non-empty when you finish.');
    SL.Add('');
    SL.Add('Selected files: ' + IntToStr(ATotalFiles));
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
