program I18nAuditTest;

{$APPTYPE CONSOLE}

{ For each key in keys file: which of the 13 non-English languages fall back to the English text. }

uses
  Windows, SysUtils, Classes, TypInfo, uI18n;

var
  Keys, Outp: TStringList;
  I: Integer;
  L: TAppLanguage;
  En, T, Miss: string;
begin
  Keys := TStringList.Create;
  Outp := TStringList.Create;
  try
    Keys.LoadFromFile(ParamStr(1), TEncoding.UTF8);
    for I := 0 to Keys.Count - 1 do
    begin
      if Trim(Keys[I]) = '' then Continue;
      SetCurrentLanguage(alEnglish);
      En := TrText(StringReplace(Keys[I], '''''', '''', [rfReplaceAll]));
      Miss := '';
      for L := Succ(alEnglish) to High(TAppLanguage) do
      begin
        SetCurrentLanguage(L);
        T := TrText(StringReplace(Keys[I], '''''', '''', [rfReplaceAll]));
        if (T = En) or (T = Keys[I]) then
          Miss := Miss + ' ' + GetEnumName(TypeInfo(TAppLanguage), Ord(L));
      end;
      if (En = Keys[I]) and (Pos('.', Keys[I]) > 0) and (Pos(' ', Keys[I]) = 0) then
        Miss := ' NO-ENGLISH' + Miss;
      if Miss <> '' then
        Outp.Add(Keys[I] + ' =>' + Miss + '   [' + Copy(En, 1, 60) + ']');
    end;
    Outp.SaveToFile(ParamStr(2), TEncoding.UTF8);
    Writeln('flagged=', Outp.Count, ' of ', Keys.Count);
  finally
    Keys.Free;
    Outp.Free;
  end;
end.
