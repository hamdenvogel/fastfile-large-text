program ParseShapeTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  uAgentProtocol;

var
  Fails: Integer = 0;

procedure Check(const AName: string; AOk: Boolean);
begin
  if AOk then
    Writeln('PASS ', AName)
  else
  begin
    Writeln('FAIL ', AName);
    Inc(Fails);
  end;
end;

var
  T: TAgentTurn;
begin
  T := ParseAgentTurn('{"answer":"Substitui...","prompt":"queue replace_all","tool":{"replace_all":' +
    '{"path":"C:\\x\\a.csv","find":"gmail","replace":"GMAIL","case_sensitive":true}}}');
  Check('keyed tool -> action', T.Tool = atkAction);
  Check('keyed tool action id', T.ActionId = 'replace_all');
  Check('keyed tool path', T.Path = 'C:\x\a.csv');
  Check('keyed tool find', T.Needle = 'gmail');
  Check('keyed tool replace', T.ReplaceText = 'GMAIL');
  Check('keyed tool case', T.CaseSensitive = 1);

  T := ParseAgentTurn('{"tool":{"name":"count","needle":"x"}}');
  Check('named tool still works', (T.Tool = atkCount) and (T.Needle = 'x'));

  T := ParseAgentTurn('{"tool":"app_action","action":"replace_all","find":"a","replace":"b"}');
  Check('app_action still works', (T.Tool = atkAction) and (T.ActionId = 'replace_all') and (T.ReplaceText = 'b'));

  T := ParseAgentTurn('{"answer":"ok","tool":""}');
  Check('plain answer', (T.Tool = atkNone) and (T.Answer = 'ok'));

  Writeln('fails=', Fails);
  ExitCode := Fails;
end.
