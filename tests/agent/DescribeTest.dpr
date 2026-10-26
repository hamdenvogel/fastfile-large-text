program DescribeTest;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, uAgentDescribe;

var
  L: TStringList;
  I: Integer;
begin
  L := TStringList.Create;
  try
    for I := 1 to ParamCount do
      L.Add(ParamStr(I));
    Writeln(AgentToolDescribe(L, nil, 14000, StrToIntDef(GetEnvironmentVariable('SAMPLE'), 500)));
  finally
    L.Free;
  end;
end.
