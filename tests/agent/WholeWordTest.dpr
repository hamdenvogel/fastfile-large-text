program WholeWordTest;

{$APPTYPE CONSOLE}

{ Exact vs partial: the request decides (AgentWantsExactMatch), then search runs as the agent loop runs it. }

uses
  SysUtils, Classes, uAgentTools, uAgentMatchIntent;

const
  PROMPTS: array[0..5] of string = (
    'eu quero pesquisar o nome Allyne',
    'eu quero pesquisar o nome Allyne que é parcial',
    'eu quero pesquisar o nome Allyne sem ser parcial ou seja o nome exato',
    'Quantos registros aparecem como Allyne? Eu quero o nome completo, sem ser parcial.',
    'quero exatamente as linhas com Allyne',
    'search the name Allyne, whole word only');

var
  I: Integer;
  Exact: Boolean;
  Needle, Res, Nos: string;
  P: Integer;
begin
  Needle := 'Allyne';
  for I := 0 to High(PROMPTS) do
  begin
    Exact := AgentWantsExactMatch(PROMPTS[I]);
    Res := AgentToolSearch(ParamStr(1), Needle, 20, nil,
      Exact and (Needle <> AnsiLowerCase(Needle)), Exact);
    P := Pos('hits=', Res);
    Nos := Copy(Res, P, Pos(#13, Copy(Res, P, MaxInt)) - 1);
    Write(Format('%-90s exact=%-5s %s', [PROMPTS[I], BoolToStr(Exact, True), Nos]));
    P := Pos('line_numbers=', Res);
    if P > 0 then
      Write('  ', Copy(Res, P, Pos(#13, Copy(Res, P, MaxInt)) - 1));
    Writeln;
  end;
end.
