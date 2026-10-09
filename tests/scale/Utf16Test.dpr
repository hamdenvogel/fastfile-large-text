program Utf16Test;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, uTextEncoding;

var
  Raw, L, Brk: AnsiString;
  Lines: TArray<AnsiString>;
  I, Start, Fails: Integer;
  CR: Boolean;
  F: TFileStream;
  Out1: TStringList;
  Enc: string;
begin
  Fails := 0;
  F := TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, F.Size);
    F.Read(Pointer(Raw)^, F.Size);
  finally
    F.Free;
  end;
  Enc := DetectTextFileEncoding(ParamStr(1));
  Writeln('enc=', Enc);
  { Split on the byte 0A, as the core index does. }
  Start := 1;
  for I := 1 to Length(Raw) do
    if Raw[I] = #10 then
    begin
      Lines := Lines + [Copy(Raw, Start, I - Start)];
      Start := I + 1;
    end;
  if Start <= Length(Raw) then
    Lines := Lines + [Copy(Raw, Start, MaxInt)];
  Out1 := TStringList.Create;
  try
    for I := 0 to High(Lines) do
    begin
      { View path: trailing 0A/0D bytes stripped, then decoded. }
      L := Lines[I];
      while (L <> '') and (L[Length(L)] in [#10, #13]) do
        SetLength(L, Length(L) - 1);
      Writeln(I + 1, ' view  : [', TrimRight(FileBytesToUnicodeText(L, Enc)), ']');
      L := Utf16LineBytes(Lines[I], Enc, CR);
      Writeln(I + 1, ' export: [', FileBytesToUnicodeText(L, Enc), '] cr=', CR, ' len=', Length(Lines[I]));
    end;
    Brk := Utf16LineBreakBytes(Enc, True);
    Writeln('break bytes=', Length(Brk));
  finally
    Out1.Free;
  end;
  Writeln('fails=', Fails);
end.
