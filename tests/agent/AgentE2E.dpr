program AgentE2E;

{ Runs the checklist prompts (prompts.txt, "id|prompt" per line) through the real
  agent loop and gateway, on copies of C:\Hamden\Files. Proposals and core actions
  are only recorded, never applied. Usage: AgentE2E [id-prefix] }

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IOUtils, Forms, Windows,
  uAgentPrefs, uAgentPatch, uAgentLoop, uAgentTools, uAgentProtocol, uFastFileAssistantHost;

type
  TRecClient = class(TAgentLoopClient)
  public
    Log: TStringList;
    CancelFlag: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Status(const AText: string); override;
    procedure QueueEdit(AEdit: TAgentEdit); override;
    procedure RunAfter(AEdit: TAgentEdit); override;
  end;

function OneLine(const S: string; AMax: Integer = 300): string;
begin
  Result := StringReplace(S, #13#10, ' \n ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' \n ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' \n ', [rfReplaceAll]);
  if Length(Result) > AMax then
    Result := Copy(Result, 1, AMax) + '...';
end;

function Describe(const ATag: string; E: TAgentEdit): string;
const
  KINDS: array[TAgentEditKind] of string = ('replace', 'insert', 'delete', 'anonymize', 'action');
var
  A: TAssistantChainStep;
begin
  Result := Format('  %s %s %s', [ATag, KINDS[E.Kind], ExtractFileName(E.Path)]);
  case E.Kind of
    aekReplace, aekDelete:
      Result := Result + Format(' lines %d-%d', [E.LineStart, E.LineEnd]);
    aekInsert:
      Result := Result + Format(' before %d', [E.LineStart]);
    aekAnonymize:
      Result := Result + Format(' lines %d-%d [%s]', [E.LineStart, E.LineEnd, E.AnonInfo]);
    aekAction:
      begin
        A := E.Action;
        Result := Result + ' id=' + A.ActionId;
        if A.FilterText <> '' then Result := Result + ' filter="' + A.FilterText + '"';
        if A.ReplaceText <> '' then Result := Result + ' replace="' + A.ReplaceText + '"';
        if A.LineNo <> 0 then Result := Result + ' line=' + IntToStr(A.LineNo);
        if A.Parts <> 0 then Result := Result + ' parts=' + IntToStr(A.Parts);
        if A.TotalParts <> 0 then
          Result := Result + Format(' total=%d from=%d to=%d', [A.TotalParts, A.PartFrom, A.PartTo]);
        if A.ByteOffset <> 0 then Result := Result + ' byte=' + IntToStr(A.ByteOffset);
        if A.CaseSensitive then Result := Result + ' case';
        if A.MaxLines <> 0 then Result := Result + ' max=' + IntToStr(A.MaxLines);
      end;
  end;
  if (E.Kind in [aekReplace, aekInsert]) then
    Result := Result + ' text="' + OneLine(E.NewText, 200) + '"';
end;

constructor TRecClient.Create;
begin
  inherited Create;
  Log := TStringList.Create;
  CancelPtr := @CancelFlag;
end;

destructor TRecClient.Destroy;
begin
  Log.Free;
  inherited;
end;

procedure TRecClient.Status(const AText: string);
begin
  if (Copy(AText, 1, 5) = 'turn:') or (AText = 'retry') then
    Log.Add('  status ' + AText);
end;

procedure TRecClient.QueueEdit(AEdit: TAgentEdit);
begin
  Log.Add(Describe('PROPOSAL', AEdit));
  AEdit.Free;
end;

procedure TRecClient.RunAfter(AEdit: TAgentEdit);
begin
  Log.Add(Describe('RUNAFTER', AEdit));
  AEdit.Free;
end;

var
  Dir, Work, OutFile, Filter, Line, Id, Prompt, Ans, Rev, Err, Block: string;
  Prompts, Files: TStringList;
  Prefs: TAgentPrefs;
  C: TRecClient;
  I, P: Integer;
  T0: Cardinal;
  PT: TAgentTurn;
begin
  Dir := ExtractFilePath(ParamStr(0));
  Work := Dir + 'work\';
  ForceDirectories(Work);
  for Line in ['clientes.csv', 'log.txt', 'unicode16.txt'] do
    TFile.Copy('C:\Hamden\Files\' + Line, Work + Line, True);
  Filter := ParamStr(1);
  if Filter = 'parse' then
  begin
    for Line in [
      '{"answer":"","tool":"{\"tool\":\"count\",\"needle\":\"Bianca\"}"}',
      '{"tool":"toggle_bookmark;next_bookmark"}',
      '{"tool":"[{\"tool\":\"app_action\",\"action\":\"toggle_word_wrap\"},{\"tool\":\"app_action\",\"action\":\"zoom_in\"}]"}',
      '{"tool":[{"tool":"app_action","action":"toggle_word_wrap"},{"tool":"app_action","action":"zoom_in"}]}',
      '{"tool":"read_lines","path":"C:\\a.csv","start":1,"count":1}{"tool":"read_lines","path":"C:\\b.csv","start":2}',
      '{"tool":"{\"tool\":\"app_action\",\"action\":\"split_equal_parts\",\"path\":\"C:\\\\x.txt\",\"parts\":3}"}',
      '{"tool":"{\"tool\":\"delete_lines\",\"path\":\"C:\\\\x.txt\",\"start\":5,\"end\":7}"}',
      '{"tool":"read_lines","file":"clientes.csv","from":2,"to":4}',
      '{"answer":"Pronto","prompt":"ok","tool":""}'] do
    begin
      PT := ParseAgentTurn(Line);
      Writeln(Line);
      Writeln(Format('  -> tool=%d raw=%s action=%s needle=%s path=%s start=%d end=%d count=%d parts=%d more=%s malformed=%s answer=%s',
        [Ord(PT.Tool), PT.RawTool, PT.ActionId, PT.Needle, PT.Path, PT.StartLine, PT.EndLine, PT.Count,
         PT.Parts, BoolToStr(PT.MoreTools, True), BoolToStr(PT.Malformed, True), PT.Answer]));
    end;
    Exit;
  end;
  if Filter = 'tools' then
  begin
    Files := TStringList.Create;
    try
      Files.Add(Work + 'clientes.csv');
      Files.Add(Work + 'log.txt');
      Files.Add(Work + 'unicode16.txt');
      Writeln('--- count Bianca'); Writeln(AgentToolCount(Files, 'Bianca', 8, nil));
      Writeln('--- count @gmail.com'); Writeln(AgentToolCount(Files, '@gmail.com', 8, nil));
      Writeln('--- count São Paulo'); Writeln(AgentToolCount(Files, 'São Paulo', 8, nil));
      Writeln('--- search Bianca csv'); Writeln(AgentToolSearch(Files[0], 'Bianca', 20, nil));
      Writeln('--- search Bianca utf16'); Writeln(AgentToolSearch(Files[2], 'Bianca', 20, nil));
      Writeln('--- read csv 1..5'); Writeln(AgentToolReadLines(Files[0], 1, 5, nil));
      Writeln('--- read log 26..30'); Writeln(AgentToolReadLines(Files[1], 26, 5, nil));
      Writeln('--- read utf16 1..3'); Writeln(AgentToolReadLines(Files[2], 1, 3, nil));
      Writeln('--- count @gmail.com case'); Writeln(AgentToolCount(Files, '@gmail.com', 8, nil, True));
      Writeln('--- search bianca case csv'); Writeln(AgentToolSearch(Files[0], 'bianca', 20, nil, True));
      Writeln('--- read log last 5'); Writeln(AgentToolReadLines(Files[1], -1, 5, nil));
      Writeln('--- read utf16 last 1'); Writeln(AgentToolReadLines(Files[2], -1, 1, nil));
      Writeln('--- read csv 999999999'); Writeln(AgentToolReadLines(Files[0], 999999999, 5, nil));
      Writeln('--- list'); Writeln(AgentToolList(Files, 4000));
    finally
      Files.Free;
    end;
    Exit;
  end;
  OutFile := Dir + 'out.txt';
  TFile.WriteAllText(OutFile, '', TEncoding.UTF8);
  Files := TStringList.Create;
  Prompts := TStringList.Create;
  try
    Files.Add(Work + 'clientes.csv');
    Files.Add(Work + 'log.txt');
    Files.Add(Work + 'unicode16.txt');
    Prompts.LoadFromFile(Dir + 'prompts.txt', TEncoding.UTF8);
    Prefs := DefaultAgentPrefs;
    Prefs.OpenPath := Files[0];
    for I := 0 to Prompts.Count - 1 do
    begin
      Line := Trim(Prompts[I]);
      P := Pos('|', Line);
      if (Line = '') or (Line[1] = '#') or (P = 0) then Continue;
      Id := Copy(Line, 1, P - 1);
      Prompt := Copy(Line, P + 1, MaxInt);
      if (Filter <> '') and (Copy(Id, 1, Length(Filter)) <> Filter) then Continue;
      Writeln(Id, ' ...');
      C := TRecClient.Create;
      try
        T0 := GetTickCount;
        try
          AgentExecute(Prompt, Files, Prefs, C, Ans, Rev, Err);
        except
          on E: Exception do
            Err := 'EXCEPTION ' + E.ClassName + ': ' + E.Message;
        end;
        Block := '=== ' + Id + '  (' + IntToStr((GetTickCount - T0) div 1000) + ' s)' + sLineBreak +
          'PROMPT: ' + Prompt + sLineBreak +
          'ANSWER: ' + OneLine(Ans, 1500) + sLineBreak;
        if Err <> '' then
          Block := Block + 'ERR: ' + OneLine(Err, 500) + sLineBreak;
        if C.Log.Count > 0 then
          Block := Block + C.Log.Text;
        TFile.AppendAllText(OutFile, Block + sLineBreak, TEncoding.UTF8);
      finally
        C.Free;
      end;
    end;
  finally
    Prompts.Free;
    Files.Free;
  end;
  Writeln('done');
end.
