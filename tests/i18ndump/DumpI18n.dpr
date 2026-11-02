program DumpI18n;

{$APPTYPE CONSOLE}

{ Dev tool: dumps every translation table (all languages) to the file in
  ParamStr(1). Input of tools\gen_rtl_i18n.py. }

uses
  SysUtils, uI18n;

begin
  try
    I18nDumpAllTables(ParamStr(1));
    Writeln('dumped to ', ParamStr(1));
  except
    on E: Exception do
    begin
      Writeln('ERROR: ', E.Message);
      Halt(1);
    end;
  end;
end.
